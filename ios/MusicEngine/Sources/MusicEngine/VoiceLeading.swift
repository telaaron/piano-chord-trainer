// Voice Leading Engine — analyze note movements between consecutive chords.
// 1:1 port of src/lib/engine/voice-leading.ts.

import Foundation

public enum VoiceLeadingMode: String, Sendable, CaseIterable, Codable {
    case guided
    case findInversion = "find-inversion"
    case free
}

public enum VLGrade: String, Sendable {
    case optimal
    case correct
    case wrong
}

public struct VLValidationResult: Sendable, Equatable {
    public let valid: Bool
    public let grade: VLGrade
    public let playerMovement: Int
    public let optimalMovement: Int
}

public struct VoiceMovement: Sendable, Equatable {
    public let from: String
    public let to: String
    public let semitones: Int
    public let stays: Bool
}

public struct VoiceLeadingInfo: Sendable, Equatable {
    public let fromNotes: [String]
    public let toNotes: [String]
    public let movements: [VoiceMovement]
    public let commonTones: [String]
    public let totalMovement: Int
}

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

private func chromaticDist(_ fromIdx: Int, _ toIdx: Int) -> Int { toIdx - fromIdx }

/// Analyze voice leading from one set of notes to another (octave-aware).
public func analyzeVoiceLeading(_ fromNotes: [String], _ toNotes: [String]) -> VoiceLeadingInfo {
    if fromNotes.isEmpty || toNotes.isEmpty {
        return VoiceLeadingInfo(fromNotes: fromNotes, toNotes: toNotes, movements: [], commonTones: [], totalMovement: 0)
    }

    let fromPCs = fromNotes.map(noteToSemitone)
    let toPCs = toNotes.map(noteToSemitone)

    let fromIndices = placeAscending(fromPCs.filter { $0 != -1 })
    let toIndices = placeAscending(toPCs.filter { $0 != -1 })

    let matchLen = min(fromIndices.count, toIndices.count)

    var movements: [VoiceMovement] = []
    var commonTones: [String] = []
    var totalMovement = 0

    for i in 0..<matchLen {
        let dist = chromaticDist(fromIndices[i], toIndices[i])
        let stays = dist == 0
        movements.append(VoiceMovement(from: fromNotes[i], to: toNotes[i], semitones: dist, stays: stays))
        if stays { commonTones.append(fromNotes[i]) }
        totalMovement += abs(dist)
    }

    if toNotes.count > matchLen {
        for i in matchLen..<toNotes.count {
            movements.append(VoiceMovement(from: "", to: toNotes[i], semitones: 0, stays: false))
        }
    }
    if fromNotes.count > matchLen {
        for i in matchLen..<fromNotes.count {
            movements.append(VoiceMovement(from: fromNotes[i], to: "", semitones: 0, stays: false))
        }
    }

    return VoiceLeadingInfo(fromNotes: fromNotes, toNotes: toNotes, movements: movements, commonTones: commonTones, totalMovement: totalMovement)
}

/// Format voice leading info as a human-readable string. E.g. "F stays, C → B (↓1)".
public func formatVoiceLeading(_ info: VoiceLeadingInfo) -> String {
    if info.movements.isEmpty { return "" }
    var parts: [String] = []
    for m in info.movements {
        if m.from.isEmpty || m.to.isEmpty { continue }
        if m.stays {
            parts.append("\(m.from) stays")
        } else {
            let arrow = m.semitones < 0 ? "↓" : "↑"
            parts.append("\(m.from) → \(m.to) (\(arrow)\(abs(m.semitones)))")
        }
    }
    return parts.joined(separator: ", ")
}

/// Find the rotation (inversion) of the target notes that minimises total voice movement.
public func computeVoiceLeadVoicing(
    _ prevVoicing: [String],
    _ targetNotes: [String],
    _ pref: AccidentalPreference = .both
) -> [String] {
    if prevVoicing.isEmpty { return targetNotes }
    if targetNotes.isEmpty { return targetNotes }

    let prevPCs = prevVoicing.map(noteToSemitone).filter { $0 != -1 }
    if prevPCs.isEmpty { return targetNotes }
    let prevPositions = placeAscending(prevPCs)

    let validTargets = targetNotes.filter { noteToSemitone($0) != -1 }
    let n = validTargets.count
    if n == 0 { return targetNotes }

    var bestRotation = validTargets
    var bestScore = Int.max

    for r in 0..<n {
        let rotated = Array(validTargets[r...]) + Array(validTargets[..<r])
        let rotatedPCs = rotated.map(noteToSemitone)
        let positions = placeAscending(rotatedPCs)

        let matchLen = min(prevPositions.count, positions.count)
        var score = 0
        for i in 0..<matchLen {
            score += abs(positions[i] - prevPositions[i])
        }

        if positions.count > matchLen {
            let prevCenter = (prevPositions[0] + prevPositions[prevPositions.count - 1]) / 2
            for i in matchLen..<positions.count {
                score += abs(positions[i] - prevCenter)
            }
        }

        if score < bestScore {
            bestScore = score
            bestRotation = rotated
        }
    }

    return bestRotation
}

