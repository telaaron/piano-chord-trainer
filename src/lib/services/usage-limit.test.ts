import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import {
	remainingFreeSessions,
	hasFreeSessionLeft,
	recordCoachSessionStart,
	resetCoachUsage,
	deviceDayIndex,
	effectiveDailyLimit,
} from './usage-limit';
import { FREE_LIMITS } from './subscription';

/**
 * Two regimes to cover: inside the unlimited window (today, and for every user
 * we currently have) and after it, when the daily allowance applies again.
 *
 * The failure modes matter in both directions: letting someone practise
 * forever after the window costs revenue, and locking someone out a day early
 * costs a user. The rollover and calibration cases are the ones most likely to
 * break silently.
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

/** Pin the device's first-seen day so day-index maths is deterministic. */
function seenFirstOn(dateKey: string) {
	localStorage.setItem('chord-trainer-first-seen', dateKey);
}

const DAY_MS = 86_400_000;

describe('unlimited window (a device in its first FREE_LIMITS.unlimitedDays)', () => {
	beforeEach(() => {
		installStorage();
		resetCoachUsage();
	});
	afterEach(() => vi.unstubAllGlobals());

	it('imposes no limit at all on a brand-new device', () => {
		expect(effectiveDailyLimit()).toBe(Infinity);
		expect(remainingFreeSessions()).toBe(Infinity);
		expect(hasFreeSessionLeft()).toBe(true);
	});

	it('still lets you practise after many sessions in one day', () => {
		for (let i = 0; i < 25; i++) recordCoachSessionStart();
		expect(hasFreeSessionLeft()).toBe(true);
	});

	it('stamps day 0 on first contact and counts forward', () => {
		const t0 = new Date('2026-08-01T10:00:00').getTime();
		expect(deviceDayIndex(t0)).toBe(0);
		expect(deviceDayIndex(t0 + 3 * DAY_MS)).toBe(3);
	});

	it('holds the window open on its last day and closes it the next', () => {
		const start = new Date('2026-08-01T10:00:00');
		seenFirstOn('2026-08-01');
		const lastFreeDay = start.getTime() + (FREE_LIMITS.unlimitedDays - 1) * DAY_MS;
		const firstLimitedDay = start.getTime() + FREE_LIMITS.unlimitedDays * DAY_MS;
		expect(effectiveDailyLimit(lastFreeDay)).toBe(Infinity);
		expect(effectiveDailyLimit(firstLimitedDay)).toBe(FREE_LIMITS.coachSessionsPerDay);
	});
});

describe('calibration is never billed as practice', () => {
	beforeEach(() => {
		installStorage();
		resetCoachUsage();
	});
	afterEach(() => vi.unstubAllGlobals());

	it('does not spend the allowance', () => {
		// Put the device past the window so a limit is actually in force.
		seenFirstOn('2026-01-01');
		const now = new Date('2026-08-01T20:00:00').getTime();
		const before = remainingFreeSessions(now);

		recordCoachSessionStart({ kind: 'calibrate', now });

		expect(remainingFreeSessions(now)).toBe(before);
		expect(hasFreeSessionLeft(now)).toBe(true);
	});

	it('leaves the day intact for the real session that follows it', () => {
		// The reported bug: placement test → "that was today's session".
		seenFirstOn('2026-01-01');
		const now = new Date('2026-08-01T20:00:00').getTime();
		recordCoachSessionStart({ kind: 'calibrate', now });
		expect(hasFreeSessionLeft(now)).toBe(true);

		// The first real block does spend it.
		recordCoachSessionStart({ kind: 'warmup', now });
		expect(remainingFreeSessions(now)).toBe(FREE_LIMITS.coachSessionsPerDay - 1);
	});
});

describe('daily allowance after the unlimited window', () => {
	const now = new Date('2026-08-01T20:00:00').getTime();

	beforeEach(() => {
		installStorage();
		resetCoachUsage();
		seenFirstOn('2026-01-01'); // long past the window
	});
	afterEach(() => vi.unstubAllGlobals());

	it('starts the day with the full allowance', () => {
		expect(remainingFreeSessions(now)).toBe(FREE_LIMITS.coachSessionsPerDay);
		expect(hasFreeSessionLeft(now)).toBe(true);
	});

	it('closes the door once the allowance is used up', () => {
		for (let i = 0; i < FREE_LIMITS.coachSessionsPerDay; i++) {
			recordCoachSessionStart({ kind: 'focus', now });
		}
		expect(hasFreeSessionLeft(now)).toBe(false);
		expect(remainingFreeSessions(now)).toBe(0);
	});

	it('never reports a negative remainder when over-recorded', () => {
		for (let i = 0; i < FREE_LIMITS.coachSessionsPerDay + 5; i++) {
			recordCoachSessionStart({ kind: 'focus', now });
		}
		expect(remainingFreeSessions(now)).toBe(0);
	});

	it('resets on the next calendar day', () => {
		const day1 = new Date('2026-08-01T21:00:00').getTime();
		for (let i = 0; i < FREE_LIMITS.coachSessionsPerDay; i++) {
			recordCoachSessionStart({ kind: 'focus', now: day1 });
		}
		expect(hasFreeSessionLeft(day1)).toBe(false);

		// Four hours later it is tomorrow locally — the allowance is back.
		const day2 = new Date('2026-08-02T01:00:00').getTime();
		expect(hasFreeSessionLeft(day2)).toBe(true);
		expect(remainingFreeSessions(day2)).toBe(FREE_LIMITS.coachSessionsPerDay);
	});

	it('uses the local calendar day, not UTC', () => {
		// Late evening in a positive-offset zone is already "tomorrow" in UTC.
		// The counter must follow the player's clock, not the server's.
		const lateEvening = new Date('2026-08-01T23:30:00').getTime();
		recordCoachSessionStart({ kind: 'focus', now: lateEvening });
		const sameEveningLater = new Date('2026-08-01T23:59:00').getTime();
		expect(remainingFreeSessions(sameEveningLater)).toBe(
			FREE_LIMITS.coachSessionsPerDay - 1,
		);
	});

	it('treats unreadable storage as a fresh day rather than a lockout', () => {
		localStorage.setItem('chord-trainer-coach-usage', '{ not json');
		expect(hasFreeSessionLeft(now)).toBe(true);
	});
});
