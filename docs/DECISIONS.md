# Chord Trainer – Design-Entscheidungen

> Dokumentation der wichtigsten technischen und konzeptionellen Entscheidungen.
> **Stand:** Maerz 2026

---

## Architektur-Entscheidungen

### Svelte 5 Runes statt Svelte 4 Stores

**Entscheidung:** Alle Reaktivitaet via $state, $derived, $props, $effect.

**Gruende:**
- Svelte 5 war bei Projektstart aktuell
- Runes sind expliziter als automatische Reaktivitaet
- Kein reactivity-footgun (vergessenes $: Label)
- Train-Page (2700 Zeilen) waere mit Stores unwartbar

### localStorage statt Datenbank

**Entscheidung:** Alle Daten in localStorage. Kein Backend.

**Gruende:**
- Keine Registrierung noetig → sofortige Nutzung
- Kein Server-Betrieb → Kosten = 0
- Datenschutz: Nutzerdaten verlassen nie den Browser
- Nachteil: Kein Cross-Device-Sync (Roadmap: Cloud-Sync als Pro-Feature)

**Keys:** ~10 localStorage-Eintraege (siehe ARCHITECTURE.md)

### Pure Engine Layer

**Entscheidung:** Alle Musiktheorie-Berechnungen in `src/lib/engine/` ohne DOM/Browser-Abhaengigkeiten.

**Gruende:**
- Testbar ohne Browser (Vitest laeuft rein in Node)
- Portierbar in andere Frameworks
- Klare Schicht-Trennung (Engine → Services → Components → Routes)

### Pitch-Class-basiertes Matching

**Entscheidung:** Akkord-Erkennung vergleicht Pitch Classes (mod 12), nicht absolute MIDI-Noten.

**Gruende:**
- Oktave egal: C3 und C5 sind beide "C"
- Enharmonische Toene behandelt: C# = Db
- Voicing-unabhaengig: Shell-Voicing wird in jeder Oktave erkannt

---

## Kurs-System-Entscheidungen

### 3 Steps statt 5

**Entscheidung:** Theory → Practice → Challenge (nicht Theory → Discover → Guided → Free → Challenge).

**Gruende:**
- 5 Steps = zu viel UI-Komplexitaet
- Practice kombiniert Guided und Free in einem Flow (Phasen-Wechsel)
- MVP beweist Konzept schneller

### 3-Phasen-Practice (Guided → Find → Free)

**Entscheidung:** Practice-Step hat interne Phasen statt separate Steps.

**Gruende:**
- Fliessender Uebergang fuehlt sich natuerlich an
- Pool-Shuffle bei Phasenwechsel verhindert Auswendiglernen der Reihenfolge
- Guided zeigt alle Noten, Find nur Root + Name, Free ohne Hilfe

### IntervalSpec neben ChordSpec

**Entscheidung:** Eigener Typ `IntervalSpec { root, target, label, semitones }` fuer Intervall-Lektionen.

**Gruende:**
- Intervalle sind kein Akkord (kein quality, kein voicing)
- Eigene Validierung: Ziel-Note muss exakt stimmen (nicht Pitch-Class-Set)
- Saubere Trennung der Datenmodelle

### Kurse als statische TS-Dateien

**Entscheidung:** Kurse sind `src/lib/courses/*.ts` Dateien, keine Datenbank.

**Gruende:**
- Type-Checking zur Compile-Zeit
- Kein CMS noetig
- Versioniert in Git
- Bundle-optimiert (Tree-Shaking)
- Nachteil: Neue Kurse brauchen Deploy (akzeptabel bei Solo-Dev)

---

## i18n-Entscheidungen

### Eigenes t()-System statt Framework

**Entscheidung:** Eigene `t(key, params?)` Funktion mit verschachtelten Objekten statt svelte-i18n oder paraglide.

**Gruende:**
- ~100 Zeilen Code, kein Dependency
- Punkt-separierte Keys: `t('nav.home')` → "Startseite"
- Parameter-Interpolation: `t('midi_test.hidden_count', { n: 3 })`
- Fallback auf EN automatisch
- Nachtraeglich migrierbar zu echtem Framework wenn noetig

### Deutsch als Primaersprache

**Entscheidung:** DE zuerst, EN als Fallback.

