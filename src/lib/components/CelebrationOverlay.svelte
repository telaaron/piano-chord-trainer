<script lang="ts">
	import { t } from '$lib/i18n';
	import type { CelebrationEvent } from '$lib/engine/habits';
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
	<div class="celebration-overlay" transition:fade={{ duration: 200 }} onclick={handleDismissAll}>
		<!-- Confetti -->
		{#if current.type === 'level-up' || current.type === 'streak-milestone'}
			<div class="confetti-container">
				{#each confettiPieces as piece}
					<div
						class="confetti"
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
			class="celebration-card"
			transition:scale={{ duration: 300, start: 0.8 }}
			style="background: {currentConfig.bg}; box-shadow: 0 0 40px {currentConfig.glow};"
			onclick={(e) => e.stopPropagation()}
		>
			<div class="celebration-emoji">{currentConfig.emoji}</div>
			<h2 class="celebration-title">
				{t(current.titleKey, current.titleParams) || current.title}
			</h2>
			{#if current.subtitle}
				<p class="celebration-subtitle">
					{t(current.subtitleKey || '', current.subtitleParams) || current.subtitle}
				</p>
			{/if}

			{#if current.xpGained > 0}
				<div class="xp-toast">+{current.xpGained} XP</div>
			{/if}

			<button class="celebration-btn" onclick={handleNext}>
				{hasMore ? t('habit.celebration_next') || 'Next' : t('habit.celebration_continue') || 'Continue'}
			</button>

			{#if celebrations.length > 1}
				<div class="celebration-dots">
					{#each celebrations as _, i}
						<div class="dot" class:active={i === currentIndex} class:done={i < currentIndex}></div>
					{/each}
				</div>
			{/if}
		</div>
	</div>
{/if}

<style>
	.celebration-overlay {
		position: fixed;
		inset: 0;
		z-index: 1000;
		display: flex;
		align-items: center;
		justify-content: center;
		background: rgba(0, 0, 0, 0.7);
		backdrop-filter: blur(4px);
		padding: 20px;
	}

	.confetti-container {
		position: absolute;
		inset: 0;
		overflow: hidden;
		pointer-events: none;
	}

	.confetti {
		position: absolute;
		border-radius: 2px;
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

	.celebration-card {
		border: 1px solid rgba(255, 255, 255, 0.1);
		border-radius: 16px;
		padding: 32px 28px;
		text-align: center;
		max-width: 340px;
		width: 100%;
	}

	.celebration-emoji {
		font-size: 3rem;
		margin-bottom: 12px;
		animation: bounce 0.6s ease-out;
	}

	@keyframes bounce {
		0%, 100% { transform: translateY(0); }
		40% { transform: translateY(-12px); }
		60% { transform: translateY(-6px); }
	}

	.celebration-title {
		font-size: 1.25rem;
		font-weight: 800;
		color: var(--text, #fff);
		margin: 0 0 6px;
	}

	.celebration-subtitle {
		font-size: 0.85rem;
		color: var(--text-muted, #888);
		margin: 0 0 16px;
	}

	.xp-toast {
		display: inline-block;
		padding: 4px 14px;
		border-radius: 999px;
		background: rgba(251, 146, 60, 0.15);
		color: #fb923c;
		font-size: 0.8rem;
		font-weight: 700;
		margin-bottom: 20px;
		animation: xp-pop 0.4s ease-out;
	}

	@keyframes xp-pop {
		0% { transform: scale(0.5); opacity: 0; }
		70% { transform: scale(1.1); }
		100% { transform: scale(1); opacity: 1; }
	}

	.celebration-btn {
		display: block;
		width: 100%;
		padding: 10px 20px;
		border: none;
		border-radius: var(--radius, 8px);
		background: #fb923c;
		color: #000;
		font-size: 0.85rem;
		font-weight: 700;
		cursor: pointer;
		transition: all 0.2s;
	}

	.celebration-btn:hover {
		background: #f59e0b;
		transform: translateY(-1px);
	}

	.celebration-dots {
		display: flex;
		justify-content: center;
		gap: 6px;
		margin-top: 14px;
	}

	.dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: rgba(255, 255, 255, 0.15);
		transition: all 0.2s;
	}

	.dot.active {
		background: #fb923c;
		transform: scale(1.3);
	}

	.dot.done {
		background: rgba(251, 146, 60, 0.4);
	}
</style>
