// ══════════════════════════════════════════════════════════════════════════════
// Audio playback using Tone.js — chord voicings, metronome & backing tracks
// ══════════════════════════════════════════════════════════════════════════════
//
// Sound presets:
//   grand-piano     Tone.Sampler with Salamander grand piano samples (CDN)
//   electric-piano  PolySynth<FMSynth>  — Rhodes-like FM synthesis
//   vibraphone      PolySynth<FMSynth>  — mellow bell mallet sound
//   organ           PolySynth<Synth>    — jazz organ drawbar harmonics
//   synth-pad       PolySynth<Synth>    — warm sustained pad
//
// Tone.js (~200 kB) is imported lazily on first use so it never ends up
// in the homepage bundle and does not block Time-to-Interactive on /train.
import type * as ToneType from 'tone';

// ─── Lazy Tone singleton ─────────────────────────────────────────────────────
let _tone: typeof ToneType | null = null;

async function getTone(): Promise<typeof ToneType> {
	if (!_tone) {
		_tone = await import('tone');
	}
	return _tone;
}

// ─── Sound Presets ──────────────────────────────────────────────────────────

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

// ─── Salamander Grand Piano Samples (CDN) ─────────────────────────────────
// Octaves 2–6 — covers all jazz piano voicing ranges.
// Tone.Sampler auto-repitches between sampled notes (every minor 3rd).
const SALAMANDER_SAMPLES: Record<string, string> = {
	C2: 'C2.mp3',     'D#2': 'Ds2.mp3', 'F#2': 'Fs2.mp3', A2: 'A2.mp3',
	C3: 'C3.mp3',     'D#3': 'Ds3.mp3', 'F#3': 'Fs3.mp3', A3: 'A3.mp3',
	C4: 'C4.mp3',     'D#4': 'Ds4.mp3', 'F#4': 'Fs4.mp3', A4: 'A4.mp3',
	C5: 'C5.mp3',     'D#5': 'Ds5.mp3', 'F#5': 'Fs5.mp3', A5: 'A5.mp3',
	C6: 'C6.mp3',
};
const SALAMANDER_BASE_URL = 'https://tonejs.github.io/audio/salamander/';

// ─── Synth Preset Configs (oscillator-based presets) ────────────────────────

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

// ─── Instrument state ────────────────────────────────────────────────────────
let instrument: ToneType.PolySynth | ToneType.Sampler | null = null;
let currentPreset: SoundPreset = 'grand-piano';
let reverb: ToneType.Reverb | null = null;
let started = false;
let samplesLoading = false;
let samplesLoadedCallbacks: (() => void)[] = [];

// Pre-computed chromatic note names for releasing all Sampler voices
const ALL_CHROMATIC: string[] = [];
for (let oct = 2; oct <= 6; oct++) {
	for (const n of ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']) {
		ALL_CHROMATIC.push(`${n}${oct}`);
	}
}

// ─── AudioContext bootstrap ─────────────────────────────────────────────────
/**
 * Ensure AudioContext is running (must be called from a user-interaction handler).
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

// ─── Instrument factory ─────────────────────────────────────────────────────

function createReverb(): ToneType.Reverb {
	const T = _tone!;
	return new T.Reverb({ decay: 2.0, wet: 0.15 }).toDestination();
}

function createSampler(): ToneType.Sampler {
	const T = _tone!;
	samplesLoading = true;

	const sampler = new T.Sampler({
		urls: SALAMANDER_SAMPLES,
		baseUrl: SALAMANDER_BASE_URL,
		release: 1,
		onload: () => {
			samplesLoading = false;
			for (const cb of samplesLoadedCallbacks) cb();
			samplesLoadedCallbacks = [];
		},
		onerror: (err: Error) => {
			console.error('[audio] Failed to load piano samples:', err);
			samplesLoading = false;
		},
	});

	return sampler;
}

/* eslint-disable @typescript-eslint/no-explicit-any */
function createPolySynth(): ToneType.PolySynth {
	const T = _tone!;
	const cfg = SYNTH_CONFIGS[currentPreset as Exclude<SoundPreset, 'grand-piano'>];
	const SynthClass = cfg.synthType === 'FMSynth' ? T.FMSynth : T.Synth;
	const synth = new T.PolySynth(SynthClass as any, cfg.config);
	synth.maxPolyphony = 8;
	return synth;
}
/* eslint-enable @typescript-eslint/no-explicit-any */

