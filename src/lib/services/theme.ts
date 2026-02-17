// Theme system — allows switching between default (personal) and Open Studio branded theme
// Themes are CSS custom property overrides applied via data-theme attribute on <html>

export type ThemeId = 'default' | 'openstudio';

export interface ThemeInfo {
	id: ThemeId;
	name: string;
	description: string;
}

export const THEMES: ThemeInfo[] = [
	{
		id: 'default',
		name: 'Chord Trainer',
		description: 'Persönliches Design',
	},
	{
		id: 'openstudio',
		name: 'Open Studio',
		description: 'Open Studio Jazz Branding',
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
