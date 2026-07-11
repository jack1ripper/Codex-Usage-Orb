# Liquid Sphere UI Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the dual-arc progress indicator with a clickable liquid-filled glass sphere, add a Standard/Small size setting, and always show the current window's reset countdown.

**Architecture:** Extract testable styling policy (`BallSize`, `UsageColorPolicy`) into `Models/BallStyle.swift`. Rebuild `FloatingBallView` as a single liquid sphere. Wire size preference from `SettingsView` through `AppStorage` to `FloatingWindowController`.

**Tech Stack:** Swift 6, SwiftUI, AppKit, XCTest.

---

### Task 1: Extract Testable Ball Style Policy

**Files:**
- Create: `Sources/Codex-Usage/Models/BallStyle.swift`
- Test: `Tests/Codex-UsageTests/BallStyleTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import Codex_Usage

final class BallStyleTests: XCTestCase {
    func testBallSizeMapping() {
        XCTAssertEqual(BallSize.standard.pointSize, 180)
        XCTAssertEqual(BallSize.small.pointSize, 130)
    }

    func testColorPolicyThresholds() {
        XCTAssertEqual(UsageColorPolicy.color(for: 0.30), .usageBlue)
        XCTAssertEqual(UsageColorPolicy.color(for: 0.29), .usageWarning)
        XCTAssertEqual(UsageColorPolicy.color(for: 0.10), .usageWarning)
        XCTAssertEqual(UsageColorPolicy.color(for: 0.09), .usageCritical)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter BallStyleTests`
Expected: FAIL — `BallSize` and `UsageColorPolicy` not found.

- [ ] **Step 3: Write minimal implementation**

Create `Sources/Codex-Usage/Models/BallStyle.swift`:

```swift
import SwiftUI

enum BallSize: String, CaseIterable, Identifiable {
    case standard = "standard"
    case small = "small"

    var id: String { rawValue }

    var pointSize: CGFloat {
        switch self {
        case .standard: return 180
        case .small: return 130
        }
    }

    var localizedName: String {
        switch self {
        case .standard: return "标准"
        case .small: return "小"
        }
    }
}

enum UsageColorPolicy {
    static func color(for remainingRatio: Double) -> Color {
        switch remainingRatio {
        case ..<0.10: return .usageCritical
        case 0.10..<0.30: return .usageWarning
        default: return .usageBlue
        }
    }
}

extension Color {
    static let usageBlue = Color(red: 0.29, green: 0.56, blue: 0.99)
    static let usageWarning = Color(red: 0.96, green: 0.59, blue: 0.15)
    static let usageCritical = Color(red: 0.95, green: 0.28, blue: 0.28)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter BallStyleTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/Codex-Usage/Models/BallStyle.swift Tests/Codex-UsageTests/BallStyleTests.swift
git commit -m "feat: add BallSize and UsageColorPolicy"
```

---

### Task 2: Add Ball Size Setting

**Files:**
- Modify: `Sources/Codex-Usage/Views/SettingsView.swift`

- [ ] **Step 1: Add `@AppStorage` for ball size**

Insert after existing `@AppStorage` declarations:

```swift
@AppStorage("floatingBallSize") private var ballSizeRaw: String = BallSize.standard.rawValue
```

- [ ] **Step 2: Add size picker section**

Add a new `Section` to the `Form`:

```swift
Section {
    Picker("悬浮球大小", selection: $ballSizeRaw) {
        ForEach(BallSize.allCases) { size in
            Text(size.localizedName).tag(size.rawValue)
        }
    }
    .pickerStyle(.segmented)
} header: {
    Text("外观")
        .font(.headline)
        .foregroundStyle(.primary)
        .textCase(nil)
}
```

- [ ] **Step 3: Verify build**

Run: `swift build`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Sources/Codex-Usage/Views/SettingsView.swift
git commit -m "feat: add floating ball size setting"
```

---

### Task 3: Rebuild FloatingBallView as Liquid Sphere

**Files:**
- Modify: `Sources/Codex-Usage/Views/FloatingBallView.swift`

- [ ] **Step 1: Add display mode state and helpers**

Add enum and state inside `FloatingBallView`:

```swift
private enum DisplayMode {
    case primary
    case secondary

    var label: String {
        switch self {
        case .primary: return "5小时剩余"
        case .secondary: return "本周剩余"
        }
    }
}

@State private var displayMode: DisplayMode = .primary
```

Add helpers:

```swift
private var activeWindow: UsageWindow? {
    switch displayMode {
    case .primary: return primaryWindow
    case .secondary: return secondaryWindow
    }
}

