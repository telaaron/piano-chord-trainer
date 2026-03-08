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
//   • Shares the SoundPreset type from audio.ts for consistency.
//   • Persists enabled / volume / preset in localStorage.
// ══════════════════════════════════════════════════════════════════════════════

import type * as ToneType from 'tone';
import type { SoundPreset } from './audio';

// ─── Lazy Tone singleton (shared with audio.ts via ES module cache) ─────────
let _tone: typeof ToneType | null = null;

async function getTone(): Promise<typeof ToneType> {
	if (!_tone) {
		_tone = await import('tone');
	}
	return _tone;
}

// ─── Salamander samples (same CDN URLs as audio.ts) ─────────────────────────
const SALAMANDER_SAMPLES: Record<string, string> = {
	C2: 'C2.mp3',     'D#2': 'Ds2.mp3', 'F#2': 'Fs2.mp3', A2: 'A2.mp3',
	C3: 'C3.mp3',     'D#3': 'Ds3.mp3', 'F#3': 'Fs3.mp3', A3: 'A3.mp3',
	C4: 'C4.mp3',     'D#4': 'Ds4.mp3', 'F#4': 'Fs4.mp3', A4: 'A4.mp3',
	C5: 'C5.mp3',     'D#5': 'Ds5.mp3', 'F#5': 'Fs5.mp3', A5: 'A5.mp3',
	C6: 'C6.mp3',
};
const SALAMANDER_BASE_URL = 'https://tonejs.github.io/audio/salamander/';

// ─── Synth configs (mirror of audio.ts presets) ─────────────────────────────
/* eslint-disable @typescript-eslint/no-explicit-any */
interface SynthPresetConfig {
	synthType: 'Synth' | 'FMSynth';
	config: Record<string, any>;
}

const SYNTH_CONFIGS: Record<Exclude<SoundPreset, 'grand-piano'>, SynthPresetConfig> = {
	'electric-piano': {
		synthType: 'FMSynth',
		config: {
			harmonicity: 3.01,
			modulationIndex: 2,
			oscillator: { type: 'sine' },
			modulation: { type: 'sine' },
			envelope:           { attack: 0.005, decay: 0.8,  sustain: 0.15, release: 1.2 },
			modulationEnvelope: { attack: 0.002, decay: 0.4,  sustain: 0.2,  release: 0.8 },
			volume: -8,
		},
	},
	'vibraphone': {
		synthType: 'FMSynth',
		config: {
			harmonicity: 6,
			modulationIndex: 8,
			oscillator: { type: 'sine' },
			modulation: { type: 'square' },
			envelope:           { attack: 0.001, decay: 1.8,  sustain: 0.02, release: 2.5 },
			modulationEnvelope: { attack: 0.002, decay: 0.6,  sustain: 0.1,  release: 1.5 },
			volume: -10,
		},
	},
	'organ': {
		synthType: 'Synth',
		config: {
			oscillator: { type: 'custom', partials: [1, 0.8, 0.6, 0.3, 0.2, 0.1, 0.05, 0.02] },
			envelope: { attack: 0.01, decay: 0.3, sustain: 0.9, release: 0.1 },
			volume: -8,
		},
	},
	'synth-pad': {
		synthType: 'Synth',
		config: {
			oscillator: { type: 'fatsawtooth', spread: 20, count: 3 },
			envelope: { attack: 0.2, decay: 0.5, sustain: 0.6, release: 2.5 },
			volume: -12,
		},
	},
};
/* eslint-enable @typescript-eslint/no-explicit-any */

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
	private instrument: ToneType.PolySynth | ToneType.Sampler | null = null;
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

	// Samples loading flag
	private _samplesLoading = false;

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
		if (this.instrument && !this._samplesLoading) {
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
		const T = await getTone();
		await T.start();
		const ctx = T.getContext().rawContext as AudioContext;
		if (ctx.state === 'suspended') {
			await ctx.resume();
		}
		this.createInstrument();
		if (this._preset === 'grand-piano' && this._samplesLoading) {
			await T.loaded();
		}
	}

	private createInstrument(): void {
		if (this.instrument) return;
		const T = _tone!;

		// Volume node for independent level control
		this.volume = new T.Volume(this._volume).toDestination();
		this.reverb = new T.Reverb({ decay: 2.0, wet: 0.15 }).connect(this.volume);

		if (this._preset === 'grand-piano') {
			this._samplesLoading = true;
			this.instrument = new T.Sampler({
				urls: SALAMANDER_SAMPLES,
				baseUrl: SALAMANDER_BASE_URL,
				release: 1,
				onload: () => { this._samplesLoading = false; },
				onerror: (err: Error) => {
					console.error('[midi-sound] Failed to load piano samples:', err);
					this._samplesLoading = false;
				},
			}).connect(this.reverb);
		} else {
			const cfg = SYNTH_CONFIGS[this._preset as Exclude<SoundPreset, 'grand-piano'>];
			const SynthClass = cfg.synthType === 'FMSynth' ? T.FMSynth : T.Synth;
			// eslint-disable-next-line @typescript-eslint/no-explicit-any
			const synth = new T.PolySynth(SynthClass as any, cfg.config);
			synth.maxPolyphony = 16;
			this.instrument = synth;
			this.instrument.connect(this.reverb);
		}
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
		this._samplesLoading = false;
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
