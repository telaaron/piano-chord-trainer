// Microphone-based audio input service – polyphonic chord recognition via @spotify/basic-pitch
//
// Flow:
// 1. getUserMedia → microphone MediaStream
// 2. AudioContext → MediaStreamSource → ScriptProcessorNode (ring buffer)
// 3. AnalyserNode for real-time energy monitoring
// 4. When sufficient energy detected, run basic-pitch ML on buffered audio
// 5. Extract sounding notes → update activeNotes → fire callback
// 6. Same checkChord interface as MidiService

import { noteToSemitone } from '$lib/engine';
import type { ChordMatchResult } from './midi';

export type AudioInputState =
	| 'idle'
	| 'requesting'
	| 'loading-model'
	| 'listening'
	| 'analyzing'
	| 'error'
	| 'denied'
	| 'unsupported';

type NoteCallback = (activeNotes: Set<number>) => void;
type StateCallback = (state: AudioInputState) => void;

// basic-pitch dynamic import types
interface BasicPitchModule {
	BasicPitch: new (modelPath: string) => BasicPitchInstance;
	outputToNotesPoly: (
		frames: number[][],
		onsets: number[][],
		onsetThresh?: number,
		frameThresh?: number,
		minNoteLen?: number,
		inferOnsets?: boolean,
		maxFreq?: number | null,
		minFreq?: number | null,
		melodiaTrick?: boolean,
		energyTolerance?: number,
	) => NoteEvent[];
	noteFramesToTime: (notes: NoteEvent[]) => NoteEventTime[];
}

interface BasicPitchInstance {
	evaluateModel(
		buffer: AudioBuffer | Float32Array,
		onComplete: (frames: number[][], onsets: number[][], contours: number[][]) => void,
		percentCallback: (percent: number) => void,
	): Promise<void>;
}

interface NoteEvent {
	startFrame: number;
	durationFrames: number;
	pitchMidi: number;
	amplitude: number;
}

interface NoteEventTime {
	startTimeSeconds: number;
	durationSeconds: number;
	pitchMidi: number;
	amplitude: number;
}

export class AudioInputService {
	private audioContext: AudioContext | null = null;
	private stream: MediaStream | null = null;
	private source: MediaStreamAudioSourceNode | null = null;
	private analyser: AnalyserNode | null = null;
	private processor: ScriptProcessorNode | null = null;
	private silentGain: GainNode | null = null;

	// Ring buffer: last ~2 seconds of raw PCM audio
	private ringBuffer: Float32Array = new Float32Array(0);
	private ringWriteIndex = 0;
	private ringBufferFilled = false;

	// basic-pitch ML model (lazy-loaded)
	private bpModule: BasicPitchModule | null = null;
	private bpInstance: BasicPitchInstance | null = null;
	private modelLoaded = false;
	private modelLoading = false;
	private modelLoadPromise: Promise<boolean> | null = null;

	// State
	private _activeNotes = new Set<number>();
	private _state: AudioInputState = 'idle';
	private isAnalyzing = false;
	private analysisTimer: ReturnType<typeof setInterval> | null = null;

	// Energy detection
	private energyThreshold = 0.0013;
	private silenceFrames = 0;
	private readonly silenceFramesThreshold = 4; // 4 cycles × 0.8s = ~3s of silence before clearing
	private hadEnergyOnce = false;

	// Audio output suppression — prevents mic from detecting its own audio output
	private _suppressUntil = 0;

	// Adaptive level normalization for display (getLevel())
	// Tracks the recent peak RMS so the meter auto-calibrates to the mic.
	private levelPeakRMS = 0.03; // starting floor — prevents noise looking huge at startup

	// Callbacks
	private onNoteChange: NoteCallback | null = null;
	private onStateChange: StateCallback | null = null;

	// ─── Public getters ─────────────────────────────────────────

	/** Currently detected MIDI note numbers */
	get activeNotes(): ReadonlySet<number> {
		return this._activeNotes;
	}

	get state(): AudioInputState {
		return this._state;
	}

