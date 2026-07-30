<script lang="ts">
	// Admin — the owner's own screen, on the same editorial plate as the rest
	// of the app. Four figures, the gift panel, the intake chart, the directory.
	//
	// The gift field was the complaint: it used to be a bare text input where
	// you typed an email blind, with no way to see who you were about to give a
	// membership to. It is now a combobox over the users the page already
	// loads — filtered as you type, showing the current tier next to each
	// address — while still accepting an address that is not in the list,
	// because somebody may not have signed up yet.

	import { t } from '$lib/i18n';
	import { onMount } from 'svelte';
	import { Check, ChevronDown, Gift, Search, Users, X } from 'lucide-svelte';

	interface AdminStats {
		totalUsers: number;
		activeToday: number;
		totalSessions: number;
		activeSubs: number;
	}

	interface AdminUser {
		id: string;
		email: string;
		created_at: string;
		last_sign_in_at: string | null;
		role: string;
		tier: string;
		sub_status: string | null;
	}

	let stats: AdminStats | null = $state(null);
	let recentUsers: AdminUser[] = $state([]);
	let signupsByDay: Record<string, number> = $state({});
	let tierDistribution: Record<string, number> = $state({});
	let loading = $state(true);
	let error = $state('');

	onMount(async () => {
		try {
			const res = await fetch('/api/admin/stats');
			if (!res.ok) {
				if (res.status === 403) error = 'Access denied. Admin role required.';
				else if (res.status === 401) error = 'Not authenticated. Please sign in.';
				else error = `Error ${res.status}`;
				loading = false;
				return;
			}
			const data = await res.json();
			stats = data.stats;
			recentUsers = data.recentUsers;
			signupsByDay = data.signupsByDay;
			tierDistribution = data.tierDistribution;
		} catch {
			error = 'Failed to load admin data.';
		}
		loading = false;
	});

	// ── The intake chart ────────────────────────────────────────
	//
	// This box used to render empty, and the cause was a key mismatch rather
	// than a drawing bug. The API buckets signups by UTC day
	// (`new Date(created_at).toISOString().slice(0,10)`), but the axis here was
	// built by mutating a LOCAL date and then calling toISOString() on it —
	// which shifts by the UTC offset and lands on the neighbouring day for most
	// of the world. Every lookup therefore missed. Building the axis from UTC
	// puts both sides in the same key space.
	//
	// Fixing the keys does not conjure traffic, though: this instance genuinely
	// has very few signups, so an honest chart is mostly flat. Rather than
	// present a frame full of 2%-tall stubs as if it were a graph, the panel
	// states the count in words when there is nothing (or almost nothing) to
	// draw, and only renders bars once they would actually mean something.

	function getLast30Days(): string[] {
		const days: string[] = [];
		const today = new Date();
		// Anchor to UTC midnight, then step back in whole UTC days.
		const cursor = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate());
		for (let i = 29; i >= 0; i--) {
			days.push(new Date(cursor - i * 86_400_000).toISOString().slice(0, 10));
		}
		return days;
	}

	const chartDays = getLast30Days();
	const chartCounts = $derived(chartDays.map((d) => signupsByDay[d] || 0));
	const totalSignups = $derived(chartCounts.reduce((a, b) => a + b, 0));
	const maxSignups = $derived(Math.max(1, ...chartCounts));
	const peakDay = $derived.by(() => {
		let best = -1;
		let idx = -1;
		chartCounts.forEach((c, i) => {
			if (c > best) {
				best = c;
				idx = i;
			}
		});
		return best > 0 ? { count: best, day: chartDays[idx] } : null;
	});

	function shortDay(iso: string): string {
		return iso.slice(5).replace('-', '.');
	}

	// ── Gift a membership ───────────────────────────────────────

	let grantEmail = $state('');
	let grantTier = $state('pro');
	let grantBusy = $state(false);
	let grantMsg = $state('');
	let grantOk = $state(false);

	// Combobox state. `grantEmail` is the single source of truth for what will
	// be submitted — picking from the list only writes into it, so a typed
	// address and a chosen one are the same thing downstream.
	let pickerOpen = $state(false);
	let activeIndex = $state(-1);
	let pickerInput: HTMLInputElement | null = $state(null);
	let comboEl: HTMLDivElement | null = $state(null);

	/** Click anywhere outside the combobox dismisses the list. */
	function onDocPointerDown(event: MouseEvent) {
		if (!pickerOpen || !comboEl) return;
		if (!comboEl.contains(event.target as Node)) {
			pickerOpen = false;
			activeIndex = -1;
		}
	}

	const matches = $derived.by(() => {
		const q = grantEmail.trim().toLowerCase();
		if (!q) return recentUsers;
		return recentUsers.filter((u) => u.email?.toLowerCase().includes(q));
	});

	/** The exact user the typed text resolves to, if any — drives the confirmation line. */
	const selectedUser = $derived(
		recentUsers.find((u) => u.email?.toLowerCase() === grantEmail.trim().toLowerCase()) ?? null,
	);

	/** A non-empty address that matches nobody: valid, but worth flagging. */
	const isNewAddress = $derived(grantEmail.trim().length > 0 && !selectedUser);

	function openPicker() {
		pickerOpen = true;
		activeIndex = -1;
	}

	function choose(user: AdminUser) {
		grantEmail = user.email;
		pickerOpen = false;
		activeIndex = -1;
		pickerInput?.focus();
	}

	function clearPick() {
		grantEmail = '';
		pickerOpen = false;
		activeIndex = -1;
		pickerInput?.focus();
	}

	function onPickerKey(event: KeyboardEvent) {
		if (event.key === 'Escape') {
			pickerOpen = false;
			activeIndex = -1;
			return;
		}
		if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
			event.preventDefault();
			if (!pickerOpen) {
				pickerOpen = true;
				activeIndex = 0;
				return;
			}
			const delta = event.key === 'ArrowDown' ? 1 : -1;
			const n = matches.length;
			if (n === 0) return;
			activeIndex = (activeIndex + delta + n) % n;
			return;
		}
		// Enter only commits a HIGHLIGHTED row. With nothing highlighted the
		// keystroke belongs to the form, so a typed-in address still submits.
		if (event.key === 'Enter' && pickerOpen && activeIndex >= 0) {
			const user = matches[activeIndex];
			if (user) {
				event.preventDefault();
				choose(user);
			}
		}
	}

	function tierLabel(tier: string): string {
		return tier === 'free' ? t('admin.tier_free') : tier;
	}

	async function submitGrant(revoke = false) {
		if (!grantEmail.trim()) return;
		pickerOpen = false;
		grantBusy = true;
		grantMsg = '';
		try {
			const res = await fetch('/api/admin/grant', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ email: grantEmail.trim(), tier: grantTier, revoke }),
			});
			const data = await res.json();
			if (!res.ok) {
				grantOk = false;
				grantMsg = data.message || data.error || `Error ${res.status}`;
			} else {
				grantOk = true;
				grantMsg =
					data.action === 'revoked'
						? t('admin.grant_revoked', { email: data.email })
						: t('admin.grant_done', { tier: data.tier, email: data.email });
				grantEmail = '';
			}
		} catch {
			grantOk = false;
			grantMsg = 'Network error';
		}
		grantBusy = false;
	}
