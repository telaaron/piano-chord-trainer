// Custom Progressions — parse user input, presets, evaluation.
// Port of the PURE parts of src/lib/engine/custom-progressions.ts.
// Storage (localStorage) is handled by the app's persistence layer, not here.

import Foundation

public struct CustomChord: Sendable, Equatable, Codable {
    public let display: String
    public let root: String
    public let quality: String
    public let beats: Int

    public init(display: String, root: String, quality: String, beats: Int) {
        self.display = display
        self.root = root
        self.quality = quality
        self.beats = beats
    }
}

public struct ParsedChord: Sendable, Equatable {
    public let root: String
    public let quality: String
    public let display: String
}

// ─── Quality map (longest-first greedy matching) ──────────────

private let qualityMap: [String: String] = {
    var map: [String: String] = [:]
    for (_, table) in CHORD_NOTATIONS {
        for (internalKey, display) in table {
            map[display] = internalKey
        }
    }
    // Common aliases people might type
    let aliases: [String: String] = [
        "Δ7": "Maj7", "Δ9": "Maj9", "-7": "m7", "-9": "m9", "-11": "m11",
        "ø7": "m7b5", "ø": "m7b5", "dim7": "dim7", "dim": "dim7", "o7": "dim7",
        "maj7": "Maj7", "maj9": "Maj9", "min7": "m7", "min9": "m9",
        "M7": "Maj7", "M9": "Maj9", "mi7": "m7", "mi9": "m9",
    ]
    for (k, v) in aliases { map[k] = v }
    return map
}()

private let qualityKeys: [String] = qualityMap.keys.sorted { $0.count > $1.count }

/// Parse a single chord symbol like "Dm7", "BbMaj7", "F#7#9". Returns nil if unrecognized.
public func parseChordSymbol(_ input: String) -> ParsedChord? {
    let trimmed = input.trimmingCharacters(in: .whitespaces)
    if trimmed.isEmpty { return nil }

    // Extract root: A-G followed by optional accidental
    guard let rootRange = trimmed.range(of: "^[A-G][#b♯♭]?", options: .regularExpression) else {
        return nil
    }
    var root = String(trimmed[rootRange])
    root = root.replacingOccurrences(of: "♯", with: "#").replacingOccurrences(of: "♭", with: "b")
    let rest = String(trimmed[rootRange.upperBound...])

    if rest.isEmpty { return nil }

    // First pass: exact match (case-sensitive: M7 ≠ m7)
    for key in qualityKeys where rest == key {
        if let quality = qualityMap[key], CHORD_INTERVALS[quality] != nil {
            return ParsedChord(root: root, quality: quality, display: trimmed)
        }
    }
    // Second pass: case-insensitive fallback
    for key in qualityKeys where rest.lowercased() == key.lowercased() {
        if let quality = qualityMap[key], CHORD_INTERVALS[quality] != nil {
            return ParsedChord(root: root, quality: quality, display: trimmed)
        }
    }
    // Direct lookup (user typed internal key like "Maj7")
    if CHORD_INTERVALS[rest] != nil {
        return ParsedChord(root: root, quality: rest, display: trimmed)
    }

    return nil
}

/// Parse a full progression string. Accepts "Dm7 | G7 | CMaj7", dashes, commas,
/// and beat annotations "Dm7(2)".
public func parseProgression(_ input: String) -> [CustomChord] {
    // Normalize separators: | – - , → space
    var normalized = input
    for sep in ["|", "–", "-", ","] {
        normalized = normalized.replacingOccurrences(of: sep, with: " ")
    }
    normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespaces)

    if normalized.isEmpty { return [] }

    let tokens = normalized.split(separator: " ").map(String.init).filter { !$0.isEmpty }
    var chords: [CustomChord] = []

    for token in tokens {
        var chordStr = token
        var beats = 4
        // Beat annotation: "Dm7(2)"
        if let m = token.range(of: "^(.+)\\((\\d+)\\)$", options: .regularExpression) {
            let matched = String(token[m])
            if let paren = matched.firstIndex(of: "("), let close = matched.firstIndex(of: ")") {
                chordStr = String(matched[matched.startIndex..<paren])
                let beatStr = String(matched[matched.index(after: paren)..<close])
                beats = Int(beatStr) ?? 4
            }
        }

        if let parsed = parseChordSymbol(chordStr) {
            chords.append(CustomChord(display: parsed.display, root: parsed.root, quality: parsed.quality, beats: beats))
        }
    }

    return chords
}

