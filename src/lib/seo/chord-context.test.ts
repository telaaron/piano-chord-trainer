import { describe, expect, it } from 'vitest';
import { progressionFor } from './chord-context';

const names = (r: ReturnType<typeof progressionFor>) => r?.chords.map((c) => c.name);

describe('progressionFor', () => {
	it('places a maj7 chord as the I of its own key', () => {
		const p = progressionFor('C', 'Maj7')!;
		expect(p.key).toBe('C major');
		expect(p.role).toBe('I');
		expect(names(p)).toEqual(['Dm7', 'G7', 'Cmaj7']);
	});

	it('places a dominant chord as the V, a fourth up', () => {
		const p = progressionFor('Eb', '7')!;
		expect(p.key).toBe('A♭ major');
		expect(names(p)).toEqual(['B♭m7', 'E♭7', 'A♭maj7']);
	});

	it('keeps Db7 in G♭ major instead of an F♯/C♯ respelling', () => {
		const p = progressionFor('Db', '7')!;
		expect(p.key).toBe('G♭ major');
		expect(names(p)).toEqual(['A♭m7', 'D♭7', 'G♭maj7']);
		expect(p.enharmonic).toBeNull();
	});

	it('respells a minor ii whose key would be theoretical (Dbm7 → C♯m7 in B major)', () => {
		const p = progressionFor('Db', 'm7')!;
		expect(p.key).toBe('B major');
		expect(names(p)).toEqual(['C♯m7', 'F♯7', 'Bmaj7']);
		expect(p.enharmonic).toBe('C♯m7');
	});

	it('places m7b5 as the ii of a minor ii-V-i', () => {
		const p = progressionFor('D', 'm7b5')!;
		expect(p.key).toBe('C minor');
		expect(names(p)).toEqual(['Dm7♭5', 'G7', 'Cm6']);
	});

	it('uses a sharp minor key where the flat one is awkward (F♯m7♭5 → E minor)', () => {
		const p = progressionFor('F#', 'm7b5')!;
		expect(p.key).toBe('E minor');
		expect(names(p)).toEqual(['F♯m7♭5', 'B7', 'Em6']);
	});

	it('links to existing chord pages only', () => {
		const p = progressionFor('Db', 'm7')!;
		// C#m7 has no page (Dbm7 does), F#7 and Bmaj7 do.
		expect(p.chords.map((c) => c.slug)).toEqual(['dbm7', 'fsharp7', 'bmaj7']);
	});

	it('returns null for qualities it has no progression for', () => {
		expect(progressionFor('C', '13')).toBeNull();
	});
});
