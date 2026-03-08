// Intervals course — learn to recognize and play musical intervals
// Pure interval training: theory shows 2 notes, practice/challenge drills intervals across keys

import type { Course, IntervalSpec } from '$lib/engine/courses';
import { noteToSemitone, getNoteName } from '$lib/engine/notes';

const ALL_KEYS = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
const EASY_KEYS = ['C', 'F', 'Bb', 'Eb'];

/** Generate interval pool: for each root, build { root, target, label, semitones } */
function ivPool(roots: string[], semitones: number, label: string): IntervalSpec[] {
	return roots.map((root) => {
		const rootSt = noteToSemitone(root);
		const target = getNoteName(rootSt, semitones, 'flats');
		return { root, target, label, semitones };
	});
}

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
							exampleInterval: { root: 'C', target: 'E', label: 'Maj 3rd', semitones: 4 },
						},
						{
							type: 'practice',
							intervalPool: [
								...ivPool(EASY_KEYS, 4, 'Maj 3rd'),
								...ivPool(EASY_KEYS, 3, 'min 3rd'),
							],
							guidedCount: 4,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: 'Maj7',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
							intervalSemitones: 4,
							intervalLabel: 'Maj 3rd',
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
							exampleInterval: { root: 'B', target: 'F', label: 'Tritone', semitones: 6 },
						},
						{
							type: 'practice',
							intervalPool: ivPool(EASY_KEYS, 6, 'Tritone'),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: '7',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
							intervalSemitones: 6,
							intervalLabel: 'Tritone',
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
							exampleInterval: { root: 'C', target: 'G', label: 'P5', semitones: 7 },
						},
						{
							type: 'practice',
							intervalPool: ivPool(EASY_KEYS, 7, 'P5'),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: 'Maj7',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
							intervalSemitones: 7,
							intervalLabel: 'P5',
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
							exampleInterval: { root: 'C', target: 'Gb', label: '♭5', semitones: 6 },
						},
						{
							type: 'practice',
							intervalPool: [
								...ivPool(EASY_KEYS, 6, '♭5'),
								...ivPool(EASY_KEYS, 8, '#5'),
							],
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: 'm7b5',
							keys: ALL_KEYS,
							masteryThresholdMs: 4500,
							intervalSemitones: 6,
							intervalLabel: '♭5',
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
							exampleInterval: { root: 'C', target: 'A', label: 'Maj 6th', semitones: 9 },
						},
						{
							type: 'practice',
							intervalPool: ivPool(EASY_KEYS, 9, 'Maj 6th'),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: '6',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
							intervalSemitones: 9,
							intervalLabel: 'Maj 6th',
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
							exampleInterval: { root: 'C', target: 'Bb', label: '♭7', semitones: 10 },
						},
						{
							type: 'practice',
							intervalPool: ivPool(EASY_KEYS, 10, '♭7'),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: '7',
							keys: ALL_KEYS,
							masteryThresholdMs: 4000,
							intervalSemitones: 10,
							intervalLabel: '♭7',
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
							exampleInterval: { root: 'C', target: 'B', label: 'Maj 7th', semitones: 11 },
						},
						{
							type: 'practice',
							intervalPool: ivPool(EASY_KEYS, 11, 'Maj 7th'),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: 'Maj7',
							keys: ALL_KEYS,
							masteryThresholdMs: 3500,
							intervalSemitones: 11,
							intervalLabel: 'Maj 7th',
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
							exampleInterval: { root: 'C', target: 'D', label: 'Maj 9th', semitones: 14 },
						},
						{
							type: 'practice',
							intervalPool: ivPool(EASY_KEYS, 2, '9th'),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: '9',
							keys: ALL_KEYS,
							masteryThresholdMs: 4500,
							intervalSemitones: 2,
							intervalLabel: '9th',
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
							exampleInterval: { root: 'C', target: 'F', label: '11th', semitones: 17 },
						},
						{
							type: 'practice',
							intervalPool: [
								...ivPool(EASY_KEYS, 5, '11th'),
								...ivPool(EASY_KEYS, 9, '13th'),
							],
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'root',
							quality: '13',
							keys: ALL_KEYS,
							masteryThresholdMs: 4500,
							intervalSemitones: 5,
							intervalLabel: '11th',
						},
					],
				},
			],
		},
	],
};
