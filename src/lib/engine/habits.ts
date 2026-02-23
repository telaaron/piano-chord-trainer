// Habit Engine — XP, Levels, Smart Goals, Spaced Repetition
// Pure TypeScript, no DOM, no side effects.

import type { SessionResult, StreakData, WeakChord } from '../services/progress';
import { analyzeWeakChords } from '../services/progress';

// ─── XP Constants ───────────────────────────────────────────

export const XP_SESSION_COMPLETE = 10;
export const XP_PERSONAL_BEST = 2;
export const XP_STREAK_DAY = 5;
export const XP_STREAK_7_BONUS = 50;
export const XP_STREAK_14_BONUS = 100;
export const XP_STREAK_30_BONUS = 200;
export const XP_GOAL_COMPLETED = 25;
export const XP_NEW_VOICING = 15;
export const XP_LONG_SESSION = 10; // > 5 min
export const XP_DEDICATED = 20; // 3+ sessions in one day
export const XP_FULL_CIRCLE = 30; // all 12 keys

// ─── Types ──────────────────────────────────────────────────

export type GoalType = 'speed' | 'consistency' | 'mastery' | 'exploration' | 'endurance' | 'review';
export type TimeOfDay = 'morning' | 'afternoon' | 'evening';

export interface SmartGoal {
	id: string;
	type: GoalType;
	title: string;
	titleKey: string; // i18n key
	titleParams?: Record<string, string | number>;
	description: string;
	descriptionKey: string;
	descriptionParams?: Record<string, string | number>;
	icon: string;
	target: number;
	current: number;
	xpReward: number;
	createdAt: string; // ISO
	completedAt?: string; // ISO
	expiresAt?: string; // ISO (weekly goals expire)
}

export interface ChordReview {
	chordKey: string; // e.g. "Db-Maj7"
	root: string;
	quality: string;
	lastReviewed: string; // ISO
	nextReview: string; // ISO
	interval: number; // days
	ease: number; // 1.3 - 2.5 (SM-2)
	repetitions: number;
}

export interface HabitProfile {
	// Player configuration
	dailyGoalMinutes: number; // 2, 5, 10, 15, 20
	preferredTime: TimeOfDay;
	practiceAnchor: string; // free text

	// XP & Level
	totalXP: number;
	weeklyXP: number;
	weekStart: string; // ISO date YYYY-MM-DD (Monday)

	// Goals
	activeGoals: SmartGoal[];
	completedGoals: SmartGoal[]; // last 20

	// Spaced Repetition
	chordSchedule: ChordReview[];

	// Notifications
	notificationsEnabled: boolean;
	notificationTime: string; // HH:MM
	lastNotificationDate: string;

	// Setup completed
	onboardingDone: boolean;

	// Tracking
	sessionsToday: number;
	lastSessionDate: string; // YYYY-MM-DD
}

export interface XPEvent {
	amount: number;
	reason: string;
	reasonKey: string; // i18n
	reasonParams?: Record<string, string | number>;
}

export interface LevelInfo {
	level: number;
	title: string;
	titleKey: string;
	currentXP: number;
	xpForCurrentLevel: number;
	xpForNextLevel: number;
	progressPercent: number;
}

export interface CelebrationEvent {
	type: 'level-up' | 'goal-complete' | 'streak-milestone' | 'personal-best' | 'xp-gain';
	title: string;
	titleKey: string;
	titleParams?: Record<string, string | number>;
	subtitle?: string;
	subtitleKey?: string;
	subtitleParams?: Record<string, string | number>;
	xpGained: number;
	timestamp: string;
}

// ─── Level System ───────────────────────────────────────────

const LEVEL_TITLES: { maxLevel: number; key: string; en: string; de: string }[] = [
	{ maxLevel: 4, key: 'habit.level_listener', en: 'Listener', de: 'Zuhörer' },
	{ maxLevel: 9, key: 'habit.level_beginner', en: 'Beginner', de: 'Einsteiger' },
	{ maxLevel: 14, key: 'habit.level_student', en: 'Student', de: 'Schüler' },
	{ maxLevel: 19, key: 'habit.level_sideman', en: 'Sideman', de: 'Sideman' },
	{ maxLevel: 24, key: 'habit.level_gigging', en: 'Gigging Musician', de: 'Club-Musiker' },
	{ maxLevel: 29, key: 'habit.level_session', en: 'Session Player', de: 'Session-Musiker' },
	{ maxLevel: 34, key: 'habit.level_bandleader', en: 'Bandleader', de: 'Bandleader' },
	{ maxLevel: 39, key: 'habit.level_jazzcat', en: 'Jazz Cat', de: 'Jazz Cat' },
	{ maxLevel: 44, key: 'habit.level_virtuoso', en: 'Virtuoso', de: 'Virtuose' },
	{ maxLevel: 49, key: 'habit.level_legend', en: 'Legend', de: 'Legende' },
	{ maxLevel: Infinity, key: 'habit.level_monk', en: 'Monk Status', de: 'Monk Status' },
];

