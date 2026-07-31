import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import {
	remainingFreeSessions,
	hasFreeSessionLeft,
	recordCoachSessionStart,
	resetCoachUsage,
} from './usage-limit';
import { FREE_LIMITS } from './subscription';

/**
 * The daily allowance is the free tier's only limit and the main upgrade
 * trigger, so the failure modes matter in both directions: letting someone
 * practise forever costs revenue, and locking someone out a day early costs
 * a user. The date-rollover case is the one most likely to break silently.
 */

// Minimal localStorage stand-in — the service is storage-only by design.
function installStorage() {
	const store = new Map<string, string>();
	vi.stubGlobal('localStorage', {
		getItem: (k: string) => store.get(k) ?? null,
		setItem: (k: string, v: string) => void store.set(k, v),
		removeItem: (k: string) => void store.delete(k),
		clear: () => store.clear(),
	});
	return store;
}

describe('free-tier daily coach allowance', () => {
	beforeEach(() => {
		installStorage();
		resetCoachUsage();
	});
	afterEach(() => vi.unstubAllGlobals());

	it('starts the day with the full allowance', () => {
		expect(remainingFreeSessions()).toBe(FREE_LIMITS.coachSessionsPerDay);
		expect(hasFreeSessionLeft()).toBe(true);
	});

	it('spends the allowance when a session actually starts', () => {
		recordCoachSessionStart();
		expect(remainingFreeSessions()).toBe(FREE_LIMITS.coachSessionsPerDay - 1);
	});

	it('closes the door once the allowance is used up', () => {
		for (let i = 0; i < FREE_LIMITS.coachSessionsPerDay; i++) recordCoachSessionStart();
		expect(hasFreeSessionLeft()).toBe(false);
		expect(remainingFreeSessions()).toBe(0);
	});

	it('never reports a negative remainder when over-recorded', () => {
		for (let i = 0; i < FREE_LIMITS.coachSessionsPerDay + 5; i++) recordCoachSessionStart();
		expect(remainingFreeSessions()).toBe(0);
	});

	it('resets on the next calendar day', () => {
		const day1 = new Date('2026-07-30T21:00:00').getTime();
		for (let i = 0; i < FREE_LIMITS.coachSessionsPerDay; i++) recordCoachSessionStart(day1);
		expect(hasFreeSessionLeft(day1)).toBe(false);

		// Two hours later it is tomorrow locally — the allowance is back.
		const day2 = new Date('2026-07-31T01:00:00').getTime();
		expect(hasFreeSessionLeft(day2)).toBe(true);
		expect(remainingFreeSessions(day2)).toBe(FREE_LIMITS.coachSessionsPerDay);
	});

	it('uses the local calendar day, not UTC', () => {
		// Late evening in a positive-offset zone is already "tomorrow" in UTC.
		// The counter must follow the player's clock, not the server's.
		const lateEvening = new Date('2026-07-30T23:30:00').getTime();
		recordCoachSessionStart(lateEvening);
		const sameEveningLater = new Date('2026-07-30T23:59:00').getTime();
		expect(remainingFreeSessions(sameEveningLater)).toBe(FREE_LIMITS.coachSessionsPerDay - 1);
	});

	it('treats unreadable storage as a fresh day rather than a lockout', () => {
		localStorage.setItem('chord-trainer-coach-usage', '{ not json');
		expect(hasFreeSessionLeft()).toBe(true);
	});
});
