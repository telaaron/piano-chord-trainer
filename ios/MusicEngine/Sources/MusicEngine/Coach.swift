// Coach — the Auto-Mode engine ("your teacher in one tap").
//
// Three layers (see docs/auto-mode-design.md):
//   1. Skill-Map     — buildSkillLadder(): what the player can do, as a ladder of units.
//   2. Controller    — applySessionToCoach(): promote / hold / demote after each session.
//   3. Composer      — buildCoachPlan(): today's session as a sequence of blocks.
//
// 1:1 port of src/lib/engine/coach.ts. Pure — no Date.now(), no persistence.
// Time enters as `now` (ms since epoch, Double — mirrors the TS `now: number`).
//
// CoachState is persisted and rides the jsonb-blob sync, so every Codable key
// MUST match the TS field names exactly (camelCase). Optionals are omitted when
// nil (JSONEncoder default), matching TS `undefined` fields being absent.

import Foundation

// ─── Public types ───────────────────────────────────────────

public enum KeyTier: String, Sendable, Equatable, Codable {
    case easy, med, all
}

public enum UnitState: String, Sendable, Equatable, Codable {
    case locked, learning, practicing, mastered
}

/// A rung on the skill ladder: one voicing × quality × key-tier.
public struct SkillUnit: Sendable, Equatable {
    /// Stable id, e.g. "shell|Maj7|easy".
    public let id: String
    public let voicing: VoicingType
    /// Quality display string, e.g. "Maj7" (matches ChordType.display).
    public let quality: String
    public let keyTier: KeyTier
    /// Concrete root notes this unit drills.
    public let keys: [String]
    /// Lowest difficulty tier whose chord pool contains `quality`.
    public let difficulty: Difficulty
    /// Curriculum-order index (0 = first rung).
    public let index: Int
    /// i18n key for the module this unit belongs to (for teacher-talk).
    public let moduleTitleKey: String

    public init(id: String, voicing: VoicingType, quality: String, keyTier: KeyTier,
                keys: [String], difficulty: Difficulty, index: Int, moduleTitleKey: String) {
        self.id = id
        self.voicing = voicing
        self.quality = quality
        self.keyTier = keyTier
        self.keys = keys
        self.difficulty = difficulty
        self.index = index
        self.moduleTitleKey = moduleTitleKey
    }
}

public struct UnitProgress: Sendable, Equatable, Codable {
    public var state: UnitState
    /// Best windowed average ms seen so far (lower = better).
    public var bestAvgMs: Double?
    /// `now` of the last session that trained this unit.
    public var lastTrainedAt: Double?
    /// Consecutive holds (missed the threshold) on this unit while it was the frontier.
    public var holds: Int

    public init(state: UnitState, bestAvgMs: Double? = nil, lastTrainedAt: Double? = nil, holds: Int) {
        self.state = state
        self.bestAvgMs = bestAvgMs
        self.lastTrainedAt = lastTrainedAt
        self.holds = holds
    }
}

public struct CoachState: Sendable, Equatable, Codable {
    public var version: Int
    /// Per-unit progress, keyed by SkillUnit.id. Sparse — absent = 'locked'.
    public var unitStates: [String: UnitProgress]
    /// Index of the frontier unit (first non-mastered rung).
    public var frontierIndex: Int
    /// Monotonic counter for deterministic block rotation.
    public var dayIndex: Int
    /// -clamp..+clamp from "too easy / too hard". Positive = wants it harder.
    public var difficultyBias: Double
    /// Whether the one-time calibration has run.
    public var calibrated: Bool
    /// Consecutive sessions the player struggled (slow / many wrong). Drives the
    /// "too hard? start easier" offer only after real, sustained struggle.
    public var struggleStreak: Int?
    /// Ear-side progress, keyed by the SAME SkillUnit ids as `unitStates`.
    /// The piano side proves you can BUILD a chord; the ear side proves you can
    /// HEAR it. One curriculum, two senses — To-Go work moves this map.
    public var earStates: [String: UnitProgress]?
    /// Last plan built, for resume / display.
    public var lastPlan: CoachPlan?

    public init(version: Int, unitStates: [String: UnitProgress], frontierIndex: Int,
                dayIndex: Int, difficultyBias: Double, calibrated: Bool,
                struggleStreak: Int? = nil, earStates: [String: UnitProgress]? = nil,
                lastPlan: CoachPlan? = nil) {
        self.version = version
        self.unitStates = unitStates
        self.frontierIndex = frontierIndex
        self.dayIndex = dayIndex
        self.difficultyBias = difficultyBias
        self.calibrated = calibrated
        self.struggleStreak = struggleStreak
        self.earStates = earStates
        self.lastPlan = lastPlan
    }
}

/// What the post-session screen should offer, derived from how the session went.
public enum SessionVerdict: String, Sendable, Equatable {
    case excellent, struggling, neutral
}

/// Exactly the settings axes an existing drill session understands.
public struct PracticePlanSettings: Sendable, Equatable, Codable {
    public var difficulty: Difficulty
    public var notation: NotationStyle
    public var voicing: VoicingType
    public var displayMode: DisplayMode
    public var accidentals: AccidentalPreference
    public var progressionMode: ProgressionMode
    public var totalChords: Int

    public init(difficulty: Difficulty, notation: NotationStyle, voicing: VoicingType,
                displayMode: DisplayMode, accidentals: AccidentalPreference,
                progressionMode: ProgressionMode, totalChords: Int) {
        self.difficulty = difficulty
        self.notation = notation
        self.voicing = voicing
        self.displayMode = displayMode
        self.accidentals = accidentals
        self.progressionMode = progressionMode
        self.totalChords = totalChords
    }
}

public enum BlockKind: String, Sendable, Equatable, Codable {
    case warmup, review, focus, new, apply, calibrate
}

public struct CoachBlock: Sendable, Equatable, Codable {
    public var kind: BlockKind
    public var settings: PracticePlanSettings
    /// Roots to weight heavily (focus / review).
    public var focusRoots: [String]?
    /// Voicing to weight heavily (focus).
    public var focusVoicing: String?
    /// If set, the chord pool is RESTRICTED to exactly these qualities (display
    /// strings, e.g. ["Maj7"]). Used by 'new' and 'focus' blocks so the block
    /// delivers precisely the chord it promises. warmup/review/apply leave this
    /// nil and draw from the broader mastered/due pool.
    public var focusQualities: [String]?
    /// How many chords this block presents.
    public var targetChords: Int
    /// i18n key for the mid-session mini-screen ("Warm-up done — now your focus: …").
    public var labelKey: String
    /// Params for labelKey interpolation (no hard-coded prose).
    public var labelParams: [String: String]?

