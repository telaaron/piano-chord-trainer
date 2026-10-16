// Progress — editorial header with level eyebrow, streak/speed/sessions stats, a
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
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                EditorialHeader(eyebrow: Strings.progressEyebrow(level: habits.levelInfo.level), title: CoachL10n.t("nav.progress"))
                if history.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.line.uptrend.xyaxis",
                        title: CoachL10n.t("ui.insights_empty_title"),
                        message: CoachL10n.t("ui.insights_empty_desc"),
                        artName: "empty"
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    statsHeader
                    trendChart
                    weakSpotsSection
                    personalBestsSection
                }
            }
            .padding(.horizontal, Theme.space4)
            .padding(.vertical, Theme.space3)
            .readableWidth(720)
            .id(refresh)
        }
        .screenBackground()
        .onAppear { habits.reload(); refresh += 1 }
        .refreshable { habits.reload(); refresh += 1 }
        // Account data from another device landed in the stores: show it.
        .onChange(of: SyncService.shared.revision) { habits.reload(); refresh += 1 }
        .fullScreenCover(item: $drillSpot, onDismiss: { habits.reload(); refresh += 1 }) { spot in
            NavigationStack { TrainerView(plan: drillPlan(for: spot)) }
        }
    }

    private var stats: ProgressStats { computeStats(history) }

    private var statsHeader: some View {
        StatsRow(items: [
            StatItem(value: "\(streak.current)", label: Strings.statDaysInRow),
            StatItem(value: Strings.seconds(stats.overallAvgMs / 1000), label: Strings.statPerChord),
            StatItem(value: "\(stats.totalSessions)", label: Strings.statSessions),
        ])
    }

    private var trendChart: some View {
        let recent = Array(history.prefix(12).reversed())
        return VStack(alignment: .leading, spacing: Theme.space2) {
            SectionHeader(text: CoachL10n.t("ui.speed_trend"))
            Chart {
                ForEach(Array(recent.enumerated()), id: \.offset) { idx, s in
                    AreaMark(x: .value("Session", idx), y: .value("Avg s", s.avgMs / 1000))
                        .foregroundStyle(palette.music.opacity(0.14))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Session", idx), y: .value("Avg s", s.avgMs / 1000))
                        .foregroundStyle(palette.music)
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Session", idx), y: .value("Avg s", s.avgMs / 1000))
                        .foregroundStyle(palette.music)
                        .symbolSize(24)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(palette.hairline)
                    AxisValueLabel().foregroundStyle(palette.inkMuted)
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
                TrackGroup {
                    ForEach(Array(spots.enumerated()), id: \.offset) { idx, spot in
                        Button { drillSpot = spot } label: {
                            // Root is typeset (D♭, not "Db"); voicing name is localized.
                            TrackRow(badge: Notation.root(spot.root),
                                     title: CoachL10n.voicing(spot.voicing),
                                     meta: "Ø " + Strings.seconds(spot.avgMs / 1000),
                                     showsDivider: idx < spots.count - 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var personalBestsSection: some View {
        let pbs = Array(stats.personalBests.values.sorted { $0.avgMs < $1.avgMs }.prefix(3))
        if !pbs.isEmpty {
            VStack(alignment: .leading, spacing: Theme.space2) {
                SectionHeader(text: CoachL10n.t("ui.personal_bests"))
                TrackGroup {
                    ForEach(Array(pbs.enumerated()), id: \.offset) { idx, pb in
                        TrackRow(number: "0\(idx + 1)",
                                 title: CoachL10n.t("ui.avg_suffix", ["seconds": String(format: "%.1f", pb.avgMs / 1000)]),
                                 meta: CoachL10n.plural("count.chords", pb.totalChords),
                                 showsDivider: idx < pbs.count - 1,
                                 showsChevron: false)
                    }
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
