// Course engine — types, mastery logic.
// 1:1 port of src/lib/engine/courses.ts. Step union → Swift enum with payloads.

import Foundation

public enum StepType: String, Sendable, Codable {
    case theory, practice, challenge
}

public enum MasteryLevel: String, Sendable, Codable {
    case none, started, completed, mastered
}

public struct ChordSpec: Sendable, Equatable {
    public let root: String
    public let quality: String
    public let voicing: VoicingType
    public init(root: String, quality: String, voicing: VoicingType) {
        self.root = root; self.quality = quality; self.voicing = voicing
    }
}

public struct IntervalSpec: Sendable, Equatable {
    public let root: String
    public let target: String
    public let label: String
    public let semitones: Int
    public init(root: String, target: String, label: String, semitones: Int) {
        self.root = root; self.target = target; self.label = label; self.semitones = semitones
    }
}

public struct TheoryStep: Sendable, Equatable {
    public let contentKey: String
    public let exampleChord: ChordSpec?
    public let exampleInterval: IntervalSpec?
    public init(contentKey: String, exampleChord: ChordSpec? = nil, exampleInterval: IntervalSpec? = nil) {
        self.contentKey = contentKey; self.exampleChord = exampleChord; self.exampleInterval = exampleInterval
    }
}

public struct PracticeStep: Sendable, Equatable {
    public let chordPool: [ChordSpec]?
    public let intervalPool: [IntervalSpec]?
    public let guidedCount: Int
    public init(chordPool: [ChordSpec]? = nil, intervalPool: [IntervalSpec]? = nil, guidedCount: Int) {
        self.chordPool = chordPool; self.intervalPool = intervalPool; self.guidedCount = guidedCount
    }
}

public struct ChallengeStep: Sendable, Equatable {
    public let voicing: VoicingType
    public let quality: String
    public let keys: [String]
    public let masteryThresholdMs: Int
    public let intervalSemitones: Int?
    public let intervalLabel: String?
    public init(voicing: VoicingType, quality: String, keys: [String], masteryThresholdMs: Int,
                intervalSemitones: Int? = nil, intervalLabel: String? = nil) {
        self.voicing = voicing; self.quality = quality; self.keys = keys
        self.masteryThresholdMs = masteryThresholdMs
        self.intervalSemitones = intervalSemitones; self.intervalLabel = intervalLabel
    }
}

public enum LessonStep: Sendable, Equatable {
    case theory(TheoryStep)
    case practice(PracticeStep)
    case challenge(ChallengeStep)

    public var type: StepType {
        switch self {
        case .theory: return .theory
        case .practice: return .practice
        case .challenge: return .challenge
        }
    }
}

public struct Lesson: Sendable, Equatable {
    public let id: String
    public let titleKey: String
    public let subtitleKey: String
    public let steps: [LessonStep]
    public init(id: String, titleKey: String, subtitleKey: String, steps: [LessonStep]) {
        self.id = id; self.titleKey = titleKey; self.subtitleKey = subtitleKey; self.steps = steps
    }
}

public struct CourseModule: Sendable, Equatable {
    public let id: String
    public let titleKey: String
    public let lessons: [Lesson]
    public init(id: String, titleKey: String, lessons: [Lesson]) {
        self.id = id; self.titleKey = titleKey; self.lessons = lessons
    }
}

public enum CourseLevel: String, Sendable {
    case beginner, intermediate, advanced
}

public struct Course: Sendable, Equatable {
    public let id: String
    public let titleKey: String
    public let descriptionKey: String
    public let subtitleKey: String
    public let icon: String
    public let level: CourseLevel
    public let modules: [CourseModule]
    public init(id: String, titleKey: String, descriptionKey: String, subtitleKey: String,
                icon: String, level: CourseLevel, modules: [CourseModule]) {
        self.id = id; self.titleKey = titleKey; self.descriptionKey = descriptionKey
        self.subtitleKey = subtitleKey; self.icon = icon; self.level = level; self.modules = modules
    }
}

// ─── Progress types ─────────────────────────────────────────

