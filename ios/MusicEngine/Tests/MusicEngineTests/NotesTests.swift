// Ported from src/lib/engine/notes.test.ts — must stay green to guarantee parity.

import XCTest
@testable import MusicEngine

final class NotesTests: XCTestCase {

    private func sp(_ root: String, _ quality: String) -> [String] {
        spellChordNotes(root, CHORD_INTERVALS[quality]!)
    }

    // MARK: spellChordNotes (theory-correct, no doubled letters)

    func testSpellsCm7WithFlats() {
        XCTAssertEqual(sp("C", "m7"), ["C", "Eb", "G", "Bb"])
    }

    func testSpellsDominantFlat7AsBbInC7() {
        XCTAssertEqual(sp("C", "7"), ["C", "E", "G", "Bb"])
    }

    func testKeepsCmaj7Natural() {
        XCTAssertEqual(sp("C", "Maj7"), ["C", "E", "G", "B"])
    }

    func testUsesSharpsForSharpKeyDominantFSharp7() {
        XCTAssertEqual(sp("F#", "7"), ["F#", "A#", "C#", "E"])
    }

    func testNeverProducesUnresolvableNote() {
        let roots = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
        for root in roots {
            for quality in CHORD_INTERVALS.keys {
                for n in sp(root, quality) {
                    XCTAssertGreaterThanOrEqual(noteToSemitone(n), 0, "\(n) in \(root)\(quality)")
                }
            }
        }
    }

    // MARK: NOTES_SHARPS / NOTES_FLATS

    func testHas12SharpsNotes() { XCTAssertEqual(NOTES_SHARPS.count, 12) }
    func testHas12FlatsNotes() { XCTAssertEqual(NOTES_FLATS.count, 12) }
    func testStartsWithC() {
        XCTAssertEqual(NOTES_SHARPS[0], "C")
        XCTAssertEqual(NOTES_FLATS[0], "C")
    }

    // MARK: ENHARMONIC_MAP

    func testMapsCSharpToDbAndBack() {
        XCTAssertEqual(ENHARMONIC_MAP["C#"], "Db")
        XCTAssertEqual(ENHARMONIC_MAP["Db"], "C#")
    }
    func testMapsBbToASharpAndBack() {
        XCTAssertEqual(ENHARMONIC_MAP["Bb"], "A#")
        XCTAssertEqual(ENHARMONIC_MAP["A#"], "Bb")
    }

    // MARK: noteToSemitone

    func testNoteToSemitone() {
        XCTAssertEqual(noteToSemitone("C"), 0)
        XCTAssertEqual(noteToSemitone("E"), 4)
        XCTAssertEqual(noteToSemitone("G"), 7)
        XCTAssertEqual(noteToSemitone("Bb"), 10)
        XCTAssertEqual(noteToSemitone("A#"), 10)
        XCTAssertEqual(noteToSemitone("Gb"), 6)
        XCTAssertEqual(noteToSemitone("X"), -1)
    }

    // MARK: getNoteName

    func testGetNoteName() {
        XCTAssertEqual(getNoteName(0, 4, .sharps), "E")
        XCTAssertEqual(getNoteName(0, 7, .sharps), "G")
        XCTAssertEqual(getNoteName(0, 10, .flats), "Bb")
        XCTAssertEqual(getNoteName(0, 12, .sharps), "C")
        XCTAssertEqual(getNoteName(2, 4, .both), "F#")
        XCTAssertEqual(getNoteName(10, 5, .both), "Eb")
        XCTAssertEqual(getNoteName(4, 4, .both), "G#")
    }

    // MARK: getNoteArray

    func testGetNoteArray() {
        XCTAssertEqual(getNoteArray(.flats), NOTES_FLATS)
        XCTAssertEqual(getNoteArray(.sharps), NOTES_SHARPS)
        XCTAssertEqual(getNoteArray(.both), NOTES_SHARPS)
    }

    // MARK: getNotePool

    func testGetNotePool() {
        XCTAssertEqual(getNotePool(.sharps).count, 12)
        XCTAssertEqual(getNotePool(.flats).count, 12)
        XCTAssertGreaterThan(getNotePool(.both).count, 12)
    }

    // MARK: convertNoteName

    func testConvertNoteName() {
        XCTAssertEqual(convertNoteName("B", .german), "H")
        XCTAssertEqual(convertNoteName("Bb", .german), "B")
        XCTAssertEqual(convertNoteName("C", .german), "C")
        XCTAssertEqual(convertNoteName("F#", .german), "F#")
        XCTAssertEqual(convertNoteName("B", .international), "B")
        XCTAssertEqual(convertNoteName("Bb", .international), "Bb")
    }

    // MARK: convertChordNotation

    func testConvertChordNotation() {
        XCTAssertEqual(convertChordNotation("BbMaj7", .german), "BMaj7")
        XCTAssertEqual(convertChordNotation("BMaj7", .german), "HMaj7")
        XCTAssertEqual(convertChordNotation("BbMaj7", .international), "BbMaj7")
        XCTAssertEqual(convertChordNotation("BMaj7", .international), "BMaj7")
    }
}
