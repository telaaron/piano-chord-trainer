<script lang="ts">
	import { t } from '$lib/i18n';
</script>

<svelte:head>
	<title>{t('terms.title')} – jazzchords.app</title>
	<meta name="description" content={t('terms.meta_desc')} />
	<meta name="robots" content="noindex" />
</svelte:head>

<main class="flex-1 px-4 py-16 sm:py-20" style="background: linear-gradient(180deg, var(--bg) 0%, color-mix(in srgb, var(--bg) 92%, var(--primary)) 40%, var(--bg) 100%);">
	<div class="max-w-3xl mx-auto prose-custom">
		<h1>{t('terms.h1')}</h1>
		<p class="meta">{t('terms.last_updated')}</p>

		<p>{t('terms.intro')}</p>

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
		<p>{@html t('terms.p_data')}</p>

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
		<p>{@html t('terms.p_governing')}</p>

		<h2>{t('terms.h_contact')}</h2>
		<p>{@html t('terms.p_contact')}</p>
	</div>
</main>
