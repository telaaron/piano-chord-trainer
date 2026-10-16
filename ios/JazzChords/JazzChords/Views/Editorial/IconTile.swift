// One SF Symbol on a soft rounded square — the single icon style for Settings
// and Üben. An icon shows what you do; chord symbols are never icons.

import SwiftUI

struct IconTile: View {
    @Environment(\.palette) private var palette
    let systemImage: String
    var tint: Tint = .gold
    var size: CGFloat = 30

    enum Tint { case gold, red, slate }

    var body: some View {
        let fg = foreground
        Image(systemName: systemImage)
            .font(.system(size: size * 0.52, weight: .medium))
            .foregroundStyle(fg)
            .frame(width: size, height: size)
            .background(fg.opacity(0.16), in: RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
            .accessibilityHidden(true)
    }

    private var foreground: Color {
        switch tint {
        case .gold: return palette.music
        case .red: return palette.action
        case .slate: return palette.inkMuted
        }
    }
}

#Preview("Tiles") {
    HStack {
        IconTile(systemImage: "flame")
        IconTile(systemImage: "bell", tint: .red)
        IconTile(systemImage: "lock.shield", tint: .slate)
        IconTile(systemImage: "stopwatch", size: 32)
    }
    .padding()
    .environment(\.palette, .light)
}
