// Maps a SmartGoal `type` to an Icon key (see ui/Icon.svelte).
// Keeps the engine's emoji data in habits.ts untouched — only the render layer
// (GoalCard) translates type → custom icon, with the emoji as graceful fallback.

export function goalIconName(type: string): string {
	switch (type) {
		case 'speed':
			return 'speed';
		case 'consistency':
			return 'consistency';
		case 'exploration':
			return 'explore';
		case 'endurance':
			return 'endurance';
		case 'mastery':
			return 'challenge';
		case 'review':
			return 'adaptive';
		case 'accuracy':
			return 'accuracy';
		default:
			return 'focus';
	}
}
