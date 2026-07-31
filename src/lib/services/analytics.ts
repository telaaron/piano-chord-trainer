// Web analytics — who arrives, where from, and which pages they see.
//
// This answers the ONE question our own telemetry cannot: coach_events only
// ever sees people who already reached the trainer, so it is blind to the
// visitor who lands on the site and leaves. Acquisition is measured here;
// everything that happens inside a practice session stays in coach_events
// (see docs/coach-tuning-playbook.md). Two systems, no overlap.
//
// Vercel Analytics rather than a third-party tracker: the app already runs on
// Vercel, it needs no account, no cookie banner and no extra origin in the
// CSP, and the privacy policy has claimed we use it for some time — this makes
// that true rather than adding a further processor to disclose.

import { dev } from '$app/environment';
import { inject } from '@vercel/analytics';
import { isTelemetryEnabled } from './telemetry';

let injected = false;

/**
 * Start collecting page views. Safe to call more than once.
 *
 * Honours the same opt-out as the coach telemetry: a person who switched
 * tracking off in settings expects that to cover ALL measurement, not just
 * the part we happen to file under "telemetry". Opting out mid-session takes
 * effect on the next load — the script cannot be recalled once injected, and
 * pretending otherwise in the settings copy would be worse than saying so.
 */
export function initAnalytics(): void {
	if (injected) return;
	if (typeof window === 'undefined') return;
	if (!isTelemetryEnabled()) return;
	injected = true;
	// `mode` keeps local development out of the production numbers — without
	// it our own page reloads would be the bulk of the early traffic.
	inject({ mode: dev ? 'development' : 'production' });
}
