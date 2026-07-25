<script lang="ts">
	// Tap along with the click; graded on timing offsets.
	//
	// TIME BASE: the metronome callback hands us the Web-Audio context time in
	// SECONDS, which is a different clock from `performance.now()`. Rather than
	// converting, we stamp `performance.now()` inside the callback — the callback
	// fires synchronously on the beat, so both the expected beats and the user's
	// taps end up on one clock and `gradeTaps` compares like with like.

	import { onDestroy } from 'svelte';
	import { t } from '$lib/i18n';
	import { startMetronome, stopMetronome } from '$lib/services/audio';
	import type { ToGoExercise } from '$lib/engine/togo';

	interface Props {
		exercise: ToGoExercise;
		/** Reports the two time series once the run ends. */
		onanswer: (beatTimesMs: number[], tapTimesMs: number[]) => void;
		locked?: boolean;
	}

	let { exercise, onanswer, locked = false }: Props = $props();

	const pulse = $derived(exercise.play.type === 'pulse' ? exercise.play : null);
	const tap = $derived(exercise.input.type === 'tap' ? exercise.input : null);

	let running = $state(false);
	let currentBeat = $state(0);
	let barsPlayed = $state(0);
	let tapFlash = $state(false);

	// Collected outside $state — these are hot-path arrays, not rendered.
	let beatTimes: number[] = [];
	let tapTimes: number[] = [];
	let flashTimer: ReturnType<typeof setTimeout> | null = null;

	// One free bar to count in before anything is scored.
	const COUNT_IN_BARS = 1;

	async function start() {
		if (running || !pulse || !tap) return;
		beatTimes = [];
		tapTimes = [];
		barsPlayed = 0;
		currentBeat = 0;
		running = true;

		const beatsPerBar = pulse.beatsPerBar;
		const totalBars = COUNT_IN_BARS + pulse.bars;
		let absoluteBeat = 0;

		await startMetronome(pulse.bpm, beatsPerBar, (beat) => {
			// Same clock as the tap handler — see the note at the top of this file.
			const stamp = performance.now();
			absoluteBeat++;
			currentBeat = beat;
			const bar = Math.floor((absoluteBeat - 1) / beatsPerBar);
			barsPlayed = bar;

			// Score only after the count-in bar.
			if (bar >= COUNT_IN_BARS && tap.onBeats.includes(beat)) {
				beatTimes.push(stamp);
			}

			if (bar >= totalBars - 1 && beat === beatsPerBar) {
				// Give the final beat its tolerance window before we grade.
				setTimeout(finish, tap.toleranceMs + 120);
			}
		});
	}

	function registerTap() {
		if (!running || locked) return;
		tapTimes.push(performance.now());
		tapFlash = true;
		if (flashTimer) clearTimeout(flashTimer);
		flashTimer = setTimeout(() => (tapFlash = false), 110);
	}

	function finish() {
		if (!running) return;
		running = false;
		stopMetronome();
		onanswer([...beatTimes], [...tapTimes]);
	}

	function onKeydown(e: KeyboardEvent) {
		if (e.code !== 'Space' || e.repeat) return;
		e.preventDefault();
		registerTap();
	}

	onDestroy(() => {
		if (flashTimer) clearTimeout(flashTimer);
		stopMetronome();
	});
</script>

<svelte:window onkeydown={running ? onKeydown : undefined} />

<div class="flex flex-col gap-4">
	{#if !running}
		<p class="text-center text-[var(--text-sm)] text-[var(--text-muted)]">{t('togo.tap_ready')}</p>
		<button
			type="button"
			onclick={start}
			disabled={locked}
			class="min-h-14 w-full rounded-[var(--radius)] bg-[var(--primary)] px-5 font-semibold text-white shadow-[var(--shadow-md)] transition hover:brightness-105 disabled:opacity-50"
		>
			{t('togo.tap_start')}
		</button>
	{:else}
		<!-- Beat lamps -->
		<div class="flex items-center justify-center gap-3" aria-hidden="true">
			{#each Array(pulse?.beatsPerBar ?? 4) as _, i}
				{@const beat = i + 1}
				{@const isTarget = tap?.onBeats.includes(beat) ?? false}
				<div
					class="h-4 w-4 rounded-full border-2 transition-all duration-75
					{currentBeat === beat
						? 'scale-125 border-[var(--primary)] bg-[var(--primary)]'
						: isTarget
							? 'border-[var(--primary)]/60 bg-transparent'
							: 'border-[var(--border)] bg-transparent'}"
				></div>
			{/each}
		</div>

		<div class="text-center text-[var(--text-xs)] uppercase tracking-wide text-[var(--text-muted)]">
			{barsPlayed < COUNT_IN_BARS ? t('togo.tap_ready') : `${barsPlayed - COUNT_IN_BARS + 1} / ${pulse?.bars ?? 0}`}
		</div>

		<button
			type="button"
			onpointerdown={registerTap}
			class="aspect-square w-full max-w-[16rem] self-center rounded-full border-4 text-[var(--text-xl)] font-bold uppercase tracking-wide transition-transform duration-75
			{tapFlash
				? 'scale-95 border-[var(--primary)] bg-[var(--primary)] text-white'
				: 'border-[var(--primary)]/50 bg-[var(--bg-card)] text-[var(--text)]'}"
		>
			{t('togo.tap_button')}
		</button>
		<p class="text-center text-[var(--text-xs)] text-[var(--text-muted)]">{t('togo.tap_hint')}</p>
	{/if}
</div>
