// The one red block per screen: eyebrow, content, action, optional ghost chord.

import SwiftUI

struct FeatureBlock<Content: View, Action: View>: View {
    @Environment(\.palette) private var palette
    let eyebrow: String
    var ghost: String? = nil
    @ViewBuilder var content: () -> Content
    @ViewBuilder var action: () -> Action

    init(eyebrow: String, ghost: String? = nil,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder action: @escaping () -> Action) {
        self.eyebrow = eyebrow
        self.ghost = ghost
        self.content = content
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            EyebrowText(eyebrow, color: palette.featureAccent)
            content()
            action()
                .padding(.top, Theme.space1)
        }
        .foregroundStyle(palette.onFeature)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottomTrailing) {
            if let ghost {
                Text(ghost)
                    .font(Display.chord(170, relativeTo: .body))
                    // Faint enough not to fight the text over it.
                    .foregroundStyle(palette.onFeature.opacity(0.08))
                    .lineLimit(1)
                    .fixedSize()
                    .offset(x: 8, y: 44)
                    .accessibilityHidden(true)
            }
        }
        .background(palette.feature)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusFeature, style: .continuous))
    }
}

extension FeatureBlock where Action == EmptyView {
    init(eyebrow: String, ghost: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.init(eyebrow: eyebrow, ghost: ghost, content: content) { EmptyView() }
    }
}

#Preview("Feature") {
    FeatureBlock(eyebrow: "Heute dran · 5 Min · 24 Akkorde", ghost: "Δ7") {
        Text("ii–V–I in B♭, zum ersten Mal ohne Grundton.")
            .font(Display.serif(20, italic: true))
    } action: {
        PrimaryCapsule(title: "Weiter üben", systemImage: "play.fill", inverted: true) {}
    }
    .padding(16)
    .background(Palette.dark.canvas)
    .environment(\.palette, .dark)
}
