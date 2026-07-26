<script lang="ts">
	import { t } from '$lib/i18n';
	import KeyClock from '$lib/components/KeyClock.svelte';
	import { buildKeyDial, loadHistory } from '$lib/services/progress';
	import { ArrowRight, Check, Keyboard, Mic, Play } from 'lucide-svelte';

	const curriculumSteps = [
		{ state: 'done', num: 'I', titleKey: 'landing.cur_s1_t', descKey: 'landing.cur_s1_d', chord: 'Cmaj7', notes: 'C · E · B' },
		{ state: 'done', num: 'II', titleKey: 'landing.cur_s2_t', descKey: 'landing.cur_s2_d', chord: 'C6/9', notes: 'C · E · A · D' },
		{ state: 'active', num: 'III', titleKey: 'landing.cur_s3_t', descKey: 'landing.cur_s3_d', chord: 'Dm9', notes: 'F · A · C · E' },
		{ state: 'locked', num: 'IV', titleKey: 'landing.cur_s4_t', descKey: 'landing.cur_s4_d', chord: 'G7/B', notes: 'B · F · G' },
		{ state: 'locked', num: 'V', titleKey: 'landing.cur_s5_t', descKey: 'landing.cur_s5_d', chord: 'G7♯5♭9', notes: 'B · F · A♭ · E♭' }
	] as const;

	const sessionBlocks = [
		{ labelKey: 'landing.coach_mock_b1', min: '2', state: 'done' },
		{ labelKey: 'landing.coach_mock_b2', min: '3', state: 'done' },
		{ labelKey: 'landing.coach_mock_b3', min: '3', state: 'now' },
		{ labelKey: 'landing.coach_mock_b4', min: '3', state: 'next' },
		{ labelKey: 'landing.coach_mock_b5', min: '2', state: 'next' }
	] as const;

	const faqItems = [
		{ qKey: 'landing.faq1_q', aKey: 'landing.faq1_a' },
		{ qKey: 'landing.faq2_q', aKey: 'landing.faq2_a' },
		{ qKey: 'landing.faq3_q', aKey: 'landing.faq3_a' },
		{ qKey: 'landing.faq4_q', aKey: 'landing.faq4_a' },
		{ qKey: 'landing.faq5_q', aKey: 'landing.faq5_a' }
	] as const;

	/* The hero specimen: a printed ii–V–I in B♭, with the V ringed as "now".
	   Musical glyphs are real ♭ ♯ characters, never emoji and never b/#.
	   Their spacing is handled by the AccidentalFit @font-face further down. */
	const specimenChords = [
		{ sym: 'Cm7', deg: 'ii', now: false },
		{ sym: 'F7', deg: 'V', now: true },
		{ sym: 'B♭maj7', deg: 'I', now: false },
		{ sym: 'G7♭9', deg: 'VI', now: false }
	] as const;

	const inputModes = [
		{ icon: Keyboard, key: 'landing.listen_chip1' },
		{ icon: Mic, key: 'landing.listen_chip2' },
		{ icon: Play, key: 'landing.listen_chip3' }
	] as const;

	/* The dial reads the visitor's own history. With none, KeyClock renders its
	   honest empty state ("12 TONARTEN") — better than inventing numbers.
	   loadHistory() touches localStorage, so it only runs after mount. */
	let dial = $state(buildKeyDial([]));
	$effect(() => {
		dial = buildKeyDial(loadHistory());
	});
</script>

