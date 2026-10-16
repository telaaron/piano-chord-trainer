// PlanPresentation — how each practice plan appears on Üben (spec §3): goal
// group, plain-language title and subline, and one SF Symbol for what you do.
// Chord symbols are never icons. One table, checked by PlanPresentationTests.

import Foundation

enum PracticeGroup: CaseIterable {
    case start, jazzForms, targeted, ownWay

    var title: String {
        switch self {
        case .start: return SettingsText.t("To get started", "Zum Einstieg")
        case .jazzForms: return SettingsText.t("Typical jazz progressions", "Typische Jazz-Folgen")
        case .targeted: return SettingsText.t("Targeted practice", "Gezielt trainieren")
        case .ownWay: return SettingsText.t("Your own way", "Eigene Wege")
        }
    }
}

struct PlanPresentation {
    let id: String
    let group: PracticeGroup
    let symbol: String
    private let titleEn: String
    private let titleDe: String
    private let subEn: String
    private let subDe: String

    var title: String { SettingsText.t(titleEn, titleDe) }
    var subtitle: String { SettingsText.t(subEn, subDe) }

    static let freeId = "free"
    static let customId = "custom"

    private init(_ id: String, _ group: PracticeGroup, _ symbol: String,
                 _ titleEn: String, _ titleDe: String, _ subEn: String, _ subDe: String) {
        self.id = id; self.group = group; self.symbol = symbol
        self.titleEn = titleEn; self.titleDe = titleDe; self.subEn = subEn; self.subDe = subDe
    }

    nonisolated static let all: [PlanPresentation] = [
        .init("warmup", .start, "flame",
              "Warm-up", "Aufwärmen",
              "Easy chords in familiar keys", "Leichte Akkorde in bekannten Tonarten"),
        .init("speed", .start, "stopwatch",
              "Sprint", "Sprint",
              "As fast and sure as you can", "So schnell und sicher wie möglich"),

        .init("deepdive", .jazzForms, "stairs",
              "ii–V–I", "ii–V–I",
              "The most important progression in jazz", "Die wichtigste Folge im Jazz"),
        .init("turnaround", .jazzForms, "arrow.2.circlepath",
              "Turnaround", "Turnaround",
              "I–VI–ii–V, round and round", "I–VI–ii–V, immer im Kreis"),
        .init("quartenzirkel", .jazzForms, "circle.dotted",
              "Circle of fifths", "Quintenzirkel",
              "In fourths, the way jazz players practise it", "In Quarten, wie im Jazz geübt"),
        .init("voice-leading-flow", .jazzForms, "point.topleft.down.to.point.bottomright.curvepath",
              "Voice leading", "Stimmführung",
              "Connect chords without jumping", "Akkorde ohne Sprünge verbinden"),

        .init("voicing-drill", .targeted, "pianokeys",
              "One shape, all keys", "Ein Griff, alle Tonarten",
              "One voicing through all 12 keys", "Ein Voicing durch alle 12 Tonarten"),
        .init("inversions-drill", .targeted, "arrow.up.arrow.down",
              "Inversions", "Umkehrungen",
              "Chords in every position", "Akkorde in allen Lagen"),
        .init("left-hand-comping", .targeted, "hand.raised",
              "Left-hand comping", "Linke Hand begleiten",
              "Rootless shapes, no root needed", "Griffe ohne Grundton, wie im Jazz"),
        .init("in-time-comping", .targeted, "metronome",
              "Comping in time", "Im Takt begleiten",
              "Change chords on the beat", "Akkordwechsel auf den Schlag"),
        .init("ear-check", .targeted, "ear",
              "By ear", "Nach Gehör",
              "Recognise chords by their sound", "Akkorde am Klang erkennen"),
        .init("adaptive-drill", .targeted, "scope",
              "Weak spots", "Schwachstellen",
              "Practises exactly what still trips you up", "Übt genau das, was noch hakt"),
        .init("challenge", .targeted, "flag.checkered",
              "Challenge", "Challenge",
              "Extended chords, no hints", "Erweiterte Akkorde, keine Hilfe"),

        .init(freeId, .ownWay, "infinity",
              "Free practice", "Frei üben",
              "Set everything up yourself", "Alles selbst einstellen"),
        .init(customId, .ownWay, "slider.horizontal.3",
              "Your own progression", "Eigene Folge",
              "Put chords together yourself", "Akkorde selbst zusammenstellen"),
    ]

    static func of(_ id: String) -> PlanPresentation? { all.first { $0.id == id } }
}
