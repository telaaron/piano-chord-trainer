<script lang="ts">
	import { t } from '$lib/i18n';
	import { getChordNotes, getVoicingNotes, getVoicingIntervalLabels, getChordFormula } from '$lib/engine';
	import type { VoicingType, ChordWithNotes } from '$lib/engine';
	import { playChord } from '$lib/services/audio';
	import PianoKeyboard from './PianoKeyboard.svelte';

	interface Props {
		/** The chord currently displayed, e.g. "CMaj7" */
		chordData: ChordWithNotes;
		/** The active voicing type */
		voicing: VoicingType;
		/** Called when the panel should close */
		onclose: () => void;
	}

	let { chordData, voicing, onclose }: Props = $props();

	// ─── Voicing explanation from i18n ─────────────────────────
	const voicingTitle = $derived(t(`explain.${voicing}.title`));
	const voicingDesc = $derived(t(`explain.${voicing}.desc`));

	// ─── Chord quality explanation from i18n ───────────────────
	const qualityTitle = $derived(t(`explain.quality.${chordData.type}.title`));
	const qualityDesc = $derived(t(`explain.quality.${chordData.type}.desc`));

	// ─── Dynamic formula from actual notes ─────────────────────
	const voicingNotes = $derived(
		getVoicingNotes(chordData.notes, voicing, chordData.root, 'sharps'),
	);
	const intervalLabels = $derived(
		getVoicingIntervalLabels(voicingNotes, chordData.root, chordData.type),
	);
	const chordFormula = $derived(getChordFormula(chordData.type));

	// ─── Visual diff: which chord tones are kept vs dropped ────
	const droppedIntervals = $derived(
		chordFormula.filter((iv) => !intervalLabels.includes(iv)),
	);
	const keptCount = $derived(intervalLabels.length);
	const totalCount = $derived(chordFormula.length);
	const isReduced = $derived(keptCount < totalCount);

	const displayData = $derived<ChordWithNotes>({
		...chordData,
		voicing: voicingNotes,
	});

	// ─── Glossary for interval symbols ─────────────────────────
	const INTERVAL_GLOSSARY: Record<string, string> = {
		'R': 'explain.glossary.R',
		'♭2': 'explain.glossary.b2',
		'2': 'explain.glossary.2',
		'♭3': 'explain.glossary.b3',
		'3': 'explain.glossary.3',
		'4': 'explain.glossary.4',
		'♯4': 'explain.glossary.s4',
		'°5': 'explain.glossary.dim5',
		'♭5': 'explain.glossary.b5',
		'5': 'explain.glossary.5',
		'♯5': 'explain.glossary.s5',
		'°7': 'explain.glossary.dim7',
		'6': 'explain.glossary.6',
		'♭7': 'explain.glossary.b7',
		'7': 'explain.glossary.7',
		'♭9': 'explain.glossary.b9',
		'9': 'explain.glossary.9',
		'♯9': 'explain.glossary.s9',
		'11': 'explain.glossary.11',
		'♯11': 'explain.glossary.s11',
		'13': 'explain.glossary.13',
	};

	let showGlossary = $state(false);

	// ─── Audio ─────────────────────────────────────────────────
	function listen() {
		playChord(voicingNotes.map((n) => n + '4'));
	}

	// ─── Format with basic markdown bold ───────────────────────
	function fmt(text: string): string {
		return text
			.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
			.replace(/\n/g, '<br>');
	}

	// ─── Keyboard shortcut: Escape closes ──────────────────────
	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') {
			e.preventDefault();
			onclose();
		}
	}
</script>

<svelte:window onkeydown={handleKeydown} />

<!-- Backdrop -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div
	class="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60 backdrop-blur-sm"
	onclick={(e) => { if (e.target === e.currentTarget) onclose(); }}
	onkeydown={() => {}}
