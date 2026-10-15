// Strings — human display names for plans, courses, modules, lessons. Ported
// from src/lib/i18n/{en,de}.ts so the UI shows real names instead of id-derived
// labels. The header used to say "full localization can layer on later"; it has
// now layered on: every table below has a German twin, and the language decision
// is delegated to CoachL10n.isGerman so the whole app switches as one.

import Foundation
import MusicEngine

enum Strings {

    /// Pick the table matching the app's language — same decision CoachL10n makes,
    /// deliberately not a second one.
    private static func pick<T>(_ en: T, _ de: T) -> T { CoachL10n.isGerman ? de : en }

    // MARK: Plans

    private static let planNamesEn: [String: String] = [
        "warmup": "Warm-Up", "speed": "Speed Run", "deepdive": "ii-V-I Deep Dive",
        "turnaround": "Turnaround", "challenge": "Challenge", "quartenzirkel": "Cycle of 4ths",
        "voicing-drill": "Voicing Drill", "left-hand-comping": "Left-Hand Comping",
        "inversions-drill": "Inversions", "in-time-comping": "In-Time Comping",
        "ear-check": "Ear Check", "adaptive-drill": "Adaptive Drill",
        "voice-leading-flow": "Voice Leading Flow", "weak-drill": "Weak-Spot Drill",
    ]
    private static let planNamesDe: [String: String] = [
        "warmup": "Aufwärmen", "speed": "Sprint", "deepdive": "ii-V-I Tiefgang",
        "turnaround": "Turnaround", "challenge": "Herausforderung", "quartenzirkel": "Quartenzirkel",
        "voicing-drill": "Voicing-Drill", "left-hand-comping": "Linke-Hand Comping",
        "inversions-drill": "Umkehrungen", "in-time-comping": "Im-Takt Comping",
        "ear-check": "Gehörtest", "adaptive-drill": "Adaptiver Drill",
        "voice-leading-flow": "Stimmführungs-Flow", "weak-drill": "Schwachstellen-Drill",
    ]

    private static let planTaglinesEn: [String: String] = [
        "warmup": "Shell · ii-V-I · all keys", "speed": "Root · random · timed",
        "deepdive": "Full voicings · all 12 keys", "turnaround": "I-vi-ii-V · all keys",
        "challenge": "Extended chords · no hints", "quartenzirkel": "12 keys · half-shell",
        "voicing-drill": "Root → shell → half → full", "left-hand-comping": "Rootless A · no root",
        "inversions-drill": "1st/2nd/3rd · all keys", "in-time-comping": "On the beat · 100 BPM",
        "ear-check": "Hear it · play it", "adaptive-drill": "Smart practice · all voicings",
        "voice-leading-flow": "See the connections", "weak-drill": "Your slowest chords",
    ]
    private static let planTaglinesDe: [String: String] = [
        "warmup": "Shell · ii-V-I · alle Tonarten", "speed": "Grundstellung · Zufall · auf Zeit",
        "deepdive": "Volle Voicings · alle 12 Tonarten", "turnaround": "I-vi-ii-V · alle Tonarten",
        "challenge": "Erweiterte Akkorde · keine Hilfe", "quartenzirkel": "12 Tonarten · Half-Shell",
        "voicing-drill": "Grundton → Shell → Halb → Voll", "left-hand-comping": "Rootless A · ohne Grundton",
        "inversions-drill": "1./2./3. Umkehrung · alle Tonarten", "in-time-comping": "Auf den Schlag · 100 BPM",
        "ear-check": "Hören · spielen", "adaptive-drill": "Smartes Üben · alle Voicings",
        "voice-leading-flow": "Verbindungen sehen", "weak-drill": "Deine langsamsten Akkorde",
    ]

    static func planName(_ id: String) -> String {
        pick(planNamesEn, planNamesDe)[id] ?? humanize(id)
    }
    static func planTagline(_ id: String) -> String {
        pick(planTaglinesEn, planTaglinesDe)[id] ?? ""
    }

    // MARK: Courses