**Gruende:**
- Erstmarkt ist DACH
- Alle UI-Texte in DE gedacht und geschrieben
- EN-Uebersetzung ist vollstaendig (~1460 Keys)

---

## UI/UX-Entscheidungen

### Click-Piano als Default-Input

**Entscheidung:** Keyboard funktioniert immer per Klick, MIDI/Mikrofon sind Add-Ons.

**Gruende:**
- Funktioniert ueberall (Mobile, Desktop, ohne Hardware)
- Kein Setup noetig
- MIDI ist "upgrade" fuer ernsthafte Nutzer
- Mikrofon ist "upgrade" fuer iOS-Nutzer

### Kein Account-Zwang

**Entscheidung:** App ist sofort nutzbar, kein Login.

**Gruende:**
- Maximale Conversion (kein Signup-Friction)
- Datenschutz (keine PII)
- localStorage reicht fuer lokalen Fortschritt
- Cloud-Sync kommt als optionales Pro-Feature

### Dark Mode als Default

**Entscheidung:** Dunkles Theme als Standard.

**Gruende:**
- Passt zur Jazz-Aesthetik
- Besser fuer Abend-Nutzung (Ueben am Klavier)
- Weniger Augenbelastung bei laengeren Sessions

### Tailwind 4 statt CSS Modules

**Entscheidung:** Tailwind CSS 4 via @tailwindcss/vite Plugin.

**Gruende:**
- Utility-First spart Datei-Overhead
- CSS Custom Properties fuer Theming
- JIT-Compiler in v4 braucht keine Config
- Konsistent ueber alle Komponenten

---

## Habit-Engine-Entscheidungen

### XP-Level-Formel: sqrt(totalXP / 50)

**Entscheidung:** `Level = floor(sqrt(totalXP / 50))`

**Gruende:**
- Quadratisches Wachstum: Anfangs schnelle Level-Ups, spaeter langsamer
- Level 5 bei 1.250 XP, Level 10 bei 5.000 XP, Level 50 bei 125.000 XP
- Motivierend am Anfang, herausfordernd spaeter

### Max 2 Ziele statt 3

**Entscheidung:** Maximal 2 aktive Smart Goals gleichzeitig.

**Gruende:**
- Weniger Cognitive Load (CPO Review)
- Fokus statt Ueberladung
- Goal-Descriptions entfernt — Titel reicht

### SM-2 fuer Spaced Repetition

**Entscheidung:** SM-2 Algorithmus (wie Anki) fuer Akkord-Review.

**Gruende:**
- Bewaeehrt und gut verstanden
- Einfach implementierbar (~50 Zeilen)
- Ease-Faktor pro Akkord anpassbar

---

## MIDI-Entscheidungen

### Persistente Device-Auswahl

**Entscheidung:** MIDI-Device-ID in localStorage speichern + Auto-Reconnect.

**Gruende:**
- Nutzer muss nicht bei jedem Besuch neu waehlen
- Hot-Plug: Geraet wird automatisch wiederverbunden
- Keine "welches Geraet?"-Frage nach Browser-Restart

### Virtual-Port-Filtering

**Entscheidung:** macOS IAC, MIDI Through, Microsoft GS werden automatisch versteckt.

**Gruende:**
- Verwirrung vermeiden: Diese Ports sind keine echten Keyboards
- Trotzdem erreichbar ueber "Alle einblenden"
- Regex-basiert, erweiterbar

### Hide/Unhide statt Delete

**Entscheidung:** Geraete koennen ausgeblendet, nicht geloescht werden.

**Gruende:**
- Reversibel: "Alle einblenden" stellt alles wieder her
- Kein Datenverlust
- "N ausgeblendet — Alle einblenden" Button wenn noetig

---

## Audio-Entscheidungen

### Tone.js statt Web Audio API direkt

**Entscheidung:** Tone.js als Abstraction ueber Web Audio.

**Gruende:**
- PolySynth, Transport, Loop out-of-the-box
- Cross-Browser-Kompatibilitaet
- Metronom-Implementation in ~20 Zeilen statt ~200

### @spotify/basic-pitch fuer Mikrofon

**Entscheidung:** ML-basierte Pitch-Detection statt einfacher FFT.

