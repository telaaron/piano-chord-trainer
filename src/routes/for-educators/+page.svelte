<script lang="ts">
	import { t } from '$lib/i18n';
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
	<title>{t('educators.title')}</title>
	<meta name="description" content={t('educators.meta_desc')} />
	<link rel="canonical" href="https://jazzchords.app/for-educators" />
	<meta property="og:title" content={t('educators.title')} />
	<meta property="og:description" content={t('educators.meta_desc')} />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://jazzchords.app/for-educators" />
	<meta property="og:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta property="og:image:type" content="image/webp" />
	<meta property="og:image:width" content="966" />
	<meta property="og:image:height" content="507" />
	<meta property="og:image:alt" content="Chord Trainer for Jazz Education Platforms" />
	<meta property="og:site_name" content="Chord Trainer" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="Jazz Voicing Trainer for Music Schools &amp; Online Jazz Platforms" />
	<meta name="twitter:description" content="Professional chord voicing trainer for jazz education. MIDI recognition, progress tracking, white-label ready." />
	<meta name="twitter:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta name="twitter:image:alt" content="Chord Trainer for Jazz Education Platforms" />

	{@html `<script type="application/ld+json">${JSON.stringify({
		"@context": "https://schema.org",
		"@type": "FAQPage",
		"mainEntity": [
			{
				"@type": "Question",
				"name": "How does the Chord Trainer integrate into my music education platform?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "Integration is a single embed code — an iframe with URL parameters for preset, branding, and voicing type. White-label colors and logo are configurable. Students never leave your platform."
				}
			},
			{
				"@type": "Question",
				"name": "Does the Chord Trainer require a MIDI keyboard?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "No. MIDI is optional and unlocks automatic chord validation. Without MIDI, students can still practice using the on-screen keyboard. The tool works in Chrome and Edge."
				}
			},
			{
				"@type": "Question",
				"name": "What jazz voicing types does the trainer cover?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "The trainer covers root-position chords, shell voicings (3-7), rootless A and B voicings (Bill Evans style), and all inversions — across 14 chord qualities in all 12 keys."
				}
			},
			{
				"@type": "Question",
				"name": "How much does a platform license cost?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "Pricing is a flat monthly license fee, typically starting at €200/month depending on platform size, with a 30-day free trial. Contact us for a demo and custom quote."
				}
			},
			{
				"@type": "Question",
				"name": "Can the trainer be linked to specific lessons in my curriculum?",
				"acceptedAnswer": {
					"@type": "Answer",
					"text": "Yes. URL parameters pre-set the voicing type, progression, and difficulty for each embed. A shell voicings lesson links to a shell voicings drill; a ii-V-I lesson links to ii-V-I in all 12 keys — no extra setup needed."
				}
			}
		]
	})}</script>`}
</svelte:head>

