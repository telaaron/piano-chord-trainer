import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ locals }) => {
	const { user } = await locals.safeGetSession();
	if (!user) throw error(401, 'Not authenticated');

	// Verify admin role
	const { data: profile } = await locals.supabaseAdmin
		.from('profiles')
		.select('role')
		.eq('id', user.id)
		.single();
	if (profile?.role !== 'admin') throw error(403, 'Forbidden');

	const supabase = locals.supabaseAdmin;

	// Total users (from auth.users via admin API)
	const { data: { users: allUsers }, error: usersError } = await supabase.auth.admin.listUsers({
		perPage: 1000,
	});

	const totalUsers = allUsers?.length ?? 0;

	// Active subscriptions
	const { data: subs, count: activeSubs } = await supabase
		.from('subscriptions')
		.select('*', { count: 'exact' })
		.in('status', ['active', 'trialing']);

	// User data stats (sessions count from user_data)
	const { data: userData } = await supabase
		.from('user_data')
		.select('user_id, data, updated_at');
	
	let totalSessions = 0;
	let activeToday = 0;
	const today = new Date().toISOString().slice(0, 10);

	for (const ud of userData ?? []) {
		const d = ud.data as Record<string, unknown> | null;
		if (d && Array.isArray(d['chord-trainer-history'])) {
			totalSessions += d['chord-trainer-history'].length;
		}
		if (ud.updated_at && ud.updated_at.startsWith(today)) {
			activeToday++;
		}
	}

	// Recent users (last 20)
	const recentUsers = (allUsers ?? [])
		.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
		.slice(0, 20)
		.map(u => ({
			id: u.id,
			email: u.email,
			created_at: u.created_at,
			last_sign_in_at: u.last_sign_in_at,
		}));

	// Enrich with profiles data
	const userIds = recentUsers.map(u => u.id);
	const { data: profiles } = await supabase
		.from('profiles')
		.select('id, role')
		.in('id', userIds);
	const { data: subscriptions } = await supabase
		.from('subscriptions')
		.select('user_id, tier, status')
		.in('user_id', userIds);

	const profileMap = new Map((profiles ?? []).map(p => [p.id, p]));
	const subMap = new Map((subscriptions ?? []).map(s => [s.user_id, s]));

	const enrichedUsers = recentUsers.map(u => ({
		...u,
		role: profileMap.get(u.id)?.role ?? 'user',
		tier: subMap.get(u.id)?.tier ?? 'free',
		sub_status: subMap.get(u.id)?.status ?? null,
	}));

	// Signups per day (last 30 days)
	const thirtyDaysAgo = new Date();
	thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
	
	const signupsByDay: Record<string, number> = {};
	for (const u of allUsers ?? []) {
		const day = new Date(u.created_at).toISOString().slice(0, 10);
		if (new Date(day) >= thirtyDaysAgo) {
			signupsByDay[day] = (signupsByDay[day] || 0) + 1;
		}
	}

	// Subscription distribution
	const tierDistribution: Record<string, number> = { free: 0, pro: 0, educator: 0, institution: 0 };
	for (const s of subs ?? []) {
		if (s.tier in tierDistribution) {
			tierDistribution[s.tier]++;
		}
	}
	tierDistribution.free = totalUsers - (activeSubs ?? 0);

	return json({
		stats: {
			totalUsers,
			activeToday,
			totalSessions,
			activeSubs: activeSubs ?? 0,
		},
		recentUsers: enrichedUsers,
		signupsByDay,
		tierDistribution,
	});
};
