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
	import { t } from '$lib/i18n';

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
		/** In-Time mode toggle */
		inTimeMode: boolean;
		/** Bars per chord in In-Time mode (1, 2, or 4) */
		inTimeBars: number;
		/** Adaptive difficulty toggle */
		adaptiveEnabled: boolean;
		/** Voice leading visualization toggle */
		voiceLeadingEnabled: boolean;
		onstart: () => void;
		onstartplan: (plan: PracticePlan) => void;
		oncustomprogression: () => void;
		onstarteartraining: () => void;
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
		inTimeMode = $bindable(),
		inTimeBars = $bindable(),
		adaptiveEnabled = $bindable(),
		voiceLeadingEnabled = $bindable(),
		onstart,
		onstartplan,
		oncustomprogression,
		onstarteartraining,
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

	const PLAN_ICON: Record<string, string> = {
		'warmup':            'icon-warm-up',
		'speed':             'icon-speed-run',
		'deepdive':          'icon-deep-dive',
		'turnaround':        'icon-turnaround',
		'challenge':         'icon-challenge',
		'quartenzirkel':     'icon-cycle',
		'voicing-drill':     'icon-voicing-drill',
		'left-hand-comping': 'icon-left-hand',
		'inversions-drill':  'icon-inversions',
		'in-time-comping':   'icon-in-time-comping',
		'ear-check':         'icon-ear-check',
		'adaptive-drill':    'icon-adaptive-drill',
		'voice-leading-flow':'icon-voice-leading-flow',
	};

	const LEVEL_CONFIG: Record<'beginner' | 'intermediate' | 'advanced', { color: string; shadow: string; dotsFilled: number }> = {
		beginner:     { color: '#4ade80', shadow: '0 0 18px rgba(74,222,128,0.15)',  dotsFilled: 2 },
		intermediate: { color: '#fb923c', shadow: '0 0 18px rgba(251,146,60,0.15)', dotsFilled: 3 },
		advanced:     { color: '#ef4444', shadow: '0 0 18px rgba(239,68,68,0.15)',  dotsFilled: 5 },
	};

</script>

