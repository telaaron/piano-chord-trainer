// Subscription service — manages tier checks client-side
// During beta: everything is free. Stripe integration is prepared but greyed out.
import { getSupabase } from './supabase';
import { getAuthState } from './auth';

export type SubscriptionTier = 'free' | 'pro' | 'educator' | 'institution';

export interface SubscriptionInfo {
	tier: SubscriptionTier;
	/** Whether the subscription is actually active (vs cancelled/past_due) */
	active: boolean;
	/** Stripe subscription end date */
	currentPeriodEnd: string | null;
	/** Whether we're in beta mode (everything free) */
	isBeta: boolean;
}

// Beta flag — set to false when launching paid tiers
const IS_BETA = false;

/**
 * Get the current user's subscription tier.
 * During beta, returns 'pro' for all features to be accessible.
 */
export async function getSubscription(): Promise<SubscriptionInfo> {
	const defaultInfo: SubscriptionInfo = {
		tier: 'free',
		active: true,
		currentPeriodEnd: null,
		isBeta: IS_BETA,
	};

	if (IS_BETA) {
		return { ...defaultInfo, tier: 'free', isBeta: true };
	}

	const { user } = getAuthState();
	if (!user) return defaultInfo;

	const supabase = getSupabase();
	const { data } = await supabase
		.from('subscriptions')
		.select('tier, status, current_period_end')
		.eq('user_id', user.id)
		.in('status', ['active', 'trialing'])
		.order('created_at', { ascending: false })
		.limit(1)
		.maybeSingle();

	if (!data) return defaultInfo;

	return {
		tier: data.tier as SubscriptionTier,
		active: true,
		currentPeriodEnd: data.current_period_end,
		isBeta: IS_BETA,
	};
}

/**
 * Check if a feature is accessible at the current tier.
 * During beta: all features are accessible.
 */
export function hasAccess(requiredTier: SubscriptionTier, currentTier: SubscriptionTier): boolean {
	if (IS_BETA) return true;

	const tierOrder: SubscriptionTier[] = ['free', 'pro', 'educator', 'institution'];
	return tierOrder.indexOf(currentTier) >= tierOrder.indexOf(requiredTier);
}

/**
 * Feature gate definitions — what tier each feature requires.
 */
export const FEATURE_GATES: Record<string, SubscriptionTier> = {
	// Free features
	'courses': 'free',
	'speed-drill-random': 'free',
	'shell-voicings': 'free',
	'midi-input': 'free',
	'microphone-input': 'free',
	'habit-basic': 'free',
	'i18n': 'free',

	// Pro features
	'adaptive-difficulty': 'pro',
	'all-voicing-types': 'pro',
	'voice-leading': 'pro',
	'custom-progressions': 'pro',
	'advanced-stats': 'pro',
	'cloud-sync': 'pro',

	// Educator features
	'embed-widget': 'educator',
	'student-progress': 'educator',

	// Institution features
	'custom-branding': 'institution',
	'lms-integration': 'institution',
	'api-access': 'institution',
	'sso': 'institution',
};

export function isFeatureAvailable(feature: string, tier: SubscriptionTier): boolean {
	if (IS_BETA) return true;
	const required = FEATURE_GATES[feature] || 'free';
	return hasAccess(required, tier);
}

export function isBeta(): boolean {
	return IS_BETA;
}

/**
 * Create a Stripe checkout session via our API.
 */
export async function createCheckoutSession(priceId: string): Promise<{ url: string | null; error: string | null }> {
	try {
		const res = await fetch('/api/stripe/checkout', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ priceId }),
		});
		const data = await res.json();
		if (!res.ok) return { url: null, error: data.error || 'Checkout failed' };
		return { url: data.url, error: null };
	} catch {
		return { url: null, error: 'Network error' };
	}
}

/**
 * Create a Stripe customer portal session for managing subscription.
 */
export async function createPortalSession(): Promise<{ url: string | null; error: string | null }> {
	try {
		const res = await fetch('/api/stripe/portal', { method: 'POST' });
		const data = await res.json();
		if (!res.ok) return { url: null, error: data.error || 'Portal error' };
		return { url: data.url, error: null };
	} catch {
		return { url: null, error: 'Network error' };
	}
}
