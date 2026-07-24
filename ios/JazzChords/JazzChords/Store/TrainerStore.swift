// TrainerStore — the drill state machine (setup → playing → finished).
// Ports the core of src/routes/train/+page.svelte: chord generation (random +
// progression + optional voice-leading rearrange), per-chord timing, advance,
// and session save. In-time/ear-training/VL-modes-B-C arrive in M4.

import Foundation
import Observation
import MusicEngine

@MainActor
@Observable
final class TrainerStore {
    enum Screen { case setup, playing, finished, earTraining }

    // ─── Settings (persisted) ───────────────────────────────
    var difficulty: Difficulty = .beginner
    var notation: NotationStyle = .standard
    var voicing: VoicingType = .root
    var displayMode: DisplayMode = .verify
    var accidentals: AccidentalPreference = .both
    var notationSystem: NotationSystem = .international
    var totalChords: Int = 20
    var progressionMode: ProgressionMode = .random
    var voiceLeadingEnabled = false
    var adaptiveEnabled = false
    var focusRoots: [String] = []
    /// When a Coach block promises one quality (new/focus), restrict the pool to it.
    var qualityFilter: [String] = []
    var audioEnabled = true
    var soundPreset: SoundPreset = .grandPiano

    // ─── Input (none / midi / mic) ──────────────────────────
    enum InputMode: String { case none, midi, microphone }
    var inputMode: InputMode = .none
    var inputActive: Bool { inputMode != .none }
    /// Notes currently held via MIDI/mic (for keyboard overlay + validation).
    private(set) var heldNotes: Set<Int> = []
    private(set) var midiCorrectCount = 0
    private(set) var midiTotalAttempts = 0
    private var autoAdvanceArmed = false
    var midiAccuracy: Int { midiTotalAttempts > 0 ? Int((Double(midiCorrectCount) / Double(midiTotalAttempts) * 100).rounded()) : 0 }

    /// Expected pitch classes of the current voicing (for green/red key coloring).
    var expectedPitchClasses: Set<Int> {
        guard let d = currentData else { return [] }
        var set = Set<Int>()
        for n in d.voicing {
            let st = noteToSemitone(n)
            if st != -1 { set.insert(st) }
        }
        return set
    }

    // ─── Game state ─────────────────────────────────────────
    var screen: Screen = .setup
    private(set) var chords: [String] = []
    private(set) var chordsWithNotes: [ChordWithNotes] = []
    var currentIdx = 0
    private(set) var sessionOctaves: OctaveCount? = nil

    enum PlayPhase { case playing, verifying }
    var playPhase: PlayPhase = .playing

    // timing
    private(set) var timerStarted = false
    private var startTime: TimeInterval = 0
    private var chordStartTime: TimeInterval = 0
    private var chordTimings: [ChordTiming] = []
    private(set) var endTime: TimeInterval = 0
    private(set) var lastResult: SessionResult?
    /// Celebrations from the just-finished session (level-up, PB, …) for the UI.
    var pendingCelebrations: [CelebrationEvent] = []
    private(set) var lastHabitResult: SessionHabitResult?

    // ─── Ear training ───────────────────────────────────────
    var earRevealed = false
    var earGuess: Set<Int> = []            // pitch classes the user selected
    private(set) var earCorrect = 0
    private(set) var earTotal = 0
    var earResult: Bool? = nil             // last guess outcome

    // ─── Tap-guess (verify mode, no MIDI/mic) ───────────────
    /// Pitch classes the player tapped to build their guess before revealing.
    var tapGuess: Set<Int> = []
    /// Outcome of the last checked tap-guess (nil until Check). Drives green/red.
    var tapResult: Bool? = nil
    /// True while the player is building a guess: verify mode, tap input, not yet revealed.
    var isTapGuessMode: Bool {
        displayMode == .verify && inputMode == .none && playPhase == .playing && screen == .playing
    }

    // ─── Derived ────────────────────────────────────────────
    var currentChord: String { currentIdx < chords.count ? chords[currentIdx] : "" }
    var currentData: ChordWithNotes? { currentIdx < chordsWithNotes.count ? chordsWithNotes[currentIdx] : nil }
    var actualTotalChords: Int { chords.isEmpty ? totalChords : chords.count }
    var progress: Double { actualTotalChords > 0 ? Double(currentIdx + 1) / Double(actualTotalChords) : 0 }

    var shouldShowVoicing: Bool {
        displayMode == .always || (displayMode == .verify && playPhase == .verifying)
    }

    // ─── Settings load/save ─────────────────────────────────
    func loadSettings() {
        let s = ProgressStore.loadSettings()
        difficulty = s.difficulty; notation = s.notation; voicing = s.voicing
        displayMode = s.displayMode; accidentals = s.accidentals; notationSystem = s.notationSystem
        totalChords = s.totalChords; progressionMode = s.progressionMode
        audioEnabled = s.audioEnabled
        soundPreset = SoundPreset(rawValue: s.soundPreset) ?? .grandPiano
        AudioEngine.shared.setPreset(soundPreset)
    }

