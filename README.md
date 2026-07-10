# Codex-Usage

A minimalist macOS floating-ball widget for OpenAI Codex usage.

## Features
- Always-on-top floating ball showing Codex 5-hour and weekly usage remaining.
- Shows countdown to the nearest reset.
- Drag to reposition; position is remembered.
- Auto-refreshes every 60 seconds.

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
open Codex-Usage.app
```

## Data Source

Reads from the local Codex CLI via JSON-RPC (`codex app-server`). No API keys or browser cookies required.
