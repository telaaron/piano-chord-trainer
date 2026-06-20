// Habit Engine — XP, Levels, Smart Goals, Spaced Repetition.
// 1:1 port of src/lib/engine/habits.ts. Pure, no side effects.
// i18n: `title`/`description` carry the English fallback; the app resolves the
// `*Key` fields against its localization tables at display time.

import Foundation

// ─── XP Constants ───────────────────────────────────────────

public let XP_SESSION_COMPLETE = 10
public let XP_PERSONAL_BEST = 2
public let XP_STREAK_DAY = 5
public let XP_STREAK_7_BONUS = 50
public let XP_STREAK_14_BONUS = 100
public let XP_STREAK_30_BONUS = 200
public let XP_GOAL_COMPLETED = 25
public let XP_NEW_VOICING = 15
public let XP_LONG_SESSION = 10
public let XP_DEDICATED = 20
public let XP_FULL_CIRCLE = 30
public let XP_HIGH_ACCURACY = 5

/// Short labels for voicing types (music terms, no i18n).
private let VOICING_SHORT_LABELS: [String: String] = [
    "root": "Root Pos.", "shell": "Shell", "half-shell": "Half Shell", "full": "Full",
    "rootless-a": "Rootless A", "rootless-b": "Rootless B",
    "inversion-1": "1st Inv.", "inversion-2": "2nd Inv.", "inversion-3": "3rd Inv.",
]

public enum GoalType: String, Sendable, Codable {
    case speed, consistency, mastery, exploration, endurance, review, accuracy
}

public enum TimeOfDay: String, Sendable, Codable {
    case morning, afternoon, evening
}

public struct SmartGoal: Sendable, Equatable, Codable {
    public var id: String
    public var type: GoalType
    public var title: String
    public var titleKey: String
    public var titleParams: [String: String]?
    public var description: String
    public var descriptionKey: String
    public var descriptionParams: [String: String]?
    public var icon: String
    public var target: Double
    public var current: Double
    public var xpReward: Int
    public var createdAt: String
    public var completedAt: String?
    public var expiresAt: String?
}

public struct ChordReview: Sendable, Equatable, Codable {
    public var chordKey: String
    public var root: String
    public var quality: String
    public var lastReviewed: String
    public var nextReview: String
    public var interval: Int
    public var ease: Double
    public var repetitions: Int
}

public struct HabitProfile: Sendable, Equatable, Codable {
    public var dailyGoalMinutes: Int
    public var preferredTime: TimeOfDay
    public var practiceAnchor: String
    public var totalXP: Int
    public var weeklyXP: Int
    public var weekStart: String
    public var activeGoals: [SmartGoal]
    public var completedGoals: [SmartGoal]
    public var chordSchedule: [ChordReview]
    public var notificationsEnabled: Bool
    public var notificationTime: String
    public var lastNotificationDate: String
    public var onboardingDone: Bool
    public var sessionsToday: Int
    public var lastSessionDate: String
    public var dailyGoalDates: [String]
    public var todayPracticeMs: Double
}

public struct XPEvent: Sendable, Equatable {
    public let amount: Int
    public let reason: String
    public let reasonKey: String
    public let reasonParams: [String: String]?

    public init(amount: Int, reason: String, reasonKey: String, reasonParams: [String: String]? = nil) {
        self.amount = amount
        self.reason = reason
        self.reasonKey = reasonKey
        self.reasonParams = reasonParams
    }
}

public struct LevelInfo: Sendable, Equatable {
    public let level: Int
    public let title: String
    public let titleKey: String
    public let currentXP: Int
    public let xpForCurrentLevel: Int
    public let xpForNextLevel: Int
    public let progressPercent: Int
}

public enum CelebrationType: String, Sendable {
    case levelUp = "level-up"
    case goalComplete = "goal-complete"
    case streakMilestone = "streak-milestone"
    case personalBest = "personal-best"
    case xpGain = "xp-gain"
}

public struct CelebrationEvent: Sendable, Equatable {
    public let type: CelebrationType
    public let title: String
    public let titleKey: String
    public let titleParams: [String: String]?
    public let subtitle: String?
    public let subtitleKey: String?
    public let subtitleParams: [String: String]?
    public let xpGained: Int
    public let timestamp: String

