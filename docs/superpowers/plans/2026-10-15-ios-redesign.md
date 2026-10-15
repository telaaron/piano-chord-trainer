# iOS Redesign „Editorial × iOS“ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the card/glass-card look of the SwiftUI app with the approved „Final“ design (serif + Real-Book handwriting in content, Liquid Glass only on controls) without changing app behaviour.

**Architecture:** Design system first (semantic palette roles, fonts with accidental fallback, a small set of components in `Views/Editorial/`), then each screen swaps its presentation to those components. Stores, Audio, MusicEngine stay untouched. One new behaviour: chord preview sheet on Heute.

**Tech Stack:** SwiftUI (iOS 17+, Swift 6), xcodegen, XCTest, MusicEngine (local SPM package).

**Spec:** `docs/superpowers/specs/2026-10-15-ios-redesign-design.md` · Mockups: https://claude.ai/artifact/7rkC7Hmsvn318ELN1grGC9 (page „Final“)

## Global Constraints

- Deployment target stays iOS 17.0; `SWIFT_VERSION` 6.0; Liquid Glass via `#available(iOS 26.0, *)` with material fallback.
- Colours exactly as spec §3.1 table (dark/light hex values verbatim).
- Fonts: Instrument Serif (Regular, Italic), Kalam Bold, SF Mono for eyebrows, SF for UI. Space Grotesk is removed at the end.
- Red (`action`) = act/error, Gold (`music`) = music/success/progress. Exactly one `FeatureBlock` per screen.
- Glass only on: tab bar, toolbar circle buttons, trainer progress capsule, secondary button. Never on content.
- No staff lines on Heute; `LeadSheetStrip` only in the trainer.
- No changes under `Store/`, `Audio/`, `ios/MusicEngine/` (except reading APIs).
- All existing MusicEngine tests (`swift test`) stay green; new app tests live in `JazzChordsTests`.
- Builds/tests run only on Aaron's Mac (Remote Control): no Swift toolchain in the cloud container.
- Strings: every new user-visible string goes through `CoachL10n`/`Strings` with DE + EN.

## Review Focus

1. Chord symbols with ♭/♯/Δ/ø/° in Kalam and Instrument Serif must not render as boxes → test in Task 1.
2. Dynamic Type XXL must not clip the 148 pt trainer chord or the StatsRow → `minimumScaleFactor` + preview check in Tasks 3/8.
3. A coach plan with no focus block / empty roots must not crash the Heute chord row → test in Task 7 (empty → row hidden).
4. Held wrong notes (MIDI/mic) must still be visibly wrong after the green→gold switch → test in Task 5.
5. iPad split view and landscape trainer must keep working with the new components → manual check in Task 13.

---

### Task 1: Test target, fonts, accidental-safe typography

**Files:**
- Modify: `ios/JazzChords/project.yml` (add `JazzChordsTests` target, bundle tests; `UIAppFonts`)
- Already done in de2701a: `Resources/Fonts/InstrumentSerif-Regular.ttf`, `InstrumentSerif-Italic.ttf`, `Kalam-Bold.ttf`, OFL licenses, `UIAppFonts` entries (verified: neither font has ♭ ♯ Δ →)
- Modify: `ios/JazzChords/JazzChords/Theme/Typography.swift`
- Test: `ios/JazzChords/JazzChordsTests/TypographyTests.swift`

**Interfaces:**
- Produces: `enum Display` with `static func serif(_ size: CGFloat, italic: Bool = false, relativeTo: Font.TextStyle = .largeTitle) -> Font`, `static func chord(_ size: CGFloat, relativeTo: Font.TextStyle = .largeTitle) -> Font` (Kalam), `static func eyebrow(_ size: CGFloat = 12) -> Font` (SF Mono medium), `static func uiFont(family: String, size: CGFloat) -> UIFont?` (cascade, internal for tests). `Text.chordText(_:)` keeps its name and now uses Kalam.
- Family names as registered: `"Instrument Serif"`, `"Kalam"` (verify with `UIFont.familyNames` in the test).

