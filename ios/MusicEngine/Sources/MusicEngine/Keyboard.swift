// Keyboard helpers – map chord notes to keyboard key indices.
// 1:1 port of src/lib/engine/keyboard.ts.

import Foundation

public enum OctaveCount: Int, Sendable {
    case two = 2
    case three = 3
}

public let WHITE_KEY_COUNT = 14
public let CHROMATIC_COUNT = 24

/// White key chromatic indices: C=0, D=2, E=4, F=5, G=7, A=9, B=11
public let WHITE_KEY_CHROMATIC = [0, 2, 4, 5, 7, 9, 11]

/// Get chromatic index for white key i (0-based).
public func whiteKeyChromaticIndex(_ i: Int) -> Int {
    let octave = i / 7
    let noteInOctave = WHITE_KEY_CHROMATIC[i % 7]
    return octave * 12 + noteInOctave
}

public struct BlackKey: Sendable, Equatable {
    public let idx: Int
    public let pos: Int
}

/// Generate black key layout for a given number of octaves.
public func generateBlackKeys(_ octaves: OctaveCount) -> [BlackKey] {
    let perOctave: [(offset: Int, whitePos: Int)] = [
        (1, 1), (3, 2), (6, 4), (8, 5), (10, 6),
    ]
    var keys: [BlackKey] = []
    for oct in 0..<octaves.rawValue {
        for k in perOctave {
            keys.append(BlackKey(idx: oct * 12 + k.offset, pos: oct * 7 + k.whitePos))
        }
    }
    return keys
}

private func noteToPitchClass(_ note: String, _ baseNotes: [String]) -> Int {
    if let idx = baseNotes.firstIndex(of: note) { return idx }
    if let enh = ENHARMONIC_MAP[note], let idx = baseNotes.firstIndex(of: enh) { return idx }
    return -1
}

public struct KeyboardLayout: Sendable, Equatable {
    public let activeIndices: Set<Int>
    public let octaves: OctaveCount
    public init(activeIndices: Set<Int>, octaves: OctaveCount) {
        self.activeIndices = activeIndices
        self.octaves = octaves
    }
}

/// Place pitch classes in ascending order on the keyboard, each above the previous.
private func placeAscending(_ pitchClasses: [Int]) -> [Int] {
    var indices: [Int] = []
    var prevIdx = -1
    for pc in pitchClasses {
        var kbIdx = pc
        if prevIdx != -1 {
            while kbIdx <= prevIdx { kbIdx += 12 }
        }
        indices.append(kbIdx)
        prevIdx = kbIdx
    }
    return indices
}

/// Build the set of chromatic indices and determine keyboard size.
/// ONLY highlights notes present in chordData.voicing.
public func getKeyboardLayout(_ chordData: ChordWithNotes, _ pref: AccidentalPreference) -> KeyboardLayout {
    let baseNotes = pref == .flats ? NOTES_FLATS : NOTES_SHARPS
    let voicingNotes = chordData.voicing

    if voicingNotes.isEmpty { return KeyboardLayout(activeIndices: [], octaves: .two) }

    var pitchClasses: [Int] = []
    var seen = Set<Int>()
    for note in voicingNotes {
        let pc = noteToPitchClass(note, baseNotes)
        if pc != -1, !seen.contains(pc) {
            pitchClasses.append(pc)
            seen.insert(pc)
        }
    }

    if pitchClasses.isEmpty { return KeyboardLayout(activeIndices: [], octaves: .two) }

    let indices = placeAscending(pitchClasses)

    if indices.allSatisfy({ $0 >= 0 && $0 < 24 }) {
        return KeyboardLayout(activeIndices: Set(indices), octaves: .two)
    }
    if indices.allSatisfy({ $0 >= 0 && $0 < 36 }) {
        return KeyboardLayout(activeIndices: Set(indices), octaves: .three)
    }

    let sortedPCs = pitchClasses.sorted()
    let compactIndices = placeAscending(sortedPCs)
    let fits3 = compactIndices.allSatisfy { $0 >= 0 && $0 < 36 }
    let octaves: OctaveCount = (fits3 && compactIndices.contains { $0 >= 24 }) ? .three : .two
    let maxIdx = octaves == .three ? 36 : 24

    return KeyboardLayout(
        activeIndices: Set(compactIndices.filter { $0 >= 0 && $0 < maxIdx }),
        octaves: octaves
    )
}

/// Check if a chromatic index matches the root note AND the root is in the voicing.
public func isRootIndex(_ chromaticIndex: Int, _ root: String, _ voicing: [String]) -> Bool {
    let rootSemi = noteToSemitone(root)
    if rootSemi == -1 { return false }
    if (chromaticIndex % 12) != rootSemi { return false }
    return voicing.contains { noteToSemitone($0) == rootSemi }
}

/// Determine the keyboard octave count needed to display ALL chords in a session.
public func computeSessionOctaves(_ allChords: [ChordWithNotes], _ pref: AccidentalPreference) -> OctaveCount {
    let baseNotes = pref == .flats ? NOTES_FLATS : NOTES_SHARPS

    for chordData in allChords {
        var pitchClasses: [Int] = []
        var seen = Set<Int>()
        for note in chordData.voicing {
            let pc = noteToPitchClass(note, baseNotes)
            if pc != -1, !seen.contains(pc) {
                pitchClasses.append(pc)
                seen.insert(pc)
            }
        }
        if pitchClasses.isEmpty { continue }
        let indices = placeAscending(pitchClasses)
        if indices.contains(where: { $0 >= 24 }) {
            return .three
        }
    }
    return .two
}
