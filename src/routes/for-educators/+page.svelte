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
	<meta property="og:title" content="Chord Trainer for Music Schools & Jazz Education" />
	<meta property="og:description" content="Integrate a professional chord voicing trainer into your jazz education platform." />
	<meta property="og:type" content="website" />
</svelte:head>

<main class="flex-1 px-4 py-16 sm:py-24">
	<div class="max-w-4xl mx-auto">
		<!-- Hero -->
		<div class="text-center mb-20">
			<div class="inline-flex items-center gap-2 px-3 py-1 mb-6 rounded-full border border-[var(--border)] bg-[var(--bg-card)] text-xs text-[var(--text-muted)]">
				For Jazz Education Platforms &amp; Music Schools
			</div>

			<h1 class="text-4xl sm:text-5xl font-bold tracking-tight leading-[1.1] mb-6">
				Your students say<br />
				<span class="text-gradient">"Take it through all 12 keys"</span><br />
				<span class="text-[var(--text-muted)] text-3xl sm:text-4xl">Now there's a tool for that.</span>
			</h1>

			<p class="text-lg text-[var(--text-muted)] max-w-2xl mx-auto leading-relaxed">
				A speed-drill tool that systematically trains chord voicings in every key.
				MIDI recognition validates technique. Progress tracking shows improvement.
				Ready for integration into your platform.
			</p>
		</div>

		<!-- Problem -->
		<section class="mb-20">
			<div class="card p-8 sm:p-10 border-[var(--accent-amber)]/20">
				<h2 class="text-xl font-bold mb-4 text-[var(--accent-amber)]">The Problem</h2>
				<p class="text-[var(--text-muted)] leading-relaxed text-lg">
					Students learn voicing theory but struggle to <strong class="text-[var(--text)]">play changes fluently in all 12 keys</strong>.
					There's no shortage of chord charts and theory lessons — but there's no dedicated tool for the repetitive,
					timed speed-drill practice that actually builds muscle memory.
				</p>
				<p class="mt-4 text-[var(--text-muted)] leading-relaxed">
					That's the gap between knowing a voicing and <em>owning</em> it.
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
						Randomized chords on a timer. ii-V-I progressions, turnarounds, and circle of fourths — all through 12 keys. Timed per chord for measurable improvement.
					</p>
				</div>

				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<CheckCircle size={20} class="text-[var(--accent-green)]" />
						<h3 class="font-semibold">MIDI Validation</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						Students plug in their keyboard. The app listens, validates the chord, and auto-advances. Accuracy score per session — no more self-reporting.
					</p>
				</div>

				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<BarChart3 size={20} class="text-[var(--accent-red)]" />
						<h3 class="font-semibold">Progress Analytics</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						Weakness analysis identifies slowest keys. Improvement trends show "You're 25% faster at ♭ keys this week." Streaks reward daily practice.
					</p>
				</div>

				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<Users size={20} class="text-[var(--accent-purple)]" />
						<h3 class="font-semibold">Guided Practice</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						9 curated practice plans: Warm-Up, ii-V-I Deep Dive, Left-Hand Comping, Challenge Mode. Students tap once and start — no configuration needed.
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
							Flat monthly fee or revenue share — whatever works for your business model. Built-in analytics to track member engagement.
						</p>
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
						href="mailto:hello@chordtrainer.app"
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