	// ─── Event registration ─────────────────────────────────────

	onNotes(cb: NoteCallback): void {
		this.onNoteChange = cb;
	}

	onConnection(cb: StateCallback): void {
		this.onStateChange = cb;
	}

	/**
	 * Suppress detection for the given duration.
	 * Use this when audio playback starts — prevents the microphone
	 * from hearing its own speakers and self-triggering chord matches.
	 *
	 * @param durationMs  How long to mute detection (default: 2500ms — enough for
	 *                    a chord to ring out + ML inference latency)
	 */
	suppress(durationMs = 2500): void {
		this._suppressUntil = Date.now() + durationMs;
		// Clear any currently detected notes immediately so a previously
		// matched chord doesn't linger during the suppression window.
		if (this._activeNotes.size > 0) {
			this._activeNotes = new Set<number>();
			this.onNoteChange?.(this._activeNotes);
		}
	}

	// ─── Lifecycle ──────────────────────────────────────────────

	/**
	 * Request microphone access, set up audio graph, begin listening.
	 * Lazy-loads the basic-pitch ML model in the background.
	 * Returns true if mic access was granted.
	 */
	async init(): Promise<boolean> {
		// Guard: already running
		if (this._state === 'listening' || this._state === 'analyzing') return true;

		// mediaDevices is only available in secure contexts (HTTPS or localhost).
		// Over plain HTTP (e.g. local network dev), it will be undefined.
		if (typeof navigator === 'undefined' || !navigator.mediaDevices?.getUserMedia) {
			console.warn('[AudioInput] navigator.mediaDevices unavailable — page must be served over HTTPS');
			this.setState('unsupported');
			return false;
		}

		this.setState('requesting');

		try {
			// Request microphone.
			// autoGainControl:true lets iOS/Android hardware normalize mic level
			// (critical for iPad and quiet-mic devices).
			this.stream = await navigator.mediaDevices.getUserMedia({
				audio: {
					echoCancellation: false,
					noiseSuppression: false,
					autoGainControl: true,
				},
			});

			// Create AudioContext at the browser's native sample rate.
			// iOS Safari ignores custom sampleRate options; we resample to 22050 Hz
			// in runInference() using OfflineAudioContext before calling basic-pitch.
			const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
			this.audioContext = new AudioCtx();

			// Resume context on iOS Safari (requires user gesture before init)
			if (this.audioContext.state === 'suspended') {
				await this.audioContext.resume();
			}

			// Connect microphone source — use the native signal level as-is.
			// No software preamp; let the browser's autoGainControl handle
			// hardware-level normalisation (iPad, external mics, etc.).
			this.source = this.audioContext.createMediaStreamSource(this.stream);

			// AnalyserNode for RMS energy monitoring
			this.analyser = this.audioContext.createAnalyser();
			this.analyser.fftSize = 2048;
			this.analyser.smoothingTimeConstant = 0.3;
			this.source.connect(this.analyser);

			// ScriptProcessorNode for raw audio capture into ring buffer
			// Connect through a silent gain node to prevent mic feedback
			this.processor = this.audioContext.createScriptProcessor(4096, 1, 1);
			this.silentGain = this.audioContext.createGain();
			this.silentGain.gain.value = 0;

			this.source.connect(this.processor);
			this.processor.connect(this.silentGain);
			this.silentGain.connect(this.audioContext.destination);

			// Ring buffer: 2 seconds of audio at current sample rate
			const bufferLength = Math.ceil(this.audioContext.sampleRate * 2);
			this.ringBuffer = new Float32Array(bufferLength);
			this.ringWriteIndex = 0;
			this.ringBufferFilled = false;

			this.processor.onaudioprocess = (e: AudioProcessingEvent) => {
				const input = e.inputBuffer.getChannelData(0);
				for (let i = 0; i < input.length; i++) {
					this.ringBuffer[this.ringWriteIndex] = input[i];
					this.ringWriteIndex++;
					if (this.ringWriteIndex >= this.ringBuffer.length) {
						this.ringWriteIndex = 0;
						this.ringBufferFilled = true;
					}
				}
			};

			// Start model loading in background
			this.setState('loading-model');
			this.loadModel().then((ok) => {
				if (ok && this._state === 'loading-model') {
					this.setState('listening');
				}
			});

			// Start periodic analysis loop (every 0.8 seconds)
			this.analysisTimer = setInterval(() => this.analyzeLoop(), 800);

			return true;
		} catch (err: unknown) {
			const domErr = err as DOMException;
			if (domErr?.name === 'NotAllowedError' || domErr?.name === 'PermissionDeniedError') {
				this.setState('denied');
			} else {
				console.warn('[AudioInput] Microphone access error:', err);
				this.setState('error');
			}
			return false;
		}
	}

