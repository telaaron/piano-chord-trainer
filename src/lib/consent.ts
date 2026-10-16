// The exact wording a person agrees to when they opt into product-update mail.
//
// Kept here rather than in i18n because the server stores the text shown with
// each consent: changing it means a new version, so old consents keep the
// words they were actually given.

// v2 adds the weekly practice mail (retention sprint, 16.10.2026). People who
// agreed to v1 only were promised "a few per month" about features, so they
// do not get the weekly mail until they agree to v2.
export const CONSENT_TEXT_VERSION = 'v2-2026-10-16';

export const CONSENT_TEXT: Record<'de' | 'en', string> = {
	de: 'Ja, schickt mir einmal pro Woche eine 5-Minuten-Übung und gelegentlich Neuigkeiten zu Funktionen, Kursen und der JazzChords-App. Ich kann mich jederzeit mit einem Klick abmelden.',
	en: 'Yes, send me a 5-minute exercise once a week and occasional news about features, courses and the JazzChords app. I can unsubscribe at any time with one click.',
};

export type ConsentStatus = 'none' | 'pending' | 'confirmed';

export function consentText(locale: string | undefined): string {
	return locale?.startsWith('de') ? CONSENT_TEXT.de : CONSENT_TEXT.en;
}
