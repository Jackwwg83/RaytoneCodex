#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
if [[ "$#" -gt 0 ]]; then
  shift
fi
UI_SCREEN=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --screen)
      if [[ "$#" -lt 2 ]]; then
        echo "--screen requires a screen name." >&2
        exit 2
      fi
      UI_SCREEN="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

APP_NAME="RaytoneCodex"
BUNDLE_ID="com.raytone.codex"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DEV_CLI_DIR="$ROOT_DIR/.build/raytone-codex-cli"
DEV_CLI="$DEV_CLI_DIR/codex"
SOURCE_BUILT_CLI="$ROOT_DIR/dist/RaytoneCodexCLI/codex"
DEV_PROXY="$DEV_CLI_DIR/raytone-proxy"
RAYTONE_PROXY_MANIFEST="$ROOT_DIR/sidecar/raytone-proxy/Cargo.toml"
RAYTONE_PROXY_BINARY="$ROOT_DIR/sidecar/raytone-proxy/target/release/raytone-proxy"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
NOTICE_FILE="$APP_RESOURCES/OPENAI_CODEX_CLI_NOTICE.txt"
PROXY_NOTICE_FILE="$APP_RESOURCES/RAYTONE_PROXY_NOTICE.txt"
PROXY_LICENSE_FILE="$APP_RESOURCES/CC_SWITCH_MIT_LICENSE.txt"
RELEASE_MANIFEST="$APP_RESOURCES/RaytoneCodexRelease.json"
APP_ICON_NAME="AppIcon"
APP_ICON="$APP_RESOURCES/$APP_ICON_NAME.icns"
ICON_GENERATOR="$ROOT_DIR/script/generate_icon.sh"
ENTITLEMENTS_FILE="$ROOT_DIR/Signing/RaytoneCodex.entitlements"
CODEX_LICENSE_SOURCE="$ROOT_DIR/third_party/openai-codex/LICENSE"
CODEX_NOTICE_SOURCE="$ROOT_DIR/third_party/openai-codex/NOTICE"
CODEX_RAYTONE_NOTICE_SOURCE="$ROOT_DIR/third_party/openai-codex/RAYTONE_CODEX_NOTICE.txt"
CODEX_LICENSE_DEST="$APP_RESOURCES/OPENAI_CODEX_LICENSE.txt"
CODEX_NOTICE_DEST="$APP_RESOURCES/OPENAI_CODEX_NOTICE.txt"
PROXY_NOTICE_SOURCE="$ROOT_DIR/sidecar/raytone-proxy/NOTICE"
PROXY_LICENSE_SOURCE="$ROOT_DIR/sidecar/raytone-proxy/vendor/cc-switch/LICENSE"
PKG_INFO="$APP_CONTENTS/PkgInfo"
APP_VERSION="0.1.0"
PACKAGE_BASENAME="$APP_NAME-$APP_VERSION-macos-arm64"
ZIP_ARTIFACT="$DIST_DIR/$PACKAGE_BASENAME.zip"
DMG_ARTIFACT="$DIST_DIR/$PACKAGE_BASENAME.dmg"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"
STAGE_LOCK_DIR="$DIST_DIR/.stage.lock"
LAUNCH_LOG="${TMPDIR:-/tmp}/raytone-codex-launch.log"
SCREENSHOT_DIR="$ROOT_DIR/screenshots"
if [[ -n "$UI_SCREEN" ]]; then
  UI_SCREEN_SLUG="${UI_SCREEN//[^[:alnum:]_-]/-}"
  UI_SMOKE_SCREENSHOT="$SCREENSHOT_DIR/raytonecodex-$UI_SCREEN_SLUG.png"
else
  UI_SMOKE_SCREENSHOT="$SCREENSHOT_DIR/raytonecodex-ui-smoke.png"
fi
APP_SIGN_IDENTITY=""
OPENAI_CODEX_REPO="https://github.com/openai/codex"
OPENAI_CODEX_HEAD_FALLBACK="18ce671fed526be9033907bd88a3a63c6888bbf4"

acquire_stage_lock() {
  mkdir -p "$DIST_DIR"
  while ! mkdir "$STAGE_LOCK_DIR" 2>/dev/null; do
    if [[ -f "$STAGE_LOCK_DIR/pid" ]]; then
      local owner_pid
      owner_pid="$(cat "$STAGE_LOCK_DIR/pid" 2>/dev/null || true)"
      if [[ -n "$owner_pid" ]] && ! kill -0 "$owner_pid" >/dev/null 2>&1; then
        rm -rf "$STAGE_LOCK_DIR"
        continue
      fi
    fi
    sleep 0.25
  done
  printf '%s\n' "$$" >"$STAGE_LOCK_DIR/pid"
  trap release_stage_lock EXIT
}

release_stage_lock() {
  if [[ -f "$STAGE_LOCK_DIR/pid" ]] && [[ "$(cat "$STAGE_LOCK_DIR/pid" 2>/dev/null || true)" == "$$" ]]; then
    rm -rf "$STAGE_LOCK_DIR"
  fi
}

find_codex_cli() {
  if [[ -n "${RAYTONE_CODEX_CLI:-}" && -x "${RAYTONE_CODEX_CLI:-}" ]]; then
    printf '%s\n' "$RAYTONE_CODEX_CLI"
    return 0
  fi

  if [[ -x "$SOURCE_BUILT_CLI" ]] && is_standalone_binary "$SOURCE_BUILT_CLI"; then
    printf '%s\n' "$SOURCE_BUILT_CLI"
    return 0
  fi

  if [[ -x "/Applications/Codex.app/Contents/Resources/codex" ]] && is_standalone_binary "/Applications/Codex.app/Contents/Resources/codex"; then
    printf '%s\n' "/Applications/Codex.app/Contents/Resources/codex"
    return 0
  fi

  if command -v codex >/dev/null 2>&1; then
    PATH_CODEX="$(command -v codex)"
    if is_standalone_binary "$PATH_CODEX"; then
      printf '%s\n' "$PATH_CODEX"
      return 0
    fi
  fi

  for candidate in /opt/homebrew/bin/codex /usr/local/bin/codex; do
    if [[ -x "$candidate" ]] && is_standalone_binary "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

is_standalone_binary() {
  local candidate="$1"
  local kind
  kind="$(/usr/bin/file "$candidate")"
  case "$kind" in
    *Mach-O*|*ELF*|*PE32*)
      return 0
      ;;
  esac

  return 1
}

find_sign_identity() {
  if [[ -n "${RAYTONE_CODEX_SIGN_IDENTITY:-}" ]]; then
    printf '%s\n' "$RAYTONE_CODEX_SIGN_IDENTITY"
    return 0
  fi

  /usr/bin/security find-identity -v -p codesigning 2>/dev/null \
    | /usr/bin/awk -F'"' '/"/ { print $2; exit }'
}

openai_codex_head() {
  if [[ -n "${RAYTONE_CODEX_OPENAI_CODEX_HEAD:-}" ]]; then
    printf '%s\n' "$RAYTONE_CODEX_OPENAI_CODEX_HEAD"
    return 0
  fi

  local head
  if [[ -x /usr/bin/perl ]]; then
    head="$(GIT_TERMINAL_PROMPT=0 /usr/bin/perl -e 'alarm shift; exec @ARGV' 8 git ls-remote "$OPENAI_CODEX_REPO.git" HEAD 2>/dev/null | /usr/bin/awk '{ print $1; exit }' || true)"
  else
    head="$(GIT_TERMINAL_PROMPT=0 git -c http.lowSpeedLimit=1 -c http.lowSpeedTime=8 ls-remote "$OPENAI_CODEX_REPO.git" HEAD 2>/dev/null | /usr/bin/awk '{ print $1; exit }' || true)"
  fi
  if [[ -n "$head" ]]; then
    printf '%s\n' "$head"
  else
    printf '%s\n' "$OPENAI_CODEX_HEAD_FALLBACK"
  fi
}

write_release_manifest() {
  local cli_version proxy_version openai_head bundled_commit generated_at source_cli icon_sha proxy_sha
  cli_version="$(run_cli_version "$APP_RESOURCES/codex" | tr -d '\r')"
  proxy_version="$("$APP_RESOURCES/raytone-proxy" --version | tr -d '\r')"
  openai_head="$(openai_codex_head)"
  bundled_commit="$(git -C "$ROOT_DIR/third_party/openai-codex" rev-parse HEAD 2>/dev/null || true)"
  generated_at="${RAYTONE_CODEX_BUILD_TIMESTAMP:-unknown}"
  source_cli="${CLI_SOURCE:-unknown}"
  icon_sha="$(file_sha256 "$APP_ICON")"
  proxy_sha="$(file_sha256 "$APP_RESOURCES/raytone-proxy")"

  cat >"$RELEASE_MANIFEST" <<JSON
{
  "schemaVersion": 1,
  "generatedAt": "$(json_escape "$generated_at")",
  "app": {
    "name": "$APP_NAME",
    "bundleIdentifier": "$BUNDLE_ID",
    "version": "$APP_VERSION",
    "minimumSystemVersion": "$MIN_SYSTEM_VERSION",
    "packageBasename": "$PACKAGE_BASENAME",
    "icon": "Contents/Resources/$APP_ICON_NAME.icns",
    "iconSHA256": "$icon_sha"
  },
  "codex": {
    "repository": "$OPENAI_CODEX_REPO",
    "observedHead": "$(json_escape "$openai_head")",
    "bundledSourceCommit": "$(json_escape "$bundled_commit")",
    "bundledExecutable": "Contents/Resources/codex",
    "sourceCLI": "$(json_escape "$source_cli")",
    "version": "$(json_escape "$cli_version")"
  },
  "sidecar": {
    "bundledExecutable": "Contents/Resources/raytone-proxy",
    "source": "sidecar/raytone-proxy",
    "version": "$(json_escape "$proxy_version")",
    "sha256": "$proxy_sha"
  },
  "notices": {
    "license": "Contents/Resources/OPENAI_CODEX_LICENSE.txt",
    "notice": "Contents/Resources/OPENAI_CODEX_NOTICE.txt",
    "cliNotice": "Contents/Resources/OPENAI_CODEX_CLI_NOTICE.txt",
    "proxyNotice": "Contents/Resources/RAYTONE_PROXY_NOTICE.txt",
    "ccSwitchLicense": "Contents/Resources/CC_SWITCH_MIT_LICENSE.txt"
  }
}
JSON
}

