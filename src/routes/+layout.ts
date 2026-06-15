// Default rendering policy for all routes: SSR, no prerender.
// Marketing/content pages explicitly opt into prerendering (static HTML in the
// CDN) via per-route `prerender = true`. App routes that read url.searchParams
// or need a live session (/embed, /auth, /train, /account) stay SSR by default —
// they must NOT inherit prerendering, hence the default is `false`, not 'auto'.
export const prerender = false;
export const trailingSlash = 'never';
