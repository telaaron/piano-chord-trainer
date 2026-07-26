// Note arrays and enharmonic mapping.
// 1:1 port of src/lib/engine/notes.ts — keep behavior identical to the web engine.

import Foundation

public let NOTES_SHARPS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
public let NOTES_FLATS = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

public enum AccidentalPreference: String, Sendable, CaseIterable, Codable {
    case sharps
    case flats
    case both
}

public enum NotationSystem: String, Sendable, CaseIterable, Codable {
    case international
    case german
}

/// Map between enharmonic equivalents (same semitone, different spelling).
public let ENHARMONIC_MAP: [String: String] = [
    "C#": "Db", "Db": "C#",
    "D#": "Eb", "Eb": "D#",
    "F#": "Gb", "Gb": "F#",
    "G#": "Ab", "Ab": "G#",
    "A#": "Bb", "Bb": "A#",
    // White-key accidentals — produced by theory-correct chord spelling
    // (e.g. Abm7b5 → Cb). Map to their natural equivalent so the keyboard
    // and semitone lookup never break.
    "Cb": "B", "B#": "C", "Fb": "E", "E#": "F",
]

/// Get the preferred note array based on accidental preference.
public func getNoteArray(_ pref: AccidentalPreference) -> [String] {
    switch pref {
    case .flats: return NOTES_FLATS
    case .sharps: return NOTES_SHARPS
    // "both" – use sharps as canonical, user sees mixed during generation
    case .both: return NOTES_SHARPS
    }
}

/// Get note pool for chord generation.
public func getNotePool(_ pref: AccidentalPreference) -> [String] {
    switch pref {
    case .sharps: return NOTES_SHARPS
    case .flats: return NOTES_FLATS
    case .both:
        // Both: all unique notes including enharmonics
        return [
            "C", "C#", "Db", "D", "D#", "Eb", "E", "F",
            "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B",
        ]
    }
}

/// Find semitone index (0–11) for a note name. Returns -1 if unknown.
public func noteToSemitone(_ note: String) -> Int {
    if let idx = NOTES_SHARPS.firstIndex(of: note) { return idx }
    if let idx = NOTES_FLATS.firstIndex(of: note) { return idx }
    // Try enharmonic
    if let enh = ENHARMONIC_MAP[note], let idx = NOTES_SHARPS.firstIndex(of: enh) {
        return idx
    }
    return -1
}

/// Sharp keys: C(0), D(2), E(4), F#/Gb(6), G(7), A(9), B(11)
/// Flat keys:  Db(1), Eb(3), F(5), Ab(8), Bb(10)
private let FLAT_ROOTS: Set<Int> = [1, 3, 5, 8, 10]

public func usesSharps(_ semitone: Int) -> Bool {
    return !FLAT_ROOTS.contains(((semitone % 12) + 12) % 12)
}

// ─── Theory-correct chord spelling ──────────────────────────────────────────
private let LETTERS = ["C", "D", "E", "F", "G", "A", "B"]
private let LETTER_SEMITONES: [String: Int] = [
    "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11,
]

/// Map a chromatic interval (semitones from root) to its diatonic degree
/// (0-based letter step).
private let INTERVAL_TO_LETTER_STEP: [Int: Int] = [
    0: 0,   // root
    1: 1,   // ♭9 / ♭2  → a second
    2: 1,   // 9 / 2
    3: 2,   // ♭3       → a third
    4: 2,   // 3
    5: 3,   // 11 / 4   → a fourth
    6: 3,   // ♯11 / ♯4 → a fourth (sharpened); diminished 5th handled per-chord below
    7: 4,   // 5
    8: 5,   // ♭13 / ♭6 → a sixth
    9: 5,   // 13 / 6
    10: 6,  // ♭7       → a seventh
    11: 6,  // 7
]

/// Spell one note at the given letter step, choosing the smallest accidental.
private func spellAt(
    _ rootLetterIndex: Int,
    _ rootSemitone: Int,
    _ letterStep: Int,
    _ targetSemitoneFromRoot: Int
) -> String {
    let letterIdx = (rootLetterIndex + letterStep) % 7
    let letter = LETTERS[letterIdx]
    let targetPc = (rootSemitone + targetSemitoneFromRoot) % 12
    let naturalPc = LETTER_SEMITONES[letter]!
    // Smallest signed accidental to move from the natural letter pitch to target.
    var diff = ((targetPc - naturalPc) % 12 + 12) % 12
    if diff > 6 { diff -= 12 } // prefer flats over many sharps (e.g. -1 not +11)
    // Avoid double accidentals (Ebb, F##) — fall back to the plain flat name.
    if abs(diff) > 1 {
        return NOTES_FLATS[targetPc]
    }
    let acc = diff > 0 ? String(repeating: "#", count: diff) : String(repeating: "b", count: -diff)
    return letter + acc
}

