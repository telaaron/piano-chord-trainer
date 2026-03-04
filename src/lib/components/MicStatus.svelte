<script lang="ts">
	import type { AudioInputState } from '$lib/services/audio-input';
	import { t } from '$lib/i18n';

	interface Props {
		state: AudioInputState;
		activeNoteCount: number;
		onConnect: () => void;
	}

	let { state, activeNoteCount, onConnect }: Props = $props();

	const stateLabel = $derived(
		state === 'listening'
			? t('mic.listening')
			: state === 'analyzing'
				? t('mic.analyzing')
				: state === 'loading-model'
					? t('mic.loading_model')
					: state === 'requesting'
						? t('mic.requesting')
						: state === 'denied'
							? t('mic.denied')
							: state === 'unsupported'
								? t('mic.unsupported')
								: state === 'error'
									? t('mic.error')
									: t('mic.idle'),
	);

	const stateColor = $derived(
		state === 'listening'
			? 'bg-[var(--accent-green)]'
			: state === 'analyzing'
				? 'bg-[var(--accent-amber)] animate-pulse'
				: state === 'loading-model' || state === 'requesting'
					? 'bg-[var(--accent-amber)] animate-pulse'
					: state === 'denied' || state === 'error'
						? 'bg-red-500'
						: 'bg-[var(--text-dim)]',
	);
</script>

<div class="flex items-center gap-3 text-sm flex-wrap">
	<!-- Status dot + label -->
	<div class="flex items-center gap-2">
		<div class="w-2 h-2 rounded-full {stateColor}"></div>
		<span class="text-[var(--text-muted)]">🎙 {stateLabel}</span>
	</div>

	{#if state === 'idle'}
		<button
			class="px-3 py-1 rounded-[var(--radius-sm)] border border-[var(--border)] text-xs hover:border-[var(--border-hover)] transition-colors cursor-pointer"
			onclick={onConnect}
		>
			{t('mic.enable')}
		</button>
	{/if}

	{#if state === 'denied'}
		<span class="text-xs text-[var(--accent-amber)]">
			{t('mic.denied_hint')}
		</span>
	{/if}

	{#if state === 'unsupported'}
		<span class="text-xs text-[var(--text-dim)]">
			{t('mic.unsupported_hint')}
		</span>
	{/if}

	{#if (state === 'listening' || state === 'analyzing') && activeNoteCount > 0}
		<span class="text-xs text-[var(--text-dim)] font-mono">
			♪ {activeNoteCount}
		</span>
	{/if}
</div>
