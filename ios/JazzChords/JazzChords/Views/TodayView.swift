// Today — the daily home in the editorial layout: date + serif title, the one
// red feature block (the first-step check for newcomers, else today's coach
// session with its chords), "So funktioniert's" for newcomers or stats with real
// numbers, then a plain list to just start playing (spec §1).

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
    @State private var guideDismissed = NewcomerGuideStore.dismissed

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

    private var stage: TodayStage {
        TodayStage.of(sessions: history.count, calibrated: CoachStore.shared.isCalibrated,
                      firstLaunch: NewcomerGuideStore.firstLaunch, now: Date(),
                      dismissed: guideDismissed)
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
            guideOrStats
            justPlay
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
                justPlay.frame(maxWidth: .infinity)
                guideOrStats.frame(width: 340)
            }
        }
        .padding(Theme.space6)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
        .id(refreshToken)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Strings.todayDate(Date()))
                .font(.subheadline)
                .foregroundStyle(palette.inkMuted)
            EditorialHeader(title: stage.title == .welcome ? Strings.welcome : greeting) {
                SettingsEntryButton()
            }
        }
    }

    /// The one red block: the first-step check for newcomers, else today's
    /// coach session (tapping a chord previews it).
    @ViewBuilder private var feature: some View {
        if stage.showsFirstStep { firstStep } else { sessionFeature }
    }

    /// Newcomers: one plain invitation to the placement check.
    private var firstStep: some View {
        FeatureBlock(eyebrow: Strings.firstStepEyebrow, ghost: "Δ7") {
            VStack(alignment: .leading, spacing: Theme.space3) {
                Text(Strings.firstStepTitle)
                    .font(Display.serif(28, relativeTo: .title2))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Theme.space2) {
                    ForEach(Strings.firstStepChips, id: \.symbol) { chip in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(chip.symbol)
                                .font(Display.chord(22, relativeTo: .title3))
                            Text(chip.words)
                                .font(.caption)
                                .opacity(0.9)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, Theme.space2)
                        .background(palette.onFeature.opacity(0.14),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityElement(children: .combine)
                    }
                }
                // Equal chip heights even when one label wraps.
                .fixedSize(horizontal: false, vertical: true)
            }
        } action: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.space3) {
                    PrimaryCapsule(title: Strings.startCheck, systemImage: "play.fill", inverted: true) {
                        startCoach = true
                    }
                    Text(Strings.checkNote).font(.subheadline).opacity(0.9)
                }
                VStack(alignment: .leading, spacing: Theme.space2) {
                    PrimaryCapsule(title: Strings.startCheck, systemImage: "play.fill", inverted: true) {
                        startCoach = true
                    }
                    Text(Strings.checkNote).font(.subheadline).opacity(0.9)
                }
            }
        }
    }

    private var sessionFeature: some View {
        let plan = coachPlan
        let chords = TodayChordPreview.chords(for: plan)
        let total = plan.blocks.reduce(0) { $0 + $1.targetChords }
        return FeatureBlock(eyebrow: Strings.todayFeatureEyebrow(minutes: plan.estMinutes, chords: total),
                            ghost: "Δ7") {
            VStack(alignment: .leading, spacing: Theme.space3) {
                if !chords.isEmpty {
                    chordRow(chords, sequence: TodayChordPreview.isSequence(for: plan),
                             anyKey: TodayChordPreview.isAnyKey(for: plan))
                }
                Text(coachSay)
                    .font(Display.serif(20, italic: true, relativeTo: .title3))
                    .fixedSize(horizontal: false, vertical: true)
                let steps = TodayChordPreview.steps(for: plan)
                if steps.count > 1 { stepsRow(steps) }
            }
        } action: {
            PrimaryCapsule(title: Strings.keepPracticing, systemImage: "play.fill", inverted: true) {
                startCoach = true
            }
        }
    }

    private func chordRow(_ chords: [ChordWithNotes], sequence: Bool, anyKey: Bool) -> some View {
        HStack(spacing: Theme.space2) {
            if !sequence && !anyKey {
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
                    Text(chipLabel(chord, anyKey: anyKey))
                        .font(Display.chord(30, relativeTo: .title2))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, Theme.space3)
                        .background(palette.onFeature.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Notation.chord(chord.chord))
                .accessibilityHint(Strings.chordPreviewHint)
            }
            if anyKey {
                Text(Strings.inAllKeys)
                    .font(Display.serif(18, italic: true, relativeTo: .body))
                    .opacity(0.8)
            }
        }
    }

    /// Today's units in order; the first (where "Weiter üben" starts) is lit.
    private func stepsRow(_ steps: [TodayChordPreview.Step]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.space2) { stepItems(steps) }
            VStack(alignment: .leading, spacing: Theme.space1) { stepItems(steps) }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func stepItems(_ steps: [TodayChordPreview.Step]) -> some View {
        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            HStack(spacing: 6) {
                Text("\(index + 1)")
                    .font(Display.eyebrow(11))
                    .frame(width: 18, height: 18)
                    .background(index == 0 ? palette.featureAccent : palette.onFeature.opacity(0.15), in: Circle())
                    .foregroundStyle(index == 0 ? palette.feature : palette.onFeature)
                Text("\(Strings.blockKind(step.kind)) \(step.chords)")
                    .font(.footnote.weight(index == 0 ? .semibold : .regular))
                    .opacity(index == 0 ? 1 : 0.8)
            }
        }
    }

    /// Full chord name, or just its quality when the session deals random keys
    /// (a calibration check would otherwise read as "C, C, C").
    private func chipLabel(_ chord: ChordWithNotes, anyKey: Bool) -> String {
        let full = Notation.chord(chord.chord)
        guard anyKey else { return full }
        let root = Notation.root(chord.root)
        return full.hasPrefix(root) ? String(full.dropFirst(root.count)) : full
    }

    /// Newcomers get the three-step guide; everyone else the stats with real numbers.
    @ViewBuilder private var guideOrStats: some View {
        let st = stage
        if st.showsGuide {
            NewcomerGuide(done: st.guideDone) {
                NewcomerGuideStore.dismissed = true
                withAnimation { guideDismissed = true }
            }
        } else {
            let s = computeStats(history)
            let items = StatsRow.items(streak: streak.current,
                                       avgMs: s.totalSessions > 0 ? s.overallAvgMs : nil,
                                       sessions: s.totalSessions)
            if !items.isEmpty { StatsRow(items: items) }
        }
    }

    /// "Oder einfach losspielen": plain rows to start without the coach.
    private var justPlay: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            EyebrowText(Strings.justPlay)
                .padding(.leading, Theme.space4)
            TrackGroup {
                Button { startSuggested = true } label: {
                    TrackRow(icon: "flame", title: planTitle(suggested.id), subtitle: Strings.warmupLine,
                             meta: planMeta(suggested), showsDivider: true)
                }
                .buttonStyle(.plain)
                if let plan = weakDrillPlan {
                    Button { startWeakDrill = true } label: {
                        TrackRow(icon: "scope", title: CoachL10n.t("results.drill_weak"),
                                 subtitle: Strings.weakSpotsLine, meta: weakDrillMeta(plan), showsDivider: true)
                    }
                    .buttonStyle(.plain)
                }
                Button { startToGo = true } label: {
                    TrackRow(icon: "headphones", title: CoachL10n.t(CoachL10n.ToGo.entry), subtitle: Strings.toGoLine)
                }
                .buttonStyle(.plain)
            }
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

    // MARK: helpers

    private func planTitle(_ id: String) -> String { Strings.planName(id) }
    private func planSubtitle(_ plan: PracticePlan) -> String {
        let prog = CoachL10n.progression(plan.settings.progressionMode)
        let v = CoachL10n.voicing(plan.settings.voicing)
        // "N chords" is a counted noun — plural form comes from the .stringsdict.
        let chords = CoachL10n.plural("count.chords", plan.settings.totalChords)
        return "\(v) · \(prog) · \(chords)"
    }

}
