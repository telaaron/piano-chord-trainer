import { describe, it, expect } from 'vitest';
import { buildKeyDial, CIRCLE_OF_FIFTHS } from './progress';
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
