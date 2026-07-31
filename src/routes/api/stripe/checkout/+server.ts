import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import Stripe from 'stripe';
import {
	STRIPE_SECRET_KEY,
	STRIPE_PRICE_PRO,
	STRIPE_PRICE_PRO_YEARLY,
	STRIPE_PRICE_EDUCATOR,
	STRIPE_PRICE_EDUCATOR_YEARLY,
	STRIPE_PRICE_INSTITUTION,
} from '$env/static/private';

const stripe = new Stripe(STRIPE_SECRET_KEY);

/**
 * Plan key → price. 'pro' is Studio, 'educator' is Lehrpult (the tier keys stay
 * as they are because Stripe metadata and the subscriptions table use them).
 *
 * Institut is invoiced by hand — public institutions generally cannot pay by
 * card — so it has no self-service price and resolves to '' here.
 */
const PLAN_PRICE: Record<string, string> = {
	pro: STRIPE_PRICE_PRO,
	'pro-yearly': STRIPE_PRICE_PRO_YEARLY,
	educator: STRIPE_PRICE_EDUCATOR,
	'educator-yearly': STRIPE_PRICE_EDUCATOR_YEARLY,
	institution: STRIPE_PRICE_INSTITUTION,
};

export const POST: RequestHandler = async ({ request, locals }) => {
	const { session, user } = await locals.safeGetSession();
	if (!user) throw error(401, 'Not authenticated');

	const body = await request.json();
	// Accept either an explicit priceId (pricing page) or a plan key (upgrade sheet).
	const priceId: string | undefined =
		typeof body.priceId === 'string' ? body.priceId : PLAN_PRICE[body.plan];
	// Institut resolves to an empty string by design — say so plainly rather than
	// letting an empty price reach Stripe and come back as a cryptic error.
	if (body.plan === 'institution') {
		throw error(400, 'Institut is arranged by invoice — please get in touch.');
	}
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
		// Seven days free. Someone who practises daily has felt the value well
		// inside a week; someone who hasn't returned by day 7 won't by day 14 —
		// the longer trial only delays the decision.
		subscription_data: {
			trial_period_days: 7,
			// No card on file means Stripe cannot silently charge at trial end.
			// Cancel instead, and let the app ask for the upgrade in context.
			trial_settings: {
				end_behavior: { missing_payment_method: 'cancel' },
			},
			metadata: { supabase_user_id: user.id },
		},
		// Deliberately NOT collecting a card up front. The landing page promises
		// "Free. No signup." — asking for card details in the same product breaks
		// that promise. At our signup volume every deterred trial start costs more
		// than the conversion a card requirement would have bought.
		payment_method_collection: 'if_required',
		allow_promotion_codes: true,
		success_url: `${request.headers.get('origin')}/account?checkout=success`,
		cancel_url: `${request.headers.get('origin')}/pricing?checkout=cancelled`,
		metadata: { supabase_user_id: user.id },
	});

	return json({ url: checkoutSession.url });
};
