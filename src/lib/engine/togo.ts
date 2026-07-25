// To-Go — practice away from the piano.
//
// Seven disciplines a jazz musician trains without an instrument:
//   interval · quality · progression · sing · time · lick · theory
//
// This module is the engine: it BUILDS exercises and GRADES answers. It never
// plays audio, touches the DOM, or reads the clock — the UI does that and hands
// results back. Randomness enters through an injected `rng`, time through `now`.
//
// PURE TypeScript, ported 1:1 to Swift (ios/MusicEngine/.../ToGo.swift).

import type { AccidentalPreference } from './notes';
import { noteToSemitone, getNoteName } from './notes';
import { CHORD_INTERVALS, CHORDS_BY_DIFFICULTY } from './chords';
import type { Difficulty } from './chords';
import { getChordNotes } from './voicings';

// ─── Public types ───────────────────────────────────────────

export type ToGoKind = 'interval' | 'quality' | 'progression' | 'sing' | 'time' | 'lick' | 'theory';

/** How the UI should sound out an exercise. Engine-neutral — no Tone.js here. */
export type ToGoPlayback =
	/** Sound these notes together (a chord). */
	| { type: 'chord'; notes: string[] }
	/** Sound these notes one after another. */
	| { type: 'sequence'; notes: string[]; stepMs: number }
	/**
	 * Sound each inner array as a chord, one after another — a cadence.
	 * Distinct from `sequence` because a progression must be *heard as chords*;
	 * flattening it into single notes destroys the very thing being tested.
	 */
	| { type: 'chords'; chords: string[][]; stepMs: number }
	/** Hold a reference tone while the player sings. */
	| { type: 'drone'; note: string }
	/** Run the metronome; the player taps along. */
	| { type: 'pulse'; bpm: number; bars: number; beatsPerBar: number }
	/** Nothing to play — a silent flashcard. */
	| { type: 'silent' };

/** How the player answers. */
export type ToGoInput =
	/** Pick one of `options`. */
	| { type: 'choice' }
	/** Sing a pitch; graded on pitch class. */
	| { type: 'sing'; targetPitchClass: number }
	/** Tap along; graded on timing offsets. */
	| { type: 'tap'; onBeats: number[]; beatsPerBar: number; toleranceMs: number }
	/** Tap the notes back on a keyboard; graded as a pitch-class set. */
	| { type: 'notes'; targetPitchClasses: number[] };

export interface ToGoExercise {
	id: string;
	kind: ToGoKind;
	play: ToGoPlayback;
	input: ToGoInput;
	/** Choice labels (empty for non-choice inputs). */
	options: string[];
	/** Index into `options` for choice inputs; -1 otherwise. */
	answerIndex: number;
	/** i18n key + params for the instruction line. */
	promptKey: string;
	promptParams: Record<string, string>;
	/** The plain answer, for the reveal ("it was a m7"). */
	answerLabel: string;
	/** Links to a Coach skill unit so ear progress moves the same map. */
	unitId?: string;
	/** Theory cards carry their card id so the SRS can reschedule them. */
	cardId?: string;
}

/** What the UI reports back after one exercise. */
export interface ToGoResult {
	exerciseId: string;
	kind: ToGoKind;
	correct: boolean;
	/** Time from prompt to answer. */
	ms: number;
	unitId?: string;
	cardId?: string;
}

export interface ToGoSession {
	exercises: ToGoExercise[];
	/** i18n key for the one-line intro ("Ear work — 8 rounds, no piano needed"). */
	sayKey: string;
	sayParams: Record<string, string>;
	estMinutes: number;
}

/** Which disciplines the player enabled / the device supports. */
export interface ToGoCapabilities {
	/** Mic available & permitted — gates `sing`. */
	mic: boolean;
	/** Sound on — gates everything except `theory`. */
	audio: boolean;
}

export const ALL_TOGO_KINDS: ToGoKind[] = [
	'interval',
	'quality',
	'progression',
	'sing',
	'time',
	'lick',
	'theory',
];

// ─── Tunables ───────────────────────────────────────────────

