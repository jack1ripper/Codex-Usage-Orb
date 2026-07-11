# Settings, Refresh, Compatibility, and v0.1.4 Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship v0.1.4 with immediate-save settings, a corrected CLI path field, an interactive floating refresh rail, and safe Codex App Server response compatibility.

**Architecture:** Keep the current AppKit window controllers and SwiftUI views. Add small, testable model helpers for path status and refresh visual state, and make the JSON-RPC decoder tolerant of historical/current envelopes while requiring complete quota windows. Release from `main` because the user explicitly requested a tagged GitHub release and Homebrew Tap update.

**Tech Stack:** Swift 6, SwiftUI, AppKit, XCTest, Swift Package Manager, shell release scripts, GitHub Actions, Homebrew Cask.

## Global Constraints

- macOS 14+ and no new third-party dependencies.
- Settings are immediate-save; no Save button or staged draft state.
- Settings window content width is 440pt.
- The floating left rail refreshes on click, shows hover/loading/stale states, and remains accessible.
- Accept historical snake_case, current camelCase, and multi-bucket rate-limit responses.
- Never substitute missing primary/secondary windows with `usedPercent = 0`.
- Preserve the existing JSON-RPC process, timeout, authentication, and stale-snapshot behavior.
- Release version is v0.1.4 in the app bundle, Git tag, GitHub Release workflow, and Homebrew Cask.

---

### Task 1: Safe App Server response decoding

**Files:**
- Modify: `Sources/Codex-Usage/Services/CodexRPCClient.swift`
- Modify: `Sources/Codex-Usage/Models/UsageModel.swift`
- Modify: `Tests/Codex-UsageTests/CodexRPCClientTests.swift`
- Modify: `Tests/Codex-UsageTests/UsageModelTests.swift`

**Interfaces:**
- Produces: `UsageError.incompatibleResponse(String)`.
- Produces: `RPCRateLimitsResponse.bestCompleteRateLimits() -> RateLimits?`.
- Consumes: existing `CodexRPCClient.parseRateLimitsResponse(_:)`.

- [ ] Add failing tests for camelCase response decoding, `rateLimitsByLimitId["codex"]` fallback, first complete bucket fallback, unknown fields, and incomplete windows throwing `incompatibleResponse`.
- [ ] Run `swift test --filter CodexRPCClientTests` and confirm failures are caused by the absent compatibility behavior.
- [ ] Make `rateLimits` optional, add optional `[String: RateLimits]` buckets, select the first complete semantic snapshot in the documented order, and require both windows.
- [ ] Add `UsageError.incompatibleResponse(String)` and update equality coverage.
- [ ] Run `swift test --filter CodexRPCClientTests` and `swift test --filter UsageModelTests`; confirm green.

### Task 2: CLI path status and immediate-save settings

**Files:**
- Create: `Sources/Codex-Usage/Models/CodexCLIPathStatus.swift`
- Create: `Tests/Codex-UsageTests/CodexCLIPathStatusTests.swift`
- Modify: `Sources/Codex-Usage/Services/CodexRPCClient.swift`
- Modify: `Sources/Codex-Usage/Views/SettingsView.swift`
- Modify: `Sources/Codex-Usage/Windows/FloatingWindowController.swift`

**Interfaces:**
- Produces: `CodexCLIPathStatus.resolve(configuredPath:autoDetectedPath:fileManager:)`.
- Produces: `DefaultCodexCLIExecutor.validatedOverridePath(_:)` as an internal reusable validator.
- `SettingsView` no longer accepts `onSave`.

- [ ] Add failing tests for empty+detected, empty+missing, valid explicit, relative, wrong filename, directory, missing, and non-executable paths.
- [ ] Run `swift test --filter CodexCLIPathStatusTests` and confirm expected failures.
- [ ] Implement the path-status model and expose the existing validator without duplicating filesystem rules.
- [ ] Replace the path field title with a real prompt, hide labels, give the field layout priority, keep Browse fixed-size, and render status copy/icon/color below it.
- [ ] Remove the Save section, callback, and redundant apply method; set the Settings view/window width to 440pt.
- [ ] Run path tests and the full suite.

