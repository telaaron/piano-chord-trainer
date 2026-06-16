// SEO metadata for /chords/[chord] content pages (Welle 1: all root C).
// The musical data (notes, voicings, intervals) is computed at render time from
// the same engine the trainer uses (src/lib/engine) — this file only holds the
// editorial layer: slugs, prose, and FAQ that can't be derived from intervals.
//
// `quality` MUST match a key in CHORD_INTERVALS (src/lib/engine/chords.ts).

import { getChordNotes } from '$lib/engine/voicings';

export interface ChordPageMeta {
	/** URL slug, e.g. "cmaj7" */
	slug: string;
	/** Root note for engine calls, e.g. "C" */
	root: string;
	/** Internal quality key — must exist in CHORD_INTERVALS, e.g. "Maj7" */
	quality: string;
	/** Human chord name in the title, e.g. "Cmaj7" */
	name: string;
	/** Spoken/long name, e.g. "C major seventh" */
	longName: string;
	/** One-line intent blurb (meta description core). */
	blurb: string;
	/** Where this chord shows up — musical context, 1–2 sentences. */
	context: string;
	/** FAQ pairs → FAQPage schema + on-page accordion. */
	faq: { q: string; a: string }[];
}

// Hand-written pages for root C (Welle 1) — richer, chord-specific copy.
const C_CHORD_PAGES: ChordPageMeta[] = [
	{
		slug: 'cmaj7',
		root: 'C',
		quality: 'Maj7',
		name: 'Cmaj7',
		longName: 'C major seventh',
		blurb:
			'Learn the notes, shell voicing, and rootless voicings of Cmaj7 on piano — then drill it in all 12 keys.',
		context:
			'Cmaj7 is the I chord of a C major ii-V-I (Dm7–G7–Cmaj7) and the most common resting chord in jazz. Its bright, open sound makes it the first voicing most pianists master.',
		faq: [
			{ q: 'What notes are in Cmaj7?', a: 'Cmaj7 is built from C, E, G and B — the root, major third, perfect fifth and major seventh.' },
			{ q: 'What is the shell voicing for Cmaj7?', a: 'The shell voicing keeps only root, third and seventh: C, E, B. It leaves out the fifth so the chord stays clear and uncluttered, which is why jazz pianists use it in the left hand.' },
			{ q: 'What is the difference between Cmaj7 and C6?', a: 'Cmaj7 uses the major seventh (B), giving a lush, slightly tense colour. C6 replaces that B with the sixth (A), giving a more stable, old-school sound often used as a final chord.' },
		],
	},
	{
		slug: 'c7',
		root: 'C',
		quality: '7',
		name: 'C7',
		longName: 'C dominant seventh',
		blurb:
			'The notes, shell and rootless voicings of C7 — the dominant chord that drives every ii-V-I. Practice it in all 12 keys.',
		context:
			'C7 is a dominant chord: the V of F major. Its flat seventh creates the tension that wants to resolve, which is why it sits in the middle of every ii-V-I progression.',
		faq: [
			{ q: 'What notes are in C7?', a: 'C7 contains C, E, G and B♭ — root, major third, perfect fifth and flat (minor) seventh. The flat seventh is what makes it a dominant chord.' },
			{ q: 'What is the shell voicing for C7?', a: 'The C7 shell voicing is C, E, B♭ — root, third and flat seventh. The third and seventh (the guide tones) carry the dominant sound.' },
			{ q: 'Why does C7 sound unresolved?', a: 'The major third (E) and flat seventh (B♭) form a tritone, an unstable interval that pulls toward resolution — typically to F major.' },
		],
	},
	{
		slug: 'cm7',
		root: 'C',
		quality: 'm7',
		name: 'Cm7',
		longName: 'C minor seventh',
		blurb:
			'Notes, shell and rootless voicings of Cm7 on piano — the ii chord of every minor-key ii-V-I. Drill it in all 12 keys.',
		context:
			'Cm7 is the ii chord of a B♭ major ii-V-I and the i chord of C minor. Smooth and mellow, it is one of the four core seventh chords every jazz pianist drills first.',
		faq: [
			{ q: 'What notes are in Cm7?', a: 'Cm7 contains C, E♭, G and B♭ — root, minor third, perfect fifth and flat seventh.' },
			{ q: 'What is the shell voicing for Cm7?', a: 'The Cm7 shell voicing is C, E♭, B♭ — root, minor third and flat seventh.' },
			{ q: 'What is the rootless voicing for Cm7?', a: 'A Cm7 rootless A voicing uses E♭, G, B♭, D — the third, fifth, seventh and ninth. The bassist covers the root, so the pianist plays a fuller upper structure.' },
		],
	},
	{
		slug: 'c6',
		root: 'C',
		quality: '6',
		name: 'C6',
		longName: 'C major sixth',
		blurb:
			'The notes and voicings of C6 — a stable, vintage-sounding major chord. Practice it in all 12 keys on piano.',
		context:
			'C6 replaces the major seventh with the sixth, giving a settled, swing-era sound. It is a common substitute for Cmaj7 as a final tonic chord.',
		faq: [
			{ q: 'What notes are in C6?', a: 'C6 contains C, E, G and A — root, major third, perfect fifth and major sixth.' },
			{ q: 'When do you use C6 instead of Cmaj7?', a: 'C6 is often used as a final resting chord because the sixth sounds more stable and less tense than the major seventh of Cmaj7.' },
		],
	},
	{
		slug: 'cm6',
		root: 'C',
		quality: 'm6',
		name: 'Cm6',
		longName: 'C minor sixth',
		blurb:
			'Notes and voicings of Cm6 on piano — a classic minor tonic colour. Drill it in all 12 keys.',
		context:
			'Cm6 is a frequent minor tonic chord, brighter than Cm7 because of its natural sixth. It also doubles as a rootless dominant voicing a fourth away.',
		faq: [
			{ q: 'What notes are in Cm6?', a: 'Cm6 contains C, E♭, G and A — root, minor third, perfect fifth and major sixth.' },
			{ q: 'Why is Cm6 used as a minor tonic?', a: 'The natural sixth (A) brightens the minor triad and avoids the heavier sound of the minor seventh, which is why it is a favourite final minor chord.' },
		],
	},
	{
		slug: 'cmaj9',
		root: 'C',
		quality: 'Maj9',
		name: 'Cmaj9',
		longName: 'C major ninth',
		blurb:
			'The notes and rootless voicings of Cmaj9 — a lush extended tonic chord. Practice it in all 12 keys on piano.',
		context:
			'Cmaj9 adds the ninth on top of Cmaj7 for a rich, modern tonic sound. It is a staple resting chord in ballads and modal jazz.',
		faq: [
			{ q: 'What notes are in Cmaj9?', a: 'Cmaj9 contains C, E, G, B and D — root, major third, fifth, major seventh and ninth.' },
			{ q: 'What is the rootless voicing for Cmaj9?', a: 'A rootless Cmaj9 voicing plays E, G, B, D (third, fifth, seventh, ninth), letting the bass cover the root for a fuller upper structure.' },
		],
	},
	{
		slug: 'c9',
		root: 'C',
		quality: '9',
		name: 'C9',
		longName: 'C dominant ninth',
		blurb:
			'Notes and rootless voicings of C9 — a colourful dominant chord. Drill it in all 12 keys on piano.',
		context:
			'C9 extends C7 with a ninth, a brighter dominant colour heard constantly in blues, funk and bebop. The rootless voicing is the bread-and-butter left-hand shape.',
		faq: [
			{ q: 'What notes are in C9?', a: 'C9 contains C, E, G, B♭ and D — root, third, fifth, flat seventh and ninth.' },
			{ q: 'What is the rootless A voicing for C9?', a: 'C9 rootless A is E, G, B♭, D — third, fifth, flat seventh and ninth. It is one of the most-used left-hand dominant voicings in jazz.' },
		],
	},
	{
		slug: 'cm9',
		root: 'C',
		quality: 'm9',
		name: 'Cm9',
		longName: 'C minor ninth',
		blurb:
			'The notes and rootless voicings of Cm9 — a smooth, modern minor chord. Practice it in all 12 keys.',
		context:
			'Cm9 adds the ninth to Cm7 for a warm, contemporary minor sound. It is a favourite ii chord and minor tonic in modal jazz and neo-soul.',
		faq: [
			{ q: 'What notes are in Cm9?', a: 'Cm9 contains C, E♭, G, B♭ and D — root, minor third, fifth, flat seventh and ninth.' },
			{ q: 'What is the rootless voicing for Cm9?', a: 'A rootless Cm9 voicing plays E♭, G, B♭, D — third, fifth, seventh and ninth — letting the bassist cover the root.' },
		],
	},
	{
		slug: 'cmaj7sharp11',
		root: 'C',
		quality: 'Maj7#11',
		name: 'Cmaj7#11',
		longName: 'C major seven sharp eleven',
		blurb:
			'Notes and voicings of Cmaj7#11 — the lydian tonic chord. Drill this advanced colour in all 12 keys.',
		context:
			'Cmaj7#11 raises the eleventh for a floating, lydian sound. It is the go-to voicing for a bright, modern major tonic in film and modal jazz writing.',
		faq: [
			{ q: 'What notes are in Cmaj7#11?', a: 'Cmaj7#11 contains C, E, G, B and F♯ — root, third, fifth, major seventh and sharp eleventh.' },
			{ q: 'Why is Cmaj7#11 called a lydian chord?', a: 'The raised eleventh (F♯) is the characteristic note of the C lydian mode, giving the chord its bright, suspended quality.' },
		],
	},
	{
		slug: 'c7sharp9',
		root: 'C',
		quality: '7#9',
		name: 'C7#9',
		longName: 'C seven sharp nine',
		blurb:
			'The notes and voicings of C7#9 — the "Hendrix chord". Practice this altered dominant in all 12 keys.',
		context:
			'C7#9 is an altered dominant famous from rock and bebop alike. The clash between the major third and the sharp ninth gives it a gritty, bluesy tension.',
		faq: [
			{ q: 'What notes are in C7#9?', a: 'C7#9 contains C, E, G, B♭ and D♯ — root, third, fifth, flat seventh and sharp ninth.' },
			{ q: 'Why is C7#9 called the Hendrix chord?', a: 'Jimi Hendrix made the dominant 7#9 voicing iconic in rock; the sharp ninth grinding against the major third gives it its signature bite.' },
		],
	},
	{
		slug: 'c7b9',
		root: 'C',
		quality: '7b9',
		name: 'C7b9',
		longName: 'C seven flat nine',
		blurb:
			'Notes and voicings of C7b9 — a dark altered dominant. Drill it in all 12 keys on piano.',
		context:
			'C7b9 is an altered dominant that resolves powerfully to a minor or major tonic. The flat ninth adds a tense, dramatic colour heard throughout bebop.',
		faq: [
			{ q: 'What notes are in C7b9?', a: 'C7b9 contains C, E, G, B♭ and D♭ — root, third, fifth, flat seventh and flat ninth.' },
			{ q: 'When do you use C7b9?', a: 'C7b9 is commonly used as a V chord resolving to a minor i, where its flat ninth strengthens the pull toward resolution.' },
		],
	},
	{
		slug: 'cm11',
		root: 'C',
		quality: 'm11',
		name: 'Cm11',
		longName: 'C minor eleventh',
		blurb:
			'The notes and voicings of Cm11 — a spacious modal minor chord. Practice it in all 12 keys.',
		context:
			'Cm11 stacks the eleventh on a minor ninth for an open, suspended sound. It is a defining colour of modal and contemporary jazz piano.',
		faq: [
			{ q: 'What notes are in Cm11?', a: 'Cm11 contains C, E♭, G, B♭, D and F — root, minor third, fifth, flat seventh, ninth and eleventh.' },
			{ q: 'How do you voice Cm11 on piano?', a: 'A common Cm11 voicing omits the fifth and stacks fourths in the right hand (e.g. B♭, E♭, F) over the root, producing its characteristic open sound.' },
		],
	},
	{
		slug: 'c13',
		root: 'C',
		quality: '13',
		name: 'C13',
		longName: 'C dominant thirteenth',
		blurb:
			'Notes and voicings of C13 — the full dominant colour. Drill this rich chord in all 12 keys.',
		context:
			'C13 is the largest common dominant chord, adding the thirteenth for a warm, complete sound. The thirteenth and third/seventh guide tones do most of the work.',
		faq: [
			{ q: 'What notes are in C13?', a: 'C13 contains C, E, G, B♭, D and A — root, third, fifth, flat seventh, ninth and thirteenth.' },
			{ q: 'How do you voice C13 with two hands?', a: 'A typical C13 voicing plays the guide tones E and B♭ in the left hand and adds the ninth (D) and thirteenth (A) on top in the right hand.' },
		],
	},
	{
		slug: 'cm7b5',
		root: 'C',
		quality: 'm7b5',
		name: 'Cm7b5',
		longName: 'C half-diminished seventh',
		blurb:
			'The notes and voicings of Cm7b5 (half-diminished) — the ii chord of a minor ii-V-i. Practice it in all 12 keys.',
		context:
			'Cm7b5, the half-diminished chord, is the ii chord of a B♭ minor ii-V-i. Its lowered fifth gives the tense, unresolved colour that defines minor-key jazz.',
		faq: [
			{ q: 'What notes are in Cm7b5?', a: 'Cm7b5 contains C, E♭, G♭ and B♭ — root, minor third, diminished (flat) fifth and flat seventh.' },
			{ q: 'What is the difference between Cm7b5 and Cdim7?', a: 'Both lower the fifth, but Cm7b5 keeps a flat seventh (B♭) while Cdim7 uses a diminished seventh (B♭♭ / A), making the diminished chord fully symmetrical.' },
		],
	},
];

