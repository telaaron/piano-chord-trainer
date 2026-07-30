<script lang="ts">
	import { t } from '$lib/i18n';
	import { ArrowRight, Check, Mail } from 'lucide-svelte';
	// This page is prerendered, so {@html t(...)} would freeze the build-time
	// (English) locale into the markup. RichText re-reads t() after hydration.
	import RichText from '$lib/components/RichText.svelte';

	const platforms = [
		{ name: 'Open Studio Jazz', descKey: 'educators.platform_open_studio', href: '/open-studio' },
		{ name: 'Jazz-Academy', descKey: 'educators.platform_jazz_academy', href: '' },
		{ name: 'Learn Jazz Standards', descKey: 'educators.platform_learn_jazz', href: '' },
		{ name: 'Private Teachers', descKey: 'educators.platform_private_teachers', href: '' },
	];

	const solutions = [
		{ num: '01', titleKey: 'educators.solution_speed', descKey: 'educators.solution_speed_desc' },
		{ num: '02', titleKey: 'educators.solution_midi', descKey: 'educators.solution_midi_desc' },
		{ num: '03', titleKey: 'educators.solution_analytics', descKey: 'educators.solution_analytics_desc' },
		{ num: '04', titleKey: 'educators.solution_guided', descKey: 'educators.solution_guided_desc' },
	];

	const trainItems = [
		'educators.train_chord_types',
		'educators.train_shell_voicings',
		'educators.train_rootless_a',
		'educators.train_inversions',
		'educators.train_progressions',
		'educators.train_turnarounds',
		'educators.train_circle',
		'educators.train_custom',
		'educators.train_difficulty',
		'educators.train_notation',
		'educators.train_audio',
		'educators.train_metronome',
	];

	const integrations = [
		{ titleKey: 'educators.integration_white_label', descKey: 'educators.integration_white_label_desc' },
		{ titleKey: 'educators.integration_trial', descKey: 'educators.integration_trial_desc' },
		{ titleKey: 'educators.integration_licensing', descKey: 'educators.integration_licensing_desc' },
	];

	const steps = [
		{ num: 'I', titleKey: 'educators.how_step1', descKey: 'educators.how_step1_desc' },
		{ num: 'II', titleKey: 'educators.how_step2', descKey: 'educators.how_step2_desc' },
		{ num: 'III', titleKey: 'educators.how_step3', descKey: 'educators.how_step3_desc' },
	];
</script>

<svelte:head>
	<title>{t('educators.title')}</title>
	<meta name="description" content={t('educators.meta_desc')} />
	<link rel="canonical" href="https://jazzchords.app/for-educators" />
	<meta property="og:title" content={t('educators.title')} />
	<meta property="og:description" content={t('educators.meta_desc')} />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://jazzchords.app/for-educators" />
	<meta property="og:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta property="og:image:type" content="image/webp" />
	<meta property="og:image:width" content="966" />
	<meta property="og:image:height" content="507" />
	<meta property="og:image:alt" content="Chord Trainer for Jazz Education Platforms" />
	<meta property="og:site_name" content="Chord Trainer" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="Jazz Voicing Trainer for Music Schools &amp; Online Jazz Platforms" />
	<meta name="twitter:description" content="Professional chord voicing trainer for jazz education. MIDI recognition, progress tracking, white-label ready." />
	<meta name="twitter:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta name="twitter:image:alt" content="Chord Trainer for Jazz Education Platforms" />

	{@html `<script type="application/ld+json">${JSON.stringify({
		"@context": "https://schema.org",
		"@type": "FAQPage",
		"mainEntity": [
			{
				"@type": "Question",
				"name": "How does the Chord Trainer integrate into my music education platform?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "Integration is a single embed code — an iframe with URL parameters for preset, branding, and voicing type. White-label colors and logo are configurable. Students never leave your platform."
				}
			},
			{
				"@type": "Question",
				"name": "Does the Chord Trainer require a MIDI keyboard?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "No. MIDI is optional and unlocks automatic chord validation. Without MIDI, students can still practice using the on-screen keyboard. The tool works in Chrome and Edge."
				}
			},
			{
				"@type": "Question",
				"name": "What jazz voicing types does the trainer cover?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "The trainer covers root-position chords, shell voicings (3-7), rootless A and B voicings (Bill Evans style), and all inversions — across 14 chord qualities in all 12 keys."
				}
			},
			{
				"@type": "Question",
				"name": "How much does a platform license cost?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "Pricing is a flat monthly license fee, typically starting at €200/month depending on platform size, with a 30-day free trial. Contact us for a demo and custom quote."
				}
			},
			{
				"@type": "Question",
				"name": "Can the trainer be linked to specific lessons in my curriculum?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "Yes. URL parameters pre-set the voicing type, progression, and difficulty for each embed. A shell voicings lesson links to a shell voicings drill; a ii-V-I lesson links to ii-V-I in all 12 keys — no extra setup needed."
				}
			}
		]
	})}</script>`}
