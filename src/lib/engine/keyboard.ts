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
 * Find the pitch-class (0–11) for a note name, checking enharmonics.
 */
function noteToPitchClass(note: string, baseNotes: readonly string[]): number {
	let idx = baseNotes.indexOf(note as any);
	if (idx !== -1) return idx;
	const enh = ENHARMONIC_MAP[note];
	if (enh) idx = baseNotes.indexOf(enh as any);
	return idx;
}

/**
 * Build the set of chromatic indices that should be highlighted on the keyboard.
 *
 * ONLY highlights notes present in chordData.voicing — NOT the full chord.
 * E.g. rootless voicings won't highlight the root.
 *
 * Notes are placed on the 2-octave keyboard (0–23) using a smart layout:
 * - The lowest voicing note is placed in the first octave (0–11) if possible
 * - Subsequent notes go upward from there, wrapping to octave 2 when needed
 * - This creates a spread voicing rather than stacking everything tightly
 */
export function getActiveKeyIndices(chordData: ChordWithNotes, pref: AccidentalPreference): Set<number> {
	const baseNotes = pref === 'flats' ? NOTES_FLATS : NOTES_SHARPS;
	const voicingNotes = chordData.voicing;

	if (voicingNotes.length === 0) return new Set();

	const result = new Set<number>();

	// Convert voicing notes to pitch classes (0–11)
	const pitchClasses: number[] = [];
	for (const note of voicingNotes) {
		const pc = noteToPitchClass(note, baseNotes);
		if (pc !== -1) pitchClasses.push(pc);
	}

	if (pitchClasses.length === 0) return new Set();

	// Place notes in ascending order on the keyboard, starting from
	// the first note in the lowest reasonable position.
	// The voicing order determines the bottom-up layout.
	let prevIdx = -1;

	for (const pc of pitchClasses) {
		let kbIdx: number;

		if (prevIdx === -1) {
			// First note: place in first octave
			kbIdx = pc;
		} else {
			// Subsequent notes: go upward from previous position
			kbIdx = pc;
			// Ensure this note is above the previous
			while (kbIdx <= prevIdx) {
				kbIdx += 12;
			}
		}

		// Keep within keyboard range (0–23)
		if (kbIdx < CHROMATIC_COUNT) {
			result.add(kbIdx);
			prevIdx = kbIdx;
		}
	}

	return result;
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
