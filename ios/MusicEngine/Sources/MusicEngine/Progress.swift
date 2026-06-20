// Progress data model + analytics — the PURE parts of src/lib/services/progress.ts.
// localStorage I/O lives in the app's persistence layer; the types + analyzers
// (which the Habit engine and Progress screen consume) live here so they're testable.

import Foundation

public struct SessionSettings: Sendable, Equatable, Codable {
    public let difficulty: Difficulty
    public let notation: NotationStyle
    public let voicing: VoicingType
    public let displayMode: DisplayMode
    public let accidentals: AccidentalPreference
    public let progressionMode: ProgressionMode

    public init(difficulty: Difficulty, notation: NotationStyle, voicing: VoicingType,
                displayMode: DisplayMode, accidentals: AccidentalPreference, progressionMode: ProgressionMode) {
        self.difficulty = difficulty
        self.notation = notation
        self.voicing = voicing
        self.displayMode = displayMode
        self.accidentals = accidentals
        self.progressionMode = progressionMode
    }
}

public struct SessionMidi: Sendable, Equatable, Codable {
    public let enabled: Bool
    public let accuracy: Int

    public init(enabled: Bool, accuracy: Int) {
        self.enabled = enabled
        self.accuracy = accuracy
    }
}

public struct SessionResult: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public let timestamp: Double
    public let elapsedMs: Double
    public let totalChords: Int
    public let avgMs: Double
    public let chordTimings: [ChordTiming]?
    public let settings: SessionSettings
    public let midi: SessionMidi

    public init(id: String, timestamp: Double, elapsedMs: Double, totalChords: Int, avgMs: Double,
                chordTimings: [ChordTiming]?, settings: SessionSettings, midi: SessionMidi) {
        self.id = id
        self.timestamp = timestamp
        self.elapsedMs = elapsedMs
        self.totalChords = totalChords
        self.avgMs = avgMs
        self.chordTimings = chordTimings
        self.settings = settings
        self.midi = midi
    }
}

public struct PersonalBest: Sendable, Equatable, Codable {
    public let elapsedMs: Double
    public let avgMs: Double
    public let timestamp: Double
    public let totalChords: Int
}

public struct ProgressStats: Sendable, Equatable {
    public let totalSessions: Int
    public let totalChords: Int
    public let totalTimeMs: Double
    public let overallAvgMs: Double
    public let personalBests: [String: PersonalBest]
    public let recentSessions: [SessionResult]
}

public struct StreakData: Sendable, Equatable, Codable {
    public var current: Int
    public var best: Int
    public var lastDate: String

    public init(current: Int, best: Int, lastDate: String) {
        self.current = current
        self.best = best
        self.lastDate = lastDate
    }
}

private func bestKey(_ session: SessionResult) -> String {
    let s = session.settings
    return "\(s.difficulty.rawValue)-\(s.voicing.rawValue)-\(s.progressionMode.rawValue)"
}

/// Compute aggregate stats + personal bests from history.
public func computeStats(_ history: [SessionResult]) -> ProgressStats {
    let totalSessions = history.count
    var totalChords = 0
    var totalTimeMs = 0.0
    var personalBests: [String: PersonalBest] = [:]

    for s in history {
        totalChords += s.totalChords
        totalTimeMs += s.elapsedMs

        let key = bestKey(s)
        if let existing = personalBests[key] {
            if s.avgMs < existing.avgMs {
                personalBests[key] = PersonalBest(elapsedMs: s.elapsedMs, avgMs: s.avgMs, timestamp: s.timestamp, totalChords: s.totalChords)
            }
        } else {
            personalBests[key] = PersonalBest(elapsedMs: s.elapsedMs, avgMs: s.avgMs, timestamp: s.timestamp, totalChords: s.totalChords)
        }
    }

    return ProgressStats(
        totalSessions: totalSessions,
        totalChords: totalChords,
        totalTimeMs: totalTimeMs,
        overallAvgMs: totalChords > 0 ? totalTimeMs / Double(totalChords) : 0,
        personalBests: personalBests,
        recentSessions: Array(history.prefix(30))
    )
}

