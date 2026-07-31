// Reactive Pro-status — components read this instead of calling the async
// getSubscription() at every gate. Loads on auth change; honors beta mode.
import { onAuthChange } from './auth';
import {
	getSubscription,
	hasAccess,
	FEATURE_GATES,
	isBeta as isBetaFlag,
	type SubscriptionTier,
} from './subscription';
import { hasFreeSessionLeft, remainingFreeSessions } from './usage-limit';

interface ProState {
	tier: SubscriptionTier;
	/** True when the user has full access (beta, or a paid tier). */
	isPro: boolean;
	isBeta: boolean;
	loading: boolean;
}

const state = $state<ProState>({
	tier: 'free',
	isPro: isBetaFlag(),
	isBeta: isBetaFlag(),
	loading: true,
});

let started = false;

/** Call once (layout) to keep the store in sync with auth. */
export function initSubscriptionStore(): () => void {
	if (started) return () => {};
	started = true;
	const unsub = onAuthChange(async () => {
		await refreshSubscription();
	});
	// Initial load (covers the already-signed-in case).
	void refreshSubscription();
	return unsub;
}

export async function refreshSubscription(): Promise<void> {
	state.loading = true;
	try {
		const sub = await getSubscription();
		state.tier = sub.tier;
		state.isBeta = sub.isBeta;
		state.isPro = sub.isBeta || sub.tier === 'pro' || sub.tier === 'educator' || sub.tier === 'institution';
	} catch {
		// Keep last-known state on failure.
	} finally {
		state.loading = false;
	}
}

/** Reactive accessor object — destructure in components: `const sub = subState;` */
export const subState = state;

/**
 * Reactive feature check. During beta everything is available, so no gate ever
 * shows. Once live, returns false for Pro features a free user lacks.
 */
export function canUse(feature: string): boolean {
	if (state.isBeta) return true;
	const required = FEATURE_GATES[feature] ?? 'free';
	return hasAccess(required, state.tier);
}

/** Should we *show* a lock/upgrade affordance for this feature? */
export function showLock(feature: string): boolean {
	return !state.isBeta && !canUse(feature);
}

/**
 * May the user start a coach session right now?
 *
 * Studio and above: always. Free: once per calendar day (FREE_LIMITS).
 * Callers should use this rather than combining tier and usage themselves —
 * the daily allowance is the one limit the free tier has, and it should be
 * asked about in exactly one way.
 */
export function canStartCoachSession(): boolean {
	if (state.isBeta || canUse('unlimited-coach-sessions')) return true;
	return hasFreeSessionLeft();
}

/** Free sessions left today. Meaningless for Pro — check `canUse` first. */
export function freeSessionsLeftToday(): number {
	return remainingFreeSessions();
}
