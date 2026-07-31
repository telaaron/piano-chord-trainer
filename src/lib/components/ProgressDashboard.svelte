<script lang="ts">
	import { onMount } from 'svelte';
	import {
		loadHistory,
		loadVisibleHistory,
		computeStats,
		clearHistory,
		analyzeWeakChords,
		analyzeChordTrends,
		type SessionResult,
		type ProgressStats,
		type WeakChord,
		type ChordTrend,
	} from '$lib/services/progress';
	import { t, getLocale } from '$lib/i18n';
	import { Icon } from '$lib/components/ui';
	import { showLock, canUse } from '$lib/services/subscription-store.svelte';
	import { FREE_LIMITS } from '$lib/services/subscription';
	import { hasUsedTeaser, markTeaserUsed } from '$lib/utils/teaser';

	interface Props {
		/** Called by the empty-state CTA (e.g. start a first session). */
		onstart?: () => void;
		/** Called when a locked advanced block is tapped (opens upgrade sheet). */
		onupgrade?: () => void;
	}
	let { onstart, onupgrade }: Props = $props();

	// Advanced stats are Pro. Free users get one full look (the aha), then the
	// deep blocks lock — the basic metrics (sessions / chords / avg) stay free.
	let advancedLocked = $state(false);

	let history: SessionResult[] = $state([]);
	let stats: ProgressStats = $state(computeStats([]));
	let weakChords: WeakChord[] = $state([]);
	let chordTrends: ChordTrend[] = $state([]);
	let showHistory = $state(false);
	/** Sessions hidden by the free tier's rolling window — drives the hint below. */
	let hiddenByWindow = $state(0);

	onMount(() => {
		// Free tier sees a rolling window; nothing is deleted, only hidden.
		const fullHistoryAccess = canUse('full-history');
		history = loadVisibleHistory(fullHistoryAccess, FREE_LIMITS.historyDays);
		hiddenByWindow = fullHistoryAccess ? 0 : loadHistory().length - history.length;
		stats = computeStats(history);
		weakChords = analyzeWeakChords(history, 5);
		chordTrends = analyzeChordTrends(history);

		// First full view = the teaser. Lock the deep blocks only afterwards.
		if (showLock('advanced-stats')) {
			if (hasUsedTeaser('advanced-stats')) {
				advancedLocked = true;
			} else {
				markTeaserUsed('advanced-stats');
			}
		}
	});

	function handleClear() {
		if (confirm(t('ui.confirm_delete'))) {
			clearHistory();
			history = [];
			stats = computeStats([]);
			weakChords = [];
			chordTrends = [];
			hiddenByWindow = 0;
		}
	}

	function fmt(ms: number): string {
		const s = Math.floor(ms / 1000);
		const m = Math.floor(s / 60);
		const sec = s % 60;
		const cs = Math.floor((ms % 1000) / 10);
		return `${m}:${sec.toString().padStart(2, '0')}.${cs.toString().padStart(2, '0')}`;
	}

	function fmtDate(ts: number): string {
		return new Date(ts).toLocaleDateString(getLocale(), {
			day: '2-digit',
			month: '2-digit',
			hour: '2-digit',
			minute: '2-digit',
		});
	}

	/** Sparkline: last 10 sessions avg time */
	const sparkData = $derived.by(() => {
		const recent = stats.recentSessions.slice(0, 10).reverse();
		if (recent.length < 2) return null;
		const avgs = recent.map((s) => s.avgMs);
		const min = Math.min(...avgs);
		const range = (Math.max(...avgs) - min) || 1;
		return avgs.map((v, i) => ({
			height: 15 + ((v - min) / range) * 85,
			value: v,
			isLast: i === avgs.length - 1,
		}));
	});

	/**
	 * Trend: only meaningful when |change| > 8% AND absolute diff > 150ms.
	 * Requires at least 3 sessions in each window to reduce noise.
	 */
	const trend = $derived.by((): { pct: number; meaningful: boolean } | null => {
		const recent = stats.recentSessions.slice(0, 5);
		const older = stats.recentSessions.slice(5, 10);
		if (recent.length < 3 || older.length < 3) return null;
		const recentAvg = recent.reduce((s, r) => s + r.avgMs, 0) / recent.length;
		const olderAvg = older.reduce((s, r) => s + r.avgMs, 0) / older.length;
		const pct = ((recentAvg - olderAvg) / olderAvg) * 100;
		const absDiff = Math.abs(recentAvg - olderAvg);
		return { pct, meaningful: Math.abs(pct) > 8 && absDiff > 150 };
	});

	/**
	 * Improvements: show absolute old→new times, not raw %. Filter out
	 * suspiciously extreme changes (likely sparse old data artifacts).
	 */
	const improvements = $derived(
		chordTrends
			.filter((c) => c.changePercent < -5 && c.recentAvgMs > 200 && c.oldAvgMs > 300)
			.slice(0, 3)
	);

	/** Absolute bar scale: max is slowest chord floored at 2000ms so bars
	 *  don't all look 100% wide when times are close together. */
	function weakBarWidth(wc: WeakChord): number {
		const maxMs = Math.max(weakChords[0]?.avgMs ?? 1, 2000);
		return Math.min(100, (wc.avgMs / maxMs) * 100);
	}
