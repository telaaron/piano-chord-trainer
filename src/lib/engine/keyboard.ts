// Keyboard helpers – map chord notes to keyboard key indices

import { NOTES_SHARPS, NOTES_FLATS, ENHARMONIC_MAP, noteToSemitone, type AccidentalPreference } from './notes';
import type { ChordWithNotes } from './voicings';

/** Standard keyboard sizes */
export const OCTAVE_CONFIGS = {
	2: { whiteKeys: 14, chromaticCount: 24 },
	3: { whiteKeys: 21, chromaticCount: 36 },
} as const;

export type OctaveCount = keyof typeof OCTAVE_CONFIGS;

/** Default 2-octave keyboard for backward compat */
export const WHITE_KEY_COUNT = 14;
export const CHROMATIC_COUNT = 24;

/** White key chromatic indices: C=0, D=2, E=4, F=5, G=7, A=9, B=11, then +12 */
export const WHITE_KEY_CHROMATIC = [0, 2, 4, 5, 7, 9, 11] as const;

/** Get chromatic index for white key i (0-based) */
export function whiteKeyChromaticIndex(i: number): number {
	const octave = Math.floor(i / 7);
	const noteInOctave = WHITE_KEY_CHROMATIC[i % 7];
	return octave * 12 + noteInOctave;
}

/**
 * Generate black key layout for a given number of octaves.
 * idx = chromatic index, pos = position in white-key units (for CSS left%)
 */
export function generateBlackKeys(octaves: OctaveCount): readonly { idx: number; pos: number }[] {
	// Black keys within one octave: C#(1,1) D#(3,2) F#(6,4) G#(8,5) A#(10,6)
	const perOctave = [
		{ offset: 1, whitePos: 1 },
		{ offset: 3, whitePos: 2 },
		{ offset: 6, whitePos: 4 },
		{ offset: 8, whitePos: 5 },
		{ offset: 10, whitePos: 6 },
	];
	const keys: { idx: number; pos: number }[] = [];
	for (let oct = 0; oct < octaves; oct++) {
		for (const k of perOctave) {
			keys.push({ idx: oct * 12 + k.offset, pos: oct * 7 + k.whitePos });
		}
	}
	return keys;
}

/** Static 2-octave black keys for backward compat */
export const BLACK_KEYS = generateBlackKeys(2);

/**
 * Find the pitch-class (0–11) for a note name, checking enharmonics.
 */
function noteToPitchClass(note: string, baseNotes: readonly string[]): number {
	let idx = baseNotes.indexOf(note as any);
	if (idx !== -1) return idx;
	const enh = ENHARMONIC_MAP[note];
	if (enh) idx = baseNotes.indexOf(enh as any);
	return idx;
}

/** Result of placing voicing notes on a keyboard */
export interface KeyboardLayout {
	/** Chromatic indices of highlighted keys */
	activeIndices: Set<number>;
	/** How many octaves needed to fit all notes */
	octaves: OctaveCount;
}

/**
 * Build the set of chromatic indices and determine keyboard size.
 *
 * ONLY highlights notes present in chordData.voicing — NOT the full chord.
 * Voicing order (bottom-to-top) is preserved for ascending placement.
 * If notes don't fit in 2 octaves, automatically expands to 3.
 */
export function getKeyboardLayout(chordData: ChordWithNotes, pref: AccidentalPreference): KeyboardLayout {
	const baseNotes = pref === 'flats' ? NOTES_FLATS : NOTES_SHARPS;
	const voicingNotes = chordData.voicing;

	if (voicingNotes.length === 0) return { activeIndices: new Set(), octaves: 2 };

	// Convert voicing notes to pitch classes (0–11), preserving order, deduplicating
	const pitchClasses: number[] = [];
	const seen = new Set<number>();
	for (const note of voicingNotes) {
		const pc = noteToPitchClass(note, baseNotes);
		if (pc !== -1 && !seen.has(pc)) {
			pitchClasses.push(pc);
			seen.add(pc);
		}
	}

	if (pitchClasses.length === 0) return { activeIndices: new Set(), octaves: 2 };

	// Place notes ascending from the voicing order
	const indices = placeAscending(pitchClasses);

	// Check if they fit in 2 octaves
	if (indices.every((idx) => idx >= 0 && idx < 24)) {
		return { activeIndices: new Set(indices), octaves: 2 };
	}

	// Try 3 octaves
	if (indices.every((idx) => idx >= 0 && idx < 36)) {
		return { activeIndices: new Set(indices), octaves: 3 };
	}

	// Fallback: compact sorted placement (always fits in 2 octaves)
	const sortedPCs = [...pitchClasses].sort((a, b) => a - b);
	const compactIndices = placeAscending(sortedPCs);
	const fits3 = compactIndices.every((idx) => idx >= 0 && idx < 36);
	const octaves: OctaveCount = fits3 && compactIndices.some((idx) => idx >= 24) ? 3 : 2;
	const maxIdx = octaves === 3 ? 36 : 24;

	return {
		activeIndices: new Set(compactIndices.filter((idx) => idx >= 0 && idx < maxIdx)),
		octaves,
	};
}

/**
 * Legacy wrapper — returns just the set of indices, always fitting in 2 octaves.
 * Used by mini keyboards in Results screen.
 */
export function getActiveKeyIndices(chordData: ChordWithNotes, pref: AccidentalPreference): Set<number> {
	const layout = getKeyboardLayout(chordData, pref);
	// For backward compat (mini keyboards), clamp to 2 octaves
	if (layout.octaves === 2) return layout.activeIndices;
	// Fallback: compact sorted to fit 2 octaves
	const baseNotes = pref === 'flats' ? NOTES_FLATS : NOTES_SHARPS;
	const pitchClasses: number[] = [];
	const seen = new Set<number>();
	for (const note of chordData.voicing) {
		const pc = noteToPitchClass(note, baseNotes);
		if (pc !== -1 && !seen.has(pc)) {
			pitchClasses.push(pc);
			seen.add(pc);
		}
	}
	const sortedPCs = [...pitchClasses].sort((a, b) => a - b);
	const compactIndices = placeAscending(sortedPCs);
	return new Set(compactIndices.filter((idx) => idx >= 0 && idx < 24));
}

/** Place pitch classes in ascending order on the keyboard, each above the previous */
function placeAscending(pitchClasses: number[]): number[] {
	const indices: number[] = [];
	let prevIdx = -1;

	for (const pc of pitchClasses) {
		let kbIdx = pc;
		if (prevIdx !== -1) {
			while (kbIdx <= prevIdx) kbIdx += 12;
		}
		indices.push(kbIdx);
		prevIdx = kbIdx;
	}

	return indices;
}

/**
 * Check if a chromatic index matches the root note
 * AND the root is part of the active voicing.
 */
export function isRootIndex(chromaticIndex: number, root: string, voicing: string[]): boolean {
	const rootSemi = noteToSemitone(root);
	if (rootSemi === -1) return false;
	if ((chromaticIndex % 12) !== rootSemi) return false;

	// Only mark as root if root is actually in the voicing
	const rootInVoicing = voicing.some((n) => {
		const s = noteToSemitone(n);
		return s === rootSemi;
	});
	return rootInVoicing;
}
