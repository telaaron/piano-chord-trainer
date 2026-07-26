// To-Go — practice away from the piano.
//
// Seven disciplines a jazz musician trains without an instrument:
//   interval · quality · progression · sing · time · lick · theory
//
// This module is the engine: it BUILDS exercises and GRADES answers. It never
// plays audio, touches the UI, or reads the clock — the UI does that and hands
// results back. Randomness enters through an injected `rng`, time through `now`.
//
// 1:1 port of src/lib/engine/togo.ts. TheoryCardState is persisted and rides the
// jsonb-blob sync, so every Codable key MUST match the TS field names exactly.

import Foundation

// ─── Public types ───────────────────────────────────────────

public enum ToGoKind: String, Sendable, Equatable, Codable, CaseIterable {
    case interval, quality, progression, sing, time, lick, theory
}

/// How the UI should sound out an exercise. Engine-neutral — no audio here.
public enum ToGoPlayback: Sendable, Equatable {
    /// Sound these notes together (a chord).
    case chord(notes: [String])
    /// Sound these notes one after another.
    case sequence(notes: [String], stepMs: Double)
    /// Sound each inner array as a chord, one after another — a cadence.
    /// Distinct from `sequence` because a progression must be *heard as chords*;
    /// flattening it into single notes destroys the very thing being tested.
    case chords(chords: [[String]], stepMs: Double)
    /// Hold a reference tone while the player sings.
    case drone(note: String)
    /// Run the metronome; the player taps along.
    case pulse(bpm: Int, bars: Int, beatsPerBar: Int)
    /// Nothing to play — a silent flashcard.
    case silent

    /// The TS discriminant string, so tests and UI can switch on it like the web.
    public var type: String {
        switch self {
        case .chord: return "chord"
        case .sequence: return "sequence"
        case .chords: return "chords"
        case .drone: return "drone"
        case .pulse: return "pulse"
        case .silent: return "silent"
        }
    }
}

/// How the player answers.
public enum ToGoInput: Sendable, Equatable {
    /// Pick one of `options`.
    case choice
    /// Sing a pitch; graded on pitch class.
    case sing(targetPitchClass: Int)
    /// Tap along; graded on timing offsets.
    case tap(onBeats: [Int], beatsPerBar: Int, toleranceMs: Double)
    /// Tap the notes back on a keyboard; graded as a pitch-class set.
    case notes(targetPitchClasses: [Int])

    public var type: String {
        switch self {
        case .choice: return "choice"
        case .sing: return "sing"
        case .tap: return "tap"
        case .notes: return "notes"
        }
    }
}

public struct ToGoExercise: Sendable, Equatable {
    public var id: String
    public var kind: ToGoKind
    public var play: ToGoPlayback
    public var input: ToGoInput
    /// Choice labels (empty for non-choice inputs).
    public var options: [String]
    /// Index into `options` for choice inputs; -1 otherwise.
    public var answerIndex: Int
    /// i18n key + params for the instruction line.
    public var promptKey: String
    public var promptParams: [String: String]
    /// The plain answer, for the reveal ("it was a m7").
    public var answerLabel: String
    /// Links to a Coach skill unit so ear progress moves the same map.
    public var unitId: String?
    /// Theory cards carry their card id so the SRS can reschedule them.
    public var cardId: String?

    public init(id: String, kind: ToGoKind, play: ToGoPlayback, input: ToGoInput,
                options: [String], answerIndex: Int, promptKey: String,
                promptParams: [String: String], answerLabel: String,
                unitId: String? = nil, cardId: String? = nil) {
        self.id = id
        self.kind = kind
        self.play = play
        self.input = input
        self.options = options
        self.answerIndex = answerIndex
        self.promptKey = promptKey
        self.promptParams = promptParams
        self.answerLabel = answerLabel
        self.unitId = unitId
        self.cardId = cardId
    }
}

/// What the UI reports back after one exercise.
public struct ToGoResult: Sendable, Equatable {
    public var exerciseId: String
    public var kind: ToGoKind
    public var correct: Bool
    /// Time from prompt to answer.
    public var ms: Double
    public var unitId: String?
    public var cardId: String?

    public init(exerciseId: String, kind: ToGoKind, correct: Bool, ms: Double,
                unitId: String? = nil, cardId: String? = nil) {
        self.exerciseId = exerciseId
        self.kind = kind
        self.correct = correct
        self.ms = ms
        self.unitId = unitId
        self.cardId = cardId
    }
}

public struct ToGoSession: Sendable, Equatable {
    public var exercises: [ToGoExercise]
    /// i18n key for the one-line intro ("Ear work — 8 rounds, no piano needed").
    public var sayKey: String
    public var sayParams: [String: String]
    public var estMinutes: Int

    public init(exercises: [ToGoExercise], sayKey: String, sayParams: [String: String], estMinutes: Int) {
        self.exercises = exercises
        self.sayKey = sayKey
        self.sayParams = sayParams
        self.estMinutes = estMinutes
    }
}

