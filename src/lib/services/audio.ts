// Audio playback using Tone.js – plays chord voicings with configurable sound
//
// Tone.js (~200 kB) is imported lazily on first use so it never ends up in
// the homepage bundle and does not block Time-to-Interactive on /train.
import type * as ToneType from 'tone';

// ─── Lazy Tone singleton ─────────────────────────────────────────────────────
let _tone: typeof ToneType | null = null;

async function getTone(): Promise<typeof ToneType> {
	if (!_tone) {
		_tone = await import('tone');
	}
	return _tone;
}

// ─── Sound Presets ──────────────────────────────────────────

export type SoundPreset = 'electric-piano' | 'warm-keys' | 'bell' | 'soft-pad' | 'bright-piano';

export const SOUND_PRESETS: Record<SoundPreset, { label: string; description: string }> = {
	'electric-piano': { label: 'Electric Piano', description: 'Classic Rhodes-style EP' },
	'warm-keys': { label: 'Warm Keys', description: 'Soft, mellow tone' },
	'bell': { label: 'Bell', description: 'Clean bell-like attack' },
	'soft-pad': { label: 'Soft Pad', description: 'Sustained, ambient' },
	'bright-piano': { label: 'Bright Piano', description: 'Crisp, articulated' },
};

/* eslint-disable @typescript-eslint/no-explicit-any */
const PRESET_CONFIGS: Record<SoundPreset, Record<string, any>> = {
	'electric-piano': {
		oscillator: { type: 'fmsine', modulationType: 'sine', modulationIndex: 2, harmonicity: 3.01 },
		envelope: { attack: 0.005, decay: 1.0, sustain: 0.2, release: 1.5 },
		volume: -8,
	},
	'warm-keys': {
		oscillator: { type: 'sine' },
		envelope: { attack: 0.01, decay: 0.8, sustain: 0.3, release: 2.0 },
		volume: -6,
	},
	'bell': {
		oscillator: { type: 'fmsine', modulationType: 'square', modulationIndex: 8, harmonicity: 6 },
		envelope: { attack: 0.001, decay: 1.5, sustain: 0.05, release: 2.0 },
		volume: -10,
	},
	'soft-pad': {
		oscillator: { type: 'fatsawtooth', spread: 20, count: 3 },
		envelope: { attack: 0.15, decay: 0.5, sustain: 0.6, release: 2.5 },
		volume: -12,
	},
	'bright-piano': {
		oscillator: { type: 'fmsine', modulationType: 'sine', modulationIndex: 4, harmonicity: 2 },
		envelope: { attack: 0.002, decay: 0.6, sustain: 0.1, release: 1.0 },
		volume: -7,
	},
};
/* eslint-enable @typescript-eslint/no-explicit-any */

let synth: ToneType.PolySynth | null = null;
let currentPreset: SoundPreset = 'electric-piano';
let reverb: ToneType.Reverb | null = null;
let started = false;

/**
 * Ensure AudioContext is running (must be called from a user-interaction handler).
 * Calls Tone.start() which internally invokes AudioContext.resume(), then explicitly
 * resumes the raw context as a belt-and-braces measure for strict autoplay policies.
 */
async function ensureStarted(): Promise<void> {
	const T = await getTone();
	await T.start();
	const ctx = T.getContext().rawContext as AudioContext;
	if (ctx.state === 'suspended') {
		await ctx.resume();
	}
	started = true;
}

function getSynth(): ToneType.PolySynth {
	if (!synth) {
		const T = _tone!;
		const config = PRESET_CONFIGS[currentPreset];
		synth = new T.PolySynth(T.Synth, config).toDestination();
		synth.maxPolyphony = 8;

		// Add subtle reverb for ambience
		reverb = new T.Reverb({ decay: 2.0, wet: 0.2 }).toDestination();
		synth.connect(reverb);
	}
	return synth;
}

/** Switch sound preset. Disposes old synth so next play uses new config. */
export function setSoundPreset(preset: SoundPreset): void {
	if (preset === currentPreset && synth) return;
	currentPreset = preset;
	disposeAudio();
}

/** Get current sound preset */
export function getSoundPreset(): SoundPreset {
	return currentPreset;
}

/**
 * Map note names (e.g. "C", "Db", "F#") to Tone.js-friendly names with octave.
 * Notes are placed ascending from octave 3 (typical jazz left-hand voicing range).
 * Each note is placed above the previous one for a musical spread.
 */
