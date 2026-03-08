<script lang="ts">
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { t } from '$lib/i18n';
	import { getLesson } from '$lib/courses';
	import { getLessonProgress, completeStep, recordAttempt, skipLesson } from '$lib/services/course-progress';
	import { getChordNotes, getVoicingNotes, noteToSemitone, getNoteName, CHORD_NOTATIONS, VOICING_LABELS, getVoicingIntervalLabels } from '$lib/engine';
	import type { ChordWithNotes } from '$lib/engine';
	import type { MasteryLevel, TheoryStep, PracticeStep, ChallengeStep, ChordSpec, IntervalSpec } from '$lib/engine/courses';
	import { MASTERY_THRESHOLD_MS } from '$lib/engine/courses';
	import { playChord } from '$lib/services/audio';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import { MidiService } from '$lib/services/midi';
	import type { ChordMatchResult } from '$lib/services/midi';

	// ─── Route params ─────────────────────────────────────────────
	const courseId = $derived(page.params.courseId ?? '');
	const lessonId = $derived(page.params.lessonId ?? '');

	const found = $derived(getLesson(courseId, lessonId));
	const course = $derived(found?.course);
	const lessonModule = $derived(found?.module);
	const lesson = $derived(found?.lesson);

	// ─── Step navigation ──────────────────────────────────────────
	let currentStepIndex = $state(0);
	const currentStep = $derived(lesson?.steps[currentStepIndex]);
	const totalSteps = $derived(lesson?.steps.length ?? 0);

	// ─── MIDI ─────────────────────────────────────────────────────
	const midi = new MidiService();
	let midiEnabled = $state(false);
	let midiActiveNotes = $state<Set<number>>(new Set());
	let midiMatchResult = $state<ChordMatchResult | null>(null);

	// ─── Practice state ───────────────────────────────────────────
	let practicePhase = $state<'guided' | 'find' | 'free'>('guided');
	let practiceStreak = $state(0);
	let practiceChordIndex = $state(0);
	let practiceCorrect = $state(false);
	let practiceShowHint = $state(false);
	let practicePoolComplete = $state(false);
	let practiceFreeCorrectSet = $state<Set<number>>(new Set());

	// ─── Challenge state ──────────────────────────────────────────
	let challengeStarted = $state(false);
	let challengeIndex = $state(0);
	let challengeStartTime = $state(0);
	let challengeChordStart = $state(0);
	let challengeTimings = $state<number[]>([]);
	let challengeFinished = $state(false);
	let challengeAvgMs = $state(0);
	let challengePassed = $state(false);
	let challengeKeys = $state<string[]>([]);

	// ─── Quick-test mode ("Kann ich schon") ───────────────────
	let quickTestMode = $state(false);
	let quickTestDone = $state(false);

	/** Enter quick-test: skip theory, jump to practice. If practice completed → mark lesson done. */
	function enterQuickTest() {
		if (!lesson || !course) return;
		quickTestMode = true;
		// Find practice step index
		const practiceIdx = lesson.steps.findIndex((s) => s.type === 'practice');
		if (practiceIdx >= 0) {
			// Complete theory steps silently
			for (let i = 0; i < practiceIdx; i++) {
				completeStep(course, lessonId, i);
			}
			goToStep(practiceIdx);
		} else {
			// No practice step — just skip the whole lesson
			skipLesson(course, lessonId);
			quickTestDone = true;
		}
	}

	/** Called when practice pool is completed in quick-test mode */
	function finishQuickTest() {
		if (!course || !lesson) return;
		// Complete all remaining steps
		for (let i = 0; i < lesson.steps.length; i++) {
			completeStep(course, lessonId, i);
		}
		quickTestDone = true;
	}

	// ─── Derived chord data ───────────────────────────────────────

	/** Build ChordWithNotes for a ChordSpec */
	function buildChordData(spec: ChordSpec): ChordWithNotes {
		const notes = getChordNotes(spec.root, spec.quality, 'flats');
		const voicing = getVoicingNotes(notes, spec.voicing, spec.root, 'flats');
		const display = `${spec.root}${CHORD_NOTATIONS.standard[spec.quality] ?? spec.quality}`;
		return { chord: display, root: spec.root, type: spec.quality, notes, voicing };
	}

	/** Build ChordWithNotes for a pure interval (2 notes) */
	function buildIntervalData(iv: IntervalSpec): ChordWithNotes {
		const display = `${iv.root} → ${iv.target}`;
		const notes = [iv.root, iv.target];
		return { chord: display, root: iv.root, type: '', notes, voicing: notes };
	}

	/** Build ChordWithNotes for root note only (used in find mode) */
	function buildRootOnlyData(root: string): ChordWithNotes {
		return { chord: root, root, type: '', notes: [root], voicing: [root] };
	}

	/** Is the current theory step an interval (not a chord)? */
	const theoryIsInterval = $derived(
		currentStep?.type === 'theory' && !!(currentStep as TheoryStep).exampleInterval,
	);

	const theoryChord = $derived(
		currentStep?.type === 'theory'
			? (currentStep as TheoryStep).exampleInterval
				? buildIntervalData((currentStep as TheoryStep).exampleInterval!)
				: (currentStep as TheoryStep).exampleChord
					? buildChordData((currentStep as TheoryStep).exampleChord!)
					: null
			: null,
	);

	// ─── Practice: chord vs interval pools ────────────────────────
	const practiceChordPool = $derived(
		currentStep?.type === 'practice'
			? (currentStep as PracticeStep).chordPool ?? []
			: [],
	);

	const practiceIntervalPool = $derived(
		currentStep?.type === 'practice'
			? (currentStep as PracticeStep).intervalPool ?? []
			: [],
	);

	const practiceIsInterval = $derived(practiceIntervalPool.length > 0);
	const practicePoolSize = $derived(practiceIsInterval ? practiceIntervalPool.length : practiceChordPool.length);

	const practiceCurrentSpec = $derived(
		!practiceIsInterval && practiceChordPool.length > 0
			? practiceChordPool[practiceChordIndex % practiceChordPool.length]
			: null,
	);

	const practiceCurrentInterval = $derived(
		practiceIsInterval && practiceIntervalPool.length > 0
			? practiceIntervalPool[practiceChordIndex % practiceIntervalPool.length]
			: null,
	);

	const practiceChordData = $derived(
		practiceIsInterval
			? practiceCurrentInterval ? buildIntervalData(practiceCurrentInterval) : null
			: practiceCurrentSpec ? buildChordData(practiceCurrentSpec) : null,
	);

	// ─── Challenge: chord vs interval ─────────────────────────────
	const challengeIsInterval = $derived(
		currentStep?.type === 'challenge' && (currentStep as ChallengeStep).intervalSemitones !== undefined,
	);

	const challengeCurrentSpec = $derived<ChordSpec | null>(
		currentStep?.type === 'challenge' && challengeStarted && challengeIndex < challengeKeys.length && !challengeIsInterval
			? { root: challengeKeys[challengeIndex], quality: (currentStep as ChallengeStep).quality, voicing: (currentStep as ChallengeStep).voicing }
			: null,
	);

	const challengeCurrentInterval = $derived<IntervalSpec | null>(
		challengeIsInterval && challengeStarted && challengeIndex < challengeKeys.length
			? (() => {
				const step = currentStep as ChallengeStep;
				const root = challengeKeys[challengeIndex];
				const rootSt = noteToSemitone(root);
				const target = getNoteName(rootSt, step.intervalSemitones!, 'flats');
				return { root, target, label: step.intervalLabel!, semitones: step.intervalSemitones! };
			})()
			: null,
	);

	const challengeChordData = $derived(
		challengeIsInterval
			? challengeCurrentInterval ? buildIntervalData(challengeCurrentInterval) : null
			: challengeCurrentSpec ? buildChordData(challengeCurrentSpec) : null,
	);

	// ─── Keyboard display vs validation data ─────────────────────
	// In "find" mode for intervals: keyboard shows only root highlight,
	// but MIDI validation checks both root + target.

	/** Keyboard display data: root-only in find/challenge interval mode */
	const practiceKeyboardData = $derived(
		practiceIsInterval && practicePhase === 'find' && practiceCurrentInterval && !practiceShowHint && !practiceCorrect
			? buildRootOnlyData(practiceCurrentInterval.root)
			: practiceChordData,
	);

	const challengeKeyboardData = $derived(
		challengeIsInterval && challengeCurrentInterval
			? buildRootOnlyData(challengeCurrentInterval.root)
			: challengeChordData,
	);

	// Active chord data for the keyboard highlights
	const activeKeyboardData = $derived(
		currentStep?.type === 'theory' ? theoryChord
		: currentStep?.type === 'practice' ? practiceKeyboardData
		: currentStep?.type === 'challenge' ? challengeKeyboardData
		: null,
	);

	// Full data for MIDI validation (always includes all expected notes)
	const activeFullData = $derived(
		currentStep?.type === 'theory' ? theoryChord
		: currentStep?.type === 'practice' ? practiceChordData
		: currentStep?.type === 'challenge' ? challengeChordData
		: null,
	);

	// Expected pitch classes for MIDI overlay (always full interval/chord)
	const expectedPCs = $derived(
		activeFullData
			? new Set(activeFullData.voicing.map((n) => noteToSemitone(n)).filter((s) => s !== -1))
			: new Set<number>(),
	);

	// Show keyboard highlights?
	const showKeyHighlights = $derived(
		currentStep?.type === 'theory'
		|| (currentStep?.type === 'practice' && (practicePhase === 'guided' || practicePhase === 'find' || practiceShowHint))
	);

	// ─── Step label helpers ───────────────────────────────────────
	function stepLabel(type: string): string {
		return t(`learn.step_${type}`);
	}

	function stepIcon(type: string, index: number): string {
		const progress = course ? getLessonProgress(course, lessonId) : null;
		const stepProg = progress?.steps[index];
		if (stepProg?.completed) return '✓';
		if (index === currentStepIndex) return '●';
		return '○';
	}

	function stepClass(index: number): string {
		const progress = course ? getLessonProgress(course, lessonId) : null;
		const stepProg = progress?.steps[index];
		if (stepProg?.completed) return 'text-[var(--accent-green)]';
		if (index === currentStepIndex) return 'text-[var(--primary)]';
		return 'text-[var(--text-dim)]';
	}

	// ─── Theory actions ───────────────────────────────────────────
	function playTheoryChord() {
		if (theoryChord) {
			playChord(theoryChord.voicing);
		}
	}

	// ─── Practice logic ───────────────────────────────────────────
	function resetPractice() {
		practicePhase = 'guided';
		practiceStreak = 0;
		practiceChordIndex = 0;
		practiceCorrect = false;
		practiceShowHint = false;
		practicePoolComplete = false;
		practiceFreeCorrectSet = new Set();
		midiMatchResult = null;
	}

	function handlePracticeMidi(activeNotes: Set<number>) {
		midiActiveNotes = new Set(activeNotes);
		if (!practiceChordData || practicePoolComplete) return;

		const result = midi.checkChord(practiceChordData.voicing);
		midiMatchResult = result;

		if (result.correct && activeNotes.size > 0 && !practiceCorrect) {
			practiceCorrect = true;
			practiceStreak++;

			const guidedCount = currentStep?.type === 'practice' ? (currentStep as PracticeStep).guidedCount : 3;

			if (practicePhase === 'guided' && practiceStreak >= guidedCount) {
				// Transition: intervals → find phase, chords → free phase
				const nextPhase = practiceIsInterval ? 'find' : 'free';
				setTimeout(() => {
					practicePhase = nextPhase;
					practiceStreak = 0;
					practiceChordIndex = 0;
					practiceCorrect = false;
					practiceFreeCorrectSet = new Set();
					midiMatchResult = null;
				}, 800);
			} else if (practicePhase === 'find' || practicePhase === 'free') {
				practiceFreeCorrectSet = new Set([...practiceFreeCorrectSet, practiceChordIndex]);
				if (practiceFreeCorrectSet.size >= practicePoolSize) {
					// All chords done without help
					setTimeout(() => {
						practicePoolComplete = true;
						if (quickTestMode) finishQuickTest();
					}, 600);
				}
			}

			// Advance to next chord after short delay
			if (!practicePoolComplete) {
				setTimeout(() => {
					practiceChordIndex = (practiceChordIndex + 1) % practicePoolSize;
					practiceCorrect = false;
					practiceShowHint = false;
					midiMatchResult = null;
					midi.releaseAll();
				}, 800);
			}
		}
	}

	// Click-piano fallback for practice
	function handlePracticeClick(chrIdx: number) {
		if (!practiceChordData || practicePoolComplete) return;
		// Toggle note in active set
		const pc = chrIdx % 12;
		const newSet = new Set(midiActiveNotes);
		// We map chrIdx to a MIDI note number (C4 = 60 base, chrIdx 0 = C)
		const midiNote = 60 + chrIdx;
		
		if (newSet.has(midiNote)) {
			newSet.delete(midiNote);
		} else {
			newSet.add(midiNote);
		}
		handlePracticeMidi(newSet);
	}

	// ─── Challenge logic ──────────────────────────────────────────
	function startChallenge() {
		if (currentStep?.type !== 'challenge') return;
		const step = currentStep as ChallengeStep;
		challengeKeys = [...step.keys].sort(() => Math.random() - 0.5); // shuffle
		challengeIndex = 0;
		challengeTimings = [];
		challengeStarted = true;
		challengeFinished = false;
		challengeStartTime = Date.now();
		challengeChordStart = Date.now();
		midiMatchResult = null;
	}

	function handleChallengeMidi(activeNotes: Set<number>) {
		midiActiveNotes = new Set(activeNotes);
		if (!challengeChordData || challengeFinished || !challengeStarted) return;

		const result = midi.checkChord(challengeChordData.voicing);
		midiMatchResult = result;

		if (result.correct && activeNotes.size > 0) {
			const elapsed = Date.now() - challengeChordStart;
			challengeTimings = [...challengeTimings, elapsed];
			challengeIndex++;

			if (challengeIndex >= challengeKeys.length) {
				// Challenge complete
				const totalMs = challengeTimings.reduce((a, b) => a + b, 0);
				challengeAvgMs = Math.round(totalMs / challengeTimings.length);
				const threshold = (currentStep as ChallengeStep).masteryThresholdMs;
				challengePassed = challengeAvgMs <= threshold;
				challengeFinished = true;

				if (course) {
					if (challengePassed) {
						completeStep(course, lessonId, currentStepIndex, challengeAvgMs);
					} else {
						recordAttempt(course, lessonId, currentStepIndex, challengeAvgMs);
					}
				}
			} else {
				challengeChordStart = Date.now();
				midiMatchResult = null;
				midi.releaseAll();
			}
		}
	}

	// ─── Click-piano for challenge ────────────────────────────────
	function handleChallengeClick(chrIdx: number) {
		if (!challengeChordData || challengeFinished || !challengeStarted) return;
		const midiNote = 60 + chrIdx;
		const newSet = new Set(midiActiveNotes);
		if (newSet.has(midiNote)) {
			newSet.delete(midiNote);
		} else {
			newSet.add(midiNote);
		}
		handleChallengeMidi(newSet);
	}

	// ─── MIDI note callback dispatch ──────────────────────────────
	function handleMidiNotes(activeNotes: Set<number>) {
		if (currentStep?.type === 'practice') {
			handlePracticeMidi(activeNotes);
		} else if (currentStep?.type === 'challenge') {
			handleChallengeMidi(activeNotes);
		} else {
			midiActiveNotes = new Set(activeNotes);
		}
	}

	// ─── Step navigation ──────────────────────────────────────────
	function goToStep(index: number) {
		if (index < 0 || index >= totalSteps) return;
		currentStepIndex = index;
		resetPractice();
		challengeStarted = false;
		challengeFinished = false;
		midiMatchResult = null;
		midiActiveNotes = new Set();
		midi.releaseAll();
	}

	function nextStep() {
		if (currentStep?.type === 'theory' && course) {
			completeStep(course, lessonId, currentStepIndex);
		}
		if (currentStep?.type === 'practice' && practicePoolComplete && course) {
			completeStep(course, lessonId, currentStepIndex);
		}
		if (currentStepIndex < totalSteps - 1) {
			goToStep(currentStepIndex + 1);
		} else {
			// All steps done — go back to course overview
			goto(`/learn/${courseId}`);
		}
	}

	function skipStep() {
		if (course) {
			completeStep(course, lessonId, currentStepIndex);
		}
		nextStep();
	}

	// ─── Keyboard click handler ───────────────────────────────────
	function handleKeyClick(chrIdx: number) {
		if (currentStep?.type === 'practice') {
			handlePracticeClick(chrIdx);
		} else if (currentStep?.type === 'challenge') {
			handleChallengeClick(chrIdx);
		}
	}

	// ─── Lifecycle ────────────────────────────────────────────────
	onMount(() => {
		// Load lesson progress to resume at last incomplete step
		if (course && lesson) {
			const progress = getLessonProgress(course, lessonId);
			if (progress) {
				const firstIncomplete = progress.steps.findIndex((s) => !s.completed);
				if (firstIncomplete > 0) {
					currentStepIndex = firstIncomplete;
				}
			}
		}

		midi.onNotes(handleMidiNotes);
		midi.onConnection(() => {});
		midi.onDevices((devices) => {
			if (devices.length > 0) midiEnabled = true;
		});
		midi.init();

		return () => {
			midi.destroy();
		};
	});

	// ─── Format theory text with basic markdown ───────────────────
	function formatTheory(text: string): string {
		return text
			.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
			.replace(/\n/g, '<br>');
	}
