# Chord Trainer – Architektur

> Technische Referenz für Entwickler. Was wo lebt, wie Daten fließen, und warum.

---

## Überblick

```
┌─────────────────────────────────────────────────────────────┐
│                        Browser                              │
│                                                             │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │   Routes     │    │  Components  │    │   Services    │  │
│  │  (Svelte)    │───▸│  (Svelte 5)  │───▸│  (TypeScript) │  │
│  │              │    │              │    │               │  │
│  │ +page.svelte │    │ ChordCard    │    │ audio.ts      │  │
│  │ /train       │    │ Keyboard     │    │ midi.ts       │  │
│  │ /for-edu     │    │ Settings     │    │ progress.ts   │  │
│  │ /open-studio │    │ Results      │    │ theme.ts      │  │
│  └──────┬───────┘    └──────┬───────┘    └───────┬───────┘  │
│         │                   │                    │          │
│         └───────────────────┼────────────────────┘          │
│                             │                               │
│                    ┌────────▼────────┐                      │
│                    │     Engine      │                      │
│                    │  (Pure TS)      │                      │
│                    │                 │                      │
│                    │ notes.ts        │                      │
│                    │ chords.ts       │                      │
│                    │ voicings.ts     │                      │
│                    │ keyboard.ts     │                      │
│                    │ progressions.ts │                      │
│                    │ plans.ts        │                      │
│                    │ custom-prog.ts  │                      │
│                    └────────┬────────┘                      │
│                             │                               │
│                    ┌────────▼────────┐                      │
│                    │   localStorage  │                      │
│                    │   (Persistenz)  │                      │
│                    └─────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

### Schichten

| Schicht | Verzeichnis | Verantwortung | Darf importieren von |
|---------|------------|---------------|---------------------|
| **Engine** | `src/lib/engine/` | Musiktheorie, Berechnung, pure Funktionen | Nichts (standalone) |
| **Services** | `src/lib/services/` | Browser-APIs, Seiteneffekte | Engine |
| **Components** | `src/lib/components/` | UI-Darstellung, User Interaction | Engine, Services |
| **Routes** | `src/routes/` | Seiten, State Machine, Orchestrierung | Engine, Services, Components |
| **Utils** | `src/lib/utils/` | Shared Hilfsfunktionen | Nichts |

**Regel:** Engine importiert nie Services oder Components. Services importieren nie Components. Diese Richtung ist strikt.

---

## Engine (`src/lib/engine/`)

Pure TypeScript ohne DOM-Abhängigkeiten. Theoretisch in jedes Framework portierbar.

### notes.ts

Grundlage für alles. Definiert die chromatische Skala in zwei Varianten:

```
NOTES_SHARPS = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
NOTES_FLATS  = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B']
```

- `noteToSemitone(note)` — Universaler Lookup: Sharps → Flats → Enharmonic Map → -1
- `getNotePool(pref)` — Gibt das richtige Array zurück (sharps/flats/both)
- `convertNoteName(note, system)` — B→H, Bb→B für deutsche Notation
- **Index = Semitone** — C=0, C#/Db=1, ... B=11

### chords.ts

Definiert 16 Akkord-Typen als Semitone-Intervalle vom Root:

```typescript
CHORD_INTERVALS = {
  'Maj7':    [0, 4, 7, 11],    // C E G B
  '7':       [0, 4, 7, 10],    // C E G Bb     (Dominant)
  'm7':      [0, 3, 7, 10],    // C Eb G Bb
  'm7b5':    [0, 3, 6, 10],    // C Eb Gb Bb   (Half-diminished)
  'dim7':    [0, 3, 6, 9],     // C Eb Gb A    (Full diminished)
  '6':       [0, 4, 7, 9],     // C E G A
  // ... + m6, Maj9, 9, m9, 6/9, Maj7#11, 7#9, 7b9, m11, 13
}
```

Weitere Exports:
- `CHORDS_BY_DIFFICULTY` — Pools pro Level (beginner: 5, intermediate: 9, advanced: 14)
- `CHORD_NOTATIONS` — 3 Display-Systeme (standard/symbols/short) pro Chord
- `VoicingType` — Union von 9 Voicing-Keys
- `displayToQuality()` — Reverse-Lookup: Notation → interner Key

### voicings.ts

Berechnet die tatsächlich gespielten Noten für einen Akkord:

```typescript
getChordNotes(root: string, quality: string): string[]
// → Alle Noten in Root Position

