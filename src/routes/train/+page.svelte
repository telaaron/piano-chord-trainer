<script lang="ts">
	import { onMount } from 'svelte';
	import { fly, fade, scale } from 'svelte/transition';
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
	import { saveSession, loadSettings, saveSettings, loadStreak, recordPracticeDay, recordPlanUsed, type StreakData, type ChordTiming } from '$lib/services/progress';
	import { playChord, stopAll, startMetronome, stopMetronome, setMetronomeBpm, isMetronomeRunning, disposeAll, setSoundPreset, getSoundPreset, SOUND_PRESETS, type SoundPreset } from '$lib/services/audio';
	import {
		CHORDS_BY_DIFFICULTY,
		CHORD_NOTATIONS,
		VOICING_LABELS,
		PROGRESSION_LABELS,
		getNotePool,
		getChordNotes,
		getVoicingNotes,
		formatVoicing,
		displayToQuality,
		convertChordNotation,
		noteToSemitone,
		generateProgression,
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
	} from '$lib/engine';

	import { formatTime } from '$lib/utils/format';

	// ─── Exercise descriptions ───────────────────────────────────
	const VOICING_DESCRIPTIONS: Record<VoicingType, { example: string; tip: string }> = {
		root: { example: 'CMaj7 → C E G B', tip: 'All notes stacked from the root up. The foundation of all voicings.' },
		shell: { example: 'CMaj7 → C E B', tip: 'Root + 3rd + 7th. The essential chord tones that define the sound.' },
		'half-shell': { example: 'CMaj7 → E C B', tip: '3rd on bottom, then root + 7th. Common jazz left-hand voicing.' },
		full: { example: 'CMaj7 → C B E G', tip: 'Root + 7th + 3rd + 5th. Spread voicing for a fuller sound.' },
		'rootless-a': { example: 'CMaj7 → E G B D', tip: 'No root — let the bass player cover it. Type A: starts from the 3rd.' },
		'rootless-b': { example: 'CMaj7 → B D E G', tip: 'No root — Type B: starts from the 7th. Used with the other hand.' },
		'inversion-1': { example: 'CMaj7 → E G B C', tip: '3rd on bottom. Same notes, different bass note changes the color.' },
		'inversion-2': { example: 'CMaj7 → G B C E', tip: '5th on bottom. Creates a more open, spread sound.' },
		'inversion-3': { example: 'CMaj7 → B C E G', tip: '7th on bottom. The most tension — resolves beautifully.' },
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

	// ─── Audio / Metronome settings ──────────────────────────────
	let audioEnabled = $state(true);
	let metronomeEnabled = $state(false);
	let metronomeBpm = $state(80);
	let currentBeat = $state(0);
	let soundPreset: SoundPreset = $state(getSoundPreset());

	// ─── Game state ──────────────────────────────────────────────
	type Screen = 'setup' | 'playing' | 'finished' | 'custom-editor' | 'custom-playing' | 'custom-results';
	type PlayPhase = 'playing' | 'verifying';

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

	// (formatTime imported from $lib/utils/format)

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
				const voicingArr = getVoicingNotes(notes, voicing, pc.root, accidentals);
				newData.push({ chord: pc.display, root: pc.root, type: pc.quality, notes, voicing: voicingArr });
			}

			chords = newChords;
			chordsWithNotes = newData;
			return;
		}

		// Random mode (original logic)
		const available = CHORDS_BY_DIFFICULTY[difficulty];
		const pool = getNotePool(accidentals);
		const newChords: string[] = [];
		const newData: ChordWithNotes[] = [];
		let last = '';

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
				const voicingArr = getVoicingNotes(notes, voicing, root, accidentals);
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

		// Start metronome
		if (metronomeEnabled) {
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
		if (timerHandle) clearInterval(timerHandle);
		timerHandle = null;
		if (autoAdvanceTimeout) {
			clearTimeout(autoAdvanceTimeout);
			autoAdvanceTimeout = null;
		}
		stopMetronome();
		stopAll();
		currentBeat = 0;
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

			// Auto-advance after short delay (let player hear the chord)
			if (!autoAdvanceTimeout) {
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
		if (e.code === 'KeyP' && screen === 'playing' && timerStarted) {
			e.preventDefault();
			togglePause();
		}
		if (e.code === 'Escape' && screen === 'playing') {
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
			midiDisconnectToast = `${deviceName} disconnected — reconnect to continue`;
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
	<meta property="og:image:alt" content="Chord Trainer practice interface with piano keyboard" />
	<meta property="og:site_name" content="Chord Trainer" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="Practice Jazz Piano Voicings – Chord Trainer" />
	<meta name="twitter:description" content="Speed-drill chord voicings in all 12 keys. MIDI recognition, ii-V-I progressions, guided practice plans." />
	<meta name="twitter:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta name="robots" content="noindex" />
</svelte:head>

<main class="flex-1 py-8 sm:py-12 px-4" style="background: linear-gradient(180deg, var(--bg) 0%, #110e0a 30%, #12100c 70%, var(--bg) 100%);">
	<div class="max-w-4xl mx-auto">
		<!-- Header -->
		<div class="text-center mb-10">
			<h1 class="text-4xl sm:text-5xl font-bold tracking-tight text-gradient pb-1">
				Chord Trainer
			</h1>
			<p class="mt-3 text-[var(--text-muted)]">
				Build speed and fluency across all 12 keys
			</p>
		</div>

		<!-- ─────── Setup Screen ─────── -->
		{#if screen === 'setup'}
			<div class="space-y-6" in:fade={{ duration: 200, delay: 100 }}>
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
					{streak}
					{midiState}
					{midiDevices}
					onstart={startGame}
					onstartplan={startPlan}
					oncustomprogression={openCustomEditor}
				/>
				<ProgressDashboard />
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
					title="Back to setup (ESC)"
				>
					← Back
				</button>
				<div class="flex items-center gap-3">
					<div class="text-sm text-[var(--text-muted)] text-right">
						<span class="font-semibold text-[var(--text)]">{VOICING_LABELS[voicing]}</span>
						<span class="mx-1">·</span>
						<span class="capitalize">{difficulty}</span>
						<span class="mx-1">·</span>
						<span>{PROGRESSION_LABELS[progressionMode]}</span>
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
							<h3 class="font-semibold text-[var(--primary)]">{VOICING_LABELS[voicing]}</h3>
							<p class="text-sm text-[var(--text-muted)]">{VOICING_DESCRIPTIONS[voicing].tip}</p>
							<p class="text-xs font-mono text-[var(--text-dim)]">Example: {VOICING_DESCRIPTIONS[voicing].example}</p>
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
					</div>
				{/if}

				<!-- Audio / Metronome / Sound controls -->
				<div class="flex items-center gap-3 text-sm flex-wrap">
					<button
						class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-sm)] border transition-colors cursor-pointer {audioEnabled ? 'border-[var(--primary)] bg-[var(--primary-muted)] text-[var(--primary)]' : 'border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)]'}"
						onclick={() => (audioEnabled = !audioEnabled)}
						title={audioEnabled ? 'Mute audio' : 'Enable audio'}
					>
						{audioEnabled ? '🔊' : '🔇'} Audio
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
						{metronomeEnabled ? '⏸' : '▶'} Metronome
					</button>
					{#if metronomeEnabled}
						<div class="flex items-center gap-2">
							<button
								class="w-7 h-7 rounded border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)] cursor-pointer flex items-center justify-center"
								onclick={() => updateBpm(metronomeBpm - 5)}
							>−</button>
							<span class="font-mono text-xs w-12 text-center">{metronomeBpm} BPM</span>
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
					{/if}
				</div>

				<!-- Progress bar + timer -->
				<div>
					<div class="flex justify-between text-sm mb-2 text-[var(--text-muted)]">
						<span>Chord {currentIdx + 1} / {actualTotalChords}</span>
						<div class="flex items-center gap-3">
							<span class="font-mono">{timerStarted ? formatTime(elapsedMs > 0 ? elapsedMs : 0) : '0:00.00'}</span>
							{#if timerStarted}
								<button
									class="text-xs px-2 py-0.5 rounded border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--text)] hover:text-[var(--text)] transition-colors cursor-pointer"
									onclick={togglePause}
									title="Pause (P)"
								>{paused ? '▶ Resume' : '⏸ Pause'}</button>
								<button
									class="text-xs px-2 py-0.5 rounded border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer"
									onclick={restartGame}
									title="Restart exercise"
								>↺ Restart</button>
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
				<ChordCard chord={currentChord} system={notationSystem} onclick={nextChord}>
					<!-- Piano keyboard inside card -->
					<div class="mt-8">
						<PianoKeyboard
							chordData={currentData}
							accidentalPref={accidentals}
							showVoicing={shouldShowVoicing}
							midiEnabled={midiEnabled}
							midiActiveNotes={midiActiveNotes}
							midiExpectedPitchClasses={expectedPitchClasses}
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
							<div class="text-sm text-[var(--text-muted)]">{VOICING_LABELS[voicing]}</div>
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
						<p>Get ready — press <strong class="text-[var(--text)]">Start</strong> when you're ready</p>
					{:else if paused}
						<!-- hidden during pause -->
					{:else if midiEnabled && midiState === 'connected' && midiDevices.length > 0}
						<p>Play the chord on your piano — <strong class="text-[var(--text)]">auto-advance</strong> on correct voicing</p>
					{:else if displayMode === 'verify' && playPhase === 'playing'}
						<p>Play the chord, then press <strong class="text-[var(--text)]">Space</strong> to verify</p>
					{:else if displayMode === 'verify' && playPhase === 'verifying'}
						<p>Check your voicing — then <strong class="text-[var(--text)]">Space</strong> for next chord</p>
					{:else}
						<p>Tap the card or press <strong class="text-[var(--text)]">Space</strong></p>
					{/if}
				</div>
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
					← Back to Setup
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
