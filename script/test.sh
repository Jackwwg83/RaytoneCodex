#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

swift run RaytoneCodexCoreChecks
"$ROOT_DIR/script/check_app_server_methods.sh"