/// Which disciplines the player enabled / the device supports.
public struct ToGoCapabilities: Sendable, Equatable {
    /// Mic available & permitted — gates `sing`.
    public var mic: Bool
    /// Sound on — gates everything except `theory`.
    public var audio: Bool

    public init(mic: Bool, audio: Bool) {
        self.mic = mic
        self.audio = audio
    }
}

public let ALL_TOGO_KINDS: [ToGoKind] = [
    .interval, .quality, .progression, .sing, .time, .lick, .theory,
]

// ─── Tunables ───────────────────────────────────────────────

public struct ToGoParams: Sendable, Equatable, Codable {
    /// Exercises in a standard session.
    public var sessionLength: Int
    /// ms between notes when a melodic phrase is sounded.
    public var sequenceStepMs: Double
    /// How close a tap must land to count (± ms).
    public var tapToleranceMs: Double
    /// Taps required before a time exercise is graded.
    public var tapTargetCount: Int
    /// Default tempo for time exercises.
    public var tapBpm: Int
    /// How many wrong choices to offer alongside the right one.
    public var distractors: Int
    /// SM-2 floor for theory-card ease.
    public var minEase: Double

    public init(sessionLength: Int, sequenceStepMs: Double, tapToleranceMs: Double,
                tapTargetCount: Int, tapBpm: Int, distractors: Int, minEase: Double) {
        self.sessionLength = sessionLength
        self.sequenceStepMs = sequenceStepMs
        self.tapToleranceMs = tapToleranceMs
        self.tapTargetCount = tapTargetCount
        self.tapBpm = tapBpm
        self.distractors = distractors
        self.minEase = minEase
    }
}

public let DEFAULT_TOGO_PARAMS = ToGoParams(
    sessionLength: 8,
    sequenceStepMs: 420,
    tapToleranceMs: 120,
    tapTargetCount: 8,
    tapBpm: 100,
    distractors: 3,
    minEase: 1.3
)

// ─── Musical vocabulary ─────────────────────────────────────

public struct IntervalRung: Sendable, Equatable {
    public let semitones: Int
    public let label: String
    public init(semitones: Int, label: String) { self.semitones = semitones; self.label = label }
}

/// Intervals worth hearing, easiest first — the order a curriculum teaches them.
public let INTERVAL_LADDER: [IntervalRung] = [
    IntervalRung(semitones: 12, label: "Octave"),
    IntervalRung(semitones: 7, label: "Perfect 5th"),
    IntervalRung(semitones: 5, label: "Perfect 4th"),
    IntervalRung(semitones: 4, label: "Major 3rd"),
    IntervalRung(semitones: 3, label: "Minor 3rd"),
    IntervalRung(semitones: 9, label: "Major 6th"),
    IntervalRung(semitones: 8, label: "Minor 6th"),
    IntervalRung(semitones: 2, label: "Major 2nd"),
    IntervalRung(semitones: 1, label: "Minor 2nd"),
    IntervalRung(semitones: 11, label: "Major 7th"),
    IntervalRung(semitones: 10, label: "Minor 7th"),
    IntervalRung(semitones: 6, label: "Tritone"),
]

public struct ProgressionRung: Sendable, Equatable {
    public let degrees: [Int]
    public let label: String
    public init(degrees: [Int], label: String) { self.degrees = degrees; self.label = label }
}

/// Roman-numeral shapes the ear should recognise, easiest first.
public let PROGRESSION_LADDER: [ProgressionRung] = [
    ProgressionRung(degrees: [0, 4, 0], label: "I – V – I"),
    ProgressionRung(degrees: [1, 4, 0], label: "ii – V – I"),
    ProgressionRung(degrees: [0, 5, 1, 4], label: "I – vi – ii – V"),
    ProgressionRung(degrees: [2, 5, 1, 4], label: "iii – vi – ii – V"),
    ProgressionRung(degrees: [0, 3, 4], label: "I – IV – V"),
    ProgressionRung(degrees: [3, 0], label: "IV – I"),
]

/// Chord quality per major-scale degree — for sounding a progression.
private let DEGREE_QUALITY = ["Maj7", "m7", "m7", "Maj7", "7", "m7", "m7b5"]
/// Semitone offset of each major-scale degree from the tonic.
private let DEGREE_SEMITONES = [0, 2, 4, 5, 7, 9, 11]

public struct SingRung: Sendable, Equatable {
    public let semitones: Int
    public let label: String
    public init(semitones: Int, label: String) { self.semitones = semitones; self.label = label }
}

/// Scale degrees a singer is asked to find over a drone, easiest first.
public let SING_LADDER: [SingRung] = [
    SingRung(semitones: 0, label: "Root"),
    SingRung(semitones: 7, label: "5th"),
    SingRung(semitones: 4, label: "Major 3rd"),
    SingRung(semitones: 3, label: "Minor 3rd"),
    SingRung(semitones: 10, label: "♭7"),
    SingRung(semitones: 2, label: "9th"),
    SingRung(semitones: 11, label: "Major 7th"),
    SingRung(semitones: 6, label: "♯11"),
]

