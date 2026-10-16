// ══════════════════════════════════════════════════════════════════════════════
// Audio engine — the one place that owns Tone.js, the AudioContext and the
// piano samples. audio.ts (chord playback, drone, metronome) and midi-sound.ts
// (live MIDI sound) build their instruments here instead of each loading Tone,
// fetching samples and handling failures their own way.
//
//   • One lazy Tone import, one context start.
//   • Piano samples are fetched and decoded ONCE and shared by every Sampler.
//   • If the samples fail, the piano preset is voiced by a synth: no silence.
//   • One status (`getAudioStatus` / `onAudioStatus`) the UI can show.
// ══════════════════════════════════════════════════════════════════════════════

import type * as ToneType from 'tone';
import { trackCoachEvent } from './telemetry';

// ─── Presets ────────────────────────────────────────────────────────────────

export type SoundPreset =
	| 'grand-piano'
	| 'electric-piano'
	| 'vibraphone'
	| 'organ'
	| 'synth-pad';

export const SOUND_PRESETS: Record<SoundPreset, { label: string; description: string }> = {
	'grand-piano':    { label: 'Grand Piano',    description: 'Salamander samples — realistic piano' },
	'electric-piano': { label: 'Electric Piano',  description: 'FM synthesis Rhodes tone' },
	'vibraphone':     { label: 'Vibraphone',      description: 'Mellow bell-like mallet sound' },
	'organ':          { label: 'Organ',            description: 'Jazz organ with drawbar harmonics' },
	'synth-pad':      { label: 'Synth Pad',        description: 'Warm sustained pad' },
};

/** What the piano preset is voiced by when its samples are missing. */
const PIANO_FALLBACK: SoundPreset = 'electric-piano';

// ─── Salamander Grand Piano samples (self-hosted, static/audio/piano) ──────
// Octaves 2–6, one sample every minor third; Tone.Sampler repitches between.
const PIANO_SAMPLES: Record<string, string> = {
	C2: 'C2.mp3',     'D#2': 'Ds2.mp3', 'F#2': 'Fs2.mp3', A2: 'A2.mp3',
	C3: 'C3.mp3',     'D#3': 'Ds3.mp3', 'F#3': 'Fs3.mp3', A3: 'A3.mp3',
	C4: 'C4.mp3',     'D#4': 'Ds4.mp3', 'F#4': 'Fs4.mp3', A4: 'A4.mp3',
	C5: 'C5.mp3',     'D#5': 'Ds5.mp3', 'F#5': 'Fs5.mp3', A5: 'A5.mp3',
	C6: 'C6.mp3',
};
const PIANO_BASE_URL = '/audio/piano/';

// ─── Synth presets ──────────────────────────────────────────────────────────

/* eslint-disable @typescript-eslint/no-explicit-any */
export interface SynthPresetConfig {
	synthType: 'Synth' | 'FMSynth';
	config: Record<string, any>;
}

