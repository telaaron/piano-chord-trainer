import XCTest
import SwiftUI
@testable import JazzChords

final class PaletteTests: XCTestCase {
    private func rgb(_ c: Color) -> [Int] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b].map { Int(($0 * 255).rounded()) }
    }

    private func assertRole(_ c: Color, _ hex: String, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(rgb(c), rgb(Color(hex: hex)), name, file: file, line: line)
    }

    func testDarkRolesMatchSpec() {
        let p = Palette.dark
        assertRole(p.canvas, "0E141D", "canvas")
        assertRole(p.ink, "F2E8D5", "ink")
        assertRole(p.inkMuted, "9AA6B8", "inkMuted")
        assertRole(p.hairline, "2A3443", "hairline")
        assertRole(p.group, "151D29", "group")
        assertRole(p.action, "E06A5C", "action")
        assertRole(p.onAction, "0E141D", "onAction")
        assertRole(p.music, "E8B04B", "music")
        assertRole(p.musicFill, "E8B04B", "musicFill")
        assertRole(p.keyBed, "070A0F", "keyBed")
    }

    func testLightRolesMatchSpec() {
        let p = Palette.light
        assertRole(p.canvas, "F6F2EA", "canvas")
        assertRole(p.ink, "1A1916", "ink")
        assertRole(p.inkMuted, "736D66", "inkMuted")
        assertRole(p.hairline, "CFC7B8", "hairline")
        assertRole(p.group, "FFFFFF", "group")
        assertRole(p.action, "B0302A", "action")
        assertRole(p.onAction, "FFF8EF", "onAction")
        assertRole(p.music, "8F5A05", "music")
        assertRole(p.musicFill, "E2A93B", "musicFill")
        assertRole(p.keyBed, "1A1916", "keyBed")
    }
}
