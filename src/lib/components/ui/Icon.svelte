<script lang="ts">
	import {
		Activity,
		ArrowLeftRight,
		BarChart3,
		Brain,
		CalendarCheck,
		Crosshair,
		Dumbbell,
		Ear,
		Flame,
		Gauge,
		Hand,
		Headphones,
		ListMusic,
		Mic,
		Music2,
		Music4,
		Piano,
		Plug,
		RefreshCw,
		Repeat,
		RotateCw,
		Settings2,
		Sparkles,
		Sunrise,
		Target,
		Timer,
		Trophy,
		Waves,
		type Icon as LucideIcon,
	} from 'lucide-svelte';

	/**
	 * Unified icon system — one stroke family across the whole app.
	 *
	 * Call sites name what an icon MEANS ("warmup", "weak-spots"), never which
	 * glyph to draw, so the art direction lives in this one file. It used to
	 * resolve most names to bespoke .webp illustrations; those read as a
	 * different product next to the rest of the UI, so every name now maps to a
	 * Lucide icon and inherits the surrounding colour and stroke weight.
	 *
	 * Usage: <Icon name="warmup" size={44} />
	 */
	interface Props {
		name: string;
		/** Pixel size (square). */
		size?: number;
		/** Add a warm glow — for hero and feature tiles. */
		glow?: boolean;
		/** Extra classes on the icon. */
		class?: string;
		/** Decorative by default; pass a label to expose it to screen readers. */
		label?: string;
	}

	let { name, size = 24, glow = false, class: extraClass = '', label }: Props = $props();

	/** Semantic name → glyph. Keep the keys stable; swap the glyphs freely. */
	const ICONS: Record<string, typeof LucideIcon> = {
		// Practice plans & drills
		warmup: Sunrise,
		'weak-spots': Crosshair,
		adaptive: Brain,
		'ii-v-i': Music4,
		piano: Piano,
		speed: Gauge,
		explore: ListMusic,
		'voicing-drill': ListMusic,
		challenge: Trophy,
		'deep-dive': Waves,
		cycle: Repeat,
		'ear-check': Ear,
		inversions: ArrowLeftRight,
		'left-hand': Hand,
		'in-time': Timer,
		'voice-leading': Activity,
		'custom-progression': ListMusic,
		turnaround: RefreshCw,
		focus: Target,

		// Status & meta
		progress: BarChart3,
		settings: Settings2,
		listen: Headphones,
		mic: Mic,
		'personal-best': Trophy,
		streak: Flame,
		midi: Plug,
		'note-single': Music2,
		'notes-multi': Music4,

		// Habit goals
		consistency: CalendarCheck,
		endurance: Dumbbell,
		resume: RotateCw,
		accuracy: Sparkles,
	};

	const Glyph = $derived(ICONS[name] ?? Sparkles);
</script>

<Glyph
	{size}
	class="text-[var(--primary)] {extraClass}"
	style={glow ? 'filter:drop-shadow(0 0 10px rgba(245,166,35,0.45));' : undefined}
	aria-hidden={label ? undefined : 'true'}
	aria-label={label}
/>
