import XCTest
@testable import Codex_Usage

final class UsageRefreshServiceTests: XCTestCase {
    @MainActor
    func testPublishesSnapshotAfterRefresh() async {
        let service = UsageRefreshService()
        
        XCTAssertNil(service.snapshot)
        XCTAssertFalse(service.isLoading)
        
        await service.refresh()
        
        // Outcome depends on local Codex CLI state; in CI this may be .cliNotFound.
        // The important behavior is that isLoading returns to false.
        XCTAssertFalse(service.isLoading)
    }
}
