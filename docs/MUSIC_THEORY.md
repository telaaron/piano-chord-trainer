# Chord Trainer – Musiktheorie-Referenz

Technisches Wissen das man braucht um den Code zu verstehen, ohne Musiktheorie-Studium.

---

## Grundlagen

### Chromatic Scale (12 Halbtöne)
```
Index:  0    1    2    3    4    5    6    7    8    9   10   11
Sharp:  C    C#   D    D#   E    F    F#   G    G#   A    A#   B
Flat:   C    Db   D    Eb   E    F    Gb   G    Ab   A    Bb   B
```

Ein Halbton (semitone) = kleinster Abstand auf dem Klavier. C→C# = 1, C→D = 2, C→E = 4.

### Enharmonics
Gleicher Ton, verschiedene Namen: `C# = Db`, `D# = Eb`, `F# = Gb`, `G# = Ab`, `A# = Bb`.

Achtung: `E# = F` und `Cb = B` existieren in der Musiktheorie, werden aber hier NICHT verwendet (zu verwirrend, praxis-irrelevant für unseren Anwendungsfall).

### Deutsche vs. Internationale Notation
```
International:  C  D  E  F  G  A  B   Bb
Deutsch:        C  D  E  F  G  A  H   B
```
In Deutschland heißt die Note B → H, und Bb → B. Das verwirrt international Studierende massiv. Unser Tool unterstützt beide Systeme.

---

## Akkord-Aufbau

Ein Akkord = mehrere Noten gleichzeitig, definiert durch **Intervalle** (Abstände in Halbtönen vom Root).

### Basis-Intervalle
```
Name              Halbtöne    Beispiel (von C)
Minor 2nd         1           C → Db
Major 2nd         2           C → D
Minor 3rd         3           C → Eb
Major 3rd         4           C → E
Perfect 4th       5           C → F
Tritone           6           C → F#/Gb
Perfect 5th       7           C → G
Minor 6th         8           C → Ab
Major 6th         9           C → A
Minor 7th         10          C → Bb
Major 7th         11          C → B
Octave            12          C → C'
Major 9th         14          C → D' (Octave + Major 2nd)
#9th              15          C → D#' (Octave + Minor 3rd)
b9th              13          C → Db' (Octave + Minor 2nd)
#11th             18          C → F#' (Octave + Tritone)
13th              21          C → A' (Octave + Major 6th)
```

### Unsere Akkord-Typen
```
Akkord        Intervalle              Noten (Root = C)
Maj7          [0, 4, 7, 11]          C  E  G  B
7 (Dom7)      [0, 4, 7, 10]          C  E  G  Bb
m7            [0, 3, 7, 10]          C  Eb G  Bb
6             [0, 4, 7, 9]           C  E  G  A
m6            [0, 3, 7, 9]           C  Eb G  A
Maj9          [0, 4, 7, 11, 14]      C  E  G  B  D'
9             [0, 4, 7, 10, 14]      C  E  G  Bb D'
m9            [0, 3, 7, 10, 14]      C  Eb G  Bb D'
6/9           [0, 4, 7, 9, 14]       C  E  G  A  D'
Maj7#11       [0, 4, 7, 11, 18]      C  E  G  B  F#'
7#9           [0, 4, 7, 10, 15]      C  E  G  Bb D#'
7b9           [0, 4, 7, 10, 13]      C  E  G  Bb Db'
m11           [0, 3, 7, 10, 14, 17]  C  Eb G  Bb D' F'
13            [0, 4, 7, 10, 14, 21]  C  E  G  Bb D' A'
m7b5 (ø7)    [0, 3, 6, 10]          C  Eb Gb Bb
```

---

## Voicings

"Voicing" = welche Noten man tatsächlich spielt und in welcher Reihenfolge/Lage.

### Root Position
Alle Noten in Grundstellung: Root unten, dann aufwärts gestapelt.
```
CMaj7 Root: C - E - G - B
```

### Shell Voicing
Nur Root + 3rd + 7th. Die 5th wird weggelassen (ist harmonisch am wenigsten wichtig).
```
CMaj7 Shell: C - E - B          [indices: 0, 1, 3]
```
**Warum Shell?** Die 3rd bestimmt ob Dur/Moll. Die 7th bestimmt den Charakter (Major 7th vs. Dominant 7th vs. Minor 7th). Die 5th ist fast immer "perfect" und sagt wenig aus.

### Half Shell
3rd ins Bass (tiefste Note), dann Root, dann 7th. Invertierung für smootheres Voice Leading.
```
CMaj7 Half Shell: E - C - B     [indices: 1, 0, 3]
```

### Full Voicing
Offene Lage: Root - höchste Note - 3rd - 5th. Jazz-typischer "spread".
```
CMaj7 Full: C - B - E - G       [indices: 0, last, 1, 2]
```

---

## 2-5-1 Progression

Die wichtigste Akkordverbindung im Jazz. "Take it through all 12 keys" ist THE Übung.

### Aufbau
In der Tonart C-Dur:
```
Stufe II:  Dm7    (D Moll 7)
Stufe V:   G7     (G Dominant 7)
Stufe I:   CMaj7  (C Major 7)
```

### Durch alle 12 Keys
```
Key  | ii       | V        | I
C    | Dm7      | G7       | CMaj7
F    | Gm7      | C7       | FMaj7
Bb   | Cm7      | F7       | BbMaj7
Eb   | Fm7      | Bb7      | EbMaj7
Ab   | Bbm7     | Eb7      | AbMaj7
Db   | Ebm7     | Ab7      | DbMaj7
Gb   | Abm7     | Db7      | GbMaj7
B    | C#m7     | F#7      | BMaj7
E    | F#m7     | B7       | EMaj7
A    | Bm7      | E7       | AMaj7
D    | Em7      | A7       | DMaj7
G    | Am7      | D7       | GMaj7
```

Das folgt dem **Quartenzirkel** (Cycle of 4ths): C → F → Bb → Eb → ...

### Implementation Hinweis
Für den 2-5-1 Mode braucht man:
1. Eine Funktion die für jede Tonart die 3 Akkorde berechnet
2. Die Reihenfolge der Keys (Quartenzirkel oder chromatisch)
3. Die Möglichkeit durch alle Keys zu rotieren
4. Voicing-Wechsel innerhalb einer Progression (Shell für ii, Full für V, etc.)
