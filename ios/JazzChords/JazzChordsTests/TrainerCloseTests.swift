import XCTest
@testable import JazzChords

final class TrainerCloseTests: XCTestCase {
    // × in a session started from Heute/Üben goes back there, not into the
    // trainer's own setup screen; only free practice returns to setup.
    func testCloseLeavesTrainerWhenStartedDirectly() {
        XCTAssertTrue(TrainerView.closeLeavesTrainer(coachSession: true, hasPlan: false))
        XCTAssertTrue(TrainerView.closeLeavesTrainer(coachSession: false, hasPlan: true))
        XCTAssertFalse(TrainerView.closeLeavesTrainer(coachSession: false, hasPlan: false))
    }
}
