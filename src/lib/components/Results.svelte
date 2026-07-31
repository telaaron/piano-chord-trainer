<script lang="ts">
	import PianoKeyboard from './PianoKeyboard.svelte';
	import KeyClock from './KeyClock.svelte';
	import type { KeyDial } from '$lib/services/progress';
	import type { DialProgress } from '$lib/engine/habits';
	import {
		convertChordNotation,
		convertNoteName,
		typesetChordName,
		formatVoicing,
		VOICING_LABELS,
		PROGRESSION_LABELS,
		type AccidentalPreference,
		type Difficulty,
		type DisplayMode,
		type NotationStyle,
		type NotationSystem,
		type VoicingType,
		type ProgressionMode,
	} from '$lib/engine';
	import type { ChordWithNotes } from '$lib/engine';
	import { formatTime as fmt } from '$lib/utils/format';
	import { t } from '$lib/i18n';
	import { Target, Piano, Rocket, Repeat, Zap, Music, BookOpen, type Icon as LucideIcon } from 'lucide-svelte';

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
		progressionMode: ProgressionMode;
		midiEnabled: boolean;
		midiAccuracy: number;
		/** Average timing offset in ms for In-Time mode (optional) */
		avgTimingMs?: number;
		/** Whether In-Time mode was active */
		inTimeModeActive?: boolean;
		/** Ear Training correct count */
		earTrainingCorrect?: number;
		/** Ear Training total attempts */
		earTrainingTotal?: number;
		/** Voice Leading: average movement score */
		vlAvgMovement?: number;
		/** Voice Leading: optimal inversions found (mode B) */
		vlOptimalCount?: number;
		/** Voice Leading: total VL chords attempted */
		vlTotalChords?: number;
		/** Voice Leading mode active */
		vlModeActive?: string;
		/** Whether the player has enough history to drill weak spots. */
		candrillweak?: boolean;
		/** The dial as it stands AFTER this session. Omitted = no dial shown. */
		dial?: KeyDial[];
		/** Roots touched in this session — lit up, the rest dimmed. */
		dialHighlight?: string[];
		/** What moved. Only a genuine crossing produces a line. */
		dialProgress?: DialProgress | null;
		/** Mastery threshold, so the dial's reference ring matches the engine. */
		dialThresholdMs?: number;
		onrestart: () => void;
		onreset: () => void;
		/** Launch a focused drill on the player's weakest chords. */
		ondrillweak?: () => void;
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
		progressionMode,
		midiEnabled,
		midiAccuracy,
		avgTimingMs = 0,
		inTimeModeActive = false,
		earTrainingCorrect = 0,
		earTrainingTotal = 0,
		vlAvgMovement = 0,
		vlOptimalCount = 0,
		vlTotalChords = 0,
		vlModeActive = '',
		candrillweak = false,
		dial,
		dialHighlight,
		dialProgress = null,
		dialThresholdMs = 2000,
		onrestart,
		onreset,
		ondrillweak,
	}: Props = $props();

	// ─── The dial, as the session left it ──────────────────────
	/* Note names arrive from the engine as ASCII ("Db"). They go through the
	   player's own notation setting first (German shows H for B), then the
	   accidental is typeset as a real ♭/♯ — same path KeyClock uses, so the
	   line and the ring never disagree about what a key is called. */
	const keyName = (root: string) =>
		convertNoteName(root, notationSystem).replace('b', '♭').replace('#', '♯');

	const secs = (ms: number) => (ms / 1000).toFixed(1).replace('.', ',') + ' s';

	const hasDial = $derived(!!dial && dial.length > 0);

	/**
	 * The fluency line. Silence is the default: if nothing crossed the
	 * threshold this session, we say nothing rather than inventing praise for
	 * a session that did not move the dial.
	 */
	const fluencyLine = $derived.by<string | null>(() => {
		if (!dialProgress) return null;
		const { gained, milestones } = dialProgress;
		if (milestones.includes(12)) return t('clock.milestone_complete');
		if (gained.length === 1) {
			const g = gained[0];
			return g.beforeMs === null
				? t('clock.gained_one_fresh', { key: keyName(g.root), after: secs(g.afterMs) })
				: t('clock.gained_one', {
						key: keyName(g.root),
						before: secs(g.beforeMs),
						after: secs(g.afterMs),
					});
		}
		if (gained.length > 1) {
			return t('clock.gained_many', { keys: gained.map((g) => keyName(g.root)).join(', ') });
		}
		return null;
	});

	/** A milestone below 12 is worth its own quieter line under the first. */
	const milestoneLine = $derived.by<string | null>(() => {
		if (!dialProgress) return null;
		const m = dialProgress.milestones.filter((x) => x < 12).at(-1);
		return m ? t('clock.milestone', { count: m }) : null;
	});

	// ─── Performance-based recommendation ──────────────────────
	const secondsPerChord = $derived(elapsedMs / totalChords / 1000);

	const recommendation = $derived.by<{ icon: typeof LucideIcon; key: string; link: string }>(() => {
		// Low MIDI accuracy → focus on correct notes
		if (midiEnabled && midiAccuracy > 0 && midiAccuracy < 80) {
			return { icon: Target, key: 'results.tip_low_accuracy', link: '' };
		}
		// Using root voicing → suggest shell
		if (voicing === 'root') {
			return { icon: Piano, key: 'results.tip_try_shell', link: '' };
		}
		// Using shell → suggest rootless
		if (voicing === 'shell' || voicing === 'half-shell') {
			return { icon: Rocket, key: 'results.tip_try_rootless', link: '' };
		}
		// Slow pace (> 5s per chord)
		if (secondsPerChord > 5) {
			return { icon: Repeat, key: 'results.tip_slow_pace', link: '' };
		}
		// Fast pace (< 2s per chord) → raise difficulty
		if (secondsPerChord < 2) {
			return { icon: Zap, key: 'results.tip_fast_pace', link: '' };
		}
		// Random mode → suggest ii-V-I
		if (progressionMode === 'random') {
			return { icon: Music, key: 'results.tip_try_progression', link: '' };
		}
		// Default: suggest learning
		return { icon: BookOpen, key: 'results.tip_explore_course', link: '/learn' };
	});
	const RecoIcon = $derived(recommendation.icon);
