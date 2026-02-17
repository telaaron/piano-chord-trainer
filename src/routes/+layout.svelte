<script lang="ts">
	import '../app.css';
	import { page } from '$app/state';
	import { Music } from 'lucide-svelte';

	let { children } = $props();
	const isTrainPage = $derived(page.url.pathname.startsWith('/train'));
</script>

<div class="min-h-dvh flex flex-col">
	<!-- Navigation -->
	<nav class="px-4 sm:px-6 py-4 flex items-center justify-between border-b border-[var(--border)]/50">
		<a href="/" class="flex items-center gap-2 group">
			<Music size={28} class="text-[var(--accent-gold)]" />
			<span class="font-bold text-lg text-gradient">Chord Trainer</span>
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
		</div>
	</nav>

	<!-- Content -->
	<div class="flex-1 flex flex-col">
		{@render children()}
	</div>

	<!-- Footer (hidden on train page for focus) -->
	{#if !isTrainPage}
		<footer class="px-4 sm:px-6 py-6 border-t border-[var(--border)]/50">
			<div class="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-[var(--text-dim)]">
				<span>&copy; 2026 Aaron Technologies OÜ</span>
				<div class="flex items-center gap-4">
					<a href="/about" class="hover:text-[var(--text-muted)] transition-colors">About</a>
					<a href="/privacy" class="hover:text-[var(--text-muted)] transition-colors">Privacy</a>
					<a href="/impressum" class="hover:text-[var(--text-muted)] transition-colors">Impressum</a>
					<a href="mailto:info@jazzchords.app" class="hover:text-[var(--text-muted)] transition-colors">Contact</a>
				</div>
				<span>Built for jazz education</span>
			</div>
		</footer>
	{/if}
</div>
