// Chord matching — shared by MIDI and microphone input. Octave-agnostic
// (pitch-class) comparison. 1:1 port of the checkChord family duplicated in
// src/lib/services/midi.ts and audio-input.ts.

import Foundation

public struct ChordMatchResult: Sendable, Equatable {
    /// All expected notes are held (possibly in any octave) and none extra.
    public let correct: Bool
    /// Semitones expected but not held.
    public let missing: [Int]
    /// Semitones held but not in the chord.
    public let extra: [Int]
    /// 0–1 ratio of expected notes held.
    public let accuracy: Double

    public init(correct: Bool, missing: [Int], extra: [Int], accuracy: Double) {
        self.correct = correct; self.missing = missing; self.extra = extra; self.accuracy = accuracy
    }
}

public enum ChordMatch {

    /// Strict: every expected pitch class held, nothing extra.
    public static func checkChord(_ expectedNotes: [String], activeMidi: Set<Int>) -> ChordMatchResult {
        var expected = Set<Int>()
        for note in expectedNotes {
            let st = noteToSemitone(note)
            if st != -1 { expected.insert(st) }
        }
        let active = Set(activeMidi.map { ((($0 % 12) + 12) % 12) })

        var missing: [Int] = []
        var matched: [Int] = []
        for e in expected {
            if active.contains(e) { matched.append(e) } else { missing.append(e) }
        }
        var extra: [Int] = []
        for a in active where !expected.contains(a) { extra.append(a) }

        let total = expected.count
        let accuracy = total > 0 ? Double(matched.count) / Double(total) : 0
        return ChordMatchResult(correct: missing.isEmpty && extra.isEmpty, missing: missing, extra: extra, accuracy: accuracy)
    }

    /// Lenient: all expected held, extra notes tolerated (extensions/doublings/overtones).
    public static func checkChordLenient(_ expectedNotes: [String], activeMidi: Set<Int>) -> ChordMatchResult {
        let r = checkChord(expectedNotes, activeMidi: activeMidi)
        return ChordMatchResult(correct: r.missing.isEmpty, missing: r.missing, extra: r.extra, accuracy: r.accuracy)
    }

    /// Inversion-aware: lenient + the lowest held note must equal the expected bass pitch class.
    public static func checkChordWithBass(_ expectedNotes: [String], expectedBassNote: String, activeMidi: Set<Int>) -> ChordMatchResult {
        let r = checkChordLenient(expectedNotes, activeMidi: activeMidi)
        if !r.correct || activeMidi.isEmpty { return r }

        let lowestMidi = activeMidi.min() ?? Int.max
        let lowestPc = ((lowestMidi % 12) + 12) % 12
        let expectedBassPc = noteToSemitone(expectedBassNote)

        if expectedBassPc == -1 || lowestPc == expectedBassPc { return r }
        return ChordMatchResult(correct: false, missing: r.missing, extra: r.extra, accuracy: r.accuracy)
    }
}
