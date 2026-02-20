<script lang="ts">
	import { fly, fade } from 'svelte/transition';
	import { onMount } from 'svelte';

	interface Props {
		message: string;
		onDismiss: () => void;
		onReconnect?: () => void;
	}

	let { message, onDismiss, onReconnect }: Props = $props();

	// Auto-dismiss after 6 seconds
	onMount(() => {
		const t = setTimeout(onDismiss, 6000);
		return () => clearTimeout(t);
	});
</script>

<div
	in:fly={{ y: 40, duration: 250 }}
	out:fade={{ duration: 200 }}
	class="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3
	       bg-[var(--bg-card)] border border-[var(--accent-amber)]/50
	       rounded-[var(--radius)] px-4 py-3 shadow-xl
	       text-sm max-w-sm w-[calc(100%-2rem)]"
>
	<span class="text-[var(--accent-amber)] text-base shrink-0">⚠</span>
	<span class="flex-1 text-[var(--text)]">{message}</span>
	{#if onReconnect}
		<button
			class="shrink-0 text-xs px-2 py-1 rounded-[var(--radius-sm)]
			       border border-[var(--border)] text-[var(--text-muted)]
			       hover:border-[var(--accent-amber)] hover:text-[var(--accent-amber)]
			       transition-colors cursor-pointer"
			onclick={onReconnect}
		>
			Reconnect
		</button>
	{/if}
	<button
		class="shrink-0 text-[var(--text-dim)] hover:text-[var(--text)] transition-colors cursor-pointer text-lg leading-none"
		onclick={onDismiss}
		aria-label="Dismiss"
	>×</button>
</div>
