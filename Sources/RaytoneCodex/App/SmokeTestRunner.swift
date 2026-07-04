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
        } else if CommandLine.arguments.contains("--file-search-smoke-test") {
            runFileSearchSmoke()
        } else if CommandLine.arguments.contains("--review-smoke-test") {
            runReviewSmoke()
        } else if CommandLine.arguments.contains("--catalog-smoke-test") {
            runCatalogSmoke()
        } else if CommandLine.arguments.contains("--mention-smoke-test") {
            runMentionSmoke()
        } else if CommandLine.arguments.contains("--runtime-pages-smoke-test") {
            runRuntimePagesSmoke()
        } else if CommandLine.arguments.contains("--automation-smoke-test") {
            runAutomationSmoke()
        } else if CommandLine.arguments.contains("--automation-hook-smoke-test") {
            runAutomationHookSmoke()
        } else if CommandLine.arguments.contains("--integration-pages-smoke-test") {
            runIntegrationPagesSmoke()
        } else if CommandLine.arguments.contains("--access-mode-smoke-test") {
            runAccessModeSmoke()
        } else if CommandLine.arguments.contains("--personality-smoke-test") {
            runPersonalitySmoke()
        } else if CommandLine.arguments.contains("--config-write-smoke-test") {
            runConfigWriteSmoke()
        } else if CommandLine.arguments.contains("--thread-management-smoke-test") {
            runThreadManagementSmoke()
        } else if CommandLine.arguments.contains("--history-smoke-test") {
            runHistorySmoke()
        } else if CommandLine.arguments.contains("--slash-smoke-test") {
            runSlashSmoke()
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

    private static func runFileSearchSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexFileSearchSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexFileSearchCodexHome-\(UUID().uuidString)", isDirectory: true)

            do {
                let sourceDirectory = workspaceURL.appendingPathComponent("Sources/Nested", isDirectory: true)
                let docsDirectory = workspaceURL.appendingPathComponent("docs", isDirectory: true)
                try fileManager.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: docsDirectory, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)

                let targetURL = sourceDirectory.appendingPathComponent("NeedleRuntimeFile.swift")
                let targetText = "let raytoneSearchNeedle = \"fuzzy-file-search-runtime-proof\"\n"
                try targetText.write(to: targetURL, atomically: true, encoding: .utf8)
                try "not the target\n".write(
                    to: docsDirectory.appendingPathComponent("notes.md"),
                    atomically: true,
                    encoding: .utf8
                )

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "FileSearchSmoke"
                }

                await store.refreshRuntime()
                store.fileSearchQuery = "NeedleRuntime"
                await store.searchWorkspaceFiles()

                let targetResult = store.fileSearchResults.first { $0.path == targetURL.path }
                if let targetResult {
                    await store.openFileEntry(targetResult)
                }

                let preview = store.filePreview
                let ok = store.runtimeSnapshot.executable != nil &&
                    targetResult != nil &&
                    preview?.path == targetURL.path &&
                    preview?.text.contains("fuzzy-file-search-runtime-proof") == true

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "query": store.fileSearchQuery,
                    "searchStatus": store.fileSearchStatusText,
                    "resultCount": store.fileSearchResults.count,
                    "results": store.fileSearchResults.prefix(8).map { result in
                        [
                            "name": result.name,
                            "path": result.path,
                            "isDirectory": result.isDirectory,
                            "isFile": result.isFile
                        ] as [String: Any]
                    },
                    "openedPreview": [
                        "path": preview?.path ?? "",
                        "fileName": preview?.fileName ?? "",
                        "textPreview": String((preview?.text ?? "").prefix(200)),
                        "isTruncated": preview?.isTruncated ?? false
                    ] as [String: Any]
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "unknown",
                    "runtimePath": "",
                    "runtimeVersion": "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runReviewSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexReviewSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexReviewCodexHome-\(UUID().uuidString)", isDirectory: true)
            var mockServer: MockResponsesServer?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                let targetURL = workspaceURL.appendingPathComponent("review_target.swift")
                try "let before = 1\n".write(to: targetURL, atomically: true, encoding: .utf8)
                _ = try runProcess(["git", "init"], cwd: workspaceURL)
                _ = try runProcess(["git", "add", "review_target.swift"], cwd: workspaceURL)
                _ = try runProcess([
                    "git",
                    "-c", "user.name=Raytone Smoke",
                    "-c", "user.email=raytone@example.invalid",
                    "commit",
                    "-m",
                    "initial"
                ], cwd: workspaceURL)
                try "let before = 1\nlet after = 2\n".write(to: targetURL, atomically: true, encoding: .utf8)

                let reviewPayload = """
                {"findings":[{"title":"Raytone review smoke finding","body":"Mock reviewer saw the changed file through review/start.","confidence_score":0.9,"priority":1,"code_location":{"absolute_file_path":"\(targetURL.path)","line_range":{"start":2,"end":2}}}],"overall_correctness":"patch is correct","overall_explanation":"Synthetic review smoke completed.","overall_confidence_score":0.8}
                """
                mockServer = try startMockResponsesServer(message: reviewPayload)
                try writeMockCodexConfig(codexHome: codexHomeURL, baseURL: mockServer!.baseURL)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.model = "mock-model"
                store.sandbox = .readOnly
                store.approval = .never
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "ReviewSmoke"
                }

                await store.refreshRuntime()
                await store.runReviewOfCurrentChanges(displayedPrompt: "审查当前变更")
                await waitForStoreToSettle(store)
                await store.stopAppServerForTesting()

                let agentMessages = store.selectedThread.items.compactMap { item -> String? in
                    if case let .agentMessage(text) = item.kind { return text }
                    return nil
                }
                let notices = store.selectedThread.items.compactMap { item -> Notice? in
                    if case let .notice(notice) = item.kind { return notice }
                    return nil
                }
                let requestLog = (try? String(contentsOf: mockServer!.requestLogURL, encoding: .utf8)) ?? ""
                let finalReview = agentMessages.joined(separator: "\n\n")
                let ok = store.runtimeSnapshot.executable != nil &&
                    !store.isRunning &&
                    store.selectedThread.appServerThreadID?.isEmpty == false &&
                    finalReview.contains("Raytone review smoke finding") &&
                    requestLog.contains("/v1/responses") &&
                    notices.allSatisfy { notice in
                        if case .error = notice.level { return false }
                        return true
                    }

                mockServer?.stop()
                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "mockResponsesBaseURL": mockServer?.baseURL ?? "",
                    "appServerThreadID": store.selectedThread.appServerThreadID ?? "",
                    "transcriptItemCount": store.selectedThread.items.count,
                    "agentMessageCount": agentMessages.count,
                    "noticeCount": notices.count,
                    "finalReviewPreview": String(finalReview.prefix(1200)),
                    "mockRequestLogPreview": String(requestLog.prefix(1200))
                ])
                exit(ok ? 0 : 1)
            } catch {
                mockServer?.stop()
                emitJSON([
                    "ok": false,
                    "runtimeSource": "unknown",
                    "runtimePath": "",
                    "runtimeVersion": "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
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

    private static func runAccessModeSmoke() {
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
                .appendingPathComponent("RaytoneCodexAccessModeSmoke-\(UUID().uuidString)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)

                let uiMapping = await MainActor.run { () -> [String: String] in
                    let store = SessionStore()
                    store.workspacePath = workspacePath
                    store.chooseAccessMode(.autoReview)
                    return [
                        "accessMode": store.accessMode.shortTitle,
                        "approvalPolicy": store.approval.appServerValue,
                        "approvalsReviewer": store.approvalsReviewer.rawValue,
                        "sandbox": store.sandbox.rawValue
                    ]
                }

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
                    sandbox: .workspaceWrite,
                    approvalPolicy: .onFailure,
                    approvalsReviewer: .autoReview
                )
                let serverThread = try await client.startThread(options: options)
                try await client.writeConfigValue(
                    keyPath: "approval_policy",
                    value: .string(CodexApprovalPolicy.onFailure.appServerValue)
                )
                try await client.writeConfigValue(
                    keyPath: "approvals_reviewer",
                    value: .string(CodexApprovalsReviewer.autoReview.rawValue)
                )
                try await client.writeConfigValue(
                    keyPath: "sandbox_mode",
                    value: .string(CodexSandboxMode.workspaceWrite.rawValue)
                )
                let config = try await client.readConfig(cwd: workspacePath, includeLayers: true)
                await client.stop()

                let configURL = codexHome.appendingPathComponent("config.toml")
                let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let ok = uiMapping["approvalPolicy"] == "on-failure" &&
                    uiMapping["approvalsReviewer"] == "auto_review" &&
                    uiMapping["sandbox"] == "workspace-write" &&
                    serverThread.approvalPolicy == "on-failure" &&
                    serverThread.approvalsReviewer == .autoReview &&
                    config.approvalPolicy == "on-failure" &&
                    config.approvalsReviewer == "auto_review" &&
                    config.sandboxMode == "workspace-write" &&
                    configText.contains("approvals_reviewer")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "uiMapping": uiMapping,
                    "threadID": serverThread.id,
                    "threadApprovalPolicy": serverThread.approvalPolicy ?? "",
                    "threadApprovalsReviewer": serverThread.approvalsReviewer?.rawValue ?? "",
                    "threadSandbox": serverThread.sandboxSummary ?? "",
                    "configApprovalPolicy": config.approvalPolicy ?? "",
                    "configApprovalsReviewer": config.approvalsReviewer ?? "",
                    "configSandboxMode": config.sandboxMode ?? "",
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

    private static func runPersonalitySmoke() {
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
                .appendingPathComponent("RaytoneCodexPersonalitySmoke-\(UUID().uuidString)", isDirectory: true)
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
                let serverThread = try await client.startThread(options: CodexAppServerOptions(
                    workspaceURL: URL(fileURLWithPath: workspacePath),
                    sandbox: .workspaceWrite,
                    approvalPolicy: .onRequest,
                    approvalsReviewer: .user,
                    personality: .friendly
                ))

                let eventTask = Task { () -> [String: String] in
                    for await event in client.events {
                        guard case let .notification(method, params) = event,
                              method == "thread/settings/updated",
                              params?["threadId"]?.stringValue == serverThread.id else {
                            continue
                        }
                        return [
                            "method": method,
                            "threadId": params?["threadId"]?.stringValue ?? "",
                            "personality": params?["threadSettings"]?["personality"]?.stringValue ?? "",
                            "model": params?["threadSettings"]?["model"]?.stringValue ?? "",
                            "approvalPolicy": params?["threadSettings"]?["approvalPolicy"]?.stringValue ?? "",
                            "approvalsReviewer": params?["threadSettings"]?["approvalsReviewer"]?.stringValue ?? ""
                        ]
                    }
                    return [:]
                }

                try await client.updateThreadPersonality(threadID: serverThread.id, personality: .pragmatic)
                let notification = await withTaskGroup(of: [String: String].self) { group in
                    group.addTask { await eventTask.value }
                    group.addTask {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        return [:]
                    }
                    let first = await group.next() ?? [:]
                    group.cancelAll()
                    return first
                }
                eventTask.cancel()
                await client.stop()

                let ok = notification["personality"] == CodexPersonality.pragmatic.rawValue
                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "threadID": serverThread.id,
                    "requestedInitialPersonality": CodexPersonality.friendly.rawValue,
                    "requestedUpdatedPersonality": CodexPersonality.pragmatic.rawValue,
                    "notification": notification
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

    private static func runAutomationHookSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexAutomationHookSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try "# Automation hook smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                }

                await store.refreshRuntime()
                await store.installAutomationHookTemplate(
                    title: "项目监控",
                    prompt: "Raytone automation hook smoke prompt"
                )

                let configURL = codexHomeURL.appendingPathComponent("config.toml")
                let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let hooks = store.runtimeHooks
                let raytoneHooks = hooks.filter { hook in
                    let normalizedEvent = hook.eventName
                        .unicodeScalars
                        .filter { CharacterSet.alphanumerics.contains($0) }
                        .map { String($0).lowercased() }
                        .joined()
                    return normalizedEvent == "userpromptsubmit" &&
                        hook.command?.contains("raytone-automation-events.jsonl") == true
                }
                let ok = store.runtimeSnapshot.executable != nil &&
                    configText.contains("[features]") &&
                    configText.contains("hooks = true") &&
                    configText.contains("UserPromptSubmit") &&
                    configText.contains("raytone-automation-events.jsonl") &&
                    raytoneHooks.count == 1 &&
                    store.runtimeCatalogStatusText.contains("已安装 项目监控")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "configPath": configURL.path,
                    "configText": configText,
                    "hookCount": hooks.count,
                    "raytoneHookCount": raytoneHooks.count,
                    "hooks": hooks.map { hook in
                        [
                            "key": hook.key,
                            "eventName": hook.eventName,
                            "handlerType": hook.handlerType,
                            "command": hook.command ?? "",
                            "source": hook.source,
                            "sourcePath": hook.sourcePath,
                            "enabled": hook.enabled,
                            "trustStatus": hook.trustStatus
                        ] as [String: Any]
                    },
                    "status": store.runtimeCatalogStatusText,
                    "errors": store.runtimeCatalogErrors
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "unknown",
                    "runtimePath": "",
                    "runtimeVersion": "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
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

    private static func runSlashSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexSlashSmoke-\(UUID().uuidString)", isDirectory: true)

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                let readmeURL = workspaceURL.appendingPathComponent("README.md")
                try "# Slash smoke\n\nold line\n".write(to: readmeURL, atomically: true, encoding: .utf8)
                _ = try runProcess(["git", "init"], cwd: workspaceURL)
                _ = try runProcess(["git", "add", "README.md"], cwd: workspaceURL)
                _ = try runProcess([
                    "git",
                    "-c", "user.name=Raytone Smoke",
                    "-c", "user.email=raytone@example.invalid",
                    "commit",
                    "-m",
                    "initial"
                ], cwd: workspaceURL)
                try "# Slash smoke\n\nold line\nnew line from slash smoke\n".write(to: readmeURL, atomically: true, encoding: .utf8)

                let scriptDirectory = workspaceURL.appendingPathComponent("script", isDirectory: true)
                try fileManager.createDirectory(at: scriptDirectory, withIntermediateDirectories: true)
                let testScriptURL = scriptDirectory.appendingPathComponent("test.sh")
                try "#!/bin/sh\necho slash test OK\n".write(to: testScriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: testScriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.sandbox = .workspaceWrite
                store.approval = .never
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                }

                await store.refreshRuntime()
                store.prompt = "/diff"
                await store.runPrompt()
                await waitForStoreToSettle(store)

                let diffItems = store.selectedThread.items
                let diffCommands = commandRuns(in: diffItems)
                let fileChanges = fileChanges(in: diffItems)
                let diffCommand = diffCommands.last

                store.prompt = "/test"
                await store.runPrompt()
                await waitForStoreToSettle(store)

                let testCommands = commandRuns(in: store.selectedThread.items)
                let testCommand = testCommands.last

                store.prompt = "/clear"
                await store.runPrompt()
                let afterClearItemCount = store.selectedThread.items.count

                let ok = store.runtimeSnapshot.executable != nil &&
                    diffCommand?.exitCode == 0 &&
                    diffCommand?.output.contains("README.md") == true &&
                    fileChanges.contains(where: { $0.path == "README.md" && $0.additions > 0 }) &&
                    testCommand?.exitCode == 0 &&
                    testCommand?.output.contains("slash test OK") == true &&
                    afterClearItemCount == 0

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "diffCommandExitCode": Int(diffCommand?.exitCode ?? -999),
                    "diffCommandPreview": diffCommand?.command ?? "",
                    "diffOutputPreview": String((diffCommand?.output ?? "").prefix(1200)),
                    "fileChanges": fileChanges.map { change in
                        [
                            "path": change.path,
                            "type": change.type.rawValue,
                            "additions": change.additions,
                            "deletions": change.deletions
                        ] as [String: Any]
                    },
                    "testCommandExitCode": Int(testCommand?.exitCode ?? -999),
                    "testCommandPreview": testCommand?.command ?? "",
                    "testOutput": testCommand?.output ?? "",
                    "afterClearItemCount": afterClearItemCount
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "unknown",
                    "runtimePath": "",
                    "runtimeVersion": "",
                    "workspacePath": workspaceURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private struct MockResponsesServer {
        let process: Process
        let baseURL: String
        let requestLogURL: URL

        func stop() {
            if process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }
        }
    }

    private static func startMockResponsesServer(message: String) throws -> MockResponsesServer {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("RaytoneCodexMockResponses-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let messageURL = directory.appendingPathComponent("message.txt")
        let scriptURL = directory.appendingPathComponent("server.py")
        let portURL = directory.appendingPathComponent("port.txt")
        let logURL = directory.appendingPathComponent("requests.jsonl")
        try message.write(to: messageURL, atomically: true, encoding: .utf8)
        try mockResponsesServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", scriptURL.path, messageURL.path, portURL.path, logURL.path]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()

        let deadline = Date().addingTimeInterval(5)
        while !fileManager.fileExists(atPath: portURL.path), Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        guard fileManager.fileExists(atPath: portURL.path) else {
            process.terminate()
            throw NSError(
                domain: "RaytoneCodexReviewSmoke",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "mock Responses server did not publish a port"]
            )
        }

        let port = try String(contentsOf: portURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return MockResponsesServer(
            process: process,
            baseURL: "http://127.0.0.1:\(port)",
            requestLogURL: logURL
        )
    }

    private static var mockResponsesServerScript: String {
        #"""
        import json
        import sys
        from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
        from pathlib import Path

        message = Path(sys.argv[1]).read_text(encoding="utf-8")
        port_file = Path(sys.argv[2])
        log_file = Path(sys.argv[3])

        def sse_payload():
            events = [
                {"type": "response.created", "response": {"id": "resp-raytone-review"}},
                {
                    "type": "response.output_item.done",
                    "item": {
                        "type": "message",
                        "role": "assistant",
                        "id": "msg-raytone-review",
                        "content": [{"type": "output_text", "text": message}],
                    },
                },
                {
                    "type": "response.completed",
                    "response": {
                        "id": "resp-raytone-review",
                        "usage": {
                            "input_tokens": 0,
                            "input_tokens_details": None,
                            "output_tokens": 0,
                            "output_tokens_details": None,
                            "total_tokens": 0,
                        },
                    },
                },
            ]
            chunks = []
            for event in events:
                chunks.append(f"event: {event['type']}\n")
                chunks.append("data: " + json.dumps(event, separators=(",", ":")) + "\n\n")
            return "".join(chunks).encode("utf-8")

        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                length = int(self.headers.get("content-length") or "0")
                body = self.rfile.read(length).decode("utf-8", "replace")
                with log_file.open("a", encoding="utf-8") as fh:
                    fh.write(json.dumps({"path": self.path, "body": body}) + "\n")
                payload = sse_payload()
                self.send_response(200)
                self.send_header("content-type", "text/event-stream")
                self.send_header("cache-control", "no-cache")
                self.send_header("content-length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)

            def log_message(self, format, *args):
                return

        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        port_file.write_text(str(server.server_port), encoding="utf-8")
        server.serve_forever()
        """#
    }

    private static func writeMockCodexConfig(codexHome: URL, baseURL: String) throws {
        let config = """
        model = "mock-model"
        approval_policy = "never"
        sandbox_mode = "read-only"

        model_provider = "mock_provider"

        [features]
        shell_snapshot = false

        [model_providers.mock_provider]
        name = "Mock provider"
        base_url = "\(baseURL)/v1"
        wire_api = "responses"
        request_max_retries = 0
        stream_max_retries = 0
        """
        try config.write(to: codexHome.appendingPathComponent("config.toml"), atomically: true, encoding: .utf8)
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

    @MainActor
    private static func waitForStoreToSettle(_ store: SessionStore) async {
        let deadline = Date().addingTimeInterval(120)
        while store.isRunning && Date() < deadline {
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    private static func commandRuns(in items: [TranscriptItem]) -> [CommandRun] {
        items.compactMap { item in
            if case let .command(run) = item.kind {
                return run
            }
            return nil
        }
    }

    private static func fileChanges(in items: [TranscriptItem]) -> [FileChange] {
        items.compactMap { item in
            if case let .fileChange(change) = item.kind {
                return change
            }
            return nil
        }
    }

    private static func runProcess(_ arguments: [String], cwd: URL) throws -> (exitCode: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = cwd

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            throw NSError(
                domain: "RaytoneCodexSlashSmoke",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "\(arguments.joined(separator: " ")) failed: \(output)"]
            )
        }
        return (process.terminationStatus, output)
    }
}
