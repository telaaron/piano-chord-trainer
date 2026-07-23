<script lang="ts">
	import { t } from '$lib/i18n';
	import { PRACTICE_PLANS, type PracticePlan } from '$lib/engine';
	import { Card, Icon } from '$lib/components/ui';

	import { Play } from 'lucide-svelte';

	interface Props {
		/** Plan id to resume, if the user has a recent session. null = no resume card. */
		resumePlanId?: string | null;
		/** Whether adaptive history exists (enables the "weak spots" card). */
		hasHistory?: boolean;
		onstart: (plan: PracticePlan) => void;
		onstartdefault: () => void;
		oncustomize: () => void;
		/** Launch a focused drill on the player's weakest chords (weak-spots card). */
		onweakdrill?: () => void;
		/** Start today's Auto-Mode ("Coach") session — the dominant hero action. */
		onstartcoach?: () => void;
		/** One-line, already-localized coach announcement shown under the hero button. */
		coachAnnouncement?: string;
	}

	let { resumePlanId = null, hasHistory = false, onstart, onstartdefault, oncustomize, onweakdrill, onstartcoach, coachAnnouncement }: Props = $props();

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
					// Focused drill on the actual weak roots (falls back to plain adaptive).
					run: () => (onweakdrill ? onweakdrill() : onstart(adaptive)),
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

<section aria-label={t('quickstart.section_label')} class="flex flex-col gap-4">
	{#if onstartcoach}
		<!-- Coach hero — the single dominant "just start" action. -->
		<div class="flex flex-col gap-2">
			<button
				type="button"
				onclick={onstartcoach}
				class="group flex w-full items-center gap-4 rounded-2xl bg-[var(--primary)] px-5 py-4 text-left text-white shadow-lg transition-all hover:opacity-95 hover:shadow-xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--bg)]"
			>
				<span class="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-white/20" aria-hidden="true">
					<Play size={26} fill="currentColor" />
				</span>
				<span class="min-w-0 flex-1">
					<span class="block text-lg font-bold">{t('quickstart.coach_hero_title')}</span>
					{#if coachAnnouncement}
						<span class="mt-0.5 block truncate text-sm text-white/85">{coachAnnouncement}</span>
					{:else}
						<span class="mt-0.5 block truncate text-sm text-white/85">{t('quickstart.coach_hero_sub')}</span>
					{/if}
				</span>
			</button>
		</div>

		<!-- "Pick it yourself" — the manual cards live below the coach. -->
		<div class="flex items-center gap-3">
			<span class="h-px flex-1 bg-[var(--border)]"></span>
			<span class="text-xs font-medium uppercase tracking-[0.06em] text-(--text-muted)">{t('quickstart.pick_yourself')}</span>
			<span class="h-px flex-1 bg-[var(--border)]"></span>
		</div>
	{/if}

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
