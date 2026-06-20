// Tests for chord matching (MIDI/mic). Mirrors midi.ts checkChord behavior.

import XCTest
@testable import MusicEngine

final class ChordMatchTests: XCTestCase {

    // Dm7 shell = [D, F, C] → pitch classes 2, 5, 0.

    func testExactMatch() {
        // D3=50, F3=53, C4=60 → pcs 2,5,0
        let r = ChordMatch.checkChord(["D", "F", "C"], activeMidi: [50, 53, 60])
        XCTAssertTrue(r.correct)
        XCTAssertEqual(r.accuracy, 1.0)
    }

    func testMissingNote() {
        let r = ChordMatch.checkChord(["D", "F", "C"], activeMidi: [50, 53])
        XCTAssertFalse(r.correct)
        XCTAssertTrue(r.missing.contains(0)) // C missing
        XCTAssertEqual(r.accuracy, 2.0 / 3.0, accuracy: 0.0001)
    }

    func testStrictRejectsExtra() {
        // extra E (pc 4)
        let r = ChordMatch.checkChord(["D", "F", "C"], activeMidi: [50, 53, 60, 64])
        XCTAssertFalse(r.correct)
        XCTAssertTrue(r.extra.contains(4))
    }

    func testLenientToleratesExtra() {
        let r = ChordMatch.checkChordLenient(["D", "F", "C"], activeMidi: [50, 53, 60, 64])
        XCTAssertTrue(r.correct)
    }

    func testOctaveAgnostic() {
        // all an octave up: D4=62, F4=65, C5=72
        let r = ChordMatch.checkChordLenient(["D", "F", "C"], activeMidi: [62, 65, 72])
        XCTAssertTrue(r.correct)
    }

    func testBassAwareCorrectBass() {
        // 1st inversion of C: bass = E. Notes E,G,B,C with lowest = E(64).
        let r = ChordMatch.checkChordWithBass(["E", "G", "B", "C"], expectedBassNote: "E", activeMidi: [64, 67, 71, 72])
        XCTAssertTrue(r.correct)
    }

    func testBassAwareWrongBass() {
        // Same notes but C in the bass (60) → wrong inversion.
        let r = ChordMatch.checkChordWithBass(["E", "G", "B", "C"], expectedBassNote: "E", activeMidi: [60, 64, 67, 71])
        XCTAssertFalse(r.correct)
    }
}
