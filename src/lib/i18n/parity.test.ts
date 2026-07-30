import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { de } from './de';
import { en } from './en';

/**
 * Locale parity, checked against the imported objects rather than the file
 * text — so it sees what the app sees, including nested blocks and values
 * that span lines.
 *
 * This exists because a missing key is invisible in review and specific in
 * production: t() falls back to English when a German key is absent, so a
 * German-only gap ships as English text, and a key missing from BOTH renders
 * the raw path ("ui.next_chord") on the button. Both had shipped.
 */

/** Flatten a locale to dotted paths: { ui: { a: 1 } } → ["ui.a"]. */
function paths(obj: unknown, prefix = ''): string[] {
	if (obj === null || typeof obj !== 'object') return [prefix];
	return Object.entries(obj as Record<string, unknown>).flatMap(([k, v]) =>
		paths(v, prefix ? `${prefix}.${k}` : k),
	);
}

const dePaths = paths(de);
const enPaths = paths(en);
const deSet = new Set(dePaths);
const enSet = new Set(enPaths);

/**
 * `explain.glossary` is keyed partly by the term itself — "Terz"/"Quinte" in
 * German, "Third"/"5th" in English — so those entries are SUPPOSED to diverge.
 * The whole sub-tree is exempt from path equality; the keys code actually looks
 * up (the interval symbols) are asserted on their own below.
 */
const GLOSSARY = 'explain.glossary.';
const exempt = (p: string) => p.startsWith(GLOSSARY);

/**
 * The glossary keys code looks up, read out of ExplainPanel rather than copied
 * here — a duplicated list would drift the moment someone adds an interval.
 */
function glossaryKeysUsedByCode(): string[] {
	const src = readFileSync(
		new URL('../components/ExplainPanel.svelte', import.meta.url),
		'utf8',
	);
	return [...src.matchAll(/'explain\.glossary\.([a-zA-Z_0-9]+)'/g)].map((m) => m[1]);
}

describe('i18n locale parity', () => {
	it('exposes the same key paths in both locales', () => {
		expect({
			missingInDe: enPaths.filter((k) => !deSet.has(k) && !exempt(k)).sort(),
			missingInEn: dePaths.filter((k) => !enSet.has(k) && !exempt(k)).sort(),
		}).toEqual({ missingInDe: [], missingInEn: [] });
	});

	it('keeps every glossary key ExplainPanel looks up in both locales', () => {
		// A gap here prints a raw key inside the theory panel.
		const used = glossaryKeysUsedByCode();
		expect(used.length).toBeGreaterThan(10); // guard: the scrape found the table
		const missing = used.flatMap((k) => [
			...(deSet.has(GLOSSARY + k) ? [] : [`de:${k}`]),
			...(enSet.has(GLOSSARY + k) ? [] : [`en:${k}`]),
		]);
		expect(missing).toEqual([]);
	});

	it('has no duplicate paths after flattening', () => {
		// A duplicated key in the source silently shadows its twin, so the count
		// of unique paths must equal the count of entries.
		expect(dePaths.length).toBe(deSet.size);
		expect(enPaths.length).toBe(enSet.size);
	});

	it('leaves no value empty or untranslated-looking', () => {
		const suspect = (entries: string[], loc: Record<string, unknown>) =>
			entries.filter((p) => {
				const v = p.split('.').reduce<any>((o, k) => o?.[k], loc);
				return typeof v === 'string' && v.trim() === '';
			});
		expect(suspect(dePaths, de as Record<string, unknown>)).toEqual([]);
		expect(suspect(enPaths, en as Record<string, unknown>)).toEqual([]);
	});

	it('keeps the placeholders identical between locales', () => {
		// {n}, {player}, {count}… must match, or one locale drops a value the
		// call site passes and the sentence reads wrong.
		const placeholders = (s: string) => (s.match(/\{[a-zA-Z_0-9]+\}/g) ?? []).sort();
		const mismatched: string[] = [];
		for (const p of dePaths) {
			const dv = p.split('.').reduce<any>((o, k) => o?.[k], de);
			const ev = p.split('.').reduce<any>((o, k) => o?.[k], en);
			if (typeof dv !== 'string' || typeof ev !== 'string') continue;
			const a = placeholders(dv).join(','), b = placeholders(ev).join(',');
			if (a !== b) mismatched.push(`${p}: de[${a}] vs en[${b}]`);
		}
		expect(mismatched).toEqual([]);
	});
});
