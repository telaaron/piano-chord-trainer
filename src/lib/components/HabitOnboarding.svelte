<script lang="ts">
	import { t } from '$lib/i18n';
	import { fade, fly } from 'svelte/transition';
	import type { HabitProfile, TimeOfDay } from '$lib/engine/habits';
	import { requestNotificationPermission } from '$lib/services/habits';

	interface Props {
		oncomplete: (config: {
			dailyGoalMinutes: number;
			preferredTime: TimeOfDay;
			notificationsEnabled: boolean;
			notificationTime: string;
		}) => void;
	}

	let { oncomplete }: Props = $props();

	let step = $state(1);
	let dailyGoalMinutes = $state(5);
	let preferredTime: TimeOfDay = $state('evening');
	let enableNotifications = $state(false);
	let notificationTime = $state('20:00');

	const MINUTE_OPTIONS = [
		{ value: 2, label: '2 min', desc: t('habit.onboard_2min') || 'Just a taste' },
		{ value: 5, label: '5 min', desc: t('habit.onboard_5min') || 'Quick session' },
		{ value: 10, label: '10 min', desc: t('habit.onboard_10min') || 'Solid practice' },
		{ value: 15, label: '15 min', desc: t('habit.onboard_15min') || 'Deep work' },
	];

	const TIME_OPTIONS: { value: TimeOfDay; label: string; icon: string }[] = [
		{ value: 'morning', label: t('settings.greeting_morning') || 'Morning', icon: '☀️' },
		{ value: 'afternoon', label: t('settings.greeting_afternoon') || 'Afternoon', icon: '🌤️' },
		{ value: 'evening', label: t('settings.greeting_evening') || 'Evening', icon: '🌙' },
	];

	async function handleNotificationChoice(enable: boolean) {
		enableNotifications = enable;
		if (enable) {
			const granted = await requestNotificationPermission();
			enableNotifications = granted;
		}
		step = 4;
	}

	function handleFinish() {
		oncomplete({
			dailyGoalMinutes,
			preferredTime,
			notificationsEnabled: enableNotifications,
			notificationTime,
		});
	}
</script>

