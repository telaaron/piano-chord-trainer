# Kurs-Modus / Lektionen-System — Konzept

> **Status:** In Umsetzung (MVP)  
> **Inspiration:** Typing-Kurse wie edclub.com, Duolingo skill trees  
> **Kern-Problem:** Der Trainer trainiert aktuell nur Geschwindigkeit, nicht Verständnis. Ein Nutzer, der nicht weiß, wie F#9b13 als Shell-Voicing aussieht, kann das Tool nicht nutzen.

---

## 0. Kritische Überprüfung — Rollenanalyse

### Perspektive: Open Studio Partner (B2B-Kunde)

**Problem:** "Jazz Piano Grundlagen" klingt nach Konkurrenz zu Open Studio. Die lehren Jazz-Piano — wenn wir das auch tun, warum brauchen sie uns?

**Lösung:** Wir lehren die **Mathematik hinter Akkorden**, nicht Jazz. Unsere Kurse heißen:
- ~~"Jazz Piano Grundlagen"~~ → **"Shell Voicings verstehen"**
- ~~"Bill Evans Stil"~~ → **"Rootless Voicings (A & B)"**
- ~~"Comping in Time"~~ → **"Rhythmisches Voicing-Training"**

**Positionierung:** Wir sind das **Übungs-Tool**, nicht die Musikschule. Like edclub.com vs. eine Schule — edclub lehrt nicht Deutsch, es trainiert die Finger. Wir lehren nicht Jazz, wir trainieren die Akkord-Konstruktion. Open Studio lehrt WANN und WARUM man einen Akkord spielt, wir lehren WIE man ihn greift.

### Perspektive: Anfänger-Nutzer

**Problem:** Jazz-Terminologie ist einschüchternd. "Shell Voicing" sagt einem Anfänger nichts.

**Lösung:** Jede Lektion erklärt den Begriff sofort mit einfacher Sprache. Theorie-Schritt zeigt die Formel visuell, nicht akademisch. Kursnamen bekommen Untertitel: "Shell Voicing — Die 3-Noten-Methode".

### Perspektive: Fortgeschrittener Nutzer

**Problem:** Gezwungene Linearität ist nervig. "Ich weiß was ein Shell Voicing ist, lass mich direkt üben."

**Lösung:** **"Überspringen"-Button** auf jedem Schritt. Alternativ: Challenge direkt spielbar — wer sie besteht, hat die Lektion sofort abgeschlossen. Kein Zwang durch Theorie.

### Perspektive: Entwickler / Wartbarkeit

**Problem:** 5 Step-Typen = 5 verschiedene UIs. Theorie-Content ist Redaktionsarbeit.

**Lösung:** MVP hat nur **3 Steps** (Verstehen → Üben → Meistern). Theorie-Content ist inline-Svelte, kein Markdown-Renderer nötig. Discover-Step entfällt im MVP.

### Perspektive: Mobile / iPhone

**Problem:** Kein Web MIDI API auf iOS. Click-Piano für 5 Steps ist mühsam.

**Lösung:** Theorie-Step funktioniert ohne Input. Guided Practice + Challenge funktionieren mit Click-Piano (ausreichend für Lernen, nicht ideal für Speed).

### Perspektive: B2B Embed (Open Studio iFrame)

**Problem:** Ein Kurs-in-einem-Kurs ist verwirrend. Open Studio hat eigene Lektionen.

**Lösung:** Für B2B exponieren wir atomare "Practice Tasks" via Lesson-Context-API — Kein ganzer Kurs, sondern einzelne Übungs-Schritte. Der Kurs-Modus ist B2C. Die API ist B2B. Gleiche Engine, verschiedene Oberflächen.

### Perspektive: Genre-Neutralität

**Problem:** Roadmap klingt Jazz-only. Shell Voicings, Rootless — alles Jazz-Begriffe.

**Lösung:** Diese Voicing-Typen SIND musikalisch neutral (werden in Neo-Soul, Gospel, R&B genauso genutzt). Die Kurs-Titel vermeiden explizites "Jazz": "Voicing-Rezepte", "Akkord-Anatomie", nicht "Jazz-Harmonielehre".

---

## 1. Vision

**Vom Speed-Drill zum Lern-Instrument.**

Der Kurs-Modus transformiert den Chord Trainer von einem reinen Geschwindigkeits-Tool zu einem vollständigen Lern-System:

```
LERNEN → VERSTEHEN → ÜBEN → MEISTERN
```

