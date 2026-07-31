<script lang="ts">
	import { t } from '$lib/i18n';
	import KeyClock from '$lib/components/KeyClock.svelte';
	import { buildKeyDial, loadHistory, loadSettings, type KeyDial } from '$lib/services/progress';
	import type { NotationSystem } from '$lib/engine';
	import { getAuthState, onAuthChange, signOut, deleteAccount, updatePassword } from '$lib/services/auth';
	import { downloadCloudData, uploadLocalDataToCloud } from '$lib/services/cloud-sync';
	import { getSubscription, isBeta, createPortalSession } from '$lib/services/subscription';
	import { getSupabase } from '$lib/services/supabase';
	import { toastSuccess, toastError, toastInfo } from '$lib/services/toast';
	import { isTelemetryEnabled, setTelemetryEnabled } from '$lib/services/telemetry';
	import { goto } from '$app/navigation';
	import { PartyPopper } from 'lucide-svelte';
	import type { AuthState } from '$lib/services/auth';
	import type { SubscriptionInfo } from '$lib/services/subscription';

	let auth: AuthState = $state(getAuthState());
	let sub: SubscriptionInfo | null = $state(null);
	let showDeleteConfirm = $state(false);
	let syncing = $state(false);
	let showPasswordChange = $state(false);
	let newPassword = $state('');
	let confirmNewPassword = $state('');
	let passwordError = $state('');
	let displayName = $state('');
	let savingName = $state(false);
	let telemetryEnabled = $state(isTelemetryEnabled());

	// ─── Progress: the dial, at a size you can actually read ───
	/** The coach's mastery threshold — the same one the trainer diffs against. */
	const DIAL_THRESHOLD_MS = 2000;
	/* localStorage is off-limits until mount, so both start empty and fill in. */
	let dial: KeyDial[] = $state(buildKeyDial([]));
	let notationSystem: NotationSystem = $state('international');
	$effect(() => {
		dial = buildKeyDial(loadHistory(), DIAL_THRESHOLD_MS);
		notationSystem = (loadSettings()?.notationSystem ?? 'international') as NotationSystem;
	});
	const fluentCount = $derived(dial.filter((d) => d.fluent).length);
	const playedCount = $derived(dial.filter((d) => d.count > 0).length);

	function handleTelemetryToggle() {
		telemetryEnabled = !telemetryEnabled;
		setTelemetryEnabled(telemetryEnabled);
	}

	$effect(() => {
		const unsub = onAuthChange(async (s) => {
			auth = s;
			if (s.user) {
				sub = await getSubscription();
				const { data } = await getSupabase().from('profiles').select('display_name').eq('id', s.user.id).single();
				displayName = data?.display_name ?? '';
			}
		});
		return unsub;
	});

	async function handleSyncToCloud() {
		syncing = true;
		const { error } = await uploadLocalDataToCloud();
		if (error) toastError(`Error: ${error.message}`);
		else toastSuccess(t('account.sync_success'));
		syncing = false;
	}

	async function handleSyncFromCloud() {
		syncing = true;
		const { merged, error } = await downloadCloudData();
		if (error) toastError(`Error: ${error.message}`);
		else if (merged) toastSuccess(t('account.download_success'));
		else toastInfo(t('account.no_cloud_data'));
		syncing = false;
	}

	async function handleSignOut() {
		await signOut();
		goto('/');
	}

	async function handleDeleteAccount() {
		const { error } = await deleteAccount();
		if (error) toastError(`Error: ${error.message}`);
		else goto('/');
	}

	async function handleManageSubscription() {
		const { url, error } = await createPortalSession();
		if (url) window.location.href = url;
		else toastError(error || 'Error');
	}

	async function handleSaveDisplayName() {
		if (!auth.user) return;
		savingName = true;
		const { error } = await getSupabase().from('profiles').update({ display_name: displayName.trim() || null }).eq('id', auth.user.id);
		if (error) toastError(error.message);
		else toastSuccess(t('account.display_name_saved'));
		savingName = false;
	}

	async function handlePasswordChange(e: Event) {
		e.preventDefault();
		passwordError = '';
		if (newPassword !== confirmNewPassword) {
			passwordError = t('auth.passwords_mismatch');
			return;
		}
		if (newPassword.length < 8) {
			passwordError = t('auth.password_too_short');
			return;
		}
		const { error } = await updatePassword(newPassword);
		if (error) {
			passwordError = error.message;
		} else {
			toastSuccess(t('account.password_changed'));
			newPassword = '';
			confirmNewPassword = '';
			showPasswordChange = false;
		}
	}
</script>

<svelte:head>
	<title>{t('account.title')} – jazzchords.app</title>
