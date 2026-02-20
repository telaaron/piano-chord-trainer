# QA Checklist — New Features (Feb 2026)

Everything that needs to work before we ship. Check off items as they pass.

---

## 0. MIDI Grundfunktion

> **Blocker — solange MIDI nicht geht, kann nichts anderes getestet werden.**

- [ ] **MIDI Test Page** (`/midi-test`): Seite laden, Keyboard anschließen
- [ ] Gerät wird erkannt und angezeigt
- [ ] Note-On Events erscheinen im Log (grüner Text)
- [ ] Note-Off Events erscheinen im Log (grauer Text)
- [ ] Live-Keyboard zeigt gedrückte Tasten in Echtzeit (grün)
- [ ] Pitch-Class-Grid unten leuchtet auf
- [ ] "Held Now"-Counter stimmt mit gedrückten Tasten überein
- [ ] **Train → normaler Modus**: Chord spielen → grüne Tasten auf dem Keyboard
- [ ] Korrekt gespielter Chord → "✓ Correct!" + auto-advance nach 400ms
- [ ] Falscher Chord → rote Tasten für falsche Noten
- [ ] MIDI Accuracy am Ende der Session > 0%
- [ ] Nach Session-Ende: MIDI bleibt verbunden (kein Disconnect)

---

## 1. Voice Leading Flow

> **Konzept (neu):** Wenn Voice Leading aktiv ist, wird jeder Chord ab dem 2. so umgeordnet,
> dass er minimale Stimmführungsbewegung zum vorherigen Chord hat.
> Common Tones bleiben auf derselben Taste (pitch class), andere Stimmen
> bewegen sich minimal. Die Keyboard-Anzeige zeigt das korrekt.

- [ ] Plan "Voice Leading Flow" starten
- [ ] **Erster Chord**: normales Voicing, kein Voice-Leading-Highlight
- [ ] **Ab 2. Chord**: Voicing ist umgeordnet (z.B. Shell Dm7 → G7: gemeinsame Töne bleiben)
- [ ] Common Tones sind **gold/amber** mit glow (deutlich sichtbar!)
  - [ ] Weiße Tasten: goldgelb mit Ring + Schatten
  - [ ] Schwarze Tasten: goldgelb mit hellem Border + Glow
- [ ] **Neue Töne** (bewegt): **blau** hervorgehoben
  - [ ] Weiße Tasten: hellblau mit Ring
  - [ ] Schwarze Tasten: blau mit hellem Border
- [ ] Voice-Leading-Text unter dem Chord-Namen (z.B. "F stays, C → B (↓1)")
- [ ] Voice Leading manuell an/aus-toggeln in GameSettings funktioniert
- [ ] VL im Random-Modus (nicht nur 2-5-1)
- [ ] MIDI-Erkennung mit voice-led Voicing: korrekt gespieltes umgeordnetes Voicing wird erkannt

---

## 2. In-Time Comping

- [ ] Plan "In-Time Comping" starten
- [ ] Metronom startet automatisch bei 100 BPM
- [ ] Bar-Counter sichtbar (z.B. "Bar 1/2")
- [ ] **Stoppuhr ist versteckt** (In-Time braucht keine Zeitanzeige)
- [ ] Chord wechselt automatisch nach 2 Bars (auf Beat 1 von Bar 3)
- [ ] **Mit MIDI**: gedrückte Tasten werden sofort angezeigt (grün/rot)
- [ ] **Mit MIDI**: nach Chord-Wechsel werden gehaltene Noten neu gegen neuen Chord geprüft
- [ ] **Ohne MIDI**: Session soll trotzdem durchlaufen (Chords wechseln automatisch)
- [ ] Skip-Button / Space zum Überspringen
- [ ] Results: "Avg. Timing: Xms" wird angezeigt (nicht "N/A")
- [ ] Results: MIDI Accuracy wird korrekt angezeigt
- [ ] In-Time manuell an/aus in GameSettings
- [ ] Bars per Chord (1, 2, 4) einstellbar und wirksam

---

## 3. Adaptive Drill

- [ ] Plan "Adaptive Drill" starten
- [ ] **Ohne History**: verhält sich wie normaler Random-Modus (kein Crash)
- [ ] **Mit History** (nach ein paar Sessions): schwache Chords erscheinen öfter
- [ ] Adaptive + 2-5-1: wird ignoriert (kein Crash, Hinweis wäre nice)
- [ ] Adaptive manuell an/aus in GameSettings

---

## 4. Ear Training (Ear Check)