export const SYNTH_CONFIGS: Record<Exclude<SoundPreset, 'grand-piano'>, SynthPresetConfig> = {
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

// ─── Status ─────────────────────────────────────────────────────────────────

/**
 * idle      nothing loaded yet
 * loading   Tone or the piano samples are on their way
 * ready     sound works as asked
 * fallback  sound works, but the piano is voiced by a synth (samples missing)
 * blocked   the browser kept the AudioContext suspended — no sound until a click
 */
export type AudioStatus = 'idle' | 'loading' | 'ready' | 'fallback' | 'blocked';

let status: AudioStatus = 'idle';
const statusListeners = new Set<(s: AudioStatus) => void>();

function setStatus(next: AudioStatus): void {
	if (next === status) return;
	status = next;
	// Only the failures are worth an event: they are what "audio works here,
	// not there" reports are made of.
	if (next === 'fallback' || next === 'blocked') trackCoachEvent('audio_state', { status: next });
	for (const cb of statusListeners) cb(next);
}

export function getAudioStatus(): AudioStatus {
	return status;
}

/** Subscribe to status changes. Returns an unsubscribe function. */
export function onAudioStatus(cb: (s: AudioStatus) => void): () => void {
	statusListeners.add(cb);
	return () => statusListeners.delete(cb);
}

// ─── Tone & context ─────────────────────────────────────────────────────────

let tone: typeof ToneType | null = null;
let tonePromise: Promise<typeof ToneType> | null = null;

/** Tone.js, imported lazily (~200 kB) so it never weighs on first paint. */
export function getTone(): Promise<typeof ToneType> {
	if (tone) return Promise.resolve(tone);
	tonePromise ??= import('tone').then((m) => (tone = m));
	return tonePromise;
}

/** Tone if it has already been imported — for synchronous hot paths. */
export function loadedTone(): typeof ToneType | null {
	return tone;
}

/**
 * Start (or resume) the AudioContext. Must run inside a user gesture the first
 * time. Resolves true when the context is running.
 */
export async function startAudio(): Promise<boolean> {
	if (status === 'idle') setStatus('loading');
	const T = await getTone();
	await T.start();
	const ctx = T.getContext().rawContext as AudioContext;
	if (ctx.state === 'suspended') await ctx.resume();
	const running = ctx.state === 'running';
	if (!running) setStatus('blocked');
	else if (status === 'blocked' || status === 'loading') setStatus(pianoFailed ? 'fallback' : 'ready');
	return running;
}

/**
 * Unlock audio from a click handler — call this FIRST, before any other work.
 *
 * Browsers only honour `AudioContext.resume()` while the user's gesture is
 * still "active". Tone.js is a lazy import, so a first sound that has to
 * download it first spends that activation and the context stays suspended,
 * silently. Safe to call repeatedly; never throws.
 */
export async function unlockAudio(): Promise<void> {
	try {
		await startAudio();
	} catch {
		setStatus('blocked');
	}
}

// ─── Piano samples (shared) ─────────────────────────────────────────────────

let pianoBuffers: ToneType.ToneAudioBuffers | null = null;
let pianoLoad: Promise<boolean> | null = null;
let pianoFailed = false;

/** Fetch and decode the piano samples once. Resolves false if they can't be had. */
function loadPiano(T: typeof ToneType): Promise<boolean> {
	pianoLoad ??= new Promise<boolean>((resolve) => {
		const buffers = new T.ToneAudioBuffers({
			urls: PIANO_SAMPLES,
			baseUrl: PIANO_BASE_URL,
			onload: () => {
				pianoBuffers = buffers;
				resolve(true);
			},
			onerror: (err: Error) => {
				// Fires once per missing file; report and give up on the first.
				if (pianoFailed) return;
				console.error('[audio] Piano samples unavailable, using synth:', err);
				pianoFailed = true;
				resolve(false);
			},
		});
	});
	return pianoLoad;
}

/** True while the piano samples are still on their way. */
export function isPianoLoading(): boolean {
	return pianoLoad !== null && pianoBuffers === null && !pianoFailed;
}

/** The preset that actually sounds for `preset`, given what has loaded. */
export function soundingPreset(preset: SoundPreset): SoundPreset {
	return preset === 'grand-piano' && pianoFailed ? PIANO_FALLBACK : preset;
}

// ─── Instruments ────────────────────────────────────────────────────────────

export type Instrument = ToneType.PolySynth | ToneType.Sampler;

/* eslint-disable @typescript-eslint/no-explicit-any */
function buildSynth(T: typeof ToneType, preset: Exclude<SoundPreset, 'grand-piano'>, polyphony: number): ToneType.PolySynth {
	const cfg = SYNTH_CONFIGS[preset];
	const SynthClass = cfg.synthType === 'FMSynth' ? T.FMSynth : T.Synth;
	const synth = new T.PolySynth(SynthClass as any, cfg.config);
	synth.maxPolyphony = polyphony;
	return synth;
}
/* eslint-enable @typescript-eslint/no-explicit-any */

/**
 * Build a ready-to-play instrument for `preset` (not yet connected anywhere).
 * Waits for the piano samples when needed and falls back to a synth if they
 * fail, so the caller always gets something that makes sound.
 *
 * Returns the instrument and the preset it actually voices.
 */
export async function createInstrument(
	preset: SoundPreset,
	polyphony = 8,
): Promise<{ instrument: Instrument; voiced: SoundPreset }> {
	const T = await getTone();
	if (preset === 'grand-piano' && !pianoFailed) {
		if (status !== 'blocked') setStatus('loading');
		const ok = await loadPiano(T);
		if (ok && pianoBuffers) {
			// Hand the decoded AudioBuffers over: every Sampler plays the same
			// memory, nothing is fetched or decoded twice.
			const urls: Record<string, AudioBuffer> = {};
			for (const note of Object.keys(PIANO_SAMPLES)) urls[note] = pianoBuffers.get(note).get()!;
			const sampler = new T.Sampler({ urls, release: 1 });
			if (status !== 'blocked') setStatus('ready');
			return { instrument: sampler, voiced: 'grand-piano' };
		}
	}
	const voiced = soundingPreset(preset) as Exclude<SoundPreset, 'grand-piano'>;
	if (status !== 'blocked') setStatus(preset === 'grand-piano' ? 'fallback' : 'ready');
	return { instrument: buildSynth(T, voiced, polyphony), voiced };
}

/** Test seam: forget everything loaded, as on a fresh page. */
export function _resetAudioEngineForTests(): void {
	tone = null;
	tonePromise = null;
	pianoBuffers = null;
	pianoLoad = null;
	pianoFailed = false;
	status = 'idle';
	statusListeners.clear();
}