</svelte:head>

<main class="acct">
	<div class="acct-col">
		<header class="acct-head">
			<p class="plate">{t('nav_auth.account')}</p>
			<h1>{t('account.heading')}</h1>
		</header>

		<!-- Progress: the circle of fifths, with the times on. This is the
		     "look back at where I am" surface, so it shows the numbers the
		     setup screen's compact dial deliberately leaves out.

		     Deliberately OUTSIDE the auth branch: the dial reads local practice
		     history, not account data, so someone practising without an account
		     has every right to see where they stand. It stays hidden until
		     there is history to show. -->
		{#if playedCount > 0}
			<section class="panel">
				<h2 class="panel-title">{t('account.progress')}</h2>
				<div class="dial-panel">
					<KeyClock {dial} thresholdMs={DIAL_THRESHOLD_MS} size={300} {notationSystem} />
					<p class="dial-count">{t('clock.fluent_count', { count: fluentCount })}</p>
					<p class="note-body">{t('clock.account_sub')}</p>
				</div>
			</section>
		{/if}

		{#if !auth.user}
			<section class="panel panel-empty">
				<p>{t('account.not_logged_in')}</p>
				<a href="/auth/login" class="btn-stamp">{t('auth.login_button')}</a>
			</section>
		{:else}
			<!-- Profile info -->
			<section class="panel">
				<h2 class="panel-title">{t('account.profile')}</h2>
				<dl class="ledger">
					<div class="ledger-cell">
						<dt>{t('auth.email')}</dt>
						<dd>{auth.user.email}</dd>
					</div>
					<div class="ledger-cell">
						<dt>{t('account.member_since')}</dt>
						<dd>{new Date(auth.user.created_at).toLocaleDateString()}</dd>
					</div>
				</dl>
				<div class="flex items-end gap-2 max-w-sm">
					<div class="flex-1">
						<label for="display-name" class="field-label">{t('account.display_name')}</label>
						<input
							id="display-name"
							type="text"
							bind:value={displayName}
							placeholder={t('account.display_name_placeholder')}
							maxlength={50}
							class="field"
						/>
					</div>
					<button onclick={handleSaveDisplayName} disabled={savingName} class="btn-stamp btn-sm">
						{savingName ? '…' : t('account.save')}
					</button>
				</div>
				<button onclick={() => showPasswordChange = !showPasswordChange} class="link">
					{t('account.change_password')}
				</button>
				{#if showPasswordChange}
					<form onsubmit={handlePasswordChange} class="space-y-3 max-w-sm">
						<input type="password" bind:value={newPassword} minlength={8} placeholder={t('account.new_password')}
							class="field" />
						<input type="password" bind:value={confirmNewPassword} minlength={8} placeholder={t('auth.confirm_password')}
							class="field" />
						{#if passwordError}<p class="err-text">{passwordError}</p>{/if}
						<button type="submit" class="btn-stamp btn-sm">{t('account.save')}</button>
					</form>
				{/if}
			</section>

			<!-- Subscription -->
			<section class="panel">
				<h2 class="panel-title">{t('account.subscription')}</h2>
				{#if isBeta()}
					<div class="live-note">
						<PartyPopper size={18} class="shrink-0" aria-hidden="true" />
						<div>
							<p class="live-title">{t('account.beta_active')}</p>
							<p class="note-body">{t('account.beta_description')}</p>
						</div>
					</div>
				{:else if sub}
					<div class="panel-body">
						<p>{t('account.current_plan')}: <span class="plan-tier">{sub.tier}</span></p>
						{#if sub.currentPeriodEnd}
							<p class="dim">{t('account.renews')}: {new Date(sub.currentPeriodEnd).toLocaleDateString()}</p>
						{/if}
						<button onclick={handleManageSubscription} class="btn-rule btn-sm">
							{t('account.manage_subscription')}
						</button>
					</div>
				{:else}
					<div class="panel-body">
						<p>{t('account.free_plan')}</p>
						<a href="/pricing" class="btn-stamp btn-sm">{t('account.upgrade')}</a>
					</div>
				{/if}
			</section>

			<!-- Cloud Sync -->
			<section class="panel">
				<h2 class="panel-title">{t('account.cloud_sync')}</h2>
				<p class="note-body">{t('account.cloud_sync_desc')}</p>
				<div class="btn-row">
					<button onclick={handleSyncToCloud} disabled={syncing} class="btn-stamp btn-sm">
						{syncing ? '…' : t('account.upload_to_cloud')}
					</button>
					<button onclick={handleSyncFromCloud} disabled={syncing} class="btn-rule btn-sm">
						{syncing ? '…' : t('account.download_from_cloud')}
					</button>
				</div>
			</section>

			<!-- Danger Zone -->
			<section class="panel panel-danger">
				<h2 class="panel-title is-danger">{t('account.danger_zone')}</h2>
				<div class="btn-row">
					<button onclick={handleSignOut} class="btn-rule btn-sm">
						{t('account.sign_out')}
					</button>
					<button onclick={() => showDeleteConfirm = true} class="btn-danger btn-sm">
						{t('account.delete_account')}
					</button>
				</div>
				{#if showDeleteConfirm}
					<div class="confirm" role="alert">
						<p class="err-text">{t('account.delete_confirm')}</p>
						<div class="btn-row">
							<button onclick={handleDeleteAccount} class="btn-danger-solid btn-sm">{t('account.delete_yes')}</button>
							<button onclick={() => showDeleteConfirm = false} class="btn-rule btn-sm">{t('account.delete_cancel')}</button>
						</div>
					</div>
				{/if}
			</section>
		{/if}

		<!-- Privacy / Telemetry -->
		<section class="panel">
			<h2 class="panel-title">{t('account.privacy')}</h2>
			<p class="note-body">{t('account.privacy_desc')}</p>
			<label class="check">
				<input
					type="checkbox"
					checked={telemetryEnabled}
					onchange={handleTelemetryToggle}
					aria-label={t('account.privacy_toggle_label')}
				/>
				<span>{t('account.privacy_toggle_label')}</span>
			</label>
		</section>
	</div>
</main>

<style>
	.acct {
		flex: 1;
		padding: clamp(2.5rem, 7vw, 4rem) clamp(1rem, 5vw, 2rem) 5rem;
	}
	.acct-col {
		max-width: 44rem;
		margin: 0 auto;
		display: flex;
		flex-direction: column;
		gap: 2rem;
	}

	.acct-head {
		padding-bottom: 1.25rem;
		border-bottom: 1px solid var(--border);
	}
	.plate {
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.18em;
		text-transform: uppercase;
		color: var(--primary);
		margin-bottom: 0.7rem;
	}
	.acct-head h1 {
		font-family: var(--font-display);
		font-size: clamp(1.9rem, 5.5vw, 2.5rem);
		font-weight: 600;
		line-height: 1.1;
		letter-spacing: -0.025em;
		color: var(--text);
		margin: 0;
	}

	/* ── Panels: ruled sections, not floating cards ── */
	.panel {
		border: 1px solid var(--border);
		background: var(--bg-card);
		padding: clamp(1.15rem, 3.5vw, 1.6rem);
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}
	.panel-empty {
		align-items: flex-start;
		gap: 1.15rem;
		color: var(--text-muted);
		font-size: 0.92rem;
	}
	.panel-danger {
		border-color: color-mix(in srgb, var(--danger) 45%, transparent);
	}
	.panel-title {
		font-family: var(--font-display);
		font-size: 1.15rem;
		font-weight: 600;
		letter-spacing: -0.015em;
		color: var(--text);
		padding-bottom: 0.7rem;
		border-bottom: 1px solid color-mix(in srgb, var(--border) 70%, transparent);
	}
	.panel-title.is-danger {
		color: var(--danger);
		border-bottom-color: color-mix(in srgb, var(--danger) 30%, transparent);
	}
	.panel-body {
		display: flex;
		flex-direction: column;
		align-items: flex-start;
		gap: 0.65rem;
		font-size: 0.9rem;
		color: var(--text-muted);
	}
	.note-body {
		font-size: 0.88rem;
		line-height: 1.55;
		color: var(--text-muted);
	}
	/* The dial sits centred in its panel; the count reads as the caption. */
	.dial-panel {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.6rem;
		text-align: center;
	}
	.dial-count {
		font-family: var(--font-display);
		font-size: 1rem;
		font-weight: 600;
		color: var(--text);
	}
	.dim {
		color: var(--text-dim);
	}
	.plan-tier {
		font-family: var(--font-display);
		font-size: 1.05rem;
		font-weight: 600;
		color: var(--primary);
		text-transform: capitalize;
	}

	/* ── Ledger: the profile facts, ruled like a register ── */
	.ledger {
		display: grid;
		grid-template-columns: 1fr;
		border: 1px solid var(--border);
		margin: 0;
	}
	@media (min-width: 480px) {
		.ledger {
			grid-template-columns: 1fr 1fr;
		}
	}
	.ledger-cell {
		padding: 0.75rem 0.9rem;
		min-width: 0;
		border-bottom: 1px solid color-mix(in srgb, var(--border) 70%, transparent);
	}
	.ledger-cell:last-child {
		border-bottom: none;
	}
	@media (min-width: 480px) {
		.ledger-cell {
			border-bottom: none;
			border-right: 1px solid color-mix(in srgb, var(--border) 70%, transparent);
		}
		.ledger-cell:last-child {
			border-right: none;
		}
	}
	.ledger-cell dt {
		font-family: var(--font-mono);
		font-size: 0.58rem;
		letter-spacing: 0.15em;
		text-transform: uppercase;
		color: var(--text-dim);
	}
	.ledger-cell dd {
		margin: 0.3rem 0 0;
		font-size: 0.9rem;
		color: var(--text);
		overflow-wrap: anywhere;
	}

	/* ── Fields ── */
	.field-label {
		display: block;
		font-family: var(--font-mono);
		font-size: 0.58rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
		margin-bottom: 0.4rem;
	}
	.field {
		width: 100%;
		min-height: var(--tap-min);
		padding: 0.55rem 0.7rem;
		border-radius: 2px;
		background: var(--bg);
		border: 1px solid var(--border);
		color: var(--text);
		font-size: 0.9rem;
		transition: border-color 0.15s ease, box-shadow 0.15s ease;
	}
	.field::placeholder {
		color: var(--text-dim);
	}
	.field:focus {
		outline: none;
		border-color: var(--primary);
		box-shadow: inset 0 -2px 0 var(--primary);
	}

	/* ── Buttons: three flat weights, square corners, no gradients ── */
	.btn-row {
		display: flex;
		flex-wrap: wrap;
		gap: 0.6rem;
	}
	.btn-stamp,
	.btn-rule,
	.btn-danger,
	.btn-danger-solid {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		min-height: var(--tap-min);
		padding: 0 1.1rem;
		border-radius: 2px;
		font-size: 0.9rem;
		font-weight: 600;
		text-decoration: none;
		cursor: pointer;
		transition: background 0.15s ease, border-color 0.15s ease, color 0.15s ease;
	}
	.btn-sm {
		min-height: 2.25rem;
		padding: 0 0.85rem;
		font-size: 0.82rem;
	}
	.btn-stamp {
		background: var(--primary);
		border: 1px solid var(--primary);
		color: var(--primary-text);
	}
	.btn-stamp:hover:not(:disabled) {
		background: var(--primary-hover);
		border-color: var(--primary-hover);
	}
	.btn-rule {
		background: transparent;
		border: 1px solid var(--border);
		color: var(--text-muted);
	}
	.btn-rule:hover:not(:disabled) {
		border-color: var(--text-muted);
		color: var(--text);
		background: var(--bg-card-hover);
	}
	.btn-danger {
		background: transparent;
		border: 1px solid color-mix(in srgb, var(--danger) 50%, transparent);
		color: var(--danger);
	}
	.btn-danger:hover {
		background: var(--danger-muted);
		border-color: var(--danger);
	}
	.btn-danger-solid {
		background: var(--danger);
		border: 1px solid var(--danger);
		color: var(--bg);
	}
	.btn-danger-solid:hover {
		filter: brightness(1.08);
	}
	.btn-stamp:disabled,
	.btn-rule:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.link {
		background: none;
		border: none;
		padding: 0;
		align-self: flex-start;
		cursor: pointer;
		font-size: 0.85rem;
		color: var(--text);
		text-decoration: underline;
		text-decoration-color: var(--primary);
		text-underline-offset: 3px;
		transition: color 0.15s ease;
	}
	.link:hover {
		color: var(--primary);
	}

	/* Amber is reserved for live/active state — the beta run is exactly that */
	.live-note {
		display: flex;
		align-items: flex-start;
		gap: 0.7rem;
		border-left: 2px solid var(--accent-amber);
		padding-left: 0.85rem;
	}
	.live-note :global(svg) {
		color: var(--accent-amber);
		margin-top: 0.2rem;
	}
	.live-title {
		font-weight: 600;
		color: var(--accent-amber);
		font-size: 0.92rem;
	}

	.err-text {
		font-size: 0.85rem;
		color: var(--danger);
	}
	.confirm {
		display: flex;
		flex-direction: column;
		gap: 0.85rem;
		border-left: 2px solid var(--danger);
		background: var(--danger-muted);
		padding: 0.85rem 1rem;
	}

	.check {
		display: flex;
		align-items: center;
		gap: 0.6rem;
		width: fit-content;
		font-size: 0.88rem;
		color: var(--text-muted);
		cursor: pointer;
	}
	.check input {
		accent-color: var(--primary);
		flex: none;
	}

	form {
		display: flex;
		flex-direction: column;
		gap: 0.7rem;
		max-width: 22rem;
	}
</style>
