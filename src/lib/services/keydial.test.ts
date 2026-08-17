import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { buildKeyDial, CIRCLE_OF_FIFTHS, loadSettings } from './progress';
import type { SessionResult } from './progress';

/**
 * The clock is a claim about the player, so the arithmetic behind it has to be
 * exact: a key it calls slow must really be slow, and a key it leaves hollow
 * must really be untouched.
 */

function session(timings: Array<{ root: string; durationMs: number }>): SessionResult {
	return {
		chordTimings: timings.map((t) => ({ ...t, chord: t.root + 'maj7', correct: true })),
		settings: { voicing: 'shell' },
	} as unknown as SessionResult;
}

describe('buildKeyDial', () => {
	it('returns twelve keys in circle-of-fifths order', () => {
		const dial = buildKeyDial([]);
		expect(dial).toHaveLength(12);
		expect(dial.map((d) => d.root)).toEqual([...CIRCLE_OF_FIFTHS]);
		expect(dial[0].root).toBe('C');
	});

	it('leaves untouched keys null rather than zero', () => {
		// A key nobody has played must not read as instant. Zero would make an
		// empty dial look like mastery.
		const dial = buildKeyDial([session([{ root: 'C', durationMs: 500 }])]);
		const c = dial.find((d) => d.root === 'C')!;
		const gb = dial.find((d) => d.root === 'Gb')!;

		expect(c.avgMs).toBe(500);
		expect(gb.avgMs).toBeNull();
		expect(gb.count).toBe(0);
		expect(gb.fluent).toBe(false);
	});

	it('averages across sessions and voicings', () => {
		const dial = buildKeyDial([
			session([{ root: 'D', durationMs: 1000 }]),
			session([{ root: 'D', durationMs: 2000 }]),
		]);
		const d = dial.find((x) => x.root === 'D')!;
		expect(d.avgMs).toBe(1500);
		expect(d.count).toBe(2);
	});

	it('marks fluent at or under the threshold, not above', () => {
		const dial = buildKeyDial(
			[
				session([{ root: 'C', durationMs: 2000 }]),
				session([{ root: 'G', durationMs: 2001 }]),
			],
			2000,
		);
		expect(dial.find((d) => d.root === 'C')!.fluent).toBe(true);
		expect(dial.find((d) => d.root === 'G')!.fluent).toBe(false);
	});

	it('honours a custom threshold', () => {
		const history = [session([{ root: 'C', durationMs: 1500 }])];
		expect(buildKeyDial(history, 1000).find((d) => d.root === 'C')!.fluent).toBe(false);
		expect(buildKeyDial(history, 2000).find((d) => d.root === 'C')!.fluent).toBe(true);
	});

	it('ignores sessions without timings instead of throwing', () => {
		const dial = buildKeyDial([{ settings: { voicing: 'shell' } } as SessionResult]);
		expect(dial).toHaveLength(12);
		expect(dial.every((d) => d.avgMs === null)).toBe(true);
	});
});

// ─── loadSettings validation ────────────────────────────────

