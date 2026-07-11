# Menu Bar Popover and Floating Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship an image-only menu bar item, a light two-row Codex quota popover, and an optional compact two-row desktop panel using the generated logo.

**Architecture:** `AppDelegate` owns one long-lived `UsageRefreshService`. A pure presentation model formats both quota windows for shared SwiftUI rows. `StatusBarController` owns the square status item and transient popover, while `FloatingWindowController` owns only the optional desktop panel and Settings window.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Swift Package Manager resources, XCTest.

## Global Constraints

- Target macOS 14 or later with no new third-party dependencies.
- The status item is logo-only and uses `NSStatusItem.squareLength`.
- The popover and desktop panel use a forced light appearance.
- Normal primary progress is blue; normal weekly progress is violet; below 30% is orange; below 10% is red.
- Preserve all existing user changes in the dirty working tree; do not create commits automatically.
- Keep the existing `floatingBallSize`, `floatingBallX`, and `floatingBallY` preference keys for upgrade compatibility.

---

### Task 1: Package and Load the Generated Logo

**Files:**
- Modify: `Package.swift`
- Create: `Sources/Codex-Usage/Resources/CodexUsageLogo.png`
- Create: `Sources/Codex-Usage/Models/CodexUsageBrand.swift`
- Modify: `Scripts/build_app.sh`
- Test: `Tests/Codex-UsageTests/CodexUsageBrandTests.swift`

**Interfaces:**
- Produces: `CodexUsageBrand.menuBarImage(pointSize:) -> NSImage?`

- [ ] Write `CodexUsageBrandTests` asserting the resource loads, is 18×18 pt by default, and is marked as a template image.
- [ ] Run `swift test --filter CodexUsageBrandTests` and confirm it fails because `CodexUsageBrand` does not exist.
- [ ] Add `resources: [.process("Resources")]` to the executable target.
- [ ] Implement:

```swift
import AppKit

enum CodexUsageBrand {
    @MainActor
    static func menuBarImage(pointSize: NSSize = NSSize(width: 18, height: 18)) -> NSImage? {
        guard let url = Bundle.module.url(forResource: "CodexUsageLogo", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.size = pointSize
        image.isTemplate = true
        return image
    }
}
```

- [ ] Update `build_app.sh` to fail when `.build/release/Codex-Usage_Codex-Usage.bundle` is missing and copy that whole bundle into `.app/Contents/Resources` before signing. Load it from `Bundle.main.resourceURL` in packaged apps and fall back to `Bundle.module` in SwiftPM development.
- [ ] Run the focused test and inspect `CodexUsageLogo.png` for 128×128 dimensions, alpha, and transparent corners.

### Task 2: Build a Testable Quota Presentation Model

**Files:**
- Create: `Sources/Codex-Usage/Models/UsageQuotaPresentation.swift`
- Modify: `Sources/Codex-Usage/Models/BallStyle.swift`
- Test: `Tests/Codex-UsageTests/UsageQuotaPresentationTests.swift`
- Modify: `Tests/Codex-UsageTests/BallStyleTests.swift`

**Interfaces:**
- Produces: `UsageQuotaKind.primary`, `UsageQuotaKind.weekly`
- Produces: `UsageQuotaPresentation(kind:window:now:calendar:)`
- Produces: `title`, `compactLabel`, `remainingText`, `fullResetText`, `compactResetText`, and `accessibilityText`
- Produces: `FloatingPanelSize.cardSize`

- [ ] Write failing tests for `97%`, primary `将于 13:32 重置`, weekly `将于 7 月 18 日重置`, compact reset strings, expired/nil reset handling, and VoiceOver copy using a fixed Shanghai calendar.
- [ ] Update the style tests to expect standard `220×84` and compact `200×76` card sizes plus blue primary/violet weekly normal colors.
- [ ] Run both focused test classes and confirm failures are caused by the missing presentation and new size/color APIs.
- [ ] Implement the kind and immutable presentation values. Date formatters must use the injected calendar time zone and `zh_CN` locale.
- [ ] Rename the size type to `FloatingPanelSize` while preserving raw values `standard` and `small`; expose localized names `标准` and `紧凑`.
- [ ] Add `Color.usageWeekly` and `UsageColorPolicy.color(for:kind:remainingRatio:)`, preserving the current threshold boundaries.
- [ ] Run the focused tests until green, then run all model tests.

### Task 3: Create Shared Light Quota Rows and Popover

**Files:**
- Create: `Sources/Codex-Usage/Views/UsageQuotaViews.swift`
- Create: `Sources/Codex-Usage/Views/UsagePopoverView.swift`

**Interfaces:**
- Consumes: `UsageQuotaPresentation`, `UsageColorPolicy`, `CodexUsageBrand`
- Produces: `UsageQuotaRow(presentation:window:style:)`
- Produces: `UsagePopoverView(service:onSettings:onRefresh:)`

