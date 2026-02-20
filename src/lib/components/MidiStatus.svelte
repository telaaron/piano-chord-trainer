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
				? 'Connected'
				: 'No Device'
			: state === 'connecting'
				? 'Connecting…'
				: state === 'unsupported'
					? 'Not Supported'
					: state === 'denied'
						? 'Permission Denied'
						: 'Disconnected',
	);

	const stateColor = $derived(
		state === 'connected' && devices.length > 0
			? 'bg-[var(--accent-green)]'
			: state === 'connecting'
				? 'bg-[var(--accent-amber)]'
				: state === 'denied'
					? 'bg-red-500'
					: 'bg-[var(--text-dim)]',
	);
</script>

<div class="flex items-center gap-3 text-sm flex-wrap">
	<!-- Status dot -->
	<div class="flex items-center gap-2">
		<div class="w-2 h-2 rounded-full {stateColor} {state === 'connecting' ? 'animate-pulse' : ''}"></div>
		<span class="text-[var(--text-muted)]">MIDI: {stateLabel}</span>
	</div>

	{#if state === 'disconnected'}
		<button
			class="px-3 py-1 rounded-[var(--radius-sm)] border border-[var(--border)] text-xs hover:border-[var(--border-hover)] transition-colors cursor-pointer"
			onclick={onConnect}
		>
			Connect
		</button>
	{/if}

	{#if state === 'denied'}
		<a
			href="https://support.google.com/chrome/answer/114662"
			target="_blank"
			rel="noopener noreferrer"
			class="text-xs text-[var(--accent-amber)] underline underline-offset-2 hover:text-[var(--primary)] transition-colors"
		>
			How to allow MIDI →
		</a>
	{/if}

	{#if state === 'unsupported'}
		<span class="text-xs text-[var(--text-dim)]">
			Use
			<a
				href="https://www.google.com/chrome/"
				target="_blank"
				rel="noopener noreferrer"
				class="text-[var(--accent-amber)] underline underline-offset-2 hover:text-[var(--primary)] transition-colors"
			>Chrome</a>
			or
			<a
				href="https://www.microsoft.com/edge"
				target="_blank"
				rel="noopener noreferrer"
				class="text-[var(--accent-amber)] underline underline-offset-2 hover:text-[var(--primary)] transition-colors"
			>Edge</a>
			for MIDI
		</span>
	{/if}

	{#if state === 'connected' && devices.length > 1}
		<select
			value={selectedDeviceId}
			class="px-2 py-1 rounded-[var(--radius-sm)] border border-[var(--border)] bg-[var(--bg)] text-[var(--text)] text-xs focus:outline-none focus:ring-1 focus:ring-[var(--primary)]"
			onchange={(e) => onSelectDevice((e.target as HTMLSelectElement).value)}
		>
			{#each devices as device}
				<option value={device.id} selected={device.id === selectedDeviceId}>
					{device.name}
				</option>
			{/each}
		</select>
	{:else if state === 'connected' && devices.length === 1}
		<span class="text-xs text-[var(--text-dim)] truncate max-w-[160px]" title={devices[0].name}>
			{devices[0].name}
		</span>
	{/if}

	{#if state === 'connected' && devices.length > 0 && activeNoteCount > 0}
		<span class="text-xs text-[var(--text-dim)] font-mono">
			♪ {activeNoteCount}
		</span>
	{/if}
</div>