</svelte:head>

<main class="edi flex-1">
	<!-- ═══ Masthead ═══ -->
	<header class="head">
		<div class="shell">
			<p class="eyebrow">{t('educators.badge')}</p>
			<h1 class="head-h1">
				<RichText key="educators.hero_h1_gradient" as="span" class="quote" />
				<span class="l2">{t('educators.hero_h1_b')}</span>
			</h1>
			<p class="head-lede">{t('educators.hero_p')}</p>
		</div>
	</header>

	<div class="shell">
		<!-- ═══ A · Platforms ═══ -->
		<section class="sec">
			<div class="sec-head">
				<span class="rehearsal">A</span>
				<div class="sec-col">
					<p class="eyebrow blue">{t('educators.platforms_title')}</p>
				</div>
			</div>
			<ul class="plats">
				{#each platforms as p}
					<li class="plat">
						<!-- Both branches must wrap in exactly ONE child: `.plat > *`
						     is the cell box, and two loose spans would each become
						     their own grid item and break out of the cell. -->
						{#if p.href}
							<a href={p.href}>
								<span class="plat-n">{p.name}</span>
								<span class="plat-d">{t(p.descKey)}</span>
							</a>
						{:else}
							<div>
								<span class="plat-n">{p.name}</span>
								<span class="plat-d">{t(p.descKey)}</span>
							</div>
						{/if}
					</li>
				{/each}
			</ul>
		</section>

		<!-- ═══ B · The problem, as a marked-up note ═══ -->
		<section class="sec">
			<div class="sec-head">
				<span class="rehearsal">B</span>
				<div class="sec-col">
					<p class="eyebrow">{t('educators.problem_title')}</p>
				</div>
			</div>
			<blockquote class="problem"><RichText key="educators.problem_desc" as="span" /></blockquote>
		</section>

		<!-- ═══ C · The solution, as a numbered contents list ═══ -->
		<section class="sec">
			<div class="sec-head">
				<span class="rehearsal">C</span>
				<div class="sec-col">
					<h2 class="sec-h2 lead">{t('educators.solution_title')}</h2>
				</div>
			</div>
			<ol class="contents">
				{#each solutions as s}
					<li class="row">
						<span class="no">{s.num}</span>
						<span class="row-txt">
							<span class="ttl">{t(s.titleKey)}</span>
							<span class="dsc">{t(s.descKey)}</span>
						</span>
					</li>
				{/each}
			</ol>
		</section>

		<!-- ═══ D · What students train ═══ -->
		<section class="sec">
			<div class="sec-head">
				<span class="rehearsal">D</span>
				<div class="sec-col">
					<h2 class="sec-h2 lead">{t('educators.what_students_train')}</h2>
				</div>
			</div>
			<ul class="train">
				{#each trainItems as item}
					<li><Check size={13} aria-hidden="true" />{t(item)}</li>
				{/each}
			</ul>
		</section>

		<!-- ═══ E · Integration ═══ -->
		<section class="sec">
			<div class="sec-head">
				<span class="rehearsal">E</span>
				<div class="sec-col">
					<h2 class="sec-h2 lead">{t('educators.integration_title')}</h2>
				</div>
			</div>
			<div class="ledger">
				{#each integrations as item}
					<div class="cell">
						<h3 class="cell-t">{t(item.titleKey)}</h3>
						<p class="cell-d">{t(item.descKey)}</p>
					</div>
				{/each}
			</div>
		</section>

		<!-- ═══ F · How integration works ═══ -->
		<section class="sec">
			<div class="sec-head">
				<span class="rehearsal">F</span>
				<div class="sec-col">
					<h2 class="sec-h2 lead">{t('educators.how_it_works')}</h2>
				</div>
			</div>
			<ol class="contents">
				{#each steps as s}
					<li class="row">
						<span class="no roman">{s.num}</span>
						<span class="row-txt">
							<span class="ttl">{t(s.titleKey)}</span>
							<span class="dsc">{t(s.descKey)}</span>
						</span>
					</li>
				{/each}
			</ol>
			<p class="see-live">
				<a href="/embed?mode=2-5-1&voicing=shell&chords=12">
					{t('educators.see_live_widget')}
					<ArrowRight size={14} />
				</a>
			</p>
		</section>

		<!-- ═══ Fine · CTA ═══ -->
		<section class="fine">
			<p class="eyebrow mid">{t('educators.cta_title')}</p>
			<p class="fine-p">{t('educators.cta_desc')}</p>
			<div class="fine-btns">
				<a href="/embed?mode=2-5-1&voicing=shell&chords=12" class="btn btn-stamp">
					{t('educators.cta_try_demo')}
					<ArrowRight size={17} />
				</a>
				<a href="mailto:info@jazzchords.app" class="btn btn-ghost">
					<Mail size={17} />
					{t('educators.cta_contact')}
				</a>
			</div>
		</section>
	</div>
</main>

<style>
	/* Same press job as the landing page: hairlines and section marks carry the
	   structure. The old version leaned on a photo hero, gradient text and four
	   rounded cards; none of that survives. */

	.edi {
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		font-variant-numeric: oldstyle-nums;
	}

	.shell {
		max-width: 980px;
		margin: 0 auto;
		padding: 0 1.25rem;
	}
	@media (min-width: 900px) {
		.shell { padding: 0 2.5rem; }
	}

	/* ── Primitives ───────────────────────────────────────────── */

	.eyebrow {
		display: flex;
		align-items: center;
		gap: 0.625rem;
		margin: 0;
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

	/* ── Buttons ──────────────────────────────────────────────── */

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

	/* ── Masthead ─────────────────────────────────────────────── */

	.head {
		padding: 3rem 0 2.25rem;
		border-bottom: 1px solid var(--rule-soft);
	}
	@media (min-width: 900px) {
		.head { padding: 4.5rem 0 3rem; }
	}

	.head-h1 {
		margin: 1.1rem 0 0;
		font-family: var(--font-display);
		font-size: clamp(1.85rem, 4.2vw, 2.9rem);
		font-weight: 600;
		line-height: 1.1;
		letter-spacing: -0.025em;
		max-width: 17em;
		text-wrap: balance;
		color: var(--text);
	}
	/* The teacher's demand, set as the quotation it is — red pencil, italic.
	   Replaces the old gradient-filled text. */
	/* :global because RichText renders this span in its own component scope. */
	.head-h1 :global(.quote) {
		display: block;
		font-style: italic;
		color: var(--primary);
	}
	.head-h1 .l2 {
		display: block;
		margin-top: 0.15em;
		font-weight: 400;
		color: var(--text-muted);
	}

	.head-lede {
		margin: 1.2rem 0 0;
		max-width: 62ch;
		font-size: 1.02rem;
		line-height: 1.65;
		color: var(--text-muted);
	}

	/* ── Sections ─────────────────────────────────────────────── */

	.sec {
		padding: 2.5rem 0;
		border-top: 1px solid var(--rule-soft);
	}
	.sec:first-child { border-top: none; }
	@media (min-width: 900px) {
		.sec { padding: 3.5rem 0; }
	}

	.sec-head {
		display: flex;
		align-items: flex-start;
		gap: 1rem;
		margin-bottom: 1.6rem;
	}
	.sec-col { flex: 1; min-width: 0; }
	.sec-h2 {
		margin: 0.7rem 0 0;
		font-family: var(--font-display);
		font-size: clamp(1.35rem, 3.2vw, 1.9rem);
		font-weight: 600;
		line-height: 1.15;
		letter-spacing: -0.018em;
		max-width: 24ch;
		text-wrap: balance;
		color: var(--text);
	}
	.sec-h2.lead { margin-top: 0.15rem; }

	/* ── Platforms ────────────────────────────────────────────── */

	.plats {
		list-style: none;
		display: grid;
		gap: 1px;
		margin: 0;
		padding: 0;
		border: 1px solid var(--border);
		background: var(--border);
	}
	@media (min-width: 620px) {
		.plats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
	}
	@media (min-width: 900px) {
		.plats { grid-template-columns: repeat(4, minmax(0, 1fr)); }
	}
	.plat { background: var(--bg-card); }
	.plat > * {
		display: flex;
		flex-direction: column;
		gap: 0.35rem;
		height: 100%;
		padding: 1.1rem 1rem;
		text-decoration: none;
	}
	.plat a { transition: background-color 0.12s; }
	.plat a:hover { background: var(--bg-card-hover); }
	.plat-n {
		font-family: var(--font-display);
		font-size: 0.98rem;
		font-weight: 600;
		color: var(--text);
	}
	.plat a .plat-n { color: var(--primary); }
	.plat-d {
		font-size: 0.82rem;
		line-height: 1.5;
		color: var(--text-muted);
	}

	/* ── The problem — a blue-pencil note ─────────────────────── */

	.problem {
		margin: 0;
		padding-left: 1.1rem;
		border-left: 2px solid var(--ink-blue);
		max-width: 64ch;
		font-family: var(--font-display);
		font-size: clamp(1.05rem, 2.2vw, 1.28rem);
		font-style: italic;
		line-height: 1.55;
		color: var(--text-muted);
	}
	.problem :global(strong) {
		font-style: normal;
		color: var(--text);
	}

	/* ── Numbered contents ────────────────────────────────────── */

	.contents {
		list-style: none;
		margin: 0;
		padding: 0;
		border-top: 1px solid var(--border);
	}
	.row {
		display: grid;
		grid-template-columns: auto minmax(0, 1fr);
		gap: 0.9rem;
		align-items: baseline;
		padding: 0.95rem 0;
		border-bottom: 1px solid var(--rule-soft);
	}
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
		font-family: var(--font-display);
		font-size: 1.04rem;
		font-weight: 600;
		color: var(--text);
	}
	.dsc {
		display: block;
		margin-top: 0.2rem;
		max-width: 66ch;
		font-size: 0.88rem;
		line-height: 1.55;
		color: var(--text-muted);
	}

	/* ── What students train ──────────────────────────────────── */

	.train {
		list-style: none;
		display: grid;
		gap: 0.65rem 1.5rem;
		margin: 0;
		padding: 0;
		grid-template-columns: repeat(2, minmax(0, 1fr));
	}
	@media (min-width: 760px) {
		.train { grid-template-columns: repeat(3, minmax(0, 1fr)); }
	}
	.train li {
		display: flex;
		align-items: flex-start;
		gap: 0.5rem;
		font-size: 0.88rem;
		line-height: 1.5;
		color: var(--text-muted);
	}
	.train :global(svg) {
		flex: none;
		margin-top: 0.22rem;
		color: var(--accent-green);
	}

	/* ── Integration ledger ───────────────────────────────────── */

	.ledger {
		display: grid;
		gap: 1px;
		border: 1px solid var(--border);
		background: var(--border);
	}
	@media (min-width: 760px) {
		.ledger { grid-template-columns: repeat(3, minmax(0, 1fr)); }
	}
	.cell {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		padding: 1.2rem 1.1rem;
		background: var(--bg-card);
	}
	.cell-t {
		margin: 0;
		font-family: var(--font-display);
		font-size: 1rem;
		font-weight: 600;
		color: var(--text);
	}
	.cell-d {
		margin: 0;
		font-size: 0.85rem;
		line-height: 1.55;
		color: var(--text-muted);
	}

	/* ── See it live ──────────────────────────────────────────── */

	.see-live { margin: 1.5rem 0 0; }
	.see-live a {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		font-family: var(--font-mono);
		font-size: 0.68rem;
		font-weight: 600;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--primary);
		text-decoration: none;
		border-bottom: 1px solid currentColor;
		padding-bottom: 0.15rem;
		transition: color 0.12s;
	}
	.see-live a:hover { color: var(--primary-hover); }

	/* ── Fine ─────────────────────────────────────────────────── */

	.fine {
		padding: 3rem 0 4rem;
		border-top: 2px solid var(--text);
		text-align: center;
	}
	.fine-p {
		margin: 1rem auto 1.6rem;
		max-width: 50ch;
		font-size: 0.98rem;
		line-height: 1.65;
		color: var(--text-muted);
	}
	.fine-btns {
		display: flex;
		flex-wrap: wrap;
		justify-content: center;
		gap: 0.7rem;
	}

	@media (prefers-reduced-motion: reduce) {
		.btn { transition: none; }
		.btn:hover { transform: none; }
	}
</style>
