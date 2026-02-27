// Progression engine – generate structured chord sequences (2-5-1, cycle of 4ths, etc.)

import { NOTES_SHARPS, NOTES_FLATS, type AccidentalPreference } from './notes';
import { CHORD_NOTATIONS, type NotationStyle } from './chords';

/**
 * Built-in progression modes + 'custom' (user-defined scale-degree sequence).
 *
 *  random        – random chords (no harmonic structure)
 *  2-5-1         – ii – V – I
 *  1-6-2-5       – I – vi – ii – V  (turnaround)
 *  cycle-of-4ths – dom7 chords around the cycle
 *  3-6-2-5       – iii – vi – ii – V   (extended turnaround)
 *  1-4-5         – I – IV – V          (blues/pop)
 *  diatonic      – I–ii–iii–IV–V–vi–vii  (all 7 degrees)
 *  custom        – user-defined degree sequence
 */
export type ProgressionMode =
	| 'random'
	| '2-5-1'
	| '1-6-2-5'
	| 'cycle-of-4ths'
	| '3-6-2-5'
	| '1-4-5'
	| 'diatonic'
	| 'custom';

export const PROGRESSION_LABELS: Record<ProgressionMode, string> = {
	'random': 'Random',
	'2-5-1': 'ii – V – I',
	'1-6-2-5': 'I – vi – ii – V',
	'cycle-of-4ths': 'Cycle of 4ths',
	'3-6-2-5': 'iii – vi – ii – V',
	'1-4-5': 'I – IV – V',
	'diatonic': 'I – ii – iii – IV – V – vi – vii',
	'custom': 'Custom',
};

export const PROGRESSION_DESCRIPTIONS: Record<ProgressionMode, string> = {
	'random': 'Random chords',
	'2-5-1': 'Dm7 → G7 → CMaj7 through all keys',
	'1-6-2-5': 'CMaj7 → Am7 → Dm7 → G7 through all keys',
	'cycle-of-4ths': 'C → F → Bb → Eb → … through all 12',
	'3-6-2-5': 'Em7 → Am7 → Dm7 → G7 through all keys',
	'1-4-5': 'CMaj7 → FMaj7 → G7 through all keys',
	'diatonic': 'All 7 diatonic chords through all keys',
	'custom': 'Your own scale-degree sequence through all keys',
};

/** Semitone offsets from root for each scale degree (major scale) */
const SCALE_DEGREES = [0, 2, 4, 5, 7, 9, 11] as const; // 1 2 3 4 5 6 7

/**
 * Quality assigned to each scale degree in major:
 * I=Maj7, ii=m7, iii=m7, IV=Maj7, V=7, vi=m7, vii=m7b5
 */
const MAJOR_DEGREE_QUALITIES = ['Maj7', 'm7', 'm7', 'Maj7', '7', 'm7', 'm7b5'] as const;

/** Cycle of 4ths order (semitone intervals) */
const CYCLE_OF_4THS = [0, 5, 10, 3, 8, 1, 6, 11, 4, 9, 2, 7] as const;

interface ProgressionChord {
	root: string;
	quality: string;
	display: string; // Full chord name, e.g. "Dm7"
}

/**
 * Get note name from semitone, respecting key context.
 * For the progression engine we pick sharp or flat based on the key center.
 */
function noteFromSemitone(semitone: number, pref: AccidentalPreference): string {
	const idx = ((semitone % 12) + 12) % 12;
	if (pref === 'flats') return NOTES_FLATS[idx];
	if (pref === 'sharps') return NOTES_SHARPS[idx];
	// 'both': use flats for common jazz keys, sharps otherwise
	return NOTES_FLATS[idx];
}

/** Get the key centers to cycle through */
function getKeyCenters(pref: AccidentalPreference): string[] {
	if (pref === 'flats') return [...NOTES_FLATS];
	if (pref === 'sharps') return [...NOTES_SHARPS];
	// 'both': all 12 in cycle-of-4ths order for jazz feel
	return CYCLE_OF_4THS.map((st) => noteFromSemitone(st, 'flats'));
}

/** Roman numeral labels for each scale degree (0-indexed) */
const DEGREE_ROMAN = ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°'] as const;

/**
 * Map a built-in ProgressionMode to its scale-degree indices (0-based).
 * e.g. '2-5-1' → [1, 4, 0] (ii, V, I)
 */
