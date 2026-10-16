// Theme — the editorial palette (spec §3.1) as semantic roles.
//
// Dark is a night stage (deep navy), light is warm paper — not white. Three
// colours carry meaning: red (`action`) = act or error, gold (`music`,
// `musicFill`, the website's #e8b04b) = music, success, progress, and the
// night blue `canvas` = the stage. Views use roles, never raw hex.

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
    // Piano key faces (the bed and key states use the roles below).
    let keyWhite: Color
    let keyBlack: Color
    // ── Editorial roles (spec §3.1).
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
    /// The one feature block per screen. Dark: deep oxblood, so it reads as
    /// light type on a dark field instead of a glaring coral card.
    let feature: Color
    /// Text and the inverted button on `feature`.
    let onFeature: Color
    /// Eyebrow on `feature`.
    let featureAccent: Color

    /// Night stage — dark.
    static let dark = Palette(
        // Variant E (Aaron, 16.10.): brighter secondary text, visible
        // hairlines, lifted groups, softer white keys at night.
        keyWhite: Color(hex: "ECE6DA"), keyBlack: Color(hex: "161329"),
        canvas: Color(hex: "0E141D"), ink: Color(hex: "F2E8D5"), inkMuted: Color(hex: "B4BCC8"),
        hairline: Color(hex: "3A4658"), group: Color(hex: "18212E"),
        action: Color(hex: "F07B6C"), onAction: Color(hex: "0E141D"),
        music: Color(hex: "E8B04B"), musicFill: Color(hex: "E8B04B"), keyBed: Color(hex: "070A0F"),
        feature: Color(hex: "8C2A22"), onFeature: Color(hex: "F6EDE0"), featureAccent: Color(hex: "F2C46B"))

    /// Warm paper — light.
    static let light = Palette(
        keyWhite: Color(hex: "ffffff"), keyBlack: Color(hex: "131a26"),
        canvas: Color(hex: "F6F2EA"), ink: Color(hex: "1A1916"), inkMuted: Color(hex: "736D66"),
        hairline: Color(hex: "CFC7B8"), group: Color(hex: "FFFFFF"),
        action: Color(hex: "B0302A"), onAction: Color(hex: "FFF8EF"),
        music: Color(hex: "8F5A05"), musicFill: Color(hex: "E2A93B"), keyBed: Color(hex: "1A1916"),
        feature: Color(hex: "B0302A"), onFeature: Color(hex: "FFF8EF"), featureAccent: Color(hex: "FFF8EF"))
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
