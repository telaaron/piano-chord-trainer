<script lang="ts">
	import type { KeyDial } from '$lib/services/progress';
	import { convertNoteName, type NotationSystem } from '$lib/engine';

	/**
	 * The clock — twelve keys on the circle of fifths, each segment sized and
	 * coloured by how long the player's hands need to find that chord.
	 *
	 * It is a diagnosis, not a trophy: the keys you avoid are the keys you are
	 * slow in, and the ring shows both at once. Untouched keys stay hollow
	 * rather than reading as fast, because an unplayed key is not a fast key.
	 *
	 * Data comes from `buildKeyDial()`; nothing here invents numbers.
	 */
	interface Props {
		dial: KeyDial[];
		/** Mastery threshold in ms — the dashed reference ring. */
		thresholdMs?: number;
		/** Outer diameter in px. */
		size?: number;
		/** Dim every key except these roots (used during a session). */
		highlight?: string[];
		/** Show the seconds inside each segment. Off for small sizes. */
		showTimes?: boolean;
		/** Follows the player's own setting — B vs H, as elsewhere in the app. */
		notationSystem?: NotationSystem;
		class?: string;
	}

	let {
		dial,
		thresholdMs = 2000,
		size = 320,
		highlight,
		showTimes = true,
		notationSystem = 'international',
		class: extraClass = '',
	}: Props = $props();

	/** Longest time we scale to. Anything slower pins to the outer edge. */
	const CEIL_MS = 3600;

	const R_OUT = 50;
	const R_IN = 26;
	const CENTRE = 60;

	const slowCount = $derived(
		dial.filter((d) => d.avgMs !== null && d.avgMs > thresholdMs).length,
	);
	const playedCount = $derived(dial.filter((d) => d.count > 0).length);
	const hasData = $derived(playedCount > 0);

	/**
	 * Segment reaches outward in proportion to time. The floor of 0.3 keeps a
	 * fast key a readable band instead of a hairline — being quick should still
	 * look like something, and the colour carries the verdict either way.
	 */
	function radiusFor(avgMs: number | null): number {
		if (avgMs === null) return R_IN + 2;
		const t = Math.min(avgMs, CEIL_MS) / CEIL_MS;
		return R_IN + (R_OUT - R_IN) * Math.max(0.3, t);
	}

	function bandFor(d: KeyDial): string {
		if (d.avgMs === null) return 'none';
		if (d.avgMs <= 1000) return 'fast';
		if (d.avgMs <= thresholdMs) return 'ok';
		if (d.avgMs <= 2600) return 'slow';
		return 'stuck';
	}

	/**
	 * Wedge for slot i, CENTRED on its slot so C sits at twelve o'clock —
	 * the orientation every circle-of-fifths chart uses. Centring here (rather
	 * than running the wedge from i to i+1) is what keeps the key names, the
	 * times and the segments on one radius.
	 */
	function wedge(i: number, r: number): string {
		const step = 360 / 12;
		const gap = 2.4;
		const a0 = ((i * step - step / 2 - 90 + gap / 2) * Math.PI) / 180;
		const a1 = ((i * step + step / 2 - 90 - gap / 2) * Math.PI) / 180;
		const x0 = CENTRE + R_IN * Math.cos(a0);
		const y0 = CENTRE + R_IN * Math.sin(a0);
		const x1 = CENTRE + r * Math.cos(a0);
		const y1 = CENTRE + r * Math.sin(a0);
		const x2 = CENTRE + r * Math.cos(a1);
		const y2 = CENTRE + r * Math.sin(a1);
		const x3 = CENTRE + R_IN * Math.cos(a1);
		const y3 = CENTRE + R_IN * Math.sin(a1);
		return `M ${x0} ${y0} L ${x1} ${y1} A ${r} ${r} 0 0 1 ${x2} ${y2} L ${x3} ${y3} A ${R_IN} ${R_IN} 0 0 0 ${x0} ${y0} Z`;
	}

	/** Point on slot i's centre radius, distance d from the middle. */
	function polar(i: number, d: number): { x: number; y: number } {
		const a = ((i * (360 / 12) - 90) * Math.PI) / 180;
		return { x: CENTRE + d * Math.cos(a), y: CENTRE + d * Math.sin(a) };
	}

	const seconds = (ms: number) => (ms / 1000).toFixed(1).replace('.', ',');

	const isDimmed = (root: string) => !!highlight && !highlight.includes(root);

	/** Respect the notation setting, then typeset b/# as real ♭/♯. */
	const keyLabel = (root: string) =>
		convertNoteName(root, notationSystem).replace('b', '♭').replace('#', '♯');
</script>

