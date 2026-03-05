<script lang="ts">
	import { t } from '$lib/i18n';
	import type { SmartGoal } from '$lib/engine/habits';

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

	const GOAL_COLORS: Record<string, string> = {
		speed: '#fb923c',
		consistency: '#4ade80',
		mastery: '#f59e0b',
		exploration: '#a78bfa',
		endurance: '#f472b6',
		review: '#38bdf8',
		accuracy: '#06b6d4',
	};

	const color = $derived(GOAL_COLORS[goal.type] || '#fb923c');
</script>

<div
	class="goal-card bg-white/[0.03] border border-[color:var(--border,#222)] border-l-[3px]
		rounded-[var(--radius,8px)] py-2 px-3 transition-all duration-200 ease-in-out
		hover:bg-white/[0.05] hover:border-[color:var(--goal-color)] hover:border-l-[color:var(--goal-color)]
		max-sm:py-2.5
		{isCompleted ? 'opacity-60 border-l-[color:var(--accent-green,#4ade80)]' : 'border-l-[color:var(--goal-color)]'}"
	style="--goal-color: {color}"
>
	<div class="flex items-start gap-2 mb-1.5">
		<span class="goal-icon text-[0.85rem] shrink-0 mt-px max-sm:text-base">{goal.icon}</span>
		<div class="flex flex-col gap-px flex-1 min-w-0">
			<span class="goal-title text-xs font-semibold text-[var(--text,#fff)] min-w-0 max-sm:text-[0.85rem]">{t(goal.titleKey, goal.titleParams) || goal.title}</span>
			{#if goal.descriptionKey}
				<span class="goal-desc text-[0.6rem] text-white/[0.32] whitespace-nowrap overflow-hidden text-ellipsis max-sm:text-[0.68rem] max-sm:whitespace-normal max-sm:line-clamp-2">{t(goal.descriptionKey, goal.descriptionParams)}</span>
			{/if}
		</div>
		{#if isCompleted}
			<span class="text-[var(--accent-green,#4ade80)] font-bold text-[0.85rem] max-sm:text-[0.95rem]">✓</span>
		{/if}
	</div>

	<div class="flex items-center gap-2">
		<div class="goal-bar flex-1 h-1 bg-white/[0.06] rounded-full overflow-hidden max-sm:h-[5px]">
			<div class="h-full bg-[var(--goal-color)] rounded-full transition-[width] duration-[0.8s] ease-out" style="width: {progressPct}%"></div>
		</div>
		{#if progressPct === 0 && !isCompleted}
			<span class="goal-new text-[0.6rem] text-[var(--text-muted,#888)] font-medium uppercase tracking-[0.03em] min-w-[28px] text-right shrink-0 max-sm:text-[0.62rem]">New</span>
		{:else}
			<span class="goal-pct text-[0.6rem] text-[var(--goal-color)] font-semibold tabular-nums min-w-[28px] text-right shrink-0 max-sm:text-[0.65rem]">{progressPct}%</span>
		{/if}
		<span class="goal-xp text-[0.6rem] text-[var(--text-dim,#666)] font-medium shrink-0 max-sm:text-[0.65rem]">+{goal.xpReward} XP</span>
	</div>
</div>

<style>
	/* ── iPad / large touch ─────────────────────── */
	@media (hover: none) and (pointer: coarse) and (min-width: 768px) {
		.goal-card {
			padding: 14px 16px;
		}

		.goal-icon {
			font-size: 1.1rem;
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
			-webkit-box-orient: vertical;
		}

		.goal-bar {
			height: 6px;
		}

		.goal-pct {
			font-size: 0.8rem;
		}

		.goal-new {
			font-size: 0.78rem;
		}

		.goal-xp {
			font-size: 0.8rem;
		}
	}
</style>
