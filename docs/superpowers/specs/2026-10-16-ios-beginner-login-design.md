# iOS: beginner-friendly app, central settings, icons, Lernen guides, login + sync

Date: 2026-10-16 · Thread: App Store (roadmap step 4) · Target: Build 4 (1.0.0)

## Why

Aaron's device test of Build 3 (16.10. 12:06 UTC): the redesign looks right, but a
newcomer understands nothing on first open. "Session 1", "Seite B", "0 / – / 0",
seven unlabeled dots and badges like 1·3·7 / R / Δ7 are insider language. Settings
still use the old design and a gear sits on every tab. Lernen looks empty next to the
website. Lesson titles wrap to two lines. There is no login, so progress does not
follow him between iPhone, iPad and the browser.

Success: someone who has never used the app knows what to tap first and why, without
reading anything else; Aaron opens the app on iPad and finds the same history he made
on iPhone and in the browser.

## Decisions already made

| Decision | By | When |
|---|---|---|
| Row F mockups (Heute-Neu, Einstellungen, Üben-Icons) are the design | Aaron | 16.10. 12:15 |
| Sync for **all** accounts, free included; web drops its Pro gate too | Aaron | 16.10. 12:07 |
| Login = e-mail + password and Sign in with Apple; Google/GitHub stay web-only | default, told Aaron | 16.10. |
| Exercise name "Quintenzirkel", subline "in Quarten, wie im Jazz geübt" | Jazz Lead | 16.10. |
| "So funktioniert's" lifetime rule (below) | CPO | 16.10. |

Design reference: https://claude.ai/artifact/WY7kugn8bEAT3TqNNKkYDp, row F.

## 1. Heute for newcomers

`TodayView` gets two states, decided by a pure function
`TodayStage.of(history:, calibrated:, profile:, now:, dismissed:)` in the app (tested).

- **Header:** date line ("Donnerstag, 16. Oktober") + serif title. Title is
  "Willkommen" until the first finished session, then the existing greeting.
  "Session N" disappears from the eyebrow everywhere.
- **Profile circle** (44 pt, top right of Heute only): initial of the account e-mail
  when signed in, a `person` glyph when not. Opens the new Settings sheet. This is
  the only entry to Settings; `SettingsHeaderButton` is removed from Üben, Lernen,
  Fortschritt (4 call sites today).
- **Feature block, first step:** until calibration is done, the red block reads
  eyebrow "DEIN ERSTER SCHRITT", title "Ein kurzer Check: Wir hören, was du schon
  kannst.", three chips Δ7 / 7 / –7 with plain words under each (Dur-Septakkord,
  Dominant, Moll-Sept), button "Check starten" + "3 Minuten · kein Druck". It starts
  the existing coach session (whose first block is calibration). After calibration
  the block is today's coach session as now (steps row from Build 3 stays).
- **"So funktioniert's"** (three numbered steps: Check machen · Täglich 5 Minuten ·
  Griffe sitzen) replaces the stats row while newcomer rules hold.
  - Visible until calibration is done AND 3 sessions are finished, but never longer
    than 7 days after first launch.
  - A × in its top-right corner hides it for good (stored flag).
  - Done steps get a gold check; the next step is emphasized. Step 1 done =
    calibrated; step 2 done = 3 sessions.
- **Stats row** appears only once the guide is gone, and only with real numbers
  (no "–", no 0 values: a stat with no data is omitted).
- **"Seite B" and the dots go.** In their place "ODER EINFACH LOSSPIELEN": a grouped
  list with icon rows (Aufwärmen · "Leichte Akkorde zum Einspielen", Ohne Klavier ·
  "Akkorde unterwegs im Kopf üben"), each with a one-line plain subline. For returning
  users the list also shows the weak-spot drill row when history names weak spots.
- The weekday dots, if kept anywhere, carry labels (Mo Di Mi …). In Build 4 they are
  removed from Heute; the streak lives in the stats row.

## 2. Settings + account (new)

New `SettingsView` in the editorial style, presented as a sheet with "Fertig".

