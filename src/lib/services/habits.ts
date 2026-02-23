// Habit Service — localStorage persistence for Habit Engine
// Handles save/load of HabitProfile, goals, celebrations, and XP

import type {
	HabitProfile,
	SmartGoal,
	CelebrationEvent,
	XPEvent,
	ChordReview,
} from '../engine/habits';
import {
	createDefaultProfile,
	migrateToHabitProfile,
	generateGoals,
	calculateSessionXP,
	sumXP,
	checkGoalProgress,
	getLevelInfo,
	processSessionForSchedule,
	getQuickStartSuggestion,
	XP_GOAL_COMPLETED,
} from '../engine/habits';
import type { SessionResult, StreakData } from './progress';
import { loadHistory, loadStreak } from './progress';

// ─── Storage Keys ───────────────────────────────────────────

const PROFILE_KEY = 'chord-trainer-habit-profile';
const CELEBRATIONS_KEY = 'chord-trainer-celebrations';

// ─── Load / Save ────────────────────────────────────────────

export function loadHabitProfile(): HabitProfile {
	if (typeof localStorage === 'undefined') return createDefaultProfile();
	try {
		const raw = localStorage.getItem(PROFILE_KEY);
		if (!raw) {
			// First time — try migration
			return migrateExisting();
		}
		const profile: HabitProfile = JSON.parse(raw);

		// Reset weekly XP if new week
		const today = new Date();
		const day = today.getDay();
		const diff = day === 0 ? 6 : day - 1;
		const monday = new Date(today);
		monday.setDate(today.getDate() - diff);
		const weekStart = monday.toISOString().slice(0, 10);

		if (profile.weekStart !== weekStart) {
			profile.weeklyXP = 0;
			profile.weekStart = weekStart;
			// Regenerate goals for new week
			const history = loadHistory();
			const streak = loadStreak();
			profile.activeGoals = generateGoals(profile, history, streak);
		}

		// Reset sessions today if different day
		const todayStr = today.toISOString().slice(0, 10);
		if (profile.lastSessionDate !== todayStr) {
			profile.sessionsToday = 0;
		}

		return profile;
	} catch {
		return migrateExisting();
	}
}

export function saveHabitProfile(profile: HabitProfile): void {
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(PROFILE_KEY, JSON.stringify(profile));
	}
}

function migrateExisting(): HabitProfile {
	const history = loadHistory();
	const streak = loadStreak();
	const profile = migrateToHabitProfile(history, streak);

	// Generate initial goals
	if (history.length > 0) {
		profile.activeGoals = generateGoals(profile, history, streak);
	}

	saveHabitProfile(profile);
	return profile;
}

// ─── Celebrations Queue ─────────────────────────────────────

export function loadPendingCelebrations(): CelebrationEvent[] {
	if (typeof localStorage === 'undefined') return [];
	try {
		const raw = localStorage.getItem(CELEBRATIONS_KEY);
		return raw ? JSON.parse(raw) : [];
	} catch {
		return [];
	}
}

export function savePendingCelebrations(celebrations: CelebrationEvent[]): void {
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(CELEBRATIONS_KEY, JSON.stringify(celebrations));
	}
}

export function clearPendingCelebrations(): void {
	if (typeof localStorage !== 'undefined') {
		localStorage.removeItem(CELEBRATIONS_KEY);
	}
}

// ─── Session Processing ─────────────────────────────────────

export interface SessionHabitResult {
	/** XP events earned */
	xpEvents: XPEvent[];
	/** Total XP earned this session */
	totalXP: number;
	/** Updated profile */
	profile: HabitProfile;
	/** Celebrations to show */
	celebrations: CelebrationEvent[];
	/** Did the player level up? */
	leveledUp: boolean;
	/** New level (if leveled up) */
	newLevel?: number;
	/** Completed goals this session */
	completedGoals: SmartGoal[];
}

/**
 * Process a completed session through the habit engine.
 * Updates XP, checks goals, updates spaced repetition, generates celebrations.
 */