public struct TapRung: Sendable, Equatable {
    public let onBeats: [Int]
    public let labelKey: String
    public init(onBeats: [Int], labelKey: String) { self.onBeats = onBeats; self.labelKey = labelKey }
}

/// Rhythm feels, easiest first. `onBeats` are 1-based beats in a 4/4 bar.
public let TAP_LADDER: [TapRung] = [
    TapRung(onBeats: [1, 2, 3, 4], labelKey: "togo.tap.quarters"),
    TapRung(onBeats: [2, 4], labelKey: "togo.tap.backbeat"),
    TapRung(onBeats: [1, 3], labelKey: "togo.tap.downbeats"),
    TapRung(onBeats: [2], labelKey: "togo.tap.two_only"),
]

public struct Lick: Sendable, Equatable {
    public let offsets: [Int]
    public let nameKey: String
    public init(offsets: [Int], nameKey: String) { self.offsets = offsets; self.nameKey = nameKey }
}

/// Short bebop-flavoured phrases, as semitone offsets from a root.
/// These are the language: enclosures, guide-tone moves, bebop scale fragments.
public let LICK_LIBRARY: [Lick] = [
    Lick(offsets: [0, 2, 4, 5], nameKey: "togo.lick.scale_up"),
    Lick(offsets: [4, 2, 0], nameKey: "togo.lick.triad_down"),
    Lick(offsets: [0, 4, 7, 10], nameKey: "togo.lick.arpeggio"),
    Lick(offsets: [1, 0, -1, 0], nameKey: "togo.lick.enclosure"),
    Lick(offsets: [10, 9, 7, 5], nameKey: "togo.lick.guide_down"),
    Lick(offsets: [0, 3, 5, 6], nameKey: "togo.lick.blues_climb"),
    Lick(offsets: [7, 5, 4, 2, 0], nameKey: "togo.lick.descent"),
    Lick(offsets: [0, 4, 3, 2], nameKey: "togo.lick.chromatic_fall"),
]

private let TOGO_KEYS_EASY = ["C", "F", "Bb", "Eb"]
private let TOGO_KEYS_ALL = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

// ─── Theory cards (generated, not hand-written) ─────────────

public enum TheoryCardKind: String, Sendable, Equatable, Codable {
    case chordNotes = "chord-notes"
    case chordDegree = "chord-degree"
    case tritoneSub = "tritone-sub"
    case relativeMinor = "relative-minor"
}

public struct TheoryCard: Sendable, Equatable {
    public var id: String
    public var kind: TheoryCardKind
    public var promptKey: String
    public var promptParams: [String: String]
    public var answer: String
    /// Plausible wrong answers drawn from the same family.
    public var distractors: [String]

    public init(id: String, kind: TheoryCardKind, promptKey: String,
                promptParams: [String: String], answer: String, distractors: [String]) {
        self.id = id
        self.kind = kind
        self.promptKey = promptKey
        self.promptParams = promptParams
        self.answer = answer
        self.distractors = distractors
    }
}

/// SM-2 state for one theory card. Mirrors habits.ChordReview's maths.
public struct TheoryCardState: Sendable, Equatable, Codable {
    public var cardId: String
    /// ms since epoch.
    public var lastReviewed: Double
    public var nextReview: Double
    /// days
    public var interval: Double
    public var ease: Double
    public var repetitions: Int

    public init(cardId: String, lastReviewed: Double, nextReview: Double,
                interval: Double, ease: Double, repetitions: Int) {
        self.cardId = cardId
        self.lastReviewed = lastReviewed
        self.nextReview = nextReview
        self.interval = interval
        self.ease = ease
        self.repetitions = repetitions
    }
}

private struct DegreeLabel {
    let interval: Int
    let label: String
}

private let DEGREE_LABELS: [DegreeLabel] = [
    DegreeLabel(interval: 3, label: "♭3"),
    DegreeLabel(interval: 4, label: "3rd"),
    DegreeLabel(interval: 7, label: "5th"),
    DegreeLabel(interval: 10, label: "♭7"),
    DegreeLabel(interval: 11, label: "7th"),
    DegreeLabel(interval: 1, label: "♭9"),
    DegreeLabel(interval: 2, label: "9th"),
]

