<script lang="ts">
	import type { Snippet } from 'svelte';

	type Variant = 'primary' | 'secondary' | 'ghost' | 'danger';
	type Size = 'sm' | 'md' | 'lg';

	interface Props {
		variant?: Variant;
		size?: Size;
		type?: 'button' | 'submit';
		href?: string;
		disabled?: boolean;
		fullWidth?: boolean;
		ariaLabel?: string;
		title?: string;
		onclick?: (e: MouseEvent) => void;
		children: Snippet;
	}

	let {
		variant = 'primary',
		size = 'md',
		type = 'button',
		href,
		disabled = false,
		fullWidth = false,
		ariaLabel,
		title,
		onclick,
		children,
	}: Props = $props();

	// Press-shop buttons: a near-square 2px corner, a real 1px rule on every
	// variant so they all sit on the same optical grid, and no gradients —
	// the primary is one flat pull of stamp ink.
	const base =
		'inline-flex items-center justify-center gap-2 font-semibold rounded-[2px] tracking-[0.005em] ' +
		'transition-[background-color,border-color,color] duration-150 ' +
		'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--bg)] ' +
		'active:translate-y-px disabled:opacity-50 disabled:pointer-events-none select-none';

	const sizes: Record<Size, string> = {
		sm: 'min-h-9 px-3.5 text-[var(--text-sm)]',
		md: 'min-h-[var(--tap-min)] px-5 text-[var(--text-base)]',
		lg: 'min-h-12 px-7 text-[var(--text-lg)]',
	};

	const variants: Record<Variant, string> = {
		primary:
			'bg-[var(--primary)] text-[var(--primary-text)] border border-[var(--primary)] ' +
			'hover:bg-[var(--primary-hover)] hover:border-[var(--primary-hover)]',
		secondary:
			'bg-transparent text-[var(--text)] border border-[var(--border)] ' +
			'hover:bg-[var(--bg-card)] hover:border-[var(--text-muted)]',
		ghost:
			'bg-transparent text-[var(--text-muted)] border border-transparent ' +
			'hover:bg-[var(--bg-card)] hover:text-[var(--text)]',
		danger:
			'bg-transparent text-[var(--danger)] border border-[var(--danger)]/50 ' +
			'hover:bg-[var(--danger)] hover:border-[var(--danger)] hover:text-[var(--bg)]',
	};

	const cls = $derived(
		`${base} ${sizes[size]} ${variants[variant]} ${fullWidth ? 'w-full' : ''}`,
	);
</script>

{#if href}
	<a {href} class={cls} aria-label={ariaLabel} {title} aria-disabled={disabled} {onclick}>
		{@render children()}
	</a>
{:else}
	<button {type} class={cls} {disabled} aria-label={ariaLabel} {title} {onclick}>
		{@render children()}
	</button>
{/if}
