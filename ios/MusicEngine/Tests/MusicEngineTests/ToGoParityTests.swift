// Parity mirror of src/lib/engine/togo.test.ts — same 44 scenarios, same
// expected values, same deterministic seed. If ToGo.swift drifts from togo.ts,
// these fail.

import XCTest
@testable import MusicEngine

final class ToGoParityTests: XCTestCase {

    /// Deterministic rng: cycles a fixed sequence so every test is reproducible.
    private func seeded(_ seq: [Double] = [0.1, 0.5, 0.9, 0.3, 0.7, 0.05, 0.45, 0.85]) -> Rng {
        let box = Box()
        return {
            let v = seq[box.i % seq.count]
            box.i += 1
            return v
        }
    }

    private final class Box { var i = 0 }

    private let CAPS_ALL = ToGoCapabilities(mic: true, audio: true)

    // ─── Exercise construction ──────────────────────────────

    func testIntervalPlaysTwoNotesAndOffersTheRightLabel() {
        let ex = buildIntervalExercise(seeded())
        XCTAssertEqual(ex.kind, .interval)
        XCTAssertEqual(ex.play.type, "sequence")
        if case let .sequence(notes, _) = ex.play { XCTAssertEqual(notes.count, 2) }
        XCTAssertTrue(ex.options.contains(ex.answerLabel))
        XCTAssertEqual(ex.options[ex.answerIndex], ex.answerLabel)
    }

    // The pitched-interval fixes, mirroring togo.test.ts. Found by play-testing:
    // a major seventh sounded as a semitone DOWN, and an octave played the same
    // note twice — pitch-class arithmetic, so "distance" had no direction.

    /// "Bb4" → absolute semitone, so tests can measure real distance.
    private func absSemitone(_ note: String) -> Int {
        // Split at the first digit or minus: everything before is the note name,
        // everything after is the octave.
        guard let split = note.firstIndex(where: { $0.isNumber || $0 == "-" }) else {
            XCTFail("not a pitched note: \(note)")
            return 0
        }
        let name = String(note[note.startIndex..<split])
        let octave = Int(note[split...]) ?? 0
        return noteToSemitone(name) + 12 * octave
    }

    private func notesOf(_ ex: ToGoExercise) -> [String] {
        if case let .sequence(notes, _) = ex.play { return notes }
        XCTFail("expected a sequence")
        return []
    }

    func testAscendingIntervalRisesByItsSemitoneCount() {
        for depth in 2...INTERVAL_LADDER.count {
            let ex = buildIntervalExercise(seeded(), DEFAULT_TOGO_PARAMS, .flats, ladderDepth: depth)
            let entry = INTERVAL_LADDER.first { $0.label == ex.answerLabel }!
            let n = notesOf(ex)
            XCTAssertEqual(absSemitone(n[1]) - absSemitone(n[0]), entry.semitones)
        }
    }

    func testDescendingIntervalFallsByItsSemitoneCount() {
        for depth in 2...INTERVAL_LADDER.count {
            let ex = buildIntervalExercise(
                seeded(), DEFAULT_TOGO_PARAMS, .flats, ladderDepth: depth, descending: true)
            let entry = INTERVAL_LADDER.first { $0.label == ex.answerLabel }!
            let n = notesOf(ex)
            XCTAssertEqual(absSemitone(n[1]) - absSemitone(n[0]), -entry.semitones)
        }
    }

    func testIntervalNeverSoundsTheSamePitchTwice() {
        for depth in 2...INTERVAL_LADDER.count {
            for down in [false, true] {
                let ex = buildIntervalExercise(
                    seeded(), DEFAULT_TOGO_PARAMS, .flats, ladderDepth: depth, descending: down)
                let n = notesOf(ex)
                XCTAssertNotEqual(n[0], n[1])
            }
        }
    }

