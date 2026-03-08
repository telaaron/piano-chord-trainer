// Course engine — types, data, mastery logic
// Pure TypeScript, no DOM, no side effects.

import type { VoicingType } from './chords';

// ─── Types ──────────────────────────────────────────────────

export type StepType = 'theory' | 'practice' | 'challenge';
export type MasteryLevel = 'none' | 'started' | 'completed' | 'mastered';

export interface ChordSpec {
	root: string;
	quality: string;
	voicing: VoicingType;
}

export interface IntervalSpec {
	/** Lower note of the interval */
	root: string;
	/** Upper note of the interval */
	target: string;
	/** Display label, e.g. 'Große Terz' — provided via i18n in the theory text */
	label: string;
	/** Semitone distance */
	semitones: number;
}

export interface TheoryStep {
	type: 'theory';
	/** i18n key for the theory content, e.g. 'course.shell.maj7.theory' */
	contentKey: string;
	/** Example chord to display on the interactive keyboard */
	exampleChord?: ChordSpec;
	/** Pure interval to display (2 notes on keyboard) — alternative to exampleChord */
	exampleInterval?: IntervalSpec;
}

export interface PracticeStep {
	type: 'practice';
	/** Chord pool for guided → free practice */
	chordPool: ChordSpec[];
	/** How many correct in a row before hints are removed */
	guidedCount: number;
}

export interface ChallengeStep {
	type: 'challenge';
	/** Voicing type for the speed drill */
	voicing: VoicingType;
	/** Chord quality to drill (e.g. 'maj7') */
	quality: string;
	/** All 12 keys or a subset */
	keys: string[];
	/** Average ms per chord to pass */
	masteryThresholdMs: number;
}

export type LessonStep = TheoryStep | PracticeStep | ChallengeStep;

export interface Lesson {
	id: string;
	/** i18n key for lesson title */
	titleKey: string;
	/** i18n key for lesson subtitle */
	subtitleKey: string;
	steps: LessonStep[];
}

export interface CourseModule {
	id: string;
	/** i18n key for module title */
	titleKey: string;
	lessons: Lesson[];
}

export interface Course {
	id: string;
	/** i18n key for course title */
	titleKey: string;
	/** i18n key for course description */
	descriptionKey: string;
	/** i18n key for subtitle shown on the card */
	subtitleKey: string;
	icon: string;
	level: 'beginner' | 'intermediate' | 'advanced';
	modules: CourseModule[];
}

// ─── Progress types ─────────────────────────────────────────

export interface StepProgress {
	stepType: StepType;
	completed: boolean;
	attempts: number;
	bestScore?: number;
}

export interface LessonProgress {
	lessonId: string;
	steps: StepProgress[];
	mastery: MasteryLevel;
	bestChallengeAvgMs?: number;
}

export interface ModuleProgress {
	moduleId: string;
	lessons: LessonProgress[];
}

export interface CourseProgress {
	courseId: string;
	modules: ModuleProgress[];
	startedAt: number;
	lastActivityAt: number;
}

// ─── Mastery helpers ────────────────────────────────────────

export const MASTERY_THRESHOLD_MS = 2000;

/** Compute mastery level from step progress */
export function computeMastery(steps: StepProgress[], bestChallengeAvgMs?: number): MasteryLevel {
	if (steps.every((s) => !s.completed && s.attempts === 0)) return 'none';

	const allCompleted = steps.every((s) => s.completed);
	if (!allCompleted) return 'started';

	if (bestChallengeAvgMs !== undefined && bestChallengeAvgMs < MASTERY_THRESHOLD_MS) {
		return 'mastered';
	}
	return 'completed';
}

/** Create empty progress for a lesson */
export function createLessonProgress(lesson: Lesson): LessonProgress {
	return {
		lessonId: lesson.id,
		steps: lesson.steps.map((s) => ({
			stepType: s.type,
			completed: false,
			attempts: 0,
		})),
		mastery: 'none',
	};
}

/** Create empty progress for a course */
export function createCourseProgress(course: Course): CourseProgress {
	return {
		courseId: course.id,
		modules: course.modules.map((m) => ({
			moduleId: m.id,
			lessons: m.lessons.map(createLessonProgress),
		})),
		startedAt: Date.now(),
		lastActivityAt: Date.now(),
	};
}

/** Get completion percentage for a module (0–100) */
export function moduleCompletionPercent(moduleProgress: ModuleProgress): number {
	const lessons = moduleProgress.lessons;
	if (lessons.length === 0) return 0;
	const completed = lessons.filter(
		(l) => l.mastery === 'completed' || l.mastery === 'mastered',
	).length;
	return Math.round((completed / lessons.length) * 100);
}

/** Get completion percentage for a course */
export function courseCompletionPercent(courseProgress: CourseProgress): number {
	const allLessons = courseProgress.modules.flatMap((m) => m.lessons);
	if (allLessons.length === 0) return 0;
	const completed = allLessons.filter(
		(l) => l.mastery === 'completed' || l.mastery === 'mastered',
	).length;
	return Math.round((completed / allLessons.length) * 100);
}

/** Get the next incomplete lesson across the whole course */
export function getNextLesson(
	course: Course,
	progress: CourseProgress,
): { moduleId: string; lessonId: string } | null {
	for (const mod of course.modules) {
		const modProgress = progress.modules.find((mp) => mp.moduleId === mod.id);
		for (const lesson of mod.lessons) {
			const lp = modProgress?.lessons.find((lp) => lp.lessonId === lesson.id);
			if (!lp || lp.mastery === 'none' || lp.mastery === 'started') {
				return { moduleId: mod.id, lessonId: lesson.id };
			}
		}
	}
	return null;
}
