# Chord Trainer – Projekt-Übersicht & Roadmap

**Projekt:** Chord Trainer  
**Status:** v0.5.0 — Theming + Bug Fixes + Audio/Keyboard Overhaul  
**Zuletzt aktualisiert:** 17. Februar 2026  
**Autoren:** Agent 1 + Agent 2 + Agent 3  

---

## 🎹 Vision

> **Ein Übungspartner, kein Settings-Panel.**

Der Chord Trainer soll sich anfühlen wie ein guter Lehrer: Er weiß, wo du stehst, schlägt vor, was du üben sollst, und macht das Üben einfach — nicht komplex. Ein Spieler öffnet die App, sieht *eine* klare Empfehlung, drückt Play und übt. Die Tiefe kommt nicht durch mehr Buttons, sondern durch intelligente Defaults und organisches Schwieriger-Werden.

### Design-Prinzipien
1. **One-Tap-to-Play** — Die wichtigste Aktion ist immer sofort erreichbar
2. **Guided, nicht Loaded** — Optionen existieren, aber die App empfiehlt
3. **Fortschritt spüren** — Nicht nur Zahlen, sondern: "Du wirst schneller bei Bb-Akkorden"
4. **Übe-Routine > Einzel-Session** — Streaks, tägliche Plans, Wiederkommen belohnen
5. **Sound first** — Jeder Akkord ist hörbar. Ear + Finger = echtes Lernen

### Die Spieler-Perspektive
Ein Jazz-Piano-Student setzt sich ans Klavier und denkt:
- *"Ich hab 10 Minuten. Was soll ich üben?"* → **Übungsplan** schlägt vor
- *"ii-V-I in allen Keys, aber meine ♭-Keys sind schwach"* → **Schwachstellen-Analyse** fokussiert
- *"Bin ich eigentlich besser geworden?"* → **Fortschritts-Dashboard** zeigt Trend
- *"Heute keine Lust, aber ich will meinen Streak nicht verlieren"* → **Streak-Motivation**
- *"Wie klingt nochmal Db-Maj7 als Shell Voicing?"* → **Audio-Referenz** per Knopfdruck

---

## ✅ Aktuell Gebaut (v0.5.0)

### Audio- & Keyboard-Überhaul ✅
- ✅ **Keyboard-Display-Fix**: Nur Voicing-Noten werden highlighted, nie automatisch der Root bei Rootless-Voicings
- ✅ **Musik-Register-Spread**: Voicings spielen ab Oktave 3 mit natürlicher Spreizung, nicht mehr crammed
- ✅ **Root-Indikator-Fix**: Weißer Punkt erscheint nur wenn Root tatsächlich im Voicing ist
- ✅ **6 neue Voicing-Typen**: Rootless A (Bill Evans), Rootless B, Umkehrung 1–3
- ✅ **Custom Progressions**: Editor, Player mit Metronom, Evaluator, 7 Jazz-Presets

### Bug Fixes & Quality (v0.5.0) ✅
- ✅ **BUG-2**: `CM7` nicht mehr falsch als `Cm7` geparst (exakter Match first, dann case-insensitive)
- ✅ **BUG-3**: Sharp/Flat-Konsistenz behoben für `'both'` Akzidentalien
- ✅ **BUG-4**: Normale Bindestriche `-` jetzt als Progressions-Separator erkannt
- ✅ **BUG-1**: MIDI-Handler nach Custom Progressions korrekt wiederhergestellt
- ✅ **IMP-5**: `dim7 ≠ m7b5` — beide nun korrekt definiert
- ✅ **A11y**: ChordCard mit Tastatur-Support (`role="button"`, `tabindex="0"`)
- ✅ **DRY**: `formatTime()` aus 3 Dateien extrahiert → [src/lib/utils/format.ts](../src/lib/utils/format.ts)

