// Liquid Glass surfaces. On iOS 26+ uses the system .glassEffect(); older OSes
// fall back to a translucent material so the look degrades gracefully. Use for
// cards, the floating Next control, and grouped surfaces — accents, not every
// pixel (per HIG: glass floats above content, doesn't replace it).

import SwiftUI

struct GlassCardModifier: ViewModifier {
    @Environment(\.palette) private var palette
    var cornerRadius: CGFloat = Theme.radiusLg
    var tint: Color? = nil

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(palette.border.opacity(0.6), lineWidth: 0.5)
                )
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        if let tint { return .regular.tint(tint.opacity(0.18)).interactive() }
        return .regular.interactive()
    }
}

/// A rounded glass capsule (for the floating "Next" control).
struct GlassCapsuleModifier: ViewModifier {
    @Environment(\.palette) private var palette
    var tint: Color? = nil

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(tint.map { .regular.tint($0.opacity(0.25)).interactive() } ?? .regular.interactive(), in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(palette.border.opacity(0.6), lineWidth: 0.5))
        }
    }
}

extension View {
    /// Glass card surface (padding applied by caller).
    func glassCard(cornerRadius: CGFloat = Theme.radiusLg, tint: Color? = nil) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, tint: tint))
    }
    func glassCapsule(tint: Color? = nil) -> some View {
        modifier(GlassCapsuleModifier(tint: tint))
    }
}
