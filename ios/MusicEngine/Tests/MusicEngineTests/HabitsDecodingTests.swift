// Habit JSON written by the web app must decode on iOS (cloud sync shares it).

import XCTest
@testable import MusicEngine

final class HabitsDecodingTests: XCTestCase {

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    private let webGoal = """
    {"id":"g1","type":"consistency","title":"Practice 3 days","titleKey":"habit.goal_days",
     "titleParams":{"days":3},"description":"d","descriptionKey":"habit.goal_days_desc",
     "descriptionParams":{"count":3,"label":"x"},"icon":"calendar","target":3,"current":1,
     "xpReward":50,"createdAt":"2026-10-12T00:00:00Z"}
    """

    func testSmartGoalDecodesNumericParamsFromWeb() throws {
        let goal = try decode(SmartGoal.self, webGoal)
        XCTAssertEqual(goal.titleParams, ["days": "3"])
        XCTAssertEqual(goal.descriptionParams, ["count": "3", "label": "x"])
    }

    func testSmartGoalParamsRoundTripAsStrings() throws {
        let goal = try decode(SmartGoal.self, webGoal)
        let again = try JSONDecoder().decode(SmartGoal.self, from: JSONEncoder().encode(goal))
        XCTAssertEqual(again, goal)
    }

    func testHabitProfileDecodesOlderWebProfileWithoutNewFields() throws {
        let json = """
        {"dailyGoalMinutes":10,"preferredTime":"evening","practiceAnchor":"","totalXP":420,
         "weeklyXP":30,"weekStart":"2026-10-12","activeGoals":[\(webGoal)],"completedGoals":[],
         "chordSchedule":[],"notificationsEnabled":false,"notificationTime":"19:00",
         "lastNotificationDate":"","onboardingDone":true}
        """
        let p = try decode(HabitProfile.self, json)
        XCTAssertEqual(p.totalXP, 420)
        XCTAssertEqual(p.dailyGoalMinutes, 10)
        XCTAssertEqual(p.activeGoals.first?.titleParams, ["days": "3"])
        XCTAssertEqual(p.todayPracticeMs, 0)
        XCTAssertEqual(p.sessionsToday, 0)
        XCTAssertEqual(p.dailyGoalDates, [])
        XCTAssertTrue(p.onboardingDone)
    }

    func testHabitProfileRoundTripsUnchanged() throws {
        var p = createDefaultProfile()
        p.totalXP = 99
        p.todayPracticeMs = 1234
        let again = try JSONDecoder().decode(HabitProfile.self, from: JSONEncoder().encode(p))
        XCTAssertEqual(again, p)
    }
}
