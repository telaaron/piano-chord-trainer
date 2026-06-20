// Ported from src/lib/engine/voicings.test.ts.

import XCTest
@testable import MusicEngine

final class VoicingsTests: XCTestCase {

    // MARK: getChordNotes

    func testGetChordNotes() {
        XCTAssertEqual(getChordNotes("C", "Maj7", .sharps), ["C", "E", "G", "B"])
        XCTAssertEqual(getChordNotes("D", "m7", .flats), ["D", "F", "A", "C"])
        XCTAssertEqual(getChordNotes("G", "7", .sharps), ["G", "B", "D", "F"])
        XCTAssertEqual(getChordNotes("C", "dim7", .flats), ["C", "Eb", "Gb", "A"])
        XCTAssertEqual(getChordNotes("C", "m7b5", .flats), ["C", "Eb", "Gb", "Bb"])
        XCTAssertEqual(getChordNotes("C", "unknown", .sharps), [])
        XCTAssertEqual(getChordNotes("X", "Maj7", .sharps), [])
    }

    // MARK: getVoicingNotes

    func testRoot() {
        XCTAssertEqual(getVoicingNotes(["C", "E", "G", "B"], .root), ["C", "E", "G", "B"])
    }

    func testShell() {
        XCTAssertEqual(getVoicingNotes(["C", "E", "G", "B"], .shell), ["C", "E", "B"])
        XCTAssertEqual(getVoicingNotes(["C", "E", "G"], .shell), ["C", "E", "G"])
    }

    func testHalfShell() {
        XCTAssertEqual(getVoicingNotes(["C", "E", "G", "B"], .halfShell), ["E", "C", "B"])
    }

    func testFull() {
        XCTAssertEqual(getVoicingNotes(["C", "E", "G", "B"], .full), ["C", "B", "E", "G"])
    }

    func testInversions() {
        XCTAssertEqual(getVoicingNotes(["C", "E", "G", "B"], .inversion1), ["E", "G", "B", "C"])
        XCTAssertEqual(getVoicingNotes(["C", "E", "G", "B"], .inversion2), ["G", "B", "C", "E"])
        XCTAssertEqual(getVoicingNotes(["C", "E", "G", "B"], .inversion3), ["B", "C", "E", "G"])
    }

    func testRootlessA() {
        XCTAssertEqual(getVoicingNotes(["C", "E", "G", "B", "D"], .rootlessA), ["E", "G", "B", "D"])
    }

    func testRootlessB() {
        XCTAssertEqual(getVoicingNotes(["C", "E", "G", "B", "D"], .rootlessB), ["B", "D", "E", "G"])
    }

    func testEdgeCases() {
        XCTAssertEqual(getVoicingNotes([], .root), [])
        XCTAssertEqual(getVoicingNotes(["C", "E", "G"], .inversion3).count, 3)
    }
}
