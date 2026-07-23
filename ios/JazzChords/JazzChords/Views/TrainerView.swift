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

    /// When true, launch the Auto-Mode (Coach) session on appear instead of a plan.
    var coachSession = false

    var body: some View {
        Group {
            switch store.screen {
            case .setup: TrainerSetupView(store: store, onClose: { dismiss() })
            case .playing:
                ZStack {
                    TrainerPlayingView(store: store, onClose: { store.resetToSetup() })
                    // Between-block transition overlay (Coach only).
                    if let t = store.coachTransition {
                        CoachTransitionView(transition: t) { store.advanceCoachBlock() }
                    }
                }
            case .earTraining: EarTrainingView(store: store, onClose: { store.resetToSetup() })
            case .finished:
                // Coach sessions land on a teacher-feedback screen; normal drills on stats.
                if store.coachShowFeedback {
                    CoachFeedbackView(store: store,
                                      onAgain: { store.restartCoachSession() },
                                      onDone: { store.endCoachMode(); dismiss() })
                } else {
                    TrainerFinishedView(store: store, onClose: { dismiss() })
                }
            }
        }
        .screenBackground()
        .onAppear {
            store.loadSettings()
            if coachSession {
                store.startCoachSession()
            } else if let plan {
                store.apply(plan: plan)
                store.startSession()
            }
        }
    }
}

// ─── Coach: between-block transition ────────────────────────

/// A calm 1-line "block done → next up" screen. Auto-advances after ~2.5s
/// (handled by the store); tapping anywhere advances immediately.
struct CoachTransitionView: View {
    @Environment(\.palette) private var palette
    let transition: TrainerStore.CoachTransition
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            palette.bg.opacity(0.96).ignoresSafeArea()
            VStack(spacing: Theme.space5) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(palette.accentGreen)
                    .symbolRenderingMode(.hierarchical)
                Text(CoachL10n.blockDone(transition.doneKind))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textMuted)
                Text(CoachL10n.t(transition.nextLabelKey, transition.nextLabelParams))
                    .font(Display.headline(26))
                    .foregroundStyle(palette.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.space5)
                Spacer()
                Text(CoachL10n.t(CoachL10n.transitionContinue))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(palette.textDim)
                    .padding(.bottom, Theme.space5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
        .transition(.opacity)
    }
}

// ─── Coach: post-session teacher feedback ───────────────────

/// Teacher talk + the "too easy / just right / too hard" valve + Again/Done.
struct CoachFeedbackView: View {
    @Environment(\.palette) private var palette
    @Bindable var store: TrainerStore
    var onAgain: () -> Void
    var onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                Text(CoachL10n.t(CoachL10n.feedbackTitle))
                    .font(Display.title(32))
                    .foregroundStyle(palette.text)
                    .padding(.top, Theme.space4)

