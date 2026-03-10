// Supabase client for browser-side usage
import { createBrowserClient } from '@supabase/ssr';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

let supabaseInstance: ReturnType<typeof createBrowserClient> | null = null;

export function getSupabase() {
	if (!supabaseInstance) {
		supabaseInstance = createBrowserClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);
	}
	return supabaseInstance;
}
