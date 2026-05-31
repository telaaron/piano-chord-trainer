import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import Stripe from 'stripe';
import { STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, STRIPE_PRICE_PRO, STRIPE_PRICE_EDUCATOR, STRIPE_PRICE_INSTITUTION } from '$env/static/private';

const stripe = new Stripe(STRIPE_SECRET_KEY);

/**
 * Stripe API 2025-x moved current_period_start/end off the subscription
 * top-level onto each subscription item. Read from the item first, fall back
 * to the (legacy) top-level, and tolerate either being absent.
 */
function periodBounds(subscription: Stripe.Subscription): {
	current_period_start: string | null;
	current_period_end: string | null;
} {
	const item = subscription.items?.data?.[0] as unknown as Record<string, unknown> | undefined;
	const sub = subscription as unknown as Record<string, unknown>;
	const start = (item?.current_period_start ?? sub.current_period_start) as number | undefined;
	const end = (item?.current_period_end ?? sub.current_period_end) as number | undefined;
	return {
		current_period_start: typeof start === 'number' ? new Date(start * 1000).toISOString() : null,
		current_period_end: typeof end === 'number' ? new Date(end * 1000).toISOString() : null,
	};
}

export const POST: RequestHandler = async ({ request, locals }) => {
	const body = await request.text();
	const signature = request.headers.get('stripe-signature');

	if (!signature) {
		return json({ error: 'Missing signature' }, { status: 400 });
	}

	let event: Stripe.Event;
	try {
		event = stripe.webhooks.constructEvent(body, signature, STRIPE_WEBHOOK_SECRET);
	} catch (err) {
		const message = err instanceof Error ? err.message : 'Unknown error';
		console.error('[Stripe Webhook] Verification failed:', message);
		return json({ error: 'Invalid signature' }, { status: 400 });
	}

	const supabaseAdmin = locals.supabaseAdmin;

	switch (event.type) {
		case 'checkout.session.completed': {
			const session = event.data.object as Stripe.Checkout.Session;
			const userId = session.metadata?.supabase_user_id;
			if (!userId || !session.subscription) break;

			const subscription = await stripe.subscriptions.retrieve(session.subscription as string);
			const priceId = subscription.items.data[0]?.price?.id;
			const tier = priceIdToTier(priceId);

			await supabaseAdmin.from('subscriptions').upsert({
				user_id: userId,
				stripe_subscription_id: subscription.id,
				stripe_customer_id: session.customer as string,
				tier,
				status: subscription.status,
				...periodBounds(subscription),
				price_id: priceId,
			}, { onConflict: 'user_id' });

			break;
		}

		case 'customer.subscription.created':
		case 'customer.subscription.updated':
		case 'customer.subscription.deleted': {
			const subscription = event.data.object as Stripe.Subscription;
			const customerId = subscription.customer as string;

			// Find user by stripe customer id
			const { data: profile } = await supabaseAdmin
				.from('profiles')
				.select('id')
				.eq('stripe_customer_id', customerId)
				.single();

			if (!profile) break;

			const priceId = subscription.items.data[0]?.price?.id;
			const tier = priceIdToTier(priceId);

			await supabaseAdmin.from('subscriptions').upsert({
				user_id: profile.id,
				stripe_subscription_id: subscription.id,
				stripe_customer_id: customerId,
				tier,
				status: subscription.status,
				...periodBounds(subscription),
				price_id: priceId,
			}, { onConflict: 'user_id' });

			break;
		}

		case 'invoice.payment_failed': {
			const invoice = event.data.object as Stripe.Invoice;
			const customerId = invoice.customer as string;
			console.warn(`[Stripe] Payment failed for customer ${customerId}`);
			// Reflect the dunning state so the app can prompt the user.
			const { data: profile } = await supabaseAdmin
				.from('profiles')
				.select('id')
				.eq('stripe_customer_id', customerId)
				.single();
			if (profile) {
				await supabaseAdmin
					.from('subscriptions')
					.update({ status: 'past_due' })
					.eq('user_id', profile.id);
			}
			break;
		}

		case 'customer.subscription.trial_will_end': {
			// 3 days before trial ends — info only (hook for a reminder email later).
			const subscription = event.data.object as Stripe.Subscription;
			console.info(`[Stripe] Trial ending soon for customer ${subscription.customer}`);
			break;
		}

		default:
			break;
	}

	return json({ received: true });
};

function priceIdToTier(priceId: string | undefined): string {
	if (!priceId) return 'free';
	if (priceId === STRIPE_PRICE_PRO) return 'pro';
	if (priceId === STRIPE_PRICE_EDUCATOR) return 'educator';
	if (priceId === STRIPE_PRICE_INSTITUTION) return 'institution';
	return 'free';
}
