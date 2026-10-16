// SyncKeys — which device stores sync, and under which web key. iOS keeps the
// web's JSON shapes (Persistence.swift), so a store's file is the value of its
// web localStorage key inside the account's `user_data.data`.

import Foundation

enum SyncKeys {
    /// iOS store key → web localStorage key.
    static let map: [String: String] = [
        StoreKey.history: "chord-trainer-history",
        StoreKey.streak: "chord-trainer-streak",
        StoreKey.settings: "chord-trainer-settings",
        StoreKey.habitProfile: "chord-trainer-habit-profile",
        StoreKey.courseProgress: "chord-trainer-course-progress",
        StoreKey.coachState: "chord-trainer-coach-state",
        StoreKey.togoCards: "chord-trainer-togo-cards",
    ]

    /// This device's synced stores, keyed by web key.
    static func snapshot(read: (String) -> JSONValue?) -> SyncData {
        var out: SyncData = [:]
        for (ios, web) in map { if let v = read(ios) { out[web] = v } }
        return out
    }

    /// Write the synced keys of `data` into the device stores; web-only keys are skipped.
    static func apply(_ data: SyncData, write: (String, JSONValue) -> Void) {
        for (ios, web) in map { if let v = data[web] { write(ios, v) } }
    }

    /// What to upload: the account's last row with this device's keys on top, so
    /// keys only the web writes (locale, theme, celebrations) are never dropped.
    static func payload(local: SyncData, lastCloud: SyncData) -> SyncData {
        lastCloud.merging(local) { _, l in l }
    }
}