/// Build the full deck of theory cards from the engine's own chord tables, so
/// the deck stays correct and grows automatically when the curriculum does.
/// Deterministic — same deck every call.
public func buildTheoryDeck(_ pref: AccidentalPreference = .flats) -> [TheoryCard] {
    var deck: [TheoryCard] = []
    let qualities = (CHORDS_BY_DIFFICULTY[.intermediate] ?? []).map { $0.display }

    for root in TOGO_KEYS_EASY {
        let rootSt = noteToSemitone(root)

        // "Which notes are in Cmaj7?"
        for quality in qualities {
            let notes = getChordNotes(root, quality, pref)
            if notes.isEmpty { continue }
            deck.append(TheoryCard(
                id: "notes|\(root)|\(quality)",
                kind: .chordNotes,
                promptKey: "togo.card.chord_notes",
                promptParams: ["chord": "\(root)\(quality)"],
                answer: notes.joined(separator: " – "),
                distractors: [
                    getChordNotes(root, quality == "Maj7" ? "m7" : "Maj7", pref).joined(separator: " – "),
                    getChordNotes(getNoteName(rootSt, 2, pref), quality, pref).joined(separator: " – "),
                    getChordNotes(getNoteName(rootSt, 5, pref), quality, pref).joined(separator: " – "),
                ].filter { !$0.isEmpty }
            ))
        }

        // "What's the 3rd of C7?"
        for quality in ["Maj7", "7", "m7"] {
            let ivs = CHORD_INTERVALS[quality] ?? []
            for deg in DEGREE_LABELS {
                if !ivs.contains(deg.interval) { continue }
                deck.append(TheoryCard(
                    id: "degree|\(root)|\(quality)|\(deg.interval)",
                    kind: .chordDegree,
                    promptKey: "togo.card.chord_degree",
                    promptParams: ["degree": deg.label, "chord": "\(root)\(quality)"],
                    answer: getNoteName(rootSt, deg.interval, pref),
                    distractors: [
                        getNoteName(rootSt, (deg.interval + 1) % 12, pref),
                        getNoteName(rootSt, (deg.interval + 11) % 12, pref),
                        getNoteName(rootSt, (deg.interval + 5) % 12, pref),
                    ]
                ))
            }
        }

        // "What's the tritone sub of C7?"
        deck.append(TheoryCard(
            id: "tritone|\(root)",
            kind: .tritoneSub,
            promptKey: "togo.card.tritone_sub",
            promptParams: ["chord": "\(root)7"],
            answer: "\(getNoteName(rootSt, 6, pref))7",
            distractors: [
                "\(getNoteName(rootSt, 5, pref))7",
                "\(getNoteName(rootSt, 7, pref))7",
                "\(getNoteName(rootSt, 1, pref))7",
            ]
        ))

        // "What's the relative minor of C major?"
        deck.append(TheoryCard(
            id: "relminor|\(root)",
            kind: .relativeMinor,
            promptKey: "togo.card.relative_minor",
            promptParams: ["key": root],
            answer: "\(getNoteName(rootSt, 9, pref))m",
            distractors: [
                "\(getNoteName(rootSt, 7, pref))m",
                "\(getNoteName(rootSt, 2, pref))m",
                "\(getNoteName(rootSt, 4, pref))m",
            ]
        ))
    }

    return deck
}

/// SM-2 reschedule for a theory card. Pure: time enters as `now` (ms).
/// `quality` is 0–5 exactly as habits.ts uses it.
public func scheduleCard(
    _ state: TheoryCardState,
    _ quality: Int,
    _ now: Double,
    _ params: ToGoParams = DEFAULT_TOGO_PARAMS
) -> TheoryCardState {
    var interval = state.interval
    var ease = state.ease
    var repetitions = state.repetitions

    if quality >= 3 {
        if repetitions == 0 { interval = 1 }
        else if repetitions == 1 { interval = 3 }
        else { interval = (interval * ease).rounded() }
        repetitions += 1
    } else {
        // Missed — start over tomorrow.
        repetitions = 0
        interval = 1
    }

    let q = Double(quality)
    ease = ease + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    if ease < params.minEase { ease = params.minEase }

    let DAY: Double = 24 * 60 * 60 * 1000
    return TheoryCardState(
        cardId: state.cardId,
        lastReviewed: now,
        nextReview: now + interval * DAY,
        interval: interval,
        ease: ease,
        repetitions: repetitions
    )
}

/// A fresh card, due immediately.
public func newCardState(_ cardId: String, _ now: Double) -> TheoryCardState {
    TheoryCardState(cardId: cardId, lastReviewed: 0, nextReview: now, interval: 0, ease: 2.5, repetitions: 0)
}

/// Cards whose review date has arrived, soonest-due first.
public func dueCards(_ deck: [TheoryCard], _ states: [String: TheoryCardState], _ now: Double) -> [TheoryCard] {
    let due = deck.filter { c in
        guard let s = states[c.id] else { return true }
        return s.nextReview <= now
    }
    // Stable sort by nextReview (JS Array.sort is stable) — enumerated() index breaks ties.
    return due.enumerated().sorted { a, b in
        let av = states[a.element.id]?.nextReview ?? 0
        let bv = states[b.element.id]?.nextReview ?? 0
        if av == bv { return a.offset < b.offset }
        return av < bv
    }.map { $0.element }
}

// ─── Exercise builders ──────────────────────────────────────
// Each takes an rng so sessions are varied but reproducible in tests.

public typealias Rng = () -> Double

private func pick<T>(_ arr: [T], _ rng: Rng) -> T {
    arr[min(arr.count - 1, Int(floor(rng() * Double(arr.count))))]
}

