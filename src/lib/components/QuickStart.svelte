<script lang="ts">
	import { t } from '$lib/i18n';
	import { PRACTICE_PLANS, type PracticePlan } from '$lib/engine';
	import { Icon } from '$lib/components/ui';

	import { Play } from 'lucide-svelte';

	interface Props {
		/** Plan id to resume, if the user has a recent session. null = no resume card. */
		resumePlanId?: string | null;
		/** Whether adaptive history exists (enables the "weak spots" card). */
		hasHistory?: boolean;
		onstart: (plan: PracticePlan) => void;
		onstartdefault: () => void;
		oncustomize: () => void;
		/** Launch a focused drill on the player's weakest chords (weak-spots card). */
		onweakdrill?: () => void;
		/** Start today's Auto-Mode ("Coach") session — the dominant hero action. */
		onstartcoach?: () => void;
		/** One-line, already-localized coach announcement shown under the hero button. */
		coachAnnouncement?: string;
	}

	let { resumePlanId = null, hasHistory = false, onstart, onstartdefault, oncustomize, onweakdrill, onstartcoach, coachAnnouncement }: Props = $props();

	const byId = (id: string) => PRACTICE_PLANS.find((p) => p.id === id);

	// The four primary entry points — curated, not the full 14-plan list.
	// Order: resume (if any) → daily warmup → weak-spots (if history) → ii-V-I.
	interface QuickCard {
		key: string;
		icon: string;
		titleKey: string;
		descKey: string;
		accent: string;
		run: () => void;
	}

	// Warmup is intentionally NOT a card here — the hero owns the daily warmup CTA.
	// These cards complement it: resume → weak-spots → ii-V-I → (backfill).
	const cards = $derived.by<QuickCard[]>(() => {
		const out: QuickCard[] = [];

		if (resumePlanId && resumePlanId !== 'warmup') {
			const p = byId(resumePlanId);
			if (p) {
				out.push({
					key: 'resume',
					icon: 'resume',
					titleKey: 'quickstart.resume_title',
					descKey: p.tagline,
					accent: 'var(--primary)',
					run: () => onstart(p),
				});
			}
		}

		if (hasHistory) {
			const adaptive = byId('adaptive-drill');
			if (adaptive) {
				out.push({
					key: 'weak',
					icon: 'weak-spots',
					titleKey: 'quickstart.weakspots_title',
					descKey: 'quickstart.weakspots_desc',
					accent: 'var(--success)',
					// Focused drill on the actual weak roots (falls back to plain adaptive).
					run: () => (onweakdrill ? onweakdrill() : onstart(adaptive)),
				});
			}
		}

		// ii-V-I — the core jazz cadence (warmup's 2-5-1 beginner settings)
		const twofive = byId('warmup') ?? PRACTICE_PLANS.find((p) => p.settings.progressionMode === '2-5-1');
		if (twofive) {
			out.push({
				key: 'ii-v-i',
				icon: 'ii-v-i',
				titleKey: 'quickstart.iivi_title',
				descKey: 'quickstart.iivi_desc',
				accent: 'var(--info)',
				run: () => onstart(twofive),
			});
		}

		// Backfill to keep a balanced 3-up grid (cycle of 4ths, then speed).
		const backfill: Array<{ id: string; icon: string; descKey: string; accent: string }> = [
			{ id: 'quartenzirkel', icon: 'cycle', descKey: 'quickstart.cycle_desc', accent: 'var(--accent-gold)' },
			{ id: 'speed', icon: 'speed', descKey: 'quickstart.speed_desc', accent: 'var(--accent-red)' },
		];
		for (const b of backfill) {
			if (out.length >= 3) break;
			const p = byId(b.id);
			if (p && !out.some((c) => c.key === b.id)) {
				out.push({
					key: b.id,
					icon: b.icon,
					titleKey: p.name,
					descKey: b.descKey,
					accent: b.accent,
					run: () => onstart(p),
				});
			}
		}

		return out;
	});

	// The alternatives are printed as a running order, the way /togo sets its
	// seven disciplines. Roman numerals: these are movements of one programme,
	// not a ranked list.
	const ROMAN = ['I', 'II', 'III', 'IV', 'V'] as const;
</script>

