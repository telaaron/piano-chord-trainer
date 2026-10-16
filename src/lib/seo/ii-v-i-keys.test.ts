import { describe, expect, it } from 'vitest';
import { IIVI_KEYS, buildIIVITable } from './ii-v-i-keys';

describe('ii-V-I in all 12 keys', () => {
	it('covers 12 distinct keys in circle-of-fourths order starting on C', () => {
		expect(IIVI_KEYS.map((k) => k.key)).toEqual([
			'C', 'F', 'B♭', 'E♭', 'A♭', 'D♭', 'G♭', 'B', 'E', 'A', 'D', 'G',
		]);
	});

	it('spells the C major row as Dm7 – G7 – Cmaj7 with shell voicings', () => {
		const c = buildIIVITable('shell')[0];
		expect(c.chords.map((ch) => ch.name)).toEqual(['Dm7', 'G7', 'Cmaj7']);
		expect(c.chords.map((ch) => ch.notes)).toEqual([
			['D', 'F', 'C'],
			['G', 'B', 'F'],
			['C', 'E', 'B'],
		]);
	});

	it('alternates rootless A/B so the voicings move by step (ii A → V B → I A)', () => {
		const c = buildIIVITable('rootless-ab')[0];
		expect(c.chords.map((ch) => ch.notes)).toEqual([
			['F', 'A', 'C', 'E'], // Dm7 A: 3 5 7 9
			['F', 'A', 'B', 'D'], // G7 B: 7 9 3 5
			['E', 'G', 'B', 'D'], // Cmaj7 A: 3 5 7 9
		]);
	});

	it('uses key-correct spelling in flat and sharp keys', () => {
		const gb = buildIIVITable('shell').find((r) => r.key === 'G♭')!;
		expect(gb.chords.map((ch) => ch.name)).toEqual(['A♭m7', 'D♭7', 'G♭maj7']);
		expect(gb.chords[1].notes).toEqual(['Db', 'F', 'Cb']);

		const b = buildIIVITable('shell').find((r) => r.key === 'B')!;
		expect(b.chords.map((ch) => ch.name)).toEqual(['C♯m7', 'F♯7', 'Bmaj7']);
		expect(b.chords[2].notes).toEqual(['B', 'D#', 'A#']);
	});

	it('links only to chord pages that exist', () => {
		const rows = buildIIVITable('shell');
		const c = rows[0];
		expect(c.chords.map((ch) => ch.slug)).toEqual(['dm7', 'g7', 'cmaj7']);
		const b = rows.find((r) => r.key === 'B')!;
		// There is a /chords/fsharp7 page but no C#m7 page.
		expect(b.chords[0].slug).toBeNull();
		expect(b.chords[1].slug).toBe('fsharp7');
	});
});
