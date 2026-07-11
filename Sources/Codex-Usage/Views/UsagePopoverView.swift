import SwiftUI

struct UsagePopoverView: View {
    @ObservedObject var service: UsageRefreshService
    let onSettings: () -> Void
    let onRefresh: () -> Void

    private var state: UsageDisplayState {
        UsageDisplayState.resolve(snapshot: service.snapshot, error: service.error)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .frame(width: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 9) {
            CodexUsageLogoView(pointSize: 18)

            Text("Codex 用量")
                .font(.system(size: 16, weight: .semibold))

            switch state {
            case .data(_, let isStale) where isStale:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
                    .help("当前显示的是上次成功获取的数据")
            default:
                if service.isLoading, service.snapshot != nil {
                    ProgressView()
                        .controlSize(.small)
                        .help("正在刷新")
                }
            }

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("设置")
            .accessibilityLabel("打开设置")
        }
        .padding(.horizontal, 18)
        .frame(height: 50)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            VStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("正在获取用量…")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 126)

        case .error(let error):
            let presentation = UsageErrorPresentation(error: error)
            VStack(spacing: 9) {
                Image(systemName: presentation.systemImageName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.orange)

                Text(presentation.title)
                    .font(.system(size: 14, weight: .semibold))

                Text(presentation.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if presentation.canRetry {
                    Button("重试", action: onRefresh)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 126)

        case .data(let snapshot, _):
            VStack(spacing: 0) {
                UsageQuotaRow(
                    presentation: UsageQuotaPresentation(
                        kind: .primary,
                        window: snapshot.primary
                    ),
                    window: snapshot.primary,
                    style: .detail
                )

                Divider()

                UsageQuotaRow(
                    presentation: UsageQuotaPresentation(
                        kind: .weekly,
                        window: snapshot.secondary
                    ),
                    window: snapshot.secondary,
                    style: .detail
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 5)
        }
    }

}

#if DEBUG
#Preview("Popover") {
    UsagePopoverView(
        service: UsageRefreshService(previewSnapshot: UsageSnapshot(
            primary: UsageWindow(
                usedPercent: 3,
                windowMinutes: 300,
                resetsAt: Date().addingTimeInterval(4 * 3600)
            ),
            secondary: UsageWindow(
                usedPercent: 1,
                windowMinutes: 10_080,
                resetsAt: Date().addingTimeInterval(7 * 24 * 3600)
            ),
            fetchedAt: Date()
        )),
        onSettings: {},
        onRefresh: {}
    )
}

#Preview("Low quota") {
    UsagePopoverView(
        service: UsageRefreshService(previewSnapshot: UsageSnapshot(
            primary: UsageWindow(
                usedPercent: 84,
                windowMinutes: 300,
                resetsAt: Date().addingTimeInterval(2 * 3600)
            ),
            secondary: UsageWindow(
                usedPercent: 95,
                windowMinutes: 10_080,
                resetsAt: Date().addingTimeInterval(2 * 24 * 3600)
            ),
            fetchedAt: Date()
        )),
        onSettings: {},
        onRefresh: {}
    )
}

#Preview("Stale data") {
    UsagePopoverView(
        service: UsageRefreshService(
            previewSnapshot: UsageSnapshot(
                primary: UsageWindow(
                    usedPercent: 20,
                    windowMinutes: 300,
                    resetsAt: Date().addingTimeInterval(2 * 3600)
                ),
                secondary: UsageWindow(
                    usedPercent: 30,
                    windowMinutes: 10_080,
                    resetsAt: Date().addingTimeInterval(2 * 24 * 3600)
                ),
                fetchedAt: Date().addingTimeInterval(-900)
            ),
            previewError: .rpcFailed("offline")
        ),
        onSettings: {},
        onRefresh: {}
    )
}

#Preview("Loading") {
    UsagePopoverView(
        service: UsageRefreshService(previewIsLoading: true),
        onSettings: {},
        onRefresh: {}
    )
}

#Preview("Hard error") {
    UsagePopoverView(
        service: UsageRefreshService(previewError: .cliNotFound),
        onSettings: {},
        onRefresh: {}
    )
}
#endif
