// Today — the daily home in the editorial layout: eyebrow + serif title, the one
// red feature block (today's coach session with its chords), stats as
// typography, then "Side B" tracklist for picking a session yourself.

import SwiftUI
import MusicEngine

/// Identifiable wrapper so a chord can drive `.sheet(item:)`.
struct PreviewChord: Identifiable {
    let chord: ChordWithNotes
    var id: String { chord.chord }
}

struct TodayView: View {
    @Environment(\.palette) private var palette
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var habits = HabitStore.shared
    @State private var startSuggested = false
    @State private var startWeakDrill = false
    @State private var startCoach = false
    @State private var startToGo = false
    @State private var refreshToken = 0
    @State private var previewChord: PreviewChord?

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
    private var coachPlan: CoachPlan {
        CoachStore.shared.previewPlan(history: history, profile: habits.profile)
    }

    private var coachSay: String {
        let (sayKey, sayParams) = describeCoachPlan(coachPlan)
        return CoachL10n.t(sayKey, sayParams)
    }

    var body: some View {
        ScrollView {
            if isPad { iPadDashboard } else { phoneStack }
        }
        .screenBackground()
        .refreshable { habits.reload(); refreshToken += 1 }
        .onAppear { habits.reload(); refreshToken += 1 }
        .sheet(item: $previewChord) { item in
            ChordPreviewSheet(chord: item.chord)
                .environment(\.palette, palette)
        }
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

    private var phoneStack: some View {
        VStack(alignment: .leading, spacing: Theme.space5) {
            header
            feature
            stats
            sideB
            motivationLine
        }
        .padding(.horizontal, Theme.space4)
        .padding(.top, Theme.space3)
        .padding(.bottom, Theme.space6)
        .readableWidth()
        .id(refreshToken)
    }

    // iPad: header and feature full width, then Side B next to the stats column.
    private var iPadDashboard: some View {
        VStack(alignment: .leading, spacing: Theme.space5) {
            header
            feature
            HStack(alignment: .top, spacing: Theme.space6) {
                sideB.frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: Theme.space5) {
                    stats
                    motivationLine
                }
                .frame(width: 340)
            }
        }
        .padding(Theme.space6)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
        .id(refreshToken)
    }

    private var header: some View {
        EditorialHeader(eyebrow: Strings.todayEyebrow(date: Date(), session: history.count + 1),
                        title: CoachL10n.t("nav.today")) {
            SettingsHeaderButton()
        }
    }

    /// The one red block: today's coach session. Tapping a chord previews it.
    private var feature: some View {
        let plan = coachPlan
        let chords = TodayChordPreview.chords(for: plan)
        let total = plan.blocks.reduce(0) { $0 + $1.targetChords }
        return FeatureBlock(eyebrow: Strings.todayFeatureEyebrow(minutes: plan.estMinutes, chords: total),
                            ghost: "Δ7") {
            VStack(alignment: .leading, spacing: Theme.space3) {
                if !chords.isEmpty {
                    chordRow(chords, sequence: TodayChordPreview.isSequence(for: plan))
                }
                Text(coachSay)
                    .font(Display.serif(20, italic: true, relativeTo: .title3))
                    .fixedSize(horizontal: false, vertical: true)
            }
        } action: {
            PrimaryCapsule(title: Strings.keepPracticing, systemImage: "play.fill", inverted: true) {
                startCoach = true
            }
        }
    }

    private func chordRow(_ chords: [ChordWithNotes], sequence: Bool) -> some View {
        HStack(spacing: Theme.space2) {
            if !sequence {
                // Dealt at random when the session starts — examples, not a promise.
                Text(Strings.forExample)
                    .font(Display.serif(18, italic: true, relativeTo: .body))
                    .opacity(0.8)
            }
            ForEach(Array(chords.enumerated()), id: \.offset) { index, chord in
                if sequence, index > 0 {
                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.semibold))
                        .opacity(0.7)
                        .accessibilityHidden(true)
                }
                Button { previewChord = PreviewChord(chord: chord) } label: {
                    Text(Notation.chord(chord.chord))
                        .font(Display.chord(30, relativeTo: .title2))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, Theme.space2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(palette.onAction.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityHint(Strings.chordPreviewHint)
            }
        }
    }

    private var stats: some View {
        let s = computeStats(history)
        return StatsRow(items: [
            StatItem(value: "\(streak.current)", label: Strings.statDaysInRow),
            StatItem(value: s.totalSessions > 0 ? Strings.seconds(s.overallAvgMs / 1000) : "—", label: Strings.statPerChord),
            StatItem(value: "\(s.totalSessions)", label: Strings.statSessions),
        ])
    }

    /// "Side B": pick a session yourself — suggested plan, weak spots, To-Go.
    private var sideB: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            EyebrowText(Strings.sideB)
                .padding(.leading, Theme.space4)
            TrackGroup {
                Button { startSuggested = true } label: {
                    TrackRow(badge: Strings.voicingBadge(suggested.settings.voicing),
                             title: planTitle(suggested.id), meta: planMeta(suggested), showsDivider: true)
                }
                .buttonStyle(.plain)
                if let plan = weakDrillPlan {
                    Button { startWeakDrill = true } label: {
                        TrackRow(badge: plan.focusRoots?.first.map(Notation.root) ?? "?",
                                 title: CoachL10n.t("results.drill_weak"), meta: weakDrillMeta(plan), showsDivider: true)
                    }
                    .buttonStyle(.plain)
                }
                Button { startToGo = true } label: {
                    TrackRow(badge: "♪", title: CoachL10n.t(CoachL10n.ToGo.entry), meta: nil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Week dots and the daily nudge, set as one quiet line instead of a card.
    private var motivationLine: some View {
        let m = getDailyMotivation(habits.profile, streak)
        let dots = weekDots()
        return HStack(alignment: .firstTextBaseline, spacing: Theme.space3) {
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(dots[i] ? palette.music : palette.hairline)
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityHidden(true)
            Label {
                Text(motivationText(m))
            } icon: {
                Image(systemName: motivationIcon(m.type))
            }
            .font(.subheadline)
            .foregroundStyle(palette.inkMuted)
        }
    }

    private func planMeta(_ plan: PracticePlan) -> String {
        CoachL10n.plural("count.chords", plan.settings.totalChords)
    }

    private func weakDrillMeta(_ plan: PracticePlan) -> String {
        CoachL10n.voicing(plan.settings.voicing)
    }

    /// "Shell Voicing · D♭, F♯, B — deine langsamsten Akkorde"
    private func weakDrillSubtitle(_ plan: PracticePlan) -> String {
        let v = CoachL10n.voicing(plan.settings.voicing)
        // Root names are typeset, not raw engine strings: ♭/♯ must be real Unicode.
        let roots = (plan.focusRoots ?? []).map(Notation.root).joined(separator: ", ")
        if roots.isEmpty { return CoachL10n.t("ui.slowest_chords") }
        return CoachL10n.t("ui.slowest_chords_detail", ["voicing": v, "roots": roots])
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
