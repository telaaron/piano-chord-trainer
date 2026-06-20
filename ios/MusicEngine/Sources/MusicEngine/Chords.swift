// Chord definitions, intervals, notation styles, difficulty levels.
// 1:1 port of src/lib/engine/chords.ts.

import Foundation

public enum Difficulty: String, Sendable, CaseIterable, Codable {
    case beginner
    case intermediate
    case advanced
}

public enum NotationStyle: String, Sendable, CaseIterable, Codable {
    case standard
    case symbols
    case short
}

public enum VoicingType: String, Sendable, CaseIterable, Codable {
    case root
    case shell
    case halfShell = "half-shell"
    case full
    case rootlessA = "rootless-a"
    case rootlessB = "rootless-b"
    case inversion1 = "inversion-1"
    case inversion2 = "inversion-2"
    case inversion3 = "inversion-3"
}

public enum DisplayMode: String, Sendable, CaseIterable, Codable {
    case off
    case always
    case verify
}

public struct ChordType: Sendable, Equatable {
    /// Internal key, e.g. "maj7"
    public let name: String
    /// Display name used for lookup, e.g. "Maj7"
    public let display: String

    public init(name: String, display: String) {
        self.name = name
        self.display = display
    }
}

/// Chord types grouped by difficulty.
public let CHORDS_BY_DIFFICULTY: [Difficulty: [ChordType]] = [
    .beginner: [
        ChordType(name: "maj7", display: "Maj7"),
        ChordType(name: "7", display: "7"),
        ChordType(name: "m7", display: "m7"),
        ChordType(name: "6", display: "6"),
        ChordType(name: "m6", display: "m6"),
    ],
    .intermediate: [
        ChordType(name: "maj7", display: "Maj7"),
        ChordType(name: "7", display: "7"),
        ChordType(name: "m7", display: "m7"),
        ChordType(name: "6", display: "6"),
        ChordType(name: "m6", display: "m6"),
        ChordType(name: "maj9", display: "Maj9"),
        ChordType(name: "9", display: "9"),
        ChordType(name: "m9", display: "m9"),
        ChordType(name: "6/9", display: "6/9"),
    ],
    .advanced: [
        ChordType(name: "maj7", display: "Maj7"),
        ChordType(name: "7", display: "7"),
        ChordType(name: "m7", display: "m7"),
        ChordType(name: "6", display: "6"),
        ChordType(name: "m6", display: "m6"),
        ChordType(name: "maj9", display: "Maj9"),
        ChordType(name: "9", display: "9"),
        ChordType(name: "m9", display: "m9"),
        ChordType(name: "maj7#11", display: "Maj7#11"),
        ChordType(name: "7#9", display: "7#9"),
        ChordType(name: "7b9", display: "7b9"),
        ChordType(name: "m11", display: "m11"),
        ChordType(name: "13", display: "13"),
        ChordType(name: "m7b5", display: "m7b5"),
        ChordType(name: "dim7", display: "dim7"),
    ],
]

/// Semitone intervals from root for each chord quality (keyed by display name).
public let CHORD_INTERVALS: [String: [Int]] = [
    "Maj7": [0, 4, 7, 11],
    "7": [0, 4, 7, 10],
    "m7": [0, 3, 7, 10],
    "6": [0, 4, 7, 9],
    "m6": [0, 3, 7, 9],
    "Maj9": [0, 4, 7, 11, 14],
    "9": [0, 4, 7, 10, 14],
    "m9": [0, 3, 7, 10, 14],
    "6/9": [0, 4, 7, 9, 14],
    "Maj7#11": [0, 4, 7, 11, 18],
    "7#9": [0, 4, 7, 10, 15],
    "7b9": [0, 4, 7, 10, 13],
    "m11": [0, 3, 7, 10, 14, 17],
    "13": [0, 4, 7, 10, 14, 21],
    "m7b5": [0, 3, 6, 10],
    "dim7": [0, 3, 6, 9],
]

/// Maps display key → display string for each notation style.
public let CHORD_NOTATIONS: [NotationStyle: [String: String]] = [
    .standard: [
        "Maj7": "Maj7", "7": "7", "m7": "m7", "6": "6", "m6": "m6",
        "Maj9": "Maj9", "9": "9", "m9": "m9", "6/9": "6/9",
        "Maj7#11": "Maj7#11", "7#9": "7#9", "7b9": "7b9",
        "m11": "m11", "13": "13", "m7b5": "m7b5", "dim7": "dim7",
    ],
    .symbols: [
        "Maj7": "Δ7", "7": "7", "m7": "-7", "6": "6", "m6": "-6",
        "Maj9": "Δ9", "9": "9", "m9": "-9", "6/9": "6/9",
        "Maj7#11": "Δ7#11", "7#9": "7#9", "7b9": "7b9",
        "m11": "-11", "13": "13", "m7b5": "ø7", "dim7": "°7",
    ],
    .short: [
        "Maj7": "M7", "7": "7", "m7": "mi7", "6": "6", "m6": "mi6",
        "Maj9": "M9", "9": "9", "m9": "mi9", "6/9": "6/9",
        "Maj7#11": "M7#11", "7#9": "7#9", "7b9": "7b9",
        "m11": "mi11", "13": "13", "m7b5": "mi7b5", "dim7": "dim7",
    ],
]

/// Human-readable voicing labels.
public let VOICING_LABELS: [VoicingType: String] = [
    .root: "Root Position",
    .shell: "Shell Voicing",
    .halfShell: "Half Shell",
    .full: "Full Voicing",
    .rootlessA: "Rootless A",
    .rootlessB: "Rootless B",
    .inversion1: "1st Inversion",
    .inversion2: "2nd Inversion",
    .inversion3: "3rd Inversion",
]
