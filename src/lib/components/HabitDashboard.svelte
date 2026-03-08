<script lang="ts">
	import { t } from '$lib/i18n';
	import type { HabitProfile, SmartGoal, QuickStartSuggestion, LevelInfo, DailyProgress, DailyMotivation } from '$lib/engine/habits';
	import { getLevelInfo, getQuickStartSuggestion, getDailyProgress, getDailyMotivation } from '$lib/engine/habits';
	import type { StreakData, SessionResult } from '$lib/services/progress';
	import { loadHistory, loadStreak } from '$lib/services/progress';
	import GoalCard from './GoalCard.svelte';
	import LevelBadge from './LevelBadge.svelte';
	import { onMount } from 'svelte';

	interface Props {
		profile: HabitProfile;
		streak: StreakData;
		weekDots: boolean[];
		midiConnected: boolean;
		onquickstart: (suggestion: QuickStartSuggestion) => void;
	}

	let { profile, streak, weekDots, midiConnected, onquickstart }: Props = $props();

	const levelInfo: LevelInfo = $derived(getLevelInfo(profile.totalXP));
	const dailyProgress: DailyProgress = $derived(getDailyProgress(profile));
	const motivation: DailyMotivation = $derived(getDailyMotivation(profile, streak));

	/** Motivation text color based on state */
	const motivationColor = $derived.by(() => {
		switch (motivation.type) {
			case 'goal-reached':
			case 'extra-credit': return '#4ade80';
			case 'streak-at-risk': return '#fb923c';
			case 'almost-there': return '#e2e8f0';
			default: return '#94a3b8';
		}
	});

	function isToday(dayIndex: number): boolean {
		const jsDay = new Date().getDay();
		const mondayBased = jsDay === 0 ? 6 : jsDay - 1;
		return dayIndex === mondayBased;
	}

	/** SVG progress ring */
	const RING_SIZE = 62;
	const RING_STROKE = 5;
	const RING_RADIUS = (RING_SIZE - RING_STROKE) / 2;
	const RING_CIRCUMFERENCE = 2 * Math.PI * RING_RADIUS;
	const ringDashoffset = $derived(RING_CIRCUMFERENCE * (1 - dailyProgress.progressPercent / 100));

	let quickSuggestion: QuickStartSuggestion = $state({
		title: 'Warm-up',
		titleKey: 'habit.quick_warmup',
		titleParams: { minutes: 5 },
		description: '',
		descriptionKey: 'habit.quick_warmup_desc',
		descriptionParams: {},
		planId: 'warmup',
		minutes: 5,
		icon: '☀️',
	});

	onMount(() => {
		const history = loadHistory();
		const currentStreak = loadStreak();
		quickSuggestion = getQuickStartSuggestion(profile, history, currentStreak);
	});

	function greetingText(): string {
		const h = new Date().getHours();
		if (h < 12) return t('settings.greeting_morning');
		if (h < 18) return t('settings.greeting_afternoon');
		return t('settings.greeting_evening');
	}

	const greeting = greetingText();

	const dayLabels = [
		t('settings.week_mon'),
		t('settings.week_tue'),
		t('settings.week_wed'),
		t('settings.week_thu'),
		t('settings.week_fri'),
		t('settings.week_sat'),
		t('settings.week_sun'),
	];

	const activeGoals = $derived(profile.activeGoals.filter((g) => !g.completedAt));
</script>

