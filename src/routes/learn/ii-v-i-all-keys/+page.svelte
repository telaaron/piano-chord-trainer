<script lang="ts">
	import IIVIChart from '$lib/components/seo/IIVIChart.svelte';
	import type { IIVIVoicing } from '$lib/seo/ii-v-i-keys';

	const title = 'ii-V-I in All 12 Keys: Piano Chart with Shell & Rootless Voicings | jazzchords.app';
	const description =
		'Free ii-V-I chart for all 12 keys with the exact notes for shell and rootless A/B voicings. Hear each key, print it, then drill it with live MIDI feedback.';
	const canonical = 'https://jazzchords.app/learn/ii-v-i-all-keys';

	const VOICINGS: { id: IIVIVoicing; label: string; hint: string }[] = [
		{ id: 'shell', label: 'Shell', hint: 'Root – 3rd – 7th. Start here.' },
		{ id: 'rootless-ab', label: 'Rootless A → B', hint: 'ii (A) → V (B) → I (A). The classic left-hand ii-V-I.' },
		{ id: 'rootless-ba', label: 'Rootless B → A', hint: 'ii (B) → V (A) → I (B). Same idea, other register.' },
	];

	const CHART_TEXT = {
		voicingGroup: 'Voicing',
		print: 'Print',
		notesHint: 'Notes are listed bottom to top.',
		key: 'Key',
		listen: 'Listen',
		playAria: (key: string) => `Play ii-V-I in ${key}`,
		cta: 'Drill these 12 keys with live feedback',
	};

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'What are the ii-V-I chords in all 12 keys?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Around the circle of fourths: C: Dm7–G7–Cmaj7 · F: Gm7–C7–Fmaj7 · B♭: Cm7–F7–B♭maj7 · E♭: Fm7–B♭7–E♭maj7 · A♭: B♭m7–E♭7–A♭maj7 · D♭: E♭m7–A♭7–D♭maj7 · G♭: A♭m7–D♭7–G♭maj7 · B: C♯m7–F♯7–Bmaj7 · E: F♯m7–B7–Emaj7 · A: Bm7–E7–Amaj7 · D: Em7–A7–Dmaj7 · G: Am7–D7–Gmaj7.',
				},
			},
			{
				'@type': 'Question',
				name: 'In what order should I practice ii-V-I in 12 keys?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Most teachers use the circle of fourths (C, F, B♭, E♭, A♭, D♭, G♭, B, E, A, D, G), because each new key is the next ii-V in real tunes. Learn one key until it is automatic, then add the next; spend extra time on the keys that feel slowest.',
				},
			},
			{
				'@type': 'Question',
				name: 'Why alternate rootless A and B voicings in a ii-V-I?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Switching between the A form (3–5–7–9) and the B form (7–9–3–5) keeps the left hand in one register: the seventh of each chord falls by a half step to the third of the next, so the voicings move smoothly instead of jumping.',
				},
			},
		],
	};

	const breadcrumbSchema = {
		'@context': 'https://schema.org',
		'@type': 'BreadcrumbList',
		itemListElement: [
			{ '@type': 'ListItem', position: 1, name: 'ii-V-I Progression', item: 'https://jazzchords.app/learn/ii-v-i' },
			{ '@type': 'ListItem', position: 2, name: 'ii-V-I in All 12 Keys', item: canonical },
		],
	};
</script>

<svelte:head>
	<title>{title}</title>
	<meta name="description" content={description} />
	<link rel="canonical" href={canonical} />
	<link rel="alternate" hreflang="en" href={canonical} />
	<link rel="alternate" hreflang="de" href="https://jazzchords.app/de/ii-v-i-alle-tonarten" />
	<link rel="alternate" hreflang="x-default" href={canonical} />
	<meta property="og:type" content="article" />
	<meta property="og:url" content={canonical} />
	<meta property="og:title" content={title} />
	<meta property="og:description" content={description} />
	<meta name="twitter:title" content={title} />
	<meta name="twitter:description" content={description} />
	{@html `<script type="application/ld+json">${JSON.stringify(faqSchema)}</` + `script>`}
	{@html `<script type="application/ld+json">${JSON.stringify(breadcrumbSchema)}</` + `script>`}
</svelte:head>

<article class="lesson">
	<header class="masthead">
		<p class="plate-mark">Chart · free</p>
		<h1>ii-V-I in All 12 Keys</h1>
		<p class="lead">
			Every major ii-V-I with the exact notes to play, in shell and rootless
			voicings. Tap a key to hear it, print the chart for the piano, then drill
			the keys you are slowest in.
		</p>
	</header>

	<section aria-labelledby="chart-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="chart-h">The chart</h2>
		</div>

		<IIVIChart voicings={VOICINGS} text={CHART_TEXT} />
	</section>

	<section aria-labelledby="how-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="how-h">How to practice it in all 12 keys</h2>
		</div>
		<ol class="steps">
			<li>Pick one key. Play ii-V-I with shell voicings until you don't have to think.</li>
			<li>Add the next key around the circle of fourths (C → F → B♭ …). Review the old keys every day.</li>
			<li>Once the shells are automatic, switch to rootless A → B. Listen for the seventh falling a half step into the next third.</li>
			<li>Time yourself. The keys that feel slowest are the ones to drill tomorrow.</li>
		</ol>
		<p>
			Playing through a chart works, but you can't tell whether you're getting
			faster. The <a href="/train">trainer</a> listens through your MIDI keyboard,
			times every chord and shows which keys still slow you down.
		</p>
		<p class="hint">
			Shell voicings drop the fifth; rootless voicings drop the root and add the ninth,
			so a bass player or your right hand covers the root. On the V chord many players
			swap the fifth for the 13th; once the shapes above are solid, try it.
		</p>
	</section>

	<aside class="related no-print">
		<p class="plate-mark blue">Related</p>
		<ul>
			<li><a href="/learn/ii-v-i">The ii-V-I progression explained</a></li>
			<li><a href="/learn/rootless-voicings">Rootless voicings: A and B forms</a></li>
			<li><a href="/learn/jazz-piano-voicings">Jazz piano voicings: the complete guide</a></li>
			<li><a href="/learn/jazz-voicing-practice-apps">Apps to practice jazz voicings, compared</a></li>
			<li><a href="/de/ii-v-i-alle-tonarten" hreflang="de" lang="de">Diese Tabelle auf Deutsch</a></li>
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
		line-height: 1.08; letter-spacing: -0.025em; margin: 0; color: var(--text); text-wrap: balance;
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
		line-height: 1.2; letter-spacing: -0.02em; margin: 0; color: var(--text);
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
		.no-print { display: none !important; }
		.lesson { padding: 0; max-width: none; }
	}
</style>
