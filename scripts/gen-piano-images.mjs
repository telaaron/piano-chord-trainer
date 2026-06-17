// Generate the three landing "story" illustrations from scratch in the new
// midnight-indigo + amber brand. Abstract, premium 3D scenes (not the old
// brown toy piano). One cohesive set telling See → Play → Master.
//
//   FAL_KEY=... node scripts/gen-piano-images.mjs
//
// Outputs transparent PNGs into static/bilder/.

import { fal } from '@fal-ai/client';
import { writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const KEY = process.env.FAL_KEY;
if (!KEY) {
	console.error('Missing FAL_KEY env var.');
	process.exit(1);
}
fal.config({ credentials: KEY });

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = join(__dirname, '..', 'static', 'bilder');

// Shared visual language so all three read as one set.
const STYLE =
	'premium 3D render, glossy glass-and-clay materials, deep midnight indigo-violet ' +
	'palette with warm amber-gold glowing accents, soft volumetric studio lighting, ' +
	'subtle bloom, floating composition, dark transparent background, ' +
	'sophisticated and modern, jazz-at-night mood, no text, no logo, no watermark';

const ASSETS = [
	{
		// Step 01 — See the chord
		name: 'pluged-in-piano',
		prompt:
			`A cluster of floating glossy 3D piano keys arranged like a chord voicing, ` +
			`a few keys glowing warm amber-gold (the chord tones) while the rest are deep ` +
			`indigo glass, hovering in dark space with soft reflections. ${STYLE}`,
	},
	{
		// Step 02 — Play
		name: 'hands-on-piano',
		prompt:
			`A sleek 3D piano keyboard seen at a dynamic angle, one key pressed and emitting ` +
			`a ripple of warm amber-gold light and a soundwave pulse across the indigo keys, ` +
			`conveying instant feedback and motion. ${STYLE}`,
	},
	{
		// Step 03 — Master
		name: 'lvl-up-piano',
		prompt:
			`Glowing amber-gold and cream 3D musical notes and a treble clef spiraling upward ` +
			`out of a stylized indigo piano keyboard in a celebratory burst, light trails, ` +
			`sense of mastery and flow. ${STYLE}`,
	},
];

for (const a of ASSETS) {
	process.stdout.write(`Generating ${a.name}... `);
	try {
		const out = await fal.subscribe('fal-ai/recraft-v3', {
			input: {
				prompt: a.prompt,
				style: 'digital_illustration',
				image_size: 'square_hd',
			},
			logs: false,
		});
		const url = out?.data?.images?.[0]?.url;
		if (!url) {
			console.error(`FAILED — no image for ${a.name}`);
			continue;
		}
		const res = await fetch(url);
		const buf = Buffer.from(await res.arrayBuffer());
		const dest = join(outDir, `${a.name}.png`);
		await writeFile(dest, buf);
		console.log(`saved ${dest} (${(buf.length / 1024).toFixed(0)} KB)`);
	} catch (e) {
		console.error(`ERROR ${a.name}:`, e?.message ?? e);
	}
}

console.log('Done. Review the PNGs, then convert to .webp.');