export interface ToGoParams {
	/** Exercises in a standard session. */
	sessionLength: number;
	/** ms between notes when a melodic phrase is sounded. */
	sequenceStepMs: number;
	/** How close a tap must land to count (± ms). */
	tapToleranceMs: number;
	/** Taps required before a time exercise is graded. */
	tapTargetCount: number;
	/** Default tempo for time exercises. */
	tapBpm: number;
	/** How many wrong choices to offer alongside the right one. */
	distractors: number;
	/** SM-2 floor for theory-card ease. */
	minEase: number;
}

export const DEFAULT_TOGO_PARAMS: ToGoParams = {
	sessionLength: 8,
	sequenceStepMs: 420,
	tapToleranceMs: 120,
	tapTargetCount: 8,
	tapBpm: 100,
	distractors: 3,
	minEase: 1.3,
};

// ─── Musical vocabulary ─────────────────────────────────────

/** Intervals worth hearing, easiest first — the order a curriculum teaches them. */
export const INTERVAL_LADDER: { semitones: number; label: string }[] = [
	{ semitones: 12, label: 'Octave' },
	{ semitones: 7, label: 'Perfect 5th' },
	{ semitones: 5, label: 'Perfect 4th' },
	{ semitones: 4, label: 'Major 3rd' },
	{ semitones: 3, label: 'Minor 3rd' },
	{ semitones: 9, label: 'Major 6th' },
	{ semitones: 8, label: 'Minor 6th' },
	{ semitones: 2, label: 'Major 2nd' },
	{ semitones: 1, label: 'Minor 2nd' },
	{ semitones: 11, label: 'Major 7th' },
	{ semitones: 10, label: 'Minor 7th' },
	{ semitones: 6, label: 'Tritone' },
];

/** Roman-numeral shapes the ear should recognise, easiest first. */
export const PROGRESSION_LADDER: { degrees: number[]; label: string }[] = [
	{ degrees: [0, 4, 0], label: 'I – V – I' },
	{ degrees: [1, 4, 0], label: 'ii – V – I' },
	{ degrees: [0, 5, 1, 4], label: 'I – vi – ii – V' },
	{ degrees: [2, 5, 1, 4], label: 'iii – vi – ii – V' },
	{ degrees: [0, 3, 4], label: 'I – IV – V' },
	{ degrees: [3, 0], label: 'IV – I' },
];

/** Chord quality per major-scale degree — for sounding a progression. */
const DEGREE_QUALITY = ['Maj7', 'm7', 'm7', 'Maj7', '7', 'm7', 'm7b5'];
/** Semitone offset of each major-scale degree from the tonic. */
const DEGREE_SEMITONES = [0, 2, 4, 5, 7, 9, 11];

/** Scale degrees a singer is asked to find over a drone, easiest first. */
export const SING_LADDER: { semitones: number; label: string }[] = [
	{ semitones: 0, label: 'Root' },
	{ semitones: 7, label: '5th' },
	{ semitones: 4, label: 'Major 3rd' },
	{ semitones: 3, label: 'Minor 3rd' },
	{ semitones: 10, label: '♭7' },
	{ semitones: 2, label: '9th' },
	{ semitones: 11, label: 'Major 7th' },
	{ semitones: 6, label: '♯11' },
];

/** Rhythm feels, easiest first. `onBeats` are 1-based beats in a 4/4 bar. */
export const TAP_LADDER: { onBeats: number[]; labelKey: string }[] = [
	{ onBeats: [1, 2, 3, 4], labelKey: 'togo.tap.quarters' },
	{ onBeats: [2, 4], labelKey: 'togo.tap.backbeat' },
	{ onBeats: [1, 3], labelKey: 'togo.tap.downbeats' },
	{ onBeats: [2], labelKey: 'togo.tap.two_only' },
];

/**
 * Short bebop-flavoured phrases, as semitone offsets from a root.
 * These are the language: enclosures, guide-tone moves, bebop scale fragments.
 */
