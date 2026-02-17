<script lang="ts">
	import { scale } from 'svelte/transition';
	import type { SessionEvaluation } from '$lib/engine';
	import { formatTime } from '$lib/utils/format';

	interface Props {
		evaluation: SessionEvaluation;
		name: string;
		bpm: number;
		onback: () => void;
		onreplay: () => void;
	}

	let { evaluation, name, bpm, onback, onreplay }: Props = $props();

	function gradeLabel(accuracy: number): { text: string; color: string; emoji: string } {
		if (accuracy >= 0.95) return { text: 'Perfect', color: 'var(--accent-green)', emoji: '🌟' };
		if (accuracy >= 0.8) return { text: 'Excellent', color: 'var(--accent-green)', emoji: '🎯' };
		if (accuracy >= 0.6) return { text: 'Good', color: 'var(--accent-amber)', emoji: '👍' };
		if (accuracy >= 0.4) return { text: 'Room to grow', color: 'var(--accent-amber)', emoji: '💪' };
		return { text: 'Keep practicing', color: 'var(--accent-red)', emoji: '🎹' };
	}

	const grade = $derived(gradeLabel(evaluation.overallAccuracy));
	const accuracyPercent = $derived(Math.round(evaluation.overallAccuracy * 100));
</script>

<div class="max-w-2xl mx-auto space-y-6" in:scale={{ start: 0.95, duration: 300 }}>
	<!-- Hero -->
	<div class="card p-8 text-center">
		<div class="text-5xl mb-3">{grade.emoji}</div>
		<div class="text-3xl font-bold" style="color: {grade.color}">{grade.text}</div>
		<div class="text-sm text-[var(--text-muted)] mt-2">{name} · {bpm} BPM</div>
	</div>

	<!-- Stats Grid -->
	<div class="grid grid-cols-3 gap-3">
		<div class="card p-4 text-center">
			<div class="text-2xl font-bold">{accuracyPercent}%</div>
			<div class="text-xs text-[var(--text-muted)] mt-1">Chord Accuracy</div>
		</div>
		<div class="card p-4 text-center">
			<div class="text-2xl font-bold">{evaluation.avgTimingMs}<span class="text-sm font-normal">ms</span></div>
			<div class="text-xs text-[var(--text-muted)] mt-1">⌀ Timing-Offset</div>
		</div>
		<div class="card p-4 text-center">
			<div class="text-2xl font-bold">{formatTime(evaluation.totalMs)}</div>
			<div class="text-xs text-[var(--text-muted)] mt-1">Total Time</div>
		</div>
	</div>

	<!-- Per-Loop Breakdown -->
	{#if evaluation.loops.length > 1}
		<div class="card p-5">
			<h3 class="text-sm font-medium mb-3">Loops</h3>
			<div class="space-y-2">
				{#each evaluation.loops as loop, i}
					<div class="flex items-center gap-3">
						<span class="text-xs text-[var(--text-dim)] w-6">{i + 1}.</span>
						<div class="flex-1 bg-[var(--bg-muted)] rounded-full h-3 overflow-hidden">
							<div
								class="h-full rounded-full transition-all {loop.accuracy >= 0.8 ? 'bg-[var(--accent-green)]' : loop.accuracy >= 0.5 ? 'bg-[var(--accent-amber)]' : 'bg-[var(--accent-red)]'}"
								style="width: {loop.accuracy * 100}%"
							></div>
						</div>
						<span class="text-xs font-mono w-10 text-right">{Math.round(loop.accuracy * 100)}%</span>
					</div>
				{/each}
			</div>
		</div>
	{/if}

	<!-- Weak Chords -->
	{#if evaluation.weakChords.length > 0}
		<div class="card p-5">
			<h3 class="text-sm font-medium mb-2">Weakest Chords</h3>
			<p class="text-xs text-[var(--text-dim)] mb-3">These chords were often missed — focus on them!</p>
			<div class="flex flex-wrap gap-2">
				{#each evaluation.weakChords as chord}
					<span class="bg-[var(--accent-red)]/10 text-[var(--accent-red)] px-3 py-1 rounded-full text-sm font-mono font-semibold">
						{chord}
					</span>
				{/each}
			</div>
		</div>
	{/if}

	<!-- Per-chord detail (last loop) -->
	{#if evaluation.loops.length > 0}
		{@const lastLoop = evaluation.loops[evaluation.loops.length - 1]}
		<div class="card p-5">
			<h3 class="text-sm font-medium mb-3">Detail (last loop)</h3>
			<div class="grid grid-cols-4 sm:grid-cols-6 gap-2">
				{#each lastLoop.chords as ce}
					<div
						class="p-2 rounded-[var(--radius-sm)] text-center text-xs font-mono border {ce.hit ? 'border-[var(--accent-green)]/30 bg-[var(--accent-green)]/5' : 'border-[var(--accent-red)]/30 bg-[var(--accent-red)]/5'}"
					>
						<div class="font-semibold {ce.hit ? 'text-[var(--accent-green)]' : 'text-[var(--accent-red)]'}">
							{ce.hit ? '✓' : '✗'}
						</div>
						<div class="mt-0.5 text-[var(--text-muted)] truncate">{ce.chord.display}</div>
					</div>
				{/each}
			</div>
		</div>
	{/if}

	<!-- Actions -->
	<div class="flex gap-3">
		<button
			class="flex-1 h-12 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] text-base font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer"
			onclick={onreplay}
		>
			🔄 Again
		</button>
		<button
			class="flex-1 h-12 rounded-[var(--radius)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)] transition-colors cursor-pointer"
			onclick={onback}
		>
			← Back
		</button>
	</div>
</div>