<section aria-label={t('quickstart.section_label')} class="qs">
	{#if onstartcoach}
		<!-- The one filled action on the whole screen. Amber is the system's
		     live ink and starting a session is exactly that; the values are
		     fixed in both themes for the same reason /togo fixes them —
		     near-black on bright amber measures 9.65:1 either way, and the
		     invitation to press must not change character on paper. -->
		<button type="button" onclick={onstartcoach} class="stamp">
			<Play size={22} fill="currentColor" aria-hidden="true" />
			<span class="stamp-txt">
				<span class="stamp-t">{t('quickstart.coach_hero_title')}</span>
				<span class="stamp-s">{coachAnnouncement || t('quickstart.coach_hero_sub')}</span>
			</span>
		</button>

		<!-- "Pick it yourself" — a ruled head, not a divider with a label in it. -->
		<p class="eyebrow blue rule-head">{t('quickstart.pick_yourself')}</p>
	{/if}

	<ol class="contents ruled">
		{#each cards as card, i (card.key)}
			<li class="row">
				<button type="button" onclick={card.run} aria-label={t(card.titleKey)} class="row-btn">
					<span class="no roman">{ROMAN[i] ?? String(i + 1)}</span>
					<span class="row-icon" aria-hidden="true"><Icon name={card.icon} size={26} /></span>
					<span class="row-txt">
						<span class="ttl">{t(card.titleKey)}</span>
						<span class="dsc">{t(card.descKey)}</span>
					</span>
					<span class="go plate">{t('habit.start_arrow')}</span>
				</button>
			</li>
		{/each}
	</ol>

	<div class="fin">
		<button type="button" onclick={onstartdefault} class="link primary">
			{t('quickstart.start_custom')}
		</button>
		<span class="sep" aria-hidden="true">·</span>
		<button type="button" onclick={oncustomize} class="link">
			{t('quickstart.customize')}
		</button>
		<span class="sep" aria-hidden="true">·</span>
		<a href="/togo" class="link">{t('togo.entry')}</a>
	</div>
</section>

<style>
	/* The pre-session screen on the editorial plate. Same vocabulary as the
	   landing page and /togo — hairline rules, a printed contents list, the
	   display serif for anything read rather than scanned. This screen is
	   seen before EVERY session, so exactly one thing is loud: the start. */

	.qs {
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		/* AccidentalFit is unicode-range-scoped, so it only ever claims ♭ ♯ ° ø;
		   every other character still comes from the normal stack below it. */
		--font-display-mus: 'AccidentalFit', var(--font-display);
		font-family: 'AccidentalFit', var(--font-sans);
	}

	.eyebrow {
		display: flex;
		align-items: center;
		gap: 0.625rem;
		margin: 0;
		font-family: var(--font-mono);
		font-size: 0.66rem;
		font-weight: 600;
		letter-spacing: 0.19em;
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
	.rule-head { margin: 1.75rem 0 0.25rem; }

	.plate {
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	/* ── The start ────────────────────────────────────────────── */

	.stamp {
		display: flex;
		align-items: center;
		gap: 0.9rem;
		width: 100%;
		min-height: 3.85rem;
		padding: 0.75rem 1.25rem;
		/* Fixed values in BOTH themes, for the reason /togo fixes them: the
		   light theme resolves --accent-amber to the paper-safe ochre #8f5a05,
		   which turns the one invitation on the screen into a muddy brown slab.
		   Near-black on bright amber measures 9.65:1 either way, and the
		   invitation to press must not change character on paper. */
		border: 1.5px solid var(--stamp);
		border-radius: var(--radius-sm);
		background: var(--stamp);
		color: var(--stamp-ink);
		font-family: inherit;
		text-align: left;
		cursor: pointer;
		transition: transform 0.12s ease-out, background-color 0.12s, border-color 0.12s;
	}
	.stamp:hover {
		transform: translateY(-1px);
		background: var(--stamp-hover);
		border-color: var(--stamp-hover);
	}
	.stamp:active { transform: none; }
	.stamp:focus-visible {
		outline: 2px solid var(--text);
		outline-offset: 2px;
	}
	.stamp :global(svg) { flex: none; }

	/* On diazo paper the amber fill separates from the ground at only 1.75:1,
	   so the button's SHAPE goes soft though its label is fine. An ink edge
	   gives it back its cut. Dark ground needs none. */
	:global([data-theme='light']) .stamp {
		border-color: var(--stamp-ink);
	}

	.stamp-txt { display: block; min-width: 0; }
	.stamp-t {
		display: block;
		font-family: var(--font-display-mus);
		font-size: 1.16rem;
		font-weight: 700;
		line-height: 1.2;
		letter-spacing: -0.012em;
	}
	.stamp-s {
		display: block;
		margin-top: 0.14rem;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		font-size: 0.79rem;
		font-weight: 500;
		line-height: 1.35;
		opacity: 0.82;
	}

	/* ── The alternatives, as a printed running order ─────────── */

	.contents {
		list-style: none;
		margin: 0;
		padding: 0;
	}
	.contents.ruled { border-top: 1px solid var(--border); }

	.row { border-bottom: 1px solid var(--rule-soft); }

	.row-btn {
		display: grid;
		grid-template-columns: auto auto minmax(0, 1fr) auto;
		gap: 0.85rem;
		align-items: center;
		width: 100%;
		min-height: var(--tap-min);
		padding: 0.8rem 0.25rem;
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

	.no {
		font-family: var(--font-mono);
		font-size: 0.7rem;
		letter-spacing: 0.08em;
		color: var(--text-dim);
	}
	.no.roman { min-width: 1.6rem; }

	.row-icon { display: flex; flex: none; }

	.row-txt { min-width: 0; }
	.ttl {
		display: block;
		font-family: var(--font-display-mus);
		font-size: 1.04rem;
		font-weight: 600;
		line-height: 1.25;
		color: var(--text);
	}
	.dsc {
		display: block;
		margin-top: 0.15rem;
		font-size: 0.86rem;
		line-height: 1.45;
		color: var(--text-muted);
	}

	.go { white-space: nowrap; }
	.row-btn:hover .go { color: var(--primary); }

	/* ── The quiet exits ──────────────────────────────────────── */

	.fin {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.5rem;
		margin-top: 1.1rem;
	}

	.link {
		padding: 0.25rem 0;
		border: 0;
		background: transparent;
		font-family: inherit;
		font-size: 0.86rem;
		font-weight: 500;
		color: var(--text-muted);
		text-decoration: underline;
		text-decoration-color: var(--border-hover);
		text-decoration-thickness: 1px;
		text-underline-offset: 4px;
		cursor: pointer;
		transition: color 0.12s, text-decoration-color 0.12s;
	}
	.link:hover {
		color: var(--text);
		text-decoration-color: var(--accent-amber);
	}
	.link.primary { color: var(--primary); }
	.link.primary:hover { color: var(--primary-hover); }
	.link:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: 2px;
	}

	.sep { color: var(--text-dim); }

	@media (prefers-reduced-motion: reduce) {
		.stamp { transition: none; }
		.stamp:hover { transform: none; }
	}
</style>
