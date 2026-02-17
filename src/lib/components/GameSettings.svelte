<script lang="ts">
	import {
		CHORDS_BY_DIFFICULTY,
		VOICING_LABELS,
		PROGRESSION_LABELS,
		PROGRESSION_DESCRIPTIONS,
		PRACTICE_PLANS,
		suggestPlan,
		type Difficulty,
		type NotationStyle,
		type VoicingType,
		type DisplayMode,
		type AccidentalPreference,
		type NotationSystem,
		type ProgressionMode,
		type PracticePlan,
	} from '$lib/engine';
	import { loadRecentPlanIds, type StreakData } from '$lib/services/progress';
	import type { MidiConnectionState, MidiDevice } from '$lib/services/midi';
	import { onMount } from 'svelte';

	interface Props {
		difficulty: Difficulty;
		notation: NotationStyle;
		voicing: VoicingType;
		displayMode: DisplayMode;
		accidentals: AccidentalPreference;
		notationSystem: NotationSystem;
		totalChords: number;
		progressionMode: ProgressionMode;
		midiEnabled: boolean;
		streak: StreakData;
		midiState: MidiConnectionState;
		midiDevices: MidiDevice[];
		onstart: () => void;
		onstartplan: (plan: PracticePlan) => void;
		oncustomprogression: () => void;
	}

	let {
		difficulty = $bindable(),
		notation = $bindable(),
		voicing = $bindable(),
		displayMode = $bindable(),
		accidentals = $bindable(),
		notationSystem = $bindable(),
		totalChords = $bindable(),
		progressionMode = $bindable(),
		midiEnabled = $bindable(),
		streak,
		midiState,
		midiDevices,
		onstart,
		onstartplan,
		oncustomprogression,
	}: Props = $props();

	let suggested: PracticePlan = $state(PRACTICE_PLANS[0]);

	onMount(() => {
		const recent = loadRecentPlanIds();
		// We need totalSessions but don't have it as prop — use recent length as proxy
		suggested = suggestPlan(recent, recent.length);
	});

	/** Helper: quick 2-col option grid item */
	function sel<T>(current: T, value: T): string {
		return current === value
			? 'border-[var(--primary)] bg-[var(--primary-muted)]'
			: 'border-[var(--border)] hover:border-[var(--border-hover)]';
	}

	function greetingText(): string {
		const h = new Date().getHours();
		if (h < 12) return 'Guten Morgen';
		if (h < 18) return 'Guten Tag';
		return 'Guten Abend';
	}
</script>