### Open Studio Theme & Branding ✅
- ✅ **Theme-System**: Switcher in Nav (Palette-Icon), localStorage-Persistiert
- ✅ **Open Studio Theme**: Navy (#0c1821) + Gold (#c9a54e), warmere Piano-Keys, glowing hover-states
- ✅ **Conditional Branding**: Logo & Footer passen sich zum aktiven Theme an
- ✅ **Für Pitch zu Open Studio**: "Open Studio" im Logo, gold accent, Navy-Hintergrund

### Voicing-Typen: Vollständige Liste ✅

| Label | Englisch | Setting-Key | Was es macht |
|-------|----------|------------|---------------|
| Root Position | Root | `root` | Alle Noten, Root unten (C-E-G-Bb) |
| Shell Voicing | Shell | `shell` | 1st-3rd-7th nur (C-E-Bb) |
| Half Shell | Half-Shell | `half-shell` | 3rd-Root-7th geordnet (E-C-Bb) |
| Full Voicing | Full | `full` | Root-7th-3rd-5th (C-B-E-G) |
| Rootless A | Rootless A | `rootless-a` | 3-5-7-9 (Bill Evans; Bb-D-F-A) |
| Rootless B | Rootless B | `rootless-b` | 7-9-3-5 (komplementär; F-A-Bb-D) |
| 1. Umkehrung | 1st Inversion | `inversion-1` | 3rd auf dem Boden (rotiert um 1) |
| 2. Umkehrung | 2nd Inversion | `inversion-2` | 5th auf dem Boden (rotiert um 2) |
| 3. Umkehrung | 3rd Inversion | `inversion-3` | 7th auf dem Boden (rotiert um 3) |

### Core Game Loop (Basis v0.1–0.4) ✅
- ✅ Akkord-Generation (zufällig + 4 Progressions-Modi)
- ✅ Visuelle Klaviatur (2 Oktaven, responsive, Root-Markierung)
- ✅ Timer mit Millisekunden-Genauigkeit
- ✅ 3 Notations-Systeme (International, German, Symbole)
- ✅ 3 Schwierigkeitsgrade (Beginner, Intermediate, Advanced)
- ✅ Verify-Mode (Voicing erst nach Spielen zeigen)
- ✅ Mobile Support (Tap statt Space)
- ✅ Results-Screen mit allen Voicings + Mini-Keyboards

### MIDI (P1) ✅
- ✅ Web MIDI API Integration (Chrome/Edge Desktop)
- ✅ Device-Auswahl, Hot-Plug Support
- ✅ Echtzeit-Erkennung: Grün (richtig) / Rot (falsch) auf Klaviatur
- ✅ Auto-Advance bei korrektem Akkord (400ms Delay)
- ✅ Lenient Matching (Oktav-Toleranz, Extra-Noten erlaubt)
- ✅ Accuracy-Score pro Session

### Progressions (P2) ✅
- ✅ ii–V–I in allen 12 Keys (36 Akkorde)
- ✅ Quartenzirkel (12 Keys)
- ✅ I–vi–ii–V Turnaround (48 Akkorde)
- ✅ Random-Modus wie gehabt

### Progress Tracking (P3) ✅
- ✅ localStorage: Session-History (bis 100 Sessions)
- ✅ Settings-Persistenz (beim nächsten Öffnen = letzte Einstellungen)
- ✅ Dashboard auf Setup-Screen: Sessions, Akkorde, ⌀/Akkord
- ✅ Sparkline-Trend (letzte 10 Sessions)
- ✅ Bestzeiten pro Difficulty × Voicing × Modus

### Audio (P4) ✅
- ✅ Tone.js PolySynth (Triangle-Wave, Piano-ähnlich)
- ✅ Auto-Play bei jedem neuen Akkord
- ✅ "Anhören"-Button zum Nochmal-Hören
- ✅ Audio-Toggle (🔊/🔇) während des Spielens

### Metronom (P5) ✅
- ✅ BPM-konfigurierbarer Click (40–240 BPM, ±5)
- ✅ Akzent auf Beat 1, visueller Beat-Indicator (4 Dots)
- ✅ Start/Stop während der Session

### Design (P6) ✅
- ✅ Svelte Transitions (fade/fly/scale) zwischen Screens
- ✅ Dark Theme mit CSS Custom Properties
- ✅ **Multi-Theme-System** (Default + Open Studio)
- ✅ Responsive (Mobile → Desktop)

---

## 🎯 Guided Practice (v0.4) ✅

### Problem & Lösung
Der Setup-Screen hatte 10 Einstellungs-Dimensionen → Überforderung. Lösung: **Übungspläne** (One-Tap-to-Play) + Settings als Experten-Modus versteckt.

### Eingebaute Übungspläne ✅

| Name | Was es trainiert | Settings |
|------|-----------------|----------|
| **Warm-Up** | Einspielen, Grundlagen | Shell Voicings, ii-V-I, 12 Keys |
| **Speed Run** | Tempo | Root Position, Zufällig, Auf Zeit |
| **ii-V-I Deep Dive** | Jazz-Standard-Progression | Full Voicings, alle 12 Keys, Noten an |
| **Turnaround** | I-vi-ii-V | Shell Voicings, alle 12 Keys |
| **Challenge** | Erweitertes Vokabular | Advanced, Symbol-Notation, Noten aus |
| **Quartenzirkel** | Tonarten-Flüssigkeit | Half-Shell, ♭-Keys |
| **Voicing Drill** | Muscle Memory pro Griff-Typ | Root Position + ii-V-I, alle Keys |

### Streak-System ✅
- Tägliche Praxis-Streak (🔥 Tag X)
- Best-Streak Tracking
- Motivation: "7 Tage in Folge!" / "Starte neu!"

### MIDI Auto-Detection ✅
- MIDI wird beim App-Start automatisch geprüft
- Grüner Banner bei erkanntem Gerät: "🎹 [Gerätename] erkannt — MIDI ist aktiv"
- Dezenter Hinweis wenn kein Gerät da
- Hot-Plug: Klavier jederzeit anstecken → sofort erkannt

### Per-Chord Analyse ✅
- SessionResult speichert Millisekunden pro Akkord (ChordTiming[])
- Schwächste Akkorde identifiziert (langsamste Reaktionszeit pro Root)
- Verbesserungs-Trends: "Du wirst besser bei Db-Akkorden ↓ 25% schneller"
- Heatmap-Balken im Dashboard: größter Balken = langsamster Akkord

### Klare UX-Erklärungen ✅
- **Jede Setting-Option erklärt**, was sie macht (kein Fachjargon ohne Kontext)
- **Voicing-Arten** kurz & klar: "Shell = nur die wichtigsten 2-3 Töne (wie Jazz-Pianisten in Combos)"
- **Plan-Beschreibungen** sagen wer & warum, nicht nur was

---

## 📂 Projektstruktur

### Tech Stack
```
SvelteKit 2.52.0 (SSR, adapter-vercel)
├─ Svelte 5.51.2 (Runes-Syntax: $state, $derived, $props, $bindable)
├─ Tailwind CSS 4.1.18 (@tailwindcss/vite Plugin)
├─ Vite 6.4.1
├─ TypeScript 5.9.3
├─ Tone.js 15.1.22 (Audio Playback + Metronom)
├─ Web MIDI API (Chrome/Edge Desktop only)
└─ localStorage (Progress + Settings Persistenz)
```

### Code-Struktur
```
src/
├── lib/engine/               ← Pure TypeScript, kein DOM
│   ├── index.ts              (Re-exports)
│   ├── notes.ts              (Note-Arrays, Enharmonic)
│   ├── chords.ts             (14 Akkord-Typen, Difficulty-Pools)
│   ├── voicings.ts           (4 Voicing-Berechnungen)
│   ├── keyboard.ts           (Keyboard-Geometrie, 2 Oktaven)
│   └── progressions.ts       (ii-V-I, Quarterzirkel, I-vi-ii-V)
│   ├── plans.ts              (7 Übungspläne, suggestPlan-Logik)
│   └── custom-progressions.ts (Parser, Evaluator, Presets)
├── lib/utils/                ← Shared Utilities
│   └── format.ts             (formatTime für alle Screens)
├── lib/services/             ← Seiteneffekte, externe APIs
│   ├── midi.ts               (Web MIDI API Wrapper, Chord Matching)
│   ├── audio.ts              (Tone.js: Synth, Metronom, Playback)
│   ├── progress.ts           (localStorage: History, Streak)
│   └── theme.ts              (Theme-System, Switching)
├── lib/components/           ← Svelte 5 Components
│   ├── PianoKeyboard.svelte  (2-Oktaven, MIDI-Overlay, Voicing-Highlight)
│   ├── ChordCard.svelte      (Akkord-Display, keyboard-accessible)
│   ├── GameSettings.svelte   (Übungspläne, custom settings)
│   ├── Results.svelte        (Ergebnis-Screen + Mini-Keyboards)
│   ├── MidiStatus.svelte     (MIDI-Connection + Device-Picker)
│   ├── ProgressDashboard.svelte (Stats, Weak Chords, Trends)
│   ├── ProgressionEditor.svelte (Custom progression input)
│   ├── ProgressionPlayer.svelte (Loop player mit Evaluator)
│   └── ProgressionResults.svelte (Results für Custom Progressions)
├── routes/
│   ├── +layout.svelte        (CSS Import, min-h-dvh Wrapper)
│   └── +page.svelte          (Game Loop, ~620 Zeilen State Machine)
├── app.css                   (Tailwind + CSS Custom Properties)
└── app.html
```

---

## 📖 Konventionen

### Svelte 5 (strikt)
- **NUR Runes**: `$state`, `$derived`, `$props`, `$bindable`, `$effect`
- **Kein Legacy**: Kein `$:`, kein `<slot>`, kein `on:click`
- **Children**: `Snippet` + `{@render children()}`
- **Events**: Callback-Props (`onclick`, `onchange`)
- **TypeScript-Tipp**: `$state<UnionType>()` für Narrowing bei String Unions

### Tailwind 4
- Import via `@import 'tailwindcss'` in app.css
- **KRITISCH**: Unlayered CSS (`* { ... }`) überschreibt ALLE `@layer utilities` Klassen
- Custom Properties überall: `bg-[var(--primary)]`, `text-[var(--text-muted)]`
- Keine `tailwind.config.js` — alles über CSS Vars

### File-Naming
- Components: `PascalCase.svelte`
- Services: `camelCase.ts`
- Engine: `camelCase.ts` (pure functions, kein DOM)

---

## 📋 Change Log

### [v0.1.0] – 16. Feb 2026 – Initial MVP (Agent 1)
- Scaffolding: SvelteKit 2 + Svelte 5 + Tailwind 4
- Engine: Notes, Chords (14 Typen), Voicings (4), Keyboard
- Components: PianoKeyboard, ChordCard, GameSettings, Results
- Game Loop: Setup → Playing → Finished State Machine
- Mobile Support, Responsive Design

### [v0.2.0] – 16. Feb 2026 – MIDI + Progressions (Agent 2)
- MIDI Input: Web MIDI API, Device-Selection, Auto-Advance
- Chord Recognition: Lenient Matching, Accuracy Score
- Progressions: ii-V-I, Quartenzirkel, I-vi-ii-V (+ Random)
- MIDI Visual Feedback: Grün/Rot Keys auf Klaviatur
- Verify-Skip bei MIDI (Auto-Erkennung ersetzt manuelles Verify)
- Bug fixes: Tailwind 4 spacing, MIDI octave highlighting

### [v0.3.0] – 16. Feb 2026 – Audio + Progress + Polish (Agent 2)
- Tone.js Audio: Auto-Play, Anhören-Button, Toggle
- Metronom: BPM ±5, Beat-Indicator, Akzent auf Beat 1
- Progress: localStorage History, Dashboard, Sparkline, Bestzeiten
- Settings-Persistenz (localStorage)
- Svelte Transitions (fade/fly/scale)
- Bug fixes: $effect infinite loop, async audio fire-and-forget

### [v0.4.0] – 16. Feb 2026 – Guided Practice + Custom Progressions (Agent 2)
- Übungspläne: 7 kuratierte One-Tap-Presets (Warm-Up bis Voicing Drill)
- Streak-System (tägliche Motivation, Best-Streak)
- MIDI Auto-Detection (automatisch erkennen, Banner, Hot-Plug)
- Per-Chord Timing (ms pro Akkord in SessionResult)
- Schwachstellen-Analyse (langsamste Akkorde pro Root)
- Verbesserungs-Trends ("Du wirst besser bei X")
- UX-Redesign: Empfehlung statt Settings-Overload
- Klare Erklärungen: Jede Option sagt was sie tut
- **Custom Progressions**: Editor, Player, Evaluator, 7 Jazz-Presets

### [v0.5.0] – 17. Feb 2026 – Keyboard Fix + Theme System + Quality (Agent 3)
- **Audio/Keyboard Overhaul**: Nur Voicing-Noten highlighted, natürliche Register-Spreizung
- **6 neue Voicing-Typen**: Rootless A/B + Umkehrungen 1–3
- **Theme-System**: Default + Open Studio branding, Theme-Switcher in Nav
- **Bug Fixes**: CM7-Parsing, Sharp/Flat-Konsistenz, Hyphen-Support, MIDI re-registration, dim7-Handling
- **ChordCard A11y**: Tastatur-Navigation (role="button", keydown-Handler)
- **Code Quality**: `formatTime()` extrahiert → shared utility
- **Voicing-Label-Updates**: Deutsch für inversions
