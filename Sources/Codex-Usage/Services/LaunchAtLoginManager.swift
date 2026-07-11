import Foundation
import ServiceManagement

/// Manages registering/unregistering the current app to launch at login.
@MainActor
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    private let defaultsKey = "launchAtLogin"

    /// Whether the user wants the app to launch at login.
    @Published private(set) var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: defaultsKey)
        }
    }

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: defaultsKey)
    }

    /// Toggles the launch-at-login preference and syncs it with the system.
    /// - Returns: `true` if the preference was applied successfully.
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            isEnabled = enabled
            return true
        } catch {
            // Revert the published value to reflect the actual system state.
            isEnabled = (service.status == .enabled)
            return false
        }
    }

    /// Refreshes the published state from the system service status.
    func sync() {
        isEnabled = (SMAppService.mainApp.status == .enabled)
    }
}
