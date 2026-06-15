<script lang="ts">
	import { ArrowRight, Music } from 'lucide-svelte';
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

	// Build a ChordWithNotes per voicing so PianoKeyboard can draw it.
	function chordData(voicingNotes: string[]): ChordWithNotes {
		return {
			chord: meta.name,
			root: meta.root,
			type: meta.quality,
			notes,
			voicing: voicingNotes,
		};
	}

	// JSON-LD: FAQPage built from the editorial FAQ.
	const faqSchema = $derived({
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		mainEntity: meta.faq.map((f) => ({
			'@type': 'Question',
			name: f.q,
			acceptedAnswer: { '@type': 'Answer', text: f.a },
		})),
	});

	// JSON-LD: breadcrumb for the chords hub.
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
		<span aria-hidden="true">/</span>
		<span>{meta.name}</span>
	</nav>

	<header class="hero">
		<h1>{meta.name} Piano Voicings</h1>
		<p class="lead">{meta.context}</p>
		<a class="cta" href="/train">
			Drill {meta.name} in all 12 keys
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</header>

	<section aria-labelledby="notes-h">
		<h2 id="notes-h">The notes in {meta.name}</h2>
		<p>
			{meta.longName} ({meta.name}) is built from these notes:
		</p>
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
		<p>
			Each voicing below is the exact shape the trainer drills. The root position
			shows the full chord; the shell and rootless voicings are the working
			left-hand shapes jazz pianists actually use.
		</p>

		{#each voicings as v (v.type)}
			<div class="voicing">
				<h3>{VOICING_LABELS[v.type]}</h3>
				<div class="keyboard">
					<PianoKeyboard chordData={chordData(v.notes)} accidentalPref="flats" showVoicing={true} />
				</div>
				<p class="voicing-notes">
					<Music size={15} aria-hidden="true" />
					{v.notes.join(' – ')}
					<span class="voicing-intervals">({v.intervals.join(' · ')})</span>
				</p>
			</div>
		{/each}
	</section>

	<section aria-labelledby="ctx-h">
		<h2 id="ctx-h">Where {meta.name} fits in a ii-V-I</h2>
		<p>{meta.context}</p>
		<p>
			The fastest way to internalise {meta.name} is to drill it in context across
			all 12 keys until the shape is automatic. <a href="/learn/ii-v-i">Practice the full ii-V-I progression →</a>
		</p>
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
		<ul>
			<li><a href="/learn/rootless-voicings">Master rootless voicings</a></li>
			<li><a href="/learn/jazz-piano-voicings">All jazz piano voicings (hub)</a></li>
			<li><a href="/train">Open the voicing trainer</a></li>
		</ul>
	</aside>
</article>

<style>
	.chord-page {
		max-width: 760px;
		margin: 0 auto;
		padding: 2rem 1.25rem 4rem;
	}
	.crumbs {
		display: flex;
		gap: 0.5rem;
		font-size: 0.85rem;
		opacity: 0.7;
		margin-bottom: 1.5rem;
	}
	.crumbs a {
		color: inherit;
	}
	.hero h1 {
		font-size: clamp(1.75rem, 4vw, 2.5rem);
		line-height: 1.1;
		margin: 0 0 0.75rem;
	}
	.lead {
		font-size: 1.05rem;
		opacity: 0.85;
		margin: 0 0 1.25rem;
	}
	.cta {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		background: var(--accent, #e8763b);
		color: #fff;
		font-weight: 600;
		padding: 0.7rem 1.25rem;
		border-radius: 0.6rem;
		text-decoration: none;
	}
	section,
	.related {
		margin-top: 2.5rem;
	}
	h2 {
		font-size: 1.4rem;
		margin: 0 0 0.75rem;
	}
	h3 {
		font-size: 1.05rem;
		margin: 0 0 0.5rem;
	}
	.note-list {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem;
		list-style: none;
		padding: 0;
	}
	.note-list li {
		display: flex;
		flex-direction: column;
		align-items: center;
		min-width: 3rem;
		padding: 0.5rem;
		border: 1px solid color-mix(in srgb, currentColor 15%, transparent);
		border-radius: 0.5rem;
	}
	.note-list .note {
		font-weight: 700;
		font-size: 1.1rem;
	}
	.note-list .interval {
		font-size: 0.75rem;
		opacity: 0.6;
	}
	.voicing {
		margin-top: 1.5rem;
	}
	.keyboard {
		max-width: 480px;
	}
	.voicing-notes {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		font-weight: 600;
		margin: 0.5rem 0 0;
	}
	.voicing-intervals {
		font-weight: 400;
		opacity: 0.6;
	}
	.faq details {
		border-bottom: 1px solid color-mix(in srgb, currentColor 12%, transparent);
		padding: 0.75rem 0;
	}
	.faq summary {
		font-weight: 600;
		cursor: pointer;
	}
	.faq p {
		margin: 0.5rem 0 0;
		opacity: 0.85;
	}
	.related ul {
		padding-left: 1.1rem;
		line-height: 1.9;
	}
</style>
