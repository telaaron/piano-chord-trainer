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
		Lock,
		Users,
		Menu,
		Sparkles,
		Piano,
	} from 'lucide-svelte';
	import { t } from '$lib/i18n';
	// This page is prerendered, so {@html t(...)} would freeze the build-time
	// (English) locale into the markup. RichText re-reads t() after hydration.
	import RichText from '$lib/components/RichText.svelte';
</script>

<svelte:head>
	<title>{t('open_studio.title')}</title>
	<meta name="description" content={t('open_studio.meta_desc')} />
	<link rel="canonical" href="https://jazzchords.app/open-studio" />
	<meta property="og:title" content={t('open_studio.title')} />
	<meta property="og:description" content={t('open_studio.meta_desc')} />
	<meta property="og:type" content="website" />
	<meta property="og:url" content="https://jazzchords.app/open-studio" />
	<meta property="og:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta property="og:image:type" content="image/webp" />
	<meta property="og:image:width" content="966" />
	<meta property="og:image:height" content="507" />
	<meta property="og:image:alt" content="Chord Trainer embedded inside Open Studio Jazz platform" />
	<meta property="og:site_name" content="Chord Trainer" />
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content={t('open_studio.title')} />
	<meta name="twitter:description" content={t('open_studio.meta_desc')} />
	<meta name="twitter:image" content="https://jazzchords.app/seo/OG-image.webp" />
	<meta name="twitter:image:alt" content="Chord Trainer embedded inside Open Studio Jazz platform" />

	{@html `<script type="application/ld+json">${JSON.stringify({
		"@context": "https://schema.org",
		"@type": "Service",
		"name": "Chord Trainer – Open Studio Integration",
		"description": "White-label jazz piano voicing speed-drill trainer for embedding in music education platforms.",
		"provider": {
			"@type": "Organization",
			"name": "Aaron Technologies OÜ",
			"url": "https://jazzchords.app"
		},
		"serviceType": "Music Education Software",
		"areaServed": "Worldwide",
		"offers": {
			"@type": "Offer",
			"price": "0",
			"priceCurrency": "USD",
			"description": "30-day free trial, then flat monthly license fee"
		}
	})}</script>`}
</svelte:head>

