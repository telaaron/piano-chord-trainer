// Habit Engine — XP, Levels, Smart Goals, Spaced Repetition
// Pure TypeScript, no DOM, no side effects.

import type { SessionResult, StreakData, WeakChord, WeakSpot } from '../services/progress';
import { analyzeWeakChords, analyzeWeakSpots } from '../services/progress';

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
export const XP_HIGH_ACCURACY = 5; // ≥ 95% MIDI accuracy

// ─── Types ──────────────────────────────────────────────────

/** Short labels for voicing types (used in goals/quick start, no i18n needed — these are music terms) */
const VOICING_SHORT_LABELS: Record<string, string> = {
	'root': 'Root Pos.',
	'shell': 'Shell',
	'half-shell': 'Half Shell',
	'full': 'Full',
	'rootless-a': 'Rootless A',
	'rootless-b': 'Rootless B',
	'inversion-1': '1st Inv.',
	'inversion-2': '2nd Inv.',
	'inversion-3': '3rd Inv.',
};

export type GoalType = 'speed' | 'consistency' | 'mastery' | 'exploration' | 'endurance' | 'review' | 'accuracy';
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
	dailyGoalDates: string[]; // YYYY-MM-DD where daily goal was reached this week
	todayPracticeMs: number; // accumulated practice time today
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

	// 8. High accuracy bonus (MIDI ≥ 95%)
	if (session.midi?.enabled && session.midi.accuracy >= 95) {
		events.push({
			amount: XP_HIGH_ACCURACY,
			reason: `${session.midi.accuracy}% accuracy!`,
			reasonKey: 'habit.xp_high_accuracy',
			reasonParams: { accuracy: session.midi.accuracy },
		});
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

	// 2. SPEED — based on weakest root+voicing combo
	const weakSpots = analyzeWeakSpots(history, 5);
	if (weakSpots.length > 0 && weakSpots[0].avgMs > 2000) {
		const ws = weakSpots[0];
		const vLabel = VOICING_SHORT_LABELS[ws.voicing] || ws.voicing;
		const targetTime = Math.max(1.5, Math.round((ws.avgMs / 1000) * 0.75 * 10) / 10);
		goals.push({
			id: generateGoalId(),
			type: 'speed',
			title: `Get ${ws.root} ${vLabel} under ${targetTime}s`,
			titleKey: 'habit.goal_speed',
			titleParams: { root: ws.root, voicing: vLabel, target: targetTime },
			description: `Currently ${(ws.avgMs / 1000).toFixed(1)}s average — aim for ${targetTime}s`,
			descriptionKey: 'habit.goal_speed_desc',
			descriptionParams: { current: Number((ws.avgMs / 1000).toFixed(1)), target: targetTime },
			icon: '⚡',
			target: targetTime,
			current: Number((ws.avgMs / 1000).toFixed(1)),
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

	// 6. ACCURACY — MIDI accuracy below 90%
	const midiSessions = history.filter((s) => s.midi?.enabled && s.midi.accuracy > 0);
	if (midiSessions.length >= 3 && goals.length < 3) {
		const avgAccuracy = Math.round(
			midiSessions.slice(0, 10).reduce((sum, s) => sum + s.midi.accuracy, 0) /
			Math.min(midiSessions.length, 10),
		);
		if (avgAccuracy < 90) {
			const target = Math.min(90, avgAccuracy + 10);
			goals.push({
				id: generateGoalId(),
				type: 'accuracy',
				title: `Reach ${target}% MIDI accuracy`,
				titleKey: 'habit.goal_accuracy',
				titleParams: { target },
				description: `Currently ${avgAccuracy}% — clean playing beats fast playing`,
				descriptionKey: 'habit.goal_accuracy_desc',
				descriptionParams: { current: avgAccuracy, target },
				icon: '🎯',
				target,
				current: avgAccuracy,
				xpReward: XP_GOAL_COMPLETED,
				createdAt: new Date().toISOString(),
				expiresAt,
			});
		}
	}

	// 7. MASTERY — ii-V-I all keys (for intermediate+ players)
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
	/** Root notes to focus on in adaptive drill (e.g. ['Db', 'F#', 'B']) */
	focusRoots?: string[];
	/** Voicing type to drill (e.g. 'half-shell') */
	focusVoicing?: string;
}

/**
 * Generate a quick start suggestion based on profile and history.
 */
export function getQuickStartSuggestion(
	profile: HabitProfile,
	history: SessionResult[],
	streak: StreakData,
): QuickStartSuggestion {
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

	// Weak chord focus — voicing-aware weak spots
	const weakSpots = analyzeWeakSpots(history, 10);
	const slowSpots = weakSpots.filter(ws => ws.avgMs > 2500);
	if (slowSpots.length > 0) {
		// Group by voicing to find which voicing has most issues
		const byVoicing = new Map<string, typeof slowSpots>();
		for (const ws of slowSpots) {
			const list = byVoicing.get(ws.voicing) || [];
			list.push(ws);
			byVoicing.set(ws.voicing, list);
		}
		// Pick voicing with most weak spots (= biggest problem area)
		const [worstVoicing, worstSpots] = [...byVoicing.entries()]
			.sort((a, b) => b[1].length - a[1].length || b[1][0].avgMs - a[1][0].avgMs)[0];
		const roots = worstSpots.slice(0, 3).map(ws => ws.root);
		const targetTime = Math.max(1.5, Math.round(worstSpots[0].avgMs / 1000 * 0.75 * 10) / 10);
		const voicingLabel = VOICING_SHORT_LABELS[worstVoicing] || worstVoicing;
		return {
			title: `${voicingLabel}: ${roots.join(', ')} under ${targetTime}s`,
			titleKey: 'habit.quick_weak_focus',
			titleParams: { voicing: voicingLabel, root: roots.join(', '), target: targetTime },
			description: `Focused drill — ${roots.join(', ')} in ${voicingLabel} appear most often`,
			descriptionKey: 'habit.quick_weak_focus_desc',
			descriptionParams: { voicing: voicingLabel, roots: roots.join(', ') },
			planId: 'adaptive-drill',
			minutes: 3,
			icon: '🎯',
			focusRoots: roots,
			focusVoicing: worstVoicing,
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
				// Check if weak root+voicing combo improved
				const spots = analyzeWeakSpots(history, 10);
				const targetRoot = g.titleParams?.root as string;
				const targetVoicing = g.titleParams?.voicing as string;
				if (targetRoot) {
					// Try voicing-specific match first, fall back to root-only
					const matching = targetVoicing
						? spots.find((ws) => ws.root === targetRoot && VOICING_SHORT_LABELS[ws.voicing] === targetVoicing)
						: spots.find((ws) => ws.root === targetRoot);
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
			case 'accuracy': {
				const recentMidi = history.filter((s) => s.midi?.enabled && s.midi.accuracy > 0).slice(0, 10);
				if (recentMidi.length > 0) {
					g.current = Math.round(
						recentMidi.reduce((sum, s) => sum + s.midi.accuracy, 0) / recentMidi.length,
					);
				}
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
		case 'accuracy':
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
		dailyGoalDates: [],
		todayPracticeMs: 0,
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

// ─── Daily Progress & Motivation ────────────────────────────

export interface DailyProgress {
	/** Minutes practiced today */
	practicedMinutes: number;
	/** Daily goal in minutes */
	goalMinutes: number;
	/** 0-100 progress percent */
	progressPercent: number;
	/** Minutes remaining (0 if goal met) */
	remainingMinutes: number;
	/** Whether daily goal is met */
	goalMet: boolean;
}

/**
 * Compute today's daily goal progress from the profile.
 */
export function getDailyProgress(profile: HabitProfile): DailyProgress {
	const todayStr = new Date().toISOString().slice(0, 10);
	const practicedMs = profile.lastSessionDate === todayStr ? profile.todayPracticeMs : 0;
	const practicedMinutes = Math.round(practicedMs / 60000 * 10) / 10; // 1 decimal
	const goalMinutes = profile.dailyGoalMinutes;
	const progressPercent = Math.min(100, Math.round((practicedMs / (goalMinutes * 60000)) * 100));
	const remainingMs = Math.max(0, goalMinutes * 60000 - practicedMs);
	const remainingMinutes = Math.ceil(remainingMs / 60000);
	const goalMet = practicedMs >= goalMinutes * 60000;

	return { practicedMinutes, goalMinutes, progressPercent, remainingMinutes, goalMet };
}

export type MotivationType =
	| 'not-started'      // No practice today yet
	| 'just-started'     // < 30% of goal
	| 'almost-there'     // ≥ 70% of goal
	| 'goal-reached'     // 100% done
	| 'extra-credit'     // Practicing beyond goal
	| 'streak-at-risk';  // Evening + no practice + active streak

export interface DailyMotivation {
	type: MotivationType;
	messageKey: string;
	messageParams: Record<string, string | number>;
	emoji: string;
}

/**
 * Generate context-aware motivational micro-copy.
 * Considers: daily progress, time of day, streak, sessions today.
 */
export function getDailyMotivation(
	profile: HabitProfile,
	streak: StreakData,
): DailyMotivation {
	const progress = getDailyProgress(profile);
	const hour = new Date().getHours();
	const todayStr = new Date().toISOString().slice(0, 10);
	const practicedToday = profile.lastSessionDate === todayStr && profile.sessionsToday > 0;

	// Streak at risk: evening (after 18h), haven't practiced, streak ≥ 2
	if (!practicedToday && hour >= 18 && streak.current >= 2) {
		return {
			type: 'streak-at-risk',
			messageKey: 'habit.motivation_streak_risk',
			messageParams: { days: streak.current },
			emoji: '🔥',
		};
	}

	// Not started today
	if (!practicedToday || progress.progressPercent === 0) {
		return {
			type: 'not-started',
			messageKey: 'habit.motivation_not_started',
			messageParams: { minutes: progress.goalMinutes },
			emoji: '🎹',
		};
	}

	// Goal reached + came back (extra credit)
	if (progress.goalMet && profile.sessionsToday > 1) {
		return {
			type: 'extra-credit',
			messageKey: 'habit.motivation_extra',
			messageParams: { practiced: progress.practicedMinutes },
			emoji: '⭐',
		};
	}

	// Goal reached
	if (progress.goalMet) {
		return {
			type: 'goal-reached',
			messageKey: 'habit.motivation_goal_reached',
			messageParams: {},
			emoji: '🎉',
		};
	}

	// Almost there (≥ 70%)
	if (progress.progressPercent >= 70) {
		return {
			type: 'almost-there',
			messageKey: 'habit.motivation_almost',
			messageParams: { remaining: progress.remainingMinutes },
			emoji: '💪',
		};
	}

	// Just started (< 70%)
	return {
		type: 'just-started',
		messageKey: 'habit.motivation_keep_going',
		messageParams: { remaining: progress.remainingMinutes, practiced: progress.practicedMinutes },
		emoji: '🎵',
	};
}
