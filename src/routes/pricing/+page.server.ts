import type { PageServerLoad } from './$types';
import {
	STRIPE_PRICE_PRO,
	STRIPE_PRICE_PRO_YEARLY,
	STRIPE_PRICE_EDUCATOR,
	STRIPE_PRICE_EDUCATOR_YEARLY,
	STRIPE_PRICE_INSTITUTION,
} from '$env/static/private';

export const load: PageServerLoad = async () => {
	return {
		priceIdPro: STRIPE_PRICE_PRO,
		priceIdProYearly: STRIPE_PRICE_PRO_YEARLY,
		priceIdEducator: STRIPE_PRICE_EDUCATOR,
		priceIdEducatorYearly: STRIPE_PRICE_EDUCATOR_YEARLY,
		// Empty by design — Institut is invoiced by hand, so the page shows a
		// contact link instead of a checkout button.
		priceIdInstitution: STRIPE_PRICE_INSTITUTION,
	};
};
