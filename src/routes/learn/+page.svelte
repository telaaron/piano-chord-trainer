<script lang="ts">
	import { t } from '$lib/i18n';
	import { ALL_COURSES } from '$lib/courses';
	import { getCourseProgress, getLessonProgress } from '$lib/services/course-progress';
	import { courseCompletionPercent, moduleCompletionPercent, getNextLesson } from '$lib/engine/courses';
	import type { Course, CourseProgress, MasteryLevel } from '$lib/engine/courses';

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
		switch (mastery) {
			case 'none': return 'text-[var(--text-dim)]';
			case 'started': return 'text-[var(--accent-amber)]';
			case 'completed': return 'text-[var(--accent-green)]';
			case 'mastered': return 'text-[var(--accent-gold)]';
		}
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

<main class="max-w-3xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
	<!-- Header -->
	<div class="mb-8">
		<h1 class="text-2xl sm:text-3xl font-bold text-[var(--text)]">{t('learn.title')}</h1>
		<p class="mt-2 text-[var(--text-muted)] text-sm sm:text-base">{t('learn.subtitle')}</p>
	</div>

	<!-- Global "Continue where you left off" -->
	{#if globalContinue}
		<a
			href="/learn/{globalContinue.course.id}/{globalContinue.lessonId}"
			class="flex items-center gap-4 mb-8 p-4 sm:p-5 rounded-xl border border-[var(--primary)]/40 bg-[var(--primary-muted)] hover:bg-[var(--primary-muted)]/80 transition-colors"
		>
			<span class="text-2xl">▶</span>
			<div class="flex-1 min-w-0">
				<span class="text-sm font-bold text-[var(--primary)] block">{t('learn.global_continue')}</span>
				<span class="text-xs text-[var(--text-muted)] block truncate mt-0.5">
					{t('learn.global_continue_sub', { course: t(globalContinue.course.titleKey), lesson: globalContinue.lessonTitle })}
				</span>
			</div>
			<span class="text-[var(--primary)] text-lg shrink-0">→</span>
		</a>
	{/if}

	<!-- Course Cards -->
	<div class="space-y-6">
		{#each ALL_COURSES as course (course.id)}
			{@const progress = progressMap[course.id]}
			{@const percent = progress ? courseCompletionPercent(progress) : 0}
			{@const next = progress ? getNextLesson(course, progress) : null}
			
			<div class="card p-5 sm:p-6">
				<!-- Course header -->
				<div class="flex items-start gap-4">
					<span class="text-3xl" role="img">{course.icon}</span>
					<div class="flex-1 min-w-0">
						<h2 class="text-lg sm:text-xl font-bold text-[var(--text)]">
							{t(course.titleKey)}
						</h2>
						<p class="text-sm text-[var(--text-muted)] mt-0.5">{t(course.subtitleKey)}</p>
						<p class="text-xs text-[var(--text-dim)] mt-1">{t(course.descriptionKey)}</p>
						<span class="inline-block mt-2 text-xs px-2 py-0.5 rounded-sm bg-[var(--bg-muted)] text-[var(--text-muted)]">
							{levelLabel(course.level)}
						</span>
					</div>
				</div>

				<!-- Modules -->
				<div class="mt-5 space-y-3">
					{#each course.modules as mod (mod.id)}
						{@const modProg = progress?.modules.find((m) => m.moduleId === mod.id)}
						{@const modPercent = modProg ? moduleCompletionPercent(modProg) : 0}
						
						<div>
							<div class="flex items-center justify-between mb-2">
								<h3 class="text-sm font-medium text-[var(--text-muted)]">
									{t(mod.titleKey)}
								</h3>
								<span class="text-xs text-[var(--text-dim)]">{modPercent}%</span>
							</div>

							<!-- Progress bar -->
							<div class="h-1.5 rounded-full bg-[var(--bg-muted)] overflow-hidden mb-3">
								<div 
									class="h-full rounded-full transition-all duration-500"
									style="width: {modPercent}%; background: {modPercent === 100 ? 'var(--accent-green)' : 'var(--primary)'};"
								></div>
							</div>

							<!-- Lessons list -->
							<div class="space-y-1.5">
								{#each mod.lessons as lesson (lesson.id)}
									{@const lp = modProg?.lessons.find((l) => l.lessonId === lesson.id)}
									{@const mastery = lp?.mastery ?? 'none'}
									{@const isNext = next?.lessonId === lesson.id}

									<a
										href="/learn/{course.id}/{lesson.id}"
										class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors
											{isNext ? 'bg-[var(--primary-muted)] border border-[var(--primary)]/30' : 'hover:bg-[var(--bg-card-hover)]'}"
									>
										<span class="text-sm {masteryClass(mastery)}" title={t(`learn.mastery_${mastery}`)}>
											{masteryIcon(mastery)}
										</span>
										<div class="flex-1 min-w-0">
											<span class="text-sm text-[var(--text)] block truncate">{t(lesson.titleKey)}</span>
											<span class="text-xs text-[var(--text-dim)] block truncate">{t(lesson.subtitleKey)}</span>
										</div>
										{#if isNext}
											<span class="text-xs text-[var(--primary)] font-medium shrink-0">→</span>
										{/if}
									</a>
								{/each}
							</div>
						</div>
					{/each}
				</div>

				<!-- CTA -->
				<div class="mt-5 pt-4 border-t border-[var(--border)]/30">
					{#if next}
						<a
							href="/learn/{course.id}/{next.lessonId}"
							class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[var(--primary)] text-[var(--primary-text)] font-medium text-sm hover:bg-[var(--primary-hover)] transition-colors"
						>
							{percent > 0 ? t('learn.continue') : t('learn.start')}
						</a>
					{:else if percent === 100}
						<span class="text-sm text-[var(--accent-green)] font-medium">✓ {t('learn.complete')}</span>
					{/if}
				</div>
			</div>
		{/each}
	</div>
</main>