    private static let courseTitlesEn: [String: String] = [
        "intervals": "Intervals",
        "shell-voicings": "Shell Voicings",
        "scale-degrees": "Scale Degrees",
        "ultimate-plan": "Ultimate Plan",
    ]
    private static let courseTitlesDe: [String: String] = [
        "intervals": "Intervalle",
        "shell-voicings": "Shell Voicings",
        "scale-degrees": "Stufentheorie",
        "ultimate-plan": "Ultimate Plan",
    ]
    private static let courseSubtitlesEn: [String: String] = [
        "intervals": "Hear & play every interval",
        "shell-voicings": "The 3-note method",
        "scale-degrees": "Diatonic harmony & function",
        "ultimate-plan": "From zero to master",
    ]
    private static let courseSubtitlesDe: [String: String] = [
        "intervals": "Jedes Intervall hören & spielen",
        "shell-voicings": "Die 3-Noten-Methode",
        "scale-degrees": "Akkorde in ihrer Funktion verstehen",
        "ultimate-plan": "Von Null auf Meister",
    ]

    static func courseTitle(_ id: String) -> String {
        pick(courseTitlesEn, courseTitlesDe)[id] ?? humanize(id)
    }
    static func courseSubtitle(_ id: String) -> String {
        pick(courseSubtitlesEn, courseSubtitlesDe)[id] ?? ""
    }

    // MARK: Modules

    private static let moduleTitlesEn: [String: String] = [
        // ultimate
        "fundamentals": "Fundamentals", "shells": "Shell Voicings", "sixths": "Sixth & Special",
        "ninths": "Extended (9th)", "full-voicings": "Full & Half-Shell", "rootless": "Rootless",
        "inversions": "Inversions", "advanced": "Altered & Advanced",
        // shell
        "basics": "The Basic Chords",
        // intervals
        "seconds-thirds": "Seconds & Thirds", "fifths-sixths": "Fifths & Sixths",
        "sevenths": "Sevenths", "extended": "Extended Intervals",
        // degrees
        "tonic-family": "The Tonic Family", "subdominant-family": "The Subdominant",
        "dominant-family": "The Dominant", "progressions": "ii-V-I & Turnaround",
    ]
    private static let moduleTitlesDe: [String: String] = [
        // ultimate
        "fundamentals": "Grundlagen", "shells": "Shell Voicings", "sixths": "Sext- & Sonderakkorde",
        "ninths": "Erweitert (9th)", "full-voicings": "Full & Half-Shell", "rootless": "Rootless",
        "inversions": "Umkehrungen", "advanced": "Altered & Advanced",
        // shell
        "basics": "Die Hauptakkorde",
        // intervals
        "seconds-thirds": "Sekunden & Terzen", "fifths-sixths": "Quinten & Sexten",
        "sevenths": "Septimen", "extended": "Erweiterte Intervalle",
        // degrees
        "tonic-family": "Die Tonika-Familie", "subdominant-family": "Die Subdominante",
        "dominant-family": "Die Dominante", "progressions": "ii-V-I & Turnaround",
    ]
    static func moduleTitle(_ id: String) -> String {
        pick(moduleTitlesEn, moduleTitlesDe)[id] ?? humanize(id)
    }

    // MARK: Lessons

