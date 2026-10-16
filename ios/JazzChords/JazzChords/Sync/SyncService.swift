// SyncService — keeps this device's stores and the account's `user_data` row in
// step, by the same rules as the web's cloud-sync.ts: merge on sign-in
// (hydrate), never upload before that merge succeeded for this user, debounce
// uploads, and upsert the whole row. Pulls again whenever the app comes back,
// so the iPad sees what the iPhone or browser did meanwhile.

import Foundation
import Observation

@MainActor
@Observable
final class SyncService {
    enum Status: Equatable { case idle, syncing, synced(Date), offline, failed }

    static let shared = SyncService(remote: SupabaseUserData(),
                                    read: Store.loadRaw,
                                    write: Store.saveRaw)

    private(set) var status: Status = .idle
    /// Bumped whenever account data changed this device's stores; views reload on it.
    private(set) var revision = 0
    private(set) var isDirty = false
    /// Called after account data was written into the stores, to reload them.
    var onApplied: (() -> Void)?

    private let remote: RemoteUserData
    private let read: (String) -> JSONValue?
    private let write: (String, JSONValue) -> Void
    private let debounce: Duration

    private var currentUser: String?
    private var hydratedFor: String?
    private var lastCloud: SyncData = [:]
    private var applying = false
    private var pending: Task<Void, Never>?
    private var inFlight: Task<Void, Never>?

    /// `debounce: .zero` schedules nothing; the caller flushes (tests).
    init(remote: RemoteUserData,
         read: @escaping (String) -> JSONValue?,
         write: @escaping (String, JSONValue) -> Void,
         debounce: Duration = .seconds(3)) {
        self.remote = remote
        self.read = read
        self.write = write
        self.debounce = debounce
    }

    nonisolated static func isSynced(key: String) -> Bool { SyncKeys.map[key] != nil }

    /// Signed in as `userId`: merge the account with this device, write the
    /// result to the stores, upload the union. False if the account couldn't be
    /// read; then nothing is written or uploaded.
    @discardableResult
    func hydrate(userId: String) async -> Bool {
        currentUser = userId
        hydratedFor = nil
        status = .syncing
        let cloud: SyncData
        do { cloud = try await remote.fetch(userId: userId) ?? [:] } catch {
            if currentUser == userId { status = .failed }
            return false
        }
        guard currentUser == userId else { return false } // signed out meanwhile
        let merged = SyncMerge.merge(local: SyncKeys.snapshot(read: read), cloud: cloud)
        applyToStores(merged)
        lastCloud = cloud
        hydratedFor = userId
        isDirty = SyncKeys.payload(local: merged, lastCloud: cloud) != cloud
        if isDirty { await flush() } else { status = .synced(Date()) }
        return true
    }

    /// A synced store was saved: upload soon.
    func markDirty() {
        guard !applying else { return }
        isDirty = true
        guard debounce > .zero else { return }
        pending?.cancel()
        let wait = debounce
        pending = Task { [weak self] in
            try? await Task.sleep(for: wait)
            guard !Task.isCancelled else { return }
            await self?.flush()
        }
    }

    /// Upload now if there is something to upload and the merge has happened.
    func flush() async {
        if let running = inFlight { await running.value }
        guard isDirty, let user = currentUser, hydratedFor == user else { return }
        let task = Task { await upload(user) }
        inFlight = task
        await task.value
        if inFlight == task { inFlight = nil }
    }

    /// App came back: send what's waiting, then take in what other devices did.
    func pull() async {
        guard let user = currentUser else { return }
        guard hydratedFor == user else { await hydrate(userId: user); return }
        await flush()
        let cloud: SyncData
        do { cloud = try await remote.fetch(userId: user) ?? [:] } catch {
            status = .offline
            return
        }
        guard currentUser == user else { return }
        let merged = SyncMerge.merge(local: SyncKeys.snapshot(read: read), cloud: cloud)
        applyToStores(merged)
        lastCloud = cloud
        if SyncKeys.payload(local: merged, lastCloud: cloud) != cloud {
            isDirty = true
            await flush()
        } else {
            status = .synced(Date())
        }
    }

    /// Signed out: stop syncing. Device data stays on the device.
    func reset() {
        pending?.cancel()
        pending = nil
        currentUser = nil
        hydratedFor = nil
        lastCloud = [:]
        isDirty = false
        status = .idle
    }

    /// Read, merge, write: the row is replaced whole, so merge in what other
    /// devices uploaded since our last look instead of overwriting it.
    private func upload(_ user: String) async {
        isDirty = false
        status = .syncing
        do {
            let cloud = try await remote.fetch(userId: user) ?? [:]
            guard currentUser == user else { return }
            let merged = SyncMerge.merge(local: SyncKeys.snapshot(read: read), cloud: cloud,
                                         preferLocal: true)
            applyToStores(merged)
            let payload = SyncKeys.payload(local: merged, lastCloud: cloud)
            try await remote.upsert(userId: user, data: payload)
            guard currentUser == user else { return }
            lastCloud = payload
            status = .synced(Date())
        } catch {
            guard currentUser == user else { return }
            isDirty = true
            status = .offline
        }
    }

    /// Write only what changed, without those writes marking the device dirty.
    private func applyToStores(_ data: SyncData) {
        var changed = false
        applying = true
        SyncKeys.apply(data) { key, value in
            if read(key) != value { write(key, value); changed = true }
        }
        applying = false
        if changed {
            revision += 1
            onApplied?()
        }
    }
}
