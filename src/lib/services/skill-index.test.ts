import { describe, it, expect } from 'vitest';
import {
	buildSkillIndex,
	cellKey,
	canonicalRoot,
	cellsForRoot,
	rootStanding,
	recentImprovements,
	SKILL_WINDOW,
} from './skill-index';
import type { ChordTiming, SessionResult } from './progress';
import type { VoicingType } from '$lib/engine';

/**
 * The skill index is the answer to "how good is this player at chord X in
 * voicing Y" — a question none of the four previous stores could answer, because
 * each dropped a different axis. These tests pin the properties the progress
 * surfaces depend on.
 */

/** Trivial quality parser: everything after a root letter + optional accidental. */
const qualityOf = (chord: string) => chord.replace(/^[A-G][#b]?/, '');

function timing(
	root: string,
	quality: string,
	durationMs: number,
	voicing?: VoicingType,
	correct?: boolean,
): ChordTiming {
	return {
		chord: `${root}${quality}`,
		root,
		durationMs,
		...(voicing ? { voicing } : {}),
		...(correct !== undefined ? { correct } : {}),
	};
}

function session(
	timings: ChordTiming[],
	at: number,
	sessionVoicing: VoicingType = 'root',
): SessionResult {
	return {
		id: `s${at}`,
		timestamp: at,
		elapsedMs: 1000,
		totalChords: timings.length,
		avgMs: 1000,
		chordTimings: timings,
		settings: {
			difficulty: 'beginner',
			notation: 'standard',
			voicing: sessionVoicing,
			displayMode: 'verify',
			accidentals: 'flats',
			progressionMode: 'random',
		},
		midi: { enabled: true, accuracy: 100 },
	} as unknown as SessionResult;
}

describe('buildSkillIndex — one cell per root × quality × voicing', () => {
	it('keeps the three axes apart instead of collapsing one', () => {
		const index = buildSkillIndex(
			[
				session(
					[
						timing('C', 'Maj7', 500, 'shell'),
						timing('C', 'Maj7', 5500, 'rootless-a'),
						timing('C', 'm7', 800, 'shell'),
						timing('F', 'Maj7', 900, 'shell'),
					],
					1000,
				),
			],
			qualityOf,
		);

		// Four distinct cells — the old dial merged the first two into one entry
		// with a 3000ms average and called the key fluent.
		expect(index.size).toBe(4);
		expect(index.get(cellKey('C', 'Maj7', 'shell'))?.avgMs).toBe(500);
		expect(index.get(cellKey('C', 'Maj7', 'rootless-a'))?.avgMs).toBe(5500);
	});

	it('averages only the most recent attempts, not a lifetime mean', () => {
		// Four sessions, oldest slowest. The window keeps the newest three.
		const history = [
			session([timing('C', 'Maj7', 4000, 'root')], 1000),
			session([timing('C', 'Maj7', 1200, 'root')], 2000),
			session([timing('C', 'Maj7', 1000, 'root')], 3000),
			session([timing('C', 'Maj7', 800, 'root')], 4000),
		];
		const cell = buildSkillIndex(history, qualityOf).get(cellKey('C', 'Maj7', 'root'))!;

		expect(cell.attempts).toBe(SKILL_WINDOW);
		expect(cell.totalAttempts).toBe(4);
		// (800 + 1000 + 1200) / 3 = 1000 — the ancient 4000ms attempt is out.
		expect(cell.avgMs).toBe(1000);
	});

	it('carries accuracy alongside speed', () => {
		const index = buildSkillIndex(
			[
				session(
					[
						timing('C', 'Maj7', 900, 'root', true),
						timing('C', 'Maj7', 900, 'root', false),
					],
					1000,
				),
			],
			qualityOf,
		);
		expect(index.get(cellKey('C', 'Maj7', 'root'))?.accuracy).toBe(0.5);
	});

	it('reports accuracy null when nothing recorded it', () => {
		const index = buildSkillIndex([session([timing('C', 'Maj7', 900, 'root')], 1000)], qualityOf);
		expect(index.get(cellKey('C', 'Maj7', 'root'))?.accuracy).toBeNull();
	});

	it('falls back to the session voicing for records written before the field existed', () => {
		// No per-chord voicing — the old shape.
		const index = buildSkillIndex(
			[session([timing('C', 'Maj7', 900)], 1000, 'shell')],
			qualityOf,
		);
		expect(index.get(cellKey('C', 'Maj7', 'shell'))?.avgMs).toBe(900);
	});

	it('merges enharmonic spellings into one cell', () => {
		// The app generates flats but can be set to sharps; the coach ladder says F#.
		const index = buildSkillIndex(
			[
				session([timing('Gb', 'Maj7', 1000, 'root')], 1000),
				session([timing('F#', 'Maj7', 1200, 'root')], 2000),
			],
			qualityOf,
		);
		expect(canonicalRoot('F#')).toBe('Gb');
		expect(index.size).toBe(1);
		expect(index.get(cellKey('Gb', 'Maj7', 'root'))?.totalAttempts).toBe(2);
	});
});

describe('rootStanding — a key is judged by its weakest voicing', () => {
	const history = [
		session(
			[
				timing('C', 'Maj7', 400, 'root', true),
				timing('C', 'Maj7', 450, 'shell', true),
				timing('C', 'Maj7', 6000, 'rootless-a', true),
			],
			1000,
		),
	];

	it('reports the slowest voicing, not the average', () => {
		const index = buildSkillIndex(history, qualityOf);
		const s = rootStanding(index, 'C', 2000);

		// Mean would be ~2283ms and the old dial called this fluent at 1800.
		expect(s.worstVoicing).toBe('rootless-a');
		expect(s.worstAvgMs).toBe(6000);
		expect(s.mastered).toBe(false);
	});

	it('gives the per-voicing breakdown, slowest first — the hover detail', () => {
		const index = buildSkillIndex(history, qualityOf);
		const s = rootStanding(index, 'C', 2000);

		expect(s.perVoicing.map((v) => v.voicing)).toEqual(['rootless-a', 'shell', 'root']);
	});

	it('only counts voicings the player has unlocked', () => {
		const index = buildSkillIndex(history, qualityOf);
		// The disastrous voicing has not been taught yet — it must not hold the
		// key back.
		const s = rootStanding(index, 'C', 2000, ['root', 'shell']);

		expect(s.worstVoicing).toBe('shell');
		expect(s.mastered).toBe(true);
	});

	it('is not mastered when a voicing is fast but wrong', () => {
		const index = buildSkillIndex(
			[
				session(
					[
						timing('D', 'Maj7', 300, 'root', false),
						timing('D', 'Maj7', 320, 'root', false),
					],
					1000,
				),
			],
			qualityOf,
		);
		const s = rootStanding(index, 'D', 2000);

		// 300ms is quick, and completely wrong. The old dial rated this fluent.
		expect(s.worstAvgMs).toBeLessThan(2000);
		expect(s.mastered).toBe(false);
	});

	it('reports an untouched key as unplayed rather than perfect', () => {
		const s = rootStanding(new Map(), 'B', 2000);
		expect(s.worstAvgMs).toBeNull();
		expect(s.mastered).toBe(false);
		expect(s.attempts).toBe(0);
	});

	it('cellsForRoot finds a key under either spelling', () => {
		const index = buildSkillIndex([session([timing('Gb', 'Maj7', 900, 'root')], 1000)], qualityOf);
		expect(cellsForRoot(index, 'F#')).toHaveLength(1);
	});
});

describe('recentImprovements — what to name in the summary', () => {
	it('names the chord that got meaningfully faster', () => {
		const before = buildSkillIndex(
			[session([timing('C', 'Maj7', 3000, 'root'), timing('F', 'm7', 1000, 'root')], 1000)],
			qualityOf,
		);
		const after = buildSkillIndex(
			[
				session([timing('C', 'Maj7', 3000, 'root'), timing('F', 'm7', 1000, 'root')], 1000),
				session([timing('C', 'Maj7', 1000, 'root'), timing('F', 'm7', 990, 'root')], 2000),
			],
			qualityOf,
		);

		const gains = recentImprovements(before, after);
		// C Maj7 improved by a second; F m7 barely moved and is not worth saying.
		expect(gains[0].cell.quality).toBe('Maj7');
		expect(gains[0].cell.root).toBe('C');
		expect(gains.some((g) => g.cell.quality === 'm7')).toBe(false);
	});

	it('says nothing about a chord played for the first time', () => {
		const before = new Map();
		const after = buildSkillIndex([session([timing('C', 'Maj7', 900, 'root')], 1000)], qualityOf);
		expect(recentImprovements(before, after)).toEqual([]);
	});
});
