// HabitStore — persistence + session processing for the Habit engine.
// Ports src/lib/services/habits.ts (loadHabitProfile weekly reset, saveHabitProfile,
// processSessionHabits). The pure engine functions live in MusicEngine.

import Foundation
import Observation
import MusicEngine

struct SessionHabitResult {
    var xpEvents: [XPEvent]
    var totalXP: Int
    var celebrations: [CelebrationEvent]
    var leveledUp: Bool
    var newLevel: Int?
    var completedGoals: [SmartGoal]
}

@MainActor
@Observable
final class HabitStore {
    static let shared = HabitStore()

    private(set) var profile: HabitProfile

    private init() {
        profile = Self.loadProfile()
    }

    // MARK: Date helpers (UTC YYYY-MM-DD)

    private static func dayString(_ d: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    private static func weekStartString(_ now: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let weekday = cal.component(.weekday, from: now) // 1 = Sun
        let jsDay = weekday - 1
        let diff = jsDay == 0 ? 6 : jsDay - 1
        let monday = cal.date(byAdding: .day, value: -diff, to: now)!
        return dayString(monday)
    }

    // MARK: Load / Save

    private static func loadProfile() -> HabitProfile {
        guard var p = Store.load(HabitProfile.self, StoreKey.habitProfile) else {
            // First run — migrate from any existing history/streak.
            let history = ProgressStore.loadHistory()
            let streak = ProgressStore.loadStreak()
            var migrated = migrateToHabitProfile(history, streak)
            if !history.isEmpty {
                migrated.activeGoals = generateGoals(migrated, history, streak)
            }
            Store.save(migrated, StoreKey.habitProfile)
            return migrated
        }

        let weekStart = weekStartString()
        if p.weekStart != weekStart {
            p.weeklyXP = 0
            p.weekStart = weekStart
            let history = ProgressStore.loadHistory()
            let streak = ProgressStore.loadStreak()
            p.activeGoals = generateGoals(p, history, streak)
        }

        let today = dayString()
        if p.lastSessionDate != today {
            p.sessionsToday = 0
            p.todayPracticeMs = 0
        }
        return p
    }

    func reload() { profile = Self.loadProfile() }

    private func save() { Store.save(profile, StoreKey.habitProfile) }

    var levelInfo: LevelInfo { getLevelInfo(profile.totalXP) }

    // MARK: Session processing (ports processSessionHabits)

    @discardableResult
    func processSession(_ session: SessionResult, previousBestAvgMs: Double?) -> SessionHabitResult {
        var p = profile
        let streak = ProgressStore.loadStreak()
        let history = ProgressStore.loadHistory()
        let oldLevel = getLevelInfo(p.totalXP).level

        // 1. XP
        var xpEvents = calculateSessionXP(session, streak, p, previousBestAvgMs)
        let baseXP = sumXP(xpEvents)

        // 2. Apply
        p.totalXP += baseXP
        p.weeklyXP += baseXP

        // 3. Daily practice time + goal achievement
        let today = Self.dayString()
        if p.lastSessionDate == today {
            p.todayPracticeMs += session.elapsedMs
        } else {
            p.todayPracticeMs = session.elapsedMs
        }
        if p.todayPracticeMs >= Double(p.dailyGoalMinutes) * 60000 && !p.dailyGoalDates.contains(today) {
            p.dailyGoalDates.append(today)
        }
        let weekStart = Self.weekStartString()
        if p.weekStart != weekStart { p.dailyGoalDates = [] }

        // 4. Sessions today
        if p.lastSessionDate == today {
            p.sessionsToday += 1
        } else {
            p.sessionsToday = 1
            p.lastSessionDate = today
        }

        // 5. Goal progress
        let (updated, completed) = checkGoalProgress(p.activeGoals, session, history, streak)
        p.activeGoals = updated.filter { $0.completedAt == nil }
        for goal in completed {
            p.totalXP += goal.xpReward
            p.weeklyXP += goal.xpReward
            xpEvents.append(XPEvent(amount: goal.xpReward, reason: "Goal: \(goal.title)",
                                    reasonKey: "habit.xp_goal_completed", reasonParams: ["title": goal.title]))
        }
        p.completedGoals = Array((completed + p.completedGoals).prefix(20))

        // Top up to 3 active goals
        if p.activeGoals.count < 3 {
            let newGoals = generateGoals(p, history, streak)
            var activeTypes = Set(p.activeGoals.map { $0.type })
            for ng in newGoals where !activeTypes.contains(ng.type) && p.activeGoals.count < 3 {
                p.activeGoals.append(ng)
                activeTypes.insert(ng.type)
            }
        }

        // 6. Spaced repetition
        if let timings = session.chordTimings, !timings.isEmpty {
            p.chordSchedule = processSessionForSchedule(p.chordSchedule, timings)
        }

        // 7. Level up
        let newLevel = getLevelInfo(p.totalXP).level
        let leveledUp = newLevel > oldLevel

        // 8. Celebrations
        var celebrations: [CelebrationEvent] = []
        let now = ISO8601DateFormatter().string(from: Date())
        let goalXP = completed.reduce(0) { $0 + $1.xpReward }
        let totalShown = baseXP + goalXP

        if totalShown > 0 {
            celebrations.append(CelebrationEvent(type: .xpGain, title: "+\(totalShown) XP",
                titleKey: "habit.celebration_xp", titleParams: ["amount": "\(totalShown)"],
                subtitle: nil, subtitleKey: nil, subtitleParams: nil, xpGained: baseXP, timestamp: now))
        }
        if leveledUp {
            let info = getLevelInfo(p.totalXP)
            celebrations.append(CelebrationEvent(type: .levelUp, title: "Level \(newLevel)!",
                titleKey: "habit.celebration_level_up", titleParams: ["level": "\(newLevel)"],
                subtitle: info.title, subtitleKey: info.titleKey, subtitleParams: nil, xpGained: 0, timestamp: now))
        }
        for goal in completed {
            celebrations.append(CelebrationEvent(type: .goalComplete, title: goal.title,
                titleKey: goal.titleKey, titleParams: goal.titleParams,
                subtitle: "+\(goal.xpReward) XP", subtitleKey: "habit.xp_amount", subtitleParams: ["amount": "\(goal.xpReward)"],
                xpGained: goal.xpReward, timestamp: now))
        }
        if [7, 14, 30, 50, 100].contains(streak.current) {
            celebrations.append(CelebrationEvent(type: .streakMilestone, title: "\(streak.current)-day streak!",
                titleKey: "habit.celebration_streak", titleParams: ["days": "\(streak.current)"],
                subtitle: nil, subtitleKey: nil, subtitleParams: nil, xpGained: 0, timestamp: now))
        }
        if let prev = previousBestAvgMs, session.avgMs < prev {
            let improvement = Int(((1 - session.avgMs / prev) * 100).rounded())
            celebrations.append(CelebrationEvent(type: .personalBest, title: "New Personal Best!",
                titleKey: "habit.celebration_pb", titleParams: nil,
                subtitle: "\(improvement)% faster", subtitleKey: "habit.celebration_pb_sub", subtitleParams: ["percent": "\(improvement)"],
                xpGained: 0, timestamp: now))
        }

        profile = p
        save()

        return SessionHabitResult(xpEvents: xpEvents, totalXP: totalShown, celebrations: celebrations,
                                  leveledUp: leveledUp, newLevel: leveledUp ? newLevel : nil, completedGoals: completed)
    }

    // MARK: Onboarding

    func completeOnboarding(dailyGoalMinutes: Int, preferredTime: TimeOfDay) {
        var p = profile
        p.dailyGoalMinutes = dailyGoalMinutes
        p.preferredTime = preferredTime
        p.onboardingDone = true
        let history = ProgressStore.loadHistory()
        let streak = ProgressStore.loadStreak()
        p.activeGoals = generateGoals(p, history, streak)
        profile = p
        save()
    }
}
