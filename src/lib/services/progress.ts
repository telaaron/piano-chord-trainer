// Progress tracking – save session history to localStorage

import type { Difficulty, NotationStyle, VoicingType, DisplayMode, AccidentalPreference, ProgressionMode } from '$lib/engine';
import { qualityOfChordName } from '$lib/engine';
import { debouncedSync } from './cloud-sync';
import { buildSkillIndex, rootStanding } from './skill-index';

export interface ChordTiming {
	/** The displayed chord name */
	chord: string;
	/** Root note (C, Db, F#, etc.) */
	root: string;
	/** Duration in ms for this specific chord */
	durationMs: number;
	/**
	 * Whether the player answered this chord correctly (verify/MIDI modes).
	 * Absent in older sessions and in modes that don't validate input —
	 * consumers must treat `undefined` as "unknown" (fall back to timing only).
	 */
	correct?: boolean;
	/**
	 * The voicing this chord was played in.
	 *
	 * Previously recoverable only from `session.settings.voicing`, i.e. per
	 * session — which breaks the moment one session mixes voicings, and Coach
	 * sessions do exactly that (each block may set its own). Without it on the
	 * record, "how fast is this player at C Maj7 in shell" has no answer, and
	 * the dial had to average across voicings and call the result a key's speed.
	 *
	 * Absent in sessions recorded before this field existed; consumers fall back
	 * to the session's setting, which is correct for single-voicing sessions and
	 * the best available guess for older mixed ones.
	 */
	voicing?: VoicingType;
}

export interface SessionResult {
	id: string;
	timestamp: number;
	/** Duration in ms */
	elapsedMs: number;
	totalChords: number;
	/** Average ms per chord */
	avgMs: number;
	/** Per-chord timing data (may be absent in older sessions) */
	chordTimings?: ChordTiming[];
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
	/**
	 * Which Coach block produced this session (warmup|review|focus|new|apply|calibrate).
	 * Absent for manually-started sessions and older history.
	 */
	blockKind?: string;
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

/**
 * History as it should be *displayed* to a given tier.
 *
 * The free tier sees a rolling window (FREE_LIMITS.historyDays); Studio sees
 * everything. Nothing is ever deleted — the data stays on the device and comes
 * back in full the moment someone upgrades.
 *
 * Note this is deliberately NOT applied inside `loadHistory()`: the coach,
 * the habit engine and the streak counter all read the full history, and
 * truncating their input would quietly make the coach dumber and break streaks
 * for free users. The limit is a display rule, not a data rule.
 */
export function loadVisibleHistory(fullAccess: boolean, days: number, now = Date.now()): SessionResult[] {
	const all = loadHistory();
	if (fullAccess) return all;
	const cutoff = now - days * 24 * 60 * 60 * 1000;
	return all.filter((s) => s.timestamp >= cutoff);
}

export function saveSession(session: Omit<SessionResult, 'id'>): SessionResult {
	const full: SessionResult = { ...session, id: generateId() };
	const history = loadHistory();
	history.unshift(full);
	// Keep only last N sessions
	if (history.length > MAX_HISTORY) history.length = MAX_HISTORY;
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(history));
		debouncedSync();
	}
	return full;
}