</script>

<div class="card surface-glass p-6 sm:p-8 w-full max-w-4xl mx-auto text-center space-y-6">
	<!-- Trophy -->
	<div>
		<div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-[var(--primary-muted)] mb-4">
			<svg class="w-8 h-8 text-[var(--primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
					d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
			</svg>
		</div>
		<h2 class="text-3xl font-bold">{t('results.congratulations')}</h2>
		<p class="text-[var(--text-muted)]">{t('results.mastered', { total: totalChords })}</p>
	</div>

	<!-- Time -->
	<div class="bg-[var(--bg-muted)]/35 rounded-[var(--radius-lg)] p-6 border border-[var(--border)]/40 backdrop-blur-sm">
		<div class="text-sm text-[var(--text-muted)] mb-1">{t('results.time')}</div>
		<div class="text-5xl font-bold text-[var(--primary)]">{fmt(elapsedMs)}</div>
		<div class="text-sm text-[var(--text-muted)] mt-2">
			{t('results.time_per_chord', { seconds: (elapsedMs / totalChords / 1000).toFixed(2) })}
		</div>
	</div>

	<!-- The dial: what this session moved. Highlighted keys are the ones just
	     played; the fluency line appears only when something actually crossed. -->
	{#if hasDial}
		<div class="bg-[var(--bg-muted)]/35 rounded-[var(--radius-lg)] p-5 sm:p-6 border border-[var(--border)]/40 backdrop-blur-sm flex flex-col items-center gap-3">
			<div>
				<div class="text-sm font-semibold text-[var(--text)]">{t('clock.results_title')}</div>
				<div class="text-xs text-[var(--text-muted)] mt-0.5">{t('clock.results_sub')}</div>
			</div>

			<KeyClock
				dial={dial ?? []}
				thresholdMs={dialThresholdMs}
				size={248}
				highlight={dialHighlight}
				showTimes={false}
				{notationSystem}
			/>

			{#if fluencyLine}
				<p class="text-sm font-semibold text-[var(--accent-green)]">{fluencyLine}</p>
			{/if}
			{#if milestoneLine}
				<p class="text-xs text-[var(--text-muted)]">{milestoneLine}</p>
			{/if}
		</div>
	{/if}

	<!-- Stats grid -->
	<div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
		{#each [
			{ label: t('results.mode'), value: t('settings.progression_' + (progressionMode === 'cycle-of-4ths' ? 'cycle' : progressionMode === '1-6-2-5' ? 'turnaround' : progressionMode === '2-5-1' ? '251' : progressionMode)) },
			{ label: t('results.difficulty'), value: t('settings.difficulty_' + difficulty) },
			{ label: t('results.chords'), value: String(totalChords) },
			{ label: t('results.notation'), value: t('settings.notation_' + notation) },
			{ label: t('results.accidentals'), value: t('settings.accidentals_' + accidentals) },
			{ label: t('results.voicing'), value: t('settings.voicing_' + voicing.replace(/-/g, '_')) }, // Voicing keys use underscores
		] as stat}
			<div class="bg-[var(--bg)]/72 rounded-[var(--radius)] p-3 border border-[var(--border)] backdrop-blur-sm">
				<div class="text-xs text-[var(--text-muted)] mb-1">{stat.label}</div>
				<div class="font-semibold capitalize">{stat.value}</div>
			</div>
		{/each}
		{#if midiEnabled && midiAccuracy > 0}
			<div class="bg-[var(--bg)]/72 rounded-[var(--radius)] p-3 border border-[var(--border)] backdrop-blur-sm">
				<div class="text-xs text-[var(--text-muted)] mb-1">{t('results.midi_accuracy')}</div>
				<div class="font-semibold text-[var(--accent-green)]">{midiAccuracy}%</div>
			</div>
		{/if}
		{#if inTimeModeActive}
			<div class="bg-[var(--bg)]/72 rounded-[var(--radius)] p-3 border border-[var(--border)] backdrop-blur-sm">
				<div class="text-xs text-[var(--text-muted)] mb-1">{t('results.avg_timing')}</div>
				<div class="font-semibold text-[var(--accent-amber)]">{avgTimingMs > 0 ? avgTimingMs + 'ms' : 'N/A'}</div>
			</div>
		{/if}
		{#if earTrainingTotal > 0}
			<div class="bg-[var(--bg)]/72 rounded-[var(--radius)] p-3 border border-[var(--border)] backdrop-blur-sm">
				<div class="text-xs text-[var(--text-muted)] mb-1">{t('results.ear_score')}</div>
				<div class="font-semibold text-[var(--accent-amber)]">{earTrainingTotal > 0 ? Math.round((earTrainingCorrect / earTrainingTotal) * 100) : 0}%</div>
			</div>
		{/if}
		{#if vlModeActive && vlTotalChords > 0}
			<div class="bg-[var(--bg)]/72 rounded-[var(--radius)] p-3 border border-[var(--border)] backdrop-blur-sm">
				<div class="text-xs text-[var(--text-muted)] mb-1">{t('results.vl_mode')}</div>
				<div class="font-semibold text-[var(--primary)] capitalize">{vlModeActive}</div>
			</div>
			<div class="bg-[var(--bg)]/72 rounded-[var(--radius)] p-3 border border-[var(--border)] backdrop-blur-sm">
				<div class="text-xs text-[var(--text-muted)] mb-0.5">{t('results.avg_movement')}</div>
				<div class="font-semibold text-[var(--accent-amber)]">{vlAvgMovement} {t('results.semitones_short')}</div>
			</div>
			{#if vlModeActive === 'find-inversion'}
				<div class="bg-[var(--bg)]/72 rounded-[var(--radius)] p-3 border border-[var(--border)] backdrop-blur-sm">
					<div class="text-xs text-[var(--text-muted)] mb-1">{t('results.optimal')}</div>
					<div class="font-semibold text-[var(--accent-green)]">{vlOptimalCount}/{vlTotalChords}</div>
				</div>
			{/if}
		{/if}
	</div>

	<!-- Next up recommendation -->
	{#if recommendation}
		<div class="bg-[var(--bg-muted)]/30 rounded-[var(--radius-lg)] p-4 text-left flex items-start gap-3 border border-[var(--border)]/55 backdrop-blur-sm">
			<RecoIcon size={24} class="shrink-0 mt-0.5 text-[var(--primary)]" aria-hidden="true" />
			<div>
				<div class="text-xs font-semibold text-[var(--primary)] uppercase tracking-wide mb-1">{t('results.next_up')}</div>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">{t(recommendation.key)}</p>
				{#if recommendation.link}
					<a href={recommendation.link} class="inline-block mt-2 text-sm font-semibold text-[var(--primary)] hover:underline">
						→ {t('landing.cta_learn')}
					</a>
				{/if}
			</div>
		</div>
	{/if}

	<!-- Action buttons -->
	{#if candrillweak && ondrillweak}
		<!-- Peak-motivation moment: drill the chords you were slowest at. -->
		<button
			class="w-full h-11 pill-btn pill-btn-primary text-[var(--primary-text)] font-semibold transition-colors cursor-pointer flex items-center justify-center gap-2"
			onclick={ondrillweak}
		>
			<Target size={18} aria-hidden="true" />
			{t('results.drill_weak')}
		</button>
		<div class="flex gap-3">
			<button
				class="flex-1 h-11 pill-btn pill-btn-secondary text-[var(--text)] font-medium transition-colors cursor-pointer"
				onclick={onrestart}
			>
				{t('results.play_again')}
			</button>
			<button
				class="flex-1 h-11 pill-btn pill-btn-secondary text-[var(--text)] font-medium transition-colors cursor-pointer"
				onclick={onreset}
			>
				{t('results.back_to_setup')}
			</button>
		</div>
	{:else}
		<div class="flex gap-3">
			<button
				class="flex-1 h-11 pill-btn pill-btn-secondary text-[var(--text)] font-medium transition-colors cursor-pointer"
				onclick={onrestart}
			>
				{t('results.play_again')}
			</button>
			<button
				class="flex-1 h-11 pill-btn pill-btn-primary text-[var(--primary-text)] font-medium transition-colors cursor-pointer"
				onclick={onreset}
			>
				{t('results.back_to_setup')}
			</button>
		</div>
	{/if}

	<!-- Chord list with mini keyboards -->
	{#if chordsWithNotes.length > 0}
		<details class="text-left" open>
			<summary class="cursor-pointer text-sm font-semibold hover:text-[var(--primary)] mb-4">
				{t('results.all_chords')}
			</summary>
			<div class="mt-4 space-y-3 max-h-[28rem] overflow-y-auto pr-1">
				{#each chordsWithNotes as cd, i}
					<div class="bg-[var(--bg)]/72 rounded-[var(--radius)] p-4 border border-[var(--border)] hover:border-[var(--border-hover)] transition-colors backdrop-blur-sm">
						<div class="flex items-center gap-3 mb-3">
							<span class="text-xs bg-[var(--bg-muted)] px-2 py-0.5 rounded">{i + 1}</span>
							<span class="text-lg font-bold text-[var(--primary)]">
								{typesetChordName(convertChordNotation(cd.chord, notationSystem))}
							</span>
						</div>

						<!-- Mini keyboard -->
						<div class="mb-3">
							<PianoKeyboard chordData={cd} accidentalPref={accidentals} showVoicing={true} mini={true} />
						</div>

						<!-- All 4 voicings -->
						<div class="grid grid-cols-2 gap-2 text-xs">
							{#each (['root', 'shell', 'half-shell', 'full'] as const) as v}
								<div class="bg-[var(--bg-muted)]/50 p-2 rounded-[var(--radius-sm)] border border-[var(--border)]/40">
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