describe('loadSettings — stored values are policed at the boundary', () => {
	const KEY = 'chord-trainer-settings';

	const VALID = {
		difficulty: 'intermediate',
		notation: 'standard',
		voicing: 'shell',
		displayMode: 'always',
		accidentals: 'flats',
		notationSystem: 'german',
		totalChords: 12,
		progressionMode: '2-5-1',
		midiEnabled: false,
	};

	/* These tests run in vitest's node environment, which has no DOM. Rather
	   than pull in jsdom for one suite, stub the three methods loadSettings
	   touches — the behaviour under test is the validation, not the browser. */
	beforeEach(() => {
		const store = new Map<string, string>();
		(globalThis as { localStorage?: unknown }).localStorage = {
			getItem: (k: string) => store.get(k) ?? null,
			setItem: (k: string, v: string) => void store.set(k, v),
			removeItem: (k: string) => void store.delete(k),
			clear: () => store.clear(),
		};
	});

	afterEach(() => {
		delete (globalThis as { localStorage?: unknown }).localStorage;
	});

	it('returns null when nothing is stored', () => {
		expect(loadSettings()).toBeNull();
	});

	it('passes a valid profile through untouched', () => {
		localStorage.setItem(KEY, JSON.stringify(VALID));
		expect(loadSettings()).toEqual(VALID);
	});

	it('replaces a value this build does not recognise', () => {
		// The reported bug: "easy" is a KeyTier, never a Difficulty. Stored, it
		// reached the UI and rendered as the literal "settings.difficulty_easy".
		localStorage.setItem(KEY, JSON.stringify({ ...VALID, difficulty: 'easy' }));
		expect(loadSettings()!.difficulty).toBe('beginner');
	});

	it('corrects every enum field, not just difficulty', () => {
		localStorage.setItem(
			KEY,
			JSON.stringify({
				...VALID,
				difficulty: 'nonsense',
				notation: 'nonsense',
				voicing: 'nonsense',
				displayMode: 'nonsense',
				accidentals: 'nonsense',
				notationSystem: 'nonsense',
				progressionMode: 'nonsense',
			}),
		);
		const s = loadSettings()!;
		expect(s.difficulty).toBe('beginner');
		expect(s.notation).toBe('standard');
		expect(s.voicing).toBe('root');
		expect(s.displayMode).toBe('always');
		expect(s.accidentals).toBe('flats');
		expect(s.notationSystem).toBe('international');
		expect(s.progressionMode).toBe('random');
	});

	it('leaves non-enum fields alone', () => {
		localStorage.setItem(KEY, JSON.stringify({ ...VALID, totalChords: 37, customDegrees: [0, 3, 4] }));
		const s = loadSettings()!;
		expect(s.totalChords).toBe(37);
		expect(s.customDegrees).toEqual([0, 3, 4]);
	});

	it('does not invent a value for an absent optional field', () => {
		// inputMode is optional; absent must stay absent so the caller's own
		// default applies rather than this function guessing.
		const { ...withoutInput } = VALID;
		localStorage.setItem(KEY, JSON.stringify(withoutInput));
		expect(loadSettings()!.inputMode).toBeUndefined();
	});

	it('survives corrupt JSON', () => {
		localStorage.setItem(KEY, '{not json');
		expect(loadSettings()).toBeNull();
	});

	it('every fallback is itself a legal value', () => {
		// Guards the guard: a typo in a fallback would quietly write an invalid
		// value on every load, which is worse than the bug being fixed.
		localStorage.setItem(KEY, JSON.stringify({ ...VALID, difficulty: 'x', notation: 'x', voicing: 'x',
			displayMode: 'x', accidentals: 'x', notationSystem: 'x', progressionMode: 'x' }));
		const first = loadSettings()!;
		localStorage.setItem(KEY, JSON.stringify(first));
		// Feeding the corrected profile back in must change nothing.
		expect(loadSettings()).toEqual(first);
	});
});

describe('the dial reports a key by its WEAKEST voicing', () => {
	/** One session, one voicing, `count` attempts at a fixed speed. */
	function voiced(
		root: string,
		voicing: string,
		durationMs: number,
		count = 3,
		correct = true,
	): SessionResult {
		return {
			timestamp: 1000,
			chordTimings: Array.from({ length: count }, () => ({
				root,
				chord: `${root}Maj7`,
				durationMs,
				voicing,
				correct,
			})),
			settings: { voicing },
		} as unknown as SessionResult;
	}

	it('shows the slow voicing, not the flattering average', () => {
		// Three quick voicings and one disastrous one. Averaging every attempt gave
		// ~1800ms and painted the key fluent — while one voicing took six seconds.
		const history = [
			voiced('C', 'root', 400),
			voiced('C', 'shell', 450),
			voiced('C', 'half-shell', 400),
			voiced('C', 'rootless-a', 6000),
		];
		const entry = buildKeyDial(history, 2000).find((d) => d.root === 'C')!;

		expect(entry.avgMs).toBe(6000);
		expect(entry.worstVoicing).toBe('rootless-a');
		expect(entry.fluent).toBe(false);
	});

	it('carries the per-voicing breakdown for the hover detail', () => {
		const history = [voiced('F', 'root', 1200), voiced('F', 'shell', 3200)];
		const entry = buildKeyDial(history, 2000).find((d) => d.root === 'F')!;

		// Slowest first, so the hover names the problem before the rest.
		expect(entry.perVoicing?.map((v) => v.voicing)).toEqual(['shell', 'root']);
		expect(entry.perVoicing?.[0].avgMs).toBe(3200);
	});

	it('can ignore voicings the player has not unlocked yet', () => {
		const history = [voiced('G', 'root', 500), voiced('G', 'rootless-b', 7000)];
		const all = buildKeyDial(history, 2000).find((d) => d.root === 'G')!;
		const unlocked = buildKeyDial(history, 2000, ['root']).find((d) => d.root === 'G')!;

		expect(all.fluent).toBe(false);
		expect(unlocked.fluent).toBe(true);
	});

	it('does not call a key fluent when it is fast but wrong', () => {
		// 300ms and every attempt incorrect. Timing alone rated this fluent.
		const history = [voiced('A', 'root', 300, 3, false)];
		const entry = buildKeyDial(history, 2000).find((d) => d.root === 'A')!;

		expect(entry.avgMs).toBeLessThan(2000);
		expect(entry.fluent).toBe(false);
	});
});
