# Chord Trainer – Feature-Inventar

> **Zweck:** Verbindliche Referenz für das, was TATSÄCHLICH funktioniert.  
> **Regel:** Nur Features listen, die im Code implementiert und vom User erreichbar sind.  
> **Zuletzt geprüft gegen Code:** 17. Februar 2026

---

## ✅ Live Features (v0.5.0)

### Training-Modi

| Feature | Details | Erreichbar via |
|---------|---------|----------------|
| **Random Mode** | Zufällige Akkorde aus gewähltem Difficulty-Pool | Settings → Modus |
| **ii-V-I Drill** | 36 Akkorde (3 × 12 Keys im Quartenzirkel) | Settings → Modus |
| **Cycle of 4ths** | 12 Keys, ein Akkord-Typ rotiert | Settings → Modus |
| **I-vi-ii-V Turnaround** | 48 Akkorde (4 × 12 Keys) | Settings → Modus |
| **Custom Progressions** | Freie Akkord-Sequenz, Metronom-Loop, Evaluierung | Button auf Setup |

### Akkord-Typen (15 spielbar)

| Level | Typen | Anzahl |
|-------|-------|--------|
| **Beginner** | Maj7, 7, m7, 6, m6 | 5 |
| **Intermediate** | + Maj9, 9, m9, 6/9 | 9 |
| **Advanced** | + Maj7#11, 7#9, 7b9, m11, 13 | 14 |
| *Engine-definiert* | + m7b5 (wird bei ii-V-I/progressions verwendet) | 15 |

