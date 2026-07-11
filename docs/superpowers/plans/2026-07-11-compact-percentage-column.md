# Compact Percentage Column Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display `100%` completely in both compact quota rows without changing either floating-panel size.

**Architecture:** Store the compact percentage-column width in one shared layout constant. Verify it against the matching AppKit font measurement, then consume it from the SwiftUI row so both progress bars remain aligned.

**Tech Stack:** Swift 6, SwiftUI, AppKit, XCTest, Swift Package Manager.

## Global Constraints

- Keep standard and compact cards at 220×84 pt and 200×84 pt.
- Keep the 15 pt semibold monospaced-digit percentage style.
- Preserve row spacing, labels, reset text, shadow, and interactions.
- Do not add dependencies or unrelated refactors.

---

### Task 1: Guarantee the Compact Percentage Column Fits `100%`

**Files:**
- Modify: `Tests/Codex-UsageTests/BallStyleTests.swift`
- Modify: `Sources/Codex-Usage/Models/BallStyle.swift`
- Modify: `Sources/Codex-Usage/Views/UsageQuotaViews.swift`

**Interfaces:**
- Produces: `UsageQuotaRowLayout.compactPercentWidth: CGFloat`
- Consumes: that width from `UsageQuotaRow.compactRow`

- [x] **Step 1: Write the failing test**

Add `import AppKit` and:

```swift
func testCompactPercentageColumnFitsOneHundredPercent() {
    let font = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
    let requiredWidth = ceil(("100%" as NSString).size(
        withAttributes: [.font: font]
    ).width)

    XCTAssertGreaterThanOrEqual(
        UsageQuotaRowLayout.compactPercentWidth,
        requiredWidth
    )
}
```

- [x] **Step 2: Verify RED**

Run `swift test --filter BallStyleTests`.

Expected: compilation fails because `UsageQuotaRowLayout` does not exist.

- [x] **Step 3: Add the minimal layout constant**

Add to `BallStyle.swift`:

```swift
enum UsageQuotaRowLayout {
    static let compactPercentWidth: CGFloat = 46
}
```

Replace the compact row's literal width with:

```swift
.frame(width: UsageQuotaRowLayout.compactPercentWidth, alignment: .leading)
```

- [x] **Step 4: Verify GREEN**

Run `swift test --filter BallStyleTests`.

Expected: every `BallStyleTests` test passes.

- [x] **Step 5: Verify the application**

Run:

```bash
swift build
swift test
./Scripts/build_app.sh
```

Then quit, reinstall, launch, and capture the live panel. Confirm both rows show `100%` without ellipsis and their progress bars remain aligned.
