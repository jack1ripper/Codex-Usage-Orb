import SwiftUI
import AppKit
import ServiceManagement
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval: Double = 300
    @AppStorage("codexCLIPath") private var codexCLIPath: String = ""
    @AppStorage("floatingBallSize") private var panelSizeRaw: String = FloatingPanelSize.standard.rawValue
    @AppStorage(FloatingPanelPreference.visibilityKey) private var showFloatingPanel = true
    @StateObject private var launchManager = LaunchAtLoginManager()
    @State private var showLaunchLoginError = false

    private let intervalOptions: [Double] = [60, 300, 600, 900, 1800, 3600]

    private var refreshIntervalBinding: Binding<Double> {
        Binding<Double>(
            get: { min(3600, max(60, refreshInterval)) },
            set: { refreshInterval = min(3600, max(60, $0)) }
        )
    }

    private var cliPathStatus: CodexCLIPathStatus {
        let configuredPath = codexCLIPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let autoDetectedPath = configuredPath.isEmpty
            ? DefaultCodexCLIExecutor().resolveCodexExecutable()
            : nil
        return CodexCLIPathStatus.resolve(
            configuredPath: configuredPath,
            autoDetectedPath: autoDetectedPath
        )
    }

    var body: some View {
        let pathStatus = cliPathStatus

        Form {
            Section {
                Picker("自动刷新间隔", selection: refreshIntervalBinding) {
                    ForEach(intervalOptions, id: \.self) { seconds in
                        Text(intervalLabel(for: seconds))
                            .tag(seconds)
                    }
                }
                .pickerStyle(.menu)

                Text("设置自动刷新用量数据的时间间隔")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("通用")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }

            Section {
                HStack(spacing: 8) {
                    TextField(
                        "",
                        text: $codexCLIPath,
                        prompt: Text("/usr/local/bin/codex")
                    )
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .layoutPriority(1)

                    Button("浏览…") {
                        browseForCodexCLI()
                    }
                    .controlSize(.regular)
                    .fixedSize()
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: pathStatus.systemImageName)
                        .accessibilityHidden(true)

                    Text(pathStatus.message)
                        .textSelection(.enabled)
                }
                    .font(.caption)
                    .foregroundStyle(pathStatusColor(for: pathStatus))
                    .accessibilityElement(children: .combine)
            } header: {
                Text("Codex CLI 路径")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }

            Section {
                Toggle("显示桌面悬浮窗", isOn: $showFloatingPanel)

                Picker("悬浮窗大小", selection: $panelSizeRaw) {
                    ForEach(FloatingPanelSize.allCases) { size in
                        Text(size.localizedName).tag(size.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!showFloatingPanel)

                Text("悬浮窗会同时显示 5 小时和每周剩余额度")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("外观")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }

            Section {
                Toggle(isOn: launchAtLoginBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("开机启动")
                            .font(.body)
                        Text("系统启动时自动运行")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("启动设置")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }

        }
        .formStyle(.grouped)
        .frame(minWidth: 400, idealWidth: 420, maxWidth: 440)
        .padding()
        .alert("无法设置开机启动", isPresented: $showLaunchLoginError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("请前往“系统设置”>“通用”>“登录项”手动允许本应用。")
        }
        .onAppear {
            launchManager.sync()
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding<Bool>(
            get: { launchManager.isEnabled },
            set: { enabled in
                let success = launchManager.setEnabled(enabled)
                if !success {
                    showLaunchLoginError = true
                }
            }
        )
    }

    private func pathStatusColor(for status: CodexCLIPathStatus) -> Color {
        status.isError ? .red : Color(nsColor: .secondaryLabelColor)
    }

    private func intervalLabel(for seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes) 分钟"
    }

    private func browseForCodexCLI() {
        let panel = NSOpenPanel()
        panel.title = "选择 Codex CLI"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.unixExecutable]

        guard panel.runModal() == .OK,
              let url = panel.url else { return }

        codexCLIPath = url.path
    }
}

#if DEBUG
#Preview {
    SettingsView()
}
#endif
