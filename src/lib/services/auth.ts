// Auth service — manages Supabase auth state on the client
import { getSupabase } from './supabase';
import type { User, Session, AuthError, AuthChangeEvent } from '@supabase/supabase-js';

export type AuthState = {
	user: User | null;
	session: Session | null;
	loading: boolean;
};

const AUTH_CALLBACKS: Array<(state: AuthState) => void> = [];

let currentState: AuthState = { user: null, session: null, loading: true };
let initialized = false;

export function getAuthState(): AuthState {
	return currentState;
}

export function onAuthChange(cb: (state: AuthState) => void): () => void {
	AUTH_CALLBACKS.push(cb);
	cb(currentState);
	return () => {
		const idx = AUTH_CALLBACKS.indexOf(cb);
		if (idx >= 0) AUTH_CALLBACKS.splice(idx, 1);
	};
}

/** Resolves with the first settled auth state (session known, or none). */
export function whenAuthReady(): Promise<AuthState> {
	return new Promise((resolve) => {
		let unsub: (() => void) | null = null;
		let done = false;
		unsub = onAuthChange((s) => {
			if (done || s.loading) return;
			done = true;
			resolve(s);
			unsub?.();
		});
		if (done) unsub();
	});
}

// The habit onboarding is per player, not per browser, so "done" lives on the
// account. User metadata needs no table or migration, works for free accounts
// (whose data never syncs) and arrives with the session — no extra request.
const ONBOARDING_FLAG = 'onboarding_done';

export function isAccountOnboarded(user: User | null): boolean {
	return user?.user_metadata?.[ONBOARDING_FLAG] === true;
}

export async function markAccountOnboarded(): Promise<void> {
	const { user } = currentState;
	if (!user || isAccountOnboarded(user)) return;
	await getSupabase().auth.updateUser({ data: { [ONBOARDING_FLAG]: true } });
}

function notify(state: AuthState) {
	currentState = state;
	for (const cb of AUTH_CALLBACKS) cb(state);
}

export async function initAuth(): Promise<void> {
	if (initialized) return;
	initialized = true;

	const supabase = getSupabase();

	// Get current session
	const { data: { session } } = await supabase.auth.getSession();
	const user = session?.user ?? null;
	notify({ user, session, loading: false });

	// Listen for auth changes
	supabase.auth.onAuthStateChange((event: AuthChangeEvent, session: Session | null) => {
		notify({ user: session?.user ?? null, session, loading: false });
		// First sign-in after ticking the signup opt-in: let the server record it
		// and send the double opt-in mail. Idempotent, so a repeat is harmless.
		if (event === 'SIGNED_IN' && session?.user.user_metadata?.email_updates_opt_in) {
			void fetch('/api/email-consent').catch(() => {});
		}
	});
}

/**
 * `emailUpdates` is the unticked-by-default opt-in from the signup form. It
 * rides in user metadata because the account cannot record anything until the
 * address is confirmed; /api/email-consent turns it into a consent record and
 * sends the double opt-in on first sign-in.
 */
export async function signUp(
	email: string,
	password: string,
	emailUpdates = false,
	locale = 'en',
): Promise<{ error: AuthError | null }> {
	const supabase = getSupabase();
	const { error } = await supabase.auth.signUp({
		email,
		password,
		options: {
			emailRedirectTo: `${window.location.origin}/auth/callback`,
			data: emailUpdates ? { email_updates_opt_in: true, locale } : undefined,
		},
	});
	return { error };
}

export async function signIn(
	email: string,
	password: string,
): Promise<{ error: AuthError | null; user: User | null }> {
	const supabase = getSupabase();
	const { data, error } = await supabase.auth.signInWithPassword({ email, password });
	return { error, user: data?.user ?? null };
}

export async function signInWithProvider(provider: 'google' | 'github'): Promise<{ error: AuthError | null }> {
	const supabase = getSupabase();
	const { error } = await supabase.auth.signInWithOAuth({
		provider,
		options: {
			redirectTo: `${window.location.origin}/auth/callback`,
		},
	});
	return { error };
}

export async function signOut(): Promise<void> {
	const supabase = getSupabase();
	await supabase.auth.signOut();
}

export async function resetPassword(email: string): Promise<{ error: AuthError | null }> {
	const supabase = getSupabase();
	const { error } = await supabase.auth.resetPasswordForEmail(email, {
		redirectTo: `${window.location.origin}/auth/reset-password`,
	});
	return { error };
}

export async function updatePassword(newPassword: string): Promise<{ error: AuthError | null }> {
	const supabase = getSupabase();
	const { error } = await supabase.auth.updateUser({ password: newPassword });
	return { error };
}

export async function deleteAccount(): Promise<{ error: Error | null }> {
	try {
		const res = await fetch('/api/account/delete', { method: 'POST' });
		if (!res.ok) {
			const data = await res.json();
			return { error: new Error(data.error || 'Failed to delete account') };
		}
		await signOut();
		return { error: null };
	} catch (e) {
		return { error: e instanceof Error ? e : new Error('Unknown error') };
	}
}
