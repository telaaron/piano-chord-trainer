// Today — the daily-habit home. Greeting + weekly streak dots + suggested plan.
// M1: static skeleton wired to the real engine (suggestPlan). Live data lands M3.

import SwiftUI
import MusicEngine

struct TodayView: View {
    @Environment(\.palette) private var palette
    @State private var startSuggested = false

    // M1 placeholder inputs; M3 replaces with persisted history/streak.
    private let suggested = suggestPlan([], 0)
    private let weekDots = [true, true, true, true, false, false, false]

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 18 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                // Greeting + week dots
                VStack(alignment: .leading, spacing: Theme.space3) {
                    Text(greeting)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(palette.text)
                    HStack(spacing: Theme.space2) {
                        ForEach(0..<7, id: \.self) { i in
                            Circle()
                                .fill(weekDots[i] ? palette.primary : palette.bgMuted)
                                .frame(width: 12, height: 12)
                        }
                    }
                    Text("4-day streak · weekly goal 4/5")
                        .font(.caption)
                        .foregroundStyle(palette.textDim)
                }

                // Suggested plan card
                CardSurface {
                    VStack(alignment: .leading, spacing: Theme.space3) {
                        Text("SUGGESTED")
                            .font(.caption2.weight(.semibold))
                            .tracking(1)
                            .foregroundStyle(palette.primary)
                        Text(planTitle(suggested.id))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(palette.text)
                        Text(planSubtitle(suggested))
                            .font(.subheadline)
                            .foregroundStyle(palette.textMuted)
                        Button {
                            startSuggested = true
                        } label: {
                            Text("Start")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.space3)
                                .background(palette.primary)
                                .foregroundStyle(palette.primaryText)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                        }
                        .padding(.top, Theme.space1)
                    }
                }
            }
            .padding(Theme.space4)
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .fullScreenCover(isPresented: $startSuggested) {
            NavigationStack { TrainerView(plan: suggested) }
        }
    }

    // Plan name/tagline are i18n keys in the engine; M1 shows a readable fallback.
    private func planTitle(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
    private func planSubtitle(_ plan: PracticePlan) -> String {
        let prog = PROGRESSION_LABELS[plan.settings.progressionMode] ?? ""
        let v = VOICING_LABELS[plan.settings.voicing] ?? ""
        return "\(v) · \(prog) · \(plan.settings.totalChords) chords"
    }
}
