import { describe, it, expect } from 'vitest';
import {
	buildSkillLadder,
	buildCoachPlan,
	applySessionToCoach,
	applyFeedback,
	teacherFeedback,
	createInitialCoachState,
	type CoachState,
	type CoachPlan,
	type SkillUnit,
} from './coach';
import { DEFAULT_COACH_PARAMS } from './coach-params';
import type { SessionResult, ChordTiming } from '../services/progress';
import type { HabitProfile } from './habits';
import { createDefaultProfile } from './habits';

// ─── Test helpers ───────────────────────────────────────────

function profile(overrides: Partial<HabitProfile> = {}): HabitProfile {
	return { ...createDefaultProfile(), ...overrides };
}

function timing(root: string, durationMs: number, correct?: boolean): ChordTiming {
	return { root, chord: `${root}X`, durationMs, correct };
}

function session(timings: ChordTiming[], voicing: SessionResult['settings']['voicing'] = 'root'): SessionResult {
	const avg = timings.length ? timings.reduce((s, t) => s + t.durationMs, 0) / timings.length : 0;
	return {
		id: 'test',
		timestamp: 0,
		elapsedMs: avg * timings.length,
		totalChords: timings.length,
		avgMs: avg,
		chordTimings: timings,
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing,
			displayMode: 'verify',
			accidentals: 'both',
			progressionMode: 'random',
		},
		midi: { enabled: false, accuracy: 0 },
	};
}

/** State where calibration is done but nothing mastered — frontier at unit 0. */
function calibratedState(): CoachState {
	return { ...createInitialCoachState(), calibrated: true };
}

// ─── Skill ladder ───────────────────────────────────────────

describe('buildSkillLadder', () => {
	it('is deterministic', () => {
		const a = buildSkillLadder();
		const b = buildSkillLadder();
		expect(a).toEqual(b);
	});

	it('produces 3 key tiers per unique voicing×quality, in curriculum order', () => {
		const ladder = buildSkillLadder();
		// First lesson is fundamentals maj7 root → easy/med/all first.
		expect(ladder[0]).toMatchObject({ voicing: 'root', quality: 'Maj7', keyTier: 'easy', index: 0 });
		expect(ladder[1]).toMatchObject({ voicing: 'root', quality: 'Maj7', keyTier: 'med', index: 1 });
		expect(ladder[2]).toMatchObject({ voicing: 'root', quality: 'Maj7', keyTier: 'all', index: 2 });
		// Length is a multiple of 3.
		expect(ladder.length % 3).toBe(0);
	});

	it('de-duplicates repeated voicing×quality pairs', () => {
		const ladder = buildSkillLadder();
		const pairs = new Set(ladder.map((u) => `${u.voicing}|${u.quality}`));
		// One pair == 3 units.
		expect(ladder.length).toBe(pairs.size * 3);
	});

	it('maps qualities to the lowest containing difficulty tier', () => {
		const ladder = buildSkillLadder();
		const maj7 = ladder.find((u) => u.quality === 'Maj7')!;
		expect(maj7.difficulty).toBe('beginner');
		const alt = ladder.find((u) => u.quality === '7#9');
		if (alt) expect(alt.difficulty).toBe('advanced');
	});
});

// ─── Promotion / Hold / Demotion ────────────────────────────

describe('applySessionToCoach — promotion', () => {
	it('promotes the frontier when ≥ promotionRatio of attempts are under threshold', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		// 10 attempts on the frontier's easy keys, all fast & correct.
		const timings = Array.from({ length: 10 }, (_, i) =>
			timing(frontier.keys[i % frontier.keys.length], 1500, true),
		);
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const next = applySessionToCoach(state, plan, session(timings, frontier.voicing), DEFAULT_COACH_PARAMS, 1000);
		expect(next.unitStates[frontier.id].state).toBe('mastered');
		expect(next.frontierIndex).toBeGreaterThan(0);
	});

	it('does NOT promote when below the ratio, and records a hold', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		// Half fast, half slow → ratio 0.5 < 0.8.
		const timings = [
			...Array.from({ length: 5 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 1500, true)),
			...Array.from({ length: 5 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 4000, true)),
		];
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const next = applySessionToCoach(state, plan, session(timings, frontier.voicing), DEFAULT_COACH_PARAMS, 1000);
		expect(next.unitStates[frontier.id].state).not.toBe('mastered');
		expect(next.unitStates[frontier.id].holds).toBe(1);
		expect(next.frontierIndex).toBe(0);
	});
});

