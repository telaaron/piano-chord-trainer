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
	import ExplainPanel from '$lib/components/ExplainPanel.svelte';
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

	const PRESET_KEYS: Record<string, string> = {
		'shell-warmup': 'embed.preset_shell_warmup',
		'rootless-drill': 'embed.preset_rootless_drill',
		'251-advanced': 'embed.preset_251_advanced',
		'openstudio-intro': 'embed.preset_openstudio_intro',
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
		'3-6-2-5': 'settings.progression_3625',
		'1-4-5': 'settings.progression_145',
		'diatonic': 'settings.progression_diatonic',
		'custom': 'settings.progression_custom',
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
	let showExplain = $state(false);
	const presetLabel = PRESET_KEYS[presetKey] ? t(PRESET_KEYS[presetKey]) : '';

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
			result = midi.checkChord(currentData.voicing);
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

<main class="w-full min-h-dvh bg-(--bg) text-(--text) font-sans flex flex-col" aria-label="Chord Trainer Practice Widget">
	<!-- ── Setup Screen ──────────────────────────────────────── -->
	{#if screen === 'setup'}
		<div class="flex-1 flex items-center justify-center p-6">
			<div class="text-center max-w-90 w-full">
				<!-- Logo mark -->
				<div class="text-[2.5rem] mb-3 block" aria-hidden="true">🎹</div>

				<h1 class="text-2xl font-bold mb-1 text-(--text)">{t('embed.setup_title')}</h1>

				{#if presetLabel}
					<p class="text-sm text-(--text-muted) mb-4 font-medium">{presetLabel}</p>
				{/if}

				<div class="flex flex-wrap gap-2 justify-center mb-5">
					<span class="text-[0.7rem] font-semibold uppercase tracking-[0.06em] py-[0.2rem] px-[0.6rem] rounded-full bg-(--primary-muted) text-(--primary) border border-[color-mix(in_srgb,var(--primary)_30%,transparent)]">{t(VOICING_KEYS[config.voicing])}</span>
					<span class="text-[0.7rem] font-semibold uppercase tracking-[0.06em] py-[0.2rem] px-[0.6rem] rounded-full bg-(--primary-muted) text-(--primary) border border-[color-mix(in_srgb,var(--primary)_30%,transparent)]">{t(PROGRESSION_KEYS[config.progressionMode])}</span>
					<span class="text-[0.7rem] font-semibold uppercase tracking-[0.06em] py-[0.2rem] px-[0.6rem] rounded-full bg-(--primary-muted) text-(--primary) border border-[color-mix(in_srgb,var(--primary)_30%,transparent)]">{config.chords} {t('embed.stat_chords')}</span>
					<span class="text-[0.7rem] font-semibold uppercase tracking-[0.06em] py-[0.2rem] px-[0.6rem] rounded-full bg-(--primary-muted) text-(--primary) border border-[color-mix(in_srgb,var(--primary)_30%,transparent)]">{t(DIFFICULTY_KEYS[config.difficulty])}</span>
				</div>

				{#if midiState === 'connected' && midiHasDevice}
					<p class="text-[0.8rem] text-(--accent-green) mb-6">{t('embed.midi_connected')}</p>
				{:else if midiState === 'connecting'}
					<p class="text-[0.8rem] text-(--text-muted) mb-6">{t('embed.connecting')}</p>
				{:else}
					<p class="text-sm text-(--text-muted) leading-[1.6] mb-6">{@html t('embed.setup_hint')}</p>
				{/if}

				<button class="inline-flex items-center justify-center py-3 px-8 rounded-lg bg-(--primary) text-(--primary-text,#fff) font-bold text-base cursor-pointer border-none transition-[background] duration-150 w-full max-w-55 hover:bg-(--primary-hover)" onclick={startGame}>
					{t('embed.start_drill')}
				</button>

				<p class="mt-3 text-xs text-(--text-dim)">{@html t('embed.or_press_space')}</p>
			</div>
		</div>
	{/if}

	<!-- ── Playing Screen ────────────────────────────────────── -->
	{#if screen === 'playing'}
		<div class="flex-1 flex flex-col min-h-dvh">
			<!-- Top bar -->
			<div class="flex items-center justify-between py-[0.6rem] px-4 border-b border-(--border) shrink-0 max-[480px]:py-2 max-[480px]:px-3">
				<div class="flex items-center gap-2 min-w-20">
					<span class="text-[0.7rem] font-semibold uppercase tracking-[0.06em] text-(--text-dim)">{t(VOICING_KEYS[config.voicing])}</span>
					{#if midiState === 'connected' && midiHasDevice}
						<span class="text-[0.5rem] text-(--accent-green) leading-none" title={t('embed.midi_connected')} aria-label={t('embed.midi_connected')}>●</span>
					{/if}
				</div>
				<div class="flex-1 flex justify-center">
					<span class="font-mono text-[1.1rem] font-bold text-(--text) tracking-[0.04em] max-[480px]:text-[0.95rem]" aria-live="off">{formatTime(elapsedMs)}</span>
				</div>
				<div class="flex items-center gap-2 min-w-20 justify-end">
					<span class="text-xs text-(--text-muted) tabular-nums">{currentIdx + 1} / {totalChords}</span>
				</div>
			</div>

			<!-- Progress bar -->
			<div class="h-0.75 bg-(--wood-dark) shrink-0" role="progressbar" aria-valuenow={currentIdx} aria-valuemax={totalChords}>
				<div class="h-full bg-linear-to-r from-(--primary) to-(--accent-amber) transition-[width] duration-400 ease-in-out" style="width: {progressPct}%"></div>
			</div>

			<!-- Chord display -->
			<div class="flex-1 flex items-center justify-center p-4 min-h-0" class:streak-glow={streakGlow}>
				{#if !timerStarted}
					<div class="text-center">
						<p class="text-[0.9rem] text-(--text-muted) mb-3">{t('embed.ready')}</p>
						<button class="inline-flex items-center justify-center py-[0.6rem] px-7 rounded-lg bg-(--primary) text-(--primary-text,#fff) font-bold text-[0.95rem] cursor-pointer border-none transition-[background] duration-150 hover:bg-(--primary-hover)" onclick={beginTimer}>{t('embed.begin')}</button>
						<p class="mt-2 text-xs text-(--text-dim)">{@html t('embed.or_press_space')}</p>
					</div>
				{:else}
					<div class="chord-display text-center py-4 px-2 rounded-lg transition-[background] duration-150"
						class:chord-correct={midiMatchResult?.correct}
						class:chord-wrong={midiMatchResult && !midiMatchResult.correct && midiActiveNotes.size > 0}>
						<div class="chord-name text-[clamp(3rem,12vw,5.5rem)] font-extrabold leading-none text-(--text) tracking-[-0.02em] transition-[color] duration-150 max-[480px]:text-[clamp(2.5rem,16vw,4rem)]" aria-live="polite">
							{currentData?.chord ?? ''}
						</div>
						{#if currentData?.voicing && currentData.voicing.length > 0}
							<div class="mt-[0.4rem] text-sm text-(--text-muted) tracking-[0.02em]">{currentData.voicing.join(' – ')}</div>
						{:else if currentData}
							<div class="mt-[0.4rem] text-sm tracking-[0.02em]" style="color: var(--text-dim)">{t('embed.no_voicing')}</div>
						{/if}
						{#if streak >= STREAK_THRESHOLD}
							<div class="streak-badge">{t('embed.streak', { count: streak })}</div>
						{/if}
					</div>
				{/if}
			</div>

			<!-- Piano keyboard -->
			<div class="px-2 shrink-0">
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
			<div class="flex items-center justify-between gap-3 py-3 px-4 border-t border-(--border) shrink-0">
				<button class="py-[0.65rem] px-4 rounded-lg bg-transparent text-(--text-dim) text-[0.8rem] cursor-pointer border border-(--border) transition-[color,border-color] duration-150 hover:text-(--text-muted) hover:border-(--border-hover)" onclick={resetToSetup} title={t('embed.back_to_setup_title')}>
					{t('embed.back_to_setup')}
				</button>
				{#if timerStarted && currentData}
					<button class="py-[0.65rem] px-4 rounded-lg bg-transparent text-(--text-dim) text-[0.8rem] cursor-pointer border border-(--border) transition-[color,border-color] duration-150 hover:text-(--text-muted) hover:border-(--border-hover)" onclick={() => { showExplain = true; }} title={t('explain.title')}>
						?
					</button>
				{/if}
				{#if timerStarted}
					<button class="flex-1 max-w-45 py-[0.65rem] px-5 rounded-lg bg-(--primary) text-(--primary-text,#fff) font-bold text-[0.9rem] cursor-pointer border-none transition-[background] duration-150 hover:bg-(--primary-hover)" onclick={nextChord}>
						{currentIdx < totalChords - 1 ? t('embed.next') : t('embed.finish')}
					</button>
				{/if}
			</div>
		</div>
	{/if}

	<!-- ── Finished Screen ────────────────────────────────────── -->
	{#if screen === 'finished'}
		<div class="flex-1 flex items-center justify-center p-6">
			<div class="text-center max-w-90 w-full">
				<div class="w-12 h-12 rounded-full bg-[color-mix(in_srgb,var(--accent-green)_15%,transparent)] border-2 border-(--accent-green) text-(--accent-green) text-xl font-bold flex items-center justify-center mx-auto mb-4" aria-hidden="true">✓</div>
				<h2 class="text-xl font-bold mb-5 text-(--text)">{t('embed.session_complete')}</h2>

				<div class="grid grid-cols-[repeat(auto-fit,minmax(80px,1fr))] gap-3 mb-6 p-4 bg-(--bg-card) border border-(--border) rounded-lg">
					<div class="text-center">
						<div class="text-xl font-extrabold text-(--primary) tabular-nums">{totalChords}</div>
						<div class="text-[0.65rem] uppercase tracking-[0.06em] text-(--text-dim) mt-[0.15rem]">{t('embed.stat_chords')}</div>
					</div>
					<div class="text-center">
						<div class="text-xl font-extrabold text-(--primary) tabular-nums">{formatTime(endTime - startTime)}</div>
						<div class="text-[0.65rem] uppercase tracking-[0.06em] text-(--text-dim) mt-[0.15rem]">{t('embed.stat_total_time')}</div>
					</div>
					<div class="text-center">
						<div class="text-xl font-extrabold text-(--primary) tabular-nums">{(avgMs / 1000).toFixed(1)}s</div>
						<div class="text-[0.65rem] uppercase tracking-[0.06em] text-(--text-dim) mt-[0.15rem]">{t('embed.stat_avg')}</div>
					</div>
					{#if midiTotalAttempts > 0}
						<div class="text-center">
							<div class="text-xl font-extrabold text-(--primary) tabular-nums">{midiAccuracy}%</div>
							<div class="text-[0.65rem] uppercase tracking-[0.06em] text-(--text-dim) mt-[0.15rem]">{t('embed.stat_accuracy')}</div>
						</div>
					{/if}
					{#if bestStreak >= STREAK_THRESHOLD}
						<div class="text-center">
							<div class="text-xl font-extrabold text-(--primary) tabular-nums">🔥 {bestStreak}</div>
							<div class="text-[0.65rem] uppercase tracking-[0.06em] text-(--text-dim) mt-[0.15rem]">{t('embed.stat_best_streak')}</div>
						</div>
					{/if}
				</div>

				<div class="flex flex-col items-center gap-3">
					<button class="inline-flex items-center justify-center py-3 px-8 rounded-lg bg-(--primary) text-(--primary-text,#fff) font-bold text-base cursor-pointer border-none transition-[background] duration-150 w-full max-w-55 hover:bg-(--primary-hover)" onclick={startGame}>
						{t('embed.play_again')}
					</button>
					<a class="text-[0.8rem] text-(--text-muted) no-underline transition-[color] duration-150 hover:text-(--primary)" href="/train" target="_top">
						{t('embed.full_trainer')}
					</a>
				</div>

				<p class="mt-5 text-[0.7rem] text-(--text-dim) tracking-[0.04em]">{t('embed.brand')}</p>
			</div>
		</div>
	{/if}
</main>

{#if showExplain && currentData}
	<ExplainPanel
		chordData={currentData}
		voicing={config.voicing}
		onclose={() => { showExplain = false; }}
	/>
{/if}

<style>
	/* -- Kept: element selector used in @html content -- */
	:global(kbd) {
		font-family: var(--font-mono);
		font-size: 0.7rem;
		padding: 0.1rem 0.35rem;
		border: 1px solid var(--border);
		border-radius: 3px;
		background: var(--bg-card);
		color: var(--text-muted);
	}

	/* -- Kept: conditional chord state classes -- */
	.chord-correct {
		background: color-mix(in srgb, var(--accent-green) 12%, transparent);
	}

	.chord-wrong {
		background: color-mix(in srgb, var(--accent-red) 10%, transparent);
	}

	.chord-correct .chord-name {
		color: var(--accent-green);
	}

	/* -- Kept: animation classes referencing keyframes -- */
	.streak-badge {
		margin-top: 0.5rem;
		font-size: 0.75rem;
		color: var(--accent-amber);
		font-weight: 600;
		animation: streakPulse 0.4s ease;
	}

	.streak-glow {
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
</style>

