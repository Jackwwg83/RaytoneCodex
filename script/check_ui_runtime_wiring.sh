#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path.cwd()

files = {
    "routes": root / "Sources/RaytoneCodex/Models/AppRoutes.swift",
    "settings": root / "Sources/RaytoneCodex/Views/SettingsRouteView.swift",
    "content": root / "Sources/RaytoneCodex/Views/ContentView.swift",
    "sidebar": root / "Sources/RaytoneCodex/Views/SidebarView.swift",
    "inspector": root / "Sources/RaytoneCodex/Views/InspectorView.swift",
    "browser_panel": root / "Sources/RaytoneCodex/Views/BrowserPanelView.swift",
    "plugins": root / "Sources/RaytoneCodex/Views/PluginsPage.swift",
    "automation": root / "Sources/RaytoneCodex/Views/AutomationPage.swift",
    "environment": root / "Sources/RaytoneCodex/Views/EnvironmentInfoPanel.swift",
    "thread": root / "Sources/RaytoneCodex/Views/ThreadView.swift",
    "hero": root / "Sources/RaytoneCodex/Views/NewThreadHeroView.swift",
    "commands": root / "Sources/RaytoneCodex/App/AppCommands.swift",
    "store": root / "Sources/RaytoneCodex/Stores/SessionStore.swift",
    "store_ui": root / "Sources/RaytoneCodex/Stores/SessionStore+UI.swift",
    "provider_model": root / "Sources/RaytoneCodexCore/Models/RaytoneProviderConfiguration.swift",
    "keychain": root / "Sources/RaytoneCodexCore/Services/KeychainService.swift",
    "proxy_service": root / "Sources/RaytoneCodexCore/Services/RaytoneProxyService.swift",
    "client": root / "Sources/RaytoneCodexCore/Services/CodexAppServerClient.swift",
    "smoke": root / "Sources/RaytoneCodex/App/SmokeTestRunner.swift",
    "onboarding": root / "Sources/RaytoneCodex/Views/ProviderOnboardingView.swift",
    "runner": root / "script/build_and_run.sh",
}

missing_files = [str(path.relative_to(root)) for path in files.values() if not path.exists()]
if missing_files:
    print(json.dumps({"ok": False, "missingFiles": missing_files}, ensure_ascii=False, indent=2))
    sys.exit(1)

text = {name: path.read_text(encoding="utf-8") for name, path in files.items()}
all_text = "\n".join(text.values())
failures = []


def require(surface, token, haystack=None):
    haystack = all_text if haystack is None else haystack
    if token not in haystack:
        failures.append({"surface": surface, "missing": token})


def enum_cases(enum_name):
    match = re.search(rf"enum {enum_name}:[^{{]*\{{(?P<body>.*?)\n\}}", text["routes"], re.S)
    if not match:
        failures.append({"surface": enum_name, "missing": "enum declaration"})
        return []
    return re.findall(r"\bcase\s+([A-Za-z_][A-Za-z0-9_]*)", match.group("body"))


settings_cases = enum_cases("SettingsPane")
tool_panel_cases = enum_cases("ToolPanel")

for pane in settings_cases:
    require(f"settings pane {pane}", f"case .{pane}", text["settings"])

