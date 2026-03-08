# Chord Trainer – Projektuebersicht

> Technische und organisatorische Eckdaten.
> **Stand:** Maerz 2026 · **Version:** 0.5.0

---

## Produkt

| Feld | Wert |
|------|------|
| Name | Jazz Piano Chord Trainer |
| Domain | jazzchords.app |
| Typ | Web-App (SPA mit SSR) |
| Sprachen | Deutsch + Englisch |
| Betreiber | Aaron Technologies OUe |
| Lizenz | Proprietaer |

---

## Tech Stack

| Technologie | Version | Zweck |
|------------|---------|-------|
| SvelteKit | 2.5.x | Full-Stack Framework |
| Svelte | 5.x | UI mit Runes ($state, $derived, $props, $effect) |
| TypeScript | 5.5.x | Typsicherheit (strict mode) |
| Tailwind CSS | 4.x | Styling via @tailwindcss/vite |
| Tone.js | 15.x | Audio-Synthese |
| @spotify/basic-pitch | 1.x | ML Pitch-Detection (Mikrofon) |
| lucide-svelte | 0.525.x | Icons |
| Vitest | 3.2.x | Unit Testing |
| Vercel | — | Hosting (adapter-vercel) |
| pnpm | — | Package Manager |

---

## Verzeichnisstruktur

```
src/
  app.html, app.css, app.d.ts
  lib/
    components/        18 Svelte-Komponenten
    engine/            12 Pure-TS-Module + 4 Test-Dateien
    services/          8 Browser-Service-Module
    courses/           4 Kurs-Definitionen + Index
    i18n/              3 Dateien (de.ts, en.ts, index.ts)
    utils/             1 Hilfsfunktion (format.ts)
  routes/
    +layout.svelte     Root-Layout
    +page.svelte       Landing Page
    train/             Haupt-Trainer
    learn/             Kurs-Browser
    learn/[courseId]/   Kurs-Detail
    learn/[courseId]/[lessonId]/  Lektions-Player
    midi-test/         MIDI-Diagnostik
    embed/             iFrame-Embed
    for-educators/     B2B Landing
    open-studio/       Partner-Pitch
    about/             Ueber uns
    privacy/           Datenschutz
    impressum/         Impressum
static/
  sw.js               Service Worker
  sitemap.xml         SEO
  robots.txt          SEO
  site.webmanifest    PWA
  favicon/            Favicons
  models/basic-pitch/ ML-Modell
  elements/           Bilder, Icons
  videos/             Hintergrund-Videos
docs/
  ARCHITECTURE.md     Technische Architektur
  FEATURES.md         Feature-Dokumentation
  BUSINESS.md         Business Model
  MUSIC_THEORY.md     Musiktheorie-Referenz
  PROJECT.md          Diese Datei
  DECISIONS.md        Design-Entscheidungen
  CONTRIBUTING.md     Entwickler-Guide
  ROADMAP.md          Produkt-Roadmap
  HABIT_ENGINE.md     Habit-Engine-Spec
  KURS_KONZEPT.md     Kurs-Konzept-Spec
  QA_CHECKLIST.md     QA-Checkliste
  SEO_STRATEGY.md     SEO/Backlink-Strategie
  OPEN_QUESTIONS.md   Offene Fragen
```

---

## Routen

| Route | Beschreibung |
|-------|-------------|
| `/` | Landing Page mit 3D-Video-Hero |
| `/train` | Speed-Drill Trainer (~2700 Zeilen) |
| `/learn` | Kurs-Browser |
| `/learn/[courseId]` | Kurs-Detail mit Modulen |
| `/learn/[courseId]/[lessonId]` | Lektions-Player (~980 Zeilen) |
| `/midi-test` | MIDI/Mikrofon-Test |
| `/embed` | iFrame-Embed (eigenes Layout) |
| `/for-educators` | B2B Landing Page |
| `/open-studio` | Open Studio Pitch |
| `/about` | Ueber das Projekt |
| `/privacy` | Datenschutzerklaerung |
| `/impressum` | Impressum |

---

## Qualitaet

| Metrik | Status |
|--------|--------|
| TypeScript Errors | 0 |
| svelte-check Errors | 0 |
| svelte-check Warnings | 0 (inkl. a11y) |
| Test-Dateien | 4 |
| Test-Assertions | 132+ |
| Runtime Dependencies | 3 |
| DevDependencies | 14 |

---

## Scripts

```bash
pnpm dev          # Entwicklungsserver
pnpm build        # Production Build
pnpm preview      # Build-Vorschau
pnpm check        # svelte-check
pnpm check:watch  # svelte-check (watch)
pnpm test         # Vitest
pnpm test:watch   # Vitest (watch)
pnpm format       # Prettier
```

---

## Browser-Support

| Browser | MIDI | Mikrofon | Audio | Status |
|---------|------|---------|-------|--------|
| Chrome/Edge (Desktop) | Ja | Ja | Ja | Voll unterstuetzt |
| Firefox (Desktop) | Nein | Ja | Ja | Kein MIDI, Mikrofon als Ersatz |
| Safari (Desktop) | Nein | Ja | Ja | Kein MIDI, Mikrofon als Ersatz |
| Chrome (Android) | Ja (OTG) | Ja | Ja | USB-MIDI mit Adapter |
| Safari (iOS) | Nein | Ja | Ja | Nur Mikrofon-Input |

---

## Design-Prinzipien

1. **Offline-First:** Kein Server-State, alles in localStorage
2. **Progressive Enhancement:** Erst Click-Piano, dann MIDI, dann Mikrofon
3. **Keine Registrierung:** Sofort nutzbar, kein Account noetig
4. **Zweisprachig:** DE + EN mit t()-System
5. **Accessibility:** a11y-konform (0 Warnings)
6. **Performance:** Client-only, Edge SSR via Vercel

---

*Zuletzt aktualisiert: Maerz 2026*