getVoicingNotes(allNotes: string[], voicingType: VoicingType): string[]
// → Subset/Rearrangement nach Voicing-Typ
```

**9 Voicing-Typen:**

| Typ | Indizes | Beispiel (CMaj7: C-E-G-B) | Verwendet für |
|-----|---------|--------------------------|---------------|
| `root` | [0,1,2,3] | C-E-G-B | Grundlagen |
| `shell` | [0,1,3] | C-E-B | Jazz-Combo (R+3+7) |
| `half-shell` | [1,0,3] | E-C-B | Voice Leading |
| `full` | [0,last,1,2] | C-B-E-G | Open Spread |
| `rootless-a` | 3-5-7-9 | E-G-B-D' | Bill Evans Style |
| `rootless-b` | 7-9-3-5 | B-D'-E-G | Komplementär zu A |
| `inversion-1` | Rotation um 1 | E-G-B-C' | 3rd im Bass |
| `inversion-2` | Rotation um 2 | G-B-C'-E' | 5th im Bass |
| `inversion-3` | Rotation um 3 | B-C'-E'-G' | 7th im Bass |

### keyboard.ts

Bildet Voicing-Noten auf eine 2-Oktaven-Klaviatur (C3–B4) ab:

- 14 weiße Tasten, 10 schwarze Tasten, 24 chromatische Positionen
- `getActiveKeyIndices()` — berechnet welche Tasten leuchten
- Root wird immer in Oktave 1 platziert, andere Noten darüber gestapelt
- `isRootIndex()` — `(chrIdx % 12) === rootSemitone` (enharmonic-safe)

### progressions.ts

Generiert Akkord-Sequenzen für 4 Modi:

| Modus | Akkorde pro Durchlauf | Logik |
|-------|----------------------|-------|
| `random` | N (eingestellt) | Zufällig aus Difficulty-Pool |
| `2-5-1` | 36 (3 × 12 Keys) | ii-V-I durch Quartenzirkel |
| `cycle-of-4ths` | 12 | Ein Akkord-Typ durch alle Keys |
| `1-6-2-5` | 48 (4 × 12 Keys) | I-vi-ii-V Turnaround |

### plans.ts

9 kuratierte Übungspläne mit voreingestellten Settings:

```typescript
interface PracticePlan {
  id: string;
  name: string;
  tagline: string;
  description: string;
  icon: string;
  accent: string;
  settings: Partial<GameSettings>;
}
```

`suggestPlan(sessionCount)` empfiehlt basierend auf Erfahrung:
- 0 Sessions → Warm-Up
- 1–4 Sessions → ii-V-I Deep Dive
- 5–9 → Speed Run
- 10+ → Challenge

### custom-progressions.ts

Vollständiger Parser und Evaluator für freie Akkord-Sequenzen:

- **Parser:** `parseChordSymbol("Dm7")` → `{ root: "D", quality: "m7", ... }`
- **Separatoren:** `|`, `-`, Leerzeichen, Beat-Annotationen `(2)`
- **7 Presets:** Autumn Leaves, All of Me, Blue Bossa, Rhythm Changes, 12-Bar Blues, So What, Satin Doll
- **Evaluator:** `evaluateSession()` → Accuracy, Timing-Offsets, schwächste Akkorde pro Loop
- **CRUD:** localStorage mit max. 50 eigene Progressions

---

## Services (`src/lib/services/`)

Browser-APIs und Seiteneffekte. Alles was `window`, `navigator`, `localStorage` oder externe Libraries braucht.

### audio.ts (Tone.js)

```
PolySynth (triangle8)  ──→  playChord(notes)
                        ──→  playNote(note)

MembraneSynth          ──→  Metronom-Click
Tone.Transport         ──→  BPM-basiertes Timing
Tone.Loop              ──→  Beat-Zyklus
Tone.getDraw()         ──→  UI-Sync für Beat-Indicator
```

- Oktav-Placement ab Oktave 3 mit natürlicher Spreizung
- ADSR-Envelope: Attack 0.02, Decay 0.3, Sustain 0.2, Release 1.5
- Metronom: Akzent auf Beat 1 (0.3 vs 0.15 Velocity)

### midi.ts (Web MIDI API)

```
navigator.requestMIDIAccess()
  → MIDIInput.onmidimessage
    → Note On (144) / Note Off (128)
      → activeNotes Set
        → checkChord(expected, active)
          → { correct, accuracy, matched, missing, extra }
