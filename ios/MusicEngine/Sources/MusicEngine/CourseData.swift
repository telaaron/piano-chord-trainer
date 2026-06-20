// Course content data — ports of src/lib/courses/{shell-voicings,intervals,scale-degrees,ultimate-plan}.ts.

import Foundation

private let ALL_KEYS = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
private let EASY_KEYS_3 = ["C", "F", "Bb"]
private let EASY_KEYS_4 = ["C", "F", "Bb", "Eb"]
private let MEDIUM_KEYS = ["C", "F", "Bb", "Eb", "Ab", "G", "D"]

/// Standard 3-step lesson (theory → practice → challenge) for a chord.
private func makeChordLesson(
    _ id: String, _ titleKey: String, _ subtitleKey: String,
    quality: String, voicing: VoicingType, exampleRoot: String,
    practiceKeys: [String], challengeKeys: [String], masteryMs: Int = 3000,
    contentKey: String? = nil
) -> Lesson {
    Lesson(id: id, titleKey: titleKey, subtitleKey: subtitleKey, steps: [
        .theory(TheoryStep(contentKey: contentKey ?? "course.ultimate.\(id).theory",
                           exampleChord: ChordSpec(root: exampleRoot, quality: quality, voicing: voicing))),
        .practice(PracticeStep(chordPool: practiceKeys.map { ChordSpec(root: $0, quality: quality, voicing: voicing) }, guidedCount: 3)),
        .challenge(ChallengeStep(voicing: voicing, quality: quality, keys: challengeKeys, masteryThresholdMs: masteryMs)),
    ])
}

/// Build an interval pool: for each root, { root, target, label, semitones }.
private func ivPool(_ roots: [String], _ semitones: Int, _ label: String) -> [IntervalSpec] {
    roots.map { root in
        let rootSt = noteToSemitone(root)
        let target = getNoteName(rootSt, semitones, .flats)
        return IntervalSpec(root: root, target: target, label: label, semitones: semitones)
    }
}

// ─── Shell Voicings ─────────────────────────────────────────

public let shellVoicingsCourse = Course(
    id: "shell-voicings", titleKey: "course.shell.title", descriptionKey: "course.shell.description",
    subtitleKey: "course.shell.subtitle", icon: "🎹", level: .beginner,
    modules: [
        CourseModule(id: "basics", titleKey: "course.shell.mod1.title", lessons: [
            makeChordLesson("maj7", "course.shell.maj7.title", "course.shell.maj7.subtitle",
                quality: "Maj7", voicing: .shell, exampleRoot: "C", practiceKeys: EASY_KEYS_3, challengeKeys: ALL_KEYS,
                contentKey: "course.shell.maj7.theory"),
            makeChordLesson("dom7", "course.shell.dom7.title", "course.shell.dom7.subtitle",
                quality: "7", voicing: .shell, exampleRoot: "C", practiceKeys: EASY_KEYS_3, challengeKeys: ALL_KEYS,
                contentKey: "course.shell.dom7.theory"),
            makeChordLesson("m7", "course.shell.m7.title", "course.shell.m7.subtitle",
                quality: "m7", voicing: .shell, exampleRoot: "C", practiceKeys: EASY_KEYS_3, challengeKeys: ALL_KEYS,
                contentKey: "course.shell.m7.theory"),
        ]),
    ])

// ─── Intervals ──────────────────────────────────────────────

private func makeIntervalLesson(
    _ id: String, _ titleKey: String, _ subtitleKey: String, contentKey: String,
    example: IntervalSpec, practicePool: [IntervalSpec], guidedCount: Int,
    challengeQuality: String, masteryMs: Int, intervalSemitones: Int, intervalLabel: String
) -> Lesson {
    Lesson(id: id, titleKey: titleKey, subtitleKey: subtitleKey, steps: [
        .theory(TheoryStep(contentKey: contentKey, exampleInterval: example)),
        .practice(PracticeStep(intervalPool: practicePool, guidedCount: guidedCount)),
        .challenge(ChallengeStep(voicing: .root, quality: challengeQuality, keys: ALL_KEYS,
            masteryThresholdMs: masteryMs, intervalSemitones: intervalSemitones, intervalLabel: intervalLabel)),
    ])
}