export const LICK_LIBRARY: { offsets: number[]; nameKey: string }[] = [
	{ offsets: [0, 2, 4, 5], nameKey: 'togo.lick.scale_up' },
	{ offsets: [4, 2, 0], nameKey: 'togo.lick.triad_down' },
	{ offsets: [0, 4, 7, 10], nameKey: 'togo.lick.arpeggio' },
	{ offsets: [1, 0, -1, 0], nameKey: 'togo.lick.enclosure' },
	{ offsets: [10, 9, 7, 5], nameKey: 'togo.lick.guide_down' },
	{ offsets: [0, 3, 5, 6], nameKey: 'togo.lick.blues_climb' },
	{ offsets: [7, 5, 4, 2, 0], nameKey: 'togo.lick.descent' },
	{ offsets: [0, 4, 3, 2], nameKey: 'togo.lick.chromatic_fall' },
];

const KEYS_EASY = ['C', 'F', 'Bb', 'Eb'];
const KEYS_ALL = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];

// ─── Theory cards (generated, not hand-written) ─────────────

export type TheoryCardKind = 'chord-notes' | 'chord-degree' | 'tritone-sub' | 'relative-minor';

export interface TheoryCard {
	id: string;
	kind: TheoryCardKind;
	promptKey: string;
	promptParams: Record<string, string>;
	answer: string;
	/** Plausible wrong answers drawn from the same family. */
	distractors: string[];
}

/** SM-2 state for one theory card. Mirrors habits.ChordReview's maths. */
export interface TheoryCardState {
	cardId: string;
	/** ms since epoch. */
	lastReviewed: number;
	nextReview: number;
	/** days */
	interval: number;
	ease: number;
	repetitions: number;
}

const DEGREE_LABELS: { interval: number; label: string }[] = [
	{ interval: 3, label: '♭3' },
	{ interval: 4, label: '3rd' },
	{ interval: 7, label: '5th' },
	{ interval: 10, label: '♭7' },
	{ interval: 11, label: '7th' },
	{ interval: 1, label: '♭9' },
	{ interval: 2, label: '9th' },
];

/**
 * Build the full deck of theory cards from the engine's own chord tables, so
 * the deck stays correct and grows automatically when the curriculum does.
 * Deterministic — same deck every call.
 */
export function buildTheoryDeck(pref: AccidentalPreference = 'flats'): TheoryCard[] {
	const deck: TheoryCard[] = [];
	const qualities = CHORDS_BY_DIFFICULTY.intermediate.map((c) => c.display);

	for (const root of KEYS_EASY) {
		const rootSt = noteToSemitone(root);

		// "Which notes are in Cmaj7?"
		for (const quality of qualities) {
			const notes = getChordNotes(root, quality, pref);
			if (notes.length === 0) continue;
			deck.push({
				id: `notes|${root}|${quality}`,
				kind: 'chord-notes',
				promptKey: 'togo.card.chord_notes',
				promptParams: { chord: `${root}${quality}` },
				answer: notes.join(' – '),
				distractors: [
					getChordNotes(root, quality === 'Maj7' ? 'm7' : 'Maj7', pref).join(' – '),
					getChordNotes(getNoteName(rootSt, 2, pref), quality, pref).join(' – '),
					getChordNotes(getNoteName(rootSt, 5, pref), quality, pref).join(' – '),
				].filter((d) => d.length > 0),
			});
		}

		// "What's the 3rd of C7?"
		for (const quality of ['Maj7', '7', 'm7']) {
			const ivs = CHORD_INTERVALS[quality] ?? [];
			for (const deg of DEGREE_LABELS) {
				if (!ivs.includes(deg.interval)) continue;
				deck.push({
					id: `degree|${root}|${quality}|${deg.interval}`,
					kind: 'chord-degree',
					promptKey: 'togo.card.chord_degree',
					promptParams: { degree: deg.label, chord: `${root}${quality}` },
					answer: getNoteName(rootSt, deg.interval, pref),
					distractors: [
						getNoteName(rootSt, (deg.interval + 1) % 12, pref),
						getNoteName(rootSt, (deg.interval + 11) % 12, pref),
						getNoteName(rootSt, (deg.interval + 5) % 12, pref),
					],
				});
			}
		}

		// "What's the tritone sub of C7?"
		deck.push({
			id: `tritone|${root}`,
			kind: 'tritone-sub',
			promptKey: 'togo.card.tritone_sub',
			promptParams: { chord: `${root}7` },
			answer: `${getNoteName(rootSt, 6, pref)}7`,
			distractors: [`${getNoteName(rootSt, 5, pref)}7`, `${getNoteName(rootSt, 7, pref)}7`, `${getNoteName(rootSt, 1, pref)}7`],
		});

		// "What's the relative minor of C major?"
		deck.push({
			id: `relminor|${root}`,
			kind: 'relative-minor',
			promptKey: 'togo.card.relative_minor',
			promptParams: { key: root },
			answer: `${getNoteName(rootSt, 9, pref)}m`,
			distractors: [`${getNoteName(rootSt, 7, pref)}m`, `${getNoteName(rootSt, 2, pref)}m`, `${getNoteName(rootSt, 4, pref)}m`],
		});
	}

	return deck;
}