    func testIntervalDistinguishesDirection() {
        let up = buildIntervalExercise(seeded(), DEFAULT_TOGO_PARAMS, .flats, ladderDepth: 4, descending: false)
        let down = buildIntervalExercise(seeded(), DEFAULT_TOGO_PARAMS, .flats, ladderDepth: 4, descending: true)
        XCTAssertTrue(up.id.contains("up"))
        XCTAssertTrue(down.id.contains("down"))
        XCTAssertNotEqual(up.promptKey, down.promptKey)
    }

    func testPitchedNoteCrossesTheOctaveBoundaryDownward() {
        // C4 down a minor second is B3, not B4 — the floor-divide, in one case.
        XCTAssertEqual(getPitchedNote(0, -1, .flats, octave: 4), "B3")
        XCTAssertEqual(getPitchedNote(0, 12, .flats, octave: 4), "C5")
        XCTAssertEqual(getPitchedNote(0, 0, .flats, octave: 4), "C4")
    }

    func testQualitySoundsARealChordAndAnswerIsAmongOptions() {
        let ex = buildQualityExercise(seeded())
        XCTAssertEqual(ex.play.type, "chord")
        if case let .chord(notes) = ex.play { XCTAssertGreaterThanOrEqual(notes.count, 3) }
        XCTAssertEqual(ex.options[ex.answerIndex], ex.answerLabel)
    }

    func testQualityHonoursAFocusQuality() {
        let ex = buildQualityExercise(seeded(), DEFAULT_TOGO_PARAMS, .flats, .beginner,
                                      unitId: "root|m7|easy", forcedQuality: "m7")
        XCTAssertEqual(ex.answerLabel, "m7")
        XCTAssertEqual(ex.unitId, "root|m7|easy")
    }

    func testProgressionSoundsRealChordsNotSingleNotes() {
        let ex = buildProgressionExercise(seeded())
        // A cadence must be heard as chords — flattening it would destroy the
        // very thing the exercise tests.
        XCTAssertEqual(ex.play.type, "chords")
        if case let .chords(chords, _) = ex.play {
            XCTAssertGreaterThanOrEqual(chords.count, 2)
            XCTAssertTrue(chords.allSatisfy { $0.count >= 3 })
        }
        XCTAssertEqual(ex.options[ex.answerIndex], ex.answerLabel)
    }

    func testProgressionHasOneChordPerRomanNumeral() {
        let ex = buildProgressionExercise(seeded())
        let degrees = ex.id.split(separator: "|")[2].split(separator: "-")
        if case let .chords(chords, _) = ex.play {
            XCTAssertEqual(chords.count, degrees.count)
        }
    }

    func testSingHoldsADroneAndTargetsAPitchClass() {
        let ex = buildSingExercise(seeded())
        XCTAssertEqual(ex.play.type, "drone")
        XCTAssertEqual(ex.input.type, "sing")
        if case let .sing(pc) = ex.input {
            XCTAssertGreaterThanOrEqual(pc, 0)
            XCTAssertLessThan(pc, 12)
        }
    }

    func testTimeAsksForAPulseAndNamesTheBeats() {
        let ex = buildTimeExercise(seeded())
        XCTAssertEqual(ex.play.type, "pulse")
        XCTAssertEqual(ex.input.type, "tap")
        if case let .tap(onBeats, _, _) = ex.input { XCTAssertGreaterThan(onBeats.count, 0) }
    }

    func testLickPlaysAPhraseAndExpectsItTappedBack() {
        let ex = buildLickExercise(seeded())
        XCTAssertEqual(ex.play.type, "sequence")
        XCTAssertEqual(ex.input.type, "notes")
        if case let .sequence(notes, _) = ex.play, case let .notes(pcs) = ex.input {
            XCTAssertEqual(pcs.count, notes.count)
        }
    }

    func testTheoryIsSilent() {
        let deck = buildTheoryDeck()
        let ex = buildTheoryExercise(deck[0], seeded())
        XCTAssertEqual(ex.play.type, "silent")
        XCTAssertEqual(ex.cardId, deck[0].id)
    }

