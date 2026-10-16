import { describe, it, expect } from 'vitest';
import { migrateToHabitProfile, needsOnboarding } from './habits';
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
	const fresh = { profileDone: false, sessionCount: 0, accountDone: false };

	it('shows it to a first-time player', () => {
		expect(needsOnboarding(fresh)).toBe(true);
	});
	it('never again once this device recorded it', () => {
		expect(needsOnboarding({ ...fresh, profileDone: true })).toBe(false);
	});
	it('never to someone who has already practised', () => {
		expect(needsOnboarding({ ...fresh, sessionCount: 3 })).toBe(false);
	});
	it('never when the account did it on another device', () => {
		expect(needsOnboarding({ ...fresh, accountDone: true })).toBe(false);
	});
});
