# Codex Mac App Reference

Date: 2026-06-09

This project references OpenAI Codex without copying the private Codex desktop
frontend. The implementation target for RaytoneCodex is a native SwiftUI macOS
client with an app-bundled Codex CLI runtime.

## Observed Local Codex.app

- App bundle: `/Applications/Codex.app`
- Bundle identifier: `com.openai.codex`
- Version: `26.602.71036` build `3685`
- Signing: Developer ID Application `OpenAI OpCo, LLC (2DC432GLL2)`, stapled notarization ticket
- Runtime shape: Electron/Chromium app with `Contents/Resources/app.asar`
- Electron package name: `openai-codex-electron`
- Electron version in package metadata: `42.1.0`
- Packaged frontend: Vite build under `.vite/build` and `webview/assets`
- Native/resource tools: `Contents/Resources/codex`, `node`, `rg`, `node_repl`, `codex_chronicle`, plugins, native node modules
- Bundled CLI version observed: `codex-cli 0.137.0-alpha.4`

The installed PATH CLI on this machine is currently `codex-cli 0.135.0`, so the
official desktop app appears to prefer an app-bundled Codex runtime rather than
requiring the user's shell install.

## Public openai/codex Reference

- Repository: `https://github.com/openai/codex`
- Observed HEAD: `14660c22d14312c28a50c52954dd77dd88f03c26`
- Public repo focus: Rust CLI/TUI plus `codex app-server`, protocol, daemon,
  state, plugins, skills, MCP, and SDK packages
- The public checkout did not expose the packaged `codex-apps/electron` source
  directory seen in the local app manifest.

Useful public reference modules:

- `codex-rs/cli`: top-level CLI commands, including `exec`, `app`, `app-server`,
  `remote-control`, `doctor`, `mcp`, `plugin`, `review`
- `codex-rs/app-server`: JSON-RPC server used by rich clients
- `codex-rs/app-server-protocol`: generated v2 schemas for threads, turns,
  items, command execution, filesystem, model list, skills, plugins, apps
- `codex-rs/app-server-daemon`: managed local app-server lifecycle

## Official Desktop Product Shape

The Electron frontend names and protocol docs point to this shape:

- Sidebar project/thread grouping
- Thread page with header, transcript, bottom composer, and side panels
- Composer controller, footer, branch/workspace controls, slash commands
- App-server connection state with connected, disconnected, login required,
  update required, restart required, and Codex-not-installed states
- Terminal, review, browser/file side panels
- Local/remote host managers and recent conversation caches

## RaytoneCodex Slice

The first implemented slice intentionally stays smaller:

- Native SwiftUI app shell with sidebar, transcript, composer, and inspector
- Build script stages a `.app` bundle and copies a Codex CLI executable into
  `Contents/Resources/codex`
- Runtime resolver priority:
  1. `RAYTONE_CODEX_CLI` override
  2. App bundle `Contents/Resources/codex`
  3. Installed `/Applications/Codex.app/Contents/Resources/codex`
  4. `PATH`
  5. common Homebrew paths
- Current execution path uses `codex exec` for a testable vertical slice.
- Codex CLI `0.137.0-alpha.4` no longer accepts the older
  `codex exec --ask-for-approval` flag. Headless `exec` defaults to never asking
  for approvals, so the current UI displays this as `Headless never` instead of
  presenting a non-functional approval picker.
- The next richer-client step should switch from `codex exec` to
  `codex app-server` JSON-RPC:
  - initialize
  - thread/start
  - turn/start
  - stream item and turn notifications
  - render command/file/reasoning/agent-message items as first-class UI rows

## Packaging Requirement

RaytoneCodex releases should be one-install artifacts. Users should not need to
install Codex CLI separately. The release pipeline should either:

- build the Codex CLI from the Apache-2.0 `openai/codex` source at a pinned
  commit, or
- download a pinned official Codex CLI release asset,

then place the executable at `Contents/Resources/codex` and include required
license/notice files in the app bundle.
