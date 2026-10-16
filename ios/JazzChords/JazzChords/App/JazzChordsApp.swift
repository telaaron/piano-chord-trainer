// App entry point. Sets up the root scene + the shared environment.

import SwiftUI
import UserNotifications

@main
struct JazzChordsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.init(hex: "f5a623")) // amber accent across the app
        }
        .onChange(of: scenePhase) { _, phase in
            // Keep the week of reminders rolling forward and drop today's once practiced.
            if phase == .active { Task { await ReminderScheduler.shared.reschedule() } }
        }
    }
}

/// Owns the notification-center delegate: measures reminder taps and keeps
/// reminders silent while the app is already open.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // nonisolated: the UN types are not Sendable, so they must not cross into the main actor.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        guard response.notification.request.content.userInfo["reminder"] as? Bool == true else { return }
        await MainActor.run { TelemetryService.shared.track("app_opened_from_reminder") }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        []
    }
}
