# jazzchords iOS/iPadOS — open backlog (prioritized)

Status: v1 feature-complete (M1–M5 + design pass + iPad). Builds + runs on
iPhone 17 Pro and iPad Pro. Branch `ios/native`. This file = everything still
worth doing, highest priority first.

---

## P0 — Blockers / correctness (do before any release)

- [ ] **Verify all 3 crash fixes hold on device** — audio graph (sf3 removed),
      Bluetooth usage string, BT picker CALayer bounds (nav-wrapped). Re-test:
      start drill, tap Next, Settings → Connect Bluetooth, connect a device.
- [ ] **Hardware MIDI end-to-end test** — connect a real USB/BT MIDI keyboard,
      set Input → MIDI in the trainer, confirm held notes light green/red and
      auto-advance works. Only the picker + note plumbing were unit-reasoned;
      never tested with real hardware.
- [ ] **Mic input real-world test** — FFT detector quality on real piano chords
      (false notes? misses?). If too weak, prioritize the CoreML upgrade (P2).
- [ ] **Audit remaining UIKit-in-SwiftUI / privacy strings** — any other system
      VC or capability (e.g. future notifications) needs its Info.plist string
      to avoid the same class of instant-crash.

## P1 — Ship readiness (App Store / TestFlight)

- [ ] **Paid Apple Developer account** ($99/yr) — required for TestFlight + Store.
- [ ] **App Store Connect setup** — app record, bundle id `app.jazzchords.trainer`,
      name, subtitle, category (Music / Education), age rating.
- [ ] **Archive + upload** — Release config, real distribution signing, upload
      build, invite TestFlight testers.
- [ ] **Store assets** — screenshots (iPhone 6.7"/6.9" + iPad 13"), app preview,
      description, keywords, privacy policy URL (reuse jazzchords.app/privacy),
      support URL.
- [ ] **App icon final polish** — current icon is code-rendered (good); confirm
      it reads at all sizes (Settings/Spotlight/Notification). Consider a dark/
      tinted variant for iOS 18+ icon styles.
- [ ] **Launch screen** — currently generated/blank; add a branded one.
- [ ] **Real device matrix** — test on a small iPhone (SE/13 mini) + older iPad;
      check safe areas, Dynamic Type XL, landscape.

## P2 — Quality bar (makes it feel finished)

- [ ] **CoreML basic-pitch mic** — convert the Spotify TFJS model → CoreML
      (Python 3.11 venv + tensorflow + coremltools), parity-test vs web,
      swap `MicInput.detector` to `CoreMLBasicPitchDetector`. Scaffold + drop-in
      point already in place (`PitchDetectors.swift`). Biggest audio-quality win.
- [ ] **Real sampled grand piano** — find/license an uncompressed `.sf2`
      (FluidR3 full is 141 MB; want a compact piano-only sf2 ~5–15 MB). Drop in
      as `GrandPiano.sf2`; the sampler path is already wired and guarded. Until
      then the synth voice ships.
- [ ] **Other sound presets** — electric piano / vibraphone / organ / pad
      currently approximated by the additive synth; tune timbres or add patches.
- [ ] **Voice-leading modes B & C** (find-inversion / free) — engine
      (`validateFindInversion`/`validateFreeVoicing`) is ported + tested but no
      UI yet; only guided VL ships. Needs MIDI/mic input UI.
- [ ] **Full i18n** — only plan/course/module names + a humanized lesson title
      are localized (English). Lesson theory text, German locale, and the rest of
      `en.ts`/`de.ts` are not ported. Decide if German matters for launch.
- [ ] **Lesson theory content** — lesson player shows the example chord/interval
      + a generic "tap continue", not the real theory copy from `course.*.theory`
      i18n keys. Port the teaching text.

## P3 — iPad / UX deepening

- [ ] **Progress screen on iPad** — still single-column-ish; make charts wider,
      multi-column (trend + weak-spots + PBs side by side).
- [ ] **Learn detail as split pane** — on iPad, course → lessons could use the
      3rd split-view column instead of a push.
- [ ] **Practice cards richer** — show last-played / mastery / best time per plan.
- [ ] **Keyboard window / external display** — iPad + Stage Manager / external
      monitor polish.
- [ ] **Haptics audit** — confirm haptics fire on correct chord, level-up, PB
      across both devices.
- [ ] **Pull-to-refresh + empty/error states** — re-verify every data screen has
      all three states (mostly done; double-check Learn + lesson player).

## P4 — Product / monetization / growth

- [ ] **StoreKit 2 Pro** — `SubscriptionStore` is a stub returning `isPro = true`
      (everything free). To monetize iOS: real product, `Transaction.updates`,
      purchase/restore, and re-gate custom progressions + adaptive drill
      (matching the web's Guideline-3.1.1-safe approach). Decision pending.
- [ ] **Push notifications** — daily practice reminder / streak-saver (the web
      habit engine has `scheduleDailyReminder`/`scheduleStreakSaver`; iOS needs
      UNUserNotificationCenter + a usage prompt + scheduling). Big retention lever.
- [ ] **Home-screen widget** — streak / "today's plan" widget (WidgetKit).
- [ ] **Cloud sync** — optional Supabase auth + progress backup (web has
      `cloud-sync.ts`); currently iOS is local-only. Needs the API/CORS shipped
      to production first.
- [ ] **iCloud/Handoff** — sync progress across the user's own devices.

## P5 — Engineering hygiene

- [ ] **CI** — run `swift test` (MusicEngine, 66 tests) + the xcodebuild
      compile-gate on PRs.
- [ ] **Crash reporting** — add a lightweight crash/error reporter for TestFlight
      (these 3 crashes were only caught by manual device testing).
- [ ] **App size** — audit bundle (art webp, fonts); ensure no stray large assets.
- [ ] **Accessibility pass** — VoiceOver labels on the keyboard, trainer controls,
      celebration overlay; Dynamic Type on the chord symbol.
- [ ] **Settings completeness** — input mode, theme override, language, daily-goal
      edit, notification toggle are referenced in copy but not all wired in
      Settings yet.

---

### Known shortcuts taken (context)
- Audio = additive synth, not sampled (sf3 crashed; sf2 pending).
- Mic = FFT peak-picker, not the ML model (CoreML conversion pending).
- Pro features all unlocked (StoreKit deferred per plan).
- i18n = names only, English only.
- VL modes B/C, lesson theory text, push, widgets, cloud sync = not built.
