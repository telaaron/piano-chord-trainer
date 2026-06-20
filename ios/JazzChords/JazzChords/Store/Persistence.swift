// Persistence — Codable JSON in Application Support, mirroring the web app's
// localStorage keys/shapes (progress.ts). Single source for history, streak,
// settings, plan-history, habit profile. (Optional Supabase cloud-sync later.)

import Foundation
import MusicEngine

/// Trainer settings persisted between launches (mirrors SavedSettings in progress.ts).
struct SavedSettings: Codable, Equatable {
    var difficulty: Difficulty = .beginner
    var notation: NotationStyle = .standard
    var voicing: VoicingType = .root
    var displayMode: DisplayMode = .always
    var accidentals: AccidentalPreference = .both
    var notationSystem: NotationSystem = .international
    var totalChords: Int = 20
    var progressionMode: ProgressionMode = .random
    var inputMode: String = "none"
    var customDegrees: [Int] = [1, 4, 0]
    var soundPreset: String = "grand-piano"
    var audioEnabled: Bool = true
    var metronomeEnabled: Bool = false
    var metronomeBpm: Int = 80
}

/// Tiny JSON-file key/value store under Application Support.
enum Store {
    private static let dir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let d = base.appendingPathComponent("JazzChords", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    private static func url(_ key: String) -> URL { dir.appendingPathComponent("\(key).json") }

    static func load<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = try? Data(contentsOf: url(key)) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func save<T: Encodable>(_ value: T, _ key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url(key), options: .atomic)
    }
}

/// Keys (string-stable, independent of the web's localStorage names).
enum StoreKey {
    static let history = "history"
    static let streak = "streak"
    static let settings = "settings"
    static let planHistory = "plan-history"
    static let habitProfile = "habit-profile"
    static let courseProgress = "course-progress"
}

/// Convenience wrappers used by the stores.
enum ProgressStore {
    private static let maxHistory = 100

    static func loadHistory() -> [SessionResult] {
        Store.load([SessionResult].self, StoreKey.history) ?? []
    }

    @discardableResult
    static func saveSession(_ session: SessionResult) -> SessionResult {
        var history = loadHistory()
        history.insert(session, at: 0)
        if history.count > maxHistory { history = Array(history.prefix(maxHistory)) }
        Store.save(history, StoreKey.history)
        return session
    }

    static func loadStreak() -> StreakData {
        Store.load(StreakData.self, StoreKey.streak) ?? StreakData(current: 0, best: 0, lastDate: "")
    }

    private static func todayStr() -> String { dayString(Date()) }
    private static func yesterdayStr() -> String {
        dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    }
    private static func dayString(_ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    @discardableResult
    static func recordPracticeDay() -> StreakData {
        var streak = loadStreak()
        let today = todayStr()
        if streak.lastDate == today { return streak }
        let yesterday = yesterdayStr()
        if streak.lastDate == yesterday || streak.lastDate.isEmpty {
            streak.current += 1
        } else {
            streak.current = 1
        }
        streak.lastDate = today
        streak.best = max(streak.best, streak.current)
        Store.save(streak, StoreKey.streak)
        return streak
    }

    static func loadSettings() -> SavedSettings {
        Store.load(SavedSettings.self, StoreKey.settings) ?? SavedSettings()
    }

    static func saveSettings(_ s: SavedSettings) {
        Store.save(s, StoreKey.settings)
    }
}