/// Distinct wrong options plus the right one, shuffled deterministically.
func withDistractors(_ answer: String, _ pool: [String], _ count: Int, _ rng: Rng) -> (options: [String], answerIndex: Int) {
    var wrong: [String] = []
    let candidates = pool.filter { $0 != answer }
    // Walk the candidate list from a random offset — deterministic given rng,
    // and guarantees distinct options without a rejection loop.
    let start = Int(floor(rng() * Double(max(1, candidates.count))))
    var i = 0
    while i < candidates.count && wrong.count < count {
        let c = candidates[(start + i) % candidates.count]
        if !wrong.contains(c) { wrong.append(c) }
        i += 1
    }
    var options = wrong + [answer]
    // Fisher-Yates with the injected rng.
    var k = options.count - 1
    while k > 0 {
        let j = Int(floor(rng() * Double(k + 1)))
        options.swapAt(k, j)
        k -= 1
    }
    return (options, options.firstIndex(of: answer) ?? -1)
}

/// Hear two notes, name the distance.
/// Both notes carry an octave. Naming them by pitch class alone made the
/// exercise lie: a major seventh over C came back as B in the same octave and
/// sounded like a semitone DOWN, and an octave resolved to 12 % 12 = 0, so the
/// same note played twice. An interval is a direction as well as a distance.
///
/// - Parameter descending: play the second note below the first instead of above.
public func buildIntervalExercise(
    _ rng: Rng,
    _ params: ToGoParams = DEFAULT_TOGO_PARAMS,
    _ pref: AccidentalPreference = .flats,
    ladderDepth: Int = INTERVAL_LADDER.count,
    descending: Bool = false
) -> ToGoExercise {
    let entry = pick(Array(INTERVAL_LADDER.prefix(max(2, ladderDepth))), rng)
    let root = pick(TOGO_KEYS_ALL, rng)
    let rootSt = noteToSemitone(root)
    // Descending starts an octave higher so the answer stays in a singable range.
    let startOct = descending ? 5 : 4
    let step = descending ? -entry.semitones : entry.semitones
    let from = getPitchedNote(rootSt, 0, pref, octave: startOct)
    let target = getPitchedNote(rootSt, step, pref, octave: startOct)
    let (options, answerIndex) = withDistractors(
        entry.label,
        INTERVAL_LADDER.map { $0.label },
        params.distractors,
        rng
    )
    return ToGoExercise(
        id: "interval|\(root)|\(entry.semitones)|\(descending ? "down" : "up")",
        kind: .interval,
        play: .sequence(notes: [from, target], stepMs: params.sequenceStepMs),
        input: .choice,
        options: options,
        answerIndex: answerIndex,
        promptKey: descending ? "togo.prompt.interval_down" : "togo.prompt.interval_up",
        promptParams: [:],
        answerLabel: entry.label
    )
}

/// Hear a chord, name the quality. Mirrors the piano drill, inverted.
public func buildQualityExercise(
    _ rng: Rng,
    _ params: ToGoParams = DEFAULT_TOGO_PARAMS,
    _ pref: AccidentalPreference = .flats,
    _ difficulty: Difficulty = .beginner,
    unitId: String? = nil,
    forcedQuality: String? = nil
) -> ToGoExercise {
    let pool = (CHORDS_BY_DIFFICULTY[difficulty] ?? []).map { $0.display }
    let quality: String
    if let forcedQuality, pool.contains(forcedQuality) { quality = forcedQuality }
    else { quality = pick(pool, rng) }
    let root = pick(TOGO_KEYS_ALL, rng)
    let notes = getChordNotes(root, quality, pref)
    let (options, answerIndex) = withDistractors(quality, pool, params.distractors, rng)
    return ToGoExercise(
        id: "quality|\(root)|\(quality)",
        kind: .quality,
        play: .chord(notes: notes),
        input: .choice,
        options: options,
        answerIndex: answerIndex,
        promptKey: "togo.prompt.quality",
        promptParams: [:],
        answerLabel: quality,
        unitId: unitId
    )
}

/// Hear a cadence, name the roman-numeral shape.
public func buildProgressionExercise(
    _ rng: Rng,
    _ params: ToGoParams = DEFAULT_TOGO_PARAMS,
    _ pref: AccidentalPreference = .flats,
    ladderDepth: Int = PROGRESSION_LADDER.count
) -> ToGoExercise {
    let entry = pick(Array(PROGRESSION_LADDER.prefix(max(2, ladderDepth))), rng)
    let key = pick(TOGO_KEYS_EASY, rng)
    let keySt = noteToSemitone(key)

    // One inner array per chord, so the UI can sound a real cadence.
    let chords: [[String]] = entry.degrees.map { deg in
        let root = getNoteName(keySt, DEGREE_SEMITONES[deg % 7], pref)
        return getChordNotes(root, DEGREE_QUALITY[deg % 7], pref)
    }

    let (options, answerIndex) = withDistractors(
        entry.label,
        PROGRESSION_LADDER.map { $0.label },
        params.distractors,
        rng
    )
    return ToGoExercise(
        id: "prog|\(key)|\(entry.degrees.map(String.init).joined(separator: "-"))",
        kind: .progression,
        play: .chords(chords: chords, stepMs: params.sequenceStepMs * 2),
        input: .choice,
        options: options,
        answerIndex: answerIndex,
        promptKey: "togo.prompt.progression",
        promptParams: ["key": key],
        answerLabel: entry.label
    )
}

