<svelte:head>
	<title>About – Chord Trainer</title>
	<meta name="description" content="Built at 2 AM because the tool didn't exist. Chord Trainer by Aaron Technologies OÜ." />
	<link rel="canonical" href="https://jazzchords.app/about" />
	<meta property="og:title" content="About – Chord Trainer" />
	<meta property="og:description" content="Built at 2 AM because the tool didn't exist. Chord Trainer by Aaron Technologies OÜ." />
	<meta property="og:url" content="https://jazzchords.app/about" />
</svelte:head>

<div class="about-page">

	<!-- ── 1. Hero ── -->
	<section class="about-hero">
		<img
			src="/elements/about/hero-keys-closeup.webp"
			alt=""
			aria-hidden="true"
			loading="eager"
			fetchpriority="high"
			class="about-hero-bg"
		/>
		<div class="about-hero-overlay"></div>
		<div class="about-hero-content">
			<p class="about-eyebrow">Aaron Technologies OÜ</p>
			<h1 class="about-hero-h1">
				Built at 2&nbsp;AM,<br>because the tool didn't exist.
			</h1>
		</div>
	</section>

	<!-- ── 2. Story ── -->
	<section class="about-story">
		<p>
			Every jazz teacher eventually says it:
			<strong class="accent">"Take it through all 12 keys."</strong>
			Every student nods — and then practices C major for another week.
		</p>
		<p>
			Not because they don't understand the voicing.
			Because there was no tool that made drilling all 12 keys
			fast, measurable, and actually engaging.
		</p>
		<p>
			Chord Trainer is that tool. MIDI-validated, timed per chord,
			weakness analysis built in. It works at 2&nbsp;AM when no class is running.
		</p>
	</section>

	<!-- ── 3. Company block ── -->
	<section class="about-company">
		<div class="company-col">
			<p class="col-label">The Company</p>
			<p class="col-body">
				Aaron Technologies OÜ<br>
				Registry: 17336129 · VAT: EE102955587<br>
				Tallinn, Estonia
			</p>
		</div>
		<div class="company-col">
			<p class="col-label">Contact</p>
			<p class="col-body">
				<a href="mailto:info@jazzchords.app">info@jazzchords.app</a><br>
				<a href="/impressum">Impressum</a><br>
				<a href="/privacy">Privacy Policy</a>
			</p>
		</div>
	</section>

</div>

<style>
	.about-page {
		flex: 1;
	}

	/* ── Hero ── */
	.about-hero {
		position: relative;
		min-height: 60vh;
		overflow: hidden;
		display: flex;
		align-items: flex-end;
	}

	.about-hero-bg {
		position: absolute;
		inset: 0;
		width: 100%;
		height: 100%;
		object-fit: cover;
		object-position: center 60%;
		z-index: 0;
		opacity: 0.55;
	}

	.about-hero-overlay {
		position: absolute;
		inset: 0;
		z-index: 1;
		background: linear-gradient(
			to bottom,
			rgba(0,0,0,0.1) 0%,
			rgba(0,0,0,0.4) 60%,
			rgba(0,0,0,1) 100%
		);
	}

	.about-hero-content {
		position: relative;
		z-index: 2;
		width: 100%;
		text-align: center;
		padding: 0 24px 60px;
	}

	.about-eyebrow {
		color: #fb923c;
		font-size: 0.85rem;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		margin-bottom: 16px;
	}

	.about-hero-h1 {
		font-size: clamp(2rem, 5vw, 3.5rem);
		font-weight: 700;
		color: #fff;
		max-width: 700px;
		margin: 0 auto;
		line-height: 1.15;
	}

	/* ── Story ── */
	.about-story {
		max-width: 680px;
		margin: 0 auto;
		padding: 80px 24px;
		display: flex;
		flex-direction: column;
		gap: 24px;
		font-size: 1.05rem;
		line-height: 1.8;
		color: var(--text-muted, rgba(255,255,255,0.7));
	}

	.about-story .accent {
		color: #fb923c;
		font-weight: 600;
	}

	/* ── Company block ── */
	.about-company {
		max-width: 680px;
		margin: 0 auto;
		padding: 48px 24px 80px;
		border-top: 1px solid rgba(255,255,255,0.08);
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 40px;
	}

	.col-label {
		color: #fb923c;
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		margin-bottom: 10px;
	}

	.col-body {
		font-size: 0.9rem;
		line-height: 1.8;
		color: var(--text-muted, rgba(255,255,255,0.6));
	}

	.col-body a {
		color: var(--text-muted, rgba(255,255,255,0.6));
		text-decoration: underline;
		text-underline-offset: 3px;
		transition: color 0.15s;
	}

	.col-body a:hover {
		color: #fff;
	}

	@media (max-width: 560px) {
		.about-company {
			grid-template-columns: 1fr;
			gap: 32px;
		}
	}
</style>
