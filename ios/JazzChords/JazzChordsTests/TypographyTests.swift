import XCTest
import UIKit
@testable import JazzChords

final class TypographyTests: XCTestCase {
    func testFamiliesRegistered() {
        XCTAssertTrue(UIFont.familyNames.contains("Instrument Serif"))
        XCTAssertTrue(UIFont.familyNames.contains("Kalam"))
    }

    func testAccidentalsResolveInKalam() throws {
        try assertAccidentalsResolve(family: "Kalam")
    }

    func testAccidentalsResolveInInstrumentSerif() throws {
        try assertAccidentalsResolve(family: "Instrument Serif")
    }

    /// A glyph the face lacks and no fallback covers typesets as a box roughly
    /// the width of the em square — wider than a capital B.
    private func assertAccidentalsResolve(family: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let font = try XCTUnwrap(Display.uiFont(family: family, size: 40), file: file, line: line)
        let b = ("B" as NSString).size(withAttributes: [.font: font]).width
        for glyph in ["♭", "♯", "Δ", "ø", "°"] {
            let w = (glyph as NSString).size(withAttributes: [.font: font]).width
            XCTAssertLessThan(w, b * 1.2, "\(glyph) falls back to a box in \(family)", file: file, line: line)
        }
    }

    // Brand faces follow Dynamic Type: same size at the default category,
    // clearly larger at accessibility sizes (titles broke into "Auf-wär-men").
    func testBrandFaceSizeFollowsContentSize() {
        XCTAssertEqual(Display.pointSize(20, relativeTo: .title3, category: .large), 20, accuracy: 0.5)
        XCTAssertGreaterThan(Display.pointSize(20, relativeTo: .title3, category: .accessibilityExtraLarge), 26)
    }
}