    public init(kind: BlockKind, settings: PracticePlanSettings, focusRoots: [String]? = nil,
                focusVoicing: String? = nil, focusQualities: [String]? = nil, targetChords: Int,
                labelKey: String, labelParams: [String: String]? = nil) {
        self.kind = kind
        self.settings = settings
        self.focusRoots = focusRoots
        self.focusVoicing = focusVoicing
        self.focusQualities = focusQualities
        self.targetChords = targetChords
        self.labelKey = labelKey
        self.labelParams = labelParams
    }
}

public struct CoachPlan: Sendable, Equatable, Codable {
    public var blocks: [CoachBlock]
    /// i18n key for the one-line coach announcement.
    public var sayKey: String
    /// Params for sayKey (root/voicing/minutes/quality as strings).
    public var sayParams: [String: String]
    public var estMinutes: Int
    /// Snapshot of the frontier at plan time — lets the feedback screen compare before/after.
    public var frontierUnitId: String?

    public init(blocks: [CoachBlock], sayKey: String, sayParams: [String: String],
                estMinutes: Int, frontierUnitId: String? = nil) {
        self.blocks = blocks
        self.sayKey = sayKey
        self.sayParams = sayParams
        self.estMinutes = estMinutes
        self.frontierUnitId = frontierUnitId
    }
}

/// One structured statement for the post-session teacher screen.
public struct TeacherStatement: Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable {
        case promoted, held, demoted, improved, placed, nextGoal, calibrated
    }
    public let kind: Kind
    public let key: String
    public let params: [String: String]

    public init(kind: Kind, key: String, params: [String: String]) {
        self.kind = kind
        self.key = key
        self.params = params
    }
}

// ─── i18n key catalogue (consumed by the UX task) ───────────

public enum CoachLabelKeys {
    public static let warmup = "coach.block.warmup"
    public static let review = "coach.block.review"
    public static let focus = "coach.block.focus"
    public static let new = "coach.block.new"
    public static let apply = "coach.block.apply"
    public static let calibrate = "coach.block.calibrate"

    static func forKind(_ kind: BlockKind) -> String {
        switch kind {
        case .warmup: return warmup
        case .review: return review
        case .focus: return focus
        case .new: return new
        case .apply: return apply
        case .calibrate: return calibrate
        }
    }
}

public enum CoachSayKeys {
    public static let calibrate = "coach.say.calibrate"
    public static let short = "coach.say.short"
    public static let full = "coach.say.full"
    public static let reviewOnly = "coach.say.reviewOnly"
}

public enum CoachFeedbackKeys {
    public static let promoted = "coach.fb.promoted"
    public static let held = "coach.fb.held"
    public static let demoted = "coach.fb.demoted"
    public static let improved = "coach.fb.improved"
    public static let placed = "coach.fb.placed"
    public static let nextGoal = "coach.fb.nextGoal"
    public static let calibrated = "coach.fb.calibrated"
}

// ─── Key tiers ──────────────────────────────────────────────
// Derived to mirror ultimate-plan's EASY_KEYS → (…) → ALL_KEYS ladder.
// `med` is an 8-key middle rung so the three tiers form a real progression
// (ultimate-plan collapses med into all; the Coach keeps them distinct).

private let ALL_KEYS = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
private let EASY_KEYS = ["C", "F", "Bb", "Eb"]
private let MED_KEYS = ["C", "F", "Bb", "Eb", "G", "D", "A", "Ab"]

private func keysForTier(_ tier: KeyTier) -> [String] {
    switch tier {
    case .easy: return EASY_KEYS
    case .med: return MED_KEYS
    case .all: return ALL_KEYS
    }
}

private let KEY_TIERS: [KeyTier] = [.easy, .med, .all]

// ─── Difficulty mapping ─────────────────────────────────────

private let DIFF_ORDER: [Difficulty] = [.beginner, .intermediate, .advanced]

/// Lowest difficulty tier whose chord pool contains this quality display.
private func difficultyForQuality(_ quality: String) -> Difficulty {
    for d in DIFF_ORDER {
        if (CHORDS_BY_DIFFICULTY[d] ?? []).contains(where: { $0.display == quality }) { return d }
    }
    // Qualities not in any pool (shouldn't happen) default to advanced.
    return .advanced
}

// ─── 1. Skill-Map ───────────────────────────────────────────

/// Build the skill ladder deterministically from the ultimate-plan curriculum.
///
/// Order = curriculum order (module → lesson). Each lesson contributes ONE
/// (voicing × quality) pair, expanded into three key-tier rungs (easy → med → all).
/// Duplicate (voicing × quality) pairs are de-duplicated, first occurrence wins,
/// so the ladder is stable regardless of how often a pair appears.
///
/// No randomness, no time — same output every call.
public func buildSkillLadder() -> [SkillUnit] {
    var units: [SkillUnit] = []
    var seen = Set<String>() // "voicing|quality"

    for mod in ultimatePlanCourse.modules {
        for lesson in mod.lessons {
            // The theory step carries the canonical exampleChord (root/quality/voicing).
            let ex: ChordSpec? = lesson.steps.compactMap { step -> ChordSpec? in
                if case let .theory(t) = step { return t.exampleChord }
                return nil
            }.first
            guard let ex else { continue }
            let pairKey = "\(ex.voicing.rawValue)|\(ex.quality)"
            if seen.contains(pairKey) { continue }
            seen.insert(pairKey)

            let difficulty = difficultyForQuality(ex.quality)
            for tier in KEY_TIERS {
                let id = "\(ex.voicing.rawValue)|\(ex.quality)|\(tier.rawValue)"
                units.append(SkillUnit(
                    id: id,
                    voicing: ex.voicing,
                    quality: ex.quality,
                    keyTier: tier,
                    keys: keysForTier(tier),
                    difficulty: difficulty,
                    index: units.count,
                    moduleTitleKey: mod.titleKey
                ))
            }
        }
    }

    return units
}

