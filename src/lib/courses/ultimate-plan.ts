// Ultimate Plan — comprehensive learning journey from beginner to master
// Covers all chord types, voicings, and inversions in a structured progression.

import type { Course, CourseModule, Lesson, ChordSpec } from '$lib/engine/courses';
import type { VoicingType } from '$lib/engine/chords';

const ALL_KEYS = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
const EASY_KEYS = ['C', 'F', 'Bb', 'Eb'];
const MED_KEYS = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B']; // all 12

// ─── Helper: build standard 3-step lesson (theory → practice → challenge) ──

function lesson(
	id: string,
	titleKey: string,
	subtitleKey: string,
	quality: string,
	voicing: VoicingType,
	exampleRoot: string,
	practiceKeys: string[],
	challengeKeys: string[],
	masteryMs = 3000,
): Lesson {
	return {
		id,
		titleKey,
		subtitleKey,
		steps: [
			{
				type: 'theory',
				contentKey: `course.ultimate.${id}.theory`,
				exampleChord: { root: exampleRoot, quality, voicing },
			},
			{
				type: 'practice',
				chordPool: practiceKeys.map((root) => ({
					root,
					quality,
					voicing,
				})),
				guidedCount: 3,
			},
			{
				type: 'challenge',
				voicing,
				quality,
				keys: challengeKeys,
				masteryThresholdMs: masteryMs,
			},
		],
	};
}

// ═══════════════════════════════════════════════════════════
// Module 1 — Grundlagen: Die 3 Hauptakkorde in Grundstellung
// ═══════════════════════════════════════════════════════════

const mod1_fundamentals: CourseModule = {
	id: 'fundamentals',
	titleKey: 'course.ultimate.mod1.title',
	lessons: [
		lesson('fund-maj7', 'course.ultimate.fund-maj7.title', 'course.ultimate.fund-maj7.subtitle', 'Maj7', 'root', 'C', EASY_KEYS, ALL_KEYS, 4000),
		lesson('fund-dom7', 'course.ultimate.fund-dom7.title', 'course.ultimate.fund-dom7.subtitle', '7', 'root', 'G', EASY_KEYS, ALL_KEYS, 4000),
		lesson('fund-m7', 'course.ultimate.fund-m7.title', 'course.ultimate.fund-m7.subtitle', 'm7', 'root', 'D', EASY_KEYS, ALL_KEYS, 4000),
	],
};

// ═══════════════════════════════════════════════════════════
// Module 2 — Shell Voicings
// ═══════════════════════════════════════════════════════════

const mod2_shells: CourseModule = {
	id: 'shells',
	titleKey: 'course.ultimate.mod2.title',
	lessons: [
		lesson('shell-maj7', 'course.ultimate.shell-maj7.title', 'course.ultimate.shell-maj7.subtitle', 'Maj7', 'shell', 'C', EASY_KEYS, ALL_KEYS),
		lesson('shell-dom7', 'course.ultimate.shell-dom7.title', 'course.ultimate.shell-dom7.subtitle', '7', 'shell', 'C', EASY_KEYS, ALL_KEYS),
		lesson('shell-m7', 'course.ultimate.shell-m7.title', 'course.ultimate.shell-m7.subtitle', 'm7', 'shell', 'D', EASY_KEYS, ALL_KEYS),
	],
};

// ═══════════════════════════════════════════════════════════
// Module 3 — Sext- und Sonderakkorde
// ═══════════════════════════════════════════════════════════

const mod3_sixths: CourseModule = {
	id: 'sixths',
	titleKey: 'course.ultimate.mod3.title',
	lessons: [
		lesson('sixth-6', 'course.ultimate.sixth-6.title', 'course.ultimate.sixth-6.subtitle', '6', 'root', 'C', EASY_KEYS, ALL_KEYS, 3500),
		lesson('sixth-m6', 'course.ultimate.sixth-m6.title', 'course.ultimate.sixth-m6.subtitle', 'm6', 'root', 'A', EASY_KEYS, ALL_KEYS, 3500),
		lesson('sixth-m7b5', 'course.ultimate.sixth-m7b5.title', 'course.ultimate.sixth-m7b5.subtitle', 'm7b5', 'root', 'B', EASY_KEYS, ALL_KEYS, 3500),
		lesson('sixth-dim7', 'course.ultimate.sixth-dim7.title', 'course.ultimate.sixth-dim7.subtitle', 'dim7', 'root', 'B', EASY_KEYS, ALL_KEYS, 3500),
	],
};

// ═══════════════════════════════════════════════════════════
// Module 4 — Erweiterte Akkorde (9th chords)
// ═══════════════════════════════════════════════════════════

const mod4_ninths: CourseModule = {
	id: 'ninths',
	titleKey: 'course.ultimate.mod4.title',
	lessons: [
		lesson('ninth-maj9', 'course.ultimate.ninth-maj9.title', 'course.ultimate.ninth-maj9.subtitle', 'Maj9', 'root', 'C', EASY_KEYS, ALL_KEYS, 3500),
		lesson('ninth-9', 'course.ultimate.ninth-9.title', 'course.ultimate.ninth-9.subtitle', '9', 'root', 'G', EASY_KEYS, ALL_KEYS, 3500),
		lesson('ninth-m9', 'course.ultimate.ninth-m9.title', 'course.ultimate.ninth-m9.subtitle', 'm9', 'root', 'D', EASY_KEYS, ALL_KEYS, 3500),
		lesson('ninth-69', 'course.ultimate.ninth-69.title', 'course.ultimate.ninth-69.subtitle', '6/9', 'root', 'C', EASY_KEYS, ALL_KEYS, 3500),
	],
};

// ═══════════════════════════════════════════════════════════
// Module 5 — Volle Besetzung & Half-Shell
// ═══════════════════════════════════════════════════════════