</script>

<svelte:head>
	<title>{t('admin.title')} – jazzchords.app</title>
	<meta name="robots" content="noindex, nofollow" />
</svelte:head>

<svelte:document onmousedown={onDocPointerDown} />

<div class="edi shell">
	<header class="head">
		<p class="eyebrow">{t('admin.overview')}</p>
		<h1 class="h1">{t('admin.heading')}</h1>
	</header>

	{#if loading}
		<p class="notice">{t('admin.loading')}</p>
	{:else if error}
		<!-- The guard's own words (401/403) — kept verbatim, they are diagnostic. -->
		<p class="notice bad">{error}</p>
	{:else if stats}
		<!-- ═══ Four figures ═══════════════════════════════════════ -->
		<div class="ledger">
			<div class="cell">
				<span class="v">{stats.totalUsers}</span>
				<span class="l">{t('admin.total_users')}</span>
			</div>
			<div class="cell">
				<span class="v">{stats.activeToday}</span>
				<span class="l">{t('admin.active_today')}</span>
			</div>
			<div class="cell">
				<span class="v">{stats.totalSessions}</span>
				<span class="l">{t('admin.total_sessions')}</span>
			</div>
			<div class="cell">
				<span class="v">{stats.activeSubs}</span>
				<span class="l">{t('admin.active_subs')}</span>
			</div>
		</div>

		<!-- ═══ Gift a membership ══════════════════════════════════ -->
		<p class="eyebrow blue rule-head">{t('admin.section_grant')}</p>
		<section class="plate-frame">
			<div class="plate-head">
				<Gift size={14} aria-hidden="true" />
				<span class="plate-title">{t('admin.grant_title')}</span>
			</div>

			<div class="plate-body">
				<p class="desc">{t('admin.grant_desc')}</p>

				<!-- The picker. A combobox rather than a bare input: the owner
				     could not see who he was typing at. -->
				<div class="field">
					<label for="grant-person" class="lbl">{t('admin.grant_person')}</label>
					<div class="combo" bind:this={comboEl}>
						<span class="combo-icon" aria-hidden="true"><Search size={16} /></span>
						<input
							id="grant-person"
							bind:this={pickerInput}
							bind:value={grantEmail}
							oninput={openPicker}
							onfocus={openPicker}
							onkeydown={onPickerKey}
							placeholder={t('admin.grant_search_placeholder')}
							class="ctl combo-input"
							type="text"
							role="combobox"
							aria-expanded={pickerOpen}
							aria-controls="grant-listbox"
							aria-autocomplete="list"
							aria-describedby="grant-person-hint"
							autocomplete="off"
						/>
						{#if grantEmail}
							<button
								type="button"
								onclick={clearPick}
								class="combo-clear"
								aria-label={t('admin.grant_clear')}
							>
								<X size={15} aria-hidden="true" />
							</button>
						{:else}
							<span class="combo-icon end" aria-hidden="true"><ChevronDown size={16} /></span>
						{/if}

						{#if pickerOpen}
							<ul class="options" id="grant-listbox" role="listbox">
								{#each matches as user, i (user.id)}
									<li role="none">
										<button
											type="button"
											role="option"
											aria-selected={i === activeIndex}
											class="option"
											class:active={i === activeIndex}
											onmouseenter={() => (activeIndex = i)}
											onclick={() => choose(user)}
										>
											<span class="opt-mail">{user.email}</span>
											<!-- Current tier, so the owner can see what he is
											     about to change before he changes it. -->
											<span class="opt-tier" class:paid={user.tier !== 'free'}>
												{tierLabel(user.tier)}
											</span>
										</button>
									</li>
								{:else}
									<li class="option-empty">{t('admin.grant_no_matches')}</li>
								{/each}
							</ul>
						{/if}
					</div>
					<p id="grant-person-hint" class="hint">{t('admin.grant_person_hint')}</p>

					<!-- What is actually going to happen, in words. -->
					{#if selectedUser}
						<p class="resolved">
							<Check size={14} aria-hidden="true" />
							<span class="res-mail">{selectedUser.email}</span>
							<span class="res-note">
								{t('admin.grant_current_tier', { tier: tierLabel(selectedUser.tier) })}
							</span>
						</p>
					{:else if isNewAddress && !pickerOpen}
						<!-- Only once the list is dismissed: while it is open the row
						     sits under the dropdown and the reader is still choosing. -->
						<p class="resolved new">
							<span class="res-note">{t('admin.grant_new_email')}</span>
							<span class="res-mail">{grantEmail.trim()}</span>
						</p>
					{/if}
				</div>

				<div class="field">
					<label for="grant-tier" class="lbl">{t('admin.grant_tier_label')}</label>
					<select id="grant-tier" bind:value={grantTier} class="ctl sel">
						<option value="pro">Pro</option>
						<option value="educator">Educator</option>
						<option value="institution">Institution</option>
					</select>
				</div>

				<div class="acts">
					<button
						type="button"
						onclick={() => submitGrant(false)}
						disabled={grantBusy || !grantEmail.trim()}
						class="btn btn-stamp"
					>
						<Gift size={16} aria-hidden="true" />
						{grantBusy ? '…' : t('admin.grant_cta')}
					</button>
					<button
						type="button"
						onclick={() => submitGrant(true)}
						disabled={grantBusy || !grantEmail.trim()}
						class="btn btn-quiet"
					>
						{t('admin.grant_revoke')}
					</button>
				</div>

				{#if grantMsg}
					<p class="grant-msg" class:ok={grantOk} role="status" aria-live="polite">{grantMsg}</p>
				{/if}
			</div>
		</section>

		<!-- ═══ Intake ═════════════════════════════════════════════ -->
		<p class="eyebrow blue rule-head">{t('admin.section_signups')}</p>
		<section class="plate-frame">
			<div class="plate-head">
				<span class="plate-title">{t('admin.signups_chart')}</span>
				<span class="plate head-fig">{t('admin.signups_total', { count: totalSignups })}</span>
			</div>
			<div class="plate-body">
				{#if totalSignups === 0}
					<!-- No frame full of stubs pretending to be a graph. -->
					<p class="desc flat">{t('admin.signups_none')}</p>
				{:else}
					<div class="chart" role="img" aria-label={t('admin.signups_total', { count: totalSignups })}>
						{#each chartDays as day, i (day)}
							{@const count = chartCounts[i]}
							<span class="bar-slot" title={t('admin.chart_day_count', { day: shortDay(day), count })}>
								{#if count > 0}
									<span class="bar" style="height: {(count / maxSignups) * 100}%"></span>
								{:else}
									<span class="bar zero"></span>
								{/if}
							</span>
						{/each}
					</div>
					<div class="axis">
						<span>{shortDay(chartDays[0])}</span>
						{#if peakDay}
							<span class="peak">
								{t('admin.signups_peak', { count: peakDay.count, day: shortDay(peakDay.day) })}
							</span>
						{/if}
						<span>{shortDay(chartDays[chartDays.length - 1])}</span>
					</div>
					{#if totalSignups <= 3}
						<p class="desc flat sparse">{t('admin.signups_sparse')}</p>
					{/if}
				{/if}
			</div>
		</section>

		<!-- ═══ Tier distribution ══════════════════════════════════ -->
		<p class="eyebrow blue rule-head">{t('admin.subscriptions')}</p>
		<div class="ledger tiers">
			{#each Object.entries(tierDistribution) as [tier, count] (tier)}
				<div class="cell">
					<span class="v small">{count}</span>
					<span class="l">{tierLabel(tier)}</span>
				</div>
			{/each}
		</div>

		<!-- ═══ Directory ══════════════════════════════════════════ -->
		<p class="eyebrow blue rule-head">{t('admin.section_users')}</p>
		<section class="plate-frame">
			<div class="plate-head">
				<Users size={14} aria-hidden="true" />
				<span class="plate-title">{t('admin.recent_users')}</span>
				<span class="plate head-fig">{t('admin.users_count', { count: recentUsers.length })}</span>
			</div>

			{#if recentUsers.length === 0}
				<div class="plate-body"><p class="desc">{t('admin.no_data')}</p></div>
			{:else}
				<!-- The table scrolls inside its own frame; the page never does. -->
				<div class="table-wrap">
					<table>
						<thead>
							<tr>
								<th>{t('admin.email')}</th>
								<th>{t('admin.role')}</th>
								<th>{t('admin.tier')}</th>
								<th>{t('admin.joined')}</th>
								<th>{t('admin.last_active')}</th>
							</tr>
						</thead>
						<tbody>
							{#each recentUsers as user (user.id)}
								<tr>
									<td class="mail">{user.email}</td>
									<td>
										<span class="tag" class:admin={user.role === 'admin'}>{user.role}</span>
									</td>
									<td>
										<span class="tag" class:paid={user.tier !== 'free'}>{tierLabel(user.tier)}</span>
									</td>
									<td class="dim">{new Date(user.created_at).toLocaleDateString()}</td>
									<td class="dim">
										{user.last_sign_in_at ? new Date(user.last_sign_in_at).toLocaleDateString() : '–'}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		</section>
	{/if}
</div>

<style>
	/* The owner's screen, on the same plate as /togo: hairlines, 2px rules,
	   printed mono labels, the display serif for figures. No glass cards. */

	.edi {
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		--font-display-mus: 'AccidentalFit', var(--font-display);
		font-family: var(--font-sans);
	}

	.shell {
		width: 100%;
		max-width: 62rem;
		margin: 0 auto;
		padding: 1.75rem 1.25rem 6rem;
	}
	@media (min-width: 700px) {
		.shell { padding: 2.75rem 2rem 6rem; }
	}

	/* ── Primitives ───────────────────────────────────────────── */

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
	.rule-head { margin: 2.5rem 0 0.75rem; }

	.plate {
		font-family: var(--font-mono);
		font-size: 0.625rem;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	.head { margin-bottom: 2rem; }

	.h1 {
		margin: 0.85rem 0 0;
		font-family: var(--font-display-mus);
		font-size: clamp(1.9rem, 6vw, 2.5rem);
		font-weight: 600;
		line-height: 1.12;
		letter-spacing: -0.022em;
		color: var(--text);
	}

	.notice {
		margin: 0;
		padding-left: 0.9rem;
		border-left: 2px solid var(--ink-blue);
		font-family: var(--font-display-mus);
		font-size: 1rem;
		font-style: italic;
		line-height: 1.55;
		color: var(--text-muted);
	}
	.notice.bad {
		border-left-color: var(--danger);
		color: var(--danger);
	}

	/* ── The four figures ─────────────────────────────────────── */
	/* One hairline grid, gap:1px over a rule colour — the cells are separated
	   by the grid itself rather than each carrying its own border. */
	.ledger {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 1px;
		border: 1px solid var(--border);
		background: var(--border);
	}
	@media (min-width: 720px) {
		.ledger { grid-template-columns: repeat(4, 1fr); }
	}
	.cell {
		display: flex;
		flex-direction: column;
		gap: 0.4rem;
		padding: 1.15rem 1rem;
		background: var(--bg-card);
	}
	.cell .v {
		font-family: var(--font-display-mus);
		font-size: clamp(1.7rem, 5vw, 2.2rem);
		font-weight: 600;
		line-height: 1;
		font-variant-numeric: lining-nums tabular-nums;
		color: var(--text);
	}
	.cell .v.small { font-size: clamp(1.35rem, 4vw, 1.7rem); }
	.cell .l {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	.tiers { grid-template-columns: repeat(2, 1fr); }
	@media (min-width: 560px) {
		.tiers { grid-template-columns: repeat(4, 1fr); }
	}

	/* ── Plates ───────────────────────────────────────────────── */

	.plate-frame {
		border: 1px solid var(--border);
		border-left: 3px solid var(--primary);
		background: var(--bg-card);
		box-shadow: var(--shadow-sm);
	}

	.plate-head {
		display: flex;
		align-items: center;
		gap: 0.55rem;
		padding: 0.65rem 0.9rem;
		border-bottom: 1px solid var(--rule-soft);
		background: var(--bg-muted);
	}
	.plate-head :global(svg) { flex: none; color: var(--ink-blue); }
	.plate-title {
		font-family: var(--font-mono);
		font-size: 0.66rem;
		font-weight: 700;
		letter-spacing: 0.15em;
		text-transform: uppercase;
		color: var(--text);
	}
	.head-fig {
		margin-left: auto;
		white-space: nowrap;
		font-variant-numeric: tabular-nums;
	}

	.plate-body { padding: 1.35rem 1.1rem; }
	@media (min-width: 560px) {
		.plate-body { padding: 1.6rem 1.5rem; }
	}

	.desc {
		margin: 0 0 1.35rem;
		max-width: 62ch;
		font-size: 0.95rem;
		line-height: 1.6;
		color: var(--text-muted);
	}
	.desc.flat { margin: 0; }
	.desc.sparse {
		margin-top: 1rem;
		font-size: 0.86rem;
		color: var(--text-dim);
	}

	/* ── Form controls ────────────────────────────────────────── */

	.field { margin-bottom: 1.35rem; }

	.lbl {
		display: block;
		margin-bottom: 0.5rem;
		font-family: var(--font-mono);
		font-size: 0.63rem;
		font-weight: 700;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text);
	}

	.ctl {
		display: block;
		width: 100%;
		padding: 0.72rem 0.85rem;
		border: 1px solid var(--border-hover);
		border-radius: var(--radius-sm);
		background: var(--bg);
		color: var(--text);
		font-family: inherit;
		font-size: 1rem;
		line-height: 1.5;
		transition: border-color 0.12s, box-shadow 0.12s;
	}
	.ctl::placeholder { color: var(--text-dim); }
	.ctl:hover { border-color: var(--text-dim); }
	.ctl:focus {
		outline: none;
		border-color: var(--primary);
		box-shadow: 0 0 0 3px var(--primary-muted);
	}
	.sel {
		max-width: 22rem;
		cursor: pointer;
	}

	/* ── The combobox ─────────────────────────────────────────── */
	/* "das feld angenehm groß": 3.25rem tall, full width, real type size —
	   the old one was a cramped pill you typed an address into blind. */

	.combo { position: relative; }
	.combo-input {
		min-height: 3.25rem;
		padding-left: 2.5rem;
		padding-right: 2.5rem;
		font-family: var(--font-mono);
		font-size: 0.95rem;
	}
	.combo-icon {
		position: absolute;
		top: 50%;
		left: 0.85rem;
		display: grid;
		place-items: center;
		transform: translateY(-50%);
		color: var(--text-dim);
		pointer-events: none;
	}
	.combo-icon.end { left: auto; right: 0.85rem; }
	.combo-clear {
		position: absolute;
		top: 50%;
		right: 0.5rem;
		display: grid;
		place-items: center;
		width: 2rem;
		height: 2rem;
		transform: translateY(-50%);
		border: 0;
		border-radius: var(--radius-sm);
		background: transparent;
		color: var(--text-dim);
		cursor: pointer;
		transition: color 0.12s, background-color 0.12s;
	}
	.combo-clear:hover { color: var(--primary); background: var(--bg-card-hover); }
	.combo-clear:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: -2px;
	}

	.options {
		position: absolute;
		z-index: 20;
		top: calc(100% + 3px);
		left: 0;
		right: 0;
		max-height: 17rem;
		margin: 0;
		padding: 0;
		overflow-y: auto;
		list-style: none;
		border: 1px solid var(--border-hover);
		border-radius: var(--radius-sm);
		background: var(--bg-card);
		box-shadow: var(--shadow-md);
	}
	.option {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.85rem;
		width: 100%;
		min-height: var(--tap-min);
		padding: 0.6rem 0.85rem;
		border: 0;
		border-bottom: 1px solid var(--rule-soft);
		background: transparent;
		font-family: inherit;
		text-align: left;
		cursor: pointer;
	}
	.option.active { background: var(--bg-card-hover); }
	.option:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: -2px;
	}
	.opt-mail {
		min-width: 0;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		font-family: var(--font-mono);
		font-size: 0.85rem;
		color: var(--text);
	}
	.opt-tier {
		flex: none;
		padding: 0.15rem 0.45rem;
		border: 1px solid var(--border-hover);
		border-radius: 2px;
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	.opt-tier.paid {
		border-color: var(--accent-amber);
		color: var(--accent-amber);
	}
	.option-empty {
		padding: 0.85rem;
		font-size: 0.88rem;
		line-height: 1.5;
		color: var(--text-dim);
	}

	.hint {
		margin: 0.5rem 0 0;
		font-size: 0.84rem;
		line-height: 1.5;
		color: var(--text-dim);
	}

	/* Who is about to be gifted, spelled out. */
	.resolved {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.5rem;
		margin: 0.8rem 0 0;
		padding-left: 0.75rem;
		border-left: 2px solid var(--accent-green);
		font-size: 0.9rem;
		color: var(--text-muted);
	}
	.resolved :global(svg) { flex: none; color: var(--accent-green); }
	.resolved.new { border-left-color: var(--ink-blue); }
	.res-mail {
		min-width: 0;
		overflow-wrap: anywhere;
		font-family: var(--font-mono);
		font-size: 0.86rem;
		color: var(--text);
	}
	.res-note {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
	}

	/* ── Actions ──────────────────────────────────────────────── */

	.acts {
		display: flex;
		flex-wrap: wrap;
		gap: 0.7rem;
		align-items: center;
	}

	.btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.55rem;
		min-height: var(--tap-min);
		padding: 0 1.35rem;
		border-radius: var(--radius-sm);
		border: 1.5px solid var(--text);
		background: var(--text);
		color: var(--bg);
		font-family: inherit;
		font-size: 0.94rem;
		font-weight: 600;
		cursor: pointer;
		transition: transform 0.12s ease-out, background-color 0.12s, border-color 0.12s;
	}
	.btn:hover:not(:disabled) { transform: translateY(-1px); }
	.btn:active { transform: none; }
	.btn:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: 2px;
	}
	.btn:disabled { opacity: 0.45; cursor: not-allowed; }

	.btn-stamp {
		background: var(--stamp);
		border-color: var(--stamp);
		color: var(--stamp-ink);
		font-weight: 700;
	}
	.btn-stamp:hover:not(:disabled) {
		background: var(--stamp-hover);
		border-color: var(--stamp-hover);
	}
	:global([data-theme='light']) .btn-stamp {
		border-color: var(--stamp-ink);
	}

	/* Revoke is destructive, so it stays quiet — a rule, not a fill. */
	.btn-quiet {
		background: transparent;
		border-color: var(--text-dim);
		color: var(--text);
		font-weight: 500;
	}
	.btn-quiet:hover:not(:disabled) {
		border-color: var(--danger);
		color: var(--danger);
	}

	.grant-msg {
		margin: 1.1rem 0 0;
		padding-left: 0.8rem;
		border-left: 2px solid var(--danger);
		font-size: 0.9rem;
		line-height: 1.5;
		color: var(--danger);
	}
	.grant-msg.ok {
		border-left-color: var(--accent-green);
		color: var(--accent-green);
	}

	/* ── Chart ────────────────────────────────────────────────── */

	.chart {
		display: flex;
		align-items: flex-end;
		gap: 2px;
		height: 8rem;
		padding-bottom: 1px;
		border-bottom: 2px solid var(--text);
	}
	.bar-slot {
		display: flex;
		flex: 1;
		align-items: flex-end;
		justify-content: center;
		height: 100%;
		min-width: 0;
	}
	.bar {
		width: 100%;
		min-height: 3px;
		background: var(--primary);
	}
	/* An empty day is a hairline on the baseline, not a stub pretending to be
	   a value — the distinction is the whole point of the rebuild. */
	.bar.zero {
		height: 1px;
		min-height: 1px;
		background: var(--border-hover);
	}

	.axis {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		margin-top: 0.6rem;
		font-family: var(--font-mono);
		font-size: 0.62rem;
		letter-spacing: 0.1em;
		font-variant-numeric: tabular-nums;
		color: var(--text-dim);
	}
	.peak {
		text-align: center;
		text-transform: uppercase;
		letter-spacing: 0.12em;
		color: var(--ink-blue);
	}

	/* ── Directory table ──────────────────────────────────────── */

	.table-wrap {
		width: 100%;
		overflow-x: auto;
	}
	table {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.88rem;
	}
	thead th {
		padding: 0.7rem 0.85rem;
		border-bottom: 2px solid var(--text);
		font-family: var(--font-mono);
		font-size: 0.6rem;
		font-weight: 700;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		text-align: left;
		white-space: nowrap;
		color: var(--text);
	}
	tbody td {
		padding: 0.7rem 0.85rem;
		border-bottom: 1px solid var(--rule-soft);
		white-space: nowrap;
		color: var(--text);
	}
	tbody tr:last-child td { border-bottom: 0; }
	tbody tr:hover { background: var(--bg-card-hover); }
	td.mail {
		font-family: var(--font-mono);
		font-size: 0.8rem;
	}
	td.dim {
		font-variant-numeric: tabular-nums;
		color: var(--text-dim);
	}

	.tag {
		display: inline-block;
		padding: 0.15rem 0.45rem;
		border: 1px solid var(--border-hover);
		border-radius: 2px;
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	.tag.admin {
		border-color: var(--primary);
		color: var(--primary);
	}
	.tag.paid {
		border-color: var(--accent-amber);
		color: var(--accent-amber);
	}

	@media (prefers-reduced-motion: reduce) {
		.btn { transition: none; }
		.btn:hover:not(:disabled) { transform: none; }
	}
</style>
