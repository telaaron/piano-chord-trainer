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
}

export const DEFAULT_COACH_PARAMS: CoachParams = {
	masteryThresholdMs: 2000,
	masteryWindow: 20,
	promotionRatio: 0.8,
	demotionAfterHolds: 2,
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
	chordsPerMinute: 8,
	minBlockChords: 4,
};
