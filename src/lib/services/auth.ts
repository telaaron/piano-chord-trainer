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
	supabase.auth.onAuthStateChange((_event: AuthChangeEvent, session: Session | null) => {
		notify({ user: session?.user ?? null, session, loading: false });
	});
}

export async function signUp(email: string, password: string): Promise<{ error: AuthError | null }> {
	const supabase = getSupabase();
	const { error } = await supabase.auth.signUp({
		email,
		password,
		options: {
			emailRedirectTo: `${window.location.origin}/auth/callback`,
		},
	});
	return { error };
}

export async function signIn(email: string, password: string): Promise<{ error: AuthError | null }> {
	const supabase = getSupabase();
	const { error } = await supabase.auth.signInWithPassword({ email, password });
	return { error };
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