</script>

{#if stats.totalSessions > 0}
	<!-- overflow-hidden because the glow below is deliberately positioned half
	     outside this box: 256px wide with translate-x-1/2, it reached 1307px in a
	     1280px viewport and gave the whole page a horizontal scrollbar. Clipping
	     it here keeps the effect and drops the overflow. -->
	<div class="card surface-glass p-5 sm:p-7 w-full space-y-8 sm:space-y-10 border-l-4 border-l-[var(--primary)] shadow-[0_0_30px_rgba(251,146,60,0.06)] relative overflow-hidden">

		<!-- Optional subtle background glow -->
		<div class="absolute top-0 right-0 w-64 h-64 bg-[var(--primary)]/5 blur-3xl rounded-full -translate-y-1/2 translate-x-1/2 pointer-events-none"></div>

		<!-- Top Row: Big Metrics -->
		<!-- pb-6, not pb-2: the rule reads as the floor of this group, so it needs
		     air above it rather than sitting tight under the labels. -->
		<div class="flex flex-wrap items-center justify-between gap-6 pb-6 border-b border-[var(--border)]/30">
			<!-- Metric 1: Sessions -->
			<div class="flex flex-col items-center flex-1 min-w-[80px]">
				<span class="text-3xl font-bold text-[var(--primary)] font-mono leading-none mb-1">{stats.totalSessions}</span>
				<span class="text-xs text-[var(--text-muted)] uppercase tracking-wider font-medium">{t('ui.sessions')}</span>
			</div>
			
			<div class="w-px h-10 bg-[var(--border)]/50"></div>

			<!-- Metric 2: Total Chords -->
			<div class="flex flex-col items-center flex-1 min-w-[80px]">
				<span class="text-3xl font-bold text-[var(--primary)] font-mono leading-none mb-1">{stats.totalChords}</span>
				<span class="text-xs text-[var(--text-muted)] uppercase tracking-wider font-medium text-center leading-tight whitespace-nowrap">{t('ui.chords_practiced')}</span>
			</div>

			<div class="w-px h-10 bg-[var(--border)]/50"></div>

			<!-- Metric 3: Avg Speed -->
			<div class="flex flex-col items-center flex-1 min-w-[80px]">
				<span class="text-3xl font-bold text-[var(--primary)] font-mono leading-none mb-1">{(stats.overallAvgMs / 1000).toFixed(1)}s</span>
				<span class="text-xs text-[var(--text-muted)] uppercase tracking-wider font-medium">{t('ui.avg_per_chord')}</span>
			</div>
		</div>

		<!-- ── Middle: Improvements + Weak Spots ── -->
		<!-- Advanced stats — Pro. Free users saw it once; now blurred + locked. -->
		<div class="relative">
		<div class={advancedLocked ? "pointer-events-none select-none blur-[6px] opacity-50" : ""}>
		<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">

			<!-- Improvements: show absolute old→new times -->
			{#if improvements.length > 0}
				<div class="bg-[var(--accent-green)]/10 border border-[var(--accent-green)]/20 rounded-[var(--radius)] p-4">
					<div class="flex items-center gap-2 mb-3">
						<Icon name="progress" size={18} />
						<span class="font-bold text-[var(--accent-green)] text-sm">{t('ui.getting_faster')}</span>
					</div>
					<div class="space-y-2">
						{#each improvements as imp}
						<div class="flex items-center justify-between gap-3">
							<strong class="text-[var(--text)] font-mono text-base shrink-0">{imp.root}</strong>
							<div class="flex items-center gap-1.5 text-xs whitespace-nowrap">
									<span class="text-[var(--text-dim)] font-mono line-through">{(imp.oldAvgMs / 1000).toFixed(1)}s</span>
									<span class="text-[var(--accent-green)] font-mono font-semibold">→ {(imp.recentAvgMs / 1000).toFixed(1)}s</span>
								</div>
							</div>
						{/each}
					</div>
				</div>
			{:else if stats.totalSessions > 3}
				<div class="bg-[var(--bg-muted)]/20 border border-[var(--border)] rounded-[var(--radius)] p-4 flex flex-col items-center justify-center gap-1.5 text-center min-h-[90px]">
					<Icon name="progress" size={26} class="opacity-50" />
					<span class="text-[var(--text-dim)] text-xs">{t('ui.more_sessions_needed')}</span>
				</div>
			{/if}

			<!-- Weak Chords: absolute bar scale, 3 chords instead of 2 -->
			{#if weakChords.length > 0}
				<div>
					<div class="flex items-center gap-2 mb-3">
						<Icon name="weak-spots" size={18} />
						<span class="font-medium text-sm text-[var(--text-muted)]">{t('ui.focus_on')}</span>
					</div>
					<div class="space-y-3">
						{#each weakChords.slice(0, 3) as wc}
							{@const w = weakBarWidth(wc)}
							<div>
								<div class="flex justify-between text-xs mb-1">
									<span class="font-mono font-semibold text-[var(--text)]">{wc.root}</span>
									<span class="font-mono text-[var(--accent-amber)]">{(wc.avgMs / 1000).toFixed(1)}s</span>
								</div>
								<div class="h-1.5 w-full bg-[var(--bg-muted)] rounded-full overflow-hidden">
									<div
										class="h-full bg-[var(--accent-amber)] rounded-full transition-all duration-500"
										style="width: {w}%"
									></div>
								</div>
							</div>
						{/each}
					</div>
				</div>
			{/if}
		</div>

		<!-- ── Bottom: Bar Chart ── -->
		{#if sparkData}
			<div class="bg-[var(--bg-muted)]/20 border border-[var(--border)] rounded-[var(--radius)] p-5 sm:p-6">
				<!-- Header -->
				<div class="flex justify-between items-start mb-5">
					<div>
						<div class="text-[var(--text-muted)] text-xs font-medium uppercase tracking-wide">{t('ui.sessions_label', { n: sparkData.length })}</div>
						<div class="text-[var(--text-dim)] text-xs mt-0.5">{t('ui.seconds_per_chord')}</div>
					</div>
					{#if trend !== null && trend.meaningful}
						<!-- amber for slower (not alarming red), green for faster -->
						<div class="text-right">
							<div class="text-xs font-semibold {trend.pct < 0 ? 'text-[var(--accent-green)]' : 'text-[var(--accent-amber)]'}">
								{trend.pct < 0 ? `↓ ${t('ui.faster')}` : `↑ ${t('ui.slower')}`}
							</div>
							<div class="text-[10px] text-[var(--text-dim)] font-mono mt-0.5">{t('ui.vs_before', { pct: Math.abs(trend.pct).toFixed(0) })}</div>
						</div>
					{:else if trend !== null}
						<div class="text-xs text-[var(--text-dim)]">→ {t('ui.same')}</div>
					{/if}
				</div>

				<!-- Bars: uniform color, last bar = accent, no random green outlier, no pulse -->
				<div class="flex items-end justify-between gap-1 sm:gap-1.5 h-20 w-full">
					{#each sparkData as bar}
						<div
							class="relative flex-1 flex flex-col justify-end h-full group/bar"
							title="{(bar.value / 1000).toFixed(2)}s"
						>
							<div class="absolute bottom-full mb-1.5 left-1/2 -translate-x-1/2 bg-[var(--bg-card)] border border-[var(--border)] text-[var(--text)] text-[10px] py-0.5 px-1.5 rounded opacity-0 group-hover/bar:opacity-100 transition-opacity whitespace-nowrap z-10 pointer-events-none shadow-md">
								{(bar.value / 1000).toFixed(2)}s
							</div>
							<div
								class="w-full rounded-t-sm transition-all duration-300 {bar.isLast ? 'bg-[var(--primary)]' : 'bg-[var(--primary)]/25 group-hover/bar:bg-[var(--primary)]/40'}"
								style="height: {bar.height}%"
							></div>
						</div>
					{/each}
				</div>

				<!-- X-axis label -->
				<div class="flex justify-between text-[10px] text-[var(--text-dim)] mt-2">
					<span>{t('ui.older')}</span>
					<span>{t('ui.now')}</span>
				</div>
			</div>
		{:else if stats.totalSessions > 0 && stats.totalSessions < 5}
			<div class="text-center py-2 text-[var(--text-dim)] text-xs">
				{t(5 - stats.totalSessions === 1 ? 'ui.sessions_until_chart' : 'ui.sessions_until_chart_plural', { n: 5 - stats.totalSessions })}
			</div>
		{/if}

		<!-- Footer: Best Times & History (Collapsible) -->
		<div class="space-y-5 pt-7 border-t border-[var(--border)]">
			
			<!-- Personal Bests Toggle -->
			{#if Object.keys(stats.personalBests).length > 0}
				<details class="group/bests text-sm">
					<summary class="flex items-center gap-2 cursor-pointer hover:text-[var(--primary-hover)] transition-colors list-none select-none">
						<Icon name="personal-best" size={20} />
						<span class="font-medium text-[var(--text-muted)] group-hover/bests:text-[var(--text)]">{t('ui.personal_bests')} ({Object.keys(stats.personalBests).length})</span>
						<span class="text-[var(--text-dim)] text-xs rotate-0 group-open/bests:rotate-180 transition-transform ml-auto">▼</span>
					</summary>

					<div class="mt-4 space-y-2 pl-2 border-l border-[var(--border)]/50 ml-2.5">
						{#each Object.entries(stats.personalBests).slice(0, 10) as [key, best]}
							{@const parts = key.split('-')}
							{@const diff = parts[0]}
							{@const voicingKey = parts.length >= 3 ? parts.slice(1, -1).join('-') : parts[1]}
							{@const mode = parts[parts.length - 1]}
							<div class="flex items-center justify-between text-xs py-1">
								<div class="flex items-center gap-2 text-[var(--text-dim)]">
									<span class="text-[var(--text-muted)] capitalize">{t('settings.difficulty_' + diff)}</span>
									<span>·</span>
									<span>{t('settings.voicing_' + voicingKey.toLowerCase().replace(/-/g, '_'))}</span>
								</div>
								<span class="font-mono font-semibold text-[var(--accent-green)]">{(best.avgMs / 1000).toFixed(2)}s</span>
							</div>
						{/each}
						
						<button 
							onclick={handleClear}
							class="text-[10px] text-[var(--text-dim)] hover:text-[var(--accent-red)] uppercase tracking-wider mt-4 block"
						>
							{t('ui.reset')}
						</button>
					</div>
				</details>
			{/if}

			<!-- History Toggle -->
			{#if history.length > 0}
				<details class="group/history text-sm" bind:open={showHistory}>
					<summary class="flex items-center gap-2 cursor-pointer hover:text-[var(--primary-hover)] transition-colors list-none select-none">
						<span class="text-lg leading-none grayscale opacity-70 group-hover/history:grayscale-0 group-hover/history:opacity-100 transition-all font-mono">▶</span>
						<span class="font-medium text-[var(--text-muted)] group-hover/history:text-[var(--text)]">{t('ui.recent_sessions')} ({Math.min(history.length, 20)})</span>
						<span class="text-[var(--text-dim)] text-xs rotate-0 group-open/history:rotate-180 transition-transform ml-auto">▼</span>
					</summary>

					<div class="mt-4 space-y-2 max-h-60 overflow-y-auto pr-2 custom-scrollbar">
						{#each history.slice(0, 20) as session}
							<div class="flex items-center justify-between text-xs bg-[var(--bg-muted)]/30 rounded px-3 py-2 border border-[var(--border)]/50 hover:border-[var(--border)] transition-colors">
								<div class="flex flex-col gap-0.5">
									<div class="font-medium text-[var(--text-muted)]">{fmtDate(session.timestamp)}</div>
									<div class="text-[var(--text-dim)] flex gap-1.5">
										<span>{session.totalChords} chd</span>
										<span>·</span>
										<span class="capitalize">{t('settings.difficulty_' + session.settings.difficulty)}</span>
									</div>
								</div>
								<div class="text-right">
									<div class="font-mono font-semibold text-[var(--text)]">{fmt(session.elapsedMs)}</div>
									{#if session.midi.enabled && session.midi.accuracy > 0}
										<div class="text-[10px] text-[var(--accent-green)]">{session.midi.accuracy}% acc</div>
									{/if}
								</div>
							</div>
						{/each}
					</div>
				</details>
			{/if}

			<!-- Rolling-window hint. Only ever shown when something is actually
			     hidden, and it says the sessions are kept, not lost. -->
			{#if hiddenByWindow > 0}
				<button
					type="button"
					onclick={() => onupgrade?.()}
					class="mt-3 w-full text-left text-xs text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors"
				>
					{t('ui.history_window_hint').replace('{days}', String(FREE_LIMITS.historyDays)).replace('{count}', String(hiddenByWindow))}
					<span class="text-[var(--accent-gold)] font-medium">{t('upgrade.cta_trial')} →</span>
				</button>
			{/if}

		</div>
		{#if advancedLocked}
			<button type="button" onclick={() => onupgrade?.()} class="absolute inset-0 z-10 flex flex-col items-center justify-center gap-2 rounded-[var(--radius-lg)] bg-[var(--bg)]/30 backdrop-blur-[1px] cursor-pointer">
				<span class="grid h-11 w-11 place-items-center rounded-full bg-[var(--accent-gold)]/15">
					<svg class="h-5 w-5 text-[var(--accent-gold)]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>
				</span>
				<span class="text-sm font-semibold text-[var(--text)]">{t("upgrade.lock_stats_title")}</span>
				<span class="text-xs text-[var(--accent-gold)] font-medium">{t("upgrade.cta_trial")} →</span>
			</button>
		{/if}
		</div>
		</div>
	</div>
{:else}
	<!-- Empty state — insights fill up once the player has sessions -->
	<div class="card surface-glass flex flex-col items-center gap-3 rounded-2xl p-8 text-center sm:p-10">
		<div class="grid h-16 w-16 place-items-center rounded-2xl bg-[var(--primary-muted)]">
			<Icon name="progress" size={40} glow />
		</div>
		<h3 class="text-lg font-bold text-[var(--text)]">{t('ui.insights_empty_title')}</h3>
		<p class="max-w-sm text-sm leading-relaxed text-[var(--text-muted)]">{t('ui.insights_empty_desc')}</p>
		{#if onstart}
			<button class="pill-btn pill-btn-primary mt-1 px-5 py-2.5 text-sm" onclick={onstart}>
				{t('ui.insights_empty_cta')}
			</button>
		{/if}
	</div>
{/if}

<style>
	/* Custom scrollbar for history list */
	.custom-scrollbar::-webkit-scrollbar {
		width: 4px;
	}
	.custom-scrollbar::-webkit-scrollbar-track {
		background: transparent;
	}
	.custom-scrollbar::-webkit-scrollbar-thumb {
		background: var(--border);
		border-radius: 4px;
	}
	.custom-scrollbar::-webkit-scrollbar-thumb:hover {
		background: var(--border-hover);
	}
</style>