// Chord timing with an explicit quality display in the name, for calibration tests.
function qTiming(root: string, quality: string, durationMs: number, correct?: boolean): ChordTiming {
	return { root, chord: `${root}${quality}`, durationMs, correct };
}

describe('adaptive calibration placement', () => {
	it('a beginner (only Maj7 solid) is placed at Maj7, no further', () => {
		const state = createInitialCoachState();
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		// Fast on Maj7, slow on the next quality (7).
		const timings = [
			qTiming('C', 'Maj7', 1000, true),
			qTiming('F', 'Maj7', 1100, true),
			qTiming('C', '7', 5000, true),
		];
		const next = applySessionToCoach(state, plan, session(timings, 'root'), DEFAULT_COACH_PARAMS, 1000);
		expect(next.calibrated).toBe(true);
		const ladder = buildSkillLadder();
		const maj7 = ladder.filter((u) => u.quality === 'Maj7' && u.voicing === 'root');
		const seven = ladder.filter((u) => u.quality === '7' && u.voicing === 'root');
		// All Maj7 tiers mastered…
		expect(maj7.every((u) => next.unitStates[u.id]?.state === 'mastered')).toBe(true);
		// …but 7 is not (it was slow).
		expect(seven.some((u) => next.unitStates[u.id]?.state === 'mastered')).toBe(false);
	});

	it('a pro (solid up several qualities) is placed high, contiguous', () => {
		const state = createInitialCoachState();
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		// Fast + clean on Maj7, 7, m7; then slow on 6.
		const timings = [
			qTiming('C', 'Maj7', 800, true),
			qTiming('C', '7', 900, true),
			qTiming('C', 'm7', 850, true),
			qTiming('C', '6', 4000, true),
		];
		const next = applySessionToCoach(state, plan, session(timings, 'root'), DEFAULT_COACH_PARAMS, 1000);
		const ladder = buildSkillLadder();
		for (const q of ['Maj7', '7', 'm7']) {
			expect(ladder.filter((u) => u.quality === q && u.voicing === 'root').every((u) => next.unitStates[u.id]?.state === 'mastered')).toBe(true);
		}
		expect(ladder.filter((u) => u.quality === '6' && u.voicing === 'root').some((u) => next.unitStates[u.id]?.state === 'mastered')).toBe(false);
	});

	it('stops at the first shaky quality even if a later one was fast (contiguous)', () => {
		const state = createInitialCoachState();
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const timings = [
			qTiming('C', 'Maj7', 800, true),
			qTiming('C', '7', 5000, true), // shaky
			qTiming('C', 'm7', 800, true), // fast but should NOT be placed (gap)
		];
		const next = applySessionToCoach(state, plan, session(timings, 'root'), DEFAULT_COACH_PARAMS, 1000);
		const ladder = buildSkillLadder();
		expect(ladder.filter((u) => u.quality === 'm7' && u.voicing === 'root').some((u) => next.unitStates[u.id]?.state === 'mastered')).toBe(false);
	});
});

