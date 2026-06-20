// Practice — plan picker. Lists the real PRACTICE_PLANS from the engine.
// M1: tapping a plan is a no-op; M2 wires it to the trainer.

import SwiftUI
import MusicEngine

// PracticePlan already has a stable `id` — make it usable with .fullScreenCover(item:).
extension PracticePlan: @retroactive Identifiable {}

struct PracticeView: View {
    @Environment(\.palette) private var palette
    @State private var activePlan: PracticePlan?
    @State private var freePlay = false

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: Theme.space3)]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.space3) {
                Button { freePlay = true } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Free practice").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(palette.textDim)
                    }
                    .foregroundStyle(palette.text)
                    .padding(Theme.space4)
                    .frame(maxWidth: .infinity)
                    .background(palette.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
                }
                .buttonStyle(.plain)

                LazyVGrid(columns: columns, spacing: Theme.space3) {
                    ForEach(PRACTICE_PLANS, id: \.id) { plan in
                        Button { activePlan = plan } label: { planCard(plan) }
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

    private func planCard(_ plan: PracticePlan) -> some View {
        CardSurface {
            VStack(alignment: .leading, spacing: Theme.space2) {
                Text(plan.icon)
                    .font(.title2)
                Text(planName(plan.id))
                    .font(.headline)
                    .foregroundStyle(palette.text)
                Text(levelLabel(plan.level))
                    .font(.caption)
                    .foregroundStyle(palette.textDim)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        }
    }

    private func planName(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
    private func levelLabel(_ level: PlanLevel) -> String {
        level.rawValue.capitalized
    }
}
