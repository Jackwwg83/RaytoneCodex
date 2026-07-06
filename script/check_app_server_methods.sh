#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STABLE_SCHEMA="$ROOT_DIR/Schemas/codex_app_server_protocol.v2.schemas.json"
EXPERIMENTAL_SCHEMA="$ROOT_DIR/Schemas/experimental/codex_app_server_protocol.v2.schemas.json"
SWIFT_CLIENT="$ROOT_DIR/Sources/RaytoneCodexCore/Services/CodexAppServerClient.swift"

if [[ ! -f "$STABLE_SCHEMA" ]]; then
  echo "missing stable schema: $STABLE_SCHEMA" >&2
  exit 2
fi
if [[ ! -f "$EXPERIMENTAL_SCHEMA" ]]; then
  echo "missing experimental schema: $EXPERIMENTAL_SCHEMA" >&2
  echo "run: codex app-server generate-json-schema --experimental --out Schemas/experimental" >&2
  exit 2
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/raytone-app-server-methods.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

jq -r '.definitions.ClientRequest.oneOf[]?.properties.method.enum[]?' "$STABLE_SCHEMA" |
  sort -u >"$tmp_dir/stable_methods"
jq -r '.definitions.ClientRequest.oneOf[]?.properties.method.enum[]?' "$EXPERIMENTAL_SCHEMA" |
  sort -u >"$tmp_dir/experimental_methods"
cat "$tmp_dir/stable_methods" "$tmp_dir/experimental_methods" |
  sort -u >"$tmp_dir/allowed_methods"

rg -o 'request\(method: "[^"]+"' "$SWIFT_CLIENT" |
  sed -E 's/.*"([^"]+)"/\1/' |
  sort -u >"$tmp_dir/swift_methods"

comm -23 "$tmp_dir/swift_methods" "$tmp_dir/allowed_methods" >"$tmp_dir/missing"

stable_count="$(wc -l <"$tmp_dir/stable_methods" | tr -d ' ')"
experimental_count="$(wc -l <"$tmp_dir/experimental_methods" | tr -d ' ')"
swift_count="$(wc -l <"$tmp_dir/swift_methods" | tr -d ' ')"
missing_count="$(wc -l <"$tmp_dir/missing" | tr -d ' ')"

if [[ "$missing_count" != "0" ]]; then
  echo "Swift app-server methods missing from generated schemas:" >&2
  cat "$tmp_dir/missing" >&2
  echo "{\"ok\":false,\"stableMethods\":$stable_count,\"experimentalMethods\":$experimental_count,\"swiftMethods\":$swift_count,\"missingMethods\":$missing_count}"
  exit 1
fi

echo "{\"ok\":true,\"stableMethods\":$stable_count,\"experimentalMethods\":$experimental_count,\"swiftMethods\":$swift_count,\"missingMethods\":0}"
