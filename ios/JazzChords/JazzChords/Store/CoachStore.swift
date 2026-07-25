// CoachStore — persists the Auto-Mode ("Coach") state and exposes a thin,
// UI-facing convenience API over the pure engine (Coach.swift). Mirrors the
// web app's coach-state service; all decision logic lives in MusicEngine.
//
// The persisted CoachState rides the jsonb-blob cloud-sync, so its Codable
// shape matches the TypeScript CoachState 1:1 (see Coach.swift).

import Foundation
import Observation
import MusicEngine

@MainActor
@Observable
final class CoachStore {
    static let shared = CoachStore()

    /// The full persisted coach state. Read by the UI for teacher-talk / frontier.
    private(set) var state: CoachState

    private init() {
        state = Store.load(CoachState.self, StoreKey.coachState) ?? createInitialCoachState()
    }

    private func persist() { Store.save(state, StoreKey.coachState) }

    // ─── Reads ──────────────────────────────────────────────

    /// Whether the one-time calibration drill has run.
    var isCalibrated: Bool { state.calibrated }

    /// The current frontier unit (first non-mastered rung), if any.
    var frontierUnit: SkillUnit? {
        let ladder = buildSkillLadder()
        guard !ladder.isEmpty else { return nil }
        let idx = min(max(0, state.frontierIndex), ladder.count - 1)
        return ladder[idx]
    }

    // ─── Plan building ──────────────────────────────────────

    /// Build today's Coach plan from live history + habit profile + course progress.
    /// Stores the plan into state (lastPlan) so a later `applySession` can compare
    /// before/after, then persists.
    func currentPlan(
        history: [SessionResult],
        profile: HabitProfile,
        courseProgress: CourseProgress? = nil,
        now: Date = Date()
    ) -> CoachPlan {
        let nowMs = now.timeIntervalSince1970 * 1000
        let plan = buildCoachPlan(history, profile, courseProgress, state, DEFAULT_COACH_PARAMS, now: nowMs)
        state.lastPlan = plan
        persist()
        return plan
    }

    // ─── Mutations ──────────────────────────────────────────

    /// Apply a finished Coach session (promotion / hold / demotion / decay) and
    /// return the structured teacher feedback for the post-session screen.
    @discardableResult
    func applySession(
        plan: CoachPlan,
        session: SessionResult,
        now: Date = Date()
    ) -> [TeacherStatement] {
        let nowMs = now.timeIntervalSince1970 * 1000
        let before = state
        let after = applySessionToCoach(before, plan, session, DEFAULT_COACH_PARAMS, now: nowMs)
        state = after
        persist()
        // Feedback compares before/after; give it `before` with its plan snapshot.
        var beforeWithPlan = before
        beforeWithPlan.lastPlan = plan
        return teacherFeedback(beforeWithPlan, after, session, DEFAULT_COACH_PARAMS)
    }

    /// Apply a "too easy / just right / too hard" tap (updates difficultyBias).
    func applyFeedbackSignal(_ signal: FeedbackSignal) {
        state = applyFeedback(state, signal, DEFAULT_COACH_PARAMS)
        persist()
    }

    /// Fold a To-Go run's ear tallies into the shared skill map. The piano side
    /// (unitStates) is untouched — hearing a chord is a different facet from
    /// being able to play it.
    func applyEarProgress(_ tallies: [EarTally], now: Date = Date()) {
        guard !tallies.isEmpty else { return }
        let nowMs = now.timeIntervalSince1970 * 1000
        state = applyEarTallies(state, tallies, DEFAULT_COACH_PARAMS, now: nowMs)
        persist()
    }

    /// System verdict on the just-finished session (carries struggleStreak forward).
    func assess(_ session: SessionResult) -> SessionVerdict {
        let result = assessSession(state, session, DEFAULT_COACH_PARAMS)
        state = result.state
        persist()
        return result.verdict
    }
}
