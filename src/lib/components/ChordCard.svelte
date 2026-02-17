<script lang="ts">
	import { convertChordNotation, type NotationSystem } from '$lib/engine';

	import type { Snippet } from 'svelte';

	interface Props {
		chord: string;
		system?: NotationSystem;
		onclick?: () => void;
		children?: Snippet;
	}

	let { chord, system = 'international', onclick, children }: Props = $props();

	const display = $derived(convertChordNotation(chord, system));
</script>

<div
	class="card p-8 sm:p-12 text-center cursor-pointer active:scale-[0.98] transition-transform"
	role="button"
	tabindex="0"
	{onclick}
	onkeydown={(e) => { if (e.code === 'Space' || e.code === 'Enter') { e.preventDefault(); onclick?.(); } }}
>
	<div class="text-6xl sm:text-8xl font-bold text-gradient animate-pulse-slow">
		{display}
	</div>
	{#if children}
		{@render children()}
	{/if}
</div>

<style>
	@keyframes pulse-slow {
		0%, 100% { opacity: 1; }
		50% { opacity: 0.85; }
	}
	.animate-pulse-slow {
		animation: pulse-slow 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
	}
</style>
