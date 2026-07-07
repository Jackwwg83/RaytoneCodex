#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STABLE_ROOT_SCHEMA="$ROOT_DIR/Schemas/codex_app_server_protocol.schemas.json"
EXPERIMENTAL_ROOT_SCHEMA="$ROOT_DIR/Schemas/experimental/codex_app_server_protocol.schemas.json"
STABLE_SCHEMA="$ROOT_DIR/Schemas/codex_app_server_protocol.v2.schemas.json"
EXPERIMENTAL_SCHEMA="$ROOT_DIR/Schemas/experimental/codex_app_server_protocol.v2.schemas.json"
STABLE_SPLIT_SCHEMA_DIR="$ROOT_DIR/Schemas/v2"
EXPERIMENTAL_SPLIT_SCHEMA_DIR="$ROOT_DIR/Schemas/experimental/v2"
SWIFT_CLIENT="$ROOT_DIR/Sources/RaytoneCodexCore/Services/CodexAppServerClient.swift"
SESSION_STORE="$ROOT_DIR/Sources/RaytoneCodex/Stores/SessionStore.swift"

if [[ ! -f "$STABLE_ROOT_SCHEMA" ]]; then
  echo "missing stable root schema: $STABLE_ROOT_SCHEMA" >&2
  exit 2
fi
if [[ ! -f "$EXPERIMENTAL_ROOT_SCHEMA" ]]; then
  echo "missing experimental root schema: $EXPERIMENTAL_ROOT_SCHEMA" >&2
  echo "run: codex app-server generate-json-schema --experimental --out Schemas/experimental" >&2
  exit 2
fi
if [[ ! -f "$STABLE_SCHEMA" ]]; then
  echo "missing stable schema: $STABLE_SCHEMA" >&2
  exit 2
fi
if [[ ! -f "$EXPERIMENTAL_SCHEMA" ]]; then
  echo "missing experimental schema: $EXPERIMENTAL_SCHEMA" >&2
  echo "run: codex app-server generate-json-schema --experimental --out Schemas/experimental" >&2
  exit 2
fi
if [[ ! -f "$SWIFT_CLIENT" ]]; then
  echo "missing Swift client: $SWIFT_CLIENT" >&2
  exit 2
fi
if [[ ! -f "$SESSION_STORE" ]]; then
  echo "missing SessionStore: $SESSION_STORE" >&2
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

printf '%s\n' \
  "mock/experimentalMethod" \
  | sort -u >"$tmp_dir/client_allowlist"

rg -o 'request\(method: "[^"]+"' "$SWIFT_CLIENT" |
  sed -E 's/.*"([^"]+)"/\1/' |
  sort -u >"$tmp_dir/swift_methods"

comm -23 "$tmp_dir/swift_methods" "$tmp_dir/allowed_methods" >"$tmp_dir/swift_not_in_schema"
comm -23 "$tmp_dir/allowed_methods" "$tmp_dir/swift_methods" >"$tmp_dir/schema_not_in_swift_raw"
comm -23 "$tmp_dir/schema_not_in_swift_raw" "$tmp_dir/client_allowlist" >"$tmp_dir/schema_not_in_swift"

jq -r '.definitions.ServerNotification.oneOf[]?.properties.method.enum[]?' "$STABLE_SCHEMA" "$EXPERIMENTAL_SCHEMA" |
  sort -u >"$tmp_dir/server_notifications"

: >"$tmp_dir/unhandled_notifications"
while IFS= read -r method; do
  if ! rg -Fq "\"$method\"" "$SESSION_STORE"; then
    echo "$method" >>"$tmp_dir/unhandled_notifications"
  fi
done <"$tmp_dir/server_notifications"

jq -r '.definitions.ServerRequest.oneOf[]?.properties.method.enum[]?' "$STABLE_ROOT_SCHEMA" "$EXPERIMENTAL_ROOT_SCHEMA" |
  sort -u >"$tmp_dir/server_requests"

: >"$tmp_dir/unhandled_server_requests"
while IFS= read -r method; do
  if ! rg -Fq "\"$method\"" "$SESSION_STORE"; then
    echo "$method" >>"$tmp_dir/unhandled_server_requests"
  fi
done <"$tmp_dir/server_requests"

