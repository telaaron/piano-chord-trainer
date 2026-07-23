// Practice Plans — curated presets that guide the player
// Instead of 10 settings dimensions, one tap starts a focused session.

import type {
	Difficulty,
	NotationStyle,
	VoicingType,
	DisplayMode,
	AccidentalPreference,
	ProgressionMode,
	VoiceLeadingMode,
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
	/** Overall plan difficulty / user level */
	level: 'beginner' | 'intermediate' | 'advanced';
	settings: {
		difficulty: Difficulty;
		notation: NotationStyle;
		voicing: VoicingType;
		displayMode: DisplayMode;
		accidentals: AccidentalPreference;
		progressionMode: ProgressionMode;
		totalChords: number;
		/** Voice leading sub-mode (only set on VL plans) */
		vlMode?: VoiceLeadingMode;
	};
}

export const PRACTICE_PLANS: PracticePlan[] = [
	{
		id: 'warmup',
		name: 'plans.warmup_name',
		tagline: 'plans.warmup_tagline',
		description: 'plans.warmup_desc',
		icon: '',
		accent: 'var(--accent-amber)',
		level: 'beginner',
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
		name: 'plans.speed_name',
		tagline: 'plans.speed_tagline',
		description: 'plans.speed_desc',
		icon: '',
		accent: 'var(--accent-red)',
		level: 'beginner',
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
		name: 'plans.deepdive_name',
		tagline: 'plans.deepdive_tagline',
		description: 'plans.deepdive_desc',
		icon: '',
		accent: 'var(--primary)',
		level: 'intermediate',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'full',
			displayMode: 'verify',
			accidentals: 'both',
			progressionMode: '1-6-2-5',
			totalChords: 48,
		},
	},
	{
		id: 'turnaround',
		name: 'plans.turnaround_name',
		tagline: 'plans.turnaround_tagline',
		description: 'plans.turnaround_desc',
		icon: '',
		accent: 'var(--accent-purple)',
		level: 'intermediate',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'shell',
			displayMode: 'verify',
			accidentals: 'both',
			progressionMode: '1-6-2-5',
			totalChords: 48,
		},
	},
	{
		id: 'challenge',
		name: 'plans.challenge_name',
		tagline: 'plans.challenge_tagline',
		description: 'plans.challenge_desc',
		icon: '',
		accent: 'var(--accent-green)',
		level: 'advanced',
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
		name: 'plans.quartenzirkel_name',
		tagline: 'plans.quartenzirkel_tagline',
		description: 'plans.quartenzirkel_desc',
		icon: '',
		accent: 'var(--accent-amber)',
		level: 'intermediate',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'half-shell',
			displayMode: 'verify',
			accidentals: 'flats',
			progressionMode: 'cycle-of-4ths',
			totalChords: 12,
		},
	},
	{
		id: 'voicing-drill',
		name: 'plans.voicing_drill_name',
		tagline: 'plans.voicing_drill_tagline',
		description: 'plans.voicing_drill_desc',
		icon: '',
		accent: 'var(--primary)',
		level: 'intermediate',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'root',
			displayMode: 'verify',
			accidentals: 'both',
			progressionMode: '3-6-2-5',
			totalChords: 48,
		},
	},
	{
		id: 'left-hand-comping',
		name: 'plans.left_hand_comping_name',
		tagline: 'plans.left_hand_comping_tagline',
		description: 'plans.left_hand_comping_desc',
		icon: '',
		accent: 'var(--accent-amber)',
		level: 'advanced',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'rootless-a',
			displayMode: 'verify',
			accidentals: 'both',
			progressionMode: 'cycle-of-4ths',
			totalChords: 48,
		},
	},
	{
		id: 'inversions-drill',
		name: 'plans.inversions_drill_name',
		tagline: 'plans.inversions_drill_tagline',
		description: 'plans.inversions_drill_desc',
		icon: '',
		accent: 'var(--accent-purple)',
		level: 'advanced',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'inversion-1',
			displayMode: 'verify',
			accidentals: 'both',
			progressionMode: '1-4-5',
			totalChords: 36,
		},
	},
	{
		id: 'in-time-comping',
		name: 'plans.in_time_comping_name',
		tagline: 'plans.in_time_comping_tagline',
		description: 'plans.in_time_comping_desc',
		icon: '',
		accent: 'var(--accent-green)',
		level: 'intermediate',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'shell',
			displayMode: 'always',
			accidentals: 'both',
			progressionMode: '3-6-2-5',
			totalChords: 48,
		},
	},
	{
		id: 'ear-check',
		name: 'plans.ear_check_name',
		tagline: 'plans.ear_check_tagline',
		description: 'plans.ear_check_desc',
		icon: '',
		accent: 'var(--accent-amber)',
		level: 'intermediate',
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: 'root',
			displayMode: 'off',
			accidentals: 'both',
			progressionMode: 'random',
			totalChords: 12,
		},
	},
	{
		id: 'adaptive-drill',
		name: 'plans.adaptive_drill_name',
		tagline: 'plans.adaptive_drill_tagline',
		description: 'plans.adaptive_drill_desc',
		icon: '',
		accent: 'var(--accent-purple)',
		level: 'intermediate',
		settings: {
			difficulty: 'intermediate',
			notation: 'standard',
			voicing: 'shell',
			displayMode: 'verify',
			accidentals: 'both',
			progressionMode: 'random',
			totalChords: 20,
		},
	},
	{
		id: 'voice-leading-flow',
		name: 'plans.voice_leading_flow_name',
		tagline: 'plans.voice_leading_flow_tagline',
		description: 'plans.voice_leading_flow_desc',
		icon: '',
		accent: 'var(--primary)',
		level: 'intermediate',
		settings: {
			difficulty: 'intermediate',
			notation: 'standard',
			voicing: 'shell',
			displayMode: 'always',
			accidentals: 'both',
			progressionMode: 'diatonic',
			totalChords: 84,
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
	// Difficulty tier grows with experience — never throw an advanced plan at a newbie.
	const maxLevel: PracticePlan['level'] =
		totalSessions < 6 ? 'beginner' : totalSessions < 20 ? 'intermediate' : 'advanced';
	const levelRank = { beginner: 0, intermediate: 1, advanced: 2 } as const;
	const eligible = PRACTICE_PLANS.filter((p) => levelRank[p.level] <= levelRank[maxLevel]);
	const pool = eligible.length > 0 ? eligible : PRACTICE_PLANS;

	if (totalSessions === 0) {
		// First-ever: the gentlest entry point.
		return pool.find((p) => p.id === 'warmup') ?? pool[0];
	}

	// Prefer something they haven't drilled recently, within their tier.
	const unused = pool.filter((p) => !recentPlanIds.includes(p.id));
	if (unused.length > 0) return unused[0];

	// All used recently → rotate within tier.
	return pool[totalSessions % pool.length];
}
