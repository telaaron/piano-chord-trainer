# Auto-Modus („Coach") — Design

> Ziel: App öffnen → **ein Button** → losspielen. Kein Nachdenken, kein Konfigurieren.
> Ein System, das wie ein Lehrer dort ansetzt, wo der Spieler steht, Schwächen gezielt übt,
> bei Erfolg das Trainingsgebiet erweitert und dabei abwechslungsreich bleibt.

Stand: 2026-07-23 · Betrifft: Web (`src/lib/engine`) + iOS (`ios/MusicEngine`) — 1:1-Port-Pflicht.

---

## 1. Warum das jetzt geht (Ist-Analyse)

Fast alle Bausteine existieren bereits — sie sind nur nicht verbunden:

| Baustein | Wo | Status |
|---|---|---|
| Weak-Spot-Analyse (Root×Voicing) | `progress.ts` `analyzeWeakSpots` | ✅ fertig, wird für Weak-Drill genutzt |
| Gewichtete Chord-Auswahl (WEAK 4×, NEW 2.5×, FOCUS 10×) | `engine/adaptive.ts` | ✅ fertig, nur bei `progressionMode==='random'` aktiv |
| Spaced Repetition (SM-2, `chordSchedule`) | `engine/habits.ts` | ⚠️ implementiert, aber **nur** für Goal-Texte genutzt — steuert keine Auswahl |
| Trend-Analyse (improving/declining) | `adaptive.ts` `computeTrend` | ✅ fertig, ungenutzt für Steuerung |
| Plan-Vorschlag | `plans.ts` `suggestPlan` | ⚠️ flach: Session-Count-Gate + Rotation, kein Können-Bezug |
| Curriculum (leicht → schwer) | `courses/ultimate-plan.ts` (8 Module, ~28 Lektionen) | ✅ fertig, aber Kurs-Fortschritt und Drill-Historie reden **nicht** miteinander |
| Tages-Ziel, XP, Streak, Motivation | `habits.ts` | ✅ fertig |

**Die Lücke:** Es gibt keinen Regelkreis, der (a) den Übungsraum über Zeit erweitert,
(b) Schwierigkeit rauf-/runterregelt, (c) über Tage hinweg plant. Genau das ist der Coach.

---

## 2. Kernkonzept: 3 Schichten

```
┌─────────────────────────────────────────────────┐
│ 1. SKILL-MAP        „Was kann der Spieler?"     │  Zustand
├─────────────────────────────────────────────────┤
│ 2. COACH-CONTROLLER „Was ist heute dran?"       │  Entscheidung
├─────────────────────────────────────────────────┤
│ 3. SESSION-COMPOSER „Wie sieht die Session aus?"│  Ausführung
└─────────────────────────────────────────────────┘
```

### 2.1 Skill-Map — der Wissensstand

Eine **Skill-Unit** = (Voicing × Quality × Key-Gruppe), z. B. „Shell-Voicings, Dominant 7, easy keys".
Die Units bilden eine Leiter, die direkt aus dem Ultimate-Plan-Curriculum abgeleitet wird
(Fundamentals → Shells → 6ths → 9ths → Full/Half-Shell → Rootless → Inversions → Altered),
jeweils in 3 Key-Stufen: `EASY_KEYS → MED_KEYS → ALL_KEYS` (existiert schon in den Kursdaten).

Jede Unit hat einen Zustand:

```
locked → learning → practicing → mastered → (decayed → practicing)
```

- **mastered**: Ø-Zeit < Schwelle (2000 ms, wie `MASTERY_THRESHOLD_MS`) über die letzten N Versuche
  UND Trend nicht `declining`.
- **decayed**: SM-2 `nextReview` überfällig → Unit fällt zurück in den Review-Pool.
  (Damit wird der bereits implementierte `chordSchedule` endlich Steuerungs-Input.)

Die **Frontier** = die erste nicht-gemasterte Unit auf der Leiter. Sie ist „das Neue von heute".

### 2.2 Coach-Controller — der Regelkreis

Pure Function, läuft bei App-Start und nach jeder Session:

```
Input:  SessionResult[] (History), HabitProfile (inkl. chordSchedule),
        CourseProgress, CoachState (neu, persistiert)
Output: CoachPlan für heute (Liste von Session-Blöcken + Begründung)
```

Regeln (bewusst simpel und erklärbar — der Coach soll seine Entscheidungen zeigen können):

