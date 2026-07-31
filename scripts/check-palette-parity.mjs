#!/usr/bin/env node
// Palette parity: iOS Theme.swift must agree with the web's src/app.css.
//
// The two platforms hand-maintain the same design tokens, and they drifted once
// already — iOS was still on the old indigo/amber palette long after the web
// moved to the press palette, while the file comment claimed a 1:1 mapping.
// Comments do not catch drift; this does.
//
// Compares only literal hex values present on both sides. Tokens that resolve
// through var() on the web, or that iOS deliberately does not model, are
// skipped rather than guessed at.
//
//   node scripts/check-palette-parity.mjs
//
// Exits non-zero on any mismatch, so it can gate CI.

import { readFileSync } from 'node:fs';

const CSS = 'src/app.css';
const SWIFT = 'ios/JazzChords/JazzChords/Theme/Theme.swift';

/** Swift `Palette` field → CSS custom property. */
const TOKENS = {
	bg: 'bg',
	bgCard: 'bg-card',
	bgCardHover: 'bg-card-hover',
	bgMuted: 'bg-muted',
	border: 'border',
	borderHover: 'border-hover',
	text: 'text',
	textMuted: 'text-muted',
	textDim: 'text-dim',
	primary: 'primary',
	primaryHover: 'primary-hover',
	primaryText: 'primary-text',
	inkBlue: 'ink-blue',
	accentGold: 'accent-gold',
	accentAmber: 'accent-amber',
	accentRed: 'accent-red',
	accentGreen: 'accent-green',
	success: 'success',
	warning: 'warning',
	danger: 'danger',
	xp: 'xp',
	keyWhite: 'key-white',
	keyWhiteBorder: 'key-white-border',
	keyBlack: 'key-black',
};

function cssBlock(css, selector) {
	const re = new RegExp(`${selector} \\{([\\s\\S]*?)\\n\\}`);
	const m = css.match(re);
	const out = {};
	if (!m) return out;
	for (const line of m[1].split('\n')) {
		const t = line.match(/--([a-z0-9-]+):\s*(#[0-9a-fA-F]{6})\b/);
		if (t) out[t[1]] = t[2].slice(1).toLowerCase();
	}
	return out;
}

function swiftPalette(swift, name) {
	const m = swift.match(new RegExp(`static let ${name} = Palette\\(([\\s\\S]*?)\\)\\n`));
	const out = {};
	if (!m) return out;
	for (const p of m[1].matchAll(/(\w+):\s*Color\(hex:\s*"([0-9a-fA-F]{6})"\)/g)) {
		out[p[1]] = p[2].toLowerCase();
	}
	return out;
}

const css = readFileSync(CSS, 'utf8');
const swift = readFileSync(SWIFT, 'utf8');

const schemes = [
	{ name: 'dark', css: cssBlock(css, ':root'), swift: swiftPalette(swift, 'dark') },
	{ name: 'light', css: cssBlock(css, '\\[data-theme="light"\\]'), swift: swiftPalette(swift, 'light') },
];

let mismatches = 0;
let compared = 0;
for (const scheme of schemes) {
	for (const [swiftKey, cssKey] of Object.entries(TOKENS)) {
		const want = scheme.css[cssKey];
		const got = scheme.swift[swiftKey];
		// Absent on either side → not comparable (var()-based, or inherited).
		if (!want || !got) continue;
		compared++;
		if (want !== got) {
			console.error(`MISMATCH ${scheme.name}.${swiftKey}: Theme.swift #${got} vs app.css #${want}`);
			mismatches++;
		}
	}
}

if (mismatches > 0) {
	console.error(`\n${mismatches} palette mismatch(es). Update ${SWIFT} to match ${CSS}.`);
	process.exit(1);
}
console.log(`Palette parity OK — ${compared} tokens match across dark and light.`);
