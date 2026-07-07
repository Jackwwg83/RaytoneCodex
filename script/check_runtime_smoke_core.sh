#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

default_cases=(
  model-config-smoke
  config-write-smoke
  reasoning-config-smoke
  instructions-config-smoke
  service-tier-smoke
  memory-settings-smoke
  desktop-settings-smoke
  open-target-smoke
  prevent-sleep-smoke
  access-mode-smoke
  new-thread-permissions-smoke
  default-permissions-smoke
  auto-review-smoke
  approval-compat-smoke
  guardian-denial-approve-smoke
  tool-user-input-smoke
  auth-attestation-smoke
  provider-sidecar-smoke
  model-provider-capabilities-smoke
  model-catalog-smoke
  provider-onboarding-smoke
  provider-unauthorized-smoke
  external-agent-config-smoke
  usage-activity-smoke
  account-auth-smoke
  account-device-code-smoke
  account-api-key-smoke
  profile-privacy-smoke
  profile-share-smoke
  add-credits-nudge-smoke
  feedback-upload-smoke
  settings-project-smoke
  settings-scene-smoke
  runtime-pages-smoke
  command-surface-smoke
  sample-data-gate-smoke
  experimental-features-smoke
  catalog-smoke
  plugin-read-smoke
  plugin-install-response-smoke
  plugin-share-smoke
  marketplace-upgrade-smoke
  skill-read-smoke
  skill-extra-roots-smoke
  skill-toggle-smoke
  automation-smoke
  automation-hook-smoke
  hook-notification-smoke
  app-mention-config-smoke
  app-list-updated-smoke
  file-change-stream-smoke
  runtime-diagnostics-smoke
  app-server-notification-smoke
  mcp-resource-smoke
  mcp-tool-smoke
  mcp-login-smoke
  mcp-elicitation-smoke
  browser-navigation-smoke
  browser-clear-data-smoke
  browser-snapshot-input-smoke
  file-search-smoke
  local-image-input-smoke
  file-mention-turn-smoke
  app-mention-turn-smoke
  slash-smoke
  review-smoke
  terminal-stream-smoke
  terminal-resize-smoke
  process-stream-smoke
  thread-management-smoke
  thread-lifecycle-smoke
  thread-bootstrap-actions-smoke
  history-smoke
  thread-resume-smoke
  loaded-threads-smoke
  thread-unsubscribe-smoke
  thread-metadata-smoke
  thread-memory-mode-smoke
  work-mode-smoke
  project-switch-smoke
  workspace-switch-smoke
  branch-switch-smoke
  worktree-switch-smoke
  realtime-voices-smoke
  realtime-session-smoke
  runtime-environment-smoke
  connection-recovery-smoke
  home-connection-actions-smoke
  remote-control-smoke
  remote-control-mode-smoke
  remote-control-revoke-smoke
  personality-smoke
  windows-sandbox-smoke
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
