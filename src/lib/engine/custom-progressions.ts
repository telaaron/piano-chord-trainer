// Custom Progressions — parse user input, store/load, provide presets

import { CHORD_INTERVALS, CHORD_NOTATIONS, type NotationStyle } from './chords';
import { noteToSemitone, type AccidentalPreference } from './notes';

// ─── Types ──────────────────────────────────────────────────

export interface CustomChord {
	/** Display text as entered, e.g. "Dm7" */
	display: string;
	/** Root note, e.g. "D" */
	root: string;
	/** Internal quality key, e.g. "m7" */
	quality: string;
	/** How many beats this chord lasts (default 4) */
	beats: number;
}

export interface CustomProgression {
	id: string;
	name: string;
	/** User-entered chord string, e.g. "Dm7 | G7 | CMaj7" */
	raw: string;
	chords: CustomChord[];
	/** BPM for playback */
	bpm: number;
	/** How many times the progression loops (0 = infinite until user stops) */
	loops: number;
	/** Creation timestamp */
	createdAt: number;
}

export interface LoopEvaluation {
	/** Per-chord results for this loop pass */
	chords: ChordEval[];
	/** Overall accuracy (0–1) for this pass */
	accuracy: number;
}

export interface ChordEval {
	/** The chord that was expected */
	chord: CustomChord;
	/** Was the correct chord played at some point during this chord's window? */
	hit: boolean;
	/** Timing offset in ms from the downbeat (negative = early, positive = late) */
	timingOffsetMs: number;
	/** Best accuracy achieved (0–1) during the window */
	bestAccuracy: number;
}

export interface SessionEvaluation {
	/** Results per loop pass */
	loops: LoopEvaluation[];
	/** Overall hit rate */
	overallAccuracy: number;
	/** Average absolute timing offset */
	avgTimingMs: number;
	/** Chords that were consistently missed */
	weakChords: string[];
	/** Total elapsed ms */
	totalMs: number;
}

// ─── Chord Parsing ──────────────────────────────────────────

/**
 * All quality labels we recognize — longest first so "Maj7#11" matches before "Maj7".
 * Built from CHORD_NOTATIONS + some common aliases.
 */
function buildQualityMap(): Map<string, string> {
	const map = new Map<string, string>();
	// Add all notation variants (longest match first)
	for (const style of Object.keys(CHORD_NOTATIONS) as NotationStyle[]) {
		for (const [internal, display] of Object.entries(CHORD_NOTATIONS[style])) {
			map.set(display, internal);
		}
	}
	// Common aliases people might type
	map.set('Δ7', 'Maj7');
	map.set('Δ9', 'Maj9');
	map.set('-7', 'm7');
	map.set('-9', 'm9');
	map.set('-11', 'm11');
	map.set('ø7', 'm7b5');
	map.set('ø', 'm7b5');
	map.set('dim7', 'dim7');
	map.set('dim', 'dim7');
	map.set('o7', 'dim7');
	map.set('maj7', 'Maj7');
	map.set('maj9', 'Maj9');
	map.set('min7', 'm7');
	map.set('min9', 'm9');
	map.set('M7', 'Maj7');
	map.set('M9', 'Maj9');
	map.set('mi7', 'm7');
	map.set('mi9', 'm9');
	return map;
}

const qualityMap = buildQualityMap();
/** Quality strings sorted longest-first for greedy matching */
const qualityKeys = [...qualityMap.keys()].sort((a, b) => b.length - a.length);

/**
 * Parse a single chord symbol like "Dm7", "BbMaj7", "F#7#9".
 * Returns null if unrecognized.
 */