    public init(type: CelebrationType, title: String, titleKey: String, titleParams: [String: String]?,
                subtitle: String?, subtitleKey: String?, subtitleParams: [String: String]?,
                xpGained: Int, timestamp: String) {
        self.type = type; self.title = title; self.titleKey = titleKey; self.titleParams = titleParams
        self.subtitle = subtitle; self.subtitleKey = subtitleKey; self.subtitleParams = subtitleParams
        self.xpGained = xpGained; self.timestamp = timestamp
    }
}

// ─── Date helpers (ISO YYYY-MM-DD, UTC — matches JS toISOString().slice(0,10)) ──

private let utcCalendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}()

private let isoDayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.calendar = utcCalendar
    f.timeZone = TimeZone(identifier: "UTC")!
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

private func dayString(_ date: Date) -> String { isoDayFormatter.string(from: date) }

/// Full ISO 8601 with milliseconds + Z, matching JS Date.toISOString().
nonisolated(unsafe) private let isoFullFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    f.timeZone = TimeZone(identifier: "UTC")!
    return f
}()

private func isoNow(_ date: Date = Date()) -> String { isoFullFormatter.string(from: date) }

private func parseISO(_ s: String) -> Date {
    isoFullFormatter.date(from: s) ?? isoDayFormatter.date(from: s) ?? Date(timeIntervalSince1970: 0)
}

private func dayString(fromMillis ms: Double) -> String {
    dayString(Date(timeIntervalSince1970: ms / 1000))
}

// ─── Level System ───────────────────────────────────────────

private struct LevelTitle { let maxLevel: Int; let key: String; let en: String; let de: String }
private let LEVEL_TITLES: [LevelTitle] = [
    LevelTitle(maxLevel: 4, key: "habit.level_listener", en: "Listener", de: "Zuhörer"),
    LevelTitle(maxLevel: 9, key: "habit.level_beginner", en: "Beginner", de: "Einsteiger"),
    LevelTitle(maxLevel: 14, key: "habit.level_student", en: "Student", de: "Schüler"),
    LevelTitle(maxLevel: 19, key: "habit.level_sideman", en: "Sideman", de: "Sideman"),
    LevelTitle(maxLevel: 24, key: "habit.level_gigging", en: "Gigging Musician", de: "Club-Musiker"),
    LevelTitle(maxLevel: 29, key: "habit.level_session", en: "Session Player", de: "Session-Musiker"),
    LevelTitle(maxLevel: 34, key: "habit.level_bandleader", en: "Bandleader", de: "Bandleader"),
    LevelTitle(maxLevel: 39, key: "habit.level_jazzcat", en: "Jazz Cat", de: "Jazz Cat"),
    LevelTitle(maxLevel: 44, key: "habit.level_virtuoso", en: "Virtuoso", de: "Virtuose"),
    LevelTitle(maxLevel: 49, key: "habit.level_legend", en: "Legend", de: "Legende"),
    LevelTitle(maxLevel: Int.max, key: "habit.level_monk", en: "Monk Status", de: "Monk Status"),
]

/// level = floor(sqrt(totalXP / 50)), min 1.
public func calculateLevel(_ totalXP: Int) -> Int {
    max(1, Int((Double(totalXP) / 50).squareRoot()))
}

public func xpForLevel(_ level: Int) -> Int {
    level * level * 50
}

public func getLevelInfo(_ totalXP: Int) -> LevelInfo {
    let level = calculateLevel(totalXP)
    let currentLevelXP = xpForLevel(level)
    let nextLevelXP = xpForLevel(level + 1)
    let range = nextLevelXP - currentLevelXP
    let progress = totalXP - currentLevelXP

    let titleEntry = LEVEL_TITLES.first { level <= $0.maxLevel } ?? LEVEL_TITLES[LEVEL_TITLES.count - 1]

    return LevelInfo(
        level: level,
        title: titleEntry.en,
        titleKey: titleEntry.key,
        currentXP: totalXP,
        xpForCurrentLevel: currentLevelXP,
        xpForNextLevel: nextLevelXP,
        progressPercent: range > 0 ? min(100, Int((Double(progress) / Double(range) * 100).rounded())) : 100
    )
}

// ─── Streak Multiplier ──────────────────────────────────────

