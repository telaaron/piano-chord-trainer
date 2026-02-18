<script lang="ts">
	import {
		ArrowRight,
		CheckCircle,
		Play,
		Keyboard,
		BarChart3,
		Zap,
		Mail,
		Monitor,
		Layers,
		Bookmark,
		User,
	} from 'lucide-svelte';
</script>

<svelte:head>
	<title>Chord Trainer for Open Studio — Jazz Voicing Practice, Embedded</title>
	<meta name="description" content="A dedicated chord voicing speed-drill trainer built for Open Studio Jazz. White-label integration, MIDI recognition, progress tracking — inside your platform." />
	<link rel="canonical" href="https://jazzchords.app/open-studio" />
	<meta property="og:title" content="Chord Trainer for Open Studio" />
	<meta property="og:description" content="Jazz voicing speed-drill trainer built for the Open Studio learning environment. MIDI, progress tracking, white-label." />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://jazzchords.app/open-studio" />
</svelte:head>

<main class="flex-1" style="background: linear-gradient(180deg, var(--bg) 0%, #110e0a 30%, #0d0b08 60%, var(--bg) 100%);">
	<!-- Hero -->
	<section class="max-w-4xl mx-auto px-4 py-20 sm:py-28 text-center">
		<div class="inline-flex items-center gap-2 px-4 py-1.5 mb-8 rounded-full border border-[var(--border)] bg-[var(--bg-card)] text-xs text-[var(--text-muted)] tracking-wide uppercase">
			Built for Open Studio
		</div>

		<h1 class="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight leading-[1.08] mb-6">
			<span class="text-gradient">From Concept to Muscle Memory</span><br />
			<span class="text-[var(--text-muted)] text-2xl sm:text-3xl lg:text-4xl font-medium mt-2 block">The practice tool your lessons are missing.</span>
		</h1>

		<p class="text-lg sm:text-xl text-[var(--text-muted)] max-w-2xl mx-auto leading-relaxed mb-10">
			Adam explains <em>"The Family"</em>. The student clicks <strong class="text-[var(--text)]">Practice</strong> and drills those voicings through all 12 keys — with MIDI validation, a timer, and weakness analysis. Right inside Open Studio.
		</p>

		<div class="flex flex-col sm:flex-row items-center justify-center gap-4">
			<a
				href="/train"
				class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white font-bold transition-colors"
			>
				Try the Live Demo
				<Play size={18} />
			</a>
			<a
				href="mailto:info@jazzchords.app?subject=Open%20Studio%20Integration"
				class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] border border-[var(--border)] hover:border-[var(--border-hover)] text-[var(--text-muted)] hover:text-[var(--text)] font-medium transition-colors"
			>
				<Mail size={18} />
				Schedule a Demo
			</a>
		</div>
	</section>

	<!-- The Pitch -->
	<section class="px-4 py-16 sm:py-20">
		<div class="max-w-4xl mx-auto">
			<div class="card p-8 sm:p-10 border-[var(--accent-amber)]/20">
				<h2 class="text-xl font-bold mb-4 text-[var(--accent-amber)]">The Gap</h2>
				<p class="text-[var(--text-muted)] leading-relaxed text-lg">
					Open Studio has the best jazz piano instruction online. Peter &amp; Adam teach voicing concepts beautifully. But after the lesson ends, there's <strong class="text-[var(--text)]">no tool to drill what was just learned</strong>. Students understand the theory — they just can't play it fluently in all 12 keys yet.
				</p>
				<p class="text-[var(--text-muted)] leading-relaxed text-lg mt-4">
					That's the difference between <em>knowing</em> a voicing and <em>owning</em> it. <strong class="text-[var(--text)]">Chord Trainer closes that gap.</strong>
				</p>
			</div>
		</div>
	</section>

	<!-- How It Works Inside OS -->
	<section class="px-4 py-16 sm:py-20">
		<div class="max-w-4xl mx-auto">
			<h2 class="text-2xl sm:text-3xl font-bold mb-4 text-center">How It Works Inside Open Studio</h2>
			<p class="text-center text-[var(--text-muted)] mb-12 max-w-2xl mx-auto">
				Students never leave your platform. The trainer appears as a tab within each lesson.
			</p>

			<div class="grid grid-cols-1 sm:grid-cols-3 gap-6 mb-16">
				<div class="card p-6 text-center">
					<div class="w-12 h-12 rounded-xl bg-[var(--primary-muted)] flex items-center justify-center mx-auto mb-4">
						<Monitor size={24} class="text-[var(--primary)]" />
					</div>
					<h3 class="font-bold mb-2">1. Watch the Lesson</h3>
					<p class="text-sm text-[var(--text-muted)]">
						Student watches Adam teach shell voicings, rootless concepts, or any chord topic.
					</p>
				</div>

				<div class="card p-6 text-center">
					<div class="w-12 h-12 rounded-xl bg-[var(--primary-muted)] flex items-center justify-center mx-auto mb-4">
						<Keyboard size={24} class="text-[var(--primary)]" />
					</div>
					<h3 class="font-bold mb-2">2. Click "Practice"</h3>
					<p class="text-sm text-[var(--text-muted)]">
						A new tab opens with the trainer pre-loaded for exactly those voicings. One click to start drilling.
					</p>
				</div>

				<div class="card p-6 text-center">
					<div class="w-12 h-12 rounded-xl bg-[var(--primary-muted)] flex items-center justify-center mx-auto mb-4">
						<BarChart3 size={24} class="text-[var(--primary)]" />
					</div>
					<h3 class="font-bold mb-2">3. Track Progress</h3>
					<p class="text-sm text-[var(--text-muted)]">
						MIDI validates every chord. Weakness analysis shows which keys need work. Speed improves session by session.
					</p>
				</div>
			</div>
		</div>
	</section>

	<!-- Platform Mock — Accurate Open Studio UI -->
	<section class="px-4 py-16 sm:py-20">
		<div class="max-w-5xl mx-auto">
			<h2 class="text-2xl sm:text-3xl font-bold mb-4 text-center">Inside Your Platform</h2>
			<p class="text-center text-[var(--text-muted)] mb-10 max-w-2xl mx-auto">
				A new <strong class="text-[var(--text)]">"Practice"</strong> tab — right next to Overview, Materials, and Shortcuts.
			</p>

			<div class="os-mock">
				<!-- Browser Chrome -->
				<div class="os-browser-bar">
					<div class="os-dots"><span></span><span></span><span></span></div>
					<div class="os-url-bar">
						<span class="os-lock">🔒</span>
						app.openstudiojazz.com
					</div>
				</div>

				<!-- OS Top Nav -->
				<div class="os-topnav">
					<img src="/mock-content/open-studio-logo.png" alt="Open Studio" class="os-logo-img" />
					<div class="os-nav-links">
						<span class="os-nav-link">
							<span class="os-nav-icon">◎</span> Courses
						</span>
						<span class="os-nav-link">
							<span class="os-nav-icon">⦿</span> Live Sessions
						</span>
						<span class="os-nav-link">
							<span class="os-nav-icon">👥</span> The Hang
						</span>
					</div>
					<div class="os-nav-right">
						<Bookmark size={18} class="text-[#999]" />
						<User size={18} class="text-[#999]" />
					</div>
				</div>

				<!-- OS Content Area -->
				<div class="os-content">
					<!-- Breadcrumb -->
					<div class="os-breadcrumb">
						<span>← Harmony Games Unlimited</span>
						<span class="os-chapters">☰ View Chapters</span>
					</div>

					<!-- Video Thumbnail -->
					<div class="os-video">
						<img src="/mock-content/thumbnail.png" alt="ii-V-I Progression — Jazz fundamentals drill" class="os-video-img" />
						<!-- Video Controls Bar -->
						<div class="os-video-controls">
							<div class="os-play-btn">▶</div>
							<div class="os-video-info">
								<span class="os-video-title">ii-V-I Progression · Speed Drill</span>
								<span class="os-video-time">0:00 / 14:18</span>
							</div>
							<div class="os-video-right">
								<span>100%</span>
								<span>⊖ ⊕</span>
								<span>↻ Loop</span>
							</div>
						</div>
					</div>

					<!-- Tabs — with our new "Practice" tab -->
					<div class="os-tabs">
						<span class="os-tab">Overview</span>
						<span class="os-tab">Materials</span>
						<span class="os-tab">Shortcuts</span>
						<span class="os-tab os-tab-active">Practice ✨</span>
					</div>

					<!-- Chord Trainer Embedded -->
					<div class="os-trainer-embed">
						<div class="os-trainer-badge">Chord Trainer · Embedded</div>

						<div class="os-trainer-top">
							<span class="os-trainer-status">🎹 MIDI Connected</span>
							<span class="os-trainer-meta">ii-V-I Progression · All Keys</span>
							<span class="os-trainer-timer">1:47</span>
						</div>

						<div class="os-trainer-chord">
							<div class="os-chord-name">Dm7</div>
							<div class="os-chord-type">Shell Voicing (D – F – C)</div>
						</div>

						<!-- Piano Keys -->
						<div class="os-piano">
							{#each Array(15) as _, i}
								{@const isBlack = [1, 3, 6, 8, 10, 13].includes(i)}
								{@const isActive = [2, 5, 12].includes(i)}
								<div
									class="os-key"
									class:os-key-black={isBlack}
									class:os-key-white={!isBlack}
									class:os-key-active={isActive}
								></div>
							{/each}
						</div>

						<div class="os-trainer-footer">
							<span>Chord 8 / 20</span>
							<div class="os-progress-track">
								<div class="os-progress-bar" style="width: 40%"></div>
							</div>
							<span class="os-trainer-accuracy">Accuracy: 94%</span>
						</div>
					</div>

				</div>
			</div>
		</div>

		<!-- Benefits as annotation OUTSIDE the mock -->
		<div class="max-w-5xl mx-auto">
			<div class="os-embed-benefits">
				<div class="os-benefit-item">
					<CheckCircle size={20} class="text-[#00a86b]" />
					<span>Students never leave Open Studio</span>
				</div>
				<div class="os-benefit-item">
					<CheckCircle size={20} class="text-[#00a86b]" />
					<span>Pre-loaded with the lesson's voicings</span>
				</div>
				<div class="os-benefit-item">
					<CheckCircle size={20} class="text-[#00a86b]" />
					<span>White-label — matches your design system</span>
				</div>
			</div>
		</div>
	</section>

	<!-- What The Trainer Covers -->
	<section class="px-4 py-16 sm:py-20">
		<div class="max-w-4xl mx-auto">
			<h2 class="text-2xl sm:text-3xl font-bold mb-4 text-center">What Students Can Practice</h2>
			<p class="text-center text-[var(--text-muted)] mb-10">Every concept Adam &amp; Peter teach has a matching drill.</p>

			<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
				{#each [
					{ title: 'Shell Voicings (3-7)', desc: '"The bread and butter" — drill through all 12 keys' },
					{ title: 'Rootless A (Bill Evans)', desc: '3-5-7-9 voicings, the classic left-hand sound' },
					{ title: 'Rootless B', desc: '7-9-3-5, the complement to A voicings' },
					{ title: 'ii-V-I Progressions', desc: 'The most common jazz cadence, all 12 keys' },
					{ title: 'I-vi-ii-V Turnarounds', desc: 'Full rhythm changes turnaround' },
					{ title: 'Custom Progressions', desc: 'Autumn Leaves, All The Things, any standard' },
					{ title: 'Inversions (1st – 3rd)', desc: 'Drop-2, spread voicings, all positions' },
					{ title: '16 Chord Qualities', desc: 'Maj7, m7, dom7, m7b5, dim7, alt, sus, and more' },
				] as item}
					<div class="card p-5 flex items-start gap-3">
						<CheckCircle size={18} class="text-[var(--primary)] flex-shrink-0 mt-0.5" />
						<div>
							<h3 class="font-semibold text-sm">{item.title}</h3>
							<p class="text-xs text-[var(--text-muted)] mt-0.5">{item.desc}</p>
						</div>
					</div>
				{/each}
			</div>
		</div>
	</section>

	<!-- Integration Options -->
	<section class="px-4 py-16 sm:py-20">
		<div class="max-w-4xl mx-auto">
			<h2 class="text-2xl sm:text-3xl font-bold mb-10 text-center">Integration Options</h2>

			<div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
				<div class="card p-6 border-[var(--primary)]/30 relative overflow-hidden">
					<div class="absolute top-3 right-3 text-[0.65rem] uppercase tracking-wider text-[var(--primary)] bg-[var(--primary-muted)] px-2 py-0.5 rounded-full font-semibold">Recommended</div>
					<Layers size={24} class="text-[var(--primary)] mb-3" />
					<h3 class="font-bold mb-2">Lesson Tab</h3>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						New "Practice" tab within each lesson. Context-specific: the lesson's voicings are pre-loaded. Zero friction for students.
					</p>
					<p class="text-xs text-[var(--text-dim)] mt-3 font-mono">iframe with URL params</p>
				</div>

				<div class="card p-6">
					<Monitor size={24} class="text-[var(--primary)] mb-3" />
					<h3 class="font-bold mb-2">Standalone Section</h3>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						Dedicated "Practice Tools" area in your navigation. For free practice, not tied to any specific lesson. Scalable to future tools.
					</p>
					<p class="text-xs text-[var(--text-dim)] mt-3 font-mono">Subdomain or embedded route</p>
				</div>

				<div class="card p-6">
					<Zap size={24} class="text-[var(--primary)] mb-3" />
					<h3 class="font-bold mb-2">Post-Video Challenge</h3>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						CTA after the video: "Ready to practice? Test in all 12 keys!" Highest conversion — motivation peaks right after learning.
					</p>
					<p class="text-xs text-[var(--text-dim)] mt-3 font-mono">Overlay / modal trigger</p>
				</div>

				<div class="card p-6">
					<Play size={24} class="text-[var(--primary)] mb-3" />
					<h3 class="font-bold mb-2">Materials Enhancement</h3>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						Alongside PDFs in the Materials tab: "🎹 Practice this voicing interactively." Lowest integration effort.
					</p>
					<p class="text-xs text-[var(--text-dim)] mt-3 font-mono">Link with preset params</p>
				</div>
			</div>
		</div>
	</section>

	<!-- Harmony Games vs Chord Trainer -->
	<section class="px-4 py-16 sm:py-20">
		<div class="max-w-4xl mx-auto">
			<div class="card p-8 sm:p-10">
				<h2 class="text-xl font-bold mb-6">Harmony Games Unlimited shows concepts.<br /><span class="text-gradient">Chord Trainer makes them muscle memory.</span></h2>

				<div class="grid grid-cols-1 sm:grid-cols-2 gap-6 text-sm">
					<div>
						<h3 class="font-semibold text-[var(--text-muted)] mb-3 uppercase tracking-wider text-xs">Harmony Games</h3>
						<ul class="space-y-2 text-[var(--text-muted)]">
							<li>✓ Quiz-based (identify chords)</li>
							<li>✓ Great for ear training</li>
							<li>✓ Theory recognition</li>
						</ul>
					</div>
					<div>
						<h3 class="font-semibold text-[var(--primary)] mb-3 uppercase tracking-wider text-xs">Chord Trainer</h3>
						<ul class="space-y-2 text-[var(--text)]">
							<li>✓ Performance-based (play the voicings)</li>
							<li>✓ MIDI validates actual playing</li>
							<li>✓ Speed drill through all 12 keys</li>
							<li>✓ Weakness analysis per chord root</li>
							<li>✓ Custom progressions (standards)</li>
						</ul>
					</div>
				</div>

				<p class="text-[var(--text-muted)] mt-6 text-sm leading-relaxed">
					They're complementary: Harmony Games trains the <em>ear</em>, Chord Trainer trains the <em>hands</em>. Together, they cover the full learning loop.
				</p>
			</div>
		</div>
	</section>

	<!-- Terms -->
	<section class="px-4 py-16 sm:py-20">
		<div class="max-w-4xl mx-auto">
			<h2 class="text-2xl sm:text-3xl font-bold mb-10 text-center">Simple Terms</h2>

			<div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
				<div class="card p-6 text-center">
					<div class="text-3xl font-bold text-[var(--primary)] mb-2">30 Days</div>
					<div class="text-sm font-medium mb-2">Free Trial</div>
					<p class="text-xs text-[var(--text-muted)]">Full functionality. MIDI, progress, all voicings. Zero risk.</p>
				</div>

				<div class="card p-6 text-center border-[var(--primary)]/30">
					<div class="text-3xl font-bold text-[var(--primary)] mb-2">Flat Fee</div>
					<div class="text-sm font-medium mb-2">Monthly License</div>
					<p class="text-xs text-[var(--text-muted)]">Predictable cost. No per-user fees. Scales with your growth.</p>
				</div>

				<div class="card p-6 text-center">
					<div class="text-3xl font-bold text-[var(--primary)] mb-2">White-Label</div>
					<div class="text-sm font-medium mb-2">Your Branding</div>
					<p class="text-xs text-[var(--text-muted)]">Open Studio colors, logo, domain. Students never know it's external.</p>
				</div>
			</div>
		</div>
	</section>

	<!-- CTA -->
	<section class="px-4 py-20 sm:py-28">
		<div class="max-w-3xl mx-auto text-center">
			<div class="card p-10 sm:p-14 border-[var(--primary)]/20">
				<h2 class="text-2xl sm:text-3xl font-bold mb-4">Let's Build This Together</h2>
				<p class="text-[var(--text-muted)] mb-8 max-w-lg mx-auto leading-relaxed">
					15-minute demo. I'll show you the trainer running with Open Studio branding, walk through the integration options, and answer any questions.
				</p>

				<div class="flex flex-col sm:flex-row items-center justify-center gap-4">
					<a
						href="mailto:info@jazzchords.app?subject=Open%20Studio%20x%20Chord%20Trainer%20Demo"
						class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white font-bold transition-colors"
					>
						<Mail size={18} />
						Schedule a Demo
					</a>
					<a
						href="/train"
						class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] border border-[var(--border)] hover:border-[var(--border-hover)] text-[var(--text-muted)] hover:text-[var(--text)] font-medium transition-colors"
					>
						Try the Live Trainer
						<ArrowRight size={18} />
					</a>
				</div>

				<p class="text-xs text-[var(--text-dim)] mt-6">
					Aaron Pfutzner · Aaron Technologies OÜ · info@jazzchords.app
				</p>
			</div>
		</div>
	</section>
