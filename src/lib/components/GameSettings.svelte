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

	/**
	 * Returns a 7-element boolean array (Mon–Sun) for the current week.
	 * A slot is true if the user practiced on that calendar day, inferred
	 * from the streak's consecutive-day count and lastDate.
	 */
	function getWeekDots(s: StreakData): boolean[] {
		const dots: boolean[] = Array(7).fill(false);
		if (s.current === 0 || !s.lastDate) return dots;

		// Build the set of practiced dates (YYYY-MM-DD) from streak
		const practiceDates = new Set<string>();
		const lastDate = new Date(s.lastDate + 'T00:00:00');
		for (let i = 0; i < s.current; i++) {
			const d = new Date(lastDate);
			d.setDate(lastDate.getDate() - i);
			practiceDates.add(d.toISOString().slice(0, 10));
		}

		// Monday of the current week
		const today = new Date();
		const jsDay = today.getDay(); // 0 = Sun, 1 = Mon … 6 = Sat
		const daysFromMonday = jsDay === 0 ? 6 : jsDay - 1;
		const monday = new Date(today);
		monday.setDate(today.getDate() - daysFromMonday);

		for (let i = 0; i < 7; i++) {
			const d = new Date(monday);
			d.setDate(monday.getDate() + i);
			dots[i] = practiceDates.has(d.toISOString().slice(0, 10));
		}
		return dots;
	}

	const WEEKLY_GOAL = 5;

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
	};

	const LEVEL_CONFIG: Record<'beginner' | 'intermediate' | 'advanced', { color: string; shadow: string; dotsFilled: number }> = {
		beginner:     { color: '#4ade80', shadow: '0 0 18px rgba(74,222,128,0.15)',  dotsFilled: 2 },
		intermediate: { color: '#fb923c', shadow: '0 0 18px rgba(251,146,60,0.15)', dotsFilled: 3 },
		advanced:     { color: '#ef4444', shadow: '0 0 18px rgba(239,68,68,0.15)',  dotsFilled: 5 },
	};

	let weekDots = $derived(getWeekDots(streak));
	let daysThisWeek = $derived(weekDots.filter(Boolean).length);
	let weeklyPct = $derived(Math.min(100, Math.round((daysThisWeek / WEEKLY_GOAL) * 100)));

	// Animated bar width — starts at 0, transitions to target on mount/update
	let barWidth = $state(0);
	$effect(() => {
		const target = weeklyPct;
		// Small delay so the CSS transition fires from 0 each time streak changes
		const t = setTimeout(() => { barWidth = target; }, 60);
		return () => clearTimeout(t);
	});
</script>