export function parseChordSymbol(input: string): { root: string; quality: string; display: string } | null {
	const trimmed = input.trim();
	if (!trimmed) return null;

	// Extract root: A-G followed by optional # or b
	const rootMatch = trimmed.match(/^([A-G][#b♯♭]?)/);
	if (!rootMatch) return null;

	let root = rootMatch[1].replace('♯', '#').replace('♭', 'b');
	const rest = trimmed.slice(rootMatch[0].length);

	// If nothing follows, it's probably a major triad — not in our system
	if (!rest) return null;

	// Try to match quality from longest to shortest
	// First pass: exact match only (preserves case sensitivity: M7≠m7)
	for (const key of qualityKeys) {
		if (rest === key) {
			const quality = qualityMap.get(key)!;
			if (CHORD_INTERVALS[quality]) {
				return { root, quality, display: trimmed };
			}
		}
	}
	// Second pass: case-insensitive fallback for user convenience
	for (const key of qualityKeys) {
		if (rest.toLowerCase() === key.toLowerCase()) {
			const quality = qualityMap.get(key)!;
			// Verify we have intervals for this quality
			if (CHORD_INTERVALS[quality]) {
				return { root, quality, display: trimmed };
			}
		}
	}

	// Direct lookup in CHORD_INTERVALS (user typed internal key like "Maj7")
	if (CHORD_INTERVALS[rest]) {
		return { root, quality: rest, display: trimmed };
	}

	return null;
}

/**
 * Parse a full progression string.
 * Accepts: "Dm7 | G7 | CMaj7" or "Dm7 - G7 - CMaj7" or "Dm7 G7 CMaj7"
 * Also accepts beat annotations: "Dm7(2) | G7(2) | CMaj7(4)"
 */
export function parseProgression(input: string): CustomChord[] {
	// Normalize separators: | or – or - or , → consistent delimiter
	const normalized = input
		.replace(/[|–\-,]/g, ' ')
		.replace(/\s+/g, ' ')
		.trim();

	if (!normalized) return [];

	const tokens = normalized.split(' ').filter(Boolean);
	const chords: CustomChord[] = [];

	for (const token of tokens) {
		// Check for beat annotation: "Dm7(2)"
		const beatMatch = token.match(/^(.+)\((\d+)\)$/);
		const chordStr = beatMatch ? beatMatch[1] : token;
		const beats = beatMatch ? parseInt(beatMatch[2], 10) : 4;

		const parsed = parseChordSymbol(chordStr);
		if (parsed) {
			chords.push({
				display: parsed.display,
				root: parsed.root,
				quality: parsed.quality,
				beats,
			});
		}
	}

	return chords;
}

/**
 * Format a progression back into a display string.
 */
export function formatProgression(chords: CustomChord[]): string {
	return chords.map((c) => {
		if (c.beats !== 4) return `${c.display}(${c.beats})`;
		return c.display;
	}).join(' | ');
}

// ─── Preset Progressions ────────────────────────────────────

export interface ProgressionPreset {
	name: string;
	/** Genre/source */
	tag: string;
	raw: string;
	bpm: number;
}

export const PROGRESSION_PRESETS: ProgressionPreset[] = [
	{
		name: 'Autumn Leaves (A-Teil)',
		tag: 'Jazz Standard',
		raw: 'Cm7 | F7 | BbMaj7 | EbMaj7 | Am7b5 | D7 | Gm7 | Gm7',
		bpm: 140,
	},
	{
		name: 'All of Me (A-Teil)',
		tag: 'Jazz Standard',
		raw: 'CMaj7 | CMaj7 | E7 | E7 | A7 | A7 | Dm7 | Dm7',
		bpm: 130,
	},
	{
		name: 'Blue Bossa',
		tag: 'Latin Jazz',
		raw: 'Cm7 | Cm7 | Fm7 | Fm7 | Dm7b5 | G7 | Cm7 | Cm7',
		bpm: 140,
	},
	{
		name: 'Rhythm Changes (A)',
		tag: 'Bebop',
		raw: 'BbMaj7 | Gm7 | Cm7 | F7 | Dm7 | Gm7 | Cm7 | F7',
		bpm: 160,
	},
	{
		name: '12-Bar Blues',
		tag: 'Blues',
		raw: 'C7 | C7 | C7 | C7 | F7 | F7 | C7 | C7 | G7 | F7 | C7 | G7',
		bpm: 120,
	},
	{
		name: 'So What',
		tag: 'Modal Jazz',
		raw: 'Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Ebm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7 | Dm7',
		bpm: 136,
	},
	{
		name: 'Satin Doll (A)',
		tag: 'Swing',
		raw: 'Dm7 | G7 | Em7 | A7 | Am7 | D7 | AbMaj7 | DbMaj7',
		bpm: 120,
	},
];

// ─── Storage ────────────────────────────────────────────────

const STORAGE_KEY = 'chord-trainer-custom-progressions';
const MAX_SAVED = 50;

function generateId(): string {
	return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

export function loadCustomProgressions(): CustomProgression[] {
	if (typeof localStorage === 'undefined') return [];
	try {
		const raw = localStorage.getItem(STORAGE_KEY);
		return raw ? JSON.parse(raw) : [];
	} catch {
		return [];
	}
}

export function saveCustomProgression(prog: Omit<CustomProgression, 'id' | 'createdAt'>): CustomProgression {
	const full: CustomProgression = {
		...prog,
		id: generateId(),
		createdAt: Date.now(),
	};
	const all = loadCustomProgressions();
	all.unshift(full);
	if (all.length > MAX_SAVED) all.length = MAX_SAVED;
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(all));
	}
	return full;
}

export function deleteCustomProgression(id: string): void {
	const all = loadCustomProgressions().filter((p) => p.id !== id);
	if (typeof localStorage !== 'undefined') {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(all));
	}
}

// ─── Evaluation ─────────────────────────────────────────────

/**
 * Given an array of per-chord evaluations from one or more loop passes,
 * compute the overall session evaluation.
 */
export function evaluateSession(loops: LoopEvaluation[], totalMs: number): SessionEvaluation {
	const allChordEvals = loops.flatMap((l) => l.chords);
	const hitCount = allChordEvals.filter((e) => e.hit).length;
	const totalCount = allChordEvals.length;
	const avgTiming = totalCount > 0
		? allChordEvals.reduce((sum, e) => sum + Math.abs(e.timingOffsetMs), 0) / totalCount
		: 0;

	// Track miss count per chord display
	const missCounts = new Map<string, number>();
	for (const e of allChordEvals) {
		if (!e.hit) {
			missCounts.set(e.chord.display, (missCounts.get(e.chord.display) ?? 0) + 1);
		}
	}

	// Weak = missed more than half the time
	const loopCount = loops.length || 1;
	const weakChords = [...missCounts.entries()]
		.filter(([, count]) => count > loopCount / 2)
		.map(([chord]) => chord);

	return {
		loops,
		overallAccuracy: totalCount > 0 ? hitCount / totalCount : 0,
		avgTimingMs: Math.round(avgTiming),
		weakChords,
		totalMs,
	};
}