describe('excellence threshold — climb several tiers in one excellent session', () => {
	it('an excellent session on Maj7 masters easy→med→all in one go', () => {
		const state = calibratedState(); // frontier at Maj7 root easy
		const ladder = buildSkillLadder();
		// The frontier is root|Maj7; only those three tiers should climb.
		const maj7Units = ladder.filter((u) => u.quality === 'Maj7' && u.voicing === 'root');
		// Excellent (well under 0.6×2000=1200ms), correct, covering all 12 keys.
		const allKeys = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
		const timings = allKeys.map((k) => qTiming(k, 'Maj7', 700, true));
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const next = applySessionToCoach(state, plan, session(timings, 'root'), DEFAULT_COACH_PARAMS, 1000);
		// All three root|Maj7 tiers mastered in this one excellent session.
		expect(maj7Units.every((u) => next.unitStates[u.id]?.state === 'mastered')).toBe(true);
	});

	it('a merely-passing session promotes only one tier (no explosion)', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		// Just under threshold (1500 < 2000) but NOT excellent (> 1200).
		const timings = frontier.keys.map((k) => qTiming(k, 'Maj7', 1500, true));
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const next = applySessionToCoach(state, plan, session(timings, 'root'), DEFAULT_COACH_PARAMS, 1000);
		const maj7Units = ladder.filter((u) => u.quality === 'Maj7' && u.voicing === 'root');
		const masteredCount = maj7Units.filter((u) => next.unitStates[u.id]?.state === 'mastered').length;
		expect(masteredCount).toBe(1); // only the easy tier
	});
});

describe('review block draws only mastered qualities', () => {
	it('with only Maj7 mastered, review pins to Maj7 (not the full pool)', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		// Master all Maj7 tiers so review has something to draw from.
		for (const u of ladder.filter((x) => x.quality === 'Maj7')) {
			state.unitStates[u.id] = { state: 'mastered', holds: 0 };
		}
		// Due review roots so a review block is included.
		const withDue = profile({
			chordSchedule: [
				{ chordKey: 'C-Maj7', root: 'C', quality: 'Maj7', lastReviewed: '2020-01-01', nextReview: '2020-01-01', interval: 1, ease: 2, repetitions: 1 },
			],
		});
		const plan = buildCoachPlan([], withDue, undefined, state, DEFAULT_COACH_PARAMS, Date.now());
		const review = plan.blocks.find((b) => b.kind === 'review');
		if (review) expect(review.focusQualities).toEqual(['Maj7']);
	});
});

describe('focusQualities — a block delivers only what it promises', () => {
	it('new block pins the pool to exactly the frontier quality', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[state.frontierIndex];
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const newBlock = plan.blocks.find((b) => b.kind === 'new');
		expect(newBlock).toBeDefined();
		expect(newBlock!.focusQualities).toEqual([frontier.quality]);
	});

	it('focus block pins the pool to the frontier quality', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[state.frontierIndex];
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const focusBlock = plan.blocks.find((b) => b.kind === 'focus');
		if (focusBlock) expect(focusBlock.focusQualities).toEqual([frontier.quality]);
	});

	it('warmup / review / apply leave the quality pool open (undefined)', () => {
		const state = calibratedState();
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		for (const b of plan.blocks) {
			if (b.kind === 'warmup' || b.kind === 'review' || b.kind === 'apply') {
				expect(b.focusQualities).toBeUndefined();
			}
		}
	});
});

