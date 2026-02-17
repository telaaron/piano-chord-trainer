<script lang="ts">
	import {
		ArrowRight,
		CheckCircle,
		Users,
		BarChart3,
		Zap,
		Shield,
		Mail,
	} from 'lucide-svelte';
</script>

<svelte:head>
	<title>Chord Trainer for Music Schools &amp; Jazz Education</title>
	<meta name="description" content="Integrate a professional chord voicing trainer into your jazz education platform. MIDI recognition, progress tracking, white-label ready." />
	<link rel="canonical" href="https://jazzchords.app/for-educators" />
	<meta property="og:title" content="Chord Trainer for Music Schools & Jazz Education" />
	<meta property="og:description" content="Integrate a professional chord voicing trainer into your jazz education platform. MIDI recognition, progress tracking, white-label ready." />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://jazzchords.app/for-educators" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="Chord Trainer for Music Schools & Jazz Education" />
	<meta name="twitter:description" content="Professional chord voicing trainer for jazz education. MIDI recognition, progress tracking, white-label ready." />
</svelte:head>

<main class="flex-1 px-4 py-16 sm:py-24">
	<div class="max-w-4xl mx-auto">
		<!-- Hero -->
		<div class="text-center mb-20">
			<div class="inline-flex items-center gap-2 px-3 py-1 mb-6 rounded-full border border-[var(--border)] bg-[var(--bg-card)] text-xs text-[var(--text-muted)]">
				For Jazz Education Platforms &amp; Music Schools
			</div>

			<h1 class="text-4xl sm:text-5xl font-bold tracking-tight leading-[1.1] mb-6">
				<span class="text-gradient">"Take it through all 12 keys"</span><br />
				<span class="text-[var(--text-muted)] text-3xl sm:text-4xl">Now there's a tool for that.</span>
			</h1>

			<p class="text-lg text-[var(--text-muted)] max-w-2xl mx-auto leading-relaxed">
				Speed-drill training that systematically builds chord voicing fluency.
				MIDI recognition validates technique. Progress tracking shows improvement.
			</p>
		</div>

		<!-- Problem -->
		<section class="mb-20">
			<div class="card p-8 sm:p-10 border-[var(--accent-amber)]/20">
				<h2 class="text-xl font-bold mb-4 text-[var(--accent-amber)]">The Problem</h2>
				<p class="text-[var(--text-muted)] leading-relaxed text-lg">
					Students learn voicing theory but struggle to <strong class="text-[var(--text)]">play changes fluently in all 12 keys</strong>.
					There's no dedicated tool for the repetitive, timed speed-drill practice that builds muscle memory.
				</p>
			</div>
		</section>

		<!-- Solution -->
		<section class="mb-20">
			<h2 class="text-2xl sm:text-3xl font-bold mb-8 text-center">The Solution</h2>

			<div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<Zap size={20} class="text-[var(--primary)]" />
						<h3 class="font-semibold">Speed Training</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						ii-V-I progressions through all 12 keys. Timed per chord for measurable improvement.
					</p>
				</div>

				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<CheckCircle size={20} class="text-[var(--accent-green)]" />
						<h3 class="font-semibold">MIDI Validation</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						Auto-validates chords and advances. Accuracy score per session.
					</p>
				</div>

				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<BarChart3 size={20} class="text-[var(--accent-red)]" />
						<h3 class="font-semibold">Progress Analytics</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						Weakness analysis, improvement trends, practice streaks.
					</p>
				</div>

				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<Users size={20} class="text-[var(--accent-purple)]" />
						<h3 class="font-semibold">Guided Practice</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						One-tap practice plans. Students start instantly.
					</p>
				</div>
			</div>
		</section>

		<!-- What we cover -->
		<section class="mb-20">
			<h2 class="text-2xl sm:text-3xl font-bold mb-8 text-center">What students can train</h2>
			<div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
				{#each [
					'14 chord types (Maj7 to Alt)',
					'Shell voicings (3-7)',
					'Rootless A voicings',
					'Inversions (1st, 2nd, 3rd)',
					'ii-V-I progressions',
					'I-vi-ii-V turnarounds',
					'Circle of fourths',
					'Custom progressions',
					'3 difficulty levels',
					'3 notation systems',
					'Audio playback',
					'Built-in metronome',
				] as item}
					<div class="flex items-center gap-2 text-sm text-[var(--text-muted)]">
						<CheckCircle size={14} class="text-[var(--accent-green)] flex-shrink-0" />
						{item}
					</div>
				{/each}
			</div>
		</section>

		<!-- Integration -->
		<section class="mb-20">
			<h2 class="text-2xl sm:text-3xl font-bold mb-8 text-center">Integration Options</h2>

			<div class="space-y-4">
				<div class="card p-6 flex items-start gap-4">
					<Shield size={24} class="text-[var(--primary)] flex-shrink-0 mt-0.5" />
					<div>
						<h3 class="font-semibold mb-1">White-Label Integration</h3>
						<p class="text-sm text-[var(--text-muted)]">
							Embed directly into your platform with your branding. Custom colors, logo, and domain. Your students never leave your site.
						</p>
					</div>
				</div>

				<div class="card p-6 flex items-start gap-4">
					<Zap size={24} class="text-[var(--accent-green)] flex-shrink-0 mt-0.5" />
					<div>
						<h3 class="font-semibold mb-1">Free 30-Day Trial</h3>
						<p class="text-sm text-[var(--text-muted)]">
							Test with your members at zero risk. Full functionality, MIDI support, progress tracking. See engagement metrics before committing.
						</p>
					</div>
				</div>

				<div class="card p-6 flex items-start gap-4">
					<BarChart3 size={24} class="text-[var(--accent-amber)] flex-shrink-0 mt-0.5" />
					<div>
						<h3 class="font-semibold mb-1">Flexible Licensing</h3>
						<p class="text-sm text-[var(--text-muted)]">
							Flat monthly fee or revenue share. Built-in analytics to track member engagement.
						</p>
					</div>
				</div>
			</div>
		</section>

		<!-- Implementation Example for Open Studio -->
		<section class="mb-20">
			<h2 class="text-2xl sm:text-3xl font-bold mb-8 text-center">How It Looks in Your Platform</h2>
			<p class="text-center text-[var(--text-muted)] mb-8 max-w-2xl mx-auto">
				Example: Seamless integration into the Open Studio learning environment
			</p>

			<div class="implementation-mock">
				<!-- Mock Browser Frame -->
				<div class="browser-frame">
					<div class="browser-header">
						<div class="browser-dots">
							<span></span><span></span><span></span>
						</div>
						<div class="browser-url">openstudio.app/courses/jazz-piano/chord-voicings</div>
					</div>

					<!-- Mock Open Studio Interface -->
					<div class="mock-interface">
						<!-- Left Sidebar (Open Studio Navigation) -->
						<div class="mock-sidebar">
							<div class="sidebar-logo">Open Studio</div>
							<div class="sidebar-nav">
								<div class="nav-item">My Courses</div>
								<div class="nav-item active">Jazz Piano Fundamentals</div>
								<div class="nav-item indent">• Scales &amp; Modes</div>
								<div class="nav-item indent">• Voicing Theory</div>
								<div class="nav-item indent active">• Chord Trainer ✨</div>
								<div class="nav-item indent">• Transcription</div>
								<div class="nav-item">Progress</div>
							</div>
						</div>

						<!-- Main Content (Embedded Chord Trainer) -->
						<div class="mock-main">
							<div class="mock-content-header">
								<h3>Interactive Chord Voicing Trainer</h3>
								<span class="progress-badge">Lesson 5/12</span>
							</div>

							<!-- Embedded Trainer Preview -->
							<div class="trainer-embed">
								<div class="trainer-header">
									<span class="trainer-status">🎹 MIDI Connected</span>
									<span class="trainer-timer">2:34</span>
								</div>
								<div class="trainer-chord">
									<div class="chord-name">Dm7</div>
									<div class="chord-voicing">Shell Voicing (D-F-C)</div>
								</div>
								<div class="trainer-keyboard">
									<div class="piano-keys">
										{#each Array(14) as _, i}
											<div class="key {[1, 3, 6, 8, 10].includes(i) ? 'black' : 'white'} {[2, 5, 11].includes(i) ? 'highlighted' : ''}"></div>
										{/each}
									</div>
								</div>
								<div class="trainer-progress">
									<span>Progress: 8/20 chords</span>
									<div class="progress-bar">
										<div class="progress-fill" style="width: 40%"></div>
									</div>
								</div>
							</div>

							<div class="mock-cta">
								<p>✅ Fully branded with Open Studio colors</p>
								<p>✅ Syncs progress with your course analytics</p>
								<p>✅ Students stay in your learning environment</p>
							</div>
						</div>
					</div>
				</div>
			</div>
		</section>

		<!-- CTA -->
		<section class="text-center">
			<div class="card p-10 sm:p-14 border-[var(--primary)]/20">
				<h2 class="text-2xl sm:text-3xl font-bold mb-4">Let's talk</h2>
				<p class="text-[var(--text-muted)] mb-8 max-w-lg mx-auto">
					See the tool in action. 15-minute demo, no obligations.
					Let's discuss how this fits your platform.
				</p>

				<div class="flex flex-col sm:flex-row items-center justify-center gap-4">
					<a
						href="/train"
						class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white font-semibold transition-colors"
					>
						Try the Live Demo
						<ArrowRight size={18} />
					</a>
					<a
						href="mailto:info@jazzchords.app"
						class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] border border-[var(--border)] hover:border-[var(--border-hover)] text-[var(--text-muted)] hover:text-[var(--text)] font-medium transition-colors"
					>
						<Mail size={18} />
						Get in Touch
					</a>
				</div>
			</div>
		</section>
	</div>
