// Coach — the Auto-Mode engine ("your teacher in one tap").
//
// Three layers (see docs/auto-mode-design.md):
//   1. Skill-Map     — buildSkillLadder(): what the player can do, as a ladder of units.
//   2. Controller    — applySessionToCoach(): promote / hold / demote after each session.
//   3. Composer      — buildCoachPlan(): today's session as a sequence of blocks.
//
// PURE TypeScript. No Date.now(), no localStorage, no Svelte/DOM. Time enters as `now`.
// This file is ported 1:1 to Swift (ios/MusicEngine/.../Coach.swift), so keep it
// free of anything that can't cross that boundary.

import type { Difficulty, VoicingType, DisplayMode, NotationStyle } from './chords';
import { CHORDS_BY_DIFFICULTY } from './chords';
import type { AccidentalPreference } from './notes';
import type { ProgressionMode } from './progressions';
import type { SessionResult, ChordTiming, WeakSpot } from '../services/progress';
import { analyzeWeakSpots } from '../services/progress';
import type { HabitProfile, ChordReview } from './habits';
import type { CourseProgress } from './courses';
import { ultimatePlanCourse } from '../courses/ultimate-plan';
import type { CoachParams } from './coach-params';
import { DEFAULT_COACH_PARAMS } from './coach-params';

// ─── Public types ───────────────────────────────────────────

export type KeyTier = 'easy' | 'med' | 'all';
export type UnitState = 'locked' | 'learning' | 'practicing' | 'mastered';

/** A rung on the skill ladder: one voicing × quality × key-tier. */
export interface SkillUnit {
	/** Stable id, e.g. "shell|Maj7|easy". */
	id: string;
	voicing: VoicingType;
	/** Quality display string, e.g. "Maj7" (matches ChordType.display). */
	quality: string;
	keyTier: KeyTier;
	/** Concrete root notes this unit drills. */
	keys: string[];
	/** Lowest difficulty tier whose chord pool contains `quality`. */
	difficulty: Difficulty;
	/** Curriculum-order index (0 = first rung). */
	index: number;
	/** i18n key for the module this unit belongs to (for teacher-talk). */
	moduleTitleKey: string;
}

export interface UnitProgress {
	state: UnitState;
	/** Best windowed average ms seen so far (lower = better). */
	bestAvgMs?: number;
	/** `now` of the last session that trained this unit. */
	lastTrainedAt?: number;
	/** Consecutive holds (missed the threshold) on this unit while it was the frontier. */
	holds: number;
}

export interface CoachState {
	version: number;
	/** Per-unit progress, keyed by SkillUnit.id. Sparse — absent = 'locked'. */
	unitStates: Record<string, UnitProgress>;
	/** Index of the frontier unit (first non-mastered rung). */
	frontierIndex: number;
	/** Monotonic counter for deterministic block rotation. */
	dayIndex: number;
	/** -clamp..+clamp from "too easy / too hard". Positive = wants it harder. */
	difficultyBias: number;
	/** Whether the one-time calibration has run. */
	calibrated: boolean;
	/** Last plan built, for resume / display. */
	lastPlan?: CoachPlan;
}

/** Exactly the settings axes an existing drill session understands. */
export interface PracticePlanSettings {
	difficulty: Difficulty;
	notation: NotationStyle;
	voicing: VoicingType;
	displayMode: DisplayMode;
	accidentals: AccidentalPreference;
	progressionMode: ProgressionMode;
	totalChords: number;
}

export type BlockKind = 'warmup' | 'review' | 'focus' | 'new' | 'apply' | 'calibrate';

export interface CoachBlock {
	kind: BlockKind;
	settings: PracticePlanSettings;
	/** Roots to weight heavily (focus / review). */
	focusRoots?: string[];
	/** Voicing to weight heavily (focus). */
	focusVoicing?: string;
	/** How many chords this block presents. */
	targetChords: number;
	/** i18n key for the mid-session mini-screen ("Warm-up done — now your focus: …"). */
	labelKey: string;
	/** Params for labelKey interpolation (no hard-coded prose). */
	labelParams?: Record<string, string>;
}