### Task 3: Floating refresh rail

**Files:**
- Create: `Sources/Codex-Usage/Models/FloatingRefreshVisualState.swift`
- Create: `Tests/Codex-UsageTests/FloatingRefreshVisualStateTests.swift`
- Modify: `Sources/Codex-Usage/Views/FloatingBallView.swift`

**Interfaces:**
- Produces: `FloatingRefreshVisualState.resolve(isLoading:isHovering:)` with `.logo`, `.refresh`, and `.loading`.
- Consumes: existing `onRefresh` closure and `UsageRefreshService.isLoading`.

- [ ] Add failing tests for default, hover, and loading priority.
- [ ] Run `swift test --filter FloatingRefreshVisualStateTests` and confirm expected failures.
- [ ] Implement the pure visual-state resolver.
- [ ] Convert the 28pt logo rail to a plain Button: logo by default, refresh glyph on hover, spinner while loading, disabled during loading, stale dot preserved, help and accessibility labels added.
- [ ] Run the focused tests and full suite.

### Task 4: Compatibility error presentation

**Files:**
- Create: `Sources/Codex-Usage/Models/UsageErrorPresentation.swift`
- Create: `Tests/Codex-UsageTests/UsageErrorPresentationTests.swift`
- Modify: `Sources/Codex-Usage/Views/FloatingBallView.swift`
- Modify: `Sources/Codex-Usage/Views/UsagePopoverView.swift`
- Modify: `Tests/Codex-UsageTests/UsageDisplayStateTests.swift`

**Interfaces:**
- Consumes: `UsageError.incompatibleResponse(String)`.
- Produces: `UsageErrorPresentation` with title, message, SF Symbol name, and retry eligibility.
- Preserves: existing stale-snapshot behavior in `UsageDisplayState.resolve`.

- [ ] Add failing presentation tests for CLI missing, unauthenticated, RPC/decode failure, and incompatible response; add a display-state regression test proving an incompatibility error preserves an existing snapshot as stale.
- [ ] Run `swift test --filter UsageErrorPresentationTests` and confirm failure because the presentation model is absent.
- [ ] Implement the presentation model and make both views consume it so incompatibility errors show a clear title/message and allow retry.
- [ ] Run the focused tests and full suite.

### Task 5: Build, install, and visual verification

**Files:**
- Save screenshots under: `/tmp/codex-usage-v0.1.4-qa/`

- [ ] Run `swift build`, `swift test`, and `./Scripts/build_app.sh`.
- [ ] Quit Codex-Usage, delete `/Applications/Codex-Usage.app`, install, and launch the rebuilt app.
- [ ] Capture and inspect the full Settings page: no Save button, correct path layout/status, no clipping at 440pt.
- [ ] Capture and inspect the floating panel default state and refresh hover/loading feedback; confirm quota data remains visible.
- [ ] Correct any visual defect with a failing test where practical, then repeat build/install/screenshot.

### Task 6: Release v0.1.4

**Files:**
- Modify: `Scripts/build_app.sh`
- Regenerate: `Codex-Usage.app/Contents/Info.plist`
- Modify: `README.md` only if user-facing behavior needs documentation.
- Modify: `/Users/dengxiang/homebrew-tap/Casks/codex-usage.rb`

- [ ] Set `CFBundleShortVersionString` and `CFBundleVersion` to `0.1.4` in the build script and regenerate the app bundle.
- [ ] Re-run `swift build`, `swift test`, `./Scripts/build_app.sh`, reinstall, relaunch, and verify screenshots against the release bundle.
- [ ] Run `git diff --check`, inspect the complete diff, and confirm no unrelated changes.
- [ ] Commit the application repository as `Release v0.1.4`, create tag `v0.1.4`, and push `main` plus the tag.
- [ ] Wait for the GitHub Release workflow and verify the v0.1.4 release asset exists.
- [ ] Update Homebrew Cask to `version "0.1.4"`, run `brew audit --cask codex-usage` and `brew style Casks/codex-usage.rb` where available, commit, and push `main`.
- [ ] Verify both repositories are clean and both remotes contain the pushed commits.