// ─── Weak-chord analysis ────────────────────────────────────

public struct WeakChord: Sendable, Equatable {
    public let root: String
    public let chord: String
    public let avgMs: Double
    public let count: Int
}

public struct ChordTrend: Sendable, Equatable {
    public let root: String
    public let oldAvgMs: Double
    public let recentAvgMs: Double
    public let changePercent: Double
}

public struct WeakSpot: Sendable, Equatable {
    public let root: String
    public let voicing: VoicingType
    public let avgMs: Double
    public let count: Int
}

/// Group all chord timings by root, return sorted slowest-first.
public func analyzeWeakChords(_ history: [SessionResult], _ limit: Int = 5) -> [WeakChord] {
    var byRoot: [String: (totalMs: Double, count: Int, chord: String)] = [:]

    for session in history {
        guard let timings = session.chordTimings else { continue }
        for ct in timings {
            if byRoot[ct.root] != nil {
                byRoot[ct.root]!.totalMs += ct.durationMs
                byRoot[ct.root]!.count += 1
            } else {
                byRoot[ct.root] = (totalMs: ct.durationMs, count: 1, chord: ct.chord)
            }
        }
    }

    var result: [WeakChord] = []
    for (root, data) in byRoot {
        if data.count < 2 { continue }
        result.append(WeakChord(root: root, chord: data.chord, avgMs: data.totalMs / Double(data.count), count: data.count))
    }

    result.sort { $0.avgMs > $1.avgMs }
    return Array(result.prefix(limit))
}

/// Compare recent (last 5) vs older (5-15) sessions per root.
public func analyzeChordTrends(_ history: [SessionResult]) -> [ChordTrend] {
    let recent = Array(history.prefix(5))
    let older = Array(history.dropFirst(5).prefix(10))

    if recent.count < 2 || older.count < 2 { return [] }

    func avgByRoot(_ sessions: [SessionResult]) -> [String: (totalMs: Double, count: Int)] {
        var map: [String: (totalMs: Double, count: Int)] = [:]
        for s in sessions {
            guard let timings = s.chordTimings else { continue }
            for ct in timings {
                if map[ct.root] != nil {
                    map[ct.root]!.totalMs += ct.durationMs
                    map[ct.root]!.count += 1
                } else {
                    map[ct.root] = (totalMs: ct.durationMs, count: 1)
                }
            }
        }
        return map
    }

    let recentAvgs = avgByRoot(recent)
    let olderAvgs = avgByRoot(older)

    var trends: [ChordTrend] = []
    for (root, recentData) in recentAvgs {
        guard let olderData = olderAvgs[root], olderData.count >= 2 else { continue }
        let recentAvg = recentData.totalMs / Double(recentData.count)
        let olderAvg = olderData.totalMs / Double(olderData.count)
        let change = ((recentAvg - olderAvg) / olderAvg) * 100
        trends.append(ChordTrend(root: root, oldAvgMs: olderAvg, recentAvgMs: recentAvg, changePercent: change))
    }

    trends.sort { $0.changePercent < $1.changePercent }
    return trends
}

/// Group by root+voicing, return sorted slowest-first.
public func analyzeWeakSpots(_ history: [SessionResult], _ limit: Int = 5) -> [WeakSpot] {
    var byKey: [String: (root: String, voicing: VoicingType, totalMs: Double, count: Int)] = [:]

    for session in history {
        guard let timings = session.chordTimings else { continue }
        let v = session.settings.voicing
        for ct in timings {
            let key = "\(ct.root)|\(v.rawValue)"
            if byKey[key] != nil {
                byKey[key]!.totalMs += ct.durationMs
                byKey[key]!.count += 1
            } else {
                byKey[key] = (root: ct.root, voicing: v, totalMs: ct.durationMs, count: 1)
            }
        }
    }

    var result: [WeakSpot] = []
    for data in byKey.values {
        if data.count < 2 { continue }
        result.append(WeakSpot(root: data.root, voicing: data.voicing, avgMs: data.totalMs / Double(data.count), count: data.count))
    }

    result.sort { $0.avgMs > $1.avgMs }
    return Array(result.prefix(limit))
}
