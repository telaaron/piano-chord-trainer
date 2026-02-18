# Chord Trainer – Open Questions & Tech Debt

> **Last reviewed:** 18. Februar 2026  
> **Legend:** 🔴 Blocker · 🟡 Should fix · 🟢 Nice to have · ❓ Decision needed

No open items. All resolved — see history below.

---

## Resolved

### ✅ No Tests
- **Resolution:** Created `notes.test.ts`, `chords.test.ts`, `voicings.test.ts` — 70 tests, all passing via `pnpm test`.

### ✅ Theme Switcher: openstudio theme removed
- **Resolution:** Removed `openstudio` ThemeId from `theme.ts`, removed `[data-theme="openstudio"]` CSS block from `app.css`. The `/open-studio` page uses its own scoped `<style>` block.

### ✅ Verify Mode disabled with MIDI
- **Resolution:** Verify Mode button in `GameSettings.svelte` is greyed out (`opacity-40`, `cursor-not-allowed`, `disabled`) when `midiEnabled` is true.

### ✅ Supabase / Cloud Sync
- **Resolution:** Not a current priority. Documented in `DECISIONS.md` as future-only, pending a full B2C system (accounts + Stripe). Removed from near-term roadmap.

### ✅ Open Studio Member Count
- **Resolution:** Researched live from openstudiojazz.com (Feb 2026). No public member count available. `BUSINESS.md` now uses verifiable facts: $47/mo (annual) / $97/mo (monthly), 18 team members, 27 instructors, 86 courses, 100K+ YouTube subscribers.