/// The distinct qualities in curriculum (easy→hard) order — the ascending test
/// sequence the calibration drill presents. Derived from the ladder so it stays
/// in lockstep with the curriculum.
public let CALIBRATION_QUALITIES: [String] = {
    var seen = Set<String>()
    var out: [String] = []
    for u in buildSkillLadder() {
        if !seen.contains(u.quality) {
            seen.insert(u.quality)
            out.append(u.quality)
        }
    }
    return out
}()

// ─── State helpers ──────────────────────────────────────────

public func createInitialCoachState() -> CoachState {
    CoachState(
        version: 1,
        unitStates: [:],
        frontierIndex: 0,
        dayIndex: 0,
        difficultyBias: 0,
        calibrated: false
    )
}

private func unitProgress(_ state: CoachState, _ id: String) -> UnitProgress {
    state.unitStates[id] ?? UnitProgress(state: .locked, holds: 0)
}

private func isMastered(_ state: CoachState, _ id: String) -> Bool {
    state.unitStates[id]?.state == .mastered
}

/// First non-mastered rung. Clamped to the ladder's last index.
private func computeFrontierIndex(_ ladder: [SkillUnit], _ state: CoachState) -> Int {
    for i in 0..<ladder.count {
        if !isMastered(state, ladder[i].id) { return i }
    }
    return max(0, ladder.count - 1)
}

// ─── Difficulty-bias application ────────────────────────────

/// Nudge a base difficulty up/down by the accumulated bias.
private func applyBias(_ base: Difficulty, _ bias: Double) -> Difficulty {
    let idx = DIFF_ORDER.firstIndex(of: base) ?? 0
    var shifted = idx
    if bias >= 0.34 { shifted = idx + 1 }
    else if bias <= -0.34 { shifted = idx - 1 }
    shifted = max(0, min(DIFF_ORDER.count - 1, shifted))
    return DIFF_ORDER[shifted]
}

// ─── 3. Session-Composer ────────────────────────────────────

private let DEFAULT_NOTATION: NotationStyle = .standard
// Flats, not `.both`: the Coach's key tiers are all spelled with flats
// (Db, Eb, Ab, Bb), and jazz lead-sheets favour flats for these roots — so a
// focus block on B♭m6 must not surface as "A#m6". Aligns generated roots with
// the ladder's own spelling.
private let DEFAULT_ACCIDENTALS: AccidentalPreference = .flats

private func chordsForMinutes(_ minutes: Double, _ params: CoachParams) -> Int {
    let raw = Int((minutes * params.chordsPerMinute).rounded())
    return min(params.maxBlockChords, max(params.minBlockChords, raw))
}

/// Roots that are due for SRS review right now, mapped from the chord schedule.
private func dueReviewRoots(_ schedule: [ChordReview], _ now: Double) -> [String] {
    var roots: [String] = []
    for r in schedule {
        if coachParseISO(r.nextReview) <= now { roots.append(r.root) }
    }
    // Dedupe preserving order (matches JS [...new Set(roots)]).
    var seen = Set<String>()
    var out: [String] = []
    for r in roots where !seen.contains(r) { seen.insert(r); out.append(r) }
    return out
}

/// Qualities the player has actually mastered, for a given voicing. The review
/// block draws only from these. Falls back to the frontier's quality when nothing
/// is mastered yet (very first sessions).
private func masteredQualities(
    _ ladder: [SkillUnit],
    _ state: CoachState,
    _ voicing: VoicingType,
    _ fallback: String,
    _ cap: Int
) -> [String] {
    // Most-recently-trained first; never-timed units sort last.
    var seen: [String: Double] = [:]
    for u in ladder where u.voicing == voicing && isMastered(state, u.id) {
        let at = state.unitStates[u.id]?.lastTrainedAt ?? 0
        seen[u.quality] = Swift.max(seen[u.quality] ?? 0, at)
    }
    if seen.isEmpty { return [fallback] }
    return seen.sorted { $0.value > $1.value }
        .prefix(Swift.max(1, cap))
        .map { $0.key }
}

/// Parse an ISO date string to ms-since-epoch (mirrors `new Date(x).getTime()`).
private func coachParseISO(_ s: String) -> Double {
    let full = ISO8601DateFormatter()
    full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = full.date(from: s) { return d.timeIntervalSince1970 * 1000 }
    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]
    if let d = plain.date(from: s) { return d.timeIntervalSince1970 * 1000 }
    let dayFmt = DateFormatter()
    dayFmt.calendar = Calendar(identifier: .gregorian)
    dayFmt.locale = Locale(identifier: "en_US_POSIX")
    dayFmt.timeZone = TimeZone(identifier: "UTC")
    dayFmt.dateFormat = "yyyy-MM-dd"
    if let d = dayFmt.date(from: s) { return d.timeIntervalSince1970 * 1000 }
    return 0
}

private func warmupSettings(_ voicing: VoicingType, _ bias: Double) -> PracticePlanSettings {
    PracticePlanSettings(
        difficulty: applyBias(.beginner, bias),
        notation: DEFAULT_NOTATION,
        voicing: voicing,
        displayMode: .off,
        accidentals: DEFAULT_ACCIDENTALS,
        progressionMode: .random,
        totalChords: 0
    )
}

private func newSettings(_ unit: SkillUnit, _ bias: Double, _ guided: Bool) -> PracticePlanSettings {
    PracticePlanSettings(
        difficulty: applyBias(unit.difficulty, bias),
        notation: DEFAULT_NOTATION,
        voicing: unit.voicing,
        // Hold escalates guided support: 'always' shows the answer, 'verify' checks it.
        displayMode: guided ? .always : .verify,
        accidentals: DEFAULT_ACCIDENTALS,
        progressionMode: .random,
        totalChords: 0
    )
}

private func focusSettings(_ weak: WeakSpot?, _ frontier: SkillUnit, _ bias: Double) -> PracticePlanSettings {
    PracticePlanSettings(
        difficulty: applyBias(frontier.difficulty, bias),
        notation: DEFAULT_NOTATION,
        voicing: weak?.voicing ?? frontier.voicing,
        displayMode: .verify,
        accidentals: DEFAULT_ACCIDENTALS,
        progressionMode: .random,
        totalChords: 0
    )
}