/**
 * Calculate level from total XP.
 * Formula: level = floor(sqrt(totalXP / 50))
 */
export function calculateLevel(totalXP: number): number {
	return Math.max(1, Math.floor(Math.sqrt(totalXP / 50)));
}

/**
 * Calculate XP needed for a specific level.
 */
export function xpForLevel(level: number): number {
	return level * level * 50;
}

/**
 * Get full level info including progress to next level.
 */
export function getLevelInfo(totalXP: number): LevelInfo {
	const level = calculateLevel(totalXP);
	const currentLevelXP = xpForLevel(level);
	const nextLevelXP = xpForLevel(level + 1);
	const range = nextLevelXP - currentLevelXP;
	const progress = totalXP - currentLevelXP;

	const titleEntry = LEVEL_TITLES.find((t) => level <= t.maxLevel) ?? LEVEL_TITLES[LEVEL_TITLES.length - 1];

	return {
		level,
		title: titleEntry.en, // Will use i18n key at display time
		titleKey: titleEntry.key,
		currentXP: totalXP,
		xpForCurrentLevel: currentLevelXP,
		xpForNextLevel: nextLevelXP,
		progressPercent: range > 0 ? Math.min(100, Math.round((progress / range) * 100)) : 100,
	};
}

// ─── Streak Multiplier ──────────────────────────────────────

export function getStreakMultiplier(streakDays: number): number {
	if (streakDays >= 31) return 2.0;
	if (streakDays >= 15) return 1.5;
	if (streakDays >= 8) return 1.25;
	return 1.0;
}

// ─── XP Calculation ─────────────────────────────────────────

/**
 * Calculate XP earned from a completed session.
 * Returns array of XP events for animation/display.
 */
export function calculateSessionXP(
	session: SessionResult,
	streak: StreakData,
	profile: HabitProfile,
	previousBestAvgMs?: number,
): XPEvent[] {
	const events: XPEvent[] = [];

	// 1. Session complete
	events.push({
		amount: XP_SESSION_COMPLETE,
		reason: 'Session complete',
		reasonKey: 'habit.xp_session_complete',
	});

	// 2. Personal best
	if (previousBestAvgMs && session.avgMs < previousBestAvgMs) {
		events.push({
			amount: XP_PERSONAL_BEST,
			reason: 'New personal best!',
			reasonKey: 'habit.xp_personal_best',
		});
	}

	// 3. Streak day bonus (with multiplier)
	if (streak.current > 0) {
		const multiplier = getStreakMultiplier(streak.current);
		const streakXP = Math.round(XP_STREAK_DAY * multiplier);
		events.push({
			amount: streakXP,
			reason: `Day ${streak.current} streak (${multiplier}×)`,
			reasonKey: 'habit.xp_streak_day',
			reasonParams: { days: streak.current, multiplier },
		});
	}

	// 4. Streak milestones
	if (streak.current === 7) {
		events.push({ amount: XP_STREAK_7_BONUS, reason: '7-day streak!', reasonKey: 'habit.xp_streak_7' });
	} else if (streak.current === 14) {
		events.push({ amount: XP_STREAK_14_BONUS, reason: '14-day streak!', reasonKey: 'habit.xp_streak_14' });
	} else if (streak.current === 30) {
		events.push({ amount: XP_STREAK_30_BONUS, reason: '30-day streak!', reasonKey: 'habit.xp_streak_30' });
	}

	// 5. Long session bonus (> 5 min = 300000ms)
	if (session.elapsedMs > 300000) {
		events.push({
			amount: XP_LONG_SESSION,
			reason: 'Long session bonus',
			reasonKey: 'habit.xp_long_session',
		});
	}

	// 6. Dedicated bonus (3+ sessions today)
	const todayStr = new Date().toISOString().slice(0, 10);
	if (profile.lastSessionDate === todayStr && profile.sessionsToday >= 2) {
		// This will be session #3+
		events.push({
			amount: XP_DEDICATED,
			reason: 'Dedicated practice!',
			reasonKey: 'habit.xp_dedicated',
		});
	}

	// 7. Full circle (all 12 keys in session)
	if (session.chordTimings) {
		const roots = new Set(session.chordTimings.map((ct) => ct.root));
		if (roots.size >= 12) {
			events.push({
				amount: XP_FULL_CIRCLE,
				reason: 'All 12 keys!',
				reasonKey: 'habit.xp_full_circle',
			});
		}
	}

	return events;
}

