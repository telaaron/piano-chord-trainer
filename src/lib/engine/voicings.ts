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

/** Select voicing notes from full chord notes */
export function getVoicingNotes(allNotes: string[], voicing: VoicingType): string[] {
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
		default:
			return allNotes;
	}
}

/** Format voicing notes for display: "C – E – B" */
export function formatVoicing(chordData: ChordWithNotes, voicing: VoicingType, system: NotationSystem): string {
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
