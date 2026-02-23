import { describe, it, expect, vi } from 'vitest';
import {
	calculateLevel,
	xpForLevel,
	getLevelInfo,
	getStreakMultiplier,
	calculateSessionXP,
	sumXP,
	updateChordSchedule,
	timingToQuality,
	processSessionForSchedule,
	createDefaultProfile,
	migrateToHabitProfile,
	XP_SESSION_COMPLETE,
	XP_PERSONAL_BEST,
	XP_STREAK_DAY,
	XP_STREAK_7_BONUS,
	XP_LONG_SESSION,
	XP_DEDICATED,
	XP_FULL_CIRCLE,
	type HabitProfile,
	type SmartGoal,
	type ChordReview,
} from './habits';

// ─── Level System ───────────────────────────────────────────

describe('calculateLevel', () => {
	it('returns 1 for 0 XP', () => {
		expect(calculateLevel(0)).toBe(1);
	});

	it('returns 1 for 49 XP (just under level 2)', () => {
		expect(calculateLevel(49)).toBe(1);
	});

	it('returns 1 for 50 XP (edge of level 1)', () => {
		// sqrt(50/50) = 1 → floor = 1
		expect(calculateLevel(50)).toBe(1);
	});

	it('returns 2 for 200 XP', () => {
		// sqrt(200/50) = sqrt(4) = 2
		expect(calculateLevel(200)).toBe(2);
	});

	it('returns 5 for 1250 XP', () => {
		// sqrt(1250/50) = sqrt(25) = 5
		expect(calculateLevel(1250)).toBe(5);
	});

	it('returns 10 for 5000 XP', () => {
		// sqrt(5000/50) = sqrt(100) = 10
		expect(calculateLevel(5000)).toBe(10);
	});

	it('returns 50 for 125000 XP', () => {
		// sqrt(125000/50) = sqrt(2500) = 50
		expect(calculateLevel(125000)).toBe(50);
	});
});

describe('xpForLevel', () => {
	it('level 1 = 50 XP', () => {
		expect(xpForLevel(1)).toBe(50);
	});

	it('level 5 = 1250 XP', () => {
		expect(xpForLevel(5)).toBe(1250);
	});

	it('level 10 = 5000 XP', () => {
		expect(xpForLevel(10)).toBe(5000);
	});
});

describe('getLevelInfo', () => {
	it('returns correct title key for level 1', () => {
		const info = getLevelInfo(0);
		expect(info.level).toBe(1);
		expect(info.titleKey).toBe('habit.level_listener');
	});

	it('returns correct title key for level 10', () => {
		const info = getLevelInfo(5000);
		expect(info.level).toBe(10);
		expect(info.titleKey).toBe('habit.level_student');
	});

	it('returns progress percent between levels', () => {
		const info = getLevelInfo(100);
		expect(info.progressPercent).toBeGreaterThan(0);
		expect(info.progressPercent).toBeLessThan(100);
	});

	it('clamps progress at 100', () => {
		const info = getLevelInfo(199);
		expect(info.progressPercent).toBeLessThanOrEqual(100);
	});
});

// ─── Streak Multiplier ──────────────────────────────────────

describe('getStreakMultiplier', () => {
	it('returns 1.0× for days 1-7', () => {
		expect(getStreakMultiplier(1)).toBe(1.0);
		expect(getStreakMultiplier(7)).toBe(1.0);
	});

	it('returns 1.25× for days 8-14', () => {
		expect(getStreakMultiplier(8)).toBe(1.25);
		expect(getStreakMultiplier(14)).toBe(1.25);
	});

	it('returns 1.5× for days 15-30', () => {
		expect(getStreakMultiplier(15)).toBe(1.5);
		expect(getStreakMultiplier(30)).toBe(1.5);
	});

	it('returns 2.0× for days 31+', () => {
		expect(getStreakMultiplier(31)).toBe(2.0);
		expect(getStreakMultiplier(100)).toBe(2.0);
	});
});

// ─── XP Calculation ─────────────────────────────────────────

