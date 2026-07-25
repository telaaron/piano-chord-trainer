// To-Go — practice away from the piano.
//
// The screen is built generically from what the engine hands back: `play` says
// how to sound the exercise, `input` says how the player answers. Adding a
// discipline to ToGo.swift needs no change here as long as it reuses one of the
// five playback modes and four input modes.
//
// All decisions (what to ask, what counts as right) live in MusicEngine.

import SwiftUI
import MusicEngine

struct ToGoView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var store = ToGoStore.shared
    @State private var mic = MicInput.shared

    /// nil = the intro screen; set = a run in progress or finished.
    @State private var session: ToGoSession?
    @State private var index = 0
    @State private var results: [ToGoResult] = []
    @State private var finished = false
    @State private var summary: ToGoSummary?

    /// Per-exercise transient answer state.
    @State private var revealed = false
    @State private var lastCorrect = false
    @State private var chosenIndex: Int?
    @State private var startedAt: Double = 0

    /// Sing.
    @State private var singing = false
    @State private var heardMidi: [Int] = []
    /// Tap.
    @State private var tapping = false
    @State private var expectedBeatTimes: [Double] = []
    @State private var tapTimes: [Double] = []
    @State private var tapScore: TapScore?
    /// Notes (tap-back on the keyboard).
    @State private var tappedPitchClasses: Set<Int> = []

    @State private var playbackTask: Task<Void, Never>?

    private var settings: SavedSettings { ProgressStore.loadSettings() }
    private var capabilities: ToGoCapabilities {
        ToGoCapabilities(mic: mic.state != .denied && mic.state != .unsupported,
                         audio: settings.audioEnabled)
    }

    private var current: ToGoExercise? {
        guard let session, index < session.exercises.count else { return nil }
        return session.exercises[index]
    }

    var body: some View {
        Group {
            if finished {
                resultsScreen
            } else if session != nil, let ex = current {
                runScreen(ex)
            } else {
                introScreen
            }
        }
        .navigationTitle(CoachL10n.t(CoachL10n.ToGo.title))
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .onDisappear { teardownAudio() }
    }

    // ─── Intro ──────────────────────────────────────────────

    private var introScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                VStack(alignment: .leading, spacing: Theme.space2) {
                    Text(CoachL10n.t(CoachL10n.ToGo.subtitle))
                        .font(Display.headline(22))
                        .foregroundStyle(palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(CoachL10n.t(CoachL10n.ToGo.intro))
                        .font(.subheadline)
                        .foregroundStyle(palette.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !capabilities.audio {
                    noticeRow(CoachL10n.t(CoachL10n.ToGo.audioOff), icon: "speaker.slash.fill")
                } else if !capabilities.mic {
                    noticeRow(CoachL10n.t(CoachL10n.ToGo.micOff), icon: "mic.slash.fill")
                }

                Button { start(only: nil) } label: {
                    VStack(alignment: .leading, spacing: Theme.space1) {
                        Text(CoachL10n.t(CoachL10n.ToGo.start))
                            .font(Display.headline(24))
                            .foregroundStyle(palette.primaryText)
                        Text(CoachL10n.t(CoachL10n.ToGo.startSub))
                            .font(.subheadline)
                            .foregroundStyle(palette.primaryText.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(Theme.space4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.primary, in: RoundedRectangle(cornerRadius: Theme.radius))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: Theme.space3) {
                    Text(CoachL10n.t(CoachL10n.ToGo.pickOne).uppercased())
                        .font(.caption2.weight(.semibold)).tracking(1.5)
                        .foregroundStyle(palette.textDim)
                    ForEach(ALL_TOGO_KINDS, id: \.self) { kind in
                        disciplineRow(kind)
                    }
                }

                let p = store.progress
                Text(CoachL10n.t(CoachL10n.ToGo.earProgress,
                                 ["ear": String(p.earMastered), "total": String(p.total)]))
                    .font(.caption)
                    .foregroundStyle(palette.textDim)
            }
            .padding(Theme.space4)
            .readableWidth()
        }
    }

    private func noticeRow(_ text: String, icon: String) -> some View {
        HStack(spacing: Theme.space3) {
            Image(systemName: icon)
                .foregroundStyle(palette.accentRed)
                .symbolRenderingMode(.hierarchical)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Theme.space4)
        .glassCard()
    }

    @ViewBuilder
    private func disciplineRow(_ kind: ToGoKind) -> some View {
        let available = isAvailable(kind)
        Button { if available { start(only: kind) } } label: {
            HStack(spacing: Theme.space3) {
                Image(systemName: icon(for: kind))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(available ? palette.primary : palette.textDim)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(CoachL10n.ToGo.kind(kind))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(available ? palette.text : palette.textDim)
                    Text(available ? CoachL10n.ToGo.kindDesc(kind) : unavailableReason(kind))
                        .font(.caption)
                        .foregroundStyle(palette.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textDim)
            }
            .padding(Theme.space3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(.plain)
        .disabled(!available)
    }

    /// A discipline is runnable when the device can do what it needs.
    private func isAvailable(_ kind: ToGoKind) -> Bool {
        if kind == .theory { return !store.deck.isEmpty }
        if !capabilities.audio { return false }
        if kind == .sing { return capabilities.mic }
        return true
    }

    private func unavailableReason(_ kind: ToGoKind) -> String {
        if kind == .sing && !capabilities.mic { return CoachL10n.t(CoachL10n.ToGo.needsMic) }
        return CoachL10n.t(CoachL10n.ToGo.needsAudio)
    }

    private func icon(for kind: ToGoKind) -> String {
        switch kind {
        case .interval: return "arrow.up.and.down"
        case .quality: return "paintpalette.fill"
        case .progression: return "arrow.triangle.turn.up.right.diamond.fill"
        case .sing: return "mic.fill"
        case .time: return "metronome.fill"
        case .lick: return "music.note.list"
        case .theory: return "rectangle.stack.fill"
        }
    }

    // ─── Run ────────────────────────────────────────────────

    private func runScreen(_ ex: ToGoExercise) -> some View {
        VStack(spacing: Theme.space4) {
            topBar

            ScrollView {
                VStack(spacing: Theme.space4) {
                    Text(CoachL10n.t(ex.promptKey, ex.promptParams))
                        .font(Display.headline(22))
                        .foregroundStyle(palette.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    playbackControls(ex)

                    if revealed { revealBanner(ex) }

                    inputArea(ex)
                }
                .padding(.vertical, Theme.space3)
            }

            Spacer(minLength: 0)

            if revealed {
                primaryButton(isLast ? CoachL10n.t(CoachL10n.ToGo.finish)
                                     : CoachL10n.t(CoachL10n.ToGo.next)) {
                    advance()
                }
            }
        }
        .padding(Theme.space4)
        .readableWidth()
        .onAppear { beginExercise(ex) }
    }

    private var isLast: Bool {
        guard let session else { return true }
        return index >= session.exercises.count - 1
    }

    private var topBar: some View {
        VStack(spacing: Theme.space2) {
            HStack {
                Text(CoachL10n.t(CoachL10n.ToGo.round,
                                 ["current": String(index + 1),
                                  "total": String(session?.exercises.count ?? 0)]))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(palette.textMuted)
                Spacer()
                Button { quit() } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(palette.textDim)
                    .accessibilityLabel(CoachL10n.t(CoachL10n.ToGo.quit))
            }
            ProgressView(value: Double(index + 1),
                         total: Double(max(1, session?.exercises.count ?? 1)))
                .tint(palette.primary)
        }
    }

    /// "Play again" for anything audible; pulse exercises drive the metronome instead.
    @ViewBuilder
    private func playbackControls(_ ex: ToGoExercise) -> some View {
        switch ex.play {
        case .chord, .sequence, .chords:
            Button { play(ex) } label: {
                Label(CoachL10n.t(CoachL10n.ToGo.replay), systemImage: "speaker.wave.2.fill")
            }
            .tint(palette.primary)
        case .drone:
            Label(CoachL10n.t(CoachL10n.ToGo.listen), systemImage: "waveform")
                .font(.subheadline)
                .foregroundStyle(palette.textMuted)
        case .pulse:
            if !tapping && !revealed {
                Button { startPulse(ex) } label: {
                    Label(CoachL10n.t(CoachL10n.ToGo.tapStart), systemImage: "metronome.fill")
                }
                .tint(palette.primary)
            }
        case .silent:
            EmptyView()
        }
    }

    @ViewBuilder
    private func revealBanner(_ ex: ToGoExercise) -> some View {
        VStack(spacing: Theme.space1) {
            Text(lastCorrect ? CoachL10n.t(CoachL10n.ToGo.revealCorrect)
                             : CoachL10n.t(CoachL10n.ToGo.revealWrong))
                .font(.title3.weight(.semibold))
                .foregroundStyle(lastCorrect ? palette.accentGreen : palette.accentRed)
            Text(CoachL10n.t(CoachL10n.ToGo.answerWas, ["answer": ex.answerLabel]))
                .font(.subheadline)
                .foregroundStyle(palette.textMuted)
                .multilineTextAlignment(.center)
            if let s = tapScore { tapFeedback(s) }
        }
    }

    private func tapFeedback(_ s: TapScore) -> some View {
        VStack(spacing: 2) {
            Text(CoachL10n.t(CoachL10n.ToGo.tapScore,
                             ["hits": String(s.hits), "expected": String(s.expected)]))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.text)
            Text(timingHint(s))
                .font(.caption)
                .foregroundStyle(palette.textMuted)
        }
    }

    /// Rushing / dragging / in the pocket — from the SIGNED mean offset.
    private func timingHint(_ s: TapScore) -> String {
        if s.hits == 0 { return "" }
        if s.meanOffsetMs < -25 { return CoachL10n.t(CoachL10n.ToGo.tapRushing) }
        if s.meanOffsetMs > 25 { return CoachL10n.t(CoachL10n.ToGo.tapDragging) }
        return CoachL10n.t(CoachL10n.ToGo.tapLocked)
    }

    // ─── Input areas (one per ToGoInput case) ───────────────

    @ViewBuilder
    private func inputArea(_ ex: ToGoExercise) -> some View {
        switch ex.input {
        case .choice:
            choiceInput(ex)
        case .sing:
            singInput(ex)
        case let .tap(onBeats, beatsPerBar, _):
            tapInput(ex, onBeats: onBeats, beatsPerBar: beatsPerBar)
        case .notes:
            notesInput(ex)
        }
    }

    private func choiceInput(_ ex: ToGoExercise) -> some View {
        VStack(spacing: Theme.space2) {
            ForEach(Array(ex.options.enumerated()), id: \.offset) { i, option in
                Button {
                    guard !revealed else { return }
                    chosenIndex = i
                    finishExercise(ex, correct: gradeChoice(ex, i))
                } label: {
                    Text(option)
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.space3)
                        .background(choiceBackground(ex, i), in: RoundedRectangle(cornerRadius: Theme.radius))
                        .foregroundStyle(choiceForeground(ex, i))
                }
                .buttonStyle(.plain)
                .disabled(revealed)
            }
        }
    }

    private func choiceBackground(_ ex: ToGoExercise, _ i: Int) -> Color {
        guard revealed else { return palette.bgMuted }
        if i == ex.answerIndex { return palette.accentGreen.opacity(0.22) }
        if i == chosenIndex { return palette.accentRed.opacity(0.22) }
        return palette.bgMuted
    }

    private func choiceForeground(_ ex: ToGoExercise, _ i: Int) -> Color {
        guard revealed else { return palette.text }
        if i == ex.answerIndex { return palette.accentGreen }
        if i == chosenIndex { return palette.accentRed }
        return palette.textDim
    }

    private func singInput(_ ex: ToGoExercise) -> some View {
        VStack(spacing: Theme.space3) {
            Text(CoachL10n.t(CoachL10n.ToGo.singHint))
                .font(.caption)
                .foregroundStyle(palette.textDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if mic.state == .denied || mic.state == .unsupported {
                Text(CoachL10n.t(CoachL10n.ToGo.singDenied))
                    .font(.subheadline)
                    .foregroundStyle(palette.accentRed)
                    .multilineTextAlignment(.center)
            } else if singing {
                VStack(spacing: Theme.space2) {
                    Text(CoachL10n.t(CoachL10n.ToGo.singLevel))
                        .font(.caption).foregroundStyle(palette.textDim)
                    ProgressView(value: min(1, mic.level)).tint(palette.primary)
                    Text(heardMidi.isEmpty
                         ? CoachL10n.t(CoachL10n.ToGo.singNothingYet)
                         : "\(CoachL10n.t(CoachL10n.ToGo.singHeard)): \(heardNoteNames)")
                        .font(.caption)
                        .foregroundStyle(palette.textMuted)
                }
            }

            if !revealed {
                if singing {
                    primaryButton(CoachL10n.t(CoachL10n.ToGo.singCheck)) {
                        stopListening()
                        finishExercise(ex, correct: gradeSing(ex, heardMidi))
                    }
                } else if mic.state != .denied && mic.state != .unsupported {
                    primaryButton(CoachL10n.t(CoachL10n.ToGo.singStart)) { startListening() }
                }
            }
        }
    }

    private var heardNoteNames: String {
        let pcs = Array(Set(heardMidi.map { ((($0 % 12) + 12) % 12) })).sorted()
        return pcs.map { NOTES_FLATS[$0] }.joined(separator: " ")
    }

    private func tapInput(_ ex: ToGoExercise, onBeats: [Int], beatsPerBar: Int) -> some View {
        VStack(spacing: Theme.space3) {
            Text(CoachL10n.t(CoachL10n.ToGo.tapReady))
                .font(.caption)
                .foregroundStyle(palette.textDim)
                .multilineTextAlignment(.center)

            Button {
                guard tapping else { return }
                // Same time base as the metronome callback (CACurrentMediaTime).
                tapTimes.append(CACurrentMediaTime() * 1000)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } label: {
                ZStack {
                    Circle()
                        .fill(tapping ? palette.primary : palette.bgMuted)
                        .frame(width: 180, height: 180)
                    Text(CoachL10n.t(CoachL10n.ToGo.tapButton))
                        .font(Display.headline(28))
                        .foregroundStyle(tapping ? palette.primaryText : palette.textDim)
                }
            }
            .buttonStyle(.plain)
            .disabled(!tapping)
            .accessibilityLabel(CoachL10n.t(CoachL10n.ToGo.tapButton))

            Text(onBeats.map(String.init).joined(separator: " · "))
                .font(.caption.monospacedDigit())
                .foregroundStyle(palette.textDim)
        }
    }

    private func notesInput(_ ex: ToGoExercise) -> some View {
        VStack(spacing: Theme.space3) {
            Text(CoachL10n.t(CoachL10n.ToGo.notesHint))
                .font(.caption)
                .foregroundStyle(palette.textDim)
                .multilineTextAlignment(.center)

            PianoKeyboard(
                accidentalPref: .flats,
                showVoicing: false,
                interactive: !revealed,
                selectedPitchClasses: tappedPitchClasses,
                onKeyTap: { chr in
                    guard !revealed else { return }
                    let pc = ((chr % 12) + 12) % 12
                    if tappedPitchClasses.contains(pc) { tappedPitchClasses.remove(pc) }
                    else { tappedPitchClasses.insert(pc) }
                }
            )

            if !revealed {
                HStack(spacing: Theme.space3) {
                    Button(CoachL10n.t(CoachL10n.ToGo.notesClear)) { tappedPitchClasses = [] }
                        .tint(palette.textMuted)
                    primaryButton(CoachL10n.t(CoachL10n.ToGo.notesCheck),
                                  disabled: tappedPitchClasses.isEmpty) {
                        finishExercise(ex, correct: gradeNotes(ex, Array(tappedPitchClasses)))
                    }
                }
            }
        }
    }

    // ─── Results ────────────────────────────────────────────

    private var resultsScreen: some View {
        ScrollView {
            VStack(spacing: Theme.space4) {
                Text(CoachL10n.t(CoachL10n.ToGo.resultsTitle))
                    .font(Display.title(28))
                    .foregroundStyle(palette.text)

                if let s = summary {
                    Text(CoachL10n.t(CoachL10n.ToGo.resultsScore,
                                     ["correct": String(s.correct), "total": String(s.total)]))
                        .font(Display.headline(22))
                        .foregroundStyle(palette.primary)

                    Text(verdictLine(s.ratio))
                        .font(.subheadline)
                        .foregroundStyle(palette.textMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: Theme.space2) {
                        statRow(CoachL10n.t(CoachL10n.ToGo.resultsAccuracy),
                                "\(Int((s.ratio * 100).rounded()))%")
                        statRow(CoachL10n.t(CoachL10n.ToGo.resultsAvg),
                                String(format: "%.1fs", s.avgMs / 1000))
                    }
                    .padding(Theme.space4)
                    .glassCard()

                    VStack(alignment: .leading, spacing: Theme.space2) {
                        SectionHeader(text: CoachL10n.t(CoachL10n.ToGo.resultsBreakdown))
                        ForEach(ALL_TOGO_KINDS, id: \.self) { kind in
                            if let b = s.byKind[kind.rawValue] {
                                statRow(CoachL10n.ToGo.kind(kind), "\(b.correct)/\(b.total)")
                            }
                        }
                    }
                    .padding(Theme.space4)
                    .glassCard()

                    let p = store.progress
                    Text(CoachL10n.t(CoachL10n.ToGo.earProgress,
                                     ["ear": String(p.earMastered), "total": String(p.total)]))
                        .font(.caption)
                        .foregroundStyle(palette.textDim)
                }

                VStack(spacing: Theme.space2) {
                    primaryButton(CoachL10n.t(CoachL10n.ToGo.again)) { start(only: nil) }
                    Button(CoachL10n.t(CoachL10n.ToGo.done)) { dismiss() }
                        .tint(palette.textMuted)
                }
                .padding(.top, Theme.space2)
            }
            .padding(Theme.space4)
            .readableWidth()
        }
    }

    private func verdictLine(_ ratio: Double) -> String {
        if ratio >= 0.95 { return CoachL10n.t(CoachL10n.ToGo.resultsPerfect) }
        if ratio >= 0.75 { return CoachL10n.t(CoachL10n.ToGo.resultsGood) }
        if ratio >= 0.4 { return CoachL10n.t(CoachL10n.ToGo.resultsMixed) }
        return CoachL10n.t(CoachL10n.ToGo.resultsRough)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(palette.textMuted)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(palette.text)
        }
    }

    private func primaryButton(_ label: String, disabled: Bool = false,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.space4)
                .background(disabled ? palette.bgMuted : palette.primary,
                            in: RoundedRectangle(cornerRadius: Theme.radius))
                .foregroundStyle(disabled ? palette.textDim : palette.primaryText)
        }
        .disabled(disabled)
    }

    // ─── Flow ───────────────────────────────────────────────

    private func start(only: ToGoKind?) {
        teardownAudio()
        session = store.buildSession(capabilities: capabilities, only: only)
        index = 0
        results = []
        summary = nil
        finished = false
        resetExerciseState()
    }

    private func resetExerciseState() {
        revealed = false
        lastCorrect = false
        chosenIndex = nil
        heardMidi = []
        singing = false
        tapping = false
        expectedBeatTimes = []
        tapTimes = []
        tapScore = nil
        tappedPitchClasses = []
    }

    /// Sound the exercise (if it makes sound) and start its clock.
    private func beginExercise(_ ex: ToGoExercise) {
        startedAt = CACurrentMediaTime() * 1000
        switch ex.play {
        case .chord, .sequence, .chords:
            play(ex)
        case let .drone(note):
            if capabilities.audio { AudioEngine.shared.startDrone(note) }
        case .pulse, .silent:
            break
        }
    }

    private func play(_ ex: ToGoExercise) {
        guard capabilities.audio else { return }
        playbackTask?.cancel()
        switch ex.play {
        case let .chord(notes):
            AudioEngine.shared.playChord(notes)
        case let .sequence(notes, stepMs):
            playbackTask = AudioEngine.shared.playSequence(notes, stepMs: stepMs)
        case let .chords(chords, stepMs):
            // A cadence — each step is a whole chord, not a single note.
            playbackTask = AudioEngine.shared.playChordSequence(chords, stepMs: stepMs)
        default:
            break
        }
    }

    /// Run the click for `bars`, collecting the moments the asked-for beats fire.
    private func startPulse(_ ex: ToGoExercise) {
        guard case let .pulse(bpm, bars, beatsPerBar) = ex.play,
              case let .tap(onBeats, _, toleranceMs) = ex.input else { return }
        tapping = true
        tapTimes = []
        expectedBeatTimes = []
        let wanted = Set(onBeats)
        let totalBeats = bars * beatsPerBar
        var seen = 0

        Metronome.shared.start(bpm: Double(bpm), beatsPerBar: beatsPerBar) { beat, time in
            seen += 1
            // `time` is CACurrentMediaTime seconds — same base as the tap button.
            if wanted.contains(beat) { expectedBeatTimes.append(time * 1000) }
            if seen >= totalBeats {
                Metronome.shared.stop()
                tapping = false
                // Give the last tap a moment to land before scoring.
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(toleranceMs * 1_000_000) + 200_000_000)
                    let score = gradeTaps(expectedBeatTimes, tapTimes, toleranceMs)
                    tapScore = score
                    finishExercise(ex, correct: score.correct)
                }
            }
        }
    }

    private func startListening() {
        heardMidi = []
        singing = true
        mic.onNotesChanged = { notes in
            heardMidi.append(contentsOf: notes)
        }
        mic.start()
    }

    private func stopListening() {
        mic.onNotesChanged = nil
        mic.stop()
        singing = false
    }

    private func finishExercise(_ ex: ToGoExercise, correct: Bool) {
        guard !revealed else { return }
        playbackTask?.cancel()
        AudioEngine.shared.stopDrone()
        lastCorrect = correct
        revealed = true
        let ms = CACurrentMediaTime() * 1000 - startedAt
        results.append(ToGoResult(exerciseId: ex.id, kind: ex.kind, correct: correct,
                                  ms: ms, unitId: ex.unitId, cardId: ex.cardId))
        UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .warning)
    }

    private func advance() {
        guard let session else { return }
        teardownAudio()
        if index >= session.exercises.count - 1 {
            summary = store.applyResults(results)
            finished = true
            return
        }
        index += 1
        resetExerciseState()
    }

    private func quit() {
        teardownAudio()
        if results.isEmpty {
            dismiss()
        } else {
            summary = store.applyResults(results)
            finished = true
        }
    }

    /// Stop every sound source this screen can own. Called on leave and between rounds.
    private func teardownAudio() {
        playbackTask?.cancel()
        playbackTask = nil
        AudioEngine.shared.stopDrone()
        Metronome.shared.stop()
        Metronome.shared.onBeat = nil
        if singing { stopListening() }
    }
}
