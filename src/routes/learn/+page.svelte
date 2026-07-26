<script lang="ts">
	import { t } from '$lib/i18n';
	import { ALL_COURSES } from '$lib/courses';
	import { getCourseProgress } from '$lib/services/course-progress';
	import { courseCompletionPercent, moduleCompletionPercent, getNextLesson } from '$lib/engine/courses';
	import type { Course, CourseProgress, MasteryLevel } from '$lib/engine/courses';
	import { Ruler, Piano, Rocket, BookOpen, Play, ArrowRight, Check } from 'lucide-svelte';

	/** Pick a lucide icon component for a course by its id */
	function courseIcon(id: string) {
		switch (id) {
			case 'intervals': return Ruler;
			case 'shell-voicings': return Piano;
			case 'ultimate':
			case 'ultimate-plan': return Rocket;
			default: return BookOpen;
		}
	}

	/** Roman numerals for the section marks — the plate's rehearsal letters. */
	const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];

	// Load progress for all courses
	let progressMap = $state<Record<string, CourseProgress>>({});

	$effect(() => {
		const map: Record<string, CourseProgress> = {};
		for (const course of ALL_COURSES) {
			map[course.id] = getCourseProgress(course);
		}
		progressMap = map;
	});

	// ─── Global "continue where you left off" ──────────────────
	const globalContinue = $derived.by(() => {
		let best: { course: Course; lessonId: string; lessonTitle: string; lastActivity: number } | null = null;
		for (const course of ALL_COURSES) {
			const progress = progressMap[course.id];
			if (!progress) continue;
			const percent = courseCompletionPercent(progress);
			if (percent === 0 || percent === 100) continue; // skip untouched or finished
			const next = getNextLesson(course, progress);
			if (!next) continue;
			// find the lesson title
			let lessonTitle = '';
			for (const mod of course.modules) {
				const lesson = mod.lessons.find((l) => l.id === next.lessonId);
				if (lesson) { lessonTitle = t(lesson.titleKey); break; }
			}
			const latest = progress.lastActivityAt || 0;
			if (!best || latest > best.lastActivity) {
				best = { course, lessonId: next.lessonId, lessonTitle, lastActivity: latest };
			}
		}
		return best;
	});

	function masteryIcon(mastery: MasteryLevel): string {
		switch (mastery) {
			case 'none': return '○';
			case 'started': return '◐';
			case 'completed': return '●';
			case 'mastered': return '◆';
		}
	}

	function masteryClass(mastery: MasteryLevel): string {
		return `mk mk-${mastery}`;
	}

	function levelLabel(level: string): string {
		return t(`learn.level_${level}`);
	}
</script>

<svelte:head>
	<title>{t('learn.title')} – Chord Trainer</title>
	<meta name="description" content={t('learn.subtitle')} />
	<link rel="canonical" href="https://jazzchords.app/learn" />
</svelte:head>

