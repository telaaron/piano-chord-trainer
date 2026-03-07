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
		onstartplan,
	}: Props = $props();

	const VL_MODE_CONFIG: Record<VoiceLeadingMode, { labelKey: string; descKey: string; icon: string }> = {
		guided:          { labelKey: 'ui.vl_guided_label', descKey: 'ui.vl_guided_desc', icon: '👁️' },
		'find-inversion': { labelKey: 'ui.vl_find_label',  descKey: 'ui.vl_find_desc',   icon: '🔍' },
		free:            { labelKey: 'ui.vl_free_label',   descKey: 'ui.vl_free_desc',    icon: '🎹' },
	};

	let suggested: PracticePlan = $state(PRACTICE_PLANS[0]);

	onMount(() => {
		const recent = loadRecentPlanIds();
		// We need totalSessions but don't have it as prop — use recent length as proxy
		suggested = suggestPlan(recent, recent.length);
	});

	/** Helper: quick 2-col option grid item */
	function sel<T>(current: T, value: T): string {
		return current === value
			? 'border-[var(--primary)] bg-[var(--primary-muted)]'
			: 'border-[var(--border)] hover:border-[var(--border-hover)]';
	}

	const PLAN_ICON: Record<string, string> = {
		'warmup':            'icon-warm-up',
		'speed':             'icon-speed-run',
		'deepdive':          'icon-deep-dive',
		'turnaround':        'icon-turnaround',
		'challenge':         'icon-challenge',
		'quartenzirkel':     'icon-cycle',
		'voicing-drill':     'icon-voicing-drill',
		'left-hand-comping': 'icon-left-hand',
		'inversions-drill':  'icon-inversions',
		'in-time-comping':   'icon-in-time-comping',
		'ear-check':         'icon-ear-check',
		'adaptive-drill':    'icon-adaptive-drill',
		'voice-leading-flow':'icon-voice-leading-flow',
	};

	const LEVEL_CONFIG: Record<'beginner' | 'intermediate' | 'advanced', { color: string; shadow: string; dotsFilled: number }> = {
		beginner:     { color: '#4ade80', shadow: '0 0 18px rgba(74,222,128,0.15)',  dotsFilled: 2 },
		intermediate: { color: '#fb923c', shadow: '0 0 18px rgba(251,146,60,0.15)', dotsFilled: 3 },
		advanced:     { color: '#ef4444', shadow: '0 0 18px rgba(239,68,68,0.15)',  dotsFilled: 5 },
	};

</script>

