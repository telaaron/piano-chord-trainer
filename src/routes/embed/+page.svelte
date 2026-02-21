<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import {
		CHORDS_BY_DIFFICULTY,
		CHORD_NOTATIONS,
		VOICING_LABELS,
		PROGRESSION_LABELS,
		getNotePool,
		getChordNotes,
		getVoicingNotes,
		generateProgression,
		displayToQuality,
		noteToSemitone,
		type VoicingType,
		type Difficulty,
		type ProgressionMode,
		type ChordWithNotes,
	} from '$lib/engine';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import { MidiService, type MidiConnectionState, type MidiDevice, type ChordMatchResult } from '$lib/services/midi';
	import { formatTime } from '$lib/utils/format';
	import { t } from '$lib/i18n';

	// ─── Config ────────────────────────────────────────────────────
	interface EmbedConfig {
		voicing: VoicingType;
		progressionMode: ProgressionMode;
		difficulty: Difficulty;
		chords: number;
		theme: string;
		origin: string; // postMessage target origin
	}

	const PRESET_LABELS: Record<string, string> = {
		'shell-warmup': 'Shell Voicing Warmup',
		'rootless-drill': 'Rootless Voicing Drill',
		'251-advanced': 'ii – V – I Advanced',
		'openstudio-intro': 'Open Studio Intro',
	};

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

	const DIFFICULTY_KEYS: Record<Difficulty, string> = {
		'beginner': 'settings.difficulty_beginner',
		'intermediate': 'settings.difficulty_intermediate',
		'advanced': 'settings.difficulty_advanced',
	};

	const PRESETS: Record<string, Omit<EmbedConfig, 'origin'>> = {
		'shell-warmup': {
			voicing: 'shell',
			progressionMode: '2-5-1',
			difficulty: 'beginner',
			chords: 12,
			theme: 'default',
		},
		'rootless-drill': {
			voicing: 'rootless-a',
			progressionMode: '2-5-1',
			difficulty: 'intermediate',
			chords: 20,
			theme: 'default',
		},
		'251-advanced': {
			voicing: 'rootless-a',
			progressionMode: '2-5-1',
			difficulty: 'advanced',
			chords: 36,
			theme: 'default',
		},
		'openstudio-intro': {
			voicing: 'shell',
			progressionMode: '2-5-1',
			difficulty: 'beginner',
			chords: 16,
			theme: 'openstudio',
		},
	};

	function parseConfig(): EmbedConfig {
		const params = page.url.searchParams;
		const preset = params.get('preset');
		const base: Omit<EmbedConfig, 'origin'> = preset && PRESETS[preset]
			? { ...PRESETS[preset] }
			: { voicing: 'shell', progressionMode: '2-5-1', difficulty: 'intermediate', chords: 20, theme: 'default' };

		return {
			voicing: (params.get('voicing') as VoicingType) || base.voicing,
			progressionMode: (params.get('mode') as ProgressionMode) || base.progressionMode,
			difficulty: (params.get('difficulty') as Difficulty) || base.difficulty,
			chords: parseInt(params.get('chords') || '') || base.chords,
			theme: params.get('theme') || base.theme,
			origin: params.get('origin') || '*',
		};
	}

	const config = parseConfig();
	const presetKey = page.url.searchParams.get('preset') || '';
	const presetLabel = PRESET_LABELS[presetKey] || '';

	// ─── State machine ──────────────────────────────────────────────
	type Screen = 'setup' | 'playing' | 'finished';

	let screen: Screen = $state<Screen>('setup');
	let chordsWithNotes: ChordWithNotes[] = $state([]);
	let currentIdx = $state(0);
	let startTime = $state(0);
	let endTime = $state(0);
	let now = $state(0);
	let timerStarted = $state(false);

	// ─── MIDI ───────────────────────────────────────────────────────
	const midi = new MidiService();
	let midiState: MidiConnectionState = $state('disconnected');
	let midiDevices: MidiDevice[] = $state([]);
	let midiActiveNotes: Set<number> = $state(new Set());
	let midiMatchResult: ChordMatchResult | null = $state(null);
	let midiCorrectCount = $state(0);
	let midiTotalAttempts = $state(0);
	let autoAdvanceTimeout: ReturnType<typeof setTimeout> | null = null;
	const midiHasDevice = $derived(midiDevices.length > 0);

	// ─── Streak tracking ────────────────────────────────────────────
	let streak = $state(0);
	let bestStreak = $state(0);
	let streakGlow = $state(false);
	const STREAK_THRESHOLD = 5;

	const DIFFICULTY_LABELS: Record<Difficulty, string> = {
		beginner: 'Beginner',
		intermediate: 'Intermediate',
		advanced: 'Advanced',
	};

	// ─── Derived ────────────────────────────────────────────────────
	const currentData = $derived(chordsWithNotes[currentIdx] ?? null);
	const totalChords = $derived(chordsWithNotes.length || config.chords);
	const progressPct = $derived(totalChords > 0 ? (currentIdx / totalChords) * 100 : 0);
	const elapsedMs = $derived(
		screen === 'playing' && timerStarted
			? now - startTime
			: endTime > startTime ? endTime - startTime : 0,
	);

	const midiAccuracy = $derived(
		midiTotalAttempts > 0 ? Math.round((midiCorrectCount / midiTotalAttempts) * 100) : 0,
	);

	// Stats for results screen
	const avgMs = $derived(totalChords > 0 ? Math.round((endTime - startTime) / totalChords) : 0);

	// ─── Expected pitch classes (for MIDI coloring in PianoKeyboard) ─
	const expectedPitchClasses = $derived.by(() => {
		if (!currentData) return new Set<number>();
		const set = new Set<number>();
		for (const note of currentData.voicing) {
			const st = noteToSemitone(note);
			if (st !== -1) set.add(st);
		}
		return set;
	});

	// ─── Timer (reactive via $effect) ─────────────────────────────
	$effect(() => {
		if (screen === 'playing' && timerStarted) {
			const handle = setInterval(() => {
				now = Date.now();
			}, 50);
			return () => clearInterval(handle);
		}
	});

	// ─── Chord generation ────────────────────────────────────────────
	function generateChords() {
		const { voicing, progressionMode, difficulty, chords } = config;

		if (progressionMode !== 'random') {
			const result = generateProgression(progressionMode, 'both', 'standard', chords);
			const data: ChordWithNotes[] = [];
			for (const pc of result.chords) {
				const notes = getChordNotes(pc.root, pc.quality, 'both');
				const voicingArr = getVoicingNotes(notes, voicing, pc.root, 'both');
				data.push({ chord: pc.display, root: pc.root, type: pc.quality, notes, voicing: voicingArr });
			}
			chordsWithNotes = data.slice(0, chords);
		} else {
			const available = CHORDS_BY_DIFFICULTY[difficulty];
			const pool = getNotePool('both');
			const data: ChordWithNotes[] = [];
			let last = '';
			for (let i = 0; i < chords; i++) {
				let name = '';
				let attempts = 0;
				do {
					const note = pool[Math.floor(Math.random() * pool.length)];
					const ct = available[Math.floor(Math.random() * available.length)];
					const display = CHORD_NOTATIONS['standard'][ct.display] || ct.display;
					name = `${note}${display}`;
					attempts++;
				} while (name === last && attempts < 50);
				last = name;
				const match = name.match(/^([A-G][#b]?)(.+)$/);
				if (match) {
					const root = match[1];
					const quality = displayToQuality(match[2], 'standard');
					const notes = getChordNotes(root, quality, 'both');
					const voicingArr = getVoicingNotes(notes, voicing, root, 'both');
					data.push({ chord: name, root, type: quality, notes, voicing: voicingArr });
				}
			}
			chordsWithNotes = data;
		}
	}

	// ─── Game logic ──────────────────────────────────────────────────
	function startGame() {
		generateChords();
		currentIdx = 0;
		screen = 'playing';
		timerStarted = false;
		startTime = 0;
		endTime = 0;
		now = 0;
		midiCorrectCount = 0;
		midiTotalAttempts = 0;
		midiMatchResult = null;
		streak = 0;
		bestStreak = 0;
		streakGlow = false;
		midi.releaseAll();
		midi.onNotes(handleMidiNotes);
		postMsg({ type: 'chord-trainer:start', chords: totalChords, voicing: config.voicing, mode: config.progressionMode });
	}

	function beginTimer() {
		timerStarted = true;
		startTime = Date.now();
		now = startTime;
	}

	function nextChord() {
		if (screen !== 'playing') return;
		if (!timerStarted) {
			beginTimer();
			return;
		}
		if (autoAdvanceTimeout) {
			clearTimeout(autoAdvanceTimeout);
			autoAdvanceTimeout = null;
		}
		midiMatchResult = null;
		midi.releaseAll();
		if (currentIdx < totalChords - 1) {
			currentIdx++;
		} else {
			endGame();
		}
	}

	function endGame() {
		endTime = Date.now();
		screen = 'finished';
		if (autoAdvanceTimeout) {
			clearTimeout(autoAdvanceTimeout);
			autoAdvanceTimeout = null;
		}
		postMsg({
			type: 'chord-trainer:end',
			results: {
				totalChords: totalChords,
				totalMs: endTime - startTime,
				avgMs: Math.round((endTime - startTime) / totalChords),
				midiAccuracy: midiAccuracy,
			},
		});
	}

	function resetToSetup() {
		screen = 'setup';
		timerStarted = false;
		if (autoAdvanceTimeout) {
			clearTimeout(autoAdvanceTimeout);
			autoAdvanceTimeout = null;
		}
	}

	// ─── MIDI ───────────────────────────────────────────────────────
	function handleMidiNotes(activeNotes: Set<number>) {
		midiActiveNotes = new Set(activeNotes);
		if (screen !== 'playing' || !currentData) return;

		let result: ChordMatchResult;
		if (config.voicing.startsWith('inversion-') && currentData.voicing.length > 0) {
			result = midi.checkChordWithBass(currentData.voicing, currentData.voicing[0]);
		} else {
			result = midi.checkChordLenient(currentData.voicing);
		}
		midiMatchResult = result;

		if (!timerStarted) beginTimer();

		if (result.correct && activeNotes.size > 0) {
			midiTotalAttempts++;
			midiCorrectCount++;
			streak++;
			if (streak > bestStreak) bestStreak = streak;
			if (streak >= STREAK_THRESHOLD && streak % STREAK_THRESHOLD === 0) {
				streakGlow = true;
				setTimeout(() => { streakGlow = false; }, 1200);
			}
			if (!autoAdvanceTimeout) {
				autoAdvanceTimeout = setTimeout(() => {
					autoAdvanceTimeout = null;
					nextChord();
				}, 400);
			}
		} else if (activeNotes.size > 0 && result.accuracy < 1) {
			const expectedCount = currentData.voicing.length;
			if (activeNotes.size >= expectedCount) {
				midiTotalAttempts++;
				streak = 0;
			}
		}
	}

	// ─── postMessage API ────────────────────────────────────────────
	function postMsg(data: Record<string, unknown>) {
		if (typeof window !== 'undefined') {
			if (window.parent && window.parent !== window) {
				window.parent.postMessage(data, config.origin);
			} else {
				console.log('[chord-trainer] postMessage (no parent frame):', data);
			}
		}
	}

	// ─── Parent→Embed message listener ─────────────────────────
	function handleParentMessage(e: MessageEvent) {
		if (config.origin !== '*' && e.origin !== config.origin) return;
		const msg = e.data;
		if (!msg || typeof msg.type !== 'string') return;

		switch (msg.type) {
			case 'chord-trainer:next':
				nextChord();
				break;
			case 'chord-trainer:restart':
				startGame();
				break;
			case 'chord-trainer:reset':
				resetToSetup();
				break;
			default:
				break;
		}
	}

	// ─── Keyboard shortcuts ─────────────────────────────────────────
	function handleKeydown(e: KeyboardEvent) {
		if (e.code === 'Space' && screen === 'playing') {
			e.preventDefault();
			if (!timerStarted) beginTimer();
			else nextChord();
		}
		if (e.code === 'Escape' && screen === 'playing') {
			e.preventDefault();
			resetToSetup();
		}
	}

	// ─── Mount ──────────────────────────────────────────────────────
	onMount(() => {
		// Apply theme (or auto-detect dark mode for default)
		const themeId = config.theme || 'default';
		if (themeId !== 'default') {
			document.documentElement.setAttribute('data-theme', themeId);
		}

		// MIDI
		midi.onConnection((state) => { midiState = state; });
		midi.onDevices((devices) => { midiDevices = devices; });
		midi.onNotes(handleMidiNotes);
		midi.init();

		// Listen for parent→embed messages
		window.addEventListener('message', handleParentMessage);

		postMsg({ type: 'chord-trainer:ready' });

		return () => {
			// Reset theme to avoid leaking into other routes
			document.documentElement.removeAttribute('data-theme');
			window.removeEventListener('message', handleParentMessage);
			if (autoAdvanceTimeout) clearTimeout(autoAdvanceTimeout);
			midi.destroy();
		};
	});


</script>

<svelte:window onkeydown={handleKeydown} />

<svelte:head>
	<title>Chord Trainer Embed</title>
	<meta name="robots" content="noindex, nofollow" />
</svelte:head>

<main class="embed-widget" aria-label="Chord Trainer Practice Widget">
	<!-- ── Setup Screen ──────────────────────────────────────── -->
	{#if screen === 'setup'}
		<div class="setup-screen">
			<div class="setup-inner">
				<!-- Logo mark -->
				<div class="setup-icon" aria-hidden="true">🎹</div>

				<h1 class="setup-title">{t('embed.setup_title')}</h1>

				{#if presetLabel}
					<p class="setup-preset-label">{presetLabel}</p>
				{/if}

				<div class="setup-meta">
					<span class="meta-badge">{VOICING_LABELS[config.voicing] ?? config.voicing}</span>
					<span class="meta-badge">{PROGRESSION_LABELS[config.progressionMode] ?? config.progressionMode}</span>
					<span class="meta-badge">{config.chords} {t('embed.stat_chords')}</span>
					<span class="meta-badge">{DIFFICULTY_LABELS[config.difficulty]}</span>
				</div>

				{#if midiState === 'connected' && midiHasDevice}
					<p class="setup-midi-status connected">{t('embed.midi_connected')}</p>
				{:else if midiState === 'connecting'}
					<p class="setup-midi-status">{t('embed.connecting')}</p>
				{:else}
					<p class="setup-hint">{@html t('embed.setup_hint')}</p>
				{/if}

				<button class="btn-start" onclick={startGame}>
					{t('embed.start_drill')}
				</button>

				<p class="setup-shortcut">{@html t('embed.or_press_space')}</p>
			</div>
		</div>
	{/if}

	<!-- ── Playing Screen ────────────────────────────────────── -->
	{#if screen === 'playing'}
		<div class="playing-screen">
			<!-- Top bar -->
			<div class="top-bar">
				<div class="top-bar-left">
					<span class="voicing-label">{VOICING_LABELS[config.voicing] ?? config.voicing}</span>
					{#if midiState === 'connected' && midiHasDevice}
						<span class="midi-dot" title="MIDI Connected" aria-label="MIDI Connected">●</span>
					{/if}
				</div>
				<div class="top-bar-center">
					<span class="timer" aria-live="off">{formatTime(elapsedMs)}</span>
				</div>
				<div class="top-bar-right">
					<span class="chord-counter">{currentIdx + 1} / {totalChords}</span>
				</div>
			</div>

			<!-- Progress bar -->
			<div class="progress-track" role="progressbar" aria-valuenow={currentIdx} aria-valuemax={totalChords}>
				<div class="progress-fill" style="width: {progressPct}%"></div>
			</div>

			<!-- Chord display -->
			<div class="chord-area" class:streak-glow={streakGlow}>
				{#if !timerStarted}
					<div class="chord-start-hint">
						<p class="hint-label">{t('embed.ready')}</p>
						<button class="btn-begin" onclick={beginTimer}>{t('embed.begin')}</button>
						<p class="hint-sub">{@html t('embed.or_press_space')}</p>
					</div>
				{:else}
					<div class="chord-display"
						class:chord-correct={midiMatchResult?.correct}
						class:chord-wrong={midiMatchResult && !midiMatchResult.correct && midiActiveNotes.size > 0}>
						<div class="chord-name" aria-live="polite">
							{currentData?.chord ?? ''}
						</div>
						{#if currentData?.voicing && currentData.voicing.length > 0}
							<div class="chord-voicing">{currentData.voicing.join(' – ')}</div>
						{:else if currentData}
							<div class="chord-voicing" style="color: var(--text-dim)">{t('embed.no_voicing')}</div>
						{/if}
						{#if streak >= STREAK_THRESHOLD}
							<div class="streak-badge">{t('embed.streak', { count: streak })}</div>
						{/if}
					</div>
				{/if}
			</div>

			<!-- Piano keyboard -->
			<div class="piano-wrap">
				<PianoKeyboard
					chordData={currentData}
					accidentalPref="both"
					showVoicing={true}
					midiEnabled={midiState === 'connected' && midiHasDevice}
					midiActiveNotes={midiActiveNotes}
					midiExpectedPitchClasses={expectedPitchClasses}
				/>
			</div>

			<!-- Actions -->
			<div class="action-bar">
				<button class="btn-secondary" onclick={resetToSetup} title={t('embed.back_to_setup_title')}>
					{t('embed.back_to_setup')}
				</button>
				{#if timerStarted}
					<button class="btn-next" onclick={nextChord}>
						{currentIdx < totalChords - 1 ? t('embed.next') : t('embed.finish')}
					</button>
				{/if}
			</div>
		</div>
	{/if}

	<!-- ── Finished Screen ────────────────────────────────────── -->
	{#if screen === 'finished'}
		<div class="results-screen">
			<div class="results-inner">
				<div class="results-icon" aria-hidden="true">✓</div>
				<h2 class="results-title">{t('embed.session_complete')}</h2>

				<div class="results-stats">
					<div class="stat">
						<div class="stat-value">{totalChords}</div>
						<div class="stat-label">{t('embed.stat_chords')}</div>
					</div>
					<div class="stat">
						<div class="stat-value">{formatTime(endTime - startTime)}</div>
						<div class="stat-label">{t('embed.stat_total_time')}</div>
					</div>
					<div class="stat">
						<div class="stat-value">{(avgMs / 1000).toFixed(1)}s</div>
						<div class="stat-label">{t('embed.stat_avg')}</div>
					</div>
					{#if midiTotalAttempts > 0}
						<div class="stat">
							<div class="stat-value">{midiAccuracy}%</div>
							<div class="stat-label">{t('embed.stat_accuracy')}</div>
						</div>
					{/if}
					{#if bestStreak >= STREAK_THRESHOLD}
						<div class="stat">
							<div class="stat-value">🔥 {bestStreak}</div>
							<div class="stat-label">{t('embed.stat_best_streak')}</div>
						</div>
					{/if}
				</div>

				<div class="results-actions">
					<button class="btn-start" onclick={startGame}>
						{t('embed.play_again')}
					</button>
					<a class="results-link" href="/train" target="_top">
						{t('embed.full_trainer')}
					</a>
				</div>

				<p class="results-brand">{t('embed.brand')}</p>
			</div>
		</div>
	{/if}
</main>

<style>
	/* ── Root widget ─────────────────────────────────────────── */
	.embed-widget {
		width: 100%;
		min-height: 100dvh;
		background: var(--bg);
		color: var(--text);
		font-family: var(--font-sans);
		display: flex;
		flex-direction: column;
	}

	/* ── Setup ───────────────────────────────────────────────── */
	.setup-screen {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1.5rem;
	}

	.setup-inner {
		text-align: center;
		max-width: 360px;
		width: 100%;
	}

	.setup-icon {
		font-size: 2.5rem;
		margin-bottom: 0.75rem;
		display: block;
	}

	.setup-title {
		font-size: 1.5rem;
		font-weight: 700;
		margin-bottom: 0.25rem;
		color: var(--text);
	}

	.setup-preset-label {
		font-size: 0.85rem;
		color: var(--text-muted);
		margin-bottom: 1rem;
		font-weight: 500;
	}

	.setup-meta {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem;
		justify-content: center;
		margin-bottom: 1.25rem;
	}

	.meta-badge {
		font-size: 0.7rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		padding: 0.2rem 0.6rem;
		border-radius: 999px;
		background: var(--primary-muted);
		color: var(--primary);
		border: 1px solid color-mix(in srgb, var(--primary) 30%, transparent);
	}

	.setup-hint {
		font-size: 0.85rem;
		color: var(--text-muted);
		line-height: 1.6;
		margin-bottom: 1.5rem;
	}

	.setup-midi-status {
		font-size: 0.8rem;
		color: var(--text-muted);
		margin-bottom: 1.5rem;
	}

	.setup-midi-status.connected {
		color: var(--accent-green);
	}

	.setup-shortcut {
		margin-top: 0.75rem;
		font-size: 0.75rem;
		color: var(--text-dim);
	}

	kbd {
		font-family: var(--font-mono);
		font-size: 0.7rem;
		padding: 0.1rem 0.35rem;
		border: 1px solid var(--border);
		border-radius: 3px;
		background: var(--bg-card);
		color: var(--text-muted);
	}

	/* ── Buttons ─────────────────────────────────────────────── */
	.btn-start {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.75rem 2rem;
		border-radius: var(--radius-lg);
		background: var(--primary);
		color: var(--primary-text, #fff);
		font-weight: 700;
		font-size: 1rem;
		cursor: pointer;
		border: none;
		transition: background 0.15s;
		width: 100%;
		max-width: 220px;
	}

	.btn-start:hover {
		background: var(--primary-hover);
	}

	.btn-begin {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		padding: 0.6rem 1.75rem;
		border-radius: var(--radius-lg);
		background: var(--primary);
		color: var(--primary-text, #fff);
		font-weight: 700;
		font-size: 0.95rem;
		cursor: pointer;
		border: none;
		transition: background 0.15s;
	}

	.btn-begin:hover {
		background: var(--primary-hover);
	}

	.btn-next {
		flex: 1;
		max-width: 180px;
		padding: 0.65rem 1.25rem;
		border-radius: var(--radius-lg);
		background: var(--primary);
		color: var(--primary-text, #fff);
		font-weight: 700;
		font-size: 0.9rem;
		cursor: pointer;
		border: none;
		transition: background 0.15s;
	}

	.btn-next:hover {
		background: var(--primary-hover);
	}

	.btn-secondary {
		padding: 0.65rem 1rem;
		border-radius: var(--radius-lg);
		background: transparent;
		color: var(--text-dim);
		font-size: 0.8rem;
		cursor: pointer;
		border: 1px solid var(--border);
		transition: color 0.15s, border-color 0.15s;
	}

	.btn-secondary:hover {
		color: var(--text-muted);
		border-color: var(--border-hover);
	}

	/* ── Playing screen ──────────────────────────────────────── */
	.playing-screen {
		flex: 1;
		display: flex;
		flex-direction: column;
		min-height: 100dvh;
	}

	/* Top bar */
	.top-bar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0.6rem 1rem;
		border-bottom: 1px solid var(--border);
		flex-shrink: 0;
	}

	.top-bar-left,
	.top-bar-right {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		min-width: 80px;
	}

	.top-bar-right {
		justify-content: flex-end;
	}

	.top-bar-center {
		flex: 1;
		display: flex;
		justify-content: center;
	}

	.voicing-label {
		font-size: 0.7rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--text-dim);
	}

	.midi-dot {
		font-size: 0.5rem;
		color: var(--accent-green);
		line-height: 1;
	}

	.timer {
		font-family: var(--font-mono);
		font-size: 1.1rem;
		font-weight: 700;
		color: var(--text);
		letter-spacing: 0.04em;
	}

	.chord-counter {
		font-size: 0.75rem;
		color: var(--text-muted);
		font-variant-numeric: tabular-nums;
	}

	/* Progress */
	.progress-track {
		height: 3px;
		background: var(--wood-dark);
		flex-shrink: 0;
	}

	.progress-fill {
		height: 100%;
		background: linear-gradient(90deg, var(--primary), var(--accent-amber));
		transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1);
	}

	/* Chord area */
	.chord-area {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1rem;
		min-height: 0;
	}

	.chord-start-hint {
		text-align: center;
	}

	.hint-label {
		font-size: 0.9rem;
		color: var(--text-muted);
		margin-bottom: 0.75rem;
	}

	.hint-sub {
		margin-top: 0.5rem;
		font-size: 0.75rem;
		color: var(--text-dim);
	}

	.chord-display {
		text-align: center;
		padding: 1rem 0.5rem;
		border-radius: var(--radius-lg);
		transition: background 0.15s;
	}

	.chord-display.chord-correct {
		background: color-mix(in srgb, var(--accent-green) 12%, transparent);
	}

	.chord-display.chord-wrong {
		background: color-mix(in srgb, var(--accent-red) 10%, transparent);
	}

	.chord-name {
		font-size: clamp(3rem, 12vw, 5.5rem);
		font-weight: 800;
		line-height: 1;
		color: var(--text);
		letter-spacing: -0.02em;
		transition: color 0.15s;
	}

	.chord-display.chord-correct .chord-name {
		color: var(--accent-green);
	}

	.chord-voicing {
		margin-top: 0.4rem;
		font-size: 0.85rem;
		color: var(--text-muted);
		letter-spacing: 0.02em;
	}

	.streak-badge {
		margin-top: 0.5rem;
		font-size: 0.75rem;
		color: var(--accent-amber);
		font-weight: 600;
		animation: streakPulse 0.4s ease;
	}

	.chord-area.streak-glow {
		animation: glowFlash 1.2s ease forwards;
	}

	@keyframes streakPulse {
		0% { transform: scale(0.8); opacity: 0; }
		50% { transform: scale(1.15); }
		100% { transform: scale(1); opacity: 1; }
	}

	@keyframes glowFlash {
		0% { box-shadow: 0 0 0 0 transparent; }
		20% { box-shadow: inset 0 0 40px color-mix(in srgb, var(--accent-amber) 15%, transparent); }
		100% { box-shadow: 0 0 0 0 transparent; }
	}

	/* Piano */
	.piano-wrap {
		padding: 0 0.5rem;
		flex-shrink: 0;
	}

	/* Action bar */
	.action-bar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		padding: 0.75rem 1rem;
		border-top: 1px solid var(--border);
		flex-shrink: 0;
	}

	/* ── Results ─────────────────────────────────────────────── */
	.results-screen {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 1.5rem;
	}

	.results-inner {
		text-align: center;
		max-width: 360px;
		width: 100%;
	}

	.results-icon {
		width: 3rem;
		height: 3rem;
		border-radius: 50%;
		background: color-mix(in srgb, var(--accent-green) 15%, transparent);
		border: 2px solid var(--accent-green);
		color: var(--accent-green);
		font-size: 1.25rem;
		font-weight: 700;
		display: flex;
		align-items: center;
		justify-content: center;
		margin: 0 auto 1rem;
	}

	.results-title {
		font-size: 1.35rem;
		font-weight: 700;
		margin-bottom: 1.25rem;
		color: var(--text);
	}

	.results-stats {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(80px, 1fr));
		gap: 0.75rem;
		margin-bottom: 1.5rem;
		padding: 1rem;
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: var(--radius-lg);
	}

	.stat {
		text-align: center;
	}

	.stat-value {
		font-size: 1.4rem;
		font-weight: 800;
		color: var(--primary);
		font-variant-numeric: tabular-nums;
	}

	.stat-label {
		font-size: 0.65rem;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--text-dim);
		margin-top: 0.15rem;
	}

	.results-actions {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.75rem;
	}

	.results-link {
		font-size: 0.8rem;
		color: var(--text-muted);
		text-decoration: none;
		transition: color 0.15s;
	}

	.results-link:hover {
		color: var(--primary);
	}

	.results-brand {
		margin-top: 1.25rem;
		font-size: 0.7rem;
		color: var(--text-dim);
		letter-spacing: 0.04em;
	}

	/* ── Responsive: narrow iframes (400–500px) ─────────────── */
	@media (max-width: 480px) {
		.chord-name {
			font-size: clamp(2.5rem, 16vw, 4rem);
		}

		.top-bar {
			padding: 0.5rem 0.75rem;
		}

		.timer {
			font-size: 0.95rem;
		}
	}
</style>
