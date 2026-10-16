<script lang="ts">
	// "Keep going next week?" — the weekly practice mail opt-in.
	//
	// Asked once per device, right after the first finished session: the one
	// moment someone has just felt it work. Without a reason to come back, a
	// browser tab does not bring anyone back on day seven, and most people who
	// finish a block have no account, so this asks for an address only.
	//
	// The consent wording is shown verbatim next to the button (it is what the
	// server stores), and nothing is subscribed until the Brevo confirmation
	// link is clicked.
	import { t, getLocale } from '$lib/i18n';
	import { Sheet } from '$lib/components/ui';
	import { consentText } from '$lib/consent';
	import { trackCoachEvent } from '$lib/services/telemetry';
	import { getAuthState } from '$lib/services/auth';

	interface Props {
		open: boolean;
		onclose?: () => void;
	}

	let { open = $bindable(), onclose }: Props = $props();

	type Phase = 'asking' | 'sending' | 'sent' | 'already';
	let phase = $state<Phase>('asking');
	let email = $state(getAuthState().user?.email ?? '');
	let website = $state(''); // honeypot, never shown
	let errorKey = $state('');

	const looksValid = $derived(/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email.trim()));

	$effect(() => {
		if (open) trackCoachEvent('mail_optin_shown');
	});

	async function submit(event: SubmitEvent) {
		event.preventDefault();
		if (phase === 'sending') return;
		errorKey = '';
		if (!looksValid) {
			errorKey = 'practice_mail.error_email';
			return;
		}
		phase = 'sending';
		try {
			const res = await fetch('/api/practice-reminder', {
				method: 'POST',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({ email: email.trim(), locale: getLocale(), website }),
			});
			if (!res.ok) throw new Error(String(res.status));
			const body = (await res.json()) as { status: string };
			phase = body.status === 'confirmed' ? 'already' : 'sent';
			trackCoachEvent('mail_optin_submitted', { status: body.status });
		} catch {
			phase = 'asking';
			errorKey = 'practice_mail.error_generic';
		}
	}

	function dismiss() {
		if (phase === 'asking') trackCoachEvent('mail_optin_dismissed');
		open = false;
		onclose?.();
	}
</script>

<Sheet bind:open title={t('practice_mail.title')} onclose={dismiss}>
	{#if phase === 'sent' || phase === 'already'}
		<div class="space-y-3">
			{#if phase === 'sent'}
				<p class="font-semibold">{t('practice_mail.sent_title')}</p>
				<p class="text-[var(--text-muted)] leading-relaxed">{t('practice_mail.sent_desc')}</p>
			{:else}
				<p class="text-[var(--text-muted)] leading-relaxed">{t('practice_mail.already')}</p>
			{/if}
		</div>
	{:else}
		<form id="practice-mail-form" class="space-y-4" onsubmit={submit} novalidate>
			<p class="text-[var(--text-muted)] leading-relaxed">{t('practice_mail.desc')}</p>
			<label class="block space-y-1.5">
				<span class="text-sm text-[var(--text-muted)]">{t('practice_mail.email_label')}</span>
				<input
					type="email"
					autocomplete="email"
					inputmode="email"
					bind:value={email}
					placeholder={t('practice_mail.email_placeholder')}
					class="w-full rounded-xl border border-[var(--border)] bg-[var(--bg-card)] px-3 py-2.5 text-base"
				/>
			</label>
			<!-- Honeypot: off-screen, out of the tab order, ignored by people. -->
			<input
				type="text"
				name="website"
				tabindex="-1"
				autocomplete="off"
				aria-hidden="true"
				bind:value={website}
				class="absolute -left-[9999px] h-px w-px opacity-0"
			/>
			{#if errorKey}
				<p class="text-sm text-[var(--error,#d33)]" role="alert">{t(errorKey)}</p>
			{/if}
			<p class="text-xs text-[var(--text-dim)] leading-relaxed">
				{consentText(getLocale())}
				<a href="/privacy" class="underline">{t('nav.privacy')}</a>
			</p>
		</form>
	{/if}

	{#snippet footer()}
		<div class="space-y-2">
			{#if phase === 'sent' || phase === 'already'}
				<button onclick={dismiss} class="pill-btn pill-btn-primary w-full py-3 text-base">
					{t('practice_mail.close')}
				</button>
			{:else}
				<button
					type="submit"
					form="practice-mail-form"
					disabled={phase === 'sending'}
					class="pill-btn pill-btn-primary w-full py-3 text-base disabled:opacity-60"
				>
					{phase === 'sending' ? t('practice_mail.sending') : t('practice_mail.cta')}
				</button>
				<button
					onclick={dismiss}
					class="w-full py-1.5 text-sm text-[var(--text-dim)] hover:text-[var(--text-muted)] transition-colors"
				>
					{t('practice_mail.later')}
				</button>
			{/if}
		</div>
	{/snippet}
</Sheet>
