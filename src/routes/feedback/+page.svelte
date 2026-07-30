<script lang="ts">
	// Feedback — the direct line.
	//
	// Referenced from mail the owner sends to subscribers, so the failure mode
	// that matters is a stranger arriving cold, on a phone, and bouncing. The
	// page is therefore one column, one form, and nothing else: no nav bait,
	// no marketing, no second call to action competing with the send button.
	//
	// The message goes to POST /api/feedback, which writes a row to the
	// `feedback` table under the service role. Nothing is emailed — there are
	// no mail credentials in this project — so the owner reads it in Supabase.

	import { t, getLocale } from '$lib/i18n';
	import { Send, Check } from 'lucide-svelte';

	type Phase = 'writing' | 'sending' | 'sent';

	let phase = $state<Phase>('writing');
	let message = $state('');
	let email = $state('');
	let errorKey = $state('');

	// Mirrors the server's rule so a typo is caught before a round-trip; the
	// endpoint re-checks regardless, since this one is only a convenience.
	const emailLooksValid = $derived(email.trim() === '' || /^\S+@\S+\.\S+$/.test(email.trim()));

	const canSend = $derived(message.trim().length > 0 && emailLooksValid && phase !== 'sending');

	async function submit(event: SubmitEvent) {
		event.preventDefault();
		if (phase === 'sending') return;

		errorKey = '';
		if (!message.trim()) {
			errorKey = 'feedback.error_empty';
			return;
		}
		if (!emailLooksValid) {
			errorKey = 'feedback.error_email';
			return;
		}

		phase = 'sending';
		try {
			const res = await fetch('/api/feedback', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					message: message.trim(),
					email: email.trim(),
					locale: getLocale(),
				}),
			});
			if (!res.ok) {
				// 429 is the one failure a sender can actually act on, so it gets
				// its own line rather than the generic apology.
				errorKey = res.status === 429 ? 'feedback.error_rate' : 'feedback.error_generic';
				phase = 'writing';
				return;
			}
			message = '';
			email = '';
			phase = 'sent';
		} catch {
			errorKey = 'feedback.error_generic';
			phase = 'writing';
		}
	}

	function writeAnother() {
		phase = 'writing';
		errorKey = '';
	}
</script>

<svelte:head>
	<title>{t('feedback.title')} — jazzchords.app</title>
	<meta name="description" content={t('feedback.lede')} />
</svelte:head>

