<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';
	import { getChordNotes } from '$lib/engine/voicings';

	const title = 'Leadsheet spielen lernen als klassischer Pianist: Akkordsymbole und Septakkorde | jazzchords.app';
	const description =
		'Du spielst Chopin, aber bei „Dm7“ stockst du? Warum Akkordsymbole klassisch ausgebildeten Pianisten schwerfallen, eine Übersicht aller Septakkord-Symbole und ein Weg in 4 Schritten zum Spiel nach Leadsheet.';
	const canonical = 'https://jazzchords.app/de/leadsheet-spielen-klassik';
	const enUrl = 'https://jazzchords.app/learn/lead-sheets-for-classical-pianists';

	// Every symbol spelling a classical player will meet for the same chords,
	// with the notes on C from the trainer's engine.
	const SYMBOLS: { quality: string; names: string; label: string; formula: string; slug: string }[] = [
		{ quality: 'Maj7', names: 'Cmaj7 · CΔ · CM7', label: 'großer Septakkord', formula: '1 – 3 – 5 – 7', slug: 'cmaj7' },
		{ quality: '7', names: 'C7', label: 'Dominantseptakkord', formula: '1 – 3 – 5 – ♭7', slug: 'c7' },
		{ quality: 'm7', names: 'Cm7 · C-7 · Cmin7', label: 'Moll-Septakkord', formula: '1 – ♭3 – 5 – ♭7', slug: 'cm7' },
		{ quality: 'm7b5', names: 'Cm7♭5 · Cø', label: 'halbvermindert', formula: '1 – ♭3 – ♭5 – ♭7', slug: 'cm7b5' },
		{ quality: 'dim7', names: 'C°7 · Cdim7', label: 'vermindert', formula: '1 – ♭3 – ♭5 – ♭♭7', slug: '' },
		{ quality: '6', names: 'C6', label: 'Dur mit Sexte', formula: '1 – 3 – 5 – 6', slug: 'c6' },
		{ quality: 'm6', names: 'Cm6 · C-6', label: 'Moll mit Sexte', formula: '1 – ♭3 – 5 – 6', slug: 'cm6' },
	];
	const pretty = (n: string) => n.replace('#', '♯').replace(/^([A-G])b/, '$1♭');
	const rows = SYMBOLS.map((s) => ({ ...s, notes: getChordNotes('C', s.quality, 'both').map(pretty) }));

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		inLanguage: 'de',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'Warum fällt klassischen Pianisten das Spielen nach Leadsheet so schwer?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Die klassische Ausbildung trainiert Lesen: Jede Note steht auf dem Blatt, du übersetzt sie auf die Tasten. Ein Leadsheet gibt nur Melodie und Akkordsymbol vor, den Akkord und seinen Griff musst du in Echtzeit aus dem Gedächtnis abrufen. Das ist eine andere Fähigkeit, Abrufgeschwindigkeit, und sie wird durch gezieltes Üben besser, nicht durch mehr Lesen.',
				},
			},
			{
				'@type': 'Question',
				name: 'Was bedeutet ein Akkordsymbol wie Dm7 am Klavier?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Der Buchstabe ist der Grundton (D), „m“ steht für die kleine Terz, „7“ für die kleine Septime: D, F, A, C. Cmaj7 oder CΔ ist ein großer Septakkord (C E G B, deutsch H), C7 ein Dominantseptakkord (C E G B♭, deutsch B) und Cø bzw. Cm7♭5 ein halbverminderter Akkord (C E♭ G♭ B♭).',
				},
			},
			{
				'@type': 'Question',
				name: 'Wie lerne ich Septakkorde am Klavier am schnellsten?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Lerne die fünf Haupttypen (maj7, 7, m7, m7♭5, dim7) erst als Shell-Voicing aus Grundton, Terz und Septime, auf allen 12 Grundtönen. Übe sie in zufälliger Reihenfolge und Tonart statt immer chromatisch, täglich ein paar Minuten, und miss deine Zeit: Die langsamen Tonarten übst du am nächsten Tag zuerst.',
				},
			},
		],
	};
</script>

