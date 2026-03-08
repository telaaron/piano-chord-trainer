# Chord Trainer – Feature-Dokumentation

> Vollständige Aufstellung aller implementierten Features.
> **Stand:** März 2026 · **Version:** 0.5.0

---

## Kern-Feature: Speed-Drill Trainer (`/train`)

Das Herzstück der App. Setup → Spielen → Ergebnis.

### Akkord-Anzeige und Eingabe
- **ChordCard** mit Akkord-Name, Voicing-Label, Formel (1-3-7 etc.)
- **PianoKeyboard** (2–3 Oktaven, dynamisch) zeigt erwartete Noten
- **3 Eingabe-Modi:** MIDI-Keyboard, Mikrofon (Audio-Input), Click-Piano (Maus/Touch)
- **Auto-Advance** nach korrektem Match (400ms Verzögerung)
- **Space/Enter** zum Überspringen

### Voicing-System (9 Typen)

| Voicing | Noten | Level |
|---------|-------|-------|
| Root Position | Alle Akkordtöne | Beginner |
| Shell | Root + 3 + 7 | Beginner |
| Half-Shell | 3 + 7 (ohne Root) | Intermediate |
| Full | Alle Erweiterungen | Intermediate |
| Rootless A | 3-5-7-9 | Advanced |
| Rootless B | 7-9-3-5 | Advanced |
| Inversion 1/2/3 | Umkehrungen | Advanced |

### 16 Akkord-Qualitaeten

Maj7, 7, m7, m7b5, dim7, 6, m6, Maj9, 9, m9, 6/9, Maj7#11, 7#9, 7b9, m11, 13

### 3 Notation-Systeme
- Standard: CMaj7, Dm7, G7
- Symbols: C(Triangle)7, D-7, G7
- Short: CM7, Dm7, G7

### Progressions-Modi

| Modus | Beschreibung |
|-------|-------------|
| Random | Zufällig aus Difficulty-Pool |
| ii-V-I | 36 Akkorde durch Quartenzirkel |
| Cycle of 4ths | 12 Keys mit einem Typ |
| I-vi-ii-V | 48 Akkorde Turnaround |
| Custom | Eigene Stufenakkorde im Editor |

### Difficulty-Level
- **Beginner:** Maj7, 7, m7, m7b5, dim7 (5 Typen)
- **Intermediate:** + 6, m6, Maj9, 9 (9 Typen)
- **Advanced:** + m9, 6/9, Maj7#11, 7#9, 7b9 (14 Typen)

---

## Kurs-System (`/learn`)

### 4 Kurse

**Intervals** (Beginner)
- Intervall-Erkennung: Terzen, Quarten, Quinten, Tritone etc.
- 3-Phasen-Lernen: Guided → Find → Mastery
- Guided: Beide Noten angezeigt, Student spielt nach
- Find: Nur Root + Intervall-Name, Student findet Ziel-Note
- Free/Mastery: Ohne Hilfe, Pool fehlerfrei durchspielen
- Pool-Shuffle bei Phasenwechsel (Fisher-Yates)

**Shell Voicings** (Beginner)
- Root + 3rd + 7th fuer Maj7, Dom7, m7
- Theory → Practice → Challenge Flow
- Challenge: alle 12 Keys, Speed-Drill mit Mastery-Kriterium

**Scale Degrees** (Intermediate)
- Diatonische Stufenakkorde, Roemische Ziffern
- 7 Lektionen ueber alle Stufen

**Ultimate Plan** (Comprehensive)
- 6 Module, 18+ Lektionen
- Vollstaendiger Beginner-to-Master-Weg

### Lektions-Ablauf (3 Steps)
1. **Theory:** Erklaerung, Beispiel-Akkord, Formel, Piano-Vorschau
2. **Practice:** Gefuehrtes Spielen (Guided → Find → Free)
3. **Challenge:** Speed-Drill ueber alle Keys, Timer, Mastery-Bewertung (A–F)

### Kurs-Fortschritt
- Pro Lektion: abgeschlossene Steps + Challenge-Ergebnisse
- MasteryLevel: none → started → completed → mastered
- Persistenz in localStorage

---

## MIDI-System

### Device-Management
- Automatische Erkennung via Web MIDI API
- **Persistente Geraeteauswahl** (ueberlebt Browser-Restart)
- **Geraete ausblenden** (Hide/Unhide pro Device)
- **Alle einblenden** Button wenn versteckte Geraete existieren
- **Virtual-Port-Filter:** macOS IAC, MIDI Through, Microsoft GS automatisch versteckt
- Hot-Plug-Support, Auto-Reconnect

### Matching-Modi
- **Strict:** Pitch-Class-basiert, keine Extra-Noten
- **Lenient:** Extra-Noten toleriert
- **Bass-Matching:** Strict + unterste Note muss Bass sein

### MIDI-Test-Seite (`/midi-test`)
- Live-Keyboard-Anzeige aller gedrueckten Tasten
- Note On/Off Event-Log
- Pitch-Class-Grid
- Held-Now-Counter
- Mikrofon-Status
- Hidden-Device-Management

---

## Audio-System

### Synthese (Tone.js)
- **PolySynth** (triangle8) fuer Akkord-Playback
- **MembraneSynth** fuer Metronom-Click
- **Transport** fuer BPM-basiertes Timing
- Celebration-Sounds

### Mikrofon-Input (@spotify/basic-pitch)
- ML-basierte Pitch-Erkennung
- States: idle → requesting → loading-model → listening → analyzing
- MIDI-Ersatz fuer iOS-Kompatibilitaet

### MIDI-Sound (midi-sound.ts)
- Audio-Output fuer eingehendes MIDI
- Note On/Off + Control Change Support

---

## Habit-Engine und Gamification

