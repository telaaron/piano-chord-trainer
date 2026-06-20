// Tests for the larger engine modules (progressions, voice-leading, custom
// progressions, habits, courses). Mirror the web behavior; guard the port.

import XCTest
@testable import MusicEngine

final class ProgressionsTests: XCTestCase {

    func testTwoFiveOneDegrees() {
        XCTAssertEqual(MODE_DEGREE_MAP[.twoFiveOne], [1, 4, 0])
    }

    func testGenerateTwoFiveOneProducesAllKeys() {
        // 3 chords (ii-V-I) × 12 keys = 36 chords
        let result = generateProgression(.twoFiveOne, .both, .standard, 0, nil)
        XCTAssertEqual(result.chords.count, 36)
        // First key (C in cycle-of-4ths order = C): Dm7 G7 CMaj7
        XCTAssertEqual(result.chords[0].display, "Dm7")
        XCTAssertEqual(result.chords[1].display, "G7")
        XCTAssertEqual(result.chords[2].display, "CMaj7")
    }

    func testCycleOf4thsTwelveDominants() {
        let result = generateProgression(.cycleOf4ths, .flats, .standard, 0, nil)
        XCTAssertEqual(result.chords.count, 12)
        XCTAssertEqual(result.chords[0].display, "C7")
        XCTAssertEqual(result.chords[1].display, "F7")
        XCTAssertEqual(result.chords[2].display, "Bb7")
    }

    func testParseCustomDegreesClamps() {
        // 1-based → 0-based, clamped to 0...6
        XCTAssertEqual(parseCustomDegrees([2, 5, 1]), [1, 4, 0])
        XCTAssertEqual(parseCustomDegrees([0, 9]), [0, 6])
    }

    func testDegreesToLabel() {
        XCTAssertEqual(degreesToLabel([1, 4, 0]), "ii – V – I")
    }
}

final class VoiceLeadingTests: XCTestCase {

    func testAnalyzeCommonTone() {
        // F stays between Dm7 shell [D,F,C] and a voicing that keeps F at the same position
        let info = analyzeVoiceLeading(["D", "F", "C"], ["D", "F", "C"])
        XCTAssertEqual(info.totalMovement, 0)
        XCTAssertEqual(info.commonTones, ["D", "F", "C"])
    }

    func testComputeVoiceLeadVoicingPicksTighterRotation() {
        // G7 shell [G,B,F] → Dm7 shell base [D,F,C]; rotation [F,C,D] is tighter.
        let result = computeVoiceLeadVoicing(["G", "B", "F"], ["D", "F", "C"])
        XCTAssertEqual(result, ["F", "C", "D"])
    }

    func testValidateFindInversionWrongNotes() {
        let r = validateFindInversion([60, 64, 67], ["D", "F", "C"], ["G", "B", "F"], ["F", "C", "D"])
        XCTAssertFalse(r.valid)
        XCTAssertEqual(r.grade, .wrong)
    }

    func testGetAllRotations() {
        XCTAssertEqual(getAllRotations(["D", "F", "C"]), [["D", "F", "C"], ["F", "C", "D"], ["C", "D", "F"]])
    }
}

final class CustomProgressionsTests: XCTestCase {

    func testParseChordSymbol() {
        XCTAssertEqual(parseChordSymbol("Dm7")?.quality, "m7")
        XCTAssertEqual(parseChordSymbol("Dm7")?.root, "D")
        XCTAssertEqual(parseChordSymbol("BbMaj7")?.root, "Bb")
        XCTAssertEqual(parseChordSymbol("F#7")?.root, "F#")
        XCTAssertNil(parseChordSymbol("C"))      // bare triad not in system
        XCTAssertNil(parseChordSymbol("Xyz"))
    }

