<script lang="ts">
	import { t, translations } from '$lib/i18n';
	import { onMount } from 'svelte';

	/**
	 * A translated string containing markup, on a prerendered page.
	 *
	 * `{@html t('…')}` looks equivalent but leaves non-English readers with
	 * English text on any route with `prerender = true`. The markup is built
	 * where localStorage does not exist, so the locale falls back to English.
	 * During hydration Svelte replaces plain text nodes — which is why the
	 * headings on those pages corrected themselves — but it ADOPTS the existing
	 * DOM for an {@html} block instead of re-rendering it, so English paragraphs
	 * survived under German headings.
	 *
	 * Rendering the build-time (English) value first and switching after mount
	 * makes the correction a real state change, which is what forces {@html} to
	 * re-render — and it keeps the first client render matching the server, so
	 * hydration stays clean.
	 */
	interface Props {
		/** i18n key, e.g. 'privacy.intro'. */
		key: string;
		/** Interpolation params, passed straight through to t(). */
		params?: Record<string, string | number>;
		/** Element to render as — matches whatever the surrounding markup needs. */
		as?: 'p' | 'div' | 'span' | 'li';
		class?: string;
	}

	let { key, params, as = 'p', class: extraClass = '' }: Props = $props();

	/** Resolve a dotted key against a specific locale object. */
	function fromEn(k: string, p?: Record<string, string | number>): string {
		let cur: unknown = translations.en;
		for (const part of k.split('.')) {
			if (cur && typeof cur === 'object' && part in cur) cur = (cur as Record<string, unknown>)[part];
			else return k;
		}
		let text = typeof cur === 'string' ? cur : k;
		if (p) for (const [n, v] of Object.entries(p)) text = text.replaceAll(`{${n}}`, String(v));
		return text;
	}

	let mounted = $state(false);
	onMount(() => {
		mounted = true;
	});

	// English until mounted (matching the prerendered markup), then the real
	// locale. setLocale() reloads the page, so nothing else can change it here.
	const html = $derived(mounted ? t(key, params) : fromEn(key, params));
</script>

{#if as === 'p'}
	<p class={extraClass}>{@html html}</p>
{:else if as === 'div'}
	<div class={extraClass}>{@html html}</div>
{:else if as === 'li'}
	<li class={extraClass}>{@html html}</li>
{:else}
	<span class={extraClass}>{@html html}</span>
{/if}
