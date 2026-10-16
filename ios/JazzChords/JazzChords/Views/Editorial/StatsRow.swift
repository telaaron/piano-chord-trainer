// Stats as typography: three columns, rule on top, hairlines between,
// serif numbers in gold.

import SwiftUI

struct StatItem: Identifiable {
    let value: String
    let label: String
    var id: String { label }
}

struct StatsRow: View {
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    let items: [StatItem]

    var body: some View {
        if typeSize.isAccessibilitySize {
            stacked
        } else {
            columns
        }
    }

    /// Accessibility sizes: one stat per line, value and label side by side.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            ForEach(items) { item in
                HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
                    Text(item.value)
                        .font(Display.serif(32))
                        .foregroundStyle(palette.music)
                    Text(item.label)
                        .font(.caption)
                        .foregroundStyle(palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(item.value) \(item.label)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 14)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.ink).frame(height: 1)
        }
    }

    private var columns: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 0) {
                    if index > 0 {
                        Rectangle().fill(palette.hairline).frame(width: 1)
                            .padding(.trailing, Theme.space3)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.value)
                            .font(Display.serif(32))
                            .foregroundStyle(palette.music)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(item.label)
                            .font(.caption)
                            .foregroundStyle(palette.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(item.value) \(item.label)")
            }
        }
        .padding(.top, 14)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.ink).frame(height: 1)
        }
    }
}

extension StatsRow {
    /// Today's stats with real numbers only: a stat without data is left out
    /// instead of showing "0" or "–" (spec §1).
    nonisolated static func items(streak: Int, avgMs: Double?, sessions: Int) -> [StatItem] {
        var out: [StatItem] = []
        if streak > 0 { out.append(StatItem(value: "\(streak)", label: Strings.statDaysInRow)) }
        if let avgMs, avgMs > 0 { out.append(StatItem(value: Strings.seconds(avgMs / 1000), label: Strings.statPerChord)) }
        if sessions > 0 { out.append(StatItem(value: "\(sessions)", label: Strings.statSessions)) }
        return out
    }
}

#Preview("Stats") {
    StatsRow(items: [
        StatItem(value: "4", label: "Tage in Folge"),
        StatItem(value: "1,8 s", label: "pro Akkord"),
        StatItem(value: "31", label: "Voicings sitzen"),
    ])
    .padding(20)
    .background(Palette.light.canvas)
    .environment(\.palette, .light)
}
