<script lang="ts">
	import { t } from '$lib/i18n';
	import { getLevelInfo, type LevelInfo } from '$lib/engine/habits';

	interface Props {
		totalXP: number;
		compact?: boolean;
	}

	let { totalXP, compact = false }: Props = $props();

	const info: LevelInfo = $derived(getLevelInfo(totalXP));
</script>

{#if compact}
	<div class="level-badge-compact">
		<span class="level-num">Lv.{info.level}</span>
		<div class="xp-bar-mini">
			<div class="xp-fill-mini" style="width: {info.progressPercent}%"></div>
		</div>
	</div>
{:else}
	<div class="level-badge">
		<div class="level-circle">
			<span class="level-number">{info.level}</span>
		</div>
		<div class="level-info">
			<span class="level-title">{t(info.titleKey)}</span>
			<div class="xp-bar">
				<div class="xp-fill" style="width: {info.progressPercent}%"></div>
			</div>
			<span class="xp-text">{info.currentXP.toLocaleString()} XP</span>
		</div>
	</div>
{/if}

<style>
	.level-badge-compact {
		display: flex;
		align-items: center;
		gap: 6px;
	}

	.level-num {
		font-size: 0.75rem;
		font-weight: 700;
		color: #fb923c;
		font-variant-numeric: tabular-nums;
	}

	.xp-bar-mini {
		width: 40px;
		height: 3px;
		background: rgba(251, 146, 60, 0.15);
		border-radius: 999px;
		overflow: hidden;
	}

	.xp-fill-mini {
		height: 100%;
		background: #fb923c;
		border-radius: 999px;
		transition: width 0.6s ease-out;
	}

	.level-badge {
		display: flex;
		align-items: center;
		gap: 12px;
	}

	.level-circle {
		width: 44px;
		height: 44px;
		border-radius: 50%;
		background: linear-gradient(135deg, #fb923c 0%, #f59e0b 100%);
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
		box-shadow: 0 0 16px rgba(251, 146, 60, 0.3);
	}

	.level-number {
		font-size: 1rem;
		font-weight: 800;
		color: #000;
		line-height: 1;
	}

	.level-info {
		display: flex;
		flex-direction: column;
		gap: 4px;
		min-width: 0;
	}

	.level-title {
		font-size: 0.8rem;
		font-weight: 600;
		color: var(--text);
	}

	.xp-bar {
		width: 100%;
		height: 4px;
		background: rgba(251, 146, 60, 0.15);
		border-radius: 999px;
		overflow: hidden;
	}

	.xp-fill {
		height: 100%;
		background: linear-gradient(90deg, #fb923c 0%, #f59e0b 100%);
		border-radius: 999px;
		transition: width 0.8s ease-out;
	}

	.xp-text {
		font-size: 0.65rem;
		color: var(--text-muted);
		font-variant-numeric: tabular-nums;
	}
</style>