public func getStreakMultiplier(_ streakDays: Int) -> Double {
    if streakDays >= 31 { return 2.0 }
    if streakDays >= 15 { return 1.5 }
    if streakDays >= 8 { return 1.25 }
    return 1.0
}

// ─── XP Calculation ─────────────────────────────────────────

public func calculateSessionXP(
    _ session: SessionResult,
    _ streak: StreakData,
    _ profile: HabitProfile,
    _ previousBestAvgMs: Double? = nil
) -> [XPEvent] {
    var events: [XPEvent] = []

    events.append(XPEvent(amount: XP_SESSION_COMPLETE, reason: "Session complete", reasonKey: "habit.xp_session_complete"))

    if let previousBestAvgMs, session.avgMs < previousBestAvgMs {
        events.append(XPEvent(amount: XP_PERSONAL_BEST, reason: "New personal best!", reasonKey: "habit.xp_personal_best"))
    }

    if streak.current > 0 {
        let multiplier = getStreakMultiplier(streak.current)
        let streakXP = Int((Double(XP_STREAK_DAY) * multiplier).rounded())
        events.append(XPEvent(amount: streakXP, reason: "Day \(streak.current) streak (\(multiplier)×)", reasonKey: "habit.xp_streak_day",
                              reasonParams: ["days": "\(streak.current)", "multiplier": "\(multiplier)"]))
    }

    if streak.current == 7 {
        events.append(XPEvent(amount: XP_STREAK_7_BONUS, reason: "7-day streak!", reasonKey: "habit.xp_streak_7"))
    } else if streak.current == 14 {
        events.append(XPEvent(amount: XP_STREAK_14_BONUS, reason: "14-day streak!", reasonKey: "habit.xp_streak_14"))
    } else if streak.current == 30 {
        events.append(XPEvent(amount: XP_STREAK_30_BONUS, reason: "30-day streak!", reasonKey: "habit.xp_streak_30"))
    }

    if session.elapsedMs > 300_000 {
        events.append(XPEvent(amount: XP_LONG_SESSION, reason: "Long session bonus", reasonKey: "habit.xp_long_session"))
    }

    let today = dayString(Date())
    if profile.lastSessionDate == today && profile.sessionsToday >= 2 {
        events.append(XPEvent(amount: XP_DEDICATED, reason: "Dedicated practice!", reasonKey: "habit.xp_dedicated"))
    }

    if let timings = session.chordTimings {
        let roots = Set(timings.map { $0.root })
        if roots.count >= 12 {
            events.append(XPEvent(amount: XP_FULL_CIRCLE, reason: "All 12 keys!", reasonKey: "habit.xp_full_circle"))
        }
    }

    if session.midi.enabled && session.midi.accuracy >= 95 {
        events.append(XPEvent(amount: XP_HIGH_ACCURACY, reason: "\(session.midi.accuracy)% accuracy!", reasonKey: "habit.xp_high_accuracy",
                              reasonParams: ["accuracy": "\(session.midi.accuracy)"]))
    }

    return events
}

public func sumXP(_ events: [XPEvent]) -> Int {
    events.reduce(0) { $0 + $1.amount }
}

// ─── Week boundary helpers ──────────────────────────────────

private func weekStartISO(_ now: Date = Date()) -> String {
    let day = utcCalendar.component(.weekday, from: now) // 1 = Sunday
    let jsDay = day - 1 // 0 = Sunday (match JS getDay)
    let diff = jsDay == 0 ? 6 : jsDay - 1
    let monday = utcCalendar.date(byAdding: .day, value: -diff, to: now)!
    return dayString(monday)
}

private func weekEndISO(_ now: Date = Date()) -> String {
    let day = utcCalendar.component(.weekday, from: now)
    let jsDay = day - 1
    let diff = jsDay == 0 ? 0 : 7 - jsDay
    let sunday = utcCalendar.date(byAdding: .day, value: diff, to: now)!
    return dayString(sunday)
}

private func generateGoalId() -> String {
    let ms = Int(Date().timeIntervalSince1970 * 1000)
    let rand = String(Int.random(in: 0..<1_000_000), radix: 36)
    return String(ms, radix: 36) + rand
}

// ─── Smart Goal Generation ──────────────────────────────────

