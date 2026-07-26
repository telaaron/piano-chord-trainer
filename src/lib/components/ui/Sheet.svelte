<script lang="ts">
	import type { Snippet } from 'svelte';
	import { fade, fly } from 'svelte/transition';

	interface Props {
		open: boolean;
		title?: string;
		onclose?: () => void;
		children: Snippet;
		footer?: Snippet;
	}

	let { open = $bindable(), title, onclose, children, footer }: Props = $props();

	let dialogEl: HTMLDivElement | undefined = $state();

	function close() {
		open = false;
		onclose?.();
	}

	function onkeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') {
			e.stopPropagation();
			close();
			return;
		}
		if (e.key !== 'Tab' || !dialogEl) return;
		const focusable = dialogEl.querySelectorAll<HTMLElement>(
			'a[href],button:not([disabled]),input:not([disabled]),select,textarea,[tabindex]:not([tabindex="-1"])',
		);
		if (focusable.length === 0) return;
		const first = focusable[0];
		const last = focusable[focusable.length - 1];
		if (e.shiftKey && document.activeElement === first) {
			e.preventDefault();
			last.focus();
		} else if (!e.shiftKey && document.activeElement === last) {
			e.preventDefault();
			first.focus();
		}
	}

	$effect(() => {
		if (open) {
			const prev = document.body.style.overflow;
			document.body.style.overflow = 'hidden';
			queueMicrotask(() => dialogEl?.querySelector<HTMLElement>('button,a,input')?.focus());
			return () => {
				document.body.style.overflow = prev;
			};
		}
	});
</script>

<svelte:window {onkeydown} />

{#if open}
	<div class="fixed inset-0 z-50 flex items-end justify-center sm:items-center" role="presentation">
		<button
			type="button"
			aria-label="Close"
			tabindex="-1"
			class="absolute inset-0 bg-black/60 backdrop-blur-sm"
			onclick={close}
			transition:fade={{ duration: 150 }}
		></button>

		<div
			bind:this={dialogEl}
			role="dialog"
			aria-modal="true"
			aria-label={title}
			class="relative w-full max-w-lg max-h-[90dvh] overflow-y-auto rounded-t-[2px] sm:rounded-[2px]
				border border-[var(--border-hover)] bg-[var(--bg)] shadow-[var(--shadow-lg)]"
			transition:fly={{ y: 24, duration: 220 }}
		>
			{#if title}
				<div class="sticky top-0 z-10 flex items-center justify-between gap-4 border-b border-[var(--border)] bg-[var(--bg)] px-5 py-3.5">
					<h2 class="text-[var(--text-lg)] font-semibold text-[var(--text)] font-[family-name:var(--font-display)] tracking-[-0.02em]">{title}</h2>
					<button
						type="button"
						aria-label="Close"
						onclick={close}
						class="grid h-9 w-9 place-items-center rounded-[2px] text-[var(--text-muted)] hover:bg-[var(--bg-card)] hover:text-[var(--text)]
							focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)]"
					>
						<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
							<path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
						</svg>
					</button>
				</div>
			{/if}
			<div class="px-5 py-4">{@render children()}</div>
			{#if footer}
				<div class="sticky bottom-0 border-t border-[var(--border)] bg-[var(--bg)] px-5 py-3">
					{@render footer()}
				</div>
			{/if}
		</div>
	</div>
{/if}
