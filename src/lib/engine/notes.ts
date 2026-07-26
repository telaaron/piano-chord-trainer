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
	// White-key accidentals — produced by theory-correct chord spelling
	// (e.g. Abm7b5 → Cb). Map to their natural equivalent so the keyboard
	// and semitone lookup never break.
	'Cb': 'B', 'B#': 'C', 'Fb': 'E', 'E#': 'F',
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

/**
 * For 'both' preference, determine if a root/key semitone conventionally uses sharps.
 * Sharp keys: C(0), D(2), E(4), F#/Gb(6), G(7), A(9), B(11)
 * Flat keys:  Db(1), Eb(3), F(5), Ab(8), Bb(10)
 */
const FLAT_ROOTS = new Set([1, 3, 5, 8, 10]);
export function usesSharps(semitone: number): boolean {
	return !FLAT_ROOTS.has(((semitone % 12) + 12) % 12);
}

// ─── Theory-correct chord spelling ──────────────────────────────────────────
// The 7 letter names and their natural (no-accidental) semitone positions.
const LETTERS = ['C', 'D', 'E', 'F', 'G', 'A', 'B'] as const;
const LETTER_SEMITONES: Record<string, number> = {
	C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11,
};

/** Map a chromatic interval (semitones from root) to its diatonic degree
 *  (0-based letter step). e.g. minor 3rd (3 semis) and major 3rd (4 semis)
 *  are both "a third" → 2 letter steps. Covers all intervals used by chords. */
const INTERVAL_TO_LETTER_STEP: Record<number, number> = {
	0: 0,   // root
	1: 1,   // ♭9 / ♭2  → a second
	2: 1,   // 9 / 2
	3: 2,   // ♭3       → a third
	4: 2,   // 3
	5: 3,   // 11 / 4   → a fourth
	6: 3,   // ♯11 / ♯4 → a fourth (sharpened); diminished 5th handled per-chord below
	7: 4,   // 5
	8: 5,   // ♭13 / ♭6 → a sixth
	9: 5,   // 13 / 6
	10: 6,  // ♭7       → a seventh
	11: 6,  // 7
};

/** For a few intervals the correct letter depends on the chord context
 *  (e.g. a ♭5 is a *fifth* spelled flat, but a ♯11 is a *fourth* spelled
 *  sharp — same 6 semitones). The caller passes the desired letter step. */
function spellAt(rootLetterIndex: number, rootSemitone: number, letterStep: number, targetSemitoneFromRoot: number): string {
	const letterIdx = (rootLetterIndex + letterStep) % 7;
	const letter = LETTERS[letterIdx];
	const targetPc = (rootSemitone + targetSemitoneFromRoot) % 12;
	const naturalPc = LETTER_SEMITONES[letter];
	// Smallest signed accidental to move from the natural letter pitch to target.
	let diff = ((targetPc - naturalPc) % 12 + 12) % 12;
	if (diff > 6) diff -= 12; // prefer flats over many sharps (e.g. -1 not +11)
	// Avoid double accidentals (Ebb, F##) — jazz lead-sheets favour the simpler
	// single-accidental enharmonic (write Eb, not Ebb). Fall back to the plain
	// flat/sharp name at the target pitch class.
	if (Math.abs(diff) > 1) {
		return NOTES_FLATS[targetPc];
	}
	const acc = diff > 0 ? '#'.repeat(diff) : 'b'.repeat(-diff);
	return letter + acc;
}

/**
 * Spell a chord's notes with theoretically correct accidentals, so the same
 * letter is never used twice and quality drives the spelling.
 *   Cm7 → C, Eb, G, Bb   (not C, D#, G, A#)
 *   C7  → C, E,  G, Bb
 *   F#7 → F#, A#, C#, E
 * `intervals` are semitone offsets from the root (from CHORD_INTERVALS).
 */
export function spellChordNotes(root: string, intervals: number[]): string[] {
	const rootSemi = noteToSemitone(root);
	if (rootSemi === -1) return [];
	// Determine the root's letter. Prefer the explicit letter in `root`
	// (e.g. "Db" → D, "F#" → F); fall back to the flat-spelling letter.
	const rootLetter = root[0].toUpperCase();
	const rootLetterIndex = LETTERS.indexOf(rootLetter as (typeof LETTERS)[number]);
	const baseIndex = rootLetterIndex === -1 ? 0 : rootLetterIndex;

	return intervals.map((iv) => {
		const pc = ((iv % 12) + 12) % 12;
		let step = INTERVAL_TO_LETTER_STEP[pc] ?? 0;
		// Diminished 5th (6 semis) inside a chord that has no natural 5th elsewhere
		// should read as a *fifth* (♭5), not a ♯11. Heuristic: if the chord also
		// contains a perfect 4th/11th this is a ♯11; otherwise a ♭5.
		if (pc === 6 && !intervals.some((x) => ((x % 12) + 12) % 12 === 5)) {
			step = 4; // a fifth
		}
		return spellAt(baseIndex, rootSemi, step, iv % 12);
	});
}

/** Get note name at a given semitone offset from root */
export function getNoteName(rootSemitone: number, interval: number, pref: AccidentalPreference): string {
	const index = (rootSemitone + interval) % 12;
	if (pref === 'sharps') return NOTES_SHARPS[index];
	if (pref === 'flats') return NOTES_FLATS[index];
	// 'both': choose sharps/flats based on the chord root's key context
	return usesSharps(rootSemitone) ? NOTES_SHARPS[index] : NOTES_FLATS[index];
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

// ─── Pitched notes (with octave) ────────────────────────────

/**
 * A note name WITH its octave, e.g. "Bb4" — what a synth needs to sound the
 * right pitch.
 *
 * `getNoteName` returns a pitch class, which is correct for naming a chord
 * tone but cannot express direction: C→B is a major seventh UP or a minor
 * second DOWN, and the name alone does not say which. Ear training has to
 * say which, so intervals are built from an absolute semitone offset here.
 *
 * @param rootSemitone pitch class of the starting note (0 = C)
 * @param interval signed semitone distance; negative descends
 * @param octave octave of the starting note in scientific pitch notation
 */
export function getPitchedNote(
	rootSemitone: number,
	interval: number,
	pref: AccidentalPreference,
	octave = 4,
): string {
	const abs = rootSemitone + interval;
	// Floor-divide so descending intervals cross the octave boundary correctly:
	// C4 down a minor second is B3, not B4.
	const oct = octave + Math.floor(abs / 12);
	const index = ((abs % 12) + 12) % 12;
	const names =
		pref === 'sharps'
			? NOTES_SHARPS
			: pref === 'flats'
				? NOTES_FLATS
				: usesSharps(rootSemitone)
					? NOTES_SHARPS
					: NOTES_FLATS;
	return `${names[index]}${oct}`;
}