<main class="flex-1 os">
	<!-- Hero -->
	<section class="relative overflow-hidden">
		<!-- Background image -->
		<img
			src="/elements/open-studio/hero-2am-piano.webp"
			alt=""
			aria-hidden="true"
			loading="eager"
			fetchpriority="high"
			class="absolute inset-0 w-full h-full object-cover object-[center_30%] z-0 opacity-[0.45] max-md:object-[70%_center]"
		/>

		<!-- Gradient overlay -->
		<div class="absolute inset-0 z-1" style="background: linear-gradient(to bottom, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.55) 50%, var(--bg) 100%)"></div>

		<!-- Content -->
		<div class="max-w-4xl mx-auto px-4 py-20 sm:py-28 text-center relative z-2">
			<p class="plate plate-center">{t('open_studio.badge')}</p>

			<h1 class="os-h1">
				<RichText key="open_studio.hero_h1" as="span" />
			</h1>

			<RichText key="open_studio.hero_p" class="text-lg sm:text-xl text-[var(--text-muted)] max-w-2xl mx-auto leading-relaxed mb-10" />

			<div class="flex flex-col sm:flex-row items-center justify-center gap-4">
				<a
					href="/embed?theme=openstudio&mode=2-5-1&voicing=shell"
					class="btn-stamp"
				>
					{t('open_studio.cta_demo')}
					<Play size={18} />
				</a>
				<a
					href="mailto:info@jazzchords.app?subject=Open%20Studio%20Integration"
					class="btn-rule"
				>
					<Mail size={18} />
					{t('open_studio.cta_schedule')}
				</a>
			</div>
		</div>
	</section>

	<!-- The Pitch -->
	<section class="px-4 py-14 sm:py-16">
		<div class="max-w-4xl mx-auto">
			<div class="panel panel-note p-8 sm:p-10">
				<h2 class="panel-h">{t('open_studio.opportunity_title')}</h2>
				<p class="text-[var(--text-muted)] leading-relaxed text-lg">
					{t('open_studio.opportunity_p1')}
				</p>
				<RichText key="open_studio.opportunity_p2" class="text-[var(--text-muted)] leading-relaxed text-lg mt-4" />
			</div>
		</div>
	</section>

	<!-- How It Works Inside OS -->
	<section class="px-4 py-14 sm:py-16">
		<div class="max-w-4xl mx-auto">
			<h2 class="sec-h">{t('open_studio.how_title')}</h2>
			<p class="text-center text-[var(--text-muted)] mb-12 max-w-2xl mx-auto">
				{t('open_studio.how_sub')}
			</p>

			<div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
				<div class="panel p-6 text-center">
					<div class="icon-plate">
						<Monitor size={24} class="text-[var(--primary)]" />
					</div>
					<h3 class="panel-h3">{t('open_studio.how_step1')}</h3>
					<p class="text-sm text-[var(--text-muted)]">
						{t('open_studio.how_step1_desc')}
					</p>
				</div>

				<div class="panel p-6 text-center">
					<div class="icon-plate">
						<Keyboard size={24} class="text-[var(--primary)]" />
					</div>
					<h3 class="panel-h3">{t('open_studio.how_step2')}</h3>
					<p class="text-sm text-[var(--text-muted)]">
						{t('open_studio.how_step2_desc')}
					</p>
				</div>

				<div class="panel p-6 text-center">
					<img src="/elements/open-studio/step-track-progress.webp" alt="Track Progress" width="72" height="72" loading="lazy" style="object-fit: contain; display: block; margin: 0 auto 16px;" />
					<h3 class="panel-h3">{t('open_studio.how_step3')}</h3>
					<p class="text-sm text-[var(--text-muted)]">
						{t('open_studio.how_step3_desc')}
					</p>
				</div>
			</div>
		</div>
	</section>

	<!-- Platform Mock — Accurate Open Studio UI -->
	<section class="px-4 py-14 sm:py-16">
		<div class="max-w-5xl mx-auto">
			<h2 class="sec-h">{t('open_studio.platform_title')}</h2>
			<p class="text-center text-[var(--text-muted)] mb-10 max-w-2xl mx-auto">
				{@html t('open_studio.platform_sub')}
				<span class="block mt-1 text-sm text-[var(--text-dim)]">{t('open_studio.platform_preview')}</span>
			</p>

			<div class="mock-frame">
				<!-- Browser Chrome -->
				<div class="bg-[#2b2b2b] px-3 py-[0.6rem] flex items-center gap-3">
					<div class="flex gap-[0.35rem]"><span class="w-2.75 h-2.75 rounded-full bg-[#ff5f57]"></span><span class="w-2.75 h-2.75 rounded-full bg-[#ffbd2e]"></span><span class="w-2.75 h-2.75 rounded-full bg-[#28c840]"></span></div>
					<div class="flex-1 bg-[#3a3a3a] px-3 py-[0.35rem] rounded-md text-[0.8rem] text-[#ccc] flex items-center gap-[0.4rem]">
						<Lock size={11} class="text-[#ccc] shrink-0" aria-hidden="true" />
						app.openstudiojazz.com
					</div>
				</div>

				<!-- OS Top Nav -->
				<div class="bg-[#0D0D0D] px-6 py-3 flex items-center justify-between border-b border-[#e5e5e5]">
					<img src="/mock-content/open-studio-logo.png" alt="Open Studio" class="h-6"
						width="160" height="32" loading="lazy" />
					<div class="flex gap-6 max-md:hidden">
						<span class="text-[0.8rem] text-[#555] flex items-center gap-[0.3rem] cursor-default">
							<span class="text-[0.7rem]">◎</span> Courses
						</span>
						<span class="text-[0.8rem] text-[#555] flex items-center gap-[0.3rem] cursor-default">
							<span class="text-[0.7rem]">⦿</span> Live Sessions
						</span>
						<span class="text-[0.8rem] text-[#555] flex items-center gap-[0.3rem] cursor-default">
							<Users size={11} class="text-[#555] shrink-0" aria-hidden="true" /> The Hang
						</span>
					</div>
					<div class="flex items-center gap-3 max-md:hidden">
						<Bookmark size={18} class="text-[#999]" />
						<User size={18} class="text-[#999]" />
					</div>
				</div>

				<!-- OS Content Area -->
				<div class="bg-white pb-6">
					<!-- Breadcrumb -->
					<div class="px-6 py-3 flex justify-between items-center text-[0.85rem] text-[#333]">
						<span>← Harmony Games Unlimited</span>
						<span class="text-[0.8rem] text-[#555] border border-[#ddd] px-3 py-[0.35rem] rounded-md cursor-default inline-flex items-center gap-[0.3rem]"><Menu size={13} class="text-[#555] shrink-0" aria-hidden="true" /> View Chapters</span>
					</div>

					<!-- Video Thumbnail -->
					<div class="mx-6 rounded-lg overflow-hidden relative bg-black">
						<img src="/mock-content/thumbnail.png" alt="ii-V-I Progression — Jazz fundamentals drill" class="w-full h-auto block"
							width="960" height="540" loading="lazy" />
						<!-- Video Controls Bar -->
						<div class="bg-black/85 px-3 py-2 flex items-center gap-3 text-xs text-[#ccc]">
							<div class="w-7 h-7 bg-[#4da6ff] rounded-full flex items-center justify-center text-white text-[0.65rem] shrink-0">▶</div>
							<div class="flex flex-col gap-[0.1rem] flex-1">
								<span class="font-semibold text-white text-[0.8rem]">ii-V-I Progression · Speed Drill</span>
								<span class="text-[0.7rem] text-[#999]">0:00 / 14:18</span>
							</div>
							<div class="flex gap-3 text-[0.7rem] text-[#999] max-md:hidden">
								<span>100%</span>
								<span>⊖ ⊕</span>
								<span>↻ Loop</span>
							</div>
						</div>
					</div>

					<!-- Tabs — with our new "Practice" tab -->
					<div class="flex gap-0 border-b border-[#e5e5e5] px-6 mt-6">
						<span class="px-4 py-3 text-[0.85rem] text-[#888] border-b-2 border-transparent cursor-default">Overview</span>
						<span class="px-4 py-3 text-[0.85rem] text-[#888] border-b-2 border-transparent cursor-default">Materials</span>
						<span class="px-4 py-3 text-[0.85rem] text-[#888] border-b-2 border-transparent cursor-default">Shortcuts</span>
						<span class="px-4 py-3 text-[0.85rem] border-b-2 cursor-default text-[#1a1a1a] border-b-[#1a1a1a] font-semibold inline-flex items-center gap-[0.3rem]">Practice <Sparkles size={13} class="text-[#1a1a1a] shrink-0" aria-hidden="true" /></span>
					</div>

					<!-- Chord Trainer Embedded -->
					<div class="m-6 bg-[#f8f8f8] border-2 border-[#004E89] rounded-xl p-6 relative">
						<div class="absolute top-[-0.6rem] left-5 bg-[#004E89] text-white text-[0.65rem] font-bold px-2 py-[0.15rem] rounded uppercase tracking-[0.04em]">Preview · Chord Trainer Integration</div>

						<div class="flex justify-between items-center mb-5 pb-3 border-b border-[rgba(0,78,137,0.2)] text-[0.8rem]">
							<span class="text-[#00a86b] font-semibold inline-flex items-center gap-[0.3rem]"><Piano size={14} class="text-[#00a86b] shrink-0" aria-hidden="true" /> MIDI Connected</span>
							<span class="text-[#666]">ii-V-I Progression · All Keys</span>
							<span class="text-xl font-bold text-[#004E89]" style="font-family: var(--font-mono)">1:47</span>
						</div>

						<div class="text-center mb-5">
							<div class="text-[2.75rem] font-extrabold text-[#004E89] leading-none mb-1">Dm7</div>
							<div class="text-[0.9rem] text-[#333]">Shell Voicing (D – F – C)</div>
						</div>

						<!-- Piano Keys -->
						<div class="flex justify-center items-start h-22.5 gap-px mb-5 px-4 relative max-md:px-0">
							{#each Array(15) as _, i}
								{@const isBlack = [1, 3, 6, 8, 10, 13].includes(i)}
								{@const isActive = [2, 5, 12].includes(i)}
								<div
									class="rounded-b {isBlack ? 'w-5.5 h-14.5 bg-[#161329] border border-[#2d2952] -mx-3 z-2 relative max-md:w-4 max-md:-mx-2.25' : 'w-8.5 h-22.5 bg-[#f5f3ee] border border-[#c8c4ba] max-md:w-6.5'}"
									class:os-key-active={isActive}
									class:os-key-white={!isBlack}
									class:os-key-black={isBlack}
								></div>
							{/each}
						</div>

						<div class="flex items-center gap-3 text-[0.8rem] text-(--text-muted)">
							<span>Chord 8 / 20</span>
							<div class="flex-1 h-1.25 bg-[rgba(45, 41, 82,0.2)] rounded-[3px] overflow-hidden">
								<div class="h-full" style="width: 40%; background: var(--primary)"></div>
							</div>
							<span class="text-(--accent-green) font-semibold">Accuracy: 94%</span>
						</div>
					</div>

				</div>
			</div>
		</div>

		<!-- Benefits as annotation OUTSIDE the mock -->
		<div class="max-w-5xl mx-auto">
			<div class="benefits">
				<div class="benefit">
					<CheckCircle size={18} class="text-[var(--success)]" />
					<span>{t('open_studio.benefits_1')}</span>
				</div>
				<div class="benefit">
					<CheckCircle size={18} class="text-[var(--success)]" />
					<span>{t('open_studio.benefits_2')}</span>
				</div>
				<div class="benefit">
					<CheckCircle size={18} class="text-[var(--success)]" />
					<span>{t('open_studio.benefits_3')}</span>
				</div>
			</div>
		</div>
	</section>

	<!-- What The Trainer Covers -->
	<section class="px-4 py-14 sm:py-16">
		<div class="max-w-4xl mx-auto">
			<h2 class="sec-h">{t('open_studio.practice_title')}</h2>
			<p class="text-center text-[var(--text-muted)] mb-10">{t('open_studio.practice_sub')}</p>

			<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
				{#each [
					{ title: t('open_studio.practice_shell'), desc: t('open_studio.practice_shell_desc') },
					{ title: t('open_studio.practice_rootless_a'), desc: t('open_studio.practice_rootless_a_desc') },
					{ title: t('open_studio.practice_rootless_b'), desc: t('open_studio.practice_rootless_b_desc') },
					{ title: t('open_studio.practice_251'), desc: t('open_studio.practice_251_desc') },
					{ title: t('open_studio.practice_turnaround'), desc: t('open_studio.practice_turnaround_desc') },
					{ title: t('open_studio.practice_custom'), desc: t('open_studio.practice_custom_desc') },
					{ title: t('open_studio.practice_inversions'), desc: t('open_studio.practice_inversions_desc') },
					{ title: t('open_studio.practice_qualities'), desc: t('open_studio.practice_qualities_desc') },
				] as item}
					<div class="panel p-5 flex items-start gap-3">
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
	<section class="px-4 py-14 sm:py-16">
		<div class="max-w-4xl mx-auto">
			<h2 class="sec-h sec-h-wide">{t('open_studio.integration_title')}</h2>

			<div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
				<div class="panel panel-mark p-6 relative overflow-hidden">
					<div class="tag-mark">{t('open_studio.integration_recommended')}</div>
					<Layers size={24} class="text-[var(--primary)] mb-3" />
					<h3 class="panel-h3">{t('open_studio.integration_lesson')}</h3>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						{t('open_studio.integration_lesson_desc')}
					</p>
					<p class="text-xs text-[var(--text-dim)] mt-3 font-mono">iframe with URL params</p>
				</div>

				<div class="panel p-6">
					<Monitor size={24} class="text-[var(--primary)] mb-3" />
					<h3 class="panel-h3">{t('open_studio.integration_standalone')}</h3>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						{t('open_studio.integration_standalone_desc')}
					</p>
					<p class="text-xs text-[var(--text-dim)] mt-3 font-mono">Subdomain or embedded route</p>
				</div>

				<div class="panel p-6">
					<Zap size={24} class="text-[var(--primary)] mb-3" />
					<h3 class="panel-h3">{t('open_studio.integration_challenge')}</h3>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						{t('open_studio.integration_challenge_desc')}
					</p>
					<p class="text-xs text-[var(--text-dim)] mt-3 font-mono">Overlay / modal trigger</p>
				</div>

				<div class="panel p-6">
					<Play size={24} class="text-[var(--primary)] mb-3" />
					<h3 class="panel-h3">{t('open_studio.integration_materials')}</h3>
					<p class="text-sm text-[var(--text-muted)] leading-relaxed">
						{t('open_studio.integration_materials_desc')}
					</p>
					<p class="text-xs text-[var(--text-dim)] mt-3 font-mono">Link with preset params</p>
				</div>
			</div>
		</div>
	</section>

	<!-- Harmony Games vs Chord Trainer -->
	<section class="px-4 py-14 sm:py-16">
		<div class="max-w-4xl mx-auto">
			<div class="panel p-8 sm:p-10">
				<h2 class="panel-h mb-6"><RichText key="open_studio.comparison_title" as="span" /></h2>

				<div class="grid grid-cols-1 sm:grid-cols-2 gap-6 text-sm">
					<div class="compare p-4 sm:p-5">
						<div class="tag">{t('open_studio.comparison_tag_ear')}</div>
						<h3 class="font-semibold text-[var(--text-muted)] mb-3 uppercase tracking-wider text-xs">{t('open_studio.comparison_hg')}</h3>
						<ul class="space-y-2 text-[var(--text-muted)]">
							<li>{t('open_studio.comparison_hg_1')}</li>
							<li>{t('open_studio.comparison_hg_2')}</li>
							<li>{t('open_studio.comparison_hg_3')}</li>
						</ul>
					</div>
					<div class="compare compare-mark p-4 sm:p-5">
						<div class="tag tag-stamp">{t('open_studio.comparison_tag_hands')}</div>
						<h3 class="font-semibold text-[var(--primary)] mb-3 uppercase tracking-wider text-xs">{t('open_studio.comparison_ct')}</h3>
						<ul class="space-y-2 text-[var(--text)]">
							<li>{t('open_studio.comparison_ct_1')}</li>
							<li>{t('open_studio.comparison_ct_2')}</li>
							<li>{t('open_studio.comparison_ct_3')}</li>
							<li>{t('open_studio.comparison_ct_4')}</li>
							<li>{t('open_studio.comparison_ct_5')}</li>
						</ul>
					</div>
				</div>

				<RichText key="open_studio.comparison_summary" class="text-[var(--text-muted)] mt-6 text-sm leading-relaxed" />
			</div>
		</div>
	</section>

	<!-- Terms -->
	<section class="px-4 py-14 sm:py-16">
		<div class="max-w-4xl mx-auto">
			<h2 class="sec-h sec-h-wide">{t('open_studio.terms_title')}</h2>

			<div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
				<div class="panel p-6 text-center">				<img src="/elements/open-studio/pricing-trial.webp" alt="30 Days Free Trial" width="64" height="64" loading="lazy" style="object-fit: contain; display: block; margin: 0 auto 16px;" />					<div class="terms-figure">{t('open_studio.terms_trial')}</div>
					<div class="text-sm font-medium mb-2">{t('open_studio.terms_trial_sub')}</div>
					<p class="text-xs text-[var(--text-muted)]">{t('open_studio.terms_trial_desc')}</p>
				</div>

				<div class="panel panel-mark p-6 text-center">				<img src="/elements/open-studio/pricing-flat.webp" alt="Flat Fee Monthly License" width="64" height="64" loading="lazy" style="object-fit: contain; display: block; margin: 0 auto 16px;" />					<div class="terms-figure">{t('open_studio.terms_flat')}</div>
					<div class="text-sm font-medium mb-2">{t('open_studio.terms_flat_sub')}</div>
					<p class="text-xs text-[var(--text-muted)]">{t('open_studio.terms_flat_desc')}</p>
				</div>

				<div class="panel p-6 text-center">				<img src="/elements/open-studio/pricing-whitelabel.webp" alt="White-Label Your Branding" width="64" height="64" loading="lazy" style="object-fit: contain; display: block; margin: 0 auto 16px;" />					<div class="terms-figure">{t('open_studio.terms_white')}</div>
					<div class="text-sm font-medium mb-2">{t('open_studio.terms_white_sub')}</div>
					<p class="text-xs text-[var(--text-muted)]">{t('open_studio.terms_white_desc')}</p>
				</div>
			</div>
		</div>
	</section>

	<!-- CTA -->
	<section class="px-4 py-16 sm:py-20">
		<div class="max-w-3xl mx-auto text-center">
			<div class="panel panel-mark p-10 sm:p-14">
				<h2 class="sec-h">{t('open_studio.final_title')}</h2>
				<p class="text-[var(--text-muted)] mb-8 max-w-lg mx-auto leading-relaxed">
					{t('open_studio.final_desc')}
				</p>

				<div class="flex flex-col sm:flex-row items-center justify-center gap-4">
					<a
						href="mailto:info@jazzchords.app?subject=Open%20Studio%20x%20Chord%20Trainer%20Demo"
						class="btn-stamp"
					>
						<Mail size={18} />
						{t('open_studio.cta_schedule')}
					</a>
					<a
						href="/embed?theme=openstudio&mode=2-5-1&voicing=shell"
						class="btn-rule"
					>
						{t('open_studio.cta_demo')}
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
	/* ── Press-shop chrome around the Open Studio mock ──────────────
	   The mock itself keeps its literal brand colours: it is a depiction
	   of their product, so it must stay accurate. Everything that is
	   *ours* is set in the editorial system. */
	.os {
		background: var(--bg);
	}

	.plate {
		font-family: var(--font-mono);
		font-size: 0.62rem;
		letter-spacing: 0.18em;
		text-transform: uppercase;
		color: var(--primary);
	}
	.plate-center {
		margin-bottom: 1.75rem;
	}

	.os-h1 {
		font-family: var(--font-display);
		font-size: clamp(2.1rem, 6vw, 3.6rem);
		font-weight: 600;
		line-height: 1.08;
		letter-spacing: -0.028em;
		margin-bottom: 1.5rem;
		text-wrap: balance;
	}
	/* The headline copy ships with the global .text-gradient class, which
	   paints red→amber. Amber is reserved for live/active state in this
	   direction, so the headline is pulled back to one flat stamp ink.
	   Scoped to this page — the global class is untouched for other pages. */
	.os-h1 :global(.text-gradient) {
		background: none;
		-webkit-background-clip: border-box;
		background-clip: border-box;
		-webkit-text-fill-color: var(--primary);
		color: var(--primary);
	}

	.sec-h {
		font-family: var(--font-display);
		font-size: clamp(1.5rem, 4vw, 2.15rem);
		font-weight: 600;
		line-height: 1.15;
		letter-spacing: -0.022em;
		text-align: center;
		margin-bottom: 1rem;
	}
	.sec-h-wide {
		margin-bottom: 2.5rem;
	}

	/* ── Panels ── */
	.panel {
		border: 1px solid var(--border);
		background: var(--bg-card);
		border-radius: 2px;
	}
	.panel-mark {
		border-color: color-mix(in srgb, var(--primary) 45%, transparent);
	}
	/* The opportunity note is annotation, so it takes the copyist's blue */
	.panel-note {
		border-left: 3px solid var(--ink-blue);
	}
	.panel-h {
		font-family: var(--font-display);
		font-size: 1.35rem;
		font-weight: 600;
		letter-spacing: -0.018em;
		color: var(--ink-blue);
		margin-bottom: 1rem;
	}
	.panel :global(.panel-h3),
	.panel-h3 {
		font-family: var(--font-display);
		font-size: 1.05rem;
		font-weight: 600;
		letter-spacing: -0.015em;
		margin-bottom: 0.5rem;
	}

	/* A ruled square holding the icon — not a rounded app tile */
	.icon-plate {
		width: 2.75rem;
		height: 2.75rem;
		display: flex;
		align-items: center;
		justify-content: center;
		margin: 0 auto 1rem;
		border: 1px solid color-mix(in srgb, var(--primary) 45%, transparent);
		background: var(--primary-muted);
	}

	/* ── Buttons ── */
	.btn-stamp,
	.btn-rule {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		min-height: var(--tap-min);
		padding: 0 1.75rem;
		border-radius: 2px;
		font-size: 0.95rem;
		font-weight: 600;
		text-decoration: none;
		transition: background 0.15s ease, border-color 0.15s ease, color 0.15s ease;
	}
	.btn-stamp {
		background: var(--primary);
		border: 1px solid var(--primary);
		color: var(--primary-text);
	}
	.btn-stamp:hover {
		background: var(--primary-hover);
		border-color: var(--primary-hover);
	}
	.btn-rule {
		background: transparent;
		border: 1px solid var(--border);
		color: var(--text-muted);
	}
	.btn-rule:hover {
		border-color: var(--text-muted);
		color: var(--text);
	}

	/* ── Tags: plate lines, not pills ── */
	.tag,
	.tag-mark {
		display: inline-block;
		font-family: var(--font-mono);
		font-size: 0.58rem;
		font-weight: 600;
		letter-spacing: 0.15em;
		text-transform: uppercase;
		padding: 0.25rem 0.5rem;
		border: 1px solid var(--border);
		color: var(--text-dim);
	}
	.tag {
		margin-bottom: 0.85rem;
	}
	.tag-stamp {
		border-color: color-mix(in srgb, var(--primary) 45%, transparent);
		color: var(--primary);
	}
	.tag-mark {
		position: absolute;
		top: 0.75rem;
		right: 0.75rem;
		border-color: color-mix(in srgb, var(--primary) 45%, transparent);
		background: var(--primary-muted);
		color: var(--primary);
	}

	.compare {
		border: 1px solid var(--border);
		background: var(--bg);
		border-radius: 2px;
	}
	.compare-mark {
		border-color: color-mix(in srgb, var(--primary) 40%, transparent);
		background: var(--primary-muted);
	}

	/* ── Benefits: a hairline register, no wash ── */
	.benefits {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1px;
		background: var(--border);
		border: 1px solid var(--border);
		margin-top: 1.5rem;
	}
	@media (max-width: 768px) {
		.benefits {
			grid-template-columns: 1fr;
		}
	}
	.benefit {
		display: flex;
		align-items: center;
		gap: 0.7rem;
		background: var(--bg-card);
		padding: 1.5rem 1.25rem;
		font-size: 0.88rem;
		font-weight: 500;
		color: var(--text);
	}

	.mock-frame {
		overflow: hidden;
		border: 1px solid var(--border);
		box-shadow: var(--shadow-lg);
		border-radius: 2px;
	}

	.terms-figure {
		font-family: var(--font-display);
		font-size: 2rem;
		font-weight: 600;
		line-height: 1.05;
		letter-spacing: -0.02em;
		color: var(--primary);
		margin-bottom: 0.5rem;
	}

	/* Active piano key highlights — kept in CSS for compound selector support */
	.os-key-active.os-key-white {
		background: var(--accent-gold) !important;
		box-shadow: 0 0 14px var(--accent-gold);
	}

	.os-key-active.os-key-black {
		background: var(--accent-amber) !important;
		box-shadow: 0 0 10px var(--accent-amber);
	}
</style>
