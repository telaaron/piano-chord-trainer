<script lang="ts">
	import { t } from '$lib/i18n';
	import type { HabitProfile, SmartGoal, QuickStartSuggestion, LevelInfo, DailyProgress, DailyMotivation, MotivationType } from '$lib/engine/habits';
	import { getLevelInfo, getQuickStartSuggestion, getDailyProgress, getDailyMotivation } from '$lib/engine/habits';
	import type { StreakData, SessionResult } from '$lib/services/progress';
	import { loadHistory, loadStreak } from '$lib/services/progress';
	import GoalCard from './GoalCard.svelte';
	import LevelBadge from './LevelBadge.svelte';
	import { Icon } from '$lib/components/ui';
	import { onMount } from 'svelte';
	import { Flame, Piano, Star, PartyPopper, Dumbbell, Music, Check, ArrowRight, type Icon as LucideIcon } from 'lucide-svelte';

	/** Map a motivation type to its lucide icon component. */
	function motivationIcon(type: MotivationType): typeof LucideIcon {
		switch (type) {
			case 'streak-at-risk': return Flame;
			case 'not-started': return Piano;
			case 'extra-credit': return Star;
			case 'goal-reached': return PartyPopper;
			case 'almost-there': return Dumbbell;
			case 'just-started': return Music;
			default: return Music;
		}
	}

	/** plan id → Icon key (custom webp art); falls back to 'warmup'. */
	const PLAN_ICON_KEY: Record<string, string> = {
		warmup: 'warmup',
		speed: 'speed',
		deepdive: 'deep-dive',
		turnaround: 'turnaround',
		challenge: 'challenge',
		quartenzirkel: 'cycle',
		'voicing-drill': 'voicing-drill',
		'left-hand-comping': 'left-hand',
		'inversions-drill': 'inversions',
		'in-time-comping': 'in-time',
		'ear-check': 'ear-check',
		'adaptive-drill': 'weak-spots',
		'voice-leading-flow': 'voice-leading',
	};

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
	const MotivationIcon = $derived(motivationIcon(motivation.type));

	/**
	 * Motivation ink. Amber is the system's LIVE ink and is spent only on the
	 * one line that reports a live obligation — a streak about to lapse. A goal
	 * met is reported in green, and everything else is body copy: this line sits
	 * above the start button and must never out-shout it.
	 */
	const motivationColor = $derived.by(() => {
		switch (motivation.type) {
			case 'goal-reached':
			case 'extra-credit': return 'var(--accent-green)';
			case 'streak-at-risk': return 'var(--accent-amber)';
			case 'almost-there': return 'var(--text)';
			default: return 'var(--text-muted)';
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
		icon: '',
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

<!-- The masthead of the practice screen: who is reading, how the week has gone,
     and what today still owes. It is a printed header — a rule under it, figures
     in the display face — and deliberately quieter than the start button below. -->
<div class="hd">
	<!-- Masthead line: greeting + rank, MIDI state as a plate on the right -->
	<div class="mast">
		<div class="mast-l">
			<div class="name-row">
				<span class="greeting">{greeting}</span>
				<span class="rank plate">{t(levelInfo.titleKey)}</span>
			</div>
			<div class="meta-row">
				<span class="streak" class:live={streak.current > 0}>
					<Icon name="streak" size={13} />
					<span class="streak-n">{streak.current}</span>
					<span class="streak-u">{streak.current === 1 ? t('habit.day') : t('habit.days')}</span>
				</span>
				<span class="sep" aria-hidden="true">·</span>
				<LevelBadge totalXP={profile.totalXP} compact />
			</div>
		</div>
		<a href="/midi-test?tab=midi" class="midi plate" class:on={midiConnected}>
			<Icon name="midi" size={12} label="MIDI" />
			{#if midiConnected}
				<span class="midi-txt">MIDI <Check size={11} aria-hidden="true" /></span>
			{:else}
				<span class="midi-txt">{t('settings.no_midi')}</span>
			{/if}
		</a>
	</div>

	<!-- The day's ledger: minutes done against the goal, the week as a strip -->
	<div class="ledger">
		<div class="ring-area" aria-hidden="true">
			<svg viewBox="0 0 {RING_SIZE} {RING_SIZE}" width={RING_SIZE} height={RING_SIZE} style="display:block">
				<circle
					cx={RING_SIZE / 2} cy={RING_SIZE / 2} r={RING_RADIUS}
					fill="none" stroke="var(--border)" stroke-width={RING_STROKE}
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
			<div class="ring-mid">
				{#if dailyProgress.goalMet}
					<span class="ring-check"><Check size={22} aria-hidden="true" /></span>
				{:else}
					<span class="ring-num">{Math.floor(dailyProgress.practicedMinutes)}</span>
					<span class="ring-den">/{dailyProgress.goalMinutes}m</span>
				{/if}
			</div>
		</div>

		<div class="ledger-r">
			<p class="motiv" style="color: {motivationColor}">
				<MotivationIcon size={14} aria-hidden="true" class="shrink-0" />{t(motivation.messageKey, motivation.messageParams)}
			</p>

			<div class="week-row">
				<div class="week">
					{#each dayLabels as label, i}
						<div class="day">
							<span class="day-l" class:today={isToday(i)}>{label}</span>
							{#if isToday(i) && !weekDots[i]}
								<svg viewBox="0 0 16 16" width="16" height="16" style="display:block;overflow:visible">
									<circle cx="8" cy="8" r="6" fill="none" stroke="var(--border)" stroke-width="2" />
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
								<!-- A filled square, not a glass bead: the week reads as a
								     printed tally. Today's empty slot keeps an amber edge
								     because today is the live one. -->
								<span class="dot" class:done={weekDots[i]} class:today={isToday(i)}></span>
							{/if}
						</div>
					{/each}
				</div>
				<div class="xp">
					<span class="xp-n">+{profile.weeklyXP}</span>
					<span class="xp-l">XP {t('habit.this_week')}</span>
				</div>
			</div>
		</div>
	</div>

	<!-- Goals -->
	{#if activeGoals.length > 0}
		<div class="goals">
			<p class="eyebrow blue"><Icon name="weak-spots" size={13} /> {t('habit.your_goals')}</p>
			<div class="goal-list">
				{#each activeGoals.slice(0, 2) as goal (goal.id)}
					<GoalCard {goal} />
				{/each}
			</div>
		</div>
	{/if}

	<!-- The suggested resumption. A ruled row, not a second filled button —
	     the coach hero below owns the loud start; this is the alternative. -->
	<button class="resume" onclick={() => onquickstart(quickSuggestion)}>
		<span class="resume-icon" aria-hidden="true"><Icon name={PLAN_ICON_KEY[quickSuggestion.planId ?? ''] ?? 'warmup'} size={24} /></span>
		<span class="resume-txt">
			<span class="resume-t">{t(quickSuggestion.titleKey, quickSuggestion.titleParams) || quickSuggestion.title}</span>
			<span class="resume-m">{quickSuggestion.minutes} min · {t(quickSuggestion.descriptionKey, quickSuggestion.descriptionParams) || quickSuggestion.description}</span>
		</span>
		<span class="resume-go plate">{t('habit.start_arrow')} <ArrowRight size={13} aria-hidden="true" /></span>
	</button>
</div>

<style>
	/* The practice masthead on the editorial plate. Structure comes from a
	   hairline rule and the figures, not from a glass card — and nothing here
	   is allowed to be as loud as the start button underneath it. */

	.hd {
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		/* AccidentalFit is unicode-range-scoped, so it only ever claims ♭ ♯ ° ø;
		   every other character still comes from the normal stack below it. */
		--font-display-mus: 'AccidentalFit', var(--font-display);
		display: flex;
		flex-direction: column;
		gap: 1rem;
		padding-bottom: 1.1rem;
		border-bottom: 2px solid var(--text);
		font-family: 'AccidentalFit', var(--font-sans);
	}

	.plate {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	.eyebrow {
		display: flex;
		align-items: center;
		gap: 0.45rem;
		margin: 0;
		font-family: var(--font-mono);
		font-size: 0.62rem;
		font-weight: 600;
		letter-spacing: 0.17em;
		text-transform: uppercase;
		color: var(--primary);
	}
	.eyebrow.blue { color: var(--ink-blue); }

	/* ── Masthead ─────────────────────────────────────────────── */

	.mast {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 0.75rem;
	}
	.mast-l {
		display: flex;
		flex-direction: column;
		gap: 0.3rem;
		min-width: 0;
	}

	.name-row {
		display: flex;
		align-items: baseline;
		flex-wrap: wrap;
		gap: 0.6rem;
	}
	.greeting {
		font-family: var(--font-display-mus);
		font-size: clamp(1.3rem, 4.6vw, 1.7rem);
		font-weight: 600;
		line-height: 1.1;
		letter-spacing: -0.02em;
		color: var(--text);
	}
	/* The rank is a printed credit line, not a coloured pill. */
	.rank {
		padding-left: 0.65rem;
		border-left: 1px solid var(--border-hover);
		color: var(--ink-blue);
		letter-spacing: 0.16em;
	}

	.meta-row {
		display: flex;
		align-items: center;
		gap: 0.55rem;
		min-width: 0;
	}
	.streak {
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		color: var(--text-muted);
	}
	/* A running streak is a LIVE state — the one thing amber is for. */
	.streak.live { color: var(--accent-amber); }
	.streak-n {
		font-family: var(--font-display-mus);
		font-size: 1.02rem;
		font-weight: 700;
		font-variant-numeric: lining-nums tabular-nums;
		line-height: 1;
	}
	.streak-u {
		font-size: 0.74rem;
		font-weight: 500;
	}
	.sep { color: var(--text-dim); font-size: 0.7rem; }

	.midi {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		flex: none;
		padding: 0.3rem 0.55rem;
		border: 1px solid var(--border);
		border-radius: var(--radius-sm);
		text-decoration: none;
		transition: border-color 0.12s, color 0.12s;
	}
	.midi:hover { border-color: var(--border-hover); color: var(--text-muted); }
	.midi.on {
		border-color: color-mix(in srgb, var(--accent-green) 45%, transparent);
		color: var(--accent-green);
	}
	.midi-txt { display: inline-flex; align-items: center; gap: 0.25rem; }

	/* ── The day's ledger ─────────────────────────────────────── */

	.ledger {
		display: flex;
		align-items: center;
		gap: 1rem;
	}

	.ring-area {
		position: relative;
		flex: none;
		width: 62px;
		height: 62px;
	}
	.ring-mid {
		position: absolute;
		inset: 0;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		line-height: 1;
	}
	.ring-check { display: flex; color: var(--accent-green); }
	/* The figure is the point of the ring — display face, lining figures. */
	.ring-num {
		font-family: var(--font-display-mus);
		font-size: 1.24rem;
		font-weight: 700;
		font-variant-numeric: lining-nums tabular-nums;
		line-height: 1;
		color: var(--text);
	}
	.ring-den {
		margin-top: 1px;
		font-family: var(--font-mono);
		font-size: 0.56rem;
		letter-spacing: 0.06em;
		color: var(--text-dim);
	}

	.ledger-r {
		display: flex;
		flex-direction: column;
		gap: 0.6rem;
		flex: 1;
		min-width: 0;
	}

	.motiv {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		margin: 0;
		overflow: hidden;
		text-overflow: ellipsis;
		font-family: var(--font-display-mus);
		font-size: 0.95rem;
		font-style: italic;
		font-weight: 600;
		line-height: 1.35;
		transition: color 0.4s ease-in-out;
	}
	@media (max-width: 639px) {
		.motiv { white-space: normal; }
	}
	@media (min-width: 640px) {
		.motiv { white-space: nowrap; }
	}

	.week-row {
		display: flex;
		align-items: flex-end;
		justify-content: space-between;
		gap: 0.65rem;
	}
	.week {
		display: flex;
		gap: 0.45rem;
	}
	.day {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.25rem;
	}
	.day-l {
		font-family: var(--font-mono);
		font-size: 0.55rem;
		font-weight: 600;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	.day-l.today { color: var(--accent-amber); }

	/* Printed tally squares. Sharp corners, ink fill — no glow, no bead. */
	.dot {
		width: 0.7rem;
		height: 0.7rem;
		border: 1px solid var(--border);
		background: transparent;
		transition: background-color 0.3s ease, border-color 0.3s ease;
	}
	.dot.done {
		border-color: var(--accent-green);
		background: var(--accent-green);
	}
	.dot.today { border-color: var(--accent-amber); }

	.xp {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		flex: none;
	}
	.xp-n {
		font-family: var(--font-display-mus);
		font-size: 1rem;
		font-weight: 700;
		font-variant-numeric: lining-nums tabular-nums;
		line-height: 1.1;
		color: var(--text);
	}
	.xp-l {
		font-family: var(--font-mono);
		font-size: 0.55rem;
		letter-spacing: 0.1em;
		white-space: nowrap;
		color: var(--text-dim);
	}

	/* ── Goals ───────────────────────────────────────────────── */

	.goals {
		display: flex;
		flex-direction: column;
		gap: 0.45rem;
	}
	.goal-list {
		display: flex;
		flex-direction: column;
		gap: 0.4rem;
	}

	/* ── The suggested resumption ─────────────────────────────── */

	.resume {
		display: grid;
		grid-template-columns: auto minmax(0, 1fr) auto;
		gap: 0.75rem;
		align-items: center;
		width: 100%;
		min-height: var(--tap-min);
		padding: 0.7rem 0.25rem 0;
		border: 0;
		border-top: 1px solid var(--rule-soft);
		background: transparent;
		font-family: inherit;
		text-align: left;
		cursor: pointer;
		transition: background-color 0.12s;
	}
	.resume:hover { background: var(--bg-card); }
	.resume:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: -2px;
	}
	.resume-icon { display: flex; flex: none; }

	.resume-txt { min-width: 0; }
	.resume-t {
		display: block;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		font-family: var(--font-display-mus);
		font-size: 0.98rem;
		font-weight: 600;
		line-height: 1.25;
		color: var(--text);
	}
	.resume-m {
		display: block;
		margin-top: 0.1rem;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		font-size: 0.8rem;
		line-height: 1.4;
		color: var(--text-muted);
	}
	.resume-go {
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		white-space: nowrap;
	}
	.resume:hover .resume-go { color: var(--primary); }

	/* SVG stroke transitions — no Tailwind equivalent */
	.ring-arc {
		stroke: var(--primary);
		transition: stroke-dashoffset 0.9s cubic-bezier(0.4, 0, 0.2, 1);
	}
	.ring-arc.ring-done {
		stroke: var(--accent-green);
	}
	.mini-arc {
		stroke: var(--accent-amber);
		transition: stroke-dashoffset 0.6s ease-out;
	}

	/* ── iPad / large touch devices: scale up for native feel ── */
	@media (hover: none) and (pointer: coarse) and (min-width: 768px) {
		.hd { gap: 1.25rem; padding-bottom: 1.35rem; }
		.greeting { font-size: 1.85rem; }
		.rank { font-size: 0.68rem; }
		.streak-n { font-size: 1.15rem; }
		.streak-u { font-size: 0.85rem; }
		.motiv { font-size: 1.06rem; }
		.ring-area { width: 80px; height: 80px; }
		.ring-area svg { width: 80px; height: 80px; }
		.ring-num { font-size: 1.5rem; }
		.ring-den { font-size: 0.66rem; }
		.day-l { font-size: 0.64rem; }
		.dot { width: 0.85rem; height: 0.85rem; }
		.week { gap: 0.6rem; }
		.xp-n { font-size: 1.15rem; }
		.xp-l { font-size: 0.62rem; }
		.midi { font-size: 0.7rem; padding: 0.4rem 0.7rem; }
		.resume { gap: 0.9rem; padding-top: 0.9rem; }
		.resume-t { font-size: 1.1rem; }
		.resume-m { font-size: 0.85rem; }
	}

	@media (prefers-reduced-motion: reduce) {
		.ring-arc, .mini-arc, .motiv, .dot { transition: none; }
	}
</style>
