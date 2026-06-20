// Today — live daily-habit home. Greeting + level + streak + weekly dots,
// suggested plan, and a motivational nudge, all from persisted data.

import SwiftUI
import MusicEngine

struct TodayView: View {
    @Environment(\.palette) private var palette
    @State private var habits = HabitStore.shared
    @State private var startSuggested = false
    @State private var refreshToken = 0

    private var history: [SessionResult] { ProgressStore.loadHistory() }
    private var streak: StreakData { ProgressStore.loadStreak() }

    private var suggested: PracticePlan {
        suggestPlan(recentPlanIds(), history.count)
    }
    private func recentPlanIds() -> [String] {
        Store.load([String].self, StoreKey.planHistory) ?? []
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 18 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                header
                weekStrip
                suggestedCard
                motivationCard
            }
            .padding(Theme.space4)
            .id(refreshToken)
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .refreshable { habits.reload(); refreshToken += 1 }
        .onAppear { habits.reload(); refreshToken += 1 }
        .fullScreenCover(isPresented: $startSuggested, onDismiss: { habits.reload(); refreshToken += 1 }) {
            NavigationStack { TrainerView(plan: suggested) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            Text(greeting)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(palette.text)
            HStack(spacing: Theme.space2) {
                LevelBadge(level: habits.levelInfo.level)
                Text(habits.levelInfo.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textMuted)
                Spacer()
                if streak.current > 0 {
                    Label("\(streak.current)", systemImage: "flame.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.primary)
                }
            }
            // XP progress to next level
            ProgressView(value: Double(habits.levelInfo.progressPercent), total: 100)
                .tint(palette.xp)
        }
    }

    private var weekStrip: some View {
        let dots = weekDots()
        return VStack(alignment: .leading, spacing: Theme.space2) {
            HStack(spacing: Theme.space2) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(dots[i] ? palette.primary : palette.bgMuted)
                        .frame(width: 14, height: 14)
                }
            }
            Text("\(dots.filter { $0 }.count)/5 this week · \(habits.profile.dailyGoalMinutes) min/day goal")
                .font(.caption)
                .foregroundStyle(palette.textDim)
        }
    }

    private var suggestedCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: Theme.space3) {
                Text("SUGGESTED")
                    .font(.caption2.weight(.semibold)).tracking(1)
                    .foregroundStyle(palette.primary)
                Text(planTitle(suggested.id))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(palette.text)
                Text(planSubtitle(suggested))
                    .font(.subheadline)
                    .foregroundStyle(palette.textMuted)
                Button { startSuggested = true } label: {
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

    @ViewBuilder
    private var motivationCard: some View {
        let m = getDailyMotivation(habits.profile, streak)
        HStack(spacing: Theme.space3) {
            Text(m.emoji).font(.title2)
            Text(motivationText(m))
                .font(.subheadline)
                .foregroundStyle(palette.textMuted)
            Spacer()
        }
        .padding(Theme.space4)
        .background(palette.bgCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
    }

    // MARK: helpers

    private func weekDots() -> [Bool] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let f = DateFormatter()
        f.calendar = cal; f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = cal.timeZone; f.dateFormat = "yyyy-MM-dd"

        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        let jsDay = weekday - 1
        let fromMonday = jsDay == 0 ? 6 : jsDay - 1
        let monday = cal.date(byAdding: .day, value: -fromMonday, to: today)!
        let goalSet = Set(habits.profile.dailyGoalDates)
        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i, to: monday)!
            return goalSet.contains(f.string(from: d))
        }
    }

    private func planTitle(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
    private func planSubtitle(_ plan: PracticePlan) -> String {
        let prog = PROGRESSION_LABELS[plan.settings.progressionMode] ?? ""
        let v = VOICING_LABELS[plan.settings.voicing] ?? ""
        return "\(v) · \(prog) · \(plan.settings.totalChords) chords"
    }
    /// Minimal motivation copy (the engine returns i18n keys + params).
    private func motivationText(_ m: DailyMotivation) -> String {
        switch m.type {
        case .streakAtRisk: return "Your \(m.messageParams["days"] ?? "")-day streak is at risk — a quick session keeps it alive."
        case .notStarted: return "Ready for your \(m.messageParams["minutes"] ?? "")-minute practice?"
        case .justStarted: return "Nice start — \(m.messageParams["remaining"] ?? "") min to today's goal."
        case .almostThere: return "Almost there — \(m.messageParams["remaining"] ?? "") min to go."
        case .goalReached: return "Daily goal reached. 🎉"
        case .extraCredit: return "Extra credit — \(m.messageParams["practiced"] ?? "") min today."
        }
    }
}
