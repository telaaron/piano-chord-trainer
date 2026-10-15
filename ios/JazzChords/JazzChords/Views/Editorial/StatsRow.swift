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
    let items: [StatItem]

    var body: some View {
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
