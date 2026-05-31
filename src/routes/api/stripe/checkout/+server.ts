import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import Stripe from 'stripe';
import { STRIPE_SECRET_KEY } from '$env/static/private';

const stripe = new Stripe(STRIPE_SECRET_KEY);

export const POST: RequestHandler = async ({ request, locals }) => {
	const { session, user } = await locals.safeGetSession();
	if (!user) throw error(401, 'Not authenticated');

	const { priceId } = await request.json();
	if (!priceId || typeof priceId !== 'string') throw error(400, 'Invalid price ID');

	// Get or create Stripe customer
	const { data: profile } = await locals.supabaseAdmin
		.from('profiles')
		.select('stripe_customer_id')
		.eq('id', user.id)
		.single();

	let customerId = profile?.stripe_customer_id;

	if (!customerId) {
		const customer = await stripe.customers.create({
			email: user.email,
			metadata: { supabase_user_id: user.id },
		});
		customerId = customer.id;
		await locals.supabaseAdmin
			.from('profiles')
			.update({ stripe_customer_id: customerId })
			.eq('id', user.id);
	}

	const checkoutSession = await stripe.checkout.sessions.create({
		customer: customerId,
		mode: 'subscription',
		line_items: [{ price: priceId, quantity: 1 }],
		// Grand-slam offer: 14 days free, no charge until trial ends.
		subscription_data: {
			trial_period_days: 14,
			metadata: { supabase_user_id: user.id },
		},
		// Collect card up front so billing continues seamlessly after the trial.
		payment_method_collection: 'always',
		allow_promotion_codes: true,
		success_url: `${request.headers.get('origin')}/account?checkout=success`,
		cancel_url: `${request.headers.get('origin')}/pricing?checkout=cancelled`,
		metadata: { supabase_user_id: user.id },
	});

	return json({ url: checkoutSession.url });
};
