import type { PageServerLoad } from './$types';
import { settleConfirmation } from '$lib/server/consent-settle';

// The double opt-in link lands here with `?c=<consent row id>`. Never blocks
// the page: a bad id, a Brevo hiccup or a second click just renders it.
export const load: PageServerLoad = async ({ url, locals }) => {
	const id = url.searchParams.get('c');
	if (id) {
		try {
			await settleConfirmation(locals.supabaseAdmin, id);
		} catch (e) {
			console.error('[updates/confirmed] settle failed:', e);
		}
	}
	return {};
};
