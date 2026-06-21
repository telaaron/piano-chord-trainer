// Strings — human display names for plans, courses, modules, lessons. Ported
// from the English side of src/lib/i18n/en.ts so the UI shows real names instead
// of id-derived labels. (Full localization can layer on later; this is the en base.)

import Foundation
import MusicEngine

enum Strings {

    // MARK: Plans

    private static let planNames: [String: String] = [
        "warmup": "Warm-Up", "speed": "Speed Run", "deepdive": "ii-V-I Deep Dive",
        "turnaround": "Turnaround", "challenge": "Challenge", "quartenzirkel": "Cycle of 4ths",
        "voicing-drill": "Voicing Drill", "left-hand-comping": "Left-Hand Comping",
        "inversions-drill": "Inversions", "in-time-comping": "In-Time Comping",
        "ear-check": "Ear Check", "adaptive-drill": "Adaptive Drill",
        "voice-leading-flow": "Voice Leading Flow", "weak-drill": "Weak-Spot Drill",
    ]

    private static let planTaglines: [String: String] = [
        "warmup": "Shell · ii-V-I · all keys", "speed": "Root · random · timed",
        "deepdive": "Full voicings · all 12 keys", "turnaround": "I-vi-ii-V · all keys",
        "challenge": "Extended chords · no hints", "quartenzirkel": "12 keys · half-shell",
        "voicing-drill": "Root → shell → half → full", "left-hand-comping": "Rootless A · no root",
        "inversions-drill": "1st/2nd/3rd · all keys", "in-time-comping": "On the beat · 100 BPM",
        "ear-check": "Hear it · play it", "adaptive-drill": "Smart practice · all voicings",
        "voice-leading-flow": "See the connections", "weak-drill": "Your slowest chords",
    ]

    static func planName(_ id: String) -> String { planNames[id] ?? humanize(id) }
    static func planTagline(_ id: String) -> String { planTaglines[id] ?? "" }

    // MARK: Courses

    private static let courseTitles: [String: String] = [
        "intervals": "Intervals",
        "shell-voicings": "Shell Voicings",
        "scale-degrees": "Scale Degrees",
        "ultimate-plan": "Ultimate Plan",
    ]
    private static let courseSubtitles: [String: String] = [
        "intervals": "Hear & play every interval",
        "shell-voicings": "The 3-note method",
        "scale-degrees": "Diatonic harmony & function",
        "ultimate-plan": "From zero to master",
    ]

    static func courseTitle(_ id: String) -> String { courseTitles[id] ?? humanize(id) }
    static func courseSubtitle(_ id: String) -> String { courseSubtitles[id] ?? "" }

    // MARK: Modules

    private static let moduleTitles: [String: String] = [
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
    static func moduleTitle(_ id: String) -> String { moduleTitles[id] ?? humanize(id) }

    // MARK: Lessons — humanized (context is the course/module).

    static func lessonTitle(_ id: String) -> String {
        // Normalize quality tokens for readability.
        let replacements: [(String, String)] = [
            ("maj7#11", "Maj7♯11"), ("m7b5", "m7♭5"), ("7b9", "7♭9"), ("7#9", "7♯9"),
            ("maj9", "Maj9"), ("maj7", "Maj7"), ("dim7", "dim7"), ("m11", "m11"),
            ("69", "6/9"), ("fund", ""), ("shell", "Shell"), ("hshell", "Half-Shell"),
            ("rla", "Rootless A"), ("rlb", "Rootless B"), ("inv1", "1st Inv"),
            ("inv2", "2nd Inv"), ("inv3", "3rd Inv"), ("adv", ""),
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

    static func level(_ level: PlanLevel) -> String { level.rawValue.capitalized }
}
