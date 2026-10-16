import XCTest
import UIKit
import MusicEngine
@testable import JazzChords

final class PlanPresentationTests: XCTestCase {
    func testCoversEveryPlan() {
        let ids = Set(PlanPresentation.all.map(\.id))
        for plan in PRACTICE_PLANS {
            XCTAssertTrue(ids.contains(plan.id), "no presentation for \(plan.id)")
        }
        XCTAssertTrue(ids.contains(PlanPresentation.freeId))
        XCTAssertTrue(ids.contains(PlanPresentation.customId))
    }

    func testNoChordSymbolIcons() {
        for p in PlanPresentation.all {
            for bad in ["Δ", "°", "ø", "∞", "+", "♭", "♯"] {
                XCTAssertFalse(p.symbol.contains(bad), "\(p.id) uses chord text \(bad) as icon")
            }
            XCTAssertFalse(p.symbol.allSatisfy(\.isNumber), "\(p.id) icon is a number")
        }
    }

    func testSymbolsExist() {
        for p in PlanPresentation.all {
            XCTAssertNotNil(UIImage(systemName: p.symbol), "missing SF Symbol \(p.symbol) for \(p.id)")
        }
    }

    func testGroupOrder() {
        XCTAssertEqual(PracticeGroup.allCases, [.start, .jazzForms, .targeted, .ownWay])
        // Every group has at least one row.
        for g in PracticeGroup.allCases {
            XCTAssertFalse(PlanPresentation.all.filter { $0.group == g }.isEmpty, "empty group \(g)")
        }
    }

    func testEveryRowHasPlainWords() {
        for p in PlanPresentation.all {
            XCTAssertFalse(p.title.isEmpty, p.id)
            XCTAssertFalse(p.subtitle.isEmpty, p.id)
        }
    }
}
