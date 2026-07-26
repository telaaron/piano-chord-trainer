<script lang="ts">
	import { t } from '$lib/i18n';
	import { signIn, signUp, resetPassword } from '$lib/services/auth';
	import { uploadLocalDataToCloud } from '$lib/services/cloud-sync';
	import { toastSuccess, toastError } from '$lib/services/toast';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { Cloud } from 'lucide-svelte';

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

<main class="auth">
	<div class="auth-col">
		<div class="auth-sheet">
			<!-- Header — a title block, not a centred hero -->
			<header class="auth-head">
				<p class="plate">{t('nav_auth.login')}</p>
				<h1>
					{#if mode === 'login'}{t('auth.login_heading')}{:else if mode === 'signup'}{t('auth.signup_heading')}{:else}{t('auth.reset_heading')}{/if}
				</h1>
				<p class="auth-sub">
					{#if mode === 'login'}{t('auth.login_subheading')}{:else if mode === 'signup'}{t('auth.signup_subheading')}{:else}{t('auth.reset_subheading')}{/if}
				</p>
			</header>

			<!-- Sync hint — a marginal note in copyist blue -->
			{#if mode === 'signup' || mode === 'login'}
				<div class="marginalia">
					<Cloud size={16} class="shrink-0" aria-hidden="true" />
					<p>{t('auth.sync_hint')}</p>
				</div>
			{/if}

			<!-- Form -->
			<form onsubmit={handleSubmit} class="space-y-4">
				<div>
					<label for="email" class="field-label">{t('auth.email')}</label>
					<input
						id="email"
						type="email"
						required
						autocomplete="email"
						bind:value={email}
						class="field"
						placeholder="you@example.com"
					/>
				</div>

				{#if mode !== 'reset'}
					<div>
						<label for="password" class="field-label">{t('auth.password')}</label>
						<input
							id="password"
							type="password"
							required
							autocomplete={mode === 'signup' ? 'new-password' : 'current-password'}
							bind:value={password}
							minlength={8}
							class="field"
							placeholder="••••••••"
						/>
					</div>
				{/if}

				{#if mode === 'signup'}
					<div>
						<label for="confirm-password" class="field-label">{t('auth.confirm_password')}</label>
						<input
							id="confirm-password"
							type="password"
							required
							autocomplete="new-password"
							bind:value={confirmPassword}
							minlength={8}
							class="field"
							placeholder="••••••••"
						/>
					</div>

					<!-- Merge local data checkbox -->
					<label class="check">
						<input type="checkbox" bind:checked={mergeLocal} />
						<span>{t('auth.merge_local_data')}</span>
					</label>
				{/if}

				{#if mode === 'login'}
					<label class="check">
						<input type="checkbox" bind:checked={mergeLocal} />
						<span>{t('auth.merge_local_data')}</span>
					</label>
				{/if}

				{#if errorMsg}
					<div class="auth-error" role="alert">
						{errorMsg}
					</div>
				{/if}

				<button type="submit" disabled={loading} class="auth-submit" class:is-loading={loading}>
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
			<div class="auth-switch">
				{#if mode === 'login'}
					<button onclick={() => mode = 'reset'} class="link">
						{t('auth.forgot_password')}
					</button>
					<p>
						{t('auth.no_account')} <button onclick={() => mode = 'signup'} class="link">{t('auth.signup_link')}</button>
					</p>
				{:else if mode === 'signup'}
					<p>
						{t('auth.has_account')} <button onclick={() => mode = 'login'} class="link">{t('auth.login_link')}</button>
					</p>
				{:else}
					<button onclick={() => mode = 'login'} class="link">
						{t('auth.back_to_login')}
					</button>
				{/if}
			</div>

			<!-- Legal notice — set as the fine print at the foot of the form -->
			<p class="auth-legal">
				{@html t('auth.legal_notice')}
			</p>
		</div>

		<!-- Continue without account -->
		<p class="auth-escape">
			<a href="/train">{t('auth.continue_without_account')} →</a>
		</p>
	</div>
</main>

<style>
	.auth {
		flex: 1;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: clamp(2.5rem, 8vw, 5rem) clamp(1rem, 5vw, 2rem);
	}
	.auth-col {
		width: 100%;
		max-width: 26rem;
	}
	/* A form printed on the stock: one hairline frame, square corners. */
	.auth-sheet {
		border: 1px solid var(--border);
		background: var(--bg-card);
		padding: clamp(1.5rem, 5vw, 2.25rem);
		display: flex;
		flex-direction: column;
		gap: 1.5rem;
	}

	.auth-head {
		padding-bottom: 1.1rem;
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
	.auth-head h1 {
		font-family: var(--font-display);
		font-size: 1.85rem;
		font-weight: 600;
		line-height: 1.12;
		letter-spacing: -0.025em;
		color: var(--text);
		margin: 0;
	}
	.auth-sub {
		margin-top: 0.5rem;
		font-size: 0.88rem;
		line-height: 1.5;
		color: var(--text-muted);
	}

	/* The copyist's marginal note: a blue rule, no box */
	.marginalia {
		display: flex;
		align-items: flex-start;
		gap: 0.7rem;
		border-left: 2px solid var(--ink-blue);
		padding-left: 0.85rem;
		font-size: 0.85rem;
		line-height: 1.5;
		color: var(--text-muted);
	}
	.marginalia :global(svg) {
		color: var(--ink-blue);
		margin-top: 0.15rem;
	}

	/* ── Fields: ruled, not pilled. The underline is the input. ── */
	.field-label {
		display: block;
		font-family: var(--font-mono);
		font-size: 0.6rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--text-dim);
		margin-bottom: 0.45rem;
	}
	.field {
		width: 100%;
		min-height: var(--tap-min);
		padding: 0.6rem 0.75rem;
		border-radius: 2px;
		background: var(--bg);
		border: 1px solid var(--border);
		color: var(--text);
		font-size: 0.95rem;
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

	.check {
		display: flex;
		align-items: flex-start;
		gap: 0.55rem;
		font-size: 0.85rem;
		line-height: 1.45;
		color: var(--text-muted);
		cursor: pointer;
	}
	.check input {
		margin-top: 0.15rem;
		accent-color: var(--primary);
		flex: none;
	}

	.auth-error {
		border-left: 2px solid var(--danger);
		background: var(--danger-muted);
		padding: 0.65rem 0.85rem;
		font-size: 0.85rem;
		color: var(--danger);
	}

	/* One flat pull of stamp ink */
	.auth-submit {
		width: 100%;
		min-height: var(--tap-min);
		border-radius: 2px;
		border: 1px solid var(--primary);
		background: var(--primary);
		color: var(--primary-text);
		font-size: 0.95rem;
		font-weight: 600;
		cursor: pointer;
		transition: background 0.15s ease, border-color 0.15s ease;
	}
	.auth-submit:hover:not(.is-loading) {
		background: var(--primary-hover);
		border-color: var(--primary-hover);
	}
	.auth-submit.is-loading {
		opacity: 0.55;
		cursor: wait;
	}

	.auth-switch {
		display: flex;
		flex-direction: column;
		gap: 0.45rem;
		padding-top: 1.25rem;
		border-top: 1px solid var(--border);
		font-size: 0.85rem;
		color: var(--text-muted);
	}
	.link {
		background: none;
		border: none;
		padding: 0;
		cursor: pointer;
		color: var(--text);
		font-size: inherit;
		text-decoration: underline;
		text-decoration-color: var(--primary);
		text-underline-offset: 3px;
		transition: color 0.15s ease;
		align-self: flex-start;
	}
	.link:hover {
		color: var(--primary);
	}

	.auth-legal {
		font-size: 0.7rem;
		line-height: 1.5;
		color: var(--text-dim);
	}
	.auth-legal :global(a) {
		color: var(--text-muted);
		text-decoration: underline;
		text-underline-offset: 2px;
	}
	.auth-legal :global(a:hover) {
		color: var(--primary);
	}

	.auth-escape {
		margin-top: 1.25rem;
		text-align: center;
		font-size: 0.85rem;
	}
	.auth-escape a {
		color: var(--text-dim);
		text-decoration: none;
		transition: color 0.15s ease;
	}
	.auth-escape a:hover {
		color: var(--text);
	}
</style>