settings_runtime = {
    "general": ["refreshRuntimeCatalog", "saveRuntimeWorkMode", "saveRuntimeShowInMenuBar", "diagnoseWorkspaceRuntime", "--runtime-diagnostics-smoke-test"],
    "modelsProviders": ["model/list", "modelProvider/capabilities/read", "RaytoneKeychainService", "RaytoneProxyService", "continueProviderOnboardingWithOpenAI", "继续使用 OpenAI", "--model-catalog-smoke-test", "--model-provider-capabilities-smoke-test", "--provider-sidecar-smoke-test", "--provider-onboarding-smoke-test", "--provider-unauthorized-smoke-test"],
    "profile": ["account/read", "account/usage/read", "feedback/upload", "--profile-share-smoke-test"],
    "appearance": ["saveRuntimeAppearance", "--desktop-settings-smoke-test"],
    "configuration": [
        "config/read",
        "config/value/write",
        "saveRuntimeApprovalPolicy",
        "externalAgentConfig/detect",
        "externalAgentConfig/import",
        "--config-write-smoke-test",
        "--external-agent-config-smoke-test",
    ],
    "experimentalFeatures": ["experimentalFeature/list", "experimentalFeature/enable", "--experimental-features-smoke-test"],
    "personalization": [
        "thread/settings/update",
        "thread/realtime/listVoices",
        "desktop.raytone.commit_instructions",
        "desktop.raytone.pull_request_instructions",
        "config/batchWrite",
        "/commit",
        "/pr",
        "/goal",
        "/goal-status",
        "/goal-clear",
        "thread/goal/set",
        "thread/goal/get",
        "thread/goal/clear",
        "--goal-smoke-test",
        "--personality-smoke-test",
        "--realtime-voices-smoke-test",
    ],
    "keyboardShortcuts": ["AppCommands", "CommandMenu(\"对话\")", "CommandMenu(\"工具\")", "--command-surface-smoke-test"],
    "usageBilling": [
        "account/usage/read",
        "account/rateLimits/read",
        "raytone-proxy /usage",
        "refreshUsageBillingRuntime",
        "--usage-activity-smoke-test",
        "--provider-sidecar-smoke-test",
    ],
    "appSnapshots": ["app/list", "useRuntimeAppSnapshotPromptInComposer", "snapshotMentionInTurnStart", "captureBrowserPanelScreenshot", "--app-mention-turn-smoke-test"],
    "mcpServers": ["mcpServerStatus/list", "mcpServer/tool/call", "mcpServer/resource/read", "--mcp-tool-smoke-test", "--mcp-resource-smoke-test"],
    "browser": [
        "WKWebView",
        "fs/getMetadata",
        "fs/readFile",
        "WKWebsiteDataStore",
        "BrowserSnapshotWriter",
        "captureBrowserPanelScreenshot",
        "browserAttachedSnapshotPath",
        "localImagePaths",
        "--browser-navigation-smoke-test",
        "--browser-clear-data-smoke-test",
        "--browser-snapshot-input-smoke-test",
    ],
    "computerControl": ["configRequirements/read", "windowsSandbox/readiness", "windowsSandbox/setupStart", "--windows-sandbox-smoke-test"],
    "hooks": ["hooks/list", "config/value/write", "--hook-controls-smoke-test", "--automation-hook-smoke-test"],
    "connections": ["remoteControl/status/read", "app/list", "mcpServerStatus/list", "openRuntimeAppInstallURL", "installFallbackObserved", "--remote-control-smoke-test", "--home-connection-app-mention-smoke-test"],
    "git": ["command/exec", "git diff", "gh repo create", "gh pr create", "runGitCreateRepositoryInTerminal", "runGitPushCurrentBranchInTerminal", "runGitCreatePullRequestInTerminal", "--git-repo-create-smoke-test", "--git-push-smoke-test", "--git-pr-create-smoke-test", "--runtime-environment-smoke-test"],
    "environments": ["environment/add", "permissionProfile/list", "configRequirements/read", "--runtime-environment-smoke-test"],
    "worktrees": ["git worktree list", "openWorkspaceWorktree", "--worktree-switch-smoke-test"],
    "archivedChats": ["thread/list", "thread/unarchive", "--thread-lifecycle-smoke-test"],
}

missing_pane_specs = sorted(set(settings_cases) - set(settings_runtime))
if missing_pane_specs:
    failures.append({"surface": "settings pane runtime spec", "missing": ", ".join(missing_pane_specs)})

for pane, tokens in settings_runtime.items():
    for token in tokens:
        require(f"settings pane {pane}", token)

tool_panels = {
    "launcher": [
        "EnvironmentInfoPanel",
        "private var launcher",
        "ActiveGoalDetailCard",
        "environmentSourceFacts",
        "title: \"目标\"",
        "thread/goal/get",
        "refreshSelectedRuntimeGoal",
    ],
    "browser": [
        "BrowserPanelView",
        "WKWebView",
        "fs/getMetadata",
        "WKWebsiteDataStore",
        "BrowserSnapshotWriter",
        "openBrowserAddress",
        "captureBrowserPanelScreenshot",
        "browserAttachedSnapshotPath",
        "--browser-navigation-smoke-test",
        "--browser-clear-data-smoke-test",
        "--browser-snapshot-input-smoke-test",
    ],
    "files": [
        "FilesToolPanel",
        "fs/getMetadata",
        "fs/readDirectory",
        "fs/watch",
        "fs/readFile",
        "fs/writeFile",
        "fs/createDirectory",
        "fs/copy",
        "fs/remove",
        "fuzzyFileSearch",
        "addPreviewedFileReferenceToPrompt",
        "--file-search-smoke-test",
    ],
    "terminal": [
        "TerminalToolPanel",
        "process/spawn",
        "process/writeStdin",
        "process/resizePty",
        "process/kill",
        "thread/shellCommand",
        "thread/backgroundTerminals/clean",
        "command/exec",
        "--terminal-stream-smoke-test",
        "--terminal-resize-smoke-test",
        "--thread-shell-command-smoke-test",
    ],
    "sideChat": ["SideChatToolPanel", "turn/start", "turn/steer", "thread/inject_items", "--side-chat-smoke-test", "--side-chat-injection-smoke-test"],
}

missing_tool_specs = sorted(set(tool_panel_cases) - set(tool_panels))
if missing_tool_specs:
    failures.append({"surface": "tool panel runtime spec", "missing": ", ".join(missing_tool_specs)})

