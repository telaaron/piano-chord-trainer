<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { Music, Palette } from 'lucide-svelte';
	import { THEMES, loadTheme, saveTheme, applyTheme, type ThemeId } from '$lib/services/theme';

	let { children } = $props();
	const isTrainPage = $derived(page.url.pathname.startsWith('/train'));
	let activeTheme = $state<ThemeId>('default');
	let showThemePicker = $state(false);

	const themeInfo = $derived(THEMES.find((t) => t.id === activeTheme) ?? THEMES[0]);
	const isOpenStudio = $derived(activeTheme === 'openstudio');

	function setTheme(id: ThemeId) {
		activeTheme = id;
		saveTheme(id);
		applyTheme(id);
		showThemePicker = false;
	}

	onMount(() => {
		activeTheme = loadTheme();
		applyTheme(activeTheme);
	});
</script>

<div class="min-h-dvh flex flex-col">
	<!-- Navigation -->
	<nav class="px-4 sm:px-6 py-4 flex items-center justify-between border-b border-[var(--border)]/50">
		<a href="/" class="flex items-center gap-2 group">
			{#if isOpenStudio}
				<div class="w-8 h-8 rounded-[var(--radius-sm)] bg-[var(--primary)] flex items-center justify-center">
					<span class="text-sm font-bold text-[var(--primary-text)]">OS</span>
				</div>
				<span class="font-bold text-lg text-gradient">Open Studio</span>
				<span class="text-xs text-[var(--text-dim)] ml-1 hidden sm:inline">Chord Trainer</span>
			{:else}
				<div class="w-8 h-8 rounded-[var(--radius-sm)] bg-[var(--primary)] flex items-center justify-center">
					<Music size={16} class="text-white" />
				</div>
				<span class="font-bold text-lg text-gradient">Chord Trainer</span>
			{/if}
		</a>

		<div class="flex items-center gap-1 text-sm">
			<a
				href="/train"
				class="px-3 py-1.5 rounded-[var(--radius-sm)] transition-colors {page.url.pathname.startsWith('/train') ? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium' : 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
			>
				Train
			</a>
			<a
				href="/for-educators"
				class="px-3 py-1.5 rounded-[var(--radius-sm)] transition-colors {page.url.pathname === '/for-educators' ? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium' : 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
			>
				For Educators
			</a>

			<!-- Theme switcher -->
			<div class="relative ml-2">
				<button
					class="p-1.5 rounded-[var(--radius-sm)] text-[var(--text-dim)] hover:text-[var(--text)] hover:bg-[var(--bg-muted)] transition-colors"
					onclick={() => showThemePicker = !showThemePicker}
					title="Theme wechseln"
				>
					<Palette size={16} />
				</button>
				{#if showThemePicker}
					<!-- Backdrop -->
					<!-- svelte-ignore a11y_click_events_have_key_events -->
					<!-- svelte-ignore a11y_no_static_element_interactions -->
					<div class="fixed inset-0 z-40" onclick={() => showThemePicker = false}></div>
					<div class="absolute right-0 top-full mt-2 z-50 w-52 rounded-[var(--radius-lg)] bg-[var(--bg-card)] border border-[var(--border)] shadow-xl overflow-hidden">
						{#each THEMES as theme}
							<button
								class="w-full px-4 py-3 text-left text-sm transition-colors flex items-center gap-3
									{theme.id === activeTheme ? 'bg-[var(--primary-muted)] text-[var(--primary)]' : 'text-[var(--text-muted)] hover:bg-[var(--bg-muted)] hover:text-[var(--text)]'}"
								onclick={() => setTheme(theme.id)}
							>
								<div class="w-5 h-5 rounded-full border-2 flex items-center justify-center
									{theme.id === activeTheme ? 'border-[var(--primary)]' : 'border-[var(--border)]'}">
									{#if theme.id === activeTheme}
										<div class="w-2.5 h-2.5 rounded-full bg-[var(--primary)]"></div>
									{/if}
								</div>
								<div>
									<div class="font-medium">{theme.name}</div>
									<div class="text-xs text-[var(--text-dim)]">{theme.description}</div>
								</div>
							</button>
						{/each}
					</div>
				{/if}
			</div>
		</div>
	</nav>

	<!-- Content -->
	<div class="flex-1 flex flex-col">
		{@render children()}
	</div>

	<!-- Footer (hidden on train page for focus) -->
	{#if !isTrainPage}
		<footer class="px-4 sm:px-6 py-6 border-t border-[var(--border)]/50">
			<div class="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-[var(--text-dim)]">
				{#if isOpenStudio}
					<span>&copy; 2026 Open Studio Jazz &middot; Chord Trainer</span>
					<span>Powered by Open Studio</span>
				{:else}
					<span>&copy; 2026 Chord Trainer</span>
					<span>Built for jazz education</span>
				{/if}
			</div>
		</footer>
	{/if}
</div>
