// Reminders — when the daily practice reminder fires. Pure date math, no
// UserNotifications: the app's ReminderScheduler turns these dates into local
// notifications. Mirrors the web's scheduleDailyReminder rules (habits.ts):
// never on a day the player already practiced, never in the past.

import Foundation

/// A wall-clock time of day ("HH:mm"), as stored in `HabitProfile.notificationTime`.
public struct ReminderTime: Sendable, Equatable {
    public let hour: Int
    public let minute: Int

    public init?(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    /// Parses "HH:mm" (also "H:mm"). Anything else → nil.
    public init?(_ string: String) {
        let parts = string.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, parts[1].count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        self.init(hour: h, minute: m)
    }

    /// "HH:mm", zero-padded.
    public var string: String { String(format: "%02d:%02d", hour, minute) }

    /// The reminder time that matches the slot picked in onboarding.
    public static func `default`(for slot: TimeOfDay) -> ReminderTime {
        switch slot {
        case .morning: return ReminderTime(hour: 8, minute: 0)!
        case .afternoon: return ReminderTime(hour: 13, minute: 0)!
        case .evening: return ReminderTime(hour: 19, minute: 0)!
        }
    }
}

public enum Reminders {
    /// Fire dates for the next `days` calendar days starting today, at `time`
    /// in `calendar`'s time zone. Today is skipped when the player already
    /// practiced or the time has passed. Days where `time` does not exist
    /// (DST gap) fall back to the next valid instant, never to a past one.
    public static func fireDates(
        now: Date,
        time: ReminderTime,
        practicedToday: Bool,
        days: Int = 7,
        calendar: Calendar
    ) -> [Date] {
        guard days > 0 else { return [] }
        let startOfToday = calendar.startOfDay(for: now)
        var out: [Date] = []
        for offset in 0..<days {
            if offset == 0 && practicedToday { continue }
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday),
                  let fire = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0,
                                           of: day, matchingPolicy: .nextTime,
                                           repeatedTimePolicy: .first, direction: .forward)
            else { continue }
            if fire > now { out.append(fire) }
        }
        return out
    }

    /// Whether `last` (the most recent session) falls on the same calendar day as `now`.
    public static func practicedToday(lastSession last: Date?, now: Date, calendar: Calendar) -> Bool {
        guard let last else { return false }
        return calendar.isDate(last, inSameDayAs: now)
    }
}
