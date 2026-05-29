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

<div
	role="radiogroup"
	aria-label={label}
	class="inline-flex flex-wrap gap-1 rounded-full border border-[var(--border)]/50 bg-[var(--bg-card)]/50 p-1"
>
	{#each options as opt (opt.value)}
		<button
			type="button"
			role="radio"
			aria-checked={value === opt.value}
			onclick={() => select(opt.value)}
			class="min-h-9 rounded-full px-3.5 text-[var(--text-sm)] font-medium transition-colors
				focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)]
				{value === opt.value
				? 'bg-[var(--primary)] text-white'
				: 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
		>
			{opt.label}
		</button>
	{/each}
</div>
