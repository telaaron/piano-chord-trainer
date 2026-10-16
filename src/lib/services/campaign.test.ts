import { describe, it, expect } from 'vitest';
import { captureCampaign, getCampaign } from './campaign';

function store() {
	const m = new Map<string, string>();
	return { getItem: (k: string) => m.get(k) ?? null, setItem: (k: string, v: string) => void m.set(k, v) };
}

describe('campaign', () => {
	it('remembers the campaign a visit arrived with', () => {
		const s = store();
		captureCampaign(new URL('https://jazzchords.app/learn/x?utm_source=brevo&utm_medium=email&utm_campaign=uebung-w43'), s);
		expect(getCampaign(s)).toEqual({ source: 'brevo', medium: 'email', campaign: 'uebung-w43' });
	});

	it('keeps it while the visit moves on to pages without parameters', () => {
		const s = store();
		captureCampaign(new URL('https://jazzchords.app/?utm_campaign=uebung-w43'), s);
		captureCampaign(new URL('https://jazzchords.app/train'), s);
		expect(getCampaign(s)?.campaign).toBe('uebung-w43');
	});

	it('is null for a visit without one, and never throws without storage', () => {
		expect(getCampaign(store())).toBeNull();
		expect(getCampaign(null)).toBeNull();
		expect(() => captureCampaign(new URL('https://jazzchords.app/?utm_campaign=x'), null)).not.toThrow();
	});

	it('caps what it stores', () => {
		const s = store();
		captureCampaign(new URL(`https://jazzchords.app/?utm_campaign=${'x'.repeat(500)}`), s);
		expect(getCampaign(s)?.campaign).toHaveLength(64);
	});
});
