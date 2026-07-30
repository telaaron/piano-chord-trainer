import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/**
 * Public: accept a note from the /feedback page.
 *
 * Unlike every other endpoint here this one has no auth gate — a stranger who
 * has never signed up is exactly who it is for. That makes the validation below
 * the only thing standing in front of the table, so it is deliberate rather
 * than incidental:
 *
 *   - the message is length-capped here AND in the column (a public endpoint
 *     should not rely on the form to bound what reaches the database);
 *   - user_id is read from the session, never from the body, so a caller
 *     cannot attribute their note to somebody else;
 *   - one IP gets a small burst, so the table cannot be flooded from a loop.
 */

const MAX_MESSAGE = 4000;
const MAX_EMAIL = 320;

/**
 * In-memory throttle. Per-instance and lost on restart — enough to stop a
 * naive flood, and honestly not a defence against a determined one. A real
 * limiter belongs at the edge, but that is infrastructure this project does
 * not have yet, and an unbounded public insert is the worse of the two.
 */
const hits = new Map<string, number[]>();
const WINDOW_MS = 60 * 60 * 1000;
const MAX_PER_WINDOW = 5;

function rateLimited(ip: string, now: number): boolean {
	const recent = (hits.get(ip) ?? []).filter((t) => now - t < WINDOW_MS);
	if (recent.length >= MAX_PER_WINDOW) {
		hits.set(ip, recent);
		return true;
	}
	recent.push(now);
	hits.set(ip, recent);
	// Keep the map from growing without bound on a long-lived instance.
	if (hits.size > 5000) {
		for (const [key, times] of hits) {
			if (times.every((t) => now - t >= WINDOW_MS)) hits.delete(key);
		}
	}
	return false;
}

export const POST: RequestHandler = async ({ request, locals, getClientAddress }) => {
	let body: { message?: unknown; email?: unknown; locale?: unknown };
	try {
		body = await request.json();
	} catch {
		throw error(400, 'Invalid body');
	}

	const message = typeof body.message === 'string' ? body.message.trim() : '';
	if (!message) throw error(400, 'Message required');
	if (message.length > MAX_MESSAGE) throw error(400, 'Message too long');

	const rawEmail = typeof body.email === 'string' ? body.email.trim() : '';
	// Deliberately loose: this address exists so the owner can reply, and
	// rejecting an unusual-but-valid address costs more than accepting a typo.
	if (rawEmail && (rawEmail.length > MAX_EMAIL || !/^\S+@\S+\.\S+$/.test(rawEmail))) {
		throw error(400, 'Invalid email');
	}

	const locale = typeof body.locale === 'string' ? body.locale.slice(0, 10) : null;

	let ip = 'unknown';
	try {
		ip = getClientAddress();
	} catch {
		// Adapter may not expose one; the throttle then simply groups them.
	}
	if (rateLimited(ip, Date.now())) throw error(429, 'Too many messages');

	// Attribution comes from the session, never the body.
	let userId: string | null = null;
	try {
		const { user } = await locals.safeGetSession();
		userId = user?.id ?? null;
	} catch {
		userId = null;
	}

	const { error: insertErr } = await locals.supabaseAdmin.from('feedback').insert({
		message,
		email: rawEmail || null,
		user_id: userId,
		locale,
	});
	// Log server-side, but do not hand the database's message back to a public
	// caller — it would leak schema detail to anyone who posts malformed data.
	if (insertErr) {
		console.error('[feedback] insert failed:', insertErr.message);
		throw error(500, 'Could not save message');
	}

	return json({ ok: true });
};
