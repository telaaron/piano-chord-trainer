// CourseProgressStore — persists per-course progress (mastery per lesson) and
// applies step completions. Mirrors src/lib/services/course-progress.ts shape;
// mastery logic comes from the engine (computeMastery, createCourseProgress).

import Foundation
import Observation
import MusicEngine

@MainActor
@Observable
final class CourseProgressStore {
    static let shared = CourseProgressStore()

    private var all: [String: CourseProgress]

    private init() {
        all = Store.load([String: CourseProgress].self, StoreKey.courseProgress) ?? [:]
    }

    private func persist() { Store.save(all, StoreKey.courseProgress) }

    func progress(for course: Course) -> CourseProgress {
        if let p = all[course.id] { return p }
        let fresh = createCourseProgress(course)
        all[course.id] = fresh
        persist()
        return fresh
    }

    func mastery(courseId: String, lessonId: String) -> MasteryLevel {
        guard let cp = all[courseId] else { return .none }
        for m in cp.modules {
            if let lp = m.lessons.first(where: { $0.lessonId == lessonId }) { return lp.mastery }
        }
        return .none
    }

    func completionPercent(for course: Course) -> Int {
        courseCompletionPercent(progress(for: course))
    }

    /// Mark a lesson's steps as completed; record challenge time; recompute mastery.
    func completeLesson(course: Course, lessonId: String, challengeAvgMs: Double?) {
        var cp = progress(for: course)
        for mi in cp.modules.indices {
            for li in cp.modules[mi].lessons.indices where cp.modules[mi].lessons[li].lessonId == lessonId {
                var lp = cp.modules[mi].lessons[li]
                lp.steps = lp.steps.map { step in
                    var s = step; s.completed = true; s.attempts += 1; return s
                }
                if let challengeAvgMs {
                    lp.bestChallengeAvgMs = min(lp.bestChallengeAvgMs ?? .infinity, challengeAvgMs)
                }
                lp.mastery = computeMastery(lp.steps, lp.bestChallengeAvgMs)
                cp.modules[mi].lessons[li] = lp
            }
        }
        cp.lastActivityAt = Date().timeIntervalSince1970 * 1000
        all[course.id] = cp
        persist()
    }
}