export interface CoachPlan {
	blocks: CoachBlock[];
	/** i18n key for the one-line coach announcement. */
	sayKey: string;
	/** Params for sayKey (root/voicing/minutes/quality as strings). */
	sayParams: Record<string, string>;
	estMinutes: number;
	/** Snapshot of the frontier at plan time — lets the feedback screen compare before/after. */
	frontierUnitId?: string;
}

/** One structured statement for the post-session teacher screen. */
export interface TeacherStatement {
	kind: 'promoted' | 'held' | 'demoted' | 'improved' | 'placed' | 'nextGoal' | 'calibrated';
	key: string;
	params: Record<string, string>;
}

// ─── i18n key catalogue (consumed by the UX task) ───────────
// Exported so the UI/i18n task has the exact set to translate.

export const COACH_LABEL_KEYS = {
	warmup: 'coach.block.warmup',
	review: 'coach.block.review',
	focus: 'coach.block.focus',
	new: 'coach.block.new',
	apply: 'coach.block.apply',
	calibrate: 'coach.block.calibrate',
} as const;

export const COACH_SAY_KEYS = {
	calibrate: 'coach.say.calibrate',
	short: 'coach.say.short',
	full: 'coach.say.full',
	reviewOnly: 'coach.say.reviewOnly',
} as const;

export const COACH_FEEDBACK_KEYS = {
	promoted: 'coach.fb.promoted',
	held: 'coach.fb.held',
	demoted: 'coach.fb.demoted',
	improved: 'coach.fb.improved',
	placed: 'coach.fb.placed',
	nextGoal: 'coach.fb.nextGoal',
	calibrated: 'coach.fb.calibrated',
} as const;

// ─── Key tiers ──────────────────────────────────────────────
// Derived to mirror ultimate-plan's EASY_KEYS → (…) → ALL_KEYS ladder.
// `med` is an 8-key middle rung so the three tiers form a real progression
// (ultimate-plan collapses med into all; the Coach keeps them distinct).

const ALL_KEYS = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
const EASY_KEYS = ['C', 'F', 'Bb', 'Eb'];
const MED_KEYS = ['C', 'F', 'Bb', 'Eb', 'G', 'D', 'A', 'Ab'];

function keysForTier(tier: KeyTier): string[] {
	if (tier === 'easy') return EASY_KEYS;
	if (tier === 'med') return MED_KEYS;
	return ALL_KEYS;
}

const KEY_TIERS: KeyTier[] = ['easy', 'med', 'all'];

// ─── Difficulty mapping ─────────────────────────────────────

const DIFF_ORDER: Difficulty[] = ['beginner', 'intermediate', 'advanced'];

/** Lowest difficulty tier whose chord pool contains this quality display. */
function difficultyForQuality(quality: string): Difficulty {
	for (const d of DIFF_ORDER) {
		if (CHORDS_BY_DIFFICULTY[d].some((c) => c.display === quality)) return d;
	}
	// Qualities not in any pool (shouldn't happen) default to advanced.
	return 'advanced';
}

// ─── 1. Skill-Map ───────────────────────────────────────────

/**
 * Build the skill ladder deterministically from the ultimate-plan curriculum.
 *
 * Order = curriculum order (module → lesson). Each lesson contributes ONE
 * (voicing × quality) pair, expanded into three key-tier rungs (easy → med → all).
 * Duplicate (voicing × quality) pairs are de-duplicated, first occurrence wins,
 * so the ladder is stable regardless of how often a pair appears.
 *
 * No randomness, no time — same output every call.
 */
export function buildSkillLadder(): SkillUnit[] {
	const units: SkillUnit[] = [];
	const seen = new Set<string>(); // "voicing|quality"

	for (const mod of ultimatePlanCourse.modules) {
		for (const lesson of mod.lessons) {
			const theory = lesson.steps.find((s) => s.type === 'theory');
			// The theory step carries the canonical exampleChord (root/quality/voicing).
			const ex = theory && 'exampleChord' in theory ? theory.exampleChord : undefined;
			if (!ex) continue;
			const pairKey = `${ex.voicing}|${ex.quality}`;
			if (seen.has(pairKey)) continue;
			seen.add(pairKey);

			const difficulty = difficultyForQuality(ex.quality);
			for (const tier of KEY_TIERS) {
				const id = `${ex.voicing}|${ex.quality}|${tier}`;
				units.push({
					id,
					voicing: ex.voicing,
					quality: ex.quality,
					keyTier: tier,
					keys: keysForTier(tier),
					difficulty,
					index: units.length,
					moduleTitleKey: mod.titleKey,
				});
			}
		}
	}

	return units;
}

