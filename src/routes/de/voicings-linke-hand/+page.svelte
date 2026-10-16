<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';
	import { buildIIVITable, type IIVIVoicing } from '$lib/seo/ii-v-i-keys';

	const title = 'Jazz-Voicings für die linke Hand: Shell und Rootless einfach erklärt | jazzchords.app';
	const description =
		'Deine linke Hand klingt nach Grundton-Oktaven? So kommst du in zwei Stufen zu Jazz-Voicings: erst Shell (1-3-7), dann Rootless A und B. Mit Tönen zum Nachspielen und Übeplan.';
	const canonical = 'https://jazzchords.app/de/voicings-linke-hand';

	// Example voicings come from the trainer's engine (II-V-I in C), so the page
	// shows exactly what the drill will ask for.
	const EXAMPLES: { id: IIVIVoicing; label: string; formula: string }[] = [
		{ id: 'shell', label: 'Shell', formula: '1 – 3 – 7 (bzw. 1 – 7 – 3)' },
		{ id: 'rootless-ab', label: 'Rootless A → B', formula: 'A: 3 – 5 – 7 – 9 · B: 7 – 9 – 3 – 5' },
	];
	const rowsFor = (id: IIVIVoicing) => buildIIVITable(id)[0].chords;
	const pretty = (n: string) => n.replace('#', '♯').replace(/^([A-G])b/, '$1♭');

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		inLanguage: 'de',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'Was spielt die linke Hand im Jazz-Klavier?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Statt Grundton oder Oktave spielt die linke Hand im Jazz meist Voicings: kompakte Akkordgriffe aus Terz und Septime (Shell-Voicings) oder, wenn ein Bass dabei ist, Rootless-Voicings aus Terz, Quinte, Septime und None. Die rechte Hand spielt dazu Melodie oder Improvisation.',
				},
			},
			{
				'@type': 'Question',
				name: 'Was ist ein Shell-Voicing?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Ein Shell-Voicing besteht aus Grundton, Terz und Septime; die Quinte fällt weg. Terz und Septime bestimmen, ob ein Akkord Dur, Moll oder Dominante ist, deshalb klingt der Griff trotz nur drei Tönen vollständig.',
				},
			},
			{
				'@type': 'Question',
				name: 'Was ist ein Rootless-Voicing?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Ein Rootless-Voicing lässt den Grundton weg und nimmt dafür die None dazu. Die A-Form ist 3–5–7–9, die B-Form 7–9–3–5. In der II-V-I wechselt man zwischen beiden, damit die Hand in einer Lage bleibt.',
				},
			},
			{
				'@type': 'Question',
				name: 'Wie lange dauert es, Voicings in allen Tonarten zu lernen?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Das hängt vor allem davon ab, wie regelmäßig du übst. Ein bewährter Weg: eine Tonart pro Woche neu dazunehmen, täglich alle bisherigen kurz wiederholen und die langsamsten Tonarten gezielt öfter spielen.',
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
	<meta name="twitter:title" content={title} />
	<meta name="twitter:description" content={description} />
	{@html `<script type="application/ld+json">${JSON.stringify(faqSchema)}</` + `script>`}
</svelte:head>

<article class="lesson" lang="de">
	<header class="masthead">
		<p class="plate-mark">Voicings · linke Hand</p>
		<h1>Jazz-Voicings für die linke Hand</h1>
		<p class="lead">
			Wenn deine linke Hand nur Grundtöne und Oktaven spielt, klingt Jazz schnell
			nach Schlager. Der Ausweg sind Voicings: kleine Griffe aus den Tönen, die einen
			Akkord wirklich ausmachen. Hier ist der Weg in zwei Stufen.
		</p>
	</header>

	<section aria-labelledby="why-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="why-h">Warum Terz und Septime reichen</h2>
		</div>
		<p>
			Ob ein Akkord Dur-Septakkord, Moll-Septakkord oder Dominante ist, hörst du an
			zwei Tönen: der Terz und der Septime. Die Quinte ist in fast allen Akkorden
			gleich und kann weg, den Grundton übernimmt oft der Bass. Genau diese
			Reduktion macht Jazz-Voicings so kompakt und lässt der rechten Hand Platz.
		</p>
	</section>

	<section aria-labelledby="levels-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="levels-h">Zwei Stufen, am Beispiel II-V-I in C</h2>
		</div>
		{#each EXAMPLES as ex (ex.id)}
			<h3>{ex.label} <span class="formula">{ex.formula}</span></h3>
			<table class="vt">
				<thead>
					<tr><th scope="col">Stufe</th><th scope="col">Akkord</th><th scope="col">Töne (unten → oben)</th></tr>
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
			<strong>Stufe 1, Shell:</strong> Solange du allein spielst, behält die linke
			Hand den Grundton unten. Drei Töne, sofort jazzig, und du lernst nebenbei, wo
			in jedem Akkord Terz und Septime liegen.
		</p>
		<p>
			<strong>Stufe 2, Rootless:</strong> Sobald der Grundton woanders herkommt
			(Bass, Band oder deine rechte Hand), lässt du ihn weg und nimmst die None dazu.
			A- und B-Form wechseln sich ab, so bleibt die Hand ruhig in der Mitte der
			Tastatur.
		</p>
		<p>
			Alle zwölf Tonarten mit Tönen und Hörbeispiel stehen in der
			<a href="/de/ii-v-i-alle-tonarten">II-V-I-Tabelle für alle 12 Tonarten</a>.
		</p>
	</section>

	<section aria-labelledby="practice-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">III</span>
			<h2 id="practice-h">So übst du, ohne dass es zäh wird</h2>
		</div>
		<ol class="steps">
			<li>Jeden Tag zehn Minuten statt einmal pro Woche eine Stunde. Voicings sind Reflexe, keine Theorie.</li>
			<li>Erst Shells in allen Tonarten, dann Rootless. Nicht beides gleichzeitig anfangen.</li>
			<li>Ohne Hinschauen spielen: Akkordsymbol lesen, Griff greifen, nächstes Symbol.</li>
			<li>Tempo messen. Wenn du bei einer Tonart hängen bleibst, ist das die Tonart für morgen.</li>
		</ol>
		<p>
			Das Problem beim Üben allein: Du weißt nicht, ob du schneller wirst. Der
			<a href="/train">Trainer</a> zeigt dir ein Akkordsymbol, hört über dein
			MIDI-Keyboard zu und misst, wie lange du für jeden Griff brauchst.
		</p>
		<a class="cta" href="/train">
			Voicings kostenlos üben
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</section>

	<aside class="related">
		<p class="plate-mark blue">Weiterlesen</p>
		<ul>
			<li><a href="/de/ii-v-i-alle-tonarten">II-V-I in allen 12 Tonarten (Tabelle)</a></li>
			<li><a href="/de/jazz-klavier-aufnahmepruefung">Aufnahmeprüfung Jazz-Klavier: Akkorde und Voicings vorbereiten</a></li>
			<li><a href="/learn/rootless-voicings" hreflang="en">Rootless voicings in depth (English)</a></li>
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
</style>
