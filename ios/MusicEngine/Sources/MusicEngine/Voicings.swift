// Voicing calculation – which notes to play for each voicing type.
// 1:1 port of src/lib/engine/voicings.ts.

import Foundation

public struct ChordWithNotes: Sendable, Equatable {
    /// Full display name, e.g. "C#Δ7"
    public let chord: String
    /// Root note, e.g. "C#"
    public let root: String
    /// Internal quality key, e.g. "Maj7"
    public let type: String
    /// All notes in root position
    public let notes: [String]
    /// Notes for the selected voicing
    public let voicing: [String]

    public init(chord: String, root: String, type: String, notes: [String], voicing: [String]) {
        self.chord = chord
        self.root = root
        self.type = type
        self.notes = notes
        self.voicing = voicing
    }
}

/// Compute chord notes from root + quality.
public func getChordNotes(_ root: String, _ quality: String, _ pref: AccidentalPreference) -> [String] {
    let rootSemi = noteToSemitone(root)
    guard let intervals = CHORD_INTERVALS[quality], rootSemi != -1 else { return [] }
    // 'both' = let chord theory drive the spelling (no doubled letters, quality-aware).
    if pref == .both { return spellChordNotes(root, intervals) }
    return intervals.map { getNoteName(rootSemi, $0, pref) }
}

/// Compute the 9th (natural) for a chord root. root + 14 semitones = root + 2 (mod 12).
private func getNinth(_ root: String, _ pref: AccidentalPreference) -> String {
    let rootSemi = noteToSemitone(root)
    if rootSemi == -1 { return "" }
    if pref == .both {
        let spelled = spellChordNotes(root, [0, 2])
        return spelled.count > 1 ? spelled[1] : ""
    }
    return getNoteName(rootSemi, 14, pref)
}

/// Rotate an array left by `n` positions.
private func rotateLeft<T>(_ arr: [T], _ n: Int) -> [T] {
    if arr.isEmpty { return arr }
    let k = ((n % arr.count) + arr.count) % arr.count
    return Array(arr[k...]) + Array(arr[..<k])
}

/// Select voicing notes from full chord notes.
/// For rootless voicings, pass root + pref so we can compute the 9th.
public func getVoicingNotes(
    _ allNotes: [String],
    _ voicing: VoicingType,
    _ root: String? = nil,
    _ pref: AccidentalPreference? = nil
) -> [String] {
    if allNotes.isEmpty { return [] }
    switch voicing {
    case .root:
        return allNotes
    case .shell:
        return allNotes.count >= 4 ? [allNotes[0], allNotes[1], allNotes[3]] : allNotes
    case .halfShell:
        return allNotes.count >= 4 ? [allNotes[1], allNotes[0], allNotes[3]] : allNotes
    case .full:
        return allNotes.count >= 4
            ? [allNotes[0], allNotes[allNotes.count - 1], allNotes[1], allNotes[2]]
            : allNotes

    case .rootlessA:
        // Type A: 3rd – 5th – 7th – 9th (Bill Evans style)
        if allNotes.count < 4 { return allNotes }
        let ninth: String = allNotes.count >= 5
            ? allNotes[4]
            : (root != nil && pref != nil ? getNinth(root!, pref!) : allNotes[1])
        return [allNotes[1], allNotes[2], allNotes[3], ninth]

    case .rootlessB:
        // Type B: 7th – 9th – 3rd – 5th
        if allNotes.count < 4 { return allNotes }
        let ninth: String = allNotes.count >= 5
            ? allNotes[4]
            : (root != nil && pref != nil ? getNinth(root!, pref!) : allNotes[1])
        return [allNotes[3], ninth, allNotes[1], allNotes[2]]

    case .inversion1:
        return rotateLeft(allNotes, 1)
    case .inversion2:
        return rotateLeft(allNotes, 2)
    case .inversion3:
        return allNotes.count >= 4 ? rotateLeft(allNotes, 3) : rotateLeft(allNotes, allNotes.count - 1)
    }
}

// ─── Interval name maps ────────────────────────────────────

