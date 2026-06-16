<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';
	import { CHORD_PAGES } from '$lib/seo/chords';

	// Group chord pages by root so the (now ~74-page) index stays scannable.
	const ROOT_ORDER = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
	const chordsByRoot = ROOT_ORDER.map((root) => ({
		root,
		chords: CHORD_PAGES.filter((c) => c.root === root),
	})).filter((g) => g.chords.length > 0);

	const title = 'Jazz Piano Voicings — The Complete Guide (Shell, Rootless, All 12 Keys) | jazzchords.app';
	const description =
		'Learn jazz piano voicings: shell, rootless A/B, and full voicings for every core chord type — with interactive piano diagrams and a free trainer to drill them in all 12 keys.';
	const canonical = 'https://jazzchords.app/learn/jazz-piano-voicings';

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'What is a jazz piano voicing?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'A voicing is a specific arrangement of a chord’s notes. Instead of stacking notes from the root, jazz pianists use shapes like shell voicings (root, third, seventh) and rootless voicings (third, fifth, seventh, ninth) for a richer, more professional sound.',
				},
			},
			{
				'@type': 'Question',
				name: 'What are the most important jazz piano voicings to learn first?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Start with shell voicings (root–third–seventh) for the four core chords — major 7, dominant 7, minor 7 and half-diminished — then move to Bill Evans rootless A and B voicings. Drill each in all 12 keys until automatic.',
				},
			},
		],
	};
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
</svelte:head>

<article class="hub">
	<header>
		<h1>Jazz Piano Voicings: The Complete Guide</h1>
		<p class="lead">
			Every great jazz pianist plays the same chords differently from a beginner.
			The difference is voicings — how the notes of a chord are arranged. This
			guide breaks down shell, rootless and full voicings for every core chord
			type, with an interactive trainer to drill them in all 12 keys.
		</p>
		<a class="cta" href="/train">
			Open the free voicing trainer
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</header>

	<section aria-labelledby="types-h">
		<h2 id="types-h">The voicing types</h2>
		<dl>
			<dt>Shell voicing</dt>
			<dd>Root, third and seventh only. The guide tones (third and seventh) define the chord quality; dropping the fifth keeps it clean. The first voicing to master.</dd>
			<dt>Rootless A &amp; B</dt>
			<dd>Bill Evans’ left-hand shapes: third–fifth–seventh–ninth (A) and seventh–ninth–third–fifth (B). Fuller and more professional, built for a trio where the bassist covers the root.</dd>
			<dt>Full &amp; extended</dt>
			<dd>All chord tones plus tensions (9, 11, 13). Used for solo piano and lush ballad textures.</dd>
		</dl>
		<p><a href="/learn/rootless-voicings">Go deeper on rootless voicings →</a></p>
	</section>

	<section aria-labelledby="chords-h">
		<h2 id="chords-h">Voicings by chord, in every key</h2>
		<p>Pick a chord to see its notes, shell and rootless voicings on an interactive keyboard:</p>
		{#each chordsByRoot as group (group.root)}
			<div class="key-group">
				<h3>{group.root}</h3>
				<ul class="chord-grid">
					{#each group.chords as c (c.slug)}
						<li><a href={`/chords/${c.slug}`}>{c.name}</a></li>
					{/each}
				</ul>
			</div>
		{/each}
	</section>

	<section aria-labelledby="practice-h">
		<h2 id="practice-h">How to practice voicings</h2>
		<p>
			Reading about voicings is not the same as owning them. The goal is muscle
			memory in every key. Drill one voicing type at a time through all 12 roots,
			then combine them into <a href="/learn/ii-v-i">ii-V-I progressions</a>. The
			free trainer measures your reaction time and surfaces your weakest keys.
		</p>
		<a class="cta" href="/train">
			Drill voicings in all 12 keys
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</section>
</article>

<style>
	.hub {
		max-width: 760px;
		margin: 0 auto;
		padding: 2rem 1.25rem 4rem;
	}
	h1 {
		font-size: clamp(1.9rem, 4.5vw, 2.7rem);
		line-height: 1.1;
		margin: 0 0 0.85rem;
	}
	.lead {
		font-size: 1.1rem;
		opacity: 0.85;
		margin: 0 0 1.25rem;
	}
	.cta {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		background: var(--primary);
		color: #fff;
		font-weight: 600;
		padding: 0.7rem 1.25rem;
		border-radius: 0.6rem;
		text-decoration: none;
	}
	section {
		margin-top: 2.5rem;
	}
	h2 {
		font-size: 1.45rem;
		margin: 0 0 0.75rem;
	}
	dl dt {
		font-weight: 700;
		margin-top: 1rem;
	}
	dl dd {
		margin: 0.25rem 0 0;
		opacity: 0.85;
	}
	.key-group {
		margin-top: 1.25rem;
	}
	.key-group h3 {
		font-size: 0.95rem;
		opacity: 0.6;
		margin: 0 0 0.4rem;
		letter-spacing: 0.02em;
	}
	.chord-grid {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem;
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.chord-grid a {
		display: inline-block;
		padding: 0.45rem 0.8rem;
		border: 1px solid color-mix(in srgb, currentColor 15%, transparent);
		border-radius: 0.5rem;
		text-decoration: none;
		color: inherit;
		font-weight: 600;
		font-size: 0.92rem;
	}
</style>