<figure class="clock {extraClass}" style="--size:{size}px">
	<svg viewBox="0 0 120 120" role="img" aria-label={hasData
		? `Deine Zeiten in ${playedCount} von 12 Tonarten. ${slowCount} über ${seconds(thresholdMs)} Sekunden.`
		: 'Noch keine Zeiten — zwölf Tonarten warten.'}>
		<!-- Mastery threshold: everything outside this ring is too slow. -->
		<circle
			class="ring-threshold"
			cx={CENTRE}
			cy={CENTRE}
			r={radiusFor(thresholdMs)}
		/>

		{#each dial as d, i (d.root)}
			<path
				class="seg band-{bandFor(d)}"
				class:dim={isDimmed(d.root)}
				d={wedge(i, radiusFor(d.avgMs))}
			/>
		{/each}

		<!-- Key names sit outside the ring, where a circle-of-fifths chart puts them. -->
		{#each dial as d, i (d.root)}
			{@const p = polar(i, R_OUT + 7)}
			<text
				class="label"
				class:dim={isDimmed(d.root)}
				x={p.x}
				y={p.y}
				text-anchor="middle"
				dominant-baseline="central">{keyLabel(d.root)}</text
			>
		{/each}

		{#if showTimes}
			{#each dial as d, i (d.root)}
				<!-- Only label a segment deep enough to hold the digits; a fast key's
				     band is a sliver, and text crammed into it reads as noise. The
				     colour already says "fast", so nothing is lost. -->
				{#if d.avgMs !== null && radiusFor(d.avgMs) - R_IN >= 7}
					{@const p = polar(i, (R_IN + radiusFor(d.avgMs)) / 2)}
					<text
						class="time band-{bandFor(d)}"
						class:dim={isDimmed(d.root)}
						x={p.x}
						y={p.y}
						text-anchor="middle"
						dominant-baseline="central">{seconds(d.avgMs)}</text
					>
				{/if}
			{/each}
		{/if}

		<circle class="hub" cx={CENTRE} cy={CENTRE} r={R_IN - 1} />

		{#if hasData}
			<text class="hub-n" x={CENTRE} y={CENTRE - 4} text-anchor="middle">{slowCount}</text>
			<text class="hub-l" x={CENTRE} y={CENTRE + 7} text-anchor="middle">ÜBER {seconds(thresholdMs)} S</text>
			<text class="hub-l" x={CENTRE} y={CENTRE + 14} text-anchor="middle">VON 12</text>
		{:else}
			<text class="hub-n" x={CENTRE} y={CENTRE - 2} text-anchor="middle">12</text>
			<text class="hub-l" x={CENTRE} y={CENTRE + 9} text-anchor="middle">TONARTEN</text>
		{/if}
	</svg>
</figure>

<style>
	.clock {
		margin: 0;
		width: var(--size);
		max-width: 100%;
	}
	svg {
		display: block;
		width: 100%;
		height: auto;
		overflow: visible;
	}

	.ring-threshold {
		fill: none;
		stroke: var(--text-dim);
		stroke-width: 0.4;
		stroke-dasharray: 1.5 2;
		opacity: 0.55;
	}

	.seg {
		stroke: var(--bg);
		stroke-width: 0.6;
		transition: opacity 0.25s ease;
	}
	/* Bands read as one scale: green is fluent, red is stuck. Untouched keys
	   are hollow so an unplayed key never passes for a fast one. */
	.seg.band-none {
		fill: none;
		stroke: var(--border);
		stroke-width: 0.5;
		stroke-dasharray: 1 1.4;
	}
	.seg.band-fast { fill: var(--accent-green); }
	.seg.band-ok { fill: var(--accent-gold); }
	.seg.band-slow { fill: var(--accent-amber); }
	.seg.band-stuck { fill: var(--primary); }

	.seg.dim,
	.label.dim,
	.time.dim {
		opacity: 0.22;
	}

	.label {
		font-family: var(--font-display);
		font-size: 7px;
		font-weight: 600;
		fill: var(--text);
	}

	.time {
		font-family: var(--font-mono);
		font-size: 4.6px;
		font-weight: 600;
		/* Bands are light enough that near-black stays the legible choice. */
		fill: #14181e;
	}

	.hub {
		fill: var(--bg-card);
		stroke: var(--border);
		stroke-width: 0.5;
	}
	.hub-n {
		font-family: var(--font-display);
		font-size: 15px;
		font-weight: 700;
		fill: var(--text);
	}
	.hub-l {
		font-family: var(--font-mono);
		font-size: 3.6px;
		letter-spacing: 0.09em;
		fill: var(--text-muted);
	}

	@media (prefers-reduced-motion: reduce) {
		.seg { transition: none; }
	}
</style>
