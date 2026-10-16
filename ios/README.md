# JazzChords iOS / iPadOS

Native SwiftUI app (iOS 17+, iPhone + iPad). The music logic lives in the
`MusicEngine` Swift package, a 1:1 port of the web engine; the app target in
`JazzChords/` holds UI, audio/MIDI/mic input, persistence and telemetry.

Release scope and decisions: `docs/DECISIONS.md` (section "iOS-App v1.0").
Open work: `TODO.md`.

## Build

Requirements: a **release** Xcode (App Store Connect rejects uploads built with
a beta), `xcodegen` (`brew install xcodegen`).

```sh
cd ios/MusicEngine && swift test            # engine tests
cd ../JazzChords && xcodegen generate       # after adding/removing files
xcodebuild -project JazzChords.xcodeproj -scheme JazzChords \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

`project.yml` is the source of truth for the Xcode project and `Info.plist`.
Run `xcodegen generate` and commit the regenerated `project.pbxproj` whenever
files are added.

## Release

1. Bump `MARKETING_VERSION` (user-facing) and `CURRENT_PROJECT_VERSION`
   (build number, must increase on every upload) in `project.yml`, regenerate.
2. Xcode → Product → Archive (Release, automatic signing, team set in
   `project.yml` → `DEVELOPMENT_TEAM`).
3. Organizer → Distribute App → App Store Connect → Upload.
4. TestFlight first; App Store submission only with Aaron's go.

Already handled in the project: `ITSAppUsesNonExemptEncryption = NO` (no export
compliance question), privacy manifest (`Resources/PrivacyInfo.xcprivacy`),
localized permission texts (`*.lproj/InfoPlist.strings`), launch colour.

**App Privacy label** in App Store Connect must match the manifest: *Product
Interaction* and *Device ID*, used for *Analytics*, **not linked** to the user,
**not used for tracking**. No other data is collected (no account, mic audio is
analysed on device and never stored).

## Daily reminder

- Date logic: `MusicEngine/Sources/MusicEngine/Reminders.swift` (tested in
  `RemindersTests`).
- Scheduling: `JazzChords/Store/ReminderScheduler.swift` keeps 7 local
  notifications ahead (slot ids `practice-reminder-0…6`), none today once the
  player practiced; rebuilt on app foreground, session end and settings change.
- Permission: `Views/ReminderOfferCard.swift` offers it once after the first
  finished drill; only "Remind me" triggers the system dialog. Settings has the
  toggle and time.
- Telemetry (`coach_events`, `app = 'ios'`): `reminder_prompt_shown`,
  `reminder_prompt_accepted`, `reminder_prompt_declined` (`system`: whether the
  iOS dialog was shown, `source`: `card` | `settings`), `app_opened_from_reminder`.

## Telemetry

`Store/TelemetryService.swift`: anonymous per-install UUID, batched inserts into
Supabase `coach_events` with the publishable anon key (RLS: insert only).
`version` is `ios-<CFBundleShortVersionString>` in Release, `ios-dev` in Debug,
so development traffic can be filtered out. Opt-in: nothing is sent and no
device ID exists until the user agrees on the last onboarding page or in
Settings (`coach-telemetry-consent`). Opting out deletes the device ID.
