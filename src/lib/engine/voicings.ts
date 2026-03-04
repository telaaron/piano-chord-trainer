// Voicing calculation – which notes to play for each voicing type

import type { AccidentalPreference, NotationSystem } from './notes';
import { noteToSemitone, getNoteName, convertNoteName, ENHARMONIC_MAP } from './notes';
import { CHORD_INTERVALS, CHORD_NOTATIONS, type NotationStyle, type VoicingType } from './chords';

export interface ChordWithNotes {
	/** Full display name, e.g. "C#Δ7" */
	chord: string;
	/** Root note, e.g. "C#" */
	root: string;
	/** Internal quality key, e.g. "Maj7" */
	type: string;
	/** All notes in root position */
	notes: string[];
	/** Notes for the selected voicing */
	voicing: string[];
}

/** Compute chord notes from root + quality */
export function getChordNotes(root: string, quality: string, pref: AccidentalPreference): string[] {
	const rootSemi = noteToSemitone(root);
	const intervals = CHORD_INTERVALS[quality];
	if (!intervals || rootSemi === -1) return [];
	return intervals.map((iv) => getNoteName(rootSemi, iv, pref));
}

/**
 * Compute the 9th (natural) for a chord root.
 * The 9th = root + 14 semitones = root + 2 semitones (mod 12).
 */
function getNinth(root: string, pref: AccidentalPreference): string {
	const rootSemi = noteToSemitone(root);
	if (rootSemi === -1) return '';
	return getNoteName(rootSemi, 14, pref);
}

/**
 * Rotate an array left by `n` positions.
 * E.g. rotate([C,E,G,B], 1) → [E,G,B,C]
 */
function rotateLeft<T>(arr: T[], n: number): T[] {
	if (arr.length === 0) return arr;
	const k = ((n % arr.length) + arr.length) % arr.length;
	return [...arr.slice(k), ...arr.slice(0, k)];
}

/** Select voicing notes from full chord notes.
 *  For rootless voicings, pass root + pref so we can compute the 9th.
 */
export function getVoicingNotes(
	allNotes: string[],
	voicing: VoicingType,
	root?: string,
	pref?: AccidentalPreference,
): string[] {
	if (allNotes.length === 0) return [];
	switch (voicing) {
		case 'root':
			return allNotes;
		case 'shell':
			return allNotes.length >= 4
				? [allNotes[0], allNotes[1], allNotes[3]]
				: allNotes;
		case 'half-shell':
			return allNotes.length >= 4
				? [allNotes[1], allNotes[0], allNotes[3]]
				: allNotes;
		case 'full':
			return allNotes.length >= 4
				? [allNotes[0], allNotes[allNotes.length - 1], allNotes[1], allNotes[2]]
				: allNotes;

		// ── Rootless voicings (left-hand, bass player covers root) ──
		case 'rootless-a': {
			// Type A: 3rd – 5th – 7th – 9th (Bill Evans style)
			if (allNotes.length < 4) return allNotes;
			const ninth = allNotes.length >= 5
				? allNotes[4]  // chord already has 9th (Maj9, 9, m9…)
				: (root && pref) ? getNinth(root, pref) : allNotes[1]; // fallback
			// [3rd, 5th, 7th, 9th]
			return [allNotes[1], allNotes[2], allNotes[3], ninth];
		}
		case 'rootless-b': {
			// Type B: 7th – 9th – 3rd – 5th (complementary to A)
			if (allNotes.length < 4) return allNotes;
			const ninth = allNotes.length >= 5
				? allNotes[4]
				: (root && pref) ? getNinth(root, pref) : allNotes[1];
			// [7th, 9th, 3rd, 5th]
			return [allNotes[3], ninth, allNotes[1], allNotes[2]];
		}

		// ── Inversions (rotate chord tones) ──
		case 'inversion-1':
			// 1st inversion: 3rd on bottom
			return rotateLeft(allNotes, 1);
		case 'inversion-2':
			// 2nd inversion: 5th on bottom
			return rotateLeft(allNotes, 2);
		case 'inversion-3':
			// 3rd inversion: 7th on bottom (only for 4+ note chords)
			return allNotes.length >= 4
				? rotateLeft(allNotes, 3)
				: rotateLeft(allNotes, allNotes.length - 1);

		default:
			return allNotes;
	}
}

// ─── Interval name maps ────────────────────────────────────

/** Context-aware interval names per chord quality (semitone → label). */
const QUALITY_INTERVAL_NAMES: Record<string, Record<number, string>> = {
	Maj7:       { 0: 'R', 4: '3', 7: '5', 11: '7' },
	'7':        { 0: 'R', 4: '3', 7: '5', 10: '♭7' },
	m7:         { 0: 'R', 3: '♭3', 7: '5', 10: '♭7' },
	'6':        { 0: 'R', 4: '3', 7: '5', 9: '6' },
	m6:         { 0: 'R', 3: '♭3', 7: '5', 9: '6' },
	Maj9:       { 0: 'R', 4: '3', 7: '5', 11: '7', 2: '9' },
	'9':        { 0: 'R', 4: '3', 7: '5', 10: '♭7', 2: '9' },
	m9:         { 0: 'R', 3: '♭3', 7: '5', 10: '♭7', 2: '9' },
	'6/9':      { 0: 'R', 4: '3', 7: '5', 9: '6', 2: '9' },
	'Maj7#11':  { 0: 'R', 4: '3', 7: '5', 11: '7', 6: '♯11' },
	'7#9':      { 0: 'R', 4: '3', 7: '5', 10: '♭7', 3: '♯9' },
	'7b9':      { 0: 'R', 4: '3', 7: '5', 10: '♭7', 1: '♭9' },
	m11:        { 0: 'R', 3: '♭3', 7: '5', 10: '♭7', 2: '9', 5: '11' },
	'13':       { 0: 'R', 4: '3', 7: '5', 10: '♭7', 2: '9', 9: '13' },
	m7b5:       { 0: 'R', 3: '♭3', 6: '♭5', 10: '♭7' },
	dim7:       { 0: 'R', 3: '♭3', 6: '♭5', 9: '°7' },
};