private func reviewSettings(_ frontier: SkillUnit, _ bias: Double) -> PracticePlanSettings {
    PracticePlanSettings(
        difficulty: applyBias(.intermediate, bias),
        notation: DEFAULT_NOTATION,
        voicing: frontier.voicing,
        displayMode: .verify,
        accidentals: DEFAULT_ACCIDENTALS,
        progressionMode: .random,
        totalChords: 0
    )
}

private func applySettings(_ masteredVoicing: VoicingType, _ bias: Double, _ progMode: ProgressionMode) -> PracticePlanSettings {
    PracticePlanSettings(
        difficulty: applyBias(.intermediate, bias),
        notation: DEFAULT_NOTATION,
        voicing: masteredVoicing,
        displayMode: .always,
        accidentals: DEFAULT_ACCIDENTALS,
        progressionMode: progMode,
        totalChords: 0
    )
}

// Deterministic rotation of the "apply" progression by dayIndex.
private let APPLY_PROGRESSIONS: [ProgressionMode] = [.twoFiveOne, .oneSixTwoFive, .cycleOf4ths, .threeSixTwoFive]

/// Build today's Coach plan.
///
/// Rules (design-doc §2.3):
///  - Uncalibrated user → single calibrate block.
///  - Short session (< shortSessionCutoffMin) → review + focus + new only.
///  - Full session → warmup + review + focus + new + apply.
/// Block rotation & progression choice are deterministic from state.dayIndex.
public func buildCoachPlan(
    _ history: [SessionResult],
    _ profile: HabitProfile,
    _ courseProgress: CourseProgress?,
    _ state: CoachState,
    _ params: CoachParams = DEFAULT_COACH_PARAMS,
    now: Double = 0
) -> CoachPlan {
    let ladder = buildSkillLadder()
    let frontierIndex = computeFrontierIndex(ladder, state)
    let frontier = ladder[frontierIndex]
    let bias = state.difficultyBias
    let minutes = profile.dailyGoalMinutes

    // ── Uncalibrated → calibration drill ──────────────────
    if !state.calibrated {
        let firstUnit = ladder[0]
        // The calibration drill climbs difficulty: it presents the ascending
        // CALIBRATION_QUALITIES so placeByCalibration can read how far up the
        // player is solid and place them there — a pro is placed high, a beginner
        // stays low. `advanced` is the widest pool so 'random' can hit them all.
        let calSettings = PracticePlanSettings(
            difficulty: .advanced,
            notation: DEFAULT_NOTATION,
            voicing: firstUnit.voicing,
            displayMode: .verify,
            accidentals: DEFAULT_ACCIDENTALS,
            progressionMode: .random,
            totalChords: params.calibrationChords
        )
        let block = CoachBlock(
            kind: .calibrate,
            settings: calSettings,
            focusQualities: CALIBRATION_QUALITIES,
            targetChords: params.calibrationChords,
            labelKey: CoachLabelKeys.calibrate
        )
        return CoachPlan(
            blocks: [block],
            sayKey: CoachSayKeys.calibrate,
            sayParams: ["chords": String(params.calibrationChords)],
            estMinutes: 3,
            frontierUnitId: frontier.id
        )
    }

    let isShort = minutes < params.shortSessionCutoffMin

    // Frontier is guided when it has accrued holds (design §2.2 rule 2).
    let frontierHolds = unitProgress(state, frontier.id).holds
    let guided = frontierHolds > 0

    // Weak spot for the focus block.
    let weak = analyzeWeakSpots(history, 1).first
    let reviewRoots = dueReviewRoots(profile.chordSchedule, now)

    // Choose which normal blocks are present.
    let mix = params.blockMix
    struct Part { let kind: BlockKind; let weight: Double }
    let parts: [Part] = isShort
        ? [
            Part(kind: .review, weight: mix.review),
            Part(kind: .focus, weight: mix.focus),
            Part(kind: .new, weight: mix.new),
          ]
        : [
            Part(kind: .warmup, weight: mix.warmup),
            Part(kind: .review, weight: mix.review),
            Part(kind: .focus, weight: mix.focus),
            Part(kind: .new, weight: mix.new),
            Part(kind: .apply, weight: mix.apply),
          ]

    // Drop review if nothing is due.
    let activeParts = reviewRoots.isEmpty ? parts.filter { $0.kind != .review } : parts

    let totalWeightRaw = activeParts.reduce(0.0) { $0 + $1.weight }
    let totalWeight = totalWeightRaw == 0 ? 1 : totalWeightRaw

    // Nearest already-mastered voicing (for warmup & apply). Falls back to frontier.
    let masteredVoicing = nearestMasteredVoicing(ladder, state, frontier)
    let applyProg = APPLY_PROGRESSIONS[state.dayIndex % APPLY_PROGRESSIONS.count]

    var blocks: [CoachBlock] = []
    for part in activeParts {
        let blockMinutes = (part.weight / totalWeight) * Double(minutes)
        let targetChords = chordsForMinutes(blockMinutes, params)

        var settings: PracticePlanSettings
        var focusRoots: [String]? = nil
        var focusVoicing: String? = nil
        var focusQualities: [String]? = nil
        var labelParams: [String: String]? = nil

        switch part.kind {
        case .warmup:
            settings = warmupSettings(masteredVoicing, bias)
            labelParams = ["voicing": masteredVoicing.rawValue]
        case .review:
            // Review only ever drills qualities the player has already mastered
            // (in the frontier's voicing) — never the whole difficulty pool.
            settings = reviewSettings(frontier, bias)
            focusRoots = reviewRoots
            focusQualities = masteredQualities(
                ladder, state, frontier.voicing, frontier.quality, params.reviewQualityCap)
            labelParams = ["count": String(reviewRoots.count)]
        case .focus:
            // Focus drills the frontier's quality in the player's weak keys —
            // "practise the thing you're learning, in the keys that trip you up".
            settings = focusSettings(weak, frontier, bias)
            focusRoots = weak != nil ? [weak!.root] : nil
            focusVoicing = weak?.voicing.rawValue ?? frontier.voicing.rawValue
            focusQualities = [frontier.quality]
            labelParams = ["root": weak?.root ?? frontier.keys[0], "voicing": focusVoicing!]
        case .new:
            // The 'new' block must deliver EXACTLY the promised quality.
            settings = newSettings(frontier, bias, guided)
            focusVoicing = frontier.voicing.rawValue
            focusQualities = [frontier.quality]
            labelParams = ["quality": frontier.quality, "voicing": frontier.voicing.rawValue]
        case .apply:
            settings = applySettings(masteredVoicing, bias, applyProg)
            labelParams = ["voicing": masteredVoicing.rawValue]
        case .calibrate:
            settings = newSettings(frontier, bias, guided)
        }

        settings.totalChords = targetChords
        blocks.append(CoachBlock(
            kind: part.kind,
            settings: settings,
            focusRoots: focusRoots,
            focusVoicing: focusVoicing,
            focusQualities: focusQualities,
            targetChords: targetChords,
            labelKey: CoachLabelKeys.forKind(part.kind),
            labelParams: labelParams
        ))
    }

    let sayKey: String
    if isShort {
        sayKey = (!reviewRoots.isEmpty && blocks.allSatisfy { $0.kind == .review })
            ? CoachSayKeys.reviewOnly
            : CoachSayKeys.short
    } else {
        sayKey = CoachSayKeys.full
    }

    return CoachPlan(
        blocks: blocks,
        sayKey: sayKey,
        sayParams: [
            "voicing": frontier.voicing.rawValue,
            "quality": frontier.quality,
            "minutes": String(minutes),
            "focusRoot": weak?.root ?? "",
        ],
        estMinutes: minutes,
        frontierUnitId: frontier.id
    )
}

