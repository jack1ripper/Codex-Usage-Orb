import Foundation

protocol CodexCLIExecutor: Sendable {
    func execute() throws -> Process
    var isInstalled: Bool { get }
}
struct DefaultCodexCLIExecutor: CodexCLIExecutor {
    func execute() throws -> Process {
        let process = Process()

        if let executablePath = resolveCodexExecutable() {
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = ["-s", "read-only", "-a", "untrusted", "app-server", "--stdio"]
        } else {
            // Fall back to PATH resolution; `CodexRPCClient` will report
            // `cliNotFound` via `isInstalled` if this cannot be resolved.
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["codex", "-s", "read-only", "-a", "untrusted", "app-server", "--stdio"]
        }

        return process
    }

    var isInstalled: Bool {
        resolveCodexExecutable() != nil
    }

    /// Returns the first valid `codex` executable path from:
    /// 1. The `codexCLIPath` `UserDefaults` override.
    /// 2. Common install locations for Homebrew, `~/.local/bin`, and system paths.
    /// 3. The first path returned by `/usr/bin/env which codex`.
    func resolveCodexExecutable() -> String? {
        if let overridePath = resolveUserDefaultsOverride() {
            return overridePath
        }

        if let commonPath = resolveCommonInstallLocation() {
            return commonPath
        }

        return resolveViaWhich()
    }

    // MARK: - Resolution helpers

    private func resolveUserDefaultsOverride() -> String? {
        let override = UserDefaults.standard.string(forKey: "codexCLIPath")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let override, !override.isEmpty else { return nil }

        return validatedOverridePath(override)
    }

    private func validatedOverridePath(_ path: String) -> String? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("/"),
              (trimmed as NSString).lastPathComponent == "codex",
              trimmed.rangeOfCharacter(from: .controlCharacters) == nil else {
            return nil
        }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: trimmed, isDirectory: &isDir),
              !isDir.boolValue,
              FileManager.default.isExecutableFile(atPath: trimmed) else {
            return nil
        }
        return trimmed
    }

    private func resolveCommonInstallLocation() -> String? {
        let candidates = [
            NSString(string: "~/.local/bin/codex").expandingTildeInPath,
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            "/usr/bin/codex",
            "/Applications/ChatGPT.app/Contents/Resources/codex",
        ]
        return candidates.first(where: fileExistsAtPath)
    }

    private func resolveViaWhich() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["which", "codex"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()

        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: output, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if task.terminationStatus == 0 && !path.isEmpty && fileExistsAtPath(path) {
            return path
        }
        return nil
    }

    private func fileExistsAtPath(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path) && FileManager.default.isExecutableFile(atPath: path)
    }
}

struct RPCResponse: Codable {
    let result: RPCRateLimitsResponse?
    let error: RPCErrorMessage?
}

struct RPCErrorMessage: Codable {
    let code: Int?
    let message: String
}

struct RPCRateLimitsResponse: Codable {
    struct RateLimitWindow: Codable {
        let usedPercent: Double
        let windowDurationMins: Int?
        let resetsAt: Date?
    }
    struct RateLimits: Codable {
        let primary: RateLimitWindow?
        let secondary: RateLimitWindow?
    }
    let rateLimits: RateLimits
}

protocol CodexRPCClientProtocol: Sendable {
    func fetchUsage() async throws -> UsageSnapshot
}

