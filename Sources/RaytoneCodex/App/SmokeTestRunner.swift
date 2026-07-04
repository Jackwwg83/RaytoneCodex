import Dispatch
import Foundation
import RaytoneCodexCore

enum SmokeTestRunner {
    static func runIfRequested() {
        if CommandLine.arguments.contains("--cli-smoke-test") {
            runCLISmoke()
        } else if CommandLine.arguments.contains("--session-smoke-test") {
            runSessionSmoke()
        } else if CommandLine.arguments.contains("--tools-smoke-test") {
            runToolsSmoke()
        } else if CommandLine.arguments.contains("--catalog-smoke-test") {
            runCatalogSmoke()
        } else if CommandLine.arguments.contains("--mention-smoke-test") {
            runMentionSmoke()
        } else if CommandLine.arguments.contains("--runtime-pages-smoke-test") {
            runRuntimePagesSmoke()
        } else if CommandLine.arguments.contains("--automation-smoke-test") {
            runAutomationSmoke()
        } else if CommandLine.arguments.contains("--integration-pages-smoke-test") {
            runIntegrationPagesSmoke()
        } else if CommandLine.arguments.contains("--config-write-smoke-test") {
            runConfigWriteSmoke()
        } else if CommandLine.arguments.contains("--thread-management-smoke-test") {
            runThreadManagementSmoke()
        } else if CommandLine.arguments.contains("--history-smoke-test") {
            runHistorySmoke()
        }
    }

