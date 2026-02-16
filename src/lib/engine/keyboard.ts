// Keyboard helpers – map chord notes to keyboard key indices

import { NOTES_SHARPS, NOTES_FLATS, ENHARMONIC_MAP, noteToSemitone, type AccidentalPreference } from './notes';
import type { ChordWithNotes } from './voicings';

/** Total white keys on our 2-octave keyboard */
export const WHITE_KEY_COUNT = 14;

/** Total chromatic notes across 2 octaves */
export const CHROMATIC_COUNT = 24;

/**
 * Black key layout:
 * idx = chromatic index within the 24-note range
 * pos = position in white-key units (used for left %)
 */
export const BLACK_KEYS = [
	{ idx: 1, pos: 1 },  { idx: 3, pos: 2 },   // C#  D#
	{ idx: 6, pos: 4 },  { idx: 8, pos: 5 },  { idx: 10, pos: 6 },  // F#  G#  A#
	{ idx: 13, pos: 8 }, { idx: 15, pos: 9 },  // C#' D#'
	{ idx: 18, pos: 11 }, { idx: 20, pos: 12 }, { idx: 22, pos: 13 }, // F#' G#' A#'
] as const;

/** White key chromatic indices: C=0, D=2, E=4, F=5, G=7, A=9, B=11, then +12 */
export const WHITE_KEY_CHROMATIC = [0, 2, 4, 5, 7, 9, 11] as const;

/** Get chromatic index for white key i (0-based among 14 keys) */
export function whiteKeyChromaticIndex(i: number): number {
	const octave = Math.floor(i / 7);
	const noteInOctave = WHITE_KEY_CHROMATIC[i % 7];
	return octave * 12 + noteInOctave;
}

/**
 * Build the set of chromatic indices that should be highlighted on the keyboard.
 * Root is placed in the first octave; other voicing notes are stacked above it.
 */
export function getActiveKeyIndices(chordData: ChordWithNotes, pref: AccidentalPreference): Set<number> {
	const baseNotes = pref === 'flats' ? NOTES_FLATS : NOTES_SHARPS;
	const root = chordData.root;

	// Find root in first octave (0-11)
	let rootIndex = baseNotes.findIndex((n) => n === root || ENHARMONIC_MAP[n] === root);
	if (rootIndex === -1 && ENHARMONIC_MAP[root]) {
		rootIndex = baseNotes.findIndex((n) => n === ENHARMONIC_MAP[root]);
	}
	if (rootIndex === -1) return new Set();

	const result = new Set<number>();
	const usedNames = new Set<string>();

	// Root always in first octave
	result.add(rootIndex);
	usedNames.add(baseNotes[rootIndex]);
	if (ENHARMONIC_MAP[baseNotes[rootIndex]]) usedNames.add(ENHARMONIC_MAP[baseNotes[rootIndex]]);

	for (const note of chordData.voicing) {
		if (usedNames.has(note)) continue;
		if (ENHARMONIC_MAP[note] && usedNames.has(ENHARMONIC_MAP[note])) continue;

		let ni = baseNotes.findIndex((n) => n === note);
		if (ni === -1 && ENHARMONIC_MAP[note]) {
			ni = baseNotes.findIndex((n) => n === ENHARMONIC_MAP[note]);
		}
		if (ni === -1) continue;

		// Stack above root
		const kbIdx = ni <= rootIndex ? ni + 12 : ni;
		if (kbIdx < CHROMATIC_COUNT) {
			result.add(kbIdx);
			usedNames.add(note);
			if (ENHARMONIC_MAP[note]) usedNames.add(ENHARMONIC_MAP[note]);
		}
	}

	return result;
}

/** Check if a chromatic index matches the root note */
export function isRootIndex(chromaticIndex: number, root: string): boolean {
	const rootSemi = noteToSemitone(root);
	if (rootSemi === -1) return false;
	return (chromaticIndex % 12) === rootSemi;
}
