// ══════════════════════════════════════════════════════════════════════════════
// MIDI Live-Sound Engine — plays audio for incoming MIDI notes so that
// controller keyboards without built-in sounds produce audible tones.
//
// Architecture:
//   • Owns a SEPARATE Tone.js PolySynth / Sampler (independent from the
//     playback instrument in audio.ts) so live playing never conflicts
//     with chord-preview or metronome playback.
//   • Uses triggerAttack / triggerRelease (not triggerAttackRelease) for
//     natural sustain while keys are held.
//   • Supports sustain pedal (MIDI CC 64).
//   • Builds its instrument through audio-engine.ts, which shares the piano
//     samples with chord playback and falls back to a synth if they fail.
//   • Persists enabled / volume / preset in localStorage.
// ══════════════════════════════════════════════════════════════════════════════

import type * as ToneType from 'tone';
import { getTone, startAudio, createInstrument, type Instrument, type SoundPreset } from './audio-engine';

// ─── MIDI note → Tone.js note name ─────────────────────────────────────────
const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

function midiToNoteName(midi: number): string {
	const octave = Math.floor(midi / 12) - 1;
	const name = NOTE_NAMES[midi % 12];
	return `${name}${octave}`;
}

// ─── Persistence ────────────────────────────────────────────────────────────
const LS_KEY = 'midiSound';
const LS_DEVICES_KEY = 'midiSoundDevices';

interface MidiSoundSettings {
	enabled: boolean;
	volume: number;      // dB, -40 to 0
	preset: SoundPreset;
}

/** Per-device override — only stores `enabled` flag, rest is global */
interface DeviceSoundPref {
	enabled: boolean;
}

function loadSettings(): MidiSoundSettings {
	try {
		const raw = localStorage.getItem(LS_KEY);
		if (raw) {
			const parsed = JSON.parse(raw);
			return {
				enabled: parsed.enabled ?? false,
				volume: typeof parsed.volume === 'number' ? parsed.volume : -6,
				preset: parsed.preset ?? 'grand-piano',
			};
		}
	} catch { /* ignore */ }
	return { enabled: false, volume: -6, preset: 'grand-piano' };
}

function saveSettings(s: MidiSoundSettings): void {
	try {
		localStorage.setItem(LS_KEY, JSON.stringify(s));
	} catch { /* quota exceeded etc */ }
}

function loadDevicePrefs(): Record<string, DeviceSoundPref> {
	try {
		const raw = localStorage.getItem(LS_DEVICES_KEY);
		if (raw) return JSON.parse(raw);
	} catch { /* ignore */ }
	return {};
}

function saveDevicePrefs(prefs: Record<string, DeviceSoundPref>): void {
	try {
		localStorage.setItem(LS_DEVICES_KEY, JSON.stringify(prefs));
	} catch { /* quota exceeded etc */ }
}

// ══════════════════════════════════════════════════════════════════════════════
//  MidiSoundEngine
// ══════════════════════════════════════════════════════════════════════════════

export class MidiSoundEngine {
	private instrument: Instrument | null = null;
	private reverb: ToneType.Reverb | null = null;
	private volume: ToneType.Volume | null = null;
	private _enabled: boolean;
	private _volume: number;
	private _preset: SoundPreset;

	// Per-device tracking
	private _currentDeviceId: string | null = null;
	private _devicePrefs: Record<string, DeviceSoundPref>;

	// Sustain pedal state
	private _sustainDown = false;
	private _sustainedNotes = new Set<number>();  // notes physically released but held by pedal

	// Track which notes are physically held down (for sustain pedal logic)
	private _heldNotes = new Set<number>();

	// Initialization guard
	private _initPromise: Promise<void> | null = null;

	constructor() {
		const settings = loadSettings();
		this._enabled = settings.enabled;
		this._volume = settings.volume;
		this._preset = settings.preset;
		this._devicePrefs = loadDevicePrefs();
	}

	// ─── Public API: state ─────────────────────────────────────

	get enabled(): boolean {
		return this._enabled;
	}

	set enabled(v: boolean) {
		this._enabled = v;
		this.persist();
		if (this._currentDeviceId) {
			this._devicePrefs[this._currentDeviceId] = {
				...this._devicePrefs[this._currentDeviceId],
				enabled: v,
			};
			saveDevicePrefs(this._devicePrefs);
		}
		if (!v) {
			this.releaseAllNow();
		}
	}

	/**
	 * Switch to a MIDI device.  Loads the per-device enabled pref
	 * (or falls back to the global default for unknown devices).
	 * Returns the effective `enabled` state for convenience.
	 */
	setDevice(deviceId: string | null): boolean {
		this.releaseAllNow();
		this._currentDeviceId = deviceId;
		if (deviceId && this._devicePrefs[deviceId] !== undefined) {
			this._enabled = this._devicePrefs[deviceId].enabled;
		}
		// For unknown devices keep current _enabled as default
		return this._enabled;
	}

	get volumeDb(): number {
		return this._volume;
	}

	set volumeDb(v: number) {
		this._volume = Math.max(-40, Math.min(0, v));
		if (this.volume) {
			this.volume.volume.value = this._volume;
		}
		this.persist();
	}

