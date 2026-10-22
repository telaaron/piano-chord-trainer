import XCTest
@testable import JazzChords

/// Same cases as the web's src/lib/services/cloud-merge.test.ts: iOS and the
/// browser write the same account row, so they must merge it the same way.
final class SyncMergeTests: XCTestCase {
    private let H = SyncMerge.historyKey
    private let P = SyncMerge.profileKey
    private let S = SyncMerge.streakKey

    private func session(_ id: String, _ ts: Double) -> JSONValue {
        .object(["id": .string(id), "timestamp": .number(ts)])
    }

    private func ids(_ v: JSONValue?) -> [String] {
        guard case .array(let items)? = v else { return [] }
        return items.compactMap { if case .object(let o) = $0, case .string(let id)? = o["id"] { return id } else { return nil } }
    }

    func testFreshDeviceDoesNotWipeHistory() {
        let cloud: SyncData = [H: .array([session("a", 2), session("b", 1)])]
        let merged = SyncMerge.merge(local: [:], cloud: cloud)
        XCTAssertEqual(merged[H], cloud[H])
    }

    func testHistoryUnionNewestFirstNoDuplicates() {
        let local: SyncData = [H: .array([session("c", 3), session("a", 2)])]
        let cloud: SyncData = [H: .array([session("a", 2), session("b", 1)])]
        XCTAssertEqual(ids(SyncMerge.merge(local: local, cloud: cloud)[H]), ["c", "a", "b"])
    }

    func testHistoryCappedAt100() {
        func mk(_ p: String, _ n: Int) -> JSONValue { .array((0..<n).map { session("\(p)\($0)", Double($0)) }) }
        let merged = SyncMerge.merge(local: [H: mk("l", 80)], cloud: [H: mk("c", 80)])
        XCTAssertEqual(ids(merged[H]).count, 100)
    }

    func testProfileMoreXPWinsOnboardingOred() {
        let local: SyncData = [P: .object(["totalXP": .number(0), "onboardingDone": .bool(true), "dailyGoalMinutes": .number(5)])]
        let cloud: SyncData = [P: .object(["totalXP": .number(900), "onboardingDone": .bool(false), "dailyGoalMinutes": .number(10)])]
        guard case .object(let p)? = SyncMerge.merge(local: local, cloud: cloud)[P] else { return XCTFail("profile missing") }
        XCTAssertEqual(p["totalXP"], .number(900))
        XCTAssertEqual(p["dailyGoalMinutes"], .number(10))
        XCTAssertEqual(p["onboardingDone"], .bool(true))
    }

    func testStreakLatestDayBestMax() {
        let local: SyncData = [S: .object(["current": .number(1), "best": .number(2), "lastDate": .string("2026-10-16")])]
        let cloud: SyncData = [S: .object(["current": .number(5), "best": .number(9), "lastDate": .string("2026-10-10")])]
        XCTAssertEqual(SyncMerge.merge(local: local, cloud: cloud)[S],
                       .object(["current": .number(1), "best": .number(9), "lastDate": .string("2026-10-16")]))
    }

    func testAccountWinsPlainSettingsLocalOnlyKeysKept() {
        let merged = SyncMerge.merge(
            local: ["chord-trainer-theme": .string("light"), "chord-trainer-locale": .string("de")],
            cloud: ["chord-trainer-theme": .string("dark")])
        XCTAssertEqual(merged["chord-trainer-theme"], .string("dark"))
        XCTAssertEqual(merged["chord-trainer-locale"], .string("de"))
    }

    func testWithoutKeepLocalAccountReplaces() {
        let local: SyncData = [H: .array([session("x", 9)])]
        let cloud: SyncData = [H: .array([session("a", 2)])]
        XCTAssertEqual(SyncMerge.merge(local: local, cloud: cloud, keepLocal: false)[H], cloud[H])
    }

    /// iPhone and iPad both practiced offline; neither may lose a session.
    func testTwoOfflineDevicesUnion() {
        let local: SyncData = [H: .array([session("b", 20), session("a", 10)])]
        let cloud: SyncData = [H: .array([session("c", 30), session("b", 20)])]
        XCTAssertEqual(ids(SyncMerge.merge(local: local, cloud: cloud)[H]), ["c", "b", "a"])
    }

    /// Sessions without an id fall back to their timestamp, like the web.
    func testHistoryWithoutIdDedupesByTimestamp() {
        let noId = JSONValue.object(["timestamp": .number(5)])
        let merged = SyncMerge.merge(local: [H: .array([noId])], cloud: [H: .array([noId])])
        guard case .array(let items)? = merged[H] else { return XCTFail("history missing") }
        XCTAssertEqual(items.count, 1)
    }

    func testSettingsMergePerFieldKeepsIOSOnlyFields() {
        let key = SyncMerge.settingsKey
        let local: SyncData = [key: .object(["totalChords": .number(20), "soundPreset": .string("rhodes")])]
        let cloud: SyncData = [key: .object(["totalChords": .number(36), "midiEnabled": .bool(false)])]
        XCTAssertEqual(SyncMerge.merge(local: local, cloud: cloud)[key], .object([
            "totalChords": .number(36), "soundPreset": .string("rhodes"), "midiEnabled": .bool(false),
        ]))
    }

    func testPreferLocalKeepsDeviceEditsButStillUnionsHistory() {
        let K = SyncMerge.settingsKey
        let local: SyncData = [K: .object(["totalChords": .number(36)]), "x": .string("device"),
                               H: .array([session("a", 2)])]
        let cloud: SyncData = [K: .object(["totalChords": .number(20), "midiEnabled": .bool(false)]),
                               "x": .string("account"), H: .array([session("b", 1)])]
        let merged = SyncMerge.merge(local: local, cloud: cloud, preferLocal: true)
        XCTAssertEqual(merged[K], .object(["totalChords": .number(36), "midiEnabled": .bool(false)]))
        XCTAssertEqual(merged["x"], .string("device"))
        XCTAssertEqual(ids(merged[H]), ["a", "b"])
    }

    func testPreferLocalKeepsProfilePreferencesButTakesHigherXP() {
        let local: SyncData = [P: .object(["totalXP": .number(10), "dailyGoalMinutes": .number(10),
                                           "notificationTime": .string("07:00")])]
        let cloud: SyncData = [P: .object(["totalXP": .number(500), "dailyGoalMinutes": .number(5),
                                           "notificationTime": .string("20:00")])]
        let merged = SyncMerge.merge(local: local, cloud: cloud, preferLocal: true)[P]?.object
        XCTAssertEqual(merged?["totalXP"], .number(500))
        XCTAssertEqual(merged?["dailyGoalMinutes"], .number(10))
        XCTAssertEqual(merged?["notificationTime"], .string("07:00"))
    }

    func testJSONValueRoundTripsThroughJSON() throws {
        let raw = #"{"a":[1,2.5,"x",true,null],"b":{"c":false}}"#.data(using: .utf8)!
        let value = try JSONDecoder().decode(JSONValue.self, from: raw)
        let again = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
        XCTAssertEqual(value, again)
        guard case .object(let o) = value, case .array(let a)? = o["a"] else { return XCTFail("shape") }
        XCTAssertEqual(a, [.number(1), .number(2.5), .string("x"), .bool(true), .null])
    }
}