// ─── Welle 2: top-5 chord types × the other 11 keys ─────────────────────────
// C is already covered by the hand-written pages above, so the generator skips
// it. Musical data is still computed at render time from the engine — these
// templates only fill the editorial layer, with the root spliced in.

/** The 11 non-C roots, each with the conventional enharmonic spelling for its
 *  key (flat keys use flats) and a URL-safe slug. One page per pitch class —
 *  no separate C#/Db pages, to avoid two pages competing for the same chord. */
const GEN_ROOTS: { root: string; slug: string; spoken: string }[] = [
	{ root: 'Db', slug: 'db', spoken: 'D-flat' },
	{ root: 'D', slug: 'd', spoken: 'D' },
	{ root: 'Eb', slug: 'eb', spoken: 'E-flat' },
	{ root: 'E', slug: 'e', spoken: 'E' },
	{ root: 'F', slug: 'f', spoken: 'F' },
	{ root: 'F#', slug: 'fsharp', spoken: 'F-sharp' },
	{ root: 'G', slug: 'g', spoken: 'G' },
	{ root: 'Ab', slug: 'ab', spoken: 'A-flat' },
	{ root: 'A', slug: 'a', spoken: 'A' },
	{ root: 'Bb', slug: 'bb', spoken: 'B-flat' },
	{ root: 'B', slug: 'b', spoken: 'B' },
];