/// Voicing of the highest mastered unit at or below the frontier; else frontier's.
private func nearestMasteredVoicing(_ ladder: [SkillUnit], _ state: CoachState, _ frontier: SkillUnit) -> VoicingType {
    if frontier.index - 1 >= 0 {
        var i = frontier.index - 1
        while i >= 0 {
            if isMastered(state, ladder[i].id) { return ladder[i].voicing }
            i -= 1
        }
    }
    return frontier.voicing
}

// ─── Session analysis (shared by controller & feedback) ─────

private struct UnitSessionStats {
    let attempts: Int
    let underThreshold: Int
    let avgMs: Double
    /// true if any timing had explicit correctness info.
    let hasCorrectness: Bool
    /// attempts that count as "good" (fast enough AND, if known, correct).
    let good: Int
}

/// Enharmonic spellings of the same pitch, so a key set written one way still
/// matches a timing written the other.
///
/// The ladder spells the tritone `F#`, but the coach forces flats when it
/// generates chords, so the player is actually shown `Gb`. Exact string matching
/// dropped every one of those attempts: one key in twelve could never be scored,
/// no matter how well it was played.
private let ENHARMONIC: [String: String] = [
    "F#": "Gb", "Gb": "F#",
    "C#": "Db", "Db": "C#",
    "D#": "Eb", "Eb": "D#",
    "G#": "Ab", "Ab": "G#",
    "A#": "Bb", "Bb": "A#",
]

/// Does `root` name a key in `keySet`, under either spelling?
private func keyMatches(_ keySet: Set<String>, _ root: String) -> Bool {
    if keySet.contains(root) { return true }
    guard let alt = ENHARMONIC[root] else { return false }
    return keySet.contains(alt)
}

/// Every quality the curriculum ladder actually teaches. Used to tell "this
/// chord belongs to a different unit" apart from "this chord name is not one we
/// can read" — only the former may be filtered out of a unit's evidence.
private let CURRICULUM_QUALITIES: Set<String> = Set(CALIBRATION_QUALITIES)

/// Score a session's timings against the mastery threshold for a given unit.
/// When `correct` is present it gates a "good" attempt; when nil only
/// timing matters (back-compat with older sessions).
private func scoreSessionForUnit(
    _ timings: [ChordTiming],
    _ unit: SkillUnit,
    _ params: CoachParams
) -> UnitSessionStats {
    // Count a timing only if BOTH its key and its quality belong to this unit.
    //
    // Filtering by root alone credited a unit for chords of a different quality:
    // a flawless session of Maj7 counted as evidence for the 7 and m7 units in
    // the same keys, so the climb mastered qualities the player never touched.
    //
    // A quality the curriculum does not know still counts on key alone — older
    // sessions stored chord names this parser cannot resolve, and dropping them
    // would silently discard that practice history.
    let keySet = Set(unit.keys)
    let relevant = timings.filter { t in
        guard keyMatches(keySet, t.root) else { return false }
        let q = qualityOfChord(t.chord)
        guard CURRICULUM_QUALITIES.contains(q) else { return true }
        return q == unit.quality
    }
    let window = Array(relevant.suffix(params.masteryWindow))

    var underThreshold = 0
    var good = 0
    var sum = 0.0
    var hasCorrectness = false
    for t in window {
        sum += t.durationMs
        let fast = t.durationMs <= params.masteryThresholdMs
        if fast { underThreshold += 1 }
        if t.correct != nil { hasCorrectness = true }
        // A "good" attempt is fast AND (correct or correctness unknown).
        if fast && t.correct != false { good += 1 }
    }

    return UnitSessionStats(
        attempts: window.count,
        underThreshold: underThreshold,
        avgMs: window.isEmpty ? 0 : sum / Double(window.count),
        hasCorrectness: hasCorrectness,
        good: good
    )
}

// ─── 2. Controller ──────────────────────────────────────────