1. **Promotion**: Frontier-Unit ≥ 80 % der Versuche unter Schwelle UND Trend `improving|stable`
   → Unit `mastered`, Frontier rückt weiter. Erst Keys erweitern (easy→med→all), dann nächste Quality, dann nächstes Voicing.
2. **Hold**: Schwelle verfehlt → Frontier bleibt, nächste Session bekommt mehr Guided-Anteil
   (`displayMode: 'always'` statt `'verify'`) und kleineren Pool (FOCUS-Gewichtung 10× existiert).
3. **Demotion (sanft)**: 2 Sessions in Folge deutlich verfehlt ODER SM-2-Lapse
   → Unit zurück auf `practicing`, Key-Stufe eine runter. Nie mehr als eine Stufe.
4. **Fast-Track fürs Onboarding**: Neue Nutzer starten mit einer 3-Minuten-Kalibrierung
   (gemischte Basics, `displayMode: 'verify'`). Wer schnell ist, überspringt Units per
   „mastered by placement" — kein Beginner-Gefängnis für Fortgeschrittene.
5. **Decay**: Überfällige `chordSchedule`-Einträge mappen auf ihre Unit → Review-Pool.

### 2.3 Session-Composer — die Stunde beim Lehrer

Eine Auto-Session (Länge = `dailyGoalMinutes` aus dem Habit-Profil) besteht aus Blöcken —
das erzeugt die gewünschte Abwechslung strukturell, nicht zufällig:

| Block | Anteil | Inhalt | Quelle |
|---|---|---|---|
| **Warm-up** | ~15 % | Gemasterte Units, schnell, Erfolgserlebnis | mastered-Pool |
| **Review** | ~20 % | Fällige SRS-Chords | `chordSchedule` due |
| **Focus** | ~25 % | Schwächster Weak-Spot (Root×Voicing) | `analyzeWeakSpots` + FOCUS 10× |
| **Neu** | ~25 % | Frontier-Unit, guided (`verify`, kleiner Pool) | Frontier |
| **Anwenden** | ~15 % | Progression (ii-V-I, Turnaround, Cycle) **nur mit gemasterten Voicings** | `progressions.ts` |

- Kurze Sessions (< 8 min): nur Review + Focus + Neu.
- Blöcke rotieren im Charakter (mal Ear-Check statt Warm-up, mal In-Time statt Anwenden),
  damit sich auch Wochen abwechslungsreich anfühlen — Rotation deterministisch aus `CoachState.dayIndex`.
- Jeder Block ist intern ein normaler Drill-Run mit eigenen Settings → wir komponieren
  bestehende `PracticePlan`-artige Specs, keine neue Game-Loop.

---

## 3. UX — „einfach los"

### Einstieg
- **Today/QuickStart bekommt EINEN dominanten Button:** „▶ Weiter üben" (Web: `QuickStart.svelte`, iOS: `TodayView.swift`).
- Darunter eine Zeile Coach-Ansage, damit es sich nach Lehrer anfühlt, nicht nach Zufall:
  *„Heute: Shell-Voicings auffrischen, dann 7♯5 in neuen Keys — 12 Minuten."*
- Alle bestehenden Modi bleiben unter „Selbst wählen" erreichbar — der Auto-Modus ist der Default, kein Ersatz.

