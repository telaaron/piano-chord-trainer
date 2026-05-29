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

	const base =
		'inline-flex items-center justify-center gap-2 font-semibold rounded-[var(--radius)] ' +
		'transition-[background-color,border-color,color,transform,filter] duration-200 ' +
		'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--bg)] ' +
		'active:translate-y-px disabled:opacity-50 disabled:pointer-events-none select-none';

	const sizes: Record<Size, string> = {
		sm: 'min-h-9 px-3 text-[var(--text-sm)]',
		md: 'min-h-[var(--tap-min)] px-4 text-[var(--text-base)]',
		lg: 'min-h-12 px-6 text-[var(--text-lg)]',
	};

	const variants: Record<Variant, string> = {
		primary:
			'text-white border border-white/10 shadow-[var(--shadow-md)] hover:brightness-105 ' +
			'[background:linear-gradient(135deg,var(--primary)_0%,var(--accent-amber)_100%)]',
		secondary:
			'bg-[var(--bg-card)] text-[var(--text)] border border-[var(--border)] ' +
			'hover:bg-[var(--bg-card-hover)] hover:border-[var(--primary)]/50',
		ghost:
			'bg-transparent text-[var(--text-muted)] border border-transparent ' +
			'hover:bg-[var(--bg-card)] hover:text-[var(--text)]',
		danger:
			'bg-[var(--danger-muted)] text-[var(--danger)] border border-[var(--danger)]/40 ' +
			'hover:bg-[var(--danger)] hover:text-white',
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