/// Format a progression back into a display string.
public func formatProgression(_ chords: [CustomChord]) -> String {
    chords.map { c in
        c.beats != 4 ? "\(c.display)(\(c.beats))" : c.display
    }.joined(separator: " | ")
}

// ─── Preset Progressions ────────────────────────────────────

public struct ProgressionPreset: Sendable, Equatable {
    public let name: String
    public let tag: String
    public let raw: String
    public let bpm: Int
}

public let PROGRESSION_PRESETS: [ProgressionPreset] = [
    ProgressionPreset(name: "Autumn Leaves (A-Teil)", tag: "Jazz Standard", raw: "Cm7 | F7 | BbMaj7 | EbMaj7 | Am7b5 | D7 | Gm7 | Gm7", bpm: 140),
    ProgressionPreset(name: "All of Me (A-Teil)", tag: "Jazz Standard", raw: "CMaj7 | CMaj7 | E7 | E7 | A7 | A7 | Dm7 | Dm7", bpm: 130),
    ProgressionPreset(name: "Blue Bossa", tag: "Latin Jazz", raw: "Cm7 | Cm7 | Fm7 | Fm7 | Dm7b5 | G7 | Cm7 | Cm7", bpm: 140),
    ProgressionPreset(name: "Rhythm Changes (A)", tag: "Bebop", raw: "BbMaj7 | Gm7 | Cm7 | F7 | Dm7 | Gm7 | Cm7 | F7", bpm: 160),
    ProgressionPreset(name: "12-Bar Blues", tag: "Blues", raw: "C7 | C7 | C7 | C7 | F7 | F7 | C7 | C7 | G7 | F7 | C7 | G7", bpm: 120),
    ProgressionPreset(name: "So What", tag: "Modal Jazz", raw: "Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7", bpm: 136),
    ProgressionPreset(name: "Satin Doll (A)", tag: "Swing", raw: "Dm7 | G7 | Em7 | A7 | Am7 | D7 | AbMaj7 | DbMaj7", bpm: 120),
]

// ─── Evaluation ─────────────────────────────────────────────

public struct ChordEval: Sendable, Equatable {
    public let chord: CustomChord
    public let hit: Bool
    public let timingOffsetMs: Double
    public let bestAccuracy: Double

    public init(chord: CustomChord, hit: Bool, timingOffsetMs: Double, bestAccuracy: Double) {
        self.chord = chord
        self.hit = hit
        self.timingOffsetMs = timingOffsetMs
        self.bestAccuracy = bestAccuracy
    }
}

public struct LoopEvaluation: Sendable, Equatable {
    public let chords: [ChordEval]
    public let accuracy: Double

    public init(chords: [ChordEval], accuracy: Double) {
        self.chords = chords
        self.accuracy = accuracy
    }
}

public struct SessionEvaluation: Sendable, Equatable {
    public let loops: [LoopEvaluation]
    public let overallAccuracy: Double
    public let avgTimingMs: Int
    public let weakChords: [String]
    public let totalMs: Double
}

/// Compute the overall session evaluation from per-loop results.
public func evaluateSession(_ loops: [LoopEvaluation], _ totalMs: Double) -> SessionEvaluation {
    let allChordEvals = loops.flatMap { $0.chords }
    let hitCount = allChordEvals.filter { $0.hit }.count
    let totalCount = allChordEvals.count
    let avgTiming = totalCount > 0
        ? allChordEvals.reduce(0.0) { $0 + abs($1.timingOffsetMs) } / Double(totalCount)
        : 0.0

    var missCounts: [String: Int] = [:]
    for e in allChordEvals where !e.hit {
        missCounts[e.chord.display, default: 0] += 1
    }

    let loopCount = loops.isEmpty ? 1 : loops.count
    let weakChords = missCounts
        .filter { Double($0.value) > Double(loopCount) / 2 }
        .map { $0.key }

    return SessionEvaluation(
        loops: loops,
        overallAccuracy: totalCount > 0 ? Double(hitCount) / Double(totalCount) : 0,
        avgTimingMs: Int(avgTiming.rounded()),
        weakChords: weakChords,
        totalMs: totalMs
    )
}
