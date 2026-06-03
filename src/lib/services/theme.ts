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
 * Light mode is scoped to the practice surfaces only. The marketing/landing
 * pages and the global header always stay on the dark jazz-club theme.
 */
export function routeAllowsLight(pathname: string): boolean {
	return pathname.startsWith('/train') || pathname.startsWith('/learn');
}

/**
 * The user's *preferred* color scheme (override wins, else OS). This is what a
 * light/dark toggle reflects — independent of whether the current route shows it.
 */
export function preferredScheme(): 'light' | 'default' {
	const override = loadThemeOverride();
	if (override === 'light') return 'light';
	if (override === 'default') return 'default';
	if (override === 'openstudio') return 'default';
	return systemPrefersLight() ? 'light' : 'default';
}

/** Back-compat alias. */
export function resolveTheme(): ThemeId {
	return preferredScheme();
}

export function applyTheme(theme: ThemeId): void {
	if (typeof document === 'undefined') return;
	document.documentElement.setAttribute('data-theme', theme);
}

/**
 * Apply the effective theme for a given route: light only if the route allows
 * it AND the user prefers light; otherwise the default dark theme.
 */
export function applyThemeForRoute(pathname: string): void {
	const wantLight = routeAllowsLight(pathname) && preferredScheme() === 'light';
	applyTheme(wantLight ? 'light' : 'default');
}

/**
 * Initialise theming and keep it in sync with the OS (until overridden) for the
 * current route. Returns a cleanup fn. Pass the current pathname.
 */
export function initTheme(pathname = '/'): () => void {
	applyThemeForRoute(pathname);
	if (typeof window === 'undefined' || !window.matchMedia) return () => {};
	const mq = window.matchMedia('(prefers-color-scheme: light)');
	const onChange = () => {
		if (!loadThemeOverride()) applyThemeForRoute(getCurrentPath());
	};
	mq.addEventListener?.('change', onChange);
	return () => mq.removeEventListener?.('change', onChange);
}

function getCurrentPath(): string {
	return typeof location !== 'undefined' ? location.pathname : '/';
}

/** Is the dark/light *preference* light? (Not the currently-rendered theme.) */
export function isLightActive(): boolean {
	return preferredScheme() === 'light';
}

/** Flip the user's light/dark preference and re-apply for the current route. */
export function toggleLightDark(): ThemeId {
	const next: ThemeId = preferredScheme() === 'light' ? 'default' : 'light';
	saveTheme(next);
	applyThemeForRoute(getCurrentPath());
	return next;
}
