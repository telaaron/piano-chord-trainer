<script lang="ts">
	// To-Go — practice away from the piano.
	//
	// This screen is a thin shell over src/lib/engine/togo.ts. The engine builds
	// and grades; this file only sounds things out, collects the answer, and hands
	// the result back. Rendering is driven GENERICALLY by `exercise.play.type` and
	// `exercise.input.type` — there is no per-discipline branch anywhere below.

	import { onDestroy } from 'svelte';
	import { browser } from '$app/environment';
	import { t } from '$lib/i18n';
	import {
		ALL_TOGO_KINDS,
		DEFAULT_TOGO_PARAMS,
		applyResultsToCards,
		buildTheoryDeck,
		buildToGoSession,
		gradeChoice,
		gradeNotes,
		gradeSing,
		gradeTaps,
		summarize,
		type TapScore,
		type ToGoExercise,
		type ToGoKind,
		type ToGoResult,
		type ToGoSession,
	} from '$lib/engine/togo';
	import { applyEarTallies, earFocus, skillMapProgress, tallyEarResults } from '$lib/engine/coach';
	import { loadCoachState, saveCoachState } from '$lib/services/coach-state';
	import { loadCardStates, saveCardStates } from '$lib/services/togo-state';
	import {
		playChord,
		playNote,
		startDrone,
		stopDrone,
		stopMetronome,
		stopAll,
	} from '$lib/services/audio';
	import SingInput from '$lib/components/togo/SingInput.svelte';
	import TapInput from '$lib/components/togo/TapInput.svelte';
	import NotesInput from '$lib/components/togo/NotesInput.svelte';
	import { ArrowLeft, Check, Ear, Play, RotateCcw, X } from 'lucide-svelte';

	type Phase = 'start' | 'run' | 'results';

	// ─── Capabilities ───────────────────────────────────────────
	// Audio is a browser thing (SSR has none); the mic we only claim when the
	// platform can actually offer one — the engine then drops `sing` on its own.
	let audioOn = $state(true);
	const micAvailable = $derived(
		browser && typeof navigator !== 'undefined' && !!navigator.mediaDevices?.getUserMedia,
	);
	const caps = $derived({ audio: browser && audioOn, mic: micAvailable && audioOn });

	// ─── Session state ──────────────────────────────────────────
	let phase = $state<Phase>('start');
	let session = $state<ToGoSession | null>(null);
	let index = $state(0);
	let results = $state<ToGoResult[]>([]);
	let startedAt = 0;

	/** null while unanswered; then the graded outcome for the reveal. */
	let verdict = $state<boolean | null>(null);
	let chosenIndex = $state<number | null>(null);
	let tapScore = $state<TapScore | null>(null);
	let playing = $state(false);

	/** Ear-map progress, refreshed after each save. */
	let earProgress = $state<{ total: number; earMastered: number } | null>(null);

	const exercise = $derived<ToGoExercise | null>(session?.exercises[index] ?? null);
	const summary = $derived(results.length > 0 ? summarize(results) : null);

	// Timers for the sequence playback chain — cancelled on teardown so a note
	// can never fire after the exercise (or the page) is gone.
	let seqTimers: ReturnType<typeof setTimeout>[] = [];

	function clearSeqTimers() {
		for (const id of seqTimers) clearTimeout(id);
		seqTimers = [];
	}

	function silence() {
		clearSeqTimers();
		stopDrone();
		stopMetronome();
		stopAll();
		playing = false;
	}

	// ─── Playback: one branch per play.type ─────────────────────

	/** Note names arrive bare ("Bb"); the drone and sequence want an octave. */
	function withOctave(note: string, octave = 4): string {
		return /\d/.test(note) ? note : `${note}${octave}`;
	}

	async function sound(ex: ToGoExercise) {
		clearSeqTimers();
		if (!caps.audio) return;
		const p = ex.play;

		if (p.type === 'chord') {
			playing = true;
			await playChord(p.notes, '1n');
			playing = false;
			return;
		}

		if (p.type === 'sequence') {
			// Own setTimeout chain rather than playArpeggio: the engine's step is a
			// musical value we must honour exactly, and a progression's flat note
			// stream needs each note in its own slot, not re-octaved as an arpeggio.
			playing = true;
			// Warm the audio path so the first note isn't late.
			await playNote(withOctave(p.notes[0]), '8n');
			for (let i = 1; i < p.notes.length; i++) {
				seqTimers.push(
					setTimeout(() => {
						playNote(withOctave(p.notes[i]), '8n');
						if (i === p.notes.length - 1) playing = false;
					}, i * p.stepMs),
				);
			}
			if (p.notes.length <= 1) playing = false;
			return;
		}

		if (p.type === 'chords') {
			// A cadence: each step is a whole chord, so the progression is heard
			// as harmony rather than a run of single notes.
			playing = true;
			await playChord(p.chords[0], '2n');
			for (let i = 1; i < p.chords.length; i++) {
				seqTimers.push(
					setTimeout(() => {
						playChord(p.chords[i], '2n');
						if (i === p.chords.length - 1) playing = false;
					}, i * p.stepMs),
				);
			}
			if (p.chords.length <= 1) playing = false;
			return;
		}

		if (p.type === 'drone') {
			await startDrone(p.note);
			return;
		}

		// 'pulse' is owned by TapInput (it needs the beat callback); 'silent' is silent.
	}

	// ─── Session lifecycle ──────────────────────────────────────

	function begin(only?: ToGoKind) {
		silence();
		const coach = loadCoachState();
		const focus = earFocus(coach);
		const built = buildToGoSession(
			Math.random,
			caps,
			{
				deck: buildTheoryDeck(),
				cardStates: loadCardStates(),
				now: Date.now(),
				focusQuality: focus?.quality,
				focusUnitId: focus?.unitId,
				only,
			},
			DEFAULT_TOGO_PARAMS,
		);
		session = built;
		index = 0;
		results = [];
		resetRound();
		phase = 'run';
		if (built.exercises[0]) {
			startedAt = performance.now();
			sound(built.exercises[0]);
		}
	}

	function resetRound() {
		verdict = null;
		chosenIndex = null;
		tapScore = null;
	}

	/** Record the graded outcome and stop the sound; the reveal takes over. */
	function record(correct: boolean) {
		if (!exercise || verdict !== null) return;
		silence();
		verdict = correct;
		results = [
			...results,
			{
				exerciseId: exercise.id,
				kind: exercise.kind,
				correct,
				ms: Math.round(performance.now() - startedAt),
				unitId: exercise.unitId,
				cardId: exercise.cardId,
			},
		];
	}

	function advance() {
		if (!session) return;
		silence();
		if (index + 1 >= session.exercises.length) {
			finishSession();
			return;
		}
		index += 1;
		resetRound();
		startedAt = performance.now();
		const next = session.exercises[index];
		if (next) sound(next);
	}

	/** Persist both facets: theory SRS and the shared ear skill map. */
	function finishSession() {
		silence();
		const now = Date.now();

		saveCardStates(applyResultsToCards(loadCardStates(), results, now));

		const tallies = tallyEarResults(results);
		const coach = tallies.length > 0 ? applyEarTallies(loadCoachState(), tallies, undefined, now) : loadCoachState();
		if (tallies.length > 0) saveCoachState(coach);
		const map = skillMapProgress(coach);
		earProgress = { total: map.total, earMastered: map.earMastered };

		phase = 'results';
	}

	function quit() {
		silence();
		// A half-finished run still taught something — keep what was answered.
		if (results.length > 0) finishSession();
		else phase = 'start';
	}

	// ─── Answer handlers, one per input.type ────────────────────

	function answerChoice(i: number) {
		if (!exercise || verdict !== null) return;
		chosenIndex = i;
		record(gradeChoice(exercise, i));
	}

	function answerSing(sungMidi: number[]) {
		if (!exercise) return;
		record(gradeSing(exercise, sungMidi));
	}

	function answerNotes(pcs: number[]) {
		if (!exercise) return;
		record(gradeNotes(exercise, pcs));
	}

	function answerTaps(beatTimesMs: number[], tapTimesMs: number[]) {
		if (!exercise || exercise.input.type !== 'tap') return;
		const score = gradeTaps(beatTimesMs, tapTimesMs, exercise.input.toleranceMs);
		tapScore = score;
		record(score.correct);
	}

	// ─── Display helpers ────────────────────────────────────────

	const resultsVerdictKey = $derived.by(() => {
		if (!summary) return 'togo.results_mixed';
		if (summary.ratio >= 1) return 'togo.results_perfect';
		if (summary.ratio >= 0.75) return 'togo.results_good';
		if (summary.ratio >= 0.4) return 'togo.results_mixed';
		return 'togo.results_rough';
	});

	/** Which disciplines are runnable right now, and why not if they aren't. */
	const kindAvailability = $derived(
		ALL_TOGO_KINDS.map((kind) => {
			if (kind === 'theory') return { kind, available: true, noteKey: 'togo.silent_ok' };
			if (kind === 'sing') {
				return {
					kind,
					available: caps.audio && caps.mic,
					noteKey: caps.mic ? 'togo.needs_mic' : 'togo.mic_off',
				};
			}
			return { kind, available: caps.audio, noteKey: 'togo.needs_audio' };
		}),
	);

	function tapVerdictKey(score: TapScore): string {
		if (score.correct && Math.abs(score.meanOffsetMs) < 40) return 'togo.tap_locked';
		return score.meanOffsetMs < 0 ? 'togo.tap_rushing' : 'togo.tap_dragging';
	}

	onDestroy(silence);
