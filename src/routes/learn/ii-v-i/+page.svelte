<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';

	const title = 'ii-V-I Progression: How to Practice It in All 12 Keys (Piano) | jazzchords.app';
	const description =
		'The ii-V-I is the most important progression in jazz. Learn the theory, the voicings (Dm7–G7–Cmaj7), and the fastest way to drill it in all 12 keys on piano — free.';
	const canonical = 'https://jazzchords.app/learn/ii-v-i';

	// C major ii-V-I, the worked example.
	const example = [
		{ degree: 'ii', chord: 'Dm7', slug: 'cm7', shell: 'D – F – C', note: 'minor 7th' },
		{ degree: 'V', chord: 'G7', slug: 'c7', shell: 'G – B – F', note: 'dominant 7th' },
		{ degree: 'I', chord: 'Cmaj7', slug: 'cmaj7', shell: 'C – E – B', note: 'major 7th' },
	];

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'What is a ii-V-I progression?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'A ii-V-I is a three-chord progression built on the second, fifth and first degrees of a major scale. In C major it is Dm7–G7–Cmaj7. It is the backbone of jazz harmony because it sets up tension (V) and resolves it (I).',
				},
			},
			{
				'@type': 'Question',
				name: 'How do you practice ii-V-I in all 12 keys?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Drill the progression one key at a time using shell or rootless voicings until each is automatic, then cycle through all 12 keys — often around the circle of fourths. A speed-drill tool with a metronome and weakness analysis makes this far faster than playing along to a backing track.',
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

<article class="lesson">
	<header class="masthead">
		<p class="plate-mark">Progression</p>
		<h1>The ii-V-I Progression — and How to Drill It in All 12 Keys</h1>
		<p class="lead">
			If you learn one thing in jazz harmony, learn the ii-V-I. It is the single
			most common progression in the repertoire, and fluency in all 12 keys is
			what separates players who can read changes from players who can play them.
		</p>
		<a class="cta" href="/train">
			Drill ii-V-I in all 12 keys
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</header>

	<section aria-labelledby="what-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="what-h">What is a ii-V-I?</h2>
		</div>
		<p>
			A ii-V-I is built on the second, fifth and first degrees of a major scale.
			The ii is a minor 7th, the V is a dominant 7th, and the I is a major 7th.
			The dominant chord creates tension; the I resolves it. In C major:
		</p>

		<!-- The worked example, set as a lead-sheet analysis strip -->
		<ol class="prog">
			{#each example as step (step.chord)}
				<li>
					<span class="degree">{step.degree}</span>
					<a class="chord" href={`/chords/${step.slug}`}>{step.chord}</a>
					<span class="shell">{step.shell}</span>
					<span class="kind">{step.note}</span>
				</li>
			{/each}
		</ol>
		<p class="hint">Each shell voicing above is root–third–seventh. Tap a chord to see its full voicings.</p>
	</section>

	<section aria-labelledby="why-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="why-h">Why drill it in all 12 keys?</h2>
		</div>
		<p>
			Real tunes modulate. A single jazz standard can run ii-V-I figures through
			five or six keys. If you only know it in C, you freeze the moment the music
			moves. Drilling all 12 keys turns the progression into muscle memory, so you
			react instead of calculate.
		</p>
		<p>
			Use <a href="/learn/rootless-voicings">rootless voicings</a> once the shell
			shapes are solid — they sound fuller and free up your right hand for melody.
		</p>
	</section>

	<section aria-labelledby="how-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">III</span>
			<h2 id="how-h">The fastest way to practice</h2>
		</div>
		<ol class="steps">
			<li>Play the ii-V-I in C with shell voicings until it is effortless.</li>
			<li>Move around the circle of fourths: C → F → B♭ → E♭ …</li>
			<li>Switch to rootless A and B voicings for a professional sound.</li>
			<li>Use the trainer’s weakness analysis to find your three slowest keys, then drill only those.</li>
		</ol>
		<a class="cta" href="/train">
			Start the ii-V-I speed drill
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</section>

	<aside class="related">
		<p class="plate-mark blue">Related</p>
		<ul>
			<li><a href="/learn/jazz-piano-voicings">Jazz piano voicings — the complete guide</a></li>
			<li><a href="/learn/rootless-voicings">Rootless voicings explained</a></li>
			<li><a href="/chords/cmaj7">Cmaj7 voicings</a> · <a href="/chords/c7">C7 voicings</a> · <a href="/chords/cm7">Cm7 voicings</a></li>
		</ul>
	</aside>
</article>

<style>
	/* ═══ Editorial plate — long-form reading page ════════════════ */
	.lesson {
		max-width: 52rem;
		width: 100%;
		margin: 0 auto;
		padding: 2.5rem 1.25rem 5rem;
	}
	@media (min-width: 40rem) {
		.lesson { padding: 3.5rem 2.5rem 6rem; }
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
	.plate-mark.blue { color: var(--ink-blue); }

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
	section p a,
	.related a {
		color: var(--primary);
		text-decoration: underline;
		text-underline-offset: 0.15em;
		text-decoration-thickness: 1px;
	}
	section p a:hover,
	.related a:hover { color: var(--primary-hover); }

	/* ── The progression: a lead-sheet analysis strip ── */
	.prog {
		list-style: none;
		padding: 0;
		margin: 1.5rem 0 0.9rem;
		border-top: 1px solid var(--border);
	}
	.prog li {
		display: grid;
		grid-template-columns: 2.25rem minmax(0, auto) minmax(0, 1fr) auto;
		align-items: baseline;
		gap: 0.85rem;
		padding: 0.8rem 0.25rem;
		border-bottom: 1px solid var(--border);
	}
	/* Roman numeral analysis — copyist blue, as on a marked-up chart */
	.prog .degree {
		font-family: var(--font-display);
		font-size: 1rem;
		font-weight: 700;
		font-style: italic;
		color: var(--ink-blue);
	}
	.prog .chord {
		font-family: var(--font-display);
		font-size: 1.1875rem;
		font-weight: 600;
		letter-spacing: -0.01em;
		text-decoration: none;
		color: var(--text);
		font-variant-numeric: lining-nums;
	}
	.prog .chord:hover {
		color: var(--primary);
	}
	.prog .shell {
		font-family: var(--font-mono);
		font-size: 0.8125rem;
		color: var(--text-muted);
	}
	.prog .kind {
		font-family: var(--font-mono);
		font-size: 0.5875rem;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--text-dim);
		white-space: nowrap;
	}
	@media (max-width: 30rem) {
		.prog li {
			grid-template-columns: 2rem minmax(0, 1fr);
			row-gap: 0.2rem;
		}
		.prog .shell,
		.prog .kind { grid-column: 2; }
	}

	.hint {
		font-size: 0.875rem !important;
		line-height: 1.6 !important;
		color: var(--text-dim) !important;
		max-width: 60ch;
	}

	/* ── Steps: numbered instructions ── */
	.steps {
		max-width: 64ch;
		margin: 0 0 1.75rem;
		padding-left: 1.4rem;
		font-size: 1.0625rem;
		line-height: 1.75;
		color: var(--text-muted);
	}
	.steps li { margin-bottom: 0.5rem; }
	.steps li::marker {
		font-family: var(--font-mono);
		font-size: 0.8125rem;
		color: var(--ink-blue);
	}
	/* ── Related ── */
	.related {
		padding-top: 2.5rem;
		margin-top: 2.75rem;
		border-top: 1px solid var(--border);
	}
	.related ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.related li {
		padding: 0.55rem 0;
		font-size: 0.9375rem;
		line-height: 1.5;
		color: var(--text-muted);
		border-bottom: 1px solid var(--border);
	}
	.related li:last-child { border-bottom: 0; }
</style>
