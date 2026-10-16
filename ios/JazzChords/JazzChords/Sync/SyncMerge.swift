// SyncMerge — Swift port of the web's src/lib/services/cloud-merge.ts. The
// account row is shared by iPhone, iPad and the browser, so all of them must
// merge it by the same rules: never drop a session, keep the more advanced
// profile, keep the latest streak with the best record, account wins the rest.

import Foundation

enum SyncMerge {
    static let historyKey = "chord-trainer-history"
    static let profileKey = "chord-trainer-habit-profile"
    static let streakKey = "chord-trainer-streak"
    static let settingsKey = "chord-trainer-settings"
    /// Same cap as the web's services/progress and ProgressStore.
    static let maxHistory = 100

    /// Combine this device's data with the account's. `keepLocal: false` is the
    /// "don't bring my device data" choice: the account replaces what it has,
    /// local-only keys stay. `preferLocal: true` is for uploads: the device's
    /// own edits are the newest, so they win where the account would otherwise.
    static func merge(local: SyncData, cloud: SyncData, keepLocal: Bool = true,
                      preferLocal: Bool = false) -> SyncData {
        var out = local
        for (key, c) in cloud {
            guard keepLocal, let l = local[key] else { out[key] = c; continue }
            switch key {
            case historyKey: out[key] = mergeHistory(l, c)
            case profileKey: out[key] = mergeProfile(l, c)
            case streakKey: out[key] = mergeStreak(l, c)
            case settingsKey: out[key] = preferLocal ? mergeFields(c, l) : mergeFields(l, c)
            default: out[key] = preferLocal ? l : c
            }
        }
        return out
    }

    private static func mergeHistory(_ local: JSONValue, _ cloud: JSONValue) -> JSONValue {
        guard let l = local.array else { return cloud }
        guard let c = cloud.array else { return local }
        func key(_ s: JSONValue) -> String {
            let o = s.object
            return o?["id"]?.string ?? "t\(timestampText(o?["timestamp"]))"
        }
        // Cloud first, then local: on an id clash the device's copy wins (as on the web).
        var order: [String] = []
        var byId: [String: JSONValue] = [:]
        for s in c + l {
            let k = key(s)
            if byId[k] == nil { order.append(k) }
            byId[k] = s
        }
        let sorted = order.compactMap { byId[$0] }.enumerated().sorted { a, b in
            let ta = a.element.object?["timestamp"]?.number ?? 0
            let tb = b.element.object?["timestamp"]?.number ?? 0
            return ta != tb ? ta > tb : a.offset < b.offset
        }.map(\.element)
        return .array(Array(sorted.prefix(maxHistory)))
    }

    /// The web keys id-less sessions by `t${timestamp}`; JS prints whole numbers without ".0".
    private static func timestampText(_ v: JSONValue?) -> String {
        guard let n = v?.number else { return "undefined" }
        return n == n.rounded() && abs(n) < 1e15 ? String(Int64(n)) : String(n)
    }

    private static func mergeProfile(_ local: JSONValue, _ cloud: JSONValue) -> JSONValue {
        guard let l = local.object else { return cloud }
        guard let c = cloud.object else { return local }
        var base = (c["totalXP"]?.number ?? 0) > (l["totalXP"]?.number ?? 0) ? c : l
        base["onboardingDone"] = .bool((l["onboardingDone"]?.bool ?? false) || (c["onboardingDone"]?.bool ?? false))
        return .object(base)
    }

    /// `winner` wins field by field, so fields only iOS writes (sound,
    /// metronome) survive the browser saving its smaller settings object.
    private static func mergeFields(_ other: JSONValue, _ winner: JSONValue) -> JSONValue {
        guard let o = other.object, let w = winner.object else { return winner }
        return .object(o.merging(w) { _, win in win })
    }

    private static func mergeStreak(_ local: JSONValue, _ cloud: JSONValue) -> JSONValue {
        guard let l = local.object else { return cloud }
        guard let c = cloud.object else { return local }
        var latest = (c["lastDate"]?.string ?? "") > (l["lastDate"]?.string ?? "") ? c : l
        latest["best"] = .number(max(l["best"]?.number ?? 0, c["best"]?.number ?? 0))
        return .object(latest)
    }
}