</main>

<style>
	/* ── Open Studio Mock ─────────────────────────────── */
	/* Matches the real app.openstudiojazz.com UI exactly */

	.os-mock {
		border-radius: 12px;
		overflow: hidden;
		box-shadow: 0 25px 80px rgba(0, 0, 0, 0.6);
		border: 1px solid rgba(109, 76, 65, 0.3);
	}

	/* Browser chrome */
	.os-browser-bar {
		background: #2b2b2b;
		padding: 0.6rem 0.75rem;
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.os-dots {
		display: flex;
		gap: 0.35rem;
	}

	.os-dots span {
		width: 11px;
		height: 11px;
		border-radius: 50%;
	}

	.os-dots span:nth-child(1) { background: #ff5f57; }
	.os-dots span:nth-child(2) { background: #ffbd2e; }
	.os-dots span:nth-child(3) { background: #28c840; }

	.os-url-bar {
		flex: 1;
		background: #3a3a3a;
		padding: 0.35rem 0.75rem;
		border-radius: 6px;
		font-size: 0.8rem;
		color: #ccc;
		display: flex;
		align-items: center;
		gap: 0.4rem;
	}

	.os-lock {
		font-size: 0.65rem;
	}

	/* OS Top Navigation — white bar, dark text */
	.os-topnav {
		background: #0D0D0D;
		padding: 0.75rem 1.5rem;
		display: flex;
		align-items: center;
		justify-content: space-between;
		border-bottom: 1px solid #e5e5e5;
	}


	.os-nav-links {
		display: flex;
		gap: 1.5rem;
	}

	.os-nav-link {
		font-size: 0.8rem;
		color: #555;
		display: flex;
		align-items: center;
		gap: 0.3rem;
		cursor: default;
	}

	.os-nav-icon {
		font-size: 0.7rem;
	}

	.os-nav-right {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.os-logo-img {
		height: 24px;
	}

	/* OS Content — white background */
	.os-content {
		background: #ffffff;
		padding: 0 0 1.5rem 0;
	}

	.os-breadcrumb {
		padding: 0.75rem 1.5rem;
		display: flex;
		justify-content: space-between;
		align-items: center;
		font-size: 0.85rem;
		color: #333;
	}

	.os-chapters {
		font-size: 0.8rem;
		color: #555;
		border: 1px solid #ddd;
		padding: 0.35rem 0.75rem;
		border-radius: 6px;
		cursor: default;
	}

	/* Video area — real thumbnail */
	.os-video {
		margin: 0 1.5rem;
		border-radius: 8px;
		overflow: hidden;
		position: relative;
		background: #000;
	}

	.os-video-img {
		width: 100%;
		height: auto;
		display: block;
	}

	.os-video-controls {
		background: rgba(0, 0, 0, 0.85);
		padding: 0.5rem 0.75rem;
		display: flex;
		align-items: center;
		gap: 0.75rem;
		font-size: 0.75rem;
		color: #ccc;
	}

	.os-play-btn {
		width: 28px;
		height: 28px;
		background: #4da6ff;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		color: white;
		font-size: 0.65rem;
		flex-shrink: 0;
	}

	.os-video-info {
		display: flex;
		flex-direction: column;
		gap: 0.1rem;
		flex: 1;
	}

	.os-video-title {
		font-weight: 600;
		color: #fff;
		font-size: 0.8rem;
	}

	.os-video-time {
		font-size: 0.7rem;
		color: #999;
	}

	.os-video-right {
		display: flex;
		gap: 0.75rem;
		font-size: 0.7rem;
		color: #999;
	}

	/* Tabs — matching OS tab style */
	.os-tabs {
		display: flex;
		gap: 0;
		border-bottom: 1px solid #e5e5e5;
		padding: 0 1.5rem;
		margin-top: 1.5rem;
	}

	.os-tab {
		padding: 0.75rem 1rem;
		font-size: 0.85rem;
		color: #888;
		border-bottom: 2px solid transparent;
		cursor: default;
	}

	.os-tab-active {
		color: #1a1a1a;
		border-bottom-color: #1a1a1a;
		font-weight: 600;
	}

	/* Embedded Chord Trainer inside OS */
	.os-trainer-embed {
		margin: 1.5rem;
		background: #f8f8f8;
		border: 2px solid #004E89;
		border-radius: 12px;
		padding: 1.5rem;
		position: relative;
	}

	.os-trainer-badge {
		position: absolute;
		top: -0.6rem;
		left: 1.25rem;
		background: #004E89;
		color: white;
		font-size: 0.65rem;
		font-weight: 700;
		padding: 0.15rem 0.5rem;
		border-radius: 4px;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.os-trainer-top {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1.25rem;
		padding-bottom: 0.75rem;
		border-bottom: 1px solid rgba(0, 78, 137, 0.2);
		font-size: 0.8rem;
	}

	.os-trainer-status {
		color: #00a86b;
		font-weight: 600;
	}

	.os-trainer-meta {
		color: #666;
	}

	.os-trainer-timer {
		font-family: var(--font-mono);
		font-size: 1.25rem;
		font-weight: 700;
		color: #004E89;
	}

	.os-trainer-chord {
		text-align: center;
		margin-bottom: 1.25rem;
	}

	.os-chord-name {
		font-size: 2.75rem;
		font-weight: 800;
		color: #004E89;
		line-height: 1;
		margin-bottom: 0.25rem;
	}

	.os-chord-type {
		font-size: 0.9rem;
		color: #333;
	}

	/* Mini piano inside the embed */
	.os-piano {
		display: flex;
		justify-content: center;
		align-items: flex-start;
		height: 90px;
		gap: 1px;
		margin-bottom: 1.25rem;
		padding: 0 1rem;
		position: relative;
	}

	.os-key {
		border-radius: 0 0 4px 4px;
	}

	.os-key-white {
		width: 34px;
		height: 90px;
		background: #f5f3ee;
		border: 1px solid #c8c4ba;
	}

	.os-key-black {
		width: 22px;
		height: 58px;
		background: #1a1410;
		border: 1px solid #3e2723;
		margin: 0 -12px;
		z-index: 2;
		position: relative;
	}

	.os-key-active.os-key-white {
		background: var(--accent-gold) !important;
		box-shadow: 0 0 14px var(--accent-gold);
	}

	.os-key-active.os-key-black {
		background: var(--accent-amber) !important;
		box-shadow: 0 0 10px var(--accent-amber);
	}

	.os-trainer-footer {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		font-size: 0.8rem;
		color: var(--text-muted);
	}

	.os-progress-track {
		flex: 1;
		height: 5px;
		background: rgba(109, 76, 65, 0.2);
		border-radius: 3px;
		overflow: hidden;
	}

	.os-progress-bar {
		height: 100%;
		background: linear-gradient(90deg, var(--primary), var(--accent-amber));
		border-radius: 3px;
	}

	.os-trainer-accuracy {
		color: var(--accent-green);
		font-weight: 600;
	}

	/* Benefits as annotation outside mock */
	.os-embed-benefits {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1.5rem;
		background: rgba(232, 118, 59, 0.05);
		padding: 2.5rem 1.5rem;
		margin-top: 1.5rem;
		border-radius: 8px;
	}

	.os-benefit-item {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		font-size: 0.9rem;
		color: var(--text);
		font-weight: 500;
	}

	/* ── Mobile ───────────────────────────────────────── */
	@media (max-width: 768px) {
		.os-nav-links {
			display: none;
		}

		.os-nav-right {
			display: none;
		}

		.os-piano {
			padding: 0;
		}

		.os-key-white {
			width: 26px;
		}

		.os-key-black {
			width: 16px;
			margin: 0 -9px;
		}

		.os-video-right {
			display: none;
		}

		.os-embed-benefits {
			grid-template-columns: 1fr;
		}
	}
</style>
