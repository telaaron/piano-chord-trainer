// "So funktioniert's" — three numbered steps for newcomers on Heute (spec §1).
// Done steps get a gold check, the next one is emphasized, the × hides it for good.

import SwiftUI

struct NewcomerGuide: View {
    @Environment(\.palette) private var palette
    let done: [Bool]
    let onDismiss: () -> Void

    private var nextIndex: Int { done.firstIndex(of: false) ?? done.count }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            HStack(alignment: .firstTextBaseline) {
                Text(Strings.guideTitle)
                    .font(Display.serif(26, relativeTo: .title2))
                    .foregroundStyle(palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(palette.inkMuted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Strings.guideHide)
            }
            ForEach(Array(Strings.guideSteps.enumerated()), id: \.offset) { index, step in
                stepRow(index: index, title: step.title, body: step.body)
            }
        }
    }

    private func stepRow(index: Int, title: String, body: String) -> some View {
        let isDone = index < done.count && done[index]
        let isNext = index == nextIndex
        return HStack(alignment: .top, spacing: Theme.space3) {
            ZStack {
                Circle().fill(isDone ? palette.music : (isNext ? palette.ink : palette.hairline.opacity(0.6)))
                if isDone {
                    Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(palette.canvas)
                } else {
                    Text("\(index + 1)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isNext ? palette.canvas : palette.ink)
                }
            }
            .frame(width: 28, height: 28)
            .accessibilityHidden(true)
            (Text(title).fontWeight(.semibold).foregroundStyle(palette.ink)
             + Text(" ") + Text(body).foregroundStyle(isNext || isDone ? palette.ink : palette.inkMuted))
                .font(.subheadline)
                .strikethrough(false)
                .opacity(isDone ? 0.7 : 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isDone ? CoachL10n.t("ui.done") : "")
    }
}

#Preview("Guide") {
    NewcomerGuide(done: [true, false, false]) {}
        .padding(20)
        .background(Palette.light.canvas)
        .environment(\.palette, .light)
}