>
	<!-- Panel: slides up from bottom on mobile, centered on desktop -->
	<div
		class="w-full sm:max-w-lg max-h-[85vh] overflow-y-auto rounded-t-2xl sm:rounded-2xl bg-[var(--bg-card)] border border-[var(--border)]/40 shadow-2xl"
		role="dialog"
		aria-modal="true"
		aria-label={voicingTitle}
	>
		<!-- Header -->
		<div class="sticky top-0 z-10 flex items-center justify-between px-5 py-4 border-b border-[var(--border)]/30 bg-[var(--bg-card)]">
			<div>
				<h2 class="text-lg font-bold text-[var(--text)]">{voicingTitle}</h2>
				<p class="text-xs text-[var(--text-dim)] mt-0.5">{chordData.chord}</p>
			</div>
			<button
				onclick={onclose}
				class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[var(--bg-muted)] text-[var(--text-muted)] transition-colors text-lg"
				aria-label="Close"
			>✕</button>
		</div>

		<!-- Content -->
		<div class="px-5 py-5 space-y-5">
			<!-- ① Chord quality section -->
			<div class="space-y-2">
				<div class="flex items-center gap-2">
					<span class="text-xs font-semibold text-[var(--accent-gold)] uppercase tracking-wide">{t('explain.chord_label')}</span>
					<span class="text-sm font-bold text-[var(--text)]">{qualityTitle}</span>
				</div>
				<!-- Visual formula with diff: kept tones bright, dropped tones dimmed -->
				<div class="flex items-center gap-1.5 flex-wrap">
					<span class="text-xs text-[var(--text-dim)]">{t('explain.formula_label')}</span>
					<span class="text-sm font-mono bg-[var(--bg-muted)] px-2.5 py-1 rounded-md flex items-center gap-1">
						{#each chordFormula as iv, i}
							{#if i > 0}<span class="text-[var(--text-dim)]">–</span>{/if}
							{#if droppedIntervals.includes(iv)}
								<span class="line-through opacity-40 text-[var(--text-dim)]" title={t('explain.dropped_tone')}>{iv}</span>
							{:else}
								<span class="text-[var(--text)]">{iv}</span>
							{/if}
						{/each}
					</span>
				</div>
				<p class="text-sm leading-relaxed text-[var(--text-muted)]">
					<!-- eslint-disable-next-line svelte/no-at-html-tags -->
					{@html fmt(qualityDesc)}
				</p>
			</div>

			<!-- Bridge: why the voicing drops notes -->
			{#if isReduced}
				<div class="bg-[var(--bg-muted)] rounded-lg px-4 py-3 border-l-3 border-[var(--primary)]">
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						<!-- eslint-disable-next-line svelte/no-at-html-tags -->
						{@html fmt(t('explain.bridge', { total: String(totalCount), kept: String(keptCount), dropped: droppedIntervals.join(', '), voicing: voicingTitle }))}
					</p>
				</div>
			{/if}

			<!-- Divider -->
			<div class="border-t border-[var(--border)]/20"></div>

			<!-- ② Voicing section -->
			<div class="space-y-2">
				<div class="flex items-center gap-2">
					<span class="text-xs font-semibold text-[var(--primary)] uppercase tracking-wide">{t('explain.voicing_label')}</span>
					<span class="text-sm font-bold text-[var(--text)]">{voicingTitle}</span>
				</div>
				<div class="flex items-center gap-2 flex-wrap">
					<span class="text-xs text-[var(--text-dim)]">{t('explain.plays_label')}</span>
					<span class="text-sm font-mono text-[var(--primary)] bg-[var(--primary-muted)] px-2.5 py-1 rounded-md">
						{intervalLabels.join(' – ')}
					</span>
				</div>
				<p class="text-sm leading-relaxed text-[var(--text-muted)]">
					<!-- eslint-disable-next-line svelte/no-at-html-tags -->
					{@html fmt(voicingDesc)}
				</p>
			</div>

			<!-- Keyboard visualisation -->
			<div>
				<div class="flex items-center justify-between mb-2">
					<span class="text-xs text-[var(--text-dim)]">
						{voicingNotes.join(' – ')}
						<span class="text-[var(--text-muted)] ml-1">({intervalLabels.join(' – ')})</span>
					</span>
					<button
						onclick={listen}
						class="text-xs px-2.5 py-1 rounded-md border border-[var(--border)] text-[var(--text-muted)] hover:text-[var(--text)] hover:border-[var(--border-hover)] transition-colors"
					>
						🔊 {t('explain.listen')}
					</button>
				</div>
				<PianoKeyboard
					chordData={displayData}
					showVoicing={true}
					accidentalPref="sharps"
					mini={true}
				/>
			</div>

			<!-- Beginner glossary toggle -->
			<div>
				<button
					onclick={() => showGlossary = !showGlossary}
					class="text-xs text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors flex items-center gap-1"
				>
					<span class="text-sm">{showGlossary ? '▾' : '▸'}</span>
					{t('explain.glossary_toggle')}
				</button>
				{#if showGlossary}
					<div class="mt-2 grid grid-cols-2 gap-x-4 gap-y-1 text-xs bg-[var(--bg-muted)] rounded-lg p-3">
						{#each [...new Set([...chordFormula, ...intervalLabels])] as iv}
							{#if INTERVAL_GLOSSARY[iv]}
								<div class="flex items-center gap-2">
									<span class="font-mono font-bold text-[var(--primary)] w-6 text-right">{iv}</span>
									<span class="text-[var(--text-muted)]">{t(INTERVAL_GLOSSARY[iv])}</span>
								</div>
							{/if}
						{/each}
					</div>
				{/if}
			</div>
		</div>

		<!-- Footer -->
		<div class="px-5 py-4 border-t border-[var(--border)]/30">
			<button
				onclick={onclose}
				class="w-full py-2.5 rounded-lg bg-[var(--primary)] text-[var(--primary-text)] font-medium text-sm hover:bg-[var(--primary-hover)] transition-colors"
			>
				{t('explain.close')}
			</button>
		</div>
	</div>
</div>
