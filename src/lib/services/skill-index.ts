// Skill index — the one place that answers "how good is this player at chord X
// in voicing Y", and the only thing every progress surface should read.
//
// Before this, four stores each held part of the answer and each dropped a
// different axis: session timings kept the root but not the voicing, coach unit
// states kept voicing+quality but not the individual key, the SRS schedule kept
// root+quality but not voicing, and personal bests kept neither root nor
// quality. So no component could answer the question above, and the circle of
// fifths resorted to averaging every attempt ever recorded — which rated a key
// "fluent" while one of its voicings took six seconds.
//
// This module derives one record per (root × quality × voicing) from the session
// history, carrying BOTH speed and accuracy, over a rolling window of the most
// recent attempts. It owns no storage: history stays the single source of truth,
// and this is the projection everything else reads.

import type { ChordTiming, SessionResult } from './progress';
import type { VoicingType } from '$lib/engine';

/** Attempts kept per cell. The rolling average reflects recent playing, not a lifetime mean. */
export const SKILL_WINDOW = 3;

/** One cell of the index: a single chord in a single voicing. */
export interface SkillCell {
	root: string;
	/** Canonical quality display, e.g. "Maj7". */
	quality: string;
	voicing: VoicingType;
	/** Mean ms over the last `SKILL_WINDOW` attempts (most recent first). */
	avgMs: number;
	/** Fraction of those attempts played correctly, or null when none recorded it. */
	accuracy: number | null;
	/** How many attempts the average is based on (≤ SKILL_WINDOW). */
	attempts: number;
	/** Total attempts ever seen for this cell, across all sessions. */
	totalAttempts: number;
	/** Timestamp of the most recent attempt. */
	lastPlayedAt: number;
}

/** `root|quality|voicing` — the key every consumer should use. */
export function cellKey(root: string, quality: string, voicing: string): string {
	return `${root}|${quality}|${voicing}`;
}

/**
 * Enharmonic spellings of the same pitch, so Gb and F# land in one cell.
 *
 * The app generates flats by default but can be set to sharps, and the coach
 * ladder spells the tritone F#. Keying on the raw string split one key into two
 * half-filled cells — the same trap that made one key in twelve unscoreable.
 */
const ENHARMONIC: Record<string, string> = {
	'F#': 'Gb', 'C#': 'Db', 'D#': 'Eb', 'G#': 'Ab', 'A#': 'Bb',
};

/** Canonical spelling for a root, so both spellings share one cell. */
export function canonicalRoot(root: string): string {
	return ENHARMONIC[root] ?? root;
}

/** Raw attempt, flattened out of the session history with its context attached. */
interface Attempt {
	root: string;
	quality: string;
	voicing: VoicingType;
	durationMs: number;
	correct?: boolean;
	at: number;
	/** Position within its session, so same-session chords keep played order. */
	seq: number;
}

/**
 * Flatten history into attempts, newest session first.
 *
 * `voicing` comes from the timing itself when present. Older records predate
 * that field, so they fall back to the session's setting — right for
 * single-voicing sessions, and the best available guess for older mixed ones.
 */
function flatten(
	history: SessionResult[],
	qualityOf: (chord: string) => string,
): Attempt[] {
	const out: Attempt[] = [];
	history.forEach((session, sessionIdx) => {
		if (!session.chordTimings) return;
		const fallback = session.settings?.voicing;
		// Timestamps order the window. Records without one still have to count —
		// dropping them would discard real practice — so they fall back to array
		// position. Note that position alone cannot say which is newer: the stored
		// history is newest-first, while a caller building a "before/after" pair
		// appends. So an absent timestamp is treated as "no information", ordered
		// after everything timestamped and left in the order given.
		const at = session.timestamp ?? Number.NEGATIVE_INFINITY;
		session.chordTimings.forEach((ct, chordIdx) => {
			const voicing = (ct.voicing ?? fallback) as VoicingType | undefined;
			if (!voicing) return; // no way to place it — skip rather than guess
			const quality = qualityOf(ct.chord);
			if (!quality) return;
			out.push({
				root: canonicalRoot(ct.root),
				quality,
				voicing,
				durationMs: ct.durationMs,
				correct: ct.correct,
				at,
				// Global position, so untimestamped records still have a stable and
				// meaningful order: later in the input means later played.
				seq: sessionIdx * 10_000 + chordIdx,
			});
		});
	});

	// Newest first. Timestamps decide when both sides have one; otherwise input
	// order does, with later entries treated as more recent.
	return out.sort((a, b) => {
		const bothTimed = Number.isFinite(a.at) && Number.isFinite(b.at);
		if (bothTimed && a.at !== b.at) return b.at - a.at;
		if (!bothTimed && Number.isFinite(a.at) !== Number.isFinite(b.at)) {
			return Number.isFinite(a.at) ? -1 : 1; // timestamped wins
		}
		return b.seq - a.seq;
	});
}

/**
 * Build the index: one cell per (root × quality × voicing).
 *
 * @param qualityOf maps a displayed chord name to its canonical quality. Passed
 *   in rather than imported so this module stays free of notation concerns and
 *   testable without the engine's notation tables.
 * @param window how many recent attempts each cell averages over.
 */