/// Sing a scale degree over a drone; the mic grades the pitch class.
public func buildSingExercise(
    _ rng: Rng,
    _ params: ToGoParams = DEFAULT_TOGO_PARAMS,
    _ pref: AccidentalPreference = .flats,
    ladderDepth: Int = SING_LADDER.count
) -> ToGoExercise {
    let entry = pick(Array(SING_LADDER.prefix(max(1, ladderDepth))), rng)
    let root = pick(TOGO_KEYS_EASY, rng)
    let rootSt = noteToSemitone(root)
    let targetPc = (rootSt + entry.semitones) % 12
    return ToGoExercise(
        id: "sing|\(root)|\(entry.semitones)",
        kind: .sing,
        play: .drone(note: root),
        input: .sing(targetPitchClass: targetPc),
        options: [],
        answerIndex: -1,
        promptKey: "togo.prompt.sing",
        promptParams: ["degree": entry.label, "root": root],
        answerLabel: getNoteName(rootSt, entry.semitones, pref)
    )
}

/// Tap the groove; graded on timing offsets against the click.
public func buildTimeExercise(
    _ rng: Rng,
    _ params: ToGoParams = DEFAULT_TOGO_PARAMS,
    ladderDepth: Int = TAP_LADDER.count
) -> ToGoExercise {
    let entry = pick(Array(TAP_LADDER.prefix(max(1, ladderDepth))), rng)
    let bars = max(2, Int(ceil(Double(params.tapTargetCount) / Double(max(1, entry.onBeats.count)))))
    return ToGoExercise(
        id: "time|\(entry.onBeats.map(String.init).joined(separator: "-"))",
        kind: .time,
        play: .pulse(bpm: params.tapBpm, bars: bars, beatsPerBar: 4),
        input: .tap(onBeats: entry.onBeats, beatsPerBar: 4, toleranceMs: params.tapToleranceMs),
        options: [],
        answerIndex: -1,
        promptKey: entry.labelKey,
        promptParams: ["bpm": String(params.tapBpm)],
        answerLabel: entry.onBeats.map(String.init).joined(separator: " · ")
    )
}

/// Hear a short phrase, tap it back from memory.
public func buildLickExercise(
    _ rng: Rng,
    _ params: ToGoParams = DEFAULT_TOGO_PARAMS,
    _ pref: AccidentalPreference = .flats,
    maxNotes: Int = 5
) -> ToGoExercise {
    let candidates = LICK_LIBRARY.filter { $0.offsets.count <= max(3, maxNotes) }
    let lick = pick(candidates.isEmpty ? LICK_LIBRARY : candidates, rng)
    let root = pick(TOGO_KEYS_EASY, rng)
    let rootSt = noteToSemitone(root)
    let notes = lick.offsets.map { getNoteName(rootSt, ((($0 % 12) + 12) % 12), pref) }
    let pcs = lick.offsets.map { ((((rootSt + $0) % 12) + 12) % 12) }
    return ToGoExercise(
        id: "lick|\(root)|\(lick.nameKey)",
        kind: .lick,
        play: .sequence(notes: notes, stepMs: params.sequenceStepMs),
        input: .notes(targetPitchClasses: pcs),
        options: [],
        answerIndex: -1,
        promptKey: "togo.prompt.lick",
        promptParams: ["count": String(notes.count)],
        answerLabel: notes.joined(separator: " – ")
    )
}

/// A silent flashcard — works with the sound off.
public func buildTheoryExercise(_ card: TheoryCard, _ rng: Rng, _ params: ToGoParams = DEFAULT_TOGO_PARAMS) -> ToGoExercise {
    let (options, answerIndex) = withDistractors(card.answer, card.distractors, params.distractors, rng)
    return ToGoExercise(
        id: "theory|\(card.id)",
        kind: .theory,
        play: .silent,
        input: .choice,
        options: options,
        answerIndex: answerIndex,
        promptKey: card.promptKey,
        promptParams: card.promptParams,
        answerLabel: card.answer,
        cardId: card.id
    )
}

// ─── Grading ────────────────────────────────────────────────

/// Did the player pick the right option?
public func gradeChoice(_ ex: ToGoExercise, _ chosenIndex: Int) -> Bool {
    chosenIndex == ex.answerIndex
}

/// Was the sung note the target pitch class? `sungMidi` comes from the mic.
/// Octave-agnostic — singing the 3rd an octave down is still the 3rd.
public func gradeSing(_ ex: ToGoExercise, _ sungMidi: [Int]) -> Bool {
    guard case let .sing(target) = ex.input else { return false }
    return sungMidi.contains { ((($0 % 12) + 12) % 12) == target }
}

/// Did the player tap back the right notes (as a pitch-class set)?
public func gradeNotes(_ ex: ToGoExercise, _ tappedPitchClasses: [Int]) -> Bool {
    guard case let .notes(targetPitchClasses) = ex.input else { return false }
    let target = Set(targetPitchClasses.map { ((($0 % 12) + 12) % 12) })
    let got = Set(tappedPitchClasses.map { ((($0 % 12) + 12) % 12) })
    if got.count != target.count { return false }
    for p in got where !target.contains(p) { return false }
    return true
}