</main>

<style>
	/* Implementation Mock Styles - Open Studio Theme */
	.implementation-mock {
		max-width: 1200px;
		margin: 0 auto;
		
		/* Open Studio Color Overrides */
		--os-bg: #0c1821;
		--os-bg-card: #132030;
		--os-bg-hover: #1a2d42;
		--os-border: #1f3550;
		--os-text: #f2f0eb;
		--os-text-muted: #8a9ab0;
		--os-text-dim: #5a6e85;
		--os-primary: #c9a54e;
		--os-primary-muted: rgba(201, 165, 78, 0.15);
		--os-green: #3fb573;
	}

	.browser-frame {
		border-radius: 12px;
		overflow: hidden;
		box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
		border: 1px solid var(--os-border);
	}

	.browser-header {
		background: var(--os-bg-card);
		padding: 0.75rem 1rem;
		border-bottom: 1px solid var(--os-border);
		display: flex;
		align-items: center;
		gap: 1rem;
	}

	.browser-dots {
		display: flex;
		gap: 0.4rem;
	}

	.browser-dots span {
		width: 10px;
		height: 10px;
		border-radius: 50%;
		background: var(--os-text-dim);
	}

	.browser-url {
		flex: 1;
		background: var(--os-bg);
		padding: 0.4rem 0.8rem;
		border-radius: 6px;
		font-size: 0.75rem;
		color: var(--os-text-muted);
		font-family: monospace;
	}

	.mock-interface {
		display: grid;
		grid-template-columns: 240px 1fr;
		min-height: 500px;
		background: var(--os-bg);
	}

	/* Sidebar */
	.mock-sidebar {
		background: var(--os-bg-card);
		border-right: 1px solid var(--os-border);
		padding: 1.5rem 0;
	}

	.sidebar-logo {
		font-weight: 700;
		font-size: 1.1rem;
		padding: 0 1.5rem 1.5rem;
		border-bottom: 1px solid var(--os-border);
		margin-bottom: 1rem;
		color: var(--os-primary);
	}

	.sidebar-nav {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
		padding: 0 0.75rem;
	}

	.nav-item {
		padding: 0.5rem 0.75rem;
		border-radius: 6px;
		font-size: 0.875rem;
		color: var(--os-text-muted);
		cursor: pointer;
		transition: all 0.2s;
	}

	.nav-item.indent {
		padding-left: 1.5rem;
		font-size: 0.8rem;
	}

	.nav-item.active {
		background: var(--os-primary-muted);
		color: var(--os-primary);
		font-weight: 500;
	}

	.nav-item:hover:not(.active) {
		background: var(--os-bg);
	}

	/* Main Content */
	.mock-main {
		padding: 2rem;
		background: var(--os-bg);
	}

	.mock-content-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1.5rem;
	}

	.mock-content-header h3 {
		font-size: 1.5rem;
		font-weight: 700;
		color: var(--os-text);
	}

	.progress-badge {
		background: var(--os-green);
		color: white;
		padding: 0.25rem 0.75rem;
		border-radius: 20px;
		font-size: 0.75rem;
		font-weight: 600;
	}

	/* Trainer Embed */
	.trainer-embed {
		background: var(--os-bg-card);
		border: 2px solid var(--os-primary);
		border-radius: 12px;
		padding: 2rem;
		margin-bottom: 2rem;
	}

	.trainer-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 2rem;
		padding-bottom: 1rem;
		border-bottom: 1px solid var(--os-border);
	}

	.trainer-status {
		color: var(--os-green);
		font-size: 0.875rem;
		font-weight: 600;
	}

	.trainer-timer {
		font-family: monospace;
		font-size: 1.5rem;
		font-weight: 700;
		color: var(--os-primary);
	}

	.trainer-chord {
		text-align: center;
		margin-bottom: 2rem;
	}

	.chord-name {
		font-size: 3rem;
		font-weight: 800;
		color: var(--os-primary);
		margin-bottom: 0.5rem;
	}

	.chord-voicing {
		font-size: 1rem;
		color: var(--os-text-muted);
	}

	.trainer-keyboard {
		margin-bottom: 2rem;
	}

	.piano-keys {
		display: flex;
		gap: 2px;
		justify-content: center;
		align-items: flex-end;
		height: 120px;
		padding: 0 2rem;
	}

	.key {
		border-radius: 0 0 4px 4px;
		position: relative;
	}

	.key.white {
		width: 40px;
		height: 120px;
		background: #f5f3ee;
		border: 1px solid #c8c4ba;
	}

	.key.black {
		width: 28px;
		height: 80px;
		background: var(--os-bg);
		border: 1px solid var(--os-border);
		margin: 0 -15px;
		z-index: 1;
	}

	.key.highlighted {
		background: var(--os-primary) !important;
		box-shadow: 0 0 20px var(--os-primary);
	}

	.trainer-progress {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.trainer-progress span {
		font-size: 0.875rem;
		color: var(--os-text-muted);
	}

	.progress-bar {
		height: 8px;
		background: var(--os-bg);
		border-radius: 4px;
		overflow: hidden;
	}

	.progress-fill {
		height: 100%;
		background: linear-gradient(90deg, var(--os-primary) 0%, #8b7ec8 100%);
		transition: width 0.3s ease;
	}

	.mock-cta {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.mock-cta p {
		color: var(--os-green);
		font-size: 0.95rem;
		font-weight: 500;
	}

	/* Mobile */
	@media (max-width: 968px) {
		.mock-interface {
			grid-template-columns: 1fr;
		}

		.mock-sidebar {
			display: none;
		}

		.piano-keys {
			padding: 0;
		}

		.key.white {
			width: 30px;
		}

		.key.black {
			width: 20px;
			margin: 0 -11px;
		}
	}
</style>
