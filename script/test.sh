#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

swift build
swift run RaytoneCodexCoreChecks
"$ROOT_DIR/script/check_app_server_methods.sh"
"$ROOT_DIR/script/check_ui_runtime_wiring.sh"
