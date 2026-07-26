<script lang="ts">
	import { t } from '$lib/i18n';
</script>

<svelte:head>
	<title>{t('privacy.title')}</title>
	<meta name="description" content={t('privacy.meta_desc')} />
	<meta name="robots" content="noindex" />
</svelte:head>

<main class="legal">
	<article class="legal-sheet">
		<header class="legal-head">
			<p class="plate">{t('nav.privacy')}</p>
			<h1>{t('privacy.h1')}</h1>
			<p class="meta">{t('privacy.last_updated')}</p>
		</header>

		<p class="lede">
			{@html t('privacy.intro')}
		</p>

		<h2>{t('privacy.h_data_collect')}</h2>

		<h3>{t('privacy.h_local_storage')}</h3>
		<p>
			{@html t('privacy.p_local_storage')}
		</p>
		<ul>
			<li>{t('privacy.li_settings')}</li>
			<li>{t('privacy.li_history')}</li>
			<li>{t('privacy.li_streak')}</li>
			<li>{t('privacy.li_theme')}</li>
		</ul>
		<p>
			{@html t('privacy.p_local_storage_end')}
		</p>

		<h3>{t('privacy.h_midi')}</h3>
		<p>
			{@html t('privacy.p_midi')}
		</p>

		<h3>{t('privacy.h_analytics')}</h3>
		<p>
			{@html t('privacy.p_analytics')}
		</p>

		<h3>{t('privacy.h_hosting')}</h3>
		<p>
			{@html t('privacy.p_hosting')}
		</p>

		<h3>{t('privacy.h_fonts')}</h3>
		<p>
			{@html t('privacy.p_fonts')}
		</p>

		<h2>{t('privacy.h_no_collect')}</h2>
		<ul>
			<li>{t('privacy.li_no_account')}</li>
			<li>{t('privacy.li_no_cookies')}</li>
			<li>{t('privacy.li_no_personal')}</li>
			<li>{t('privacy.li_no_audio')}</li>
			<li>{t('privacy.li_no_midi')}</li>
		</ul>

		<h2>{t('privacy.h_third_party')}</h2>
		<div class="legal-table">
		<table>
			<thead>
				<tr><th>{t('privacy.th_service')}</th><th>{t('privacy.th_purpose')}</th><th>{t('privacy.th_policy')}</th></tr>
			</thead>
			<tbody>
				<tr>
					<td>Vercel</td>
					<td>{t('privacy.td_vercel_purpose')}</td>
					<td><a href="https://vercel.com/legal/privacy-policy" target="_blank" rel="noopener noreferrer">{t('privacy.td_link')}</a></td>
				</tr>
				<!-- Google Fonts was here. Type is self-hosted now, so Google is no
				     longer a recipient of anyone's IP and does not belong in this table. -->
				<tr>
					<td>Cloudflare</td>
					<td>{t('privacy.td_cloudflare_purpose')}</td>
					<td><a href="https://www.cloudflare.com/privacypolicy/" target="_blank" rel="noopener noreferrer">{t('privacy.td_link')}</a></td>
				</tr>
				<tr>
					<td>Supabase</td>
					<td>{t('privacy.td_supabase_purpose')}</td>
					<td><a href="https://supabase.com/privacy" target="_blank" rel="noopener noreferrer">{t('privacy.td_link')}</a></td>
				</tr>
				<tr>
					<td>Stripe</td>
					<td>{t('privacy.td_stripe_purpose')}</td>
					<td><a href="https://stripe.com/privacy" target="_blank" rel="noopener noreferrer">{t('privacy.td_link')}</a></td>
				</tr>
			</tbody>
		</table>
		</div>

		<h2>{t('privacy.h_rights')}</h2>
		<p>{t('privacy.p_rights')}</p>
		<ul>
			<li>{@html t('privacy.li_access')}</li>
			<li>{@html t('privacy.li_delete')}</li>
			<li>{@html t('privacy.li_portability')}</li>
			<li>{@html t('privacy.li_object')}</li>
		</ul>

		<h2>{t('privacy.h_children')}</h2>
		<p>
			{t('privacy.p_children')}
		</p>

		<h2>{t('privacy.h_changes')}</h2>
		<p>
			{t('privacy.p_changes')}
		</p>

		<h2>{t('privacy.h_contact')}</h2>
		<p>
			{@html t('privacy.contact_address')}<br />
			{t('privacy.contact_email')} <a href="mailto:info@jazzchords.app">info@jazzchords.app</a><br />
			{t('privacy.contact_alt')} <a href="mailto:admin@must-seen.com">admin@must-seen.com</a><br />
			{t('privacy.contact_phone')} +49 15679 706761<br />
			{t('privacy.contact_website')} <a href="https://jazzchords.app">jazzchords.app</a>
		</p>
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
	.lede {
		font-size: 1.08rem;
		line-height: 1.65;
		color: var(--text);
		margin-bottom: 2.4rem;
	}

	/* Numbered clause headings — the copyist's structure, in blue */
	.legal-sheet :global(h2) {
		counter-increment: clause;
		display: flex;
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
	/* Privacy's headings already carry their own numbers in the copy
	   (both locales), so the counter would double-number them. The clause
	   rule and rhythm stay; only the generated numeral is suppressed. */
	.legal-sheet :global(h2)::before {
		content: none;
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

	/* Third-party register — a ruled table, no zebra fill */
	.legal-sheet :global(table) {
		width: 100%;
		border-collapse: collapse;
		margin: 0 0 1.6rem;
		font-size: 0.85rem;
		line-height: 1.5;
	}
	.legal-sheet :global(thead th) {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		font-weight: 600;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
		text-align: left;
		padding: 0 0.9rem 0.5rem 0;
		border-bottom: 1px solid var(--text-muted);
	}
	.legal-sheet :global(tbody td) {
		padding: 0.7rem 0.9rem 0.7rem 0;
		border-bottom: 1px solid color-mix(in srgb, var(--border) 70%, transparent);
		vertical-align: top;
	}
	.legal-sheet :global(tbody td:first-child) {
		color: var(--text);
		font-weight: 600;
		white-space: nowrap;
	}
	.legal-sheet :global(tbody td:last-child),
	.legal-sheet :global(thead th:last-child) {
		padding-right: 0;
	}
	.legal-table {
		overflow-x: auto;
		margin-bottom: 1.6rem;
	}
	/* The register scrolls inside its own wrapper rather than pushing the
	   document sideways. 22rem is the narrowest the three columns stay
	   legible, so the sideways drag on a phone is as short as possible. */
	.legal-table :global(table) {
		min-width: 22rem;
		margin-bottom: 0;
	}
</style>