- [ ] Plan "Ear Check" starten
- [ ] Ear Training Screen öffnet sich (nicht der normale Playing-Screen)
- [ ] Chord wird **abgespielt** aber Name ist **versteckt** (🎧 Icon)
- [ ] "Listen Again"-Button funktioniert
- [ ] "Reveal"-Button zeigt Chord-Namen
- [ ] **Mit MIDI**: korrektes Spielen zählt als richtig + auto-advance
- [ ] **Mit MIDI**: falsches Spielen → kein Advance (aktuell kein Feedback-Sound — see TODO)
- [ ] Results: "Ear Score: X%" wird angezeigt
- [ ] Ear Training Button in GameSettings funktioniert
- [ ] Space/Escape-Handling auf dem Ear Training Screen

---

## 5. Neue Übungspläne

- [ ] Alle 4 neuen Plans sichtbar auf der Setup-Seite:
  - [ ] 🎶 In-Time Comping
  - [ ] 👂 Ear Check
  - [ ] 🧠 Adaptive Drill
  - [ ] 🔗 Voice Leading Flow
- [ ] Jeder Plan startet korrekt mit den richtigen Settings
- [ ] Plan-Icons werden angezeigt (keine fehlenden Bilder)

---

## 6. GameSettings UI

- [ ] Aufklappen → neue Sections sichtbar:
  - [ ] In-Time Mode Toggle
  - [ ] Bars per Chord (1/2/4) — nur sichtbar wenn In-Time an
  - [ ] Adaptive Difficulty Toggle
  - [ ] Voice Leading Toggle
  - [ ] Ear Training Button
- [ ] Toggles binden korrekt (Änderung wirkt sich auf Session aus)
- [ ] Settings werden nach Reload NICHT persistiert (known limitation — TODO)

---

## 7. Results Screen

- [ ] Standard-Session: keine neuen Stats (nur die bekannten)
- [ ] In-Time Session: "Avg. Timing" Block wird angezeigt
- [ ] Ear Training Session: "Ear Score" Block wird angezeigt
- [ ] Beide zusammen: geht das? (Edge case)

---

## 8. PianoKeyboard allgemein

- [ ] MIDI-Farben (grün/rot) funktionieren auf weißen Tasten
- [ ] MIDI-Farben funktionieren auf schwarzen Tasten
- [ ] Voice-Leading-Farben überlagern MIDI-Farben NICHT (MIDI hat Vorrang)
- [ ] Mini-Keyboard in Results: keine crashes

---

## 9. Regressions

- [ ] Normaler Speed Run ohne MIDI: funktioniert wie vorher
- [ ] 2-5-1 Progression: Chords stimmen
- [ ] Custom Progression Editor: funktioniert
- [ ] Embed-Route `/embed`: funktioniert
- [ ] Metronom an/aus im normalen Modus: funktioniert
- [ ] Alle Sound-Presets: funktionieren

---

## Verbesserungen / TODOs

> Dinge die noch fehlen oder besser sein könnten.

### Prio 1 — sollte bald rein
- [x] **MIDI Bug fixen**: War ein temporäres Problem, MIDI funktioniert wieder
- [ ] **In-Time ohne MIDI**: Session endet nie, weil Chords nicht als "gespielt" gelten → Chords automatisch als korrekt werten (nur Timing tracken) ODER "Done"-Button pro Chord
- [ ] **Ear Training Feedback**: Kein visuelles/akustisches Feedback bei falschem Spielen → roter Flash oder "Wrong"-Ton
- [ ] **Settings persistieren**: `inTimeMode`, `inTimeBars`, `adaptiveEnabled`, `voiceLeadingEnabled` werden nach Reload vergessen → `SavedSettings` in `progress.ts` erweitern

### Prio 2 — nice to have
- [ ] **Voice Leading bei Root-Voicings**: VL-Anzeige deaktivieren/dimmen bei Root-Voicings (Oktavsprünge verzerren die Analyse) — **teilweise gelöst**: voice-led voicings rearrangieren jetzt automatisch
- [ ] **Bar-Counter Sichtbarkeit**: In-Time Bar-Counter auch anzeigen wenn Metronom-Section collapsed
- [ ] **Ear Training + 2-5-1**: Warnung wenn Ear Training mit Progressions (statt Random) gestartet wird
- [ ] **Metronom Bluetooth-Latenz**: Beat 1 vs andere Beats: unterschiedliche Lautstärke ist DESIGN (Akzent auf 1), aber Bluetooth verursacht zusätzliche Artefakte → nicht fixbar, USB empfehlen

### Prio 3 — Qualität
- [ ] **Unit Tests**: `voice-leading.test.ts` und `adaptive.test.ts` schreiben (Pattern von `chords.test.ts` folgen)
- [ ] **MIDI Test Page**: Nav-Link nach QA entfernen oder hinter Feature-Flag verstecken
- [ ] **Bluetooth Audio Latenz**: Metronom-Lautstärke-Bug mit Bluetooth Lautsprechern (reported by user)
- [ ] **In-Time "Skip" Logik**: Klären ob Skip in In-Time Sinn macht (aktuell: ja, zählt als verpasst)
