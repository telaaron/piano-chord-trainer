<script lang="ts">
	import { onMount } from 'svelte';
	import { fade, fly } from 'svelte/transition';
	import { t } from '$lib/i18n';
	import PianoKeyboard from './PianoKeyboard.svelte';
	import {
		getChordNotes,
		getVoicingNotes,
		formatVoicing,
		noteToSemitone,
		VOICING_LABELS,
		evaluateSession,
		type CustomChord,
		type ChordWithNotes,
		type VoicingType,
		type AccidentalPreference,
		type NotationSystem,
		type LoopEvaluation,
		type ChordEval,
		type SessionEvaluation,
	} from '$lib/engine';
	import { startMetronome, stopMetronome, playChord, stopAll, setMetronomeBpm } from '$lib/services/audio';
	import type { MidiConnectionState, MidiDevice, ChordMatchResult } from '$lib/services/midi';
	import { MidiService } from '$lib/services/midi';

	interface Props {
		chords: CustomChord[];
		bpm: number;
		loops: number; // 0 = infinite
		name: string;
		voicing: VoicingType;
		accidentals: AccidentalPreference;
		notationSystem: NotationSystem;
		audioEnabled: boolean;
		midiEnabled: boolean;
		midi: MidiService;
		midiState: MidiConnectionState;
		midiDevices: MidiDevice[];
		onstop: (evaluation: SessionEvaluation | null) => void;
	}

	let {
		chords,
		bpm,
		loops,
		name,
		voicing,
		accidentals,
		notationSystem,
		audioEnabled,
		midiEnabled,
		midi,
		midiState,
		midiDevices,
		onstop,
	}: Props = $props();

	// ── Derived chord data ──
	const chordsWithNotes: ChordWithNotes[] = $derived(
		chords.map((c) => {
			const notes = getChordNotes(c.root, c.quality, accidentals);
			const voicingArr = getVoicingNotes(notes, voicing, c.root, accidentals);
			return { chord: c.display, root: c.root, type: c.quality, notes, voicing: voicingArr };
		}),
	);

	// ── Play state ──
	let currentChordIdx = $state(0);
	let currentLoop = $state(0);
	let currentBeat = $state(0); // 1-based, beat within current chord
	let globalBeat = $state(0); // total beats counted
	let isPlaying = $state(false);
	let isPaused = $state(false);
	let startTime = $state(0);
	let midiActiveNotes: Set<number> = $state(new Set());
	let midiMatchResult: ChordMatchResult | null = $state(null);

	// ── Evaluation tracking ──
	let loopEvals: LoopEvaluation[] = $state([]);
	let currentLoopChordEvals: ChordEval[] = $state([]);
	let chordHit = $state(false);
	let chordBestAccuracy = $state(0);
	let chordFirstHitTime = $state(0);
	let chordWindowStart = $state(0);
	let countInBeats = $state(0); // 4-beat count-in

	// ── Computed ──
	const totalBeatsPerPass = $derived(chords.reduce((s, c) => s + c.beats, 0));
	const currentChord = $derived(chords[currentChordIdx]);
	const currentData = $derived(chordsWithNotes[currentChordIdx] ?? null);

	const expectedPitchClasses = $derived.by(() => {
		if (!currentData) return new Set<number>();
		const set = new Set<number>();
		for (const note of currentData.voicing) {
			const st = noteToSemitone(note);
			if (st !== -1) set.add(st);
		}
		return set;
	});

	/** How far through the current chord we are (0–1) */
	const chordProgress = $derived(
		currentChord ? currentBeat / currentChord.beats : 0,
	);

	// ── Beat handler (called by metronome) ──
	function onBeat(beat: number) {
		// During count-in
		if (countInBeats < 4) {
			countInBeats++;
			currentBeat = countInBeats;
			if (countInBeats === 4) {
				// Count-in done, start real playback
				startTime = Date.now();
				currentBeat = 0;
				globalBeat = 0;
				currentChordIdx = 0;
				currentLoop = 0;
				chordWindowStart = Date.now();
				resetChordTracking();
				// Play first chord
				if (audioEnabled && chordsWithNotes[0]) {
					playChord(chordsWithNotes[0].voicing).catch(() => {});
				}
			}
			return;
		}

		globalBeat++;
		currentBeat++;

		// Check if we've exhausted beats for the current chord
		if (currentChord && currentBeat > currentChord.beats) {
			// Record eval for the chord we're leaving
			recordChordEval();
			currentBeat = 1;

			if (currentChordIdx < chords.length - 1) {
				// Next chord in progression
				currentChordIdx++;
			} else {
				// End of one pass — record loop eval
				const loopAcc = currentLoopChordEvals.length > 0
					? currentLoopChordEvals.filter((e) => e.hit).length / currentLoopChordEvals.length
					: 0;
				loopEvals.push({ chords: [...currentLoopChordEvals], accuracy: loopAcc });
				currentLoopChordEvals = [];
				currentLoop++;

				// Check if we've done all loops
				if (loops > 0 && currentLoop >= loops) {
					finishSession();
					return;
				}

				// Start next pass
				currentChordIdx = 0;
			}

			resetChordTracking();

			// Play the new chord
			if (audioEnabled && chordsWithNotes[currentChordIdx]) {
				playChord(chordsWithNotes[currentChordIdx].voicing).catch(() => {});
			}
		}
	}

	function resetChordTracking() {
		chordHit = false;
		chordBestAccuracy = 0;
		chordFirstHitTime = 0;
		chordWindowStart = Date.now();
		midiMatchResult = null;
	}

	function recordChordEval() {
		currentLoopChordEvals.push({
			chord: currentChord,
			hit: chordHit,
			timingOffsetMs: chordHit ? chordFirstHitTime - chordWindowStart : 0,
			bestAccuracy: chordBestAccuracy,
		});
	}

	// ── MIDI handling ──
	function handleMidiNotes(activeNotes: Set<number>) {
		midiActiveNotes = new Set(activeNotes);

		if (!isPlaying || isPaused || !currentData || !midiEnabled) return;
		if (countInBeats < 4) return; // Still counting in

		const result = midi.checkChordLenient(currentData.voicing);
		midiMatchResult = result;

		if (result.accuracy > chordBestAccuracy) {
			chordBestAccuracy = result.accuracy;
		}

		if (result.correct && !chordHit) {
			chordHit = true;
			chordFirstHitTime = Date.now();
		}
	}

	// ── Start / Stop / Pause ──
	function start() {
		isPlaying = true;
		isPaused = false;
		countInBeats = 0;
		currentBeat = 0;
		currentChordIdx = 0;
		currentLoop = 0;
		globalBeat = 0;
		loopEvals = [];
		currentLoopChordEvals = [];
		resetChordTracking();
		midi.onNotes(handleMidiNotes);

		// Start with count-in (4 beats)
		startMetronome(bpm, 4, onBeat);
	}

	function finishSession() {
		isPlaying = false;
		stopMetronome();
		stopAll();
		const totalMs = Date.now() - startTime;
		const evaluation = evaluateSession(loopEvals, totalMs);
		onstop(evaluation);
	}

	function handleStop() {
		isPlaying = false;
		stopMetronome();
		stopAll();
		// Partial eval
		if (currentLoopChordEvals.length > 0 || loopEvals.length > 0) {
			// Record current chord if mid-chord
			if (chordHit || chordBestAccuracy > 0) {
				recordChordEval();
			}
			if (currentLoopChordEvals.length > 0) {
				const loopAcc = currentLoopChordEvals.filter((e) => e.hit).length / currentLoopChordEvals.length;
				loopEvals.push({ chords: [...currentLoopChordEvals], accuracy: loopAcc });
			}
			const totalMs = Date.now() - startTime;
			onstop(evaluateSession(loopEvals, totalMs));
		} else {
			onstop(null);
		}
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.code === 'Escape') {
			e.preventDefault();
			handleStop();
		}
	}

	onMount(() => {
		window.addEventListener('keydown', handleKeydown);
		start();
		return () => {
			window.removeEventListener('keydown', handleKeydown);
			stopMetronome();
			stopAll();
		};
	});
