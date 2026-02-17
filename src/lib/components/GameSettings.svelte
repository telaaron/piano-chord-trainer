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
		if (h < 12) return 'Good morning';
		if (h < 18) return 'Good afternoon';
		return 'Good evening';
	}
</script>

<div class="max-w-2xl mx-auto space-y-6">
	<!-- Greeting + Streak -->
	<div class="text-center space-y-2">
		<h2 class="text-3xl font-bold">
			{greetingText()}!
			{#if streak.current > 0}
				<span class="ml-2" title="{streak.current} day streak">🔥 {streak.current}</span>
			{/if}
		</h2>
		{#if streak.current >= 3}
			<p class="text-sm text-[var(--accent-amber)]">
				{streak.current} days in a row — keep going!
				{#if streak.best > streak.current}
					<span class="text-[var(--text-dim)]">· Record: {streak.best}</span>
				{/if}
			</p>
		{:else if streak.current === 0 && streak.best > 0}
			<p class="text-sm text-[var(--text-muted)]">Start a new streak!</p>
		{/if}
	</div>

	<!-- ── MIDI Auto-Detection Banner ── -->
	{#if midiState === 'connected' && midiDevices.length > 0}
		<div class="card p-4 border-[var(--accent-green)]/40 bg-[var(--accent-green)]/5">
			<div class="flex items-center gap-3">
				<div class="text-2xl">🎹</div>
				<div class="flex-1 min-w-0">
					<div class="font-semibold text-sm text-[var(--accent-green)]">
						{midiDevices[0].name} detected
					</div>
					<div class="text-xs text-[var(--text-muted)] mt-0.5">
						MIDI active — play chords directly on your piano
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
					<div class="text-sm text-[var(--text-muted)]">No MIDI device found</div>
					<div class="text-xs text-[var(--text-dim)] mt-0.5">
						Connect a keyboard via USB — it will be detected automatically
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
					<div class="text-sm text-[var(--text-muted)]">Connect a MIDI keyboard?</div>
					<div class="text-xs text-[var(--text-dim)] mt-0.5">
						Plug in a USB keyboard for auto chord recognition (Chrome/Edge)
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
				<div class="text-xs text-[var(--text-dim)] font-medium mb-1">Recommended</div>
				<div class="text-xl font-bold group-hover:text-[var(--primary)] transition-colors">{suggested.name}</div>
				<div class="text-sm text-[var(--text-muted)] mt-1">{suggested.tagline}</div>
				<p class="text-xs text-[var(--text-dim)] mt-2">{suggested.description}</p>
			</div>
			<div class="text-[var(--primary)] text-2xl opacity-60 group-hover:opacity-100 transition-opacity self-center">▶</div>
		</div>
	</button>

		<!-- ── Practice Plans Grid ── -->
	<div>
		<h3 class="text-sm font-medium text-[var(--text-muted)] mb-3">Practice Plans</h3>
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
				<div class="text-xs text-[var(--text-dim)] mt-1">Enter your own chord sequence, practice with metronome, get results. Jazz standards available as templates.</div>
			</div>
			<div class="text-[var(--text-dim)] text-xl group-hover:text-[var(--primary)] transition-colors">→</div>
		</div>
	</button>

		<!-- ── Custom Practice ── -->
	<details class="card group">
		<summary class="cursor-pointer p-5 sm:p-6 flex items-center justify-between">
			<div>
				<div class="text-sm font-medium">⚙️ Custom Settings</div>
				<div class="text-xs text-[var(--text-dim)] mt-1 flex flex-wrap gap-2">
					<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full">
						{progressionMode === 'random' ? `${totalChords} chords` : PROGRESSION_LABELS[progressionMode]}
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
				▶ Start with these settings
			</button>
			<!-- Practice mode -->
			<fieldset>
				<legend class="text-sm font-medium mb-1">Practice Mode</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">How chords are sequenced. Progressions train real jazz patterns.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: 'random' as ProgressionMode, label: 'Random', sub: 'Random chords, no pattern' },
						{ val: '2-5-1' as ProgressionMode, label: 'ii – V – I', sub: 'The jazz standard progression, e.g. Dm7 → G7 → CMaj7' },
						{ val: 'cycle-of-4ths' as ProgressionMode, label: 'Circle of 4ths', sub: 'Through all 12 keys by fourths' },
						{ val: '1-6-2-5' as ProgressionMode, label: 'I – vi – ii – V', sub: 'Turnaround: the progression behind thousands of songs' },
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
				<legend class="text-sm font-medium mb-1">MIDI Recognition</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">When on: the app listens to what you play and auto-advances on correct chord.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: false, label: 'Off', sub: 'Press Space to advance' },
						{ val: true, label: 'On', sub: 'Auto-advance on correct chord' },
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
					Web MIDI requires a desktop browser (Chrome/Edge). Not available on iPad/iPhone.
				</p>
			</fieldset>

			<!-- Difficulty -->
			<fieldset>
				<legend class="text-sm font-medium mb-1">Difficulty</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Which chord types appear. Beginner = standard jazz. Advanced = extended voicings.</p>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'beginner' as Difficulty, label: 'Beginner', sub: 'Maj7, 7, m7, 6, m6' },
						{ val: 'intermediate' as Difficulty, label: 'Intermediate', sub: '+ 9th, 6/9, dim' },
						{ val: 'advanced' as Difficulty, label: 'Advanced', sub: '+ 11th, 13th, Alt, ø' },
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
				<legend class="text-sm font-medium mb-1">Accidentals</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Whether black keys use # (sharp) or ♭ (flat). Jazz typically uses flats.</p>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'sharps' as AccidentalPreference, label: 'Sharps (#)', sub: 'C#, D#, F#, G#, A#' },
						{ val: 'flats' as AccidentalPreference, label: 'Flats (♭)', sub: 'Db, Eb, Gb, Ab, Bb' },
						{ val: 'both' as AccidentalPreference, label: 'Both', sub: '# and ♭ mixed' },
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
				<legend class="text-sm font-medium mb-1">Notation System</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">International: B = the note below C. German: H = the note below C, B = Bb.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: 'international' as NotationSystem, label: 'International', sub: 'C D E F G A B' },
						{ val: 'german' as NotationSystem, label: 'German', sub: 'C D E F G A H (B=♭)' },
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
				<legend class="text-sm font-medium mb-1">Chord Notation</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">How chord types are written. Standard = spelled out, Symbols = Δ, -, ø etc.</p>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'standard' as NotationStyle, label: 'Standard', sub: 'CMaj7, Cm7' },
						{ val: 'symbols' as NotationStyle, label: 'Symbols', sub: 'CΔ7, C-7, Cø7' },
						{ val: 'short' as NotationStyle, label: 'Short', sub: 'CM7, Cmi7' },
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
				<legend class="text-sm font-medium mb-1">Voicing Type</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Determines which notes of a chord you play. Shell = only the 2-3 most important notes (like jazz pianists in combos).</p>

				<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">Basics</div>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: 'root' as VoicingType, label: 'Root Position', sub: 'Root + all notes from bottom. The textbook voicing.' },
						{ val: 'shell' as VoicingType, label: 'Shell Voicing', sub: 'Root + 3rd + 7th only. Foundation for jazz comping.' },
						{ val: 'half-shell' as VoicingType, label: 'Half Shell', sub: '3rd/7th around the root. Typical left-hand voicing.' },
						{ val: 'full' as VoicingType, label: 'Full Voicing', sub: 'All notes in jazz order: 1-7-3-5.' },
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

				<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">🎹 Left-Hand Voicings <span class="text-[var(--text-dim)] font-normal">(no root — bassist plays the bass)</span></div>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: 'rootless-a' as VoicingType, label: 'Rootless A', sub: '3 – 5 – 7 – 9 · Bill Evans style. The essential left-hand comping voicing.' },
						{ val: 'rootless-b' as VoicingType, label: 'Rootless B', sub: '7 – 9 – 3 – 5 · Complement to Type A. Same chord, different position.' },
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

				<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">🔄 Inversions <span class="text-[var(--text-dim)] font-normal">(same chord, different note on bottom)</span></div>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'inversion-1' as VoicingType, label: '1st Inversion', sub: '3rd on bottom. Softer color.' },
						{ val: 'inversion-2' as VoicingType, label: '2nd Inversion', sub: '5th on bottom. Open sound.' },
						{ val: 'inversion-3' as VoicingType, label: '3rd Inversion', sub: '7th on bottom. 4+ note chords only.' },
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
				<legend class="text-sm font-medium mb-1">Note Display</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Whether individual chord notes are shown on the keyboard.</p>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'off' as DisplayMode, label: 'Off', sub: 'Play blind — no help' },
						{ val: 'always' as DisplayMode, label: 'Always', sub: 'Notes visible on keyboard' },
						{ val: 'verify' as DisplayMode, label: 'Verify', sub: 'Play first, then reveal' },
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
					<legend class="text-sm font-medium mb-3">Number of Chords</legend>
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
