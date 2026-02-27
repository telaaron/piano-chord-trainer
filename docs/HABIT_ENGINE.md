# Habit Engine – Psychologisch fundiertes Übungssystem

**Autor:** CTO  
**Status:** ✅ Vollständig implementiert  
**Datum:** 24. Februar 2026  
**Version:** v0.6.0  

---

## Executive Summary

Das aktuelle "Weekly Goal" ist ein statischer Fortschrittsbalken: 5 Tage üben = 100%. Niemand schaut drauf, weil es **kein echtes Ziel ist** — es misst nur Anwesenheit, nicht Fortschritt. Es fehlt an drei Dingen:

1. **Persönliche Relevanz** — Das Ziel passt sich nicht an den Spieler an
2. **Dopamin-Loops** — Es gibt keine Micro-Rewards für kleine Erfolge
3. **Commitment-Architektur** — Kein System, das den Spieler sanft zurückholt

Dieses Dokument beschreibt ein **Habit Engine** System, das auf fundierten psychologischen Prinzipien basiert und den Chord Trainer von einem Tool zu einem **Übungspartner** transformiert.

---

## 🧠 Psychologische Grundlagen

### 1. Atomic Habits (James Clear) — Die 1%-Methode

> *"You do not rise to the level of your goals. You fall to the level of your systems."*

**Die 4 Gesetze der Verhaltensänderung:**

| Gesetz | Prinzip | Unsere Umsetzung |
|--------|---------|-------------------|
| **1. Make it Obvious** | Cue sichtbar machen | Push-Notifications, Dashboard-Widget mit klarem nächstem Schritt |
| **2. Make it Attractive** | Belohnung antizipieren | XP-System, Level-Ups, Streak-Multiplier, Milestone-Celebrations |
| **3. Make it Easy** | Friction reduzieren | "2-Minute Rule" — Sessions ab 2 Min möglich, One-Tap-Start |
| **4. Make it Satisfying** | Sofortige Belohnung | Instant Feedback, Sound-Effects, Progress-Animationen |

**Konkrete Taktiken:**
- **Habit Stacking**: "Nach meinem Kaffee → 5 Min Chord Trainer" (konfigurierbar)
- **2-Minute Rule**: Kleinstmögliche Session = 4 Akkorde. Kein Grund, nicht zu üben.
- **Identity-Shift**: Nicht "Ich übe Akkorde" → "Ich bin jemand, der jeden Tag am Klavier sitzt"
- **Environment Design**: Push Notification zur gewählten Uhrzeit = Cue in der Umgebung

### 2. Hooked Model (Nir Eyal)

> *Trigger → Action → Variable Reward → Investment*

| Phase | Umsetzung |
|-------|-----------|
| **Trigger** | Push-Notification: "Deine Db-Akkorde werden schwächer — 3 Min reichen" |
| **Action** | One-Tap → direkt in die empfohlene Session |
| **Variable Reward** | Unvorhersehbare Celebrations, XP-Bonusse, "New Personal Best!" |
| **Investment** | Streak wird länger, Level steigt, Daten akkumulieren = Switching Cost |

### 3. Self-Determination Theory (Deci & Ryan)

Intrinsische Motivation entsteht durch drei Grundbedürfnisse:

| Bedürfnis | Umsetzung |
|-----------|-----------|
| **Autonomy** | Spieler wählt Ziele, Uhrzeiten, Fokus-Bereiche |
| **Competence** | Klares Feedback: "Du bist 23% schneller bei Bb-Akkorden als letzte Woche" |
| **Relatedness** | (Zukunft: Social Features) Für jetzt: "Du bist unter den Top 10% der Übenden diese Woche" |

### 4. Flow-Theorie (Csikszentmihalyi)

Das Adaptive-Difficulty-System ist bereits gebaut. Jetzt wird es zum **Flow-Regulator**:

