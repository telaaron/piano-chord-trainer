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
		FREE_TOGO_KINDS,
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
		unlockAudio,
		setSoundPreset,
	} from '$lib/services/audio';
	import SingInput from '$lib/components/togo/SingInput.svelte';
	import TapInput from '$lib/components/togo/TapInput.svelte';
	import NotesInput from '$lib/components/togo/NotesInput.svelte';
	import UpgradeSheet from '$lib/components/UpgradeSheet.svelte';
	import { canUse } from '$lib/services/subscription-store.svelte';
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
	/** Studio offer, opened by a locked discipline row. */
	let upgradeOpen = $state(false);
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
			try {
				await playChord(p.notes, '1n');
			} finally {
				playing = false;
			}
			return;
		}

		if (p.type === 'sequence') {
			// Own setTimeout chain rather than playArpeggio: the engine's step is a
			// musical value we must honour exactly, and a progression's flat note
			// stream needs each note in its own slot, not re-octaved as an arpeggio.
			playing = true;
			// Warm the audio path so the first note isn't late.
			try {
				await playNote(withOctave(p.notes[0]), '8n');
			} catch {
				playing = false;
				return;
			}
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
			try {
				await playChord(p.chords[0], '2n');
			} catch {
				playing = false;
				return;
			}
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
			playing = true;
			try {
				await startDrone(p.note);
			} finally {
				playing = false;
			}
			return;
		}

		// 'pulse' is owned by TapInput (it needs the beat callback); 'silent' is silent.
	}

	// ─── Session lifecycle ──────────────────────────────────────

	function begin(only?: ToGoKind) {
		// FIRST, before any other work: browsers only unlock audio while the
		// click's activation is still live, and the lazy Tone.js import would
		// otherwise burn it — leaving the whole session silent.
		unlockAudio();
		// To-Go is used on the move: the piano preset streams 17 samples from a
		// CDN, so use a synthesised voice that needs no network.
		setSoundPreset('electric-piano');
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
				// A mixed session must not deal disciplines the tier doesn't include.
				allow: canUse('togo-full') ? undefined : FREE_TOGO_KINDS,
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
			void sound(built.exercises[0]).catch(() => {});
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
		if (next) void sound(next).catch(() => {});
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

	/**
	 * Which disciplines are runnable right now, and why not if they aren't.
	 *
	 * Two independent reasons a row can be closed: the device can't do it
	 * (no sound, no mic) or the tier doesn't include it. They're kept apart
	 * because they need different answers — "turn your sound on" is a fix the
	 * user can make, "this is Studio" is an offer. A discipline the device
	 * can't run is never sold as an upgrade.
	 */
	const kindAvailability = $derived(
		ALL_TOGO_KINDS.map((kind) => {
			const locked = !FREE_TOGO_KINDS.includes(kind) && !canUse('togo-full');
			const base =
				kind === 'theory'
					? { available: true, noteKey: 'togo.silent_ok' }
					: kind === 'sing'
						? {
								available: caps.audio && caps.mic,
								noteKey: caps.mic ? 'togo.needs_mic' : 'togo.mic_off',
							}
						: { available: caps.audio, noteKey: 'togo.needs_audio' };
			// Device problems win: fix what's fixable before offering an upgrade.
			if (!base.available) return { kind, ...base, locked: false };
			return {
				kind,
				available: !locked,
				noteKey: locked ? 'togo.studio_only' : base.noteKey,
				locked,
			};
		}),
	);

	function tapVerdictKey(score: TapScore): string {
		if (score.correct && Math.abs(score.meanOffsetMs) < 40) return 'togo.tap_locked';
		return score.meanOffsetMs < 0 ? 'togo.tap_rushing' : 'togo.tap_dragging';
	}

	// ─── Editorial framing ──────────────────────────────────────
	// The seven disciplines are printed as a numbered running order, the way
	// the rest of the app sets a contents list. Roman numerals rather than
	// digits: these are movements of one programme, not a ranked list.
	const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'] as const;

	/**
	 * The rehearsal mark for the round in play. Eight rounds, letters A–H —
	 * the same alphabet the landing page uses to number its sections, so a
	 * player who has seen one page reads the other without being told.
	 */
	const roundMark = $derived(String.fromCharCode(65 + (index % 26)));

	/**
	 * Which input the round wants, as a printed plate line. The engine drives
	 * rendering off `input.type`; this only names it for the reader.
	 */
	const inputNoteKey = $derived.by(() => {
		switch (exercise?.input.type) {
			case 'choice':
				return 'togo.mode_choice';
			case 'sing':
				return 'togo.mode_sing';
			case 'tap':
				return 'togo.mode_tap';
			case 'notes':
				return 'togo.mode_notes';
			default:
				return '';
		}
	});

	onDestroy(silence);
</script>

<svelte:head>
	<title>{t('togo.title')} — jazzchords.app</title>
	<meta name="description" content={t('togo.subtitle')} />
</svelte:head>

<div class="edi shell">
	<!-- ═══ Start ═══════════════════════════════════════════════ -->
	{#if phase === 'start'}
		<header class="head">
			<a href="/train" class="back">
				<ArrowLeft size={15} aria-hidden="true" />
				{t('togo.back_to_train')}
			</a>
			<p class="eyebrow">{t('togo.entry')}</p>
			<h1 class="h1">
				<Ear size={26} aria-hidden="true" />
				{t('togo.title')}
			</h1>
			<!-- The subtitle is the deck, set in the display italic; the intro is
			     the body under it. Mono uppercase (the eyebrow) cannot carry a
			     sentence this long — it took two shouting lines. -->
			<p class="deck">{t('togo.subtitle')}</p>
			<p class="lede">{t('togo.intro')}</p>
		</header>

		{#if !caps.audio}
			<p class="notice">{t('togo.audio_off')}</p>
		{:else if !caps.mic}
			<p class="notice">{t('togo.mic_off')}</p>
		{/if}

		<!-- The one filled action: the mixed session. -->
		<button type="button" onclick={() => begin()} class="btn btn-stamp start">
			<Play size={20} fill="currentColor" aria-hidden="true" />
			<span class="start-txt">
				<span class="start-t">{t('togo.start')}</span>
				<span class="start-s">{t('togo.start_sub')}</span>
			</span>
		</button>

		<!-- The seven disciplines, as a printed running order. -->
		<p class="eyebrow blue rule-head">{t('togo.pick_one')}</p>
		<ol class="contents ruled">
			{#each kindAvailability as k, i (k.kind)}
				<li class="disc-row" class:off={!k.available}>
					<!-- A Studio-locked row stays pressable and opens the offer; a row the
					     device can't run stays disabled, because there is nothing to sell. -->
					<button
						type="button"
						onclick={() => (k.locked ? (upgradeOpen = true) : begin(k.kind))}
						disabled={!k.available && !k.locked}
						class="disc-btn"
					>
						<span class="no roman">{ROMAN[i] ?? String(i + 1)}</span>
						<span class="row-txt">
							<span class="ttl">{t(`togo.kind.${k.kind}`)}</span>
							<span class="dsc">{t(`togo.kind_desc.${k.kind}`)}</span>
						</span>
						<span class="disc-note plate">{k.available ? t('togo.go') : t(k.noteKey)}</span>
					</button>
				</li>
			{/each}
		</ol>

	<!-- ═══ Run ═════════════════════════════════════════════════ -->
	{:else if phase === 'run' && exercise && session}
		<!-- The round, framed as a plate. Everything the player needs to know
		     about WHERE they are sits in the head; the question sits in the body. -->
		<section class="plate-frame">
			<div class="plate-head">
				<span class="rehearsal">{roundMark}</span>
				<span class="live-dot" aria-hidden="true"></span>
				<span class="live-tag">{t(`togo.kind.${exercise.kind}`)}</span>
				<span class="plate run-count">
					{t('togo.round', { current: index + 1, total: session.exercises.length })}
				</span>
				<button type="button" onclick={quit} class="quit">
					<X size={14} aria-hidden="true" />
					{t('togo.quit')}
				</button>
			</div>

			<div class="rail" aria-hidden="true">
				<span
					class="rail-fill"
					style="width: {((index + (verdict !== null ? 1 : 0)) / session.exercises.length) * 100}%"
				></span>
			</div>

			<div class="plate-body">
				<!-- The question. On the interval drills the direction lives in this
				     line, so it is set large and in the display face — a player who
				     skims it answers the wrong exercise. -->
				<h2 class="prompt">{t(exercise.promptKey, exercise.promptParams)}</h2>
				{#if inputNoteKey}
					<p class="plate prompt-mode">{t(inputNoteKey)}</p>
				{/if}

				<!-- Replay: only where there is something to hear again -->
				{#if exercise.play.type === 'chord' || exercise.play.type === 'sequence' || exercise.play.type === 'chords' || exercise.play.type === 'drone'}
					<div class="replay-row">
						<button
							type="button"
							onclick={() => void sound(exercise).catch(() => {})}
							disabled={!caps.audio}
							class="replay"
						>
							<Play size={16} aria-hidden="true" />
							{playing ? t('togo.listen') : t('togo.replay')}
						</button>
					</div>
				{/if}

				<!-- Input — generic on input.type -->
				{#if exercise.input.type === 'choice'}
					<div class="opts">
						{#each exercise.options as option, i (option + i)}
							<button
								type="button"
								onclick={() => answerChoice(i)}
								disabled={verdict !== null}
								class="opt"
								class:right={verdict !== null && i === exercise.answerIndex}
								class:wrong={verdict !== null && i === chosenIndex && i !== exercise.answerIndex}
								class:spent={verdict !== null && i !== exercise.answerIndex && i !== chosenIndex}
							>
								<span class="opt-txt">{option}</span>
								{#if verdict !== null && i === exercise.answerIndex}
									<Check size={16} aria-hidden="true" />
								{:else if verdict !== null && i === chosenIndex}
									<X size={16} aria-hidden="true" />
								{/if}
							</button>
						{/each}
					</div>
				{:else if exercise.input.type === 'sing'}
					{#if verdict === null}
						<div class="input-slot"><SingInput onanswer={answerSing} /></div>
					{/if}
				{:else if exercise.input.type === 'tap'}
					{#if verdict === null}
						{#key exercise.id}
							<div class="input-slot"><TapInput {exercise} onanswer={answerTaps} /></div>
						{/key}
					{/if}
				{:else if exercise.input.type === 'notes'}
					{#if verdict === null}
						{#key exercise.id}
							<div class="input-slot"><NotesInput onanswer={answerNotes} /></div>
						{/key}
					{/if}
				{/if}

				<!-- Reveal -->
				{#if verdict !== null}
					<div class="reveal" class:ok={verdict}>
						<span class="reveal-mark" aria-hidden="true">
							{#if verdict}<Check size={15} />{:else}<X size={15} />{/if}
						</span>
						<span class="reveal-txt">
							<span class="reveal-v">{verdict ? t('togo.reveal_correct') : t('togo.reveal_wrong')}</span>
							<span class="reveal-a">{t('togo.answer_was', { answer: exercise.answerLabel })}</span>
							{#if tapScore}
								<span class="reveal-tap">
									{t('togo.tap_score', { hits: tapScore.hits, expected: tapScore.expected })}
									<span class="sep">·</span>
									{t(tapVerdictKey(tapScore))}
								</span>
							{/if}
						</span>
					</div>

					<button type="button" onclick={advance} class="btn btn-stamp wide">
						{index + 1 >= session.exercises.length ? t('togo.finish') : t('togo.next')}
					</button>
				{/if}
			</div>
		</section>

	<!-- ═══ Results ═════════════════════════════════════════════ -->
	{:else if phase === 'results' && summary}
		<header class="head">
			<h1 class="h1">{t('togo.results_title')}</h1>
			<!-- The verdict is a sentence in the teacher's voice — it belongs in the
			     display italic, not shouted in mono uppercase as an eyebrow. -->
			<p class="deck">{t(resultsVerdictKey)}</p>
		</header>

		<div class="ledger">
			<div class="cell">
				<span class="v">{Math.round(summary.ratio * 100)}%</span>
				<span class="l">{t('togo.results_accuracy')}</span>
				<span class="l sub">{t('togo.results_score', { correct: summary.correct, total: summary.total })}</span>
			</div>
			<div class="cell">
				<span class="v">{(summary.avgMs / 1000).toFixed(1)}s</span>
				<span class="l">{t('togo.results_avg')}</span>
			</div>
		</div>

		<!-- Per-discipline breakdown, as a ruled table -->
		<p class="eyebrow blue rule-head">{t('togo.results_breakdown')}</p>
		<ul class="contents ruled">
			{#each Object.entries(summary.byKind) as [kind, b] (kind)}
				<li class="bk-row">
					<span class="bk-name">{t(`togo.kind.${kind}`)}</span>
					<span class="bk-bar" aria-hidden="true">
						<span class="bk-fill" style="width: {(b.correct / Math.max(1, b.total)) * 100}%"></span>
					</span>
					<span class="bk-n">{b.correct}/{b.total}</span>
				</li>
			{/each}
		</ul>

		{#if earProgress}
			<p class="plate ear-note">
				{t('togo.ear_progress', { ear: earProgress.earMastered, total: earProgress.total })}
			</p>
		{/if}

		<div class="fin">
			<button type="button" onclick={() => begin()} class="btn btn-stamp">
				<RotateCcw size={17} aria-hidden="true" />
				{t('togo.again')}
			</button>
			<button type="button" onclick={() => (phase = 'start')} class="btn btn-ghost">{t('togo.done')}</button>
		</div>
	{/if}
</div>

<UpgradeSheet bind:open={upgradeOpen} feature="togo-full" />

<style>
	/* To-Go on the editorial plate. Same vocabulary as the landing page —
	   rehearsal marks, hairline rules, a printed contents list, the display
	   serif for anything that is read rather than scanned — but this is a
	   WORKING screen: the question and the answer buttons stay the loudest
	   things on it, and no rule is allowed to compete with them. */

	.edi {
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		/* AccidentalFit is unicode-range-scoped, so it only ever claims ♭ ♯ ° ø;
		   every other character still comes from the normal stack below it. */
		--font-display-mus: 'AccidentalFit', var(--font-display);
		--font-sans-mus: 'AccidentalFit', var(--font-sans);
		font-family: var(--font-sans-mus);
	}

	.shell {
		width: 100%;
		max-width: 40rem;
		margin: 0 auto;
		padding: 1.75rem 1.25rem 6rem;
	}
	@media (min-width: 700px) {
		.shell { padding: 2.75rem 2rem 6rem; }
	}

	/* ── Editorial primitives ─────────────────────────────────── */

	.eyebrow {
		display: flex;
		align-items: center;
		gap: 0.625rem;
		margin: 0;
		font-family: var(--font-mono);
		font-size: 0.66rem;
		font-weight: 600;
		letter-spacing: 0.19em;
		text-transform: uppercase;
		color: var(--primary);
	}
	.eyebrow::after {
		content: '';
		flex: 1;
		min-width: 1rem;
		height: 1px;
		background: currentColor;
		opacity: 0.32;
	}
	.eyebrow.blue { color: var(--ink-blue); }
	.rule-head { margin: 2.25rem 0 0.25rem; }

	.plate {
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	.rehearsal {
		display: inline-grid;
		place-items: center;
		flex: none;
		min-width: 1.45rem;
		height: 1.45rem;
		padding: 0 0.35rem;
		border: 1.5px solid var(--text);
		font-family: var(--font-mono);
		font-size: 0.68rem;
		font-weight: 700;
		color: var(--text);
	}

	/* ── Buttons ──────────────────────────────────────────────── */

	.btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.55rem;
		min-height: var(--tap-min);
		padding: 0 1.35rem;
		border-radius: var(--radius-sm);
		border: 1.5px solid var(--text);
		background: var(--text);
		color: var(--bg);
		font-family: inherit;
		font-size: 0.94rem;
		font-weight: 600;
		cursor: pointer;
		transition: transform 0.12s ease-out, background-color 0.12s, border-color 0.12s;
	}
	.btn:hover { transform: translateY(-1px); }
	.btn:active { transform: none; }

	/* The one filled action. Amber is the system's live ink and a start is
	   exactly that. Fixed values in BOTH themes for the same reason the
	   landing page fixes them: near-black on bright amber measures 9.65:1
	   either way, and the invitation to press should not change character. */
	.btn-stamp {
		background: var(--stamp);
		border-color: var(--stamp);
		color: var(--stamp-ink);
		font-weight: 700;
	}
	.btn-stamp:hover {
		background: var(--stamp-hover);
		border-color: var(--stamp-hover);
	}
	/* On diazo paper the amber fill separates from the ground at only 1.75:1,
	   so the button's SHAPE goes soft though its label is fine. An ink edge
	   gives it back its cut. Dark ground needs none. */
	:global([data-theme='light']) .btn-stamp {
		border-color: var(--stamp-ink);
	}

	.btn-ghost {
		background: transparent;
		border-color: transparent;
		color: var(--text-muted);
		font-weight: 500;
		padding: 0 0.85rem;
		text-underline-offset: 4px;
		text-decoration: underline;
		text-decoration-color: var(--border-hover);
		text-decoration-thickness: 1px;
	}
	.btn-ghost:hover {
		color: var(--text);
		text-decoration-color: var(--accent-amber);
		background: transparent;
	}

	/* ── Start ────────────────────────────────────────────────── */

	.head { margin-bottom: 1.75rem; }

	.back {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		margin-bottom: 1.5rem;
		font-size: 0.86rem;
		color: var(--text-muted);
		text-decoration: underline;
		text-decoration-color: var(--border-hover);
		text-underline-offset: 4px;
		transition: color 0.12s;
	}
	.back:hover { color: var(--text); text-decoration-color: var(--accent-amber); }

	.h1 {
		display: flex;
		align-items: center;
		gap: 0.7rem;
		margin: 0.85rem 0 0;
		font-family: var(--font-display-mus);
		font-size: clamp(1.9rem, 6vw, 2.6rem);
		font-weight: 600;
		line-height: 1.1;
		letter-spacing: -0.022em;
		color: var(--text);
	}
	.h1 :global(svg) { flex: none; color: var(--ink-blue); }

	.deck {
		margin: 0.85rem 0 0;
		max-width: 46ch;
		font-family: var(--font-display-mus);
		font-size: 1.06rem;
		font-style: italic;
		line-height: 1.45;
		color: var(--text-muted);
	}

	.lede {
		margin: 0.75rem 0 0;
		max-width: 52ch;
		font-size: 0.98rem;
		line-height: 1.62;
		color: var(--text-muted);
	}

	.notice {
		margin: 0 0 1.25rem;
		padding-left: 0.9rem;
		border-left: 2px solid var(--ink-blue);
		font-family: var(--font-display-mus);
		font-size: 0.95rem;
		font-style: italic;
		line-height: 1.5;
		color: var(--text-muted);
	}

	.start {
		width: 100%;
		min-height: 3.6rem;
		justify-content: flex-start;
		gap: 0.9rem;
		padding: 0.7rem 1.25rem;
		text-align: left;
	}
	.start-txt { display: block; min-width: 0; }
	.start-t {
		display: block;
		font-family: var(--font-display-mus);
		font-size: 1.12rem;
		font-weight: 700;
		line-height: 1.2;
	}
	.start-s {
		display: block;
		margin-top: 0.12rem;
		font-size: 0.78rem;
		font-weight: 500;
		line-height: 1.35;
		opacity: 0.82;
	}

	/* ── The printed running order ────────────────────────────── */

	.contents {
		list-style: none;
		margin: 0;
		padding: 0;
	}
	.contents.ruled { border-top: 1px solid var(--border); }

	.disc-row { border-bottom: 1px solid var(--rule-soft); }
	.disc-row.off { opacity: 0.45; }

	.disc-btn {
		display: grid;
		grid-template-columns: auto minmax(0, 1fr) auto;
		gap: 0.9rem;
		align-items: baseline;
		width: 100%;
		min-height: var(--tap-min);
		padding: 0.85rem 0.25rem;
		border: 0;
		background: transparent;
		font-family: inherit;
		text-align: left;
		cursor: pointer;
		transition: background-color 0.12s;
	}
	.disc-btn:hover:not(:disabled) { background: var(--bg-card); }
	.disc-btn:disabled { cursor: not-allowed; }
	.disc-btn:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: -2px;
	}

	.no {
		font-family: var(--font-mono);
		font-size: 0.7rem;
		letter-spacing: 0.08em;
		color: var(--text-dim);
	}
	.no.roman { min-width: 1.75rem; }

	.row-txt { min-width: 0; }
	.ttl {
		display: block;
		font-family: var(--font-display-mus);
		font-size: 1.06rem;
		font-weight: 600;
		color: var(--text);
	}
	.dsc {
		display: block;
		margin-top: 0.15rem;
		font-size: 0.88rem;
		line-height: 1.5;
		color: var(--text-muted);
	}
	.disc-note {
		align-self: center;
		white-space: nowrap;
	}
	.disc-btn:hover:not(:disabled) .disc-note { color: var(--primary); }

	/* ── The round plate ──────────────────────────────────────── */

	.plate-frame {
		border: 1px solid var(--border);
		border-left: 3px solid var(--primary);
		background: var(--bg-card);
		box-shadow: var(--shadow-sm);
	}

	.plate-head {
		display: flex;
		align-items: center;
		gap: 0.6rem;
		padding: 0.6rem 0.85rem;
		border-bottom: 1px solid var(--rule-soft);
		background: var(--bg-muted);
	}

	/* Amber pulse = live. The one reserved use, and this round IS live. */
	.live-dot {
		width: 0.45rem;
		height: 0.45rem;
		flex: none;
		border-radius: 50%;
		background: var(--accent-amber);
		animation: pulse 2s ease-out infinite;
	}
	@keyframes pulse {
		0% { box-shadow: 0 0 0 0 color-mix(in srgb, var(--accent-amber) 55%, transparent); }
		70% { box-shadow: 0 0 0 6px transparent; }
		100% { box-shadow: 0 0 0 0 transparent; }
	}
	.live-tag {
		min-width: 0;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		font-family: var(--font-mono);
		font-size: 0.6rem;
		font-weight: 700;
		letter-spacing: 0.15em;
		text-transform: uppercase;
		color: var(--accent-amber);
	}
	.run-count {
		margin-left: auto;
		flex: none;
		white-space: nowrap;
	}

	.quit {
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		flex: none;
		padding: 0.3rem 0.1rem 0.3rem 0.5rem;
		border: 0;
		background: transparent;
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
		cursor: pointer;
		transition: color 0.12s;
	}
	.quit:hover { color: var(--primary); }

	/* A hairline progress rail rather than a rounded bar — it reports, it
	   does not decorate. */
	.rail {
		height: 2px;
		background: var(--border);
	}
	.rail-fill {
		display: block;
		height: 100%;
		background: var(--primary);
		transition: width 0.3s ease;
	}

	.plate-body { padding: 1.5rem 1.1rem 1.35rem; }
	@media (min-width: 560px) {
		.plate-body { padding: 1.75rem 1.6rem 1.6rem; }
	}

	/* The question. This is the drill — it is the largest thing in the frame,
	   in the display serif, and on the interval exercises it carries the
	   direction ("Aufwärts — wie weit?"), which a player must not skim past. */
	.prompt {
		margin: 0;
		font-family: var(--font-display-mus);
		font-size: clamp(1.45rem, 5.4vw, 1.95rem);
		font-weight: 600;
		line-height: 1.22;
		letter-spacing: -0.015em;
		text-wrap: balance;
		color: var(--text);
	}
	.prompt-mode { margin: 0.65rem 0 0; }

	.replay-row { margin-top: 1.15rem; }
	.replay {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		min-height: var(--tap-min);
		padding: 0 1.05rem;
		border: 1px solid var(--border-hover);
		border-radius: var(--radius-sm);
		background: transparent;
		font-family: inherit;
		font-size: 0.88rem;
		font-weight: 500;
		color: var(--text);
		cursor: pointer;
		transition: border-color 0.12s, color 0.12s;
	}
	.replay:hover:not(:disabled) { border-color: var(--accent-amber); color: var(--accent-amber); }
	.replay:disabled { opacity: 0.4; cursor: not-allowed; }

	/* ── Answers ──────────────────────────────────────────────── */

	.opts {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		margin-top: 1.35rem;
	}
	.opt {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		min-height: 3.25rem;
		padding: 0.6rem 1rem;
		border: 1px solid var(--border);
		border-radius: var(--radius-sm);
		background: var(--bg);
		font-family: var(--font-display-mus);
		font-size: 1.14rem;
		font-weight: 600;
		color: var(--text);
		text-align: left;
		cursor: pointer;
		transition: border-color 0.12s, background-color 0.12s;
	}
	.opt-txt { min-width: 0; }
	.opt:hover:not(:disabled) {
		border-color: var(--text);
		background: var(--bg-card-hover);
	}
	.opt:disabled { cursor: default; }
	.opt.right {
		border-color: var(--accent-green);
		border-width: 2px;
		padding: calc(0.6rem - 1px) calc(1rem - 1px);
		background: color-mix(in srgb, var(--accent-green) 12%, transparent);
		color: var(--text);
	}
	.opt.right :global(svg) { color: var(--accent-green); flex: none; }
	.opt.wrong {
		border-color: var(--accent-red);
		border-width: 2px;
		padding: calc(0.6rem - 1px) calc(1rem - 1px);
		background: color-mix(in srgb, var(--accent-red) 10%, transparent);
	}
	.opt.wrong :global(svg) { color: var(--accent-red); flex: none; }
	.opt.spent { opacity: 0.45; }

	.input-slot { margin-top: 1.35rem; }

	/* ── Reveal ───────────────────────────────────────────────── */

	.reveal {
		display: flex;
		align-items: flex-start;
		gap: 0.7rem;
		margin-top: 1.35rem;
		padding-top: 1.1rem;
		border-top: 1px dashed var(--border-hover);
	}
	.reveal-mark {
		display: inline-grid;
		place-items: center;
		flex: none;
		width: 1.5rem;
		height: 1.5rem;
		border-radius: 50%;
		background: color-mix(in srgb, var(--accent-red) 18%, transparent);
		color: var(--accent-red);
	}
	.reveal.ok .reveal-mark {
		background: color-mix(in srgb, var(--accent-green) 18%, transparent);
		color: var(--accent-green);
	}
	.reveal-txt { min-width: 0; }
	.reveal-v {
		display: block;
		font-family: var(--font-display-mus);
		font-size: 1.06rem;
		font-weight: 600;
		line-height: 1.3;
		color: var(--text);
	}
	.reveal-a {
		display: block;
		margin-top: 0.2rem;
		font-size: 0.92rem;
		line-height: 1.5;
		color: var(--text-muted);
	}
	.reveal-tap {
		display: block;
		margin-top: 0.35rem;
		font-family: var(--font-mono);
		font-size: 0.72rem;
		line-height: 1.5;
		color: var(--text-dim);
	}
	.reveal-tap .sep { margin: 0 0.3rem; opacity: 0.5; }

	.wide {
		width: 100%;
		margin-top: 1.35rem;
		min-height: 3.1rem;
		font-size: 1rem;
	}

	/* ── Results ──────────────────────────────────────────────── */

	.ledger {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 1px;
		margin-top: 0.5rem;
		border: 1px solid var(--border);
		background: var(--border);
	}
	.cell {
		display: flex;
		flex-direction: column;
		gap: 0.35rem;
		padding: 1.1rem 1rem;
		background: var(--bg-card);
	}
	.cell .v {
		font-family: var(--font-display-mus);
		font-size: clamp(1.7rem, 6vw, 2.2rem);
		font-weight: 600;
		line-height: 1;
		font-variant-numeric: lining-nums;
		color: var(--text);
	}
	.cell .l {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	.cell .l.sub { letter-spacing: 0.08em; }

	.bk-row {
		display: grid;
		grid-template-columns: minmax(0, 1fr) 5rem auto;
		gap: 0.85rem;
		align-items: center;
		padding: 0.8rem 0.25rem;
		border-bottom: 1px solid var(--rule-soft);
	}
	.bk-name {
		min-width: 0;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		font-family: var(--font-display-mus);
		font-size: 1rem;
		font-weight: 600;
		color: var(--text);
	}
	.bk-bar {
		height: 0.3rem;
		background: var(--border);
	}
	.bk-fill {
		display: block;
		height: 100%;
		background: var(--primary);
	}
	.bk-n {
		font-family: var(--font-mono);
		font-size: 0.78rem;
		font-variant-numeric: lining-nums tabular-nums;
		color: var(--text-muted);
	}

	.ear-note {
		margin: 1.35rem 0 0;
		line-height: 1.7;
	}

	.fin {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.7rem;
		margin-top: 1.75rem;
		padding-top: 1.35rem;
		border-top: 2px solid var(--text);
	}

	@media (prefers-reduced-motion: reduce) {
		.btn, .rail-fill { transition: none; }
		.btn:hover { transform: none; }
		.live-dot { animation: none; }
	}
</style>