/// Context-aware interval names per chord quality (semitone → label).
private let QUALITY_INTERVAL_NAMES: [String: [Int: String]] = [
    "Maj7": [0: "R", 4: "3", 7: "5", 11: "7"],
    "7": [0: "R", 4: "3", 7: "5", 10: "♭7"],
    "m7": [0: "R", 3: "♭3", 7: "5", 10: "♭7"],
    "6": [0: "R", 4: "3", 7: "5", 9: "6"],
    "m6": [0: "R", 3: "♭3", 7: "5", 9: "6"],
    "Maj9": [0: "R", 4: "3", 7: "5", 11: "7", 2: "9"],
    "9": [0: "R", 4: "3", 7: "5", 10: "♭7", 2: "9"],
    "m9": [0: "R", 3: "♭3", 7: "5", 10: "♭7", 2: "9"],
    "6/9": [0: "R", 4: "3", 7: "5", 9: "6", 2: "9"],
    "Maj7#11": [0: "R", 4: "3", 7: "5", 11: "7", 6: "♯11"],
    "7#9": [0: "R", 4: "3", 7: "5", 10: "♭7", 3: "♯9"],
    "7b9": [0: "R", 4: "3", 7: "5", 10: "♭7", 1: "♭9"],
    "m11": [0: "R", 3: "♭3", 7: "5", 10: "♭7", 2: "9", 5: "11"],
    "13": [0: "R", 4: "3", 7: "5", 10: "♭7", 2: "9", 9: "13"],
    "m7b5": [0: "R", 3: "♭3", 6: "♭5", 10: "♭7"],
    "dim7": [0: "R", 3: "♭3", 6: "♭5", 9: "°7"],
]

/// Generic fallback for intervals added by voicings (e.g. 9th in rootless).
private let GENERIC_INTERVAL: [Int: String] = [
    0: "R", 1: "♭9", 2: "9", 3: "♭3", 4: "3", 5: "11",
    6: "♯11", 7: "5", 8: "♯5", 9: "6", 10: "♭7", 11: "7",
]

/// Compute the interval labels for a set of voicing notes, aware of chord quality.
public func getVoicingIntervalLabels(_ voicingNotes: [String], _ root: String, _ quality: String) -> [String] {
    let rootSemi = noteToSemitone(root)
    if rootSemi == -1 { return voicingNotes }
    let qualityMap = QUALITY_INTERVAL_NAMES[quality] ?? [:]

    return voicingNotes.map { note in
        let semi = noteToSemitone(note)
        if semi == -1 { return "?" }
        let interval = ((semi - rootSemi) % 12 + 12) % 12
        return qualityMap[interval] ?? GENERIC_INTERVAL[interval] ?? "?"
    }
}

/// Compute the full chord formula (all intervals, not just voicing selection).
public func getChordFormula(_ quality: String) -> [String] {
    guard let intervals = CHORD_INTERVALS[quality] else { return [] }
    let qualityMap = QUALITY_INTERVAL_NAMES[quality] ?? [:]
    return intervals.map { iv in
        let pc = ((iv % 12) + 12) % 12
        return qualityMap[pc] ?? GENERIC_INTERVAL[pc] ?? "?"
    }
}

/// Format voicing notes for display: "C – E – B".
public func formatVoicing(_ chordData: ChordWithNotes, _ voicing: VoicingType, _ system: NotationSystem) -> String {
    let allNotes = chordData.notes.map { convertNoteName($0, system) }
    if allNotes.isEmpty { return "-" }

    switch voicing {
    case .root:
        return allNotes.joined(separator: " – ")
    case .shell:
        return allNotes.count >= 4
            ? "\(allNotes[0]) – \(allNotes[1]) – \(allNotes[3])"
            : allNotes.joined(separator: " – ")
    case .halfShell:
        return allNotes.count >= 4
            ? "\(allNotes[1]) – \(allNotes[0]) – \(allNotes[3])"
            : allNotes.joined(separator: " – ")
    case .full:
        return allNotes.count >= 4
            ? "\(allNotes[0]) – \(allNotes[allNotes.count - 1]) – \(allNotes[1]) – \(allNotes[2])"
            : allNotes.joined(separator: " – ")
    case .rootlessA, .rootlessB, .inversion1, .inversion2, .inversion3:
        // Use the actual voicing notes (already computed and stored).
        return chordData.voicing.map { convertNoteName($0, system) }.joined(separator: " – ")
    }
}

/// Reverse-lookup: notation display string → internal quality key.
public func displayToQuality(_ display: String, _ style: NotationStyle) -> String {
    let map = CHORD_NOTATIONS[style] ?? [:]
    for (key, value) in map where value == display {
        return key
    }
    return display
}

/// Get all unique valid pitch-class sets for a chord across common voicing types.
/// Used in Free Voice Leading mode to validate any voicing the player chooses.
public func getValidPCSets(_ root: String, _ quality: String, _ pref: AccidentalPreference) -> [Set<Int>] {
    let allNotes = getChordNotes(root, quality, pref)
    if allNotes.isEmpty { return [] }

    let voicingTypes: [VoicingType] = [.root, .shell, .halfShell, .full, .rootlessA, .rootlessB]
    var seen = Set<String>()
    var result: [Set<Int>] = []

    for vt in voicingTypes {
        let notes = getVoicingNotes(allNotes, vt, root, pref)
        let pcs = Set(notes.map { noteToSemitone($0) }.filter { $0 != -1 })
        // Deduplicate by sorted PC string
        let key = pcs.sorted().map(String.init).joined(separator: ",")
        if !seen.contains(key) {
            seen.insert(key)
            result.append(pcs)
        }
    }

    return result
}
