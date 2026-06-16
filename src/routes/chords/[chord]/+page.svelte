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

	<section class="panel notes-panel" aria-labelledby="notes-h">
		<h2 id="notes-h">The notes in {meta.name}</h2>
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
		<h2 id="voicings-h">{meta.name} voicings on piano</h2>
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

	<section class="panel" aria-labelledby="ctx-h">
		<h2 id="ctx-h">Where {meta.name} fits in a ii-V-I</h2>
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
		<h2 id="faq-h">{meta.name} — frequently asked questions</h2>
		{#each meta.faq as item (item.q)}
			<details>
				<summary>{item.q}</summary>
				<p>{item.a}</p>
			</details>
		{/each}
	</section>

	<aside class="related" aria-labelledby="rel-h">
		<h2 id="rel-h">Keep going</h2>
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
	.chord-page {
		max-width: 780px;
		margin: 0 auto;
		padding: 2.5rem 1.25rem 5rem;
	}

	.crumbs {
		display: flex;
		align-items: center;
		gap: 0.35rem;
		font-size: 0.85rem;
		color: var(--text-dim);
		margin-bottom: 1.75rem;
	}
	.crumbs a {
		color: var(--text-muted);
		text-decoration: none;
	}
	.crumbs a:hover {
		color: var(--primary);
	}

	/* ── Hero ── */
	.hero {
		margin-bottom: 3rem;
	}
	.eyebrow {
		font-size: 0.8rem;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--accent-amber);
		margin: 0 0 0.5rem;
		font-weight: 600;
	}
	.hero h1 {
		font-size: clamp(2rem, 5vw, 3rem);
		line-height: 1.05;
		letter-spacing: -0.02em;
		margin: 0 0 0.9rem;
		font-weight: 800;
	}
	.hero h1 span {
		color: var(--text-muted);
		font-weight: 600;
	}
	.lead {
		font-size: 1.08rem;
		line-height: 1.6;
		color: var(--text-muted);
		max-width: 60ch;
		margin: 0 0 1.5rem;
	}

	/* ── CTA ── */
	.cta {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		background: var(--primary);
		color: var(--primary-text);
		font-weight: 600;
		padding: 0.8rem 1.4rem;
		border-radius: 0.7rem;
		text-decoration: none;
		transition: transform 0.18s cubic-bezier(0.16, 1, 0.3, 1), background 0.18s;
		box-shadow: 0 6px 24px -8px var(--primary);
	}
	.cta:hover {
		background: var(--primary-hover);
		transform: translateY(-2px);
	}

	/* ── Panels & sections ── */
	section {
		margin-top: 3rem;
	}
	.panel {
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: 1rem;
		padding: 1.5rem 1.6rem;
	}
	h2 {
		font-size: 1.45rem;
		letter-spacing: -0.01em;
		margin: 0 0 0.9rem;
		font-weight: 700;
	}
	.section-intro {
		color: var(--text-muted);
		max-width: 60ch;
		margin: 0 0 1.5rem;
		line-height: 1.6;
	}
	.panel p {
		color: var(--text-muted);
		line-height: 1.65;
		margin: 0 0 0.75rem;
	}

	/* ── Notes ── */
	.notes-panel h2 {
		margin-bottom: 1.1rem;
	}
	.note-list {
		display: flex;
		flex-wrap: wrap;
		gap: 0.6rem;
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.note-list li {
		display: flex;
		flex-direction: column;
		align-items: center;
		min-width: 3.3rem;
		padding: 0.6rem 0.4rem;
		background: var(--bg);
		border: 1px solid var(--border);
		border-radius: 0.6rem;
	}
	.note-list .note {
		font-weight: 700;
		font-size: 1.25rem;
		color: var(--text);
	}
	.note-list .interval {
		font-size: 0.72rem;
		color: var(--accent-amber);
		margin-top: 0.15rem;
		font-weight: 600;
	}

	/* ── Voicing cards ── */
	.voicing-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
		gap: 1rem;
	}
	.voicing-card {
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: 1rem;
		padding: 1.1rem 1.2rem 1.3rem;
		transition: border-color 0.18s;
	}
	.voicing-card:hover {
		border-color: var(--border-hover);
	}
	.voicing-head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		margin-bottom: 0.9rem;
	}
	.voicing-head h3 {
		font-size: 1.05rem;
		margin: 0;
		font-weight: 700;
	}
	.play-controls {
		display: flex;
		gap: 0.4rem;
	}
	.play-btn {
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		font-size: 0.8rem;
		font-weight: 600;
		font-family: inherit;
		color: var(--text-muted);
		background: var(--bg);
		border: 1px solid var(--border);
		border-radius: 0.5rem;
		padding: 0.35rem 0.6rem;
		cursor: pointer;
		transition: color 0.15s, border-color 0.15s, background 0.15s, transform 0.1s;
	}
	.play-btn:hover {
		color: var(--text);
		border-color: var(--primary);
	}
	.play-btn:active {
		transform: scale(0.95);
	}
	.play-btn.active {
		color: var(--primary-text);
		background: var(--primary);
		border-color: var(--primary);
	}
	.keyboard {
		margin-bottom: 0.8rem;
	}
	.voicing-notes {
		display: flex;
		flex-direction: column;
		gap: 0.15rem;
		margin: 0;
	}
	.vn-notes {
		font-weight: 700;
		color: var(--text);
		letter-spacing: 0.01em;
	}
	.vn-intervals {
		font-size: 0.82rem;
		color: var(--text-dim);
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

	/* ── FAQ ── */
	.faq details {
		border: 1px solid var(--border);
		border-radius: 0.7rem;
		padding: 0.85rem 1.1rem;
		margin-bottom: 0.6rem;
		background: var(--bg-card);
		transition: border-color 0.15s;
	}
	.faq details[open] {
		border-color: var(--border-hover);
	}
	.faq summary {
		font-weight: 600;
		cursor: pointer;
		list-style: none;
		display: flex;
		justify-content: space-between;
		align-items: center;
	}
	.faq summary::after {
		content: '+';
		color: var(--accent-amber);
		font-size: 1.3rem;
		line-height: 1;
		transition: transform 0.2s;
	}
	.faq details[open] summary::after {
		transform: rotate(45deg);
	}
	.faq p {
		margin: 0.7rem 0 0;
		color: var(--text-muted);
		line-height: 1.6;
	}

	/* ── Related (now obviously cards/links) ── */
	.related-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
		gap: 0.8rem;
	}
	.related-grid a {
		display: grid;
		grid-template-columns: 1fr auto;
		grid-template-rows: auto auto;
		align-items: center;
		gap: 0.1rem 0.6rem;
		padding: 1rem 1.1rem;
		background: var(--bg-card);
		border: 1px solid var(--border);
		border-radius: 0.85rem;
		text-decoration: none;
		transition: border-color 0.18s, transform 0.18s cubic-bezier(0.16, 1, 0.3, 1), background 0.18s;
	}
	.related-grid a:hover {
		border-color: var(--primary);
		transform: translateY(-2px);
	}
	.related-grid a :global(svg) {
		grid-row: 1 / 3;
		grid-column: 2;
		color: var(--primary);
	}
	.rl-title {
		font-weight: 700;
		color: var(--text);
		grid-column: 1;
	}
	.rl-sub {
		font-size: 0.82rem;
		color: var(--text-dim);
		grid-column: 1;
	}
	.related-grid a.rl-accent {
		background: var(--primary-muted);
		border-color: color-mix(in srgb, var(--primary) 40%, transparent);
	}

	@media (prefers-reduced-motion: reduce) {
		.cta:hover,
		.related-grid a:hover {
			transform: none;
		}
	}
</style>