// ─── State helpers ──────────────────────────────────────────

export function createInitialCoachState(): CoachState {
	return {
		version: 1,
		unitStates: {},
		frontierIndex: 0,
		dayIndex: 0,
		difficultyBias: 0,
		calibrated: false,
	};
}

function unitProgress(state: CoachState, id: string): UnitProgress {
	return state.unitStates[id] ?? { state: 'locked', holds: 0 };
}

function isMastered(state: CoachState, id: string): boolean {
	return state.unitStates[id]?.state === 'mastered';
}

/** First non-mastered rung. Clamped to the ladder's last index. */
function computeFrontierIndex(ladder: SkillUnit[], state: CoachState): number {
	for (let i = 0; i < ladder.length; i++) {
		if (!isMastered(state, ladder[i].id)) return i;
	}
	return Math.max(0, ladder.length - 1);
}

// ─── Difficulty-bias application ────────────────────────────

/** Nudge a base difficulty up/down by the accumulated bias. */
function applyBias(base: Difficulty, bias: number): Difficulty {
	const idx = DIFF_ORDER.indexOf(base);
	let shifted = idx;
	if (bias >= 0.34) shifted = idx + 1;
	else if (bias <= -0.34) shifted = idx - 1;
	shifted = Math.max(0, Math.min(DIFF_ORDER.length - 1, shifted));
	return DIFF_ORDER[shifted];
}

// ─── 3. Session-Composer ────────────────────────────────────

const DEFAULT_NOTATION: NotationStyle = 'standard';
// Flats, not 'both': the Coach's key tiers are all spelled with flats
// (Db, Eb, Ab, Bb), and jazz lead-sheets favour flats for these roots — so a
// focus block on B♭m6 must not surface as "A#m6". Aligns generated roots with
// the ladder's own spelling.
const DEFAULT_ACCIDENTALS: AccidentalPreference = 'flats';

function chordsForMinutes(minutes: number, params: CoachParams): number {
	return Math.max(params.minBlockChords, Math.round(minutes * params.chordsPerMinute));
}

/** Roots that are due for SRS review right now, mapped from the chord schedule. */
function dueReviewRoots(schedule: ChordReview[], now: number): string[] {
	const roots: string[] = [];
	for (const r of schedule) {
		if (new Date(r.nextReview).getTime() <= now) roots.push(r.root);
	}
	return [...new Set(roots)];
}

function warmupSettings(unit: SkillUnit, bias: number): PracticePlanSettings {
	return {
		difficulty: applyBias('beginner', bias),
		notation: DEFAULT_NOTATION,
		voicing: unit.voicing,
		displayMode: 'off',
		accidentals: DEFAULT_ACCIDENTALS,
		progressionMode: 'random',
		totalChords: 0,
	};
}

function newSettings(unit: SkillUnit, bias: number, guided: boolean): PracticePlanSettings {
	return {
		difficulty: applyBias(unit.difficulty, bias),
		notation: DEFAULT_NOTATION,
		voicing: unit.voicing,
		// Hold escalates guided support: 'always' shows the answer, 'verify' checks it.
		displayMode: guided ? 'always' : 'verify',
		accidentals: DEFAULT_ACCIDENTALS,
		progressionMode: 'random',
		totalChords: 0,
	};
}

function focusSettings(weak: WeakSpot | undefined, frontier: SkillUnit, bias: number): PracticePlanSettings {
	return {
		difficulty: applyBias(frontier.difficulty, bias),
		notation: DEFAULT_NOTATION,
		voicing: weak?.voicing ?? frontier.voicing,
		displayMode: 'verify',
		accidentals: DEFAULT_ACCIDENTALS,
		progressionMode: 'random',
		totalChords: 0,
	};
}