    private static func runCLISmoke() {
        let prompt = argument(after: "--prompt") ?? "Reply exactly: RaytoneCodex bundled CLI smoke OK"
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let model = argument(after: "--model")
        let service = CodexCLIService()

        Task {
            let runtime = await service.inspectRuntime()
            do {
                let result = try await service.run(
                    prompt: prompt,
                    options: CodexRunOptions(
                        workspaceURL: URL(fileURLWithPath: workspacePath),
                        model: model,
                        sandbox: .readOnly,
                        approvalPolicy: .never
                    )
                )
                emitJSON([
                    "ok": true,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "exitCode": Int(result.exitCode),
                    "finalMessage": result.finalMessage,
                    "outputFile": result.outputFileURL.path,
                    "commandPreview": result.commandPreview
                ])
                exit(0)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runSessionSmoke() {
        let prompt = argument(after: "--prompt") ?? "Reply exactly: RaytoneCodex session smoke OK"
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let model = argument(after: "--model") ?? ""

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.model = model
            store.sandbox = .readOnly

            await store.refreshRuntime()
            let runtime = store.runtimeSnapshot
            store.prompt = prompt
            await store.runPrompt()
            let deadline = Date().addingTimeInterval(120)
            while store.isRunning && Date() < deadline {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }

            let items = store.selectedThread.items
            let userMessages = items.compactMap { item -> String? in
                if case let .userMessage(text) = item.kind { return text }
                return nil
            }
            let agentMessages = items.compactMap { item -> String? in
                if case let .agentMessage(text) = item.kind { return text }
                return nil
            }
            let commands = items.compactMap { item -> CommandRun? in
                if case let .command(run) = item.kind { return run }
                return nil
            }
            let notices = items.compactMap { item -> Notice? in
                if case let .notice(notice) = item.kind { return notice }
                return nil
            }
            let lastCommand = commands.last
            let finalMessage = agentMessages.last ?? ""
            let usedExecFallback = lastCommand?.command.contains(" codex exec ") == true ||
                lastCommand?.command.hasSuffix("/codex exec") == true ||
                lastCommand?.command.contains("/codex exec ") == true
            let appServerThreadID = store.selectedThread.appServerThreadID ?? ""
            let ok = userMessages.last == prompt &&
                !store.isRunning &&
                !usedExecFallback &&
                !appServerThreadID.isEmpty &&
                finalMessage == "RaytoneCodex session smoke OK" &&
                notices.allSatisfy { notice in
                    if case .error = notice.level { return false }
                    return true
                }

            emitJSON([
                "ok": ok,
                "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                "runtimePath": runtime.executable?.url.path ?? "",
                "runtimeVersion": runtime.version ?? "",
                "workspacePath": workspacePath,
                "threadTitle": store.selectedThread.title,
                "isRunning": store.isRunning,
                "appServerThreadID": appServerThreadID,
                "usedExecFallback": usedExecFallback,
                "transcriptItemCount": items.count,
                "userMessageCount": userMessages.count,
                "commandCount": commands.count,
                "agentMessageCount": agentMessages.count,
                "noticeCount": notices.count,
                "lastCommandExitCode": Int(lastCommand?.exitCode ?? -999),
                "lastCommandPreview": lastCommand?.command ?? "",
                "finalMessage": finalMessage,
                "lastOutputPath": store.lastOutputPath
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runToolsSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let command = argument(after: "--command") ?? "pwd && ls Package.swift Sources script"

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.filePanelPath = workspacePath
            store.terminalCommand = command
            store.sandbox = .dangerFullAccess

            fputs("tools-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()
            fputs("tools-smoke: loadFilePanelDirectory\n", stderr)
            await store.loadFilePanelDirectory(workspacePath)
            fputs("tools-smoke: runTerminalCommand\n", stderr)
            await store.runTerminalCommand()
            fputs("tools-smoke: addFileReferencesToPrompt\n", stderr)
            await store.addFileReferencesToPrompt(paths: [
                URL(fileURLWithPath: workspacePath).appendingPathComponent("Package.swift").path
            ])
            fputs("tools-smoke: refreshWorkspaceBranches\n", stderr)
            await store.refreshWorkspaceBranches()
            fputs("tools-smoke: collect result\n", stderr)

            let lastRun = store.terminalRuns.last
            let requiredEntries = Set(["Package.swift", "Sources", "script"])
            let foundEntries = Set(store.fileEntries.map(\.name))
            let filePreview = store.filePreview
            let currentBranch = store.selectedProject.branch ?? ""
            let ok = requiredEntries.isSubset(of: foundEntries) &&
                lastRun?.exitCode == 0 &&
                lastRun?.output.contains("Package.swift") == true &&
                filePreview?.fileName == "Package.swift" &&
                store.prompt.contains("Package.swift") &&
                !currentBranch.isEmpty &&
                store.workspaceBranches.contains(currentBranch)

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "filePanelPath": store.filePanelPath,
                "filePanelStatus": store.filePanelStatusText,
                "fileEntryCount": store.fileEntries.count,
                "fileEntriesPreview": Array(store.fileEntries.map(\.name).prefix(12)),
                "fileReferencePrompt": store.prompt,
                "filePreview": [
                    "fileName": filePreview?.fileName ?? "",
                    "path": filePreview?.path ?? "",
                    "bytesPreviewed": filePreview?.text.utf8.count ?? 0,
                    "isTruncated": filePreview?.isTruncated ?? false
                ] as [String: Any],
                "branchStatus": store.workspaceBranchStatusText,
                "currentBranch": currentBranch,
                "branches": store.workspaceBranches,
                "terminalCommand": command,
                "terminalExitCode": Int(lastRun?.exitCode ?? -999),
                "terminalOutput": lastRun?.output ?? ""
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runCatalogSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("catalog-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()
            fputs("catalog-smoke: refreshRuntimeCatalog\n", stderr)
            await store.refreshRuntimeCatalog(forceReloadSkills: true)
            fputs("catalog-smoke: collect result\n", stderr)

            let config = store.runtimeConfig
            let hasConfig = config != nil
            let ok = store.runtimeSnapshot.executable != nil &&
                hasConfig &&
                !store.runtimeCatalogStatusText.hasPrefix("app-server 读取失败")

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "status": store.runtimeCatalogStatusText,
                "errorCount": store.runtimeCatalogErrors.count,
                "errors": store.runtimeCatalogErrors,
                "pluginCount": store.runtimePlugins.count,
                "pluginsPreview": Array(store.runtimePlugins.prefix(8).map { plugin in
                    [
                        "id": plugin.id,
                        "name": plugin.name,
                        "displayName": plugin.displayName,
                        "installed": plugin.installed,
                        "enabled": plugin.enabled,
                        "marketplace": plugin.marketplaceDisplayName
                    ] as [String: Any]
                }),
                "skillCount": store.runtimeSkills.count,
                "skillsPreview": Array(store.runtimeSkills.prefix(8).map { skill in
                    [
                        "name": skill.name,
                        "displayName": skill.displayName,
                        "enabled": skill.enabled,
                        "scope": skill.scope,
                        "path": skill.path
                    ] as [String: Any]
                }),
                "mcpServerCount": store.runtimeMCPServers.count,
                "mcpServersPreview": Array(store.runtimeMCPServers.prefix(8).map { server in
                    [
                        "name": server.name,
                        "title": server.title,
                        "authStatus": server.authStatus,
                        "toolCount": server.toolNames.count
                    ] as [String: Any]
                }),
                "hookCount": store.runtimeHooks.count,
                "hooksPreview": Array(store.runtimeHooks.prefix(8).map { hook in
                    [
                        "eventName": hook.eventName,
                        "handlerType": hook.handlerType,
                        "enabled": hook.enabled,
                        "trustStatus": hook.trustStatus,
                        "source": hook.source
                    ] as [String: Any]
                }),
                "config": [
                    "model": config?.model ?? "",
                    "modelProvider": config?.modelProvider ?? "",
                    "approvalPolicy": config?.approvalPolicy ?? "",
                    "sandboxMode": config?.sandboxMode ?? "",
                    "layerCount": config?.layerCount ?? 0,
                    "desktopKeys": config?.desktopKeys ?? []
                ] as [String: Any]
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runConfigWriteSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task {
            let service = CodexCLIService()
            let runtime = await service.inspectRuntime()
            guard let executable = runtime.executable else {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "none",
                    "runtimePath": "",
                    "runtimeVersion": runtime.version ?? "",
                    "error": "Codex runtime executable was not found"
                ])
                exit(1)
            }

            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexConfigSmoke-\(UUID().uuidString)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                let client = CodexAppServerClient(
                    executable: executable,
                    workspaceURL: URL(fileURLWithPath: workspacePath),
                    environmentOverrides: [
                        "CODEX_HOME": codexHome.path
                    ]
                )
                try await client.initialize()
                try await client.writeConfigValue(
                    keyPath: "approval_policy",
                    value: .string(CodexApprovalPolicy.onRequest.appServerValue)
                )
                try await client.writeConfigValue(
                    keyPath: "sandbox_mode",
                    value: .string(CodexSandboxMode.readOnly.rawValue)
                )
                try await client.resetMemory()
                let config = try await client.readConfig(cwd: workspacePath, includeLayers: true)
                await client.stop()

                let configURL = codexHome.appendingPathComponent("config.toml")
                let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let ok = config.approvalPolicy == "on-request" &&
                    config.sandboxMode == "read-only" &&
                    configText.contains("approval_policy") &&
                    configText.contains("sandbox_mode")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "approvalPolicy": config.approvalPolicy ?? "",
                    "sandboxMode": config.sandboxMode ?? "",
                    "memoryReset": true,
                    "configText": configText
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runThreadManagementSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task {
            let service = CodexCLIService()
            let runtime = await service.inspectRuntime()
            guard let executable = runtime.executable else {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "none",
                    "runtimePath": "",
                    "runtimeVersion": runtime.version ?? "",
                    "error": "Codex runtime executable was not found"
                ])
                exit(1)
            }

            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadSmoke-\(UUID().uuidString)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                let client = CodexAppServerClient(
                    executable: executable,
                    workspaceURL: URL(fileURLWithPath: workspacePath),
                    environmentOverrides: [
                        "CODEX_HOME": codexHome.path
                    ]
                )
                try await client.initialize()
                let options = CodexAppServerOptions(
                    workspaceURL: URL(fileURLWithPath: workspacePath),
                    sandbox: .readOnly,
                    approvalPolicy: .never
                )
                let thread = try await client.startThread(options: options)
                let renamed = "Raytone smoke \(UUID().uuidString.prefix(8))"
                try await client.setThreadName(id: thread.id, name: renamed)
                let forked = try await client.forkThread(id: thread.id, options: options)
                try await client.archiveThread(id: forked.id)
                await client.stop()

                let ok = !thread.id.isEmpty && !forked.id.isEmpty && thread.id != forked.id
                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "threadId": thread.id,
                    "forkedThreadId": forked.id,
                    "renamedTo": renamed,
                    "archivedFork": forked.id
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runHistorySmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let marker = "RaytoneCodex history smoke OK \(UUID().uuidString.prefix(8))"
        let prompt = "Reply exactly: \(marker)"

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.sandbox = .readOnly
            store.approval = .never
            await store.refreshRuntime()
            store.prompt = prompt
            await store.runPrompt()
            let deadline = Date().addingTimeInterval(120)
            while store.isRunning && Date() < deadline {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }

            let createdThreadID = store.selectedThread.appServerThreadID ?? ""
            let initialAgentMessages = store.selectedThread.items.compactMap { item -> String? in
                if case let .agentMessage(text) = item.kind { return text }
                return nil
            }
            let initialCommands = store.selectedThread.items.compactMap { item -> CommandRun? in
                if case let .command(run) = item.kind { return run }
                return nil
            }
            let usedExecFallback = initialCommands.contains { run in
                run.command.contains(" codex exec ") || run.command.contains("/codex exec ")
            }

            let reloaded = SessionStore()
            reloaded.workspacePath = workspacePath
            await reloaded.refreshRuntime()
            await reloaded.refreshRuntimeThreads(searchTerm: marker, limit: 10)

            let historyThread = reloaded.threads.first { thread in
                thread.appServerThreadID == createdThreadID ||
                    thread.title.localizedCaseInsensitiveContains(marker) ||
                    thread.preview.localizedCaseInsensitiveContains(marker)
            }
            if let historyThread {
                reloaded.selectThread(historyThread)
                await reloaded.loadRuntimeThreadTranscript(localThreadID: historyThread.id)
            }

            let loadedItems = historyThread == nil ? [] : reloaded.selectedThread.items
            let loadedUserMessages = loadedItems.compactMap { item -> String? in
                if case let .userMessage(text) = item.kind { return text }
                return nil
            }
            let loadedAgentMessages = loadedItems.compactMap { item -> String? in
                if case let .agentMessage(text) = item.kind { return text }
                return nil
            }

            let ok = !createdThreadID.isEmpty &&
                !store.isRunning &&
                !usedExecFallback &&
                initialAgentMessages.last == marker &&
                historyThread != nil &&
                loadedUserMessages.contains(prompt) &&
                loadedAgentMessages.contains(marker)

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "marker": marker,
                "createdThreadID": createdThreadID,
                "usedExecFallback": usedExecFallback,
                "historySyncStatus": reloaded.runtimeThreadSyncStatusText,
                "historyThreadFound": historyThread != nil,
                "loadedTranscriptItemCount": loadedItems.count,
                "loadedUserMessages": loadedUserMessages,
                "loadedAgentMessages": loadedAgentMessages
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runMentionSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("mention-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()
            fputs("mention-smoke: refreshRuntimeCatalog\n", stderr)
            await store.refreshRuntimeCatalog(forceReloadSkills: false)

            guard let plugin = store.runtimePlugins.first(where: { $0.installed && $0.enabled }) else {
                emitJSON([
                    "ok": false,
                    "error": "no installed and enabled plugin returned by app-server",
                    "pluginCount": store.runtimePlugins.count,
                    "status": store.runtimeCatalogStatusText
                ])
                exit(1)
            }

            let prompt = "@\(plugin.name) 用一句话说明你能做什么"
            let mentions = await store.previewPluginMentions(for: prompt)
            let inputItems = CodexAppServerClient.userInputItems(prompt: prompt, mentions: mentions)
            let inputJSONObject = jsonObject(from: inputItems)
            let mentionPath = mentions.first?.path ?? ""
            let ok = mentions.count == 1 &&
                mentionPath == plugin.mentionPath &&
                inputItems.arrayValue?.count == 2 &&
                inputItems.arrayValue?.last?["type"]?.stringValue == "mention"

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "pluginCount": store.runtimePlugins.count,
                "selectedPlugin": [
                    "id": plugin.id,
                    "name": plugin.name,
                    "displayName": plugin.displayName,
                    "marketplace": plugin.marketplaceName,
                    "mentionPath": plugin.mentionPath
                ],
                "prompt": prompt,
                "mentions": mentions.map { ["name": $0.name, "path": $0.path] },
                "turnInput": inputJSONObject
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runRuntimePagesSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("runtime-pages-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("runtime-pages-smoke: refreshAccountUsageRuntime\n", stderr)
            await store.refreshAccountUsageRuntime()
            let accountStatus = store.runtimeCatalogStatusText
            let accountErrors = store.runtimeCatalogErrors

            fputs("runtime-pages-smoke: refreshArchivedThreads\n", stderr)
            await store.refreshArchivedThreads()
            let archivedStatus = store.runtimeCatalogStatusText
            let archivedErrors = store.runtimeCatalogErrors

            fputs("runtime-pages-smoke: refreshWorkspaceGitDiff\n", stderr)
            await store.refreshWorkspaceGitDiff()
            let gitStatus = store.runtimeCatalogStatusText
            let gitErrors = store.runtimeCatalogErrors
            let diffSummary = SessionStore.diffSummary(store.workspaceGitDiff?.diff ?? "")

            let hardFailure = store.runtimeSnapshot.executable == nil ||
                archivedStatus.hasPrefix("已归档对话读取失败") ||
                (gitStatus.hasPrefix("Git 差异读取失败") && store.workspaceGitStatusText.isEmpty)

            emitJSON([
                "ok": !hardFailure,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "accountStatus": accountStatus,
                "accountErrors": accountErrors,
                "account": [
                    "kind": store.runtimeAccount?.kind ?? "",
                    "email": store.runtimeAccount?.email ?? "",
                    "planType": store.runtimeAccount?.planType ?? "",
                    "requiresOpenAIAuth": store.runtimeAccount?.requiresOpenAIAuth ?? false
                ] as [String: Any],
                "tokenUsage": [
                    "lifetimeTokens": store.runtimeTokenUsage?.lifetimeTokens.map { $0 as Any } ?? NSNull(),
                    "peakDailyTokens": store.runtimeTokenUsage?.peakDailyTokens.map { $0 as Any } ?? NSNull(),
                    "dailyBucketCount": store.runtimeTokenUsage?.dailyBuckets.count ?? 0
                ] as [String: Any],
                "rateLimitBucketCount": store.runtimeRateLimits?.buckets.count ?? 0,
                "archivedStatus": archivedStatus,
                "archivedErrors": archivedErrors,
                "archivedThreadCount": store.archivedRuntimeThreads.count,
                "archivedThreadsPreview": Array(store.archivedRuntimeThreads.prefix(5).map { thread in
                    [
                        "id": thread.id,
                        "title": thread.title,
                        "cwd": thread.cwd ?? "",
                        "updatedAt": thread.updatedAt ?? "",
                        "modelProvider": thread.modelProvider ?? ""
                    ] as [String: Any]
                }),
                "gitStatus": gitStatus,
                "gitErrors": gitErrors,
                "git": [
                    "sha": store.workspaceGitDiff?.sha ?? "",
                    "diffBytes": store.workspaceGitDiff?.diff.utf8.count ?? 0,
                    "files": diffSummary.files,
                    "additions": diffSummary.additions,
                    "deletions": diffSummary.deletions,
                    "fallbackStatus": store.workspaceGitStatusText
                ] as [String: Any]
            ])
            exit(hardFailure ? 1 : 0)
        }

        dispatchMain()
    }

    private static func runAutomationSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("automation-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()
            fputs("automation-smoke: refreshRuntimeHooks\n", stderr)
            await store.refreshRuntimeHooks()

            let hardFailure = store.runtimeSnapshot.executable == nil ||
                store.runtimeCatalogStatusText.hasPrefix("hooks/list 失败")

            emitJSON([
                "ok": !hardFailure,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "status": store.runtimeCatalogStatusText,
                "errors": store.runtimeCatalogErrors,
                "hookCount": store.runtimeHooks.count,
                "hooksPreview": Array(store.runtimeHooks.prefix(10).map { hook in
                    [
                        "key": hook.key,
                        "eventName": hook.eventName,
                        "handlerType": hook.handlerType,
                        "matcher": hook.matcher ?? "",
                        "command": hook.command ?? "",
                        "source": hook.source,
                        "sourcePath": hook.sourcePath,
                        "trustStatus": hook.trustStatus,
                        "timeoutSec": hook.timeoutSec,
                        "enabled": hook.enabled,
                        "isManaged": hook.isManaged
                    ] as [String: Any]
                })
            ])
            exit(hardFailure ? 1 : 0)
        }

        dispatchMain()
    }

    private static func runIntegrationPagesSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("integration-pages-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("integration-pages-smoke: refreshIntegrationRuntime\n", stderr)
            await store.refreshIntegrationRuntime(forceRefetchApps: false)
            let integrationStatus = store.runtimeCatalogStatusText
            let integrationErrors = store.runtimeCatalogErrors

            fputs("integration-pages-smoke: refreshWorkspaceWorktrees\n", stderr)
            await store.refreshWorkspaceWorktrees()
            let worktreeStatus = store.runtimeCatalogStatusText
            let worktreeErrors = store.runtimeCatalogErrors

            let browserPlugins = store.runtimePlugins.filter { plugin in
                let name = "\(plugin.name) \(plugin.displayName)".lowercased()
                return name.contains("browser") || name.contains("chrome")
            }
            let computerPlugins = store.runtimePlugins.filter { plugin in
                let name = "\(plugin.name) \(plugin.displayName)".lowercased()
                return name.contains("computer")
            }
            let appsWithScreenshots = store.runtimeApps.filter { !$0.screenshotPrompts.isEmpty }
            let ok = store.runtimeSnapshot.executable != nil &&
                !integrationStatus.hasPrefix("集成状态读取失败") &&
                !worktreeStatus.hasPrefix("工作树读取失败")

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "integrationStatus": integrationStatus,
                "integrationErrors": integrationErrors,
                "requirements": [
                    "allowAppSnapshots": store.runtimeRequirements?.allowAppSnapshots.map { $0 as Any } ?? NSNull(),
                    "allowLockedComputerUse": store.runtimeRequirements?.allowLockedComputerUse.map { $0 as Any } ?? NSNull(),
                    "networkEnabled": store.runtimeRequirements?.networkEnabled.map { $0 as Any } ?? NSNull(),
                    "defaultPermissions": store.runtimeRequirements?.defaultPermissions ?? ""
                ] as [String: Any],
                "remoteControl": [
                    "status": store.runtimeRemoteControlStatus?.status ?? "",
                    "serverName": store.runtimeRemoteControlStatus?.serverName ?? "",
                    "environmentID": store.runtimeRemoteControlStatus?.environmentID ?? ""
                ] as [String: Any],
                "appCount": store.runtimeApps.count,
                "appsWithScreenshotMetadata": appsWithScreenshots.count,
                "appPreview": Array(store.runtimeApps.prefix(8).map { app in
                    [
                        "id": app.id,
                        "name": app.name,
                        "enabled": app.isEnabled,
                        "accessible": app.isAccessible,
                        "screenshotPromptCount": app.screenshotPrompts.count
                    ] as [String: Any]
                }),
                "browserPluginCount": browserPlugins.count,
                "computerPluginCount": computerPlugins.count,
                "mcpServerCount": store.runtimeMCPServers.count,
                "permissionProfileCount": store.runtimePermissionProfiles.count,
                "worktreeStatus": worktreeStatus,
                "worktreeErrors": worktreeErrors,
                "worktrees": store.workspaceWorktrees
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func argument(after flag: String) -> String? {
        guard let index = CommandLine.arguments.firstIndex(of: flag) else {
            return nil
        }
        let valueIndex = CommandLine.arguments.index(after: index)
        guard CommandLine.arguments.indices.contains(valueIndex) else {
            return nil
        }
        return CommandLine.arguments[valueIndex]
    }

    private static func emitJSON(_ object: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8)
        else {
            print(#"{"ok":false,"error":"failed to encode smoke output"}"#)
            return
        }
        print(json)
    }

    private static func jsonObject(from value: JSONValue) -> Any {
        switch value {
        case let .string(value):
            value
        case let .number(value):
            value
        case let .bool(value):
            value
        case let .object(value):
            value.mapValues(jsonObject(from:))
        case let .array(value):
            value.map(jsonObject(from:))
        case .null:
            NSNull()
        }
    }
}
