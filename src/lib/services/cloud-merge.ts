// Merge rules for cloud sync — pure, no storage access.
//
// The account's copy and this device's copy are both partial truths: a new
// browser starts with defaults, an old one may hold sessions the cloud never
// saw. Overwriting either side loses practice data, so the two are merged.

type SyncData = Record<string, unknown>;

const HISTORY_KEY = 'chord-trainer-history';
const PROFILE_KEY = 'chord-trainer-habit-profile';
const STREAK_KEY = 'chord-trainer-streak';
const MAX_HISTORY = 100; // same cap as services/progress

type Session = { id?: string; timestamp?: number };
type Profile = { totalXP?: number; onboardingDone?: boolean };
type Streak = { current?: number; best?: number; lastDate?: string };

const isObj = (v: unknown): v is Record<string, unknown> =>
	typeof v === 'object' && v !== null && !Array.isArray(v);

function mergeHistory(local: unknown, cloud: unknown): unknown {
	if (!Array.isArray(local)) return cloud;
	if (!Array.isArray(cloud)) return local;
	const byId = new Map<string, Session>();
	for (const s of [...cloud, ...local] as Session[]) {
		byId.set(s.id ?? `t${s.timestamp}`, s);
	}
	return [...byId.values()]
		.sort((a, b) => (b.timestamp ?? 0) - (a.timestamp ?? 0))
		.slice(0, MAX_HISTORY);
}

/** Choices the player makes; on upload the device's own choice is the newest. */
const PROFILE_PREFERENCES = [
	'dailyGoalMinutes',
	'preferredTime',
	'practiceAnchor',
	'notificationsEnabled',
	'notificationTime',
];

function mergeProfile(local: unknown, cloud: unknown, preferLocal: boolean): unknown {
	if (!isObj(local)) return cloud;
	if (!isObj(cloud)) return local;
	const l = local as Profile;
	const c = cloud as Profile;
	const base: Record<string, unknown> = { ...((c.totalXP ?? 0) > (l.totalXP ?? 0) ? cloud : local) };
	if (preferLocal) {
		for (const key of PROFILE_PREFERENCES) if (key in local) base[key] = local[key];
	}
	return { ...base, onboardingDone: Boolean(l.onboardingDone || c.onboardingDone) };
}

function mergeStreak(local: unknown, cloud: unknown): unknown {
	if (!isObj(local)) return cloud;
	if (!isObj(cloud)) return local;
	const l = local as Streak;
	const c = cloud as Streak;
	const latest = (c.lastDate ?? '') > (l.lastDate ?? '') ? cloud : local;
	return { ...latest, best: Math.max(l.best ?? 0, c.best ?? 0) };
}

/**
 * Combine this device's sync data with the account's.
 * `keepLocal: false` is the explicit "don't bring my device data" choice at
 * login: the account replaces whatever it has, local-only keys stay.
 * `preferLocal: true` is for uploads: this device's edits are the newest, so
 * they win plain keys and profile preferences; history, XP and streak still merge.
 */
export function mergeSyncData(
	local: SyncData,
	cloud: SyncData,
	{ keepLocal = true, preferLocal = false }: { keepLocal?: boolean; preferLocal?: boolean } = {},
): SyncData {
	const out: SyncData = { ...local };
	for (const [key, c] of Object.entries(cloud)) {
		if (c === undefined) continue;
		const l = local[key];
		if (!keepLocal || l === undefined) {
			out[key] = c;
		} else if (key === HISTORY_KEY) {
			out[key] = mergeHistory(l, c);
		} else if (key === PROFILE_KEY) {
			out[key] = mergeProfile(l, c, preferLocal);
		} else if (key === STREAK_KEY) {
			out[key] = mergeStreak(l, c);
		} else {
			out[key] = preferLocal ? l : c;
		}
	}
	return out;
}
