// Progress — live dashboards from saved history: level/XP/streak header, a
// last-N-sessions trend (Swift Charts), weak spots (with a drill action), and
// personal bests. Empty state until the first session lands.

import SwiftUI
import Charts
import MusicEngine

struct ProgressView_: View {
    @Environment(\.palette) private var palette
    @State private var habits = HabitStore.shared
    @State private var refresh = 0
    @State private var drillSpot: WeakSpot?

    private var history: [SessionResult] { ProgressStore.loadHistory() }
    private var streak: StreakData { ProgressStore.loadStreak() }

    var body: some View {
        Group {
            if history.isEmpty {
                EmptyStateView(
                    systemImage: "chart.line.uptrend.xyaxis",
                    title: CoachL10n.t("ui.insights_empty_title"),
                    message: CoachL10n.t("ui.insights_empty_desc"),
                    artName: "empty"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .navigationTitle(CoachL10n.t("nav.progress"))
        .screenBackground()
        .onAppear { habits.reload(); refresh += 1 }
        .refreshable { habits.reload(); refresh += 1 }
        .fullScreenCover(item: $drillSpot, onDismiss: { habits.reload(); refresh += 1 }) { spot in
            NavigationStack { TrainerView(plan: drillPlan(for: spot)) }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                statsHeader
                trendChart
                weakSpotsSection
                personalBestsSection
            }
            .padding(Theme.space4)
            .readableWidth(720)
            .id(refresh)
        }
    }

    private var stats: ProgressStats { computeStats(history) }

    private var statsHeader: some View {
        HStack(spacing: Theme.space3) {
            metric("\(habits.levelInfo.level)", CoachL10n.t("ui.stat_level"))
            metric("\(streak.current)", CoachL10n.t("ui.stat_streak"))
            metric(String(format: "%.1fs", stats.overallAvgMs / 1000), CoachL10n.t("ui.stat_avg"))
            metric("\(stats.totalSessions)", CoachL10n.t("ui.stat_sessions"))
        }
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(palette.primary)
            Text(label).font(.caption2).foregroundStyle(palette.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.space3)
        .background(palette.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
    }

    private var trendChart: some View {
        let recent = Array(history.prefix(12).reversed())
        return VStack(alignment: .leading, spacing: Theme.space2) {
            SectionHeader(text: CoachL10n.t("ui.speed_trend"))
            Chart {
                ForEach(Array(recent.enumerated()), id: \.offset) { idx, s in
                    LineMark(x: .value("Session", idx), y: .value("Avg s", s.avgMs / 1000))
                        .foregroundStyle(palette.primary)
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Session", idx), y: .value("Avg s", s.avgMs / 1000))
                        .foregroundStyle(palette.primary)
                }
            }
            .frame(height: 160)
            .chartYAxisLabel(CoachL10n.t("ui.seconds_per_chord"))
        }
    }

    @ViewBuilder
    private var weakSpotsSection: some View {
        let spots = analyzeWeakSpots(history, 5)
        if !spots.isEmpty {
            VStack(alignment: .leading, spacing: Theme.space2) {
                SectionHeader(text: CoachL10n.t("quickstart.weakspots_title"))
                ForEach(Array(spots.enumerated()), id: \.offset) { _, spot in
                    Button { drillSpot = spot } label: {
                        HStack {
                            // Root is typeset (D♭, not "Db"); voicing name is localized.
                            Text("\(Notation.root(spot.root)) \(CoachL10n.voicing(spot.voicing))")
                                .foregroundStyle(palette.text)
                            Spacer()
                            Text(String(format: "%.1fs", spot.avgMs / 1000))
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(palette.accentRed)
                            Image(systemName: "play.circle.fill").foregroundStyle(palette.primary)
                        }
                        .padding(Theme.space3)
                        .background(palette.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var personalBestsSection: some View {
        let pbs = stats.personalBests.values.sorted { $0.avgMs < $1.avgMs }.prefix(3)
        if !pbs.isEmpty {
            VStack(alignment: .leading, spacing: Theme.space2) {
                SectionHeader(text: CoachL10n.t("ui.personal_bests"))
                ForEach(Array(pbs.enumerated()), id: \.offset) { _, pb in
                    HStack {
                        Image(systemName: "trophy.fill").foregroundStyle(palette.accentGold)
                        Text(CoachL10n.t("ui.avg_suffix", ["seconds": String(format: "%.1f", pb.avgMs / 1000)]))
                            .foregroundStyle(palette.text)
                        Spacer()
                        Text(CoachL10n.plural("count.chords", pb.totalChords))
                            .font(.caption).foregroundStyle(palette.textDim)
                    }
                    .padding(Theme.space3)
                    .background(palette.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                }
            }
        }
    }

    /// Build a focused adaptive drill for a weak spot — concentrates on this root
    /// (10× weight) and hides the answer (`.verify`) so it's a real test, not a copy.
    private func drillPlan(for spot: WeakSpot) -> PracticePlan {
        PracticePlan(
            id: "weak-drill", name: "", tagline: "", description: "", icon: "", accent: "var(--primary)", level: .intermediate,
            settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: spot.voicing,
                                   displayMode: .verify, accidentals: .both, progressionMode: .random, totalChords: 20),
            focusRoots: [spot.root], focusVoicing: spot.voicing.rawValue)
    }
}

extension WeakSpot: @retroactive Identifiable {
    public var id: String { "\(root)-\(voicing.rawValue)" }
}
