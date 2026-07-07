# RaytoneCodex Runtime Wiring Matrix

This matrix is the product-side contract for keeping the Codex-style UI backed by the open-source Codex runtime instead of static screens. Each listed surface must have a store action, an app-server or Codex runtime method, and a smoke test or artifact that proves the path ran.

## Thread And Composer

| UI surface | Runtime backing | Evidence |
| --- | --- | --- |
| Main composer run / stop | `thread/start`, `turn/start`, `turn/steer`, `turn/interrupt` | `--session-smoke-test`, `--interrupt-smoke-test` |
| Slash commands and review | `command/exec`, `review/start`, `/diff`, `/test`, `/commit`, `/pr`, `/goal` | `--slash-smoke-test`, `--review-smoke-test`, `--goal-smoke-test` |
| Mentions and local images | `app/list`, `input` mention items, local image items | `--mention-smoke-test`, `--app-mention-turn-smoke-test`, `--file-mention-turn-smoke-test`, `--local-image-input-smoke-test` |
| Access mode and approvals | `thread/settings/update`, `item/commandExecution/requestApproval`, `item/fileChange/requestApproval`, `item/permissions/requestApproval`, `serverRequest/resolved` | `--access-mode-smoke-test`, `--new-thread-permissions-smoke-test`, `--approval-compat-smoke-test` |
| Thread menu actions | `thread/name/set`, `thread/fork`, `thread/rollback`, `thread/compact/start`, `thread/archive`, `thread/unarchive` | `--thread-management-smoke-test`, `--thread-lifecycle-smoke-test`, `--thread-bootstrap-actions-smoke-test` |

## Tool Panels

| UI surface | Runtime backing | Evidence |
| --- | --- | --- |
| Tool launcher / environment info | `thread/loaded/list`, `thread/metadata/update`, `thread/goal/get`, `command/exec git`, `gh pr view` | `--environment-smoke-test`, `--loaded-threads-smoke-test`, `--thread-metadata-smoke-test` |
| Browser panel | `WKWebView`, `fs/getMetadata`, browser snapshot writer, local image attachment | `--browser-navigation-smoke-test`, `--browser-snapshot-smoke-test`, `--browser-snapshot-input-smoke-test` |
| Files panel | `fs/readDirectory`, `fs/watch`, `fs/readFile`, `fs/writeFile`, `fs/createDirectory`, `fs/copy`, `fs/remove`, `fuzzyFileSearch` | `--tools-smoke-test`, `--file-search-smoke-test`, `--file-change-stream-smoke-test` |
| Terminal panel | `command/exec`, `command/exec/write`, `command/exec/resize`, `command/exec/terminate`, `thread/shellCommand` | `--terminal-stream-smoke-test`, `--terminal-resize-smoke-test`, `--thread-shell-command-smoke-test` |
| Side chat | `thread/inject_items`, `turn/start`, `turn/steer` | `--side-chat-smoke-test`, `--side-chat-injection-smoke-test` |

## Settings

| Pane | Runtime backing | Evidence |
| --- | --- | --- |
| General / Appearance / Configuration | `config/read`, `config/value/write`, `config/batchWrite`, `thread/settings/update`, `collaborationMode/list` | `--config-write-smoke-test`, `--work-mode-smoke-test`, `--desktop-settings-smoke-test` |
| Models and providers | `model/list`, `modelProvider/capabilities/read`, `raytone-proxy /health`, `raytone-proxy /usage`, Keychain API | `--model-catalog-smoke-test`, `--model-provider-capabilities-smoke-test`, `--provider-sidecar-smoke-test`, `--provider-onboarding-smoke-test` |
| Account, profile, usage, billing | `account/read`, `account/login/start`, `account/login/cancel`, `account/logout`, `account/usage/read`, `account/rateLimits/read`, `account/sendAddCreditsNudgeEmail` | `--account-auth-smoke-test`, `--profile-share-smoke-test`, `--profile-privacy-smoke-test`, `--usage-activity-smoke-test`, `--add-credits-nudge-smoke-test` |
| Personalization and memory | `developer_instructions`, `desktop.raytone.commit_instructions`, `desktop.raytone.pull_request_instructions`, `memory/reset`, `thread/memoryMode/set` | `--instructions-config-smoke-test`, `--memory-settings-smoke-test`, `--thread-memory-mode-smoke-test`, `--personality-smoke-test` |
| MCP and apps | `mcpServerStatus/list`, `config/mcpServer/reload`, `mcpServer/oauth/login`, `mcpServer/tool/call`, `mcpServer/resource/read`, `app/list`, `app/setEnabled` | `--mcp-login-smoke-test`, `--mcp-tool-smoke-test`, `--mcp-resource-smoke-test`, `--integration-pages-smoke-test`, `--app-list-updated-smoke-test` |
| Hooks and automation | `hooks/list`, `config/value/write`, `fs/readFile`, `UserPromptSubmit` JSONL | `--automation-hook-smoke-test`, `--hook-controls-smoke-test`, `--hook-notification-smoke-test` |
| Git, worktrees, environments | `command/exec`, `environment/add`, `permissionProfile/list`, `configRequirements/read`, `git worktree list` | `--git-push-smoke-test`, `--git-pr-create-smoke-test`, `--runtime-environment-smoke-test`, `--worktree-switch-smoke-test` |
| External agent migration | `externalAgentConfig/detect`, `externalAgentConfig/import`, `externalAgentConfig/import/completed` | `--external-agent-config-smoke-test`, `--external-agent-real-smoke-test` |

