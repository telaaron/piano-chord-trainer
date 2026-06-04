// One-time "try before you buy" tracking. Certain Pro features (adaptive
// coaching, advanced stats) let a free user experience them once — that aha
// moment converts far better than a cold paywall. After the first taste we
// remember it and show the upgrade prompt instead.

const KEY = (feature: string) => `chord-trainer-teaser:${feature}`;

export function hasUsedTeaser(feature: string): boolean {
	if (typeof localStorage === 'undefined') return false;
	return localStorage.getItem(KEY(feature)) === '1';
}

export function markTeaserUsed(feature: string): void {
	if (typeof localStorage === 'undefined') return;
	try {
		localStorage.setItem(KEY(feature), '1');
	} catch {
		/* storage full / blocked — non-critical */
	}
}

/** Reset (e.g. for testing or when a user upgrades then downgrades). */
export function resetTeaser(feature: string): void {
	if (typeof localStorage === 'undefined') return;
	localStorage.removeItem(KEY(feature));
}
