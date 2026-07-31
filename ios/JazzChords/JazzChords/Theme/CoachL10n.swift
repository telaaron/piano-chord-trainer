// CoachL10n — localized strings for the whole app UI (de + en).
//
// Originally the Coach was the only bilingual feature while the rest of the app
// was English-only inline. That split showed: on a German device the chrome read
// "Good afternoon" / "Your progress" next to the coach's "Weiter üben". The UI
// chrome now goes through this same table, so there is exactly one mechanism and
// one language decision for the entire app. Keys are the engine's i18n keys
// (CoachLabelKeys / CoachSayKeys / CoachFeedbackKeys) plus UI-chrome keys, and
// texts are content-identical to the web source of truth
// (src/lib/i18n/{en,de}.ts) wherever a matching key exists there.
//
// Language selection follows the device's preferred language (de → German, else
// English), matching how a native app localizes without a String Catalog. Params
// are interpolated `{name}`-style exactly like the web `t(key, params)` helper,
// and raw voicing values are localized the same way as web `localizeCoachParams`.
//
// Counted nouns do NOT live in these tables — see `plural(_:_:)` below.

import Foundation
import MusicEngine

enum CoachL10n {
    /// True when the device's top preferred language is German.
    static var isGerman: Bool {
        (Locale.preferredLanguages.first ?? "en").lowercased().hasPrefix("de")
    }

    // ─── Plurals ────────────────────────────────────────────
    // Counted nouns live in Resources/{en,de}.lproj/Localizable.stringsdict
    // rather than in the tables above, because German and English inflect a
    // counted noun differently ("1 Tag"/"2 Tage" vs "1 day"/"2 days") and a
    // `count == 1 ? … : …` at the call site is precisely how "1 days" shipped.
    // A .stringsdict lets the OS apply the CLDR plural category for the chosen
    // language to the actual number, so a call site can only pass a count — it
    // cannot pick a form at all, correctly or otherwise.

    /// The bundle whose language matches `isGerman`. `Locale.preferredLanguages`
    /// and the bundle's own resolution can disagree (e.g. when the app has no
    /// de.lproj match for a regional variant), which would let the plural line
    /// come back English while the surrounding chrome is German. Resolving the
    /// .lproj explicitly keeps both halves of a sentence in one language.
    private static let bundle: Bundle = {
        let lang = isGerman ? "de" : "en"
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let b = Bundle(path: path) { return b }
        return .main
    }()

    /// Localize a counted noun/sentence, e.g. `plural("count.days", 1)` → "1 Tag".
    static func plural(_ key: String, _ count: Int) -> String {
        String(format: bundle.localizedString(forKey: key, value: nil, table: nil), count)
    }

    /// Two-argument plural (the week line: N days + a minutes goal).
    static func plural(_ key: String, _ a: Int, _ b: Int) -> String {
        String(format: bundle.localizedString(forKey: key, value: nil, table: nil), a, b)
    }

    // ─── Interpolation ──────────────────────────────────────
    // Mirrors web `t(key, params)`: look up the raw template, then replace
    // every `{name}` occurrence with its param value.

    /// Localize an engine i18n key, interpolating `{param}` placeholders.
    /// Voicing params arrive as raw values (e.g. "shell") and are localized here,
    /// mirroring the web `localizeCoachParams` step.
    static func t(_ key: String, _ params: [String: String] = [:]) -> String {
        let table = isGerman ? de : en
        var out = table[key] ?? key
        for (name, rawValue) in localizeParams(params) {
            out = out.replacingOccurrences(of: "{\(name)}", with: rawValue)
        }
        return out
    }

    /// Localize a raw voicing value ("shell", "rootless-a", …) for coach labels.
    static func voicingLabel(_ raw: String) -> String {
        guard let v = VoicingType(rawValue: raw) else { return raw }
        let table = isGerman ? deVoicings : enVoicings
        return table[v] ?? raw
    }

    /// One-line "what notes" explanation of a voicing — so the player knows what
    /// to play from a name like E♭9. Mirrors web settings.voicing_*_sub.
    static func voicingSub(_ v: VoicingType) -> String {
        let en: [VoicingType: String] = [
            .root: "Root + all notes from bottom.", .shell: "Root + 3rd + 7th only.",
            .halfShell: "3rd/7th around the root.", .full: "All notes in jazz order: 1-7-3-5.",
            .rootlessA: "3–5–7–9 · Bill Evans style.", .rootlessB: "7–9–3–5 · complement to Type A.",
            .inversion1: "3rd on bottom.", .inversion2: "5th on bottom.", .inversion3: "7th on bottom.",
        ]
        let de: [VoicingType: String] = [
            .root: "Grundton + alle Töne von unten.", .shell: "Nur Grundton + Terz + Septime.",
            .halfShell: "Terz/Septime um den Grundton.", .full: "Alle Töne in Jazz-Reihenfolge: 1-7-3-5.",
            .rootlessA: "3–5–7–9 · Bill-Evans-Stil.", .rootlessB: "7–9–3–5 · Ergänzung zu Typ A.",
            .inversion1: "Terz im Bass.", .inversion2: "Quinte im Bass.", .inversion3: "Septime im Bass.",
        ]
        return (isGerman ? de : en)[v] ?? ""
    }

    /// Copy of `params` with any `voicing` value translated (web `localizeCoachParams`).
    private static func localizeParams(_ params: [String: String]) -> [String: String] {
        var out = params
        if let v = out["voicing"] { out["voicing"] = voicingLabel(v) }
        // The key-tier ('easy'|'med'|'all') becomes a localized suffix like " (easy keys)".
        if let tier = out["tier"] { out["tier"] = t("coach.tier.\(tier)") }
        return out
    }

    // ─── UI chrome keys (not from the engine) ───────────────

