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
                    title: "No sessions yet",
                    message: "Play your first drill and your speed, streaks, and weak spots will show up here.",
                    artName: "empty"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .navigationTitle("Progress")
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
            metric("\(habits.levelInfo.level)", "level")
            metric("\(streak.current)", "streak")
            metric(String(format: "%.1fs", stats.overallAvgMs / 1000), "avg")
            metric("\(stats.totalSessions)", "sessions")
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
            SectionHeader(text: "Speed trend")
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
            .chartYAxisLabel("s / chord")
        }
    }

    @ViewBuilder
    private var weakSpotsSection: some View {
        let spots = analyzeWeakSpots(history, 5)
        if !spots.isEmpty {
            VStack(alignment: .leading, spacing: Theme.space2) {
                SectionHeader(text: "Weak spots")
                ForEach(Array(spots.enumerated()), id: \.offset) { _, spot in
                    Button { drillSpot = spot } label: {
                        HStack {
                            Text("\(spot.root) \(VOICING_LABELS[spot.voicing] ?? spot.voicing.rawValue)")
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
                SectionHeader(text: "Personal bests")
                ForEach(Array(pbs.enumerated()), id: \.offset) { _, pb in
                    HStack {
                        Image(systemName: "trophy.fill").foregroundStyle(palette.accentGold)
                        Text(String(format: "%.1fs avg", pb.avgMs / 1000))
                            .foregroundStyle(palette.text)
                        Spacer()
                        Text("\(pb.totalChords) chords")
                            .font(.caption).foregroundStyle(palette.textDim)
                    }
                    .padding(Theme.space3)
                    .background(palette.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                }
            }
        }
    }

    /// Build a focused adaptive drill for a weak spot.
    private func drillPlan(for spot: WeakSpot) -> PracticePlan {
        PracticePlan(
            id: "weak-drill", name: "", tagline: "", description: "", icon: "🎯", accent: "var(--primary)", level: .intermediate,
            settings: PlanSettings(difficulty: .beginner, notation: .standard, voicing: spot.voicing,
                                   displayMode: .always, accidentals: .both, progressionMode: .random, totalChords: 20))
    }
}

extension WeakSpot: @retroactive Identifiable {
    public var id: String { "\(root)-\(voicing.rawValue)" }
}
