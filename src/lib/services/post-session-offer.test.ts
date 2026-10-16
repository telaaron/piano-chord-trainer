import { describe, it, expect } from 'vitest';
import { nextOffer, MAIL_OFFER_KEY, SYNC_OFFER_KEY } from './post-session-offer';

/** A Map that behaves like the slice of localStorage the decision uses. */
function store(init: Record<string, string> = {}) {
	const m = new Map(Object.entries(init));
	return {
		getItem: (k: string) => m.get(k) ?? null,
		setItem: (k: string, v: string) => void m.set(k, v),
		has: (k: string) => m.has(k),
	};
}

describe('nextOffer', () => {
	it('asks for the practice mail first, once', () => {
		const s = store();
		expect(nextOffer(s, { kind: 'coach', signedIn: false })).toBe('mail');
		expect(s.has(MAIL_OFFER_KEY)).toBe(true);
	});

	it('then offers the account on the next coach session, never twice', () => {
		const s = store({ [MAIL_OFFER_KEY]: '1' });
		expect(nextOffer(s, { kind: 'coach', signedIn: false })).toBe('sync');
		expect(nextOffer(s, { kind: 'coach', signedIn: false })).toBeNull();
	});

	it('never after calibration, which is a placement test, not practice', () => {
		const s = store();
		expect(nextOffer(s, { kind: 'coach', firstBlockKind: 'calibrate', signedIn: false })).toBeNull();
		expect(s.has(MAIL_OFFER_KEY)).toBe(false);
	});

	it('a finished free drill counts for the mail, but does not bring the account offer', () => {
		expect(nextOffer(store(), { kind: 'drill', signedIn: false })).toBe('mail');
		expect(nextOffer(store({ [MAIL_OFFER_KEY]: '1' }), { kind: 'drill', signedIn: false })).toBeNull();
	});

	it('signed-in people get the mail offer but no account offer', () => {
		expect(nextOffer(store(), { kind: 'coach', signedIn: true })).toBe('mail');
		expect(nextOffer(store({ [MAIL_OFFER_KEY]: '1' }), { kind: 'coach', signedIn: true })).toBeNull();
	});

	it('someone who already saw the account offer still gets the mail offer once', () => {
		const s = store({ [SYNC_OFFER_KEY]: '1' });
		expect(nextOffer(s, { kind: 'coach', signedIn: false })).toBe('mail');
		expect(nextOffer(s, { kind: 'coach', signedIn: false })).toBeNull();
	});

	it('without storage it asks nothing rather than asking every time', () => {
		const broken = {
			getItem: () => {
				throw new Error('blocked');
			},
			setItem: () => {
				throw new Error('blocked');
			},
		};
		expect(nextOffer(broken, { kind: 'coach', signedIn: false })).toBeNull();
		expect(nextOffer(null, { kind: 'coach', signedIn: false })).toBeNull();
	});
});
