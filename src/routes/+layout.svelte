<script lang="ts">
	import '../app.css';
	import { page } from '$app/state';

	let { children } = $props();
	const isTrainPage = $derived(page.url.pathname.startsWith('/train'));
</script>

<div class="min-h-dvh flex flex-col">
	<!-- Navigation -->
	<nav class="sticky top-0 z-10 px-4 sm:px-6 py-3 flex items-center justify-between border-b border-[var(--wood-dark)]/60 bg-[var(--bg)]/75 backdrop-blur-md">
		<a href="/" class="flex items-center gap-2 group">
			<img src="/jazzchords-logo.png" alt="Chord Trainer" class="h-8 w-8 object-contain" />
			<span class="font-bold text-lg text-gradient">jazzchords.app</span>
		</a>

		<div class="flex items-center gap-1 text-sm">
			<a
				href="/train"
				class="px-3 py-1.5 rounded-sm transition-colors {page.url.pathname.startsWith('/train') ? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium' : 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
			>
				Train
			</a>
			<a
				href="/for-educators"
				class="hidden sm:inline-block px-3 py-1.5 rounded-sm transition-colors {page.url.pathname === '/for-educators' ? 'bg-[var(--primary-muted)] text-[var(--primary)] font-medium' : 'text-[var(--text-muted)] hover:text-[var(--text)]'}"
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
		<footer class="px-4 sm:px-6 py-8 border-t border-[var(--wood-dark)]/40">
			<div class="max-w-5xl mx-auto space-y-6">
				<!-- Logo + Brand -->
				<div class="flex items-center gap-3">
					<img src="/jazzchords-logo.png" alt="Chord Trainer" class="h-12 w-12 object-contain" />
					<div>
						<p class="font-bold text-[var(--text)]">Chord Trainer</p>
						<p class="text-xs text-[var(--text-dim)]">Jazz Piano Speed Training</p>
					</div>
				</div>

				<!-- Links -->
				<div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 text-xs text-[var(--text-dim)]">
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