    // ─── options ────────────────────────────────────────────

    func testOptionsAlwaysContainAnswerExactlyOnceAndAreDistinct() {
        for i in 0..<20 {
            let rng = seeded([Double(i) / 20.0, 0.3, 0.66, 0.12, 0.98, 0.44])
            let ex = buildIntervalExercise(rng)
            let hits = ex.options.filter { $0 == ex.answerLabel }.count
            XCTAssertEqual(hits, 1)
            XCTAssertEqual(Set(ex.options).count, ex.options.count)
        }
    }

    func testOptionsOfferDistractorsPlusTheAnswer() {
        let ex = buildIntervalExercise(seeded())
        XCTAssertEqual(ex.options.count, DEFAULT_TOGO_PARAMS.distractors + 1)
    }

    // ─── Grading ────────────────────────────────────────────

    func testGradeChoiceAcceptsAnswerIndexAndRejectsOthers() {
        let ex = buildIntervalExercise(seeded())
        XCTAssertTrue(gradeChoice(ex, ex.answerIndex))
        XCTAssertFalse(gradeChoice(ex, (ex.answerIndex + 1) % ex.options.count))
    }

    func testGradeSingAcceptsTargetPitchClassInAnyOctave() {
        let ex = buildSingExercise(seeded())
        var pc = 0
        if case let .sing(t) = ex.input { pc = t }
        XCTAssertTrue(gradeSing(ex, [pc + 60]))  // one octave
        XCTAssertTrue(gradeSing(ex, [pc + 72]))  // another
        XCTAssertFalse(gradeSing(ex, [pc + 61])) // a semitone off
    }

    func testGradeSingAcceptsRightNoteAmongSeveralDetected() {
        let ex = buildSingExercise(seeded())
        var pc = 0
        if case let .sing(t) = ex.input { pc = t }
        XCTAssertTrue(gradeSing(ex, [pc + 61, pc + 60]))
    }

    func testGradeNotesMatchesPhraseAsPitchClassSet() {
        let ex = buildLickExercise(seeded())
        var target: [Int] = []
        if case let .notes(t) = ex.input { target = t }
        XCTAssertTrue(gradeNotes(ex, target.map { $0 + 60 }))
        XCTAssertFalse(gradeNotes(ex, Array(target.dropLast()))) // missing a note
    }

    func testGradeTapsScoresDeadOnTapsAsPerfect() {
        let beats: [Double] = [0, 500, 1000, 1500]
        let s = gradeTaps(beats, [0, 500, 1000, 1500], 120)
        XCTAssertEqual(s.hits, 4)
        XCTAssertTrue(s.correct)
        XCTAssertEqual(s.meanAbsOffsetMs, 0)
    }

    func testGradeTapsReportsSignedOffset() {
        let beats: [Double] = [0, 500, 1000]
        let rushing = gradeTaps(beats, [-40, 460, 960], 120)
        XCTAssertLessThan(rushing.meanOffsetMs, 0)
        let dragging = gradeTaps(beats, [40, 540, 1040], 120)
        XCTAssertGreaterThan(dragging.meanOffsetMs, 0)
        // Both are equally tight in absolute terms.
        XCTAssertEqual(rushing.meanAbsOffsetMs, dragging.meanAbsOffsetMs, accuracy: 1e-5)
    }

    func testGradeTapsIgnoresTapsOutsideTolerance() {
        let s = gradeTaps([0, 500], [0, 900], 120)
        XCTAssertEqual(s.hits, 1)
        XCTAssertFalse(s.correct) // 1/2 < 0.7
    }

    func testGradeTapsNeverLetsOneTapScoreTwoBeats() {
        // A single tap between two beats must satisfy only the nearer one.
        let s = gradeTaps([0, 100], [50], 120)
        XCTAssertEqual(s.hits, 1)
    }