<svelte:head>
	<title>{t('landing.meta_title')}</title>
	<meta name="description" content={t('landing.meta_desc')} />
	<link rel="canonical" href="https://jazzchords.app/" />
	<meta property="og:title" content={t('landing.meta_title')} />
	<meta property="og:description" content={t('landing.meta_desc')} />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://jazzchords.app/" />
	<meta property="og:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta property="og:image:type" content="image/webp" />
	<meta property="og:image:width" content="966" />
	<meta property="og:image:height" content="507" />
	<meta property="og:image:alt" content={t('landing.og_alt')} />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content={t('landing.twitter_title')} />
	<meta name="twitter:description" content={t('landing.twitter_desc')} />
	<meta name="twitter:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta name="twitter:image:alt" content={t('landing.og_alt')} />
	{@html `<script type="application/ld+json">${JSON.stringify({
		"@context": "https://schema.org",
		"@type": "FAQPage",
		"mainEntity": [
			{
				"@type": "Question",
				"name": "What is a jazz piano voicing?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "A jazz piano voicing is a specific arrangement of the notes in a chord. Instead of playing all notes stacked from the root, jazz pianists use voicings like shell voicings (root, third, seventh), rootless voicings (third, fifth, seventh, ninth), and inversions to create a richer, more professional sound. Mastering voicings in all 12 keys is the foundation of jazz piano."
				}
			},
			{
				"@type": "Question",
				"name": "How do I practice ii-V-I progressions efficiently?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "The most effective way to practice ii-V-I progressions is to drill them in all 12 keys until they become muscle memory. Start with shell voicings (root, third, seventh), then move to full voicings and rootless voicings. Use a speed-drill tool with a metronome to track your reaction time and identify which keys are weakest. Chord Trainer provides ii-V-I progressions in all 12 keys with MIDI recognition and weakness analysis."
				}
			},
			{
				"@type": "Question",
				"name": "What is a rootless voicing in jazz piano?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "A rootless voicing omits the root note and instead uses the third, fifth, seventh, and ninth of the chord. Bill Evans popularized two rootless voicing shapes: Rootless A (3-5-7-9) and Rootless B (7-9-3-5). They sound fuller and more professional than root-position chords, and work perfectly in a piano trio where the bassist covers the root."
				}
			},
			{
				"@type": "Question",
				"name": "Can I practice jazz chords with a MIDI keyboard?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "Yes. Chord Trainer supports MIDI keyboards via the Web MIDI API in Chrome and Edge on desktop. Connect your MIDI keyboard, select it in the app, and play along. The app recognizes chord voicings in real time — with octave tolerance and lenient matching so extra notes do not count against you — and automatically advances to the next chord when you play it correctly."
				}
			},
			{
				"@type": "Question",
				"name": "Is Chord Trainer free to use?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "Yes. All training features are free — the adaptive coach, every voicing type, progressions, MIDI support, and progress tracking. No account or signup required: open jazzchords.app and start practicing immediately. An optional Pro plan adds cloud sync and deeper statistics."
				}
			}
		]
	})}</script>`}
</svelte:head>