/// Spell a chord's notes with theoretically correct accidentals, so the same
/// letter is never used twice and quality drives the spelling.
///   Cm7 → C, Eb, G, Bb   (not C, D#, G, A#)
public func spellChordNotes(_ root: String, _ intervals: [Int]) -> [String] {
    let rootSemi = noteToSemitone(root)
    if rootSemi == -1 { return [] }
    let rootLetter = String(root.prefix(1)).uppercased()
    let rootLetterIndex = LETTERS.firstIndex(of: rootLetter)
    let baseIndex = rootLetterIndex ?? 0

    return intervals.map { iv in
        let pc = ((iv % 12) + 12) % 12
        var step = INTERVAL_TO_LETTER_STEP[pc] ?? 0
        // Diminished 5th (6 semis) inside a chord with no natural 4th/11th reads
        // as a *fifth* (♭5), not a ♯11.
        if pc == 6, !intervals.contains(where: { (($0 % 12) + 12) % 12 == 5 }) {
            step = 4 // a fifth
        }
        return spellAt(baseIndex, rootSemi, step, iv % 12)
    }
}

/// Get note name at a given semitone offset from root.
public func getNoteName(_ rootSemitone: Int, _ interval: Int, _ pref: AccidentalPreference) -> String {
    let index = (rootSemitone + interval) % 12
    switch pref {
    case .sharps: return NOTES_SHARPS[index]
    case .flats: return NOTES_FLATS[index]
    case .both:
        // 'both': choose sharps/flats based on the chord root's key context
        return usesSharps(rootSemitone) ? NOTES_SHARPS[index] : NOTES_FLATS[index]
    }
}

// MARK: - Pitched notes (with octave)

/// A note name WITH its octave, e.g. "Bb4" — what a synth needs to sound the
/// right pitch.
///
/// `getNoteName` returns a pitch class, which is correct for naming a chord
/// tone but cannot express direction: C→B is a major seventh UP or a minor
/// second DOWN, and the name alone does not say which. Ear training has to say
/// which, so intervals are built from an absolute semitone offset here.
///
/// 1:1 port of `getPitchedNote` in `src/lib/engine/notes.ts`.
///
/// - Parameters:
///   - rootSemitone: pitch class of the starting note (0 = C)
///   - interval: signed semitone distance; negative descends
///   - octave: octave of the starting note in scientific pitch notation
public func getPitchedNote(
    _ rootSemitone: Int,
    _ interval: Int,
    _ pref: AccidentalPreference,
    octave: Int = 4
) -> String {
    let abs = rootSemitone + interval
    // Floor-divide so descending intervals cross the octave boundary correctly:
    // C4 down a minor second is B3, not B4. Swift's / truncates toward zero,
    // so a plain abs / 12 would round -1 up to 0 and keep the note in octave 4.
    let oct = octave + Int(floor(Double(abs) / 12.0))
    let index = ((abs % 12) + 12) % 12
    let names: [String]
    switch pref {
    case .sharps: names = NOTES_SHARPS
    case .flats: names = NOTES_FLATS
    case .both: names = usesSharps(rootSemitone) ? NOTES_SHARPS : NOTES_FLATS
    }
    return "\(names[index])\(oct)"
}

/// Convert a note name between international and German notation.
public func convertNoteName(_ note: String, _ system: NotationSystem) -> String {
    if system == .german {
        if note == "B" { return "H" }
        if note == "Bb" { return "B" }
    }
    return note
}

/// Convert a full chord name (e.g. "BbMaj7") to German notation.
public func convertChordNotation(_ chordName: String, _ system: NotationSystem) -> String {
    if system != .german { return chordName }
    if chordName.hasPrefix("Bb") { return "B" + chordName.dropFirst(2) }
    if chordName.hasPrefix("B") && !chordName.hasPrefix("Bb") { return "H" + chordName.dropFirst(1) }
    return chordName
}
