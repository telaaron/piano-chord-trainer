import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * The weekly practice mail opt-in for people without an account.
 *
 * Anyone can call this endpoint, so it must not become a way to send mail to
 * strangers: Brevo's double opt-in is the only mail it triggers, at most one
 * per address per day, and with a global cap per hour.
 */

const brevo = {
	configured: true,
	listState: 'unknown' as 'subscribed' | 'unsubscribed' | 'unknown',
	sent: [] as { email: string; redirect: string }[],
};

vi.mock('$lib/server/brevo', () => ({
	brevoConfig: () => (brevo.configured ? { apiKey: 'k', listId: 6, doiTemplateId: 3 } : null),
	sendDoubleOptIn: async (_c: unknown, email: string, redirect: string) => {
		brevo.sent.push({ email, redirect });
		return true;
	},
	listState: async () => brevo.listState,
}));

const { POST } = await import('./+server');

type Row = {
	user_id: string | null;
	email: string;
	status: string;
	source: string;
	consent_text: string | null;
	text_version: string | null;
	created_at: string;
};

/** A tiny stand-in for the two queries the endpoint makes. */
function makeLocals(rows: Row[], user: { id: string; email: string } | null = null) {
	const admin = {
		from: () => ({
			select: () => {
				const filters: ((r: Row) => boolean)[] = [];
				const q = {
					eq: (col: keyof Row, v: unknown) => (filters.push((r) => r[col] === v), q),
					is: (col: keyof Row, v: unknown) => (filters.push((r) => r[col] === v), q),
					ilike: (col: keyof Row, v: string) =>
						(filters.push((r) => String(r[col]).toLowerCase() === v.toLowerCase()), q),
					gte: (col: keyof Row, v: string) => (filters.push((r) => String(r[col]) >= v), q),
					then: (resolve: (x: { count: number; error: null }) => void) =>
						resolve({ count: rows.filter((r) => filters.every((f) => f(r))).length, error: null }),
				};
				return q;
			},
			insert: async (row: Omit<Row, 'created_at'>) => {
				rows.push({ ...row, created_at: new Date().toISOString() });
				return { error: null };
			},
		}),
	};
	return { safeGetSession: async () => ({ user }), supabaseAdmin: admin };
}

const url = new URL('https://jazzchords.app/api/practice-reminder');

function post(locals: unknown, body: unknown) {
	const request = new Request(url, { method: 'POST', body: JSON.stringify(body) });
	return POST({ locals, request, url } as never);
}

describe('/api/practice-reminder', () => {
	beforeEach(() => {
		brevo.configured = true;
		brevo.listState = 'unknown';
		brevo.sent = [];
	});

	it('records the wording as pending and sends the double opt-in', async () => {
		const rows: Row[] = [];
		const res = await post(makeLocals(rows), { email: ' Anna@Example.com ', locale: 'de' });
		expect((await res.json()).status).toBe('pending');
		expect(rows).toHaveLength(1);
		expect(rows[0]).toMatchObject({
			user_id: null,
			email: 'anna@example.com',
			status: 'pending',
			source: 'prompt',
		});
		expect(rows[0].consent_text).toMatch(/pro Woche/);
		expect(rows[0].text_version).toMatch(/^v2/);
		expect(brevo.sent).toEqual([
			{ email: 'anna@example.com', redirect: 'https://jazzchords.app/updates/confirmed' },
		]);
	});

	it('links the row to the account when someone is signed in', async () => {
		const rows: Row[] = [];
		await post(makeLocals(rows, { id: 'u1', email: 'a@example.com' }), { email: 'a@example.com' });
		expect(rows[0].user_id).toBe('u1');
	});

	it('rejects an address that is not one', async () => {
		await expect(post(makeLocals([]), { email: 'nope' })).rejects.toMatchObject({ status: 400 });
		await expect(post(makeLocals([]), {})).rejects.toMatchObject({ status: 400 });
	});

	it('a filled honeypot looks accepted but records and sends nothing', async () => {
		const rows: Row[] = [];
		const res = await post(makeLocals(rows), { email: 'bot@example.com', website: 'http://spam' });
		expect((await res.json()).status).toBe('pending');
		expect(rows).toHaveLength(0);
		expect(brevo.sent).toHaveLength(0);
	});

	it('sends at most one confirmation mail per address per day', async () => {
		const rows: Row[] = [];
		const locals = makeLocals(rows);
		await post(locals, { email: 'anna@example.com' });
		const res = await post(locals, { email: 'ANNA@example.com' });
		expect((await res.json()).status).toBe('pending');
		expect(rows).toHaveLength(1);
		expect(brevo.sent).toHaveLength(1);
	});

	it('an address already on the list is not asked again', async () => {
		brevo.listState = 'subscribed';
		const rows: Row[] = [];
		const res = await post(makeLocals(rows), { email: 'anna@example.com' });
		expect((await res.json()).status).toBe('confirmed');
		expect(rows).toHaveLength(0);
		expect(brevo.sent).toHaveLength(0);
	});

	it('stops after the hourly cap of anonymous opt-ins', async () => {
		const now = new Date().toISOString();
		const rows: Row[] = Array.from({ length: 30 }, (_, i) => ({
			user_id: null,
			email: `p${i}@example.com`,
			status: 'pending',
			source: 'prompt',
			consent_text: 'x',
			text_version: 'v2',
			created_at: now,
		}));
		await expect(post(makeLocals(rows), { email: 'late@example.com' })).rejects.toMatchObject({
			status: 429,
		});
		expect(brevo.sent).toHaveLength(0);
	});

	it('says so when mail is not set up, without recording a consent nobody can confirm', async () => {
		brevo.configured = false;
		const rows: Row[] = [];
		await expect(post(makeLocals(rows), { email: 'anna@example.com' })).rejects.toMatchObject({
			status: 503,
		});
		expect(rows).toHaveLength(0);
	});
});
