// Practice — plan picker. Real PRACTICE_PLANS as rich glass cards: SF icon in a
// tinted halo, display-face name, level + a voicing/progression mini-line, and a
// duration pill. Free-practice entry on top. Tapping a card opens the trainer.

import SwiftUI
import MusicEngine

extension PracticePlan: @retroactive Identifiable {}

struct PracticeView: View {
    @Environment(\.palette) private var palette
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var activePlan: PracticePlan?
    @State private var freePlay = false
    @State private var customOpen = false

    // iPad (regular width) gets a wider auto-fitting grid; iPhone stays 2-up.
    private var columns: [GridItem] {
        hSize == .regular
            ? [GridItem(.adaptive(minimum: 200), spacing: Theme.space3)]
            : [GridItem(.flexible(), spacing: Theme.space3), GridItem(.flexible(), spacing: Theme.space3)]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.space4) {
                freePracticeButton
                customButton
                LazyVGrid(columns: columns, spacing: Theme.space3) {
                    ForEach(PRACTICE_PLANS) { plan in
                        Button { activePlan = plan } label: { PlanCard(plan: plan) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(Theme.space4)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Practice")
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

    private var customButton: some View {
        Button { customOpen = true } label: {
            HStack(spacing: Theme.space3) {
                Image(systemName: "text.badge.plus").font(.title3).foregroundStyle(palette.primary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Custom progression").font(Display.headline(17)).foregroundStyle(palette.text)
                    Text("Type any chord sequence").font(.caption).foregroundStyle(palette.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(palette.textDim)
            }
            .padding(Theme.space4)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var freePracticeButton: some View {
        Button { freePlay = true } label: {
            HStack(spacing: Theme.space3) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(palette.primary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Free practice").font(Display.headline(17)).foregroundStyle(palette.text)
                    Text("Your own settings").font(.caption).foregroundStyle(palette.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(palette.textDim)
            }
            .padding(Theme.space4)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}

/// A single practice-plan card.
struct PlanCard: View {
    @Environment(\.palette) private var palette
    let plan: PracticePlan

    /// Level dot color — the only chromatic cue beyond the amber accent.
    private var levelColor: Color {
        switch plan.level {
        case .beginner: return palette.accentGreen
        case .intermediate: return palette.primary
        case .advanced: return palette.accentRed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            // Amber icon — single consistent accent across all cards.
            Image(systemName: AppIcons.plan(plan.id))
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(palette.primary)
                .symbolRenderingMode(.hierarchical)
                .frame(height: 28)

            Text(Strings.planName(plan.id))
                .font(Display.headline(18))
                .foregroundStyle(palette.text)
                .lineLimit(1)

            Text(Strings.planTagline(plan.id))
                .font(.caption)
                .foregroundStyle(palette.textMuted)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Circle().fill(levelColor).frame(width: 6, height: 6)
                Text(plan.level.rawValue.capitalized)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(palette.textMuted)
                Spacer()
                Image(systemName: "music.note").font(.system(size: 9))
                Text("\(plan.settings.totalChords)").font(.caption2.weight(.medium))
            }
            .foregroundStyle(palette.textDim)
        }
        .frame(maxWidth: .infinity, minHeight: 152, alignment: .topLeading)
        .padding(Theme.space4)
        .glassCard()
    }

}
