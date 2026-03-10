import type { PageServerLoad } from './$types';
import { STRIPE_PRICE_PRO, STRIPE_PRICE_EDUCATOR, STRIPE_PRICE_INSTITUTION } from '$env/static/private';

export const load: PageServerLoad = async () => {
	return {
		priceIdPro: STRIPE_PRICE_PRO,
		priceIdEducator: STRIPE_PRICE_EDUCATOR,
		priceIdInstitution: STRIPE_PRICE_INSTITUTION,
	};
};
