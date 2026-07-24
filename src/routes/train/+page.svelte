<script lang="ts">
	import { onMount } from 'svelte';
	import { fly, fade, scale, slide } from 'svelte/transition';
	import { t } from '$lib/i18n';
	import GameSettings from '$lib/components/GameSettings.svelte';
	import QuickStart from '$lib/components/QuickStart.svelte';
	import { Icon } from '$lib/components/ui';
	import UpgradeSheet from '$lib/components/UpgradeSheet.svelte';
	import ProBadge from '$lib/components/ProBadge.svelte';
	import { canUse, showLock } from '$lib/services/subscription-store.svelte';
	import { hasUsedTeaser, markTeaserUsed } from '$lib/utils/teaser';
	import { toggleLightDark, isLightActive } from '$lib/services/theme';
	import { Sun, Moon, Eye, Settings, TabletSmartphone, Piano, RefreshCw, Ear, Volume2, VolumeX, Music, Target, Check, X, CornerDownLeft, ArrowDown, Play, Pause, RotateCcw, ArrowLeft } from 'lucide-svelte';
	import ChordCard from '$lib/components/ChordCard.svelte';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import Results from '$lib/components/Results.svelte';
	import MidiStatus from '$lib/components/MidiStatus.svelte';
	import MicStatus from '$lib/components/MicStatus.svelte';
	import MidiToast from '$lib/components/MidiToast.svelte';
	import ProgressDashboard from '$lib/components/ProgressDashboard.svelte';
	import ProgressionEditor from '$lib/components/ProgressionEditor.svelte';
	import ProgressionPlayer from '$lib/components/ProgressionPlayer.svelte';
	import ProgressionResults from '$lib/components/ProgressionResults.svelte';
	import ExplainPanel from '$lib/components/ExplainPanel.svelte';
	import HabitDashboard from '$lib/components/HabitDashboard.svelte';
	import HabitOnboarding from '$lib/components/HabitOnboarding.svelte';
	import CelebrationOverlay from '$lib/components/CelebrationOverlay.svelte';
	import { initAuth, onAuthChange, getAuthState, type AuthState } from '$lib/services/auth';
	import type { HabitProfile, CelebrationEvent, QuickStartSuggestion, TimeOfDay } from '$lib/engine/habits';
	import { loadHabitProfile, saveHabitProfile, processSessionHabits, scheduleDailyReminder, scheduleStreakSaver } from '$lib/services/habits';
	import { MidiService, isIOSorIPadOS } from '$lib/services/midi';
	import type { MidiConnectionState, MidiDevice, ChordMatchResult } from '$lib/services/midi';
	import { MidiSoundEngine } from '$lib/services/midi-sound';
	import { AudioInputService } from '$lib/services/audio-input';
	import type { AudioInputState } from '$lib/services/audio-input';
	import { saveSession, loadSettings, saveSettings, loadStreak, recordPracticeDay, recordPlanUsed, loadRecentPlanIds, loadHistory, computeStats, analyzeWeakSpots, type ProgressStats, type StreakData, type ChordTiming, type SessionResult } from '$lib/services/progress';
	import { playChord, playChordAtTime, playNote, stopAll, startMetronome, stopMetronome, setMetronomeBpm, isMetronomeRunning, disposeAll, setSoundPreset, getSoundPreset, SOUND_PRESETS, type SoundPreset } from '$lib/services/audio';
	import {
		CHORDS_BY_DIFFICULTY,
		CHORD_NOTATIONS,
		PROGRESSION_DESCRIPTIONS,
		getNotePool,
		getChordNotes,
		getVoicingNotes,
		formatVoicing,
		displayToQuality,
		convertChordNotation,
		noteToSemitone,
		generateProgression,
		analyzeVoiceLeading,
		computeVoiceLeadVoicing,
		computeSessionOctaves,
		PRACTICE_PLANS,
		getWeightedChordPool,
		pickWeightedChord,
		validateFindInversion,
		validateFreeVoicing,
		getValidPCSets,
		degreesToLabel,
		parseCustomDegrees,
		type Difficulty,
		type NotationStyle,
		type VoicingType,
		type DisplayMode,
		type AccidentalPreference,
		type NotationSystem,
		type ChordWithNotes,
		type ProgressionMode,
		type PracticePlan,
		type CustomChord,
		type SessionEvaluation,
		type VoiceLeadingInfo,
		type OctaveCount,
		type VoiceLeadingMode,
		type VLValidationResult,
	} from '$lib/engine';

	import { formatTime } from '$lib/utils/format';
	import {
		buildCoachPlan,
		applySessionToCoach,
		applyFeedback,
		assessSession,
		teacherFeedback,
		describeCoachPlan,
		createInitialCoachState,
		buildSkillLadder,
		type CoachState,
		type CoachPlan,
		type CoachBlock,
		type TeacherStatement,
		type FeedbackSignal,
		type SessionVerdict,
	} from '$lib/engine/coach';
	import { DEFAULT_COACH_PARAMS, type CoachParams } from '$lib/engine/coach-params';
	import { loadCoachState, saveCoachState } from '$lib/services/coach-state';
	import { getDeviceId, trackCoachEvent } from '$lib/services/telemetry';
	import { getCohort, fetchCoachParams } from '$lib/services/coach-config';

	const VOICING_KEYS: Record<VoicingType, string> = {
		'root': 'settings.voicing_root',
		'shell': 'settings.voicing_shell',
		'half-shell': 'settings.voicing_half_shell',
		'full': 'settings.voicing_full',
		'rootless-a': 'settings.voicing_rootless_a',
		'rootless-b': 'settings.voicing_rootless_b',
		'inversion-1': 'settings.voicing_inversion_1',
		'inversion-2': 'settings.voicing_inversion_2',
		'inversion-3': 'settings.voicing_inversion_3',
	};

	/** Localize a raw voicing value (e.g. "shell", "rootless-a") for coach labels. */
	function voicingLabel(v: string | undefined): string {
		if (!v) return '';
		const key = VOICING_KEYS[v as VoicingType];
		return key ? t(key) : v;
	}

	/**
	 * Localize the params a Coach label/say/feedback key carries. Voicing values
	 * arrive raw and need translating; quality/root/count/etc. are passed through.
	 */
	function localizeCoachParams(params: Record<string, string> | undefined): Record<string, string> {
		if (!params) return {};
		const out: Record<string, string> = { ...params };
		if (out.voicing) out.voicing = voicingLabel(out.voicing);
		// The key-tier ('easy'|'med'|'all') becomes a localized suffix like " (easy keys)".
		if (out.tier) out.tier = t(`coach.tier.${out.tier}`);
		return out;
	}

	const PROGRESSION_KEYS: Record<ProgressionMode, string> = {
		'random': 'settings.progression_random',
		'2-5-1': 'settings.progression_251',
		'cycle-of-4ths': 'settings.progression_cycle',
		'1-6-2-5': 'settings.progression_turnaround',
		'3-6-2-5': 'settings.progression_3625',
		'1-4-5': 'settings.progression_145',
		'diatonic': 'settings.progression_diatonic',
		'custom': 'settings.progression_custom',
	};

	// ─── Exercise descriptions ───────────────────────────────────
	const VOICING_EXAMPLES: Record<VoicingType, string> = {
		root: 'CMaj7 → C E G B',
		shell: 'CMaj7 → C E B',
		'half-shell': 'CMaj7 → E C B',
		full: 'CMaj7 → C B E G',
		'rootless-a': 'CMaj7 → E G B D',
		'rootless-b': 'CMaj7 → B D E G',
		'inversion-1': 'CMaj7 → E G B C',
		'inversion-2': 'CMaj7 → G B C E',
		'inversion-3': 'CMaj7 → B C E G',
	};

	// ─── Settings (persisted) ────────────────────────────────────
	let difficulty: Difficulty = $state('beginner');
	let notation: NotationStyle = $state('standard');
	let voicing: VoicingType = $state('root');
	let displayMode: DisplayMode = $state('verify' as DisplayMode);
	let accidentals: AccidentalPreference = $state('both');
	let notationSystem: NotationSystem = $state('international');
	let totalChords = $state(20);
	let progressionMode: ProgressionMode = $state('random');
	/** 0-based degree indices for 'custom' progression mode */
	let customDegrees: number[] = $state([1, 4, 0]); // default ii-V-I
	type InputMode = 'none' | 'midi' | 'microphone';
	let inputMode: InputMode = $state<InputMode>('none');
	/** Convenience: true when any real-time input (MIDI or Mic) is active */
	const inputActive = $derived(inputMode !== 'none');

	/**
	 * Suppress mic input when playing audio — prevents the microphone from
	 * hearing the speaker output and self-triggering chord matches.
	 */
	function suppressMicForPlayback(): void {
		if (inputMode === 'microphone') audioInput.suppress(2500);
	}
	let streak: StreakData = $state({ current: 0, best: 0, lastDate: '' });
	let dashStats: ProgressStats = $state(computeStats([]));

	// ─── Habit Engine state ─────────────────────────────────────
	let habitProfile: HabitProfile = $state(null as unknown as HabitProfile);
	let showOnboarding = $state(false);
	let pendingHabitOffer = $state(false);
	let pendingCelebrations: CelebrationEvent[] = $state([]);
	let notificationCleanup: (() => void) | null = $state(null);
	let streakSaverCleanup: (() => void) | null = $state(null);

	// ─── Audio / Metronome settings ──────────────────────────────
	let audioEnabled = $state(true);
	let metronomeEnabled = $state(false);
	let metronomeBpm = $state(80);
	let currentBeat = $state(0);
	let soundPreset: SoundPreset = $state(getSoundPreset());

	// ─── MIDI Live-Sound Engine ─────────────────────────────────
	const midiSoundEngine = new MidiSoundEngine();
	let midiSoundEnabled = $state(midiSoundEngine.enabled);
	const isIpadOS = isIOSorIPadOS();

	// ─── Game state ──────────────────────────────────────────────
	type Screen = 'setup' | 'playing' | 'finished' | 'custom-editor' | 'custom-playing' | 'custom-results' | 'ear-training' | 'coach-feedback';
	type PlayPhase = 'playing' | 'verifying';

	// ─── New mode settings ───────────────────────────────────────
	let inTimeMode = $state(false);
	let inTimeBars = $state(2);
	let inTimeLookAhead = $state(false);
	let adaptiveEnabled = $state(false);
	let focusRoots: string[] = $state([]);
	let focusVoicing: string | null = $state(null);
	// When a Coach block promises one quality (new/focus), restrict the pool to it.
	let qualityFilter: string[] = $state([]);
	let voiceLeadingEnabled = $state(false);
	let showExplain = $state(false);

	// ─── Coach (Auto-Mode) state ─────────────────────────────────
	// Additive path: the Coach drives a sequence of normal drill blocks. All existing
	// modes are untouched — `coachMode` gates every Coach-specific branch.
	/** True while an auto-session (Coach) is running its block sequence. */
	let coachMode = $state(false);
	/** The plan being played; its `blocks` are run one after another. */
	let coachPlan: CoachPlan | null = $state(null);
	/** Index of the block currently playing (0-based). */
	let coachBlockIdx = $state(0);
	/** Snapshot of CoachState BEFORE this session — feeds teacherFeedback(before, …). */
	let coachStateBefore: CoachState | null = $state(null);
	/** Per-block SessionResults accumulated across the whole auto-session, for the 'session_end' telemetry payload. */
	let coachSessionBlocks: SessionResult[] = $state([]);
	/** Wall-clock start of the whole auto-session (all blocks), for 'session_end' durationMs. */
	let coachSessionStartedAt = 0;
	/** Working CoachState, advanced once per block via applySessionToCoach. */
	let coachStateWorking: CoachState | null = $state(null);
	/**
	 * Coach params in effect. Starts as DEFAULT_COACH_PARAMS; onMount kicks off a
	 * non-blocking fetchCoachParams() that swaps in the remote-merged values once
	 * ready (falls back to defaults on timeout/error — never blocks or spinners).
	 */
	let coachParams: CoachParams = $state(DEFAULT_COACH_PARAMS);
	/** Mini transition screen shown between blocks (null = not showing). */
	let coachTransition: { doneKind: string; next: CoachBlock } | null = $state(null);
	/** Auto-advance handle for the transition screen. */
	let coachTransitionTimeout: ReturnType<typeof setTimeout> | null = $state(null);
	/** Localized teacher statements for the post-session feedback screen. */
	let coachFeedback: TeacherStatement[] = $state([]);
	/** True once the player has used the "too easy / passt / too hard" valve this session. */
	let coachFeedbackGiven = $state(false);
	/** System-detected verdict for the post-session screen (excellent / struggling / neutral). */
	let coachVerdict: SessionVerdict = $state('neutral');

	// ─── In-Time mode state ──────────────────────────────────────
	let inTimeBeatCount = $state(0);
	let inTimeBarCount = $state(0);
	let inTimeTimingOffsets: number[] = $state([]);
	let inTimeChordPlayedAt: number | null = $state(null);
	let inTimeBeatOneTime = $state(0);

	// ─── Look-ahead confirm dialog state ───────────────────────
	let showLookAheadConfirm = $state(false);

	// ─── Ear Training state ──────────────────────────────────────
	let earTrainingRevealed = $state(false);
	let earTrainingCorrect = $state(0);
	let earTrainingTotal = $state(0);
	/** Pitch classes (0-11) the user selected as their guess by clicking the piano */
	let earGuessNotes: Set<number> = $state(new Set());
	/** Mobile toggle: when true, plain click = select; when false, plain click = preview */
	let earSelectMode = $state(false);
	/** Result of the last guess submission */
	let earGuessResult: 'correct' | 'wrong' | null = $state(null);

	// ─── Tap-guess state (verify mode, no MIDI/mic) ──────────────
	/** Pitch classes (0-11) the user tapped to build their guess before revealing. */
	let tapGuessNotes: Set<number> = $state(new Set());
	/** Outcome of the last checked tap-guess (drives green/red). */
	let tapGuessResult: 'correct' | 'wrong' | null = $state(null);

	// ─── Voice Leading state ─────────────────────────────────────
	let voiceLeadingInfo: VoiceLeadingInfo | null = $state(null);
	/** Fixed keyboard octave count for the entire session (prevents zoom during VL) */
	let sessionOctaves: OctaveCount | null = $state(null);
	/** Voice leading sub-mode */
	let vlMode: VoiceLeadingMode = $state('guided');
	/** VL validation result for modes B/C */
	let vlValidation: VLValidationResult | null = $state(null);
	/** Tracks movement scores across the session for avg display */
	let vlMovementScores: number[] = $state([]);
	/** Count of optimal inversions found (mode B) */
	let vlOptimalCount = $state(0);

	let screen: Screen = $state<Screen>('setup');

	let settingsOpen = $state(false);
	/** Tracks which screen opened the settings modal (null = from setup) */
	let settingsOpenedFromScreen: Screen | null = $state(null);
	let playPhase: PlayPhase = $state<PlayPhase>('playing');
	let timerStarted = $state(false);
	let paused = $state(false);
	let pauseAccumulated = $state(0);
	let pauseStart = $state(0);
	let showExerciseInfo = $state(false);
	let showInsights = $state(false);
	let advancedOpen = $state(false);

	// ─── Upgrade / paywall ───────────────────────────────────────
	let upgradeOpen = $state(false);
	let upgradeFeature = $state('adaptive-difficulty');
	let upgradeTeaser = $state(false);
	/** Tracks whether the just-finished session was an adaptive (Pro) drill. */
	let sessionWasAdaptive = $state(false);

	function openUpgrade(feature: string, teaser = false) {
		upgradeFeature = feature;
		upgradeTeaser = teaser;
		upgradeOpen = true;
	}

	/**
	 * Gate a Pro feature. Returns true if the caller may proceed.
	 * Free users get one teaser taste of teaser-able features; after that (or for
	 * non-teaser features) the upgrade sheet opens and we block.
	 */
	function gatePro(feature: string, opts: { teaserable?: boolean } = {}): boolean {
		if (canUse(feature)) return true;
		if (opts.teaserable && !hasUsedTeaser(feature)) return true; // allow the one free taste
		openUpgrade(feature, false);
		return false;
	}
	let themeIsLight = $state(false);
	function flipTheme() {
		toggleLightDark();
		themeIsLight = isLightActive();
	}
	$effect(() => {
		themeIsLight = isLightActive();
	});
	let currentIdx = $state(0);
	let chords: string[] = $state([]);
	let chordsWithNotes: ChordWithNotes[] = $state([]);
	let startTime = $state(0);
	let endTime = $state(0);
	let now = $state(0);
	let timerHandle: ReturnType<typeof setInterval> | null = $state(null);
	let chordTimings: ChordTiming[] = $state([]);
	let chordStartTime = $state(0);
	/**
	 * Correctness verdict for the chord currently on screen, set the moment a
	 * right/wrong decision is made (tap-guess, MIDI/mic match, VL validation).
	 * `undefined` = no verdict yet (e.g. answer read in 'always' mode, or "show me").
	 * Read into each ChordTiming as it's pushed, then reset on advance. This runs in
	 * ALL modes (not just Coach) — it only enriches the timing data, never gates flow.
	 */
	let currentChordCorrect: boolean | undefined = $state(undefined);

	/** Push a timing for `data`, stamping the current correctness verdict + optional block kind. */
	function pushTiming(data: ChordWithNotes, durationMs: number): void {
		chordTimings.push({
			chord: data.chord,
			root: data.root,
			durationMs,
			...(currentChordCorrect !== undefined ? { correct: currentChordCorrect } : {}),
		});
	}

	// ─── Custom Progression state ────────────────────────────────
	let customChords: CustomChord[] = $state([]);
	let customBpm = $state(120);
	let customLoops = $state(2);
	let customName = $state('');
	let customEvaluation: SessionEvaluation | null = $state(null);

	// ─── MIDI disconnect toast ───────────────────────────────────
	let midiDisconnectToast: string | null = $state(null);
	let authState: AuthState = $state({ user: null, session: null, loading: true });

	// ─── MIDI state ──────────────────────────────────────────────
	const midi = new MidiService();
	let midiState: MidiConnectionState = $state('disconnected');
	let midiDevices: MidiDevice[] = $state([]);
	let midiSelectedDeviceId: string | null = $state(null);
	let midiActiveNotes: Set<number> = $state(new Set());
	let midiMatchResult: ChordMatchResult | null = $state(null);
	let midiCorrectCount = $state(0);
	let midiTotalAttempts = $state(0);
	let autoAdvanceTimeout: ReturnType<typeof setTimeout> | null = $state(null);

	// ─── Audio Input (Microphone) state ─────────────────────────
	const audioInput = new AudioInputService();
	let micState: AudioInputState = $state('idle');

	// ─── Derived ─────────────────────────────────────────────────
	const currentChord = $derived(chords[currentIdx] ?? '');
	const currentData = $derived(chordsWithNotes[currentIdx] ?? null);
	const shouldShowVoicing = $derived(
		// In VL modes B/C, hide the voicing on the keyboard (player must find it)
		voiceLeadingEnabled && vlMode !== 'guided'
			? false
			: displayMode === 'always' || (displayMode === 'verify' && playPhase === 'verifying'),
	);
	const actualTotalChords = $derived(chords.length || totalChords);
	/** True while the player builds a guess: verify mode, no input device, not yet revealed. */
	const isTapGuessMode = $derived(
		screen === 'playing' &&
		timerStarted &&
		!paused &&
		!inTimeMode &&
		!inputActive &&
		!(voiceLeadingEnabled && vlMode !== 'guided') &&
		displayMode === 'verify' &&
		playPhase === 'playing',
	);
	const progress = $derived(((currentIdx + 1) / actualTotalChords) * 100);
	const elapsedMs = $derived(
		screen === 'playing' && timerStarted
			? (paused ? pauseStart : now) - startTime - pauseAccumulated
			: endTime - startTime - pauseAccumulated
	);

	/** Pitch classes expected for the current chord (for MIDI coloring) */
	const expectedPitchClasses = $derived.by(() => {
		if (!currentData) return new Set<number>();
		const set = new Set<number>();
		for (const note of currentData.voicing) {
			const st = noteToSemitone(note);
			if (st !== -1) set.add(st);
		}
		return set;
	});

	const midiAccuracy = $derived(
		midiTotalAttempts > 0 ? Math.round((midiCorrectCount / midiTotalAttempts) * 100) : 0,
	);

	// ─── Status bar helpers ──────────────────────────────────────
	function greetingText(): string {
		const h = new Date().getHours();
		if (h < 12) return t('settings.greeting_morning');
		if (h < 18) return t('settings.greeting_afternoon');
		return t('settings.greeting_evening');
	}

	function getStatusbarWeekDots(profile: HabitProfile | null): boolean[] {
		const dots: boolean[] = Array(7).fill(false);
		if (!profile) return dots;

		const today = new Date();
		const jsDay = today.getDay();
		const daysFromMonday = jsDay === 0 ? 6 : jsDay - 1;
		const monday = new Date(today);
		monday.setDate(today.getDate() - daysFromMonday);

		// Check each day of the week against dailyGoalDates
		const goalDateSet = new Set(profile.dailyGoalDates);
		for (let i = 0; i < 7; i++) {
			const d = new Date(monday);
			d.setDate(monday.getDate() + i);
			dots[i] = goalDateSet.has(d.toISOString().slice(0, 10));
		}
		return dots;
	}

	const sbWeekDots = $derived(getStatusbarWeekDots(habitProfile));
	const weeklyGoalPct = $derived(Math.min(100, Math.round((sbWeekDots.filter(Boolean).length / 5) * 100)));
	const greeting = greetingText();

	// (formatTime imported from $lib/utils/format)

	/** Shared selection helper for option buttons */
	function sel<T>(current: T, value: T): string {
		return current === value
			? 'border-[var(--primary)] bg-[var(--primary-muted)]'
			: 'border-[var(--border)] hover:border-[var(--border-hover)]';
	}

	// ─── Game logic ──────────────────────────────────────────────
	function generateChords() {
		// Progression modes
		if (progressionMode !== 'random') {
			const result = generateProgression(progressionMode, accidentals, notation, totalChords, customDegrees);
			const newChords: string[] = [];
			const newData: ChordWithNotes[] = [];

			for (const pc of result.chords) {
				newChords.push(pc.display);
				const notes = getChordNotes(pc.root, pc.quality, accidentals);
				let voicingArr = getVoicingNotes(notes, voicing, pc.root, accidentals);
				// Voice-led rearrangement: minimise movement from previous chord
				if (voiceLeadingEnabled && newData.length > 0) {
					voicingArr = computeVoiceLeadVoicing(newData[newData.length - 1].voicing, voicingArr, accidentals);
				}
				newData.push({ chord: pc.display, root: pc.root, type: pc.quality, notes, voicing: voicingArr });
			}

			chords = newChords;
			chordsWithNotes = newData;
			return;
		}

		// Random mode (original logic, with optional adaptive weighting)
		let available = CHORDS_BY_DIFFICULTY[difficulty];
		// Coach 'new'/'focus' blocks pin the pool to the promised quality so the
		// block delivers exactly what its label says. Fall back to the full pool
		// if the filter would empty it (defensive — shouldn't happen).
		if (qualityFilter.length > 0) {
			const filtered = available.filter((c) => qualityFilter.includes(c.display));
			if (filtered.length > 0) available = filtered;
		}
		const pool = getNotePool(accidentals);
		const newChords: string[] = [];
		const newData: ChordWithNotes[] = [];
		let last = '';

		// Adaptive mode: use weighted selection
		if (adaptiveEnabled && progressionMode === 'random') {
			// Filter history to current voicing — so switching voicing type treats chords as "new"
			const allHistory = loadHistory();
			const matchingHistory = allHistory.filter(s => s.settings.voicing === voicing);
			const history = matchingHistory.flatMap(s => s.chordTimings ?? []);
			const weighted = getWeightedChordPool(history, available, pool, focusRoots.length > 0 ? focusRoots : undefined);
			let lastRoot = '';
			let lastDisplay = '';

			for (let i = 0; i < totalChords; i++) {
				const pick = pickWeightedChord(weighted, lastRoot, lastDisplay);
				const displayQuality = CHORD_NOTATIONS[notation][pick.display] || pick.display;
				const name = `${pick.root}${displayQuality}`;
				lastRoot = pick.root;
				lastDisplay = pick.display;

				newChords.push(name);
				const notes = getChordNotes(pick.root, pick.display, accidentals);
				let voicingArr = getVoicingNotes(notes, voicing, pick.root, accidentals);
				if (voiceLeadingEnabled && newData.length > 0) {
					voicingArr = computeVoiceLeadVoicing(newData[newData.length - 1].voicing, voicingArr, accidentals);
				}
				newData.push({ chord: name, root: pick.root, type: pick.display, notes, voicing: voicingArr });
			}

			chords = newChords;
			chordsWithNotes = newData;
			return;
		}

		for (let i = 0; i < totalChords; i++) {
			let name = '';
			let attempts = 0;
			do {
				const note = pool[Math.floor(Math.random() * pool.length)];
				const ct = available[Math.floor(Math.random() * available.length)];
				const display = CHORD_NOTATIONS[notation][ct.display] || ct.display;
				name = `${note}${display}`;
				attempts++;
			} while (name === last && attempts < 50);

			last = name;
			newChords.push(name);

			const match = name.match(/^([A-G][#b]?)(.+)$/);
			if (match) {
				const root = match[1];
				const displayType = match[2];
				const quality = displayToQuality(displayType, notation);
				const notes = getChordNotes(root, quality, accidentals);
				let voicingArr = getVoicingNotes(notes, voicing, root, accidentals);
				if (voiceLeadingEnabled && newData.length > 0) {
					voicingArr = computeVoiceLeadVoicing(newData[newData.length - 1].voicing, voicingArr, accidentals);
				}
				newData.push({ chord: name, root, type: quality, notes, voicing: voicingArr });
			}
		}

		chords = newChords;
		chordsWithNotes = newData;
	}

	function startGame() {
		generateChords();
		currentIdx = 0;
		playPhase = 'playing';
		screen = 'playing';
		timerStarted = false;
		paused = false;
		pauseAccumulated = 0;
		pauseStart = 0;
		startTime = 0;
		now = 0;
		chordTimings = [];
		chordStartTime = 0;
		midiCorrectCount = 0;
		midiTotalAttempts = 0;
		midiMatchResult = null;
		midi.releaseAll();

		// Reset new mode state
		inTimeBeatCount = 0;
		inTimeBarCount = 0;
		inTimeTimingOffsets = [];
		inTimeChordPlayedAt = null;
		inTimeBeatOneTime = 0;
		earTrainingRevealed = false;
		earTrainingCorrect = 0;
		earTrainingTotal = 0;
		voiceLeadingInfo = null;
		vlValidation = null;
		vlMovementScores = [];
		vlOptimalCount = 0;

		// Compute stable keyboard range for the entire session (prevents layout-shift between chords)
		if (chordsWithNotes.length > 0) {
			sessionOctaves = computeSessionOctaves(chordsWithNotes, accidentals);
		} else {
			sessionOctaves = null;
		}

		// Re-register MIDI handler (ProgressionPlayer may have overwritten it)
		midi.onNotes(handleMidiNotes);
		audioInput.onNotes(handleAudioInputNotes);
		if (timerHandle) clearInterval(timerHandle);
		timerHandle = null;

		// Init input based on mode
		if (inputMode === 'midi' && midiState === 'disconnected') {
			midi.init();
		} else if (inputMode === 'microphone' && (micState === 'idle' || micState === 'error')) {
			audioInput.init();
		}

		// Persist settings
		saveSettings({
			difficulty,
			notation,
			voicing,
			displayMode,
			accidentals,
			notationSystem,
			totalChords,
			progressionMode,
			midiEnabled: inputActive,
			inputMode,
			customDegrees,
		});
	}

	/** User clicks "Start" to begin timing */
	function beginTimer() {
		timerStarted = true;
		startTime = Date.now();
		now = startTime;
		chordStartTime = startTime;

		timerHandle = setInterval(() => {
			if (screen === 'playing' && !paused) now = Date.now();
		}, 100);

		// Play first chord audio
		if (audioEnabled && chordsWithNotes[0]) {
			suppressMicForPlayback();
			playChord(chordsWithNotes[0].voicing).catch(() => {});
		}

		// In-Time mode: always start metronome & use beat callback for chord changes
		if (inTimeMode) {
			inTimeBeatCount = 0;
			inTimeBarCount = 0;
			inTimeBeatOneTime = Date.now();
			metronomeEnabled = true;
			startMetronome(metronomeBpm, 4, (beat, time) => {
				currentBeat = beat;
				handleInTimeBeat(beat, time);
			});
		} else if (metronomeEnabled) {
			// Standard metronome
			startMetronome(metronomeBpm, 4, (beat) => {
				currentBeat = beat;
			});
		}
	}

	/** Show dialog asking to restart with look-ahead enabled; pauses game first. */
	function promptLookAhead() {
		if (screen !== 'playing' || !timerStarted || paused) return;
		togglePause(); // pause so the metronome stops while the dialog is open
		showLookAheadConfirm = true;
	}

	/** Confirmed: enable look-ahead, restart, auto-begin timing. */
	function confirmLookAhead() {
		showLookAheadConfirm = false;
		inTimeLookAhead = true;
		startGame();
		beginTimer(); // skip the manual "Start" click
	}

	/** Cancelled: close dialog and resume from where we left off. */
	function cancelLookAhead() {
		showLookAheadConfirm = false;
		if (paused) togglePause();
	}

	/** Open settings modal from an active game screen (auto-pauses) */
	function openSettingsFromGame() {
		settingsOpenedFromScreen = screen;
		// Auto-pause if timer is running and not already paused
		if (timerStarted && !paused) {
			togglePause();
		}
		settingsOpen = true;
	}

	/** Close settings modal — resumes game if opened from gameplay */
	function closeSettingsModal() {
		settingsOpen = false;
		if (settingsOpenedFromScreen) {
			// Resume if we auto-paused
			if (timerStarted && paused) {
				togglePause();
			}
			settingsOpenedFromScreen = null;
		}
	}

	/** Toggle pause/resume */
	function togglePause() {
		if (!timerStarted) return;
		if (paused) {
			// Resume
			pauseAccumulated += Date.now() - pauseStart;
			paused = false;
			if (metronomeEnabled) {
				if (inTimeMode) {
					startMetronome(metronomeBpm, 4, (beat, time) => {
						currentBeat = beat;
						handleInTimeBeat(beat, time);
					});
				} else {
					startMetronome(metronomeBpm, 4, (beat) => { currentBeat = beat; });
				}
			}
		} else {
			// Pause
			paused = true;
			pauseStart = Date.now();
			stopMetronome();
			stopAll();
			currentBeat = 0;
		}
	}

	function startPlan(plan: PracticePlan) {
		// Adaptive coaching is Pro — free users get one teaser run, then a prompt.
		if (plan.id === 'adaptive-drill' && !gatePro('adaptive-difficulty', { teaserable: true })) {
			return;
		}
		// Remember (for the post-session teaser) whether this run was the free taste.
		sessionWasAdaptive =
			plan.id === 'adaptive-drill' && !canUse('adaptive-difficulty') && !hasUsedTeaser('adaptive-difficulty');

		// Clear focus unless this is an adaptive drill with focus
		if (plan.id !== 'adaptive-drill') {
			focusRoots = [];
			focusVoicing = null;
		}
		// Manual plans never pin a single quality — that's a Coach-only restriction.
		qualityFilter = [];
		// Apply plan settings
		difficulty = plan.settings.difficulty;
		notation = plan.settings.notation;
		// Use focused voicing if set (e.g. from quick start weak-spot drill)
		voicing = (focusVoicing as VoicingType) ?? plan.settings.voicing;
		displayMode = plan.settings.displayMode;
		accidentals = plan.settings.accidentals;
		progressionMode = plan.settings.progressionMode;
		totalChords = plan.settings.totalChords;

		// Apply special mode settings based on plan ID
		if (plan.id === 'in-time-comping') {
			inTimeMode = true;
			inTimeBars = 2;
			metronomeBpm = 100;
			audioEnabled = false; // timing exercise — audio distracts more than it helps
		} else {
			inTimeMode = false;
		}

		if (plan.id === 'adaptive-drill') {
			adaptiveEnabled = true;
		} else {
			adaptiveEnabled = false;
		}

		if (plan.id === 'voice-leading-flow') {
			voiceLeadingEnabled = true;
			vlMode = plan.settings.vlMode ?? vlMode;
		} else {
			voiceLeadingEnabled = false;
		}

		if (plan.id === 'ear-check') {
			// Track plan usage for suggestions
			recordPlanUsed(plan.id);
			startEarTraining();
			return;
		}

		// Track plan usage for suggestions
		recordPlanUsed(plan.id);

		// Start the game with plan settings
		startGame();
	}

	/**
	 * Build today's coach announcement string for the QuickStart hero.
	 * Uses the persisted CoachState + current history/profile to preview the plan,
	 * then localizes its say-key. Returns '' if the profile isn't ready yet.
	 */
	function coachAnnouncement(): string {
		if (!habitProfile) return '';
		try {
			const state = loadCoachState() ?? createInitialCoachState();
			const plan = buildCoachPlan(
				loadHistory(),
				habitProfile,
				undefined,
				state,
				coachParams,
				Date.now(),
			);
			const { sayKey, sayParams } = describeCoachPlan(plan);
			return t(sayKey, localizeCoachParams(sayParams));
		} catch {
			return '';
		}
	}

	/** True once there's enough history to name any weak spots. */
	function hasWeakSpots(): boolean {
		return analyzeWeakSpots(loadHistory(), 5).length > 0;
	}

	/**
	 * Re-run as a focused, answer-hidden drill on the player's weakest chords.
	 * Mirrors iOS makeWeakDrillPlan: pick the voicing that dominates the weak
	 * list, drill its worst roots (10× weight), and hide the answer ('verify')
	 * so it's a real test, not a copy. No-op if there isn't enough history.
	 */
	function startWeakDrill() {
		const spots = analyzeWeakSpots(loadHistory(), 5);
		if (spots.length === 0) return;

		// Group by voicing; drill the voicing with the most weak spots.
		const byVoicing = new Map<string, typeof spots>();
		for (const s of spots) {
			const arr = byVoicing.get(s.voicing) ?? [];
			arr.push(s);
			byVoicing.set(s.voicing, arr);
		}
		let bestVoicing = spots[0].voicing;
		let bestGroup = spots;
		for (const [v, group] of byVoicing) {
			if (group.length > bestGroup.length) {
				bestVoicing = v as VoicingType;
				bestGroup = group;
			}
		}
		focusRoots = bestGroup.slice(0, 5).map((s) => s.root);
		focusVoicing = bestVoicing;

		const adaptive = PRACTICE_PLANS.find((p) => p.id === 'adaptive-drill');
		if (!adaptive) return;
		// Hide the answer for the weak drill — a real test, not look-and-copy.
		startPlan({ ...adaptive, settings: { ...adaptive.settings, displayMode: 'verify' } });
	}

	// ─── Coach (Auto-Mode) session flow ──────────────────────────
	// The Coach plays a CoachPlan's blocks in sequence. Each block is a normal drill
	// run with the block's settings + focus plumbing. Between blocks we show a mini
	// transition screen; after the last block, applySessionToCoach + a teacher screen.
	//
	// Telemetry hook points:
	//   startCoachSession()  → trackCoachEvent('session_start', …)
	//   applyCoachBlockResult() (per block) → trackCoachEvent('block_result', …) [+ 'calibration_result' on first calibration]
	//   finishCoachSession() → trackCoachEvent('session_end' + 'coach_decision', …)
	//   applyCoachFeedback() → trackCoachEvent('feedback_valve', …)
	//   resetToSetup() (Coach mid-block quit path — Escape/back while screen === 'playing')
	//     → trackCoachEvent('quit_midblock', …)

	/** Fraction of chords answered correctly this session, or undefined if unknown (no verify/MIDI grading). */
	function correctRateOf(session: SessionResult): number | undefined {
		const graded = (session.chordTimings ?? []).filter((t) => t.correct !== undefined);
		if (graded.length === 0) return undefined;
		return graded.filter((t) => t.correct).length / graded.length;
	}

	/**
	 * Diffs two CoachStates' unit progress against the skill ladder to emit one
	 * 'coach_decision' telemetry event per unit transition (promoted/held/demoted/placed),
	 * mirroring teacherFeedback()'s transition logic but keeping the unitId (which the
	 * localized TeacherStatement params drop in favor of quality/voicing display strings).
	 */
	function trackCoachDecisions(before: CoachState, after: CoachState): void {
		const ladder = buildSkillLadder();
		const justCalibrated = !before.calibrated && after.calibrated;
		for (const unit of ladder) {
			const b = before.unitStates[unit.id]?.state ?? 'locked';
			const a = after.unitStates[unit.id]?.state ?? 'locked';
			if (b === a) continue;
			if (a === 'mastered') {
				trackCoachEvent('coach_decision', {
					decision: justCalibrated ? 'placed' : 'promoted',
					unitId: unit.id,
				});
			} else if (b === 'mastered' && a === 'practicing') {
				trackCoachEvent('coach_decision', { decision: 'demoted', unitId: unit.id });
			}
		}
		// Held frontier: holds increased on the pre-session frontier without a promotion.
		const frontierId = before.lastPlan?.frontierUnitId;
		if (frontierId) {
			const bh = before.unitStates[frontierId]?.holds ?? 0;
			const ah = after.unitStates[frontierId]?.holds ?? 0;
			if (ah > bh && after.unitStates[frontierId]?.state !== 'mastered') {
				trackCoachEvent('coach_decision', { decision: 'held', unitId: frontierId });
			}
		}
	}

	/**
	 * Entry point for the Auto-Mode "Weiter üben" hero. Loads (or seeds) the
	 * CoachState, builds today's plan and starts the first block. No-op if the
	 * plan has no blocks (defensive — the engine always returns ≥1).
	 */
	function startCoachSession() {
		const state = loadCoachState() ?? createInitialCoachState();
		const plan = buildCoachPlan(
			loadHistory(),
			habitProfile,
			undefined,
			state,
			coachParams,
			Date.now(),
		);
		if (!plan.blocks.length) return;

		coachStateBefore = { ...state, lastPlan: plan };
		coachStateWorking = { ...state };
		coachPlan = plan;
		coachBlockIdx = 0;
		coachMode = true;
		coachTransition = null;
		coachFeedback = [];
		coachFeedbackGiven = false;
		coachSessionBlocks = [];
		coachSessionStartedAt = Date.now();
		trackCoachEvent('session_start', {
			estMinutes: plan.estMinutes,
			blocks: plan.blocks.map((b) => b.kind),
			frontierUnitId: plan.frontierUnitId,
			dayIndex: state.dayIndex,
		});
		startCoachBlock(0);
	}

	/** Map a CoachBlock's settings onto the drill state and start it. */
	function startCoachBlock(idx: number) {
		if (!coachPlan) return;
		const block = coachPlan.blocks[idx];
		if (!block) return;
		coachBlockIdx = idx;

		const s = block.settings;
		difficulty = s.difficulty;
		notation = s.notation;
		voicing = (block.focusVoicing as VoicingType) ?? s.voicing;
		displayMode = s.displayMode;
		accidentals = s.accidentals;
		progressionMode = s.progressionMode;
		totalChords = block.targetChords || s.totalChords;

		// Focus plumbing (same axes the weak-drill uses). Adaptive weighting only
		// bites when progressionMode === 'random' — exactly as intended.
		focusRoots = block.focusRoots ?? [];
		focusVoicing = block.focusVoicing ?? null;
		qualityFilter = block.focusQualities ?? [];
		adaptiveEnabled = s.progressionMode === 'random';

		// Coach never uses the special exercise sub-modes.
		inTimeMode = false;
		voiceLeadingEnabled = false;

		startGame();
	}

	/**
	 * Called from endGame() when a Coach block finishes. Aggregates one SessionResult
	 * per block into the CoachState (keeps existing history semantics: one row/block),
	 * then either shows the between-block transition or ends the session.
	 */
	function applyCoachBlockResult(session: SessionResult) {
		if (!coachPlan || !coachStateWorking) return;
		coachSessionBlocks = [...coachSessionBlocks, session];
		const block = coachPlan.blocks[coachBlockIdx];
		trackCoachEvent('block_result', {
			kind: block.kind,
			unitId: coachPlan.frontierUnitId,
			chords: session.totalChords,
			avgMs: session.avgMs,
			correctRate: correctRateOf(session),
			completed: session.totalChords >= block.targetChords,
		});
		const wasCalibrated = coachStateWorking.calibrated;
		coachStateWorking = applySessionToCoach(
			coachStateWorking,
			coachPlan,
			session,
			coachParams,
			Date.now(),
		);
		saveCoachState(coachStateWorking);
		if (!wasCalibrated && coachStateWorking.calibrated) {
			const placedUnits = Object.values(coachStateWorking.unitStates).filter(
				(u) => u.state === 'mastered',
			).length;
			trackCoachEvent('calibration_result', {
				placedUnits,
				frontierIndex: coachStateWorking.frontierIndex,
			});
		}

		const nextIdx = coachBlockIdx + 1;
		if (nextIdx < coachPlan.blocks.length) {
			// Show a 1–2 line transition, auto-advancing after ~2.5s (tap to skip).
			coachTransition = {
				doneKind: coachPlan.blocks[coachBlockIdx].kind,
				next: coachPlan.blocks[nextIdx],
			};
			if (coachTransitionTimeout) clearTimeout(coachTransitionTimeout);
			coachTransitionTimeout = setTimeout(() => advanceCoachBlock(), 2500);
		} else {
			finishCoachSession(session);
		}
	}

	/** Dismiss the transition screen and start the next block. */
	function advanceCoachBlock() {
		if (coachTransitionTimeout) {
			clearTimeout(coachTransitionTimeout);
			coachTransitionTimeout = null;
		}
		if (!coachPlan) return;
		const nextIdx = coachBlockIdx + 1;
		coachTransition = null;
		if (nextIdx < coachPlan.blocks.length) {
			startCoachBlock(nextIdx);
		}
	}

	/** Last block done: build teacher feedback, persist, land on the feedback screen. */
	function finishCoachSession(lastSession: SessionResult) {
		if (!coachStateBefore || !coachPlan || !coachStateWorking) return;
		coachFeedback = teacherFeedback(
			coachStateBefore,
			coachStateWorking,
			lastSession,
			coachParams,
		);
		// The system reads how the session went — the UI never asks "too easy?".
		const assessed = assessSession(coachStateWorking, lastSession, coachParams);
		coachVerdict = assessed.verdict;
		coachStateWorking = assessed.state; // carries struggleStreak forward
		saveCoachState(coachStateWorking);

		const totalChords = coachSessionBlocks.reduce((s, b) => s + b.totalChords, 0);
		const totalMs = coachSessionBlocks.reduce((s, b) => s + b.avgMs * b.totalChords, 0);
		trackCoachEvent('session_end', {
			durationMs: Date.now() - coachSessionStartedAt,
			totalChords,
			avgMs: totalChords > 0 ? totalMs / totalChords : 0,
			completedBlocks: coachSessionBlocks.length,
			totalBlocks: coachPlan.blocks.length,
			frontierUnitId: coachPlan.frontierUnitId,
		});
		trackCoachDecisions(coachStateBefore, coachStateWorking);
		screen = 'coach-feedback';
	}

	/** Feedback valve: biases the controller. Only 'tooHard' is user-triggered now
	 *  (the "start easier" option shown after sustained struggle). */
	function applyCoachFeedback(signal: FeedbackSignal) {
		if (!coachStateWorking || coachFeedbackGiven) return;
		coachStateWorking = applyFeedback(coachStateWorking, signal, coachParams);
		saveCoachState(coachStateWorking);
		coachFeedbackGiven = true;
		trackCoachEvent('feedback_valve', { signal });
	}

	/** "Yes, start easier" after the struggling offer → bias down, then next session. */
	function startEasierAndContinue() {
		applyCoachFeedback('tooHard');
		restartCoachSession();
	}

	/** Continue straight into the next building session ("Keep going" / "Weiter geht's"). */
	function restartCoachSession() {
		endCoachMode();
		startCoachSession();
	}

	/** Leave Coach mode cleanly (from feedback screen "Fertig" or on abort). */
	function endCoachMode() {
		if (coachTransitionTimeout) {
			clearTimeout(coachTransitionTimeout);
			coachTransitionTimeout = null;
		}
		coachMode = false;
		coachPlan = null;
		coachTransition = null;
		coachFeedback = [];
		coachStateBefore = null;
		coachStateWorking = null;
	}

	function nextChord() {
		if (screen !== 'playing' || paused) return;

		// Auto-start timer on first interaction if not started
		if (!timerStarted) {
			beginTimer();
			return; // First click just starts the timer, chord is already shown
		}

		// Clear auto-advance timeout
		if (autoAdvanceTimeout) {
			clearTimeout(autoAdvanceTimeout);
			autoAdvanceTimeout = null;
		}

		// Verify mode: first press reveals, second advances. With no input device,
		// grade the built tap-guess on reveal (so recall is measured, not read speed).
		if (displayMode === 'verify' && playPhase === 'playing' && !inputActive) {
			submitTapGuess();
			return;
		}

		playPhase = 'playing';
		midiMatchResult = null;
		vlValidation = null;
		tapGuessNotes = new Set();
		tapGuessResult = null;
		midi.releaseAll();

		// Record timing for the chord we're leaving
		const nowMs = Date.now();
		if (currentData) {
			pushTiming(currentData, nowMs - chordStartTime);
		}
		currentChordCorrect = undefined; // fresh verdict for the next chord
		chordStartTime = nowMs;

		if (currentIdx < actualTotalChords - 1) {
			currentIdx++;
			// Compute voice leading for the new chord
			updateVoiceLeading();
			// Play chord audio on advance
			if (audioEnabled && chordsWithNotes[currentIdx]) {
				suppressMicForPlayback();
				playChord(chordsWithNotes[currentIdx].voicing).catch(() => {});
			}
		} else {
			endGame();
		}
	}

	function endGame() {
		endTime = Date.now();
		// In Coach mode the block loop decides the next screen (transition or
		// feedback); a normal drill lands on the results screen.
		if (!coachMode) screen = 'finished';

		// Record timing for the last chord
		if (currentData) {
			pushTiming(currentData, endTime - chordStartTime);
		}
		currentChordCorrect = undefined;

		if (timerHandle) clearInterval(timerHandle);
		timerHandle = null;
		if (autoAdvanceTimeout) {
			clearTimeout(autoAdvanceTimeout);
			autoAdvanceTimeout = null;
		}
		stopMetronome();
		currentBeat = 0;

		// Save session to progress history
		const sessionResult = saveSession({
			timestamp: Date.now(),
			elapsedMs: endTime - startTime,
			totalChords: actualTotalChords,
			avgMs: (endTime - startTime) / actualTotalChords,
			chordTimings: [...chordTimings],
			blockKind: coachMode ? coachPlan?.blocks[coachBlockIdx]?.kind : undefined,
			settings: {
				difficulty,
				notation,
				voicing,
				displayMode,
				accidentals,
				progressionMode,
			},
			midi: {
				enabled: inputActive,
				accuracy: midiAccuracy,
			},
		});

		// Update streak
		streak = recordPracticeDay();

		// ─── Habit Engine: process session ───────────────────────
		if (habitProfile) {
			// Compute previous best avg for PB detection
			const history = loadHistory();
			const sameKey = history.filter(h => h.id !== sessionResult.id && h.settings.difficulty === difficulty && h.settings.voicing === voicing && h.settings.progressionMode === progressionMode);
			const previousBestAvg = sameKey.length > 0 ? Math.min(...sameKey.map(h => h.avgMs)) : undefined;
			const habitResult = processSessionHabits(sessionResult, previousBestAvg);
			habitProfile = loadHabitProfile(); // reload after processing
			if (habitResult.celebrations.length > 0) {
				pendingCelebrations = habitResult.celebrations;
			}
		}

		// Refresh dashboard stats
		dashStats = computeStats(loadHistory());

		// Adaptive teaser: the free user just felt the coaching — convert now.
		if (sessionWasAdaptive) {
			markTeaserUsed('adaptive-difficulty');
			sessionWasAdaptive = false;
			setTimeout(() => openUpgrade('adaptive-difficulty', true), 900);
		}

		// Coach mode: fold this block's result into the CoachState and drive the
		// block loop (transition screen, or the teacher-feedback screen at the end).
		if (coachMode) applyCoachBlockResult(sessionResult);
	}

	function restartGame() {
		startGame();
	}

	function resetToSetup() {
		// Leaving mid-Coach-session (back / Escape): persist the progress made so
		// far, then drop out of Coach mode. Safe if Coach isn't active.
		if (coachMode) {
			// Only a genuine mid-block quit (still on the 'playing' screen — not the
			// between-block transition or the end-of-session feedback screen) counts
			// as 'quit_midblock'.
			if (screen === 'playing') {
				const block = coachPlan?.blocks[coachBlockIdx];
				if (block) {
					trackCoachEvent('quit_midblock', {
						kind: block.kind,
						atChord: currentIdx,
						targetChords: block.targetChords,
					});
				}
			}
			if (coachStateWorking) saveCoachState(coachStateWorking);
			endCoachMode();
		}
		screen = 'setup';
		currentIdx = 0;
		chords = [];
		chordsWithNotes = [];
		midiMatchResult = null;
		timerStarted = false;
		paused = false;
		pauseAccumulated = 0;
		showExerciseInfo = false;
		voiceLeadingInfo = null;
		vlValidation = null;
		earTrainingRevealed = false;
		if (timerHandle) clearInterval(timerHandle);
		timerHandle = null;
		if (autoAdvanceTimeout) {
			clearTimeout(autoAdvanceTimeout);
			autoAdvanceTimeout = null;
		}
		stopMetronome();
		stopAll();
		currentBeat = 0;
		// Re-register main MIDI/audio handler (ear training may have overridden it)
		midi.onNotes(handleMidiNotes);
		audioInput.onNotes(handleAudioInputNotes);
	}

	// ─── Custom Progression handlers ─────────────────────────────
	function openCustomEditor() {
		// Custom progressions are Pro (no teaser — a half-built editor has no aha).
		if (!gatePro('custom-progressions')) return;
		screen = 'custom-editor';
	}

	function startCustomProgression(chordsToPlay: CustomChord[], bpm: number, loopCount: number, progName: string) {
		customChords = chordsToPlay;
		customBpm = bpm;
		customLoops = loopCount;
		customName = progName;
		customEvaluation = null;
		screen = 'custom-playing';
	}

	function handleCustomStop(evaluation: SessionEvaluation | null) {
		if (evaluation) {
			customEvaluation = evaluation;
			screen = 'custom-results';
			// Count as practice day
			streak = recordPracticeDay();
		} else {
			screen = 'custom-editor';
		}
	}

	function replayCustom() {
		screen = 'custom-playing';
	}

	function backToCustomEditor() {
		screen = 'custom-editor';
	}

	// ─── MIDI callbacks ──────────────────────────────────────────
	function handleMidiNotes(activeNotes: Set<number>) {
		midiActiveNotes = new Set(activeNotes);

		if (screen !== 'playing' || !currentData || inputMode !== 'midi') return;

		handleActiveNotesInput(activeNotes, midi);
	}

	/** Callback for the AudioInputService note events */
	function handleAudioInputNotes(activeNotes: Set<number>) {
		midiActiveNotes = new Set(activeNotes);

		if (screen !== 'playing' || !currentData || inputMode !== 'microphone') return;

		handleActiveNotesInput(activeNotes, audioInput);
	}

	/**
	 * Core validation logic — shared between MIDI and audio input.
	 * `service` is the active input provider (MidiService or AudioInputService), exposing
	 * the same checkChord / checkChordLenient / checkChordWithBass interface.
	 */
	function handleActiveNotesInput(
		activeNotes: Set<number>,
		service: { checkChordLenient: (notes: string[]) => ChordMatchResult; checkChordWithBass: (notes: string[], bass: string) => ChordMatchResult },
	) {
		if (!currentData) return;

		// ── Voice Leading modes B/C: custom validation ──
		if (voiceLeadingEnabled && vlMode !== 'guided' && activeNotes.size > 0) {
			// VL modes only work with MIDI (they need note-by-note precision)
			if (inputMode === 'midi') handleVLModeMidi(activeNotes);
			return;
		}

		// ── Standard / Guided mode validation ──
		let result: ChordMatchResult;
		if (voicing.startsWith('inversion-') && currentData.voicing.length > 0) {
			result = service.checkChordWithBass(currentData.voicing, currentData.voicing[0]);
		} else {
			result = service.checkChordLenient(currentData.voicing);
		}
		midiMatchResult = result;

		if (result.correct && activeNotes.size > 0) {
			midiTotalAttempts++;
			midiCorrectCount++;
			currentChordCorrect = true;

			if (inTimeMode && inTimeChordPlayedAt === null) {
				const timeSinceBeatOne = Date.now() - inTimeBeatOneTime;
				inTimeChordPlayedAt = timeSinceBeatOne;
			}

			if (!inTimeMode && !autoAdvanceTimeout) {
				autoAdvanceTimeout = setTimeout(() => {
					autoAdvanceTimeout = null;
					nextChord();
				}, 400);
			}
		} else if (activeNotes.size > 0 && result.accuracy < 1) {
			const expectedCount = currentData.voicing.length;
			if (activeNotes.size >= expectedCount) {
				midiTotalAttempts++;
				// A full-note attempt that didn't match is a miss — but never
				// downgrade a chord the player already got right this turn.
				if (currentChordCorrect !== true) currentChordCorrect = false;
			}
		}
	}

	/**
	 * Handle MIDI input for VL modes B (Find Inversion) and C (Free).
	 */
	function handleVLModeMidi(activeNotes: Set<number>) {
		if (!currentData) return;
		const midiNotes = [...activeNotes];
		const expectedCount = vlMode === 'free' ? 3 : currentData.voicing.length; // at least 3 notes for free mode

		// Wait until player has enough notes held
		if (midiNotes.length < expectedCount) {
			vlValidation = null;
			return;
		}

		const prevVoicing = currentIdx > 0 ? chordsWithNotes[currentIdx - 1]?.voicing ?? [] : [];

		if (vlMode === 'find-inversion') {
			// Get the base voicing notes (before voice-led rearrangement)
			const baseNotes = getVoicingNotes(currentData.notes, voicing, currentData.root, accidentals);
			const result = validateFindInversion(midiNotes, baseNotes, prevVoicing, currentData.voicing);
			vlValidation = result;

			if (result.valid) {
				midiTotalAttempts++;
				midiCorrectCount++;
				currentChordCorrect = true;
				vlMovementScores.push(result.playerMovement);
				if (result.grade === 'optimal') vlOptimalCount++;

				// Set MIDI match result for compatibility
				midiMatchResult = { correct: true, missing: [], extra: [], accuracy: 1 };

				// Auto-advance (longer delay for feedback reading)
				if (!autoAdvanceTimeout) {
					autoAdvanceTimeout = setTimeout(() => {
						autoAdvanceTimeout = null;
						nextChord();
					}, result.grade === 'optimal' ? 600 : 1200);
				}
			} else {
				midiMatchResult = { correct: false, missing: [], extra: [], accuracy: 0 };
				midiTotalAttempts++;
				if (currentChordCorrect !== true) currentChordCorrect = false;
			}
		} else if (vlMode === 'free') {
			// Get all valid pitch-class sets for this chord
			const validSets = getValidPCSets(currentData.root, currentData.type, accidentals);
			const result = validateFreeVoicing(midiNotes, validSets, prevVoicing);
			vlValidation = result;

			if (result.valid) {
				midiTotalAttempts++;
				midiCorrectCount++;
				currentChordCorrect = true;
				vlMovementScores.push(result.playerMovement);

				midiMatchResult = { correct: true, missing: [], extra: [], accuracy: 1 };

				if (!autoAdvanceTimeout) {
					autoAdvanceTimeout = setTimeout(() => {
						autoAdvanceTimeout = null;
						nextChord();
					}, 800);
				}
			} else {
				midiMatchResult = { correct: false, missing: [], extra: [], accuracy: 0 };
				if (midiNotes.length >= 3) {
					midiTotalAttempts++;
					if (currentChordCorrect !== true) currentChordCorrect = false;
				}
			}
		}
	}

	function handleMidiConnect() {
		midi.init();
	}

	function handleMidiSelectDevice(deviceId: string) {
		midi.selectDevice(deviceId);
		midiSoundEnabled = midiSoundEngine.setDevice(deviceId);
	}

	// ─── Audio helpers ───────────────────────────────────────────
	function toggleMetronome() {
		if (metronomeEnabled) {
			stopMetronome();
			metronomeEnabled = false;
			currentBeat = 0;
		} else {
			metronomeEnabled = true;
			startMetronome(metronomeBpm, 4, (beat) => {
				currentBeat = beat;
			});
		}
	}

	function updateBpm(newBpm: number) {
		metronomeBpm = Math.max(40, Math.min(240, newBpm));
		if (isMetronomeRunning()) {
			setMetronomeBpm(metronomeBpm);
		}
	}

	/** Re-play current chord audio on demand */
	function replayChord() {
		if (currentData) {
			suppressMicForPlayback();
			playChord(currentData.voicing);
		}
	}

	// ─── In-Time Mode Logic ──────────────────────────────────────

	/** Called on each metronome beat in In-Time mode */
	function handleInTimeBeat(beat: number, time: number) {
		if (!inTimeMode || screen !== 'playing' || paused || !timerStarted) return;

		if (beat === 1) {
			inTimeBeatOneTime = Date.now();
			inTimeBarCount++;

			// Check if it's time to change chords
			if (inTimeBarCount > inTimeBars) {
				inTimeBarCount = 1;

				// Record timing accuracy for the chord we're leaving
				if (inTimeChordPlayedAt !== null) {
					// How close to beat 1 was the player? (lower = better)
					inTimeTimingOffsets.push(inTimeChordPlayedAt);
				} else {
					// Player didn't play — record a miss (max offset)
					inTimeTimingOffsets.push(999);
				}
				inTimeChordPlayedAt = null;

				// Compute voice leading before advancing
				if (voiceLeadingEnabled && currentData && currentIdx < actualTotalChords - 1) {
					const nextData = chordsWithNotes[currentIdx + 1];
					if (nextData) {
						voiceLeadingInfo = analyzeVoiceLeading(currentData.voicing, nextData.voicing);
					}
				} else {
					voiceLeadingInfo = null;
				}

				// Advance to next chord
				const nowMs = Date.now();
				if (currentData) {
					pushTiming(currentData, nowMs - chordStartTime);
				}
				currentChordCorrect = undefined;
				chordStartTime = nowMs;

				if (currentIdx < actualTotalChords - 1) {
					currentIdx++;
					midiMatchResult = null;
					inTimeChordPlayedAt = null;
					if (audioEnabled && chordsWithNotes[currentIdx]) {
						playChordAtTime(chordsWithNotes[currentIdx].voicing, '2n', time);
					}
					// Release all held notes so previous chord doesn't bleed into the new one.
					// The player needs to re-play to get feedback on the new chord.
					if (inputMode === 'midi') midi.releaseAll();
					else if (inputMode === 'microphone') audioInput.releaseAll();
				} else {
					endGame();
				}
			}
		}
	}

	// ─── Ear Training Mode Logic ─────────────────────────────────

	function startEarTraining() {
		generateChords();
		currentIdx = 0;
		playPhase = 'playing';
		screen = 'ear-training';
		timerStarted = false;
		paused = false;
		pauseAccumulated = 0;
		pauseStart = 0;
		startTime = 0;
		now = 0;
		chordTimings = [];
		chordStartTime = 0;
		midiCorrectCount = 0;
		midiTotalAttempts = 0;
		midiMatchResult = null;
		earTrainingRevealed = false;
		earTrainingCorrect = 0;
		earTrainingTotal = 0;
		earGuessNotes = new Set();
		earGuessResult = null;
		earSelectMode = false;
		voiceLeadingInfo = null;
		midi.releaseAll();
		audioInput.releaseAll();
		midi.onNotes(handleEarTrainingMidi);
		audioInput.onNotes(handleEarTrainingMidi);

		if (inputMode === 'midi' && midiState === 'disconnected') {
			midi.init();
		} else if (inputMode === 'microphone' && (micState === 'idle' || micState === 'error')) {
			audioInput.init();
		}
	}

	function beginEarTraining() {
		timerStarted = true;
		startTime = Date.now();
		now = startTime;
		chordStartTime = startTime;

		timerHandle = setInterval(() => {
			if (screen === 'ear-training' && !paused) now = Date.now();
		}, 100);

		// Play the first chord audio (player must identify it)
		if (chordsWithNotes[0]) {
			suppressMicForPlayback();
			playChord(chordsWithNotes[0].voicing).catch(() => {});
		}
	}

	function earTrainingReveal() {
		earTrainingRevealed = true;
		earTrainingTotal++;
	}

	function earTrainingNext() {
		// Record timing
		const nowMs = Date.now();
		if (currentData) {
			pushTiming(currentData, nowMs - chordStartTime);
		}
		currentChordCorrect = undefined;
		chordStartTime = nowMs;

		earTrainingRevealed = false;
		midiMatchResult = null;
		earGuessNotes = new Set();
		earGuessResult = null;
		midi.releaseAll();

		if (currentIdx < actualTotalChords - 1) {
			currentIdx++;
			// Play next chord
			if (chordsWithNotes[currentIdx]) {
				suppressMicForPlayback();
				playChord(chordsWithNotes[currentIdx].voicing).catch(() => {});
			}
		} else {
			endTime = Date.now();
			screen = 'finished';
			if (currentData) {
				pushTiming(currentData, endTime - chordStartTime);
			}
			currentChordCorrect = undefined;
			if (timerHandle) clearInterval(timerHandle);
			timerHandle = null;
			saveSession({
				timestamp: Date.now(),
				elapsedMs: endTime - startTime,
				totalChords: actualTotalChords,
				avgMs: (endTime - startTime) / actualTotalChords,
				chordTimings: [...chordTimings],
				settings: { difficulty, notation, voicing, displayMode, accidentals, progressionMode },
				midi: { enabled: inputActive, accuracy: earTrainingTotal > 0 ? Math.round((earTrainingCorrect / earTrainingTotal) * 100) : 0 },
			});
			streak = recordPracticeDay();
		}
	}

	function handleEarTrainingMidi(activeNotes: Set<number>) {
		midiActiveNotes = new Set(activeNotes);
		if (screen !== 'ear-training' || !currentData || !inputActive) return;

		const service = inputMode === 'microphone' ? audioInput : midi;
		const result = service.checkChordLenient(currentData.voicing);
		midiMatchResult = result;

		if (result.correct && activeNotes.size > 0) {
			earTrainingCorrect++;
			earTrainingTotal++;
			earTrainingRevealed = true;
			currentChordCorrect = true;

			// Auto-advance after a delay
			if (!autoAdvanceTimeout) {
				autoAdvanceTimeout = setTimeout(() => {
					autoAdvanceTimeout = null;
					earTrainingNext();
				}, 1200);
			}
		}
	}

	// ─── Clickable Piano (Ear Training without MIDI) ─────────────

	const CHROMATIC_NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

	/** Convert a keyboard chromatic index to a Tone.js note name (e.g. 0→"C3", 13→"C#4") */
	function chrIdxToNoteName(chrIdx: number): string {
		return CHROMATIC_NOTE_NAMES[chrIdx % 12] + (3 + Math.floor(chrIdx / 12));
	}

	/** Handle piano key click in ear training: preview or select */
	function handleEarPianoClick(chrIdx: number, shiftKey: boolean) {
		// Always play the note
		const noteName = chrIdxToNoteName(chrIdx);
		suppressMicForPlayback();
		playNote(noteName, '4n');

		// Determine if this click should toggle selection
		// Default: click = preview, shift+click = select
		// With earSelectMode toggled: click = select, shift+click = preview
		const selecting = earSelectMode ? !shiftKey : shiftKey;

		if (selecting) {
			const pc = chrIdx % 12;
			const next = new Set(earGuessNotes);
			if (next.has(pc)) next.delete(pc);
			else next.add(pc);
			earGuessNotes = next;
			earGuessResult = null;
		}
	}

	/** Submit the user's ear training guess (selected pitch classes vs expected) */
	function submitEarGuess() {
		if (earGuessNotes.size === 0 || !currentData) return;

		const expected = expectedPitchClasses;
		const correct = earGuessNotes.size === expected.size &&
			[...earGuessNotes].every((pc) => expected.has(pc));

		if (correct) {
			earGuessResult = 'correct';
			earTrainingCorrect++;
			earTrainingTotal++;
			earTrainingRevealed = true;
			currentChordCorrect = true;

			// Auto-advance after a delay
			if (!autoAdvanceTimeout) {
				autoAdvanceTimeout = setTimeout(() => {
					autoAdvanceTimeout = null;
					earTrainingNext();
				}, 1200);
			}
		} else {
			earGuessResult = 'wrong';
			if (currentChordCorrect !== true) currentChordCorrect = false;
			// Don't count as attempt yet — let user correct
			setTimeout(() => { if (earGuessResult === 'wrong') earGuessResult = null; }, 1500);
		}
	}

	/** Clear all selected guess notes */
	function clearEarGuess() {
		earGuessNotes = new Set();
		earGuessResult = null;
	}

	// ─── Tap-guess (main drill, verify mode, no MIDI/mic) ────────

	/** Toggle a pitch class in the tap-guess and preview the note. Starts the timer. */
	function handleTapPianoClick(chrIdx: number, _shiftKey: boolean) {
		if (!isTapGuessMode) return;
		suppressMicForPlayback();
		playNote(chrIdxToNoteName(chrIdx), '4n');
		const pc = chrIdx % 12;
		const next = new Set(tapGuessNotes);
		if (next.has(pc)) next.delete(pc); else next.add(pc);
		tapGuessNotes = next;
	}

	/**
	 * Reveal the answer after a tap-guess, grading it green/red first so weak-spot
	 * data reflects real recall. Mirrors iOS checkTapGuess + submitEarGuess.
	 */
	function submitTapGuess() {
		const expected = expectedPitchClasses;
		// An empty guess is a "Show me" (reveal without attempting) — not graded/counted.
		if (tapGuessNotes.size > 0) {
			const correct =
				expected.size > 0 &&
				tapGuessNotes.size === expected.size &&
				[...tapGuessNotes].every((pc) => expected.has(pc));
			tapGuessResult = correct ? 'correct' : 'wrong';
			currentChordCorrect = correct;
			midiTotalAttempts++;
			if (correct) midiCorrectCount++;
		}
		// Reveal (reuse verify phase) + play the chord; Space/Next advances from here.
		playPhase = 'verifying';
		if (audioEnabled && currentData) {
			suppressMicForPlayback();
			playChord(currentData.voicing).catch(() => {});
		}
	}

	/**
	 * "Show me the chord" — reveal the voicing on the keyboard without grading,
	 * regardless of what's been tapped. A dedicated help for beginners who don't
	 * yet recognise a chord name like "E♭9". Clears the pending guess so it isn't
	 * scored, then reveals.
	 */
	function revealTapGuess() {
		tapGuessNotes = new Set();
		submitTapGuess();
	}

	// ─── Voice Leading computation on chord change ───────────────

	/** Update voice leading info when chord index changes (standard mode) */
	function updateVoiceLeading() {
		if (!voiceLeadingEnabled || currentIdx === 0) {
			voiceLeadingInfo = null;
			return;
		}
		const prevData = chordsWithNotes[currentIdx - 1];
		const currData = chordsWithNotes[currentIdx];
		if (prevData && currData) {
			voiceLeadingInfo = analyzeVoiceLeading(prevData.voicing, currData.voicing);
		} else {
			voiceLeadingInfo = null;
		}
	}

	/** Change sound preset */
	function changeSoundPreset(preset: SoundPreset) {
		soundPreset = preset;
		setSoundPreset(preset);
		// Sync MIDI sound engine to same preset
		midiSoundEngine.preset = preset;
		// Play a preview chord
		if (currentData) {
			suppressMicForPlayback();
			playChord(currentData.voicing).catch(() => {});
		}
	}

	/** Toggle MIDI live sound on/off */
	function toggleMidiSound() {
		midiSoundEnabled = !midiSoundEnabled;
		midiSoundEngine.enabled = midiSoundEnabled;
	}

	// ─── Keyboard shortcut ───────────────────────────────────────
	function handleKeydown(e: KeyboardEvent) {
		if (e.code === 'Space' && screen === 'playing') {
			e.preventDefault();
			if (!timerStarted) {
				beginTimer();
			} else if (paused) {
				togglePause();
			} else {
				nextChord();
			}
		}
		// H = prompt Vorschau (look-ahead) — only meaningful in In-Time mode when not yet active
		if (e.code === 'KeyH' && screen === 'playing' && timerStarted && !paused && inTimeMode && !inTimeLookAhead) {
			e.preventDefault();
			promptLookAhead();
		}
		if (e.code === 'Space' && screen === 'ear-training') {
			e.preventDefault();
			if (!timerStarted) {
				beginEarTraining();
			} else if (earTrainingRevealed) {
				earTrainingNext();
			} else {
				earTrainingReveal();
			}
		}
		// Enter = submit ear training guess
		if (e.code === 'Enter' && screen === 'ear-training' && timerStarted && !earTrainingRevealed && earGuessNotes.size > 0) {
			e.preventDefault();
			submitEarGuess();
		}
		// Backspace = clear ear training guess
		if (e.code === 'Backspace' && screen === 'ear-training' && timerStarted && !earTrainingRevealed && earGuessNotes.size > 0) {
			e.preventDefault();
			clearEarGuess();
		}
		if (e.code === 'KeyP' && screen === 'playing' && timerStarted) {
			e.preventDefault();
			togglePause();
		}
		// S = open/close settings from active game screens
		if (e.code === 'KeyS' && (screen === 'playing' || screen === 'ear-training')) {
			e.preventDefault();
			if (settingsOpen) {
				closeSettingsModal();
			} else {
				openSettingsFromGame();
			}
		}
		// Escape: close settings modal first, close explain panel, otherwise back to setup
		if (e.code === 'Escape' && (screen === 'playing' || screen === 'ear-training')) {
			e.preventDefault();
			if (showExplain) {
				showExplain = false;
			} else if (settingsOpen) {
				closeSettingsModal();
			} else {
				resetToSetup();
			}
		}
		// ? (Shift+/) = toggle explain panel
		if (e.key === '?' && (screen === 'playing' || screen === 'ear-training') && currentData && !settingsOpen) {
			e.preventDefault();
			showExplain = !showExplain;
		}
	}

	onMount(() => {
		authState = getAuthState();
		initAuth();
		const authCleanup = onAuthChange((state) => {
			authState = state;
		});

		// Load persisted settings
		const saved = loadSettings();
		if (saved) {
			difficulty = saved.difficulty;
			notation = saved.notation;
			voicing = saved.voicing;
			displayMode = saved.displayMode;
			accidentals = saved.accidentals;
			notationSystem = (saved.notationSystem ?? 'international') as NotationSystem;
			totalChords = saved.totalChords;
			progressionMode = saved.progressionMode;
			// Migrate old midiEnabled flag to inputMode
			if (saved.inputMode) {
				inputMode = saved.inputMode;
			} else {
				inputMode = saved.midiEnabled ? 'midi' : 'none';
			}
			if (saved.customDegrees && saved.customDegrees.length > 0) customDegrees = saved.customDegrees;
		}

		// Load streak data
		const savedStreak = loadStreak();
		if (savedStreak) {
			streak = savedStreak;
		}

		// Load dashboard stats
		dashStats = computeStats(loadHistory());

		// ─── Habit Engine init ───────────────────────────────────
		habitProfile = loadHabitProfile();
		if (!habitProfile.onboardingDone) {
			showOnboarding = true;
		}
		// Schedule notifications if user opted in
		if (habitProfile.notificationsEnabled) {
			const dailyCleanup = scheduleDailyReminder(habitProfile);
			const streakCleanup = scheduleStreakSaver(habitProfile);
			notificationCleanup = dailyCleanup;
			streakSaverCleanup = streakCleanup;
		}
		// Register service worker for push notifications
		if ('serviceWorker' in navigator) {
			navigator.serviceWorker.register('/sw.js').catch(() => {});
		}

		// Coach remote config: fetch once, non-blocking. Defaults remain in effect
		// until this resolves (no wait, no spinner); on error/timeout it stays defaults.
		const deviceId = getDeviceId();
		if (deviceId) {
			fetchCoachParams(DEFAULT_COACH_PARAMS, getCohort(deviceId)).then((merged) => {
				coachParams = merged;
			});
		}

		// MIDI setup — always probe for devices so we can show auto-detection
		midi.onNotes(handleMidiNotes);
		midi.onNoteOn((note, velocity) => midiSoundEngine.noteOn(note, velocity));
		midi.onNoteOff((note) => midiSoundEngine.noteOff(note));
		midi.onCC((cc, value) => midiSoundEngine.controlChange(cc, value));
		midi.onConnection((state) => {
			midiState = state;
		});
		midi.onDevices((devices) => {
			midiDevices = [...devices];
			if (devices.length > 0) {
				midiSelectedDeviceId = midi.selectedDeviceId;
				midiSoundEnabled = midiSoundEngine.setDevice(midiSelectedDeviceId);
				// Auto-switch to MIDI input when a device is detected for the first time
				if (inputMode === 'none') {
					inputMode = 'midi';
				}
			}
		});

		midi.onDisconnect((deviceName) => {
			midiDisconnectToast = t('ui.disconnected_reconnect', { device: deviceName });
		});

		// Always init MIDI to detect devices (even if not yet selected as input mode)
		midi.init();

		// Microphone state tracking
		audioInput.onNotes(handleAudioInputNotes);
		audioInput.onConnection((state) => {
			micState = state;
		});

		// Retry MIDI init when tab becomes visible (handles backgrounded tabs, client-side nav)
		function handleVisibility() {
			if (document.visibilityState === 'visible') {
				if (inputMode === 'midi' && midiState === 'disconnected') midi.init();
			}
		}
		document.addEventListener('visibilitychange', handleVisibility);

		window.addEventListener('keydown', handleKeydown);
		return () => {
			authCleanup();
			document.removeEventListener('visibilitychange', handleVisibility);
			window.removeEventListener('keydown', handleKeydown);
			if (timerHandle) clearInterval(timerHandle);
			if (autoAdvanceTimeout) clearTimeout(autoAdvanceTimeout);
			midi.destroy();
			audioInput.destroy();
			midiSoundEngine.dispose();
			disposeAll();
			notificationCleanup?.();
			streakSaverCleanup?.();
		};
	});
</script>

<svelte:head>
	<title>Practice Jazz Piano Voicings – Chord Trainer Speed Drill</title>
	<meta name="description" content="Speed-drill jazz piano chord voicings in all 12 keys. MIDI auto-validation, ii-V-I progressions, shell & rootless voicings. Choose a plan and start now." />
	<link rel="canonical" href="https://jazzchords.app/train" />
	<meta property="og:title" content="Practice Jazz Piano Voicings – Chord Trainer" />
	<meta property="og:description" content="Speed-drill chord voicings in all 12 keys. MIDI recognition, ii-V-I progressions, guided practice plans." />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://jazzchords.app/train" />
	<meta property="og:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta property="og:image:type" content="image/webp" />
	<meta property="og:image:width" content="966" />
	<meta property="og:image:height" content="507" />
	<meta property="og:image:alt" content="Chord Trainer practice interface with piano keyboard" />
	<meta property="og:site_name" content="Chord Trainer" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="Practice Jazz Piano Voicings – Chord Trainer" />
	<meta name="twitter:description" content="Speed-drill chord voicings in all 12 keys. MIDI recognition, ii-V-I progressions, guided practice plans." />
	<meta name="twitter:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta name="robots" content="noindex" />
</svelte:head>

<main class="train-page flex-1 py-2 sm:py-3 px-3 xl:py-4 xl:px-8">
	<div class="w-full max-w-345 mx-auto">
		<!-- ─────── Setup Screen ─────── -->
			{#if screen === 'setup'}
				<div in:fade={{ duration: 200, delay: 80 }} class="mx-auto flex max-w-[1080px] flex-col gap-6 sm:gap-7">
					<!-- ⓪ Dashboard nav — back to landing + user settings -->
					<div class="flex items-center justify-between gap-3">
						<a
							href="/"
							class="group inline-flex items-center gap-2 rounded-full py-1.5 pr-3.5 pl-2 text-sm font-medium text-(--text-muted) transition-colors hover:text-(--text)"
						>
							<span class="grid h-7 w-7 place-items-center rounded-full border border-[var(--border)] transition-colors group-hover:border-(--primary)">
								<svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 12H5"/><path d="m12 19-7-7 7-7"/></svg>
							</span>
							<span class="text-gradient font-bold">{t('settings.back_to_home')}</span>
						</a>
					<div class="flex items-center gap-2">
						<button
							onclick={flipTheme}
							class="grid h-9 w-9 place-items-center rounded-full border border-[var(--border)] text-(--text-muted) transition-colors hover:border-(--primary) hover:text-(--text) focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)]"
							title={t('nav.theme')}
							aria-label={t('nav.theme')}
						>
							{#if themeIsLight}<Moon size={16} />{:else}<Sun size={16} />{/if}
						</button>
						<a
							href="/account"
							class="inline-flex items-center gap-2 rounded-full border border-[var(--border)] py-1.5 pr-3.5 pl-2.5 text-sm font-medium text-(--text-muted) no-underline transition-colors hover:border-(--primary) hover:text-(--text)"
							title={t('settings.open_settings')}
						>
							<Icon name="settings" size={18} />
							<span class="hidden sm:inline">{t('settings.open_settings')}</span>
						</a>
					</div>
					</div>

					<!-- ① Progress hero — single source for greeting / streak / level / MIDI -->
					{#if habitProfile}
						<HabitDashboard
							profile={habitProfile}
							{streak}
							weekDots={sbWeekDots}
							midiConnected={midiState === 'connected' && midiDevices.length > 0}
							onquickstart={(suggestion) => {
								focusRoots = suggestion.focusRoots ?? [];
								focusVoicing = suggestion.focusVoicing ?? null;
								const plan = PRACTICE_PLANS.find(p => p.id === suggestion.planId);
								if (plan) startPlan(plan); else startGame();
							}}
						/>
					{:else}
						<div class="surface-glass flex items-center justify-between gap-4 rounded-2xl px-4 py-3.5 sm:px-5">
							<div class="flex items-center gap-4 min-w-0">
								<span class="text-lg font-bold text-(--text) truncate">{greeting}!</span>
								<div class="flex items-center gap-1.5 text-sm font-semibold text-(--xp)">
									<img src="/elements/images/streak-flame.webp" width="18" height="18" alt="" style="mix-blend-mode: lighten; object-fit: contain;" />
									<span>{streak.current}</span>
									<span class="text-(--text-dim) font-normal">{streak.current === 1 ? t('habit.day') : t('habit.days')}</span>
								</div>
							</div>
							<a href="/midi-test?tab=midi" class="flex shrink-0 items-center gap-1.5 rounded-full px-3 py-1.5 text-xs no-underline transition-opacity hover:opacity-80 {midiState === 'connected' && midiDevices.length > 0 ? 'bg-[var(--success-muted)] text-(--success)' : 'bg-(--bg-muted) text-(--text-dim)'}">
								<img src="/elements/images/midi-connect.webp" width="14" height="14" alt="MIDI" style="mix-blend-mode: lighten; object-fit: contain;" />
								<span>{midiState === 'connected' && midiDevices.length > 0 ? (midiDevices[0]?.name ?? 'MIDI') : t('settings.no_midi')}</span>
								<span class="opacity-50"><Settings size={14} aria-hidden="true" /></span>
							</a>
						</div>
					{/if}

					<!-- ② Start practicing — the single primary action zone -->
					<section aria-labelledby="start-heading" class="flex flex-col gap-3.5">
						<div class="flex items-end justify-between gap-3">
							<div>
								<h1 id="start-heading" class="text-xl sm:text-2xl font-bold text-(--text)">{t('settings.start_practicing')}</h1>
								<p class="mt-1 text-sm text-(--text-dim)">{t('settings.start_practicing_sub')}</p>
							</div>
							<button
								class="hidden shrink-0 rounded-full border border-[var(--border)] px-3.5 py-1.5 text-sm font-medium text-(--text-muted) transition-colors hover:border-(--primary) hover:text-(--text) sm:inline-flex"
								onclick={() => (showInsights = !showInsights)}
							>
								{showInsights ? t('settings.hide_insights') : t('settings.show_insights')}
							</button>
						</div>

						{#if loadHistory().length === 0}
							<div class="flex items-start gap-2.5 rounded-2xl border border-[var(--border)]/60 bg-[var(--bg-card)]/40 px-4 py-3">
								<span class="mt-0.5 shrink-0"><Icon name="weak-spots" size={20} /></span>
								<p class="text-sm leading-relaxed text-(--text-muted)">
									<span class="font-semibold text-(--text)">{t('settings.how_it_works_goal')}</span>
									<span class="block text-(--text-dim)">{t('settings.how_it_works_steps')}</span>
								</p>
							</div>
						{/if}

						<QuickStart
							onweakdrill={startWeakDrill}
							resumePlanId={loadRecentPlanIds()[0] ?? null}
							hasHistory={loadHistory().length > 0}
							onstart={startPlan}
							onstartdefault={startGame}
							oncustomize={() => (settingsOpen = true)}
							onstartcoach={startCoachSession}
							coachAnnouncement={coachAnnouncement()}
						/>
					</section>

					<!-- ③ Insights (toggle) -->
					{#if showInsights}
						<section in:fade={{ duration: 180 }} class="flex flex-col gap-3">
							<h2 class="text-sm font-semibold uppercase tracking-[0.06em] text-(--text-muted)">{t('settings.your_progress')}</h2>
							<ProgressDashboard onstart={startGame} onupgrade={() => openUpgrade('advanced-stats', false)} />
						</section>
					{/if}

					<!-- ④ Advanced setup — full plan library + custom settings, opt-in -->
					<section class="surface-glass overflow-hidden rounded-2xl">
						<button
							class="flex w-full items-center justify-between gap-3 px-4 py-3.5 text-left transition-colors hover:bg-(--bg-card-hover) sm:px-5"
							onclick={() => (advancedOpen = !advancedOpen)}
							aria-expanded={advancedOpen}
						>
							<div class="flex items-center gap-3 min-w-0">
								<span class="text-sm font-semibold text-(--text)">{t('settings.advanced_setup')}</span>
								<div class="hidden items-center gap-1.5 sm:flex">
									<span class="rounded-full border border-[var(--border)]/60 bg-black/20 px-2.5 py-0.5 text-[11px] text-(--text-muted)">{t('settings.difficulty_' + difficulty)}</span>
									<span class="rounded-full border border-[var(--border)]/60 bg-black/20 px-2.5 py-0.5 text-[11px] text-(--text-muted)">{t(VOICING_KEYS[voicing])}</span>
									<span class="rounded-full border border-[var(--border)]/60 bg-black/20 px-2.5 py-0.5 text-[11px] text-(--text-muted)">{t(PROGRESSION_KEYS[progressionMode])}</span>
									{#if inTimeMode}
										<span class="rounded-full border border-[var(--success)]/30 bg-[var(--success-muted)] px-2.5 py-0.5 text-[11px] text-(--success)">{t('settings.in_time_mode')}</span>
									{/if}
								</div>
							</div>
							<span class="shrink-0 text-(--text-dim) transition-transform duration-200 {advancedOpen ? 'rotate-180' : ''}">▾</span>
						</button>

						{#if advancedOpen}
							<div class="border-t border-[var(--border)]/30 px-4 py-4 sm:px-5 sm:py-5 space-y-5" transition:slide={{ duration: 220 }}>
								<div class="flex flex-wrap items-center gap-2">
									<button class="pill-btn pill-btn-primary text-sm px-4 py-2" onclick={startGame}>{t('settings.start_training')}</button>
									<button class="pill-btn pill-btn-secondary text-sm px-3 py-2" onclick={() => (settingsOpen = true)}>{t('settings.custom_settings')}</button>
									<button class="pill-btn pill-btn-secondary text-sm px-3 py-2 inline-flex items-center gap-1.5" onclick={openCustomEditor}>{t('settings.custom_progression')} <ProBadge feature="custom-progressions" size="xs" /></button>
								</div>

								<GameSettings
									compact={true}
									bind:difficulty
									bind:notation
									bind:voicing={voicing}
									bind:displayMode
									bind:accidentals
									bind:notationSystem
									bind:totalChords
									bind:progressionMode
									midiEnabled={inputMode === 'midi'}
									bind:inTimeMode
									bind:inTimeBars
									bind:adaptiveEnabled
									bind:voiceLeadingEnabled
									bind:vlMode
									{streak}
									{midiState}
									{midiDevices}
									onstartplan={startPlan}
								/>
							</div>
						{/if}
					</section>
				</div>
			{/if}

		<!-- ─── Training einrichten Modal ─── -->
		{#if settingsOpen}
			<div
				class="fixed inset-0 z-40 bg-black/75"
				transition:fade={{ duration: 180 }}
				onclick={closeSettingsModal}
				role="presentation"
			></div>
			<div
				class="fixed left-0 right-0 bottom-0 z-50 max-h-[88vh] bg-[var(--bg-card,#1c1a17)] rounded-t-[20px] border-t border-[var(--border)] flex flex-col overflow-hidden min-[600px]:left-1/2 min-[600px]:right-auto min-[600px]:w-[560px] min-[600px]:-translate-x-1/2"
				transition:fly={{ y: 500, duration: 340, opacity: 1 }}
				role="dialog"
				aria-modal="true"
			>
				<div class="flex items-center justify-between px-5 py-4 border-b border-[var(--border)] shrink-0">
					<h2 class="text-base font-bold">{t('settings.custom_settings')}</h2>
					<button
						class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[var(--bg-muted)] transition-colors text-2xl leading-none cursor-pointer text-[var(--text-dim)] hover:text-[var(--text)]"
						onclick={closeSettingsModal}
						aria-label="Schließen"
					><X size={20} aria-hidden="true" /></button>
				</div>
				<div class="overflow-y-auto p-5 pb-[max(20px,env(safe-area-inset-bottom))] flex-1 space-y-6">
					<button
						class="w-full h-12 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] text-base font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer inline-flex items-center justify-center gap-2"
						onclick={() => { settingsOpen = false; settingsOpenedFromScreen = null; startGame(); }}
					>{#if settingsOpenedFromScreen}<RotateCcw size={18} aria-hidden="true" /> {t('settings.restart_with_settings')}{:else}<Play size={18} aria-hidden="true" /> {t('settings.start_training')}{/if}</button>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.progression_mode')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.progression_desc')}</p>
						<div class="grid grid-cols-2 gap-2">
							{#each ([
								{ val: 'random' as ProgressionMode,        label: t('settings.progression_random'),     sub: t('settings.progression_random_sub') },
								{ val: 'cycle-of-4ths' as ProgressionMode, label: t('settings.progression_cycle'),      sub: t('settings.progression_cycle_sub') },
								{ val: '2-5-1' as ProgressionMode,         label: t('settings.progression_251'),        sub: t('settings.progression_251_sub') },
								{ val: '1-6-2-5' as ProgressionMode,       label: t('settings.progression_turnaround'), sub: t('settings.progression_turnaround_sub') },
								{ val: '3-6-2-5' as ProgressionMode,       label: t('settings.progression_3625'),       sub: t('settings.progression_3625_sub') },
								{ val: '1-4-5' as ProgressionMode,         label: t('settings.progression_145'),        sub: t('settings.progression_145_sub') },
								{ val: 'diatonic' as ProgressionMode,      label: t('settings.progression_diatonic'),   sub: t('settings.progression_diatonic_sub') },
								{ val: 'custom' as ProgressionMode,        label: t('settings.progression_custom'),     sub: t('settings.progression_custom_sub') },
							] as Array<{val: ProgressionMode; label: string; sub: string}>).map(o => o) as opt}
								<button class="p-2.5 rounded-[var(--radius)] border-2 transition-all text-left {sel(progressionMode, opt.val)}" onclick={() => (progressionMode = opt.val)}>
									<div class="font-semibold text-sm leading-tight">{opt.label}</div>
									<div class="text-xs text-[var(--text-dim)] mt-0.5 leading-tight">{opt.sub}</div>
								</button>
							{/each}
						</div>

						<!-- Custom degree builder -->
						{#if progressionMode === 'custom'}
							<div class="mt-3 space-y-2">
								<div class="text-xs font-medium text-[var(--text-muted)]">{t('settings.custom_degrees_label')}</div>
								<p class="text-xs text-[var(--text-dim)]">{t('settings.custom_degrees_hint')}</p>
								<div class="flex gap-1.5 flex-wrap">
									{#each [0,1,2,3,4,5,6] as di}
										{@const romans = ['I','ii','iii','IV','V','vi','vii°']}
										{@const qualities = ['Maj7','m7','m7','Maj7','7','m7','m7b5']}
										<button
											class="flex flex-col items-center px-2 py-1.5 rounded-[var(--radius-sm)] border-2 transition-all text-center cursor-pointer min-w-[2.5rem]
												{customDegrees.includes(di) ? 'border-[var(--primary)] bg-[var(--primary-muted)]' : 'border-[var(--border)] hover:border-[var(--border-hover)]'}"
											onclick={() => {
												customDegrees = customDegrees.includes(di)
													? customDegrees.filter(d => d !== di)
													: [...customDegrees, di];
											}}
										>
											<span class="text-xs font-bold leading-none">{romans[di]}</span>
											<span class="text-[9px] text-[var(--text-dim)] leading-none mt-0.5">{qualities[di]}</span>
										</button>
									{/each}
								</div>
								{#if customDegrees.length > 0}
									<div class="flex items-center gap-1.5 flex-wrap mt-1">
										<span class="text-[10px] text-[var(--text-dim)] uppercase tracking-wide">{t('ui.loop_label')}</span>
										{#each customDegrees as di, i}
											{@const romans = ['I','ii','iii','IV','V','vi','vii°']}
											<span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-[var(--primary-muted)] border border-[var(--primary)]/30 text-xs font-semibold">
												{romans[di]}
												<button class="text-[var(--text-dim)] hover:text-[var(--accent-red)] leading-none cursor-pointer inline-flex items-center" onclick={() => { customDegrees = customDegrees.filter((_, idx) => idx !== i); }}><X size={12} aria-hidden="true" /></button>
											</span>
										{/each}
										<button class="text-[10px] text-[var(--text-dim)] hover:text-[var(--accent-red)] underline cursor-pointer" onclick={() => { customDegrees = []; }}>{t('ui.clear')}</button>
									</div>
								{/if}
							</div>
						{/if}
					</fieldset>
				<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.input_mode')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.input_mode_desc')}</p>
						<div class="grid grid-cols-3 gap-3">
							{#each [
								{ val: 'none' as InputMode, label: t('settings.input_mode_none'), sub: t('settings.input_mode_none_sub') },
								{ val: 'midi' as InputMode, label: t('settings.input_mode_midi'), sub: t('settings.input_mode_midi_sub') },
								{ val: 'microphone' as InputMode, label: t('settings.input_mode_mic'), sub: t('settings.input_mode_mic_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(inputMode, opt.val)}" onclick={() => {
									inputMode = opt.val;
									if (opt.val === 'midi' && midiState === 'disconnected') midi.init();
									if (opt.val === 'microphone' && (micState === 'idle' || micState === 'error' || micState === 'denied')) audioInput.init();
								}}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
						<p class="mt-2 text-xs text-[var(--text-dim)]">{t('settings.input_mode_note')}</p>
						{#if midiState === 'unsupported' && isIpadOS}
							<a
								href="https://apps.apple.com/app/web-midi-browser/id953846217"
								target="_blank"
								rel="noopener noreferrer"
								class="inline-flex items-center gap-1.5 mt-1.5 text-xs text-[var(--accent-amber)] underline underline-offset-2 hover:text-[var(--primary)] transition-colors"
							>
								<span class="inline-flex items-center gap-1.5"><TabletSmartphone size={14} aria-hidden="true" /> {t('midi.ipad_open_app')}</span>
							</a>
						{/if}
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.difficulty')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.difficulty_desc')}</p>
						<div class="grid grid-cols-3 gap-3">
							{#each [
								{ val: 'beginner' as Difficulty, label: t('settings.difficulty_beginner'), sub: t('settings.difficulty_beginner_sub') },
								{ val: 'intermediate' as Difficulty, label: t('settings.difficulty_intermediate'), sub: t('settings.difficulty_intermediate_sub') },
								{ val: 'advanced' as Difficulty, label: t('settings.difficulty_advanced'), sub: t('settings.difficulty_advanced_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left overflow-hidden {sel(difficulty, opt.val)}" onclick={() => (difficulty = opt.val)}>
									<div class="font-semibold text-sm truncate">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.accidentals')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.accidentals_desc')}</p>
						<div class="grid grid-cols-3 gap-3">
							{#each [
								{ val: 'sharps' as AccidentalPreference, label: t('settings.accidentals_sharps'), sub: t('settings.accidentals_sharps_sub') },
								{ val: 'flats' as AccidentalPreference, label: t('settings.accidentals_flats'), sub: t('settings.accidentals_flats_sub') },
								{ val: 'both' as AccidentalPreference, label: t('settings.accidentals_both'), sub: t('settings.accidentals_both_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(accidentals, opt.val)}" onclick={() => (accidentals = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.notation_system')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.notation_system_desc')}</p>
						<div class="grid grid-cols-2 gap-3">
							{#each [
								{ val: 'international' as NotationSystem, label: t('settings.notation_system_international'), sub: t('settings.notation_system_international_sub') },
								{ val: 'german' as NotationSystem, label: t('settings.notation_system_german'), sub: t('settings.notation_system_german_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(notationSystem, opt.val)}" onclick={() => (notationSystem = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.chord_notation_title')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.chord_notation_desc')}</p>
						<div class="grid grid-cols-3 gap-3">
							{#each [
								{ val: 'standard' as NotationStyle, label: t('settings.notation_standard'), sub: t('settings.notation_standard_sub') },
								{ val: 'symbols' as NotationStyle, label: t('settings.notation_symbols'), sub: t('settings.notation_symbols_sub') },
								{ val: 'short' as NotationStyle, label: t('settings.notation_short'), sub: t('settings.notation_short_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(notation, opt.val)}" onclick={() => (notation = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.voicing')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.voicing_desc')}</p>
						<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">{t('settings.voicing_basics')}</div>
						<div class="grid grid-cols-2 gap-3">
							{#each [
								{ val: 'root' as VoicingType, label: t('settings.voicing_root'), sub: t('settings.voicing_root_sub') },
								{ val: 'shell' as VoicingType, label: t('settings.voicing_shell'), sub: t('settings.voicing_shell_sub') },
								{ val: 'half-shell' as VoicingType, label: t('settings.voicing_half_shell'), sub: t('settings.voicing_half_shell_sub') },
								{ val: 'full' as VoicingType, label: t('settings.voicing_full'), sub: t('settings.voicing_full_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voicing, opt.val)}" onclick={() => (voicing = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
						<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4 flex items-center gap-1.5"><Piano size={14} aria-hidden="true" /> {t('settings.voicing_left_hand')}</div>
						<div class="grid grid-cols-2 gap-3">
							{#each [
								{ val: 'rootless-a' as VoicingType, label: t('settings.voicing_rootless_a'), sub: t('settings.voicing_rootless_a_sub') },
								{ val: 'rootless-b' as VoicingType, label: t('settings.voicing_rootless_b'), sub: t('settings.voicing_rootless_b_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voicing, opt.val)}" onclick={() => (voicing = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
						<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4 flex items-center gap-1.5"><RefreshCw size={14} aria-hidden="true" /> {t('settings.voicing_inversions_group')}</div>
						<div class="grid grid-cols-3 gap-3">
							{#each [
								{ val: 'inversion-1' as VoicingType, label: t('settings.voicing_inversion_1'), sub: t('settings.voicing_inversion_1_sub') },
								{ val: 'inversion-2' as VoicingType, label: t('settings.voicing_inversion_2'), sub: t('settings.voicing_inversion_2_sub') },
								{ val: 'inversion-3' as VoicingType, label: t('settings.voicing_inversion_3'), sub: t('settings.voicing_inversion_3_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voicing, opt.val)}" onclick={() => (voicing = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.display_mode')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.display_mode_desc')}</p>
						<div class="grid grid-cols-3 gap-3">
							{#each [
								{ val: 'off' as DisplayMode, label: t('settings.display_mode_off'), sub: t('settings.display_mode_off_sub') },
								{ val: 'always' as DisplayMode, label: t('settings.display_mode_always'), sub: t('settings.display_mode_always_sub') },
								{ val: 'verify' as DisplayMode, label: t('settings.display_mode_verify'), sub: inputActive ? t('settings.display_mode_verify_midi') : t('settings.display_mode_verify_sub') },
							] as opt}
								<button
									class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(displayMode, opt.val)} {opt.val === 'verify' && inputActive ? 'opacity-40 cursor-not-allowed' : ''}"
									onclick={() => { if (!(opt.val === 'verify' && inputActive)) displayMode = opt.val; }}
									disabled={opt.val === 'verify' && inputActive}
								><div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div></button>
							{/each}
						</div>
					</fieldset>
					{#if progressionMode === 'random'}
						<fieldset>
							<legend class="text-sm font-medium mb-3">{t('settings.chord_count')}</legend>
							<input type="number" min="5" max="50" bind:value={totalChords}
								class="w-full px-4 py-2 rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg)] text-[var(--text)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
							/>
						</fieldset>
					{:else}
						<div class="p-3 bg-[var(--bg)] rounded-[var(--radius)] border border-[var(--border)] text-sm text-[var(--text-muted)]">
							{t(PROGRESSION_KEYS[progressionMode])}
						</div>
					{/if}
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.in_time_mode')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.in_time_desc')}</p>
						<div class="grid grid-cols-2 gap-3">
							{#each [
								{ val: false, label: t('settings.on_off_off'), sub: t('settings.in_time_off_sub') },
								{ val: true, label: t('settings.on_off_on'), sub: t('settings.in_time_on_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(inTimeMode, opt.val)}" onclick={() => (inTimeMode = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
						{#if inTimeMode}
							<div class="mt-3">
								<div class="text-xs font-medium text-[var(--text-muted)] mb-2">{t('settings.bars_per_chord')}</div>
								<div class="grid grid-cols-3 gap-3">
									{#each [1, 2, 4] as bars}
										<button class="p-2 rounded-[var(--radius)] border-2 transition-all text-center {sel(inTimeBars, bars)}" onclick={() => (inTimeBars = bars)}>
											<div class="font-semibold text-sm">{bars}</div>
											<div class="text-xs text-[var(--text-dim)]">{bars === 1 ? t('settings.bar_singular') : t('settings.bar_plural')}</div>
										</button>
									{/each}
								</div>
								<div class="mt-3">
									<div class="text-xs font-medium text-[var(--text-muted)] mb-1 flex items-center gap-1.5"><Eye size={14} aria-hidden="true" /> Vorschau (Look-ahead)</div>
									<p class="text-xs text-[var(--text-dim)] mb-2">Siehst du den nächsten Chord schon im letzten Bar?</p>
									<div class="grid grid-cols-2 gap-3">
										{#each [
											{ val: false, label: 'Blind', sub: 'Nächster Chord unbekannt — testet Reaktion' },
											{ val: true, label: 'Vorschau', sub: 'Nächster Chord im letzten Bar sichtbar — testet Vorbereitung' },
										] as opt}
											<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(inTimeLookAhead, opt.val)}" onclick={() => (inTimeLookAhead = opt.val)}>
												<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
											</button>
										{/each}
									</div>
								</div>
							</div>
						{/if}
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1 flex items-center gap-2">{t('settings.adaptive_mode')} <ProBadge feature="adaptive-difficulty" size="xs" /></legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.adaptive_desc')}</p>
						<div class="grid grid-cols-2 gap-3">
							{#each [
								{ val: false, label: t('settings.on_off_off'), sub: t('settings.adaptive_off_sub') },
								{ val: true, label: t('settings.on_off_on'), sub: t('settings.adaptive_on_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(adaptiveEnabled, opt.val)}" onclick={() => {
									if (opt.val && showLock('adaptive-difficulty')) { openUpgrade('adaptive-difficulty', false); return; }
									adaptiveEnabled = opt.val;
								}}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.voice_leading')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.voice_leading_desc')}</p>
						<div class="grid grid-cols-2 gap-3">
							{#each [
								{ val: false, label: t('settings.on_off_off'), sub: t('settings.voice_leading_off_sub') },
								{ val: true, label: t('settings.on_off_on'), sub: t('settings.voice_leading_on_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voiceLeadingEnabled, opt.val)}" onclick={() => (voiceLeadingEnabled = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
					</fieldset>
					<button
						class="w-full p-4 rounded-[var(--radius)] border-2 border-[var(--border)] hover:border-[var(--accent-amber)] transition-all text-left group"
						onclick={() => { settingsOpen = false; settingsOpenedFromScreen = null; startEarTraining(); }}
					>
						<div class="flex items-center gap-3">
							<Ear size={24} class="text-[var(--text-muted)]" aria-hidden="true" />
							<div>
								<div class="font-semibold text-sm group-hover:text-[var(--accent-amber)] transition-colors">{t('settings.ear_training_title')}</div>
								<div class="text-xs text-[var(--text-dim)] mt-0.5">{t('settings.ear_training_desc')}</div>
							</div>
						</div>
					</button>
				</div>
			</div>
		{/if}

		<!-- ─────── Custom Progression Editor ─────── -->
		{#if screen === 'custom-editor'}
			<div in:fade={{ duration: 200, delay: 100 }}>
				<ProgressionEditor
					onplay={startCustomProgression}
					onback={resetToSetup}
				/>
			</div>
		{/if}

		<!-- ─────── Custom Progression Playing ─────── -->
		{#if screen === 'custom-playing'}
			<ProgressionPlayer
				chords={customChords}
				bpm={customBpm}
				loops={customLoops}
				name={customName}
				{voicing}
				{accidentals}
				{notationSystem}
				{audioEnabled}
				midiEnabled={inputMode === 'midi'}
				{midi}
				{midiState}
				{midiDevices}
				onstop={handleCustomStop}
			/>
		{/if}

		<!-- ─────── Custom Progression Results ─────── -->
		{#if screen === 'custom-results' && customEvaluation}
			<ProgressionResults
				evaluation={customEvaluation}
				name={customName}
				bpm={customBpm}
				onback={backToCustomEditor}
				onreplay={replayCustom}
			/>
		{/if}

		<!-- ─────── Playing Screen ─────── -->
		{#if screen === 'playing'}
			<div in:fly={{ y: 20, duration: 300, delay: 50 }}>
			<!-- Page-level top bar -->
				<div class="flex items-center justify-between gap-3 mb-6">
					<button
						class="inline-flex items-center gap-1.5 rounded-full border border-[var(--border)] px-3.5 py-1.5 text-sm font-medium text-[var(--text-muted)] transition-colors hover:border-[var(--text)] hover:text-[var(--text)]"
						onclick={resetToSetup}
						title={t('ui.back_setup')}
					>
						<ArrowLeft size={16} aria-hidden="true" /> {t('ui.back')}
					</button>
					<div class="flex items-center gap-2 sm:gap-3 min-w-0">
						<div class="hidden sm:flex items-center gap-1.5 text-sm text-[var(--text-muted)]">
							<span class="font-semibold text-[var(--text)]">{t(VOICING_KEYS[voicing])}</span>
							<span class="text-[var(--text-dim)]">·</span>
							<span class="capitalize">{t('settings.difficulty_' + difficulty)}</span>
							<span class="text-[var(--text-dim)]">·</span>
							<span>{t(PROGRESSION_KEYS[progressionMode])}</span>
						</div>
						<button
							class="grid h-9 w-9 place-items-center rounded-full border border-[var(--border)] text-[var(--text-muted)] transition-colors hover:border-[var(--primary)] hover:text-[var(--primary)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)]"
							onclick={openSettingsFromGame}
							title="{t('settings.custom_settings')} (S)"
							aria-label="{t('settings.custom_settings')}"
						>
							<svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
						</button>
						<button
							class="grid h-9 w-9 place-items-center rounded-full border text-sm font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] {showExerciseInfo ? 'border-[var(--primary)] bg-[var(--primary-muted)] text-[var(--primary)]' : 'border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)]'}"
							onclick={() => (showExerciseInfo = !showExerciseInfo)}
							title={t('explain.title')}
							aria-label={t('explain.title')}
							aria-pressed={showExerciseInfo}
						>?</button>
					</div>
				</div>

			<!-- Exercise info panel -->
			{#if showExerciseInfo}
				<div class="mb-6 p-4 rounded-[var(--radius)] border border-[var(--primary)]/30 bg-[var(--primary-muted)]/50" transition:fly={{ y: -10, duration: 200 }}>
					<div class="flex items-start justify-between gap-4">
						<div class="space-y-2">
							<h3 class="font-semibold text-[var(--primary)]">{t('settings.voicing_' + voicing.replace(/-/g, '_'))}</h3>
							<p class="text-sm text-[var(--text-muted)]">{t('voicing_info.' + voicing.replace(/-/g, '_') + '_tip')}</p>
							<p class="text-xs font-mono text-[var(--text-dim)]">{t('ui.example')}: {VOICING_EXAMPLES[voicing]}</p>
						</div>
						<button
							class="text-[var(--text-muted)] hover:text-[var(--text)] cursor-pointer text-sm shrink-0"
							onclick={() => (showExerciseInfo = false)}
						><X size={16} aria-hidden="true" /></button>
					</div>
				</div>
			{/if}

			<div class="w-full space-y-6">
				<!-- Input status bar -->
				{#if inputMode === 'midi'}
					<div class="flex items-center justify-between">
						<MidiStatus
							state={midiState}
							devices={midiDevices}
							selectedDeviceId={midiSelectedDeviceId}
							activeNoteCount={midiActiveNotes.size}
							onSelectDevice={handleMidiSelectDevice}
							onConnect={handleMidiConnect}
						/>
						<span class="text-xs text-[var(--text-muted)] font-mono min-w-[5rem] text-right">
							Accuracy: {midiTotalAttempts > 0 ? `${midiAccuracy}%` : '—'}
						</span>
						<a href="/midi-test?tab=midi" class="text-xs text-[var(--text-dim)] hover:text-[var(--primary)] transition-colors" title={t('nav.midi_test')}><Settings size={14} aria-hidden="true" /></a>
					</div>
				{:else if inputMode === 'microphone'}
					<div class="flex items-center justify-between gap-3">
						<MicStatus
							state={micState}
							activeNoteCount={midiActiveNotes.size}
							onConnect={() => audioInput.init()}
						/>
						<a href="/midi-test?tab=mic" class="text-xs text-[var(--text-dim)] hover:text-[var(--primary)] transition-colors shrink-0" title={t('nav.midi_test')}><Settings size={14} aria-hidden="true" /></a>
					</div>
				{/if}

				<!-- Transport — audio, sound, metronome in one coherent bar -->
				<div class="flex flex-wrap items-center gap-2 rounded-full border border-[var(--border)]/50 bg-[var(--bg-card)]/40 px-2 py-1.5 text-sm backdrop-blur-sm">
					<button
						class="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 font-medium transition-colors {audioEnabled ? 'bg-[var(--primary-muted)] text-[var(--primary)]' : 'text-[var(--text-muted)] hover:bg-(--bg-muted) hover:text-[var(--text)]'}"
						onclick={() => (audioEnabled = !audioEnabled)}
						aria-pressed={audioEnabled}
						title={audioEnabled ? t('ui.audio') : t('ui.audio')}
					>
						{#if audioEnabled}<Volume2 size={16} aria-hidden="true" />{:else}<VolumeX size={16} aria-hidden="true" />{/if} {t('ui.audio')}
					</button>
					{#if audioEnabled}
						<select
							class="rounded-full border border-[var(--border)]/60 bg-[var(--bg)]/70 px-2.5 py-1.5 text-xs text-[var(--text-muted)] transition-colors hover:border-[var(--border-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] cursor-pointer"
							value={soundPreset}
							onchange={(e) => changeSoundPreset((e.target as HTMLSelectElement).value as SoundPreset)}
							aria-label={t('ui.audio')}
						>
							{#each Object.entries(SOUND_PRESETS) as [key, preset]}
								<option value={key}>{preset.label}</option>
							{/each}
						</select>
					{/if}
					{#if inputMode === 'midi'}
						<button
							class="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 font-medium transition-colors {midiSoundEnabled ? 'bg-[var(--primary-muted)] text-[var(--primary)]' : 'text-[var(--text-muted)] hover:bg-(--bg-muted) hover:text-[var(--text)]'}"
							onclick={toggleMidiSound}
							aria-pressed={midiSoundEnabled}
							title={midiSoundEnabled ? t('settings.midi_sound_on') : t('settings.midi_sound_off')}
						>
							<Piano size={16} aria-hidden="true" /> {t('settings.midi_sound')}
						</button>
					{/if}

					<span class="mx-0.5 hidden h-5 w-px bg-[var(--border)]/50 sm:block"></span>

					<button
						class="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 font-medium transition-colors {metronomeEnabled ? 'bg-[var(--primary-muted)] text-[var(--primary)]' : 'text-[var(--text-muted)] hover:bg-(--bg-muted) hover:text-[var(--text)]'}"
						onclick={toggleMetronome}
						aria-pressed={metronomeEnabled}
					>
						{#if metronomeEnabled}<Pause size={16} aria-hidden="true" />{:else}<Play size={16} aria-hidden="true" />{/if} {t('ui.metronome')}
					</button>
					{#if metronomeEnabled}
						<div class="flex items-center gap-1.5">
							<button
								class="grid h-7 w-7 place-items-center rounded-full border border-[var(--border)] text-[var(--text-muted)] transition-colors hover:border-[var(--primary)] hover:text-[var(--primary)]"
								onclick={() => updateBpm(metronomeBpm - 5)}
								aria-label="−5 BPM"
							>−</button>
							<span class="w-14 text-center font-mono text-xs tabular-nums">{metronomeBpm} {t('ui.bpm')}</span>
							<button
								class="grid h-7 w-7 place-items-center rounded-full border border-[var(--border)] text-[var(--text-muted)] transition-colors hover:border-[var(--primary)] hover:text-[var(--primary)]"
								onclick={() => updateBpm(metronomeBpm + 5)}
								aria-label="+5 BPM"
							>+</button>
						</div>
						<div class="flex items-center gap-1 pl-0.5">
							{#each [1, 2, 3, 4] as beat}
								<div
									class="h-2.5 w-2.5 rounded-full transition-all duration-100 {currentBeat === beat
										? beat === 1
											? 'bg-[var(--success)] scale-125'
											: 'bg-[var(--primary)] scale-110'
										: 'bg-[var(--border)]'}"
								></div>
							{/each}
						</div>
					{/if}
				</div>

				<!-- In-Time bar counter — always visible while playing, even with metronome collapsed -->
				{#if inTimeMode && timerStarted}
					<div class="flex items-center justify-between px-4 py-2.5 rounded-[var(--radius)] border border-[var(--accent-amber)]/25 bg-[var(--accent-amber)]/5">
						<div class="flex items-center gap-3">
							{#each Array.from({length: inTimeBars}, (_, i) => i + 1) as barNum}
								<div class="flex flex-col items-center gap-0.5">
									<div class="w-9 h-9 rounded-[var(--radius-sm)] border-2 flex items-center justify-center font-mono font-bold text-sm transition-all duration-150
										{Math.min(inTimeBarCount, inTimeBars) === barNum
											? (barNum === 1
												? 'border-[var(--accent-amber)] bg-[var(--accent-amber)]/15 text-[var(--accent-amber)]'
												: 'border-[var(--primary)]/50 bg-[var(--primary-muted)] text-[var(--primary)]')
											: 'border-[var(--border)] text-[var(--text-dim)]'}">{barNum}</div>
									<span class="text-[9px] leading-tight inline-flex items-center gap-0.5 {barNum === 1 ? 'text-[var(--accent-amber)]' : 'text-[var(--text-dim)]'}">{#if barNum === 1}<Play size={9} aria-hidden="true" /> spielen{:else}halten{/if}</span>
								</div>
							{/each}
						</div>
						<span class="text-xs text-[var(--text-dim)] hidden sm:block">{t('ui.timing_note')}</span>
					</div>
				{/if}

				<!-- Progress bar + timer -->
				<div>
					<div class="flex justify-between text-sm mb-2 text-[var(--text-muted)]">
						<span>{t('ui.chord_progress', { current: currentIdx + 1, total: actualTotalChords })}</span>
						<div class="flex items-center gap-3">
							{#if !inTimeMode}
							<span class="font-mono">{timerStarted ? formatTime(elapsedMs > 0 ? elapsedMs : 0) : '0:00.00'}</span>
							{/if}
							{#if timerStarted}
								<button
									class="flex items-center gap-1 text-xs px-2 py-0.5 rounded border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--text)] hover:text-[var(--text)] transition-colors cursor-pointer"
									onclick={togglePause}
									title={`${t('ui.pause')} (P)`}
								>{#if paused}<Play size={14} aria-hidden="true" /> {t('ui.resume')}{:else}<Pause size={14} aria-hidden="true" /> {t('ui.pause')}{/if}</button>
								<button
									class="flex items-center gap-1 text-xs px-2 py-0.5 rounded border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer"
									onclick={restartGame}
									title={t('ui.restart')}
								><RotateCcw size={14} aria-hidden="true" /> {t('ui.restart')}</button>
								{#if inTimeMode && !inTimeLookAhead}
									<button
										class="flex items-center gap-1 text-xs px-2 py-0.5 rounded border border-[var(--accent-amber)]/50 text-[var(--accent-amber)] hover:border-[var(--accent-amber)] hover:bg-[var(--accent-amber)]/10 transition-colors cursor-pointer"
										onclick={promptLookAhead}
										title="Vorschau aktivieren — zeigt nächsten Chord im letzten Bar (H)"
									><Eye size={14} aria-hidden="true" /> Vorschau <kbd class="ml-0.5 px-1 py-0.5 rounded border border-[var(--accent-amber)]/40 font-mono text-[10px] not-italic">H</kbd></button>
								{/if}
							{/if}
						</div>
					</div>
					<div class="h-1.5 bg-[var(--bg-muted)] rounded-full overflow-hidden">
						<div
							class="h-full bg-[var(--primary)] transition-all duration-300 rounded-full"
							style="width: {progress}%"
						></div>
					</div>
				</div>

				<!-- Start overlay (before timer started) -->
				{#if !timerStarted}
					<div class="text-center py-4">
						<button
							class="px-8 py-3 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] font-semibold text-lg hover:bg-[var(--primary-hover)] transition-colors cursor-pointer shadow-lg inline-flex items-center justify-center gap-2"
							onclick={beginTimer}
						>
							<Play size={20} aria-hidden="true" /> Start
						</button>
						<p class="mt-3 text-xs text-[var(--text-muted)]">Press <strong>Space</strong> to start</p>
					</div>
				{/if}

				<!-- Pause overlay -->
				{#if paused}
					<div class="text-center py-8">
						<div class="text-2xl font-bold text-[var(--text-muted)] mb-4 inline-flex items-center justify-center gap-2"><Pause size={22} aria-hidden="true" /> Paused</div>
						<button
							class="px-6 py-2 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer inline-flex items-center justify-center gap-2"
							onclick={togglePause}
						>
							<Play size={18} aria-hidden="true" /> Resume
						</button>
						<p class="mt-2 text-xs text-[var(--text-muted)]">Press <strong>P</strong> or <strong>Space</strong> to resume</p>
					</div>
				{/if}

				<!-- Coach: tell the player which voicing to play (they can't be expected
				     to know from a chord name like E♭9), with a one-line what-notes hint. -->
				{#if coachMode}
					<div class="mb-3 flex items-center justify-center gap-2 text-center flex-wrap">
						<span class="inline-flex items-center gap-1.5 rounded-full border border-[var(--primary)] bg-[var(--primary-muted)] px-3 py-1 text-xs font-semibold text-(--primary)">
							<Icon name="weak-spots" size={13} />
							{t('settings.voicing_' + voicing.replace(/-/g, '_'))}
						</span>
						<span class="text-xs text-(--text-muted)">{t('settings.voicing_' + voicing.replace(/-/g, '_') + '_sub')}</span>
					</div>
				{/if}

				<!-- Chord card + keyboard (dimmed when paused or not started) -->
				<div class="{paused ? 'opacity-30 pointer-events-none' : ''} flex items-start gap-4">
				<div class="flex-1 min-w-0">
				<ChordCard chord={currentChord} system={notationSystem} onclick={nextChord} voiceLeading={voiceLeadingInfo} showVoiceLeading={voiceLeadingEnabled} vlMode={voiceLeadingEnabled ? vlMode : 'guided'} voicingTypeHint={voiceLeadingEnabled && vlMode === 'find-inversion' ? t('settings.voicing_' + voicing.replace(/-/g, '_')) : ''}>
					<!-- Piano keyboard inside card -->
					<div class="mt-8">
						<PianoKeyboard
							chordData={currentData}
							accidentalPref={accidentals}
							showVoicing={shouldShowVoicing}
							midiEnabled={inputActive}
							midiActiveNotes={midiActiveNotes}
							midiExpectedPitchClasses={expectedPitchClasses}
							voiceLeading={voiceLeadingInfo}
							showVoiceLeading={voiceLeadingEnabled}
							forceOctaves={sessionOctaves}
							interactive={isTapGuessMode}
							selectedPitchClasses={tapGuessNotes}
							onKeyClick={isTapGuessMode ? handleTapPianoClick : undefined}
						/>
					</div>

					<!-- VL Mode B/C feedback -->
					{#if voiceLeadingEnabled && vlMode !== 'guided' && vlValidation && midiActiveNotes.size > 0}
						<div class="mt-4 text-center">
							{#if vlValidation.grade === 'optimal'}
								<span class="text-[var(--accent-green)] font-semibold text-lg inline-flex items-center gap-1"><Check size={18} aria-hidden="true" /> Optimal!</span>
								<div class="text-xs text-[var(--text-muted)] mt-0.5">{t('ui.vl_movement', { n: vlValidation.playerMovement })}</div>
							{:else if vlValidation.grade === 'correct'}
								<span class="text-[var(--accent-amber)] font-semibold">{t('ui.correct_but_not_closest')}</span>
								<div class="text-xs text-[var(--text-muted)] mt-0.5">
									{t('ui.vl_your_movement', { player: vlValidation.playerMovement, optimal: vlValidation.optimalMovement })}
								</div>
							{:else}
								<span class="text-[var(--accent-red)] text-sm">{t('ui.vl_wrong_notes')}</span>
							{/if}
						</div>
					<!-- Standard match feedback (guided mode / non-VL) -->
					{:else if inputActive && midiMatchResult && midiActiveNotes.size > 0}
						<div class="mt-4 text-center">
							{#if midiMatchResult.correct}
								<span class="text-[var(--accent-green)] font-semibold text-lg inline-flex items-center gap-1"><Check size={18} aria-hidden="true" /> Correct!</span>
							{:else if midiMatchResult.missing.length === 0 && voicing.startsWith('inversion-') && currentData}
								<span class="text-[var(--accent-amber)] text-sm">
									Right notes — wrong bass! Put <strong>{currentData.voicing[0]}</strong> on bottom
								</span>
							{:else if midiMatchResult.accuracy > 0}
								<span class="text-[var(--accent-amber)] text-sm">
									{Math.round(midiMatchResult.accuracy * 100)}% – {midiMatchResult.missing.length} note{midiMatchResult.missing.length !== 1 ? 's' : ''} missing
								</span>
							{:else}
								<span class="text-[var(--accent-red)] text-sm">Wrong notes</span>
							{/if}
						</div>
					{/if}

					<!-- Listen button -->
					{#if audioEnabled && currentData}
						<div class="mt-4 text-center flex items-center justify-center gap-2">
							<!-- svelte-ignore a11y_click_events_have_key_events -->
							<button
								class="px-4 py-1.5 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer inline-flex items-center justify-center gap-1.5"
								onclick={(e) => { e.stopPropagation(); replayChord(); }}
							>
								<Music size={16} aria-hidden="true" /> Listen
							</button>
							<button
								class="px-2.5 py-1.5 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer"
								onclick={(e) => { e.stopPropagation(); showExplain = true; }}
								title={t('explain.title')}
							>
								?
							</button>
						</div>
					{:else if currentData}
						<div class="mt-4 text-center">
							<button
								class="px-2.5 py-1.5 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer"
								onclick={(e) => { e.stopPropagation(); showExplain = true; }}
								title={t('explain.title')}
							>
								? {t('explain.title')}
							</button>
						</div>
					{/if}

					<!-- Voicing text -->
					{#if shouldShowVoicing && currentData}
						<div class="mt-6 space-y-1">
							<div class="text-sm text-[var(--text-muted)]">{t('settings.voicing_' + voicing.replace(/-/g, '_'))}</div>
							<div class="text-xl font-mono font-semibold">
								{formatVoicing(currentData, voicing, notationSystem)}
							</div>
							{#if voicing.startsWith('inversion-') && currentData.voicing.length > 0}
								<div class="text-xs text-[var(--accent-gold)] mt-1 flex items-center gap-1">
									<ArrowDown size={12} aria-hidden="true" /> Bass: {currentData.voicing[0]}
								</div>
							{/if}
						</div>
					{/if}
				</ChordCard>
				</div><!-- /flex-1 -->

				<!-- Next chord preview (In-Time look-ahead) — outer container always present so ChordCard width stays stable -->
				{#if inTimeMode && inTimeLookAhead}
					<div class="w-36 shrink-0 pt-2">
						{#if inTimeBarCount === inTimeBars && currentIdx < actualTotalChords - 1 && chordsWithNotes[currentIdx + 1]}
							<div class="flex flex-col items-center gap-1.5" transition:fade={{ duration: 120 }}>
								<span class="text-[10px] font-medium uppercase tracking-widest text-[var(--text-dim)]">Nächster</span>
								<div class="card w-full py-6 px-4 text-center opacity-60 hover:opacity-80 transition-opacity">
									<div class="text-2xl font-bold text-gradient leading-snug break-words">{chordsWithNotes[currentIdx + 1].chord}</div>
								</div>
							</div>
						{/if}
					</div>
				{/if}
				</div><!-- /flex row -->

				<!-- Instruction -->
				<div class="text-center text-sm text-[var(--text-muted)]">
					{#if !timerStarted}
						<p>{t('ui.get_ready')}</p>
					{:else if paused}
						<!-- hidden during pause -->
					{:else if inTimeMode}
						<p>{t('ui.play_beat_1')}</p>
					{:else if inputMode === 'microphone' && (micState === 'listening' || micState === 'analyzing')}
						<p>{t('ui.play_mic')}</p>
					{:else if inputMode === 'midi' && midiState === 'connected' && midiDevices.length > 0}
						<p>{t('ui.play_auto')}</p>
					{:else if tapGuessResult === 'correct'}
						<p class="text-[var(--accent-green)] font-semibold">{t('ui.tap_correct')}</p>
					{:else if tapGuessResult === 'wrong'}
						<p class="text-[var(--accent-red)] font-semibold">{t('ui.tap_wrong')}</p>
					{:else if isTapGuessMode}
						<p>{t('ui.tap_build')}</p>
					{:else if displayMode === 'verify' && playPhase === 'verifying'}
						<p>{t('ui.check_verify')}</p>
					{:else}
						<p>{t('ui.tap_space')}</p>
					{/if}
				</div>

				<!-- Primary action — visible on all viewports (no more hidden Space-only advance) -->
				{#if timerStarted && !paused && inputMode === 'none' && !inTimeMode}
					<div class="flex flex-col items-center gap-2 pt-1">
						<button
							class="btn btn-primary min-h-[var(--tap-min)] px-8 text-base font-semibold"
							onclick={nextChord}
						>
							{#if isTapGuessMode}
								{tapGuessNotes.size === 0 ? t('ui.show_me') : t('ui.check')}
							{:else}
								{currentIdx < actualTotalChords - 1 ? t('ui.next_chord') : t('ui.finish')}
							{/if}
						</button>
						<!-- Dedicated, always-available "show me the chord" help — for
						     beginners who don't yet recognise a name like E♭9. Only in
						     tap-guess mode, before the answer is revealed. -->
						{#if isTapGuessMode && playPhase !== 'verifying' && tapGuessNotes.size > 0}
							<button
								class="text-[13px] font-medium text-[var(--accent-amber)] underline decoration-dotted underline-offset-4 hover:text-[var(--primary)] transition-colors"
								onclick={revealTapGuess}
							>
								{t('ui.show_me_chord')}
							</button>
						{/if}
						<div class="flex flex-wrap justify-center gap-x-3 gap-y-1 text-[11px] text-[var(--text-dim)]">
							<span><kbd class="kbd">Space</kbd> {t('ui.shortcut_next')}</span>
							<span><kbd class="kbd">P</kbd> {t('ui.shortcut_pause')}</span>
							<span><kbd class="kbd">H</kbd> {t('ui.shortcut_lookahead')}</span>
							<span><kbd class="kbd">?</kbd> {t('ui.shortcut_explain')}</span>
							<span><kbd class="kbd">Esc</kbd> {t('ui.shortcut_back')}</span>
						</div>
					</div>
				{/if}

				</div>
			</div>
		{/if}

		<!-- ─── Look-ahead confirm dialog ─── -->
		{#if showLookAheadConfirm}
			<div
				class="fixed inset-0 z-40 bg-black/60"
				transition:fade={{ duration: 180 }}
				onclick={cancelLookAhead}
				role="presentation"
			></div>
			<div
				class="fixed bottom-0 left-0 right-0 z-50 mx-auto max-w-md bg-[var(--bg-card)] rounded-t-2xl border-t border-x border-[var(--border)] p-6 space-y-5 shadow-2xl"
				transition:fly={{ y: 120, duration: 300, opacity: 1 }}
				role="dialog"
				aria-modal="true"
			>
				<div class="flex items-start justify-between">
					<div>
						<h3 class="text-base font-bold">Mit Vorschau üben?</h3>
						<p class="text-sm text-[var(--text-muted)] mt-1">Im letzten Bar siehst du den nächsten Chord — ideal zum Einspielen. Die Session startet neu.</p>
					</div>
					<button
						class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[var(--bg-muted)] transition-colors text-2xl leading-none cursor-pointer text-[var(--text-dim)] hover:text-[var(--text)] shrink-0 ml-4"
						onclick={cancelLookAhead}
						aria-label="Abbrechen"
					><X size={20} aria-hidden="true" /></button>
				</div>
				<div class="grid grid-cols-2 gap-3">
					<button
						class="h-12 rounded-[var(--radius)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--text)] hover:text-[var(--text)] transition-colors cursor-pointer text-sm font-medium"
						onclick={cancelLookAhead}
					>{t('ui.continue_playing')}</button>
					<button
						class="h-12 rounded-[var(--radius)] bg-[var(--accent-amber)] text-[var(--bg)] font-semibold hover:opacity-90 transition-opacity cursor-pointer text-sm inline-flex items-center justify-center gap-2"
						onclick={confirmLookAhead}
					><Eye size={16} aria-hidden="true" /> Neu starten mit Vorschau</button>
				</div>
			</div>
		{/if}

		<!-- ─────── Ear Training Screen ─────── -->
		{#if screen === 'ear-training'}
			<div in:fly={{ y: 20, duration: 300, delay: 50 }}>
			<div class="flex items-center justify-between mb-6">
				<button
					class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--text)] hover:text-[var(--text)] transition-colors cursor-pointer text-sm font-medium"
					onclick={resetToSetup}
					title={`${t('ui.back_setup')} (ESC)`}
				>
					<ArrowLeft size={16} aria-hidden="true" /> {t('ui.back')}
				</button>
				<div class="flex items-center gap-3">
					<div class="text-sm text-[var(--text-muted)]">
						<span class="font-semibold text-[var(--accent-amber)]">{t('ui.ear_training')}</span>
						<span class="mx-1">·</span>
						<span class="capitalize">{t('settings.difficulty_' + difficulty)}</span>
					</div>
					<button
						class="w-7 h-7 rounded-full border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--accent-amber)] hover:text-[var(--accent-amber)] transition-colors cursor-pointer flex items-center justify-center text-sm"
						onclick={openSettingsFromGame}
						title="Settings (S)"
					><Settings size={16} aria-hidden="true" /></button>
				</div>
			</div>

			<div class="w-full space-y-6">
				<!-- Input status -->
				{#if inputMode === 'midi'}
					<MidiStatus
						state={midiState}
						devices={midiDevices}
						selectedDeviceId={midiSelectedDeviceId}
						activeNoteCount={midiActiveNotes.size}
						onSelectDevice={handleMidiSelectDevice}
						onConnect={handleMidiConnect}
					/>
				{:else if inputMode === 'microphone'}
					<MicStatus
						state={micState}
						activeNoteCount={midiActiveNotes.size}
						onConnect={() => audioInput.init()}
					/>
				{/if}

				<!-- Progress -->
				<div>
					<div class="flex justify-between text-sm mb-2 text-[var(--text-muted)]">
						<span>{t('ui.chord_progress', { current: currentIdx + 1, total: actualTotalChords })}</span>
						<span>
							{earTrainingTotal > 0 ? `${t('ui.accuracy')}: ${Math.round((earTrainingCorrect / earTrainingTotal) * 100)}%` : ''}
						</span>
					</div>
					<div class="h-1.5 bg-[var(--bg-muted)] rounded-full overflow-hidden">
						<div
							class="h-full bg-[var(--accent-amber)] transition-all duration-300 rounded-full"
							style="width: {progress}%"
						></div>
					</div>
				</div>

				<!-- Start overlay -->
				{#if !timerStarted}
					<div class="text-center py-4">
						<button
							class="px-8 py-3 rounded-[var(--radius)] bg-[var(--accent-amber)] text-black font-semibold text-lg hover:brightness-110 transition-all cursor-pointer shadow-lg inline-flex items-center justify-center gap-2"
							onclick={beginEarTraining}
						>
							<Ear size={20} aria-hidden="true" /> {t('ui.ear_training_start')}
						</button>
						<p class="mt-3 text-xs text-[var(--text-muted)]">{t('ui.ear_training_desc')}</p>
					</div>
				{/if}

				<!-- Chord card (hidden or revealed) -->
				{#if timerStarted}
					<ChordCard
						chord={currentChord}
						system={notationSystem}
						onclick={() => earTrainingRevealed ? earTrainingNext() : earTrainingReveal()}
						hideChordName={!earTrainingRevealed}
					>
						<!-- Piano keyboard — always interactive for click-to-play -->
						{#if earTrainingRevealed}
							<div class="mt-8">
								<PianoKeyboard
									chordData={currentData}
									accidentalPref={accidentals}
									showVoicing={true}
									midiEnabled={inputActive}
									midiActiveNotes={midiActiveNotes}
									midiExpectedPitchClasses={expectedPitchClasses}
									interactive={true}
									onKeyClick={handleEarPianoClick}
									selectedPitchClasses={earGuessNotes}
								/>
							</div>
						{:else}
							<div class="mt-8">
								<PianoKeyboard
									chordData={null}
									accidentalPref={accidentals}
									showVoicing={false}
									midiEnabled={inputActive}
									midiActiveNotes={midiActiveNotes}
									midiExpectedPitchClasses={expectedPitchClasses}
									interactive={true}
									onKeyClick={handleEarPianoClick}
									selectedPitchClasses={earGuessNotes}
								/>
							</div>
						{/if}

						<!-- Guess controls (only before reveal) -->
						{#if !earTrainingRevealed}
							<div class="mt-4 flex flex-col items-center gap-3">
								<!-- Mode toggle + note count -->
								<div class="flex items-center gap-3">
									<button
										class="px-3 py-1 text-xs rounded-full border transition-colors cursor-pointer inline-flex items-center justify-center gap-1.5
											{earSelectMode
												? 'border-[var(--accent-amber)] bg-[var(--accent-amber)]/15 text-[var(--accent-amber)]'
												: 'border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--accent-amber)] hover:text-[var(--accent-amber)]'}"
										onclick={(e) => { e.stopPropagation(); earSelectMode = !earSelectMode; }}
										title={earSelectMode ? t('ui.ear_mode_preview') : t('ui.ear_mode_select')}
									>
										{#if earSelectMode}<Target size={14} aria-hidden="true" /> {t('ui.ear_mode_select')}{:else}<Piano size={14} aria-hidden="true" /> {t('ui.ear_mode_preview')}{/if}
									</button>
									{#if earGuessNotes.size > 0}
										<span class="text-xs text-[var(--text-muted)]">
											{earGuessNotes.size} {earGuessNotes.size === 1 ? t('ui.ear_note_singular') : t('ui.ear_notes_plural')}
										</span>
									{/if}
								</div>

								<!-- Submit + Clear buttons -->
								{#if earGuessNotes.size > 0}
									<div class="flex gap-2" transition:fade={{ duration: 150 }}>
										<button
											class="px-4 py-1.5 text-sm rounded-[var(--radius-sm)] font-medium transition-all cursor-pointer inline-flex items-center justify-center gap-1.5
												{earGuessResult === 'correct'
													? 'bg-[var(--accent-green)] text-white'
													: earGuessResult === 'wrong'
														? 'bg-[var(--accent-red)] text-white animate-shake'
														: 'bg-[var(--accent-amber)] text-black hover:brightness-110'}"
											onclick={(e) => { e.stopPropagation(); submitEarGuess(); }}
										>
											{#if earGuessResult === 'correct'}<Check size={16} aria-hidden="true" /> {t('ui.correct')}{:else if earGuessResult === 'wrong'}<X size={16} aria-hidden="true" /> {t('ui.ear_try_again')}{:else}<CornerDownLeft size={16} aria-hidden="true" /> {t('ui.ear_check')}{/if}
										</button>
										<button
											class="px-3 py-1.5 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--text)] hover:text-[var(--text)] transition-colors cursor-pointer"
											onclick={(e) => { e.stopPropagation(); clearEarGuess(); }}
										>
											{t('ui.ear_clear')}
										</button>
									</div>
								{/if}
							</div>
						{/if}

						<!-- Input feedback -->
						{#if inputActive && midiMatchResult && midiActiveNotes.size > 0}
							<div class="mt-4 text-center">
								{#if midiMatchResult.correct}
									<span class="text-[var(--accent-green)] font-semibold text-lg inline-flex items-center gap-1"><Check size={18} aria-hidden="true" /> {t('ui.correct')}</span>
								{:else if midiMatchResult.accuracy > 0}
									<span class="text-[var(--accent-amber)] text-sm">
										{t('ui.keep_trying', { percent: Math.round(midiMatchResult.accuracy * 100) })}
									</span>
								{:else}
									<span class="text-[var(--accent-red)] text-sm">{t('ui.wrong_notes')}</span>
								{/if}
							</div>
						{/if}

						<!-- Listen again button -->
						<div class="mt-4 text-center">
							<button
								class="px-4 py-1.5 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--accent-amber)] hover:text-[var(--accent-amber)] transition-colors cursor-pointer inline-flex items-center justify-center gap-1.5"
								onclick={(e) => { e.stopPropagation(); replayChord(); }}
							>
								<Music size={16} aria-hidden="true" /> {t('ui.listen_again')}
							</button>
						</div>
					</ChordCard>

					<!-- Instruction -->
					<div class="text-center text-sm text-[var(--text-muted)]">
						{#if earTrainingRevealed}
							<p>{t('ui.ear_training_revealed')}</p>
						{:else if inputActive}
							<p>{t('ui.ear_training_listen')}</p>
						{:else}
							<p>{t('ui.ear_piano_hint')}</p>
						{/if}
					</div>
				{/if}
			</div>
			</div>
		{/if}

		<!-- ─────── Results Screen ─────── -->
		{#if screen === 'finished'}
			<div in:scale={{ start: 0.95, duration: 300, delay: 50 }} style="transform-origin: center top">
			<!-- Back button -->
			<div class="mb-4">
				<button
					class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--text)] hover:text-[var(--text)] transition-colors cursor-pointer text-sm font-medium"
					onclick={resetToSetup}
				>
					<ArrowLeft size={16} aria-hidden="true" /> {t('ui.back_setup')}
				</button>
			</div>
			<Results
				{chordsWithNotes}
				totalChords={actualTotalChords}
				elapsedMs={elapsedMs > 0 ? elapsedMs : 0}
				{difficulty}
				{notation}
				{voicing}
				{displayMode}
				{accidentals}
				{notationSystem}
				{progressionMode}
				midiEnabled={inputActive}
				{midiAccuracy}
				inTimeModeActive={inTimeMode}
				avgTimingMs={inTimeTimingOffsets.length > 0
					? Math.round(inTimeTimingOffsets.filter(t => t < 900).reduce((a,b) => a+b, 0) / Math.max(1, inTimeTimingOffsets.filter(t => t < 900).length))
					: 0}
				{earTrainingCorrect}
				{earTrainingTotal}
				vlModeActive={voiceLeadingEnabled && vlMode !== 'guided' ? vlMode : ''}
				vlAvgMovement={vlMovementScores.length > 0 ? Math.round(vlMovementScores.reduce((a, b) => a + b, 0) / vlMovementScores.length) : 0}
				{vlOptimalCount}
				vlTotalChords={vlMovementScores.length}
				onrestart={restartGame}
				onreset={resetToSetup}
				candrillweak={hasWeakSpots()}
				ondrillweak={startWeakDrill}
			/>
			</div>
		{/if}

		<!-- ─────── Coach: Teacher Feedback Screen ─────── -->
		{#if screen === 'coach-feedback'}
			<div in:scale={{ start: 0.95, duration: 300, delay: 50 }} style="transform-origin: center top" class="mx-auto max-w-[560px]">
				<div class="surface-glass rounded-2xl p-6 sm:p-8 flex flex-col gap-6">
					<div class="flex flex-col items-center gap-3 text-center">
						<span class="grid h-14 w-14 place-items-center rounded-full bg-[var(--primary-muted)] text-[var(--primary)]" aria-hidden="true">
							<Icon name="weak-spots" size={30} />
						</span>
						<h1 class="text-xl sm:text-2xl font-bold text-(--text)">{t('coach.feedback.title')}</h1>
					</div>

					<!-- Teacher statements (honest, from promotion/hold decisions) -->
					{#if coachFeedback.length > 0}
						<ul class="flex flex-col gap-2.5">
							{#each coachFeedback as stmt, i (i)}
								<li class="flex items-start gap-2.5 text-[var(--text-base)] leading-relaxed text-(--text)">
									<span class="mt-1 shrink-0 text-[var(--primary)]" aria-hidden="true"><Check size={16} /></span>
									<span>{t(stmt.key, localizeCoachParams(stmt.params))}</span>
								</li>
							{/each}
						</ul>
					{/if}

					<!-- System-detected verdict — the app never asks "too easy?". -->
					{#if coachVerdict === 'excellent'}
						<div class="flex items-center justify-center gap-2 rounded-[var(--radius)] bg-[var(--success-muted,var(--primary-muted))] px-4 py-3 text-center text-sm font-medium text-(--text)">
							<Check size={16} class="text-(--accent-green)" />
							{t('coach.verdict.excellent')}
						</div>
					{:else if coachVerdict === 'struggling' && !coachFeedbackGiven}
						<div class="flex flex-col gap-2 rounded-[var(--radius)] border border-[var(--border)] px-4 py-3">
							<span class="text-sm text-(--text-muted)">{t('coach.verdict.struggling')}</span>
							<button
								type="button"
								onclick={startEasierAndContinue}
								class="self-start rounded-[var(--radius)] border-2 border-[var(--primary)] px-3 py-2 text-sm font-medium text-(--primary) transition-colors hover:bg-[var(--primary-muted)]"
							>
								{t('coach.verdict.start_easier')}
							</button>
						</div>
					{/if}

					<!-- Keep going (next building session) / Done for today -->
					<div class="flex flex-col gap-2">
						<button
							type="button"
							onclick={restartCoachSession}
							class="w-full rounded-[var(--radius)] bg-[var(--primary)] px-4 py-3.5 text-base font-semibold text-white transition-opacity hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)]"
						>
							{t('coach.feedback.keep_going')}
						</button>
						<button
							type="button"
							onclick={() => { endCoachMode(); resetToSetup(); }}
							class="w-full rounded-[var(--radius)] px-4 py-2 text-sm font-medium text-(--text-muted) transition-colors hover:text-(--text)"
						>
							{t('coach.feedback.enough_today')}
						</button>
					</div>
				</div>
			</div>
		{/if}
	</div>
</main>

<!-- ─────── Coach: Between-block Transition Overlay ─────── -->
{#if coachTransition}
	<button
		type="button"
		class="fixed inset-0 z-50 flex items-center justify-center bg-[var(--bg)]/85 backdrop-blur-sm p-6"
		onclick={advanceCoachBlock}
		in:fade={{ duration: 180 }}
		aria-label={t('coach.transition.tap_continue')}
	>
		<div class="surface-glass flex max-w-[420px] flex-col items-center gap-4 rounded-2xl px-6 py-8 text-center" in:scale={{ start: 0.94, duration: 220 }}>
			<div class="flex items-center gap-2 text-[var(--success)]">
				<Check size={20} aria-hidden="true" />
				<span class="text-base font-semibold">{t('coach.done.' + coachTransition.doneKind)}</span>
			</div>
			<div class="h-px w-16 bg-[var(--border)]" aria-hidden="true"></div>
			<p class="text-lg font-medium text-(--text)">
				{t(coachTransition.next.labelKey, localizeCoachParams(coachTransition.next.labelParams))}
			</p>
			<span class="text-xs text-(--text-dim)">{t('coach.transition.tap_continue')}</span>
		</div>
	</button>
{/if}

{#if midiDisconnectToast}
	<MidiToast
		message={midiDisconnectToast}
		onDismiss={() => (midiDisconnectToast = null)}
		onReconnect={() => { midiDisconnectToast = null; midi.init(); }}
	/>
{/if}

{#if showOnboarding}
	<HabitOnboarding
		oncomplete={(config) => {
			habitProfile.dailyGoalMinutes = config.dailyGoalMinutes;
			habitProfile.preferredTime = config.preferredTime as TimeOfDay;
			habitProfile.notificationsEnabled = config.notificationsEnabled;
			habitProfile.notificationTime = config.notificationTime;
			habitProfile.onboardingDone = true;
			saveHabitProfile(habitProfile);
			showOnboarding = false;
			// Reload profile to get generated goals
			habitProfile = loadHabitProfile();
			// Schedule notifications if opted in
			if (config.notificationsEnabled) {
				notificationCleanup = scheduleDailyReminder(habitProfile);
				streakSaverCleanup = scheduleStreakSaver(habitProfile);
			}
		}}
	/>
{/if}

{#if pendingCelebrations.length > 0}
	<CelebrationOverlay
		celebrations={pendingCelebrations}
		ondismiss={() => { pendingCelebrations = []; }}
	/>
{/if}

{#if showExplain && currentData}
	<ExplainPanel
		chordData={currentData}
		{voicing}
		onclose={() => { showExplain = false; }}
	/>
{/if}

<UpgradeSheet bind:open={upgradeOpen} feature={upgradeFeature} teaserMode={upgradeTeaser} />

<style>
	/* Ambient page wash — token-based so it flips with the theme. */
	.train-page {
		background:
			radial-gradient(ellipse 80% 40% at 50% 0%, color-mix(in srgb, var(--primary) 6%, transparent) 0%, transparent 70%),
			linear-gradient(180deg, var(--bg) 0%, color-mix(in srgb, var(--bg) 88%, var(--primary)) 35%, var(--bg) 100%);
	}

	/* Touch devices (iPad): maximum screen real-estate */
	@media (hover: none) and (pointer: coarse) and (min-width: 768px) {
		.train-page {
			padding: 1rem;
		}
		.train-layout {
			grid-template-columns: 1fr 320px;
			gap: 1rem;
		}
	}

	/* Shake animation for wrong guess */
	:global(.animate-shake) {
		animation: shake 0.4s ease-in-out;
	}
	@keyframes shake {
		0%, 100% { transform: translateX(0); }
		20% { transform: translateX(-4px); }
		40% { transform: translateX(4px); }
		60% { transform: translateX(-3px); }
		80% { transform: translateX(3px); }
	}
</style>