public func generateGoals(_ profile: HabitProfile, _ history: [SessionResult], _ streak: StreakData) -> [SmartGoal] {
    var goals: [SmartGoal] = []
    let expiresAt = weekEndISO() + "T23:59:59.999Z"
    let createdAt = isoNow()

    let currentWeekStart = weekStartISO()
    var weekDays = Set<String>()
    for s in history {
        let date = dayString(fromMillis: s.timestamp)
        if date >= currentWeekStart { weekDays.insert(date) }
    }

    // 1. CONSISTENCY
    if streak.current < 14 {
        let targetDays = streak.current < 3 ? 3 : 5
        goals.append(SmartGoal(
            id: generateGoalId(), type: .consistency,
            title: "Practice \(targetDays) days this week", titleKey: "habit.goal_consistency",
            titleParams: ["days": "\(targetDays)"],
            description: "Building the habit is more important than any single session",
            descriptionKey: "habit.goal_consistency_desc", descriptionParams: nil,
            icon: "📅", target: Double(targetDays), current: Double(weekDays.count),
            xpReward: XP_GOAL_COMPLETED, createdAt: createdAt, completedAt: nil, expiresAt: expiresAt))
    }

    // 2. SPEED
    let weakSpots = analyzeWeakSpots(history, 5)
    if let ws = weakSpots.first, ws.avgMs > 2000 {
        let vLabel = VOICING_SHORT_LABELS[ws.voicing.rawValue] ?? ws.voicing.rawValue
        let targetTime = max(1.5, (ws.avgMs / 1000 * 0.75 * 10).rounded() / 10)
        let currentSec = (ws.avgMs / 1000 * 10).rounded() / 10
        goals.append(SmartGoal(
            id: generateGoalId(), type: .speed,
            title: "Get \(ws.root) \(vLabel) under \(targetTime)s", titleKey: "habit.goal_speed",
            titleParams: ["root": ws.root, "voicing": vLabel, "target": "\(targetTime)"],
            description: "Currently \(currentSec)s average — aim for \(targetTime)s",
            descriptionKey: "habit.goal_speed_desc", descriptionParams: ["current": "\(currentSec)", "target": "\(targetTime)"],
            icon: "⚡", target: targetTime, current: currentSec,
            xpReward: XP_GOAL_COMPLETED, createdAt: createdAt, completedAt: nil, expiresAt: expiresAt))
    }

    // 3. EXPLORATION
    var usedVoicings = Set<String>()
    for s in history { usedVoicings.insert(s.settings.voicing.rawValue) }
    let allVoicings: [(key: String, label: String)] = [
        ("root", "Root Position"), ("shell", "Shell Voicing"), ("half-shell", "Half Shell"),
        ("full", "Full Voicing"), ("rootless-a", "Rootless A"), ("rootless-b", "Rootless B"),
        ("inversion-1", "1st Inversion"), ("inversion-2", "2nd Inversion"), ("inversion-3", "3rd Inversion"),
    ]
    let unused = allVoicings.filter { !usedVoicings.contains($0.key) }
    if let first = unused.first, goals.count < 3 {
        goals.append(SmartGoal(
            id: generateGoalId(), type: .exploration,
            title: "Try \(first.label)", titleKey: "habit.goal_exploration",
            titleParams: ["voicing": first.label],
            description: "Expand your voicing vocabulary — \(unused.count) types still unexplored",
            descriptionKey: "habit.goal_exploration_desc", descriptionParams: ["remaining": "\(unused.count)"],
            icon: "🔍", target: 1, current: 0,
            xpReward: XP_NEW_VOICING, createdAt: createdAt, completedAt: nil, expiresAt: expiresAt))
    }

    // 4. ENDURANCE
    let recentSessions = Array(history.prefix(10))
    let avgChords = recentSessions.isEmpty ? 0.0 : Double(recentSessions.reduce(0) { $0 + $1.totalChords }) / Double(recentSessions.count)
    if avgChords > 0 && avgChords < 30 && goals.count < 3 {
        goals.append(SmartGoal(
            id: generateGoalId(), type: .endurance,
            title: "Complete a 50-chord session", titleKey: "habit.goal_endurance", titleParams: nil,
            description: "Push your stamina with a longer session",
            descriptionKey: "habit.goal_endurance_desc", descriptionParams: nil,
            icon: "💪", target: 50, current: 0,
            xpReward: XP_GOAL_COMPLETED, createdAt: createdAt, completedAt: nil, expiresAt: expiresAt))
    }

    // 5. REVIEW
    let now = Date()
    let dueChords = profile.chordSchedule.filter { parseISO($0.nextReview) <= now }
    if dueChords.count >= 3 && goals.count < 3 {
        goals.append(SmartGoal(
            id: generateGoalId(), type: .review,
            title: "\(dueChords.count) chords due for review", titleKey: "habit.goal_review",
            titleParams: ["count": "\(dueChords.count)"],
            description: "Keep your skills sharp — these chords need refreshing",
            descriptionKey: "habit.goal_review_desc", descriptionParams: nil,
            icon: "🔄", target: Double(dueChords.count), current: 0,
            xpReward: 20, createdAt: createdAt, completedAt: nil, expiresAt: expiresAt))
    }

    // 6. ACCURACY
    let midiSessions = history.filter { $0.midi.enabled && $0.midi.accuracy > 0 }
    if midiSessions.count >= 3 && goals.count < 3 {
        let sample = Array(midiSessions.prefix(10))
        let avgAccuracy = Int((Double(sample.reduce(0) { $0 + $1.midi.accuracy }) / Double(sample.count)).rounded())
        if avgAccuracy < 90 {
            let target = min(90, avgAccuracy + 10)
            goals.append(SmartGoal(
                id: generateGoalId(), type: .accuracy,
                title: "Reach \(target)% MIDI accuracy", titleKey: "habit.goal_accuracy",
                titleParams: ["target": "\(target)"],
                description: "Currently \(avgAccuracy)% — clean playing beats fast playing",
                descriptionKey: "habit.goal_accuracy_desc", descriptionParams: ["current": "\(avgAccuracy)", "target": "\(target)"],
                icon: "🎯", target: Double(target), current: Double(avgAccuracy),
                xpReward: XP_GOAL_COMPLETED, createdAt: createdAt, completedAt: nil, expiresAt: expiresAt))
        }
    }

    // 7. MASTERY
    if history.count > 20 && goals.count < 3 {
        let iiVISessions = history.filter { $0.settings.progressionMode == .twoFiveOne }
        let bestAvg = iiVISessions.map { $0.avgMs }.min() ?? Double.infinity
        if bestAvg > 2500 {
            let current = bestAvg == Double.infinity ? 0 : (bestAvg / 1000 * 10).rounded() / 10
            goals.append(SmartGoal(
                id: generateGoalId(), type: .mastery,
                title: "ii-V-I in all keys under 2.5s/chord", titleKey: "habit.goal_mastery_251", titleParams: nil,
                description: "The ultimate jazz drill — smooth through every key",
                descriptionKey: "habit.goal_mastery_251_desc", descriptionParams: nil,
                icon: "🏆", target: 2.5, current: current,
                xpReward: 50, createdAt: createdAt, completedAt: nil, expiresAt: expiresAt))
        }
    }

    return Array(goals.prefix(3))
}

