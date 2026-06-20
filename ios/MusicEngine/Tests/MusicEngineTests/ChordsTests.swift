// Ported from src/lib/engine/chords.test.ts.

import XCTest
@testable import MusicEngine

final class ChordsTests: XCTestCase {

    // MARK: CHORD_INTERVALS

    func testChordIntervals() {
        XCTAssertEqual(CHORD_INTERVALS["Maj7"], [0, 4, 7, 11])
        XCTAssertEqual(CHORD_INTERVALS["m7"], [0, 3, 7, 10])
        XCTAssertEqual(CHORD_INTERVALS["7"], [0, 4, 7, 10])
        XCTAssertEqual(CHORD_INTERVALS["m7b5"], [0, 3, 6, 10])
        XCTAssertEqual(CHORD_INTERVALS["dim7"], [0, 3, 6, 9])
    }

    func testHas16ChordTypes() {
        XCTAssertEqual(CHORD_INTERVALS.count, 16)
    }

    // MARK: CHORDS_BY_DIFFICULTY

    func testDifficultyCounts() {
        XCTAssertEqual(CHORDS_BY_DIFFICULTY[.beginner]?.count, 5)
        XCTAssertEqual(CHORDS_BY_DIFFICULTY[.intermediate]?.count, 9)
        XCTAssertEqual(CHORDS_BY_DIFFICULTY[.advanced]?.count, 15)
    }

    func testAdvancedIncludesDim7AndM7b5() {
        let names = CHORDS_BY_DIFFICULTY[.advanced]!.map { $0.name }
        XCTAssertTrue(names.contains("dim7"))
        XCTAssertTrue(names.contains("m7b5"))
    }

    func testEveryChordHasIntervals() {
        for (_, chords) in CHORDS_BY_DIFFICULTY {
            for chord in chords {
                let found = CHORD_INTERVALS[chord.name] ?? CHORD_INTERVALS[chord.display]
                XCTAssertNotNil(found, "no intervals for \(chord.name)/\(chord.display)")
            }
        }
    }

    // MARK: CHORD_NOTATIONS

    func testNotationStyles() {
        XCTAssertEqual(CHORD_NOTATIONS[.standard]?["dim7"], "dim7")
        XCTAssertEqual(CHORD_NOTATIONS[.symbols]?["dim7"], "°7")
        XCTAssertEqual(CHORD_NOTATIONS[.short]?["dim7"], "dim7")
        XCTAssertEqual(CHORD_NOTATIONS[.symbols]?["Maj7"], "Δ7")
        XCTAssertEqual(CHORD_NOTATIONS[.symbols]?["m7b5"], "ø7")
    }

    func testAllStylesShareKeys() {
        let std = Set(CHORD_NOTATIONS[.standard]!.keys)
        let sym = Set(CHORD_NOTATIONS[.symbols]!.keys)
        let sht = Set(CHORD_NOTATIONS[.short]!.keys)
        XCTAssertEqual(std, sym)
        XCTAssertEqual(std, sht)
    }

    // MARK: VOICING_LABELS

    func testVoicingLabels() {
        XCTAssertEqual(VOICING_LABELS.count, 9)
        XCTAssertEqual(VOICING_LABELS[.inversion1], "1st Inversion")
        XCTAssertEqual(VOICING_LABELS[.shell], "Shell Voicing")
    }
}
