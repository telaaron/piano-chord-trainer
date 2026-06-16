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
	<header>
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
		<h2 id="what-h">What is a ii-V-I?</h2>
		<p>
			A ii-V-I is built on the second, fifth and first degrees of a major scale.
			The ii is a minor 7th, the V is a dominant 7th, and the I is a major 7th.
			The dominant chord creates tension; the I resolves it. In C major:
		</p>
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
		<h2 id="why-h">Why drill it in all 12 keys?</h2>
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
		<h2 id="how-h">The fastest way to practice</h2>
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
		<h2>Related</h2>
		<ul>
			<li><a href="/learn/jazz-piano-voicings">Jazz piano voicings — the complete guide</a></li>
			<li><a href="/learn/rootless-voicings">Rootless voicings explained</a></li>
			<li><a href="/chords/cmaj7">Cmaj7 voicings</a> · <a href="/chords/c7">C7 voicings</a> · <a href="/chords/cm7">Cm7 voicings</a></li>
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
	.prog {
		list-style: none;
		padding: 0;
		display: grid;
		gap: 0.6rem;
	}
	.prog li {
		display: grid;
		grid-template-columns: 2.5rem auto 1fr auto;
		align-items: baseline;
		gap: 0.75rem;
		padding: 0.6rem 0.75rem;
		border: 1px solid color-mix(in srgb, currentColor 15%, transparent);
		border-radius: 0.55rem;
	}
	.prog .degree {
		font-weight: 700;
		opacity: 0.6;
	}
	.prog .chord {
		font-weight: 700;
		text-decoration: none;
		color: inherit;
	}
	.prog .shell {
		opacity: 0.8;
	}
	.prog .kind {
		font-size: 0.8rem;
		opacity: 0.55;
	}
	.hint {
		font-size: 0.9rem;
		opacity: 0.7;
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
