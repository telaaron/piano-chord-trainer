# Chord Trainer – Agent Handoff

> **Letzte Bearbeitung:** 16. Februar 2026  
> **Commit:** `24ab02f` (initial commit)  
> **Repo:** `/Users/aaronpfutzner/Dateien - Local/chord-trainer/`  
> **Dev Server:** `pnpm dev` → http://localhost:5173 (oder 5174 wenn 5173 belegt)  
> **Origin-Projekt:** `/Users/aaronpfutzner/Dateien - Local/mustseen-bridge-engine/src/routes/chord-trainer/+page.svelte` (1173 Zeilen, Svelte 4)

---

## 1. Was ist das?

Ein **Jazz Piano Chord Trainer** – Speed-Training für Klavier-Voicings. Der Nutzer sieht zufällige Akkorde, spielt sie auf seinem Klavier, drückt Space/Tap und sieht seine Zeit. Ziel: Muscle Memory aufbauen, messbar schneller werden.

**Zielgruppe:** Jazz-Pianisten, Musikstudenten, potenziell B2B-Lizenz an [Open Studio](https://openstudiojazz.com) (Jazz-Education-Plattform, $47/mo × 1000+ Members).

**Status:** Funktionierendes MVP. Alle visuellen Features portiert aus dem Original. Noch kein MIDI, kein Audio, kein Progress Tracking.

---

## 2. Tech Stack

| Layer | Tech | Version (installiert) | Anmerkungen |
|-------|------|-----------------------|-------------|
| Framework | SvelteKit | 2.52.0 | Routing, SSR, adapter-vercel |
| UI | Svelte 5 | 5.51.2 | **Runes-Syntax** (`$state`, `$derived`, `$props`, `$bindable`) |
| CSS | Tailwind CSS 4 | 4.1.18 | `@import 'tailwindcss'` statt `@tailwind base/components/utilities` |
| CSS Integration | @tailwindcss/vite | 4.1.18 | Vite Plugin, nicht PostCSS |
| Build | Vite | 6.4.1 | — |
| Deploy | Vercel | adapter-vercel 5.10.3 | — |
| Audio (geplant) | Tone.js | 15.1.22 | Installiert, noch nicht verwendet |
| MIDI (geplant) | Web MIDI API | nativ | Kein Package nötig |
| Icons | lucide-svelte | 0.525.0 | Installiert, noch nicht verwendet |
| UI Primitives | bits-ui | 1.8.0 | Installiert, noch nicht verwendet |
| Utility | clsx + tailwind-merge | 2.1.1 / 2.6.1 | Installiert, noch nicht verwendet |

### Svelte 5 Runes – Wichtig!

Dieses Projekt nutzt **ausschließlich Svelte 5 Runes**. Kein `$:`, kein `on:click`, kein `<slot>`.

```svelte
// STATE
let count = $state(0);

// DERIVED
const doubled = $derived(count * 2);

// PROPS (in Components)
let { name, onclick }: Props = $props();
let { value = $bindable() }: Props = $props(); // Two-way binding

// EVENTS → Callback Props
// Statt on:click → onclick prop
<button onclick={handler}>

// CHILDREN (statt <slot>)
import type { Snippet } from 'svelte';
interface Props { children?: Snippet; }
{#if children}{@render children()}{/if}
```

### Tailwind 4 – Unterschiede zu v3

- **Import:** `@import 'tailwindcss'` (nicht `@tailwind base; @tailwind components; @tailwind utilities`)
- **Vite Plugin:** `@tailwindcss/vite` statt PostCSS-Plugin
- **Keine tailwind.config.js:** Theme wird über CSS Custom Properties definiert
- **Arbitrary Values:** `text-[var(--text-muted)]`, `bg-[var(--primary)]` überall verwendet

---

## 3. Dateistruktur

```
chord-trainer/
├── src/
│   ├── app.css              ← Design Tokens (CSS Custom Properties), Tailwind Import
│   ├── app.html             ← HTML Shell, Google Fonts (Inter)
│   ├── app.d.ts             ← SvelteKit Typen
│   ├── lib/
│   │   ├── engine/          ← Pure TypeScript, kein Svelte, kein DOM
│   │   │   ├── index.ts     ← Re-exports aller Engine-Module
│   │   │   ├── notes.ts     ← Noten-Arrays, Enharmonic Map, Konvertierung
│   │   │   ├── chords.ts    ← Chord-Typen, Intervalle, Notation-Styles, Difficulty
│   │   │   ├── voicings.ts  ← Voicing-Berechnung, ChordWithNotes Interface
│   │   │   └── keyboard.ts  ← Keyboard-Layout, aktive Keys berechnen, Root erkennen
│   │   └── components/
│   │       ├── PianoKeyboard.svelte  ← 2-Oktaven-Klaviatur (responsive)
│   │       ├── ChordCard.svelte      ← Akkord-Anzeige mit Gradient + Pulse
│   │       ├── GameSettings.svelte   ← Setup-Screen mit allen 7 Einstellungen
│   │       └── Results.svelte        ← Ergebnis-Screen mit Mini-Keyboards
│   └── routes/
│       ├── +layout.svelte   ← CSS Import + min-h-dvh Wrapper
│       └── +page.svelte     ← Game Loop (270 Zeilen), State Management
├── static/
│   └── favicon.svg          ← Lila ♪ Icon
├── package.json
├── svelte.config.js         ← adapter-vercel + vitePreprocess
├── vite.config.ts           ← tailwindcss() + sveltekit()
├── tsconfig.json            ← Strict mode, bundler resolution
└── .prettierrc              ← Tabs, Single Quotes, Svelte Parser
```

---

## 4. Engine-Architektur im Detail

### notes.ts – Das Fundament

Zwei Note-Arrays: `NOTES_SHARPS` (C, C#, D...) und `NOTES_FLATS` (C, Db, D...). Index = Semitone (0–11).

Die `ENHARMONIC_MAP` verbindet: `C# ↔ Db`, `D# ↔ Eb`, etc.

**Kritische Funktion:** `noteToSemitone(note)` — versucht nacheinander Sharps, Flats, Enharmonic. Gibt -1 zurück wenn nichts passt. Wird überall als Basis benutzt.

### chords.ts – Akkord-Definitionen

`CHORD_INTERVALS` definiert Semitone-Abstände vom Root:
- Maj7 = [0, 4, 7, 11] → Root, Major 3rd, Perfect 5th, Major 7th
- m7b5 = [0, 3, 6, 10] → Root, Minor 3rd, Diminished 5th, Minor 7th

`CHORD_NOTATIONS` mapped interne Keys auf 3 Display-Styles:
- standard: `Maj7`, `m7`, `m7b5`
- symbols: `Δ7`, `-7`, `ø7`
- short: `M7`, `mi7`, `mi7b5`

**Achtung:** `displayToQuality()` macht den Reverse-Lookup (Notation → interner Key). Wird beim Parsen des generierten Chord-Namens gebraucht.

### voicings.ts – Welche Töne man spielt

`getChordNotes(root, quality, pref)` → Array aller Noten des Akkords

`getVoicingNotes(allNotes, voicing)` → selektiert Subset:
- **Root:** Alle Noten [0,1,2,3]
- **Shell:** Root + 3rd + 7th [0,1,3] (Skip 5th)
- **Half-Shell:** 3rd + Root + 7th [1,0,3] (3rd als Bass)
- **Full:** Root + höchste + 3rd + 5th [0, last, 1, 2] (open spread)

### keyboard.ts – Die härteste Logik

**Problem:** Noten einem visuellen 2-Oktaven-Klavier zuordnen.

Keyboard hat 14 weiße Tasten (2×7) und 10 schwarze Tasten (2×5). Weiße Tasten haben chromatic indices `[0,2,4,5,7,9,11]` pro Oktave.

`BLACK_KEYS` sind als `{ idx: chromaticIndex, pos: whiteKeyPosition }` definiert:
- `{ idx: 1, pos: 1 }` = C# sitzt bei Position 1 (zwischen C=0 und D=2)
- Position wird via `left: {(pos * 100) / 14}%` + `-translate-x-1/2` positioniert

`getActiveKeyIndices()` baut die Highlight-Menge:
1. Root wird **immer in der ersten Oktave** platziert (Index 0–11)
2. Andere Voicing-Noten werden **oberhalb des Roots gestapelt** (wenn chromatischer Index ≤ Root → +12)
3. Duplikate und Enharmonische werden via `usedNames` Set verhindert

`isRootIndex()` prüft via `(chromaticIndex % 12) === rootSemitone` — das ist **bulletproof** für alle Notations-Kontexte.

---

## 5. Hard-Won Bug Knowledge

Diese Bugs haben zusammen ~3 Stunden gekostet. Nicht nochmal machen.

### Bug 1: Weiße Root-Noten nicht highlighted
**Symptom:** Schwarze Root-Tasten zeigten Primary-Farbe, weiße nicht.
**Ursache:** `class="bg-white {isActive ? 'bg-primary' : ''}"` — Tailwind: `bg-white` hatte gleiche Spezifität wie `bg-primary`, Reihenfolge im HTML gewann.
**Fix:** `bg-white` nur im else-Branch: `{isActive ? 'bg-primary' : 'bg-white'}`.

### Bug 2: isNoteRoot() versagte bei Natural Notes
**Symptom:** C-Root wurde auf dem Keyboard nicht als Root markiert, C# schon.
**Ursache:** String-Vergleich `keyboardNote === root` versagte wenn das Keyboard-Array Sharps hatte aber der Root als Flat angegeben war (oder umgekehrt).
**Fix:** Zusätzlich chromatic-index Vergleich: `(noteIndex % 12) === rootSemitone`. Bulletproof.

### Bug 3: Keyboard-Lücken zwischen Oktaven
**Symptom:** Sichtbare Lücke in der Mitte des Keyboards.
**Ursache:** 5 verschiedene Ansätze probiert (absolute px, calc-basiert, etc.). Problem war immer das Mischen von relativen und absoluten Einheiten.
**Fix:** 2-Layer-Ansatz. Weiße Tasten = `flex-1` in einem `flex` Container (keine Gaps möglich). Schwarze Tasten = absolut über dem Container mit `%`-Positionierung.

### Bug 4: `<slot>` deprecated in Svelte 5
**Symptom:** `css is not a function` Runtime-Error.
**Fix:** `<slot />` → `{@render children()}` mit `Snippet` Import.

### Bug 5: Chord Parsing für Flat-Noten
**Symptom:** `Bb7` wurde als Root=`B`, Type=`b7` geparst.
**Ursache:** Regex `/^([A-G][#b]?)(.+)$/` matcht `b` optional nach dem Buchstaben — bei `Bb7` matcht `B` als Root und `b7` als Type.
**Fix:** Das Regex funktioniert tatsächlich korrekt: `[#b]?` matched das `b`, also Root=`Bb`, Type=`7`. Das Problem war woanders — im Original fehlten Flat-Noten im `availableNotes` Array.

### Bug 6: Timer zählt nicht
**Symptom:** Timer blieb bei 0:00.00 stehen.
**Ursache:** In Svelte 4: `$: elapsed = Date.now() - startTime` wird nicht reaktiv getriggert weil `Date.now()` kein reactives Binding hat.
**Fix:** `setInterval(() => { now = Date.now() }, 100)` — `now` ist reactive, Timer wird alle 100ms aktualisiert.

---

## 6. Design System

Alles über CSS Custom Properties in `app.css`:

```
--bg: #0a0a0b          Dark background
--bg-card: #141416      Card background
--bg-muted: #1e1e23     Muted backgrounds (tags, inputs)
--border: #2a2a30       Default border
--text: #f0f0f2         Primary text
--text-muted: #8a8a95   Secondary text
--text-dim: #5a5a65     Tertiary text
--primary: #7c5cfc      Lila (Buttons, Active Keys, Highlights)
--accent-purple: #a855f7 Aktive schwarze Tasten
--accent-green: #22c55e  (noch unbenutzt, für Correct)
--accent-red: #ef4444    (noch unbenutzt, für Incorrect)
--key-white: #f8f8f8     Weiße Tasten
```

Utility-Klassen: `.card` (bg + border + radius), `.text-gradient` (primary → purple Gradient).

**Kein Light Mode.** Dark ist Default und einziger Modus (Musiker-Standard).

---

## 7. Game-Loop Architektur

```
┌─────────┐   startGame()   ┌─────────┐   nextChord()   ┌──────────┐
│  SETUP  │ ───────────────> │ PLAYING │ ───────────────> │ FINISHED │
│         │                  │         │ (nach letztem)   │          │
│ Settings│                  │ Timer ⏱ │                  │ Results  │
│ Start ▶ │                  │ Space/↓ │                  │ 🔄 / ⚙️  │
└─────────┘                  └────┬────┘                  └──────────┘
                                  │
                        Verify Mode?
                       ┌──────────┴──────────┐
                       │ playPhase: 'playing' │
                       │ → Space = show notes │
                       │ playPhase: 'verifying'│
                       │ → Space = next chord │
                       └──────────────────────┘
```

State lebt in `+page.svelte`. Settings werden via `bind:` an `GameSettings` durchgereicht. Events kommen als Callback Props (`onstart`, `onrestart`, `onreset`).

---

## 8. Was noch zu tun ist (Priorität)

### 🔴 P1: MIDI Input + Chord Recognition (Pitch-Blocker)
- Web MIDI API in `$lib/services/midi.ts`
- `navigator.requestMIDIAccess()` → Input Device auswählen
- MIDI Note On/Off Events → aktive Noten tracken
- Vergleich aktive MIDI-Noten vs. erwartete Voicing-Noten
- Toleranzen: Oktavlagen akzeptieren, Inversions partiell
- Visuelles Feedback: Grün (richtig) / Rot (falsch)
- Auto-Advance nach korrektem Chord
- Accuracy Score pro Session

### 🔴 P2: 2-5-1 Progression Mode
- Nicht nur Random Chords, sondern: `Dm7 → G7 → CMaj7` in allen 12 Keys
- Modus-Toggle: "Random" / "2-5-1" / "Cycle of 4ths"
- Jazz-Standard-Drill: universelle Übung
- Erweiterbar: 1-6-2-5, Blues Changes, Rhythm Changes

### 🔴 P3: Progress Tracking
- `localStorage` zunächst (Supabase später)
- Bestzeiten pro Difficulty + Voicing-Typ speichern
- History: Array von Sessions mit Timestamp, Settings, Ergebnis
- Dashboard/Chart auf Setup-Screen: "Dein Trend"
- Accuracy-Rate (braucht MIDI)

### 🟡 P4: Audio Playback
- Tone.js ist installiert (`tone@15.1.22`), noch unbenutzt
- Piano Samples laden (Tone.js Sampler)
- Chord abspielen bei Anzeige oder on-demand
- Verschiedene Sounds: Piano, Rhodes

### 🟡 P5: Metronom
- Click-Track mit einstellbarem BPM
- "Play chord on beat 1" Modus
- Tempo-Stufen: 60 → 80 → 100 → 120 BPM
- Swing-Feel Option

### 🟡 P6: Design Polish
- Transitions/Animations (Svelte transitions: `fly`, `fade`, `scale`)
- Touch-Targets vergrößern für Mobile
- Accordion-Animations für Settings
- Keyboard hover/press States

### 🟢 P7: Advanced Features
- Ear Training Mode (Chord hören → identifizieren)
- Custom Voicing Sets (Bill Evans Rootless A/B)
- Gamification (Streaks, Achievements, Levels)
- Voice Leading Awareness (Common Tones hervorheben)
- Song-basierte Übungen (Autumn Leaves, All The Things You Are)
- Targeted Drills (Schwächen-basiert: langsamste Chords mehr üben)

---

## 9. Bekannte Einschränkungen

1. **bits-ui, lucide-svelte, clsx, tailwind-merge** sind installiert aber **unbenutzt**. Wurden für spätere UI-Komponenten eingeplant. Können jederzeit eingebunden werden.

2. **Tone.js** ist installiert aber **unbenutzt**. Für Audio Playback vorgesehen.

3. **Kein ESLint-Config.** `eslint` ist installiert, aber keine `eslint.config.js` existiert. Bei Bedarf mit `@eslint/js` + `typescript-eslint` + `eslint-plugin-svelte` konfigurieren.

4. **Kein Test.** `vitest` ist installiert, `vitest.config.ts` fehlt aber noch. Die Engine-Module (`notes.ts`, `chords.ts`, `voicings.ts`, `keyboard.ts`) sind pure Funktionen und ideal testbar.

5. **Settings nicht persistent.** Alle Settings resetten bei Page Reload. localStorage-Persistierung ist trivial (JSON.stringify/parse in onMount).

6. **Vite-Plugin-Svelte Peer Warning.** `@sveltejs/vite-plugin-svelte@5.1.1` hat bekannte Peer-Dep-Warnung mit Vite 6 – funktioniert aber fehlerfrei.

7. **SSR funktioniert**, aber die App ist rein client-seitig. Kein Server-State, keine API-Routes.

---

## 10. Kontext: Herkunft und Strategie

### Herkunft
Dieses Repo wurde aus einem Proof-of-Concept extrahiert, der als Unterseite von **MustSeen Bridge Engine** (Reiseplattform mit Flugsuche/Stripe/Supabase) gebaut wurde. Das Original war ein 1173-Zeilen Single-File-Component in Svelte 4.

Die Extraktion in ein eigenständiges Repo mit Svelte 5 + Tailwind 4 war ein bewusster Entscheid: sauberer Tech Stack, keine Altlasten, klar definierter Scope.

### Original-Datei (Referenz)
`/Users/aaronpfutzner/Dateien - Local/mustseen-bridge-engine/src/routes/chord-trainer/+page.svelte`

Dort liegt noch das alte Svelte-4-Original. Das neue Repo ist die **kanonische Version** – das Original wird nicht weiterentwickelt.

### Strategie-Dokument
`/Users/aaronpfutzner/Dateien - Local/mustseen-bridge-engine/docs/planning/chord-trainer-project.md`

Enthält: vollständige Feature-Liste, ehrliche Stärken/Schwächen-Bewertung, externe Einschätzung (Gemini 3 Pro), Pitch-Strategie für Open Studio (Hormozi-Style Offer), Prioritäts-Tabelle mit Zeitschätzungen.

**Kernaussage aus externer Bewertung:** "Ja, kontaktiere Open Studio – aber warte 5 Tage und baue erst MIDI-Recognition + 2-5-1-Progressions."

### Pitch-Ziel: Open Studio
- Jazz-Education-Platform, $47/mo, 1000+ Members
- Sagen selbst "Take it through all 12 keys" → genau unser Tool
- Haben GPS, Living Notation, Ear Training – aber **kein Speed-Drill-Tool**
- Angebot: White-Label Integration, Free Trial, dann Lizenz/Rev-Share

---

## 11. Quickstart für neuen Agent

```bash
cd "/Users/aaronpfutzner/Dateien - Local/chord-trainer"
pnpm install    # Falls node_modules fehlt
pnpm dev        # → http://localhost:5173
```

### Erste sinnvolle Aktion: MIDI Service

```typescript
// src/lib/services/midi.ts
export class MidiService {
  private access: MIDIAccess | null = null;
  private activeNotes = new Set<number>(); // MIDI note numbers (0-127)
  
  async init(): Promise<boolean> {
    if (!navigator.requestMIDIAccess) return false;
    this.access = await navigator.requestMIDIAccess();
    // ... inputs listener setup
  }
  
  // Compare active MIDI notes against expected chord notes
  checkChord(expected: Set<number>): { correct: boolean; missing: number[]; extra: number[] } {
    // ...
  }
}
```

### Repo-Konventionen
- **Tabs** für Indentation (nicht Spaces)
- **Single Quotes** in TypeScript/Svelte
- **Trailing Commas** überall
- **Deutsche UI-Texte** (Zielgruppe: deutschsprachige Musiker, aber International-ready)
- **CSS Custom Properties** für alle Farben (kein hardcoded hex in Components)
- **Engine = Pure Functions** (kein DOM, kein Svelte-Import)
- **Components = Svelte 5 Runes** (kein `$:`, kein `on:`, kein `<slot>`)