- **Zu leicht?** → Automatisch härtere Akkorde, kürzere Zeitfenster
- **Zu schwer?** → Fokus auf bekannte Akkorde, ermutigende Messages
- **Im Flow?** → Nicht stören. Kein Popup, keine Notification.

### 5. Spaced Repetition (Ebbinghaus)

Akkorde, die der Spieler schlecht kann, erscheinen häufiger — aber auch **zeitbasiert**:
- Gestern geübt & gut? → Morgen nochmal, dann übermorgen, dann in 4 Tagen
- Gestern geübt & schlecht? → Heute nochmal, morgen nochmal
- Lange nicht geübt? → "Db-Akkorde hast du seit 5 Tagen nicht geübt — kurzes Review?"

### 6. Tiny Habits (BJ Fogg)

> *"After I [ANCHOR], I will [TINY BEHAVIOR]."*

- Der Spieler setzt einen **Anchor**: "Nach dem Aufstehen" / "Nach der Mittagspause" / "Abends um 20:00"
- Die **Tiny Behavior** ist konfigurierbar: "4 Akkorde" / "1 Warm-Up" / "2 Minuten"
- **Celebration**: Sofort nach dem Tiny Habit → konfettiartige Animation, Sound, XP

---

## 🏗️ System-Architektur

### Smart Goals (ersetzt "Weekly Goal")

Das neue System generiert **personalisierte, dynamische Ziele** basierend auf:

```
HabitProfile {
  // Spieler-Konfiguration
  dailyGoalMinutes: number        // 2, 5, 10, 15, 20 Min
  preferredTime: string           // "morning" | "afternoon" | "evening"  
  practiceAnchor: string          // Freitext: "Nach dem Kaffee"
  
  // Automatisch getrackt
  currentLevel: number            // 1-50, basierend auf XP
  currentXP: number               // Erfahrungspunkte (akkumuliert)
  weeklyXP: number                // XP diese Woche
  
  // Intelligente Ziele
  activeGoals: SmartGoal[]        // Bis zu 3 gleichzeitige Ziele
  completedGoals: SmartGoal[]     // Archiv
  
  // Spaced Repetition
  chordSchedule: ChordReview[]    // Wann welcher Akkord wiederholt werden soll
  
  // Notifications
  notificationsEnabled: boolean
  notificationTime: string        // HH:MM
  lastNotificationDate: string    // YYYY-MM-DD
}
```

### SmartGoal-Typen

| Typ | Beispiel | Wie es generiert wird |
|-----|----------|----------------------|
| **Speed** | "Bringe Db-Akkorde unter 2.0s" | Basierend auf schwächsten Akkorden |
| **Consistency** | "Übe 5 Tage diese Woche" | Streak-Daten |
| **Mastery** | "Spiele ii-V-I in allen 12 Keys unter 3s/Akkord" | Progression-Daten |
| **Exploration** | "Probiere Rootless A Voicings" | Ungenutzte Voicing-Typen |
| **Endurance** | "Schaffe 50 Akkorde in einer Session" | Session-History |
| **Review** | "Wiederhole Shell Voicings — 5 Tage nicht geübt" | Spaced Repetition |

### XP-System

```
Aktionen & XP-Werte:
──────────────────────────────
Session abgeschlossen          +10 XP
Akkord unter Personal Best     +2 XP pro Akkord
Streak-Tag (täglich)           +5 XP × Streak-Multiplikator
Streak 7 Tage                  +50 XP Bonus
Streak 30 Tage                 +200 XP Bonus
Smart Goal erreicht            +25 XP
Neuen Voicing-Typ probiert     +15 XP
Session > 5 Min                +10 XP Bonus
3 Sessions an einem Tag        +20 XP ("Dedicated" Bonus)
Alle 12 Keys in einer Session  +30 XP ("Full Circle" Bonus)

Streak-Multiplikator:
  Tag 1-7:   1.0×
  Tag 8-14:  1.25×
  Tag 15-30: 1.5×
  Tag 31+:   2.0×

Level-Berechnung:
  Level = floor(sqrt(totalXP / 50))
  Level 1:   0 XP
  Level 5:   1.250 XP
  Level 10:  5.000 XP
  Level 20:  20.000 XP
  Level 50:  125.000 XP
```

