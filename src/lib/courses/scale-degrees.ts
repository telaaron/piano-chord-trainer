// Scale-degrees (Stufentechnik) course — diatonic harmony & Roman numeral analysis
// Teaches chord function in major keys: I–vii°, then common jazz progressions

import type { Course } from '$lib/engine/courses';

const ALL_KEYS = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
const EASY_KEYS = ['C', 'F', 'Bb', 'Eb'];
const MEDIUM_KEYS = ['C', 'F', 'Bb', 'Eb', 'Ab', 'G', 'D'];

export const scaleDegreesCourse: Course = {
	id: 'scale-degrees',
	titleKey: 'course.degrees.title',
	descriptionKey: 'course.degrees.description',
	subtitleKey: 'course.degrees.subtitle',
	icon: 'Ⅱ',
	level: 'intermediate',
	modules: [
		// ── Module 1: Die Tonika-Familie ─────────────────────────────
		{
			id: 'tonic-family',
			titleKey: 'course.degrees.mod1.title',
			lessons: [
				{
					id: 'I-maj7',
					titleKey: 'course.degrees.I_maj7.title',
					subtitleKey: 'course.degrees.I_maj7.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.degrees.I_maj7.theory',
							exampleChord: { root: 'C', quality: 'maj7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((r) => ({ root: r, quality: 'maj7' as const, voicing: 'shell' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'maj7',
							keys: MEDIUM_KEYS,
							masteryThresholdMs: 3500,
						},
					],
				},
				{
					id: 'vi-m7',
					titleKey: 'course.degrees.vi_m7.title',
					subtitleKey: 'course.degrees.vi_m7.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.degrees.vi_m7.theory',
							exampleChord: { root: 'A', quality: 'm7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((r) => ({ root: r, quality: 'm7' as const, voicing: 'shell' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'm7',
							keys: MEDIUM_KEYS,
							masteryThresholdMs: 3500,
						},
					],
				},
				{
					id: 'iii-m7',
					titleKey: 'course.degrees.iii_m7.title',
					subtitleKey: 'course.degrees.iii_m7.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.degrees.iii_m7.theory',
							exampleChord: { root: 'E', quality: 'm7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((r) => ({ root: r, quality: 'm7' as const, voicing: 'shell' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'm7',
							keys: MEDIUM_KEYS,
							masteryThresholdMs: 3500,
						},
					],
				},
			],
		},
		// ── Module 2: Die Subdominante ───────────────────────────────
		{
			id: 'subdominant-family',
			titleKey: 'course.degrees.mod2.title',
			lessons: [
				{
					id: 'IV-maj7',
					titleKey: 'course.degrees.IV_maj7.title',
					subtitleKey: 'course.degrees.IV_maj7.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.degrees.IV_maj7.theory',
							exampleChord: { root: 'F', quality: 'maj7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((r) => ({ root: r, quality: 'maj7' as const, voicing: 'shell' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'maj7',
							keys: MEDIUM_KEYS,
							masteryThresholdMs: 3500,
						},
					],
				},
				{
					id: 'ii-m7',
					titleKey: 'course.degrees.ii_m7.title',
					subtitleKey: 'course.degrees.ii_m7.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.degrees.ii_m7.theory',
							exampleChord: { root: 'D', quality: 'm7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((r) => ({ root: r, quality: 'm7' as const, voicing: 'shell' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'm7',
							keys: MEDIUM_KEYS,
							masteryThresholdMs: 3500,
						},
					],
				},
			],
		},
		// ── Module 3: Die Dominante ──────────────────────────────────
		{
			id: 'dominant-family',
			titleKey: 'course.degrees.mod3.title',
			lessons: [
				{
					id: 'V-7',
					titleKey: 'course.degrees.V_7.title',
					subtitleKey: 'course.degrees.V_7.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.degrees.V_7.theory',
							exampleChord: { root: 'G', quality: '7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((r) => ({ root: r, quality: '7' as const, voicing: 'shell' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: '7',
							keys: MEDIUM_KEYS,
							masteryThresholdMs: 3500,
						},
					],
				},
				{
					id: 'vii-m7b5',
					titleKey: 'course.degrees.vii_m7b5.title',
					subtitleKey: 'course.degrees.vii_m7b5.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.degrees.vii_m7b5.theory',
							exampleChord: { root: 'B', quality: 'm7b5', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((r) => ({ root: r, quality: 'm7b5' as const, voicing: 'shell' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'm7b5',
							keys: MEDIUM_KEYS,
							masteryThresholdMs: 4000,
						},
					],
				},
			],
		},
		// ── Module 4: Verbindungen — ii-V-I & Turnaround ────────────
		{
			id: 'progressions',
			titleKey: 'course.degrees.mod4.title',
			lessons: [
				{
					id: 'ii-V-I',
					titleKey: 'course.degrees.iiVI.title',
					subtitleKey: 'course.degrees.iiVI.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.degrees.iiVI.theory',
							exampleChord: { root: 'D', quality: 'm7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: [
								...EASY_KEYS.map((r) => ({ root: r, quality: 'm7' as const, voicing: 'shell' as const })),
								...EASY_KEYS.map((r) => ({ root: r, quality: '7' as const, voicing: 'shell' as const })),
								...EASY_KEYS.map((r) => ({ root: r, quality: 'maj7' as const, voicing: 'shell' as const })),
							],
							guidedCount: 4,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'm7',
							keys: ALL_KEYS,
							masteryThresholdMs: 3500,
						},
					],
				},
				{
					id: 'turnaround',
					titleKey: 'course.degrees.turnaround.title',
					subtitleKey: 'course.degrees.turnaround.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.degrees.turnaround.theory',
							exampleChord: { root: 'C', quality: 'maj7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: [
								...EASY_KEYS.map((r) => ({ root: r, quality: 'maj7' as const, voicing: 'shell' as const })),
								...EASY_KEYS.map((r) => ({ root: r, quality: 'm7' as const, voicing: 'shell' as const })),
								...EASY_KEYS.map((r) => ({ root: r, quality: '7' as const, voicing: 'shell' as const })),
							],
							guidedCount: 4,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'maj7',
							keys: ALL_KEYS,
							masteryThresholdMs: 3500,
						},
					],
				},
			],
		},
	],
};
