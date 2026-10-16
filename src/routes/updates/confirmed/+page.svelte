<script lang="ts">
	// Where Brevo's double opt-in link lands. Most people who get here have no
	// account, so /account?updates=confirmed (which needs a login) would greet
	// them with a sign-in wall right after they said yes. One line of
	// confirmation and the shortest way back to the keys.
	import { t } from '$lib/i18n';
	import { Check } from 'lucide-svelte';
</script>

<svelte:head>
	<title>{t('practice_mail.confirmed_page_title')} — jazzchords.app</title>
	<meta name="robots" content="noindex" />
</svelte:head>

<div class="shell">
	<span class="mark" aria-hidden="true"><Check size={18} /></span>
	<h1 class="h1">{t('practice_mail.confirmed_page_title')}</h1>
	<p class="lede">{t('practice_mail.confirmed_page_desc')}</p>
	<a href="/train" class="pill-btn pill-btn-primary cta">{t('practice_mail.confirmed_page_cta')}</a>
</div>

<style>
	.shell {
		width: 100%;
		max-width: 36rem;
		margin: 0 auto;
		padding: 3rem 1.25rem 6rem;
		font-family: var(--font-sans);
	}
	.mark {
		display: inline-grid;
		place-items: center;
		width: 2.25rem;
		height: 2.25rem;
		border-radius: 999px;
		background: color-mix(in srgb, var(--primary) 16%, transparent);
		color: var(--primary);
	}
	.h1 {
		margin: 1rem 0 0;
		font-family: var(--font-display);
		font-size: clamp(1.9rem, 6vw, 2.5rem);
		font-weight: 600;
		line-height: 1.12;
		color: var(--text);
	}
	.lede {
		margin: 0.9rem 0 0;
		max-width: 60ch;
		line-height: 1.6;
		color: var(--text-muted);
	}
	.cta {
		display: inline-block;
		margin-top: 1.75rem;
		padding: 0.75rem 1.5rem;
	}
</style>
