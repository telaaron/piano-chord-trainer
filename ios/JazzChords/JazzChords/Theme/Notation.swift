// Notation — typesetting for note and chord names shown to the user.
//
// The engine stores accidentals ASCII-style ("Db", "F#") because that is what the
// web engine stores and ParityTests pins those values 1:1. The UI must never show
// them that way: this project's rule is that ♭ ♯ ° ø are real Unicode text — never
// "b"/"#", never emoji. Views that previously interpolated an engine root straight
// into a Text() (Today's weak-spot subtitle, Progress' weak-spot rows) leaked the
// ASCII form; everything user-visible now goes through here instead.
//
// This is presentation only. It does not touch the engine, and it composes with
// convertChordNotation(_:_:) (H/B German note naming), which is a different
// question — that one is about *which letter*, this one is about *which glyph*.

import Foundation
import MusicEngine

enum Notation {
    /// Typeset a root/note name for display: "Db" → "D♭", "F#" → "F♯".
    static func root(_ name: String) -> String {
        name
            .replacingOccurrences(of: "b", with: "♭")
            .replacingOccurrences(of: "#", with: "♯")
    }

    /// Typeset a full chord name for display, honouring the notation system.
    ///
    /// Two different accidentals appear in a name like "B♭m7♭5": the root's, and
    /// the ones inside the quality suffix (the engine spells qualities ASCII —
    /// "m7b5", "7b9", "Maj7#11" — because the web engine does and ParityTests
    /// pins it). Both must render as real glyphs, so the root is handled by
    /// position and the suffix by pattern: a "b"/"#" is an accidental only when
    /// a digit follows it ("7b9"), never in a letter like the "b" of "sus".
    static func chord(_ name: String, _ system: NotationSystem = .international) -> String {
        let converted = convertChordNotation(name, system)
        guard let first = converted.first else { return converted }
        var rest = String(converted.dropFirst())
        var root = String(first)
        // The root's own accidental, if any, sits right after the letter.
        if rest.hasPrefix("b") { root += "♭"; rest.removeFirst() }
        else if rest.hasPrefix("#") { root += "♯"; rest.removeFirst() }
        return root + typesetQuality(rest)
    }

    /// Rewrite accidentals inside a quality suffix ("m7b5" → "m7♭5").
    private static func typesetQuality(_ q: String) -> String {
        var out = ""
        var chars = Array(q)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            let nextIsDigit = i + 1 < chars.count && chars[i + 1].isNumber
            if c == "b", nextIsDigit { out += "♭" }
            else if c == "#", nextIsDigit { out += "♯" }
            else { out.append(c) }
            i += 1
        }
        return out
    }
}
