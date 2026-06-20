// Progression engine – generate structured chord sequences (ii-V-I, cycle of 4ths, etc.)
// 1:1 port of src/lib/engine/progressions.ts.

import Foundation

public enum ProgressionMode: String, Sendable, CaseIterable, Codable {
    case random
    case twoFiveOne = "2-5-1"
    case oneSixTwoFive = "1-6-2-5"
    case cycleOf4ths = "cycle-of-4ths"
    case threeSixTwoFive = "3-6-2-5"
    case oneFourFive = "1-4-5"
    case diatonic
    case custom
}

public let PROGRESSION_LABELS: [ProgressionMode: String] = [
    .random: "Random",
    .twoFiveOne: "ii – V – I",
    .oneSixTwoFive: "I – vi – ii – V",
    .cycleOf4ths: "Cycle of 4ths",
    .threeSixTwoFive: "iii – vi – ii – V",
    .oneFourFive: "I – IV – V",
    .diatonic: "I – ii – iii – IV – V – vi – vii",
    .custom: "Custom",
]

public let PROGRESSION_DESCRIPTIONS: [ProgressionMode: String] = [
    .random: "Random chords",
    .twoFiveOne: "Dm7 → G7 → CMaj7 through all keys",
    .oneSixTwoFive: "CMaj7 → Am7 → Dm7 → G7 through all keys",
    .cycleOf4ths: "C → F → Bb → Eb → … through all 12",
    .threeSixTwoFive: "Em7 → Am7 → Dm7 → G7 through all keys",
    .oneFourFive: "CMaj7 → FMaj7 → G7 through all keys",
    .diatonic: "All 7 diatonic chords through all keys",
    .custom: "Your own scale-degree sequence through all keys",
]

/// Semitone offsets from root for each scale degree (major scale): 1 2 3 4 5 6 7
private let SCALE_DEGREES = [0, 2, 4, 5, 7, 9, 11]

/// I=Maj7, ii=m7, iii=m7, IV=Maj7, V=7, vi=m7, vii=m7b5
private let MAJOR_DEGREE_QUALITIES = ["Maj7", "m7", "m7", "Maj7", "7", "m7", "m7b5"]

/// Cycle of 4ths order (semitone intervals).
private let CYCLE_OF_4THS = [0, 5, 10, 3, 8, 1, 6, 11, 4, 9, 2, 7]

public struct ProgressionChord: Sendable, Equatable {
    public let root: String
    public let quality: String
    public let display: String

    public init(root: String, quality: String, display: String) {
        self.root = root
        self.quality = quality
        self.display = display
    }
}

private func noteFromSemitone(_ semitone: Int, _ pref: AccidentalPreference, _ keySemitone: Int? = nil) -> String {
    let idx = ((semitone % 12) + 12) % 12
    if pref == .flats { return NOTES_FLATS[idx] }
    if pref == .sharps { return NOTES_SHARPS[idx] }
    let ref = keySemitone != nil ? ((keySemitone! % 12) + 12) % 12 : idx
    return usesSharps(ref) ? NOTES_SHARPS[idx] : NOTES_FLATS[idx]
}

private func getKeyCenters(_ pref: AccidentalPreference) -> [String] {
    if pref == .flats { return NOTES_FLATS }
    if pref == .sharps { return NOTES_SHARPS }
    return CYCLE_OF_4THS.map { noteFromSemitone($0, .flats) }
}

private let DEGREE_ROMAN = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]

/// Map a built-in mode to its scale-degree indices (0-based). nil for random/cycle/custom.
public let MODE_DEGREE_MAP: [ProgressionMode: [Int]] = [
    .twoFiveOne: [1, 4, 0],
    .oneSixTwoFive: [0, 5, 1, 4],
    .threeSixTwoFive: [2, 5, 1, 4],
    .oneFourFive: [0, 3, 4],
    .diatonic: [0, 1, 2, 3, 4, 5, 6],
]

private func generateFromDegrees(
    _ degreeIndices: [Int],
    _ keySemitone: Int,
    _ pref: AccidentalPreference,
    _ notation: NotationStyle
) -> [ProgressionChord] {
    degreeIndices.map { degIdx in
        let rootSemitone = (keySemitone + SCALE_DEGREES[degIdx]) % 12
        let quality = MAJOR_DEGREE_QUALITIES[degIdx]
        let root = noteFromSemitone(rootSemitone, pref, keySemitone)
        let displayQuality = CHORD_NOTATIONS[notation]?[quality] ?? quality
        return ProgressionChord(root: root, quality: quality, display: "\(root)\(displayQuality)")
    }
}

private func generateDegreeProgression(
    _ degreeIndices: [Int],
    _ pref: AccidentalPreference,
    _ notation: NotationStyle
) -> [ProgressionChord] {
    let keys = getKeyCenters(pref)
    var allChords: [ProgressionChord] = []
    for key in keys {
        let keySemitone = NOTES_SHARPS.firstIndex(of: key) ?? NOTES_FLATS.firstIndex(of: key) ?? -1
        if keySemitone == -1 { continue }
        allChords.append(contentsOf: generateFromDegrees(degreeIndices, keySemitone, pref, notation))
    }
    return allChords
}

private func generateCycleOf4ths(_ pref: AccidentalPreference, _ notation: NotationStyle) -> [ProgressionChord] {
    let quality = "7"
    let displayQuality = CHORD_NOTATIONS[notation]?[quality] ?? quality
    return CYCLE_OF_4THS.map { st in
        let root = noteFromSemitone(st, pref)
        return ProgressionChord(root: root, quality: quality, display: "\(root)\(displayQuality)")
    }
}

/// Convert 1-based user-facing degrees (1–7) to 0-based indices. Clamps to valid range.
public func parseCustomDegrees(_ degrees: [Int]) -> [Int] {
    degrees.map { max(0, min(6, $0 - 1)) }
}

/// Build a human-readable Roman numeral label from degree indices (0-based).
public func degreesToLabel(_ degreeIndices: [Int]) -> String {
    degreeIndices.map { DEGREE_ROMAN[$0] }.joined(separator: " – ")
}

public struct GeneratedProgression: Sendable, Equatable {
    public let chords: [ProgressionChord]
    public let label: String
}

/// Generate a full chord list for a progression mode.
public func generateProgression(
    _ mode: ProgressionMode,
    _ pref: AccidentalPreference,
    _ notation: NotationStyle,
    _ totalChords: Int,
    _ customDegrees: [Int]? = nil
) -> GeneratedProgression {
    let degrees: [Int]? = mode == .custom
        ? (customDegrees ?? [0, 3, 4])
        : MODE_DEGREE_MAP[mode]

    if let degrees {
        let chords = generateDegreeProgression(degrees, pref, notation)
        let label = "\(degreesToLabel(degrees)) through all 12 keys (\(chords.count) chords)"
        return GeneratedProgression(chords: chords, label: label)
    }

    if mode == .cycleOf4ths {
        let chords = generateCycleOf4ths(pref, notation)
        return GeneratedProgression(chords: chords, label: "Cycle of 4ths (\(chords.count) chords)")
    }

    // 'random' — handled by the trainer's generateChords()
    return GeneratedProgression(chords: [], label: "\(totalChords) random chords")
}
