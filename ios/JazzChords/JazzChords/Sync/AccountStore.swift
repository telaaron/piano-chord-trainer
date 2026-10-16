// AccountStore — the signed-in JazzChords account (same Supabase users as the
// website). Sign in with Apple or e-mail; the session lives in the Keychain and
// is restored on launch. Every sign-in hands the user to SyncService, which
// merges this device with the account before anything is uploaded.

import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class AccountStore {
    static let shared = AccountStore()

    private(set) var email: String?
    private(set) var userId: String?
    /// Plain-German problem to show under the sign-in buttons.
    var error: String?
    /// Plain-German note that isn't an error ("check your mail").
    var info: String?
    private(set) var isWorking = false

    var isSignedIn: Bool { userId != nil }

    private let client = SupabaseConfig.client
    private let sync = SyncService.shared
    private var listener: Task<Void, Never>?

    private init() {}

    /// Restore the saved session and follow sign-in / sign-out from now on.
    func start() {
        guard listener == nil else { return }
        listener = Task { [weak self] in
            guard let changes = self?.client.auth.authStateChanges else { return }
            for await (event, session) in changes {
                await self?.handle(event, session)
            }
        }
    }

    private func handle(_ event: AuthChangeEvent, _ session: Session?) async {
        switch event {
        case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
            guard let user = session?.user else { signedOutLocally(); return }
            let id = user.id.uuidString.lowercased()
            email = user.email
            if case .bool(true)? = user.userMetadata["onboarding_done"] {
                HabitStore.shared.markOnboardingDone()
            }
            if userId != id {
                userId = id
                await sync.hydrate(userId: id)
            }
        case .signedOut, .userDeleted:
            signedOutLocally()
        default:
            break
        }
    }

    private func signedOutLocally() {
        userId = nil
        email = nil
        sync.reset()
    }

    // MARK: Sign in

    /// Sign in with Apple: `nonce` is the raw nonce whose SHA-256 went into the Apple request.
    func signInWithApple(idToken: String, nonce: String) async {
        await run(fallback: Self.failed) {
            try await self.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce))
        }
    }

    func signIn(email: String, password: String) async {
        await run(fallback: Self.wrongPassword) {
            try await self.client.auth.signIn(email: email.trimmed, password: password)
        }
    }

    func signUp(email: String, password: String) async {
        await run(fallback: Self.failed) {
            let response = try await self.client.auth.signUp(email: email.trimmed, password: password)
            if response.session == nil {
                self.info = Strings.pick("Check your inbox and confirm your e-mail, then sign in.",
                                         "Schau in dein Postfach und bestätige deine E-Mail, dann melde dich an.")
            }
        }
    }

    /// Sends the website's reset mail; the new password is set on jazzchords.app.
    func resetPassword(email: String) async {
        await run(fallback: Self.failed) {
            try await self.client.auth.resetPasswordForEmail(
                email.trimmed, redirectTo: SupabaseConfig.site.appending(path: "auth/reset-password"))
            self.info = Strings.pick("We sent you a link to set a new password.",
                                     "Wir haben dir einen Link für ein neues Passwort geschickt.")
        }
    }

    func signOut() async {
        try? await client.auth.signOut(scope: .local)
        signedOutLocally()
    }

    /// Deletes the account and its data on the server (App Store guideline
    /// 5.1.1(v)); this device keeps its own practice data.
    func deleteAccount() async {
        await run(fallback: Self.failed) {
            let token = try await self.client.auth.session.accessToken
            var request = URLRequest(url: SupabaseConfig.site.appending(path: "api/account/delete"))
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw DeleteFailed() }
            await self.signOut()
        }
    }

    /// Mirrors the web: once onboarding is done on any device, it never shows again.
    func noteOnboardingDone() async {
        guard isSignedIn else { return }
        _ = try? await client.auth.update(user: UserAttributes(data: ["onboarding_done": .bool(true)]))
    }

    // MARK: Apple nonce

    /// A random nonce for the Apple request; pass `sha256(nonce)` to Apple and the raw one here.
    nonisolated static func makeNonce(length: Int = 32) -> String {
        let chars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in chars.randomElement(using: &generator)! })
    }

    nonisolated static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: Errors

    private struct DeleteFailed: Error {}

    nonisolated static var wrongPassword: String { Strings.pick("E-mail or password is wrong", "E-Mail oder Passwort stimmt nicht") }
    nonisolated static var offline: String { Strings.pick("No connection", "Keine Verbindung") }
    nonisolated static var failed: String { Strings.pick("Sign-in failed", "Anmeldung fehlgeschlagen") }

    /// `URLError` means the network; anything else gets the action's own message.
    nonisolated static func message(for error: Error, fallback: String) -> String {
        error is URLError ? offline : fallback
    }

    private func run(fallback: String, _ action: @escaping () async throws -> Void) async {
        error = nil
        info = nil
        isWorking = true
        defer { isWorking = false }
        do { try await action() } catch {
            self.error = Self.message(for: error, fallback: fallback)
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
