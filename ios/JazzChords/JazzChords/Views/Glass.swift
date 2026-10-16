// Liquid Glass for controls. On iOS 26+ uses the system .glassEffect(); older
// OSes fall back to a translucent material so the look degrades gracefully.

import SwiftUI

/// Liquid Glass for the controls layer only (toolbar circles, progress capsule,
/// secondary button, segment). Never on content — see spec §3.3.
struct GlassControlModifier<S: Shape>: ViewModifier {
    @Environment(\.palette) private var palette
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(palette.hairline.opacity(0.8), lineWidth: 0.5))
        }
    }
}

extension View {
    func glassControl<S: Shape>(in shape: S) -> some View {
        modifier(GlassControlModifier(shape: shape))
    }
}
