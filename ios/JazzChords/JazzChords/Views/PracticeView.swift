// Practice — plan picker (spec §3). Header + plain subline, then plans grouped
// by goal; every row is an icon tile (what you do), a title, a plain subline and
// the chord count. The recommendation lives on Heute, not here.

import SwiftUI
import MusicEngine

extension PracticePlan: @retroactive Identifiable {}

struct PracticeView: View {
    @Environment(\.palette) private var palette
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var activePlan: PracticePlan?
    @State private var freePlay = false
    @State private var customOpen = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                VStack(alignment: .leading, spacing: Theme.space1) {
                    EditorialHeader(title: CoachL10n.t("nav.practice"))
                    Text(SettingsText.t("Choose what you want to practise today.",
                                        "Wähle, was du heute trainieren willst."))
                        .font(.body)
                        .foregroundStyle(palette.inkMuted)
                }
                ForEach(PracticeGroup.allCases, id: \.self) { group in
                    groupSection(group)
                }
            }
            .padding(.horizontal, Theme.space4)
            .padding(.top, Theme.space3)
            .padding(.bottom, Theme.space6)
            .readableWidth(hSize == .regular ? 820 : 640)
        }
        .screenBackground()
        .fullScreenCover(item: $activePlan) { plan in
            NavigationStack { TrainerView(plan: plan) }
        }
        .fullScreenCover(isPresented: $freePlay) {
            NavigationStack { TrainerView(plan: nil) }
        }
        .fullScreenCover(isPresented: $customOpen) {
            NavigationStack { CustomProgressionView() }
        }
    }

    private func groupSection(_ group: PracticeGroup) -> some View {
        let rows = PlanPresentation.all.filter { $0.group == group }
        return VStack(alignment: .leading, spacing: Theme.space2) {
            EyebrowText(group.title)
                .padding(.leading, Theme.space4)
            TrackGroup {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    Button { open(row.id) } label: {
                        TrackRow(icon: row.symbol, title: row.title, subtitle: row.subtitle,
                                 meta: chordCount(row.id),
                                 showsDivider: index < rows.count - 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func open(_ id: String) {
        switch id {
        case PlanPresentation.freeId: freePlay = true
        case PlanPresentation.customId: customOpen = true
        default: activePlan = PRACTICE_PLANS.first { $0.id == id }
        }
    }

    private func chordCount(_ id: String) -> String? {
        PRACTICE_PLANS.first { $0.id == id }.map { "\($0.settings.totalChords)" }
    }
}
