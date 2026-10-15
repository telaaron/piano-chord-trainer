// "Tracklist" row inside an inset group: gold Kalam badge or serif number,
// SF title, muted meta, optional chevron.

import SwiftUI

struct TrackGroup<Content: View>: View {
    @Environment(\.palette) private var palette
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) { content() }
            .background(palette.group)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusGroup, style: .continuous))
    }
}

struct TrackRow: View {
    @Environment(\.palette) private var palette
    var badge: String? = nil
    var number: String? = nil
    let title: String
    var meta: String? = nil
    var showsDivider: Bool = false
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: Theme.space3) {
            if let badge {
                Text(badge)
                    .font(Display.chord(18, relativeTo: .body))
                    .foregroundStyle(palette.music)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 44, alignment: .leading)
            } else if let number {
                Text(number)
                    .font(Display.serif(22, relativeTo: .body))
                    .foregroundStyle(palette.music)
                    .frame(width: 36, alignment: .leading)
            }
            HStack(spacing: Theme.space2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(palette.ink)
                Spacer(minLength: Theme.space2)
                if let meta {
                    Text(meta)
                        .font(.subheadline)
                        .foregroundStyle(palette.inkMuted)
                }
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(palette.inkMuted)
                }
            }
            .frame(minHeight: 52)
            .overlay(alignment: .bottom) {
                if showsDivider {
                    Rectangle().fill(palette.hairline).frame(height: 0.5)
                }
            }
        }
        .padding(.leading, Theme.space4)
        .padding(.trailing, Theme.space4)
        .contentShape(Rectangle())
    }
}

#Preview("Tracks") {
    TrackGroup {
        TrackRow(badge: "A/B", title: "Rootless Voicings", showsDivider: true)
        TrackRow(badge: "F♯7", title: "Schwachstellen", meta: "12", showsDivider: true)
        TrackRow(badge: "ii–V", title: "Turnaround", meta: "alle Tonarten")
    }
    .padding(16)
    .background(Palette.dark.canvas)
    .environment(\.palette, .dark)
}
