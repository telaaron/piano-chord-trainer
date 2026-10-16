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

// The web writes this same object without the iOS-only fields (and with a
// string notationSystem), so each field falls back to its default on its own
// instead of the whole decode failing and resetting everything.
extension SavedSettings {
    private enum CodingKeys: String, CodingKey {
        case difficulty, notation, voicing, displayMode, accidentals, notationSystem, totalChords
        case progressionMode, inputMode, customDegrees, soundPreset, audioEnabled, metronomeEnabled
        case metronomeBpm
    }

    /// `stored` with only the fields that changed from `old` to `new`, so a view
    /// holding an older copy never writes back values that sync updated meanwhile.
    static func patched(stored: SavedSettings, old: SavedSettings, new: SavedSettings) -> SavedSettings {
        let encoder = JSONEncoder()
        guard let s = try? JSONDecoder().decode(JSONValue.self, from: encoder.encode(stored)).object,
              let o = try? JSONDecoder().decode(JSONValue.self, from: encoder.encode(old)).object,
              let n = try? JSONDecoder().decode(JSONValue.self, from: encoder.encode(new)).object,
              let data = try? encoder.encode(JSONValue.object(s.merging(n.filter { o[$0.key] != $0.value }) { _, changed in changed })),
              let result = try? JSONDecoder().decode(SavedSettings.self, from: data)
        else { return new }
        return result
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func field<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            ((try? c.decodeIfPresent(T.self, forKey: key)) ?? nil) ?? fallback
        }
        let d = SavedSettings()
        self.init()
        difficulty = field(.difficulty, d.difficulty)
        notation = field(.notation, d.notation)
        voicing = field(.voicing, d.voicing)
        displayMode = field(.displayMode, d.displayMode)
        accidentals = field(.accidentals, d.accidentals)
        notationSystem = field(.notationSystem, d.notationSystem)
        totalChords = field(.totalChords, d.totalChords)
        progressionMode = field(.progressionMode, d.progressionMode)
        inputMode = field(.inputMode, d.inputMode)
        customDegrees = field(.customDegrees, d.customDegrees)
        soundPreset = field(.soundPreset, d.soundPreset)
        audioEnabled = field(.audioEnabled, d.audioEnabled)
        metronomeEnabled = field(.metronomeEnabled, d.metronomeEnabled)
        metronomeBpm = field(.metronomeBpm, d.metronomeBpm)
    }
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
        onSave?(key)
    }

    /// The stored JSON as-is, for sync (keeps fields the typed model doesn't know).
    /// Load for a store that persists the whole value back. `locked` means a
    /// file exists but doesn't decode (a newer shape, e.g. written by the web):
    /// the store must not save over it, or the account's data is lost.
    static func loadGuarded<T: Decodable>(_ type: T.Type, _ key: String) -> (value: T?, locked: Bool) {
        let value = load(type, key)
        return (value, value == nil && exists(key))
    }

    static func exists(_ key: String) -> Bool { FileManager.default.fileExists(atPath: url(key).path) }

    static func loadRaw(_ key: String) -> JSONValue? { load(JSONValue.self, key) }

    static func saveRaw(_ value: JSONValue, _ key: String) { save(value, key) }

    /// Called with the key after every save, so cloud sync knows the device changed.
    /// Set once at launch, before any store saves.
    nonisolated(unsafe) static var onSave: ((String) -> Void)?
}

/// Keys (string-stable, independent of the web's localStorage names).
enum StoreKey {
    static let history = "history"
    static let streak = "streak"
    static let settings = "settings"
    static let planHistory = "plan-history"
    static let habitProfile = "habit-profile"
    static let courseProgress = "course-progress"
    static let coachState = "coach-state"
    /// To-Go theory-card SRS states, keyed by card id (see MusicEngine.TheoryCardState).
    static let togoCards = "togo-cards"
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
