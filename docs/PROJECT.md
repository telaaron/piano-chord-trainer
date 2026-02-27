# Chord Trainer — Projektbeschreibung

**Live:** [jazzchords.app](https://jazzchords.app)  
**Version:** 0.6.x  
**Stand:** Februar 2026  
**Betreiber:** Aaron Technologies OÜ, Tallinn

---

## Was ist Chord Trainer?

Chord Trainer ist eine kostenlose Web-App für Jazz-Piano-Schüler und -Studenten, die Akkorde und Voicings systematisch trainieren wollen. Die App läuft komplett im Browser — kein Login, keine Installation, kein Abo.

**Kern-Idee:** Wer Jazz Piano lernt, muss Akkorde so automatisieren, dass er nicht mehr über den Griff nachdenken muss. Das schafft man durch wiederholtes, strukturiertes Üben in allen 12 Tonarten. Chord Trainer macht genau das — schnell, fokussiert und ohne Overhead.

---

## Zielgruppen

| Segment | Beschreibung | Zugang |
|---------|-------------|--------|
| **B2C** | Jazz-Piano-Schüler, -Studenten, Autodidakten | Direkt auf jazzchords.app |
| **B2B** | Musiklehrer, die ihren Schülern Hausaufgaben geben | Über /for-educators |
| **B2B2C** | Musikschulen, Hochschulen, Konservatorien | Embed-Code auf /open-studio |

---

## Funktionsumfang

### Akkordtypen (16)

Beginner: Maj7, m7, 7 (Dominant), m7b5  
Intermediate: + Maj6, m6, dim7, Maj9, m9, 9  
Advanced: + Maj7#11, 7#11, 7b9, 7#9, 13, m11

### Voicing-Typen (9)

| Label | Kurzbeschreibung |
|-------|-----------------|
| Root Position | Alle Töne, Root unten |
| Shell Voicing | Nur Root + Terz + Septime |
| Half Shell | Terz-Root-Septime geordnet |
| Full Voicing | Root-Septime-Terz-Quinte |
| Rootless A | 3-5-7-9 (Bill Evans-Style) |
| Rootless B | 7-9-3-5 (komplementär) |
| 1st Inversion | Terz im Bass |
| 2nd Inversion | Quinte im Bass |
| 3rd Inversion | Septime im Bass |

### Progressions-Modi

- **Zufällig** — jeder Akkord unabhängig generiert
- **ii–V–I** — in allen 12 Tonarten, sequenziell
- **Quartenzirkel** — alle 12 Keys im Quintenzirkel
- **I–vi–ii–V Turnaround** — klassisches Jazz-Pattern
- **Custom Progressions** — eigene Folge tippen (z. B. `Cm7 - F7 - BbMaj7`), loopen, evaluieren

### MIDI-Integration

Web MIDI API (Chrome/Edge Desktop). Keyboard anstecken → App erkennt automatisch → Live-Feedback: grüne/rote Tasten auf der visuellen Klaviatur → bei richtigem Akkord automatisch weiter. Accuracy-Score pro Session.

### Übungspläne (7 kuratierte Pläne)

| Plan | Fokus |
|------|-------|
| Warm-Up | Einspielen, Shell Voicings |
| Speed Run | Tempo, Root Position |
| ii-V-I Deep Dive | Jazz-Standards-Vorbereitung |
| Turnaround | I-vi-ii-V in allen Keys |
| Challenge | Advanced Akkorde, Symbole |
| Quartenzirkel | Tonarten-Flüssigkeit |
| Voicing Drill | Muscle Memory pro Griff-Typ |

### Fortschritt & Gamification

- Session-History (localStorage, bis 100 Sessions)
- Tages-Streak mit Best-Streak-Tracking
- Sparkline-Trend (letzte 10 Sessions)
- Schwachstellen-Analyse: langsamster Root-Akkord identifiziert
- Verbesserungs-Trend pro Akkord ("25% schneller bei Db")

### Audio

Tone.js PolySynth (Triangle-Wave). Auto-Play bei jedem neuen Akkord. Metronom mit BPM-Einstellung (40–240), Akzent auf Beat 1, visueller Beat-Indicator.

### Embed-Modus

Leichtgewichtiger iFrame-Player (`/embed`) für Musikschul-Websites. Vordefinierte Progression, kein Navigation-Overhead.

---

## Tech Stack

| Schicht | Technologie |
|---------|------------|
| Framework | SvelteKit 2 + Svelte 5 (Runes) |
| Styling | Tailwind CSS 4 (CSS-native, kein Config-File) |
| Build | Vite 6 + TypeScript 5 |
| Audio | Tone.js 15 |
| MIDI | Web MIDI API (Browser-nativ) |
| Persistenz | localStorage (kein Backend, kein Login) |
| Hosting | Vercel (adapter-vercel) |

---

## Architektur-Prinzip

```
Engine (pure TS)  →  Services (Seiteneffekte)  →  Components (Svelte)  →  Routes (Pages)
```

- **`src/lib/engine/`** — Pure TypeScript, kein DOM. Akkord-Logik, Voicing-Berechnungen, Progressions-Generatoren, Übungspläne.
- **`src/lib/services/`** — Audio (Tone.js), MIDI (Web MIDI API), Progress (localStorage), Theme.
- **`src/lib/components/`** — Svelte 5 Components (Runes-Syntax). Kein Legacy (`$:`, `on:event`, `<slot>`).
- **`src/routes/`** — SvelteKit Pages und Layouts.

---

## Routen-Übersicht

| Route | Zweck |
|-------|-------|
| `/` | Haupt-App (Setup → Spielen → Ergebnis) |
| `/train` | Direktlink zum Training |
| `/for-educators` | Landing Page für Musiklehrer |
| `/open-studio` | Pitch + Embed-Generator für Musikschulen |
| `/embed` | iFrame-fähiger Embed-Player |
| `/about` | Projekt-Hintergrund |
| `/privacy` | Datenschutzerklärung |
| `/impressum` | Impressum |

---

## Browser-Support

| Browser | MIDI | Audio | Vollständig |
|---------|------|-------|-------------|
| Chrome Desktop | ✅ | ✅ | ✅ |
| Edge Desktop | ✅ | ✅ | ✅ |
| Firefox Desktop | ❌ | ✅ | Ohne MIDI |
| Safari (alle) | ❌ | ✅ | Ohne MIDI |
| Mobile (alle) | ❌ | ✅ | Ohne MIDI |

---

## Design-Prinzipien

1. **One-Tap-to-Play** — Wichtigste Aktion sofort erreichbar
2. **Guided, nicht Loaded** — App empfiehlt; Optionen sind versteckt, nicht weg
3. **Sound first** — Jeder Akkord ist hörbar; Ear + Finger = echtes Lernen
4. **Fortschritt spüren** — Nicht nur Zahlen, sondern konkrete Trends
5. **Übe-Routine > Einzel-Session** — Streaks, tägliche Pläne, Wiederkommen belohnen

---

## Business-Kontext

- **Kostenlos** — keine Paywall, kein Login
- **SEO-First** — jazzchords.app als Einstieg, /for-educators für B2B-SEO
- **Open Studio** — Lizenzmodell für Musikschulen in Entwicklung (White-Label, eigene Progressions-Bibliothek)
- **Kein Tracking** — keine Cookies, kein Analytics-Cookie-Banner, DSGVO-konform

---

## Weiterführende Dokumentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — Technische Entscheidungen & Patterns
- [FEATURES.md](FEATURES.md) — Feature-Backlog & Prioritäten
- [MUSIC_THEORY.md](MUSIC_THEORY.md) — Jazz-Theorie-Grundlagen für die Engine
- [DECISIONS.md](DECISIONS.md) — ADRs (Architecture Decision Records)
- [BACKLINK_STRATEGY.md](BACKLINK_STRATEGY.md) — Off-Page SEO & Marketing
- [BUSINESS.md](BUSINESS.md) — Lizenzmodell & Open Studio Strategie
- [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) — Offene Fragen & To-Dos
