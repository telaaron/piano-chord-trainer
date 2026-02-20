<script lang="ts">
	import { onMount } from 'svelte';
	import { MidiService } from '$lib/services/midi';
	import type { MidiConnectionState, MidiDevice } from '$lib/services/midi';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import { noteToSemitone, NOTES_SHARPS } from '$lib/engine';

	// ─── MIDI state ──────────────────────────────────────────────
	const midi = new MidiService();
	let midiState: MidiConnectionState = $state('disconnected');
	let midiDevices: MidiDevice[] = $state([]);
	let midiSelectedDeviceId: string | null = $state(null);
	let midiActiveNotes: Set<number> = $state(new Set());

	// ─── Log ─────────────────────────────────────────────────────
	interface MidiLogEntry {
		time: string;
		type: 'note-on' | 'note-off' | 'connection' | 'info';
		message: string;
	}

	let log: MidiLogEntry[] = $state([]);
	let maxLog = 200;
	let lastNoteOnTime = $state(0);
	let noteOnCount = $state(0);
	let noteOffCount = $state(0);

	function addLog(type: MidiLogEntry['type'], message: string) {
		const now = new Date();
		const time = now.toLocaleTimeString('de-DE', { hour12: false }) + '.' + String(now.getMilliseconds()).padStart(3, '0');
		log = [{ time, type, message }, ...log.slice(0, maxLog - 1)];
	}

	// ─── Derived ─────────────────────────────────────────────────
	/** Human-readable note names from active MIDI notes */
	const activeNoteNames = $derived.by(() => {
		const names: string[] = [];
		const sorted = [...midiActiveNotes].sort((a, b) => a - b);
		for (const mn of sorted) {
			const pc = mn % 12;
			const octave = Math.floor(mn / 12) - 1;
			names.push(`${NOTES_SHARPS[pc]}${octave}`);
		}
		return names;
	});

	/** Pitch classes currently held */
	const activePitchClasses = $derived.by(() => {
		const set = new Set<number>();
		for (const mn of midiActiveNotes) set.add(mn % 12);
		return set;
	});

	/** Velocity of last note (for display) */
	let lastVelocity = $state(0);
	let lastNoteName = $state('');

	// ─── Raw MIDI message handler ────────────────────────────────
	// We override midi.onNotes to also log
	function handleNotes(activeNotes: Set<number>) {
		midiActiveNotes = new Set(activeNotes);
	}

	// ─── Lifecycle ───────────────────────────────────────────────
	onMount(() => {
		midi.onNotes(handleNotes);
		midi.onConnection((state) => {
			midiState = state;
			addLog('connection', `State → ${state}`);
		});
		midi.onDevices((devices) => {
			midiDevices = [...devices];
			if (devices.length > 0) {
				midiSelectedDeviceId = midi.selectedDeviceId;
				addLog('info', `Devices: ${devices.map(d => d.name).join(', ')}`);
			} else {
				addLog('info', 'No MIDI devices found');
			}
		});

		midi.init().then((ok) => {
			if (ok) {
				addLog('info', 'MIDI API initialized successfully');
				// Hook into raw messages for logging
				hookRawMessages();
			} else {
				addLog('info', 'MIDI API not available or denied');
			}
		});

		return () => {
			midi.destroy();
		};
	});

	function hookRawMessages() {
		// Access the internal MIDI access to attach a raw logger
		// We re-select the device to ensure our handler is attached
		if (midiSelectedDeviceId) {
			selectDevice(midiSelectedDeviceId);
		}
	}

	function selectDevice(deviceId: string) {
		midi.selectDevice(deviceId);
		midiSelectedDeviceId = deviceId;
		addLog('connection', `Selected device: ${midiDevices.find(d => d.id === deviceId)?.name ?? deviceId}`);

		// Attach a raw message interceptor by wrapping
		// We need to access the internal MIDIAccess — but MidiService doesn't expose it.
		// Instead we rely on the onNotes callback which tracks note-on/off.
		// For detailed logging, we'll track delta via the callback.
	}

	// Track note changes by diffing
	let prevNotes = new Set<number>();
	$effect(() => {
		const current = midiActiveNotes;
		// Find newly pressed
		for (const n of current) {
			if (!prevNotes.has(n)) {
				const pc = n % 12;
				const octave = Math.floor(n / 12) - 1;
				const name = `${NOTES_SHARPS[pc]}${octave}`;
				lastNoteName = name;
				noteOnCount++;
				const delta = lastNoteOnTime > 0 ? Date.now() - lastNoteOnTime : 0;
				lastNoteOnTime = Date.now();
				addLog('note-on', `🎹 ${name} (MIDI ${n}, PC ${pc})${delta > 0 ? ` +${delta}ms` : ''}`);
			}
		}
		// Find released
		for (const n of prevNotes) {
			if (!current.has(n)) {
				const pc = n % 12;
				const octave = Math.floor(n / 12) - 1;
				const name = `${NOTES_SHARPS[pc]}${octave}`;
				noteOffCount++;
				addLog('note-off', `   ${name} released (MIDI ${n})`);
			}
		}
		prevNotes = new Set(current);
	});

	function clearLog() {
		log = [];
		noteOnCount = 0;
		noteOffCount = 0;
	}