<div class="space-y-6">
	<!-- ── Empfohlen ── -->
	<button
		class="card w-full p-5 sm:p-6 text-left cursor-pointer hover:border-[var(--border-hover)] transition-colors group relative"
		style="border-left: 3px solid {LEVEL_CONFIG[suggested.level].color}; box-shadow: {LEVEL_CONFIG[suggested.level].shadow};"
		onclick={() => onstartplan(suggested)}
	>
		<!-- Difficulty badge -->
		<div
			class="absolute top-3 right-3 uppercase font-medium"
			style="font-size: 0.65rem; letter-spacing: 0.05em; color: {LEVEL_CONFIG[suggested.level].color};"
		>
			{t('settings.difficulty_' + suggested.level)}
		</div>
		<div class="flex items-start gap-4">
			<img
				src="/elements/icons/{PLAN_ICON[suggested.id]}.webp"
				alt="{suggested.name}"
				width="52"
				height="52"
				loading="lazy"
				class="suggested-icon"
				style="width:52px; height:52px; mix-blend-mode:lighten; object-fit:contain; flex-shrink:0; filter: drop-shadow(0 0 10px rgba(251,146,60,0.5));"
			/>
			<div class="flex-1 min-w-0">
				<div class="text-xs text-[var(--text-dim)] font-medium mb-1">{t('settings.suggested_plan')}</div>
				<div class="text-xl font-bold group-hover:text-[var(--primary)] transition-colors">{t(suggested.name)}</div>
				<div class="text-sm text-[var(--text-muted)] mt-1">{t(suggested.tagline)}</div>
				<p class="text-xs text-[var(--text-dim)] mt-2 overflow-hidden transition-all duration-300 max-h-0 group-hover:max-h-24">{t(suggested.description)}</p>
			</div>
			<div class="text-[var(--primary)] text-2xl opacity-60 group-hover:opacity-100 transition-opacity self-center">▶</div>
		</div>
	</button>

		<!-- ── Practice Plans Grid ── -->
	<div>
		<h3 class="text-sm font-medium text-[var(--text-muted)] mb-3">{t('settings.all_plans')}</h3>
		<div class="plan-grid grid grid-cols-2 sm:grid-cols-3 gap-3">
			{#each PRACTICE_PLANS.filter((p) => p.id !== suggested.id) as plan}
				{#if plan.id === 'voice-leading-flow'}
					<!-- Voice Leading Flow: full-width card spanning all 3 columns with mode sub-cards -->
					<div
						class="vl-flow-card card text-left transition-all duration-200 relative"
						style="grid-column: 1 / -1; border-left: 3px solid {LEVEL_CONFIG[plan.level].color}; box-shadow: {LEVEL_CONFIG[plan.level].shadow};"
					>
						<div class="absolute top-3 right-3 uppercase font-medium" style="font-size: 0.65rem; letter-spacing: 0.05em; color: {LEVEL_CONFIG[plan.level].color};">
							{t('settings.difficulty_' + plan.level)}
						</div>
						<!-- Header: icon + name -->
						<div class="flex items-center gap-3 p-4 pb-3">
							<img src="/elements/icons/{PLAN_ICON[plan.id]}.webp" alt="{t(plan.name)}" width="44" height="44"
								loading="lazy" style="width:44px; height:44px; mix-blend-mode:lighten; object-fit:contain; flex-shrink:0; filter: drop-shadow(0 0 10px rgba(251,146,60,0.5));" />
							<div class="font-semibold text-sm">{t(plan.name)}</div>
						</div>
						<!-- 3 equal mode sub-cards -->
						<div class="grid grid-cols-3 gap-3 px-4 pb-4">
							{#each (['guided', 'find-inversion', 'free'] as VoiceLeadingMode[]) as mode}
								{@const cfg = VL_MODE_CONFIG[mode]}
								<button
									class="vl-mode-btn flex flex-col items-start p-3 rounded-[var(--radius)] border cursor-pointer transition-all text-left hover:scale-105 hover:z-10 {vlMode === mode ? 'border-[var(--primary)] bg-[var(--primary-muted)]' : 'border-[var(--border)] hover:border-[var(--border-hover)]'}"
									onclick={() => { vlMode = mode; onstartplan(plan); }}
								>
									<span class="vl-mode-icon text-2xl mb-2 leading-none">{cfg.icon}</span>
									<span class="vl-mode-label text-xs font-bold {vlMode === mode ? 'text-[var(--primary)]' : ''} mb-1">{t(cfg.labelKey)}</span>
									<span class="text-[10px] text-[var(--text-dim)] leading-snug">{t(cfg.descKey)}</span>
								</button>
							{/each}
						</div>
					</div>
				{:else}
					<button
					class="plan-card card p-4 text-left cursor-pointer transition-all duration-200 group relative hover:z-10 hover:scale-105 hover:border-[var(--border-hover)]"
					style="border-left: 3px solid {LEVEL_CONFIG[plan.level].color}; box-shadow: {LEVEL_CONFIG[plan.level].shadow};"
					onclick={() => onstartplan(plan)}
				>
					<div class="absolute top-2 right-2 uppercase font-medium" style="font-size: 0.65rem; letter-spacing: 0.05em; color: {LEVEL_CONFIG[plan.level].color};">
						{t('settings.difficulty_' + plan.level)}
					</div>
					<img src="/elements/icons/{PLAN_ICON[plan.id]}.webp" alt="{t(plan.name)}" width="56" height="56"
						loading="lazy" class="plan-icon" style="width:56px; height:56px; mix-blend-mode:lighten; object-fit:contain; margin-bottom:0.5rem; filter: drop-shadow(0 0 10px rgba(251,146,60,0.5));" />
					<div class="plan-name font-semibold text-sm group-hover:text-[var(--primary)] transition-colors">{t(plan.name)}</div>
						<div class="absolute inset-x-0 bottom-0 translate-y-full pt-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none z-20">
							<div class="rounded-[var(--radius)] border border-[var(--border-hover)] bg-[var(--bg-card,#1a1a1a)] p-3 shadow-xl"
								style="box-shadow: 0 8px 32px rgba(0,0,0,0.6), {LEVEL_CONFIG[plan.level].shadow};">
								<div class="text-xs font-medium text-[var(--text-muted)] mb-1">{t(plan.tagline)}</div>
								<div class="text-xs text-[var(--text-dim)] leading-snug">{t(plan.description)}</div>
							</div>
						</div>
					</button>
				{/if}
			{/each}
		</div>
	</div>

</div>

<style>
	/* ── iPad / large touch: native app feel ─────────────── */
	@media (hover: none) and (pointer: coarse) and (min-width: 768px) {
		/* 3-column grid, larger gap */
		.plan-grid {
			gap: 1rem;
		}

		/* Taller, more padded plan cards */
		.plan-card {
			padding: 1.25rem !important;
			min-height: 150px;
		}

		/* Bigger icons */
		.plan-icon {
			width: 76px !important;
			height: 76px !important;
			margin-bottom: 0.75rem !important;
		}

		/* Larger card name text */
		.plan-name {
			font-size: 1rem !important;
			font-weight: 700;
		}

		/* Disable hover scale on touch */
		.plan-card:hover {
			transform: none !important;
		}
		.plan-card:active {
			transform: scale(0.97) !important;
		}

		/* Bigger suggested plan icon */
		.suggested-icon {
			width: 72px !important;
			height: 72px !important;
		}

		/* Voice leading mode sub-cards */
		.vl-mode-btn {
			padding: 1rem !important;
		}
		.vl-mode-icon {
			font-size: 2rem !important;
			margin-bottom: 0.75rem !important;
		}
		.vl-mode-label {
			font-size: 0.875rem !important;
		}
		.vl-mode-btn span:last-child {
			font-size: 0.75rem !important;
		}
		.vl-mode-btn:hover {
			transform: none !important;
		}
		.vl-mode-btn:active {
			transform: scale(0.97) !important;
		}
		/* VL header icon */
		.vl-flow-card .flex img {
			width: 56px !important;
			height: 56px !important;
		}
		.vl-flow-card .flex .font-semibold {
			font-size: 1rem !important;
			font-weight: 700 !important;
		}
	}
</style>
