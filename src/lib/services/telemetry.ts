// Coach-Lab telemetry — anonymous, batched event tracking for the Auto-Modus ("Coach").
// Events are queued in memory and flushed as a single batched insert to `coach_events`.
// Never throws and never blocks the app: telemetry failures are always swallowed silently.

import { getSupabase } from './supabase';
import { getAuthState } from './auth';
import { getCohort } from './coach-config';

const DEVICE_ID_KEY = 'chord-trainer-device-id';
const OPTOUT_KEY = 'chord-trainer-telemetry-optout';

// No client-exposed build-time app version exists in this repo yet — fall back to 'dev'.
const APP_VERSION = 'dev';

const FLUSH_INTERVAL_MS = 10_000;
const FLUSH_BATCH_SIZE = 10;

export interface CoachEventRow {
	device_id: string;
	user_id: string | null;
	app: 'web';
	version: string;
	cohort: string;
	event_type: string;
	payload: object;
}

let queue: CoachEventRow[] = [];
let flushTimer: ReturnType<typeof setInterval> | null = null;
let listenersAttached = false;

/**
 * Returns the anonymous device ID, lazily generating and persisting one in localStorage.
 * Returns null when not in a browser (SSR) or when storage is unavailable.
 */
export function getDeviceId(): string | null {
	if (typeof window === 'undefined') return null;
	try {
		let id = localStorage.getItem(DEVICE_ID_KEY);
		if (!id) {
			id = crypto.randomUUID();
			localStorage.setItem(DEVICE_ID_KEY, id);
		}
		return id;
	} catch {
		return null;
	}
}

/** Whether telemetry is currently enabled (i.e. the user has not opted out). */
export function isTelemetryEnabled(): boolean {
	if (typeof window === 'undefined') return false;
	try {
		return localStorage.getItem(OPTOUT_KEY) !== '1';
	} catch {
		return true;
	}
}

/** Sets the telemetry opt-out flag. Pass `false` to opt out, `true` to opt back in. */
export function setTelemetryEnabled(enabled: boolean): void {
	if (typeof window === 'undefined') return;
	try {
		if (enabled) {
			localStorage.removeItem(OPTOUT_KEY);
		} else {
			localStorage.setItem(OPTOUT_KEY, '1');
			// Drop anything queued but not yet sent — respect opt-out immediately.
			queue = [];
		}
	} catch {
		// ignore
	}
}

function ensureListeners(): void {
	if (listenersAttached || typeof window === 'undefined') return;
	listenersAttached = true;

	if (!flushTimer) {
		flushTimer = setInterval(() => {
			void flushQueue();
		}, FLUSH_INTERVAL_MS);
	}

	document.addEventListener('visibilitychange', () => {
		if (document.visibilityState === 'hidden') {
			void flushQueue();
		}
	});
}

/**
 * Queues a coach telemetry event. Flushed in batches (every 10s, at 10 events, or on
 * page hide). Safe to call anywhere — it is a no-op during SSR, when telemetry is
 * disabled, and never throws.
 */
export function trackCoachEvent(eventType: string, payload: object = {}): void {
	try {
		if (typeof window === 'undefined') return;
		if (!isTelemetryEnabled()) return;

		const deviceId = getDeviceId();
		if (!deviceId) return;

		ensureListeners();

		const { user } = getAuthState();

		queue.push({
			device_id: deviceId,
			user_id: user?.id ?? null,
			app: 'web',
			version: APP_VERSION,
			cohort: getCohort(deviceId),
			event_type: eventType,
			payload,
		});

		if (queue.length >= FLUSH_BATCH_SIZE) {
			void flushQueue();
		}
	} catch {
		// Telemetry must never disturb the app.
	}
}

/** Flushes the in-memory queue as a single batched insert. Swallows all errors. */
export async function flushQueue(): Promise<void> {
	if (typeof window === 'undefined') return;
	if (queue.length === 0) return;

	const batch = queue;
	queue = [];

	try {
		const supabase = getSupabase();
		const { error } = await supabase.from('coach_events').insert(batch);
		if (error) {
			// Best-effort only — do not re-queue to avoid unbounded growth on persistent errors.
		}
	} catch {
		// Telemetry must never disturb the app.
	}
}