generate_app_icon() {
  if [[ ! -x "$ICON_GENERATOR" ]]; then
    echo "Icon generator is missing or not executable: $ICON_GENERATOR" >&2
    return 1
  fi
  "$ICON_GENERATOR" "$APP_ICON" >/dev/null
}

stage_app_bundle() {
  swift build
  build_raytone_proxy
  BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
  if ! CLI_SOURCE="$(find_codex_cli)"; then
    echo "No standalone Codex CLI binary found for bundling." >&2
    echo "Set RAYTONE_CODEX_CLI to a pinned release binary, or install/open Codex.app so its bundled Mach-O CLI can be copied." >&2
    exit 1
  fi

  rm -rf "$APP_BUNDLE"
  rm -rf "$DEV_CLI_DIR"
  mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$DEV_CLI_DIR"
  cp "$BUILD_BINARY" "$APP_BINARY"
  chmod +x "$APP_BINARY"

  cp -X "$CLI_SOURCE" "$APP_RESOURCES/codex"
  chmod +x "$APP_RESOURCES/codex"
  cp -X "$CLI_SOURCE" "$DEV_CLI"
  chmod +x "$DEV_CLI"
  cp -X "$RAYTONE_PROXY_BINARY" "$APP_RESOURCES/raytone-proxy"
  chmod +x "$APP_RESOURCES/raytone-proxy"
  cp -X "$RAYTONE_PROXY_BINARY" "$DEV_PROXY"
  chmod +x "$DEV_PROXY"
  generate_app_icon

  cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>Raytone Codex</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.developer-tools</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSRequiresAquaSystemAppearance</key>
  <false/>
</dict>
</plist>
PLIST

  printf 'APPL????' >"$PKG_INFO"

  cat >"$NOTICE_FILE" <<NOTICE
RaytoneCodex bundles a Codex CLI executable at Contents/Resources/codex.

Build-time source path:
$CLI_SOURCE

For redistribution, use a pinned OpenAI Codex CLI release or a reproducible build
from https://github.com/openai/codex and include the Apache-2.0 license and any
required notices with the packaged artifact.
NOTICE

  if [[ -f "$CODEX_LICENSE_SOURCE" ]]; then
    cp "$CODEX_LICENSE_SOURCE" "$CODEX_LICENSE_DEST"
  fi
  if [[ -f "$CODEX_RAYTONE_NOTICE_SOURCE" ]]; then
    cp "$CODEX_RAYTONE_NOTICE_SOURCE" "$CODEX_NOTICE_DEST"
  elif [[ -f "$CODEX_NOTICE_SOURCE" ]]; then
    cp "$CODEX_NOTICE_SOURCE" "$CODEX_NOTICE_DEST"
  fi
  if [[ -f "$PROXY_NOTICE_SOURCE" ]]; then
    cp "$PROXY_NOTICE_SOURCE" "$PROXY_NOTICE_FILE"
  fi
  if [[ -f "$PROXY_LICENSE_SOURCE" ]]; then
    cp "$PROXY_LICENSE_SOURCE" "$PROXY_LICENSE_FILE"
  fi

  /usr/bin/xattr -cr "$APP_BUNDLE" >/dev/null 2>&1 || true
  APP_SIGN_IDENTITY="$(find_sign_identity)"
  if [[ -n "$APP_SIGN_IDENTITY" ]]; then
    local timestamp_args=()
    local app_entitlements_args=()
    if [[ "${RAYTONE_CODEX_CODESIGN_TIMESTAMP:-1}" != "0" ]]; then
      timestamp_args=(--timestamp)
    fi
    if [[ -f "$ENTITLEMENTS_FILE" ]]; then
      app_entitlements_args=(--entitlements "$ENTITLEMENTS_FILE")
    fi

    /usr/bin/codesign --force --options runtime "${timestamp_args[@]}" \
      --sign "$APP_SIGN_IDENTITY" "$APP_RESOURCES/codex" >/dev/null
    /usr/bin/codesign --force --options runtime "${timestamp_args[@]}" \
      --sign "$APP_SIGN_IDENTITY" "$APP_RESOURCES/raytone-proxy" >/dev/null
    write_release_manifest
    /usr/bin/codesign --force --deep --options runtime "${timestamp_args[@]}" \
      "${app_entitlements_args[@]}" --sign "$APP_SIGN_IDENTITY" "$APP_BUNDLE" >/dev/null
  else
    echo "No trusted codesigning identity found; ad-hoc signing the .app for local test packaging and using $DEV_CLI for local development verification." >&2
    local app_entitlements_args=()
    if [[ -f "$ENTITLEMENTS_FILE" ]]; then
      app_entitlements_args=(--entitlements "$ENTITLEMENTS_FILE")
    fi
    /usr/bin/codesign --force --options runtime --sign - "$APP_RESOURCES/codex" >/dev/null
    /usr/bin/codesign --force --options runtime --sign - "$APP_RESOURCES/raytone-proxy" >/dev/null
    write_release_manifest
    /usr/bin/codesign --force --deep --options runtime \
      "${app_entitlements_args[@]}" --sign - "$APP_BUNDLE" >/dev/null
  fi
  /usr/bin/xattr -cr "$APP_BUNDLE" >/dev/null 2>&1 || true
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

run_bundle_binary() {
  /usr/bin/nohup /usr/bin/env \
    RAYTONE_PROXY="$APP_RESOURCES/raytone-proxy" \
    RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
    "$APP_BINARY" >"$LAUNCH_LOG" 2>&1 &
}

run_development_binary() {
  /usr/bin/nohup /usr/bin/env \
    RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
    RAYTONE_PROXY="$(local_proxy_for_verification)" \
    RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
    "$BUILD_BINARY" >"$LAUNCH_LOG" 2>&1 &
}

run_development_binary_detached() {
  /usr/bin/nohup /usr/bin/env \
    RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
    RAYTONE_PROXY="$(local_proxy_for_verification)" \
    RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
    "$BUILD_BINARY" >"$LAUNCH_LOG" 2>&1 &
  printf '%s\n' "$!"
}

run_development_binary_for_smoke() {
  /usr/bin/env \
    RAYTONE_CODEX_UI_SCREEN="$UI_SCREEN" \
    RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
    RAYTONE_PROXY="$(local_proxy_for_verification)" \
    RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
    "$BUILD_BINARY" >"$LAUNCH_LOG" 2>&1 &
  printf '%s\n' "$!"
}

local_cli_for_verification() {
  if [[ -n "$APP_SIGN_IDENTITY" ]]; then
    printf '%s\n' "$APP_RESOURCES/codex"
  else
    printf '%s\n' "$DEV_CLI"
  fi
}

local_proxy_for_verification() {
  if [[ -n "$APP_SIGN_IDENTITY" ]]; then
    printf '%s\n' "$APP_RESOURCES/raytone-proxy"
  else
    printf '%s\n' "$DEV_PROXY"
  fi
}

first_app_pid() {
  pgrep -x "$APP_NAME" | head -1 || true
}

wait_for_app() {
  for _ in {1..20}; do
    local pid
    pid="$(first_app_pid)"
    if [[ -n "$pid" ]]; then
      sleep 0.75
      if ps -p "$pid" >/dev/null 2>&1; then
        return 0
      fi
    else
      sleep 0.25
    fi
  done

  return 1
}

run_cli_version() {
  local cli="$1"
  local stdout_file stderr_file pid status
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  "$cli" --version >"$stdout_file" 2>"$stderr_file" &
  pid="$!"

  for _ in {1..60}; do
    if ! kill -0 "$pid" >/dev/null 2>&1; then
      if wait "$pid"; then
        status=0
      else
        status="$?"
      fi
      cat "$stdout_file"
      cat "$stderr_file" >&2
      rm -f "$stdout_file" "$stderr_file"
      return "$status"
    fi
    sleep 0.25
  done

  kill "$pid" >/dev/null 2>&1 || true
  wait "$pid" >/dev/null 2>&1 || true
  cat "$stdout_file"
  cat "$stderr_file" >&2
  rm -f "$stdout_file" "$stderr_file"
  echo "Timed out while running $cli --version" >&2
  return 124
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

file_sha256() {
  /usr/bin/shasum -a 256 "$1" | /usr/bin/awk '{ print $1 }'
}

build_raytone_proxy() {
  if [[ ! -f "$RAYTONE_PROXY_MANIFEST" ]]; then
    echo "Raytone proxy manifest is missing: $RAYTONE_PROXY_MANIFEST" >&2
    return 1
  fi

  cargo build --release --manifest-path "$RAYTONE_PROXY_MANIFEST"
  require_executable_path "Raytone provider proxy" "$RAYTONE_PROXY_BINARY"
}

window_info_for_pid() {
  /usr/bin/swift - "$1" <<'SWIFT'
import CoreGraphics
import Foundation

let targetPID = Int(CommandLine.arguments[1]) ?? -1
let options = CGWindowListOption(arrayLiteral: [.optionOnScreenOnly, .excludeDesktopElements])
let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []

for window in windows {
    guard (window[kCGWindowOwnerPID as String] as? Int) == targetPID else {
        continue
    }
    guard let number = window[kCGWindowNumber as String] as? Int,
          let bounds = window[kCGWindowBounds as String] as? [String: Any],
          let width = bounds["Width"] as? CGFloat,
          let height = bounds["Height"] as? CGFloat else {
        continue
    }
    print("WINDOW_ID=\(number)")
    print("WINDOW_WIDTH=\(Int(width))")
    print("WINDOW_HEIGHT=\(Int(height))")
    exit(0)
}

exit(1)
SWIFT
}

wait_for_window_for_pid() {
  local app_pid="$1"
  local window_info

  for _ in {1..40}; do
    if ! ps -p "$app_pid" >/dev/null 2>&1; then
      return 2
    fi

    if window_info="$(window_info_for_pid "$app_pid" 2>/dev/null)"; then
      printf '%s\n' "$window_info"
      return 0
    fi
    sleep 0.25
  done

  return 1
}

run_ui_smoke() {
  local app_pid="" window_info window_id window_width window_height screenshot_size cli_version runtime_path settle_seconds

  cleanup_ui_smoke() {
    if [[ -n "$app_pid" ]]; then
      kill "$app_pid" >/dev/null 2>&1 || true
      wait "$app_pid" >/dev/null 2>&1 || true
    fi
    if [[ -n "$UI_SCREEN" ]]; then
      /bin/launchctl unsetenv RAYTONE_CODEX_UI_SCREEN >/dev/null 2>&1 || true
      /bin/launchctl unsetenv RAYTONE_CODEX_WORKSPACE >/dev/null 2>&1 || true
      /bin/launchctl unsetenv RAYTONE_PROXY >/dev/null 2>&1 || true
      /bin/launchctl unsetenv RAYTONE_CODEX_BROWSER_SNAPSHOT_SMOKE >/dev/null 2>&1 || true
      /bin/launchctl unsetenv RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH >/dev/null 2>&1 || true
      /bin/launchctl unsetenv RAYTONE_CODEX_BROWSER_CLEAR_DATA_SMOKE >/dev/null 2>&1 || true
      /bin/launchctl unsetenv RAYTONE_CODEX_SETTINGS_BROWSER_SNAPSHOT_SMOKE >/dev/null 2>&1 || true
    fi
  }
  trap cleanup_ui_smoke RETURN

  mkdir -p "$SCREENSHOT_DIR"
  rm -f "$UI_SMOKE_SCREENSHOT"

  if [[ -n "$UI_SCREEN" ]]; then
    if [[ -n "$APP_SIGN_IDENTITY" ]]; then
      echo "Launching UI smoke screen '$UI_SCREEN' from $APP_BUNDLE." >&2
      /bin/launchctl setenv RAYTONE_CODEX_UI_SCREEN "$UI_SCREEN"
      /bin/launchctl setenv RAYTONE_CODEX_WORKSPACE "$ROOT_DIR"
      /bin/launchctl setenv RAYTONE_PROXY "$APP_RESOURCES/raytone-proxy"
      if [[ -n "${RAYTONE_CODEX_BROWSER_SNAPSHOT_SMOKE:-}" ]]; then
        /bin/launchctl setenv RAYTONE_CODEX_BROWSER_SNAPSHOT_SMOKE "$RAYTONE_CODEX_BROWSER_SNAPSHOT_SMOKE"
      fi
      if [[ -n "${RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH:-}" ]]; then
        /bin/launchctl setenv RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH "$RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH"
      fi
      if [[ -n "${RAYTONE_CODEX_BROWSER_CLEAR_DATA_SMOKE:-}" ]]; then
        /bin/launchctl setenv RAYTONE_CODEX_BROWSER_CLEAR_DATA_SMOKE "$RAYTONE_CODEX_BROWSER_CLEAR_DATA_SMOKE"
      fi
      if [[ -n "${RAYTONE_CODEX_SETTINGS_BROWSER_SNAPSHOT_SMOKE:-}" ]]; then
        /bin/launchctl setenv RAYTONE_CODEX_SETTINGS_BROWSER_SNAPSHOT_SMOKE "$RAYTONE_CODEX_SETTINGS_BROWSER_SNAPSHOT_SMOKE"
      fi
      open_app || true
      if ! wait_for_app; then
        echo "$APP_NAME did not remain running for UI smoke screen '$UI_SCREEN'." >&2
        cat "$LAUNCH_LOG" >&2 || true
        return 1
      fi
      app_pid="$(first_app_pid)"
      runtime_path="$APP_RESOURCES/codex"
    else
      echo "Launching UI smoke screen '$UI_SCREEN' from the direct development binary with the staged local CLI from $DEV_CLI." >&2
      app_pid="$(run_development_binary_for_smoke)"
      runtime_path="$(local_cli_for_verification)"
    fi
  elif [[ -n "$APP_SIGN_IDENTITY" ]]; then
    open_app || true
    if ! wait_for_app; then
      echo "$APP_NAME did not remain running for UI smoke." >&2
      cat "$LAUNCH_LOG" >&2 || true
      return 1
    fi
    app_pid="$(first_app_pid)"
    runtime_path="$APP_RESOURCES/codex"
  else
    echo "Trying unsigned staged app UI smoke from $APP_BUNDLE." >&2
    open_app || true
    if wait_for_app; then
      app_pid="$(first_app_pid)"
      runtime_path="$APP_RESOURCES/codex"
    else
      echo "LaunchServices did not keep the unsigned staged app running; falling back to direct development binary." >&2
      echo "Launching the SwiftUI binary with the staged local CLI from $DEV_CLI." >&2
      app_pid="$(run_development_binary_for_smoke)"
      runtime_path="$(local_cli_for_verification)"
    fi
  fi

  if ! window_info="$(wait_for_window_for_pid "$app_pid")"; then
    if ! ps -p "$app_pid" >/dev/null 2>&1; then
      echo "$APP_NAME exited before its UI window appeared." >&2
    else
      echo "No onscreen $APP_NAME window was found for PID $app_pid." >&2
    fi
    cat "$LAUNCH_LOG" >&2 || true
    return 1
  fi
  eval "$window_info"

  window_id="${WINDOW_ID:-}"
  window_width="${WINDOW_WIDTH:-0}"
  window_height="${WINDOW_HEIGHT:-0}"

  if [[ -z "$window_id" ]]; then
    echo "No onscreen $APP_NAME window was found for PID $app_pid." >&2
    cat "$LAUNCH_LOG" >&2 || true
    return 1
  fi

  if [[ "$window_width" -lt 1220 || "$window_height" -lt 760 ]]; then
    echo "Window is smaller than the supported minimum: ${window_width}x${window_height}." >&2
    return 1
  fi

  # Give SwiftUI tasks that inspect the bundled CLI and app-server catalog
  # enough time to update visible panels before the screenshot is captured.
  settle_seconds="${RAYTONE_CODEX_UI_SETTLE_SECONDS:-8}"
  case "${UI_SCREEN:-}" in
    home|start|new-thread|hero)
      settle_seconds="${RAYTONE_CODEX_UI_SETTLE_SECONDS:-18}"
      ;;
  esac
  sleep "$settle_seconds"
  if window_info="$(window_info_for_pid "$app_pid" 2>/dev/null)"; then
    eval "$window_info"
    window_id="${WINDOW_ID:-$window_id}"
    window_width="${WINDOW_WIDTH:-$window_width}"
    window_height="${WINDOW_HEIGHT:-$window_height}"
  fi

  /usr/sbin/screencapture -x -l "$window_id" "$UI_SMOKE_SCREENSHOT"
  screenshot_size="$(/usr/bin/stat -f '%z' "$UI_SMOKE_SCREENSHOT")"
  if [[ "$screenshot_size" -lt 100000 ]]; then
    echo "UI screenshot is unexpectedly small: $screenshot_size bytes." >&2
    return 1
  fi

  cli_version="$("$runtime_path" --version | tr -d '\r')"

  printf '{\n'
  printf '  "ok": true,\n'
  printf '  "app": "%s",\n' "$APP_NAME"
  printf '  "screen": "%s",\n' "$(json_escape "${UI_SCREEN:-default}")"
  printf '  "windowId": %s,\n' "$window_id"
  printf '  "windowWidth": %s,\n' "$window_width"
  printf '  "windowHeight": %s,\n' "$window_height"
  printf '  "runtimePath": "%s",\n' "$(json_escape "$runtime_path")"
  printf '  "runtimeVersion": "%s",\n' "$(json_escape "$cli_version")"
  printf '  "screenshot": "%s",\n' "$(json_escape "$UI_SMOKE_SCREENSHOT")"
  printf '  "screenshotBytes": %s\n' "$screenshot_size"
  printf '}\n'

  cleanup_ui_smoke
  trap - RETURN
}

run_browser_snapshot_smoke() {
  local snapshot_path="$SCREENSHOT_DIR/raytonecodex-browser-webview-snapshot.png"
  local snapshot_size window_screenshot window_screenshot_size old_ui_screen old_ui_smoke_screenshot

  mkdir -p "$SCREENSHOT_DIR"
  rm -f "$snapshot_path"
  old_ui_screen="$UI_SCREEN"
  old_ui_smoke_screenshot="$UI_SMOKE_SCREENSHOT"
  UI_SCREEN="browser"
  UI_SMOKE_SCREENSHOT="$SCREENSHOT_DIR/raytonecodex-browser-snapshot-window.png"
  window_screenshot="$UI_SMOKE_SCREENSHOT"
  rm -f "$window_screenshot"
  export RAYTONE_CODEX_BROWSER_SNAPSHOT_SMOKE=1
  export RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH="$snapshot_path"
  export RAYTONE_CODEX_BROWSER_CLEAR_DATA_SMOKE=1
  export RAYTONE_CODEX_UI_SETTLE_SECONDS="${RAYTONE_CODEX_UI_SETTLE_SECONDS:-10}"

  if ! run_ui_smoke; then
    UI_SCREEN="$old_ui_screen"
    UI_SMOKE_SCREENSHOT="$old_ui_smoke_screenshot"
    unset RAYTONE_CODEX_BROWSER_SNAPSHOT_SMOKE
    unset RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH
    unset RAYTONE_CODEX_BROWSER_CLEAR_DATA_SMOKE
    return 1
  fi

  UI_SCREEN="$old_ui_screen"
  UI_SMOKE_SCREENSHOT="$old_ui_smoke_screenshot"
  unset RAYTONE_CODEX_BROWSER_SNAPSHOT_SMOKE
  unset RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH
  unset RAYTONE_CODEX_BROWSER_CLEAR_DATA_SMOKE

  if [[ ! -f "$window_screenshot" ]]; then
    echo "Browser window screenshot was not created: $window_screenshot" >&2
    return 1
  fi
  window_screenshot_size="$(/usr/bin/stat -f '%z' "$window_screenshot")"
  if [[ "$window_screenshot_size" -lt 20000 ]]; then
    echo "Browser window screenshot is unexpectedly small: $window_screenshot_size bytes." >&2
    return 1
  fi

  if [[ ! -f "$snapshot_path" ]]; then
    echo "Browser WebView snapshot was not created: $snapshot_path" >&2
    return 1
  fi
  snapshot_size="$(/usr/bin/stat -f '%z' "$snapshot_path")"
  if [[ "$snapshot_size" -lt 20000 ]]; then
    echo "Browser WebView snapshot is unexpectedly small: $snapshot_size bytes." >&2
    return 1
  fi

  printf '{\n'
  printf '  "ok": true,\n'
  printf '  "screen": "browser-snapshot",\n'
  printf '  "windowScreenshot": "%s",\n' "$(json_escape "$window_screenshot")"
  printf '  "windowScreenshotBytes": %s,\n' "$window_screenshot_size"
  printf '  "webviewSnapshot": "%s",\n' "$(json_escape "$snapshot_path")"
  printf '  "webviewSnapshotBytes": %s\n' "$snapshot_size"
  printf '}\n'
}

run_settings_browser_snapshot_smoke() {
  local snapshot_path="$SCREENSHOT_DIR/raytonecodex-settings-browser-webview-snapshot.png"
  local snapshot_size window_screenshot window_screenshot_size old_ui_screen old_ui_smoke_screenshot

  mkdir -p "$SCREENSHOT_DIR"
  rm -f "$snapshot_path"
  old_ui_screen="$UI_SCREEN"
  old_ui_smoke_screenshot="$UI_SMOKE_SCREENSHOT"
  UI_SCREEN="settings-browser"
  UI_SMOKE_SCREENSHOT="$SCREENSHOT_DIR/raytonecodex-settings-browser-snapshot-window.png"
  window_screenshot="$UI_SMOKE_SCREENSHOT"
  rm -f "$window_screenshot"
  export RAYTONE_CODEX_SETTINGS_BROWSER_SNAPSHOT_SMOKE=1
  export RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH="$snapshot_path"
  export RAYTONE_CODEX_UI_SETTLE_SECONDS="${RAYTONE_CODEX_UI_SETTLE_SECONDS:-12}"

  if ! run_ui_smoke; then
    UI_SCREEN="$old_ui_screen"
    UI_SMOKE_SCREENSHOT="$old_ui_smoke_screenshot"
    unset RAYTONE_CODEX_SETTINGS_BROWSER_SNAPSHOT_SMOKE
    unset RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH
    return 1
  fi

  UI_SCREEN="$old_ui_screen"
  UI_SMOKE_SCREENSHOT="$old_ui_smoke_screenshot"
  unset RAYTONE_CODEX_SETTINGS_BROWSER_SNAPSHOT_SMOKE
  unset RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH

  if [[ ! -f "$window_screenshot" ]]; then
    echo "Settings browser window screenshot was not created: $window_screenshot" >&2
    return 1
  fi
  window_screenshot_size="$(/usr/bin/stat -f '%z' "$window_screenshot")"
  if [[ "$window_screenshot_size" -lt 20000 ]]; then
    echo "Settings browser window screenshot is unexpectedly small: $window_screenshot_size bytes." >&2
    return 1
  fi

  if [[ ! -f "$snapshot_path" ]]; then
    echo "Settings browser WebView snapshot was not created: $snapshot_path" >&2
    return 1
  fi
  snapshot_size="$(/usr/bin/stat -f '%z' "$snapshot_path")"
  if [[ "$snapshot_size" -lt 20000 ]]; then
    echo "Settings browser WebView snapshot is unexpectedly small: $snapshot_size bytes." >&2
    return 1
  fi

  printf '{\n'
  printf '  "ok": true,\n'
  printf '  "screen": "settings-browser-snapshot",\n'
  printf '  "windowScreenshot": "%s",\n' "$(json_escape "$window_screenshot")"
  printf '  "windowScreenshotBytes": %s,\n' "$window_screenshot_size"
  printf '  "webviewSnapshot": "%s",\n' "$(json_escape "$snapshot_path")"
  printf '  "webviewSnapshotBytes": %s\n' "$snapshot_size"
  printf '}\n'
}

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST"
}