	/** Load the basic-pitch ML model (idempotent, lazy) */
	private loadModel(): Promise<boolean> {
		if (this.modelLoaded) return Promise.resolve(true);
		if (this.modelLoadPromise) return this.modelLoadPromise;

		this.modelLoading = true;
		this.modelLoadPromise = (async () => {
			try {
				const mod = await import('@spotify/basic-pitch');
				this.bpModule = mod as unknown as BasicPitchModule;
				this.bpInstance = new this.bpModule.BasicPitch('/models/basic-pitch/model.json');
				this.modelLoaded = true;
				this.modelLoading = false;
				return true;
			} catch (err) {
				console.warn('[AudioInput] Failed to load basic-pitch model:', err);
				this.modelLoaded = false;
				this.modelLoading = false;
				return false;
			}
		})();

		return this.modelLoadPromise;
	}

	/**
	 * Returns current mic input level as a 0–1 float for UI display.
	 *
	 * Uses an adaptive peak follower so the meter auto-calibrates to the
	 * microphone's actual output level:
	 *   - Fast attack: peak rises quickly when you play
	 *   - Very slow decay: peak holds for ~60 s, then drifts down during silence
	 *   - Normalises so "typical peak playing" ≈ 60 % on the meter
	 *
	 * This way a loud Mac condenser and a quiet iPad mic both show useful levels.
	 */
	getLevel(): number {
		const raw = this.getRMSEnergy();

		// Attack: move 12 % toward new value per call (~60 fps → 0.3 s to reach 85 %)
		// Decay:  0.02 % drop per call → half-life ≈ 57 s (holds the reference long)
		if (raw > this.levelPeakRMS) {
			this.levelPeakRMS = raw * 0.12 + this.levelPeakRMS * 0.88;
		} else {
			this.levelPeakRMS = this.levelPeakRMS * 0.9998;
		}

		// Normalise: use a floor of 0.01 so ambient noise near 0 stays small.
		// Scale × 0.6 so playing at peak level ≈ 60 % (leaves headroom visible).
		const norm = Math.max(this.levelPeakRMS, 0.01);
		return Math.min((raw / norm) * 0.6, 1);
	}

	/** Compute RMS energy from the AnalyserNode's time-domain data */
	private getRMSEnergy(): number {
		if (!this.analyser) return 0;
		const data = new Float32Array(this.analyser.fftSize);
		this.analyser.getFloatTimeDomainData(data);
		let sum = 0;
		for (let i = 0; i < data.length; i++) {
			sum += data[i] * data[i];
		}
		return Math.sqrt(sum / data.length);
	}

