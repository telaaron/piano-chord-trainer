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
	<header>
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
		<h2 id="ab-h">The two shapes: A and B</h2>
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
		<h2 id="why-h">Why they sound better</h2>
		<p>
			Root-position chords double what the bass already plays and crowd the low
			register, sounding muddy. Rootless voicings move the chord into the clear
			middle of the keyboard and add the ninth, a tension that gives jazz its
			colour. The result is open, modern, and unmistakably professional.
		</p>
	</section>

	<section aria-labelledby="how-h">
		<h2 id="how-h">How to practice them</h2>
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
		<h2>Related</h2>
		<ul>
			<li><a href="/learn/jazz-piano-voicings">Jazz piano voicings — the complete guide</a></li>
			<li><a href="/learn/ii-v-i">The ii-V-I progression in all 12 keys</a></li>
		</ul>
	</aside>
</article>

<style>
	.lesson {
		max-width: 760px;
		margin: 0 auto;
		padding: 2rem 1.25rem 4rem;
	}
	h1 {
		font-size: clamp(1.8rem, 4.5vw, 2.6rem);
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
	section,
	.related {
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
	.steps {
		line-height: 1.8;
		padding-left: 1.2rem;
	}
	.related ul {
		padding-left: 1.1rem;
		line-height: 1.9;
	}
</style>
