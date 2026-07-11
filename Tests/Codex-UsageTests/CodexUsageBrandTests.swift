import AppKit
import XCTest
@testable import Codex_Usage

@MainActor
final class CodexUsageBrandTests: XCTestCase {
    func testMenuBarImageLoadsAsEighteenPointTemplate() throws {
        let image = try XCTUnwrap(CodexUsageBrand.menuBarImage())

        XCTAssertEqual(image.size.width, 18)
        XCTAssertEqual(image.size.height, 18)
        XCTAssertTrue(image.isTemplate)
    }
}
