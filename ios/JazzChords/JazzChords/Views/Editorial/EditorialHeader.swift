// Eyebrow (SF Mono) + serif large title. Replaces the navigation-bar title on
// tab-root screens; an optional trailing control sits on the eyebrow row.

import SwiftUI

struct EditorialHeader<Trailing: View>: View {
    @Environment(\.palette) private var palette
    let eyebrow: String?
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    init(eyebrow: String? = nil, title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.eyebrow = eyebrow
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                if let eyebrow {
                    EyebrowText(eyebrow)
                }
                Text(title)
                    .font(Display.serif(44))
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: Theme.space3)
            trailing()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension EditorialHeader where Trailing == EmptyView {
    init(eyebrow: String? = nil, title: String) {
        self.init(eyebrow: eyebrow, title: title) { EmptyView() }
    }
}

/// Small uppercase monospaced label above titles and sections.
struct EyebrowText: View {
    @Environment(\.palette) private var palette
    let text: String
    var color: Color? = nil

    init(_ text: String, color: Color? = nil) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(Display.eyebrow())
            .tracking(1)
            .foregroundStyle(color ?? palette.inkMuted)
    }
}

#Preview("Header dark") {
    EditorialHeader(eyebrow: "Do · 15. Okt / Session 07", title: "Heute") {
        GlassCircleButton(systemImage: "slider.horizontal.3", label: "Einstellungen") {}
    }
    .padding(20)
    .background(Palette.dark.canvas)
    .environment(\.palette, .dark)
}
