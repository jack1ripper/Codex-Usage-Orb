import AppKit
import SwiftUI

@MainActor
final class FloatingWindowController: NSObject, NSWindowDelegate {
    private let service: UsageRefreshService
    private var window: NSPanel?
    private var settingsWindow: NSWindow?
    private var settingsWindowDelegate: SettingsWindowDelegate?

    init(service: UsageRefreshService) {
        self.service = service
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var isFloatingPanelVisible: Bool {
        window != nil
    }

    private var currentPanelSize: FloatingPanelSize {
        let raw = UserDefaults.standard.string(forKey: "floatingBallSize")
            ?? FloatingPanelSize.standard.rawValue
        return FloatingPanelSize(rawValue: raw) ?? .standard
    }

    private var currentWindowSize: CGSize {
        FloatingPanelLayout.windowSize(for: currentPanelSize.cardSize)
    }

    func show() {
        if let window {
            window.orderFrontRegardless()
            return
        }

        let size = currentWindowSize
        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: size.width, height: size.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow
        panel.appearance = NSAppearance(named: .aqua)
        panel.delegate = self

        let contentView = FloatingBallView(
            service: service,
            onRefresh: { [weak service] in
                Task { await service?.refresh() }
            },
            onSettings: { [weak self] in
                self?.showSettings()
            },
            onHide: { [weak self] in
                self?.setFloatingPanelVisible(false)
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            }
        )
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView

        restorePosition(for: panel)

        window = panel
        panel.orderFrontRegardless()
    }

    func setFloatingPanelVisible(_ visible: Bool) {
        UserDefaults.standard.set(visible, forKey: FloatingPanelPreference.visibilityKey)

        if visible {
            show()
        } else {
            close()
        }
    }

    func applyVisibilityPreference() {
        if FloatingPanelPreference.isEnabled() {
            show()
        } else {
            close()
        }
    }

    func bringToFront() {
        setFloatingPanelVisible(true)
    }

    func refresh() {
        Task { await service.refresh() }
    }

    func close() {
        window?.close()
    }

    @objc private func userDefaultsDidChange(_ notification: Notification) {
        guard FloatingPanelPreference.isEnabled() else {
            close()
            return
        }

        guard let window else {
            show()
            return
        }

        let newSize = currentWindowSize
        guard window.frame.size != newSize else { return }

        let resized = FloatingPanelLayout.resizedFrameKeepingTopEdge(
            window.frame,
            newSize: newSize
        )
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? resized
        window.setFrame(clampedFrame(resized, to: visibleFrame), display: true, animate: true)
    }

    // MARK: - Settings window

    func showSettings() {
        if let settingsWindow {
            NSApplication.shared.activate(ignoringOtherApps: true)
            settingsWindow.makeKeyAndOrderFront(nil)
            return
        }

        let delegate = SettingsWindowDelegate(controller: self)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = NSHostingView(rootView: SettingsView(onSave: { [weak self] in
            self?.hideSettings()
        }))
        window.center()
        window.delegate = delegate
        settingsWindow = window
        settingsWindowDelegate = delegate

        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    fileprivate func settingsWindowShouldClose() {
        // Hide instead of closing so the LSUIElement app is never left with
        // zero windows, which can cause the system to terminate it.
        settingsWindow?.orderOut(nil)
    }

    fileprivate func settingsWindowDidClose() {
        settingsWindow = nil
        settingsWindowDelegate = nil
    }

    func hideSettings() {
        settingsWindow?.orderOut(nil)
    }

    // MARK: - NSWindowDelegate

    func windowDidMove(_ notification: Notification) {
        guard let window,
              notification.object as? NSWindow == window else { return }
        savePosition(of: window)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow == window else { return }
        window = nil
    }

    // MARK: - Position persistence

    private func savePosition(of window: NSWindow) {
        let origin = window.frame.origin
        UserDefaults.standard.set(Double(origin.x), forKey: "floatingBallX")
        UserDefaults.standard.set(Double(origin.y), forKey: "floatingBallY")
    }

    private func restorePosition(for window: NSWindow) {
        let defaultOrigin = NSPoint(x: 100, y: 100)
        let savedX = UserDefaults.standard.object(forKey: "floatingBallX") as? Double
        let savedY = UserDefaults.standard.object(forKey: "floatingBallY") as? Double
        let savedOrigin = NSPoint(
            x: savedX.map { CGFloat($0) } ?? defaultOrigin.x,
            y: savedY.map { CGFloat($0) } ?? defaultOrigin.y
        )

        var frame = window.frame
        frame.origin = savedOrigin

        let visibleFrame = FloatingPanelLayout.visibleFrame(
            containing: savedOrigin,
            candidates: NSScreen.screens.map(\.visibleFrame)
        ) ?? NSScreen.main?.visibleFrame ?? frame

        window.setFrame(clampedFrame(frame, to: visibleFrame), display: false)
    }

    private func clampedFrame(_ frame: CGRect, to visibleFrame: CGRect) -> CGRect {
        var result = frame
        result.origin.x = max(
            visibleFrame.minX,
            min(result.origin.x, visibleFrame.maxX - result.width)
        )
        result.origin.y = max(
            visibleFrame.minY,
            min(result.origin.y, visibleFrame.maxY - result.height)
        )
        return result
    }
}

@MainActor
private final class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    private weak var controller: FloatingWindowController?

    init(controller: FloatingWindowController) {
        self.controller = controller
        super.init()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        controller?.settingsWindowShouldClose()
        return false
    }

    func windowWillClose(_ notification: Notification) {
        controller?.settingsWindowDidClose()
    }
}
