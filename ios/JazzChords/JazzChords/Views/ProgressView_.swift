// Progress — trend, weak spots, PBs, streak. M1: empty state (no sessions yet).
// Live dashboards (computeStats / analyzeWeakSpots) land M3 once persistence exists.

import SwiftUI
import MusicEngine

struct ProgressView_: View {
    @Environment(\.palette) private var palette

    // M1: no persisted history yet → empty state.
    private let history: [SessionResult] = []

    var body: some View {
        Group {
            if history.isEmpty {
                EmptyStateView(
                    systemImage: "chart.line.uptrend.xyaxis",
                    title: "No sessions yet",
                    message: "Play your first drill and your speed, streaks, and weak spots will show up here."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView { /* M3: dashboards */ }
            }
        }
        .navigationTitle("Progress")
        .screenBackground()
    }
}
