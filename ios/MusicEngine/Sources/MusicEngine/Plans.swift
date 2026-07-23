// Practice Plans — curated presets that guide the player.
// 1:1 port of src/lib/engine/plans.ts. Plan name/tagline/description are i18n keys
// (resolved by the app's localization layer). `accent` is a CSS-token string the
// Theme maps to a Color. `icon` is the original emoji (UI may map to SF Symbols).

import Foundation

public enum PlanLevel: String, Sendable {
    case beginner
    case intermediate
    case advanced
}

public struct PlanSettings: Sendable, Equatable {
    public let difficulty: Difficulty
    public let notation: NotationStyle
    public let voicing: VoicingType
    public let displayMode: DisplayMode
    public let accidentals: AccidentalPreference
    public let progressionMode: ProgressionMode
    public let totalChords: Int
    public let vlMode: VoiceLeadingMode?

    public init(
        difficulty: Difficulty,
        notation: NotationStyle,
        voicing: VoicingType,
        displayMode: DisplayMode,
        accidentals: AccidentalPreference,
        progressionMode: ProgressionMode,
        totalChords: Int,
        vlMode: VoiceLeadingMode? = nil
    ) {
        self.difficulty = difficulty
        self.notation = notation
        self.voicing = voicing
        self.displayMode = displayMode
        self.accidentals = accidentals
        self.progressionMode = progressionMode
        self.totalChords = totalChords
        self.vlMode = vlMode
    }
}

public struct PracticePlan: Sendable, Equatable {
    public let id: String
    public let name: String
    public let tagline: String
    public let description: String
    public let icon: String
    public let accent: String
    public let level: PlanLevel
    public let settings: PlanSettings
    /// Optional roots to weight the adaptive pool toward (weak-spot drills). nil = no focus.
    public let focusRoots: [String]?
    /// Optional voicing the focus roots were weakest in (for display only).
    public let focusVoicing: String?

    public init(id: String, name: String, tagline: String, description: String,
                icon: String, accent: String, level: PlanLevel, settings: PlanSettings,
                focusRoots: [String]? = nil, focusVoicing: String? = nil) {
        self.id = id; self.name = name; self.tagline = tagline; self.description = description
        self.icon = icon; self.accent = accent; self.level = level; self.settings = settings
        self.focusRoots = focusRoots; self.focusVoicing = focusVoicing
    }
}

