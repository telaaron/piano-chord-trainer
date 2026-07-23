<script lang="ts">
	import { t } from '$lib/i18n';
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

<main class="flex-1 px-4 py-16">
	<div class="max-w-2xl mx-auto space-y-8">
		<h1 class="text-3xl font-bold text-gradient">{t('account.heading')}</h1>

		{#if !auth.user}
			<div class="card surface-glass p-8 text-center space-y-4">
				<p class="text-[var(--text-muted)]">{t('account.not_logged_in')}</p>
				<a href="/auth/login" class="inline-block px-6 py-2.5 pill-btn pill-btn-primary text-white font-medium transition-colors">
					{t('auth.login_button')}
				</a>
			</div>
		{:else}
			<!-- Profile info -->
			<div class="card surface-glass p-6 space-y-4">
				<h2 class="text-lg font-semibold">{t('account.profile')}</h2>
				<div class="grid grid-cols-2 gap-4 text-sm">
					<div>
						<span class="text-[var(--text-dim)]">{t('auth.email')}</span>
						<p class="text-[var(--text)]">{auth.user.email}</p>
					</div>
					<div>
						<span class="text-[var(--text-dim)]">{t('account.member_since')}</span>
						<p class="text-[var(--text)]">{new Date(auth.user.created_at).toLocaleDateString()}</p>
					</div>
				</div>
				<div class="flex items-end gap-2 max-w-sm">
					<div class="flex-1">
						<label for="display-name" class="text-xs text-[var(--text-dim)] block mb-1">{t('account.display_name')}</label>
						<input
							id="display-name"
							type="text"
							bind:value={displayName}
							placeholder={t('account.display_name_placeholder')}
							maxlength={50}
							class="pill-input text-sm"
						/>
					</div>
					<button onclick={handleSaveDisplayName} disabled={savingName} class="px-3 py-2 pill-btn pill-btn-primary text-white text-sm disabled:opacity-50">
						{savingName ? '…' : t('account.save')}
					</button>
				</div>
				<button onclick={() => showPasswordChange = !showPasswordChange} class="text-sm text-[var(--primary)] hover:underline">
					{t('account.change_password')}
				</button>
				{#if showPasswordChange}
					<form onsubmit={handlePasswordChange} class="space-y-3 max-w-sm">
						<input type="password" bind:value={newPassword} minlength={8} placeholder={t('account.new_password')}
							class="pill-input" />
						<input type="password" bind:value={confirmNewPassword} minlength={8} placeholder={t('auth.confirm_password')}
							class="pill-input" />
						{#if passwordError}<p class="text-sm text-red-400">{passwordError}</p>{/if}
						<button type="submit" class="px-4 py-2 pill-btn pill-btn-primary text-white text-sm">{t('account.save')}</button>
					</form>
				{/if}
			</div>

			<!-- Subscription -->
			<div class="card surface-glass p-6 space-y-4">
				<h2 class="text-lg font-semibold">{t('account.subscription')}</h2>
				{#if isBeta()}
					<div class="status-glass flex items-center gap-3">
						<PartyPopper size={20} class="text-[var(--gold)] shrink-0" aria-hidden="true" />
						<div>
							<p class="font-medium text-[var(--gold)]">{t('account.beta_active')}</p>
							<p class="text-sm text-[var(--text-muted)]">{t('account.beta_description')}</p>
						</div>
					</div>
				{:else if sub}
					<div class="text-sm space-y-2">
						<p>{t('account.current_plan')}: <span class="font-semibold text-[var(--primary)] capitalize">{sub.tier}</span></p>
						{#if sub.currentPeriodEnd}
							<p class="text-[var(--text-dim)]">{t('account.renews')}: {new Date(sub.currentPeriodEnd).toLocaleDateString()}</p>
						{/if}
						<button onclick={handleManageSubscription} class="px-4 py-2 pill-btn pill-btn-secondary text-sm transition-colors">
							{t('account.manage_subscription')}
						</button>
					</div>
				{:else}
					<div class="text-sm space-y-2">
						<p class="text-[var(--text-muted)]">{t('account.free_plan')}</p>
						<a href="/pricing" class="inline-block px-4 py-2 pill-btn pill-btn-primary text-white text-sm transition-colors">
							{t('account.upgrade')}
						</a>
					</div>
				{/if}
			</div>

			<!-- Cloud Sync -->
			<div class="card surface-glass p-6 space-y-4">
				<h2 class="text-lg font-semibold">{t('account.cloud_sync')}</h2>
				<p class="text-sm text-[var(--text-muted)]">{t('account.cloud_sync_desc')}</p>
				<div class="flex flex-wrap gap-3">
					<button onclick={handleSyncToCloud} disabled={syncing}
						class="px-4 py-2 pill-btn pill-btn-primary text-white text-sm disabled:opacity-50 transition-colors">
						{syncing ? '...' : t('account.upload_to_cloud')}
					</button>
					<button onclick={handleSyncFromCloud} disabled={syncing}
						class="px-4 py-2 pill-btn pill-btn-secondary text-sm disabled:opacity-50 transition-colors">
						{syncing ? '...' : t('account.download_from_cloud')}
					</button>
				</div>
			</div>

			<!-- Danger Zone -->
			<div class="card surface-glass p-6 space-y-4 border-red-500/30">
				<h2 class="text-lg font-semibold text-red-400">{t('account.danger_zone')}</h2>
				<div class="flex flex-wrap gap-3">
					<button onclick={handleSignOut}
						class="px-4 py-2 pill-btn pill-btn-secondary text-sm text-[var(--text-muted)] hover:text-[var(--text)] transition-colors">
						{t('account.sign_out')}
					</button>
					<button onclick={() => showDeleteConfirm = true}
						class="px-4 py-2 pill-btn border border-red-500/30 text-sm text-red-400 hover:bg-red-500/10 transition-colors">
						{t('account.delete_account')}
					</button>
				</div>
				{#if showDeleteConfirm}
					<div class="status-danger p-4 space-y-3">
						<p class="text-sm text-red-400">{t('account.delete_confirm')}</p>
						<div class="flex gap-3">
							<button onclick={handleDeleteAccount} class="px-4 py-2 pill-btn bg-red-600 text-white text-sm">{t('account.delete_yes')}</button>
							<button onclick={() => showDeleteConfirm = false} class="px-4 py-2 pill-btn pill-btn-secondary text-sm">{t('account.delete_cancel')}</button>
						</div>
					</div>
				{/if}
			</div>
		{/if}

		<!-- Privacy / Telemetry -->
		<div class="card surface-glass p-6 space-y-4">
			<h2 class="text-lg font-semibold">{t('account.privacy')}</h2>
			<p class="text-sm text-[var(--text-muted)]">{t('account.privacy_desc')}</p>
			<label class="flex items-center gap-3 text-sm cursor-pointer w-fit">
				<input
					type="checkbox"
					checked={telemetryEnabled}
					onchange={handleTelemetryToggle}
					class="accent-[var(--primary)]"
					aria-label={t('account.privacy_toggle_label')}
				/>
				{t('account.privacy_toggle_label')}
			</label>
		</div>
	</div>
</main>
