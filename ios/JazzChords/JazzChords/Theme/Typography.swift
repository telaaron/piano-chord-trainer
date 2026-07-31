// Typography — the brand display face (Space Grotesk) for the chord symbol and
// large titles, alongside SF for body/UI. Bundled via UIAppFonts; the real
// registered family name is "Space Grotesk". Display sizes scale with Dynamic
// Type via .custom(_, size:relativeTo:).
//
// ── Accidentals ──────────────────────────────────────────────────────────────
// Space Grotesk contains no ♭ (U+266D) or ♯ (U+266F) — verified against the
// bundled TTFs, which carry ordinary letters but neither accidental. Notation.swift
// deliberately emits those real Unicode glyphs (never "b"/"#"), so every flat and
// sharp chord hits a hole in the font and iOS silently substitutes from some
// unrelated system family. Measured at 26pt, an unfallback'd ♭ typesets 26.0pt
// wide — wider than a capital B at 17.3pt — i.e. a blank box the width of a
// whole character.
//
// `displayFont(_:weight:)` builds the same face with an explicit cascade list, so
// the accidentals resolve from Apple Symbols while every other character still
// comes from Space Grotesk. Same measurement with the cascade: ♭ = 9.6pt, and B
// is untouched at 17.3pt.
//
// Chord symbols must therefore use `Display.chord(_:)` (or `.chordText()`), never
// a bare `.custom("Space Grotesk", …)`, or the box comes back.

import SwiftUI
import CoreText

enum Display {
    static let family = "Space Grotesk"

    /// Families consulted, in order, for glyphs the brand face lacks. Apple
    /// Symbols ships with iOS and carries the musical accidentals.
    private static let fallbackFamilies = ["AppleSymbols"]

    /// The display face with the accidental fallback wired in.
    ///
    /// Falls back to the plain custom font if the family is missing (e.g. the
    /// resource failed to register) — a wrong face is better than no text.
    static func displayFont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        guard let ui = cascadedUIFont(size: size) else {
            return .custom(family, size: size).weight(weight)
        }
        return Font(ui).weight(weight)
    }

    /// Build a UIFont for the brand family with `fallbackFamilies` cascaded in.
    private static func cascadedUIFont(size: CGFloat) -> UIFont? {
        let cascade = fallbackFamilies.map {
            CTFontDescriptorCreateWithNameAndSize($0 as CFString, size)
        }
        let descriptor = CTFontDescriptorCreateWithAttributes([
            kCTFontNameAttribute: family as CFString,
            kCTFontCascadeListAttribute: cascade as CFArray,
        ] as CFDictionary)
        let ct = CTFontCreateWithFontDescriptor(descriptor, size, nil)
        // If the family is absent, CoreText hands back a substitute; treat the
        // resolved name as the check rather than trusting the descriptor.
        let resolved = CTFontCopyFamilyName(ct) as String
        guard resolved == family else { return nil }
        return ct as UIFont
    }

    /// Huge chord symbol on the trainer. Accidental-safe.
    static func chord(_ size: CGFloat = 60) -> Font {
        displayFont(size, weight: .bold)
    }

    /// Large screen titles ("Good morning", "Nice work").
    static func title(_ size: CGFloat = 30) -> Font {
        displayFont(size, weight: .bold)
    }

    /// Section / card headline.
    static func headline(_ size: CGFloat = 18) -> Font {
        displayFont(size, weight: .medium)
    }
}

extension Text {
    /// Apply the display face quickly. Accidental-safe.
    func display(_ size: CGFloat) -> Text {
        self.font(Display.displayFont(size, weight: .regular))
    }

    /// Chord symbols and note names — anything that may contain ♭ or ♯.
    func chordText(_ size: CGFloat = 60) -> Text {
        self.font(Display.chord(size))
    }
}
