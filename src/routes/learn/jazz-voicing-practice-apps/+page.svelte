<script lang="ts">
	import { ArrowRight } from 'lucide-svelte';

	const title = 'Apps to Practice Jazz Piano Voicings (2026): Honest Comparison | jazzchords.app';
	const description =
		'Which app actually drills jazz piano voicings? We compare MIDI voicing trainers, play-along apps, theory sites, books and courses: what each one trains, platforms and listed prices.';
	const canonical = 'https://jazzchords.app/learn/jazz-voicing-practice-apps';
	const checked = '15 October 2026';

	// Facts are taken from each product's own store listing or website on the
	// date above. No ratings or "best" claims: what it trains, where it runs,
	// what it lists as price.
	const tools = [
		{
			name: 'JazzChords (this site)',
			url: '/train',
			kind: 'Voicing drill + coach',
			platform: 'Web (MIDI in Chrome/Edge, microphone, on-screen); iOS app in preparation',
			trains: 'Shell, rootless A/B and 6 more voicing types in all 12 keys; ii-V-I and other progressions; times every chord and adapts the tempo',
			price: 'Free: unlimited practice, all voicings, MIDI & mic. Pro €7.99/month for long-term coaching and history',
			note: 'We built it, so weigh our view accordingly. Web MIDI does not work in Safari yet.',
		},
		{
			name: 'VoicingLab',
			url: 'https://voicinglab.com/',
			kind: 'Voicing drill',
			platform: 'Web, MIDI',
			trains: 'Voicing practice with mastery tracking; imports iReal Pro charts; teacher tier',
			price: 'Listed: £29 lifetime "Founding Member" offer',
			note: '',
		},
		{
			name: 'VoicingWorkout',
			url: 'https://apps.apple.com/app/voicingworkout/id6748817790',
			kind: 'Voicing drill',
			platform: 'iOS, MIDI',
			trains: 'Voicing drills across jazz, R&B, funk and neo-soul',
			price: 'Listed: Pro $8.99',
			note: '',
		},
		{
			name: 'Jazz Piano Voicings: Chord App',
			url: 'https://apps.apple.com/search?term=jazz%20piano%20voicings%20chord%20app',
			kind: 'Voicing flashcards',
			platform: 'iOS, MIDI or on-screen keys',
			trains: 'Voicing practice cards (listed: 1,400)',
			price: 'Listed: weekly, monthly, yearly or lifetime purchase',
			note: '',
		},
		{
			name: 'iReal Pro',
			url: 'https://www.irealpro.com/',
			kind: 'Play-along',
			platform: 'iOS, Android, Mac',
			trains: 'Backing tracks and chord charts for thousands of tunes. You comp along; it does not check what you play',
			price: 'One-time purchase',
			note: 'Great partner for a voicing drill once the shapes are in your hands.',
		},
		{
			name: 'musictheory.net',
			url: 'https://www.musictheory.net/',
			kind: 'Theory exercises',
			platform: 'Web, iOS (Tenuto)',
			trains: 'Note, interval and chord identification. No drills for specific jazz voicings',
			price: 'Web free; Tenuto app paid',
			note: '',
		},
	];

	const faqSchema = {
		'@context': 'https://schema.org',
		'@type': 'FAQPage',
		mainEntity: [
			{
				'@type': 'Question',
				name: 'Is there an app that drills jazz piano voicings?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'Yes. MIDI voicing trainers such as JazzChords, VoicingLab and VoicingWorkout show a chord symbol, listen to what you play on a MIDI keyboard and tell you whether the voicing is right. Play-along apps like iReal Pro give you backing tracks but do not check your voicings.',
				},
			},
			{
				'@type': 'Question',
				name: 'Do I need a MIDI keyboard to practice voicings with an app?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'A MIDI keyboard gives the most reliable feedback, because the app sees exactly which keys you press. Some apps, including JazzChords, also work with a microphone on an acoustic piano or with on-screen keys.',
				},
			},
			{
				'@type': 'Question',
				name: 'App, book or course: what should I use to learn jazz voicings?',
				acceptedAnswer: {
					'@type': 'Answer',
					text: 'They do different jobs. Books and courses (for example Mark Levine’s The Jazz Piano Book, Open Studio, Pianogroove) explain which voicings to use and why. A drill app makes those shapes automatic in all 12 keys. A play-along app like iReal Pro is where you then use them on tunes.',
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

<article class="lesson">
	<header class="masthead">
		<p class="plate-mark">Comparison · checked {checked}</p>
		<h1>Apps to Practice Jazz Piano Voicings</h1>
		<p class="lead">
			You know what a rootless voicing is, but your hands still grind to a halt
			on E♭7. That gap is what drill apps are for. Here is what each type of tool
			actually trains, so you can pick the one that fixes your problem.
		</p>
	</header>

	<section aria-labelledby="kinds-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">I</span>
			<h2 id="kinds-h">Four kinds of tools, four different jobs</h2>
		</div>
		<dl class="kinds">
			<dt>Books and video courses</dt>
			<dd>Explain which voicings to use and why. Mark Levine’s <em>The Jazz Piano Book</em>, Open Studio and Pianogroove are the usual starting points. They don’t check your playing.</dd>
			<dt>Voicing drill apps</dt>
			<dd>Show a chord symbol, listen to your MIDI keyboard and tell you if the voicing is right. This is the step that turns knowledge into reflexes in all 12 keys.</dd>
			<dt>Play-along apps</dt>
			<dd>Backing tracks and chord charts for real tunes. Where you use the voicings, not where you learn them.</dd>
			<dt>Theory trainers</dt>
			<dd>Note, interval and chord recognition. Useful for reading, but they don’t drill specific jazz voicings.</dd>
		</dl>
	</section>

	<section aria-labelledby="table-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">II</span>
			<h2 id="table-h">The tools, side by side</h2>
		</div>
		<p class="hint">From each product’s own listing on {checked}. Prices change; check the link before buying. Spotted something outdated? <a href="/feedback">Tell us</a>.</p>
		<div class="cards">
			{#each tools as tool (tool.name)}
				<article class="card">
					<h3>
						<a href={tool.url} rel={tool.url.startsWith('http') ? 'noopener' : undefined}>{tool.name}</a>
						<span class="kind">{tool.kind}</span>
					</h3>
					<dl>
						<dt>Runs on</dt><dd>{tool.platform}</dd>
						<dt>Trains</dt><dd>{tool.trains}</dd>
						<dt>Price</dt><dd>{tool.price}</dd>
					</dl>
					{#if tool.note}<p class="note">{tool.note}</p>{/if}
				</article>
			{/each}
		</div>
	</section>

	<section aria-labelledby="pick-h">
		<div class="sec-head">
			<span class="rehearsal" aria-hidden="true">III</span>
			<h2 id="pick-h">Which one fits your problem?</h2>
		</div>
		<ul class="pick">
			<li><strong>“I don’t know which notes to play.”</strong> Start with a book or course, or our <a href="/learn/jazz-piano-voicings">voicing guide</a>.</li>
			<li><strong>“I know the shapes but I’m slow in most keys.”</strong> A drill app with timing. Try the <a href="/learn/ii-v-i-all-keys">ii-V-I chart for all 12 keys</a>, then the <a href="/train">trainer</a>.</li>
			<li><strong>“My voicings are fine, I need to use them on tunes.”</strong> A play-along app like iReal Pro.</li>
			<li><strong>“I’m a teacher and want to see my students’ progress.”</strong> Look for a teacher tier, like our <a href="/for-educators">educator plan</a>.</li>
		</ul>
		<a class="cta" href="/train">
			Try the voicing drill, free
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
		font-family: var(--font-mono); font-size: 0.625rem; letter-spacing: 0.19em;
		text-transform: uppercase; font-weight: 600; color: var(--primary);
	}
	.plate-mark::after { content: ''; flex: 1; height: 1px; background: currentColor; opacity: 0.3; }
	h1 {
		font-family: var(--font-display); font-size: clamp(2rem, 5.4vw, 2.9rem); font-weight: 600;
		line-height: 1.08; letter-spacing: -0.025em; margin: 0; color: var(--text); text-wrap: balance;
	}
	.lead { font-size: 1.125rem; line-height: 1.65; color: var(--text-muted); max-width: 56ch; margin: 1rem 0 0; }
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
		border: 1.5px solid var(--primary); border-radius: var(--radius-sm); background: var(--primary);
		color: var(--primary-text); font-weight: 600; text-decoration: none;
	}
	.cta:hover { background: var(--primary-hover); border-color: var(--primary-hover); }
</style>
