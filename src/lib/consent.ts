// The exact wording a person agrees to when they opt into product-update mail.
//
// Kept here rather than in i18n because the server stores the text shown with
// each consent: changing it means a new version, so old consents keep the
// words they were actually given.

export const CONSENT_TEXT_VERSION = 'v1-2026-10-13';

export const CONSENT_TEXT: Record<'de' | 'en', string> = {
	de: 'Ja, schickt mir gelegentlich E-Mails zu neuen Funktionen, Kursen und der JazzChords-App (höchstens ein paar pro Monat). Ich kann mich jederzeit mit einem Klick abmelden.',
	en: 'Yes, send me occasional emails about new features, courses and the JazzChords app (a few per month at most). I can unsubscribe at any time with one click.',
};

export type ConsentStatus = 'none' | 'pending' | 'confirmed';

export function consentText(locale: string | undefined): string {
	return locale?.startsWith('de') ? CONSENT_TEXT.de : CONSENT_TEXT.en;
}
