# iOS Redesign „Editorial × iOS“ — Design Spec

Stand: 15.10.2026 · Freigabe Design: Aaron („passt“, 15.10. 10:56 UTC)
Referenz-Mockups: Design-Canvas, Seite „Final“ — https://claude.ai/artifact/7rkC7Hmsvn318ELN1grGC9
(Vorstudien Reihe D: https://claude.ai/artifact/WY7kugn8bEAT3TqNNKkYDp)

## 1. Ziel

Nach dem TestFlight-Test von Build 1 wirkte die App „wie altes iOS, in dem die Cards durch Glass-Cards ersetzt wurden“. v1.0 soll vor dem Store-Submit ein eigenständiges Gesicht bekommen: Jazz-Editorial (Real-Book-Handschrift, Serif-Titel, typografische Zahlen) im Inhalt, aktuelles iOS (Liquid Glass, Large Titles, Inset-Grouped-Listen, Capsule-Buttons) in Steuerung und Navigation.

**Erfolg heißt:**
- Die drei Kernscreens (Heute, Trainer, Lernen) entsprechen den Final-Mockups in hell und dunkel.
- Alle übrigen Screens folgen denselben Regeln (Abschnitt 3), kein Screen sieht mehr nach Kachel-/Glass-Card-Raster aus.
- Kein Funktionsverlust: alle 180 Tests bleiben grün, kein Store-/Engine-Code ändert Verhalten.
- Dynamic Type, VoiceOver, Kontrast (WCAG AA) und iPad-Layout funktionieren weiter.

**Nicht-Ziele:** neue Features (Ausnahme: Akkord-Vorschau auf Heute, Abschnitt 4.1), Änderungen an MusicEngine, Audio, Stores, Telemetrie, Web-App.

## 2. Ansatz

Gewählt: **Design-System zuerst, dann Screens umbauen** (bestehende Views behalten, nur Präsentation ersetzen).

Verworfen:
- *Nur die 3 gemockten Screens umbauen* — der Rest bliebe im alten Look, die App wirkt zusammengestückelt.
- *Views neu schreiben* — hohes Regressionsrisiko in TrainerView (605 Zeilen) und ToGoView (716 Zeilen) ohne Mehrwert; die Logik steckt in den Stores und bleibt.

## 3. Design-System

### 3.1 Farben (`Theme/Theme.swift`)

Palette bleibt 1:1 aus `src/app.css`. Neu sind semantische Rollen, die Views ausschließlich verwenden:

| Rolle | Dunkel | Hell | Verwendung |
|---|---|---|---|
| `canvas` | #0E141D | #F6F2EA | Screen-Hintergrund (Nachtblau / Papier) |
| `ink` | #F2E8D5 | #1A1916 | Haupttext, Haarlinie unter Titeln |
| `inkMuted` | #B4BCC8 (E) | #736D66 (AA 4,58:1) | Sekundärtext, Eyebrows |
| `hairline` | #3A4658 (E) | #CFC7B8 | Trennlinien, Notenlinien |
| `group` | #18212E (E) | #FFFFFF | Inset-Grouped-Listen |
| `action` (Rot) | #F07B6C (E) | #B0302A | Primär-Button, aktiver Tab, fehlender Ton |
| `onAction` | #0E141D | #FFF8EF | Text auf Rot |
| `music` (Gold) | #E8B04B | #8F5A05 | Stats-Zahlen, Akkord-Badges, Kursnummern, „fertig“, nächster Akkord |
| `musicFill` | #E8B04B | #E2A93B | gespielte Tasten, Fortschrittsbalken |
| `feature` | #8C2A22 (E) | #B0302A | Feature-Block (dunkel: Ochsenblut statt Koralle) |
| `onFeature` | #F6EDE0 (E) | #FFF8EF | Text und invertierter Button auf dem Feature-Block |
| `featureAccent` | #F2C46B (E) | #FFF8EF | Eyebrow auf dem Feature-Block |

Variante E (Aaron, 16.10.): Dunkel mit hellerem Sekundärtext, sichtbaren Haarlinien, abgesetzten Listen (feine Kante), Feature-Block hell auf dunkel, Geister-Akkord 8 %, weiße Tasten #ECE6DA.

**Farbregel:** Rot = tun / Fehler. Gold = Musik / Erfolg / Fortschritt. Nachtblau = Bühne. Genau **ein** roter Feature-Block pro Screen. Kein Grün mehr für „richtig“ im Trainer (Gold ersetzt es); `accentGreen` bleibt nur für bestehende Charts erhalten, falls nötig.

Die alten Tokens (`primary`, `stamp`, `inkBlue` …) bleiben vorerst als Aliase bestehen und werden screenweise abgelöst; am Ende ungenutzte Tokens entfernen.

### 3.2 Typografie (`Theme/Typography.swift`)

| Rolle | Schrift | Größe (Basis) | Wo |
|---|---|---|---|
| Large Title | Instrument Serif Regular | 44 | „Heute“, „Lernen“, „Fortschritt“ |
| Lede / Kicker | Instrument Serif Italic | 20–22 | Satz im Feature-Block, „Shell Voicing · die ii“ |
| Stats / Kurstitel | Instrument Serif Regular | 24–32 | Kennzahlen, Kursnamen |
| Akkord | Kalam Bold | 148 (Trainer), 18–30 (Badges) | jedes Akkordsymbol |
| Eyebrow | SF Mono Medium, Tracking 0.08em | 11–12 | „DO · 15. OKT / SESSION 07“ |
| UI | SF Pro (System) | Systemstile | alles andere |

- Instrument Serif und Kalam sind OFL-lizenziert; TTFs nach `Resources/Fonts/`, in `UIAppFonts` eintragen. Space Grotesk entfällt.
- **Vorzeichen:** Kalam und Instrument Serif haben kein ♭/♯, Kalam evtl. kein Δ. Der bestehende Cascade-Mechanismus (`cascadedUIFont`, Fallback Apple Symbols) wird für beide Familien generalisiert. Unit-Test: Breite von „♭“ in `Display.chord` < Breite von „B“.
- Alle Custom-Größen skalieren mit Dynamic Type (`relativeTo:`); Trainer-Akkord hat `minimumScaleFactor(0.5)`.

### 3.3 Glass & Komponenten (`Views/Glass.swift`, `Views/Components.swift`)

**Glas nur auf der Steuerungsebene** (HIG): Tab Bar, Toolbar-Kreisbuttons, Fortschritts-Capsule im Trainer, Segment-Umschalter, Sekundär-Button. Nie auf Inhalt. `glassCard` wird entfernt; alle Aufrufer (28 Stellen) wechseln auf die neuen Komponenten.

Neue Komponenten:
- `FeatureBlock` — roter Block, Radius 26, Eyebrow + Inhalt + Aktion, optionaler Geister-Akkord (Kalam, 16–22 % Deckkraft) unten rechts.
- `StatsRow` — 3 Spalten, Haarlinie oben in `ink`, vertikale Haarlinien, Serif-Zahl in `music`, Label in `inkMuted`.
- `EditorialHeader` — Eyebrow (Mono) + Large Title (Serif), ersetzt `.navigationTitle`-Optik auf Tab-Root-Screens.
- `TrackRow` — Zeile in Inset-Grouped-Gruppe (Radius 22): Kalam-Badge oder Serif-Nummer in `music`, Titel SF 17, Meta rechts.
- `PrimaryCapsule` — Capsule 56 pt in `action`; `GlassCircleButton` 44 pt.
- `LeadSheetStrip` — 5 Notenlinien, Taktstriche, drei Akkorde (vorher gedimmt, jetzt `action` größer, danach `inkMuted`).
- `FunctionGrid` — 3 Zellen Ton + Funktion; Zustand ok (`music`) / fehlt (gestrichelt `action`) / offen (`ink`).
- `HeroGradient` und `CardSurface` entfallen.

### 3.4 Navigation

- iPhone: System-`TabView` (auf iOS 26 automatisch Liquid-Glass-Tab-Bar), `.tint(action)`. Keine eigene Tab Bar — Familiarity schlägt Pixel-Treue zum Mockup.
- iOS 17–25: dieselbe TabView mit Material-Hintergrund (Systemverhalten).
- Einstellungen: Glass-Kreisbutton oben rechts (Toolbar), wie bisher als Sheet.
- iPad: `NavigationSplitView` bleibt, Sidebar übernimmt Farben und Schriften.

### 3.5 Tastatur (`Views/PianoKeyboard.swift`)

Randlos, auf dunklem Bett (`#070A0F` dunkel / `ink` hell). Gespielt/erwartet = `musicFill` mit dunklem Label, fehlend = 2,5 pt Innenrand `action` mit Label in `action`, falsch gehalten = `action`-Füllung. Weiße Tasten Radius 6 unten. Geometrie und Input-Logik bleiben unverändert.

## 4. Screens

### 4.1 Heute (`TodayView`)
Reihenfolge: Eyebrow (Wochentag · Datum / Session-Nr.) → Large Title „Heute“ → FeatureBlock „HEUTE DRAN · x MIN · n AKKORDE“ mit der Akkordfolge des Coach-Vorschlags in Kalam (`C–7 → F7 → B♭Δ7`), Lede-Satz, „Weiter üben“ → StatsRow (Serie, Ø Zeit pro Akkord, sitzende Voicings) → „SEITE B · SELBST WÄHLEN“ mit TrackRows (bestehende Optionen: Aufwärmen/Turnaround/Schwachstellen/To-Go).

**Kein Notensystem auf Heute** (Entscheidung 15.10.: Heute hat einen Job — in < 3 s ans Klavier).

**Akkord-Vorschau (einziges neues Verhalten):** Tipp auf einen Akkord der Folge öffnet ein kleines Sheet (`.presentationDetents([.height(260)])`) mit Akkordname und `PianoKeyboard` im Voicing des Coach-Plans plus Abspielen-Button. Keine Session, keine Telemetrie-Events außer dem bestehenden Preview-Audio.

Motivation-Card, Reminder-Angebot und Wochenstreifen bleiben inhaltlich, werden als TrackRow bzw. schlichte Textzeile gesetzt (keine Kacheln).

### 4.2 Trainer (`TrainerSessionView` in `TrainerView.swift`)
Oben: GlassCircle Schließen · Glass-Capsule mit Fortschritt (`musicFill`) und „8/24“ · GlassCircle Anhören. Darunter `LeadSheetStrip` (vorher | jetzt | danach), wenn eine Progression läuft; bei Einzelakkord-Drills entfällt er. Mitte: Kicker (Serif Italic: Voicing · Stufe), Akkord in Kalam 148, `FunctionGrid`, Feedbackzeile (`action` bei Fehler, `music` bei richtig). Unten: Tastatur randlos, „nächster: G7 — die V“, Buttons „Tipp“ (Glass) + Primär-Capsule.
Landscape/iPad: bestehende Zwei-Spalten-Logik bleibt, Komponenten werden getauscht.

### 4.3 Lernen (`LearnView`, `CourseDetailView`)
EditorialHeader „Lernen“ (das Segment „Kurse | Karten“ aus dem Mockup entfällt: einen Karten-Screen gibt es nicht, kein Platzhalter) → FeatureBlock „DER WEG · 32 LEKTIONEN“ (Ultimate Plan) mit Fortschritt → „INHALT“ mit Serif-Nummern 01…, Serif-Kurstitel, Meta, Status rechts („fertig“ in `music`, „2/3“, „neu“). `CourseDetailView` und `LessonPlayerView` übernehmen Header, TrackRows, FunctionGrid und Tastatur.

### 4.4 Übrige Screens (abgeleitet, ohne eigenes Mockup)
- **Üben** (`PracticeView`): EditorialHeader, Level-Gruppen als Inset-Grouped mit TrackRows; Custom-Progression als PrimaryCapsule-Zeile.
- **Fortschritt** (`ProgressView_`): EditorialHeader, StatsRow, Trend-Chart in `music`, Schwachstellen als TrackRows mit Kalam-Badges.
- **To-Go, Gehörbildung, Custom Progression, Session-Ergebnis** (Ergebnisansicht in `TrainerView.swift`, `statCard`): gleiche Regeln; Ergebnis mit StatsRow statt Stat-Kacheln und einem FeatureBlock.
- **Onboarding, Einstellungen, Reminder-Angebot**: Farben + Schriften, sonst System-Formulare.

## 5. Umsetzung & Prüfung

- Reihenfolge: Tokens/Fonts → Komponenten → Heute → Trainer → Lernen → übrige Screens → alte Tokens/`glassCard` entfernen.
- Tests: bestehende 180 Tests grün; neu Unit-Tests für Font-Cascade (♭/♯/Δ), Palette-Rollen hell/dunkel, FunctionGrid-Zustandsableitung aus `expectedPitchClasses`/`heldNotes`.
- Visuell: SwiftUI-Previews je Screen in hell/dunkel und Dynamic Type XXL; Screenshot-Vergleich gegen die Final-Mockups auf Aarons Mac (Simulator iPhone 16/17 Pro + iPad).
- Build & Upload: auf Aarons Mac via Remote Control, Build 3 (`CURRENT_PROJECT_VERSION` 3) nach TestFlight auf Aarons Go.
- Store-Screenshots werden nach dem Redesign neu erstellt.

## 6. Risiken

- **Kalam-Lesbarkeit kleiner Größen** (< 16 pt): Badges mindestens 18 pt; VoiceOver liest Akkorde über bestehende `accessibilityLabel`s, nicht den Glyphen.
- **Fehlende Glyphen** (♭ ♯ Δ ø °): durch Cascade + Test abgedeckt.
- **iOS < 26 ohne Liquid Glass**: Material-Fallback, gleiche Formen; akzeptiert.
- **Umfang**: ~15 Views. Falls der Zeitrahmen drückt, sind 4.1–4.3 + Tastatur das Minimum für den Submit; 4.4 darf in 1.0.1 folgen (Entscheidung Aaron).
