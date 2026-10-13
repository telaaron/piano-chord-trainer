import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Consent has to be provable: every change is a new row, the wording is
 * stored with the opt-in, and "confirmed" only ever comes from Brevo — never
 * from the client.
 */

const brevo = {
	configured: true,
	listState: 'unknown' as 'subscribed' | 'unsubscribed' | 'unknown',
	sent: [] as string[],
	removed: [] as string[],
};

vi.mock('$lib/server/brevo', () => ({
	brevoConfig: () => (brevo.configured ? { apiKey: 'k', listId: 7, doiTemplateId: 3 } : null),
	sendDoubleOptIn: async (_c: unknown, email: string) => {
		brevo.sent.push(email);
		return true;
	},
	listState: async () => brevo.listState,
	removeFromList: async (_c: unknown, email: string) => void brevo.removed.push(email),
}));

const { GET, POST } = await import('./+server');

type Row = { user_id: string; status: string; source: string; consent_text: string | null; created_at: number };

function makeLocals(rows: Row[], user: Record<string, unknown> | null) {
	let clock = rows.length;
	const admin = {
		from: () => ({
			select: () => {
				const q = {
					eq: () => q,
					order: () => q,
					limit: () => q,
					maybeSingle: async () => ({ data: [...rows].sort((a, b) => b.created_at - a.created_at)[0] ?? null }),
				};
				return q;
			},
			insert: async (row: Omit<Row, 'created_at'>) => {
				rows.push({ ...row, created_at: ++clock });
				return { error: null };
			},
		}),
	};
	return { safeGetSession: async () => ({ user }), supabaseAdmin: admin };
}

const user = { id: 'u1', email: 'a@example.com', user_metadata: {} };
const url = new URL('https://jazzchords.app/api/email-consent');

function post(locals: unknown, body: unknown) {
	const request = new Request(url, { method: 'POST', body: JSON.stringify(body) });
	return POST({ locals, request, url } as never);
}

describe('/api/email-consent', () => {
	beforeEach(() => {
		brevo.configured = true;
		brevo.listState = 'unknown';
		brevo.sent = [];
		brevo.removed = [];
	});

	it('subscribing records the wording as pending and sends the double opt-in', async () => {
		const rows: Row[] = [];
		const res = await post(makeLocals(rows, user), { subscribe: true, locale: 'de' });
		expect((await res.json()).status).toBe('pending');
		expect(rows).toHaveLength(1);
		expect(rows[0].status).toBe('pending');
		expect(rows[0].consent_text).toMatch(/jederzeit/);
		expect(brevo.sent).toEqual(['a@example.com']);
	});

	it('a client cannot mark itself confirmed', async () => {
		const rows: Row[] = [];
		const res = await post(makeLocals(rows, user), { subscribe: true, status: 'confirmed' });
		expect((await res.json()).status).toBe('pending');
		expect(rows.every((r) => r.status !== 'confirmed')).toBe(true);
	});

	it('pending becomes confirmed only once Brevo has the address on the list', async () => {
		const rows: Row[] = [];
		const locals = makeLocals(rows, user);
		await post(locals, { subscribe: true });
		expect((await (await GET({ locals, url } as never)).json()).status).toBe('pending');
		brevo.listState = 'subscribed';
		expect((await (await GET({ locals, url } as never)).json()).status).toBe('confirmed');
		expect(rows.at(-1)?.source).toBe('brevo');
	});

	it('the signup opt-in is recorded on first read', async () => {
		const rows: Row[] = [];
		const signedUp = { ...user, user_metadata: { email_updates_opt_in: true, locale: 'en' } };
		const res = await GET({ locals: makeLocals(rows, signedUp), url } as never);
		expect((await res.json()).status).toBe('pending');
		expect(rows[0].source).toBe('signup');
		expect(brevo.sent).toEqual(['a@example.com']);
	});

	it('unsubscribing appends a withdrawal and leaves the list', async () => {
		const rows: Row[] = [];
		const locals = makeLocals(rows, user);
		await post(locals, { subscribe: true });
		const res = await post(locals, { subscribe: false });
		expect((await res.json()).status).toBe('none');
		expect(rows.map((r) => r.status)).toEqual(['pending', 'withdrawn']);
		expect(brevo.removed).toEqual(['a@example.com']);
	});

	it('an unsubscribe link clicked in a mail is picked up', async () => {
		const rows: Row[] = [];
		const locals = makeLocals(rows, user);
		await post(locals, { subscribe: true });
		brevo.listState = 'unsubscribed';
		expect((await (await GET({ locals, url } as never)).json()).status).toBe('none');
		expect(rows.at(-1)?.status).toBe('withdrawn');
	});

	it('rejects anonymous callers', async () => {
		await expect(GET({ locals: makeLocals([], null), url } as never)).rejects.toMatchObject({ status: 401 });
	});
});
