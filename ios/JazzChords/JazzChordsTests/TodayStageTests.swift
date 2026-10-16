import XCTest
@testable import JazzChords

final class TodayStageTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func stage(sessions: Int, calibrated: Bool, after seconds: TimeInterval = 3600,
                       dismissed: Bool = false) -> TodayStage {
        TodayStage.of(sessions: sessions, calibrated: calibrated, firstLaunch: start,
                      now: start.addingTimeInterval(seconds), dismissed: dismissed)
    }

    func testBrandNewUser() {
        let s = stage(sessions: 0, calibrated: false)
        XCTAssertTrue(s.showsFirstStep)
        XCTAssertTrue(s.showsGuide)
        XCTAssertEqual(s.guideDone, [false, false, false])
        XCTAssertEqual(s.title, .welcome)
    }

    func testCalibratedOneSession() {
        let s = stage(sessions: 1, calibrated: true)
        XCTAssertFalse(s.showsFirstStep)
        XCTAssertTrue(s.showsGuide)
        XCTAssertEqual(s.guideDone, [true, false, false])
        XCTAssertEqual(s.title, .greeting)
    }

    func testGuideEndsAfterThreeSessions() {
        XCTAssertTrue(stage(sessions: 2, calibrated: true).showsGuide)
        XCTAssertFalse(stage(sessions: 3, calibrated: true).showsGuide)
        // Three sessions without the check: the guide still has a job.
        XCTAssertTrue(stage(sessions: 3, calibrated: false).showsGuide)
    }

    func testGuideEndsAfterSevenDays() {
        let day: TimeInterval = 86_400
        XCTAssertTrue(stage(sessions: 0, calibrated: false, after: 6 * day + 23 * 3600).showsGuide)
        XCTAssertFalse(stage(sessions: 0, calibrated: false, after: 7 * day).showsGuide)
    }

    func testDismissIsPermanent() {
        XCTAssertFalse(stage(sessions: 0, calibrated: false, dismissed: true).showsGuide)
    }

    func testStatsOmitEmpty() {
        XCTAssertTrue(StatsRow.items(streak: 0, avgMs: nil, sessions: 0).isEmpty)
        XCTAssertEqual(StatsRow.items(streak: 4, avgMs: 1800, sessions: 12).count, 3)
        XCTAssertEqual(StatsRow.items(streak: 0, avgMs: 1800, sessions: 2).count, 2)
    }
}
