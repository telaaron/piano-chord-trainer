// Progression engine – generate structured chord sequences (2-5-1, cycle of 4ths, etc.)

import { NOTES_SHARPS, NOTES_FLATS, type AccidentalPreference } from './notes';
import { CHORD_NOTATIONS, type NotationStyle } from './chords';

export type ProgressionMode = 'random' | '2-5-1' | 'cycle-of-4ths' | '1-6-2-5';

export const PROGRESSION_LABELS: Record<ProgressionMode, string> = {
	'random': 'Zufällig',
	'2-5-1': 'ii – V – I',
	'cycle-of-4ths': 'Quartenzirkel',
	'1-6-2-5': 'I – vi – ii – V',
};

export const PROGRESSION_DESCRIPTIONS: Record<ProgressionMode, string> = {
	'random': 'Zufällige Akkorde',
	'2-5-1': 'Dm7 → G7 → CMaj7 in allen Tonarten',
	'cycle-of-4ths': 'C → F → Bb → Eb → … durch alle 12',
	'1-6-2-5': 'CMaj7 → Am7 → Dm7 → G7 in allen Tonarten',
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

/** Generate a ii-V-I progression for a given key center */
function generate251(keySemitone: number, pref: AccidentalPreference, notation: NotationStyle): ProgressionChord[] {
	// ii = degree 2 (index 1), V = degree 5 (index 4), I = degree 1 (index 0)
	const degrees = [1, 4, 0]; // ii, V, I
	return degrees.map((degIdx) => {
		const rootSemitone = (keySemitone + SCALE_DEGREES[degIdx]) % 12;
		const quality = MAJOR_DEGREE_QUALITIES[degIdx];
		const root = noteFromSemitone(rootSemitone, pref);
		const displayQuality = CHORD_NOTATIONS[notation][quality] || quality;
		return { root, quality, display: `${root}${displayQuality}` };
	});
}

/** Generate a I-vi-ii-V turnaround for a given key center */
function generate1625(keySemitone: number, pref: AccidentalPreference, notation: NotationStyle): ProgressionChord[] {
	const degrees = [0, 5, 1, 4]; // I, vi, ii, V
	return degrees.map((degIdx) => {
		const rootSemitone = (keySemitone + SCALE_DEGREES[degIdx]) % 12;
		const quality = MAJOR_DEGREE_QUALITIES[degIdx];
		const root = noteFromSemitone(rootSemitone, pref);
		const displayQuality = CHORD_NOTATIONS[notation][quality] || quality;
		return { root, quality, display: `${root}${displayQuality}` };
	});
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
 */
export function generateProgression(
	mode: ProgressionMode,
	pref: AccidentalPreference,
	notation: NotationStyle,
	totalChords: number,
): GeneratedProgression {
	if (mode === '2-5-1') {
		const keys = getKeyCenters(pref);
		const allChords: ProgressionChord[] = [];
		for (const key of keys) {
			const keySemitone = NOTES_SHARPS.indexOf(key as any) !== -1
				? NOTES_SHARPS.indexOf(key as any)
				: NOTES_FLATS.indexOf(key as any);
			if (keySemitone === -1) continue;
			allChords.push(...generate251(keySemitone, pref, notation));
		}
		return {
			chords: allChords,
			label: `ii – V – I durch alle 12 Tonarten (${allChords.length} Akkorde)`,
		};
	}

	if (mode === '1-6-2-5') {
		const keys = getKeyCenters(pref);
		const allChords: ProgressionChord[] = [];
		for (const key of keys) {
			const keySemitone = NOTES_SHARPS.indexOf(key as any) !== -1
				? NOTES_SHARPS.indexOf(key as any)
				: NOTES_FLATS.indexOf(key as any);
			if (keySemitone === -1) continue;
			allChords.push(...generate1625(keySemitone, pref, notation));
		}
		return {
			chords: allChords,
			label: `I – vi – ii – V durch alle 12 Tonarten (${allChords.length} Akkorde)`,
		};
	}

	if (mode === 'cycle-of-4ths') {
		const chords = generateCycleOf4ths(pref, notation);
		return {
			chords,
			label: `Quartenzirkel (${chords.length} Akkorde)`,
		};
	}

	// 'random' — handled by the existing generateChords() in +page.svelte
	return { chords: [], label: `${totalChords} zufällige Akkorde` };
}
