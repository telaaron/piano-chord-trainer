<script lang="ts">
	import { fade } from 'svelte/transition';
	import {
		parseProgression,
		formatProgression,
		PROGRESSION_PRESETS,
		loadCustomProgressions,
		saveCustomProgression,
		deleteCustomProgression,
		type CustomProgression,
		type CustomChord,
		type ProgressionPreset,
	} from '$lib/engine';

	interface Props {
		/** Called when the user starts playing a progression */
		onplay: (chords: CustomChord[], bpm: number, loops: number, name: string) => void;
		/** Called when user wants to go back */
		onback: () => void;
	}

	let { onplay, onback }: Props = $props();

	// ── State ──
	let rawInput = $state('');
	let bpm = $state(120);
	let loops = $state(2);
	let progressionName = $state('');
	let parsedChords: CustomChord[] = $state([]);
	let parseError = $state('');
	let savedProgressions: CustomProgression[] = $state([]);
	let showPresets = $state(false);

	// Live-parse as user types
	$effect(() => {
		const result = parseProgression(rawInput);
		if (rawInput.trim() && result.length === 0) {
			parseError = 'No valid chords recognized. Use e.g. "Dm7 | G7 | CMaj7"';
			parsedChords = [];
		} else {
			parseError = '';
			parsedChords = result;
		}
	});

	function loadSaved() {
		savedProgressions = loadCustomProgressions();
	}

	// Load saved on mount
	$effect(() => {
		loadSaved();
	});

	function handlePlay() {
		if (parsedChords.length === 0) return;
		onplay(parsedChords, bpm, loops, progressionName || 'Custom');
	}

	function handleSave() {
		if (parsedChords.length === 0) return;
		saveCustomProgression({
			name: progressionName || `Progression ${savedProgressions.length + 1}`,
			raw: rawInput,
			chords: parsedChords,
			bpm,
			loops,
		});
		loadSaved();
	}

	function handleDelete(id: string) {
		deleteCustomProgression(id);
		loadSaved();
	}

	function loadProgression(prog: CustomProgression) {
		rawInput = prog.raw;
		bpm = prog.bpm;
		loops = prog.loops;
		progressionName = prog.name;
	}

	function loadPreset(preset: ProgressionPreset) {
		rawInput = preset.raw;
		bpm = preset.bpm;
		progressionName = preset.name;
		showPresets = false;
	}

	/** Total beats in one pass */
	const totalBeats = $derived(parsedChords.reduce((s, c) => s + c.beats, 0));
	/** Duration of one pass in seconds */
	const passDuration = $derived(totalBeats > 0 ? (totalBeats / bpm) * 60 : 0);
</script>