<div class="onboarding-overlay" transition:fade={{ duration: 200 }}>
	<div class="onboarding-card" in:fly={{ y: 30, duration: 300 }}>
		<!-- Progress dots -->
		<div class="step-dots">
			{#each [1, 2, 3, 4] as s}
				<div class="step-dot" class:active={s === step} class:done={s < step}></div>
			{/each}
		</div>

		{#if step === 1}
			<div class="step-content" in:fade={{ duration: 200 }}>
				<h2 class="step-title">{t('habit.onboard_time_title') || 'How much time do you have daily?'}</h2>
				<p class="step-desc">{t('habit.onboard_time_desc') || 'Start small — you can always do more.'}</p>
				<div class="option-grid">
					{#each MINUTE_OPTIONS as opt}
						<button
							class="option-btn"
							class:selected={dailyGoalMinutes === opt.value}
							onclick={() => { dailyGoalMinutes = opt.value; step = 2; }}
						>
							<span class="option-main">{opt.label}</span>
							<span class="option-sub">{opt.desc}</span>
						</button>
					{/each}
				</div>
			</div>
		{:else if step === 2}
			<div class="step-content" in:fade={{ duration: 200 }}>
				<h2 class="step-title">{t('habit.onboard_when_title') || 'When do you like to practice?'}</h2>
				<p class="step-desc">{t('habit.onboard_when_desc') || 'Helps us time your reminders right.'}</p>
				<div class="option-row">
					{#each TIME_OPTIONS as opt}
						<button
							class="option-btn time-btn"
							class:selected={preferredTime === opt.value}
							onclick={() => { preferredTime = opt.value; step = 3; }}
						>
							<span class="time-icon">{opt.icon}</span>
							<span class="option-main">{opt.label}</span>
						</button>
					{/each}
				</div>
			</div>
		{:else if step === 3}
			<div class="step-content" in:fade={{ duration: 200 }}>
				<h2 class="step-title">{t('habit.onboard_notify_title') || 'Want a daily reminder?'}</h2>
				<p class="step-desc">{t('habit.onboard_notify_desc') || 'A gentle nudge when it\'s time to practice.'}</p>
				<div class="option-row">
					<button class="option-btn notify-btn" onclick={() => handleNotificationChoice(true)}>
						<span class="option-main">🔔 {t('habit.onboard_yes') || 'Yes, remind me!'}</span>
					</button>
					<button class="option-btn notify-btn secondary" onclick={() => handleNotificationChoice(false)}>
						<span class="option-main">{t('habit.onboard_no') || 'Not now'}</span>
					</button>
				</div>
			</div>
		{:else if step === 4}
			<div class="step-content" in:fade={{ duration: 200 }}>
				<div class="ready-emoji">🎹</div>
				<h2 class="step-title">{t('habit.onboard_ready_title') || 'You\'re all set!'}</h2>
				<div class="ready-summary">
					<div class="summary-item">
						<span class="summary-label">{t('habit.onboard_daily') || 'Daily goal'}</span>
						<span class="summary-value">{dailyGoalMinutes} min</span>
					</div>
					<div class="summary-item">
						<span class="summary-label">{t('habit.onboard_time') || 'Preferred time'}</span>
						<span class="summary-value">{TIME_OPTIONS.find(o => o.value === preferredTime)?.icon} {TIME_OPTIONS.find(o => o.value === preferredTime)?.label}</span>
					</div>
					<div class="summary-item">
						<span class="summary-label">{t('habit.onboard_reminders') || 'Reminders'}</span>
						<span class="summary-value">{enableNotifications ? '🔔 On' : '🔕 Off'}</span>
					</div>
				</div>
				<button class="start-btn" onclick={handleFinish}>
					{t('habit.onboard_start') || 'Start Practicing'} →
				</button>
			</div>
		{/if}
	</div>
</div>

<style>
	.onboarding-overlay {
		position: fixed;
		inset: 0;
		z-index: 999;
		display: flex;
		align-items: center;
		justify-content: center;
		background: rgba(0, 0, 0, 0.8);
		backdrop-filter: blur(8px);
		padding: 20px;
	}

	.onboarding-card {
		background: var(--card-bg, #161616);
		border: 1px solid var(--border, #222);
		border-radius: 16px;
		padding: 32px 28px;
		max-width: 400px;
		width: 100%;
	}

	.step-dots {
		display: flex;
		justify-content: center;
		gap: 8px;
		margin-bottom: 24px;
	}

	.step-dot {
		width: 8px;
		height: 8px;
		border-radius: 50%;
		background: rgba(255, 255, 255, 0.1);
		transition: all 0.3s;
	}

	.step-dot.active {
		background: #fb923c;
		transform: scale(1.3);
	}

	.step-dot.done {
		background: #4ade80;
	}

	.step-content {
		text-align: center;
	}

	.step-title {
		font-size: 1.2rem;
		font-weight: 700;
		color: var(--text, #fff);
		margin: 0 0 8px;
	}

	.step-desc {
		font-size: 0.8rem;
		color: var(--text-muted, #888);
		margin: 0 0 24px;
	}

	.option-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 10px;
	}

	.option-row {
		display: flex;
		flex-direction: column;
		gap: 10px;
	}

	.option-btn {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 4px;
		padding: 14px 16px;
		border: 1.5px solid var(--border, #222);
		border-radius: var(--radius, 8px);
		background: rgba(255, 255, 255, 0.03);
		cursor: pointer;
		transition: all 0.2s;
		color: inherit;
		font-family: inherit;
		width: 100%;
	}

	.option-btn:hover {
		border-color: rgba(251, 146, 60, 0.4);
		background: rgba(251, 146, 60, 0.06);
	}

	.option-btn.selected {
		border-color: #fb923c;
		background: rgba(251, 146, 60, 0.1);
	}

	.option-main {
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--text, #fff);
	}

	.option-sub {
		font-size: 0.65rem;
		color: var(--text-muted, #888);
	}

	.time-btn {
		flex-direction: row;
		gap: 10px;
		justify-content: center;
	}

	.time-icon {
		font-size: 1.2rem;
	}

	.notify-btn {
		padding: 16px;
	}

	.notify-btn.secondary {
		border-color: var(--border, #222);
		background: transparent;
	}

	.notify-btn.secondary .option-main {
		color: var(--text-muted, #888);
		font-weight: 400;
	}

	.ready-emoji {
		font-size: 3rem;
		margin-bottom: 12px;
	}

	.ready-summary {
		display: flex;
		flex-direction: column;
		gap: 8px;
		margin: 20px 0 24px;
		padding: 14px;
		background: rgba(255, 255, 255, 0.03);
		border-radius: var(--radius, 8px);
		border: 1px solid var(--border, #222);
	}

	.summary-item {
		display: flex;
		justify-content: space-between;
		font-size: 0.8rem;
	}

	.summary-label {
		color: var(--text-muted, #888);
	}

	.summary-value {
		color: var(--text, #fff);
		font-weight: 600;
	}

	.start-btn {
		display: block;
		width: 100%;
		padding: 14px;
		border: none;
		border-radius: var(--radius, 8px);
		background: #fb923c;
		color: #000;
		font-size: 0.95rem;
		font-weight: 700;
		cursor: pointer;
		transition: all 0.2s;
		font-family: inherit;
	}

	.start-btn:hover {
		background: #f59e0b;
		transform: translateY(-1px);
	}
</style>
