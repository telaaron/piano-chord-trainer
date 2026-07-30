<script lang="ts">
	import { t } from '$lib/i18n';
	// This page is prerendered, so {@html t(...)} would freeze the build-time
	// (English) locale into the markup. RichText re-reads t() after hydration.
	import RichText from '$lib/components/RichText.svelte';

	/* The i18n headline carries a hard <br>. Rendering it raw and hiding the
	   break with CSS butts the words together ("2 AM,because"), so split on the
	   break instead and let each part be its own line — which collapses to a
	   normal wrap with proper spacing once the lines are set inline. */
	const headlineParts = t('about.h1').split(/<br\s*\/?>/i);
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

<div class="edi flex-1">
	<!-- ═══ Masthead statement ═══ -->
	<header class="head">
		<div class="shell">
			<p class="eyebrow">{t('about.eyebrow')}</p>
			<h1 class="head-h1">
				{#each headlineParts as part, i}<span class="hl">{part.trim()}</span>{#if i < headlineParts.length - 1}{' '}{/if}{/each}
			</h1>
		</div>
	</header>

	<!-- ═══ The story — one column, generous measure ═══ -->
	<section class="shell">
		<div class="story">
			<RichText key="about.p1" class="lede" />
			<RichText key="about.p2" />
			<RichText key="about.p3" />
		</div>

		<!-- ═══ Colophon: who prints this ═══ -->
		<div class="colophon">
			<div class="col">
				<p class="plate">{t('about.company_title')}</p>
				<RichText key="about.company_address" class="col-body" />
			</div>
			<div class="col">
				<p class="plate">{t('about.contact_title')}</p>
				<p class="col-body">
					<a href="mailto:info@jazzchords.app">info@jazzchords.app</a><br />
					<a href="/impressum">{t('nav.impressum')}</a><br />
					<a href="/privacy">{t('nav.privacy')}</a>
				</p>
			</div>
		</div>
	</section>
</div>

<style>
	/* The about page is the colophon of the press: a masthead statement, one
	   column of set text, and the imprint. No photo, no cards — the typography
	   carries it. Structure from hairlines and whitespace only. */

	.edi {
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		font-variant-numeric: oldstyle-nums;
	}

	.shell {
		max-width: 720px;
		margin: 0 auto;
		padding: 0 1.25rem;
	}
	@media (min-width: 900px) {
		.shell { padding: 0 2rem; }
	}

	.eyebrow {
		display: flex;
		align-items: center;
		gap: 0.625rem;
		margin: 0;
		font-family: var(--font-mono);
		font-size: 0.66rem;
		font-weight: 600;
		letter-spacing: 0.19em;
		text-transform: uppercase;
		color: var(--primary);
	}
	.eyebrow::after {
		content: '';
		flex: 1;
		min-width: 1rem;
		height: 1px;
		background: currentColor;
		opacity: 0.32;
	}

	.plate {
		margin: 0;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	/* ── Masthead ─────────────────────────────────────────────── */

	.head {
		padding: 3.5rem 0 2.5rem;
		border-bottom: 1px solid var(--rule-soft);
	}
	@media (min-width: 900px) {
		.head { padding: 5.5rem 0 3.25rem; }
	}

	.head-h1 {
		margin: 1.1rem 0 0;
		font-family: var(--font-display);
		font-size: clamp(1.95rem, 4.6vw, 3.1rem);
		font-weight: 600;
		line-height: 1.1;
		letter-spacing: -0.025em;
		max-width: 16em;
		text-wrap: balance;
		color: var(--text);
	}
	/* The h1 copy carries a hard line break from i18n — honour it on wide
	   screens, but let the line wrap naturally once the measure is narrow.
	   `display:none` would butt the two words together ("2 AM,because"), so
	   collapse the break to a space instead. */
	/* Each headline part is a block on wide screens (honouring the author's
	   intended break) and inline once the measure is narrow, where the space
	   emitted between parts lets it wrap like ordinary prose. */
	@media (min-width: 561px) {
		.head-h1 .hl { display: block; }
	}

	/* ── The story ────────────────────────────────────────────── */

	.story {
		padding: 2.75rem 0 3rem;
	}
	@media (min-width: 900px) {
		.story { padding: 3.5rem 0 4rem; }
	}

	.story :global(p) {
		margin: 0 0 1.35rem;
		max-width: 62ch;
		font-size: 1.02rem;
		line-height: 1.75;
		color: var(--text-muted);
	}
	.story :global(p:last-child) { margin-bottom: 0; }

	/* The opening paragraph is set larger — a printed drop-in.
	   :global because RichText renders it in its own component scope. */
	.story :global(.lede) {
		font-family: var(--font-display);
		font-size: clamp(1.12rem, 2.3vw, 1.35rem);
		line-height: 1.6;
		color: var(--text);
	}

	/* The teacher's line, marked in red pencil. */
	.story :global(.accent) {
		font-style: italic;
		font-weight: 600;
		color: var(--primary);
	}
	.story :global(strong) { color: var(--text); }

	/* ── Colophon / imprint ───────────────────────────────────── */

	.colophon {
		display: grid;
		gap: 2rem;
		padding: 1.75rem 0 4rem;
		border-top: 2px solid var(--text);
	}
	@media (min-width: 560px) {
		.colophon { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 2.5rem; }
	}

	.col-body {
		margin: 0.7rem 0 0;
		font-size: 0.9rem;
		line-height: 1.8;
		color: var(--text-muted);
	}
	.col-body :global(a) {
		color: var(--text-muted);
		text-decoration: underline;
		text-underline-offset: 3px;
		text-decoration-color: var(--border-hover);
		transition: color 0.15s, text-decoration-color 0.15s;
	}
	.col-body :global(a:hover) {
		color: var(--primary);
		text-decoration-color: var(--primary);
	}
</style>
