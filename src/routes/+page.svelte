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

	/* The hero practice card's keyboard: an octave and a half with the B♭7
	   shell struck — B♭ (black), D (white), A♭ (black). That is a real shell
	   voicing: the third and the seventh of B♭7, no root.

	   Geometry is derived from ONE unit (100 / whites.length) rather than
	   hardcoded percentages, so the board stays correct if the range changes.
	   Musical glyphs are real ♭ ♯ characters, never emoji and never b/#;
	   their spacing is handled by the AccidentalFit @font-face further down. */
	const whiteKeys = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'A', 'B'] as const;

	/* Struck white key, by index into whiteKeys: D in the first octave. */
	const struckWhite: Record<number, string> = { 1: 'D' };

	const KEY_UNIT = 100 / whiteKeys.length;
	/* A black key is ~58% the width of a white one. At a full unit they fused
	   into slabs, so the board is drawn at 0.58 × unit and centred on the gap. */
	const BLACK_W = 0.58 * KEY_UNIT;

	/* Black keys follow the white indices they sit after, per octave:
	   C♯ D♯ — F♯ G♯ A♯. */
	const BLACK_PATTERN = [0, 1, 3, 4, 5] as const;

	const blackKeys = (() => {
		const out: { left: number; name: string | null }[] = [];
		for (let oct = 0; oct < 2; oct++) {
			for (const p of BLACK_PATTERN) {
				const idx = oct * 7 + p;
				if (idx >= whiteKeys.length - 1) continue;
				/* B♭ is the A♯ of the first octave (p=5), A♭ its G♯ (p=4). */
				const name = oct === 0 && p === 5 ? 'B♭' : oct === 0 && p === 4 ? 'A♭' : null;
				out.push({ left: (idx + 1) * KEY_UNIT - BLACK_W / 2, name });
			}
		}
		return out;
	})();

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

	<!-- ═══ Hero — "Der Saal": the club photograph, type set over it ═══ -->
	<section class="hero">
		<div class="hero-media" aria-hidden="true">
			<picture>
				<source
					srcset="/bilder/hero-piano-480.avif 480w, /bilder/hero-piano-768.avif 768w, /bilder/hero-piano-1280.avif 1280w, /bilder/hero-piano-1920.avif 1920w"
					sizes="100vw"
					type="image/avif"
				/>
				<source
					srcset="/bilder/hero-piano-480.webp 480w, /bilder/hero-piano-768.webp 768w, /bilder/hero-piano-1280.webp 1280w, /bilder/hero-piano-1920.webp 1920w"
					sizes="100vw"
					type="image/webp"
				/>
				<img
					src="/bilder/hero-piano-1280.webp"
					alt=""
					width="1280"
					height="714"
					fetchpriority="high"
					decoding="async"
				/>
			</picture>
		</div>
		<div class="shell hero-inner">
			<div class="hero-head">
				<p class="eyebrow">{t('landing.badge')}</p>
				<h1 class="hero-h1">
					{t('landing.hero_title_line1')}<span class="l2">{t('landing.hero_title_line2')}</span>
				</h1>
				<p class="hero-lede">{t('landing.hero_subtitle')}</p>

				<div class="hero-cta">
					<span class="cta-stack">
						<a href="/train" class="btn btn-stamp">
							{t('landing.cta_start')}
							<ArrowRight size={17} />
						</a>
						<!-- The reassurance belongs ON the decision, not three
						     paragraphs below it. Small, green, one line: it answers
						     "what does this cost me" before the click without
						     competing with the button it sits under. -->
						<span class="cta-badge">{t('landing.cta_badge')}</span>
					</span>
					<a href="/learn" class="btn btn-ghost">{t('landing.cta_learn')}</a>
					<a href="/for-educators" class="btn btn-ghost hide-sm">{t('landing.cta_educators')}</a>
				</div>

				<p class="hero-fine">{t('landing.hero_no_midi')}</p>
			</div>

			<!-- The practice card: the loop the app actually runs, top to bottom.
			     A chord is asked, a keyboard answers it, a stopwatch judges it.
			     A stranger should conclude "this drills chords and times you"
			     without reading a word of caption. -->
			<figure class="pcard">
				<figcaption class="pcard-head">
					<span class="rehearsal">A</span>
					<span class="live-dot" aria-hidden="true"></span>
					<span class="live-tag">{t('landing.pcard_live')}</span>
					<span class="plate">{t('landing.pcard_head')}</span>
				</figcaption>

				<div class="pcard-body">
					<span class="p-step">{t('landing.pcard_step_ask')}</span>
					<div class="p-ask">
						<span class="p-chord">{t('landing.pcard_chord')}</span>
						<span class="p-voicing">
							{t('landing.pcard_voicing_name')}<br />{t('landing.pcard_voicing_notes')}
						</span>
					</div>

					<span class="p-arrow">{t('landing.pcard_step_answer')}</span>
					<div class="kbd" role="img" aria-label={t('landing.pcard_kbd_alt')}>
						{#each whiteKeys as _key, i}
							<span class="wk" class:on={struckWhite[i]} data-n={struckWhite[i] ?? null}></span>
						{/each}
						{#each blackKeys as bk}
							<span
								class="bk"
								class:on={bk.name}
								data-n={bk.name}
								style="left:{bk.left.toFixed(2)}%; width:{BLACK_W.toFixed(2)}%"
							></span>
						{/each}
					</div>

					<div class="p-result">
						<span class="p-check" aria-hidden="true">✓</span>
						<span class="p-verdict">{t('landing.pcard_verdict')}</span>
						<span class="p-time">
							<b>{t('landing.pcard_time_now')}</b><span>{t('landing.pcard_time_label')}</span>
						</span>
					</div>

					<div class="p-bars">
						<span class="p-bar">
							<span>{t('landing.pcard_bar_last')}</span><i style="width:100%"></i><b
							>{t('landing.pcard_time_prev')}</b
						>
						</span>
						<span class="p-bar now">
							<span>{t('landing.pcard_bar_today')}</span><i style="width:38%"></i><b
							>{t('landing.pcard_time_now')}</b
						>
						</span>
					</div>
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
				<!-- The dial is the real KeyClock reading the visitor's own history.
				     The frame around it names what the object IS: a circle of
				     fifths, annotated in copyist blue the way a printed chart
				     labels its own construction. -->
				<figure class="clock-frame">
					<figcaption class="fifths-head">
						<span class="fifths-label">{t('landing.clock_fifths_label')}</span>
					</figcaption>
					<KeyClock {dial} size={252} showTimes={false} />
					<p class="fifths-chain">{t('landing.clock_fifths_chain')}</p>
					<p class="plate clock-cap">{t('landing.clock_caption')}</p>
				</figure>
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

		/* ── The hall's own ink ──────────────────────────────────
		   The hero photograph is a dim room at night and stays that way in
		   both themes, so the type over it cannot use the page tokens: in the
		   light theme --accent-gold resolves to the paper-safe ochre #8f5a05,
		   which measured 2.21:1 against the lit part of the frame. These are
		   the hall's fixed values, named here rather than scattered as literals
		   through the hero rules. They are page-local by design — nothing
		   outside this hero sits on a photograph. */
		--hall-ground: #0b0f14;
		--hall-ink: #ffffff;
		--hall-ink-warm: #f4f1ec;
		--hall-ink-soft: #ddd6cb;
		--hall-lede: #d8d2c8;
		--hall-eyebrow: #e8b04b;
		--hall-plate: #c3bcb1;
		--hall-l2: #ddd5c8;
		/* The lit plate that floats on the photograph, and its own inks. The
		   page's copyist blue is tuned for paper and goes murky on a dark
		   card, so the annotation lifts to the prototype's lit blue. */
		--plate-ground: rgba(14, 20, 29, 0.92);
		--plate-ground-solid: rgba(14, 20, 29, 0.98);
		--plate-head: rgba(26, 36, 49, 0.9);
		--plate-rule: rgba(255, 255, 255, 0.16);
		--plate-rule-soft: rgba(255, 255, 255, 0.1);
		--plate-blue: #9dc2e6;
		--plate-staff: rgba(157, 194, 230, 0.34);
		--plate-plate: #b6c0cc;
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

	/* The one action that matters. Amber is the system's "live" ink and a
	   start button is exactly that — it also separates the invitation to play
	   from stamp red, which is the narrative voice everywhere else on the
	   page. Bigger and heavier than its neighbours on purpose: three buttons
	   of equal weight is the same as none. */
	.btn-stamp {
		/* Not var(--accent-amber): that token darkens to ochre on the light
		   theme so amber TEXT can hold 4.5:1. This is a filled button with
		   near-black on top, so it wants the bright amber in BOTH themes —
		   the invitation to press should not change character with the
		   theme. Measured 9.65:1 either way. */
		background: var(--stamp);
		border-color: var(--stamp);
		color: var(--stamp-ink);
		min-height: 3.1rem;
		padding: 0 1.9rem;
		font-size: 1.02rem;
		font-weight: 700;
	}
	.btn-stamp:hover {
		background: var(--stamp-hover);
		border-color: var(--stamp-hover);
	}
	/* On diazo paper the amber fill only separates from the ground at 1.75:1,
	   so the button's SHAPE goes soft even though its label is at 9.65:1.
	   An ink edge gives it back its cut, the way a printed block sits on
	   paper. Dark ground needs none — there it separates at 9.12:1. */
	:global([data-theme='light']) .btn-stamp {
		border-color: var(--stamp-ink);
	}
	/* Secondary actions step back to quiet text with a rule — present for
	   anyone looking for them, never competing with the start button. */
	.btn-ghost {
		background: transparent;
		border-color: transparent;
		color: var(--text-muted);
		font-weight: 500;
		padding: 0 0.85rem;
		text-underline-offset: 4px;
		text-decoration: underline;
		text-decoration-color: var(--border-hover);
		text-decoration-thickness: 1px;
	}
	.btn-ghost:hover {
		color: var(--text);
		text-decoration-color: var(--accent-amber);
		background: transparent;
	}

	/* ── Hero ─────────────────────────────────────────────────── */

	/* "Der Saal" — the club photograph full-bleed, the type set on top.
	   The hall is always night, in BOTH themes: it is a photograph of a dim
	   room, and inverting it with the theme would be a lie. So every ink over
	   the photo is a fixed light value, not a theme token — --text-muted is
	   tuned for a card, not for a night photograph. The page below the hero
	   still follows the theme. */
	.hero {
		position: relative;
		isolation: isolate;
		overflow: hidden;
		background: var(--hall-ground);
		color: var(--hall-ink);
		padding: 2.75rem 0 3.25rem;
	}
	@media (min-width: 900px) {
		.hero { padding: clamp(4.5rem, 7vw, 6.5rem) 0 clamp(5rem, 7.5vw, 7rem); }
	}

	.hero-media {
		position: absolute;
		inset: 0;
		z-index: 0;
	}
	.hero-media img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		/* Keeps the keys and the string of bulbs in frame at every width. */
		object-position: 62% 52%;
		filter: brightness(0.98) contrast(1.05) saturate(1.12);
	}
	/* The type well. Opaque under the words, releasing over the piano so the
	   bulbs, the bassist and the lit body stay visible. These stops were
	   MEASURED, not guessed: the string of bokeh bulbs sits directly behind
	   the italic second line, and at .55 on the first ramp white came back at
	   4.42:1. As set here the worst pixel under the headline is ≥ 7:1 while
	   the right half of the frame stays open. Do not round these off. */
	.hero-media::after {
		content: '';
		position: absolute;
		inset: 0;
		background:
			linear-gradient(90deg,
				rgba(8, 11, 15, 0.95) 0%,
				rgba(8, 11, 15, 0.92) 26%,
				rgba(8, 11, 15, 0.84) 44%,
				rgba(8, 11, 15, 0.3) 66%,
				rgba(8, 11, 15, 0.03) 100%),
			linear-gradient(180deg,
				rgba(8, 11, 15, 0.55) 0%,
				rgba(8, 11, 15, 0.1) 30%,
				rgba(8, 11, 15, 0.28) 74%,
				rgba(8, 11, 15, 0.8) 100%);
	}
	@media (max-width: 979px) {
		/* Stacked: the type sits over the whole frame, so the wash goes
		   vertical and much heavier — there is no ramp to hide behind. */
		.hero-media::after {
			background: linear-gradient(180deg,
				rgba(8, 11, 15, 0.9) 0%,
				rgba(8, 11, 15, 0.82) 42%,
				rgba(8, 11, 15, 0.9) 72%,
				rgba(8, 11, 15, 0.97) 100%);
		}
		.hero-media img { object-position: 68% 55%; }
	}

	/* Ink over the photograph — fixed light values, theme-independent. */
	.hero .eyebrow { color: var(--hall-eyebrow); }
	.hero .plate { color: var(--hall-plate); }
	.hero .btn-ghost {
		color: var(--hall-ink-soft);
		text-decoration-color: color-mix(in srgb, var(--hall-ink-soft) 50%, transparent);
	}
	.hero .btn-ghost:hover {
		color: var(--hall-ink);
		text-decoration-color: var(--hall-ink);
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
		color: var(--hall-ink);
		/* A whisper of shadow so the stems hold where the wash is thinnest.
		   Not a glow — just enough to keep the serif crisp. */
		text-shadow: 0 1px 2px rgba(0, 0, 0, 0.55), 0 2px 18px rgba(0, 0, 0, 0.45);
	}
	.hero-h1 .l2 {
		display: block;
		font-style: italic;
		font-weight: 400;
		color: var(--hall-l2);
	}

	.hero-lede {
		margin-top: 1.35rem;
		max-width: 44ch;
		font-size: 1.05rem;
		line-height: 1.62;
		color: var(--hall-lede);
		text-shadow: 0 1px 3px rgba(0, 0, 0, 0.6);
	}

	.hero-cta {
		display: flex;
		flex-wrap: wrap;
		align-items: flex-start;
		gap: 0.7rem;
		margin-top: 1.6rem;
	}
	/* The button and its badge travel together, so the badge stays attached to
	   the decision even when the row wraps on a narrow screen. */
	.cta-stack {
		display: inline-flex;
		flex-direction: column;
		align-items: center;
		gap: 0.45rem;
	}
	.cta-badge {
		display: inline-flex;
		align-items: center;
		gap: 0.34rem;
		font-family: var(--font-mono);
		font-size: 0.64rem;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--accent-green);
		white-space: nowrap;
	}
	/* A small filled dot rather than a checkmark glyph: it reads as a status
	   light at this size, where a ✓ turns to mush. */
	.cta-badge::before {
		content: '';
		width: 0.36rem;
		height: 0.36rem;
		border-radius: 50%;
		background: var(--accent-green);
		flex: none;
	}

	.hero-fine {
		margin-top: 1.15rem;
		max-width: 48ch;
		font-size: 0.9rem;
		line-height: 1.55;
		color: var(--hall-plate);
		text-shadow: 0 1px 3px rgba(0, 0, 0, 0.6);
	}

	@media (max-width: 640px) {
		.hide-sm { display: none; }
	}

	/* ── The practice card ────────────────────────────────────── */

	/* The card floats on the photograph as a lit plate. Because the hall is
	   night in BOTH themes, this plate keeps its dark treatment in both —
	   hence explicit light values for every text role inside it rather than
	   inheriting the light-theme tokens. */
	.pcard {
		margin: 2.25rem 0 0;
		background: var(--plate-ground);
		border: 1px solid color-mix(in srgb, var(--accent-amber) 30%, transparent);
		box-shadow: var(--shadow-lg);
		backdrop-filter: blur(14px) saturate(1.1);
		-webkit-backdrop-filter: blur(14px) saturate(1.1);
	}
	@media (min-width: 980px) {
		.pcard { margin-top: 0.5rem; }
	}

	.pcard-head {
		display: flex;
		align-items: center;
		gap: 0.6rem;
		padding: 0.6rem 0.9rem;
		border-bottom: 1px solid var(--plate-rule-soft);
		background: var(--plate-head);
	}
	.pcard-head .plate {
		flex: 1;
		min-width: 0;
		color: var(--plate-plate);
	}
	/* The rehearsal mark keeps the A–F sequence unbroken; on the dark plate
	   it takes the hall's ink rather than the page's. */
	.pcard .rehearsal {
		border-color: var(--hall-ink-soft);
		color: var(--hall-ink);
		min-width: 1.45rem;
		height: 1.45rem;
		font-size: 0.66rem;
	}
	/* Amber pulse = live. The one reserved use, and it agrees with the CTA.
	   On the dark plate amber holds in both themes, so unlike the prototype
	   there is no light-theme substitution to make here. */
	.live-dot {
		width: 0.5rem;
		height: 0.5rem;
		flex: none;
		border-radius: 50%;
		background: var(--accent-amber);
		animation: pulse 2s ease-out infinite;
	}
	@keyframes pulse {
		0% { box-shadow: 0 0 0 0 color-mix(in srgb, var(--accent-amber) 55%, transparent); }
		70% { box-shadow: 0 0 0 7px transparent; }
		100% { box-shadow: 0 0 0 0 transparent; }
	}
	.live-tag {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		font-weight: 700;
		letter-spacing: 0.15em;
		text-transform: uppercase;
		color: var(--accent-amber);
	}

	.pcard-body { padding: 1.15rem 1.1rem 1.2rem; }

	/* Step 1 — the prompt */
	.p-step,
	.p-arrow {
		display: block;
		font-family: var(--font-mono);
		font-size: 0.58rem;
		font-weight: 600;
		letter-spacing: 0.18em;
		text-transform: uppercase;
		color: var(--plate-plate);
	}
	.p-arrow { margin: 0.85rem 0 0.55rem; }

	.p-ask {
		display: flex;
		align-items: baseline;
		justify-content: space-between;
		gap: 1rem;
		margin-top: 0.45rem;
	}
	.p-chord {
		font-family: var(--font-display-mus);
		font-size: clamp(2.3rem, 8.5vw, 3.1rem);
		font-weight: 700;
		line-height: 1;
		letter-spacing: -0.02em;
		font-variant-numeric: lining-nums;
		color: var(--hall-ink);
	}
	.p-voicing {
		font-family: var(--font-mono);
		font-size: 0.68rem;
		letter-spacing: 0.1em;
		line-height: 1.5;
		text-transform: uppercase;
		text-align: right;
		white-space: nowrap;
		color: var(--plate-blue);
	}

	/* Step 2 — the keyboard that answers it. Widths come from KEY_UNIT in
	   the script, so the board stays correct if the range ever changes. */
	.kbd {
		position: relative;
		display: flex;
		height: 5.6rem;
		border: 1px solid var(--key-white-border);
		border-radius: 3px;
		overflow: hidden;
		background: var(--key-white);
	}
	.kbd .wk {
		position: relative;
		flex: 1;
		border-right: 1px solid var(--key-white-border);
		background: var(--key-white);
	}
	.kbd .wk:last-child { border-right: 0; }
	.kbd .bk {
		position: absolute;
		top: 0;
		height: 62%;
		border-radius: 0 0 2px 2px;
		background: var(--key-black);
		box-shadow: 0 2px 3px rgba(0, 0, 0, 0.45);
		z-index: 2;
	}
	/* A pressed key: amber, because amber is live. */
	.kbd .wk.on { background: var(--accent-gold); }
	.kbd .bk.on { background: var(--accent-amber); }
	/* The note name printed on the struck keys, so the graphic teaches. */
	.kbd .wk.on::after,
	.kbd .bk.on::after {
		content: attr(data-n);
		position: absolute;
		left: 50%;
		transform: translateX(-50%);
		font-family: var(--font-mono);
		font-size: 0.58rem;
		font-weight: 700;
		letter-spacing: 0.02em;
	}
	/* Near-black on the bright amber of the dark theme measures 9.6:1, but the
	   light theme compresses --accent-gold to the paper-safe ochre #8f5a05,
	   where the same ink falls to 3.38:1. The struck key's fill changes
	   character between themes, so its label has to as well: dark ink on the
	   bright fill, white on the ochre. Measured 9.63:1 and 6.05:1. */
	.kbd .wk.on::after {
		bottom: 0.35rem;
		color: var(--stamp-ink);
	}
	:global([data-theme='light']) .kbd .wk.on::after {
		color: #ffffff;
	}
	/* A black key is only ~21px wide — a label will not fit inside it. Hang
	   it just under the key, on the white below, where there is room. The
	   chip carries the key's own ink on a light plate so it holds anywhere. */
	.kbd .bk.on::after {
		bottom: -1.45rem;
		padding: 0.05rem 0.24rem;
		border: 1px solid var(--accent-gold);
		border-radius: 2px;
		background: var(--key-white);
		color: var(--key-black);
		white-space: nowrap;
	}

	/* Step 3 — the clock that is running on you */
	.p-result {
		display: flex;
		align-items: center;
		gap: 0.7rem;
		margin-top: 2.1rem;
		padding-top: 0.85rem;
		border-top: 1px dashed var(--plate-rule);
	}
	.p-check {
		display: inline-grid;
		place-items: center;
		flex: none;
		width: 1.4rem;
		height: 1.4rem;
		border-radius: 50%;
		background: color-mix(in srgb, var(--accent-green) 22%, transparent);
		color: var(--accent-green);
		font-size: 0.78rem;
		font-weight: 700;
	}
	.p-verdict {
		min-width: 0;
		font-family: var(--font-display-mus);
		font-size: 0.95rem;
		font-style: italic;
		line-height: 1.35;
		color: var(--hall-ink-soft);
	}
	.p-time {
		margin-left: auto;
		flex: none;
		text-align: right;
	}
	.p-time b {
		display: block;
		font-family: var(--font-mono);
		font-size: 1.28rem;
		font-weight: 700;
		line-height: 1;
		font-variant-numeric: lining-nums tabular-nums;
		color: var(--accent-green);
	}
	.p-time span {
		display: block;
		margin-top: 0.2rem;
		font-family: var(--font-mono);
		font-size: 0.54rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--plate-plate);
	}

	/* The speed bars: last attempt against this one. Reads at a glance. */
	.p-bars {
		display: grid;
		gap: 0.35rem;
		margin-top: 0.8rem;
	}
	/* The label column is sized against the LONGER locale: "Letzte Woche"
	   wrapped to two lines at 3.9rem and threw the two bars out of alignment.
	   Mono uppercase does not reflow gracefully, so the label gets its own
	   width and is told not to wrap. */
	.p-bar {
		display: grid;
		grid-template-columns: 5.4rem minmax(0, 1fr) 2.6rem;
		align-items: center;
		gap: 0.55rem;
		font-family: var(--font-mono);
		font-size: 0.58rem;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--plate-plate);
	}
	.p-bar > span:first-child {
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.p-bar i {
		display: block;
		height: 0.42rem;
		border-radius: 999px;
		background: color-mix(in srgb, var(--hall-ink-soft) 40%, transparent);
	}
	.p-bar.now i { background: var(--accent-green); }
	/* These two figures are the whole "you got faster" claim — they are read,
	   so they take full ink, not a muted grey. */
	.p-bar b {
		font-weight: 700;
		text-align: right;
		font-variant-numeric: lining-nums tabular-nums;
		color: var(--hall-ink);
	}
	.p-bar.now b { color: var(--accent-green); }


	/* ── Sections ─────────────────────────────────────────────── */

	/* Sections read as separate movements, so they get real air between them.
	   A clamp rather than a fixed step: the vw term is what opens the page up
	   on a desktop spread, and the 3.25rem floor is what stops a phone from
	   becoming an endless scroll of whitespace. */
	.sec {
		padding: clamp(3.25rem, 4.5vw, 4rem) 0;
		border-top: 1px solid var(--rule-soft);
	}
	@media (min-width: 900px) {
		.sec { padding: clamp(5.5rem, 8vw, 8rem) 0; }
	}

	.sec-head {
		display: flex;
		align-items: flex-start;
		gap: 1rem;
		/* The heading needs to stand clear of its own section body, not just
		   of the section above it. */
		margin-bottom: clamp(2.25rem, 3.5vw, 3.25rem);
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
		margin: 0;
		padding: 1.75rem 1.5rem 1.5rem;
		border: 1px solid var(--border);
		/* The object inside is a circle; a hard-cornered box fights it. The
		   frame rounds to echo the dial and its segment ends. */
		border-radius: var(--radius-lg);
		background: var(--bg-card);
	}

	/* The fifths annotation — copyist blue, the page's voice for "this is how
	   the thing is built". It names the dial's construction so the ring reads
	   as a circle of fifths and not merely as a pie chart. */
	.fifths-head {
		display: flex;
		align-items: center;
		gap: 0.6rem;
		align-self: stretch;
		font-family: var(--font-mono);
		font-size: 0.62rem;
		font-weight: 600;
		letter-spacing: 0.19em;
		text-transform: uppercase;
		color: var(--ink-blue);
	}
	.fifths-head::before,
	.fifths-head::after {
		content: '';
		flex: 1;
		height: 1px;
		background: currentColor;
		opacity: 0.32;
	}
	.fifths-label { flex: none; }

	/* C → G → D … each step a fifth up. Set as a chain so the interval
	   relationship is legible as a sequence, not just as a claim in prose. */
	.fifths-chain {
		margin: 0.35rem 0 0;
		font-family: var(--font-display-mus);
		font-size: 0.95rem;
		font-weight: 600;
		font-variant-numeric: lining-nums;
		letter-spacing: 0.04em;
		text-align: center;
		text-wrap: balance;
		color: var(--ink-blue);
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

	.habit { margin-top: clamp(3.5rem, 5.5vw, 5.5rem); }
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
		padding: clamp(4.5rem, 7vw, 7rem) 0 0.5rem;
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
		margin-top: clamp(3.5rem, 5vw, 5rem);
		padding: 1.35rem 0 2.5rem;
		border-top: 2px solid var(--text);
	}

	@media (prefers-reduced-motion: reduce) {
		.btn { transition: none; }
		.btn:hover { transform: none; }
	}
</style>
