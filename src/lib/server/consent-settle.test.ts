import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * The double opt-in click of someone without an account is recorded when
 * the confirmation link lands, once Brevo agrees the address is on the list.
 */

const brevo = { configured: true, listState: 'subscribed' as 'subscribed' | 'unsubscribed' | 'unknown' };

vi.mock('$lib/server/brevo', () => ({
	brevoConfig: () => (brevo.configured ? { apiKey: 'k', listId: 6, doiTemplateId: 3 } : null),
	listState: async () => brevo.listState,
}));

const { settleConfirmation } = await import('./consent-settle');

type Row = Record<string, unknown> & { id: string; email: string; status: string; created_at: string };

const ID = '0b5c0a52-2f3e-4f0e-9d7a-3c1d2e4f5a6b';

function makeAdmin(rows: Row[]) {
	return {
		from: () => ({
			select: (_cols: string, opts?: { head?: boolean }) => {
				const filters: ((r: Row) => boolean)[] = [];
				const matches = () => rows.filter((r) => filters.every((f) => f(r)));
				const q = {
					eq: (col: string, v: unknown) => (filters.push((r) => r[col] === v), q),
					ilike: (col: string, v: string) =>
						(filters.push((r) => String(r[col]).toLowerCase() === v.toLowerCase()), q),
					gte: (col: string, v: string) => (filters.push((r) => String(r[col]) >= v), q),
					maybeSingle: async () => ({ data: matches()[0] ?? null, error: null }),
					then: (resolve: (x: unknown) => void) =>
						resolve(opts?.head ? { count: matches().length, error: null } : { data: matches(), error: null }),
				};
				return q;
			},
			insert: async (row: Row) => {
				rows.push({ ...row, id: `new-${rows.length}`, created_at: new Date().toISOString() });
				return { error: null };
			},
		}),
	} as never;
}

function pendingRow(): Row {
	return {
		id: ID,
		user_id: null,
		email: 'anna@example.com',
		purpose: 'product_updates',
		status: 'pending',
		source: 'prompt',
		text_version: 'v2-2026-10-16',
		created_at: '2026-10-16T21:22:56.000Z',
	};
}

describe('settleConfirmation', () => {
	beforeEach(() => {
		brevo.configured = true;
		brevo.listState = 'subscribed';
	});

	it('records the click with the wording version it confirms', async () => {
		const rows = [pendingRow()];
		expect(await settleConfirmation(makeAdmin(rows), ID)).toBe(true);
		expect(rows).toHaveLength(2);
		expect(rows[1]).toMatchObject({
			user_id: null,
			email: 'anna@example.com',
			status: 'confirmed',
			source: 'brevo',
			text_version: 'v2-2026-10-16',
		});
	});

	it('a second click records nothing new', async () => {
		const rows = [pendingRow()];
		const admin = makeAdmin(rows);
		await settleConfirmation(admin, ID);
		expect(await settleConfirmation(admin, ID)).toBe(false);
		expect(rows).toHaveLength(2);
	});

	it('records nothing until Brevo has the address on the list', async () => {
		brevo.listState = 'unknown';
		const rows = [pendingRow()];
		expect(await settleConfirmation(makeAdmin(rows), ID)).toBe(false);
		expect(rows).toHaveLength(1);
	});

	it('ignores ids that are not a pending consent', async () => {
		const rows = [pendingRow()];
		expect(await settleConfirmation(makeAdmin(rows), 'not-a-uuid')).toBe(false);
		expect(await settleConfirmation(makeAdmin(rows), 'ffffffff-ffff-4fff-8fff-ffffffffffff')).toBe(false);
		expect(rows).toHaveLength(1);
	});
});
