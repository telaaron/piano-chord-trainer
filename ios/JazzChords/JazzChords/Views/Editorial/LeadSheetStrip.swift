// Trainer-only lead sheet line: previous | current | next chord over five
// staff lines. Never on Heute (spec §4.1).

import SwiftUI

struct LeadSheetStrip: View {
    @Environment(\.palette) private var palette
    let previous: String?
    let current: String
    let next: String?

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            bar(previous, isCurrent: false).opacity(0.6)
            bar(current, isCurrent: true)
            bar(next, isCurrent: false)
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(palette.inkMuted).frame(width: 2, height: 33)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 72)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.leadSheetLabel(previous: previous, current: current, next: next))
    }

    private func bar(_ chord: String?, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(chord ?? " ")
                .font(Display.chord(isCurrent ? 28 : 22, relativeTo: .title2))
                .foregroundStyle(isCurrent ? palette.action : palette.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.leading, 4)
            staff
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottomLeading) {
            Rectangle().fill(palette.hairline).frame(width: 1, height: 33)
        }
    }

    private var staff: some View {
        VStack(spacing: 7) {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle().fill(palette.hairline).frame(height: 1)
            }
        }
    }
}

#Preview("Lead sheet") {
    LeadSheetStrip(previous: "A–7", current: "D–7", next: "G7")
        .padding(20)
        .background(Palette.light.canvas)
        .environment(\.palette, .light)
}