/// Apply a completed session to the Coach state.
///
/// Order of operations:
///  1. difficultyBias already updated via applyFeedback() before this — untouched here.
///  2. Calibration → placement (mark fast units mastered, set frontier).
///  3. Frontier promotion / hold / demotion from this session's scoring.
///  4. SRS lapse → decay mapped units toward practicing.
///  5. Recompute frontier, bump dayIndex.
public func applySessionToCoach(
    _ state: CoachState,
    _ plan: CoachPlan,
    _ session: SessionResult,
    _ params: CoachParams = DEFAULT_COACH_PARAMS,
    now: Double = 0
) -> CoachState {
    let ladder = buildSkillLadder()
    var next = state
    next.unitStates = state.unitStates
    let timings = session.chordTimings ?? []

    // ── Calibration placement ─────────────────────────────
    if !next.calibrated {
        placeByCalibration(ladder, &next, timings, params)
        next.calibrated = true
        next.frontierIndex = computeFrontierIndex(ladder, next)
        next.dayIndex = state.dayIndex + 1
        return next
    }

    // ── Frontier promotion / hold / demotion ──────────────
    // Target the unit the plan was built around (plan.frontierUnitId), NOT the
    // live-recomputed frontier. The plan is built once per session and reused for
    // every block, so a normal pass advances one tier per session.
    // Fall back to the live frontier for older plans without a frontierUnitId.
    let planFrontier: SkillUnit =
        (plan.frontierUnitId.flatMap { id in ladder.first { $0.id == id } })
        ?? ladder[computeFrontierIndex(ladder, next)]
    // A block only trains the frontier when it drills the frontier's voicing.
    // Warmup/apply (mastered voicing) and focus (weak-spot voicing) blocks must
    // never promote the frontier just because their roots happen to overlap.
    let trainsFrontier = session.settings.voicing == planFrontier.voicing

    if trainsFrontier {
        // Climb the ladder from the plan's frontier while this session's timings
        // keep clearing the next unit. A normal pass promotes at most the plan
        // frontier (one tier); an EXCELLENT pass (fast + clean) keeps climbing
        // same-voicing units it also covers — so a player who's clearly on top of
        // a quality clears easy→med→all in one session instead of one tier each.
        var unit: SkillUnit? = planFrontier
        var firstStep = true
        while let u = unit, u.voicing == planFrontier.voicing, !isMastered(next, u.id) {
            let stats = scoreSessionForUnit(timings, u, params)
            if stats.attempts == 0 { break }
            let ratio = Double(stats.good) / Double(stats.attempts)
            var prog = unitProgress(next, u.id)
            prog.lastTrainedAt = now
            prog.bestAvgMs = prog.bestAvgMs == nil ? stats.avgMs : min(prog.bestAvgMs!, stats.avgMs)

            if ratio >= params.promotionRatio {
                prog.state = .mastered
                prog.holds = 0
                next.unitStates[u.id] = prog
                // Only keep climbing past the plan frontier when the pass was
                // excellent — otherwise stop after the one planned promotion.
                let excellent =
                    stats.avgMs > 0 && stats.avgMs <= params.masteryThresholdMs * params.excellentFactor
                if !excellent { break }
                let nextIdx = u.index + 1
                unit = nextIdx < ladder.count ? ladder[nextIdx] : nil
            } else {
                // Hold — count it; escalate to (single-step) demotion after N holds.
                // Holds only apply to the actual frontier (the first step).
                if firstStep {
                    prog.state = prog.state == .locked ? .learning : prog.state
                    prog.holds = prog.holds + 1
                    next.unitStates[u.id] = prog
                    if prog.holds >= params.demotionAfterHolds {
                        demoteOneStep(ladder, &next, u.index, params)
                    }
                }
                break
            }
            firstStep = false
        }
    }

    // ── SRS lapse → decay ─────────────────────────────────
    if params.srsLapseDemotes {
        decayLapsedUnits(ladder, &next, session, params, now)
    }

    next.frontierIndex = computeFrontierIndex(ladder, next)
    next.dayIndex = state.dayIndex + 1
    return next
}

/// Placement after calibration: any early unit the player cleared fast is marked
/// mastered ("mastered by placement"), so advanced players skip the beginner grind.
/// We only place along the easiest key tier and only contiguous from the bottom.
private func placeByCalibration(
    _ ladder: [SkillUnit],
    _ state: inout CoachState,
    _ timings: [ChordTiming],
    _ params: CoachParams
) {
    if timings.isEmpty { return }

    // Group the calibration timings by chord quality. The chord name is
    // "<root><notated>", so strip the leading root to recover the quality.
    var byQuality: [String: [ChordTiming]] = [:]
    for t in timings {
        let q = qualityOfChord(t.chord)
        if q.isEmpty { continue }
        byQuality[q, default: []].append(t)
    }

    // Calibration only tests the first curriculum voicing (root) — place only that
    // voicing's units, never voicings the player never touched.
    let calVoicing = ladder.first?.voicing

    // Walk the qualities easy→hard. A quality is "solid" when the player was fast
    // and (where known) correct on it. Place every unit of each solid quality as
    // mastered — CONTIGUOUS: the first non-solid quality stops the walk, so we
    // never place a hard quality the player skipped past by luck. A pro who's
    // solid up to 13 gets placed there; a beginner stops after Maj7 (or nothing).
    for quality in CALIBRATION_QUALITIES {
        guard let qt = byQuality[quality], !qt.isEmpty else { break }
        let avg = qt.reduce(0.0) { $0 + $1.durationMs } / Double(qt.count)
        let fast = avg <= params.masteryThresholdMs
        let clean = qt.allSatisfy { $0.correct != false }
        if !fast || !clean { break } // first shaky quality → placement stops here.

        for unit in ladder where unit.quality == quality && unit.voicing == calVoicing {
            state.unitStates[unit.id] = UnitProgress(state: .mastered, bestAvgMs: avg, holds: 0)
        }
    }
}

// Map every notated quality form (across all notation styles) back to its
// canonical `display` key, so placement works whatever notation the drill used.
private let NOTATED_TO_DISPLAY: [String: String] = {
    var m: [String: String] = [:]
    for style in NotationStyle.allCases {
        for (display, notated) in (CHORD_NOTATIONS[style] ?? [:]) {
            m[notated] = display
        }
    }
    return m
}()

/// Recover a chord's canonical quality display from "<root><notated>", e.g. "EbΔ7" → "Maj7".
private func qualityOfChord(_ chord: String) -> String {
    // Root = a letter, optionally followed by one accidental (# / b / ♯ / ♭).
    var rest = Substring(chord)
    guard let first = rest.first, first >= "A", first <= "G" else { return "" }
    rest = rest.dropFirst()
    if let acc = rest.first, acc == "#" || acc == "b" || acc == "♯" || acc == "♭" {
        rest = rest.dropFirst()
    }
    let notated = String(rest)
    return NOTATED_TO_DISPLAY[notated] ?? notated
}

