# Chord Trainer – Agent Handoff

> Kontext fuer AI-Agenten die am Projekt weiterarbeiten.
> **Stand:** Maerz 2026 · **Version:** 0.5.0

---

## Projekt-Identitaet

| Feld | Wert |
|------|------|
| Name | Jazz Piano Chord Trainer |
| URL | jazzchords.app |
| Stack | SvelteKit 2.5 + Svelte 5 (Runes) + TS 5.5 + Tailwind 4 |
| Hosting | Vercel (adapter-vercel) |
| Package Manager | pnpm |

---

## Aktueller Stand

### Was existiert

- **Speed-Drill Trainer** (`/train`, ~2700 Zeilen): 16 Akkord-Typen, 9 Voicings, 4+ Progressions-Modi, MIDI/Mikrofon/Click Input, Adaptive Difficulty, Voice Leading, Results
- **Kurs-System** (`/learn`, 4 Kurse): Intervals, Shell Voicings, Scale Degrees, Ultimate Plan. 3-Step-Modell (Theory → Practice → Challenge) mit 3-Phasen-Practice (Guided → Find → Free)
- **Habit-Engine**: XP, Levels (1-50), Streaks, Smart Goals, Spaced Repetition, Celebrations, Onboarding
- **MIDI**: Web MIDI API, persistente Device-Auswahl, Hide/Unhide, Virtual-Port-Filter, Auto-Reconnect
- **Audio**: Tone.js Synthese, @spotify/basic-pitch Mikrofon-Input, MIDI-Sound
- **i18n**: DE + EN (~1460 Keys), t() Funktion
- **12 Routen**, **18 Komponenten**, **12 Engine-Module**, **8 Services**, **4 Test-Dateien**

### Qualitaet

- 0 TypeScript Errors
- 0 svelte-check Errors
- 0 svelte-check a11y Warnings
- 132+ Unit Tests (notes, chords, voicings, habits)

---

## Architektur-Regeln

1. **Engine importiert nie Services/Components** (pure TS, Framework-agnostisch)
2. **Services importieren nie Components** (Browser-APIs only)
3. **Alle UI-Texte via t()** (keine hardcodierten Strings)
4. **Svelte 5 Runes** ($state, $derived, $props, $effect — keine Stores)
5. **Neue i18n-Keys immer in BEIDEN Dateien** (de.ts + en.ts)
6. **localStorage fuer Persistenz** (kein Backend)

---

## Wichtige Dateien

| Datei | Zeilen | Inhalt |
|-------|--------|--------|
| `src/routes/train/+page.svelte` | ~2700 | Haupt-Trainer State Machine |
| `src/routes/learn/[courseId]/[lessonId]/+page.svelte` | ~980 | Lektions-Player |
| `src/lib/engine/courses.ts` | 202 | Kurs-Typsystem |
| `src/lib/services/midi.ts` | — | MIDI Device Management |
| `src/lib/i18n/de.ts` | ~1470 | Deutsche Uebersetzungen |
| `src/lib/courses/intervals.ts` | — | Intervall-Kurs (9 Lektionen) |

---

## Offene Arbeit (Roadmap-Auszug)

### Kurzfristig (Q2 2026)
- Mehr Kurse (Rootless Voicings, Rhythmisches Training)
- Voice Leading QA durcharbeiten (siehe QA_CHECKLIST.md)
- In-Time Comping QA
- Ear Training fertigstellen
- Unit Tests fuer voice-leading.ts, adaptive.ts

### Mittelfristig (Q3-Q4 2026)
- Product Hunt Launch
- B2B Pilot (Open Studio)
- Pro-Tier (Freemium-Gate)
- Benutzerkonten + Cloud-Sync

### Langfristig (2027)
- Lesson-Context-API (B2B postMessage)
- LMS-Integration (LTI)
- Mobile App

---

## Kontext fuer haeufige Aufgaben

### Neuen Kurs erstellen
→ Siehe CONTRIBUTING.md, Abschnitt "Neuen Kurs hinzufuegen"

### Bug im Trainer fixen
→ `src/routes/train/+page.svelte` — State Machine mit Phasen: setup, warmup, playing, results, custom-editor

### MIDI-Problem debuggen
→ `src/lib/services/midi.ts` + `/midi-test` Route fuer Live-Diagnostik

### i18n erweitern
→ Key in `de.ts` UND `en.ts` hinzufuegen, in Component via `t('path.to.key')` verwenden

### Test schreiben
→ Pattern von `habits.test.ts` folgen (56 Tests, gutes Beispiel)

---

## Docs-Uebersicht

| Dokument | Inhalt |
|----------|--------|
| ARCHITECTURE.md | Schichten, Module, Datenfluesse |
| FEATURES.md | Vollstaendige Feature-Liste |
| BUSINESS.md | Monetarisierung, Wettbewerb, GTM |
| MUSIC_THEORY.md | Musiktheoretische Konzepte |
| PROJECT.md | Tech Stack, Verzeichnisstruktur |
| DECISIONS.md | Design-Entscheidungen + Begruendungen |
| CONTRIBUTING.md | Entwickler-Setup + Konventionen |
| ROADMAP.md | Produkt-Roadmap (Q2 2026 – 2027) |
| HABIT_ENGINE.md | Habit-Engine-Designdokument |
| KURS_KONZEPT.md | Kurs-System-Designdokument |
| QA_CHECKLIST.md | QA-Checkliste fuer neue Features |
| SEO_STRATEGY.md | Backlink- und SEO-Strategie |
| OPEN_QUESTIONS.md | Offene Fragen |

---

*Zuletzt aktualisiert: Maerz 2026*
