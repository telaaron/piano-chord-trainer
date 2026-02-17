// Note arrays and enharmonic mapping

export const NOTES_SHARPS = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'] as const;
export const NOTES_FLATS = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'] as const;

export type NoteName = (typeof NOTES_SHARPS)[number] | (typeof NOTES_FLATS)[number];
export type AccidentalPreference = 'sharps' | 'flats' | 'both';
export type NotationSystem = 'international' | 'german';

/** Map between enharmonic equivalents (same semitone, different spelling) */
export const ENHARMONIC_MAP: Record<string, string> = {
	'C#': 'Db', 'Db': 'C#',
	'D#': 'Eb', 'Eb': 'D#',
	'F#': 'Gb', 'Gb': 'F#',
	'G#': 'Ab', 'Ab': 'G#',
	'A#': 'Bb', 'Bb': 'A#',
};

/** Get the preferred note array based on accidental preference */
export function getNoteArray(pref: AccidentalPreference): readonly string[] {
	if (pref === 'flats') return NOTES_FLATS;
	if (pref === 'sharps') return NOTES_SHARPS;
	// "both" – use sharps as canonical, user sees mixed during generation
	return NOTES_SHARPS;
}

/** Get note pool for chord generation */
export function getNotePool(pref: AccidentalPreference): string[] {
	if (pref === 'sharps') return [...NOTES_SHARPS];
	if (pref === 'flats') return [...NOTES_FLATS];
	// Both: all unique notes including enharmonics
	return [
		'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F',
		'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B',
	];
}

/** Find semitone index (0–11) for a note name */
export function noteToSemitone(note: string): number {
	let idx = NOTES_SHARPS.indexOf(note as any);
	if (idx !== -1) return idx;
	idx = NOTES_FLATS.indexOf(note as any);
	if (idx !== -1) return idx;
	// Try enharmonic
	const enh = ENHARMONIC_MAP[note];
	if (enh) {
		idx = NOTES_SHARPS.indexOf(enh as any);
		if (idx !== -1) return idx;
	}
	return -1;
}

/** Get note name at a given semitone offset from root */
export function getNoteName(rootSemitone: number, interval: number, pref: AccidentalPreference): string {
	const index = (rootSemitone + interval) % 12;
	const base = pref === 'sharps' ? NOTES_SHARPS : NOTES_FLATS;
	return base[index];
}

/** Convert a note name between international and German notation */
export function convertNoteName(note: string, system: NotationSystem): string {
	if (system === 'german') {
		if (note === 'B') return 'H';
		if (note === 'Bb') return 'B';
	}
	return note;
}

/** Convert a full chord name (e.g. "BbMaj7") to German notation */
export function convertChordNotation(chordName: string, system: NotationSystem): string {
	if (system !== 'german') return chordName;
	if (chordName.startsWith('Bb')) return 'B' + chordName.slice(2);
	if (chordName.startsWith('B') && !chordName.startsWith('Bb')) return 'H' + chordName.slice(1);
	return chordName;
}