function reviewSettings(frontier: SkillUnit, bias: number): PracticePlanSettings {
	return {
		difficulty: applyBias('intermediate', bias),
		notation: DEFAULT_NOTATION,
		voicing: frontier.voicing,
		displayMode: 'verify',
		accidentals: DEFAULT_ACCIDENTALS,
		progressionMode: 'random',
		totalChords: 0,
	};
}

function applySettings(masteredVoicing: VoicingType, bias: number, progMode: ProgressionMode): PracticePlanSettings {
	return {
		difficulty: applyBias('intermediate', bias),
		notation: DEFAULT_NOTATION,
		voicing: masteredVoicing,
		displayMode: 'always',
		accidentals: DEFAULT_ACCIDENTALS,
		progressionMode: progMode,
		totalChords: 0,
	};
}

// Deterministic rotation of the "apply" progression by dayIndex.
const APPLY_PROGRESSIONS: ProgressionMode[] = ['2-5-1', '1-6-2-5', 'cycle-of-4ths', '3-6-2-5'];

/**
 * Build today's Coach plan.
 *
 * Rules (design-doc §2.3):
 *  - Uncalibrated user → single calibrate block.
 *  - Short session (< shortSessionCutoffMin) → review + focus + new only.
 *  - Full session → warmup + review + focus + new + apply.
 * Block rotation & progression choice are deterministic from state.dayIndex.
 */
