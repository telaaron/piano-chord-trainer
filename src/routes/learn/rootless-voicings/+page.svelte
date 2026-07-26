<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';

	const title = 'Rootless Voicings for Jazz Piano (Bill Evans A & B Shapes) | jazzchords.app';
	const description =
		'Rootless voicings are the left-hand shapes that make jazz piano sound professional. Learn the Bill Evans A and B voicings, when to use each, and drill them in all 12 keys — free.';
	const canonical = 'https://jazzchords.app/learn/rootless-voicings';

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'What is a rootless voicing in jazz piano?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'A rootless voicing omits the root and uses the third, fifth, seventh and ninth instead. Bill Evans popularised two shapes — Rootless A (3-5-7-9) and Rootless B (7-9-3-5). They sound fuller than root-position chords and work perfectly in a trio where the bassist covers the root.',
				},
			},
			{
				'@type': 'Question',
				name: 'When do you use Rootless A vs Rootless B?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Choose the shape that keeps your hand in the middle of the keyboard and moves the least between chords. A common rule: use Rootless A when the root is in the lower half of the octave and Rootless B when it is in the upper half, so voicings of a ii-V-I connect smoothly.',
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
		<p class="plate-mark">Voicings</p>
		<h1>Rootless Voicings for Jazz Piano</h1>
		<p class="lead">
			Rootless voicings are the single biggest upgrade to your left hand. By
			dropping the root and adding the ninth, you get the fuller, more
			professional sound Bill Evans built his style on — and they leave room for
			the bass to do its job.
		</p>
		<a class="cta" href="/train">
			Drill rootless voicings in all 12 keys
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</header>

	<section aria-labelledby="ab-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="ab-h">The two shapes: A and B</h2>
		</div>
		<dl>
			<dt>Rootless A — 3 · 5 · 7 · 9</dt>
			<dd>Third on the bottom. For Cm9 that is E♭ – G – B♭ – D. Brighter, sits a little higher.</dd>
			<dt>Rootless B — 7 · 9 · 3 · 5</dt>
			<dd>Seventh on the bottom. For Cm9 that is B♭ – D – E♭ – G. Darker, sits a little lower.</dd>
		</dl>
		<p>
			See both shapes drawn on a keyboard for any chord — for example
			<a href="/chords/cm9">Cm9</a>, <a href="/chords/c9">C9</a> or
			<a href="/chords/cmaj9">Cmaj9</a>.
		</p>
	</section>

	<section aria-labelledby="why-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="why-h">Why they sound better</h2>
		</div>
		<p>
			Root-position chords double what the bass already plays and crowd the low
			register, sounding muddy. Rootless voicings move the chord into the clear
			middle of the keyboard and add the ninth, a tension that gives jazz its
			colour. The result is open, modern, and unmistakably professional.
		</p>
	</section>

	<section aria-labelledby="how-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">III</span>
			<h2 id="how-h">How to practice them</h2>
		</div>
		<ol class="steps">
			<li>Learn Rootless A for one chord (try <a href="/chords/cm9">Cm9</a>) until the shape is automatic.</li>
			<li>Learn Rootless B for the same chord.</li>
			<li>Apply both across a <a href="/learn/ii-v-i">ii-V-I progression</a>, choosing the shape that moves the least.</li>
			<li>Cycle through all 12 keys; use the trainer’s weakness analysis to target your slowest.</li>
		</ol>
		<a class="cta" href="/train">
			Start the rootless voicing drill
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</section>

	<aside class="related">
		<p class="plate-mark blue">Related</p>
		<ul>
			<li><a href="/learn/jazz-piano-voicings">Jazz piano voicings — the complete guide</a></li>
			<li><a href="/learn/ii-v-i">The ii-V-I progression in all 12 keys</a></li>
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

	/* ── The two shapes: an editorial definition table ── */
	dl {
		margin: 0 0 1.5rem;
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
	.steps a {
		color: var(--primary);
		text-decoration: underline;
		text-underline-offset: 0.15em;
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
