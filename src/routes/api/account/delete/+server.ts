import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { brevoConfig, deleteContact } from '$lib/server/brevo';

export const POST: RequestHandler = async ({ locals }) => {
	const { user } = await locals.safeGetSession();
	if (!user) throw error(401, 'Not authenticated');

	// Delete user data
	await locals.supabaseAdmin.from('user_data').delete().eq('user_id', user.id);
	await locals.supabaseAdmin.from('subscriptions').delete().eq('user_id', user.id);
	await locals.supabaseAdmin.from('profiles').delete().eq('id', user.id);

	// The mailing contact goes with the account (email_consents cascades).
	const brevo = brevoConfig();
	if (brevo && user.email) {
		await deleteContact(brevo, user.email).catch((e) =>
			console.error('[Account Delete] Brevo contact not removed:', e),
		);
	}

	// Delete auth user
	const { error: authError } = await locals.supabaseAdmin.auth.admin.deleteUser(user.id);
	if (authError) {
		console.error('[Account Delete] Failed:', authError.message);
		throw error(500, 'Failed to delete account');
	}

	return json({ success: true });
};
