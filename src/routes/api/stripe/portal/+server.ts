import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import Stripe from 'stripe';
import { STRIPE_SECRET_KEY } from '$env/static/private';

const stripe = new Stripe(STRIPE_SECRET_KEY);

export const POST: RequestHandler = async ({ request, locals }) => {
	const { user } = await locals.safeGetSession();
	if (!user) throw error(401, 'Not authenticated');

	const { data: profile } = await locals.supabaseAdmin
		.from('profiles')
		.select('stripe_customer_id')
		.eq('id', user.id)
		.single();

	if (!profile?.stripe_customer_id) {
		throw error(400, 'No subscription found');
	}

	const portalSession = await stripe.billingPortal.sessions.create({
		customer: profile.stripe_customer_id,
		return_url: `${request.headers.get('origin')}/account`,
	});

	return json({ url: portalSession.url });
};
