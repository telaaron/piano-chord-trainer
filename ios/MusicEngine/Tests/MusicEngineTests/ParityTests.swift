// Golden-master parity check: expected values captured by running the live
// TypeScript engine (src/lib/engine/*) under tsx. If the Swift port ever drifts
// from the web engine, these fail.

import XCTest
@testable import MusicEngine

final class ParityTests: XCTestCase {

    /// `<root><quality>` → comma-joined spelled notes, from `spellChordNotes`.
    private let spellingGolden: [String: String] = [
        "CMaj7": "C,E,G,B", "Cm7": "C,Eb,G,Bb", "C7": "C,E,G,Bb",
        "Cdim7": "C,Eb,Gb,A", "Cm7b5": "C,Eb,Gb,Bb", "C13": "C,E,G,Bb,D,A",
        "DbMaj7": "Db,F,Ab,C", "Dbm7": "Db,Fb,Ab,Cb", "Db7": "Db,F,Ab,Cb",
        "Dbdim7": "Db,Fb,G,Bb", "Dbm7b5": "Db,Fb,G,Cb", "Db13": "Db,F,Ab,Cb,Eb,Bb",
        "F#Maj7": "F#,A#,C#,E#", "F#m7": "F#,A,C#,E", "F#7": "F#,A#,C#,E",
        "F#dim7": "F#,A,C,D#", "F#m7b5": "F#,A,C,E", "F#13": "F#,A#,C#,E,G#,D#",
        "BbMaj7": "Bb,D,F,A", "Bbm7": "Bb,Db,F,Ab", "Bb7": "Bb,D,F,Ab",
        "Bbdim7": "Bb,Db,Fb,G", "Bbm7b5": "Bb,Db,Fb,Ab", "Bb13": "Bb,D,F,Ab,C,G",
        "AbMaj7": "Ab,C,Eb,G", "Abm7": "Ab,Cb,Eb,Gb", "Ab7": "Ab,C,Eb,Gb",
        "Abdim7": "Ab,Cb,D,F", "Abm7b5": "Ab,Cb,D,Gb", "Ab13": "Ab,C,Eb,Gb,Bb,F",
    ]

    func testSpellingMatchesTypeScript() {
        for root in ["C", "Db", "F#", "Bb", "Ab"] {
            for q in ["Maj7", "m7", "7", "dim7", "m7b5", "13"] {
                let got = spellChordNotes(root, CHORD_INTERVALS[q]!).joined(separator: ",")
                let expected = spellingGolden["\(root)\(q)"]!
                XCTAssertEqual(got, expected, "spelling drift for \(root)\(q)")
            }
        }
    }

    func testRootlessAMatchesTypeScript() {
        let got = getVoicingNotes(getChordNotes("C", "Maj9", .both), .rootlessA).joined(separator: ",")
        XCTAssertEqual(got, "E,G,B,D")
    }

    func testTwoFiveOneMatchesTypeScript() {
        let got = generateProgression(.twoFiveOne, .both, .standard, 0, nil)
            .chords.prefix(6).map { $0.display }.joined(separator: " ")
        XCTAssertEqual(got, "Dm7 G7 CMaj7 Gm7 C7 FMaj7")
    }
}