    private func persistSettings() {
        var s = ProgressStore.loadSettings()
        s.difficulty = difficulty; s.notation = notation; s.voicing = voicing
        s.displayMode = displayMode; s.accidentals = accidentals; s.notationSystem = notationSystem
        s.totalChords = totalChords; s.progressionMode = progressionMode
        s.audioEnabled = audioEnabled; s.soundPreset = soundPreset.rawValue
        ProgressStore.saveSettings(s)
    }

    // ─── Apply a practice plan ──────────────────────────────
    func apply(plan: PracticePlan) {
        difficulty = plan.settings.difficulty
        notation = plan.settings.notation
        voicing = plan.settings.voicing
        displayMode = plan.settings.displayMode
        accidentals = plan.settings.accidentals
        progressionMode = plan.settings.progressionMode
        totalChords = plan.settings.totalChords
        voiceLeadingEnabled = (plan.id == "voice-leading-flow")
        adaptiveEnabled = (plan.id == "adaptive-drill" || plan.id == "weak-drill")
        isEarTraining = (plan.id == "ear-check")
        inTimeMode = (plan.id == "in-time-comping")
        // Weak-spot drills carry the roots to concentrate practice on (10× weight).
        focusRoots = plan.focusRoots ?? []
        // Manual plans never pin a single quality — that's a Coach-only restriction.
        qualityFilter = []
    }

    /// Plan-selected modes that change which screen startSession opens.
    var isEarTraining = false
    var inTimeMode = false

    // ─── Coach (Auto-Mode) block flow ───────────────────────
    // Additive path mirroring the web train page: the Coach drives a sequence of
    // normal drill blocks. `coachMode` gates every Coach-specific branch; all
    // existing modes stay untouched. Each block is a normal drill run with the
    // block's settings + focus plumbing, producing one SessionResult (with
    // blockKind) that folds into the CoachStore before the next block.

    /// True while an auto-session is running its block sequence.
    private(set) var coachMode = false
    private(set) var coachPlan: CoachPlan?
    private(set) var coachBlockIdx = 0
    /// Per-block SessionResults accumulated across the whole auto-session.
    private var coachSessionBlocks: [SessionResult] = []
    private var coachSessionStartedAtMs: Double = 0
    /// CoachState snapshot BEFORE this session — feeds session-level teacherFeedback.
    private var coachStateBefore: CoachState?

    /// Between-block transition (nil = not showing). Drives a mini screen.
    struct CoachTransition: Equatable {
        var doneKind: BlockKind
        var nextKind: BlockKind
        var nextLabelKey: String
        var nextLabelParams: [String: String]
    }
    var coachTransition: CoachTransition?
    private var coachTransitionWork: DispatchWorkItem?

    /// Teacher statements shown on the post-session feedback screen.
    private(set) var coachFeedback: [TeacherStatement] = []
    /// Whether the "too easy / just right / too hard" valve was already tapped.
    private(set) var coachFeedbackGiven = false
    /// True once the last block folded in — TrainerView shows the feedback screen.
    var coachShowFeedback = false

    /// Correctness verdict for the chord currently on screen, set the moment a
    /// right/wrong decision is made (tap-guess / MIDI-mic match). `nil` = no
    /// verdict yet. Stamped onto each ChordTiming as it's recorded, then reset on
    /// advance. Runs in ALL modes — it only enriches timing data, never gates flow.
    private var currentChordCorrect: Bool?

    /// Start the appropriate session for the selected mode.
    func startSession() {
        if isEarTraining { startEarTraining() }
        else { startGame() }
    }

    /// Record a timing for `data`, stamping the current correctness verdict.
    private func pushTiming(_ data: ChordWithNotes, durationMs: Double) {
        chordTimings.append(ChordTiming(chord: data.chord, root: data.root,
                                        durationMs: durationMs, correct: currentChordCorrect))
    }

