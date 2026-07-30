<script lang="ts">
	import {
		CHORDS_BY_DIFFICULTY,
		VOICING_LABELS,
		PROGRESSION_LABELS,
		PRACTICE_PLANS,
		suggestPlan,
		type Difficulty,
		type NotationStyle,
		type VoicingType,
		type DisplayMode,
		type AccidentalPreference,
		type NotationSystem,
		type ProgressionMode,
		type PracticePlan,
		type VoiceLeadingMode,
	} from '$lib/engine';
	import { loadRecentPlanIds, type StreakData } from '$lib/services/progress';
	import type { MidiConnectionState, MidiDevice } from '$lib/services/midi';
	import { onMount } from 'svelte';
	import { t } from '$lib/i18n';
	import { Icon } from '$lib/components/ui';
	import { Eye, Search, Piano, Play, type Icon as LucideIcon } from 'lucide-svelte';

	interface Props {
		difficulty: Difficulty;
		notation: NotationStyle;
		voicing: VoicingType;
		displayMode: DisplayMode;
		accidentals: AccidentalPreference;
		notationSystem: NotationSystem;
		totalChords: number;
		progressionMode: ProgressionMode;
		midiEnabled: boolean;
		streak: StreakData;
		midiState: MidiConnectionState;
		midiDevices: MidiDevice[];
		/** In-Time mode toggle */
		inTimeMode: boolean;
		/** Bars per chord in In-Time mode (1, 2, or 4) */
		inTimeBars: number;
		/** Adaptive difficulty toggle */
		adaptiveEnabled: boolean;
		/** Voice leading visualization toggle */
		voiceLeadingEnabled: boolean;
		/** Voice leading sub-mode */
		vlMode: VoiceLeadingMode;
		/** Compact mode for calmer dashboard-first layout */
		compact?: boolean;
		onstartplan: (plan: PracticePlan) => void;
	}

	let {
		difficulty = $bindable(),
		notation = $bindable(),
		voicing = $bindable(),
		displayMode = $bindable(),
		accidentals = $bindable(),
		notationSystem = $bindable(),
		totalChords = $bindable(),
		progressionMode = $bindable(),
		midiEnabled = $bindable(),
		streak,
		midiState,
		midiDevices,
		inTimeMode = $bindable(),
		inTimeBars = $bindable(),
		adaptiveEnabled = $bindable(),
		voiceLeadingEnabled = $bindable(),
		vlMode = $bindable(),
		compact = false,
		onstartplan,
	}: Props = $props();

	const VL_MODE_CONFIG: Record<VoiceLeadingMode, { labelKey: string; descKey: string; icon: typeof LucideIcon }> = {
		guided:          { labelKey: 'ui.vl_guided_label', descKey: 'ui.vl_guided_desc', icon: Eye },
		'find-inversion': { labelKey: 'ui.vl_find_label',  descKey: 'ui.vl_find_desc',   icon: Search },
		free:            { labelKey: 'ui.vl_free_label',   descKey: 'ui.vl_free_desc',    icon: Piano },
	};

	let suggested: PracticePlan = $state(PRACTICE_PLANS[0]);
	let showPlanLibrary = $state(true);

	onMount(() => {
		const recent = loadRecentPlanIds();
		// We need totalSessions but don't have it as prop — use recent length as proxy
		suggested = suggestPlan(recent, recent.length);
	});

	$effect(() => {
		showPlanLibrary = !compact;
	});

	/** Helper: quick 2-col option grid item */
	function sel<T>(current: T, value: T): string {
		return current === value
			? 'border-[var(--primary)] bg-[var(--primary-muted)]'
			: 'border-[var(--border)] hover:border-[var(--border-hover)]';
	}

	/** plan id → semantic Icon name (see Icon.svelte for the full glyph map) */
	const PLAN_ICON: Record<string, string> = {
		'warmup':            'warmup',
		'speed':             'speed',
		'deepdive':          'deep-dive',
		'turnaround':        'turnaround',
		'challenge':         'challenge',
		'quartenzirkel':     'cycle',
		'voicing-drill':     'voicing-drill',
		'left-hand-comping': 'left-hand',
		'inversions-drill':  'inversions',
		'in-time-comping':   'in-time',
		'ear-check':         'ear-check',
		'adaptive-drill':    'adaptive',
		'voice-leading-flow':'voice-leading',
	};

	/**
	 * Level is printed, not glowed. Each level gets an ink and a count of filled
	 * marks — the same information the old coloured glow carried, but as type and
	 * a hairline rather than a halo. Green/amber/red are the semantic tokens; the
	 * grade is legible without relying on colour alone because the marks count.
	 */
	const LEVEL_CONFIG: Record<'beginner' | 'intermediate' | 'advanced', { color: string; marks: number }> = {
		beginner:     { color: 'var(--accent-green)', marks: 1 },
		intermediate: { color: 'var(--ink-blue)',     marks: 2 },
		advanced:     { color: 'var(--primary)',      marks: 3 },
	};

	/** The grade, printed as filled/empty marks: ▮▮▯ reads at 10px, a glow does not. */
	function marks(level: 'beginner' | 'intermediate' | 'advanced'): string {
		const n = LEVEL_CONFIG[level].marks;
		return '▮'.repeat(n) + '▯'.repeat(3 - n);
	}