<main class="flex-1" style="background: linear-gradient(180deg, var(--bg) 0%, #110e0a 30%, #0d0b08 60%, var(--bg) 100%);">
	<!-- Hero -->
	<section style="position: relative; overflow: hidden;">
		<!-- Background image -->
		<img
			src="/elements/for-educators/hero-studio-classroom.webp"
			alt=""
			aria-hidden="true"
			loading="eager"
			fetchpriority="high"
			class="educators-hero-bg-image"
			style="
				position: absolute;
				inset: 0;
				width: 100%;
				height: 100%;
				object-fit: cover;
				object-position: center 20%;
				z-index: 0;
				opacity: 0.5;
			"
		/>

		<!-- Gradient overlay -->
		<div style="
			position: absolute;
			inset: 0;
			z-index: 1;
			background: linear-gradient(
				to bottom,
				rgba(0,0,0,0.2) 0%,
				rgba(0,0,0,0.5) 50%,
				var(--bg) 100%
			);
		"></div>

		<!-- Content -->
		<div class="text-center px-4 py-16 sm:py-24" style="position: relative; z-index: 2;">
			<div class="max-w-4xl mx-auto">
				<div class="inline-flex items-center gap-2 px-3 py-1 mb-6 rounded-full border border-[var(--border)] bg-[var(--bg-card)] text-xs text-[var(--text-muted)]">
					{t('educators.badge')}
				</div>

				<h1 class="text-4xl sm:text-5xl font-bold tracking-tight leading-[1.1] mb-6">
					<span class="text-gradient">{@html t('educators.hero_h1_gradient')}</span><br />
					<span class="text-[var(--text-muted)] text-3xl sm:text-4xl">{t('educators.hero_h1_b')}</span>
				</h1>

				<p class="text-lg text-[var(--text-muted)] max-w-2xl mx-auto leading-relaxed">
					{t('educators.hero_p')}
				</p>
			</div>
		</div>
	</section>

	<div class="max-w-4xl mx-auto px-4 py-16 sm:py-24">

		<!-- Platforms we speak to -->
		<section class="mb-20">
			<h2 class="text-xl sm:text-2xl font-bold mb-8 text-center">{t('educators.platforms_title')}</h2>
			<div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
				{#each [
					{ name: 'Open Studio Jazz', desc: t('educators.platform_open_studio'), href: '/open-studio' },
					{ name: 'Jazz-Academy', desc: t('educators.platform_jazz_academy'), href: '' },
					{ name: 'Learn Jazz Standards', desc: t('educators.platform_learn_jazz'), href: '' },
					{ name: 'Private Teachers', desc: t('educators.platform_private_teachers'), href: '' },
				] as platform}
					{#if platform.href}
						<a href={platform.href} class="card card-hover p-5 text-center block no-underline">
							<p class="font-semibold text-sm text-[var(--text)] mb-1">{@html platform.name}</p>
							<p class="text-xs text-[var(--text-muted)] leading-relaxed">{@html platform.desc}</p>
						</a>
					{:else}
						<div class="card p-5 text-center">
							<p class="font-semibold text-sm text-[var(--text)] mb-1">{@html platform.name}</p>
							<p class="text-xs text-[var(--text-muted)] leading-relaxed">{@html platform.desc}</p>
						</div>
					{/if}
				{/each}
			</div>
		</section>

		<!-- Problem -->
		<section class="mb-20">
			<div class="card p-8 sm:p-10 border-[var(--accent-amber)]/20">
				<h2 class="text-xl font-bold mb-4 text-[var(--accent-amber)]">{t('educators.problem_title')}</h2>
				<p class="text-[var(--text-muted)] leading-relaxed text-lg">
					{@html t('educators.problem_desc')}
				</p>
			</div>
		</section>

		<!-- Solution -->
		<section class="mb-20">
			<h2 class="text-2xl sm:text-3xl font-bold mb-8 text-center">{t('educators.solution_title')}</h2>

			<div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<Zap size={20} class="text-[var(--primary)]" />
						<h3 class="font-semibold">{t('educators.solution_speed')}</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						{t('educators.solution_speed_desc')}
					</p>
				</div>

				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<CheckCircle size={20} class="text-[var(--accent-green)]" />
						<h3 class="font-semibold">{t('educators.solution_midi')}</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						{t('educators.solution_midi_desc')}
					</p>
				</div>

				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<BarChart3 size={20} class="text-[var(--accent-red)]" />
						<h3 class="font-semibold">{t('educators.solution_analytics')}</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						{t('educators.solution_analytics_desc')}
					</p>
				</div>

				<div class="card p-6">
					<div class="flex items-center gap-3 mb-3">
						<Users size={20} class="text-[var(--accent-purple)]" />
						<h3 class="font-semibold">{t('educators.solution_guided')}</h3>
					</div>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						{t('educators.solution_guided_desc')}
					</p>
				</div>
			</div>
		</section>

		<!-- What we cover -->
		<section class="mb-20">
			<h2 class="text-2xl sm:text-3xl font-bold mb-8 text-center">{t('educators.what_students_train')}</h2>
			<div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
				{#each [
					t('educators.train_chord_types'),
					t('educators.train_shell_voicings'),
					t('educators.train_rootless_a'),
					t('educators.train_inversions'),
					t('educators.train_progressions'),
					t('educators.train_turnarounds'),
					t('educators.train_circle'),
					t('educators.train_custom'),
					t('educators.train_difficulty'),
					t('educators.train_notation'),
					t('educators.train_audio'),
					t('educators.train_metronome'),
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
			<h2 class="text-2xl sm:text-3xl font-bold mb-8 text-center">{t('educators.integration_title')}</h2>

			<div class="space-y-4">
				<div class="card p-6 flex items-start gap-4">
					<Shield size={24} class="text-[var(--primary)] flex-shrink-0 mt-0.5" />
					<div>
						<h3 class="font-semibold mb-1">{t('educators.integration_white_label')}</h3>
						<p class="text-sm text-[var(--text-muted)]">
							{t('educators.integration_white_label_desc')}
						</p>
					</div>
				</div>

				<div class="card p-6 flex items-start gap-4">
					<Zap size={24} class="text-[var(--accent-green)] flex-shrink-0 mt-0.5" />
					<div>
						<h3 class="font-semibold mb-1">{t('educators.integration_trial')}</h3>
						<p class="text-sm text-[var(--text-muted)]">
							{t('educators.integration_trial_desc')}
						</p>
					</div>
				</div>

				<div class="card p-6 flex items-start gap-4">
					<BarChart3 size={24} class="text-[var(--accent-amber)] flex-shrink-0 mt-0.5" />
					<div>
						<h3 class="font-semibold mb-1">{t('educators.integration_licensing')}</h3>
						<p class="text-sm text-[var(--text-muted)]">
							{t('educators.integration_licensing_desc')}
						</p>
					</div>
				</div>
			</div>
		</section>

		<!-- How It Works -->
		<section class="mb-20">
			<h2 class="text-2xl sm:text-3xl font-bold mb-8 text-center">{t('educators.how_it_works')}</h2>

			<div class="space-y-4">
				<div class="card p-6">
					<div class="flex items-start gap-4">
						<div class="w-8 h-8 rounded-full bg-[var(--primary-muted)] flex items-center justify-center flex-shrink-0 text-sm font-bold text-[var(--primary)]">1</div>
						<div>
							<h3 class="font-semibold mb-1">{t('educators.how_step1')}</h3>
							<p class="text-sm text-[var(--text-muted)]">
								{t('educators.how_step1_desc')}
							</p>
						</div>
					</div>
				</div>

				<div class="card p-6">
					<div class="flex items-start gap-4">
						<div class="w-8 h-8 rounded-full bg-[var(--primary-muted)] flex items-center justify-center flex-shrink-0 text-sm font-bold text-[var(--primary)]">2</div>
						<div>
							<h3 class="font-semibold mb-1">{t('educators.how_step2')}</h3>
							<p class="text-sm text-[var(--text-muted)]">
								{t('educators.how_step2_desc')}
							</p>
						</div>
					</div>
				</div>

				<div class="card p-6">
					<div class="flex items-start gap-4">
						<div class="w-8 h-8 rounded-full bg-[var(--primary-muted)] flex items-center justify-center flex-shrink-0 text-sm font-bold text-[var(--primary)]">3</div>
						<div>
							<h3 class="font-semibold mb-1">{t('educators.how_step3')}</h3>
							<p class="text-sm text-[var(--text-muted)]">
								{t('educators.how_step3_desc')}
							</p>
						</div>
					</div>
				</div>
			</div>

			<div class="mt-8 text-center">
				<a
					href="/embed?mode=2-5-1&voicing=shell&chords=12"
					class="inline-flex items-center gap-2 text-sm text-[var(--primary)] hover:text-[var(--primary-hover)] transition-colors"
				>
					{t('educators.see_live_widget')}
					<ArrowRight size={14} />
				</a>
			</div>
		</section>

		<!-- CTA -->
		<section class="text-center">
			<div class="card p-10 sm:p-14 border-[var(--primary)]/20">
				<h2 class="text-2xl sm:text-3xl font-bold mb-4">{t('educators.cta_title')}</h2>
				<p class="text-[var(--text-muted)] mb-8 max-w-lg mx-auto">
					{t('educators.cta_desc')}
				</p>

				<div class="flex flex-col sm:flex-row items-center justify-center gap-4">
					<a
						href="/embed?mode=2-5-1&voicing=shell&chords=12"
						class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] bg-[var(--primary)] hover:bg-[var(--primary-hover)] text-white font-semibold transition-colors"
					>
						{t('educators.cta_try_demo')}
						<ArrowRight size={18} />
					</a>
					<a
						href="mailto:info@jazzchords.app"
						class="inline-flex items-center gap-2 px-8 py-3.5 rounded-[var(--radius-lg)] border border-[var(--border)] hover:border-[var(--border-hover)] text-[var(--text-muted)] hover:text-[var(--text)] font-medium transition-colors"
					>
						<Mail size={18} />
						{t('educators.cta_contact')}
					</a>
				</div>
			</div>
		</section>
	</div>
</main>

<style>
	/* Hero background image mobile adjustment */
	@media (max-width: 768px) {
		.educators-hero-bg-image {
			object-position: center center !important;
		}
	}
</style>