1. **Account card** (dark ink block, gold eyebrow "DEIN KONTO"):
   - Signed out: "Auf iPhone, iPad und im Browser genau da weitermachen, wo du
     warst." · "Mit Apple anmelden" · "Mit E-Mail anmelden" · "Gleiches Konto wie auf
     jazzchords.app".
   - Signed in: e-mail, "Synchronisiert · zuletzt 12:41" (or "Synchronisiere…" /
     "Offline, wird nachgeholt"), "Abmelden", and "Konto löschen" (destructive, with
     confirmation). Account deletion inside the app is an App Store requirement
     (guideline 5.1.1(v)) once sign-up is possible.
2. **Üben:** Akkord-Schreibweise (value + chevron), Klang, Keyboard verbinden
   (Bluetooth MIDI sheet, existing).
3. **Erinnerung:** toggle + time (existing ReminderScheduler).
4. **Darstellung:** segmented Hell / Dunkel / Wie iPhone.
5. **Datenschutz:** "Anonym beim Verbessern helfen" toggle (existing telemetry
   opt-in, default off) + footnote.
6. **Über JazzChords:** Hilfe & Kontakt, Datenschutzerklärung, Impressum (links to
   the website), footer line.

Every row uses the same 30 pt rounded-square icon tile as Üben (section 3).
All settings that exist today keep their storage keys; only the UI changes.

## 3. Üben: one icon system

Rule: an icon shows **what you do**; a chord symbol shows **what you play** and is
never used as an icon. One SF Symbols set, same weight, gold tint on a light gold
32 pt rounded square (dark mode: `featureAccent` on `group`).

The red feature block leaves Üben (Heute owns the recommendation). Header:
"Üben" + "Wähle, was du heute trainieren willst." Groups by goal; each row has
title, plain-language subline, chord count.

| Group | Plan id | Title | Symbol |
|---|---|---|---|
| Zum Einstieg | warmup | Aufwärmen | flame |
| | speed | Sprint | stopwatch |
| Typische Jazz-Folgen | deepdive | II–V–I | stairs |
| | turnaround | Turnaround | arrow.trianglehead.2.clockwise |
| | quartenzirkel | Quintenzirkel | circle.dotted |
| | voice-leading-flow | Stimmführung | point.topleft.down.to.point.bottomright.curvepath |
| Gezielt trainieren | voicing-drill | Ein Griff, alle Tonarten | pianokeys |
| | inversions-drill | Umkehrungen | arrow.up.arrow.down |
| | left-hand-comping | Linke Hand begleiten | hand.raised |
| | in-time-comping | Im Takt begleiten | metronome |
| | ear-check | Nach Gehör | ear |
| | adaptive-drill | Schwachstellen | scope |
| | challenge | Challenge | flag.checkered |
| Eigene Wege | free | Frei üben | infinity |
| | custom | Eigene Folge | slider.horizontal.3 |

Sublines come from the existing plan taglines, rewritten where they use jargon.
Mapping lives in one table (`PlanPresentation`) that a test checks covers every
`PRACTICE_PLANS` id and uses no chord-symbol text. Symbols that don't exist on the
deployment target fall back to a listed alternative (checked on the Mac build).

## 4. Lernen

- **Guides section** under the courses: the website's guide articles, rendered
  natively (serif headings, body text, chord examples in Kalam), bundled as Markdown
  so they work offline. German app → the German articles where they exist
  (`/de/ii-v-i-alle-tonarten`, `/de/voicings-linke-hand`, `/de/leadsheet-spielen-klassik`),
  English otherwise until translated: ii-V-I, Rootless Voicings, Jazz Piano Voicings,
  Left Hand. App-comparison and entrance-exam pages are marketing, not learning, and
  stay web-only.
  Each guide ends with a "Jetzt üben" button that starts the matching plan.
- **Lesson titles:** rows allow two lines with proper line height and leading
  alignment instead of truncating oddly; long titles get shorter German names
  where a shorter one exists (e.g. "Große & kleine Terz" → "Terzen"). A test lists
  titles longer than 22 characters so none slips through unreviewed.

## 5. Login + sync

### Accounts

