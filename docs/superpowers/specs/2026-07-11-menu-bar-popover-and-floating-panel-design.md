# Menu Bar Popover and Floating Usage Panel Design

## Goal

Replace the wide text status item and circular liquid ball with a compact,
image-only menu bar entry, a light two-row quota popover, and an optional light
two-row desktop panel. Both quota windows must be visible at the same time.

## Brand Mark

- Use the generated `CodexUsageLogo.png` mark: a rounded C-shaped meter with two
  horizontal quota strokes.
- The menu bar uses the mark as an 18×18 pt macOS template image, so the system
  supplies light, dark, pressed, and disabled colors.
- The status item uses `NSStatusItem.squareLength` and contains no title text.
- The same mark appears in the popover header and in the desktop panel's drag
  rail.

## Menu Bar Interaction

- Left-click toggles a transient `NSPopover`.
- Right-click opens the existing operational menu: show/hide desktop panel,
  refresh, settings, and quit.
- The popover is forced to the light Aqua appearance.
- The popover header contains the logo, `Codex 用量`, stale/loading feedback when
  applicable, and a settings gear.

## Popover Content

The popover shows two equal rows. Each row contains full Codex wording on the
left, a colored progress bar in the middle, and remaining percentage on the
right.

Primary row:

- `5 小时使用限制`
- `将于 13:32 重置` using the actual local reset time
- `剩余 97%` using the actual remaining percentage

Weekly row:

- `每周使用限额`
- `将于 7月18日 重置` using the actual local reset date
- `剩余 99%` using the actual remaining percentage

At normal levels the 5-hour bar is blue and the weekly bar is violet. Both turn
orange below 30% and red below 10%. Color is never the only status cue.

## Persistent Desktop Panel

- Replace the circle with a 220×84 pt standard or 200×84 pt compact rounded
  light panel.
- A narrow left rail shows the logo and acts as the visual drag affordance.
- Two equal rows show `5h` / `周`, percentage, progress bar, and abbreviated
  absolute reset (`13:32` / `7/18`).
- The panel has no title, settings button, wave animation, countdown timer, or
  click-to-switch behavior.
- Keep drag-to-move, saved position, right-click menu, and all-space visibility.
- The desktop panel is enabled by default and can be disabled in Settings or
  from the status item's right-click menu.

## Data and Lifecycle

- `UsageRefreshService` is owned and started by `AppDelegate`; closing or hiding
  the desktop panel must not stop menu-bar data refresh.
- The popover and desktop panel observe the same service instance.
- A saved snapshot remains visible after a refresh error and gains a subtle
  stale indicator. Without any snapshot, show a fixed-size loading or actionable
  error state.
- Missing or expired reset times use `重置时间未知` in the full popover and `—`
  in the compact panel.

## Accessibility and Energy

- The menu bar image has an accessibility label and tooltip.
- Each quota row exposes a complete VoiceOver sentence with quota name,
  percentage, and reset information.
- Visible numbers use tabular digits and readable system fonts.
- Removing the 20 fps liquid timer and one-second countdown timer eliminates
  continuous animation wakeups.

## Packaging

- Declare `Sources/Codex-Usage/Resources` as a SwiftPM processed resource.
- Load the packaged PNG from `Bundle.main.resourceURL` and fall back to
  `Bundle.module` during SwiftPM development and tests.
- Copy the generated SwiftPM resource bundle into `Contents/Resources` in the
  packaged `.app` before code signing.

## Visual References

- `docs/design-assets/menu-bar-popover-light.png`
- `docs/design-assets/floating-usage-panel-light.png`

## Acceptance Criteria

- The macOS menu bar shows only the new logo at square status-item width.
- Left-click opens the light two-row popover; both quotas, reset times, and
  colored progress bars are visible without switching.
- The desktop panel shows both quotas simultaneously and is materially smaller
  than the old ball.
- Hiding or closing the desktop panel does not stop background refresh.
- The logo is available in both development and the packaged application.
- Existing data, launch-at-login, settings, and RPC tests remain green.