- [ ] Implement a six-point rounded `UsageProgressBar` whose fill width clamps to `0...1` and whose normal color depends on quota kind.
- [ ] Implement `.detail` rows with full title/reset copy, a 96–112 pt progress bar, and trailing `剩余 N%`.
- [ ] Add complete accessibility labels to each row and hide duplicate child elements from VoiceOver.
- [ ] Build the popover header with the generated logo, `Codex 用量`, a stale/loading indicator when needed, and a gear button.
- [ ] Keep successful stale snapshots visible; add fixed-size loading and hard-error states only when no snapshot exists.
- [ ] Force `.preferredColorScheme(.light)` and set the root frame to approximately `400×190`.
- [ ] Add SwiftUI previews for success, low quota, stale snapshot, loading, and hard error.
- [ ] Run `swift build` and resolve all compiler diagnostics before continuing.

### Task 4: Convert the Status Item to Logo-Only Popover Interaction

**Files:**
- Modify: `Sources/Codex-Usage/Windows/StatusBarController.swift`
- Modify: `Sources/Codex-Usage/App/AppDelegate.swift`

**Interfaces:**
- Consumes: `CodexUsageBrand.menuBarImage`, `UsagePopoverView`, `FloatingWindowController`
- Produces: left-click popover toggle and right-click operational context menu

- [ ] Change the status item to `NSStatusItem.squareLength`, clear its title, install the 18×18 template image, set proportional scaling, tooltip, and accessibility label.
- [ ] Strongly own an `NSPopover` with `.transient` behavior and an `NSHostingController` containing `UsagePopoverView`.
- [ ] Send both left and right mouse-up events to one action: left toggles the popover; right opens a context menu containing show/hide panel, refresh, settings, and quit.
- [ ] Close the popover before opening Settings and explicitly activate the accessory application so the Settings window becomes key.
- [ ] Move service ownership/start/stop into `AppDelegate`; remove panel-dependent service lifecycle behavior.
- [ ] Build and manually smoke-test repeated popover toggling, Settings activation, right-click commands, and background refresh after the panel is closed.

### Task 5: Replace the Liquid Ball with the Compact Two-Row Panel

**Files:**
- Replace contents: `Sources/Codex-Usage/Views/FloatingBallView.swift`
- Modify: `Sources/Codex-Usage/Windows/FloatingWindowController.swift`
- Modify: `Sources/Codex-Usage/Views/SettingsView.swift`

**Interfaces:**
- Consumes: shared compact quota rows, `FloatingPanelSize.cardSize`
- Produces: `setFloatingPanelVisible(_:)` and `isFloatingPanelVisible`

- [ ] Remove display switching, liquid shapes, and both UI timers.
- [ ] Build the 220×84 standard or 200×84 compact light panel: narrow logo rail, vertical divider, two equal compact rows, one horizontal divider, blue/violet progress fills, and abbreviated reset values.
- [ ] Keep the existing context menu and add `隐藏悬浮窗`; do not add a whole-panel tap gesture that competes with dragging.
- [ ] Convert window sizing from one `CGFloat` to `CGSize`, use a 12 pt shadow inset, anchor the top edge during size changes, and clamp the resized rectangle to its current screen.
- [ ] Remove service start/stop from panel show/close, remove notification observers when replaced or deinitialized, and use `.floating` with `.canJoinAllSpaces` and `.fullScreenAuxiliary`.
- [ ] Add Settings toggle `显示桌面悬浮窗`, rename size copy to `悬浮窗大小`, and keep standard/compact choices.
- [ ] Ensure a missing visibility key defaults to enabled; preference changes show or hide the panel without affecting refresh.
- [ ] Run focused layout/style tests and then the full test suite.

### Task 6: Package and Verify the Application

**Files:**
- Modify: `README.md`
- Verify: `Codex-Usage.app`

**Interfaces:**
- Consumes: all previous tasks
- Produces: a signed local app bundle containing its logo resource bundle

- [ ] Update README feature wording from floating ball to logo-only menu item, popover, and optional desktop panel.
- [ ] Run `swift test` and confirm zero failures.
- [ ] Run `swift build -c release` and `./Scripts/build_app.sh`.
- [ ] Verify `Codex-Usage.app/Contents/Resources/Codex-Usage_Codex-Usage.bundle/CodexUsageLogo.png` exists.
- [ ] Run `codesign --verify --deep --strict --verbose=2 Codex-Usage.app` and confirm success.
- [ ] Launch the built app, visually inspect the menu bar width, popover, floating panel, and Settings, then confirm both quota rows remain legible at their actual sizes.
- [ ] Review `git diff` to ensure unrelated user changes were preserved and no generated temporary files are included.
