// RemoteUserData — the account's `user_data` row (one jsonb blob per user, the
// same row the web writes). A protocol so SyncService can be tested offline.

import Foundation
import Supabase

protocol RemoteUserData: Sendable {
    func fetch(userId: String) async throws -> SyncData?
    func upsert(userId: String, data: SyncData) async throws
}

struct SupabaseUserData: RemoteUserData {
    private struct Row: Codable, Sendable {
        var user_id: String
        var data: SyncData
        var updated_at: String
    }

    private struct DataOnly: Decodable { var data: SyncData }

    func fetch(userId: String) async throws -> SyncData? {
        let rows: [DataOnly] = try await SupabaseConfig.client
            .from("user_data")
            .select("data")
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first?.data
    }

    func upsert(userId: String, data: SyncData) async throws {
        let row = Row(user_id: userId, data: data,
                      updated_at: ISO8601DateFormatter().string(from: Date()))
        try await SupabaseConfig.client
            .from("user_data")
            .upsert(row, onConflict: "user_id")
            .execute()
    }
}
