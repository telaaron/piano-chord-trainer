// Regenerates the printable ii-V-I chart PDFs in static/downloads/ from the
// print layout of the prerendered pages. Run after changing the chart or its
// print CSS:
//   pnpm build && pnpm exec vite preview --port 4317 &
//   node tools/growth/make-chart-pdfs.mjs
// Uses the globally installed Playwright (PLAYWRIGHT_BROWSERS_PATH).
import { createRequire } from 'node:module';
import { execSync } from 'node:child_process';
import { resolve } from 'node:path';

const globalRoot = execSync('npm root -g').toString().trim();
const { chromium } = createRequire(import.meta.url)(resolve(globalRoot, 'playwright'));

const BASE = process.env.BASE ?? 'http://localhost:4317';
const PAGES = [
	['/learn/ii-v-i-all-keys', 'ii-v-i-all-keys.pdf'],
	['/de/ii-v-i-alle-tonarten', 'ii-v-i-alle-tonarten.pdf'],
];

const browser = await chromium.launch();
const page = await browser.newPage();
for (const [path, file] of PAGES) {
	await page.goto(BASE + path, { waitUntil: 'networkidle' });
	await page.pdf({
		path: resolve('static/downloads', file),
		format: 'A4',
		margin: { top: '14mm', bottom: '14mm', left: '14mm', right: '14mm' },
	});
	console.log('wrote static/downloads/' + file);
}
await browser.close();
