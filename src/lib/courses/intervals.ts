// Intervals course — learn to recognize and play musical intervals
// Teaches intervals through chord construction: from 2nds to 13ths

import type { Course } from '$lib/engine/courses';

const ALL_KEYS = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
const EASY_KEYS = ['C', 'F', 'Bb', 'Eb'];

export const intervalsCourse: Course = {
	id: 'intervals',
	titleKey: 'course.intervals.title',
	descriptionKey: 'course.intervals.description',
	subtitleKey: 'course.intervals.subtitle',
	icon: '📏',
	level: 'beginner',
	modules: [
		// ── Module 1: Sekunden & Terzen ──────────────────────────────
		{
			id: 'seconds-thirds',
			titleKey: 'course.intervals.mod1.title',
			lessons: [
				{
					id: 'major-minor-3rd',
					titleKey: 'course.intervals.major_minor_3rd.title',
					subtitleKey: 'course.intervals.major_minor_3rd.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.intervals.major_minor_3rd.theory',
							exampleChord: { root: 'C', quality: 'maj7', voicing: 'root' },
						},
						{
							type: 'practice',
							chordPool: [
								...EASY_KEYS.map((root) => ({ root, quality: 'maj7' as const, voicing: 'root' as const })),
								...EASY_KEYS.map((root) => ({ root, quality: 'm7' as const, voicing: 'root' as const })),
							],
							guidedCount: 4,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: 'maj7',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
						},
					],
				},
				{
					id: 'tritone',
					titleKey: 'course.intervals.tritone.title',
					subtitleKey: 'course.intervals.tritone.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.intervals.tritone.theory',
							exampleChord: { root: 'C', quality: '7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((root) => ({ root, quality: '7' as const, voicing: 'shell' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: '7',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
						},
					],
				},
			],
		},
		// ── Module 2: Quinten & Sexten ───────────────────────────────
		{
			id: 'fifths-sixths',
			titleKey: 'course.intervals.mod2.title',
			lessons: [
				{
					id: 'perfect-5th',
					titleKey: 'course.intervals.perfect_5th.title',
					subtitleKey: 'course.intervals.perfect_5th.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.intervals.perfect_5th.theory',
							exampleChord: { root: 'C', quality: 'maj7', voicing: 'root' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((root) => ({ root, quality: 'maj7' as const, voicing: 'root' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: 'maj7',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
						},
					],
				},
				{
					id: 'dim5-aug5',
					titleKey: 'course.intervals.dim5_aug5.title',
					subtitleKey: 'course.intervals.dim5_aug5.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.intervals.dim5_aug5.theory',
							exampleChord: { root: 'B', quality: 'm7b5', voicing: 'root' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((root) => ({ root, quality: 'm7b5' as const, voicing: 'root' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: 'm7b5',
							keys: ALL_KEYS,
							masteryThresholdMs: 4500,
						},
					],
				},
				{
					id: 'major-6th',
					titleKey: 'course.intervals.major_6th.title',
					subtitleKey: 'course.intervals.major_6th.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.intervals.major_6th.theory',
							exampleChord: { root: 'C', quality: '6', voicing: 'root' },
						},
						{
							type: 'practice',
							chordPool: [
								...EASY_KEYS.map((root) => ({ root, quality: '6' as const, voicing: 'root' as const })),
								...EASY_KEYS.map((root) => ({ root, quality: 'm6' as const, voicing: 'root' as const })),
							],
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: '6',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
						},
					],
				},
			],
		},
		// ── Module 3: Septimen ───────────────────────────────────────
		{
			id: 'sevenths',
			titleKey: 'course.intervals.mod3.title',
			lessons: [
				{
					id: 'minor-7th',
					titleKey: 'course.intervals.minor_7th.title',
					subtitleKey: 'course.intervals.minor_7th.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.intervals.minor_7th.theory',
							exampleChord: { root: 'C', quality: '7', voicing: 'root' },
						},
						{
							type: 'practice',
							chordPool: [
								...EASY_KEYS.map((root) => ({ root, quality: '7' as const, voicing: 'root' as const })),
								...EASY_KEYS.map((root) => ({ root, quality: 'm7' as const, voicing: 'root' as const })),
							],
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: '7',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
						},
					],
				},
				{
					id: 'major-7th',
					titleKey: 'course.intervals.major_7th.title',
					subtitleKey: 'course.intervals.major_7th.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.intervals.major_7th.theory',
							exampleChord: { root: 'C', quality: 'maj7', voicing: 'root' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((root) => ({ root, quality: 'maj7' as const, voicing: 'root' as const })),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: 'maj7',
							keys: ALL_KEYS,
							masteryThresholdMs: 3500,
						},
					],
				},
			],
		},
		// ── Module 4: Erweiterte Intervalle ──────────────────────────
		{
			id: 'extended',
			titleKey: 'course.intervals.mod4.title',
			lessons: [
				{
					id: 'ninths',
					titleKey: 'course.intervals.ninths.title',
					subtitleKey: 'course.intervals.ninths.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.intervals.ninths.theory',
							exampleChord: { root: 'C', quality: 'Maj9', voicing: 'root' },
						},
						{
							type: 'practice',
							chordPool: [
								...EASY_KEYS.map((root) => ({ root, quality: 'Maj9' as const, voicing: 'root' as const })),
								...EASY_KEYS.map((root) => ({ root, quality: '9' as const, voicing: 'root' as const })),
							],
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: '9',
							keys: ALL_KEYS,
							masteryThresholdMs: 4500,
						},
					],
				},
				{
					id: 'elevenths-thirteenths',
					titleKey: 'course.intervals.elevenths.title',
					subtitleKey: 'course.intervals.elevenths.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.intervals.elevenths.theory',
							exampleChord: { root: 'C', quality: '13', voicing: 'root' },
						},
						{
							type: 'practice',
							chordPool: [
								...EASY_KEYS.map((root) => ({ root, quality: 'm11' as const, voicing: 'root' as const })),
								...EASY_KEYS.map((root) => ({ root, quality: '13' as const, voicing: 'root' as const })),
							],
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: '13',
							keys: ALL_KEYS,
							masteryThresholdMs: 4500,
						},
					],
				},
			],
		},
	],
};
