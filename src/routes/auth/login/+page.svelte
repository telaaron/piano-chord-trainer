<script lang="ts">
	import { t } from '$lib/i18n';
	import { signIn, signUp, resetPassword } from '$lib/services/auth';
	import { uploadLocalDataToCloud } from '$lib/services/cloud-sync';
	import { toastSuccess, toastError } from '$lib/services/toast';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';

	let mode: 'login' | 'signup' | 'reset' = $state('login');
	let email = $state('');
	let password = $state('');
	let confirmPassword = $state('');
	let errorMsg = $state('');
	let loading = $state(false);
	let mergeLocal = $state(true);

	const redirect = $derived(page.url.searchParams.get('redirect') || '/train');

	async function handleSubmit(e: Event) {
		e.preventDefault();
		errorMsg = '';
		loading = true;

		try {
			if (mode === 'reset') {
				const { error } = await resetPassword(email);
				if (error) {
					errorMsg = error.message;
				} else {
					toastSuccess(t('auth.reset_sent'));
					mode = 'login';
				}
				loading = false;
				return;
			}

			if (mode === 'signup') {
				if (password !== confirmPassword) {
					errorMsg = t('auth.passwords_mismatch');
					loading = false;
					return;
				}
				if (password.length < 8) {
					errorMsg = t('auth.password_too_short');
					loading = false;
					return;
				}
				const { error } = await signUp(email, password);
				if (error) {
					errorMsg = error.message;
					loading = false;
					return;
				}
				toastSuccess(t('auth.check_email'), { duration: 8000 });
				loading = false;
				return;
			}

			// Login
			const { error } = await signIn(email, password);
			if (error) {
				errorMsg = error.message;
				loading = false;
				return;
			}

			// Merge local data if opted in
			if (mergeLocal) {
				await uploadLocalDataToCloud();
			}

			goto(redirect);
		} catch {
			errorMsg = t('auth.unknown_error');
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>{mode === 'login' ? t('auth.login_title') : mode === 'signup' ? t('auth.signup_title') : t('auth.reset_title')} – jazzchords.app</title>
</svelte:head>

<main class="flex-1 flex items-center justify-center px-4 py-16">
	<div class="w-full max-w-md">
		<div class="card surface-glass p-8 space-y-6">
			<!-- Header -->
			<div class="text-center space-y-2">
				<h1 class="text-2xl font-bold text-gradient">
					{#if mode === 'login'}{t('auth.login_heading')}{:else if mode === 'signup'}{t('auth.signup_heading')}{:else}{t('auth.reset_heading')}{/if}
				</h1>
				<p class="text-sm text-[var(--text-muted)]">
					{#if mode === 'login'}{t('auth.login_subheading')}{:else if mode === 'signup'}{t('auth.signup_subheading')}{:else}{t('auth.reset_subheading')}{/if}
				</p>
			</div>

			<!-- Sync hint -->
			{#if mode === 'signup' || mode === 'login'}
				<div class="status-glass flex items-start gap-3 text-sm">
					<span class="text-[var(--primary)] text-lg mt-0.5">☁️</span>
					<p class="text-[var(--text-muted)]">{t('auth.sync_hint')}</p>
				</div>
			{/if}

			<!-- Form -->
			<form onsubmit={handleSubmit} class="space-y-4">
				<div>
					<label for="email" class="block text-sm font-medium text-[var(--text-muted)] mb-1">{t('auth.email')}</label>
					<input
						id="email"
						type="email"
						required
						autocomplete="email"
						bind:value={email}
						class="pill-input"
						placeholder="you@example.com"
					/>
				</div>

				{#if mode !== 'reset'}
					<div>
						<label for="password" class="block text-sm font-medium text-[var(--text-muted)] mb-1">{t('auth.password')}</label>
						<input
							id="password"
							type="password"
							required
							autocomplete={mode === 'signup' ? 'new-password' : 'current-password'}
							bind:value={password}
							minlength={8}
							class="pill-input"
							placeholder="••••••••"
						/>
					</div>
				{/if}

				{#if mode === 'signup'}
					<div>
						<label for="confirm-password" class="block text-sm font-medium text-[var(--text-muted)] mb-1">{t('auth.confirm_password')}</label>
						<input
							id="confirm-password"
							type="password"
							required
							autocomplete="new-password"
							bind:value={confirmPassword}
							minlength={8}
							class="pill-input"
							placeholder="••••••••"
						/>
					</div>

					<!-- Merge local data checkbox -->
					<label class="flex items-start gap-2 text-sm text-[var(--text-muted)] cursor-pointer">
						<input type="checkbox" bind:checked={mergeLocal} class="mt-0.5 accent-[var(--primary)]" />
						<span>{t('auth.merge_local_data')}</span>
					</label>
				{/if}

				{#if mode === 'login'}
					<label class="flex items-start gap-2 text-sm text-[var(--text-muted)] cursor-pointer">
						<input type="checkbox" bind:checked={mergeLocal} class="mt-0.5 accent-[var(--primary)]" />
						<span>{t('auth.merge_local_data')}</span>
					</label>
				{/if}

				{#if errorMsg}
					<div class="status-danger text-sm">
						{errorMsg}
					</div>
				{/if}

				<button
					type="submit"
					disabled={loading}
					class="w-full pill-btn transition-all text-white {loading
						? 'bg-[var(--primary)]/50 cursor-wait'
						: 'pill-btn-primary active:scale-[0.98]'}"
				>
					{#if loading}
						{t('auth.loading')}...
					{:else if mode === 'login'}
						{t('auth.login_button')}
					{:else if mode === 'signup'}
						{t('auth.signup_button')}
					{:else}
						{t('auth.reset_button')}
					{/if}
				</button>
			</form>

			<!-- Mode switching -->
			<div class="text-center text-sm space-y-2">
				{#if mode === 'login'}
					<button onclick={() => mode = 'reset'} class="text-[var(--primary)] hover:underline">
						{t('auth.forgot_password')}
					</button>
					<p class="text-[var(--text-muted)]">
						{t('auth.no_account')} <button onclick={() => mode = 'signup'} class="text-[var(--primary)] hover:underline">{t('auth.signup_link')}</button>
					</p>
				{:else if mode === 'signup'}
					<p class="text-[var(--text-muted)]">
						{t('auth.has_account')} <button onclick={() => mode = 'login'} class="text-[var(--primary)] hover:underline">{t('auth.login_link')}</button>
					</p>
				{:else}
					<button onclick={() => mode = 'login'} class="text-[var(--primary)] hover:underline">
						{t('auth.back_to_login')}
					</button>
				{/if}
			</div>

			<!-- Legal notice -->
			<p class="text-xs text-center text-[var(--text-dim)]">
				{@html t('auth.legal_notice')}
			</p>
		</div>

		<!-- Continue without account hint -->
		<div class="text-center mt-6">
			<a href="/train" class="text-sm text-[var(--text-muted)] hover:text-[var(--text)] transition-colors">
				{t('auth.continue_without_account')} →
			</a>
		</div>
	</div>
</main>
