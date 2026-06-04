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
