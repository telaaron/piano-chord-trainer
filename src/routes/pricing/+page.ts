// Pricing reads private Stripe env in +page.server.ts → keep SSR, do not prerender.
// Still serves full HTML to crawlers; just not a static CDN file.
export const prerender = false;
