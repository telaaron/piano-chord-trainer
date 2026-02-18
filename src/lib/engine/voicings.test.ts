import { describe, it, expect } from 'vitest';
import { getChordNotes, getVoicingNotes } from './voicings';

// ── getChordNotes ─────────────────────────────────────────────────────────────

describe('getChordNotes', () => {
	it('CMaj7 = [C, E, G, B]', () => {
		expect(getChordNotes('C', 'Maj7', 'sharps')).toEqual(['C', 'E', 'G', 'B']);
	});

	it('Dm7 = [D, F, A, C]', () => {
		expect(getChordNotes('D', 'm7', 'flats')).toEqual(['D', 'F', 'A', 'C']);
	});

	it('G7 = [G, B, D, F]', () => {
		expect(getChordNotes('G', '7', 'sharps')).toEqual(['G', 'B', 'D', 'F']);
	});

	it('Cdim7 = [C, Eb, Gb, A]', () => {
		expect(getChordNotes('C', 'dim7', 'flats')).toEqual(['C', 'Eb', 'Gb', 'A']);
	});

	it('Cm7b5 = [C, Eb, Gb, Bb]', () => {
		expect(getChordNotes('C', 'm7b5', 'flats')).toEqual(['C', 'Eb', 'Gb', 'Bb']);
	});

	it('returns [] for unknown quality', () => {
		expect(getChordNotes('C', 'unknown', 'sharps')).toEqual([]);
	});

	it('returns [] for unknown root', () => {
		expect(getChordNotes('X', 'Maj7', 'sharps')).toEqual([]);
	});
});

// ── getVoicingNotes ───────────────────────────────────────────────────────────

describe('getVoicingNotes — root', () => {
	it('returns all notes unchanged', () => {
		const notes = ['C', 'E', 'G', 'B'];
		expect(getVoicingNotes(notes, 'root')).toEqual(['C', 'E', 'G', 'B']);
	});
});

describe('getVoicingNotes — shell', () => {
	it('returns root, 3rd, 7th (indices 0, 1, 3)', () => {
		const notes = ['C', 'E', 'G', 'B'];
		expect(getVoicingNotes(notes, 'shell')).toEqual(['C', 'E', 'B']);
	});

	it('falls back to all notes for < 4 notes', () => {
		const notes = ['C', 'E', 'G'];
		expect(getVoicingNotes(notes, 'shell')).toEqual(['C', 'E', 'G']);
	});
});

describe('getVoicingNotes — half-shell', () => {
	it('returns 3rd, root, 7th (indices 1, 0, 3)', () => {
		const notes = ['C', 'E', 'G', 'B'];
		expect(getVoicingNotes(notes, 'half-shell')).toEqual(['E', 'C', 'B']);
	});
});

describe('getVoicingNotes — full', () => {
	it('returns root, 7th, 3rd, 5th reordering', () => {
		const notes = ['C', 'E', 'G', 'B'];
		// [0, last, 1, 2] = [C, B, E, G]
		expect(getVoicingNotes(notes, 'full')).toEqual(['C', 'B', 'E', 'G']);
	});
});

describe('getVoicingNotes — inversions', () => {
	it('inversion-1: 3rd on bottom (rotate left 1)', () => {
		const notes = ['C', 'E', 'G', 'B'];
		expect(getVoicingNotes(notes, 'inversion-1')).toEqual(['E', 'G', 'B', 'C']);
	});

	it('inversion-2: 5th on bottom (rotate left 2)', () => {
		const notes = ['C', 'E', 'G', 'B'];
		expect(getVoicingNotes(notes, 'inversion-2')).toEqual(['G', 'B', 'C', 'E']);
	});

	it('inversion-3: 7th on bottom (rotate left 3)', () => {
		const notes = ['C', 'E', 'G', 'B'];
		expect(getVoicingNotes(notes, 'inversion-3')).toEqual(['B', 'C', 'E', 'G']);
	});
});

describe('getVoicingNotes — rootless A', () => {
	it('returns 3rd, 5th, 7th, 9th', () => {
		// CMaj9 = [C, E, G, B, D]
		const notes = ['C', 'E', 'G', 'B', 'D'];
		// [3rd=E, 5th=G, 7th=B, 9th=D]
		expect(getVoicingNotes(notes, 'rootless-a')).toEqual(['E', 'G', 'B', 'D']);
	});
});

describe('getVoicingNotes — rootless B', () => {
	it('returns 7th, 9th, 3rd, 5th', () => {
		// CMaj9 = [C, E, G, B, D]
		// [7th=B, 9th=D, 3rd=E, 5th=G]
		const notes = ['C', 'E', 'G', 'B', 'D'];
		expect(getVoicingNotes(notes, 'rootless-b')).toEqual(['B', 'D', 'E', 'G']);
	});
});

describe('getVoicingNotes — edge cases', () => {
	it('returns [] for empty input', () => {
		expect(getVoicingNotes([], 'root')).toEqual([]);
	});

	it('inversion-3 on 3-note chord falls back gracefully', () => {
		const notes = ['C', 'E', 'G'];
		const result = getVoicingNotes(notes, 'inversion-3');
		expect(result).toHaveLength(3);
	});
});