// ─── Spaced Repetition (SM-2 variant) ───────────────────────

public func updateChordSchedule(_ review: ChordReview, _ quality: Int) -> ChordReview {
    let now = Date()
    var interval = review.interval
    var ease = review.ease
    var repetitions = review.repetitions

    if quality >= 3 {
        if repetitions == 0 {
            interval = 1
        } else if repetitions == 1 {
            interval = 3
        } else {
            interval = Int((Double(interval) * ease).rounded())
        }
        repetitions += 1
    } else {
        repetitions = 0
        interval = 1
    }

    let q = Double(quality)
    ease = max(1.3, ease + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))

    let nextReview = utcCalendar.date(byAdding: .day, value: interval, to: now)!

    var updated = review
    updated.lastReviewed = isoNow(now)
    updated.nextReview = isoNow(nextReview)
    updated.interval = interval
    updated.ease = (ease * 100).rounded() / 100
    updated.repetitions = repetitions
    return updated
}

public func timingToQuality(_ avgMs: Double, _ medianMs: Double) -> Int {
    let ratio = avgMs / medianMs
    if ratio < 0.5 { return 5 }
    if ratio < 0.7 { return 4 }
    if ratio < 1.0 { return 3 }
    if ratio < 1.4 { return 2 }
    if ratio < 2.0 { return 1 }
    return 0
}