for panel, tokens in tool_panels.items():
    for token in tokens:
        require(f"tool panel {panel}", token)

dynamic_tools = [
    ("raytone_context", "workspace_snapshot", "dynamicToolResponse"),
    ("raytone_context", "list_workspace_files", "dynamicToolFilesResponse"),
    ("raytone_context", "read_workspace_file", "dynamicToolReadFileResponse"),
    ("raytone_browser", "current_page", "dynamicToolBrowserResponse"),
    ("raytone_browser", "open_url", "dynamicToolBrowserOpenResponse"),
    ("raytone_browser", "capture_snapshot", "dynamicToolBrowserSnapshotResponse"),
    ("raytone_terminal", "run_command", "dynamicToolTerminalResponse"),
    ("raytone_mcp", "read_resource", "dynamicToolMCPResourceResponse"),
    ("raytone_mcp", "call_tool", "dynamicToolMCPToolResponse"),
]

for namespace, tool, smoke_token in dynamic_tools:
    require(f"dynamic tool {namespace}.{tool}", f'"namespace": .string("{namespace}")', text["client"])
    require(f"dynamic tool {namespace}.{tool}", f'"name": .string("{tool}")', text["client"])
    require(f"dynamic tool {namespace}.{tool}", f'namespace == "{namespace}"', text["store"])
    require(f"dynamic tool {namespace}.{tool}", f'tool == "{tool}"', text["store"])
    require(f"dynamic tool {namespace}.{tool}", smoke_token, text["smoke"])
    require(f"dynamic tool {namespace}.{tool}", f"{namespace}.{tool}", text["smoke"])
require("dynamic tool browser snapshot artifact", "browserSnapshotIsPNG", text["smoke"])
require("dynamic tool browser snapshot artifact", "isPNGData", text["smoke"])

route_tokens = {
    "plugins": ["store.route = .plugins", "PluginsPage", "plugin/list", "plugin/read", "--plugin-read-smoke-test"],
    "automation": ["store.route = .automation", "AutomationPage", "hooks/list", "--automation-smoke-test"],
    "settings": ["store.route = .settings", "SettingsRouteView", "CommandGroup(replacing: .appSettings)", "⌘,"],
    "thread": ["store.route = .thread", "ThreadView", "turn/start", "thread/start"],
}
for route, tokens in route_tokens.items():
    for token in tokens:
        require(f"route {route}", token)

page_runtime_tokens = {
    "plugins page": [
        "refreshRuntimeCatalog",
        "plugin/list",
        "skills/list",
        "plugin/read",
        "plugin/install",
        "plugin/uninstall",
        "plugin/share/save",
        "plugin/share/checkout",
        "skills/config/write",
        "createLocalPluginTemplate",
        "createLocalSkillTemplate",
        "--skill-toggle-smoke-test",
        "--plugin-share-smoke-test",
    ],
    "automation page": [
        "refreshRuntimeHooks",
        "refreshAutomationEventLog",
        "installAutomationHookTemplate",
        "trustRuntimeHook",
        "setRuntimeHookEnabled",
        "removeRaytoneAutomationHookTemplate",
        "hooks/list",
        "config/value/write",
        "fs/readFile",
        "--automation-hook-smoke-test",
        "--hook-controls-smoke-test",
    ],
}
for page, tokens in page_runtime_tokens.items():
    for token in tokens:
        require(page, token)

menu_runtime_tokens = [
    "--command-surface-smoke-test",
    "CommandGroup(replacing: .appSettings)",
    "CommandGroup(replacing: .newItem)",
    "CommandMenu(\"工具\")",
    "thread/name/set",
    "thread/fork",
    "thread/compact/start",
    "thread/rollback",
    "turn/interrupt",
    "thread/goal/set",
    "thread/goal/clear",
]
for token in menu_runtime_tokens:
    require("menu and goal actions", token)

sample_data_guard = [
    "RAYTONE_CODEX_ENABLE_SAMPLE_DATA",
    "RAYTONE_CODEX_UI_SCREEN",
    "installSampleWorkspaceIfNeeded",
]
for token in sample_data_guard:
    require("sample data gating", token)

empty_button_matches = re.findall(r"Button\s*(?:\([^)]*\))?\s*\{\s*\}", all_text)
if empty_button_matches:
    failures.append({"surface": "interactive controls", "missing": f"found {len(empty_button_matches)} empty Button closures"})

result = {
    "ok": not failures,
    "settingsPanes": len(settings_cases),
    "toolPanels": len(tool_panel_cases),
    "dynamicTools": len(dynamic_tools),
    "settingsRuntimeSpecs": len(settings_runtime),
    "checkedFiles": len(files),
    "failures": failures,
}
print(json.dumps(result, ensure_ascii=False, indent=2))
sys.exit(0 if not failures else 1)
PY