/**
 * SM-2 reschedule for a theory card. Pure: time enters as `now` (ms).
 * `quality` is 0–5 exactly as habits.ts uses it.
 */
export function scheduleCard(
	state: TheoryCardState,
	quality: number,
	now: number,
	params: ToGoParams = DEFAULT_TOGO_PARAMS,
): TheoryCardState {
	let { interval, ease, repetitions } = state;

	if (quality >= 3) {
		if (repetitions === 0) interval = 1;
		else if (repetitions === 1) interval = 3;
		else interval = Math.round(interval * ease);
		repetitions += 1;
	} else {
		// Missed — start over tomorrow.
		repetitions = 0;
		interval = 1;
	}

	ease = ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
	if (ease < params.minEase) ease = params.minEase;

	const DAY = 24 * 60 * 60 * 1000;
	return {
		cardId: state.cardId,
		lastReviewed: now,
		nextReview: now + interval * DAY,
		interval,
		ease,
		repetitions,
	};
}

/** A fresh card, due immediately. */
export function newCardState(cardId: string, now: number): TheoryCardState {
	return { cardId, lastReviewed: 0, nextReview: now, interval: 0, ease: 2.5, repetitions: 0 };
}

/** Cards whose review date has arrived, soonest-due first. */
export function dueCards(deck: TheoryCard[], states: Record<string, TheoryCardState>, now: number): TheoryCard[] {
	const due = deck.filter((c) => {
		const s = states[c.id];
		return !s || s.nextReview <= now;
	});
	return due.sort((a, b) => (states[a.id]?.nextReview ?? 0) - (states[b.id]?.nextReview ?? 0));
}

// ─── Exercise builders ──────────────────────────────────────
// Each takes an rng so sessions are varied but reproducible in tests.

type Rng = () => number;

function pick<T>(arr: readonly T[], rng: Rng): T {
	return arr[Math.min(arr.length - 1, Math.floor(rng() * arr.length))];
}

/** Distinct wrong options plus the right one, shuffled deterministically. */
function withDistractors(answer: string, pool: string[], count: number, rng: Rng): { options: string[]; answerIndex: number } {
	const wrong: string[] = [];
	const candidates = pool.filter((p) => p !== answer);
	// Walk the candidate list from a random offset — deterministic given rng,
	// and guarantees distinct options without a rejection loop.
	const start = Math.floor(rng() * Math.max(1, candidates.length));
	for (let i = 0; i < candidates.length && wrong.length < count; i++) {
		const c = candidates[(start + i) % candidates.length];
		if (!wrong.includes(c)) wrong.push(c);
	}
	const options = [...wrong, answer];
	// Fisher-Yates with the injected rng.
	for (let i = options.length - 1; i > 0; i--) {
		const j = Math.floor(rng() * (i + 1));
		[options[i], options[j]] = [options[j], options[i]];
	}
	return { options, answerIndex: options.indexOf(answer) };
}

