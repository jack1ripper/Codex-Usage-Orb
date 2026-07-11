import XCTest
@testable import Codex_Usage

final class UsageErrorPresentationTests: XCTestCase {
    func testCLIMissingPresentationExplainsPathSelection() {
        let presentation = UsageErrorPresentation(error: .cliNotFound)

        XCTAssertEqual(presentation.title, "未找到 Codex CLI")
        XCTAssertEqual(presentation.message, "请在设置中选择 Codex CLI 的路径。")
        XCTAssertEqual(presentation.systemImageName, "terminal")
        XCTAssertFalse(presentation.canRetry)
    }

    func testUnauthenticatedPresentationExplainsLogin() {
        let presentation = UsageErrorPresentation(error: .notAuthenticated)

        XCTAssertEqual(presentation.title, "Codex CLI 尚未登录")
        XCTAssertEqual(presentation.message, "请先在终端运行 codex login。")
        XCTAssertEqual(presentation.systemImageName, "person.crop.circle.badge.xmark")
        XCTAssertFalse(presentation.canRetry)
    }

    func testRPCFailurePresentationAllowsRetry() {
        let presentation = UsageErrorPresentation(error: .rpcFailed("timeout"))

        XCTAssertEqual(presentation.title, "暂时无法获取用量")
        XCTAssertEqual(presentation.message, "请检查网络或稍后重试。")
        XCTAssertEqual(presentation.systemImageName, "exclamationmark.triangle")
        XCTAssertTrue(presentation.canRetry)
    }

    func testIncompatibleResponsePresentationRequestsCLIUpdate() {
        let presentation = UsageErrorPresentation(
            error: .incompatibleResponse("missing windows")
        )

        XCTAssertEqual(presentation.title, "Codex CLI 版本不兼容")
        XCTAssertEqual(presentation.message, "请更新 Codex CLI 后重试。")
        XCTAssertEqual(presentation.systemImageName, "arrow.triangle.2.circlepath")
        XCTAssertTrue(presentation.canRetry)
    }
}
