#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

swift build
swift run RaytoneCodexCoreChecks
"$ROOT_DIR/script/check_app_server_methods.sh"
"$ROOT_DIR/script/check_ui_runtime_wiring.sh"

if [[ "${RAYTONE_CODEX_RUN_RUNTIME_SMOKE:-0}" == "1" ]]; then
  "$ROOT_DIR/script/check_runtime_smoke_core.sh"
fi
