<script lang="ts">
	import type { Snippet } from 'svelte';

	interface Props {
		label: string;
		value: string | number;
		accent?: 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'xp';
		icon?: Snippet;
	}

	let { label, value, accent = 'default', icon }: Props = $props();

	const valueColor: Record<string, string> = {
		default: 'text-[var(--text)]',
		primary: 'text-[var(--primary)]',
		success: 'text-[var(--success)]',
		warning: 'text-[var(--warning)]',
		danger: 'text-[var(--danger)]',
		xp: 'text-[var(--xp)]',
	};
</script>

<!-- A ledger cell: the label is a small-caps plate line, the figure is set
     in the display serif so numbers read as printed, not as a dashboard. -->
<div class="flex flex-col gap-1.5 rounded-[2px] border border-[var(--border)] bg-[var(--bg-card)] px-3 py-2.5">
	<div class="flex items-center gap-1.5 text-[var(--text-dim)]">
		{#if icon}<span class="shrink-0">{@render icon()}</span>{/if}
		<span class="text-[0.6rem] uppercase tracking-[0.15em] font-[family-name:var(--font-mono)]">{label}</span>
	</div>
	<span
		class="text-[var(--text-2xl)] font-semibold tabular-nums leading-none font-[family-name:var(--font-display)] {valueColor[accent]}"
		>{value}</span
	>
</div>
