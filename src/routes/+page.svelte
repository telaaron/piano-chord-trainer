<script lang="ts">
	import { onMount } from 'svelte';
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
	<title>Chord Trainer – Jazz Piano Voicing Speed Training</title>
	<meta name="description" content="Master jazz piano voicings in all 12 keys. Speed training with MIDI recognition, ii-V-I progressions, 4 voicing types, and progress tracking. Free, no signup." />
	<link rel="canonical" href="https://jazzchords.app/" />
	<meta property="og:title" content="Chord Trainer – Jazz Piano Voicing Speed Training" />
	<meta property="og:description" content="Master jazz piano voicings in all 12 keys. Speed training with MIDI recognition and ii-V-I progressions." />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://jazzchords.app/" />
	<meta property="og:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta property="og:image:type" content="image/webp" />
	<meta property="og:image:width" content="966" />
	<meta property="og:image:height" content="507" />
	<meta property="og:image:alt" content="Chord Trainer hero with piano and jazz voicing practice" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="Chord Trainer – Jazz Piano Voicing Speed Training" />
	<meta name="twitter:description" content="Master jazz piano voicings in all 12 keys. MIDI recognition, ii-V-I progressions, progress tracking." />
	<meta name="twitter:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta name="twitter:image:alt" content="Chord Trainer hero with piano and jazz voicing practice" />
</svelte:head>

<!-- Hero with Scroll-Controlled 3D Piano -->
<section class="hero">
	<div class="hero-content">
		<!-- Badge -->
		<div class="badge hide-mobile">
			<span class="dot"></span>
			MIDI · Audio · Progress Tracking
		</div>

		<!-- Titles -->
		<h1>
			<span class="gradient-text">Master Jazz Piano</span>
			<span class="white-text">Voicings in All 12 Keys</span>
		</h1>

		<p class="subtitle hide-mobile">
			Speed training that builds muscle memory. See a chord, play it, get faster.
			Shell voicings, rootless, ii-V-I — through every key.
		</p>

		<p class="subtitle show-mobile-only">
			See a chord, play it, get faster — through all 12 keys.
		</p>

		<!-- CTAs -->
		<div class="cta-buttons">
			<a href="/train" class="btn btn-primary">
				Start Training
				<span class="arrow">→</span>
			</a>
			<a href="/for-educators" class="btn btn-secondary hide-mobile">
				For Music Schools
			</a>
		</div>

		<p class="footnote hide-mobile">Free. No signup. Works in Chrome &amp; Edge.</p>
		<p class="footnote show-mobile-only">Free · MIDI · No signup</p>
	</div>

	<!-- Piano Animation (Scroll-controlled) -->
	<div class="piano-container">
		<video 
			bind:this={videoElement}
			muted
			playsinline
			preload="auto"
			class="piano-video"
		>
			<source src="/videos/piano-rotation-4.webm" type="video/webm" />
		</video>
	</div>

	<!-- Static image for mobile/touch (no video) -->
	<div class="piano-static">
		<img src="/bilder/piano.webp" alt="Jazz piano" class="piano-static-img" />
	</div>
</section>

<!-- Plug in. Play. Get faster. — cinematic rows -->
<section class="story-section">

	<!-- Step 1: Plug In -->
	<div class="story-row">
		<div class="story-image-wrap story-image-left">
			<div class="story-glow story-glow-1"></div>
			<img src="/bilder/pluged-in-piano.webp" alt="Connect MIDI keyboard via USB" class="story-image story-image-1" />
		</div>
		<div class="story-text">
			<span class="story-num">01</span>
			<h2 class="story-title">Plug In</h2>
			<p class="story-desc">Connect your MIDI keyboard via USB. The app detects it instantly — no drivers, no setup.</p>
			<div class="story-chips">
				<span class="story-chip"><Piano size={14} />MIDI auto-detect</span>
				<span class="story-chip"><Volume2 size={14} />Audio &amp; metronome</span>
			</div>
		</div>
	</div>

	<!-- Step 2: Play -->
	<div class="story-row story-row-reverse">
		<div class="story-image-wrap story-image-right">
			<div class="story-glow story-glow-2"></div>
		<img src="/bilder/hands-on-piano.webp" alt="Play chords on the keyboard" class="story-image" />
		</div>
		<div class="story-text">
			<span class="story-num">02</span>
			<h2 class="story-title">Play</h2>
			<p class="story-desc">See a chord on screen, play it on your keyboard. Instant feedback every time.</p>
			<div class="story-chips">
				<span class="story-chip"><Target size={14} />ii-V-I all 12 keys</span>
				<span class="story-chip"><Keyboard size={14} />4+ voicing types</span>
			</div>
		</div>
	</div>

	<!-- Step 3: Get Faster -->
	<div class="story-row">
		<div class="story-image-wrap story-image-left">
			<div class="story-glow story-glow-3"></div>
		<img src="/bilder/lvl-up-piano.webp" alt="Level up and get faster" class="story-image" />
		</div>
		<div class="story-text">
			<span class="story-num">03</span>
			<h2 class="story-title">Get Faster</h2>
			<p class="story-desc">Track your response times, pinpoint weak spots, watch yourself improve session by session.</p>
			<div class="story-chips">
				<span class="story-chip"><BarChart3 size={14} />Weakness tracking</span>
				<span class="story-chip"><BookOpen size={14} />Practice plans</span>
			</div>
		</div>
	</div>

