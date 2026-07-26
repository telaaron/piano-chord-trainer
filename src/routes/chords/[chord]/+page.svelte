<script lang="ts">
	import { ArrowRight, Play, AudioWaveform, ChevronRight } from 'lucide-svelte';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import { VOICING_LABELS } from '$lib/engine/chords';
	import type { ChordWithNotes } from '$lib/engine/voicings';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	const meta = $derived(data.meta);
	const notes = $derived(data.notes);
	const formula = $derived(data.formula);
	const voicings = $derived(data.voicings);

	const title = $derived(`${meta.name} Piano Voicings — Notes, Shell & Rootless | jazzchords.app`);
	const description = $derived(meta.blurb);
	const canonical = $derived(`https://jazzchords.app/chords/${meta.slug}`);

	function chordData(voicingNotes: string[]): ChordWithNotes {
		return { chord: meta.name, root: meta.root, type: meta.quality, notes, voicing: voicingNotes };
	}

	// Audio is loaded lazily on first interaction so it never blocks prerender
	// or the initial load. Tone.js only enters the bundle when a button is hit.
	let playing = $state<string | null>(null);

	async function playBlock(key: string, voicingNotes: string[]) {
		playing = key;
		const { playChord } = await import('$lib/services/audio');
		await playChord(voicingNotes, '1n');
		setTimeout(() => { if (playing === key) playing = null; }, 900);
	}

	async function playArp(key: string, voicingNotes: string[]) {
		playing = key + '-arp';
		const { playArpeggio } = await import('$lib/services/audio');
		await playArpeggio(voicingNotes, 200, '2n');
		setTimeout(() => { if (playing === key + '-arp') playing = null; }, voicingNotes.length * 200 + 400);
	}

	const faqSchema = $derived({
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		mainEntity: meta.faq.map((f) => ({
			'@type': 'Question',
			name: f.q,
			acceptedAnswer: { '@type': 'Answer', text: f.a },
		})),
	});

	const breadcrumbSchema = $derived({
		'@context': 'https://schema.org',
		'@type': 'BreadcrumbList',
		itemListElement: [
			{ '@type': 'ListItem', position: 1, name: 'Jazz Piano Voicings', item: 'https://jazzchords.app/learn/jazz-piano-voicings' },
			{ '@type': 'ListItem', position: 2, name: `${meta.name} Voicings`, item: canonical },
		],
	});
</script>

<svelte:head>
	<title>{title}</title>
	<meta name="description" content={description} />
	<link rel="canonical" href={canonical} />
	<meta property="og:type" content="article" />
	<meta property="og:url" content={canonical} />
	<meta property="og:title" content={title} />
	<meta property="og:description" content={description} />
	<meta property="og:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content={title} />
	<meta name="twitter:description" content={description} />
	<meta name="twitter:image" content="https://jazzchords.app/seo/OG-image.webp" />
	{@html `<script type="application/ld+json">${JSON.stringify(faqSchema)}</` + `script>`}
	{@html `<script type="application/ld+json">${JSON.stringify(breadcrumbSchema)}</` + `script>`}
</svelte:head>