    // Generated from the web course titles (src/lib/i18n/{en,de}.ts, course.*.title)
    // keyed by lesson id. Unknown ids fall back to a humanized id.
    private static let lessonTitlesEn: [String: String] = [
        "maj7": "Major Seventh (Maj7)",
        "dom7": "Dominant Seventh (7)",
        "m7": "Minor Seventh (m7)",
        "major-minor-3rd": "Major & Minor 3rd",
        "tritone": "The Tritone",
        "perfect-5th": "The Perfect 5th",
        "dim5-aug5": "Diminished & Augmented 5th",
        "major-6th": "The Major 6th",
        "minor-7th": "The Minor 7th",
        "major-7th": "The Major 7th",
        "ninths": "The 9th",
        "elevenths-thirteenths": "11th & 13th",
        "I-maj7": "Degree I — Maj7 (Tonic)",
        "vi-m7": "Degree vi — m7 (Tonic Sub)",
        "iii-m7": "Degree iii — m7 (Mediant)",
        "IV-maj7": "Degree IV — Maj7 (Subdominant)",
        "ii-m7": "Degree ii — m7 (Subdominant Sub)",
        "V-7": "Degree V — Dom7 (Dominant)",
        "vii-m7b5": "Degree vii° — m7♭5 (Dominant Sub)",
        "ii-V-I": "The ii-V-I Progression",
        "turnaround": "The Turnaround (I-vi-ii-V)",
        "fund-maj7": "Major 7th (Maj7)",
        "fund-dom7": "Dominant 7th (7)",
        "fund-m7": "Minor 7th (m7)",
        "shell-maj7": "Maj7 Shell",
        "shell-dom7": "Dom7 Shell",
        "shell-m7": "m7 Shell",
        "sixth-6": "Major 6th (6)",
        "sixth-m6": "Minor 6th (m6)",
        "sixth-m7b5": "Half-Diminished (m7♭5)",
        "sixth-dim7": "Diminished 7th (dim7)",
        "ninth-maj9": "Major 9th (Maj9)",
        "ninth-9": "Dominant 9th (9)",
        "ninth-m9": "Minor 9th (m9)",
        "ninth-69": "Six-Nine (6/9)",
        "full-maj7": "Maj7 Full Voicing",
        "full-dom7": "Dom7 Full Voicing",
        "full-m7": "m7 Full Voicing",
        "hshell-maj7": "Half-Shell Voicing",
        "rla-maj7": "Rootless A — Maj7",
        "rla-dom7": "Rootless A — Dom7",
        "rla-m7": "Rootless A — m7",
        "rlb-maj7": "Rootless B — Maj7",
        "rlb-dom7": "Rootless B — Dom7",
        "rlb-m7": "Rootless B — m7",
        "inv1-maj7": "1st Inversion — Maj7",
        "inv2-maj7": "2nd Inversion — Maj7",
        "inv3-maj7": "3rd Inversion — Maj7",
        "adv-7s9": "Dominant ♯9 (Hendrix)",
        "adv-7b9": "Dominant ♭9",
        "adv-lyd": "Lydian (Maj7♯11)",
        "adv-m11": "Minor 11 (m11)",
        "adv-13": "Dominant 13 (13)",
    ]
    private static let lessonTitlesDe: [String: String] = [
        "maj7": "Dur-Septakkord (Maj7)",
        "dom7": "Dominant-Septakkord (7)",
        "m7": "Moll-Septakkord (m7)",
        "major-minor-3rd": "Große & kleine Terz",
        "tritone": "Der Tritonus",
        "perfect-5th": "Die reine Quinte",
        "dim5-aug5": "Verminderte & übermäßige Quinte",
        "major-6th": "Die große Sexte",
        "minor-7th": "Die kleine Septime",
        "major-7th": "Die große Septime",
        "ninths": "Die None (9th)",
        "elevenths-thirteenths": "Undezime & Tredezime (11th & 13th)",
        "I-maj7": "Stufe I — Maj7 (Tonika)",
        "vi-m7": "Stufe vi — m7 (Tonika-Stellvertreter)",
        "iii-m7": "Stufe iii — m7 (Mediane)",
        "IV-maj7": "Stufe IV — Maj7 (Subdominante)",
        "ii-m7": "Stufe ii — m7 (Subdominant-Stellvertreter)",
        "V-7": "Stufe V — Dom7 (Dominante)",
        "vii-m7b5": "Stufe vii° — m7♭5 (Dominante-Stellvertreter)",
        "ii-V-I": "Die ii-V-I Verbindung",
        "turnaround": "Der Turnaround (I-vi-ii-V)",
        "fund-maj7": "Dur-Septakkord (Maj7)",
        "fund-dom7": "Dominant-Septakkord (7)",
        "fund-m7": "Moll-Septakkord (m7)",
        "shell-maj7": "Maj7 Shell",
        "shell-dom7": "Dom7 Shell",
        "shell-m7": "m7 Shell",
        "sixth-6": "Dur-Sextakkord (6)",
        "sixth-m6": "Moll-Sextakkord (m6)",
        "sixth-m7b5": "Halbvermindert (m7♭5)",
        "sixth-dim7": "Vermindert (dim7)",
        "ninth-maj9": "Dur-Nonenakkord (Maj9)",
        "ninth-9": "Dominant-Nonenakkord (9)",
        "ninth-m9": "Moll-Nonenakkord (m9)",
        "ninth-69": "Sext-Nonen-Akkord (6/9)",
        "full-maj7": "Maj7 Full Voicing",
        "full-dom7": "Dom7 Full Voicing",
        "full-m7": "m7 Full Voicing",
        "hshell-maj7": "Half-Shell Voicing",
        "rla-maj7": "Rootless A — Maj7",
        "rla-dom7": "Rootless A — Dom7",
        "rla-m7": "Rootless A — m7",
        "rlb-maj7": "Rootless B — Maj7",
        "rlb-dom7": "Rootless B — Dom7",
        "rlb-m7": "Rootless B — m7",
        "inv1-maj7": "1. Umkehrung — Maj7",
        "inv2-maj7": "2. Umkehrung — Maj7",
        "inv3-maj7": "3. Umkehrung — Maj7",
        "adv-7s9": "Dominant ♯9 (Hendrix)",
        "adv-7b9": "Dominant ♭9",
        "adv-lyd": "Lydisch (Maj7♯11)",
        "adv-m11": "Moll 11 (m11)",
        "adv-13": "Dominant 13 (13)",
    ]