**Gruende:**
- Polyphonie: Erkennt mehrere Toene gleichzeitig
- Akkuratheit: Besser als Autocorrelation-basierte Ansaetze
- Nachteil: Grosses Modell (~5MB), laengere Ladezeit
- Nachteil: Latenz hoeher als MIDI

---

## iOS-App v1.0 (Oktober 2026)

### Gratis ohne In-App-Kauf (Empfehlung, Freigabe Aaron offen)

**Entscheidung:** iOS v1.0 erscheint kostenlos, `SubscriptionStore.isPro` bleibt `true`, kein StoreKit.

**Gruende:**
- Erst messen, ob iOS die Retention hebt (D7 Web ≈ 2 %); Monetarisierung ist Roadmap-Schritt 7
- Kein Kaufweg in der App → kein Konflikt mit Guideline 3.1.1, die App verlinkt nicht auf den Web-Checkout
- Gate-Aufrufe bleiben im Code, StoreKit 2 kann ohne Umbau nachgezogen werden

### Taegliche Erinnerung als lokale Notification

**Entscheidung:** `ReminderScheduler` plant 7 Tage voraus lokale Notifications (kein Server, kein APNs), keine Erinnerung an einem Tag mit Uebung. Erlaubnis per Pre-Permission-Karte nach dem ersten abgeschlossenen Drill, nicht im Onboarding.

**Gruende:**
- Einziger Rueckkehr-Anlass ohne E-Mail-Infrastruktur (Masterplan 1.6)
- Der System-Dialog erscheint nur einmal; ein „Nicht jetzt“ auf der eigenen Karte verbraucht ihn nicht
- Wer eine Woche nicht oeffnet, bekommt danach keine Erinnerungen mehr (kein Dauer-Nerven)
- Datumslogik in `MusicEngine/Reminders.swift`, getestet inkl. Sommerzeit

### Anonyme Nutzungsdaten nur mit Zustimmung (iOS)

**Entscheidung (Aaron, 13.10.2026):** In der iOS-App ist Telemetrie standardmaessig aus. Die letzte Onboarding-Seite fragt ohne Vorauswahl; ueberspringen zaehlt als Nein. Aenderbar in den Settings, Widerruf loescht die Geraete-ID.

**Gruende:**
- Die Geraete-ID wird auf dem Geraet gespeichert und ausgelesen (ePrivacy/§ 25 TDDDG), Zustimmung ist der sichere Weg
- Weniger Daten als im Web, dafuer sauber fuer App-Review und Datenschutzerklaerung

### Anzeige-Praeferenzen gehoeren dem Nutzer

**Entscheidung:** Notation und Vorzeichen kommen immer aus den Settings; Plaene und Coach-Bloecke ueberschreiben sie nicht mehr.

---

## Entscheidungen die sich geaendert haben

| Urspruenglich | Jetzt | Warum |
|--------------|-------|-------|
| "Kein i18n" | Volles i18n (DE+EN) | Internationaler Markt ist wichtig |
| "Single Page" | 12 Routes | Kurse brauchen eigene URLs, SEO |
| "Nur Speed-Drill" | Kurse + Drill | Verstaendnis vor Geschwindigkeit |
| "Kein Audio" | Tone.js + Mikrofon | Audio ist Kern-Feature geworden |
| "MIDI nur basic" | Persistence + Hide + Filter | UX erfordert Device-Management |
| "Keine Gamification" | XP, Levels, Streaks, Goals | Retention ist kritisch |

---

*Zuletzt aktualisiert: Oktober 2026*

### Akkordwurzel wie im Leadsheet (keine Doppelvorzeichen)

**Entscheidung (Aaron, 13.10.2026):** Bei gemischten Vorzeichen (`both`) schreibt der Trainer die Wurzel so, dass kein Doppelvorzeichen nötig ist: G#m7b5 statt Abm7b5, Eb7 statt D#7 (`preferredRoot` in `notes.ts` / `Notes.swift`). Feste Kreuz-/b-Einstellung bleibt unangetastet.

**Gruende:**
- So stehen die Akkorde in Jazz-Leadsheets; Abm7b5 hätte E𝄫 als ♭5
- Doppelvorzeichen generell einzuschalten hätte rund 45 Akkorde ungewohnt benannt
- Dabei behoben: Der ♯11 in Maj7#11 wird als Quarte geschrieben (DbMaj7#11 → G), nicht als verminderte Quinte
