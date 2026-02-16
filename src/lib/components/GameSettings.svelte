<script lang="ts">
	import {
		CHORDS_BY_DIFFICULTY,
		VOICING_LABELS,
		type Difficulty,
		type NotationStyle,
		type VoicingType,
		type DisplayMode,
		type AccidentalPreference,
		type NotationSystem,
	} from '$lib/engine';

	interface Props {
		difficulty: Difficulty;
		notation: NotationStyle;
		voicing: VoicingType;
		displayMode: DisplayMode;
		accidentals: AccidentalPreference;
		notationSystem: NotationSystem;
		totalChords: number;
		onstart: () => void;
	}

	let {
		difficulty = $bindable(),
		notation = $bindable(),
		voicing = $bindable(),
		displayMode = $bindable(),
		accidentals = $bindable(),
		notationSystem = $bindable(),
		totalChords = $bindable(),
		onstart,
	}: Props = $props();

	/** Helper: quick 2-col option grid item */
	function sel<T>(current: T, value: T): string {
		return current === value
			? 'border-[var(--primary)] bg-[var(--primary-muted)]'
			: 'border-[var(--border)] hover:border-[var(--border-hover)]';
	}
</script>

<div class="card p-6 sm:p-8 max-w-2xl mx-auto space-y-8">
	<!-- Quick start -->
	<div class="text-center space-y-4">
		<h2 class="text-3xl font-bold">Bereit zum Üben?</h2>
		<p class="text-[var(--text-muted)]">
			{totalChords} zufällige Akkorde spielen und deine Zeit tracken.
		</p>

		<!-- Current settings tags -->
		<div class="flex flex-wrap gap-2 justify-center text-sm">
			<span class="bg-[var(--bg-muted)] px-3 py-1 rounded-full">{totalChords} Akkorde</span>
			<span class="bg-[var(--bg-muted)] px-3 py-1 rounded-full capitalize">{difficulty}</span>
			<span class="bg-[var(--bg-muted)] px-3 py-1 rounded-full">{VOICING_LABELS[voicing]}</span>
			<span class="bg-[var(--bg-muted)] px-3 py-1 rounded-full">
				{displayMode === 'off' ? 'Noten: Aus' : displayMode === 'always' ? 'Noten: Immer' : 'Noten: Überprüfen'}
			</span>
		</div>

		<!-- Start button -->
		<button
			class="w-full h-14 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] text-lg font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer"
			onclick={onstart}
		>
			▶ Jetzt spielen!
		</button>
	</div>

	<!-- Collapsible settings -->
	<details class="group">
		<summary class="cursor-pointer text-sm font-medium text-[var(--text-muted)] hover:text-[var(--text)] flex items-center gap-2">
			⚙️ Einstellungen anpassen
		</summary>

		<div class="mt-6 pt-6 border-t border-[var(--border)] space-y-6">
			<!-- Difficulty -->
			<fieldset>
				<legend class="text-sm font-medium mb-3">Schwierigkeitsgrad</legend>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'beginner' as Difficulty, label: 'Anfänger', sub: 'Maj7, 7, m7, 6, m6' },
						{ val: 'intermediate' as Difficulty, label: 'Fortgeschritten', sub: '+ 9th, 6/9' },
						{ val: 'advanced' as Difficulty, label: 'Profi', sub: '+ 11th, 13th, Alt.' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(difficulty, opt.val)}"
							onclick={() => (difficulty = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
			</fieldset>

			<!-- Accidentals -->
			<fieldset>
				<legend class="text-sm font-medium mb-3">Vorzeichen</legend>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'sharps' as AccidentalPreference, label: 'Kreuze (#)', sub: 'C#, D#, F#, G#, A#' },
						{ val: 'flats' as AccidentalPreference, label: "B's (♭)", sub: 'Db, Eb, Gb, Ab, Bb' },
						{ val: 'both' as AccidentalPreference, label: 'Beide', sub: '# und ♭ gemischt' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(accidentals, opt.val)}"
							onclick={() => (accidentals = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
			</fieldset>

			<!-- Notation system -->
			<fieldset>
				<legend class="text-sm font-medium mb-3">Notationssystem</legend>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: 'international' as NotationSystem, label: 'International', sub: 'C D E F G A B' },
						{ val: 'german' as NotationSystem, label: 'Deutsch', sub: 'C D E F G A H (B=♭)' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(notationSystem, opt.val)}"
							onclick={() => (notationSystem = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
			</fieldset>

			<!-- Chord notation style -->
			<fieldset>
				<legend class="text-sm font-medium mb-3">Akkord-Schreibweise</legend>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'standard' as NotationStyle, label: 'Standard', sub: 'CMaj7, Cm7' },
						{ val: 'symbols' as NotationStyle, label: 'Symbole', sub: 'CΔ7, C-7, Cø7' },
						{ val: 'short' as NotationStyle, label: 'Kurz', sub: 'CM7, Cmi7' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(notation, opt.val)}"
							onclick={() => (notation = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
			</fieldset>

			<!-- Voicing type -->
			<fieldset>
				<legend class="text-sm font-medium mb-3">Voicing</legend>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: 'root' as VoicingType, label: 'Root Position', sub: 'C – E – G – B' },
						{ val: 'shell' as VoicingType, label: 'Shell Voicing', sub: 'C – E – B' },
						{ val: 'half-shell' as VoicingType, label: 'Half Shell', sub: 'E – C – B' },
						{ val: 'full' as VoicingType, label: 'Full Voicing', sub: 'C – B – E – G' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voicing, opt.val)}"
							onclick={() => (voicing = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
			</fieldset>

			<!-- Display mode -->
			<fieldset>
				<legend class="text-sm font-medium mb-3">Noten-Anzeige</legend>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'off' as DisplayMode, label: 'Aus', sub: 'Keine Töne' },
						{ val: 'always' as DisplayMode, label: 'Immer', sub: 'Immer sichtbar' },
						{ val: 'verify' as DisplayMode, label: 'Überprüfen', sub: 'Nach dem Spielen' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(displayMode, opt.val)}"
							onclick={() => (displayMode = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
			</fieldset>

			<!-- Chord count -->
			<fieldset>
				<legend class="text-sm font-medium mb-3">Anzahl Akkorde</legend>
				<input
					type="number"
					min="5"
					max="50"
					bind:value={totalChords}
					class="w-full px-4 py-2 rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg)] text-[var(--text)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
				/>
			</fieldset>
		</div>
	</details>

	<!-- Quick instruction -->
	<div class="p-4 bg-[var(--bg-muted)] rounded-[var(--radius)] text-center">
		<p class="text-sm text-[var(--text-muted)]">
			Spiele die Akkorde und drücke <strong class="text-[var(--text)]">Leertaste</strong> oder tippe zum Fortfahren
		</p>
	</div>
</div>