    static let heroTitle = "quickstart.coach_hero_title"
    static let heroSub = "quickstart.coach_hero_sub"
    static let pickYourself = "quickstart.pick_yourself"
    static let transitionContinue = "coach.transition.tap_continue"
    static let feedbackTitle = "coach.feedback.title"
    static let feedbackAgain = "coach.feedback.again"
    static let feedbackDone = "coach.feedback.done"
    static let feedbackKeepGoing = "coach.feedback.keep_going"
    static let feedbackEnoughToday = "coach.feedback.enough_today"
    static let verdictExcellent = "coach.verdict.excellent"
    static let verdictStruggling = "coach.verdict.struggling"
    static let verdictStartEasier = "coach.verdict.start_easier"
    static let valvePrompt = "coach.valve.prompt"
    static let valveTooEasy = "coach.valve.too_easy"
    static let valveJustRight = "coach.valve.just_right"
    static let valveTooHard = "coach.valve.too_hard"
    static let valveThanks = "coach.valve.thanks"
    static let privacyTitle = "settings.privacy"
    static let privacyDesc = "settings.privacy_desc"
    static let privacyToggle = "settings.privacy_toggle_label"

    /// Short "done" confirmation for a finished block (transition screen).
    static func blockDone(_ kind: BlockKind) -> String { t("coach.done.\(kind.rawValue)") }

    // ─── Engine label localization ──────────────────────────
    // MusicEngine's VOICING_LABELS / PROGRESSION_LABELS are English constants
    // that ParityTests pins 1:1 against the web engine, so they must not be
    // translated in place. The UI therefore localizes them here on the way out,
    // mirroring how the web renders `settings.voicing_*` / `settings.progression_*`
    // instead of the engine's own English constants.

    /// Localized display name for a voicing (falls back to the engine constant).
    static func voicing(_ v: VoicingType) -> String {
        (isGerman ? deVoicings : enVoicings)[v] ?? VOICING_LABELS[v] ?? v.rawValue
    }

    /// Localized display name for a progression mode.
    static func progression(_ m: ProgressionMode) -> String {
        t("settings.progression.\(m.rawValue)")
    }

    /// Greeting for the Today hero, chosen by hour of day.
    static func greeting(hour: Int) -> String {
        if hour < 12 { return t("settings.greeting_morning") }
        if hour < 18 { return t("settings.greeting_afternoon") }
        return t("settings.greeting_evening")
    }

    // ─── To-Go keys (practice away from the piano) ──────────
    // Engine-supplied keys (togo.prompt/tap/lick/card/say.*) arrive via
    // exercise.promptKey / session.sayKey and are looked up directly by `t`.

    enum ToGo {
        static let entry = "togo.entry"
        static let title = "togo.title"
        static let subtitle = "togo.subtitle"
        static let intro = "togo.intro"
        static let start = "togo.start"
        static let startSub = "togo.start_sub"
        static let pickOne = "togo.pick_one"
        static let needsAudio = "togo.needs_audio"
        static let needsMic = "togo.needs_mic"
        static let silentOk = "togo.silent_ok"
        static let audioOff = "togo.audio_off"
        static let micOff = "togo.mic_off"
        static let enableAudio = "togo.enable_audio"
        static let enableMic = "togo.enable_mic"
        static let round = "togo.round"
        static let replay = "togo.replay"
        static let play = "togo.play"
        static let listen = "togo.listen"
        static let revealCorrect = "togo.reveal_correct"
        static let revealWrong = "togo.reveal_wrong"
        static let answerWas = "togo.answer_was"
        static let next = "togo.next"
        static let finish = "togo.finish"
        static let quit = "togo.quit"
        static let singStart = "togo.sing_start"
        static let singHint = "togo.sing_hint"
        static let singHeard = "togo.sing_heard"
        static let singNothingYet = "togo.sing_nothing_yet"
        static let singCheck = "togo.sing_check"
        static let singLevel = "togo.sing_level"
        static let singDenied = "togo.sing_denied"
        static let tapReady = "togo.tap_ready"
        static let tapButton = "togo.tap_button"
        static let tapStart = "togo.tap_start"
        static let tapScore = "togo.tap_score"
        static let tapRushing = "togo.tap_rushing"
        static let tapDragging = "togo.tap_dragging"
        static let tapLocked = "togo.tap_locked"
        static let notesHint = "togo.notes_hint"
        static let notesCheck = "togo.notes_check"
        static let notesClear = "togo.notes_clear"
        static let resultsTitle = "togo.results_title"
        static let resultsScore = "togo.results_score"
        static let resultsAccuracy = "togo.results_accuracy"
        static let resultsAvg = "togo.results_avg"
        static let resultsBreakdown = "togo.results_breakdown"
        static let resultsPerfect = "togo.results_perfect"
        static let resultsGood = "togo.results_good"
        static let resultsMixed = "togo.results_mixed"
        static let resultsRough = "togo.results_rough"
        static let again = "togo.again"
        static let done = "togo.done"
        static let backToTrain = "togo.back_to_train"
        static let earProgress = "togo.ear_progress"

        /// Display name for one discipline ("Intervals" / "Intervalle").
        static func kind(_ k: ToGoKind) -> String { CoachL10n.t("togo.kind.\(k.rawValue)") }
        /// One-line description of a discipline.
        static func kindDesc(_ k: ToGoKind) -> String { CoachL10n.t("togo.kind_desc.\(k.rawValue)") }
    }

    // ─── Voicing tables (mirror web settings.voicing_*) ─────

    private static let enVoicings: [VoicingType: String] = [
        .root: "Root Position", .shell: "Shell Voicing", .halfShell: "Half Shell",
        .full: "Full Voicing", .rootlessA: "Rootless A", .rootlessB: "Rootless B",
        .inversion1: "1st Inversion", .inversion2: "2nd Inversion", .inversion3: "3rd Inversion",
    ]
    private static let deVoicings: [VoicingType: String] = [
        .root: "Grundstellung", .shell: "Shell Voicing", .halfShell: "Half-Shell",
        .full: "Volle Besetzung", .rootlessA: "Rootless A", .rootlessB: "Rootless B",
        .inversion1: "1. Umkehrung", .inversion2: "2. Umkehrung", .inversion3: "3. Umkehrung",
    ]