/// Demote: frontier back to 'practicing', drop one key tier if possible. Never more than one step.
private func demoteOneStep(
    _ ladder: [SkillUnit],
    _ state: inout CoachState,
    _ frontierIndex: Int,
    _ params: CoachParams
) {
    let frontier = ladder[frontierIndex]
    var prog = unitProgress(state, frontier.id)
    prog.state = .practicing
    prog.holds = 0 // reset after acting, so we don't demote repeatedly.
    state.unitStates[frontier.id] = prog

    // If a lower key-tier rung of the same voicing×quality exists and is mastered,
    // knock it back to practicing (one step down the ladder) — but only one.
    let base = String(frontier.id[..<frontier.id.lastIndex(of: "|")!])
    let lowerTier: KeyTier? = frontier.keyTier == .all ? .med : (frontier.keyTier == .med ? .easy : nil)
    if let lowerTier {
        let lowerId = "\(base)|\(lowerTier.rawValue)"
        if state.unitStates[lowerId]?.state == .mastered {
            var lower = state.unitStates[lowerId]!
            lower.state = .practicing
            lower.holds = 0
            state.unitStates[lowerId] = lower
        }
    }
}

/// Map overdue SRS entries to their units and decay mastered ones back to practicing.
private func decayLapsedUnits(
    _ ladder: [SkillUnit],
    _ state: inout CoachState,
    _ session: SessionResult,
    _ params: CoachParams,
    _ now: Double
) {
    let voicing = session.settings.voicing
    // A lapse this session = a chord that was answered incorrectly (if known).
    let lapsedRoots = Set((session.chordTimings ?? []).filter { $0.correct == false }.map { $0.root })
    if lapsedRoots.isEmpty { return }

    for unit in ladder {
        if unit.voicing != voicing { continue }
        if state.unitStates[unit.id]?.state != .mastered { continue }
        // Does this unit cover any lapsed root?
        if unit.keys.contains(where: { lapsedRoots.contains($0) }) {
            var prog = state.unitStates[unit.id]!
            prog.state = .practicing
            prog.lastTrainedAt = now
            state.unitStates[unit.id] = prog
        }
    }
}

// ─── Feedback bias ("too easy / too hard") ──────────────────

public enum FeedbackSignal: String, Sendable, Equatable {
    case tooEasy, justRight, tooHard
}

/// Apply a single feedback tap, returning a new state with clamped bias.
public func applyFeedback(
    _ state: CoachState,
    _ signal: FeedbackSignal,
    _ params: CoachParams = DEFAULT_COACH_PARAMS
) -> CoachState {
    var bias = state.difficultyBias
    if signal == .tooEasy { bias += params.feedbackBiasStep }
    else if signal == .tooHard { bias -= params.feedbackBiasStep }
    // justRight → no change.
    let c = params.feedbackBiasClamp
    bias = max(-c, min(c, bias))
    var next = state
    next.difficultyBias = bias
    return next
}

/// The post-session verdict — the UI never asks "too easy?" (the system detects
/// excellence itself). It only offers:
///  - .excellent  → "nailed it, keep going" (fast AND clean)
///  - .struggling → "too hard? start easier" — but ONLY after
///    struggleSessionsBeforeOffer sessions in a row of real struggle.
///  - .neutral    → nothing special.
/// `struggleStreak` on the returned state tracks the consecutive-struggle count.
public func assessSession(
    _ state: CoachState,
    _ session: SessionResult,
    _ params: CoachParams = DEFAULT_COACH_PARAMS
) -> (verdict: SessionVerdict, state: CoachState) {
    let timings = session.chordTimings ?? []
    let avg = session.avgMs
    let graded = timings.filter { $0.correct != nil }
    let correctRate = graded.isEmpty
        ? 1.0
        : Double(graded.filter { $0.correct == true }.count) / Double(graded.count)

    let excellent =
        avg > 0 && avg <= params.masteryThresholdMs * params.excellentFactor && correctRate >= 0.9
    let struggled = avg > params.masteryThresholdMs || correctRate < 0.6

    let prevStreak = state.struggleStreak ?? 0
    let streak = struggled ? prevStreak + 1 : 0
    var nextState = state
    nextState.struggleStreak = streak

    var verdict: SessionVerdict = .neutral
    if excellent { verdict = .excellent }
    else if streak >= params.struggleSessionsBeforeOffer { verdict = .struggling }

    return (verdict, nextState)
}

// ─── Ear facet (To-Go) ──────────────────────────────────────
// The ear side runs on the same ladder as the piano side. A unit has two
// facets: can you BUILD it (unitStates) and can you HEAR it (earStates).

/// Has the player mastered hearing this unit?
public func isEarMastered(_ state: CoachState, _ unitId: String) -> Bool {
    state.earStates?[unitId]?.state == .mastered
}

/// The quality the ear side should drill right now: whatever the piano side is
/// currently teaching. This is what makes To-Go feel like the same teacher —
/// you hear the chord you're learning to play.
public func earFocus(_ state: CoachState) -> (quality: String, unitId: String, voicing: VoicingType)? {
    let ladder = buildSkillLadder()
    let idx = computeFrontierIndex(ladder, state)
    guard idx >= 0 && idx < ladder.count else { return nil }
    let frontier = ladder[idx]
    return (frontier.quality, frontier.id, frontier.voicing)
}

/// One unit's tally from a To-Go run: how many times it was heard right.
public struct EarTally: Sendable, Equatable {
    public var unitId: String
    public var attempts: Int
    public var correct: Int

    public init(unitId: String, attempts: Int, correct: Int) {
        self.unitId = unitId
        self.attempts = attempts
        self.correct = correct
    }
}

