import { describe, it, expect } from 'vitest';
import {
	CHORDS_BY_DIFFICULTY,
	CHORD_INTERVALS,
	CHORD_NOTATIONS,
	VOICING_LABELS,
} from './chords';

describe('CHORD_INTERVALS', () => {
	it('Maj7 = [0, 4, 7, 11]', () => {
		expect(CHORD_INTERVALS['Maj7']).toEqual([0, 4, 7, 11]);
	});

	it('m7 = [0, 3, 7, 10]', () => {
		expect(CHORD_INTERVALS['m7']).toEqual([0, 3, 7, 10]);
	});

	it('7 (dominant) = [0, 4, 7, 10]', () => {
		expect(CHORD_INTERVALS['7']).toEqual([0, 4, 7, 10]);
	});

	it('m7b5 = [0, 3, 6, 10]', () => {
		expect(CHORD_INTERVALS['m7b5']).toEqual([0, 3, 6, 10]);
	});

	it('dim7 = [0, 3, 6, 9]', () => {
		expect(CHORD_INTERVALS['dim7']).toEqual([0, 3, 6, 9]);
	});

	it('has 16 chord types', () => {
		expect(Object.keys(CHORD_INTERVALS)).toHaveLength(16);
	});
});

describe('CHORDS_BY_DIFFICULTY', () => {
	it('beginner has 5 chords', () => {
		expect(CHORDS_BY_DIFFICULTY.beginner).toHaveLength(5);
	});

	it('intermediate has 9 chords', () => {
		expect(CHORDS_BY_DIFFICULTY.intermediate).toHaveLength(9);
	});

	it('advanced has 15 chords', () => {
		expect(CHORDS_BY_DIFFICULTY.advanced).toHaveLength(15);
	});

	it('advanced includes dim7', () => {
		const names = CHORDS_BY_DIFFICULTY.advanced.map((c) => c.name);
		expect(names).toContain('dim7');
	});

	it('advanced includes m7b5', () => {
		const names = CHORDS_BY_DIFFICULTY.advanced.map((c) => c.name);
		expect(names).toContain('m7b5');
	});

	it('every chord in every difficulty has a matching CHORD_INTERVALS entry', () => {
		for (const [, chords] of Object.entries(CHORDS_BY_DIFFICULTY)) {
			for (const chord of chords) {
				expect(CHORD_INTERVALS[chord.name] ?? CHORD_INTERVALS[chord.display]).toBeDefined();
			}
		}
	});
});

describe('CHORD_NOTATIONS', () => {
	it('standard notation has dim7', () => {
		expect(CHORD_NOTATIONS.standard['dim7']).toBe('dim7');
	});

	it('symbols notation has dim7 as °7', () => {
		expect(CHORD_NOTATIONS.symbols['dim7']).toBe('°7');
	});

	it('short notation has dim7', () => {
		expect(CHORD_NOTATIONS.short['dim7']).toBe('dim7');
	});

	it('symbols notation uses Δ7 for Maj7', () => {
		expect(CHORD_NOTATIONS.symbols['Maj7']).toBe('Δ7');
	});

	it('symbols notation uses ø7 for m7b5', () => {
		expect(CHORD_NOTATIONS.symbols['m7b5']).toBe('ø7');
	});

	it('all three styles have the same set of keys', () => {
		const stdKeys = Object.keys(CHORD_NOTATIONS.standard).sort();
		const symKeys = Object.keys(CHORD_NOTATIONS.symbols).sort();
		const shtKeys = Object.keys(CHORD_NOTATIONS.short).sort();
		expect(stdKeys).toEqual(symKeys);
		expect(stdKeys).toEqual(shtKeys);
	});
});

describe('VOICING_LABELS', () => {
	it('has 9 voicing types', () => {
		expect(Object.keys(VOICING_LABELS)).toHaveLength(9);
	});

	it('inversion-1 is "1st Inversion"', () => {
		expect(VOICING_LABELS['inversion-1']).toBe('1st Inversion');
	});

	it('shell is "Shell Voicing"', () => {
		expect(VOICING_LABELS['shell']).toBe('Shell Voicing');
	});
});
