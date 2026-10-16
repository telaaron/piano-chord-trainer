// Data the web app writes into the shared account must load on iOS without
// being reset to defaults (and then saved back over the account's data).

import XCTest
import MusicEngine
@testable import JazzChords

final class WebCompatTests: XCTestCase {

    func testSettingsDecodeFromWebShape() throws {
        // What jazzchords.app stores: no sound/metronome fields, midiEnabled extra.
        let json = """
        {"difficulty":"advanced","notation":"symbols","voicing":"rootless","displayMode":"always",
         "accidentals":"both","notationSystem":"international","totalChords":36,
         "progressionMode":"random","midiEnabled":false}
        """
        let s = try JSONDecoder().decode(SavedSettings.self, from: Data(json.utf8))
        XCTAssertEqual(s.difficulty, .advanced)
        XCTAssertEqual(s.totalChords, 36)
        XCTAssertEqual(s.soundPreset, SavedSettings().soundPreset)
        XCTAssertEqual(s.metronomeBpm, SavedSettings().metronomeBpm)
        XCTAssertEqual(s.customDegrees, SavedSettings().customDegrees)
    }

    func testSettingsUnknownEnumValueFallsBackPerField() throws {
        let json = #"{"difficulty":"expert","totalChords":12}"#
        let s = try JSONDecoder().decode(SavedSettings.self, from: Data(json.utf8))
        XCTAssertEqual(s.difficulty, SavedSettings().difficulty)
        XCTAssertEqual(s.totalChords, 12)
    }

    func testGuardedLoadFlagsUnreadableFile() {
        Store.saveRaw(.string("not a dictionary"), "guarded-load-test")
        let unreadable = Store.loadGuarded([String: Int].self, "guarded-load-test")
        XCTAssertNil(unreadable.value)
        XCTAssertTrue(unreadable.locked)

        Store.saveRaw(.object(["a": .number(1)]), "guarded-load-test")
        let readable = Store.loadGuarded([String: Int].self, "guarded-load-test")
        XCTAssertEqual(readable.value, ["a": 1])
        XCTAssertFalse(readable.locked)

        let missing = Store.loadGuarded([String: Int].self, "guarded-load-missing")
        XCTAssertNil(missing.value)
        XCTAssertFalse(missing.locked)
    }

    func testSettingsPatchOnlyWritesTheFieldThatChanged() {
        var stored = SavedSettings()
        stored.totalChords = 36          // arrived from the account meanwhile
        var old = SavedSettings()
        old.totalChords = 20             // what the open sheet still shows
        var new = old
        new.metronomeEnabled = true      // the one thing the user changed
        let result = SavedSettings.patched(stored: stored, old: old, new: new)
        XCTAssertEqual(result.totalChords, 36)
        XCTAssertTrue(result.metronomeEnabled)
    }

    func testUnreadableStoredProfileIsNotOverwritten() {
        let decision = HabitStore.initialProfile(stored: nil, fileExists: true) { createDefaultProfile() }
        XCTAssertFalse(decision.save)
    }

    func testMissingProfileIsMigratedAndSaved() {
        var migrated = createDefaultProfile()
        migrated.totalXP = 70
        let decision = HabitStore.initialProfile(stored: nil, fileExists: false) { migrated }
        XCTAssertEqual(decision.profile.totalXP, 70)
        XCTAssertTrue(decision.save)
    }

    func testStoredProfileIsUsedAsIs() {
        var stored = createDefaultProfile()
        stored.totalXP = 300
        let decision = HabitStore.initialProfile(stored: stored, fileExists: true) { createDefaultProfile() }
        XCTAssertEqual(decision.profile.totalXP, 300)
        XCTAssertFalse(decision.save)
    }
}
