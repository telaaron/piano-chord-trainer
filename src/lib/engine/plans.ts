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
		tagline: 'Shell Voicings · ii-V-I',
		description: 'Einspielen mit Shell Voicings durch alle 12 Tonarten. Perfekt zum Ankommen.',
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
		description: 'So schnell wie möglich! 20 zufällige Akkorde in Root Position. Schlag deine Bestzeit.',
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
		tagline: 'Full Voicings · Alle Keys',
		description: 'Die Jazz-Standardprogression in allen 12 Tonarten mit Full Voicings. Der Kern-Skill.',
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
		tagline: 'I-vi-ii-V · Shell Voicings',
		description: 'Der klassische Jazz-Turnaround in allen 12 Keys. Essentiell für Standards.',
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
		tagline: 'Advanced · Noten aus · 30 Akkorde',
		description: 'Für Fortgeschrittene: Erweitertes Akkord-Vokabular ohne Hilfe. Kennst du alle?',
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
		name: 'Quartenzirkel',
		tagline: 'Alle 12 Keys · Half-Shell',
		description: 'Chromatisch durch alle Tonarten mit Half-Shell Voicings. Fluid um den Circle of 4ths.',
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
