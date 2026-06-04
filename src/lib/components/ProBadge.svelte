<script lang="ts">
	import { showLock } from '$lib/services/subscription-store.svelte';

	interface Props {
		/** Feature gate key; badge only shows when this feature is locked. */
		feature: string;
		/** Visual size. */
		size?: 'xs' | 'sm';
		class?: string;
	}

	let { feature, size = 'sm', class: extra = '' }: Props = $props();

	const sizes = {
		xs: 'text-[0.6rem] px-1.5 py-px gap-0.5',
		sm: 'text-[0.65rem] px-2 py-0.5 gap-1',
	} as const;
</script>

{#if showLock(feature)}
	<span
		class="inline-flex items-center rounded-full border border-[var(--accent-gold)]/40 bg-[var(--accent-gold)]/12 font-semibold uppercase tracking-wide text-[var(--accent-gold)] {sizes[
			size
		]} {extra}"
		aria-label="Pro feature"
	>
		<svg class="h-2.5 w-2.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
			<rect x="5" y="11" width="14" height="9" rx="2" />
			<path d="M8 11V7a4 4 0 0 1 8 0v4" />
		</svg>
		Pro
	</span>
{/if}