    // ─── Chord generation (ports generateChords) ────────────
    private func generateChords() {
        if progressionMode != .random {
            let result = generateProgression(progressionMode, accidentals, notation, totalChords, nil)
            var newChords: [String] = []
            var newData: [ChordWithNotes] = []
            for pc in result.chords {
                newChords.append(pc.display)
                let notes = getChordNotes(pc.root, pc.quality, accidentals)
                var voicingArr = getVoicingNotes(notes, voicing, pc.root, accidentals)
                if voiceLeadingEnabled, let prev = newData.last {
                    voicingArr = computeVoiceLeadVoicing(prev.voicing, voicingArr, accidentals)
                }
                newData.append(ChordWithNotes(chord: pc.display, root: pc.root, type: pc.quality, notes: notes, voicing: voicingArr))
            }
            chords = newChords
            chordsWithNotes = newData
            return
        }

        // Random mode
        var available = CHORDS_BY_DIFFICULTY[difficulty] ?? []
        // Coach 'new'/'focus' blocks pin the pool to the promised quality so the
        // block delivers exactly what its label says. Fall back to the full pool
        // if the filter would empty it (defensive — shouldn't happen).
        if !qualityFilter.isEmpty {
            let filtered = available.filter { qualityFilter.contains($0.display) }
            if !filtered.isEmpty { available = filtered }
        }
        let pool = getNotePool(accidentals)
        var newChords: [String] = []
        var newData: [ChordWithNotes] = []
        var last = ""

        // Adaptive: weight selection by past per-chord timing (spaced-repetition-ish).
        if adaptiveEnabled {
            let allHistory = ProgressStore.loadHistory()
            let matching = allHistory.filter { $0.settings.voicing == voicing }
            let timings = matching.flatMap { $0.chordTimings ?? [] }
            let weighted = getWeightedChordPool(timings, available, pool, focusRoots.isEmpty ? nil : focusRoots)
            var lastRoot = ""
            var lastDisplay = ""
            for _ in 0..<totalChords {
                let pick = pickWeightedChord(weighted, lastRoot: lastRoot, lastDisplay: lastDisplay)
                let displayQuality = CHORD_NOTATIONS[notation]?[pick.display] ?? pick.display
                let name = "\(pick.root)\(displayQuality)"
                lastRoot = pick.root; lastDisplay = pick.display
                newChords.append(name)
                let notes = getChordNotes(pick.root, pick.display, accidentals)
                var voicingArr = getVoicingNotes(notes, voicing, pick.root, accidentals)
                if voiceLeadingEnabled, let prev = newData.last {
                    voicingArr = computeVoiceLeadVoicing(prev.voicing, voicingArr, accidentals)
                }
                newData.append(ChordWithNotes(chord: name, root: pick.root, type: pick.display, notes: notes, voicing: voicingArr))
            }
            chords = newChords
            chordsWithNotes = newData
            return
        }

        for _ in 0..<totalChords {
            var name = ""
            var attempts = 0
            repeat {
                let note = pool.randomElement() ?? "C"
                let ct = available.randomElement() ?? ChordType(name: "maj7", display: "Maj7")
                let display = CHORD_NOTATIONS[notation]?[ct.display] ?? ct.display
                name = "\(note)\(display)"
                attempts += 1
            } while name == last && attempts < 50

            last = name
            newChords.append(name)

            // Parse root + display quality back to internal quality.
            if let (root, displayType) = Self.splitChordName(name) {
                let quality = displayToQuality(displayType, notation)
                let notes = getChordNotes(root, quality, accidentals)
                var voicingArr = getVoicingNotes(notes, voicing, root, accidentals)
                if voiceLeadingEnabled, let prev = newData.last {
                    voicingArr = computeVoiceLeadVoicing(prev.voicing, voicingArr, accidentals)
                }
                newData.append(ChordWithNotes(chord: name, root: root, type: quality, notes: notes, voicing: voicingArr))
            }
        }

        chords = newChords
        chordsWithNotes = newData
    }

    /// Split "C#Maj7" → ("C#", "Maj7").
    private static func splitChordName(_ name: String) -> (String, String)? {
        guard let first = name.first, ("A"..."G").contains(first) else { return nil }
        var idx = name.index(after: name.startIndex)
        if idx < name.endIndex, name[idx] == "#" || name[idx] == "b" {
            idx = name.index(after: idx)
        }
        let root = String(name[name.startIndex..<idx])
        let rest = String(name[idx...])
        return (root, rest)
    }

    // ─── Game lifecycle ─────────────────────────────────────
    func startGame() {
        generateChords()
        currentIdx = 0
        playPhase = .playing
        timerStarted = false
        startTime = 0
        chordTimings = []
        chordStartTime = 0
        heldNotes = []
        midiCorrectCount = 0
        midiTotalAttempts = 0
        autoAdvanceArmed = false
        currentChordCorrect = nil
        sessionOctaves = chordsWithNotes.isEmpty ? nil : computeSessionOctaves(chordsWithNotes, accidentals)
        AudioEngine.shared.setPreset(soundPreset)
        if inputMode == .midi { attachMidi() }
        if inputMode == .microphone { attachMic() }
        persistSettings()
        screen = .playing
    }

    // ─── Input wiring ───────────────────────────────────────
    private func attachMidi() {
        let midi = MIDIInput.shared
        midi.start()
        midi.onNoteOn = { note, _ in AudioEngine.shared.playMidi(note) }
        midi.onNotesChanged = { [weak self] notes in
            guard let self else { return }
            self.heldNotes = notes
            self.validateHeld()
        }
    }

    private func detachMidi() {
        MIDIInput.shared.onNotesChanged = nil
        MIDIInput.shared.onNoteOn = nil
        MIDIInput.shared.stop()
        heldNotes = []
    }

    private func attachMic() {
        let mic = MicInput.shared
        mic.onNotesChanged = { [weak self] notes in
            guard let self else { return }
            self.heldNotes = notes
            self.validateHeld()
        }
        mic.start()
    }

    private func detachMic() {
        MicInput.shared.onNotesChanged = nil
        MicInput.shared.stop()
        heldNotes = []
    }