<article class="chord-page">
	<nav class="crumbs" aria-label="Breadcrumb">
		<a href="/learn/jazz-piano-voicings">Jazz Piano Voicings</a>
		<ChevronRight size={13} aria-hidden="true" />
		<span aria-current="page">{meta.name}</span>
	</nav>

	<header class="hero">
		<p class="eyebrow">{meta.longName}</p>
		<h1>{meta.name} <span>Piano Voicings</span></h1>
		<p class="lead">{meta.context}</p>
		<a class="cta" href="/train">
			Drill {meta.name} in all 12 keys
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</header>

	<section class="notes-panel" aria-labelledby="notes-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="notes-h">The notes in {meta.name}</h2>
		</div>
		<!-- Note / interval analysis — blue does the labelling -->
		<ul class="note-list">
			{#each notes as note, i (note + i)}
				<li>
					<span class="note">{note}</span>
					<span class="interval">{formula[i] ?? ''}</span>
				</li>
			{/each}
		</ul>
	</section>

	<section aria-labelledby="voicings-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="voicings-h">{meta.name} voicings on piano</h2>
		</div>
		<p class="section-intro">
			Each voicing is the exact shape the trainer drills. Press play to hear it —
			as a block chord or rolled note by note.
		</p>

		<div class="voicing-grid">
			{#each voicings as v (v.type)}
				<div class="voicing-card">
					<div class="voicing-head">
						<h3>{VOICING_LABELS[v.type]}</h3>
						<div class="play-controls">
							<button
								class="play-btn"
								class:active={playing === v.type}
								onclick={() => playBlock(v.type, v.notes)}
								aria-label={`Play ${VOICING_LABELS[v.type]} as a block chord`}
							>
								<Play size={15} aria-hidden="true" /> Chord
							</button>
							<button
								class="play-btn"
								class:active={playing === v.type + '-arp'}
								onclick={() => playArp(v.type, v.notes)}
								aria-label={`Play ${VOICING_LABELS[v.type]} as an arpeggio`}
							>
								<AudioWaveform size={15} aria-hidden="true" /> Arp
							</button>
						</div>
					</div>
					<div class="keyboard">
						<PianoKeyboard chordData={chordData(v.notes)} accidentalPref="both" showVoicing={true} />
					</div>
					<p class="voicing-notes">
						<span class="vn-notes">{v.notes.join(' · ')}</span>
						<span class="vn-intervals">{v.intervals.join(' · ')}</span>
					</p>
				</div>
			{/each}
		</div>
	</section>

	<section aria-labelledby="ctx-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">III</span>
			<h2 id="ctx-h">Where {meta.name} fits in a ii-V-I</h2>
		</div>
		<p>{meta.context}</p>
		<p>
			The fastest way to internalise {meta.name} is to drill it in context across
			all 12 keys until the shape is automatic.
		</p>
		<a class="text-link" href="/learn/ii-v-i">
			Practice the full ii-V-I progression
			<ArrowRight size={15} aria-hidden="true" />
		</a>
	</section>

	<section aria-labelledby="faq-h" class="faq">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">IV</span>
			<h2 id="faq-h">{meta.name} — frequently asked questions</h2>
		</div>
		{#each meta.faq as item (item.q)}
			<details>
				<summary>{item.q}</summary>
				<p>{item.a}</p>
			</details>
		{/each}
	</section>

	<aside class="related" aria-labelledby="rel-h">
		<h2 id="rel-h" class="plate-mark blue">Keep going</h2>
		<div class="related-grid">
			<a href="/learn/rootless-voicings">
				<span class="rl-title">Master rootless voicings</span>
				<span class="rl-sub">The Bill Evans left-hand shapes</span>
				<ArrowRight size={16} aria-hidden="true" />
			</a>
			<a href="/learn/jazz-piano-voicings">
				<span class="rl-title">All jazz piano voicings</span>
				<span class="rl-sub">The complete guide & every chord</span>
				<ArrowRight size={16} aria-hidden="true" />
			</a>
			<a href="/train" class="rl-accent">
				<span class="rl-title">Open the voicing trainer</span>
				<span class="rl-sub">Drill {meta.name} in all 12 keys — free</span>
				<ArrowRight size={16} aria-hidden="true" />
			</a>
		</div>
	</aside>
</article>

<style>
	/* ═══ Editorial plate — a chord's printed entry ═══════════════ */
	.chord-page {
		max-width: 46rem;
		width: 100%;
		margin: 0 auto;
		padding: 2.5rem 1.25rem 5rem;
	}
	@media (min-width: 40rem) {
		.chord-page { padding: 3rem 2rem 6rem; }
	}

	/* ── Breadcrumb ── */
	.crumbs {
		display: flex;
		align-items: center;
		gap: 0.3rem;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.13em;
		text-transform: uppercase;
		color: var(--text-dim);
		margin-bottom: 1.75rem;
	}
	.crumbs a {
		color: var(--text-muted);
		text-decoration: none;
		transition: color 0.15s;
	}
	.crumbs a:hover {
		color: var(--primary);
	}

	/* ── Masthead ──
	   No bottom rule here: the first <section> already draws its own top
	   hairline, and two rules with dead space between them read as a gap,
	   not as structure. */
	.hero {
		padding-bottom: 0;
	}
	.eyebrow {
		display: flex;
		align-items: center;
		gap: 0.625rem;
		margin: 0 0 0.75rem;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.19em;
		text-transform: uppercase;
		font-weight: 600;
		color: var(--primary);
	}
	.eyebrow::after {
		content: '';
		flex: 1;
		height: 1px;
		background: currentColor;
		opacity: 0.3;
	}
	/* The chord symbol is the headline — set it as one */
	.hero h1 {
		font-family: var(--font-display);
		font-size: clamp(2.25rem, 6.4vw, 3.25rem);
		line-height: 1.04;
		letter-spacing: -0.03em;
		margin: 0;
		font-weight: 600;
		color: var(--text);
		font-variant-numeric: lining-nums;
		text-wrap: balance;
	}
	.hero h1 span {
		color: var(--text-muted);
		font-weight: 400;
		font-style: italic;
	}
	.lead {
		font-size: 1.0625rem;
		line-height: 1.7;
		color: var(--text-muted);
		max-width: 60ch;
		margin: 1rem 0 1.75rem;
	}

	/* ── CTA ── */
	.cta {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		min-height: var(--tap-min);
		padding: 0 1.4rem;
		border: 1.5px solid var(--primary);
		border-radius: var(--radius-sm);
		background: var(--primary);
		color: var(--primary-text);
		font-weight: 600;
		text-decoration: none;
		transition: background 0.15s, border-color 0.15s;
	}
	.cta:hover {
		background: var(--primary-hover);
		border-color: var(--primary-hover);
	}

	/* ── Sections, numbered ── */
	section {
		padding-top: 2.75rem;
		margin-top: 2.75rem;
		border-top: 1px solid var(--border);
	}
	.sec-head {
		display: flex;
		align-items: center;
		gap: 0.85rem;
		margin-bottom: 1.1rem;
	}
	.rehearsal {
		display: grid;
		place-items: center;
		flex: none;
		min-width: 1.65rem;
		height: 1.65rem;
		padding: 0 0.35rem;
		border: 1.5px solid var(--text);
		font-family: var(--font-mono);
		font-size: 0.6875rem;
		font-weight: 700;
		color: var(--text);
	}
	h2 {
		font-family: var(--font-display);
		font-size: clamp(1.35rem, 3.6vw, 1.7rem);
		line-height: 1.2;
		letter-spacing: -0.02em;
		margin: 0;
		font-weight: 600;
		color: var(--text);
	}
	section p {
		max-width: 66ch;
		color: var(--text-muted);
		font-size: 1.0625rem;
		line-height: 1.75;
		margin: 0 0 1rem;
	}
	.section-intro {
		max-width: 62ch;
		margin: 0 0 1.75rem !important;
	}

	/* ── Notes: the chord spelled out, blue for the analysis ── */
	.note-list {
		display: flex;
		flex-wrap: wrap;
		gap: 0;
		list-style: none;
		padding: 0;
		margin: 0;
		border-top: 1px solid var(--border);
		border-bottom: 1px solid var(--border);
	}
	.note-list li {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.2rem;
		min-width: 4rem;
		padding: 0.9rem 0.85rem;
		border-right: 1px solid var(--border);
	}
	.note-list li:last-child { border-right: 0; }
	.note-list .note {
		font-family: var(--font-display);
		font-weight: 600;
		font-size: 1.5rem;
		line-height: 1;
		letter-spacing: -0.02em;
		color: var(--text);
		font-variant-numeric: lining-nums;
	}
	.note-list .interval {
		font-family: var(--font-mono);
		font-size: 0.5875rem;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--ink-blue);
	}

	/* ── Voicing plates ── */
	.voicing-grid {
		display: grid;
		grid-template-columns: 1fr;
		gap: 0;
		border-top: 1px solid var(--border);
	}
	.voicing-card {
		padding: 1.25rem 0 1.5rem;
		border-bottom: 1px solid var(--border);
	}
	.voicing-head {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		margin-bottom: 1rem;
	}
	.voicing-head h3 {
		font-family: var(--font-display);
		font-size: 1.125rem;
		margin: 0;
		font-weight: 600;
		letter-spacing: -0.01em;
		color: var(--text);
	}
	.play-controls {
		display: flex;
		gap: 0.4rem;
	}
	.play-btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.35rem;
		/* WCAG 2.2 target size — these are the page's only real controls */
		min-height: var(--tap-min);
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.11em;
		text-transform: uppercase;
		font-weight: 600;
		color: var(--text-muted);
		background: transparent;
		border: 1px solid var(--border);
		border-radius: var(--radius-sm);
		padding: 0 0.85rem;
		cursor: pointer;
		transition: color 0.15s, border-color 0.15s, background 0.15s;
	}
	.play-btn:hover {
		color: var(--text);
		border-color: var(--border-hover);
	}
	/* Sounding right now — the one amber on this page */
	.play-btn.active {
		color: var(--accent-amber);
		border-color: var(--accent-amber);
		background: var(--warning-muted);
	}
	.keyboard {
		margin-bottom: 0.9rem;
	}
	.voicing-notes {
		display: flex;
		flex-wrap: wrap;
		align-items: baseline;
		gap: 0.3rem 1rem;
		margin: 0;
	}
	.vn-notes {
		font-family: var(--font-display);
		font-weight: 600;
		font-size: 1.0625rem;
		color: var(--text);
		font-variant-numeric: lining-nums;
	}
	.vn-intervals {
		font-family: var(--font-mono);
		font-size: 0.6875rem;
		letter-spacing: 0.1em;
		color: var(--ink-blue);
	}

	/* ── Inline text link ── */
	.text-link {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		color: var(--primary);
		font-weight: 600;
		text-decoration: none;
		margin-top: 0.25rem;
	}
	.text-link:hover {
		text-decoration: underline;
		text-underline-offset: 3px;
	}

	/* ── FAQ: a printed Q&A list, not a stack of cards ── */
	.faq details {
		border-bottom: 1px solid var(--border);
		padding: 0.9rem 0;
	}
	.faq details:first-of-type {
		border-top: 1px solid var(--border);
	}
	.faq summary {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 1rem;
		font-family: var(--font-display);
		font-size: 1.0625rem;
		font-weight: 600;
		letter-spacing: -0.01em;
		color: var(--text);
		cursor: pointer;
		list-style: none;
	}
	.faq summary::-webkit-details-marker { display: none; }
	.faq summary:hover { color: var(--primary); }
	.faq summary::after {
		content: '+';
		flex: none;
		font-family: var(--font-mono);
		color: var(--primary);
		font-size: 1.1rem;
		line-height: 1;
		transition: transform 0.2s;
	}
	.faq details[open] summary::after {
		transform: rotate(45deg);
	}
	.faq p {
		max-width: 66ch;
		margin: 0.75rem 0 0.25rem;
		color: var(--text-muted);
		font-size: 1rem;
		line-height: 1.7;
	}

	/* ── Related ── */
	.related {
		padding-top: 2.5rem;
		margin-top: 2.75rem;
		border-top: 1px solid var(--border);
	}
	.plate-mark {
		display: flex;
		align-items: center;
		gap: 0.625rem;
		margin: 0 0 1rem;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.19em;
		text-transform: uppercase;
		font-weight: 600;
	}
	.plate-mark::after {
		content: '';
		flex: 1;
		height: 1px;
		background: currentColor;
		opacity: 0.3;
	}
	.plate-mark.blue { color: var(--ink-blue); }

	.related-grid {
		display: grid;
		grid-template-columns: 1fr;
		gap: 0;
		border-top: 1px solid var(--border);
	}
	.related-grid a {
		display: grid;
		grid-template-columns: minmax(0, 1fr) auto;
		grid-template-rows: auto auto;
		align-items: center;
		gap: 0.1rem 0.75rem;
		padding: 0.9rem 0.25rem;
		border-bottom: 1px solid var(--border);
		text-decoration: none;
		transition: background 0.13s, padding 0.13s;
	}
	.related-grid a:hover {
		background: var(--bg-card);
		padding-left: 0.6rem;
		padding-right: 0.6rem;
	}
	.related-grid a :global(svg) {
		grid-row: 1 / 3;
		grid-column: 2;
		color: var(--primary);
	}
	.rl-title {
		font-family: var(--font-display);
		font-size: 1rem;
		font-weight: 600;
		letter-spacing: -0.01em;
		color: var(--text);
		grid-column: 1;
	}
	.rl-sub {
		font-size: 0.8125rem;
		color: var(--text-dim);
		grid-column: 1;
	}
	/* The trainer link — stamped, since it is the page's real action */
	.related-grid a.rl-accent {
		box-shadow: inset 2px 0 0 var(--primary);
		padding-left: 0.75rem;
	}
	.related-grid a.rl-accent:hover {
		background: var(--primary-muted);
		padding-left: 0.9rem;
	}
</style>
