<script lang="ts">
	import { t } from '$lib/i18n';
	import {
		ArrowRight,
		Check,
		Flame,
		GraduationCap,
		Keyboard,
		Lock,
		Mic,
		Play,
		Sparkles,
		Trophy,
	} from 'lucide-svelte';

	const curriculumSteps = [
		{ state: 'done', titleKey: 'landing.cur_s1_t', descKey: 'landing.cur_s1_d', chord: 'Cmaj7', notes: 'C · E · B' },
		{ state: 'done', titleKey: 'landing.cur_s2_t', descKey: 'landing.cur_s2_d', chord: 'C6/9', notes: 'C · E · A · D' },
		{ state: 'active', titleKey: 'landing.cur_s3_t', descKey: 'landing.cur_s3_d', chord: 'Dm9', notes: 'F · A · C · E' },
		{ state: 'locked', titleKey: 'landing.cur_s4_t', descKey: 'landing.cur_s4_d', chord: 'G7/B', notes: 'B · F · G' },
		{ state: 'locked', titleKey: 'landing.cur_s5_t', descKey: 'landing.cur_s5_d', chord: 'G7♯5♭9', notes: 'B · F · A♭ · E♭' }
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

	// White-key layout for the CSS keyboard; lit = Cmaj7 shell (C E B)
	const whiteKeys = [
		{ note: 'C', lit: true },
		{ note: 'D', lit: false },
		{ note: 'E', lit: true },
		{ note: 'F', lit: false },
		{ note: 'G', lit: false },
		{ note: 'A', lit: false },
		{ note: 'B', lit: true },
		{ note: 'C', lit: false },
		{ note: 'D', lit: false },
		{ note: 'E', lit: false }
	] as const;
	// Black keys positioned between white keys (index = gap after that white key)
	const blackKeys = [0, 1, 3, 4, 5, 7, 8] as const;
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

<!-- Cinematic Hero — static jazz-club piano, subject right / dark left for copy -->
<section
	class="hero-stage relative isolate h-[calc(100svh-3.5rem)] overflow-hidden max-[968px]:h-auto max-[968px]:min-h-[calc(100svh-3.5rem)]"
>
	<div class="hero-media absolute inset-0 z-0">
		<picture>
			<source
				type="image/avif"
				srcset="/bilder/hero-piano-480.avif 480w, /bilder/hero-piano-768.avif 768w, /bilder/hero-piano-1280.avif 1280w, /bilder/hero-piano-1920.avif 1920w"
				sizes="100vw"
			/>
			<source
				type="image/webp"
				srcset="/bilder/hero-piano-480.webp 480w, /bilder/hero-piano-768.webp 768w, /bilder/hero-piano-1280.webp 1280w, /bilder/hero-piano-1920.webp 1920w"
				sizes="100vw"
			/>
			<img
				src="/bilder/hero-piano-1280.webp"
				alt=""
				aria-hidden="true"
				width="2752"
				height="1536"
				fetchpriority="high"
				class="hero-canvas h-full w-full object-cover"
			/>
		</picture>
	</div>

	<div class="hero-vignette absolute inset-0 pointer-events-none"></div>

	<div class="hero-content-frame relative z-2 flex h-full items-center">
	<div class="hero-copy-shell max-w-140 px-8 py-8 rounded-[1.35rem] max-[968px]:max-w-none max-[968px]:rounded-2xl max-[968px]:px-5 max-[968px]:py-5.5">
		<!-- Badge -->
		<div class="hero-badge inline-flex items-center gap-2 py-2 px-4 bg-[rgba(16, 13, 32,0.55)] border border-[rgba(255, 184, 77,0.45)] rounded-[999px] text-[0.76rem] tracking-[0.08em] uppercase text-(--accent-amber) mb-6 w-fit max-[968px]:mb-4 max-[968px]:text-[0.72rem]">
			<span class="w-2 h-2 bg-(--accent-amber) rounded-full animate-pulse"></span>
			{t('landing.badge')}
		</div>

		<!-- Titles -->
		<h1 class="hero-title text-[clamp(2rem,3.7vw,3.9rem)] font-black leading-[1.04] tracking-[-0.03em] mb-5 max-w-[16ch] max-[968px]:text-[clamp(1.62rem,8.2vw,2.32rem)] max-[968px]:leading-[1.07] max-[968px]:max-w-[11ch] max-[968px]:mb-3">
			<span class="block text-[rgba(255, 200, 130,0.96)]">{t('landing.hero_title_line1')}</span>
			<span class="block text-(--text)">{t('landing.hero_title_line2')}</span>
		</h1>

		<p class="hero-subtitle text-[0.98rem] leading-[1.62] text-[rgba(220, 214, 240,0.9)] max-w-[56ch] mb-4 max-[968px]:text-[0.92rem] max-[968px]:leading-[1.55]">
			{t('landing.hero_subtitle')}
		</p>

		<p class="hero-support text-[0.84rem] text-[rgba(150, 144, 178,0.9)] mb-7 flex items-center gap-1.5 max-[968px]:mb-5 max-[968px]:text-[0.8rem]">
			<svg class="w-4 h-4 text-(--accent-green) shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
			{t('landing.hero_no_midi')}
		</p>

		<!-- CTAs -->
		<div class="hero-cta-row flex flex-wrap gap-2.5 mb-5 max-[968px]:items-center">
			<a
				href="/train"
				class="hero-cta-primary py-3 px-5.5 rounded-[0.85rem] text-base font-semibold no-underline transition-all duration-300 inline-flex items-center gap-2 whitespace-nowrap text-(--primary-text) shadow-[0_6px_30px_rgba(245, 166, 35,0.35)] hover:-translate-y-0.5 hover:shadow-[0_12px_38px_rgba(245, 166, 35,0.45)] max-[968px]:text-[0.95rem] max-[968px]:px-4.5"
				style="background: linear-gradient(135deg, var(--primary) 0%, var(--accent-amber) 100%)"
			>
				{t('landing.cta_start')}
				<span>→</span>
			</a>
			<a href="/learn" class="hero-cta-secondary py-3 px-5.5 rounded-[0.85rem] text-base font-semibold no-underline transition-all duration-300 inline-flex items-center gap-2 whitespace-nowrap bg-[rgba(14, 11, 28,0.56)] text-(--text) border border-[rgba(80, 72, 120,0.32)] hover:bg-[rgba(24, 20, 44,0.72)] hover:border-[rgba(245, 166, 35,0.62)] max-[968px]:py-2.5 max-[968px]:px-4 max-[968px]:text-[0.95rem]">
				{t('landing.cta_learn')}
			</a>
			<a href="/for-educators" class="py-3 px-5.5 rounded-[0.85rem] text-base font-semibold no-underline transition-all duration-300 inline-flex items-center gap-2 whitespace-nowrap bg-[rgba(14, 11, 28,0.56)] text-(--text) border border-[rgba(80, 72, 120,0.32)] hover:bg-[rgba(24, 20, 44,0.72)] hover:border-[rgba(245, 166, 35,0.62)] max-[968px]:hidden">
				{t('landing.cta_educators')}
			</a>
		</div>

		<p class="hero-footnote text-[0.9rem] text-[rgba(140, 134, 168,0.92)] max-[968px]:hidden">{t('landing.footnote')}</p>
		<p class="hero-footnote-mobile text-[0.9rem] text-[rgba(140, 134, 168,0.92)] hidden max-[968px]:block">{t('landing.footnote_mobile')}</p>
		<a href="/for-educators" class="hero-edu-link hidden max-[968px]:inline-block max-[968px]:mt-3 text-[0.8rem] text-(--text-muted) no-underline transition-colors duration-150 hover:text-(--text)">
			{t('landing.cta_educators')} →
		</a>
	</div>
	</div>
</section>

<!-- ═══ S1 · Meet your coach ═══ -->
<section class="py-24 max-[968px]:py-14 px-6">
	<div class="max-w-6xl mx-auto grid grid-cols-[1.05fr_1fr] gap-16 items-center max-[968px]:grid-cols-1 max-[968px]:gap-10">
		<div>
			<span class="landing-eyebrow"><Sparkles size={13} /> {t('landing.coach_eyebrow')}</span>
			<h2 class="landing-h2">{t('landing.coach_title')}</h2>
			<p class="landing-lead">{t('landing.coach_desc')}</p>
			<ul class="mt-8 flex flex-col gap-5">
				<li class="flex gap-3.5">
					<span class="landing-bullet-icon"><GraduationCap size={17} /></span>
					<div>
						<div class="font-semibold text-(--text)">{t('landing.coach_b1_t')}</div>
						<div class="text-[0.95rem] text-(--text-muted) leading-[1.6]">{t('landing.coach_b1_d')}</div>
					</div>
				</li>
				<li class="flex gap-3.5">
					<span class="landing-bullet-icon"><Sparkles size={17} /></span>
					<div>
						<div class="font-semibold text-(--text)">{t('landing.coach_b2_t')}</div>
						<div class="text-[0.95rem] text-(--text-muted) leading-[1.6]">{t('landing.coach_b2_d')}</div>
					</div>
				</li>
				<li class="flex gap-3.5">
					<span class="landing-bullet-icon"><Trophy size={17} /></span>
					<div>
						<div class="font-semibold text-(--text)">{t('landing.coach_b3_t')}</div>
						<div class="text-[0.95rem] text-(--text-muted) leading-[1.6]">{t('landing.coach_b3_d')}</div>
					</div>
				</li>
			</ul>
		</div>

		<!-- Product-true coach session mockup -->
		<div class="coach-mock rounded-2xl border border-(--border) bg-(--bg-card) p-6 max-[968px]:p-5" aria-hidden="true">
			<div class="flex items-center gap-2.5 text-[0.85rem] text-(--text-muted) leading-[1.5]">
				<span class="shrink-0 inline-flex items-center justify-center w-7 h-7 rounded-full bg-(--primary-muted) text-(--primary)"><GraduationCap size={15} /></span>
				{t('landing.coach_mock_say')}
			</div>
			<div class="coach-mock-btn mt-4 flex items-center gap-3 rounded-[0.85rem] py-3.5 px-5 font-semibold text-(--primary-text)">
				<Play size={18} fill="currentColor" />
				{t('landing.coach_mock_btn')}
			</div>
			<div class="mt-5 flex flex-col gap-2">
				{#each sessionBlocks as block}
					<div class="flex items-center gap-3 rounded-lg border py-2 px-3 text-[0.86rem]
						{block.state === 'now'
							? 'border-(--primary) bg-(--primary-muted) text-(--text)'
							: 'border-(--border) text-(--text-muted)'}
						{block.state === 'next' ? 'opacity-55' : ''}"
					>
						{#if block.state === 'done'}
							<span class="text-(--accent-green) inline-flex shrink-0"><Check size={14} /></span>
						{:else if block.state === 'now'}
							<span class="w-2 h-2 rounded-full bg-(--primary) animate-pulse shrink-0"></span>
						{:else}
							<span class="w-2 h-2 rounded-full bg-(--border) shrink-0"></span>
						{/if}
						<span class="{block.state === 'now' ? 'font-semibold' : ''}">{t(block.labelKey)}</span>
						<span class="ml-auto tabular-nums text-[0.78rem] text-(--text-dim,inherit) opacity-70">{block.min} min</span>
					</div>
				{/each}
			</div>
			<div class="mt-5 pt-4 border-t border-(--border)">
				<p class="text-[0.9rem] italic leading-[1.55] text-(--text)">{t('landing.coach_mock_fb')}</p>
				<p class="mt-1.5 text-[0.75rem] uppercase tracking-[0.08em] text-(--text-muted)">{t('landing.coach_mock_fb_label')}</p>
			</div>
		</div>
	</div>
</section>

<!-- ═══ S2 · The curriculum ladder ═══ -->
<section class="py-24 max-[968px]:py-14 px-6 landing-tint">
	<div class="max-w-6xl mx-auto">
		<div class="max-w-2xl">
			<span class="landing-eyebrow"><Check size={13} /> {t('landing.cur_eyebrow')}</span>
			<h2 class="landing-h2">{t('landing.cur_title')}</h2>
			<p class="landing-lead">{t('landing.cur_desc')}</p>
		</div>
		<div class="mt-12 max-w-3xl flex flex-col">
			{#each curriculumSteps as step, i}
				<div class="cur-row relative flex items-start gap-5 pb-9 last:pb-0 {step.state === 'locked' ? 'opacity-55' : ''}">
					{#if i < curriculumSteps.length - 1}
						<span class="cur-line" aria-hidden="true"></span>
					{/if}
					<span class="cur-dot shrink-0
						{step.state === 'done' ? 'cur-dot-done' : step.state === 'active' ? 'cur-dot-active' : 'cur-dot-locked'}">
						{#if step.state === 'done'}<Check size={15} />{:else if step.state === 'active'}<Play size={13} fill="currentColor" />{:else}<Lock size={13} />{/if}
					</span>
					<div class="flex-1 flex items-baseline justify-between gap-6 max-[640px]:flex-col max-[640px]:gap-1">
						<div>
							<div class="font-bold text-[1.08rem] text-(--text) flex items-center gap-2.5">
								{t(step.titleKey)}
								{#if step.state === 'active'}<span class="text-[0.68rem] font-semibold uppercase tracking-[0.08em] text-(--primary) border border-(--primary) rounded-full py-0.5 px-2">{t('landing.cur_now')}</span>{/if}
							</div>
							<div class="text-[0.92rem] text-(--text-muted) mt-0.5 leading-[1.55]">{t(step.descKey)}</div>
						</div>
						<div class="font-mono text-[0.88rem] text-(--text-muted) whitespace-nowrap shrink-0">
							<span class="font-bold text-(--primary)">{step.chord}</span>
							<span class="mx-1.5 opacity-40">·</span>{step.notes}
						</div>
					</div>
				</div>
			{/each}
		</div>
		<p class="mt-10 text-[0.95rem] text-(--text-muted) max-w-2xl flex items-center gap-2">
			<GraduationCap size={16} class="shrink-0 text-(--primary)" />
			{t('landing.cur_foot')}
		</p>
	</div>
</section>

<!-- ═══ S3 · It listens ═══ -->
<section class="py-24 max-[968px]:py-14 px-6">
	<div class="max-w-6xl mx-auto grid grid-cols-[1fr_1.05fr] gap-16 items-center max-[968px]:grid-cols-1 max-[968px]:gap-10">
		<!-- CSS keyboard (order swapped on mobile: copy first) -->
		<div class="max-[968px]:order-2" aria-hidden="true">
			<div class="rounded-2xl border border-(--border) bg-(--bg-card) p-6 max-[968px]:p-4">
				<div class="landing-kbd relative flex h-40 max-[640px]:h-30 rounded-lg overflow-hidden">
					{#each whiteKeys as key}
						<div class="landing-key-white relative flex-1 {key.lit ? 'is-lit' : ''}">
							{#if key.lit}<span class="landing-key-label">{key.note}</span>{/if}
						</div>
					{/each}
					{#each blackKeys as gap}
						<div class="landing-key-black" style="left: {((gap + 1) / whiteKeys.length) * 100}%"></div>
					{/each}
				</div>
				<div class="mt-4 flex items-center justify-between gap-3 flex-wrap">
					<span class="inline-flex items-center gap-2 text-[0.9rem] font-semibold text-(--accent-green)">
						<Check size={15} /> {t('landing.listen_caption')}
					</span>
					<span class="font-mono text-[0.85rem] text-(--text-muted)">Cmaj7 = C · E · B</span>
				</div>
			</div>
		</div>
		<div class="max-[968px]:order-1">
			<span class="landing-eyebrow"><Mic size={13} /> {t('landing.listen_eyebrow')}</span>
			<h2 class="landing-h2">{t('landing.listen_title')}</h2>
			<p class="landing-lead">{t('landing.listen_desc')}</p>
			<div class="mt-7 flex flex-wrap gap-2.5">
				<span class="landing-chip"><Keyboard size={14} /> {t('landing.listen_chip1')}</span>
				<span class="landing-chip"><Mic size={14} /> {t('landing.listen_chip2')}</span>
				<span class="landing-chip"><Play size={14} /> {t('landing.listen_chip3')}</span>
			</div>
		</div>
	</div>
</section>

<!-- ═══ S4 · Five minutes a day ═══ -->
<section class="py-24 max-[968px]:py-14 px-6 landing-tint">
	<div class="max-w-6xl mx-auto grid grid-cols-[1.05fr_1fr] gap-16 items-center max-[968px]:grid-cols-1 max-[968px]:gap-10">
		<div>
			<span class="landing-eyebrow"><Flame size={13} /> {t('landing.habit_eyebrow')}</span>
			<h2 class="landing-h2">{t('landing.habit_title')}</h2>
			<p class="landing-lead">{t('landing.habit_desc')}</p>
		</div>
		<div aria-hidden="true">
			<div class="grid grid-cols-3 gap-3 max-[640px]:grid-cols-3 max-[640px]:gap-2">
				<div class="landing-stat">
					<Flame size={18} class="text-(--primary)" />
					<div class="landing-stat-num">12</div>
					<div class="landing-stat-label">{t('landing.habit_stat1')}</div>
				</div>
				<div class="landing-stat">
					<Check size={18} class="text-(--accent-green)" />
					<div class="landing-stat-num">5/5</div>
					<div class="landing-stat-label">{t('landing.habit_stat2')}</div>
				</div>
				<div class="landing-stat">
					<Trophy size={18} class="text-(--accent-amber)" />
					<div class="landing-stat-num">Lv.4</div>
					<div class="landing-stat-label">{t('landing.habit_stat3')}</div>
				</div>
			</div>
			<div class="mt-3 rounded-xl border border-(--border) bg-(--bg-card) p-5">
				<p class="text-[0.92rem] italic leading-[1.6] text-(--text)">{t('landing.habit_quote')}</p>
				<p class="mt-2 text-[0.75rem] uppercase tracking-[0.08em] text-(--text-muted)">{t('landing.habit_quote_label')}</p>
			</div>
		</div>
	</div>
</section>

<!-- ═══ S5 · FAQ (visible content matching the FAQPage schema) ═══ -->
<section class="py-24 max-[968px]:py-14 px-6">
	<div class="max-w-3xl mx-auto">
		<h2 class="landing-h2 text-center">{t('landing.faq_title')}</h2>
		<div class="mt-10 flex flex-col gap-3">
			{#each faqItems as item}
				<details class="landing-faq group rounded-xl border border-(--border) bg-(--bg-card)">
					<summary class="flex items-center justify-between gap-4 cursor-pointer list-none py-4 px-5 font-semibold text-(--text) text-[0.98rem]">
						{t(item.qKey)}
						<span class="landing-faq-marker shrink-0" aria-hidden="true">+</span>
					</summary>
					<p class="px-5 pb-5 text-[0.93rem] leading-[1.65] text-(--text-muted)">{t(item.aKey)}</p>
				</details>
			{/each}
		</div>
	</div>
</section>

<!-- ═══ S6 · Final CTA ═══ -->
<section class="pb-28 pt-4 px-6">
	<div class="max-w-2xl mx-auto text-center">
		<h2 class="landing-h2">{t('landing.cta2_title')}</h2>
		<p class="landing-lead mt-3">{t('landing.cta2_desc')}</p>
		<a
			href="/train"
			class="mt-8 inline-flex items-center gap-2.5 px-9 py-4 rounded-[0.85rem] font-semibold text-[1.05rem] no-underline text-(--primary-text) transition-all duration-300 shadow-[0_6px_30px_rgba(245,166,35,0.35)] hover:-translate-y-0.5 hover:shadow-[0_12px_38px_rgba(245,166,35,0.45)]"
			style="background: linear-gradient(135deg, var(--primary) 0%, var(--accent-amber) 100%)"
		>
			{t('landing.cta_start')}
			<ArrowRight size={20} />
		</a>
		<p class="mt-5 text-[0.88rem] text-(--text-muted)">{t('landing.footnote')}</p>
	</div>
</section>

<style>
	.hero-stage {
		--hero-safe: clamp(1.8rem, 4.2vw, 5.8rem);
		background:
			radial-gradient(circle at 50% 78%, rgba(245, 166, 35, 0.38) 0%, rgba(245, 166, 35, 0.1) 25%, transparent 58%),
			radial-gradient(circle at 82% 14%, rgba(245, 166, 35, 0.22) 0%, transparent 40%),
			linear-gradient(180deg, #0a0816 0%, #0c0a18 36%, #120e26 72%, #0b0918 100%);
	}

	.hero-content-frame {
		width: 100%;
		max-width: min(1720px, 100%);
		margin: 0 auto;
		padding-left: var(--hero-safe);
		padding-right: var(--hero-safe);
	}

	.hero-media {
		overflow: hidden;
	}

	.hero-media::before {
		content: '';
		position: absolute;
		inset: 0;
		z-index: 1;
		pointer-events: none;
		background: linear-gradient(
			90deg,
			rgba(6, 5, 4, 1) 0%,
			rgba(6, 5, 4, 0.96) 18%,
			rgba(6, 5, 4, 0.82) 34%,
			rgba(6, 5, 4, 0.56) 48%,
			rgba(6, 5, 4, 0.22) 62%,
			transparent 72%
		);
	}

	.hero-canvas {
		display: block;
		background: #090713;
		filter: saturate(1.09) contrast(1.05) brightness(0.9);
	}

	.hero-copy-shell {
		width: min(41rem, 48vw);
		min-width: 31rem;
		/* Solid translucent fill instead of backdrop-blur — same readability,
		   no per-frame blur cost behind the moving keys. */
		background: linear-gradient(145deg, rgba(12, 10, 24, 0.86) 0%, rgba(12, 10, 24, 0.66) 52%, rgba(12, 10, 24, 0.42) 100%);
		border: 1px solid rgba(255, 200, 130, 0.2);
		box-shadow: 0 18px 50px rgba(0, 0, 0, 0.34), inset 0 1px 0 rgba(235, 220, 255, 0.12);
	}

	@media (max-width: 1280px) {
		.hero-copy-shell {
			width: min(36rem, 54vw);
			min-width: 0;
		}
	}


	.hero-vignette {
		background:
			radial-gradient(circle at 50% 35%, transparent 0%, rgba(0, 0, 0, 0.3) 62%, rgba(0, 0, 0, 0.66) 100%),
			linear-gradient(90deg, rgba(7, 5, 4, 0.8) 0%, transparent 18%, transparent 82%, rgba(7, 5, 4, 0.82) 100%);
	}

	.hero-title {
		text-wrap: balance;
	}


	@media (max-width: 968px) {
		.hero-media {
			display: none;
		}

		.hero-media::before {
			display: none;
		}

		.hero-canvas {
			filter: saturate(1.03) contrast(1.02) brightness(0.8);
		}

		.hero-copy-shell {
			height: auto;
			max-width: none;
			overflow: visible;
			background: transparent;
			border-color: transparent;
			box-shadow: none;
			backdrop-filter: none;
			padding: 0;
			margin-top: 0;
		}

		.hero-stage {
			height: auto;
			min-height: calc(100svh - 3.5rem);
			padding-top: 4.5rem;
			padding-bottom: 2rem;
			background:
				radial-gradient(75% 58% at 88% 12%, rgba(245, 166, 35, 0.22) 0%, transparent 72%),
				linear-gradient(180deg, #0b0918 0%, #0c0a1c 38%, #0e0b20 100%);
		}

		.hero-content-frame {
			padding: 0 1.25rem;
		}

		.hero-badge,
		.hero-support {
			display: none;
		}

		.hero-vignette {
			background: linear-gradient(180deg, rgba(11, 9, 22, 0.08) 0%, rgba(11, 9, 22, 0.42) 50%, rgba(11, 9, 22, 0.76) 100%);
		}

		.hero-title {
			font-size: clamp(1.72rem, 10.2vw, 2.34rem);
			line-height: 1.06;
			max-width: 10.5ch;
			margin-bottom: 0.9rem;
		}

		.hero-subtitle {
			font-size: 1rem;
			line-height: 1.56;
			max-width: 36ch;
			margin-bottom: 1.25rem;
		}

		.hero-cta-row {
			gap: 0.65rem;
			margin-bottom: 1.15rem;
		}

		.hero-cta-primary,
		.hero-cta-secondary {
			width: 100%;
			justify-content: center;
			padding-top: 0.9rem;
			padding-bottom: 0.9rem;
			font-size: 1rem;
		}

		.hero-footnote-mobile {
			display: block;
			font-size: 0.82rem;
			line-height: 1.45;
			color: rgba(180, 159, 140, 0.9);
		}

		.hero-edu-link {
			margin-top: 0.8rem;
			font-size: 0.95rem;
			font-weight: 500;
			color: rgba(211, 192, 170, 0.95);
		}
	}

	/* The hero stays dark in every theme — re-pin indigo-dark tokens locally
	   so text/borders read over the dark art. Sections below follow the theme. */
	.hero-stage {
		--text: #f1eff8;
		--text-muted: #a9a3c6;
		--text-dim: #6f6992;
		--bg: #0c0a18;
		--bg-card: #16132a;
		--border: #2d2952;
	}

	/* ── Landing design system (below hero, theme-aware) ─────────────── */

	.landing-eyebrow {
		display: inline-flex;
		align-items: center;
		gap: 0.45rem;
		font-size: 0.76rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: var(--primary);
		margin-bottom: 1rem;
	}

	.landing-h2 {
		font-size: clamp(1.7rem, 2.6vw, 2.5rem);
		font-weight: 800;
		line-height: 1.14;
		letter-spacing: -0.02em;
		color: var(--text);
		text-wrap: balance;
	}

	.landing-lead {
		margin-top: 1.1rem;
		font-size: 1.05rem;
		line-height: 1.7;
		color: var(--text-muted);
		max-width: 54ch;
	}

	.landing-bullet-icon {
		flex-shrink: 0;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 2.3rem;
		height: 2.3rem;
		border-radius: 0.7rem;
		background: var(--primary-muted);
		color: var(--primary);
	}

	.landing-chip {
		display: inline-flex;
		align-items: center;
		gap: 0.45rem;
		padding: 0.45rem 0.95rem;
		border-radius: 999px;
		border: 1px solid var(--border);
		background: var(--bg-card);
		font-size: 0.87rem;
		color: var(--text-muted);
	}
	.landing-chip :global(svg) {
		color: var(--primary);
		flex-shrink: 0;
	}

	/* Alternating section tint */
	.landing-tint {
		background: color-mix(in srgb, var(--bg-card) 42%, transparent);
	}

	/* Coach mockup */
	.coach-mock {
		box-shadow: 0 24px 60px rgba(0, 0, 0, 0.22);
	}
	.coach-mock-btn {
		background: linear-gradient(135deg, var(--primary) 0%, var(--accent-amber) 100%);
		box-shadow: 0 6px 22px rgba(245, 166, 35, 0.3);
	}

	/* Curriculum ladder */
	.cur-line {
		position: absolute;
		left: 0.95rem;
		top: 2.2rem;
		bottom: 0.35rem;
		width: 2px;
		background: var(--border);
	}
	.cur-dot {
		position: relative;
		z-index: 1;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 2rem;
		height: 2rem;
		border-radius: 999px;
		margin-top: 0.1rem;
	}
	.cur-dot-done {
		background: color-mix(in srgb, var(--accent-green) 16%, transparent);
		color: var(--accent-green);
		border: 1px solid color-mix(in srgb, var(--accent-green) 45%, transparent);
	}
	.cur-dot-active {
		background: var(--primary-muted);
		color: var(--primary);
		border: 1px solid var(--primary);
		box-shadow: 0 0 0 4px color-mix(in srgb, var(--primary) 14%, transparent);
	}
	.cur-dot-locked {
		background: var(--bg-card);
		color: var(--text-muted);
		border: 1px solid var(--border);
	}

	/* CSS keyboard */
	.landing-kbd {
		background: #0d0b1a;
		padding: 0.55rem 0.55rem 0;
		border: 1px solid var(--border);
	}
	.landing-key-white {
		background: linear-gradient(180deg, #fdfcf8 0%, #f0ede4 100%);
		border-right: 1px solid rgba(0, 0, 0, 0.18);
		border-radius: 0 0 4px 4px;
	}
	.landing-key-white:last-child {
		border-right: none;
	}
	.landing-key-white.is-lit {
		background: linear-gradient(180deg, var(--accent-amber) 0%, var(--primary) 100%);
		box-shadow: inset 0 -10px 18px rgba(0, 0, 0, 0.15), 0 0 18px rgba(245, 166, 35, 0.5);
	}
	.landing-key-label {
		position: absolute;
		bottom: 0.5rem;
		left: 50%;
		transform: translateX(-50%);
		font-size: 0.72rem;
		font-weight: 700;
		color: #1a1206;
	}
	.landing-key-black {
		position: absolute;
		top: 0;
		width: 6%;
		height: 58%;
		transform: translateX(-50%);
		background: linear-gradient(180deg, #201d33 0%, #0b0918 100%);
		border-radius: 0 0 3px 3px;
		z-index: 1;
		box-shadow: 0 3px 6px rgba(0, 0, 0, 0.4);
	}

	/* Habit stat tiles */
	.landing-stat {
		display: flex;
		flex-direction: column;
		align-items: flex-start;
		gap: 0.3rem;
		padding: 1rem;
		border-radius: 0.9rem;
		border: 1px solid var(--border);
		background: var(--bg-card);
	}
	.landing-stat-num {
		font-size: 1.45rem;
		font-weight: 800;
		color: var(--text);
		letter-spacing: -0.02em;
		line-height: 1;
	}
	.landing-stat-label {
		font-size: 0.72rem;
		text-transform: uppercase;
		letter-spacing: 0.07em;
		color: var(--text-muted);
	}

	/* FAQ */
	.landing-faq summary::-webkit-details-marker {
		display: none;
	}
	.landing-faq-marker {
		font-size: 1.25rem;
		font-weight: 400;
		line-height: 1;
		color: var(--primary);
		transition: transform 0.2s ease;
	}
	.landing-faq[open] .landing-faq-marker {
		transform: rotate(45deg);
	}
</style>
