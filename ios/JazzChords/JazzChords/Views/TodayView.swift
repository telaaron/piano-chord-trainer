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
                hero
                weekStrip
                suggestedCard
                motivationCard
            }
            .padding(.horizontal, Theme.space4)
            .padding(.bottom, Theme.space5)
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

    /// Hero band: atmospheric gradient with the greeting + level + streak on top.
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            HeroGradient(height: 168)
            VStack(alignment: .leading, spacing: Theme.space3) {
                Text(greeting)
                    .font(Display.title(32))
                    .foregroundStyle(.white)
                HStack(spacing: Theme.space2) {
                    LevelBadge(level: habits.levelInfo.level)
                    Text(habits.levelInfo.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                    Spacer()
                    if streak.current > 0 {
                        Label("\(streak.current)", systemImage: "flame.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.primary)
                    }
                }
                ProgressView(value: Double(habits.levelInfo.progressPercent), total: 100)
                    .tint(palette.primary)
            }
            .padding(Theme.space4)
        }
        .padding(.top, Theme.space2)
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
                HStack(spacing: Theme.space2) {
                    ZStack {
                        Circle().fill(palette.primary.opacity(0.16)).frame(width: 40, height: 40)
                        Image(systemName: AppIcons.plan(suggested.id))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(palette.primary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    Text("SUGGESTED")
                        .font(.caption2.weight(.semibold)).tracking(1.5)
                        .foregroundStyle(palette.primary)
                    Spacer()
                }
                Text(planTitle(suggested.id))
                    .font(Display.headline(24))
                    .foregroundStyle(palette.text)
                Text(planSubtitle(suggested))
                    .font(.subheadline)
                    .foregroundStyle(palette.textMuted)
                Button { startSuggested = true } label: {
                    Text("Start")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space3)
                        .background(palette.primary, in: RoundedRectangle(cornerRadius: Theme.radius))
                        .foregroundStyle(palette.primaryText)
                }
                .padding(.top, Theme.space1)
            }
        }
    }

    @ViewBuilder
    private var motivationCard: some View {
        let m = getDailyMotivation(habits.profile, streak)
        HStack(spacing: Theme.space3) {
            Image(systemName: motivationIcon(m.type))
                .font(.title3)
                .foregroundStyle(palette.primary)
                .symbolRenderingMode(.hierarchical)
            Text(motivationText(m))
                .font(.subheadline)
                .foregroundStyle(palette.textMuted)
            Spacer()
        }
        .padding(Theme.space4)
        .glassCard()
    }

    private func motivationIcon(_ t: MotivationType) -> String {
        switch t {
        case .streakAtRisk: return "flame.fill"
        case .notStarted: return "pianokeys"
        case .justStarted: return "music.note"
        case .almostThere: return "bolt.fill"
        case .goalReached: return "checkmark.seal.fill"
        case .extraCredit: return "star.fill"
        }
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

    private func planTitle(_ id: String) -> String { Strings.planName(id) }
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
