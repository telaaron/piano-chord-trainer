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

	const base =
		'rounded-[var(--radius-lg)] border bg-[var(--bg-card)]/60 backdrop-blur-md transition-all duration-200';

	const state = $derived(
		selected
			? 'border-[var(--primary)] bg-[var(--primary-muted)]'
			: 'border-[var(--border)]/40',
	);

	const interactiveCls = $derived(
		interactive
			? 'cursor-pointer text-left w-full hover:border-[var(--primary)]/50 hover:bg-[var(--bg-card-hover)]/80 ' +
					'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--bg)] active:translate-y-px'
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
