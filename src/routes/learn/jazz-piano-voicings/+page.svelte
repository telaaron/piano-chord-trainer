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
	<header class="masthead">
		<p class="plate-mark">The complete guide</p>
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
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="types-h">The voicing types</h2>
		</div>
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
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="chords-h">Voicings by chord, in every key</h2>
		</div>
		<p>Pick a chord to see its notes, shell and rootless voicings on an interactive keyboard:</p>

		<!-- The register: every chord page, filed by root -->
		<div class="register">
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
		</div>
	</section>

	<section aria-labelledby="practice-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">III</span>
			<h2 id="practice-h">How to practice voicings</h2>
		</div>
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
	/* ═══ Editorial plate — long-form reading page ════════════════ */
	.hub {
		max-width: 52rem;
		width: 100%;
		margin: 0 auto;
		padding: 2.5rem 1.25rem 5rem;
	}
	@media (min-width: 40rem) {
		.hub { padding: 3.5rem 2.5rem 6rem; }
	}

	/* ── Masthead ── */
	.masthead {
		padding-bottom: 2rem;
		border-bottom: 1px solid var(--border);
	}
	.plate-mark {
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
	.plate-mark::after {
		content: '';
		flex: 1;
		height: 1px;
		background: currentColor;
		opacity: 0.3;
	}

	h1 {
		font-family: var(--font-display);
		font-size: clamp(2rem, 5.4vw, 2.9rem);
		font-weight: 600;
		line-height: 1.08;
		letter-spacing: -0.025em;
		margin: 0;
		max-width: 18ch;
		color: var(--text);
		text-wrap: balance;
	}
	.lead {
		font-size: 1.125rem;
		line-height: 1.65;
		color: var(--text-muted);
		max-width: 54ch;
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
	/* The masthead already rules off below itself — a second hairline here
	   would read as an empty gap rather than as structure. */
	section:first-of-type {
		border-top: 0;
		margin-top: 0;
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
		font-size: clamp(1.4rem, 3.6vw, 1.75rem);
		font-weight: 600;
		line-height: 1.2;
		letter-spacing: -0.02em;
		margin: 0;
		color: var(--text);
	}

	/* ── Body copy: 66ch measure ── */
	section p {
		max-width: 66ch;
		font-size: 1.0625rem;
		line-height: 1.75;
		color: var(--text-muted);
		margin: 0 0 1rem;
	}
	section p a {
		color: var(--primary);
		text-decoration: underline;
		text-underline-offset: 0.15em;
		text-decoration-thickness: 1px;
	}
	section p a:hover { color: var(--primary-hover); }

	/* ── Voicing types: an editorial definition table ── */
	dl {
		margin: 0 0 1.25rem;
		border-top: 1px solid var(--border);
	}
	dl dt {
		font-family: var(--font-display);
		font-size: 1.0625rem;
		font-weight: 600;
		letter-spacing: -0.01em;
		color: var(--text);
		padding-top: 1rem;
		font-variant-numeric: lining-nums;
	}
	dl dd {
		max-width: 62ch;
		margin: 0.3rem 0 0;
		padding-bottom: 1rem;
		border-bottom: 1px solid var(--border);
		font-size: 1rem;
		line-height: 1.7;
		color: var(--text-muted);
	}

	/* ── The register: chord pages filed by root ── */
	.register {
		margin-top: 1.5rem;
		border-top: 1px solid var(--border);
	}
	.key-group {
		display: grid;
		grid-template-columns: 2.5rem minmax(0, 1fr);
		align-items: baseline;
		gap: 0.75rem;
		padding: 0.85rem 0;
		border-bottom: 1px solid var(--border);
	}
	/* Root letter set as a plate key signature */
	.key-group h3 {
		font-family: var(--font-display);
		font-size: 1.125rem;
		font-weight: 600;
		letter-spacing: -0.01em;
		color: var(--ink-blue);
		margin: 0;
	}
	.chord-grid {
		display: flex;
		flex-wrap: wrap;
		gap: 0.35rem 0.5rem;
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.chord-grid a {
		display: inline-block;
		padding: 0.3rem 0.55rem;
		border: 1px solid var(--border);
		border-radius: var(--radius-sm);
		text-decoration: none;
		color: var(--text-muted);
		font-family: var(--font-display);
		font-weight: 600;
		font-size: 0.875rem;
		font-variant-numeric: lining-nums;
		transition: color 0.13s, border-color 0.13s, background 0.13s;
	}
	.chord-grid a:hover {
		color: var(--primary);
		border-color: var(--primary);
		background: var(--primary-muted);
	}
</style>
