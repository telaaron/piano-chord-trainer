// TrainerView — hosts the drill state machine UI (setup → playing → finished).
// Presented as a full-screen cover from Practice / Today.

import SwiftUI
import MusicEngine

struct TrainerView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var store = TrainerStore()

    /// Optional plan to apply + auto-start on appear (from Practice / Today).
    var plan: PracticePlan?

    var body: some View {
        Group {
            switch store.screen {
            case .setup: TrainerSetupView(store: store, onClose: { dismiss() })
            case .playing: TrainerPlayingView(store: store, onClose: { store.resetToSetup() })
            case .finished: TrainerFinishedView(store: store, onClose: { dismiss() })
            }
        }
        .screenBackground()
        .onAppear {
            store.loadSettings()
            if let plan {
                store.apply(plan: plan)
                store.startGame()
            }
        }
    }
}

// ─── Setup ──────────────────────────────────────────────────

struct TrainerSetupView: View {
    @Environment(\.palette) private var palette
    @Bindable var store: TrainerStore
    var onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                pickerRow("Difficulty") {
                    Picker("", selection: $store.difficulty) {
                        Text("Beginner").tag(Difficulty.beginner)
                        Text("Intermediate").tag(Difficulty.intermediate)
                        Text("Advanced").tag(Difficulty.advanced)
                    }.pickerStyle(.segmented)
                }
                pickerRow("Voicing") {
                    Picker("", selection: $store.voicing) {
                        ForEach(VoicingType.allCases, id: \.self) { v in
                            Text(VOICING_LABELS[v] ?? v.rawValue).tag(v)
                        }
                    }
                }
                pickerRow("Progression") {
                    Picker("", selection: $store.progressionMode) {
                        ForEach(ProgressionMode.allCases, id: \.self) { m in
                            Text(PROGRESSION_LABELS[m] ?? m.rawValue).tag(m)
                        }
                    }
                }
                pickerRow("Reveal") {
                    Picker("", selection: $store.displayMode) {
                        Text("Always").tag(DisplayMode.always)
                        Text("On reveal").tag(DisplayMode.verify)
                        Text("Off").tag(DisplayMode.off)
                    }.pickerStyle(.segmented)
                }
                Toggle("Audio", isOn: $store.audioEnabled)
                    .tint(palette.primary)
                    .foregroundStyle(palette.text)

                Button {
                    store.startGame()
                } label: {
                    Text("Start drill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space4)
                        .background(palette.primary)
                        .foregroundStyle(palette.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                }
            }
            .padding(Theme.space4)
        }
        .navigationTitle("Trainer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { onClose() }
            }
        }
    }

    private func pickerRow<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(palette.textMuted)
            content().tint(palette.primary)
        }
    }
}

// ─── Playing ────────────────────────────────────────────────

struct TrainerPlayingView: View {
    @Environment(\.palette) private var palette
    @Bindable var store: TrainerStore

    var onClose: () -> Void

    var body: some View {
        VStack(spacing: Theme.space5) {
            // Progress + counter
            HStack {
                Text("\(store.currentIdx + 1) / \(store.actualTotalChords)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(palette.textMuted)
                Spacer()
                Button { onClose() } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(palette.textDim)
            }
            ProgressView(value: store.progress)
                .tint(palette.primary)

            Spacer()

            // Chord symbol
            VStack(spacing: Theme.space2) {
                Text(displayedChord)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.text)
                    .contentTransition(.numericText())
                if store.shouldShowVoicing, let d = store.currentData {
                    Text(VOICING_LABELS[store.voicing]?.uppercased() ?? "")
                        .font(.caption.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(palette.primary)
                    Text(formatVoicing(d, store.voicing, store.notationSystem))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(palette.textMuted)
                }
            }

            // Keyboard
            if store.shouldShowVoicing {
                PianoKeyboard(
                    chordData: store.currentData,
                    accidentalPref: store.accidentals,
                    showVoicing: true,
                    forceOctaves: store.sessionOctaves
                )
                .padding(.horizontal, Theme.space2)
            }

            Spacer()

            // Replay + Next
            HStack(spacing: Theme.space3) {
                Button { store.replayChord() } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .frame(width: Theme.tapMin, height: Theme.tapMin)
                        .background(palette.bgCard)
                        .foregroundStyle(palette.text)
                        .clipShape(Circle())
                }
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    store.next()
                } label: {
                    Text(nextLabel)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space4)
                        .background(palette.primary)
                        .foregroundStyle(palette.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                }
            }
        }
        .padding(Theme.space4)
        .navigationBarBackButtonHidden()
        // Big invisible tap target: tap anywhere advances (like Space on web).
        .contentShape(Rectangle())
        .onTapGesture { store.next() }
    }

    private var displayedChord: String {
        convertChordNotation(store.currentChord, store.notationSystem)
    }
    private var nextLabel: String {
        if store.currentIdx >= store.actualTotalChords - 1 { return "Finish" }
        return "Next chord"
    }
}

// ─── Finished ───────────────────────────────────────────────

struct TrainerFinishedView: View {
    @Environment(\.palette) private var palette
    @Bindable var store: TrainerStore
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: Theme.space5) {
            Spacer()
            Text("Nice work")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(palette.text)

            if let r = store.lastResult {
                HStack(spacing: Theme.space3) {
                    statCard(value: String(format: "%.1fs", r.avgMs / 1000), label: "avg / chord")
                    statCard(value: "\(r.totalChords)", label: "chords")
                    statCard(value: String(format: "%.0fs", r.elapsedMs / 1000), label: "total")
                }
            }

            Spacer()

            VStack(spacing: Theme.space3) {
                Button { store.restart() } label: {
                    Text("Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space4)
                        .background(palette.primary)
                        .foregroundStyle(palette.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                }
                Button { onClose() } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space4)
                        .foregroundStyle(palette.text)
                        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(palette.border))
                }
            }
        }
        .padding(Theme.space4)
        .navigationBarBackButtonHidden()
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: Theme.space1) {
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(palette.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(palette.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.space4)
        .background(palette.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
    }
}
