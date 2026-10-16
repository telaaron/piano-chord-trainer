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
        /// "ios-1.0.0" in release builds, "ios-dev" in debug, so dev traffic can be filtered out.
        static let version: String = {
            #if DEBUG
            return "ios-dev"
            #else
            let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
            return "ios-\(v)"
            #endif
        }()
    }

    private let flushBatchSize = 10

    private var queue: [[String: Any]] = []
    private let session = URLSession(configuration: .ephemeral)

    private init() {}

    // ─── Device ID + consent (persisted) ────────────────────

    private static let deviceIdKey = "coach-device-id"
    /// Opt-in: nothing is sent and no device ID exists until the user agrees
    /// (onboarding or Settings). Missing key = no consent.
    private static let consentKey = "coach-telemetry-consent"

    /// Anonymous, stable, per-install device UUID (persisted in UserDefaults).
    /// Only created on the first tracked event, i.e. after consent.
    private var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: Self.deviceIdKey) {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: Self.deviceIdKey)
        return id
    }

    /// Whether the user has opted in.
    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.consentKey)
    }

    /// Opt in (`true`) or out (`false`). Opting out drops anything queued and
    /// forgets the device ID, so a later opt-in starts as a new anonymous device.
    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.consentKey)
        if !enabled {
            queue.removeAll()
            UserDefaults.standard.removeObject(forKey: Self.deviceIdKey)
        }
    }

    // ─── Tracking ───────────────────────────────────────────

    /// Queue a coach event. Flushed in batches (at `flushBatchSize`, or on flush()).
    /// No-op when disabled at build time or without consent. Never throws.
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