### Während der Session
- Block-Übergänge als Mini-Zwischenscreens (1 Zeile: „Warm-up geschafft — jetzt dein Fokus: B♭7 Shell").
- Kein Settings-UI sichtbar. Ein einziges Feedback-Ventil: „zu leicht / passt / zu schwer"
  (fließt als Bias in den Controller — Nutzerkontrolle ohne Konfigurationszwang).

### Danach
- Lehrer-Feedback statt nackter Stats: *„E♭maj7 sitzt jetzt (−31 %). B♭7 üben wir morgen nochmal.
  Nächstes Ziel: Rootless A."* → speist sich aus Promotion/Hold-Entscheidungen, ist also ehrlich.
- XP/Streak/Goals laufen unverändert über `processSessionHabits`.

---

## 4. Technische Umsetzung

### Neue Engine-Datei (pure, portierbar)
`src/lib/engine/coach.ts` → Port `ios/MusicEngine/Sources/MusicEngine/Coach.swift`

```ts
export interface SkillUnit { id: string; voicing: VoicingType; quality: string; keyTier: 'easy'|'med'|'all'; }
export type UnitState = 'locked' | 'learning' | 'practicing' | 'mastered';

export interface CoachState {
  version: number;
  unitStates: Record<string, { state: UnitState; bestAvgMs?: number; lastTrainedAt?: number; holds: number }>;
  frontierIndex: number;
  dayIndex: number;                 // für deterministische Block-Rotation
  difficultyBias: number;           // -1..+1 aus „zu leicht/zu schwer"
  calibrated: boolean;
  lastPlan?: CoachPlan;             // fürs Resume
}

export interface CoachBlock {
  kind: 'warmup' | 'review' | 'focus' | 'new' | 'apply' | 'calibrate';
  settings: PracticePlanSettings;   // exakt die bestehenden Settings-Achsen
  focusRoots?: string[]; focusVoicing?: string;   // Plumbing existiert Ende-zu-Ende
  targetChords: number;
  labelKey: string;                 // Coach-Ansage (i18n)
}

export interface CoachPlan { blocks: CoachBlock[]; sayKey: string; sayParams: Record<string,string>; estMinutes: number; }

export function buildCoachPlan(history, profile, courseProgress, state, now): CoachPlan;
export function applySessionToCoach(state, plan, session): CoachState;   // Promotion/Hold/Demotion
```

### Persistenz & Sync
- Neuer Key `chord-trainer-coach-state` → in `SYNC_KEYS` (`cloud-sync.ts`) aufnehmen,
  iOS parallel als `StoreKey` in `Persistence.swift`. Reitet auf dem bestehenden jsonb-Blob-Sync.

### Nötige kleine Engine-Fixes (Voraussetzungen)
1. **`ChordTiming` um `correct?: boolean` erweitern** (`progress.ts` + `Progress.swift`).
   Bisher wird Korrektheit im Verify-Modus live genutzt, aber nicht persistiert — für Mastery
   brauchen wir sie. Optionales Feld → alte Sessions bleiben kompatibel.
2. **Adaptive Gewichtung auch in Progression-Blöcken zulassen** ist NICHT nötig — der Composer
   nutzt Progressionen bewusst nur im „Anwenden"-Block mit gemastertem Material.
3. `SessionResult` um `blockKind?: string` erweitern, damit die Auswertung Blöcke unterscheiden kann.

### Wiederverwendung (bewusst maximal)
- Auswahl-Engine: `getWeightedChordPool` + `pickWeightedChord` unverändert.
- Mastery-Schwelle: `MASTERY_THRESHOLD_MS` aus `courses.ts`.
- Curriculum-Leiter: aus `ultimate-plan.ts`-Struktur generiert (kein zweites Curriculum pflegen).
- SRS: `chordSchedule`/`processSessionForSchedule` unverändert, nur endlich als Input verdrahtet.
- Kurs-Brücke: gemasterte Units markieren die zugehörige Lektion als `mastered`
  (`course-progress.ts`) — Learn-Tab und Auto-Modus zeigen denselben Fortschritt.

### Pro-Gating (Empfehlung)
Auto-Modus **frei** machen (er ist DER Retention-Treiber und das beste Onboarding),
Pro behält: unbegrenzte Historie-Tiefe/Statistiken, Cloud-Sync, Custom-Progressions im
„Anwenden"-Block. Das bisherige `adaptive-difficulty`-Gate auf den manuellen `adaptive-drill`
beschränken. (Entscheidung liegt bei Aaron — technisch ist beides ein Einzeiler am Gate.)

---

## 5. Umsetzungs-Phasen

| Phase | Inhalt | Aufwand |
|---|---|---|
| **1 — MVP** | `coach.ts` (Skill-Map aus Ultimate-Plan, Controller, Composer als EIN zusammenhängender Drill statt echter Blöcke), „Weiter üben"-Button in QuickStart, Coach-Ansage, `correct`-Flag persistieren | ~2–3 Tage |
| **2 — Blöcke** | Echte Block-Sessions mit Zwischenscreens, Lehrer-Feedback-Screen, „zu leicht/zu schwer" | ~2 Tage |
| **3 — Tiefe** | SRS-Decay verdrahten, Kalibrierung für neue Nutzer, Kurs-Brücke, Block-Rotation (Ear/In-Time) | ~2 Tage |
| **4 — iOS** | `Coach.swift`-Port + ParityTests, TodayView-Hero-Button, TrainerStore-Blöcke | ~2–3 Tage |

Phase 1 ist allein schon ein spürbarer Sprung: App öffnen → ein Tap → eine Session, die
Warm-up-Anteil, Weak-Spots und genau eine neue Sache mischt.
