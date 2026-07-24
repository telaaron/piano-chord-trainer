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
        let keys = ["C", "F", "Bb", "Eb"]
        let timings = (0..<12).map { timing(keys[$0 % 4], 1200, true) }
        let next = applySessionToCoach(state, plan, session(timings), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertTrue(next.calibrated)
        let mastered = next.unitStates.values.filter { $0.state == .mastered }
        XCTAssertGreaterThan(mastered.count, 0)
        XCTAssertGreaterThan(next.frontierIndex, 0)
    }

    func testSlowCalibrationStaysAtBottom() {
        let state = createInitialCoachState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let keys = ["C", "F", "Bb", "Eb"]
        let timings = (0..<12).map { timing(keys[$0 % 4], 5000, true) }
        let next = applySessionToCoach(state, plan, session(timings), DEFAULT_COACH_PARAMS, now: 1000)
        XCTAssertTrue(next.calibrated)
        XCTAssertEqual(next.frontierIndex, 0)
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

    func testFastCalibrationMastersOnlyEasyTier() {
        let state = createInitialCoachState()
        let plan = buildCoachPlan([], profile(), nil, state, DEFAULT_COACH_PARAMS, now: 0)
        let timings = (0..<12).map { timing(["C", "F", "Bb", "Eb"][$0 % 4], 1200, true) }
        let next = applySessionToCoach(state, plan, session(timings), DEFAULT_COACH_PARAMS, now: 1000)
        let ladder = buildSkillLadder()
        for (id, prog) in next.unitStates where prog.state == .mastered {
            let unit = ladder.first { $0.id == id }
            XCTAssertEqual(unit?.keyTier, .easy)
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
}
