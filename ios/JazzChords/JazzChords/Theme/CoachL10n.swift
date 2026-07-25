// CoachL10n — localized strings for the Auto-Mode ("Coach") UI (de + en).
//
// The rest of the iOS app is English-only inline; the Coach is the first feature
// that ships both languages, so it carries a small self-contained table keyed by
// the engine's i18n keys (CoachLabelKeys / CoachSayKeys / CoachFeedbackKeys) plus
// a handful of UI-chrome keys. Texts are content-identical to the web source of
// truth (src/lib/i18n/{en,de}.ts, `coach:` block + `quickstart.coach_*`).
//
// Language selection follows the device's preferred language (de → German, else
// English), matching how a native app localizes without a String Catalog. Params
// are interpolated `{name}`-style exactly like the web `t(key, params)` helper,
// and raw voicing values are localized the same way as web `localizeCoachParams`.

import Foundation
import MusicEngine

enum CoachL10n {
    /// True when the device's top preferred language is German.
    static var isGerman: Bool {
        (Locale.preferredLanguages.first ?? "en").lowercased().hasPrefix("de")
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
