<script lang="ts" generics="T extends string">
	interface Option {
		value: T;
		label: string;
	}

	interface Props {
		options: Option[];
		value: T;
		label: string;
		onchange?: (value: T) => void;
	}

	let { options, value = $bindable(), label, onchange }: Props = $props();

	function select(v: T) {
		value = v;
		onchange?.(v);
	}
</script>

<!-- Divided cells inside one ruled frame — a register strip, not pills. -->
<div
	role="radiogroup"
	aria-label={label}
	class="inline-flex flex-wrap rounded-[2px] border border-[var(--border)] bg-[var(--bg-card)]"
>
	{#each options as opt (opt.value)}
		<button
			type="button"
			role="radio"
			aria-checked={value === opt.value}
			onclick={() => select(opt.value)}
			class="min-h-9 px-3.5 text-[var(--text-sm)] font-medium transition-colors
				border-l border-[var(--border)] first:border-l-0
				focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-inset
				{value === opt.value
				? 'bg-[var(--primary)] text-[var(--primary-text)] font-semibold'
				: 'text-[var(--text-muted)] hover:bg-[var(--bg-card-hover)] hover:text-[var(--text)]'}"
		>
			{opt.label}
		</button>
	{/each}
</div>
