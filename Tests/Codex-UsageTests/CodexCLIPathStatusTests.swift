import XCTest
@testable import Codex_Usage

final class CodexCLIPathStatusTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexCLIPathStatusTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    func testEmptyPathShowsDetectedExecutable() {
        let status = CodexCLIPathStatus.resolve(
            configuredPath: "  ",
            autoDetectedPath: "/opt/homebrew/bin/codex"
        )

        XCTAssertEqual(status, .automaticDetected("/opt/homebrew/bin/codex"))
    }

    func testEmptyPathShowsMissingAutomaticDetection() {
        let status = CodexCLIPathStatus.resolve(
            configuredPath: "",
            autoDetectedPath: nil
        )

        XCTAssertEqual(status, .automaticNotFound)
    }

    func testValidExplicitExecutableIsAccepted() throws {
        let executable = try makeFile(name: "codex", permissions: 0o755)

        let status = CodexCLIPathStatus.resolve(
            configuredPath: executable.path,
            autoDetectedPath: nil
        )

        XCTAssertEqual(status, .valid(executable.path))
    }

    func testRelativePathIsRejected() {
        let status = CodexCLIPathStatus.resolve(
            configuredPath: "bin/codex",
            autoDetectedPath: nil
        )

        XCTAssertEqual(status, .invalid("请输入 Codex CLI 的绝对路径"))
    }

    func testWrongFilenameIsRejected() throws {
        let executable = try makeFile(name: "not-codex", permissions: 0o755)

        let status = CodexCLIPathStatus.resolve(
            configuredPath: executable.path,
            autoDetectedPath: nil
        )

        XCTAssertEqual(status, .invalid("请选择名为 codex 的可执行文件"))
    }

    func testDirectoryIsRejected() throws {
        let directory = temporaryDirectory.appendingPathComponent("codex")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)

        let status = CodexCLIPathStatus.resolve(
            configuredPath: directory.path,
            autoDetectedPath: nil
        )

        XCTAssertEqual(status, .invalid("所选路径是文件夹，不是可执行文件"))
    }

    func testMissingFileIsRejected() {
        let path = temporaryDirectory.appendingPathComponent("codex").path

        let status = CodexCLIPathStatus.resolve(
            configuredPath: path,
            autoDetectedPath: nil
        )

        XCTAssertEqual(status, .invalid("指定的 Codex CLI 路径不存在"))
    }

    func testNonExecutableFileIsRejected() throws {
        let file = try makeFile(name: "codex", permissions: 0o644)

        let status = CodexCLIPathStatus.resolve(
            configuredPath: file.path,
            autoDetectedPath: nil
        )

        XCTAssertEqual(status, .invalid("所选文件没有执行权限"))
    }

    private func makeFile(name: String, permissions: Int) throws -> URL {
        let url = temporaryDirectory.appendingPathComponent(name)
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data("#!/bin/sh\n".utf8)))
        try FileManager.default.setAttributes(
            [.posixPermissions: permissions],
            ofItemAtPath: url.path
        )
        return url
    }
}
