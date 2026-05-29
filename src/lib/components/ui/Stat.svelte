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

<div class="flex flex-col gap-1 rounded-[var(--radius)] border border-[var(--border)]/40 bg-[var(--bg-card)]/50 p-3">
	<div class="flex items-center gap-1.5 text-[var(--text-dim)]">
		{#if icon}<span class="shrink-0">{@render icon()}</span>{/if}
		<span class="text-[var(--text-xs)] uppercase tracking-wide">{label}</span>
	</div>
	<span class="text-[var(--text-2xl)] font-bold tabular-nums leading-none {valueColor[accent]}">{value}</span>
</div>