describe('hold → guided escalation', () => {
	it('turns the new-block displayMode to always once the frontier has holds', () => {
		let state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		// First: a hold (no promotion).
		const slow = Array.from({ length: 6 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 4000, true));
		const plan0 = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		state = applySessionToCoach(state, plan0, session(slow, frontier.voicing), DEFAULT_COACH_PARAMS, 1000);
		expect(state.unitStates[frontier.id].holds).toBe(1);

		// Next plan: the new block must be guided (displayMode 'always').
		const plan1 = buildCoachPlan([], profile({ dailyGoalMinutes: 5 }), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const newBlock = plan1.blocks.find((b) => b.kind === 'new')!;
		expect(newBlock.settings.displayMode).toBe('always');
	});
});

describe('demotion', () => {
	it('demotes at most one step after demotionAfterHolds holds', () => {
		let state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		// Pre-master a lower key tier so there is something to knock back.
		// Master easy first, so med becomes frontier.
		const fast = Array.from({ length: 8 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 1400, true));
		let plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		state = applySessionToCoach(state, plan, session(fast, frontier.voicing), DEFAULT_COACH_PARAMS, 1000);
		expect(state.unitStates[ladder[0].id].state).toBe('mastered');
		const medUnit = ladder[1]; // same voicing×quality, med tier

		// Now two holds on the med frontier → demotion.
		const slow = Array.from({ length: 6 }, (_, i) => timing(medUnit.keys[i % medUnit.keys.length], 4000, true));
		for (let n = 0; n < DEFAULT_COACH_PARAMS.demotionAfterHolds; n++) {
			plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
			state = applySessionToCoach(state, plan, session(slow, medUnit.voicing), DEFAULT_COACH_PARAMS, 1000);
		}
		// The med unit is set to practicing (demoted), holds reset — not mastered.
		expect(state.unitStates[medUnit.id].state).toBe('practicing');
		expect(state.unitStates[medUnit.id].holds).toBe(0);
		// The lower (easy) rung dropped at most one step: from mastered → practicing.
		expect(state.unitStates[ladder[0].id].state).toBe('practicing');
	});
});

// ─── Short-session block mix ────────────────────────────────

describe('short session block mix', () => {
	it('drops warmup and apply for sessions under the cutoff', () => {
		const state = calibratedState();
		const plan = buildCoachPlan([], profile({ dailyGoalMinutes: 5 }), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const kinds = plan.blocks.map((b) => b.kind);
		expect(kinds).not.toContain('warmup');
		expect(kinds).not.toContain('apply');
		// review dropped because no SRS due → focus + new remain.
		expect(kinds).toContain('focus');
		expect(kinds).toContain('new');
	});

	it('includes warmup and apply for full-length sessions', () => {
		const state = calibratedState();
		const plan = buildCoachPlan([], profile({ dailyGoalMinutes: 15 }), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const kinds = plan.blocks.map((b) => b.kind);
		expect(kinds).toContain('warmup');
		expect(kinds).toContain('apply');
	});
});

// ─── Calibration ────────────────────────────────────────────

describe('calibration placement', () => {
	it('an uncalibrated user gets a single calibrate block', () => {
		const state = createInitialCoachState();
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		expect(plan.blocks).toHaveLength(1);
		expect(plan.blocks[0].kind).toBe('calibrate');
		expect(plan.blocks[0].targetChords).toBe(DEFAULT_COACH_PARAMS.calibrationChords);
	});

	it('fast calibration skips beginner units (mastered by placement)', () => {
		const state = createInitialCoachState();
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		// Very fast calibration, solid on Maj7.
		const timings = ['C', 'F', 'Bb', 'Eb'].map((k) => qTiming(k, 'Maj7', 1200, true));
		const next = applySessionToCoach(state, plan, session(timings), DEFAULT_COACH_PARAMS, 1000);
		expect(next.calibrated).toBe(true);
		const mastered = Object.values(next.unitStates).filter((u) => u.state === 'mastered');
		expect(mastered.length).toBeGreaterThan(0);
		// Frontier moved past unit 0.
		expect(next.frontierIndex).toBeGreaterThan(0);
	});

	it('slow calibration stays at the bottom rung', () => {
		const state = createInitialCoachState();
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const timings = ['C', 'F', 'Bb', 'Eb'].map((k) => qTiming(k, 'Maj7', 5000, true));
		const next = applySessionToCoach(state, plan, session(timings), DEFAULT_COACH_PARAMS, 1000);
		expect(next.calibrated).toBe(true);
		expect(next.frontierIndex).toBe(0);
	});
});

// ─── difficultyBias clamp ───────────────────────────────────

describe('difficultyBias clamp', () => {
	it('clamps to +clamp after many too-easy taps', () => {
		let state = createInitialCoachState();
		for (let i = 0; i < 20; i++) state = applyFeedback(state, 'tooEasy');
		expect(state.difficultyBias).toBe(DEFAULT_COACH_PARAMS.feedbackBiasClamp);
	});

	it('clamps to -clamp after many too-hard taps', () => {
		let state = createInitialCoachState();
		for (let i = 0; i < 20; i++) state = applyFeedback(state, 'tooHard');
		expect(state.difficultyBias).toBe(-DEFAULT_COACH_PARAMS.feedbackBiasClamp);
	});

	it('justRight leaves bias unchanged', () => {
		const state = { ...createInitialCoachState(), difficultyBias: 0.2 };
		expect(applyFeedback(state, 'justRight').difficultyBias).toBe(0.2);
	});

	it('a strong positive bias raises the new-block difficulty', () => {
		const state = { ...calibratedState(), difficultyBias: 0.5 };
		const plan = buildCoachPlan([], profile({ dailyGoalMinutes: 5 }), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const newBlock = plan.blocks.find((b) => b.kind === 'new')!;
		// frontier unit 0 is beginner; +0.5 bias bumps to intermediate.
		expect(newBlock.settings.difficulty).toBe('intermediate');
	});
});

// ─── correct === undefined handling ─────────────────────────

describe('correct === undefined (legacy sessions)', () => {
	it('promotes on timing alone when correctness is unknown', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		// Fast timings, correct undefined → still counts as good.
		const timings = Array.from({ length: 10 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 1500));
		expect(timings.every((t) => t.correct === undefined)).toBe(true);
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const next = applySessionToCoach(state, plan, session(timings, frontier.voicing), DEFAULT_COACH_PARAMS, 1000);
		expect(next.unitStates[frontier.id].state).toBe('mastered');
	});

	it('correct === false blocks a "good" attempt even when fast', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		// All fast but marked incorrect → ratio 0 → hold, not promotion.
		const timings = Array.from({ length: 10 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 1500, false));
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const next = applySessionToCoach(state, plan, session(timings, frontier.voicing), DEFAULT_COACH_PARAMS, 1000);
		expect(next.unitStates[frontier.id].state).not.toBe('mastered');
	});
});

// ─── teacherFeedback ────────────────────────────────────────

describe('teacherFeedback', () => {
	it('emits a promoted statement and a nextGoal', () => {
		const before = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		const timings = Array.from({ length: 10 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 1500, true));
		const plan = buildCoachPlan([], profile(), undefined, before, DEFAULT_COACH_PARAMS, 0);
		const s = session(timings, frontier.voicing);
		const after = applySessionToCoach(before, plan, s, DEFAULT_COACH_PARAMS, 1000);
		const fb = teacherFeedback({ ...before, lastPlan: plan }, after, s, DEFAULT_COACH_PARAMS);
		expect(fb.some((f) => f.kind === 'promoted')).toBe(true);
		expect(fb.some((f) => f.kind === 'nextGoal')).toBe(true);
		// No hard-coded prose: every statement is a key + params.
		for (const f of fb) {
			expect(typeof f.key).toBe('string');
			expect(f.key.startsWith('coach.')).toBe(true);
		}
	});

	it('every unit statement carries a key-tier param (Bug 3)', () => {
		const before = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		const timings = Array.from({ length: 10 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 1500, true));
		const plan = buildCoachPlan([], profile(), undefined, before, DEFAULT_COACH_PARAMS, 0);
		const s = session(timings, frontier.voicing);
		const after = applySessionToCoach(before, plan, s, DEFAULT_COACH_PARAMS, 1000);
		const fb = teacherFeedback({ ...before, lastPlan: plan }, after, s, DEFAULT_COACH_PARAMS);
		// promoted / nextGoal name a concrete unit → must include tier so
		// "already have it" and "next goal" cannot read as a contradiction.
		for (const f of fb) {
			if (f.kind === 'promoted' || f.kind === 'placed' || f.kind === 'held' || f.kind === 'demoted' || f.kind === 'nextGoal') {
				expect(['easy', 'med', 'all']).toContain(f.params.tier);
			}
		}
	});

	it('emits at most one statement per unit id (Bug 2 — no doubles)', () => {
		const before = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		const timings = Array.from({ length: 10 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 1500, true));
		const plan = buildCoachPlan([], profile(), undefined, before, DEFAULT_COACH_PARAMS, 0);
		const s = session(timings, frontier.voicing);
		const after = applySessionToCoach(before, plan, s, DEFAULT_COACH_PARAMS, 1000);
		const fb = teacherFeedback({ ...before, lastPlan: plan }, after, s, DEFAULT_COACH_PARAMS);
		// No two unit-statements share the same rendered (quality, voicing, tier).
		const unitLines = fb
			.filter((f) => f.params.tier !== undefined)
			.map((f) => `${f.params.quality}|${f.params.voicing}|${f.params.tier}`);
		expect(new Set(unitLines).size).toBe(unitLines.length);
	});
});

// ─── Bug 1: promotion is bounded to the trained frontier unit ────

describe('promotion cannot explode across tiers (Bug 1)', () => {
	it('a good session on the easy unit does NOT master med+all with it', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0]; // easy
		const medUnit = ladder[1];
		const allUnit = ladder[2];
		// Timings cover EVERY key (as the shared picker's full note pool would),
		// all fast & correct — the tempting-but-wrong "master everything" input.
		const allKeys = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
		const timings = allKeys.concat(allKeys).map((r) => timing(r, 1400, true));
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const next = applySessionToCoach(state, plan, session(timings, frontier.voicing), DEFAULT_COACH_PARAMS, 1000);
		expect(next.unitStates[frontier.id]?.state).toBe('mastered');
		// The higher tiers of the same voicing×quality must NOT be promoted.
		expect(next.unitStates[medUnit.id]?.state).not.toBe('mastered');
		expect(next.unitStates[allUnit.id]?.state).not.toBe('mastered');
	});

	it('a block that is not the frontier voicing does not promote the frontier', () => {
		const state = calibratedState();
		const ladder = buildSkillLadder();
		const frontier = ladder[0];
		// Same fast timings on the frontier's keys, but the session voicing is a
		// different voicing (a warmup/apply block) → must NOT promote the frontier.
		const otherVoicing: SkillUnit['voicing'] = frontier.voicing === 'shell' ? 'root' : 'shell';
		const timings = Array.from({ length: 10 }, (_, i) => timing(frontier.keys[i % frontier.keys.length], 1400, true));
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const next = applySessionToCoach(state, plan, session(timings, otherVoicing), DEFAULT_COACH_PARAMS, 1000);
		expect(next.unitStates[frontier.id]?.state).not.toBe('mastered');
		expect(next.frontierIndex).toBe(0);
	});

	it('calibration only places the tested voicing, never other voicings', () => {
		const state = createInitialCoachState();
		const plan = buildCoachPlan([], profile(), undefined, state, DEFAULT_COACH_PARAMS, 0);
		// Solid on Maj7 in the calibration (root) voicing.
		const timings = ['C', 'F', 'Bb', 'Eb'].map((k) => qTiming(k, 'Maj7', 1000, true));
		const next = applySessionToCoach(state, plan, session(timings), DEFAULT_COACH_PARAMS, 1000);
		const ladder = buildSkillLadder();
		for (const [id, prog] of Object.entries(next.unitStates)) {
			if (prog.state !== 'mastered') continue;
			const unit = ladder.find((u) => u.id === id)!;
			expect(unit.voicing).toBe('root');
		}
	});

	it('an entire multi-block session advances the frontier at most one tier', () => {
		let state = calibratedState();
		const ladder = buildSkillLadder();
		const before = computeMastered(state);
		// One session's plan, reused across ALL its blocks (as the app does).
		const plan = buildCoachPlan([], profile({ dailyGoalMinutes: 20 }), undefined, state, DEFAULT_COACH_PARAMS, 0);
		const allKeys = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
		for (const block of plan.blocks) {
			const roots = Array.from({ length: block.targetChords }, (_, i) => allKeys[i % 12]);
			const bs = session(roots.map((r) => timing(r, 1400, true)), block.settings.voicing);
			state = applySessionToCoach(state, plan, bs, DEFAULT_COACH_PARAMS, 1000);
		}
		// At most ONE newly-mastered unit across the whole session.
		expect(computeMastered(state) - before).toBeLessThanOrEqual(1);
		void ladder;
	});
});

function computeMastered(s: CoachState): number {
	return Object.values(s.unitStates).filter((u) => u.state === 'mastered').length;
}