public let intervalsCourse = Course(
    id: "intervals", titleKey: "course.intervals.title", descriptionKey: "course.intervals.description",
    subtitleKey: "course.intervals.subtitle", icon: "📏", level: .beginner,
    modules: [
        CourseModule(id: "seconds-thirds", titleKey: "course.intervals.mod1.title", lessons: [
            makeIntervalLesson("major-minor-3rd", "course.intervals.major_minor_3rd.title", "course.intervals.major_minor_3rd.subtitle",
                contentKey: "course.intervals.major_minor_3rd.theory",
                example: IntervalSpec(root: "C", target: "E", label: "Maj 3rd", semitones: 4),
                practicePool: ivPool(EASY_KEYS_4, 4, "Maj 3rd") + ivPool(EASY_KEYS_4, 3, "min 3rd"),
                guidedCount: 4, challengeQuality: "Maj7", masteryMs: 4000, intervalSemitones: 4, intervalLabel: "Maj 3rd"),
            makeIntervalLesson("tritone", "course.intervals.tritone.title", "course.intervals.tritone.subtitle",
                contentKey: "course.intervals.tritone.theory",
                example: IntervalSpec(root: "B", target: "F", label: "Tritone", semitones: 6),
                practicePool: ivPool(EASY_KEYS_4, 6, "Tritone"),
                guidedCount: 3, challengeQuality: "7", masteryMs: 4000, intervalSemitones: 6, intervalLabel: "Tritone"),
        ]),
        CourseModule(id: "fifths-sixths", titleKey: "course.intervals.mod2.title", lessons: [
            makeIntervalLesson("perfect-5th", "course.intervals.perfect_5th.title", "course.intervals.perfect_5th.subtitle",
                contentKey: "course.intervals.perfect_5th.theory",
                example: IntervalSpec(root: "C", target: "G", label: "P5", semitones: 7),
                practicePool: ivPool(EASY_KEYS_4, 7, "P5"),
                guidedCount: 3, challengeQuality: "Maj7", masteryMs: 4000, intervalSemitones: 7, intervalLabel: "P5"),
            makeIntervalLesson("dim5-aug5", "course.intervals.dim5_aug5.title", "course.intervals.dim5_aug5.subtitle",
                contentKey: "course.intervals.dim5_aug5.theory",
                example: IntervalSpec(root: "C", target: "Gb", label: "♭5", semitones: 6),
                practicePool: ivPool(EASY_KEYS_4, 6, "♭5") + ivPool(EASY_KEYS_4, 8, "#5"),
                guidedCount: 3, challengeQuality: "m7b5", masteryMs: 4500, intervalSemitones: 6, intervalLabel: "♭5"),
            makeIntervalLesson("major-6th", "course.intervals.major_6th.title", "course.intervals.major_6th.subtitle",
                contentKey: "course.intervals.major_6th.theory",
                example: IntervalSpec(root: "C", target: "A", label: "Maj 6th", semitones: 9),
                practicePool: ivPool(EASY_KEYS_4, 9, "Maj 6th"),
                guidedCount: 3, challengeQuality: "6", masteryMs: 4000, intervalSemitones: 9, intervalLabel: "Maj 6th"),
        ]),
        CourseModule(id: "sevenths", titleKey: "course.intervals.mod3.title", lessons: [
            makeIntervalLesson("minor-7th", "course.intervals.minor_7th.title", "course.intervals.minor_7th.subtitle",
                contentKey: "course.intervals.minor_7th.theory",
                example: IntervalSpec(root: "C", target: "Bb", label: "♭7", semitones: 10),
                practicePool: ivPool(EASY_KEYS_4, 10, "♭7"),
                guidedCount: 3, challengeQuality: "7", masteryMs: 4000, intervalSemitones: 10, intervalLabel: "♭7"),
            makeIntervalLesson("major-7th", "course.intervals.major_7th.title", "course.intervals.major_7th.subtitle",
                contentKey: "course.intervals.major_7th.theory",
                example: IntervalSpec(root: "C", target: "B", label: "Maj 7th", semitones: 11),
                practicePool: ivPool(EASY_KEYS_4, 11, "Maj 7th"),
                guidedCount: 3, challengeQuality: "Maj7", masteryMs: 3500, intervalSemitones: 11, intervalLabel: "Maj 7th"),
        ]),
        CourseModule(id: "extended", titleKey: "course.intervals.mod4.title", lessons: [
            makeIntervalLesson("ninths", "course.intervals.ninths.title", "course.intervals.ninths.subtitle",
                contentKey: "course.intervals.ninths.theory",
                example: IntervalSpec(root: "C", target: "D", label: "Maj 9th", semitones: 14),
                practicePool: ivPool(EASY_KEYS_4, 2, "9th"),
                guidedCount: 3, challengeQuality: "9", masteryMs: 4500, intervalSemitones: 2, intervalLabel: "9th"),
            makeIntervalLesson("elevenths-thirteenths", "course.intervals.elevenths.title", "course.intervals.elevenths.subtitle",
                contentKey: "course.intervals.elevenths.theory",
                example: IntervalSpec(root: "C", target: "F", label: "11th", semitones: 17),
                practicePool: ivPool(EASY_KEYS_4, 5, "11th") + ivPool(EASY_KEYS_4, 9, "13th"),
                guidedCount: 3, challengeQuality: "13", masteryMs: 4500, intervalSemitones: 5, intervalLabel: "11th"),
        ]),
    ])

