import XCTest
@testable import Codex_Usage

@MainActor
final class FloatingWindowControllerTests: XCTestCase {
    func testShowCreatesOneVisiblePanelWithoutReentrantConstruction() {
        let service = UsageRefreshService(previewSnapshot: UsageSnapshot(
            primary: UsageWindow(usedPercent: 10, windowMinutes: 300, resetsAt: nil),
            secondary: UsageWindow(usedPercent: 20, windowMinutes: 10_080, resetsAt: nil),
            fetchedAt: Date()
        ))
        let controller = FloatingWindowController(service: service)

        controller.show()
        addTeardownBlock { @MainActor in
            controller.close()
        }

        XCTAssertTrue(controller.isFloatingPanelVisible)
        controller.show()
        XCTAssertTrue(controller.isFloatingPanelVisible)
    }
}
