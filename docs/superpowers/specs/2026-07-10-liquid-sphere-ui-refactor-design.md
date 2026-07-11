# Liquid Sphere UI Refactor Design

## Goal
Replace the current dual-arc progress indicator inside the floating ball with a single glass-like liquid-filled sphere. The sphere shows one usage window at a time, toggled by left-click, with the corresponding reset countdown always visible inside.

## Visual Design

### Sphere Shell
- Circular `ultraThinMaterial` base.
- Inner white overlay at low opacity (`0.08`) for frosted glass feel.
- Soft drop shadow for floating depth.
- Subtle inner highlight arc at top-left to mimic glass reflection.
- Thin white stroke around the edge (`0.25` opacity).

### Liquid Fill
- A wave-shaped `Path` clipped to the circle.
- Fill height equals the current window's `remainingRatio` (0–1).
- Gentle horizontal wave animation using `phase` animating continuously.
- Liquid color transitions by threshold:
  - `≥ 30%`: blue `#4A90FF`
  - `10% – 30%`: warning orange `#F5A623`
  - `< 10%`: red `#F24C4C`
- When empty (`remainingRatio ≈ 0`), the ball still shows a sliver of red liquid so it doesn't disappear entirely.

### Typography
- Large centered percentage (e.g. `42%`) using rounded bold font.
- Smaller label below: `"5小时剩余"` or `"本周剩余"`.
- Reset countdown below the label (e.g. `"2h 15m 后重置"`).

## Interaction

### Left-Click Toggle
- A left mouse click anywhere on the ball toggles the displayed window between the 5-hour window and the weekly window.
- State is local to the view (`@State private var displayMode: DisplayMode`).
- Does not affect data refresh or settings.

### Context Menu
- Existing right-click context menu remains: refresh, settings, quit.

## Settings

### Ball Size
- New section in `SettingsView`: `"悬浮球大小"`.
- Two options:
  - `"标准"` — 180 pt diameter (current default).
  - `"小"` — 130 pt diameter.
- Persisted via `@AppStorage("floatingBallSize")` as a string tag.
- `FloatingWindowController` reads the preference and updates the panel size.

## Data Mapping

### Display Modes
- `.primary` — 5-hour window (`snapshot.primary`).
- `.secondary` — weekly window (`snapshot.secondary`).

### Color Thresholds
Only the currently displayed window's remaining ratio determines the liquid color. No separate alert/notification is fired; color change is the only visual cue.

- `ratio >= 0.30`: blue
- `0.10 <= ratio < 0.30`: warning orange
- `ratio < 0.10`: red

### Reset Time
- Countdown is computed from `window.resetsAt` relative to `Date()`.
- Format:
  - `> 1 hour`: `"Xh Ym"`
  - `< 1 hour`: `"Xm"`
  - expired/unknown: `"—"`

## Files to Modify
- `Sources/Codex-Usage/Views/FloatingBallView.swift` — new liquid sphere UI and toggle logic.
- `Sources/Codex-Usage/Views/SettingsView.swift` — add ball size picker.
- `Sources/Codex-Usage/Windows/FloatingWindowController.swift` — dynamic window sizing.

## Files to Create
- `Sources/Codex-Usage/Models/BallStyle.swift` — `BallSize` enum + `UsageColorPolicy` for testable thresholds.
- `Tests/Codex-UsageTests/BallStyleTests.swift` — tests for color policy and size mapping.

## Testing
- Unit-test color thresholds at boundaries (30%, 10%).
- Unit-test `BallSize` raw value mapping and `pointSize`.
- Build release app and install to `/Applications` for manual visual verification.
