<script lang="ts">
	import { t } from '$lib/i18n';
	import { fade, fly } from 'svelte/transition';
	import type { HabitProfile, TimeOfDay } from '$lib/engine/habits';
	import { requestNotificationPermission } from '$lib/services/habits';
	import { Sun, CloudSun, Moon, Bell, BellOff, Piano, ArrowRight, type Icon as LucideIcon } from 'lucide-svelte';

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

	const TIME_OPTIONS: { value: TimeOfDay; label: string; icon: typeof LucideIcon }[] = [
		{ value: 'morning', label: t('settings.greeting_morning') || 'Morning', icon: Sun },
		{ value: 'afternoon', label: t('settings.greeting_afternoon') || 'Afternoon', icon: CloudSun },
		{ value: 'evening', label: t('settings.greeting_evening') || 'Evening', icon: Moon },
	];

	async function handleNotificationChoice(enable: boolean) {
		enableNotifications = enable;
		if (enable) {
			const granted = await requestNotificationPermission();
			enableNotifications = granted;
		}
		step = 4;
	}

	const selectedTime = $derived(TIME_OPTIONS.find((o) => o.value === preferredTime));

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
	<!-- `--bg-card`, not `--card-bg`: the latter is defined nowhere, so the
	     hard-coded near-black fallback used to win in every theme — which is
	     what made this panel a dark slab on the light surfaces. -->
	<div class="bg-[var(--bg-card)] border border-[var(--border)] rounded-2xl py-8 px-7 max-w-[400px] w-full" in:fly={{ y: 30, duration: 300 }}>
		<!-- Progress dots -->
		<div class="flex justify-center gap-2 mb-6">
			{#each [1, 2, 3, 4] as s}
				<div class="w-2 h-2 rounded-full transition-all duration-300 {s === step ? 'bg-[var(--xp)] scale-[1.3]' : s < step ? 'bg-[var(--success)]' : 'bg-[var(--border)]'}"></div>
			{/each}
		</div>

		{#if step === 1}
			<div class="text-center" in:fade={{ duration: 200 }}>
				<h2 class="text-[1.2rem] font-bold text-[var(--text)] m-0 mb-2">{t('habit.onboard_time_title') || 'How much time do you have daily?'}</h2>
				<p class="text-[0.8rem] text-[var(--text-muted)] m-0 mb-6">{t('habit.onboard_time_desc') || 'Start small — you can always do more.'}</p>
				<div class="grid grid-cols-2 gap-2.5">
					{#each MINUTE_OPTIONS as opt}
						<button
							class="flex flex-col items-center gap-1 py-3.5 px-4 border-[1.5px] rounded-[var(--radius)] cursor-pointer transition-all duration-200 text-inherit font-[inherit] w-full {dailyGoalMinutes === opt.value ? 'border-[var(--xp)] bg-[var(--xp-muted)]' : 'border-[var(--border)] bg-[var(--bg-muted)] hover:border-[var(--xp)] hover:bg-[var(--xp-muted)]'}"
							onclick={() => { dailyGoalMinutes = opt.value; step = 2; }}
						>
							<span class="text-[0.85rem] font-semibold text-[var(--text)]">{opt.label}</span>
							<span class="text-[0.65rem] text-[var(--text-muted)]">{opt.desc}</span>
						</button>
					{/each}
				</div>
			</div>
		{:else if step === 2}
			<div class="text-center" in:fade={{ duration: 200 }}>
				<h2 class="text-[1.2rem] font-bold text-[var(--text)] m-0 mb-2">{t('habit.onboard_when_title') || 'When do you like to practice?'}</h2>
				<p class="text-[0.8rem] text-[var(--text-muted)] m-0 mb-6">{t('habit.onboard_when_desc') || 'Helps us time your reminders right.'}</p>
				<div class="flex flex-col gap-2.5">
					{#each TIME_OPTIONS as opt}
						{@const OptIcon = opt.icon}
						<button
							class="flex flex-row items-center gap-2.5 justify-center py-3.5 px-4 border-[1.5px] rounded-[var(--radius)] cursor-pointer transition-all duration-200 text-inherit font-[inherit] w-full {preferredTime === opt.value ? 'border-[var(--xp)] bg-[var(--xp-muted)]' : 'border-[var(--border)] bg-[var(--bg-muted)] hover:border-[var(--xp)] hover:bg-[var(--xp-muted)]'}"
							onclick={() => { preferredTime = opt.value; step = 3; }}
						>
							<span class="flex"><OptIcon size={19} aria-hidden="true" /></span>
							<span class="text-[0.85rem] font-semibold text-[var(--text)]">{opt.label}</span>
						</button>
					{/each}
				</div>
			</div>
		{:else if step === 3}
			<div class="text-center" in:fade={{ duration: 200 }}>
				<h2 class="text-[1.2rem] font-bold text-[var(--text)] m-0 mb-2">{t('habit.onboard_notify_title') || 'Want a daily reminder?'}</h2>
				<p class="text-[0.8rem] text-[var(--text-muted)] m-0 mb-6">{t('habit.onboard_notify_desc') || 'A gentle nudge when it\'s time to practice.'}</p>
				<div class="flex flex-col gap-2.5">
					<button class="flex flex-col items-center gap-1 p-4 border-[1.5px] border-[var(--border)] rounded-[var(--radius)] bg-[var(--bg-muted)] cursor-pointer transition-all duration-200 text-inherit font-[inherit] w-full hover:border-[var(--xp)] hover:bg-[var(--xp-muted)]" onclick={() => handleNotificationChoice(true)}>
						<span class="text-[0.85rem] font-semibold text-[var(--text)] inline-flex items-center gap-1.5"><Bell size={15} aria-hidden="true" /> {t('habit.onboard_yes') || 'Yes, remind me!'}</span>
					</button>
					<button class="flex flex-col items-center gap-1 p-4 border-[1.5px] border-[var(--border)] rounded-[var(--radius)] bg-transparent cursor-pointer transition-all duration-200 text-inherit font-[inherit] w-full hover:border-[var(--xp)] hover:bg-[var(--xp-muted)]" onclick={() => handleNotificationChoice(false)}>
						<span class="text-[0.85rem] font-normal text-[var(--text-muted)]">{t('habit.onboard_no') || 'Not now'}</span>
					</button>
				</div>
			</div>
		{:else if step === 4}
			<div class="text-center" in:fade={{ duration: 200 }}>
				<div class="mb-3 flex justify-center text-[var(--xp)]"><Piano size={48} aria-hidden="true" /></div>
				<h2 class="text-[1.2rem] font-bold text-[var(--text)] m-0 mb-2">{t('habit.onboard_ready_title') || 'You\'re all set!'}</h2>
				<div class="flex flex-col gap-2 mt-5 mb-6 p-3.5 bg-[var(--bg-muted)] rounded-[var(--radius)] border border-[var(--border)]">
					<div class="flex justify-between text-[0.8rem]">
						<span class="text-[var(--text-muted)]">{t('habit.onboard_daily') || 'Daily goal'}</span>
						<span class="text-[var(--text)] font-semibold">{dailyGoalMinutes} min</span>
					</div>
					<div class="flex justify-between text-[0.8rem]">
						<span class="text-[var(--text-muted)]">{t('habit.onboard_time') || 'Preferred time'}</span>
						<span class="text-[var(--text)] font-semibold inline-flex items-center gap-1.5">{#if selectedTime}{@const SelectedIcon = selectedTime.icon}<SelectedIcon size={14} aria-hidden="true" /> {selectedTime.label}{/if}</span>
					</div>
					<div class="flex justify-between text-[0.8rem]">
						<span class="text-[var(--text-muted)]">{t('habit.onboard_reminders') || 'Reminders'}</span>
						<span class="text-[var(--text)] font-semibold inline-flex items-center gap-1.5">{#if enableNotifications}<Bell size={14} aria-hidden="true" /> On{:else}<BellOff size={14} aria-hidden="true" /> Off{/if}</span>
					</div>
				</div>
				<button class="w-full p-3.5 border-none rounded-[var(--radius)] bg-[var(--stamp)] text-[var(--stamp-ink)] text-[0.95rem] font-bold cursor-pointer transition-all duration-200 font-[inherit] hover:bg-[var(--stamp-hover)] hover:-translate-y-px inline-flex items-center justify-center gap-1.5" onclick={handleFinish}>
					{t('habit.onboard_start') || 'Start Practicing'} <ArrowRight size={16} aria-hidden="true" />
				</button>
			</div>
		{/if}
	</div>
</div>