/** Hear two notes, name the distance. */
export function buildIntervalExercise(
	rng: Rng,
	params: ToGoParams = DEFAULT_TOGO_PARAMS,
	pref: AccidentalPreference = 'flats',
	ladderDepth = INTERVAL_LADDER.length,
): ToGoExercise {
	const entry = pick(INTERVAL_LADDER.slice(0, Math.max(2, ladderDepth)), rng);
	const root = pick(KEYS_ALL, rng);
	const rootSt = noteToSemitone(root);
	const target = getNoteName(rootSt, entry.semitones % 12, pref);
	const { options, answerIndex } = withDistractors(
		entry.label,
		INTERVAL_LADDER.map((i) => i.label),
		params.distractors,
		rng,
	);
	return {
		id: `interval|${root}|${entry.semitones}`,
		kind: 'interval',
		play: { type: 'sequence', notes: [root, target], stepMs: params.sequenceStepMs },
		input: { type: 'choice' },
		options,
		answerIndex,
		promptKey: 'togo.prompt.interval',
		promptParams: {},
		answerLabel: entry.label,
	};
}

/** Hear a chord, name the quality. Mirrors the piano drill, inverted. */
export function buildQualityExercise(
	rng: Rng,
	params: ToGoParams = DEFAULT_TOGO_PARAMS,
	pref: AccidentalPreference = 'flats',
	difficulty: Difficulty = 'beginner',
	unitId?: string,
	forcedQuality?: string,
): ToGoExercise {
	const pool = CHORDS_BY_DIFFICULTY[difficulty].map((c) => c.display);
	const quality = forcedQuality && pool.includes(forcedQuality) ? forcedQuality : pick(pool, rng);
	const root = pick(KEYS_ALL, rng);
	const notes = getChordNotes(root, quality, pref);
	const { options, answerIndex } = withDistractors(quality, pool, params.distractors, rng);
	return {
		id: `quality|${root}|${quality}`,
		kind: 'quality',
		play: { type: 'chord', notes },
		input: { type: 'choice' },
		options,
		answerIndex,
		promptKey: 'togo.prompt.quality',
		promptParams: {},
		answerLabel: quality,
		unitId,
	};
}

/** Hear a cadence, name the roman-numeral shape. */
export function buildProgressionExercise(
	rng: Rng,
	params: ToGoParams = DEFAULT_TOGO_PARAMS,
	pref: AccidentalPreference = 'flats',
	ladderDepth = PROGRESSION_LADDER.length,
): ToGoExercise {
	const entry = pick(PROGRESSION_LADDER.slice(0, Math.max(2, ladderDepth)), rng);
	const key = pick(KEYS_EASY, rng);
	const keySt = noteToSemitone(key);

	// One inner array per chord, so the UI can sound a real cadence.
	const chords: string[][] = entry.degrees.map((deg) => {
		const root = getNoteName(keySt, DEGREE_SEMITONES[deg % 7], pref);
		return getChordNotes(root, DEGREE_QUALITY[deg % 7], pref);
	});

	const { options, answerIndex } = withDistractors(
		entry.label,
		PROGRESSION_LADDER.map((p) => p.label),
		params.distractors,
		rng,
	);
	return {
		id: `prog|${key}|${entry.degrees.join('-')}`,
		kind: 'progression',
		play: { type: 'chords', chords, stepMs: params.sequenceStepMs * 2 },
		input: { type: 'choice' },
		options,
		answerIndex,
		promptKey: 'togo.prompt.progression',
		promptParams: { key },
		answerLabel: entry.label,
	};
}

/** Sing a scale degree over a drone; the mic grades the pitch class. */
export function buildSingExercise(
	rng: Rng,
	_params: ToGoParams = DEFAULT_TOGO_PARAMS,
	pref: AccidentalPreference = 'flats',
	ladderDepth = SING_LADDER.length,
): ToGoExercise {
	const entry = pick(SING_LADDER.slice(0, Math.max(1, ladderDepth)), rng);
	const root = pick(KEYS_EASY, rng);
	const rootSt = noteToSemitone(root);
	const targetPc = (rootSt + entry.semitones) % 12;
	return {
		id: `sing|${root}|${entry.semitones}`,
		kind: 'sing',
		play: { type: 'drone', note: root },
		input: { type: 'sing', targetPitchClass: targetPc },
		options: [],
		answerIndex: -1,
		promptKey: 'togo.prompt.sing',
		promptParams: { degree: entry.label, root },
		answerLabel: getNoteName(rootSt, entry.semitones, pref),
	};
}