require_existing_path() {
  local label="$1"
  local path="$2"
  if [[ ! -e "$path" ]]; then
    echo "Missing $label: $path" >&2
    return 1
  fi
}

require_executable_path() {
  local label="$1"
  local path="$2"
  require_existing_path "$label" "$path"
  if [[ ! -x "$path" ]]; then
    echo "$label is not executable: $path" >&2
    return 1
  fi
}

require_nonempty_file() {
  local label="$1"
  local path="$2"
  require_existing_path "$label" "$path"
  if [[ ! -s "$path" ]]; then
    echo "$label is empty: $path" >&2
    return 1
  fi
}

require_plist_value() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(plist_value "$key")"
  if [[ "$actual" != "$expected" ]]; then
    echo "Info.plist $key expected '$expected' but found '$actual'." >&2
    return 1
  fi
}

manifest_value() {
  local manifest="$1"
  local key="$2"
  /usr/bin/plutil -extract "$key" raw -o - "$manifest" 2>/dev/null
}

require_manifest_value() {
  local manifest="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual="$(manifest_value "$manifest" "$key")"
  if [[ "$actual" != "$expected" ]]; then
    echo "Release manifest $key expected '$expected' but found '${actual:-missing}'." >&2
    return 1
  fi
}

require_manifest_nonempty_value() {
  local manifest="$1"
  local key="$2"
  local actual
  actual="$(manifest_value "$manifest" "$key")"
  if [[ -z "$actual" ]]; then
    echo "Release manifest $key is missing or empty." >&2
    return 1
  fi
}

