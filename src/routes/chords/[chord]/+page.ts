import { error } from '@sveltejs/kit';
import { getChordPage, CHORD_PAGE_SLUGS } from '$lib/seo/chords';
import { getChordNotes, getVoicingNotes, getVoicingIntervalLabels, getChordFormula } from '$lib/engine/voicings';
import type { VoicingType } from '$lib/engine/chords';
import type { EntryGenerator, PageLoad } from './$types';

// Prerender every chord page to static HTML for fast crawl + indexing.
export const prerender = true;

// Tell SvelteKit which dynamic params to render at build time.
export const entries: EntryGenerator = () => CHORD_PAGE_SLUGS.map((chord) => ({ chord }));

// Voicings showcased on each page, in pedagogical order.
const SHOWCASE_VOICINGS: VoicingType[] = ['root', 'shell', 'rootless-a', 'rootless-b'];

export const load: PageLoad = ({ params }) => {
	const meta = getChordPage(params.chord);
	if (!meta) throw error(404, `No chord page for "${params.chord}"`);

	const notes = getChordNotes(meta.root, meta.quality, 'flats');
	const formula = getChordFormula(meta.quality);

	const voicings = SHOWCASE_VOICINGS.map((type) => {
		const voicingNotes = getVoicingNotes(notes, type, meta.root, 'flats');
		const intervals = getVoicingIntervalLabels(voicingNotes, meta.root, meta.quality);
		return { type, notes: voicingNotes, intervals };
	});

	return { meta, notes, formula, voicings };
};
