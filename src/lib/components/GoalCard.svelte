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

<div class="goal-card" class:completed={isCompleted} style="--goal-color: {color}">
	<div class="goal-header">
		<span class="goal-icon">{goal.icon}</span>
		<div class="goal-title-block">
			<span class="goal-title">{t(goal.titleKey, goal.titleParams) || goal.title}</span>
			{#if goal.descriptionKey}
				<span class="goal-desc">{t(goal.descriptionKey, goal.descriptionParams)}</span>
			{/if}
		</div>
		{#if isCompleted}
			<span class="goal-done">✓</span>
		{/if}
	</div>

	<div class="goal-progress-row">
		<div class="goal-bar">
			<div class="goal-fill" style="width: {progressPct}%"></div>
		</div>
		{#if progressPct === 0 && !isCompleted}
			<span class="goal-new">New</span>
		{:else}
			<span class="goal-pct">{progressPct}%</span>
		{/if}
		<span class="goal-xp">+{goal.xpReward} XP</span>
	</div>
</div>

<style>
	.goal-card {
		background: rgba(255, 255, 255, 0.03);
		border: 1px solid var(--border, #222);
		border-left: 3px solid var(--goal-color);
		border-radius: var(--radius, 8px);
		padding: 8px 12px;
		transition: all 0.2s ease;
	}

	.goal-card:hover {
		background: rgba(255, 255, 255, 0.05);
		border-color: var(--goal-color);
	}

	.goal-card.completed {
		opacity: 0.6;
		border-left-color: var(--accent-green, #4ade80);
	}

	.goal-header {
		display: flex;
		align-items: flex-start;
		gap: 8px;
		margin-bottom: 6px;
	}

	.goal-icon {
		font-size: 0.85rem;
		flex-shrink: 0;
		margin-top: 1px;
	}

	.goal-title-block {
		display: flex;
		flex-direction: column;
		gap: 1px;
		flex: 1;
		min-width: 0;
	}

	.goal-title {
		font-size: 0.75rem;
		font-weight: 600;
		color: var(--text, #fff);
		min-width: 0;
	}

	.goal-desc {
		font-size: 0.6rem;
		color: rgba(255, 255, 255, 0.32);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.goal-done {
		color: var(--accent-green, #4ade80);
		font-weight: 700;
		font-size: 0.85rem;
	}

	.goal-progress-row {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.goal-bar {
		flex: 1;
		height: 4px;
		background: rgba(255, 255, 255, 0.06);
		border-radius: 999px;
		overflow: hidden;
	}

	.goal-fill {
		height: 100%;
		background: var(--goal-color);
		border-radius: 999px;
		transition: width 0.8s ease-out;
	}

	.goal-pct {
		font-size: 0.6rem;
		color: var(--goal-color);
		font-weight: 600;
		font-variant-numeric: tabular-nums;
		min-width: 28px;
		text-align: right;
		flex-shrink: 0;
	}

	.goal-new {
		font-size: 0.6rem;
		color: var(--text-muted, #888);
		font-weight: 500;
		text-transform: uppercase;
		letter-spacing: 0.03em;
		min-width: 28px;
		text-align: right;
		flex-shrink: 0;
	}

	.goal-xp {
		font-size: 0.6rem;
		color: var(--text-dim, #666);
		font-weight: 500;
		flex-shrink: 0;
	}

	/* ── Mobile ─────────────────────────────────── */
	@media (max-width: 640px) {
		.goal-card {
			padding: 10px 12px;
		}

		.goal-icon {
			font-size: 1rem;
		}

		.goal-title {
			font-size: 0.85rem;
		}

		/* Allow description to show 2 lines instead of clipping */
		.goal-desc {
			font-size: 0.68rem;
			white-space: normal;
			overflow: hidden;
			display: -webkit-box;
			-webkit-line-clamp: 2;
			-webkit-box-orient: vertical;
			text-overflow: unset;
		}

		.goal-done {
			font-size: 0.95rem;
		}

		.goal-bar {
			height: 5px;
		}

		.goal-pct {
			font-size: 0.65rem;
		}

		.goal-new {
			font-size: 0.62rem;
		}

		.goal-xp {
			font-size: 0.65rem;
		}
	}
</style>