### Level-Titel (Jazz-Thematisch)

| Level | Titel EN | Titel DE |
|-------|----------|----------|
| 1-4 | Listener | Zuhörer |
| 5-9 | Beginner | Einsteiger |
| 10-14 | Student | Schüler |
| 15-19 | Sideman | Sideman |
| 20-24 | Gigging Musician | Club-Musiker |
| 25-29 | Session Player | Session-Musiker |
| 30-34 | Bandleader | Bandleader |
| 35-39 | Jazz Cat | Jazz Cat |
| 40-44 | Virtuoso | Virtuose |
| 45-49 | Legend | Legende |
| 50 | Monk Status | Monk Status |

### Push Notifications (Service Worker)

**Trigger-Logik:**

| Zeitpunkt | Nachricht | Bedingung |
|-----------|-----------|-----------|
| Gewählte Uhrzeit | "🎹 Zeit für deine {dailyGoalMinutes} Minuten — {practiceAnchor}" | Heute noch nicht geübt |
| 20:00 (Abend-Reminder) | "Noch {minutes} Min bis dein Streak endet! 🔥 Tag {streak}" | Heute nicht geübt + Streak > 3 |
| Nach 2 Tagen Pause | "Deine Db-Akkorde werden langsamer — 3 Min reichen um dran zu bleiben" | Basierend auf Spaced Repetition |
| Nach Streak-Verlust | "Neuer Start: 4 Akkorde. Mehr brauchst du nicht." | Tiny Habit Trigger |
| Persönliche Best | "🏆 Gestern warst du 15% schneller bei F#-Akkorden! Weiter so?" | Nach guter Session |

**Implementierung:**
- Service Worker registriert bei App-Start
- `Notification.requestPermission()` Prompt
- Notification-Scheduling über `setTimeout` / `setInterval` im SW
- Fallback: Kein SW → In-App Banner beim nächsten Besuch

### Spaced Repetition für Akkorde

```
ChordReview {
  chordKey: string        // z.B. "Db-Maj7"
  lastReviewed: string    // ISO timestamp
  nextReview: string      // ISO timestamp
  interval: number        // in Tagen (1, 2, 4, 7, 14, 30)
  ease: number            // 1.3 - 2.5 (SM-2 Algorithmus)
  repetitions: number     // Anzahl korrekte Reviews in Folge
}

Nach jeder Session:
  - Für jeden geübten Akkord → Performance bewerten
  - avgTime < median × 0.7 → "easy" → Interval verdoppeln
  - avgTime < median × 1.4 → "good" → Interval × ease
  - avgTime > median × 1.4 → "hard" → Interval = 1 Tag
  - Ease adjustieren (SM-2 Algorithmus)
```

---

## 🎨 UI-Konzept

### Setup Screen: Neues Dashboard-Header

**Vorher:**
```
Guten Tag!  🔥 5 day streak    [No MIDI]
Weekly Goal ████████░░ 60%
```

**Nachher:**
```
┌─────────────────────────────────────────────────┐
│  Guten Tag!                      🔥 12 · Lv.7  │
│  Session Player                  [MIDI ✓]       │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │ 📎 Tagesziel: 5 Min Shell Voicings      │    │
│  │ ████████████░░░░░░░░░ 3/5 Min            │    │
│  │                                          │    │
│  │ 🎯 Wochenziel: ii-V-I alle Keys < 3s    │    │
│  │ 8/12 Keys geschafft                     │    │
│  └──────────────────────────────────────────┘    │
│                                                  │
│  Mo Di Mi Do Fr Sa So                            │
│  ✓  ✓  ✓  ·  ·  ·  ·    +35 XP heute           │
│                                                  │
│  ⚡ Quick: "3 Min Db-Fokus"  [Start →]          │
└─────────────────────────────────────────────────┘
```