- [ ] **Step 1:** Add to `project.yml` a `JazzChordsTests` target (`type: bundle.unit-test`, `platform: iOS`, sources `JazzChordsTests`, dependency `JazzChords`, `GENERATE_INFOPLIST_FILE: YES`) and a scheme `JazzChords` whose test action includes it. Space Grotesk stays in `UIAppFonts` until Task 12.
- [ ] **Step 2: Write the failing tests**

```swift
func testFamiliesRegistered() {
    XCTAssertTrue(UIFont.familyNames.contains("Instrument Serif"))
    XCTAssertTrue(UIFont.familyNames.contains("Kalam"))
}
func testAccidentalsResolveInKalam() throws {
    let f = try XCTUnwrap(Display.uiFont(family: "Kalam", size: 40))
    for glyph in ["♭", "♯", "Δ", "ø", "°", "→"] {
        let w = (glyph as NSString).size(withAttributes: [.font: f]).width
        let b = ("B" as NSString).size(withAttributes: [.font: f]).width
        XCTAssertLessThan(w, b * 1.2, "\(glyph) falls back to a box")
    }
}
func testAccidentalsResolveInInstrumentSerif() { /* same loop, family "Instrument Serif" */ }
```

- [ ] **Step 3:** Run on the Mac: `cd ios/JazzChords && xcodegen && xcodebuild test -project JazzChords.xcodeproj -scheme JazzChords -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:JazzChordsTests/TypographyTests` → FAIL (`uiFont` undefined).
- [ ] **Step 4:** Generalise `cascadedUIFont` into `uiFont(family:size:)` (cascade list `["AppleSymbols"]`, return nil if resolved family differs); build `serif`, `chord`, `eyebrow` on it with `UIFontMetrics(forTextStyle:).scaledFont` for Dynamic Type. Keep `title`/`headline` as wrappers over `serif` so existing call sites compile.
- [ ] **Step 5:** Re-run → PASS. Also `cd ios/MusicEngine && swift test` → all green.
- [ ] **Step 6:** Commit `feat(ios): Instrument Serif + Kalam with accidental fallback, app test target`.

### Task 2: Semantic palette roles

**Files:**
- Modify: `ios/JazzChords/JazzChords/Theme/Theme.swift`
- Test: `ios/JazzChords/JazzChordsTests/PaletteTests.swift`

**Interfaces:**
- Produces on `Palette`: `canvas, ink, inkMuted, hairline, group, action, onAction, music, musicFill, keyBed: Color` (keyBed: dark `070A0F`, light `1A1916`). Also `Theme.radiusGroup: CGFloat = 22`, `Theme.radiusFeature: CGFloat = 26`. Old fields stay.

- [ ] **Step 1: Failing test** — for `.dark` and `.light`, assert each role equals `Color(hex:)` of the spec §3.1 value (compare via `UIColor(...).cgColor.components`), e.g. `XCTAssertEqual(rgb(Palette.dark.music), rgb(Color(hex: "E8B04B")))`, `XCTAssertEqual(rgb(Palette.light.canvas), rgb(Color(hex: "F6F2EA")))`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Add the stored properties and values to both static palettes.
- [ ] **Step 4:** Run → PASS. Commit `feat(ios): semantic palette roles (action/music/canvas)`.

### Task 3: Editorial components and glass rework

**Files:**
- Create: `ios/JazzChords/JazzChords/Views/Editorial/FeatureBlock.swift`, `StatsRow.swift`, `EditorialHeader.swift`, `TrackRow.swift`, `Buttons.swift` (`PrimaryCapsule`, `GlassCircleButton`, `GlassSecondaryButton`)
- Modify: `ios/JazzChords/JazzChords/Views/Glass.swift` (add `glassControl(in: some Shape)`; keep `glassCard` until Task 12)

