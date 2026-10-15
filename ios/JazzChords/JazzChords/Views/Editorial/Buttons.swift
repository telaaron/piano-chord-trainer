// Primary capsule (red, the one main action), glass circle (toolbar), glass
// secondary capsule. Glass only on controls — spec §3.3.

import SwiftUI

struct PrimaryCapsule: View {
    @Environment(\.palette) private var palette
    let title: String
    var systemImage: String? = nil
    /// Inverted variant for use on top of a red FeatureBlock.
    var inverted: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.space2) {
                if let systemImage {
                    Image(systemName: systemImage).font(.subheadline.weight(.bold))
                }
                Text(title).font(.body.weight(.semibold))
            }
            .frame(maxWidth: inverted ? nil : .infinity)
            .frame(minHeight: inverted ? 44 : 56)
            .padding(.horizontal, Theme.space5)
            .foregroundStyle(inverted ? palette.action : palette.onAction)
            .background(inverted ? palette.onAction : palette.action, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct GlassCircleButton: View {
    @Environment(\.palette) private var palette
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: Theme.tapMin, height: Theme.tapMin)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassControl(in: Circle())
        .accessibilityLabel(label)
    }
}

struct GlassSecondaryButton: View {
    @Environment(\.palette) private var palette
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(palette.ink)
                .padding(.horizontal, Theme.space5)
                .frame(minHeight: 56)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassControl(in: Capsule())
    }
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        HStack { GlassSecondaryButton(title: "Tipp") {}; PrimaryCapsule(title: "Nochmal spielen") {} }
        GlassCircleButton(systemImage: "xmark", label: "Schließen") {}
    }
    .padding(20)
    .background(Palette.light.canvas)
    .environment(\.palette, .light)
}
