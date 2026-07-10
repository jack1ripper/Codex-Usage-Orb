import XCTest
@testable import Codex_Usage

actor MockCodexRPCClient: CodexRPCClientProtocol {
    private(set) var fetchCount = 0
    private var result: Result<UsageSnapshot, Error> = .failure(UsageError.cliNotFound)

    func setResult(_ result: Result<UsageSnapshot, Error>) {
        self.result = result
    }

    func fetchUsage() async throws -> UsageSnapshot {
        fetchCount += 1
        switch result {
        case .success(let snapshot):
            return snapshot
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
final class UsageRefreshServiceTests: XCTestCase {
    private let snapshot = UsageSnapshot(
        primary: UsageWindow(usedPercent: 10, windowMinutes: 300, resetsAt: Date(timeIntervalSince1970: 1_000_000)),
        secondary: UsageWindow(usedPercent: 20, windowMinutes: 10080, resetsAt: Date(timeIntervalSince1970: 2_000_000)),
        fetchedAt: Date(timeIntervalSince1970: 0)
    )

    func testRefreshPublishesSnapshotOnSuccess() async {
        let mock = MockCodexRPCClient()
        await mock.setResult(.success(snapshot))
        let service = UsageRefreshService(rpcClient: mock)

        XCTAssertNil(service.snapshot)
        XCTAssertFalse(service.isLoading)

        await service.refresh()

        XCTAssertEqual(service.snapshot, snapshot)
        XCTAssertNil(service.error)
        XCTAssertFalse(service.isLoading)
        let count = await mock.fetchCount
        XCTAssertEqual(count, 1)
    }

    func testRefreshPublishesErrorOnFailure() async {
        let mock = MockCodexRPCClient()
        await mock.setResult(.failure(UsageError.cliNotFound))
        let service = UsageRefreshService(rpcClient: mock)

        await service.refresh()

        XCTAssertNil(service.snapshot)
        XCTAssertEqual(service.error, .cliNotFound)
        XCTAssertFalse(service.isLoading)
        let count = await mock.fetchCount
        XCTAssertEqual(count, 1)
    }

    func testRefreshDoesNotRunConcurrently() async {
        let mock = MockCodexRPCClient()
        await mock.setResult(.success(snapshot))
        let service = UsageRefreshService(rpcClient: mock)

        async let first: () = service.refresh()
        async let second: () = service.refresh()
        _ = await (first, second)

        XCTAssertEqual(service.snapshot, snapshot)
        XCTAssertNil(service.error)
        XCTAssertFalse(service.isLoading)
        let count = await mock.fetchCount
        XCTAssertEqual(count, 1)
    }

    func testStartIsIdempotent() async throws {
        let mock = MockCodexRPCClient()
        await mock.setResult(.success(snapshot))
        let service = UsageRefreshService(rpcClient: mock, refreshInterval: 1)

        service.start()
        service.start()

        try await Task.sleep(for: .milliseconds(50))
        service.stop()

        let count = await mock.fetchCount
        XCTAssertEqual(count, 1)
    }
}