### Celebrations & Micro-Rewards

| Event | Animation | Sound |
|-------|-----------|-------|
| Session complete | Confetti burst | Chord arpeggio up |
| New Personal Best | Gold glow + "NEW PB!" | Triumph fanfare |
| Streak milestone (7, 14, 30) | Full-screen celebration | Jazz lick |
| Level Up | Level-number morphs + particles | Ascending scale |
| Smart Goal completed | Goal card → gold → checkmark | Achievement chime |
| XP gained | "+10 XP" float-up animation | Subtle click |

### Onboarding: Habit Setup

Beim ersten Öffnen (oder bei Migration von v0.5):

```
Schritt 1: "Wie viel Zeit hast du täglich?"
  [2 Min]  [5 Min]  [10 Min]  [15 Min]

Schritt 2: "Wann übst du am liebsten?"
  [☀️ Morgens]  [🌤️ Nachmittags]  [🌙 Abends]

Schritt 3: "Darf ich dich erinnern?"
  [Ja, bitte!]  [Lieber nicht]
  → Bei Ja: Uhrzeit-Picker

Schritt 4: "Dein erstes Ziel"
  → Auto-generiert basierend auf History (oder Warm-Up für Neue)
```

---

## 📊 Goal-Engine Algorithmus

### Ziel-Generierung

```typescript
function generateGoals(profile: HabitProfile, history: SessionResult[]): SmartGoal[] {
  const goals: SmartGoal[] = [];
  
  // 1. CONSISTENCY (immer dabei wenn Streak < 7)
  if (streak.current < 7) {
    goals.push({
      type: 'consistency',
      title: 'Übe 5 Tage diese Woche',
      target: 5,
      current: weekDaysPracticed,
      xpReward: 25,
    });
  }
  
  // 2. SPEED (basierend auf schwächsten Akkorden)
  const weakest = analyzeWeakChords(history, 1)[0];
  if (weakest && weakest.avgMs > 2500) {
    goals.push({
      type: 'speed',
      title: `Bringe ${weakest.root}-Akkorde unter ${targetTime}s`,
      target: targetTime,
      current: weakest.avgMs / 1000,
      xpReward: 25,
    });
  }
  
  // 3. EXPLORATION (ungenutzte Features)
  const usedVoicings = new Set(history.map(s => s.settings.voicing));
  const allVoicings = ['root','shell','half-shell','full','rootless-a','rootless-b'];
  const unused = allVoicings.filter(v => !usedVoicings.has(v));
  if (unused.length > 0) {
    goals.push({
      type: 'exploration',
      title: `Probiere ${VOICING_LABELS[unused[0]]} aus`,
      target: 1,
      current: 0,
      xpReward: 15,
    });
  }
  
  // 4. REVIEW (Spaced Repetition fällig)
  const dueChords = profile.chordSchedule
    .filter(c => new Date(c.nextReview) <= new Date());
  if (dueChords.length > 3) {
    goals.push({
      type: 'review',
      title: `${dueChords.length} Akkorde warten auf Review`,
      target: dueChords.length,
      current: 0,
      xpReward: 20,
    });
  }
  
  return goals.slice(0, 3); // Max 3 aktive Ziele
}
```

### Ziel-Completion Check

Nach jeder Session werden alle aktiven Ziele geprüft. Erreichte Ziele:
1. XP gutschreiben
2. Celebration-Animation abspielen
3. Ins Archiv verschieben
4. Neues Ziel generieren (nächste Session)

---

## 🔧 Technische Implementation

### Neue Dateien

