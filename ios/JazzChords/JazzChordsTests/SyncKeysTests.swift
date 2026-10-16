import XCTest
@testable import JazzChords

final class SyncKeysTests: XCTestCase {
    func testMapCoversSevenKeys() {
        XCTAssertEqual(SyncKeys.map, [
            "history": "chord-trainer-history",
            "streak": "chord-trainer-streak",
            "settings": "chord-trainer-settings",
            "habit-profile": "chord-trainer-habit-profile",
            "course-progress": "chord-trainer-course-progress",
            "coach-state": "chord-trainer-coach-state",
            "togo-cards": "chord-trainer-togo-cards",
        ])
    }

    func testSnapshotRoundTrip() {
        var files: [String: JSONValue] = [
            "history": .array([.object(["id": .string("s1"), "timestamp": .number(1)])]),
            "streak": .object(["current": .number(2), "best": .number(3), "lastDate": .string("2026-10-16")]),
            "plan-history": .array([.string("warmup")]), // not synced
        ]
        let snap = SyncKeys.snapshot { files[$0] }
        XCTAssertEqual(snap.keys.sorted(), ["chord-trainer-history", "chord-trainer-streak"])

        var written: [String: JSONValue] = [:]
        SyncKeys.apply(snap) { written[$0] = $1 }
        XCTAssertEqual(written["history"], files["history"])
        XCTAssertEqual(written["streak"], files["streak"])
        XCTAssertNil(written["plan-history"])
        files.removeAll()
    }

    func testApplyIgnoresWebOnlyKeys() {
        var written: [String: JSONValue] = [:]
        SyncKeys.apply(["chord-trainer-locale": .string("de"), "chord-trainer-celebrations": .array([])]) { written[$0] = $1 }
        XCTAssertTrue(written.isEmpty)
    }

    func testUnknownWebKeysSurviveUpload() {
        let lastCloud: SyncData = [
            "chord-trainer-locale": .string("de"),
            "chord-trainer-history": .array([]),
        ]
        let local: SyncData = ["chord-trainer-history": .array([.object(["id": .string("s1")])])]
        let payload = SyncKeys.payload(local: local, lastCloud: lastCloud)
        XCTAssertEqual(payload["chord-trainer-locale"], .string("de"))
        XCTAssertEqual(payload["chord-trainer-history"], local["chord-trainer-history"])
    }

    func testSettingsDecodeAfterRoundTrip() throws {
        var s = SavedSettings()
        s.totalChords = 36
        s.soundPreset = "rhodes"
        let raw = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(s))
        var written: [String: JSONValue] = [:]
        SyncKeys.apply(SyncKeys.snapshot { $0 == "settings" ? raw : nil }) { written[$0] = $1 }
        let back = try JSONDecoder().decode(SavedSettings.self, from: JSONEncoder().encode(written["settings"]))
        XCTAssertEqual(back, s)
    }

    func testStoreReportsSavedKeys() {
        var saved: [String] = []
        Store.onSave = { saved.append($0) }
        defer { Store.onSave = nil }
        Store.save(["x"], "sync-keys-test")
        Store.saveRaw(.array([]), "sync-keys-test")
        XCTAssertEqual(saved, ["sync-keys-test", "sync-keys-test"])
        XCTAssertEqual(Store.loadRaw("sync-keys-test"), .array([]))
    }
}