<div class="edi">

	<!-- ═══ Hero — an editorial spread, not a photo poster ═══ -->
	<section class="hero">
		<div class="staff-wash" aria-hidden="true"></div>
		<div class="shell hero-inner">
			<div class="hero-head">
				<p class="eyebrow">{t('landing.badge')}</p>
				<h1 class="hero-h1">
					{t('landing.hero_title_line1')}<span class="l2">{t('landing.hero_title_line2')}</span>
				</h1>
				<p class="hero-lede">{t('landing.hero_subtitle')}</p>

				<div class="hero-cta">
					<a href="/train" class="btn btn-stamp">
						{t('landing.cta_start')}
						<ArrowRight size={17} />
					</a>
					<a href="/learn" class="btn btn-ghost">{t('landing.cta_learn')}</a>
					<a href="/for-educators" class="btn btn-ghost hide-sm">{t('landing.cta_educators')}</a>
				</div>

				<p class="hero-fine">{t('landing.hero_no_midi')}</p>
				<p class="plate hero-plate">{t('landing.footnote')}</p>
			</div>

			<!-- The lead-sheet specimen: the product's own language, printed. -->
			<figure class="specimen">
				<figcaption class="spec-head">
					<span class="rehearsal">A</span>
					<span class="spec-titles">
						<span class="spec-title">{t('landing.spec_title')}</span>
						<span class="plate">{t('landing.spec_plate')}</span>
					</span>
				</figcaption>
				<div class="spec-body">
					<div class="spec-staff">
						<div class="spec-lines" aria-hidden="true"></div>
						<div class="spec-chords">
							{#each specimenChords as c}
								<span class="spec-chord" class:now={c.now}>
									<span class="sym">{c.sym}</span>
									<span class="deg">{c.deg}</span>
								</span>
							{/each}
						</div>
					</div>
					<p class="spec-note">{t('landing.spec_note')}</p>
				</div>
			</figure>
		</div>
	</section>

	<!-- ═══ B · Meet your coach ═══ -->
	<section class="sec">
		<div class="shell">
			<div class="sec-head">
				<span class="rehearsal">B</span>
				<div class="sec-col">
					<p class="eyebrow">{t('landing.coach_eyebrow')}</p>
					<h2 class="sec-h2">{t('landing.coach_title')}</h2>
					<p class="sec-lede">{t('landing.coach_desc')}</p>
				</div>
			</div>

			<div class="pair">
				<div>
					<ol class="contents">
						<li class="row">
							<span class="no">01</span>
							<span class="row-txt">
								<span class="ttl">{t('landing.coach_b1_t')}</span>
								<span class="dsc">{t('landing.coach_b1_d')}</span>
							</span>
						</li>
						<li class="row">
							<span class="no">02</span>
							<span class="row-txt">
								<span class="ttl">{t('landing.coach_b2_t')}</span>
								<span class="dsc">{t('landing.coach_b2_d')}</span>
							</span>
						</li>
						<li class="row">
							<span class="no">03</span>
							<span class="row-txt">
								<span class="ttl">{t('landing.coach_b3_t')}</span>
								<span class="dsc">{t('landing.coach_b3_d')}</span>
							</span>
						</li>
					</ol>
					<blockquote class="marginalia">
						{t('landing.coach_mock_fb')}
						<span class="plate">{t('landing.coach_mock_fb_label')}</span>
					</blockquote>
				</div>

				<!-- Session plan, as a printed running order -->
				<div class="mock" aria-hidden="true">
					<p class="mock-say">{t('landing.coach_mock_say')}</p>
					<ul class="plan">
						{#each sessionBlocks as block}
							<li class="plan-row" class:on={block.state === 'now'} class:next={block.state === 'next'}>
								<span class="plan-mark">
									{#if block.state === 'done'}<Check size={13} />{:else if block.state === 'now'}●{:else}○{/if}
								</span>
								<span class="plan-d">{t(block.labelKey)}</span>
								<span class="plan-min">{block.min} min</span>
							</li>
						{/each}
					</ul>
					<p class="mock-foot">{t('landing.coach_mock_btn')}</p>
				</div>
			</div>
		</div>
	</section>

	<!-- ═══ C · Curriculum, as a printed table of contents ═══ -->
	<section class="sec">
		<div class="shell">
			<div class="sec-head">
				<span class="rehearsal">C</span>
				<div class="sec-col">
					<p class="eyebrow blue">{t('landing.cur_eyebrow')}</p>
					<h2 class="sec-h2">{t('landing.cur_title')}</h2>
					<p class="sec-lede">{t('landing.cur_desc')}</p>
				</div>
			</div>

			<ol class="contents ruled">
				{#each curriculumSteps as step}
					<li class="cur-row" class:locked={step.state === 'locked'}>
						<span class="no roman">{step.num}</span>
						<span class="row-txt">
							<span class="ttl">
								{t(step.titleKey)}
								{#if step.state === 'active'}<em class="tag-live">{t('landing.cur_now')}</em>{/if}
							</span>
							<span class="dsc">{t(step.descKey)}</span>
						</span>
						<span class="cur-voicing">
							<b>{step.chord}</b><span class="sep">·</span>{step.notes}
						</span>
					</li>
				{/each}
			</ol>
			<p class="sec-foot">{t('landing.cur_foot')}</p>
		</div>
	</section>

	<!-- ═══ D · The twelve keys — the clock, mid-weight ═══ -->
	<section class="sec">
		<div class="shell">
			<div class="sec-head">
				<span class="rehearsal">D</span>
				<div class="sec-col">
					<p class="eyebrow blue">{t('landing.clock_eyebrow')}</p>
					<h2 class="sec-h2">{t('landing.clock_title')}</h2>
				</div>
			</div>

			<div class="clock-pair">
				<div class="clock-frame">
					<KeyClock {dial} size={252} showTimes={false} />
					<p class="plate clock-cap">{t('landing.clock_caption')}</p>
				</div>
				<div class="clock-copy">
					<p class="sec-lede tight">{t('landing.clock_desc')}</p>
					<ul class="legend">
						<li><i class="sw fast"></i>{t('landing.clock_legend_fast')}</li>
						<li><i class="sw slow"></i>{t('landing.clock_legend_slow')}</li>
						<li><i class="sw none"></i>{t('landing.clock_legend_none')}</li>
					</ul>
				</div>
			</div>
		</div>
	</section>

	<!-- ═══ E · It listens ═══ -->
	<section class="sec">
		<div class="shell">
			<div class="sec-head">
				<span class="rehearsal">E</span>
				<div class="sec-col">
					<p class="eyebrow">{t('landing.listen_eyebrow')}</p>
					<h2 class="sec-h2">{t('landing.listen_title')}</h2>
					<p class="sec-lede">{t('landing.listen_desc')}</p>
				</div>
			</div>

			<ul class="modes">
				{#each inputModes as mode}
					<li class="mode">
						<mode.icon size={19} />
						<span>{t(mode.key)}</span>
					</li>
				{/each}
			</ul>

			<!-- Habit: three figures on a ledger rule, not three cards -->
			<div class="habit">
				<p class="eyebrow blue">{t('landing.habit_eyebrow')}</p>
				<h3 class="habit-h3">{t('landing.habit_title')}</h3>
				<p class="sec-lede tight">{t('landing.habit_desc')}</p>
				<div class="ledger" aria-hidden="true">
					<div class="cell"><span class="v">12</span><span class="l">{t('landing.habit_stat1')}</span></div>
					<div class="cell"><span class="v">5/5</span><span class="l">{t('landing.habit_stat2')}</span></div>
					<div class="cell"><span class="v small">{t('landing.habit_stat3')}</span><span class="l">Lv. 4</span></div>
				</div>
				<blockquote class="marginalia">
					{t('landing.habit_quote')}
					<span class="plate">{t('landing.habit_quote_label')}</span>
				</blockquote>
			</div>
		</div>
	</section>

	<!-- ═══ F · FAQ ═══ -->
	<section class="sec">
		<div class="shell">
			<div class="sec-head">
				<span class="rehearsal">F</span>
				<div class="sec-col">
					<p class="eyebrow">{t('landing.sec_faq_eyebrow')}</p>
					<h2 class="sec-h2">{t('landing.faq_title')}</h2>
				</div>
			</div>
			<div class="faq">
				{#each faqItems as item}
					<details>
						<summary>{t(item.qKey)}</summary>
						<p class="ans">{t(item.aKey)}</p>
					</details>
				{/each}
			</div>
		</div>
	</section>

	<!-- ═══ Fine — closing CTA + colophon ═══ -->
	<section class="shell">
		<div class="fine">
			<p class="eyebrow mid">{t('landing.sec_fine')}</p>
			<h2 class="fine-h2">{t('landing.cta2_title')}</h2>
			<p class="fine-p">{t('landing.cta2_desc')}</p>
			<div class="fine-btns">
				<a href="/train" class="btn btn-stamp">
					{t('landing.cta_start')}
					<ArrowRight size={18} />
				</a>
				<a href="/pricing" class="btn btn-ghost">{t('landing.cta_learn')}</a>
			</div>
			<p class="plate fine-note">{t('landing.footnote')}</p>
		</div>

		<div class="colophon">
			<span class="plate">{t('landing.colophon_left')}</span>
			<span class="plate">{t('landing.colophon_right')}</span>
		</div>
	</section>
</div>

<style>
	/* ─────────────────────────────────────────────────────────────
	   THE COPYIST'S BLUEPRINT — landing page
	   Structure comes from hairlines, whitespace and section marks.
	   Two inks: stamp red (--primary) is the loud one, copyist blue
	   (--ink-blue) annotates. Amber is reserved for live state only.
	   Every colour resolves to a token in app.css.
	───────────────────────────────────────────────────────────── */

	/* The AccidentalFit face is declared globally in app.css — accidentals are
	   printed on every page, not just this one. */

	.edi {
		--rule: color-mix(in srgb, var(--border) 100%, transparent);
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		--staff: color-mix(in srgb, var(--ink-blue) 30%, transparent);
		/* AccidentalFit is unicode-range-scoped, so it only ever claims ♭ ♯ ° ø;
		   every other character still comes from the normal stack below it. */
		--font-display-mus: 'AccidentalFit', var(--font-display);
		--font-sans-mus: 'AccidentalFit', var(--font-sans);
		font-family: var(--font-sans-mus);
		font-variant-numeric: oldstyle-nums;
	}

	.shell {
		max-width: 1120px;
		margin: 0 auto;
		padding: 0 1.25rem;
	}
	@media (min-width: 900px) {
		.shell { padding: 0 2.5rem; }
	}

	/* ── Editorial primitives ─────────────────────────────────── */

	.eyebrow {
		display: flex;
		align-items: center;
		gap: 0.625rem;
		font-family: var(--font-mono);
		font-size: 0.66rem;
		font-weight: 600;
		letter-spacing: 0.19em;
		text-transform: uppercase;
		color: var(--primary);
	}
	.eyebrow::after {
		content: '';
		flex: 1;
		min-width: 1rem;
		height: 1px;
		background: currentColor;
		opacity: 0.32;
	}
	.eyebrow.blue { color: var(--ink-blue); }
	.eyebrow.mid { justify-content: center; }
	.eyebrow.mid::after { display: none; }

	/* Rehearsal mark — the boxed letter that numbers a section. */
	.rehearsal {
		display: inline-grid;
		place-items: center;
		flex: none;
		min-width: 1.7rem;
		height: 1.7rem;
		padding: 0 0.4rem;
		border: 1.5px solid var(--text);
		font-family: var(--font-mono);
		font-size: 0.78rem;
		font-weight: 700;
		color: var(--text);
	}

	.plate {
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	/* Blue-pencil marginalia — the copyist's note in the margin. */
	.marginalia {
		margin: 1.5rem 0 0;
		padding-left: 0.9rem;
		border-left: 2px solid var(--ink-blue);
		font-family: var(--font-display-mus);
		font-size: 1rem;
		font-style: italic;
		line-height: 1.5;
		color: var(--text-muted);
	}
	.marginalia .plate {
		display: block;
		margin-top: 0.5rem;
		font-style: normal;
	}

	/* ── Buttons — solid ink, no gradients, no glow ───────────── */

	.btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.55rem;
		min-height: var(--tap-min);
		padding: 0 1.35rem;
		border-radius: var(--radius-sm);
		border: 1.5px solid var(--text);
		background: var(--text);
		color: var(--bg);
		font-size: 0.94rem;
		font-weight: 600;
		text-decoration: none;
		transition: transform 0.12s ease-out, background-color 0.12s, border-color 0.12s;
	}
	.btn:hover { transform: translateY(-1px); }
	.btn:active { transform: none; }

	.btn-stamp {
		background: var(--primary);
		border-color: var(--primary);
		color: var(--primary-text);
	}
	.btn-stamp:hover {
		background: var(--primary-hover);
		border-color: var(--primary-hover);
	}
	.btn-ghost {
		background: transparent;
		border-color: var(--border);
		color: var(--text);
	}
	.btn-ghost:hover {
		border-color: var(--text);
		background: var(--bg-card);
	}

	/* ── Hero ─────────────────────────────────────────────────── */

	.hero {
		position: relative;
		overflow: hidden;
		padding: 2.5rem 0 3rem;
	}
	@media (min-width: 900px) {
		.hero { padding: 4.5rem 0 5rem; }
	}

	/* A band of staff lines washing behind the hero. On narrow screens the
	   headline grows down into this band and the rules read as a strike-through,
	   so the wash only appears once there is whitespace for it to sit in. */
	.staff-wash { display: none; }
	@media (min-width: 980px) {
		.staff-wash {
			display: block;
			position: absolute;
			left: 0;
			right: 0;
			top: 7rem;
			height: 8rem;
			pointer-events: none;
			opacity: 0.42;
			background: repeating-linear-gradient(to bottom, transparent 0 23px, var(--staff) 23px 24px);
		}
	}

	.hero-inner { position: relative; }
	@media (min-width: 980px) {
		.hero-inner {
			display: grid;
			grid-template-columns: minmax(0, 1.03fr) minmax(0, 0.97fr);
			gap: 3.5rem;
			align-items: start;
		}
	}

	.hero-h1 {
		margin: 1rem 0 0;
		font-family: var(--font-display-mus);
		/* Sized against the LONGER of the two locales (German runs ~15% longer
		   than English here). At 6vw the German headline took four lines and
		   pushed the CTA under the fold at 1280×860. */
		font-size: clamp(2rem, 4.2vw, 3.1rem);
		font-weight: 600;
		line-height: 1.08;
		letter-spacing: -0.026em;
		/* em-based measure: scales with the headline, not the 16px parent —
		   this is what stops the hero collapsing to one word per line. */
		max-width: 15em;
		text-wrap: balance;
		color: var(--text);
	}
	.hero-h1 .l2 {
		display: block;
		font-style: italic;
		font-weight: 400;
		color: var(--text-muted);
	}

	.hero-lede {
		margin-top: 1.35rem;
		max-width: 46ch;
		font-size: 1.05rem;
		line-height: 1.62;
		color: var(--text-muted);
	}

	.hero-cta {
		display: flex;
		flex-wrap: wrap;
		gap: 0.7rem;
		margin-top: 1.6rem;
	}

	.hero-fine {
		margin-top: 1.15rem;
		max-width: 48ch;
		font-size: 0.9rem;
		line-height: 1.55;
		color: var(--text-muted);
	}
	.hero-plate { margin-top: 1rem; }

	@media (max-width: 640px) {
		.hide-sm { display: none; }
	}

	/* ── The lead-sheet specimen ──────────────────────────────── */

	.specimen {
		margin: 2.25rem 0 0;
		background: var(--bg-card);
		border: 1px solid var(--border);
		box-shadow: var(--shadow-md);
	}
	@media (min-width: 980px) {
		.specimen { margin-top: 0.5rem; }
	}

	.spec-head {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 0.7rem 1rem;
		border-bottom: 1px solid var(--border);
		background: var(--bg-muted);
	}
	.spec-titles { min-width: 0; }
	.spec-title {
		display: block;
		font-family: var(--font-display-mus);
		font-size: 0.92rem;
		font-weight: 600;
		color: var(--text);
	}

	.spec-body { padding: 1.1rem 1rem 1.25rem; }

	.spec-staff {
		position: relative;
		padding: 1.4rem 0 0.4rem;
	}
	.spec-lines {
		position: absolute;
		inset: 0;
		top: 0.9rem;
		height: 2.6rem;
		background: repeating-linear-gradient(to bottom, transparent 0 9px, var(--staff) 9px 10px);
	}
	.spec-chords {
		position: relative;
		display: flex;
		gap: 0.25rem;
		align-items: flex-end;
		min-height: 3.9rem;
	}
	.spec-chord {
		position: relative;
		flex: 1;
		min-width: 0;
		text-align: center;
	}
	.spec-chord .sym {
		position: relative;
		z-index: 2;
		display: inline-block;
		padding: 0 0.2rem;
		background: var(--bg-card);
		font-family: var(--font-display-mus);
		font-size: clamp(0.95rem, 3.4vw, 1.28rem);
		font-weight: 600;
		font-variant-numeric: lining-nums;
		color: var(--text);
	}
	.spec-chord .deg {
		display: block;
		margin-top: 2.15rem;
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.1em;
		color: var(--ink-blue);
	}
	/* The V chord is ringed in red pencil — "you are here". */
	.spec-chord.now .sym { color: var(--primary); }
	.spec-chord.now::after {
		content: '';
		position: absolute;
		left: 50%;
		bottom: 0.9rem;
		transform: translateX(-50%);
		width: 1.6rem;
		height: 1.6rem;
		border: 1.5px solid var(--primary);
		border-radius: 50%;
		opacity: 0.55;
	}

	.spec-note {
		display: block;
		margin: 0;
		padding-top: 0.9rem;
		border-top: 1px dashed var(--border);
		font-family: var(--font-display-mus);
		font-size: 0.95rem;
		font-style: italic;
		line-height: 1.45;
		color: var(--ink-blue);
	}

	/* ── Sections ─────────────────────────────────────────────── */

	.sec {
		padding: 3rem 0;
		border-top: 1px solid var(--rule-soft);
	}
	@media (min-width: 900px) {
		.sec { padding: 4.25rem 0; }
	}

	.sec-head {
		display: flex;
		align-items: flex-start;
		gap: 1rem;
		margin-bottom: 1.75rem;
	}
	.sec-col {
		flex: 1;
		min-width: 0;
	}
	.sec-h2 {
		margin: 0.7rem 0 0;
		font-family: var(--font-display-mus);
		font-size: clamp(1.5rem, 3.9vw, 2.25rem);
		font-weight: 600;
		line-height: 1.14;
		letter-spacing: -0.018em;
		max-width: 22ch;
		text-wrap: balance;
		color: var(--text);
	}
	.sec-lede {
		margin: 0.85rem 0 0;
		max-width: 66ch;
		font-size: 1rem;
		line-height: 1.62;
		color: var(--text-muted);
	}
	.sec-lede.tight { margin-top: 0; }
	.sec-foot {
		margin: 1.5rem 0 0;
		max-width: 60ch;
		font-size: 0.94rem;
		line-height: 1.6;
		color: var(--text-muted);
	}

	.pair {
		display: grid;
		gap: 1.75rem;
		align-items: start;
	}
	@media (min-width: 820px) {
		.pair { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 2.5rem; }
	}

	/* ── Printed contents list ────────────────────────────────── */

	.contents {
		list-style: none;
		margin: 0;
		padding: 0;
	}
	.contents.ruled { border-top: 1px solid var(--border); }

	.row,
	.cur-row {
		display: grid;
		grid-template-columns: auto minmax(0, 1fr);
		gap: 0.9rem;
		align-items: baseline;
		padding: 0.9rem 0;
		border-bottom: 1px solid var(--rule-soft);
	}
	.cur-row {
		grid-template-columns: auto minmax(0, 1fr);
	}
	@media (min-width: 760px) {
		.cur-row { grid-template-columns: auto minmax(0, 1fr) auto; }
	}
	.cur-row.locked { opacity: 0.55; }

	.no {
		font-family: var(--font-mono);
		font-size: 0.7rem;
		letter-spacing: 0.08em;
		color: var(--text-dim);
	}
	.no.roman { min-width: 1.6rem; }

	.row-txt { min-width: 0; }
	.ttl {
		display: block;
		font-family: var(--font-display-mus);
		font-size: 1.06rem;
		font-weight: 600;
		color: var(--text);
	}
	.dsc {
		display: block;
		margin-top: 0.15rem;
		font-size: 0.88rem;
		line-height: 1.5;
		color: var(--text-muted);
	}

	/* Amber earns its keep here and only here: this step is live. */
	.tag-live {
		display: inline-block;
		margin-left: 0.5rem;
		padding: 0.1rem 0.45rem;
		border: 1px solid var(--accent-amber);
		border-radius: 999px;
		font-family: var(--font-mono);
		font-size: 0.58rem;
		font-style: normal;
		font-weight: 600;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--accent-amber);
		vertical-align: middle;
	}

	.cur-voicing {
		grid-column: 2;
		font-family: var(--font-mono);
		font-size: 0.78rem;
		white-space: nowrap;
		color: var(--text-muted);
	}
	@media (min-width: 760px) {
		.cur-voicing { grid-column: 3; text-align: right; }
	}
	.cur-voicing b { color: var(--primary); font-weight: 600; }
	.cur-voicing .sep { margin: 0 0.35rem; opacity: 0.4; }

	/* ── Coach session mock ───────────────────────────────────── */

	.mock {
		border: 1px solid var(--border);
		border-left: 3px solid var(--primary);
		background: var(--bg-card);
	}
	.mock-say {
		margin: 0;
		padding: 1.05rem 1.1rem;
		border-bottom: 1px solid var(--rule-soft);
		font-family: var(--font-display-mus);
		font-size: 1.02rem;
		font-style: italic;
		line-height: 1.4;
		color: var(--text);
	}
	.plan {
		list-style: none;
		margin: 0;
		padding: 0.4rem 0;
	}
	.plan-row {
		display: flex;
		align-items: center;
		gap: 0.7rem;
		padding: 0.5rem 1.1rem;
		font-size: 0.87rem;
		color: var(--text-muted);
	}
	.plan-row.next { opacity: 0.55; }
	/* Live block: amber, the one reserved use. */
	.plan-row.on {
		background: color-mix(in srgb, var(--accent-amber) 12%, transparent);
		color: var(--text);
		font-weight: 600;
	}
	.plan-mark {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		flex: none;
		width: 1rem;
		font-size: 0.6rem;
		color: var(--text-dim);
	}
	.plan-row.on .plan-mark { color: var(--accent-amber); }
	.plan-row :global(svg) { color: var(--accent-green); }
	.plan-d {
		min-width: 0;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.plan-min {
		margin-left: auto;
		flex: none;
		font-family: var(--font-mono);
		font-size: 0.68rem;
		color: var(--text-dim);
	}
	.mock-foot {
		margin: 0;
		padding: 0.8rem 1.1rem;
		border-top: 1px solid var(--rule-soft);
		font-family: var(--font-mono);
		font-size: 0.66rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--primary);
	}

	/* ── The clock — mid-weight, never the hero ───────────────── */

	.clock-pair {
		display: grid;
		gap: 1.75rem;
		align-items: center;
	}
	@media (min-width: 820px) {
		.clock-pair {
			grid-template-columns: auto minmax(0, 1fr);
			gap: 3rem;
		}
	}

	.clock-frame {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.85rem;
		padding: 1.5rem;
		border: 1px solid var(--border);
		background: var(--bg-card);
	}
	.clock-cap {
		/* Mono uppercase eats width fast; a 22ch cap broke this to four ragged
		   lines under the dial. Let it run the frame's width and sit on two. */
		max-width: none;
		text-align: center;
		line-height: 1.7;
		text-wrap: balance;
	}

	.legend {
		list-style: none;
		display: flex;
		flex-wrap: wrap;
		gap: 0.6rem 1.35rem;
		margin: 1.35rem 0 0;
		padding: 0;
		font-family: var(--font-mono);
		font-size: 0.66rem;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--text-muted);
	}
	.legend li {
		display: flex;
		align-items: center;
		gap: 0.45rem;
	}
	.sw {
		width: 0.7rem;
		height: 0.7rem;
		flex: none;
	}
	.sw.fast { background: var(--accent-green); }
	.sw.slow { background: var(--primary); }
	.sw.none {
		border: 1px dashed var(--border-hover);
		background: transparent;
	}

	/* ── Input modes — a rule of three, not three cards ───────── */

	.modes {
		list-style: none;
		display: grid;
		gap: 0;
		margin: 0;
		padding: 0;
		border-top: 1px solid var(--border);
		border-bottom: 1px solid var(--border);
	}
	@media (min-width: 700px) {
		.modes { grid-template-columns: repeat(3, 1fr); }
	}
	.mode {
		display: flex;
		align-items: center;
		gap: 0.7rem;
		padding: 0.95rem 0;
		font-family: var(--font-display-mus);
		font-size: 1rem;
		font-weight: 600;
		color: var(--text);
		border-bottom: 1px solid var(--rule-soft);
	}
	.mode:last-child { border-bottom: none; }
	@media (min-width: 700px) {
		.mode {
			padding: 1rem 1.25rem 1rem 0;
			border-bottom: none;
			border-right: 1px solid var(--rule-soft);
		}
		.mode:not(:first-child) { padding-left: 1.25rem; }
		.mode:last-child { border-right: none; }
	}
	.mode :global(svg) {
		flex: none;
		color: var(--ink-blue);
	}

	/* ── Habit ledger ─────────────────────────────────────────── */

	.habit { margin-top: 2.75rem; }
	.habit-h3 {
		margin: 0.7rem 0 0;
		font-family: var(--font-display-mus);
		font-size: clamp(1.3rem, 3.2vw, 1.75rem);
		font-weight: 600;
		line-height: 1.16;
		letter-spacing: -0.015em;
		color: var(--text);
	}
	.habit .sec-lede { margin-top: 0.85rem; }

	.ledger {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1px;
		margin-top: 1.5rem;
		border: 1px solid var(--border);
		background: var(--border);
	}
	.cell {
		display: flex;
		flex-direction: column;
		gap: 0.4rem;
		padding: 1rem 0.9rem;
		background: var(--bg-card);
	}
	.cell .v {
		font-family: var(--font-display-mus);
		font-size: clamp(1.5rem, 4.6vw, 2.1rem);
		font-weight: 600;
		line-height: 1;
		font-variant-numeric: lining-nums;
		color: var(--text);
	}
	.cell .v.small { font-size: clamp(1rem, 3vw, 1.3rem); }
	.cell .l {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	/* ── FAQ ──────────────────────────────────────────────────── */

	.faq {
		max-width: 68ch;
		border-top: 1px solid var(--border);
	}
	.faq details { border-bottom: 1px solid var(--rule-soft); }
	.faq summary {
		display: flex;
		align-items: center;
		position: relative;
		min-height: var(--tap-min);
		padding: 0.9rem 1.75rem 0.9rem 0;
		cursor: pointer;
		list-style: none;
		font-family: var(--font-display-mus);
		font-size: 1.02rem;
		font-weight: 600;
		color: var(--text);
	}
	.faq summary::-webkit-details-marker { display: none; }
	.faq summary::after {
		content: '+';
		position: absolute;
		right: 0.1rem;
		top: 50%;
		transform: translateY(-50%);
		font-family: var(--font-mono);
		font-size: 1.05rem;
		color: var(--primary);
	}
	.faq details[open] summary::after { content: '–'; }
	.faq .ans {
		margin: 0;
		padding: 0 0 1rem;
		max-width: 62ch;
		font-size: 0.95rem;
		line-height: 1.62;
		color: var(--text-muted);
	}

	/* ── Fine — closing CTA + colophon ────────────────────────── */

	.fine {
		padding: 3.25rem 0 0.5rem;
		border-top: 1px solid var(--rule-soft);
		text-align: center;
	}
	.fine-h2 {
		margin: 0.85rem auto 0;
		max-width: 17ch;
		font-family: var(--font-display-mus);
		font-size: clamp(1.6rem, 4.6vw, 2.5rem);
		font-weight: 600;
		line-height: 1.12;
		letter-spacing: -0.02em;
		text-wrap: balance;
		color: var(--text);
	}
	.fine-p {
		margin: 0.9rem auto 0;
		max-width: 44ch;
		font-size: 1rem;
		line-height: 1.6;
		color: var(--text-muted);
	}
	.fine-btns {
		display: flex;
		flex-wrap: wrap;
		justify-content: center;
		gap: 0.7rem;
		margin-top: 1.6rem;
	}
	.fine-note { margin-top: 1.1rem; }

	.colophon {
		display: flex;
		flex-wrap: wrap;
		gap: 0.75rem 1.5rem;
		justify-content: space-between;
		align-items: baseline;
		margin-top: 3.25rem;
		padding: 1.35rem 0 2.5rem;
		border-top: 2px solid var(--text);
	}

	@media (prefers-reduced-motion: reduce) {
		.btn { transition: none; }
		.btn:hover { transform: none; }
	}
</style>
