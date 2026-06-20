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
    enum Screen { case setup, playing, finished }

    // ─── Settings (persisted) ───────────────────────────────
    var difficulty: Difficulty = .beginner
    var notation: NotationStyle = .standard
    var voicing: VoicingType = .root
    var displayMode: DisplayMode = .always
    var accidentals: AccidentalPreference = .both
    var notationSystem: NotationSystem = .international
    var totalChords: Int = 20
    var progressionMode: ProgressionMode = .random
    var voiceLeadingEnabled = false
    var adaptiveEnabled = false
    var focusRoots: [String] = []
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
    private var timerStarted = false
    private var startTime: TimeInterval = 0
    private var chordStartTime: TimeInterval = 0
    private var chordTimings: [ChordTiming] = []
    private(set) var endTime: TimeInterval = 0
    private(set) var lastResult: SessionResult?
    /// Celebrations from the just-finished session (level-up, PB, …) for the UI.
    var pendingCelebrations: [CelebrationEvent] = []
    private(set) var lastHabitResult: SessionHabitResult?

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
        let available = CHORDS_BY_DIFFICULTY[difficulty] ?? []
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
                midiTotalAttempts += 1
                midiCorrectCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    guard let self, self.autoAdvanceArmed else { return }
                    self.autoAdvanceArmed = false
                    self.advanceFromInput()
                }
            }
        } else if heldNotes.count >= d.voicing.count {
            midiTotalAttempts += 1
        }
    }

    /// Advance triggered by correct input (skips the verify pause).
    private func advanceFromInput() {
        playPhase = .playing
        let nowMs = Date().timeIntervalSince1970
        if let d = currentData {
            chordTimings.append(ChordTiming(chord: d.chord, root: d.root, durationMs: (nowMs - chordStartTime) * 1000))
        }
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

    /// First interaction starts the timer (chord already visible).
    private func beginTimer() {
        timerStarted = true
        startTime = Date().timeIntervalSince1970
        chordStartTime = startTime
        if audioEnabled, let d = chordsWithNotes.first {
            suppressMicForPlayback()
            AudioEngine.shared.playChord(d.voicing)
        }
    }

    /// Advance / reveal. Tap-driven (Space on web).
    func next() {
        guard screen == .playing else { return }

        if !timerStarted {
            beginTimer()
            return
        }

        // Verify mode: first tap reveals voicing, second advances.
        if displayMode == .verify && playPhase == .playing {
            playPhase = .verifying
            if audioEnabled, let d = currentData {
                suppressMicForPlayback()
                AudioEngine.shared.playChord(d.voicing)
            }
            return
        }
        playPhase = .playing

        // Record timing for the chord we leave.
        let nowMs = Date().timeIntervalSince1970
        if let d = currentData {
            chordTimings.append(ChordTiming(chord: d.chord, root: d.root, durationMs: (nowMs - chordStartTime) * 1000))
        }
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

    private func endGame() {
        endTime = Date().timeIntervalSince1970
        if let d = currentData {
            chordTimings.append(ChordTiming(chord: d.chord, root: d.root, durationMs: (endTime - chordStartTime) * 1000))
        }
        AudioEngine.shared.stopAll()

        let elapsedMs = (endTime - startTime) * 1000
        let result = SessionResult(
            id: Self.generateId(),
            timestamp: Date().timeIntervalSince1970 * 1000,
            elapsedMs: elapsedMs,
            totalChords: actualTotalChords,
            avgMs: actualTotalChords > 0 ? elapsedMs / Double(actualTotalChords) : 0,
            chordTimings: chordTimings,
            settings: SessionSettings(difficulty: difficulty, notation: notation, voicing: voicing,
                                      displayMode: displayMode, accidentals: accidentals, progressionMode: progressionMode),
            midi: SessionMidi(enabled: inputActive, accuracy: midiAccuracy)
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
        let habitResult = HabitStore.shared.processSession(result, previousBestAvgMs: previousBestAvg)

        lastResult = result
        lastHabitResult = habitResult
        pendingCelebrations = habitResult.celebrations
        screen = .finished
    }

    func restart() { startGame() }

    func resetToSetup() {
        screen = .setup
        currentIdx = 0
        chords = []
        chordsWithNotes = []
        timerStarted = false
        AudioEngine.shared.stopAll()
        detachMidi()
        detachMic()
    }

    private static func generateId() -> String {
        String(Int(Date().timeIntervalSince1970 * 1000), radix: 36) + String(Int.random(in: 0..<10000), radix: 36)
    }
}
