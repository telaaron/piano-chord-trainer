import { describe, it, expect } from 'vitest';
import {
	buildIntervalExercise,
	buildQualityExercise,
	buildProgressionExercise,
	buildSingExercise,
	buildTimeExercise,
	buildLickExercise,
	buildTheoryExercise,
	buildTheoryDeck,
	buildToGoSession,
	gradeChoice,
	gradeSing,
	gradeNotes,
	gradeTaps,
	scheduleCard,
	newCardState,
	dueCards,
	summarize,
	applyResultsToCards,
	DEFAULT_TOGO_PARAMS,
	INTERVAL_LADDER,
	type ToGoResult,
	type TheoryCardState,
} from './togo';
import { noteToSemitone } from './notes';

/** Deterministic rng: cycles a fixed sequence so every test is reproducible. */
function seeded(seq: number[] = [0.1, 0.5, 0.9, 0.3, 0.7, 0.05, 0.45, 0.85]) {
	let i = 0;
	return () => seq[i++ % seq.length];
}

const CAPS_ALL = { mic: true, audio: true };

// ─── Exercise construction ──────────────────────────────────

describe('exercise builders', () => {
	it('interval: plays two notes in sequence and offers the right label', () => {
		const ex = buildIntervalExercise(seeded());
		expect(ex.kind).toBe('interval');
		expect(ex.play.type).toBe('sequence');
		if (ex.play.type === 'sequence') expect(ex.play.notes).toHaveLength(2);
		expect(ex.options).toContain(ex.answerLabel);
		expect(ex.options[ex.answerIndex]).toBe(ex.answerLabel);
	});

	/**
	 * These three come from play-testing: a major seventh sounded as a semitone
	 * DOWN, and an octave played the same note twice. Both were pitch-class
	 * arithmetic — the notes carried no octave, so "distance" had no direction.
	 * Asserting the label was not enough; the pitches themselves need checking.
	 */
	describe('interval: the notes actually sound the interval', () => {
		/** "Bb4" → absolute semitone, so tests can measure real distance. */
		function abs(note: string): number {
			const m = note.match(/^([A-G][b#]?)(-?\d+)$/);
			if (!m) throw new Error(`not a pitched note: ${note}`);
			return noteToSemitone(m[1]) + 12 * Number(m[2]);
		}

		function notesOf(ex: ReturnType<typeof buildIntervalExercise>): string[] {
			if (ex.play.type !== 'sequence') throw new Error('expected a sequence');
			return ex.play.notes;
		}

		it('every ascending interval rises by exactly its semitone count', () => {
			for (let depth = 2; depth <= INTERVAL_LADDER.length; depth++) {
				const ex = buildIntervalExercise(seeded(), undefined, 'flats', depth);
				const entry = INTERVAL_LADDER.find((i) => i.label === ex.answerLabel)!;
				const [a, b] = notesOf(ex);
				expect(abs(b) - abs(a)).toBe(entry.semitones);
			}
		});

		it('every descending interval falls by exactly its semitone count', () => {
			for (let depth = 2; depth <= INTERVAL_LADDER.length; depth++) {
				const ex = buildIntervalExercise(seeded(), undefined, 'flats', depth, true);
				const entry = INTERVAL_LADDER.find((i) => i.label === ex.answerLabel)!;
				const [a, b] = notesOf(ex);
				expect(abs(b) - abs(a)).toBe(-entry.semitones);
			}
		});

		it('never sounds the same pitch twice — an octave is 12 apart, not 0', () => {
			// The reported bug: 12 % 12 === 0, so both notes were identical.
			for (let depth = 2; depth <= INTERVAL_LADDER.length; depth++) {
				for (const down of [false, true]) {
					const ex = buildIntervalExercise(seeded(), undefined, 'flats', depth, down);
					const [a, b] = notesOf(ex);
					expect(a).not.toBe(b);
					expect(Math.abs(abs(b) - abs(a))).toBeGreaterThan(0);
				}
			}
		});

		it('carries an octave on both notes, so playback cannot guess', () => {
			const ex = buildIntervalExercise(seeded());
			for (const n of notesOf(ex)) expect(n).toMatch(/^[A-G][b#]?-?\d+$/);
		});

		it('distinguishes the two directions in its id and prompt', () => {
			const up = buildIntervalExercise(seeded(), undefined, 'flats', 4, false);
			const down = buildIntervalExercise(seeded(), undefined, 'flats', 4, true);
			expect(up.id).toContain('up');
			expect(down.id).toContain('down');
			expect(up.promptKey).not.toBe(down.promptKey);
		});
	});

	it('quality: sounds a real chord and the answer is among the options', () => {
		const ex = buildQualityExercise(seeded());
		expect(ex.play.type).toBe('chord');
		if (ex.play.type === 'chord') expect(ex.play.notes.length).toBeGreaterThanOrEqual(3);
		expect(ex.options[ex.answerIndex]).toBe(ex.answerLabel);
	});

	it('quality: honours a focus quality so the ear mirrors the piano', () => {
		const ex = buildQualityExercise(seeded(), DEFAULT_TOGO_PARAMS, 'flats', 'beginner', 'root|m7|easy', 'm7');
		expect(ex.answerLabel).toBe('m7');
		expect(ex.unitId).toBe('root|m7|easy');
	});

	it('progression: sounds real CHORDS, not a run of single notes', () => {
		const ex = buildProgressionExercise(seeded());
		// A cadence must be heard as chords — flattening it would destroy the
		// very thing the exercise tests.
		expect(ex.play.type).toBe('chords');
		if (ex.play.type === 'chords') {
			expect(ex.play.chords.length).toBeGreaterThanOrEqual(2);
			// Every step is a genuine chord, not a lone note.
			expect(ex.play.chords.every((c) => c.length >= 3)).toBe(true);
		}
		expect(ex.options[ex.answerIndex]).toBe(ex.answerLabel);
	});

	it('progression: one chord per roman numeral in the shape', () => {
		const ex = buildProgressionExercise(seeded());
		// The id carries the degrees; the playback must match them 1:1.
		const degrees = ex.id.split('|')[2].split('-');
		if (ex.play.type === 'chords') expect(ex.play.chords).toHaveLength(degrees.length);
	});

	it('sing: holds a drone and targets a pitch class', () => {
		const ex = buildSingExercise(seeded());
		expect(ex.play.type).toBe('drone');
		expect(ex.input.type).toBe('sing');
		if (ex.input.type === 'sing') {
			expect(ex.input.targetPitchClass).toBeGreaterThanOrEqual(0);
			expect(ex.input.targetPitchClass).toBeLessThan(12);
		}
	});

	it('time: asks for a pulse and names the beats to tap', () => {
		const ex = buildTimeExercise(seeded());
		expect(ex.play.type).toBe('pulse');
		expect(ex.input.type).toBe('tap');
		if (ex.input.type === 'tap') expect(ex.input.onBeats.length).toBeGreaterThan(0);
	});

	it('lick: plays a phrase and expects it tapped back', () => {
		const ex = buildLickExercise(seeded());
		expect(ex.play.type).toBe('sequence');
		expect(ex.input.type).toBe('notes');
		if (ex.play.type === 'sequence' && ex.input.type === 'notes') {
			expect(ex.input.targetPitchClasses).toHaveLength(ex.play.notes.length);
		}
	});

	it('theory: is silent — works with the sound off', () => {
		const deck = buildTheoryDeck();
		const ex = buildTheoryExercise(deck[0], seeded());
		expect(ex.play.type).toBe('silent');
		expect(ex.cardId).toBe(deck[0].id);
	});
});

describe('options', () => {
	it('always contain the answer exactly once and are distinct', () => {
		for (let i = 0; i < 20; i++) {
			const rng = seeded([i / 20, 0.3, 0.66, 0.12, 0.98, 0.44]);
			const ex = buildIntervalExercise(rng);
			const hits = ex.options.filter((o) => o === ex.answerLabel).length;
			expect(hits).toBe(1);
			expect(new Set(ex.options).size).toBe(ex.options.length);
		}
	});

	it('offer distractors + the answer', () => {
		const ex = buildIntervalExercise(seeded());
		expect(ex.options.length).toBe(DEFAULT_TOGO_PARAMS.distractors + 1);
	});
});

// ─── Grading ────────────────────────────────────────────────

describe('gradeChoice', () => {
	it('accepts the answer index and rejects others', () => {
		const ex = buildIntervalExercise(seeded());
		expect(gradeChoice(ex, ex.answerIndex)).toBe(true);
		expect(gradeChoice(ex, (ex.answerIndex + 1) % ex.options.length)).toBe(false);
	});
});

describe('gradeSing', () => {
	it('accepts the target pitch class in any octave', () => {
		const ex = buildSingExercise(seeded());
		const pc = ex.input.type === 'sing' ? ex.input.targetPitchClass : 0;
		expect(gradeSing(ex, [pc + 60])).toBe(true); // one octave
		expect(gradeSing(ex, [pc + 72])).toBe(true); // another
		expect(gradeSing(ex, [pc + 61])).toBe(false); // a semitone off
	});

	it('accepts when the right note is among several detected', () => {
		const ex = buildSingExercise(seeded());
		const pc = ex.input.type === 'sing' ? ex.input.targetPitchClass : 0;
		expect(gradeSing(ex, [pc + 61, pc + 60])).toBe(true);
	});
});

describe('gradeNotes', () => {
	it('matches the phrase as a pitch-class set, octave-agnostic', () => {
		const ex = buildLickExercise(seeded());
		const target = ex.input.type === 'notes' ? ex.input.targetPitchClasses : [];
		expect(gradeNotes(ex, target.map((p) => p + 60))).toBe(true);
		expect(gradeNotes(ex, target.slice(0, -1))).toBe(false); // missing a note
	});
});

describe('gradeTaps', () => {
	it('scores dead-on taps as perfect', () => {
		const beats = [0, 500, 1000, 1500];
		const s = gradeTaps(beats, [0, 500, 1000, 1500], 120);
		expect(s.hits).toBe(4);
		expect(s.correct).toBe(true);
		expect(s.meanAbsOffsetMs).toBe(0);
	});

	it('reports SIGNED offset — rushing reads negative, dragging positive', () => {
		const beats = [0, 500, 1000];
		const rushing = gradeTaps(beats, [-40, 460, 960], 120);
		expect(rushing.meanOffsetMs).toBeLessThan(0);
		const dragging = gradeTaps(beats, [40, 540, 1040], 120);
		expect(dragging.meanOffsetMs).toBeGreaterThan(0);
		// Both are equally tight in absolute terms.
		expect(rushing.meanAbsOffsetMs).toBeCloseTo(dragging.meanAbsOffsetMs, 5);
	});

	it('ignores taps outside the tolerance window', () => {
		const s = gradeTaps([0, 500], [0, 900], 120);
		expect(s.hits).toBe(1);
		expect(s.correct).toBe(false); // 1/2 < 0.7
	});

	it('never lets one tap score two beats', () => {
		// A single tap between two beats must satisfy only the nearer one.
		const s = gradeTaps([0, 100], [50], 120);
		expect(s.hits).toBe(1);
	});

	it('counts missed beats against you', () => {
		const s = gradeTaps([0, 500, 1000, 1500], [0, 500], 120);
		expect(s.hits).toBe(2);
		expect(s.expected).toBe(4);
		expect(s.correct).toBe(false);
	});

	it('passes at the 70% ratio', () => {
		const s = gradeTaps([0, 500, 1000, 1500], [0, 500, 1000], 120);
		expect(s.hits / s.expected).toBeGreaterThanOrEqual(0.7);
		expect(s.correct).toBe(true);
	});
});

// ─── Theory deck + SRS ──────────────────────────────────────

describe('theory deck', () => {
	it('generates cards with distinct ids and real answers', () => {
		const deck = buildTheoryDeck();
		expect(deck.length).toBeGreaterThan(20);
		expect(new Set(deck.map((c) => c.id)).size).toBe(deck.length);
		for (const c of deck) {
			expect(c.answer.length).toBeGreaterThan(0);
			expect(c.distractors.every((d) => d !== c.answer)).toBe(true);
		}
	});

	it('is deterministic', () => {
		expect(buildTheoryDeck()).toEqual(buildTheoryDeck());
	});

	it('knows real theory — the tritone sub of C7 is Gb7', () => {
		const deck = buildTheoryDeck();
		const card = deck.find((c) => c.id === 'tritone|C');
		expect(card?.answer).toBe('Gb7');
	});

	it('knows the relative minor of C is Am', () => {
		const deck = buildTheoryDeck();
		expect(deck.find((c) => c.id === 'relminor|C')?.answer).toBe('Am');
	});

	it('knows the 3rd of C7 is E', () => {
		const deck = buildTheoryDeck();
		expect(deck.find((c) => c.id === 'degree|C|7|4')?.answer).toBe('E');
	});
});

describe('SM-2 scheduling', () => {
	it('lengthens the interval on success and resets it on failure', () => {
		const now = 1_000_000;
		let s = newCardState('x', now);
		s = scheduleCard(s, 5, now); // first success
		expect(s.interval).toBe(1);
		s = scheduleCard(s, 5, now); // second
		expect(s.interval).toBe(3);
		const grown = scheduleCard(s, 5, now);
		expect(grown.interval).toBeGreaterThan(3);
		const lapsed = scheduleCard(grown, 1, now);
		expect(lapsed.interval).toBe(1);
		expect(lapsed.repetitions).toBe(0);
	});

	it('never lets ease fall below the floor', () => {
		const now = 0;
		let s = newCardState('x', now);
		for (let i = 0; i < 20; i++) s = scheduleCard(s, 0, now);
		expect(s.ease).toBeGreaterThanOrEqual(DEFAULT_TOGO_PARAMS.minEase);
	});

	it('schedules the next review into the future', () => {
		const now = 5_000_000;
		const s = scheduleCard(newCardState('x', now), 5, now);
		expect(s.nextReview).toBeGreaterThan(now);
	});
});

describe('dueCards', () => {
	it('treats never-seen cards as due', () => {
		const deck = buildTheoryDeck();
		expect(dueCards(deck, {}, 0).length).toBe(deck.length);
	});

	it('hides cards scheduled for later', () => {
		const deck = buildTheoryDeck().slice(0, 3);
		const now = 1_000_000;
		const states: Record<string, TheoryCardState> = {};
		for (const c of deck) states[c.id] = scheduleCard(newCardState(c.id, now), 5, now);
		expect(dueCards(deck, states, now)).toHaveLength(0);
		// …and shows them again once the date arrives.
		const later = now + 2 * 24 * 60 * 60 * 1000;
		expect(dueCards(deck, states, later).length).toBe(3);
	});
});

// ─── Session composition ────────────────────────────────────

describe('buildToGoSession', () => {
	it('fills a session of the configured length', () => {
		const s = buildToGoSession(seeded(), CAPS_ALL, { deck: buildTheoryDeck() });
		expect(s.exercises).toHaveLength(DEFAULT_TOGO_PARAMS.sessionLength);
	});

	it('drops sing when there is no mic', () => {
		const s = buildToGoSession(seeded(), { mic: false, audio: true }, { deck: buildTheoryDeck() });
		expect(s.exercises.some((e) => e.kind === 'sing')).toBe(false);
	});

	it('falls back to silent theory cards when audio is off', () => {
		const s = buildToGoSession(seeded(), { mic: false, audio: false }, { deck: buildTheoryDeck() });
		expect(s.exercises.length).toBeGreaterThan(0);
		expect(s.exercises.every((e) => e.kind === 'theory')).toBe(true);
	});

	it('still produces a session with no theory deck at all', () => {
		const s = buildToGoSession(seeded(), CAPS_ALL, {});
		expect(s.exercises.length).toBeGreaterThan(0);
		expect(s.exercises.some((e) => e.kind === 'theory')).toBe(false);
	});

	it('honours a single-discipline request', () => {
		const s = buildToGoSession(seeded(), CAPS_ALL, { only: 'interval' });
		expect(s.exercises.every((e) => e.kind === 'interval')).toBe(true);
		expect(s.sayKey).toBe('togo.say.single');
	});

	it('mirrors the Coach focus quality on the ear side', () => {
		const s = buildToGoSession(seeded(), CAPS_ALL, { only: 'quality', focusQuality: 'm7' });
		expect(s.exercises.every((e) => e.answerLabel === 'm7')).toBe(true);
	});

	it('still covers every available discipline after shuffling', () => {
		const s = buildToGoSession(seeded(), CAPS_ALL, { deck: buildTheoryDeck() });
		const kinds = new Set(s.exercises.map((e) => e.kind));
		// 8 slots dealt round-robin over 7 disciplines → every one appears.
		expect(kinds.size).toBe(7);
	});

	it('does not always run the disciplines in ladder order', () => {
		// Two different seeds should not produce the same running order.
		const a = buildToGoSession(seeded([0.1, 0.5, 0.9, 0.3]), CAPS_ALL, { deck: buildTheoryDeck() });
		const b = buildToGoSession(seeded([0.8, 0.2, 0.05, 0.62]), CAPS_ALL, { deck: buildTheoryDeck() });
		expect(a.exercises.map((e) => e.kind)).not.toEqual(b.exercises.map((e) => e.kind));
	});

	it('is reproducible for a given seed', () => {
		const a = buildToGoSession(seeded(), CAPS_ALL, { deck: buildTheoryDeck() });
		const b = buildToGoSession(seeded(), CAPS_ALL, { deck: buildTheoryDeck() });
		expect(a.exercises.map((e) => e.id)).toEqual(b.exercises.map((e) => e.id));
	});
});

// ─── Summary + card application ─────────────────────────────

describe('summarize', () => {
	it('counts accuracy and breaks it down per discipline', () => {
		const results: ToGoResult[] = [
			{ exerciseId: 'a', kind: 'interval', correct: true, ms: 1000 },
			{ exerciseId: 'b', kind: 'interval', correct: false, ms: 2000 },
			{ exerciseId: 'c', kind: 'theory', correct: true, ms: 900 },
		];
		const s = summarize(results);
		expect(s.total).toBe(3);
		expect(s.correct).toBe(2);
		expect(s.byKind.interval).toEqual({ total: 2, correct: 1 });
		expect(s.byKind.theory).toEqual({ total: 1, correct: 1 });
		expect(s.avgMs).toBeCloseTo(1300, 0);
	});

	it('maps accuracy onto an SM-2 quality', () => {
		const perfect = summarize([{ exerciseId: 'a', kind: 'theory', correct: true, ms: 1 }]);
		expect(perfect.srsQuality).toBe(5);
		const failed = summarize([{ exerciseId: 'a', kind: 'theory', correct: false, ms: 1 }]);
		expect(failed.srsQuality).toBe(0);
	});

	it('handles an empty run without dividing by zero', () => {
		const s = summarize([]);
		expect(s.ratio).toBe(0);
		expect(s.avgMs).toBe(0);
	});
});

describe('applyResultsToCards', () => {
	it('reschedules only the cards the session touched', () => {
		const now = 2_000_000;
		const next = applyResultsToCards({}, [
			{ exerciseId: 'x', kind: 'theory', correct: true, ms: 1200, cardId: 'tritone|C' },
			{ exerciseId: 'y', kind: 'interval', correct: true, ms: 1200 }, // no card
		], now);
		expect(Object.keys(next)).toEqual(['tritone|C']);
		expect(next['tritone|C'].nextReview).toBeGreaterThan(now);
	});

	it('sends a missed card back to tomorrow', () => {
		const now = 2_000_000;
		let states = applyResultsToCards({}, [
			{ exerciseId: 'x', kind: 'theory', correct: true, ms: 1000, cardId: 'tritone|C' },
		], now);
		states = applyResultsToCards(states, [
			{ exerciseId: 'x', kind: 'theory', correct: true, ms: 1000, cardId: 'tritone|C' },
		], now);
		const grown = states['tritone|C'].interval;
		const lapsed = applyResultsToCards(states, [
			{ exerciseId: 'x', kind: 'theory', correct: false, ms: 9000, cardId: 'tritone|C' },
		], now);
		expect(grown).toBeGreaterThan(1);
		expect(lapsed['tritone|C'].interval).toBe(1);
	});
});

// ─── Vocabulary sanity ──────────────────────────────────────

describe('musical vocabulary', () => {
	it('covers all twelve intervals', () => {
		expect(new Set(INTERVAL_LADDER.map((i) => i.semitones)).size).toBe(12);
	});

	it('orders the interval ladder easiest-first (octave and 5th before the tritone)', () => {
		const idx = (s: number) => INTERVAL_LADDER.findIndex((i) => i.semitones === s);
		expect(idx(12)).toBeLessThan(idx(6));
		expect(idx(7)).toBeLessThan(idx(6));
	});
});