<main class="plate">
	<!-- ── Masthead ── -->
	<header class="masthead">
		<p class="plate-mark">{t('learn.plate_curriculum')}</p>
		<h1>{t('learn.title')}</h1>
		<p class="lede">{t('learn.subtitle')}</p>
	</header>

	<!-- ── Continue where you left off — the one live element ── -->
	{#if globalContinue}
		<a class="resume" href="/learn/{globalContinue.course.id}/{globalContinue.lessonId}">
			<Play size={18} aria-hidden="true" />
			<span class="resume-body">
				<span class="resume-title">{t('learn.global_continue')}</span>
				<span class="resume-sub">
					{t('learn.global_continue_sub', { course: t(globalContinue.course.titleKey), lesson: globalContinue.lessonTitle })}
				</span>
			</span>
			<ArrowRight size={16} class="resume-go" aria-hidden="true" />
		</a>
	{/if}

	<!-- ── Courses as numbered plate sections ── -->
	{#each ALL_COURSES as course, ci (course.id)}
		{@const progress = progressMap[course.id]}
		{@const percent = progress ? courseCompletionPercent(progress) : 0}
		{@const next = progress ? getNextLesson(course, progress) : null}
		{@const CourseIcon = courseIcon(course.id)}

		<section class="course" aria-labelledby="course-{course.id}">
			<div class="course-head">
				<span class="rehearsal" aria-hidden="true">{ROMAN[ci] ?? ci + 1}</span>
				<div class="course-titles">
					<h2 id="course-{course.id}">
						<CourseIcon size={19} class="course-icon" aria-hidden="true" />
						<a href="/learn/{course.id}">{t(course.titleKey)}</a>
					</h2>
					<p class="course-sub">{t(course.subtitleKey)}</p>
					<p class="course-desc">{t(course.descriptionKey)}</p>
					<p class="course-meta">
						<span class="level">{levelLabel(course.level)}</span>
						<span class="rule" aria-hidden="true"></span>
						<span class="pct" class:done={percent === 100}>{percent}%</span>
					</p>
				</div>
			</div>

			<!-- Modules: annotated in copyist blue, lessons as a contents list -->
			{#each course.modules as mod, mi (mod.id)}
				{@const modProg = progress?.modules.find((m) => m.moduleId === mod.id)}
				{@const modPercent = modProg ? moduleCompletionPercent(modProg) : 0}

				<div class="module">
					<div class="module-head">
						<span class="module-no">{t('learn.module_mark', { n: String(mi + 1) })}</span>
						<h3>{t(mod.titleKey)}</h3>
						<span class="module-pct" class:done={modPercent === 100}>{modPercent}%</span>
					</div>
					<div
						class="meter"
						class:done={modPercent === 100}
						role="progressbar"
						aria-valuenow={modPercent}
						aria-valuemin="0"
						aria-valuemax="100"
						aria-label={t(mod.titleKey)}
					>
						<span style="width: {modPercent}%"></span>
					</div>

					<ol class="contents">
						{#each mod.lessons as lesson (lesson.id)}
							{@const lp = modProg?.lessons.find((l) => l.lessonId === lesson.id)}
							{@const mastery = lp?.mastery ?? 'none'}
							{@const isNext = next?.lessonId === lesson.id}

							<li>
								<a class="entry" class:is-next={isNext} href="/learn/{course.id}/{lesson.id}">
									<span class={masteryClass(mastery)} title={t(`learn.mastery_${mastery}`)}>
										{masteryIcon(mastery)}
									</span>
									<span class="entry-body">
										<span class="entry-title">{t(lesson.titleKey)}</span>
										<span class="entry-sub">{t(lesson.subtitleKey)}</span>
									</span>
									{#if isNext}
										<ArrowRight size={14} class="entry-go" aria-hidden="true" />
									{/if}
								</a>
							</li>
						{/each}
					</ol>
				</div>
			{/each}

			<div class="course-foot">
				{#if next}
					<a class="btn-stamp" href="/learn/{course.id}/{next.lessonId}">
						{percent > 0 ? t('learn.continue') : t('learn.start')}
						<ArrowRight size={15} aria-hidden="true" />
					</a>
				{:else if percent === 100}
					<span class="done-note">
						<Check size={15} aria-hidden="true" /> {t('learn.complete')}
					</span>
				{/if}
			</div>
		</section>
	{/each}
</main>

<style>
	/* ═══ The plate: an editorial page, not a card grid ═══════════ */
	.plate {
		max-width: 46rem;
		width: 100%;
		margin: 0 auto;
		padding: 2.5rem 1.25rem 5rem;
	}
	@media (min-width: 40rem) {
		.plate { padding: 3.5rem 2rem 6rem; }
	}

	/* ── Masthead ── */
	.masthead {
		padding-bottom: 1.75rem;
		border-bottom: 1px solid var(--border);
		margin-bottom: 2.5rem;
	}
	.plate-mark {
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.19em;
		text-transform: uppercase;
		color: var(--primary);
		font-weight: 600;
		margin: 0 0 0.75rem;
		display: flex;
		align-items: center;
		gap: 0.625rem;
	}
	.plate-mark::after {
		content: '';
		flex: 1;
		height: 1px;
		background: currentColor;
		opacity: 0.3;
	}
	.masthead h1 {
		font-family: var(--font-display);
		font-size: clamp(2rem, 6vw, 2.85rem);
		font-weight: 600;
		line-height: 1.08;
		letter-spacing: -0.025em;
		margin: 0;
		color: var(--text);
	}
	.lede {
		margin: 0.85rem 0 0;
		max-width: 46ch;
		font-size: 1.0625rem;
		line-height: 1.6;
		color: var(--text-muted);
	}

	/* ── Resume strip: amber = live, the only place it appears here ── */
	.resume {
		display: flex;
		align-items: center;
		gap: 0.875rem;
		padding: 0.9rem 1rem;
		margin-bottom: 2.75rem;
		text-decoration: none;
		color: var(--text);
		border: 1px solid var(--border);
		border-left: 3px solid var(--accent-amber);
		border-radius: var(--radius-sm);
		background: var(--bg-card);
		transition: border-color 0.15s, background 0.15s;
	}
	.resume:hover {
		border-color: var(--border-hover);
		border-left-color: var(--accent-amber);
		background: var(--bg-card-hover);
	}
	.resume :global(svg:first-child) { color: var(--accent-amber); flex: none; }
	.resume-body { flex: 1; min-width: 0; }
	.resume-title {
		display: block;
		font-size: 0.8125rem;
		font-weight: 600;
		color: var(--text);
	}
	.resume-sub {
		display: block;
		margin-top: 0.1rem;
		font-size: 0.8125rem;
		color: var(--text-muted);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.resume :global(.resume-go) { color: var(--text-dim); flex: none; }

	/* ── Course section ── */
	.course {
		padding-top: 2.25rem;
		margin-top: 2.25rem;
		border-top: 1px solid var(--border);
	}
	.course:first-of-type {
		padding-top: 0;
		margin-top: 0;
		border-top: 0;
	}
	.course-head {
		display: flex;
		align-items: flex-start;
		gap: 1rem;
	}
	.rehearsal {
		display: grid;
		place-items: center;
		flex: none;
		min-width: 1.75rem;
		height: 1.75rem;
		padding: 0 0.35rem;
		margin-top: 0.15rem;
		border: 1.5px solid var(--text);
		font-family: var(--font-mono);
		font-size: 0.6875rem;
		font-weight: 700;
		letter-spacing: 0.03em;
		color: var(--text);
	}
	.course-titles { flex: 1; min-width: 0; }
	.course-titles h2 {
		display: flex;
		align-items: center;
		gap: 0.55rem;
		font-family: var(--font-display);
		font-size: 1.5rem;
		font-weight: 600;
		line-height: 1.2;
		letter-spacing: -0.02em;
		margin: 0;
	}
	.course-titles h2 :global(.course-icon) { color: var(--primary); flex: none; }
	.course-titles h2 a {
		color: var(--text);
		text-decoration: none;
	}
	.course-titles h2 a:hover {
		color: var(--primary);
	}
	.course-sub {
		margin: 0.4rem 0 0;
		max-width: 58ch;
		font-size: 0.9375rem;
		line-height: 1.55;
		color: var(--text-muted);
	}
	.course-desc {
		margin: 0.3rem 0 0;
		max-width: 62ch;
		font-size: 0.8125rem;
		line-height: 1.55;
		color: var(--text-dim);
	}
	.course-meta {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin: 0.85rem 0 0;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
	}
	.level { color: var(--ink-blue); }
	.course-meta .rule {
		flex: 1;
		height: 1px;
		background: var(--border);
	}
	.pct { color: var(--text-dim); font-variant-numeric: tabular-nums; }
	.pct.done { color: var(--accent-green); }

	/* ── Module: blue annotation, hairline meter ── */
	.module { margin-top: 1.75rem; }
	.module-head {
		display: flex;
		align-items: baseline;
		gap: 0.75rem;
		margin-bottom: 0.5rem;
	}
	.module-no {
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.13em;
		text-transform: uppercase;
		color: var(--ink-blue);
		flex: none;
	}
	.module-head h3 {
		flex: 1;
		min-width: 0;
		font-family: var(--font-display);
		font-size: 1rem;
		font-weight: 600;
		letter-spacing: -0.01em;
		margin: 0;
		color: var(--text);
	}
	.module-pct {
		font-family: var(--font-mono);
		font-size: 0.625rem;
		color: var(--text-dim);
		font-variant-numeric: tabular-nums;
		flex: none;
	}
	.module-pct.done { color: var(--accent-green); }

	.meter {
		height: 2px;
		background: var(--border);
		overflow: hidden;
		margin-bottom: 0.75rem;
	}
	.meter span {
		display: block;
		height: 100%;
		background: var(--primary);
		transition: width 0.5s ease;
	}
	.meter.done span { background: var(--accent-green); }

	/* ── Contents list: the printed table of contents ── */
	.contents {
		list-style: none;
		margin: 0;
		padding: 0;
		border-top: 1px solid var(--border);
	}
	.contents li { border-bottom: 1px solid var(--border); }
	.entry {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 0.7rem 0.25rem;
		text-decoration: none;
		transition: background 0.12s, padding 0.12s;
	}
	.entry:hover {
		background: var(--bg-card);
		padding-left: 0.6rem;
		padding-right: 0.6rem;
	}
	.entry.is-next {
		background: var(--primary-muted);
		padding-left: 0.6rem;
		padding-right: 0.6rem;
		box-shadow: inset 2px 0 0 var(--primary);
	}
	.mk { flex: none; font-size: 0.8125rem; line-height: 1; }
	.mk-none { color: var(--text-dim); }
	.mk-started { color: var(--accent-amber); }
	.mk-completed { color: var(--accent-green); }
	.mk-mastered { color: var(--accent-gold); }

	.entry-body { flex: 1; min-width: 0; }
	.entry-title {
		display: block;
		font-size: 0.9375rem;
		line-height: 1.35;
		color: var(--text);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.entry-sub {
		display: block;
		margin-top: 0.05rem;
		font-size: 0.8125rem;
		line-height: 1.35;
		color: var(--text-dim);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.entry :global(.entry-go) { color: var(--primary); flex: none; }

	/* ── Foot ── */
	.course-foot { margin-top: 1.5rem; }
	.btn-stamp {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		min-height: var(--tap-min);
		padding: 0 1.25rem;
		border: 1.5px solid var(--primary);
		border-radius: var(--radius-sm);
		background: var(--primary);
		color: var(--primary-text);
		font-size: 0.9375rem;
		font-weight: 600;
		text-decoration: none;
		transition: background 0.15s, border-color 0.15s;
	}
	.btn-stamp:hover {
		background: var(--primary-hover);
		border-color: var(--primary-hover);
	}
	.done-note {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		font-size: 0.875rem;
		font-weight: 600;
		color: var(--accent-green);
	}
</style>
