import type { SupabaseClient } from '@supabase/supabase-js';
import { brevoConfig, listState } from '$lib/server/brevo';

/**
 * Record the double opt-in click of an anonymous practice-mail consent.
 *
 * People without an account never open /account, which is where a signed-in
 * user's pending consent gets settled. The confirmation link carries the
 * pending row's id instead; once Brevo has the address on the list, a
 * 'confirmed' row is added that keeps the wording version of the pending row
 * it confirms. The weekly mail relies on that version (v1 does not count).
 */

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function settleConfirmation(admin: SupabaseClient, id: string): Promise<boolean> {
	const cfg = brevoConfig();
	if (!cfg || !UUID_RE.test(id)) return false;

	const { data: pending } = await admin
		.from('email_consents')
		.select('user_id, email, purpose, text_version, created_at')
		.eq('id', id)
		.eq('status', 'pending')
		.maybeSingle();
	if (!pending) return false;

	const { count: already } = await admin
		.from('email_consents')
		.select('id', { count: 'exact', head: true })
		.ilike('email', pending.email)
		.eq('purpose', pending.purpose)
		.eq('status', 'confirmed')
		.gte('created_at', pending.created_at);
	if ((already ?? 0) > 0) return false;

	if ((await listState(cfg, pending.email)) !== 'subscribed') return false;

	const { error: err } = await admin.from('email_consents').insert({
		user_id: pending.user_id,
		email: pending.email,
		purpose: pending.purpose,
		status: 'confirmed',
		source: 'brevo',
		consent_text: null,
		text_version: pending.text_version,
	});
	if (err) {
		console.error('[updates/confirmed] insert failed:', err.message);
		return false;
	}
	return true;
}