/** Generic fallback for intervals added by voicings (e.g. 9th in rootless). */
const GENERIC_INTERVAL: Record<number, string> = {
	0: 'R', 1: '♭9', 2: '9', 3: '♭3', 4: '3', 5: '11',
	6: '♯11', 7: '5', 8: '♯5', 9: '6', 10: '♭7', 11: '7',
};

/**
 * Compute the interval labels for a set of voicing notes, aware of chord quality.
 *
 * Example: G9 shell voicing [G, B, F] → ['R', '3', '♭7']
 */
export function getVoicingIntervalLabels(
	voicingNotes: string[],
	root: string,
	quality: string,
): string[] {
	const rootSemi = noteToSemitone(root);
	if (rootSemi === -1) return voicingNotes;
	const qualityMap = QUALITY_INTERVAL_NAMES[quality] || {};

	return voicingNotes.map((note) => {
		const semi = noteToSemitone(note);
		if (semi === -1) return '?';
		const interval = ((semi - rootSemi) % 12 + 12) % 12;
		return qualityMap[interval] ?? GENERIC_INTERVAL[interval] ?? '?';
	});
}

/**
 * Compute the full chord formula (all intervals, not just voicing selection).
 *
 * Example: quality '9' → ['R', '3', '5', '♭7', '9']
 */
export function getChordFormula(quality: string): string[] {
	const intervals = CHORD_INTERVALS[quality];
	if (!intervals) return [];
	const qualityMap = QUALITY_INTERVAL_NAMES[quality] || {};
	return intervals.map((iv) => {
		const pc = ((iv % 12) + 12) % 12;
		return qualityMap[pc] ?? GENERIC_INTERVAL[pc] ?? '?';
	});
}

/** Format voicing notes for display: "C – E – B" */
export function formatVoicing(
	chordData: ChordWithNotes,
	voicing: VoicingType,
	system: NotationSystem,
): string {
	const allNotes = chordData.notes.map((n) => convertNoteName(n, system));
	if (allNotes.length === 0) return '-';

	switch (voicing) {
		case 'root':
			return allNotes.join(' – ');
		case 'shell':
			return allNotes.length >= 4
				? `${allNotes[0]} – ${allNotes[1]} – ${allNotes[3]}`
				: allNotes.join(' – ');
		case 'half-shell':
			return allNotes.length >= 4
				? `${allNotes[1]} – ${allNotes[0]} – ${allNotes[3]}`
				: allNotes.join(' – ');
		case 'full':
			return allNotes.length >= 4
				? `${allNotes[0]} – ${allNotes[allNotes.length - 1]} – ${allNotes[1]} – ${allNotes[2]}`
				: allNotes.join(' – ');

		case 'rootless-a':
		case 'rootless-b':
		case 'inversion-1':
		case 'inversion-2':
		case 'inversion-3': {
			// Use the actual voicing notes (already computed and stored)
			return chordData.voicing.map((n) => convertNoteName(n, system)).join(' – ');
		}

		default:
			return allNotes.join(' – ');
	}
}

/** Reverse-lookup: notation display string → internal quality key */
export function displayToQuality(display: string, style: NotationStyle): string {
	const map = CHORD_NOTATIONS[style];
	for (const [key, value] of Object.entries(map)) {
		if (value === display) return key;
	}
	return display;
}

/**
 * Get all unique valid pitch-class sets for a chord across common voicing types.
 * Used in Free Voice Leading mode to validate any voicing the player chooses.
 *
 * Returns an array of Sets, each containing the pitch classes (0-11) for one voicing variant.
 * Deduplicates — e.g. shell and half-shell share the same PCs.
 */
export function getValidPCSets(
	root: string,
	quality: string,
	pref: AccidentalPreference,
): Set<number>[] {
	const allNotes = getChordNotes(root, quality, pref);
	if (allNotes.length === 0) return [];

	const voicingTypes: VoicingType[] = ['root', 'shell', 'half-shell', 'full', 'rootless-a', 'rootless-b'];
	const seen = new Set<string>();
	const result: Set<number>[] = [];

	for (const vt of voicingTypes) {
		const notes = getVoicingNotes(allNotes, vt, root, pref);
		const pcs = new Set(notes.map(noteToSemitone).filter(pc => pc !== -1));
		// Deduplicate by sorted PC string
		const key = [...pcs].sort((a, b) => a - b).join(',');
		if (!seen.has(key)) {
			seen.add(key);
			result.push(pcs);
		}
	}

	return result;
}