/** Tap the groove; graded on timing offsets against the click. */
export function buildTimeExercise(
	rng: Rng,
	params: ToGoParams = DEFAULT_TOGO_PARAMS,
	ladderDepth = TAP_LADDER.length,
): ToGoExercise {
	const entry = pick(TAP_LADDER.slice(0, Math.max(1, ladderDepth)), rng);
	const bars = Math.max(2, Math.ceil(params.tapTargetCount / Math.max(1, entry.onBeats.length)));
	return {
		id: `time|${entry.onBeats.join('-')}`,
		kind: 'time',
		play: { type: 'pulse', bpm: params.tapBpm, bars, beatsPerBar: 4 },
		input: { type: 'tap', onBeats: entry.onBeats, beatsPerBar: 4, toleranceMs: params.tapToleranceMs },
		options: [],
		answerIndex: -1,
		promptKey: entry.labelKey,
		promptParams: { bpm: String(params.tapBpm) },
		answerLabel: entry.onBeats.join(' · '),
	};
}

/** Hear a short phrase, tap it back from memory. */
export function buildLickExercise(
	rng: Rng,
	params: ToGoParams = DEFAULT_TOGO_PARAMS,
	pref: AccidentalPreference = 'flats',
	maxNotes = 5,
): ToGoExercise {
	const candidates = LICK_LIBRARY.filter((l) => l.offsets.length <= Math.max(3, maxNotes));
	const lick = pick(candidates.length > 0 ? candidates : LICK_LIBRARY, rng);
	const root = pick(KEYS_EASY, rng);
	const rootSt = noteToSemitone(root);
	const notes = lick.offsets.map((o) => getNoteName(rootSt, ((o % 12) + 12) % 12, pref));
	const pcs = lick.offsets.map((o) => (((rootSt + o) % 12) + 12) % 12);
	return {
		id: `lick|${root}|${lick.nameKey}`,
		kind: 'lick',
		play: { type: 'sequence', notes, stepMs: params.sequenceStepMs },
		input: { type: 'notes', targetPitchClasses: pcs },
		options: [],
		answerIndex: -1,
		promptKey: 'togo.prompt.lick',
		promptParams: { count: String(notes.length) },
		answerLabel: notes.join(' – '),
	};
}

/** A silent flashcard — works with the sound off. */
export function buildTheoryExercise(card: TheoryCard, rng: Rng, params: ToGoParams = DEFAULT_TOGO_PARAMS): ToGoExercise {
	const { options, answerIndex } = withDistractors(card.answer, card.distractors, params.distractors, rng);
	return {
		id: `theory|${card.id}`,
		kind: 'theory',
		play: { type: 'silent' },
		input: { type: 'choice' },
		options,
		answerIndex,
		promptKey: card.promptKey,
		promptParams: card.promptParams,
		answerLabel: card.answer,
		cardId: card.id,
	};
}

// ─── Grading ────────────────────────────────────────────────

/** Did the player pick the right option? */
export function gradeChoice(ex: ToGoExercise, chosenIndex: number): boolean {
	return chosenIndex === ex.answerIndex;
}

/**
 * Was the sung note the target pitch class? `sungMidi` comes from the mic.
 * Octave-agnostic — singing the 3rd an octave down is still the 3rd.
 */
export function gradeSing(ex: ToGoExercise, sungMidi: number[]): boolean {
	if (ex.input.type !== 'sing') return false;
	const target = ex.input.targetPitchClass;
	return sungMidi.some((m) => ((m % 12) + 12) % 12 === target);
}

