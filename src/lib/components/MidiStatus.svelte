<script lang="ts">
	import type { MidiConnectionState, MidiDevice } from '$lib/services/midi';

	interface Props {
		state: MidiConnectionState;
		devices: MidiDevice[];
		selectedDeviceId: string | null;
		activeNoteCount: number;
		onSelectDevice: (deviceId: string) => void;
		onConnect: () => void;
	}

	let {
		state,
		devices,
		selectedDeviceId,
		activeNoteCount,
		onSelectDevice,
		onConnect,
	}: Props = $props();

	const stateLabel = $derived(
		state === 'connected'
			? devices.length > 0
				? 'Verbunden'
				: 'Kein Gerät'
			: state === 'connecting'
				? 'Verbinde…'
				: state === 'unsupported'
					? 'Nicht unterstützt'
					: 'Getrennt',
	);

	const stateColor = $derived(
		state === 'connected' && devices.length > 0
			? 'bg-[var(--accent-green)]'
			: state === 'connecting'
				? 'bg-[var(--accent-amber)]'
				: 'bg-[var(--text-dim)]',
	);
</script>

<div class="flex items-center gap-3 text-sm">
	<!-- Status dot -->
	<div class="flex items-center gap-2">
		<div class="w-2 h-2 rounded-full {stateColor}"></div>
		<span class="text-[var(--text-muted)]">MIDI: {stateLabel}</span>
	</div>

	{#if state === 'disconnected'}
		<button
			class="px-3 py-1 rounded-[var(--radius-sm)] border border-[var(--border)] text-xs hover:border-[var(--border-hover)] transition-colors cursor-pointer"
			onclick={onConnect}
		>
			Verbinden
		</button>
	{/if}

	{#if state === 'connected' && devices.length > 1}
		<select
			class="px-2 py-1 rounded-[var(--radius-sm)] border border-[var(--border)] bg-[var(--bg)] text-[var(--text)] text-xs focus:outline-none focus:ring-1 focus:ring-[var(--primary)]"
			onchange={(e) => onSelectDevice((e.target as HTMLSelectElement).value)}
		>
			{#each devices as device}
				<option value={device.id} selected={device.id === selectedDeviceId}>
					{device.name}
				</option>
			{/each}
		</select>
	{/if}

	{#if state === 'connected' && devices.length > 0 && activeNoteCount > 0}
		<span class="text-xs text-[var(--text-dim)] font-mono">
			♪ {activeNoteCount}
		</span>
	{/if}

	{#if state === 'unsupported'}
		<span class="text-xs text-[var(--text-dim)]">
			Web MIDI nur auf Desktop (Chrome/Edge) verfügbar
		</span>
	{/if}
</div>