<svelte:head>
	<title>{title}</title>
	<meta name="description" content={description} />
	<link rel="canonical" href={canonical} />
	<link rel="alternate" hreflang="de" href={canonical} />
	<link rel="alternate" hreflang="en" href={enUrl} />
	<link rel="alternate" hreflang="x-default" href={enUrl} />
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
		<p class="plate-mark">Klassik → Jazz</p>
		<h1>Leadsheet spielen lernen als klassischer Pianist</h1>
		<p class="lead">
			Du spielst ein Chopin-Nocturne, aber ein Blatt mit einer Melodiezeile und
			„Dm7 G7 Cmaj7“ darüber lässt dich erstarren. Das ist kein Talentproblem. Es ist
			eine andere Fähigkeit, und die lässt sich direkt trainieren.
		</p>
	</header>

	<section aria-labelledby="why-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="why-h">Warum Notenlesen hier nicht hilft</h2>
		</div>
		<p>
			Klassisches Spiel ist Übersetzen: Jede Note steht auf dem Blatt, die Augen führen
			die Hände. Ein Leadsheet gibt dir eine Melodie und ein Akkordsymbol, alles andere
			kommt aus dem Gedächtnis, im Tempo, während du schon weiterliest.
		</p>
		<p>
			Der Engpass ist also die <strong>Abrufgeschwindigkeit</strong>: „B♭7“ sehen und
			den Griff in der Hand haben, bevor der Schlag kommt. Mehr Leadsheets lesen hilft
			langsam. Den Abruf selbst zu trainieren hilft schnell.
		</p>
	</section>

	<section aria-labelledby="symbols-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="symbols-h">Übersicht: Akkordsymbole und Septakkorde</h2>
		</div>
		<p>
			Derselbe Akkord wird je nach Buch unterschiedlich geschrieben. Diese sieben
			begegnen dir auf fast jedem Jazz- oder Pop-Leadsheet, hier auf C.
		</p>
		<table class="vt">
			<thead>
				<tr><th scope="col">Symbol</th><th scope="col">Formel</th><th scope="col">Auf C</th></tr>
			</thead>
			<tbody>
				{#each rows as r (r.quality)}
					<tr>
						<td class="sym">
							{#if r.slug}<a href={`/chords/${r.slug}`}>{r.names}</a>{:else}{r.names}{/if}
							<span class="label">{r.label}</span>
						</td>
						<td class="formula">{r.formula}</td>
						<td class="notes">{r.notes.join(' ')}</td>
					</tr>
				{/each}
			</tbody>
		</table>
		<p class="hint">
			Leadsheets benutzen die internationalen Tonnamen: B steht für das deutsche H,
			B♭ für das deutsche B. Optionstöne (9, 11, 13) und Alterationen (♭9, ♯11) kommen
			oben drauf; am Anfang kannst du sie weglassen. Der Septakkord darunter muss
			automatisch kommen.
		</p>
	</section>

	<section aria-labelledby="path-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">III</span>
			<h2 id="path-h">In 4 Schritten vom Notenblatt zum Leadsheet</h2>
		</div>
		<ol class="steps">
			<li>
				<strong>Linke Hand: Shells.</strong> Grundton, Terz und Septime. Lerne die fünf
				Haupttypen auf allen 12 Grundtönen, bevor du ein Stück anfasst.
				<a href="/de/voicings-linke-hand">Voicings für die linke Hand</a>
			</li>
			<li>
				<strong>Abruf üben statt lesen.</strong> Symbol sehen, Griff spielen, nächstes
				Symbol. Zufällige Reihenfolge und Tonart, ein paar Minuten am Tag. Miss die Zeit,
				damit du siehst, dass du schneller wirst.
			</li>
			<li>
				<strong>Die II-V-I.</strong> Die meisten Jazz-Standards sind Ketten von II-V-Is.
				Sitzt sie in jeder Tonart, sind ganze Stücke plötzlich nicht mehr neu.
				<a href="/de/ii-v-i-alle-tonarten">II-V-I-Tabelle, alle 12 Tonarten</a>
			</li>
			<li>
				<strong>Dann das Stück.</strong> Erst die linke Hand allein im Tempo, dann die
				Melodie dazu. Nimm einen echten Standard und spiel ihn in einer zweiten Tonart,
				sobald er sitzt.
			</li>
		</ol>
		<p>
			Schritt 2 lassen die meisten aus, weil Karteikarten und Listen mit zufälligen
			Tonarten mühsam selbst zu organisieren sind. Der <a href="/train">Trainer</a> macht
			das für dich: Er zeigt ein Akkordsymbol, hört über dein MIDI-Keyboard zu und misst
			jeden Akkord, damit du weißt, welche Tonarten dich noch bremsen.
		</p>
		<a class="cta" href="/train">
			Kostenlosen Abruf-Drill starten
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</section>

	<aside class="related">
		<p class="plate-mark blue">Weiterlesen</p>
		<ul>
			<li><a href="/de/voicings-linke-hand">Jazz-Voicings für die linke Hand: Shell und Rootless</a></li>
			<li><a href="/de/ii-v-i-alle-tonarten">II-V-I in allen 12 Tonarten (Tabelle und PDF)</a></li>
			<li><a href="/de/jazz-klavier-aufnahmepruefung">Aufnahmeprüfung Jazz-Klavier: Akkorde und Voicings vorbereiten</a></li>
			<li><a href="/de/jazz-voicings-app-vergleich">Apps zum Üben von Jazz-Voicings im Vergleich</a></li>
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
		border: 1.5px solid var(--primary); border-radius: var(--radius-sm); background: var(--primary);
		color: var(--primary-text); font-weight: 600; text-decoration: none;
	}
	.cta:hover { background: var(--primary-hover); border-color: var(--primary-hover); }
	.vt .label { display: block; font-family: var(--font-body, inherit); font-size: 0.75rem; font-weight: 400; color: var(--text-dim); }
</style>