**Interfaces:**
- `FeatureBlock<Content: View, Action: View>(eyebrow: String, ghost: String? = nil, @ViewBuilder content:, @ViewBuilder action:)` — background `action`, foreground `onAction`, radius 26, padding 20; ghost in `Display.chord(170)` at `onAction.opacity(0.2)`, bottom-trailing, clipped, `accessibilityHidden(true)`.
- `StatsRow(items: [StatItem])`, `struct StatItem: Identifiable { let value: String; let label: String }` — top 1 pt rule in `ink`, 1 pt vertical `hairline` between, value `Display.serif(32)` in `music` with `minimumScaleFactor(0.6)`, label `.caption` `inkMuted`; combined accessibility element "value label".
- `EditorialHeader(eyebrow: String?, title: String)` — eyebrow `Display.eyebrow()` uppercase `inkMuted`, title `Display.serif(44)` `ink`, `.accessibilityAddTraits(.isHeader)` on title.
- `TrackRow(badge: String?, number: String?, title: String, meta: String?, showsDivider: Bool)` — badge `Display.chord(18)` in `music`, number `Display.serif(22)` in `music`, title `.body`, meta `.subheadline` `inkMuted`; min height 52. `TrackGroup { … }` wraps rows: `group` background, radius 22.
- `PrimaryCapsule(title: String, systemImage: String? = nil, action: () -> Void)` — height 56, `action` fill, `onAction` text, full width.
- `GlassCircleButton(systemImage: String, label: String, action:)` — 44×44, `glassControl(in: Circle())`.

- [ ] **Step 1:** Implement each component with a `#Preview` in dark and light (`.environment(\.palette, .light)`), using the Heute mockup values.
- [ ] **Step 2:** Build on the Mac (`xcodebuild build … -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`) → succeeds; check previews at Dynamic Type XXL (no clipping in StatsRow).
- [ ] **Step 3:** Commit `feat(ios): editorial component set`.

### Task 4: LeadSheetStrip and FunctionGrid

**Files:**
- Create: `ios/JazzChords/JazzChords/Views/Editorial/LeadSheetStrip.swift`, `FunctionGrid.swift`
- Test: `ios/JazzChords/JazzChordsTests/FunctionGridTests.swift`

**Interfaces:**
- `LeadSheetStrip(previous: String?, current: String, next: String?)` — five 1 pt `hairline` lines 8 pt apart, bar lines, chords in `Display.chord`: previous 22 pt `inkMuted` 60 %, current 28 pt `action`, next 22 pt `inkMuted`. Accessibility label „vorher X, jetzt Y, danach Z“ via `Strings`.
- `enum ToneState { case ok, missing, open }`, `struct FunctionTone: Identifiable, Equatable { let note: String; let function: String; let state: ToneState }`.
- `static func FunctionGrid.tones(voicingNotes: [String], labels: [String], expected: Set<Int>, held: Set<Int>, showResult: Bool) -> [FunctionTone]` — pitch class of each note via `noteToSemitone`; `held` is MIDI note numbers (mod 12). `showResult == false` → all `.open`; otherwise `.ok` if its pitch class is held, else `.missing`. Labels come from `getVoicingIntervalLabels` mapped through `Strings` (Grundton/Terz/Septime…).
- `FunctionGrid(tones: [FunctionTone])` — `ok` note in `music`, `missing` dashed 1.5 pt `action` border + `action` text, `open` in `ink`.

- [ ] **Step 1: Failing tests**

```swift
func testOpenBeforeResult() {
    let t = FunctionGrid.tones(voicingNotes: ["D","F","C"], labels: ["Grundton","Terz","Septime"],
                               expected: [2,5,0], held: [], showResult: false)
    XCTAssertEqual(t.map(\.state), [.open, .open, .open])
}
func testMissingThird() {
    let t = FunctionGrid.tones(voicingNotes: ["D","F","C"], labels: ["Grundton","Terz","Septime"],
                               expected: [2,5,0], held: [50, 60], showResult: true)
    XCTAssertEqual(t.map(\.state), [.ok, .missing, .ok])
}
func testEnharmonicHeld() { // E♭ held as D♯ (MIDI 63) counts for "E♭"
    let t = FunctionGrid.tones(voicingNotes: ["C","E♭","B♭"], labels: ["Grundton","Terz","Septime"],
                               expected: [0,3,10], held: [60, 63, 70], showResult: true)
    XCTAssertEqual(t.map(\.state), [.ok, .ok, .ok])
}
```

- [ ] **Step 2:** Run `-only-testing:JazzChordsTests/FunctionGridTests` → FAIL.
- [ ] **Step 3:** Implement `tones` and both views (+ previews).
- [ ] **Step 4:** Run → PASS. Commit `feat(ios): lead sheet strip and function grid`.