export function processSessionHabits(
	session: SessionResult,
	previousBestAvgMs?: number,
): SessionHabitResult {
	const profile = loadHabitProfile();
	const streak = loadStreak();
	const history = loadHistory();
	const oldLevel = getLevelInfo(profile.totalXP).level;

	// 1. Calculate XP
	const xpEvents = calculateSessionXP(session, streak, profile, previousBestAvgMs);
	const totalXP = sumXP(xpEvents);

	// 2. Update profile XP
	profile.totalXP += totalXP;
	profile.weeklyXP += totalXP;

	// 3. Track sessions today
	const todayStr = new Date().toISOString().slice(0, 10);
	if (profile.lastSessionDate === todayStr) {
		profile.sessionsToday++;
	} else {
		profile.sessionsToday = 1;
		profile.lastSessionDate = todayStr;
	}

	// 4. Check goal progress
	const { updated, completed } = checkGoalProgress(
		profile.activeGoals,
		session,
		history,
		streak,
	);
	profile.activeGoals = updated.filter((g) => !g.completedAt);

	// Add XP for completed goals
	for (const goal of completed) {
		profile.totalXP += goal.xpReward;
		profile.weeklyXP += goal.xpReward;
		xpEvents.push({
			amount: goal.xpReward,
			reason: `Goal: ${goal.title}`,
			reasonKey: 'habit.xp_goal_completed',
			reasonParams: { title: goal.title },
		});
	}

	// Move completed to archive
	profile.completedGoals = [
		...completed,
		...profile.completedGoals,
	].slice(0, 20);

	// Regenerate goals if we have < 3 active
	if (profile.activeGoals.length < 3) {
		const newGoals = generateGoals(profile, history, streak);
		const activeIds = new Set(profile.activeGoals.map((g) => g.type));
		for (const ng of newGoals) {
			if (!activeIds.has(ng.type) && profile.activeGoals.length < 3) {
				profile.activeGoals.push(ng);
				activeIds.add(ng.type);
			}
		}
	}

	// 5. Update spaced repetition
	if (session.chordTimings && session.chordTimings.length > 0) {
		profile.chordSchedule = processSessionForSchedule(
			profile.chordSchedule,
			session.chordTimings,
		);
	}

	// 6. Check level up
	const newLevel = getLevelInfo(profile.totalXP).level;
	const leveledUp = newLevel > oldLevel;

	// 7. Build celebrations
	const celebrations: CelebrationEvent[] = [];
	const now = new Date().toISOString();

	// XP summary
	if (totalXP > 0) {
		celebrations.push({
			type: 'xp-gain',
			title: `+${totalXP + completed.reduce((s, g) => s + g.xpReward, 0)} XP`,
			titleKey: 'habit.celebration_xp',
			titleParams: { amount: totalXP + completed.reduce((s, g) => s + g.xpReward, 0) },
			xpGained: totalXP,
			timestamp: now,
		});
	}

	// Level up
	if (leveledUp) {
		const levelInfo = getLevelInfo(profile.totalXP);
		celebrations.push({
			type: 'level-up',
			title: `Level ${newLevel}!`,
			titleKey: 'habit.celebration_level_up',
			titleParams: { level: newLevel },
			subtitle: levelInfo.title,
			subtitleKey: levelInfo.titleKey,
			xpGained: 0,
			timestamp: now,
		});
	}

	// Goal completions
	for (const goal of completed) {
		celebrations.push({
			type: 'goal-complete',
			title: goal.title,
			titleKey: goal.titleKey,
			titleParams: goal.titleParams,
			subtitle: `+${goal.xpReward} XP`,
			subtitleKey: 'habit.xp_amount',
			subtitleParams: { amount: goal.xpReward },
			xpGained: goal.xpReward,
			timestamp: now,
		});
	}

	// Streak milestones
	if ([7, 14, 30, 50, 100].includes(streak.current)) {
		celebrations.push({
			type: 'streak-milestone',
			title: `${streak.current}-day streak!`,
			titleKey: 'habit.celebration_streak',
			titleParams: { days: streak.current },
			xpGained: 0,
			timestamp: now,
		});
	}

	// Personal best
	if (previousBestAvgMs && session.avgMs < previousBestAvgMs) {
		const improvement = Math.round((1 - session.avgMs / previousBestAvgMs) * 100);
		celebrations.push({
			type: 'personal-best',
			title: 'New Personal Best!',
			titleKey: 'habit.celebration_pb',
			subtitle: `${improvement}% faster`,
			subtitleKey: 'habit.celebration_pb_sub',
			subtitleParams: { percent: improvement },
			xpGained: 0,
			timestamp: now,
		});
	}

	// 8. Save
	saveHabitProfile(profile);

	return {
		xpEvents,
		totalXP: totalXP + completed.reduce((s, g) => s + g.xpReward, 0),
		profile,
		celebrations,
		leveledUp,
		newLevel: leveledUp ? newLevel : undefined,
		completedGoals: completed,
	};
}