export function clearHistory(): void {
	if (typeof localStorage !== 'undefined') {
		localStorage.removeItem(STORAGE_KEY);
		debouncedSync();
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
	/** Input mode: none, midi, or microphone — replaces midiEnabled */
	inputMode?: 'none' | 'midi' | 'microphone';
	/** 0-based degree indices for custom progression mode */
	customDegrees?: number[];
}

/**
 * Allowed values per enum field, and what to fall back to.
 *
 * These mirror the engine's own types. They are listed rather than derived
 * because a TypeScript union does not exist at runtime, and this function's
 * whole job is to police data that arrives from outside the type system.
 */
const SETTINGS_ENUMS = {
	difficulty: { values: ['beginner', 'intermediate', 'advanced'], fallback: 'beginner' },
	notation: { values: ['standard', 'symbols', 'short'], fallback: 'standard' },
	voicing: {
		values: [
			'root', 'shell', 'half-shell', 'full',
			'rootless-a', 'rootless-b',
			'inversion-1', 'inversion-2', 'inversion-3',
		],
		fallback: 'root',
	},
	displayMode: { values: ['off', 'always', 'verify'], fallback: 'always' },
	accidentals: { values: ['sharps', 'flats', 'both'], fallback: 'flats' },
	notationSystem: { values: ['international', 'german'], fallback: 'international' },
	progressionMode: {
		values: ['random', '2-5-1', '1-6-2-5', 'cycle-of-4ths', '3-6-2-5', '1-4-5', 'diatonic', 'custom'],
		fallback: 'random',
	},
	inputMode: { values: ['none', 'midi', 'microphone'], fallback: 'none' },
} as const;

/**
 * Read saved settings, replacing any value this build does not recognise.
 *
 * Without this, a stale or hand-edited localStorage entry flows straight into
 * the UI: a stored `difficulty: "easy"` (a KeyTier, never a Difficulty) made
 * the settings chip render the literal string "settings.difficulty_easy",
 * because t() returns the key it cannot resolve. Reproduced, then fixed here.
 *
 * The boundary is the right place for it — one guard covers every screen that
 * reads these settings, and the values persist across releases, so a rename in
 * the engine would otherwise poison every returning player's profile.
 */
export function loadSettings(): SavedSettings | null {
	if (typeof localStorage === 'undefined') return null;
	try {
		const raw = localStorage.getItem(SETTINGS_KEY);
		if (!raw) return null;
		const parsed = JSON.parse(raw);
		if (!parsed || typeof parsed !== 'object') return null;

		for (const [field, spec] of Object.entries(SETTINGS_ENUMS)) {
			const current = parsed[field];
			// Leave absent optional fields absent; only correct wrong ones.
			if (current === undefined || current === null) continue;
			if (!(spec.values as readonly string[]).includes(current)) {
				parsed[field] = spec.fallback;
			}
		}
		return parsed as SavedSettings;
	} catch {
		return null;
	}
}

export function saveSettings(settings: SavedSettings): void {
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
		debouncedSync();
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
		debouncedSync();
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
		debouncedSync();
	}
}

// ─── Weak-chord analysis ────────────────────────────────────

export interface WeakChord {
	/** Root note, e.g. "Db" */
	root: string;
	/** Full chord name, e.g. "DbMaj7" */
	chord: string;
	/** Average ms across all appearances */
	avgMs: number;
	/** Number of times this chord appeared */
	count: number;
}

export interface ChordTrend {
	/** Root note */
	root: string;
	/** Old avg (older sessions) */
	oldAvgMs: number;
	/** Recent avg (newer sessions) */
	recentAvgMs: number;
	/** Percentage change (negative = improved) */
	changePercent: number;
}

/**
 * Analyze weak chords from session history.
 * Groups all chord timings by root note, computes averages, returns sorted slowest-first.
 */
export function analyzeWeakChords(history: SessionResult[], limit = 5): WeakChord[] {
	const byRoot = new Map<string, { totalMs: number; count: number; chord: string }>();

	for (const session of history) {
		if (!session.chordTimings) continue;
		for (const ct of session.chordTimings) {
			const existing = byRoot.get(ct.root);
			if (existing) {
				existing.totalMs += ct.durationMs;
				existing.count++;
			} else {
				byRoot.set(ct.root, { totalMs: ct.durationMs, count: 1, chord: ct.chord });
			}
		}
	}

	const result: WeakChord[] = [];
	for (const [root, data] of byRoot) {
		if (data.count < 2) continue; // Need at least 2 data points
		result.push({
			root,
			chord: data.chord,
			avgMs: data.totalMs / data.count,
			count: data.count,
		});
	}

	result.sort((a, b) => b.avgMs - a.avgMs);
	return result.slice(0, limit);
}

/**
 * Compute improvement trends per root note.
 * Compares recent sessions (last 5) vs older sessions (5-15).
 */
export function analyzeChordTrends(history: SessionResult[]): ChordTrend[] {
	const recent = history.slice(0, 5);
	const older = history.slice(5, 15);

	if (recent.length < 2 || older.length < 2) return [];

	function avgByRoot(sessions: SessionResult[]): Map<string, { totalMs: number; count: number }> {
		const map = new Map<string, { totalMs: number; count: number }>();
		for (const s of sessions) {
			if (!s.chordTimings) continue;
			for (const ct of s.chordTimings) {
				const existing = map.get(ct.root);
				if (existing) {
					existing.totalMs += ct.durationMs;
					existing.count++;
				} else {
					map.set(ct.root, { totalMs: ct.durationMs, count: 1 });
				}
			}
		}
		return map;
	}

	const recentAvgs = avgByRoot(recent);
	const olderAvgs = avgByRoot(older);

	const trends: ChordTrend[] = [];
	for (const [root, recentData] of recentAvgs) {
		const olderData = olderAvgs.get(root);
		if (!olderData || olderData.count < 2) continue;

		const recentAvg = recentData.totalMs / recentData.count;
		const olderAvg = olderData.totalMs / olderData.count;
		const change = ((recentAvg - olderAvg) / olderAvg) * 100;

		trends.push({ root, oldAvgMs: olderAvg, recentAvgMs: recentAvg, changePercent: change });
	}

	// Sort by most improved (largest negative change first)
	trends.sort((a, b) => a.changePercent - b.changePercent);
	return trends;
}

