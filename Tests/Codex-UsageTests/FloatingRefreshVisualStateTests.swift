import XCTest
@testable import Codex_Usage

final class FloatingRefreshVisualStateTests: XCTestCase {
    func testDefaultStateShowsLogo() {
        XCTAssertEqual(
            FloatingRefreshVisualState.resolve(isLoading: false, isHovering: false),
            .logo
        )
    }

    func testHoverStateShowsRefreshGlyph() {
        XCTAssertEqual(
            FloatingRefreshVisualState.resolve(isLoading: false, isHovering: true),
            .refresh
        )
    }

    func testLoadingStateTakesPriorityOverHover() {
        XCTAssertEqual(
            FloatingRefreshVisualState.resolve(isLoading: true, isHovering: true),
            .loading
        )
    }
}
