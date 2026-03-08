# Chord Trainer – Architektur

> Technische Referenz für Entwickler. Was wo lebt, wie Daten fließen, und warum.
> **Stand:** März 2026 · **Version:** 0.5.0

---

## Überblick

```
┌──────────────────────────────────────────────────────────────────┐
│                           Browser                                │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐ │
│  │   Routes      │  │  Components  │  │       Services         │ │
│  │  (SvelteKit)  │─▸│  (Svelte 5)  │─▸│     (TypeScript)       │ │
│  │               │  │              │  │                        │ │
│  │ /train        │  │ ChordCard    │  │ audio.ts (Tone.js)     │ │
│  │ /learn/[…]    │  │ PianoKeyboard│  │ midi.ts  (Web MIDI)    │ │
│  │ /midi-test    │  │ GameSettings │  │ audio-input.ts (Pitch) │ │
│  │ /open-studio  │  │ HabitDash    │  │ midi-sound.ts          │ │
│  │ /for-educators│  │ GoalCard     │  │ progress.ts            │ │
│  │ /embed        │  │ LevelBadge   │  │ course-progress.ts     │ │
│  │ /about        │  │ Results      │  │ habits.ts              │ │
│  │ …             │  │ …(18 total)  │  │ theme.ts               │ │
│  └──────┬────────┘  └──────┬───────┘  └────────┬───────────────┘ │
│         │                  │                    │                 │
│         └──────────────────┼────────────────────┘                 │
│                            │                                     │
│  ┌─────────────┐  ┌───────▼────────┐  ┌───────────────────────┐ │
│  │   Courses   │  │     Engine     │  │        i18n           │ │
│  │  (Daten)    │  │  (Pure TS)     │  │  (DE + EN)            │ │
│  │             │  │                │  │                       │ │
│  │ intervals   │  │ notes.ts       │  │ de.ts (~1470 Keys)    │ │
│  │ shell-voic. │  │ chords.ts      │  │ en.ts (~1460 Keys)    │ │
│  │ scale-deg.  │  │ voicings.ts    │  │ index.ts (t()-Helper) │ │
│  │ ultimate    │  │ keyboard.ts    │  └───────────────────────┘ │
│  └─────────────┘  │ progressions.ts│                            │
│                   │ plans.ts       │                            │
│                   │ custom-prog.ts │                            │
│                   │ voice-leading  │                            │
│                   │ adaptive.ts    │                            │
│                   │ habits.ts      │                            │
│                   │ courses.ts     │                            │
│                   └───────┬────────┘                            │
│                           │                                     │
│                  ┌────────▼────────┐                            │
│                  │   localStorage  │                            │
│                  │   (Persistenz)  │                            │
│                  └─────────────────┘                            │
└──────────────────────────────────────────────────────────────────┘
```

### Schichten

| Schicht | Verzeichnis | Verantwortung | Darf importieren von |
|---------|------------|---------------|---------------------|
| **Engine** | `src/lib/engine/` | Musiktheorie, Berechnung, pure Funktionen | Nichts (standalone) |
| **Courses** | `src/lib/courses/` | Kursstruktur, Lektionen, Step-Definitionen | Engine |
| **Services** | `src/lib/services/` | Browser-APIs, Seiteneffekte | Engine |
| **i18n** | `src/lib/i18n/` | Zweisprachige UI-Texte (DE/EN) | Nichts |
| **Components** | `src/lib/components/` | UI-Darstellung, User Interaction | Engine, Services, i18n |
| **Routes** | `src/routes/` | Seiten, State Machine, Orchestrierung | Alles |
| **Utils** | `src/lib/utils/` | Shared Hilfsfunktionen | Nichts |

**Regel:** Engine importiert nie Services oder Components. Services importieren nie Components.

---

## Engine (`src/lib/engine/`) — 12 Module + 4 Test-Dateien

Pure TypeScript ohne DOM-Abhängigkeiten. Theoretisch in jedes Framework portierbar.

### notes.ts

Grundlage für alles. Definiert die chromatische Skala in zwei Varianten:

```
NOTES_SHARPS = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
NOTES_FLATS  = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B']
```

- `noteToSemitone(note)` — Universaler Lookup: Sharps → Flats → Enharmonic Map → -1
- `getNoteName(semitone, interval, pref)` — Berechnet Ziel-Note basierend auf Root + Semitone-Offset
- `getNotePool(pref)` — Gibt das richtige Array zurück (sharps/flats/both)
- `convertNoteName(note, system)` — B→H, Bb→B für deutsche Notation
- **Index = Semitone** — C=0, C#/Db=1, ... B=11

### chords.ts

16 Akkord-Typen als Semitone-Intervalle vom Root:

