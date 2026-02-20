// Adaptive Difficulty Engine — spaced-repetition-style weighted chord selection
// Pure TypeScript, no DOM, no side effects.

import type { ChordType } from './chords';
import type { ChordTiming } from '../services/progress';

// ─── Types ──────────────────────────────────────────────────

export interface ChordPerformance {
	/** Root note, e.g. "C" */
	root: string;
	/** Quality display, e.g. "Maj7" */
	quality: string;
	/** Average response time in ms */
	avgTime: number;
	/** Total attempts */
	attempts: number;
	/** Is the player getting faster, stable, or slower? */
	trend: 'improving' | 'stable' | 'declining';
}

export interface WeightedChord {
	/** Root note */
	root: string;
	/** Quality key (internal name like "maj7") */
	quality: string;
	/** Quality display name (like "Maj7") */
	display: string;
	/** Selection weight (higher = more likely to appear) */
	weight: number;
	/** Reason for weighting */
	reason: 'weak' | 'new' | 'normal' | 'strong';
}

// ─── Configuration ──────────────────────────────────────────

/** Weights for different performance categories */
const WEIGHT_WEAK = 4.0;        // Slow chords appear 4× more often
const WEIGHT_NEW = 2.5;         // Unseen chords get a boost
const WEIGHT_NORMAL = 1.0;      // Average chords
const WEIGHT_STRONG = 0.3;      // Fast chords appear less

/** Threshold: chords slower than median × factor are "weak" */
const WEAK_FACTOR = 1.4;
/** Threshold: chords faster than median × factor are "strong" */
const STRONG_FACTOR = 0.7;

// ─── Performance Analysis ───────────────────────────────────

/**
 * Aggregate per-chord timing history into performance profiles.
 */
export function analyzePerformance(history: ChordTiming[]): Map<string, ChordPerformance> {
	const grouped = new Map<string, { times: number[]; root: string; quality: string }>();

	for (const t of history) {
		// Extract quality from chord name: e.g. "DbMaj7" → root="Db", quality="Maj7"
		const key = `${t.root}-${extractQuality(t.chord, t.root)}`;
		const existing = grouped.get(key);
		if (existing) {
			existing.times.push(t.durationMs);
		} else {
			grouped.set(key, { times: [t.durationMs], root: t.root, quality: extractQuality(t.chord, t.root) });
		}
	}

	const result = new Map<string, ChordPerformance>();
	for (const [key, data] of grouped) {
		const avgTime = data.times.reduce((a, b) => a + b, 0) / data.times.length;
		const trend = computeTrend(data.times);
		result.set(key, {
			root: data.root,
			quality: data.quality,
			avgTime,
			attempts: data.times.length,
			trend,
		});
	}

	return result;
}

/**
 * Extract quality portion from a chord name.
 * "DbMaj7" with root "Db" → "Maj7"
 */
function extractQuality(chord: string, root: string): string {
	if (chord.startsWith(root)) {
		return chord.slice(root.length) || 'unknown';
	}
	return chord;
}

/**
 * Determine trend from a time series.
 * Compare the first half average vs second half average.
 */
function computeTrend(times: number[]): 'improving' | 'stable' | 'declining' {
	if (times.length < 4) return 'stable';
	const mid = Math.floor(times.length / 2);
	const firstHalf = times.slice(0, mid);
	const secondHalf = times.slice(mid);
	const avgFirst = firstHalf.reduce((a, b) => a + b, 0) / firstHalf.length;
	const avgSecond = secondHalf.reduce((a, b) => a + b, 0) / secondHalf.length;

	const ratio = avgSecond / avgFirst;
	if (ratio < 0.85) return 'improving';
	if (ratio > 1.15) return 'declining';
	return 'stable';
}

// ─── Weighted Selection ─────────────────────────────────────

/**
 * Generate a weighted chord pool based on performance history.
 *
 * - Weak chords (slow response) appear more frequently
 * - New/unseen chords are introduced gradually
 * - Strong chords (fast response) appear less often
 *
 * @param history All chord timing records from past sessions
 * @param pool Available chord types for the current difficulty
 * @param notePool Available root notes
 * @returns Weighted chord list for random selection
 */
export function getWeightedChordPool(
	history: ChordTiming[],
	pool: ChordType[],
	notePool: string[],
): WeightedChord[] {
	const performance = analyzePerformance(history);

	// Compute median time across all known chords
	const allTimes = [...performance.values()].map((p) => p.avgTime);
	const medianTime = allTimes.length > 0
		? allTimes.sort((a, b) => a - b)[Math.floor(allTimes.length / 2)]
		: 3000; // Default 3s if no history

	const weighted: WeightedChord[] = [];

	for (const chord of pool) {
		for (const root of notePool) {
			const key = `${root}-${chord.display}`;
			const perf = performance.get(key);

			let weight: number;
			let reason: WeightedChord['reason'];

			if (!perf) {
				// Never played this combination — treat as "new"
				weight = WEIGHT_NEW;
				reason = 'new';
			} else if (perf.avgTime > medianTime * WEAK_FACTOR) {
				// Slow — needs more practice
				weight = WEIGHT_WEAK;
				reason = 'weak';
				// Extra boost for declining trend
				if (perf.trend === 'declining') weight *= 1.3;
			} else if (perf.avgTime < medianTime * STRONG_FACTOR) {
				// Fast — reduce frequency
				weight = WEIGHT_STRONG;
				reason = 'strong';
			} else {
				weight = WEIGHT_NORMAL;
				reason = 'normal';
			}

			weighted.push({
				root,
				quality: chord.name,
				display: chord.display,
				weight,
				reason,
			});
		}
	}

	return weighted;
}

/**
 * Pick a chord from a weighted pool using weighted random selection.
 * Avoids repeating the last chord.
 */
export function pickWeightedChord(pool: WeightedChord[], lastRoot?: string, lastDisplay?: string): WeightedChord {
	// Filter out immediate repetition
	const candidates = pool.length > 1
		? pool.filter((c) => !(c.root === lastRoot && c.display === lastDisplay))
		: pool;

	const totalWeight = candidates.reduce((sum, c) => sum + c.weight, 0);
	let roll = Math.random() * totalWeight;

	for (const chord of candidates) {
		roll -= chord.weight;
		if (roll <= 0) return chord;
	}

	// Fallback (shouldn't happen)
	return candidates[candidates.length - 1];
}

/**
 * Get a summary of chord performance for display.
 * Returns the top N weakest and strongest chords.
 */
export function getPerformanceSummary(
	history: ChordTiming[],
	topN: number = 5,
): { weakest: ChordPerformance[]; strongest: ChordPerformance[] } {
	const perf = analyzePerformance(history);
	const all = [...perf.values()].filter((p) => p.attempts >= 2);

	const sorted = all.sort((a, b) => b.avgTime - a.avgTime);

	return {
		weakest: sorted.slice(0, topN),
		strongest: sorted.slice(-topN).reverse(),
	};
}
