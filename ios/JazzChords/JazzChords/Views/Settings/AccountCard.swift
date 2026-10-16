// Account card at the top of Settings (row F): dark ink block, gold eyebrow.
// Signed out it pitches cross-device progress; signed in it shows the e-mail,
// the sync state, sign-out and account deletion (App Store 5.1.1(v)).
//
// The card is presentation only: auth and sync arrive through `AccountCardModel`
// so the view does not depend on how accounts are implemented.

import SwiftUI
import AuthenticationServices

enum SyncStatusLine: Equatable {
    case synced(Date), syncing, offline, never

    var text: String {
        switch self {
        case .synced(let date):
            return SettingsText.synced(at: date.formatted(date: .omitted, time: .shortened))
        case .syncing: return SettingsText.syncing
        case .offline: return SettingsText.offline
        case .never: return SettingsText.notSynced
        }
    }
}

enum AccountCardState: Equatable {
    case signedOut
    case signedIn(email: String, sync: SyncStatusLine)
}

/// What the card needs from the account layer.
struct AccountCardModel {
    var state: AccountCardState = .signedOut
    var configureAppleRequest: (ASAuthorizationAppleIDRequest) -> Void = { _ in }
    var completeApple: (Result<ASAuthorization, Error>) -> Void = { _ in }
    var openEmailSignIn: () -> Void = {}
    var signOut: () -> Void = {}
    var deleteAccount: () -> Void = {}
}

struct AccountCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var scheme
    let model: AccountCardModel
    @State private var confirmDelete = false

    // Dark ink block in both schemes (light: ink on paper; dark: the lifted group).
    private var block: Color { scheme == .dark ? palette.group : palette.ink }
    private var onBlock: Color { scheme == .dark ? palette.ink : palette.canvas }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            Text(SettingsText.accountEyebrow)
                .font(.footnote.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(palette.music)

            switch model.state {
            case .signedOut:
                signedOut
            case .signedIn(let email, let sync):
                signedIn(email: email, sync: sync)
            }
        }
        .padding(Theme.space5 - 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Ghost chord sits behind the content so it never covers a button.
        .background(alignment: .topTrailing) {
            Text("Δ7")
                .font(Display.chord(110, relativeTo: .largeTitle))
                .foregroundStyle(palette.music.opacity(0.14))
                .offset(x: 8, y: -18)
                .accessibilityHidden(true)
        }
        .background(block, in: RoundedRectangle(cornerRadius: Theme.radiusFeature, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusFeature, style: .continuous))
        .confirmationDialog(SettingsText.deleteConfirmTitle, isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(SettingsText.deleteAccount, role: .destructive) { model.deleteAccount() }
            Button(SettingsText.cancel, role: .cancel) {}
        } message: {
            Text(SettingsText.deleteConfirmMessage)
        }
    }

    @ViewBuilder private var signedOut: some View {
        Text(SettingsText.accountPitch)
            .font(Display.serif(26, relativeTo: .title2))
            .foregroundStyle(onBlock)
            .fixedSize(horizontal: false, vertical: true)

        SignInWithAppleButton(.signIn,
                              onRequest: model.configureAppleRequest,
                              onCompletion: model.completeApple)
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(Capsule())
            .padding(.top, Theme.space1)

        Button(action: model.openEmailSignIn) {
            Text(SettingsText.signInEmail)
                .font(.body.weight(.semibold))
                .foregroundStyle(onBlock)
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay(Capsule().strokeBorder(onBlock.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)

        Text(SettingsText.sameAccount)
            .font(.footnote)
            .foregroundStyle(onBlock.opacity(0.75))
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func signedIn(email: String, sync: SyncStatusLine) -> some View {
        HStack(spacing: Theme.space3) {
            Text(ProfileCircleButton.initial(for: email) ?? "?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(block)
                .frame(width: 44, height: 44)
                .background(palette.music, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(email)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(onBlock)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(sync.text)
                    .font(.footnote)
                    .foregroundStyle(onBlock.opacity(0.75))
            }
        }
        HStack(spacing: Theme.space3) {
            Button(action: model.signOut) {
                Text(SettingsText.signOut)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(block)
                    .padding(.horizontal, Theme.space5)
                    .frame(minHeight: 44)
                    .background(onBlock, in: Capsule())
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            Button(role: .destructive) { confirmDelete = true } label: {
                Text(SettingsText.deleteAccount)
                    .font(.subheadline)
                    .foregroundStyle(onBlock.opacity(0.8))
                    .underline()
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, Theme.space1)
    }
}

/// The single entry to Settings: a 44 pt circle on Heute, top right. Shows the
/// account's initial when signed in, a person glyph otherwise.
struct ProfileCircleButton: View {
    @Environment(\.palette) private var palette
    var email: String? = nil
    let action: () -> Void

    nonisolated static func initial(for email: String?) -> String? {
        guard let first = email?.trimmingCharacters(in: .whitespaces).first else { return nil }
        return String(first).uppercased()
    }

    var body: some View {
        Button(action: action) {
            Group {
                if let initial = Self.initial(for: email) {
                    Text(initial).font(.headline)
                } else {
                    Image(systemName: "person").font(.system(size: 18, weight: .medium))
                }
            }
            .foregroundStyle(palette.ink)
            .frame(width: 44, height: 44)
            .background(palette.music.opacity(0.18), in: Circle())
            .overlay(Circle().strokeBorder(palette.hairline.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(SettingsText.profileLabel)
    }
}

#Preview("Account card") {
    VStack(spacing: 16) {
        AccountCard(model: AccountCardModel())
        AccountCard(model: AccountCardModel(state: .signedIn(email: "aaron@example.com", sync: .synced(.now))))
    }
    .padding()
    .background(Palette.light.canvas)
    .environment(\.palette, .light)
}
