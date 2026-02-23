<script lang="ts">
	import { t } from '$lib/i18n';
	import type { HabitProfile, SmartGoal, QuickStartSuggestion, LevelInfo } from '$lib/engine/habits';
	import { getLevelInfo, getQuickStartSuggestion } from '$lib/engine/habits';
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

	function isToday(dayIndex: number): boolean {
		const jsDay = new Date().getDay();
		const mondayBased = jsDay === 0 ? 6 : jsDay - 1;
		return dayIndex === mondayBased;
	}

	let quickSuggestion: QuickStartSuggestion = $state({
		title: 'Warm-up',
		titleKey: 'habit.quick_warmup',
		titleParams: { minutes: 5 },
		description: '',
		descriptionKey: 'habit.quick_warmup_desc',
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

	const todayXP = $derived(profile.weeklyXP); // Simplified — shows weekly
	const activeGoals = $derived(profile.activeGoals.filter((g) => !g.completedAt));
</script>

<div class="habit-dashboard">
	<!-- Top row: greeting + level + MIDI -->
	<div class="dash-top">
		<div class="dash-left">
			<div class="greeting-row">
				<span class="greeting">{greeting}!</span>
				<span class="level-title-inline">{t(levelInfo.titleKey)}</span>
			</div>
			<div class="streak-level-row">
				<div class="streak-inline">
					<img src="/elements/images/streak-flame.webp" width="16" height="16" alt="" style="mix-blend-mode: lighten; object-fit: contain;" />
					<span class="streak-num">{streak.current}</span>
				</div>
				<span class="dot-sep">·</span>
				<LevelBadge totalXP={profile.totalXP} compact />
			</div>
		</div>
		<div class="midi-pill" class:connected={midiConnected}>
			<img src="/elements/images/midi-connect.webp" width="14" height="14" alt="MIDI" style="mix-blend-mode: lighten; object-fit: contain;" />
			<span>{midiConnected ? 'MIDI ✓' : 'No MIDI'}</span>
		</div>
	</div>

	<!-- Week dots with daily goal progress -->
	<div class="week-row">
		<div class="week-dots">
			{#each dayLabels as label, i}
				<div class="day-col">
					<span class="day-label">{label}</span>
					<div class="day-dot" class:practiced={weekDots[i]} class:today={isToday(i)}></div>
				</div>
			{/each}
		</div>
		<div class="week-xp">
			<span class="xp-amount">+{profile.weeklyXP}</span>
			<span class="xp-label">XP {t('habit.this_week') || 'this week'}</span>
		</div>
	</div>

	<!-- Smart Goals -->
	{#if activeGoals.length > 0}
		<div class="goals-section">
			<div class="goals-header">
				<span class="goals-title">🎯 {t('habit.your_goals') || 'Your Goals'}</span>
			</div>
			<div class="goals-list">
				{#each activeGoals.slice(0, 2) as goal (goal.id)}
					<GoalCard {goal} />
				{/each}
			</div>
		</div>
	{/if}

	<!-- Quick Start -->
	<button class="quick-start" onclick={() => onquickstart(quickSuggestion)}>
		<div class="quick-left">
			<span class="quick-icon">{quickSuggestion.icon}</span>
			<div class="quick-text">
				<span class="quick-title">{t(quickSuggestion.titleKey, quickSuggestion.titleParams) || quickSuggestion.title}</span>
				<span class="quick-desc">{quickSuggestion.minutes} min · {t(quickSuggestion.descriptionKey, quickSuggestion.descriptionParams) || quickSuggestion.description}</span>
			</div>
		</div>
		<span class="quick-arrow">→</span>
	</button>
</div>



<style>
	.habit-dashboard {
		display: flex;
		flex-direction: column;
		gap: 12px;
		padding: 18px 20px 20px;
		border-radius: var(--radius, 8px);
		background: rgba(255, 255, 255, 0.02);
		border: 1px solid var(--border, #222);
		margin-bottom: 20px;
	}

	.dash-top {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
	}

	.dash-left {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.greeting-row {
		display: flex;
		align-items: baseline;
		gap: 10px;
	}

	.greeting {
		font-size: 0.95rem;
		font-weight: 600;
		color: var(--text, #fff);
	}

	.level-title-inline {
		font-size: 0.7rem;
		font-weight: 500;
		color: #fb923c;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		opacity: 0.8;
	}

	.streak-level-row {
		display: flex;
		align-items: center;
		gap: 8px;
	}

	.streak-inline {
		display: flex;
		align-items: center;
		gap: 3px;
	}

	.streak-num {
		font-size: 0.8rem;
		font-weight: 700;
		color: #fb923c;
	}

	.dot-sep {
		color: var(--text-dim, #444);
		font-size: 0.7rem;
	}

	.midi-pill {
		display: flex;
		align-items: center;
		gap: 6px;
		padding: 4px 12px;
		border-radius: 999px;
		font-size: 0.7rem;
		background: rgba(255, 255, 255, 0.05);
		color: #555;
	}

	.midi-pill.connected {
		background: rgba(74, 222, 128, 0.1);
		color: #4ade80;
	}

	/* Week row */
	.week-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
	}

	.week-dots {
		display: flex;
		gap: 8px;
	}

	.day-col {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 4px;
	}

	.day-label {
		font-size: 0.55rem;
		color: var(--text-dim, #444);
		text-transform: uppercase;
		letter-spacing: 0.02em;
	}

	.day-dot {
		width: 10px;
		height: 10px;
		border-radius: 50%;
		background: rgba(255, 255, 255, 0.06);
		border: 1.5px solid rgba(255, 255, 255, 0.08);
		transition: all 0.3s ease;
	}

	.day-dot.practiced {
		background: #4ade80;
		border-color: #4ade80;
		box-shadow: 0 0 8px rgba(74, 222, 128, 0.35);
	}

	.day-dot.today:not(.practiced) {
		border-color: #fb923c;
		animation: pulse-dot 2s ease-in-out infinite;
	}

	@keyframes pulse-dot {
		0%, 100% { border-color: #fb923c; box-shadow: none; }
		50% { border-color: #fb923c; box-shadow: 0 0 8px rgba(251, 146, 60, 0.3); }
	}

	.week-xp {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 1px;
	}

	.xp-amount {
		font-size: 0.8rem;
		font-weight: 700;
		color: #fb923c;
		font-variant-numeric: tabular-nums;
	}

	.xp-label {
		font-size: 0.55rem;
		color: var(--text-dim, #444);
	}

	/* Goals */
	.goals-section {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.goals-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.goals-title {
		font-size: 0.75rem;
		font-weight: 600;
		color: var(--text-muted, #888);
	}

	.goals-list {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	/* Quick Start */
	.quick-start {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 10px;
		padding: 10px 14px;
		background: rgba(251, 146, 60, 0.06);
		border: 1px solid rgba(251, 146, 60, 0.15);
		border-radius: var(--radius, 8px);
		cursor: pointer;
		transition: all 0.2s ease;
		width: 100%;
		text-align: left;
		color: inherit;
		font-family: inherit;
	}

	.quick-start:hover {
		background: rgba(251, 146, 60, 0.14);
		border-color: rgba(251, 146, 60, 0.35);
		transform: translateY(-1px);
	}

	.quick-left {
		display: flex;
		align-items: center;
		gap: 10px;
		min-width: 0;
	}

	.quick-icon {
		font-size: 1rem;
		flex-shrink: 0;
	}

	.quick-text {
		display: flex;
		flex-direction: column;
		gap: 2px;
		min-width: 0;
	}

	.quick-title {
		font-size: 0.75rem;
		font-weight: 600;
		color: var(--text, #fff);
	}

	.quick-desc {
		font-size: 0.6rem;
		color: var(--text-muted, #888);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.quick-arrow {
		font-size: 1rem;
		color: #fb923c;
		font-weight: 700;
		flex-shrink: 0;
	}
</style>
