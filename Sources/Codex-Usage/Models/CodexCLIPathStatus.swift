import Foundation

enum CodexCLIPathStatus: Equatable, Sendable {
    case automaticDetected(String)
    case automaticNotFound
    case valid(String)
    case invalid(String)

    var message: String {
        switch self {
        case .automaticDetected(let path):
            return "已自动检测：\(path)"
        case .automaticNotFound:
            return "留空时将自动检测 Codex CLI；当前尚未检测到"
        case .valid:
            return "路径有效"
        case .invalid(let message):
            return message
        }
    }

    var systemImageName: String {
        switch self {
        case .automaticDetected, .valid:
            return "checkmark.circle.fill"
        case .automaticNotFound:
            return "info.circle"
        case .invalid:
            return "exclamationmark.triangle.fill"
        }
    }

    var isError: Bool {
        if case .invalid = self { return true }
        return false
    }

    static func resolve(
        configuredPath: String,
        autoDetectedPath: String?,
        fileManager: FileManager = .default
    ) -> CodexCLIPathStatus {
        let trimmed = configuredPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            if let autoDetectedPath {
                return .automaticDetected(autoDetectedPath)
            }
            return .automaticNotFound
        }

        return validateExplicitPath(trimmed, fileManager: fileManager)
    }

    static func validateExplicitPath(
        _ path: String,
        fileManager: FileManager = .default
    ) -> CodexCLIPathStatus {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("/"),
              trimmed.rangeOfCharacter(from: .controlCharacters) == nil else {
            return .invalid("请输入 Codex CLI 的绝对路径")
        }

        guard (trimmed as NSString).lastPathComponent == "codex" else {
            return .invalid("请选择名为 codex 的可执行文件")
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: trimmed, isDirectory: &isDirectory) else {
            return .invalid("指定的 Codex CLI 路径不存在")
        }

        guard !isDirectory.boolValue else {
            return .invalid("所选路径是文件夹，不是可执行文件")
        }

        guard fileManager.isExecutableFile(atPath: trimmed) else {
            return .invalid("所选文件没有执行权限")
        }

        return .valid(trimmed)
    }
}
