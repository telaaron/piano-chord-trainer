// Course progress persistence — localStorage-based
// Stores per-course progress independently.

import type { Course } from '$lib/engine/courses';
import {
	type CourseProgress,
	type LessonProgress,
	type StepProgress,
	type MasteryLevel,
	createCourseProgress,
	computeMastery,
} from '$lib/engine/courses';

const STORAGE_KEY = 'chord-trainer-course-progress';

// ─── Load / Save ────────────────────────────────────────────

function loadAllProgress(): Record<string, CourseProgress> {
	if (typeof localStorage === 'undefined') return {};
	try {
		const raw = localStorage.getItem(STORAGE_KEY);
		return raw ? JSON.parse(raw) : {};
	} catch {
		return {};
	}
}

function saveAllProgress(data: Record<string, CourseProgress>): void {
	if (typeof localStorage === 'undefined') return;
	try {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
	} catch {
		// Storage full — silently fail
	}
}

// ─── Public API ─────────────────────────────────────────────

/** Get progress for a specific course. Creates empty progress if none exists. */
export function getCourseProgress(course: Course): CourseProgress {
	const all = loadAllProgress();
	if (all[course.id]) return all[course.id];
	return createCourseProgress(course);
}

/** Get lesson progress, creating default if missing */
export function getLessonProgress(
	course: Course,
	lessonId: string,
): LessonProgress | undefined {
	const cp = getCourseProgress(course);
	for (const mod of cp.modules) {
		const lp = mod.lessons.find((l) => l.lessonId === lessonId);
		if (lp) return lp;
	}
	return undefined;
}

/** Mark a step as completed and update mastery */
export function completeStep(
	course: Course,
	lessonId: string,
	stepIndex: number,
	score?: number,
): void {
	const all = loadAllProgress();
	if (!all[course.id]) {
		all[course.id] = createCourseProgress(course);
	}

	const cp = all[course.id];
	cp.lastActivityAt = Date.now();

	for (const mod of cp.modules) {
		const lp = mod.lessons.find((l) => l.lessonId === lessonId);
		if (!lp) continue;

		if (stepIndex >= 0 && stepIndex < lp.steps.length) {
			const step = lp.steps[stepIndex];
			step.completed = true;
			step.attempts++;
			if (score !== undefined) {
				step.bestScore = step.bestScore !== undefined
					? Math.min(step.bestScore, score)
					: score;
			}

			// Update challenge avg if this was the challenge step
			if (step.stepType === 'challenge' && score !== undefined) {
				lp.bestChallengeAvgMs = lp.bestChallengeAvgMs !== undefined
					? Math.min(lp.bestChallengeAvgMs, score)
					: score;
			}

			lp.mastery = computeMastery(lp.steps, lp.bestChallengeAvgMs);
		}
		break;
	}

	saveAllProgress(all);
}

/** Record an attempt without completing (e.g., challenge failed) */
export function recordAttempt(
	course: Course,
	lessonId: string,
	stepIndex: number,
	score?: number,
): void {
	const all = loadAllProgress();
	if (!all[course.id]) {
		all[course.id] = createCourseProgress(course);
	}

	const cp = all[course.id];
	cp.lastActivityAt = Date.now();

	for (const mod of cp.modules) {
		const lp = mod.lessons.find((l) => l.lessonId === lessonId);
		if (!lp) continue;

		if (stepIndex >= 0 && stepIndex < lp.steps.length) {
			const step = lp.steps[stepIndex];
			step.attempts++;
			if (score !== undefined && step.bestScore !== undefined) {
				step.bestScore = Math.min(step.bestScore, score);
			} else if (score !== undefined) {
				step.bestScore = score;
			}

			// Update mastery (might go from none → started)
			lp.mastery = computeMastery(lp.steps, lp.bestChallengeAvgMs);
		}
		break;
	}

	saveAllProgress(all);
}

/** Skip all steps and mark entire lesson as completed (for advanced users) */
export function skipLesson(course: Course, lessonId: string): void {
	const all = loadAllProgress();
	if (!all[course.id]) {
		all[course.id] = createCourseProgress(course);
	}

	const cp = all[course.id];
	cp.lastActivityAt = Date.now();

	for (const mod of cp.modules) {
		const lp = mod.lessons.find((l) => l.lessonId === lessonId);
		if (!lp) continue;

		for (const step of lp.steps) {
			step.completed = true;
		}
		lp.mastery = 'completed';
		break;
	}

	saveAllProgress(all);
}
