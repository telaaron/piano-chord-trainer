<script lang="ts">
	import '../app.css';
	import { page } from '$app/state';
	import { t, setLocale, getLocale, type Locale } from '$lib/i18n';

	let { children } = $props();
	const isTrainPage = $derived(page.url.pathname.startsWith('/train'));
	const isEmbedRoute = $derived(page.url.pathname.startsWith('/embed'));
	
	function toggleLanguage() {
		const current = getLocale();
		setLocale(current === 'en' ? 'de' : 'en');
	}
</script>

<div class="min-h-dvh flex flex-col">
	<!-- Navigation — hidden on embed routes for clean iframe experience -->
	{#if !isEmbedRoute}
	<nav class="sticky top-0 z-10 border-b border-[var(--wood-dark)]/60 bg-[var(--bg)]/75 backdrop-blur-md">
		<div class="max-w-[1600px] mx-auto px-4 sm:px-6 py-3 flex items-center justify-between">
		<a href="/" class="flex items-center gap-2 group">
			<img src="/favicon/favicon.svg" alt="Chord Trainer" class="h-8 w-8 object-contain"
				width="32" height="32" loading="eager" fetchpriority="high" />
			<span class="hidden sm:inline font-bold text-lg text-gradient">jazzchords.app</span>
		</a>

		<div class="flex items-center gap-1 text-sm">
			<a
				href="/train"
				class="px-3 py-1.5 rounded-sm transition-colors {page.url.pathname.startsWith('/train') ? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium' : 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
			>
				{t('nav.train')}
			</a>
			<a
				href="/for-educators"
				class="px-3 py-1.5 rounded-sm transition-colors {page.url.pathname === '/for-educators' ? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium' : 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
			>
				<span class="hidden sm:inline">{t('nav.educators')}</span>
				<span class="sm:hidden">{t('nav.educators_short')}</span>
			</a>
			<button
				onclick={toggleLanguage}
				class="ml-2 px-2 py-1 text-xs font-mono border border-[var(--border)] rounded items-center justify-center opacity-70 hover:opacity-100 transition-opacity"
				title={t('nav.language')}
			>
				{getLocale().toUpperCase()}
			</button>
		</div>
		</div>
	</nav>
	{/if}

	<!-- Content -->
	<div class="flex-1 flex flex-col">
		{@render children()}
	</div>

	<!-- Footer (hidden on train page and embed routes for focus) -->
	{#if !isTrainPage && !isEmbedRoute}
		<footer class="px-4 sm:px-6 py-8 border-t border-[var(--wood-dark)]/40">
			<div class="max-w-5xl mx-auto space-y-5">
				<!-- Logo + Brand -->
				<div class="flex items-center gap-3">
					<img src="/favicon/logo-full.webp" alt="Chord Trainer" class="h-10 w-auto object-contain"
						height="40" loading="lazy" />
					<div>
						<p class="font-bold text-[var(--text)]">Chord Trainer</p>
						<p class="text-xs text-[var(--text-dim)]">{t('nav.subtitle')}</p>
					</div>
				</div>

				<!-- Nav links — wrap freely on mobile -->
				<div class="flex flex-wrap gap-x-5 gap-y-2 text-xs text-[var(--text-dim)]">
					<a href="/for-educators" class="hover:text-[var(--text-muted)] transition-colors">{t('nav.educators')}</a>
					<a href="/about" class="hover:text-[var(--text-muted)] transition-colors">{t('nav.about')}</a>
					<a href="/midi-test" class="hover:text-[var(--text-muted)] transition-colors">{t('nav.midi_test')}</a>
					<a href="/privacy" class="hover:text-[var(--text-muted)] transition-colors">{t('nav.privacy')}</a>
					<a href="/impressum" class="hover:text-[var(--text-muted)] transition-colors">{t('nav.impressum')}</a>
					<a href="mailto:info@jazzchords.app" class="hover:text-[var(--text-muted)] transition-colors">{t('nav.contact')}</a>
				</div>

				<!-- Bottom bar: copyright left, tagline right -->
				<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 text-xs text-[var(--text-dim)]">
					<span>&copy; 2026 Aaron Technologies OÜ</span>
					<span>{t('nav.built_for')}</span>
				</div>
			</div>
		</footer>
	{/if}
</div>
