import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

const VALID_TIERS = ['free', 'pro', 'educator', 'institution'] as const;
type Tier = (typeof VALID_TIERS)[number];

/**
 * Admin-only: gift a subscription tier to a user by email (no Stripe charge).
 * Writes a synthetic subscriptions row so the app treats them as a paying member.
 * POST { email: string, tier: 'free'|'pro'|'educator'|'institution', revoke?: boolean }
 */
export const POST: RequestHandler = async ({ request, locals }) => {
	const { user } = await locals.safeGetSession();
	if (!user) throw error(401, 'Not authenticated');

	// Verify caller is an admin.
	const { data: me } = await locals.supabaseAdmin
		.from('profiles')
		.select('role')
		.eq('id', user.id)
		.single();
	if (me?.role !== 'admin') throw error(403, 'Admin only');

	const { email, tier, revoke } = await request.json();
	if (!email || typeof email !== 'string') throw error(400, 'Email required');
	if (!revoke && !VALID_TIERS.includes(tier)) throw error(400, 'Invalid tier');

	// Resolve the target user by email via the admin auth API.
	const { data: list, error: listErr } = await locals.supabaseAdmin.auth.admin.listUsers();
	if (listErr) throw error(500, 'Lookup failed');
	const target = list.users.find(
		(u) => u.email?.toLowerCase() === email.trim().toLowerCase(),
	);
	if (!target) throw error(404, 'No user with that email');

	if (revoke) {
		// Revoke a gifted membership (only touch admin grants, never real Stripe subs).
		await locals.supabaseAdmin
			.from('subscriptions')
			.update({ tier: 'free', status: 'canceled' })
			.eq('user_id', target.id)
			.like('stripe_subscription_id', 'admin_grant_%');
		return json({ ok: true, action: 'revoked', email: target.email });
	}

	const farFuture = new Date();
	farFuture.setFullYear(farFuture.getFullYear() + 100);

	const { error: upsertErr } = await locals.supabaseAdmin.from('subscriptions').upsert(
		{
			user_id: target.id,
			stripe_subscription_id: `admin_grant_${target.id}`,
			stripe_customer_id: null,
			tier: tier as Tier,
			status: 'active',
			current_period_start: new Date().toISOString(),
			current_period_end: farFuture.toISOString(),
			price_id: null,
		},
		{ onConflict: 'user_id' },
	);
	if (upsertErr) throw error(500, `Grant failed: ${upsertErr.message}`);

	return json({ ok: true, action: 'granted', tier, email: target.email });
};