	/**
	 * Periodic analysis loop — called every ~1.2 seconds.
	 * Monitors energy and triggers ML inference when sound is present.
	 */
	private async analyzeLoop(): Promise<void> {
		// Don't overlap analyses
		if (this.isAnalyzing || !this.audioContext) return;

		// Suppressed — audio playback is active, skip to avoid self-detection
		if (Date.now() < this._suppressUntil) return;

		const energy = this.getRMSEnergy();

		// ── Silence handling ──
		if (energy < this.energyThreshold) {
			this.silenceFrames++;
			// Clear notes after sustained silence (only if we had notes before)
			if (this.silenceFrames > this.silenceFramesThreshold && this._activeNotes.size > 0) {
				this._activeNotes = new Set<number>();
				this.onNoteChange?.(this._activeNotes);
			}
			return;
		}

		this.silenceFrames = 0;
		this.hadEnergyOnce = true;

		// Wait for model
		if (!this.modelLoaded) {
			if (!this.modelLoading) this.loadModel();
			return;
		}

		// Need sufficient audio data (at least ~0.5 seconds)
		const minSamples = Math.ceil(this.audioContext.sampleRate * 0.5);
		if (!this.ringBufferFilled && this.ringWriteIndex < minSamples) {
			return;
		}

		const prevState = this._state;
		this.setState('analyzing');

		try {
			this.isAnalyzing = true;
			const notes = await this.runInference();

			// Update detected notes
			const detected = new Set<number>();
			for (const n of notes) {
				detected.add(n.pitchMidi);
			}

			this._activeNotes = detected;
			this.onNoteChange?.(this._activeNotes);
		} catch (err) {
			console.warn('[AudioInput] Analysis error:', err);
		}

		this.isAnalyzing = false;
		// Restore to listening (unless we were destroyed)
		if (this._state === 'analyzing') {
			this.setState(prevState === 'listening' || prevState === 'analyzing' ? 'listening' : prevState);
		}
	}

	/**
	 * Run basic-pitch ML inference on the current ring buffer.
	 * Returns detected note events in the "recent" portion of the audio.
	 */
	private async runInference(): Promise<NoteEventTime[]> {
		if (!this.bpInstance || !this.bpModule || !this.audioContext) return [];

		const sampleRate = this.audioContext.sampleRate;
		const totalSamples = this.ringBufferFilled ? this.ringBuffer.length : this.ringWriteIndex;

		// Create AudioBuffer from ring buffer (linearize circular buffer)
		const audioBuffer = this.audioContext.createBuffer(1, totalSamples, sampleRate);
		const channelData = audioBuffer.getChannelData(0);

		if (this.ringBufferFilled) {
			// Circular buffer: copy from writeIndex→end, then 0→writeIndex
			const firstPart = this.ringBuffer.subarray(this.ringWriteIndex);
			const secondPart = this.ringBuffer.subarray(0, this.ringWriteIndex);
			channelData.set(firstPart, 0);
			channelData.set(secondPart, firstPart.length);
		} else {
			channelData.set(this.ringBuffer.subarray(0, totalSamples));
		}

		// basic-pitch requires exactly 22050 Hz. iOS Safari (and some other platforms)
		// always create AudioContext at 44100 Hz regardless of the sampleRate option.
		// Resample via OfflineAudioContext whenever the native rate differs.
		const TARGET_RATE = 22050;
		let analysisBuffer: AudioBuffer = audioBuffer;
		let analysisSamples = totalSamples;

		if (Math.round(sampleRate) !== TARGET_RATE) {
			const resampledLength = Math.round(totalSamples * TARGET_RATE / sampleRate);
			const offlineCtx = new OfflineAudioContext(1, resampledLength, TARGET_RATE);
			const src = offlineCtx.createBufferSource();
			src.buffer = audioBuffer;
			src.connect(offlineCtx.destination);
			src.start(0);
			analysisBuffer = await offlineCtx.startRendering();
			analysisSamples = resampledLength;
		}

		// Run ML inference
		let frames: number[][] = [];
		let onsets: number[][] = [];

		await this.bpInstance.evaluateModel(
			analysisBuffer,
			(f, o, _c) => {
				frames = f;
				onsets = o;
			},
			() => {}, // progress callback (unused)
		);

		// Convert to note events — tuned thresholds for piano chords
		const noteEvents = this.bpModule.outputToNotesPoly(
			frames,
			onsets,
			0.5, // onsetThresh — higher = fewer false positives
			0.3, // frameThresh
			3, // minNoteLen (frames)
			true, // inferOnsets
			null, // maxFreq — no limit
			null, // minFreq — no limit
			true, // melodiaTrick
			11, // energyTolerance
		);

		const noteEventsTime = this.bpModule.noteFramesToTime(noteEvents);

		// The ring buffer only holds the last ~2 seconds of audio, so all detected
		// notes are inherently recent. Just filter by amplitude — no time window
		// needed (a window filter caused notes to be silently dropped when inference
		// took longer than the window size).
		return noteEventsTime.filter((note) => note.amplitude > 0.15);
	}