private var activeColor: Color {
    UsageColorPolicy.color(for: activeWindow?.remainingRatio ?? 1)
}
```

- [ ] **Step 2: Replace gauge body with liquid sphere**

Replace `gaugeBody` and `gaugeArcs` with:

```swift
private var gaugeBody: some View {
    ZStack {
        liquidFill

        VStack(spacing: 0) {
            Spacer().frame(height: ballSize.pointSize * 0.22)

            Text(percentString(for: activeWindow))
                .font(.system(size: ballSize.pointSize * 0.18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                .contentTransition(.numericText())

            Text(displayMode.label)
                .font(.system(size: ballSize.pointSize * 0.055, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .padding(.top, 2)

            Spacer().frame(height: ballSize.pointSize * 0.05)

            Text(resetText)
                .font(.system(size: ballSize.pointSize * 0.075, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)

            Text("后重置")
                .font(.system(size: ballSize.pointSize * 0.05, weight: .medium))
                .foregroundColor(.white.opacity(0.75))

            Spacer().frame(height: ballSize.pointSize * 0.22)
        }
    }
}
```

- [ ] **Step 3: Implement liquid wave shape**

Add:

```swift
@AppStorage("floatingBallSize") private var ballSizeRaw: String = BallSize.standard.rawValue

private var ballSize: BallSize {
    BallSize(rawValue: ballSizeRaw) ?? .standard
}

private var liquidFill: some View {
    let ratio = max(0.02, activeWindow?.remainingRatio ?? 1)
    return GeometryReader { geo in
        let size = geo.size.width
        LiquidWaveShape(
            ratio: ratio,
            phase: wavePhase,
            amplitude: size * 0.025
        )
        .fill(activeColor)
        .clipShape(Circle())
    }
}

private struct LiquidWaveShape: Shape {
    let ratio: Double
    let phase: Double
    let amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let waterHeight = height * CGFloat(ratio)
        let baseY = height - waterHeight
        var path = Path()
        path.move(to: CGPoint(x: 0, y: height))
        for x in stride(from: 0, through: width, by: 1) {
            let normalizedX = Double(x) / Double(width) * 2 * .pi
            let y = baseY + CGFloat(sin(normalizedX + phase)) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}
```

- [ ] **Step 4: Add wave animation and tap gesture**

Add state for phase:

```swift
@State private var wavePhase: Double = 0
```

Add animation in `.onReceive(timer)`:

```swift
.onReceive(timer) { _ in
    now = Date()
    withAnimation(.linear(duration: 0.1)) {
        wavePhase += 0.15
    }
}
```

Add tap gesture to the main `ZStack`:

```swift
.contentShape(Circle())
.onTapGesture {
    displayMode = (displayMode == .primary) ? .secondary : .primary
}
```

- [ ] **Step 5: Update frame and countdown**

Replace hardcoded `.frame(width: 180, height: 180)` with:

```swift
.frame(width: ballSize.pointSize, height: ballSize.pointSize)
```

Replace `countdownText` logic with:

```swift
private var resetText: String {
    guard let resetAt = activeWindow?.resetsAt, resetAt > now else { return "—" }
    let totalSeconds = resetAt.timeIntervalSince(now)
    let hours = Int(totalSeconds) / 3600
    let minutes = (Int(totalSeconds) % 3600) / 60
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}
```

Remove old `countdownPill`, `countdownText`, `countdownColor`, `gaugeArcs`, `semicircleArc`, `primaryColor`, `secondaryColor`, and `colorForRatio`.

- [ ] **Step 6: Update preview**

Update `#Preview` to show the new liquid sphere with the same mock data.

- [ ] **Step 7: Verify build**

Run: `swift build`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add Sources/Codex-Usage/Views/FloatingBallView.swift
git commit -m "feat: liquid sphere UI with click toggle"
```

---

### Task 4: Make FloatingWindowController Respond to Size Changes

**Files:**
- Modify: `Sources/Codex-Usage/Windows/FloatingWindowController.swift`

- [ ] **Step 1: Read ball size when creating window**

Use `UserDefaults` to read size when computing the initial content rect:

```swift
private var currentBallSize: CGFloat {
    let raw = UserDefaults.standard.string(forKey: "floatingBallSize") ?? BallSize.standard.rawValue
    return BallSize(rawValue: raw)?.pointSize ?? 180
}
```

Update `show()` to use `currentBallSize` for the panel frame.

- [ ] **Step 2: Observe size changes**

Add a `NotificationCenter` observer in `show()`:

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(ballSizeDidChange),
    name: UserDefaults.didChangeNotification,
    object: nil
)
```

Implement:

```swift
@objc private func ballSizeDidChange() {
    guard let window else { return }
    let size = currentBallSize
    var frame = window.frame
    frame.origin.y += frame.height - size
    frame.size.width = size
    frame.size.height = size
    window.setFrame(frame, display: true, animate: true)
}
```

- [ ] **Step 3: Verify build**

Run: `swift build`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Sources/Codex-Usage/Windows/FloatingWindowController.swift
git commit -m "feat: resize floating panel when ball size setting changes"
```

---

### Task 5: Run All Tests and Build Release

- [ ] **Step 1: Run full test suite**

Run: `swift test`
Expected: PASS.

- [ ] **Step 2: Build release bundle**

Run: `./Scripts/build_app.sh`
Expected: exit 0, `Codex-Usage.app` created.

- [ ] **Step 3: Install to /Applications**

Run: `./Scripts/install.sh`
Expected: app copied to `/Applications/Codex-Usage.app`.

- [ ] **Step 4: Commit any remaining changes**

```bash
git add docs/superpowers/specs/2026-07-10-liquid-sphere-ui-refactor-design.md
git add docs/superpowers/plans/2026-07-10-liquid-sphere-ui-refactor.md
git commit -m "docs: add liquid sphere refactor design and plan"
```
