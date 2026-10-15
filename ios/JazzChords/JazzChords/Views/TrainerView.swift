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

    /// × in a session started from Heute/Üben/Fortschritt returns there; only
    /// free practice (opened on the setup screen) goes back to setup.
    nonisolated static func closeLeavesTrainer(coachSession: Bool, hasPlan: Bool) -> Bool {
        coachSession || hasPlan
    }

    private func closeSession() {
        store.resetToSetup()
        if Self.closeLeavesTrainer(coachSession: coachSession, hasPlan: plan != nil) { dismiss() }
    }

    var body: some View {
        Group {
            switch store.screen {
            case .setup: TrainerSetupView(store: store, onClose: { dismiss() })
            case .playing:
                ZStack {
                    TrainerPlayingView(store: store, onClose: { closeSession() })
                    // Between-block transition overlay (Coach only).
                    if let t = store.coachTransition {
                        CoachTransitionView(transition: t) { store.advanceCoachBlock() }
                    }
                }
            case .earTraining: EarTrainingView(store: store, onClose: { closeSession() })
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
            store.autoSelectInput()
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
            palette.canvas.opacity(0.96).ignoresSafeArea()
            VStack(spacing: Theme.space5) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(palette.music)
                    .symbolRenderingMode(.hierarchical)
                Text(CoachL10n.blockDone(transition.doneKind))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.inkMuted)
                Text(CoachL10n.t(transition.nextLabelKey, transition.nextLabelParams))
                    .font(Display.headline(26))
                    .foregroundStyle(palette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.space5)
                Spacer()
                Text(CoachL10n.t(CoachL10n.transitionContinue))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(palette.inkMuted)
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
                    .foregroundStyle(palette.ink)
                    .padding(.top, Theme.space4)

                // Teacher statements (localized).
                VStack(alignment: .leading, spacing: Theme.space3) {
                    ForEach(Array(store.coachFeedback.enumerated()), id: \.offset) { _, stmt in
                        HStack(alignment: .top, spacing: Theme.space3) {
                            Image(systemName: statementIcon(stmt.kind))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(palette.action)
                                .symbolRenderingMode(.hierarchical)
                                .frame(width: 24)
                            Text(CoachL10n.t(stmt.key, stmt.params))
                                .font(.body)
                                .foregroundStyle(palette.ink)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(Theme.space4)
                .groupSurface()

                // System-detected verdict — the app never asks "too easy?".
                if store.coachVerdict == .excellent {
                    Label(CoachL10n.t(CoachL10n.verdictExcellent), systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.music)
                        .padding(Theme.space4)
                        .frame(maxWidth: .infinity)
                        .background(palette.action.opacity(0.15), in: RoundedRectangle(cornerRadius: Theme.radius))
                } else if store.coachVerdict == .struggling, !store.coachFeedbackGiven {
                    VStack(alignment: .leading, spacing: Theme.space3) {
                        Text(CoachL10n.t(CoachL10n.verdictStruggling))
                            .font(.subheadline)
                            .foregroundStyle(palette.inkMuted)
                        Button { store.startEasierAndContinue() } label: {
                            Text(CoachL10n.t(CoachL10n.verdictStartEasier))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(palette.action)
                                .padding(.vertical, Theme.space2).padding(.horizontal, Theme.space3)
                                .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(palette.action, lineWidth: 2))
                        }
                    }
                    .padding(Theme.space4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(palette.hairline))
                }

                ReminderOfferCard()

                Spacer(minLength: Theme.space5)

                VStack(spacing: Theme.space3) {
                    Button { onAgain() } label: {
                        Text(CoachL10n.t(CoachL10n.feedbackKeepGoing))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.space4)
                            .background(palette.action)
                            .foregroundStyle(palette.onAction)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                    }
                    Button { onDone() } label: {
                        Text(CoachL10n.t(CoachL10n.feedbackEnoughToday))
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.space3)
                            .foregroundStyle(palette.inkMuted)
                    }
                }
            }
            .padding(Theme.space4)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .navigationBarBackButtonHidden()
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
                pickerRow(CoachL10n.t("settings.difficulty")) {
                    Picker("", selection: $store.difficulty) {
                        Text(CoachL10n.t("settings.difficulty_beginner")).tag(Difficulty.beginner)
                        Text(CoachL10n.t("settings.difficulty_intermediate")).tag(Difficulty.intermediate)
                        Text(CoachL10n.t("settings.difficulty_advanced")).tag(Difficulty.advanced)
                    }.pickerStyle(.segmented)
                }
                pickerRow(CoachL10n.t("results.voicing")) {
                    Picker("", selection: $store.voicing) {
                        ForEach(VoicingType.allCases, id: \.self) { v in
                            Text(CoachL10n.voicing(v)).tag(v)
                        }
                    }
                }
                pickerRow(CoachL10n.t("settings.progression_mode")) {
                    Picker("", selection: $store.progressionMode) {
                        ForEach(ProgressionMode.allCases, id: \.self) { m in
                            Text(CoachL10n.progression(m)).tag(m)
                        }
                    }
                }
                pickerRow(CoachL10n.t("settings.display_mode")) {
                    Picker("", selection: $store.displayMode) {
                        Text(CoachL10n.t("settings.display_mode_always")).tag(DisplayMode.always)
                        Text(CoachL10n.t("settings.display_mode_verify")).tag(DisplayMode.verify)
                        Text(CoachL10n.t("settings.display_mode_off")).tag(DisplayMode.off)
                    }.pickerStyle(.segmented)
                }
                pickerRow(CoachL10n.t("settings.input_mode")) {
                    Picker("", selection: $store.inputMode) {
                        Text(CoachL10n.t("settings.input_mode_none")).tag(TrainerStore.InputMode.none)
                        Text(CoachL10n.t("settings.input_mode_midi")).tag(TrainerStore.InputMode.midi)
                        Text(CoachL10n.t("settings.input_mode_mic")).tag(TrainerStore.InputMode.microphone)
                    }.pickerStyle(.segmented)
                }
                if store.inputMode == .microphone {
                    Text(CoachL10n.t("settings.mic_hint"))
                        .font(.footnote).foregroundStyle(palette.inkMuted)
                }

                Toggle(CoachL10n.t("ui.audio"), isOn: $store.audioEnabled)
                    .tint(palette.action)
                    .foregroundStyle(palette.ink)
                Toggle(CoachL10n.t("settings.ear_training_toggle"), isOn: $store.isEarTraining)
                    .tint(palette.action)
                    .foregroundStyle(palette.ink)
                Toggle(CoachL10n.t("settings.in_time_toggle"), isOn: $store.inTimeMode)
                    .tint(palette.action)
                    .foregroundStyle(palette.ink)
                if store.inTimeMode {
                    HStack {
                        Text(CoachL10n.t("ui.tempo")).font(.subheadline).foregroundStyle(palette.inkMuted)
                        Slider(value: Binding(get: { Double(store.metronomeBpm) }, set: { store.metronomeBpm = Int($0) }), in: 40...200, step: 5)
                            .tint(palette.action)
                        Text("\(store.metronomeBpm)").font(.caption.monospacedDigit()).foregroundStyle(palette.ink).frame(width: 36)
                    }
                }

                Button {
                    store.startSession()
                } label: {
                    Text(CoachL10n.t(store.isEarTraining ? "ui.ear_training_start" : "settings.start_training"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space4)
                        .background(palette.action)
                        .foregroundStyle(palette.onAction)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                }
            }
            .padding(Theme.space4)
        }
        .navigationTitle(CoachL10n.t("nav.trainer"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(CoachL10n.t("ui.close")) { onClose() }
            }
        }
    }

    private func pickerRow<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(palette.inkMuted)
            content().tint(palette.action)
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
                leadSheet
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
        .screenBackground()
        // iPad uses the full width for a big keyboard; iPhone keeps a tidy cap.
        .frame(maxWidth: (isLandscape || isPad) ? .infinity : 760)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .navigationBarBackButtonHidden()
    }

    private var topBar: some View {
        HStack(spacing: Theme.space2) {
            GlassCircleButton(systemImage: "xmark", label: CoachL10n.t("ui.close")) { onClose() }
            HStack(spacing: Theme.space3) {
                ProgressView(value: store.progress)
                    .tint(palette.musicFill)
                Text("\(store.currentIdx + 1)/\(store.actualTotalChords)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(palette.ink)
            }
            .padding(.horizontal, Theme.space4)
            .frame(height: Theme.tapMin)
            .glassControl(in: Capsule())
            GlassCircleButton(systemImage: "speaker.wave.2.fill", label: Strings.listen) { store.replayChord() }
        }
    }

    /// Previous | current | next over a staff — only when playing a progression.
    @ViewBuilder
    private var leadSheet: some View {
        if store.progressionMode != .random, store.currentIdx < store.chords.count {
            LeadSheetStrip(previous: chordName(at: store.currentIdx - 1),
                           current: displayedChord,
                           next: chordName(at: store.currentIdx + 1))
        }
    }

    private func chordName(at index: Int) -> String? {
        guard index >= 0, index < store.chords.count else { return nil }
        return Notation.chord(store.chords[index], store.notationSystem)
    }

    /// The function grid has a verdict once a tap-guess is graded or live input
    /// is sounding.
    private var gridShowsResult: Bool {
        store.tapResult != nil || (store.inputActive && !store.heldNotes.isEmpty)
    }

    private var gridHeld: Set<Int> {
        FunctionGrid.held(inputActive: store.inputActive, heldNotes: store.heldNotes, tapGuess: store.tapGuess)
    }

    private var chordBlock: some View {
        VStack(spacing: Theme.space2) {
            Text(CoachL10n.voicing(store.voicing))
                .font(Display.serif(isPad ? 26 : 22, italic: true, relativeTo: .title3))
                .foregroundStyle(palette.inkMuted)
            // Kalam's line box is ~1.6 em, so a 148 pt chord needs ~236 pt of
            // height. Step down when the screen (iPhone SE, XXL type) is short
            // instead of squeezing the keyboard.
            ViewThatFits(in: .vertical) {
                ForEach([chordFontSize, chordFontSize * 0.75, chordFontSize * 0.55], id: \.self) { size in
                    Text(displayedChord)
                        .font(Display.chord(size))
                        .foregroundStyle(palette.ink)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
            // Only once the voicing may be seen — in Verify/Off the grid would
            // give the answer away before the attempt.
            if store.shouldShowVoicing, let d = store.currentData {
                FunctionGrid(tones: FunctionGrid.tones(
                    voicingNotes: d.voicing.map(Notation.root),
                    labels: getVoicingIntervalLabels(d.voicing, d.root, d.type).map(Strings.intervalFunction),
                    held: gridHeld,
                    showResult: gridShowsResult))
                    .frame(maxWidth: 320)
            } else if store.isTapGuessMode {
                Text(CoachL10n.t("ui.tap_build"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.inkMuted)
            }
            if let r = store.tapResult {
                Text(CoachL10n.t(r ? "ui.correct" : "ui.not_quite"))
                    .font(.body.weight(.medium))
                    .foregroundStyle(r ? palette.music : palette.action)
            }
        }
    }

    private var chordFontSize: CGFloat {
        if isLandscape { return isPad ? 96 : 64 }
        return isPad ? 180 : 148
    }

    @ViewBuilder
    private var keyboardBlock: some View {
        if store.shouldShowVoicing || store.inputActive || store.isTapGuessMode {
            VStack(spacing: Theme.space3) {
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
                    maxHeight: isPad ? (isLandscape ? 240 : 320) : 200,
                    showMissing: store.tapResult == false
                )
                // Edge to edge on iPhone portrait (the stack is padded).
                .padding(.horizontal, (isPad || isLandscape) ? 0 : -Theme.space4)
                // The keyboard is the input; the chord gives way first.
                .layoutPriority(1)
                if let next = chordName(at: store.currentIdx + 1) {
                    (Text(Strings.nextPrefix) + Text(" ") + Text(next).font(Display.chord(19, relativeTo: .body)).foregroundStyle(palette.music))
                        .font(Display.serif(17, italic: true, relativeTo: .body))
                        .foregroundStyle(palette.inkMuted)
                }
            }
        }
    }

    private var inputHint: some View {
        Label(inputStatus, systemImage: store.inputMode == .midi ? "pianokeys.inverse" : "mic.fill")
            .font(.caption)
            .foregroundStyle(palette.inkMuted)
    }

    @ViewBuilder
    private var controls: some View {
        if store.inTimeMode {
            // Metronome drives advancement; show a calm in-time indicator.
            HStack(spacing: Theme.space2) {
                Image(systemName: "metronome.fill").foregroundStyle(palette.music)
                Text(CoachL10n.t("ui.playing_in_time", ["bpm": String(store.metronomeBpm)]))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.inkMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .glassControl(in: Capsule())
            .onAppear { if !store.timerStarted { store.next() } } // kick off timer + metronome
        } else {
            HStack(spacing: Theme.space3) {
                // Dedicated "show me the chord" help — for beginners who don't
                // yet recognise a name like E♭9.
                if store.isTapGuessMode, store.playPhase != .verifying, !store.tapGuess.isEmpty {
                    GlassSecondaryButton(title: Strings.hint) { store.revealTapGuess() }
                }
                PrimaryCapsule(title: nextLabel) {
                    UISelectionFeedbackGenerator().selectionChanged()
                    store.next()
                }
            }
        }
    }

    private var displayedChord: String {
        // Typeset: the big chord name shows real ♭/♯ glyphs, never "b"/"#".
        Notation.chord(store.currentChord, store.notationSystem)
    }
    private var nextLabel: String {
        // Tap-guess: the primary action reveals + grades before advancing.
        if store.isTapGuessMode { return CoachL10n.t(store.tapGuess.isEmpty ? "ui.show_me" : "ui.check") }
        if store.currentIdx >= store.actualTotalChords - 1 { return CoachL10n.t("ui.finish") }
        return CoachL10n.t("ui.next_chord")
    }
    private var inputStatus: String {
        if store.inputMode == .midi {
            return CoachL10n.t(MIDIInput.shared.connected ? "ui.play_on_keyboard" : "ui.connect_midi")
        }
        return CoachL10n.t("ui.play_listening")
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
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                EditorialHeader(eyebrow: CoachL10n.t("results.stat_chords"), title: CoachL10n.t("results.nice_work"))

                if let r = store.lastResult {
                    StatsRow(items: [
                        StatItem(value: Strings.seconds(r.avgMs / 1000), label: CoachL10n.t("results.stat_avg")),
                        StatItem(value: "\(r.totalChords)", label: CoachL10n.t("results.stat_chords")),
                        StatItem(value: String(format: "%.0f s", r.elapsedMs / 1000), label: CoachL10n.t("results.stat_total")),
                    ])
                }

                if store.canDrillWeakSpots {
                    // Peak-motivation moment: drill the chords you were slowest at.
                    FeatureBlock(eyebrow: CoachL10n.t("quickstart.weakspots_title"), ghost: "♯") {
                        Text(CoachL10n.t("results.drill_weak"))
                            .font(Display.serif(28, relativeTo: .title2))
                    } action: {
                        PrimaryCapsule(title: CoachL10n.t("ui.start"), systemImage: "target", inverted: true) {
                            store.startWeakDrill()
                        }
                    }
                }

                ReminderOfferCard()

                VStack(spacing: Theme.space3) {
                    if store.canDrillWeakSpots {
                        GlassSecondaryButton(title: CoachL10n.t("results.again_same")) { store.restart() }
                            .frame(maxWidth: .infinity)
                    } else {
                        PrimaryCapsule(title: CoachL10n.t("results.again")) { store.restart() }
                    }
                    GlassSecondaryButton(title: CoachL10n.t("ui.done")) { onClose() }
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(Theme.space4)
            .padding(.top, Theme.space6)
            .readableWidth()
        }
        .screenBackground()
        .navigationBarBackButtonHidden()
    }
}
