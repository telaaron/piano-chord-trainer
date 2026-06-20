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

/// Empty state — large glyph in a soft amber halo + display title + message.
struct EmptyStateView: View {
    @Environment(\.palette) private var palette
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.space4) {
            ZStack {
                Circle()
                    .fill(palette.primary.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .regular))
                    .foregroundStyle(palette.primary)
                    .symbolRenderingMode(.hierarchical)
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

/// A warm "jazz-club at night" gradient band — used behind the Today header and
/// as a lightweight hero until rendered art lands. Abstract key-light streaks.
struct HeroGradient: View {
    var height: CGFloat = 150

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Base radial glow + linear depth.
            LinearGradient(
                colors: [Color(hex: "1a1530"), Color(hex: "120e26"), Color(hex: "0c0a18")],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(hex: "f5a623").opacity(0.28), .clear],
                center: .init(x: 0.82, y: 0.2), startRadius: 4, endRadius: height * 1.4
            )
            // Abstract "white key" light streaks.
            GeometryReader { geo in
                let w = geo.size.width
                ForEach(0..<6, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.04 + Double(i) * 0.006))
                        .frame(width: 2)
                        .offset(x: w * 0.55 + CGFloat(i) * 16, y: 0)
                        .rotationEffect(.degrees(18))
                }
            }
        }
        .frame(height: height)
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
}
