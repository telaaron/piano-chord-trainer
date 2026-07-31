// Shared UI building blocks — glass card surface, section header, empty state,
// hero gradient band, level badge helpers. Visual language: Midnight Indigo +
// amber, Liquid Glass surfaces, Space Grotesk for headings.

import SwiftUI

/// A glass card surface (Liquid Glass on iOS 26+, material fallback).
struct CardSurface<Content: View>: View {
    var padding: CGFloat = Theme.space4
    var tint: Color? = nil
    var content: () -> Content

    init(padding: CGFloat = Theme.space4, tint: Color? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.tint = tint
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(tint: tint)
    }
}

/// Section heading — display face, generous weight.
struct SectionHeader: View {
    @Environment(\.palette) private var palette
    let text: String
    var body: some View {
        Text(text)
            .font(Display.headline(19))
            .foregroundStyle(palette.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Empty state — rendered art (if `artName` present in bundle) or an SF glyph in
/// an amber halo, plus a display title + message.
struct EmptyStateView: View {
    @Environment(\.palette) private var palette
    let systemImage: String
    let title: String
    let message: String
    var artName: String? = nil

    private func art(_ name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "webp"),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        VStack(spacing: Theme.space4) {
            if let artName, let img = art(artName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
            } else {
                ZStack {
                    Circle().fill(palette.primary.opacity(0.12)).frame(width: 120, height: 120)
                    Image(systemName: systemImage)
                        .font(.system(size: 48, weight: .regular))
                        .foregroundStyle(palette.primary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            Text(title)
                .font(Display.headline(22))
                .foregroundStyle(palette.text)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.textMuted)
                .padding(.horizontal, Theme.space6)
        }
        .frame(maxWidth: 380)
        .padding(Theme.space6)
    }
}

/// Atmospheric "jazz-club at night" hero band. Uses the rendered art if present
/// in the bundle; otherwise a code gradient with key-light streaks. A bottom
/// scrim keeps overlaid text legible.
struct HeroGradient: View {
    var height: CGFloat = 168

    private var heroImage: UIImage? {
        if let url = Bundle.main.url(forResource: "hero2", withExtension: "webp"),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let img = heroImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                // Night pressroom, matching the web hero. Deliberately dark in
                // both schemes: this panel always carries light text over it, so
                // it does not follow the active palette the way surfaces do.
                LinearGradient(
                    colors: [Color(hex: "1c2735"), Color(hex: "151d29"), Color(hex: "0e141d")],
                    startPoint: .top, endPoint: .bottom
                )
                RadialGradient(
                    colors: [Palette.dark.stamp.opacity(0.28), .clear],
                    center: .init(x: 0.82, y: 0.2), startRadius: 4, endRadius: height * 1.4
                )
            }
            // Scrim for text legibility.
            LinearGradient(
                colors: [.clear, Color(hex: "0e141d").opacity(0.75)],
                startPoint: .center, endPoint: .bottom
            )
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
    }
}

/// Background that reaches every edge.
struct ScreenBackground: ViewModifier {
    @Environment(\.palette) private var palette
    func body(content: Content) -> some View {
        content.background(palette.bg.ignoresSafeArea())
    }
}

extension View {
    func screenBackground() -> some View { modifier(ScreenBackground()) }
    /// Constrain content to a comfortable reading width, centered (great on iPad).
    func readableWidth(_ max: CGFloat = 640) -> some View {
        frame(maxWidth: max).frame(maxWidth: .infinity)
    }
}
