import AppKit
import SwiftUI

enum StatusBarInteraction: Equatable {
    case togglePopover
    case contextMenu

    static func resolve(eventType: NSEvent.EventType?) -> StatusBarInteraction {
        eventType == .rightMouseUp ? .contextMenu : .togglePopover
    }
}

@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let windowController: FloatingWindowController
    private let service: UsageRefreshService

    init(windowController: FloatingWindowController, service: UsageRefreshService) {
        self.windowController = windowController
        self.service = service
        super.init()
    }

    func install() {
        configurePopover()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = item.button else { return }

        button.title = ""
        button.image = CodexUsageBrand.menuBarImage()
            ?? NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: nil)
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = "Codex 用量"
        button.setAccessibilityLabel("Codex 用量")
        button.target = self
        button.action = #selector(statusItemPressed(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        statusItem = item
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 400, height: 177)

        let rootView = UsagePopoverView(
            service: service,
            onSettings: { [weak self] in
                self?.showSettings()
            },
            onRefresh: { [weak service] in
                Task { await service?.refresh() }
            }
        )
        let hostingController = NSHostingController(rootView: rootView)
        hostingController.view.appearance = NSAppearance(named: .aqua)
        popover.contentViewController = hostingController
    }

    @objc private func statusItemPressed(_ sender: NSStatusBarButton) {
        switch StatusBarInteraction.resolve(eventType: NSApp.currentEvent?.type) {
        case .togglePopover:
            togglePopover(from: sender)
        case .contextMenu:
            showContextMenu(from: sender)
        }
    }

    private func togglePopover(from button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        }
    }

    private func showContextMenu(from button: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        popover.performClose(nil)
        NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: button)
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        let visibilityTitle = windowController.isFloatingPanelVisible
            ? "隐藏悬浮窗"
            : "显示悬浮窗"

        menu.addItem(menuItem(
            title: visibilityTitle,
            action: #selector(toggleFloatingPanel)
        ))
        menu.addItem(menuItem(
            title: "刷新数据",
            action: #selector(refresh),
            keyEquivalent: "r"
        ))
        menu.addItem(.separator())
        menu.addItem(menuItem(
            title: "打开设置…",
            action: #selector(showSettings),
            keyEquivalent: ","
        ))
        menu.addItem(.separator())
        menu.addItem(menuItem(
            title: "退出",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        return menu
    }

    private func menuItem(
        title: String,
        action: Selector,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: action,
            keyEquivalent: keyEquivalent
        )
        item.target = self
        return item
    }

    @objc private func toggleFloatingPanel() {
        windowController.setFloatingPanelVisible(!windowController.isFloatingPanelVisible)
    }

    @objc private func refresh() {
        Task { await service.refresh() }
    }

    @objc private func showSettings() {
        popover.performClose(nil)
        windowController.showSettings()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
