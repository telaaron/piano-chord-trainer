<script lang="ts">
	// Sing a scale degree over a drone; the mic grades the pitch class.
	//
	// The detector runs on ~800 ms cycles, so we ACCUMULATE every MIDI number it
	// reports across the whole attempt rather than reading one snapshot — a held
	// note only has to be caught once for `gradeSing` to find its pitch class.

	import { onDestroy } from 'svelte';
	import { t } from '$lib/i18n';
	import { AudioInputService, type AudioInputState } from '$lib/services/audio-input';
	import { Mic } from 'lucide-svelte';

	interface Props {
		/** Answer callback — the accumulated MIDI numbers the mic heard. */
		onanswer: (sungMidi: number[]) => void;
		/** Freeze input once the answer is in. */
		locked?: boolean;
	}

	let { onanswer, locked = false }: Props = $props();

	const NOTE_NAMES = ['C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B'];

	let mic: AudioInputService | null = null;
	let micState = $state<AudioInputState>('idle');
	let listening = $state(false);
	let level = $state(0);
	/** Every MIDI number the mic reported during this attempt. */
	let heard = $state<number[]>([]);
	let levelTimer: ReturnType<typeof setInterval> | null = null;

	const heardNames = $derived([...new Set(heard.map((m) => ((m % 12) + 12) % 12))].map((pc) => NOTE_NAMES[pc]));

	async function startListening() {
		if (listening) return;
		heard = [];
		listening = true;
		mic = new AudioInputService();
		mic.onConnection((s) => (micState = s));
		mic.onNotes((notes) => {
			if (notes.size === 0) return;
			heard = [...heard, ...notes];
		});
		const ok = await mic.init();
		if (!ok) {
			listening = false;
			return;
		}
		levelTimer = setInterval(() => {
			level = mic?.getLevel() ?? 0;
		}, 80);
	}

	function teardown() {
		if (levelTimer) {
			clearInterval(levelTimer);
			levelTimer = null;
		}
		mic?.destroy();
		mic = null;
		listening = false;
		level = 0;
	}

	function submit() {
		const collected = [...heard];
		teardown();
		onanswer(collected);
	}

	onDestroy(teardown);
</script>

<div class="flex flex-col gap-4">
	{#if !listening}
		<button
			type="button"
			onclick={startListening}
			disabled={locked}
			class="flex min-h-14 w-full items-center justify-center gap-2 rounded-[var(--radius)] bg-[var(--primary)] px-5 font-semibold text-white shadow-[var(--shadow-md)] transition hover:brightness-105 disabled:opacity-50"
		>
			<Mic size={20} aria-hidden="true" />
			{t('togo.sing_start')}
		</button>
		<p class="text-center text-[var(--text-sm)] text-[var(--text-muted)]">{t('togo.sing_hint')}</p>
	{:else}
		{#if micState === 'denied' || micState === 'unsupported' || micState === 'error'}
			<p class="rounded-[var(--radius)] border border-[var(--accent-red)]/40 bg-[var(--accent-red)]/10 p-3 text-center text-[var(--text-sm)] text-[var(--text)]">
				{t('togo.sing_denied')}
			</p>
		{:else}
			<!-- Input level -->
			<div>
				<div class="mb-1 flex items-center justify-between text-[var(--text-xs)] text-[var(--text-muted)]">
					<span>{t('togo.sing_level')}</span>
					{#if micState === 'loading-model'}<span>{t('togo.listen')}</span>{/if}
				</div>
				<div class="h-2.5 w-full overflow-hidden rounded-full bg-[var(--border)]">
					<div
						class="h-full rounded-full bg-[var(--primary)] transition-[width] duration-75"
						style="width: {Math.round(level * 100)}%"
					></div>
				</div>
			</div>

			<!-- What the mic has heard so far -->
			<div class="rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg-card)] p-3 text-center">
				<div class="text-[var(--text-xs)] uppercase tracking-wide text-[var(--text-muted)]">{t('togo.sing_heard')}</div>
				<div class="mt-1 text-[var(--text-lg)] font-semibold text-[var(--text)]">
					{heardNames.length > 0 ? heardNames.join(' · ') : t('togo.sing_nothing_yet')}
				</div>
			</div>
		{/if}

		<button
			type="button"
			onclick={submit}
			disabled={locked}
			class="min-h-14 w-full rounded-[var(--radius)] bg-[var(--primary)] px-5 font-semibold text-white shadow-[var(--shadow-md)] transition hover:brightness-105 disabled:opacity-50"
		>
			{t('togo.sing_check')}
		</button>
	{/if}
</div>