export function buildCoachPlan(
	history: SessionResult[],
	profile: HabitProfile,
	courseProgress: CourseProgress | undefined,
	state: CoachState,
	params: CoachParams = DEFAULT_COACH_PARAMS,
	now: number = 0,
): CoachPlan {
	const ladder = buildSkillLadder();
	const frontierIndex = computeFrontierIndex(ladder, state);
	const frontier = ladder[frontierIndex];
	const bias = state.difficultyBias;
	const minutes = profile.dailyGoalMinutes;

	// ── Uncalibrated → calibration drill ──────────────────
	if (!state.calibrated) {
		const firstUnit = ladder[0];
		const calSettings: PracticePlanSettings = {
			difficulty: 'beginner',
			notation: DEFAULT_NOTATION,
			voicing: firstUnit.voicing,
			displayMode: 'verify',
			accidentals: DEFAULT_ACCIDENTALS,
			progressionMode: 'random',
			totalChords: params.calibrationChords,
		};
		const block: CoachBlock = {
			kind: 'calibrate',
			settings: calSettings,
			targetChords: params.calibrationChords,
			labelKey: COACH_LABEL_KEYS.calibrate,
		};
		return {
			blocks: [block],
			sayKey: COACH_SAY_KEYS.calibrate,
			sayParams: { chords: String(params.calibrationChords) },
			estMinutes: 3,
			frontierUnitId: frontier?.id,
		};
	}

	const isShort = minutes < params.shortSessionCutoffMin;

	// Frontier is guided when it has accrued holds (design §2.2 rule 2).
	const frontierHolds = unitProgress(state, frontier.id).holds;
	const guided = frontierHolds > 0;

	// Weak spot for the focus block.
	const weak = analyzeWeakSpots(history, 1)[0];
	const reviewRoots = dueReviewRoots(profile.chordSchedule, now);

	// Choose which normal blocks are present.
	const mix = params.blockMix;
	const parts: { kind: BlockKind; weight: number }[] = isShort
		? [
				{ kind: 'review', weight: mix.review },
				{ kind: 'focus', weight: mix.focus },
				{ kind: 'new', weight: mix.new },
		  ]
		: [
				{ kind: 'warmup', weight: mix.warmup },
				{ kind: 'review', weight: mix.review },
				{ kind: 'focus', weight: mix.focus },
				{ kind: 'new', weight: mix.new },
				{ kind: 'apply', weight: mix.apply },
		  ];

	// Drop review if nothing is due.
	const activeParts =
		reviewRoots.length === 0 ? parts.filter((p) => p.kind !== 'review') : parts;

	const totalWeight = activeParts.reduce((s, p) => s + p.weight, 0) || 1;

	// Nearest already-mastered voicing (for warmup & apply). Falls back to frontier.
	const masteredVoicing = nearestMasteredVoicing(ladder, state, frontier);
	const applyProg = APPLY_PROGRESSIONS[state.dayIndex % APPLY_PROGRESSIONS.length];

	const blocks: CoachBlock[] = [];
	for (const part of activeParts) {
		const blockMinutes = (part.weight / totalWeight) * minutes;
		const targetChords = chordsForMinutes(blockMinutes, params);

		let settings: PracticePlanSettings;
		let focusRoots: string[] | undefined;
		let focusVoicing: string | undefined;
		let labelParams: Record<string, string> | undefined;

		switch (part.kind) {
			case 'warmup':
				settings = warmupSettings({ ...frontier, voicing: masteredVoicing }, bias);
				labelParams = { voicing: masteredVoicing };
				break;
			case 'review':
				settings = reviewSettings(frontier, bias);
				focusRoots = reviewRoots;
				labelParams = { count: String(reviewRoots.length) };
				break;
			case 'focus':
				settings = focusSettings(weak, frontier, bias);
				focusRoots = weak ? [weak.root] : undefined;
				focusVoicing = weak?.voicing ?? frontier.voicing;
				labelParams = { root: weak?.root ?? frontier.keys[0], voicing: focusVoicing };
				break;
			case 'new':
				settings = newSettings(frontier, bias, guided);
				focusVoicing = frontier.voicing;
				labelParams = { quality: frontier.quality, voicing: frontier.voicing };
				break;
			case 'apply':
				settings = applySettings(masteredVoicing, bias, applyProg);
				labelParams = { voicing: masteredVoicing };
				break;
			default:
				settings = newSettings(frontier, bias, guided);
		}

		settings = { ...settings, totalChords: targetChords };
		blocks.push({
			kind: part.kind,
			settings,
			focusRoots,
			focusVoicing,
			targetChords,
			labelKey: COACH_LABEL_KEYS[part.kind],
			labelParams,
		});
	}

	const sayKey = isShort
		? reviewRoots.length > 0 && blocks.every((b) => b.kind === 'review')
			? COACH_SAY_KEYS.reviewOnly
			: COACH_SAY_KEYS.short
		: COACH_SAY_KEYS.full;

	return {
		blocks,
		sayKey,
		sayParams: {
			voicing: frontier.voicing,
			quality: frontier.quality,
			minutes: String(minutes),
			focusRoot: weak?.root ?? '',
		},
		estMinutes: minutes,
		frontierUnitId: frontier.id,
	};
}

/** Voicing of the highest mastered unit at or below the frontier; else frontier's. */
function nearestMasteredVoicing(ladder: SkillUnit[], state: CoachState, frontier: SkillUnit): VoicingType {
	for (let i = frontier.index - 1; i >= 0; i--) {
		if (isMastered(state, ladder[i].id)) return ladder[i].voicing;
	}
	return frontier.voicing;
}

// ─── Session analysis (shared by controller & feedback) ─────

interface UnitSessionStats {
	attempts: number;
	underThreshold: number;
	avgMs: number;
	/** true if any timing had explicit correctness info. */
	hasCorrectness: boolean;
	/** attempts that count as "good" (fast enough AND, if known, correct). */
	good: number;
}

/**
 * Score a session's timings against the mastery threshold for a given unit.
 * When `correct` is present it gates a "good" attempt; when undefined only
 * timing matters (back-compat with older sessions).
 */
function scoreSessionForUnit(
	timings: ChordTiming[],
	unit: SkillUnit,
	params: CoachParams,
): UnitSessionStats {
	// Only count timings whose root belongs to this unit's key set.
	const keySet = new Set(unit.keys);
	const relevant = timings.filter((t) => keySet.has(t.root));
	const window = relevant.slice(-params.masteryWindow);

	let underThreshold = 0;
	let good = 0;
	let sum = 0;
	let hasCorrectness = false;
	for (const t of window) {
		sum += t.durationMs;
		const fast = t.durationMs <= params.masteryThresholdMs;
		if (fast) underThreshold++;
		if (t.correct !== undefined) hasCorrectness = true;
		// A "good" attempt is fast AND (correct or correctness unknown).
		if (fast && t.correct !== false) good++;
	}

	return {
		attempts: window.length,
		underThreshold,
		avgMs: window.length ? sum / window.length : 0,
		hasCorrectness,
		good,
	};
}