</script>

<div class="gs">
	<!-- ── The recommendation: one ruled plate, the only accented thing here ── -->
	<section class="rec">
		<p class="eyebrow blue">{t('settings.suggested_plan')}</p>
		<button class="rec-btn" onclick={() => onstartplan(suggested)}>
			<Icon
				name={PLAN_ICON[suggested.id]}
				size={48}
				class="suggested-icon shrink-0"
				label={t(suggested.name)}
			/>
			<span class="rec-txt">
				<span class="rec-head">
					<span class="rec-name">{t(suggested.name)}</span>
					<span class="grade" style="color: {LEVEL_CONFIG[suggested.level].color}">
						<span class="grade-m" aria-hidden="true">{marks(suggested.level)}</span>
						<span class="grade-l">{t('settings.difficulty_' + suggested.level)}</span>
					</span>
				</span>
				<span class="rec-tag">{t(suggested.tagline)}</span>
				<span class="rec-desc">{t(suggested.description)}</span>
			</span>
			<span class="rec-go">
				<Play size={18} fill="currentColor" aria-hidden="true" />
				<span class="rec-go-l">{t('settings.start_training')}</span>
			</span>
		</button>
	</section>

	<!-- ── The library, as a printed index ── -->
	<section class="lib">
		<div class="lib-head">
			<p class="eyebrow">{t('settings.all_plans')}</p>
			<button class="toggle plate" onclick={() => (showPlanLibrary = !showPlanLibrary)}>
				{showPlanLibrary ? t('settings.fewer_plans') : t('settings.more_plans')}
			</button>
		</div>

		{#if !showPlanLibrary}
			<ol class="contents ruled">
				{#each PRACTICE_PLANS.filter((p) => p.id !== suggested.id).slice(0, 3) as quick, i (quick.id)}
					<li class="row">
						<button class="row-btn" onclick={() => onstartplan(quick)}>
							<span class="no">{String(i + 1).padStart(2, '0')}</span>
							<span class="row-icon" aria-hidden="true"><Icon name={PLAN_ICON[quick.id]} size={24} /></span>
							<span class="row-txt">
								<span class="ttl">{t(quick.name)}</span>
								<span class="dsc">{t(quick.tagline)}</span>
							</span>
							<span class="grade" style="color: {LEVEL_CONFIG[quick.level].color}">
								<span class="grade-m" aria-hidden="true">{marks(quick.level)}</span>
								<span class="grade-l">{t('settings.difficulty_' + quick.level)}</span>
							</span>
							<span class="go plate">{t('habit.start_arrow')}</span>
						</button>
					</li>
				{/each}
			</ol>
		{:else}
			<ol class="contents ruled">
				{#each PRACTICE_PLANS.filter((p) => p.id !== suggested.id) as plan, i (plan.id)}
					{#if plan.id === 'voice-leading-flow'}
						<!-- Voice Leading Flow carries three modes, so it is set as a
						     block entry: the plan line, then its modes indented under
						     it the way a score prints divisi. -->
						<li class="row block">
							<div class="row-btn as-head">
								<span class="no">{String(i + 1).padStart(2, '0')}</span>
								<span class="row-icon" aria-hidden="true"><Icon name={PLAN_ICON[plan.id]} size={24} /></span>
								<span class="row-txt">
									<span class="ttl">{t(plan.name)}</span>
									<span class="dsc">{t(plan.tagline)}</span>
								</span>
								<span class="grade" style="color: {LEVEL_CONFIG[plan.level].color}">
									<span class="grade-m" aria-hidden="true">{marks(plan.level)}</span>
									<span class="grade-l">{t('settings.difficulty_' + plan.level)}</span>
								</span>
							</div>
							<div class="modes">
								{#each (['guided', 'find-inversion', 'free'] as VoiceLeadingMode[]) as mode}
									{@const cfg = VL_MODE_CONFIG[mode]}
									{@const VlIcon = cfg.icon}
									<button
										class="mode"
										class:on={vlMode === mode}
										aria-pressed={vlMode === mode}
										onclick={() => { vlMode = mode; onstartplan(plan); }}
									>
										<span class="mode-icon" aria-hidden="true"><VlIcon size={20} /></span>
										<span class="mode-l">{t(cfg.labelKey)}</span>
										<span class="mode-d">{t(cfg.descKey)}</span>
									</button>
								{/each}
							</div>
						</li>
					{:else}
						<li class="row">
							<button class="row-btn" onclick={() => onstartplan(plan)}>
								<span class="no">{String(i + 1).padStart(2, '0')}</span>
								<span class="row-icon" aria-hidden="true"><Icon name={PLAN_ICON[plan.id]} size={24} /></span>
								<span class="row-txt">
									<span class="ttl">{t(plan.name)}</span>
									<span class="dsc">{t(plan.tagline)}</span>
								</span>
								<span class="grade" style="color: {LEVEL_CONFIG[plan.level].color}">
									<span class="grade-m" aria-hidden="true">{marks(plan.level)}</span>
									<span class="grade-l">{t('settings.difficulty_' + plan.level)}</span>
								</span>
								<span class="go plate">{t('habit.start_arrow')}</span>
							</button>
						</li>
					{/if}
				{/each}
			</ol>
		{/if}
	</section>
</div>

<style>
	/* The setup form on the editorial plate. This is SECONDARY furniture — it
	   sits behind a disclosure and must read as a printed index of plans, not
	   as a wall of glass cards competing with the start button above it. */

	.gs {
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		/* AccidentalFit is unicode-range-scoped, so it only ever claims ♭ ♯ ° ø;
		   every other character still comes from the normal stack below it. */
		--font-display-mus: 'AccidentalFit', var(--font-display);
		display: flex;
		flex-direction: column;
		gap: 1.85rem;
		font-family: 'AccidentalFit', var(--font-sans);
	}

	.eyebrow {
		display: flex;
		align-items: center;
		gap: 0.6rem;
		margin: 0 0 0.55rem;
		font-family: var(--font-mono);
		font-size: 0.63rem;
		font-weight: 600;
		letter-spacing: 0.18em;
		text-transform: uppercase;
		color: var(--primary);
	}
	.eyebrow::after {
		content: '';
		flex: 1;
		min-width: 1rem;
		height: 1px;
		background: currentColor;
		opacity: 0.32;
	}
	.eyebrow.blue { color: var(--ink-blue); }

	.plate {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	/* ── The recommendation ───────────────────────────────────── */

	.rec-btn {
		display: grid;
		grid-template-columns: auto minmax(0, 1fr);
		gap: 0.9rem;
		align-items: start;
		width: 100%;
		padding: 1rem;
		border: 1px solid var(--border);
		border-left: 3px solid var(--primary);
		background: var(--bg-card);
		font-family: inherit;
		text-align: left;
		cursor: pointer;
		transition: border-color 0.12s, background-color 0.12s;
	}
	.rec-btn:hover {
		border-color: var(--border-hover);
		border-left-color: var(--primary);
		background: var(--bg-card-hover);
	}
	.rec-btn:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: 2px;
	}

	.rec-txt { min-width: 0; }
	.rec-head {
		display: flex;
		align-items: baseline;
		flex-wrap: wrap;
		gap: 0.5rem 0.75rem;
	}
	.rec-name {
		font-family: var(--font-display-mus);
		font-size: 1.22rem;
		font-weight: 600;
		line-height: 1.2;
		letter-spacing: -0.015em;
		color: var(--text);
	}
	.rec-btn:hover .rec-name { color: var(--primary); }

	.rec-tag {
		display: block;
		margin-top: 0.3rem;
		font-family: var(--font-display-mus);
		font-size: 0.95rem;
		font-style: italic;
		line-height: 1.4;
		color: var(--text-muted);
	}
	.rec-desc {
		display: block;
		margin-top: 0.45rem;
		max-width: 54ch;
		font-size: 0.85rem;
		line-height: 1.55;
		color: var(--text-dim);
	}

	/* The recommendation's own action. Stamp-red outline — loud enough to be
	   found, quiet enough that the amber coach hero above still wins. */
	.rec-go {
		display: inline-flex;
		align-items: center;
		gap: 0.45rem;
		grid-column: 2;
		justify-self: start;
		margin-top: 0.85rem;
		min-height: var(--tap-min);
		padding: 0 1rem;
		border: 1.5px solid var(--primary);
		border-radius: var(--radius-sm);
		color: var(--primary);
		transition: background-color 0.12s, color 0.12s;
	}
	.rec-go-l {
		font-family: var(--font-mono);
		font-size: 0.64rem;
		font-weight: 700;
		letter-spacing: 0.14em;
		text-transform: uppercase;
	}
	.rec-btn:hover .rec-go {
		background: var(--primary);
		color: var(--primary-text);
	}

	/* ── The grade ────────────────────────────────────────────── */

	.grade {
		display: inline-flex;
		align-items: center;
		gap: 0.35rem;
		flex: none;
	}
	.grade-m {
		font-size: 0.6rem;
		letter-spacing: 0.06em;
		line-height: 1;
	}
	.grade-l {
		font-family: var(--font-mono);
		font-size: 0.58rem;
		font-weight: 600;
		letter-spacing: 0.13em;
		text-transform: uppercase;
	}

	/* ── The library index ────────────────────────────────────── */

	.lib-head {
		display: flex;
		align-items: center;
		gap: 0.85rem;
	}
	.lib-head .eyebrow { flex: 1; margin-bottom: 0; }

	.toggle {
		flex: none;
		padding: 0.4rem 0.7rem;
		border: 1px solid var(--border);
		border-radius: var(--radius-sm);
		background: transparent;
		cursor: pointer;
		transition: border-color 0.12s, color 0.12s;
	}
	.toggle:hover { border-color: var(--border-hover); color: var(--text); }
	.toggle:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: 2px;
	}

	.contents {
		list-style: none;
		margin: 0.6rem 0 0;
		padding: 0;
	}
	.contents.ruled { border-top: 1px solid var(--border); }

	.row { border-bottom: 1px solid var(--rule-soft); }

	.row-btn {
		display: grid;
		grid-template-columns: auto auto minmax(0, 1fr) auto auto;
		gap: 0.8rem;
		align-items: center;
		width: 100%;
		min-height: var(--tap-min);
		padding: 0.75rem 0.25rem;
		border: 0;
		background: transparent;
		font-family: inherit;
		text-align: left;
		cursor: pointer;
		transition: background-color 0.12s;
	}
	.row-btn:hover { background: var(--bg-card); }
	.row-btn:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: -2px;
	}
	/* The voice-leading header is a label, not a button: its modes are the
	   actions, so it must not look pressable. */
	.row-btn.as-head {
		grid-template-columns: auto auto minmax(0, 1fr) auto;
		cursor: default;
	}
	.row-btn.as-head:hover { background: transparent; }

	.no {
		font-family: var(--font-mono);
		font-size: 0.66rem;
		letter-spacing: 0.08em;
		font-variant-numeric: lining-nums tabular-nums;
		color: var(--text-dim);
	}
	.row-icon { display: flex; flex: none; }

	.row-txt { min-width: 0; }
	.ttl {
		display: block;
		font-family: var(--font-display-mus);
		font-size: 1rem;
		font-weight: 600;
		line-height: 1.25;
		color: var(--text);
	}
	.row-btn:hover .ttl { color: var(--primary); }
	.dsc {
		display: block;
		margin-top: 0.12rem;
		overflow: hidden;
		text-overflow: ellipsis;
		font-size: 0.82rem;
		line-height: 1.45;
		color: var(--text-muted);
	}

	.go { white-space: nowrap; }
	.row-btn:hover .go { color: var(--primary); }

	/* Narrow: the grade label and the GO plate would wrap the row — keep the
	   marks (which carry the level) and drop the words. */
	@media (max-width: 560px) {
		.row-btn { grid-template-columns: auto auto minmax(0, 1fr) auto; gap: 0.6rem; }
		.row-btn.as-head { grid-template-columns: auto auto minmax(0, 1fr) auto; }
		.grade-l { display: none; }
		.row-btn .go { display: none; }
		.dsc { white-space: nowrap; }
	}

	/* ── Voice-leading modes ──────────────────────────────────── */

	.modes {
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 0.5rem;
		margin: 0 0 0.8rem;
		padding-left: 1.5rem;
	}
	@media (max-width: 560px) {
		.modes { grid-template-columns: 1fr; padding-left: 0; }
	}

	.mode {
		display: flex;
		flex-direction: column;
		align-items: flex-start;
		gap: 0.3rem;
		min-height: var(--tap-min);
		padding: 0.65rem 0.7rem;
		border: 1px solid var(--border);
		border-radius: var(--radius-sm);
		background: transparent;
		font-family: inherit;
		text-align: left;
		cursor: pointer;
		transition: border-color 0.12s, background-color 0.12s, color 0.12s;
	}
	.mode:hover { border-color: var(--border-hover); background: var(--bg-card); }
	.mode:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: 2px;
	}
	/* The selected mode IS the live one — the reserved use of amber. */
	.mode.on {
		border-color: var(--accent-amber);
		background: color-mix(in srgb, var(--accent-amber) 10%, transparent);
	}
	.mode-icon { display: flex; color: var(--text-dim); }
	.mode.on .mode-icon { color: var(--accent-amber); }
	.mode-l {
		font-family: var(--font-display-mus);
		font-size: 0.92rem;
		font-weight: 600;
		line-height: 1.2;
		color: var(--text);
	}
	.mode.on .mode-l { color: var(--accent-amber); }
	.mode-d {
		font-size: 0.76rem;
		line-height: 1.4;
		color: var(--text-muted);
	}

	/* ── iPad / large touch: native app feel ─────────────────── */
	@media (hover: none) and (pointer: coarse) and (min-width: 768px) {
		.rec-name { font-size: 1.4rem; }
		.rec-tag { font-size: 1.02rem; }
		.ttl { font-size: 1.1rem; }
		.dsc { font-size: 0.9rem; }
		.row-btn { padding: 0.95rem 0.25rem; }
		:global(.suggested-icon) {
			width: 64px !important;
			height: 64px !important;
		}
		.mode { padding: 0.85rem; }
		.mode-l { font-size: 1rem; }
		.mode-d { font-size: 0.82rem; }
		.row-btn:hover, .mode:hover { background: transparent; }
		.row-btn:active { background: var(--bg-card); }
		.mode:active { background: var(--bg-card); }
	}

	@media (prefers-reduced-motion: reduce) {
		.rec-btn, .row-btn, .mode, .toggle, .rec-go { transition: none; }
	}
</style>
