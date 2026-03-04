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

<div class="habit-dashboard">
	<!-- Header row -->
	<div class="dash-top">
		<div class="dash-left">
			<div class="greeting-row">
				<span class="greeting">{greeting}!</span>
				<span class="rank-pill">{t(levelInfo.titleKey)}</span>
			</div>
			<div class="streak-level-row">
				<div class="streak-inline">
					<img src="/elements/images/streak-flame.webp" width="14" height="14" alt="" style="mix-blend-mode: lighten; object-fit: contain;" />
					<span class="streak-num">{streak.current}</span>
					<span class="streak-days">{streak.current === 1 ? 'Tag' : 'Tage'}</span>
				</div>
				<span class="dot-sep">·</span>
				<LevelBadge totalXP={profile.totalXP} compact />
			</div>
		</div>
		<div class="midi-pill" class:connected={midiConnected}>
			<img src="/elements/images/midi-connect.webp" width="12" height="12" alt="MIDI" style="mix-blend-mode: lighten; object-fit: contain;" />
			<span>{midiConnected ? 'MIDI ✓' : 'No MIDI'}</span>
		</div>
	</div>

	<!-- Daily Progress ring + motivation + week -->
	<div class="daily-section">
		<!-- Ring -->
		<div class="daily-ring-area">
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
			<div class="ring-label">
				{#if dailyProgress.goalMet}
					<span class="ring-check">✓</span>
				{:else}
					<span class="ring-num">{Math.floor(dailyProgress.practicedMinutes)}</span>
					<span class="ring-denom">/{dailyProgress.goalMinutes}m</span>
				{/if}
			</div>
		</div>

		<!-- Right: motivation + week strip -->
		<div class="daily-info">
			<p class="motivation-text" style="color: {motivationColor}">
				{motivation.emoji}&nbsp;{t(motivation.messageKey, motivation.messageParams)}
			</p>

			<div class="week-strip">
				<div class="week-dots">
					{#each dayLabels as label, i}
						<div class="day-col">
							<span class="day-label" class:day-today={isToday(i)}>{label}</span>
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
								<div class="day-dot" class:practiced={weekDots[i]} class:today={isToday(i)}></div>
							{/if}
						</div>
					{/each}
				</div>
				<div class="week-xp">
					<span class="xp-num">+{profile.weeklyXP}</span>
					<span class="xp-lbl">XP {t('habit.this_week') || 'this week'}</span>
				</div>
			</div>
		</div>
	</div>

	<!-- Goals -->
	{#if activeGoals.length > 0}
		<div class="goals-section">
			<span class="goals-title">🎯 {t('habit.your_goals') || 'Your Goals'}</span>
			<div class="goals-list">
				{#each activeGoals.slice(0, 2) as goal (goal.id)}
					<GoalCard {goal} />
				{/each}
			</div>
		</div>
	{/if}

	<!-- Quick Start CTA -->
	<button class="quick-start" onclick={() => onquickstart(quickSuggestion)}>
		<span class="qs-icon">{quickSuggestion.icon}</span>
		<div class="qs-text">
			<span class="qs-title">{t(quickSuggestion.titleKey, quickSuggestion.titleParams) || quickSuggestion.title}</span>
			<span class="qs-meta">{quickSuggestion.minutes} min · {t(quickSuggestion.descriptionKey, quickSuggestion.descriptionParams) || quickSuggestion.description}</span>
		</div>
		<span class="qs-cta">Start →</span>
	</button>
</div>

<style>
	.habit-dashboard {
		display: flex;
		flex-direction: column;
		gap: 14px;
		padding: 16px 18px 18px;
		border-radius: 10px;
		background: rgba(255, 255, 255, 0.025);
		border: 1px solid rgba(255, 255, 255, 0.07);
		margin-bottom: 20px;
	}

	/* ── Header ────────────────────────────────── */
	.dash-top {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
	}

	.dash-left {
		display: flex;
		flex-direction: column;
		gap: 5px;
	}

	.greeting-row {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.greeting {
		font-size: 1rem;
		font-weight: 700;
		color: var(--text, #fff);
		letter-spacing: -0.01em;
	}

	.rank-pill {
		font-size: 0.6rem;
		font-weight: 600;
		color: #fb923c;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		background: rgba(251, 146, 60, 0.12);
		border: 1px solid rgba(251, 146, 60, 0.22);
		border-radius: 999px;
		padding: 2px 7px;
	}

	.streak-level-row {
		display: flex;
		align-items: center;
		gap: 7px;
	}

	.streak-inline {
		display: flex;
		align-items: center;
		gap: 3px;
	}

	.streak-num {
		font-size: 0.82rem;
		font-weight: 700;
		color: #fb923c;
	}

	.streak-days {
		font-size: 0.68rem;
		color: rgba(251, 146, 60, 0.6);
		font-weight: 500;
	}

	.dot-sep {
		color: rgba(255, 255, 255, 0.15);
		font-size: 0.7rem;
	}

	.midi-pill {
		display: flex;
		align-items: center;
		gap: 5px;
		padding: 4px 10px;
		border-radius: 999px;
		font-size: 0.65rem;
		font-weight: 500;
		background: rgba(255, 255, 255, 0.04);
		border: 1px solid rgba(255, 255, 255, 0.06);
		color: rgba(255, 255, 255, 0.3);
	}

	.midi-pill.connected {
		background: rgba(74, 222, 128, 0.08);
		border-color: rgba(74, 222, 128, 0.2);
		color: #4ade80;
	}

	/* ── Daily progress section ────────────────── */
	.daily-section {
		display: flex;
		align-items: center;
		gap: 16px;
	}

	.daily-ring-area {
		position: relative;
		flex-shrink: 0;
		width: 62px;
		height: 62px;
	}

	.ring-arc {
		stroke: #fb923c;
		transition: stroke-dashoffset 0.9s cubic-bezier(0.4, 0, 0.2, 1);
	}

	.ring-arc.ring-done {
		stroke: #4ade80;
	}

	.ring-label {
		position: absolute;
		inset: 0;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 0;
		line-height: 1;
	}

	.ring-check {
		font-size: 1.3rem;
		color: #4ade80;
		font-weight: 700;
	}

	.ring-num {
		font-size: 1.1rem;
		font-weight: 800;
		color: #fb923c;
		font-variant-numeric: tabular-nums;
		line-height: 1;
	}

	.ring-denom {
		font-size: 0.6rem;
		color: rgba(255, 255, 255, 0.3);
		font-weight: 500;
		margin-top: 1px;
	}

	.daily-info {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 9px;
		min-width: 0;
	}

	.motivation-text {
		margin: 0;
		font-size: 0.78rem;
		font-weight: 600;
		line-height: 1.3;
		transition: color 0.4s ease;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	/* ── Week strip ────────────────────────────── */
	.week-strip {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 10px;
	}

	.week-dots {
		display: flex;
		gap: 7px;
	}

	.day-col {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 4px;
	}

	.day-label {
		font-size: 0.58rem;
		color: rgba(255, 255, 255, 0.28);
		text-transform: uppercase;
		letter-spacing: 0.02em;
		font-weight: 500;
	}

	.day-label.day-today {
		color: #fb923c;
	}

	.mini-arc {
		stroke: #fb923c;
		transition: stroke-dashoffset 0.6s ease-out;
	}

	.day-dot {
		width: 12px;
		height: 12px;
		border-radius: 50%;
		background: rgba(255, 255, 255, 0.05);
		border: 1.5px solid rgba(255, 255, 255, 0.09);
		transition: all 0.3s ease;
	}

	.day-dot.practiced {
		background: #4ade80;
		border-color: #4ade80;
		box-shadow: 0 0 8px rgba(74, 222, 128, 0.4);
	}

	.day-dot.today:not(.practiced) {
		border-color: rgba(251, 146, 60, 0.5);
	}

	.week-xp {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 1px;
		flex-shrink: 0;
	}

	.xp-num {
		font-size: 0.82rem;
		font-weight: 700;
		color: #fb923c;
		font-variant-numeric: tabular-nums;
	}

	.xp-lbl {
		font-size: 0.55rem;
		color: rgba(255, 255, 255, 0.25);
		white-space: nowrap;
	}

	/* ── Goals ─────────────────────────────────── */
	.goals-section {
		display: flex;
		flex-direction: column;
		gap: 7px;
	}

	.goals-title {
		font-size: 0.68rem;
		font-weight: 600;
		color: rgba(255, 255, 255, 0.35);
		text-transform: uppercase;
		letter-spacing: 0.06em;
	}

	.goals-list {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	/* ── Quick Start CTA ────────────────────────── */
	.quick-start {
		display: flex;
		align-items: center;
		gap: 12px;
		padding: 11px 14px;
		background: rgba(251, 146, 60, 0.07);
		border: 1px solid rgba(251, 146, 60, 0.18);
		border-radius: 8px;
		cursor: pointer;
		transition: background 0.18s ease, border-color 0.18s ease, transform 0.15s ease;
		width: 100%;
		text-align: left;
		color: inherit;
		font-family: inherit;
	}

	.quick-start:hover {
		background: rgba(251, 146, 60, 0.13);
		border-color: rgba(251, 146, 60, 0.32);
		transform: translateY(-1px);
	}

	.quick-start:active {
		transform: translateY(0);
	}

	.qs-icon {
		font-size: 1.1rem;
		flex-shrink: 0;
	}

	.qs-text {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 2px;
		min-width: 0;
	}

	.qs-title {
		font-size: 0.78rem;
		font-weight: 700;
		color: var(--text, #fff);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.qs-meta {
		font-size: 0.62rem;
		color: rgba(255, 255, 255, 0.38);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.qs-cta {
		font-size: 0.72rem;
		font-weight: 700;
		color: #fb923c;
		flex-shrink: 0;
		letter-spacing: 0.02em;
	}
</style>