    // ─── String tables (content-identical to web coach: block) ──

    private static let en: [String: String] = [
        // Block announcements (transition screen).
        "coach.block.warmup": "Warm up with {voicing}",
        "coach.block.review": "Refresh {count} chords",
        "coach.block.focus": "Focus: {root} in {voicing}",
        "coach.block.new": "New: {quality} in {voicing}",
        "coach.block.apply": "Apply: {voicing} in a progression",
        "coach.block.calibrate": "A quick check of where you stand",
        // Block done (short confirmation, no params).
        "coach.done.warmup": "Warmed up",
        "coach.done.review": "Refreshed",
        "coach.done.focus": "Focus done",
        "coach.done.new": "New material practiced",
        "coach.done.apply": "Applied",
        "coach.done.calibrate": "Check done",
        // Coach announcement on the hero button.
        "coach.say.calibrate": "First a quick check — {chords} chords, then we begin.",
        "coach.say.short": "Today: refresh {voicing} and dig into {quality} — {minutes} minutes.",
        "coach.say.full": "Today: warm up, firm up {focusRoot}, and {quality} in {voicing} is new — {minutes} minutes.",
        "coach.say.reviewOnly": "Just a refresh today — {minutes} minutes and you're back on track.",
        // Teacher feedback after the session. {tier} names the key stage so
        // "already have it" and "next goal" never sound contradictory.
        "coach.fb.promoted": "{quality} in {voicing} {tier} sits now — cleanly mastered.",
        "coach.fb.held": "We'll take another pass at {quality} in {voicing} {tier} — it's coming.",
        "coach.fb.demoted": "Easing {quality} in {voicing} {tier} down a step — no worries.",
        "coach.fb.improved": "Noticeably faster: avg {avgMs} ms per chord.",
        "coach.fb.placed": "You already have {quality} in {voicing} {tier} — skipped ahead.",
        "coach.fb.nextGoal": "Next goal: {quality} in {voicing} {tier}.",
        "coach.fb.calibrated": "Check done — {placed} building blocks already in place.",
        // Key-stage suffix used in fb.* strings — reads as a parenthetical.
        "coach.tier.easy": "(easy keys)",
        "coach.tier.med": "(more keys)",
        "coach.tier.all": "(all 12 keys)",
        // UI chrome.
        "coach.transition.tap_continue": "Continue",
        "coach.feedback.title": "Your lesson",
        "coach.feedback.again": "Again",
        "coach.feedback.done": "Done",
        "coach.feedback.keep_going": "Keep going",
        "coach.feedback.enough_today": "Enough for today",
        "coach.verdict.excellent": "Nailed it — that was fast and clean.",
        "coach.verdict.struggling": "That one was tough. Want to ease off?",
        "coach.verdict.start_easier": "Yes, start easier",
        "coach.valve.prompt": "How did that feel?",
        "coach.valve.too_easy": "Too easy",
        "coach.valve.just_right": "Just right",
        "coach.valve.too_hard": "Too hard",
        "coach.valve.thanks": "Noted for next time.",
        "quickstart.coach_hero_title": "Keep practicing",
        "quickstart.coach_hero_sub": "Your coach builds today's session.",
        "quickstart.pick_yourself": "Pick it yourself",
        "settings.privacy": "Anonymous Usage Data",
        "settings.privacy_desc": "Helps us improve the practice coach — fully anonymous, no personal data, and you can turn it off anytime.",
        "settings.privacy_toggle_label": "Share anonymous usage data",

        // ── App chrome (web keys noted where one exists) ──
        // Today.
        "settings.greeting_morning": "Good morning",
        "settings.greeting_afternoon": "Good afternoon",
        "settings.greeting_evening": "Good evening",
        "settings.your_progress": "Your progress",
        "ui.level": "Level",
        "ui.streak": "Streak",
        "ui.sessions": "Sessions",
        "embed.stat_avg": "Avg / chord",
        "ui.start": "Start",
        "settings.suggested": "Suggested",
        "quickstart.weakspots_title": "Weak spots",
        "results.drill_weak": "Drill your weak spots",
        "ui.slowest_chords": "Your slowest chords",
        // "{voicing} · {roots} — your slowest chords"
        "ui.slowest_chords_detail": "{voicing} · {roots} — your slowest chords",
        // Daily motivation (web habit.motivation_*; streak-at-risk is a plural entry).
        "habit.motivation_not_started": "Ready for your {minutes}-minute practice?",
        "habit.motivation_keep_going": "Nice start — {remaining} min to today's goal.",
        "habit.motivation_almost": "Almost there — {remaining} min to go.",
        "habit.motivation_goal_reached": "Daily goal reached.",
        "habit.motivation_extra": "Extra credit — {practiced} min today.",
        // Tabs / navigation.
        "nav.today": "Today",
        "nav.practice": "Practice",
        "nav.learn": "Learn",
        "nav.progress": "Progress",
        "settings.open_settings": "Settings",
        "ui.close": "Close",
        "ui.done": "Done",
        "ui.next": "Next",
        "ui.finish": "Finish",
        "ui.check": "Check",
        "ui.continue": "Continue",
        // Settings screen.
        "settings.notation": "Notation",
        "settings.notation_system": "System",
        "settings.notation_system_international": "International",
        "settings.notation_system_german": "German (H/B)",
        "settings.chord_notation_title": "Style",
        "settings.notation_standard": "Standard",
        "settings.notation_symbols": "Symbols (Δ7)",
        "settings.notation_short": "Short",
        "settings.accidentals": "Accidentals",
        "settings.accidentals_both": "Both",
        "settings.accidentals_sharps": "Sharps",
        "settings.accidentals_flats": "Flats",
        "settings.sound": "Sound",
        "settings.instrument": "Instrument",
        "settings.midi": "MIDI",
        "settings.connect_bluetooth": "Connect Bluetooth keyboard",
        "settings.midi_footer": "Hardware MIDI works in the trainer (set Input → MIDI). Microphone recognition and more settings arrive soon.",
        "sound.grand-piano": "Grand Piano",
        "sound.electric-piano": "Electric Piano",
        "sound.vibraphone": "Vibraphone",
        "sound.organ": "Organ",
        "sound.synth-pad": "Synth Pad",
        // Trainer setup.
        "nav.trainer": "Trainer",
        "settings.difficulty": "Difficulty",
        "settings.difficulty_beginner": "Beginner",
        "settings.difficulty_intermediate": "Intermediate",
        "settings.difficulty_advanced": "Advanced",
        "results.voicing": "Voicing",
        "settings.progression_mode": "Progression",
        "settings.display_mode": "Reveal",
        "settings.display_mode_always": "Always",
        "settings.display_mode_verify": "On reveal",
        "settings.display_mode_off": "Off",
        "settings.input_mode": "Input",
        "settings.input_mode_none": "Tap",
        "settings.input_mode_midi": "MIDI",
        "settings.input_mode_mic": "Mic",
        "settings.mic_hint": "Play chords into your mic — clear, sustained voicings work best.",
        "ui.audio": "Audio",
        "settings.ear_training_toggle": "Ear training (guess by ear)",
        "settings.in_time_toggle": "In-time (metronome advances)",
        "ui.tempo": "Tempo",
        "ui.ear_training_start": "Start ear training",
        "settings.start_training": "Start drill",
        // Progression modes (web settings.progression_*).
        "settings.progression.random": "Random",
        "settings.progression.2-5-1": "ii-V-I",
        "settings.progression.1-6-2-5": "Turnaround (I-vi-ii-V)",
        "settings.progression.cycle-of-4ths": "Cycle of 4ths",
        "settings.progression.3-6-2-5": "iii-vi-ii-V",
        "settings.progression.1-4-5": "I-IV-V",
        "settings.progression.diatonic": "Diatonic",
        "settings.progression.custom": "Custom",
        // Trainer play + results.
        "ui.tap_build": "Build the chord, then Check",
        "ui.show_me_chord": "Show me the chord",
        "ui.show_me": "Show me",
        "ui.next_chord": "Next chord",
        "ui.correct": "Correct",
        "ui.not_quite": "Not quite",
        "ui.playing_in_time": "Playing in time · {bpm} BPM",
        "ui.play_on_keyboard": "Play it on your keyboard",
        "ui.connect_midi": "Connect a MIDI keyboard",
        "ui.play_listening": "Play it — listening…",
        "results.nice_work": "Nice work",
        "results.stat_avg": "avg / chord",
        "results.stat_chords": "chords",
        "results.stat_total": "total",
        "results.again_same": "Again (same session)",
        "results.again": "Again",
        // Progress screen.
        "ui.insights_empty_title": "No sessions yet",
        "ui.insights_empty_desc": "Play your first drill and your speed, streaks, and weak spots will show up here.",
        "ui.speed_trend": "Speed trend",
        "ui.seconds_per_chord": "s / chord",
        "ui.personal_bests": "Personal bests",
        "ui.stat_level": "level",
        "ui.stat_streak": "streak",
        "ui.stat_avg": "avg",
        "ui.stat_sessions": "sessions",
        "ui.avg_suffix": "{seconds}s avg",
        // Practice screen.
        "ui.custom_progression": "Custom progression",
        "ui.custom_progression_desc": "Type any chord sequence",
        "ui.free_practice": "Free practice",
        "ui.free_practice_desc": "Your own settings",
        "ui.start_typing_suggestion": "Type a progression",
        "ui.progression_input_placeholder": "e.g. Dm7 | G7 | CMaj7",
        "ui.no_valid_chords": "No chords recognized yet — try forms like Dm7, B♭Maj7, F♯7.",
        "ui.standards": "Standards",
        "nav.custom": "Custom",
        // Learn / lesson player.
        "learn.step_theory": "Theory",
        "learn.step_practice": "Practice",
        "learn.step_challenge": "Challenge",
        "learn.hear_it": "Hear it",
        "learn.tap_continue": "Tap continue when you've got it.",
        "learn.done_practicing": "Done practicing",
        "learn.finish_lesson": "Finish lesson",
        "learn.challenge_beat": "Challenge · beat {seconds}s/chord",
        // Ear training.
        "ui.what_chord": "What chord is this?",
        "ui.listen_again": "Play again",
        // Onboarding.
        "onboarding.tagline": "Build muscle memory for jazz piano voicings — fast, focused, and measurable.",
        "habit.onboard_daily": "Daily goal",
        "habit.onboard_time_title": "How long do you want to practice each day?",
        "habit.onboard_when_title": "When do you practice?",
        "habit.onboard_morning": "Morning",
        "habit.onboard_afternoon": "Afternoon",
        "habit.onboard_evening": "Evening",
        "habit.onboard_start": "Start practicing",
        // Plan level names (web learn.level_*).
        "learn.level_beginner": "Beginner",
        "learn.level_intermediate": "Intermediate",
        "learn.level_advanced": "Advanced",

        // ── To-Go (content-identical to web i18n `togo:` block) ──
        "togo.entry": "Practice without a piano",
        "togo.title": "To-Go",
        "togo.subtitle": "Ear, time and theory — everything you can train with nothing but headphones.",
        "togo.intro": "Seven ways to keep getting better away from the keys. Eight quick rounds, about three minutes. Headphones help.",
        "togo.start": "Let's go",
        "togo.start_sub": "A mix of everything you can train right now",
        "togo.pick_one": "Or train one thing",
        "togo.kind.interval": "Intervals",
        "togo.kind.quality": "Chord colours",
        "togo.kind.progression": "Progressions",
        "togo.kind.sing": "Singing",
        "togo.kind.time": "Time",
        "togo.kind.lick": "Licks",
        "togo.kind.theory": "Theory",
        "togo.kind_desc.interval": "Two notes — name the distance.",
        "togo.kind_desc.quality": "Hear a chord, name its quality.",
        "togo.kind_desc.progression": "Hear a cadence, name the shape.",
        "togo.kind_desc.sing": "Find a scale degree with your voice.",
        "togo.kind_desc.time": "Tap the groove against the click.",
        "togo.kind_desc.lick": "Hear a phrase, tap it back.",
        "togo.kind_desc.theory": "Silent flashcards — works anywhere.",
        "togo.needs_audio": "Needs sound",
        "togo.needs_mic": "Needs a microphone",
        "togo.silent_ok": "Works in silence",
        "togo.audio_off": "Sound is off — only theory cards are available.",
        "togo.mic_off": "No microphone — singing is sitting this one out.",
        "togo.enable_audio": "Turn sound on",
        "togo.enable_mic": "Allow microphone",
        // Engine-supplied prompts.
        "togo.prompt.interval": "How far apart are these two notes?",
        "togo.prompt.quality": "What colour is this chord?",
        "togo.prompt.progression": "Which shape is this, in {key}?",
        "togo.prompt.sing": "Sing the {degree} over {root}.",
        "togo.prompt.lick": "Tap the {count} notes back.",
        "togo.tap.quarters": "Tap every beat — {bpm} bpm.",
        "togo.tap.backbeat": "Tap only 2 and 4 — {bpm} bpm.",
        "togo.tap.downbeats": "Tap only 1 and 3 — {bpm} bpm.",
        "togo.tap.two_only": "Tap only the 2 — {bpm} bpm.",
        "togo.lick.scale_up": "Scale, climbing",
        "togo.lick.triad_down": "Triad, coming down",
        "togo.lick.arpeggio": "Seventh arpeggio",
        "togo.lick.enclosure": "Enclosure",
        "togo.lick.guide_down": "Guide tones falling",
        "togo.lick.blues_climb": "Blues climb",
        "togo.lick.descent": "Long descent",
        "togo.lick.chromatic_fall": "Chromatic fall",
        "togo.card.chord_notes": "Which notes are in {chord}?",
        "togo.card.chord_degree": "What is the {degree} of {chord}?",
        "togo.card.tritone_sub": "What is the tritone sub of {chord}?",
        "togo.card.relative_minor": "What is the relative minor of {key}?",
        "togo.say.mixed": "A bit of everything — {count} rounds, no piano needed.",
        "togo.say.single": "{count} rounds of {kind}.",
        // Run screen.
        "togo.round": "Round {current} of {total}",
        "togo.replay": "Play again",
        "togo.play": "Play",
        "togo.listen": "Listening…",
        "togo.reveal_correct": "That's it.",
        "togo.reveal_wrong": "Not quite.",
        "togo.answer_was": "It was {answer}",
        "togo.next": "Next",
        "togo.finish": "Finish",
        "togo.quit": "Stop",
        // Singing.
        "togo.sing_start": "Start listening",
        "togo.sing_hint": "Hold the note steadily for a moment — give the mic time to hear you.",
        "togo.sing_heard": "Heard so far",
        "togo.sing_nothing_yet": "Nothing yet",
        "togo.sing_check": "Check my note",
        "togo.sing_level": "Input level",
        "togo.sing_denied": "The microphone stayed shut. Check your permissions in Settings.",
        // Tapping.
        "togo.tap_ready": "Count yourself in, then tap along.",
        "togo.tap_button": "Tap",
        "togo.tap_start": "Start the click",
        "togo.tap_score": "{hits} of {expected} on target",
        "togo.tap_rushing": "You're a touch ahead — let the click lead.",
        "togo.tap_dragging": "You're a touch behind — lean into the beat.",
        "togo.tap_locked": "Right in the pocket.",
        // Note tap-back.
        "togo.notes_hint": "Tap the notes you heard, then check.",
        "togo.notes_check": "Check",
        "togo.notes_clear": "Clear",
        // Results.
        "togo.results_title": "Session done",
        "togo.results_score": "{correct} of {total} right",
        "togo.results_accuracy": "Accuracy",
        "togo.results_avg": "Average time",
        "togo.results_breakdown": "How each part went",
        "togo.results_perfect": "Clean sweep. Your ear is sharp today.",
        "togo.results_good": "Solid work — most of it landed.",
        "togo.results_mixed": "Some of it stuck. The rest just needs another pass.",
        "togo.results_rough": "A rough one. That's how the ear learns — come back to it.",
        "togo.again": "Again",
        "togo.done": "Done",
        "togo.back_to_train": "Back to training",
        "togo.ear_progress": "Ear progress: {ear} of {total} units",
    ]

