<script lang="ts">
	import { t } from '$lib/i18n';
	import type { SmartGoal } from '$lib/engine/habits';
	import { Icon } from '$lib/components/ui';
	import { goalIconName } from '$lib/utils/goal-icon';
	import { Check } from 'lucide-svelte';

	interface Props {
		goal: SmartGoal;
	}

	let { goal }: Props = $props();

	const progressPct = $derived.by(() => {
		if (goal.type === 'speed' || goal.type === 'mastery') {
			// For time-based: progress is inverse (lower = better)
			if (goal.current <= 0) return 0;
			if (goal.current <= goal.target) return 100;
			const descParams = goal.descriptionParams;
			const originalCurrent = descParams?.current as number || goal.current;
			if (originalCurrent <= goal.target) return 100;
			const range = originalCurrent - goal.target;
			const progress = originalCurrent - goal.current;
			return Math.max(0, Math.min(100, Math.round((progress / range) * 100)));
		}
		return Math.min(100, Math.round((goal.current / goal.target) * 100));
	});

	const isCompleted = $derived(!!goal.completedAt);

	// Per-goal-type ink, on the system's semantic tokens rather than a private
	// palette. `review` and `accuracy` both read as the annotating blue — the
	// two are told apart by their printed mark (adaptive vs accuracy) and their
	// title, not by inventing a seventh hue outside the system.
	const GOAL_COLORS: Record<string, string> = {
		speed: 'var(--accent-amber)',
		consistency: 'var(--accent-green)',
		mastery: 'var(--accent-gold)',
		exploration: 'var(--ink-blue)',
		endurance: 'var(--primary)',
		review: 'var(--info)',
		accuracy: 'var(--info)',
	};

	const color = $derived(GOAL_COLORS[goal.type] || 'var(--accent-amber)');
</script>

<!-- A goal is a ruled entry, not a card: a 2px ink rule on the left carries the
     goal's type colour, the mark sits in the margin, the tally is set in mono
     at the right. No radius, no fill beyond the plate. -->
<div
	class="goal-card {isCompleted ? 'done' : ''}"
	style="--goal-color: {color}"
>
	<div class="goal-head">
		<span class="goal-icon" aria-hidden="true"><Icon name={goalIconName(goal.type)} size={18} /></span>
		<div class="goal-txt">
			<span class="goal-title">{t(goal.titleKey, goal.titleParams) || goal.title}</span>
			{#if goal.descriptionKey}
				<span class="goal-desc">{t(goal.descriptionKey, goal.descriptionParams)}</span>
			{/if}
		</div>
		{#if isCompleted}
			<span class="goal-check" aria-hidden="true"><Check size={16} /></span>
		{/if}
	</div>

	<div class="goal-foot">
		<div class="goal-bar">
			<div class="goal-fill" style="width: {progressPct}%"></div>
		</div>
		{#if progressPct === 0 && !isCompleted}
			<span class="goal-new">{t('habit.goal_new')}</span>
		{:else}
			<span class="goal-pct">{progressPct}%</span>
		{/if}
		{#if goal.xpReward}
			<span class="goal-xp">{t('habit.xp_amount', { amount: goal.xpReward })}</span>
		{/if}
	</div>
</div>

<style>
	/* ── A goal as a ruled entry ──────────────────────────────── */

	.goal-card {
		padding: 0.5rem 0.75rem;
		border: 1px solid var(--border);
		border-left: 2px solid var(--goal-color);
		background: var(--bg-muted);
		transition: background-color 0.16s, border-color 0.16s;
	}
	.goal-card:hover {
		background: var(--bg-card-hover);
		border-color: var(--goal-color);
	}
	.goal-card.done {
		opacity: 0.62;
		border-left-color: var(--accent-green);
	}
	@media (max-width: 640px) {
		.goal-card { padding: 0.625rem 0.75rem; }
	}

	.goal-head {
		display: flex;
		align-items: flex-start;
		gap: 0.5rem;
		margin-bottom: 0.375rem;
	}

	.goal-icon {
		flex: none;
		margin-top: 1px;
		color: var(--goal-color);
	}

	.goal-txt {
		display: flex;
		flex: 1;
		min-width: 0;
		flex-direction: column;
		gap: 1px;
	}

	/* Read, not scanned — the display serif, as everywhere else. */
	.goal-title {
		min-width: 0;
		font-family: 'AccidentalFit', var(--font-display);
		font-size: 0.875rem;
		font-weight: 600;
		line-height: 1.3;
		color: var(--text);
	}

	.goal-desc {
		overflow: hidden;
		white-space: nowrap;
		text-overflow: ellipsis;
		font-size: 0.66rem;
		line-height: 1.35;
		color: var(--text-dim);
	}
	@media (max-width: 640px) {
		.goal-title { font-size: 0.95rem; }
		.goal-desc {
			display: -webkit-box;
			-webkit-line-clamp: 2;
			line-clamp: 2;
			-webkit-box-orient: vertical;
			white-space: normal;
			font-size: 0.72rem;
		}
	}

	.goal-check {
		display: inline-flex;
		flex: none;
		color: var(--accent-green);
	}

	.goal-foot {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	/* A measured rail, squared off — a printed bar, not a pill. */
	.goal-bar {
		flex: 1;
		height: 3px;
		overflow: hidden;
		background: color-mix(in srgb, var(--border) 70%, transparent);
	}
	.goal-fill {
		height: 100%;
		background: var(--goal-color);
		transition: width 0.8s ease-out;
	}

	/* Every figure and label in the footer is mono — this is the tally line. */
	.goal-new,
	.goal-pct,
	.goal-xp {
		flex: none;
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.1em;
		text-transform: uppercase;
	}
	.goal-new {
		min-width: 28px;
		text-align: right;
		color: var(--text-muted);
	}
	.goal-pct {
		min-width: 28px;
		text-align: right;
		font-weight: 600;
		font-variant-numeric: tabular-nums;
		color: var(--goal-color);
	}
	.goal-xp {
		font-variant-numeric: tabular-nums;
		color: var(--text-dim);
	}
	@media (max-width: 640px) {
		.goal-new,
		.goal-pct,
		.goal-xp { font-size: 0.65rem; }
	}

	/* ── iPad / large touch ─────────────────────── */
	@media (hover: none) and (pointer: coarse) and (min-width: 768px) {
		.goal-card {
			padding: 14px 16px;
		}

		.goal-title {
			font-size: 1rem;
			font-weight: 600;
		}

		.goal-desc {
			font-size: 0.8rem;
			white-space: normal;
			overflow: hidden;
			display: -webkit-box;
			-webkit-line-clamp: 2;
			line-clamp: 2;
			-webkit-box-orient: vertical;
		}

		.goal-bar {
			height: 5px;
		}

		.goal-pct,
		.goal-new,
		.goal-xp {
			font-size: 0.78rem;
		}
	}

	@media (prefers-reduced-motion: reduce) {
		.goal-card,
		.goal-fill { transition: none; }
	}
</style>