	// ─── Chord matching ─────────────────────────────────────────
	// Identical logic to MidiService — operates on detected active notes

	/**
	 * Check if detected notes match the expected chord.
	 * Octave-agnostic (pitch classes mod 12).
	 */
	checkChord(expectedNotes: string[]): ChordMatchResult {
		const expectedSemitones = new Set<number>();
		for (const note of expectedNotes) {
			const st = noteToSemitone(note);
			if (st !== -1) expectedSemitones.add(st);
		}

		const activePitchClasses = new Set<number>();
		for (const midiNote of this._activeNotes) {
			activePitchClasses.add(midiNote % 12);
		}

		const missing: number[] = [];
		const matched: number[] = [];

		for (const expected of expectedSemitones) {
			if (activePitchClasses.has(expected)) {
				matched.push(expected);
			} else {
				missing.push(expected);
			}
		}

		const extra: number[] = [];
		for (const active of activePitchClasses) {
			if (!expectedSemitones.has(active)) {
				extra.push(active);
			}
		}

		const total = expectedSemitones.size;
		const accuracy = total > 0 ? matched.length / total : 0;

		return { correct: missing.length === 0 && extra.length === 0, missing, extra, accuracy };
	}

	/**
	 * Lenient match: all expected notes held, extra notes tolerated.
	 * Important for audio where overtones may trigger extra pitch classes.
	 */
	checkChordLenient(expectedNotes: string[]): ChordMatchResult {
		const result = this.checkChord(expectedNotes);
		return { ...result, correct: result.missing.length === 0 };
	}

	/**
	 * Inversion-aware match (checks lowest detected note = expected bass).
	 */
	checkChordWithBass(expectedNotes: string[], expectedBassNote: string): ChordMatchResult {
		const result = this.checkChordLenient(expectedNotes);
		if (!result.correct || this._activeNotes.size === 0) return result;

		let lowestMidi = Infinity;
		for (const mn of this._activeNotes) {
			if (mn < lowestMidi) lowestMidi = mn;
		}

		const lowestPitchClass = lowestMidi % 12;
		const expectedBassPc = noteToSemitone(expectedBassNote);

		if (expectedBassPc === -1 || lowestPitchClass === expectedBassPc) {
			return result;
		}

		return { ...result, correct: false };
	}

	/** Clear all detected notes */
	releaseAll(): void {
		this._activeNotes = new Set<number>();
		this.onNoteChange?.(this._activeNotes);
	}

	/** Clean up everything: stop mic, close audio context, clear state */
	destroy(): void {
		if (this.analysisTimer) {
			clearInterval(this.analysisTimer);
			this.analysisTimer = null;
		}

		if (this.processor) {
			this.processor.onaudioprocess = null;
			this.processor.disconnect();
			this.processor = null;
		}

		if (this.source) {
			this.source.disconnect();
			this.source = null;
		}

		if (this.silentGain) {
			this.silentGain.disconnect();
			this.silentGain = null;
		}

		this.analyser = null;

		if (this.audioContext && this.audioContext.state !== 'closed') {
			this.audioContext.close().catch(() => {});
			this.audioContext = null;
		}

		if (this.stream) {
			this.stream.getTracks().forEach((t) => t.stop());
			this.stream = null;
		}

		this._activeNotes = new Set<number>();
		this.hadEnergyOnce = false;
		this.levelPeakRMS = 0.03;
		this.isAnalyzing = false;
		this.silenceFrames = 0;
		this.ringWriteIndex = 0;
		this.ringBufferFilled = false;
		this.setState('idle');
	}

	// ─── Private ────────────────────────────────────────────────

	private setState(state: AudioInputState): void {
		this._state = state;
		this.onStateChange?.(state);
	}
}