public struct StepProgress: Sendable, Equatable, Codable {
    public var stepType: StepType
    public var completed: Bool
    public var attempts: Int
    public var bestScore: Double?
    public init(stepType: StepType, completed: Bool, attempts: Int, bestScore: Double? = nil) {
        self.stepType = stepType; self.completed = completed; self.attempts = attempts; self.bestScore = bestScore
    }
}

public struct LessonProgress: Sendable, Equatable, Codable {
    public var lessonId: String
    public var steps: [StepProgress]
    public var mastery: MasteryLevel
    public var bestChallengeAvgMs: Double?
    public init(lessonId: String, steps: [StepProgress], mastery: MasteryLevel, bestChallengeAvgMs: Double? = nil) {
        self.lessonId = lessonId; self.steps = steps; self.mastery = mastery; self.bestChallengeAvgMs = bestChallengeAvgMs
    }
}

public struct ModuleProgress: Sendable, Equatable, Codable {
    public var moduleId: String
    public var lessons: [LessonProgress]
    public init(moduleId: String, lessons: [LessonProgress]) {
        self.moduleId = moduleId; self.lessons = lessons
    }
}

public struct CourseProgress: Sendable, Equatable, Codable {
    public var courseId: String
    public var modules: [ModuleProgress]
    public var startedAt: Double
    public var lastActivityAt: Double
    public init(courseId: String, modules: [ModuleProgress], startedAt: Double, lastActivityAt: Double) {
        self.courseId = courseId; self.modules = modules; self.startedAt = startedAt; self.lastActivityAt = lastActivityAt
    }
}

// ─── Mastery helpers ────────────────────────────────────────

public let MASTERY_THRESHOLD_MS = 2000.0

public func computeMastery(_ steps: [StepProgress], _ bestChallengeAvgMs: Double? = nil) -> MasteryLevel {
    if steps.allSatisfy({ !$0.completed && $0.attempts == 0 }) { return .none }

    let allCompleted = steps.allSatisfy { $0.completed }
    if !allCompleted { return .started }

    if let bestChallengeAvgMs, bestChallengeAvgMs < MASTERY_THRESHOLD_MS {
        return .mastered
    }
    return .completed
}

public func createLessonProgress(_ lesson: Lesson) -> LessonProgress {
    LessonProgress(
        lessonId: lesson.id,
        steps: lesson.steps.map { StepProgress(stepType: $0.type, completed: false, attempts: 0) },
        mastery: .none
    )
}

public func createCourseProgress(_ course: Course, now: Double = Date().timeIntervalSince1970 * 1000) -> CourseProgress {
    CourseProgress(
        courseId: course.id,
        modules: course.modules.map { m in
            ModuleProgress(moduleId: m.id, lessons: m.lessons.map(createLessonProgress))
        },
        startedAt: now,
        lastActivityAt: now
    )
}

public func moduleCompletionPercent(_ moduleProgress: ModuleProgress) -> Int {
    let lessons = moduleProgress.lessons
    if lessons.isEmpty { return 0 }
    let completed = lessons.filter { $0.mastery == .completed || $0.mastery == .mastered }.count
    return Int((Double(completed) / Double(lessons.count) * 100).rounded())
}

public func courseCompletionPercent(_ courseProgress: CourseProgress) -> Int {
    let allLessons = courseProgress.modules.flatMap { $0.lessons }
    if allLessons.isEmpty { return 0 }
    let completed = allLessons.filter { $0.mastery == .completed || $0.mastery == .mastered }.count
    return Int((Double(completed) / Double(allLessons.count) * 100).rounded())
}

public struct LessonRef: Sendable, Equatable {
    public let moduleId: String
    public let lessonId: String
}

public func getNextLesson(_ course: Course, _ progress: CourseProgress) -> LessonRef? {
    for mod in course.modules {
        let modProgress = progress.modules.first { $0.moduleId == mod.id }
        for lesson in mod.lessons {
            let lp = modProgress?.lessons.first { $0.lessonId == lesson.id }
            if lp == nil || lp!.mastery == .none || lp!.mastery == .started {
                return LessonRef(moduleId: mod.id, lessonId: lesson.id)
            }
        }
    }
    return nil
}
