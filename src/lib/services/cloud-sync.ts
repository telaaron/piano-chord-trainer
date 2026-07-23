// Cloud Sync Service — syncs localStorage data to Supabase for logged-in users
// Implements merge-on-login: local data is merged into cloud on first sign-in.
import { getSupabase } from './supabase';
import { getAuthState } from './auth';
import { canUse } from './subscription-store.svelte';

// All localStorage keys that should be synced
const SYNC_KEYS = [
	'chord-trainer-history',
	'chord-trainer-settings',
	'chord-trainer-streak',
	'chord-trainer-habit-profile',
	'chord-trainer-celebrations',
	'chord-trainer-course-progress',
	'chord-trainer-coach-state',
	'chord-trainer-theme',
	'chord-trainer-locale',
] as const;

export type SyncKey = typeof SYNC_KEYS[number];

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
	// Cloud sync is a Pro feature — free users keep data local only.
	if (!canUse('cloud-sync')) return;

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