// ─── Voicing-aware weak-spot analysis ───────────────────────

export interface WeakSpot {
	/** Root note, e.g. "Db" */
	root: string;
	/** Voicing type used, e.g. "shell" */
	voicing: VoicingType;
	/** Average ms across all appearances with this voicing */
	avgMs: number;
	/** Number of times this root appeared with this voicing */
	count: number;
}

/**
 * Analyze weak spots considering both root AND voicing.
 *
 * The insight: "Db is slow" isn't specific enough.
 * "Db half-shell is 9.2s while Db shell is 2.1s" tells us
 * the problem is the voicing pattern in that key, not the key itself.
 *
 * Groups all chord timings by root+voicing, returns sorted slowest-first.
 */
export function analyzeWeakSpots(history: SessionResult[], limit = 5): WeakSpot[] {
	const byKey = new Map<string, { root: string; voicing: VoicingType; totalMs: number; count: number }>();

	for (const session of history) {
		if (!session.chordTimings) continue;
		const v = session.settings.voicing;
		for (const ct of session.chordTimings) {
			const key = `${ct.root}|${v}`;
			const existing = byKey.get(key);
			if (existing) {
				existing.totalMs += ct.durationMs;
				existing.count++;
			} else {
				byKey.set(key, { root: ct.root, voicing: v, totalMs: ct.durationMs, count: 1 });
			}
		}
	}

	const result: WeakSpot[] = [];
	for (const data of byKey.values()) {
		if (data.count < 2) continue; // Need at least 2 data points
		result.push({
			root: data.root,
			voicing: data.voicing,
			avgMs: data.totalMs / data.count,
			count: data.count,
		});
	}

	result.sort((a, b) => b.avgMs - a.avgMs);
	return result.slice(0, limit);
}

// ─── The clock — twelve keys, ordered by fifths ─────────────

/**
 * Circle of fifths, starting at C. This is the order every jazz player
 * already carries in their head, so the dial needs no legend to be read.
 */
export const CIRCLE_OF_FIFTHS = [
	'C', 'G', 'D', 'A', 'E', 'B', 'Gb', 'Db', 'Ab', 'Eb', 'Bb', 'F',
] as const;

export interface KeyDial {
	/** Root note as stored in the engine, e.g. "Db". */
	root: string;
	/**
	 * The key's standing: the mean of its WEAKEST voicing, or null when never
	 * played. Not an average across voicings — that reported three quick
	 * voicings and one six-second one as a fluent key, which is the opposite of
	 * what the player needs to see.
	 */
	avgMs: number | null;
	/** Attempts behind avgMs — 0 means untouched. */
	count: number;
	/**
	 * Fluent in EVERY voicing played (speed and accuracy), not on average.
	 */
	fluent: boolean;
	/** Which voicing is holding the key back. */
	worstVoicing?: VoicingType;
	/** Per-voicing detail, slowest first — the hover breakdown. */
	perVoicing?: { voicing: VoicingType; avgMs: number; accuracy: number | null }[];
}

/**
 * Per-key timings for the clock, in circle-of-fifths order.
 *
 * Same source as `analyzeWeakSpots`, aggregated across voicings instead of
 * split by them: the clock answers "which keys are slow", the weak-spot list
 * answers "and which voicing is to blame". Keys never played return avgMs
 * null so the UI can show a gap rather than a fake zero — an untouched key
 * is not a fast key, and drawing it as one would flatter the player.
 *
 * @param thresholdMs mastery threshold; defaults to the coach's 2000 ms.
 */
export function buildKeyDial(
	history: SessionResult[],
	thresholdMs = 2000,
	unlockedVoicings?: VoicingType[],
): KeyDial[] {
	const index = buildSkillIndex(history, qualityOfChordName);

	return CIRCLE_OF_FIFTHS.map((root) => {
		const s = rootStanding(index, root, thresholdMs, unlockedVoicings);
		return {
			root,
			avgMs: s.worstAvgMs,
			count: s.attempts,
			fluent: s.mastered,
			...(s.worstVoicing ? { worstVoicing: s.worstVoicing } : {}),
			...(s.perVoicing.length ? { perVoicing: s.perVoicing } : {}),
		};
	});
}
