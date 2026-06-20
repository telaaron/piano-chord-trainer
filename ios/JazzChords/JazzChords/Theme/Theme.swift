// Theme — maps the web app's design tokens (src/app.css) 1:1 to SwiftUI Colors.
// Midnight Indigo dark + lavender light. Resolves against the active color scheme
// so a single token set drives both modes, matching the web behavior.

import SwiftUI

/// Hex → Color helper (supports "RRGGBB" and "RRGGBBAA").
extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        if s.count == 8 {
            r = Double((v >> 24) & 0xff) / 255
            g = Double((v >> 16) & 0xff) / 255
            b = Double((v >> 8) & 0xff) / 255
            a = Double(v & 0xff) / 255
        } else {
            r = Double((v >> 16) & 0xff) / 255
            g = Double((v >> 8) & 0xff) / 255
            b = Double(v & 0xff) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

/// One palette = the resolved token values for a single color scheme.
struct Palette {
    let bg: Color
    let bgCard: Color
    let bgCardHover: Color
    let bgMuted: Color
    let border: Color
    let borderHover: Color
    let text: Color
    let textMuted: Color
    let textDim: Color
    let primary: Color
    let primaryHover: Color
    let primaryText: Color
    let accentGold: Color
    let accentAmber: Color
    let accentRed: Color
    let accentGreen: Color
    let success: Color
    let warning: Color
    let danger: Color
    let xp: Color
    // Piano
    let keyWhite: Color
    let keyWhiteActive: Color
    let keyWhiteBorder: Color
    let keyBlack: Color
    let keyBlackActive: Color
    let keyRootDot: Color

    /// Midnight Indigo — dark (jazz club at night). From :root in app.css.
    static let dark = Palette(
        bg: Color(hex: "0c0a18"), bgCard: Color(hex: "16132a"), bgCardHover: Color(hex: "1f1b3a"),
        bgMuted: Color(hex: "211d40"), border: Color(hex: "2d2952"), borderHover: Color(hex: "423c6e"),
        text: Color(hex: "f1eff8"), textMuted: Color(hex: "a9a3c6"), textDim: Color(hex: "6f6992"),
        primary: Color(hex: "f5a623"), primaryHover: Color(hex: "ffb840"), primaryText: Color(hex: "1a1206"),
        accentGold: Color(hex: "e8b04b"), accentAmber: Color(hex: "ffb84d"),
        accentRed: Color(hex: "e0436b"), accentGreen: Color(hex: "3fd09a"),
        success: Color(hex: "4ade80"), warning: Color(hex: "f59e0b"), danger: Color(hex: "ef4444"),
        xp: Color(hex: "fb923c"),
        keyWhite: Color(hex: "f5f4fa"), keyWhiteActive: Color(hex: "e8b04b"), keyWhiteBorder: Color(hex: "c9c6da"),
        keyBlack: Color(hex: "161329"), keyBlackActive: Color(hex: "ffb84d"), keyRootDot: Color(hex: "e8b04b"))

    /// Daytime indigo — light. From [data-theme="light"] in app.css.
    static let light = Palette(
        bg: Color(hex: "f4f3fa"), bgCard: Color(hex: "ffffff"), bgCardHover: Color(hex: "eeecf8"),
        bgMuted: Color(hex: "e6e3f4"), border: Color(hex: "ddd9ee"), borderHover: Color(hex: "c2bce0"),
        text: Color(hex: "1a1730"), textMuted: Color(hex: "5a5478"), textDim: Color(hex: "8a84a8"),
        primary: Color(hex: "c77f12"), primaryHover: Color(hex: "ad6c08"), primaryText: Color(hex: "ffffff"),
        accentGold: Color(hex: "a87d1a"), accentAmber: Color(hex: "c77f12"),
        accentRed: Color(hex: "c5345e"), accentGreen: Color(hex: "18936a"),
        success: Color(hex: "18936a"), warning: Color(hex: "b87708"), danger: Color(hex: "d23b34"),
        xp: Color(hex: "c77f12"),
        keyWhite: Color(hex: "ffffff"), keyWhiteActive: Color(hex: "c77f12"), keyWhiteBorder: Color(hex: "d6d2e8"),
        keyBlack: Color(hex: "221d3a"), keyBlackActive: Color(hex: "c77f12"), keyRootDot: Color(hex: "a87d1a"))
}

/// Environment-aware theme. Inject via `.environment(\.theme, …)` or read the
/// computed `Theme.current(for:)`. Most views read `palette` off the scheme.
struct Theme {
    static func palette(for scheme: ColorScheme) -> Palette {
        scheme == .dark ? .dark : .light
    }

    // Spacing scale (4px base) — app.css --space-*.
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 24
    static let space6: CGFloat = 32
    static let space8: CGFloat = 48

    // Corner radii — app.css --radius*.
    static let radiusSm: CGFloat = 6
    static let radius: CGFloat = 10
    static let radiusLg: CGFloat = 14

    // Minimum touch target (WCAG 2.2 / HIG).
    static let tapMin: CGFloat = 44
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: Palette = .dark
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