export function buildSkillIndex(
	history: SessionResult[],
	qualityOf: (chord: string) => string,
	window = SKILL_WINDOW,
): Map<string, SkillCell> {
	const buckets = new Map<string, Attempt[]>();

	for (const a of flatten(history, qualityOf)) {
		const key = cellKey(a.root, a.quality, a.voicing);
		const bucket = buckets.get(key);
		if (bucket) bucket.push(a);
		else buckets.set(key, [a]);
	}

	const index = new Map<string, SkillCell>();
	for (const [key, all] of buckets) {
		const recent = all.slice(0, window);
		const graded = recent.filter((a) => a.correct !== undefined);
		const first = recent[0];
		index.set(key, {
			root: first.root,
			quality: first.quality,
			voicing: first.voicing,
			avgMs: recent.reduce((s, a) => s + a.durationMs, 0) / recent.length,
			accuracy: graded.length
				? graded.filter((a) => a.correct === true).length / graded.length
				: null,
			attempts: recent.length,
			totalAttempts: all.length,
			lastPlayedAt: first.at,
		});
	}
	return index;
}

/** Every cell recorded for one key, across voicings and qualities. */
export function cellsForRoot(index: Map<string, SkillCell>, root: string): SkillCell[] {
	const want = canonicalRoot(root);
	return [...index.values()].filter((c) => c.root === want);
}

/**
 * How a key stands, judged by its WEAKEST voicing rather than an average.
 *
 * Averaging hid exactly what the player needs to see: three quick voicings and
 * one disastrous one came out "fluent". A key is only really yours when every
 * voicing you have unlocked is fluent, so that is what this reports.
 *
 * @param unlockedVoicings restricts the judgement to voicings the player has
 *   actually been taught. Omit to judge on everything recorded.
 */
export function rootStanding(
	index: Map<string, SkillCell>,
	root: string,
	thresholdMs: number,
	unlockedVoicings?: VoicingType[],
): {
	/** The slowest voicing's average — what the dial should show. */
	worstAvgMs: number | null;
	/** The voicing responsible for it. */
	worstVoicing: VoicingType | null;
	/** Per-voicing detail, slowest first — the hover breakdown. */
	perVoicing: { voicing: VoicingType; avgMs: number; accuracy: number | null }[];
	/** Fluent in EVERY unlocked voicing, not just on average. */
	mastered: boolean;
	attempts: number;
} {
	let cells = cellsForRoot(index, root);
	if (unlockedVoicings?.length) {
		cells = cells.filter((c) => unlockedVoicings.includes(c.voicing));
	}
	if (cells.length === 0) {
		return { worstAvgMs: null, worstVoicing: null, perVoicing: [], mastered: false, attempts: 0 };
	}

	// Collapse qualities within a voicing: the dial asks about the key, and the
	// per-quality split belongs to the weak-spot list.
	const byVoicing = new Map<VoicingType, { totalMs: number; n: number; correct: number; graded: number }>();
	for (const c of cells) {
		const cur = byVoicing.get(c.voicing) ?? { totalMs: 0, n: 0, correct: 0, graded: 0 };
		cur.totalMs += c.avgMs * c.attempts;
		cur.n += c.attempts;
		if (c.accuracy !== null) {
			cur.correct += c.accuracy * c.attempts;
			cur.graded += c.attempts;
		}
		byVoicing.set(c.voicing, cur);
	}

	const perVoicing = [...byVoicing.entries()]
		.map(([voicing, v]) => ({
			voicing,
			avgMs: v.totalMs / v.n,
			accuracy: v.graded > 0 ? v.correct / v.graded : null,
		}))
		.sort((a, b) => b.avgMs - a.avgMs); // slowest first

	const worst = perVoicing[0];
	const attempts = cells.reduce((s, c) => s + c.attempts, 0);

	// Mastery needs speed AND accuracy in every unlocked voicing. A chord played
	// fast but wrong is not mastered, however good the clock looks.
	const mastered = perVoicing.every(
		(v) => v.avgMs <= thresholdMs && (v.accuracy === null || v.accuracy >= 0.8),
	);

	return {
		worstAvgMs: worst.avgMs,
		worstVoicing: worst.voicing,
		perVoicing,
		mastered,
		attempts,
	};
}

/**
 * Cells that improved the most between the previous window and the latest
 * attempt — for the end-of-session "this got noticeably better" line.
 *
 * Returns newest-improvement-first, only where the gain is real (a cell needs a
 * prior window to compare against, and the gain must clear `minGainMs`).
 */
export function recentImprovements(
	before: Map<string, SkillCell>,
	after: Map<string, SkillCell>,
	minGainMs = 250,
): { cell: SkillCell; gainMs: number }[] {
	const out: { cell: SkillCell; gainMs: number }[] = [];
	for (const [key, now] of after) {
		const then = before.get(key);
		if (!then) continue; // brand new — no improvement to report yet
		const gainMs = then.avgMs - now.avgMs;
		if (gainMs >= minGainMs) out.push({ cell: now, gainMs });
	}
	return out.sort((a, b) => b.gainMs - a.gainMs);
}
