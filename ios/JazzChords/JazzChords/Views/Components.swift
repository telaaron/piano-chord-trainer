// Small shared UI building blocks (card surface, section header, empty state).
// Keep visuals consistent with the web "card"/"surface-glass" language.

import SwiftUI

/// A card surface — translucent fill + hairline border + soft radius.
struct CardSurface<Content: View>: View {
    @Environment(\.palette) private var palette
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        content()
            .padding(Theme.space4)
            .background(palette.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLg)
                    .stroke(palette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
    }
}

/// A placeholder / empty-state block: icon + title + message.
struct EmptyStateView: View {
    @Environment(\.palette) private var palette
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.space3) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(palette.primary)
            Text(title)
                .font(.headline)
                .foregroundStyle(palette.text)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.textMuted)
        }
        .frame(maxWidth: 360)
        .padding(Theme.space6)
    }
}

/// Section heading used inside scroll views.
struct SectionHeader: View {
    @Environment(\.palette) private var palette
    let text: String
    var body: some View {
        Text(text)
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(palette.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Background that reaches every edge (no strips under status bar / home indicator).
struct ScreenBackground: ViewModifier {
    @Environment(\.palette) private var palette
    func body(content: Content) -> some View {
        content.background(palette.bg.ignoresSafeArea())
    }
}

extension View {
    func screenBackground() -> some View { modifier(ScreenBackground()) }
}
