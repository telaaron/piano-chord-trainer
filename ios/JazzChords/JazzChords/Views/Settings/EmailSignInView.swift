// E-mail + password sign-in / sign-up sheet. Presentation only: the account
// layer passes `submit`, which returns an error message to show, or nil.

import SwiftUI

struct EmailSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    let submit: (_ email: String, _ password: String, _ createAccount: Bool) async -> String?

    @State private var email = ""
    @State private var password = ""
    @State private var creating = false
    @State private var busy = false
    @State private var error: String?

    private var canSubmit: Bool { email.contains("@") && password.count >= 6 && !busy }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space4) {
                Text(creating ? SettingsText.createAccount : SettingsText.signIn)
                    .font(Display.serif(40))
                    .foregroundStyle(palette.ink)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 0) {
                    TextField(SettingsText.email, text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, Theme.space4)
                        .frame(minHeight: 52)
                    Rectangle().fill(palette.hairline).frame(height: 0.5).padding(.leading, Theme.space4)
                    SecureField(SettingsText.password, text: $password)
                        .textContentType(creating ? .newPassword : .password)
                        .padding(.horizontal, Theme.space4)
                        .frame(minHeight: 52)
                }
                .background(palette.group, in: RoundedRectangle(cornerRadius: Theme.radiusGroup, style: .continuous))

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(palette.action)
                }

                PrimaryCapsule(title: creating ? SettingsText.createAccount : SettingsText.signIn) {
                    Task {
                        busy = true
                        error = await submit(email.trimmingCharacters(in: .whitespaces), password, creating)
                        busy = false
                        if error == nil { dismiss() }
                    }
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)

                Button(creating ? SettingsText.haveAccount : SettingsText.newHere) {
                    creating.toggle()
                    error = nil
                }
                .font(.subheadline)
                .tint(palette.ink)
                .frame(maxWidth: .infinity)
            }
            .padding(Theme.space5 - 4)
        }
        .background(palette.canvas)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(SettingsText.cancel) { dismiss() }.tint(palette.ink)
            }
        }
    }
}