public struct TapScore: Sendable, Equatable {
    /// Taps that landed inside the tolerance window.
    public var hits: Int
    /// Taps expected across the exercise.
    public var expected: Int
    /// Mean |offset| in ms over the taps that hit. Lower is tighter.
    public var meanAbsOffsetMs: Double
    /// Signed mean — negative = rushing, positive = dragging.
    public var meanOffsetMs: Double
    public var correct: Bool

    public init(hits: Int, expected: Int, meanAbsOffsetMs: Double, meanOffsetMs: Double, correct: Bool) {
        self.hits = hits
        self.expected = expected
        self.meanAbsOffsetMs = meanAbsOffsetMs
        self.meanOffsetMs = meanOffsetMs
        self.correct = correct
    }
}

/// Score tap timing against the beat grid.
///
/// `beatTimesMs` are the moments the click fired for the beats the player was
/// asked to tap; `tapTimesMs` are when they actually tapped. Each expected beat
/// is matched to its nearest unused tap, so an extra tap can't score twice and a
/// missed beat counts against you. Offsets are SIGNED — this is what lets us say
/// "you're rushing" instead of only "you're off".
public func gradeTaps(
    _ beatTimesMs: [Double],
    _ tapTimesMs: [Double],
    _ toleranceMs: Double,
    passRatio: Double = 0.7
) -> TapScore {
    var used = [Bool](repeating: false, count: tapTimesMs.count)
    var offsets: [Double] = []

    for beat in beatTimesMs {
        var bestIdx = -1
        var bestDist = Double.infinity
        for i in 0..<tapTimesMs.count {
            if used[i] { continue }
            let d = abs(tapTimesMs[i] - beat)
            if d < bestDist {
                bestDist = d
                bestIdx = i
            }
        }
        if bestIdx >= 0 && bestDist <= toleranceMs {
            used[bestIdx] = true
            offsets.append(tapTimesMs[bestIdx] - beat)
        }
    }

    let hits = offsets.count
    let expected = beatTimesMs.count
    let meanOffsetMs = hits > 0 ? offsets.reduce(0, +) / Double(hits) : 0
    let meanAbsOffsetMs = hits > 0 ? offsets.reduce(0) { $0 + abs($1) } / Double(hits) : 0
    return TapScore(
        hits: hits,
        expected: expected,
        meanAbsOffsetMs: meanAbsOffsetMs,
        meanOffsetMs: meanOffsetMs,
        correct: expected > 0 && Double(hits) / Double(expected) >= passRatio
    )
}

// ─── Session composer ───────────────────────────────────────

/// Options for `buildToGoSession` — mirrors the TS `opts` object.
public struct ToGoSessionOptions: Sendable {
    public var deck: [TheoryCard]?
    public var cardStates: [String: TheoryCardState]?
    public var now: Double?
    /// Quality the Coach is currently teaching — the ear side mirrors it.
    public var focusQuality: String?
    /// Coach unit the ear work should credit, so both senses move one map.
    public var focusUnitId: String?
    public var difficulty: Difficulty?
    /// Restrict to one discipline (the player picked it explicitly).
    public var only: ToGoKind?
    public var pref: AccidentalPreference?

    public init(deck: [TheoryCard]? = nil, cardStates: [String: TheoryCardState]? = nil,
                now: Double? = nil, focusQuality: String? = nil, focusUnitId: String? = nil,
                difficulty: Difficulty? = nil, only: ToGoKind? = nil,
                pref: AccidentalPreference? = nil) {
        self.deck = deck
        self.cardStates = cardStates
        self.now = now
        self.focusQuality = focusQuality
        self.focusUnitId = focusUnitId
        self.difficulty = difficulty
        self.only = only
        self.pref = pref
    }
}

