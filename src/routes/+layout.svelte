<script lang="ts">
	import '../app.css';
	import { page } from '$app/state';
	import { t, setLocale, getLocale, type Locale } from '$lib/i18n';
	import { initTheme, applyThemeForRoute, isLightActive, toggleLightDark, routeAllowsLight } from '$lib/services/theme';
	import { Sun, Moon } from 'lucide-svelte';
	import { initAuth, onAuthChange, type AuthState } from '$lib/services/auth';
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
		return unsub;
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
		<nav
			class="sticky top-0 z-20 px-2 sm:px-4 transition-[padding] duration-500 {navbarCondensed
				? isTrainPage
					? 'pt-0'
					: 'pt-1 sm:pt-2'
				: isTrainPage
					? 'pt-0'
					: 'pt-0.5 sm:pt-1'}"
		>
			<div
				class="relative mx-auto w-full px-1 sm:px-0 transition-all duration-500 ease-out {isTrainPage || navbarCondensed
					? 'max-w-[920px] rounded-[999px] border border-[var(--border)]/75 bg-[var(--bg)]/70 shadow-[0_10px_28px_rgba(0,0,0,0.4)] backdrop-blur-xl'
					: 'max-w-[1600px] rounded-2xl border border-transparent bg-[var(--bg)]/85 backdrop-blur-sm'}"
			>
				<div class="px-3 sm:px-6 flex items-center justify-between {isTrainPage ? 'py-1.5 sm:py-2' : 'py-2 sm:py-2.5'}">
					<a href="/" class="flex items-center gap-2 group">
						<img
							src="/favicon/favicon-96x96.png"
							alt="Chord Trainer"
							class="object-contain {isTrainPage ? 'h-7 w-7' : 'h-8 w-8'}"
							width="32"
							height="32"
							loading="eager"
							fetchpriority="high"
						/>
						<span class="hidden sm:inline font-bold text-gradient {isTrainPage ? 'text-base' : 'text-lg'}">jazzchords.app</span>
					</a>

					<div class="flex items-center gap-1 text-sm">
						<!-- Desktop nav links -->
						<div class="hidden sm:flex items-center gap-1.5">
							<a
								href="/learn"
								class="rounded-full transition-colors {isTrainPage ? 'px-3 py-1 text-xs' : 'px-3.5 py-1.5'} {page.url.pathname.startsWith(
									'/learn',
								)
									? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
									: 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
							>
								{t('nav.learn')}
							</a>
							<a
								href="/train"
								class="rounded-full transition-colors {isTrainPage ? 'px-3 py-1 text-xs' : 'px-3.5 py-1.5'} {page.url.pathname.startsWith(
									'/train',
								)
									? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
									: 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
							>
								{t('nav.train')}
							</a>
							<a
								href="/for-educators"
								class="rounded-full transition-colors {isTrainPage ? 'px-3 py-1 text-xs' : 'px-3.5 py-1.5'} {page.url.pathname ===
								'/for-educators'
									? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
									: 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
							>
								{t('nav.educators_short')}
							</a>
							{#if isAdmin}
								<a
									href="/admin"
									class="rounded-full transition-colors {isTrainPage ? 'px-2 py-1' : 'px-3 py-1.5'} {page.url.pathname === '/admin'
										? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
										: 'text-[var(--text-dim)] hover:text-[var(--text)]'}"
									title="Admin Dashboard"
								>
									<img
										src="/elements/icons/icon-settings.webp"
										alt="Admin"
										class="h-8 w-8 object-contain"
										width="16"
										height="16"
										loading="lazy"
									/>
								</a>
							{/if}
						</div>

						{#if showThemeToggle}
							<button
								onclick={flipTheme}
								class="border border-(--border) rounded-full inline-flex items-center justify-center text-(--text-muted) opacity-70 hover:opacity-100 hover:text-(--text) transition-all {isTrainPage ? 'min-h-9 min-w-9 sm:min-h-10 sm:min-w-10' : 'min-h-10 min-w-10 sm:min-h-11 sm:min-w-11'}"
								title={t('nav.theme')}
								aria-label={t('nav.theme')}
							>
								{#if themeIsLight}
									<Moon size={16} />
								{:else}
									<Sun size={16} />
								{/if}
							</button>
						{/if}
						<button
							onclick={toggleLanguage}
							class="px-2 py-1 text-xs font-mono border border-(--border) rounded-full inline-flex items-center justify-center opacity-70 hover:opacity-100 transition-opacity {isTrainPage ? 'min-h-9 min-w-9 sm:min-h-10 sm:min-w-10' : 'min-h-10 min-w-10 sm:min-h-11 sm:min-w-11'}"
							title={t('nav.language')}
						>
							{getLocale().toUpperCase()}
						</button>
						{#if !auth.loading}
							{#if auth.user}
								<a
									href="/account"
									class="ml-1 rounded-full transition-colors {isTrainPage ? 'px-3 py-1 text-xs' : 'px-3 py-1.5 text-sm'} {page.url.pathname ===
									'/account'
										? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
										: 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
								>
									{t('nav_auth.account')}
								</a>
							{:else}
								<a
									href="/auth/login"
									class="ml-1 rounded-full bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white font-medium transition-colors {isTrainPage ? 'px-3 py-1 text-xs' : 'px-3 py-1.5 text-sm'}"
								>
									{t('nav_auth.login')}
								</a>
							{/if}
						{/if}

						<!-- Mobile hamburger -->
						<button
							class="sm:hidden ml-1 p-2 min-h-10 min-w-10 rounded-full inline-flex items-center justify-center text-(--text-muted) hover:text-(--text) hover:bg-(--bg-card) transition-colors"
							onclick={() => (mobileMenuOpen = !mobileMenuOpen)}
							aria-label="Menu"
						>
							{#if mobileMenuOpen}
								<svg
									xmlns="http://www.w3.org/2000/svg"
									class="h-5 w-5"
									viewBox="0 0 20 20"
									fill="currentColor"
								>
									<path
										fill-rule="evenodd"
										d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
										clip-rule="evenodd"
									/>
								</svg>
							{:else}
								<svg
									xmlns="http://www.w3.org/2000/svg"
									class="h-5 w-5"
									viewBox="0 0 20 20"
									fill="currentColor"
								>
									<path
										fill-rule="evenodd"
										d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z"
										clip-rule="evenodd"
									/>
								</svg>
							{/if}
						</button>
					</div>
				</div>

				<!-- Mobile dropdown -->
				{#if mobileMenuOpen}
					<div
						class="sm:hidden absolute top-[calc(100%+0.45rem)] left-2 right-2 z-30 rounded-2xl border border-[var(--border)]/70 bg-[var(--bg)]/86 backdrop-blur-xl px-3 py-3 flex flex-col gap-1 shadow-[0_22px_50px_rgba(0,0,0,0.48)]"
					>
						<a
							href="/learn"
							class="px-3 py-2 rounded-xl transition-colors text-sm {page.url.pathname.startsWith(
								'/learn',
							)
								? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
								: 'text-[var(--text-muted)]'}"
						>
							{t('nav.learn')}
						</a>
						<a
							href="/train"
							class="px-3 py-2 rounded-xl transition-colors text-sm {page.url.pathname.startsWith(
								'/train',
							)
								? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
								: 'text-[var(--text-muted)]'}"
						>
							{t('nav.train')}
						</a>
						<a
							href="/for-educators"
							class="px-3 py-2 rounded-xl transition-colors text-sm {page.url.pathname ===
							'/for-educators'
								? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
								: 'text-[var(--text-muted)]'}"
						>
							{t('nav.educators')}
						</a>
						<a
							href="/pricing"
							class="px-3 py-2 rounded-xl transition-colors text-sm {page.url.pathname === '/pricing'
								? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
								: 'text-[var(--text-muted)]'}"
						>
							{t('nav_auth.pricing')}
						</a>
						{#if isAdmin}
							<a
								href="/admin"
								class="px-3 py-2 rounded-xl transition-colors text-sm {page.url.pathname === '/admin'
									? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium'
									: 'text-[var(--text-dim)]'}"
							>
								Admin
							</a>
						{/if}
					</div>
				{/if}
			</div>
		</nav>

		<!-- Sync banner for non-logged-in users with existing data -->
		{#if showSyncBanner && !isEmbedRoute}
			<div class="bg-[var(--primary)]/10 border-b border-[var(--primary)]/20 px-4 py-2.5">
				<div class="max-w-[1600px] mx-auto flex items-center justify-between gap-4 text-sm">
					<div class="flex items-center gap-2">
						<span>☁️</span>
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