public func processSessionForSchedule(_ schedule: [ChordReview], _ timings: [ChordTiming]) -> [ChordReview] {
    if timings.isEmpty { return schedule }

    var grouped: [String: [Double]] = [:]
    for t in timings {
        let quality = t.chord.hasPrefix(t.root) ? (String(t.chord.dropFirst(t.root.count)).isEmpty ? "Maj" : String(t.chord.dropFirst(t.root.count))) : t.chord
        let key = "\(t.root)-\(quality)"
        grouped[key, default: []].append(t.durationMs)
    }

    var allTimes = timings.map { $0.durationMs }
    allTimes.sort()
    let medianMs = allTimes.isEmpty ? 3000.0 : allTimes[allTimes.count / 2]

    var scheduleMap: [String: ChordReview] = [:]
    for s in schedule { scheduleMap[s.chordKey] = s }

    for (key, times) in grouped {
        let avgMs = times.reduce(0, +) / Double(times.count)
        let quality = timingToQuality(avgMs, medianMs)

        if let existing = scheduleMap[key] {
            scheduleMap[key] = updateChordSchedule(existing, quality)
        } else {
            let parts = key.split(separator: "-", maxSplits: 1).map(String.init)
            let root = parts.first ?? ""
            let qualityStr = parts.count > 1 ? parts[1] : ""
            let now = Date()
            let nextReview = utcCalendar.date(byAdding: .day, value: quality >= 3 ? 1 : 0, to: now)!
            scheduleMap[key] = ChordReview(
                chordKey: key, root: root, quality: qualityStr,
                lastReviewed: isoNow(now), nextReview: isoNow(nextReview),
                interval: quality >= 3 ? 1 : 0, ease: 2.5, repetitions: quality >= 3 ? 1 : 0)
        }
    }

    return Array(scheduleMap.values)
}

// ─── Quick Start Suggestion ─────────────────────────────────

public struct QuickStartSuggestion: Sendable, Equatable {
    public let title: String
    public let titleKey: String
    public let titleParams: [String: String]?
    public let description: String
    public let descriptionKey: String
    public let descriptionParams: [String: String]?
    public let planId: String?
    public let minutes: Int
    public let icon: String
    public let focusRoots: [String]?
    public let focusVoicing: String?
}

public func getQuickStartSuggestion(_ profile: HabitProfile, _ history: [SessionResult], _ streak: StreakData) -> QuickStartSuggestion {
    if streak.current == 0 && streak.best > 3 {
        return QuickStartSuggestion(
            title: "Quick restart: 4 chords", titleKey: "habit.quick_restart", titleParams: nil,
            description: "Just 4 chords. That's all it takes to start again.",
            descriptionKey: "habit.quick_restart_desc", descriptionParams: nil,
            planId: nil, minutes: 1, icon: "🔥", focusRoots: nil, focusVoicing: nil)
    }

    let weakSpots = analyzeWeakSpots(history, 10)
    let slowSpots = weakSpots.filter { $0.avgMs > 2500 }
    if !slowSpots.isEmpty {
        var byVoicing: [String: [WeakSpot]] = [:]
        for ws in slowSpots { byVoicing[ws.voicing.rawValue, default: []].append(ws) }
        let sortedGroups = byVoicing.sorted { a, b in
            if a.value.count != b.value.count { return a.value.count > b.value.count }
            return a.value[0].avgMs > b.value[0].avgMs
        }
        let (worstVoicing, worstSpots) = sortedGroups[0]
        let roots = worstSpots.prefix(3).map { $0.root }
        let targetTime = max(1.5, (worstSpots[0].avgMs / 1000 * 0.75 * 10).rounded() / 10)
        let voicingLabel = VOICING_SHORT_LABELS[worstVoicing] ?? worstVoicing
        let rootsStr = roots.joined(separator: ", ")
        return QuickStartSuggestion(
            title: "\(voicingLabel): \(rootsStr) under \(targetTime)s", titleKey: "habit.quick_weak_focus",
            titleParams: ["voicing": voicingLabel, "root": rootsStr, "target": "\(targetTime)"],
            description: "Focused drill — \(rootsStr) in \(voicingLabel) appear most often",
            descriptionKey: "habit.quick_weak_focus_desc", descriptionParams: ["voicing": voicingLabel, "roots": rootsStr],
            planId: "adaptive-drill", minutes: 3, icon: "🎯", focusRoots: Array(roots), focusVoicing: worstVoicing)
    }

    return QuickStartSuggestion(
        title: "\(profile.dailyGoalMinutes) min warm-up", titleKey: "habit.quick_warmup",
        titleParams: ["minutes": "\(profile.dailyGoalMinutes)"],
        description: "Your daily practice — start with what you know",
        descriptionKey: "habit.quick_warmup_desc", descriptionParams: nil,
        planId: "warmup", minutes: profile.dailyGoalMinutes, icon: "☀️", focusRoots: nil, focusVoicing: nil)
}

