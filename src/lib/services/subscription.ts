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
 *
 * The rule behind this split (see docs/MONETARISIERUNG.md):
 * free is everything that BUILDS the habit, paid is everything that
 * AMPLIFIES, ACCELERATES or PRESERVES it. Nothing a first-week user needs
 * sits behind the wall.
 *
 * Note what is deliberately NOT gated: the courses (our reach and SEO engine),
 * every voicing type (a crippled free tier teaches a fragment of jazz and earns
 * bad word of mouth — currently our only channel), MIDI and microphone input
 * (the one reason someone picks us over the iOS competitors), and the coach's
 * QUALITY. Only the coach's daily VOLUME is limited, never how good it is.
 */
export const FEATURE_GATES: Record<string, SubscriptionTier> = {
	// ─── Free ("Übung") — a genuinely strong free tier ───
	'courses': 'free',
	'speed-drill-random': 'free',
	'shell-voicings': 'free',
	'all-voicing-types': 'free',
	'voice-leading': 'free',
	'progressions': 'free',
	'midi-input': 'free',
	'microphone-input': 'free',
	'habit-basic': 'free',
	'i18n': 'free',
	/** Unlimited free practice — the release valve that keeps the daily coach
	 *  limit feeling like an offer rather than a lockout. Never gate this. */
	'free-practice': 'free',
	/** To-Go without an instrument: the three disciplines that carry the
	 *  free tier. The other four are Studio (see 'togo-full'). */
	'togo-basic': 'free',

	// ─── Studio (tier key 'pro') — volume, memory and depth ───
	/** More than one coach session per day. The one limit a motivated user
	 *  feels daily, and the primary reason to upgrade. */
	'unlimited-coach-sessions': 'pro',
	/** The remaining four To-Go disciplines: sing, time, lick, progression. */
	'togo-full': 'pro',
	/** History beyond the free tier's rolling 7-day window. */
	'full-history': 'pro',
	'adaptive-difficulty': 'pro',
	'custom-progressions': 'pro',
	'advanced-stats': 'pro',
	'cloud-sync': 'pro',

	// ─── Lehrpult (tier key 'educator') ───
	'embed-widget': 'educator',
	'student-progress': 'educator',
	'student-seats': 'educator',
	'assignments': 'educator',

	// ─── Institut (tier key 'institution') ───
	'custom-branding': 'institution',
	'lms-integration': 'institution',
	'api-access': 'institution',
	'sso': 'institution',
};

/**
 * Free-tier limits. Enforcement lives with the features themselves
 * (coach session start, history read) — this is the single place the
 * numbers are defined so they can be tuned without hunting through the UI.
 */
export const FREE_LIMITS = {
	/** Coach sessions per calendar day on the free tier. */
	coachSessionsPerDay: 1,
	/** Days of practice history visible on the free tier. */
	historyDays: 7,
} as const;

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
