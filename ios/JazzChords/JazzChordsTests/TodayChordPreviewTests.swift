import XCTest
import MusicEngine
@testable import JazzChords

final class TodayChordPreviewTests: XCTestCase {
    private func settings(_ mode: ProgressionMode) -> PracticePlanSettings {
        PracticePlanSettings(difficulty: .beginner, notation: .standard, voicing: .shell,
                             displayMode: .always, accidentals: .flats,
                             progressionMode: mode, totalChords: 12)
    }

    private func plan(_ blocks: [CoachBlock]) -> CoachPlan {
        CoachPlan(blocks: blocks, sayKey: "x", sayParams: [:], estMinutes: 5)
    }

    func testFocusBlockYieldsItsChord() {
        let block = CoachBlock(kind: .focus, settings: settings(.random), focusRoots: ["Bb"],
                               focusQualities: ["Maj7"], targetChords: 8, labelKey: "x")
        let chords = TodayChordPreview.chords(for: plan([block]))
        XCTAssertEqual(chords.count, 1)
        XCTAssertEqual(chords.first?.root, "Bb")
        XCTAssertFalse(chords.first?.voicing.isEmpty ?? true)
    }

    func testProgressionBlockYieldsThreeChords() {
        let block = CoachBlock(kind: .focus, settings: settings(.twoFiveOne), targetChords: 8, labelKey: "x")
        XCTAssertEqual(TodayChordPreview.chords(for: plan([block])).count, 3)
    }

    func testPrefersFocusOverWarmup() {
        let warmup = CoachBlock(kind: .warmup, settings: settings(.random), focusRoots: ["C"],
                                focusQualities: ["7"], targetChords: 4, labelKey: "x")
        let focus = CoachBlock(kind: .new, settings: settings(.random), focusRoots: ["D"],
                               focusQualities: ["m7"], targetChords: 4, labelKey: "x")
        XCTAssertEqual(TodayChordPreview.chords(for: plan([warmup, focus])).first?.root, "D")
    }

    func testEmptyPlanYieldsNothing() {
        XCTAssertTrue(TodayChordPreview.chords(for: plan([])).isEmpty)
    }

    func testRandomBlockWithoutQualitiesYieldsNothing() {
        let block = CoachBlock(kind: .focus, settings: settings(.random), targetChords: 8, labelKey: "x")
        XCTAssertTrue(TodayChordPreview.chords(for: plan([block])).isEmpty)
    }

    // Arrows on Heute promise a sequence; only progression blocks are one.
    func testProgressionIsSequenceFocusIsNot() {
        let progression = CoachBlock(kind: .focus, settings: settings(.twoFiveOne), targetChords: 8, labelKey: "x")
        let focus = CoachBlock(kind: .focus, settings: settings(.random), focusRoots: ["C"],
                               focusQualities: ["Maj7", "7"], targetChords: 8, labelKey: "x")
        XCTAssertTrue(TodayChordPreview.isSequence(for: plan([progression])))
        XCTAssertFalse(TodayChordPreview.isSequence(for: plan([focus])))
    }

    // A calibration block has no roots: chords come in random keys, so the row
    // shows qualities only, not three times C.
    func testBlockWithoutRootsIsAnyKey() {
        let calibrate = CoachBlock(kind: .calibrate, settings: settings(.random),
                                   focusQualities: ["Maj7", "7", "m7"], targetChords: 12, labelKey: "x")
        let focus = CoachBlock(kind: .focus, settings: settings(.random), focusRoots: ["D"],
                               focusQualities: ["m7"], targetChords: 8, labelKey: "x")
        XCTAssertTrue(TodayChordPreview.isAnyKey(for: plan([calibrate])))
        XCTAssertFalse(TodayChordPreview.isAnyKey(for: plan([focus])))
    }
}
