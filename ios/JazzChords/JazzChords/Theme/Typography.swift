// Typography — the editorial faces for content, SF for UI.
//
// · Instrument Serif (Regular/Italic): large titles, ledes, stats, course titles.
// · Kalam Bold: every chord symbol — the Real Book handwriting.
// · SF Mono: small eyebrows ("DO · 15. OKT / SESSION 07").
// · SF Pro: everything else (system text styles).
//
// ── Accidentals ──────────────────────────────────────────────────────────────
// Neither Instrument Serif nor Kalam contains ♭ (U+266D), ♯ (U+266F) or Δ, and
// Notation.swift deliberately emits those real glyphs. Without a cascade iOS
// substitutes from an arbitrary family and the accidental typesets as a box the
// width of a whole character. `uiFont(family:size:)` builds the face with an
// explicit cascade list so those glyphs resolve from Apple Symbols while every
// other character still comes from the brand face (pinned by TypographyTests).
//
// Chord symbols must therefore use `Display.chord(_:)` (or `.chordText()`),
// never a bare `.custom("Kalam", …)`, or the box comes back.

import SwiftUI
import UIKit
import CoreText

enum Display {
    static let serifFamily = "Instrument Serif"
    static let chordFamily = "Kalam"

    /// Families consulted, in order, for glyphs the brand faces lack. Apple
    /// Symbols ships with iOS and carries the musical accidentals.
    private static let fallbackFamilies = ["AppleSymbols"]

    /// A brand face with the accidental fallback wired in, or nil if the
    /// family is not registered (e.g. the resource failed to load).
    static func uiFont(family: String, size: CGFloat, italic: Bool = false) -> UIFont? {
        let cascade = fallbackFamilies.map {
            CTFontDescriptorCreateWithNameAndSize($0 as CFString, size)
        }
        var attributes: [CFString: Any] = [
            kCTFontFamilyNameAttribute: family as CFString,
            kCTFontCascadeListAttribute: cascade as CFArray,
        ]
        if italic {
            attributes[kCTFontTraitsAttribute] = [kCTFontSymbolicTrait: CTFontSymbolicTraits.traitItalic.rawValue] as CFDictionary
        }
        let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        let ct = CTFontCreateWithFontDescriptor(descriptor, size, nil)
        // If the family is absent CoreText hands back a substitute; trust the
        // resolved name rather than the descriptor.
        guard (CTFontCopyFamilyName(ct) as String) == family else { return nil }
        return ct as UIFont
    }

    /// Scale a brand face with Dynamic Type relative to `style`; fall back to
    /// the system font of that style if the face is missing.
    private static func scaled(family: String, size: CGFloat, italic: Bool, relativeTo style: UIFont.TextStyle) -> Font {
        guard let base = uiFont(family: family, size: size, italic: italic) else {
            return Font(UIFont.preferredFont(forTextStyle: style))
        }
        return Font(UIFontMetrics(forTextStyle: style).scaledFont(for: base))
    }

    /// Serif for large titles, ledes, stats and course titles. Accidental-safe.
    static func serif(_ size: CGFloat, italic: Bool = false, relativeTo style: UIFont.TextStyle = .largeTitle) -> Font {
        scaled(family: serifFamily, size: size, italic: italic, relativeTo: style)
    }

    /// Real Book handwriting for every chord symbol. Accidental-safe.
    static func chord(_ size: CGFloat = 60, relativeTo style: UIFont.TextStyle = .largeTitle) -> Font {
        scaled(family: chordFamily, size: size, italic: false, relativeTo: style)
    }

    /// Small monospaced eyebrow above titles and sections. Callers uppercase
    /// the text and add `.tracking(1)`.
    static func eyebrow(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    /// Large screen titles. Kept so existing call sites compile; now serif.
    static func title(_ size: CGFloat = 30) -> Font {
        serif(size)
    }

    /// Section / card headline. Kept so existing call sites compile; now serif.
    static func headline(_ size: CGFloat = 18) -> Font {
        serif(size, relativeTo: .headline)
    }

    /// Legacy entry point; maps to the serif face.
    static func displayFont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        serif(size)
    }
}

extension Text {
    /// Apply the serif display face quickly. Accidental-safe.
    func display(_ size: CGFloat) -> Text {
        self.font(Display.serif(size))
    }

    /// Chord symbols and note names — anything that may contain ♭ or ♯.
    func chordText(_ size: CGFloat = 60) -> Text {
        self.font(Display.chord(size))
    }
}