// ─── Goal Progress Check ────────────────────────────────────

public func checkGoalProgress(
    _ goals: [SmartGoal],
    _ session: SessionResult,
    _ history: [SessionResult],
    _ streak: StreakData
) -> (updated: [SmartGoal], completed: [SmartGoal]) {
    var completed: [SmartGoal] = []
    var updated: [SmartGoal] = []

    for goal in goals {
        if goal.completedAt != nil {
            updated.append(goal)
            continue
        }

        var g = goal

        switch g.type {
        case .consistency:
            let currentWeekStart = weekStartISO()
            var weekDays = Set<String>()
            for s in history {
                let date = dayString(fromMillis: s.timestamp)
                if date >= currentWeekStart { weekDays.insert(date) }
            }
            g.current = Double(weekDays.count)
        case .speed:
            let spots = analyzeWeakSpots(history, 10)
            let targetRoot = g.titleParams?["root"]
            let targetVoicing = g.titleParams?["voicing"]
            if let targetRoot {
                let matching: WeakSpot? = targetVoicing != nil
                    ? spots.first { $0.root == targetRoot && (VOICING_SHORT_LABELS[$0.voicing.rawValue] ?? $0.voicing.rawValue) == targetVoicing }
                    : spots.first { $0.root == targetRoot }
                g.current = matching != nil ? (matching!.avgMs / 1000 * 10).rounded() / 10 : g.target
            }
        case .exploration:
            let voicingUsed = session.settings.voicing.rawValue
            if g.titleParams?["voicing"] != nil {
                let usedVoicings = Set(history.map { $0.settings.voicing.rawValue })
                g.current = usedVoicings.contains(voicingUsed) ? 1 : 0
            }
        case .endurance:
            g.current = max(g.current, Double(session.totalChords))
        case .mastery:
            let iiVI = history.filter { $0.settings.progressionMode == .twoFiveOne }
            let best = iiVI.map { $0.avgMs }.min() ?? Double.infinity
            g.current = best == Double.infinity ? 0 : (best / 1000 * 10).rounded() / 10
        case .accuracy:
            let recentMidi = history.filter { $0.midi.enabled && $0.midi.accuracy > 0 }.prefix(10)
            if !recentMidi.isEmpty {
                g.current = Double((Double(recentMidi.reduce(0) { $0 + $1.midi.accuracy }) / Double(recentMidi.count)).rounded())
            }
        case .review:
            let sinceCreation = history.filter { parseISO(isoNow(Date(timeIntervalSince1970: $0.timestamp / 1000))) >= parseISO(g.createdAt) }
            var reviewedRoots = Set<String>()
            for s in sinceCreation {
                if let timings = s.chordTimings {
                    for ct in timings { reviewedRoots.insert(ct.root) }
                }
            }
            g.current = Double(reviewedRoots.count)
        }

        if isGoalMet(g) {
            g.completedAt = isoNow()
            completed.append(g)
        }
        updated.append(g)
    }

    return (updated, completed)
}

private func isGoalMet(_ goal: SmartGoal) -> Bool {
    switch goal.type {
    case .consistency, .endurance, .exploration, .review, .accuracy:
        return goal.current >= goal.target
    case .speed, .mastery:
        return goal.current > 0 && goal.current <= goal.target
    }
}

// ─── Default Profile ────────────────────────────────────────