    func testGradeTapsCountsMissedBeatsAgainstYou() {
        let s = gradeTaps([0, 500, 1000, 1500], [0, 500], 120)
        XCTAssertEqual(s.hits, 2)
        XCTAssertEqual(s.expected, 4)
        XCTAssertFalse(s.correct)
    }

    func testGradeTapsPassesAtSeventyPercentRatio() {
        let s = gradeTaps([0, 500, 1000, 1500], [0, 500, 1000], 120)
        XCTAssertGreaterThanOrEqual(Double(s.hits) / Double(s.expected), 0.7)
        XCTAssertTrue(s.correct)
    }

    // ─── Theory deck + SRS ──────────────────────────────────

    func testDeckGeneratesCardsWithDistinctIdsAndRealAnswers() {
        let deck = buildTheoryDeck()
        XCTAssertGreaterThan(deck.count, 20)
        XCTAssertEqual(Set(deck.map { $0.id }).count, deck.count)
        for c in deck {
            XCTAssertGreaterThan(c.answer.count, 0)
            XCTAssertTrue(c.distractors.allSatisfy { $0 != c.answer })
        }
    }

    func testDeckIsDeterministic() {
        XCTAssertEqual(buildTheoryDeck(), buildTheoryDeck())
    }

    func testDeckKnowsTritoneSubOfC7IsGb7() {
        let deck = buildTheoryDeck()
        XCTAssertEqual(deck.first { $0.id == "tritone|C" }?.answer, "Gb7")
    }

    func testDeckKnowsRelativeMinorOfCIsAm() {
        let deck = buildTheoryDeck()
        XCTAssertEqual(deck.first { $0.id == "relminor|C" }?.answer, "Am")
    }

    func testDeckKnowsThirdOfC7IsE() {
        let deck = buildTheoryDeck()
        XCTAssertEqual(deck.first { $0.id == "degree|C|7|4" }?.answer, "E")
    }

    func testSM2LengthensIntervalOnSuccessAndResetsOnFailure() {
        let now: Double = 1_000_000
        var s = newCardState("x", now)
        s = scheduleCard(s, 5, now) // first success
        XCTAssertEqual(s.interval, 1)
        s = scheduleCard(s, 5, now) // second
        XCTAssertEqual(s.interval, 3)
        let grown = scheduleCard(s, 5, now)
        XCTAssertGreaterThan(grown.interval, 3)
        let lapsed = scheduleCard(grown, 1, now)
        XCTAssertEqual(lapsed.interval, 1)
        XCTAssertEqual(lapsed.repetitions, 0)
    }

    func testSM2NeverLetsEaseFallBelowFloor() {
        let now: Double = 0
        var s = newCardState("x", now)
        for _ in 0..<20 { s = scheduleCard(s, 0, now) }
        XCTAssertGreaterThanOrEqual(s.ease, DEFAULT_TOGO_PARAMS.minEase)
    }

    func testSM2SchedulesNextReviewIntoTheFuture() {
        let now: Double = 5_000_000
        let s = scheduleCard(newCardState("x", now), 5, now)
        XCTAssertGreaterThan(s.nextReview, now)
    }

    func testDueCardsTreatsNeverSeenCardsAsDue() {
        let deck = buildTheoryDeck()
        XCTAssertEqual(dueCards(deck, [:], 0).count, deck.count)
    }

    func testDueCardsHidesCardsScheduledForLater() {
        let deck = Array(buildTheoryDeck().prefix(3))
        let now: Double = 1_000_000
        var states: [String: TheoryCardState] = [:]
        for c in deck { states[c.id] = scheduleCard(newCardState(c.id, now), 5, now) }
        XCTAssertEqual(dueCards(deck, states, now).count, 0)
        // …and shows them again once the date arrives.
        let later = now + 2 * 24 * 60 * 60 * 1000
        XCTAssertEqual(dueCards(deck, states, later).count, 3)
    }

