// Theme system — light/dark + partner white-label themes.

export type ThemeId = 'default' | 'light' | 'openstudio';

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
		description: 'Dark — warm jazz club',
		dataTheme: 'default',
	},
	{
		id: 'light',
		name: 'Chord Trainer Light',
		description: 'Light — daytime café',
		dataTheme: 'light',
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

/** Raw stored override, if the user explicitly picked one. null = follow system. */
export function loadThemeOverride(): ThemeId | null {
	if (typeof localStorage === 'undefined') return null;
	const v = localStorage.getItem(THEME_KEY);
	return v === 'default' || v === 'light' || v === 'openstudio' ? v : null;
}

/** Back-compat: previous code imported loadTheme(). */
export function loadTheme(): ThemeId {
	return resolveTheme();
}

export function saveTheme(theme: ThemeId): void {
	if (typeof localStorage === 'undefined') return;
	localStorage.setItem(THEME_KEY, theme);
}

export function clearThemeOverride(): void {
	if (typeof localStorage === 'undefined') return;
	localStorage.removeItem(THEME_KEY);
}

function systemPrefersLight(): boolean {
	if (typeof window === 'undefined' || !window.matchMedia) return false;
	return window.matchMedia('(prefers-color-scheme: light)').matches;
}

/**
 * Effective theme: explicit override wins; otherwise follow the OS.
 * White-label (openstudio) is only ever set explicitly.
 */
export function resolveTheme(): ThemeId {
	const override = loadThemeOverride();
	if (override) return override;
	return systemPrefersLight() ? 'light' : 'default';
}

export function applyTheme(theme: ThemeId): void {
	if (typeof document === 'undefined') return;
	document.documentElement.setAttribute('data-theme', theme);
}

/** Apply the resolved theme and keep it in sync with the OS until overridden. */
export function initTheme(): () => void {
	applyTheme(resolveTheme());
	if (typeof window === 'undefined' || !window.matchMedia) return () => {};
	const mq = window.matchMedia('(prefers-color-scheme: light)');
	const onChange = () => {
		if (!loadThemeOverride()) applyTheme(resolveTheme());
	};
	mq.addEventListener?.('change', onChange);
	return () => mq.removeEventListener?.('change', onChange);
}

/** Is the currently-applied theme a light one? */
export function isLightActive(): boolean {
	if (typeof document === 'undefined') return false;
	return document.documentElement.getAttribute('data-theme') === 'light';
}

/** Flip between light and dark, persisting the explicit choice. */
export function toggleLightDark(): ThemeId {
	const next: ThemeId = isLightActive() ? 'default' : 'light';
	saveTheme(next);
	applyTheme(next);
	return next;
}