### XP-System
- Session abgeschlossen: +10 XP
- Akkord unter Personal Best: +2 XP
- Streak-Tag: +5 XP mal Streak-Multiplikator
- Smart Goal erreicht: +25 XP
- Streak-Multiplikator: 1.0x (Tag 1-7) bis 2.0x (Tag 31+)

### Level-System (Jazz-thematisch)
- Level = floor(sqrt(totalXP / 50))
- Titel: Zuhoerer → Einsteiger → Schueler → Sideman → Club-Musiker → ... → Monk Status (Lv.50)

### Smart Goals
- Dynamisch generiert basierend auf Performance
- Typen: Speed, Consistency, Mastery, Exploration, Endurance, Review
- Max 2 aktive Ziele gleichzeitig

### Habit-Dashboard
- XP + Level + Streak-Anzeige
- Tages-/Wochenziele mit Fortschritt
- Wochentags-Tracker (Mo–So)
- Quick-Start-Empfehlung

### Spaced Repetition
- SM-2-basiert fuer schwache Akkorde
- Intervalle: 1, 2, 4, 7, 14, 30 Tage
- Performance-basierte Ease-Adjustierung

### Celebrations
- Confetti (Session complete)
- Gold Glow (Personal Best)
- Full-Screen (Streak-Milestone)
- Level-Up Animation
- Float-Up XP-Counter

### Onboarding
- 4-Step-Wizard: Tageszeit → Dauer → Erinnerung → Erstes Ziel
- Automatische Migration bestehender Daten

---

## Uebungsplaene

| Plan | Beschreibung |
|------|-------------|
| Shell Basics | Shell Voicings, Beginner |
| ii-V-I Mastery | Durch alle 12 Keys |
| Full Voicing Workout | Alle Erweiterungen |
| In-Time Comping | Mit Metronom, Bar-basiert |
| Ear Check | Akkord hoeren + erkennen |
| Adaptive Drill | Schwache Akkorde gewichtet |
| Voice Leading Flow | Optimierte Stimmfuehrung |

---

## Voice Leading

- Automatische Stimmfuehrungsanalyse (Common Tones, minimale Bewegung)
- Farbcode: Gold/Amber = Common Tones, Blau = neue Noten
- Voice-Leading-Text: "F stays, C → B"
- Aktivierbar pro Session

---

## Adaptive Difficulty

- Timing-basierte Performance-Analyse pro Akkord
- Schwache Akkorde erscheinen haeufiger im Pool
- Performance-Summary fuer UI

---

## Custom Progressions

- Progression Editor: Stufenakkorde per GUI
- Tonart + Modus waehlbar (Dur/Moll/Dorisch/etc.)
- Progression Player mit Loop
- Ergebnisse pro Progression

---

## i18n (Internationalisierung)

- **2 Sprachen:** Deutsch (Standard) + Englisch
- **~1460 Keys** pro Sprache
- **Locale-Toggle** in Navigation
- **t(key, params?)** Funktion mit Punkt-Pfad + Parameter-Interpolation
- **Fallback:** Englisch wenn Key fehlt
- **Persistenz:** localStorage

---

## UI/UX

### Themes
- Dark Mode (Standard), weitere via data-theme
- Persistenz in localStorage

### Responsive Design
- Mobile-first, Click-Piano als MIDI-Ersatz
- Breakpoints: sm (640), md (768), lg (1024)

### Accessibility
- 0 svelte-check a11y Warnings
- role=button + tabindex + aria-label auf interaktiven Keys
- Keyboard-Navigation (Enter/Space) fuer Piano-Keys

### Navigation
- Tabs: Train, Learn, For Educators
- Locale-Toggle (DE/EN)
- Responsive Nav mit Mobile-Menu

---

## Embed-Modus (`/embed`)

- iFrame-faehig (eigenes Layout ohne Nav/Footer)
- Query-Parameter fuer Presets
- Grundlage fuer B2B-Integration

---

## Technischer Stack

| Technologie | Version | Zweck |
|------------|---------|-------|
| SvelteKit | 2.5.x | Framework |
| Svelte | 5.x | UI (Runes: $state, $derived, $props, $effect) |
| TypeScript | 5.5.x | Typsicherheit |
| Tailwind CSS | 4.x | Styling (@tailwindcss/vite) |
| Tone.js | 15.x | Audio-Synthese |
| @spotify/basic-pitch | 1.x | ML Pitch-Detection |
| lucide-svelte | 0.525.x | Icons |
| Vitest | 3.2.x | Testing (4 Dateien, 132+ Tests) |
| Vercel | — | Hosting + Edge SSR |

---

## Noch NICHT gebaut

- [ ] Benutzerkonten (Cloud-Sync)
- [ ] Social Features (Ranglisten, Friends)
- [ ] Backing Tracks
- [ ] Progression Recording
- [ ] Mobile App (Native)
- [ ] Lesson-Context-API (B2B postMessage)
- [ ] Mehr Kurse (Rootless Voicings, Rhythmisches Training)
- [ ] Audio Recognition auf iOS (ohne Web MIDI)

---

## Zahlen-Cheatsheet

| Was | Wert |
|-----|------|
| Akkord-Qualitaeten | 16 |
| Voicing-Typen | 9 |
| Progressions-Modi | 4 + Custom |
| Kurse | 4 |
| Components | 18 |
| Engine-Module | 12 + 4 Tests |
| Services | 8 |
| i18n-Keys | ~1460 pro Sprache |
| Routes | 12 |
| localStorage-Keys | ~10 |
| Test-Dateien | 4 (132+ Assertions) |
| Runtime-Dependencies | 3 |
| DevDependencies | 14 |

---

*Zuletzt aktualisiert: Maerz 2026*