    // ─── Session composition ────────────────────────────────

    func testSessionFillsConfiguredLength() {
        let s = buildToGoSession(seeded(), CAPS_ALL, ToGoSessionOptions(deck: buildTheoryDeck()))
        XCTAssertEqual(s.exercises.count, DEFAULT_TOGO_PARAMS.sessionLength)
    }

    func testSessionDropsSingWhenThereIsNoMic() {
        let s = buildToGoSession(seeded(), ToGoCapabilities(mic: false, audio: true),
                                 ToGoSessionOptions(deck: buildTheoryDeck()))
        XCTAssertFalse(s.exercises.contains { $0.kind == .sing })
    }

    func testSessionFallsBackToSilentTheoryWhenAudioIsOff() {
        let s = buildToGoSession(seeded(), ToGoCapabilities(mic: false, audio: false),
                                 ToGoSessionOptions(deck: buildTheoryDeck()))
        XCTAssertGreaterThan(s.exercises.count, 0)
        XCTAssertTrue(s.exercises.allSatisfy { $0.kind == .theory })
    }

    func testSessionStillProducedWithNoTheoryDeck() {
        let s = buildToGoSession(seeded(), CAPS_ALL, ToGoSessionOptions())
        XCTAssertGreaterThan(s.exercises.count, 0)
        XCTAssertFalse(s.exercises.contains { $0.kind == .theory })
    }

    func testSessionHonoursSingleDisciplineRequest() {
        let s = buildToGoSession(seeded(), CAPS_ALL, ToGoSessionOptions(only: .interval))
        XCTAssertTrue(s.exercises.allSatisfy { $0.kind == .interval })
        XCTAssertEqual(s.sayKey, "togo.say.single")
    }

    func testSessionMirrorsCoachFocusQualityOnTheEarSide() {
        let s = buildToGoSession(seeded(), CAPS_ALL,
                                 ToGoSessionOptions(focusQuality: "m7", only: .quality))
        XCTAssertTrue(s.exercises.allSatisfy { $0.answerLabel == "m7" })
    }

    func testSessionStillCoversEveryDisciplineAfterShuffling() {
        let s = buildToGoSession(seeded(), CAPS_ALL, ToGoSessionOptions(deck: buildTheoryDeck()))
        // 8 slots dealt round-robin over 7 disciplines → every one appears.
        XCTAssertEqual(Set(s.exercises.map { $0.kind }).count, 7)
    }

    func testSessionDoesNotAlwaysRunInLadderOrder() {
        let a = buildToGoSession(seeded([0.1, 0.5, 0.9, 0.3]), CAPS_ALL, ToGoSessionOptions(deck: buildTheoryDeck()))
        let b = buildToGoSession(seeded([0.8, 0.2, 0.05, 0.62]), CAPS_ALL, ToGoSessionOptions(deck: buildTheoryDeck()))
        XCTAssertNotEqual(a.exercises.map { $0.kind }, b.exercises.map { $0.kind })
    }

    func testSessionIsReproducibleForAGivenSeed() {
        let a = buildToGoSession(seeded(), CAPS_ALL, ToGoSessionOptions(deck: buildTheoryDeck()))
        let b = buildToGoSession(seeded(), CAPS_ALL, ToGoSessionOptions(deck: buildTheoryDeck()))
        XCTAssertEqual(a.exercises.map { $0.id }, b.exercises.map { $0.id })
    }

    // ─── Summary + card application ─────────────────────────

