// Coach parameters — every tunable knob of the Auto-Mode ("Coach") in ONE place.
// Pure data, no logic. Ported 1:1 to Swift (ios/MusicEngine/.../CoachParams.swift).
//
// Keeping every threshold here (instead of scattering magic numbers through
// coach.ts) makes the controller's behaviour auditable and lets us A/B-tune
// without touching the control-flow code.

/** Relative frequency each block gets when composing a full-length session. */
export interface BlockMix {
	warmup: number;
	review: number;
	focus: number;
	new: number;
	apply: number;
}

/** Selection weights mirrored from adaptive.ts so the Coach and the picker agree. */
export interface CoachWeights {
	/** Slow / weak chords. Matches adaptive WEIGHT_WEAK. */
	weak: number;
	/** Never-seen chords. Matches adaptive WEIGHT_NEW. */
	new: number;
	/** Fast / mastered chords. Matches adaptive WEIGHT_STRONG. */
	strong: number;
	/** Focused-drill roots. Matches adaptive WEIGHT_FOCUS. */
	focus: number;
}

export interface CoachParams {
	/** Avg ms per chord below which a unit counts as "mastered". Mirrors MASTERY_THRESHOLD_MS. */
	masteryThresholdMs: number;
	/** How many recent attempts (per unit) the mastery window looks back over. */
	masteryWindow: number;
	/** Fraction of windowed attempts that must be under threshold to promote (0..1). */
	promotionRatio: number;
	/** Consecutive holds on the frontier before a (single-step) demotion kicks in. */
	demotionAfterHolds: number;
	/**
	 * Sessions stuck on one rung before the coach eases it instead of repeating.
	 *
	 * Without this a player who kept just missing the bar saw the same session
	 * every single day: `holds` reset on each demotion, so the escalation never
	 * fired and the frontier never moved. Past this many sessions the rung is
	 * granted on the evidence the player *has* shown — they have demonstrably
	 * put in the work, and drilling the identical block a seventh time teaches
	 * nothing.
	 */
	easeAfterStuckSessions: number;
	/** Relative block sizes for a full session. */
	blockMix: BlockMix;
	/** Sessions shorter than this (minutes) drop warmup/apply and only run review/focus/new. */
	shortSessionCutoffMin: number;
	/** Selection weights handed to the weighted picker. */
	weights: CoachWeights;
	/** How many chords the one-time calibration drill presents. */
	calibrationChords: number;
	/** Per "too easy / too hard" tap, how far difficultyBias moves. */
	feedbackBiasStep: number;
	/** Absolute clamp on difficultyBias (± this value). */
	feedbackBiasClamp: number;
	/** When true, an overdue SRS lapse decays the mapped unit back toward practicing. */
	srsLapseDemotes: boolean;
	/** Target chords per minute — turns a block's minute budget into a chord count. */
	chordsPerMinute: number;
	/** Minimum number of chords any block will ever request. */
	minBlockChords: number;
	/**
	 * Ceiling on a single block. Past roughly this many chords of one quality a
	 * block stops being a focused drill and becomes a slog — and the player
	 * loses track of where they are in the session.
	 */
	maxBlockChords: number;
	/**
	 * Fraction of masteryThresholdMs below which a block counts as "excellent".
	 * An excellent block promotes even the LIVE frontier (not just the plan's),
	 * so a player who's clearly on top of a quality climbs several key-tiers in a
	 * single session — one tier per block — instead of one tier per session.
	 */
	excellentFactor: number;
	/** Consecutive sessions of real struggle before offering "too hard? start easier". */
	struggleSessionsBeforeOffer: number;
	/** How many recently-mastered qualities the review block may mix. */
	reviewQualityCap: number;
}

export const DEFAULT_COACH_PARAMS: CoachParams = {
	masteryThresholdMs: 2000,
	masteryWindow: 20,
	promotionRatio: 0.8,
	demotionAfterHolds: 2,
	// Six sessions on one rung is roughly a week of daily practice. Long enough
	// that it is not luck, short enough that nobody spends a fortnight there.
	easeAfterStuckSessions: 6,
	blockMix: {
		warmup: 0.15,
		review: 0.2,
		focus: 0.25,
		new: 0.25,
		apply: 0.15,
	},
	shortSessionCutoffMin: 8,
	weights: {
		weak: 4.0,
		new: 2.5,
		strong: 0.3,
		focus: 10.0,
	},
	calibrationChords: 12,
	feedbackBiasStep: 0.15,
	feedbackBiasClamp: 0.5,
	srsLapseDemotes: true,
	// A chord takes real thinking time: recall it, find it, play it, check it,
	// read the feedback. Four a minute (~15s each) matches how a session
	// actually plays out — eight made a "5 minute" session run to forty chords.
	chordsPerMinute: 4,
	minBlockChords: 4,
	maxBlockChords: 10,
	excellentFactor: 0.6,
	struggleSessionsBeforeOffer: 2,
	reviewQualityCap: 2,
};