/** Did the player tap back the right notes (as a pitch-class set)? */
export function gradeNotes(ex: ToGoExercise, tappedPitchClasses: number[]): boolean {
	if (ex.input.type !== 'notes') return false;
	const target = new Set(ex.input.targetPitchClasses.map((p) => ((p % 12) + 12) % 12));
	const got = new Set(tappedPitchClasses.map((p) => ((p % 12) + 12) % 12));
	if (got.size !== target.size) return false;
	for (const p of got) if (!target.has(p)) return false;
	return true;
}

export interface TapScore {
	/** Taps that landed inside the tolerance window. */
	hits: number;
	/** Taps expected across the exercise. */
	expected: number;
	/** Mean |offset| in ms over the taps that hit. Lower is tighter. */
	meanAbsOffsetMs: number;
	/** Signed mean — negative = rushing, positive = dragging. */
	meanOffsetMs: number;
	correct: boolean;
}

/**
 * Score tap timing against the beat grid.
 *
 * `beatTimesMs` are the moments the click fired for the beats the player was
 * asked to tap; `tapTimesMs` are when they actually tapped. Each expected beat
 * is matched to its nearest unused tap, so an extra tap can't score twice and a
 * missed beat counts against you. Offsets are SIGNED — this is what lets us say
 * "you're rushing" instead of only "you're off".
 */
export function gradeTaps(
	beatTimesMs: number[],
	tapTimesMs: number[],
	toleranceMs: number,
	passRatio = 0.7,
): TapScore {
	const used = new Array(tapTimesMs.length).fill(false);
	const offsets: number[] = [];

	for (const beat of beatTimesMs) {
		let bestIdx = -1;
		let bestDist = Infinity;
		for (let i = 0; i < tapTimesMs.length; i++) {
			if (used[i]) continue;
			const d = Math.abs(tapTimesMs[i] - beat);
			if (d < bestDist) {
				bestDist = d;
				bestIdx = i;
			}
		}
		if (bestIdx >= 0 && bestDist <= toleranceMs) {
			used[bestIdx] = true;
			offsets.push(tapTimesMs[bestIdx] - beat);
		}
	}

	const hits = offsets.length;
	const expected = beatTimesMs.length;
	const meanOffsetMs = hits > 0 ? offsets.reduce((s, o) => s + o, 0) / hits : 0;
	const meanAbsOffsetMs = hits > 0 ? offsets.reduce((s, o) => s + Math.abs(o), 0) / hits : 0;
	return {
		hits,
		expected,
		meanAbsOffsetMs,
		meanOffsetMs,
		correct: expected > 0 && hits / expected >= passRatio,
	};
}

// ─── Session composer ───────────────────────────────────────

/**
 * Build a To-Go session.
 *
 * Mixes the disciplines the device can actually run, weighted toward what the
 * player is currently learning: `focusQuality` (from the Coach frontier) makes
 * the ear side drill the very chord the piano side is working on.
 */
