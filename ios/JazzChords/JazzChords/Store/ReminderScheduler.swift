// ReminderScheduler — the daily practice reminder as local notifications.
//
// Ports the web's scheduleDailyReminder (habits.ts) to UNUserNotificationCenter:
// one notification per day for the next week at HabitProfile.notificationTime,
// none today once the player has practiced. Pending requests are rebuilt on
// every `reschedule()` (app foreground, session end, settings change), so a
// week without opening the app ends in silence rather than nagging forever.
//
// Permission follows the pre-permission pattern: the app asks in its own card
// after the first finished drill (`shouldOfferPrompt`), and only a "yes" there
// triggers the one-time system dialog.

import Foundation
import Observation
import UserNotifications
import MusicEngine

@MainActor
@Observable
final class ReminderScheduler {
    static let shared = ReminderScheduler()

    private static let idPrefix = "practice-reminder-"
    private static let promptShownKey = "reminder-prompt-shown"
    private static let horizonDays = 7

    private let center = UNUserNotificationCenter.current()
    private(set) var authorization: UNAuthorizationStatus = .notDetermined

    private init() {}

    var isEnabled: Bool { HabitStore.shared.profile.notificationsEnabled }

    var time: ReminderTime {
        let p = HabitStore.shared.profile
        return ReminderTime(p.notificationTime) ?? .default(for: p.preferredTime)
    }

    /// Our own card is offered once, after a finished drill, while the system
    /// dialog has never been shown and reminders are off.
    var shouldOfferPrompt: Bool {
        !UserDefaults.standard.bool(forKey: Self.promptShownKey)
            && authorization == .notDetermined
            && !isEnabled
    }

    func refreshAuthorization() async {
        authorization = await center.notificationSettings().authorizationStatus
    }

    /// Mark the card as seen so it never comes back, whatever the answer.
    func markPromptShown() {
        UserDefaults.standard.set(true, forKey: Self.promptShownKey)
        TelemetryService.shared.track("reminder_prompt_shown", ["time": time.string])
    }

    /// "Yes" on our card (or the Settings toggle): ask the system, then turn on.
    /// Returns whether reminders are now on.
    @discardableResult
    func enable(at time: ReminderTime? = nil, source: String = "card") async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshAuthorization()
        TelemetryService.shared.track(granted ? "reminder_prompt_accepted" : "reminder_prompt_declined",
                                      ["time": (time ?? self.time).string, "system": true, "source": source])
        HabitStore.shared.setReminder(enabled: granted, time: (time ?? self.time).string)
        await reschedule()
        return granted
    }

    /// "Not now" on our card.
    func decline() {
        TelemetryService.shared.track("reminder_prompt_declined", ["time": time.string, "system": false, "source": "card"])
    }

    func disable() async {
        HabitStore.shared.setReminder(enabled: false, time: time.string)
        await reschedule()
    }

    func setTime(_ time: ReminderTime) async {
        HabitStore.shared.setReminder(enabled: isEnabled, time: time.string)
        await reschedule()
    }

    /// Rebuild the pending reminders from the current profile and history.
    func reschedule(now: Date = Date()) async {
        let pending = await center.pendingNotificationRequests()
            .map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        await refreshAuthorization()
        guard isEnabled, authorization == .authorized || authorization == .provisional else { return }

        let calendar = Calendar.current
        let last = ProgressStore.loadHistory().first.map { Date(timeIntervalSince1970: $0.timestamp / 1000) }
        let practiced = Reminders.practicedToday(lastSession: last, now: now, calendar: calendar)
        let dates = Reminders.fireDates(now: now, time: time, practicedToday: practiced,
                                        days: Self.horizonDays, calendar: calendar)
        // The stored streak is only refreshed on the next session, so it is only
        // still alive when the last session was today or yesterday.
        let daysSinceLast = last.flatMap {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: $0),
                                    to: calendar.startOfDay(for: now)).day
        }
        let streak = (daysSinceLast ?? .max) <= 1 ? ProgressStore.loadStreak().current : 0
        let minutes = HabitStore.shared.profile.dailyGoalMinutes

        for (i, date) in dates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = CoachL10n.t("reminder.title")
            // A running streak is only still alive on the first upcoming reminder.
            content.body = (i == 0 && streak >= 2)
                ? CoachL10n.t("reminder.body_streak", ["days": "\(streak)"])
                : CoachL10n.t("reminder.body", ["minutes": "\(minutes)"])
            content.sound = .default
            content.threadIdentifier = "practice-reminder"
            content.userInfo = ["reminder": true]

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = Self.idPrefix + ISO8601DateFormatter().string(from: date)
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }
}
