<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';

	const title = 'Apps zum Üben von Jazz-Piano-Voicings (2026): ehrlicher Vergleich | jazzchords.app';
	const description =
		'Welche App trainiert wirklich Jazz-Voicings am Klavier? Vergleich von MIDI-Voicing-Trainern, Play-along-Apps, Theorie-Seiten, Büchern und Kursen: was sie trainieren, Plattformen und Preise.';
	const canonical = 'https://jazzchords.app/de/jazz-voicings-app-vergleich';
	const enUrl = 'https://jazzchords.app/learn/jazz-voicing-practice-apps';
	const checked = '15. Oktober 2026';

	// Same facts as the English page, from each product's own store listing or
	// website on the date above. No ratings or "best" claims.
	const tools = [
		{
			name: 'JazzChords (diese Seite)',
			url: '/train',
			kind: 'Voicing-Drill + Coach',
			platform: 'Web (MIDI in Chrome/Edge, Mikrofon, Bildschirmtastatur); iOS-App in Vorbereitung',
			trains: 'Shell, Rootless A/B und 6 weitere Voicing-Typen in allen 12 Tonarten; II-V-I und andere Verbindungen; misst jeden Akkord und passt das Tempo an',
			price: 'Kostenlos: unbegrenzt üben, alle Voicings, MIDI und Mikrofon. Pro 7,99 €/Monat für Langzeit-Coaching und Verlauf',
			note: 'Wir haben es gebaut, gewichte unsere Einschätzung entsprechend. Web-MIDI funktioniert in Safari noch nicht.',
		},
		{
			name: 'VoicingLab',
			url: 'https://voicinglab.com/',
			kind: 'Voicing-Drill',
			platform: 'Web, MIDI',
			trains: 'Voicing-Übungen mit Fortschrittsanzeige; importiert iReal-Pro-Charts; Tarif für Lehrkräfte',
			price: 'Angegeben: 29 £ einmalig als „Founding Member“',
			note: '',
		},
		{
			name: 'VoicingWorkout',
			url: 'https://apps.apple.com/app/voicingworkout/id6748817790',
			kind: 'Voicing-Drill',
			platform: 'iOS, MIDI',
			trains: 'Voicing-Drills für Jazz, R&B, Funk und Neo-Soul',
			price: 'Angegeben: Pro 8,99 $',
			note: '',
		},
		{
			name: 'Jazz Piano Voicings: Chord App',
			url: 'https://apps.apple.com/search?term=jazz%20piano%20voicings%20chord%20app',
			kind: 'Voicing-Karteikarten',
			platform: 'iOS, MIDI oder Bildschirmtastatur',
			trains: 'Voicing-Übungskarten (angegeben: 1.400)',
			price: 'Angegeben: Wochen-, Monats-, Jahresabo oder Einmalkauf',
			note: '',
		},
		{
			name: 'iReal Pro',
			url: 'https://www.irealpro.com/',
			kind: 'Play-along',
			platform: 'iOS, Android, Mac',
			trains: 'Begleit-Tracks und Akkord-Charts für Tausende Stücke. Du begleitest dazu; was du spielst, prüft die App nicht',
			price: 'Einmalkauf',
			note: 'Guter Partner für einen Voicing-Drill, sobald die Griffe sitzen.',
		},
		{
			name: 'musictheory.net',
			url: 'https://www.musictheory.net/',
			kind: 'Theorie-Übungen',
			platform: 'Web, iOS (Tenuto)',
			trains: 'Noten, Intervalle und Akkorde erkennen. Keine Drills für konkrete Jazz-Voicings',
			price: 'Web kostenlos; Tenuto-App kostenpflichtig',
			note: '',
		},
	];

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		inLanguage: 'de',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'Gibt es eine App, mit der man Jazz-Piano-Voicings üben kann?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Ja. MIDI-Voicing-Trainer wie JazzChords, VoicingLab und VoicingWorkout zeigen ein Akkordsymbol, hören über ein MIDI-Keyboard zu und sagen dir, ob das Voicing stimmt. Play-along-Apps wie iReal Pro liefern Begleit-Tracks, prüfen deine Voicings aber nicht.',
				},
			},
			{
				'@type': 'Question',
				name: 'Brauche ich ein MIDI-Keyboard, um Voicings mit einer App zu üben?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Mit MIDI-Keyboard ist das Feedback am zuverlässigsten, weil die App genau sieht, welche Tasten du drückst. Manche Apps, auch JazzChords, funktionieren zusätzlich per Mikrofon am akustischen Klavier oder mit einer Bildschirmtastatur.',
				},
			},
			{
				'@type': 'Question',
				name: 'App, Buch oder Kurs: womit lerne ich Jazz-Voicings?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Sie erledigen verschiedene Aufgaben. Bücher und Kurse (zum Beispiel Mark Levines The Jazz Piano Book, Open Studio, Pianogroove) erklären, welche Voicings du nimmst und warum. Eine Drill-App macht diese Griffe in allen 12 Tonarten automatisch. In einer Play-along-App wie iReal Pro setzt du sie dann in Stücken ein.',
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
		<p class="plate-mark">Vergleich · geprüft am {checked}</p>
		<h1>Apps zum Üben von Jazz-Piano-Voicings</h1>
		<p class="lead">
			Du weißt, was ein Rootless-Voicing ist, aber bei E♭7 bleiben die Hände trotzdem
			hängen. Genau diese Lücke sollen Drill-Apps schließen. Hier steht, was jede Art
			von Werkzeug wirklich trainiert, damit du das findest, das dein Problem löst.
		</p>
	</header>

	<section aria-labelledby="kinds-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">01</span>
			<h2 id="kinds-h">Vier Arten von Werkzeugen, vier verschiedene Aufgaben</h2>
		</div>
		<dl class="kinds">
			<dt>Bücher und Videokurse</dt>
			<dd>Erklären, welche Voicings du nimmst und warum. Mark Levines <em>The Jazz Piano Book</em>, Open Studio und Pianogroove sind die üblichen Startpunkte. Dein Spiel prüfen sie nicht.</dd>
			<dt>Voicing-Drill-Apps</dt>
			<dd>Zeigen ein Akkordsymbol, hören über dein MIDI-Keyboard zu und sagen dir, ob das Voicing stimmt. Das ist der Schritt, der aus Wissen Reflexe in allen 12 Tonarten macht.</dd>
			<dt>Play-along-Apps</dt>
			<dd>Begleit-Tracks und Akkord-Charts für echte Stücke. Dort setzt du die Voicings ein, gelernt werden sie woanders.</dd>
			<dt>Theorie-Trainer</dt>
			<dd>Noten, Intervalle und Akkorde erkennen. Gut fürs Lesen, aber konkrete Jazz-Voicings drillen sie nicht.</dd>
		</dl>
	</section>

	<section aria-labelledby="table-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">02</span>
			<h2 id="table-h">Die Werkzeuge im Überblick</h2>
		</div>
		<p class="hint">Aus den Angaben der Anbieter selbst, Stand {checked}. Preise ändern sich; prüf den Link vor dem Kauf. Etwas veraltet? <a href="/feedback">Sag uns Bescheid</a>.</p>
		<div class="cards">
			{#each tools as tool (tool.name)}
				<article class="card">
					<h3>
						<a href={tool.url} rel={tool.url.startsWith('http') ? 'noopener' : undefined}>{tool.name}</a>
						<span class="kind">{tool.kind}</span>
					</h3>
					<dl>
						<dt>Läuft auf</dt><dd>{tool.platform}</dd>
						<dt>Trainiert</dt><dd>{tool.trains}</dd>
						<dt>Preis</dt><dd>{tool.price}</dd>
					</dl>
					{#if tool.note}<p class="note">{tool.note}</p>{/if}
				</article>
			{/each}
		</div>
	</section>

	<section aria-labelledby="pick-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">03</span>
			<h2 id="pick-h">Was passt zu deinem Problem?</h2>
		</div>
		<ul class="pick">
			<li><strong>„Ich weiß nicht, welche Töne ich spielen soll.“</strong> Fang mit einem Buch oder Kurs an, oder mit unserer Seite <a href="/de/voicings-linke-hand">Voicings für die linke Hand</a>.</li>
			<li><strong>„Ich kenne die Griffe, bin aber in den meisten Tonarten zu langsam.“</strong> Eine Drill-App mit Zeitmessung. Probier die <a href="/de/ii-v-i-alle-tonarten">II-V-I-Tabelle für alle 12 Tonarten</a>, dann den <a href="/train">Trainer</a>.</li>
			<li><strong>„Meine Voicings sitzen, ich will sie in Stücken einsetzen.“</strong> Eine Play-along-App wie iReal Pro.</li>
			<li><strong>„Ich unterrichte und will den Fortschritt meiner Schüler sehen.“</strong> Achte auf einen Tarif für Lehrkräfte, wie unseren <a href="/for-educators">Educator-Plan</a>.</li>
		</ul>
		<a class="cta" href="/train">
			Voicing-Drill kostenlos testen
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</section>
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
	h1 {
		font-family: var(--font-display); font-size: clamp(2rem, 5.4vw, 2.9rem); font-weight: 600;
		line-height: 1.08; letter-spacing: -0.005em; margin: 0; color: var(--text); text-wrap: balance;
	}
	.lead { font-size: 1.125rem; line-height: 1.65; color: var(--text-muted); max-width: 56ch; margin: 1rem 0 0; }
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
	section p, .pick { max-width: 66ch; font-size: 1.0625rem; line-height: 1.75; color: var(--text-muted); margin: 0 0 1rem; }
	section a:not(.cta) { color: var(--primary); text-decoration: underline; text-underline-offset: 0.15em; }
	.hint { font-size: 0.875rem !important; line-height: 1.6 !important; color: var(--text-dim) !important; }

	.kinds dt { font-weight: 700; color: var(--text); margin-top: 0.9rem; }
	.kinds dd { margin: 0.2rem 0 0; color: var(--text-muted); line-height: 1.65; max-width: 66ch; }

	.cards { display: grid; gap: 0.9rem; grid-template-columns: repeat(auto-fill, minmax(min(100%, 20rem), 1fr)); }
	.card { border: 1px solid var(--border); border-radius: var(--radius-sm); padding: 1rem 1.1rem; }
	.card h3 { margin: 0 0 0.6rem; font-family: var(--font-display); font-size: 1.15rem; display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: baseline; }
	.card h3 a { color: var(--text) !important; text-decoration: none !important; }
	.card h3 a:hover { color: var(--primary) !important; }
	.kind { font-family: var(--font-mono); font-size: 0.625rem; letter-spacing: 0.12em; text-transform: uppercase; color: var(--ink-blue); }
	.card dl { margin: 0; display: grid; grid-template-columns: auto 1fr; gap: 0.3rem 0.75rem; font-size: 0.9rem; line-height: 1.5; }
	.card dt { font-family: var(--font-mono); font-size: 0.6875rem; text-transform: uppercase; letter-spacing: 0.08em; color: var(--text-dim); padding-top: 0.15rem; }
	.card dd { margin: 0; color: var(--text-muted); }
	.note { font-size: 0.85rem !important; margin: 0.6rem 0 0 !important; color: var(--text-dim) !important; }

	.pick { padding-left: 1.2rem; }
	.pick li { margin-bottom: 0.6rem; }
	.cta {
		display: inline-flex; align-items: center; gap: 0.5rem; min-height: var(--tap-min); padding: 0 1.4rem;
		border: 1.5px solid var(--primary); border-radius: 999px; background: var(--primary);
		color: var(--primary-text); font-weight: 600; text-decoration: none;
	}
	.cta:hover { background: var(--primary-hover); border-color: var(--primary-hover); }
</style>
