// Gamification UI — level badge + celebration overlay (level-up, PB, streak, goal).

import SwiftUI
import MusicEngine

struct LevelBadge: View {
    @Environment(\.palette) private var palette
    let level: Int

    var body: some View {
        Text("\(level)")
            .font(.caption.weight(.bold).monospacedDigit())
            .foregroundStyle(palette.primaryText)
            .frame(width: 26, height: 26)
            .background(palette.primary)
            .clipShape(Circle())
            .overlay(Circle().stroke(palette.accentAmber.opacity(0.5), lineWidth: 1))
            .accessibilityLabel("Level \(level)")
    }
}

/// Full-screen celebration shown after a session when there are events to show.
/// Auto-advances through the queue; tap to dismiss.
struct CelebrationOverlay: View {
    @Environment(\.palette) private var palette
    let events: [CelebrationEvent]
    var onDone: () -> Void

    @State private var index = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            if index < events.count {
                let e = events[index]
                VStack(spacing: Theme.space4) {
                    ZStack {
                        Circle().fill(palette.primary.opacity(0.18)).frame(width: 130, height: 130)
                        Image(systemName: AppIcons.celebration(e.type))
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(palette.primary)
                            .symbolRenderingMode(.hierarchical)
                            .symbolEffect(.bounce, value: index)
                    }
                    Text(e.title)
                        .font(Display.title(34))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if let sub = e.subtitle {
                        Text(sub)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(Theme.space8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { scheduleAdvance() }
    }

    private func scheduleAdvance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if index < events.count { advance() }
        }
    }

    private func advance() {
        if index < events.count - 1 {
            withAnimation { index += 1 }
            scheduleAdvance()
        } else {
            onDone()
        }
    }
}
