# Packaging And Notarization

Date: 2026-06-09

RaytoneX is intended to ship as a single macOS app bundle with the Codex CLI
inside the app package. Users should not need a separate `codex` install.

## Current Bundle Shape

`script/build_and_run.sh` stages:

- `dist/RaytoneX.app/Contents/MacOS/RaytoneX`
- `dist/RaytoneX.app/Contents/Resources/codex`
- `dist/RaytoneX.app/Contents/Resources/OPENAI_CODEX_CLI_NOTICE.txt`
- `dist/RaytoneX.app/Contents/Resources/OPENAI_CODEX_LICENSE.txt`
- `dist/RaytoneX.app/Contents/Resources/OPENAI_CODEX_NOTICE.txt`
- `dist/RaytoneX.app/Contents/Resources/RaytoneCodexRelease.json`

It can also produce one-install artifacts:

- `dist/RaytoneX-0.1.0-macos-arm64.zip`
- `dist/RaytoneX-0.1.0-macos-arm64.dmg`

The project also includes a signing baseline at
`Signing/RaytoneCodex.entitlements`. It is intentionally empty right now because
the app is distributed outside the Mac App Store and does not need sandbox
entitlements for the current CLI execution slice.

The source for the staged CLI is chosen in this order:

1. `RAYTONE_CODEX_CLI`
2. `dist/RaytoneCodexCLI/codex` built from the pinned OpenAI Codex source
3. `/Applications/Codex.app/Contents/Resources/codex`
4. standalone `codex` on `PATH`
5. common Homebrew paths

## Local Development Limitation

This machine currently has no valid code-signing identity:

```sh
security find-identity -v -p codesigning
```

Without a trusted Apple Development or Developer ID identity, macOS may block
executables inside an unsigned `.app` container. The script therefore uses a
development-only staged CLI at `.build/raytone-codex-cli/codex` for local smoke
tests when no signing identity is available.

This is not a release substitute. It only proves the SwiftUI app code and the
same Codex CLI binary work together in the local development environment.

The strongest local UI/runtime proof is:

```sh
bash ./script/build_and_run.sh --ui-smoke
```

That command stages the app, launches the SwiftUI client with the staged Codex
CLI, waits for the runtime panel to refresh, captures the app window, and emits
a JSON payload containing the window size, CLI version, screenshot path, and
screenshot byte size.

The strongest local bundle-shape proof is:

```sh
bash ./script/build_and_run.sh --bundle-audit
```

That command stages the app and fails if the app executable, bundled Codex CLI,
Info.plist identifiers, minimum system version, license files, or notice files
are missing or invalid. It also validates the release manifest and records
executable architectures, binary kind, CLI version, file sizes, source CLI path,
local signature status, signing authorities, and hardened runtime flags.

The strongest local package proof is:

```sh
bash ./script/build_and_run.sh --package
```

That command creates both ZIP and DMG artifacts, extracts the ZIP, mounts the
DMG read-only, and inspects the packaged `.app` from each artifact. It fails if
the packaged app executable, bundled Codex CLI, license files, or notice files
are missing, if the packaged CLI does not run `--version`, or if the packaged
app/CLI/release-manifest SHA-256 values do not match the current staged bundle.

The staging script also takes a lightweight lock under `dist/.stage.lock`.
Smoke, bundle-audit, and package commands share `dist/` and `.build`, so the
lock prevents concurrent commands from deleting another command's staged app or
development CLI while it is still running.

## Strict Release Audit

The script has a stricter release gate:

```sh
bash ./script/build_and_run.sh --release-audit
```

That command intentionally fails on this machine because the staged app is not
signed by a Raytone Developer ID identity. On a release machine it requires:

- strict code signatures for the bundled Codex CLI and app bundle
- hardened runtime on the bundled Codex CLI and app bundle
- `Developer ID Application` signing authority
- accepted Gatekeeper assessment
- valid stapled notarization ticket

When a signing identity is available, the staging script signs both
`Contents/Resources/codex` and `RaytoneX.app` with `--options runtime`.
Set `RAYTONE_CODEX_SIGN_IDENTITY` to pin the intended certificate.

## Release Requirement

For a real one-install release:

1. Build or download a pinned Codex CLI binary.
2. Place it at `Contents/Resources/codex`.
3. Include the Apache-2.0 license and NOTICE files.
4. Sign nested executables and the app bundle with a Raytone Developer ID
   Application certificate.
5. Package as DMG or ZIP.
6. Submit for notarization and staple the ticket.
7. Run the strict release audit:

```sh
RAYTONE_CODEX_SIGN_IDENTITY="Developer ID Application: Raytone (...)" \
  bash ./script/build_and_run.sh --release-audit
```

8. Verify on a clean machine with:

```sh
codesign --verify --deep --strict --verbose=4 RaytoneX.app
spctl --assess --type execute --verbose=4 RaytoneX.app
xcrun stapler validate RaytoneX.app
```

Only after those checks pass should the bundle be described as an installable
one-package macOS release.
