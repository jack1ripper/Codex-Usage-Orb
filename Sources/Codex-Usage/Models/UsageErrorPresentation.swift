struct UsageErrorPresentation: Equatable, Sendable {
    let title: String
    let message: String
    let systemImageName: String
    let canRetry: Bool

    init(error: UsageError) {
        switch error {
        case .cliNotFound:
            title = "未找到 Codex CLI"
            message = "请在设置中选择 Codex CLI 的路径。"
            systemImageName = "terminal"
            canRetry = false
        case .notAuthenticated:
            title = "Codex CLI 尚未登录"
            message = "请先在终端运行 codex login。"
            systemImageName = "person.crop.circle.badge.xmark"
            canRetry = false
        case .rpcFailed, .decodeFailed:
            title = "暂时无法获取用量"
            message = "请检查网络或稍后重试。"
            systemImageName = "exclamationmark.triangle"
            canRetry = true
        case .incompatibleResponse:
            title = "Codex CLI 版本不兼容"
            message = "请更新 Codex CLI 后重试。"
            systemImageName = "arrow.triangle.2.circlepath"
            canRetry = true
        }
    }
}
