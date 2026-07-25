// To-Go theory-card persistence — localStorage, synced via cloud-sync.
// Mirrors coach-state.ts. The blob is a plain map of card id → SM-2 state.

import type { TheoryCardState } from '$lib/engine/togo';
import { debouncedSync } from './cloud-sync';

const STORAGE_KEY = 'chord-trainer-togo-cards';

export type TheoryCardStates = Record<string, TheoryCardState>;

/** Load the persisted card states. An unreadable blob resets to an empty deck. */
export function loadCardStates(): TheoryCardStates {
	if (typeof localStorage === 'undefined') return {};
	try {
		const raw = localStorage.getItem(STORAGE_KEY);
		if (!raw) return {};
		const parsed = JSON.parse(raw);
		if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return {};
		// Drop anything that doesn't look like a card state — a corrupt entry would
		// otherwise poison dueCards() with NaN comparisons.
		const out: TheoryCardStates = {};
		for (const [id, v] of Object.entries(parsed as Record<string, unknown>)) {
			const s = v as Partial<TheoryCardState>;
			if (s && typeof s === 'object' && typeof s.nextReview === 'number') {
				out[id] = {
					cardId: typeof s.cardId === 'string' ? s.cardId : id,
					lastReviewed: typeof s.lastReviewed === 'number' ? s.lastReviewed : 0,
					nextReview: s.nextReview,
					interval: typeof s.interval === 'number' ? s.interval : 0,
					ease: typeof s.ease === 'number' ? s.ease : 2.5,
					repetitions: typeof s.repetitions === 'number' ? s.repetitions : 0,
				};
			}
		}
		return out;
	} catch {
		return {};
	}
}

export function saveCardStates(states: TheoryCardStates): void {
	if (typeof localStorage === 'undefined') return;
	try {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(states));
		debouncedSync();
	} catch {
		// Storage full — silently fail (matches coach-state behaviour).
	}
}

export function clearCardStates(): void {
	if (typeof localStorage === 'undefined') return;
	try {
		localStorage.removeItem(STORAGE_KEY);
		debouncedSync();
	} catch {
		// ignore
	}
}
