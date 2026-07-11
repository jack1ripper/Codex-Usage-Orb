import Foundation
import XCTest
@testable import Codex_Usage

final class UsageDisplayStateTests: XCTestCase {
    func testNoSnapshotUsesLoadingUntilAnErrorExists() {
        XCTAssertEqual(
            UsageDisplayState.resolve(snapshot: nil, error: nil),
            .loading
        )
        XCTAssertEqual(
            UsageDisplayState.resolve(snapshot: nil, error: .cliNotFound),
            .error(.cliNotFound)
        )
    }

    func testSnapshotRemainsVisibleAndMarksRefreshErrorAsStale() {
        let snapshot = makeSnapshot()

        XCTAssertEqual(
            UsageDisplayState.resolve(snapshot: snapshot, error: nil),
            .data(snapshot, isStale: false)
        )
        XCTAssertEqual(
            UsageDisplayState.resolve(snapshot: snapshot, error: .rpcFailed("offline")),
            .data(snapshot, isStale: true)
        )
    }

    private func makeSnapshot() -> UsageSnapshot {
        UsageSnapshot(
            primary: UsageWindow(usedPercent: 3, windowMinutes: 300, resetsAt: nil),
            secondary: UsageWindow(usedPercent: 1, windowMinutes: 10_080, resetsAt: nil),
            fetchedAt: Date(timeIntervalSince1970: 1_000)
        )
    }
}