<div class="max-w-2xl mx-auto space-y-6">
	<!-- Greeting + Streak -->
	<div class="text-center space-y-2">
		<h2 class="text-3xl font-bold">
			{greetingText()}!
			{#if streak.current > 0}
				<span class="ml-2" title="{streak.current} Tage in Folge">🔥 {streak.current}</span>
			{/if}
		</h2>
		{#if streak.current >= 3}
			<p class="text-sm text-[var(--accent-amber)]">
				{streak.current} Tage in Folge — weiter so!
				{#if streak.best > streak.current}
					<span class="text-[var(--text-dim)]">· Rekord: {streak.best}</span>
				{/if}
			</p>
		{:else if streak.current === 0 && streak.best > 0}
			<p class="text-sm text-[var(--text-muted)]">Starte einen neuen Streak!</p>
		{/if}
	</div>

	<!-- ── MIDI Auto-Detection Banner ── -->
	{#if midiState === 'connected' && midiDevices.length > 0}
		<div class="card p-4 border-[var(--accent-green)]/40 bg-[var(--accent-green)]/5">
			<div class="flex items-center gap-3">
				<div class="text-2xl">🎹</div>
				<div class="flex-1 min-w-0">
					<div class="font-semibold text-sm text-[var(--accent-green)]">
						{midiDevices[0].name} erkannt
					</div>
					<div class="text-xs text-[var(--text-muted)] mt-0.5">
						MIDI ist aktiv — spiele Akkorde direkt auf deinem Klavier
					</div>
				</div>
				<div class="w-2 h-2 rounded-full bg-[var(--accent-green)] animate-pulse"></div>
			</div>
		</div>
	{:else if midiState === 'connected' && midiDevices.length === 0}
		<div class="card p-4 border-[var(--border)]">
			<div class="flex items-center gap-3">
				<div class="text-2xl opacity-50">🎹</div>
				<div class="flex-1 min-w-0">
					<div class="text-sm text-[var(--text-muted)]">Kein MIDI-Gerät gefunden</div>
					<div class="text-xs text-[var(--text-dim)] mt-0.5">
						Schließe ein Klavier per USB an — es wird automatisch erkannt
					</div>
				</div>
			</div>
		</div>
	{:else if midiState === 'unsupported'}
		<!-- Don't show anything — browser doesn't support MIDI -->
	{:else if midiState === 'disconnected'}
		<div class="card p-4 border-[var(--border)]">
			<div class="flex items-center gap-3">
				<div class="text-2xl opacity-50">🎹</div>
				<div class="flex-1 min-w-0">
					<div class="text-sm text-[var(--text-muted)]">MIDI-Klavier anschließen?</div>
					<div class="text-xs text-[var(--text-dim)] mt-0.5">
						Verbinde ein USB-Klavier für automatische Akkord-Erkennung (Chrome/Edge)
					</div>
				</div>
			</div>
		</div>
	{/if}

	<!-- ── Empfohlen ── -->
	<button
		class="card w-full p-5 sm:p-6 text-left cursor-pointer hover:border-[var(--border-hover)] transition-colors group"
		onclick={() => onstartplan(suggested)}
	>
		<div class="flex items-start gap-4">
			<div class="text-3xl">{suggested.icon}</div>
			<div class="flex-1 min-w-0">
				<div class="text-xs text-[var(--text-dim)] font-medium mb-1">Empfohlen</div>
				<div class="text-xl font-bold group-hover:text-[var(--primary)] transition-colors">{suggested.name}</div>
				<div class="text-sm text-[var(--text-muted)] mt-1">{suggested.tagline}</div>
				<p class="text-xs text-[var(--text-dim)] mt-2">{suggested.description}</p>
			</div>
			<div class="text-[var(--primary)] text-2xl opacity-60 group-hover:opacity-100 transition-opacity self-center">▶</div>
		</div>
	</button>

	<!-- ── Übungspläne Grid ── -->
	<div>
		<h3 class="text-sm font-medium text-[var(--text-muted)] mb-3">Übungspläne</h3>
		<div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
			{#each PRACTICE_PLANS.filter((p) => p.id !== suggested.id) as plan}
				<button
					class="card p-4 text-left cursor-pointer hover:border-[var(--border-hover)] transition-all group"
					onclick={() => onstartplan(plan)}
				>
					<div class="text-2xl mb-2">{plan.icon}</div>
					<div class="font-semibold text-sm group-hover:text-[var(--primary)] transition-colors">{plan.name}</div>
					<div class="text-xs text-[var(--text-dim)] mt-1 line-clamp-2">{plan.tagline}</div>
				</button>
			{/each}
		</div>
	</div>

	<!-- ── Custom Progression ── -->
	<button
		class="card w-full p-5 text-left cursor-pointer hover:border-[var(--border-hover)] transition-colors group"
		onclick={oncustomprogression}
	>
		<div class="flex items-center gap-4">
			<div class="text-3xl">🎼</div>
			<div class="flex-1 min-w-0">
				<div class="text-sm font-bold group-hover:text-[var(--primary)] transition-colors">Custom Progression</div>
				<div class="text-xs text-[var(--text-dim)] mt-1">Eigene Akkord-Folge eingeben, mit Metronom üben, Auswertung bekommen. Jazz-Standards als Vorlage verfügbar.</div>
			</div>
			<div class="text-[var(--text-dim)] text-xl group-hover:text-[var(--primary)] transition-colors">→</div>
		</div>
	</button>

	<!-- ── Eigene Übung ── -->
	<details class="card group">
		<summary class="cursor-pointer p-5 sm:p-6 flex items-center justify-between">
			<div>
				<div class="text-sm font-medium">⚙️ Eigene Übung konfigurieren</div>
				<div class="text-xs text-[var(--text-dim)] mt-1 flex flex-wrap gap-2">
					<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full">
						{progressionMode === 'random' ? `${totalChords} Akkorde` : PROGRESSION_LABELS[progressionMode]}
					</span>
					<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full capitalize">{difficulty}</span>
					<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full">{VOICING_LABELS[voicing]}</span>
					{#if midiEnabled}
						<span class="bg-[var(--accent-green)]/20 text-[var(--accent-green)] px-2 py-0.5 rounded-full">MIDI</span>
					{/if}
				</div>
			</div>
			<svg class="w-5 h-5 text-[var(--text-dim)] transition-transform group-open:rotate-180" fill="none" viewBox="0 0 24 24" stroke="currentColor">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
			</svg>
		</summary>

		<div class="px-5 sm:px-6 pb-5 sm:pb-6 pt-0 border-t border-[var(--border)] space-y-6">
			<!-- Start custom -->
			<button
				class="w-full h-12 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] text-base font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer mt-4"
				onclick={onstart}
			>
				▶ Mit diesen Einstellungen starten
			</button>
			<!-- Übungsmodus -->
			<fieldset>
				<legend class="text-sm font-medium mb-1">Übungsmodus</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Wie die Akkorde aufeinander folgen. Progressionen (ii-V-I etc.) trainieren reale Jazz-Abfolgen.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: 'random' as ProgressionMode, label: 'Zufällig', sub: 'Zufällige Akkorde ohne Zusammenhang' },
						{ val: '2-5-1' as ProgressionMode, label: 'ii – V – I', sub: 'Die Jazz-Standardprogression, z.B. Dm7 → G7 → CMaj7' },
						{ val: 'cycle-of-4ths' as ProgressionMode, label: 'Quartenzirkel', sub: 'Durch alle 12 Tonarten im Quartabstand' },
						{ val: '1-6-2-5' as ProgressionMode, label: 'I – vi – ii – V', sub: 'Turnaround: die Akkordfolge hinter tausenden Songs' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(progressionMode, opt.val)}"
							onclick={() => (progressionMode = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
			</fieldset>

			<!-- MIDI Toggle -->
			<fieldset>
				<legend class="text-sm font-medium mb-1">MIDI-Erkennung</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Wenn an: Die App hört, was du spielst, und geht automatisch weiter bei richtigem Akkord.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: false, label: 'Aus', sub: 'Leertaste zum Weiter' },
						{ val: true, label: 'An', sub: 'Auto-Weiter bei richtigem Akkord' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(midiEnabled, opt.val)}"
							onclick={() => (midiEnabled = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
				<p class="mt-2 text-xs text-[var(--text-dim)]">
					Web MIDI benötigt Desktop-Browser (Chrome/Edge). Auf iPad/iPhone nicht verfügbar.
				</p>
			</fieldset>

			<!-- Difficulty -->
			<fieldset>
				<legend class="text-sm font-medium mb-1">Schwierigkeitsgrad</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Welche Akkord-Typen vorkommen. Anfänger = Standard-Jazz. Profi = erweiterte Voicings.</p>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'beginner' as Difficulty, label: 'Anfänger', sub: 'Maj7, 7, m7, 6, m6' },
						{ val: 'intermediate' as Difficulty, label: 'Mittel', sub: '+ 9th, 6/9, dim' },
						{ val: 'advanced' as Difficulty, label: 'Profi', sub: '+ 11th, 13th, Alt, ø' },
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
				<legend class="text-sm font-medium mb-1">Vorzeichen</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Ob schwarze Tasten als # (Kreuz) oder ♭ (B) benannt werden. Jazz nutzt meist ♭.</p>
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
				<legend class="text-sm font-medium mb-1">Notationssystem</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">International: B = die Note unter C. Deutsch: H = die Note unter C, B = Bb.</p>
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
				<legend class="text-sm font-medium mb-1">Akkord-Schreibweise</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Wie Akkord-Typen geschrieben werden. Standard = ausgeschrieben, Symbole = Δ, -, ø etc.</p>
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
				<legend class="text-sm font-medium mb-1">Voicing-Art</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Bestimmt, welche Töne eines Akkords du spielst. Shell = nur die wichtigsten 2-3 Töne (wie Jazz-Pianisten in Combos). Full = alle Töne.</p>

				<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">Grundlagen</div>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: 'root' as VoicingType, label: 'Root Position', sub: 'Grundton + alle Töne von unten. Der "Lehrbuch"-Griff.' },
						{ val: 'shell' as VoicingType, label: 'Shell Voicing', sub: 'Nur Grundton + Terz + Septime. Basis für Jazz-Comping.' },
						{ val: 'half-shell' as VoicingType, label: 'Half Shell', sub: 'Terz/Septime liegen um den Grundton. Typisch linke Hand.' },
						{ val: 'full' as VoicingType, label: 'Full Voicing', sub: 'Alle Töne in Jazz-typischer Reihenfolge: 1-7-3-5.' },
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

				<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">🎹 Left-Hand Voicings <span class="text-[var(--text-dim)] font-normal">(ohne Grundton — Bassist spielt den Bass)</span></div>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: 'rootless-a' as VoicingType, label: 'Rootless A', sub: '3 – 5 – 7 – 9 · Bill Evans-Stil. Die wichtigste Comping-Voicing für die linke Hand.' },
						{ val: 'rootless-b' as VoicingType, label: 'Rootless B', sub: '7 – 9 – 3 – 5 · Ergänzung zu Type A. Gleicher Akkord, andere Lage.' },
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

				<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">🔄 Umkehrungen <span class="text-[var(--text-dim)] font-normal">(gleicher Akkord, anderer Ton unten)</span></div>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'inversion-1' as VoicingType, label: '1. Umkehrung', sub: 'Terz liegt unten. Weichere Farbe.' },
						{ val: 'inversion-2' as VoicingType, label: '2. Umkehrung', sub: 'Quinte liegt unten. Offener Klang.' },
						{ val: 'inversion-3' as VoicingType, label: '3. Umkehrung', sub: 'Septime liegt unten. Nur bei 4+ Tönen.' },
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
				<legend class="text-sm font-medium mb-1">Noten-Anzeige</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Ob die einzelnen Töne des Akkords auf der Klaviatur angezeigt werden.</p>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'off' as DisplayMode, label: 'Aus', sub: 'Blind spielen — keine Hilfe' },
						{ val: 'always' as DisplayMode, label: 'Immer', sub: 'Töne direkt sichtbar auf der Tastatur' },
						{ val: 'verify' as DisplayMode, label: 'Prüfen', sub: 'Erst spielen, dann aufdecken' },
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

			<!-- Chord count (only for random mode) -->
			{#if progressionMode === 'random'}
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
			{:else}
				<div class="p-3 bg-[var(--bg)] rounded-[var(--radius)] border border-[var(--border)] text-sm text-[var(--text-muted)]">
					{PROGRESSION_DESCRIPTIONS[progressionMode]}
				</div>
			{/if}
		</div>
	</details>
</div>
