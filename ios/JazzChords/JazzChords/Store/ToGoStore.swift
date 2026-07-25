// ToGoStore — persists the To-Go theory-card SRS states and exposes a thin,
// UI-facing API over the pure engine (ToGo.swift). Mirrors CoachStore: every
// decision lives in MusicEngine, this only builds sessions, applies results and
// writes them where they belong.
//
// Two things are persisted / updated by a finished run:
//   1. Theory-card SRS states → StoreKey.togoCards (this store).
//   2. Ear progress on the shared skill map → CoachStore (applyEarTallies).

import Foundation
import Observation
import MusicEngine

@MainActor
@Observable
final class ToGoStore {
    static let shared = ToGoStore()

    /// SM-2 state per theory card, keyed by TheoryCard.id.
    private(set) var cardStates: [String: TheoryCardState]

    /// The generated deck — deterministic, so it is built once per launch.
    let deck: [TheoryCard]

    private init() {
        cardStates = Store.load([String: TheoryCardState].self, StoreKey.togoCards) ?? [:]
        deck = buildTheoryDeck(.flats)
    }

    private func persist() { Store.save(cardStates, StoreKey.togoCards) }

    // ─── Reads ──────────────────────────────────────────────

    /// Cards whose review date has arrived.
    func due(now: Date = Date()) -> [TheoryCard] {
        dueCards(deck, cardStates, now.timeIntervalSince1970 * 1000)
    }

    /// Both facets of the shared skill map, for the progress line.
    var progress: SkillMapProgress { skillMapProgress(CoachStore.shared.state) }

    // ─── Session building ───────────────────────────────────

    /// Build a To-Go session. The ear side mirrors whatever the Coach is
    /// currently teaching, so hearing a chord credits the same skill unit the
    /// piano side is working on.
    func buildSession(
        capabilities: ToGoCapabilities,
        only: ToGoKind? = nil,
        now: Date = Date(),
        rng: @escaping Rng = { Double.random(in: 0..<1) }
    ) -> ToGoSession {
        let focus = earFocus(CoachStore.shared.state)
        let opts = ToGoSessionOptions(
            deck: deck,
            cardStates: cardStates,
            now: now.timeIntervalSince1970 * 1000,
            focusQuality: focus?.quality,
            focusUnitId: focus?.unitId,
            difficulty: .beginner,
            only: only,
            pref: .flats
        )
        return buildToGoSession(rng, capabilities, opts, DEFAULT_TOGO_PARAMS)
    }

    // ─── Applying a finished run ────────────────────────────

    /// Fold a finished run into both homes: theory cards reschedule here, ear
    /// progress moves the Coach's shared skill map. Returns the run summary.
    @discardableResult
    func applyResults(_ results: [ToGoResult], now: Date = Date()) -> ToGoSummary {
        let nowMs = now.timeIntervalSince1970 * 1000

        // 1. Theory cards → SRS reschedule.
        cardStates = applyResultsToCards(cardStates, results, nowMs, DEFAULT_TOGO_PARAMS)
        persist()

        // 2. Ear progress → the Coach's shared skill map.
        let tallies = tallyEarResults(results.map { (unitId: $0.unitId, correct: $0.correct) })
        CoachStore.shared.applyEarProgress(tallies, now: now)

        return summarize(results)
    }
}