    static func lessonTitle(_ id: String) -> String {
        pick(lessonTitlesEn, lessonTitlesDe)[id] ?? humanizedLessonTitle(id)
    }

    /// Fallback for ids without a table entry (context is the course/module).
    private static func humanizedLessonTitle(_ id: String) -> String {
        // Normalize quality tokens for readability. The ♭/♯ here are real Unicode
        // glyphs, never "b"/"#" — same rule the chord typesetting path follows.
        let replacements: [(String, String)] = [
            ("maj7#11", "Maj7♯11"), ("m7b5", "m7♭5"), ("7b9", "7♭9"), ("7#9", "7♯9"), ("7s9", "7♯9"),
            ("maj9", "Maj9"), ("maj7", "Maj7"), ("dim7", "dim7"), ("m11", "m11"),
            ("69", "6/9"), ("fund", ""), ("shell", "Shell"), ("hshell", "Half-Shell"),
            ("rla", "Rootless A"), ("rlb", "Rootless B"),
            ("inv1", CoachL10n.isGerman ? "1. Umk." : "1st Inv"),
            ("inv2", CoachL10n.isGerman ? "2. Umk." : "2nd Inv"),
            ("inv3", CoachL10n.isGerman ? "3. Umk." : "3rd Inv"),
            ("adv", ""),
        ]
        var parts = id.split(separator: "-").map(String.init)
        parts = parts.map { token in
            for (k, v) in replacements where token == k { return v }
            // Chord symbols (m7, m9, 6, 13) and Roman numerals (vi, IV) are
            // case-sensitive: capitalizing turned "m7" into "M7" (a major 7th).
            if token.first?.isNumber == true || isMinorSymbol(token) || isRomanNumeral(token) {
                return token
            }
            return token.capitalized
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    private static func isMinorSymbol(_ token: String) -> Bool {
        token.count > 1 && token.first == "m" && token.dropFirst().first?.isNumber == true
    }

    private static let romanNumerals: Set<String> = [
        "i", "ii", "iii", "iv", "v", "vi", "vii", "I", "II", "III", "IV", "V", "VI", "VII",
    ]
    private static func isRomanNumeral(_ token: String) -> Bool { romanNumerals.contains(token) }

    // MARK: Generic

    static func humanize(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }

    /// Display name for a plan's level (web learn.level_*).
    static func level(_ level: PlanLevel) -> String {
        CoachL10n.t("learn.level_\(level.rawValue)")
    }

    /// Same three names for a course's level — the engine keeps PlanLevel and
    /// CourseLevel as separate types, so the UI needs both entry points.
    static func level(_ level: CourseLevel) -> String {
        CoachL10n.t("learn.level_\(level.rawValue)")
    }
    // ─── Editorial redesign ─────────────────────────────────

    /// Function name for an interval label from `getVoicingIntervalLabels`
    /// ("R", "♭3", "♭7", "9" …) as shown in the trainer's function grid.
    static func intervalFunction(_ label: String) -> String {
        let core = label.replacingOccurrences(of: "♭", with: "").replacingOccurrences(of: "♯", with: "").replacingOccurrences(of: "°", with: "")
        switch core {
        case "R": return pick("Root", "Grundton")
        case "3": return pick("Third", "Terz")
        case "5": return pick("Fifth", "Quinte")
        case "6": return pick("Sixth", "Sexte")
        case "13": return pick("Thirteenth", "Tredezime")
        case "7": return pick("Seventh", "Septime")
        case "9": return pick("Ninth", "None")
        case "11": return pick("Eleventh", "Undezime")
        default: return label
        }
    }

    /// VoiceOver label for the trainer's lead sheet strip.
    static func leadSheetLabel(previous: String?, current: String, next: String?) -> String {
        var parts: [String] = []
        if let previous { parts.append(pick("before \(previous)", "vorher \(previous)")) }
        parts.append(pick("now \(current)", "jetzt \(current)"))
        if let next { parts.append(pick("next \(next)", "danach \(next)")) }
        return parts.joined(separator: ", ")
    }
    static var listen: String { pick("Listen", "Anhören") }
    static var keepPracticing: String { pick("Keep practicing", "Weiter üben") }
    static var chordPreviewHint: String { pick("Shows how to play it", "Zeigt den Griff") }
    static var sideB: String { pick("Side B · Pick it yourself", "Seite B · Selbst wählen") }
    static var statDaysInRow: String { pick("days in a row", "Tage in Folge") }
    static var statPerChord: String { pick("per chord", "pro Akkord") }
    static var statSessions: String { pick("sessions", "Sessions") }
    /// "LEVEL 4 · DEIN WEG" (uppercased by EyebrowText).
    static func progressEyebrow(level: Int) -> String { pick("Level \(level) · Your path", "Level \(level) · Dein Weg") }

    /// "1,8 s" / "1.8 s" — locale decimal separator.
    static func seconds(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)).locale(CoachL10n.isGerman ? Locale(identifier: "de_DE") : Locale(identifier: "en_US"))) + " s"
    }

    /// "DO · 15. OKT / SESSION 7" (uppercased by EyebrowText).
    static func todayEyebrow(date: Date, session: Int) -> String {
        let locale = Locale(identifier: CoachL10n.isGerman ? "de_DE" : "en_US")
        let day = date.formatted(.dateTime.weekday(.abbreviated).locale(locale)).replacingOccurrences(of: ".", with: "")
        let dm = date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
        return "\(day) · \(dm) / Session \(session)"
    }

    /// "HEUTE DRAN · 5 MIN · 24 AKKORDE".
    static func todayFeatureEyebrow(minutes: Int, chords: Int) -> String {
        pick("Up today · \(minutes) min · \(chords) chords", "Heute dran · \(minutes) Min · \(chords) Akkorde")
    }

    /// Short Kalam badge for a voicing in a tracklist row.
    static func voicingBadge(_ v: VoicingType) -> String {
        switch v {
        case .root: return "R"
        case .shell: return "1·3·7"
        case .halfShell: return "½"
        case .full: return "Δ7"
        case .rootlessA: return "A"
        case .rootlessB: return "B"
        default: return "♪"
        }
    }
    static var hint: String { pick("Hint", "Tipp") }
    static var nextPrefix: String { pick("next:", "nächster:") }
    static var contents: String { pick("Contents", "Inhalt") }
    static var done: String { pick("done", "fertig") }
    static var new: String { pick("new", "neu") }
    static func xOfY(_ x: Int, _ y: Int) -> String { pick("\(x) of \(y)", "\(x) von \(y)") }
    static func learnEyebrow(lessons: Int) -> String { pick("Courses · \(lessons) lessons", "Kurse · \(lessons) Lektionen") }
    static func pathEyebrow(lessons: Int) -> String { pick("The path · \(lessons) lessons", "Der Weg · \(lessons) Lektionen") }
    static var ownWay: String { pick("Your own way", "Auf eigene Faust") }
    static func plansEyebrow(_ n: Int) -> String { pick("\(n) plans", "\(n) Pläne") }
}
