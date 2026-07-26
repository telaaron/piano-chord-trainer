<script lang="ts">
	import type { Snippet } from 'svelte';

	interface Props {
		interactive?: boolean;
		selected?: boolean;
		href?: string;
		ariaLabel?: string;
		padding?: 'sm' | 'md' | 'lg';
		onclick?: (e: MouseEvent) => void;
		children: Snippet;
	}

	let {
		interactive = false,
		selected = false,
		href,
		ariaLabel,
		padding = 'md',
		onclick,
		children,
	}: Props = $props();

	const pad: Record<string, string> = {
		sm: 'p-3',
		md: 'p-4 sm:p-5',
		lg: 'p-5 sm:p-6',
	};

	// A card here is a ruled panel, not a floating chip: hairline border,
	// flat stock, 2px corner. Structure comes from the rule, not a shadow.
	const base =
		'rounded-[2px] border bg-[var(--bg-card)] transition-[background-color,border-color] duration-150';

	const state = $derived(
		selected
			? 'border-[var(--primary)] bg-[var(--primary-muted)]'
			: 'border-[var(--border)]',
	);

	const interactiveCls = $derived(
		interactive
			? 'cursor-pointer text-left w-full hover:border-[var(--text-muted)] hover:bg-[var(--bg-card-hover)] ' +
					'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--bg)]'
			: '',
	);

	const cls = $derived(`${base} ${pad[padding]} ${state} ${interactiveCls}`);
</script>

{#if href}
	<a {href} class={cls} aria-label={ariaLabel} {onclick}>{@render children()}</a>
{:else if interactive}
	<button type="button" class={cls} aria-label={ariaLabel} aria-pressed={selected} {onclick}>
		{@render children()}
	</button>
{:else}
	<div class={cls}>{@render children()}</div>
{/if}
