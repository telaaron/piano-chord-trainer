# Chord Trainer – Contributing & Konventionen

> Regeln und Muster für alle, die am Code arbeiten.

---

## Setup

```bash
# Voraussetzungen: Node.js 18+, pnpm
pnpm install
pnpm dev          # → http://localhost:5173 (oder 5174)
```

### Verfügbare Scripts

| Script | Zweck |
|--------|-------|
| `pnpm dev` | Dev-Server starten |
| `pnpm build` | Production Build |
| `pnpm preview` | Production Build lokal testen |
| `pnpm check` | TypeScript + Svelte Type-Checking |

---

## Code-Konventionen

### Svelte 5 — Strikt Runes

```svelte
<!-- STATE -->
let count = $state(0);
let items = $state<string[]>([]);

<!-- DERIVED -->
const doubled = $derived(count * 2);

<!-- PROPS -->
let { name, onclick }: Props = $props();
let { value = $bindable() }: Props = $props();

<!-- EVENTS → Callback Props (NICHT on:click) -->
<button onclick={handler}>

<!-- CHILDREN (NICHT <slot>) -->
import type { Snippet } from 'svelte';
interface Props { children?: Snippet; }
{#if children}{@render children()}{/if}

<!-- EFFECTS -->
$effect(() => {
  // Seiteneffekte hier
  return () => { /* cleanup */ };
});
```

**Verboten in diesem Projekt:**
- `$:` (Legacy reactive declarations)
- `on:click` / `on:change` (Legacy event syntax)
- `<slot>` / `<slot name="...">` (Legacy slot syntax)
- `createEventDispatcher()` (Legacy event dispatch)

### TypeScript

- Strict mode aktiv
- `$state<UnionType>()` für korrekte Narrowing bei String Unions
- Interfaces statt `type` für Objekt-Shapes wo sinnvoll
- Explizite Return-Types für exportierte Funktionen

### Tailwind 4

```css
/* app.css — Einziger Import */
@import 'tailwindcss';

/* Theme via CSS Custom Properties */
:root {
  --primary: #e8763b;
  --bg: #0a0908;
  /* ... */
}

/* Components nutzen Arbitrary Values */
<div class="bg-[var(--primary)] text-[var(--text)]">
```

**Wichtig:**
- Keine `tailwind.config.js` — alles über CSS Vars
- Unlayered CSS (`* { ... }`) überschreibt `@layer utilities` Klassen
- Hardcoded Farb-Hex in Components vermeiden → immer CSS Vars nutzen

### File-Naming

| Typ | Konvention | Beispiel |
|-----|-----------|---------|
| Component | `PascalCase.svelte` | `PianoKeyboard.svelte` |
| Engine | `camelCase.ts` | `voicings.ts` |
| Service | `camelCase.ts` | `audio.ts` |
| Utility | `camelCase.ts` | `format.ts` |
| Route | SvelteKit Standard | `+page.svelte` |

### Formatierung

- **Tabs** für Indentation (nicht Spaces)
- **Single Quotes** in TypeScript/Svelte
- **Trailing Commas** überall
- Prettier + `prettier-plugin-svelte` für Auto-Format

---

## Architektur-Regeln

### Import-Richtung (strikt)

```
Routes  →  Components  →  Services  →  Engine
  ↕            ↕            ↕
Utils        Utils        Utils         (←  importiert NICHTS)
```

- **Engine** importiert nie Services oder Components
- **Services** importieren nie Components
- **Components** importieren aus Engine und Services
- **Routes** importieren aus allem

### Engine = Pure Functions

Module in `src/lib/engine/` dürfen **nicht**:
- `document`, `window`, `navigator` verwenden
- Svelte-Imports haben
- Seiteneffekte ausführen (localStorage, fetch, etc.)
- DOM-Elemente referenzieren

Sie dürfen **nur**: TypeScript-Typen, pure Berechnungen, Arrays, Objekte.

### Services = Browser-APIs

Module in `src/lib/services/` kapseln Seiteneffekte:
- `audio.ts` → Tone.js
- `midi.ts` → Web MIDI API
- `progress.ts` → localStorage
- `theme.ts` → DOM (data-attribute)

### Components = UI

Module in `src/lib/components/` sind Svelte 5 Components mit:
- Props über `$props()` (nie Stores)
- Events als Callback-Props
- Keine direkte localStorage/API-Zugriffe (→ über Services)

---

## Docs-Pflege

| Dokument | Wann aktualisieren |
|----------|-------------------|
| [README.md](../README.md) | Bei neuen Features oder Struktur-Änderungen |
| [PROJECT.md](PROJECT.md) | Bei jedem Release (Changelog + Roadmap) |
| [FEATURES.md](FEATURES.md) | Bei jedem Feature-Release (gegen Code prüfen!) |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Bei Architektur-Änderungen |
| [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) | Laufend — neue Fragen/Schulden eintragen |
| [DECISIONS.md](DECISIONS.md) | Bei jeder nicht-trivialen Architektur-Entscheidung |
| [BUSINESS.md](BUSINESS.md) | Bei Business-/Pricing-Änderungen |
| [MUSIC_THEORY.md](MUSIC_THEORY.md) | Bei neuen Akkord-/Voicing-Typen |

**Goldene Regel:** Docs sagen nur, was der Code auch tut. Im Zweifel Code als Quelle der Wahrheit.

---

## Bekannte Dev-Werkzeuge

| Tool | Status | Anmerkung |
|------|--------|-----------|
| `vitest` | Installiert, **keine Tests** | Engine-Tests sind die höchste Prio |
| `eslint` | Installiert, **keine Config** | Flat Config nötig |
| `prettier` | Installiert | Config sollte vorhanden sein |
| `svelte-check` | Funktioniert | `pnpm check` |
