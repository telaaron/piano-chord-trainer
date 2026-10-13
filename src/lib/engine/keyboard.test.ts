import { describe, it, expect } from 'vitest';
import { KEYBOARD_START_MIDI, keyIndexToMidi, midiToKeyIndex } from './keyboard';

describe('on-screen keyboard ↔ MIDI', () => {
	it('starts at C3', () => {
		expect(KEYBOARD_START_MIDI).toBe(48);
		expect(keyIndexToMidi(0)).toBe(48);
	});

	it('a clicked key lights up as that same key, not an octave away', () => {
		for (let i = 0; i < 36; i++) {
			expect(midiToKeyIndex(keyIndexToMidi(i), 36)).toBe(i);
		}
	});

	it('notes off the visible keyboard map to nothing', () => {
		expect(midiToKeyIndex(47, 24)).toBeNull();
		expect(midiToKeyIndex(48 + 24, 24)).toBeNull();
	});
});
