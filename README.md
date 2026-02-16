# Chord Trainer

Jazz Piano Chord Voicing Trainer – built with SvelteKit 2, Svelte 5, Tailwind CSS 4 & Tone.js.

## Stack

| Layer | Tech |
|-------|------|
| Framework | SvelteKit 2 + Svelte 5 (Runes) |
| Styling | Tailwind CSS 4 (`@import 'tailwindcss'`) |
| Audio | Tone.js (piano samples) |
| MIDI | Web MIDI API (native) |
| Deploy | Vercel (adapter-vercel) |

## Dev

```bash
pnpm install
pnpm dev
```

## Features (planned)

- 14 chord types across 3 difficulty levels
- 4 voicing types: Root, Shell, Half-Shell, Full
- Interactive 2-octave piano keyboard
- MIDI keyboard input
- 2-5-1 progression drills
- Progress tracking (localStorage → Supabase later)