	get preset(): SoundPreset {
		return this._preset;
	}

	set preset(p: SoundPreset) {
		if (p === this._preset && this.instrument) return;
		this._preset = p;
		this.disposeInstrument();
		this.persist();
	}

	// ─── Public API: note events ───────────────────────────────

	/**
	 * Called on MIDI Note-On.  Triggers a sound immediately.
	 * First call lazy-initializes the audio engine (tiny latency hit).
	 */
	noteOn(midiNote: number, velocity: number): void {
		if (!this._enabled) return;
		this._heldNotes.add(midiNote);
		// Remove from sustained set if re-struck while pedal is down
		this._sustainedNotes.delete(midiNote);

		const noteName = midiToNoteName(midiNote);
		const vel = velocity / 127;

		// Hot path: instrument ready → fire immediately
		if (this.instrument) {
			this.triggerAttack(noteName, vel);
			return;
		}

		// Cold path: first note → init, then play
		this.ensureInit().then(() => {
			// Re-check: key might have been released during init
			if (this._heldNotes.has(midiNote)) {
				this.triggerAttack(noteName, vel);
			}
		});
	}

	/**
	 * Called on MIDI Note-Off.  Releases the note (unless sustain pedal is down).
	 */
	noteOff(midiNote: number): void {
		if (!this._enabled) return;
		this._heldNotes.delete(midiNote);

		if (this._sustainDown) {
			// Pedal held — keep the note ringing, track it for later release
			this._sustainedNotes.add(midiNote);
			return;
		}

		const noteName = midiToNoteName(midiNote);
		this.triggerRelease(noteName);
	}

	/**
	 * Called on MIDI CC message.  Handles sustain pedal (CC 64).
	 */
	controlChange(cc: number, value: number): void {
		if (!this._enabled) return;
		if (cc !== 64) return;  // only sustain pedal

		if (value >= 64) {
			// Pedal down
			this._sustainDown = true;
		} else {
			// Pedal up — release all sustained notes
			this._sustainDown = false;
			for (const midiNote of this._sustainedNotes) {
				if (!this._heldNotes.has(midiNote)) {
					this.triggerRelease(midiToNoteName(midiNote));
				}
			}
			this._sustainedNotes.clear();
		}
	}

	/**
	 * Release all notes immediately (e.g. when disabling sound or navigating away).
	 */
	releaseAllNow(): void {
		this._heldNotes.clear();
		this._sustainedNotes.clear();
		this._sustainDown = false;
		if (!this.instrument) return;

		if ('releaseAll' in this.instrument && typeof this.instrument.releaseAll === 'function') {
			(this.instrument as ToneType.PolySynth).releaseAll();
		}
	}

	/**
	 * Dispose all resources.  Call when leaving the page.
	 */
	dispose(): void {
		this.releaseAllNow();
		this.disposeInstrument();
	}

	// ─── Private helpers ───────────────────────────────────────

	private triggerAttack(noteName: string, velocity: number): void {
		if (!this.instrument) return;
		try {
			if ('triggerAttack' in this.instrument) {
				(this.instrument as ToneType.PolySynth).triggerAttack(noteName, undefined, velocity);
			}
		} catch {
			// Catch max-polyphony or disposed-instrument errors silently
		}
	}

	private triggerRelease(noteName: string): void {
		if (!this.instrument) return;
		try {
			if ('triggerRelease' in this.instrument) {
				(this.instrument as ToneType.PolySynth).triggerRelease(noteName);
			}
		} catch {
			// Catch errors silently
		}
	}

	private async ensureInit(): Promise<void> {
		if (this._initPromise) return this._initPromise;
		this._initPromise = this._doInit();
		try {
			await this._initPromise;
		} finally {
			this._initPromise = null;
		}
	}

	private async _doInit(): Promise<void> {
		await startAudio();
		const T = await getTone();
		const preset = this._preset;
		// The engine shares the piano samples with chord playback and hands back
		// a synth if they are missing, so live playing never goes silent.
		const { instrument } = await createInstrument(preset, 16);
		// Preset switched (or engine disposed) while loading — drop this one.
		if (preset !== this._preset || this.instrument) {
			instrument.dispose();
			return;
		}
		// Volume node for independent level control
		this.volume = new T.Volume(this._volume).toDestination();
		this.reverb = new T.Reverb({ decay: 2.0, wet: 0.15 }).connect(this.volume);
		this.instrument = instrument.connect(this.reverb);
	}

	private disposeInstrument(): void {
		if (this.instrument) {
			this.instrument.dispose();
			this.instrument = null;
		}
		if (this.reverb) {
			this.reverb.dispose();
			this.reverb = null;
		}
		if (this.volume) {
			this.volume.dispose();
			this.volume = null;
		}
	}

	private persist(): void {
		saveSettings({
			enabled: this._enabled,
			volume: this._volume,
			preset: this._preset,
		});
		if (this._currentDeviceId) {
			this._devicePrefs[this._currentDeviceId] = {
				...this._devicePrefs[this._currentDeviceId],
				enabled: this._enabled,
			};
			saveDevicePrefs(this._devicePrefs);
		}
	}
}
