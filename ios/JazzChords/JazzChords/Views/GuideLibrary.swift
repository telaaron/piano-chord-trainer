// GuideLibrary — the website's guide articles, bundled as Markdown so they
// work offline (spec §4). German app: the German article where the website has
// one, else the English text. Each guide names the plan "Jetzt üben" starts.

import Foundation

struct Guide: Identifiable {
    let id: String
    let title: String
    let blocks: [GuideBlock]
    let planId: String
    var lead: String? {
        for b in blocks { if case .paragraph(let t) = b { return t } }
        return nil
    }
}

enum GuideBlock: Equatable {
    case heading(String, level: Int)
    case paragraph(String)
    case numbered([String])
    case bullets([String])
    /// A native table rendered by the view (e.g. ii-V-I in all keys).
    case table(String)
}

enum GuideLibrary {
    /// Guide id → plan that "Jetzt üben" opens. Order = order in Lernen.
    private static let entries: [(id: String, planId: String)] = [
        ("ii-v-i", "deepdive"),
        ("left-hand", "left-hand-comping"),
        ("rootless-voicings", "voicing-drill"),
        ("jazz-piano-voicings", "voicing-drill"),
    ]

    nonisolated static func all(german: Bool) -> [Guide] {
        entries.compactMap { e in
            let langs = german ? ["de", "en"] : ["en"]
            for lang in langs {
                if let url = Bundle.main.url(forResource: "\(e.id).\(lang)", withExtension: "md"),
                   let text = try? String(contentsOf: url, encoding: .utf8) {
                    let (title, blocks) = parse(text)
                    return Guide(id: e.id, title: title, blocks: blocks, planId: e.planId)
                }
            }
            return nil
        }
    }

    /// Minimal Markdown: "# " title, "## "/"### " headings, numbered and bullet
    /// lists, paragraphs, and {{name}} table markers. Inline **bold** and *italic*
    /// stay in the text for AttributedString(markdown:).
    nonisolated static func parse(_ text: String) -> (String, [GuideBlock]) {
        var title = ""
        var blocks: [GuideBlock] = []
        let chunks = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var numbered: [String] = []
        var bullets: [String] = []
        func flush() {
            if !numbered.isEmpty { blocks.append(.numbered(numbered)); numbered = [] }
            if !bullets.isEmpty { blocks.append(.bullets(bullets)); bullets = [] }
        }
        for chunk in chunks {
            for line in chunk.components(separatedBy: "\n") where !line.isEmpty {
                if line.hasPrefix("# ") {
                    flush(); title = String(line.dropFirst(2))
                } else if line.hasPrefix("### ") {
                    flush(); blocks.append(.heading(String(line.dropFirst(4)), level: 3))
                } else if line.hasPrefix("## ") {
                    flush(); blocks.append(.heading(String(line.dropFirst(3)), level: 2))
                } else if line.hasPrefix("{{"), line.hasSuffix("}}") {
                    flush(); blocks.append(.table(String(line.dropFirst(2).dropLast(2))))
                } else if let r = line.range(of: #"^\d+\. "#, options: .regularExpression) {
                    if !bullets.isEmpty { flush() }
                    numbered.append(String(line[r.upperBound...]))
                } else if line.hasPrefix("- ") {
                    if !numbered.isEmpty { flush() }
                    bullets.append(String(line.dropFirst(2)))
                } else {
                    flush(); blocks.append(.paragraph(line))
                }
            }
        }
        flush()
        return (title, blocks)
    }

    /// Dur-ii–V–I in every key, cycle of fourths, jazz notation.
    static let iiVITable: [(key: String, chords: String)] = [
        ("C", "D–7 · G7 · CΔ7"), ("F", "G–7 · C7 · FΔ7"), ("B♭", "C–7 · F7 · B♭Δ7"),
        ("E♭", "F–7 · B♭7 · E♭Δ7"), ("A♭", "B♭–7 · E♭7 · A♭Δ7"), ("D♭", "E♭–7 · A♭7 · D♭Δ7"),
        ("G♭", "A♭–7 · D♭7 · G♭Δ7"), ("B", "C♯–7 · F♯7 · BΔ7"), ("E", "F♯–7 · B7 · EΔ7"),
        ("A", "B–7 · E7 · AΔ7"), ("D", "E–7 · A7 · DΔ7"), ("G", "A–7 · D7 · GΔ7"),
    ]
}
