# App Store screenshots (v1.0)

Raw captures for the store listing. Headlines and framing are added afterwards;
this file only covers what to capture.

## Setup

- Simulator: iPhone 17 Pro Max (6.9", 1320 × 2868), iOS 27, dark appearance
- Status bar: `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`
- Language: capture each frame twice, German and English
  (`-AppleLanguages "(de)" -AppleLocale de_DE`, then `(en)` / `en_US`)
- Data: play real drills in the simulator first so Today, streak and Progress are
  not empty (aim for several sessions with mostly correct answers). Never use
  fake numbers that the app could not produce.
- Save as `ios/store/raw/<lang>/<n>-<name>.png`, e.g. `raw/de/1-trainer.png`

## Frames

| # | Name | Screen |
|---|---|---|
| 1 | trainer | Trainer mid-drill, large chord symbol (e.g. E♭Maj9), correct keys green on the on-screen keyboard |
| 2 | today | Today tab with the coach sentence and the daily ring |
| 3 | input | Trainer input picker showing MIDI, microphone and touch |
| 4 | progress | Progress tab with the session trend and weak spots filled |
| 5 | learn | Learn tab, lesson list |
| 6 | reminder | Result screen with the reminder card, or Today with a visible streak |

Headlines per frame: `/mnt/project-files/app-store/STORE-LISTING.md` §5.
