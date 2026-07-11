# Codex-Usage

A minimalist macOS menu bar utility for OpenAI Codex usage.

## Features
- Logo-only menu bar item that opens a light two-row usage popover.
- Shows both the 5-hour and weekly limits, progress, and reset times at once.
- Optional always-on-top two-row desktop panel.
- Drag the desktop panel to reposition it; position is remembered.
- Auto-refreshes every 5 minutes (configurable in settings).
- Right-click the menu bar logo to show/hide the desktop panel, refresh, open settings, or quit.
- Optional launch at login.

## Requirements
- macOS 14+
- Codex CLI installed and authenticated (`codex login`)

## Build

```bash
swift build
```

## Run

```bash
./Scripts/build_app.sh
./Scripts/install.sh
open /Applications/Codex-Usage.app
```

`build_app.sh` creates `Codex-Usage.app` in the project root. `install.sh` copies it to `/Applications` so it appears in Launchpad and Spotlight.

## Data Source

Reads from the local Codex CLI via JSON-RPC (`codex -s read-only -a untrusted app-server --stdio`). No API keys or browser cookies required.