function notesToToneNames(notes: string[]): string[] {
	function semitone(note: string): number {
		const map: Record<string, number> = {
			'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
			'E': 4, 'Fb': 4, 'E#': 5, 'F': 5, 'F#': 6, 'Gb': 6,
			'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10,
			'B': 11, 'Cb': 11, 'B#': 0
		};
		return map[note] ?? 0;
	}

	const result: string[] = [];
	let octave = 3;
	let prevSemi = -1;

	for (const note of notes) {
		const semi = semitone(note);
		if (prevSemi !== -1 && semi <= prevSemi) {
			octave++;
		}
		result.push(`${note}${octave}`);
		prevSemi = semi;
	}

	return result;
}

/**
 * Play a chord voicing.
 * @param notes - Array of note names like ["C", "E", "G", "B"]
 * @param duration - Duration string (e.g. "2n" = half note, "1n" = whole note)
 */
export async function playChord(notes: string[], duration: string = '2n'): Promise<void> {
	const T = await getTone();
	await ensureStarted();
	const s = getSynth();
	// Stop any currently playing notes immediately before starting new ones
	s.releaseAll(T.now());
	const toneNotes = notesToToneNames(notes);
	// Schedule slightly in the future to ensure releaseAll completes
	const t = T.now() + 0.02;
	s.triggerAttackRelease(toneNotes, duration, t);
}

/**
 * Play a single note.
 * @param note - Note name with octave, e.g. "C4"
 */
export async function playNote(note: string, duration: string = '8n'): Promise<void> {
	await ensureStarted();
	const s = getSynth();
	s.triggerAttackRelease(note, duration);
}

/** Release all playing notes */
export function stopAll(): void {
	if (synth) {
		synth.releaseAll();
	}
}

/** Clean up synth */
export function disposeAudio(): void {
	if (synth) {
		synth.releaseAll();
		synth.dispose();
		synth = null;
	}
	if (reverb) {
		reverb.dispose();
		reverb = null;
	}
}

// ─── Metronome ──────────────────────────────────────────────

let metronomeLoop: ToneType.Loop | null = null;
let metronomeSynth: ToneType.MembraneSynth | null = null;
let metronomeRunning = false;
let beatCount = 0;
let onBeatCallback: ((beat: number) => void) | null = null;

function getMetronomeSynth(): ToneType.MembraneSynth {
	if (!metronomeSynth) {
		metronomeSynth = new _tone!.MembraneSynth({
			pitchDecay: 0.008,
			octaves: 2,
			envelope: {
				attack: 0.001,
				decay: 0.1,
				sustain: 0,
				release: 0.05,
			},
			volume: -12,
		}).toDestination();
	}
	return metronomeSynth;
}

/**
 * Start metronome at given BPM.
 * @param bpm - Beats per minute
 * @param beatsPerBar - Time signature numerator (default 4)
 * @param onBeat - Callback fired on each beat with beat number (1-based)
 */
export async function startMetronome(
	bpm: number,
	beatsPerBar: number = 4,
	onBeat?: (beat: number) => void,
): Promise<void> {
	const T = await getTone();
	await ensureStarted();
	stopMetronome();

	T.getTransport().bpm.value = bpm;
	beatCount = 0;
	onBeatCallback = onBeat ?? null;

	const click = getMetronomeSynth();

	metronomeLoop = new T.Loop((time) => {
		beatCount++;
		const currentBeat = ((beatCount - 1) % beatsPerBar) + 1;

		// Accent on beat 1
		if (currentBeat === 1) {
			click.triggerAttackRelease('C3', '32n', time);
		} else {
			click.triggerAttackRelease('C4', '32n', time);
		}

		if (onBeatCallback) {
			// Schedule callback slightly after audio for visual sync
			T.getDraw().schedule(() => {
				onBeatCallback!(currentBeat);
			}, time);
		}
	}, '4n');

	metronomeLoop.start(0);
	T.getTransport().start();
	metronomeRunning = true;
}

/** Stop metronome */
export function stopMetronome(): void {
	if (metronomeLoop) {
		metronomeLoop.stop();
		metronomeLoop.dispose();
		metronomeLoop = null;
	}
	// _tone is guaranteed non-null here: stopMetronome is only reachable after
	// startMetronome has awaited getTone(), or on cleanup where nothing is running.
	_tone?.getTransport().stop();
	beatCount = 0;
	metronomeRunning = false;
	onBeatCallback = null;
}

/** Check if metronome is running */
export function isMetronomeRunning(): boolean {
	return metronomeRunning;
}

/** Update metronome BPM live */
export function setMetronomeBpm(bpm: number): void {
	if (_tone) _tone.getTransport().bpm.value = bpm;
}

/** Dispose all audio resources */
export function disposeAll(): void {
	stopMetronome();
	disposeAudio();
	if (metronomeSynth) {
		metronomeSynth.dispose();
		metronomeSynth = null;
	}
}
