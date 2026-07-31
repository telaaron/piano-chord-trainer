<script lang="ts">
	// "Your progress lives only in this browser."
	//
	// Deliberately NOT an upgrade sheet. No lock icon, no price, no plan — an
	// account is free and this is the one moment it is genuinely in the user's
	// interest: anonymous progress sits in localStorage alone (cloud-sync
	// refuses without a session), so clearing the browser or picking up the
	// iPad loses everything. Selling "full history" as a paid feature while the
	// free tier quietly forgets is the opposite of what we want.
	//
	// It also opens the only channel that can bring someone back on day two.
	// Shown once, after a real session — never after calibration, and never
	// twice, because a second ask reads as a wall.
	import { t } from '$lib/i18n';
	import { Sheet, Icon } from '$lib/components/ui';
	import { goto } from '$app/navigation';

	interface Props {
		open: boolean;
		onclose?: () => void;
	}

	let { open = $bindable(), onclose }: Props = $props();

	const points = [
		{ icon: 'midi', key: 'sync_offer.point_devices' },
		{ icon: 'progress', key: 'sync_offer.point_history' },
		{ icon: 'streak', key: 'sync_offer.point_streak' },
	];

	function createAccount() {
		open = false;
		onclose?.();
		goto('/auth/login?redirect=/train');
	}

	function dismiss() {
		open = false;
		onclose?.();
	}
</script>

<Sheet bind:open title={t('sync_offer.title')} onclose={dismiss}>
	<div class="space-y-5">
		<p class="text-[var(--text-muted)] leading-relaxed">{t('sync_offer.desc')}</p>

		<div class="rounded-2xl border border-[var(--border)]/50 bg-[var(--bg-card)]/40 p-4">
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
			<button onclick={createAccount} class="pill-btn pill-btn-primary w-full py-3 text-base">
				{t('sync_offer.cta')}
			</button>
			<!-- Free, and it says so: the number one reason people refuse an
			     account is assuming it is the start of a payment flow. -->
			<p class="text-center text-xs text-[var(--text-dim)]">{t('sync_offer.note')}</p>
			<button
				onclick={dismiss}
				class="w-full py-1.5 text-sm text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors"
			>
				{t('sync_offer.later')}
			</button>
		</div>
	{/snippet}
</Sheet>