// ─── 2. Controller ──────────────────────────────────────────

/**
 * Apply a completed session to the Coach state.
 *
 * Order of operations:
 *  1. difficultyBias already updated via applyFeedback() before this — untouched here.
 *  2. Calibration → placement (mark fast units mastered, set frontier).
 *  3. Frontier promotion / hold / demotion from this session's scoring.
 *  4. SRS lapse → decay mapped units toward practicing.
 *  5. Recompute frontier, bump dayIndex.
 */
export function applySessionToCoach(
	state: CoachState,
	plan: CoachPlan,
	session: SessionResult,
	params: CoachParams = DEFAULT_COACH_PARAMS,
	now: number = 0,
): CoachState {
	const ladder = buildSkillLadder();
	const next: CoachState = {
		...state,
		unitStates: { ...state.unitStates },
	};
	const timings = session.chordTimings ?? [];

	// ── Calibration placement ─────────────────────────────
	if (!next.calibrated) {
		placeByCalibration(ladder, next, timings, params);
		next.calibrated = true;
		next.frontierIndex = computeFrontierIndex(ladder, next);
		next.dayIndex = state.dayIndex + 1;
		return next;
	}

	// ── Frontier promotion / hold / demotion ──────────────
	// Target the unit the plan was built around (plan.frontierUnitId), NOT the
	// live-recomputed frontier. The plan is built once per session and reused for
	// every block, so this pins promotion to a single unit — the ladder can advance
	// at most ONE tier per session, however many blocks the session had.
	// Fall back to the live frontier for older plans without a frontierUnitId.
	const planFrontier =
		(plan.frontierUnitId ? ladder.find((u) => u.id === plan.frontierUnitId) : undefined) ??
		ladder[computeFrontierIndex(ladder, next)];
	// A block only trains the frontier when it drills the frontier's voicing.
	// Warmup/apply (mastered voicing) and focus (weak-spot voicing) blocks must
	// never promote the frontier just because their roots happen to overlap.
	const trainsFrontier = session.settings.voicing === planFrontier.voicing;
	// Never act on a unit that is already mastered (e.g. a later block of the same
	// session after the frontier was promoted by an earlier block).
	const alreadyMastered = isMastered(next, planFrontier.id);
	const frontier = planFrontier;
	const stats = trainsFrontier && !alreadyMastered
		? scoreSessionForUnit(timings, frontier, params)
		: { attempts: 0, underThreshold: 0, avgMs: 0, hasCorrectness: false, good: 0 };

	if (stats.attempts > 0) {
		const ratio = stats.good / stats.attempts;
		const prog = { ...unitProgress(next, frontier.id) };
		prog.lastTrainedAt = now;
		prog.bestAvgMs =
			prog.bestAvgMs === undefined ? stats.avgMs : Math.min(prog.bestAvgMs, stats.avgMs);

		if (ratio >= params.promotionRatio) {
			// Promotion — unit mastered, holds reset.
			prog.state = 'mastered';
			prog.holds = 0;
			next.unitStates[frontier.id] = prog;
		} else {
			// Hold — count it; escalate to (single-step) demotion after N holds.
			prog.state = prog.state === 'locked' ? 'learning' : prog.state;
			prog.holds = (prog.holds ?? 0) + 1;
			next.unitStates[frontier.id] = prog;

			if (prog.holds >= params.demotionAfterHolds) {
				demoteOneStep(ladder, next, frontier.index, params);
			}
		}
	}

	// ── SRS lapse → decay ─────────────────────────────────
	if (params.srsLapseDemotes) {
		decayLapsedUnits(ladder, next, session, params, now);
	}

	next.frontierIndex = computeFrontierIndex(ladder, next);
	next.dayIndex = state.dayIndex + 1;
	return next;
}