</section>

<!-- Bottom CTA -->
<section class="cta-section">
	<div class="max-w-xl mx-auto text-center px-4">
		<h2 class="text-2xl sm:text-3xl font-bold mb-3">Ready?</h2>
		<p class="text-[var(--text-muted)] mb-6">No account. No install. Just play.</p>
		<a
			href="/train"
			class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white font-semibold text-lg transition-colors"
		>
			Start Training
			<ArrowRight size={20} />
		</a>
	</div>
</section>

<style>
	.hero {
		position: relative;
		height: calc(100dvh - 3.5rem);
		min-height: 480px;
		display: flex;
		align-items: center;
		padding: 4rem 5%;
		background: linear-gradient(135deg, #0a0908 0%, #1a1410 30%, #3e2723 50%, #1a1410 70%, #0a0908 100%);
	}

	@media (min-width: 1280px) {
		.hero { padding: 4rem 8%; }
	}
	@media (min-width: 1536px) {
		.hero { padding: 4rem 12%; }
	}

	.hero-content {
		position: relative;
		z-index: 2;
		max-width: 600px;
	}

	/* Badge */
	.badge {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		padding: 0.5rem 1rem;
		background: var(--glow-warm);
		border: 1px solid var(--accent-amber);
		border-radius: 20px;
		font-size: 0.85rem;
		color: var(--accent-amber);
		margin-bottom: 2rem;
		width: fit-content;
	}

	.dot {
		width: 8px;
		height: 8px;
		background: var(--accent-amber);
		border-radius: 50%;
		animation: pulse 2s infinite;
	}

	@keyframes pulse {
		0%, 100% { opacity: 1; }
		50% { opacity: 0.5; }
	}

	/* Typography */
	h1 {
		font-size: clamp(3rem, 5vw, 4.5rem);
		font-weight: 800;
		line-height: 1.1;
		margin-bottom: 1.5rem;
	}

	.gradient-text {
		display: block;
		background: linear-gradient(135deg, var(--primary) 0%, var(--accent-amber) 100%);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}

	.white-text {
		display: block;
		color: var(--text);
	}

	.subtitle {
		font-size: 1.25rem;
		line-height: 1.6;
		color: var(--text-muted);
		max-width: 500px;
		margin-bottom: 2.5rem;
	}

	/* CTAs */
	.cta-buttons {
		display: flex;
		gap: 1rem;
		margin-bottom: 1.5rem;
	}

	.btn {
		padding: 1rem 2rem;
		border-radius: 12px;
		font-size: 1.1rem;
		font-weight: 600;
		text-decoration: none;
		transition: all 0.3s ease;
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
	}

	.btn-primary {
		background: linear-gradient(135deg, var(--primary) 0%, var(--accent-amber) 100%);
		color: var(--primary-text);
		box-shadow: 0 4px 20px var(--glow-warm);
	}

	.btn-primary:hover {
		transform: translateY(-2px);
		box-shadow: 0 6px 30px var(--glow-warm);
	}

	.btn-secondary {
		background: var(--wood-dark);
		color: var(--text);
		border: 1px solid var(--wood-light);
	}

	.btn-secondary:hover {
		background: var(--wood-light);
		border-color: var(--accent-gold);
	}

	.footnote {
		font-size: 0.9rem;
		color: var(--text-dim);
	}

	/* Static piano image — hidden on desktop, shown on mobile/touch */
	.piano-static {
		display: none;
	}

	/* Mobile-specific visibility */
	.show-mobile-only {
		display: none;
	}

	.hide-mobile {
		display: block;
	}

	/* Piano Video */
	.piano-container {
		position: absolute;
		right: 0;
		top: 0;
		bottom: 0;
		width: 60%;
		display: flex;
		align-items: center;
		justify-content: flex-end;
		pointer-events: none;
	}

	.piano-video {
		width: 100%;
		height: 100%;
		object-fit: contain;
		object-position: right center;
		mix-blend-mode: screen;
		filter: brightness(1.1) contrast(1.1);
	}

	/* Mobile: video becomes subtle background behind hero */
	@media (max-width: 968px) {
		.hide-mobile {
			display: none !important;
		}

		.show-mobile-only {
			display: block !important;
		}

		.hero {
			text-align: center;
			padding: 2rem 5%;
		}

		.hero-content {
			position: relative;
			z-index: 2;
			max-width: none;
		}

		.piano-container {
			display: none;
		}

		.piano-static {
			position: absolute;
			inset: 0;
			display: block;
			pointer-events: none;
			z-index: 0;
		}

		.piano-static-img {
			width: 100%;
			height: 100%;
			object-fit: cover;
			object-position: center center;
			opacity: 0.15;
			filter: brightness(0.8) contrast(1.2) blur(1px);
		}

		.subtitle {
			margin-left: auto;
			margin-right: auto;
		}

		.cta-buttons {
			justify-content: center;
			flex-direction: column;
			align-items: center;
		}

		.btn {
			width: 100%;
			max-width: 300px;
		}
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
		}

		.piano-static-img {
			width: 100%;
			height: 100%;
			object-fit: cover;
			object-position: center center;
			opacity: 0.15;
			filter: brightness(0.8) contrast(1.2) blur(1px);
		}
	}

	/* Cinematic story rows */
	.story-section {
		background: linear-gradient(180deg, var(--bg) 0%, #0e0c09 20%, #0e0c09 80%, var(--bg) 100%);
		overflow-x: hidden;
	}

	.story-row {
		display: grid;
		grid-template-columns: 1fr 1fr;
		align-items: center;
		min-height: 55vh;
		border-bottom: 1px solid rgba(255,255,255,0.04);
		max-width: 1600px;
		margin: 0 auto;
		width: 100%;
	}

	.story-row-reverse {
		direction: rtl;
	}

	.story-row-reverse > * {
		direction: ltr;
	}

	.story-image-wrap {
		position: relative;
		width: 100%;
		height: 100%;
		min-height: 55vh;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.story-glow {
		position: absolute;
		inset: 0;
		pointer-events: none;
		z-index: 0;
	}

	.story-glow-1 {
		background: radial-gradient(ellipse 70% 60% at 50% 60%, rgba(232, 118, 59, 0.12) 0%, transparent 65%);
	}
	.story-glow-2 {
		background: radial-gradient(ellipse 70% 60% at 50% 60%, rgba(232, 118, 59, 0.1) 0%, transparent 65%);
	}
	.story-glow-3 {
		background: radial-gradient(ellipse 70% 60% at 50% 60%, rgba(255, 170, 50, 0.15) 0%, transparent 65%);
	}

	.story-image {
		position: relative;
		z-index: 1;
		width: 85%;
		height: auto;
		object-fit: contain;
		transition: transform 0.6s ease;
	}

	.story-image-wrap:hover .story-image {
		transform: scale(1.04);
	}

	.story-text {
		padding: 3rem 5% 3rem 6%;
	}

	.story-row-reverse .story-text {
		padding: 3rem 6% 3rem 5%;
	}

	.story-num {
		display: block;
		font-size: 5rem;
		font-weight: 900;
		line-height: 1;
		margin-bottom: 0.5rem;
		background: linear-gradient(135deg, var(--primary) 0%, var(--accent-amber) 100%);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
		opacity: 0.35;
		font-variant-numeric: tabular-nums;
	}

	.story-title {
		font-size: clamp(2.5rem, 3.5vw, 4rem);
		font-weight: 800;
		line-height: 1.1;
		color: var(--text);
		margin-bottom: 1rem;
	}

	.story-desc {
		font-size: 1.15rem;
		line-height: 1.7;
		color: var(--text-muted);
		margin-bottom: 2rem;
		max-width: 420px;
	}

	.story-chips {
		display: flex;
		flex-wrap: wrap;
		gap: 0.6rem;
	}

	.story-chip {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		padding: 0.4rem 0.9rem;
		border-radius: 16px;
		border: 1px solid rgba(232, 118, 59, 0.3);
		background: rgba(232, 118, 59, 0.06);
		font-size: 0.85rem;
		color: var(--text-muted);
	}

	:global(.story-chip svg) {
		color: var(--primary);
		flex-shrink: 0;
	}

	@media (max-width: 968px) {
		.story-row,
		.story-row-reverse {
			grid-template-columns: 1fr;
			direction: ltr;
			min-height: auto;
		}

		.story-image-wrap {
			min-height: 72vw;
			padding-top: 2.5rem;
			overflow: visible;
		}

		.story-image {
			width: 115%;
			max-width: none;
		}

		.story-text,
		.story-row-reverse .story-text {
			padding: 1.5rem 1.5rem 3rem;
		}

		.story-num {
			font-size: 3.5rem;
		}

		.story-title {
			font-size: 2rem;
		}

		.story-desc {
			font-size: 1rem;
		}
	}

	.cta-section {
		padding: 2rem 0 6rem;
	}
</style>
