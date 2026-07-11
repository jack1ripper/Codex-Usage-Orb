# Compact Percentage Column Design

## Goal

Show every compact quota percentage from `0%` through `100%` without
truncation in both the 220×84 pt standard panel and the 200×84 pt compact
panel.

## Root Cause

`UsageQuotaRow.compactRow` gives the percentage text a fixed width of 38 pt.
With the existing 15 pt semibold system font and monospaced digits, `100%`
measures approximately 43.52 pt, so SwiftUI truncates it to `10…`.

## Chosen Design

- Keep both panel sizes, the 15 pt semibold percentage font, row height,
  labels, reset-time column, and six-point row spacing unchanged.
- Introduce a shared compact percentage-column width of 46 pt. This provides
  enough room for the measured `100%` text plus rendering margin.
- Use that constant for both quota rows so their progress bars remain aligned.
- Let the flexible progress bar absorb the eight-point difference. It retains
  positive visible width in both standard and compact panel sizes.
- Do not use dynamic text widths, font scaling, or a smaller font because those
  would misalign rows or weaken the most important value.

## Testing

- Add a layout test that measures `100%` with AppKit's matching 15 pt semibold
  monospaced-digit font and proves the configured column is at least that wide.
- Verify the existing percentage formatting still returns the full integer
  value and `%` suffix.
- Run focused layout tests, the full Swift test suite, and the app bundle build.
- Reinstall and capture the live panel while it displays `100%` in both rows.

## Acceptance Criteria

- `100%` is fully visible in both quota rows with no ellipsis.
- The two progress bars begin at the same horizontal position.
- Standard and compact panel dimensions do not change.
- Existing fonts, reset text, shadow, drag behavior, and context menu remain
  unchanged.