// ─── Scale Degrees ──────────────────────────────────────────

private func makeDegreeLesson(
    _ id: String, _ titleKey: String, _ subtitleKey: String, contentKey: String,
    exampleRoot: String, quality: String, practiceQualities: [(String, [String])]? = nil,
    challengeQuality: String, challengeKeys: [String], guidedCount: Int = 3, masteryMs: Int = 3500
) -> Lesson {
    let practice: [ChordSpec]
    if let practiceQualities {
        practice = practiceQualities.flatMap { (q, keys) in keys.map { ChordSpec(root: $0, quality: q, voicing: .shell) } }
    } else {
        practice = EASY_KEYS_4.map { ChordSpec(root: $0, quality: quality, voicing: .shell) }
    }
    return Lesson(id: id, titleKey: titleKey, subtitleKey: subtitleKey, steps: [
        .theory(TheoryStep(contentKey: contentKey, exampleChord: ChordSpec(root: exampleRoot, quality: quality, voicing: .shell))),
        .practice(PracticeStep(chordPool: practice, guidedCount: guidedCount)),
        .challenge(ChallengeStep(voicing: .shell, quality: challengeQuality, keys: challengeKeys, masteryThresholdMs: masteryMs)),
    ])
}

public let scaleDegreesCourse = Course(
    id: "scale-degrees", titleKey: "course.degrees.title", descriptionKey: "course.degrees.description",
    subtitleKey: "course.degrees.subtitle", icon: "Ⅱ", level: .intermediate,
    modules: [
        CourseModule(id: "tonic-family", titleKey: "course.degrees.mod1.title", lessons: [
            makeDegreeLesson("I-maj7", "course.degrees.I_maj7.title", "course.degrees.I_maj7.subtitle", contentKey: "course.degrees.I_maj7.theory",
                exampleRoot: "C", quality: "Maj7", challengeQuality: "Maj7", challengeKeys: MEDIUM_KEYS),
            makeDegreeLesson("vi-m7", "course.degrees.vi_m7.title", "course.degrees.vi_m7.subtitle", contentKey: "course.degrees.vi_m7.theory",
                exampleRoot: "A", quality: "m7", challengeQuality: "m7", challengeKeys: MEDIUM_KEYS),
            makeDegreeLesson("iii-m7", "course.degrees.iii_m7.title", "course.degrees.iii_m7.subtitle", contentKey: "course.degrees.iii_m7.theory",
                exampleRoot: "E", quality: "m7", challengeQuality: "m7", challengeKeys: MEDIUM_KEYS),
        ]),
        CourseModule(id: "subdominant-family", titleKey: "course.degrees.mod2.title", lessons: [
            makeDegreeLesson("IV-maj7", "course.degrees.IV_maj7.title", "course.degrees.IV_maj7.subtitle", contentKey: "course.degrees.IV_maj7.theory",
                exampleRoot: "F", quality: "Maj7", challengeQuality: "Maj7", challengeKeys: MEDIUM_KEYS),
            makeDegreeLesson("ii-m7", "course.degrees.ii_m7.title", "course.degrees.ii_m7.subtitle", contentKey: "course.degrees.ii_m7.theory",
                exampleRoot: "D", quality: "m7", challengeQuality: "m7", challengeKeys: MEDIUM_KEYS),
        ]),
        CourseModule(id: "dominant-family", titleKey: "course.degrees.mod3.title", lessons: [
            makeDegreeLesson("V-7", "course.degrees.V_7.title", "course.degrees.V_7.subtitle", contentKey: "course.degrees.V_7.theory",
                exampleRoot: "G", quality: "7", challengeQuality: "7", challengeKeys: MEDIUM_KEYS),
            makeDegreeLesson("vii-m7b5", "course.degrees.vii_m7b5.title", "course.degrees.vii_m7b5.subtitle", contentKey: "course.degrees.vii_m7b5.theory",
                exampleRoot: "B", quality: "m7b5", challengeQuality: "m7b5", challengeKeys: MEDIUM_KEYS, masteryMs: 4000),
        ]),
        CourseModule(id: "progressions", titleKey: "course.degrees.mod4.title", lessons: [
            makeDegreeLesson("ii-V-I", "course.degrees.iiVI.title", "course.degrees.iiVI.subtitle", contentKey: "course.degrees.iiVI.theory",
                exampleRoot: "D", quality: "m7",
                practiceQualities: [("m7", EASY_KEYS_4), ("7", EASY_KEYS_4), ("Maj7", EASY_KEYS_4)],
                challengeQuality: "m7", challengeKeys: ALL_KEYS, guidedCount: 4),
            makeDegreeLesson("turnaround", "course.degrees.turnaround.title", "course.degrees.turnaround.subtitle", contentKey: "course.degrees.turnaround.theory",
                exampleRoot: "C", quality: "Maj7",
                practiceQualities: [("Maj7", EASY_KEYS_4), ("m7", EASY_KEYS_4), ("7", EASY_KEYS_4)],
                challengeQuality: "Maj7", challengeKeys: ALL_KEYS, guidedCount: 4),
        ]),
    ])

