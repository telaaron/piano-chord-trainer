<script lang="ts">
	import { scale } from 'svelte/transition';
	import { t } from '$lib/i18n';
	import type { SessionEvaluation } from '$lib/engine';
	import { formatTime } from '$lib/utils/format';
	import { Sparkles, Target, ThumbsUp, Dumbbell, Piano, Check, X, RefreshCw, ArrowLeft, type Icon as LucideIcon } from 'lucide-svelte';

	interface Props {
		evaluation: SessionEvaluation;
		name: string;
		bpm: number;
		onback: () => void;
		onreplay: () => void;
	}

	let { evaluation, name, bpm, onback, onreplay }: Props = $props();

	function gradeLabel(accuracy: number): { text: string; color: string; icon: typeof LucideIcon } {
		if (accuracy >= 0.95) return { text: t('ui.grade_perfect'), color: 'var(--accent-green)', icon: Sparkles };
		if (accuracy >= 0.8) return { text: t('ui.grade_excellent'), color: 'var(--accent-green)', icon: Target };
		if (accuracy >= 0.6) return { text: t('ui.grade_good'), color: 'var(--accent-amber)', icon: ThumbsUp };
		if (accuracy >= 0.4) return { text: t('ui.grade_room_to_grow'), color: 'var(--accent-amber)', icon: Dumbbell };
		return { text: t('ui.grade_keep_practicing'), color: 'var(--accent-red)', icon: Piano };
	}

	const grade = $derived(gradeLabel(evaluation.overallAccuracy));
	const GradeIcon = $derived(grade.icon);
	const accuracyPercent = $derived(Math.round(evaluation.overallAccuracy * 100));
</script>

<div class="max-w-2xl mx-auto space-y-6" in:scale={{ start: 0.95, duration: 300 }}>
	<!-- Hero -->
	<div class="card surface-glass p-8 text-center">
		<div class="mb-3 flex justify-center" style="color: {grade.color}"><GradeIcon size={48} aria-hidden="true" /></div>
		<div class="text-3xl font-bold" style="color: {grade.color}">{grade.text}</div>
		<div class="text-sm text-[var(--text-muted)] mt-2">{name} · {bpm} BPM</div>
	</div>

	<!-- Stats Grid -->
	<div class="grid grid-cols-3 gap-3">
		<div class="card surface-glass p-4 text-center">
			<div class="text-2xl font-bold">{accuracyPercent}%</div>
			<div class="text-xs text-[var(--text-muted)] mt-1">{t('ui.chord_accuracy')}</div>
		</div>
		<div class="card surface-glass p-4 text-center">
			<div class="text-2xl font-bold">{evaluation.avgTimingMs}<span class="text-sm font-normal">ms</span></div>
			<div class="text-xs text-[var(--text-muted)] mt-1">{t('ui.timing_offset')}</div>
		</div>
		<div class="card surface-glass p-4 text-center">
			<div class="text-2xl font-bold">{formatTime(evaluation.totalMs)}</div>
			<div class="text-xs text-[var(--text-muted)] mt-1">{t('ui.total_time')}</div>
		</div>
	</div>

	<!-- Per-Loop Breakdown -->
	{#if evaluation.loops.length > 1}
		<div class="card surface-glass p-5">
			<h3 class="text-sm font-medium mb-3">{t('ui.results_loops')}</h3>
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
		<div class="card surface-glass p-5">
			<h3 class="text-sm font-medium mb-2">{t('ui.results_weakest_chords')}</h3>
			<p class="text-xs text-[var(--text-dim)] mb-3">{t('ui.results_weak_desc')}</p>
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
		<div class="card surface-glass p-5">
			<h3 class="text-sm font-medium mb-3">{t('ui.results_detail_last')}</h3>
			<div class="grid grid-cols-4 sm:grid-cols-6 gap-2">
				{#each lastLoop.chords as ce}
					<div
						class="p-2 rounded-[var(--radius-sm)] text-center text-xs font-mono border {ce.hit ? 'border-[var(--accent-green)]/30 bg-[var(--accent-green)]/5' : 'border-[var(--accent-red)]/30 bg-[var(--accent-red)]/5'}"
					>
						<div class="font-semibold flex justify-center {ce.hit ? 'text-[var(--accent-green)]' : 'text-[var(--accent-red)]'}">
							{#if ce.hit}<Check size={14} aria-hidden="true" />{:else}<X size={14} aria-hidden="true" />{/if}
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
			class="flex-1 h-12 pill-btn pill-btn-primary text-[var(--primary-text)] text-base font-semibold transition-colors cursor-pointer inline-flex items-center justify-center gap-2"
			onclick={onreplay}
		>
			<RefreshCw size={16} aria-hidden="true" /> {t('ui.play_again')}
		</button>
		<button
			class="flex-1 h-12 pill-btn pill-btn-secondary text-[var(--text-muted)] transition-colors cursor-pointer inline-flex items-center justify-center gap-2"
			onclick={onback}
		>
			<ArrowLeft size={16} aria-hidden="true" /> {t('ui.back_editor')}
		</button>
	</div>
</div>
