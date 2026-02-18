# Chord Trainer – Entscheidungslog

Dokumentiert **warum** Dinge so sind wie sie sind. Nicht nur was, sondern das Denken dahinter.

---

## Tech Stack Entscheidungen

### Svelte 5 statt Svelte 4
**Entscheidung:** Svelte 5 mit Runes-Syntax.
**Warum:** Das Original war Svelte 4. Bei der Extraktion in ein neues Repo war klar: Svelte 5 ist stable, die Runes-API ist sauberer, und wir vermeiden eine spätere Migration. `$state`/`$derived` sind expliziter als `$:` (kein verstecktes Dependency Tracking, klare Ownership).

### Tailwind 4 statt Tailwind 3
**Entscheidung:** Tailwind CSS 4 mit `@tailwindcss/vite` Plugin.
**Warum:** Greenfield-Projekt → neueste Version. Tailwind 4 braucht keine `tailwind.config.js`, alles läuft über CSS. Weniger Config-Files. `@import 'tailwindcss'` ist die einzige Zeile die man braucht. Theme über CSS Custom Properties definiert → maximale Flexibilität.

### CSS Custom Properties statt Tailwind Theme
**Entscheidung:** Alle Farben als `--primary`, `--bg-card` etc. in `:root`.
**Warum:** 
1. In Tailwind 4 gibt es kein `tailwind.config.js` Theme mehr
2. Custom Properties können zur Laufzeit geändert werden (Light/Dark Mode toggle)
3. Können in SVG, Canvas, etc. benutzt werden (für späteres Keyboard rendering)
4. Components referenzieren via `bg-[var(--primary)]` — ein Ort zum Ändern

### Kein Store / kein State Management Library
**Entscheidung:** State lebt direkt in `+page.svelte` als `$state()` Variablen.
**Warum:** Die App hat eine einzige Seite. Kein Routing-State nötig. Settings werden via `bind:` an Components durchgereicht. Wenn die App komplexer wird (Multi-Page, persistenter State), würde ein Svelte Store oder `$lib/stores/game.svelte.ts` sinnvoll.

### Kein Button-Component, native HTML
**Entscheidung:** `<button>` statt `bits-ui` Button Component.
**Warum:** bits-ui ist installiert (geplant für spätere Dialog/Dropdown Components), aber für einfache Buttons genügt nativer HTML + Tailwind. Weniger Abstraktion = weniger Breaking Changes. Erst einbauen wenn Modal/Dialog/Select gebraucht wird.

### adapter-vercel
**Entscheidung:** Vercel als Deploy-Target.
**Warum:** Aaron nutzt Vercel für mustseen-bridge-engine. Gleiche Infra, gleiche CI/CD-Erfahrung. Edge Functions wenn nötig. Free Tier reicht für Launch.

---

## Architektur-Entscheidungen

### Engine als Pure TypeScript Module
**Entscheidung:** `$lib/engine/` enthält nur pure Funktionen, kein DOM, kein Svelte.
**Warum:** 
1. **Testbar:** Alle Funktionen können mit `vitest` Unit-getestet werden ohne Browser
2. **Wiederverwendbar:** Könnte theoretisch in React, Vue, oder Server-Side benutzt werden
3. **Vorhersagbar:** Input → Output, keine Seiteneffekte
4. **Separierung:** Musiktheorie-Logik von UI-Logik getrennt

### 2-Layer Keyboard statt 1-Layer
**Entscheidung:** Weiße Tasten = `flex-1` Layer, schwarze Tasten = separater `absolute` Layer darüber.
**Warum:** Nach 5+ fehlgeschlagenen Ansätzen die einzige Lösung die auf allen Screen-Größen funktioniert:
- Approach 1 (absolute px): Drift bei verschiedenen Breiten
- Approach 2 (CSS Grid): Lücken an Oktav-Grenzen
- Approach 3 (calc + %): Rundungsfehler bei ungeraden Breiten
- Approach 4 (flex mit eingebetteten Black Keys): Z-Index-Chaos
- **Approach 5 (2-Layer):** flex-1 für weiße Tasten garantiert lückenlos. Schwarze Keys werden unabhängig via `left: %` + `-translate-x-1/2` positioniert. Funktioniert.