```typescript
CHORD_INTERVALS = {
  'Maj7':    [0, 4, 7, 11],
  '7':       [0, 4, 7, 10],     // Dominant
  'm7':      [0, 3, 7, 10],
  'm7b5':    [0, 3, 6, 10],     // Half-diminished
  'dim7':    [0, 3, 6, 9],
  '6':       [0, 4, 7, 9],
  // + m6, Maj9, 9, m9, 6/9, Maj7#11, 7#9, 7b9, m11, 13
}
```

Weitere Exports: `CHORDS_BY_DIFFICULTY`, `CHORD_NOTATIONS` (3 Systeme), `VOICING_LABELS`, `displayToQuality()`.

### voicings.ts

Berechnet die tatsächlich gespielten Noten:
- `getChordNotes()`, `getVoicingNotes()`, `getVoicingIntervalLabels()`
- `getChordFormula()`, `formatVoicing()`, `getValidPCSets()`
- **9 Voicing-Typen:** root, shell, half-shell, full, rootless-a, rootless-b, inversion-1/2/3

### keyboard.ts

Bildet Voicing-Noten auf 2–3-Oktaven-Klaviatur ab:
- `OCTAVE_CONFIGS`, `computeSessionOctaves()`, `getActiveKeyIndices()`
- `getKeyboardLayout()`, `isRootIndex()`

### progressions.ts

4+ Progressions-Modi: random, 2-5-1, cycle-of-4ths, 1-6-2-5.
Plus: `MODE_DEGREE_MAP`, `parseCustomDegrees()`, `degreesToLabel()`.

### voice-leading.ts

Stimmführungs-Analyse: `analyzeVoiceLeading()`, `computeVoiceLeadVoicing()`, `getAllRotations()`, `scorePlayerMovement()`, `validateFindInversion()`, `validateFreeVoicing()`.

### adaptive.ts

Adaptives Übungssystem: `analyzePerformance()`, `getWeightedChordPool()`, `pickWeightedChord()`, `getPerformanceSummary()`.

### habits.ts (Engine)

Gamification: XP/Levels (`calculateLevel()`, Level = floor(sqrt(totalXP/50))), Streaks (`getStreakMultiplier()`, 1.0× bis 2.0×), Goals (`generateGoals()`), Spaced Repetition (`updateChordSchedule()`, SM-2-basiert).

### courses.ts (202 Zeilen)

Typsystem für Kurse:

```typescript
type StepType = 'theory' | 'practice' | 'challenge';
type MasteryLevel = 'none' | 'started' | 'completed' | 'mastered';

interface Course { id, titleKey, subtitleKey, level, modules }
interface CourseModule { titleKey, lessons }
interface Lesson { id, titleKey, subtitleKey, steps }
type LessonStep = TheoryStep | PracticeStep | ChallengeStep

interface IntervalSpec { root, target, label, semitones }
interface ChordSpec { root, quality, voicing }
```

### plans.ts / custom-progressions.ts

Übungspläne und Custom-Progression-Editor.

---

## Courses (`src/lib/courses/`) — 4 Kurse

| Kurs | Level | Fokus |
|------|-------|-------|
| `intervals` | Beginner | Intervall-Erkennung (Terzen, Quarten, Tritone) |
| `shell-voicings` | Beginner | Root + 3rd + 7th für Maj7, Dom7, m7 |
| `scale-degrees` | Intermediate | Diatonische Stufenakkorde |
| `ultimate-plan` | Comprehensive | Beginner-to-Master Gesamtweg |

**Registry:** `ALL_COURSES`, `getCourse(id)`, `getLesson(courseId, lessonId)`.

**3-Phasen-Lernmodell:**

```
Theory (Verstehen)        Practice (Üben)           Challenge (Meistern)
┌────────────────┐    ┌─────────────────────┐   ┌─────────────────┐
│ Erklärung      │    │ Guided (alle Noten) │   │ Speed-Drill     │
│ Beispiel-Akkord│ →  │ Find (Root + Name)  │ → │ alle Keys       │
│ Formel + Piano │    │ Free (ohne Hilfe)   │   │ Timer + Mastery │
└────────────────┘    │ Pool-Shuffle        │   │ Bewertung A–F   │
                      └─────────────────────┘   └─────────────────┘
```

---

## Services (`src/lib/services/`) — 8 Module

| Service | Technologie | Zweck |
|---------|------------|-------|
| `audio.ts` | Tone.js | PolySynth, Metronom, Transport |
| `midi.ts` | Web MIDI API | Device-Management, Note-Matching, Persistenz |
| `audio-input.ts` | @spotify/basic-pitch | ML Pitch-Detection via Mikrofon |
| `midi-sound.ts` | Tone.js | Audio-Output für MIDI-Input |
| `course-progress.ts` | localStorage | Kurs-Fortschritt |
| `habits.ts` | localStorage | HabitProfile (XP, Streak, Goals) |
| `progress.ts` | localStorage | Session-History, Settings, Plans |
| `theme.ts` | CSS custom props | Theme-Persistenz |

