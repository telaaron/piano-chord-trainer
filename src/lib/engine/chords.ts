// Chord definitions, intervals, notation styles, difficulty levels

export type Difficulty = 'beginner' | 'intermediate' | 'advanced';
export type NotationStyle = 'standard' | 'symbols' | 'short';
export type VoicingType =
	| 'root'
	| 'shell'
	| 'half-shell'
	| 'full'
	| 'rootless-a'
	| 'rootless-b'
	| 'inversion-1'
	| 'inversion-2'
	| 'inversion-3';
export type DisplayMode = 'off' | 'always' | 'verify';

export interface ChordType {
	/** Internal key, e.g. "maj7" */
	name: string;
	/** Display name used for lookup, e.g. "Maj7" */
	display: string;
}

/** Chord types grouped by difficulty */
export const CHORDS_BY_DIFFICULTY: Record<Difficulty, ChordType[]> = {
	beginner: [
		{ name: 'maj7', display: 'Maj7' },
		{ name: '7', display: '7' },
		{ name: 'm7', display: 'm7' },
		{ name: '6', display: '6' },
		{ name: 'm6', display: 'm6' },
	],
	intermediate: [
		{ name: 'maj7', display: 'Maj7' },
		{ name: '7', display: '7' },
		{ name: 'm7', display: 'm7' },
		{ name: '6', display: '6' },
		{ name: 'm6', display: 'm6' },
		{ name: 'maj9', display: 'Maj9' },
		{ name: '9', display: '9' },
		{ name: 'm9', display: 'm9' },
		{ name: '6/9', display: '6/9' },
	],
	advanced: [
		{ name: 'maj7', display: 'Maj7' },
		{ name: '7', display: '7' },
		{ name: 'm7', display: 'm7' },
		{ name: '6', display: '6' },
		{ name: 'm6', display: 'm6' },
		{ name: 'maj9', display: 'Maj9' },
		{ name: '9', display: '9' },
		{ name: 'm9', display: 'm9' },
		{ name: 'maj7#11', display: 'Maj7#11' },
		{ name: '7#9', display: '7#9' },
		{ name: '7b9', display: '7b9' },
		{ name: 'm11', display: 'm11' },
		{ name: '13', display: '13' },
		{ name: 'm7b5', display: 'm7b5' },
		{ name: 'dim7', display: 'dim7' },
	],
};

/** Semitone intervals from root for each chord quality */
export const CHORD_INTERVALS: Record<string, number[]> = {
	Maj7: [0, 4, 7, 11],
	'7': [0, 4, 7, 10],
	m7: [0, 3, 7, 10],
	'6': [0, 4, 7, 9],
	m6: [0, 3, 7, 9],
	Maj9: [0, 4, 7, 11, 14],
	'9': [0, 4, 7, 10, 14],
	m9: [0, 3, 7, 10, 14],
	'6/9': [0, 4, 7, 9, 14],
	'Maj7#11': [0, 4, 7, 11, 18],
	'7#9': [0, 4, 7, 10, 15],
	'7b9': [0, 4, 7, 10, 13],
	m11: [0, 3, 7, 10, 14, 17],
	'13': [0, 4, 7, 10, 14, 21],
	m7b5: [0, 3, 6, 10],
	dim7: [0, 3, 6, 9],
};

/** Maps internal chord key → display string for each notation style */
export const CHORD_NOTATIONS: Record<NotationStyle, Record<string, string>> = {
	standard: {
		Maj7: 'Maj7',  '7': '7',  m7: 'm7',  '6': '6',  m6: 'm6',
		Maj9: 'Maj9',  '9': '9',  m9: 'm9',  '6/9': '6/9',
		'Maj7#11': 'Maj7#11',  '7#9': '7#9',  '7b9': '7b9',
		m11: 'm11',  '13': '13',  m7b5: 'm7b5',  dim7: 'dim7',
	},
	symbols: {
		Maj7: 'Δ7',  '7': '7',  m7: '-7',  '6': '6',  m6: '-6',
		Maj9: 'Δ9',  '9': '9',  m9: '-9',  '6/9': '6/9',
		'Maj7#11': 'Δ7#11',  '7#9': '7#9',  '7b9': '7b9',
		m11: '-11',  '13': '13',  m7b5: 'ø7',  dim7: '°7',
	},
	short: {
		Maj7: 'M7',  '7': '7',  m7: 'mi7',  '6': '6',  m6: 'mi6',
		Maj9: 'M9',  '9': '9',  m9: 'mi9',  '6/9': '6/9',
		'Maj7#11': 'M7#11',  '7#9': '7#9',  '7b9': '7b9',
		m11: 'mi11',  '13': '13',  m7b5: 'mi7b5',  dim7: 'dim7',
	},
};

/** Human-readable voicing labels */
export const VOICING_LABELS: Record<VoicingType, string> = {
	root: 'Root Position',
	shell: 'Shell Voicing',
	'half-shell': 'Half Shell',
	full: 'Full Voicing',
	'rootless-a': 'Rootless A',
	'rootless-b': 'Rootless B',
	'inversion-1': '1st Inversion',
	'inversion-2': '2nd Inversion',
	'inversion-3': '3rd Inversion',
};
