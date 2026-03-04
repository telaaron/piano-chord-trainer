// Course registry — all available courses
import { shellVoicingsCourse } from './shell-voicings';
import { ultimatePlanCourse } from './ultimate-plan';
import type { Course } from '$lib/engine/courses';

export const ALL_COURSES: Course[] = [ultimatePlanCourse, shellVoicingsCourse];

export function getCourse(id: string): Course | undefined {
	return ALL_COURSES.find((c) => c.id === id);
}

export function getLesson(courseId: string, lessonId: string) {
	const course = getCourse(courseId);
	if (!course) return undefined;
	for (const mod of course.modules) {
		const lesson = mod.lessons.find((l) => l.id === lessonId);
		if (lesson) return { course, module: mod, lesson };
	}
	return undefined;
}