codesign_details() {
  /usr/bin/codesign -dv --verbose=4 "$1" 2>&1
}

codesign_authority() {
  codesign_details "$1" | /usr/bin/awk -F= '/^Authority=/{ print $2; exit }'
}

codesign_has_hardened_runtime() {
  codesign_details "$1" | /usr/bin/grep -Eq 'flags=.*runtime'
}

require_valid_signature() {
  local label="$1"
  local path="$2"
  if ! /usr/bin/codesign --verify --strict --verbose=2 "$path" >/dev/null 2>&1; then
    echo "$label does not have a valid strict code signature: $path" >&2
    /usr/bin/codesign --verify --strict --verbose=2 "$path" >&2 || true
    return 1
  fi
}

require_hardened_runtime() {
  local label="$1"
  local path="$2"
  if ! codesign_has_hardened_runtime "$path"; then
    echo "$label is not signed with the hardened runtime option: $path" >&2
    codesign_details "$path" >&2 || true
    return 1
  fi
}

require_developer_id_signature() {
  local label="$1"
  local path="$2"
  local authority
  authority="$(codesign_authority "$path" || true)"
  if [[ "$authority" != Developer\ ID\ Application:* ]]; then
    echo "$label is not signed with a Developer ID Application identity: ${authority:-none}" >&2
    return 1
  fi
}

