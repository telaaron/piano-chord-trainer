import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Sync is for every account (decision 16.10.2026), not a Pro feature: a free
 * user's progress must reach the account once this device is hydrated.
 */

const upserts: unknown[] = [];
const user = { id: 'free-user' };
let cloudRow: Record<string, unknown> = {};

vi.mock('./auth', () => ({ getAuthState: () => ({ user }) }));
vi.mock('./subscription-store.svelte', () => ({ canUse: () => false }));
vi.mock('./supabase', () => ({
	getSupabase: () => ({
		from: () => ({
			select: () => ({ eq: () => ({ maybeSingle: async () => ({ data: { data: cloudRow }, error: null }) }) }),
			upsert: async (row: unknown) => {
				upserts.push(row);
				return { error: null };
			},
		}),
	}),
}));

const store = new Map<string, string>();
vi.stubGlobal('localStorage', {
	getItem: (k: string) => store.get(k) ?? null,
	setItem: (k: string, v: string) => void store.set(k, v),
	removeItem: (k: string) => void store.delete(k),
});

const { ensureHydrated, syncToCloud } = await import('./cloud-sync');

describe('cloud sync for free accounts', () => {
	beforeEach(() => {
		upserts.length = 0;
		store.clear();
		cloudRow = {};
	});

	it('uploads a free, hydrated user’s data', async () => {
		store.set('chord-trainer-history', JSON.stringify([{ id: 's1', timestamp: 1 }]));
		expect(await ensureHydrated(user.id)).toBe(true);
		upserts.length = 0;
		await syncToCloud();
		expect(upserts).toHaveLength(1);
		expect((upserts[0] as { user_id: string }).user_id).toBe('free-user');
	});

	it('does not drop sessions another device uploaded since this tab hydrated', async () => {
		expect(await ensureHydrated(user.id)).toBe(true);
		// The iPhone uploads a session while this tab stays open.
		cloudRow = { 'chord-trainer-history': [{ id: 'iphone', timestamp: 1 }] };
		store.set('chord-trainer-history', JSON.stringify([{ id: 'web', timestamp: 2 }]));
		upserts.length = 0;
		await syncToCloud();
		const sent = (upserts[0] as { data: Record<string, { id: string }[]> }).data;
		expect(sent['chord-trainer-history'].map((s) => s.id)).toEqual(['web', 'iphone']);
	});
});