// ─── Ultimate Plan ──────────────────────────────────────────

public let ultimatePlanCourse = Course(
    id: "ultimate-plan", titleKey: "course.ultimate.title", descriptionKey: "course.ultimate.description",
    subtitleKey: "course.ultimate.subtitle", icon: "🚀", level: .beginner,
    modules: [
        CourseModule(id: "fundamentals", titleKey: "course.ultimate.mod1.title", lessons: [
            makeChordLesson("fund-maj7", "course.ultimate.fund-maj7.title", "course.ultimate.fund-maj7.subtitle", quality: "Maj7", voicing: .root, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 4000),
            makeChordLesson("fund-dom7", "course.ultimate.fund-dom7.title", "course.ultimate.fund-dom7.subtitle", quality: "7", voicing: .root, exampleRoot: "G", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 4000),
            makeChordLesson("fund-m7", "course.ultimate.fund-m7.title", "course.ultimate.fund-m7.subtitle", quality: "m7", voicing: .root, exampleRoot: "D", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 4000),
        ]),
        CourseModule(id: "shells", titleKey: "course.ultimate.mod2.title", lessons: [
            makeChordLesson("shell-maj7", "course.ultimate.shell-maj7.title", "course.ultimate.shell-maj7.subtitle", quality: "Maj7", voicing: .shell, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS),
            makeChordLesson("shell-dom7", "course.ultimate.shell-dom7.title", "course.ultimate.shell-dom7.subtitle", quality: "7", voicing: .shell, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS),
            makeChordLesson("shell-m7", "course.ultimate.shell-m7.title", "course.ultimate.shell-m7.subtitle", quality: "m7", voicing: .shell, exampleRoot: "D", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS),
        ]),
        CourseModule(id: "sixths", titleKey: "course.ultimate.mod3.title", lessons: [
            makeChordLesson("sixth-6", "course.ultimate.sixth-6.title", "course.ultimate.sixth-6.subtitle", quality: "6", voicing: .root, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("sixth-m6", "course.ultimate.sixth-m6.title", "course.ultimate.sixth-m6.subtitle", quality: "m6", voicing: .root, exampleRoot: "A", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("sixth-m7b5", "course.ultimate.sixth-m7b5.title", "course.ultimate.sixth-m7b5.subtitle", quality: "m7b5", voicing: .root, exampleRoot: "B", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("sixth-dim7", "course.ultimate.sixth-dim7.title", "course.ultimate.sixth-dim7.subtitle", quality: "dim7", voicing: .root, exampleRoot: "B", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
        ]),
        CourseModule(id: "ninths", titleKey: "course.ultimate.mod4.title", lessons: [
            makeChordLesson("ninth-maj9", "course.ultimate.ninth-maj9.title", "course.ultimate.ninth-maj9.subtitle", quality: "Maj9", voicing: .root, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("ninth-9", "course.ultimate.ninth-9.title", "course.ultimate.ninth-9.subtitle", quality: "9", voicing: .root, exampleRoot: "G", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("ninth-m9", "course.ultimate.ninth-m9.title", "course.ultimate.ninth-m9.subtitle", quality: "m9", voicing: .root, exampleRoot: "D", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("ninth-69", "course.ultimate.ninth-69.title", "course.ultimate.ninth-69.subtitle", quality: "6/9", voicing: .root, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
        ]),
        CourseModule(id: "full-voicings", titleKey: "course.ultimate.mod5.title", lessons: [
            makeChordLesson("full-maj7", "course.ultimate.full-maj7.title", "course.ultimate.full-maj7.subtitle", quality: "Maj7", voicing: .full, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS),
            makeChordLesson("full-dom7", "course.ultimate.full-dom7.title", "course.ultimate.full-dom7.subtitle", quality: "7", voicing: .full, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS),
            makeChordLesson("full-m7", "course.ultimate.full-m7.title", "course.ultimate.full-m7.subtitle", quality: "m7", voicing: .full, exampleRoot: "D", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS),
            makeChordLesson("hshell-maj7", "course.ultimate.hshell-maj7.title", "course.ultimate.hshell-maj7.subtitle", quality: "Maj7", voicing: .halfShell, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS),
        ]),
        CourseModule(id: "rootless", titleKey: "course.ultimate.mod6.title", lessons: [
            makeChordLesson("rla-maj7", "course.ultimate.rla-maj7.title", "course.ultimate.rla-maj7.subtitle", quality: "Maj7", voicing: .rootlessA, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("rla-dom7", "course.ultimate.rla-dom7.title", "course.ultimate.rla-dom7.subtitle", quality: "7", voicing: .rootlessA, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("rla-m7", "course.ultimate.rla-m7.title", "course.ultimate.rla-m7.subtitle", quality: "m7", voicing: .rootlessA, exampleRoot: "D", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("rlb-maj7", "course.ultimate.rlb-maj7.title", "course.ultimate.rlb-maj7.subtitle", quality: "Maj7", voicing: .rootlessB, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("rlb-dom7", "course.ultimate.rlb-dom7.title", "course.ultimate.rlb-dom7.subtitle", quality: "7", voicing: .rootlessB, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("rlb-m7", "course.ultimate.rlb-m7.title", "course.ultimate.rlb-m7.subtitle", quality: "m7", voicing: .rootlessB, exampleRoot: "D", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
        ]),
        CourseModule(id: "inversions", titleKey: "course.ultimate.mod7.title", lessons: [
            makeChordLesson("inv1-maj7", "course.ultimate.inv1-maj7.title", "course.ultimate.inv1-maj7.subtitle", quality: "Maj7", voicing: .inversion1, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("inv2-maj7", "course.ultimate.inv2-maj7.title", "course.ultimate.inv2-maj7.subtitle", quality: "Maj7", voicing: .inversion2, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
            makeChordLesson("inv3-maj7", "course.ultimate.inv3-maj7.title", "course.ultimate.inv3-maj7.subtitle", quality: "Maj7", voicing: .inversion3, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 3500),
        ]),
        CourseModule(id: "advanced", titleKey: "course.ultimate.mod8.title", lessons: [
            makeChordLesson("adv-7s9", "course.ultimate.adv-7s9.title", "course.ultimate.adv-7s9.subtitle", quality: "7#9", voicing: .root, exampleRoot: "E", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 4000),
            makeChordLesson("adv-7b9", "course.ultimate.adv-7b9.title", "course.ultimate.adv-7b9.subtitle", quality: "7b9", voicing: .root, exampleRoot: "G", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 4000),
            makeChordLesson("adv-lyd", "course.ultimate.adv-lyd.title", "course.ultimate.adv-lyd.subtitle", quality: "Maj7#11", voicing: .root, exampleRoot: "C", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 4000),
            makeChordLesson("adv-m11", "course.ultimate.adv-m11.title", "course.ultimate.adv-m11.subtitle", quality: "m11", voicing: .root, exampleRoot: "D", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 4000),
            makeChordLesson("adv-13", "course.ultimate.adv-13.title", "course.ultimate.adv-13.subtitle", quality: "13", voicing: .root, exampleRoot: "G", practiceKeys: EASY_KEYS_4, challengeKeys: ALL_KEYS, masteryMs: 4000),
        ]),
    ])

// ─── Registry ───────────────────────────────────────────────

public let ALL_COURSES: [Course] = [intervalsCourse, shellVoicingsCourse, scaleDegreesCourse, ultimatePlanCourse]

public func getCourse(_ id: String) -> Course? {
    ALL_COURSES.first { $0.id == id }
}

public struct LessonLookup: Sendable, Equatable {
    public let course: Course
    public let module: CourseModule
    public let lesson: Lesson
}

public func getLesson(_ courseId: String, _ lessonId: String) -> LessonLookup? {
    guard let course = getCourse(courseId) else { return nil }
    for mod in course.modules {
        if let lesson = mod.lessons.first(where: { $0.id == lessonId }) {
            return LessonLookup(course: course, module: mod, lesson: lesson)
        }
    }
    return nil
}
