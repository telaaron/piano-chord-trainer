<script lang="ts">
	import { onMount } from 'svelte';
	import { t } from '$lib/i18n';
	import {
		Piano,
		Music,
		BarChart3,
		BookOpen,
		ArrowRight,
		Keyboard,
		Target,
	} from 'lucide-svelte';

	const HERO_FRAME_COUNT = 73;
	const HERO_FRAME_BASES = ['/video/frames', '/videos/frames'];

	let heroSection: HTMLElement | undefined;
	let heroCanvas: HTMLCanvasElement | undefined;
	let frameImages: Array<HTMLImageElement | undefined> = [];
	let activeFrameIndex = 0;
	let pendingFrameIndex = 0;
	let rafScheduled = false;
	let latestScrollY = 0;
	let hasStartedPreload = false;

	const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

	const getFrameFilename = (index: number) => `frame_${String(index + 1).padStart(4, '0')}.jpg`;

	function drawFrame(index: number) {
		if (!heroCanvas) return;
		const image = frameImages[index];
		if (!image || !image.complete || image.naturalWidth === 0) return;

		const ctx = heroCanvas.getContext('2d');
		if (!ctx) return;

		const dpr = window.devicePixelRatio || 1;
		const cssWidth = heroCanvas.clientWidth;
		const cssHeight = heroCanvas.clientHeight;

		if (!cssWidth || !cssHeight) return;

		const targetWidth = Math.floor(cssWidth * dpr);
		const targetHeight = Math.floor(cssHeight * dpr);

		if (heroCanvas.width !== targetWidth || heroCanvas.height !== targetHeight) {
			heroCanvas.width = targetWidth;
			heroCanvas.height = targetHeight;
		}

		ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
		ctx.clearRect(0, 0, cssWidth, cssHeight);

		const coverScale = Math.max(cssWidth / image.naturalWidth, cssHeight / image.naturalHeight);
		const cinematicZoom = window.innerWidth <= 968 ? 1.12 : 1.17;
		const scale = coverScale * cinematicZoom;
		const drawWidth = image.naturalWidth * scale;
		const drawHeight = image.naturalHeight * scale;
		const focalX = window.innerWidth <= 968 ? -0.03 : -0.14;
		const rightShiftPx = cssWidth * (window.innerWidth <= 968 ? 0.07 : 0.12);
		const offsetX = (cssWidth - drawWidth) * focalX + rightShiftPx;
		const offsetY = (cssHeight - drawHeight) * 0.5;

		ctx.drawImage(image, offsetX, offsetY, drawWidth, drawHeight);
		activeFrameIndex = index;
	}

	function scheduleDraw(index: number) {
		pendingFrameIndex = index;
		if (rafScheduled) return;

		rafScheduled = true;
		requestAnimationFrame(() => {
			rafScheduled = false;
			drawFrame(pendingFrameIndex);
		});
	}

	function loadFrame(index: number, basePathIndex = 0) {
		if (index < 0 || index >= HERO_FRAME_COUNT) return;
		if (frameImages[index]) return;

		const image = new Image();
		const file = getFrameFilename(index);
		const source = `${HERO_FRAME_BASES[basePathIndex]}/${file}`;

		image.decoding = 'async';
		image.src = source;

		image.onload = () => {
			frameImages[index] = image;
			if (index === pendingFrameIndex || index === 0) {
				scheduleDraw(index);
			}
		};

		image.onerror = () => {
			if (basePathIndex + 1 < HERO_FRAME_BASES.length) {
				loadFrame(index, basePathIndex + 1);
			}
		};
	}

	function ensureFramesAround(index: number) {
		const preloadRadius = 10;
		for (let i = Math.max(0, index - preloadRadius); i <= Math.min(HERO_FRAME_COUNT - 1, index + preloadRadius); i += 1) {
			loadFrame(i);
		}
	}

	function getScrollProgress(scrollY: number) {
		if (!heroSection) return 0;
		const sectionTop = heroSection.offsetTop;
		const sectionHeight = heroSection.offsetHeight;
		const viewportHeight = window.innerHeight;
		const start = Math.max(0, sectionTop - viewportHeight * 0.04);
		const end = sectionTop + sectionHeight - viewportHeight * 0.08;
		const range = Math.max(1, end - start);
		return clamp((scrollY - start) / range, 0, 1);
	}

	function updateFromScroll(scrollY: number) {
		const progress = getScrollProgress(scrollY);
		const nextIndex = Math.round(progress * (HERO_FRAME_COUNT - 1));
		ensureFramesAround(nextIndex);
		if (nextIndex !== activeFrameIndex) {
			scheduleDraw(nextIndex);
		}
	}

	onMount(() => {
		if (!heroCanvas) return;
		if (window.innerWidth <= 968) return;

		if (!hasStartedPreload) {
			hasStartedPreload = true;
			for (let i = 0; i < HERO_FRAME_COUNT; i += 1) {
				loadFrame(i);
			}
		}

		const handleScroll = () => {
			latestScrollY = window.scrollY;
			updateFromScroll(latestScrollY);
		};

		const handleResize = () => {
			scheduleDraw(activeFrameIndex);
			updateFromScroll(latestScrollY);
		};

		latestScrollY = window.scrollY;
		updateFromScroll(latestScrollY);
		scheduleDraw(0);

		window.addEventListener('scroll', handleScroll, { passive: true });
		window.addEventListener('resize', handleResize);

		return () => {
			window.removeEventListener('scroll', handleScroll);
			window.removeEventListener('resize', handleResize);
		};
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
					"text": "Yes, Chord Trainer is completely free. No account, no signup, no subscription required. Open jazzchords.app in Chrome or Edge and start practicing immediately. All voicing types, progressions, guided practice plans, MIDI support, and progress tracking are included at no cost."
				}
			}
		]
	})}</script>`}
</svelte:head>

<!-- Cinematic Hero with Frame 1 -->
<section
	bind:this={heroSection}
	class="hero-stage relative isolate h-[calc(100svh-3.5rem)] overflow-hidden max-[968px]:h-auto max-[968px]:min-h-[calc(100svh-3.5rem)]"
>
	<div class="hero-media absolute inset-0 z-0">
		<canvas bind:this={heroCanvas} class="hero-canvas h-full w-full" aria-hidden="true"></canvas>
	</div>

	<div class="hero-glow absolute inset-x-0 bottom-0 h-[58%] pointer-events-none"></div>
	<div class="hero-mist hero-mist-left absolute -left-[18%] top-[10%] h-[56%] w-[52%] pointer-events-none"></div>
	<div class="hero-mist hero-mist-right absolute -right-[20%] top-[6%] h-[58%] w-[54%] pointer-events-none"></div>
	<div class="hero-watermark-mask absolute bottom-[1.5%] right-[0.8%] h-[13%] w-[13%] pointer-events-none"></div>
	<div class="hero-vignette absolute inset-0 pointer-events-none"></div>

	<div class="hero-content-frame relative z-2 flex h-full items-center">
	<div class="hero-copy-shell max-w-140 px-8 py-8 rounded-[1.35rem] max-[968px]:max-w-none max-[968px]:rounded-2xl max-[968px]:px-5 max-[968px]:py-5.5">
		<!-- Badge -->
		<div class="hero-badge inline-flex items-center gap-2 py-2 px-4 bg-[rgba(18,12,8,0.55)] border border-[rgba(255,140,66,0.45)] rounded-[999px] text-[0.76rem] tracking-[0.08em] uppercase text-(--accent-amber) mb-6 w-fit max-[968px]:mb-4 max-[968px]:text-[0.72rem]">
			<span class="w-2 h-2 bg-(--accent-amber) rounded-full animate-pulse"></span>
			{t('landing.badge')}
		</div>

		<!-- Titles -->
		<h1 class="hero-title text-[clamp(2rem,3.7vw,3.9rem)] font-black leading-[1.04] tracking-[-0.03em] mb-5 max-w-[16ch] max-[968px]:text-[clamp(1.62rem,8.2vw,2.32rem)] max-[968px]:leading-[1.07] max-[968px]:max-w-[11ch] max-[968px]:mb-3">
			<span class="block text-[rgba(255,186,110,0.96)]">{t('landing.hero_title_line1')}</span>
			<span class="block text-(--text)">{t('landing.hero_title_line2')}</span>
		</h1>

		<p class="hero-subtitle text-[0.98rem] leading-[1.62] text-[rgba(239,219,194,0.9)] max-w-[56ch] mb-4 max-[968px]:text-[0.92rem] max-[968px]:leading-[1.55]">
			{t('landing.hero_subtitle')}
		</p>

		<p class="hero-support text-[0.84rem] text-[rgba(192,165,139,0.9)] mb-7 flex items-center gap-1.5 max-[968px]:mb-5 max-[968px]:text-[0.8rem]">
			<svg class="w-4 h-4 text-(--accent-green) shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
			{t('landing.hero_no_midi')}
		</p>

		<!-- CTAs -->
		<div class="hero-cta-row flex flex-wrap gap-2.5 mb-5 max-[968px]:items-center">
			<a
				href="/train"
				class="hero-cta-primary py-3 px-5.5 rounded-[0.85rem] text-base font-semibold no-underline transition-all duration-300 inline-flex items-center gap-2 whitespace-nowrap text-(--primary-text) shadow-[0_6px_30px_rgba(232,118,59,0.35)] hover:-translate-y-0.5 hover:shadow-[0_12px_38px_rgba(232,118,59,0.45)] max-[968px]:text-[0.95rem] max-[968px]:px-4.5"
				style="background: linear-gradient(135deg, var(--primary) 0%, var(--accent-amber) 100%)"
			>
				{t('landing.cta_start')}
				<span>→</span>
			</a>
			<a href="/learn" class="hero-cta-secondary py-3 px-5.5 rounded-[0.85rem] text-base font-semibold no-underline transition-all duration-300 inline-flex items-center gap-2 whitespace-nowrap bg-[rgba(15,10,8,0.56)] text-(--text) border border-[rgba(188,141,97,0.32)] hover:bg-[rgba(25,17,12,0.72)] hover:border-[rgba(212,175,55,0.62)] max-[968px]:py-2.5 max-[968px]:px-4 max-[968px]:text-[0.95rem]">
				{t('landing.cta_learn')}
			</a>
			<a href="/for-educators" class="py-3 px-5.5 rounded-[0.85rem] text-base font-semibold no-underline transition-all duration-300 inline-flex items-center gap-2 whitespace-nowrap bg-[rgba(15,10,8,0.56)] text-(--text) border border-[rgba(188,141,97,0.32)] hover:bg-[rgba(25,17,12,0.72)] hover:border-[rgba(212,175,55,0.62)] max-[968px]:hidden">
				{t('landing.cta_educators')}
			</a>
		</div>

		<p class="hero-footnote text-[0.9rem] text-[rgba(165,142,120,0.92)] max-[968px]:hidden">{t('landing.footnote')}</p>
		<p class="hero-footnote-mobile text-[0.9rem] text-[rgba(165,142,120,0.92)] hidden max-[968px]:block">{t('landing.footnote_mobile')}</p>
		<a href="/for-educators" class="hero-edu-link hidden max-[968px]:inline-block max-[968px]:mt-3 text-[0.8rem] text-(--text-muted) no-underline transition-colors duration-150 hover:text-(--text)">
			{t('landing.cta_educators')} →
		</a>
	</div>
	</div>
</section>

<!-- Plug in. Play. Get faster. — cinematic rows -->
<section class="overflow-x-hidden" style="background: linear-gradient(180deg, var(--bg) 0%, #0e0c09 20%, #0e0c09 80%, var(--bg) 100%)">

	<!-- Step 1: Plug In -->
	<div class="grid grid-cols-2 items-center min-h-[55vh] border-b border-[rgba(255,255,255,0.04)] max-w-400 mx-auto w-full max-[968px]:grid-cols-1 max-[968px]:min-h-auto">
		<div class="group relative w-full h-full min-h-[55vh] flex items-center justify-center contain-[layout] max-[968px]:min-h-[78vw] max-[968px]:pt-10 max-[968px]:overflow-visible">
			<div class="absolute inset-0 pointer-events-none z-0" style="background: radial-gradient(ellipse 70% 60% at 50% 60%, rgba(232, 118, 59, 0.12) 0%, transparent 65%)"></div>
			<!-- Piano image (cord curls behind via z-index) -->
			<img src="/bilder/pluged-in-piano.webp" alt="A jazz chord voicing on screen, ready to play"
				class="relative z-1 w-[85%] h-auto object-contain transition-transform duration-[0.6s] ease-in-out aspect-800/600 group-hover:scale-[1.04] max-[968px]:w-[115%] max-[968px]:max-w-none"
				width="800" height="600" loading="lazy"
				sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 567px" />
			<!-- Floating chord label — layered over the piano for depth -->
			<div class="step1-chord pointer-events-none absolute z-2 left-1/2 top-[14%] text-center select-none">
				<div class="text-gradient text-[clamp(2.4rem,5.2vw,4rem)] font-black leading-none tracking-[-0.02em] [filter:drop-shadow(0_10px_28px_rgba(0,0,0,0.55))]">CMaj7</div>
				<div class="mt-1.5 text-[0.72rem] uppercase tracking-[0.16em] text-[rgba(244,228,210,0.72)] font-medium [text-shadow:0_2px_8px_rgba(0,0,0,0.6)]">Shell Voicing</div>
				<div class="mt-1 flex items-center justify-center gap-2 font-mono text-[1.05rem] font-bold text-(--text) [text-shadow:0_2px_8px_rgba(0,0,0,0.6)]">
					<span>C</span><span class="text-(--primary)">–</span><span>E</span><span class="text-(--primary)">–</span><span>B</span>
				</div>
			</div>
		</div>
		<div class="p-[3rem_5%_3rem_6%] max-[968px]:p-[1.5rem_1.5rem_3rem]">
			<span class="block text-[5rem] font-black leading-none mb-2 opacity-35 tabular-nums bg-linear-to-br from-(--primary) to-(--accent-amber) bg-clip-text text-transparent max-[968px]:text-[3.5rem]" style="-webkit-text-fill-color: transparent">01</span>
			<h2 class="text-[clamp(2.5rem,3.5vw,4rem)] font-extrabold leading-[1.1] text-(--text) mb-4 max-[968px]:text-[2rem]">{t('landing.step1_title')}</h2>
			<p class="text-[1.15rem] leading-[1.7] text-(--text-muted) mb-8 max-w-105 max-[968px]:text-base">{t('landing.step1_desc')}</p>
			<div class="flex flex-wrap gap-[0.6rem]">
				<span class="story-chip inline-flex items-center gap-[0.4rem] py-[0.4rem] px-[0.9rem] rounded-2xl border border-[rgba(232,118,59,0.3)] bg-[rgba(232,118,59,0.06)] text-[0.85rem] text-(--text-muted)"><Piano size={14} />{t('landing.step1_chip1')}</span>
				<span class="story-chip inline-flex items-center gap-[0.4rem] py-[0.4rem] px-[0.9rem] rounded-2xl border border-[rgba(232,118,59,0.3)] bg-[rgba(232,118,59,0.06)] text-[0.85rem] text-(--text-muted)"><Music size={14} />{t('landing.step1_chip2')}</span>
			</div>
		</div>
	</div>

	<!-- Step 2: Play -->
	<div class="grid grid-cols-2 items-center min-h-[55vh] border-b border-[rgba(255,255,255,0.04)] max-w-400 mx-auto w-full [direction:rtl] *:[direction:ltr] max-[968px]:grid-cols-1 max-[968px]:min-h-auto max-[968px]:[direction:ltr]">
		<div class="group relative w-full h-full min-h-[55vh] flex items-center justify-center contain-[layout] max-[968px]:min-h-[72vw] max-[968px]:pt-10 max-[968px]:overflow-visible">
			<div class="absolute inset-0 pointer-events-none z-0" style="background: radial-gradient(ellipse 70% 60% at 50% 60%, rgba(232, 118, 59, 0.1) 0%, transparent 65%)"></div>
			<img src="/bilder/hands-on-piano.webp" alt="Play the voicing and get instant feedback"
				class="relative z-1 w-[85%] h-auto object-contain transition-transform duration-[0.6s] ease-in-out aspect-800/600 group-hover:scale-[1.04] max-[968px]:w-[115%] max-[968px]:max-w-none"
				width="800" height="600" loading="lazy"
				sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 567px" />
		</div>
		<div class="p-[3rem_6%_3rem_5%] max-[968px]:p-[1.5rem_1.5rem_3rem]">
			<span class="block text-[5rem] font-black leading-none mb-2 opacity-35 tabular-nums bg-linear-to-br from-(--primary) to-(--accent-amber) bg-clip-text text-transparent max-[968px]:text-[3.5rem]" style="-webkit-text-fill-color: transparent">02</span>
			<h2 class="text-[clamp(2.5rem,3.5vw,4rem)] font-extrabold leading-[1.1] text-(--text) mb-4 max-[968px]:text-[2rem]">{t('landing.step2_title')}</h2>
			<p class="text-[1.15rem] leading-[1.7] text-(--text-muted) mb-8 max-w-105 max-[968px]:text-base">{t('landing.step2_desc')}</p>
			<div class="flex flex-wrap gap-[0.6rem]">
				<span class="story-chip inline-flex items-center gap-[0.4rem] py-[0.4rem] px-[0.9rem] rounded-2xl border border-[rgba(232,118,59,0.3)] bg-[rgba(232,118,59,0.06)] text-[0.85rem] text-(--text-muted)"><Target size={14} />{t('landing.step2_chip1')}</span>
				<span class="story-chip inline-flex items-center gap-[0.4rem] py-[0.4rem] px-[0.9rem] rounded-2xl border border-[rgba(232,118,59,0.3)] bg-[rgba(232,118,59,0.06)] text-[0.85rem] text-(--text-muted)"><Keyboard size={14} />{t('landing.step2_chip2')}</span>
			</div>
		</div>
	</div>

	<!-- Step 3: Get Faster -->
	<div class="grid grid-cols-2 items-center min-h-[55vh] border-b border-[rgba(255,255,255,0.04)] max-w-400 mx-auto w-full max-[968px]:grid-cols-1 max-[968px]:min-h-auto">
		<div class="group relative w-full h-full min-h-[55vh] flex items-center justify-center contain-[layout] max-[968px]:min-h-[72vw] max-[968px]:pt-10 max-[968px]:overflow-visible">
			<div class="absolute inset-0 pointer-events-none z-0" style="background: radial-gradient(ellipse 70% 60% at 50% 60%, rgba(255, 170, 50, 0.15) 0%, transparent 65%)"></div>
			<img src="/bilder/lvl-up-piano.webp" alt="Level up and get faster"
				class="relative z-1 w-[85%] h-auto object-contain transition-transform duration-[0.6s] ease-in-out aspect-800/600 group-hover:scale-[1.04] max-[968px]:w-[115%] max-[968px]:max-w-none"
				width="800" height="600" loading="lazy"
				sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 567px" />
		</div>
		<div class="p-[3rem_5%_3rem_6%] max-[968px]:p-[1.5rem_1.5rem_3rem]">
			<span class="block text-[5rem] font-black leading-none mb-2 opacity-35 tabular-nums bg-linear-to-br from-(--primary) to-(--accent-amber) bg-clip-text text-transparent max-[968px]:text-[3.5rem]" style="-webkit-text-fill-color: transparent">03</span>
			<h2 class="text-[clamp(2.5rem,3.5vw,4rem)] font-extrabold leading-[1.1] text-(--text) mb-4 max-[968px]:text-[2rem]">{t('landing.step3_title')}</h2>
			<p class="text-[1.15rem] leading-[1.7] text-(--text-muted) mb-8 max-w-105 max-[968px]:text-base">{t('landing.step3_desc')}</p>
			<div class="flex flex-wrap gap-[0.6rem]">
				<span class="story-chip inline-flex items-center gap-[0.4rem] py-[0.4rem] px-[0.9rem] rounded-2xl border border-[rgba(232,118,59,0.3)] bg-[rgba(232,118,59,0.06)] text-[0.85rem] text-(--text-muted)"><BarChart3 size={14} />{t('landing.step3_chip1')}</span>
				<span class="story-chip inline-flex items-center gap-[0.4rem] py-[0.4rem] px-[0.9rem] rounded-2xl border border-[rgba(232,118,59,0.3)] bg-[rgba(232,118,59,0.06)] text-[0.85rem] text-(--text-muted)"><BookOpen size={14} />{t('landing.step3_chip2')}</span>
			</div>
		</div>
	</div>

</section>

<!-- Bottom CTA -->
<section class="pt-8 pb-24">
	<div class="max-w-xl mx-auto text-center px-4">
		<h2 class="text-2xl sm:text-3xl font-bold mb-3">{t('landing.bottom_cta_title')}</h2>
		<p class="text-(--text-muted) mb-6">{t('landing.bottom_cta_desc')}</p>
		<a
			href="/train"
			class="inline-flex items-center gap-2 px-8 py-3.5 rounded-lg bg-(--primary) hover:bg-(--primary-hover) text-white font-semibold text-lg transition-colors"
		>
			{t('landing.cta_start')}
			<ArrowRight size={20} />
		</a>
	</div>
</section>

<style>
	.hero-stage {
		--hero-safe: clamp(1.8rem, 4.2vw, 5.8rem);
		background:
			radial-gradient(circle at 50% 78%, rgba(232, 118, 59, 0.38) 0%, rgba(232, 118, 59, 0.1) 25%, transparent 58%),
			radial-gradient(circle at 82% 14%, rgba(232, 118, 59, 0.22) 0%, transparent 40%),
			linear-gradient(180deg, #070605 0%, #0a0908 36%, #0f0b08 72%, #080706 100%);
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
		background: #060504;
		filter: saturate(1.09) contrast(1.05) brightness(0.9);
	}

	.hero-copy-shell {
		width: min(41rem, 48vw);
		min-width: 31rem;
		background: linear-gradient(145deg, rgba(8, 7, 6, 0.72) 0%, rgba(8, 7, 6, 0.38) 52%, rgba(8, 7, 6, 0.16) 100%);
		border: 1px solid rgba(255, 186, 110, 0.2);
		backdrop-filter: blur(9px);
		box-shadow: 0 18px 50px rgba(0, 0, 0, 0.34), inset 0 1px 0 rgba(255, 222, 186, 0.12);
	}

	@media (max-width: 1280px) {
		.hero-copy-shell {
			width: min(36rem, 54vw);
			min-width: 0;
		}
	}

	.hero-glow {
		background: radial-gradient(ellipse at center, rgba(232, 118, 59, 0.25) 0%, rgba(232, 118, 59, 0.12) 38%, transparent 70%);
		filter: blur(20px);
	}

	.hero-watermark-mask {
		background:
			radial-gradient(ellipse at center, rgba(10, 8, 7, 0.98) 0%, rgba(10, 8, 7, 0.76) 44%, rgba(10, 8, 7, 0.18) 72%, transparent 100%),
			radial-gradient(ellipse at center, rgba(232, 118, 59, 0.28) 0%, transparent 74%);
		filter: blur(12px);
	}

	.hero-mist {
		filter: blur(42px);
		opacity: 0.5;
		will-change: transform;
		animation: hero-mist-drift 12s ease-in-out infinite;
	}

	.hero-mist-left {
		background: radial-gradient(ellipse at center, rgba(255, 199, 146, 0.13) 0%, rgba(255, 146, 83, 0.09) 34%, transparent 70%);
	}

	.hero-mist-right {
		background: radial-gradient(ellipse at center, rgba(255, 167, 98, 0.14) 0%, rgba(232, 118, 59, 0.08) 36%, transparent 72%);
		animation-delay: -4s;
	}

	.hero-vignette {
		background:
			radial-gradient(circle at 50% 35%, transparent 0%, rgba(0, 0, 0, 0.3) 62%, rgba(0, 0, 0, 0.66) 100%),
			linear-gradient(90deg, rgba(7, 5, 4, 0.8) 0%, transparent 18%, transparent 82%, rgba(7, 5, 4, 0.82) 100%);
	}

	.hero-title {
		text-wrap: balance;
	}

	@keyframes hero-mist-drift {
		0%,
		100% {
			transform: translate3d(0, 0, 0);
		}
		50% {
			transform: translate3d(12px, -8px, 0);
		}
	}

	@media (prefers-reduced-motion: reduce) {
		.hero-mist {
			animation: none;
		}
	}

	@media (max-width: 968px) {
		.hero-media,
		.hero-glow,
		.hero-mist,
		.hero-watermark-mask {
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
				radial-gradient(75% 58% at 88% 12%, rgba(232, 118, 59, 0.22) 0%, transparent 72%),
				linear-gradient(180deg, #080706 0%, #0b0806 38%, #0d0907 100%);
		}

		.hero-content-frame {
			padding: 0 1.25rem;
		}

		.hero-badge,
		.hero-support {
			display: none;
		}

		.hero-vignette {
			background: linear-gradient(180deg, rgba(8, 7, 6, 0.08) 0%, rgba(8, 7, 6, 0.42) 50%, rgba(8, 7, 6, 0.76) 100%);
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

	:global(.story-chip svg) {
		color: var(--primary);
		flex-shrink: 0;
	}

	.step1-chord {
		animation: step1-chord-float 5.5s ease-in-out infinite;
		will-change: transform;
	}

	@keyframes step1-chord-float {
		0%, 100% {
			transform: translate(-50%, 0);
		}
		50% {
			transform: translate(-50%, -7px);
		}
	}

	@media (prefers-reduced-motion: reduce) {
		.step1-chord {
			animation: none;
		}
	}
</style>