run_bundle_audit() {
  local cli_version proxy_version app_archs cli_archs proxy_archs app_bytes cli_bytes proxy_bytes license_bytes notice_bytes cli_notice_bytes
  local icon_bytes icon_sha manifest_bytes manifest_head manifest_generated_at
  local signature_status app_kind cli_kind proxy_kind display_name
  local app_authority cli_authority proxy_authority app_hardened_runtime cli_hardened_runtime proxy_hardened_runtime
  local app_sha256 cli_sha256 proxy_sha256 proxy_notice_bytes proxy_license_bytes

  require_existing_path "app bundle" "$APP_BUNDLE"
  require_existing_path "Info.plist" "$INFO_PLIST"
  require_executable_path "app executable" "$APP_BINARY"
  require_executable_path "bundled Codex CLI" "$APP_RESOURCES/codex"
  require_executable_path "bundled Raytone proxy" "$APP_RESOURCES/raytone-proxy"
  require_nonempty_file "OpenAI Codex license" "$CODEX_LICENSE_DEST"
  require_nonempty_file "OpenAI Codex notice" "$CODEX_NOTICE_DEST"
  require_nonempty_file "RaytoneCodex CLI notice" "$NOTICE_FILE"
  require_nonempty_file "Raytone proxy notice" "$PROXY_NOTICE_FILE"
  require_nonempty_file "cc-switch MIT license" "$PROXY_LICENSE_FILE"
  require_nonempty_file "RaytoneCodex release manifest" "$RELEASE_MANIFEST"
  require_nonempty_file "RaytoneCodex app icon" "$APP_ICON"

  require_plist_value "CFBundleExecutable" "$APP_NAME"
  require_plist_value "CFBundleIdentifier" "$BUNDLE_ID"
  require_plist_value "CFBundleIconFile" "$APP_ICON_NAME"
  require_plist_value "CFBundlePackageType" "APPL"
  require_plist_value "LSMinimumSystemVersion" "$MIN_SYSTEM_VERSION"
  display_name="$(plist_value "CFBundleDisplayName")"

  if ! is_standalone_binary "$APP_RESOURCES/codex"; then
    echo "Bundled Codex CLI is not a standalone binary: $APP_RESOURCES/codex" >&2
    return 1
  fi
  if ! is_standalone_binary "$APP_RESOURCES/raytone-proxy"; then
    echo "Bundled Raytone proxy is not a standalone binary: $APP_RESOURCES/raytone-proxy" >&2
    return 1
  fi

  cli_version="$(run_cli_version "$APP_RESOURCES/codex" | tr -d '\r')"
  if [[ "$cli_version" != codex-cli* ]]; then
    echo "Unexpected bundled Codex CLI version output: $cli_version" >&2
    return 1
  fi
  proxy_version="$("$APP_RESOURCES/raytone-proxy" --version | tr -d '\r')"
  if [[ "$proxy_version" != raytone-proxy* ]]; then
    echo "Unexpected bundled Raytone proxy version output: $proxy_version" >&2
    return 1
  fi

  app_archs="$(/usr/bin/lipo -archs "$APP_BINARY" 2>/dev/null || /usr/bin/file -b "$APP_BINARY")"
  cli_archs="$(/usr/bin/lipo -archs "$APP_RESOURCES/codex" 2>/dev/null || /usr/bin/file -b "$APP_RESOURCES/codex")"
  proxy_archs="$(/usr/bin/lipo -archs "$APP_RESOURCES/raytone-proxy" 2>/dev/null || /usr/bin/file -b "$APP_RESOURCES/raytone-proxy")"
  app_kind="$(/usr/bin/file -b "$APP_BINARY")"
  cli_kind="$(/usr/bin/file -b "$APP_RESOURCES/codex")"
  proxy_kind="$(/usr/bin/file -b "$APP_RESOURCES/raytone-proxy")"
  app_bytes="$(/usr/bin/stat -f '%z' "$APP_BINARY")"
  cli_bytes="$(/usr/bin/stat -f '%z' "$APP_RESOURCES/codex")"
  proxy_bytes="$(/usr/bin/stat -f '%z' "$APP_RESOURCES/raytone-proxy")"
  app_sha256="$(file_sha256 "$APP_BINARY")"
  cli_sha256="$(file_sha256 "$APP_RESOURCES/codex")"
  proxy_sha256="$(file_sha256 "$APP_RESOURCES/raytone-proxy")"
  license_bytes="$(/usr/bin/stat -f '%z' "$CODEX_LICENSE_DEST")"
  notice_bytes="$(/usr/bin/stat -f '%z' "$CODEX_NOTICE_DEST")"
  cli_notice_bytes="$(/usr/bin/stat -f '%z' "$NOTICE_FILE")"
  proxy_notice_bytes="$(/usr/bin/stat -f '%z' "$PROXY_NOTICE_FILE")"
  proxy_license_bytes="$(/usr/bin/stat -f '%z' "$PROXY_LICENSE_FILE")"
  icon_bytes="$(/usr/bin/stat -f '%z' "$APP_ICON")"
  icon_sha="$(file_sha256 "$APP_ICON")"
  manifest_bytes="$(/usr/bin/stat -f '%z' "$RELEASE_MANIFEST")"
  require_manifest_value "$RELEASE_MANIFEST" "app.name" "$APP_NAME"
  require_manifest_value "$RELEASE_MANIFEST" "app.bundleIdentifier" "$BUNDLE_ID"
  require_manifest_value "$RELEASE_MANIFEST" "app.version" "$APP_VERSION"
  require_manifest_value "$RELEASE_MANIFEST" "app.minimumSystemVersion" "$MIN_SYSTEM_VERSION"
  require_manifest_value "$RELEASE_MANIFEST" "app.packageBasename" "$PACKAGE_BASENAME"
  require_manifest_value "$RELEASE_MANIFEST" "app.icon" "Contents/Resources/$APP_ICON_NAME.icns"
  require_manifest_value "$RELEASE_MANIFEST" "app.iconSHA256" "$icon_sha"
  require_manifest_value "$RELEASE_MANIFEST" "codex.repository" "$OPENAI_CODEX_REPO"
  require_manifest_value "$RELEASE_MANIFEST" "codex.bundledExecutable" "Contents/Resources/codex"
  require_manifest_value "$RELEASE_MANIFEST" "codex.version" "$cli_version"
  require_manifest_value "$RELEASE_MANIFEST" "sidecar.bundledExecutable" "Contents/Resources/raytone-proxy"
  require_manifest_value "$RELEASE_MANIFEST" "sidecar.source" "sidecar/raytone-proxy"
  require_manifest_value "$RELEASE_MANIFEST" "sidecar.version" "$proxy_version"
  require_manifest_value "$RELEASE_MANIFEST" "sidecar.sha256" "$proxy_sha256"
  require_manifest_nonempty_value "$RELEASE_MANIFEST" "codex.observedHead"
  require_manifest_nonempty_value "$RELEASE_MANIFEST" "codex.sourceCLI"
  require_manifest_value "$RELEASE_MANIFEST" "notices.license" "Contents/Resources/OPENAI_CODEX_LICENSE.txt"
  require_manifest_value "$RELEASE_MANIFEST" "notices.notice" "Contents/Resources/OPENAI_CODEX_NOTICE.txt"
  require_manifest_value "$RELEASE_MANIFEST" "notices.cliNotice" "Contents/Resources/OPENAI_CODEX_CLI_NOTICE.txt"
  require_manifest_value "$RELEASE_MANIFEST" "notices.proxyNotice" "Contents/Resources/RAYTONE_PROXY_NOTICE.txt"
  require_manifest_value "$RELEASE_MANIFEST" "notices.ccSwitchLicense" "Contents/Resources/CC_SWITCH_MIT_LICENSE.txt"
  require_manifest_nonempty_value "$RELEASE_MANIFEST" "generatedAt"
  manifest_head="$(manifest_value "$RELEASE_MANIFEST" "codex.observedHead")"
  manifest_generated_at="$(manifest_value "$RELEASE_MANIFEST" "generatedAt")"

  if /usr/bin/codesign --verify --deep --strict "$APP_BUNDLE" >/dev/null 2>&1; then
    signature_status="valid"
  else
    signature_status="unsigned-or-not-verifiable"
  fi
  app_authority="$(codesign_authority "$APP_BUNDLE" || true)"
  cli_authority="$(codesign_authority "$APP_RESOURCES/codex" || true)"
  proxy_authority="$(codesign_authority "$APP_RESOURCES/raytone-proxy" || true)"
  if codesign_has_hardened_runtime "$APP_BUNDLE"; then
    app_hardened_runtime=true
  else
    app_hardened_runtime=false
  fi
  if codesign_has_hardened_runtime "$APP_RESOURCES/codex"; then
    cli_hardened_runtime=true
  else
    cli_hardened_runtime=false
  fi
  if codesign_has_hardened_runtime "$APP_RESOURCES/raytone-proxy"; then
    proxy_hardened_runtime=true
  else
    proxy_hardened_runtime=false
  fi

  printf '{\n'
  printf '  "ok": true,\n'
  printf '  "bundle": "%s",\n' "$(json_escape "$APP_BUNDLE")"
  printf '  "bundleIdentifier": "%s",\n' "$(json_escape "$(plist_value "CFBundleIdentifier")")"
  printf '  "displayName": "%s",\n' "$(json_escape "$display_name")"
  printf '  "minimumSystemVersion": "%s",\n' "$(json_escape "$(plist_value "LSMinimumSystemVersion")")"
  printf '  "appExecutable": "%s",\n' "$(json_escape "$APP_BINARY")"
  printf '  "appExecutableBytes": %s,\n' "$app_bytes"
  printf '  "appExecutableSHA256": "%s",\n' "$app_sha256"
  printf '  "appExecutableArchs": "%s",\n' "$(json_escape "$app_archs")"
  printf '  "appExecutableKind": "%s",\n' "$(json_escape "$app_kind")"
  printf '  "bundledCLI": "%s",\n' "$(json_escape "$APP_RESOURCES/codex")"
  printf '  "bundledCLIBytes": %s,\n' "$cli_bytes"
  printf '  "bundledCLISHA256": "%s",\n' "$cli_sha256"
  printf '  "bundledCLIArchs": "%s",\n' "$(json_escape "$cli_archs")"
  printf '  "bundledCLIKind": "%s",\n' "$(json_escape "$cli_kind")"
  printf '  "bundledCLIVersion": "%s",\n' "$(json_escape "$cli_version")"
  printf '  "bundledProxy": "%s",\n' "$(json_escape "$APP_RESOURCES/raytone-proxy")"
  printf '  "bundledProxyBytes": %s,\n' "$proxy_bytes"
  printf '  "bundledProxySHA256": "%s",\n' "$proxy_sha256"
  printf '  "bundledProxyArchs": "%s",\n' "$(json_escape "$proxy_archs")"
  printf '  "bundledProxyKind": "%s",\n' "$(json_escape "$proxy_kind")"
  printf '  "bundledProxyVersion": "%s",\n' "$(json_escape "$proxy_version")"
  printf '  "openAICodexLicenseBytes": %s,\n' "$license_bytes"
  printf '  "openAICodexNoticeBytes": %s,\n' "$notice_bytes"
  printf '  "raytoneCodexCLINoticeBytes": %s,\n' "$cli_notice_bytes"
  printf '  "raytoneProxyNoticeBytes": %s,\n' "$proxy_notice_bytes"
  printf '  "ccSwitchLicenseBytes": %s,\n' "$proxy_license_bytes"
  printf '  "appIcon": "%s",\n' "$(json_escape "$APP_ICON")"
  printf '  "appIconBytes": %s,\n' "$icon_bytes"
  printf '  "appIconSHA256": "%s",\n' "$icon_sha"
  printf '  "releaseManifest": "%s",\n' "$(json_escape "$RELEASE_MANIFEST")"
  printf '  "releaseManifestBytes": %s,\n' "$manifest_bytes"
  printf '  "releaseManifestGeneratedAt": "%s",\n' "$(json_escape "$manifest_generated_at")"
  printf '  "releaseManifestOpenAICodexHead": "%s",\n' "$(json_escape "$manifest_head")"
  printf '  "signatureStatus": "%s",\n' "$signature_status"
  printf '  "appSigningAuthority": "%s",\n' "$(json_escape "${app_authority:-none}")"
  printf '  "bundledCLISigningAuthority": "%s",\n' "$(json_escape "${cli_authority:-none}")"
  printf '  "bundledProxySigningAuthority": "%s",\n' "$(json_escape "${proxy_authority:-none}")"
  printf '  "appHardenedRuntime": %s,\n' "$app_hardened_runtime"
  printf '  "bundledCLIHardenedRuntime": %s,\n' "$cli_hardened_runtime"
  printf '  "bundledProxyHardenedRuntime": %s,\n' "$proxy_hardened_runtime"
  printf '  "sourceCLI": "%s"\n' "$(json_escape "${CLI_SOURCE:-unknown}")"
  printf '}\n'
}