### Task 5: Keyboard restyle

**Files:**
- Modify: `ios/JazzChords/JazzChords/Views/PianoKeyboard.swift:131-152` (fill functions), key shapes/bed
- Test: `ios/JazzChords/JazzChordsTests/KeyboardColorTests.swift`

**Interfaces:**
- Extract `enum KeyRole { case idle, voicing, held(correct: Bool), selected, missing }` and `static func PianoKeyboard.role(chrIdx: Int, voicing: Set<Int>, held: Set<Int>, expected: Set<Int>, selected: Set<Int>, showInput: Bool, showMissing: Bool) -> KeyRole`; `func fill(for: KeyRole, isBlack: Bool) -> Color`: voicing/held-correct/selected → `musicFill`; held-wrong → `action`; missing → base key colour + 2.5 pt inner `action` stroke; idle → existing white/black.
- New init parameter `showMissing: Bool = false` (trainer passes true after a wrong attempt).

- [ ] **Step 1: Failing tests:** held wrong key → `.held(correct: false)` and `fill` == `palette.action`; held correct → `.held(correct: true)` and `fill` == `palette.musicFill`; expected but not held with `showMissing` → `.missing`; idle without input → `.idle`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement; bed `keyBed`, edge-to-edge (no outer padding), white key bottom radius 6, labels on `voicing`/`missing` keys only. **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(ios): keyboard in gold/red roles`.

### Task 6: Root navigation

**Files:** Modify `ios/JazzChords/JazzChords/App/RootView.swift`

- [ ] **Step 1:** `TabView` gets `.tint(palette.action)`; every tab root gets `.toolbar(.hidden, for: .navigationBar)` on the root screen (headers are `EditorialHeader` now) and the settings entry moves into each root screen as `GlassCircleButton(systemImage: "slider.horizontal.3", …)` top-trailing (pass a `showSettings` binding via `@Environment` key `openSettings: () -> Void`). Sheet `presentationBackground(palette.canvas)`. iPad sidebar: `.listStyle(.sidebar)`, `scrollContentBackground(.hidden)`, background `canvas`, title in `Display.serif(28)`.
- [ ] **Step 2:** Build, run on simulator: tabs switch, settings opens from every tab, iPad sidebar renders. Commit `feat(ios): editorial navigation shell`.

### Task 7: Heute

**Files:**
- Modify: `ios/JazzChords/JazzChords/Views/TodayView.swift`
- Create: `ios/JazzChords/JazzChords/Views/TodayChordPreview.swift`
- Test: `ios/JazzChords/JazzChordsTests/TodayChordPreviewTests.swift`

**Interfaces:**
- `enum TodayChordPreview { static func chords(for plan: CoachPlan, max: Int = 3) -> [ChordWithNotes] }` — pick the first block with kind `.focus` or `.new`, else the first block; if `settings.progressionMode != .random && != .custom`, take the first `max` chords of `generateProgression(mode, accidentals, notation, max)`; else build chords from `focusRoots ?? ["C"]` × `focusQualities ?? []` via `getChordNotes`/`getVoicingNotes` with `settings.voicing`; empty plan or no qualities → `[]`.
- `ChordPreviewSheet(chord: ChordWithNotes, voicing: VoicingType)` — chord name `Display.chord(40)`, `PianoKeyboard(chordData:showVoicing:true)`, `PrimaryCapsule` „Anhören“ calling the existing preview-audio path (`AudioEngine.shared.playChord` or whatever `PianoKeyboard` tap preview already uses), `.presentationDetents([.height(300)])`.

- [ ] **Step 1: Failing tests:** plan with one `.focus` block, `focusRoots: ["B♭"]`, `focusQualities: ["Maj7"]`, random mode → 1 chord whose `root == "B♭"`; plan with `progressionMode: .twoFiveOne` → 3 chords; plan with `blocks: []` → `[]`; focus block with `focusQualities: nil` and random mode → `[]`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement `TodayChordPreview`. **Step 4:** Run → PASS.
- [ ] **Step 5:** Rebuild `TodayView.phoneStack` in this order: `EditorialHeader(eyebrow: "<Wochentag> · <Datum> / SESSION <n>", title: Strings "Heute")` + settings button → `FeatureBlock(eyebrow: "HEUTE DRAN · <estMinutes> MIN · <targetChords sum> AKKORDE", ghost: "Δ7")` containing the chord row (each chord a `Button` with Kalam 30 pt, dashed 1 pt `onAction.opacity(0.3)` outline, arrows between; row hidden when `chords` is empty), the existing `coachSay` as `Display.serif(20, italic: true)`, action `PrimaryCapsule`-style cream capsule „Weiter üben“ starting the coach (existing `startCoach`) → `StatsRow` (streak days, Ø s/chord from `computeStats`, mastered voicings count already shown on Progress) → section „SEITE B · SELBST WÄHLEN“ (eyebrow) + `TrackGroup` with existing manual options (suggested plan, weak drill, To-Go) as `TrackRow`s. Week dots, motivation and reminder offer become a single muted text line / `TrackRow` below. Remove `hero`, `HeroGradient`, `CardSurface` usage from this file. iPad dashboard: same components in two columns.
- [ ] **Step 6:** Build, compare simulator screenshot with mockup „Heute · Dunkel/Hell“; tap a chord → sheet shows the voicing and plays it. Commit `feat(ios): Heute in editorial layout with chord preview`.

### Task 8: Trainer session and result

**Files:** Modify `ios/JazzChords/JazzChords/Views/TrainerView.swift` (`topBar` 350, `chordBlock` 366, `keyboardBlock` 417, `controls` 442, result view 516-605)

- [ ] **Step 1:** `topBar` → `GlassCircleButton` close · progress capsule (`glassControl(in: Capsule())`, track `musicFill`, `"\(idx+1)/\(total)"` monospaced) · `GlassCircleButton` „Anhören“ (existing play action).
- [ ] **Step 2:** Above the chord, when the session is a progression (`store.progressionMode != .random`), `LeadSheetStrip(previous:current:next:)` from the store's chord list around `currentIdx`.
- [ ] **Step 3:** `chordBlock` → kicker `Display.serif(22, italic: true)` `inkMuted` („<Voicing> · <Stufe>“ from existing `CoachL10n.voicing`), chord `Display.chord(148)` with `minimumScaleFactor(0.5)`, `FunctionGrid(tones: FunctionGrid.tones(…))` when `shouldShowVoicing || inputActive`, feedback line (`ui.correct` in `music`, `ui.not_quite` in `action`). Remove the outlined voicing capsule and monospaced voicing text.
- [ ] **Step 4:** Keyboard edge-to-edge (`.padding(.horizontal, -Theme.space4)` inside the padded stack), pass `showMissing: store.tapResult == false || (store.inputActive && store.hasWrongAttempt)`; below it „nächster: <Kalam chord> — <Stufe>“ when known.
- [ ] **Step 5:** `controls` → `GlassSecondaryButton` „Tipp“ + `PrimaryCapsule` (existing next/check actions, labels unchanged). In-time mode line uses `music` instead of `primary`.
- [ ] **Step 6:** Result view: `statCard` grid → `StatsRow`, headline `EditorialHeader`, one `FeatureBlock` for the coach verdict/next step, remaining buttons `PrimaryCapsule`/`GlassSecondaryButton`.
- [ ] **Step 7:** Build; run a 2-5-1 session in the simulator (portrait + landscape, iPad) with tap-guess and with MIDI off; compare with mockup „Trainer“. Commit `feat(ios): trainer and result in editorial layout`.

### Task 9: Lernen

**Files:** Modify `ios/JazzChords/JazzChords/Views/LearnView.swift`, `ios/JazzChords/JazzChords/Views/LessonPlayerView.swift`

- [ ] **Step 1:** `LearnView`: `EditorialHeader(eyebrow: "KURSE · <lesson count> LEKTIONEN", title: "Lernen")`, `FeatureBlock(eyebrow: "DER WEG · <n> LEKTIONEN", ghost: "Δ7")` for the Ultimate Plan course with `Display.serif(34)` title and an `onAction` progress bar „x von n“, then eyebrow „INHALT“ with a 1 pt `ink` rule and plain rows (no group background): number `Display.serif(22)` `music`, title `Display.serif(24)`, meta `.subheadline` `inkMuted`, status right („fertig“ `music` semibold, „a/b“, „neu“). No „Kurse | Karten“ segment.
- [ ] **Step 2:** `CourseDetailView`: `EditorialHeader` with course title, lessons as `TrackGroup`/`TrackRow` (number + mastery as meta).
- [ ] **Step 3:** `LessonPlayerView`: chord in `Display.chord`, `FunctionGrid` for chord drills, interval drills keep their existing layout with new fonts/colours, buttons `PrimaryCapsule`.
- [ ] **Step 4:** Build; compare with mockup „Lernen“; open a course and run one interval and one chord lesson. Commit `feat(ios): Lernen in editorial layout`.

### Task 10: Üben and Fortschritt

**Files:** Modify `ios/JazzChords/JazzChords/Views/PracticeView.swift`, `ios/JazzChords/JazzChords/Views/ProgressView_.swift`, `ios/JazzChords/JazzChords/Views/Gamification.swift`

- [ ] **Step 1:** Üben: `EditorialHeader`, level groups as eyebrow + `TrackGroup` of `TrackRow` (Kalam badge = sample chord of the plan), custom progression and free practice as `TrackRow`s; the screen's one `FeatureBlock` = recommended plan.
- [ ] **Step 2:** Fortschritt: `EditorialHeader`, `StatsRow` for `statsHeader`, trend chart line/area in `music`, weak spots as `TrackRow(badge: chord, title: quality, meta: "Ø x,y s")`, personal bests as `TrackRow`. `LevelBadge` uses `music`.
- [ ] **Step 3:** Build and check both screens dark/light. Commit `feat(ios): Üben and Fortschritt in editorial layout`.

### Task 11: Secondary screens

**Files:** Modify `Views/ToGoView.swift`, `Views/EarTrainingView.swift`, `Views/CustomProgressionView.swift`, `Views/OnboardingView.swift`, `Views/SettingsView.swift`, `Views/ReminderOfferCard.swift`, `Views/Components.swift` (`SectionHeader` → eyebrow style, `EmptyStateView` fonts)

- [ ] **Step 1:** Replace every `glassCard`, `CardSurface`, `HeroGradient`, `palette.primary`/`stamp`/`accentGreen` use in these files with the components and roles (red = action, gold = success/progress). Forms in Settings stay system `Form` with `scrollContentBackground(.hidden)` on `canvas`.
- [ ] **Step 2:** Build; walk through To-Go, ear training, custom progression, onboarding (reset via Settings), settings. Commit `feat(ios): secondary screens in editorial style`.

### Task 12: Remove the old look

**Files:** Modify `Theme/Theme.swift`, `Theme/Typography.swift`, `Views/Glass.swift`, `Views/Components.swift`, `project.yml`; delete `Resources/Fonts/SpaceGrotesk-*.ttf`

- [ ] **Step 1:** `grep -rnE "glassCard|CardSurface|HeroGradient|Space Grotesk|\.stamp|inkBlue" ios/JazzChords/JazzChords` → expect only definitions; then delete `glassCard`, `GlassCardModifier`, `CardSurface`, `HeroGradient`, Space Grotesk files and `UIAppFonts` entries, and palette fields no longer referenced.
- [ ] **Step 2:** Re-run the grep → no matches. Full test run on the Mac (app tests + `swift test`) → all green.
- [ ] **Step 3:** Commit `refactor(ios): remove card/glass-card look and Space Grotesk`.

### Task 13: Verification on device and Build 3

- [ ] **Step 1:** On Aaron's Mac: `xcodegen`, full `xcodebuild test` (iPhone 17 Pro + iPad Pro simulators) → green; `swift test` in MusicEngine → green.
- [ ] **Step 2:** Screenshots of Heute/Trainer/Lernen in dark + light, Dynamic Type default and XXL, iPad landscape; compare side by side with the „Final“ mockups; fix deviations.
- [ ] **Step 3:** VoiceOver pass on Heute and Trainer (chord announced by name, header traits, StatsRow read as one element).
- [ ] **Step 4:** Bump `CURRENT_PROJECT_VERSION` to `"3"`, commit `chore(ios): build 3`. Archive + TestFlight upload **only after Aaron's go**.
