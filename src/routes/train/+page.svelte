<script lang="ts">
	import { onMount } from 'svelte';
	import { fly, fade, scale } from 'svelte/transition';
	import { t } from '$lib/i18n';
	import GameSettings from '$lib/components/GameSettings.svelte';
	import ChordCard from '$lib/components/ChordCard.svelte';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import Results from '$lib/components/Results.svelte';
	import MidiStatus from '$lib/components/MidiStatus.svelte';
	import MidiToast from '$lib/components/MidiToast.svelte';
	import ProgressDashboard from '$lib/components/ProgressDashboard.svelte';
	import ProgressionEditor from '$lib/components/ProgressionEditor.svelte';
	import ProgressionPlayer from '$lib/components/ProgressionPlayer.svelte';
	import ProgressionResults from '$lib/components/ProgressionResults.svelte';
	import HabitDashboard from '$lib/components/HabitDashboard.svelte';
	import HabitOnboarding from '$lib/components/HabitOnboarding.svelte';
	import CelebrationOverlay from '$lib/components/CelebrationOverlay.svelte';
	import type { HabitProfile, CelebrationEvent, QuickStartSuggestion, TimeOfDay } from '$lib/engine/habits';
	import { loadHabitProfile, saveHabitProfile, processSessionHabits, scheduleDailyReminder, scheduleStreakSaver } from '$lib/services/habits';
	import { MidiService } from '$lib/services/midi';
	import type { MidiConnectionState, MidiDevice, ChordMatchResult } from '$lib/services/midi';
	import { saveSession, loadSettings, saveSettings, loadStreak, recordPracticeDay, recordPlanUsed, loadHistory, computeStats, type ProgressStats, type StreakData, type ChordTiming } from '$lib/services/progress';
	import { playChord, stopAll, startMetronome, stopMetronome, setMetronomeBpm, isMetronomeRunning, disposeAll, setSoundPreset, getSoundPreset, SOUND_PRESETS, type SoundPreset } from '$lib/services/audio';
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

	const PROGRESSION_KEYS: Record<ProgressionMode, string> = {
		'random': 'settings.progression_random',
		'2-5-1': 'settings.progression_251',
		'cycle-of-4ths': 'settings.progression_cycle',
		'1-6-2-5': 'settings.progression_turnaround',
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
	let displayMode: DisplayMode = $state('always');
	let accidentals: AccidentalPreference = $state('both');
	let notationSystem: NotationSystem = $state('international');
	let totalChords = $state(20);
	let progressionMode: ProgressionMode = $state('random');
	let midiEnabled = $state(false);
	let streak: StreakData = $state({ current: 0, best: 0, lastDate: '' });
	let dashStats: ProgressStats = $state(computeStats([]));

	// ─── Habit Engine state ─────────────────────────────────────
	let habitProfile: HabitProfile = $state(null as unknown as HabitProfile);
	let showOnboarding = $state(false);
	let pendingCelebrations: CelebrationEvent[] = $state([]);
	let notificationCleanup: (() => void) | null = $state(null);
	let streakSaverCleanup: (() => void) | null = $state(null);

	// ─── Audio / Metronome settings ──────────────────────────────
	let audioEnabled = $state(true);
	let metronomeEnabled = $state(false);
	let metronomeBpm = $state(80);
	let currentBeat = $state(0);
	let soundPreset: SoundPreset = $state(getSoundPreset());

	// ─── Game state ──────────────────────────────────────────────
	type Screen = 'setup' | 'playing' | 'finished' | 'custom-editor' | 'custom-playing' | 'custom-results' | 'ear-training';
	type PlayPhase = 'playing' | 'verifying';

	// ─── New mode settings ───────────────────────────────────────
	let inTimeMode = $state(false);
	let inTimeBars = $state(2);
	let adaptiveEnabled = $state(false);
	let voiceLeadingEnabled = $state(false);

	// ─── In-Time mode state ──────────────────────────────────────
	let inTimeBeatCount = $state(0);
	let inTimeBarCount = $state(0);
	let inTimeTimingOffsets: number[] = $state([]);
	let inTimeChordPlayedAt: number | null = $state(null);
	let inTimeBeatOneTime = $state(0);

	// ─── Ear Training state ──────────────────────────────────────
	let earTrainingRevealed = $state(false);
	let earTrainingCorrect = $state(0);
	let earTrainingTotal = $state(0);

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
	let playPhase: PlayPhase = $state<PlayPhase>('playing');
	let timerStarted = $state(false);
	let paused = $state(false);
	let pauseAccumulated = $state(0);
	let pauseStart = $state(0);
	let showExerciseInfo = $state(false);
	let currentIdx = $state(0);
	let chords: string[] = $state([]);
	let chordsWithNotes: ChordWithNotes[] = $state([]);
	let startTime = $state(0);
	let endTime = $state(0);
	let now = $state(0);
	let timerHandle: ReturnType<typeof setInterval> | null = $state(null);
	let chordTimings: ChordTiming[] = $state([]);
	let chordStartTime = $state(0);

	// ─── Custom Progression state ────────────────────────────────
	let customChords: CustomChord[] = $state([]);
	let customBpm = $state(120);
	let customLoops = $state(2);
	let customName = $state('');
	let customEvaluation: SessionEvaluation | null = $state(null);

	// ─── MIDI disconnect toast ───────────────────────────────────
	let midiDisconnectToast: string | null = $state(null);

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

	function getStatusbarWeekDots(s: StreakData): boolean[] {
		const dots: boolean[] = Array(7).fill(false);
		if (s.current === 0 || !s.lastDate) return dots;
		const practiceDates = new Set<string>();
		const lastDate = new Date(s.lastDate + 'T00:00:00');
		for (let i = 0; i < s.current; i++) {
			const d = new Date(lastDate);
			d.setDate(lastDate.getDate() - i);
			practiceDates.add(d.toISOString().slice(0, 10));
		}
		const today = new Date();
		const jsDay = today.getDay();
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

	const sbWeekDots = $derived(getStatusbarWeekDots(streak));
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
			const result = generateProgression(progressionMode, accidentals, notation, totalChords);
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
		const available = CHORDS_BY_DIFFICULTY[difficulty];
		const pool = getNotePool(accidentals);
		const newChords: string[] = [];
		const newData: ChordWithNotes[] = [];
		let last = '';

		// Adaptive mode: use weighted selection
		if (adaptiveEnabled && progressionMode === 'random') {
			const history = loadHistory().flatMap(s => s.chordTimings ?? []);
			const weighted = getWeightedChordPool(history, available, pool);
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

		// Compute stable keyboard range for the session
		if (voiceLeadingEnabled && chordsWithNotes.length > 0) {
			sessionOctaves = computeSessionOctaves(chordsWithNotes, accidentals);
		} else {
			sessionOctaves = null;
		}

		// Re-register MIDI handler (ProgressionPlayer may have overwritten it)
		midi.onNotes(handleMidiNotes);
		if (timerHandle) clearInterval(timerHandle);
		timerHandle = null;

		// Init MIDI if enabled
		if (midiEnabled && midiState === 'disconnected') {
			midi.init();
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
			midiEnabled,
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
			playChord(chordsWithNotes[0].voicing).catch(() => {});
		}

		// In-Time mode: always start metronome & use beat callback for chord changes
		if (inTimeMode) {
			inTimeBeatCount = 0;
			inTimeBarCount = 0;
			inTimeBeatOneTime = Date.now();
			metronomeEnabled = true;
			startMetronome(metronomeBpm, 4, (beat) => {
				currentBeat = beat;
				handleInTimeBeat(beat);
			});
		} else if (metronomeEnabled) {
			// Standard metronome
			startMetronome(metronomeBpm, 4, (beat) => {
				currentBeat = beat;
			});
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
				startMetronome(metronomeBpm, 4, (beat) => { currentBeat = beat; });
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
		// Apply plan settings
		difficulty = plan.settings.difficulty;
		notation = plan.settings.notation;
		voicing = plan.settings.voicing;
		displayMode = plan.settings.displayMode;
		accidentals = plan.settings.accidentals;
		progressionMode = plan.settings.progressionMode;
		totalChords = plan.settings.totalChords;

		// Apply special mode settings based on plan ID
		if (plan.id === 'in-time-comping') {
			inTimeMode = true;
			inTimeBars = 2;
			metronomeBpm = 100;
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

		// Verify mode: first press shows voicing, second press advances
		// Skip verify phase when MIDI is doing the verification
		if (displayMode === 'verify' && playPhase === 'playing' && !midiEnabled) {
			playPhase = 'verifying';
			// Play chord audio when revealing the voicing
			if (audioEnabled && currentData) {
				playChord(currentData.voicing).catch(() => {});
			}
			return;
		}

		playPhase = 'playing';
		midiMatchResult = null;
		vlValidation = null;
		midi.releaseAll();

		// Record timing for the chord we're leaving
		const nowMs = Date.now();
		if (currentData) {
			chordTimings.push({
				chord: currentData.chord,
				root: currentData.root,
				durationMs: nowMs - chordStartTime,
			});
		}
		chordStartTime = nowMs;

		if (currentIdx < actualTotalChords - 1) {
			currentIdx++;
			// Compute voice leading for the new chord
			updateVoiceLeading();
			// Play chord audio on advance
			if (audioEnabled && chordsWithNotes[currentIdx]) {
				playChord(chordsWithNotes[currentIdx].voicing).catch(() => {});
			}
		} else {
			endGame();
		}
	}

	function endGame() {
		endTime = Date.now();
		screen = 'finished';

		// Record timing for the last chord
		if (currentData) {
			chordTimings.push({
				chord: currentData.chord,
				root: currentData.root,
				durationMs: endTime - chordStartTime,
			});
		}

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
			settings: {
				difficulty,
				notation,
				voicing,
				displayMode,
				accidentals,
				progressionMode,
			},
			midi: {
				enabled: midiEnabled,
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
	}

	function restartGame() {
		startGame();
	}

	function resetToSetup() {
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
		// Re-register main MIDI handler (ear training may have overridden it)
		midi.onNotes(handleMidiNotes);
	}

	// ─── Custom Progression handlers ─────────────────────────────
	function openCustomEditor() {
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

		if (screen !== 'playing' || !currentData || !midiEnabled) return;

		// ── Voice Leading modes B/C: custom validation ──
		if (voiceLeadingEnabled && vlMode !== 'guided' && activeNotes.size > 0) {
			handleVLModeMidi(activeNotes);
			return;
		}

		// ── Standard / Guided mode validation ──
		let result: ChordMatchResult;
		if (voicing.startsWith('inversion-') && currentData.voicing.length > 0) {
			result = midi.checkChordWithBass(currentData.voicing, currentData.voicing[0]);
		} else {
			result = midi.checkChordLenient(currentData.voicing);
		}
		midiMatchResult = result;

		if (result.correct && activeNotes.size > 0) {
			midiTotalAttempts++;
			midiCorrectCount++;

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
			}
		} else if (vlMode === 'free') {
			// Get all valid pitch-class sets for this chord
			const validSets = getValidPCSets(currentData.root, currentData.type, accidentals);
			const result = validateFreeVoicing(midiNotes, validSets, prevVoicing);
			vlValidation = result;

			if (result.valid) {
				midiTotalAttempts++;
				midiCorrectCount++;
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
				if (midiNotes.length >= 3) midiTotalAttempts++;
			}
		}
	}

	function handleMidiConnect() {
		midi.init();
	}

	function handleMidiSelectDevice(deviceId: string) {
		midi.selectDevice(deviceId);
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
			playChord(currentData.voicing);
		}
	}

	// ─── In-Time Mode Logic ──────────────────────────────────────

	/** Called on each metronome beat in In-Time mode */
	function handleInTimeBeat(beat: number) {
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
					chordTimings.push({
						chord: currentData.chord,
						root: currentData.root,
						durationMs: nowMs - chordStartTime,
					});
				}
				chordStartTime = nowMs;

				if (currentIdx < actualTotalChords - 1) {
					currentIdx++;
					midiMatchResult = null;
					inTimeChordPlayedAt = null;
					if (audioEnabled && chordsWithNotes[currentIdx]) {
						playChord(chordsWithNotes[currentIdx].voicing).catch(() => {});
					}
					// Re-check currently held MIDI notes against the new chord
					if (midiEnabled && midiActiveNotes.size > 0) {
						handleMidiNotes(midi.activeNotes as Set<number>);
					}
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
		voiceLeadingInfo = null;
		midi.releaseAll();
		midi.onNotes(handleEarTrainingMidi);

		if (midiEnabled && midiState === 'disconnected') {
			midi.init();
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
			chordTimings.push({
				chord: currentData.chord,
				root: currentData.root,
				durationMs: nowMs - chordStartTime,
			});
		}
		chordStartTime = nowMs;

		earTrainingRevealed = false;
		midiMatchResult = null;
		midi.releaseAll();

		if (currentIdx < actualTotalChords - 1) {
			currentIdx++;
			// Play next chord
			if (chordsWithNotes[currentIdx]) {
				playChord(chordsWithNotes[currentIdx].voicing).catch(() => {});
			}
		} else {
			endTime = Date.now();
			screen = 'finished';
			if (currentData) {
				chordTimings.push({
					chord: currentData.chord,
					root: currentData.root,
					durationMs: endTime - chordStartTime,
				});
			}
			if (timerHandle) clearInterval(timerHandle);
			timerHandle = null;
			saveSession({
				timestamp: Date.now(),
				elapsedMs: endTime - startTime,
				totalChords: actualTotalChords,
				avgMs: (endTime - startTime) / actualTotalChords,
				chordTimings: [...chordTimings],
				settings: { difficulty, notation, voicing, displayMode, accidentals, progressionMode },
				midi: { enabled: midiEnabled, accuracy: earTrainingTotal > 0 ? Math.round((earTrainingCorrect / earTrainingTotal) * 100) : 0 },
			});
			streak = recordPracticeDay();
		}
	}

	function handleEarTrainingMidi(activeNotes: Set<number>) {
		midiActiveNotes = new Set(activeNotes);
		if (screen !== 'ear-training' || !currentData || !midiEnabled) return;

		const result = midi.checkChordLenient(currentData.voicing);
		midiMatchResult = result;

		if (result.correct && activeNotes.size > 0) {
			earTrainingCorrect++;
			earTrainingTotal++;
			earTrainingRevealed = true;

			// Auto-advance after a delay
			if (!autoAdvanceTimeout) {
				autoAdvanceTimeout = setTimeout(() => {
					autoAdvanceTimeout = null;
					earTrainingNext();
				}, 1200);
			}
		}
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
		// Play a preview chord
		if (currentData) {
			playChord(currentData.voicing).catch(() => {});
		}
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
		if (e.code === 'KeyP' && screen === 'playing' && timerStarted) {
			e.preventDefault();
			togglePause();
		}
		if (e.code === 'Escape' && (screen === 'playing' || screen === 'ear-training')) {
			e.preventDefault();
			resetToSetup();
		}
	}

	onMount(() => {
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
			midiEnabled = saved.midiEnabled;
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

		// MIDI setup — always probe for devices so we can show auto-detection
		midi.onNotes(handleMidiNotes);
		midi.onConnection((state) => {
			midiState = state;
		});
		midi.onDevices((devices) => {
			midiDevices = [...devices];
			if (devices.length > 0) {
				midiSelectedDeviceId = midi.selectedDeviceId;
				// Auto-enable MIDI when a device is detected
				if (!midiEnabled) {
					midiEnabled = true;
				}
			}
		});

		midi.onDisconnect((deviceName) => {
			midiDisconnectToast = t('ui.disconnected_reconnect', { device: deviceName });
		});

		// Always init MIDI to detect devices (even if not yet enabled)
		midi.init();

		window.addEventListener('keydown', handleKeydown);
		return () => {
			window.removeEventListener('keydown', handleKeydown);
			if (timerHandle) clearInterval(timerHandle);
			if (autoAdvanceTimeout) clearTimeout(autoAdvanceTimeout);
			midi.destroy();
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

<main class="flex-1 py-8 sm:py-12 px-4" style="background: radial-gradient(
  ellipse 80% 40% at 50% 0%,
  rgba(251, 146, 60, 0.04) 0%,
  transparent 70%
), linear-gradient(180deg, var(--bg) 0%, #110e0a 30%, #12100c 70%, var(--bg) 100%);">
	<div class="max-w-4xl mx-auto">
		<!-- ─────── Setup Screen ─────── -->
		{#if screen === 'setup'}
			<div in:fade={{ duration: 200, delay: 100 }}>
				<!-- Dashboard header (full width) -->
				{#if habitProfile}
					<HabitDashboard
						profile={habitProfile}
						{streak}
						weekDots={sbWeekDots}
						midiConnected={midiState === 'connected' && midiDevices.length > 0}
						onquickstart={(suggestion) => {
							const plan = PRACTICE_PLANS.find(p => p.id === suggestion.planId);
							if (plan) {
								startPlan(plan);
							} else {
								startGame();
							}
						}}
					/>
				{:else}
					<div class="dashboard-header">
						<div class="dashboard-top">
							<div class="greeting-streak">
								<span class="greeting">{greeting}!</span>
								<div class="streak-inline">
									<img src="/elements/images/streak-flame.webp" width="18" height="18" alt="" style="mix-blend-mode: lighten; object-fit: contain;" />
									<span class="streak-num">{streak.current}</span>
									<span class="streak-label">day streak</span>
								</div>
							</div>
							<div class="midi-pill" class:connected={midiState === 'connected' && midiDevices.length > 0}>
								<img src="/elements/images/midi-connect.webp" width="14" height="14" alt="MIDI" style="mix-blend-mode: lighten; object-fit: contain;" />
								<span>{midiState === 'connected' && midiDevices.length > 0 ? (midiDevices[0]?.name ?? 'MIDI') : 'No MIDI'}</span>
							</div>
						</div>
					</div>
				{/if}

				<!-- Two-column layout -->
				<div class="train-layout">
					<!-- Left: Recommended plan + Plans grid -->
					<div class="train-main">
						<GameSettings
							bind:difficulty
							bind:notation
							bind:voicing={voicing}
							bind:displayMode
							bind:accidentals
							bind:notationSystem
							bind:totalChords
							bind:progressionMode
							bind:midiEnabled
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

					<!-- Right: Progress + Custom Progression + Custom Settings -->
					<div class="train-sidebar">
						<ProgressDashboard />

						<!-- Custom Progression -->
						<button
							class="card w-full p-5 text-left cursor-pointer hover:border-[var(--border-hover)] transition-colors group"
							onclick={openCustomEditor}
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

						<!-- Training einrichten trigger -->
					<button
						class="card w-full p-5 sm:p-6 text-left cursor-pointer hover:border-[var(--border-hover)] transition-colors group"
						onclick={() => settingsOpen = true}
					>
						<div class="flex items-center gap-4">
							<img
								src="/elements/icons/icon-settings.webp"
								alt="Settings"
								width="48"
								height="48"
								loading="lazy"
								style="width:48px; height:48px; flex-shrink:0; mix-blend-mode:lighten; object-fit:contain; filter: drop-shadow(0 0 10px rgba(251,146,60,0.5));"
							/>
							<div class="flex-1 min-w-0">
								<div class="text-sm font-medium group-hover:text-[var(--primary)] transition-colors">{t('settings.custom_settings')}</div>
								<div class="text-xs text-[var(--text-dim)] mt-1 flex flex-wrap gap-2">
									<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full">
										{progressionMode === 'random' ? `${totalChords} ${t('results.chords')}` : t(PROGRESSION_KEYS[progressionMode])}
									</span>
									<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full capitalize">{t('settings.difficulty_' + difficulty)}</span>
									<span class="bg-[var(--bg-muted)] px-2 py-0.5 rounded-full">{t(VOICING_KEYS[voicing])}</span>
									{#if midiEnabled}
										<span class="bg-[var(--accent-green)]/20 text-[var(--accent-green)] px-2 py-0.5 rounded-full">MIDI</span>
									{/if}
								</div>
							</div>
							<div class="text-[var(--text-dim)] text-xl group-hover:text-[var(--primary)] transition-colors flex-shrink-0">→</div>
						</div>
					</button>
					</div>
				</div>
			</div>
		{/if}

		<!-- ─── Training einrichten Modal ─── -->
		{#if settingsOpen}
			<div
				class="fixed inset-0 z-40 bg-black/75"
				transition:fade={{ duration: 180 }}
				onclick={() => settingsOpen = false}
				role="presentation"
			></div>
			<div
				class="settings-modal"
				transition:fly={{ y: 500, duration: 340, opacity: 1 }}
				role="dialog"
				aria-modal="true"
			>
				<div class="settings-modal-header">
					<h2 class="text-base font-bold">{t('settings.custom_settings')}</h2>
					<button
						class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[var(--bg-muted)] transition-colors text-2xl leading-none cursor-pointer text-[var(--text-dim)] hover:text-[var(--text)]"
						onclick={() => settingsOpen = false}
						aria-label="Schließen"
					>×</button>
				</div>
				<div class="settings-modal-body space-y-6">
					<button
						class="w-full h-12 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] text-base font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer"
						onclick={() => { settingsOpen = false; startGame(); }}
					>▶ {t('settings.start_training')}</button>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.progression_mode')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.progression_desc')}</p>
						<div class="grid grid-cols-2 gap-3">
							{#each [
								{ val: 'random' as ProgressionMode, label: t('settings.progression_random'), sub: t('settings.progression_random_sub') },
								{ val: '2-5-1' as ProgressionMode, label: t('settings.progression_251'), sub: t('settings.progression_251_sub') },
								{ val: 'cycle-of-4ths' as ProgressionMode, label: t('settings.progression_cycle'), sub: t('settings.progression_cycle_sub') },
								{ val: '1-6-2-5' as ProgressionMode, label: t('settings.progression_turnaround'), sub: t('settings.progression_turnaround_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(progressionMode, opt.val)}" onclick={() => (progressionMode = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.midi_recognition')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.midi_desc')}</p>
						<div class="grid grid-cols-2 gap-3">
							{#each [
								{ val: false, label: t('settings.on_off_off'), sub: t('settings.midi_off_sub') },
								{ val: true, label: t('settings.on_off_on'), sub: t('settings.midi_on_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(midiEnabled, opt.val)}" onclick={() => (midiEnabled = opt.val)}>
									<div class="font-semibold text-sm">{opt.label}</div><div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
								</button>
							{/each}
						</div>
						<p class="mt-2 text-xs text-[var(--text-dim)]">{t('settings.midi_note')}</p>
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
						<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">🎹 {t('settings.voicing_left_hand')}</div>
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
						<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">🔄 {t('settings.voicing_inversions_group')}</div>
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
								{ val: 'verify' as DisplayMode, label: t('settings.display_mode_verify'), sub: midiEnabled ? t('settings.display_mode_verify_midi') : t('settings.display_mode_verify_sub') },
							] as opt}
								<button
									class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(displayMode, opt.val)} {opt.val === 'verify' && midiEnabled ? 'opacity-40 cursor-not-allowed' : ''}"
									onclick={() => { if (!(opt.val === 'verify' && midiEnabled)) displayMode = opt.val; }}
									disabled={opt.val === 'verify' && midiEnabled}
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
							</div>
						{/if}
					</fieldset>
					<fieldset>
						<legend class="text-sm font-medium mb-1">{t('settings.adaptive_mode')}</legend>
						<p class="text-xs text-[var(--text-dim)] mb-3">{t('settings.adaptive_desc')}</p>
						<div class="grid grid-cols-2 gap-3">
							{#each [
								{ val: false, label: t('settings.on_off_off'), sub: t('settings.adaptive_off_sub') },
								{ val: true, label: t('settings.on_off_on'), sub: t('settings.adaptive_on_sub') },
							] as opt}
								<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(adaptiveEnabled, opt.val)}" onclick={() => (adaptiveEnabled = opt.val)}>
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
						onclick={() => { settingsOpen = false; startEarTraining(); }}
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
				{midiEnabled}
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
			<div class="flex items-center justify-between mb-6">
				<button
					class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--text)] hover:text-[var(--text)] transition-colors cursor-pointer text-sm font-medium"
					onclick={resetToSetup}
					title={t('ui.back_setup')}
				>
					← {t('ui.back')}
				</button>
				<div class="flex items-center gap-3">
					<div class="text-sm text-[var(--text-muted)] text-right">
						<span class="font-semibold text-[var(--text)]">{t(VOICING_KEYS[voicing])}</span>
						<span class="mx-1">·</span>
						<span class="capitalize">{t('settings.difficulty_' + difficulty)}</span>
						<span class="mx-1">·</span>
						<span>{t(PROGRESSION_KEYS[progressionMode])}</span>
					</div>
					<button
						class="w-7 h-7 rounded-full border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer flex items-center justify-center text-sm"
						onclick={() => (showExerciseInfo = !showExerciseInfo)}
						title="Exercise info"
					>?</button>
				</div>
			</div>

			<!-- Exercise info panel -->
			{#if showExerciseInfo}
				<div class="max-w-3xl mx-auto mb-6 p-4 rounded-[var(--radius)] border border-[var(--primary)]/30 bg-[var(--primary-muted)]/50" transition:fly={{ y: -10, duration: 200 }}>
					<div class="flex items-start justify-between gap-4">
						<div class="space-y-2">
							<h3 class="font-semibold text-[var(--primary)]">{t('settings.voicing_' + voicing.replace(/-/g, '_'))}</h3>
							<p class="text-sm text-[var(--text-muted)]">{t('voicing_info.' + voicing.replace(/-/g, '_') + '_tip')}</p>
							<p class="text-xs font-mono text-[var(--text-dim)]">{t('ui.example')}: {VOICING_EXAMPLES[voicing]}</p>
						</div>
						<button
							class="text-[var(--text-muted)] hover:text-[var(--text)] cursor-pointer text-sm shrink-0"
							onclick={() => (showExerciseInfo = false)}
						>✕</button>
					</div>
				</div>
			{/if}

			<div class="max-w-3xl mx-auto space-y-6">
				<!-- MIDI status bar -->
				{#if midiEnabled}
					<div class="flex items-center justify-between">
						<MidiStatus
							state={midiState}
							devices={midiDevices}
							selectedDeviceId={midiSelectedDeviceId}
							activeNoteCount={midiActiveNotes.size}
							onSelectDevice={handleMidiSelectDevice}
							onConnect={handleMidiConnect}
						/>
						{#if midiTotalAttempts > 0}
							<span class="text-xs text-[var(--text-muted)] font-mono">
								Accuracy: {midiAccuracy}%
							</span>
						{/if}
						<a href="/midi-test" class="text-xs text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors underline underline-offset-2" title="Test your MIDI connection">
							MIDI Test →
						</a>
					</div>
				{/if}

				<!-- Audio / Metronome / Sound controls -->
				<div class="flex items-center gap-3 text-sm flex-wrap">
					<button
						class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-sm)] border transition-colors cursor-pointer {audioEnabled ? 'border-[var(--primary)] bg-[var(--primary-muted)] text-[var(--primary)]' : 'border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)]'}"
						onclick={() => (audioEnabled = !audioEnabled)}
						title={audioEnabled ? 'Mute audio' : 'Enable audio'}
					>
						{audioEnabled ? '🔊' : '🔇'} {t('ui.audio')}
					</button>
					{#if audioEnabled}
						<select
							class="px-2 py-1.5 rounded-[var(--radius-sm)] border border-[var(--border)] bg-[var(--bg)] text-[var(--text-muted)] text-xs cursor-pointer"
							value={soundPreset}
							onchange={(e) => changeSoundPreset((e.target as HTMLSelectElement).value as SoundPreset)}
						>
							{#each Object.entries(SOUND_PRESETS) as [key, preset]}
								<option value={key}>{preset.label}</option>
							{/each}
						</select>
					{/if}
					<button
						class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-sm)] border transition-colors cursor-pointer {metronomeEnabled ? 'border-[var(--accent-green)] bg-[var(--accent-green)]/10 text-[var(--accent-green)]' : 'border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)]'}"
						onclick={toggleMetronome}
					>
						{metronomeEnabled ? '⏸' : '▶'} {t('ui.metronome')}
					</button>
					{#if metronomeEnabled}
						<div class="flex items-center gap-2">
							<button
								class="w-7 h-7 rounded border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)] cursor-pointer flex items-center justify-center"
								onclick={() => updateBpm(metronomeBpm - 5)}
							>−</button>
							<span class="font-mono text-xs w-12 text-center">{metronomeBpm} {t('ui.bpm')}</span>
							<button
								class="w-7 h-7 rounded border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)] cursor-pointer flex items-center justify-center"
								onclick={() => updateBpm(metronomeBpm + 5)}
							>+</button>
						</div>
						<div class="flex items-center gap-1">
							{#each [1, 2, 3, 4] as beat}
								<div
									class="w-2.5 h-2.5 rounded-full transition-all duration-100 {currentBeat === beat
										? beat === 1
											? 'bg-[var(--accent-green)] scale-125'
											: 'bg-[var(--primary)] scale-110'
										: 'bg-[var(--border)]'}"
								></div>
							{/each}
						</div>
						{#if inTimeMode}
							<span class="text-xs text-[var(--accent-amber)] font-mono">
								Bar {Math.min(inTimeBarCount, inTimeBars)}/{inTimeBars}
							</span>
						{/if}
					{/if}
				</div>

				<!-- Progress bar + timer -->
				<div>
					<div class="flex justify-between text-sm mb-2 text-[var(--text-muted)]">
						<span>{t('ui.chord_progress', { current: currentIdx + 1, total: actualTotalChords })}</span>
						<div class="flex items-center gap-3">
							<span class="font-mono">{timerStarted ? formatTime(elapsedMs > 0 ? elapsedMs : 0) : '0:00.00'}</span>
							{#if timerStarted}
								<button
									class="flex items-center gap-1 text-xs px-2 py-0.5 rounded border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--text)] hover:text-[var(--text)] transition-colors cursor-pointer"
									onclick={togglePause}
									title={`${t('ui.pause')} (P)`}
								>{paused ? `▶ ${t('ui.resume')}` : `⏸ ${t('ui.pause')}`}</button>
								<button
									class="flex items-center gap-1 text-xs px-2 py-0.5 rounded border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer"
									onclick={restartGame}
									title={t('ui.restart')}
								>↺ {t('ui.restart')}</button>
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
							class="px-8 py-3 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] font-semibold text-lg hover:bg-[var(--primary-hover)] transition-colors cursor-pointer shadow-lg"
							onclick={beginTimer}
						>
							▶ Start
						</button>
						<p class="mt-3 text-xs text-[var(--text-muted)]">Press <strong>Space</strong> to start</p>
					</div>
				{/if}

				<!-- Pause overlay -->
				{#if paused}
					<div class="text-center py-8">
						<div class="text-2xl font-bold text-[var(--text-muted)] mb-4">⏸ Paused</div>
						<button
							class="px-6 py-2 rounded-[var(--radius)] bg-[var(--primary)] text-[var(--primary-text)] font-semibold hover:bg-[var(--primary-hover)] transition-colors cursor-pointer"
							onclick={togglePause}
						>
							▶ Resume
						</button>
						<p class="mt-2 text-xs text-[var(--text-muted)]">Press <strong>P</strong> or <strong>Space</strong> to resume</p>
					</div>
				{/if}

				<!-- Chord card + keyboard (dimmed when paused or not started) -->
				<div class="{paused ? 'opacity-30 pointer-events-none' : ''}">
				<ChordCard chord={currentChord} system={notationSystem} onclick={nextChord} voiceLeading={voiceLeadingInfo} showVoiceLeading={voiceLeadingEnabled} vlMode={voiceLeadingEnabled ? vlMode : 'guided'} voicingTypeHint={voiceLeadingEnabled && vlMode === 'find-inversion' ? t('settings.voicing_' + voicing.replace(/-/g, '_')) : ''}>
					<!-- Piano keyboard inside card -->
					<div class="mt-8">
						<PianoKeyboard
							chordData={currentData}
							accidentalPref={accidentals}
							showVoicing={shouldShowVoicing}
							midiEnabled={midiEnabled}
							midiActiveNotes={midiActiveNotes}
							midiExpectedPitchClasses={expectedPitchClasses}
							voiceLeading={voiceLeadingInfo}
							showVoiceLeading={voiceLeadingEnabled}
							forceOctaves={sessionOctaves}
						/>
					</div>

					<!-- VL Mode B/C feedback -->
					{#if voiceLeadingEnabled && vlMode !== 'guided' && vlValidation && midiActiveNotes.size > 0}
						<div class="mt-4 text-center">
							{#if vlValidation.grade === 'optimal'}
								<span class="text-[var(--accent-green)] font-semibold text-lg">✓ Optimal!</span>
								<div class="text-xs text-[var(--text-muted)] mt-0.5">Bewegung: {vlValidation.playerMovement} Halbtöne</div>
							{:else if vlValidation.grade === 'correct'}
								<span class="text-[var(--accent-amber)] font-semibold">Richtig, aber nicht engste Lage</span>
								<div class="text-xs text-[var(--text-muted)] mt-0.5">
									Deine Bewegung: {vlValidation.playerMovement} HT — Optimal: {vlValidation.optimalMovement} HT
								</div>
							{:else}
								<span class="text-[var(--accent-red)] text-sm">Falsche Töne</span>
							{/if}
						</div>
					<!-- Standard MIDI match feedback (guided mode / non-VL) -->
					{:else if midiEnabled && midiMatchResult && midiActiveNotes.size > 0}
						<div class="mt-4 text-center">
							{#if midiMatchResult.correct}
								<span class="text-[var(--accent-green)] font-semibold text-lg">✓ Correct!</span>
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
						<div class="mt-4 text-center">
							<!-- svelte-ignore a11y_click_events_have_key_events -->
							<button
								class="px-4 py-1.5 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer"
								onclick={(e) => { e.stopPropagation(); replayChord(); }}
							>
								🎵 Listen
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
								<div class="text-xs text-[var(--accent-gold)] mt-1">
									↓ Bass: {currentData.voicing[0]}
								</div>
							{/if}
						</div>
					{/if}
				</ChordCard>
				</div>

				<!-- Instruction -->
				<div class="text-center text-sm text-[var(--text-muted)]">
					{#if !timerStarted}
						<p>{t('ui.get_ready')}</p>
					{:else if paused}
						<!-- hidden during pause -->
					{:else if inTimeMode}
						<p>{t('ui.play_beat_1')}</p>
					{:else if midiEnabled && midiState === 'connected' && midiDevices.length > 0}
						<p>{t('ui.play_auto')}</p>
					{:else if displayMode === 'verify' && playPhase === 'playing'}
						<p>{t('ui.play_verify')}</p>
					{:else if displayMode === 'verify' && playPhase === 'verifying'}
						<p>{t('ui.check_verify')}</p>
					{:else}
						<p>{t('ui.tap_space')}</p>
					{/if}
				</div>
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
					← {t('ui.back')}
				</button>
				<div class="text-sm text-[var(--text-muted)]">
					<span class="font-semibold text-[var(--accent-amber)]">{t('ui.ear_training')}</span>
					<span class="mx-1">·</span>
					<span class="capitalize">{t('settings.difficulty_' + difficulty)}</span>
				</div>
			</div>

			<div class="max-w-3xl mx-auto space-y-6">
				<!-- MIDI status -->
				{#if midiEnabled}
					<MidiStatus
						state={midiState}
						devices={midiDevices}
						selectedDeviceId={midiSelectedDeviceId}
						activeNoteCount={midiActiveNotes.size}
						onSelectDevice={handleMidiSelectDevice}
						onConnect={handleMidiConnect}
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
							class="px-8 py-3 rounded-[var(--radius)] bg-[var(--accent-amber)] text-black font-semibold text-lg hover:brightness-110 transition-all cursor-pointer shadow-lg"
							onclick={beginEarTraining}
						>
							👂 {t('ui.ear_training_start')}
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
						<!-- Piano keyboard (hidden until revealed) -->
						{#if earTrainingRevealed}
							<div class="mt-8">
								<PianoKeyboard
									chordData={currentData}
									accidentalPref={accidentals}
									showVoicing={true}
									midiEnabled={midiEnabled}
									midiActiveNotes={midiActiveNotes}
									midiExpectedPitchClasses={expectedPitchClasses}
								/>
							</div>
						{:else}
							<div class="mt-8">
								<PianoKeyboard
									chordData={null}
									accidentalPref={accidentals}
									showVoicing={false}
									midiEnabled={midiEnabled}
									midiActiveNotes={midiActiveNotes}
									midiExpectedPitchClasses={expectedPitchClasses}
								/>
							</div>
						{/if}

						<!-- MIDI feedback -->
						{#if midiEnabled && midiMatchResult && midiActiveNotes.size > 0}
							<div class="mt-4 text-center">
								{#if midiMatchResult.correct}
									<span class="text-[var(--accent-green)] font-semibold text-lg">✓ {t('ui.correct')}</span>
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
								class="px-4 py-1.5 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--accent-amber)] hover:text-[var(--accent-amber)] transition-colors cursor-pointer"
								onclick={(e) => { e.stopPropagation(); replayChord(); }}
							>
								🎵 {t('ui.listen_again')}
							</button>
						</div>
					</ChordCard>

					<!-- Instruction -->
					<div class="text-center text-sm text-[var(--text-muted)]">
						{#if earTrainingRevealed}
							<p>{t('ui.ear_training_revealed')}</p>
						{:else if midiEnabled}
							<p>{t('ui.ear_training_listen')}</p>
						{:else}
							<p>{t('ui.ear_training_hidden')}</p>
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
			<div class="max-w-2xl mx-auto mb-4">
				<button
					class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--text)] hover:text-[var(--text)] transition-colors cursor-pointer text-sm font-medium"
					onclick={resetToSetup}
				>
					← {t('ui.back_setup')}
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
				{midiEnabled}
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
			/>
			</div>
		{/if}
	</div>
</main>

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

<style>
	.dashboard-header {
		display: flex;
		flex-direction: column;
		gap: 10px;
		padding: 14px 16px;
		background: rgba(255,255,255,0.03);
		border: 1px solid rgba(255,255,255,0.07);
		border-radius: 14px;
		margin-bottom: 20px;
	}

	.dashboard-top {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.greeting-streak {
		display: flex;
		align-items: center;
		gap: 16px;
	}

	.greeting {
		font-size: 1.05rem;
		font-weight: 700;
		color: #fff;
	}

	.streak-inline {
		display: flex;
		align-items: center;
		gap: 5px;
		font-size: 0.85rem;
		color: #fb923c;
		font-weight: 600;
	}

	.streak-label {
		color: #666;
		font-weight: 400;
	}

	.midi-pill {
		display: flex;
		align-items: center;
		gap: 6px;
		padding: 4px 12px;
		border-radius: 999px;
		font-size: 0.72rem;
		background: rgba(255,255,255,0.05);
		color: #555;
	}
	.midi-pill.connected {
		background: rgba(74,222,128,0.1);
		color: #4ade80;
	}

	/* Two-column layout */
	.train-layout {
		display: grid;
		grid-template-columns: 1fr 340px;
		gap: 20px;
		align-items: start;
	}

	.train-main {
		display: flex;
		flex-direction: column;
		gap: 20px;
		min-width: 0;
	}

	.train-sidebar {
		display: flex;
		flex-direction: column;
		gap: 16px;
	}

	@media (max-width: 768px) {
		.train-layout {
			grid-template-columns: 1fr;
		}
		.train-main { order: 1; }
		.train-sidebar { order: 2; }
	}

	/* Settings modal */
	.settings-modal {
		position: fixed;
		left: 0;
		right: 0;
		bottom: 0;
		z-index: 50;
		max-height: 88vh;
		background: var(--bg-card, #1c1a17);
		border-radius: 20px 20px 0 0;
		border-top: 1px solid var(--border);
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}
	@media (min-width: 600px) {
		.settings-modal {
			left: 50%;
			right: auto;
			width: 560px;
			transform: translateX(-50%);
		}
	}
	.settings-modal-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 16px 20px;
		border-bottom: 1px solid var(--border);
		flex-shrink: 0;
	}
	.settings-modal-body {
		overflow-y: auto;
		padding: 20px;
		padding-bottom: max(20px, env(safe-area-inset-bottom));
		flex: 1;
	}
</style>
