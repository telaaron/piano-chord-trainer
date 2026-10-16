import XCTest
import SwiftUI
@testable import JazzChords

final class AppearanceTests: XCTestCase {
    func testAppearanceMapsToScheme() {
        XCTAssertEqual(Appearance.scheme(.light), .light)
        XCTAssertEqual(Appearance.scheme(.dark), .dark)
        XCTAssertNil(Appearance.scheme(.system))
    }

    func testAppearanceDefaultsToSystem() {
        XCTAssertEqual(Appearance(stored: nil), .system)
        XCTAssertEqual(Appearance(stored: "dark"), .dark)
        XCTAssertEqual(Appearance(stored: "nonsense"), .system)
    }

    func testProfileInitial() {
        XCTAssertEqual(ProfileCircleButton.initial(for: "aaron@x.de"), "A")
        XCTAssertEqual(ProfileCircleButton.initial(for: "  zoe@x.de"), "Z")
        XCTAssertNil(ProfileCircleButton.initial(for: nil))
        XCTAssertNil(ProfileCircleButton.initial(for: ""))
    }
}
