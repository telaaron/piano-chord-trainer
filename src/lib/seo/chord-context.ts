// Where a chord lives: the ii-V-I it belongs to, spelled for a real key.
// Computed for every /chords/{slug} page so each page states chord-specific
// harmony (and links its neighbours) instead of sharing one template sentence.

import { noteToSemitone, spellChordNotes } from '$lib/engine/notes';
import { CHORD_PAGE_SLUGS } from './chords';

export interface ProgressionChord {
	degree: 'ii' | 'V' | 'I' | 'i';
	/** Display name with ♭/♯, e.g. "A♭m7" */
	name: string;
	/** Existing /chords/{slug} page (enharmonic fallback), else null */
	slug: string | null;
	/** True for the chord the page is about */
	self: boolean;
}

export interface ChordProgression {
	/** e.g. "A♭ major", "C minor" */
	key: string;
	/** The page chord's degree in that key */
	role: 'I' | 'V' | 'ii';
	chords: ProgressionChord[];
	/** The page chord's name as spelled in this key, when it differs (Dbm7 → "C♯m7") */
	enharmonic: string | null;
}

// Keys as written in practice (≤ 6 accidentals; F♯ and G♭ both common).
const MAJOR_KEYS = ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'Gb', 'Db', 'Ab', 'Eb', 'Bb', 'F'];
const MINOR_KEYS = ['A', 'E', 'B', 'F#', 'C#', 'G#', 'Eb', 'Bb', 'F', 'C', 'G', 'D'];
// Preferred spelling per pitch class when the derived spelling isn't a usable key.
const MAJOR_BY_PC = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
const MINOR_BY_PC = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'];
// Chord-page roots per pitch class (matches GEN_ROOTS + C in chords.ts).
const PAGE_ROOT_BY_PC = ['c', 'db', 'd', 'eb', 'e', 'f', 'fsharp', 'g', 'ab', 'a', 'bb', 'b'];

const up = (root: string, semis: number) => spellChordNotes(root, [0, semis])[1];
const pretty = (n: string) => n.replace('#', '♯').replace(/^([A-G])b/, '$1♭');

function usableKey(candidate: string, minor: boolean): string {
	const keys = minor ? MINOR_KEYS : MAJOR_KEYS;
	if (keys.includes(candidate)) return candidate;
	const pc = noteToSemitone(candidate);
	return (minor ? MINOR_BY_PC : MAJOR_BY_PC)[pc];
}

function slugFor(root: string, suffix: string): string | null {
	const direct = root.toLowerCase().replace('#', 'sharp') + suffix;
	if (CHORD_PAGE_SLUGS.includes(direct)) return direct;
	const pc = noteToSemitone(root);
	const fallback = pc === -1 ? null : PAGE_ROOT_BY_PC[pc] + suffix;
	return fallback && CHORD_PAGE_SLUGS.includes(fallback) ? fallback : null;
}

const SUFFIX = { m7: 'm7', '7': '7', Maj7: 'maj7', m7b5: 'm7b5', m6: 'm6' } as const;
const DISPLAY = { m7: 'm7', '7': '7', Maj7: 'maj7', m7b5: 'm7♭5', m6: 'm6' } as const;

function chord(
	degree: ProgressionChord['degree'],
	root: string,
	q: keyof typeof SUFFIX,
	self: boolean,
): ProgressionChord {
	return { degree, name: pretty(root) + DISPLAY[q], slug: slugFor(root, SUFFIX[q]), self };
}

/**
 * The major (or, for m7b5, minor) ii-V-I this chord belongs to.
 * Maj7 and 6 → I · 7 → V · m7 → ii · m7b5 → ii of a minor ii-V-i.
 */
export function progressionFor(root: string, quality: string): ChordProgression | null {
	let key: string;
	let role: ChordProgression['role'];
	let minor = false;

	switch (quality) {
		case 'Maj7':
		case '6':
			key = usableKey(root, false);
			role = 'I';
			break;
		case '7':
			key = usableKey(up(root, 5), false);
			role = 'V';
			break;
		case 'm7':
			key = usableKey(up(root, 10), false);
			role = 'ii';
			break;
		case 'm7b5':
			key = usableKey(up(root, 10), true);
			role = 'ii';
			minor = true;
			break;
		default:
			return null;
	}

	const ii = up(key, 2);
	const V = up(key, 7);
	const chords = minor
		? [chord('ii', ii, 'm7b5', true), chord('V', V, '7', false), chord('i', key, 'm6', false)]
		: [
				chord('ii', ii, 'm7', role === 'ii'),
				chord('V', V, '7', role === 'V'),
				chord('I', key, 'Maj7', role === 'I'),
			];

	const selfChord = chords.find((c) => c.self)!;
	// A 6 chord is shown as the maj7 I of its key; its own name is never "respelled".
	const pageName = pretty(root) + (quality === '6' ? 'maj7' : DISPLAY[quality as keyof typeof DISPLAY]);
	const enharmonic = selfChord.name === pageName ? null : selfChord.name;

	return { key: `${pretty(key)} ${minor ? 'minor' : 'major'}`, role, chords, enharmonic };
}
