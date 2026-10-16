<script lang="ts">
	import IIVIChart from '$lib/components/seo/IIVIChart.svelte';
	import type { IIVIVoicing } from '$lib/seo/ii-v-i-keys';

	const title = 'II-V-I in allen 12 Tonarten: Klavier-Tabelle mit Shell- und Rootless-Voicings | jazzchords.app';
	const description =
		'Kostenlose II-V-I-Tabelle für alle 12 Tonarten mit den genauen Tönen für Shell- und Rootless-Voicings (A/B). Jede Tonart anhören, ausdrucken und mit MIDI-Feedback üben.';
	const canonical = 'https://jazzchords.app/de/ii-v-i-alle-tonarten';
	const enUrl = 'https://jazzchords.app/learn/ii-v-i-all-keys';

	const VOICINGS: { id: IIVIVoicing; label: string; hint: string }[] = [
		{ id: 'shell', label: 'Shell', hint: 'Grundton – Terz – Septime. Damit fängst du an.' },
		{ id: 'rootless-ab', label: 'Rootless A → B', hint: 'ii (A) → V (B) → I (A). Die klassische II-V-I der linken Hand.' },
		{ id: 'rootless-ba', label: 'Rootless B → A', hint: 'ii (B) → V (A) → I (B). Gleiche Idee, andere Lage.' },
	];

	const CHART_TEXT = {
		voicingGroup: 'Voicing',
		print: 'Drucken',
		notesHint: 'Töne von unten nach oben.',
		key: 'Tonart',
		listen: 'Anhören',
		playAria: (key: string) => `II-V-I in ${key} abspielen`,
		cta: 'Diese 12 Tonarten mit Live-Feedback üben',
	};

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		inLanguage: 'de',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'Wie lauten die II-V-I-Akkorde in allen 12 Tonarten?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Im Quartenzirkel: C: Dm7–G7–Cmaj7 · F: Gm7–C7–Fmaj7 · B♭: Cm7–F7–B♭maj7 · E♭: Fm7–B♭7–E♭maj7 · A♭: B♭m7–E♭7–A♭maj7 · D♭: E♭m7–A♭7–D♭maj7 · G♭: A♭m7–D♭7–G♭maj7 · B (H): C♯m7–F♯7–Bmaj7 · E: F♯m7–B7–Emaj7 · A: Bm7–E7–Amaj7 · D: Em7–A7–Dmaj7 · G: Am7–D7–Gmaj7.',
				},
			},
			{
				'@type': 'Question',
				name: 'In welcher Reihenfolge übe ich II-V-I in allen Tonarten?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Die meisten Lehrer nehmen den Quartenzirkel (C, F, B♭, E♭, A♭, D♭, G♭, B, E, A, D, G), weil jede neue Tonart die nächste II-V in echten Stücken ist. Eine Tonart üben, bis sie automatisch kommt, dann die nächste dazunehmen und die langsamsten Tonarten öfter wiederholen.',
				},
			},
			{
				'@type': 'Question',
				name: 'Warum wechselt man in der II-V-I zwischen Rootless A und B?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Der Wechsel zwischen A-Form (3–5–7–9) und B-Form (7–9–3–5) hält die linke Hand in einer Lage: Die Septime jedes Akkords rutscht einen Halbton nach unten zur Terz des nächsten, die Voicings verbinden sich also glatt statt zu springen.',
				},
			},
			{
				'@type': 'Question',
				name: 'Heißt es B oder H?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Im deutschen Notennamen-System ist H der Ton, der international B heißt, und B ist international B♭. Jazz-Leadsheets und Real Books benutzen fast immer die internationale Schreibweise, deshalb steht sie auch in dieser Tabelle: B = H, B♭ = B.',
				},
			},
		],
	};

	const breadcrumbSchema = {
		'@context': 'https://schema.org',
		'@type': 'BreadcrumbList',
		itemListElement: [
			{ '@type': 'ListItem', position: 1, name: 'Voicings für die linke Hand', item: 'https://jazzchords.app/de/voicings-linke-hand' },
			{ '@type': 'ListItem', position: 2, name: 'II-V-I in allen 12 Tonarten', item: canonical },
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
	{@html `<script type="application/ld+json">${JSON.stringify(breadcrumbSchema)}</` + `script>`}
</svelte:head>

<article class="lesson" lang="de">
	<header class="masthead">
		<p class="plate-mark">Tabelle · kostenlos</p>
		<h1>II-V-I in allen 12 Tonarten</h1>
		<p class="lead">
			Jede Dur-II-V-I mit den genauen Tönen, als Shell- und als Rootless-Voicing.
			Tonart antippen und anhören, Tabelle fürs Klavier ausdrucken, dann gezielt
			die Tonarten üben, in denen du am langsamsten bist.
		</p>
	</header>

	<section aria-labelledby="chart-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="chart-h">Die Tabelle</h2>
		</div>
		<IIVIChart voicings={VOICINGS} text={CHART_TEXT} />
		<p class="hint">
			Akkordsymbole und Tonnamen sind international geschrieben, wie in Real Books
			und Leadsheets: B steht für das deutsche H, B♭ für das deutsche B.
		</p>
	</section>

	<section aria-labelledby="how-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="how-h">So übst du sie in allen 12 Tonarten</h2>
		</div>
		<ol class="steps">
			<li>Eine Tonart wählen. II-V-I mit Shell-Voicings spielen, bis du nicht mehr nachdenken musst.</li>
			<li>Die nächste Tonart im Quartenzirkel dazunehmen (C → F → B♭ …). Die alten Tonarten jeden Tag kurz wiederholen.</li>
			<li>Sitzen die Shells, auf Rootless A → B wechseln. Hör hin, wie die Septime einen Halbton in die nächste Terz fällt.</li>
			<li>Stopp die Zeit. Die Tonarten, die sich am langsamsten anfühlen, übst du morgen zuerst.</li>
		</ol>
		<p>
			„Alles in 12 Tonarten“ ist der Rat, den man in jedem Jazz-Forum bekommt, und
			gleichzeitig der Teil, der am zähesten ist. Eine Tabelle durchspielen hilft,
			aber du merkst nicht, ob du schneller wirst. Der <a href="/train">Trainer</a>
			hört über dein MIDI-Keyboard zu, misst jeden Akkord und zeigt dir, welche
			Tonarten dich noch bremsen.
		</p>
		<p class="hint">
			Shell-Voicings lassen die Quinte weg, Rootless-Voicings den Grundton und nehmen
			dafür die None dazu; den Grundton spielt der Bass oder deine rechte Hand. Auf
			dem V-Akkord ersetzen viele Pianisten die Quinte durch die 13. Probier das, wenn
			die Griffe oben sicher sitzen.
		</p>
	</section>

	<aside class="related no-print">
		<p class="plate-mark blue">Weiterlesen</p>
		<ul>
			<li><a href="/de/voicings-linke-hand">Jazz-Voicings für die linke Hand: Shell und Rootless</a></li>
			<li><a href="/de/jazz-klavier-aufnahmepruefung">Aufnahmeprüfung Jazz-Klavier: Akkorde und Voicings vorbereiten</a></li>
			<li><a href="/learn/ii-v-i-all-keys" hreflang="en">This chart in English</a></li>
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