/// Generate all rotations (inversions) of a note array.
public func getAllRotations(_ notes: [String]) -> [[String]] {
    let n = notes.count
    if n == 0 { return [notes] }
    var rotations: [[String]] = []
    for r in 0..<n {
        rotations.append(Array(notes[r...]) + Array(notes[..<r]))
    }
    return rotations
}

/// Compute total voice-leading movement from a previous voicing to played MIDI notes.
public func scorePlayerMovement(_ prevVoicing: [String], _ playedMidi: [Int]) -> Int {
    if prevVoicing.isEmpty || playedMidi.isEmpty { return 0 }

    let prevPCs = prevVoicing.map(noteToSemitone).filter { $0 != -1 }
    let prevPositions = placeAscending(prevPCs)

    let sorted = playedMidi.sorted()
    let matchLen = min(prevPositions.count, sorted.count)

    let midiBase = 48
    var total = 0
    for i in 0..<matchLen {
        total += abs(sorted[i] - (prevPositions[i] + midiBase))
    }
    return total
}

private func optimalToMidi(_ voicing: [String]) -> [Int] {
    let pcs = voicing.map(noteToSemitone).filter { $0 != -1 }
    let positions = placeAscending(pcs)
    return positions.map { $0 + 48 }
}

/// Validate a player's MIDI input for "Find the Inversion" mode (Mode B).
public func validateFindInversion(
    _ playedMidi: [Int],
    _ voicingNotes: [String],
    _ prevVoicing: [String],
    _ optimalVoicing: [String]
) -> VLValidationResult {
    if playedMidi.isEmpty {
        return VLValidationResult(valid: false, grade: .wrong, playerMovement: 0, optimalMovement: 0)
    }

    let expectedPCs = Set(voicingNotes.map(noteToSemitone).filter { $0 != -1 })
    let playedPCs = Set(playedMidi.map { $0 % 12 })

    if playedPCs.count != expectedPCs.count {
        return VLValidationResult(valid: false, grade: .wrong, playerMovement: 0, optimalMovement: 0)
    }
    for pc in expectedPCs where !playedPCs.contains(pc) {
        return VLValidationResult(valid: false, grade: .wrong, playerMovement: 0, optimalMovement: 0)
    }

    let playerMovement = scorePlayerMovement(prevVoicing, playedMidi)
    let optimalMovement = scorePlayerMovement(prevVoicing, optimalToMidi(optimalVoicing))

    let grade: VLGrade = playerMovement <= optimalMovement + 2 ? .optimal : .correct

    return VLValidationResult(valid: true, grade: grade, playerMovement: playerMovement, optimalMovement: optimalMovement)
}

/// Validate a player's MIDI input for "Free" mode (Mode C).
public func validateFreeVoicing(
    _ playedMidi: [Int],
    _ validPCSets: [Set<Int>],
    _ prevVoicing: [String]
) -> VLValidationResult {
    if playedMidi.isEmpty {
        return VLValidationResult(valid: false, grade: .wrong, playerMovement: 0, optimalMovement: 0)
    }

    let playedPCs = Set(playedMidi.map { $0 % 12 })

    let matchesAny = validPCSets.contains { expected in
        if playedPCs.count != expected.count { return false }
        for pc in expected where !playedPCs.contains(pc) { return false }
        return true
    }

    if !matchesAny {
        return VLValidationResult(valid: false, grade: .wrong, playerMovement: 0, optimalMovement: 0)
    }

    let playerMovement = scorePlayerMovement(prevVoicing, playedMidi)

    return VLValidationResult(valid: true, grade: .optimal, playerMovement: playerMovement, optimalMovement: 0)
}
