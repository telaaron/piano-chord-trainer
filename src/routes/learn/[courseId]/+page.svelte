<script lang="ts">
	import { page } from '$app/state';
	import { t } from '$lib/i18n';
	import { getCourse } from '$lib/courses';
	import { getCourseProgress, getLessonProgress } from '$lib/services/course-progress';
	import { courseCompletionPercent, moduleCompletionPercent, getNextLesson } from '$lib/engine/courses';
	import type { CourseProgress, MasteryLevel } from '$lib/engine/courses';

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
	<title>{course ? t(course.titleKey) : 'Course'} – Chord Trainer</title>
</svelte:head>

{#if !course}
	<main class="max-w-3xl mx-auto px-4 py-12 text-center">
		<p class="text-[var(--text-muted)]">Course not found.</p>
		<a href="/learn" class="text-[var(--primary)] hover:underline mt-4 inline-block">{t('learn.back_to_courses')}</a>
	</main>
{:else}
	<main class="max-w-3xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
		<!-- Breadcrumb -->
		<div class="mb-6">
			<a href="/learn" class="text-sm text-[var(--text-muted)] hover:text-[var(--primary)] transition-colors">
				{t('learn.back_to_courses')}
			</a>
		</div>

		<!-- Course header -->
		<div class="flex items-start gap-4 mb-8">
			<span class="text-4xl" role="img">{course.icon}</span>
			<div class="flex-1 min-w-0">
				<h1 class="text-xl sm:text-2xl font-bold text-[var(--text)]">
					{t(course.titleKey)}
				</h1>
				<p class="text-sm text-[var(--text-muted)] mt-1">{t(course.subtitleKey)}</p>
				<p class="text-xs text-[var(--text-dim)] mt-1">{t(course.descriptionKey)}</p>
				<div class="flex items-center gap-3 mt-3">
					<span class="text-xs px-2 py-0.5 rounded-sm bg-[var(--bg-muted)] text-[var(--text-muted)]">
						{levelLabel(course.level)}
					</span>
					<span class="text-xs text-[var(--text-dim)]">{percent}%</span>
				</div>
			</div>
		</div>

		<!-- Overall progress bar -->
		<div class="h-2 rounded-full bg-[var(--bg-muted)] overflow-hidden mb-8">
			<div
				class="h-full rounded-full transition-all duration-500"
				style="width: {percent}%; background: {percent === 100 ? 'var(--accent-green)' : 'var(--primary)'};"
			></div>
		</div>

		<!-- Modules -->
		<div class="space-y-6">
			{#each course.modules as mod (mod.id)}
				{@const modProg = progress?.modules.find((m) => m.moduleId === mod.id)}
				{@const modPercent = modProg ? moduleCompletionPercent(modProg) : 0}

				<div class="card p-5 sm:p-6">
					<div class="flex items-center justify-between mb-3">
						<h2 class="text-base font-semibold text-[var(--text)]">
							{t(mod.titleKey)}
						</h2>
						<span class="text-xs text-[var(--text-dim)]">{modPercent}%</span>
					</div>

					<!-- Module progress bar -->
					<div class="h-1.5 rounded-full bg-[var(--bg-muted)] overflow-hidden mb-4">
						<div
							class="h-full rounded-full transition-all duration-500"
							style="width: {modPercent}%; background: {modPercent === 100 ? 'var(--accent-green)' : 'var(--primary)'};"
						></div>
					</div>

					<!-- Lessons -->
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
								{#if mastery === 'mastered'}
									<span class="text-xs text-[var(--accent-gold)] font-medium shrink-0">◆</span>
								{:else if isNext}
									<span class="text-xs text-[var(--primary)] font-medium shrink-0">→</span>
								{/if}
							</a>
						{/each}
					</div>
				</div>
			{/each}
		</div>

		<!-- CTA -->
		<div class="mt-8 text-center">
			{#if next}
				<a
					href="/learn/{course.id}/{next.lessonId}"
					class="inline-flex items-center gap-2 px-6 py-3 rounded-lg bg-[var(--primary)] text-[var(--primary-text)] font-semibold text-sm hover:bg-[var(--primary-hover)] transition-colors"
				>
					{percent > 0 ? t('learn.continue') : t('learn.start')} →
				</a>
			{:else if percent === 100}
				<span class="text-sm text-[var(--accent-green)] font-medium">✓ {t('learn.complete')}</span>
			{/if}
		</div>
	</main>
{/if}
