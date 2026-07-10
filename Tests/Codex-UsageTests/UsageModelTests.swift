import XCTest
@testable import Codex_Usage

final class UsageModelTests: XCTestCase {
    // MARK: - UsageWindow remaining calculations

    func testRemainingPercentAndRatio() {
        let cases: [(used: Double, expectedPercent: Double, expectedRatio: Double)] = [
            (0, 100, 1),
            (50, 50, 0.5),
            (100, 0, 0),
            (-10, 100, 1),
            (150, 0, 0),
        ]

        for (used, expectedPercent, expectedRatio) in cases {
            let window = UsageWindow(usedPercent: used, windowMinutes: nil, resetsAt: nil)
            XCTAssertEqual(window.remainingPercent, expectedPercent, accuracy: 0.0001, "usedPercent: \(used)")
            XCTAssertEqual(window.remainingRatio, expectedRatio, accuracy: 0.0001, "usedPercent: \(used)")
        }
    }

    // MARK: - UsageError equality

    func testUsageErrorEquality() {
        XCTAssertEqual(UsageError.cliNotFound, UsageError.cliNotFound)
        XCTAssertEqual(UsageError.notAuthenticated, UsageError.notAuthenticated)
        XCTAssertEqual(UsageError.rpcFailed("timeout"), UsageError.rpcFailed("timeout"))
        XCTAssertNotEqual(UsageError.rpcFailed("timeout"), UsageError.rpcFailed("refused"))
        XCTAssertEqual(UsageError.decodeFailed("bad json"), UsageError.decodeFailed("bad json"))
        XCTAssertNotEqual(UsageError.decodeFailed("bad json"), UsageError.decodeFailed("missing key"))
        XCTAssertNotEqual(UsageError.cliNotFound, UsageError.notAuthenticated)
    }

    // MARK: - UsageSnapshot equality

    func testUsageSnapshotEquality() {
        let now = Date()
        let primary = UsageWindow(usedPercent: 30, windowMinutes: 300, resetsAt: now)
        let secondary = UsageWindow(usedPercent: 60, windowMinutes: 10080, resetsAt: now.addingTimeInterval(3600))

        let snapshot1 = UsageSnapshot(primary: primary, secondary: secondary, fetchedAt: now)
        let snapshot2 = UsageSnapshot(primary: primary, secondary: secondary, fetchedAt: now)
        XCTAssertEqual(snapshot1, snapshot2)

        let differentFetchedAt = UsageSnapshot(primary: primary, secondary: secondary, fetchedAt: now.addingTimeInterval(1))
        XCTAssertNotEqual(snapshot1, differentFetchedAt)

        let differentSecondary = UsageSnapshot(
            primary: primary,
            secondary: UsageWindow(usedPercent: 70, windowMinutes: 10080, resetsAt: now.addingTimeInterval(3600)),
            fetchedAt: now
        )
        XCTAssertNotEqual(snapshot1, differentSecondary)
    }

    // MARK: - UsageWindow decoding contract

    func testUsageWindowDecodesFromRPCJSON() throws {
        let json = """
        {
            "usedPercent": 42.5,
            "window_duration_mins": 300,
            "resets_at": "2026-07-10T10:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try XCTUnwrap(json.data(using: .utf8))
        let window = try decoder.decode(UsageWindow.self, from: data)

        XCTAssertEqual(window.usedPercent, 42.5, accuracy: 0.0001)
        XCTAssertEqual(window.windowMinutes, 300)
        XCTAssertNotNil(window.resetsAt)
    }
}
