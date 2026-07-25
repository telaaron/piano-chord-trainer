// Parity mirror of src/lib/engine/coach.test.ts — same 20 scenarios, same
// expected values. If Coach.swift drifts from coach.ts, these fail.

import XCTest
@testable import MusicEngine

final class CoachParityTests: XCTestCase {

    // ─── Helpers ────────────────────────────────────────────

    private func profile(dailyGoalMinutes: Int? = nil) -> HabitProfile {
        var p = createDefaultProfile()
        if let dailyGoalMinutes { p.dailyGoalMinutes = dailyGoalMinutes }
        return p
    }

    private func timing(_ root: String, _ durationMs: Double, _ correct: Bool? = nil) -> ChordTiming {
        ChordTiming(chord: "\(root)X", root: root, durationMs: durationMs, correct: correct)
    }

    /// Chord timing with an explicit quality display in the name, for calibration tests.
    private func qTiming(_ root: String, _ quality: String, _ durationMs: Double, _ correct: Bool? = nil) -> ChordTiming {
        ChordTiming(chord: "\(root)\(quality)", root: root, durationMs: durationMs, correct: correct)
    }

    private func session(_ timings: [ChordTiming], voicing: VoicingType = .root) -> SessionResult {
        let avg = timings.isEmpty ? 0 : timings.reduce(0.0) { $0 + $1.durationMs } / Double(timings.count)
        return SessionResult(
            id: "test",
            timestamp: 0,
            elapsedMs: avg * Double(timings.count),
            totalChords: timings.count,
            avgMs: avg,
            chordTimings: timings,
            settings: SessionSettings(
                difficulty: .beginner, notation: .standard, voicing: voicing,
                displayMode: .verify, accidentals: .both, progressionMode: .random),
            midi: SessionMidi(enabled: false, accuracy: 0)
        )
    }

    /// State where calibration is done but nothing mastered — frontier at unit 0.
    private func calibratedState() -> CoachState {
        var s = createInitialCoachState()
        s.calibrated = true
        return s
    }

    // ─── Skill ladder ───────────────────────────────────────

    func testLadderIsDeterministic() {
        XCTAssertEqual(buildSkillLadder(), buildSkillLadder())
    }

    func testLadderThreeTiersPerPairInOrder() {
        let ladder = buildSkillLadder()
        XCTAssertEqual(ladder[0].voicing, .root)
        XCTAssertEqual(ladder[0].quality, "Maj7")
        XCTAssertEqual(ladder[0].keyTier, .easy)
        XCTAssertEqual(ladder[0].index, 0)
        XCTAssertEqual(ladder[1].keyTier, .med)
        XCTAssertEqual(ladder[1].index, 1)
        XCTAssertEqual(ladder[2].keyTier, .all)
        XCTAssertEqual(ladder[2].index, 2)
        XCTAssertEqual(ladder.count % 3, 0)
    }

    func testLadderDeduplicatesPairs() {
        let ladder = buildSkillLadder()
        let pairs = Set(ladder.map { "\($0.voicing.rawValue)|\($0.quality)" })
        XCTAssertEqual(ladder.count, pairs.count * 3)
    }

    func testLadderMapsQualitiesToLowestDifficulty() {
        let ladder = buildSkillLadder()
        let maj7 = ladder.first { $0.quality == "Maj7" }!
        XCTAssertEqual(maj7.difficulty, .beginner)
        if let alt = ladder.first(where: { $0.quality == "7#9" }) {
            XCTAssertEqual(alt.difficulty, .advanced)
        }
    }

    // ─── focusQualities — a block delivers only what it promises ──

    func testNewBlockPinsFrontierQuality() {
        let state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[state.frontierIndex]
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let newBlock = plan.blocks.first { $0.kind == .new }
        XCTAssertNotNil(newBlock)
        XCTAssertEqual(newBlock?.focusQualities, [frontier.quality])
    }

    func testWarmupReviewApplyLeaveQualityOpen() {
        let state = calibratedState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        for b in plan.blocks where b.kind == .warmup || b.kind == .review || b.kind == .apply {
            XCTAssertNil(b.focusQualities)
        }
    }