/// Fold To-Go results into ear progress.
///
/// A unit becomes ear-mastered when the player hears it correctly at least
/// `promotionRatio` of the time over enough attempts — the same bar the piano
/// side uses, so the two facets mean the same thing. Missing it knocks a
/// mastered ear unit back to practicing (you clearly can't hear it yet).
public func applyEarTallies(
    _ state: CoachState,
    _ tallies: [EarTally],
    _ params: CoachParams = DEFAULT_COACH_PARAMS,
    now: Double = 0,
    minAttempts: Int = 3
) -> CoachState {
    if tallies.isEmpty { return state }
    var earStates = state.earStates ?? [:]

    for t in tallies {
        if t.attempts <= 0 { continue }
        let prev = earStates[t.unitId] ?? UnitProgress(state: .locked, holds: 0)
        var prog = prev
        prog.lastTrainedAt = now
        let ratio = Double(t.correct) / Double(t.attempts)

        if t.attempts >= minAttempts && ratio >= params.promotionRatio {
            prog.state = .mastered
            prog.holds = 0
        } else if prog.state == .mastered && ratio < params.promotionRatio {
            // Heard it wrong after mastering — it slipped.
            prog.state = .practicing
        } else if prog.state == .locked {
            prog.state = .learning
        }
        earStates[t.unitId] = prog
    }

    var next = state
    next.earStates = earStates
    return next
}

/// Roll a To-Go run's per-exercise outcomes into per-unit tallies.
/// Only exercises that carry a `unitId` (i.e. the quality drill mirroring the
/// Coach frontier) count toward the shared skill map.
public func tallyEarResults(_ results: [(unitId: String?, correct: Bool)]) -> [EarTally] {
    var byUnit: [String: EarTally] = [:]
    var order: [String] = []
    for r in results {
        guard let unitId = r.unitId else { continue }
        var t = byUnit[unitId] ?? { order.append(unitId); return EarTally(unitId: unitId, attempts: 0, correct: 0) }()
        t.attempts += 1
        if r.correct { t.correct += 1 }
        byUnit[unitId] = t
    }
    return order.compactMap { byUnit[$0] }
}

public struct SkillMapProgress: Sendable, Equatable {
    public var total: Int
    public var handsMastered: Int
    public var earMastered: Int
    public var bothMastered: Int

    public init(total: Int, handsMastered: Int, earMastered: Int, bothMastered: Int) {
        self.total = total
        self.handsMastered = handsMastered
        self.earMastered = earMastered
        self.bothMastered = bothMastered
    }
}

/// How far along both facets are — for the progress display.
public func skillMapProgress(_ state: CoachState) -> SkillMapProgress {
    let ladder = buildSkillLadder()
    var handsMastered = 0
    var earMastered = 0
    var bothMastered = 0
    for u in ladder {
        let h = isMastered(state, u.id)
        let e = isEarMastered(state, u.id)
        if h { handsMastered += 1 }
        if e { earMastered += 1 }
        if h && e { bothMastered += 1 }
    }
    return SkillMapProgress(total: ladder.count, handsMastered: handsMastered,
                            earMastered: earMastered, bothMastered: bothMastered)
}

// ─── UI helpers ─────────────────────────────────────────────

/// Structured coach announcement for the QuickStart / TodayView.
public func describeCoachPlan(_ plan: CoachPlan) -> (sayKey: String, sayParams: [String: String]) {
    (plan.sayKey, plan.sayParams)
}

/// Compare Coach state before/after a session and emit structured teacher talk.
/// Pure — returns keys + params, never localized strings.
public func teacherFeedback(
    _ before: CoachState,
    _ after: CoachState,
    _ session: SessionResult,
    _ params: CoachParams = DEFAULT_COACH_PARAMS
) -> [TeacherStatement] {
    let ladder = buildSkillLadder()
    var out: [TeacherStatement] = []
    // One statement per unit id — guards against the same unit surfacing twice
    // (e.g. via both the per-unit scan and the held-frontier check).
    var spokenUnitIds = Set<String>()

    // Calibration just finished.
    if !before.calibrated && after.calibrated {
        let placed = after.unitStates.values.filter { $0.state == .mastered }.count
        out.append(TeacherStatement(
            kind: .calibrated,
            key: CoachFeedbackKeys.calibrated,
            params: ["placed": String(placed)]
        ))
    }

    // Per-unit transitions. `tier` is carried so the text can say WHICH key stage
    // changed — without it "Next goal: Maj7 in Root Position" reads as a
    // contradiction right after "You already have Maj7 in Root Position".
    for unit in ladder {
        let b = before.unitStates[unit.id]?.state ?? .locked
        let a = after.unitStates[unit.id]?.state ?? .locked
        if b == a { continue }

        if a == .mastered {
            // Placed vs promoted: placement happens only on the calibration session.
            let isPlacement = !before.calibrated && after.calibrated
            out.append(TeacherStatement(
                kind: isPlacement ? .placed : .promoted,
                key: isPlacement ? CoachFeedbackKeys.placed : CoachFeedbackKeys.promoted,
                params: unitParams(unit)
            ))
            spokenUnitIds.insert(unit.id)
        } else if b == .mastered && a == .practicing {
            out.append(TeacherStatement(
                kind: .demoted,
                key: CoachFeedbackKeys.demoted,
                params: unitParams(unit)
            ))
            spokenUnitIds.insert(unit.id)
        }
    }

    // Held frontier (holds increased but no promotion).
    if let frontierId = before.lastPlan?.frontierUnitId, !spokenUnitIds.contains(frontierId) {
        let bh = before.unitStates[frontierId]?.holds ?? 0
        let ah = after.unitStates[frontierId]?.holds ?? 0
        let unit = ladder.first { $0.id == frontierId }
        if ah > bh, let unit, after.unitStates[frontierId]?.state != .mastered {
            out.append(TeacherStatement(
                kind: .held,
                key: CoachFeedbackKeys.held,
                params: unitParams(unit)
            ))
            spokenUnitIds.insert(unit.id)
        }
    }

    // Improvement signal (avg faster than best-known for the frontier).
    if session.avgMs > 0 && session.avgMs <= params.masteryThresholdMs {
        out.append(TeacherStatement(
            kind: .improved,
            key: CoachFeedbackKeys.improved,
            params: ["avgMs": String(Int(session.avgMs.rounded()))]
        ))
    }

    // Next goal = new frontier after applying.
    let nextFrontier = ladder[computeFrontierIndex(ladder, after)]
    out.append(TeacherStatement(
        kind: .nextGoal,
        key: CoachFeedbackKeys.nextGoal,
        params: unitParams(nextFrontier)
    ))

    return out
}

/// Statement params for a unit: quality + voicing + the key-tier it refers to.
private func unitParams(_ unit: SkillUnit) -> [String: String] {
    ["quality": unit.quality, "voicing": unit.voicing.rawValue, "tier": unit.keyTier.rawValue]
}
