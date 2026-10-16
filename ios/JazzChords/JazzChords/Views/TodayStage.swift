// TodayStage — what Heute shows a newcomer (spec §1, CPO rule 16.10.).
//
// • First step: until the placement check is done, the red block invites to it.
// • "So funktioniert's": visible until the check is done AND three sessions are
//   finished, never longer than seven days after first launch, and gone for good
//   once dismissed. Its steps tick off as they happen.
// • Title: "Willkommen" until the first finished session, then the greeting.

import Foundation

struct TodayStage: Equatable {
    var showsFirstStep: Bool
    var showsGuide: Bool
    /// Check done · three sessions done · (third step has no end).
    var guideDone: [Bool]
    var title: Title

    enum Title: Equatable { case welcome, greeting }

    static let guideLifetime: TimeInterval = 7 * 86_400
    static let guideSessions = 3

    nonisolated static func of(sessions: Int, calibrated: Bool, firstLaunch: Date,
                               now: Date, dismissed: Bool) -> TodayStage {
        let graduated = calibrated && sessions >= guideSessions
        let expired = now >= firstLaunch.addingTimeInterval(guideLifetime)
        return TodayStage(
            showsFirstStep: !calibrated,
            showsGuide: !dismissed && !graduated && !expired,
            guideDone: [calibrated, sessions >= guideSessions, false],
            title: sessions == 0 ? .welcome : .greeting
        )
    }
}

/// First-launch date and the guide's dismissal, stored once per device.
enum NewcomerGuideStore {
    private static let firstLaunchKey = "newcomer-first-launch"
    private static let dismissedKey = "newcomer-guide-dismissed"

    /// The first time Heute was shown; recorded on first read.
    static var firstLaunch: Date {
        let d = UserDefaults.standard
        if let t = d.object(forKey: firstLaunchKey) as? Date { return t }
        let now = Date()
        d.set(now, forKey: firstLaunchKey)
        return now
    }

    static var dismissed: Bool {
        get { UserDefaults.standard.bool(forKey: dismissedKey) }
        set { UserDefaults.standard.set(newValue, forKey: dismissedKey) }
    }
}