                // Teacher statements (localized).
                VStack(alignment: .leading, spacing: Theme.space3) {
                    ForEach(Array(store.coachFeedback.enumerated()), id: \.offset) { _, stmt in
                        HStack(alignment: .top, spacing: Theme.space3) {
                            Image(systemName: statementIcon(stmt.kind))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(palette.primary)
                                .symbolRenderingMode(.hierarchical)
                                .frame(width: 24)
                            Text(CoachL10n.t(stmt.key, stmt.params))
                                .font(.body)
                                .foregroundStyle(palette.text)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(Theme.space4)
                .glassCard()

                // Feedback valve.
                VStack(alignment: .leading, spacing: Theme.space3) {
                    Text(CoachL10n.t(CoachL10n.valvePrompt))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textMuted)
                    if store.coachFeedbackGiven {
                        Label(CoachL10n.t(CoachL10n.valveThanks), systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(palette.accentGreen)
                    } else {
                        HStack(spacing: Theme.space2) {
                            valveButton(CoachL10n.valveTooEasy, .tooEasy)
                            valveButton(CoachL10n.valveJustRight, .justRight)
                            valveButton(CoachL10n.valveTooHard, .tooHard)
                        }
                    }
                }

                Spacer(minLength: Theme.space5)

                VStack(spacing: Theme.space3) {
                    Button { onAgain() } label: {
                        Text(CoachL10n.t(CoachL10n.feedbackAgain))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.space4)
                            .background(palette.primary)
                            .foregroundStyle(palette.primaryText)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                    }
                    Button { onDone() } label: {
                        Text(CoachL10n.t(CoachL10n.feedbackDone))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.space4)
                            .foregroundStyle(palette.text)
                            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(palette.border))
                    }
                }
            }
            .padding(Theme.space4)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .navigationBarBackButtonHidden()
    }

    private func valveButton(_ key: String, _ signal: FeedbackSignal) -> some View {
        Button { store.applyCoachFeedback(signal) } label: {
            Text(CoachL10n.t(key))
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.space3)
                .foregroundStyle(palette.text)
                .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(palette.border))
        }
    }

    private func statementIcon(_ kind: TeacherStatement.Kind) -> String {
        switch kind {
        case .promoted: return "checkmark.seal.fill"
        case .held: return "arrow.clockwise"
        case .demoted: return "arrow.down.circle"
        case .improved: return "bolt.fill"
        case .placed: return "forward.fill"
        case .nextGoal: return "target"
        case .calibrated: return "checkmark.circle.fill"
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
                pickerRow("Input") {
                    Picker("", selection: $store.inputMode) {
                        Text("Tap").tag(TrainerStore.InputMode.none)
                        Text("MIDI").tag(TrainerStore.InputMode.midi)
                        Text("Mic").tag(TrainerStore.InputMode.microphone)
                    }.pickerStyle(.segmented)
                }
                if store.inputMode == .microphone {
                    Text("Play chords into your mic — clear, sustained voicings work best.")
                        .font(.footnote).foregroundStyle(palette.textDim)
                }

                Toggle("Audio", isOn: $store.audioEnabled)
                    .tint(palette.primary)
                    .foregroundStyle(palette.text)
                Toggle("Ear training (guess by ear)", isOn: $store.isEarTraining)
                    .tint(palette.primary)
                    .foregroundStyle(palette.text)
                Toggle("In-time (metronome advances)", isOn: $store.inTimeMode)
                    .tint(palette.primary)
                    .foregroundStyle(palette.text)
                if store.inTimeMode {
                    HStack {
                        Text("Tempo").font(.subheadline).foregroundStyle(palette.textMuted)
                        Slider(value: Binding(get: { Double(store.metronomeBpm) }, set: { store.metronomeBpm = Int($0) }), in: 40...200, step: 5)
                            .tint(palette.primary)
                        Text("\(store.metronomeBpm)").font(.caption.monospacedDigit()).foregroundStyle(palette.text).frame(width: 36)
                    }
                }

                Button {
                    store.startSession()
                } label: {
                    Text(store.isEarTraining ? "Start ear training" : "Start drill")
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
    @Environment(\.verticalSizeClass) private var vSize
    @Environment(\.horizontalSizeClass) private var hSize
    @Bindable var store: TrainerStore

    var onClose: () -> Void

    private var isLandscape: Bool { vSize == .compact }
    private var isPad: Bool { hSize == .regular }
    /// iPad shows a roomier 3-octave keyboard.
    private var keyboardOctaves: OctaveCount? {
        if isPad { return .three }
        return store.sessionOctaves
    }

    var body: some View {
        VStack(spacing: isPad ? Theme.space5 : Theme.space3) {
            topBar
            if isLandscape {
                // Landscape: chord left, keyboard right — fits the short height.
                HStack(spacing: Theme.space5) {
                    chordBlock
                        .frame(maxWidth: .infinity)
                    VStack(spacing: Theme.space3) {
                        keyboardBlock
                        controls
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Spacer(minLength: 0)
                chordBlock
                Spacer(minLength: 0)
                keyboardBlock
                if store.inputActive { inputHint }
                Spacer(minLength: 0)
                controls
            }
        }
        .padding(isPad ? Theme.space6 : Theme.space4)
        // iPad uses the full width for a big keyboard; iPhone keeps a tidy cap.
        .frame(maxWidth: (isLandscape || isPad) ? .infinity : 760)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .navigationBarBackButtonHidden()
    }

    private var topBar: some View {
        VStack(spacing: Theme.space2) {
            HStack {
                Text("\(store.currentIdx + 1) / \(store.actualTotalChords)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(palette.textMuted)
                Spacer()
                Button { onClose() } label: {
                    Image(systemName: "xmark.circle.fill").font(isPad ? .title2 : .body)
                }
                .foregroundStyle(palette.textDim)
            }
            ProgressView(value: store.progress).tint(palette.primary)
        }
    }

    private var chordBlock: some View {
        VStack(spacing: Theme.space2) {
            Text(displayedChord)
                .font(Display.chord(chordFontSize))
                .foregroundStyle(palette.text)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if store.shouldShowVoicing, let d = store.currentData {
                if let r = store.tapResult {
                    // Reveal after a tap-guess: show whether the built chord was right.
                    Label(r ? "Correct" : "Not quite", systemImage: r ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font((isPad ? Font.body : Font.caption).weight(.semibold))
                        .foregroundStyle(r ? palette.accentGreen : palette.accentRed)
                }
                Text(VOICING_LABELS[store.voicing]?.uppercased() ?? "")
                    .font((isPad ? Font.body : Font.caption).weight(.semibold)).tracking(1.5)
                    .foregroundStyle(palette.primary)
                Text(formatVoicing(d, store.voicing, store.notationSystem))
                    .font(.system(isPad ? .title3 : .body, design: .monospaced))
                    .foregroundStyle(palette.textMuted)
            } else if store.isTapGuessMode {
                Text("Build the chord, then Check")
                    .font((isPad ? Font.body : Font.caption).weight(.medium))
                    .foregroundStyle(palette.textDim)
            }
        }
    }

    private var chordFontSize: CGFloat {
        if isLandscape { return isPad ? 72 : 52 }
        return isPad ? 120 : 68
    }

    @ViewBuilder
    private var keyboardBlock: some View {
        if store.shouldShowVoicing || store.inputActive || store.isTapGuessMode {
            PianoKeyboard(
                chordData: store.currentData,
                accidentalPref: store.accidentals,
                showVoicing: store.shouldShowVoicing,
                forceOctaves: keyboardOctaves,
                interactive: store.isTapGuessMode,
                selectedPitchClasses: store.tapGuess,
                heldNotes: store.heldNotes,
                expectedPitchClasses: store.expectedPitchClasses,
                showInput: store.inputActive,
                onKeyTap: store.isTapGuessMode ? { store.tapToggle($0) } : nil,
                maxHeight: isPad ? (isLandscape ? 240 : 320) : 200
            )
        }
    }

    private var inputHint: some View {
        Label(inputStatus, systemImage: store.inputMode == .midi ? "pianokeys.inverse" : "mic.fill")
            .font(.caption)
            .foregroundStyle(palette.textMuted)
    }

    @ViewBuilder
    private var controls: some View {
        if store.inTimeMode {
            // Metronome drives advancement; show a calm in-time indicator.
            HStack(spacing: Theme.space2) {
                Image(systemName: "metronome.fill").foregroundStyle(palette.primary)
                Text("Playing in time · \(store.metronomeBpm) BPM")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.space4)
            .glassCard()
            .onAppear { if !store.timerStarted { store.next() } } // kick off timer + metronome
        } else {
            HStack(spacing: Theme.space3) {
                Button { store.replayChord() } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .frame(width: Theme.tapMin, height: Theme.tapMin)
                        .glassCard(cornerRadius: Theme.tapMin / 2)
                        .foregroundStyle(palette.text)
                }
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    store.next()
                } label: {
                    Text(nextLabel)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space4)
                        .background(palette.primary, in: RoundedRectangle(cornerRadius: Theme.radius))
                        .foregroundStyle(palette.primaryText)
                }
            }
        }
    }

    private var displayedChord: String {
        convertChordNotation(store.currentChord, store.notationSystem)
    }
    private var nextLabel: String {
        // Tap-guess: the primary action reveals + grades before advancing.
        if store.isTapGuessMode { return store.tapGuess.isEmpty ? "Show me" : "Check" }
        if store.currentIdx >= store.actualTotalChords - 1 { return "Finish" }
        return "Next chord"
    }
    private var inputStatus: String {
        if store.inputMode == .midi {
            return MIDIInput.shared.connected ? "Play it on your keyboard" : "Connect a MIDI keyboard"
        }
        return "Play it — listening…"
    }
}

// ─── Finished ───────────────────────────────────────────────

struct TrainerFinishedView: View {
    @Environment(\.palette) private var palette
    @Bindable var store: TrainerStore
    var onClose: () -> Void

    @State private var showCelebration = true

    var body: some View {
        ZStack {
            content
            if showCelebration && !store.pendingCelebrations.isEmpty {
                CelebrationOverlay(events: store.pendingCelebrations) {
                    withAnimation { showCelebration = false }
                    store.pendingCelebrations = []
                }
            }
        }
    }

    private var content: some View {
        VStack(spacing: Theme.space5) {
            Spacer()
            Text("Nice work")
                .font(Display.title(34))
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
                if store.canDrillWeakSpots {
                    // Peak-motivation moment: drill the chords you were slowest at.
                    Button { store.startWeakDrill() } label: {
                        Label("Drill your weak spots", systemImage: "target")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.space4)
                            .background(palette.primary)
                            .foregroundStyle(palette.primaryText)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                    }
                    Button { store.restart() } label: {
                        Text("Again (same session)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.space4)
                            .foregroundStyle(palette.text)
                            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(palette.border))
                    }
                } else {
                    Button { store.restart() } label: {
                        Text("Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.space4)
                            .background(palette.primary)
                            .foregroundStyle(palette.primaryText)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                    }
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
                .font(Display.headline(26))
                .foregroundStyle(palette.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(palette.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.space4)
        .glassCard()
    }
}
