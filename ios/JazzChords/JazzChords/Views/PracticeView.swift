// Practice — plan picker in the editorial layout: the recommended plan as the
// one red block, then plans grouped by level as tracklists, then free practice
// and the custom progression builder. Tapping a row opens the trainer.

import SwiftUI
import MusicEngine

extension PracticePlan: @retroactive Identifiable {}

struct PracticeView: View {
    @Environment(\.palette) private var palette
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var activePlan: PracticePlan?
    @State private var freePlay = false
    @State private var customOpen = false

    private var recommended: PracticePlan {
        let ids = Store.load([String].self, StoreKey.planHistory) ?? []
        return suggestPlan(ids, ProgressStore.loadHistory().count)
    }

    private let levels: [PlanLevel] = [.beginner, .intermediate, .advanced]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                EditorialHeader(eyebrow: Strings.plansEyebrow(PRACTICE_PLANS.count),
                                title: CoachL10n.t("nav.practice")) {
                    SettingsHeaderButton()
                }
                featured
                ForEach(levels, id: \.self) { level in
                    let plans = PRACTICE_PLANS.filter { $0.level == level }
                    if !plans.isEmpty { levelSection(level, plans) }
                }
                ownWay
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

    private var featured: some View {
        let plan = recommended
        return FeatureBlock(eyebrow: CoachL10n.t("settings.suggested"), ghost: Strings.voicingBadge(plan.settings.voicing)) {
            VStack(alignment: .leading, spacing: Theme.space2) {
                Text(Strings.planName(plan.id))
                    .font(Display.serif(30, relativeTo: .title))
                Text(Strings.planTagline(plan.id))
                    .font(Display.serif(18, italic: true, relativeTo: .body))
                    .fixedSize(horizontal: false, vertical: true)
            }
        } action: {
            PrimaryCapsule(title: CoachL10n.t("ui.start"), systemImage: "play.fill", inverted: true) {
                activePlan = plan
            }
        }
    }

    private func levelSection(_ level: PlanLevel, _ plans: [PracticePlan]) -> some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            EyebrowText(Strings.level(level))
                .padding(.leading, Theme.space4)
            TrackGroup {
                ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                    Button { activePlan = plan } label: {
                        TrackRow(badge: Strings.voicingBadge(plan.settings.voicing),
                                 title: Strings.planName(plan.id),
                                 meta: "\(plan.settings.totalChords)",
                                 showsDivider: index < plans.count - 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var ownWay: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            EyebrowText(Strings.ownWay)
                .padding(.leading, Theme.space4)
            TrackGroup {
                Button { freePlay = true } label: {
                    TrackRow(badge: "∞", title: CoachL10n.t("ui.free_practice"), showsDivider: true)
                }
                .buttonStyle(.plain)
                Button { customOpen = true } label: {
                    TrackRow(badge: "+", title: CoachL10n.t("ui.custom_progression"))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
