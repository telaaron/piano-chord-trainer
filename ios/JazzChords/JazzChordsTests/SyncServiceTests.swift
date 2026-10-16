import XCTest
@testable import JazzChords

/// A scripted account row: records every upload, can be told to fail.
private actor FakeRemote: RemoteUserData {
    var row: [String: SyncData] = [:]
    var upserts: [(String, SyncData)] = []
    var fetchError: Error?
    var upsertError: Error?

    func fetch(userId: String) async throws -> SyncData? {
        if let fetchError { throw fetchError }
        return row[userId]
    }

    func upsert(userId: String, data: SyncData) async throws {
        if let upsertError { throw upsertError }
        upserts.append((userId, data))
        row[userId] = data
    }

    func set(row data: SyncData, for user: String) { row[user] = data }
    func failFetch(_ e: Error?) { fetchError = e }
    func failUpsert(_ e: Error?) { upsertError = e }
}

@MainActor
final class SyncServiceTests: XCTestCase {
    private struct Boom: Error {}
    private var files: [String: JSONValue] = [:]
    private var remote = FakeRemote()

    private func session(_ id: String, _ ts: Double) -> JSONValue {
        .object(["id": .string(id), "timestamp": .number(ts)])
    }

    private func makeService() -> SyncService {
        SyncService(remote: remote,
                    read: { [unowned self] in self.files[$0] },
                    write: { [unowned self] in self.files[$0] = $1 },
                    debounce: .zero)
    }

    override func setUp() {
        files = [:]
        remote = FakeRemote()
    }

    func testHydrateMergesAndUploadsUnion() async {
        files["history"] = .array([session("ipad", 2)])
        await remote.set(row: ["chord-trainer-history": .array([session("web", 1)]),
                               "chord-trainer-locale": .string("de")], for: "u1")
        let sync = makeService()

        let ok = await sync.hydrate(userId: "u1")

        XCTAssertTrue(ok)
        XCTAssertEqual(files["history"], .array([session("ipad", 2), session("web", 1)]))
        let upserts = await remote.upserts
        XCTAssertEqual(upserts.count, 1)
        XCTAssertEqual(upserts.first?.1["chord-trainer-history"], files["history"])
        XCTAssertEqual(upserts.first?.1["chord-trainer-locale"], .string("de"))
    }

    func testFailedHydrateNeverUploads() async {
        files["history"] = .array([session("local", 1)])
        await remote.failFetch(Boom())
        let sync = makeService()

        let ok = await sync.hydrate(userId: "u1")
        sync.markDirty()
        await sync.flush()

        XCTAssertFalse(ok)
        XCTAssertEqual(files["history"], .array([session("local", 1)]))
        let count = await remote.upserts.count
        XCTAssertEqual(count, 0)
        XCTAssertEqual(sync.status, .failed)
    }

    func testNoUploadBeforeHydrate() async {
        files["history"] = .array([session("local", 1)])
        let sync = makeService()
        sync.markDirty()
        await sync.flush()
        let count = await remote.upserts.count
        XCTAssertEqual(count, 0)
    }

    func testFailedUploadStaysDirtyAndRetries() async {
        let sync = makeService()
        _ = await sync.hydrate(userId: "u1")
        await remote.failUpsert(Boom())
        files["history"] = .array([session("new", 5)])
        sync.markDirty()
        await sync.flush()
        XCTAssertTrue(sync.isDirty)

        await remote.failUpsert(nil)
        await sync.flush()
        XCTAssertFalse(sync.isDirty)
        let last = await remote.upserts.last?.1
        XCTAssertEqual(last?["chord-trainer-history"], .array([session("new", 5)]))
    }

    func testSignOutResetsHydration() async {
        let sync = makeService()
        _ = await sync.hydrate(userId: "a")
        let before = await remote.upserts.count
        sync.reset()
        files["history"] = .array([session("after-signout", 9)])
        sync.markDirty()
        await sync.flush()
        let after = await remote.upserts.count
        XCTAssertEqual(after, before)
        XCTAssertEqual(sync.status, .idle)
    }

    func testPullMergesRemoteChanges() async {
        let sync = makeService()
        _ = await sync.hydrate(userId: "u1")
        // Meanwhile the browser practiced.
        await remote.set(row: ["chord-trainer-history": .array([session("browser", 7)])], for: "u1")
        await sync.pull()
        XCTAssertEqual(files["history"], .array([session("browser", 7)]))
    }

    func testOnlySyncedKeysMarkDirty() {
        XCTAssertTrue(SyncService.isSynced(key: "history"))
        XCTAssertFalse(SyncService.isSynced(key: "plan-history"))
    }
}