- Same Supabase project and users as the web (`chpoqghvlojwyunoplab`).
- Library: `supabase-swift` (Auth + PostgREST) via SPM; the session lives in the
  Keychain (SDK default) and refreshes itself.
- **Sign in with Apple:** native `ASAuthorizationAppleIDProvider` →
  `auth.signInWithIdToken(.apple, idToken, nonce)`. Needs the "Sign in with Apple"
  capability on the App ID and the Apple provider enabled in Supabase with the
  bundle id as client id (see "Needs Aaron").
- **E-mail:** sign in / create account with password; "Passwort vergessen" sends
  the existing Supabase reset mail (reset happens on the website).
- Sign-up from the app never opts anyone into marketing mail (consent stays the
  double-opt-in flow).

### Data

The iOS stores already mirror the web's shapes. A mapping table ties each iOS store
key to its web key inside `user_data.data`:

| iOS key | web key |
|---|---|
| history | chord-trainer-history |
| streak | chord-trainer-streak |
| settings | chord-trainer-settings |
| habit-profile | chord-trainer-habit-profile |
| course-progress | chord-trainer-course-progress |
| coach-state | chord-trainer-coach-state |
| togo-cards | chord-trainer-togo-cards |

Keys the web syncs that iOS does not own (celebrations, theme, locale) are carried
through untouched so iOS never deletes them.

### Merge (port of web `cloud-merge.ts`, same rules)

- history: union by id (fallback `t<timestamp>`), newest first, cap 100.
- habit profile: the side with more total XP wins; `onboardingDone` is OR of both.
- streak: the side with the later `lastDate` wins; `best` is the max.
- everything else: the account's value wins on login.
- Onboarding flag also honors `user_metadata.onboarding_done` (as PR #21).

The Swift merge works on raw JSON (`[String: JSONValue]`) so unknown fields survive
round trips. It is tested with the same cases as `cloud-merge.test.ts`.

### Flow

1. Sign-in succeeds → **hydrate**: fetch the account row, merge with device data,
   write the merged result to the device stores, upload the union. Until hydrate has
   succeeded for this user, nothing is uploaded (same guard as web `ensureHydrated`).
2. After each finished session, settings change, course progress or coach-state
   save: debounced upload (3 s), whole row upsert (same as web).
3. App comes to foreground while signed in: pull + merge again (so iPad picks up
   what iPhone did since).
4. Offline: uploads queue as "dirty"; retried on next foreground or network change.
5. Sign-out: stop syncing; device data stays on the device.
6. Delete account: calls the web endpoint `POST /api/account/delete` with the
   access token; on success signs out and clears the account card.

### Web changes (same PR)

- `syncToCloud` loses the `canUse('cloud-sync')` gate; `subscription.ts` drops the
  `cloud-sync` Pro feature and the upgrade-sheet case.
- `/api/account/delete` accepts `Authorization: Bearer <access token>` in addition
  to the cookie session.

## Error handling

- Sign-in errors show inline under the buttons in plain German ("E-Mail oder
  Passwort stimmt nicht", "Keine Verbindung").
- A failed hydrate leaves the device data untouched and retries on next foreground;
  the account card shows "Noch nicht synchronisiert".
- Merge never deletes sessions; worst case on conflicting settings is that the
  account's settings win once.

## Testing

- App unit tests (Mac): `TodayStage` (newcomer rules incl. 7-day cap and ×),
  `PlanPresentation` coverage + no chord symbols, lesson-title length list,
  key mapping round trip, Swift merge with the web test cases, upload guard before
  hydrate.
- Web: existing vitest suite + a test that free users sync; endpoint test for the
  bearer path.
- Device: Aaron on iPhone + iPad + browser with one account.

## Needs Aaron

1. **Supabase → Authentication → Providers → Apple:** enable, client id
   `app.jazzchords.trainer` (the app's bundle id). Without it the Apple button fails;
   e-mail login works regardless.
2. On the Mac build: allow adding the "Sign in with Apple" capability to the App ID
   (automatic signing, as with Build 1–3).

## Out of scope

Google/GitHub login on iOS, in-app purchase / Pro on iOS, translating the
English-only guides, realtime sync while two devices are open at once.