> **Hinweis:** `dim7` ist im Code definiert (Intervalle vorhanden) aber in keinem Difficulty-Pool — Spieler können ihn im normalen Spiel nicht erreichen. Siehe [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md#-dim7-ist-nur-halb-implementiert).

### Voicings (9 Typen)

| Voicing | Kürzel | Was gespielt wird | Wer nutzt das? |
|---------|--------|-------------------|----------------|
| Root Position | `root` | Alle Noten, Root im Bass | Anfänger |
| Shell | `shell` | Root + 3rd + 7th | Jazz-Combo-Spieler |
| Half-Shell | `half-shell` | 3rd + Root + 7th | Voice Leading |
| Full | `full` | Root + 7th + 3rd + 5th (open) | Fortgeschrittene |
| Rootless A | `rootless-a` | 3-5-7-9 (Bill Evans) | Jazz-Pianisten |
| Rootless B | `rootless-b` | 7-9-3-5 | Komplementär zu A |
| 1. Umkehrung | `inversion-1` | 3rd im Bass | Repertoire |
| 2. Umkehrung | `inversion-2` | 5th im Bass | Repertoire |
| 3. Umkehrung | `inversion-3` | 7th im Bass | Repertoire |

### MIDI-Integration

| Feature | Status | Einschränkung |
|---------|--------|---------------|
| Keyboard-Erkennung | ✅ | Nur Chrome/Edge Desktop |
| Multi-Device-Auswahl | ✅ | — |
| Hot-Plug (Gerät jederzeit anstecken) | ✅ | — |
| Auto-Detection beim Start | ✅ | — |
| Echtzeit-Feedback (grün/rot) | ✅ | — |
| Lenient Matching (Oktav-tolerant) | ✅ | Extra-Noten werden toleriert |
| Auto-Advance bei richtigem Akkord | ✅ | 400ms Delay |
| Accuracy-Score pro Session | ✅ | — |
| **Firefox/Safari** | ❌ | Web MIDI API nicht unterstützt |
| **Mobile** | ❌ | Web MIDI API nicht unterstützt |

### Audio

| Feature | Status | Details |
|---------|--------|---------|
| Chord-Playback | ✅ | Tone.js PolySynth (triangle8) |
| Auto-Play bei neuem Akkord | ✅ | — |
| Anhören-Button (Replay) | ✅ | — |
| Audio On/Off Toggle | ✅ | Während der Session |
| Metronom | ✅ | 40–240 BPM, Akzent auf Beat 1 |
| Visueller Beat-Indicator | ✅ | 4 Dots, synchron |
| **Piano Samples** | ❌ | Synth-Sound, keine echten Samples |

### Progress Tracking

| Feature | Status | Speicherort |
|---------|--------|-------------|
| Session-History | ✅ | localStorage (max 100) |
| Settings-Persistenz | ✅ | localStorage |
| Tägliche Streaks | ✅ | localStorage |
| Best-Streak | ✅ | localStorage |
| Bestzeiten pro Kombination | ✅ | Difficulty × Voicing × Modus |
| Schwachstellen-Analyse | ✅ | Langsamste Root-Noten |
| Verbesserungs-Trends | ✅ | Vergleich letzte 5 vs. ältere |
| Sparkline (letzte 10 Sessions) | ✅ | Im Dashboard |
| **Cloud-Sync** | ❌ | Nur lokal, kein Account-System |
| **Multi-Device** | ❌ | Daten nur auf einem Gerät |

### Übungspläne (9 Stück)

| Plan | Beschreibung | Key-Settings |
|------|-------------|-------------|
| Warm-Up | Einspielen, Grundlagen | Shell, ii-V-I, 12 Keys |
| Speed Run | Tempo-Training | Root Position, Random, Auf Zeit |
| ii-V-I Deep Dive | Standard-Progression | Full Voicings, alle 12 Keys |
| Turnaround | I-vi-ii-V | Shell, alle Keys |
| Challenge | Erweitertes Vokabular | Advanced, Symbole, Noten aus |
| Quartenzirkel | Tonarten-Flüssigkeit | Half-Shell, ♭-Keys |
| Voicing Drill | Muscle Memory | Root Position, ii-V-I |
| Left-Hand Comping | Linke-Hand-Begleitung | Rootless A, ii-V-I |
| Umkehrungen | Inversions in allen Keys | Inversion 1, Cycle of 4ths |

### Custom Progressions

| Feature | Status |
|---------|--------|
| Freie Akkord-Eingabe (Text) | ✅ |
| Live-Parsing-Preview | ✅ |
| BPM-Einstellung (40–240) | ✅ |
| Loop-Count (1–4 + ∞) | ✅ |
| 7 Jazz-Presets | ✅ |
| Speichern/Laden (max 50) | ✅ |
| Metronom-gesteuerte Wiedergabe | ✅ |
| Per-Chord MIDI-Evaluierung | ✅ |
| Grade-System (A–F) | ✅ |
| Schwachstellen pro Loop | ✅ |

**Preset-Standards:** Autumn Leaves, All of Me, Blue Bossa, Rhythm Changes, 12-Bar Blues, So What, Satin Doll

### Notation & Display

| Feature | Optionen |
|---------|----------|
| Notation-System | International, Deutsch (H/B) |
| Notation-Stil | Standard (Maj7), Symbole (Δ7), Short (M7) |
| Vorzeichen | Sharps (#), Flats (♭), Gemischt |
| Noten-Anzeige | Aus, Immer an, Verify (nach Tastendruck) |
| Akkord-Anzahl | 6, 12, 24, 36 |
| Piano-Keyboard | 2 Oktaven, responsive, Root-Punkt |

### UI & Design

| Feature | Status |
|---------|--------|
| Dark Theme | ✅ (Standard: "Warm Jazz Club") |
| Theme-System (2 Themes) | ⚠️ Infrastruktur vorhanden, Open Studio CSS fehlt |
| Responsive (Mobile → Desktop) | ✅ |
| Svelte Transitions (fade/fly/scale) | ✅ |
| Landing Page mit 3D-Video | ✅ |
| For Educators (B2B-Seite) | ✅ |
| Open Studio Pitch-Seite | ✅ |
| Impressum + Datenschutz | ✅ |
| PWA Manifest | ✅ (Add-to-Homescreen) |

---

## ❌ Noch NICHT gebaut

> Diese Features tauchen in Docs/Plänen auf, existieren aber **nicht im Code**.

| Feature | Erwähnt in | Status |
|---------|-----------|--------|
| Cloud-Sync (Supabase) | BUSINESS.md, AGENT_HANDOFF | Nicht begonnen |
| Benutzer-Accounts / Login | BUSINESS.md | Nicht begonnen |
| Freemium-Gating (Free vs Pro) | BUSINESS.md | Nicht begonnen |
| Stripe-Integration | BUSINESS.md | Nicht begonnen |
| iframe Embed-Modus | BUSINESS.md | Nicht begonnen |
| WordPress Plugin | BUSINESS.md | Nicht begonnen |
| Lesson-Context-API | BUSINESS.md | Nicht begonnen |
| Ear Training Mode | AGENT_HANDOFF | Nicht begonnen |
| Voice Leading Highlights | AGENT_HANDOFF | Nicht begonnen |
| Piano Samples (statt Synth) | AGENT_HANDOFF | Nicht begonnen |
| Light Mode | DECISIONS.md | Bewusst nicht gebaut |
| i18n / Mehrsprachigkeit | DECISIONS.md | Bewusst nicht gebaut |
| Unit Tests | — | Infrastruktur da, 0 Tests |
| CI/CD Pipeline | — | Kein GitHub Actions Workflow |

---

## Zahlen-Cheatsheet (für Marketing)

> Verwende diese Zahlen — sie sind gegen den Code verifiziert.

| Metrik | Wert | Anmerkung |
|--------|------|-----------|
| Akkord-Typen | **15** | 15 in Spieler-Pools erreichbar (16 definiert, 1 unreachable) |
| Voicing-Typen | **9** | Alle implementiert und wählbar |
| Übungspläne | **9** | One-Tap-Presets |
| Progressions-Modi | **4** | Random, ii-V-I, Cycle of 4ths, I-vi-ii-V |
| Jazz-Presets | **7** | Custom Progressions mit echten Standards |
| Training-Keys | **12** | Alle Tonarten |
| Notation-Systeme | **2** | International + Deutsch |
| Notation-Stile | **3** | Standard, Symbole, Short |

---

*Dieses Dokument wird bei jedem Release gegen den Code geprüft.*
