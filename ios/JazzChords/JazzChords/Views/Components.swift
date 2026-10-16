// Shared UI building blocks — grouped content surface, section header, empty
// state. Editorial look: content sits on plain inset groups (no glass — glass
// is for controls only), headings in the serif, eyebrows in SF Mono.

import SwiftUI

/// A plain inset-group surface for content (radius 22, `group` colour).
struct GroupSurface<Content: View>: View {
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
            .groupSurface()
    }
}

/// Section heading — SF Mono eyebrow, as in the editorial screens.
struct SectionHeader: View {
    let text: String
    var body: some View {
        EyebrowText(text)
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
                    Circle().fill(palette.action.opacity(0.12)).frame(width: 120, height: 120)
                    Image(systemName: systemImage)
                        .font(.system(size: 48, weight: .regular))
                        .foregroundStyle(palette.action)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            Text(title)
                .font(Display.headline(22))
                .foregroundStyle(palette.ink)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.inkMuted)
                .padding(.horizontal, Theme.space6)
        }
        .frame(maxWidth: 380)
        .padding(Theme.space6)
    }
}

/// Plain content surface used by `GroupSurface` and ex-card call sites.
struct GroupSurfaceModifier: ViewModifier {
    @Environment(\.palette) private var palette
    var cornerRadius: CGFloat = Theme.radiusGroup

    func body(content: Content) -> some View {
        content.background(palette.group, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Background that reaches every edge.
struct ScreenBackground: ViewModifier {
    @Environment(\.palette) private var palette
    func body(content: Content) -> some View {
        content.background(palette.canvas.ignoresSafeArea())
    }
}

extension View {
    func screenBackground() -> some View { modifier(ScreenBackground()) }
    func groupSurface(cornerRadius: CGFloat = Theme.radiusGroup) -> some View {
        modifier(GroupSurfaceModifier(cornerRadius: cornerRadius))
    }
    /// Constrain content to a comfortable reading width, centered (great on iPad).
    func readableWidth(_ max: CGFloat = 640) -> some View {
        frame(maxWidth: max).frame(maxWidth: .infinity)
    }
}