Analog zu Tipp-Kursen (edclub.com):
- **Phase 1 — Buchstabe kennenlernen:** Zeigen, wo der Buchstabe liegt → Analogie: Zeigen, welche Noten der Akkord hat
- **Phase 2 — Buchstabe üben:** Langsam den Buchstaben tippen mit Hinweisen → Analogie: Voicing mit Hilfe spielen (Noten sichtbar, Keyboard-Highlight)
- **Phase 3 — Wörter bilden:** Buchstaben in Kontext anwenden → Analogie: Voicing in Progressionen spielen
- **Phase 4 — Speed-Test:** Ohne Hilfe so schnell wie möglich → Analogie: Bestehendes Speed-Drill ohne "Vorsagen"

---

## 2. Kurs-Struktur

### 2.1 Hierarchie

```
Kurs (z.B. "Shell Voicings verstehen")
  └── Modul (z.B. "Die Grundakkorde")
        └── Lektion (z.B. "Dominant 7 Shell Voicing")
              └── Schritt 1: Verstehen (Theorie + interaktives Keyboard)
              └── Schritt 2: Üben (geführtes Spielen mit/ohne Hilfe)
              └── Schritt 3: Meistern (Speed-Drill, alle Tonarten)
```

### 2.2 Beispiel-Kurs: "Shell Voicings verstehen"

| Modul | Lektionen |
|-------|-----------|
| **1. Die 3-Noten-Methode** | Dur-Septakkord (Maj7), Dominant-Septakkord (7), Moll-Septakkord (m7) |
| **2. Alle Tonarten** | C/F/Bb, Eb/Ab/Db, G/D/A/E/B/F# |
| **3. Progressionen** | ii-V-I, I-vi-ii-V Turnaround, Quartenzirkel |
| **4. Voice Leading** | 3-7 / 7-3 Wechsel, Smooth ii-V-I |
| **5. Speed Challenge** | Random, In-Time mit Metronom |

### 2.3 Vorgeschlagene Kurse (Roadmap)

1. **Shell Voicings verstehen** — Die 3-Noten-Methode (Root + 3rd + 7th)
2. **Volle Akkorde** — Open Voicings, alle Töne in voller Besetzung
3. **Rootless Voicings (A & B)** — Fortgeschrittene linke-Hand-Technik
4. **Umkehrungen** — Akkordtöne in verschiedenen Reihenfolgen
5. **Rhythmisches Voicing-Training** — Spielen mit Metronom und Backing Track
6. **Akkorde am Klang erkennen** — Ear Training für Akkordqualitäten

---

## 3. Lektions-Schritte im Detail (3-Step-Modell)

### Schritt 1: Verstehen (Theorie + interaktives Demo)

- Inline-Svelte-Inhalt (kein Markdown-Renderer nötig)
- Erklärt das Konzept in einfacher Sprache: "Ein Shell Voicing nutzt nur 3 Noten: Grundton, Terz und Septime"
- Zeigt die Formel visuell: Keyboard mit hervorgehobenen Tasten + Labels ("Root", "3rd", "7th")
- "Anhören"-Button spielt den Akkord vor (bestehendes Audio-System)
- **Überspringen-Button:** Wer den Akkord kennt, kann direkt zum Üben
- **Kein MIDI nötig** — rein visuell/auditiv

### Schritt 2: Üben (Guided → Free, ein Flow)

Kombinierter Schritt statt zwei separate:
- **Phase A (mit Hilfe):** Keyboard zeigt korrekte Tasten, Akkord-Name sichtbar
  - Kleiner Pool (z.B. nur C, F, Bb)
  - Bei Fehler: Hinweis ("Dir fehlt das B — die Septime")
  - 3× korrekt hintereinander → Hilfe wird ausgeblendet
- **Phase B (ohne Hilfe):** Gleicher Pool, keine Highlights
  - "Zeig mir die Lösung"-Button verfügbar
  - Pool komplett fehlerfrei → Schritt abgeschlossen
- Kein Timer, kein Druck
- Nutzt bestehende MIDI-Validierung (`checkChord()`) / Click-Piano

### Schritt 3: Meistern (Challenge / Speed-Drill)

- **Alle 12 Tonarten** mit dem gelernten Voicing
- Keine Hilfe, Timer läuft
- Ist im Grunde der bestehende Speed-Drill-Modus mit vordefinierten Settings
- **Mastery-Kriterium:** Durchschnitt < 3s/Akkord (konfigurierbar)
- Erfolg → Lektion abgeschlossen, nächste Lektion freigeschaltet
- **Direkt-Einstieg möglich:** Fortgeschrittene können direkt die Challenge spielen → besteht man sie, gilt die ganze Lektion als abgeschlossen

---

## 4. Fortschritts-System

### 4.1 Mastery-Levels pro Lektion

```
⬜ Nicht begonnen
🔵 In Arbeit (mindestens 1 Schritt abgeschlossen)
⭐ Abgeschlossen (alle 3 Schritte bestanden)
💎 Gemeistert (Challenge mit <2s/Akkord)
```

