import { createServerClient } from '@supabase/ssr';
import { createClient } from '@supabase/supabase-js';
import { type Handle } from '@sveltejs/kit';
import { PUBLIC_SUPABASE_ANON_KEY, PUBLIC_SUPABASE_URL } from '$env/static/public';
import { SUPABASE_SERVICE_ROLE_KEY } from '$env/static/private';
import { sequence } from '@sveltejs/kit/hooks';

const setupSupabase: Handle = async ({ event, resolve }) => {
	event.locals.supabase = createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
		cookies: {
			getAll: () => event.cookies.getAll(),
			setAll: (cookiesToSet) => {
				cookiesToSet.forEach(({ name, value, options }) => {
					event.cookies.set(name, value, { ...options, path: '/' });
				});
			},
		},
	});

	event.locals.supabaseAdmin = createClient(PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
		auth: {
			persistSession: false,
			autoRefreshToken: false,
			detectSessionInUrl: false,
		},
	});

	event.locals.safeGetSession = async () => {
		const {
			data: { session },
		} = await event.locals.supabase.auth.getSession();
		if (!session) {
			return { session: null, user: null };
		}

		const {
			data: { user },
			error,
		} = await event.locals.supabase.auth.getUser();
		if (error) {
			return { session: null, user: null };
		}

		return { session, user };
	};

	return resolve(event, {
		filterSerializedResponseHeaders(name) {
			return name === 'content-range' || name === 'x-supabase-api-version';
		},
	});
};

const authGuard: Handle = async ({ event, resolve }) => {
	const { session, user } = await event.locals.safeGetSession();
	event.locals.session = session;
	event.locals.user = user;

	// Admin route protection
	if (event.url.pathname.startsWith('/admin')) {
		if (!user) {
			return new Response(null, {
				status: 303,
				headers: { location: '/auth/login?redirect=/admin' },
			});
		}
		// Check admin role
		const { data: profile } = await event.locals.supabaseAdmin
			.from('profiles')
			.select('role')
			.eq('id', user.id)
			.single();
		if (profile?.role !== 'admin') {
			return new Response('Forbidden', { status: 403 });
		}
	}

	return resolve(event);
};

export const handle = sequence(setupSupabase, authGuard);
