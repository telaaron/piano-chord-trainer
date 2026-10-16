// Cloud Sync Service — syncs localStorage data to Supabase for logged-in users
// Implements merge-on-login: local data is merged into cloud on first sign-in.
import { getSupabase } from './supabase';
import { getAuthState } from './auth';
import { mergeSyncData } from './cloud-merge';

// All localStorage keys that should be synced
const SYNC_KEYS = [
	'chord-trainer-history',
	'chord-trainer-settings',
	'chord-trainer-streak',
	'chord-trainer-habit-profile',
	'chord-trainer-celebrations',
	'chord-trainer-course-progress',
	'chord-trainer-coach-state',
	'chord-trainer-togo-cards',
	'chord-trainer-theme',
	'chord-trainer-locale',
] as const;

export type SyncKey = typeof SYNC_KEYS[number];

function readLocal(): Record<string, unknown> {
	const out: Record<string, unknown> = {};
	for (const key of SYNC_KEYS) {
		const raw = localStorage.getItem(key);
		if (raw) {
			try {
				out[key] = JSON.parse(raw);
			} catch {
				out[key] = raw;
			}
		}
	}
	return out;
}

function writeLocal(data: Record<string, unknown>): void {
	for (const key of SYNC_KEYS) {
		const v = data[key];
		if (v === undefined) continue;
		localStorage.setItem(key, typeof v === 'string' ? v : JSON.stringify(v));
	}
}

// ─── Hydration ──────────────────────────────────────────────
//
// Uploads replace the account's whole row. Before this existed, a browser that
// had never pulled the account's data (new device, cleared storage, Safari's
// 7-day storage purge) uploaded its empty defaults on the first save and wiped
// the account's history — and, because the habit profile was fresh too, asked
// for the onboarding again on every such login. So: pull and merge once per
// user per tab, and refuse to upload until that has happened.

let hydratedFor: string | null = null;
let hydrating: { userId: string; promise: Promise<boolean> } | null = null;

/**
 * Pull the account's data and merge it into this device. Idempotent per user
 * within a tab; concurrent callers share one request. Resolves `true` once the
 * device holds the merged state (and uploads are allowed), `false` on error.
 */
export function ensureHydrated(userId: string, opts: { keepLocal?: boolean } = {}): Promise<boolean> {
	if (hydratedFor === userId) return Promise.resolve(true);
	if (hydrating?.userId === userId) return hydrating.promise;

	const promise = (async () => {
		const { data, error } = await getSupabase()
			.from('user_data')
			.select('data')
			.eq('user_id', userId)
			.maybeSingle();
		if (error) return false;
		// Signed out or switched account while the request was in flight.
		if (getAuthState().user?.id !== userId) return false;

		const merged = mergeSyncData(readLocal(), (data?.data ?? {}) as Record<string, unknown>, opts);
		writeLocal(merged);
		hydratedFor = userId;
		// Push the union back so the account also holds what only this device had.
		await syncToCloud();
		return true;
	})()
		.catch(() => false)
		.finally(() => {
			if (hydrating?.promise === promise) hydrating = null;
		});

	hydrating = { userId, promise };
	return promise;
}

/**
 * Upload all current localStorage data to Supabase for the logged-in user.
 * Called once after login/signup when user opts in to data migration.
 */
export async function uploadLocalDataToCloud(): Promise<{ error: Error | null }> {
	const { user } = getAuthState();
	if (!user) return { error: new Error('Not authenticated') };

	const supabase = getSupabase();
	const dataPayload: Record<string, unknown> = {};

	for (const key of SYNC_KEYS) {
		const raw = localStorage.getItem(key);
		if (raw) {
			try {
				dataPayload[key] = JSON.parse(raw);
			} catch {
				dataPayload[key] = raw;
			}
		}
	}

	const { error } = await supabase.from('user_data').upsert(
		{
			user_id: user.id,
			data: dataPayload,
			updated_at: new Date().toISOString(),
		},
		{ onConflict: 'user_id' },
	);

	if (error) return { error: new Error(error.message) };
	return { error: null };
}

/**
 * Download cloud data and merge into localStorage.
 * Cloud data takes priority for newer timestamps; local data fills gaps.
 */
export async function downloadCloudData(): Promise<{ merged: boolean; error: Error | null }> {
	const { user } = getAuthState();
	if (!user) return { merged: false, error: new Error('Not authenticated') };

	const supabase = getSupabase();
	const { data, error } = await supabase
		.from('user_data')
		.select('data, updated_at')
		.eq('user_id', user.id)
		.single();

	if (error && error.code !== 'PGRST116') {
		return { merged: false, error: new Error(error.message) };
	}

	if (!data?.data) {
		return { merged: false, error: null };
	}

	const cloudData = data.data as Record<string, unknown>;

	for (const key of SYNC_KEYS) {
		if (cloudData[key] !== undefined) {
			const value = typeof cloudData[key] === 'string'
				? cloudData[key] as string
				: JSON.stringify(cloudData[key]);
			localStorage.setItem(key, value);
		}
	}

	return { merged: true, error: null };
}

/**
 * Sync current localStorage state to cloud (for ongoing saves).
 * Called after significant state changes (session complete, settings change, etc.).
 * Debounced in practice — callers should debounce.
 */
export async function syncToCloud(): Promise<void> {
	const { user } = getAuthState();
	if (!user) return;
	// Never upload a device's state over the account before merging with it.
	if (hydratedFor !== user.id) return;

	const supabase = getSupabase();
	const dataPayload: Record<string, unknown> = {};

	for (const key of SYNC_KEYS) {
		const raw = localStorage.getItem(key);
		if (raw) {
			try {
				dataPayload[key] = JSON.parse(raw);
			} catch {
				dataPayload[key] = raw;
			}
		}
	}

	await supabase.from('user_data').upsert(
		{
			user_id: user.id,
			data: dataPayload,
			updated_at: new Date().toISOString(),
		},
		{ onConflict: 'user_id' },
	);
}

let syncTimer: ReturnType<typeof setTimeout> | null = null;

/**
 * Debounced sync — waits 3 seconds of inactivity before syncing.
 */
export function debouncedSync(): void {
	if (syncTimer) clearTimeout(syncTimer);
	syncTimer = setTimeout(() => {
		syncToCloud();
	}, 3000);
}