describe('calculateSessionXP', () => {
	const baseSession = {
		id: 'test-1',
		timestamp: Date.now(),
		elapsedMs: 60000, // 1 min
		totalChords: 10,
		avgMs: 6000,
		settings: {
			difficulty: 'beginner' as const,
			notation: 'standard' as const,
			voicing: 'shell' as const,
			displayMode: 'always' as const,
			accidentals: 'sharps' as const,
			progressionMode: 'random' as const,
		},
		midi: { enabled: false, accuracy: 0 },
	};

	const baseStreak = { current: 1, best: 1, lastDate: '' };
	const baseProfile = createDefaultProfile();

	it('always awards SESSION_COMPLETE XP', () => {
		const events = calculateSessionXP(baseSession, baseStreak, baseProfile);
		const sessionEvent = events.find((e) => e.reasonKey === 'habit.xp_session_complete');
		expect(sessionEvent).toBeDefined();
		expect(sessionEvent?.amount).toBe(XP_SESSION_COMPLETE);
	});

	it('awards PERSONAL_BEST when faster than previous', () => {
		const events = calculateSessionXP(baseSession, baseStreak, baseProfile, 7000);
		const pbEvent = events.find((e) => e.reasonKey === 'habit.xp_personal_best');
		expect(pbEvent).toBeDefined();
		expect(pbEvent?.amount).toBe(XP_PERSONAL_BEST);
	});

	it('does NOT award PERSONAL_BEST when slower', () => {
		const events = calculateSessionXP(baseSession, baseStreak, baseProfile, 5000);
		const pbEvent = events.find((e) => e.reasonKey === 'habit.xp_personal_best');
		expect(pbEvent).toBeUndefined();
	});

	it('awards streak XP with multiplier', () => {
		const streak = { current: 10, best: 10, lastDate: '' };
		const events = calculateSessionXP(baseSession, streak, baseProfile);
		const streakEvent = events.find((e) => e.reasonKey === 'habit.xp_streak_day');
		expect(streakEvent).toBeDefined();
		// Day 10 = 1.25× multiplier → 5 * 1.25 = 6.25 → round = 6
		expect(streakEvent?.amount).toBe(Math.round(XP_STREAK_DAY * 1.25));
	});

	it('awards 7-day streak bonus', () => {
		const streak = { current: 7, best: 7, lastDate: '' };
		const events = calculateSessionXP(baseSession, streak, baseProfile);
		const bonusEvent = events.find((e) => e.reasonKey === 'habit.xp_streak_7');
		expect(bonusEvent).toBeDefined();
		expect(bonusEvent?.amount).toBe(XP_STREAK_7_BONUS);
	});

	it('awards long session bonus for >5 min', () => {
		const longSession = { ...baseSession, elapsedMs: 400000 };
		const events = calculateSessionXP(longSession, baseStreak, baseProfile);
		const longEvent = events.find((e) => e.reasonKey === 'habit.xp_long_session');
		expect(longEvent).toBeDefined();
		expect(longEvent?.amount).toBe(XP_LONG_SESSION);
	});

	it('does NOT award long session bonus for <5 min', () => {
		const events = calculateSessionXP(baseSession, baseStreak, baseProfile);
		const longEvent = events.find((e) => e.reasonKey === 'habit.xp_long_session');
		expect(longEvent).toBeUndefined();
	});

	it('awards FULL_CIRCLE for 12 unique roots', () => {
		const session = {
			...baseSession,
			chordTimings: ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'].map(
				(root) => ({ chord: root + 'Maj7', root, durationMs: 3000 }),
			),
		};
		const events = calculateSessionXP(session, baseStreak, baseProfile);
		const fcEvent = events.find((e) => e.reasonKey === 'habit.xp_full_circle');
		expect(fcEvent).toBeDefined();
		expect(fcEvent?.amount).toBe(XP_FULL_CIRCLE);
	});
});

describe('sumXP', () => {
	it('sums event amounts', () => {
		const events = [
			{ amount: 10, reason: 'a', reasonKey: 'a' },
			{ amount: 5, reason: 'b', reasonKey: 'b' },
			{ amount: 25, reason: 'c', reasonKey: 'c' },
		];
		expect(sumXP(events)).toBe(40);
	});

	it('returns 0 for empty array', () => {
		expect(sumXP([])).toBe(0);
	});
});

// ─── Spaced Repetition ──────────────────────────────────────

describe('timingToQuality', () => {
	it('returns 5 for very fast (<50% of median)', () => {
		expect(timingToQuality(1000, 3000)).toBe(5);
	});

	it('returns 4 for fast (50-70% of median)', () => {
		expect(timingToQuality(1800, 3000)).toBe(4);
	});

	it('returns 3 for correct (70-100% of median)', () => {
		expect(timingToQuality(2500, 3000)).toBe(3);
	});

	it('returns 2 for difficult (100-140% of median)', () => {
		expect(timingToQuality(3500, 3000)).toBe(2);
	});

	it('returns 1 for very difficult (140-200% of median)', () => {
		expect(timingToQuality(5000, 3000)).toBe(1);
	});

	it('returns 0 for failed (>200% of median)', () => {
		expect(timingToQuality(7000, 3000)).toBe(0);
	});
});

