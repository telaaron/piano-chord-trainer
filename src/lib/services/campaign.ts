// Which campaign a visit came from (utm_* on the landing URL), so coach
// telemetry can say whether the weekly practice mail brought someone back.
//
// Kept in sessionStorage: it belongs to this visit (this tab), survives the
// click from a /learn lesson into /train, and is gone with the tab. Not
// linked to anything personal; the mail link carries only the campaign name.

const KEY = 'chord-trainer-campaign';
const MAX = 64;

interface Storage {
	getItem(key: string): string | null;
	setItem(key: string, value: string): void;
}

export interface Campaign {
	source: string | null;
	medium: string | null;
	campaign: string | null;
}

export function captureCampaign(url: URL, storage: Storage | null): void {
	if (!storage) return;
	const get = (k: string) => url.searchParams.get(k)?.slice(0, MAX) || null;
	const c: Campaign = { source: get('utm_source'), medium: get('utm_medium'), campaign: get('utm_campaign') };
	if (!c.source && !c.medium && !c.campaign) return;
	try {
		storage.setItem(KEY, JSON.stringify(c));
	} catch {
		/* storage blocked: the visit simply goes unattributed */
	}
}

export function getCampaign(storage: Storage | null): Campaign | null {
	if (!storage) return null;
	try {
		const raw = storage.getItem(KEY);
		return raw ? (JSON.parse(raw) as Campaign) : null;
	} catch {
		return null;
	}
}
