import SwiftUI
import AppKit

@MainActor
final class FloatingWindowController: NSObject, NSWindowDelegate {
    private let service: UsageRefreshService
    private var window: NSPanel?

    init(service: UsageRefreshService) {
        self.service = service
        super.init()
    }

    func show() {
        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 140, height: 140),
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
        panel.delegate = self

        let contentView = FloatingBallView(
            service: service,
            onRefresh: { [weak service] in
                Task { await service?.refresh() }
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            }
        )
        panel.contentView = NSHostingView(rootView: contentView)

        restorePosition(for: panel)

        self.window = panel
        panel.orderFrontRegardless()
        service.start()
    }

    // MARK: - NSWindowDelegate

    func windowDidMove(_ notification: Notification) {
        guard let window = window else { return }
        savePosition(of: window)
    }

    // MARK: - Position persistence

    private func savePosition(of window: NSWindow) {
        let origin = window.frame.origin
        UserDefaults.standard.set(Double(origin.x), forKey: "floatingBallX")
        UserDefaults.standard.set(Double(origin.y), forKey: "floatingBallY")
    }

    private func restorePosition(for window: NSWindow) {
        let defaultOrigin = NSPoint(x: 100, y: 100)
        let savedX = UserDefaults.standard.double(forKey: "floatingBallX")
        let savedY = UserDefaults.standard.double(forKey: "floatingBallY")
        let savedOrigin = NSPoint(x: savedX == 0 ? defaultOrigin.x : savedX,
                                  y: savedY == 0 ? defaultOrigin.y : savedY)

        let screen = window.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(origin: .zero, size: window.frame.size)

        let clampedOrigin = NSPoint(
            x: max(visibleFrame.minX, min(savedOrigin.x, visibleFrame.maxX - window.frame.width)),
            y: max(visibleFrame.minY, min(savedOrigin.y, visibleFrame.maxY - window.frame.height))
        )

        window.setFrameOrigin(clampedOrigin)
    }
}
