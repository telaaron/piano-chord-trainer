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
	import { MidiService } from '$lib/services/midi';
	import type { MidiConnectionState, MidiDevice, ChordMatchResult } from '$lib/services/midi';
	import { saveSession, loadSettings, saveSettings, loadStreak, recordPracticeDay, recordPlanUsed, loadHistory, computeStats, type ProgressStats, type StreakData, type ChordTiming } from '$lib/services/progress';
	import { playChord, stopAll, startMetronome, stopMetronome, setMetronomeBpm, isMetronomeRunning, disposeAll, setSoundPreset, getSoundPreset, SOUND_PRESETS, type SoundPreset } from '$lib/services/audio';
	import {
		CHORDS_BY_DIFFICULTY,
		CHORD_NOTATIONS,
		VOICING_LABELS,
		PROGRESSION_LABELS,
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
		getWeightedChordPool,
		pickWeightedChord,
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
	} from '$lib/engine';

	import { formatTime } from '$lib/utils/format';

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

	let screen: Screen = $state<Screen>('setup');
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
		displayMode === 'always' || (displayMode === 'verify' && playPhase === 'verifying'),
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
		saveSession({
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

		// Use inversion-aware check when voicing is an inversion
		let result: ChordMatchResult;
		if (voicing.startsWith('inversion-') && currentData.voicing.length > 0) {
			// First note in voicing array is the bass note for this inversion
			result = midi.checkChordWithBass(currentData.voicing, currentData.voicing[0]);
		} else {
			result = midi.checkChordLenient(currentData.voicing);
		}
		midiMatchResult = result;

		if (result.correct && activeNotes.size > 0) {
			midiTotalAttempts++;
			midiCorrectCount++;

			// In-Time mode: record when the chord was played (timing relative to beat 1)
			if (inTimeMode && inTimeChordPlayedAt === null) {
				const timeSinceBeatOne = Date.now() - inTimeBeatOneTime;
				inTimeChordPlayedAt = timeSinceBeatOne;
			}

			// Auto-advance after short delay (let player hear the chord)
			// In In-Time mode, don't auto-advance on correct — wait for beat
			if (!inTimeMode && !autoAdvanceTimeout) {
				autoAdvanceTimeout = setTimeout(() => {
					autoAdvanceTimeout = null;
					nextChord();
				}, 400);
			}
		} else if (activeNotes.size > 0 && result.accuracy < 1) {
			// Wrong attempt tracked when player has enough notes held
			const expectedCount = currentData.voicing.length;
			if (activeNotes.size >= expectedCount) {
				midiTotalAttempts++;
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
					<div class="weekly-goal-row">
						<span class="goal-label">Weekly Goal</span>
						<div class="goal-bar">
							<div class="goal-fill" style="width: {weeklyGoalPct}%"></div>
						</div>
						<span class="goal-pct">{weeklyGoalPct}%</span>
					</div>
				</div>

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

						<!-- Custom Settings -->
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
									onclick={startGame}
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
									<p class="text-xs text-[var(--text-dim)] mb-3">Determines which notes of a chord you play.</p>
									<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">Basics</div>
									<div class="grid grid-cols-2 gap-3">
										{#each [
											{ val: 'root' as VoicingType, label: 'Root Position', sub: 'Root + all notes from bottom.' },
											{ val: 'shell' as VoicingType, label: 'Shell Voicing', sub: 'Root + 3rd + 7th only.' },
											{ val: 'half-shell' as VoicingType, label: 'Half Shell', sub: '3rd/7th around the root.' },
											{ val: 'full' as VoicingType, label: 'Full Voicing', sub: 'All notes in jazz order: 1-7-3-5.' },
										] as opt}
											<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voicing, opt.val)}" onclick={() => (voicing = opt.val)}>
												<div class="font-semibold text-sm">{opt.label}</div>
												<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
											</button>
										{/each}
									</div>
									<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">🎹 Left-Hand Voicings</div>
									<div class="grid grid-cols-2 gap-3">
										{#each [
											{ val: 'rootless-a' as VoicingType, label: 'Rootless A', sub: '3–5–7–9 · Bill Evans style.' },
											{ val: 'rootless-b' as VoicingType, label: 'Rootless B', sub: '7–9–3–5 · Complement to Type A.' },
										] as opt}
											<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voicing, opt.val)}" onclick={() => (voicing = opt.val)}>
												<div class="font-semibold text-sm">{opt.label}</div>
												<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
											</button>
										{/each}
									</div>
									<div class="text-xs font-medium text-[var(--text-muted)] mb-2 mt-4">🔄 Inversions</div>
									<div class="grid grid-cols-3 gap-3">
										{#each [
											{ val: 'inversion-1' as VoicingType, label: '1st Inversion', sub: '3rd on bottom.' },
											{ val: 'inversion-2' as VoicingType, label: '2nd Inversion', sub: '5th on bottom.' },
											{ val: 'inversion-3' as VoicingType, label: '3rd Inversion', sub: '7th on bottom.' },
										] as opt}
											<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voicing, opt.val)}" onclick={() => (voicing = opt.val)}>
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
								<!-- Chord count -->
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
								<!-- Advanced Modes -->
								<fieldset>
									<legend class="text-sm font-medium mb-1">In-Time Mode</legend>
									<p class="text-xs text-[var(--text-dim)] mb-3">Chord changes happen on the beat. Trains timing instead of speed.</p>
									<div class="grid grid-cols-2 gap-3">
										{#each [
											{ val: false, label: 'Off', sub: 'Speed drill' },
											{ val: true, label: 'On', sub: 'Play on the beat' },
										] as opt}
											<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(inTimeMode, opt.val)}" onclick={() => (inTimeMode = opt.val)}>
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
													<button class="p-2 rounded-[var(--radius)] border-2 transition-all text-center {sel(inTimeBars, bars)}" onclick={() => (inTimeBars = bars)}>
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
									<p class="text-xs text-[var(--text-dim)] mb-3">Weak chords appear more often. Spaced repetition for your drills.</p>
									<div class="grid grid-cols-2 gap-3">
										{#each [
											{ val: false, label: 'Off', sub: 'Equal weighting' },
											{ val: true, label: 'On', sub: 'Adapt to you' },
										] as opt}
											<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(adaptiveEnabled, opt.val)}" onclick={() => (adaptiveEnabled = opt.val)}>
												<div class="font-semibold text-sm">{opt.label}</div>
												<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
											</button>
										{/each}
									</div>
								</fieldset>
								<fieldset>
									<legend class="text-sm font-medium mb-1">Voice Leading</legend>
									<p class="text-xs text-[var(--text-dim)] mb-3">Highlight common tones and note movements between chords.</p>
									<div class="grid grid-cols-2 gap-3">
										{#each [
											{ val: false, label: 'Off', sub: 'Standard display' },
											{ val: true, label: 'On', sub: 'Show connections' },
										] as opt}
											<button class="p-3 rounded-[var(--radius)] border-2 transition-all text-left {sel(voiceLeadingEnabled, opt.val)}" onclick={() => (voiceLeadingEnabled = opt.val)}>
												<div class="font-semibold text-sm">{opt.label}</div>
												<div class="text-xs text-[var(--text-dim)] mt-1">{opt.sub}</div>
											</button>
										{/each}
									</div>
								</fieldset>
								<!-- Ear Training -->
								<button
									class="w-full p-4 rounded-[var(--radius)] border-2 border-[var(--border)] hover:border-[var(--accent-amber)] transition-all text-left group"
									onclick={startEarTraining}
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
						<span class="font-semibold text-[var(--text)]">{t('settings.voicing_' + voicing.replace(/-/g, '_'))}</span>
						<span class="mx-1">·</span>
						<span class="capitalize">{t('settings.difficulty_' + difficulty)}</span>
						<span class="mx-1">·</span>
						<span>{t('settings.progression_' + (progressionMode === 'cycle-of-4ths' ? 'cycle' : progressionMode === '1-6-2-5' ? 'turnaround' : progressionMode))}</span>
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
				<ChordCard chord={currentChord} system={notationSystem} onclick={nextChord} voiceLeading={voiceLeadingInfo} showVoiceLeading={voiceLeadingEnabled}>
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
						/>
					</div>

					<!-- MIDI match feedback -->
					{#if midiEnabled && midiMatchResult && midiActiveNotes.size > 0}
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

	.weekly-goal-row {
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.goal-label {
		font-size: 0.72rem;
		color: #666;
		white-space: nowrap;
	}

	.goal-bar {
		flex: 1;
		height: 4px;
		background: #1a1a1a;
		border-radius: 999px;
		overflow: hidden;
	}

	.goal-fill {
		height: 100%;
		background: #fb923c;
		border-radius: 999px;
		transition: width 0.8s ease-out;
	}

	.goal-pct {
		font-size: 0.72rem;
		color: #fb923c;
		font-weight: 600;
		white-space: nowrap;
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
		position: sticky;
		top: 20px;
		max-height: calc(100vh - 80px);
		overflow-y: auto;
		scrollbar-width: none;
	}

	.train-sidebar::-webkit-scrollbar {
		display: none;
	}

	@media (max-width: 768px) {
		.train-layout {
			grid-template-columns: 1fr;
		}
		.train-sidebar {
			position: static;
			max-height: none;
		}
		.train-main { order: 1; }
		.train-sidebar { order: 2; }
	}
</style>
