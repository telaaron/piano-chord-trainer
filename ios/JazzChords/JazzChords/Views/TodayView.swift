// Today — live daily-habit home. Greeting + level + streak + weekly dots,
// suggested plan, and a motivational nudge, all from persisted data.

import SwiftUI
import MusicEngine

struct TodayView: View {
    @Environment(\.palette) private var palette
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var habits = HabitStore.shared
    @State private var startSuggested = false
    @State private var startWeakDrill = false
    @State private var startCoach = false
    @State private var startToGo = false
    @State private var refreshToken = 0

    private var isPad: Bool { hSize == .regular }

    private var history: [SessionResult] { ProgressStore.loadHistory() }
    private var streak: StreakData { ProgressStore.loadStreak() }

    private var suggested: PracticePlan {
        suggestPlan(recentPlanIds(), history.count)
    }
    /// A focused "drill your weak spots" plan, if there's enough history to name any.
    private var weakDrillPlan: PracticePlan? {
        makeWeakDrillPlan(history)
    }
    private func recentPlanIds() -> [String] {
        Store.load([String].self, StoreKey.planHistory) ?? []
    }

    private var greeting: String {
        CoachL10n.greeting(hour: Calendar.current.component(.hour, from: Date()))
    }

    /// Localized coach announcement for the hero ("Today: warm up, …"). Previews
    /// today's plan from the persisted CoachState + live history/profile.
    private var coachSay: String {
        let plan = CoachStore.shared.currentPlan(history: history, profile: habits.profile)
        let (sayKey, sayParams) = describeCoachPlan(plan)
        return CoachL10n.t(sayKey, sayParams)
    }

    var body: some View {
        ScrollView {
            if isPad { iPadDashboard } else { phoneStack }
        }
        .navigationTitle(CoachL10n.t("nav.today"))
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .refreshable { habits.reload(); refreshToken += 1 }
        .onAppear { habits.reload(); refreshToken += 1 }
        .fullScreenCover(isPresented: $startSuggested, onDismiss: { habits.reload(); refreshToken += 1 }) {
            NavigationStack { TrainerView(plan: suggested) }
        }
        .fullScreenCover(isPresented: $startWeakDrill, onDismiss: { habits.reload(); refreshToken += 1 }) {
            NavigationStack { if let p = weakDrillPlan { TrainerView(plan: p) } }
        }
        .fullScreenCover(isPresented: $startCoach, onDismiss: { habits.reload(); refreshToken += 1 }) {
            NavigationStack { TrainerView(coachSession: true) }
        }
        .fullScreenCover(isPresented: $startToGo, onDismiss: { habits.reload(); refreshToken += 1 }) {
            NavigationStack { ToGoView() }
        }
    }

