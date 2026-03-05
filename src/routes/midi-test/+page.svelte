<script lang="ts">
	import { onMount } from 'svelte';
	import { MidiService } from '$lib/services/midi';
	import type { MidiConnectionState, MidiDevice } from '$lib/services/midi';
	import { AudioInputService } from '$lib/services/audio-input';
	import type { AudioInputState } from '$lib/services/audio-input';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import { NOTES_SHARPS } from '$lib/engine';
	import { t } from '$lib/i18n';

	// ─── Tab ─────────────────────────────────────────────────────
	type Tab = 'midi' | 'mic';
	let activeTab: Tab = $state('midi');

	// ─── MIDI state ──────────────────────────────────────────────
	const midi = new MidiService();
	let midiState: MidiConnectionState = $state('disconnected');
	let midiDevices: MidiDevice[] = $state([]);
	let midiSelectedDeviceId: string | null = $state(null);
	let midiActiveNotes: Set<number> = $state(new Set());

	// ─── Mic state ───────────────────────────────────────────────
	const audioInput = new AudioInputService();
	let micState: AudioInputState = $state('idle');
	let micActiveNotes: Set<number> = $state(new Set());

	// ─── Log ─────────────────────────────────────────────────────
	interface LogEntry {
		time: string;
		type: 'note-on' | 'note-off' | 'connection' | 'info' | 'detect';
		message: string;
	}

	let midiLog: LogEntry[] = $state([]);
	let micLog: LogEntry[] = $state([]);
	const MAX_LOG = 200;

	let midiNoteOnCount = $state(0);
	let midiNoteOffCount = $state(0);
	let midiLastNoteOnTime = $state(0);

	let micDetectionCount = $state(0);
	let micLastNoteSet = $state('');

	function timestamp(): string {
		const now = new Date();
		return (
			now.toLocaleTimeString('de-DE', { hour12: false }) +
			'.' +
			String(now.getMilliseconds()).padStart(3, '0')
		);
	}

	function addMidiLog(type: LogEntry['type'], message: string) {
		midiLog = [{ time: timestamp(), type, message }, ...midiLog.slice(0, MAX_LOG - 1)];
	}

	function addMicLog(type: LogEntry['type'], message: string) {
		micLog = [{ time: timestamp(), type, message }, ...micLog.slice(0, MAX_LOG - 1)];
	}

	// ─── Derived ─────────────────────────────────────────────────
	const midiNoteNames = $derived.by(() =>
		[...midiActiveNotes]
			.sort((a, b) => a - b)
			.map((mn) => `${NOTES_SHARPS[mn % 12]}${Math.floor(mn / 12) - 1}`)
	);

	const midiPitchClasses = $derived.by(() => {
		const s = new Set<number>();
		for (const mn of midiActiveNotes) s.add(mn % 12);
		return s;
	});

	const micNoteNames = $derived.by(() =>
		[...micActiveNotes]
			.sort((a, b) => a - b)
			.map((mn) => `${NOTES_SHARPS[mn % 12]}${Math.floor(mn / 12) - 1}`)
	);

	const micPitchClasses = $derived.by(() => {
		const s = new Set<number>();
		for (const mn of micActiveNotes) s.add(mn % 12);
		return s;
	});

	const micStateLabel = $derived.by(() => {
		switch (micState) {
			case 'idle':          return t('mic.idle');
			case 'requesting':    return t('mic.requesting');
			case 'loading-model': return t('mic.loading_model');
			case 'listening':     return t('mic.listening');
			case 'analyzing':     return t('mic.analyzing');
			case 'denied':        return t('mic.denied');
			case 'unsupported':   return t('mic.unsupported');
			case 'error':         return t('mic.error');
		}
	});

	const micStateDot = $derived.by(() => {
		switch (micState) {
			case 'listening':     return 'bg-green-500 shadow-[0_0_6px_rgba(34,197,94,0.5)]';
			case 'analyzing':     return 'bg-amber-400 animate-pulse';
			case 'loading-model':
			case 'requesting':    return 'bg-amber-500 animate-pulse';
			case 'denied':
			case 'error':
			case 'unsupported':   return 'bg-red-500';
			default:              return 'bg-[var(--text-dim)]';
		}
	});

	// ─── MIDI note tracking ──────────────────────────────────────
	let prevMidiNotes = new Set<number>();
	$effect(() => {
		const current = midiActiveNotes;
		for (const n of current) {
			if (!prevMidiNotes.has(n)) {
				const name = `${NOTES_SHARPS[n % 12]}${Math.floor(n / 12) - 1}`;
				midiNoteOnCount++;
				const delta = midiLastNoteOnTime > 0 ? Date.now() - midiLastNoteOnTime : 0;
				midiLastNoteOnTime = Date.now();
				addMidiLog('note-on', `🎹 ${name} (MIDI ${n}, PC ${n % 12})${delta > 0 ? ` +${delta}ms` : ''}`);
			}
		}
		for (const n of prevMidiNotes) {
			if (!current.has(n)) {
				const name = `${NOTES_SHARPS[n % 12]}${Math.floor(n / 12) - 1}`;
				midiNoteOffCount++;
				addMidiLog('note-off', `   ${name} released (MIDI ${n})`);
			}
		}
		prevMidiNotes = new Set(current);
	});

	// ─── Mic level meter ───────────────────────────────────────
	let micLevel = $state(0); // 0–1 normalised RMS
	$effect(() => {
		if (micState !== 'listening' && micState !== 'analyzing') {
			micLevel = 0;
			return;
		}
		let rafId: number;
		const tick = () => {
			micLevel = audioInput.getLevel();
			rafId = requestAnimationFrame(tick);
		};
		rafId = requestAnimationFrame(tick);
		return () => cancelAnimationFrame(rafId);
	});

	// ─── Mic note tracking ───────────────────────────────────────
	let prevMicNotes = new Set<number>();
	$effect(() => {
		const current = micActiveNotes;
		if (current.size === 0 && prevMicNotes.size === 0) return;
		const appeared = [...current].filter((n) => !prevMicNotes.has(n));
		const disappeared = [...prevMicNotes].filter((n) => !current.has(n));
		if (appeared.length > 0) {
			const names = appeared
				.map((n) => `${NOTES_SHARPS[n % 12]}${Math.floor(n / 12) - 1}`)
				.join(' ');
			micDetectionCount++;
			addMicLog(
				'note-on',
				`🎙 +[${names}] — ${current.size} note${current.size !== 1 ? 's' : ''} active`
			);
		}
		if (disappeared.length > 0) {
			const names = disappeared
				.map((n) => `${NOTES_SHARPS[n % 12]}${Math.floor(n / 12) - 1}`)
				.join(' ');
			addMicLog('note-off', `   −[${names}] faded`);
		}
		if (current.size > 0) {
			const pcs = [...new Set([...current].map((n) => n % 12))]
				.sort((a, b) => a - b)
				.map((pc) => NOTES_SHARPS[pc])
				.join(' ');
			if (pcs !== micLastNoteSet) {
				micLastNoteSet = pcs;
				addMicLog('detect', `✶ Pitch classes: ${pcs}`);
			}
		}
		prevMicNotes = new Set(current);
	});

	// ─── Lifecycle ───────────────────────────────────────────────
	onMount(() => {
		midi.onNotes((notes) => { midiActiveNotes = new Set(notes); });
		midi.onConnection((state) => {
			midiState = state;
			addMidiLog('connection', `State → ${state}`);
		});
		midi.onDevices((devices) => {
			midiDevices = [...devices];
			if (devices.length > 0) {
				midiSelectedDeviceId = midi.selectedDeviceId;
				addMidiLog('info', `Devices: ${devices.map((d) => d.name).join(', ')}`);
			} else {
				addMidiLog('info', 'No MIDI devices found');
			}
		});
		midi.init().then((ok) => {
			addMidiLog('info', ok ? 'MIDI API initialized' : 'MIDI API not available');
		});

		audioInput.onNotes((notes) => { micActiveNotes = new Set(notes); });
		audioInput.onConnection((state) => {
			micState = state;
			addMicLog('connection', `State → ${state}`);
		});

		return () => {
			midi.destroy();
			audioInput.destroy();
		};
	});

	function selectMidiDevice(id: string) {
		midi.selectDevice(id);
		midiSelectedDeviceId = id;
		addMidiLog('connection', `Selected: ${midiDevices.find((d) => d.id === id)?.name ?? id}`);
	}

	function startMic() {
		addMicLog('info', 'Requesting microphone…');
		audioInput.init();
	}

	function stopMic() {
		audioInput.destroy();
		micActiveNotes = new Set();
		addMicLog('info', 'Stopped.');
	}