export function buildToGoSession(
	rng: Rng,
	caps: ToGoCapabilities,
	opts: {
		deck?: TheoryCard[];
		cardStates?: Record<string, TheoryCardState>;
		now?: number;
		/** Quality the Coach is currently teaching — the ear side mirrors it. */
		focusQuality?: string;
		/** Coach unit the ear work should credit, so both senses move one map. */
		focusUnitId?: string;
		difficulty?: Difficulty;
		/** Restrict to one discipline (the player picked it explicitly). */
		only?: ToGoKind;
		pref?: AccidentalPreference;
	} = {},
	params: ToGoParams = DEFAULT_TOGO_PARAMS,
): ToGoSession {
	const pref = opts.pref ?? 'flats';
	const now = opts.now ?? 0;
	const difficulty = opts.difficulty ?? 'beginner';
	const deck = opts.deck ?? [];
	const cardStates = opts.cardStates ?? {};

	// Which disciplines can run right now?
	let kinds: ToGoKind[] = opts.only
		? [opts.only]
		: ALL_TOGO_KINDS.filter((k) => {
				if (k === 'theory') return deck.length > 0; // silent — always allowed
				if (!caps.audio) return false; // everything else needs sound
				if (k === 'sing') return caps.mic;
				return true;
			});
	if (kinds.length === 0) kinds = ['theory'];

	const due = dueCards(deck, cardStates, now);
	let cardCursor = 0;

	// Deal the disciplines round-robin so every one appears, then shuffle the
	// order — a session should feel varied, not like a fixed lap of the ladder.
	const order: ToGoKind[] = [];
	for (let i = 0; i < params.sessionLength; i++) order.push(kinds[i % kinds.length]);
	for (let i = order.length - 1; i > 0; i--) {
		const j = Math.floor(rng() * (i + 1));
		[order[i], order[j]] = [order[j], order[i]];
	}

	const exercises: ToGoExercise[] = [];
	for (let i = 0; i < params.sessionLength; i++) {
		const kind = order[i];
		switch (kind) {
			case 'interval':
				exercises.push(buildIntervalExercise(rng, params, pref));
				break;
			case 'quality':
				exercises.push(
					buildQualityExercise(rng, params, pref, difficulty, opts.focusUnitId, opts.focusQuality),
				);
				break;
			case 'progression':
				exercises.push(buildProgressionExercise(rng, params, pref));
				break;
			case 'sing':
				exercises.push(buildSingExercise(rng, params, pref));
				break;
			case 'time':
				exercises.push(buildTimeExercise(rng, params));
				break;
			case 'lick':
				exercises.push(buildLickExercise(rng, params, pref));
				break;
			case 'theory': {
				const card = due[cardCursor % Math.max(1, due.length)] ?? deck[cardCursor % Math.max(1, deck.length)];
				cardCursor++;
				if (card) exercises.push(buildTheoryExercise(card, rng, params));
				break;
			}
		}
	}

	const single = opts.only !== undefined;
	return {
		exercises,
		sayKey: single ? 'togo.say.single' : 'togo.say.mixed',
		sayParams: { count: String(exercises.length), kind: opts.only ?? '' },
		estMinutes: Math.max(1, Math.round(exercises.length * 0.4)),
	};
}

// ─── Session summary ────────────────────────────────────────

export interface ToGoSummary {
	total: number;
	correct: number;
	/** Accuracy 0–1. */
	ratio: number;
	avgMs: number;
	/** Per-discipline breakdown, for the results screen. */
	byKind: Record<string, { total: number; correct: number }>;
	/** SM-2 quality (0–5) derived from the run — feeds card scheduling. */
	srsQuality: number;
}

export function summarize(results: ToGoResult[]): ToGoSummary {
	const total = results.length;
	const correct = results.filter((r) => r.correct).length;
	const avgMs = total > 0 ? results.reduce((s, r) => s + r.ms, 0) / total : 0;
	const byKind: Record<string, { total: number; correct: number }> = {};
	for (const r of results) {
		const b = (byKind[r.kind] ??= { total: 0, correct: 0 });
		b.total++;
		if (r.correct) b.correct++;
	}
	const ratio = total > 0 ? correct / total : 0;
	// Map accuracy onto SM-2's 0–5 so theory cards reschedule sensibly.
	let srsQuality = 0;
	if (ratio >= 0.95) srsQuality = 5;
	else if (ratio >= 0.85) srsQuality = 4;
	else if (ratio >= 0.7) srsQuality = 3;
	else if (ratio >= 0.5) srsQuality = 2;
	else if (ratio > 0) srsQuality = 1;

	return { total, correct, ratio, avgMs, byKind, srsQuality };
}

/** Reschedule every theory card the session touched. */
export function applyResultsToCards(
	states: Record<string, TheoryCardState>,
	results: ToGoResult[],
	now: number,
	params: ToGoParams = DEFAULT_TOGO_PARAMS,
): Record<string, TheoryCardState> {
	const next = { ...states };
	for (const r of results) {
		if (!r.cardId) continue;
		const prev = next[r.cardId] ?? newCardState(r.cardId, now);
		// Per-card quality: right & quick = 5, right = 4, wrong = 1.
		const quality = r.correct ? (r.ms > 0 && r.ms < 4000 ? 5 : 4) : 1;
		next[r.cardId] = scheduleCard(prev, quality, now, params);
	}
	return next;
}