## Plugins And Skills

| UI surface | Runtime backing | Evidence |
| --- | --- | --- |
| Plugin catalog and details | `plugin/list`, `plugin/installed`, `plugin/read`, `plugin/skill/read`, `skills/list` | `--plugin-read-smoke-test`, `--skill-read-smoke-test` |
| Install, scaffold, extra roots | `plugin/install`, `plugin/uninstall`, `skills/config/write`, `skills/extraRoots/set`, `fs/writeFile`, `fs/readFile` | `--plugin-install-response-smoke-test`, `--plugin-scaffold-smoke-test`, `--skill-toggle-smoke-test`, `--skill-extra-roots-smoke-test` |
| Plugin marketplaces and sharing | `marketplace/add`, `marketplace/remove`, `marketplace/upgrade`, `plugin/share/save`, `plugin/share/updateTargets`, `plugin/share/checkout`, `plugin/share/delete` | `--marketplace-upgrade-smoke-test`, `--plugin-share-smoke-test` |

## App-Server Requests And Dynamic Tools

| Surface | Runtime backing | Evidence |
| --- | --- | --- |
| Event stream | `ServerEvent`, `AsyncStream<ServerEvent>`, `handleAppServerNotification`, `handleAppServerRequest` | `--app-server-notification-smoke-test`, `--process-stream-smoke-test` |
| MCP elicitation and tool user input | `mcpServer/elicitation/request`, `respondMcpElicitation`, `item/tool/requestUserInput`, `tool/user_input/response` | `--mcp-elicitation-smoke-test`, `--tool-user-input-smoke-test` |
| Dynamic tools | `raytone_context.workspace_snapshot`, `raytone_context.list_workspace_files`, `raytone_context.read_workspace_file`, `raytone_browser.current_page`, `raytone_browser.open_url`, `raytone_browser.capture_snapshot`, `raytone_terminal.run_command`, `raytone_mcp.read_resource`, `raytone_mcp.call_tool` | `--dynamic-tool-smoke-test` |

## Packaging Truth Surface

| Surface | Runtime backing | Evidence |
| --- | --- | --- |
| Bundled runtime | `script/build_codex_from_source.sh`, `third_party/openai-codex`, bundled `Contents/Resources/codex`, Apache-2.0 NOTICE | `--bundle-audit`, `--package-audit`, `--release-audit` |
| App-server protocol schema | `codex app-server generate-json-schema`, `Schemas/v2`, `CodexAppServerClient` request methods, `SessionStore` notifications and server requests | `script/check_schema_matches_binary.sh`, `script/check_app_server_methods.sh`, `script/test.sh` |
| Sidecar provider layer | bundled `raytone-proxy`, provider TOML, Keychain secrets, local `/health` and `/usage` | `--provider-sidecar-smoke-test`, `--provider-unauthorized-smoke-test` |

## Completion Rule

Do not call a screen complete from UI appearance alone. A screen is complete only when the UI action, store method, app-server or runtime method, and smoke evidence all line up in this matrix.
