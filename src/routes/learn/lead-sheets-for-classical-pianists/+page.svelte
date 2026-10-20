<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';
	import { getChordNotes } from '$lib/engine/voicings';

	const title = 'Lead Sheets for Classical Pianists: Read Chord Symbols Without Freezing | jazzchords.app';
	const description =
		'You can read Chopin but freeze at "Dm7"? Why chord symbols feel hard for classically trained pianists, a cheat sheet for every seventh-chord symbol, and a 4-step path to playing from a lead sheet.';
	const canonical = 'https://jazzchords.app/learn/lead-sheets-for-classical-pianists';

	// Every symbol spelling a classical player will meet for the same five chords,
	// with the notes on C from the trainer's engine.
	const SYMBOLS: { quality: string; names: string; formula: string; slug: string }[] = [
		{ quality: 'Maj7', names: 'Cmaj7 · CΔ · CM7', formula: '1 – 3 – 5 – 7', slug: 'cmaj7' },
		{ quality: '7', names: 'C7', formula: '1 – 3 – 5 – ♭7', slug: 'c7' },
		{ quality: 'm7', names: 'Cm7 · C-7 · Cmin7', formula: '1 – ♭3 – 5 – ♭7', slug: 'cm7' },
		{ quality: 'm7b5', names: 'Cm7♭5 · Cø', formula: '1 – ♭3 – ♭5 – ♭7', slug: 'cm7b5' },
		{ quality: 'dim7', names: 'C°7 · Cdim7', formula: '1 – ♭3 – ♭5 – ♭♭7', slug: '' },
		{ quality: '6', names: 'C6', formula: '1 – 3 – 5 – 6', slug: 'c6' },
		{ quality: 'm6', names: 'Cm6 · C-6', formula: '1 – ♭3 – 5 – 6', slug: 'cm6' },
	];
	const pretty = (n: string) => n.replace(/bb$/, '𝄫').replace('#', '♯').replace(/^([A-G])b/, '$1♭');
	const rows = SYMBOLS.map((s) => ({ ...s, notes: getChordNotes('C', s.quality, 'both').map(pretty) }));

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'Why is playing from a lead sheet hard for classical pianists?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Classical training builds reading: every note is written out, and you translate the page to the keys. A lead sheet only gives the melody and a chord symbol, so you have to recall the chord and choose a voicing in real time. That is a different skill, recall speed, and it improves with targeted practice rather than more reading.',
				},
			},
			{
				'@type': 'Question',
				name: 'What does a chord symbol like Dm7 mean on piano?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'The letter is the root (D), "m" means a minor third, and "7" adds the minor seventh: D, F, A, C. Cmaj7 or CΔ means a major seventh (C E G B), C7 a dominant seventh (C E G B♭), and Cø or Cm7♭5 a half-diminished chord (C E♭ G♭ B♭).',
				},
			},
			{
				'@type': 'Question',
				name: 'What should a classical pianist play with the left hand on a lead sheet?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Start with shell voicings: root, third and seventh. They are only three notes, they sound right in jazz and pop, and they teach you where the third and seventh of every chord sit. When those are automatic, move to rootless voicings (3-5-7-9 and 7-9-3-5).',
				},
			},
		],
	};
</script>

<svelte:head>
	<title>{title}</title>
	<meta name="description" content={description} />
	<link rel="canonical" href={canonical} />
	<link rel="alternate" hreflang="en" href={canonical} />
	<link rel="alternate" hreflang="de" href="https://jazzchords.app/de/leadsheet-spielen-klassik" />
	<link rel="alternate" hreflang="x-default" href={canonical} />
	<meta property="og:type" content="article" />
	<meta property="og:url" content={canonical} />
	<meta property="og:title" content={title} />
	<meta property="og:description" content={description} />
	<meta name="twitter:title" content={title} />
	<meta name="twitter:description" content={description} />
	{@html `<script type="application/ld+json">${JSON.stringify(faqSchema)}</` + `script>`}
</svelte:head>

