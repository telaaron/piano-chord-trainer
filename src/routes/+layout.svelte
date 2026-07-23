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
				<!-- Brand lockup -->
				<a href="/" class="brand" aria-label="jazzchords.app — home">
					<span class="brand-mark">
						<img src="/favicon/favicon.svg" alt="" width="22" height="22" />
					</span>
					<span class="brand-word">jazzchords<span class="brand-tld">.app</span></span>
				</a>

				<!-- Center links (desktop) -->
				<div class="nav-links">
					<a href="/learn" class="nav-link" class:active={page.url.pathname.startsWith('/learn')}>{t('nav.learn')}</a>
					<a href="/train" class="nav-link" class:active={page.url.pathname.startsWith('/train')}>{t('nav.train')}</a>
					<a href="/for-educators" class="nav-link" class:active={page.url.pathname === '/for-educators'}>{t('nav.educators_short')}</a>
					{#if isAdmin}
						<a href="/admin" class="nav-link" class:active={page.url.pathname === '/admin'} title="Admin Dashboard">Admin</a>
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
					<a href="/learn" class="nav-mobile-link" class:active={page.url.pathname.startsWith('/learn')}>{t('nav.learn')}</a>
					<a href="/train" class="nav-mobile-link" class:active={page.url.pathname.startsWith('/train')}>{t('nav.train')}</a>
					<a href="/for-educators" class="nav-mobile-link" class:active={page.url.pathname === '/for-educators'}>{t('nav.educators')}</a>
					<a href="/pricing" class="nav-mobile-link" class:active={page.url.pathname === '/pricing'}>{t('nav_auth.pricing')}</a>
					{#if isAdmin}
						<a href="/admin" class="nav-mobile-link" class:active={page.url.pathname === '/admin'}>Admin</a>
					{/if}
				</div>
			{/if}
		</nav>

		<!-- Sync banner for non-logged-in users with existing data -->
		{#if showSyncBanner && !isEmbedRoute}
			<div class="bg-[var(--primary)]/10 border-b border-[var(--primary)]/20 px-4 py-2.5">
				<div class="max-w-[1600px] mx-auto flex items-center justify-between gap-4 text-sm">
					<div class="flex items-center gap-2">
						<Cloud size={16} class="text-[var(--primary)] shrink-0" aria-hidden="true" />
						<span class="text-[var(--text-muted)]">{t('nav_auth.sync_banner_desc')}</span>
					</div>
					<div class="flex items-center gap-2 shrink-0">
						<a
							href="/auth/login"
							class="px-3 py-1 rounded-sm bg-[var(--primary)] text-white text-xs font-medium hover:bg-[var(--primary-hover)] transition-colors"
						>
							{t('nav_auth.sync_banner_cta')}
						</a>
						<button
							onclick={dismissSyncBanner}
							class="text-xs text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors"
						>
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
		<footer class="px-4 sm:px-6 py-8 border-t border-[var(--wood-dark)]/40">
			<div class="max-w-5xl mx-auto space-y-5">
				<!-- Logo + Brand -->
				<div class="flex items-center gap-3">
					<img
						src="/favicon/logo-full.webp"
						alt="Chord Trainer"
						class="h-10 w-auto object-contain"
						width="40"
						height="40"
						loading="lazy"
					/>
					<div>
						<p class="font-bold text-[var(--text)]">Chord Trainer</p>
						<p class="text-xs text-[var(--text-dim)]">{t('nav.subtitle')}</p>
					</div>
				</div>

				<!-- Nav links — wrap freely on mobile -->
				<div class="flex flex-wrap gap-x-5 gap-y-2 text-xs text-[var(--text-dim)]">
					<a href="/learn" class="hover:text-[var(--text-muted)] transition-colors"
						>{t('nav.learn')}</a
					>
					<a href="/for-educators" class="hover:text-[var(--text-muted)] transition-colors"
						>{t('nav.educators')}</a
					>
					<a href="/pricing" class="hover:text-[var(--text-muted)] transition-colors"
						>{t('nav_auth.pricing')}</a
					>
					<a href="/about" class="hover:text-[var(--text-muted)] transition-colors"
						>{t('nav.about')}</a
					>
					<a href="/midi-test" class="hover:text-[var(--text-muted)] transition-colors"
						>{t('nav.midi_test')}</a
					>
					<a href="/privacy" class="hover:text-[var(--text-muted)] transition-colors"
						>{t('nav.privacy')}</a
					>
					<a href="/terms" class="hover:text-[var(--text-muted)] transition-colors"
						>{t('nav_auth.terms')}</a
					>
					<a href="/impressum" class="hover:text-[var(--text-muted)] transition-colors"
						>{t('nav.impressum')}</a
					>
					<a
						href="mailto:info@jazzchords.app"
						class="hover:text-[var(--text-muted)] transition-colors">{t('nav.contact')}</a
					>
				</div>

				<!-- Bottom bar: copyright left, tagline right -->
				<div
					class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 text-xs text-[var(--text-dim)]"
				>
					<span>&copy; 2026 Aaron Technologies OÜ</span>
					<span>{t('nav.built_for')}</span>
				</div>
			</div>
		</footer>
	{/if}

	<ToastContainer />
</div>

<style>
	/* ── Site navigation ───────────────────────────────────────────── */
	.site-nav {
		position: sticky;
		top: 0;
		z-index: 30;
		background: color-mix(in srgb, var(--bg) 80%, transparent);
		backdrop-filter: blur(14px) saturate(1.2);
		border-bottom: 1px solid transparent;
		transition: border-color 0.3s ease, background 0.3s ease;
	}
	.site-nav.scrolled {
		background: color-mix(in srgb, var(--bg) 92%, transparent);
		border-bottom-color: var(--border);
	}

	.nav-inner {
		max-width: 1280px;
		margin: 0 auto;
		height: 60px;
		padding: 0 clamp(1rem, 4vw, 2rem);
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1.5rem;
	}

	/* ── Brand lockup ── */
	.brand {
		display: inline-flex;
		align-items: center;
		gap: 0.6rem;
		text-decoration: none;
		flex-shrink: 0;
	}
	.brand-mark {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 34px;
		height: 34px;
		border-radius: 9px;
		background: var(--bg-card);
		border: 1px solid var(--border);
		transition: border-color 0.2s ease, transform 0.2s cubic-bezier(0.16, 1, 0.3, 1);
	}
	.brand:hover .brand-mark {
		border-color: var(--primary);
		transform: translateY(-1px);
	}
	.brand-mark img {
		display: block;
	}
	.brand-word {
		font-size: 1.05rem;
		font-weight: 700;
		letter-spacing: -0.02em;
		color: var(--text);
	}
	.brand-tld {
		color: var(--text-dim);
		font-weight: 600;
	}
	@media (max-width: 480px) {
		.brand-word {
			display: none;
		}
	}

	/* ── Center links ── */
	.nav-links {
		display: none;
		align-items: center;
		gap: 0.15rem;
		flex: 1;
		justify-content: center;
	}
	@media (min-width: 768px) {
		.nav-links {
			display: flex;
		}
	}
	.nav-link {
		padding: 0.45rem 0.85rem;
		border-radius: 0.55rem;
		font-size: 0.92rem;
		font-weight: 500;
		color: var(--text-muted);
		text-decoration: none;
		transition: color 0.15s ease, background 0.15s ease;
	}
	.nav-link:hover {
		color: var(--text);
		background: var(--bg-card);
	}
	.nav-link.active {
		color: var(--primary);
		background: var(--primary-muted);
	}

	/* ── Right cluster ── */
	.nav-actions {
		display: flex;
		align-items: center;
		gap: 0.6rem;
		flex-shrink: 0;
	}

	/* Segmented icon controls — one container, divided */
	.nav-seg {
		display: inline-flex;
		align-items: center;
		border: 1px solid var(--border);
		border-radius: 0.6rem;
		overflow: hidden;
		background: var(--bg-card);
	}
	.seg-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		min-width: 38px;
		height: 38px;
		padding: 0 0.5rem;
		color: var(--text-muted);
		background: transparent;
		border: none;
		cursor: pointer;
		transition: color 0.15s ease, background 0.15s ease;
	}
	.seg-btn:hover {
		color: var(--text);
		background: var(--bg-card-hover);
	}
	.seg-btn + .seg-btn {
		border-left: 1px solid var(--border);
	}
	.seg-lang {
		font-family: var(--font-mono, ui-monospace, monospace);
		font-size: 0.78rem;
		font-weight: 600;
		letter-spacing: 0.03em;
	}

	.nav-account {
		padding: 0.5rem 0.9rem;
		border-radius: 0.6rem;
		font-size: 0.9rem;
		font-weight: 500;
		color: var(--text-muted);
		text-decoration: none;
		border: 1px solid var(--border);
		transition: color 0.15s ease, border-color 0.15s ease;
	}
	.nav-account:hover,
	.nav-account.active {
		color: var(--text);
		border-color: var(--border-hover);
	}

	.nav-cta {
		display: inline-flex;
		align-items: center;
		height: 38px;
		padding: 0 1.1rem;
		border-radius: 0.6rem;
		font-size: 0.9rem;
		font-weight: 600;
		color: var(--primary-text);
		background: var(--primary);
		text-decoration: none;
		transition: background 0.15s ease, transform 0.15s cubic-bezier(0.16, 1, 0.3, 1);
	}
	.nav-cta:hover {
		background: var(--primary-hover);
		transform: translateY(-1px);
	}

	/* ── Mobile ── */
	.nav-burger {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 38px;
		height: 38px;
		border-radius: 0.6rem;
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
		gap: 0.2rem;
		padding: 0.5rem clamp(1rem, 4vw, 2rem) 1rem;
		border-top: 1px solid var(--border);
		background: color-mix(in srgb, var(--bg) 96%, transparent);
	}
	@media (min-width: 768px) {
		.nav-mobile {
			display: none;
		}
	}
	.nav-mobile-link {
		padding: 0.65rem 0.75rem;
		border-radius: 0.55rem;
		font-size: 0.95rem;
		font-weight: 500;
		color: var(--text-muted);
		text-decoration: none;
	}
	.nav-mobile-link:hover {
		background: var(--bg-card);
		color: var(--text);
	}
	.nav-mobile-link.active {
		color: var(--primary);
		background: var(--primary-muted);
	}

	@media (prefers-reduced-motion: reduce) {
		.brand:hover .brand-mark,
		.nav-cta:hover {
			transform: none;
		}
	}
</style>
