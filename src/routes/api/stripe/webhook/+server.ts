import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import Stripe from 'stripe';
import { STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, STRIPE_PRICE_PRO, STRIPE_PRICE_EDUCATOR, STRIPE_PRICE_INSTITUTION } from '$env/static/private';

const stripe = new Stripe(STRIPE_SECRET_KEY);

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
			const sub = subscription as unknown as Record<string, unknown>;

			await supabaseAdmin.from('subscriptions').upsert({
				user_id: userId,
				stripe_subscription_id: subscription.id,
				stripe_customer_id: session.customer as string,
				tier,
				status: subscription.status,
				current_period_start: new Date((sub.current_period_start as number) * 1000).toISOString(),
				current_period_end: new Date((sub.current_period_end as number) * 1000).toISOString(),
				price_id: priceId,
			}, { onConflict: 'user_id' });

			break;
		}

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
			const sub = subscription as unknown as Record<string, unknown>;

			await supabaseAdmin.from('subscriptions').upsert({
				user_id: profile.id,
				stripe_subscription_id: subscription.id,
				stripe_customer_id: customerId,
				tier,
				status: subscription.status,
				current_period_start: new Date((sub.current_period_start as number) * 1000).toISOString(),
				current_period_end: new Date((sub.current_period_end as number) * 1000).toISOString(),
				price_id: priceId,
			}, { onConflict: 'user_id' });

			break;
		}

		case 'invoice.payment_failed': {
			const invoice = event.data.object as Stripe.Invoice;
			const customerId = invoice.customer as string;
			console.warn(`[Stripe] Payment failed for customer ${customerId}`);
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
