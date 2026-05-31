<script lang="ts">
	import { t } from '$lib/i18n';
	import { isBeta } from '$lib/services/subscription';
	import { getAuthState } from '$lib/services/auth';
	import { toastError } from '$lib/services/toast';
	import { goto } from '$app/navigation';
	import { Icon } from '$lib/components/ui';

	const offerItems = [
		{ icon: 'warmup', titleKey: 'pricing.offer_trial_title', descKey: 'pricing.offer_trial_desc' },
		{ icon: 'personal-best', titleKey: 'pricing.offer_guarantee_title', descKey: 'pricing.offer_guarantee_desc' },
		{ icon: 'speed', titleKey: 'pricing.offer_speed_title', descKey: 'pricing.offer_speed_desc' },
		{ icon: 'settings', titleKey: 'pricing.offer_cancel_title', descKey: 'pricing.offer_cancel_desc' },
	];

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
			<div class="max-w-2xl mx-auto p-4 surface-glass text-center">
				<p class="font-semibold text-[var(--accent-gold)]">🎉 {t('pricing.beta_banner_title')}</p>
				<p class="text-sm text-[var(--text-muted)] mt-1">{t('pricing.beta_banner_desc')}</p>
			</div>
		{/if}

		<!-- Grand-slam risk reversal -->
		<div class="max-w-5xl mx-auto">
			<div class="text-center mb-6">
				<h2 class="text-2xl sm:text-3xl font-bold text-[var(--text)]">{t('pricing.offer_title')}</h2>
				<p class="mt-2 text-[var(--text-muted)] max-w-2xl mx-auto">{t('pricing.offer_subtitle')}</p>
			</div>
			<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
				{#each offerItems as item}
					<div class="surface-glass rounded-2xl p-5 flex flex-col items-center text-center gap-2">
						<div class="grid h-12 w-12 place-items-center rounded-2xl bg-[var(--primary-muted)]">
							<Icon name={item.icon} size={28} />
						</div>
						<h3 class="font-semibold text-[var(--text)]">{t(item.titleKey)}</h3>
						<p class="text-sm text-[var(--text-muted)] leading-relaxed">{t(item.descKey)}</p>
					</div>
				{/each}
			</div>
		</div>

		<!-- Plans grid -->
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
			{#each plans as plan}
				<div class="card surface-glass p-6 flex flex-col relative {plan.highlighted ? 'border-[var(--primary)]/50 ring-1 ring-[var(--primary)]/20' : ''} {beta && plan.id !== 'free' ? 'opacity-50' : ''}">
					{#if plan.highlighted && !beta}
						<div class="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-0.5 rounded-full bg-[var(--primary)] text-white text-xs font-medium">
							{t('pricing.popular')}
						</div>
					{/if}

					{#if beta && plan.id !== 'free'}
						<div class="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-0.5 rounded-full bg-[var(--accent-gold)] text-black text-xs font-medium">
							{t('pricing.beta_free')}
						</div>
					{/if}

					<h2 class="text-lg font-bold">{t(plan.key)}</h2>

					<div class="mt-3 mb-4">
						{#if beta && plan.id !== 'free'}
							<span class="text-3xl font-bold text-[var(--text-dim)] line-through">{plan.price} €</span>
							<span class="text-2xl font-bold text-[var(--accent-gold)] ml-2">0 €</span>
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
						<button disabled class="w-full py-2.5 px-4 pill-btn pill-btn-secondary font-medium text-[var(--text-dim)] cursor-not-allowed">
							{t('pricing.coming_soon')}
						</button>
					{:else if plan.id === 'pro'}
						<button
							onclick={() => startCheckout(data.priceIdPro, 'pro')}
							disabled={checkoutLoading === 'pro'}
							class="w-full py-2.5 px-4 pill-btn pill-btn-primary font-medium text-center transition-all
								text-white
								disabled:opacity-60 disabled:cursor-wait"
						>
							{checkoutLoading === 'pro' ? '...' : t('pricing.cta_pro_trial')}
						</button>
						<p class="mt-2 text-center text-xs text-[var(--text-dim)]">{t('pricing.pro_trial_note')}</p>
					{:else}
						<a
							href={plan.href}
							class="w-full py-2.5 px-4 pill-btn font-medium text-center transition-all block
								{plan.highlighted ? 'pill-btn-primary text-white' : 'pill-btn-secondary text-[var(--text)]'}"
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
				{#each (beta ? ['beta', 'data', 'cancel', 'educator'] : ['trial', 'guarantee', 'cancel', 'data', 'educator']) as faq}
					<details class="card surface-glass p-4 group">
						<summary class="cursor-pointer font-medium text-[var(--text)] group-open:text-[var(--primary)] transition-colors">
							{t(`pricing.faq_${faq}_q`)}
						</summary>
						<p class="mt-2 text-sm text-[var(--text-muted)]">{t(`pricing.faq_${faq}_a`)}</p>
					</details>
				{/each}
			</div>
		</div>

		<!-- Feedback / open to extensions -->
		<div class="max-w-2xl mx-auto surface-glass rounded-2xl p-6 sm:p-8 text-center space-y-3">
			<div class="grid h-12 w-12 mx-auto place-items-center rounded-2xl bg-[var(--primary-muted)]">
				<Icon name="listen" size={28} />
			</div>
			<h2 class="text-xl font-bold text-[var(--text)]">{t('pricing.feedback_title')}</h2>
			<p class="text-[var(--text-muted)] leading-relaxed">{t('pricing.feedback_desc')}</p>
			<a
				href="mailto:info@jazzchords.app?subject=Feedback"
				class="pill-btn pill-btn-secondary inline-flex px-5 py-2.5 no-underline"
			>
				{t('pricing.feedback_cta')}
			</a>
		</div>
	</div>
</main>
