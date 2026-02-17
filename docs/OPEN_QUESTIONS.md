# Chord Trainer – Offene Fragen, Inkonsistenzen & Tech Debt

> **Zuletzt geprüft:** 17. Februar 2026 (gegen den echten Code)  
> **Zweck:** Alles, was unklar ist, sich widerspricht, oder aufgeräumt werden muss.  
> **Legende:** 🔴 Blocker · 🟡 Sollte behoben werden · 🟢 Nice to have · ❓ Klärungsbedarf

---

## 1. Widersprüche zwischen Docs und Code

### 🟡 package.json Version stimmt nicht
- **package.json** sagt `"version": "0.1.0"`
- **PROJECT.md** sagt `v0.5.0`
- **Empfehlung:** `package.json` auf `0.5.0` aktualisieren

### 🟡 README war komplett veraltet ✅ BEHOBEN
- Sagte "Features (planned)" und listete nur 4 Voicing-Typen
- Jetzt aktualisiert mit echtem Feature-Stand

### 🟡 AGENT_HANDOFF.md ist stark veraltet
- Sektion 8 "Was noch zu tun" listet MIDI, Audio, Progressions als P1–P6 → alles ist längst fertig
- Sagt `+page.svelte` hat 270 Zeilen → tatsächlich existiert die Hauptlogik in `/train/+page.svelte` mit 785 Zeilen
- Dateistruktur fehlt: `services/`, `utils/`, mehrere neue Komponenten, Routen
- Listet `bits-ui`, `lucide-svelte`, `clsx`, `tailwind-merge` als "noch unbenutzt" → `lucide-svelte` wird auf der Landing Page verwendet
- **Status:** Wird als historisches Dokument beibehalten, nicht mehr aktiv gepflegt

### 🟡 PROJECT.md Zahlen teilweise falsch
- Sagt "14 Akkord-Typen" → Code hat **16** (`CHORD_INTERVALS` in chords.ts)
- Sagt "7 Übungspläne" → Code hat **9** (plans.ts: + Left-Hand Comping, Umkehrungen)
- Sagt "+page.svelte ~620 Zeilen" → `/train/+page.svelte` hat **785 Zeilen**
- Sagt "4 Voicing-Berechnungen" in der Dateistruktur → es sind **9**

### 🟡 DECISIONS.md teilweise überholt
- Sagt "Dark Mode Only" → es gibt ein Theme-System mit 2 Themes
- Sagt "Kein Audio beim Start" → Audio ist vollständig implementiert
- Sagt "Kein Router / Multi-Page" → es gibt jetzt 7 Routen
- Sagt "Settings hinter `<details>` versteckt" → es gibt jetzt Übungspläne als Hauptansatz
- **Die Grundentscheidungen sind weiterhin gültig**, aber "Was bewusst NICHT gebaut wurde" ist veraltet

### 🟡 MUSIC_THEORY.md listet 15 Akkord-Typen
- Code hat **16** (dim7 fehlt in der Theorie-Referenz)
- dim7 Intervalle: `[0, 3, 6, 9]`

---

## 2. Code-Inkonsistenzen

### 🔴 Open Studio Theme hat kein CSS
- `theme.ts` registriert Theme `"openstudio"` mit `data-theme="openstudio"` Attribut
- **Aber:** In `app.css` existiert **kein** `[data-theme="openstudio"]` CSS-Block
- Das Theme kann zwar "aktiviert" werden, ändert aber visuell nichts
- **Empfehlung:** Entweder CSS-Overrides in app.css nachrüsten oder das Theme aus theme.ts entfernen

### 🟡 dim7 ist nur halb implementiert
- `CHORD_INTERVALS` enthält `dim7: [0, 3, 6, 9]` ✅
- `CHORDS_BY_DIFFICULTY` enthält dim7 **nicht** → kommt nie im normalen Spiel vor
- `CHORD_NOTATIONS` enthält dim7 **nicht** → kein Display-Label
- **Ergebnis:** dim7 ist technisch definiert aber für Spieler unerreichbar
- **Empfehlung:** Entweder zu Advanced hinzufügen mit Notation, oder aus `CHORD_INTERVALS` entfernen

### 🟡 PWA Manifest Farbwerte falsch
- `site.webmanifest` hat `theme_color: "#7c5cfc"` (lila)
- Tatsächliche App-Primary-Farbe ist `#e8763b` (orange/gold) laut app.css `:root`
- `background_color: "#0a0a0b"` → stimmt fast (`--bg: #0a0908`), kleine Differenz

### 🟡 robots.txt Domain-Inkonsistenz
- Kommentar sagt "jazzchords.com"
- Sitemap-URL verweist korrekt auf "jazzchords.app"
- **Nur kosmetisch, aber verwirrend**

### 🟡 Sitemap fehlt /open-studio
- Die Open Studio Pitch-Seite (811 Zeilen!) ist nicht in sitemap.xml
- **Falls die Seite öffentlich sein soll** → hinzufügen
- **Falls sie nur per Direktlink geteilt wird** → bewusste Entscheidung, dokumentieren

### 🟢 Unused Dependencies
- `bits-ui` — installiert, unbenutzt (geplant für Dialoge/Dropdowns)
- `clsx` + `tailwind-merge` — installiert, unbenutzt
- **Nicht blockierend**, aber erhöht Bundle-Size wenn tree-shaking nicht perfekt ist
- **Empfehlung:** Bei nächstem Aufräumen entscheiden: nutzen oder entfernen

---

