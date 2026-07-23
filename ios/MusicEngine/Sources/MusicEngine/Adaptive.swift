// Adaptive Difficulty Engine — spaced-repetition-style weighted chord selection.
// 1:1 port of src/lib/engine/adaptive.ts.

import Foundation

/// Per-chord timing record (mirrors src/lib/services/progress.ts ChordTiming).
/// Lives in the engine because the adaptive selector consumes it.
public struct ChordTiming: Sendable, Equatable, Codable {
    public let chord: String
    public let root: String
    public let durationMs: Double
    /// Whether the player answered this chord correctly (verify/MIDI modes).
    /// Absent in older sessions and in modes that don't validate input —
    /// consumers must treat `nil` as "unknown" (fall back to timing only).
    public let correct: Bool?

    public init(chord: String, root: String, durationMs: Double, correct: Bool? = nil) {
        self.chord = chord
        self.root = root
        self.durationMs = durationMs
        self.correct = correct
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chord = try c.decode(String.self, forKey: .chord)
        root = try c.decode(String.self, forKey: .root)
        durationMs = try c.decode(Double.self, forKey: .durationMs)
        // Older persisted sessions predate `correct` — decode it optionally.
        correct = try c.decodeIfPresent(Bool.self, forKey: .correct)
    }
}

public enum PerformanceTrend: String, Sendable {
    case improving
    case stable
    case declining
}

public struct ChordPerformance: Sendable, Equatable {
    public let root: String
    public let quality: String
    public let avgTime: Double
    public let attempts: Int
    public let trend: PerformanceTrend
}

public enum WeightReason: String, Sendable {
    case weak
    case new
    case normal
    case strong
}

public struct WeightedChord: Sendable, Equatable {
    public let root: String
    public let quality: String
    public let display: String
    public let weight: Double
    public let reason: WeightReason
}

private let WEIGHT_WEAK = 4.0
private let WEIGHT_NEW = 2.5
private let WEIGHT_NORMAL = 1.0
private let WEIGHT_STRONG = 0.3
private let WEIGHT_FOCUS = 10.0

private let WEAK_FACTOR = 1.4
private let STRONG_FACTOR = 0.7

/// "DbMaj7" with root "Db" → "Maj7".
private func extractQuality(_ chord: String, _ root: String) -> String {
    if chord.hasPrefix(root) {
        let q = String(chord.dropFirst(root.count))
        return q.isEmpty ? "unknown" : q
    }
    return chord
}

private func computeTrend(_ times: [Double]) -> PerformanceTrend {
    if times.count < 4 { return .stable }
    let mid = times.count / 2
    let firstHalf = Array(times[..<mid])
    let secondHalf = Array(times[mid...])
    let avgFirst = firstHalf.reduce(0, +) / Double(firstHalf.count)
    let avgSecond = secondHalf.reduce(0, +) / Double(secondHalf.count)
    let ratio = avgSecond / avgFirst
    if ratio < 0.85 { return .improving }
    if ratio > 1.15 { return .declining }
    return .stable
}

/// Aggregate per-chord timing history into performance profiles.
public func analyzePerformance(_ history: [ChordTiming]) -> [String: ChordPerformance] {
    var grouped: [String: (times: [Double], root: String, quality: String)] = [:]

    for t in history {
        let quality = extractQuality(t.chord, t.root)
        let key = "\(t.root)-\(quality)"
        if grouped[key] != nil {
            grouped[key]!.times.append(t.durationMs)
        } else {
            grouped[key] = (times: [t.durationMs], root: t.root, quality: quality)
        }
    }

    var result: [String: ChordPerformance] = [:]
    for (key, data) in grouped {
        let avgTime = data.times.reduce(0, +) / Double(data.times.count)
        let trend = computeTrend(data.times)
        result[key] = ChordPerformance(root: data.root, quality: data.quality, avgTime: avgTime, attempts: data.times.count, trend: trend)
    }

    return result
}

/// Generate a weighted chord pool based on performance history.
public func getWeightedChordPool(
    _ history: [ChordTiming],
    _ pool: [ChordType],
    _ notePool: [String],
    _ focusRoots: [String]? = nil
) -> [WeightedChord] {
    let performance = analyzePerformance(history)

    let allTimes = performance.values.map { $0.avgTime }
    let medianTime = allTimes.isEmpty ? 3000.0 : allTimes.sorted()[allTimes.count / 2]

    var weighted: [WeightedChord] = []

    for chord in pool {
        for root in notePool {
            let key = "\(root)-\(chord.display)"
            let perf = performance[key]

            var weight: Double
            var reason: WeightReason

            if perf == nil {
                weight = WEIGHT_NEW
                reason = .new
            } else if perf!.avgTime > medianTime * WEAK_FACTOR {
                weight = WEIGHT_WEAK
                reason = .weak
                if perf!.trend == .declining { weight *= 1.3 }
            } else if perf!.avgTime < medianTime * STRONG_FACTOR {
                weight = WEIGHT_STRONG
                reason = .strong
            } else {
                weight = WEIGHT_NORMAL
                reason = .normal
            }

            if let focusRoots, !focusRoots.isEmpty, focusRoots.contains(root) {
                weight = max(weight, WEIGHT_FOCUS)
                reason = .weak
            }

            weighted.append(WeightedChord(root: root, quality: chord.name, display: chord.display, weight: weight, reason: reason))
        }
    }

    return weighted
}

/// Pick a chord from a weighted pool using weighted random selection. Avoids repeating the last chord.
/// `roll01` lets tests inject determinism; defaults to a fresh random draw.
public func pickWeightedChord(
    _ pool: [WeightedChord],
    lastRoot: String? = nil,
    lastDisplay: String? = nil,
    roll01: () -> Double = { Double.random(in: 0..<1) }
) -> WeightedChord {
    let candidates = pool.count > 1
        ? pool.filter { !($0.root == lastRoot && $0.display == lastDisplay) }
        : pool

    let totalWeight = candidates.reduce(0.0) { $0 + $1.weight }
    var roll = roll01() * totalWeight

    for chord in candidates {
        roll -= chord.weight
        if roll <= 0 { return chord }
    }

    return candidates[candidates.count - 1]
}

/// Top N weakest and strongest chords for display.
public func getPerformanceSummary(
    _ history: [ChordTiming],
    _ topN: Int = 5
) -> (weakest: [ChordPerformance], strongest: [ChordPerformance]) {
    let perf = analyzePerformance(history)
    let all = perf.values.filter { $0.attempts >= 2 }
    let sorted = all.sorted { $0.avgTime > $1.avgTime }
    return (weakest: Array(sorted.prefix(topN)), strongest: Array(sorted.suffix(topN).reversed()))
}
