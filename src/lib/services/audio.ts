// ══════════════════════════════════════════════════════════════════════════════
// Audio playback using Tone.js — chord voicings, metronome & backing tracks
// ══════════════════════════════════════════════════════════════════════════════
//
// Sound presets:
//   grand-piano     Tone.Sampler with Salamander grand piano samples (self-hosted)
//   electric-piano  PolySynth<FMSynth>  — Rhodes-like FM synthesis
//   vibraphone      PolySynth<FMSynth>  — mellow bell mallet sound
//   organ           PolySynth<Synth>    — jazz organ drawbar harmonics
//   synth-pad       PolySynth<Synth>    — warm sustained pad
//
// Tone.js (~200 kB) is imported lazily on first use so it never ends up
// in the homepage bundle and does not block Time-to-Interactive on /train.
import type * as ToneType from 'tone';
import {
	getTone as engineGetTone,
	startAudio,
	createInstrument,
	soundingPreset,
	isPianoLoading,
	SYNTH_CONFIGS,
	type Instrument,
	type SoundPreset,
} from './audio-engine';

// Presets, unlock and status live in the engine; re-exported so callers keep
// importing them from here.
export { SOUND_PRESETS, unlockAudio, getAudioStatus, onAudioStatus, type SoundPreset, type AudioStatus } from './audio-engine';

// ─── Tone (owned by the engine; cached here for the synchronous hot paths) ──
let _tone: typeof ToneType | null = null;

async function getTone(): Promise<typeof ToneType> {
	_tone = await engineGetTone();
	return _tone;
}

// ─── Instrument state ────────────────────────────────────────────────────────
let instrument: Instrument | null = null;
/** Which preset `instrument` actually voices — lets us spot a stale piano Sampler. */
let instrumentPreset: SoundPreset | null = null;
/** Resolves once the instrument for the current preset is built. */
let instrumentBuild: Promise<void> | null = null;
let currentPreset: SoundPreset = 'grand-piano';
let reverb: ToneType.Reverb | null = null;
let started = false;

// Track currently sounding notes so we can release only those (fast)
let activeNotes: string[] = [];

/** Is the installed instrument the right one to play right now? */
function instrumentReady(): boolean {
	return !!_tone && started && !!instrument && instrumentPreset === soundingPreset(currentPreset);
}

// ─── AudioContext bootstrap ─────────────────────────────────────────────────
/** Ensure AudioContext is running (must be called from a user-interaction handler). */
async function ensureStarted(): Promise<void> {
	await getTone();
	await startAudio();
	started = true;
}

// ─── Instrument factory ─────────────────────────────────────────────────────

function createReverb(): ToneType.Reverb {
	const T = _tone!;
	return new T.Reverb({ decay: 2.0, wet: 0.15 }).toDestination();
}

/** The installed instrument. Only call after prepareInstrument() resolved. */
function getInstrument(): Instrument {
	return instrument!;
}

/**
 * Release all currently sounding voices.
 * PolySynth: releaseAll().  Sampler: release only the tracked active notes.
 */
function releaseAllVoices(time?: number): void {
	if (!instrument) return;
	if ('releaseAll' in instrument && typeof instrument.releaseAll === 'function') {
		(instrument as ToneType.PolySynth).releaseAll(time);
	} else if (activeNotes.length > 0) {
		(instrument as ToneType.Sampler).triggerRelease([...activeNotes], time);
	}
	activeNotes = [];
}

// ─── Loading-state API ──────────────────────────────────────────────────────
/** True while the piano samples are being fetched */
export function isSamplesLoading(): boolean {
	return isPianoLoading();
}

// ─── Sound-preset API ───────────────────────────────────────────────────────
/** Switch sound preset.  Disposes old instrument; the next sound builds the new one. */
export function setSoundPreset(preset: SoundPreset): void {
	if (preset === currentPreset && instrument) return;
	currentPreset = preset;
	disposeAudio();
	// Start building right away so the piano samples are loading before the first chord.
	if (_tone && started) prepareInstrument().catch(() => {});
}

