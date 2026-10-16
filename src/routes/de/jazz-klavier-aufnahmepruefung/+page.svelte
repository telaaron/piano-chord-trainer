<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';

	const title = 'Aufnahmeprüfung Jazz-Klavier (Nebenfach): Akkorde und Voicings vorbereiten | jazzchords.app';
	const description =
		'Klavier im Nebenfach für die Jazz- oder Pop-Aufnahmeprüfung? Welche Akkord-Fähigkeiten immer wieder verlangt werden, eine Checkliste und ein 8-Wochen-Übeplan.';
	const canonical = 'https://jazzchords.app/de/jazz-klavier-aufnahmepruefung';

	const CHECKLIST = [
		{ skill: 'Septakkorde nach Symbol greifen', detail: 'maj7, 7, m7, m7♭5 in allen 12 Tonarten, ohne nachzuzählen', href: '/chords/cmaj7' },
		{ skill: 'Shell-Voicings', detail: 'Grundton, Terz, Septime: die Grundlage für jedes Leadsheet', href: '/de/voicings-linke-hand' },
		{ skill: 'II-V-I in Dur', detail: 'in allen Tonarten, mindestens mit Shells, besser rootless', href: '/de/ii-v-i-alle-tonarten' },
		{ skill: 'II-V-I in Moll', detail: 'm7♭5 – 7 – m6, z.B. Dm7♭5 – G7 – Cm6', href: '/chords/dm7b5' },
		{ skill: 'Blues-Form', detail: '12-taktiger Jazz-Blues, häufig in F und B♭', href: null },
		{ skill: 'Leadsheet spielen', detail: 'Melodie rechts, Voicings links, im Tempo und ohne Abbrüche', href: null },
	];

	const PLAN = [
		{ weeks: 'Woche 1–2', focus: 'Septakkorde in allen Tonarten als Shell greifen. Täglich 10 Minuten, gezielt die langsamen Tonarten.' },
		{ weeks: 'Woche 3–4', focus: 'II-V-I in Dur durch den Quartenzirkel. Erst Shell, dann Rootless A → B.' },
		{ weeks: 'Woche 5', focus: 'II-V-I in Moll und Blues-Form. Beides in den Tonarten der Stücke, die du vorspielen willst.' },
		{ weeks: 'Woche 6–7', focus: 'Prüfungsstück nach Leadsheet: erst linke Hand allein im Tempo, dann Melodie dazu.' },
		{ weeks: 'Woche 8', focus: 'Generalprobe: Stück vor Publikum oder Aufnahme vorspielen, Akkord-Drills nur noch zum Aufwärmen.' },
	];

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		inLanguage: 'de',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'Was muss ich im Nebenfach Klavier für eine Jazz-Aufnahmeprüfung können?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Die verbindlichen Anforderungen stehen in der Eignungsprüfungsordnung der jeweiligen Hochschule und unterscheiden sich deutlich. Wiederkehrende Bausteine sind ein Stück nach Leadsheet (Melodie plus Akkorde), Begleiten nach Akkordsymbolen und Kadenzen wie II-V-I in mehreren Tonarten. Dafür brauchst du Septakkorde und Voicings, die ohne Nachdenken kommen.',
				},
			},
			{
				'@type': 'Question',
				name: 'Wie bereite ich mich auf die Klavier-Nebenfachprüfung vor, wenn Klavier nicht mein Hauptinstrument ist?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Konzentrier dich auf Akkorde statt auf Technik: Septakkorde und Shell-Voicings in allen Tonarten, dann II-V-I und Blues, dann das Prüfungsstück nach Leadsheet. Kurze tägliche Einheiten bringen mehr als lange seltene, weil Voicings Reflexe sein müssen.',
				},
			},
			{
				'@type': 'Question',
				name: 'Reichen Shell-Voicings für die Aufnahmeprüfung?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Für viele Nebenfach-Prüfungen sind sauber und im Tempo gespielte Shell-Voicings eine solide Basis. Rootless-Voicings klingen voller und zeigen mehr Erfahrung; ob sie erwartet werden, steht in den Anforderungen deiner Hochschule oder lässt sich bei der Studienberatung erfragen.',
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
		<p class="plate-mark">Aufnahmeprüfung · Nebenfach Klavier</p>
		<h1>Aufnahmeprüfung Jazz-Klavier: Akkorde und Voicings vorbereiten</h1>
		<p class="lead">
			Wer Jazz oder Pop studieren will, spielt in der Eignungsprüfung oft auch
			Klavier vor, selbst wenn Gesang, Saxofon oder Gitarre das Hauptfach ist. Die
			Anforderungen stehen in Hochschul-PDFs. Diese Seite macht daraus eine
			Checkliste und einen Übeplan für den Teil, der am meisten Zeit kostet: Akkorde.
		</p>
	</header>

	<section aria-labelledby="what-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="what-h">Was in der Prüfung typischerweise drankommt</h2>
		</div>
		<p>
			Verbindlich ist nur die Prüfungsordnung deiner Hochschule, und die
			unterscheidet sich von Haus zu Haus. Bestimmte Bausteine tauchen aber immer
			wieder auf: ein Stück nach Leadsheet (Melodie plus Akkorde), Begleiten nach
			Akkordsymbolen und Kadenzen wie die II-V-I in mehreren Tonarten. Manche
			Hochschulen fragen zusätzlich Tonleitern oder Vom-Blatt-Spiel ab.
		</p>
		<p>
			Alle diese Bausteine haben eine gemeinsame Grundlage: Du musst ein
			Akkordsymbol sehen und den Griff sofort in der Hand haben. Genau das lässt sich
			gezielt trainieren.
		</p>
	</section>

	<section aria-labelledby="check-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="check-h">Checkliste: Diese Akkord-Fähigkeiten brauchst du</h2>
		</div>
		<ul class="check">
			{#each CHECKLIST as item (item.skill)}
				<li>
					<span class="skill">
						{#if item.href}<a href={item.href}>{item.skill}</a>{:else}{item.skill}{/if}
					</span>
					<span class="detail">{item.detail}</span>
				</li>
			{/each}
		</ul>
	</section>

	<section aria-labelledby="plan-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">III</span>
			<h2 id="plan-h">8-Wochen-Übeplan</h2>
		</div>
		<ol class="plan">
			{#each PLAN as step (step.weeks)}
				<li><span class="weeks">{step.weeks}</span> {step.focus}</li>
			{/each}
		</ol>
		<p>
			Hast du weniger Zeit, kürze Woche 1–4, aber nicht die Generalprobe. Hast du
			mehr, nimm dir mehr Tonarten in Rootless vor.
		</p>
		<p>
			Für die Akkord-Wochen gibt es den <a href="/train">Trainer</a>: Er zeigt dir
			Akkordsymbole, hört über dein MIDI-Keyboard zu und misst, wie schnell du jeden
			Griff findest. So siehst du schwarz auf weiß, welche Tonarten vor der Prüfung
			noch wackeln.
		</p>
		<a class="cta" href="/train">
			Akkorde für die Prüfung üben
			<ArrowRight size={18} aria-hidden="true" />
		</a>
	</section>

	<aside class="related">
		<p class="plate-mark blue">Weiterlesen</p>
		<ul>
			<li><a href="/de/voicings-linke-hand">Jazz-Voicings für die linke Hand: Shell und Rootless</a></li>
			<li><a href="/de/ii-v-i-alle-tonarten">II-V-I in allen 12 Tonarten (Tabelle)</a></li>
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


	.related { padding-top: 2.5rem; margin-top: 2.75rem; border-top: 1px solid var(--border); }
	.related ul { list-style: none; padding: 0; margin: 0; }
	.related li { padding: 0.55rem 0; font-size: 0.9375rem; color: var(--text-muted); border-bottom: 1px solid var(--border); }
	.related li:last-child { border-bottom: 0; }

	@media print {
		.lesson { padding: 0; max-width: none; }
	}

	.check, .plan { max-width: 64ch; margin: 0 0 1.25rem; padding: 0; list-style: none; }
	.check li, .plan li { padding: 0.7rem 0; border-bottom: 1px solid var(--border); font-size: 1rem; line-height: 1.6; color: var(--text-muted); }
	.check li:last-child, .plan li:last-child { border-bottom: 0; }
	.skill { display: block; font-weight: 600; color: var(--text); }
	.skill a { color: var(--primary); text-decoration: underline; text-underline-offset: 0.15em; text-decoration-thickness: 1px; }
	.detail { display: block; font-size: 0.9375rem; }
	.weeks { display: block; font-family: var(--font-mono); font-size: 0.6875rem; letter-spacing: 0.12em; text-transform: uppercase; font-weight: 600; color: var(--ink-blue); }
	.cta {
		display: inline-flex; align-items: center; gap: 0.5rem; min-height: var(--tap-min); padding: 0 1.4rem;
		border: 1.5px solid var(--primary); border-radius: var(--radius-sm); background: var(--primary);
		color: var(--primary-text); font-weight: 600; text-decoration: none;
	}
	.cta:hover { background: var(--primary-hover); border-color: var(--primary-hover); }
</style>