<div class="max-w-2xl mx-auto space-y-6">
	<!-- Header -->
	<div class="flex items-center gap-3">
		<button
			class="p-2 rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)] transition-colors cursor-pointer"
			onclick={onback}
			title="Back"
		>
			←
		</button>
		<div>
			<h2 class="text-2xl font-bold">Custom Progression</h2>
			<p class="text-sm text-[var(--text-muted)]">Practice your own chord sequence with metronome</p>
		</div>
	</div>

	<!-- Preset Quick-Load -->
	<div>
		<button
			class="text-sm text-[var(--primary)] hover:underline cursor-pointer"
			onclick={() => (showPresets = !showPresets)}
		>
			{showPresets ? '▾ Hide templates' : '▸ Load jazz standard templates'}
		</button>

		{#if showPresets}
			<div class="grid grid-cols-2 gap-2 mt-3" in:fade={{ duration: 150 }}>
				{#each PROGRESSION_PRESETS as preset}
					<button
						class="card p-3 text-left cursor-pointer hover:border-[var(--border-hover)] transition-colors group"
						onclick={() => loadPreset(preset)}
					>
						<div class="font-semibold text-sm group-hover:text-[var(--primary)] transition-colors">{preset.name}</div>
						<div class="flex gap-2 mt-1">
							<span class="text-xs bg-[var(--bg-muted)] px-1.5 py-0.5 rounded-full text-[var(--text-dim)]">{preset.tag}</span>
							<span class="text-xs text-[var(--text-dim)]">{preset.bpm} BPM</span>
						</div>
					</button>
				{/each}
			</div>
		{/if}
	</div>

	<!-- Input area -->
	<div class="card p-5 space-y-4">
		<div>
			<label class="text-sm font-medium block mb-1" for="prog-name">Name <span class="text-[var(--text-dim)] font-normal">(optional)</span></label>
			<input
				id="prog-name"
				type="text"
				bind:value={progressionName}
				placeholder="Autumn Leaves A"
				class="w-full px-3 py-2 rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg)] text-[var(--text)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] text-sm"
			/>
		</div>

		<div>
			<label class="text-sm font-medium block mb-1" for="prog-input">Chords <span class="text-[var(--text-dim)] font-normal text-xs">— separate with | or space</span></label>
			<p class="text-xs text-[var(--text-dim)] mb-2">
				Example: <code class="bg-[var(--bg-muted)] px-1.5 py-0.5 rounded">Dm7 | G7 | CMaj7</code>
				<span class="hidden sm:inline"><br />Beats: <code class="bg-[var(--bg-muted)] px-1.5 py-0.5 rounded">Dm7(2)</code> — default 4</span>
			</p>
			<textarea
				id="prog-input"
				bind:value={rawInput}
				placeholder="Dm7 | G7 | CMaj7 | CMaj7"
				rows="3"
				class="w-full px-3 py-2 rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg)] text-[var(--text)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] font-mono text-sm resize-none"
			></textarea>

			{#if parseError}
				<p class="text-xs text-[var(--accent-red)] mt-1">{parseError}</p>
			{/if}
		</div>

		<!-- Live Preview -->
		{#if parsedChords.length > 0}
			<div class="bg-[var(--bg-muted)] rounded-[var(--radius)] p-3 space-y-2" in:fade={{ duration: 100 }}>
				<div class="text-xs font-medium text-[var(--text-muted)]">Preview ({parsedChords.length} chords · {totalBeats} beats · ~{Math.round(passDuration)}s per pass)</div>
				<div class="flex flex-wrap gap-2">
					{#each parsedChords as chord, i}
						<div class="bg-[var(--bg)] px-2.5 py-1.5 rounded-[var(--radius-sm)] border border-[var(--border)] text-sm font-mono">
							{chord.display}
							{#if chord.beats !== 4}
								<span class="text-xs text-[var(--text-dim)] ml-1">({chord.beats})</span>
							{/if}
						</div>
						{#if i < parsedChords.length - 1}
							<span class="text-[var(--text-dim)] self-center">→</span>
						{/if}
					{/each}
				</div>
			</div>
		{/if}

		<!-- BPM + Loops -->
		<div class="space-y-4">
			<div>
				<div class="flex items-center justify-between mb-2">
					<label class="text-sm font-medium" for="prog-bpm">Tempo</label>
					<span class="font-mono text-sm text-[var(--primary)]">{bpm} BPM</span>
				</div>
				<input
					id="prog-bpm"
					type="range"
					min="40"
					max="240"
					step="5"
					bind:value={bpm}
					class="w-full accent-[var(--primary)]"
				/>
			</div>
			<div>
				<label class="text-sm font-medium block mb-2">Loops</label>
				<div class="flex gap-2">
					{#each [1, 2, 3, 4, 0] as l}
						<button
							class="flex-1 py-2 rounded-[var(--radius-sm)] border-2 text-sm font-semibold transition-all cursor-pointer {loops === l ? 'border-[var(--primary)] bg-[var(--primary-muted)] text-[var(--primary)]' : 'border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)]'}"
							onclick={() => (loops = l)}
						>
							{l === 0 ? '∞' : `${l}×`}
						</button>
					{/each}
				</div>
			</div>
		</div>

		<!-- Action row -->
		<div class="flex gap-3 pt-2">
			<button
				class="flex-1 h-12 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] text-base font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
				onclick={handlePlay}
				disabled={parsedChords.length === 0}
			>
				▶ Play
			</button>
			<button
				class="h-12 px-5 rounded-[var(--radius)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
				onclick={handleSave}
				disabled={parsedChords.length === 0}
				title="Save progression"
			>
				💾 Save
			</button>
		</div>
	</div>

	<!-- Saved Progressions -->
	{#if savedProgressions.length > 0}
		<div>
			<h3 class="text-sm font-medium text-[var(--text-muted)] mb-3">Saved Progressions</h3>
			<div class="space-y-2">
				{#each savedProgressions as prog}
					<div class="card p-4 flex items-center gap-3 group">
						<button
							class="flex-1 text-left cursor-pointer"
							onclick={() => loadProgression(prog)}
						>
							<div class="font-semibold text-sm group-hover:text-[var(--primary)] transition-colors">{prog.name}</div>
							<div class="text-xs text-[var(--text-dim)] font-mono mt-1 truncate">{prog.raw}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{prog.bpm} BPM · {prog.loops === 0 ? '∞' : `${prog.loops}×`} · {prog.chords.length} chords</div>
						</button>
						<button
							class="flex-1 max-w-[80px] text-center px-3 py-2 rounded-[var(--radius-sm)] bg-[var(--primary)] text-[var(--primary-text)] text-xs font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer"
							onclick={() => onplay(prog.chords, prog.bpm, prog.loops, prog.name)}
						>
							▶ Go
						</button>
						<button
							class="p-2 text-[var(--text-dim)] hover:text-[var(--accent-red)] transition-colors cursor-pointer"
							onclick={() => handleDelete(prog.id)}
							title="Delete"
						>
							🗑
						</button>
					</div>
				{/each}
			</div>
		</div>
	{/if}
</div>
