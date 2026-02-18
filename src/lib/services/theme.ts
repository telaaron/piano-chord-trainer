// Theme system — single default theme
// Kept minimal; Open Studio branding is handled via inline CSS on /open-studio pitch page

export type ThemeId = 'default';

export interface ThemeInfo {
	id: ThemeId;
	name: string;
	description: string;
}

export const THEMES: ThemeInfo[] = [
	{
		id: 'default',
		name: 'Chord Trainer',
		description: 'Default Theme',
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
