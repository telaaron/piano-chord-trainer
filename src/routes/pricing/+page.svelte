<script lang="ts">
	import { t } from '$lib/i18n';
	import { isBeta } from '$lib/services/subscription';
	import { getAuthState } from '$lib/services/auth';
	import { toastError } from '$lib/services/toast';
	import { goto } from '$app/navigation';

	let { data } = $props();
	const beta = isBeta();
	let checkoutLoading = $state('');

	async function startCheckout(priceId: string, planId: string) {
		const { user } = getAuthState();
		if (!user) {
			goto(`/auth/login?redirect=/pricing`);
			return;
		}
		checkoutLoading = planId;
		try {
			const res = await fetch('/api/stripe/checkout', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ priceId }),
			});
			const json = await res.json();
			if (!res.ok || !json.url) {
				toastError(json.error || 'Checkout failed');
				return;
			}
			window.location.href = json.url;
		} finally {
			checkoutLoading = '';
		}
	}

	const plans = [
		{
			id: 'free',
			key: 'pricing.free',
			price: '0',
			period: '',
			features: [
				'pricing.feat_all_courses',
				'pricing.feat_speed_drill',
				'pricing.feat_shell_voicings',
				'pricing.feat_midi_mic',
				'pricing.feat_habit_basic',
				'pricing.feat_i18n',
			],
			cta: 'pricing.cta_free',
			href: '/train',
			highlighted: false,
		},
		{
			id: 'pro',
			key: 'pricing.pro',
			price: '4.99',
			period: 'pricing.per_month',
			features: [
				'pricing.feat_everything_free',
				'pricing.feat_adaptive',
				'pricing.feat_all_voicings',
				'pricing.feat_voice_leading',
				'pricing.feat_custom_progressions',
				'pricing.feat_advanced_stats',
				'pricing.feat_cloud_sync',
			],
			cta: 'pricing.cta_pro',
			href: '/auth/login',
			highlighted: true,
		},
		{
			id: 'educator',
			key: 'pricing.educator',
			price: '29',
			period: 'pricing.per_month',
			features: [
				'pricing.feat_everything_pro',
				'pricing.feat_embed',
				'pricing.feat_student_progress',
				'pricing.feat_30_students',
			],
			cta: 'pricing.cta_educator',
			href: 'mailto:info@jazzchords.app?subject=Educator%20Plan',
			highlighted: false,
		},
		{
			id: 'institution',
			key: 'pricing.institution',
			price: '99',
			period: 'pricing.per_month',
			features: [
				'pricing.feat_everything_educator',
				'pricing.feat_custom_branding',
				'pricing.feat_lms',
				'pricing.feat_api',
				'pricing.feat_sso',
				'pricing.feat_unlimited_students',
			],
			cta: 'pricing.cta_institution',
			href: 'mailto:info@jazzchords.app?subject=Institution%20Plan',
			highlighted: false,
		},
	];
</script>

<svelte:head>
	<title>{t('pricing.title')} – jazzchords.app</title>
	<meta name="description" content={t('pricing.meta_desc')} />
</svelte:head>

<main class="flex-1 px-4 py-16 sm:py-20">
	<div class="max-w-6xl mx-auto space-y-12">
		<!-- Header -->
		<div class="text-center space-y-4">
			<h1 class="text-3xl sm:text-4xl font-bold text-gradient">{t('pricing.heading')}</h1>
			<p class="text-lg text-[var(--text-muted)] max-w-2xl mx-auto">{t('pricing.subheading')}</p>
		</div>

		<!-- Beta banner -->
		{#if beta}
			<div class="max-w-2xl mx-auto p-4 rounded-sm bg-[var(--gold)]/10 border border-[var(--gold)]/30 text-center">
				<p class="font-semibold text-[var(--gold)]">🎉 {t('pricing.beta_banner_title')}</p>
				<p class="text-sm text-[var(--text-muted)] mt-1">{t('pricing.beta_banner_desc')}</p>
			</div>
		{/if}

		<!-- Plans grid -->
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
			{#each plans as plan}
				<div class="card p-6 flex flex-col relative {plan.highlighted ? 'border-[var(--primary)]/50 ring-1 ring-[var(--primary)]/20' : ''} {beta && plan.id !== 'free' ? 'opacity-50' : ''}">
					{#if plan.highlighted && !beta}
						<div class="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-0.5 rounded-full bg-[var(--primary)] text-white text-xs font-medium">
							{t('pricing.popular')}
						</div>
					{/if}

					{#if beta && plan.id !== 'free'}
						<div class="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-0.5 rounded-full bg-[var(--gold)] text-black text-xs font-medium">
							{t('pricing.beta_free')}
						</div>
					{/if}

					<h2 class="text-lg font-bold">{t(plan.key)}</h2>

					<div class="mt-3 mb-4">
						{#if beta && plan.id !== 'free'}
							<span class="text-3xl font-bold text-[var(--text-dim)] line-through">{plan.price} €</span>
							<span class="text-2xl font-bold text-[var(--gold)] ml-2">0 €</span>
						{:else}
							<span class="text-3xl font-bold">{plan.price} €</span>
						{/if}
						{#if plan.period}
							<span class="text-sm text-[var(--text-dim)]"> / {t(plan.period)}</span>
						{/if}
					</div>

					<ul class="flex-1 space-y-2 mb-6">
						{#each plan.features as feat}
							<li class="flex items-start gap-2 text-sm text-[var(--text-muted)]">
								<span class="text-[var(--primary)] mt-0.5 shrink-0">✓</span>
								{t(feat)}
							</li>
						{/each}
					</ul>

					{#if beta && plan.id !== 'free'}
						<button disabled class="w-full py-2.5 px-4 rounded-sm font-medium bg-[var(--card-bg)] border border-[var(--border)] text-[var(--text-dim)] cursor-not-allowed">
							{t('pricing.coming_soon')}
						</button>
					{:else if plan.id === 'pro'}
						<button
							onclick={() => startCheckout(data.priceIdPro, 'pro')}
							disabled={checkoutLoading === 'pro'}
							class="w-full py-2.5 px-4 rounded-sm font-medium text-center transition-all
								bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white
								disabled:opacity-60 disabled:cursor-wait"
						>
							{checkoutLoading === 'pro' ? '...' : t(plan.cta)}
						</button>
					{:else}
						<a
							href={plan.href}
							class="w-full py-2.5 px-4 rounded-sm font-medium text-center transition-all block
								{plan.highlighted ? 'bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white' : 'bg-[var(--card-bg)] border border-[var(--border)] hover:bg-[var(--bg)] text-[var(--text)]'}"
						>
							{t(plan.cta)}
						</a>
					{/if}
				</div>
			{/each}
		</div>

		<!-- FAQ -->
		<div class="max-w-3xl mx-auto space-y-6">
			<h2 class="text-2xl font-bold text-center">{t('pricing.faq_heading')}</h2>
			<div class="space-y-4">
				{#each ['beta', 'data', 'cancel', 'educator'] as faq}
					<details class="card p-4 group">
						<summary class="cursor-pointer font-medium text-[var(--text)] group-open:text-[var(--primary)] transition-colors">
							{t(`pricing.faq_${faq}_q`)}
						</summary>
						<p class="mt-2 text-sm text-[var(--text-muted)]">{t(`pricing.faq_${faq}_a`)}</p>
					</details>
				{/each}
			</div>
		</div>
	</div>
</main>
