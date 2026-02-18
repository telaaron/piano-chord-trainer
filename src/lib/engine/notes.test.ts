import { describe, it, expect } from 'vitest';
import {
	NOTES_SHARPS,
	NOTES_FLATS,
	ENHARMONIC_MAP,
	getNoteArray,
	getNotePool,
	noteToSemitone,
	getNoteName,
	convertNoteName,
	convertChordNotation,
} from './notes';

describe('NOTES_SHARPS / NOTES_FLATS', () => {
	it('has 12 sharps notes', () => {
		expect(NOTES_SHARPS).toHaveLength(12);
	});

	it('has 12 flats notes', () => {
		expect(NOTES_FLATS).toHaveLength(12);
	});

	it('starts with C', () => {
		expect(NOTES_SHARPS[0]).toBe('C');
		expect(NOTES_FLATS[0]).toBe('C');
	});
});

describe('ENHARMONIC_MAP', () => {
	it('maps C# to Db and back', () => {
		expect(ENHARMONIC_MAP['C#']).toBe('Db');
		expect(ENHARMONIC_MAP['Db']).toBe('C#');
	});

	it('maps Bb to A# and back', () => {
		expect(ENHARMONIC_MAP['Bb']).toBe('A#');
		expect(ENHARMONIC_MAP['A#']).toBe('Bb');
	});
});

describe('noteToSemitone', () => {
	it('returns 0 for C', () => {
		expect(noteToSemitone('C')).toBe(0);
	});

	it('returns 4 for E', () => {
		expect(noteToSemitone('E')).toBe(4);
	});

	it('returns 7 for G', () => {
		expect(noteToSemitone('G')).toBe(7);
	});

	it('returns 10 for Bb', () => {
		expect(noteToSemitone('Bb')).toBe(10);
	});

	it('returns 10 for A# (enharmonic)', () => {
		expect(noteToSemitone('A#')).toBe(10);
	});

	it('returns 6 for Gb', () => {
		expect(noteToSemitone('Gb')).toBe(6);
	});

	it('returns -1 for unknown note', () => {
		expect(noteToSemitone('X')).toBe(-1);
	});
});

describe('getNoteName', () => {
	it('returns E for root=C, interval=4, sharps', () => {
		expect(getNoteName(0, 4, 'sharps')).toBe('E');
	});

	it('returns G for root=C, interval=7, sharps', () => {
		expect(getNoteName(0, 7, 'sharps')).toBe('G');
	});

	it('returns Bb for root=C, interval=10, flats', () => {
		expect(getNoteName(0, 10, 'flats')).toBe('Bb');
	});

	it('wraps around octave correctly (C + 12 = C)', () => {
		expect(getNoteName(0, 12, 'sharps')).toBe('C');
	});
});

describe('getNoteArray', () => {
	it('returns NOTES_FLATS for flats preference', () => {
		expect(getNoteArray('flats')).toBe(NOTES_FLATS);
	});

	it('returns NOTES_SHARPS for sharps preference', () => {
		expect(getNoteArray('sharps')).toBe(NOTES_SHARPS);
	});

	it('returns NOTES_SHARPS for both preference', () => {
		expect(getNoteArray('both')).toBe(NOTES_SHARPS);
	});
});

describe('getNotePool', () => {
	it('returns 12 notes for sharps', () => {
		expect(getNotePool('sharps')).toHaveLength(12);
	});

	it('returns 12 notes for flats', () => {
		expect(getNotePool('flats')).toHaveLength(12);
	});

	it('returns more than 12 notes for both (includes enharmonics)', () => {
		expect(getNotePool('both').length).toBeGreaterThan(12);
	});
});

describe('convertNoteName', () => {
	it('converts B to H in german notation', () => {
		expect(convertNoteName('B', 'german')).toBe('H');
	});

	it('converts Bb to B in german notation', () => {
		expect(convertNoteName('Bb', 'german')).toBe('B');
	});

	it('leaves other notes unchanged in german notation', () => {
		expect(convertNoteName('C', 'german')).toBe('C');
		expect(convertNoteName('F#', 'german')).toBe('F#');
	});

	it('leaves notes unchanged in international notation', () => {
		expect(convertNoteName('B', 'international')).toBe('B');
		expect(convertNoteName('Bb', 'international')).toBe('Bb');
	});
});

describe('convertChordNotation', () => {
	it('converts Bb chords to B in german notation', () => {
		expect(convertChordNotation('BbMaj7', 'german')).toBe('BMaj7');
	});

	it('converts B chords to H in german notation', () => {
		expect(convertChordNotation('BMaj7', 'german')).toBe('HMaj7');
	});

	it('does not convert Bb to H in german notation', () => {
		expect(convertChordNotation('BbMaj7', 'german')).toBe('BMaj7');
	});

	it('leaves chords unchanged in international notation', () => {
		expect(convertChordNotation('BbMaj7', 'international')).toBe('BbMaj7');
		expect(convertChordNotation('BMaj7', 'international')).toBe('BMaj7');
	});
});