## 3. Fehlende Infrastruktur

### 🔴 Keine Tests
- `vitest` ist als devDependency installiert
- `package.json` hat `"test": "vitest run"` Script
- **Null Testdateien existieren** — keine `*.test.ts`, `*.spec.ts`
- Die Engine-Module (`notes.ts`, `chords.ts`, `voicings.ts`) sind pure Funktionen und ideal testbar
- **Empfehlung:** Mindestens Engine-Unit-Tests schreiben (Akkord-Intervalle, Voicing-Berechnung, Chord-Parsing)

### 🟡 Kein ESLint Config
- `eslint` v9.37 ist installiert
- **Keine `eslint.config.js`** (oder ähnliche Config) vorhanden
- `pnpm lint` schlägt wahrscheinlich fehl oder linted nichts
- **Empfehlung:** Flat Config mit `@eslint/js` + `typescript-eslint` + `eslint-plugin-svelte` aufsetzen

### 🟡 Kein Prettier Config sichtbar
- AGENT_HANDOFF erwähnt `.prettierrc` (Tabs, Single Quotes, Svelte Parser)
- **Kein `.prettierrc` in der aktuellen Dateistruktur gefunden**
- `prettier` + `prettier-plugin-svelte` sind in devDependencies
- **Empfehlung:** Prüfen ob die Datei existiert, sonst erstellen

### 🟢 Kein CI/CD Pipeline
- Kein `.github/workflows/` Verzeichnis
- Kein automatischer Build/Test/Deploy
- Vercel-Deploy passiert vermutlich via Git-Push (Vercel Auto-Deploy)
- **Empfehlung:** GitHub Actions Workflow für `pnpm check` + `pnpm test` bei PRs

---

## 4. UX/Feature-Fragen

### ❓ Theme-Switcher: Wo ist er?
- PROJECT.md sagt "Switcher in Nav (Palette-Icon)"
- `+layout.svelte` enthält **keinen** Theme-Switcher in der Navigation
- Nur "Train" und "For Educators" Links in der Nav
- **Frage:** Wurde der Switcher entfernt? Oder lebt er woanders?

### ❓ i18n-Strategie unklar
- UI ist überwiegend **Deutsch** (Übungsplan-Texte, Beschreibungen)
- Aber: Die Landing Page und "For Educators" sind auf **Englisch**
- `/train` mischt Deutsch und Englisch (Button-Labels teils EN, Beschreibungen teils DE)
- **Frage:** Wird die App einsprachig (EN für internationalen Markt)? Oder bleibt DE?
- **Empfehlung:** Für Open Studio und internationales Marketing sollte alles EN sein

### ❓ Verify-Mode vs. MIDI
- Bei aktivem MIDI wird Auto-Advance genutzt (Korrektheit wird automatisch geprüft)
- Verify-Mode (Voicing erst nach Tastendruck zeigen) macht dort weniger Sinn
- **Frage:** Wird Verify-Mode bei MIDI deaktiviert? Oder gibt es einen Hybrid?

### ❓ "Supabase later" — noch geplant?
- AGENT_HANDOFF und BUSINESS.md erwähnen "localStorage → Supabase later"
- **Frage:** Ist Cloud-Sync noch auf der Roadmap?
- **Empfehlung:** Wenn ja, als Future Feature dokumentieren. Wenn nein, Referenzen entfernen.

---

## 5. Marketing/Business-Widersprüche

### 🟡 Open Studio Mitgliederzahlen nicht verifiziert
- BUSINESS.md sagt "~56K Mitglieder bei $33/Monat"
- An anderer Stelle: "$47/mo × 1000+ Members"
- **Zwei verschiedene Zahlen**
- **Empfehlung:** Auf öffentlich nachprüfbare Angaben beschränken

### 🟡 Akkord-Anzahl in Marketing-Materialien
- Verschiedene Stellen sagen "14 Akkord-Typen"
- Code hat 16 (mit dim7: theoretisch 16, spielbar 15)
- **Empfehlung:** Einheitlich "15+ Akkord-Typen" sagen (nur zählen was Spieler erreichen können)

### 🟡 Voicing-Typen Zählung
- PROJECT.md Tabelle listet 9 Voicing-Typen ✅ (korrekt)
- AGENT_HANDOFF sagt "4 Voicing-Berechnungen" (veraltet)
- Feature-Liste in README sagt jetzt korrekt "9"

---

## 6. Priorisierte Empfehlungen

| Prio | Aktion | Aufwand |
|------|--------|---------|
| 🔴 1 | Open Studio Theme CSS implementieren oder aus theme.ts entfernen | 1-2h |
| 🔴 2 | Engine-Unit-Tests schreiben (mindestens notes, chords, voicings) | 3-4h |
| 🟡 3 | package.json Version auf 0.5.0 setzen | 1min |
| 🟡 4 | dim7 vollständig implementieren oder entfernen | 30min |
| 🟡 5 | PWA Manifest Farben korrigieren | 5min |
| 🟡 6 | ESLint Config erstellen | 30min |
| 🟡 7 | Sitemap.xml updaten (/open-studio, /about) | 5min |
| 🟡 8 | i18n-Strategie entscheiden und durchziehen | Entscheidung |
| 🟢 9 | Unused Dependencies evaluieren (bits-ui, clsx, tailwind-merge) | 15min |
| 🟢 10 | CI/CD Pipeline (GitHub Actions) | 1h |

---

*Dieses Dokument wird bei jedem Milestone geprüft und aktualisiert.*
