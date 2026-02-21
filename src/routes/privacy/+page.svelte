<script lang="ts">
	import { t } from '$lib/i18n';
</script>

<svelte:head>
	<title>{t('privacy.title')}</title>
	<meta name="description" content={t('privacy.meta_desc')} />
	<meta name="robots" content="noindex" />
</svelte:head>

<main class="flex-1 px-4 py-16 sm:py-20" style="background: linear-gradient(180deg, var(--bg) 0%, #110e0a 30%, #0d0b08 60%, var(--bg) 100%);">
	<div class="max-w-3xl mx-auto prose-custom">
		<h1>{t('privacy.h1')}</h1>
		<p class="meta">{t('privacy.last_updated')}</p>

		<p>
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
				<tr>
					<td>Google Fonts</td>
					<td>{t('privacy.td_fonts_purpose')}</td>
					<td><a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer">{t('privacy.td_link')}</a></td>
				</tr>
				<tr>
					<td>Cloudflare</td>
					<td>{t('privacy.td_cloudflare_purpose')}</td>
					<td><a href="https://www.cloudflare.com/privacypolicy/" target="_blank" rel="noopener noreferrer">{t('privacy.td_link')}</a></td>
				</tr>
			</tbody>
		</table>

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
	</div>
</main>