    /// Suppress mic detection while we play audio (prevents self-trigger).
    private func suppressMicForPlayback() {
        if inputMode == .microphone { MicInput.shared.suppress(2.5) }
    }

    /// Validate currently-held notes against the current voicing; auto-advance on correct.
    private func validateHeld() {
        guard screen == .playing, let d = currentData, inputActive, !heldNotes.isEmpty else { return }
        // Must have started the timer (first input also starts it).
        if !timerStarted { beginTimer() }

        let result: ChordMatchResult
        if voicing.rawValue.hasPrefix("inversion-"), let bass = d.voicing.first {
            result = ChordMatch.checkChordWithBass(d.voicing, expectedBassNote: bass, activeMidi: heldNotes)
        } else {
            result = ChordMatch.checkChordLenient(d.voicing, activeMidi: heldNotes)
        }

        if result.correct {
            if !autoAdvanceArmed {
                autoAdvanceArmed = true
                currentChordCorrect = true
                midiTotalAttempts += 1
                midiCorrectCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    guard let self, self.autoAdvanceArmed else { return }
                    self.autoAdvanceArmed = false
                    self.advanceFromInput()
                }
            }
        } else if heldNotes.count >= d.voicing.count {
            // A full wrong attempt marks this chord wrong (unless already correct).
            if currentChordCorrect != true { currentChordCorrect = false }
            midiTotalAttempts += 1
        }
    }

    /// Advance triggered by correct input (skips the verify pause).
    private func advanceFromInput() {
        playPhase = .playing
        let nowMs = Date().timeIntervalSince1970
        if let d = currentData {
            pushTiming(d, durationMs: (nowMs - chordStartTime) * 1000)
        }
        currentChordCorrect = nil
        chordStartTime = nowMs
        if currentIdx < actualTotalChords - 1 {
            currentIdx += 1
            if audioEnabled, currentIdx < chordsWithNotes.count {
                suppressMicForPlayback()
                AudioEngine.shared.playChord(chordsWithNotes[currentIdx].voicing)
            }
        } else {
            endGame()
        }
    }

    // In-time comping: metronome advances chords every `inTimeBars` bars.
    var inTimeBars = 2
    var metronomeBpm = 100
    private var inTimeBarCount = 0

    /// First interaction starts the timer (chord already visible).
    private func beginTimer() {
        timerStarted = true
        startTime = Date().timeIntervalSince1970
        chordStartTime = startTime
        if audioEnabled, let d = chordsWithNotes.first {
            suppressMicForPlayback()
            AudioEngine.shared.playChord(d.voicing)
        }
        if inTimeMode { startInTimeMetronome() }
    }

    private func startInTimeMetronome() {
        inTimeBarCount = 0
        Metronome.shared.start(bpm: Double(metronomeBpm), beatsPerBar: 4) { [weak self] beat, _ in
            guard let self else { return }
            if beat == 1 {
                self.inTimeBarCount += 1
                if self.inTimeBarCount > self.inTimeBars {
                    self.inTimeBarCount = 1
                    self.inTimeAdvance()
                }
            }
        }
    }

    /// Advance on the downbeat in In-Time mode.
    private func inTimeAdvance() {
        let nowMs = Date().timeIntervalSince1970
        if let d = currentData {
            pushTiming(d, durationMs: (nowMs - chordStartTime) * 1000)
        }
        currentChordCorrect = nil
        chordStartTime = nowMs
        if currentIdx < actualTotalChords - 1 {
            currentIdx += 1
            if audioEnabled, currentIdx < chordsWithNotes.count {
                suppressMicForPlayback()
                AudioEngine.shared.playChord(chordsWithNotes[currentIdx].voicing)
            }
        } else {
            Metronome.shared.stop()
            endGame()
        }
    }

    /// Advance / reveal. Tap-driven (Space on web).
    func next() {
        guard screen == .playing else { return }

        if !timerStarted {
            beginTimer()
            return
        }

        // Verify mode: reveal before advancing. With tap input, grade the built
        // guess first (so recall is measured); otherwise just reveal on the tap.
        if displayMode == .verify && playPhase == .playing {
            if inputMode == .none {
                checkTapGuess()
            } else {
                playPhase = .verifying
                if audioEnabled, let d = currentData {
                    suppressMicForPlayback()
                    AudioEngine.shared.playChord(d.voicing)
                }
            }
            return
        }
        playPhase = .playing
        tapGuess = []
        tapResult = nil

        // Record timing for the chord we leave.
        let nowMs = Date().timeIntervalSince1970
        if let d = currentData {
            pushTiming(d, durationMs: (nowMs - chordStartTime) * 1000)
        }
        currentChordCorrect = nil
        chordStartTime = nowMs

        if currentIdx < actualTotalChords - 1 {
            currentIdx += 1
            if audioEnabled, currentIdx < chordsWithNotes.count {
                suppressMicForPlayback()
                AudioEngine.shared.playChord(chordsWithNotes[currentIdx].voicing)
            }
        } else {
            endGame()
        }
    }

    func replayChord() {
        if let d = currentData { suppressMicForPlayback(); AudioEngine.shared.playChord(d.voicing) }
    }

    // ─── Tap-guess (build the chord, then reveal + grade) ───
    /// Toggle a pitch class in the tap-guess; preview the note. Starts the timer
    /// on first tap so "thinking time" is measured like any other input.
    func tapToggle(_ chrIdx: Int) {
        guard isTapGuessMode else { return }
        if !timerStarted { beginTimer() }
        let pc = chrIdx % 12
        if tapGuess.contains(pc) { tapGuess.remove(pc) } else { tapGuess.insert(pc) }
    }

    /// Grade the tap-guess against the chord's pitch classes, then reveal (→ verifying).
    /// Records correctness so weak-spot data reflects real recall, not read speed.
    /// An empty guess is a "Show me" (reveal without attempting) — not graded/counted.
    func checkTapGuess() {
        guard isTapGuessMode else { return }
        if !timerStarted { beginTimer() }
        let expected = expectedPitchClasses
        if !tapGuess.isEmpty {
            let correct = !expected.isEmpty && tapGuess == expected
            tapResult = correct
            currentChordCorrect = correct
            midiTotalAttempts += 1
            if correct { midiCorrectCount += 1 }
        }
        // Reveal the answer (reuse the verify phase); Next advances from here.
        playPhase = .verifying
        if audioEnabled, let d = currentData {
            suppressMicForPlayback()
            AudioEngine.shared.playChord(d.voicing)
        }
    }

    /// "Show me the chord" — reveal the voicing without grading, whatever's been
    /// tapped. A dedicated help for beginners who don't yet recognise a chord
    /// name like "E♭9". Clears the pending guess so it isn't scored, then reveals.
    func revealTapGuess() {
        guard isTapGuessMode else { return }
        tapGuess = []
        checkTapGuess()
    }

    private func endGame() {
        endTime = Date().timeIntervalSince1970
        if let d = currentData {
            pushTiming(d, durationMs: (endTime - chordStartTime) * 1000)
        }
        currentChordCorrect = nil
        AudioEngine.shared.stopAll()

        let elapsedMs = (endTime - startTime) * 1000
        // In Coach mode, tag the block kind so analysis can distinguish blocks.
        let blockKind = coachMode ? coachPlan?.blocks[safe: coachBlockIdx]?.kind.rawValue : nil
        let result = SessionResult(
            id: Self.generateId(),
            timestamp: Date().timeIntervalSince1970 * 1000,
            elapsedMs: elapsedMs,
            totalChords: actualTotalChords,
            avgMs: actualTotalChords > 0 ? elapsedMs / Double(actualTotalChords) : 0,
            chordTimings: chordTimings,
            settings: SessionSettings(difficulty: difficulty, notation: notation, voicing: voicing,
                                      displayMode: displayMode, accidentals: accidentals, progressionMode: progressionMode),
            midi: SessionMidi(enabled: inputActive, accuracy: midiAccuracy),
            blockKind: blockKind
        )
        // Previous best avg for the same difficulty/voicing/progression (for PB + XP).
        let history = ProgressStore.loadHistory()
        let sameKey = history.filter {
            $0.settings.difficulty == difficulty &&
            $0.settings.voicing == voicing &&
            $0.settings.progressionMode == progressionMode
        }
        let previousBestAvg = sameKey.map { $0.avgMs }.min()

        ProgressStore.saveSession(result)
        ProgressStore.recordPracticeDay()
        // Habit pipeline runs per block, unchanged.
        let habitResult = HabitStore.shared.processSession(result, previousBestAvgMs: previousBestAvg)

        lastResult = result
        lastHabitResult = habitResult
        pendingCelebrations = habitResult.celebrations

        // Coach mode: fold this block into the CoachState and drive the block loop
        // (transition screen, or the teacher-feedback screen at the end).
        if coachMode {
            applyCoachBlockResult(result)
        } else {
            screen = .finished
        }
    }

    /// Start a drill over an explicit custom chord list (parsed progression).
    func startCustom(_ custom: [CustomChord]) {
        var newChords: [String] = []
        var newData: [ChordWithNotes] = []
        for c in custom {
            let notes = getChordNotes(c.root, c.quality, accidentals)
            var voicingArr = getVoicingNotes(notes, voicing, c.root, accidentals)
            if voiceLeadingEnabled, let prev = newData.last {
                voicingArr = computeVoiceLeadVoicing(prev.voicing, voicingArr, accidentals)
            }
            newChords.append(c.display)
            newData.append(ChordWithNotes(chord: c.display, root: c.root, type: c.quality, notes: notes, voicing: voicingArr))
        }
        chords = newChords
        chordsWithNotes = newData
        currentIdx = 0
        playPhase = .playing
        timerStarted = false
        startTime = 0; chordTimings = []; chordStartTime = 0
        heldNotes = []; midiCorrectCount = 0; midiTotalAttempts = 0; autoAdvanceArmed = false
        sessionOctaves = newData.isEmpty ? nil : computeSessionOctaves(newData, accidentals)
        AudioEngine.shared.setPreset(soundPreset)
        if inputMode == .midi { attachMidi() }
        if inputMode == .microphone { attachMic() }
        if inTimeMode { /* metronome starts on first advance */ }
        screen = .playing
    }

    func restart() { startGame() }

    /// Is there enough history to offer a "drill your weak spots" session?
    var canDrillWeakSpots: Bool {
        makeWeakDrillPlan(ProgressStore.loadHistory()) != nil
    }

    /// Re-run as a focused, answer-hidden drill on the player's weakest chords.
    /// No-op if there isn't enough history yet.
    func startWeakDrill() {
        guard let plan = makeWeakDrillPlan(ProgressStore.loadHistory()) else { return }
        isEarTraining = false
        inTimeMode = false
        apply(plan: plan)
        startGame()
    }

    // ─── Ear training ───────────────────────────────────────
    func startEarTraining() {
        generateChords()
        currentIdx = 0
        timerStarted = false
        startTime = 0
        chordTimings = []
        chordStartTime = 0
        earRevealed = false; earGuess = []; earCorrect = 0; earTotal = 0; earResult = nil
        sessionOctaves = chordsWithNotes.isEmpty ? nil : computeSessionOctaves(chordsWithNotes, accidentals)
        AudioEngine.shared.setPreset(soundPreset)
        persistSettings()
        screen = .earTraining
    }

    /// Play the current chord (player must identify it by ear).
    func earPlayChord() {
        if !timerStarted {
            timerStarted = true
            startTime = Date().timeIntervalSince1970
            chordStartTime = startTime
        }
        if let d = currentData { AudioEngine.shared.playChord(d.voicing) }
    }

    /// Toggle a pitch-class in the guess; preview the note.
    func earToggle(_ chrIdx: Int) {
        AudioEngine.shared.playMidi(48 + chrIdx)
        let pc = chrIdx % 12
        if earGuess.contains(pc) { earGuess.remove(pc) } else { earGuess.insert(pc) }
    }

    /// Check the guess against the chord's pitch classes.
    func earCheck() {
        guard let d = currentData else { return }
        let expected = Set(d.voicing.map { noteToSemitone($0) }.filter { $0 != -1 })
        let correct = earGuess == expected
        earResult = correct
        earRevealed = true
        earTotal += 1
        if correct { earCorrect += 1 }
    }

    func earNext() {
        let nowMs = Date().timeIntervalSince1970
        if let d = currentData {
            chordTimings.append(ChordTiming(chord: d.chord, root: d.root, durationMs: (nowMs - chordStartTime) * 1000))
        }
        chordStartTime = nowMs
        earRevealed = false; earGuess = []; earResult = nil

        if currentIdx < actualTotalChords - 1 {
            currentIdx += 1
            if let d = currentData { AudioEngine.shared.playChord(d.voicing) }
        } else {
            earEndGame()
        }
    }

    private func earEndGame() {
        endTime = Date().timeIntervalSince1970
        if let d = currentData {
            chordTimings.append(ChordTiming(chord: d.chord, root: d.root, durationMs: (endTime - chordStartTime) * 1000))
        }
        AudioEngine.shared.stopAll()
        let elapsedMs = (endTime - startTime) * 1000
        let accuracy = earTotal > 0 ? Int((Double(earCorrect) / Double(earTotal) * 100).rounded()) : 0
        let result = SessionResult(
            id: Self.generateId(),
            timestamp: Date().timeIntervalSince1970 * 1000,
            elapsedMs: elapsedMs,
            totalChords: actualTotalChords,
            avgMs: actualTotalChords > 0 ? elapsedMs / Double(actualTotalChords) : 0,
            chordTimings: chordTimings,
            settings: SessionSettings(difficulty: difficulty, notation: notation, voicing: voicing,
                                      displayMode: displayMode, accidentals: accidentals, progressionMode: progressionMode),
            midi: SessionMidi(enabled: true, accuracy: accuracy)
        )
        let history = ProgressStore.loadHistory()
        let previousBestAvg = history.filter {
            $0.settings.difficulty == difficulty && $0.settings.voicing == voicing && $0.settings.progressionMode == progressionMode
        }.map { $0.avgMs }.min()
        ProgressStore.saveSession(result)
        ProgressStore.recordPracticeDay()
        let habitResult = HabitStore.shared.processSession(result, previousBestAvgMs: previousBestAvg)
        lastResult = result
        lastHabitResult = habitResult
        pendingCelebrations = habitResult.celebrations
        screen = .finished
    }

    func resetToSetup() {
        // Leaving mid-Coach-session (back / close): persist progress so far, then
        // drop out of Coach mode. Only a genuine mid-block quit (still on the
        // playing screen — not a transition or the feedback screen) is a quit.
        if coachMode {
            if screen == .playing, let block = coachPlan?.blocks[safe: coachBlockIdx] {
                TelemetryService.shared.track("quit_midblock", [
                    "kind": block.kind.rawValue,
                    "atChord": currentIdx,
                    "targetChords": block.targetChords,
                ])
            }
            endCoachMode()
        }
        screen = .setup
        currentIdx = 0
        chords = []
        chordsWithNotes = []
        timerStarted = false
        AudioEngine.shared.stopAll()
        Metronome.shared.stop()
        detachMidi()
        detachMic()
    }

    // ─── Coach (Auto-Mode) session flow ─────────────────────
    // Mirrors src/routes/train/+page.svelte:
    //   startCoachSession() → session_start telemetry, start block 0
    //   startCoachBlock()   → apply block settings + focus, run as a normal drill
    //   applyCoachBlockResult() (per block) → block_result [+ calibration_result],
    //                          CoachStore.applySession, transition or finish
    //   finishCoachSession() → session_end + coach_decision telemetry, feedback
    //   applyCoachFeedback() → feedback_valve telemetry

    /// Entry point for the "Weiter üben" hero. Builds today's plan and starts the
    /// first block. No-op if the plan somehow has no blocks (engine returns ≥1).
    func startCoachSession() {
        let plan = CoachStore.shared.currentPlan(
            history: ProgressStore.loadHistory(),
            profile: HabitStore.shared.profile
        )
        guard !plan.blocks.isEmpty else { return }

        // Snapshot the pre-session state (currentPlan already stamped lastPlan on it)
        // so session-level teacher feedback diffs start→end, not just the last block.
        coachStateBefore = CoachStore.shared.state
        coachPlan = plan
        coachBlockIdx = 0
        coachMode = true
        coachTransition = nil
        coachFeedback = []
        coachFeedbackGiven = false
        coachShowFeedback = false
        coachSessionBlocks = []
        coachSessionStartedAtMs = Date().timeIntervalSince1970 * 1000
        isEarTraining = false
        inTimeMode = false

        TelemetryService.shared.track("session_start", [
            "estMinutes": plan.estMinutes,
            "blocks": plan.blocks.map { $0.kind.rawValue },
            "frontierUnitId": plan.frontierUnitId ?? NSNull(),
            "dayIndex": CoachStore.shared.state.dayIndex,
        ])
        startCoachBlock(0)
    }

    /// Map a CoachBlock's settings onto the drill state and start it.
    private func startCoachBlock(_ idx: Int) {
        guard let plan = coachPlan, let block = plan.blocks[safe: idx] else { return }
        coachBlockIdx = idx

        loadSettings() // notation/notationSystem/accidentals/sound from the user's prefs
        let s = block.settings
        difficulty = s.difficulty
        notation = s.notation
        voicing = block.focusVoicing.flatMap { VoicingType(rawValue: $0) } ?? s.voicing
        displayMode = s.displayMode
        accidentals = s.accidentals
        progressionMode = s.progressionMode
        totalChords = block.targetChords > 0 ? block.targetChords : s.totalChords

        // Focus plumbing (same axes the weak-drill uses). Adaptive weighting only
        // bites when progressionMode == .random — exactly as intended.
        focusRoots = block.focusRoots ?? []
        qualityFilter = block.focusQualities ?? []
        adaptiveEnabled = (s.progressionMode == .random)

        // Coach never uses the special exercise sub-modes.
        isEarTraining = false
        inTimeMode = false
        voiceLeadingEnabled = false

        startGame()
    }

    /// Called from endGame() when a Coach block finishes. Folds the block's
    /// SessionResult into the CoachState, emits telemetry, then either shows the
    /// between-block transition or ends the session.
    private func applyCoachBlockResult(_ session: SessionResult) {
        guard let plan = coachPlan, let block = plan.blocks[safe: coachBlockIdx] else { return }
        coachSessionBlocks.append(session)

        TelemetryService.shared.track("block_result", [
            "kind": block.kind.rawValue,
            "unitId": plan.frontierUnitId ?? NSNull(),
            "chords": session.totalChords,
            "avgMs": session.avgMs,
            "correctRate": correctRate(session) ?? NSNull(),
            "completed": session.totalChords >= block.targetChords,
        ])

        let wasCalibrated = CoachStore.shared.isCalibrated
        // applySession advances + persists the CoachState (accumulating across
        // blocks). Session-level teacher feedback is computed once at the end from
        // the start snapshot, mirroring the web.
        _ = CoachStore.shared.applySession(plan: plan, session: session)
        if !wasCalibrated && CoachStore.shared.isCalibrated {
            let placed = CoachStore.shared.state.unitStates.values.filter { $0.state == .mastered }.count
            TelemetryService.shared.track("calibration_result", [
                "placedUnits": placed,
                "frontierIndex": CoachStore.shared.state.frontierIndex,
            ])
        }

        let nextIdx = coachBlockIdx + 1
        if nextIdx < plan.blocks.count {
            let next = plan.blocks[nextIdx]
            coachTransition = CoachTransition(
                doneKind: block.kind,
                nextKind: next.kind,
                nextLabelKey: next.labelKey,
                nextLabelParams: next.labelParams ?? [:]
            )
            // Auto-advance after ~2.5s (tap to skip).
            let work = DispatchWorkItem { [weak self] in self?.advanceCoachBlock() }
            coachTransitionWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
        } else {
            finishCoachSession(session)
        }
    }

    /// Dismiss the transition screen and start the next block.
    func advanceCoachBlock() {
        coachTransitionWork?.cancel()
        coachTransitionWork = nil
        guard let plan = coachPlan else { return }
        let nextIdx = coachBlockIdx + 1
        coachTransition = nil
        if nextIdx < plan.blocks.count { startCoachBlock(nextIdx) }
    }

    /// Last block done: gather teacher feedback (already computed by applySession's
    /// before/after diff), emit telemetry, land on the feedback screen.
    private func finishCoachSession(_ lastSession: SessionResult) {
        guard let plan = coachPlan, let before = coachStateBefore else { return }
        // Session-level teacher talk: diff the pre-session snapshot against the now
        // fully-advanced CoachState (web finishCoachSession).
        coachFeedback = teacherFeedback(before, CoachStore.shared.state, lastSession)

        let totalChords = coachSessionBlocks.reduce(0) { $0 + $1.totalChords }
        let totalMs = coachSessionBlocks.reduce(0.0) { $0 + $1.avgMs * Double($1.totalChords) }
        TelemetryService.shared.track("session_end", [
            "durationMs": Date().timeIntervalSince1970 * 1000 - coachSessionStartedAtMs,
            "totalChords": totalChords,
            "avgMs": totalChords > 0 ? totalMs / Double(totalChords) : 0,
            "completedBlocks": coachSessionBlocks.count,
            "totalBlocks": plan.blocks.count,
            "frontierUnitId": plan.frontierUnitId ?? NSNull(),
        ])
        trackCoachDecisions()
        coachShowFeedback = true
        screen = .finished
        AudioEngine.shared.stopAll()
        detachMidi()
        detachMic()
    }

    /// Feedback valve: "too easy / just right / too hard" biases the controller.
    func applyCoachFeedback(_ signal: FeedbackSignal) {
        guard !coachFeedbackGiven else { return }
        CoachStore.shared.applyFeedbackSignal(signal)
        coachFeedbackGiven = true
        TelemetryService.shared.track("feedback_valve", ["signal": signal.rawValue])
    }

    /// Restart a fresh auto-session from the feedback screen ("Again").
    func restartCoachSession() {
        endCoachMode()
        startCoachSession()
    }

    /// Leave Coach mode cleanly (feedback "Done", or on abort). Flushes telemetry.
    func endCoachMode() {
        coachTransitionWork?.cancel()
        coachTransitionWork = nil
        coachMode = false
        coachPlan = nil
        coachTransition = nil
        coachFeedback = []
        coachShowFeedback = false
        coachSessionBlocks = []
        TelemetryService.shared.flush()
    }

    /// Fraction of chords answered correctly this block, or nil if ungraded.
    private func correctRate(_ session: SessionResult) -> Double? {
        let graded = (session.chordTimings ?? []).filter { $0.correct != nil }
        guard !graded.isEmpty else { return nil }
        return Double(graded.filter { $0.correct == true }.count) / Double(graded.count)
    }

    /// Diff the pre-session and post-session CoachStates against the skill ladder
    /// and emit one coach_decision telemetry event per unit transition, keeping the
    /// unitId (which the localized TeacherStatement params drop). Web parity:
    /// trackCoachDecisions().
    private func trackCoachDecisions() {
        guard let before = coachStateBefore else { return }
        let after = CoachStore.shared.state
        let ladder = buildSkillLadder()
        let justCalibrated = !before.calibrated && after.calibrated
        for unit in ladder {
            let b = before.unitStates[unit.id]?.state ?? .locked
            let a = after.unitStates[unit.id]?.state ?? .locked
            if b == a { continue }
            if a == .mastered {
                TelemetryService.shared.track("coach_decision", [
                    "decision": justCalibrated ? "placed" : "promoted",
                    "unitId": unit.id,
                ])
            } else if b == .mastered && a == .practicing {
                TelemetryService.shared.track("coach_decision", ["decision": "demoted", "unitId": unit.id])
            }
        }
        // Held frontier: holds increased on the pre-session frontier without a promotion.
        if let frontierId = before.lastPlan?.frontierUnitId {
            let bh = before.unitStates[frontierId]?.holds ?? 0
            let ah = after.unitStates[frontierId]?.holds ?? 0
            if ah > bh && after.unitStates[frontierId]?.state != .mastered {
                TelemetryService.shared.track("coach_decision", ["decision": "held", "unitId": frontierId])
            }
        }
    }

    private static func generateId() -> String {
        String(Int(Date().timeIntervalSince1970 * 1000), radix: 36) + String(Int.random(in: 0..<10000), radix: 36)
    }
}

private extension Array {
    /// Bounds-checked subscript — nil instead of a crash for out-of-range indices.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
