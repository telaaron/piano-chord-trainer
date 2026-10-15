import XCTest
import SwiftUI
@testable import JazzChords

final class KeyboardColorTests: XCTestCase {
    private func rgb(_ c: Color) -> [Int] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a].map { Int(($0 * 255).rounded()) }
    }

    // D (chromatic idx 2) held while the chord expects C, E♭, B♭: wrong.
    func testHeldWrongKeyIsRed() {
        let role = PianoKeyboard.role(chrIdx: 2, active: false, held: [2], expected: [0, 3, 10],
                                      selected: false, showInput: true, showMissing: false)
        XCTAssertEqual(role, .held(correct: false))
        XCTAssertEqual(rgb(PianoKeyboard.fill(for: role, isBlack: false, palette: .dark)), rgb(Palette.dark.action))
    }

    func testHeldCorrectKeyIsGold() {
        let role = PianoKeyboard.role(chrIdx: 12, active: true, held: [12], expected: [0, 3, 10],
                                      selected: false, showInput: true, showMissing: false)
        XCTAssertEqual(role, .held(correct: true))
        XCTAssertEqual(rgb(PianoKeyboard.fill(for: role, isBlack: false, palette: .light)), rgb(Palette.light.musicFill))
    }

    func testVoicingKeyIsGold() {
        let role = PianoKeyboard.role(chrIdx: 4, active: true, held: [], expected: [],
                                      selected: false, showInput: false, showMissing: false)
        XCTAssertEqual(role, .voicing)
        XCTAssertEqual(rgb(PianoKeyboard.fill(for: role, isBlack: false, palette: .dark)), rgb(Palette.dark.musicFill))
    }

    func testUnplayedVoicingKeyIsMissingAfterAttempt() {
        let role = PianoKeyboard.role(chrIdx: 5, active: true, held: [2], expected: [2, 5, 0],
                                      selected: false, showInput: true, showMissing: true)
        XCTAssertEqual(role, .missing)
    }

    func testIdleKeyKeepsKeyColour() {
        let role = PianoKeyboard.role(chrIdx: 7, active: false, held: [], expected: [],
                                      selected: false, showInput: false, showMissing: false)
        XCTAssertEqual(role, .idle)
        XCTAssertEqual(rgb(PianoKeyboard.fill(for: role, isBlack: true, palette: .dark)), rgb(Palette.dark.keyBlack))
    }
}