check_split_schema_titles() {
  local root_schema="$1"
  local split_dir="$2"
  local output="$3"

  : >"$output"
  [[ -d "$split_dir" ]] || return 0

  while IFS= read -r file; do
    local title
    title="$(jq -r '.title // empty' "$file")"
    if [[ -z "$title" ]]; then
      printf '%s:<missing title>\n' "${file#$ROOT_DIR/}" >>"$output"
      continue
    fi
    if ! jq -e --arg title "$title" '.definitions[$title] != null' "$root_schema" >/dev/null; then
      printf '%s:%s\n' "${file#$ROOT_DIR/}" "$title" >>"$output"
    fi
  done < <(find "$split_dir" -maxdepth 1 -type f -name '*.json' | sort)
}

check_split_schema_titles "$STABLE_SCHEMA" "$STABLE_SPLIT_SCHEMA_DIR" "$tmp_dir/stale_stable_split_schemas"
check_split_schema_titles "$EXPERIMENTAL_SCHEMA" "$EXPERIMENTAL_SPLIT_SCHEMA_DIR" "$tmp_dir/stale_experimental_split_schemas"
cat "$tmp_dir/stale_stable_split_schemas" "$tmp_dir/stale_experimental_split_schemas" \
  >"$tmp_dir/stale_split_schemas"

stable_count="$(wc -l <"$tmp_dir/stable_methods" | tr -d ' ')"
experimental_count="$(wc -l <"$tmp_dir/experimental_methods" | tr -d ' ')"
schema_count="$(wc -l <"$tmp_dir/allowed_methods" | tr -d ' ')"
swift_count="$(wc -l <"$tmp_dir/swift_methods" | tr -d ' ')"
swift_not_in_schema_count="$(wc -l <"$tmp_dir/swift_not_in_schema" | tr -d ' ')"
schema_not_in_swift_count="$(wc -l <"$tmp_dir/schema_not_in_swift" | tr -d ' ')"
notification_count="$(wc -l <"$tmp_dir/server_notifications" | tr -d ' ')"
unhandled_notification_count="$(wc -l <"$tmp_dir/unhandled_notifications" | tr -d ' ')"
server_request_count="$(wc -l <"$tmp_dir/server_requests" | tr -d ' ')"
unhandled_server_request_count="$(wc -l <"$tmp_dir/unhandled_server_requests" | tr -d ' ')"
stale_split_schema_count="$(wc -l <"$tmp_dir/stale_split_schemas" | tr -d ' ')"

if [[ "$swift_not_in_schema_count" != "0" ]]; then
  echo "Swift app-server methods missing from generated schemas:" >&2
  cat "$tmp_dir/swift_not_in_schema" >&2
fi
if [[ "$schema_not_in_swift_count" != "0" ]]; then
  echo "Generated client methods not wrapped by Swift client:" >&2
  cat "$tmp_dir/schema_not_in_swift" >&2
fi
if [[ "$unhandled_notification_count" != "0" ]]; then
  echo "Generated server notifications not referenced by SessionStore:" >&2
  cat "$tmp_dir/unhandled_notifications" >&2
fi
if [[ "$unhandled_server_request_count" != "0" ]]; then
  echo "Generated server requests not referenced by SessionStore:" >&2
  cat "$tmp_dir/unhandled_server_requests" >&2
fi
if [[ "$stale_split_schema_count" != "0" ]]; then
  echo "Split schema files not present in matching generated root schema:" >&2
  cat "$tmp_dir/stale_split_schemas" >&2
fi

if [[ "$swift_not_in_schema_count" != "0" ||
      "$schema_not_in_swift_count" != "0" ||
      "$unhandled_notification_count" != "0" ||
      "$unhandled_server_request_count" != "0" ||
      "$stale_split_schema_count" != "0" ]]; then
  echo "{\"ok\":false,\"stableMethods\":$stable_count,\"experimentalMethods\":$experimental_count,\"schemaMethods\":$schema_count,\"swiftMethods\":$swift_count,\"swiftNotInSchema\":$swift_not_in_schema_count,\"schemaNotInSwift\":$schema_not_in_swift_count,\"serverNotifications\":$notification_count,\"unhandledNotifications\":$unhandled_notification_count,\"serverRequests\":$server_request_count,\"unhandledServerRequests\":$unhandled_server_request_count,\"staleSplitSchemas\":$stale_split_schema_count}"
  exit 1
fi

echo "{\"ok\":true,\"stableMethods\":$stable_count,\"experimentalMethods\":$experimental_count,\"schemaMethods\":$schema_count,\"swiftMethods\":$swift_count,\"swiftNotInSchema\":0,\"schemaNotInSwift\":0,\"clientAllowlisted\":1,\"serverNotifications\":$notification_count,\"unhandledNotifications\":0,\"serverRequests\":$server_request_count,\"unhandledServerRequests\":0,\"staleSplitSchemas\":0}"
