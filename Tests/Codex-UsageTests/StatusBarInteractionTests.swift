import AppKit
import XCTest
@testable import Codex_Usage

final class StatusBarInteractionTests: XCTestCase {
    func testRightMouseUpOpensContextMenu() {
        XCTAssertEqual(
            StatusBarInteraction.resolve(eventType: .rightMouseUp),
            .contextMenu
        )
    }

    func testOtherEventsTogglePopover() {
        XCTAssertEqual(
            StatusBarInteraction.resolve(eventType: .leftMouseUp),
            .togglePopover
        )
        XCTAssertEqual(
            StatusBarInteraction.resolve(eventType: nil),
            .togglePopover
        )
    }
}
