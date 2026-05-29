<script lang="ts">
	import { t } from '$lib/i18n';
	import { PRACTICE_PLANS, type PracticePlan } from '$lib/engine';
	import { Card } from '$lib/components/ui';

	interface Props {
		/** Plan id to resume, if the user has a recent session. null = no resume card. */
		resumePlanId?: string | null;
		/** Whether adaptive history exists (enables the "weak spots" card). */
		hasHistory?: boolean;
		onstart: (plan: PracticePlan) => void;
		onstartdefault: () => void;
		oncustomize: () => void;
	}

	let { resumePlanId = null, hasHistory = false, onstart, onstartdefault, oncustomize }: Props = $props();

	const byId = (id: string) => PRACTICE_PLANS.find((p) => p.id === id);

	// The four primary entry points — curated, not the full 14-plan list.
	// Order: resume (if any) → daily warmup → weak-spots (if history) → ii-V-I.
	interface QuickCard {
		key: string;
		icon: string;
		titleKey: string;
		descKey: string;
		accent: string;
		run: () => void;
	}

	const cards = $derived.by<QuickCard[]>(() => {
		const out: QuickCard[] = [];

		if (resumePlanId) {
			const p = byId(resumePlanId);
			if (p) {
				out.push({
					key: 'resume',
					icon: '↻',
					titleKey: 'quickstart.resume_title',
					descKey: p.tagline,
					accent: 'var(--primary)',
					run: () => onstart(p),
				});
			}
		}

		const warmup = byId('warmup');
		if (warmup) {
			out.push({
				key: 'warmup',
				icon: '☀️',
				titleKey: 'quickstart.warmup_title',
				descKey: 'quickstart.warmup_desc',
				accent: 'var(--xp)',
				run: () => onstart(warmup),
			});
		}

		if (hasHistory) {
			const adaptive = byId('adaptive-drill');
			if (adaptive) {
				out.push({
					key: 'weak',
					icon: '🎯',
					titleKey: 'quickstart.weakspots_title',
					descKey: 'quickstart.weakspots_desc',
					accent: 'var(--success)',
					run: () => onstart(adaptive),
				});
			}
		}

		const turnaround = byId('warmup'); // warmup uses 2-5-1
		const twofive = PRACTICE_PLANS.find((p) => p.settings.progressionMode === '2-5-1') ?? turnaround;
		if (twofive) {
			out.push({
				key: 'ii-v-i',
				icon: '🎹',
				titleKey: 'quickstart.iivi_title',
				descKey: 'quickstart.iivi_desc',
				accent: 'var(--info)',
				run: () => onstart(twofive),
			});
		}

		return out;
	});
</script>

<section aria-label={t('quickstart.section_label')} class="flex flex-col gap-3">
	<div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
		{#each cards as card (card.key)}
			<Card interactive onclick={card.run} ariaLabel={t(card.titleKey)} padding="md">
				<div class="flex items-start gap-3">
					<span
						class="grid h-11 w-11 shrink-0 place-items-center rounded-[var(--radius)] text-2xl"
						style="background: color-mix(in srgb, {card.accent} 16%, transparent);"
						aria-hidden="true">{card.icon}</span>
					<div class="min-w-0">
						<div class="text-[var(--text-base)] font-semibold text-[var(--text)]">{t(card.titleKey)}</div>
						<div class="text-[var(--text-sm)] text-[var(--text-dim)] mt-0.5">{t(card.descKey)}</div>
					</div>
				</div>
			</Card>
		{/each}
	</div>

	<div class="flex items-center gap-3 text-[var(--text-sm)]">
		<button
			type="button"
			onclick={onstartdefault}
			class="font-medium text-[var(--primary)] hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] rounded px-1"
		>
			{t('quickstart.start_custom')}
		</button>
		<span class="text-[var(--text-dim)]">·</span>
		<button
			type="button"
			onclick={oncustomize}
			class="font-medium text-[var(--text-muted)] hover:text-[var(--text)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] rounded px-1"
		>
			{t('quickstart.customize')}
		</button>
	</div>
</section>
