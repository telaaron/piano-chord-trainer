<script lang="ts">
	import { onMount } from 'svelte';
	import { loadHistory, computeStats, clearHistory, type SessionResult, type ProgressStats } from '$lib/services/progress';
	import { PROGRESSION_LABELS, VOICING_LABELS } from '$lib/engine';

	let history: SessionResult[] = $state([]);
	let stats: ProgressStats = $state(computeStats([]));
	let showHistory = $state(false);

	onMount(() => {
		history = loadHistory();
		stats = computeStats(history);
	});

	function handleClear() {
		if (confirm('Alle Trainings-Daten löschen?')) {
			clearHistory();
			history = [];
			stats = computeStats([]);
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
		return new Date(ts).toLocaleDateString('de-DE', {
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
</script>

{#if stats.totalSessions > 0}
	<div class="card p-5 sm:p-6 max-w-2xl mx-auto space-y-5">
		<div class="flex items-center justify-between">
			<h3 class="text-lg font-bold flex items-center gap-2">
				📊 Dein Fortschritt
			</h3>
			<button
				class="text-xs text-[var(--text-dim)] hover:text-[var(--accent-red)] transition-colors cursor-pointer"
				onclick={handleClear}
			>
				Zurücksetzen
			</button>
		</div>

		<!-- Overview stats -->
		<div class="grid grid-cols-3 gap-3">
			<div class="bg-[var(--bg-muted)] rounded-[var(--radius)] p-3 text-center">
				<div class="text-2xl font-bold text-[var(--primary)]">{stats.totalSessions}</div>
				<div class="text-xs text-[var(--text-muted)] mt-1">Sessions</div>
			</div>
			<div class="bg-[var(--bg-muted)] rounded-[var(--radius)] p-3 text-center">
				<div class="text-2xl font-bold text-[var(--primary)]">{stats.totalChords}</div>
				<div class="text-xs text-[var(--text-muted)] mt-1">Akkorde</div>
			</div>
			<div class="bg-[var(--bg-muted)] rounded-[var(--radius)] p-3 text-center">
				<div class="text-2xl font-bold text-[var(--primary)]">
					{(stats.overallAvgMs / 1000).toFixed(1)}s
				</div>
				<div class="text-xs text-[var(--text-muted)] mt-1">⌀ / Akkord</div>
			</div>
		</div>

		<!-- Trend sparkline -->
		{#if sparkData}
			<div class="bg-[var(--bg-muted)] rounded-[var(--radius)] p-4">
				<div class="flex items-center justify-between mb-3">
					<span class="text-xs text-[var(--text-muted)]">Letzte 10 Sessions (⌀ s/Akkord)</span>
					{#if trend !== null}
						<span class="text-xs font-medium {trend < 0 ? 'text-[var(--accent-green)]' : trend > 0 ? 'text-[var(--accent-red)]' : 'text-[var(--text-muted)]'}">
							{trend < 0 ? '↓' : trend > 0 ? '↑' : '→'} {Math.abs(trend).toFixed(0)}%
						</span>
					{/if}
				</div>
				<div class="flex items-end gap-1 h-12">
					{#each sparkData as bar, i}
						<div
							class="flex-1 rounded-t-sm transition-all {i === sparkData.length - 1 ? 'bg-[var(--primary)]' : 'bg-[var(--border)]'}"
							style="height: {bar.height}%"
							title="{(bar.value / 1000).toFixed(2)}s"
						></div>
					{/each}
				</div>
			</div>
		{/if}

		<!-- Personal bests -->
		{#if Object.keys(stats.personalBests).length > 0}
			<div>
				<div class="text-xs text-[var(--text-muted)] mb-2 font-medium">Bestzeiten (⌀/Akkord)</div>
				<div class="space-y-1.5">
					{#each Object.entries(stats.personalBests).slice(0, 5) as [key, best]}
						{@const parts = key.split('-')}
						{@const diff = parts[0]}
						{@const voicingKey = parts.length >= 3 ? parts.slice(1, -1).join('-') : parts[1]}
						{@const mode = parts[parts.length - 1]}
						<div class="flex items-center justify-between text-sm bg-[var(--bg)] rounded-[var(--radius-sm)] px-3 py-2 border border-[var(--border)]">
							<div class="flex items-center gap-2 text-[var(--text-muted)]">
								<span class="capitalize">{diff}</span>
								<span class="text-[var(--text-dim)]">·</span>
								<span>{VOICING_LABELS[voicingKey as keyof typeof VOICING_LABELS] ?? voicingKey}</span>
								<span class="text-[var(--text-dim)]">·</span>
								<span>{PROGRESSION_LABELS[mode as keyof typeof PROGRESSION_LABELS] ?? mode}</span>
							</div>
							<span class="font-mono font-semibold text-[var(--accent-green)]">
								{(best.avgMs / 1000).toFixed(2)}s
							</span>
						</div>
					{/each}
				</div>
			</div>
		{/if}

		<!-- Session history (collapsible) -->
		{#if history.length > 1}
			<details bind:open={showHistory}>
				<summary class="cursor-pointer text-xs text-[var(--text-muted)] hover:text-[var(--text)] font-medium">
					Letzte Sessions ({Math.min(history.length, 20)})
				</summary>
				<div class="mt-3 space-y-1.5 max-h-48 overflow-y-auto">
					{#each history.slice(0, 20) as session}
						<div class="flex items-center justify-between text-xs bg-[var(--bg)] rounded-[var(--radius-sm)] px-3 py-2 border border-[var(--border)]">
							<div class="flex items-center gap-2 text-[var(--text-muted)]">
								<span>{fmtDate(session.timestamp)}</span>
								<span class="text-[var(--text-dim)]">·</span>
								<span>{session.totalChords} Akkorde</span>
								<span class="text-[var(--text-dim)]">·</span>
								<span class="capitalize">{session.settings.difficulty}</span>
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
		{/if}
	</div>
{/if}