    func testParseProgressionWithSeparatorsAndBeats() {
        let chords = parseProgression("Dm7 | G7 | CMaj7")
        XCTAssertEqual(chords.count, 3)
        XCTAssertEqual(chords.map { $0.display }, ["Dm7", "G7", "CMaj7"])
        XCTAssertEqual(chords[0].beats, 4)

        let withBeats = parseProgression("Dm7(2) | G7(2)")
        XCTAssertEqual(withBeats[0].beats, 2)
        XCTAssertEqual(withBeats[1].beats, 2)
    }

    func testPresetsParse() {
        // Every preset must parse into a non-empty chord list.
        for preset in PROGRESSION_PRESETS {
            XCTAssertFalse(parseProgression(preset.raw).isEmpty, "\(preset.name) failed to parse")
        }
    }

    func testEvaluateSession() {
        let chord = CustomChord(display: "Dm7", root: "D", quality: "m7", beats: 4)
        let loop = LoopEvaluation(chords: [
            ChordEval(chord: chord, hit: true, timingOffsetMs: 50, bestAccuracy: 1),
            ChordEval(chord: chord, hit: false, timingOffsetMs: 0, bestAccuracy: 0),
        ], accuracy: 0.5)
        let eval = evaluateSession([loop], 5000)
        XCTAssertEqual(eval.overallAccuracy, 0.5)
    }
}

final class HabitsTests: XCTestCase {

    func testCalculateLevel() {
        XCTAssertEqual(calculateLevel(0), 1)
        XCTAssertEqual(calculateLevel(50), 1)   // floor(sqrt(1)) = 1
        XCTAssertEqual(calculateLevel(200), 2)  // floor(sqrt(4)) = 2
        XCTAssertEqual(calculateLevel(450), 3)  // floor(sqrt(9)) = 3
    }

    func testXpForLevel() {
        XCTAssertEqual(xpForLevel(2), 200)
        XCTAssertEqual(xpForLevel(3), 450)
    }

    func testStreakMultiplier() {
        XCTAssertEqual(getStreakMultiplier(1), 1.0)
        XCTAssertEqual(getStreakMultiplier(8), 1.25)
        XCTAssertEqual(getStreakMultiplier(15), 1.5)
        XCTAssertEqual(getStreakMultiplier(31), 2.0)
    }

    func testTimingToQuality() {
        XCTAssertEqual(timingToQuality(400, 1000), 5)
        XCTAssertEqual(timingToQuality(900, 1000), 3)
        XCTAssertEqual(timingToQuality(3000, 1000), 0)
    }

    func testDefaultProfileLevelInfo() {
        let p = createDefaultProfile()
        XCTAssertEqual(p.dailyGoalMinutes, 5)
        let info = getLevelInfo(p.totalXP)
        XCTAssertEqual(info.level, 1)
    }
}

final class CoursesTests: XCTestCase {

    func testFourCourses() {
        XCTAssertEqual(ALL_COURSES.count, 4)
    }

    func testGetCourseAndLesson() {
        XCTAssertNotNil(getCourse("shell-voicings"))
        let lookup = getLesson("shell-voicings", "maj7")
        XCTAssertNotNil(lookup)
        XCTAssertEqual(lookup?.lesson.steps.count, 3)
    }

    func testCreateCourseProgressMastery() {
        let course = getCourse("shell-voicings")!
        let progress = createCourseProgress(course, now: 0)
        XCTAssertEqual(courseCompletionPercent(progress), 0)
        XCTAssertEqual(progress.modules.count, course.modules.count)
    }

    func testUltimatePlanHasEightModules() {
        XCTAssertEqual(getCourse("ultimate-plan")?.modules.count, 8)
    }

    func testIntervalCourseTargetsSpelledCorrectly() {
        // intervals course builds targets via getNoteName(flats) — verify a known one.
        let course = getCourse("intervals")!
        let firstLesson = course.modules[0].lessons[0]
        if case let .theory(theory) = firstLesson.steps[0] {
            XCTAssertEqual(theory.exampleInterval?.target, "E") // C + 4 semis
        } else {
            XCTFail("expected theory step")
        }
    }
}
