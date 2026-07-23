<script lang="ts">
	import { fly, fade } from 'svelte/transition';
	import { flip } from 'svelte/animate';
	import { onMount } from 'svelte';
	import { onToastChange, dismissToast, type Toast } from '$lib/services/toast';
	import { Check, X, TriangleAlert, Info, type Icon as LucideIcon } from 'lucide-svelte';

	let toasts: Toast[] = $state([]);

	onMount(() => {
		return onToastChange((t) => (toasts = t));
	});

	const icons: Record<Toast['type'], typeof LucideIcon> = {
		success: Check,
		error: X,
		warning: TriangleAlert,
		info: Info,
	};

	const colors: Record<Toast['type'], string> = {
		success: 'var(--accent-green)',
		error: 'var(--accent-red)',
		warning: 'var(--accent-amber)',
		info: 'var(--primary)',
	};
</script>

<div
	class="fixed bottom-6 left-1/2 -translate-x-1/2 z-[100] flex flex-col-reverse gap-2 items-center
	       w-[calc(100%-2rem)] max-w-sm pointer-events-none"
	aria-live="polite"
	aria-label="Notifications"
>
	{#each toasts as t (t.id)}
		{@const ToastIcon = icons[t.type]}
		<div
			in:fly={{ y: 40, duration: 250 }}
			out:fade={{ duration: 200 }}
			animate:flip={{ duration: 200 }}
			class="w-full pointer-events-auto flex items-center gap-3
			       bg-[var(--bg-card)]/84 border border-[var(--border)]
			       rounded-[var(--radius)] px-4 py-3 shadow-xl text-sm backdrop-blur-xl"
			style="border-color: color-mix(in srgb, {colors[t.type]} 35%, var(--border));"
		>
			<!-- Icon -->
			<span class="shrink-0 w-5 h-5 rounded-full flex items-center justify-center text-[11px] font-bold text-[var(--bg)]"
				style="background-color: {colors[t.type]};"
			><ToastIcon size={12} aria-hidden="true" /></span>

			<!-- Message -->
			<span class="flex-1 text-[var(--text)] leading-snug">{t.message}</span>

			<!-- Optional action -->
			{#if t.action}
				<button
					class="shrink-0 text-xs px-2.5 py-1 rounded-full
					       border border-[var(--border)] text-[var(--text-muted)] bg-[var(--bg)]/50
					       hover:border-[var(--border-hover)] hover:text-[var(--text)] hover:bg-[var(--bg)]/75
					       transition-colors cursor-pointer whitespace-nowrap"
					onclick={() => { t.action!.onClick(); dismissToast(t.id); }}
				>{t.action.label}</button>
			{/if}

			<!-- Dismiss -->
			<button
				class="shrink-0 text-[var(--text-dim)] hover:text-[var(--text)] transition-colors cursor-pointer text-lg leading-none"
				onclick={() => dismissToast(t.id)}
				aria-label="Dismiss"
			>×</button>
		</div>
	{/each}
</div>