### Chromatic Index als Universal Key
**Entscheidung:** Notes werden intern als chromatic index (0–23) referenziert, nicht als Strings.
**Warum:** String-Vergleiche versagen bei Enharmonics (`C#` vs `Db`). Ein chromatic index von `1` ist immer `1`, egal ob du es `C#` oder `Db` nennst. `isRootIndex()` nutzt `(chrIdx % 12) === rootSemitone` — funktioniert immer.

### ChordWithNotes als zentrale Datenstruktur
```typescript
interface ChordWithNotes {
  chord: string;     // "BbΔ7" (display)
  root: string;      // "Bb"
  type: string;      // "Maj7" (internal key)
  notes: string[];   // ["Bb", "D", "F", "A"] (root position)
  voicing: string[]; // ["Bb", "D", "A"] (shell voicing)
}
```
**Warum:** Alles was ein Component braucht in einem Objekt. Wird einmal bei `generateChords()` berechnet, nicht on-the-fly. Components bekommen `chordData` als Prop und können alles daraus ableiten.

---

## UI/UX Entscheidungen

### German UI, International Engine
**Entscheidung:** UI-Texte auf Deutsch, Akkord-Logik international.
**Warum:** Aaron und die primäre Zielgruppe (deutschsprachige Jazz-Studenten) bevorzugen deutsche UI. Aber die Akkord-Engine arbeitet mit internationalem Standard (B = B, nicht H). Deutsche Notation (H/B) wird nur in der Display-Schicht konvertiert (`convertChordNotation`, `convertNoteName`).

### Dark Mode Only
**Entscheidung:** Kein Light Mode, kein Toggle.
**Warum:** Musiker üben oft abends/nachts. Dark ist der Standard in Musik-Apps (iReal Pro, Logic, Ableton). Weniger Code, eine Design-Richtung perfektionieren. Light Mode kann später über CSS Custom Properties hinzugefügt werden (die Infrastruktur steht).

### Settings hinter `<details>` versteckt
**Entscheidung:** Quick-Start prominent, Settings als Collapsible.
**Warum:** 80% der Nutzungen brauchen keine Settings-Änderung. "Jetzt spielen" soll 1 Klick sein. Wer tweaken will, klappt auf. Reduziert cognitive load beim Einstieg.

### Space + Tap als Dual Input
**Entscheidung:** Space-Taste für Desktop, Tap auf Chord-Card für Mobile.
**Warum:** Pianisten haben die linke Hand auf dem Keyboard, rechte auf dem Klavier. Space ist der natürlichste Key. Auf iPad/Tablet: Tap auf den Bildschirm. Beides löst `nextChord()` aus.

---

## Was bewusst NICHT gebaut wurde

### Kein Server-State
**Bewusst:** Kein Supabase, kein API. Alles client-side. Cloud-Sync nur wenn B2C-System gebaut wird (Stripe, Accounts) — kein Prio solange Open Studio B2B der Fokus ist.

### Kein Router / Multi-Page
**Bewusst:** Eine Seite. Kein `/settings`, kein `/history`. Alles in `+page.svelte` via Screen-State (`setup` / `playing` / `finished`). SvelteKit-Routing steht bereit wenn nötig.

### Kein Audio beim Start
**Bewusst:** Tone.js installiert aber nicht eingebaut. Audio-Autoplay ist auf Mobile blockiert. Muss user-initiated sein. Erst bauen wenn MIDI steht (dann Audio als Referenz-Playback sinnvoll).

### Kein i18n Framework
**Bewusst:** Strings sind hardcoded auf Deutsch. Für den Open Studio Pitch muss sowieso alles auf Englisch. Dann einfach Strings tauschen oder i18n einbauen. Vorher wäre Overengineering.
