<script lang="ts">
	import { t } from '$lib/i18n';
	import { isBeta } from '$lib/services/subscription';
	import { getAuthState } from '$lib/services/auth';
	import { toastError } from '$lib/services/toast';
	import { goto } from '$app/navigation';
	import { Icon } from '$lib/components/ui';
	import { Check } from 'lucide-svelte';

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

	/* Roman numerals rather than a "most popular" rosette: this is a price
	   list in a printed catalogue, and the tiers are numbered entries. */
	const plans = [
		{
			id: 'free',
			num: 'I',
			key: 'pricing.free',
			price: '0',
			period: '',
			features: [
				'pricing.feat_all_courses',
				'pricing.feat_all_voicings_free',
				'pricing.feat_voice_leading_free',
				'pricing.feat_progressions',
				'pricing.feat_midi_mic',
				'pricing.feat_habit_basic',
			],
			cta: 'pricing.cta_free',
			href: '/train',
			highlighted: false,
		},
		{
			id: 'pro',
			num: 'II',
			key: 'pricing.pro',
			price: '4.99',
			period: 'pricing.per_month',
			features: [
				'pricing.feat_everything_free',
				'pricing.feat_adaptive',
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
			num: 'III',
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
			num: 'IV',
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

	const faqKeys = $derived(
		beta ? ['beta', 'data', 'cancel', 'educator'] : ['trial', 'guarantee', 'cancel', 'data', 'educator'],
	);
</script>

<svelte:head>
	<title>{t('pricing.title')} – jazzchords.app</title>
	<meta name="description" content={t('pricing.meta_desc')} />
</svelte:head>

<main class="edi flex-1">
	<!-- ═══ Masthead ═══ -->
	<header class="head">
		<div class="shell">
			<p class="eyebrow">{t('pricing.title')}</p>
			<h1 class="head-h1">{t('pricing.heading')}</h1>
			<p class="head-lede">{t('pricing.subheading')}</p>

			{#if beta}
				<p class="beta">
					<strong>{t('pricing.beta_banner_title')}</strong>
					{t('pricing.beta_banner_desc')}
				</p>
			{/if}
		</div>
	</header>

	<div class="shell">
		<!-- ═══ A · The price list ═══ -->
		<section class="sec">
			<!-- The masthead already states the promise; the price list only
			     needs its section mark, not a restated headline. The eyebrow
			     names what follows rather than repeating the page title. -->
			<div class="sec-head">
				<span class="rehearsal">A</span>
				<div class="sec-col">
					<p class="eyebrow blue">{t('pricing.plans_eyebrow')}</p>
				</div>
			</div>

			<div class="tiers">
				{#each plans as plan}
					<article class="tier" class:featured={plan.highlighted} class:muted={beta && plan.id !== 'free'}>
						<header class="tier-head">
							<span class="no">{plan.num}</span>
							<h3 class="tier-name">{t(plan.key)}</h3>
							{#if plan.highlighted && !beta}
								<span class="tag">{t('pricing.popular')}</span>
							{:else if beta && plan.id !== 'free'}
								<span class="tag live">{t('pricing.beta_free')}</span>
							{/if}
						</header>

						<p class="amount">
							{#if beta && plan.id !== 'free'}
								<span class="was">{plan.price} €</span>
								<span class="now">0 €</span>
							{:else}
								<span class="now">{plan.price} €</span>
							{/if}
							{#if plan.period}<span class="per">/ {t(plan.period)}</span>{/if}
						</p>

						<ul class="feats">
							{#each plan.features as feat}
								<li><Check size={14} aria-hidden="true" />{t(feat)}</li>
							{/each}
						</ul>

						{#if beta && plan.id !== 'free'}
							<button disabled class="btn btn-ghost btn-block">{t('pricing.coming_soon')}</button>
						{:else if plan.id === 'pro'}
							<button
								onclick={() => startCheckout(data.priceIdPro, 'pro')}
								disabled={checkoutLoading === 'pro'}
								class="btn btn-stamp btn-block"
							>
								{checkoutLoading === 'pro' ? '…' : t('pricing.cta_pro_trial')}
							</button>
							<p class="plate trial-note">{t('pricing.pro_trial_note')}</p>
						{:else}
							<a href={plan.href} class="btn btn-block {plan.highlighted ? 'btn-stamp' : 'btn-ghost'}">
								{t(plan.cta)}
							</a>
						{/if}
					</article>
				{/each}
			</div>
		</section>

		<!-- ═══ B · Risk reversal, as a ledger ═══ -->
		<section class="sec">
			<div class="sec-head">
				<span class="rehearsal">B</span>
				<div class="sec-col">
					<h2 class="sec-h2 no-eyebrow">{t('pricing.offer_title')}</h2>
					<p class="sec-lede">{t('pricing.offer_subtitle')}</p>
				</div>
			</div>

			<div class="ledger">
				{#each offerItems as item}
					<div class="cell">
						<Icon name={item.icon} size={20} />
						<h3 class="cell-t">{t(item.titleKey)}</h3>
						<p class="cell-d">{t(item.descKey)}</p>
					</div>
				{/each}
			</div>
		</section>

		<!-- ═══ C · FAQ ═══ -->
		<section class="sec">
			<div class="sec-head">
				<span class="rehearsal">C</span>
				<div class="sec-col">
					<p class="eyebrow blue">{t('pricing.faq_heading')}</p>
				</div>
			</div>

			<div class="faq">
				{#each faqKeys as faq}
					<details>
						<summary>{t(`pricing.faq_${faq}_q`)}</summary>
						<p class="ans">{t(`pricing.faq_${faq}_a`)}</p>
					</details>
				{/each}
			</div>
		</section>

		<!-- ═══ Fine · Feedback ═══ -->
		<section class="fine">
			<p class="eyebrow mid">{t('pricing.feedback_title')}</p>
			<p class="fine-p">{t('pricing.feedback_desc')}</p>
			<a href="mailto:info@jazzchords.app?subject=Feedback" class="btn btn-ghost">
				{t('pricing.feedback_cta')}
			</a>
		</section>
	</div>
</main>

<style>
	/* A printed price list: tiers are numbered entries sharing hairlines,
	   not four floating rounded cards. Stamp red marks the one recommended
	   entry; amber is reserved for live/beta state. */

	.edi {
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		font-variant-numeric: oldstyle-nums;
	}

	.shell {
		max-width: 1120px;
		margin: 0 auto;
		padding: 0 1.25rem;
	}
	@media (min-width: 900px) {
		.shell { padding: 0 2.5rem; }
	}

	/* ── Primitives ───────────────────────────────────────────── */

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
	.eyebrow.blue { color: var(--ink-blue); }
	.eyebrow.mid { justify-content: center; }
	.eyebrow.mid::after { display: none; }

	.rehearsal {
		display: inline-grid;
		place-items: center;
		flex: none;
		min-width: 1.7rem;
		height: 1.7rem;
		padding: 0 0.4rem;
		border: 1.5px solid var(--text);
		font-family: var(--font-mono);
		font-size: 0.78rem;
		font-weight: 700;
		color: var(--text);
	}

	.plate {
		margin: 0;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	/* ── Buttons ──────────────────────────────────────────────── */

	.btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		min-height: var(--tap-min);
		padding: 0 1.25rem;
		border-radius: var(--radius-sm);
		border: 1.5px solid var(--text);
		background: var(--text);
		color: var(--bg);
		font-family: var(--font-sans);
		font-size: 0.92rem;
		font-weight: 600;
		text-align: center;
		text-decoration: none;
		cursor: pointer;
		transition: transform 0.12s ease-out, background-color 0.12s, border-color 0.12s;
	}
	.btn:hover:not(:disabled) { transform: translateY(-1px); }
	.btn:disabled { cursor: not-allowed; opacity: 0.55; }
	.btn-block { width: 100%; }

	.btn-stamp {
		background: var(--primary);
		border-color: var(--primary);
		color: var(--primary-text);
	}
	.btn-stamp:hover:not(:disabled) {
		background: var(--primary-hover);
		border-color: var(--primary-hover);
	}
	.btn-ghost {
		background: transparent;
		border-color: var(--border);
		color: var(--text);
	}
	.btn-ghost:hover:not(:disabled) {
		border-color: var(--text);
		background: var(--bg-card);
	}

	/* ── Masthead ─────────────────────────────────────────────── */

	.head {
		padding: 3rem 0 2.25rem;
		border-bottom: 1px solid var(--rule-soft);
	}
	@media (min-width: 900px) {
		.head { padding: 4.5rem 0 3rem; }
	}
	.head-h1 {
		margin: 1.1rem 0 0;
		font-family: var(--font-display);
		font-size: clamp(1.95rem, 4.4vw, 3rem);
		font-weight: 600;
		line-height: 1.1;
		letter-spacing: -0.025em;
		max-width: 16em;
		text-wrap: balance;
		color: var(--text);
	}
	.head-lede {
		margin: 1rem 0 0;
		max-width: 60ch;
		font-size: 1.02rem;
		line-height: 1.65;
		color: var(--text-muted);
	}

	/* Beta notice — amber, because it is a live state. */
	.beta {
		margin: 1.6rem 0 0;
		padding: 0.85rem 1.1rem;
		border-left: 3px solid var(--accent-amber);
		background: color-mix(in srgb, var(--accent-amber) 10%, transparent);
		font-size: 0.92rem;
		line-height: 1.6;
		color: var(--text-muted);
	}
	.beta strong {
		display: block;
		color: var(--text);
	}

	/* ── Sections ─────────────────────────────────────────────── */

	.sec {
		padding: 2.75rem 0;
		border-top: 1px solid var(--rule-soft);
	}
	.sec:first-child { border-top: none; }
	@media (min-width: 900px) {
		.sec { padding: 4rem 0; }
	}

	.sec-head {
		display: flex;
		align-items: flex-start;
		gap: 1rem;
		margin-bottom: 1.75rem;
	}
	.sec-col { flex: 1; min-width: 0; }
	.sec-h2 {
		margin: 0.7rem 0 0;
		font-family: var(--font-display);
		font-size: clamp(1.4rem, 3.4vw, 2rem);
		font-weight: 600;
		line-height: 1.15;
		letter-spacing: -0.018em;
		max-width: 24ch;
		text-wrap: balance;
		color: var(--text);
	}
	/* When the h2 leads the section (no eyebrow above it), it needs no top gap. */
	.sec-h2.no-eyebrow { margin-top: 0.15rem; }

	.sec-lede {
		margin: 0.85rem 0 0;
		max-width: 62ch;
		font-size: 0.98rem;
		line-height: 1.62;
		color: var(--text-muted);
	}

	/* ── The price list ───────────────────────────────────────── */

	.tiers {
		display: grid;
		gap: 0;
		border: 1px solid var(--border);
	}
	@media (min-width: 720px) {
		.tiers { grid-template-columns: repeat(2, minmax(0, 1fr)); }
	}
	@media (min-width: 1040px) {
		.tiers { grid-template-columns: repeat(4, minmax(0, 1fr)); }
	}

	.tier {
		display: flex;
		flex-direction: column;
		padding: 1.5rem 1.35rem 1.6rem;
		background: var(--bg-card);
		border-bottom: 1px solid var(--rule-soft);
	}
	.tier:last-child { border-bottom: none; }
	@media (min-width: 720px) {
		.tier { border-right: 1px solid var(--rule-soft); }
		.tier:nth-child(2n) { border-right: none; }
		.tier:nth-last-child(-n + 2) { border-bottom: none; }
	}
	@media (min-width: 1040px) {
		.tier { border-bottom: none; border-right: 1px solid var(--rule-soft); }
		.tier:nth-child(2n) { border-right: 1px solid var(--rule-soft); }
		.tier:last-child { border-right: none; }
	}
	/* The recommended entry carries the stamp on its edge. */
	.tier.featured {
		background: var(--bg-card-hover);
		box-shadow: inset 3px 0 0 var(--primary);
	}
	.tier.muted { opacity: 0.55; }

	.tier-head {
		display: flex;
		align-items: center;
		gap: 0.6rem;
		flex-wrap: wrap;
	}
	.no {
		font-family: var(--font-mono);
		font-size: 0.7rem;
		letter-spacing: 0.08em;
		color: var(--text-dim);
	}
	.tier-name {
		margin: 0;
		font-family: var(--font-display);
		font-size: 1.15rem;
		font-weight: 600;
		color: var(--text);
	}
	.tag {
		margin-left: auto;
		padding: 0.12rem 0.45rem;
		border: 1px solid var(--primary);
		border-radius: 999px;
		font-family: var(--font-mono);
		font-size: 0.55rem;
		font-weight: 600;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--primary);
		white-space: nowrap;
	}
	.tag.live {
		border-color: var(--accent-amber);
		color: var(--accent-amber);
	}

	.amount {
		display: flex;
		align-items: baseline;
		flex-wrap: wrap;
		gap: 0.4rem;
		margin: 1rem 0 0;
		font-family: var(--font-display);
		font-variant-numeric: lining-nums;
	}
	.amount .now {
		font-size: clamp(1.9rem, 4.4vw, 2.4rem);
		font-weight: 600;
		line-height: 1;
		color: var(--text);
	}
	.amount .was {
		font-size: 1.15rem;
		color: var(--text-dim);
		text-decoration: line-through;
	}
	.amount .per {
		font-family: var(--font-sans);
		font-size: 0.78rem;
		font-weight: 500;
		color: var(--text-dim);
	}

	.feats {
		flex: 1;
		list-style: none;
		display: grid;
		gap: 0.55rem;
		margin: 1.15rem 0 1.35rem;
		padding: 1.05rem 0 0;
		border-top: 1px solid var(--rule-soft);
	}
	.feats li {
		display: flex;
		gap: 0.55rem;
		align-items: flex-start;
		font-size: 0.87rem;
		line-height: 1.5;
		color: var(--text-muted);
	}
	.feats :global(svg) {
		flex: none;
		margin-top: 0.2rem;
		color: var(--accent-green);
	}

	.trial-note {
		margin-top: 0.6rem;
		text-align: center;
		line-height: 1.6;
	}

	/* ── Risk-reversal ledger ─────────────────────────────────── */

	.ledger {
		display: grid;
		gap: 1px;
		border: 1px solid var(--border);
		background: var(--border);
	}
	@media (min-width: 640px) {
		.ledger { grid-template-columns: repeat(2, minmax(0, 1fr)); }
	}
	@media (min-width: 1040px) {
		.ledger { grid-template-columns: repeat(4, minmax(0, 1fr)); }
	}
	.cell {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		padding: 1.25rem 1.1rem;
		background: var(--bg-card);
	}
	.cell :global(svg) { color: var(--ink-blue); }
	.cell-t {
		margin: 0;
		font-family: var(--font-display);
		font-size: 1rem;
		font-weight: 600;
		color: var(--text);
	}
	.cell-d {
		margin: 0;
		font-size: 0.85rem;
		line-height: 1.55;
		color: var(--text-muted);
	}

	/* ── FAQ ──────────────────────────────────────────────────── */

	.faq {
		max-width: 68ch;
		border-top: 1px solid var(--border);
	}
	.faq details { border-bottom: 1px solid var(--rule-soft); }
	.faq summary {
		display: flex;
		align-items: center;
		position: relative;
		min-height: var(--tap-min);
		padding: 0.9rem 1.75rem 0.9rem 0;
		cursor: pointer;
		list-style: none;
		font-family: var(--font-display);
		font-size: 1rem;
		font-weight: 600;
		color: var(--text);
	}
	.faq summary::-webkit-details-marker { display: none; }
	.faq summary::after {
		content: '+';
		position: absolute;
		right: 0.1rem;
		top: 50%;
		transform: translateY(-50%);
		font-family: var(--font-mono);
		font-size: 1.05rem;
		color: var(--primary);
	}
	.faq details[open] summary::after { content: '–'; }
	.faq .ans {
		margin: 0;
		padding: 0 0 1rem;
		max-width: 62ch;
		font-size: 0.93rem;
		line-height: 1.62;
		color: var(--text-muted);
	}

	/* ── Fine ─────────────────────────────────────────────────── */

	.fine {
		padding: 3rem 0 4rem;
		border-top: 2px solid var(--text);
		text-align: center;
	}
	.fine-p {
		margin: 1rem auto 1.5rem;
		max-width: 52ch;
		font-size: 0.98rem;
		line-height: 1.65;
		color: var(--text-muted);
	}

	@media (prefers-reduced-motion: reduce) {
		.btn { transition: none; }
		.btn:hover:not(:disabled) { transform: none; }
	}
</style>
