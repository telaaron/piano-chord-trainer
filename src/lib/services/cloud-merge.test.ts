import { describe, it, expect } from 'vitest';
import { mergeSyncData } from './cloud-merge';

const H = 'chord-trainer-history';
const P = 'chord-trainer-habit-profile';
const S = 'chord-trainer-streak';

describe('mergeSyncData', () => {
	it('a fresh device does not wipe the account history', () => {
		const cloud = { [H]: [{ id: 'a', timestamp: 2 }, { id: 'b', timestamp: 1 }] };
		const merged = mergeSyncData({}, cloud);
		expect(merged[H]).toEqual(cloud[H]);
	});

	it('unions history from both sides, newest first, without duplicates', () => {
		const local = { [H]: [{ id: 'c', timestamp: 3 }, { id: 'a', timestamp: 2 }] };
		const cloud = { [H]: [{ id: 'a', timestamp: 2 }, { id: 'b', timestamp: 1 }] };
		const merged = mergeSyncData(local, cloud) as Record<string, { id: string }[]>;
		expect(merged[H].map((s) => s.id)).toEqual(['c', 'a', 'b']);
	});

	it('caps the merged history at 100 sessions', () => {
		const mk = (p: string, n: number) => Array.from({ length: n }, (_, i) => ({ id: `${p}${i}`, timestamp: i }));
		const merged = mergeSyncData({ [H]: mk('l', 80) }, { [H]: mk('c', 80) }) as Record<string, unknown[]>;
		expect(merged[H]).toHaveLength(100);
	});

	it('keeps the more advanced habit profile and never loses "onboarding done"', () => {
		const local = { [P]: { totalXP: 0, onboardingDone: true, dailyGoalMinutes: 5 } };
		const cloud = { [P]: { totalXP: 900, onboardingDone: false, dailyGoalMinutes: 10 } };
		const merged = mergeSyncData(local, cloud) as Record<string, Record<string, unknown>>;
		expect(merged[P].totalXP).toBe(900);
		expect(merged[P].dailyGoalMinutes).toBe(10);
		expect(merged[P].onboardingDone).toBe(true);
	});

	it('keeps the streak with the latest practice day and the best record', () => {
		const local = { [S]: { current: 1, best: 2, lastDate: '2026-10-16' } };
		const cloud = { [S]: { current: 5, best: 9, lastDate: '2026-10-10' } };
		const merged = mergeSyncData(local, cloud) as Record<string, Record<string, unknown>>;
		expect(merged[S]).toEqual({ current: 1, best: 9, lastDate: '2026-10-16' });
	});

	it('lets the account win for plain settings, and keeps local-only keys', () => {
		const merged = mergeSyncData(
			{ 'chord-trainer-theme': 'light', 'chord-trainer-locale': 'de' },
			{ 'chord-trainer-theme': 'dark' },
		);
		expect(merged['chord-trainer-theme']).toBe('dark');
		expect(merged['chord-trainer-locale']).toBe('de');
	});

	it('without keepLocal the account replaces local data', () => {
		const local = { [H]: [{ id: 'x', timestamp: 9 }] };
		const cloud = { [H]: [{ id: 'a', timestamp: 2 }] };
		const merged = mergeSyncData(local, cloud, { keepLocal: false });
		expect(merged[H]).toEqual(cloud[H]);
	});

	it('with preferLocal the device wins plain keys but history is still a union', () => {
		const merged = mergeSyncData(
			{ 'chord-trainer-theme': 'light', [H]: [{ id: 'web', timestamp: 2 }] },
			{ 'chord-trainer-theme': 'dark', [H]: [{ id: 'iphone', timestamp: 1 }] },
			{ preferLocal: true },
		);
		expect(merged['chord-trainer-theme']).toBe('light');
		expect((merged[H] as { id: string }[]).map((s) => s.id)).toEqual(['web', 'iphone']);
	});
});
