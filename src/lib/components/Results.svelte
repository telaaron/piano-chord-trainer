<script lang="ts">
	import PianoKeyboard from './PianoKeyboard.svelte';
	import {
		convertChordNotation,
		formatVoicing,
		VOICING_LABELS,
		type AccidentalPreference,
		type Difficulty,
		type DisplayMode,
		type NotationStyle,
		type NotationSystem,
		type VoicingType,
	} from '$lib/engine';
	import type { ChordWithNotes } from '$lib/engine';

	interface Props {
		chordsWithNotes: ChordWithNotes[];
		totalChords: number;
		elapsedMs: number;
		difficulty: Difficulty;
		notation: NotationStyle;
		voicing: VoicingType;
		displayMode: DisplayMode;
		accidentals: AccidentalPreference;
		notationSystem: NotationSystem;
		onrestart: () => void;
		onreset: () => void;
	}

	let {
		chordsWithNotes,
		totalChords,
		elapsedMs,
		difficulty,
		notation,
		voicing,
		displayMode,
		accidentals,
		notationSystem,
		onrestart,
		onreset,
	}: Props = $props();

	function fmt(ms: number): string {
		const s = Math.floor(ms / 1000);
		const m = Math.floor(s / 60);
		const sec = s % 60;
		const cs = Math.floor((ms % 1000) / 10);
		return `${m}:${sec.toString().padStart(2, '0')}.${cs.toString().padStart(2, '0')}`;
	}
</script>

<div class="card p-6 sm:p-8 max-w-2xl mx-auto text-center space-y-6">
	<!-- Trophy -->
	<div>
		<div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-[var(--primary-muted)] mb-4">
			<svg class="w-8 h-8 text-[var(--primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
					d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
			</svg>
		</div>
		<h2 class="text-3xl font-bold">Glückwunsch!</h2>
		<p class="text-[var(--text-muted)]">Du hast alle {totalChords} Akkorde gemeistert</p>
	</div>

	<!-- Time -->
	<div class="bg-[var(--bg-muted)] rounded-[var(--radius-lg)] p-6">
		<div class="text-sm text-[var(--text-muted)] mb-1">Deine Zeit</div>
		<div class="text-5xl font-bold text-[var(--primary)]">{fmt(elapsedMs)}</div>
		<div class="text-sm text-[var(--text-muted)] mt-2">
			⌀ {(elapsedMs / totalChords / 1000).toFixed(2)}s pro Akkord
		</div>
	</div>

	<!-- Stats grid -->
	<div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
		{#each [
			{ label: 'Schwierigkeit', value: difficulty },
			{ label: 'Akkorde', value: String(totalChords) },
			{ label: 'Notation', value: notation },
			{ label: 'Vorzeichen', value: accidentals === 'sharps' ? 'Kreuze' : accidentals === 'flats' ? "B's" : 'Beide' },
			{ label: 'Voicing', value: VOICING_LABELS[voicing].split(' ')[0] },
			{ label: 'Anzeige', value: displayMode === 'off' ? 'Aus' : displayMode === 'always' ? 'Immer' : 'Überprüfen' },
		] as stat}
			<div class="bg-[var(--bg)] rounded-[var(--radius)] p-3 border border-[var(--border)]">
				<div class="text-xs text-[var(--text-muted)] mb-1">{stat.label}</div>
				<div class="font-semibold capitalize">{stat.value}</div>
			</div>
		{/each}
	</div>

	<!-- Action buttons -->
	<div class="flex gap-3">
		<button
			class="flex-1 h-11 rounded-[var(--radius)] border border-[var(--border)] text-[var(--text)] font-medium hover:bg-[var(--bg-muted)] transition-colors cursor-pointer"
			onclick={onreset}
		>
			⚙️ Einstellungen
		</button>
		<button
			class="flex-1 h-11 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] font-medium hover:bg-[var(--primary-hover)] transition-colors cursor-pointer"
			onclick={onrestart}
		>
			🔄 Nochmal
		</button>
	</div>

	<!-- Chord list with mini keyboards -->
	{#if chordsWithNotes.length > 0}
		<details class="text-left" open>
			<summary class="cursor-pointer text-sm font-semibold hover:text-[var(--primary)] mb-4">
				Alle Akkorde mit Voicings
			</summary>
			<div class="mt-4 space-y-3 max-h-[28rem] overflow-y-auto pr-1">
				{#each chordsWithNotes as cd, i}
					<div class="bg-[var(--bg)] rounded-[var(--radius)] p-4 border border-[var(--border)] hover:border-[var(--border-hover)] transition-colors">
						<div class="flex items-center gap-3 mb-3">
							<span class="text-xs bg-[var(--bg-muted)] px-2 py-0.5 rounded">{i + 1}</span>
							<span class="text-lg font-bold text-[var(--primary)]">
								{convertChordNotation(cd.chord, notationSystem)}
							</span>
						</div>

						<!-- Mini keyboard -->
						<div class="mb-3">
							<PianoKeyboard chordData={cd} accidentalPref={accidentals} showVoicing={true} mini={true} />
						</div>

						<!-- All 4 voicings -->
						<div class="grid grid-cols-2 gap-2 text-xs">
							{#each (['root', 'shell', 'half-shell', 'full'] as const) as v}
								<div class="bg-[var(--bg-muted)] p-2 rounded-[var(--radius-sm)]">
									<div class="text-[var(--text-dim)] mb-0.5">{VOICING_LABELS[v]}</div>
									<div class="font-mono font-semibold">{formatVoicing(cd, v, notationSystem)}</div>
								</div>
							{/each}
						</div>
					</div>
				{/each}
			</div>
		</details>
	{/if}
</div>