</script>

<svelte:head>
	<title>MIDI Test – Chord Trainer</title>
	<meta name="robots" content="noindex" />
</svelte:head>

<main class="flex-1 max-w-4xl mx-auto px-4 py-8 space-y-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-[var(--text)]">MIDI Test</h1>
			<p class="text-sm text-[var(--text-muted)] mt-1">Live view of your MIDI keyboard — verify that notes are received correctly.</p>
		</div>
		<a href="/train" class="px-4 py-2 text-sm rounded-[var(--radius-sm)] border border-[var(--border)] hover:border-[var(--border-hover)] transition-colors text-[var(--text-muted)]">
			← Back to Train
		</a>
	</div>

	<!-- Connection Status -->
	<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-4">
		<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">Connection</h2>

		<div class="flex items-center gap-3 flex-wrap">
			<div class="flex items-center gap-2">
				<div class="w-3 h-3 rounded-full {midiState === 'connected' && midiDevices.length > 0
					? 'bg-green-500 shadow-[0_0_6px_rgba(34,197,94,0.5)]'
					: midiState === 'connecting'
						? 'bg-amber-500 animate-pulse'
						: 'bg-red-500'}"></div>
				<span class="font-medium text-[var(--text)]">
					{#if midiState === 'connected' && midiDevices.length > 0}
						Connected
					{:else if midiState === 'connected'}
						API OK — No Device
					{:else if midiState === 'connecting'}
						Connecting…
					{:else if midiState === 'unsupported'}
						Not Supported (use Chrome/Edge)
					{:else if midiState === 'denied'}
						Permission Denied
					{:else}
						Disconnected
					{/if}
				</span>
			</div>

			{#if midiState === 'disconnected'}
				<button
					class="px-4 py-1.5 rounded-[var(--radius-sm)] bg-[var(--primary)] text-white text-sm font-medium hover:bg-[var(--primary-hover)] transition-colors cursor-pointer"
					onclick={() => midi.init()}
				>
					Connect
				</button>
			{/if}
		</div>

		{#if midiDevices.length > 0}
			<div class="space-y-2">
				<p class="text-xs text-[var(--text-dim)] uppercase tracking-wide">Devices ({midiDevices.length})</p>
				{#each midiDevices as device}
					<button
						class="block w-full text-left px-4 py-2.5 rounded-[var(--radius-sm)] border transition-all cursor-pointer
							{device.id === midiSelectedDeviceId
								? 'border-[var(--primary)] bg-[var(--primary-muted)] text-[var(--text)]'
								: 'border-[var(--border)] hover:border-[var(--border-hover)] text-[var(--text-muted)]'}"
						onclick={() => selectDevice(device.id)}
					>
						<span class="font-medium">{device.name}</span>
						<span class="text-xs text-[var(--text-dim)] ml-2">ID: {device.id}</span>
						{#if device.id === midiSelectedDeviceId}
							<span class="text-xs text-[var(--primary)] ml-2">● active</span>
						{/if}
					</button>
				{/each}
			</div>
		{/if}
	</section>

	<!-- Live Piano -->
	<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-4">
		<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">Live Keyboard</h2>

		<PianoKeyboard
			midiActiveNotes={midiActiveNotes}
			midiExpectedPitchClasses={new Set()}
			midiEnabled={true}
		/>

		<!-- Active notes display -->
		<div class="flex items-center gap-4 flex-wrap">
			<div class="text-sm text-[var(--text-muted)]">
				Held notes:
				{#if activeNoteNames.length > 0}
					<span class="font-mono font-bold text-[var(--text)]">
						{activeNoteNames.join(' · ')}
					</span>
				{:else}
					<span class="text-[var(--text-dim)]">None — press a key</span>
				{/if}
			</div>
		</div>

		<!-- Pitch class grid -->
		<div class="grid grid-cols-12 gap-1">
			{#each NOTES_SHARPS as note, i}
				<div class="text-center py-1.5 rounded text-xs font-mono transition-colors
					{activePitchClasses.has(i)
						? 'bg-[var(--accent-green)] text-white font-bold'
						: 'bg-[var(--bg)] text-[var(--text-dim)] border border-[var(--border)]'}">
					{note}
				</div>
			{/each}
		</div>
	</section>

	<!-- Stats -->
	<section class="grid grid-cols-3 gap-4">
		<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
			<p class="text-2xl font-bold text-[var(--text)] font-mono">{noteOnCount}</p>
			<p class="text-xs text-[var(--text-dim)] mt-1">Note On</p>
		</div>
		<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
			<p class="text-2xl font-bold text-[var(--text)] font-mono">{noteOffCount}</p>
			<p class="text-xs text-[var(--text-dim)] mt-1">Note Off</p>
		</div>
		<div class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-4 text-center">
			<p class="text-2xl font-bold text-[var(--text)] font-mono">{midiActiveNotes.size}</p>
			<p class="text-xs text-[var(--text-dim)] mt-1">Held Now</p>
		</div>
	</section>

	<!-- Event Log -->
	<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-3">
		<div class="flex items-center justify-between">
			<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">Event Log</h2>
			<button
				class="px-3 py-1 text-xs rounded-[var(--radius-sm)] border border-[var(--border)] hover:border-[var(--border-hover)] transition-colors cursor-pointer text-[var(--text-muted)]"
				onclick={clearLog}
			>
				Clear
			</button>
		</div>

		<div class="max-h-[300px] overflow-y-auto font-mono text-xs space-y-0.5 scroll-smooth">
			{#if log.length === 0}
				<p class="text-[var(--text-dim)] py-4 text-center">Play a note on your MIDI keyboard…</p>
			{/if}
			{#each log as entry}
				<div class="flex gap-2 py-0.5
					{entry.type === 'note-on' ? 'text-green-400' :
					 entry.type === 'note-off' ? 'text-[var(--text-dim)]' :
					 entry.type === 'connection' ? 'text-amber-400' :
					 'text-sky-400'}">
					<span class="text-[var(--text-dim)] shrink-0">{entry.time}</span>
					<span>{entry.message}</span>
				</div>
			{/each}
		</div>
	</section>

	<!-- Troubleshooting -->
	<section class="rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--bg-card)] p-5 space-y-3">
		<h2 class="text-sm font-semibold text-[var(--text-muted)] uppercase tracking-wider">Troubleshooting</h2>
		<ul class="text-sm text-[var(--text-muted)] space-y-2 list-disc list-inside">
			<li><strong>No devices shown?</strong> Make sure your MIDI keyboard is plugged in via USB <em>before</em> opening this page. Then click "Connect".</li>
			<li><strong>"Permission Denied"?</strong> Your browser blocked MIDI access. Reset site permissions and reload.</li>
			<li><strong>Device shows but no notes?</strong> Some keyboards need the correct MIDI channel (usually Ch 1). Check your keyboard settings.</li>
			<li><strong>Bluetooth MIDI?</strong> Web MIDI doesn't natively support Bluetooth on most platforms. Use a USB cable or a BLE-MIDI bridge app.</li>
			<li><strong>Notes stuck?</strong> If the piano shows notes held that you've released, try disconnecting and reconnecting the device.</li>
		</ul>
	</section>
</main>
