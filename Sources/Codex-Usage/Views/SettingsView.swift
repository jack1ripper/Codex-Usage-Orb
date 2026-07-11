import SwiftUI
import AppKit
import ServiceManagement
import UniformTypeIdentifiers

struct SettingsView: View {
    let onSave: () -> Void

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

    var body: some View {
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
                    TextField("/usr/local/bin/codex", text: $codexCLIPath)
                        .textFieldStyle(.roundedBorder)

                    Button("浏览…") {
                        browseForCodexCLI()
                    }
                    .controlSize(.regular)
                }

                Text("指定 Codex CLI 的安装路径，留空则自动检测")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

            Section {
                Button {
                    applySettings()
                    onSave()
                } label: {
                    Text("保存设置")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .listRowBackground(Color.clear)
        }
        .formStyle(.grouped)
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 400)
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

    private func applySettings() {
        // Ensure the stored interval is clamped.
        refreshInterval = min(3600, max(60, refreshInterval))

        // Notify the refresh service to pick up the new interval.
        NotificationCenter.default.post(
            name: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )
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
    SettingsView(onSave: {})
}
#endif
