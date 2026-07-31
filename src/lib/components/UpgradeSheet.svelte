<script lang="ts">
	import { t } from '$lib/i18n';
	import { Sheet, Icon } from '$lib/components/ui';
	import { getAuthState } from '$lib/services/auth';
	import { toastError } from '$lib/services/toast';
	import { goto } from '$app/navigation';

	interface Props {
		open: boolean;
		/** Feature gate key — drives the headline + copy. */
		feature: string;
		/** True when shown right after a free taste (warmer copy). */
		teaserMode?: boolean;
		onclose?: () => void;
	}

	let { open = $bindable(), feature, teaserMode = false, onclose }: Props = $props();

	let loading = $state(false);

	// Headline + body per feature / mode.
	const copy = $derived.by(() => {
		if (teaserMode && feature === 'adaptive-difficulty')
			return { title: t('upgrade.teaser_adaptive_title'), desc: t('upgrade.teaser_adaptive_desc') };
		if (teaserMode && feature === 'advanced-stats')
			return { title: t('upgrade.teaser_stats_title'), desc: t('upgrade.teaser_stats_desc') };
		switch (feature) {
			case 'unlimited-coach-sessions':
				return { title: t('upgrade.lock_sessions_title'), desc: t('upgrade.lock_sessions_desc') };
			case 'togo-full':
				return { title: t('upgrade.lock_togo_title'), desc: t('upgrade.lock_togo_desc') };
			case 'full-history':
				return { title: t('upgrade.lock_history_title'), desc: t('upgrade.lock_history_desc') };
			case 'adaptive-difficulty':
				return { title: t('upgrade.lock_adaptive_title'), desc: t('upgrade.lock_adaptive_desc') };
			case 'custom-progressions':
				return { title: t('upgrade.lock_custom_title'), desc: t('upgrade.lock_custom_desc') };
			case 'advanced-stats':
				return { title: t('upgrade.lock_stats_title'), desc: t('upgrade.lock_stats_desc') };
			case 'cloud-sync':
				return { title: t('upgrade.lock_sync_title'), desc: t('upgrade.lock_sync_desc') };
			default:
				return { title: t('upgrade.lock_generic_title'), desc: t('upgrade.lock_generic_desc') };
		}
	});

	// Unlimited sessions leads: it is the one limit a free user meets daily,
	// and therefore the reason most of them are reading this sheet at all.
	const points = [
		{ icon: 'speed', key: 'upgrade.point_sessions' },
		{ icon: 'weak-spots', key: 'upgrade.point_adaptive' },
		{ icon: 'custom-progression', key: 'upgrade.point_custom' },
		{ icon: 'progress', key: 'upgrade.point_stats' },
		{ icon: 'midi', key: 'upgrade.point_sync' },
	];

	async function startTrial() {
		const { user } = getAuthState();
		if (!user) {
			open = false;
			goto('/auth/login?redirect=/train');
			return;
		}
		loading = true;
		try {
			const res = await fetch('/api/stripe/checkout', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ plan: 'pro' }),
			});
			const data = await res.json();
			if (!res.ok || !data.url) {
				toastError(data.error || 'Checkout failed');
				return;
			}
			window.location.href = data.url;
		} catch {
			toastError('Network error');
		} finally {
			loading = false;
		}
	}

	const loggedIn = $derived(!!getAuthState().user);
</script>

<Sheet bind:open title={copy.title} {onclose}>
	<div class="space-y-5">
		<div class="flex items-center gap-2">
			<span class="grid h-9 w-9 place-items-center rounded-xl bg-[var(--accent-gold)]/15">
				<svg class="h-4 w-4 text-[var(--accent-gold)]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
					<rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11V7a4 4 0 0 1 8 0v4" />
				</svg>
			</span>
			<span class="text-xs font-semibold uppercase tracking-wide text-[var(--accent-gold)]">{t('upgrade.eyebrow')}</span>
		</div>

		<p class="text-[var(--text-muted)] leading-relaxed">{copy.desc}</p>

		<div class="rounded-2xl border border-[var(--border)]/50 bg-[var(--bg-card)]/40 p-4">
			<div class="mb-3 text-xs font-semibold uppercase tracking-wide text-[var(--text-dim)]">{t('upgrade.points_title')}</div>
			<ul class="space-y-2.5">
				{#each points as p}
					<li class="flex items-start gap-2.5 text-sm text-[var(--text-muted)]">
						<span class="mt-0.5 shrink-0"><Icon name={p.icon} size={18} /></span>
						<span>{t(p.key)}</span>
					</li>
				{/each}
			</ul>
		</div>
	</div>

	{#snippet footer()}
		<div class="space-y-2">
			<button
				onclick={startTrial}
				disabled={loading}
				class="pill-btn pill-btn-primary w-full py-3 text-base disabled:opacity-60 disabled:cursor-wait"
			>
				{loading ? '…' : loggedIn ? t('upgrade.cta_trial') : t('upgrade.cta_login')}
			</button>
			<p class="text-center text-xs text-[var(--text-dim)]">{t('upgrade.trial_note')}</p>
			<button
				onclick={() => { open = false; onclose?.(); }}
				class="w-full py-1.5 text-sm text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors"
			>
				{t('upgrade.later')}
			</button>
		</div>
	{/snippet}
</Sheet>