### MIDI Device-Management

- `selectDevice(id)` → persistiert in `localStorage('midi-selected-device')`
- `hideDevice(id)` / `unhideDevice(id)` / `unhideAll()` → `localStorage('midi-hidden-devices')`
- `VIRTUAL_PORT_PATTERNS` → Regex-Filter für macOS IAC, MIDI Through, Microsoft GS
- Auto-Reconnect, Hot-Plug-Support

### MIDI Matching

- **Strict:** Pitch-Class-basiert, keine Extra-Noten
- **Lenient:** Extra-Noten toleriert
- **Bass-Matching:** Strict + unterste Note = Bass

---

## localStorage Keys

| Key | Inhalt |
|-----|--------|
| `chord-trainer-history` | Session-Array (max 100) |
| `chord-trainer-settings` | Letzte Settings |
| `chord-trainer-streak` | Current/Best/LastDate |
| `chord-trainer-plan-history` | Letzte Plan-IDs (max 10) |
| `midi-selected-device` | MIDI-Device-ID |
| `midi-hidden-devices` | JSON-Array versteckter IDs |
| `chord-trainer-locale` | 'de' oder 'en' |
| `chord-trainer-courses-*` | Kurs-Fortschritt pro Kurs |
| `chord-trainer-habit-profile` | XP, Streak, Goals, Schedule |
| `chord-trainer-theme` | Theme-Name |

---

## i18n (`src/lib/i18n/`)

- **~1460 Keys** pro Sprache (DE/EN)
- `t(key, params?)` — Punkt-separierter Lookup: `t('nav.home')` → "Startseite"
- Parameter: `t('midi_test.hidden_count', { n: 3 })` → "3 ausgeblendet"
- Fallback: EN wenn Key in DE fehlt
- Locale: `localStorage('chord-trainer-locale')` → `document.documentElement.lang`

---

## Routen (12)

| Route | Zweck |
|-------|-------|
| `/` | Landing Page (3D-Video-Hero, Features) |
| `/train` | Haupt-Trainer (~2700 Zeilen) |
| `/learn` | Kurs-Browser |
| `/learn/[courseId]` | Kurs-Detail |
| `/learn/[courseId]/[lessonId]` | Lektions-Player (~980 Zeilen) |
| `/midi-test` | MIDI/Mikrofon-Diagnostik |
| `/embed` | iFrame-Embed-Player |
| `/for-educators` | B2B Landing Page |
| `/open-studio` | Open Studio Pitch |
| `/about` | Über das Projekt |
| `/privacy` | Datenschutz |
| `/impressum` | Impressum |

---

## Component-Hierarchie (18)

```
+layout.svelte
├── Nav (Train, Learn, For Educators, Locale Toggle)
├── /train/+page.svelte
│   ├── GameSettings
│   ├── HabitDashboard + GoalCard + LevelBadge + CelebrationOverlay
│   ├── ChordCard + PianoKeyboard + ExplainPanel
│   ├── Results + PianoKeyboard (mini)
│   ├── ProgressionEditor → ProgressionPlayer → ProgressionResults
│   └── MidiStatus + MidiToast + MicStatus
├── /learn/[courseId]/[lessonId]/+page.svelte
│   ├── PianoKeyboard (2–3 Oktaven)
│   └── MidiStatus
└── /midi-test/+page.svelte
    └── PianoKeyboard
```

---

## Datenfluss: Lektions-Practice-Loop

```
Course → Lesson → PracticeStep
  │
  ▼
intervalPool / chordPool
  │
  ▼
practicePhase: 'guided' | 'find' | 'free'
  │  (shuffled order via practicePoolShuffled[])
  ▼
buildIntervalData() / buildChordData()
  │
  ▼
PianoKeyboard (highlights)  ←→  midi.checkChord() → Feedback
```

**Guided:** Alle Noten sichtbar. **Find:** Nur Root + Name. **Free:** Keine Hilfe.

---

## Deployment

- **Pipeline:** GitHub → Vercel Auto-Deploy (adapter-vercel)
- **Domain:** jazzchords.app
- **Build:** `vite build` (0 TS errors, 0 svelte-check warnings)
- **PWA:** `site.webmanifest` + `sw.js` (Service Worker)
- **SEO:** `sitemap.xml`, `robots.txt`, Meta-Tags pro Seite

---

*Zuletzt aktualisiert: März 2026*
