// Free-tier allowance for coach sessions.
//
// Currently: there is none. `FREE_LIMITS.coachSessionsPerDay` is Infinity for
// the first FREE_LIMITS.unlimitedDays days of a device's life, and today that
// window is 90 days — so in practice nobody meets a wall. The machinery below
// stays in place because the window is meant to be re-evaluated, not because
// the limit is currently doing work.
//
// Why no limit (docs/MONETARISIERUNG.md, council 2026-07-31): a daily cap is a
// tool for restraining people who come back too often. Nothing in the data
// suggests we have those people — no device has ever returned on a second day.
// At this size the entire foregone revenue from unlimited free practice is
// bounded by a number too small to trade against the chance of someone forming
// a habit. Paid is depth (history beyond a week, adaptive difficulty, all To-Go
// disciplines, sync), never volume.
//
// The rules this module has to honour whenever a limit IS active:
//
//   1. It counts only sessions the coach actually started, never a session
//      someone abandoned before playing — the telemetry says most drop-offs
//      happen before the first chord, and charging someone a day's allowance
//      for a session they never played would be the worst possible first
//      impression.
//   2. Calibration never counts. It is a placement test with exactly one block
//      and no teaching in it; every product on earth gives you the assessment
//      for free. Billing it as the day's practice is what made a new user meet
//      the paywall having played nothing at all.
//   3. Free practice is never limited. The limit is an offer, not a lockout;
//      "Selbst wählen" stays open all day.
//   4. It resets on the local calendar day, because that is what "one session
//      per day" means to a person practising in the evening.
//
// Deliberately localStorage-only and not server-enforced: this is a nudge for
// honest users, not DRM. Someone who clears storage gets another session —
// that costs us nothing, and the alternative (a server round-trip before every
// session) would slow down the one flow we most need to stay instant.

import { FREE_LIMITS } from './subscription';

const STORAGE_KEY = 'chord-trainer-coach-usage';
/** First time this device ran the app, ISO date. Anchors the free window. */
const FIRST_SEEN_KEY = 'chord-trainer-first-seen';

interface UsageRecord {
	/** Local calendar day, YYYY-MM-DD. */
	day: string;
	/** Coach sessions started on that day. */
	count: number;
}

/** Local calendar day key — not UTC, see rule 4 above. */
function today(now: number = Date.now()): string {
	const d = new Date(now);
	const m = String(d.getMonth() + 1).padStart(2, '0');
	const day = String(d.getDate()).padStart(2, '0');
	return `${d.getFullYear()}-${m}-${day}`;
}

/** Whole days between two local calendar-day keys. */
function daysBetween(fromKey: string, toKey: string): number {
	const a = new Date(`${fromKey}T00:00:00`).getTime();
	const b = new Date(`${toKey}T00:00:00`).getTime();
	if (Number.isNaN(a) || Number.isNaN(b)) return 0;
	return Math.max(0, Math.round((b - a) / 86_400_000));
}

/**
 * How long this device has been with us, in whole days (0 on the first day).
 * Stamped lazily on first read so it costs nothing until something asks.
 *
 * Also the value reported as `dayIndex` in telemetry — without it, "did anyone
 * come back on a second day?" stays unanswerable, which is the one question
 * the whole free-tier decision rests on.
 */
export function deviceDayIndex(now: number = Date.now()): number {
	const t = today(now);
	if (typeof localStorage === 'undefined') return 0;
	try {
		const first = localStorage.getItem(FIRST_SEEN_KEY);
		if (!first) {
			localStorage.setItem(FIRST_SEEN_KEY, t);
			return 0;
		}
		return daysBetween(first, t);
	} catch {
		return 0;
	}
}

/**
 * Sessions a free user may run today.
 *
 * Infinity while the device is inside the unlimited window. The window exists
 * so the limit can be reintroduced later without another release — change the
 * number, not the call sites.
 */
export function effectiveDailyLimit(now: number = Date.now()): number {
	if (deviceDayIndex(now) < FREE_LIMITS.unlimitedDays) return Infinity;
	return FREE_LIMITS.coachSessionsPerDay;
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
	const limit = effectiveDailyLimit(now);
	if (limit === Infinity) return Infinity;
	return Math.max(0, limit - read(now).count);
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
 *
 * Call this at the point the first block begins, never when the plan is merely
 * built (rule 1). Safe to call for Pro users — the counter is simply ignored
 * for them, which keeps the call site free of tier branching.
 *
 * `kind` is the first block's type. A calibration session is a placement test,
 * not practice, and must never be billed as the day's allowance (rule 2) —
 * that bug put a brand-new user in front of the paywall having played nothing.
 */
export function recordCoachSessionStart(
	opts: { kind?: string; now?: number } = {},
): void {
	const { kind, now } = opts;
	if (kind === 'calibrate') return;
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
