// Practice Plans — curated presets that guide the player
// Instead of 10 settings dimensions, one tap starts a focused session.

import type {
	Difficulty,
	NotationStyle,
	VoicingType,
	DisplayMode,
	AccidentalPreference,
	ProgressionMode,
} from '$lib/engine';

export interface PracticePlan {
	id: string;
	name: string;
	/** Short tagline (shown on card) */
	tagline: string;
	/** Longer description (shown in detail) */
	description: string;
	icon: string;
	/** Color accent class */
	accent: string;
	settings: {
		difficulty: Difficulty;
		notation: NotationStyle;
		voicing: VoicingType;
		displayMode: DisplayMode;
		accidentals: AccidentalPreference;
		progressionMode: ProgressionMode;
		totalChords: number;
	};
}

export const PRACTICE_PLANS: PracticePlan[] = [
	{
		id: 'warmup',
		name: 'Warm-Up',
		tagline: 'Shell Voicings · ii-V-I · All Keys',
		description: 'Easy warm-up: The 3 essential notes of each chord (Shell) through all 12 keys.',
		icon: '☀️',
		accent: 'var(--accent-amber)',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'shell',
			displayMode: 'always',
			accidentals: 'both',
			progressionMode: '2-5-1',
			totalChords: 36,
		},
	},
	{
		id: 'speed',
		name: 'Speed Run',
		tagline: 'Root Position · Random · Timed',
		description: 'Speed training: 20 random chords as fast as possible. No note hints — just you and the clock.',
		icon: '⚡',
		accent: 'var(--accent-red)',
		settings: {
			difficulty: 'intermediate',
			notation: 'standard',
			voicing: 'root',
			displayMode: 'off',
			accidentals: 'both',
			progressionMode: 'random',
			totalChords: 20,
		},
	},
	{
		id: 'deepdive',
		name: 'ii-V-I Deep Dive',
		tagline: 'Full Voicings · All 12 Keys',
		description: 'The most important jazz progression (ii-V-I) with all 4 notes. Notes visible — ideal for learning.',
		icon: '🎯',
		accent: 'var(--primary)',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'full',
			displayMode: 'always',
			accidentals: 'both',
			progressionMode: '2-5-1',
			totalChords: 36,
		},
	},
	{
		id: 'turnaround',
		name: 'Turnaround',
		tagline: 'I-vi-ii-V · All Keys · Shell',
		description: 'The chord sequence from "I Got Rhythm" and hundreds of jazz standards. 4 chords × 12 keys.',
		icon: '🔄',
		accent: 'var(--accent-purple)',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'shell',
			displayMode: 'always',
			accidentals: 'both',
			progressionMode: '1-6-2-5',
			totalChords: 48,
		},
	},
	{
		id: 'challenge',
		name: 'Challenge',
		tagline: 'Extended Chords · No Hints',
		description: 'For advanced players: 30 complex chords (9th, 13th, Alt) with symbol notation, no note display.',
		icon: '🏆',
		accent: 'var(--accent-green)',
		settings: {
			difficulty: 'advanced',
			notation: 'symbols',
			voicing: 'shell',
			displayMode: 'off',
			accidentals: 'both',
			progressionMode: 'random',
			totalChords: 30,
		},
	},
	{
		id: 'quartenzirkel',
		name: 'Cycle of 4ths',
		tagline: '12 Keys · ♭ Accidentals · Half-Shell',
		description: 'Once around all keys in intervals of a fourth (C→F→B♭→E♭→…). Trains smooth key changes.',
		icon: '🌀',
		accent: 'var(--accent-amber)',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'half-shell',
			displayMode: 'always',
			accidentals: 'flats',
			progressionMode: 'cycle-of-4ths',
			totalChords: 12,
		},
	},
	{
		id: 'voicing-drill',
		name: 'Voicing Drill',
		tagline: 'Root → Shell → Half → Full',
		description: 'Practice all 4 voicing types in sequence with ii-V-I. Builds muscle memory for each voicing style.',
		icon: '🖐️',
		accent: 'var(--primary)',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'root', // Will be cycled through in a future iteration
			displayMode: 'always',
			accidentals: 'both',
			progressionMode: '2-5-1',
			totalChords: 36,
		},
	},
	{
		id: 'left-hand-comping',
		name: 'Left-Hand Comping',
		tagline: 'Rootless A · ii-V-I · No Root',
		description: 'Left-hand voicings for combo playing: 3-5-7-9 without root (played by the bassist). Bill Evans style.',
		icon: '🤚',
		accent: 'var(--accent-amber)',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'rootless-a',
			displayMode: 'always',
			accidentals: 'both',
			progressionMode: '2-5-1',
			totalChords: 36,
		},
	},
	{
		id: 'inversions-drill',
		name: 'Inversions',
		tagline: '1st/2nd/3rd Inversion · All Keys',
		description: 'Play each chord in different inversions. Trains smooth voice leading and position changes.',
		icon: '🔃',
		accent: 'var(--accent-purple)',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'inversion-1',
			displayMode: 'always',
			accidentals: 'both',
			progressionMode: '2-5-1',
			totalChords: 36,
		},
	},
];

/**
 * Suggest a plan based on session history.
 * Logic:
 * - No history → Warm-Up
 * - < 5 sessions → Deep Dive (build fundamentals)
 * - Returning player (streak active) → Speed Run (push yourself)
 * - Default → rotate through plans player hasn't done recently
 */
export function suggestPlan(recentPlanIds: string[], totalSessions: number): PracticePlan {
	if (totalSessions === 0) return PRACTICE_PLANS[0]; // Warm-Up
	if (totalSessions < 5) return PRACTICE_PLANS[2]; // Deep Dive

	// Find a plan not used recently
	const unused = PRACTICE_PLANS.filter((p) => !recentPlanIds.includes(p.id));
	if (unused.length > 0) return unused[0];

	// All used recently → rotate
	return PRACTICE_PLANS[totalSessions % PRACTICE_PLANS.length];
}