function getInstrument(): ToneType.PolySynth | ToneType.Sampler {
	if (!instrument) {
		if (!reverb) reverb = createReverb();
		instrument =
			currentPreset === 'grand-piano' ? createSampler() : createPolySynth();
		instrument.connect(reverb);
	}
	return instrument;
}

/**
 * Release all currently sounding voices on the instrument.
 * PolySynth has releaseAll(); Sampler does not — so we trigger
 * release on every chromatic note in the playing range (no-ops for
 * notes that are not currently sounding).
 */
function releaseAllVoices(time?: number): void {
	if (!instrument) return;
	if (typeof (instrument as any).releaseAll === 'function') {                // eslint-disable-line @typescript-eslint/no-explicit-any
		(instrument as any).releaseAll(time);                                    // eslint-disable-line @typescript-eslint/no-explicit-any
	} else {
		(instrument as ToneType.Sampler).triggerRelease(ALL_CHROMATIC, time);
	}
}

// ─── Loading-state API ──────────────────────────────────────────────────────
/** True while Sampler samples are being fetched from CDN */
export function isSamplesLoading(): boolean {
	return samplesLoading;
}

/** Register a one-shot callback that fires once samples are ready */
export function onSamplesLoaded(cb: () => void): void {
	if (!samplesLoading) cb();
	else samplesLoadedCallbacks.push(cb);
}

// ─── Sound-preset API ───────────────────────────────────────────────────────
/** Switch sound preset.  Disposes old instrument; next playChord creates new one. */
export function setSoundPreset(preset: SoundPreset): void {
	if (preset === currentPreset && instrument) return;
	currentPreset = preset;
	disposeAudio();
	// Pre-create instrument so Sampler can start loading immediately
	if (_tone && started) getInstrument();
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
 * Play a chord voicing.  Waits for Sampler samples if still loading.
 * @param notes – e.g. ["C", "E", "G", "B"]
 * @param duration – Tone.js duration string, e.g. "2n" (half note)
 */
export async function playChord(notes: string[], duration: string = '2n'): Promise<void> {
	const T = await getTone();
	await ensureStarted();
	const inst = getInstrument();

	// Block until Sampler samples are ready
	if (currentPreset === 'grand-piano' && samplesLoading) {
		await T.loaded();
	}

	const toneNotes = notesToToneNames(notes);
	const now = T.now();

	// Release current notes, then schedule new chord slightly in the future
	releaseAllVoices(now);
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	(inst as any).triggerAttackRelease(toneNotes, duration, now + 0.02);
}

/**
 * Play a single note (with octave, e.g. "C4").
 */
export async function playNote(note: string, duration: string = '8n'): Promise<void> {
	const T = await getTone();
	await ensureStarted();
	const inst = getInstrument();

	if (currentPreset === 'grand-piano' && samplesLoading) {
		await T.loaded();
	}

	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	(inst as any).triggerAttackRelease(note, duration);
}

/** Release all currently sounding notes */
export function stopAll(): void {
	releaseAllVoices();
}

/** Dispose chord / note instrument (keeps metronome & backing track intact) */
export function disposeAudio(): void {
	releaseAllVoices();
	if (instrument) {
		instrument.dispose();
		instrument = null;
	}
	if (reverb) {
		reverb.dispose();
		reverb = null;
	}
	samplesLoading = false;
	samplesLoadedCallbacks = [];
}

// ══════════════════════════════════════════════════════════════════════════════
//  Metronome
// ══════════════════════════════════════════════════════════════════════════════
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
			envelope: { attack: 0.001, decay: 0.1, sustain: 0, release: 0.05 },
			volume: -12,
		}).toDestination();
	}
	return metronomeSynth;
}

/**
 * Start metronome.  Stops any running backing track (they share the Transport).
 */
export async function startMetronome(
	bpm: number,
	beatsPerBar: number = 4,
	onBeat?: (beat: number) => void,
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

	metronomeLoop = new T.Loop((time) => {
		beatCount++;
		const currentBeat = ((beatCount - 1) % beatsPerBar) + 1;

		// Accent on beat 1
		click.triggerAttackRelease(currentBeat === 1 ? 'C3' : 'C4', '32n', time);

		if (onBeatCallback) {
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
//  Dispose everything
// ══════════════════════════════════════════════════════════════════════════════
/** Tear down ALL audio resources (instrument + metronome + backing track) */
export function disposeAll(): void {
	stopMetronome();
	stopBackingTrack();
	disposeAudio();
	if (metronomeSynth) {
		metronomeSynth.dispose();
		metronomeSynth = null;
	}
}