</script>

<svelte:head>
	<title>{t('togo.title')} — jazzchords.app</title>
	<meta name="description" content={t('togo.subtitle')} />
</svelte:head>

<div class="mx-auto w-full max-w-xl px-4 py-6 pb-24">
	<!-- ═══ Start ═══════════════════════════════════════════════ -->
	{#if phase === 'start'}
		<header class="mb-6">
			<a
				href="/train"
				class="mb-4 inline-flex items-center gap-1.5 text-[var(--text-sm)] text-[var(--text-muted)] transition hover:text-[var(--text)]"
			>
				<ArrowLeft size={16} aria-hidden="true" />
				{t('togo.back_to_train')}
			</a>
			<h1 class="flex items-center gap-2.5 text-[var(--text-2xl)] font-bold text-[var(--text)]">
				<Ear size={26} aria-hidden="true" />
				{t('togo.title')}
			</h1>
			<p class="mt-1 text-[var(--text-base)] text-[var(--text-muted)]">{t('togo.subtitle')}</p>
			<p class="mt-3 text-[var(--text-sm)] leading-relaxed text-[var(--text-muted)]">{t('togo.intro')}</p>
		</header>

		{#if !caps.audio}
			<p class="mb-4 rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg-card)] p-3 text-[var(--text-sm)] text-[var(--text-muted)]">
				{t('togo.audio_off')}
			</p>
		{:else if !caps.mic}
			<p class="mb-4 rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg-card)] p-3 text-[var(--text-sm)] text-[var(--text-muted)]">
				{t('togo.mic_off')}
			</p>
		{/if}

		<!-- Hero: the mixed session -->
		<button
			type="button"
			onclick={() => begin()}
			class="flex w-full items-center gap-4 rounded-2xl bg-[var(--primary)] px-5 py-4 text-left text-white shadow-lg transition hover:brightness-105 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--bg)]"
		>
			<span class="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-white/20" aria-hidden="true">
				<Play size={26} fill="currentColor" />
			</span>
			<span class="min-w-0 flex-1">
				<span class="block text-lg font-bold">{t('togo.start')}</span>
				<span class="mt-0.5 block text-sm text-white/85">{t('togo.start_sub')}</span>
			</span>
		</button>

		<div class="my-5 flex items-center gap-3">
			<span class="h-px flex-1 bg-[var(--border)]"></span>
			<span class="text-xs font-medium uppercase tracking-[0.06em] text-[var(--text-muted)]">{t('togo.pick_one')}</span>
			<span class="h-px flex-1 bg-[var(--border)]"></span>
		</div>

		<!-- The seven disciplines -->
		<div class="grid grid-cols-1 gap-2.5 sm:grid-cols-2">
			{#each kindAvailability as k (k.kind)}
				<button
					type="button"
					onclick={() => begin(k.kind)}
					disabled={!k.available}
					class="min-h-[var(--tap-min)] rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-left transition hover:border-[var(--primary)]/50 hover:bg-[var(--bg-card-hover)] disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:border-[var(--border)]"
				>
					<div class="text-[var(--text-base)] font-semibold text-[var(--text)]">{t(`togo.kind.${k.kind}`)}</div>
					<div class="mt-0.5 text-[var(--text-sm)] text-[var(--text-muted)]">{t(`togo.kind_desc.${k.kind}`)}</div>
					{#if !k.available}
						<div class="mt-1.5 text-[var(--text-xs)] uppercase tracking-wide text-[var(--text-muted)]">{t(k.noteKey)}</div>
					{/if}
				</button>
			{/each}
		</div>

	<!-- ═══ Run ═════════════════════════════════════════════════ -->
	{:else if phase === 'run' && exercise && session}
		<!-- Progress -->
		<div class="mb-5">
			<div class="mb-2 flex items-center justify-between">
				<span class="text-[var(--text-sm)] font-medium text-[var(--text-muted)]">
					{t('togo.round', { current: index + 1, total: session.exercises.length })}
				</span>
				<button
					type="button"
					onclick={quit}
					class="inline-flex items-center gap-1 text-[var(--text-sm)] text-[var(--text-muted)] transition hover:text-[var(--text)]"
				>
					<X size={15} aria-hidden="true" />
					{t('togo.quit')}
				</button>
			</div>
			<div class="h-1.5 w-full overflow-hidden rounded-full bg-[var(--border)]">
				<div
					class="h-full rounded-full bg-[var(--primary)] transition-[width] duration-300"
					style="width: {((index + (verdict !== null ? 1 : 0)) / session.exercises.length) * 100}%"
				></div>
			</div>
		</div>

		<!-- Prompt -->
		<div class="mb-5 text-center">
			<div class="text-[var(--text-xs)] uppercase tracking-[0.08em] text-[var(--text-muted)]">
				{t(`togo.kind.${exercise.kind}`)}
			</div>
			<h2 class="mt-1.5 text-[var(--text-xl)] font-semibold leading-snug text-[var(--text)]">
				{t(exercise.promptKey, exercise.promptParams)}
			</h2>
		</div>

		<!-- Replay: only where there is something to hear again -->
		{#if exercise.play.type === 'chord' || exercise.play.type === 'sequence' || exercise.play.type === 'chords' || exercise.play.type === 'drone'}
			<div class="mb-5 flex justify-center">
				<button
					type="button"
					onclick={() => sound(exercise)}
					disabled={!caps.audio}
					class="inline-flex min-h-[var(--tap-min)] items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--bg-card)] px-5 font-medium text-[var(--text)] transition hover:border-[var(--primary)]/50 disabled:opacity-40"
				>
					<Play size={18} aria-hidden="true" />
					{playing ? t('togo.listen') : t('togo.replay')}
				</button>
			</div>
		{/if}

		<!-- Input — generic on input.type -->
		{#if exercise.input.type === 'choice'}
			<div class="flex flex-col gap-2.5">
				{#each exercise.options as option, i (option + i)}
					<button
						type="button"
						onclick={() => answerChoice(i)}
						disabled={verdict !== null}
						class="min-h-14 w-full rounded-[var(--radius)] border-2 px-4 py-3 text-[var(--text-lg)] font-medium transition
						{verdict === null
							? 'border-[var(--border)] bg-[var(--bg-card)] text-[var(--text)] hover:border-[var(--primary)] hover:bg-[var(--bg-card-hover)]'
							: i === exercise.answerIndex
								? 'border-[var(--accent-green)] bg-[var(--accent-green)]/15 text-[var(--text)]'
								: i === chosenIndex
									? 'border-[var(--accent-red)] bg-[var(--accent-red)]/15 text-[var(--text)]'
									: 'border-[var(--border)] bg-[var(--bg-card)] text-[var(--text-muted)] opacity-60'}"
					>
						{option}
					</button>
				{/each}
			</div>
		{:else if exercise.input.type === 'sing'}
			{#if verdict === null}
				<SingInput onanswer={answerSing} />
			{/if}
		{:else if exercise.input.type === 'tap'}
			{#if verdict === null}
				{#key exercise.id}
					<TapInput {exercise} onanswer={answerTaps} />
				{/key}
			{/if}
		{:else if exercise.input.type === 'notes'}
			{#if verdict === null}
				{#key exercise.id}
					<NotesInput onanswer={answerNotes} />
				{/key}
			{/if}
		{/if}

		<!-- Reveal -->
		{#if verdict !== null}
			<div
				class="mt-5 rounded-[var(--radius-lg)] border p-4 text-center
				{verdict
					? 'border-[var(--accent-green)]/50 bg-[var(--accent-green)]/10'
					: 'border-[var(--accent-red)]/50 bg-[var(--accent-red)]/10'}"
			>
				<div class="flex items-center justify-center gap-2 text-[var(--text-lg)] font-semibold text-[var(--text)]">
					{#if verdict}<Check size={20} aria-hidden="true" />{:else}<X size={20} aria-hidden="true" />{/if}
					{verdict ? t('togo.reveal_correct') : t('togo.reveal_wrong')}
				</div>
				<div class="mt-1 text-[var(--text-base)] text-[var(--text-muted)]">
					{t('togo.answer_was', { answer: exercise.answerLabel })}
				</div>
				{#if tapScore}
					<div class="mt-2 text-[var(--text-sm)] text-[var(--text-muted)]">
						{t('togo.tap_score', { hits: tapScore.hits, expected: tapScore.expected })}
						<span class="mx-1">·</span>
						{t(tapVerdictKey(tapScore))}
					</div>
				{/if}
			</div>

			<button
				type="button"
				onclick={advance}
				class="mt-4 min-h-14 w-full rounded-[var(--radius)] bg-[var(--primary)] px-5 font-semibold text-white shadow-[var(--shadow-md)] transition hover:brightness-105"
			>
				{index + 1 >= session.exercises.length ? t('togo.finish') : t('togo.next')}
			</button>
		{/if}

	<!-- ═══ Results ═════════════════════════════════════════════ -->
	{:else if phase === 'results' && summary}
		<header class="mb-6 text-center">
			<h1 class="text-[var(--text-2xl)] font-bold text-[var(--text)]">{t('togo.results_title')}</h1>
			<p class="mt-1.5 text-[var(--text-base)] text-[var(--text-muted)]">{t(resultsVerdictKey)}</p>
		</header>

		<div class="mb-5 grid grid-cols-2 gap-3">
			<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
				<div class="text-[var(--text-xs)] uppercase tracking-wide text-[var(--text-muted)]">{t('togo.results_accuracy')}</div>
				<div class="mt-1 text-[var(--text-2xl)] font-bold text-[var(--text)]">{Math.round(summary.ratio * 100)}%</div>
				<div class="mt-0.5 text-[var(--text-sm)] text-[var(--text-muted)]">
					{t('togo.results_score', { correct: summary.correct, total: summary.total })}
				</div>
			</div>
			<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
				<div class="text-[var(--text-xs)] uppercase tracking-wide text-[var(--text-muted)]">{t('togo.results_avg')}</div>
				<div class="mt-1 text-[var(--text-2xl)] font-bold text-[var(--text)]">{(summary.avgMs / 1000).toFixed(1)}s</div>
			</div>
		</div>

		<!-- Per-discipline breakdown -->
		<h2 class="mb-2 text-[var(--text-sm)] font-semibold uppercase tracking-wide text-[var(--text-muted)]">
			{t('togo.results_breakdown')}
		</h2>
		<div class="mb-5 flex flex-col gap-2">
			{#each Object.entries(summary.byKind) as [kind, b] (kind)}
				<div class="flex items-center gap-3 rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg-card)] px-4 py-3">
					<span class="flex-1 text-[var(--text-base)] text-[var(--text)]">{t(`togo.kind.${kind}`)}</span>
					<span class="h-1.5 w-20 overflow-hidden rounded-full bg-[var(--border)]" aria-hidden="true">
						<span
							class="block h-full rounded-full bg-[var(--primary)]"
							style="width: {(b.correct / Math.max(1, b.total)) * 100}%"
						></span>
					</span>
					<span class="w-12 text-right text-[var(--text-sm)] font-medium tabular-nums text-[var(--text-muted)]">
						{b.correct}/{b.total}
					</span>
				</div>
			{/each}
		</div>

		{#if earProgress}
			<p class="mb-5 text-center text-[var(--text-sm)] text-[var(--text-muted)]">
				{t('togo.ear_progress', { ear: earProgress.earMastered, total: earProgress.total })}
			</p>
		{/if}

		<div class="flex gap-2.5">
			<button
				type="button"
				onclick={() => begin()}
				class="inline-flex min-h-14 flex-[2] items-center justify-center gap-2 rounded-[var(--radius)] bg-[var(--primary)] px-5 font-semibold text-white shadow-[var(--shadow-md)] transition hover:brightness-105"
			>
				<RotateCcw size={18} aria-hidden="true" />
				{t('togo.again')}
			</button>
			<button
				type="button"
				onclick={() => (phase = 'start')}
				class="min-h-14 flex-1 rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg-card)] px-5 font-medium text-[var(--text)] transition hover:border-[var(--primary)]/50"
			>
				{t('togo.done')}
			</button>
		</div>
	{/if}
</div>