/**
 * Placement after calibration: any early unit the player cleared fast is marked
 * mastered ("mastered by placement"), so advanced players skip the beginner grind.
 * We only place along the easiest key tier and only contiguous from the bottom.
 */
function placeByCalibration(
	ladder: SkillUnit[],
	state: CoachState,
	timings: ChordTiming[],
	params: CoachParams,
): void {
	if (timings.length === 0) return;

	// Overall calibration speed decides how far to place.
	const avg = timings.reduce((s, t) => s + t.durationMs, 0) / timings.length;
	const fastEnough = avg <= params.masteryThresholdMs;
	if (!fastEnough) return; // slow calibration → stay at the very bottom.

	// Place ONLY the easy-tier beginner units as mastered, contiguous from the
	// bottom. Calibration proves the easiest keys — it does NOT prove the med/all
	// key tiers, which must still be earned session by session. (Bulk-clearing
	// med+all here was the source of the "mastered space explodes after one
	// session" bug — see docs/auto-mode-design.md §2.2 rule 1: one tier at a time.)
	for (const unit of ladder) {
		if (unit.difficulty !== 'beginner') break;
		if (unit.keyTier !== 'easy') continue;
		state.unitStates[unit.id] = {
			state: 'mastered',
			bestAvgMs: avg,
			holds: 0,
		};
	}
}

/** Demote: frontier back to 'practicing', drop one key tier if possible. Never more than one step. */
function demoteOneStep(
	ladder: SkillUnit[],
	state: CoachState,
	frontierIndex: number,
	_params: CoachParams,
): void {
	const frontier = ladder[frontierIndex];
	const prog = { ...unitProgress(state, frontier.id) };
	prog.state = 'practicing';
	prog.holds = 0; // reset after acting, so we don't demote repeatedly.
	state.unitStates[frontier.id] = prog;

	// If a lower key-tier rung of the same voicing×quality exists and is mastered,
	// knock it back to practicing (one step down the ladder) — but only one.
	const base = frontier.id.slice(0, frontier.id.lastIndexOf('|'));
	const lowerTier: KeyTier | null =
		frontier.keyTier === 'all' ? 'med' : frontier.keyTier === 'med' ? 'easy' : null;
	if (lowerTier) {
		const lowerId = `${base}|${lowerTier}`;
		if (state.unitStates[lowerId]?.state === 'mastered') {
			state.unitStates[lowerId] = {
				...state.unitStates[lowerId],
				state: 'practicing',
				holds: 0,
			};
		}
	}
}

/** Map overdue SRS entries to their units and decay mastered ones back to practicing. */
function decayLapsedUnits(
	ladder: SkillUnit[],
	state: CoachState,
	session: SessionResult,
	_params: CoachParams,
	now: number,
): void {
	const voicing = session.settings.voicing;
	// A lapse this session = a chord that was answered incorrectly (if known).
	const lapsedRoots = new Set(
		(session.chordTimings ?? []).filter((t) => t.correct === false).map((t) => t.root),
	);
	if (lapsedRoots.size === 0) return;

	for (const unit of ladder) {
		if (unit.voicing !== voicing) continue;
		if (state.unitStates[unit.id]?.state !== 'mastered') continue;
		// Does this unit cover any lapsed root?
		if (unit.keys.some((k) => lapsedRoots.has(k))) {
			state.unitStates[unit.id] = {
				...state.unitStates[unit.id],
				state: 'practicing',
				lastTrainedAt: now,
			};
		}
	}
}

// ─── Feedback bias ("too easy / too hard") ──────────────────

export type FeedbackSignal = 'tooEasy' | 'justRight' | 'tooHard';

/** Apply a single feedback tap, returning a new state with clamped bias. */
export function applyFeedback(
	state: CoachState,
	signal: FeedbackSignal,
	params: CoachParams = DEFAULT_COACH_PARAMS,
): CoachState {
	let bias = state.difficultyBias;
	if (signal === 'tooEasy') bias += params.feedbackBiasStep;
	else if (signal === 'tooHard') bias -= params.feedbackBiasStep;
	// justRight → no change.
	const c = params.feedbackBiasClamp;
	bias = Math.max(-c, Math.min(c, bias));
	return { ...state, difficultyBias: bias };
}

