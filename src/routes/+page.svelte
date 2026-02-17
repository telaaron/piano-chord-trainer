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

	onMount(() => {
		let rafId: number;

		const handleScroll = () => {
			if (rafId) cancelAnimationFrame(rafId);
			
			rafId = requestAnimationFrame(() => {
				const scrollTop = window.scrollY;
				const docHeight = document.documentElement.scrollHeight - window.innerHeight;
				const scrollPercent = scrollTop / docHeight;

				// Map scroll to video time (first 50% of scroll)
				scrollProgress = Math.min(scrollPercent * 2, 1);

				if (videoElement && videoElement.duration) {
					videoElement.currentTime = videoElement.duration * scrollProgress;
				}
			});
		};

		window.addEventListener('scroll', handleScroll);

		// Preload video
		if (videoElement) {
			videoElement.load();
		}

		return () => {
			window.removeEventListener('scroll', handleScroll);
			if (rafId) cancelAnimationFrame(rafId);
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

<!-- Features -->
<section class="px-4 py-20">
	<div class="max-w-5xl mx-auto">
		<div class="text-center mb-12">
			<h2 class="text-2xl sm:text-3xl font-bold">Everything you need</h2>
		</div>

		<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
			<!-- MIDI -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--primary-muted)] flex items-center justify-center mb-4">
					<Piano size={20} class="text-[var(--primary)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">MIDI Recognition</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					Auto-detects when you nail the chord. No typing, no clicking.
				</p>
			</div>

			<!-- Progressions -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--accent-purple)]/15 flex items-center justify-center mb-4">
					<Target size={20} class="text-[var(--accent-purple)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">ii-V-I in All Keys</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					The most important progression, drilled through all 12 keys.
				</p>
			</div>

			<!-- Voicings -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--accent-green)]/15 flex items-center justify-center mb-4">
					<Keyboard size={20} class="text-[var(--accent-green)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">4+ Voicing Types</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					Shell, rootless A, inversions—shown on a visual keyboard.
				</p>
			</div>

			<!-- Audio -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--accent-amber)]/15 flex items-center justify-center mb-4">
					<Volume2 size={20} class="text-[var(--accent-amber)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">Audio &amp; Metronome</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					Hear every chord. Built-in metronome with BPM control.
				</p>
			</div>

			<!-- Progress -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--accent-red)]/15 flex items-center justify-center mb-4">
					<BarChart3 size={20} class="text-[var(--accent-red)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">Weakness Analysis</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					Tracks time per chord. Shows your slowest keys.
				</p>
			</div>

			<!-- Plans -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--primary-muted)] flex items-center justify-center mb-4">
					<BookOpen size={20} class="text-[var(--primary)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">Practice Plans</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					One-tap presets: Warm-Up, Speed Run, Challenge.
				</p>
			</div>
		</div>
	</div>
</section>

<!-- How it works -->
<section class="px-4 pb-20">
	<div class="max-w-3xl mx-auto">
		<div class="text-center mb-12">
			<h2 class="text-2xl sm:text-3xl font-bold">How it works</h2>
		</div>

		<div class="space-y-6">
			<div class="flex items-start gap-4">
				<div class="flex-shrink-0 w-10 h-10 rounded-full bg-[var(--primary)] flex items-center justify-center text-white font-bold text-sm">1</div>
				<div>
					<h3 class="font-semibold text-lg">Choose your drill</h3>
					<p class="text-[var(--text-muted)] mt-1">Pick a practice plan or customize.</p>
				</div>
			</div>
			<div class="flex items-start gap-4">
				<div class="flex-shrink-0 w-10 h-10 rounded-full bg-[var(--primary)] flex items-center justify-center text-white font-bold text-sm">2</div>
				<div>
					<h3 class="font-semibold text-lg">Play each chord</h3>
					<p class="text-[var(--text-muted)] mt-1">MIDI auto-advances, or press Space.</p>
				</div>
			</div>
			<div class="flex items-start gap-4">
				<div class="flex-shrink-0 w-10 h-10 rounded-full bg-[var(--primary)] flex items-center justify-center text-white font-bold text-sm">3</div>
				<div>
					<h3 class="font-semibold text-lg">Review &amp; improve</h3>
					<p class="text-[var(--text-muted)] mt-1">See results, track progress, build streaks.</p>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- Bottom CTA -->
<section class="px-4 pb-24">
	<div class="max-w-2xl mx-auto text-center">
		<div class="card p-10 sm:p-14 border-[var(--primary)]/20">
			<h2 class="text-2xl sm:text-3xl font-bold mb-4">Ready to get faster?</h2>
			<p class="text-[var(--text-muted)] mb-8 max-w-md mx-auto">
				No account needed. No install. Just open and play.
			</p>
			<a
				href="/train"
				class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white font-semibold text-lg transition-colors"
			>
				Start Training Now
				<ArrowRight size={20} />
			</a>
		</div>
	</div>
</section>

<style>
	.hero {
		position: relative;
		min-height: 100vh;
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
		width: 130%;
		max-width: 1200px;
		height: 550px;
		object-fit: cover;
		object-position: 60% center;
		
		/* Make black background transparent */
		mix-blend-mode: screen;
		
		/* Enhance brightness */
		filter: 
			brightness(1.1) 
			contrast(1.1);
		
		transition: transform 0.3s ease;
	}

	.piano-video:hover {
		transform: scale(1.02);
	}

	/* Mobile */
	@media (max-width: 968px) {
		.hero {
			grid-template-columns: 1fr;
			text-align: center;
			padding: 3rem 5%;
		}

		.hero-content {
			order: 2;
		}

		.piano-container {
			order: 1;
			margin-bottom: 2rem;
		}

		.piano-video {
			height: auto;
			max-width: 100%;
		}

		.subtitle {
			margin-left: auto;
			margin-right: auto;
		}

		.cta-buttons {
			justify-content: center;
			flex-direction: column;
		}

		.btn {
			width: 100%;
			max-width: 300px;
		}
	}
</style>
