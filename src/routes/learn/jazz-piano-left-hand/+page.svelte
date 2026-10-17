<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';
	import { buildIIVITable, type IIVIVoicing } from '$lib/seo/ii-v-i-keys';

	const title = 'What to Play With the Left Hand in Jazz Piano: Shell and Rootless Voicings | jazzchords.app';
	const description =
		'Left hand stuck on roots and octaves, or sounding boring? Get to real jazz voicings in two steps (shells, then rootless A/B), put them in time with the Charleston rhythm, and practise them in all 12 keys.';
	const canonical = 'https://jazzchords.app/learn/jazz-piano-left-hand';
	const deUrl = 'https://jazzchords.app/de/voicings-linke-hand';

	// Example voicings come from the trainer's engine (ii-V-I in C), so the page
	// shows exactly what the drill will ask for.
	const EXAMPLES: { id: IIVIVoicing; label: string; formula: string }[] = [
		{ id: 'shell', label: 'Shell', formula: '1 – 3 – 7' },
		{ id: 'rootless-ab', label: 'Rootless A → B', formula: 'A: 3 – 5 – 7 – 9 · B: 7 – 9 – 3 – 5' },
	];
	const rowsFor = (id: IIVIVoicing) => buildIIVITable(id)[0].chords;
	const pretty = (n: string) => n.replace('#', '♯').replace(/^([A-G])b/, '$1♭');

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'What should the left hand play in jazz piano?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Instead of roots or octaves, the left hand usually plays voicings: compact shapes built from the third and seventh (shell voicings) or, with a bass player, rootless voicings from the third, fifth, seventh and ninth. The right hand plays the melody or improvises on top.',
				},
			},
			{
				'@type': 'Question',
				name: 'Why does my left hand sound boring in jazz?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Usually for two reasons: it plays root-heavy shapes that sound like pop or classical accompaniment, and it plays on every beat. Switching to shell or rootless voicings fixes the sound; playing short chords on off-beats, for example the Charleston rhythm (beat 1 and the "and" of 2), fixes the feel.',
				},
			},
			{
				'@type': 'Question',
				name: 'What is the Charleston rhythm in jazz piano comping?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'A two-hit comping pattern: a short chord on beat 1, then the same chord on the "and" of beat 2, then silence for the rest of the bar. It is the most common first comping rhythm because it leaves space for the melody and makes the left hand swing.',
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
	<link rel="alternate" hreflang="de" href={deUrl} />
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
		<p class="plate-mark">Voicings · left hand</p>
		<h1>What to Play With the Left Hand in Jazz Piano</h1>
		<p class="lead">
			If your left hand only plays roots and octaves, jazz quickly sounds like a pop
			ballad. The fix is voicings: small shapes made of the notes that actually define
			each chord, played in time. Here is the path in three steps.
		</p>
	</header>

	<section aria-labelledby="why-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="why-h">Why the third and seventh are enough</h2>
		</div>
		<p>
			Whether a chord is major seventh, minor seventh or dominant, you hear it in two
			notes: the third and the seventh. The fifth is the same in almost every chord and
			can go, and a bass player usually covers the root. That reduction is what makes
			jazz voicings compact and leaves room for the right hand.
		</p>
	</section>

	<section aria-labelledby="levels-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="levels-h">Two levels, shown on ii-V-I in C</h2>
		</div>
		{#each EXAMPLES as ex (ex.id)}
			<h3>{ex.label} <span class="formula">{ex.formula}</span></h3>
			<table class="vt">
				<thead>
					<tr><th scope="col">Degree</th><th scope="col">Chord</th><th scope="col">Notes (bottom → top)</th></tr>
				</thead>
				<tbody>
					{#each rowsFor(ex.id) as ch (ch.degree)}
						<tr>
							<td class="deg">{ch.degree}</td>
							<td>
								{#if ch.slug}<a href={`/chords/${ch.slug}`}>{ch.name}</a>{:else}{ch.name}{/if}
							</td>
							<td class="notes">{ch.notes.map(pretty).join(' ')}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		{/each}
		<p>
			<strong>Level 1, shells:</strong> while you play solo, the left hand keeps the root
			at the bottom. Three notes, instantly jazzy, and you learn where the third and
			seventh sit in every chord.
		</p>
		<p>
			<strong>Level 2, rootless:</strong> once the root comes from somewhere else (bass,
			band or your right hand), drop it and add the ninth. The A and B forms alternate,
			so your hand stays in the middle of the keyboard.
		</p>
		<p>
			All twelve keys, with notes and audio, are in the
			<a href="/learn/ii-v-i-all-keys">ii-V-I chart for all 12 keys</a>.
		</p>
	</section>

	<section aria-labelledby="time-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">III</span>
			<h2 id="time-h">Put it in time: the Charleston rhythm</h2>
		</div>
		<p>
			The right notes on every beat still sound stiff. Start with the Charleston: a
			short chord on beat 1, the same chord on the "and" of 2, then rest until the next
			bar. It leaves space for the melody and makes the left hand swing.
		</p>
		<p class="count" aria-label="Count: one hit, and-of-two hit, rest on three and four">
			<span class="hit">1</span> + 2 <span class="hit">+</span> 3 + 4 +
		</p>
		<p>
			Practise it with a metronome on 2 and 4, first on one ii-V-I, then through the
			keys. When the Charleston is easy, try anticipations: play the next chord on the
			"and" of 4 just before the bar line.
		</p>
	</section>

	<section aria-labelledby="practice-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">IV</span>
			<h2 id="practice-h">Practise without the drudgery</h2>
		</div>
		<ol class="steps">
			<li>Ten minutes a day beats an hour once a week. Voicings are reflexes, not theory.</li>
			<li>Shells in all keys first, then rootless. Don't start both at once.</li>
			<li>Don't look: read the chord symbol, play the shape, next symbol.</li>
			<li>Time yourself. The key you hesitate in is tomorrow's key.</li>
		</ol>
		<p>
			The catch with practising alone: you can't tell whether you're getting faster.
			The <a href="/train">trainer</a> shows a chord symbol, listens through your MIDI
			keyboard and measures how long each shape takes you.
		</p>
		<a class="cta" href="/train">
			Practise voicings free
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</section>

	<aside class="related">
		<p class="plate-mark blue">Related</p>
		<ul>
			<li><a href="/learn/rootless-voicings">Rootless voicings: A and B forms in depth</a></li>
			<li><a href="/learn/ii-v-i-all-keys">ii-V-I in all 12 keys (chart and PDF)</a></li>
			<li><a href="/learn/lead-sheets-for-classical-pianists">Lead sheets for classical pianists</a></li>
			<li><a href="/de/voicings-linke-hand" hreflang="de" lang="de">Diese Seite auf Deutsch</a></li>
		</ul>
	</aside>
</article>

<style>
	.lesson { max-width: 52rem; width: 100%; margin: 0 auto; padding: 2.5rem 1.25rem 5rem; }
	@media (min-width: 40rem) { .lesson { padding: 3.5rem 2.5rem 6rem; } }

	.masthead { padding-bottom: 2rem; border-bottom: 1px solid var(--border); }
	.plate-mark {
		display: flex; align-items: center; gap: 0.625rem; margin: 0 0 0.75rem;
		font-family: var(--font-mono); font-size: 0.625rem; letter-spacing: 0.19em;
		text-transform: uppercase; font-weight: 600; color: var(--primary);
	}
	.plate-mark::after { content: ''; flex: 1; height: 1px; background: currentColor; opacity: 0.3; }
	.plate-mark.blue { color: var(--ink-blue); }

	h1 {
		font-family: var(--font-display); font-size: clamp(2rem, 5.4vw, 2.9rem); font-weight: 600;
		line-height: 1.08; letter-spacing: -0.005em; margin: 0; color: var(--text); text-wrap: balance;
	}
	.lead { font-size: 1.125rem; line-height: 1.65; color: var(--text-muted); max-width: 54ch; margin: 1rem 0 0; }

	section { padding-top: 2.75rem; margin-top: 2.75rem; border-top: 1px solid var(--border); }
	section:first-of-type { border-top: 0; margin-top: 0; }
	.sec-head { display: flex; align-items: center; gap: 0.85rem; margin-bottom: 1.1rem; }
	.rehearsal {
		display: grid; place-items: center; flex: none; min-width: 1.65rem; height: 1.65rem; padding: 0 0.35rem;
		border: 1.5px solid var(--text); font-family: var(--font-mono); font-size: 0.6875rem; font-weight: 700; color: var(--text);
	}
	h2 {
		font-family: var(--font-display); font-size: clamp(1.4rem, 3.6vw, 1.75rem); font-weight: 600;
		line-height: 1.2; letter-spacing: -0.005em; margin: 0; color: var(--text);
	}
	section p { max-width: 66ch; font-size: 1.0625rem; line-height: 1.75; color: var(--text-muted); margin: 0 0 1rem; }
	section p a, .related a {
		color: var(--primary); text-decoration: underline; text-underline-offset: 0.15em; text-decoration-thickness: 1px;
	}

	.steps { max-width: 64ch; margin: 0 0 1.25rem; padding-left: 1.4rem; font-size: 1.0625rem; line-height: 1.75; color: var(--text-muted); }
	.steps li { margin-bottom: 0.5rem; }

	.related { padding-top: 2.5rem; margin-top: 2.75rem; border-top: 1px solid var(--border); }
	.related ul { list-style: none; padding: 0; margin: 0; }
	.related li { padding: 0.55rem 0; font-size: 0.9375rem; color: var(--text-muted); border-bottom: 1px solid var(--border); }
	.related li:last-child { border-bottom: 0; }

	@media print {
		.lesson { padding: 0; max-width: none; }
	}

	h3 { font-family: var(--font-display); font-size: 1.2rem; font-weight: 600; margin: 1.5rem 0 0.25rem; color: var(--text); }
	.formula { display: block; font-family: var(--font-mono); font-size: 0.75rem; font-weight: 500; color: var(--text-dim); margin-top: 0.2rem; }
	.vt { width: 100%; max-width: 36rem; border-collapse: collapse; margin: 0.5rem 0 1.5rem; }
	.vt th, .vt td { padding: 0.5rem 0.4rem; border-bottom: 1px solid var(--border); text-align: left; }
	.vt thead th { font-family: var(--font-mono); font-size: 0.625rem; letter-spacing: 0.14em; text-transform: uppercase; color: var(--text-dim); }
	.vt .deg { font-family: var(--font-display); font-style: italic; color: var(--ink-blue); width: 3rem; }
	.vt a { color: var(--text); font-weight: 600; text-decoration: none; }
	.vt a:hover { color: var(--primary); }
	.vt .notes { font-family: var(--font-mono); font-size: 0.875rem; color: var(--text-muted); }
	.cta {
		display: inline-flex; align-items: center; gap: 0.5rem; min-height: var(--tap-min); padding: 0 1.4rem;
		border: 1.5px solid var(--primary); border-radius: var(--radius-sm); background: var(--primary);
		color: var(--primary-text); font-weight: 600; text-decoration: none;
	}
	.cta:hover { background: var(--primary-hover); border-color: var(--primary-hover); }
	.count { font-family: var(--font-mono); font-size: 1.1rem !important; letter-spacing: 0.35em; color: var(--text-dim) !important; }
	.count .hit { color: var(--primary); font-weight: 700; }
</style>