describe('updateChordSchedule', () => {
	const baseReview: ChordReview = {
		chordKey: 'C-Maj7',
		root: 'C',
		quality: 'Maj7',
		lastReviewed: new Date().toISOString(),
		nextReview: new Date().toISOString(),
		interval: 1,
		ease: 2.5,
		repetitions: 0,
	};

	it('sets interval to 1 on first correct review', () => {
		const result = updateChordSchedule(baseReview, 4);
		expect(result.interval).toBe(1);
		expect(result.repetitions).toBe(1);
	});

	it('sets interval to 3 on second correct review', () => {
		const review = { ...baseReview, repetitions: 1 };
		const result = updateChordSchedule(review, 4);
		expect(result.interval).toBe(3);
		expect(result.repetitions).toBe(2);
	});

	it('multiplies interval by ease on subsequent reviews', () => {
		const review = { ...baseReview, repetitions: 2, interval: 3, ease: 2.5 };
		const result = updateChordSchedule(review, 4);
		expect(result.interval).toBe(Math.round(3 * 2.5));
		expect(result.repetitions).toBe(3);
	});

	it('resets on failure (quality < 3)', () => {
		const review = { ...baseReview, repetitions: 5, interval: 14, ease: 2.3 };
		const result = updateChordSchedule(review, 2);
		expect(result.interval).toBe(1);
		expect(result.repetitions).toBe(0);
	});

	it('ease stays >= 1.3', () => {
		const review = { ...baseReview, ease: 1.3 };
		const result = updateChordSchedule(review, 0);
		expect(result.ease).toBeGreaterThanOrEqual(1.3);
	});

	it('updates nextReview date', () => {
		const result = updateChordSchedule(baseReview, 4);
		const next = new Date(result.nextReview);
		const now = new Date();
		expect(next.getTime()).toBeGreaterThan(now.getTime());
	});
});

describe('processSessionForSchedule', () => {
	it('creates new entries for unseen chords', () => {
		const timings = [
			{ root: 'C', chord: 'CMaj7', durationMs: 2000 },
			{ root: 'D', chord: 'Dm7', durationMs: 3000 },
		];
		const result = processSessionForSchedule([], timings);
		expect(result.length).toBe(2);
		expect(result.map((r) => r.chordKey)).toContain('C-Maj7');
	});

	it('updates existing entries', () => {
		const existing: ChordReview = {
			chordKey: 'C-Maj7',
			root: 'C',
			quality: 'Maj7',
			lastReviewed: '2025-01-01T00:00:00Z',
			nextReview: '2025-01-02T00:00:00Z',
			interval: 1,
			ease: 2.5,
			repetitions: 1,
		};
		// Use a fast timing relative to median — 800ms vs median of 800ms
		// Actually with only one chord the median = the timing itself (ratio 1.0)
		// quality = 2 (difficult), so repetitions reset. Test that update happened.
		const timings = [
			{ root: 'C', chord: 'CMaj7', durationMs: 1500 },
		];
		const result = processSessionForSchedule([existing], timings);
		expect(result.length).toBe(1);
		expect(result[0].chordKey).toBe('C-Maj7');
		// lastReviewed should be updated to today
		expect(new Date(result[0].lastReviewed).getTime()).toBeGreaterThan(
			new Date('2025-01-01').getTime(),
		);
	});

	it('returns schedule unchanged for empty timings', () => {
		const schedule: ChordReview[] = [];
		const result = processSessionForSchedule(schedule, []);
		expect(result).toEqual([]);
	});
});

// ─── Default Profile ────────────────────────────────────────

describe('createDefaultProfile', () => {
	it('returns profile with sensible defaults', () => {
		const p = createDefaultProfile();
		expect(p.dailyGoalMinutes).toBe(5);
		expect(p.totalXP).toBe(0);
		expect(p.weeklyXP).toBe(0);
		expect(p.activeGoals).toEqual([]);
		expect(p.chordSchedule).toEqual([]);
		expect(p.onboardingDone).toBe(false);
		expect(p.notificationsEnabled).toBe(false);
	});
});

describe('migrateToHabitProfile', () => {
	it('awards 10 XP per historical session', () => {
		const history = [
			{
				id: 's1', timestamp: Date.now(), elapsedMs: 60000, totalChords: 10,
				avgMs: 6000, settings: { difficulty: 'beginner' as const, notation: 'standard' as const, voicing: 'shell' as const, displayMode: 'always' as const, accidentals: 'sharps' as const, progressionMode: 'random' as const },
				midi: { enabled: false, accuracy: 0 },
			},
			{
				id: 's2', timestamp: Date.now() - 86400000, elapsedMs: 120000, totalChords: 20,
				avgMs: 6000, settings: { difficulty: 'beginner' as const, notation: 'standard' as const, voicing: 'shell' as const, displayMode: 'always' as const, accidentals: 'sharps' as const, progressionMode: 'random' as const },
				midi: { enabled: false, accuracy: 0 },
			},
		];
		const streak = { current: 3, best: 5, lastDate: '' };
		const profile = migrateToHabitProfile(history, streak);
		// 2 sessions × 10 XP + 5 best streak × 5 XP = 20 + 25 = 45
		expect(profile.totalXP).toBe(45);
	});

	it('handles empty history', () => {
		const profile = migrateToHabitProfile([], { current: 0, best: 0, lastDate: '' });
		expect(profile.totalXP).toBe(0);
	});
});
