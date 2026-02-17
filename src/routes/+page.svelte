<script lang="ts">
	import {
		Piano,
		Volume2,
		BarChart3,
		BookOpen,
		ArrowRight,
		Keyboard,
		Target,
	} from 'lucide-svelte';
</script>

<svelte:head>
	<title>Chord Trainer – Jazz Piano Voicing Speed Training</title>
	<meta name="description" content="Master jazz piano voicings in all 12 keys. Speed training with MIDI recognition, ii-V-I progressions, 4 voicing types, and progress tracking. Free, no signup." />
	<meta property="og:title" content="Chord Trainer – Jazz Piano Voicing Speed Training" />
	<meta property="og:description" content="Master jazz piano voicings in all 12 keys. Speed training with MIDI recognition and ii-V-I progressions." />
	<meta property="og:type" content="website" />
</svelte:head>

<!-- Hero -->
<section class="flex-1 flex flex-col items-center justify-center px-4 pt-16 sm:pt-24 pb-12">
	<div class="max-w-3xl mx-auto text-center">
		<div class="inline-flex items-center gap-2 px-3 py-1 mb-6 rounded-full border border-[var(--border)] bg-[var(--bg-card)] text-xs text-[var(--text-muted)]">
			<span class="inline-block w-2 h-2 rounded-full bg-[var(--accent-green)] animate-pulse"></span>
			MIDI · Audio · Progress Tracking
		</div>

		<h1 class="text-5xl sm:text-6xl lg:text-7xl font-bold tracking-tight leading-[1.1]">
			<span class="text-gradient">Master Jazz Piano</span><br />
			<span class="text-[var(--text)]">Voicings in All 12 Keys</span>
		</h1>

		<p class="mt-6 text-lg sm:text-xl text-[var(--text-muted)] max-w-xl mx-auto leading-relaxed">
			Speed training that builds muscle memory. See a chord, play it, get faster.
			Shell voicings, rootless, ii-V-I — through every key.
		</p>

		<div class="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
			<a
				href="/train"
				class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white font-semibold text-lg transition-colors"
			>
				Start Training
				<ArrowRight size={20} />
			</a>
			<a
				href="/for-educators"
				class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] border border-[var(--border)] hover:border-[var(--border-hover)] text-[var(--text-muted)] hover:text-[var(--text)] font-medium transition-colors"
			>
				For Music Schools
			</a>
		</div>

		<p class="mt-4 text-sm text-[var(--text-dim)]">
			Free. No signup. Works in Chrome &amp; Edge.
		</p>
	</div>
</section>

<!-- Features -->
<section class="px-4 pb-20">
	<div class="max-w-5xl mx-auto">
		<div class="text-center mb-12">
			<h2 class="text-2xl sm:text-3xl font-bold">Everything you need to drill chord changes</h2>
			<p class="mt-3 text-[var(--text-muted)]">Built by jazz pianists, for jazz pianists.</p>
		</div>

		<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
			<!-- MIDI -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--primary-muted)] flex items-center justify-center mb-4">
					<Piano size={20} class="text-[var(--primary)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">MIDI Recognition</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					Plug in your keyboard. The app listens to what you play and auto-advances when you nail the chord.
				</p>
			</div>

			<!-- Progressions -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--accent-purple)]/15 flex items-center justify-center mb-4">
					<Target size={20} class="text-[var(--accent-purple)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">ii-V-I in All Keys</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					The most important jazz progression, drilled through all 12 keys. Plus turnarounds and circle of fourths.
				</p>
			</div>

			<!-- Voicings -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--accent-green)]/15 flex items-center justify-center mb-4">
					<Keyboard size={20} class="text-[var(--accent-green)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">4+ Voicing Types</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					Root position, shell, rootless A, inversions — each shown on a visual 2-octave keyboard.
				</p>
			</div>

			<!-- Audio -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--accent-amber)]/15 flex items-center justify-center mb-4">
					<Volume2 size={20} class="text-[var(--accent-amber)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">Audio &amp; Metronome</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					Hear every chord. Auto-plays on each new chord, or tap to listen again. Built-in metronome with BPM control.
				</p>
			</div>

			<!-- Progress -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--accent-red)]/15 flex items-center justify-center mb-4">
					<BarChart3 size={20} class="text-[var(--accent-red)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">Weakness Analysis</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					Tracks time per chord. Shows your slowest keys, improvement trends, and personal records.
				</p>
			</div>

			<!-- Plans -->
			<div class="card p-6 card-hover transition-all">
				<div class="w-10 h-10 rounded-[var(--radius)] bg-[var(--primary-muted)] flex items-center justify-center mb-4">
					<BookOpen size={20} class="text-[var(--primary)]" />
				</div>
				<h3 class="font-semibold text-lg mb-2">Guided Practice Plans</h3>
				<p class="text-sm text-[var(--text-muted)] leading-relaxed">
					One-tap presets: Warm-Up, Speed Run, Challenge, Left-Hand Comping. Start training in 2 seconds.
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

		<div class="space-y-8">
			<div class="flex items-start gap-5">
				<div class="flex-shrink-0 w-10 h-10 rounded-full bg-[var(--primary)] flex items-center justify-center text-white font-bold text-sm">1</div>
				<div>
					<h3 class="font-semibold text-lg">Choose your drill</h3>
					<p class="text-[var(--text-muted)] mt-1">Pick a practice plan or customize: voicing type, difficulty, progression mode, number of chords.</p>
				</div>
			</div>
			<div class="flex items-start gap-5">
				<div class="flex-shrink-0 w-10 h-10 rounded-full bg-[var(--primary)] flex items-center justify-center text-white font-bold text-sm">2</div>
				<div>
					<h3 class="font-semibold text-lg">Play each chord</h3>
					<p class="text-[var(--text-muted)] mt-1">A chord appears on screen. Play it on your MIDI keyboard — or press Space to advance manually. The timer tracks your speed per chord.</p>
				</div>
			</div>
			<div class="flex items-start gap-5">
				<div class="flex-shrink-0 w-10 h-10 rounded-full bg-[var(--primary)] flex items-center justify-center text-white font-bold text-sm">3</div>
				<div>
					<h3 class="font-semibold text-lg">Review &amp; improve</h3>
					<p class="text-[var(--text-muted)] mt-1">See your results: total time, accuracy, slowest chords. Track progress over sessions and build daily practice streaks.</p>
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
