<script lang="ts">
	import '../app.css';
	import { page } from '$app/state';
	import { t, setLocale, getLocale, type Locale } from '$lib/i18n';
	import { initTheme, applyThemeForRoute, isLightActive, toggleLightDark, routeAllowsLight } from '$lib/services/theme';
	import { Sun, Moon, Cloud } from 'lucide-svelte';
	import { initAuth, onAuthChange, type AuthState } from '$lib/services/auth';
	import { initSubscriptionStore } from '$lib/services/subscription-store.svelte';
	import { getSupabase } from '$lib/services/supabase';
	import ToastContainer from '$lib/components/ToastContainer.svelte';
	import { browser } from '$app/environment';

	let { children } = $props();
	const isTrainPage = $derived(page.url.pathname.startsWith('/train'));
	const isLearnLesson = $derived(/^\/learn\/[^/]+\/[^/]+/.test(page.url.pathname));
	const isEmbedRoute = $derived(page.url.pathname.startsWith('/embed'));

	let auth: AuthState = $state({ user: null, session: null, loading: true });
	let showSyncBanner = $state(false);
	let isAdmin = $state(false);
	let mobileMenuOpen = $state(false);
	let navbarCondensed = $state(false);
	let themeIsLight = $state(false);

	$effect(() => {
		if (!browser) return;
		const cleanup = initTheme(page.url.pathname);
		themeIsLight = isLightActive();
		return cleanup;
	});

	// Re-apply theme whenever the route changes — light only shows on train/learn.
	$effect(() => {
		if (!browser) return;
		applyThemeForRoute(page.url.pathname);
	});

	// Theme toggle is only relevant where light mode applies (train/learn).
	const showThemeToggle = $derived(routeAllowsLight(page.url.pathname));

	function flipTheme() {
		toggleLightDark();
		themeIsLight = isLightActive();
	}

	$effect(() => {
		if (!browser) return;
		const unsubSub = initSubscriptionStore();
		initAuth();
		const unsub = onAuthChange(async (s) => {
			auth = s;
			if (s.user) {
				const { data } = await getSupabase()
					.from('profiles')
					.select('role')
					.eq('id', s.user.id)
					.single();
				isAdmin = data?.role === 'admin';
			} else {
				isAdmin = false;
			}
			if (!s.user && !s.loading) {
				const dismissed = localStorage.getItem('chord-trainer-sync-banner-dismissed');
				const hasData = localStorage.getItem('chord-trainer-history');
				showSyncBanner = !dismissed && !!hasData;
			} else {
				showSyncBanner = false;
			}
		});
		return () => {
			unsub();
			unsubSub();
		};
	});

	function dismissSyncBanner() {
		showSyncBanner = false;
		localStorage.setItem('chord-trainer-sync-banner-dismissed', '1');
	}

	function toggleLanguage() {
		const current = getLocale();
		setLocale(current === 'en' ? 'de' : 'en');
	}

	// Close mobile menu on route change
	$effect(() => {
		page.url.pathname;
		mobileMenuOpen = false;
	});

	$effect(() => {
		if (!browser) return;
		const updateNavbarState = () => {
			navbarCondensed = window.scrollY > 18;
		};
		updateNavbarState();
		window.addEventListener('scroll', updateNavbarState, { passive: true });
		return () => window.removeEventListener('scroll', updateNavbarState);
	});

</script>