/** Per-type editorial templates. `r` = root note (correctly spelled per key),
 *  `notes` = the chord's notes as a readable string (computed at build time). */
interface TypeTemplate {
	quality: string;
	/** Suffix appended to the root for the display name, e.g. "maj7" → "Cmaj7". */
	suffix: string;
	/** Spoken quality, e.g. "major seventh". */
	spokenQuality: string;
	slugSuffix: string;
	blurb: (r: string, name: string) => string;
	context: (r: string, name: string) => string;
	faq: (r: string, name: string, notes: string) => { q: string; a: string }[];
}

const GEN_TYPES: TypeTemplate[] = [
	{
		quality: 'Maj7',
		suffix: 'maj7',
		slugSuffix: 'maj7',
		spokenQuality: 'major seventh',
		blurb: (r, name) =>
			`Learn the notes, shell voicing, and rootless voicings of ${name} on piano — then drill it in all 12 keys.`,
		context: (r, name) =>
			`${name} is a major-seventh chord, the bright, restful "home" sound of jazz. It is the I chord wherever ${r} is the key centre, and one of the first voicings worth making automatic.`,
		faq: (r, name, notes) => [
			{ q: `What notes are in ${name}?`, a: `${name} is built from ${notes} — the root, major third, perfect fifth and major seventh.` },
			{ q: `What is the shell voicing for ${name}?`, a: `The ${name} shell voicing keeps only root, third and seventh, dropping the fifth so the chord stays clear in the left hand.` },
			{ q: `What is the rootless voicing for ${name}?`, a: `A rootless ${name} voicing plays the third, fifth, seventh and ninth, letting the bassist cover the root for a fuller upper structure.` },
		],
	},
	{
		quality: '7',
		suffix: '7',
		slugSuffix: '7',
		spokenQuality: 'dominant seventh',
		blurb: (r, name) =>
			`The notes, shell and rootless voicings of ${name} — the dominant chord that drives a ii-V-I. Practice it in all 12 keys.`,
		context: (r, name) =>
			`${name} is a dominant chord: the V that wants to resolve. Its flat seventh creates the tension at the heart of every ii-V-I, making ${name} one of the four core shapes to drill.`,
		faq: (r, name, notes) => [
			{ q: `What notes are in ${name}?`, a: `${name} contains ${notes} — root, major third, perfect fifth and flat seventh. The flat seventh is what makes it a dominant chord.` },
			{ q: `What is the shell voicing for ${name}?`, a: `The ${name} shell voicing is root, third and flat seventh. The third and seventh — the guide tones — carry the dominant sound.` },
			{ q: `Why does ${name} sound unresolved?`, a: `The major third and flat seventh of ${name} form a tritone, an unstable interval that pulls strongly toward resolution.` },
		],
	},
	{
		quality: 'm7',
		suffix: 'm7',
		slugSuffix: 'm7',
		spokenQuality: 'minor seventh',
		blurb: (r, name) =>
			`Notes, shell and rootless voicings of ${name} on piano — the ii chord of a ii-V-I. Drill it in all 12 keys.`,
		context: (r, name) =>
			`${name} is a minor-seventh chord, smooth and mellow. It is the ii chord that opens a ii-V-I and a minor tonic in its own right — one of the four core seventh chords every pianist drills first.`,
		faq: (r, name, notes) => [
			{ q: `What notes are in ${name}?`, a: `${name} contains ${notes} — root, minor third, perfect fifth and flat seventh.` },
			{ q: `What is the shell voicing for ${name}?`, a: `The ${name} shell voicing keeps root, minor third and flat seventh, dropping the fifth.` },
			{ q: `What is the rootless voicing for ${name}?`, a: `A rootless ${name} voicing plays the third, fifth, seventh and ninth — the Bill Evans shape used over a walking bass.` },
		],
	},
	{
		quality: '6',
		suffix: '6',
		slugSuffix: '6',
		spokenQuality: 'major sixth',
		blurb: (r, name) =>
			`The notes and voicings of ${name} — a stable, vintage-sounding major chord. Practice it in all 12 keys on piano.`,
		context: (r, name) =>
			`${name} replaces the major seventh with the sixth, giving a settled, swing-era sound. It is a common substitute for the major-seventh chord as a final tonic.`,
		faq: (r, name, notes) => [
			{ q: `What notes are in ${name}?`, a: `${name} contains ${notes} — root, major third, perfect fifth and major sixth.` },
			{ q: `When do you use ${name}?`, a: `${name} is often used as a final resting chord, because the sixth sounds more stable and less tense than a major seventh.` },
		],
	},
	{
		quality: 'm7b5',
		suffix: 'm7b5',
		slugSuffix: 'm7b5',
		spokenQuality: 'half-diminished seventh',
		blurb: (r, name) =>
			`The notes and voicings of ${name} (half-diminished) — the ii chord of a minor ii-V-i. Practice it in all 12 keys.`,
		context: (r, name) =>
			`${name}, the half-diminished chord, is the ii chord of a minor ii-V-i. Its lowered fifth gives the tense, unresolved colour that defines minor-key jazz.`,
		faq: (r, name, notes) => [
			{ q: `What notes are in ${name}?`, a: `${name} contains ${notes} — root, minor third, diminished (flat) fifth and flat seventh.` },
			{ q: `What is ${name} used for?`, a: `${name} most often appears as the ii chord in a minor ii-V-i, setting up the dominant that resolves to a minor tonic.` },
		],
	},
];