// ─── Notification Helpers ───────────────────────────────────

/**
 * Check if notifications are supported and enabled.
 */
export function canNotify(): boolean {
	if (typeof window === 'undefined') return false;
	if (!('Notification' in window)) return false;
	return Notification.permission === 'granted';
}

/**
 * Request notification permission.
 */
export async function requestNotificationPermission(): Promise<boolean> {
	if (typeof window === 'undefined') return false;
	if (!('Notification' in window)) return false;

	const permission = await Notification.requestPermission();
	return permission === 'granted';
}

/**
 * Schedule a practice reminder notification.
 * Uses setTimeout to fire at the configured time.
 * Returns a cleanup function.
 */
export function scheduleDailyReminder(profile: HabitProfile): (() => void) | null {
	if (!canNotify() || !profile.notificationsEnabled) return null;

	const now = new Date();
	const todayStr = now.toISOString().slice(0, 10);

	// Don't notify if already practiced today
	if (profile.lastSessionDate === todayStr) return null;

	// Don't notify more than once per day
	if (profile.lastNotificationDate === todayStr) return null;

	// Calculate ms until notification time
	const [hours, minutes] = profile.notificationTime.split(':').map(Number);
	const notifTime = new Date(now);
	notifTime.setHours(hours, minutes, 0, 0);

	// If the time has already passed today, don't schedule
	if (notifTime <= now) return null;

	const delay = notifTime.getTime() - now.getTime();

	const timeout = setTimeout(() => {
		const streak = loadStreak();
		const history = loadHistory();
		const suggestion = getQuickStartSuggestion(profile, history, streak);

		const body = streak.current > 0
			? `🔥 ${streak.current}-day streak — ${suggestion.title}`
			: suggestion.description;

		new Notification('🎹 Time to practice!', {
			body,
			icon: '/favicon/favicon-192.png',
			badge: '/favicon/favicon-96.png',
			tag: 'practice-reminder',
		});

		// Mark as notified
		profile.lastNotificationDate = todayStr;
		saveHabitProfile(profile);
	}, delay);

	return () => clearTimeout(timeout);
}

/**
 * Schedule an evening streak-saver notification.
 */
export function scheduleStreakSaver(profile: HabitProfile): (() => void) | null {
	if (!canNotify() || !profile.notificationsEnabled) return null;

	const now = new Date();
	const todayStr = now.toISOString().slice(0, 10);
	const streak = loadStreak();

	// Only if streak > 2 and haven't practiced today
	if (streak.current < 3 || profile.lastSessionDate === todayStr) return null;

	// Schedule for 20:00
	const notifTime = new Date(now);
	notifTime.setHours(20, 0, 0, 0);
	if (notifTime <= now) return null;

	const delay = notifTime.getTime() - now.getTime();

	const timeout = setTimeout(() => {
		// Re-check — might have practiced in the meantime
		const currentProfile = loadHabitProfile();
		if (currentProfile.lastSessionDate === todayStr) return;

		new Notification('🔥 Don\'t lose your streak!', {
			body: `${streak.current} days strong — just 2 minutes keeps it alive!`,
			icon: '/favicon/favicon-192.png',
			tag: 'streak-saver',
		});
	}, delay);

	return () => clearTimeout(timeout);
}