<div class="max-w-2xl mx-auto space-y-6">
	<!-- ── Empfohlen ── -->
	<button
		class="card w-full p-5 sm:p-6 text-left cursor-pointer hover:border-[var(--border-hover)] transition-colors group relative"
		style="border-left: 3px solid {LEVEL_CONFIG[suggested.level].color}; box-shadow: {LEVEL_CONFIG[suggested.level].shadow};"
		onclick={() => onstartplan(suggested)}
	>
		<!-- Difficulty badge -->
		<div
			class="absolute top-3 right-3 uppercase font-medium"
			style="font-size: 0.65rem; letter-spacing: 0.05em; color: {LEVEL_CONFIG[suggested.level].color};"
		>
			{suggested.level}
		</div>
		<div class="flex items-start gap-4">
			<img
				src="/elements/icons/{PLAN_ICON[suggested.id]}.webp"
				alt="{suggested.name}"
				width="52"
				height="52"
				loading="lazy"
				style="width:52px; height:52px; mix-blend-mode:lighten; object-fit:contain; flex-shrink:0; filter: drop-shadow(0 0 10px rgba(251,146,60,0.5));"
			/>
			<div class="flex-1 min-w-0">
				<div class="text-xs text-[var(--text-dim)] font-medium mb-1">{t('settings.suggested_plan')}</div>
				<div class="text-xl font-bold group-hover:text-[var(--primary)] transition-colors">{t(suggested.name)}</div>
				<div class="text-sm text-[var(--text-muted)] mt-1">{t(suggested.tagline)}</div>
				<p class="text-xs text-[var(--text-dim)] mt-2 overflow-hidden transition-all duration-300 max-h-0 group-hover:max-h-24">{t(suggested.description)}</p>
			</div>
			<div class="text-[var(--primary)] text-2xl opacity-60 group-hover:opacity-100 transition-opacity self-center">▶</div>
		</div>
	</button>

		<!-- ── Practice Plans Grid ── -->
	<div>
		<h3 class="text-sm font-medium text-[var(--text-muted)] mb-3">{t('settings.all_plans')}</h3>
		<div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
			{#each PRACTICE_PLANS.filter((p) => p.id !== suggested.id) as plan}
				<button
					class="card p-4 text-left cursor-pointer transition-all duration-200 group relative hover:z-10 hover:scale-105 hover:border-[var(--border-hover)]"
					style="border-left: 3px solid {LEVEL_CONFIG[plan.level].color}; box-shadow: {LEVEL_CONFIG[plan.level].shadow};"
					onclick={() => onstartplan(plan)}
				>
					<!-- Difficulty badge -->
					<div
						class="absolute top-2 right-2 uppercase font-medium"
						style="font-size: 0.65rem; letter-spacing: 0.05em; color: {LEVEL_CONFIG[plan.level].color};"
					>
						{t('settings.difficulty_' + plan.level)}
					</div>
					<!-- Icon + name (always visible) -->
					<img
						src="/elements/icons/{PLAN_ICON[plan.id]}.webp"
						alt="{t(plan.name)}"
						width="56"
						height="56"
						loading="lazy"
						style="width:56px; height:56px; mix-blend-mode:lighten; object-fit:contain; margin-bottom:0.5rem; filter: drop-shadow(0 0 10px rgba(251,146,60,0.5));"
					/>
					<div class="font-semibold text-sm group-hover:text-[var(--primary)] transition-colors">{t(plan.name)}</div>
					<!-- Hover overlay: tagline + description, absolutely positioned so nothing shifts -->
					<div class="absolute inset-x-0 bottom-0 translate-y-full pt-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none z-20">
						<div class="rounded-[var(--radius)] border border-[var(--border-hover)] bg-[var(--bg-card,#1a1a1a)] p-3 shadow-xl"
							style="box-shadow: 0 8px 32px rgba(0,0,0,0.6), {LEVEL_CONFIG[plan.level].shadow};">
							<div class="text-xs font-medium text-[var(--text-muted)] mb-1">{t(plan.tagline)}</div>
							<div class="text-xs text-[var(--text-dim)] leading-snug">{t(plan.description)}</div>
						</div>
					</div>
				</button>
			{/each}
		</div>
	</div>

	<!-- ── Custom Progression ── -->
	<button
		class="card w-full p-5 text-left cursor-pointer hover:border-[var(--border-hover)] transition-colors group"
		onclick={oncustomprogression}
	>
		<div class="flex items-center gap-5">
			<img
				src="/elements/icons/icon-custom-progression.webp"
				alt="{t('settings.custom_progression')}"
				width="68"
				height="68"
				loading="lazy"
				style="width:68px; height:68px; mix-blend-mode:lighten; object-fit:contain; flex-shrink:0; filter: drop-shadow(0 0 12px rgba(251,146,60,0.6));"
			/>
			<div class="flex-1 min-w-0">
				<div class="text-sm font-bold group-hover:text-[var(--primary)] transition-colors">{t('settings.custom_progression')}</div>
				<div class="text-xs text-[var(--text-dim)] mt-1">{t('settings.custom_progression_desc')}</div>
			</div>
			<div class="text-[var(--text-dim)] text-xl group-hover:text-[var(--primary)] transition-colors">→</div>
		</div>
	</button>

		<!-- ── Custom Practice ── -->
	<details class="card group">
		<summary class="cursor-pointer p-5 sm:p-6 flex items-center gap-4 justify-between">
			<img
				src="/elements/icons/icon-settings.webp"
				alt="Settings"
				width="48"
				height="48"
				loading="lazy"
				style="width:48px; height:48px; flex-shrink:0; mix-blend-mode:lighten; object-fit:contain; filter: drop-shadow(0 0 10px rgba(251,146,60,0.5));"
			/>
			<div class="flex-1 min-w-0">
				<div class="text-sm font-medium">{t('settings.custom_settings')}</div>
				<div class="text-xs text-[var(--text-dim)] mt-1 flex flex-wrap gap-2">
					<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full">
						{progressionMode === 'random' ? `${totalChords} ${t('results.chords')}` : PROGRESSION_LABELS[progressionMode]}
					</span>
					<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full capitalize">{t('settings.difficulty_' + difficulty)}</span>
					<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full">{VOICING_LABELS[voicing]}</span>
					{#if midiEnabled}
						<span class="bg-[var(--accent-green)]/20 text-[var(--accent-green)] px-2 py-0.5 rounded-full">MIDI</span>
					{/if}
				</div>
			</div>
			<svg class="w-5 h-5 text-[var(--text-dim)] transition-transform group-open:rotate-180 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
			</svg>
		</summary>

		<div class="px-5 sm:px-6 pb-5 sm:pb-6 pt-0 border-t border-[var(--border)] space-y-6">
			<!-- Start custom -->
			<button
				class="w-full h-12 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] text-base font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer mt-4"
				onclick={onstart}
			>
				▶ {t('settings.start_training')}
			</button>
			<!-- Practice mode -->
			<fieldset>
				<legend class="text-sm font-medium mb-1">{t('settings.progression_mode')}</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">How chords are sequenced. Progressions train real jazz patterns.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
					{ val: 'random' as ProgressionMode, label: t('settings.progression_random'), sub: 'No pattern' },
					{ val: '2-5-1' as ProgressionMode, label: t('settings.progression_251'), sub: 'Jazz standard' },
					{ val: 'cycle-of-4ths' as ProgressionMode, label: t('settings.progression_cycle'), sub: 'All 12 keys' },
					{ val: '1-6-2-5' as ProgressionMode, label: t('settings.progression_turnaround'), sub: 'Turnaround' },
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
				<p class="text-xs text-[var(--text-dim)] mb-3">Auto-advance when you play the correct chord</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
					{ val: false, label: 'Off', sub: 'Space to advance' },
					{ val: true, label: 'On', sub: 'Auto-advance' },
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
				<legend class="text-sm font-medium mb-1">{t('settings.difficulty')}</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Chord types: Beginner = 5 basic, Advanced = 14+ extended</p>
				<div class="grid grid-cols-3 gap-3">
					{#each [
					{ val: 'beginner' as Difficulty, label: t('settings.difficulty_beginner'), sub: '5 types' },
					{ val: 'intermediate' as Difficulty, label: t('settings.difficulty_intermediate'), sub: '9 types' },
					{ val: 'advanced' as Difficulty, label: t('settings.difficulty_advanced'), sub: '14+ types' },
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
				<legend class="text-sm font-medium mb-1">{t('settings.accidentals')}</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Whether black keys use # (sharp) or ♭ (flat). Jazz typically uses flats.</p>
				<div class="grid grid-cols-3 gap-3">
					{#each [
						{ val: 'sharps' as AccidentalPreference, label: t('settings.accidentals_sharps'), sub: 'C#, D#, F#, G#, A#' },
						{ val: 'flats' as AccidentalPreference, label: t('settings.accidentals_flats'), sub: 'Db, Eb, Gb, Ab, Bb' },
						{ val: 'both' as AccidentalPreference, label: t('settings.accidentals_both'), sub: '# and ♭ mixed' },
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
						{ val: 'verify' as DisplayMode, label: 'Verify', sub: midiEnabled ? 'N/A with MIDI' : 'Play first, then reveal' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(displayMode, opt.val)} {opt.val === 'verify' && midiEnabled ? 'opacity-40 cursor-not-allowed' : ''}"
							onclick={() => { if (!(opt.val === 'verify' && midiEnabled)) displayMode = opt.val; }}
							disabled={opt.val === 'verify' && midiEnabled}
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

			<!-- ── Advanced Training Modes ── -->
			<fieldset>
				<legend class="text-sm font-medium mb-1">In-Time Mode</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Chord changes happen on the beat. Trains timing instead of speed.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: false, label: 'Off', sub: 'Speed drill' },
						{ val: true, label: 'On', sub: 'Play on the beat' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(inTimeMode, opt.val)}"
							onclick={() => (inTimeMode = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
				{#if inTimeMode}
					<div class="mt-3">
						<div class="text-xs font-medium text-[var(--text-muted)] mb-2">Bars per Chord</div>
						<div class="grid grid-cols-3 gap-3">
							{#each [1, 2, 4] as bars}
								<button
									class="p-2 rounded-[var(--radius)] border-2 transition-all text-center {sel(inTimeBars, bars)}"
									onclick={() => (inTimeBars = bars)}
								>
									<div class="font-semibold text-sm">{bars}</div>
									<div class="text-xs text-[var(--text-dim)]">{bars === 1 ? 'bar' : 'bars'}</div>
								</button>
							{/each}
						</div>
					</div>
				{/if}
			</fieldset>

			<fieldset>
				<legend class="text-sm font-medium mb-1">Adaptive Difficulty</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Weak chords appear more often, strong ones less. Spaced repetition for your drills.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: false, label: 'Off', sub: 'Equal weighting' },
						{ val: true, label: 'On', sub: 'Adapt to you' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(adaptiveEnabled, opt.val)}"
							onclick={() => (adaptiveEnabled = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
			</fieldset>

			<fieldset>
				<legend class="text-sm font-medium mb-1">Voice Leading</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Highlight common tones and note movements between chords on the keyboard.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
						{ val: false, label: 'Off', sub: 'Standard display' },
						{ val: true, label: 'On', sub: 'Show connections' },
					] as opt}
						<button
							class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voiceLeadingEnabled, opt.val)}"
							onclick={() => (voiceLeadingEnabled = opt.val)}
						>
							<div class="font-semibold text-sm">{opt.label}</div>
							<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
						</button>
					{/each}
				</div>
			</fieldset>

			<!-- Ear Training button -->
			<button
				class="w-full p-4 rounded-[var(--radius)] border-2 border-[var(--border)] hover:border-[var(--accent-amber)] transition-all text-left group"
				onclick={onstarteartraining}
			>
				<div class="flex items-center gap-3">
					<span class="text-2xl">👂</span>
					<div>
						<div class="font-semibold text-sm group-hover:text-[var(--accent-amber)] transition-colors">Ear Training Mode</div>
						<div class="text-xs text-[var(--text-dim)] mt-0.5">Hear a chord, play it blind. No chord name shown.</div>
					</div>
				</div>
			</button>
		</div>
	</details>
</div>


