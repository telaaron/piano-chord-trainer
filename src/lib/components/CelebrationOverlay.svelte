<script lang="ts">
	import { t } from '$lib/i18n';
	import type { CelebrationEvent } from '$lib/engine/habits';
	import { playCelebrationSound } from '$lib/services/audio';
	import { fade, scale } from 'svelte/transition';
	import { onMount } from 'svelte';

	interface Props {
		celebrations: CelebrationEvent[];
		ondismiss: () => void;
	}

	let { celebrations, ondismiss }: Props = $props();

	let currentIndex = $state(0);
	let visible = $state(true);
	let confettiPieces: { x: number; y: number; rotation: number; color: string; delay: number; size: number }[] = $state([]);

	const TYPE_CONFIG: Record<string, { emoji: string; bg: string; glow: string }> = {
		'level-up': { emoji: '🎉', bg: 'linear-gradient(135deg, rgba(251,146,60,0.15) 0%, rgba(245,158,11,0.1) 100%)', glow: 'rgba(251,146,60,0.4)' },
		'goal-complete': { emoji: '🎯', bg: 'linear-gradient(135deg, rgba(74,222,128,0.12) 0%, rgba(34,197,94,0.08) 100%)', glow: 'rgba(74,222,128,0.35)' },
		'streak-milestone': { emoji: '🔥', bg: 'linear-gradient(135deg, rgba(239,68,68,0.12) 0%, rgba(251,146,60,0.08) 100%)', glow: 'rgba(239,68,68,0.35)' },
		'personal-best': { emoji: '🏆', bg: 'linear-gradient(135deg, rgba(245,158,11,0.15) 0%, rgba(251,146,60,0.08) 100%)', glow: 'rgba(245,158,11,0.4)' },
		'xp-gain': { emoji: '⚡', bg: 'linear-gradient(135deg, rgba(251,146,60,0.1) 0%, rgba(245,158,11,0.05) 100%)', glow: 'rgba(251,146,60,0.25)' },
	};

	const current = $derived(celebrations[currentIndex]);
	const hasMore = $derived(currentIndex < celebrations.length - 1);
	const currentConfig = $derived(current ? (TYPE_CONFIG[current.type] || TYPE_CONFIG['xp-gain']) : TYPE_CONFIG['xp-gain']);

	onMount(() => {
		// Play celebration sound for the first event
		if (celebrations.length > 0) {
			playCelebrationSound(celebrations[0].type);
		}

		// Generate confetti pieces
		const colors = ['#fb923c', '#f59e0b', '#4ade80', '#a78bfa', '#f472b6', '#38bdf8'];
		confettiPieces = Array.from({ length: 30 }, () => ({
			x: Math.random() * 100,
			y: -10 - Math.random() * 20,
			rotation: Math.random() * 360,
			color: colors[Math.floor(Math.random() * colors.length)],
			delay: Math.random() * 0.5,
			size: 4 + Math.random() * 6,
		}));
	});

	function handleNext() {
		if (hasMore) {
			currentIndex++;
			// Play sound for the next celebration
			playCelebrationSound(celebrations[currentIndex].type);
		} else {
			visible = false;
			setTimeout(ondismiss, 300);
		}
	}

	function handleDismissAll() {
		visible = false;
		setTimeout(ondismiss, 300);
	}
</script>

{#if visible && current}
	<!-- svelte-ignore a11y_click_events_have_key_events -->
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div class="fixed inset-0 z-[1000] flex items-center justify-center bg-black/70 backdrop-blur-[4px] p-5" transition:fade={{ duration: 200 }} onclick={handleDismissAll}>
		<!-- Confetti -->
		{#if current.type === 'level-up' || current.type === 'streak-milestone'}
			<div class="absolute inset-0 overflow-hidden pointer-events-none">
				{#each confettiPieces as piece}
					<div
						class="confetti absolute rounded-[2px]"
						style="
							left: {piece.x}%;
							background: {piece.color};
							width: {piece.size}px;
							height: {piece.size * 1.5}px;
							animation-delay: {piece.delay}s;
							transform: rotate({piece.rotation}deg);
						"
					></div>
				{/each}
			</div>
		{/if}

		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div
			class="border border-white/10 rounded-2xl py-8 px-7 text-center max-w-[340px] w-full"
			transition:scale={{ duration: 300, start: 0.8 }}
			style="background: {currentConfig.bg}; box-shadow: 0 0 40px {currentConfig.glow};"
			onclick={(e) => e.stopPropagation()}
		>
			<div class="celebration-emoji text-5xl mb-3">{currentConfig.emoji}</div>
			<h2 class="text-xl font-extrabold text-[var(--text,#fff)] m-0 mb-1.5">
				{t(current.titleKey, current.titleParams) || current.title}
			</h2>
			{#if current.subtitle}
				<p class="text-[0.85rem] text-[var(--text-muted,#888)] m-0 mb-4">
					{t(current.subtitleKey || '', current.subtitleParams) || current.subtitle}
				</p>
			{/if}

			{#if current.xpGained > 0}
				<div class="xp-toast inline-block py-1 px-3.5 rounded-full bg-orange-400/15 text-orange-400 text-[0.8rem] font-bold mb-5">+{current.xpGained} XP</div>
			{/if}

			<button class="block w-full py-2.5 px-5 border-none rounded-[var(--radius,8px)] bg-[#fb923c] text-black text-[0.85rem] font-bold cursor-pointer transition-all duration-200 hover:bg-[#f59e0b] hover:-translate-y-px" onclick={handleNext}>
				{hasMore ? t('habit.celebration_next') || 'Next' : t('habit.celebration_continue') || 'Continue'}
			</button>

			{#if celebrations.length > 1}
				<div class="flex justify-center gap-1.5 mt-3.5">
					{#each celebrations as _, i}
						<div class="w-1.5 h-1.5 rounded-full transition-all duration-200 {i === currentIndex ? 'bg-[#fb923c] scale-[1.3]' : i < currentIndex ? 'bg-[rgba(251,146,60,0.4)]' : 'bg-white/15'}"></div>
					{/each}
				</div>
			{/if}
		</div>
	</div>
{/if}

<style>
	.confetti {
		animation: confetti-fall 2.5s ease-in forwards;
	}

	@keyframes confetti-fall {
		0% {
			transform: translateY(0) rotate(0deg);
			opacity: 1;
		}
		100% {
			transform: translateY(100vh) rotate(720deg);
			opacity: 0;
		}
	}

	.celebration-emoji {
		animation: bounce 0.6s ease-out;
	}

	@keyframes bounce {
		0%, 100% { transform: translateY(0); }
		40% { transform: translateY(-12px); }
		60% { transform: translateY(-6px); }
	}

	.xp-toast {
		animation: xp-pop 0.4s ease-out;
	}

	@keyframes xp-pop {
		0% { transform: scale(0.5); opacity: 0; }
		70% { transform: scale(1.1); }
		100% { transform: scale(1); opacity: 1; }
	}
</style>
