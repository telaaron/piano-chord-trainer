import { describe, it, expect } from 'vitest';
import { migrateToHabitProfile, needsOnboarding, countPracticeSessions } from './habits';
import type { SessionResult } from '../services/progress';

const session = (id: string, timestamp: number): SessionResult =>
	({
		id, timestamp, elapsedMs: 60000, totalChords: 10, avgMs: 6000,
		settings: { difficulty: 'beginner', notation: 'standard', voicing: 'shell', displayMode: 'always', accidentals: 'sharps', progressionMode: 'random' },
		midi: { enabled: false, accuracy: 0 },
	}) as unknown as SessionResult;

describe('migrateToHabitProfile: onboarding', () => {
	it('a player with practice history has already been onboarded', () => {
		const p = migrateToHabitProfile([session('s1', Date.now())], { current: 1, best: 1, lastDate: '' });
		expect(p.onboardingDone).toBe(true);
	});

	it('a brand-new player still gets the onboarding', () => {
		const p = migrateToHabitProfile([], { current: 0, best: 0, lastDate: '' });
		expect(p.onboardingDone).toBe(false);
	});
});

describe('needsOnboarding', () => {
	const ready = { profileDone: false, sessionCount: 3, accountDone: false };

	it('does not ask before the first session', () => {
		expect(needsOnboarding({ ...ready, sessionCount: 0 })).toBe(false);
	});
	it('does not ask after one or two sessions', () => {
		expect(needsOnboarding({ ...ready, sessionCount: 2 })).toBe(false);
	});
	it('asks once the third session is done', () => {
		expect(needsOnboarding(ready)).toBe(true);
		expect(needsOnboarding({ ...ready, sessionCount: 7 })).toBe(true);
	});
	it('never again once this device recorded it (answered or skipped)', () => {
		expect(needsOnboarding({ ...ready, profileDone: true })).toBe(false);
	});
	it('never when the account did it on another device', () => {
		expect(needsOnboarding({ ...ready, accountDone: true })).toBe(false);
	});
});

describe('countPracticeSessions', () => {
	const min = 60_000;
	it('counts the blocks of one sitting as one session', () => {
		expect(countPracticeSessions([0, 3 * min, 6 * min, 9 * min])).toBe(1);
	});
	it('counts sittings at least 30 minutes apart separately, in any order', () => {
		expect(countPracticeSessions([120 * min, 0, 2 * min, 60 * min])).toBe(3);
	});
	it('is zero for no history', () => {
		expect(countPracticeSessions([])).toBe(0);
	});
});