public let PRACTICE_PLANS: [PracticePlan] = [
    PracticePlan(id: "warmup", name: "plans.warmup_name", tagline: "plans.warmup_tagline", description: "plans.warmup_desc", icon: "", accent: "var(--accent-amber)", level: .beginner,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: .shell, displayMode: .always, accidentals: .both, progressionMode: .twoFiveOne, totalChords: 36)),
    PracticePlan(id: "speed", name: "plans.speed_name", tagline: "plans.speed_tagline", description: "plans.speed_desc", icon: "", accent: "var(--accent-red)", level: .beginner,
        settings: PlanSettings(difficulty: .intermediate, notation: .standard, voicing: .root, displayMode: .off, accidentals: .both, progressionMode: .random, totalChords: 20)),
    PracticePlan(id: "deepdive", name: "plans.deepdive_name", tagline: "plans.deepdive_tagline", description: "plans.deepdive_desc", icon: "", accent: "var(--primary)", level: .intermediate,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: .full, displayMode: .verify, accidentals: .both, progressionMode: .oneSixTwoFive, totalChords: 48)),
    PracticePlan(id: "turnaround", name: "plans.turnaround_name", tagline: "plans.turnaround_tagline", description: "plans.turnaround_desc", icon: "", accent: "var(--accent-purple)", level: .intermediate,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: .shell, displayMode: .verify, accidentals: .both, progressionMode: .oneSixTwoFive, totalChords: 48)),
    PracticePlan(id: "challenge", name: "plans.challenge_name", tagline: "plans.challenge_tagline", description: "plans.challenge_desc", icon: "", accent: "var(--accent-green)", level: .advanced,
        settings: PlanSettings(difficulty: .advanced, notation: .symbols, voicing: .shell, displayMode: .off, accidentals: .both, progressionMode: .random, totalChords: 30)),
    PracticePlan(id: "quartenzirkel", name: "plans.quartenzirkel_name", tagline: "plans.quartenzirkel_tagline", description: "plans.quartenzirkel_desc", icon: "", accent: "var(--accent-amber)", level: .intermediate,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: .halfShell, displayMode: .verify, accidentals: .flats, progressionMode: .cycleOf4ths, totalChords: 12)),
    PracticePlan(id: "voicing-drill", name: "plans.voicing_drill_name", tagline: "plans.voicing_drill_tagline", description: "plans.voicing_drill_desc", icon: "", accent: "var(--primary)", level: .intermediate,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: .root, displayMode: .verify, accidentals: .both, progressionMode: .threeSixTwoFive, totalChords: 48)),
    PracticePlan(id: "left-hand-comping", name: "plans.left_hand_comping_name", tagline: "plans.left_hand_comping_tagline", description: "plans.left_hand_comping_desc", icon: "", accent: "var(--accent-amber)", level: .advanced,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: .rootlessA, displayMode: .verify, accidentals: .both, progressionMode: .cycleOf4ths, totalChords: 48)),
    PracticePlan(id: "inversions-drill", name: "plans.inversions_drill_name", tagline: "plans.inversions_drill_tagline", description: "plans.inversions_drill_desc", icon: "", accent: "var(--accent-purple)", level: .advanced,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: .inversion1, displayMode: .verify, accidentals: .both, progressionMode: .oneFourFive, totalChords: 36)),
    PracticePlan(id: "in-time-comping", name: "plans.in_time_comping_name", tagline: "plans.in_time_comping_tagline", description: "plans.in_time_comping_desc", icon: "", accent: "var(--accent-green)", level: .intermediate,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: .shell, displayMode: .always, accidentals: .both, progressionMode: .threeSixTwoFive, totalChords: 48)),
    PracticePlan(id: "ear-check", name: "plans.ear_check_name", tagline: "plans.ear_check_tagline", description: "plans.ear_check_desc", icon: "", accent: "var(--accent-amber)", level: .intermediate,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: .root, displayMode: .off, accidentals: .both, progressionMode: .random, totalChords: 12)),
    PracticePlan(id: "adaptive-drill", name: "plans.adaptive_drill_name", tagline: "plans.adaptive_drill_tagline", description: "plans.adaptive_drill_desc", icon: "", accent: "var(--accent-purple)", level: .intermediate,
        settings: PlanSettings(difficulty: .intermediate, notation: .standard, voicing: .shell, displayMode: .verify, accidentals: .both, progressionMode: .random, totalChords: 20)),
    PracticePlan(id: "voice-leading-flow", name: "plans.voice_leading_flow_name", tagline: "plans.voice_leading_flow_tagline", description: "plans.voice_leading_flow_desc", icon: "", accent: "var(--primary)", level: .intermediate,
        settings: PlanSettings(difficulty: .intermediate, notation: .standard, voicing: .shell, displayMode: .always, accidentals: .both, progressionMode: .diatonic, totalChords: 84, vlMode: .guided)),
]

/// Build a focused "drill your weak spots" plan from session history.
/// Concentrates on the roots you're slowest at (in their weakest voicing) and —
/// crucially — hides the answer (`.verify`) so the drill is a real test, not a copy.
/// Returns nil if there isn't enough history to name any weak spots yet.
public func makeWeakDrillPlan(_ history: [SessionResult], limit: Int = 5) -> PracticePlan? {
    let spots = analyzeWeakSpots(history, limit)
    guard !spots.isEmpty else { return nil }

    // Pick the voicing that dominates the weak list; drill its worst roots.
    var byVoicing: [VoicingType: [WeakSpot]] = [:]
    for s in spots { byVoicing[s.voicing, default: []].append(s) }
    let (voicing, worst) = byVoicing.max(by: { $0.value.count < $1.value.count })
        ?? (spots[0].voicing, spots)
    let roots = Array(worst.prefix(limit).map { $0.root })

    return PracticePlan(
        id: "weak-drill",
        name: "plans.weak_drill_name", tagline: "plans.weak_drill_tagline", description: "plans.weak_drill_desc",
        icon: "", accent: "var(--primary)", level: .intermediate,
        settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: voicing,
                               displayMode: .verify, accidentals: .both,
                               progressionMode: .random, totalChords: 20),
        focusRoots: roots, focusVoicing: voicing.rawValue)
}

/// Suggest a plan based on session history.
public func suggestPlan(_ recentPlanIds: [String], _ totalSessions: Int) -> PracticePlan {
    let maxLevel: PlanLevel = totalSessions < 6 ? .beginner : totalSessions < 20 ? .intermediate : .advanced
    let levelRank: [PlanLevel: Int] = [.beginner: 0, .intermediate: 1, .advanced: 2]
    let eligible = PRACTICE_PLANS.filter { levelRank[$0.level]! <= levelRank[maxLevel]! }
    let pool = eligible.isEmpty ? PRACTICE_PLANS : eligible

    if totalSessions == 0 {
        return pool.first { $0.id == "warmup" } ?? pool[0]
    }

    let unused = pool.filter { !recentPlanIds.contains($0.id) }
    if !unused.isEmpty { return unused[0] }

    return pool[totalSessions % pool.count]
}
