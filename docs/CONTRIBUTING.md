# Chord Trainer – Contributing Guide

> Alles was ein Entwickler braucht um produktiv beizutragen.
> **Stand:** Maerz 2026

---

## Schnellstart

```bash
git clone [repo-url]
cd chord-trainer
pnpm install
pnpm dev          # http://localhost:5173
pnpm test         # Vitest
pnpm check        # svelte-check
```

---

## Verzeichnisstruktur

```
src/lib/
  engine/          Pure TS, keine Browser-Abhaengigkeiten
    notes.ts         Chromatische Skala, Noten-Utilities
    chords.ts        16 Akkord-Typen, Difficulty-Pools
    voicings.ts      9 Voicing-Berechnungen
    keyboard.ts      Keyboard-Layout und Key-Mapping
    progressions.ts  Progression-Generatoren
    voice-leading.ts Stimmfuehrungs-Analyse
    adaptive.ts      Adaptive Difficulty
    habits.ts        XP, Levels, Goals, Spaced Repetition
    courses.ts       Typsystem fuer Kurse
    plans.ts         Uebungsplaene
    custom-progressions.ts  Custom Progressions
    index.ts         Barrel Export
    *.test.ts        4 Test-Dateien (notes, chords, voicings, habits)

  courses/         Kurs-Definitionen (statisches TS)
    index.ts         Registry (ALL_COURSES, getCourse, getLesson)
    intervals.ts     Intervall-Kurs (9 Lektionen)
    shell-voicings.ts  Shell-Voicing-Kurs
    scale-degrees.ts   Stufenakkord-Kurs
    ultimate-plan.ts   Gesamtkurs

  services/        Browser-APIs + Seiteneffekte
    audio.ts         Tone.js Synthese
    midi.ts          Web MIDI API + Device Management
    audio-input.ts   Mikrofon Pitch-Detection
    midi-sound.ts    MIDI Audio Output
    course-progress.ts  Kurs-Fortschritt (localStorage)
    habits.ts        Habit-Profil (localStorage)
    progress.ts      Session-History (localStorage)
    theme.ts         Theme-Persistenz

  i18n/            Internationalisierung
    index.ts         t()-Funktion, Locale-Detection
    de.ts            Deutsche Uebersetzungen (~1470 Keys)
    en.ts            Englische Uebersetzungen (~1460 Keys)

  components/      18 Svelte 5 Komponenten
  utils/           Hilfsfunktionen (format.ts)

src/routes/        12 SvelteKit-Routen
```

---

## Konventionen

### TypeScript
- Strict Mode, 0 Errors
- Keine `any` — explizite Typen oder Inferenz
- Interfaces fuer Daten, Types fuer Unions
- Engine-Module exportieren pure Funktionen + Konstanten

### Svelte 5
- **$state** fuer lokalen State
- **$derived** fuer berechnete Werte
- **$props** fuer Component Props
- **$effect** fuer Seiteneffekte (sparsam)
- Keine Stores (Svelte 4 Pattern)

### CSS / Tailwind
- Tailwind 4 Utility-Classes
- CSS Custom Properties fuer Theme-Variablen
- `data-theme` auf `<html>` fuer Theming
- Responsive: sm:, md:, lg: Breakpoints

### i18n
- Alle UI-Texte ueber `t('key.path')`
- Neue Keys in **beiden** Dateien (de.ts + en.ts)
- Parameter: `t('key', { count: 5 })` → `{count}` wird ersetzt
- Verschachtelte Objekte: `learn.course.title` → `learn: { course: { title: '...' } }`

---

## Import-Regeln

```
Engine     ←  importiert NICHTS
Courses    ←  importiert Engine
Services   ←  importiert Engine
i18n       ←  importiert NICHTS
Components ←  importiert Engine, Services, i18n
Routes     ←  importiert ALLES
Utils      ←  importiert NICHTS
```

**Strikt:** Engine importiert nie Services/Components. Services importieren nie Components.

---

## Tests

### Ausfuehren

```bash
pnpm test          # Einmalig
pnpm test:watch    # Watch-Mode
```

### Test-Dateien (4)

| Datei | Tests | Fokus |
|-------|-------|-------|
| notes.test.ts | 34 | noteToSemitone, getNoteName, Enharmonics |
| chords.test.ts | 22 | CHORD_INTERVALS, Difficulty-Pools |
| voicings.test.ts | 20 | Voicing-Berechnung, PCSets |
| habits.test.ts | 56 | XP, Levels, Goals, Spaced Repetition |

### Test-Konventionen
- Vitest mit `describe`/`it`/`expect`
- Engine-only (keine Browser-Tests)
- Dateiname: `*.test.ts` neben der Quelldatei
- Kein Mocking noetig (pure Funktionen)

---

## Neuen Kurs hinzufuegen

1. Erstelle `src/lib/courses/mein-kurs.ts`:

```typescript
import type { Course } from '$lib/engine/courses';

export const meinKurs: Course = {
  id: 'mein-kurs',
  titleKey: 'learn.courses.mein_kurs.title',
  subtitleKey: 'learn.courses.mein_kurs.subtitle',
  level: 'beginner',
  modules: [
    {
      titleKey: 'learn.courses.mein_kurs.mod1.title',
      lessons: [
        {
          id: 'lektion-1',
          titleKey: 'learn.courses.mein_kurs.l1.title',
          subtitleKey: 'learn.courses.mein_kurs.l1.subtitle',
          steps: [
            { type: 'theory', ... },
            { type: 'practice', ... },
            { type: 'challenge', ... }
          ]
        }
      ]
    }
  ]
};
```

2. Registriere in `src/lib/courses/index.ts`
3. Fuege i18n-Keys in `de.ts` und `en.ts` hinzu
4. Teste: `pnpm dev` → `/learn/mein-kurs`

---

## Neue Sprache hinzufuegen

1. Erstelle `src/lib/i18n/fr.ts` (kopiere en.ts als Vorlage)
2. Uebersetze alle Keys
3. Registriere in `src/lib/i18n/index.ts`:
   - Import hinzufuegen
   - Zum translations-Objekt hinzufuegen
   - Locale-Type erweitern
4. Locale-Toggle in Layout aktualisieren

---

## Build und Deploy

```bash
pnpm build        # Erzeugt .svelte-kit/output
pnpm preview      # Lokale Vorschau des Builds
```

- **Deploy:** Automatisch via GitHub → Vercel
- **Adapter:** @sveltejs/adapter-vercel
- **Checks vor Deploy:** `pnpm check && pnpm test`

---

## Haeufige Aufgaben

| Aufgabe | Befehl / Datei |
|---------|---------------|
| Neuen Akkord-Typ | `engine/chords.ts` → CHORD_INTERVALS |
| Neues Voicing | `engine/voicings.ts` → getVoicingNotes() |
| Neue Route | `src/routes/pfad/+page.svelte` |
| Neue Komponente | `src/lib/components/Name.svelte` |
| i18n-Key | `i18n/de.ts` + `i18n/en.ts` |
| Test | `engine/name.test.ts` |

---

*Zuletzt aktualisiert: Maerz 2026*