    /// "Practice without a piano" — the To-Go entry point (ear / time / theory).
    private var toGoCard: some View {
        Button { startToGo = true } label: {
            HStack(spacing: Theme.space3) {
                ZStack {
                    Circle().fill(palette.primary.opacity(0.16)).frame(width: 40, height: 40)
                    Image(systemName: "headphones")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(palette.primary)
                        .symbolRenderingMode(.hierarchical)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(CoachL10n.t(CoachL10n.ToGo.entry))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(palette.text)
                    Text(CoachL10n.t(CoachL10n.ToGo.startSub))
                        .font(.caption)
                        .foregroundStyle(palette.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textDim)
            }
            .padding(Theme.space3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var phoneStack: some View {
        VStack(alignment: .leading, spacing: Theme.space5) {
            hero
            weekStrip
            coachHero
            pickYourselfSection {
                suggestedCard
                if weakDrillPlan != nil { weakDrillCard }
                toGoCard
            }
            motivationCard
        }
        .padding(.horizontal, Theme.space4)
        .padding(.bottom, Theme.space5)
        .readableWidth()
        .id(refreshToken)
    }

    // iPad: full-width hero, then the coach hero, then a two-column dashboard.
    private var iPadDashboard: some View {
        VStack(alignment: .leading, spacing: Theme.space5) {
            hero
            coachHero
            HStack(alignment: .top, spacing: Theme.space5) {
                VStack(spacing: Theme.space5) {
                    pickYourselfSection {
                        suggestedCard
                        if weakDrillPlan != nil { weakDrillCard }
                        toGoCard
                    }
                    motivationCard
                }
                .frame(maxWidth: .infinity)
                statsPanel
                    .frame(width: 320)
            }
        }
        .padding(Theme.space6)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
        .id(refreshToken)
    }

    /// The dominant Auto-Mode entry point: one big "Keep practicing" button with
    /// the coach's announcement underneath (localized, incl. voicing names).
    private var coachHero: some View {
        Button { startCoach = true } label: {
            HStack(spacing: Theme.space4) {
                ZStack {
                    Circle().fill(palette.primaryText.opacity(0.18)).frame(width: 52, height: 52)
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(palette.primaryText)
                }
                VStack(alignment: .leading, spacing: Theme.space1) {
                    Text(CoachL10n.t(CoachL10n.heroTitle))
                        .font(Display.headline(24))
                        .foregroundStyle(palette.primaryText)
                    Text(coachSay)
                        .font(.subheadline)
                        .foregroundStyle(palette.primaryText.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(Theme.space4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.primary, in: RoundedRectangle(cornerRadius: Theme.radius))
        }
        .buttonStyle(.plain)
    }

    /// Wraps the manual-choice cards under a "Pick it yourself" section divider.
    @ViewBuilder
    private func pickYourselfSection<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Theme.space4) {
            Text(CoachL10n.t(CoachL10n.pickYourself).uppercased())
                .font(.caption2.weight(.semibold)).tracking(1.5)
                .foregroundStyle(palette.textDim)
            content()
        }
    }

    /// Right-hand stats panel (iPad): level, streak, weekly goal, quick stats.
    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: Theme.space4) {
            let stats = computeStats(history)
            SectionHeader(text: CoachL10n.t("settings.your_progress"))
            statRow(CoachL10n.t("ui.level"), "\(habits.levelInfo.level) · \(habits.levelInfo.title)")
            // Counted noun → .stringsdict, so this reads "1 Tag" / "2 Tage", never "1 days".
            statRow(CoachL10n.t("ui.streak"), CoachL10n.plural("count.days", streak.current))
            statRow(CoachL10n.t("ui.sessions"), "\(stats.totalSessions)")
            statRow(CoachL10n.t("embed.stat_avg"), stats.totalSessions > 0 ? String(format: "%.1fs", stats.overallAvgMs / 1000) : "—")
            Divider().overlay(palette.border)
            weekStrip
        }
        .padding(Theme.space5)
        .glassCard()
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(palette.textMuted)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(palette.text)
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
            Text(CoachL10n.plural("today.week_dots", dots.filter { $0 }.count, habits.profile.dailyGoalMinutes))
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
                    Text(CoachL10n.t("settings.suggested").uppercased())
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
                    Text(CoachL10n.t("ui.start"))
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

    /// Weakness-aware card: drill the chords you're slowest at (focused + answer-hidden).
    @ViewBuilder
    private var weakDrillCard: some View {
        if let plan = weakDrillPlan {
            CardSurface {
                VStack(alignment: .leading, spacing: Theme.space3) {
                    HStack(spacing: Theme.space2) {
                        ZStack {
                            Circle().fill(palette.accentRed.opacity(0.16)).frame(width: 40, height: 40)
                            Image(systemName: "target")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(palette.accentRed)
                                .symbolRenderingMode(.hierarchical)
                        }
                        Text(CoachL10n.t("quickstart.weakspots_title").uppercased())
                            .font(.caption2.weight(.semibold)).tracking(1.5)
                            .foregroundStyle(palette.accentRed)
                        Spacer()
                    }
                    Text(CoachL10n.t("results.drill_weak"))
                        .font(Display.headline(24))
                        .foregroundStyle(palette.text)
                    Text(weakDrillSubtitle(plan))
                        .font(.subheadline)
                        .foregroundStyle(palette.textMuted)
                    Button { startWeakDrill = true } label: {
                        Text(CoachL10n.t("ui.start"))
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
    }

    /// "Shell Voicing · D♭, F♯, B — deine langsamsten Akkorde"
    private func weakDrillSubtitle(_ plan: PracticePlan) -> String {
        let v = CoachL10n.voicing(plan.settings.voicing)
        // Root names are typeset, not raw engine strings: ♭/♯ must be real Unicode.
        let roots = (plan.focusRoots ?? []).map(Notation.root).joined(separator: ", ")
        if roots.isEmpty { return CoachL10n.t("ui.slowest_chords") }
        return CoachL10n.t("ui.slowest_chords_detail", ["voicing": v, "roots": roots])
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
        let prog = CoachL10n.progression(plan.settings.progressionMode)
        let v = CoachL10n.voicing(plan.settings.voicing)
        // "N chords" is a counted noun — plural form comes from the .stringsdict.
        let chords = CoachL10n.plural("count.chords", plan.settings.totalChords)
        return "\(v) · \(prog) · \(chords)"
    }
    /// Motivation copy (the engine returns i18n keys + params).
    private func motivationText(_ m: DailyMotivation) -> String {
        func param(_ k: String) -> String { m.messageParams[k] ?? "" }
        switch m.type {
        // Whole-sentence plural: German recasts around the count ("Serie von 1 Tag"),
        // so the count cannot just be spliced into a fixed template.
        case .streakAtRisk:
            return CoachL10n.plural("motivation.streak_at_risk", Int(param("days")) ?? 0)
        case .notStarted: return CoachL10n.t("habit.motivation_not_started", ["minutes": param("minutes")])
        case .justStarted: return CoachL10n.t("habit.motivation_keep_going", ["remaining": param("remaining")])
        case .almostThere: return CoachL10n.t("habit.motivation_almost", ["remaining": param("remaining")])
        case .goalReached: return CoachL10n.t("habit.motivation_goal_reached")
        case .extraCredit: return CoachL10n.t("habit.motivation_extra", ["practiced": param("practiced")])
        }
    }
}
