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
		isMobile = window.matchMedia('(max-width: 968px)').matches;
		const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

		// Static fallback for reduced motion preference
		if (prefersReducedMotion) {
			useStaticFallback = true;
		}

		// On mobile: show first frame only, no scroll animation
		if (isMobile) {
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
			scrollProgress = Math.min(scrollPercent * 0.5, 1);
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
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="Chord Trainer – Jazz Piano Voicing Speed Training" />
	<meta name="twitter:description" content="Master jazz piano voicings in all 12 keys. MIDI recognition, ii-V-I progressions, progress tracking." />
</svelte:head>

<!-- Hero with Scroll-Controlled 3D Piano -->
<section class="hero">
	<div class="hero-content">
		<!-- Badge -->
		<div class="badge">
			<span class="dot"></span>
			MIDI · Audio · Progress Tracking
		</div>

		<!-- Titles -->
		<h1>
			<span class="gradient-text">Master Jazz Piano</span>
			<span class="white-text">Voicings in All 12 Keys</span>
		</h1>

		<p class="subtitle">
			Speed training that builds muscle memory. See a chord, play it, get faster.
			Shell voicings, rootless, ii-V-I — through every key.
		</p>

		<!-- CTAs -->
		<div class="cta-buttons">
			<a href="/train" class="btn btn-primary">
				Start Training
				<span class="arrow">→</span>
			</a>
			<a href="/for-educators" class="btn btn-secondary">
				For Music Schools
			</a>
		</div>

		<p class="footnote">Free. No signup. Works in Chrome &amp; Edge.</p>
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
			<source src="/videos/piano-rotation-3.webm" type="video/webm" />
		</video>
	</div>
</section>

<!-- What's inside -->
<section class="features-section">
	<div class="max-w-4xl mx-auto px-4">
		<h2 class="text-2xl sm:text-3xl font-bold text-center mb-10 text-[var(--text)]">Plug in. Play. Get faster.</h2>

		<div class="grid grid-cols-2 sm:grid-cols-3 gap-4 text-center">
			<div class="card p-5 card-hover">
				<Piano size={24} class="mx-auto mb-2 text-[var(--primary)]" />
				<p class="font-semibold text-sm">MIDI auto-detect</p>
			</div>
			<div class="card p-5 card-hover">
				<Target size={24} class="mx-auto mb-2 text-[var(--accent-amber)]" />
				<p class="font-semibold text-sm">ii-V-I all 12 keys</p>
			</div>
			<div class="card p-5 card-hover">
				<Keyboard size={24} class="mx-auto mb-2 text-[var(--accent-gold)]" />
				<p class="font-semibold text-sm">4+ voicing types</p>
			</div>
			<div class="card p-5 card-hover">
				<Volume2 size={24} class="mx-auto mb-2 text-[var(--primary)]" />
				<p class="font-semibold text-sm">Audio &amp; metronome</p>
			</div>
			<div class="card p-5 card-hover">
				<BarChart3 size={24} class="mx-auto mb-2 text-[var(--accent-amber)]" />
				<p class="font-semibold text-sm">Weakness tracking</p>
			</div>
			<div class="card p-5 card-hover">
				<BookOpen size={24} class="mx-auto mb-2 text-[var(--accent-gold)]" />
				<p class="font-semibold text-sm">Practice plans</p>
			</div>
		</div>

		<!-- How it works — inline -->
		<div class="flex flex-col sm:flex-row items-center justify-center gap-4 text-center text-[var(--text-muted)] mt-12">
			<span class="inline-flex items-center gap-2"><span class="w-7 h-7 rounded-full bg-[var(--primary)] text-white text-xs font-bold flex items-center justify-center">1</span> Pick a drill</span>
			<span class="hidden sm:inline text-[var(--text-dim)]">→</span>
			<span class="inline-flex items-center gap-2"><span class="w-7 h-7 rounded-full bg-[var(--primary)] text-white text-xs font-bold flex items-center justify-center">2</span> Play the chords</span>
			<span class="hidden sm:inline text-[var(--text-dim)]">→</span>
			<span class="inline-flex items-center gap-2"><span class="w-7 h-7 rounded-full bg-[var(--primary)] text-white text-xs font-bold flex items-center justify-center">3</span> See your progress</span>
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
		min-height: 90vh;
		display: grid;
		grid-template-columns: 1fr 1fr;
		align-items: center;
		gap: 4rem;
		padding: 4rem 5%;
		background: linear-gradient(135deg, #0a0908 0%, #1a1410 30%, #3e2723 50%, #1a1410 70%, #0a0908 100%);
		overflow: hidden;
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

	/* Piano Video */
	.piano-container {
		position: relative;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 2rem;
		overflow: hidden;
	}

	.piano-container::before {
		content: '';
		position: absolute;
		inset: 0;
		background: radial-gradient(
			ellipse 50% 50% at 50% 50%,
			var(--glow-warm) 0%,
			transparent 70%
		);
		opacity: 0.6;
		pointer-events: none;
		z-index: 0;
	}

	.piano-video {
		position: relative;
		z-index: 1;
		max-width: 1200px;
		height: 500px;
		object-fit: fill;
		/* Shift video left so right 8% (watermark) is pushed out of the overflow:hidden container */
		object-position: 60% center;

		/* Make black background transparent */
		mix-blend-mode: screen;
		
		filter: brightness(1.1) contrast(1.1);
	}

	/* Mobile: video becomes subtle background behind hero */
	@media (max-width: 968px) {
		.hero {
			grid-template-columns: 1fr;
			text-align: center;
			padding: 3rem 5%;
			position: relative;
		}

		.hero-content {
			order: 1;
			position: relative;
			z-index: 2;
		}

		.piano-container {
			/* Absolute position behind content */
			position: absolute;
			inset: 0;
			padding: 0;
			display: flex;
			align-items: center;
			justify-content: center;
			pointer-events: none;
			z-index: 0;
		}

		.piano-container::before {
			display: none;
		}

		.piano-video {
			width: 100%;
			height: 100%;
			max-width: none;
			object-fit: cover;
			object-position: center 30%;
			clip-path: none;
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

	/* Sections below hero */
	.features-section {
		padding: 5rem 0;
		background: linear-gradient(180deg, var(--bg) 0%, #12100c 40%, #12100c 60%, var(--bg) 100%);
	}

	.cta-section {
		padding: 2rem 0 6rem;
	}
</style>
