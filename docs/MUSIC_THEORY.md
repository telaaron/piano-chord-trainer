# Chord Trainer – Musiktheorie-Referenz

> Erklaert die musiktheoretischen Konzepte hinter der App.
> **Stand:** Maerz 2026

---

## Chromatische Skala

12 Halbtoene pro Oktave. Jeder Ton hat einen Index (Semitone):

```
C=0  C#/Db=1  D=2  D#/Eb=3  E=4  F=5  F#/Gb=6  G=7  G#/Ab=8  A=9  A#/Bb=10  B=11
```

Die App unterstuetzt zwei Schreibweisen:
- **Sharps:** C, C#, D, D#, E, F, F#, G, G#, A, A#, B
- **Flats:** C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B

Plus eine enharmonische Zuordnung (z.B. C# = Db).

---

## Intervalle

Ein Intervall ist der Abstand zwischen zwei Toenen, gemessen in Halbtoenen:

| Halbtoene | Intervall-Name | Kurzform |
|-----------|---------------|----------|
| 0 | Unisono (Prime) | P1 |
| 1 | Kleine Sekunde | m2 |
| 2 | Grosse Sekunde | M2 |
| 3 | Kleine Terz | m3 |
| 4 | Grosse Terz | M3 |
| 5 | Reine Quarte | P4 |
| 6 | Tritonus | TT |
| 7 | Reine Quinte | P5 |
| 8 | Kleine Sexte | m6 |
| 9 | Grosse Sexte | M6 |
| 10 | Kleine Septime | m7 |
| 11 | Grosse Septime | M7 |
| 12 | Oktave | P8 |

### Intervalle in der App

Der Intervall-Kurs trainiert die Faehigkeit, Intervalle auf dem Klavier zu finden:

- **IntervalSpec:** Definition eines Intervalls mit Root, Target, Label und Semitones
- **3-Phasen-Lernen:**
  - **Guided:** Beide Noten (Root + Target) sind auf dem Keyboard angezeigt
  - **Find:** Nur der Root ist sichtbar + der Intervall-Name → Student muss die Ziel-Note selbst finden
  - **Mastery:** Ohne Hilfe, Pool fehlerfrei durchspielen

---

## Akkord-Aufbau

Ein Akkord besteht aus Intervallen uebereinander, gemessen vom Grundton (Root):

### Die 16 Akkord-Typen

| Qualitaet | Intervalle | Funktion |
|-----------|-----------|----------|
| Maj7 | 0-4-7-11 | Tonika (Dur) |
| 7 | 0-4-7-10 | Dominante |
| m7 | 0-3-7-10 | Subdominante/Tonika (Moll) |
| m7b5 | 0-3-6-10 | Halbvermindert (Locrian) |
| dim7 | 0-3-6-9 | Vollvermindert |
| 6 | 0-4-7-9 | Tonika-Variante |
| m6 | 0-3-7-9 | Moll-Tonika-Variante |
| Maj9 | 0-4-7-11-14 | Erweiterter Dur |
| 9 | 0-4-7-10-14 | Erweiterte Dominante |
| m9 | 0-3-7-10-14 | Erweiterter Moll |
| 6/9 | 0-4-7-9-14 | Erweiterte Tonika |
| Maj7#11 | 0-4-7-11-18 | Lydisch |
| 7#9 | 0-4-7-10-15 | Hendrix-Akkord |
| 7b9 | 0-4-7-10-13 | Alterierte Dominante |
| m11 | 0-3-7-10-14-17 | Moll mit 11 |
| 13 | 0-4-7-10-14-21 | Dominante mit 13 |

---

## Voicings

Ein Voicing bestimmt, WELCHE Toene eines Akkords gespielt werden und in welcher Lage:

### Shell Voicing (3 Noten)
- Root + 3rd + 7th
- Beispiel: CMaj7 Shell = C + E + B
- Reduziert auf den Kern: Grundton und die zwei Toene, die die Qualitaet definieren (Terz und Septime)
- Ideal fuer Begleitung in der linken Hand

### Half-Shell (2 Noten)
- 3rd + 7th (ohne Root)
- Der Bass spielt den Grundton, Pianist braucht ihn nicht
- Guide Tones: Die zwei wichtigsten Toene jedes Akkords

### Root Position (alle Noten)
- Alle Akkordtoene in Grundstellung
- Lernformat, praktisch wenig verwendet im Jazz

### Full Voicing
- Alle Erweiterungen (9, 11, 13 etc.)
- Dichter Klang, alle verfuegbaren Toene

### Rootless A und B
- Fortgeschrittene linke-Hand-Voicings ohne Grundton
- **A-Form:** 3-5-7-9
- **B-Form:** 7-9-3-5
- Standard in Combo-Spiel (Bass uebernimmt Root)

### Inversions (1, 2, 3)
- Umkehrungen: verschiedene Toene als tiefstem Ton
- Wichtig fuer Voice Leading

---

## Stufenakkorde (Scale Degrees)

Jede Tonleiter erzeugt 7 diatonische Akkorde:

### Dur-Tonleiter

| Stufe | Roemisch | Qualitaet | Beispiel (C-Dur) |
|-------|----------|-----------|------------------|
| I | I | Maj7 | CMaj7 |
| II | ii | m7 | Dm7 |
| III | iii | m7 | Em7 |
| IV | IV | Maj7 | FMaj7 |
| V | V | 7 | G7 |
| VI | vi | m7 | Am7 |
| VII | vii | m7b5 | Bm7b5 |

Gross = Dur, klein = Moll (roemische Ziffern).

---

## Progressionen

### ii-V-I (die wichtigste Jazz-Progression)

```
ii (m7) → V (7) → I (Maj7)
```

Beispiel in C-Dur: Dm7 → G7 → CMaj7

Die App uebt diese Progression in allen 12 Tonarten, sortiert nach dem Quartenzirkel:
C → F → Bb → Eb → Ab → Db → Gb → B → E → A → D → G

### I-vi-ii-V (Turnaround)

```
I (Maj7) → vi (m7) → ii (m7) → V (7)
```

32-taktige Jazz-Standardform basiert auf dieser Kadenz.

### Quartenzirkel (Cycle of 4ths)

```
C → F → Bb → Eb → Ab → Db → Gb → B → E → A → D → G → C
```

Jeder Ton ist eine reine Quarte (5 Halbtoene) hoeher als der vorherige.
Fundamentales Uebungs-Pattern: gleicher Akkord-Typ in allen 12 Keys.

---

## Voice Leading

Stimmfuehrung minimiert die Bewegung zwischen Akkorden:

- **Common Tones** bleiben auf derselben Taste (Pitch Class)
- **Neue Toene** bewegen sich zum naechsten verfuegbaren Ton
- Ziel: moeglichst wenig Finger bewegen

Beispiel: Dm7 Shell (D-F-C) → G7 Shell (G-F-B)
- F bleibt (Common Tone)
- D → (loslassen), C → B (1 Halbton runter)
- → G (neuer Ton)

Die App zeigt Common Tones in Gold und neue Toene in Blau.

---

## Spaced Repetition fuer Akkorde

Basiert auf dem SM-2-Algorithmus:
- Gut gekonnt → Intervall vergroessern (1 → 2 → 4 → 7 → 14 → 30 Tage)
- Schlecht gekonnt → Intervall zuruecksetzen auf 1 Tag
- Ease-Faktor (1.3–2.5) wird pro Akkord trackt

---

## Mastery-Kriterien

| Bewertung | Kriterium |
|-----------|----------|
| A (Mastered) | Durchschnitt unter Mastery-Threshold (z.B. 2000ms) |
| B | Unter 3000ms |
| C | Unter 4000ms |
| D | Unter 5000ms |
| F | Ueber 5000ms |

---

*Zuletzt aktualisiert: Maerz 2026*
