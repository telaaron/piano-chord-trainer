// Coach parameters — every tunable knob of the Auto-Mode ("Coach") in ONE place.
// Pure data, no logic. 1:1 port of src/lib/engine/coach-params.ts.
//
// Keeping every threshold here (instead of scattering magic numbers through
// Coach.swift) makes the controller's behaviour auditable and lets us A/B-tune
// without touching the control-flow code.

import Foundation

/// Relative frequency each block gets when composing a full-length session.
public struct BlockMix: Sendable, Equatable, Codable {
    public var warmup: Double
    public var review: Double
    public var focus: Double
    public var new: Double
    public var apply: Double

    public init(warmup: Double, review: Double, focus: Double, new: Double, apply: Double) {
        self.warmup = warmup
        self.review = review
        self.focus = focus
        self.new = new
        self.apply = apply
    }
}

/// Selection weights mirrored from adaptive.ts so the Coach and the picker agree.
public struct CoachWeights: Sendable, Equatable, Codable {
    /// Slow / weak chords. Matches adaptive WEIGHT_WEAK.
    public var weak: Double
    /// Never-seen chords. Matches adaptive WEIGHT_NEW.
    public var new: Double
    /// Fast / mastered chords. Matches adaptive WEIGHT_STRONG.
    public var strong: Double
    /// Focused-drill roots. Matches adaptive WEIGHT_FOCUS.
    public var focus: Double

    public init(weak: Double, new: Double, strong: Double, focus: Double) {
        self.weak = weak
        self.new = new
        self.strong = strong
        self.focus = focus
    }
}

public struct CoachParams: Sendable, Equatable, Codable {
    /// Avg ms per chord below which a unit counts as "mastered". Mirrors MASTERY_THRESHOLD_MS.
    public var masteryThresholdMs: Double
    /// How many recent attempts (per unit) the mastery window looks back over.
    public var masteryWindow: Int
    /// Fraction of windowed attempts that must be under threshold to promote (0..1).
    public var promotionRatio: Double
    /// Consecutive holds on the frontier before a (single-step) demotion kicks in.
    public var demotionAfterHolds: Int
    /// Relative block sizes for a full session.
    public var blockMix: BlockMix
    /// Sessions shorter than this (minutes) drop warmup/apply and only run review/focus/new.
    public var shortSessionCutoffMin: Int
    /// Selection weights handed to the weighted picker.
    public var weights: CoachWeights
    /// How many chords the one-time calibration drill presents.
    public var calibrationChords: Int
    /// Per "too easy / too hard" tap, how far difficultyBias moves.
    public var feedbackBiasStep: Double
    /// Absolute clamp on difficultyBias (± this value).
    public var feedbackBiasClamp: Double
    /// When true, an overdue SRS lapse decays the mapped unit back toward practicing.
    public var srsLapseDemotes: Bool
    /// Target chords per minute — turns a block's minute budget into a chord count.
    public var chordsPerMinute: Double
    /// Minimum number of chords any block will ever request.
    public var minBlockChords: Int
    /// Fraction of masteryThresholdMs below which a block counts as "excellent".
    /// An excellent block promotes even the LIVE frontier (not just the plan's),
    /// so a player who's clearly on top of a quality climbs several key-tiers in a
    /// single session — one tier per block — instead of one tier per session.
    public var excellentFactor: Double
    /// Consecutive sessions of real struggle before offering "too hard? start easier".
    public var struggleSessionsBeforeOffer: Int

    public init(masteryThresholdMs: Double, masteryWindow: Int, promotionRatio: Double,
                demotionAfterHolds: Int, blockMix: BlockMix, shortSessionCutoffMin: Int,
                weights: CoachWeights, calibrationChords: Int, feedbackBiasStep: Double,
                feedbackBiasClamp: Double, srsLapseDemotes: Bool, chordsPerMinute: Double,
                minBlockChords: Int, excellentFactor: Double, struggleSessionsBeforeOffer: Int) {
        self.masteryThresholdMs = masteryThresholdMs
        self.masteryWindow = masteryWindow
        self.promotionRatio = promotionRatio
        self.demotionAfterHolds = demotionAfterHolds
        self.blockMix = blockMix
        self.shortSessionCutoffMin = shortSessionCutoffMin
        self.weights = weights
        self.calibrationChords = calibrationChords
        self.feedbackBiasStep = feedbackBiasStep
        self.feedbackBiasClamp = feedbackBiasClamp
        self.srsLapseDemotes = srsLapseDemotes
        self.chordsPerMinute = chordsPerMinute
        self.minBlockChords = minBlockChords
        self.excellentFactor = excellentFactor
        self.struggleSessionsBeforeOffer = struggleSessionsBeforeOffer
    }
}

public let DEFAULT_COACH_PARAMS = CoachParams(
    masteryThresholdMs: 2000,
    masteryWindow: 20,
    promotionRatio: 0.8,
    demotionAfterHolds: 2,
    blockMix: BlockMix(warmup: 0.15, review: 0.2, focus: 0.25, new: 0.25, apply: 0.15),
    shortSessionCutoffMin: 8,
    weights: CoachWeights(weak: 4.0, new: 2.5, strong: 0.3, focus: 10.0),
    calibrationChords: 12,
    feedbackBiasStep: 0.15,
    feedbackBiasClamp: 0.5,
    srsLapseDemotes: true,
    chordsPerMinute: 8,
    minBlockChords: 4,
    excellentFactor: 0.6,
    struggleSessionsBeforeOffer: 2
)