/** Current sound preset id */
export function getSoundPreset(): SoundPreset {
	return currentPreset;
}

// ─── Note mapping ───────────────────────────────────────────────────────────
/**
 * Map note names (e.g. "C", "Db", "F#") to Tone.js-friendly names with octave.
 * Notes are placed ascending from octave 3 (typical jazz left-hand voicing range).
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

// ─── Playback ───────────────────────────────────────────────────────────────

/**
 * Cold-path setup shared by every playback entry point: load Tone, start the
 * context and build the instrument for the current preset. The engine waits
 * for the piano samples and hands back a synth if they fail, so the caller
 * always gets a sound instead of silence.
 */
async function prepareInstrument(): Promise<void> {
	await ensureStarted();
	// A preset switch during a build drops that build; try again, a bounded number of times.
	for (let attempt = 0; attempt < 3 && !instrumentReady(); attempt++) {
		await buildInstrument();
	}
}

async function buildInstrument(): Promise<void> {
	if (!instrumentBuild) {
		const preset = currentPreset;
		instrumentBuild = createInstrument(preset, 8)
			.then(({ instrument: built, voiced }) => {
				// The preset changed while we were loading — drop this one.
				if (preset !== currentPreset) {
					built.dispose();
					return;
				}
				disposeInstrumentOnly();
				if (!reverb) reverb = createReverb();
				built.connect(reverb);
				instrument = built;
				instrumentPreset = voiced;
			})
			.finally(() => {
				instrumentBuild = null;
			});
	}
	await instrumentBuild;
}

function disposeInstrumentOnly(): void {
	releaseAllVoices();
	if (instrument) {
		instrument.dispose();
		instrument = null;
		instrumentPreset = null;
	}
}

/**
 * SYNCHRONOUS chord trigger — zero async overhead.  Only works after
 * ensureStarted() has been called at least once (which happens on first
 * user interaction via playChord or startMetronome).
 *
 * @param toneNotes – octave-qualified note names, e.g. ["C3","E3","G3","B3"]
 * @param duration  – Tone.js duration string
 * @param time      – precise audio-context time (from Transport callback).
 *                    If omitted, uses Tone.now() (= "now").
 */
function triggerChordSync(toneNotes: string[], duration: string, time?: number, velocities?: number[]): void {
	const inst = getInstrument();
	const t = time ?? _tone!.now();

	// Release previous notes at exactly the same instant
	releaseAllVoices(t);
	activeNotes = toneNotes;

	if (velocities) {
		// One call per note: Tone takes a single velocity per call.
		toneNotes.forEach((n, i) => inst.triggerAttackRelease(n, duration, t, velocities[i] ?? 1));
		return;
	}

	if ('triggerAttackRelease' in inst) {
		// PolySynth — takes array directly
		(inst as ToneType.PolySynth).triggerAttackRelease(toneNotes, duration, t);
	} else {
		// Sampler — triggerAttackRelease also takes array
		(inst as ToneType.Sampler).triggerAttackRelease(toneNotes, duration, t);
	}
}

/**
 * Play a chord voicing.  Works in two modes:
 *
 * HOT PATH (after init):  Entirely synchronous — no await, no microtask
 * delays.  The chord fires at Tone.now() with zero overhead.
 *
 * COLD PATH (first call): Loads Tone.js, starts AudioContext, waits for
 * Sampler samples if needed.  Subsequent calls take the hot path.
 */
export async function playChord(
	notes: string[],
	duration: string = '2n',
	{ forEar = false }: { forEar?: boolean } = {},
): Promise<void> {
	let toneNotes = notesToToneNames(notes);
	let velocities: number[] | undefined;
	if (forEar) ({ notes: toneNotes, velocities } = earVoicing(toneNotes));

	// ── Hot path: everything ready → fire synchronously ──
	if (instrumentReady()) {
		triggerChordSync(toneNotes, duration, undefined, velocities);
		return;
	}

	// ── Cold path: first call or samples still loading ──
	await prepareInstrument();
	triggerChordSync(toneNotes, duration, undefined, velocities);
}

