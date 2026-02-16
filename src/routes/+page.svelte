<script lang="ts">
	import { onMount } from 'svelte';
	import GameSettings from '$lib/components/GameSettings.svelte';
	import ChordCard from '$lib/components/ChordCard.svelte';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import Results from '$lib/components/Results.svelte';
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
		type Difficulty,
		type NotationStyle,
		type VoicingType,
		type DisplayMode,
		type AccidentalPreference,
		type NotationSystem,
		type ChordWithNotes,
	} from '$lib/engine';

	// ─── Settings (persisted later) ──────────────────────────────
	let difficulty: Difficulty = $state('beginner');
	let notation: NotationStyle = $state('standard');
	let voicing: VoicingType = $state('root');
	let displayMode: DisplayMode = $state('always');
	let accidentals: AccidentalPreference = $state('both');
	let notationSystem: NotationSystem = $state('international');
	let totalChords = $state(20);

	// ─── Game state ──────────────────────────────────────────────
	type Screen = 'setup' | 'playing' | 'finished';
	type PlayPhase = 'playing' | 'verifying';

	let screen: Screen = $state('setup');
	let playPhase: PlayPhase = $state('playing');
	let currentIdx = $state(0);
	let chords: string[] = $state([]);
	let chordsWithNotes: ChordWithNotes[] = $state([]);
	let startTime = $state(0);
	let endTime = $state(0);
	let now = $state(0);
	let timerHandle: ReturnType<typeof setInterval> | null = $state(null);

	// ─── Derived ─────────────────────────────────────────────────
	const currentChord = $derived(chords[currentIdx] ?? '');
	const currentData = $derived(chordsWithNotes[currentIdx] ?? null);
	const shouldShowVoicing = $derived(
		displayMode === 'always' || (displayMode === 'verify' && playPhase === 'verifying'),
	);
	const progress = $derived(((currentIdx + 1) / totalChords) * 100);
	const elapsedMs = $derived(screen === 'playing' ? now - startTime : endTime - startTime);

	function formatTime(ms: number): string {
		const s = Math.floor(ms / 1000);
		const m = Math.floor(s / 60);
		const sec = s % 60;
		const cs = Math.floor((ms % 1000) / 10);
		return `${m}:${sec.toString().padStart(2, '0')}.${cs.toString().padStart(2, '0')}`;
	}

	// ─── Game logic ──────────────────────────────────────────────
	function generateChords() {
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
				const voicingArr = getVoicingNotes(notes, voicing);
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
		if (timerHandle) clearInterval(timerHandle);
		timerHandle = setInterval(() => {
			if (screen === 'playing') now = Date.now();
		}, 100);
	}

	function nextChord() {
		if (screen !== 'playing') return;

		// Verify mode: first press shows voicing, second press advances
		if (displayMode === 'verify' && playPhase === 'playing') {
			playPhase = 'verifying';
			return;
		}

		playPhase = 'playing';
		if (currentIdx < totalChords - 1) {
			currentIdx++;
		} else {
			endGame();
		}
	}

	function endGame() {
		endTime = Date.now();
		screen = 'finished';
		if (timerHandle) clearInterval(timerHandle);
		timerHandle = null;
	}

	function restartGame() {
		startGame();
	}

	function resetToSetup() {
		screen = 'setup';
		currentIdx = 0;
		chords = [];
		chordsWithNotes = [];
		if (timerHandle) clearInterval(timerHandle);
		timerHandle = null;
	}

	// ─── Keyboard shortcut ───────────────────────────────────────
	function handleKeydown(e: KeyboardEvent) {
		if (e.code === 'Space' && screen === 'playing') {
			e.preventDefault();
			nextChord();
		}
	}

	onMount(() => {
		window.addEventListener('keydown', handleKeydown);
		return () => {
			window.removeEventListener('keydown', handleKeydown);
			if (timerHandle) clearInterval(timerHandle);
		};
	});
</script>

<svelte:head>
	<title>Chord Trainer – Jazz Piano Voicing Practice</title>
</svelte:head>

<main class="flex-1 py-8 sm:py-12 px-4">
	<div class="max-w-4xl mx-auto">
		<!-- Header -->
		<div class="text-center mb-10">
			<h1 class="text-4xl sm:text-5xl font-bold tracking-tight text-gradient pb-1">
				Chord Trainer
			</h1>
			<p class="mt-3 text-[var(--text-muted)]">
				Verbessere deine Akkord-Umstellungen und Geschwindigkeit
			</p>
		</div>

		<!-- ─────── Setup Screen ─────── -->
		{#if screen === 'setup'}
			<GameSettings
				bind:difficulty
				bind:notation
				bind:voicing={voicing}
				bind:displayMode
				bind:accidentals
				bind:notationSystem
				bind:totalChords
				onstart={startGame}
			/>
		{/if}

		<!-- ─────── Playing Screen ─────── -->
		{#if screen === 'playing'}
			<div class="max-w-3xl mx-auto space-y-6">
				<!-- Progress bar -->
				<div>
					<div class="flex justify-between text-sm mb-2 text-[var(--text-muted)]">
						<span>Akkord {currentIdx + 1} / {totalChords}</span>
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
						/>
					</div>

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
					{#if displayMode === 'verify' && playPhase === 'playing'}
						<p>Spiele den Akkord, dann <strong class="text-[var(--text)]">Leertaste</strong> zur Überprüfung</p>
					{:else if displayMode === 'verify' && playPhase === 'verifying'}
						<p>Überprüfe – dann <strong class="text-[var(--text)]">Leertaste</strong> für den nächsten Akkord</p>
					{:else}
						<p>Tippe auf die Karte oder drücke <strong class="text-[var(--text)]">Leertaste</strong></p>
					{/if}
				</div>
			</div>
		{/if}

		<!-- ─────── Results Screen ─────── -->
		{#if screen === 'finished'}
			<Results
				{chordsWithNotes}
				{totalChords}
				elapsedMs={elapsedMs > 0 ? elapsedMs : 0}
				{difficulty}
				{notation}
				{voicing}
				{displayMode}
				{accidentals}
				{notationSystem}
				onrestart={restartGame}
				onreset={resetToSetup}
			/>
		{/if}
	</div>
</main>
