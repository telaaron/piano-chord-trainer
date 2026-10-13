import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

/**
 * Every coach event must carry the session it belongs to — otherwise a
 * session's events can only be grouped by device + time window, and
 * per-block events get mistaken for per-session ones.
 */

const inserted: unknown[][] = [];

vi.mock('./supabase', () => ({
	getSupabase: () => ({
		from: () => ({
			insert: async (rows: unknown[]) => {
				inserted.push(rows);
				return { error: null };
			},
		}),
	}),
}));
vi.mock('./auth', () => ({ getAuthState: () => ({ user: null }) }));
vi.mock('./coach-config', () => ({ getCohort: () => 'control' }));

const g = globalThis as Record<string, unknown>;

describe('trackCoachEvent', () => {
	beforeEach(() => {
		inserted.length = 0;
		const map = new Map<string, string>();
		g.window = {};
		g.document = { addEventListener: () => {} };
		g.localStorage = {
			getItem: (k: string) => map.get(k) ?? null,
			setItem: (k: string, v: string) => void map.set(k, v),
			removeItem: (k: string) => void map.delete(k),
		};
	});
	afterEach(() => {
		delete g.window;
		delete g.document;
		delete g.localStorage;
	});

	it('tags events with the current coach session id', async () => {
		const t = await import('./telemetry');
		t.setCoachSessionId('session-a');
		t.trackCoachEvent('session_start', { blocks: ['drill'] });
		t.trackCoachEvent('first_chord_played', { blockIdx: 0 });
		t.setCoachSessionId('session-b');
		t.trackCoachEvent('session_start', {});
		await t.flushQueue();

		const rows = inserted.flat() as { event_type: string; payload: Record<string, unknown> }[];
		expect(rows.map((r) => r.payload.sessionId)).toEqual(['session-a', 'session-a', 'session-b']);
		expect(rows[0].payload.blocks).toEqual(['drill']);
	});

	it('leaves the payload untouched without a session', async () => {
		const t = await import('./telemetry');
		t.setCoachSessionId(null);
		t.trackCoachEvent('feedback_valve', { signal: 'tooHard' });
		await t.flushQueue();

		const rows = inserted.flat() as { payload: Record<string, unknown> }[];
		expect(rows[0].payload).toEqual({ signal: 'tooHard' });
	});
});
