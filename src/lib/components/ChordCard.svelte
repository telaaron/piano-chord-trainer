<script lang="ts">
	import { t } from '$lib/i18n';
	import { convertChordNotation, type NotationSystem } from '$lib/engine';
	import type { VoiceLeadingInfo } from '$lib/engine';
	import { formatVoiceLeading } from '$lib/engine';

	import type { Snippet } from 'svelte';

	interface Props {
		chord: string;
		system?: NotationSystem;
		onclick?: () => void;
		children?: Snippet;
		/** Voice leading info from previous chord */
		voiceLeading?: VoiceLeadingInfo | null;
		/** Whether to show voice leading text */
		showVoiceLeading?: boolean;
		/** Whether the chord name should be hidden (ear training mode) */
		hideChordName?: boolean;
	}

	let { chord, system = 'international', onclick, children, voiceLeading = null, showVoiceLeading = false, hideChordName = false }: Props = $props();

	const display = $derived(convertChordNotation(chord, system));
	const vlText = $derived(showVoiceLeading && voiceLeading ? formatVoiceLeading(voiceLeading) : '');
</script>

<div
	class="card p-8 sm:p-12 text-center cursor-pointer active:scale-[0.98] transition-transform"
	role="button"
	tabindex="0"
	{onclick}
	onkeydown={(e) => { if (e.code === 'Space' || e.code === 'Enter') { e.preventDefault(); onclick?.(); } }}
>
	{#if hideChordName}
		<div class="text-6xl sm:text-8xl font-bold text-[var(--text-dim)] animate-pulse-slow">
			🎧
		</div>
		<div class="text-sm text-[var(--text-muted)] mt-2">{t('ui.listen_and_play')}</div>
	{:else}
		<div class="text-6xl sm:text-8xl font-bold text-gradient animate-pulse-slow">
			{display}
		</div>
	{/if}
	{#if vlText}
		<div class="mt-3 text-sm text-[var(--accent-amber)] font-mono">
			{vlText}
		</div>
	{/if}
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
