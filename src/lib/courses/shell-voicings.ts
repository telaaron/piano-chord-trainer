// Shell Voicings course — the first and core learning path
// Teaches: Root + 3rd + 7th for Maj7, Dom7, m7

import type { Course } from '$lib/engine/courses';

const ALL_KEYS = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
const EASY_KEYS = ['C', 'F', 'Bb'];

export const shellVoicingsCourse: Course = {
	id: 'shell-voicings',
	titleKey: 'course.shell.title',
	descriptionKey: 'course.shell.description',
	subtitleKey: 'course.shell.subtitle',
	icon: '🎹',
	level: 'beginner',
	modules: [
		{
			id: 'basics',
			titleKey: 'course.shell.mod1.title',
			lessons: [
				{
					id: 'maj7',
					titleKey: 'course.shell.maj7.title',
					subtitleKey: 'course.shell.maj7.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.shell.maj7.theory',
							exampleChord: { root: 'C', quality: 'Maj7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((root) => ({
								root,
								quality: 'Maj7',
								voicing: 'shell' as const,
							})),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'Maj7',
							keys: ALL_KEYS,
							masteryThresholdMs: 3000,
						},
					],
				},
				{
					id: 'dom7',
					titleKey: 'course.shell.dom7.title',
					subtitleKey: 'course.shell.dom7.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.shell.dom7.theory',
							exampleChord: { root: 'C', quality: '7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((root) => ({
								root,
								quality: '7',
								voicing: 'shell' as const,
							})),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: '7',
							keys: ALL_KEYS,
							masteryThresholdMs: 3000,
						},
					],
				},
				{
					id: 'm7',
					titleKey: 'course.shell.m7.title',
					subtitleKey: 'course.shell.m7.subtitle',
					steps: [
						{
							type: 'theory',
							contentKey: 'course.shell.m7.theory',
							exampleChord: { root: 'C', quality: 'm7', voicing: 'shell' },
						},
						{
							type: 'practice',
							chordPool: EASY_KEYS.map((root) => ({
								root,
								quality: 'm7',
								voicing: 'shell' as const,
							})),
							guidedCount: 3,
						},
						{
							type: 'challenge',
							voicing: 'shell',
							quality: 'm7',
							keys: ALL_KEYS,
							masteryThresholdMs: 3000,
						},
					],
				},
			],
		},
	],
};
