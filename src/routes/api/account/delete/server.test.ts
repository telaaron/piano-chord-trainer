import { describe, it, expect, vi } from 'vitest';

/**
 * The iOS app has no cookie session: it deletes the account with its access
 * token in an Authorization header. A forged or expired token must not delete
 * anything.
 */

vi.mock('$lib/server/brevo', () => ({
	brevoConfig: () => null,
	deleteContact: async () => {},
}));

const { POST } = await import('./+server');

function makeLocals(cookieUser: { id: string; email?: string } | null, tokenUsers: Record<string, { id: string; email?: string }>) {
	const deleted: string[] = [];
	const removedRows: string[] = [];
	const admin = {
		from: (table: string) => ({
			delete: () => ({ eq: async () => void removedRows.push(table) }),
		}),
		auth: {
			getUser: async (token: string) =>
				tokenUsers[token]
					? { data: { user: tokenUsers[token] }, error: null }
					: { data: { user: null }, error: { message: 'invalid' } },
			admin: {
				deleteUser: async (id: string) => {
					deleted.push(id);
					return { error: null };
				},
			},
		},
	};
	return {
		locals: { safeGetSession: async () => ({ user: cookieUser }), supabaseAdmin: admin },
		deleted,
		removedRows,
	};
}

function post(locals: unknown, headers: Record<string, string> = {}) {
	const request = new Request('https://jazzchords.app/api/account/delete', { method: 'POST', headers });
	return POST({ locals, request } as never);
}

describe('/api/account/delete', () => {
	it('deletes the cookie user as before', async () => {
		const { locals, deleted } = makeLocals({ id: 'web-user' }, {});
		const res = await post(locals);
		expect(res.status).toBe(200);
		expect(deleted).toEqual(['web-user']);
	});

	it('accepts a bearer token when there is no cookie session', async () => {
		const { locals, deleted, removedRows } = makeLocals(null, { 'good-token': { id: 'ios-user' } });
		const res = await post(locals, { Authorization: 'Bearer good-token' });
		expect(res.status).toBe(200);
		expect(deleted).toEqual(['ios-user']);
		expect(removedRows).toContain('user_data');
	});

	it('rejects an invalid bearer token and deletes nothing', async () => {
		const { locals, deleted } = makeLocals(null, {});
		await expect(post(locals, { Authorization: 'Bearer forged' })).rejects.toMatchObject({ status: 401 });
		expect(deleted).toEqual([]);
	});
});