/**
 * Voicing for ear training: the root doubled an octave below and played
 * louder than the upper voices.
 *
 * Played flat, a close-position chord puts the 7th on top, and the ear hears
 * the top voice and higher pitches as loudest: rendered at equal velocity, the
 * maj7 of Cmaj7 measures ~6.5 dB(A) above the root, more on phone speakers. The
 * listener then has to work down from the 7th to find the root. A bass root
 * under a softer upper structure is how a jazz bassist and pianist voice it.
 *
 * @param toneNotes octave-qualified notes, root first (as notesToToneNames gives)
 */
export function earVoicing(toneNotes: string[]): { notes: string[]; velocities: number[] } {
	const [root, ...upper] = toneNotes;
	const m = /^([A-G][#b]?)(-?\d+)$/.exec(root);
	const bass = m ? `${m[1]}${Number(m[2]) - 1}` : root;
	return {
		notes: [bass, root, ...upper],
		velocities: [0.8, 0.9, ...upper.map(() => 0.4)],
	};
}

/**
 * Transport-synced chord playback — for use inside metronome/backing-track
 * callbacks that receive the precise audio-context `time` parameter.
 *
 * This fires the chord at EXACTLY the same instant as the metronome click,
 * with zero JS-thread latency.  Must only be called after audio is started.
 *
 * @param notes    – note names WITHOUT octave, e.g. ["C","E","G","B"]
 * @param duration – Tone.js duration string
 * @param time     – the `time` value from a Tone.Loop / Sequence callback
 */
export function playChordAtTime(notes: string[], duration: string, time: number): void {
	if (!_tone || !started || !instrument) return;
	if (!instrumentReady()) return; // still loading, or a stale instrument the next cold path swaps
	const toneNotes = notesToToneNames(notes);
	triggerChordSync(toneNotes, duration, time);
}

/**
 * Play a single note (with octave, e.g. "C4").
 */
export async function playNote(note: string, duration: string = '8n'): Promise<void> {
	// Hot path
	if (instrumentReady()) {
		const inst = getInstrument();
		if ('triggerAttackRelease' in inst) {
			(inst as ToneType.PolySynth).triggerAttackRelease(note, duration);
		} else {
			(inst as ToneType.Sampler).triggerAttackRelease(note, duration);
		}
		return;
	}
	// Cold path
	await prepareInstrument();
	const inst = getInstrument();
	if ('triggerAttackRelease' in inst) {
		(inst as ToneType.PolySynth).triggerAttackRelease(note, duration);
	} else {
		(inst as ToneType.Sampler).triggerAttackRelease(note, duration);
	}
}

/**
 * Play a chord one note at a time (arpeggio), low to high.
 * Notes are bare names (e.g. ["E","G","B","D"]); octaves are assigned the same
 * ascending way as playChord. `stepMs` is the gap between notes.
 */
export async function playArpeggio(notes: string[], stepMs = 180, noteDuration = '4n'): Promise<void> {
	const toneNotes = notesToToneNames(notes);
	// Ensure audio is warm before the first note so timing is even.
	await prepareInstrument();
	const inst = getInstrument();
	toneNotes.forEach((n, i) => {
		setTimeout(() => {
			// Both PolySynth and Sampler take a single note here. This used to
			// check for PolySynth only, so with the default piano it was silent.
			inst.triggerAttackRelease(n, noteDuration);
		}, i * stepMs);
	});
}

/** Release all currently sounding notes */
export function stopAll(): void {
	releaseAllVoices();
}

/** Dispose chord / note instrument (keeps metronome & backing track intact) */
export function disposeAudio(): void {
	releaseAllVoices();
	activeNotes = [];
	if (instrument) {
		instrument.dispose();
		instrument = null;
		instrumentPreset = null;
	}
	if (reverb) {
		reverb.dispose();
		reverb = null;
	}
}

// ══════════════════════════════════════════════════════════════════════════════
//  Drone — a held reference tone for singing against (To-Go mode)
// ══════════════════════════════════════════════════════════════════════════════
//
// The reference is a PIANO, struck repeatedly — not a held pad.
//
// A sawtooth pad sustains for free, which is why it was chosen, but it is a
// harsh thing to sing against: its upper partials beat against the voice and
// singers reported it as unpleasant. A pianist giving you a note does not hold
// a synthesiser under it; they strike the key again when it fades. So this
// re-strikes an FM electric piano on a timer.
//
// Electric piano rather than the grand: the grand is a sampler that fetches 17
// files, and a reference tone must sound the instant it is asked for.

let droneSynth: ToneType.PolySynth | null = null;
let droneNote: string | null = null;
/** Re-strike timer — the reference is struck, not held. */
let droneTimer: ReturnType<typeof setInterval> | null = null;
/** Guards against a stopDrone() that lands while startDrone() is still awaiting. */
let droneGeneration = 0;

/* eslint-disable @typescript-eslint/no-explicit-any */
function getDroneSynth(): ToneType.PolySynth {
	if (!droneSynth) {
		const T = _tone!;
		const cfg = SYNTH_CONFIGS['electric-piano'];
		// Longer release than the drill preset: a reference note should ring out
		// rather than stop dead, so consecutive strikes overlap into one tone.
		droneSynth = new T.PolySynth(T.FMSynth as any, {
			...cfg.config,
			envelope: { attack: 0.005, decay: 1.4, sustain: 0.08, release: 2.2 },
			volume: -14,
		});
		droneSynth.maxPolyphony = 4;
		droneSynth.toDestination();
	}
	return droneSynth;
}
/* eslint-enable @typescript-eslint/no-explicit-any */

/**
 * Hold a reference tone until `stopDrone()`.
 *
 * @param note  bare note name ("Bb") or octave-qualified ("Bb3"). Bare names are
 *              placed in octave 3 — comfortably under most singing ranges.
 */
export async function startDrone(note: string): Promise<void> {
	const toneNote = /\d/.test(note) ? note : `${note}3`;
	const gen = ++droneGeneration;

	await getTone();
	await ensureStarted();
	// A stopDrone() (or another startDrone) landed while we were awaiting — bail.
	if (gen !== droneGeneration) return;

	const synth = getDroneSynth();
	droneNote = toneNote;

	// Strike now, then again every 2.4 s. With a 2.2 s release each strike is
	// still ringing when the next lands, so the reference reads as continuous
	// without ever being a sustained pad.
	const strike = () => {
		if (gen !== droneGeneration) return;
		synth.triggerAttackRelease([toneNote], 2.2);
	};
	strike();
	clearDroneTimer();
	droneTimer = setInterval(strike, 2400);
}

/** Stop the re-strike timer. Separate so both start and stop can call it. */
function clearDroneTimer(): void {
	if (droneTimer !== null) {
		clearInterval(droneTimer);
		droneTimer = null;
	}
}

/** Stop the reference tone. Safe to call when nothing is sounding. */
export function stopDrone(): void {
	// Bump the generation FIRST: a strike already queued checks it and bails,
	// so nothing can sound after this returns.
	droneGeneration++;
	clearDroneTimer();
	if (!droneSynth) {
		droneNote = null;
		return;
	}
	// releaseAll rather than releasing one note: strikes overlap, so several
	// voices may be ringing at once.
	droneSynth.releaseAll();
	droneNote = null;
}

/** Is a reference tone currently sounding? */
export function isDroneRunning(): boolean {
	return droneNote !== null;
}

/** Tear the drone synth down entirely. */
export function disposeDrone(): void {
	stopDrone();
	if (droneSynth) {
		droneSynth.dispose();
		droneSynth = null;
	}
}

// ══════════════════════════════════════════════════════════════════════════════
//  Metronome
// ══════════════════════════════════════════════════════════════════════════════
let metronomeLoop: ToneType.Loop | null = null;
let metronomeSynth: ToneType.MembraneSynth | null = null;
let metronomeRunning = false;
let beatCount = 0;
let onBeatCallback: ((beat: number, time: number) => void) | null = null;

function getMetronomeSynth(): ToneType.MembraneSynth {
	if (!metronomeSynth) {
		metronomeSynth = new _tone!.MembraneSynth({
			pitchDecay: 0.008,
			octaves: 2,
			envelope: { attack: 0.001, decay: 0.1, sustain: 0, release: 0.05 },
			volume: -12,
		}).toDestination();
	}
	return metronomeSynth;
}

/**
 * Start metronome.  Stops any running backing track (they share the Transport).
 *
 * The `onBeat` callback receives `(beat, time)` where `time` is the exact
 * Web Audio context time of this beat.  Pass `time` to `playChordAtTime()`
 * to trigger chords with **zero** JS-thread latency — perfectly on the beat.
 *
 * The callback fires synchronously inside the Transport Loop (NOT through
 * requestAnimationFrame) so Svelte state updates and audio scheduling
 * both happen at the earliest possible moment.
 */
export async function startMetronome(
	bpm: number,
	beatsPerBar: number = 4,
	onBeat?: (beat: number, time: number) => void,
): Promise<void> {
	const T = await getTone();
	await ensureStarted();
	stopMetronome();
	stopBackingTrack();

	T.getTransport().bpm.value = bpm;
	T.getTransport().swing = 0;
	beatCount = 0;
	onBeatCallback = onBeat ?? null;

	const click = getMetronomeSynth();

	metronomeLoop = new T.Loop((time: number) => {
		beatCount++;
		const currentBeat = ((beatCount - 1) % beatsPerBar) + 1;

		// Accent on beat 1
		click.triggerAttackRelease(currentBeat === 1 ? 'C3' : 'C4', '32n', time);

		// Fire callback directly — NOT through getDraw().schedule() —
		// so callers can schedule audio at the exact `time`.
		if (onBeatCallback) {
			onBeatCallback(currentBeat, time);
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
	if (metronomeRunning && !backingTrackRunning) {
		_tone?.getTransport().stop();
	}
	beatCount = 0;
	metronomeRunning = false;
	onBeatCallback = null;
}

/** Is the metronome ticking? */
export function isMetronomeRunning(): boolean {
	return metronomeRunning;
}

/** Change BPM on the fly (affects metronome AND backing track — shared Transport) */
export function setMetronomeBpm(bpm: number): void {
	if (_tone) _tone.getTransport().bpm.value = bpm;
}

// ══════════════════════════════════════════════════════════════════════════════
//  Backing Tracks  (synthesised drums via Transport + Sequence)
// ══════════════════════════════════════════════════════════════════════════════
export type BackingTrack = 'none' | 'swing' | 'bossa' | 'ballad';

export const BACKING_TRACKS: Record<BackingTrack, { label: string; description: string }> = {
	none:   { label: 'None',       description: 'No backing track' },
	swing:  { label: 'Swing',      description: 'Medium swing — ride, kick, hi-hat' },
	bossa:  { label: 'Bossa Nova', description: 'Classic bossa nova rhythm' },
	ballad: { label: 'Ballad',     description: 'Slow brushes & sparse kick' },
};

let backingTrackRunning = false;
let currentBackingTrack: BackingTrack = 'none';
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let backingSequences: any[] = [];
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let backingSynths: any[] = [];

interface DrumKit {
	kick:  ToneType.MembraneSynth;
	// MetalSynth & NoiseSynth have different triggerAttack signatures — typed as any internally
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	ride:  any;
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	hihat: any;
	snare: ToneType.NoiseSynth;
	brush: ToneType.NoiseSynth;
}

function createDrumKit(): DrumKit {
	const T = _tone!;

	const kick = new T.MembraneSynth({
		pitchDecay: 0.02, octaves: 6,
		envelope: { attack: 0.001, decay: 0.3, sustain: 0, release: 0.1 },
		volume: -16,
	}).toDestination();

	const ride = new T.MetalSynth({
		harmonicity: 5.1, modulationIndex: 32, resonance: 4000,
		envelope: { attack: 0.001, decay: 0.4, release: 0.2 },
		volume: -24,
	}).toDestination();

	const hihat = new T.MetalSynth({
		harmonicity: 5.1, modulationIndex: 40, resonance: 8000,
		envelope: { attack: 0.001, decay: 0.08, release: 0.01 },
		volume: -28,
	}).toDestination();

	const snare = new T.NoiseSynth({
		noise: { type: 'white' },
		envelope: { attack: 0.001, decay: 0.15, sustain: 0, release: 0.05 },
		volume: -20,
	}).toDestination();

	const brush = new T.NoiseSynth({
		noise: { type: 'pink' },
		envelope: { attack: 0.05, decay: 0.3, sustain: 0.1, release: 0.4 },
		volume: -24,
	}).toDestination();

	backingSynths.push(kick, ride, hihat, snare, brush);
	return { kick, ride, hihat, snare, brush };
}

// ── Pattern factories ────────────────────────────────────────────────────────

function buildSwing(kit: DrumKit) {
	const T = _tone!;
	T.getTransport().swing = 0.5;
	T.getTransport().swingSubdivision = '8n';

	// Ride: quarter notes + ghosted up-beats
	const rideSeq = new T.Sequence(
		(time: number, v: string | null) => {
			if (v) kit.ride.triggerAttack(time, v === 'a' ? 0.8 : 0.4);
		},
		['a', null, 'g', null, 'a', null, 'g', null], '8n',
	);

	// Hi-hat foot on 2 and 4
	const hhSeq = new T.Sequence(
		(time: number, v: string | null) => {
			if (v) kit.hihat.triggerAttack(time, 0.3);
		},
		[null, 'x', null, 'x'], '4n',
	);

	// Kick on 1, ghosted on 3
	const kickSeq = new T.Sequence(
		(time: number, v: string | null) => {
			if (v) kit.kick.triggerAttackRelease('C1', '8n', time, v === 'a' ? 0.7 : 0.4);
		},
		['a', null, 'g', null], '4n',
	);

	backingSequences.push(rideSeq, hhSeq, kickSeq);
	return [rideSeq, hhSeq, kickSeq];
}

function buildBossa(kit: DrumKit) {
	const T = _tone!;
	T.getTransport().swing = 0;

	// Classic bossa bass drum pattern (straight 8ths, 2-bar phrase)
	const kickSeq = new T.Sequence(
		(time: number, v: string | null) => {
			if (v) kit.kick.triggerAttackRelease('C1', '8n', time, 0.55);
		},
		['x', null, null, 'x', null, 'x', null, null, 'x', null, null, null, null, 'x', null, null],
		'8n',
	);

	// Cross-stick / rim on off-beats
	const rimSeq = new T.Sequence(
		(time: number, v: string | null) => {
			if (v) kit.hihat.triggerAttack(time, 0.35);
		},
		[null, null, 'x', null, 'x', null, null, 'x', null, 'x', null, null, 'x', null, 'x', null],
		'8n',
	);

	backingSequences.push(kickSeq, rimSeq);
	return [kickSeq, rimSeq];
}

function buildBallad(kit: DrumKit) {
	const T = _tone!;
	T.getTransport().swing = 0.3;
	T.getTransport().swingSubdivision = '8n';

	// Brush sweep (pink noise, slow attack)
	const brushSeq = new T.Sequence(
		(time: number, v: string | null) => {
			if (v) kit.brush.triggerAttackRelease('8n', time, v === 'a' ? 0.5 : 0.25);
		},
		['a', 's', 's', 'a', 's', 's', 'a', 's'], '8n',
	);

	// Very sparse kick
	const kickSeq = new T.Sequence(
		(time: number, v: string | null) => {
			if (v) kit.kick.triggerAttackRelease('C1', '4n', time, 0.35);
		},
		['x', null, null, null], '4n',
	);

	backingSequences.push(brushSeq, kickSeq);
	return [brushSeq, kickSeq];
}

// ── Public backing-track API ─────────────────────────────────────────────────
/**
 * Start a backing track at the given BPM.  Stops any running metronome
 * (they share the Transport and would clash rhythmically).
 */
export async function startBackingTrack(style: BackingTrack, bpm: number): Promise<void> {
	if (style === 'none') { stopBackingTrack(); return; }

	const T = await getTone();
	await ensureStarted();
	stopBackingTrack();
	stopMetronome();

	currentBackingTrack = style;
	T.getTransport().bpm.value = bpm;

	const kit = createDrumKit();
	const sequences =
		style === 'swing'  ? buildSwing(kit)  :
		style === 'bossa'  ? buildBossa(kit)  :
		                      buildBallad(kit);

	for (const seq of sequences) seq.start(0);
	T.getTransport().start();
	backingTrackRunning = true;
}

/** Stop backing track and dispose its synths / sequences */
export function stopBackingTrack(): void {
	for (const seq of backingSequences) { seq.stop(); seq.dispose(); }
	backingSequences = [];

	for (const s of backingSynths) s.dispose();
	backingSynths = [];

	if (backingTrackRunning && !metronomeRunning) {
		_tone?.getTransport().stop();
		if (_tone) _tone.getTransport().swing = 0;
	}
	backingTrackRunning = false;
	currentBackingTrack = 'none';
}

/** Change backing-track BPM on the fly (same Transport as metronome) */
export function setBackingTrackBpm(bpm: number): void {
	if (_tone) _tone.getTransport().bpm.value = bpm;
}

/** Current backing track id */
export function getBackingTrack(): BackingTrack {
	return currentBackingTrack;
}

/** Is a backing track running? */
export function isBackingTrackRunning(): boolean {
	return backingTrackRunning;
}

// ══════════════════════════════════════════════════════════════════════════════
//  Celebration sound effects (Habit Engine)
// ══════════════════════════════════════════════════════════════════════════════

type CelebrationSoundType = 'level-up' | 'goal-complete' | 'streak-milestone' | 'personal-best' | 'xp-gain';

/**
 * Play a short celebration sound effect using Tone.js synthesis.
 * Each celebration type has a distinct musical motif.
 */
export async function playCelebrationSound(type: CelebrationSoundType): Promise<void> {
	try {
		const T = await getTone();
		await ensureStarted();

		const synth = new T.Synth({
			oscillator: { type: 'triangle' },
			envelope: { attack: 0.01, decay: 0.15, sustain: 0.1, release: 0.3 },
			volume: -12,
		}).toDestination();

		const now = T.now();

		switch (type) {
			case 'level-up':
				// Ascending major arpeggio — triumphant
				synth.triggerAttackRelease('C5', '16n', now);
				synth.triggerAttackRelease('E5', '16n', now + 0.1);
				synth.triggerAttackRelease('G5', '16n', now + 0.2);
				synth.triggerAttackRelease('C6', '8n', now + 0.3);
				break;
			case 'goal-complete':
				// Two-note achievement chime
				synth.triggerAttackRelease('E5', '16n', now);
				synth.triggerAttackRelease('A5', '8n', now + 0.12);
				break;
			case 'streak-milestone':
				// Jazz lick — ascending min7 arpeggio
				synth.triggerAttackRelease('D5', '16n', now);
				synth.triggerAttackRelease('F5', '16n', now + 0.08);
				synth.triggerAttackRelease('A5', '16n', now + 0.16);
				synth.triggerAttackRelease('C6', '8n', now + 0.24);
				break;
			case 'personal-best':
				// Fanfare — major 6th leap + resolve
				synth.triggerAttackRelease('G5', '16n', now);
				synth.triggerAttackRelease('E6', '8n', now + 0.15);
				break;
			case 'xp-gain':
			default:
				// Subtle click — single soft note
				synth.triggerAttackRelease('G5', '32n', now);
				break;
		}

		// Auto-dispose after sound finishes
		setTimeout(() => synth.dispose(), 1500);
	} catch {
		// Audio not available — fail silently
	}
}

// ══════════════════════════════════════════════════════════════════════════════
//  Dispose everything
// ══════════════════════════════════════════════════════════════════════════════
/** Tear down ALL audio resources (instrument + metronome + backing track) */
export function disposeAll(): void {
	stopMetronome();
	stopBackingTrack();
	disposeDrone();
	disposeAudio();
	if (metronomeSynth) {
		metronomeSynth.dispose();
		metronomeSynth = null;
	}
}
