// Data for /learn/ii-v-i-all-keys: the major ii-V-I in all 12 keys, voiced by
// the same engine the trainer uses so the page and the drill never disagree.

import { getChordNotes, getVoicingNotes } from '$lib/engine/voicings';
import type { VoicingType } from '$lib/engine/chords';
import { CHORD_PAGE_SLUGS } from './chords';

/** Engine roots for ii, V and I, plus the key's display name. */
interface KeyRoots {
	key: string;
	ii: string;
	V: string;
	I: string;
}

// Circle of fourths from C — the order most teachers drill it in.
// Roots are spelled as the key spells them (G♭ major → A♭m7 D♭7 G♭maj7,
// B major → C♯m7 F♯7 Bmaj7).
export const IIVI_KEYS: KeyRoots[] = [
	{ key: 'C', ii: 'D', V: 'G', I: 'C' },
	{ key: 'F', ii: 'G', V: 'C', I: 'F' },
	{ key: 'B♭', ii: 'C', V: 'F', I: 'Bb' },
	{ key: 'E♭', ii: 'F', V: 'Bb', I: 'Eb' },
	{ key: 'A♭', ii: 'Bb', V: 'Eb', I: 'Ab' },
	{ key: 'D♭', ii: 'Eb', V: 'Ab', I: 'Db' },
	{ key: 'G♭', ii: 'Ab', V: 'Db', I: 'Gb' },
	{ key: 'B', ii: 'C#', V: 'F#', I: 'B' },
	{ key: 'E', ii: 'F#', V: 'B', I: 'E' },
	{ key: 'A', ii: 'B', V: 'E', I: 'A' },
	{ key: 'D', ii: 'E', V: 'A', I: 'D' },
	{ key: 'G', ii: 'A', V: 'D', I: 'G' },
];

/**
 * How the three chords are voiced.
 * Rootless voicings alternate A and B forms so each chord moves to the next by
 * step — the standard left-hand ii-V-I. `rootless-ab` starts on A (ii A, V B,
 * I A), `rootless-ba` on B.
 */
export type IIVIVoicing = 'shell' | 'rootless-ab' | 'rootless-ba';

const VOICING_PLAN: Record<IIVIVoicing, [VoicingType, VoicingType, VoicingType]> = {
	shell: ['shell', 'shell', 'shell'],
	'rootless-ab': ['rootless-a', 'rootless-b', 'rootless-a'],
	'rootless-ba': ['rootless-b', 'rootless-a', 'rootless-b'],
};

export interface IIVIChord {
	degree: 'ii' | 'V' | 'I';
	/** Display name with proper accidentals, e.g. "A♭m7" */
	name: string;
	/** Voiced notes, bottom to top, engine spelling ("Db", "F#") */
	notes: string[];
	/** /chords/{slug} when such a page exists, else null */
	slug: string | null;
}

export interface IIVIRow {
	key: string;
	chords: [IIVIChord, IIVIChord, IIVIChord];
}

const QUALITY = { ii: 'm7', V: '7', I: 'Maj7' } as const;
const SUFFIX = { ii: 'm7', V: '7', I: 'maj7' } as const;

function pretty(root: string): string {
	return root.replace('#', '♯').replace(/^([A-G])b/, '$1♭');
}

function slugFor(root: string, degree: 'ii' | 'V' | 'I'): string | null {
	const slug = root.toLowerCase().replace('#', 'sharp') + SUFFIX[degree];
	return CHORD_PAGE_SLUGS.includes(slug) ? slug : null;
}

export function buildIIVITable(voicing: IIVIVoicing): IIVIRow[] {
	const plan = VOICING_PLAN[voicing];
	return IIVI_KEYS.map((k) => {
		const chords = (['ii', 'V', 'I'] as const).map((degree, i) => {
			const root = k[degree];
			const all = getChordNotes(root, QUALITY[degree], 'both');
			return {
				degree,
				name: pretty(root) + SUFFIX[degree],
				notes: getVoicingNotes(all, plan[i], root, 'both'),
				slug: slugFor(root, degree),
			};
		}) as IIVIRow['chords'];
		return { key: k.key, chords };
	});
}