```
src/lib/engine/
  └── habits.ts           ← Pure engine: Goal-Generierung, XP, Levels, Spaced Rep ✅
  └── habits.test.ts      ← 46 Unit-Tests ✅

src/lib/services/
  └── habits.ts           ← localStorage Persistence, Notification Scheduling ✅
  (notifications.ts in habits.ts integriert — kein separates File nötig)

src/lib/services/
  └── audio.ts            ← playCelebrationSound() für Micro-Reward Sounds ✅

src/lib/components/
  └── HabitDashboard.svelte    ← Neues Dashboard (ersetzt Weekly Goal) ✅
  └── HabitOnboarding.svelte   ← Ersteinrichtung (4 Steps) ✅
  └── GoalCard.svelte          ← Einzelnes Ziel mit Progress ✅
  └── LevelBadge.svelte        ← Level + XP Anzeige ✅
  └── CelebrationOverlay.svelte ← Konfetti, Level-Up, Sounds ✅
  (QuickStart.svelte in HabitDashboard integriert — kein separates File nötig)

static/
  └── sw.js               ← Service Worker für Notifications ✅
```

### localStorage Keys

```
chord-trainer-habit-profile    → HabitProfile (enthält XP, Goals, Schedule, Config)
chord-trainer-celebrations      → CelebrationEvent[] (pending, nicht gezeigt)
```

> XP, Goals und ChordSchedule sind im HabitProfile konsolidiert — keine separaten Keys nötig.

### Migration

Bestehende Daten (Streak, History) werden beim ersten Load in das neue System migriert:
- Streak → bleibt, wird in HabitProfile integriert
- Session History → XP retroaktiv berechnet (vereinfacht: 10 XP/Session)
- Weekly Goal UI → ersetzt durch HabitDashboard

---

## 📋 Implementation Reihenfolge

Alle Schritte abgeschlossen:

1. ✅ **habits.ts** (Engine) — Types, XP-Berechnung, Goal-Generierung, Level-System
2. ✅ **habits service** (Persistence) — localStorage, Load/Save, Migration
3. ✅ **HabitDashboard** — Neues Dashboard-Widget (ersetzt Weekly Goal)
4. ✅ **GoalCard + LevelBadge** — UI-Komponenten
5. ✅ **CelebrationOverlay** — Micro-Rewards Visual + Sounds
6. ✅ **QuickStart** — In HabitDashboard integriert
7. ✅ **sw.js** — Push Notifications (Service Worker)
8. ✅ **HabitOnboarding** — Ersteinrichtung für neue Nutzer
9. ✅ **Integration** in train/+page.svelte
10. ✅ **i18n** — Alle Strings in EN + DE (~80 Keys)

### Design-Entscheidungen vs. Spec

| Spec-Element | Entscheidung |
|---|---|
| `practiceAnchor` (Freitext) | Feld existiert im Type, Onboarding fragt es nicht ab — overcomplicates UX, Erinnerungen funktionieren ohne |
| `notifications.ts` separates File | In `services/habits.ts` integriert — zu wenig Code für eigenes Modul |
| `QuickStart.svelte` separates File | In HabitDashboard eingebaut — gehört inhaltlich zusammen |
| Max 3 Goals gleichzeitig | Auf 2 reduziert (CPO Review) — weniger Cognitive Load |
| Goal-Descriptions | Entfernt (CPO Review) — Titel reicht, spart vertikalen Platz |

---

## 🎯 Erfolgsmetriken

| Metrik | Vorher (geschätzt) | Ziel |
|--------|-------------------|------|
| Retention Day 7 | ~15% | 40% |
| Retention Day 30 | ~5% | 20% |
| Sessions/Woche/User | 2.1 | 4.5 |
| Avg Session Length | 3.5 Min | 6 Min |
| Streak > 7 Tage | ~8% der User | 25% |
| Notification Opt-In | 0% (existiert nicht) | 35% |

---

*"We are what we repeatedly do. Excellence is not an act, but a habit."* — Aristoteles (via Will Durant)