    private static let de: [String: String] = [
        "coach.block.warmup": "Aufwärmen mit {voicing}",
        "coach.block.review": "{count} Akkorde auffrischen",
        "coach.block.focus": "Fokus: {root} in {voicing}",
        "coach.block.new": "Neu: {quality} in {voicing}",
        "coach.block.apply": "Anwenden: {voicing} in Progression",
        "coach.block.calibrate": "Kurzer Check, wo du stehst",
        "coach.done.warmup": "Aufgewärmt",
        "coach.done.review": "Aufgefrischt",
        "coach.done.focus": "Fokus geschafft",
        "coach.done.new": "Neues geübt",
        "coach.done.apply": "Angewendet",
        "coach.done.calibrate": "Check erledigt",
        "coach.say.calibrate": "Erst ein kurzer Check — {chords} Akkorde, dann geht’s los.",
        "coach.say.short": "Heute: {voicing} auffrischen und {quality} vertiefen — {minutes} Minuten.",
        "coach.say.full": "Heute: aufwärmen, {focusRoot} festigen und {quality} in {voicing} neu — {minutes} Minuten.",
        "coach.say.reviewOnly": "Heute nur auffrischen — {minutes} Minuten, dann bist du wieder auf Kurs.",
        "coach.fb.promoted": "{quality} in {voicing} {tier} sitzt jetzt — sauber gemeistert.",
        "coach.fb.held": "{quality} in {voicing} {tier} üben wir nochmal, das kommt.",
        "coach.fb.demoted": "{quality} in {voicing} {tier} nehmen wir eine Stufe zurück — kein Stress.",
        "coach.fb.improved": "Spürbar schneller: Ø {avgMs} ms pro Akkord.",
        "coach.fb.placed": "{quality} in {voicing} {tier} kannst du schon — übersprungen.",
        "coach.fb.nextGoal": "Nächstes Ziel: {quality} in {voicing} {tier}.",
        "coach.fb.calibrated": "Check fertig — {placed} Bausteine sitzen schon.",
        "coach.tier.easy": "(leichte Tonarten)",
        "coach.tier.med": "(mehr Tonarten)",
        "coach.tier.all": "(alle 12 Tonarten)",
        "coach.transition.tap_continue": "Weiter",
        "coach.feedback.title": "Deine Stunde",
        "coach.feedback.again": "Nochmal",
        "coach.feedback.done": "Fertig",
        "coach.feedback.keep_going": "Weiter geht's",
        "coach.feedback.enough_today": "Für heute genug",
        "coach.verdict.excellent": "Sitzt — das war schnell und sauber.",
        "coach.verdict.struggling": "Das war zäh. Sollen wir es leichter angehen?",
        "coach.verdict.start_easier": "Ja, leichter starten",
        "coach.valve.prompt": "Wie war das für dich?",
        "coach.valve.too_easy": "Zu leicht",
        "coach.valve.just_right": "Passt",
        "coach.valve.too_hard": "Zu schwer",
        "coach.valve.thanks": "Merke ich mir für nächstes Mal.",
        "quickstart.coach_hero_title": "Weiter üben",
        "quickstart.coach_hero_sub": "Dein Coach stellt die Session zusammen.",
        "quickstart.pick_yourself": "Selbst wählen",
        "settings.privacy": "Anonyme Nutzungsdaten",
        "settings.privacy_desc": "Hilft uns, den Übungs-Coach zu verbessern — komplett anonym, ohne Personendaten, jederzeit abschaltbar.",
        "settings.privacy_toggle_label": "Anonyme Nutzungsdaten teilen",

        // ── App-Chrome (Web-Wording, wo es einen Schlüssel gibt) ──
        // Heute.
        "settings.greeting_morning": "Guten Morgen",
        "settings.greeting_afternoon": "Guten Tag",
        "settings.greeting_evening": "Guten Abend",
        "settings.your_progress": "Dein Fortschritt",
        "ui.level": "Level",
        "ui.streak": "Serie",
        "ui.sessions": "Sessions",
        "embed.stat_avg": "Ø / Akkord",
        "ui.start": "Start",
        "settings.suggested": "Empfohlen",
        "quickstart.weakspots_title": "Schwachstellen",
        "results.drill_weak": "Deine Schwachstellen üben",
        "ui.slowest_chords": "Deine langsamsten Akkorde",
        "ui.slowest_chords_detail": "{voicing} · {roots} — deine langsamsten Akkorde",
        // Tagesmotivation (Web habit.motivation_*; Streak-Warnung ist ein Plural-Eintrag).
        "habit.motivation_not_started": "Bereit für deine {minutes} Minuten?",
        "habit.motivation_keep_going": "Guter Start — noch {remaining} Min bis zum Tagesziel.",
        "habit.motivation_almost": "Fast da — noch {remaining} Min.",
        "habit.motivation_goal_reached": "Tagesziel geschafft.",
        "habit.motivation_extra": "Bonus — {practiced} Min heute.",
        // Tabs / Navigation.
        "nav.today": "Heute",
        "nav.practice": "Üben",
        "nav.learn": "Lernen",
        "nav.progress": "Fortschritt",
        "settings.open_settings": "Einstellungen",
        "ui.close": "Schließen",
        "ui.done": "Fertig",
        "ui.next": "Weiter",
        "ui.finish": "Abschließen",
        "ui.check": "Prüfen",
        "ui.continue": "Weiter",
        // Einstellungen.
        "settings.notation": "Notation",
        "settings.notation_system": "System",
        "settings.notation_system_international": "International",
        "settings.notation_system_german": "Deutsch (H/B)",
        "settings.chord_notation_title": "Schreibweise",
        "settings.notation_standard": "Standard",
        "settings.notation_symbols": "Symbole (Δ7)",
        "settings.notation_short": "Kurz",
        "settings.accidentals": "Vorzeichen",
        "settings.accidentals_both": "Beide",
        "settings.accidentals_sharps": "Kreuze",
        "settings.accidentals_flats": "Be",
        "settings.sound": "Klang",
        "settings.instrument": "Instrument",
        "settings.midi": "MIDI",
        "settings.connect_bluetooth": "Bluetooth-Keyboard verbinden",
        "settings.midi_footer": "Hardware-MIDI funktioniert im Trainer (Eingabe → MIDI). Mikrofon-Erkennung und weitere Einstellungen kommen bald.",
        "sound.grand-piano": "Flügel",
        "sound.electric-piano": "E-Piano",
        "sound.vibraphone": "Vibraphon",
        "sound.organ": "Orgel",
        "sound.synth-pad": "Synth-Pad",
        // Trainer-Einrichtung.
        "nav.trainer": "Trainer",
        "settings.difficulty": "Schwierigkeit",
        "settings.difficulty_beginner": "Anfänger",
        "settings.difficulty_intermediate": "Fortgeschritten",
        "settings.difficulty_advanced": "Profi",
        "results.voicing": "Voicing",
        "settings.progression_mode": "Akkordfolge",
        "settings.display_mode": "Anzeige",
        "settings.display_mode_always": "Immer",
        "settings.display_mode_verify": "Beim Aufdecken",
        "settings.display_mode_off": "Aus",
        "settings.input_mode": "Eingabe",
        "settings.input_mode_none": "Tippen",
        "settings.input_mode_midi": "MIDI",
        "settings.input_mode_mic": "Mikro",
        "settings.mic_hint": "Spiel die Akkorde ins Mikro — klare, gehaltene Voicings klappen am besten.",
        "ui.audio": "Audio",
        "settings.ear_training_toggle": "Gehörtraining (nach Gehör raten)",
        "settings.in_time_toggle": "In-Time (Metronom schaltet weiter)",
        "ui.tempo": "Tempo",
        "ui.ear_training_start": "Gehörtraining starten",
        "settings.start_training": "Training starten",
        // Akkordfolgen (Web settings.progression_*).
        "settings.progression.random": "Zufall",
        "settings.progression.2-5-1": "ii-V-I",
        "settings.progression.1-6-2-5": "Turnaround (I-vi-ii-V)",
        "settings.progression.cycle-of-4ths": "Quartenzirkel",
        "settings.progression.3-6-2-5": "iii-vi-ii-V",
        "settings.progression.1-4-5": "I-IV-V",
        "settings.progression.diatonic": "Diatonisch",
        "settings.progression.custom": "Eigene",
        // Trainer-Lauf + Ergebnis.
        "ui.tap_build": "Bau den Akkord, dann Prüfen",
        "ui.show_me_chord": "Zeig mir den Akkord",
        "ui.show_me": "Zeig mir",
        "ui.next_chord": "Nächster Akkord",
        "ui.correct": "Richtig",
        "ui.not_quite": "Nicht ganz",
        "ui.playing_in_time": "Im Takt · {bpm} BPM",
        "ui.play_on_keyboard": "Spiel ihn auf deinem Keyboard",
        "ui.connect_midi": "MIDI-Keyboard verbinden",
        "ui.play_listening": "Spiel ihn — ich höre zu …",
        "results.nice_work": "Gute Arbeit",
        "results.stat_avg": "Ø / Akkord",
        "results.stat_chords": "Akkorde",
        "results.stat_total": "gesamt",
        "results.again_same": "Nochmal (gleiche Session)",
        "results.again": "Nochmal",
        // Fortschritt.
        "ui.insights_empty_title": "Noch keine Sessions",
        "ui.insights_empty_desc": "Spiel dein erstes Training — danach siehst du hier Tempo, Serien und Schwachstellen.",
        "ui.speed_trend": "Tempo-Verlauf",
        "ui.seconds_per_chord": "s / Akkord",
        "ui.personal_bests": "Persönliche Bestzeiten",
        "ui.stat_level": "Level",
        "ui.stat_streak": "Serie",
        "ui.stat_avg": "Ø",
        "ui.stat_sessions": "Sessions",
        "ui.avg_suffix": "Ø {seconds}s",
        // Üben.
        "ui.custom_progression": "Eigene Akkordfolge",
        "ui.custom_progression_desc": "Beliebige Akkordfolge eintippen",
        "ui.free_practice": "Freies Üben",
        "ui.free_practice_desc": "Deine eigenen Einstellungen",
        "ui.start_typing_suggestion": "Tippe eine Akkordfolge",
        "ui.progression_input_placeholder": "z. B. Dm7 | G7 | CMaj7",
        "ui.no_valid_chords": "Noch keine Akkorde erkannt — probier Formen wie Dm7, B♭Maj7, F♯7.",
        "ui.standards": "Standards",
        "nav.custom": "Eigene",
        // Lernen / Lektion.
        "learn.step_theory": "Theorie",
        "learn.step_practice": "Üben",
        "learn.step_challenge": "Challenge",
        "learn.hear_it": "Anhören",
        "learn.tap_continue": "Tippe auf Weiter, wenn du es hast.",
        "learn.done_practicing": "Üben beendet",
        "learn.finish_lesson": "Lektion abschließen",
        "learn.challenge_beat": "Challenge · unter {seconds}s/Akkord",
        // Gehörtraining.
        "ui.what_chord": "Welcher Akkord ist das?",
        "ui.listen_again": "Nochmal hören",
        // Onboarding.
        "onboarding.tagline": "Bau dir Muskelgedächtnis für Jazz-Piano-Voicings — schnell, fokussiert und messbar.",
        "habit.onboard_daily": "Tagesziel",
        "habit.onboard_time_title": "Wie lange willst du täglich üben?",
        "habit.onboard_when_title": "Wann übst du?",
        "habit.onboard_morning": "Morgens",
        "habit.onboard_afternoon": "Nachmittags",
        "habit.onboard_evening": "Abends",
        "habit.onboard_start": "Üben starten",
        // Level-Namen (Web learn.level_*).
        "learn.level_beginner": "Einsteiger",
        "learn.level_intermediate": "Fortgeschritten",
        "learn.level_advanced": "Profi",

        // ── To-Go (inhaltsgleich zum Web-i18n-Block `togo:`) ──
        "togo.entry": "Ohne Klavier üben",
        "togo.title": "To-Go",
        "togo.subtitle": "Ohr, Time und Theorie — alles, was du mit bloßen Kopfhörern trainieren kannst.",
        "togo.intro": "Sieben Wege, auch fern der Tasten besser zu werden. Acht kurze Runden, etwa drei Minuten. Kopfhörer helfen.",
        "togo.start": "Los geht's",
        "togo.start_sub": "Eine Mischung aus allem, was gerade möglich ist",
        "togo.pick_one": "Oder eine Sache üben",
        "togo.kind.interval": "Intervalle",
        "togo.kind.quality": "Akkordfarben",
        "togo.kind.progression": "Progressionen",
        "togo.kind.sing": "Singen",
        "togo.kind.time": "Time",
        "togo.kind.lick": "Licks",
        "togo.kind.theory": "Theorie",
        "togo.kind_desc.interval": "Zwei Töne — nenne den Abstand.",
        "togo.kind_desc.quality": "Akkord hören, Qualität benennen.",
        "togo.kind_desc.progression": "Kadenz hören, Form erkennen.",
        "togo.kind_desc.sing": "Eine Stufe mit der Stimme finden.",
        "togo.kind_desc.time": "Den Groove zum Klick mittappen.",
        "togo.kind_desc.lick": "Phrase hören, zurücktippen.",
        "togo.kind_desc.theory": "Stille Karten — geht überall.",
        "togo.needs_audio": "Braucht Ton",
        "togo.needs_mic": "Braucht ein Mikrofon",
        "togo.silent_ok": "Geht auch lautlos",
        "togo.audio_off": "Der Ton ist aus — es gibt nur Theoriekarten.",
        "togo.mic_off": "Kein Mikrofon — Singen setzt diesmal aus.",
        "togo.enable_audio": "Ton einschalten",
        "togo.enable_mic": "Mikrofon erlauben",
        // Prompts aus der Engine.
        "togo.prompt.interval": "Wie weit liegen diese zwei Töne auseinander?",
        "togo.prompt.quality": "Welche Farbe hat dieser Akkord?",
        "togo.prompt.progression": "Welche Form ist das, in {key}?",
        "togo.prompt.sing": "Sing die {degree} über {root}.",
        "togo.prompt.lick": "Tippe die {count} Töne zurück.",
        "togo.tap.quarters": "Tappe jeden Schlag — {bpm} bpm.",
        "togo.tap.backbeat": "Tappe nur 2 und 4 — {bpm} bpm.",
        "togo.tap.downbeats": "Tappe nur 1 und 3 — {bpm} bpm.",
        "togo.tap.two_only": "Tappe nur die 2 — {bpm} bpm.",
        "togo.lick.scale_up": "Skala, aufwärts",
        "togo.lick.triad_down": "Dreiklang, abwärts",
        "togo.lick.arpeggio": "Septakkord-Arpeggio",
        "togo.lick.enclosure": "Umspielung",
        "togo.lick.guide_down": "Leittöne fallend",
        "togo.lick.blues_climb": "Blues-Aufstieg",
        "togo.lick.descent": "Langer Abstieg",
        "togo.lick.chromatic_fall": "Chromatischer Fall",
        "togo.card.chord_notes": "Welche Töne stecken in {chord}?",
        "togo.card.chord_degree": "Was ist die {degree} von {chord}?",
        "togo.card.tritone_sub": "Was ist die Tritonus-Substitution von {chord}?",
        "togo.card.relative_minor": "Was ist die Moll-Parallele von {key}?",
        "togo.say.mixed": "Von allem etwas — {count} Runden, ganz ohne Klavier.",
        "togo.say.single": "{count} Runden {kind}.",
        // Übungslauf.
        "togo.round": "Runde {current} von {total}",
        "togo.replay": "Nochmal hören",
        "togo.play": "Abspielen",
        "togo.listen": "Hör hin …",
        "togo.reveal_correct": "Genau das.",
        "togo.reveal_wrong": "Nicht ganz.",
        "togo.answer_was": "Es war {answer}",
        "togo.next": "Weiter",
        "togo.finish": "Abschließen",
        "togo.quit": "Beenden",
        // Singen.
        "togo.sing_start": "Zuhören starten",
        "togo.sing_hint": "Halte den Ton einen Moment ruhig — gib dem Mikro Zeit, dich zu hören.",
        "togo.sing_heard": "Bisher gehört",
        "togo.sing_nothing_yet": "Noch nichts",
        "togo.sing_check": "Ton prüfen",
        "togo.sing_level": "Eingangspegel",
        "togo.sing_denied": "Das Mikrofon blieb zu. Schau in die Einstellungen.",
        // Tappen.
        "togo.tap_ready": "Zähl dich ein, dann tappe mit.",
        "togo.tap_button": "Tap",
        "togo.tap_start": "Klick starten",
        "togo.tap_score": "{hits} von {expected} getroffen",
        "togo.tap_rushing": "Du bist eine Spur zu früh — lass den Klick führen.",
        "togo.tap_dragging": "Du bist eine Spur zu spät — leg dich in den Beat.",
        "togo.tap_locked": "Genau im Pocket.",
        // Töne zurücktippen.
        "togo.notes_hint": "Tippe die gehörten Töne, dann prüfen.",
        "togo.notes_check": "Prüfen",
        "togo.notes_clear": "Leeren",
        // Ergebnis.
        "togo.results_title": "Session fertig",
        "togo.results_score": "{correct} von {total} richtig",
        "togo.results_accuracy": "Trefferquote",
        "togo.results_avg": "Ø Zeit",
        "togo.results_breakdown": "Wie die Teile liefen",
        "togo.results_perfect": "Alles sauber. Dein Ohr ist heute wach.",
        "togo.results_good": "Gute Arbeit — das meiste saß.",
        "togo.results_mixed": "Einiges ist hängen geblieben. Der Rest braucht noch einen Durchgang.",
        "togo.results_rough": "Zäh diesmal. So lernt das Ohr — komm noch mal darauf zurück.",
        "togo.again": "Nochmal",
        "togo.done": "Fertig",
        "togo.back_to_train": "Zurück zum Training",
        "togo.ear_progress": "Ohr-Fortschritt: {ear} von {total} Einheiten",
    ]
}
