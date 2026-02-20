// Theme system — supports default and partner white-label themes

export type ThemeId = 'default' | 'openstudio';

export interface ThemeInfo {
	id: ThemeId;
	name: string;
	description: string;
	/** CSS data-theme attribute value */
	dataTheme: string;
	/** Primary brand color (for UI hints) */
	accentColor?: string;
}

export const THEMES: ThemeInfo[] = [
	{
		id: 'default',
		name: 'Chord Trainer',
		description: 'Default Theme',
		dataTheme: 'default',
	},
	{
		id: 'openstudio',
		name: 'Open Studio',
		description: 'Navy & Orange — Open Studio Jazz',
		dataTheme: 'openstudio',
		accentColor: '#ff6d42',
	},
];

const THEME_KEY = 'chord-trainer-theme';

export function loadTheme(): ThemeId {
	if (typeof localStorage === 'undefined') return 'default';
	return (localStorage.getItem(THEME_KEY) as ThemeId) || 'default';
}

export function saveTheme(theme: ThemeId): void {
	if (typeof localStorage === 'undefined') return;
	localStorage.setItem(THEME_KEY, theme);
}

export function applyTheme(theme: ThemeId): void {
	if (typeof document === 'undefined') return;
	document.documentElement.setAttribute('data-theme', theme);
}