</script>

<div class="max-w-3xl mx-auto space-y-6" in:fly={{ y: 20, duration: 300 }}>
	<!-- Header -->
	<div class="flex items-center justify-between">
		<div>
			<h2 class="text-xl font-bold">{name}</h2>
			<p class="text-sm text-[var(--text-muted)]">
				{bpm} BPM
				{#if loops > 0}· {t('ui.loop_counter', { current: currentLoop + 1, total: loops })}{:else}· {t('ui.loop_counter', { current: currentLoop + 1, total: '∞' })}{/if}
			</p>
		</div>
		<button
			class="px-3 py-1.5 rounded-[var(--radius-sm)] border border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--accent-red)] hover:text-[var(--accent-red)] transition-colors cursor-pointer text-sm font-medium"
			onclick={handleStop}
		>
			✕ {t('ui.stop')}
		</button>
	</div>

	<!-- Count-In Overlay -->
	{#if countInBeats < 4}
		<div class="text-center py-12" in:fade={{ duration: 100 }}>
			<div class="text-8xl font-bold text-[var(--primary)] tabular-nums">
				{countInBeats === 0 ? '–' : countInBeats}
			</div>
			<p class="text-[var(--text-muted)] mt-4">{t('ui.count_in')}</p>
		</div>
	{:else}
		<!-- Progression bar (visual overview of chord positions) -->
		<div class="bg-[var(--bg-muted)] rounded-[var(--radius)] p-3">
			<div class="flex gap-1 overflow-x-auto">
				{#each chords as chord, i}
					<div
						class="flex-shrink-0 px-2 py-1 rounded-[var(--radius-sm)] text-sm font-mono transition-all duration-200 {i === currentChordIdx
							? 'bg-[var(--primary)] text-[var(--primary-text)] font-bold scale-105'
							: i < currentChordIdx
								? 'bg-[var(--bg)] text-[var(--text-dim)] opacity-60'
								: 'bg-[var(--bg)] text-[var(--text-muted)]'}"
						style="min-width: {Math.max(chord.beats * 12, 40)}px"
					>
						{chord.display}
					</div>
				{/each}
			</div>
		</div>

		<!-- Current Chord (big) -->
		<div class="card p-8 text-center relative overflow-hidden">
			<!-- Beat progress bar through chord -->
			<div
				class="absolute bottom-0 left-0 h-1 bg-[var(--primary)] transition-all"
				style="width: {chordProgress * 100}%"
			></div>

			<div class="text-5xl sm:text-6xl font-bold tracking-tight mb-4">
				{currentData?.chord ?? '—'}
			</div>

			<!-- Voicing info -->
			{#if currentData}
				<div class="text-sm text-[var(--text-muted)] mb-2">{VOICING_LABELS[voicing]}</div>
				<div class="text-lg font-mono">
					{formatVoicing(currentData, voicing, notationSystem)}
				</div>
			{/if}

			<!-- Piano keyboard -->
			<div class="mt-6">
				<PianoKeyboard
					chordData={currentData}
					accidentalPref={accidentals}
					showVoicing={true}
					{midiEnabled}
					{midiActiveNotes}
					midiExpectedPitchClasses={expectedPitchClasses}
				/>
			</div>

			<!-- MIDI feedback -->
			{#if midiEnabled && midiMatchResult && midiActiveNotes.size > 0}
				<div class="mt-4">
					{#if midiMatchResult.correct}
						<span class="text-[var(--accent-green)] font-semibold text-lg">✓ {t('ui.correct')}</span>
					{:else if midiMatchResult.accuracy > 0}
						<span class="text-[var(--accent-amber)] text-sm">
							{Math.round(midiMatchResult.accuracy * 100)}% – {t('ui.notes_missing', { count: midiMatchResult.missing.length })}
						</span>
					{:else if midiActiveNotes.size > 0}
						<span class="text-[var(--accent-red)] text-sm">{t('ui.wrong_notes')}</span>
					{/if}
				</div>
			{/if}

			<!-- Beat indicator -->
			<div class="flex justify-center gap-1.5 mt-4">
				{#each Array(currentChord?.beats ?? 4) as _, b}
					<div
						class="w-3 h-3 rounded-full transition-all duration-100 {b < currentBeat
							? 'bg-[var(--primary)]'
							: 'bg-[var(--border)]'}"
					></div>
				{/each}
			</div>
		</div>

		<!-- Loop progress -->
		{#if loops > 0}
			<div class="h-1 bg-[var(--bg-muted)] rounded-full overflow-hidden">
				<div
					class="h-full bg-[var(--primary)] transition-all duration-300 rounded-full"
					style="width: {((currentLoop * totalBeatsPerPass + globalBeat - currentLoop * totalBeatsPerPass) / (loops * totalBeatsPerPass)) * 100}%"
				></div>
			</div>
		{/if}
	{/if}

	<!-- Footer hint -->
	<div class="text-center text-xs text-[var(--text-dim)]">
		<strong>ESC</strong> {t('ui.stop').toLowerCase()}
		{#if !midiEnabled}
			· {t('ui.play_along_tip')}
		{/if}
	</div>
</div>
