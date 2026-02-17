<script lang="ts">
	import { onMount } from 'svelte';
	import { fly, fade, scale } from 'svelte/transition';
	import GameSettings from '$lib/components/GameSettings.svelte';
	import ChordCard from '$lib/components/ChordCard.svelte';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import Results from '$lib/components/Results.svelte';
	import MidiStatus from '$lib/components/MidiStatus.svelte';
	import ProgressDashboard from '$lib/components/ProgressDashboard.svelte';
	import ProgressionEditor from '$lib/components/ProgressionEditor.svelte';
	import ProgressionPlayer from '$lib/components/ProgressionPlayer.svelte';
	import ProgressionResults from '$lib/components/ProgressionResults.svelte';
	import { MidiService } from '$lib/services/midi';
	import type { MidiConnectionState, MidiDevice, ChordMatchResult } from '$lib/services/midi';
	import { saveSession, loadSettings, saveSettings, loadStreak, recordPracticeDay, recordPlanUsed, type StreakData, type ChordTiming } from '$lib/services/progress';
	import { playChord, stopAll, startMetronome, stopMetronome, setMetronomeBpm, isMetronomeRunning, disposeAll } from '$lib/services/audio';
	import {
		CHORDS_BY_DIFFICULTY,
		CHORD_NOTATIONS,
		VOICING_LABELS,
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

	// ─── Game state ──────────────────────────────────────────────
	type Screen = 'setup' | 'playing' | 'finished' | 'custom-editor' | 'custom-playing' | 'custom-results';
	type PlayPhase = 'playing' | 'verifying';

	let screen: Screen = $state<Screen>('setup');
	let playPhase: PlayPhase = $state<PlayPhase>('playing');
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
	const elapsedMs = $derived(screen === 'playing' ? now - startTime : endTime - startTime);

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
		startTime = Date.now();
		now = startTime;
		chordTimings = [];
		chordStartTime = startTime;
		midiCorrectCount = 0;
		midiTotalAttempts = 0;
		midiMatchResult = null;
		midi.releaseAll();

		// Re-register MIDI handler (ProgressionPlayer may have overwritten it)
		midi.onNotes(handleMidiNotes);
		if (timerHandle) clearInterval(timerHandle);
		timerHandle = setInterval(() => {
			if (screen === 'playing') now = Date.now();
		}, 100);

		// Init MIDI if enabled
		if (midiEnabled && midiState === 'disconnected') {
			midi.init();
		}

		// Play first chord audio (fire-and-forget)
		if (audioEnabled && chordsWithNotes[0]) {
			playChord(chordsWithNotes[0].voicing).catch(() => {});
		}

		// Start metronome
		if (metronomeEnabled) {
			startMetronome(metronomeBpm, 4, (beat) => {
				currentBeat = beat;
			});
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
		if (screen !== 'playing') return;

		// Clear auto-advance timeout
		if (autoAdvanceTimeout) {
			clearTimeout(autoAdvanceTimeout);
			autoAdvanceTimeout = null;
		}

		// Verify mode: first press shows voicing, second press advances
		// Skip verify phase when MIDI is doing the verification
		if (displayMode === 'verify' && playPhase === 'playing' && !midiEnabled) {
			playPhase = 'verifying';
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

		// Check chord match
		const result = midi.checkChordLenient(currentData.voicing);
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

	// ─── Keyboard shortcut ───────────────────────────────────────
	function handleKeydown(e: KeyboardEvent) {
		if (e.code === 'Space' && screen === 'playing') {
			e.preventDefault();
			nextChord();
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
	<title>Practice – Chord Trainer</title>
	<meta name="description" content="Practice jazz piano voicings with speed drills. MIDI recognition, ii-V-I progressions, progress tracking. Choose a plan and start training." />
	<link rel="canonical" href="https://jazzchords.app/train" />
	<meta property="og:title" content="Practice – Chord Trainer" />
	<meta property="og:description" content="Practice jazz piano voicings with speed drills. MIDI recognition, ii-V-I progressions, progress tracking." />
	<meta property="og:url" content="https://jazzchords.com/train" />
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
			<div class="max-w-3xl mx-auto space-y-6" in:fly={{ y: 20, duration: 300, delay: 50 }}>
				<!-- Cancel button -->
				<div class="flex justify-end">
					<button
						class="px-3 py-1.5 rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--accent-red)] hover:text-[var(--accent-red)] transition-colors cursor-pointer text-sm font-medium"
						onclick={resetToSetup}
						title="Cancel session and return to menu"
					>
						✕ Cancel
					</button>
				</div>

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

				<!-- Audio / Metronome controls -->
				<div class="flex items-center gap-4 text-sm">
					<button
						class="flex items-center gap-1.5 px-3 py-1.5 rounded-[var(--radius-sm)] border transition-colors cursor-pointer {audioEnabled ? 'border-[var(--primary)] bg-[var(--primary-muted)] text-[var(--primary)]' : 'border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--border-hover)]'}"
						onclick={() => (audioEnabled = !audioEnabled)}
						title={audioEnabled ? 'Mute audio' : 'Enable audio'}
					>
						{audioEnabled ? '🔊' : '🔇'} Audio
					</button>
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
						<!-- Beat indicator -->
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

				<!-- Progress bar -->
				<div>
					<div class="flex justify-between text-sm mb-2 text-[var(--text-muted)]">
						<span>Chord {currentIdx + 1} / {actualTotalChords}</span>
						<span class="font-mono">{formatTime(elapsedMs > 0 ? elapsedMs : 0)}</span>
					</div>
					<div class="h-1.5 bg-[var(--bg-muted)] rounded-full overflow-hidden">
						<div
							class="h-full bg-[var(--primary)] transition-all duration-300 rounded-full"
							style="width: {progress}%"
						></div>
					</div>
				</div>

				<!-- Chord card + keyboard -->
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
							<button
								class="px-4 py-1.5 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors cursor-pointer"
								onclick={replayChord}
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
						</div>
					{/if}
				</ChordCard>

				<!-- Instruction -->
				<div class="text-center text-sm text-[var(--text-muted)]">
					{#if midiEnabled && midiState === 'connected' && midiDevices.length > 0}
						<p>Play the chord on your piano — <strong class="text-[var(--text)]">auto-advance</strong> on correct voicing</p>
					{:else if displayMode === 'verify' && playPhase === 'playing'}
						<p>Play the chord, then press <strong class="text-[var(--text)]">Space</strong> to verify</p>
					{:else if displayMode === 'verify' && playPhase === 'verifying'}
						<p>Check your voicing — then <strong class="text-[var(--text)]">Space</strong> for next chord</p>
					{:else}
						<p>Tap the card or press <strong class="text-[var(--text)]">Space</strong></p>
					{/if}
					<p class="mt-2 text-xs text-[var(--text-muted)]/70">Press <strong>ESC</strong> to cancel</p>
				</div>
			</div>
		{/if}

		<!-- ─────── Results Screen ─────── -->
		{#if screen === 'finished'}
			<div in:scale={{ start: 0.95, duration: 300, delay: 50 }} style="transform-origin: center top">
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