<div class="edi shell">
	{#if phase === 'sent'}
		<!-- The confirmation carries the promise: a person, not a queue. -->
		<div class="done">
			<span class="done-mark" aria-hidden="true"><Check size={18} /></span>
			<h1 class="h1 done-h">{t('feedback.sent_title')}</h1>
			<p class="lede">{t('feedback.sent_body')}</p>
			<button type="button" onclick={writeAnother} class="btn btn-ghost again">
				{t('feedback.sent_again')}
			</button>
		</div>
	{:else}
		<header class="head">
			<p class="eyebrow">{t('feedback.eyebrow')}</p>
			<h1 class="h1">{t('feedback.heading')}</h1>
			<p class="lede">{t('feedback.lede')}</p>
		</header>

		<form onsubmit={submit} novalidate>
			<div class="field">
				<label for="fb-message" class="lbl">{t('feedback.message_label')}</label>
				<textarea
					id="fb-message"
					bind:value={message}
					placeholder={t('feedback.message_placeholder')}
					rows="7"
					maxlength="4000"
					required
					aria-describedby="fb-message-hint"
					class="ctl area"
				></textarea>
				<p id="fb-message-hint" class="hint">{t('feedback.message_hint')}</p>
			</div>

			<div class="field">
				<label for="fb-email" class="lbl">
					{t('feedback.email_label')}
					<span class="opt">{t('feedback.email_optional')}</span>
				</label>
				<input
					id="fb-email"
					type="email"
					bind:value={email}
					placeholder={t('feedback.email_placeholder')}
					maxlength="320"
					autocomplete="email"
					aria-describedby="fb-email-hint"
					class="ctl"
				/>
				<p id="fb-email-hint" class="hint">{t('feedback.email_hint')}</p>
			</div>

			<!-- aria-live so a screen reader hears the failure without the focus
			     being yanked out of the field the sender is still in. -->
			<p class="err" role="alert" aria-live="polite">
				{#if errorKey}{t(errorKey)}{/if}
			</p>

			<button type="submit" disabled={!canSend} class="btn btn-stamp send">
				<Send size={17} aria-hidden="true" />
				{phase === 'sending' ? t('feedback.sending') : t('feedback.submit')}
			</button>
		</form>
	{/if}
</div>

<style>
	/* Same editorial plate as /togo and the legal pages: hairlines and printed
	   labels rather than translucent cards. A form, though, is a working
	   surface — the controls stay the loudest thing here, and no rule competes
	   with the send button. */

	.edi {
		--rule-soft: color-mix(in srgb, var(--border) 62%, transparent);
		--font-display-mus: 'AccidentalFit', var(--font-display);
		font-family: var(--font-sans);
	}

	.shell {
		width: 100%;
		max-width: 36rem;
		margin: 0 auto;
		padding: 1.75rem 1.25rem 6rem;
	}
	@media (min-width: 700px) {
		.shell { padding: 2.75rem 2rem 6rem; }
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

	.head { margin-bottom: 2rem; }

	.h1 {
		margin: 0.85rem 0 0;
		font-family: var(--font-display-mus);
		font-size: clamp(1.9rem, 6vw, 2.5rem);
		font-weight: 600;
		line-height: 1.12;
		letter-spacing: -0.022em;
		text-wrap: balance;
		color: var(--text);
	}

	/* 60ch, a hair tighter than the legal pages' 66ch: this is two sentences of
	   framing, not a document to be read at length. */
	.lede {
		margin: 0.9rem 0 0;
		max-width: 60ch;
		font-size: 1rem;
		line-height: 1.65;
		color: var(--text-muted);
	}

	/* ── The form ─────────────────────────────────────────────── */

	.field {
		margin-bottom: 1.5rem;
		padding-top: 1.25rem;
		border-top: 1px solid var(--rule-soft);
	}

	/* A real <label>, printed as a small-caps mono plate. */
	.lbl {
		display: flex;
		align-items: baseline;
		gap: 0.5rem;
		margin-bottom: 0.55rem;
		font-family: var(--font-mono);
		font-size: 0.63rem;
		font-weight: 700;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--text);
	}
	.opt {
		font-weight: 500;
		letter-spacing: 0.12em;
		color: var(--text-dim);
	}

	/* Squared inputs with a real rule — the rounded translucent pill is exactly
	   what the rest of the app moved away from. --border-hover rather than
	   --border: an input's edge IS its shape, and the hairline token is tuned
	   for rules BETWEEN things, not around them. */
	.ctl {
		display: block;
		width: 100%;
		padding: 0.7rem 0.85rem;
		border: 1px solid var(--border-hover);
		border-radius: var(--radius-sm);
		background: var(--bg-card);
		color: var(--text);
		font-family: inherit;
		font-size: 1rem;
		line-height: 1.55;
		transition: border-color 0.12s, box-shadow 0.12s;
	}
	.ctl::placeholder { color: var(--text-dim); }
	.ctl:hover { border-color: var(--text-dim); }
	/* Visible focus is load-bearing here — a stranger may be on a keyboard. */
	.ctl:focus {
		outline: none;
		border-color: var(--primary);
		box-shadow: 0 0 0 3px var(--primary-muted);
	}
	.ctl:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: 1px;
	}
	.area {
		resize: vertical;
		min-height: 9rem;
	}

	.hint {
		margin: 0.5rem 0 0;
		font-size: 0.84rem;
		line-height: 1.5;
		color: var(--text-dim);
	}

	/* Reserves no space when empty, so the button does not jump on error. */
	.err:not(:empty) {
		margin: 0 0 1rem;
		padding-left: 0.8rem;
		border-left: 2px solid var(--danger);
		font-size: 0.9rem;
		line-height: 1.5;
		color: var(--danger);
	}
	.err:empty { margin: 0; }

	/* ── Buttons ──────────────────────────────────────────────── */

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
	/* On diazo paper the amber fill separates from the ground at only 1.75:1,
	   so the button's shape needs an ink edge. Dark ground needs none. */
	:global([data-theme='light']) .btn-stamp {
		border-color: var(--stamp-ink);
	}
	.btn:disabled {
		opacity: 0.45;
		cursor: not-allowed;
	}

	.send {
		width: 100%;
		min-height: 3.1rem;
		font-size: 1rem;
	}

	.btn-ghost {
		background: transparent;
		border-color: transparent;
		color: var(--text-muted);
		font-weight: 500;
		padding: 0 0.85rem;
		text-underline-offset: 4px;
		text-decoration: underline;
		text-decoration-color: var(--border-hover);
		text-decoration-thickness: 1px;
	}
	.btn-ghost:hover {
		color: var(--text);
		text-decoration-color: var(--accent-amber);
		background: transparent;
	}

	/* ── Confirmation ─────────────────────────────────────────── */

	.done { padding-top: 1.5rem; }
	.done-mark {
		display: inline-grid;
		place-items: center;
		width: 2.1rem;
		height: 2.1rem;
		border: 2px solid var(--accent-green);
		border-radius: 50%;
		color: var(--accent-green);
	}
	.done-h { margin-top: 1rem; }
	.again { margin-top: 1.75rem; }

	@media (prefers-reduced-motion: reduce) {
		.btn { transition: none; }
		.btn:hover:not(:disabled) { transform: none; }
	}
</style>
