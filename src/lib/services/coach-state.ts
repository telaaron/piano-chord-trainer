// Coach state persistence — localStorage, synced via cloud-sync.
// Mirrors the pattern of course-progress.ts. The blob is a single CoachState.

import { type CoachState, createInitialCoachState } from '$lib/engine/coach';
import { debouncedSync } from './cloud-sync';

const STORAGE_KEY = 'chord-trainer-coach-state';

/** Bump when the CoachState shape changes incompatibly. */
const CURRENT_VERSION = 1;

/**
 * Load the persisted Coach state.
 * Returns a fresh initial state if nothing is stored, the blob is unreadable,
 * or its version predates the current schema (forward-only migration guard).
 */
export function loadCoachState(): CoachState {
	if (typeof localStorage === 'undefined') return createInitialCoachState();
	try {
		const raw = localStorage.getItem(STORAGE_KEY);
		if (!raw) return createInitialCoachState();
		const parsed = JSON.parse(raw) as Partial<CoachState>;
		return migrate(parsed);
	} catch {
		return createInitialCoachState();
	}
}

export function saveCoachState(state: CoachState): void {
	if (typeof localStorage === 'undefined') return;
	try {
		const toStore: CoachState = { ...state, version: CURRENT_VERSION };
		localStorage.setItem(STORAGE_KEY, JSON.stringify(toStore));
		debouncedSync();
	} catch {
		// Storage full — silently fail (matches course-progress behaviour).
	}
}

export function clearCoachState(): void {
	if (typeof localStorage === 'undefined') return;
	try {
		localStorage.removeItem(STORAGE_KEY);
		debouncedSync();
	} catch {
		// ignore
	}
}

/**
 * Bring a stored blob up to the current schema.
 * Unknown / older versions are reset to a clean initial state rather than
 * risking a corrupt controller — the Coach re-calibrates cheaply.
 */
function migrate(parsed: Partial<CoachState>): CoachState {
	if (!parsed || typeof parsed !== 'object') return createInitialCoachState();
	if (parsed.version !== CURRENT_VERSION) {
		// No historical versions yet — any mismatch means reset.
		return createInitialCoachState();
	}
	const base = createInitialCoachState();
	return {
		...base,
		...parsed,
		version: CURRENT_VERSION,
		unitStates: parsed.unitStates ?? base.unitStates,
	};
}
