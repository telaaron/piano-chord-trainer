// TelemetryService — anonymous, batched Coach-Lab telemetry for iOS.
//
// Mirrors src/lib/services/telemetry.ts: events are queued in memory and flushed
// as one batched INSERT to Supabase's REST endpoint (/rest/v1/coach_events). It
// NEVER throws and NEVER blocks the practice flow — every failure is swallowed.
//
// Supabase config: the Web app ships PUBLIC_SUPABASE_URL + PUBLIC_SUPABASE_ANON_KEY
// to every browser (they are publishable client keys, gated server-side by RLS —
// anon may only INSERT into coach_events). The iOS target had no Supabase config
// of its own, so the same publishable values live in `Config` below. Set
// `Config.enabled = false` (or leave URL/anonKey empty) to run fully disabled.
//
// Event contract: docs/coach-tuning-playbook.md §2. app = "ios".

import Foundation

@MainActor
final class TelemetryService {
    static let shared = TelemetryService()

    // ─── Supabase config ────────────────────────────────────
    // Publishable client values (same as the web app's PUBLIC_* env). RLS on
    // coach_events restricts anon to INSERT only. To disable telemetry entirely
    // at build time, set `enabled = false` or blank the URL/anonKey.
    private enum Config {
        static let enabled = true
        static let url = "https://chpoqghvlojwyunoplab.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNocG9xZ2h2bG9qd3l1bm9wbGFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNzAyODIsImV4cCI6MjA4ODY0NjI4Mn0.r_1JeIDnRpKiTWn74bCHBFUU7kOu4YSPFY9QRjrdPX0"
        static let cohort = "default"
        static let version = "ios-dev"
    }

    private let flushBatchSize = 10

    private var queue: [[String: Any]] = []
    private let session = URLSession(configuration: .ephemeral)

    private init() {}

    // ─── Device ID + opt-out (persisted) ────────────────────

    private static let deviceIdKey = "coach-device-id"
    private static let optOutKey = "coach-telemetry-optout"

    /// Anonymous, stable, per-install device UUID (persisted in UserDefaults).
    private var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: Self.deviceIdKey) {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: Self.deviceIdKey)
        return id
    }

    /// Whether telemetry is currently enabled (user has NOT opted out).
    var isEnabled: Bool {
        !UserDefaults.standard.bool(forKey: Self.optOutKey)
    }

    /// Opt in (`true`) or out (`false`). Opting out drops anything queued.
    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(!enabled, forKey: Self.optOutKey)
        if !enabled { queue.removeAll() }
    }

    // ─── Tracking ───────────────────────────────────────────

    /// Queue a coach event. Flushed in batches (at `flushBatchSize`, or on flush()).
    /// No-op when disabled at build time or by opt-out. Never throws.
    func track(_ eventType: String, _ payload: [String: Any] = [:]) {
        guard Config.enabled, !Config.url.isEmpty, !Config.anonKey.isEmpty else { return }
        guard isEnabled else { return }

        let row: [String: Any] = [
            "device_id": deviceId,
            "user_id": NSNull(),
            "app": "ios",
            "version": Config.version,
            "cohort": Config.cohort,
            "event_type": eventType,
            "payload": payload,
        ]
        queue.append(row)
        if queue.count >= flushBatchSize { flush() }
    }

    /// Flush the in-memory queue as a single batched insert. Swallows all errors.
    func flush() {
        guard Config.enabled, !Config.url.isEmpty, !Config.anonKey.isEmpty else { return }
        guard isEnabled, !queue.isEmpty else { return }

        let batch = queue
        queue.removeAll()

        guard let endpoint = URL(string: "\(Config.url)/rest/v1/coach_events"),
              let body = try? JSONSerialization.data(withJSONObject: batch)
        else { return }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(Config.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = body

        // Best-effort: never re-queue (avoids unbounded growth on persistent errors).
        session.dataTask(with: req).resume()
    }
}
