import XCTest
import MusicEngine
@testable import JazzChords

final class GuideLibraryTests: XCTestCase {
    func testFourGuidesBothLanguages() {
        for german in [false, true] {
            let guides = GuideLibrary.all(german: german)
            XCTAssertEqual(guides.map(\.id), ["ii-v-i", "left-hand", "rootless-voicings", "jazz-piano-voicings"])
            for g in guides {
                XCTAssertFalse(g.title.isEmpty, g.id)
                XCTAssertFalse(g.title.hasPrefix("#"), g.id)
                XCTAssertGreaterThan(g.blocks.count, 3, g.id)
            }
        }
    }

    func testGermanUsesGermanArticlesWhereTheyExist() {
        let de = GuideLibrary.all(german: true)
        XCTAssertEqual(de.first { $0.id == "ii-v-i" }?.title, "II-V-I in allen 12 Tonarten")
        XCTAssertEqual(de.first { $0.id == "left-hand" }?.title, "Jazz-Voicings für die linke Hand")
    }

    func testGermanFallsBackToEnglish() {
        let de = GuideLibrary.all(german: true).first { $0.id == "rootless-voicings" }
        XCTAssertEqual(de?.title, "Rootless Voicings for Jazz Piano")
    }

    func testEveryGuidePlanExists() {
        let ids = Set(PRACTICE_PLANS.map(\.id))
        for g in GuideLibrary.all(german: false) {
            XCTAssertTrue(ids.contains(g.planId), "\(g.id) → \(g.planId)")
        }
    }

    func testNoWebOnlyLeftovers() {
        for german in [false, true] {
            for g in GuideLibrary.all(german: german) {
                for b in g.blocks {
                    if case .paragraph(let t) = b {
                        XCTAssertFalse(t.contains("jazzchords.app/"), "\(g.id): \(t)")
                        XCTAssertFalse(t.contains("{"), "\(g.id): \(t)")
                    }
                    if case .heading(let t, _) = b { XCTAssertFalse(t.isEmpty, g.id) }
                }
            }
        }
    }
}

final class LessonTitleTests: XCTestCase {
    func testLessonTitlesShort() {
        for german in [false, true] {
            for (id, title) in Strings.allLessonTitles(german: german) {
                XCTAssertLessThanOrEqual(title.count, 22, "\(german ? "de" : "en") \(id): \(title)")
            }
        }
    }
}