/// Build a To-Go session.
///
/// Mixes the disciplines the device can actually run, weighted toward what the
/// player is currently learning: `focusQuality` (from the Coach frontier) makes
/// the ear side drill the very chord the piano side is working on.
public func buildToGoSession(
    _ rng: Rng,
    _ caps: ToGoCapabilities,
    _ opts: ToGoSessionOptions = ToGoSessionOptions(),
    _ params: ToGoParams = DEFAULT_TOGO_PARAMS
) -> ToGoSession {
    let pref = opts.pref ?? .flats
    let now = opts.now ?? 0
    let difficulty = opts.difficulty ?? .beginner
    let deck = opts.deck ?? []
    let cardStates = opts.cardStates ?? [:]

    // Which disciplines can run right now?
    var kinds: [ToGoKind]
    if let only = opts.only {
        kinds = [only]
    } else {
        kinds = ALL_TOGO_KINDS.filter { k in
            if k == .theory { return !deck.isEmpty } // silent — always allowed
            if !caps.audio { return false }          // everything else needs sound
            if k == .sing { return caps.mic }
            return true
        }
    }
    if kinds.isEmpty { kinds = [.theory] }

    let due = dueCards(deck, cardStates, now)
    var cardCursor = 0

    // Deal the disciplines round-robin so every one appears, then shuffle the
    // order — a session should feel varied, not like a fixed lap of the ladder.
    var order: [ToGoKind] = []
    for i in 0..<params.sessionLength { order.append(kinds[i % kinds.count]) }
    var si = order.count - 1
    while si > 0 {
        let j = Int(rng() * Double(si + 1))
        order.swapAt(si, min(j, si))
        si -= 1
    }

    var exercises: [ToGoExercise] = []
    for i in 0..<params.sessionLength {
        let kind = order[i]
        switch kind {
        case .interval:
            // Mix both directions: recognising a rising fifth does not mean you
            // can name a falling one, and players who only ever hear ascending
            // intervals learn the shape of the exercise instead of the sound.
            exercises.append(buildIntervalExercise(rng, params, pref, descending: rng() < 0.4))
        case .quality:
            exercises.append(buildQualityExercise(
                rng, params, pref, difficulty,
                unitId: opts.focusUnitId, forcedQuality: opts.focusQuality))
        case .progression:
            exercises.append(buildProgressionExercise(rng, params, pref))
        case .sing:
            exercises.append(buildSingExercise(rng, params, pref))
        case .time:
            exercises.append(buildTimeExercise(rng, params))
        case .lick:
            exercises.append(buildLickExercise(rng, params, pref))
        case .theory:
            let dueIdx = cardCursor % max(1, due.count)
            let card: TheoryCard? = dueIdx < due.count
                ? due[dueIdx]
                : { let i = cardCursor % max(1, deck.count); return i < deck.count ? deck[i] : nil }()
            cardCursor += 1
            if let card { exercises.append(buildTheoryExercise(card, rng, params)) }
        }
    }

    let single = opts.only != nil
    return ToGoSession(
        exercises: exercises,
        sayKey: single ? "togo.say.single" : "togo.say.mixed",
        sayParams: ["count": String(exercises.count), "kind": opts.only?.rawValue ?? ""],
        estMinutes: max(1, Int((Double(exercises.count) * 0.4).rounded()))
    )
}

// ─── Session summary ────────────────────────────────────────

public struct ToGoKindTally: Sendable, Equatable {
    public var total: Int
    public var correct: Int
    public init(total: Int, correct: Int) { self.total = total; self.correct = correct }
}

public struct ToGoSummary: Sendable, Equatable {
    public var total: Int
    public var correct: Int
    /// Accuracy 0–1.
    public var ratio: Double
    public var avgMs: Double
    /// Per-discipline breakdown, for the results screen.
    public var byKind: [String: ToGoKindTally]
    /// SM-2 quality (0–5) derived from the run — feeds card scheduling.
    public var srsQuality: Int

    public init(total: Int, correct: Int, ratio: Double, avgMs: Double,
                byKind: [String: ToGoKindTally], srsQuality: Int) {
        self.total = total
        self.correct = correct
        self.ratio = ratio
        self.avgMs = avgMs
        self.byKind = byKind
        self.srsQuality = srsQuality
    }
}

public func summarize(_ results: [ToGoResult]) -> ToGoSummary {
    let total = results.count
    let correct = results.filter { $0.correct }.count
    let avgMs = total > 0 ? results.reduce(0.0) { $0 + $1.ms } / Double(total) : 0
    var byKind: [String: ToGoKindTally] = [:]
    for r in results {
        var b = byKind[r.kind.rawValue] ?? ToGoKindTally(total: 0, correct: 0)
        b.total += 1
        if r.correct { b.correct += 1 }
        byKind[r.kind.rawValue] = b
    }
    let ratio = total > 0 ? Double(correct) / Double(total) : 0
    // Map accuracy onto SM-2's 0–5 so theory cards reschedule sensibly.
    var srsQuality = 0
    if ratio >= 0.95 { srsQuality = 5 }
    else if ratio >= 0.85 { srsQuality = 4 }
    else if ratio >= 0.7 { srsQuality = 3 }
    else if ratio >= 0.5 { srsQuality = 2 }
    else if ratio > 0 { srsQuality = 1 }

    return ToGoSummary(total: total, correct: correct, ratio: ratio, avgMs: avgMs,
                       byKind: byKind, srsQuality: srsQuality)
}

/// Reschedule every theory card the session touched.
public func applyResultsToCards(
    _ states: [String: TheoryCardState],
    _ results: [ToGoResult],
    _ now: Double,
    _ params: ToGoParams = DEFAULT_TOGO_PARAMS
) -> [String: TheoryCardState] {
    var next = states
    for r in results {
        guard let cardId = r.cardId else { continue }
        let prev = next[cardId] ?? newCardState(cardId, now)
        // Per-card quality: right & quick = 5, right = 4, wrong = 1.
        let quality = r.correct ? ((r.ms > 0 && r.ms < 4000) ? 5 : 4) : 1
        next[cardId] = scheduleCard(prev, quality, now, params)
    }
    return next
}
