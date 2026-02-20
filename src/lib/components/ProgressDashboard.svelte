<script lang="ts">
	import { onMount } from 'svelte';
	import {
		loadHistory,
		computeStats,
		clearHistory,
		analyzeWeakChords,
		analyzeChordTrends,
		type SessionResult,
		type ProgressStats,
		type WeakChord,
		type ChordTrend,
	} from '$lib/services/progress';
	import { PROGRESSION_LABELS, VOICING_LABELS } from '$lib/engine';
	import { t, getLocale } from '$lib/i18n';

	let history: SessionResult[] = $state([]);
	let stats: ProgressStats = $state(computeStats([]));
	let weakChords: WeakChord[] = $state([]);
	let chordTrends: ChordTrend[] = $state([]);
	let showHistory = $state(false);

	onMount(() => {
		history = loadHistory();
		stats = computeStats(history);
		weakChords = analyzeWeakChords(history, 5);
		chordTrends = analyzeChordTrends(history);
	});

	function handleClear() {
		if (confirm(t('ui.confirm_delete'))) {
			clearHistory();
			history = [];
			stats = computeStats([]);
			weakChords = [];
			chordTrends = [];
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

	/** Simple sparkline: last 10 sessions avg time, visualized as blocks */
	const sparkData = $derived.by(() => {
		const recent = stats.recentSessions.slice(0, 10).reverse();
		if (recent.length < 2) return null;
		const avgs = recent.map((s) => s.avgMs);
		const max = Math.max(...avgs);
		const min = Math.min(...avgs);
		const range = max - min || 1;
		return avgs.map((v) => ({
			height: 20 + ((v - min) / range) * 80,
			value: v,
		}));
	});

	const trend = $derived.by(() => {
		const recent = stats.recentSessions.slice(0, 5);
		const older = stats.recentSessions.slice(5, 10);
		if (recent.length < 2 || older.length < 2) return null;
		const recentAvg = recent.reduce((s, r) => s + r.avgMs, 0) / recent.length;
		const olderAvg = older.reduce((s, r) => s + r.avgMs, 0) / older.length;
		const diff = ((recentAvg - olderAvg) / olderAvg) * 100;
		return diff;
	});

	/** Most improved root notes */
	const improvements = $derived(chordTrends.filter((t) => t.changePercent < -10).slice(0, 3));
</script>

{#if stats.totalSessions > 0}
	<div class="card p-5 sm:p-6 max-w-2xl mx-auto space-y-5" style="border-left: 3px solid #fb923c; box-shadow: 0 0 24px rgba(251,146,60,0.08);">
		<div class="flex items-center justify-between">
			<h3 class="text-lg font-bold flex items-center gap-2">
				<img src="/elements/icons/icon-progress.webp" alt="Your Progress" width="36" height="36" loading="lazy" style="width:36px;height:36px;mix-blend-mode:lighten; object-fit:contain; display:inline-block; vertical-align:middle; filter: drop-shadow(0 0 10px rgba(251,146,60,0.55));" />
				{t('ui.your_progress')}
			</h3>
			<button
				class="text-xs text-[var(--text-dim)] hover:text-[var(--accent-red)] transition-colors cursor-pointer"
				onclick={handleClear}
			>
				{t('ui.reset')}
			</button>
		</div>

		<!-- Overview stats -->
		<div class="grid grid-cols-3 gap-3">
			<div class="rounded-[var(--radius)] p-3 text-center" style="background: rgba(251,146,60,0.07); border: 1px solid rgba(251,146,60,0.18);">
				<div class="text-3xl font-bold" style="color:#fb923c; filter: drop-shadow(0 0 8px rgba(251,146,60,0.4));">{stats.totalSessions}</div>
				<div class="text-xs text-[var(--text-muted)] mt-1">{t('ui.sessions')}</div>
			</div>
			<div class="rounded-[var(--radius)] p-3 text-center" style="background: rgba(251,146,60,0.07); border: 1px solid rgba(251,146,60,0.18);">
				<div class="text-3xl font-bold" style="color:#fb923c; filter: drop-shadow(0 0 8px rgba(251,146,60,0.4));">{stats.totalChords}</div>
				<div class="text-xs text-[var(--text-muted)] mt-1">{t('ui.chords_practiced')}</div>
			</div>
			<div class="rounded-[var(--radius)] p-3 text-center" style="background: rgba(251,146,60,0.07); border: 1px solid rgba(251,146,60,0.18);">
				<div class="text-3xl font-bold" style="color:#fb923c; filter: drop-shadow(0 0 8px rgba(251,146,60,0.4));">
					{(stats.overallAvgMs / 1000).toFixed(1)}s
				</div>
				<div class="text-xs text-[var(--text-muted)] mt-1">{t('ui.avg_per_chord')}</div>
			</div>
		</div>

		<!-- Improvements -->
		{#if improvements.length > 0 && improvements[0].changePercent < -15}
			<div class="bg-[var(--accent-green)]/5 border border-[var(--accent-green)]/20 rounded-[var(--radius)] p-3">
				<div class="text-sm font-medium text-[var(--accent-green)] mb-2">📈 {t('ui.getting_faster')}</div>
				<div class="flex gap-3 flex-wrap">
					{#each improvements.slice(0, 3) as imp}
						<div class="text-sm">
							<strong class="text-[var(--text)]">{imp.root}</strong>
							<span class="text-[var(--accent-green)] font-mono ml-1">↓{Math.abs(imp.changePercent).toFixed(0)}%</span>
						</div>
					{/each}
				</div>
			</div>
		{/if}

		<!-- Weak chords -->
		{#if weakChords.length > 0}
			<div>
				<div class="text-sm font-medium text-[var(--text-muted)] mb-2 flex items-center gap-1.5">
					<img src="/elements/icons/icon-focus.webp" alt={t('ui.focus_on')} width="28" height="28" loading="lazy" style="mix-blend-mode:lighten; object-fit:contain; display:inline-block; vertical-align:middle;" />
					{t('ui.focus_on')}
				</div>
				<div class="space-y-2">
					{#each weakChords.slice(0, 3) as wc}
						{@const barWidth = Math.min(100, (wc.avgMs / (weakChords[0]?.avgMs || 1)) * 100)}
						<div class="relative bg-[var(--bg)] rounded-[var(--radius-sm)] border border-[var(--border)] overflow-hidden">
							<div
								class="absolute inset-y-0 left-0 bg-[var(--accent-amber)]/10"
								style="width: {barWidth}%"
							></div>
							<div class="relative flex items-center justify-between px-3 py-2">
								<span class="font-mono font-semibold text-sm">{wc.root}</span>
								<span class="font-mono text-[var(--accent-amber)] text-sm">
									{(wc.avgMs / 1000).toFixed(1)}s
								</span>
							</div>
						</div>
					{/each}
				</div>
			</div>
		{/if}

		<!-- Trend sparkline -->
		{#if sparkData && stats.totalSessions >= 5}
		<div class="rounded-[var(--radius)] p-4" style="background: rgba(251,146,60,0.05); border: 1px solid rgba(251,146,60,0.12);">
			<div class="flex items-center justify-between mb-3">
				<span class="text-xs text-[var(--text-muted)]">{t('ui.last_10_sessions')}</span>
				{#if trend !== null}
					<span class="text-xs font-medium {trend < 0 ? 'text-[var(--accent-green)]' : trend > 0 ? 'text-[var(--accent-red)]' : 'text-[var(--text-muted)]'}">
						{trend < 0 ? `↓ ${t('ui.faster')}` : trend > 0 ? `↑ ${t('ui.slower')}` : `→ ${t('ui.same')}`} ({Math.abs(trend).toFixed(0)}%)
					</span>
				{/if}
			</div>
			<div class="flex items-end gap-1 h-14">
				{#each sparkData as bar, i}
					<div
						class="flex-1 rounded-t-sm transition-all"
						style="height: {bar.height}%; background: {i === sparkData.length - 1 ? '#fb923c' : 'rgba(251,146,60,0.25)'}; {i === sparkData.length - 1 ? 'filter: drop-shadow(0 0 6px rgba(251,146,60,0.7));' : ''}"
						title="{(bar.value / 1000).toFixed(2)}s per chord"
					></div>
				{/each}
			</div>
			<div class="flex justify-between text-[10px] text-[var(--text-dim)] mt-1">
				<span>{t('ui.oldest')}</span>
				<span>{t('ui.newest')}</span>
		</div>
	</div>
{/if}
<!-- Personal bests -->
	{#if Object.keys(stats.personalBests).length > 3}
		<details>
			<summary class="text-sm font-medium text-[var(--text-muted)] cursor-pointer hover:text-[var(--text)] mb-2 flex items-center gap-1.5">
				<img src="/elements/icons/icon-personal-best.webp" alt={t('ui.personal_bests')} width="28" height="28" loading="lazy" style="mix-blend-mode:lighten; object-fit:contain; display:inline-block; vertical-align:middle;" />
				{t('ui.personal_bests')} ({Object.keys(stats.personalBests).length})
			</summary>
			<div class="space-y-1.5 mt-2">
				{#each Object.entries(stats.personalBests).slice(0, 8) as [key, best]}
					{@const parts = key.split('-')}
					{@const diff = parts[0]}
						{@const voicingKey = parts.length >= 3 ? parts.slice(1, -1).join('-') : parts[1]}
						{@const mode = parts[parts.length - 1]}
						<div class="flex items-center justify-between text-sm bg-[var(--bg)] rounded-[var(--radius-sm)] px-3 py-2 border border-[var(--border)]">
							<div class="flex items-center gap-2 text-[var(--text-muted)]">
								<span class="capitalize">{t('settings.difficulty_' + diff)}</span>
								<span class="text-[var(--text-dim)]">·</span>
								<span>{t('settings.voicing_' + voicingKey.toLowerCase().replace(/-/g, '_'))}</span>
								<span class="text-[var(--text-dim)]">·</span>
								<span>{t('plans.' + mode + '_name')}</span>
							</div>
							<span class="font-mono font-semibold text-[var(--accent-green)]">
								{(best.avgMs / 1000).toFixed(2)}s
							</span>
						</div>
					{/each}
				</div>
			</details>
		{/if}

		<!-- Session history (collapsible) -->
		{#if history.length > 1}
			<details bind:open={showHistory}>
				<summary class="cursor-pointer text-xs text-[var(--text-muted)] hover:text-[var(--text)] font-medium">
					{t('ui.recent_sessions')} ({Math.min(history.length, 20)})
				</summary>
				<div class="mt-3 space-y-1.5 max-h-48 overflow-y-auto">
					{#each history.slice(0, 20) as session}
						<div class="flex items-center justify-between text-xs bg-[var(--bg)] rounded-[var(--radius-sm)] px-3 py-2 border border-[var(--border)]">
							<div class="flex items-center gap-2 text-[var(--text-muted)]">
								<span>{fmtDate(session.timestamp)}</span>
								<span class="text-[var(--text-dim)]">·</span>
								<span>{session.totalChords} {t('ui.chords')}</span>
								<span class="text-[var(--text-dim)]">·</span>
								<span class="capitalize">{t('settings.difficulty_' + session.settings.difficulty)}</span>
							</div>
							<div class="flex items-center gap-2">
								{#if session.midi.enabled}
									<span class="text-[var(--accent-green)]">{session.midi.accuracy}%</span>
								{/if}
								<span class="font-mono font-semibold">{fmt(session.elapsedMs)}</span>
							</div>
						</div>
					{/each}
				</div>
			</details>
		{/if}</div>
{/if}