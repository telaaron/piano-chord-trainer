<script lang="ts">
	// The interactive ii-V-I table shared by /learn/ii-v-i-all-keys and its
	// German twin /de/ii-v-i-alle-tonarten. Pages pass their own copy; the
	// notes come from the trainer's engine, so both languages show the same voicings.
	import { ArrowRight, Play, Printer } from 'lucide-svelte';
	import { buildIIVITable, type IIVIVoicing } from '$lib/seo/ii-v-i-keys';

	interface Props {
		voicings: { id: IIVIVoicing; label: string; hint: string }[];
		text: {
			voicingGroup: string;
			print: string;
			notesHint: string;
			key: string;
			listen: string;
			playAria: (key: string) => string;
			cta: string;
		};
	}

	let { voicings, text }: Props = $props();

	// All three tables are tiny and built at prerender time, so the toggle is
	// instant and every version is in the static HTML.
	const tables = Object.fromEntries(
		(['shell', 'rootless-ab', 'rootless-ba'] as const).map((id) => [id, buildIIVITable(id)]),
	) as Record<IIVIVoicing, ReturnType<typeof buildIIVITable>>;

	let voicing = $state<IIVIVoicing>('shell');
	const rows = $derived(tables[voicing]);
	const hint = $derived(voicings.find((v) => v.id === voicing)!.hint);

	const pretty = (n: string) => n.replace('#', '♯').replace(/^([A-G])b/, '$1♭');

	// Audio loads lazily on first tap so it never blocks prerender or first paint.
	let playing = $state<string | null>(null);
	async function playRow(key: string, voiced: string[][]) {
		if (playing) return;
		playing = key;
		const { playChord } = await import('$lib/services/audio');
		for (const notes of voiced) {
			await playChord(notes, '2n');
			await new Promise((r) => setTimeout(r, 850));
		}
		playing = null;
	}
</script>

<div class="toolbar">
	<div class="seg" role="radiogroup" aria-label={text.voicingGroup}>
		{#each voicings as v (v.id)}
			<button
				type="button"
				role="radio"
				aria-checked={voicing === v.id}
				class:active={voicing === v.id}
				onclick={() => (voicing = v.id)}>{v.label}</button
			>
		{/each}
	</div>
	<button type="button" class="ghost" onclick={() => window.print()}>
		<Printer size={16} aria-hidden="true" />
		{text.print}
	</button>
</div>
<p class="hint">{hint} {text.notesHint}</p>

<table class="chart">
	<thead>
		<tr>
			<th scope="col">{text.key}</th>
			<th scope="col"><span class="deg">ii</span></th>
			<th scope="col"><span class="deg">V</span></th>
			<th scope="col"><span class="deg">I</span></th>
			<th scope="col" class="no-print"><span class="sr-only">{text.listen}</span></th>
		</tr>
	</thead>
	<tbody>
		{#each rows as row (row.key)}
			<tr>
				<th scope="row" class="key">{row.key}</th>
				{#each row.chords as ch (ch.degree)}
					<td>
						{#if ch.slug}
							<a class="chord" href={`/chords/${ch.slug}`}>{ch.name}</a>
						{:else}
							<span class="chord">{ch.name}</span>
						{/if}
						<span class="notes">{ch.notes.map(pretty).join(' ')}</span>
					</td>
				{/each}
				<td class="no-print">
					<button
						type="button"
						class="play"
						aria-label={text.playAria(row.key)}
						disabled={playing !== null && playing !== row.key}
						onclick={() => playRow(row.key, row.chords.map((c) => c.notes))}
					>
						<Play size={16} aria-hidden="true" />
					</button>
				</td>
			</tr>
		{/each}
	</tbody>
</table>

<a class="cta no-print" href="/train">
	{text.cta}
	<ArrowRight size={18} aria-hidden="true" />
</a>

<style>
	.hint { font-size: 0.875rem; line-height: 1.6; color: var(--text-dim); max-width: 66ch; margin: 0 0 1rem; }

	/* ── Toolbar ── */
	.toolbar { display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: center; justify-content: space-between; margin-bottom: 0.6rem; }
	.seg { display: inline-flex; border: 1.5px solid var(--border); border-radius: var(--radius-sm); overflow: hidden; }
	.seg button {
		min-height: var(--tap-min); padding: 0 0.9rem; border: 0; background: transparent; color: var(--text-muted);
		font-weight: 600; font-size: 0.875rem; cursor: pointer;
	}
	.seg button + button { border-left: 1.5px solid var(--border); }
	.seg button.active { background: var(--primary); color: var(--primary-text); }
	.ghost {
		display: inline-flex; align-items: center; gap: 0.4rem; min-height: var(--tap-min); padding: 0 0.9rem;
		border: 1.5px solid var(--border); border-radius: var(--radius-sm); background: transparent; color: var(--text);
		font-weight: 600; font-size: 0.875rem; cursor: pointer;
	}

	/* ── Chart ── */
	.chart { width: 100%; border-collapse: collapse; margin: 0.75rem 0 1.75rem; font-variant-numeric: lining-nums; }
	.chart th, .chart td { padding: 0.6rem 0.4rem; border-bottom: 1px solid var(--border); text-align: left; vertical-align: top; }
	.chart thead th { font-family: var(--font-mono); font-size: 0.625rem; letter-spacing: 0.14em; text-transform: uppercase; color: var(--text-dim); }
	.deg { font-family: var(--font-display); font-style: italic; font-size: 0.95rem; letter-spacing: 0; text-transform: none; color: var(--ink-blue); }
	.key { font-family: var(--font-display); font-size: 1.15rem; font-weight: 700; color: var(--text); width: 3rem; }
	.chord { display: block; font-family: var(--font-display); font-size: 1.05rem; font-weight: 600; color: var(--text); text-decoration: none; }
	a.chord:hover { color: var(--primary); }
	.notes { display: block; font-family: var(--font-mono); font-size: 0.8125rem; color: var(--text-muted); margin-top: 0.15rem; }
	.play {
		display: grid; place-items: center; width: var(--tap-min); height: var(--tap-min);
		border: 1.5px solid var(--border); border-radius: 999px; background: transparent; color: var(--text); cursor: pointer;
	}
	.play:disabled { opacity: 0.4; cursor: default; }
	@media (max-width: 30rem) {
		.chart th, .chart td { padding: 0.5rem 0.2rem; }
		.chord { font-size: 0.95rem; }
		.notes { font-size: 0.75rem; }
	}

	.cta {
		display: inline-flex; align-items: center; gap: 0.5rem; min-height: var(--tap-min); padding: 0 1.4rem;
		border: 1.5px solid var(--primary); border-radius: var(--radius-sm); background: var(--primary);
		color: var(--primary-text); font-weight: 600; text-decoration: none;
	}
	.cta:hover { background: var(--primary-hover); border-color: var(--primary-hover); }

	.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }

	@media print {
		.no-print, .toolbar { display: none !important; }
		.chart th, .chart td { padding: 0.35rem 0.3rem; }
	}
</style>
