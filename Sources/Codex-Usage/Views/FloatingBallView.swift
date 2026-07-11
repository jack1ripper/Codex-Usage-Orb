import SwiftUI

/// The optional always-on-top desktop summary. The historical type name is
/// retained so existing controller wiring and previews keep their source ABI.
struct FloatingBallView: View {
    @ObservedObject var service: UsageRefreshService
    let onRefresh: () -> Void
    let onSettings: () -> Void
    let onHide: () -> Void
    let onQuit: () -> Void

    @AppStorage("floatingBallSize") private var panelSizeRaw = FloatingPanelSize.standard.rawValue
    @State private var isRefreshRailHovering = false

    private var panelSize: FloatingPanelSize {
        FloatingPanelSize(rawValue: panelSizeRaw) ?? .standard
    }

    private var cardSize: CGSize { panelSize.cardSize }

    private var state: UsageDisplayState {
        UsageDisplayState.resolve(snapshot: service.snapshot, error: service.error)
    }

    private var isDataStale: Bool {
        if case .data(_, let isStale) = state { return isStale }
        return false
    }

    var body: some View {
        HStack(spacing: 0) {
            refreshRail

            Divider()
                .padding(.vertical, 9)

            content
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .background(
            RoundedRectangle(
                cornerRadius: FloatingPanelAppearance.cornerRadius,
                style: .continuous
            )
            .fill(.regularMaterial)
            .shadow(
                color: Color.black.opacity(FloatingPanelAppearance.shadowOpacity),
                radius: FloatingPanelAppearance.shadowRadius,
                x: FloatingPanelAppearance.shadowOffset.width,
                y: FloatingPanelAppearance.shadowOffset.height
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: FloatingPanelAppearance.cornerRadius,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.54))
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: FloatingPanelAppearance.cornerRadius,
                    style: .continuous
                )
                .stroke(Color.black.opacity(0.10), lineWidth: 0.8)
            )
        )
        .padding(FloatingPanelLayout.shadowInset)
        .background(Color.clear)
        .preferredColorScheme(.light)
        .contextMenu {
            Button("刷新数据") { onRefresh() }
            Button("打开设置") { onSettings() }
            Button("隐藏悬浮窗") { onHide() }
            Divider()
            Button("退出应用") { onQuit() }
        }
    }

    private var refreshVisualState: FloatingRefreshVisualState {
        FloatingRefreshVisualState.resolve(
            isLoading: service.isLoading,
            isHovering: isRefreshRailHovering
        )
    }

    private var refreshRail: some View {
        Button(action: onRefresh) {
            ZStack(alignment: .topTrailing) {
                Group {
                    switch refreshVisualState {
                    case .logo:
                        CodexUsageLogoView(pointSize: panelSize == .standard ? 21 : 19)
                    case .refresh:
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    case .loading:
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .frame(width: 22, height: 22)

                if case .data(_, let isStale) = state, isStale {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                        .offset(x: 3, y: -3)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: 28)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(service.isLoading)
        .onHover { isRefreshRailHovering = $0 }
        .help(
            service.isLoading
                ? "正在刷新用量"
                : (isDataStale ? "数据可能已过期，点击刷新" : "刷新用量")
        )
        .accessibilityLabel(service.isLoading ? "正在刷新 Codex 用量" : "刷新 Codex 用量")
        .accessibilityValue(isDataStale ? "数据可能已过期" : "数据为最新")
        .accessibilityHint("获取最新的 5 小时和每周剩余额度")
        .animation(.easeOut(duration: 0.12), value: refreshVisualState)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("正在获取用量…")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .error(let error):
            let presentation = UsageErrorPresentation(error: error)
            HStack(spacing: 8) {
                Image(systemName: presentation.systemImageName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.title)
                        .font(.system(size: 12, weight: .semibold))
                    Text("点击菜单栏图标查看详情")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

        case .data(let snapshot, _):
            VStack(spacing: 0) {
                UsageQuotaRow(
                    presentation: UsageQuotaPresentation(
                        kind: .primary,
                        window: snapshot.primary
                    ),
                    window: snapshot.primary,
                    style: .compact
                )

                Divider()

                UsageQuotaRow(
                    presentation: UsageQuotaPresentation(
                        kind: .weekly,
                        window: snapshot.secondary
                    ),
                    window: snapshot.secondary,
                    style: .compact
                )
            }
        }
    }

}

#if DEBUG
#Preview("Floating panel") {
    FloatingBallView(
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
        onRefresh: {},
        onSettings: {},
        onHide: {},
        onQuit: {}
    )
}
#endif