```

- **Strict Matching (default):** Pitch-Class-basiert (Oktave egal), Extra-Noten NICHT erlaubt — nur exakt die erwarteten Pitch-Classes werden akzeptiert
- **Lenient Matching (legacy):** Extra-Noten erlaubt, nur fehlende zählen als Fehler
- **Bass-Matching (Inversions):** Strict + niedrigste Note muss korrekte Bass-Note sein
- Callbacks: `onNotes`, `onConnection`, `onDevices`
- Auto-Reconnect bei Device-Removal

### progress.ts (localStorage)

**4 Storage Keys:**

| Key | Inhalt | Max |
|-----|--------|-----|
| `chord-trainer-history` | Session-Array mit Timings | 100 Sessions |
| `chord-trainer-settings` | Letzte Settings | 1 Objekt |
| `chord-trainer-streak` | Current/Best/LastDate | 1 Objekt |
| `chord-trainer-plan-history` | Letzte Plan-IDs | 10 Einträge |

**Analyse-Funktionen:**
- `analyzeWeakChords()` — Gruppiert Timings nach Root, sortiert langsamste zuerst
- `analyzeChordTrends()` — Vergleicht letzte 5 vs. ältere 5-15 Sessions
- `getPersonalBests()` — Keyed: `{difficulty}-{voicing}-{progressionMode}`

### theme.ts

- 2 registrierte Themes: `default`, `openstudio`
- Anwendung via `data-theme` Attribut auf `<html>`
- Persistiert in `chord-trainer-theme` localStorage Key
- ⚠️ **Bekanntes Problem:** Open Studio Theme hat kein CSS (siehe [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md))

---

## Game Loop (State Machine)

Die Haupt-Spiellogik lebt in `/train/+page.svelte` (785 Zeilen):

```
                          ┌─────────────────┐
                          │                 │
    ┌──────────┐    start │  ┌──────────┐   │  finish   ┌──────────┐
    │  setup   │─────────▸│  │ playing  │   │──────────▸│ finished │
    │          │          │  │          │   │           │          │
    │ Plans    │          │  │ Timer    │   │           │ Results  │
    │ Settings │          │  │ Space/↓  │   │           │ Stats    │
    │ MIDI     │          │  │ MIDI     │   │           │ Restart  │
    └──────────┘          │  └────┬─────┘   │           └────┬─────┘
         ▲                │       │         │                │
         │                │  Verify Mode?   │                │
         │                │  ┌─────┴──────┐ │                │
         │                │  │ 'playing'  │ │                │
         │                │  │ → zeige    │ │                │
         │                │  │ 'verifying'│ │                │
         │                │  │ → nächster │ │                │
         │                │  └────────────┘ │                │
         │                └─────────────────┘                │
         │                                                   │
         └───────────────────────────────────────────────────┘
                              reset
```

**Zusätzliche Screens für Custom Progressions:**
- `custom-editor` → `custom-playing` → `custom-results`

**MIDI-Flow** (wenn aktiv):
1. Spieler drückt Tasten → `activeNotes` Update
2. `checkChord()` vergleicht Pitch-Classes strikt (keine Extra-Noten erlaubt)
3. Grün/Rot-Feedback auf Keyboard-Overlay
4. Bei Korrektheit → 400ms Delay → Auto-Advance

---

## Datenfluss: Akkord-Generierung

```
GameSettings (User Input)
  │
  ▼
generateChords(settings)          ← progressions.ts / chords.ts
  │
  ▼
ChordWithNotes[]                  ← voicings.ts
  ├── chord: "BbΔ7"              (Display-Name)
  ├── root: "Bb"
  ├── type: "Maj7"               (interner Key)
  ├── notes: ["Bb","D","F","A"]  (Root Position)
  └── voicing: ["Bb","D","A"]    (Shell/Full/etc.)
  │
  ▼
PianoKeyboard                     ← keyboard.ts
  ├── getActiveKeyIndices()       (welche Tasten leuchten)
  └── isRootIndex()              (Root-Punkt anzeigen)
  │
  ▼
Audio Service                     ← audio.ts
  └── playChord(voicing)         (Ton abspielen)
```

---

## Component-Hierarchie

```
+layout.svelte
├── Nav (Logo, Train, For Educators)
├── {page content}
│   └── /train/+page.svelte
│       ├── GameSettings
│       │   ├── PracticePlan Grid
│       │   ├── MidiStatus
│       │   ├── ProgressDashboard
│       │   └── Custom Settings (collapsible)
│       ├── ChordCard
│       │   └── PianoKeyboard (+ MIDI Overlay)
│       ├── Results
│       │   └── PianoKeyboard (mini, per chord)
│       ├── ProgressionEditor
│       ├── ProgressionPlayer
│       │   └── PianoKeyboard
│       └── ProgressionResults
└── Footer (hidden on /train)
```

---

## Deployment

```
Code Push → GitHub → Vercel Auto-Deploy
                      ├── Build: vite build
                      ├── Adapter: adapter-vercel
                      └── Output: Edge-optimized SSR
```

- **Domain:** jazzchords.app
- **SSR:** Aktiv, aber App ist rein client-seitig (kein Server-State)
- **PWA:** `site.webmanifest` für Add-to-Homescreen
- **SEO:** `sitemap.xml`, `robots.txt`, Meta-Tags auf jeder Seite
