<script lang="ts">
	import { onMount } from 'svelte';
	import { t } from '$lib/i18n';
	import {
		Piano,
		Volume2,
		BarChart3,
		BookOpen,
		ArrowRight,
		Keyboard,
		Target,
	} from 'lucide-svelte';

	let videoElement: HTMLVideoElement;
	let scrollProgress = $state(0);
	let useStaticFallback = $state(false);
	let isMobile = $state(false);

	onMount(() => {
		const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
		isMobile = window.matchMedia('(max-width: 968px)').matches;
		const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

		// Static fallback for reduced motion preference
		if (prefersReducedMotion) {
			useStaticFallback = true;
		}

		// On mobile OR any touch device (iPad etc): show first frame only, no scroll animation
		// iOS Safari throttles video.currentTime seeks, making scroll animation unusable
		if (isMobile || isTouchDevice) {
			useStaticFallback = true;
			if (videoElement) {
				videoElement.load();
				videoElement.addEventListener('loadeddata', () => {
					videoElement.currentTime = 0;
				}, { once: true });
			}
			return;
		}

		let targetTime = 0;
		let isUpdating = false;

		const handleScroll = () => {
			if (!videoElement || !videoElement.duration) return;

			const scrollTop = window.scrollY;
			const docHeight = document.documentElement.scrollHeight - window.innerHeight;
			const scrollPercent = scrollTop / docHeight;
			scrollProgress = Math.min(scrollPercent * 0.7, 1);
			targetTime = videoElement.duration * scrollProgress;

			if (!isUpdating && !useStaticFallback) {
				isUpdating = true;
				videoElement.currentTime = targetTime;
			}
		};

		// When the browser has actually decoded a frame after seeking,
		// seek to the latest target — this avoids queueing seeks faster than decode.
		const onSeeked = () => {
			if (!videoElement || useStaticFallback) return;
			isUpdating = false;

			// If scroll moved since our last seek, catch up
			if (Math.abs(videoElement.currentTime - targetTime) > 0.05) {
				isUpdating = true;
				videoElement.currentTime = targetTime;
			}
		};

		window.addEventListener('scroll', handleScroll, { passive: true });

		// Preload video
		if (videoElement) {
			videoElement.addEventListener('seeked', onSeeked);
			videoElement.load();
		}

		return () => {
			window.removeEventListener('scroll', handleScroll);
			videoElement?.removeEventListener('seeked', onSeeked);
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

<!-- Hero with Scroll-Controlled 3D Piano -->
<section
	class="relative h-[calc(100svh-3.5rem)] min-h-120 flex items-center py-16 px-[5%] xl:px-[8%] 2xl:px-[12%] max-[968px]:text-left max-[968px]:py-8"
	style="background: linear-gradient(135deg, #0a0908 0%, #1a1410 30%, #3e2723 50%, #1a1410 70%, #0a0908 100%)"
>
	<div class="relative z-2 max-w-150 max-[968px]:max-w-none">
		<!-- Badge -->
		<div class="inline-flex items-center gap-2 py-2 px-4 bg-(--glow-warm) border border-(--accent-amber) rounded-[20px] text-[0.85rem] text-(--accent-amber) mb-8 w-fit max-[968px]:hidden">
			<span class="w-2 h-2 bg-(--accent-amber) rounded-full animate-pulse"></span>
			{t('landing.badge')}
		</div>

		<!-- Titles -->
		<h1 class="text-[clamp(3rem,5vw,4.5rem)] font-extrabold leading-[1.1] mb-6">
			{@html t('landing.hero_title_html')}
		</h1>

		<p class="text-xl leading-[1.6] text-(--text-muted) max-w-125 mb-10 max-[968px]:hidden">
			{t('landing.hero_subtitle')}
		</p>

		<p class="text-xl leading-[1.6] text-(--text-muted) max-w-125 mb-10 hidden max-[968px]:block">
			{t('landing.hero_subtitle_mobile')}
		</p>

		<!-- CTAs -->
		<div class="flex flex-wrap gap-3 mb-6 max-[968px]:items-center">
			<a
				href="/train"
				class="py-3.5 px-6 rounded-xl text-base font-semibold no-underline transition-all duration-300 inline-flex items-center gap-2 whitespace-nowrap text-(--primary-text) shadow-[0_4px_20px_var(--glow-warm)] hover:-translate-y-0.5 hover:shadow-[0_6px_30px_var(--glow-warm)]"
				style="background: linear-gradient(135deg, var(--primary) 0%, var(--accent-amber) 100%)"
			>
				{t('landing.cta_start')}
				<span class="arrow">→</span>
			</a>
			<a href="/learn" class="py-3.5 px-6 rounded-xl text-base font-semibold no-underline transition-all duration-300 inline-flex items-center gap-2 whitespace-nowrap bg-(--wood-dark) text-(--text) border border-(--wood-light) hover:bg-(--wood-light) hover:border-(--accent-gold) max-[968px]:hidden">
				{t('landing.cta_learn')}
			</a>
			<a href="/for-educators" class="py-3.5 px-6 rounded-xl text-base font-semibold no-underline transition-all duration-300 inline-flex items-center gap-2 whitespace-nowrap bg-(--wood-dark) text-(--text) border border-(--wood-light) hover:bg-(--wood-light) hover:border-(--accent-gold) max-[968px]:hidden">
				{t('landing.cta_educators')}
			</a>
		</div>

		<p class="text-[0.9rem] text-(--text-dim) max-[968px]:hidden">{t('landing.footnote')}</p>
		<p class="text-[0.9rem] text-(--text-dim) hidden max-[968px]:block">{t('landing.footnote_mobile')}</p>
		<a href="/for-educators" class="hidden max-[968px]:inline-block max-[968px]:mt-3 text-[0.8rem] text-(--text-muted) no-underline transition-colors duration-150 hover:text-(--text)">
			{t('landing.cta_educators')} →
		</a>
	</div>

	<!-- Piano Animation (Scroll-controlled) -->
	<div class="piano-container absolute right-0 top-0 bottom-0 w-[60%] flex items-center justify-end pointer-events-none max-[968px]:hidden">
		<video
			bind:this={videoElement}
			muted
			playsinline
			preload="auto"
			class="w-full h-full object-contain object-right mix-blend-screen brightness-[1.1] contrast-[1.1]"
			width="1920"
			height="1080"
		>
			<source src="/videos/piano-rotation-4.webm" type="video/webm" />
		</video>
	</div>

	<!-- Static image for mobile/touch (no video) — eager + high priority: LCP on mobile -->
	<div class="piano-static hidden max-[968px]:block max-[968px]:absolute max-[968px]:inset-0 max-[968px]:pointer-events-none max-[968px]:z-0">
		<img src="/bilder/piano.webp" alt="Jazz piano" class="piano-static-img max-[968px]:w-full max-[968px]:h-full max-[968px]:object-cover max-[968px]:object-center max-[968px]:opacity-20 max-[968px]:brightness-[0.8] max-[968px]:contrast-[1.2]"
			width="1200" height="800" loading="eager" fetchpriority="high" />
	</div>
</section>

<!-- Plug in. Play. Get faster. — cinematic rows -->
<section class="overflow-x-hidden" style="background: linear-gradient(180deg, var(--bg) 0%, #0e0c09 20%, #0e0c09 80%, var(--bg) 100%)">

	<!-- Step 1: Plug In -->
	<div class="grid grid-cols-2 items-center min-h-[55vh] border-b border-[rgba(255,255,255,0.04)] max-w-400 mx-auto w-full max-[968px]:grid-cols-1 max-[968px]:min-h-auto">
		<div class="group relative w-full h-full min-h-[55vh] flex items-center justify-center contain-[layout] max-[968px]:min-h-[72vw] max-[968px]:pt-10 max-[968px]:overflow-visible">
			<div class="absolute inset-0 pointer-events-none z-0" style="background: radial-gradient(ellipse 70% 60% at 50% 60%, rgba(232, 118, 59, 0.12) 0%, transparent 65%)"></div>
			<img src="/bilder/pluged-in-piano.webp" alt="Connect MIDI keyboard via USB"
				class="relative z-1 w-[85%] h-auto object-contain transition-transform duration-[0.6s] ease-in-out aspect-800/600 group-hover:scale-[1.04] max-[968px]:w-[115%] max-[968px]:max-w-none"
				width="800" height="600" loading="lazy"
				sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 567px" />
		</div>
		<div class="p-[3rem_5%_3rem_6%] max-[968px]:p-[1.5rem_1.5rem_3rem]">
			<span class="block text-[5rem] font-black leading-none mb-2 opacity-35 tabular-nums bg-linear-to-br from-(--primary) to-(--accent-amber) bg-clip-text text-transparent max-[968px]:text-[3.5rem]" style="-webkit-text-fill-color: transparent">01</span>
			<h2 class="text-[clamp(2.5rem,3.5vw,4rem)] font-extrabold leading-[1.1] text-(--text) mb-4 max-[968px]:text-[2rem]">{t('landing.step1_title')}</h2>
			<p class="text-[1.15rem] leading-[1.7] text-(--text-muted) mb-8 max-w-105 max-[968px]:text-base">{t('landing.step1_desc')}</p>
			<div class="flex flex-wrap gap-[0.6rem]">
				<span class="story-chip inline-flex items-center gap-[0.4rem] py-[0.4rem] px-[0.9rem] rounded-2xl border border-[rgba(232,118,59,0.3)] bg-[rgba(232,118,59,0.06)] text-[0.85rem] text-(--text-muted)"><Piano size={14} />{t('landing.step1_chip1')}</span>
				<span class="story-chip inline-flex items-center gap-[0.4rem] py-[0.4rem] px-[0.9rem] rounded-2xl border border-[rgba(232,118,59,0.3)] bg-[rgba(232,118,59,0.06)] text-[0.85rem] text-(--text-muted)"><Volume2 size={14} />{t('landing.step1_chip2')}</span>
			</div>
		</div>
	</div>

	<!-- Step 2: Play -->
	<div class="grid grid-cols-2 items-center min-h-[55vh] border-b border-[rgba(255,255,255,0.04)] max-w-400 mx-auto w-full [direction:rtl] *:[direction:ltr] max-[968px]:grid-cols-1 max-[968px]:min-h-auto max-[968px]:[direction:ltr]">
		<div class="group relative w-full h-full min-h-[55vh] flex items-center justify-center contain-[layout] max-[968px]:min-h-[72vw] max-[968px]:pt-10 max-[968px]:overflow-visible">
			<div class="absolute inset-0 pointer-events-none z-0" style="background: radial-gradient(ellipse 70% 60% at 50% 60%, rgba(232, 118, 59, 0.1) 0%, transparent 65%)"></div>
			<img src="/bilder/hands-on-piano.webp" alt="Play chords on the keyboard"
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
	/* Gradient text classes used in @html hero title */
	:global(.gradient-text) {
		display: block;
		background: linear-gradient(135deg, var(--primary) 0%, var(--accent-amber) 100%);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}

	:global(.white-text) {
		display: block;
		color: var(--text);
	}

	/* Touch devices (iPad etc) above mobile breakpoint: use static image */
	@media (hover: none) and (pointer: coarse) and (min-width: 969px) {
		.piano-container {
			display: none;
		}

		.piano-static {
			position: absolute;
			inset: 0;
			display: block;
			pointer-events: none;
			z-index: 0;
			overflow: hidden;
		}

		.piano-static-img {
			width: 100%;
			height: 100%;
			object-fit: cover;
			object-position: center center;
			opacity: 0.50;
			filter: brightness(0.8) contrast(1.2) blur(1px);
			transform: translateX(15%);
		}
	}

	:global(.story-chip svg) {
		color: var(--primary);
		flex-shrink: 0;
	}
</style>
