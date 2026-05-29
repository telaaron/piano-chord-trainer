<script lang="ts">
	interface Props {
		checked: boolean;
		label: string;
		description?: string;
		disabled?: boolean;
		onchange?: (checked: boolean) => void;
	}

	let { checked = $bindable(), label, description, disabled = false, onchange }: Props = $props();

	function toggle() {
		if (disabled) return;
		checked = !checked;
		onchange?.(checked);
	}
</script>

<button
	type="button"
	role="switch"
	aria-checked={checked}
	aria-label={label}
	{disabled}
	onclick={toggle}
	class="flex w-full items-center justify-between gap-3 rounded-[var(--radius)] px-3 py-2.5 text-left min-h-[var(--tap-min)]
		transition-colors hover:bg-[var(--bg-card)]/60 disabled:opacity-50
		focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--bg)]"
>
	<span class="flex flex-col min-w-0">
		<span class="text-[var(--text-sm)] font-medium text-[var(--text)]">{label}</span>
		{#if description}
			<span class="text-[var(--text-xs)] text-[var(--text-dim)]">{description}</span>
		{/if}
	</span>
	<span
		class="relative h-6 w-11 shrink-0 rounded-full transition-colors {checked
			? 'bg-[var(--primary)]'
			: 'bg-[var(--bg-muted)]'}"
	>
		<span
			class="absolute top-0.5 left-0.5 h-5 w-5 rounded-full bg-white shadow-sm transition-transform {checked
				? 'translate-x-5'
				: ''}"
		></span>
	</span>
</button>
