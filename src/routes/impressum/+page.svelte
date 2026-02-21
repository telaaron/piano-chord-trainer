<script lang="ts">
	import { t } from '$lib/i18n';
</script>

<svelte:head>
	<title>{t('impressum.title')}</title>
	<meta name="description" content={t('impressum.meta_desc')} />
	<meta name="robots" content="noindex" />
</svelte:head>

<main class="flex-1 px-4 py-16 sm:py-20" style="background: linear-gradient(180deg, var(--bg) 0%, #110e0a 30%, #0d0b08 60%, var(--bg) 100%);">
	<div class="max-w-3xl mx-auto prose-custom">
		<h1>{t('impressum.h1')}</h1>
		<p class="meta">{t('impressum.legal_notice')}</p>

		<h2>{t('impressum.service_provider')}</h2>
		<p>
			<strong>Aaron Technologies OÜ</strong><br />
			Sepapaja tn 6<br />
			Lasnamäe linnaosa<br />
			15551 Tallinn<br />
			Harju maakond<br />
			Estonia
		</p>

		<h2>{t('impressum.company_registration')}</h2>
		<p>
			<strong>{t('impressum.registry_code')}</strong> 17336129<br />
			<strong>{t('impressum.vat_id')}</strong> EE102955587<br />
			<strong>{t('impressum.legal_form')}</strong> {t('impressum.legal_form_value')}<br />
			<strong>{t('impressum.trade_register')}</strong> {t('impressum.trade_register_value')}<br />
			<strong>{t('impressum.reg_authority')}</strong> {t('impressum.reg_authority_value')}
		</p>

		<h2>{t('impressum.contact')}</h2>
		<p>
			Email: <a href="mailto:info@jazzchords.app">info@jazzchords.app</a><br />
			Alternative: <a href="mailto:admin@must-seen.com">admin@must-seen.com</a><br />
			Phone: +49 15679 706761<br />
			Website: <a href="https://jazzchords.app">jazzchords.app</a>
		</p>

		<h2>{t('impressum.management')}</h2>
		<p>
			<strong>{t('impressum.managing_director')}</strong> Aaron Julius Pfützner<br />
			<strong>{t('impressum.position')}</strong> CEO & Founder
		</p>

		<h2>{t('impressum.responsible_content')}</h2>
		<p>
			Aaron Julius Pfützner<br />
			Aaron Technologies OÜ
		</p>

		<h2>{t('impressum.dispute_resolution')}</h2>
		<p>
			{t('impressum.online_dispute')}
			<a href="https://ec.europa.eu/consumers/odr/" target="_blank" rel="noopener noreferrer">https://ec.europa.eu/consumers/odr/</a>
		</p>
		<p>
			{t('impressum.consumer_dispute')}
		</p>

		<h2>{t('impressum.liability_content')}</h2>
		<p>
			{t('impressum.liability_content_text')}
		</p>

		<h2>{t('impressum.liability_links')}</h2>
		<p>
			{t('impressum.liability_links_text')}
		</p>
	</div>
</main>
