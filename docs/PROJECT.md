# Chord Trainer – Projekt-Übersicht & Roadmap

**Projekt:** Chord Trainer (Standalone Repo)  
**Status:** MVP funktionsfähig  
**Erstellt:** 16. Februar 2026  
**Aktuell:** Handoff-Phase  
**Autor:** Agent 1  

---

## 📋 Projekt-Zusammenfassung

Ein **Jazz Piano Chord Trainer** für Musikstudenten und Profis. Zufällige Akkorde anzeigen lassen, auf dem Klavier spielen, Zeit messen, schneller werden. Ziel: Muscle Memory + Messbarkeit.

**Business Context:**
- Zielgruppe: Jazz-Pianisten (B2C) + [Open Studio](https://openstudiojazz.com) (B2B-Lizenz, $47/mo × 1000+ Members)
- Pitch-Timeline: 5 Tage (bis MIDI + 2-5-1 + Progress fertig)
- Status: Visuelles MVP fertig, MIDI folgt

---

## ✅ Aktueller Stand

### Was funktioniert
- ✅ Akkord-Generation (zufällig aus Difficulty-Pool)
- ✅ Visuelle Klaviatur (2 Oktaven, responsive, Root-Markierung)
- ✅ Alle 4 Voicing-Typen (Root, Shell, Half-Shell, Full)
- ✅ Swing-Timer mit Millisekunden-Genauigkeit
- ✅ 3 Notations-Systeme (International, German, Symbole)
- ✅ 3 Density-Level (Easy/Medium/Hard)
- ✅ Verify-Mode (Space: zeige Voicing → Space: nächster Akkord)
- ✅ Mobile Support (Tap statt Space)
- ✅ Results-Screen mit Mini-Keyboards
- ✅ Responsive Design (Mobile/Tablet/Desktop)
- ✅ Settings-Screen (7 Dimensionen konfigurierbar)
- ✅ Dev-Setup (pnpm, Vite, SSR funktioniert)

### Was noch nicht gebaut ist
- ❌ MIDI Input (kein Akkord-Erkennung)
- ❌ 2-5-1 Progression-Modus
- ❌ Progress Tracking (localStorage/Supabase)
- ❌ Audio Playback (Tone.js installiert aber ungenutzt)
- ❌ Metronom/Click-Track
- ❌ Ear Training
- ❌ Gamification + Achievements
- ❌ Supabase Integration
- ❌ Vercel Deployment getestet
- ❌ Performance Monitoring
- ❌ Testing (vitest nicht konfiguriert)

---

## 🎯 Prioritäts-Roadmap

### 🔴 BLOCKER (P1) – Vor Open Studio Pitch
Ohne diese 3 Features = kein Pitch möglich.

#### P1.1: MIDI Input + Chord Recognition (2–3 Tage)
- **Beschreibung:** Web MIDI API integrieren, Noten tracken, gegen erwartete Voicing vergleichen
- **Abhängigkeit:** Keine
- **Files zu erstellen:**
  - `src/lib/services/midi.ts` (MIDI-Service: init, listen, note tracking)
  - `src/routes/+page.svelte` anpassen (MIDI-State integrieren)
  - Optional: `src/lib/components/MidiStatus.svelte` (Status-Anzeige)
- **Acceptance Criteria:**
  - Spieler kann MIDI-Device auswählen
  - Noten-On/Off werden erkannt
  - Visuelles Feedback: Grün (richtig) / Rot (falsch)
  - Auto-Advance nach korrektem Chord
  - Accuracy-Score wird berechnet
- **Test-Plan:**
  - Mit realem Klavier testen (oder MIDI-Simulator auf Mac)
  - 10 Chords spielen, Speed & Accuracy prüfen
- **Notes:**
  - Oktav-Toleranzen erlauben (Cm7 mit C-Oktave daneben = akzeptabel)
  - Inversions-Toleranz: 80% Noten richtig = "correct"
  - False positives minimieren (Umgebungslärm ignorieren)

#### P1.2: 2-5-1 Progression Mode (1 Tag)
- **Beschreibung:** Nicht nur Random Chords, sondern: Dm7 → G7 → CMaj7 (in allen 12 Keys)
- **Abhängigkeit:** MIDI sollte vor diesem Feature da sein (Zweiteiliger Pitch sonst leerer)
- **Files zu ändern:**
  - `src/lib/engine/chords.ts` (Progressions-Daten hinzufügen)
  - `src/routes/+page.svelte` (Modus-Toggle, generateChords() erweitern)
  - `src/lib/components/GameSettings.svelte` (Mode RadioButton)
- **Akzeptanz:**
  - "Random" Mode funktioniert wie jetzt
  - "2-5-1" Mode zeigt 2-5-1 Progression nacheinander in 12 Keys (36 Akkorde)
  - Optional: "Cycle of 5ths" für zusätzliche Drill-Möglichkeiten
- **Notes:**
  - 2-5-1 = Jazz Standard für Improvisation Üben
  - C Quartersystem: Dm7 → G7 → CMaj7 in C, dann to → Em7 → A7 → DMaj7 in D, etc.

#### P1.3: Progress Tracking (0.5–1 Tage)
- **Beschreibung:** Gespielte Sessions speichern, Best-Times nach Schwierigkeit/Voicing anzeigen
- **Abhängigkeit:** MIDI sollte fertig sein (für Accuracy-Tracking nötig)
- **Files zu erstellen:**
  - `src/lib/services/storage.ts` (localStorage API, Session-Schema)
  - `src/routes/+page.svelte` anpassen (Sessions speichern nach endGame)
  - `src/lib/components/ProgressChart.svelte` (Trend-Visualisierung)
- **Schema:**
  ```typescript
  interface Session {
    timestamp: number;
    difficulty: 'easy' | 'medium' | 'hard';
    voicing: 'root' | 'shell' | 'half-shell' | 'full';
    totalTime: number; // ms
    noteCount: number;
    accuracy: number; // 0–100, braucht MIDI
    chords: string[];
  }
  ```
- **Akzeptanz:**
  - Sessions werden persistent gespeichert
  - Setup-Screen zeigt Trend-Chart (letzte 10 Sessions)
  - Best-Time pro Kombination (Difficulty × Voicing) sichtbar
  - "Clear History" Button als Option
- **Notes:**
  - Supabase kommt später (Phase 2)
  - Für MVP: localStorage reicht

---

### 🟡 IMPORTANT (P2–P5) – 1–2 Wochen nach MVP-Pitch

#### P2: Audio Playback (1 Tag)
- **Beschreibung:** Tone.js benutzen um Akkorde abzuspielen
- **Files:** `src/lib/services/audio.ts` (Piano Sampler laden und spielen)
- **Möglichkeiten:**
  - Chord abspielen bei Anzeige (Auto-Play)
  - Button: "Play Chord"
  - Sound-Optionen: Piano, Rhodes, Synth
- **Notes:** Tone.js ist schon installiert, nur nicht genutzt

#### P3: Metronom/Click-Track (1 Tag)
- **Beschreibung:** Click-Track mit BPM, optional Swing
- **Files:** `src/lib/services/metronom.ts`
- **Features:**
  - BPM Selector (60 → 80 → 100 → 120)
  - Visual Click Indicator
  - Optional: "Play on 1" Modus
  - Swing-Feel Toggle

#### P4: Design Polish & Transitions (1 Tag)
- **Beschreibung:** Svelte transitions, Hover-States, Mobile Touch-Targets
- **Changes:**
  - `<button transition:scale>` bei Setup-Screen
  - `<div transition:fly>` bei Accordion-Open
  - Card Hover-Effekte
  - Touch-Target Mindestgröße (48px)

#### P5: Ear Training Mode (2–3 Tage)
- **Beschreibung:** Chord hören lassen und Spieler muss ihn identifizieren
- **Files:** New Mode in Game-State
- **Varianten:**
  - "Identify Voicing" (Akkord hören, Button drücken welcher Voicing)
  - "Identify Chord Type" (Maj7 oder m7 oder m7b5?)
  - "Blind Play" (nur Sound, müssen am Piano tasten)

---

### 🟢 NICE-TO-HAVE (P6–P7+) – Später oder optional

#### P6: Gamification
- Streaks (Tage hintereinander trainiert)
- Achievements (u ≥100 Akkorde gespielt, unter 2 Sekunden durchschnitt, etc.)
- Levels basierend auf Accuracy + Speed
- Leaderboard (lokal oder Supabase)

#### P7: Advanced Features
- Voice Leading Awareness (Common Tones hervorheben)
- Targeted Drills (Schwächste Akkorde vermehrt üben)
- Song-basierte Übungen (Autumn Leaves, All The Things You Are)
- Rootless Voicings (Bill Evans Style A/B)
- Custom Voicing-Sets (User-definierte Subsets)

#### P8+: Infrastructure
- Supabase Backend (User-Accounts, Cloud Sync)
- Analytics (Welche Akkorde sind am schwierigsten?)
- Public Leaderboard
- Export als PDF (Übungs-Zertifikat)
- Teacher Dashboard (Klassenzimmer-Modus)

---

## 📂 Projektstruktur

### Tech Stack (aktuell)
```
SvelteKit 2.52.0 (SSR, adapter-vercel)
├─ Svelte 5.51.2 (Runes-Syntax)
├─ Tailwind CSS 4.1.18 (CSS Custom Properties)
├─ Vite 6.4.1
├─ TypeScript 5.9.3
├─ Tone.js 15.1.22 (Audio, noch nicht genutzt)
├─ Web MIDI API (native, kein Package nötig)
└─ [Andere: bits-ui, lucide-svelte, clsx – installiert aber ungenutzt]
```

### Code-Struktur
```
src/
├── lib/engine/           ← Pure TypeScript, kein DOM
│   ├── index.ts (Re-exports)
│   ├── notes.ts (Note-Arrays, Enharmonic)
│   ├── chords.ts (Akkord-Definitions)
│   ├── voicings.ts (Voicing-Calculation)
│   └── keyboard.ts (Keyboard-Geometrie)
├── lib/components/       ← Svelte 5 Components
│   ├── PianoKeyboard.svelte (2-Oktaven-Keyboards mit Root-Dots)
│   ├── ChordCard.svelte (Akkord-Display mit Gradient)
│   ├── GameSettings.svelte (Setup-Screen)
│   └── Results.svelte (Ergebnis-Screen)
├── lib/services/         ← (WIP: MIDI, Audio, Storage)
├── routes/
│   ├── +layout.svelte (CSS Import, Wrapper)
│   └── +page.svelte (Game Loop, State Management)
├── app.css (Tailwind Import, CSS Custom Properties)
└── app.html (HTML-Shell)
```

### Engine Functions (kritisch)
- `noteToSemitone(note)` → Noten zu Semitone-Index konvertieren
- `getChordNotes(root, quality, pref)` → Array aller Noten eines Akkords
- `getVoicingNotes(allNotes, voicing)` → Subset auswählen (Root/Shell/etc.)
- `getActiveKeyIndices(chord)` → Set welcher Keyboard-Tasten zu highlighten
- `isRootIndex(chromaticIdx, rootSemitone)` → Ist diese Taste der Root?

---

## 🐛 Known Bugs (FIXED) – damit noch nicht beschäftigen

1. ~~Weiße Root-Tasten nicht highlighted~~ → Fix: Conditional class statt Specificity
2. ~~isNoteRoot() bei Natural Notes~~ → Fix: (noteIndex % 12) === rootSemitone
3. ~~Keyboard-Lücken zwischen Oktaven~~ → Fix: 2-Layer Approach (flex + absolute)
4. ~~`<slot>` deprecated in Svelte 5~~ → Fix: `{@render children()}` + Snippet
5. ~~Timer zählt nicht~~ → Fix: `setInterval(() => { now = Date.now() }, 100)`
6. ~~vite-plugin-svelte 4 ↔ vite 6 Inkompatibilität~~ → Fix: Upgrade zu v5.1.1

**Wichtig:** Wenn neue Komponenten gebaut werden, diese Patterns beachten:
- Immer TS/JS mit `$props()` bei Eingaben
- Children via `Snippet` + `{@render}`
- Events als Callback-Props (z.B. `onclick`, `onchange`)
- Kein `<slot>`, kein `on:click`, kein `$:`

---

## 🚀 Development Workflow

```bash
# Setup (erste Ausführung)
pnpm install

# Dev Server starten (mit HMR)
pnpm dev

# Build für Production
pnpm build

# Typecheck
pnpm check

# Code Formatting
pnpm format

# Linting (nicht konfiguriert, TBD)
pnpm lint
```

### Environment-Variablen
Aktuell: Keine. Später für Supabase:
- `VITE_SUPABASE_URL=...`
- `VITE_SUPABASE_ANON_KEY=...`

### Deployment
- `adapter-vercel` ist bereits konfiguriert
- `pnpm build` + `vercel deploy` reicht

---

## 📖 Konventionen

### Svelte 5 Runes (ausschließlich)
```svelte
<script>
  // STATE
  let chords = $state([]);
  
  // DERIVED
  const count = $derived(chords.length);
  
  // PROPS
  let { name, onclick }: Props = $props();
  let { value = $bindable() }: Props = $props();
  
  // EVENTS → Callback Props (nicht on:click)
  <button {onclick}>Play</button>
</script>

<!-- CHILDREN via Snippet ${1:
import type { Snippet } from 'svelte';
interface Props { children?: Snippet; }
{#if children}{@render children()}{/if}
-->
```

### Tailwind 4 Klassen + CSS Custom Properties
```html
<!-- Keine tailwind.config.js, alles über CSS Vars -->
<div class="bg-[var(--bg)] text-[var(--text)] rounded-[var(--radius-md)]">
  <!-- oder Kurzform mit vordefinierten Klassen -->
  <button class="px-4 py-2 rounded bg-primary text-white">
```

### File-Naming
- Components: `PascalCase.svelte` (z.B. `PianoKeyboard.svelte`)
- Services: `camelCase.ts` (z.B. `midi.ts`, `audio.ts`)
- Types: `interfaces.ts` oder inline in Datei mit Präfix `interface Name`
- Routes: `+page.svelte`, `+layout.svelte`, `+server.ts`

---

## 🎓 Musik-Theorie (für Nicht-Musiker)

### Chromatic Scale (12 Semitone)
```
C → C# → D → D# → E → F → F# → G → G# → A → A# → B → (repeat)
0    1   2   3   4   5   6   7   8   9  10  11
```

**Enharmonic Equivalents:** C# = Db, D# = Eb, usw. (selbe Tonhöhe, andere Notation)

### Chord Types (14 implementiert)
```
Maj7   = 1-3-5-7     (Root, Major 3rd, Perfect 5th, Major 7th)
m7     = 1-b3-5-b7   (Root, Minor 3rd, Perfect 5th, Minor 7th)
m7b5   = 1-b3-b5-b7  (Root, Minor 3rd, Diminished 5th, Minor 7th)
7      = 1-3-5-b7
6      = 1-3-5-6
m6     = 1-b3-5-6
usw.
```

### Voicing = Welche Noten in welcher Oktave
```
Root          = [1, 3, 5, 7]        (alle Noten)
Shell         = [1, 3, 7]           (weglassen 5th)
Half-Shell    = [3, 1, 7]           (3rd als Bass)
Full          = [1, high-note, 3, 5] (open spread oben)
```

### Jazz Standard: 2-5-1 Progression
```
In C:  Dm7 → G7 → CMaj7
In D:  Em7 → A7 → DMaj7
In E:  F#m7 → B7 → EMaj7
... (12 Keys durchzyklieren)

Das ist die **Progression**, die in 90% aller Jazz-Songs vorkommt.
```

Siehe `docs/MUSIC_THEORY.md` für Details.

---

## 🤝 Handoff für nächste Agent

### Was du sofort tun solltest
1. Lese `docs/AGENT_HANDOFF.md` komplett durch
2. Lese `docs/DECISIONS.md` (warum welche Tech gewählt wurde)
3. Laufe `pnpm dev` um den App zu starten
4. Öffne http://localhost:5174 und spieler herum (probiere alle Settings)

### Für P1: MIDI Integration
1. Erstelle `src/lib/services/midi.ts`
2. Benutze `navigator.requestMIDIAccess()` (Web MIDI API)
3. Trackiere aktive Noten in `+page.svelte` State
4. Vergleich mit `getVoicingNotes()` aus Engine
5. Visuelles Feedback + Score-Berechnung
6. Teste mit realem Klavier oder MIDI-Simulator

### Für P2: 2-5-1 Progressions
1. Erweitere ChordGenerator um Progression-Daten
2. Toggle in GameSettings hinzufügen
3. Backend-Logik in generateChords()
4. Play testen bis zum 36. Akkord

### Für P3: Progress Tracking
1. localStorage Service schreiben (Session-Schema)
2. Nach endGame() Sessions speichern
3. ProgressChart Component für Trend-Visualisierung
4. Best-Times pro Setting-Kombination anzeigen

### Fragen? Siehe:
- Technische Details → `docs/AGENT_HANDOFF.md`
- Warum-Entscheidungen → `docs/DECISIONS.md`
- Musik-Theorie → `docs/MUSIC_THEORY.md`
- Code-Lesen → `src/lib/engine/` und `src/routes/+page.svelte`

---

## 📋 Change Log

### [v0.1.0] – Initial MVP – 16. Feb 2026
- ✨ MVP Scaffolding mit SvelteKit 2 + Svelte 5 + Tailwind 4
- ✨ Engine-Module (Notes, Chords, Voicings, Keyboard)
- ✨ 4 Svelte Components (PianoKeyboard, ChordCard, GameSettings, Results)
- ✨ Vollständiger Game Loop mit State Machine (Setup → Playing → Finished)
- ✨ Responsive Keyboard mit Root-Dots
- ✨ Timer mit Millisekunden-Genauigkeit
- ✨ Verify-Mode (Space-Doppelklick)
- ✨ Settings (Difficulty, Notation, Voicing, etc.)
- ✨ Mobile Support
- 🐛 Bugs gefunden und dokumentiert (6 × Hard-Won Knowledge)
- 📚 Umfangreiche Dokumentation (AGENT_HANDOFF, DECISIONS, MUSIC_THEORY)

### [v0.2.0] – MIDI Integration (TBD)
- MIDI Input-Device Selection
- Chord Recognition
- Accuracy Scoring
- Visual Feedback (Green/Red)

### [v0.3.0] – 2-5-1 Mode (TBD)
- Progressions-Modus
- Key Cycling
- Jazz-Standard Drill

### [v0.4.0] – Progress Tracking (TBD)
- localStorage Sessions
- Best-Times Tracking
- Trend Chart

---

## ✉️ Kontakt & Support

**Fragen zur Architektur?** → Lese `docs/AGENT_HANDOFF.md` Section 4–7  
**Fragen zur Tech-Wahl?** → Lese `docs/DECISIONS.md`  
**Fragen zur Musik?** → Lese `docs/MUSIC_THEORY.md`  
**Fragen zum Code?** → Siehe Inline-Comments in `src/`  

---

**Viel Erfolg beim Bauen! 🎹**