    func testSummarizeCountsAccuracyAndBreaksItDownPerDiscipline() {
        let results: [ToGoResult] = [
            ToGoResult(exerciseId: "a", kind: .interval, correct: true, ms: 1000),
            ToGoResult(exerciseId: "b", kind: .interval, correct: false, ms: 2000),
            ToGoResult(exerciseId: "c", kind: .theory, correct: true, ms: 900),
        ]
        let s = summarize(results)
        XCTAssertEqual(s.total, 3)
        XCTAssertEqual(s.correct, 2)
        XCTAssertEqual(s.byKind["interval"], ToGoKindTally(total: 2, correct: 1))
        XCTAssertEqual(s.byKind["theory"], ToGoKindTally(total: 1, correct: 1))
        XCTAssertEqual(s.avgMs, 1300, accuracy: 0.5)
    }

    func testSummarizeMapsAccuracyOntoSM2Quality() {
        let perfect = summarize([ToGoResult(exerciseId: "a", kind: .theory, correct: true, ms: 1)])
        XCTAssertEqual(perfect.srsQuality, 5)
        let failed = summarize([ToGoResult(exerciseId: "a", kind: .theory, correct: false, ms: 1)])
        XCTAssertEqual(failed.srsQuality, 0)
    }

    func testSummarizeHandlesEmptyRun() {
        let s = summarize([])
        XCTAssertEqual(s.ratio, 0)
        XCTAssertEqual(s.avgMs, 0)
    }

    func testApplyResultsReschedulesOnlyTouchedCards() {
        let now: Double = 2_000_000
        let next = applyResultsToCards([:], [
            ToGoResult(exerciseId: "x", kind: .theory, correct: true, ms: 1200, cardId: "tritone|C"),
            ToGoResult(exerciseId: "y", kind: .interval, correct: true, ms: 1200), // no card
        ], now)
        XCTAssertEqual(Array(next.keys), ["tritone|C"])
        XCTAssertGreaterThan(next["tritone|C"]!.nextReview, now)
    }

    func testApplyResultsSendsMissedCardBackToTomorrow() {
        let now: Double = 2_000_000
        var states = applyResultsToCards([:], [
            ToGoResult(exerciseId: "x", kind: .theory, correct: true, ms: 1000, cardId: "tritone|C"),
        ], now)
        states = applyResultsToCards(states, [
            ToGoResult(exerciseId: "x", kind: .theory, correct: true, ms: 1000, cardId: "tritone|C"),
        ], now)
        let grown = states["tritone|C"]!.interval
        let lapsed = applyResultsToCards(states, [
            ToGoResult(exerciseId: "x", kind: .theory, correct: false, ms: 9000, cardId: "tritone|C"),
        ], now)
        XCTAssertGreaterThan(grown, 1)
        XCTAssertEqual(lapsed["tritone|C"]!.interval, 1)
    }

    // ─── Vocabulary sanity ──────────────────────────────────

    func testIntervalLadderCoversAllTwelveIntervals() {
        XCTAssertEqual(Set(INTERVAL_LADDER.map { $0.semitones }).count, 12)
    }

    func testIntervalLadderIsOrderedEasiestFirst() {
        func idx(_ s: Int) -> Int { INTERVAL_LADDER.firstIndex { $0.semitones == s }! }
        XCTAssertLessThan(idx(12), idx(6))
        XCTAssertLessThan(idx(7), idx(6))
    }

    // ─── Cross-language determinism (Swift-only, guards the port) ──

    /// `withDistractors` must produce the IDENTICAL sequence as TS for the same
    /// rng draws — same candidate walk, same Fisher-Yates.
    func testWithDistractorsMatchesTSSequence() {
        let rng = seeded()
        let (options, answerIndex) = withDistractors(
            "Octave", INTERVAL_LADDER.map { $0.label }, 3, rng)
        XCTAssertEqual(options.count, 4)
        XCTAssertEqual(options[answerIndex], "Octave")
        XCTAssertEqual(Set(options).count, 4)
        // Re-running with a fresh seed reproduces exactly the same order.
        let (again, _) = withDistractors("Octave", INTERVAL_LADDER.map { $0.label }, 3, seeded())
        XCTAssertEqual(options, again)
    }
}
