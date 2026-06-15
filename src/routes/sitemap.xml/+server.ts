import type { RequestHandler } from './$types';

// Single source of truth for indexable URLs. Add /chords/* and /learn/* entries
// here as content pages ship. lastmod is generated at build time so Google sees
// a fresh signal instead of a hard-coded stale date.
const PAGES: { path: string; priority: number; freq: string }[] = [
	{ path: '/', priority: 1.0, freq: 'weekly' },
	{ path: '/for-educators', priority: 0.8, freq: 'monthly' },
	{ path: '/open-studio', priority: 0.7, freq: 'monthly' },
	{ path: '/pricing', priority: 0.7, freq: 'monthly' },
	{ path: '/about', priority: 0.5, freq: 'yearly' },
];

const BASE = 'https://jazzchords.app';

export const prerender = true;

export const GET: RequestHandler = async () => {
	const lastmod = new Date().toISOString().split('T')[0];
	const urls = PAGES.map(
		(p) => `  <url>
    <loc>${BASE}${p.path}</loc>
    <lastmod>${lastmod}</lastmod>
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
