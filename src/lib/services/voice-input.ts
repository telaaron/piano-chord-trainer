// ══════════════════════════════════════════════════════════════════════════════
// Voice input — the mic for singing one note at a time.
//
// getUserMedia → AnalyserNode → YIN (engine/pitch.ts) every 50 ms → a note once
// it has held ~200 ms. No ML model and no download, so it is ready the moment
// the mic opens and doesn't depend on WebGL/tfjs the way basic-pitch does.
// basic-pitch (audio-input.ts) stays for chords played on a piano.
//
// Same surface as AudioInputService where SingInput uses it: onConnection,
// onNotes, init, getLevel, suppress, destroy.
// ══════════════════════════════════════════════════════════════════════════════

import { detectPitch, freqToMidi, NoteStabilizer } from '$lib/engine/pitch';
import type { AudioInputState } from './audio-input';

const FRAME_MS = 50;
const HOLD_FRAMES = 4;

export class VoiceInputService {
	private stream: MediaStream | null = null;
	private ctx: AudioContext | null = null;
	private source: MediaStreamAudioSourceNode | null = null;
	private analyser: AnalyserNode | null = null;
	private sink: GainNode | null = null;
	private frame: Float32Array<ArrayBuffer> | null = null;
	private timer: ReturnType<typeof setInterval> | null = null;
	private stabilizer = new NoteStabilizer(HOLD_FRAMES);
	private suppressUntil = 0;
	private current: number | null = null;
	private lastRms = 0;
	private peakRms = 0.03;
	private _state: AudioInputState = 'idle';
	private onStateChange: ((s: AudioInputState) => void) | null = null;
	private onNoteChange: ((notes: Set<number>) => void) | null = null;

	get state(): AudioInputState {
		return this._state;
	}

	onConnection(cb: (s: AudioInputState) => void): void {
		this.onStateChange = cb;
	}

	/** Called with the held note ({midi}) when it changes, or an empty set when it stops. */
	onNotes(cb: (notes: Set<number>) => void): void {
		this.onNoteChange = cb;
	}

	/** Ignore the mic for a while (e.g. while a reference chord still rings in the room). */
	suppress(durationMs = 1500): void {
		this.suppressUntil = Date.now() + durationMs;
		this.emit(null);
	}

	async init(): Promise<boolean> {
		if (this._state === 'listening') return true;
		if (typeof navigator === 'undefined' || !navigator.mediaDevices?.getUserMedia) {
			this.setState('unsupported');
			return false;
		}
		this.setState('requesting');
		try {
			this.stream = await navigator.mediaDevices.getUserMedia({
				audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: true },
			});
			const AudioCtx =
				window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
			this.ctx = new AudioCtx();
			if (this.ctx.state === 'suspended') await this.ctx.resume();
			this.source = this.ctx.createMediaStreamSource(this.stream);
			this.analyser = this.ctx.createAnalyser();
			// ~45 ms at 44.1/48 kHz: two periods of the lowest note searched (70 Hz).
			this.analyser.fftSize = 2048;
			this.source.connect(this.analyser);
			// Some engines only pull audio through nodes that reach the destination;
			// a muted gain keeps the analyser fed without sending the mic to the speakers.
			this.sink = this.ctx.createGain();
			this.sink.gain.value = 0;
			this.analyser.connect(this.sink);
			this.sink.connect(this.ctx.destination);
			this.frame = new Float32Array(this.analyser.fftSize);
			this.timer = setInterval(() => this.tick(), FRAME_MS);
			this.setState('listening');
			return true;
		} catch (err) {
			const name = (err as DOMException)?.name;
			if (name === 'NotAllowedError' || name === 'PermissionDeniedError') this.setState('denied');
			else {
				console.warn('[VoiceInput] Microphone error:', err);
				this.setState('error');
			}
			this.release();
			return false;
		}
	}

	/** Input level 0–1 for a meter, auto-scaled to the mic (as AudioInputService). */
	getLevel(): number {
		const raw = this.lastRms;
		this.peakRms = raw > this.peakRms ? raw * 0.12 + this.peakRms * 0.88 : this.peakRms * 0.9998;
		return Math.min((raw / Math.max(this.peakRms, 0.01)) * 0.6, 1);
	}

	destroy(): void {
		this.release();
		this.emit(null);
		this.setState('idle');
	}

	private tick(): void {
		if (!this.analyser || !this.frame || !this.ctx) return;
		this.analyser.getFloatTimeDomainData(this.frame);
		const pitch = detectPitch(this.frame, this.ctx.sampleRate);
		this.lastRms = pitch?.rms ?? rms(this.frame);
		if (Date.now() < this.suppressUntil) {
			this.stabilizer.push(null);
			return;
		}
		this.emit(this.stabilizer.push(pitch ? freqToMidi(pitch.freq) : null));
	}

	private emit(note: number | null): void {
		if (note === this.current) return;
		this.current = note;
		this.onNoteChange?.(note === null ? new Set() : new Set([note]));
	}

	private release(): void {
		if (this.timer) clearInterval(this.timer);
		this.timer = null;
		this.source?.disconnect();
		this.source = null;
		this.analyser?.disconnect();
		this.analyser = null;
		this.sink?.disconnect();
		this.sink = null;
		this.frame = null;
		if (this.ctx && this.ctx.state !== 'closed') this.ctx.close().catch(() => {});
		this.ctx = null;
		this.stream?.getTracks().forEach((t) => t.stop());
		this.stream = null;
		this.stabilizer = new NoteStabilizer(HOLD_FRAMES);
		this.lastRms = 0;
	}

	private setState(s: AudioInputState): void {
		this._state = s;
		this.onStateChange?.(s);
	}
}

function rms(frame: Float32Array): number {
	let sum = 0;
	for (let i = 0; i < frame.length; i++) sum += frame[i] * frame[i];
	return Math.sqrt(sum / frame.length);
}