</script>

<svelte:head>
	<title>{lesson ? t(lesson.titleKey) : 'Lesson'} – Chord Trainer</title>
</svelte:head>

{#if !found || !lesson || !course}
	<main class="max-w-3xl mx-auto px-4 py-12 text-center">
		<p class="text-[var(--text-muted)]">Lesson not found.</p>
		<a href="/learn" class="text-[var(--primary)] hover:underline mt-4 inline-block">{t('learn.back_to_courses')}</a>
	</main>
{:else}
	<main class="max-w-3xl mx-auto px-4 sm:px-6 py-6 sm:py-10">
		<!-- Breadcrumb -->
		<div class="mb-6">
			<a href="/learn/{courseId}" class="text-sm text-[var(--text-muted)] hover:text-[var(--primary)] transition-colors">
				{t('learn.back_to_course')}
			</a>
		</div>

		<!-- Lesson header -->
		<div class="mb-6">
			<h1 class="text-xl sm:text-2xl font-bold text-[var(--text)]">{t(lesson.titleKey)}</h1>
			<p class="text-sm text-[var(--text-muted)] mt-1">{t(lesson.subtitleKey)}</p>
		</div>

		<!-- Quick-test success overlay -->
		{#if quickTestDone}
			<div class="card p-8 text-center space-y-4 mb-6">
				<span class="text-4xl">✓</span>
				<p class="text-lg font-bold text-[var(--accent-green)]">{t('learn.quick_test_success')}</p>
				<a
					href="/learn/{courseId}"
					class="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-[var(--primary)] text-[var(--primary-text)] font-medium text-sm hover:bg-[var(--primary-hover)] transition-colors"
				>
					{t('learn.back_to_course')}
				</a>
			</div>
		{/if}

		<!-- "Kann ich schon" quick-test button (only if lesson not started and not in quick-test) -->
		{#if !quickTestMode && !quickTestDone}
			{@const progress = getLessonProgress(course, lessonId)}
			{@const mastery = progress?.mastery ?? 'none'}
			{#if mastery === 'none'}
				<div class="mb-6 flex items-center gap-3">
					<button
						onclick={enterQuickTest}
						class="flex items-center gap-2 px-4 py-2 rounded-lg border border-[var(--border)] text-sm text-[var(--text-muted)] hover:text-[var(--text)] hover:border-[var(--accent-amber)] transition-colors"
					>
						⚡ {t('learn.quick_test')}
					</button>
					<span class="text-xs text-[var(--text-dim)]">{t('learn.quick_test_desc')}</span>
				</div>
			{/if}
		{/if}

		<!-- Step tabs -->
		{#if !quickTestDone}
		<div class="flex gap-1 mb-8">
			{#each lesson.steps as step, i (i)}
				<button
					onclick={() => goToStep(i)}
					class="flex-1 flex flex-col items-center gap-1 py-2.5 px-2 rounded-lg transition-colors text-xs sm:text-sm
						{i === currentStepIndex 
							? 'bg-[var(--primary-muted)] border border-[var(--primary)]/40' 
							: 'hover:bg-[var(--bg-card-hover)]'}"
				>
					<span class="{stepClass(i)} text-lg">{stepIcon(step.type, i)}</span>
					<span class="{stepClass(i)} font-medium">{stepLabel(step.type)}</span>
				</button>
			{/each}
		</div>

		<!-- Step content -->
		<div class="card p-5 sm:p-8 min-h-[28rem]">
			<!-- ═══ THEORY STEP ═══ -->
			{#if currentStep?.type === 'theory'}
				{@const step = currentStep as TheoryStep}
				{@const isInterval = theoryIsInterval}
				{@const voicingLabels = theoryChord && !isInterval && step.exampleChord ? getVoicingIntervalLabels(theoryChord.voicing, step.exampleChord.root, step.exampleChord.quality) : []}
				<div class="space-y-6">
					<!-- Header card -->
					{#if theoryChord}
						<div class="rounded-xl bg-[var(--surface-alt,var(--surface))]/60 border border-[var(--border)]/40 p-4 sm:p-5">
							<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
								<div>
									{#if isInterval && step.exampleInterval}
										<!-- Interval display: root → target with semitones -->
										<span class="text-2xl sm:text-3xl font-bold text-[var(--text)]">{step.exampleInterval.root} → {step.exampleInterval.target}</span>
										<span class="ml-2 text-xs px-2 py-0.5 rounded-full bg-[var(--accent-amber)]/15 text-[var(--accent-amber)] font-medium">
											{step.exampleInterval.semitones} {t('learn.semitones')}
										</span>
									{:else}
										<!-- Chord display -->
										<span class="text-2xl sm:text-3xl font-bold text-[var(--text)]">{theoryChord.chord}</span>
										{#if step.exampleChord}
											<span class="ml-2 text-xs px-2 py-0.5 rounded-full bg-[var(--primary)]/15 text-[var(--primary)] font-medium">
												{VOICING_LABELS[step.exampleChord.voicing] ?? step.exampleChord.voicing}
											</span>
										{/if}
									{/if}
								</div>
								<button 
									onclick={playTheoryChord}
									class="flex items-center gap-1.5 px-4 py-2 rounded-lg border border-[var(--border)] text-sm text-[var(--text-muted)] hover:text-[var(--text)] hover:border-[var(--border-hover)] transition-colors self-start sm:self-auto"
								>
									🔊 {t('learn.listen')}
								</button>
							</div>
							<!-- Note pills -->
							{#if isInterval && step.exampleInterval}
								<div class="flex flex-wrap gap-1.5 mt-3">
									<span class="text-xs px-2 py-1 rounded-md bg-[var(--border)]/30 text-[var(--text-muted)] font-mono">
										{step.exampleInterval.root}
										<span class="text-[var(--text-dim)] ml-0.5">({t('learn.interval_root')})</span>
									</span>
									<span class="text-[var(--text-dim)] self-center">→</span>
									<span class="text-xs px-2 py-1 rounded-md bg-[var(--border)]/30 text-[var(--text-muted)] font-mono">
										{step.exampleInterval.target}
										<span class="text-[var(--text-dim)] ml-0.5">({step.exampleInterval.label})</span>
									</span>
								</div>
							{:else if voicingLabels.length > 0}
								<div class="flex flex-wrap gap-1.5 mt-3">
									{#each theoryChord.voicing as note, i}
										<span class="text-xs px-2 py-1 rounded-md bg-[var(--border)]/30 text-[var(--text-muted)] font-mono">
											{note}
											<span class="text-[var(--text-dim)] ml-0.5">({voicingLabels[i] ?? ''})</span>
										</span>
									{/each}
								</div>
							{/if}
						</div>
					{/if}

					<!-- Theory text -->
					<div class="prose prose-invert max-w-none text-sm sm:text-base leading-relaxed text-[var(--text-muted)]">
						<!-- eslint-disable-next-line svelte/no-at-html-tags -->
						{@html formatTheory(t(step.contentKey))}
					</div>

					<!-- Interactive keyboard -->
					{#if theoryChord}
						<div class="mt-2">
							<PianoKeyboard
								chordData={theoryChord}
								showVoicing={true}
								accidentalPref="flats"
								midiActiveNotes={midiActiveNotes}
								midiExpectedPitchClasses={expectedPCs}
								midiEnabled={midiEnabled}
							/>
						</div>
					{/if}

					<!-- Navigation -->
					<div class="flex justify-between items-center pt-4 border-t border-[var(--border)]/30">
						<button
							onclick={skipStep}
							class="text-sm text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors"
						>
							{t('learn.skip_step')} →
						</button>
						<button
							onclick={nextStep}
							class="px-5 py-2.5 rounded-lg bg-[var(--primary)] text-[var(--primary-text)] font-medium text-sm hover:bg-[var(--primary-hover)] transition-colors"
						>
							{t('learn.next_step')} →
						</button>
					</div>
				</div>

			<!-- ═══ PRACTICE STEP ═══ -->
			{:else if currentStep?.type === 'practice'}
				<div class="space-y-5">
					<!-- Phase indicator -->
					<div class="text-sm text-[var(--text-muted)]">
						{#if practicePoolComplete}
							<span class="text-[var(--accent-green)] font-medium">✓ {t('learn.complete')}</span>
						{:else if practicePhase === 'guided'}
							<p>{practiceIsInterval ? t('learn.practice_guided_interval') : t('learn.practice_guided')}</p>
						{:else if practicePhase === 'find'}
							<p>{t('learn.practice_find')}</p>
						{:else}
							<p>{t('learn.practice_free')}</p>
						{/if}
					</div>

					<!-- Current chord / interval display -->
					{#if practiceChordData && !practicePoolComplete}
						<div class="text-center">
							{#if practiceIsInterval && practiceCurrentInterval}
								{#if practicePhase === 'find'}
									<!-- FIND MODE: show root + interval name, hide target -->
									<span class="text-3xl sm:text-4xl font-bold text-[var(--text)]">
										{practiceCurrentInterval.root}
									</span>
									<div class="flex items-center justify-center gap-2 mt-2">
										<span class="px-3 py-1 rounded-full bg-[var(--accent-amber)]/15 text-[var(--accent-amber)] font-medium text-sm">
											+ {practiceCurrentInterval.label}
										</span>
										<span class="text-xs text-[var(--text-dim)]">
											({practiceCurrentInterval.semitones} {t('learn.semitones')})
										</span>
									</div>
									{#if practiceCorrect}
										<p class="text-sm text-[var(--accent-green)] mt-3 font-medium">
											✓ {practiceCurrentInterval.root} → {practiceCurrentInterval.target}
										</p>
									{/if}
								{:else}
									<!-- GUIDED MODE: show both notes -->
									<span class="text-3xl sm:text-4xl font-bold text-[var(--text)]">
										{practiceCurrentInterval.root} → {practiceCurrentInterval.target}
									</span>
									<p class="text-xs text-[var(--text-dim)] mt-1">{practiceCurrentInterval.label} · {practiceCurrentInterval.semitones} {t('learn.semitones')}</p>
									{#if practiceCorrect}
										<p class="text-sm text-[var(--accent-green)] mt-2 font-medium">
											{t('learn.practice_correct')}
										</p>
									{/if}
								{/if}
							{:else}
								<span class="text-3xl sm:text-4xl font-bold text-[var(--text)]">
									{practiceChordData.chord}
								</span>
								{#if practiceCorrect}
									<p class="text-sm text-[var(--accent-green)] mt-2 font-medium">
										{t('learn.practice_correct')}
									</p>
								{/if}
							{/if}
						</div>

						<!-- Keyboard -->
						<PianoKeyboard
							chordData={showKeyHighlights ? practiceKeyboardData : null}
							showVoicing={showKeyHighlights}
							accidentalPref="flats"
							midiActiveNotes={midiActiveNotes}
							midiExpectedPitchClasses={expectedPCs}
							midiEnabled={midiEnabled || true}
							interactive={!midiEnabled}
							onKeyClick={handleKeyClick}
						/>

						<!-- Streak / Hint / Progress -->
						<div class="flex items-center justify-between text-sm">
							<span class="text-[var(--text-dim)]">
								{#if practicePhase === 'find'}
									{practiceFreeCorrectSet.size} / {practicePoolSize}
								{:else if practiceStreak > 0}
									{t('learn.practice_streak', { count: String(practiceStreak) })}
								{/if}
							</span>
							{#if (practicePhase === 'find' || practicePhase === 'free') && !practiceShowHint}
								<button
									onclick={() => practiceShowHint = true}
									class="text-[var(--text-muted)] hover:text-[var(--primary)] transition-colors"
								>
									{t('learn.practice_hint')}
								</button>
							{/if}
						</div>
					{/if}

					<!-- Navigation when complete -->
					{#if practicePoolComplete}
						<div class="flex justify-end pt-4 border-t border-[var(--border)]/30">
							<button
								onclick={nextStep}
								class="px-5 py-2.5 rounded-lg bg-[var(--primary)] text-[var(--primary-text)] font-medium text-sm hover:bg-[var(--primary-hover)] transition-colors"
							>
								{t('learn.next_step')} →
							</button>
						</div>
					{/if}

					<!-- Skip option -->
					{#if !practicePoolComplete}
						<div class="pt-4 border-t border-[var(--border)]/30">
							<button
								onclick={skipStep}
								class="text-sm text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors"
							>
								{t('learn.skip_step')} →
							</button>
						</div>
					{/if}
				</div>

			<!-- ═══ CHALLENGE STEP ═══ -->
			{:else if currentStep?.type === 'challenge'}
				{@const step = currentStep as ChallengeStep}
				<div class="space-y-5">
					{#if !challengeStarted}
						<!-- Pre-challenge intro -->
						<div class="text-center space-y-4 py-6">
							{#if challengeIsInterval}
								<p class="text-lg font-medium text-[var(--text)]">
									{step.intervalLabel}
									<span class="text-sm font-normal text-[var(--text-muted)] ml-1">
										({step.intervalSemitones} {t('learn.semitones')})
									</span>
								</p>
								<p class="text-sm text-[var(--text-muted)]">
									{t('learn.challenge_interval_intro', { label: step.intervalLabel!, count: String(step.keys.length), threshold: String(step.masteryThresholdMs) })}
								</p>
							{:else}
								<p class="text-lg font-medium text-[var(--text)]">
									{CHORD_NOTATIONS.standard[step.quality] ?? step.quality}
									<span class="text-sm font-normal text-[var(--text-muted)] ml-1">
										{VOICING_LABELS[step.voicing] ?? step.voicing}
									</span>
								</p>
								<p class="text-sm text-[var(--text-muted)]">
									{t('learn.challenge_intro', { quality: CHORD_NOTATIONS.standard[step.quality] ?? step.quality, voicing: VOICING_LABELS[step.voicing] ?? step.voicing, count: String(step.keys.length), threshold: String(step.masteryThresholdMs) })}
								</p>
							{/if}
							<button
								onclick={startChallenge}
								class="px-8 py-3 rounded-lg bg-[var(--primary)] text-[var(--primary-text)] font-bold text-lg hover:bg-[var(--primary-hover)] transition-colors"
							>
								{t('learn.challenge_go')}
							</button>
						</div>

						<!-- Skip option -->
						<div class="pt-4 border-t border-[var(--border)]/30">
							<button
								onclick={skipStep}
								class="text-sm text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors"
							>
								{t('learn.skip_step')} →
							</button>
						</div>

					{:else if challengeFinished}
						<!-- Results -->
						<div class="text-center space-y-4 py-6">
							<!-- Average time display -->
							<div class="inline-flex items-baseline gap-2">
								<span class="text-4xl font-bold text-[var(--text)] tabular-nums">{challengeAvgMs}</span>
								<span class="text-sm text-[var(--text-muted)]">ms / {challengeIsInterval ? t('learn.challenge_per_interval') : t('learn.challenge_per_chord')}</span>
							</div>

							{#if challengePassed && challengeAvgMs < MASTERY_THRESHOLD_MS}
								<!-- MASTERED! -->
								<div class="space-y-2">
									<p class="text-[var(--accent-green)] font-bold text-lg">
										⭐ {t('learn.challenge_mastered')}
									</p>
									<p class="text-sm text-[var(--text-muted)]">
										{t('learn.challenge_mastered_sub', { threshold: String(MASTERY_THRESHOLD_MS) })}
									</p>
								</div>
								<button
									onclick={nextStep}
									class="px-6 py-2.5 rounded-lg bg-[var(--primary)] text-[var(--primary-text)] font-medium hover:bg-[var(--primary-hover)] transition-colors"
								>
									{t('learn.next_step')} →
								</button>

							{:else if challengePassed}
								{@const masteryProgress = Math.min(100, Math.max(5, Math.round(((step.masteryThresholdMs - challengeAvgMs) / (step.masteryThresholdMs - MASTERY_THRESHOLD_MS)) * 100)))}
								<!-- Passed but not mastered -->
								<div class="space-y-2">
									<p class="text-[var(--accent-green)] font-medium">
										✓ {t('learn.challenge_pass')}
									</p>
									<!-- Mastery encouragement -->
									<div class="rounded-lg bg-[var(--border)]/15 border border-[var(--border)]/30 p-3 mt-3">
										<p class="text-sm text-[var(--text-muted)]">
											{t('learn.challenge_mastery_hint', { threshold: String(MASTERY_THRESHOLD_MS), current: String(challengeAvgMs) })}
										</p>
										<!-- Progress bar toward mastery -->
										<div class="mt-2 h-1.5 rounded-full bg-[var(--border)]/30 overflow-hidden">
											<div 
												class="h-full rounded-full bg-[var(--accent-amber)] transition-all"
												style="width: {masteryProgress}%"
											></div>
										</div>
										<p class="text-xs text-[var(--text-dim)] mt-1 tabular-nums">
											{challengeAvgMs}ms → {MASTERY_THRESHOLD_MS}ms
										</p>
									</div>
								</div>
								<div class="flex flex-col sm:flex-row gap-3 justify-center">
									<button
										onclick={nextStep}
										class="px-6 py-2.5 rounded-lg bg-[var(--primary)] text-[var(--primary-text)] font-medium hover:bg-[var(--primary-hover)] transition-colors"
									>
										{t('learn.next_step')} →
									</button>
									<button
										onclick={startChallenge}
										class="px-6 py-2.5 rounded-lg border border-[var(--accent-amber)]/50 text-[var(--accent-amber)] font-medium hover:bg-[var(--accent-amber)]/10 transition-colors"
									>
										⭐ {t('learn.challenge_try_mastery')}
									</button>
								</div>

							{:else}
								<!-- Failed -->
								<p class="text-[var(--accent-amber)]">
									{t('learn.challenge_retry', { threshold: String(step.masteryThresholdMs) })}
								</p>
								<button
									onclick={startChallenge}
									class="px-6 py-2.5 rounded-lg border border-[var(--border)] text-[var(--text-muted)] hover:text-[var(--text)] font-medium transition-colors"
								>
									{t('learn.challenge_retry_btn')}
								</button>
							{/if}
						</div>

					{:else}
						<!-- Active challenge -->
						<div class="text-center mb-4">
							<span class="text-xs text-[var(--text-dim)]">
								{challengeIndex + 1} / {challengeKeys.length}
							</span>
						</div>

						{#if challengeChordData}
							<div class="text-center">
								{#if challengeIsInterval && challengeCurrentInterval}
									<span class="text-3xl sm:text-4xl font-bold text-[var(--text)]">
										{challengeCurrentInterval.root}
									</span>
									<div class="flex items-center justify-center gap-2 mt-1">
										<span class="px-3 py-1 rounded-full bg-[var(--accent-amber)]/15 text-[var(--accent-amber)] font-medium text-sm">
											+ {challengeCurrentInterval.label}
										</span>
									</div>
								{:else}
									<span class="text-3xl sm:text-4xl font-bold text-[var(--text)]">
										{challengeChordData.chord}
									</span>
								{/if}
							</div>

							<PianoKeyboard
								chordData={challengeKeyboardData}
								showVoicing={challengeIsInterval}
								accidentalPref="flats"
								midiActiveNotes={midiActiveNotes}
								midiExpectedPitchClasses={expectedPCs}
								midiEnabled={midiEnabled || true}
								interactive={!midiEnabled}
								onKeyClick={handleKeyClick}
							/>
						{/if}
					{/if}
				</div>
			{/if}
		</div>

		<!-- MIDI status indicator -->
		{#if midiEnabled}
			<div class="mt-4 text-center text-xs text-[var(--accent-green)]">
				MIDI ●
			</div>
		{:else}
			<div class="mt-4 text-center text-xs text-[var(--text-dim)]">
				{#if currentStep?.type !== 'theory'}
					{t('ui.lesson_click_hint')}
				{/if}
			</div>
		{/if}
		{/if}<!-- end !quickTestDone -->
	</main>
{/if}
