import { browser } from '$app/environment';
import { en } from './en';
import { de } from './de';

export type Locale = 'en' | 'de';

let userLocale: Locale = 'en';

if (browser) {
  const stored = localStorage.getItem('chord-trainer-locale') as Locale;
  if (stored && (stored === 'en' || stored === 'de')) {
    userLocale = stored;
  }
}

export const translations = {
  en,
  de
};

export function t(key: string, params?: Record<string, string | number>): string {
  const keys = key.split('.');
  let current: any = translations[userLocale];
  
  if (!current) current = translations.en;

  for (const k of keys) {
    if (current && typeof current === 'object' && k in current) {
      current = current[k];
    } else {
      console.warn(`Missing translation for key: ${key} in locale: ${userLocale}`);
      // Fallback to EN if key missing in DE
      if (userLocale !== 'en') {
        let enCurrent: any = translations.en;
        for (const enK of keys) {
             if (enCurrent && typeof enCurrent === 'object' && enK in enCurrent) {
                enCurrent = enCurrent[enK];
             } else {
                return key;
             }
        }
        current = enCurrent;
      } else {
        return key;
      }
    }
  }
  
  let text = current as string;
  
  if (params && typeof text === 'string') {
    Object.entries(params).forEach(([k, v]) => {
      text = text.replace(new RegExp(`{${k}}`, 'g'), String(v));
    });
  }
  
  return text;
}

export function setLocale(newLocale: Locale): void {
  userLocale = newLocale;
  if (browser) {
    localStorage.setItem('chord-trainer-locale', newLocale);
    window.location.reload(); // Simple reload to apply changes
  }
}

export function getLocale(): Locale {
  return userLocale;
}
