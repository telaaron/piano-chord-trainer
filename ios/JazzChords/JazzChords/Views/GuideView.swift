// GuideView — one website guide, rendered natively: serif headings, body text,
// numbered steps, chord tables in Kalam, and "Jetzt üben" into the matching plan.

import SwiftUI
import MusicEngine

struct GuideView: View {
    @Environment(\.palette) private var palette
    @Environment(\.horizontalSizeClass) private var hSize
    let guide: Guide
    @State private var practicing = false

    private var plan: PracticePlan? { PRACTICE_PLANS.first { $0.id == guide.planId } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space4) {
                Text(guide.title)
                    .font(Display.serif(36, relativeTo: .largeTitle))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Rectangle().fill(palette.ink).frame(height: 1)
                ForEach(Array(guide.blocks.enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
                if plan != nil {
                    PrimaryCapsule(title: SettingsText.t("Practise now", "Jetzt üben"), systemImage: "play.fill") {
                        practicing = true
                    }
                    .padding(.top, Theme.space3)
                }
            }
            .padding(.horizontal, Theme.space4)
            .padding(.top, Theme.space3)
            .padding(.bottom, Theme.space6)
            .readableWidth(hSize == .regular ? 720 : 640)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $practicing) {
            NavigationStack { if let plan { TrainerView(plan: plan) } }
        }
    }

    @ViewBuilder private func blockView(_ block: GuideBlock) -> some View {
        switch block {
        case .heading(let text, let level):
            Text(text)
                .font(Display.serif(level == 2 ? 26 : 21, relativeTo: level == 2 ? .title2 : .title3))
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.space3)
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let text):
            rich(text)
        case .numbered(let items):
            VStack(alignment: .leading, spacing: Theme.space3) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    HStack(alignment: .firstTextBaseline, spacing: Theme.space3) {
                        Text("\(i + 1)")
                            .font(Display.serif(22, relativeTo: .body))
                            .foregroundStyle(palette.music)
                            .frame(width: 22, alignment: .leading)
                        rich(item)
                    }
                }
            }
        case .bullets(let items):
            VStack(alignment: .leading, spacing: Theme.space2) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
                        Circle().fill(palette.music).frame(width: 6, height: 6).alignmentGuide(.firstTextBaseline) { $0[.bottom] }
                        rich(item)
                    }
                }
            }
        case .table(let name):
            if name == "ii-v-i-table" { iiVITable }
        }
    }

    private func rich(_ text: String) -> some View {
        let attributed = (try? AttributedString(markdown: text)) ?? AttributedString(text)
        return Text(attributed)
            .font(.body)
            .foregroundStyle(palette.ink)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var iiVITable: some View {
        TrackGroup {
            ForEach(Array(GuideLibrary.iiVITable.enumerated()), id: \.offset) { i, row in
                HStack(alignment: .firstTextBaseline, spacing: Theme.space3) {
                    Text(row.key)
                        .font(Display.serif(20, relativeTo: .body))
                        .foregroundStyle(palette.music)
                        .frame(width: 36, alignment: .leading)
                    Text(row.chords)
                        .font(Display.chord(20, relativeTo: .body))
                        .foregroundStyle(palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Theme.space4)
                .frame(minHeight: 44)
                .overlay(alignment: .bottom) {
                    if i < GuideLibrary.iiVITable.count - 1 {
                        Rectangle().fill(palette.hairline).frame(height: 0.5).padding(.leading, Theme.space4)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