/**
 * Sum up total XP from events.
 */
export function sumXP(events: XPEvent[]): number {
	return events.reduce((sum, e) => sum + e.amount, 0);
}

// ─── Smart Goal Generation ──────────────────────────────────

function generateGoalId(): string {
	return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

function weekStartISO(): string {
	const now = new Date();
	const day = now.getDay();
	const diff = day === 0 ? 6 : day - 1; // Monday = 0
	const monday = new Date(now);
	monday.setDate(now.getDate() - diff);
	return monday.toISOString().slice(0, 10);
}

function weekEndISO(): string {
	const now = new Date();
	const day = now.getDay();
	const diff = day === 0 ? 0 : 7 - day;
	const sunday = new Date(now);
	sunday.setDate(now.getDate() + diff);
	return sunday.toISOString().slice(0, 10);
}

/**
 * Generate smart goals based on player profile and history.
 * Returns up to 3 goals, prioritized by relevance.
 */
export function generateGoals(
	profile: HabitProfile,
	history: SessionResult[],
	streak: StreakData,
): SmartGoal[] {
	const goals: SmartGoal[] = [];
	const expiresAt = weekEndISO() + 'T23:59:59.999Z';

	// Count days practiced this week
	const currentWeekStart = weekStartISO();
	const weekDays = new Set<string>();
	for (const s of history) {
		const date = new Date(s.timestamp).toISOString().slice(0, 10);
		if (date >= currentWeekStart) weekDays.add(date);
	}

	// 1. CONSISTENCY — always present if streak < 14
	if (streak.current < 14) {
		const targetDays = streak.current < 3 ? 3 : 5;
		goals.push({
			id: generateGoalId(),
			type: 'consistency',
			title: `Practice ${targetDays} days this week`,
			titleKey: 'habit.goal_consistency',
			titleParams: { days: targetDays },
			description: 'Building the habit is more important than any single session',
			descriptionKey: 'habit.goal_consistency_desc',
			icon: '📅',
			target: targetDays,
			current: weekDays.size,
			xpReward: XP_GOAL_COMPLETED,
			createdAt: new Date().toISOString(),
			expiresAt,
		});
	}

	// 2. SPEED — based on weakest chords
	const weakChords = analyzeWeakChords(history, 3);
	if (weakChords.length > 0 && weakChords[0].avgMs > 2000) {
		const wk = weakChords[0];
		const targetTime = Math.max(1.5, Math.round((wk.avgMs / 1000) * 0.75 * 10) / 10);
		goals.push({
			id: generateGoalId(),
			type: 'speed',
			title: `Get ${wk.root} chords under ${targetTime}s`,
			titleKey: 'habit.goal_speed',
			titleParams: { root: wk.root, target: targetTime },
			description: `Currently ${(wk.avgMs / 1000).toFixed(1)}s average — aim for ${targetTime}s`,
			descriptionKey: 'habit.goal_speed_desc',
			descriptionParams: { current: Number((wk.avgMs / 1000).toFixed(1)), target: targetTime },
			icon: '⚡',
			target: targetTime,
			current: Number((wk.avgMs / 1000).toFixed(1)),
			xpReward: XP_GOAL_COMPLETED,
			createdAt: new Date().toISOString(),
			expiresAt,
		});
	}

	// 3. EXPLORATION — unused voicing types
	const usedVoicings = new Set<string>();
	for (const s of history) {
		usedVoicings.add(s.settings.voicing);
	}
	const allVoicings: { key: string; label: string }[] = [
		{ key: 'root', label: 'Root Position' },
		{ key: 'shell', label: 'Shell Voicing' },
		{ key: 'half-shell', label: 'Half Shell' },
		{ key: 'full', label: 'Full Voicing' },
		{ key: 'rootless-a', label: 'Rootless A' },
		{ key: 'rootless-b', label: 'Rootless B' },
		{ key: 'inversion-1', label: '1st Inversion' },
		{ key: 'inversion-2', label: '2nd Inversion' },
		{ key: 'inversion-3', label: '3rd Inversion' },
	];
	const unused = allVoicings.filter((v) => !usedVoicings.has(v.key));
	if (unused.length > 0 && goals.length < 3) {
		goals.push({
			id: generateGoalId(),
			type: 'exploration',
			title: `Try ${unused[0].label}`,
			titleKey: 'habit.goal_exploration',
			titleParams: { voicing: unused[0].label },
			description: `Expand your voicing vocabulary — ${unused.length} types still unexplored`,
			descriptionKey: 'habit.goal_exploration_desc',
			descriptionParams: { remaining: unused.length },
			icon: '🔍',
			target: 1,
			current: 0,
			xpReward: XP_NEW_VOICING,
			createdAt: new Date().toISOString(),
			expiresAt,
		});
	}

	// 4. ENDURANCE — if avg session is short
	const recentSessions = history.slice(0, 10);
	const avgChords = recentSessions.length > 0
		? recentSessions.reduce((s, r) => s + r.totalChords, 0) / recentSessions.length
		: 0;
	if (avgChords > 0 && avgChords < 30 && goals.length < 3) {
		goals.push({
			id: generateGoalId(),
			type: 'endurance',
			title: 'Complete a 50-chord session',
			titleKey: 'habit.goal_endurance',
			description: 'Push your stamina with a longer session',
			descriptionKey: 'habit.goal_endurance_desc',
			icon: '💪',
			target: 50,
			current: 0,
			xpReward: XP_GOAL_COMPLETED,
			createdAt: new Date().toISOString(),
			expiresAt,
		});
	}

	// 5. REVIEW — spaced repetition due chords
	const dueChords = profile.chordSchedule.filter(
		(c) => new Date(c.nextReview) <= new Date(),
	);
	if (dueChords.length >= 3 && goals.length < 3) {
		goals.push({
			id: generateGoalId(),
			type: 'review',
			title: `${dueChords.length} chords due for review`,
			titleKey: 'habit.goal_review',
			titleParams: { count: dueChords.length },
			description: 'Keep your skills sharp — these chords need refreshing',
			descriptionKey: 'habit.goal_review_desc',
			icon: '🔄',
			target: dueChords.length,
			current: 0,
			xpReward: 20,
			createdAt: new Date().toISOString(),
			expiresAt,
		});
	}

	// 6. MASTERY — ii-V-I all keys (for intermediate+ players)
	if (history.length > 20 && goals.length < 3) {
		const iiVI_sessions = history.filter((s) => s.settings.progressionMode === '2-5-1');
		const bestAvg = iiVI_sessions.length > 0
			? Math.min(...iiVI_sessions.map((s) => s.avgMs))
			: Infinity;
		if (bestAvg > 2500) {
			goals.push({
				id: generateGoalId(),
				type: 'mastery',
				title: 'ii-V-I in all keys under 2.5s/chord',
				titleKey: 'habit.goal_mastery_251',
				description: 'The ultimate jazz drill — smooth through every key',
				descriptionKey: 'habit.goal_mastery_251_desc',
				icon: '🏆',
				target: 2.5,
				current: bestAvg === Infinity ? 0 : Number((bestAvg / 1000).toFixed(1)),
				xpReward: 50,
				createdAt: new Date().toISOString(),
				expiresAt,
			});
		}
	}

	return goals.slice(0, 3);
}

// ─── Spaced Repetition (SM-2 variant) ───────────────────────

/**
 * Update a chord's spaced repetition schedule based on performance.
 * quality: 0-5 (0=complete fail, 3=correct with difficulty, 5=perfect)
 */
export function updateChordSchedule(
	review: ChordReview,
	quality: number, // 0-5
): ChordReview {
	const now = new Date();
	let { interval, ease, repetitions } = review;

	if (quality >= 3) {
		// Correct
		if (repetitions === 0) {
			interval = 1;
		} else if (repetitions === 1) {
			interval = 3;
		} else {
			interval = Math.round(interval * ease);
		}
		repetitions++;
	} else {
		// Failed — reset
		repetitions = 0;
		interval = 1;
	}

	// Update ease factor (SM-2)
	ease = Math.max(1.3, ease + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

	const nextReview = new Date(now);
	nextReview.setDate(nextReview.getDate() + interval);

	return {
		...review,
		lastReviewed: now.toISOString(),
		nextReview: nextReview.toISOString(),
		interval,
		ease: Math.round(ease * 100) / 100,
		repetitions,
	};
}

/**
 * Convert chord timing performance to SM-2 quality (0-5).
 */
export function timingToQuality(avgMs: number, medianMs: number): number {
	const ratio = avgMs / medianMs;
	if (ratio < 0.5) return 5; // Very fast
	if (ratio < 0.7) return 4; // Fast
	if (ratio < 1.0) return 3; // Correct
	if (ratio < 1.4) return 2; // Difficult
	if (ratio < 2.0) return 1; // Very difficult
	return 0; // Failed
}

/**
 * Process a session's chord timings and update the spaced repetition schedule.
 */
export function processSessionForSchedule(
	schedule: ChordReview[],
	timings: { root: string; chord: string; durationMs: number }[],
): ChordReview[] {
	if (timings.length === 0) return schedule;

	// Group timings by chord key
	const grouped = new Map<string, number[]>();
	for (const t of timings) {
		const quality = t.chord.startsWith(t.root) ? t.chord.slice(t.root.length) || 'Maj' : t.chord;
		const key = `${t.root}-${quality}`;
		const existing = grouped.get(key) || [];
		existing.push(t.durationMs);
		grouped.set(key, existing);
	}

	// Compute median
	const allTimes = timings.map((t) => t.durationMs);
	allTimes.sort((a, b) => a - b);
	const medianMs = allTimes[Math.floor(allTimes.length / 2)] || 3000;

	const scheduleMap = new Map(schedule.map((s) => [s.chordKey, s]));

	for (const [key, times] of grouped) {
		const avgMs = times.reduce((a, b) => a + b, 0) / times.length;
		const quality = timingToQuality(avgMs, medianMs);

		const existing = scheduleMap.get(key);
		if (existing) {
			scheduleMap.set(key, updateChordSchedule(existing, quality));
		} else {
			// New chord — create entry
			const [root, qualityStr] = key.split('-');
			const now = new Date();
			const nextReview = new Date(now);
			nextReview.setDate(nextReview.getDate() + (quality >= 3 ? 1 : 0));
			scheduleMap.set(key, {
				chordKey: key,
				root,
				quality: qualityStr,
				lastReviewed: now.toISOString(),
				nextReview: nextReview.toISOString(),
				interval: quality >= 3 ? 1 : 0,
				ease: 2.5,
				repetitions: quality >= 3 ? 1 : 0,
			});
		}
	}

	return [...scheduleMap.values()];
}

// ─── Quick Start Suggestion ─────────────────────────────────

export interface QuickStartSuggestion {
	title: string;
	titleKey: string;
	titleParams?: Record<string, string | number>;
	description: string;
	descriptionKey: string;
	descriptionParams?: Record<string, string | number>;
	planId?: string; // If it maps to an existing plan
	minutes: number;
	icon: string;
}

/**
 * Generate a quick start suggestion based on profile and history.
 */
export function getQuickStartSuggestion(
	profile: HabitProfile,
	history: SessionResult[],
	streak: StreakData,
): QuickStartSuggestion {
	const weakChords = analyzeWeakChords(history, 1);

	// After streak loss — ultra low friction
	if (streak.current === 0 && streak.best > 3) {
		return {
			title: 'Quick restart: 4 chords',
			titleKey: 'habit.quick_restart',
			description: "Just 4 chords. That's all it takes to start again.",
			descriptionKey: 'habit.quick_restart_desc',
			minutes: 1,
			icon: '🔥',
		};
	}

	// Weak chord focus
	if (weakChords.length > 0 && weakChords[0].avgMs > 3000) {
		return {
			title: `3 min ${weakChords[0].root} focus`,
			titleKey: 'habit.quick_weak_focus',
			titleParams: { root: weakChords[0].root },
			description: `Your ${weakChords[0].root} chords need work — quick targeted drill`,
			descriptionKey: 'habit.quick_weak_focus_desc',
			descriptionParams: { root: weakChords[0].root },
			minutes: 3,
			icon: '🎯',
		};
	}

	// Default based on daily goal
	return {
		title: `${profile.dailyGoalMinutes} min warm-up`,
		titleKey: 'habit.quick_warmup',
		titleParams: { minutes: profile.dailyGoalMinutes },
		description: 'Your daily practice — start with what you know',
		descriptionKey: 'habit.quick_warmup_desc',
		planId: 'warmup',
		minutes: profile.dailyGoalMinutes,
		icon: '☀️',
	};
}

// ─── Goal Progress Check ────────────────────────────────────

/**
 * Check goals after a session and return completed ones.
 */
export function checkGoalProgress(
	goals: SmartGoal[],
	session: SessionResult,
	history: SessionResult[],
	streak: StreakData,
): { updated: SmartGoal[]; completed: SmartGoal[] } {
	const completed: SmartGoal[] = [];
	const updated: SmartGoal[] = [];

	for (const goal of goals) {
		if (goal.completedAt) {
			updated.push(goal);
			continue;
		}

		const g = { ...goal };

		switch (g.type) {
			case 'consistency': {
				const currentWeekStart = weekStartISO();
				const weekDays = new Set<string>();
				for (const s of history) {
					const date = new Date(s.timestamp).toISOString().slice(0, 10);
					if (date >= currentWeekStart) weekDays.add(date);
				}
				g.current = weekDays.size;
				break;
			}
			case 'speed': {
				// Check if weak chord improved
				const weakChords = analyzeWeakChords(history, 5);
				const targetRoot = g.titleParams?.root as string;
				if (targetRoot) {
					const matching = weakChords.find((w) => w.root === targetRoot);
					g.current = matching
						? Number((matching.avgMs / 1000).toFixed(1))
						: g.target; // If not in weak list anymore = improved!
				}
				break;
			}
			case 'exploration': {
				const voicingUsed = session.settings.voicing;
				const targetVoicing = g.titleParams?.voicing as string;
				if (targetVoicing) {
					const usedVoicings = new Set(history.map((s) => s.settings.voicing));
					g.current = usedVoicings.has(voicingUsed) ? 1 : 0;
				}
				break;
			}
			case 'endurance': {
				g.current = Math.max(g.current, session.totalChords);
				break;
			}
			case 'mastery': {
				const iiVI = history.filter((s) => s.settings.progressionMode === '2-5-1');
				const best = iiVI.length > 0 ? Math.min(...iiVI.map((s) => s.avgMs)) : Infinity;
				g.current = best === Infinity ? 0 : Number((best / 1000).toFixed(1));
				break;
			}
			case 'review': {
				// Count practiced since goal creation
				const sinceCreation = history.filter((s) => new Date(s.timestamp) >= new Date(g.createdAt));
				const reviewedRoots = new Set<string>();
				for (const s of sinceCreation) {
					if (s.chordTimings) {
						for (const ct of s.chordTimings) reviewedRoots.add(ct.root);
					}
				}
				g.current = reviewedRoots.size;
				break;
			}
		}

		// Check completion
		const isCompleted = isGoalMet(g);
		if (isCompleted) {
			g.completedAt = new Date().toISOString();
			completed.push(g);
		}
		updated.push(g);
	}

	return { updated, completed };
}

function isGoalMet(goal: SmartGoal): boolean {
	switch (goal.type) {
		case 'consistency':
		case 'endurance':
		case 'exploration':
		case 'review':
			return goal.current >= goal.target;
		case 'speed':
		case 'mastery':
			// For time-based goals: current <= target means faster
			return goal.current > 0 && goal.current <= goal.target;
		default:
			return false;
	}
}

// ─── Default Profile ────────────────────────────────────────

export function createDefaultProfile(): HabitProfile {
	return {
		dailyGoalMinutes: 5,
		preferredTime: 'evening',
		practiceAnchor: '',
		totalXP: 0,
		weeklyXP: 0,
		weekStart: weekStartISO(),
		activeGoals: [],
		completedGoals: [],
		chordSchedule: [],
		notificationsEnabled: false,
		notificationTime: '20:00',
		lastNotificationDate: '',
		onboardingDone: false,
		sessionsToday: 0,
		lastSessionDate: '',
	};
}

/**
 * Migrate existing data into a new HabitProfile.
 * Retroactively awards 10 XP per historical session.
 */
export function migrateToHabitProfile(
	history: SessionResult[],
	streak: StreakData,
): HabitProfile {
	const profile = createDefaultProfile();

	// Retroactive XP: 10 per session
	profile.totalXP = history.length * XP_SESSION_COMPLETE;

	// Add streak bonus XP retroactively
	if (streak.best > 0) {
		profile.totalXP += streak.best * XP_STREAK_DAY;
	}

	// Sessions today
	const today = new Date().toISOString().slice(0, 10);
	profile.sessionsToday = history.filter(
		(s) => new Date(s.timestamp).toISOString().slice(0, 10) === today,
	).length;
	profile.lastSessionDate = history.length > 0
		? new Date(history[0].timestamp).toISOString().slice(0, 10)
		: '';

	return profile;
}