run_release_audit() {
  local app_authority cli_authority

  run_bundle_audit >/dev/null
  require_valid_signature "bundled Codex CLI" "$APP_RESOURCES/codex"
  require_valid_signature "bundled Raytone proxy" "$APP_RESOURCES/raytone-proxy"
  require_valid_signature "app bundle" "$APP_BUNDLE"
  require_hardened_runtime "bundled Codex CLI" "$APP_RESOURCES/codex"
  require_hardened_runtime "bundled Raytone proxy" "$APP_RESOURCES/raytone-proxy"
  require_hardened_runtime "app bundle" "$APP_BUNDLE"
  require_developer_id_signature "bundled Codex CLI" "$APP_RESOURCES/codex"
  require_developer_id_signature "bundled Raytone proxy" "$APP_RESOURCES/raytone-proxy"
  require_developer_id_signature "app bundle" "$APP_BUNDLE"

  /usr/sbin/spctl --assess --type execute --verbose=4 "$APP_BUNDLE" >/dev/null
  /usr/bin/xcrun stapler validate "$APP_BUNDLE" >/dev/null

  app_authority="$(codesign_authority "$APP_BUNDLE" || true)"
  cli_authority="$(codesign_authority "$APP_RESOURCES/codex" || true)"
  proxy_authority="$(codesign_authority "$APP_RESOURCES/raytone-proxy" || true)"

  printf '{\n'
  printf '  "ok": true,\n'
  printf '  "bundle": "%s",\n' "$(json_escape "$APP_BUNDLE")"
  printf '  "developerIdAppAuthority": "%s",\n' "$(json_escape "$app_authority")"
  printf '  "developerIdCLIAuthority": "%s",\n' "$(json_escape "$cli_authority")"
  printf '  "developerIdProxyAuthority": "%s",\n' "$(json_escape "$proxy_authority")"
  printf '  "hardenedRuntime": true,\n'
  printf '  "gatekeeperAssessment": "accepted",\n'
  printf '  "stapledNotarizationTicket": "valid"\n'
  printf '}\n'
}

packaged_app_cli_version() {
  local label="$1"
  local app_path="$2"
  local contents="$app_path/Contents"
  local resources="$contents/Resources"
  local cli="$resources/codex"
  local proxy="$resources/raytone-proxy"

  require_existing_path "$label app bundle" "$app_path"
  require_existing_path "$label Info.plist" "$contents/Info.plist"
  require_executable_path "$label app executable" "$contents/MacOS/$APP_NAME"
  require_executable_path "$label bundled Codex CLI" "$cli"
  require_executable_path "$label bundled Raytone proxy" "$proxy"
  require_nonempty_file "$label OpenAI Codex license" "$resources/OPENAI_CODEX_LICENSE.txt"
  require_nonempty_file "$label OpenAI Codex notice" "$resources/OPENAI_CODEX_NOTICE.txt"
  require_nonempty_file "$label RaytoneCodex CLI notice" "$resources/OPENAI_CODEX_CLI_NOTICE.txt"
  require_nonempty_file "$label Raytone proxy notice" "$resources/RAYTONE_PROXY_NOTICE.txt"
  require_nonempty_file "$label cc-switch MIT license" "$resources/CC_SWITCH_MIT_LICENSE.txt"
  require_nonempty_file "$label RaytoneCodex release manifest" "$resources/RaytoneCodexRelease.json"
  require_nonempty_file "$label app icon" "$resources/$APP_ICON_NAME.icns"

  if ! is_standalone_binary "$cli"; then
    echo "$label bundled Codex CLI is not a standalone binary: $cli" >&2
    return 1
  fi
  if ! is_standalone_binary "$proxy"; then
    echo "$label bundled Raytone proxy is not a standalone binary: $proxy" >&2
    return 1
  fi

  run_cli_version "$cli" | tr -d '\r'
}

packaged_app_executable_sha256() {
  local app_path="$1"
  file_sha256 "$app_path/Contents/MacOS/$APP_NAME"
}

packaged_app_cli_sha256() {
  local app_path="$1"
  file_sha256 "$app_path/Contents/Resources/codex"
}

packaged_app_proxy_sha256() {
  local app_path="$1"
  file_sha256 "$app_path/Contents/Resources/raytone-proxy"
}

packaged_app_icon_sha256() {
  local app_path="$1"
  file_sha256 "$app_path/Contents/Resources/$APP_ICON_NAME.icns"
}

audit_packaged_manifest() {
  local label="$1"
  local app_path="$2"
  local cli_version="$3"
  local manifest="$app_path/Contents/Resources/RaytoneCodexRelease.json"
  local icon_sha proxy_sha proxy_version
  icon_sha="$(packaged_app_icon_sha256 "$app_path")"
  proxy_sha="$(packaged_app_proxy_sha256 "$app_path")"
  proxy_version="$("$app_path/Contents/Resources/raytone-proxy" --version | tr -d '\r')"

  require_manifest_value "$manifest" "app.name" "$APP_NAME"
  require_manifest_value "$manifest" "app.bundleIdentifier" "$BUNDLE_ID"
  require_manifest_value "$manifest" "app.version" "$APP_VERSION"
  require_manifest_value "$manifest" "app.minimumSystemVersion" "$MIN_SYSTEM_VERSION"
  require_manifest_value "$manifest" "app.packageBasename" "$PACKAGE_BASENAME"
  require_manifest_value "$manifest" "app.icon" "Contents/Resources/$APP_ICON_NAME.icns"
  require_manifest_value "$manifest" "app.iconSHA256" "$icon_sha"
  require_manifest_value "$manifest" "codex.repository" "$OPENAI_CODEX_REPO"
  require_manifest_value "$manifest" "codex.bundledExecutable" "Contents/Resources/codex"
  require_manifest_value "$manifest" "codex.version" "$cli_version"
  require_manifest_value "$manifest" "sidecar.bundledExecutable" "Contents/Resources/raytone-proxy"
  require_manifest_value "$manifest" "sidecar.source" "sidecar/raytone-proxy"
  require_manifest_value "$manifest" "sidecar.version" "$proxy_version"
  require_manifest_value "$manifest" "sidecar.sha256" "$proxy_sha"
  require_manifest_value "$manifest" "notices.proxyNotice" "Contents/Resources/RAYTONE_PROXY_NOTICE.txt"
  require_manifest_value "$manifest" "notices.ccSwitchLicense" "Contents/Resources/CC_SWITCH_MIT_LICENSE.txt"
  require_manifest_nonempty_value "$manifest" "codex.observedHead"
  require_manifest_nonempty_value "$manifest" "codex.sourceCLI"
  require_manifest_nonempty_value "$manifest" "generatedAt"
}

make_zip_package() {
  local zip_bytes

  run_bundle_audit >/dev/null
  rm -f "$ZIP_ARTIFACT"
  (cd "$DIST_DIR" && /usr/bin/ditto -c -k --keepParent "$APP_NAME.app" "$ZIP_ARTIFACT")
  zip_bytes="$(/usr/bin/stat -f '%z' "$ZIP_ARTIFACT")"

  printf '{\n'
  printf '  "ok": true,\n'
  printf '  "zip": "%s",\n' "$(json_escape "$ZIP_ARTIFACT")"
  printf '  "zipBytes": %s,\n' "$zip_bytes"
  printf '  "contains": "%s.app"\n' "$APP_NAME"
  printf '}\n'
}

make_dmg_package() {
  local dmg_bytes

  run_bundle_audit >/dev/null
  rm -rf "$DMG_STAGING_DIR"
  rm -f "$DMG_ARTIFACT"
  mkdir -p "$DMG_STAGING_DIR"
  /usr/bin/ditto "$APP_BUNDLE" "$DMG_STAGING_DIR/$APP_NAME.app"
  /bin/ln -s /Applications "$DMG_STAGING_DIR/Applications"
  /usr/bin/hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING_DIR" \
    -ov -format UDZO "$DMG_ARTIFACT" >/dev/null
  dmg_bytes="$(/usr/bin/stat -f '%z' "$DMG_ARTIFACT")"

  printf '{\n'
  printf '  "ok": true,\n'
  printf '  "dmg": "%s",\n' "$(json_escape "$DMG_ARTIFACT")"
  printf '  "dmgBytes": %s,\n' "$dmg_bytes"
  printf '  "volumeName": "%s"\n' "$APP_NAME"
  printf '}\n'
}

