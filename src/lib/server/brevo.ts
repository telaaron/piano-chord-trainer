// Brevo (ex-Sendinblue) — the list that product-update mail goes to.
//
// Read from dynamic env so a deployment without Brevo still builds and runs:
// the consent endpoint then records consent but cannot send the double opt-in
// mail, and says so.
import { env } from '$env/dynamic/private';

const API = 'https://api.brevo.com/v3';

export interface BrevoConfig {
	apiKey: string;
	listId: number;
	doiTemplateId: number;
}

export function brevoConfig(): BrevoConfig | null {
	const apiKey = env.BREVO_API_KEY;
	const listId = Number(env.BREVO_LIST_ID);
	const doiTemplateId = Number(env.BREVO_DOI_TEMPLATE_ID);
	if (!apiKey || !listId || !doiTemplateId) return null;
	return { apiKey, listId, doiTemplateId };
}

async function call(cfg: BrevoConfig, path: string, init: RequestInit = {}): Promise<Response> {
	return fetch(`${API}${path}`, {
		...init,
		headers: {
			'api-key': cfg.apiKey,
			'content-type': 'application/json',
			accept: 'application/json',
			...init.headers,
		},
	});
}

/** Sends Brevo's confirmation mail; the address joins the list only after the click. */
export async function sendDoubleOptIn(
	cfg: BrevoConfig,
	email: string,
	redirectionUrl: string,
	locale: string,
): Promise<boolean> {
	const res = await call(cfg, '/contacts/doubleOptinConfirmation', {
		method: 'POST',
		body: JSON.stringify({
			email,
			includeListIds: [cfg.listId],
			templateId: cfg.doiTemplateId,
			redirectionUrl,
			attributes: { LOCALE: locale },
		}),
	});
	return res.ok;
}

export type BrevoListState = 'subscribed' | 'unsubscribed' | 'unknown';

/** Whether Brevo has the address on the list (confirmed) or it unsubscribed. */
export async function listState(cfg: BrevoConfig, email: string): Promise<BrevoListState> {
	const res = await call(cfg, `/contacts/${encodeURIComponent(email)}`);
	if (res.status === 404) return 'unknown';
	if (!res.ok) return 'unknown';
	const contact = (await res.json()) as { listIds?: number[]; emailBlacklisted?: boolean };
	if (contact.emailBlacklisted) return 'unsubscribed';
	return contact.listIds?.includes(cfg.listId) ? 'subscribed' : 'unknown';
}

export async function removeFromList(cfg: BrevoConfig, email: string): Promise<void> {
	await call(cfg, `/contacts/lists/${cfg.listId}/contacts/remove`, {
		method: 'POST',
		body: JSON.stringify({ emails: [email] }),
	});
}

/** Account deletion: the contact goes too, not just its list membership. */
export async function deleteContact(cfg: BrevoConfig, email: string): Promise<void> {
	await call(cfg, `/contacts/${encodeURIComponent(email)}`, { method: 'DELETE' });
}
