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
	<div class="flex items-center gap-[6px]">
		<span class="text-xs font-bold text-[#fb923c] tabular-nums">Lv.{info.level}</span>
		<div class="w-[40px] h-[3px] bg-[rgba(251,146,60,0.15)] rounded-full overflow-hidden">
			<div class="h-full bg-[#fb923c] rounded-full transition-[width] duration-[0.6s] ease-out" style="width: {info.progressPercent}%"></div>
		</div>
	</div>
{:else}
	<div class="flex items-center gap-3">
		<div class="w-[44px] h-[44px] rounded-full bg-gradient-to-br from-[#fb923c] to-[#f59e0b] flex items-center justify-center shrink-0 shadow-[0_0_16px_rgba(251,146,60,0.3)]">
			<span class="text-base font-extrabold text-black leading-none">{info.level}</span>
		</div>
		<div class="flex flex-col gap-1 min-w-0">
			<span class="text-[0.8rem] font-semibold text-[var(--text)]">{t(info.titleKey)}</span>
			<div class="w-full h-1 bg-[rgba(251,146,60,0.15)] rounded-full overflow-hidden">
				<div class="h-full bg-gradient-to-r from-[#fb923c] to-[#f59e0b] rounded-full transition-[width] duration-[0.8s] ease-out" style="width: {info.progressPercent}%"></div>
			</div>
			<span class="text-[0.65rem] text-[var(--text-muted)] tabular-nums">{info.currentXP.toLocaleString()} XP</span>
		</div>
	</div>
{/if}

