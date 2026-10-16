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
            // Fine edge so the group lifts off the night canvas.
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusGroup, style: .continuous)
                .strokeBorder(palette.hairline.opacity(0.6), lineWidth: 0.5))
    }
}

struct TrackRow: View {
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    var badge: String? = nil
    var number: String? = nil
    /// SF Symbol shown as an IconTile — what you do (never a chord symbol).
    var icon: String? = nil
    let title: String
    /// Plain-language line under the title.
    var subtitle: String? = nil
    var meta: String? = nil
    var showsDivider: Bool = false
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: Theme.space3) {
            if let icon {
                IconTile(systemImage: icon, size: 32)
            } else if let badge {
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
                if typeSize.isAccessibilitySize {
                    // Large type: meta wraps under the title instead of squeezing it.
                    VStack(alignment: .leading, spacing: 2) {
                        titleBlock
                        if let meta {
                            Text(meta)
                                .font(.subheadline)
                                .foregroundStyle(palette.inkMuted)
                        }
                    }
                    .padding(.vertical, Theme.space2)
                    Spacer(minLength: 0)
                } else {
                    titleBlock
                    Spacer(minLength: Theme.space2)
                    if let meta {
                        Text(meta)
                            .font(.subheadline)
                            .foregroundStyle(palette.inkMuted)
                    }
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

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.body)
                .foregroundStyle(palette.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(palette.inkMuted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, subtitle == nil ? 0 : Theme.space2)
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
