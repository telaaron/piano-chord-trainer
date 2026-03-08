<script lang="ts">
	import { t } from '$lib/i18n';

	interface Props {
		/** The short symbol, e.g. "R", "♭3", "ii-V-I" */
		term: string;
		/** Optional i18n key for the tooltip. If omitted, uses glossary map. */
		tip?: string;
	}

	let { term, tip }: Props = $props();

	// ─── Built-in glossary (same data as ExplainPanel + general terms) ───
	const GLOSSARY: Record<string, string> = {
		'R': 'explain.glossary.R',
		'♭2': 'explain.glossary.b2',
		'2': 'explain.glossary.2',
		'♭3': 'explain.glossary.b3',
		'3': 'explain.glossary.3',
		'4': 'explain.glossary.4',
		'♯4': 'explain.glossary.s4',
		'°5': 'explain.glossary.dim5',
		'♭5': 'explain.glossary.b5',
		'5': 'explain.glossary.5',
		'♯5': 'explain.glossary.s5',
		'°7': 'explain.glossary.dim7',
		'6': 'explain.glossary.6',
		'♭7': 'explain.glossary.b7',
		'7': 'explain.glossary.7',
		'♭9': 'explain.glossary.b9',
		'9': 'explain.glossary.9',
		'♯9': 'explain.glossary.s9',
		'11': 'explain.glossary.11',
		'♯11': 'explain.glossary.s11',
		'13': 'explain.glossary.13',
		// General music terms
		'Shell Voicing': 'explain.glossary.Shell Voicing',
		'Rootless': 'explain.glossary.Rootless',
		'ii-V-I': 'explain.glossary.ii-V-I',
		'Terz': 'explain.glossary.Terz',
		'Quinte': 'explain.glossary.Quinte',
		'Septime': 'explain.glossary.Septime',
		'Halbtöne': 'explain.glossary.Halbtöne',
		'Tritonus': 'explain.glossary.Tritonus',
		'Kadenz': 'explain.glossary.Kadenz',
		'Tonika': 'explain.glossary.Tonika',
		'Dominante': 'explain.glossary.Dominante',
		'3rd': 'explain.glossary.3rd',
		'5th': 'explain.glossary.5th',
		'7th': 'explain.glossary.7th',
		'Semitones': 'explain.glossary.Semitones',
		'Tritone': 'explain.glossary.Tritone',
		'Cadence': 'explain.glossary.Cadence',
		'Tonic': 'explain.glossary.Tonic',
		'Dominant': 'explain.glossary.Dominant',
	};

	const resolvedTip = $derived(tip ? t(tip) : GLOSSARY[term] ? t(GLOSSARY[term]) : '');
</script>

{#if resolvedTip}
	<abbr class="music-term" title={resolvedTip}>{term}</abbr>
{:else}
	<span class="music-term-plain">{term}</span>
{/if}

<style>
	.music-term {
		text-decoration: underline dotted var(--text-dim);
		text-underline-offset: 3px;
		text-decoration-thickness: 1px;
		cursor: help;
		font-weight: 600;
		color: var(--accent-amber);
		position: relative;
	}

	/* Tooltip via CSS — works on desktop hover */
	.music-term:hover::after {
		content: attr(title);
		position: absolute;
		bottom: calc(100% + 6px);
		left: 50%;
		transform: translateX(-50%);
		background: var(--bg-elevated, #1a1612);
		color: var(--text);
		border: 1px solid var(--border);
		padding: 4px 10px;
		border-radius: 6px;
		font-size: 0.78rem;
		font-weight: 400;
		white-space: nowrap;
		z-index: 50;
		pointer-events: none;
		box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
	}

	/* Tooltip arrow */
	.music-term:hover::before {
		content: '';
		position: absolute;
		bottom: calc(100% + 2px);
		left: 50%;
		transform: translateX(-50%);
		border: 4px solid transparent;
		border-top-color: var(--border);
		z-index: 51;
		pointer-events: none;
	}

	.music-term-plain {
		font-weight: 600;
		color: var(--accent-amber);
	}
</style>
