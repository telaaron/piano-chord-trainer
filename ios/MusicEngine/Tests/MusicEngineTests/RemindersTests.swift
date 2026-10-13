// Daily practice reminder dates (Reminders.swift).

import XCTest
@testable import MusicEngine

final class RemindersTests: XCTestCase {

    private var berlin: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return c
    }()

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int = 0) -> Date {
        berlin.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    private func hm(_ d: Date) -> String {
        let c = berlin.dateComponents([.month, .day, .hour, .minute], from: d)
        return String(format: "%02d-%02d %02d:%02d", c.month!, c.day!, c.hour!, c.minute!)
    }

    // MARK: ReminderTime

    func testParsesValidTimes() {
        XCTAssertEqual(ReminderTime("20:00"), ReminderTime(hour: 20, minute: 0))
        XCTAssertEqual(ReminderTime("7:05"), ReminderTime(hour: 7, minute: 5))
        XCTAssertEqual(ReminderTime("07:05")?.string, "07:05")
    }

    func testRejectsInvalidTimes() {
        XCTAssertNil(ReminderTime("24:00"))
        XCTAssertNil(ReminderTime("12:60"))
        XCTAssertNil(ReminderTime("12:5"))
        XCTAssertNil(ReminderTime("noon"))
        XCTAssertNil(ReminderTime(""))
    }

    func testDefaultTimePerSlot() {
        XCTAssertEqual(ReminderTime.default(for: .morning).string, "08:00")
        XCTAssertEqual(ReminderTime.default(for: .afternoon).string, "13:00")
        XCTAssertEqual(ReminderTime.default(for: .evening).string, "19:00")
    }

    // MARK: fireDates

    func testIncludesTodayWhenNotPracticedAndTimeAhead() {
        let dates = Reminders.fireDates(now: date(2026, 10, 13, 10), time: ReminderTime("19:00")!,
                                        practicedToday: false, days: 3, calendar: berlin)
        XCTAssertEqual(dates.map(hm), ["10-13 19:00", "10-14 19:00", "10-15 19:00"])
    }

    func testSkipsTodayWhenAlreadyPracticed() {
        let dates = Reminders.fireDates(now: date(2026, 10, 13, 10), time: ReminderTime("19:00")!,
                                        practicedToday: true, days: 3, calendar: berlin)
        XCTAssertEqual(dates.map(hm), ["10-14 19:00", "10-15 19:00"])
    }

    func testSkipsTodayWhenTimeHasPassed() {
        let dates = Reminders.fireDates(now: date(2026, 10, 13, 19, 1), time: ReminderTime("19:00")!,
                                        practicedToday: false, days: 2, calendar: berlin)
        XCTAssertEqual(dates.map(hm), ["10-14 19:00"])
    }

    func testExactlyNowIsNotInTheFuture() {
        let dates = Reminders.fireDates(now: date(2026, 10, 13, 19), time: ReminderTime("19:00")!,
                                        practicedToday: false, days: 1, calendar: berlin)
        XCTAssertTrue(dates.isEmpty)
    }

    func testKeepsWallClockAcrossDSTEnd() {
        // Berlin leaves summer time on Sun 25 Oct 2026.
        let dates = Reminders.fireDates(now: date(2026, 10, 24, 9), time: ReminderTime("19:00")!,
                                        practicedToday: false, days: 3, calendar: berlin)
        XCTAssertEqual(dates.map(hm), ["10-24 19:00", "10-25 19:00", "10-26 19:00"])
        XCTAssertEqual(dates[2].timeIntervalSince(dates[1]), 25 * 3600)
    }

    func testTimeInDSTGapMovesForward() {
        // 29 Mar 2026: 02:00–03:00 does not exist in Berlin.
        let dates = Reminders.fireDates(now: date(2026, 3, 28, 12), time: ReminderTime("02:30")!,
                                        practicedToday: false, days: 2, calendar: berlin)
        XCTAssertEqual(dates.count, 2)
        XCTAssertTrue(["03-29 03:00", "03-29 03:30"].contains(hm(dates[0])), hm(dates[0]))
        XCTAssertTrue(dates.allSatisfy { $0 > date(2026, 3, 28, 12) })
    }

    func testZeroDaysIsEmpty() {
        XCTAssertTrue(Reminders.fireDates(now: date(2026, 10, 13, 10), time: ReminderTime("19:00")!,
                                          practicedToday: false, days: 0, calendar: berlin).isEmpty)
    }

    // MARK: practicedToday

    func testPracticedTodayUsesLocalDay() {
        let now = date(2026, 10, 13, 0, 30)
        // 23:50 the evening before is yesterday locally, though the same UTC day.
        XCTAssertFalse(Reminders.practicedToday(lastSession: date(2026, 10, 12, 23, 50), now: now, calendar: berlin))
        XCTAssertTrue(Reminders.practicedToday(lastSession: date(2026, 10, 13, 0, 10), now: now, calendar: berlin))
        XCTAssertFalse(Reminders.practicedToday(lastSession: nil, now: now, calendar: berlin))
    }
}