actor CodexRPCClient: CodexRPCClientProtocol {
    private let executor: CodexCLIExecutor

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    init(executor: CodexCLIExecutor = DefaultCodexCLIExecutor()) {
        self.executor = executor
    }

    func fetchUsage() async throws -> UsageSnapshot {
        guard executor.isInstalled else {
            throw UsageError.cliNotFound
        }

        let process = try executor.execute()
        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        drainStderr(stderr)
        let lines = lineStream(from: stdout)

        defer {
            if process.isRunning {
                process.terminate()
            }
        }

        try process.run()

        _ = try await request(
            id: 0,
            method: "initialize",
            params: ["clientInfo": ["name": "Codex-Usage", "version": "1.0.0"]],
            via: stdin,
            from: lines,
            timeout: 8
        )

        try sendNotification(method: "initialized", via: stdin)

        let responseLine = try await request(
            id: 1,
            method: "account/rateLimits/read",
            params: nil,
            via: stdin,
            from: lines,
            timeout: 8
        )

        if process.isRunning {
            process.terminate()
        }

        return try parseRateLimitsResponse(responseLine)
    }

    // MARK: - Response parsing

    nonisolated func parseRateLimitsResponse(_ data: Data) throws -> UsageSnapshot {
        let decoded: RPCResponse
        do {
            decoded = try decoder.decode(RPCResponse.self, from: data)
        } catch {
            throw UsageError.decodeFailed(error.localizedDescription)
        }

        if let error = decoded.error {
            throw UsageError.rpcFailed(error.message)
        }
        guard let result = decoded.result else {
            throw UsageError.rpcFailed("Missing result")
        }
        return UsageSnapshot(
            primary: UsageWindow(
                usedPercent: result.rateLimits.primary?.usedPercent ?? 0,
                windowMinutes: result.rateLimits.primary?.windowDurationMins,
                resetsAt: result.rateLimits.primary?.resetsAt
            ),
            secondary: UsageWindow(
                usedPercent: result.rateLimits.secondary?.usedPercent ?? 0,
                windowMinutes: result.rateLimits.secondary?.windowDurationMins,
                resetsAt: result.rateLimits.secondary?.resetsAt
            ),
            fetchedAt: Date()
        )
    }

    internal nonisolated func extractResponseLine(for id: Int, from data: Data) -> Data? {
        guard let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let lineId = json["id"] as? Int,
                  lineId == id else {
                continue
            }
            return lineData
        }
        return nil
    }

    // MARK: - JSON-RPC wiring

    private func request(
        id: Int,
        method: String,
        params: [String: Any]?,
        via stdin: Pipe,
        from lines: AsyncStream<Data>,
        timeout: TimeInterval
    ) async throws -> Data {
        try sendRequest(id: id, method: method, params: params, via: stdin)

        return try await withTimeout(seconds: timeout) {
            for await line in lines {
                guard let json = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else {
                    continue
                }
                // Skip server-initiated notifications that have no id.
                if json["id"] == nil, json["method"] != nil {
                    continue
                }
                guard let lineId = json["id"] as? Int, lineId == id else {
                    continue
                }
                if let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    let lowercased = message.localizedLowercase
                    if lowercased.contains("not authenticated") ||
                        lowercased.contains("unauthenticated") ||
                        lowercased.contains("unauthorized") ||
                        lowercased.contains("login") {
                        throw UsageError.notAuthenticated
                    }
                    throw UsageError.rpcFailed(message)
                }
                return line
            }
            throw UsageError.rpcFailed("Missing rate limits response")
        }
    }

    private func sendRequest(
        id: Int,
        method: String,
        params: [String: Any]?,
        via stdin: Pipe
    ) throws {
        var payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
        ]
        payload["params"] = params ?? [:]
        try sendPayload(payload, via: stdin)
    }

    private func sendNotification(method: String, via stdin: Pipe) throws {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": [:],
        ]
        try sendPayload(payload, via: stdin)
    }

    private func sendPayload(_ payload: [String: Any], via stdin: Pipe) throws {
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        stdin.fileHandleForWriting.write(data)
        stdin.fileHandleForWriting.write(Data("\n".utf8))
    }

    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw UsageError.rpcFailed("timeout")
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Stderr drain

    private nonisolated func drainStderr(_ pipe: Pipe) {
        let handle = pipe.fileHandleForReading
        handle.readabilityHandler = { handle in
            // Drain stderr so the child process never blocks on a full pipe.
            _ = handle.availableData
            if handle.availableData.isEmpty {
                handle.readabilityHandler = nil
            }
        }
    }

    // MARK: - Stdout line stream

    private nonisolated func lineStream(from pipe: Pipe) -> AsyncStream<Data> {
        AsyncStream { continuation in
            let buffer = LineBuffer()
            let handle = pipe.fileHandleForReading
            handle.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                    continuation.finish()
                    return
                }
                let lines = buffer.appendAndDrainLines(data)
                for line in lines {
                    continuation.yield(line)
                }
            }
        }
    }
}

// MARK: - Line buffer

private final class LineBuffer: @unchecked Sendable {
    private var buffer = Data()
    private let lock = NSLock()

    func appendAndDrainLines(_ data: Data) -> [Data] {
        lock.lock()
        defer { lock.unlock() }

        buffer.append(data)
        var out: [Data] = []
        while let newline = buffer.firstIndex(of: 0x0A) {
            let lineData = Data(buffer[..<newline])
            buffer.removeSubrange(...newline)
            if !lineData.isEmpty {
                out.append(lineData)
            }
        }
        return out
    }
}
