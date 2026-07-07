#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

default_cases=(
  model-config-smoke
  file-search-smoke
  home-connection-actions-smoke
  side-chat-injection-smoke
  thread-shell-command-smoke
  dynamic-tool-smoke
)

if [[ "$#" -gt 0 ]]; then
  cases=("$@")
else
  cases=("${default_cases[@]}")
fi

artifact_root="$ROOT_DIR/artifacts/runtime-smoke-core"
artifact_dir="$artifact_root/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$artifact_dir"

report="$artifact_dir/report.json"
overall_ok=true
case_index=0

printf '{\n' >"$report"
printf '  "ok": false,\n' >>"$report"
printf '  "artifactDir": "%s",\n' "$(json_escape "$artifact_dir")" >>"$report"
printf '  "cases": [\n' >>"$report"

for raw_case in "${cases[@]}"; do
  case_name="${raw_case#--}"
  flag="--$case_name"
  stdout_file="$artifact_dir/$case_name.stdout.log"
  stderr_file="$artifact_dir/$case_name.stderr.log"
  started_seconds="$(date +%s)"
  status=0

  echo "runtime-smoke-core: $case_name" >&2
  if bash "$ROOT_DIR/script/build_and_run.sh" "$flag" >"$stdout_file" 2>"$stderr_file"; then
    status=0
  else
    status="$?"
    overall_ok=false
  fi

  ended_seconds="$(date +%s)"
  duration_seconds="$((ended_seconds - started_seconds))"
  if /usr/bin/grep -Eq '"ok"[[:space:]]*:[[:space:]]*true' "$stdout_file"; then
    reported_ok=true
  else
    reported_ok=false
    overall_ok=false
  fi

  if [[ "$status" == "0" && "$reported_ok" == "true" ]]; then
    case_ok=true
  else
    case_ok=false
  fi

  if [[ "$case_index" -gt 0 ]]; then
    printf ',\n' >>"$report"
  fi
  printf '    {\n' >>"$report"
  printf '      "name": "%s",\n' "$(json_escape "$case_name")" >>"$report"
  printf '      "ok": %s,\n' "$case_ok" >>"$report"
  printf '      "exitCode": %s,\n' "$status" >>"$report"
  printf '      "reportedOk": %s,\n' "$reported_ok" >>"$report"
  printf '      "durationSeconds": %s,\n' "$duration_seconds" >>"$report"
  printf '      "stdout": "%s",\n' "$(json_escape "$stdout_file")" >>"$report"
  printf '      "stderr": "%s"\n' "$(json_escape "$stderr_file")" >>"$report"
  printf '    }' >>"$report"
  case_index="$((case_index + 1))"
done

printf '\n  ]\n' >>"$report"
printf '}\n' >>"$report"

tmp_report="$report.tmp"
if [[ "$overall_ok" == "true" ]]; then
  sed 's/"ok": false,/"ok": true,/' "$report" >"$tmp_report"
else
  cp "$report" "$tmp_report"
fi
mv "$tmp_report" "$report"

cat "$report"

if [[ "$overall_ok" != "true" ]]; then
  exit 1
fi