const mod5_full: CourseModule = {
	id: 'full-voicings',
	titleKey: 'course.ultimate.mod5.title',
	lessons: [
		lesson('full-maj7', 'course.ultimate.full-maj7.title', 'course.ultimate.full-maj7.subtitle', 'Maj7', 'full', 'C', EASY_KEYS, ALL_KEYS),
		lesson('full-dom7', 'course.ultimate.full-dom7.title', 'course.ultimate.full-dom7.subtitle', '7', 'full', 'C', EASY_KEYS, ALL_KEYS),
		lesson('full-m7', 'course.ultimate.full-m7.title', 'course.ultimate.full-m7.subtitle', 'm7', 'full', 'D', EASY_KEYS, ALL_KEYS),
		lesson('hshell-maj7', 'course.ultimate.hshell-maj7.title', 'course.ultimate.hshell-maj7.subtitle', 'Maj7', 'half-shell', 'C', EASY_KEYS, ALL_KEYS),
	],
};

// ═══════════════════════════════════════════════════════════
// Module 6 — Rootless Voicings
// ═══════════════════════════════════════════════════════════

const mod6_rootless: CourseModule = {
	id: 'rootless',
	titleKey: 'course.ultimate.mod6.title',
	lessons: [
		lesson('rla-maj7', 'course.ultimate.rla-maj7.title', 'course.ultimate.rla-maj7.subtitle', 'Maj7', 'rootless-a', 'C', EASY_KEYS, ALL_KEYS, 3500),
		lesson('rla-dom7', 'course.ultimate.rla-dom7.title', 'course.ultimate.rla-dom7.subtitle', '7', 'rootless-a', 'C', EASY_KEYS, ALL_KEYS, 3500),
		lesson('rla-m7', 'course.ultimate.rla-m7.title', 'course.ultimate.rla-m7.subtitle', 'm7', 'rootless-a', 'D', EASY_KEYS, ALL_KEYS, 3500),
		lesson('rlb-maj7', 'course.ultimate.rlb-maj7.title', 'course.ultimate.rlb-maj7.subtitle', 'Maj7', 'rootless-b', 'C', EASY_KEYS, ALL_KEYS, 3500),
		lesson('rlb-dom7', 'course.ultimate.rlb-dom7.title', 'course.ultimate.rlb-dom7.subtitle', '7', 'rootless-b', 'C', EASY_KEYS, ALL_KEYS, 3500),
		lesson('rlb-m7', 'course.ultimate.rlb-m7.title', 'course.ultimate.rlb-m7.subtitle', 'm7', 'rootless-b', 'D', EASY_KEYS, ALL_KEYS, 3500),
	],
};

// ═══════════════════════════════════════════════════════════
// Module 7 — Umkehrungen
// ═══════════════════════════════════════════════════════════

const mod7_inversions: CourseModule = {
	id: 'inversions',
	titleKey: 'course.ultimate.mod7.title',
	lessons: [
		lesson('inv1-maj7', 'course.ultimate.inv1-maj7.title', 'course.ultimate.inv1-maj7.subtitle', 'Maj7', 'inversion-1', 'C', EASY_KEYS, ALL_KEYS, 3500),
		lesson('inv2-maj7', 'course.ultimate.inv2-maj7.title', 'course.ultimate.inv2-maj7.subtitle', 'Maj7', 'inversion-2', 'C', EASY_KEYS, ALL_KEYS, 3500),
		lesson('inv3-maj7', 'course.ultimate.inv3-maj7.title', 'course.ultimate.inv3-maj7.subtitle', 'Maj7', 'inversion-3', 'C', EASY_KEYS, ALL_KEYS, 3500),
	],
};

// ═══════════════════════════════════════════════════════════
// Module 8 — Altered Dominants & Advanced
// ═══════════════════════════════════════════════════════════

const mod8_advanced: CourseModule = {
	id: 'advanced',
	titleKey: 'course.ultimate.mod8.title',
	lessons: [
		lesson('adv-7s9', 'course.ultimate.adv-7s9.title', 'course.ultimate.adv-7s9.subtitle', '7#9', 'root', 'E', EASY_KEYS, ALL_KEYS, 4000),
		lesson('adv-7b9', 'course.ultimate.adv-7b9.title', 'course.ultimate.adv-7b9.subtitle', '7b9', 'root', 'G', EASY_KEYS, ALL_KEYS, 4000),
		lesson('adv-lyd', 'course.ultimate.adv-lyd.title', 'course.ultimate.adv-lyd.subtitle', 'Maj7#11', 'root', 'C', EASY_KEYS, ALL_KEYS, 4000),
		lesson('adv-m11', 'course.ultimate.adv-m11.title', 'course.ultimate.adv-m11.subtitle', 'm11', 'root', 'D', EASY_KEYS, ALL_KEYS, 4000),
		lesson('adv-13', 'course.ultimate.adv-13.title', 'course.ultimate.adv-13.subtitle', '13', 'root', 'G', EASY_KEYS, ALL_KEYS, 4000),
	],
};

// ═══════════════════════════════════════════════════════════
// Course definition
// ═══════════════════════════════════════════════════════════

export const ultimatePlanCourse: Course = {
	id: 'ultimate-plan',
	titleKey: 'course.ultimate.title',
	descriptionKey: 'course.ultimate.description',
	subtitleKey: 'course.ultimate.subtitle',
	icon: '🚀',
	level: 'beginner', // starts easy, grows to advanced
	modules: [
		mod1_fundamentals,
		mod2_shells,
		mod3_sixths,
		mod4_ninths,
		mod5_full,
		mod6_rootless,
		mod7_inversions,
		mod8_advanced,
	],
};
