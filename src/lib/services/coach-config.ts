// Coach-Lab remote config — cohort assignment + fetching remote-tunable coach parameters
// from `coach_config`. Defaults are always supplied by the caller (see coach-params.ts,
// owned by a parallel task) so this file has no dependency on the coach engine.

import { getSupabase } from './supabase';

const FETCH_TIMEOUT_MS = 3000;
const CONFIG_KEY = 'coach-params';

/**
 * Deterministic cohort assignment from a device ID.
 *
 * NOTE: A/B cohorts are not active yet (per docs/auto-mode-roadmap.md, activated once
 * ~200+ weekly active devices exist). For now this always returns 'default'. The hash
 * function below exists so cohort buckets can be introduced later without changing the
 * call sites — swap the final `return 'default'` for a bucket lookup keyed by `hashDeviceId`.
 */
export function getCohort(deviceId: string): string {
	// Hash is computed even though it is unused today, to keep the structure exercised
	// and ready for future A/B cohort buckets.
	void hashDeviceId(deviceId);
	return 'default';
}

/** Simple deterministic string hash (FNV-1a), stable across sessions for a given device ID. */
function hashDeviceId(deviceId: string): number {
	let hash = 0x811c9dc5;
	for (let i = 0; i < deviceId.length; i++) {
		hash ^= deviceId.charCodeAt(i);
		hash = Math.imul(hash, 0x01000193);
	}
	return hash >>> 0;
}

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
	return new Promise((resolve, reject) => {
		const timer = setTimeout(() => reject(new Error('coach-config fetch timed out')), ms);
		promise.then(
			(value) => {
				clearTimeout(timer);
				resolve(value);
			},
			(err) => {
				clearTimeout(timer);
				reject(err);
			},
		);
	});
}

/**
 * Fetches remote coach parameters for the given cohort (falling back to the 'default'
 * cohort row, then to `defaults`), and merges them flat over `defaults`. Never throws:
 * on any error or timeout (3s) the original `defaults` are returned unchanged.
 */
export async function fetchCoachParams<T extends object>(
	defaults: T,
	cohort: string = 'default',
): Promise<T> {
	if (typeof window === 'undefined') return defaults;

	try {
		const supabase = getSupabase();
		type Row = { cohort: string; value: Record<string, unknown> };
		const { data, error } = await withTimeout<{ data: Row[] | null; error: { message: string } | null }>(
			supabase
				.from('coach_config')
				.select('cohort, value')
				.eq('key', CONFIG_KEY)
				.eq('active', true)
				.in('cohort', cohort === 'default' ? ['default'] : [cohort, 'default']),
			FETCH_TIMEOUT_MS,
		);

		if (error || !data || data.length === 0) return defaults;

		const rows = data;

		const defaultRow = rows.find((r) => r.cohort === 'default');
		const cohortRow = cohort !== 'default' ? rows.find((r) => r.cohort === cohort) : undefined;

		return {
			...defaults,
			...(defaultRow?.value ?? {}),
			...(cohortRow?.value ?? {}),
		};
	} catch {
		return defaults;
	}
}