export const MODE_DEGREE_MAP: Partial<Record<ProgressionMode, number[]>> = {
	'2-5-1':   [1, 4, 0],         // ii – V – I
	'1-6-2-5': [0, 5, 1, 4],      // I – vi – ii – V
	'3-6-2-5': [2, 5, 1, 4],      // iii – vi – ii – V
	'1-4-5':   [0, 3, 4],         // I – IV – V
	'diatonic': [0, 1, 2, 3, 4, 5, 6], // all seven
};

/**
 * Universal degree-based generator: given an array of 0-based degree indices,
 * produce diatonic chords for one key center.
 */
function generateFromDegrees(
	degreeIndices: number[],
	keySemitone: number,
	pref: AccidentalPreference,
	notation: NotationStyle,
): ProgressionChord[] {
	return degreeIndices.map((degIdx) => {
		const rootSemitone = (keySemitone + SCALE_DEGREES[degIdx]) % 12;
		const quality = MAJOR_DEGREE_QUALITIES[degIdx];
		const root = noteFromSemitone(rootSemitone, pref);
		const displayQuality = CHORD_NOTATIONS[notation][quality] || quality;
		return { root, quality, display: `${root}${displayQuality}` };
	});
}

/**
 * Generate degree-based progression through all 12 keys.
 */
function generateDegreeProgression(
	degreeIndices: number[],
	pref: AccidentalPreference,
	notation: NotationStyle,
): ProgressionChord[] {
	const keys = getKeyCenters(pref);
	const allChords: ProgressionChord[] = [];
	for (const key of keys) {
		const keySemitone = NOTES_SHARPS.indexOf(key as (typeof NOTES_SHARPS)[number]) !== -1
			? NOTES_SHARPS.indexOf(key as (typeof NOTES_SHARPS)[number])
			: NOTES_FLATS.indexOf(key as (typeof NOTES_FLATS)[number]);
		if (keySemitone === -1) continue;
		allChords.push(...generateFromDegrees(degreeIndices, keySemitone, pref, notation));
	}
	return allChords;
}

/** Generate cycle of 4ths: dom7 chords through all 12 keys */
function generateCycleOf4ths(pref: AccidentalPreference, notation: NotationStyle): ProgressionChord[] {
	const quality = '7';
	const displayQuality = CHORD_NOTATIONS[notation][quality] || quality;
	return CYCLE_OF_4THS.map((st) => {
		const root = noteFromSemitone(st, pref);
		return { root, quality, display: `${root}${displayQuality}` };
	});
}

/**
 * Convert 1-based user-facing degrees (1–7) to 0-based indices.
 * Clamps to valid range.
 */
export function parseCustomDegrees(degrees: number[]): number[] {
	return degrees
		.map((d) => Math.max(0, Math.min(6, d - 1)))
		.filter((d) => !isNaN(d));
}

/**
 * Build a human-readable Roman numeral label from degree indices (0-based).
 */
export function degreesToLabel(degreeIndices: number[]): string {
	return degreeIndices.map((i) => DEGREE_ROMAN[i]).join(' – ');
}

export interface GeneratedProgression {
	chords: ProgressionChord[];
	/** Human-readable label like "ii-V-I in C, F, Bb, …" */
	label: string;
}

/**
 * Generate a full chord list for a progression mode.
 * @param mode The progression type
 * @param pref Accidental preference
 * @param notation Display notation style
 * @param totalChords Desired total (for random mode; progressions generate exact sets)
 * @param customDegrees 0-based degree indices for 'custom' mode
 */
export function generateProgression(
	mode: ProgressionMode,
	pref: AccidentalPreference,
	notation: NotationStyle,
	totalChords: number,
	customDegrees?: number[],
): GeneratedProgression {
	// Degree-based modes (including 'custom')
	const degrees = mode === 'custom'
		? (customDegrees ?? [0, 3, 4]) // fallback I-IV-V
		: MODE_DEGREE_MAP[mode];

	if (degrees) {
		const chords = generateDegreeProgression(degrees, pref, notation);
		const label = `${degreesToLabel(degrees)} through all 12 keys (${chords.length} chords)`;
		return { chords, label };
	}

	if (mode === 'cycle-of-4ths') {
		const chords = generateCycleOf4ths(pref, notation);
		return {
			chords,
			label: `Cycle of 4ths (${chords.length} chords)`,
		};
	}

	// 'random' — handled by the existing generateChords() in +page.svelte
	return { chords: [], label: `${totalChords} random chords` };
}
