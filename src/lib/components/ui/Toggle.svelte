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
	class="flex w-full items-center justify-between gap-3 rounded-[2px] px-3 py-2.5 text-left min-h-[var(--tap-min)]
		transition-colors hover:bg-[var(--bg-card)] disabled:opacity-50
		focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--bg)]"
>
	<span class="flex flex-col min-w-0">
		<span class="text-[var(--text-sm)] font-medium text-[var(--text)]">{label}</span>
		{#if description}
			<span class="text-[var(--text-xs)] text-[var(--text-dim)]">{description}</span>
		{/if}
	</span>
	<!-- The track stays rounded — a switch has to read as a switch — but it
	     is ruled rather than filled, and the knob is a token, not raw white. -->
	<span
		class="relative h-6 w-11 shrink-0 rounded-full border transition-colors {checked
			? 'border-[var(--primary)] bg-[var(--primary)]'
			: 'border-[var(--border-hover)] bg-[var(--bg-muted)]'}"
	>
		<span
			class="absolute top-[3px] left-[3px] h-[16px] w-[16px] rounded-full transition-transform {checked
				? 'translate-x-5 bg-[var(--primary-text)]'
				: 'bg-[var(--text-muted)]'}"
		></span>
	</span>
</button>
