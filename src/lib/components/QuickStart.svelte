<script lang="ts">
	import { t } from '$lib/i18n';
	import { PRACTICE_PLANS, type PracticePlan } from '$lib/engine';
	import { Card, Icon } from '$lib/components/ui';

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

	// Warmup is intentionally NOT a card here — the hero owns the daily warmup CTA.
	// These cards complement it: resume → weak-spots → ii-V-I → (backfill).
	const cards = $derived.by<QuickCard[]>(() => {
		const out: QuickCard[] = [];

		if (resumePlanId && resumePlanId !== 'warmup') {
			const p = byId(resumePlanId);
			if (p) {
				out.push({
					key: 'resume',
					icon: 'resume',
					titleKey: 'quickstart.resume_title',
					descKey: p.tagline,
					accent: 'var(--primary)',
					run: () => onstart(p),
				});
			}
		}

		if (hasHistory) {
			const adaptive = byId('adaptive-drill');
			if (adaptive) {
				out.push({
					key: 'weak',
					icon: 'weak-spots',
					titleKey: 'quickstart.weakspots_title',
					descKey: 'quickstart.weakspots_desc',
					accent: 'var(--success)',
					run: () => onstart(adaptive),
				});
			}
		}

		// ii-V-I — the core jazz cadence (warmup's 2-5-1 beginner settings)
		const twofive = byId('warmup') ?? PRACTICE_PLANS.find((p) => p.settings.progressionMode === '2-5-1');
		if (twofive) {
			out.push({
				key: 'ii-v-i',
				icon: 'ii-v-i',
				titleKey: 'quickstart.iivi_title',
				descKey: 'quickstart.iivi_desc',
				accent: 'var(--info)',
				run: () => onstart(twofive),
			});
		}

		// Backfill to keep a balanced 3-up grid (cycle of 4ths, then speed).
		const backfill: Array<{ id: string; icon: string; descKey: string; accent: string }> = [
			{ id: 'quartenzirkel', icon: 'cycle', descKey: 'quickstart.cycle_desc', accent: 'var(--accent-gold)' },
			{ id: 'speed', icon: 'speed', descKey: 'quickstart.speed_desc', accent: 'var(--accent-red)' },
		];
		for (const b of backfill) {
			if (out.length >= 3) break;
			const p = byId(b.id);
			if (p && !out.some((c) => c.key === b.id)) {
				out.push({
					key: b.id,
					icon: b.icon,
					titleKey: p.name,
					descKey: b.descKey,
					accent: b.accent,
					run: () => onstart(p),
				});
			}
		}

		return out;
	});
</script>

<section aria-label={t('quickstart.section_label')} class="flex flex-col gap-3">
	<div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
		{#each cards as card (card.key)}
			<Card interactive onclick={card.run} ariaLabel={t(card.titleKey)} padding="md">
				<div class="flex items-start gap-3.5">
					<span
						class="grid h-12 w-12 shrink-0 place-items-center rounded-[var(--radius-lg)]"
						style="background: color-mix(in srgb, {card.accent} 16%, transparent);"
						aria-hidden="true"><Icon name={card.icon} size={30} /></span>
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
