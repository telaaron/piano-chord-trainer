<script lang="ts">
	import { t } from '$lib/i18n';
	// This page is prerendered, so {@html t(...)} would freeze the build-time
	// (English) locale into the markup. RichText re-reads t() after hydration.
	import RichText from '$lib/components/RichText.svelte';
</script>

<svelte:head>
	<title>{t('terms.title')} – jazzchords.app</title>
	<meta name="description" content={t('terms.meta_desc')} />
	<meta name="robots" content="noindex" />
</svelte:head>

<main class="legal">
	<article class="legal-sheet">
		<header class="legal-head">
			<p class="plate">{t('nav_auth.terms')}</p>
			<h1>{t('terms.h1')}</h1>
			<p class="meta">{t('terms.last_updated')}</p>
		</header>

		<p class="lede">{t('terms.intro')}</p>

		<h2>{t('terms.h_acceptance')}</h2>
		<p>{t('terms.p_acceptance')}</p>

		<h2>{t('terms.h_service')}</h2>
		<p>{t('terms.p_service')}</p>

		<h2>{t('terms.h_accounts')}</h2>
		<p>{t('terms.p_accounts')}</p>

		<h2>{t('terms.h_free')}</h2>
		<p>{t('terms.p_free')}</p>

		<h2>{t('terms.h_subscriptions')}</h2>
		<p>{t('terms.p_subscriptions')}</p>

		<h2>{t('terms.h_withdrawal')}</h2>
		<p>{t('terms.p_withdrawal')}</p>

		<h2>{t('terms.h_data')}</h2>
		<RichText key="terms.p_data" />

		<h2>{t('terms.h_ip')}</h2>
		<p>{t('terms.p_ip')}</p>

		<h2>{t('terms.h_prohibited')}</h2>
		<p>{t('terms.p_prohibited')}</p>
		<ul>
			<li>{t('terms.li_prohibited_1')}</li>
			<li>{t('terms.li_prohibited_2')}</li>
			<li>{t('terms.li_prohibited_3')}</li>
			<li>{t('terms.li_prohibited_4')}</li>
		</ul>

		<h2>{t('terms.h_liability')}</h2>
		<p>{t('terms.p_liability')}</p>

		<h2>{t('terms.h_termination')}</h2>
		<p>{t('terms.p_termination')}</p>

		<h2>{t('terms.h_changes')}</h2>
		<p>{t('terms.p_changes')}</p>

		<h2>{t('terms.h_governing')}</h2>
		<RichText key="terms.p_governing" />

		<h2>{t('terms.h_contact')}</h2>
		<RichText key="terms.p_contact" />
	</article>
</main>

<style>
	/* ── Long-form legal setting ──────────────────────────────────────
	   A single column of text at a proper measure. Headings are numbered
	   by the counter, so the document reads as a printed instrument with
	   clauses, and the rhythm comes from space + hairlines, not boxes. */
	.legal {
		flex: 1;
		padding: clamp(2.5rem, 7vw, 4.5rem) clamp(1rem, 5vw, 2rem) 5rem;
	}
	.legal-sheet {
		/* 66ch on the body size lands inside the 60–75 character window */
		max-width: 66ch;
		margin: 0 auto;
		counter-reset: clause;
		font-size: 1rem;
		line-height: var(--leading-relaxed);
		color: var(--text-muted);
	}

	.legal-head {
		padding-bottom: 1.4rem;
		margin-bottom: 2.2rem;
		border-bottom: 1px solid var(--border);
	}
	.plate {
		font-family: var(--font-mono);
		font-size: 0.62rem;
		letter-spacing: 0.18em;
		text-transform: uppercase;
		color: var(--primary);
		margin-bottom: 0.9rem;
	}
	.legal-sheet :global(h1) {
		font-family: var(--font-display);
		font-size: clamp(1.9rem, 5.5vw, 2.6rem);
		font-weight: 600;
		line-height: 1.1;
		letter-spacing: -0.025em;
		color: var(--text);
		margin: 0;
	}
	.meta {
		margin-top: 0.7rem;
		font-family: var(--font-mono);
		font-size: 0.68rem;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	/* The lede is an opening paragraph, not a subheading: it stays on the
	   sans so it belongs to the body, and earns its emphasis from size and
	   ink instead of switching face. */
	/* :global because RichText renders this <p> in its own component scope. */
	.legal-sheet :global(.lede) {
		font-size: 1.08rem;
		line-height: 1.65;
		color: var(--text);
		margin-bottom: 2.4rem;
	}

	/* Numbered clause headings — the copyist's structure, in blue */
	.legal-sheet :global(h2) {
		counter-increment: clause;
		display: flex;
		gap: 0.7rem;
		align-items: baseline;
		font-family: var(--font-display);
		font-size: 1.3rem;
		font-weight: 600;
		line-height: 1.25;
		letter-spacing: -0.015em;
		color: var(--text);
		margin: 2.6rem 0 0.8rem;
		padding-top: 1.3rem;
		border-top: 1px solid color-mix(in srgb, var(--border) 70%, transparent);
	}
	/* The first clause sits directly under the header rule — no second rule,
	   no hole. The header already provides the division. */
	.legal-sheet > :global(h2:first-of-type) {
		margin-top: 0;
		padding-top: 0;
		border-top: none;
	}
	.legal-sheet :global(h2)::before {
		content: counter(clause);
		font-family: var(--font-mono);
		font-size: 0.78rem;
		font-weight: 600;
		letter-spacing: 0.06em;
		color: var(--ink-blue);
		flex: none;
		min-width: 1.1rem;
	}
	.legal-sheet :global(h3) {
		font-family: var(--font-display);
		font-size: 1.05rem;
		font-weight: 600;
		color: var(--text);
		margin: 2rem 0 0.5rem;
	}

	.legal-sheet :global(p) {
		margin: 0 0 1.15rem;
	}
	.legal-sheet :global(p:last-child) {
		margin-bottom: 0;
	}
	.legal-sheet :global(strong) {
		color: var(--text);
		font-weight: 600;
	}

	/* Lists sit in the margin, marked with a stamp-red rule */
	.legal-sheet :global(ul) {
		list-style: none;
		margin: 0 0 1.4rem;
		padding: 0;
	}
	.legal-sheet :global(ul li) {
		position: relative;
		padding-left: 1.4rem;
		margin-bottom: 0.5rem;
	}
	.legal-sheet :global(ul li)::before {
		content: '';
		position: absolute;
		left: 0;
		top: 0.72em;
		width: 0.7rem;
		height: 1px;
		background: var(--primary);
	}

	.legal-sheet :global(a) {
		color: var(--text);
		text-decoration: underline;
		text-decoration-color: var(--primary);
		text-decoration-thickness: 1px;
		text-underline-offset: 3px;
		transition: color 0.15s ease;
	}
	.legal-sheet :global(a:hover) {
		color: var(--primary);
	}
</style>