### 4.2 Unlock-Logik

- **Linear innerhalb eines Moduls:** Lektion 2 erst nach Lektion 1
- **Module teilweise parallel:** Modul 2 braucht nur 50% von Modul 1
- **Kurse unabhängig:** Kein Kurs blockiert einen anderen (empfohlene Reihenfolge, kein Zwang)

### 4.3 Daten-Struktur (Skizze)

```typescript
interface CourseProgress {
  courseId: string;
  modules: ModuleProgress[];
  startedAt: number;
  lastActivityAt: number;
}

interface ModuleProgress {
  moduleId: string;
  lessons: LessonProgress[];
  unlocked: boolean;
}

interface LessonProgress {
  lessonId: string;
  steps: StepProgress[];
  unlocked: boolean;
  mastery: 'none' | 'started' | 'completed' | 'mastered';
  bestChallengeAvgMs?: number;
}

interface StepProgress {
  stepType: 'theory' | 'practice' | 'challenge';
  completed: boolean;
  attempts: number;
  bestScore?: number;
}
```

### 4.4 Persistierung

- **Phase 1 (MVP):** localStorage (wie bestehender Progress)
- **Phase 2:** Supabase → Cloud-Sync, Cross-Device
- **Phase 3:** Lesson-Context-API für Open Studio Integration

---

## 5. Kurs-Inhalte: Datenformat

```typescript
interface Course {
  id: string;
  title: string;                    // "Shell Voicings meistern"
  description: string;
  level: 'beginner' | 'intermediate' | 'advanced';
  modules: CourseModule[];
}

interface CourseModule {
  id: string;
  title: string;                    // "Was sind Shell Voicings?"
  description: string;
  unlockCondition: UnlockCondition;
  lessons: Lesson[];
}

interface Lesson {
  id: string;
  title: string;                    // "Dominant 7 Shell Voicing"
  chordType: string;                // "7" (Bezug auf CHORD_INTERVALS)
  voicingType: VoicingType;         // "shell"
  keys?: string[];                  // ["C","F","Bb"] — einschränken statt alle 12
  steps: LessonStep[];
}

type LessonStep =
  | { type: 'theory'; content: string }  // Inline Svelte content key
  | { type: 'practice'; chordPool: ChordSpec[]; guidedCount: number; showHintButton: boolean }
  | { type: 'challenge'; settings: Partial<PlanSettings>; masteryThresholdMs: number };

interface ChordSpec {
  root: string;      // "C"
  quality: string;   // "7"
  voicing: VoicingType;
}

interface UnlockCondition {
  type: 'none' | 'lessons-completed' | 'module-percent';
  moduleId?: string;
  lessonIds?: string[];
  percent?: number;
}
```

Kurse werden als reine Daten-Dateien definiert (z.B. `src/lib/courses/shell-voicings.ts`), keine Datenbank nötig. Das erlaubt Type-Checking, Bundling und einfache Erweiterung.

---

## 6. UI-Konzept

### 6.1 Kurs-Übersicht (neuer Screen)

```
┌──────────────────────────────────────────────┐
│  🎹 Lern-Kurse                               │
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │ ⭐ Shell Voicings meistern              │ │
│  │    Modul 1 ████████░░ 80%               │ │
│  │    Modul 2 ████░░░░░░ 40%               │ │
│  │    [Weiter lernen]                       │ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │ 🔒 Rootless Voicings                    │ │
│  │    Empfohlen nach Shell Voicings         │ │
│  │    [Vorschau]                            │ │
│  └─────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

### 6.2 Lektions-Ansicht

```
┌──────────────────────────────────────────────┐
│  ← Shell Voicings > Modul 1 > Lektion 2     │
│                                               │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐        │
│  │ ✅ │ │ ✅ │ │ 🔵 │ │ ⬜ │ │ ⬜ │        │
│  │Info│ │Entd│ │Üben│ │Frei│ │Test│        │
│  └────┘ └────┘ └────┘ └────┘ └────┘        │
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │  Cmaj7 Shell Voicing                    │ │
│  │                                         │ │
│  │  ┌───────────────────────────────────┐  │ │
│  │  │         PIANO KEYBOARD            │  │ │
│  │  │    [C]       [E]           [B]    │  │ │
│  │  └───────────────────────────────────┘  │ │
│  │                                         │ │
│  │  Spiele: Root (C), Terz (E), Septime (B)│ │
│  │                                         │ │
│  │  ✅ C  ✅ E  ⬜ B                      │ │
│  └─────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

### 6.3 Navigation

