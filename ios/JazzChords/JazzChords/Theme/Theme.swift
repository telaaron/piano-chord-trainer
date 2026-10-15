// Theme — maps the web app's design tokens (src/app.css) 1:1 to SwiftUI Colors.
//
// The press palette: ink on paper. Dark is a night pressroom (deep slate-navy),
// light is warm newsprint — NOT white, so it reads as paper rather than a blank
// screen. Stamp red is the publisher's stamp and the teacher's red pencil;
// copyist blue is the second ink, for annotation and structure. Amber survives
// from the old palette but is now reserved for one thing: live/active state.
//
// Values are copied verbatim from src/app.css (`:root` = dark,
// `[data-theme="light"]` = light) so the two platforms cannot drift apart.
// Where the light block omits a token it inherits `:root`, and that inheritance
// is reproduced here explicitly — see `stamp`.

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
    /// Copyist blue — the second ink. Annotation, analysis, structure.
    let inkBlue: Color
    /// The publisher's stamp. Reserved for live/active state; constant across
    /// schemes because the light block inherits it from `:root`.
    let stamp: Color
    let stampHover: Color
    let stampInk: Color
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
    // ── Editorial roles (spec §3.1). Views use these; the fields above are
    // legacy and disappear once every screen has moved over.
    /// Screen background — night blue / paper.
    let canvas: Color
    /// Primary text and the rule under titles.
    let ink: Color
    /// Secondary text and eyebrows.
    let inkMuted: Color
    /// Dividers and staff lines.
    let hairline: Color
    /// Inset-grouped list background.
    let group: Color
    /// Red: act or error — primary button, feature block, active tab, missing note.
    let action: Color
    /// Text on `action`.
    let onAction: Color
    /// Gold: music, success, progress — stats, chord badges, "done".
    let music: Color
    /// Gold fill for played keys and progress bars.
    let musicFill: Color
    /// Bed behind the edge-to-edge keyboard.
    let keyBed: Color

    /// Night pressroom — dark. Verbatim from `:root` in app.css.
    static let dark = Palette(
        bg: Color(hex: "0e141d"), bgCard: Color(hex: "151d29"), bgCardHover: Color(hex: "1c2735"),
        bgMuted: Color(hex: "1a2431"), border: Color(hex: "26323f"), borderHover: Color(hex: "38485a"),
        text: Color(hex: "eef1f4"), textMuted: Color(hex: "a3b0bf"), textDim: Color(hex: "71808f"),
        primary: Color(hex: "e2685c"), primaryHover: Color(hex: "ee7d71"), primaryText: Color(hex: "14090a"),
        inkBlue: Color(hex: "7ba7d4"),
        stamp: Color(hex: "f5a623"), stampHover: Color(hex: "ffb840"), stampInk: Color(hex: "14090a"),
        accentGold: Color(hex: "e8b04b"), accentAmber: Color(hex: "f5a623"),
        accentRed: Color(hex: "e2685c"), accentGreen: Color(hex: "3fd09a"),
        success: Color(hex: "4ade80"), warning: Color(hex: "f59e0b"), danger: Color(hex: "ef4444"),
        xp: Color(hex: "fb923c"),
        keyWhite: Color(hex: "f5f4fa"), keyWhiteActive: Color(hex: "e8b04b"), keyWhiteBorder: Color(hex: "c9c6da"),
        keyBlack: Color(hex: "161329"), keyBlackActive: Color(hex: "f5a623"), keyRootDot: Color(hex: "e8b04b"),
        canvas: Color(hex: "0E141D"), ink: Color(hex: "F2E8D5"), inkMuted: Color(hex: "9AA6B8"),
        hairline: Color(hex: "2A3443"), group: Color(hex: "151D29"),
        action: Color(hex: "E06A5C"), onAction: Color(hex: "0E141D"),
        music: Color(hex: "E8B04B"), musicFill: Color(hex: "E8B04B"), keyBed: Color(hex: "070A0F"))

    /// Warm newsprint — light. Verbatim from `[data-theme="light"]` in app.css.
    /// Note `bg` is paper, not white; the stamp trio is inherited from `:root`.
    static let light = Palette(
        bg: Color(hex: "ecefe9"), bgCard: Color(hex: "fbfcf9"), bgCardHover: Color(hex: "f2f4ee"),
        bgMuted: Color(hex: "e2e6de"), border: Color(hex: "d2d8cd"), borderHover: Color(hex: "b4bdad"),
        text: Color(hex: "131a26"), textMuted: Color(hex: "4a5563"), textDim: Color(hex: "6b7684"),
        primary: Color(hex: "b0302a"), primaryHover: Color(hex: "96231e"), primaryText: Color(hex: "ffffff"),
        inkBlue: Color(hex: "2c5985"),
        stamp: Color(hex: "f5a623"), stampHover: Color(hex: "ffb840"), stampInk: Color(hex: "14090a"),
        accentGold: Color(hex: "8f5a05"), accentAmber: Color(hex: "8f5a05"),
        accentRed: Color(hex: "b0302a"), accentGreen: Color(hex: "18936a"),
        success: Color(hex: "18936a"), warning: Color(hex: "b87708"), danger: Color(hex: "d23b34"),
        xp: Color(hex: "8f5a05"),
        keyWhite: Color(hex: "ffffff"), keyWhiteActive: Color(hex: "d9a441"), keyWhiteBorder: Color(hex: "cdd3c8"),
        keyBlack: Color(hex: "131a26"), keyBlackActive: Color(hex: "8f5a05"), keyRootDot: Color(hex: "b0302a"),
        canvas: Color(hex: "F6F2EA"), ink: Color(hex: "1A1916"), inkMuted: Color(hex: "77716A"),
        hairline: Color(hex: "CFC7B8"), group: Color(hex: "FFFFFF"),
        action: Color(hex: "B0302A"), onAction: Color(hex: "FFF8EF"),
        music: Color(hex: "8F5A05"), musicFill: Color(hex: "E2A93B"), keyBed: Color(hex: "1A1916"))
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
    /// Inset-grouped lists.
    static let radiusGroup: CGFloat = 22
    /// The one red feature block per screen.
    static let radiusFeature: CGFloat = 26

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