</script>

<svelte:head>
	<title>{activeTab === 'mic' ? t('mic_test.title') : t('midi_test.title')} – Chord Trainer</title>
	<meta name="robots" content="noindex" />
</svelte:head>

<main class="flex-1 max-w-4xl mx-auto px-4 py-8 space-y-6">

	<!-- Header -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-[var(--text)]">
				{activeTab === 'mic' ? t('mic_test.title') : t('midi_test.title')}
			</h1>
			<p class="text-sm text-[var(--text-muted)] mt-1">
				{activeTab === 'mic' ? t('mic_test.subtitle') : t('midi_test.subtitle')}
			</p>
		</div>
		<a
			href="/train"
			class="px-4 py-2 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] hover:border-[var(--border-hover)] transition-colors text-[var(--text-muted)]"
		>
			{t('midi_test.back')}
		</a>
	</div>

	<!-- Tab bar -->
	<div class="flex gap-1 p-1 rounded-[var(--radius)] bg-[var(--bg-muted)] border border-[var(--border)] w-fit">
		<button
			class="px-5 py-2 rounded-[var(--radius-sm)] text-sm font-medium transition-all cursor-pointer
				{activeTab === 'midi'
					? 'bg-[var(--bg-card)] text-[var(--text)] shadow-sm border border-[var(--border)]'
					: 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
			onclick={() => (activeTab = 'midi')}
		>
			🎹 MIDI
		</button>
		<button
			class="px-5 py-2 rounded-[var(--radius-sm)] text-sm font-medium transition-all cursor-pointer
				{activeTab === 'mic'
					? 'bg-[var(--bg-card)] text-[var(--text)] shadow-sm border border-[var(--border)]'
					: 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
			onclick={() => (activeTab = 'mic')}
		>
			🎙 {t('mic_test.title')}
		</button>
	</div>

	<!-- === MIDI TAB === -->
	{#if activeTab === 'midi'}

		<!-- Connection Status -->
		<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-4">
			<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">{t('midi_test.connection')}</h2>
			<div class="flex items-center gap-3 flex-wrap">
				<div class="flex items-center gap-2">
					<div class="w-3 h-3 rounded-full {midiState === 'connected' && midiDevices.length > 0
						? 'bg-green-500 shadow-[0_0_6px_rgba(34,197,94,0.5)]'
						: midiState === 'connecting' ? 'bg-amber-500 animate-pulse' : 'bg-red-500'}"></div>
					<span class="font-medium text-[var(--text)]">
						{#if midiState === 'connected' && midiDevices.length > 0}{t('midi_test.connected')}
						{:else if midiState === 'connected'}{t('midi_test.api_ok')}
						{:else if midiState === 'connecting'}{t('midi_test.connecting')}
						{:else if midiState === 'unsupported'}{t('midi_test.unsupported')}
						{:else if midiState === 'denied'}{t('midi_test.permission_denied')}
						{:else}{t('midi_test.disconnected')}{/if}
					</span>
				</div>
				{#if midiState === 'disconnected'}
					<button
						class="px-4 py-1.5 rounded-[var(--radius-sm)] bg-[var(--primary)] text-white text-sm font-medium hover:bg-[var(--primary-hover)] transition-colors cursor-pointer"
						onclick={() => midi.init()}
					>{t('midi_test.connect_btn')}</button>
				{/if}
			</div>
			{#if midiDevices.length > 0}
				<div class="space-y-2">
					<p class="text-xs text-[var(--text-dim)] uppercase tracking-wide">{t('midi_test.devices_label')} ({midiDevices.length})</p>
					{#each midiDevices as device}
						<button
							class="block w-full text-left px-4 py-2.5 rounded-[var(--radius-sm)] border transition-all cursor-pointer
								{device.id === midiSelectedDeviceId
									? 'border-[var(--primary)] bg-[var(--primary-muted)] text-[var(--text)]'
									: 'border-[var(--border)] hover:border-[var(--border-hover)] text-[var(--text-muted)]'}"
							onclick={() => selectMidiDevice(device.id)}
						>
							<span class="font-medium">{device.name}</span>
							<span class="text-xs text-[var(--text-dim)] ml-2">{t('midi_test.id_label')}: {device.id}</span>
							{#if device.id === midiSelectedDeviceId}<span class="text-xs text-[var(--primary)] ml-2">● {t('midi_test.active_label')}</span>{/if}
						</button>
					{/each}
				</div>
			{/if}
		</section>

		<!-- Live Piano -->
		<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-4">
			<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">{t('midi_test.live_keyboard')}</h2>
			<PianoKeyboard midiActiveNotes={midiActiveNotes} midiExpectedPitchClasses={new Set()} midiEnabled={true} />
			<div class="text-sm text-[var(--text-muted)]">
				{t('midi_test.held_notes')}
				{#if midiNoteNames.length > 0}
					<span class="font-mono font-bold text-[var(--text)]">{midiNoteNames.join(' · ')}</span>
				{:else}
					<span class="text-[var(--text-dim)]">{t('midi_test.none_press_key')}</span>
				{/if}
			</div>
			<div class="grid grid-cols-12 gap-1">
				{#each NOTES_SHARPS as note, i}
					<div class="text-center py-1.5 rounded text-xs font-mono transition-colors
						{midiPitchClasses.has(i) ? 'bg-[var(--accent-green)] text-white font-bold' : 'bg-[var(--bg)] text-[var(--text-dim)] border border-[var(--border)]'}">{note}</div>
				{/each}
			</div>
		</section>

		<!-- Stats -->
		<section class="grid grid-cols-3 gap-4">
			<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
				<p class="text-2xl font-bold text-[var(--text)] font-mono">{midiNoteOnCount}</p>
				<p class="text-xs text-[var(--text-dim)] mt-1">{t('midi_test.note_on')}</p>
			</div>
			<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
				<p class="text-2xl font-bold text-[var(--text)] font-mono">{midiNoteOffCount}</p>
				<p class="text-xs text-[var(--text-dim)] mt-1">{t('midi_test.note_off')}</p>
			</div>
			<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
				<p class="text-2xl font-bold text-[var(--text)] font-mono">{midiActiveNotes.size}</p>
				<p class="text-xs text-[var(--text-dim)] mt-1">{t('midi_test.held_now')}</p>
			</div>
		</section>

		<!-- Event Log -->
		<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-3">
			<div class="flex items-center justify-between">
				<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">{t('midi_test.event_log')}</h2>
				<button
					class="px-3 py-1 text-xs rounded-[var(--radius-sm)] border border-[var(--border)] hover:border-[var(--border-hover)] transition-colors cursor-pointer text-[var(--text-muted)]"
					onclick={() => { midiLog = []; midiNoteOnCount = 0; midiNoteOffCount = 0; }}
				>{t('midi_test.clear_log')}</button>
			</div>
			<div class="max-h-[300px] overflow-y-auto font-mono text-xs space-y-0.5">
				{#if midiLog.length === 0}<p class="text-[var(--text-dim)] py-4 text-center">{t('midi_test.log_empty')}</p>{/if}
				{#each midiLog as entry}
					<div class="flex gap-2 py-0.5 {entry.type === 'note-on' ? 'text-green-400' : entry.type === 'note-off' ? 'text-[var(--text-dim)]' : entry.type === 'connection' ? 'text-amber-400' : 'text-sky-400'}">
						<span class="text-[var(--text-dim)] shrink-0">{entry.time}</span>
						<span>{entry.message}</span>
					</div>
				{/each}
			</div>
		</section>

		<!-- Troubleshooting -->
		<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-3">
			<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">{t('midi_test.troubleshooting')}</h2>
			<ul class="text-sm text-[var(--text-muted)] space-y-2 list-disc list-inside">
				<li>{@html t('midi_test.ts_item1')}</li>
				<li>{@html t('midi_test.ts_item2')}</li>
				<li>{@html t('midi_test.ts_item3')}</li>
				<li>{@html t('midi_test.ts_item4')}</li>
				<li>{@html t('midi_test.ts_item5')}</li>
			</ul>
		</section>

	<!-- === MIC TAB === -->
	{:else}

		<!-- Status -->
		<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-4">
			<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">{t('mic_test.status')}</h2>
			<div class="flex items-center gap-3 flex-wrap">
				<div class="flex items-center gap-2">
					<div class="w-3 h-3 rounded-full {micStateDot}"></div>
					<span class="font-medium text-[var(--text)]">{micStateLabel}</span>
				</div>
				{#if micState === 'idle' || micState === 'error' || micState === 'denied'}
					<button
						class="px-4 py-1.5 rounded-[var(--radius-sm)] bg-[var(--primary)] text-white text-sm font-medium hover:bg-[var(--primary-hover)] transition-colors cursor-pointer"
						onclick={startMic}
					>{t('mic_test.start_btn')}</button>
				{:else if micState === 'listening' || micState === 'analyzing' || micState === 'loading-model' || micState === 'requesting'}
					<button
						class="px-4 py-1.5 rounded-[var(--radius-sm)] border border-[var(--border)] text-sm text-[var(--text-muted)] hover:border-[var(--accent-red)] hover:text-[var(--accent-red)] transition-colors cursor-pointer"
						onclick={stopMic}
					>{t('mic_test.stop_btn')}</button>
				{/if}
			</div>		<!-- Level meter -->
		{#if micState === 'listening' || micState === 'analyzing'}
			<div class="space-y-1">
				<div class="flex items-center justify-between text-xs text-[var(--text-dim)]">
					<span>Eingangspegel</span>
					<span class="font-mono">{Math.round(micLevel * 100)}%</span>
				</div>
				<div class="relative h-3 rounded-full bg-[var(--bg)] border border-[var(--border)] overflow-hidden">
					<!-- green zone 0-70% -->
					<div
						class="absolute inset-y-0 left-0 rounded-full transition-none"
						class:bg-green-500={micLevel < 0.7}
						class:bg-amber-400={micLevel >= 0.7 && micLevel < 0.9}
						class:bg-red-500={micLevel >= 0.9}
						style="width: {micLevel * 100}%"
					></div>
				<!-- threshold marker at 2% (energyThreshold 0.004 / normalisation 0.2) -->
					<div class="absolute inset-y-0 w-px bg-[var(--text-dim)] opacity-50" style="left: 2%"></div>
				</div>
				{#if micLevel === 0}
					<p class="text-xs text-amber-400">Kein Signal — falsches Mikrofon ausgewählt?</p>
				{/if}
			</div>
		{/if}
			{#if micState === 'denied'}
				<p class="text-sm text-amber-400">{t('mic.denied_hint')}</p>
			{:else if micState === 'unsupported'}
				<p class="text-sm text-red-400">{t('mic.unsupported_hint')}</p>
			{:else if micState === 'loading-model'}
				<div class="flex items-center gap-2 text-sm text-amber-400">
					<div class="w-4 h-4 rounded-full border-2 border-amber-400 border-t-transparent animate-spin shrink-0"></div>
					<span>Loading ML model (~900 KB)…</span>
				</div>
			{:else if micState === 'listening' || micState === 'analyzing'}
				<p class="text-xs text-[var(--text-dim)]">{t('mic_test.latency_note')}</p>
			{/if}
		</section>

		<!-- Live Piano -->
		<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-4">
			<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">{t('mic_test.live_keyboard')}</h2>
			<PianoKeyboard midiActiveNotes={micActiveNotes} midiExpectedPitchClasses={new Set()} midiEnabled={true} />
			<div class="text-sm text-[var(--text-muted)]">
				{t('mic_test.held_notes')}
				{#if micNoteNames.length > 0}
					<span class="font-mono font-bold text-[var(--text)]">{micNoteNames.join(' · ')}</span>
				{:else}
					<span class="text-[var(--text-dim)]">{t('mic_test.none_play_chord')}</span>
				{/if}
			</div>
			<div class="grid grid-cols-12 gap-1">
				{#each NOTES_SHARPS as note, i}
					<div class="text-center py-1.5 rounded text-xs font-mono transition-colors
						{micPitchClasses.has(i) ? 'bg-[var(--accent-amber)] text-black font-bold' : 'bg-[var(--bg)] text-[var(--text-dim)] border border-[var(--border)]'}">{note}</div>
				{/each}
			</div>
		</section>

		<!-- Stats -->
		<section class="grid grid-cols-2 gap-4">
			<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
				<p class="text-2xl font-bold text-[var(--text)] font-mono">{micDetectionCount}</p>
				<p class="text-xs text-[var(--text-dim)] mt-1">{t('mic_test.detections')}</p>
			</div>
			<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
				<p class="text-2xl font-bold text-[var(--text)] font-mono">{micActiveNotes.size}</p>
				<p class="text-xs text-[var(--text-dim)] mt-1">{t('midi_test.held_now')}</p>
			</div>
		</section>

		<!-- Detection Log -->
		<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-3">
			<div class="flex items-center justify-between">
				<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">{t('mic_test.event_log')}</h2>
				<button
					class="px-3 py-1 text-xs rounded-[var(--radius-sm)] border border-[var(--border)] hover:border-[var(--border-hover)] transition-colors cursor-pointer text-[var(--text-muted)]"
					onclick={() => { micLog = []; micDetectionCount = 0; }}
				>{t('midi_test.clear_log')}</button>
			</div>
			<div class="max-h-[300px] overflow-y-auto font-mono text-xs space-y-0.5">
				{#if micLog.length === 0}<p class="text-[var(--text-dim)] py-4 text-center">{t('mic_test.log_empty')}</p>{/if}
				{#each micLog as entry}
					<div class="flex gap-2 py-0.5 {entry.type === 'note-on' ? 'text-amber-400' : entry.type === 'note-off' ? 'text-[var(--text-dim)]' : entry.type === 'detect' ? 'text-purple-400' : 'text-sky-400'}">
						<span class="text-[var(--text-dim)] shrink-0">{entry.time}</span>
						<span>{entry.message}</span>
					</div>
				{/each}
			</div>
		</section>

		<!-- Troubleshooting -->
		<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-3">
			<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">{t('mic_test.troubleshooting')}</h2>
			<ul class="text-sm text-[var(--text-muted)] space-y-2 list-disc list-inside">
				<li>{@html t('mic_test.ts_item1')}</li>
				<li>{@html t('mic_test.ts_item2')}</li>
				<li>{@html t('mic_test.ts_item3')}</li>
				<li>{@html t('mic_test.ts_item4')}</li>
				<li>{@html t('mic_test.ts_item5')}</li>
			</ul>
		</section>

	{/if}
</main>