run_package_audit() {
  local temp_root mountpoint zip_app dmg_app zip_bytes dmg_bytes zip_cli_version dmg_cli_version
  local dmg_has_applications_symlink
  local staged_app_sha staged_cli_sha staged_proxy_sha staged_icon_sha zip_app_sha zip_cli_sha zip_proxy_sha zip_icon_sha dmg_app_sha dmg_cli_sha dmg_proxy_sha dmg_icon_sha
  local zip_manifest_sha dmg_manifest_sha manifest_sha manifest_head

  require_nonempty_file "ZIP artifact" "$ZIP_ARTIFACT"
  require_nonempty_file "DMG artifact" "$DMG_ARTIFACT"
  staged_app_sha="$(file_sha256 "$APP_BINARY")"
  staged_cli_sha="$(file_sha256 "$APP_RESOURCES/codex")"
  staged_proxy_sha="$(file_sha256 "$APP_RESOURCES/raytone-proxy")"
  staged_icon_sha="$(file_sha256 "$APP_ICON")"
  manifest_sha="$(file_sha256 "$RELEASE_MANIFEST")"
  manifest_head="$(manifest_value "$RELEASE_MANIFEST" "codex.observedHead")"

  temp_root="$(mktemp -d)"
  mountpoint="$temp_root/dmg"
  mkdir -p "$mountpoint"

  cleanup_package_audit() {
    /usr/bin/hdiutil detach "$mountpoint" >/dev/null 2>&1 || true
    rm -rf "$temp_root"
  }
  trap cleanup_package_audit RETURN

  /usr/bin/ditto -x -k "$ZIP_ARTIFACT" "$temp_root/zip"
  zip_app="$temp_root/zip/$APP_NAME.app"
  zip_cli_version="$(packaged_app_cli_version "ZIP artifact" "$zip_app")"
  audit_packaged_manifest "ZIP artifact" "$zip_app" "$zip_cli_version"
  zip_app_sha="$(packaged_app_executable_sha256 "$zip_app")"
  zip_cli_sha="$(packaged_app_cli_sha256 "$zip_app")"
  zip_proxy_sha="$(packaged_app_proxy_sha256 "$zip_app")"
  zip_icon_sha="$(packaged_app_icon_sha256 "$zip_app")"
  zip_manifest_sha="$(file_sha256 "$zip_app/Contents/Resources/RaytoneCodexRelease.json")"
  if [[ "$zip_app_sha" != "$staged_app_sha" ]]; then
    echo "ZIP artifact app executable does not match the current staged app." >&2
    echo "staged: $staged_app_sha" >&2
    echo "zip:    $zip_app_sha" >&2
    return 1
  fi
  if [[ "$zip_cli_sha" != "$staged_cli_sha" ]]; then
    echo "ZIP artifact bundled CLI does not match the current staged CLI." >&2
    echo "staged: $staged_cli_sha" >&2
    echo "zip:    $zip_cli_sha" >&2
    return 1
  fi
  if [[ "$zip_proxy_sha" != "$staged_proxy_sha" ]]; then
    echo "ZIP artifact bundled Raytone proxy does not match the current staged proxy." >&2
    echo "staged: $staged_proxy_sha" >&2
    echo "zip:    $zip_proxy_sha" >&2
    return 1
  fi
  if [[ "$zip_icon_sha" != "$staged_icon_sha" ]]; then
    echo "ZIP artifact app icon does not match the current staged icon." >&2
    echo "staged: $staged_icon_sha" >&2
    echo "zip:    $zip_icon_sha" >&2
    return 1
  fi
  if [[ "$zip_manifest_sha" != "$manifest_sha" ]]; then
    echo "ZIP artifact release manifest does not match the current staged manifest." >&2
    echo "staged: $manifest_sha" >&2
    echo "zip:    $zip_manifest_sha" >&2
    return 1
  fi

  /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mountpoint" "$DMG_ARTIFACT" >/dev/null
  dmg_app="$mountpoint/$APP_NAME.app"
  dmg_cli_version="$(packaged_app_cli_version "DMG artifact" "$dmg_app")"
  audit_packaged_manifest "DMG artifact" "$dmg_app" "$dmg_cli_version"
  dmg_app_sha="$(packaged_app_executable_sha256 "$dmg_app")"
  dmg_cli_sha="$(packaged_app_cli_sha256 "$dmg_app")"
  dmg_proxy_sha="$(packaged_app_proxy_sha256 "$dmg_app")"
  dmg_icon_sha="$(packaged_app_icon_sha256 "$dmg_app")"
  dmg_manifest_sha="$(file_sha256 "$dmg_app/Contents/Resources/RaytoneCodexRelease.json")"
  if [[ "$dmg_app_sha" != "$staged_app_sha" ]]; then
    echo "DMG artifact app executable does not match the current staged app." >&2
    echo "staged: $staged_app_sha" >&2
    echo "dmg:    $dmg_app_sha" >&2
    return 1
  fi
  if [[ "$dmg_cli_sha" != "$staged_cli_sha" ]]; then
    echo "DMG artifact bundled CLI does not match the current staged CLI." >&2
    echo "staged: $staged_cli_sha" >&2
    echo "dmg:    $dmg_cli_sha" >&2
    return 1
  fi
  if [[ "$dmg_proxy_sha" != "$staged_proxy_sha" ]]; then
    echo "DMG artifact bundled Raytone proxy does not match the current staged proxy." >&2
    echo "staged: $staged_proxy_sha" >&2
    echo "dmg:    $dmg_proxy_sha" >&2
    return 1
  fi
  if [[ "$dmg_icon_sha" != "$staged_icon_sha" ]]; then
    echo "DMG artifact app icon does not match the current staged icon." >&2
    echo "staged: $staged_icon_sha" >&2
    echo "dmg:    $dmg_icon_sha" >&2
    return 1
  fi
  if [[ "$dmg_manifest_sha" != "$manifest_sha" ]]; then
    echo "DMG artifact release manifest does not match the current staged manifest." >&2
    echo "staged: $manifest_sha" >&2
    echo "dmg:    $dmg_manifest_sha" >&2
    return 1
  fi
  if [[ -L "$mountpoint/Applications" ]]; then
    dmg_has_applications_symlink=true
  else
    dmg_has_applications_symlink=false
  fi

  zip_bytes="$(/usr/bin/stat -f '%z' "$ZIP_ARTIFACT")"
  dmg_bytes="$(/usr/bin/stat -f '%z' "$DMG_ARTIFACT")"

  printf '{\n'
  printf '  "ok": true,\n'
  printf '  "zip": "%s",\n' "$(json_escape "$ZIP_ARTIFACT")"
  printf '  "zipBytes": %s,\n' "$zip_bytes"
  printf '  "zipAppExecutableSHA256": "%s",\n' "$zip_app_sha"
  printf '  "zipBundledCLISHA256": "%s",\n' "$zip_cli_sha"
  printf '  "zipBundledProxySHA256": "%s",\n' "$zip_proxy_sha"
  printf '  "zipAppIconSHA256": "%s",\n' "$zip_icon_sha"
  printf '  "zipReleaseManifestSHA256": "%s",\n' "$zip_manifest_sha"
  printf '  "zipBundledCLIVersion": "%s",\n' "$(json_escape "$zip_cli_version")"
  printf '  "dmg": "%s",\n' "$(json_escape "$DMG_ARTIFACT")"
  printf '  "dmgBytes": %s,\n' "$dmg_bytes"
  printf '  "dmgAppExecutableSHA256": "%s",\n' "$dmg_app_sha"
  printf '  "dmgBundledCLISHA256": "%s",\n' "$dmg_cli_sha"
  printf '  "dmgBundledProxySHA256": "%s",\n' "$dmg_proxy_sha"
  printf '  "dmgAppIconSHA256": "%s",\n' "$dmg_icon_sha"
  printf '  "dmgReleaseManifestSHA256": "%s",\n' "$dmg_manifest_sha"
  printf '  "dmgBundledCLIVersion": "%s",\n' "$(json_escape "$dmg_cli_version")"
  printf '  "releaseManifestOpenAICodexHead": "%s",\n' "$(json_escape "$manifest_head")"
  printf '  "matchesCurrentStagedApp": true,\n'
  printf '  "dmgHasApplicationsSymlink": %s\n' "$dmg_has_applications_symlink"
  printf '}\n'

  cleanup_package_audit
  trap - RETURN
}

acquire_stage_lock
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
for _ in {1..40}; do
  if [[ -z "$(pgrep -x "$APP_NAME" || true)" ]]; then
    break
  fi
  sleep 0.25
done
stage_app_bundle

