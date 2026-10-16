import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { CONSENT_TEXT_VERSION, consentText } from '$lib/consent';
import { brevoConfig, listState, sendDoubleOptIn } from '$lib/server/brevo';

/**
 * Weekly practice mail opt-in, asked right after the first finished session.
 *
 *   POST { email, locale?, website? }  → { status: 'pending' | 'confirmed' }
 *
 * Works without an account: most people who finish a block never sign up.
 * The row carries no device id — the privacy policy promises the telemetry
 * id is never linked to an address. Signed-in callers are linked by user id.
 *
 * Anyone can call this, so it must not become a way to mail strangers: the
 * only mail it triggers is Brevo's double opt-in, at most one per address per
 * day, with a global hourly cap. `website` is a honeypot field a person never
 * sees; a bot that fills it gets a normal-looking answer and nothing happens.
 */

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const HOURLY_CAP = 30;
const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

export const POST: RequestHandler = async ({ locals, request, url }) => {
	let body: { email?: unknown; locale?: unknown; website?: unknown };
	try {
		body = await request.json();
	} catch {
		throw error(400, 'Invalid body');
	}

	const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
	if (!EMAIL_RE.test(email) || email.length > 254) throw error(400, 'Invalid email');
	if (typeof body.website === 'string' && body.website !== '') return json({ status: 'pending' });

	const cfg = brevoConfig();
	if (!cfg) throw error(503, 'Email is not set up');

	const admin = locals.supabaseAdmin;
	const since = (ms: number) => new Date(Date.now() - ms).toISOString();

	if ((await listState(cfg, email)) === 'subscribed') return json({ status: 'confirmed' });

	const { count: recent } = await admin
		.from('email_consents')
		.select('id', { count: 'exact', head: true })
		.ilike('email', email)
		.gte('created_at', since(DAY_MS));
	if ((recent ?? 0) > 0) return json({ status: 'pending' });

	const { count: lastHour } = await admin
		.from('email_consents')
		.select('id', { count: 'exact', head: true })
		.is('user_id', null)
		.eq('source', 'prompt')
		.gte('created_at', since(HOUR_MS));
	if ((lastHour ?? 0) >= HOURLY_CAP) throw error(429, 'Too many requests');

	const { user } = await locals.safeGetSession();
	const locale = typeof body.locale === 'string' ? body.locale.slice(0, 8) : 'en';
	const { error: err } = await admin.from('email_consents').insert({
		user_id: user?.id ?? null,
		email,
		status: 'pending',
		source: 'prompt',
		consent_text: consentText(locale),
		text_version: CONSENT_TEXT_VERSION,
	});
	if (err) {
		console.error('[practice-reminder] insert failed:', err.message);
		throw error(500, 'Could not save consent');
	}

	const sent = await sendDoubleOptIn(cfg, email, `${url.origin}/updates/confirmed`);
	return json({ status: 'pending', sent });
};
