<script lang="ts">
	import { t } from '$lib/i18n';
	import { onMount } from 'svelte';

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

	// Generate last 30 days for chart
	function getLast30Days(): string[] {
		const days: string[] = [];
		for (let i = 29; i >= 0; i--) {
			const d = new Date();
			d.setDate(d.getDate() - i);
			days.push(d.toISOString().slice(0, 10));
		}
		return days;
	}

	const chartDays = getLast30Days();
	const maxSignups = $derived(Math.max(1, ...chartDays.map(d => signupsByDay[d] || 0)));

	// ── Gift a subscription tier to a user (no Stripe charge) ──
	let grantEmail = $state('');
	let grantTier = $state('pro');
	let grantBusy = $state(false);
	let grantMsg = $state('');
	let grantOk = $state(false);

	async function submitGrant(revoke = false) {
		if (!grantEmail.trim()) return;
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

<main class="flex-1 px-4 py-8 sm:py-12">
	<div class="max-w-6xl mx-auto space-y-8">
		<h1 class="text-3xl font-bold text-gradient">{t('admin.heading')}</h1>

		{#if loading}
			<div class="card surface-glass p-8 text-center text-[var(--text-muted)]">Loading...</div>
		{:else if error}
			<div class="card surface-glass p-8 text-center text-red-400">{error}</div>
		{:else if stats}
			<!-- Overview cards -->
			<div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
				<div class="card surface-glass p-5 text-center">
					<p class="text-3xl font-bold text-[var(--primary)]">{stats.totalUsers}</p>
					<p class="text-sm text-[var(--text-muted)] mt-1">{t('admin.total_users')}</p>
				</div>
				<div class="card surface-glass p-5 text-center">
					<p class="text-3xl font-bold text-[var(--accent-gold)]">{stats.activeToday}</p>
					<p class="text-sm text-[var(--text-muted)] mt-1">{t('admin.active_today')}</p>
				</div>
				<div class="card surface-glass p-5 text-center">
					<p class="text-3xl font-bold text-[var(--primary)]">{stats.totalSessions}</p>
					<p class="text-sm text-[var(--text-muted)] mt-1">{t('admin.total_sessions')}</p>
				</div>
				<div class="card surface-glass p-5 text-center">
					<p class="text-3xl font-bold text-green-400">{stats.activeSubs}</p>
					<p class="text-sm text-[var(--text-muted)] mt-1">{t('admin.active_subs')}</p>
				</div>
			</div>

			<!-- Gift a membership -->
			<div class="card surface-glass p-6 space-y-3">
				<h2 class="text-lg font-semibold">{t('admin.grant_title')}</h2>
				<p class="text-sm text-[var(--text-muted)]">{t('admin.grant_desc')}</p>
				<div class="flex flex-col sm:flex-row gap-2.5">
					<input
						type="email"
						bind:value={grantEmail}
						placeholder={t('admin.grant_email_placeholder')}
						class="pill-input flex-1"
						autocomplete="off"
					/>
					<select bind:value={grantTier} class="pill-input sm:w-44">
						<option value="pro">Pro</option>
						<option value="educator">Educator</option>
						<option value="institution">Institution</option>
					</select>
					<button
						onclick={() => submitGrant(false)}
						disabled={grantBusy || !grantEmail.trim()}
						class="pill-btn pill-btn-primary px-5 disabled:opacity-50 disabled:cursor-wait"
					>
						{grantBusy ? '…' : t('admin.grant_cta')}
					</button>
					<button
						onclick={() => submitGrant(true)}
						disabled={grantBusy || !grantEmail.trim()}
						class="pill-btn pill-btn-secondary px-4 disabled:opacity-50"
						title={t('admin.grant_revoke')}
					>
						{t('admin.grant_revoke')}
					</button>
				</div>
				{#if grantMsg}
					<p class="text-sm {grantOk ? 'text-[var(--success)]' : 'text-[var(--danger)]'}">{grantMsg}</p>
				{/if}
			</div>

			<!-- Signup chart -->
			<div class="card surface-glass p-6 space-y-4">
				<h2 class="text-lg font-semibold">{t('admin.signups_chart')}</h2>
				<div class="flex items-end gap-[2px] h-32">
					{#each chartDays as day}
						{@const count = signupsByDay[day] || 0}
						{@const height = maxSignups > 0 ? (count / maxSignups) * 100 : 0}
						<div class="flex-1 flex flex-col items-center justify-end group relative">
							<div
								class="w-full rounded-t-sm transition-all {count > 0 ? 'bg-[var(--primary)]' : 'bg-[var(--border)]'}"
								style="height: {Math.max(height, 2)}%"
							></div>
							{#if count > 0}
								<div class="absolute -top-6 hidden group-hover:block text-xs bg-[var(--bg-card)] border border-[var(--border)] px-1.5 py-0.5 rounded whitespace-nowrap z-10">
									{day.slice(5)}: {count}
								</div>
							{/if}
						</div>
					{/each}
				</div>
				<div class="flex justify-between text-xs text-[var(--text-dim)]">
					<span>{chartDays[0]?.slice(5)}</span>
					<span>{chartDays[chartDays.length - 1]?.slice(5)}</span>
				</div>
			</div>

			<!-- Tier distribution -->
			<div class="card surface-glass p-6 space-y-4">
				<h2 class="text-lg font-semibold">{t('admin.subscriptions')}</h2>
				<div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
					{#each Object.entries(tierDistribution) as [tier, count]}
						<div class="p-3 rounded-xl bg-[var(--bg)]/70 border border-[var(--border)] text-center backdrop-blur-sm">
							<p class="text-xl font-bold">{count}</p>
							<p class="text-xs text-[var(--text-muted)] capitalize">{tier}</p>
						</div>
					{/each}
				</div>
			</div>

			<!-- Recent users -->
			<div class="card surface-glass p-6 space-y-4">
				<h2 class="text-lg font-semibold">{t('admin.recent_users')}</h2>
				{#if recentUsers.length === 0}
					<p class="text-sm text-[var(--text-muted)]">{t('admin.no_data')}</p>
				{:else}
					<div class="overflow-x-auto">
						<table class="w-full text-sm">
							<thead>
								<tr class="border-b border-[var(--border)] text-left text-[var(--text-muted)]">
									<th class="py-2 px-3">{t('admin.email')}</th>
									<th class="py-2 px-3">{t('admin.role')}</th>
									<th class="py-2 px-3">{t('admin.tier')}</th>
									<th class="py-2 px-3">{t('admin.joined')}</th>
									<th class="py-2 px-3">{t('admin.last_active')}</th>
								</tr>
							</thead>
							<tbody>
								{#each recentUsers as user}
									<tr class="border-b border-[var(--border)]/30 hover:bg-[var(--bg-card)] transition-colors">
										<td class="py-2 px-3 font-mono text-xs">{user.email}</td>
										<td class="py-2 px-3">
											<span class="px-2 py-0.5 rounded-full text-xs {user.role === 'admin' ? 'bg-[var(--primary)]/20 text-[var(--primary)]' : 'bg-[var(--border)] text-[var(--text-dim)]'}">
												{user.role}
											</span>
										</td>
										<td class="py-2 px-3">
											<span class="px-2 py-0.5 rounded-full text-xs capitalize {user.tier === 'pro' ? 'bg-[var(--accent-gold)]/20 text-[var(--accent-gold)]' : 'bg-[var(--border)] text-[var(--text-dim)]'}">
												{user.tier}
											</span>
										</td>
										<td class="py-2 px-3 text-[var(--text-dim)]">{new Date(user.created_at).toLocaleDateString()}</td>
										<td class="py-2 px-3 text-[var(--text-dim)]">{user.last_sign_in_at ? new Date(user.last_sign_in_at).toLocaleDateString() : '–'}</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				{/if}
			</div>
		{/if}
	</div>
</main>