public func createDefaultProfile() -> HabitProfile {
    HabitProfile(
        dailyGoalMinutes: 5, preferredTime: .evening, practiceAnchor: "",
        totalXP: 0, weeklyXP: 0, weekStart: weekStartISO(),
        activeGoals: [], completedGoals: [], chordSchedule: [],
        notificationsEnabled: false, notificationTime: "20:00", lastNotificationDate: "",
        onboardingDone: false, sessionsToday: 0, lastSessionDate: "",
        dailyGoalDates: [], todayPracticeMs: 0)
}

public func migrateToHabitProfile(_ history: [SessionResult], _ streak: StreakData) -> HabitProfile {
    var profile = createDefaultProfile()
    profile.totalXP = history.count * XP_SESSION_COMPLETE
    if streak.best > 0 { profile.totalXP += streak.best * XP_STREAK_DAY }

    let today = dayString(Date())
    profile.sessionsToday = history.filter { dayString(fromMillis: $0.timestamp) == today }.count
    profile.lastSessionDate = history.first.map { dayString(fromMillis: $0.timestamp) } ?? ""

    return profile
}

// ─── Daily Progress & Motivation ────────────────────────────

public struct DailyProgress: Sendable, Equatable {
    public let practicedMinutes: Double
    public let goalMinutes: Int
    public let progressPercent: Int
    public let remainingMinutes: Int
    public let goalMet: Bool
}

public func getDailyProgress(_ profile: HabitProfile) -> DailyProgress {
    let today = dayString(Date())
    let practicedMs = profile.lastSessionDate == today ? profile.todayPracticeMs : 0
    let practicedMinutes = (practicedMs / 60000 * 10).rounded() / 10
    let goalMinutes = profile.dailyGoalMinutes
    let progressPercent = min(100, Int((practicedMs / (Double(goalMinutes) * 60000) * 100).rounded()))
    let remainingMs = max(0, Double(goalMinutes) * 60000 - practicedMs)
    let remainingMinutes = Int((remainingMs / 60000).rounded(.up))
    let goalMet = practicedMs >= Double(goalMinutes) * 60000

    return DailyProgress(practicedMinutes: practicedMinutes, goalMinutes: goalMinutes,
                         progressPercent: progressPercent, remainingMinutes: remainingMinutes, goalMet: goalMet)
}

public enum MotivationType: String, Sendable {
    case notStarted = "not-started"
    case justStarted = "just-started"
    case almostThere = "almost-there"
    case goalReached = "goal-reached"
    case extraCredit = "extra-credit"
    case streakAtRisk = "streak-at-risk"
}

public struct DailyMotivation: Sendable, Equatable {
    public let type: MotivationType
    public let messageKey: String
    public let messageParams: [String: String]
    public let emoji: String
}

public func getDailyMotivation(_ profile: HabitProfile, _ streak: StreakData, now: Date = Date()) -> DailyMotivation {
    let progress = getDailyProgress(profile)
    let hour = Calendar.current.component(.hour, from: now)
    let today = dayString(now)
    let practicedToday = profile.lastSessionDate == today && profile.sessionsToday > 0

    if !practicedToday && hour >= 18 && streak.current >= 2 {
        return DailyMotivation(type: .streakAtRisk, messageKey: "habit.motivation_streak_risk", messageParams: ["days": "\(streak.current)"], emoji: "🔥")
    }
    if !practicedToday || progress.progressPercent == 0 {
        return DailyMotivation(type: .notStarted, messageKey: "habit.motivation_not_started", messageParams: ["minutes": "\(progress.goalMinutes)"], emoji: "🎹")
    }
    if progress.goalMet && profile.sessionsToday > 1 {
        return DailyMotivation(type: .extraCredit, messageKey: "habit.motivation_extra", messageParams: ["practiced": "\(progress.practicedMinutes)"], emoji: "⭐")
    }
    if progress.goalMet {
        return DailyMotivation(type: .goalReached, messageKey: "habit.motivation_goal_reached", messageParams: [:], emoji: "🎉")
    }
    if progress.progressPercent >= 70 {
        return DailyMotivation(type: .almostThere, messageKey: "habit.motivation_almost", messageParams: ["remaining": "\(progress.remainingMinutes)"], emoji: "💪")
    }
    return DailyMotivation(type: .justStarted, messageKey: "habit.motivation_keep_going",
                           messageParams: ["remaining": "\(progress.remainingMinutes)", "practiced": "\(progress.practicedMinutes)"], emoji: "🎵")
}
