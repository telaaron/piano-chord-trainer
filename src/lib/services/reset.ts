/**
 * Factory reset — put the app back to how a first-time visitor finds it.
 *
 * Everything this app stores on the device is namespaced `chord-trainer-*`, so
 * the reset sweeps by PREFIX rather than by a hand-kept list of keys. A list
 * would rot: `chord-trainer-teaser:<feature>` is built at runtime and can never
 * appear in one, and every key added later would silently survive the reset —
 * leaving a half-cleared app, which is worse than not offering the button.
 *
 * Caches are cleared too, so a reload really re-fetches instead of replaying a
 * service worker's copy of the old build.
 *
 * Deliberately NOT touched: anything server-side. A signed-in player's account,
 * subscription and synced history live in Supabase; wiping the device must not
 * quietly destroy those. Deleting the account is a separate, explicit action
 * that already exists in the danger zone.
 */

const PREFIX = 'chord-trainer-';

export interface ResetReport {
	/** Keys removed from localStorage, in the order they were found. */
	removed: string[];
	/** Cache Storage buckets deleted (empty when the API is unavailable). */
	caches: string[];
	/** Service workers unregistered. */
	serviceWorkers: number;
}

/** Every `chord-trainer-*` key currently on the device. */
function ownedKeys(store: Storage): string[] {
	const keys: string[] = [];
	for (let i = 0; i < store.length; i++) {
		const k = store.key(i);
		if (k && k.startsWith(PREFIX)) keys.push(k);
	}
	return keys;
}

/**
 * Wipe all local app state. Returns what was actually removed so the caller can
 * report it honestly rather than claiming a clean slate it never verified.
 *
 * Safe to call when storage is unavailable (private mode, SSR): each step is
 * guarded and failures are skipped rather than aborting the whole reset — a
 * blocked cache API must not stop the history from being cleared.
 */
export async function resetEverything(): Promise<ResetReport> {
	const report: ResetReport = { removed: [], caches: [], serviceWorkers: 0 };

	if (typeof localStorage !== 'undefined') {
		// Collect first, then delete: removing while iterating by index skips
		// entries, because every removal shifts the ones after it down.
		for (const key of ownedKeys(localStorage)) {
			try {
				localStorage.removeItem(key);
				report.removed.push(key);
			} catch {
				/* quota/permission errors: skip this key, keep going */
			}
		}
	}

	if (typeof sessionStorage !== 'undefined') {
		for (const key of ownedKeys(sessionStorage)) {
			try {
				sessionStorage.removeItem(key);
				report.removed.push(key);
			} catch {
				/* same */
			}
		}
	}

	// A stale service worker would serve the previous build after the reload,
	// which looks exactly like "the reset did nothing".
	if (typeof caches !== 'undefined') {
		try {
			for (const name of await caches.keys()) {
				if (await caches.delete(name)) report.caches.push(name);
			}
		} catch {
			/* Cache API blocked — localStorage is already cleared, so continue */
		}
	}

	if (typeof navigator !== 'undefined' && navigator.serviceWorker) {
		try {
			const regs = await navigator.serviceWorker.getRegistrations();
			for (const reg of regs) {
				if (await reg.unregister()) report.serviceWorkers++;
			}
		} catch {
			/* not fatal */
		}
	}

	return report;
}
