<script lang="ts">
	import { CalendarCheck, Dumbbell, RotateCw, Sparkles, type Icon as LucideIcon } from 'lucide-svelte';

	/**
	 * Unified icon system. Prefers the project's custom .webp art (warm 3D icons),
	 * falls back to a clean Lucide stroke icon where no asset exists — never a raw emoji.
	 *
	 * Usage: <Icon name="warmup" size={44} glow />
	 */
	interface Props {
		name: string;
		/** Pixel size (square). */
		size?: number;
		/** Add a warm drop-shadow glow (for hero/feature tiles). */
		glow?: boolean;
		/** Extra classes on the wrapper. */
		class?: string;
		/** Decorative by default; pass a label to expose to AT. */
		label?: string;
	}

	let { name, size = 24, glow = false, class: extraClass = '', label }: Props = $props();

	/** Semantic key → webp file under /elements/icons (or /elements/images). */
	const WEBP: Record<string, string> = {
		warmup: '/elements/icons/icon-warm-up.webp',
		'weak-spots': '/elements/icons/icon-adaptive-drill.webp',
		adaptive: '/elements/icons/icon-adaptive-drill.webp',
		'ii-v-i': '/elements/icons/icon-piano.webp',
		piano: '/elements/icons/icon-piano.webp',
		speed: '/elements/icons/icon-speed-run.webp',
		explore: '/elements/icons/icon-voicing-drill.webp',
		'voicing-drill': '/elements/icons/icon-voicing-drill.webp',
		challenge: '/elements/icons/icon-challenge.webp',
		progress: '/elements/icons/icon-progress.webp',
		settings: '/elements/icons/icon-settings.webp',
		listen: '/elements/icons/icon-listen.webp',
		mic: '/elements/icons/icon-mic.webp',
		'deep-dive': '/elements/icons/icon-deep-dive.webp',
		cycle: '/elements/icons/icon-cycle.webp',
		'ear-check': '/elements/icons/icon-ear-check.webp',
		inversions: '/elements/icons/icon-inversions.webp',
		'left-hand': '/elements/icons/icon-left-hand.webp',
		'in-time': '/elements/icons/icon-in-time-comping.webp',
		'voice-leading': '/elements/icons/icon-voice-leading-flow.webp',
		'custom-progression': '/elements/icons/icon-custom-progression.webp',
		'personal-best': '/elements/icons/icon-personal-best.webp',
		focus: '/elements/icons/icon-focus.webp',
		turnaround: '/elements/icons/icon-turnaround.webp',
		'note-single': '/elements/icons/icon-note-single.webp',
		'notes-multi': '/elements/icons/icon-notes-multi.webp',
		streak: '/elements/images/streak-flame.webp',
		midi: '/elements/images/midi-connect.webp',
	};

	/** Keys with no custom art → Lucide stroke icon. */
	const LUCIDE: Record<string, typeof LucideIcon> = {
		consistency: CalendarCheck,
		endurance: Dumbbell,
		resume: RotateCw,
		accuracy: Sparkles,
	};

	const webp = $derived(WEBP[name]);
	const Fallback = $derived(LUCIDE[name] ?? Sparkles);
</script>

{#if webp}
	<img
		src={webp}
		alt={label ?? ''}
		aria-hidden={label ? undefined : 'true'}
		width={size}
		height={size}
		loading="lazy"
		class={extraClass}
		style="width:{size}px;height:{size}px;object-fit:contain;mix-blend-mode:lighten;{glow
			? 'filter:drop-shadow(0 0 10px rgba(251,146,60,0.5));'
			: ''}"
	/>
{:else}
	<Fallback
		size={Math.round(size * 0.82)}
		class="text-[var(--primary)] {extraClass}"
		aria-hidden={label ? undefined : 'true'}
		aria-label={label}
	/>
{/if}
