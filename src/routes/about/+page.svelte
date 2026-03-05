<script lang="ts">
	import { t } from '$lib/i18n';
</script>

<svelte:head>
	<title>{t('about.title')}</title>
	<meta name="description" content={t('about.meta_desc')} />
	<link rel="canonical" href="https://jazzchords.app/about" />
	<meta property="og:title" content={t('about.title')} />
	<meta property="og:description" content={t('about.meta_desc')} />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://jazzchords.app/about" />
	<meta property="og:site_name" content="Chord Trainer" />
	<meta property="og:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta property="og:image:type" content="image/webp" />
	<meta property="og:image:width" content="966" />
	<meta property="og:image:height" content="507" />
	<meta property="og:image:alt" content="Chord Trainer – Jazz Piano Voicing Speed Training" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content={t('about.title')} />
	<meta name="twitter:description" content={t('about.meta_desc')} />
	<meta name="twitter:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta name="twitter:image:alt" content="Chord Trainer – Jazz Piano Voicing Speed Training" />
</svelte:head>

<div class="flex-1">

	<!-- ── 1. Hero ── -->
	<section class="relative min-h-[60vh] overflow-hidden flex items-end">
		<img
			src="/elements/about/hero-keys-closeup.webp"
			alt=""
			aria-hidden="true"
			loading="eager"
			fetchpriority="high"
			class="absolute inset-0 w-full h-full object-cover object-[center_60%] z-0 opacity-[0.55]"
		/>
		<div
			class="absolute inset-0 z-[1]"
			style="background: linear-gradient(to bottom, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.4) 60%, var(--bg) 100%)"
		></div>
		<div class="relative z-[2] w-full text-center px-6 pb-[60px]">
			<p class="text-orange-400 text-[0.85rem] tracking-[0.12em] uppercase mb-4">{t('about.eyebrow')}</p>
			<h1 class="text-[clamp(2rem,5vw,3.5rem)] font-bold text-white max-w-[700px] mx-auto leading-[1.15]">
				{@html t('about.h1')}
			</h1>
		</div>
	</section>

	<!-- ── 2. Story ── -->
	<section class="about-story max-w-[680px] mx-auto py-20 px-6 flex flex-col gap-6 text-[1.05rem] leading-[1.8] text-[var(--text-muted,rgba(255,255,255,0.7))]">
		<p>
			{@html t('about.p1')}
		</p>
		<p>
			{@html t('about.p2')}
		</p>
		<p>
			{@html t('about.p3')}
		</p>
	</section>

	<!-- ── 3. Company block ── -->
	<section class="max-w-[680px] mx-auto pt-12 px-6 pb-20 border-t border-[rgba(255,255,255,0.08)] grid grid-cols-2 gap-10 max-[560px]:grid-cols-1 max-[560px]:gap-8">
		<div>
			<p class="text-orange-400 text-xs uppercase tracking-[0.1em] mb-2.5">{t('about.company_title')}</p>
			<p class="text-[0.9rem] leading-[1.8] text-[var(--text-muted,rgba(255,255,255,0.6))]">
				{@html t('about.company_address')}
			</p>
		</div>
		<div>
			<p class="text-orange-400 text-xs uppercase tracking-[0.1em] mb-2.5">{t('about.contact_title')}</p>
			<p class="text-[0.9rem] leading-[1.8] text-[var(--text-muted,rgba(255,255,255,0.6))]">
				<a href="mailto:info@jazzchords.app" class="text-[var(--text-muted,rgba(255,255,255,0.6))] underline underline-offset-[3px] transition-colors duration-150 hover:text-white">info@jazzchords.app</a><br>
				<a href="/impressum" class="text-[var(--text-muted,rgba(255,255,255,0.6))] underline underline-offset-[3px] transition-colors duration-150 hover:text-white">{t('nav.impressum')}</a><br>
				<a href="/privacy" class="text-[var(--text-muted,rgba(255,255,255,0.6))] underline underline-offset-[3px] transition-colors duration-150 hover:text-white">{t('nav.privacy')}</a>
			</p>
		</div>
	</section>

</div>

<style>
	/* Needed for {@html} injected content */
	.about-story :global(.accent) {
		color: #fb923c;
		font-weight: 600;
	}
</style>
