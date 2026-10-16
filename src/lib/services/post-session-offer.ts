// What to ask after a finished session, if anything.
//
// Two offers compete for the same moment: the weekly practice mail (a reason
// to come back next week, works without an account) and the free account
// (keeps anonymous progress from vanishing with a cleared browser). Showing
// both at once is a wall, so the mail comes first, after the first finished
// session of any kind; the account offer keeps its old rule (coach sessions,
// anonymous only) and waits for the next session. Each is asked once per
// device, and never after calibration, which is a placement test.

export const MAIL_OFFER_KEY = 'chord-trainer-mail-offer-shown';
export const SYNC_OFFER_KEY = 'chord-trainer-sync-offer-shown';

export type Offer = 'mail' | 'sync' | null;

interface Storage {
	getItem(key: string): string | null;
	setItem(key: string, value: string): void;
}

export interface SessionInfo {
	kind: 'coach' | 'drill';
	firstBlockKind?: string;
	signedIn: boolean;
}

/** Decides the offer and marks it as shown. Without storage, asks nothing. */
export function nextOffer(storage: Storage | null, session: SessionInfo): Offer {
	if (!storage) return null;
	if (session.firstBlockKind === 'calibrate') return null;
	try {
		if (!storage.getItem(MAIL_OFFER_KEY)) {
			storage.setItem(MAIL_OFFER_KEY, '1');
			return 'mail';
		}
		if (session.kind !== 'coach' || session.signedIn) return null;
		if (storage.getItem(SYNC_OFFER_KEY)) return null;
		storage.setItem(SYNC_OFFER_KEY, '1');
		return 'sync';
	} catch {
		return null; // no way to remember: rather ask never than every time
	}
}
