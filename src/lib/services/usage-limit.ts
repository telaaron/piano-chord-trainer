// Free-tier daily allowance for coach sessions.
//
// This is the single limit the free tier has, and the main reason to upgrade
// (see docs/MONETARISIERUNG.md). The rules it has to honour:
//
//   1. It counts only sessions the coach actually started, never a session
//      someone abandoned before playing — the telemetry says most drop-offs
//      happen before the first chord, and charging someone a day's allowance
//      for a session they never played would be the worst possible first
//      impression.
//   2. Free practice is never limited. The limit is an offer, not a lockout;
//      "Selbst wählen" stays open all day.
//   3. It resets on the local calendar day, because that is what "one session
//      per day" means to a person practising in the evening.
//
// Deliberately localStorage-only and not server-enforced: this is a nudge for
// honest users, not DRM. Someone who clears storage gets another session —
// that costs us nothing, and the alternative (a server round-trip before every
// session) would slow down the one flow we most need to stay instant.

import { FREE_LIMITS } from './subscription';

const STORAGE_KEY = 'chord-trainer-coach-usage';

interface UsageRecord {
	/** Local calendar day, YYYY-MM-DD. */
	day: string;
	/** Coach sessions started on that day. */
	count: number;
}

/** Local calendar day key — not UTC, see rule 3 above. */
function today(now: number = Date.now()): string {
	const d = new Date(now);
	const m = String(d.getMonth() + 1).padStart(2, '0');
	const day = String(d.getDate()).padStart(2, '0');
	return `${d.getFullYear()}-${m}-${day}`;
}

function read(now?: number): UsageRecord {
	const fresh: UsageRecord = { day: today(now), count: 0 };
	if (typeof localStorage === 'undefined') return fresh;
	try {
		const raw = localStorage.getItem(STORAGE_KEY);
		if (!raw) return fresh;
		const parsed = JSON.parse(raw) as Partial<UsageRecord>;
		if (parsed?.day !== fresh.day) return fresh; // new day → allowance resets
		return { day: fresh.day, count: typeof parsed.count === 'number' ? parsed.count : 0 };
	} catch {
		return fresh;
	}
}

/** How many coach sessions the free tier has left today. */
export function remainingFreeSessions(now?: number): number {
	return Math.max(0, FREE_LIMITS.coachSessionsPerDay - read(now).count);
}

/**
 * Whether a free user may start another coach session today.
 * Pro/Studio callers should not consult this at all — see `canStartCoachSession`.
 */
export function hasFreeSessionLeft(now?: number): boolean {
	return remainingFreeSessions(now) > 0;
}

/**
 * Record that a coach session actually started.
 * Call this at the point the first block begins, never when the plan is merely
 * built (rule 1). Safe to call for Pro users — the counter is simply ignored
 * for them, which keeps the call site free of tier branching.
 */
export function recordCoachSessionStart(now?: number): void {
	if (typeof localStorage === 'undefined') return;
	const rec = read(now);
	try {
		localStorage.setItem(
			STORAGE_KEY,
			JSON.stringify({ day: rec.day, count: rec.count + 1 } satisfies UsageRecord),
		);
	} catch {
		// Storage full — fail open. A user who cannot be counted practises free.
	}
}

/** Test seam: forget today's usage. */
export function resetCoachUsage(): void {
	if (typeof localStorage === 'undefined') return;
	try {
		localStorage.removeItem(STORAGE_KEY);
	} catch {
		// ignore
	}
}
