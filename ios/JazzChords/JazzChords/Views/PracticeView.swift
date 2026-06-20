// Practice — plan picker. Real PRACTICE_PLANS as rich glass cards: SF icon in a
// tinted halo, display-face name, level + a voicing/progression mini-line, and a
// duration pill. Free-practice entry on top. Tapping a card opens the trainer.

import SwiftUI
import MusicEngine

extension PracticePlan: @retroactive Identifiable {}

struct PracticeView: View {
    @Environment(\.palette) private var palette
    @State private var activePlan: PracticePlan?
    @State private var freePlay = false

    private let columns = [GridItem(.flexible(), spacing: Theme.space3), GridItem(.flexible(), spacing: Theme.space3)]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.space4) {
                freePracticeButton
                LazyVGrid(columns: columns, spacing: Theme.space3) {
                    ForEach(PRACTICE_PLANS) { plan in
                        Button { activePlan = plan } label: { PlanCard(plan: plan) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(Theme.space4)
        }
        .navigationTitle("Practice")
        .screenBackground()
        .fullScreenCover(item: $activePlan) { plan in
            NavigationStack { TrainerView(plan: plan) }
        }
        .fullScreenCover(isPresented: $freePlay) {
            NavigationStack { TrainerView(plan: nil) }
        }
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

    private var accent: Color {
        switch plan.level {
        case .beginner: return palette.accentGreen
        case .intermediate: return palette.primary
        case .advanced: return palette.accentRed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            // Icon halo
            ZStack {
                Circle().fill(accent.opacity(0.16)).frame(width: 44, height: 44)
                Image(systemName: AppIcons.plan(plan.id))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
                    .symbolRenderingMode(.hierarchical)
            }

            Text(planName(plan.id))
                .font(Display.headline(17))
                .foregroundStyle(palette.text)
                .lineLimit(1)

            Text(miniLine)
                .font(.caption)
                .foregroundStyle(palette.textMuted)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                pill(text: plan.level.rawValue.capitalized, color: accent)
                pill(text: "\(plan.settings.totalChords)", color: palette.textDim, system: "music.note")
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(Theme.space4)
        .glassCard(tint: accent)
        .overlay(alignment: .leading) {
            // subtle accent stripe
            RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 3).padding(.vertical, Theme.space4)
        }
    }

    private func pill(text: String, color: Color, system: String? = nil) -> some View {
        HStack(spacing: 3) {
            if let system { Image(systemName: system).font(.system(size: 9)) }
            Text(text).font(.caption2.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(color.opacity(0.14), in: Capsule())
    }

    private func planName(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
    private var miniLine: String {
        let v = VOICING_LABELS[plan.settings.voicing] ?? ""
        let p = PROGRESSION_LABELS[plan.settings.progressionMode] ?? ""
        return "\(v) · \(p)"
    }
}