<div class="min-h-dvh flex flex-col">
	<!-- Navigation — hidden on embed routes for clean iframe experience -->
	{#if !isEmbedRoute && !isTrainPage}
		<nav class="site-nav" class:scrolled={navbarCondensed}>
			<div class="nav-inner">
				<!-- Brand lockup — the plate stamp: a copyist's rehearsal box
				     holding a drawn flat sign. Self-drawn, no emoji, no raster. -->
				<a href="/" class="brand" aria-label="jazzchords.app — home">
					<span class="brand-mark" aria-hidden="true">
						<svg viewBox="0 0 24 24" width="22" height="22" fill="none">
							<!-- The plate box: the rehearsal-letter frame a copyist rules
							     around a cue. Square, hairline, deliberately not a tile. -->
							<rect
								x="1"
								y="1"
								width="22"
								height="22"
								stroke="currentColor"
								stroke-width="1.6"
							/>
							<!-- A flat sign, inked as strokes so the bowl keeps its counter
							     at 22px instead of blobbing into a solid triangle. -->
							<path
								d="M9 4.5 V18"
								stroke="currentColor"
								stroke-width="1.6"
								stroke-linecap="butt"
							/>
							<path
								d="M9 11.2 C11.6 9 15 10.1 15 12.4 C15 14.6 12.4 16.2 9 18"
								stroke="currentColor"
								stroke-width="1.6"
								stroke-linecap="butt"
								stroke-linejoin="miter"
							/>
						</svg>
					</span>
					<span class="brand-word">
						<span class="brand-name">jazzchords<span class="brand-tld">.app</span></span>
						<span class="brand-sub">{t('nav.subtitle')}</span>
					</span>
				</a>

				<!-- Center links (desktop) — a printed table of contents -->
				<div class="nav-links">
					<a href="/learn" class="nav-link" class:active={page.url.pathname.startsWith('/learn')}><span class="nav-num" aria-hidden="true">I</span>{t('nav.learn')}</a>
					<a href="/train" class="nav-link" class:active={page.url.pathname.startsWith('/train')}><span class="nav-num" aria-hidden="true">II</span>{t('nav.train')}</a>
					<a href="/togo" class="nav-link" class:active={page.url.pathname.startsWith('/togo')}><span class="nav-num" aria-hidden="true">III</span>{t('nav.togo')}</a>
					<a href="/for-educators" class="nav-link" class:active={page.url.pathname === '/for-educators'}><span class="nav-num" aria-hidden="true">IV</span>{t('nav.educators_short')}</a>
					{#if isAdmin}
						<a href="/admin" class="nav-link" class:active={page.url.pathname === '/admin'} title="Admin Dashboard"><span class="nav-num" aria-hidden="true">V</span>Admin</a>
					{/if}
				</div>

				<!-- Right cluster -->
				<div class="nav-actions">
					<!-- Segmented icon controls -->
					<div class="nav-seg">
						{#if showThemeToggle}
							<button onclick={flipTheme} class="seg-btn" title={t('nav.theme')} aria-label={t('nav.theme')}>
								{#if themeIsLight}<Moon size={16} />{:else}<Sun size={16} />{/if}
							</button>
						{/if}
						<button onclick={toggleLanguage} class="seg-btn seg-lang" title={t('nav.language')}>
							{getLocale().toUpperCase()}
						</button>
					</div>

					{#if !auth.loading}
						{#if auth.user}
							<a href="/account" class="nav-account" class:active={page.url.pathname === '/account'}>{t('nav_auth.account')}</a>
						{:else}
							<a href="/auth/login" class="nav-cta">{t('nav_auth.login')}</a>
						{/if}
					{/if}

					<!-- Mobile hamburger -->
					<button class="nav-burger" onclick={() => (mobileMenuOpen = !mobileMenuOpen)} aria-label="Menu" aria-expanded={mobileMenuOpen}>
						{#if mobileMenuOpen}
							<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" /></svg>
						{:else}
							<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd" /></svg>
						{/if}
					</button>
				</div>
			</div>

			<!-- Mobile dropdown -->
			{#if mobileMenuOpen}
				<div class="nav-mobile">
					<a href="/learn" class="nav-mobile-link" class:active={page.url.pathname.startsWith('/learn')}><span class="nav-num" aria-hidden="true">I</span>{t('nav.learn')}</a>
					<a href="/train" class="nav-mobile-link" class:active={page.url.pathname.startsWith('/train')}><span class="nav-num" aria-hidden="true">II</span>{t('nav.train')}</a>
					<a href="/togo" class="nav-mobile-link" class:active={page.url.pathname.startsWith('/togo')}><span class="nav-num" aria-hidden="true">III</span>{t('nav.togo')}</a>
					<a href="/for-educators" class="nav-mobile-link" class:active={page.url.pathname === '/for-educators'}><span class="nav-num" aria-hidden="true">IV</span>{t('nav.educators')}</a>
					<a href="/pricing" class="nav-mobile-link" class:active={page.url.pathname === '/pricing'}><span class="nav-num" aria-hidden="true">V</span>{t('nav_auth.pricing')}</a>
					{#if isAdmin}
						<a href="/admin" class="nav-mobile-link" class:active={page.url.pathname === '/admin'}><span class="nav-num" aria-hidden="true">VI</span>Admin</a>
					{/if}
				</div>
			{/if}
		</nav>

		<!-- Sync banner for non-logged-in users with existing data -->
		{#if showSyncBanner && !isEmbedRoute}
			<div class="sync-banner">
				<div class="sync-inner">
					<div class="sync-msg">
						<Cloud size={15} class="shrink-0" aria-hidden="true" />
						<span class="max-sm:hidden">{t('nav_auth.sync_banner_desc')}</span>
						<span class="hidden max-sm:block">{t('nav_auth.sync_banner')}</span>
					</div>
					<div class="sync-acts">
						<a href="/auth/login" class="sync-cta">{t('nav_auth.sync_banner_cta')}</a>
						<button onclick={dismissSyncBanner} class="sync-dismiss">
							{t('nav_auth.sync_banner_dismiss')}
						</button>
					</div>
				</div>
			</div>
		{/if}
	{/if}

	<!-- Content -->
	<main class="flex-1 flex flex-col">
		{@render children()}
	</main>

	<!-- Footer (hidden on train page and embed routes for focus) -->
	{#if !isTrainPage && !isLearnLesson && !isEmbedRoute}
		<footer class="site-foot">
			<div class="foot-inner">
				<!-- Colophon: the imprint line at the foot of the plate -->
				<div class="foot-brand">
					<span class="brand-mark foot-mark" aria-hidden="true">
						<svg viewBox="0 0 24 24" width="22" height="22" fill="none">
							<rect x="1" y="1" width="22" height="22" stroke="currentColor" stroke-width="1.6" />
							<path d="M9 4.5 V18" stroke="currentColor" stroke-width="1.6" />
							<path d="M9 11.2 C11.6 9 15 10.1 15 12.4 C15 14.6 12.4 16.2 9 18" stroke="currentColor" stroke-width="1.6" />
						</svg>
					</span>
					<div>
						<p class="foot-name">jazzchords<span class="brand-tld">.app</span></p>
						<p class="foot-sub">{t('nav.subtitle')}</p>
					</div>
				</div>

				<!-- Index of the back matter -->
				<nav class="foot-links" aria-label={t('nav.footer_nav')}>
					<a href="/learn">{t('nav.learn')}</a>
					<a href="/for-educators">{t('nav.educators')}</a>
					<a href="/pricing">{t('nav_auth.pricing')}</a>
					<a href="/about">{t('nav.about')}</a>
					<a href="/midi-test">{t('nav.midi_test')}</a>
					<a href="/privacy">{t('nav.privacy')}</a>
					<a href="/terms">{t('nav_auth.terms')}</a>
					<a href="/impressum">{t('nav.impressum')}</a>
					<a href="/feedback">{t('feedback.title')}</a>
					<a href="mailto:info@jazzchords.app">{t('nav.contact')}</a>
				</nav>

				<div class="foot-rule" aria-hidden="true"></div>

				<div class="foot-imprint">
					<span>&copy; 2026 Aaron Technologies OÜ</span>
					<span>{t('nav.built_for')}</span>
				</div>
			</div>
		</footer>
	{/if}

	<ToastContainer />
</div>

<style>
	/* ── Masthead ───────────────────────────────────────────────────
	   Not a floating glass bar — a printed masthead. It sits on the
	   stock, separated by a hairline, and gains a second, heavier rule
	   once you scroll off the top of the page. */
	.site-nav {
		position: sticky;
		top: 0;
		z-index: 30;
		background: color-mix(in srgb, var(--bg) 92%, transparent);
		backdrop-filter: blur(12px) saturate(1.1);
		border-bottom: 1px solid var(--border);
		transition: border-color 0.25s ease, background 0.25s ease;
	}
	/* The plate edge: a hairline shadow-rule under the masthead, the way
	   a printed heading sits above its column. Only once scrolled. */
	.site-nav::after {
		content: '';
		position: absolute;
		left: 0;
		right: 0;
		bottom: -3px;
		height: 2px;
		background: linear-gradient(to bottom, color-mix(in srgb, var(--border) 70%, transparent), transparent);
		opacity: 0;
		transition: opacity 0.25s ease;
		pointer-events: none;
	}
	.site-nav.scrolled {
		background: color-mix(in srgb, var(--bg) 97%, transparent);
		border-bottom-color: var(--border-hover);
	}
	.site-nav.scrolled::after {
		opacity: 1;
	}

	.nav-inner {
		max-width: 1180px;
		margin: 0 auto;
		min-height: 64px;
		padding: 0 clamp(1rem, 5vw, 2rem);
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1.25rem;
	}

	/* ── Brand lockup ──
	   The plate stamp + the serif wordmark. No tile, no rounded chip —
	   the mark IS a box, so wrapping it in another one is redundant. */
	.brand {
		display: inline-flex;
		align-items: center;
		gap: 0.6rem;
		text-decoration: none;
		flex-shrink: 0;
		color: var(--text);
	}
	.brand-mark {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 22px;
		height: 22px;
		flex: none;
		color: var(--primary);
		transition: color 0.2s ease, transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
	}
	.brand-mark svg {
		display: block;
		overflow: visible;
	}
	.brand:hover .brand-mark {
		color: var(--ink-blue);
		transform: rotate(-3deg);
	}
	.brand-word {
		display: flex;
		flex-direction: column;
		gap: 1px;
		min-width: 0;
	}
	.brand-name {
		font-family: var(--font-display);
		font-size: 1.22rem;
		font-weight: 600;
		letter-spacing: -0.022em;
		line-height: 1.05;
		color: var(--text);
	}
	.brand-tld {
		color: var(--primary);
		font-weight: 600;
	}
	/* The strapline under the wordmark, set as a plate line */
	.brand-sub {
		display: none;
		font-family: var(--font-mono);
		font-size: 0.55rem;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text-dim);
		line-height: 1;
		/* The wordmark's own descenders leave no room, so the strapline sat on
		   its baseline. A small explicit gap reads as a lockup instead. */
		margin-top: 0.28rem;
	}
	@media (min-width: 900px) {
		.brand-sub {
			display: block;
		}
	}
	@media (max-width: 420px) {
		.brand-word {
			display: none;
		}
	}

	/* ── Index (centre links) ──
	   A printed table of contents: roman numeral, then the entry.
	   Current page is marked with a stamp-red rule beneath, not a pill. */
	.nav-links {
		display: none;
		align-items: stretch;
		gap: 0;
		flex: 1;
		justify-content: center;
	}
	@media (min-width: 768px) {
		.nav-links {
			display: flex;
		}
	}
	.nav-link {
		display: inline-flex;
		align-items: center;
		gap: 0.45rem;
		padding: 0.55rem 0.95rem;
		font-size: 0.9rem;
		font-weight: 500;
		color: var(--text-muted);
		text-decoration: none;
		border-bottom: 2px solid transparent;
		transition: color 0.15s ease, border-color 0.15s ease;
	}
	.nav-num {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.1em;
		color: var(--text-dim);
		transition: color 0.15s ease;
	}
	.nav-link:hover {
		color: var(--text);
	}
	.nav-link:hover .nav-num {
		color: var(--ink-blue);
	}
	.nav-link.active {
		color: var(--text);
		font-weight: 600;
		border-bottom-color: var(--primary);
	}
	.nav-link.active .nav-num {
		color: var(--primary);
	}

	/* ── Right cluster ── */
	.nav-actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		flex-shrink: 0;
	}

	/* Segmented controls — hairline-divided cells, square corners */
	.nav-seg {
		display: inline-flex;
		align-items: center;
		border: 1px solid var(--border);
		border-radius: 2px;
		overflow: hidden;
		background: transparent;
	}
	.seg-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		min-width: 36px;
		height: 34px;
		padding: 0 0.5rem;
		color: var(--text-muted);
		background: transparent;
		border: none;
		cursor: pointer;
		transition: color 0.15s ease, background 0.15s ease;
	}
	.seg-btn:hover {
		color: var(--text);
		background: var(--bg-card);
	}
	.seg-btn + .seg-btn {
		border-left: 1px solid var(--border);
	}
	.seg-lang {
		font-family: var(--font-mono);
		font-size: 0.68rem;
		font-weight: 600;
		letter-spacing: 0.12em;
	}

	.nav-account {
		display: inline-flex;
		align-items: center;
		height: 34px;
		padding: 0 0.85rem;
		border-radius: 2px;
		font-size: 0.85rem;
		font-weight: 500;
		color: var(--text-muted);
		text-decoration: none;
		border: 1px solid var(--border);
		transition: color 0.15s ease, border-color 0.15s ease, background 0.15s ease;
	}
	.nav-account:hover,
	.nav-account.active {
		color: var(--text);
		border-color: var(--text-muted);
		background: var(--bg-card);
	}

	/* The one loud ink in the masthead */
	.nav-cta {
		display: inline-flex;
		align-items: center;
		height: 34px;
		padding: 0 1rem;
		border-radius: 2px;
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--primary-text);
		background: var(--primary);
		border: 1px solid var(--primary);
		text-decoration: none;
		transition: background 0.15s ease, border-color 0.15s ease;
	}
	.nav-cta:hover {
		background: var(--primary-hover);
		border-color: var(--primary-hover);
	}

	/* ── Mobile ── */
	.nav-burger {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 36px;
		height: 34px;
		border-radius: 2px;
		color: var(--text-muted);
		background: transparent;
		border: 1px solid var(--border);
		cursor: pointer;
		transition: color 0.15s ease, background 0.15s ease;
	}
	.nav-burger:hover {
		color: var(--text);
		background: var(--bg-card);
	}
	@media (min-width: 768px) {
		.nav-burger {
			display: none;
		}
	}

	.nav-mobile {
		display: flex;
		flex-direction: column;
		border-top: 1px solid var(--border);
		background: color-mix(in srgb, var(--bg) 98%, transparent);
		padding: 0 clamp(1rem, 5vw, 2rem) 0.5rem;
	}
	@media (min-width: 768px) {
		.nav-mobile {
			display: none;
		}
	}
	.nav-mobile-link {
		display: flex;
		align-items: center;
		gap: 0.8rem;
		min-height: var(--tap-min);
		padding: 0.7rem 0.1rem;
		font-size: 0.95rem;
		font-weight: 500;
		color: var(--text-muted);
		text-decoration: none;
		border-bottom: 1px solid color-mix(in srgb, var(--border) 55%, transparent);
	}
	.nav-mobile-link:last-child {
		border-bottom: none;
	}
	.nav-mobile-link .nav-num {
		width: 1.6rem;
		flex: none;
	}
	.nav-mobile-link:hover {
		color: var(--text);
	}
	.nav-mobile-link.active {
		color: var(--text);
		font-weight: 600;
	}
	.nav-mobile-link.active .nav-num {
		color: var(--primary);
	}

	/* ── Sync banner — an errata slip pasted under the masthead ── */
	.sync-banner {
		border-bottom: 1px solid var(--border);
		background: var(--primary-muted);
	}
	.sync-inner {
		max-width: 1180px;
		margin: 0 auto;
		padding: 0.6rem clamp(1rem, 5vw, 2rem);
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
	}
	.sync-msg {
		display: flex;
		align-items: center;
		gap: 0.55rem;
		min-width: 0;
		font-size: 0.82rem;
		line-height: 1.35;
		color: var(--text-muted);
	}
	/* Below ~640px the message and the actions cannot share a line without
	   the text being clipped behind the button — stack them instead. */
	@media (max-width: 640px) {
		.sync-inner {
			flex-direction: column;
			align-items: flex-start;
			gap: 0.6rem;
		}
		.sync-acts {
			width: 100%;
			justify-content: space-between;
		}
	}
	.sync-msg :global(svg) {
		color: var(--primary);
	}
	.sync-acts {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		flex-shrink: 0;
	}
	.sync-cta {
		display: inline-flex;
		align-items: center;
		padding: 0.3rem 0.7rem;
		border-radius: 2px;
		background: var(--primary);
		border: 1px solid var(--primary);
		color: var(--primary-text);
		font-size: 0.75rem;
		font-weight: 600;
		text-decoration: none;
		transition: background 0.15s ease;
	}
	.sync-cta:hover {
		background: var(--primary-hover);
	}
	.sync-dismiss {
		font-size: 0.75rem;
		color: var(--text-dim);
		background: none;
		border: none;
		cursor: pointer;
		text-decoration: underline;
		text-underline-offset: 2px;
		transition: color 0.15s ease;
	}
	.sync-dismiss:hover {
		color: var(--text-muted);
	}

	/* ── Colophon ────────────────────────────────────────────────── */
	.site-foot {
		border-top: 1px solid var(--border);
		padding: 2.5rem clamp(1rem, 5vw, 2rem) 2.75rem;
	}
	.foot-inner {
		max-width: 1180px;
		margin: 0 auto;
		display: flex;
		flex-direction: column;
		gap: 1.4rem;
	}
	.foot-brand {
		display: flex;
		align-items: center;
		gap: 0.7rem;
	}
	.foot-mark {
		color: var(--text-dim);
	}
	.foot-name {
		font-family: var(--font-display);
		font-size: 1.05rem;
		font-weight: 600;
		letter-spacing: -0.02em;
		color: var(--text);
		line-height: 1.15;
	}
	.foot-sub {
		font-family: var(--font-mono);
		font-size: 0.56rem;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text-dim);
		margin-top: 0.28rem;
	}
	.foot-links {
		display: flex;
		flex-wrap: wrap;
		gap: 0.4rem 1.6rem;
		font-size: 0.8rem;
	}
	.foot-links a {
		color: var(--text-muted);
		text-decoration: none;
		transition: color 0.15s ease;
	}
	.foot-links a:hover {
		color: var(--primary);
	}
	.foot-rule {
		height: 1px;
		background: var(--border);
	}
	.foot-imprint {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
		font-family: var(--font-mono);
		font-size: 0.62rem;
		letter-spacing: 0.11em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	@media (min-width: 640px) {
		.foot-imprint {
			flex-direction: row;
			align-items: center;
			justify-content: space-between;
		}
	}

	@media (prefers-reduced-motion: reduce) {
		.brand:hover .brand-mark {
			transform: none;
		}
	}
</style>