<div class="max-w-2xl mx-auto space-y-6">
	<!-- Greeting + Streak -->
	<div class="text-center space-y-3">
		<h2 class="text-3xl font-bold">
			{greetingText()}!
		</h2>

		{#if streak.current > 0}
			<!-- Flame + count -->
			<div class="flex flex-col items-center gap-1">
				<div class="flex items-center gap-2 font-bold leading-none" style="color:#fb923c;">
					<img
						src="/elements/images/streak-flame.webp"
						alt="Streak flame"
						loading="lazy"
						width="64"
						height="64"
						style="width: clamp(28px, 8vw, 48px); height: auto; mix-blend-mode: lighten;"
					/>
					<span style="font-size:1.8rem;">{streak.current}</span>
				</div>

				<!-- Week dots: Mon–Sun -->
				<div class="flex gap-1.5 mt-0.5" aria-label="{streak.current} day streak">
					{#each weekDots as filled}
						<span
							style="display:inline-block; width:10px; height:10px; border-radius:50%; background:{filled ? '#fb923c' : '#2a2a2a'};"
						></span>
					{/each}
				</div>

				<p class="text-xs text-[var(--text-muted)]">day streak</p>
			</div>

			<!-- Weekly goal progress bar -->
			<div class="mx-auto mt-1" style="max-width:220px; width:100%;">
				<div class="flex justify-between mb-1" style="font-size:0.7rem; color:var(--text-muted);">
					<span>Weekly Goal</span>
					<span>{weeklyPct}%</span>
				</div>
				<div style="height:4px; border-radius:9999px; background:#1a1a1a; width:100%; overflow:hidden;">
					<div
						style="height:100%; border-radius:9999px; background:#fb923c; width:{barWidth}%; transition: width 0.8s ease-out;"
					></div>
				</div>
			</div>
		{/if}
	</div>

	<!-- ── MIDI Auto-Detection Banner ── -->
	{#if midiState === 'connected' && midiDevices.length > 0}
		<div class="card p-4 border-[var(--accent-green)]/40 bg-[var(--accent-green)]/5">
			<div class="flex items-center gap-3">
				<div class="text-2xl">🎹</div>
				<div class="flex-1 min-w-0">
					<div class="font-semibold text-sm flex items-center gap-1.5">
						<span class="connected-dot">●</span>
						<span style="color: #4ade80">{midiDevices[0].name} detected</span>
					</div>
					<div class="text-xs text-[var(--text-muted)] mt-0.5">
						MIDI active — play chords directly on your piano
					</div>
				</div>
			</div>
		</div>
	{:else if midiState === 'connected' && midiDevices.length === 0}
		<div class="card border-[var(--border)]">
			<div class="flex items-center gap-3">
				<div class="flex-1 p-4 min-w-0">
					<div class="text-sm text-[var(--text-muted)]">No MIDI device found</div>
					<div class="text-xs text-[var(--text-dim)] mt-0.5">
						Plug in via USB — detected automatically<span class="dot dot-1">.</span><span class="dot dot-2">.</span><span class="dot dot-3">.</span>
					</div>
				</div>
				<img
					src="/elements/images/midi-connect.webp"
					alt="Connect MIDI keyboard"
					loading="lazy"
					width="120"
					height="80"
					class="hidden sm:block flex-shrink-0"
					style="width: 120px; height: auto; mix-blend-mode: lighten;"
				/>
			</div>
		</div>
	{:else if midiState === 'unsupported'}
		<div class="card p-4 border-[var(--accent-amber)]/40 bg-[var(--accent-amber)]/5">
			<div class="flex items-start gap-3">
				<div class="text-xl mt-0.5">🌐</div>
				<div class="flex-1 min-w-0">
					<div class="font-semibold text-sm text-[var(--accent-amber)]">MIDI not supported in this browser</div>
					<div class="text-xs text-[var(--text-muted)] mt-1">
						Web MIDI requires Chrome or Edge on desktop. You can still train without MIDI — press <kbd class="px-1 py-0.5 rounded bg-[var(--bg-muted)] font-mono text-[10px]">Space</kbd> to advance.
					</div>
					<div class="flex gap-3 mt-2">
						<a href="https://www.google.com/chrome/" target="_blank" rel="noopener noreferrer"
							class="text-xs text-[var(--accent-amber)] underline underline-offset-2 hover:text-[var(--primary)] transition-colors">
							Download Chrome →
						</a>
						<a href="https://www.microsoft.com/edge" target="_blank" rel="noopener noreferrer"
							class="text-xs text-[var(--accent-amber)] underline underline-offset-2 hover:text-[var(--primary)] transition-colors">
							Download Edge →
						</a>
					</div>
				</div>
			</div>
		</div>
	{:else if midiState === 'denied'}
		<div class="card p-4 border-red-500/40 bg-red-500/5">
			<div class="flex items-start gap-3">
				<div class="text-xl mt-0.5">🚫</div>
				<div class="flex-1 min-w-0">
					<div class="font-semibold text-sm text-red-400">MIDI permission denied</div>
					<div class="text-xs text-[var(--text-muted)] mt-1 leading-relaxed">
						Your browser blocked MIDI access. To fix this:<br />
						Click the 🔒 lock icon in the address bar → find <strong>MIDI</strong> → set to <strong>Allow</strong> → reload the page.
					</div>
					<a href="https://support.google.com/chrome/answer/114662" target="_blank" rel="noopener noreferrer"
						class="inline-block mt-2 text-xs text-[var(--accent-amber)] underline underline-offset-2 hover:text-[var(--primary)] transition-colors">
						Step-by-step guide →
					</a>
				</div>
			</div>
		</div>
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
				<div class="text-xs text-[var(--text-dim)] font-medium mb-1">Recommended</div>
				<div class="text-xl font-bold group-hover:text-[var(--primary)] transition-colors">{suggested.name}</div>
				<div class="text-sm text-[var(--text-muted)] mt-1">{suggested.tagline}</div>
				<p class="text-xs text-[var(--text-dim)] mt-2 overflow-hidden transition-all duration-300 max-h-0 group-hover:max-h-24">{suggested.description}</p>
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
					class="card p-4 text-left cursor-pointer transition-all duration-200 group relative hover:z-10 hover:scale-105 hover:border-[var(--border-hover)]"
					style="border-left: 3px solid {LEVEL_CONFIG[plan.level].color}; box-shadow: {LEVEL_CONFIG[plan.level].shadow};"
					onclick={() => onstartplan(plan)}
				>
					<!-- Difficulty badge -->
					<div
						class="absolute top-2 right-2 uppercase font-medium"
						style="font-size: 0.65rem; letter-spacing: 0.05em; color: {LEVEL_CONFIG[plan.level].color};"
					>
						{plan.level}
					</div>
					<!-- Icon + name (always visible) -->
					<img
						src="/elements/icons/{PLAN_ICON[plan.id]}.webp"
						alt="{plan.name}"
						width="56"
						height="56"
						loading="lazy"
						style="width:56px; height:56px; mix-blend-mode:lighten; object-fit:contain; margin-bottom:0.5rem; filter: drop-shadow(0 0 10px rgba(251,146,60,0.5));"
					/>
					<div class="font-semibold text-sm group-hover:text-[var(--primary)] transition-colors">{plan.name}</div>
					<!-- Hover overlay: tagline + description, absolutely positioned so nothing shifts -->
					<div class="absolute inset-x-0 bottom-0 translate-y-full pt-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none z-20">
						<div class="rounded-[var(--radius)] border border-[var(--border-hover)] bg-[var(--bg-card,#1a1a1a)] p-3 shadow-xl"
							style="box-shadow: 0 8px 32px rgba(0,0,0,0.6), {LEVEL_CONFIG[plan.level].shadow};">
							<div class="text-xs font-medium text-[var(--text-muted)] mb-1">{plan.tagline}</div>
							<div class="text-xs text-[var(--text-dim)] leading-snug">{plan.description}</div>
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
				alt="Custom Progression"
				width="68"
				height="68"
				loading="lazy"
				style="width:68px; height:68px; mix-blend-mode:lighten; object-fit:contain; flex-shrink:0; filter: drop-shadow(0 0 12px rgba(251,146,60,0.6));"
			/>
			<div class="flex-1 min-w-0">
				<div class="text-sm font-bold group-hover:text-[var(--primary)] transition-colors">Custom Progression</div>
				<div class="text-xs text-[var(--text-dim)] mt-1">Enter your own chord sequence, practice with metronome, get results. Jazz standards available as templates.</div>
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
				<div class="text-sm font-medium">Custom Settings</div>
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
				▶ Start with these settings
			</button>
			<!-- Practice mode -->
			<fieldset>
				<legend class="text-sm font-medium mb-1">Practice Mode</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">How chords are sequenced. Progressions train real jazz patterns.</p>
				<div class="grid grid-cols-2 gap-3">
					{#each [
					{ val: 'random' as ProgressionMode, label: 'Random', sub: 'No pattern' },
					{ val: '2-5-1' as ProgressionMode, label: 'ii – V – I', sub: 'Jazz standard' },
					{ val: 'cycle-of-4ths' as ProgressionMode, label: 'Circle of 4ths', sub: 'All 12 keys' },
					{ val: '1-6-2-5' as ProgressionMode, label: 'I – vi – ii – V', sub: 'Turnaround' },
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
				<legend class="text-sm font-medium mb-1">Difficulty</legend>
				<p class="text-xs text-[var(--text-dim)] mb-3">Chord types: Beginner = 5 basic, Advanced = 14+ extended</p>
				<div class="grid grid-cols-3 gap-3">
					{#each [
					{ val: 'beginner' as Difficulty, label: 'Beginner', sub: '5 types' },
					{ val: 'intermediate' as Difficulty, label: 'Inter.', sub: '9 types' },
					{ val: 'advanced' as Difficulty, label: 'Advanced', sub: '14+ types' },
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
		</div>
	</details>
</div>

<style>
	/* ── MIDI icon pulsing ring ── */
	.midi-icon-wrapper {
		position: relative;
		width: 2.5rem;
		height: 2.5rem;
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
	}

	.midi-icon-wrapper::before {
		content: '';
		position: absolute;
		inset: -4px;
		border-radius: 50%;
		border: 1.5px solid rgba(150, 150, 150, 0.55);
		animation: midi-pulse 1.8s ease-in-out infinite;
		pointer-events: none;
	}

	@keyframes midi-pulse {
		0% {
			transform: scale(1);
			opacity: 1;
		}
		100% {
			transform: scale(1.15);
			opacity: 0.4;
		}
	}

	/* ── Waiting dots ── */
	.dot {
		display: inline-block;
		animation: dot-blink 1.5s ease-in-out infinite;
	}
	.dot-1 { animation-delay: 0ms; }
	.dot-2 { animation-delay: 300ms; }
	.dot-3 { animation-delay: 600ms; }

	@keyframes dot-blink {
		0%, 100% { opacity: 0.2; }
		50% { opacity: 1; }
	}

	/* ── Connected green dot ── */
	.connected-dot {
		color: #4ade80;
		filter: drop-shadow(0 0 4px #4ade80);
		font-size: 0.65em;
		line-height: 1;
	}
</style>
