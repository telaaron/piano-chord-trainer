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
		tagline: 'Shell Voicings · ii-V-I · Alle Keys',
		description: 'Lockeres Einspielen: Die 3 wichtigsten Töne jedes Akkords (Shell) durch alle 12 Tonarten.',
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
		tagline: 'Grundstellung · Zufällig · Auf Zeit',
		description: 'Tempo-Training: 20 zufällige Akkorde so schnell wie möglich. Keine Noten-Hilfe — nur du und die Uhr.',
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
		tagline: 'Komplette Voicings · Alle 12 Keys',
		description: 'Die wichtigste Jazz-Progression (ii-V-I) mit allen 4 Tönen. Noten sind sichtbar — ideal zum Lernen.',
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
		tagline: 'I-vi-ii-V · Alle Keys · Shell',
		description: 'Die Akkordfolge aus "I Got Rhythm" und hunderten Jazz-Standards. 4 Akkorde × 12 Tonarten.',
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
		tagline: 'Erweiterte Akkorde · Ohne Hilfe',
		description: 'Für Fortgeschrittene: 30 schwierige Akkorde (9th, 13th, Alt) mit Symbol-Notation, ohne Noten-Anzeige.',
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
		tagline: '12 Tonarten · ♭-Vorzeichen · Half-Shell',
		description: 'Einmal rund durch alle Tonarten im Quartabstand (C→F→B♭→E♭→…). Trainiert flüssiges Wechseln.',
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
		description: 'Trainiere alle 4 Voicing-Arten nacheinander mit ii-V-I. Baut Muscle Memory für jeden Griff-Typ auf.',
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
		tagline: 'Rootless A · ii-V-I · Ohne Grundton',
		description: 'Linke-Hand-Voicings für Combo-Spiel: 3-5-7-9 ohne Grundton (den spielt der Bassist). Bill Evans-Stil.',
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
		name: 'Umkehrungen',
		tagline: '1./2./3. Umkehrung · Alle Keys',
		description: 'Spiele jeden Akkord in verschiedenen Umkehrungen. Trainiert fließende Stimmführung und Lagenwechsel.',
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
