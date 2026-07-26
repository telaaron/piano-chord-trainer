<script lang="ts">
	import { page } from '$app/state';
	import { t } from '$lib/i18n';
	import { getCourse } from '$lib/courses';
	import { getCourseProgress } from '$lib/services/course-progress';
	import { courseCompletionPercent, moduleCompletionPercent, getNextLesson } from '$lib/engine/courses';
	import type { CourseProgress, MasteryLevel } from '$lib/engine/courses';
	import { Ruler, Piano, Rocket, BookOpen, Check, ArrowLeft, ArrowRight } from 'lucide-svelte';

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

	/** Roman numerals for the module section marks. */
	const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];

	const courseId = $derived(page.params.courseId ?? '');
	const course = $derived(getCourse(courseId));

	let progress = $state<CourseProgress | undefined>(undefined);

	$effect(() => {
		if (course) {
			progress = getCourseProgress(course);
		}
	});

	const percent = $derived(progress ? courseCompletionPercent(progress) : 0);
	const next = $derived(progress ? getNextLesson(course!, progress) : null);

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
	<title>{course ? t(course.titleKey) : 'Course'} – Chord Trainer</title>
        <meta name="robots" content="noindex" />
</svelte:head>

{#if !course}
	<main class="plate plate-empty">
		<p class="empty-note">{t('learn.not_found_course')}</p>
		<a class="crumb" href="/learn">
			<ArrowLeft size={14} aria-hidden="true" />
			{t('learn.back_to_courses')}
		</a>
	</main>
{:else}
	{@const CourseIcon = courseIcon(course.id)}
	<main class="plate">
		<a class="crumb" href="/learn">
			<ArrowLeft size={14} aria-hidden="true" />
			{t('learn.back_to_courses')}
		</a>

		<!-- ── Masthead ── -->
		<header class="masthead">
			<p class="plate-mark">{t('learn.plate_course')}</p>
			<h1>
				<CourseIcon size={26} class="course-icon" aria-hidden="true" />
				{t(course.titleKey)}
			</h1>
			<p class="lede">{t(course.subtitleKey)}</p>
			<p class="desc">{t(course.descriptionKey)}</p>

			<p class="course-meta">
				<span class="level">{levelLabel(course.level)}</span>
				<span class="rule" aria-hidden="true"></span>
				<span class="pct" class:done={percent === 100}>{percent}%</span>
			</p>
			<div
				class="meter meter-lg"
				class:done={percent === 100}
				role="progressbar"
				aria-valuenow={percent}
				aria-valuemin="0"
				aria-valuemax="100"
				aria-label={t('learn.plate_progress')}
			>
				<span style="width: {percent}%"></span>
			</div>
		</header>

		<!-- ── Modules as numbered plate sections ── -->
		{#each course.modules as mod, mi (mod.id)}
			{@const modProg = progress?.modules.find((m) => m.moduleId === mod.id)}
			{@const modPercent = modProg ? moduleCompletionPercent(modProg) : 0}

			<section class="module" aria-labelledby="mod-{mod.id}">
				<div class="module-head">
					<span class="rehearsal" aria-hidden="true">{ROMAN[mi] ?? mi + 1}</span>
					<div class="module-titles">
						<h2 id="mod-{mod.id}">{t(mod.titleKey)}</h2>
						<p class="module-meta">
							<span class="module-no">{t('learn.module_mark', { n: String(mi + 1) })}</span>
							<span class="rule" aria-hidden="true"></span>
							<span class="pct" class:done={modPercent === 100}>{modPercent}%</span>
						</p>
					</div>
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
					{#each mod.lessons as lesson, li (lesson.id)}
						{@const lp = modProg?.lessons.find((l) => l.lessonId === lesson.id)}
						{@const mastery = lp?.mastery ?? 'none'}
						{@const isNext = next?.lessonId === lesson.id}

						<li>
							<a class="entry" class:is-next={isNext} href="/learn/{course.id}/{lesson.id}">
								<span class="entry-no" aria-hidden="true">{String(li + 1).padStart(2, '0')}</span>
								<span class={masteryClass(mastery)} title={t(`learn.mastery_${mastery}`)}>
									{masteryIcon(mastery)}
								</span>
								<span class="entry-body">
									<span class="entry-title">{t(lesson.titleKey)}</span>
									<span class="entry-sub">{t(lesson.subtitleKey)}</span>
								</span>
								{#if mastery === 'mastered'}
									<span class="entry-flag mastered" title={t('learn.mastery_mastered')}>◆</span>
								{:else if isNext}
									<ArrowRight size={14} class="entry-go" aria-hidden="true" />
								{/if}
							</a>
						</li>
					{/each}
				</ol>
			</section>
		{/each}

		<!-- ── Foot ── -->
		<div class="plate-foot">
			{#if next}
				<a class="btn-stamp" href="/learn/{course.id}/{next.lessonId}">
					{percent > 0 ? t('learn.continue') : t('learn.start')}
					<ArrowRight size={15} aria-hidden="true" />
				</a>
			{:else if percent === 100}
				<span class="done-note">
					<Check size={16} aria-hidden="true" /> {t('learn.complete')}
				</span>
			{/if}
		</div>
	</main>
{/if}

<style>
	/* ═══ The plate ═══════════════════════════════════════════════ */
	.plate {
		max-width: 46rem;
		width: 100%;
		margin: 0 auto;
		padding: 2rem 1.25rem 5rem;
	}
	@media (min-width: 40rem) {
		.plate { padding: 2.5rem 2rem 6rem; }
	}
	.plate-empty { text-align: center; padding-top: 5rem; }
	.empty-note {
		font-family: var(--font-display);
		font-size: 1.125rem;
		color: var(--text-muted);
		margin: 0 0 1.25rem;
	}

	/* ── Breadcrumb ── */
	.crumb {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
		text-decoration: none;
		transition: color 0.15s;
	}
	.crumb:hover { color: var(--primary); }

	/* ── Masthead ── */
	.masthead {
		margin-top: 1.5rem;
		padding-bottom: 1.5rem;
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
		display: flex;
		align-items: center;
		gap: 0.7rem;
		font-family: var(--font-display);
		font-size: clamp(1.8rem, 5.2vw, 2.5rem);
		font-weight: 600;
		line-height: 1.1;
		letter-spacing: -0.025em;
		margin: 0;
		color: var(--text);
	}
	.masthead h1 :global(.course-icon) { color: var(--primary); flex: none; }
	.lede {
		margin: 0.75rem 0 0;
		max-width: 50ch;
		font-size: 1.0625rem;
		line-height: 1.6;
		color: var(--text-muted);
	}
	.desc {
		margin: 0.5rem 0 0;
		max-width: 62ch;
		font-size: 0.875rem;
		line-height: 1.6;
		color: var(--text-dim);
	}

	/* ── Meta rule line ── */
	.course-meta,
	.module-meta {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin: 1.25rem 0 0.5rem;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
	}
	.module-meta { margin: 0.35rem 0 0; }
	.level { color: var(--ink-blue); }
	.module-no { color: var(--ink-blue); flex: none; }
	.rule { flex: 1; height: 1px; background: var(--border); }
	.pct { color: var(--text-dim); font-variant-numeric: tabular-nums; flex: none; }
	.pct.done { color: var(--accent-green); }

	/* ── Meter ── */
	.meter {
		height: 2px;
		background: var(--border);
		overflow: hidden;
		margin-bottom: 0.9rem;
	}
	.meter-lg { height: 3px; margin-bottom: 0; }
	.meter span {
		display: block;
		height: 100%;
		background: var(--primary);
		transition: width 0.5s ease;
	}
	.meter.done span { background: var(--accent-green); }

	/* ── Module section ── */
	.module {
		padding-top: 2rem;
		margin-top: 2rem;
		border-top: 1px solid var(--border);
	}
	.module:first-of-type {
		padding-top: 0;
		margin-top: 0;
		border-top: 0;
	}
	.module-head {
		display: flex;
		align-items: flex-start;
		gap: 1rem;
		margin-bottom: 0.9rem;
	}
	.rehearsal {
		display: grid;
		place-items: center;
		flex: none;
		min-width: 1.75rem;
		height: 1.75rem;
		padding: 0 0.35rem;
		border: 1.5px solid var(--text);
		font-family: var(--font-mono);
		font-size: 0.6875rem;
		font-weight: 700;
		letter-spacing: 0.03em;
		color: var(--text);
	}
	.module-titles { flex: 1; min-width: 0; }
	.module-titles h2 {
		font-family: var(--font-display);
		font-size: 1.3125rem;
		font-weight: 600;
		line-height: 1.25;
		letter-spacing: -0.02em;
		margin: 0;
		color: var(--text);
	}

	/* ── Contents list ── */
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
		padding: 0.75rem 0.25rem;
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
	.entry-no {
		flex: none;
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.08em;
		color: var(--text-dim);
		font-variant-numeric: tabular-nums;
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
	.entry-flag { flex: none; font-size: 0.75rem; }
	.entry-flag.mastered { color: var(--accent-gold); }

	/* ── Foot ── */
	.plate-foot {
		margin-top: 2.5rem;
		padding-top: 1.5rem;
		border-top: 1px solid var(--border);
	}
	.btn-stamp {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		min-height: var(--tap-min);
		padding: 0 1.5rem;
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
		font-size: 0.9375rem;
		font-weight: 600;
		color: var(--accent-green);
	}
</style>
