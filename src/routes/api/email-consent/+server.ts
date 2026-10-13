import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import type { SupabaseClient, User } from '@supabase/supabase-js';
import { CONSENT_TEXT_VERSION, consentText, type ConsentStatus } from '$lib/consent';
import { brevoConfig, listState, removeFromList, sendDoubleOptIn } from '$lib/server/brevo';

/**
 * Product-update email consent for the signed-in user.
 *
 *   GET  → current status. Also settles anything outstanding: an opt-in ticked
 *          at signup (stored in user metadata until the account was confirmed)
 *          is recorded and its double opt-in sent, and a pending or confirmed
 *          state is reconciled with Brevo (confirmation click, unsubscribe link).
 *   POST { subscribe: boolean, source?: 'account' | 'prompt', locale? }
 *
 * Every change is a new row in email_consents, written with the service role:
 * the client can ask, never record.
 */

type Source = 'signup' | 'account' | 'prompt' | 'brevo';

async function currentStatus(admin: SupabaseClient, userId: string): Promise<ConsentStatus | null> {
	const { data } = await admin
		.from('email_consents')
		.select('status')
		.eq('user_id', userId)
		.order('created_at', { ascending: false })
		.limit(1)
		.maybeSingle();
	if (!data) return null;
	return data.status === 'withdrawn' ? 'none' : (data.status as ConsentStatus);
}

async function record(
	admin: SupabaseClient,
	user: User,
	status: 'pending' | 'confirmed' | 'withdrawn',
	source: Source,
	locale?: string,
): Promise<void> {
	const withText = status === 'pending';
	const { error: err } = await admin.from('email_consents').insert({
		user_id: user.id,
		email: user.email,
		status,
		source,
		consent_text: withText ? consentText(locale) : null,
		text_version: withText ? CONSENT_TEXT_VERSION : null,
	});
	if (err) {
		console.error('[email-consent] insert failed:', err.message);
		throw error(500, 'Could not save consent');
	}
}

async function startOptIn(user: User, origin: string): Promise<boolean> {
	const cfg = brevoConfig();
	if (!cfg || !user.email) return false;
	return sendDoubleOptIn(cfg, user.email, `${origin}/account?updates=confirmed`);
}

export const GET: RequestHandler = async ({ locals, url }) => {
	const { user } = await locals.safeGetSession();
	if (!user?.email) throw error(401, 'Not authenticated');
	const admin = locals.supabaseAdmin;
	const cfg = brevoConfig();

	let status = await currentStatus(admin, user.id);

	// Ticked at signup, before the account existed to record it against.
	const meta = user.user_metadata ?? {};
	if (status === null && meta.email_updates_opt_in === true) {
		const locale = typeof meta.locale === 'string' ? meta.locale : 'en';
		await record(admin, user, 'pending', 'signup', locale);
		await startOptIn(user, url.origin);
		status = 'pending';
	}

	// Brevo knows about the confirmation click and the unsubscribe link.
	if (cfg && (status === 'pending' || status === 'confirmed')) {
		const state = await listState(cfg, user.email);
		if (status === 'pending' && state === 'subscribed') {
			await record(admin, user, 'confirmed', 'brevo');
			status = 'confirmed';
		} else if (state === 'unsubscribed') {
			await record(admin, user, 'withdrawn', 'brevo');
			status = 'none';
		}
	}

	return json({ status: status ?? 'none', configured: cfg !== null });
};

export const POST: RequestHandler = async ({ locals, request, url }) => {
	const { user } = await locals.safeGetSession();
	if (!user?.email) throw error(401, 'Not authenticated');

	let body: { subscribe?: unknown; source?: unknown; locale?: unknown };
	try {
		body = await request.json();
	} catch {
		throw error(400, 'Invalid body');
	}
	if (typeof body.subscribe !== 'boolean') throw error(400, 'subscribe must be boolean');
	const source: Source = body.source === 'prompt' ? 'prompt' : 'account';
	const locale = typeof body.locale === 'string' ? body.locale.slice(0, 8) : 'en';

	const admin = locals.supabaseAdmin;
	const status = await currentStatus(admin, user.id);
	const cfg = brevoConfig();

	if (body.subscribe) {
		if (status === 'confirmed') return json({ status, configured: cfg !== null });
		await record(admin, user, 'pending', source, locale);
		const sent = await startOptIn(user, url.origin);
		return json({ status: 'pending', configured: cfg !== null, sent });
	}

	if (status !== null && status !== 'none') {
		await record(admin, user, 'withdrawn', source);
		if (cfg) await removeFromList(cfg, user.email);
	}
	return json({ status: 'none', configured: cfg !== null });
};