<article class="lesson">
	<header class="masthead">
		<p class="plate-mark">Classical → Jazz</p>
		<h1>Lead Sheets for Classical Pianists</h1>
		<p class="lead">
			You can play a Chopin nocturne, but a page with one melody line and "Dm7 G7
			Cmaj7" above it makes you freeze. That isn't a talent problem. It's a
			different skill, and it can be trained directly.
		</p>
	</header>

	<section aria-labelledby="why-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">01</span>
			<h2 id="why-h">Why reading doesn't transfer</h2>
		</div>
		<p>
			Classical training is translation: every note is on the page and your eyes
			lead your hands. A lead sheet gives you a melody and a chord symbol, and
			everything else has to come from memory, in time, while you read ahead.
		</p>
		<p>
			So the bottleneck is <strong>recall speed</strong>: seeing "B♭7" and having
			the shape in your hand before the beat arrives. Reading more lead sheets
			helps slowly. Drilling the recall itself helps fast.
		</p>
	</section>

	<section aria-labelledby="symbols-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">02</span>
			<h2 id="symbols-h">Chord symbol cheat sheet</h2>
		</div>
		<p>
			The same chord is written several ways depending on the book. These are the
			seven you will meet on almost every jazz or pop lead sheet, shown on C.
		</p>
		<table class="vt">
			<thead>
				<tr><th scope="col">Symbol</th><th scope="col">Formula</th><th scope="col">On C</th></tr>
			</thead>
			<tbody>
				{#each rows as r (r.quality)}
					<tr>
						<td class="sym">
							{#if r.slug}<a href={`/chords/${r.slug}`}>{r.names}</a>{:else}{r.names}{/if}
						</td>
						<td class="formula">{r.formula}</td>
						<td class="notes">{r.notes.join(' ')}</td>
					</tr>
				{/each}
			</tbody>
		</table>
		<p class="hint">
			Extensions (9, 11, 13) and alterations (♭9, ♯11) sit on top of these. On a
			lead sheet you may leave them out at first; the seventh chord underneath is
			what has to be automatic.
		</p>
	</section>

	<section aria-labelledby="path-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">03</span>
			<h2 id="path-h">A 4-step path from score to lead sheet</h2>
		</div>
		<ol class="steps">
			<li>
				<strong>Left hand: shells.</strong> Root, third and seventh. Learn the five
				main qualities on all 12 roots before touching a tune.
				<a href="/learn/jazz-piano-left-hand">Left-hand voicings</a>
			</li>
			<li>
				<strong>Recall drills, not reading.</strong> Look at a symbol, play the
				shape, next symbol. Random order and random keys, a few minutes a day. Time
				yourself so you can see it getting faster.
			</li>
			<li>
				<strong>The ii-V-I.</strong> Most jazz standards are chains of ii-V-Is.
				Once it is automatic in every key, whole tunes stop being new.
				<a href="/learn/ii-v-i-all-keys">ii-V-I chart, all 12 keys</a>
			</li>
			<li>
				<strong>Then the tune.</strong> Left hand alone in time first, then add the
				melody. Pick a real standard and play it in a second key once it works.
			</li>
		</ol>
		<p>
			Step 2 is the one most players skip, because flash cards and random-key
			lists are tedious to run yourself. The <a href="/train">trainer</a> does it
			for you: it shows a chord symbol, listens through your MIDI keyboard and
			times every chord, so you know which keys still slow you down.
		</p>
		<a class="cta" href="/train">
			Start a free recall drill
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</section>

	<aside class="related">
		<p class="plate-mark blue">Related</p>
		<ul>
			<li><a href="/learn/jazz-piano-voicings">Jazz piano voicings: the complete guide</a></li>
			<li><a href="/learn/rootless-voicings">Rootless voicings: A and B forms</a></li>
			<li><a href="/learn/ii-v-i-all-keys">ii-V-I in all 12 keys (chart)</a></li>
			<li><a href="/learn/jazz-voicing-practice-apps">Apps to practice jazz voicings, compared</a></li>
		</ul>
	</aside>
</article>

<style>
	.lesson { max-width: 52rem; width: 100%; margin: 0 auto; padding: 2.5rem 1.25rem 5rem; }
	@media (min-width: 40rem) { .lesson { padding: 3.5rem 2.5rem 6rem; } }

	.masthead { padding-bottom: 2rem; border-bottom: 1px solid var(--border); }
	.plate-mark {
		display: flex; align-items: center; gap: 0.625rem; margin: 0 0 0.75rem;
		font-family: var(--font-mono); font-size: 0.625rem; letter-spacing: 0.1em;
		text-transform: uppercase; font-weight: 500; color: var(--text-muted);
	}
	.plate-mark::after {
		display: none;
	}
	.plate-mark.blue { color: var(--text-muted); }

	h1 {
		font-family: var(--font-display); font-size: clamp(2rem, 5.4vw, 2.9rem); font-weight: 600;
		line-height: 1.08; letter-spacing: -0.005em; margin: 0; color: var(--text); text-wrap: balance;
	}
	.lead { font-size: 1.125rem; line-height: 1.65; color: var(--text-muted); max-width: 54ch; margin: 1rem 0 0; }

	section { padding-top: 2.75rem; margin-top: 2.75rem; border-top: 1px solid var(--border); }
	section:first-of-type { border-top: 0; margin-top: 0; }
	.sec-head { display: flex; align-items: center; gap: 0.85rem; margin-bottom: 1.1rem; }
	.rehearsal {
		display: inline-block;
		flex: none;
		min-width: 2rem;
		font-family: var(--font-display);
		font-size: 1.5rem;
		font-weight: 400;
		line-height: 1;
		color: var(--accent-gold);
	}
	h2 {
		font-family: var(--font-display); font-size: clamp(1.4rem, 3.6vw, 1.75rem); font-weight: 600;
		line-height: 1.2; letter-spacing: -0.005em; margin: 0; color: var(--text);
	}
	section p { max-width: 66ch; font-size: 1.0625rem; line-height: 1.75; color: var(--text-muted); margin: 0 0 1rem; }
	section p a, .related a {
		color: var(--primary); text-decoration: underline; text-underline-offset: 0.15em; text-decoration-thickness: 1px;
	}
	.hint { font-size: 0.875rem !important; line-height: 1.6 !important; color: var(--text-dim) !important; }

	.steps { max-width: 64ch; margin: 0 0 1.25rem; padding-left: 1.4rem; font-size: 1.0625rem; line-height: 1.75; color: var(--text-muted); }
	.steps li { margin-bottom: 0.5rem; }

	.related { padding-top: 2.5rem; margin-top: 2.75rem; border-top: 1px solid var(--border); }
	.related ul { list-style: none; padding: 0; margin: 0; }
	.related li { padding: 0.55rem 0; font-size: 0.9375rem; color: var(--text-muted); border-bottom: 1px solid var(--border); }
	.related li:last-child { border-bottom: 0; }

	@media print {
		.lesson { padding: 0; max-width: none; }
	}

	.vt { width: 100%; border-collapse: collapse; margin: 0.5rem 0 1rem; }
	.vt th, .vt td { padding: 0.55rem 0.4rem; border-bottom: 1px solid var(--border); text-align: left; vertical-align: top; }
	.vt thead th { font-family: var(--font-mono); font-size: 0.625rem; letter-spacing: 0.14em; text-transform: uppercase; color: var(--text-dim); }
	.vt .sym { font-family: var(--font-display); font-weight: 600; color: var(--text); }
	.vt .sym a { color: var(--text); text-decoration: none; }
	.vt .sym a:hover { color: var(--primary); }
	.vt .formula, .vt .notes { font-family: var(--font-mono); font-size: 0.8125rem; color: var(--text-muted); }
	@media (max-width: 30rem) { .vt th, .vt td { padding: 0.5rem 0.2rem; } .vt .formula { font-size: 0.75rem; } }
	.steps a { color: var(--primary); text-decoration: underline; text-underline-offset: 0.15em; text-decoration-thickness: 1px; margin-left: 0.25rem; }
	.cta {
		display: inline-flex; align-items: center; gap: 0.5rem; min-height: var(--tap-min); padding: 0 1.4rem;
		border: 1.5px solid var(--primary); border-radius: 999px; background: var(--primary);
		color: var(--primary-text); font-weight: 600; text-decoration: none;
	}
	.cta:hover { background: var(--primary-hover); border-color: var(--primary-hover); }
</style>
