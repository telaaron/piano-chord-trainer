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
		<h1>Impressum</h1>
		<p class="meta">Legal Notice pursuant to § 5 TMG / Estonian Commercial Code</p>

		<h2>Service Provider</h2>
		<p>
			<strong>Aaron Technologies OÜ</strong><br />
			Sepapaja tn 6<br />
			Lasnamäe linnaosa<br />
			15551 Tallinn<br />
			Harju maakond<br />
			Estonia
		</p>

		<h2>Company Registration</h2>
		<p>
			<strong>Registry Code (Registrikaod):</strong> 17336129<br />
			<strong>VAT ID (KMKR):</strong> EE102955587<br />
			<strong>Legal Form:</strong> Osaühing (Private Limited Company)<br />
			<strong>Trade Register:</strong> Estonian Commercial Register<br />
			<strong>Registration Authority:</strong> Estonian Centre of Registers and Information Systems
		</p>

		<h2>Contact</h2>
		<p>
			Email: <a href="mailto:info@jazzchords.app">info@jazzchords.app</a><br />
			Alternative: <a href="mailto:admin@must-seen.com">admin@must-seen.com</a><br />
			Phone: +49 15679 706761<br />
			Website: <a href="https://jazzchords.app">jazzchords.app</a>
		</p>

		<h2>Management</h2>
		<p>
			<strong>Managing Director (Juhataja):</strong> Aaron Julius Pfützner<br />
			<strong>Position:</strong> CEO & Founder
		</p>

		<h2>Responsible for Content</h2>
		<p>
			Aaron Julius Pfützner<br />
			Aaron Technologies OÜ
		</p>

		<h2>Dispute Resolution</h2>
		<p>
			The European Commission provides an online dispute resolution platform (OS):
			<a href="https://ec.europa.eu/consumers/odr/" target="_blank" rel="noopener noreferrer">https://ec.europa.eu/consumers/odr/</a>
		</p>
		<p>
			We are neither willing nor obliged to participate in dispute resolution proceedings before a consumer arbitration board.
		</p>

		<h2>Liability for Content</h2>
		<p>
			As a service provider, we are responsible for our own content on these pages according to general legislation.
			However, we are not obligated to monitor transmitted or stored third-party information or to investigate
			circumstances that indicate illegal activity.
		</p>

		<h2>Liability for Links</h2>
		<p>
			Our website contains links to external websites over whose content we have no influence.
			We therefore cannot accept any liability for this third-party content.
			The respective provider or operator is always responsible for the content of the linked pages.
		</p>
	</div>
</main>
