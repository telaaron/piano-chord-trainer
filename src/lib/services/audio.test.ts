import { describe, it, expect } from 'vitest';
import { earVoicing } from './audio';

describe('earVoicing', () => {
	it('doubles the root an octave below and lets it lead', () => {
		const v = earVoicing(['C3', 'E3', 'G3', 'B3']);
		expect(v.notes).toEqual(['C2', 'C3', 'E3', 'G3', 'B3']);
		// Root voices louder than every upper voice, so the 7th no longer dominates.
		const [bass, root, ...upper] = v.velocities;
		for (const u of upper) {
			expect(u).toBeLessThan(root);
			expect(u).toBeLessThan(bass);
		}
	});

	it('keeps accidentals and octave numbers right', () => {
		expect(earVoicing(['Bb3', 'D4', 'F4', 'A4']).notes[0]).toBe('Bb2');
		expect(earVoicing(['F#3', 'A#3', 'C#4']).notes[0]).toBe('F#2');
	});
});
