import type { RequestHandler } from './$types';
import { CHORD_PAGE_SLUGS } from '$lib/seo/chords';

// Single source of truth for indexable URLs.
// `updated` is the date the page's CONTENT last changed — bump it in the same
// commit that edits the page. Google ignores lastmod once it learns the value
// doesn't track real changes, so never derive it from the build date.
type SitemapPage = { path: string; priority: number; freq: string; updated: string };

const STATIC_PAGES: SitemapPage[] = [
	{ path: '/', priority: 1.0, freq: 'weekly', updated: '2026-07-30' },
	{ path: '/learn', priority: 0.8, freq: 'weekly', updated: '2026-07-26' },
	{ path: '/learn/jazz-piano-voicings', priority: 0.9, freq: 'weekly', updated: '2026-07-26' },
	{ path: '/learn/ii-v-i', priority: 0.9, freq: 'weekly', updated: '2026-10-16' },
	{ path: '/learn/ii-v-i-all-keys', priority: 0.9, freq: 'monthly', updated: '2026-10-16' },
	{ path: '/learn/jazz-voicing-practice-apps', priority: 0.8, freq: 'monthly', updated: '2026-10-16' },
	{ path: '/de/ii-v-i-alle-tonarten', priority: 0.8, freq: 'monthly', updated: '2026-10-16' },
	{ path: '/de/voicings-linke-hand', priority: 0.8, freq: 'monthly', updated: '2026-10-16' },
	{ path: '/de/jazz-klavier-aufnahmepruefung', priority: 0.8, freq: 'monthly', updated: '2026-10-16' },
	{ path: '/learn/lead-sheets-for-classical-pianists', priority: 0.8, freq: 'monthly', updated: '2026-10-16' },
	{ path: '/learn/rootless-voicings', priority: 0.9, freq: 'weekly', updated: '2026-07-26' },
	{ path: '/for-educators', priority: 0.8, freq: 'monthly', updated: '2026-07-30' },
	{ path: '/open-studio', priority: 0.7, freq: 'monthly', updated: '2026-07-30' },
	{ path: '/pricing', priority: 0.7, freq: 'monthly', updated: '2026-07-31' },
	{ path: '/about', priority: 0.5, freq: 'yearly', updated: '2026-07-30' },
];

// Content pages — one per chord type (Welle 1). They share one template, so
// they share one date: bump it when the template or src/lib/seo/chords.ts changes.
const CHORD_PAGES_UPDATED = '2026-10-16';
const CHORD_PAGES: SitemapPage[] = CHORD_PAGE_SLUGS.map((slug) => ({
	path: `/chords/${slug}`,
	priority: 0.8,
	freq: 'monthly',
	updated: CHORD_PAGES_UPDATED,
}));

const PAGES = [...STATIC_PAGES, ...CHORD_PAGES];

const BASE = 'https://jazzchords.app';

export const prerender = true;

export const GET: RequestHandler = async () => {
	const urls = PAGES.map(
		(p) => `  <url>
    <loc>${BASE}${p.path}</loc>
    <lastmod>${p.updated}</lastmod>
    <changefreq>${p.freq}</changefreq>
    <priority>${p.priority.toFixed(1)}</priority>
  </url>`
	).join('\n');

	const body = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>
`;

	return new Response(body, {
		headers: {
			'Content-Type': 'application/xml',
			'Cache-Control': 'public, max-age=3600',
		},
	});
};
