// Progress tracking – save session history to localStorage

import type { Difficulty, NotationStyle, VoicingType, DisplayMode, AccidentalPreference, ProgressionMode } from '$lib/engine';

export interface SessionResult {
	id: string;
	timestamp: number;
	/** Duration in ms */
	elapsedMs: number;
	totalChords: number;
	/** Average ms per chord */
	avgMs: number;
	settings: {
		difficulty: Difficulty;
		notation: NotationStyle;
		voicing: VoicingType;
		displayMode: DisplayMode;
		accidentals: AccidentalPreference;
		progressionMode: ProgressionMode;
	};
	midi: {
		enabled: boolean;
		accuracy: number;
	};
}

export interface PersonalBest {
	elapsedMs: number;
	avgMs: number;
	timestamp: number;
	totalChords: number;
}

export interface ProgressStats {
	totalSessions: number;
	totalChords: number;
	totalTimeMs: number;
	/** Average ms per chord across all sessions */
	overallAvgMs: number;
	/** Best times keyed by "difficulty-voicing-progressionMode" */
	personalBests: Record<string, PersonalBest>;
	/** Last 30 sessions for trend chart */
	recentSessions: SessionResult[];
}

const STORAGE_KEY = 'chord-trainer-history';
const SETTINGS_KEY = 'chord-trainer-settings';
const MAX_HISTORY = 100;

function generateId(): string {
	return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

function bestKey(session: SessionResult): string {
	const s = session.settings;
	return `${s.difficulty}-${s.voicing}-${s.progressionMode}`;
}

// ─── History ────────────────────────────────────────────────

export function loadHistory(): SessionResult[] {
	if (typeof localStorage === 'undefined') return [];
	try {
		const raw = localStorage.getItem(STORAGE_KEY);
		return raw ? JSON.parse(raw) : [];
	} catch {
		return [];
	}
}

export function saveSession(session: Omit<SessionResult, 'id'>): SessionResult {
	const full: SessionResult = { ...session, id: generateId() };
	const history = loadHistory();
	history.unshift(full);
	// Keep only last N sessions
	if (history.length > MAX_HISTORY) history.length = MAX_HISTORY;
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(history));
	}
	return full;
}

export function clearHistory(): void {
	if (typeof localStorage !== 'undefined') {
		localStorage.removeItem(STORAGE_KEY);
	}
}

// ─── Stats ──────────────────────────────────────────────────

export function computeStats(history: SessionResult[]): ProgressStats {
	const totalSessions = history.length;
	let totalChords = 0;
	let totalTimeMs = 0;
	const personalBests: Record<string, PersonalBest> = {};

	for (const s of history) {
		totalChords += s.totalChords;
		totalTimeMs += s.elapsedMs;

		const key = bestKey(s);
		const existing = personalBests[key];
		if (!existing || s.avgMs < existing.avgMs) {
			personalBests[key] = {
				elapsedMs: s.elapsedMs,
				avgMs: s.avgMs,
				timestamp: s.timestamp,
				totalChords: s.totalChords,
			};
		}
	}

	return {
		totalSessions,
		totalChords,
		totalTimeMs,
		overallAvgMs: totalChords > 0 ? totalTimeMs / totalChords : 0,
		personalBests,
		recentSessions: history.slice(0, 30),
	};
}

// ─── Settings persistence ───────────────────────────────────

export interface SavedSettings {
	difficulty: Difficulty;
	notation: NotationStyle;
	voicing: VoicingType;
	displayMode: DisplayMode;
	accidentals: AccidentalPreference;
	notationSystem: string;
	totalChords: number;
	progressionMode: ProgressionMode;
	midiEnabled: boolean;
}

export function loadSettings(): SavedSettings | null {
	if (typeof localStorage === 'undefined') return null;
	try {
		const raw = localStorage.getItem(SETTINGS_KEY);
		return raw ? JSON.parse(raw) : null;
	} catch {
		return null;
	}
}

export function saveSettings(settings: SavedSettings): void {
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
	}
}

// ─── Streak tracking ────────────────────────────────────────

const STREAK_KEY = 'chord-trainer-streak';

export interface StreakData {
	/** Current streak length in days */
	current: number;
	/** Longest streak ever */
	best: number;
	/** Last practice date as YYYY-MM-DD */
	lastDate: string;
}

function todayStr(): string {
	return new Date().toISOString().slice(0, 10);
}

function yesterdayStr(): string {
	const d = new Date();
	d.setDate(d.getDate() - 1);
	return d.toISOString().slice(0, 10);
}

export function loadStreak(): StreakData {
	if (typeof localStorage === 'undefined') return { current: 0, best: 0, lastDate: '' };
	try {
		const raw = localStorage.getItem(STREAK_KEY);
		if (!raw) return { current: 0, best: 0, lastDate: '' };
		const data: StreakData = JSON.parse(raw);

		// Check if streak is still alive
		const today = todayStr();
		const yesterday = yesterdayStr();

		if (data.lastDate === today) {
			// Already practiced today — streak intact
			return data;
		} else if (data.lastDate === yesterday) {
			// Practiced yesterday — streak continues but not yet today
			return data;
		} else {
			// Streak broken (more than 1 day gap)
			return { current: 0, best: data.best, lastDate: data.lastDate };
		}
	} catch {
		return { current: 0, best: 0, lastDate: '' };
	}
}

export function recordPracticeDay(): StreakData {
	const streak = loadStreak();
	const today = todayStr();

	if (streak.lastDate === today) {
		// Already recorded today
		return streak;
	}

	const yesterday = yesterdayStr();
	if (streak.lastDate === yesterday || streak.lastDate === '') {
		// Continue streak or start new one
		streak.current += 1;
	} else {
		// Gap — reset to 1
		streak.current = 1;
	}

	streak.lastDate = today;
	streak.best = Math.max(streak.best, streak.current);

	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(STREAK_KEY, JSON.stringify(streak));
	}
	return streak;
}

// ─── Plan tracking ──────────────────────────────────────────

const PLAN_HISTORY_KEY = 'chord-trainer-plan-history';

export function loadRecentPlanIds(): string[] {
	if (typeof localStorage === 'undefined') return [];
	try {
		const raw = localStorage.getItem(PLAN_HISTORY_KEY);
		return raw ? JSON.parse(raw) : [];
	} catch {
		return [];
	}
}

export function recordPlanUsed(planId: string): void {
	const ids = loadRecentPlanIds();
	// Remove if already present, add to front
	const filtered = ids.filter((id) => id !== planId);
	filtered.unshift(planId);
	// Keep last 10
	if (filtered.length > 10) filtered.length = 10;
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(PLAN_HISTORY_KEY, JSON.stringify(filtered));
	}
}