/** Build the readable note string for a chord, spelled correctly for its key. */
function notesFor(root: string, quality: string): string {
	const notes = getChordNotes(root, quality, 'both');
	return notes.join(', ');
}

function generatePages(): ChordPageMeta[] {
	const pages: ChordPageMeta[] = [];
	for (const { root, slug, spoken } of GEN_ROOTS) {
		for (const tpl of GEN_TYPES) {
			const name = `${root}${tpl.suffix}`;
			const notes = notesFor(root, tpl.quality);
			pages.push({
				slug: `${slug}${tpl.slugSuffix}`,
				root,
				quality: tpl.quality,
				name,
				longName: `${spoken} ${tpl.spokenQuality}`,
				blurb: tpl.blurb(root, name),
				context: tpl.context(root, name),
				faq: tpl.faq(root, name, notes),
			});
		}
	}
	return pages;
}

export const CHORD_PAGES: ChordPageMeta[] = [...C_CHORD_PAGES, ...generatePages()];

const PAGE_BY_SLUG = new Map(CHORD_PAGES.map((p) => [p.slug, p]));

export function getChordPage(slug: string): ChordPageMeta | undefined {
	return PAGE_BY_SLUG.get(slug);
}

export const CHORD_PAGE_SLUGS = CHORD_PAGES.map((p) => p.slug);
