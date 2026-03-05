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

<div class="fixed inset-0 z-[999] flex items-center justify-center bg-black/80 backdrop-blur-[8px] p-5" transition:fade={{ duration: 200 }}>
	<div class="bg-[var(--card-bg,#161616)] border border-[var(--border,#222)] rounded-2xl py-8 px-7 max-w-[400px] w-full" in:fly={{ y: 30, duration: 300 }}>
		<!-- Progress dots -->
		<div class="flex justify-center gap-2 mb-6">
			{#each [1, 2, 3, 4] as s}
				<div class="w-2 h-2 rounded-full transition-all duration-300 {s === step ? 'bg-[#fb923c] scale-[1.3]' : s < step ? 'bg-[#4ade80]' : 'bg-white/10'}"></div>
			{/each}
		</div>

		{#if step === 1}
			<div class="text-center" in:fade={{ duration: 200 }}>
				<h2 class="text-[1.2rem] font-bold text-[var(--text,#fff)] m-0 mb-2">{t('habit.onboard_time_title') || 'How much time do you have daily?'}</h2>
				<p class="text-[0.8rem] text-[var(--text-muted,#888)] m-0 mb-6">{t('habit.onboard_time_desc') || 'Start small — you can always do more.'}</p>
				<div class="grid grid-cols-2 gap-2.5">
					{#each MINUTE_OPTIONS as opt}
						<button
							class="flex flex-col items-center gap-1 py-3.5 px-4 border-[1.5px] rounded-[var(--radius,8px)] cursor-pointer transition-all duration-200 text-inherit font-[inherit] w-full {dailyGoalMinutes === opt.value ? 'border-[#fb923c] bg-[rgba(251,146,60,0.1)]' : 'border-[var(--border,#222)] bg-white/[0.03] hover:border-[rgba(251,146,60,0.4)] hover:bg-[rgba(251,146,60,0.06)]'}"
							onclick={() => { dailyGoalMinutes = opt.value; step = 2; }}
						>
							<span class="text-[0.85rem] font-semibold text-[var(--text,#fff)]">{opt.label}</span>
							<span class="text-[0.65rem] text-[var(--text-muted,#888)]">{opt.desc}</span>
						</button>
					{/each}
				</div>
			</div>
		{:else if step === 2}
			<div class="text-center" in:fade={{ duration: 200 }}>
				<h2 class="text-[1.2rem] font-bold text-[var(--text,#fff)] m-0 mb-2">{t('habit.onboard_when_title') || 'When do you like to practice?'}</h2>
				<p class="text-[0.8rem] text-[var(--text-muted,#888)] m-0 mb-6">{t('habit.onboard_when_desc') || 'Helps us time your reminders right.'}</p>
				<div class="flex flex-col gap-2.5">
					{#each TIME_OPTIONS as opt}
						<button
							class="flex flex-row items-center gap-2.5 justify-center py-3.5 px-4 border-[1.5px] rounded-[var(--radius,8px)] cursor-pointer transition-all duration-200 text-inherit font-[inherit] w-full {preferredTime === opt.value ? 'border-[#fb923c] bg-[rgba(251,146,60,0.1)]' : 'border-[var(--border,#222)] bg-white/[0.03] hover:border-[rgba(251,146,60,0.4)] hover:bg-[rgba(251,146,60,0.06)]'}"
							onclick={() => { preferredTime = opt.value; step = 3; }}
						>
							<span class="text-[1.2rem]">{opt.icon}</span>
							<span class="text-[0.85rem] font-semibold text-[var(--text,#fff)]">{opt.label}</span>
						</button>
					{/each}
				</div>
			</div>
		{:else if step === 3}
			<div class="text-center" in:fade={{ duration: 200 }}>
				<h2 class="text-[1.2rem] font-bold text-[var(--text,#fff)] m-0 mb-2">{t('habit.onboard_notify_title') || 'Want a daily reminder?'}</h2>
				<p class="text-[0.8rem] text-[var(--text-muted,#888)] m-0 mb-6">{t('habit.onboard_notify_desc') || 'A gentle nudge when it\'s time to practice.'}</p>
				<div class="flex flex-col gap-2.5">
					<button class="flex flex-col items-center gap-1 p-4 border-[1.5px] border-[var(--border,#222)] rounded-[var(--radius,8px)] bg-white/[0.03] cursor-pointer transition-all duration-200 text-inherit font-[inherit] w-full hover:border-[rgba(251,146,60,0.4)] hover:bg-[rgba(251,146,60,0.06)]" onclick={() => handleNotificationChoice(true)}>
						<span class="text-[0.85rem] font-semibold text-[var(--text,#fff)]">🔔 {t('habit.onboard_yes') || 'Yes, remind me!'}</span>
					</button>
					<button class="flex flex-col items-center gap-1 p-4 border-[1.5px] border-[var(--border,#222)] rounded-[var(--radius,8px)] bg-transparent cursor-pointer transition-all duration-200 text-inherit font-[inherit] w-full hover:border-[rgba(251,146,60,0.4)] hover:bg-[rgba(251,146,60,0.06)]" onclick={() => handleNotificationChoice(false)}>
						<span class="text-[0.85rem] font-normal text-[var(--text-muted,#888)]">{t('habit.onboard_no') || 'Not now'}</span>
					</button>
				</div>
			</div>
		{:else if step === 4}
			<div class="text-center" in:fade={{ duration: 200 }}>
				<div class="text-5xl mb-3">🎹</div>
				<h2 class="text-[1.2rem] font-bold text-[var(--text,#fff)] m-0 mb-2">{t('habit.onboard_ready_title') || 'You\'re all set!'}</h2>
				<div class="flex flex-col gap-2 mt-5 mb-6 p-3.5 bg-white/[0.03] rounded-[var(--radius,8px)] border border-[var(--border,#222)]">
					<div class="flex justify-between text-[0.8rem]">
						<span class="text-[var(--text-muted,#888)]">{t('habit.onboard_daily') || 'Daily goal'}</span>
						<span class="text-[var(--text,#fff)] font-semibold">{dailyGoalMinutes} min</span>
					</div>
					<div class="flex justify-between text-[0.8rem]">
						<span class="text-[var(--text-muted,#888)]">{t('habit.onboard_time') || 'Preferred time'}</span>
						<span class="text-[var(--text,#fff)] font-semibold">{TIME_OPTIONS.find(o => o.value === preferredTime)?.icon} {TIME_OPTIONS.find(o => o.value === preferredTime)?.label}</span>
					</div>
					<div class="flex justify-between text-[0.8rem]">
						<span class="text-[var(--text-muted,#888)]">{t('habit.onboard_reminders') || 'Reminders'}</span>
						<span class="text-[var(--text,#fff)] font-semibold">{enableNotifications ? '🔔 On' : '🔕 Off'}</span>
					</div>
				</div>
				<button class="block w-full p-3.5 border-none rounded-[var(--radius,8px)] bg-[#fb923c] text-black text-[0.95rem] font-bold cursor-pointer transition-all duration-200 font-[inherit] hover:bg-[#f59e0b] hover:-translate-y-px" onclick={handleFinish}>
					{t('habit.onboard_start') || 'Start Practicing'} →
				</button>
			</div>
		{/if}
	</div>
</div>
