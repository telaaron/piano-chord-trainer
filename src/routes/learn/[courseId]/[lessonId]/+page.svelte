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
	import { Check, Zap, Volume2, Star, ArrowLeft, ArrowRight } from 'lucide-svelte';

	/** Roman numerals for the step marks — the plate's rehearsal letters. */
	const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];

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
	let practicePoolShuffled = $state<number[]>([]); // shuffled index order for find/free phase

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
			? practiceChordPool[
					practicePoolShuffled.length > 0
						? practicePoolShuffled[practiceChordIndex % practicePoolSize]
						: practiceChordIndex % practiceChordPool.length
				]
			: null,
	);

	const practiceCurrentInterval = $derived(
		practiceIsInterval && practiceIntervalPool.length > 0
			? practiceIntervalPool[
					practicePoolShuffled.length > 0
						? practicePoolShuffled[practiceChordIndex % practicePoolSize]
						: practiceChordIndex % practiceIntervalPool.length
				]
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

	/** Whether a step is completed — completed steps render a lucide Check icon */
	function stepCompleted(index: number): boolean {
		const progress = course ? getLessonProgress(course, lessonId) : null;
		return !!progress?.steps[index]?.completed;
	}

	function stepIcon(type: string, index: number): string {
		if (index === currentStepIndex) return '●';
		return '○';
	}

	/** State modifier for a step tab: done / current / pending */
	function stepState(index: number): string {
		const progress = course ? getLessonProgress(course, lessonId) : null;
		if (progress?.steps[index]?.completed) return 'is-done';
		if (index === currentStepIndex) return 'is-current';
		return 'is-pending';
	}

	// ─── Theory actions ───────────────────────────────────────────
	function playTheoryChord() {
		if (theoryChord) {
			playChord(theoryChord.voicing);
		}
	}

	// ─── Practice logic ───────────────────────────────────────────
	function shuffleIndices(n: number): number[] {
		const arr = Array.from({ length: n }, (_, i) => i);
		for (let i = arr.length - 1; i > 0; i--) {
			const j = Math.floor(Math.random() * (i + 1));
			[arr[i], arr[j]] = [arr[j], arr[i]];
		}
		return arr;
	}

	function resetPractice() {
		practicePhase = 'guided';
		practiceStreak = 0;
		practiceChordIndex = 0;
		practiceCorrect = false;
		practiceShowHint = false;
		practicePoolComplete = false;
		practiceFreeCorrectSet = new Set();
		practicePoolShuffled = [];
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
					practicePoolShuffled = shuffleIndices(practicePoolSize);
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
        <meta name="robots" content="noindex" />
</svelte:head>

{#if !found || !lesson || !course}
	<main class="plate plate-empty">
		<p class="empty-note">{t('learn.not_found_lesson')}</p>
		<a class="crumb" href="/learn">
			<ArrowLeft size={14} aria-hidden="true" />
			{t('learn.back_to_courses')}
		</a>
	</main>
{:else}
	<main class="plate">
		<a class="crumb" href="/learn/{courseId}">
			<ArrowLeft size={14} aria-hidden="true" />
			{t('learn.back_to_course')}
		</a>

		<!-- ── Masthead ── -->
		<header class="masthead">
			<p class="plate-mark">
				{t('learn.plate_lesson')}
				<span class="mark-course">{t(course.titleKey)}</span>
			</p>
			<h1>{t(lesson.titleKey)}</h1>
			<p class="lede">{t(lesson.subtitleKey)}</p>
		</header>

		<!-- Quick-test success -->
		{#if quickTestDone}
			<div class="verdict">
				<Check size={30} class="verdict-icon" aria-hidden="true" />
				<p class="verdict-line">{t('learn.quick_test_success')}</p>
				<a class="btn-stamp" href="/learn/{courseId}">
					{t('learn.back_to_course')}
					<ArrowRight size={15} aria-hidden="true" />
				</a>
			</div>
		{/if}

		<!-- "I know this" quick test — only before the lesson is started -->
		{#if !quickTestMode && !quickTestDone}
			{@const progress = getLessonProgress(course, lessonId)}
			{@const mastery = progress?.mastery ?? 'none'}
			{#if mastery === 'none'}
				<div class="shortcut">
					<button class="btn-ghost" onclick={enterQuickTest}>
						<Zap size={15} aria-hidden="true" />
						{t('learn.quick_test')}
					</button>
					<span class="shortcut-note">{t('learn.quick_test_desc')}</span>
				</div>
			{/if}
		{/if}

		{#if !quickTestDone}
			<!-- ── Step index: numbered marks along a hairline ── -->
			<nav class="steps" aria-label={t('learn.plate_contents')}>
				{#each lesson.steps as step, i (i)}
					<button
						class="step {stepState(i)}"
						onclick={() => goToStep(i)}
						aria-current={i === currentStepIndex ? 'step' : undefined}
					>
						<span class="step-no" aria-hidden="true">{ROMAN[i] ?? i + 1}</span>
						<span class="step-mark" aria-hidden="true">
							{#if stepCompleted(i)}<Check size={14} />{:else}{stepIcon(step.type, i)}{/if}
						</span>
						<span class="step-label">{stepLabel(step.type)}</span>
					</button>
				{/each}
			</nav>

			<!-- ── The worked page ── -->
			<div class="sheet">
				<!-- ═══ THEORY ═══ -->
				{#if currentStep?.type === 'theory'}
					{@const step = currentStep as TheoryStep}
					{@const isInterval = theoryIsInterval}
					{@const voicingLabels = theoryChord && !isInterval && step.exampleChord ? getVoicingIntervalLabels(theoryChord.voicing, step.exampleChord.root, step.exampleChord.quality) : []}

					<!-- Specimen: the chord under examination -->
					{#if theoryChord}
						<div class="specimen">
							<div class="specimen-head">
								<div class="specimen-name">
									{#if isInterval && step.exampleInterval}
										<span class="chordsym">{step.exampleInterval.root} → {step.exampleInterval.target}</span>
										<span class="tag tag-blue">{step.exampleInterval.semitones} {t('learn.semitones')}</span>
									{:else}
										<span class="chordsym">{theoryChord.chord}</span>
										{#if step.exampleChord}
											<span class="tag tag-stamp">{VOICING_LABELS[step.exampleChord.voicing] ?? step.exampleChord.voicing}</span>
										{/if}
									{/if}
								</div>
								<button class="btn-ghost btn-sm" onclick={playTheoryChord}>
									<Volume2 size={15} aria-hidden="true" />
									{t('learn.listen')}
								</button>
							</div>

							<!-- Analysis row — copyist blue, the annotation ink -->
							{#if isInterval && step.exampleInterval}
								<dl class="analysis">
									<div class="an-cell">
										<dt>{step.exampleInterval.root}</dt>
										<dd>{t('learn.interval_root')}</dd>
									</div>
									<div class="an-arrow" aria-hidden="true">→</div>
									<div class="an-cell">
										<dt>{step.exampleInterval.target}</dt>
										<dd>{step.exampleInterval.label}</dd>
									</div>
								</dl>
							{:else if voicingLabels.length > 0}
								<dl class="analysis">
									{#each theoryChord.voicing as note, i (note + i)}
										<div class="an-cell">
											<dt>{note}</dt>
											<dd>{voicingLabels[i] ?? ''}</dd>
										</div>
									{/each}
								</dl>
							{/if}
						</div>
					{/if}

					<!-- Theory prose — the reading measure lives here -->
					<div class="prose">
						<!-- eslint-disable-next-line svelte/no-at-html-tags -->
						{@html formatTheory(t(step.contentKey))}
					</div>

					{#if theoryChord}
						<div class="keyboard">
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

					<div class="sheet-foot">
						<button class="btn-quiet" onclick={skipStep}>{t('learn.skip_step')}</button>
						<button class="btn-stamp" onclick={nextStep}>
							{t('learn.next_step')}
							<ArrowRight size={15} aria-hidden="true" />
						</button>
					</div>

				<!-- ═══ PRACTICE ═══ -->
				{:else if currentStep?.type === 'practice'}
					<!-- Instruction: a margin note in copyist blue -->
					<div class="marginalia" class:is-done={practicePoolComplete}>
						{#if practicePoolComplete}
							<span class="done-note"><Check size={15} aria-hidden="true" /> {t('learn.complete')}</span>
						{:else if practicePhase === 'guided'}
							{practiceIsInterval ? t('learn.practice_guided_interval') : t('learn.practice_guided')}
						{:else if practicePhase === 'find'}
							{t('learn.practice_find')}
						{:else}
							{t('learn.practice_free')}
						{/if}
					</div>

					{#if practiceChordData && !practicePoolComplete}
						<div class="prompt">
							{#if practiceIsInterval && practiceCurrentInterval}
								{#if practicePhase === 'find'}
									<!-- FIND: root shown, target withheld -->
									<span class="prompt-sym">{practiceCurrentInterval.root}</span>
									<p class="prompt-meta">
										<span class="tag tag-blue">+ {practiceCurrentInterval.label}</span>
										<span class="prompt-dim">{practiceCurrentInterval.semitones} {t('learn.semitones')}</span>
									</p>
									{#if practiceCorrect}
										<p class="correct">
											<Check size={15} aria-hidden="true" />
											{practiceCurrentInterval.root} → {practiceCurrentInterval.target}
										</p>
									{/if}
								{:else}
									<!-- GUIDED: both notes shown -->
									<span class="prompt-sym">{practiceCurrentInterval.root} → {practiceCurrentInterval.target}</span>
									<p class="prompt-meta">
										<span class="prompt-dim">{practiceCurrentInterval.label} · {practiceCurrentInterval.semitones} {t('learn.semitones')}</span>
									</p>
									{#if practiceCorrect}
										<p class="correct">{t('learn.practice_correct')}</p>
									{/if}
								{/if}
							{:else}
								<span class="prompt-sym">{practiceChordData.chord}</span>
								{#if practiceCorrect}
									<p class="correct">{t('learn.practice_correct')}</p>
								{/if}
							{/if}
						</div>

						<div class="keyboard">
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
						</div>

						<div class="tally">
							<span class="tally-count">
								{#if practicePhase === 'find'}
									{practiceFreeCorrectSet.size} / {practicePoolSize}
								{:else if practiceStreak > 0}
									{t('learn.practice_streak', { count: String(practiceStreak) })}
								{/if}
							</span>
							{#if (practicePhase === 'find' || practicePhase === 'free') && !practiceShowHint}
								<button class="btn-quiet" onclick={() => practiceShowHint = true}>
									{t('learn.practice_hint')}
								</button>
							{/if}
						</div>
					{/if}

					{#if practicePoolComplete}
						<div class="sheet-foot sheet-foot-end">
							<button class="btn-stamp" onclick={nextStep}>
								{t('learn.next_step')}
								<ArrowRight size={15} aria-hidden="true" />
							</button>
						</div>
					{:else}
						<div class="sheet-foot">
							<button class="btn-quiet" onclick={skipStep}>{t('learn.skip_step')}</button>
						</div>
					{/if}

				<!-- ═══ CHALLENGE ═══ -->
				{:else if currentStep?.type === 'challenge'}
					{@const step = currentStep as ChallengeStep}

					{#if !challengeStarted}
						<div class="brief">
							{#if challengeIsInterval}
								<p class="brief-sym">
									{step.intervalLabel}
									<span class="brief-sub">{step.intervalSemitones} {t('learn.semitones')}</span>
								</p>
								<p class="brief-text">
									{t('learn.challenge_interval_intro', { label: step.intervalLabel!, count: String(step.keys.length), threshold: String(step.masteryThresholdMs) })}
								</p>
							{:else}
								<p class="brief-sym">
									{CHORD_NOTATIONS.standard[step.quality] ?? step.quality}
									<span class="brief-sub">{VOICING_LABELS[step.voicing] ?? step.voicing}</span>
								</p>
								<p class="brief-text">
									{t('learn.challenge_intro', { quality: CHORD_NOTATIONS.standard[step.quality] ?? step.quality, voicing: VOICING_LABELS[step.voicing] ?? step.voicing, count: String(step.keys.length), threshold: String(step.masteryThresholdMs) })}
								</p>
							{/if}
							<button class="btn-stamp btn-lg" onclick={startChallenge}>{t('learn.challenge_go')}</button>
						</div>

						<div class="sheet-foot">
							<button class="btn-quiet" onclick={skipStep}>{t('learn.skip_step')}</button>
						</div>

					{:else if challengeFinished}
						<div class="verdict">
							<p class="score">
								<span class="score-n">{challengeAvgMs}</span>
								<span class="score-u">ms / {challengeIsInterval ? t('learn.challenge_per_interval') : t('learn.challenge_per_chord')}</span>
							</p>

							{#if challengePassed && challengeAvgMs < MASTERY_THRESHOLD_MS}
								<!-- MASTERED -->
								<p class="verdict-line gold">
									<Star size={18} aria-hidden="true" /> {t('learn.challenge_mastered')}
								</p>
								<p class="verdict-sub">
									{t('learn.challenge_mastered_sub', { threshold: String(MASTERY_THRESHOLD_MS) })}
								</p>
								<button class="btn-stamp" onclick={nextStep}>
									{t('learn.next_step')}
									<ArrowRight size={15} aria-hidden="true" />
								</button>

							{:else if challengePassed}
								{@const masteryProgress = Math.min(100, Math.max(5, Math.round(((step.masteryThresholdMs - challengeAvgMs) / (step.masteryThresholdMs - MASTERY_THRESHOLD_MS)) * 100)))}
								<p class="verdict-line green">
									<Check size={17} aria-hidden="true" /> {t('learn.challenge_pass')}
								</p>

								<div class="toward">
									<p class="toward-text">
										{t('learn.challenge_mastery_hint', { threshold: String(MASTERY_THRESHOLD_MS), current: String(challengeAvgMs) })}
									</p>
									<div
										class="meter meter-live"
										role="progressbar"
										aria-valuenow={masteryProgress}
										aria-valuemin="0"
										aria-valuemax="100"
									>
										<span style="width: {masteryProgress}%"></span>
									</div>
									<p class="toward-scale">{challengeAvgMs}ms → {MASTERY_THRESHOLD_MS}ms</p>
								</div>

								<div class="verdict-actions">
									<button class="btn-stamp" onclick={nextStep}>
										{t('learn.next_step')}
										<ArrowRight size={15} aria-hidden="true" />
									</button>
									<button class="btn-live" onclick={startChallenge}>
										<Star size={16} aria-hidden="true" />
										{t('learn.challenge_try_mastery')}
									</button>
								</div>

							{:else}
								<p class="verdict-line">
									{t('learn.challenge_retry', { threshold: String(step.masteryThresholdMs) })}
								</p>
								<button class="btn-ghost" onclick={startChallenge}>{t('learn.challenge_retry_btn')}</button>
							{/if}
						</div>

					{:else}
						<!-- Active run -->
						<p class="run-count">{challengeIndex + 1} / {challengeKeys.length}</p>

						{#if challengeChordData}
							<div class="prompt">
								{#if challengeIsInterval && challengeCurrentInterval}
									<span class="prompt-sym">{challengeCurrentInterval.root}</span>
									<p class="prompt-meta">
										<span class="tag tag-blue">+ {challengeCurrentInterval.label}</span>
									</p>
								{:else}
									<span class="prompt-sym">{challengeChordData.chord}</span>
								{/if}
							</div>

							<div class="keyboard">
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
							</div>
						{/if}
					{/if}
				{/if}
			</div>

			<!-- MIDI status — amber only when genuinely live -->
			<p class="wire" class:is-live={midiEnabled}>
				{#if midiEnabled}
					{t('learn.midi_live')}
				{:else if currentStep?.type !== 'theory'}
					{t('ui.lesson_click_hint')}
				{/if}
			</p>
		{/if}
	</main>
{/if}

<style>
	/* ═══ The plate ═══════════════════════════════════════════════ */
	/* Width is set by the reading measure, not by taste: the prose below
	   caps at 66ch, so the plate has to be wide enough for that cap to be
	   what actually binds. At 44rem the container was the limit and the
	   measure came out at 52 characters — too narrow for long-form. */
	.plate {
		max-width: 52rem;
		width: 100%;
		margin: 0 auto;
		padding: 2rem 1.25rem 4.5rem;
	}
	@media (min-width: 40rem) {
		.plate { padding: 2.5rem 2.5rem 5.5rem; }
	}
	.plate-empty { text-align: center; padding-top: 5rem; }
	.empty-note {
		font-family: var(--font-display);
		font-size: 1.125rem;
		color: var(--text-muted);
		margin: 0 0 1.25rem;
	}

	/* ── Breadcrumb ── */
	.crumb {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
		text-decoration: none;
		transition: color 0.15s;
	}
	.crumb:hover { color: var(--primary); }

	/* ── Masthead ── */
	.masthead {
		margin-top: 1.5rem;
		padding-bottom: 1.5rem;
		border-bottom: 1px solid var(--border);
		margin-bottom: 2rem;
	}
	.plate-mark {
		display: flex;
		align-items: center;
		gap: 0.625rem;
		margin: 0 0 0.7rem;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.19em;
		text-transform: uppercase;
		font-weight: 600;
		color: var(--primary);
	}
	.mark-course {
		color: var(--text-dim);
		font-weight: 400;
		letter-spacing: 0.12em;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.plate-mark::after {
		content: '';
		flex: 1;
		height: 1px;
		min-width: 1rem;
		background: var(--border);
	}
	.masthead h1 {
		font-family: var(--font-display);
		font-size: clamp(1.75rem, 5.2vw, 2.4rem);
		font-weight: 600;
		line-height: 1.12;
		letter-spacing: -0.025em;
		margin: 0;
		max-width: 22ch;
		color: var(--text);
		text-wrap: balance;
	}
	.lede {
		margin: 0.7rem 0 0;
		max-width: 52ch;
		font-size: 1rem;
		line-height: 1.6;
		color: var(--text-muted);
	}

	/* ── Quick-test shortcut ── */
	.shortcut {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.75rem;
		margin-bottom: 2rem;
	}
	.shortcut-note {
		font-size: 0.8125rem;
		color: var(--text-dim);
	}

	/* ── Step index ── */
	.steps {
		display: flex;
		gap: 0;
		margin-bottom: 2rem;
		border-bottom: 1px solid var(--border);
	}
	.step {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.3rem;
		padding: 0.65rem 0.4rem 0.6rem;
		min-height: var(--tap-min);
		background: none;
		border: 0;
		border-bottom: 2px solid transparent;
		margin-bottom: -1px;
		cursor: pointer;
		font-family: inherit;
		transition: color 0.15s, border-color 0.15s, background 0.15s;
	}
	.step:hover { background: var(--bg-card); }
	.step-no {
		font-family: var(--font-mono);
		font-size: 0.5625rem;
		letter-spacing: 0.12em;
		color: var(--text-dim);
	}
	.step-mark {
		display: grid;
		place-items: center;
		height: 1.125rem;
		font-size: 0.8125rem;
		line-height: 1;
	}
	.step-label {
		font-size: 0.75rem;
		font-weight: 500;
		letter-spacing: 0.01em;
	}
	.step.is-pending { color: var(--text-dim); }
	.step.is-current {
		color: var(--primary);
		border-bottom-color: var(--primary);
	}
	.step.is-current .step-no { color: var(--primary); }
	.step.is-current .step-label { font-weight: 600; }
	.step.is-done { color: var(--accent-green); }
	@media (min-width: 30rem) {
		.step-label { font-size: 0.8125rem; }
	}

	/* ── The sheet ── */
	.sheet {
		min-height: 26rem;
		padding: 1.5rem 0 0;
	}

	/* ── Specimen: the chord under examination ── */
	.specimen {
		border: 1px solid var(--border);
		border-top: 2px solid var(--primary);
		background: var(--bg-card);
		padding: 1.1rem 1.15rem 1rem;
		margin-bottom: 1.75rem;
	}
	.specimen-head {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 0.85rem;
	}
	.specimen-name {
		display: flex;
		flex-wrap: wrap;
		align-items: baseline;
		gap: 0.6rem;
		min-width: 0;
	}
	.chordsym {
		font-family: var(--font-display);
		font-size: clamp(1.6rem, 5.5vw, 2.05rem);
		font-weight: 600;
		line-height: 1.05;
		letter-spacing: -0.02em;
		color: var(--text);
		font-variant-numeric: lining-nums;
	}
	.tag {
		font-family: var(--font-mono);
		font-size: 0.5875rem;
		letter-spacing: 0.13em;
		text-transform: uppercase;
		padding: 0.22rem 0.45rem;
		border: 1px solid currentColor;
		white-space: nowrap;
	}
	.tag-stamp { color: var(--primary); }
	.tag-blue { color: var(--ink-blue); }

	/* Analysis row — copyist blue does the labelling */
	.analysis {
		display: flex;
		flex-wrap: wrap;
		align-items: flex-end;
		gap: 0.15rem 1.25rem;
		margin: 1rem 0 0;
		padding-top: 0.85rem;
		border-top: 1px dashed var(--border);
	}
	.an-cell { display: flex; flex-direction: column; gap: 0.1rem; }
	.an-cell dt {
		font-family: var(--font-display);
		font-size: 1rem;
		font-weight: 600;
		color: var(--text);
		font-variant-numeric: lining-nums;
	}
	.an-cell dd {
		margin: 0;
		font-family: var(--font-mono);
		font-size: 0.5875rem;
		letter-spacing: 0.11em;
		text-transform: uppercase;
		color: var(--ink-blue);
	}
	.an-arrow {
		font-size: 0.9rem;
		color: var(--text-dim);
		padding-bottom: 0.15rem;
	}

	/* ── Prose: the reading measure ── */
	.prose {
		max-width: 66ch;
		font-size: 1.0625rem;
		line-height: 1.75;
		color: var(--text-muted);
	}
	.prose :global(strong) {
		color: var(--text);
		font-weight: 600;
	}
	.prose :global(br) { line-height: 2.4; }

	/* ── Keyboard ── */
	.keyboard { margin-top: 1.75rem; }

	/* ── Practice ── */
	.marginalia {
		border-left: 2px solid var(--ink-blue);
		padding: 0.1rem 0 0.1rem 0.85rem;
		max-width: 60ch;
		font-size: 0.9375rem;
		line-height: 1.55;
		color: var(--text-muted);
	}
	.marginalia.is-done { border-left-color: var(--accent-green); }
	.done-note {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		font-weight: 600;
		color: var(--accent-green);
	}

	.prompt {
		text-align: center;
		margin-top: 1.75rem;
	}
	.prompt-sym {
		display: block;
		font-family: var(--font-display);
		font-size: clamp(2.1rem, 8vw, 3rem);
		font-weight: 600;
		line-height: 1.02;
		letter-spacing: -0.03em;
		color: var(--text);
		font-variant-numeric: lining-nums;
	}
	.prompt-meta {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: center;
		gap: 0.55rem;
		margin: 0.7rem 0 0;
	}
	.prompt-dim {
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.11em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	.correct {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		margin: 0.7rem 0 0;
		font-size: 0.9375rem;
		font-weight: 600;
		color: var(--accent-green);
	}

	.tally {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		margin-top: 1.1rem;
		padding-top: 0.85rem;
		border-top: 1px solid var(--border);
	}
	.tally-count {
		font-family: var(--font-mono);
		font-size: 0.6875rem;
		letter-spacing: 0.1em;
		color: var(--text-dim);
		font-variant-numeric: tabular-nums;
	}

	/* ── Challenge brief ── */
	.brief {
		text-align: center;
		padding: 1.5rem 0 0.5rem;
	}
	.brief-sym {
		font-family: var(--font-display);
		font-size: clamp(1.5rem, 5vw, 1.95rem);
		font-weight: 600;
		letter-spacing: -0.02em;
		margin: 0;
		color: var(--text);
	}
	.brief-sub {
		display: block;
		margin-top: 0.35rem;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		font-weight: 400;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--ink-blue);
	}
	.brief-text {
		max-width: 48ch;
		margin: 1.1rem auto 1.75rem;
		font-size: 0.9375rem;
		line-height: 1.65;
		color: var(--text-muted);
	}

	.run-count {
		text-align: center;
		margin: 0;
		font-family: var(--font-mono);
		font-size: 0.6875rem;
		letter-spacing: 0.14em;
		color: var(--text-dim);
		font-variant-numeric: tabular-nums;
	}

	/* ── Verdict ── */
	.verdict {
		text-align: center;
		padding: 1.75rem 0 0.5rem;
	}
	.verdict :global(.verdict-icon) {
		color: var(--accent-green);
		display: block;
		margin: 0 auto 0.85rem;
	}
	.score {
		display: flex;
		align-items: baseline;
		justify-content: center;
		gap: 0.45rem;
		margin: 0 0 1.1rem;
	}
	.score-n {
		font-family: var(--font-display);
		font-size: clamp(2.4rem, 9vw, 3.25rem);
		font-weight: 600;
		line-height: 1;
		letter-spacing: -0.03em;
		color: var(--text);
		font-variant-numeric: tabular-nums lining-nums;
	}
	.score-u {
		font-family: var(--font-mono);
		font-size: 0.6875rem;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	.verdict-line {
		display: inline-flex;
		align-items: center;
		gap: 0.45rem;
		margin: 0;
		font-family: var(--font-display);
		font-size: 1.1875rem;
		font-weight: 600;
		letter-spacing: -0.015em;
		color: var(--text-muted);
	}
	.verdict-line.green { color: var(--accent-green); }
	.verdict-line.gold { color: var(--accent-gold); }
	.verdict-sub {
		max-width: 44ch;
		margin: 0.5rem auto 0;
		font-size: 0.9375rem;
		line-height: 1.6;
		color: var(--text-muted);
	}
	.verdict .btn-stamp,
	.verdict .btn-ghost { margin-top: 1.5rem; }
	.verdict-actions {
		display: flex;
		flex-wrap: wrap;
		justify-content: center;
		gap: 0.75rem;
		margin-top: 1.5rem;
	}
	.verdict-actions .btn-stamp { margin-top: 0; }

	/* Toward mastery — amber is live/target state */
	.toward {
		max-width: 30rem;
		margin: 1.25rem auto 0;
		padding: 0.9rem 1rem;
		text-align: left;
		border: 1px solid var(--border);
		border-left: 2px solid var(--accent-amber);
		background: var(--bg-card);
	}
	.toward-text {
		margin: 0;
		font-size: 0.875rem;
		line-height: 1.55;
		color: var(--text-muted);
	}
	.toward-scale {
		margin: 0.45rem 0 0;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.1em;
		color: var(--text-dim);
		font-variant-numeric: tabular-nums;
	}
	.meter {
		height: 2px;
		margin-top: 0.6rem;
		background: var(--border);
		overflow: hidden;
	}
	.meter span { display: block; height: 100%; transition: width 0.4s ease; }
	.meter-live span { background: var(--accent-amber); }

	/* ── Foot ── */
	.sheet-foot {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		margin-top: 2rem;
		padding-top: 1.15rem;
		border-top: 1px solid var(--border);
	}
	.sheet-foot-end { justify-content: flex-end; }

	/* ── Wire / MIDI status ── */
	.wire {
		margin: 1.25rem 0 0;
		text-align: center;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
		min-height: 1rem;
	}
	.wire.is-live { color: var(--accent-amber); }
	.wire.is-live::before { content: '● '; }

	/* ── Buttons ── */
	.btn-stamp,
	.btn-ghost,
	.btn-live {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		min-height: var(--tap-min);
		padding: 0 1.25rem;
		border-radius: var(--radius-sm);
		font-family: inherit;
		font-size: 0.9375rem;
		font-weight: 600;
		text-decoration: none;
		cursor: pointer;
		transition: background 0.15s, border-color 0.15s, color 0.15s;
	}
	.btn-stamp {
		border: 1.5px solid var(--primary);
		background: var(--primary);
		color: var(--primary-text);
	}
	.btn-stamp:hover {
		background: var(--primary-hover);
		border-color: var(--primary-hover);
	}
	.btn-lg {
		min-height: 3.25rem;
		padding: 0 2.25rem;
		font-size: 1.0625rem;
	}
	.btn-ghost {
		border: 1px solid var(--border);
		background: transparent;
		color: var(--text-muted);
	}
	.btn-ghost:hover {
		border-color: var(--border-hover);
		color: var(--text);
	}
	.btn-sm {
		min-height: 2.25rem;
		padding: 0 0.85rem;
		font-size: 0.8125rem;
		font-weight: 500;
	}
	.btn-live {
		border: 1px solid var(--accent-amber);
		background: transparent;
		color: var(--accent-amber);
	}
	.btn-live:hover { background: var(--warning-muted); }

	.btn-quiet {
		background: none;
		border: 0;
		padding: 0.5rem 0;
		min-height: var(--tap-min);
		font-family: inherit;
		font-size: 0.8125rem;
		color: var(--text-dim);
		cursor: pointer;
		transition: color 0.15s;
	}
	.btn-quiet:hover {
		color: var(--text-muted);
		text-decoration: underline;
		text-underline-offset: 3px;
	}
</style>