// ─── UI helpers ─────────────────────────────────────────────

/** Structured coach announcement for the QuickStart / TodayView. */
export function describeCoachPlan(plan: CoachPlan): { sayKey: string; sayParams: Record<string, string> } {
	return { sayKey: plan.sayKey, sayParams: plan.sayParams };
}

/**
 * Compare Coach state before/after a session and emit structured teacher talk.
 * Pure — returns keys + params, never localized strings.
 */
export function teacherFeedback(
	before: CoachState,
	after: CoachState,
	session: SessionResult,
	params: CoachParams = DEFAULT_COACH_PARAMS,
): TeacherStatement[] {
	const ladder = buildSkillLadder();
	const out: TeacherStatement[] = [];
	// One statement per unit id — guards against the same unit surfacing twice
	// (e.g. via both the per-unit scan and the held-frontier check).
	const spokenUnitIds = new Set<string>();

	// Calibration just finished.
	if (!before.calibrated && after.calibrated) {
		const placed = Object.values(after.unitStates).filter((u) => u.state === 'mastered').length;
		out.push({
			kind: 'calibrated',
			key: COACH_FEEDBACK_KEYS.calibrated,
			params: { placed: String(placed) },
		});
	}

	// Per-unit transitions. `tier` is carried so the text can say WHICH key stage
	// changed — without it "Next goal: Maj7 in Root Position" reads as a
	// contradiction right after "You already have Maj7 in Root Position".
	for (const unit of ladder) {
		const b = before.unitStates[unit.id]?.state ?? 'locked';
		const a = after.unitStates[unit.id]?.state ?? 'locked';
		if (b === a) continue;

		if (a === 'mastered') {
			// Placed vs promoted: placement happens only on the calibration session.
			const kind = !before.calibrated && after.calibrated ? 'placed' : 'promoted';
			out.push({
				kind,
				key: kind === 'placed' ? COACH_FEEDBACK_KEYS.placed : COACH_FEEDBACK_KEYS.promoted,
				params: unitParams(unit),
			});
			spokenUnitIds.add(unit.id);
		} else if (b === 'mastered' && a === 'practicing') {
			out.push({
				kind: 'demoted',
				key: COACH_FEEDBACK_KEYS.demoted,
				params: unitParams(unit),
			});
			spokenUnitIds.add(unit.id);
		}
	}

	// Held frontier (holds increased but no promotion).
	const frontierId = before.lastPlan?.frontierUnitId;
	if (frontierId && !spokenUnitIds.has(frontierId)) {
		const bh = before.unitStates[frontierId]?.holds ?? 0;
		const ah = after.unitStates[frontierId]?.holds ?? 0;
		const unit = ladder.find((u) => u.id === frontierId);
		if (ah > bh && unit && after.unitStates[frontierId]?.state !== 'mastered') {
			out.push({
				kind: 'held',
				key: COACH_FEEDBACK_KEYS.held,
				params: unitParams(unit),
			});
			spokenUnitIds.add(unit.id);
		}
	}

	// Improvement signal (avg faster than best-known for the frontier).
	if (session.avgMs > 0 && session.avgMs <= params.masteryThresholdMs) {
		out.push({
			kind: 'improved',
			key: COACH_FEEDBACK_KEYS.improved,
			params: { avgMs: String(Math.round(session.avgMs)) },
		});
	}

	// Next goal = new frontier after applying.
	const nextFrontier = ladder[computeFrontierIndex(ladder, after)];
	if (nextFrontier) {
		out.push({
			kind: 'nextGoal',
			key: COACH_FEEDBACK_KEYS.nextGoal,
			params: unitParams(nextFrontier),
		});
	}

	return out;
}

/** Statement params for a unit: quality + voicing + the key-tier it refers to. */
function unitParams(unit: SkillUnit): Record<string, string> {
	return { quality: unit.quality, voicing: unit.voicing, tier: unit.keyTier };
}
