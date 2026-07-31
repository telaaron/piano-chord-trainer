import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { resetEverything } from './reset';

/**
 * The reset button is only trustworthy if it really leaves nothing behind — a
 * half-cleared app is worse than no button, because the player believes they
 * are starting fresh while old state still steers the coach.
 */

/** Minimal Storage stub — vitest runs in node, which has no DOM. */
function makeStorage(seed: Record<string, string> = {}): Storage {
	const map = new Map(Object.entries(seed));
	return {
		get length() {
			return map.size;
		},
		key: (i: number) => [...map.keys()][i] ?? null,
		getItem: (k: string) => map.get(k) ?? null,
		setItem: (k: string, v: string) => void map.set(k, v),
		removeItem: (k: string) => void map.delete(k),
		clear: () => map.clear(),
	} as Storage;
}

const g = globalThis as Record<string, unknown>;

describe('resetEverything', () => {
	afterEach(() => {
		delete g.localStorage;
		delete g.sessionStorage;
		delete g.caches;
	});

	beforeEach(() => {
		delete g.caches;
	});

	it('removes every chord-trainer key', async () => {
		g.localStorage = makeStorage({
			'chord-trainer-history': '[]',
			'chord-trainer-settings': '{}',
			'chord-trainer-streak': '{}',
			'chord-trainer-habit-profile': '{}',
		});

		const report = await resetEverything();

		expect(report.removed).toHaveLength(4);
		expect((g.localStorage as Storage).length).toBe(0);
	});

	it('removes runtime-built keys a fixed list could never name', async () => {
		// teaser.ts builds `chord-trainer-teaser:<feature>` at runtime, so the
		// exact key is unknowable up front. This is the reason for prefix sweeping.
		g.localStorage = makeStorage({
			'chord-trainer-teaser:advanced-stats': '1',
			'chord-trainer-teaser:some-future-feature': '1',
		});

		await resetEverything();

		expect((g.localStorage as Storage).length).toBe(0);
	});

	it('leaves other apps on the same origin alone', async () => {
		g.localStorage = makeStorage({
			'chord-trainer-history': '[]',
			'sb-auth-token': 'keep-me',
			'unrelated': 'keep-me',
		});

		const report = await resetEverything();

		expect(report.removed).toEqual(['chord-trainer-history']);
		expect((g.localStorage as Storage).getItem('sb-auth-token')).toBe('keep-me');
		expect((g.localStorage as Storage).getItem('unrelated')).toBe('keep-me');
	});

	it('clears every key when they are all ours', async () => {
		// Guards the index-shift bug: removing while iterating by index skips
		// entries, so a naive loop leaves roughly half the keys behind.
		const seed: Record<string, string> = {};
		for (let i = 0; i < 10; i++) seed[`chord-trainer-k${i}`] = String(i);
		g.localStorage = makeStorage(seed);

		const report = await resetEverything();

		expect(report.removed).toHaveLength(10);
		expect((g.localStorage as Storage).length).toBe(0);
	});

	it('sweeps sessionStorage as well', async () => {
		g.localStorage = makeStorage({});
		g.sessionStorage = makeStorage({ 'chord-trainer-temp': 'x', keep: 'y' });

		await resetEverything();

		expect((g.sessionStorage as Storage).getItem('chord-trainer-temp')).toBeNull();
		expect((g.sessionStorage as Storage).getItem('keep')).toBe('y');
	});

	it('still clears storage when the cache API throws', async () => {
		// A blocked Cache API must not abort the reset — the history matters more
		// than the caches, and a partial reset is the failure mode to avoid.
		g.localStorage = makeStorage({ 'chord-trainer-history': '[]' });
		g.caches = {
			keys: () => Promise.reject(new Error('blocked')),
			delete: () => Promise.resolve(false),
		};

		const report = await resetEverything();

		expect(report.removed).toEqual(['chord-trainer-history']);
		expect(report.caches).toEqual([]);
	});

	it('reports the caches it deleted', async () => {
		g.localStorage = makeStorage({});
		g.caches = {
			keys: () => Promise.resolve(['build-1', 'build-2']),
			delete: (n: string) => Promise.resolve(n === 'build-1'),
		};

		const report = await resetEverything();

		// Only the bucket that actually went away is reported.
		expect(report.caches).toEqual(['build-1']);
	});

	it('does not throw when storage is unavailable', async () => {
		// Private mode / SSR: nothing to clear, but the caller must not crash.
		const report = await resetEverything();
		expect(report.removed).toEqual([]);
	});
});
