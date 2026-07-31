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

    // MARK: Lessons — humanized (context is the course/module).

    static func lessonTitle(_ id: String) -> String {
        // Normalize quality tokens for readability. The ♭/♯ here are real Unicode
        // glyphs, never "b"/"#" — same rule the chord typesetting path follows.
        let replacements: [(String, String)] = [
            ("maj7#11", "Maj7♯11"), ("m7b5", "m7♭5"), ("7b9", "7♭9"), ("7#9", "7♯9"),
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
            return token.capitalized
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

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
}
