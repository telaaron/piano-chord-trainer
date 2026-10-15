import XCTest
@testable import JazzChords

final class FunctionGridTests: XCTestCase {
    private let labels = ["Grundton", "Terz", "Septime"]

    func testOpenBeforeResult() {
        let t = FunctionGrid.tones(voicingNotes: ["D", "F", "C"], labels: labels,
                                   held: [], showResult: false)
        XCTAssertEqual(t.map(\.state), [.open, .open, .open])
    }

    func testMissingThird() {
        let t = FunctionGrid.tones(voicingNotes: ["D", "F", "C"], labels: labels,
                                   held: [50, 60], showResult: true)
        XCTAssertEqual(t.map(\.state), [.ok, .missing, .ok])
    }

    func testEnharmonicHeld() {
        // E♭ written with the real glyph; D♯ (MIDI 63) held must count for it.
        let t = FunctionGrid.tones(voicingNotes: ["C", "E♭", "B♭"], labels: labels,
                                   held: [60, 63, 70], showResult: true)
        XCTAssertEqual(t.map(\.state), [.ok, .ok, .ok])
    }

    func testCarriesNoteAndFunction() {
        let t = FunctionGrid.tones(voicingNotes: ["D", "F", "C"], labels: labels,
                                   held: [], showResult: false)
        XCTAssertEqual(t.map(\.note), ["D", "F", "C"])
        XCTAssertEqual(t.map(\.function), labels)
    }

    // After a graded tap-guess the store leaves tap mode; the grid must still
    // judge the guess, not the (empty) live input.
    func testGridUsesTapGuessWithoutLiveInput() {
        XCTAssertEqual(FunctionGrid.held(inputActive: false, heldNotes: [], tapGuess: [0, 4]), [60, 64])
        XCTAssertEqual(FunctionGrid.held(inputActive: true, heldNotes: [62], tapGuess: [0]), [62])
    }

    func testRepeatedToneHasUniqueIDs() {
        let tones = FunctionGrid.tones(voicingNotes: ["C", "C"], labels: ["R", "R"], held: [], showResult: false)
        XCTAssertEqual(Set(tones.map(\.id)).count, 2)
    }

    func testThirteenthIsNotSixth() {
        XCTAssertNotEqual(Strings.intervalFunction("13"), Strings.intervalFunction("6"))
    }
}