- **Neuer Tab/Route:** `/learn` (neben `/train`)
- **Einstieg:** Landing Page bekommt "Lernen"-Button neben "Trainieren"
- **Nahtloser Übergang:** Challenge-Schritt einer Lektion nutzt exakt den bestehenden Speed-Drill-Modus mit vordefinierten Settings
- **Quick-Access:** Von jeder Lektion sofort in den freien Übungsmodus wechseln können

---

## 7. Integration mit bestehendem System

### 7.1 Was wiederverwendet wird

| Bestehendes Feature | Nutzung im Kurs-Modus |
|---------------------|----------------------|
| `checkChord()` / `checkChordWithBass()` | MIDI-Validierung in allen Übungs-Schritten |
| `PianoKeyboard.svelte` | Visuelle Darstellung + Click-Input |
| `getVoicingNotes()` | Generierung der erwarteten Noten |
| `ChordCard.svelte` | Akkord-Anzeige |
| Audio-System (Sampler) | Vorspielen, Feedback-Sounds |
| `ProgressDashboard` | Anpassung für Kurs-Fortschritt |
| Adaptive Engine | Gewichtung in Challenge-Steps |
| Habits/XP System | XP für Lektions-Abschluss |

### 7.2 Was neu gebaut werden muss

| Neues Feature | Beschreibung |
|---------------|-------------|
| **Kurs-Engine** (`src/lib/engine/courses.ts`) | Kurs-Definitionen, Unlock-Logik, Mastery-Berechnung |
| **Kurs-Progress** (`src/lib/services/course-progress.ts`) | Speichern/Laden von Kurs-Fortschritt |
| **Theory-Step** (Komponente) | Inline-Erklärung + interaktives Keyboard |
| **Practice-Step** (Komponente) | Guided→Free-Flow mit Hilfe-Toggle |
| **Challenge-Step** (Komponente) | Speed-Drill mit vordefinierten Settings |
| **Kurs-Übersicht** (`/learn`) | Kurs-Karten, Modul-Liste, Fortschritts-Balken |
| **Lektions-View** (`/learn/[courseId]/[lessonId]`) | Step-Navigation, Step-spezifische Darstellung |

### 7.3 Lesson-Context-API (Open Studio B2B)

Das Kurs-System bildet die Grundlage für die geplante Lesson-Context-API:

```typescript
// Extern (Open Studio) sendet per iframe postMessage:
{
  type: 'chord-trainer:start-lesson',
  courseId: 'shell-voicings',
  lessonId: 'dominant-7-shell',
  stepIndex: 2  // direkt zum Guided Practice
}

// Trainer antwortet:
{
  type: 'chord-trainer:lesson-complete',
  lessonId: 'dominant-7-shell',
  mastery: 'completed',
  avgMs: 2340
}
```

---

## 8. MVP-Scope (Phase 1)

**Ziel:** Ein funktionierender Kurs mit 3 Lektionen, der den Lern-Flow beweist.

### Was liefern:
- 1 Kurs: "Shell Voicings verstehen"
- 3 Lektionen: Maj7, Dom7, m7 (jeweils Theorie → Practice → Challenge)
- 3 Step-Typen: Theory (inline Svelte), Practice (guided→free), Challenge (Speed-Drill)
- Fortschritt in localStorage
- Route `/learn` mit Kurs-Übersicht + Lektions-View
- Responsive (Mobile + Desktop)
- "Überspringen"-Option für Fortgeschrittene

### Was NICHT:
- Kein Cloud-Sync
- Kein Unlock-System (alles verfügbar)
- Keine weiteren Kurse
- Keine Lesson-Context-API

---

## 9. Entschiedene Design-Fragen

1. **Kurs-Modus ergänzt Plans** — Plans = freies Üben (Gym), Kurse = geführtes Lernen (Kurs).
2. **Theorie-Content erst DE**, dann i18n-Keys für EN.
3. **Einfache Gamification** — ⬜/🔵/⭐/💎 Zustände, keine Badges.
4. **Mobile funktioniert** mit Click-Piano.
5. **Audio Recognition** wird perspektivisch integriert (iOS-Support).
6. **Genre-neutral** — Voicing-Typen statt Jazz-Begriffe.
7. **Kein Zwang** — Überspringen jederzeit möglich.
8. **3 Steps statt 5** — Verstehen, Üben, Meistern.

---

## 10. Zusammenfassung

Der Kurs-Modus löst das Kern-Problem: **"Ich weiß nicht, wie der Akkord aussieht."**

Er lehrt die **Mathematik und Konstruktions-Logik** von Akkorden, nicht Musiktheorie oder Jazz. Er ist das didaktische Bindeglied zwischen "Akkord gesehen" und "Akkord gekonnt".

Für Open Studio ist das der B2B-Hebel: Kein konkurrierendes Lern-Angebot, sondern ein komplementäres Übungs-Tool das in ihrem Lektions-Kontext eingebettet werden kann.