    // ─── Session sizing ─────────────────────────────────────

    func testFiveMinuteSessionStaysAroundTwentyChords() {
        let state = calibratedState()
        let plan = buildCoachPlan([], profile(dailyGoalMinutes: 5), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let total = plan.blocks.reduce(0) { $0 + $1.targetChords }
        XCTAssertLessThanOrEqual(total, 24)
        XCTAssertGreaterThanOrEqual(total, 12)
    }

    func testNoSingleBlockBecomesASlog() {
        let state = calibratedState()
        for mins in [2, 5, 10, 20, 45] {
            let plan = buildCoachPlan([], profile(dailyGoalMinutes: mins), nil, state, DEFAULT_COACH_PARAMS, now: 0)
            for b in plan.blocks {
                XCTAssertLessThanOrEqual(b.targetChords, DEFAULT_COACH_PARAMS.maxBlockChords)
                XCTAssertGreaterThanOrEqual(b.targetChords, DEFAULT_COACH_PARAMS.minBlockChords)
            }
        }
    }

    // ─── Review stays focused ───────────────────────────────

    func testReviewRefreshesTheMostRecentlyPractisedQualities() {
        var state = calibratedState()
        let ladder = buildSkillLadder()
        let stamp: [String: Double] = ["Maj7": 100, "7": 900, "m7": 500]
        for (q, at) in stamp {
            for u in ladder where u.voicing == .root && u.quality == q && u.keyTier == .easy {
                state.unitStates[u.id] = UnitProgress(state: .mastered, lastTrainedAt: at, holds: 0)
            }
        }
        var p = profile()
        p.chordSchedule = [ChordReview(chordKey: "C-Maj7", root: "C", quality: "Maj7",
                                       lastReviewed: "2020-01-01", nextReview: "2020-01-01",
                                       interval: 1, ease: 2, repetitions: 1)]
        let plan = buildCoachPlan([], p, nil, state, DEFAULT_COACH_PARAMS,
                                  now: Date().timeIntervalSince1970 * 1000)
        let review = plan.blocks.first { $0.kind == .review }
        XCTAssertEqual(review?.focusQualities, ["7", "m7"])
    }

    // ─── Promotion / Hold / Demotion ────────────────────────

    func testPromotesWhenAboveRatio() {
        let state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let timings = (0..<10).map { timing(frontier.keys[$0 % frontier.keys.count], 1500, true) }
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let next = applySessionToCoach(state, plan, session(timings, voicing: frontier.voicing), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertEqual(next.unitStates[frontier.id]?.state, .mastered)
        XCTAssertGreaterThan(next.frontierIndex, 0)
    }

    func testDoesNotPromoteBelowRatioRecordsHold() {
        let state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let fast = (0..<5).map { timing(frontier.keys[$0 % frontier.keys.count], 1500, true) }
        let slow = (0..<5).map { timing(frontier.keys[$0 % frontier.keys.count], 4000, true) }
        let timings = fast + slow
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let next = applySessionToCoach(state, plan, session(timings, voicing: frontier.voicing), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertNotEqual(next.unitStates[frontier.id]?.state, .mastered)
        XCTAssertEqual(next.unitStates[frontier.id]?.holds, 1)
        XCTAssertEqual(next.frontierIndex, 0)
    }

    func testHoldTurnsNewBlockGuided() {
        var state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let slow = (0..<6).map { timing(frontier.keys[$0 % frontier.keys.count], 4000, true) }
        let plan0 = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        state = applySessionToCoach(state, plan0, session(slow, voicing: frontier.voicing), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertEqual(state.unitStates[frontier.id]?.holds, 1)

        let plan1 = buildCoachPlan([], profile(dailyGoalMinutes: 5), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let newBlock = plan1.blocks.first { $0.kind == .new }!
        XCTAssertEqual(newBlock.settings.displayMode, .always)
    }

    func testDemotesAtMostOneStep() {
        var state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        // Master easy first, so med becomes frontier.
        let fast = (0..<8).map { timing(frontier.keys[$0 % frontier.keys.count], 1400, true) }
        var plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        state = applySessionToCoach(state, plan, session(fast, voicing: frontier.voicing), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertEqual(state.unitStates[ladder[0].id]?.state, .mastered)
        let medUnit = ladder[1]

        let slow = (0..<6).map { timing(medUnit.keys[$0 % medUnit.keys.count], 4000, true) }
        for _ in 0..<DEFAULT_COACH_PARAMS.demotionAfterHolds {
            plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
            state = applySessionToCoach(state, plan, session(slow, voicing: medUnit.voicing), DEFAULT_COACH_PARAMS, now: 1000)
        }
        XCTAssertEqual(state.unitStates[medUnit.id]?.state, .practicing)
        XCTAssertEqual(state.unitStates[medUnit.id]?.holds, 0)
        XCTAssertEqual(state.unitStates[ladder[0].id]?.state, .practicing)
    }

    // ─── Short-session block mix ────────────────────────────

    func testShortSessionDropsWarmupApply() {
        let state = calibratedState()
        let plan = buildCoachPlan([], profile(dailyGoalMinutes: 5), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let kinds = plan.blocks.map { $0.kind }
        XCTAssertFalse(kinds.contains(.warmup))
        XCTAssertFalse(kinds.contains(.apply))
        XCTAssertTrue(kinds.contains(.focus))
        XCTAssertTrue(kinds.contains(.new))
    }

    func testFullSessionIncludesWarmupApply() {
        let state = calibratedState()
        let plan = buildCoachPlan([], profile(dailyGoalMinutes: 15), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let kinds = plan.blocks.map { $0.kind }
        XCTAssertTrue(kinds.contains(.warmup))
        XCTAssertTrue(kinds.contains(.apply))
    }

    // ─── Calibration ────────────────────────────────────────

    func testUncalibratedGetsSingleCalibrateBlock() {
        let state = createInitialCoachState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        XCTAssertEqual(plan.blocks.count, 1)
        XCTAssertEqual(plan.blocks[0].kind, .calibrate)
        XCTAssertEqual(plan.blocks[0].targetChords, DEFAULT_COACH_PARAMS.calibrationChords)
    }

    func testFastCalibrationSkipsBeginnerUnits() {
        let state = createInitialCoachState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let timings = ["C", "F", "Bb", "Eb"].map { qTiming($0, "Maj7", 1200, true) }
        let next = applySessionToCoach(state, plan, session(timings), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertTrue(next.calibrated)
        let mastered = next.unitStates.values.filter { $0.state == .mastered }
        XCTAssertGreaterThan(mastered.count, 0)
        XCTAssertGreaterThan(next.frontierIndex, 0)
    }

    func testSlowCalibrationStaysAtBottom() {
        let state = createInitialCoachState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let timings = ["C", "F", "Bb", "Eb"].map { qTiming($0, "Maj7", 5000, true) }
        let next = applySessionToCoach(state, plan, session(timings), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertTrue(next.calibrated)
        XCTAssertEqual(next.frontierIndex, 0)
    }

    func testAdaptiveCalibrationBeginnerPlacedAtMaj7() {
        let state = createInitialCoachState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let timings = [qTiming("C", "Maj7", 1000, true), qTiming("F", "Maj7", 1100, true), qTiming("C", "7", 5000, true)]
        let next = applySessionToCoach(state, plan, session(timings, voicing: .root), DEFAULT_COACH_PARAMS, now: 1000)
        let ladder = buildSkillLadder()
        let maj7 = ladder.filter { $0.quality == "Maj7" && $0.voicing == .root }
        let seven = ladder.filter { $0.quality == "7" && $0.voicing == .root }
        XCTAssertTrue(maj7.allSatisfy { next.unitStates[$0.id]?.state == .mastered })
        XCTAssertFalse(seven.contains { next.unitStates[$0.id]?.state == .mastered })
    }

    func testAdaptiveCalibrationProPlacedHighContiguous() {
        let state = createInitialCoachState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let timings = [qTiming("C", "Maj7", 800, true), qTiming("C", "7", 900, true),
                       qTiming("C", "m7", 850, true), qTiming("C", "6", 4000, true)]
        let next = applySessionToCoach(state, plan, session(timings, voicing: .root), DEFAULT_COACH_PARAMS, now: 1000)
        let ladder = buildSkillLadder()
        for q in ["Maj7", "7", "m7"] {
            XCTAssertTrue(ladder.filter { $0.quality == q && $0.voicing == .root }.allSatisfy { next.unitStates[$0.id]?.state == .mastered })
        }
        XCTAssertFalse(ladder.filter { $0.quality == "6" && $0.voicing == .root }.contains { next.unitStates[$0.id]?.state == .mastered })
    }

    func testAdaptiveCalibrationStopsAtFirstShaky() {
        let state = createInitialCoachState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let timings = [qTiming("C", "Maj7", 800, true), qTiming("C", "7", 5000, true), qTiming("C", "m7", 800, true)]
        let next = applySessionToCoach(state, plan, session(timings, voicing: .root), DEFAULT_COACH_PARAMS, now: 1000)
        let ladder = buildSkillLadder()
        XCTAssertFalse(ladder.filter { $0.quality == "m7" && $0.voicing == .root }.contains { next.unitStates[$0.id]?.state == .mastered })
    }

    func testExcellentSessionClimbsAllTiers() {
        let state = calibratedState()
        let ladder = buildSkillLadder()
        let maj7 = ladder.filter { $0.quality == "Maj7" && $0.voicing == .root }
        let allKeys = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
        let timings = allKeys.map { qTiming($0, "Maj7", 700, true) }
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let next = applySessionToCoach(state, plan, session(timings, voicing: .root), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertTrue(maj7.allSatisfy { next.unitStates[$0.id]?.state == .mastered })
    }

    func testMerelyPassingPromotesOneTier() {
        let state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let timings = frontier.keys.map { qTiming($0, "Maj7", 1500, true) }
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let next = applySessionToCoach(state, plan, session(timings, voicing: .root), DEFAULT_COACH_PARAMS, now: 1000)
        let maj7 = ladder.filter { $0.quality == "Maj7" && $0.voicing == .root }
        XCTAssertEqual(maj7.filter { next.unitStates[$0.id]?.state == .mastered }.count, 1)
    }

    // ─── difficultyBias clamp ───────────────────────────────

    func testClampsPositiveAfterManyTooEasy() {
        var state = createInitialCoachState()
        for _ in 0..<20 { state = applyFeedback(state, .tooEasy) }
        XCTAssertEqual(state.difficultyBias, DEFAULT_COACH_PARAMS.feedbackBiasClamp, accuracy: 1e-9)
    }

    func testClampsNegativeAfterManyTooHard() {
        var state = createInitialCoachState()
        for _ in 0..<20 { state = applyFeedback(state, .tooHard) }
        XCTAssertEqual(state.difficultyBias, -DEFAULT_COACH_PARAMS.feedbackBiasClamp, accuracy: 1e-9)
    }

    func testJustRightLeavesBiasUnchanged() {
        var state = createInitialCoachState()
        state.difficultyBias = 0.2
        XCTAssertEqual(applyFeedback(state, .justRight).difficultyBias, 0.2, accuracy: 1e-9)
    }

    func testStrongPositiveBiasRaisesNewBlockDifficulty() {
        var state = calibratedState()
        state.difficultyBias = 0.5
        let plan = buildCoachPlan([], profile(dailyGoalMinutes: 5), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let newBlock = plan.blocks.first { $0.kind == .new }!
        XCTAssertEqual(newBlock.settings.difficulty, .intermediate)
    }

    // ─── correct === undefined handling ─────────────────────

    func testPromotesOnTimingAloneWhenCorrectnessUnknown() {
        let state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let timings = (0..<10).map { timing(frontier.keys[$0 % frontier.keys.count], 1500) }
        XCTAssertTrue(timings.allSatisfy { $0.correct == nil })
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let next = applySessionToCoach(state, plan, session(timings, voicing: frontier.voicing), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertEqual(next.unitStates[frontier.id]?.state, .mastered)
    }

    func testCorrectFalseBlocksGoodAttempt() {
        let state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let timings = (0..<10).map { timing(frontier.keys[$0 % frontier.keys.count], 1500, false) }
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let next = applySessionToCoach(state, plan, session(timings, voicing: frontier.voicing), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertNotEqual(next.unitStates[frontier.id]?.state, .mastered)
    }

    // ─── teacherFeedback ────────────────────────────────────

    func testTeacherFeedbackEmitsPromotedAndNextGoal() {
        var before = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let timings = (0..<10).map { timing(frontier.keys[$0 % frontier.keys.count], 1500, true) }
        let plan = buildCoachPlan([], profile(), nil, before, DEFAULT_COACH_PARAMS, now: 0)
        let s = session(timings, voicing: frontier.voicing)
        let after = applySessionToCoach(before, plan, s, DEFAULT_COACH_PARAMS, now: 1000)
        before.lastPlan = plan
        let fb = teacherFeedback(before, after, s, DEFAULT_COACH_PARAMS)
        XCTAssertTrue(fb.contains { $0.kind == .promoted })
        XCTAssertTrue(fb.contains { $0.kind == .nextGoal })
        for f in fb {
            XCTAssertTrue(f.key.hasPrefix("coach."))
        }
    }

    func testEveryUnitStatementCarriesTier() {
        var before = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let timings = (0..<10).map { timing(frontier.keys[$0 % frontier.keys.count], 1500, true) }
        let plan = buildCoachPlan([], profile(), nil, before, DEFAULT_COACH_PARAMS, now: 0)
        let s = session(timings, voicing: frontier.voicing)
        let after = applySessionToCoach(before, plan, s, DEFAULT_COACH_PARAMS, now: 1000)
        before.lastPlan = plan
        let fb = teacherFeedback(before, after, s, DEFAULT_COACH_PARAMS)
        for f in fb where [.promoted, .placed, .held, .demoted, .nextGoal].contains(f.kind) {
            XCTAssertTrue(["easy", "med", "all"].contains(f.params["tier"] ?? ""))
        }
    }

    func testNoDoubleStatementPerUnit() {
        var before = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let timings = (0..<10).map { timing(frontier.keys[$0 % frontier.keys.count], 1500, true) }
        let plan = buildCoachPlan([], profile(), nil, before, DEFAULT_COACH_PARAMS, now: 0)
        let s = session(timings, voicing: frontier.voicing)
        let after = applySessionToCoach(before, plan, s, DEFAULT_COACH_PARAMS, now: 1000)
        before.lastPlan = plan
        let fb = teacherFeedback(before, after, s, DEFAULT_COACH_PARAMS)
        let unitLines = fb.compactMap { f -> String? in
            guard let tier = f.params["tier"] else { return nil }
            return "\(f.params["quality"] ?? "")|\(f.params["voicing"] ?? "")|\(tier)"
        }
        XCTAssertEqual(Set(unitLines).count, unitLines.count)
    }

    // ─── Bug 1: promotion bounded to the trained frontier unit ──

    func testGoodEasySessionDoesNotMasterMedAndAll() {
        let state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let medUnit = ladder[1]
        let allUnit = ladder[2]
        let allKeys = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
        let timings = (allKeys + allKeys).map { timing($0, 1400, true) }
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let next = applySessionToCoach(state, plan, session(timings, voicing: frontier.voicing), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertEqual(next.unitStates[frontier.id]?.state, .mastered)
        XCTAssertNotEqual(next.unitStates[medUnit.id]?.state, .mastered)
        XCTAssertNotEqual(next.unitStates[allUnit.id]?.state, .mastered)
    }

    func testNonFrontierVoicingDoesNotPromoteFrontier() {
        let state = calibratedState()
        let ladder = buildSkillLadder()
        let frontier = ladder[0]
        let otherVoicing: VoicingType = frontier.voicing == .shell ? .root : .shell
        let timings = (0..<10).map { timing(frontier.keys[$0 % frontier.keys.count], 1400, true) }
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let next = applySessionToCoach(state, plan, session(timings, voicing: otherVoicing), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertNotEqual(next.unitStates[frontier.id]?.state, .mastered)
        XCTAssertEqual(next.frontierIndex, 0)
    }

    func testCalibrationOnlyPlacesTestedVoicing() {
        let state = createInitialCoachState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let timings = ["C", "F", "Bb", "Eb"].map { qTiming($0, "Maj7", 1000, true) }
        let next = applySessionToCoach(state, plan, session(timings), DEFAULT_COACH_PARAMS, now: 1000)
        let ladder = buildSkillLadder()
        for (id, prog) in next.unitStates where prog.state == .mastered {
            let unit = ladder.first { $0.id == id }
            XCTAssertEqual(unit?.voicing, .root)
        }
    }

    func testMultiBlockSessionAdvancesAtMostOneTier() {
        var state = calibratedState()
        let before = state.unitStates.values.filter { $0.state == .mastered }.count
        let plan = buildCoachPlan([], profile(dailyGoalMinutes: 20), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let allKeys = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
        for block in plan.blocks {
            let roots = (0..<block.targetChords).map { allKeys[$0 % 12] }
            let bs = session(roots.map { timing($0, 1400, true) }, voicing: block.settings.voicing)
            state = applySessionToCoach(state, plan, bs, DEFAULT_COACH_PARAMS, now: 1000)
        }
        let after = state.unitStates.values.filter { $0.state == .mastered }.count
        XCTAssertLessThanOrEqual(after - before, 1)
    }

    // ─── Ear facet — one skill map, two senses ──────────────

    func testEarFocusPointsAtTheQualityThePianoSideIsTeaching() {
        let state = calibratedState()
        let focus = earFocus(state)!
        let ladder = buildSkillLadder()
        XCTAssertEqual(focus.unitId, ladder[0].id)
        XCTAssertEqual(focus.quality, ladder[0].quality)
    }

    func testHearingAUnitReliablyMastersItsEarFacetOnly() {
        let state = calibratedState()
        let id = buildSkillLadder()[0].id
        let next = applyEarTallies(state, [EarTally(unitId: id, attempts: 5, correct: 5)],
                                   DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertTrue(isEarMastered(next, id))
        // The piano side is untouched — you still have to play it.
        XCTAssertNotEqual(next.unitStates[id]?.state, .mastered)
    }

    func testEarDoesNotMasterOnTooFewAttempts() {
        let state = calibratedState()
        let id = buildSkillLadder()[0].id
        let next = applyEarTallies(state, [EarTally(unitId: id, attempts: 2, correct: 2)],
                                   DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertFalse(isEarMastered(next, id))
    }

    func testEarKnocksMasteredUnitBackWhenItSlips() {
        let state = calibratedState()
        let id = buildSkillLadder()[0].id
        var next = applyEarTallies(state, [EarTally(unitId: id, attempts: 5, correct: 5)],
                                   DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertTrue(isEarMastered(next, id))
        next = applyEarTallies(next, [EarTally(unitId: id, attempts: 4, correct: 1)],
                               DEFAULT_COACH_PARAMS, now: 2000)
        XCTAssertFalse(isEarMastered(next, id))
    }

    func testTalliesOnlyResultsThatCarryAUnitId() {
        let tallies = tallyEarResults([
            (unitId: "a", correct: true),
            (unitId: "a", correct: false),
            (unitId: nil, correct: true), // an interval drill — not tied to a unit
        ])
        XCTAssertEqual(tallies, [EarTally(unitId: "a", attempts: 2, correct: 1)])
    }

    func testReportsBothFacetsForTheProgressDisplay() {
        var state = calibratedState()
        let ladder = buildSkillLadder()
        let id = ladder[0].id
        state.unitStates[id] = UnitProgress(state: .mastered, holds: 0)
        let withEar = applyEarTallies(state, [EarTally(unitId: id, attempts: 5, correct: 5)],
                                      DEFAULT_COACH_PARAMS, now: 1)
        let p = skillMapProgress(withEar)
        XCTAssertEqual(p.total, ladder.count)
        XCTAssertEqual(p.handsMastered, 1)
        XCTAssertEqual(p.earMastered, 1)
        XCTAssertEqual(p.bothMastered, 1)
    }
}