<div class="habit-dashboard flex flex-col gap-3.5 max-sm:gap-3.25 p-[16px_18px_18px] max-sm:p-[14px_14px_16px] rounded-[10px] bg-[rgba(255,255,255,0.025)] border border-[rgba(255,255,255,0.07)] mb-5">
	<!-- Header row -->
	<div class="flex items-start justify-between">
		<div class="flex flex-col gap-1.25">
			<div class="flex items-center gap-2">
				<span class="greeting text-base max-sm:text-[1.1rem] font-bold text-(--text,#fff) tracking-[-0.01em]">{greeting}!</span>
				<span class="rank-pill text-[0.6rem] max-sm:text-[0.68rem] font-semibold text-[#fb923c] uppercase tracking-[0.06em] bg-[rgba(251,146,60,0.12)] border border-[rgba(251,146,60,0.22)] rounded-full py-0.5 px-1.75 max-sm:px-2">{t(levelInfo.titleKey)}</span>
			</div>
			<div class="flex items-center gap-1.75">
				<div class="flex items-center gap-0.75">
					<img src="/elements/images/streak-flame.webp" width="14" height="14" alt="" style="mix-blend-mode: lighten; object-fit: contain;" />
					<span class="streak-num text-[0.82rem] max-sm:text-[0.9rem] font-bold text-[#fb923c]">{streak.current}</span>
					<span class="streak-days text-[0.68rem] max-sm:text-[0.75rem] text-[rgba(251,146,60,0.6)] font-medium">{streak.current === 1 ? 'Tag' : 'Tage'}</span>
				</div>
				<span class="text-[0.7rem] text-[rgba(255,255,255,0.15)]">·</span>
				<LevelBadge totalXP={profile.totalXP} compact />
			</div>
		</div>
		<a href="/midi-test?tab=midi" class="midi-pill flex items-center gap-1.25 py-1 px-2.5 rounded-full text-[0.65rem] font-medium border no-underline hover:opacity-80 transition-opacity {midiConnected ? 'bg-[rgba(74,222,128,0.08)] border-[rgba(74,222,128,0.2)] text-[#4ade80]' : 'bg-[rgba(255,255,255,0.04)] border-[rgba(255,255,255,0.06)] text-[rgba(255,255,255,0.3)]'}">
			<img src="/elements/images/midi-connect.webp" width="12" height="12" alt="MIDI" style="mix-blend-mode: lighten; object-fit: contain;" />
			<span>{midiConnected ? 'MIDI ✓' : 'No MIDI'}</span>
		</a>
	</div>

	<!-- Daily Progress ring + motivation + week -->
	<div class="flex items-center gap-4">
		<!-- Ring -->
		<div class="daily-ring-area relative shrink-0 w-15.5 h-15.5 max-sm:w-17.5 max-sm:h-17.5 max-sm:[&_svg]:w-17.5 max-sm:[&_svg]:h-17.5">
			<svg viewBox="0 0 {RING_SIZE} {RING_SIZE}" width={RING_SIZE} height={RING_SIZE} style="display:block">
				<circle
					cx={RING_SIZE / 2} cy={RING_SIZE / 2} r={RING_RADIUS}
					fill="none" stroke="rgba(255,255,255,0.07)" stroke-width={RING_STROKE}
				/>
				<circle
					class="ring-arc" class:ring-done={dailyProgress.goalMet}
					cx={RING_SIZE / 2} cy={RING_SIZE / 2} r={RING_RADIUS}
					fill="none" stroke-width={RING_STROKE}
					stroke-dasharray={RING_CIRCUMFERENCE}
					stroke-dashoffset={ringDashoffset}
					stroke-linecap="round"
					transform="rotate(-90 {RING_SIZE / 2} {RING_SIZE / 2})"
				/>
			</svg>
			<div class="absolute inset-0 flex flex-col items-center justify-center gap-0 leading-none">
				{#if dailyProgress.goalMet}
					<span class="text-[1.3rem] text-[#4ade80] font-bold">✓</span>
				{:else}
					<span class="ring-num text-[1.1rem] max-sm:text-[1.2rem] font-extrabold text-[#fb923c] tabular-nums leading-none">{Math.floor(dailyProgress.practicedMinutes)}</span>
					<span class="ring-denom text-[0.6rem] max-sm:text-[0.65rem] text-[rgba(255,255,255,0.3)] font-medium mt-px">/{dailyProgress.goalMinutes}m</span>
				{/if}
			</div>
		</div>

		<!-- Right: motivation + week strip -->
		<div class="flex-1 flex flex-col gap-2.25 min-w-0">
			<p class="motivation-text m-0 text-[0.78rem] max-sm:text-[0.88rem] font-semibold leading-[1.3] transition-colors duration-400 ease-in-out whitespace-nowrap max-sm:whitespace-normal overflow-hidden text-ellipsis" style="color: {motivationColor}">
				{motivation.emoji}&nbsp;{t(motivation.messageKey, motivation.messageParams)}
			</p>

			<div class="flex items-center justify-between gap-2.5">
				<div class="week-dots flex gap-1.75 max-sm:gap-2">
					{#each dayLabels as label, i}
						<div class="flex flex-col items-center gap-1">
							<span class="day-label text-[0.58rem] max-sm:text-[0.64rem] uppercase tracking-[0.02em] font-medium {isToday(i) ? 'text-[#fb923c]' : 'text-[rgba(255,255,255,0.28)]'}">{label}</span>
							{#if isToday(i) && !weekDots[i]}
								<svg viewBox="0 0 16 16" width="16" height="16" style="display:block;overflow:visible">
									<circle cx="8" cy="8" r="6" fill="none" stroke="rgba(255,255,255,0.09)" stroke-width="2" />
									<circle
										class="mini-arc"
										cx="8" cy="8" r="6" fill="none"
										stroke-width="2" stroke-linecap="round"
										stroke-dasharray={2 * Math.PI * 6}
										stroke-dashoffset={2 * Math.PI * 6 * (1 - dailyProgress.progressPercent / 100)}
										transform="rotate(-90 8 8)"
									/>
								</svg>
							{:else}
								<div class="day-dot w-3 h-3 max-sm:w-3.25 max-sm:h-3.25 rounded-full border-[1.5px] transition-all duration-300 ease-in-out {weekDots[i] ? 'bg-[#4ade80] border-[#4ade80] shadow-[0_0_8px_rgba(74,222,128,0.4)]' : isToday(i) ? 'bg-[rgba(255,255,255,0.05)] border-[rgba(251,146,60,0.5)]' : 'bg-[rgba(255,255,255,0.05)] border-[rgba(255,255,255,0.09)]'}"></div>
							{/if}
						</div>
					{/each}
				</div>
				<div class="flex flex-col items-end gap-px shrink-0">
					<span class="xp-num text-[0.82rem] max-sm:text-[0.9rem] font-bold text-[#fb923c] tabular-nums">+{profile.weeklyXP}</span>
					<span class="xp-lbl text-[0.6rem] max-sm:text-[0.62rem] text-[rgba(255,255,255,0.25)] whitespace-nowrap">XP {t('habit.this_week') || 'this week'}</span>
				</div>
			</div>
		</div>
	</div>

	<!-- Goals -->
	{#if activeGoals.length > 0}
		<div class="flex flex-col gap-1.75">
			<span class="goals-title text-[0.68rem] max-sm:text-[0.74rem] font-semibold text-[rgba(255,255,255,0.35)] uppercase tracking-[0.06em]">🎯 {t('habit.your_goals') || 'Your Goals'}</span>
			<div class="flex flex-col gap-1.5">
				{#each activeGoals.slice(0, 2) as goal (goal.id)}
					<GoalCard {goal} />
				{/each}
			</div>
		</div>
	{/if}

	<!-- Quick Start CTA -->
	<button class="quick-start flex items-center gap-3 p-[11px_14px] max-sm:p-[12px_14px] bg-[rgba(251,146,60,0.07)] border border-[rgba(251,146,60,0.18)] rounded-lg cursor-pointer w-full text-left text-inherit font-[inherit] hover:bg-[rgba(251,146,60,0.13)] hover:border-[rgba(251,146,60,0.32)] hover:-translate-y-px active:translate-y-0" style="transition: background 0.18s ease, border-color 0.18s ease, transform 0.15s ease" onclick={() => onquickstart(quickSuggestion)}>
		<span class="qs-icon text-[1.1rem] max-sm:text-[1.2rem] shrink-0">{quickSuggestion.icon}</span>
		<div class="flex-1 flex flex-col gap-0.5 min-w-0">
			<span class="qs-title text-[0.78rem] max-sm:text-[0.85rem] font-bold text-(--text,#fff) whitespace-nowrap overflow-hidden text-ellipsis">{t(quickSuggestion.titleKey, quickSuggestion.titleParams) || quickSuggestion.title}</span>
			<span class="qs-meta text-[0.62rem] max-sm:text-[0.68rem] text-[rgba(255,255,255,0.38)] whitespace-nowrap overflow-hidden text-ellipsis">{quickSuggestion.minutes} min · {t(quickSuggestion.descriptionKey, quickSuggestion.descriptionParams) || quickSuggestion.description}</span>
		</div>
		<span class="qs-cta text-[0.72rem] max-sm:text-[0.78rem] font-bold text-[#fb923c] shrink-0 tracking-[0.02em]">Start →</span>
	</button>
</div>

<style>
	/* SVG stroke transitions — no Tailwind equivalent */
	.ring-arc {
		stroke: #fb923c;
		transition: stroke-dashoffset 0.9s cubic-bezier(0.4, 0, 0.2, 1);
	}

	.ring-arc.ring-done {
		stroke: #4ade80;
	}

	.mini-arc {
		stroke: #fb923c;
		transition: stroke-dashoffset 0.6s ease-out;
	}

	/* ── iPad / large touch devices: scale up for native feel ── */
	@media (hover: none) and (pointer: coarse) and (min-width: 768px) {
		.habit-dashboard {
			padding: 22px 24px 24px;
			gap: 18px;
		}

		.greeting {
			font-size: 1.35rem;
		}

		.rank-pill {
			font-size: 0.76rem;
			padding: 3px 10px;
		}

		.streak-num {
			font-size: 1.05rem;
		}

		.streak-days {
			font-size: 0.85rem;
		}

		.motivation-text {
			font-size: 1rem;
		}

		.daily-ring-area {
			width: 80px;
			height: 80px;
		}

		.daily-ring-area svg {
			width: 80px;
			height: 80px;
		}

		.ring-num {
			font-size: 1.4rem;
		}

		.ring-denom {
			font-size: 0.72rem;
		}

		.day-label {
			font-size: 0.68rem;
		}

		.day-dot {
			width: 15px;
			height: 15px;
		}

		.week-dots {
			gap: 10px;
		}

		.xp-num {
			font-size: 1rem;
		}

		.xp-lbl {
			font-size: 0.68rem;
		}

		.goals-title {
			font-size: 0.8rem;
		}

		.midi-pill {
			font-size: 0.78rem;
			padding: 5px 13px;
		}

		.quick-start {
			padding: 14px 18px;
			gap: 14px;
		}

		.qs-icon {
			font-size: 1.4rem;
		}

		.qs-title {
			font-size: 0.95rem;
		}

		.qs-meta {
			font-size: 0.75rem;
		}

		.qs-cta {
			font-size: 0.85rem;
		}
	}
</style>