case "$MODE" in
  run)
    if [[ -n "$APP_SIGN_IDENTITY" ]]; then
      open_app
      if wait_for_app; then
        app_pid="$(first_app_pid)"
        if window_info="$(wait_for_window_for_pid "$app_pid")"; then
          eval "$window_info"
          echo "Launched $APP_NAME PID $app_pid from $APP_BUNDLE with onscreen window ${WINDOW_WIDTH}x${WINDOW_HEIGHT}."
        else
          echo "Launched $APP_NAME PID $app_pid from $APP_BUNDLE."
        fi
        exit 0
      fi

      echo "$APP_NAME did not remain running after LaunchServices open." >&2
      cat "$LAUNCH_LOG" >&2 || true
      exit 1
    else
      echo "Trying to launch unsigned staged app from $APP_BUNDLE." >&2
      open_app || true
      if wait_for_app; then
        app_pid="$(first_app_pid)"
        if window_info="$(wait_for_window_for_pid "$app_pid")"; then
          eval "$window_info"
          echo "Launched $APP_NAME PID $app_pid from $APP_BUNDLE with onscreen window ${WINDOW_WIDTH}x${WINDOW_HEIGHT}."
        else
          echo "Launched $APP_NAME PID $app_pid from $APP_BUNDLE."
        fi
        exit 0
      fi

      echo "LaunchServices did not keep the unsigned staged app running; falling back to direct development binary." >&2
      echo "Launching the SwiftUI binary with the staged local CLI from $DEV_CLI." >&2
      app_pid="$(run_development_binary_detached)"
      if window_info="$(wait_for_window_for_pid "$app_pid")"; then
        eval "$window_info"
        echo "Launched $APP_NAME PID $app_pid with onscreen window ${WINDOW_WIDTH}x${WINDOW_HEIGHT}."
        exit 0
      fi

      if ! ps -p "$app_pid" >/dev/null 2>&1; then
        echo "$APP_NAME exited before its UI window appeared." >&2
      else
        echo "No onscreen $APP_NAME window was found for PID $app_pid." >&2
      fi
      cat "$LAUNCH_LOG" >&2 || true
      exit 1
    fi
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    if [[ -n "$APP_SIGN_IDENTITY" ]]; then
      open_app || true
      if wait_for_app; then
        run_cli_version "$APP_RESOURCES/codex"
        exit 0
      fi

      echo "$APP_NAME did not remain running after LaunchServices open." >&2
      /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" >&2 || true
      /usr/sbin/spctl --assess --type execute --verbose=4 "$APP_BUNDLE" >&2 || true
      /usr/bin/log show --last 2m --style compact \
        --predicate "eventMessage CONTAINS \"$APP_NAME\" OR process == \"$APP_NAME\" OR senderImagePath CONTAINS \"$APP_NAME\"" \
        | tail -80 >&2 || true
      exit 1
    fi

    echo "Skipping LaunchServices verification: no trusted codesigning identity is installed." >&2
    echo "macOS blocks executables inside unsigned .app containers on this machine." >&2
    echo "Launching the SwiftUI binary with the staged local CLI from $DEV_CLI." >&2
    run_cli_version "$DEV_CLI"
    run_development_binary
    if wait_for_app; then
      exit 0
    fi

    echo "$APP_NAME did not remain running after direct development launch." >&2
    cat "$LAUNCH_LOG" >&2 || true
    exit 1
    ;;
  --cli-smoke|cli-smoke)
    /usr/bin/env RAYTONE_CODEX_CLI="$(local_cli_for_verification)" "$BUILD_BINARY" \
      --cli-smoke-test \
      --workspace "$ROOT_DIR" \
      --prompt "${RAYTONE_CODEX_SMOKE_PROMPT:-Reply exactly: RaytoneCodex bundled CLI smoke OK}"
    ;;
  --session-smoke|session-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --session-smoke-test \
      --workspace "$ROOT_DIR" \
      --prompt "${RAYTONE_CODEX_SESSION_SMOKE_PROMPT:-Reply exactly: RaytoneCodex session smoke OK}"
    ;;
  --history-smoke|history-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --history-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --side-chat-smoke|side-chat-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --side-chat-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --environment-smoke|environment-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_PROXY="$(local_proxy_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --environment-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --config-write-smoke|config-write-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --config-write-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --thread-management-smoke|thread-management-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --thread-management-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --tools-smoke|tools-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --tools-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --terminal-stream-smoke|terminal-stream-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --terminal-stream-smoke-test
    ;;
  --file-search-smoke|file-search-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --file-search-smoke-test
    ;;
  --local-image-input-smoke|local-image-input-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --local-image-input-smoke-test
    ;;
  --review-smoke|review-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --review-smoke-test
    ;;
  --slash-smoke|slash-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --slash-smoke-test
    ;;
  --catalog-smoke|catalog-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --catalog-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --account-auth-smoke|account-auth-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --account-auth-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --connection-recovery-smoke|connection-recovery-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --connection-recovery-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --account-api-key-smoke|account-api-key-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --account-api-key-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --add-credits-nudge-smoke|add-credits-nudge-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --add-credits-nudge-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --experimental-features-smoke|experimental-features-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --experimental-features-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --mention-smoke|mention-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --mention-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --plugin-read-smoke|plugin-read-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --plugin-read-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --plugin-scaffold-smoke|plugin-scaffold-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --plugin-scaffold-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --plugin-install-response-smoke|plugin-install-response-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --plugin-install-response-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --codex-home-directory-smoke|codex-home-directory-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --codex-home-directory-smoke-test
    ;;
  --mcp-resource-smoke|mcp-resource-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --mcp-resource-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --mcp-tool-smoke|mcp-tool-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --mcp-tool-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --runtime-pages-smoke|runtime-pages-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --runtime-pages-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --sample-data-gate-smoke|sample-data-gate-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_ENABLE_SAMPLE_DATA="" \
      RAYTONE_CODEX_UI_SCREEN="" \
      "$BUILD_BINARY" \
      --sample-data-gate-smoke-test
    /usr/bin/env \
      RAYTONE_CODEX_ENABLE_SAMPLE_DATA="1" \
      RAYTONE_CODEX_UI_SCREEN="" \
      "$BUILD_BINARY" \
      --sample-data-gate-smoke-test \
      --expect-samples
    ;;
  --usage-activity-smoke|usage-activity-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --usage-activity-smoke-test
    ;;
  --settings-project-smoke|settings-project-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --settings-project-smoke-test
    ;;
  --automation-smoke|automation-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --automation-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --automation-hook-smoke|automation-hook-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --automation-hook-smoke-test
    ;;
  --hook-controls-smoke|hook-controls-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --hook-controls-smoke-test
    ;;
  --integration-pages-smoke|integration-pages-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --integration-pages-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --project-switch-smoke|project-switch-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --project-switch-smoke-test
    ;;
  --workspace-switch-smoke|workspace-switch-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --workspace-switch-smoke-test
    ;;
  --remote-control-smoke|remote-control-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --remote-control-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --realtime-voices-smoke|realtime-voices-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --realtime-voices-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --access-mode-smoke|access-mode-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --access-mode-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --personality-smoke|personality-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --personality-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --model-catalog-smoke|model-catalog-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --model-catalog-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --model-provider-capabilities-smoke|model-provider-capabilities-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --model-provider-capabilities-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --external-agent-config-smoke|external-agent-config-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --external-agent-config-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --app-list-updated-smoke|app-list-updated-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --app-list-updated-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --model-config-smoke|model-config-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --model-config-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --provider-sidecar-smoke|provider-sidecar-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      RAYTONE_PROXY="$RAYTONE_PROXY_BINARY" \
      "$BUILD_BINARY" \
      --provider-sidecar-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --reasoning-config-smoke|reasoning-config-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --reasoning-config-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --instructions-config-smoke|instructions-config-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --instructions-config-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --default-permissions-smoke|default-permissions-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --default-permissions-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --auto-review-smoke|auto-review-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --auto-review-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --service-tier-smoke|service-tier-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --service-tier-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --memory-settings-smoke|memory-settings-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --memory-settings-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --work-mode-smoke|work-mode-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --work-mode-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --desktop-settings-smoke|desktop-settings-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --desktop-settings-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --open-target-smoke|open-target-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --open-target-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --prevent-sleep-smoke|prevent-sleep-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --prevent-sleep-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --goal-smoke|goal-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --goal-smoke-test \
      --workspace "$ROOT_DIR"
    ;;
  --browser-navigation-smoke|browser-navigation-smoke)
    /usr/bin/env \
      RAYTONE_CODEX_CLI="$(local_cli_for_verification)" \
      RAYTONE_CODEX_WORKSPACE="$ROOT_DIR" \
      "$BUILD_BINARY" \
      --browser-navigation-smoke-test
    ;;
  --browser-snapshot-smoke|browser-snapshot-smoke)
    run_browser_snapshot_smoke
    ;;
  --settings-browser-snapshot-smoke|settings-browser-snapshot-smoke)
    run_settings_browser_snapshot_smoke
    ;;
  --ui-smoke|ui-smoke)
    run_ui_smoke
    ;;
  --bundle-audit|bundle-audit)
    run_bundle_audit
    ;;
  --release-audit|release-audit)
    run_release_audit
    ;;
  --package-zip|package-zip)
    make_zip_package
    ;;
  --package-dmg|package-dmg)
    make_dmg_package
    ;;
  --package-audit|package-audit)
    run_package_audit
    ;;
  --package|package)
    make_zip_package >/dev/null
    make_dmg_package >/dev/null
    run_package_audit
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--cli-smoke|--session-smoke|--history-smoke|--side-chat-smoke|--environment-smoke|--config-write-smoke|--thread-management-smoke|--tools-smoke|--terminal-stream-smoke|--file-search-smoke|--local-image-input-smoke|--review-smoke|--slash-smoke|--catalog-smoke|--account-auth-smoke|--connection-recovery-smoke|--account-api-key-smoke|--add-credits-nudge-smoke|--experimental-features-smoke|--mention-smoke|--plugin-read-smoke|--plugin-scaffold-smoke|--plugin-install-response-smoke|--codex-home-directory-smoke|--mcp-resource-smoke|--mcp-tool-smoke|--runtime-pages-smoke|--sample-data-gate-smoke|--usage-activity-smoke|--settings-project-smoke|--automation-smoke|--automation-hook-smoke|--hook-controls-smoke|--integration-pages-smoke|--project-switch-smoke|--workspace-switch-smoke|--remote-control-smoke|--realtime-voices-smoke|--access-mode-smoke|--personality-smoke|--model-catalog-smoke|--model-provider-capabilities-smoke|--external-agent-config-smoke|--app-list-updated-smoke|--model-config-smoke|--provider-sidecar-smoke|--reasoning-config-smoke|--instructions-config-smoke|--default-permissions-smoke|--auto-review-smoke|--service-tier-smoke|--memory-settings-smoke|--work-mode-smoke|--desktop-settings-smoke|--open-target-smoke|--prevent-sleep-smoke|--goal-smoke|--browser-navigation-smoke|--browser-snapshot-smoke|--settings-browser-snapshot-smoke|--ui-smoke|--bundle-audit|--release-audit|--package|--package-zip|--package-dmg|--package-audit]" >&2
    exit 2
    ;;
esac
