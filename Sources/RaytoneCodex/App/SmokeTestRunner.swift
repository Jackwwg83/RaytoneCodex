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
        } else if CommandLine.arguments.contains("--terminal-stream-smoke-test") {
            runTerminalStreamSmoke()
        } else if CommandLine.arguments.contains("--file-search-smoke-test") {
            runFileSearchSmoke()
        } else if CommandLine.arguments.contains("--local-image-input-smoke-test") {
            runLocalImageInputSmoke()
        } else if CommandLine.arguments.contains("--review-smoke-test") {
            runReviewSmoke()
        } else if CommandLine.arguments.contains("--catalog-smoke-test") {
            runCatalogSmoke()
        } else if CommandLine.arguments.contains("--mcp-resource-smoke-test") {
            runMCPResourceSmoke()
        } else if CommandLine.arguments.contains("--mcp-tool-smoke-test") {
            runMCPToolSmoke()
        } else if CommandLine.arguments.contains("--plugin-read-smoke-test") {
            runPluginReadSmoke()
        } else if CommandLine.arguments.contains("--account-auth-smoke-test") {
            runAccountAuthSmoke()
        } else if CommandLine.arguments.contains("--account-api-key-smoke-test") {
            runAccountAPIKeySmoke()
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
        } else if CommandLine.arguments.contains("--model-catalog-smoke-test") {
            runModelCatalogSmoke()
        } else if CommandLine.arguments.contains("--model-config-smoke-test") {
            runModelConfigSmoke()
        } else if CommandLine.arguments.contains("--provider-sidecar-smoke-test") {
            runProviderSidecarSmoke()
        } else if CommandLine.arguments.contains("--reasoning-config-smoke-test") {
            runReasoningConfigSmoke()
        } else if CommandLine.arguments.contains("--instructions-config-smoke-test") {
            runInstructionsConfigSmoke()
        } else if CommandLine.arguments.contains("--default-permissions-smoke-test") {
            runDefaultPermissionsSmoke()
        } else if CommandLine.arguments.contains("--auto-review-smoke-test") {
            runAutoReviewSmoke()
        } else if CommandLine.arguments.contains("--service-tier-smoke-test") {
            runServiceTierSmoke()
        } else if CommandLine.arguments.contains("--memory-settings-smoke-test") {
            runMemorySettingsSmoke()
        } else if CommandLine.arguments.contains("--work-mode-smoke-test") {
            runWorkModeSmoke()
        } else if CommandLine.arguments.contains("--desktop-settings-smoke-test") {
            runDesktopSettingsSmoke()
        } else if CommandLine.arguments.contains("--open-target-smoke-test") {
            runOpenTargetSmoke()
        } else if CommandLine.arguments.contains("--prevent-sleep-smoke-test") {
            runPreventSleepSmoke()
        } else if CommandLine.arguments.contains("--goal-smoke-test") {
            runGoalSmoke()
        } else if CommandLine.arguments.contains("--browser-navigation-smoke-test") {
            runBrowserNavigationSmoke()
        } else if CommandLine.arguments.contains("--browser-snapshot-smoke-test") {
            runBrowserSnapshotSmoke()
        } else if CommandLine.arguments.contains("--config-write-smoke-test") {
            runConfigWriteSmoke()
        } else if CommandLine.arguments.contains("--thread-management-smoke-test") {
            runThreadManagementSmoke()
        } else if CommandLine.arguments.contains("--history-smoke-test") {
            runHistorySmoke()
        } else if CommandLine.arguments.contains("--side-chat-smoke-test") {
            runSideChatSmoke()
        } else if CommandLine.arguments.contains("--environment-smoke-test") {
            runEnvironmentSmoke()
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
            let recommendedFiles = store.inspectorRecommendedFiles
            let recommendedTarget = recommendedFiles.first {
                URL(fileURLWithPath: $0).lastPathComponent == "Package.swift"
            } ?? recommendedFiles.first
            let expectedRecommendedPath: String
            if let recommendedTarget {
                if recommendedTarget.hasPrefix("/") || recommendedTarget.hasPrefix("~") {
                    expectedRecommendedPath = (recommendedTarget as NSString).expandingTildeInPath
                } else {
                    expectedRecommendedPath = URL(fileURLWithPath: workspacePath)
                        .appendingPathComponent(recommendedTarget)
                        .standardizedFileURL
                        .path
                }
                fputs("tools-smoke: openRecommendedFile\n", stderr)
                store.filePreview = nil
                store.openRecommendedFile(recommendedTarget)
                for _ in 0..<40 {
                    if store.filePreview?.path == expectedRecommendedPath {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            } else {
                expectedRecommendedPath = ""
            }
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
                filePreview?.path == expectedRecommendedPath &&
                recommendedTarget != nil &&
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
                "recommendedFiles": recommendedFiles,
                "recommendedTarget": recommendedTarget ?? "",
                "recommendedExpectedPath": expectedRecommendedPath,
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

    private static func runTerminalStreamSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexTerminalStreamSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexTerminalStreamCodexHome-\(UUID().uuidString)", isDirectory: true)

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.sandbox = .dangerFullAccess
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                await store.refreshRuntime()

                store.terminalCommand = "printf 'ready\\n'; read line; printf 'got:%s\\n' \"$line\""
                let stdinTask = Task { @MainActor in
                    await store.runTerminalCommand()
                }
                let readyDeadline = Date().addingTimeInterval(8)
                while Date() < readyDeadline,
                      store.terminalRuns.last?.output.contains("ready") != true {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let streamedBeforeInput = store.terminalIsRunning &&
                    store.terminalRuns.last?.output.contains("ready") == true

                store.terminalCommand = "raytone-stdin-smoke"
                await store.runTerminalCommand()
                _ = await stdinTask.value
                let stdinRun = store.terminalRuns.last

                store.terminalCommand = "printf 'sleeping\\n'; sleep 20; printf 'done\\n'"
                let terminateTask = Task { @MainActor in
                    await store.runTerminalCommand()
                }
                let sleepingDeadline = Date().addingTimeInterval(8)
                while Date() < sleepingDeadline,
                      store.terminalRuns.last?.output.contains("sleeping") != true {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let streamedBeforeTerminate = store.terminalIsRunning &&
                    store.terminalRuns.last?.output.contains("sleeping") == true
                await store.stopTerminalCommand()
                _ = await terminateTask.value
                let terminatedRun = store.terminalRuns.last

                let ok = store.runtimeSnapshot.executable != nil &&
                    streamedBeforeInput &&
                    stdinRun?.output.contains("got:raytone-stdin-smoke") == true &&
                    stdinRun?.status == .succeeded &&
                    streamedBeforeTerminate &&
                    terminatedRun?.output.contains("sleeping") == true &&
                    terminatedRun?.output.contains("done") != true &&
                    store.terminalIsRunning == false

                let stdinOutput = stdinRun?.output ?? ""
                let terminatedOutput = terminatedRun?.output ?? ""
                await store.stopAppServerForTesting()

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "streamedBeforeInput": streamedBeforeInput,
                    "stdinExitCode": Int(stdinRun?.exitCode ?? -999),
                    "stdinStatus": terminalStatusName(stdinRun?.status),
                    "stdinOutput": stdinOutput,
                    "streamedBeforeTerminate": streamedBeforeTerminate,
                    "terminatedExitCode": Int(terminatedRun?.exitCode ?? -999),
                    "terminatedStatus": terminalStatusName(terminatedRun?.status),
                    "terminatedOutput": terminatedOutput
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

    private static func runFileSearchSmoke() {
        Task { @MainActor in
            do {
                let payload = try await fileSearchSmokePayload()
                let ok = payload["ok"] as? Bool ?? false
                emitJSON(payload)
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "unknown",
                    "runtimePath": "",
                    "runtimeVersion": "",
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    @MainActor
    private static func fileSearchSmokePayload() async throws -> [String: Any] {
        let fileManager = FileManager.default
        let workspaceURL = fileManager.temporaryDirectory
            .appendingPathComponent("RaytoneCodexFileSearchSmoke-\(UUID().uuidString)", isDirectory: true)
        let codexHomeURL = fileManager.temporaryDirectory
            .appendingPathComponent("RaytoneCodexFileSearchCodexHome-\(UUID().uuidString)", isDirectory: true)
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
        await store.loadFilePanelDirectory(workspaceURL.path)
        let watchedStatus = store.filePanelStatusText

        let watchedFileURL = workspaceURL.appendingPathComponent("WatchedRuntimeFile.txt")
        try "watch-refresh-runtime-proof\n".write(to: watchedFileURL, atomically: true, encoding: .utf8)
        let watchDeadline = Date().addingTimeInterval(8)
        while Date() < watchDeadline,
              !store.fileEntries.contains(where: { $0.path == watchedFileURL.path }) {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        let watchedResult = store.fileEntries.first { $0.path == watchedFileURL.path }
        let statusAfterWatch = store.filePanelStatusText

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
            preview?.text.contains("fuzzy-file-search-runtime-proof") == true &&
            preview?.byteCount == targetText.utf8.count &&
            preview?.modifiedAt != nil &&
            watchedStatus.contains("已监听") &&
            watchedResult?.name == "WatchedRuntimeFile.txt"

        let resultsPayload = store.fileSearchResults.prefix(8).map { result in
            [
                "name": result.name,
                "path": result.path,
                "isDirectory": result.isDirectory,
                "isFile": result.isFile
            ] as [String: Any]
        }
        let previewPayload: [String: Any] = [
            "path": preview?.path ?? "",
            "fileName": preview?.fileName ?? "",
            "textPreview": String((preview?.text ?? "").prefix(200)),
            "byteCount": preview?.byteCount ?? 0,
            "metadataSummary": preview?.metadataSummary ?? "",
            "isTruncated": preview?.isTruncated ?? false
        ]

        return [
            "ok": ok,
            "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
            "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
            "runtimeVersion": store.runtimeSnapshot.version ?? "",
            "workspacePath": workspaceURL.path,
            "codexHomePath": codexHomeURL.path,
            "query": store.fileSearchQuery,
            "initialFilePanelStatus": watchedStatus,
            "watchedFileObserved": watchedResult?.path ?? "",
            "filePanelStatusAfterWatch": statusAfterWatch,
            "fileEntriesPreview": Array(store.fileEntries.map(\.name).prefix(12)),
            "searchStatus": store.fileSearchStatusText,
            "resultCount": store.fileSearchResults.count,
            "results": resultsPayload,
            "openedPreview": previewPayload
        ]
    }

    private static func runLocalImageInputSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexLocalImageSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexLocalImageCodexHome-\(UUID().uuidString)", isDirectory: true)
            var mockServer: MockResponsesServer?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)

                let imageURL = workspaceURL.appendingPathComponent("raytone-local-image-smoke.png")
                let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
                guard let pngData = Data(base64Encoded: pngBase64) else {
                    throw NSError(
                        domain: "RaytoneCodexLocalImageSmoke",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "failed to decode smoke PNG"]
                    )
                }
                try pngData.write(to: imageURL)

                mockServer = try startMockResponsesServer(message: "Raytone local image smoke OK")
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
                    store.projects[index].name = "LocalImageSmoke"
                }

                await store.refreshRuntime()
                store.prompt = "请根据图片回复：Raytone local image smoke OK"
                await store.addImageReferencesToPrompt(paths: [imageURL.path])
                let turnInput = CodexAppServerClient.userInputItems(
                    prompt: store.prompt,
                    localImagePaths: store.pendingLocalImagePaths
                )
                await store.runPrompt()
                await waitForStoreToSettle(store)
                await store.stopAppServerForTesting()

                let agentMessages = store.selectedThread.items.compactMap { item -> String? in
                    if case let .agentMessage(text) = item.kind { return text }
                    return nil
                }
                let requestLog = (try? String(contentsOf: mockServer!.requestLogURL, encoding: .utf8)) ?? ""
                let requestContainsImage = requestLog.contains("input_image") ||
                    requestLog.contains("localImage") ||
                    requestLog.contains("raytone-local-image-smoke")
                let ok = store.runtimeSnapshot.executable != nil &&
                    !store.isRunning &&
                    store.lastLocalImageInputPreview == [imageURL.path] &&
                    store.pendingLocalImagePaths.isEmpty &&
                    agentMessages.contains("Raytone local image smoke OK") &&
                    requestLog.contains("/v1/responses") &&
                    requestContainsImage

                mockServer?.stop()
                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "imagePath": imageURL.path,
                    "lastLocalImageInputPreview": store.lastLocalImageInputPreview,
                    "pendingLocalImageCount": store.pendingLocalImagePaths.count,
                    "turnInput": jsonObject(from: turnInput),
                    "requestContainsImage": requestContainsImage,
                    "mockRequestLogPreview": String(requestLog.prefix(1200)),
                    "agentMessages": agentMessages
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
            fputs("catalog-smoke: reloadRuntimeMCPServers\n", stderr)
            await store.reloadRuntimeMCPServers()
            let mcpReloadStatus = store.runtimeCatalogStatusText
            let mcpReloadErrors = store.runtimeCatalogErrors
            fputs("catalog-smoke: collect result\n", stderr)

            let config = store.runtimeConfig
            let hasConfig = config != nil
            let ok = store.runtimeSnapshot.executable != nil &&
                hasConfig &&
                !store.runtimeCatalogStatusText.hasPrefix("app-server 读取失败") &&
                !mcpReloadStatus.hasPrefix("MCP 重载失败")

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "status": store.runtimeCatalogStatusText,
                "errorCount": store.runtimeCatalogErrors.count,
                "errors": store.runtimeCatalogErrors,
                "mcpReloadStatus": mcpReloadStatus,
                "mcpReloadErrors": mcpReloadErrors,
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

    private static func runMCPResourceSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let marker = "Raytone MCP resource smoke OK \(UUID().uuidString.prefix(8))"
        let serverName = "raytone_resource"
        let resourceURI = "raytone://resource/smoke"

        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexMCPResourceSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let serverURL = rootURL.appendingPathComponent("raytone_mcp_resource_server.py")

            do {
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try mcpResourceSmokeServerScript(marker: marker, resourceURI: resourceURI)
                    .write(to: serverURL, atomically: true, encoding: .utf8)

                let escapedServerPath = serverURL.path
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                let config = """
                approval_policy = "never"
                sandbox_mode = "read-only"

                [mcp_servers.\(serverName)]
                command = "/usr/bin/python3"
                args = ["\(escapedServerPath)"]
                """
                try config.write(to: codexHomeURL.appendingPathComponent("config.toml"), atomically: true, encoding: .utf8)

                let store = SessionStore()
                store.workspacePath = workspacePath
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                fputs("mcp-resource-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                fputs("mcp-resource-smoke: refreshRuntimeMCPServers\n", stderr)
                await store.refreshRuntimeMCPServers()

                guard let server = store.runtimeMCPServers.first(where: { $0.name == serverName }),
                      let resource = server.resources.first(where: { $0.uri == resourceURI }) else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                        "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                        "runtimeVersion": store.runtimeSnapshot.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHomeURL.path,
                        "serverName": serverName,
                        "resourceURI": resourceURI,
                        "status": store.runtimeCatalogStatusText,
                        "errors": store.runtimeCatalogErrors,
                        "servers": store.runtimeMCPServers.map { server in
                            [
                                "name": server.name,
                                "title": server.title,
                                "authStatus": server.authStatus,
                                "toolNames": server.toolNames,
                                "resourceCount": server.resourceCount,
                                "resources": server.resources.map(\.uri)
                            ] as [String: Any]
                        }
                    ])
                    exit(1)
                }

                fputs("mcp-resource-smoke: readMCPResource\n", stderr)
                await store.readMCPResource(resource, from: server)
                let preview = store.mcpResourcePreview?.textPreview ?? ""
                let ok = store.runtimeSnapshot.executable != nil &&
                    server.resourceCount == 1 &&
                    resource.displayName == "Raytone MCP Smoke Resource" &&
                    store.mcpResourcePreview?.server == serverName &&
                    store.mcpResourcePreview?.requestedURI == resourceURI &&
                    preview.contains(marker) &&
                    store.mcpResourceStatusText.hasPrefix("mcpServer/resource/read")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHomeURL.path,
                    "serverName": server.name,
                    "serverTitle": server.title,
                    "authStatus": server.authStatus,
                    "resourceCount": server.resourceCount,
                    "resource": [
                        "name": resource.name,
                        "displayName": resource.displayName,
                        "uri": resource.uri,
                        "mimeType": resource.mimeType ?? ""
                    ] as [String: Any],
                    "readStatus": store.mcpResourceStatusText,
                    "contentCount": store.mcpResourcePreview?.contents.count ?? 0,
                    "preview": preview
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "unknown",
                    "runtimePath": "",
                    "runtimeVersion": "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runMCPToolSmoke() {
        let marker = "Raytone MCP tool smoke OK \(UUID().uuidString.prefix(8))"
        let message = "hello from Raytone"
        let serverName = "raytone_tool"
        let toolName = "echo_tool"

        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexMCPToolSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let serverURL = rootURL.appendingPathComponent("raytone_mcp_tool_server.py")
            var mockServer: MockResponsesServer?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try mcpToolSmokeServerScript(marker: marker, toolName: toolName)
                    .write(to: serverURL, atomically: true, encoding: .utf8)

                mockServer = try startMockResponsesServer(message: "Raytone MCP tool model fallback")
                try writeMockCodexConfig(codexHome: codexHomeURL, baseURL: mockServer!.baseURL)
                let escapedServerPath = serverURL.path
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                let configURL = codexHomeURL.appendingPathComponent("config.toml")
                var config = try String(contentsOf: configURL, encoding: .utf8)
                config.append(
                    """

                    [mcp_servers.\(serverName)]
                    command = "/usr/bin/python3"
                    args = ["\(escapedServerPath)"]
                    """
                )
                try config.write(to: configURL, atomically: true, encoding: .utf8)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.model = "mock-model"
                store.sandbox = .readOnly
                store.approval = .never
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                fputs("mcp-tool-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                fputs("mcp-tool-smoke: refreshRuntimeMCPServers\n", stderr)
                await store.refreshRuntimeMCPServers()

                guard let server = store.runtimeMCPServers.first(where: { $0.name == serverName }),
                      let tool = server.tools.first(where: { $0.name == toolName }) else {
                    mockServer?.stop()
                    emitJSON([
                        "ok": false,
                        "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                        "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                        "runtimeVersion": store.runtimeSnapshot.version ?? "",
                        "workspacePath": workspaceURL.path,
                        "codexHome": codexHomeURL.path,
                        "serverName": serverName,
                        "toolName": toolName,
                        "status": store.runtimeCatalogStatusText,
                        "errors": store.runtimeCatalogErrors,
                        "servers": store.runtimeMCPServers.map { server in
                            [
                                "name": server.name,
                                "title": server.title,
                                "toolNames": server.toolNames,
                                "resourceCount": server.resourceCount
                            ] as [String: Any]
                        }
                    ])
                    exit(1)
                }

                let key = store.mcpToolCallKey(tool, server: server)
                store.mcpToolArgumentText[key] = #"{"message":"\#(message)"}"#
                fputs("mcp-tool-smoke: callMCPTool\n", stderr)
                await store.callMCPTool(tool, from: server)
                let preview = store.mcpToolCallPreview?.textPreview ?? ""
                let threadID = store.selectedThread.appServerThreadID ?? ""
                let ok = store.runtimeSnapshot.executable != nil &&
                    server.toolNames.contains(toolName) &&
                    store.mcpToolCallPreview?.server == serverName &&
                    store.mcpToolCallPreview?.tool == toolName &&
                    store.mcpToolCallPreview?.isError == false &&
                    preview.contains("echo: \(message)") &&
                    preview.contains(marker) &&
                    preview.contains(threadID) &&
                    !threadID.isEmpty &&
                    store.mcpToolCallStatusText.hasPrefix("mcpServer/tool/call")

                await store.stopAppServerForTesting()
                mockServer?.stop()
                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "serverName": server.name,
                    "serverTitle": server.title,
                    "toolName": tool.name,
                    "toolDisplayName": tool.displayName,
                    "threadID": threadID,
                    "callStatus": store.mcpToolCallStatusText,
                    "contentCount": store.mcpToolCallPreview?.content.count ?? 0,
                    "preview": preview
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
                    "codexHome": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runPluginReadSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexPluginReadSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let pluginName = "demo-plugin"
            let marketplaceName = "codex-curated"

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try writePluginReadSmokeFixture(workspaceURL: workspaceURL, codexHomeURL: codexHomeURL)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                fputs("plugin-read-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                fputs("plugin-read-smoke: refreshRuntimeCatalog\n", stderr)
                await store.refreshRuntimeCatalog(forceReloadSkills: true)

                guard let plugin = store.runtimePlugins.first(where: { $0.name == pluginName && $0.marketplaceName == marketplaceName }) else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                        "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                        "runtimeVersion": store.runtimeSnapshot.version ?? "",
                        "workspacePath": workspaceURL.path,
                        "codexHome": codexHomeURL.path,
                        "status": store.runtimeCatalogStatusText,
                        "errors": store.runtimeCatalogErrors,
                        "plugins": store.runtimePlugins.map { plugin in
                            [
                                "id": plugin.id,
                                "name": plugin.name,
                                "marketplace": plugin.marketplaceName,
                                "installed": plugin.installed,
                                "enabled": plugin.enabled
                            ] as [String: Any]
                        }
                    ])
                    exit(1)
                }

                fputs("plugin-read-smoke: readRuntimePluginDetail\n", stderr)
                await store.readRuntimePluginDetail(plugin)
                let detail = store.runtimePluginDetail
                let ok = store.runtimeSnapshot.executable != nil &&
                    plugin.installed &&
                    plugin.enabled &&
                    detail?.plugin.id == "\(pluginName)@\(marketplaceName)" &&
                    detail?.description == "Raytone plugin/read smoke long description" &&
                    detail?.skills.contains(where: { $0.name == "\(pluginName):thread-summarizer" && !$0.enabled }) == true &&
                    detail?.mcpServers.contains("demo") == true &&
                    detail?.hooks.contains(where: { $0.eventName == "preToolUse" }) == true &&
                    store.runtimePluginDetailStatusText.hasPrefix("plugin/read")

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "plugin": [
                        "id": detail?.plugin.id ?? "",
                        "name": detail?.plugin.name ?? "",
                        "displayName": detail?.plugin.displayName ?? "",
                        "installed": detail?.plugin.installed ?? false,
                        "enabled": detail?.plugin.enabled ?? false
                    ] as [String: Any],
                    "detailStatus": store.runtimePluginDetailStatusText,
                    "description": detail?.description ?? "",
                    "skills": detail?.skills.map { skill in
                        [
                            "name": skill.name,
                            "displayName": skill.displayName,
                            "enabled": skill.enabled
                        ] as [String: Any]
                    } ?? [],
                    "mcpServers": detail?.mcpServers ?? [],
                    "hooks": detail?.hooks.map { hook in
                        [
                            "key": hook.key,
                            "eventName": hook.eventName
                        ] as [String: Any]
                    } ?? []
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

    private static func runConfigWriteSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
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

    private static func runModelCatalogSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            await store.refreshRuntime()
            await store.refreshModelCatalog()

            let openAIProvider = store.providers.first { $0.id == "openai" }
            let defaultModel = store.codexModelCatalog.first(where: \.isDefault) ?? store.codexModelCatalog.first
            let defaultModelID = defaultModel?.id ?? ""
            let menuTitle = defaultModel.map { store.modelMenuTitle(providerID: "openai", model: $0.id) } ?? ""
            let ok = store.runtimeSnapshot.executable != nil &&
                !store.codexModelCatalog.isEmpty &&
                openAIProvider?.models == store.codexModelCatalog.map(\.id) &&
                defaultModel?.displayName.isEmpty == false &&
                defaultModel?.defaultReasoningEffort?.isEmpty == false &&
                menuTitle.contains(defaultModel?.displayName ?? "") &&
                menuTitle.contains("推理")

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "status": store.modelCatalogStatusText,
                "catalogCount": store.codexModelCatalog.count,
                "providerModelCount": openAIProvider?.models.count ?? 0,
                "defaultModelID": defaultModelID,
                "defaultMenuTitle": menuTitle,
                "modelsPreview": Array(store.codexModelCatalog.prefix(8).map { model in
                    [
                        "id": model.id,
                        "model": model.model,
                        "displayName": model.displayName,
                        "defaultReasoningEffort": model.defaultReasoningEffort ?? "",
                        "supportedReasoningEfforts": model.supportedReasoningEfforts.map(\.effort),
                        "inputModalities": model.inputModalities,
                        "supportsPersonality": model.supportsPersonality,
                        "isDefault": model.isDefault
                    ] as [String: Any]
                })
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runModelConfigSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let selectedModel = argument(after: "--model") ?? "gpt-5.1-codex"

        Task { @MainActor in
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexModelConfigSmoke-\(UUID().uuidString)", isDirectory: true)
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                await store.saveRuntimeModelSelection(providerID: "openai", model: selectedModel)
                let config = store.runtimeConfig
                await store.stopAppServerForTesting()

                let configURL = codexHome.appendingPathComponent("config.toml")
                let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let ok = store.selectedProviderID == "openai" &&
                    store.model == selectedModel &&
                    config?.model == selectedModel &&
                    config?.modelProvider == "openai" &&
                    configText.contains("model = \"\(selectedModel)\"") &&
                    configText.contains("model_provider = \"openai\"")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "selectedProviderID": store.selectedProviderID,
                    "storeModel": store.model,
                    "modelDisplayName": store.modelDisplayName,
                    "configModel": config?.model ?? "",
                    "configModelProvider": config?.modelProvider ?? "",
                    "modelCatalogStatusText": store.modelCatalogStatusText,
                    "runtimeCatalogStatusText": store.runtimeCatalogStatusText,
                    "configText": configText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runProviderSidecarSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let providerID = "smoke-\(UUID().uuidString.prefix(8))"
        let editedBaseURL = "http://127.0.0.1:65534/v1"
        let editedModel = "smoke-edited-model"

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.providers.append(RaytoneProviderConfiguration(
                id: providerID,
                displayName: "Smoke Provider",
                baseURL: "http://127.0.0.1:65535/v1",
                model: "smoke-model",
                models: ["smoke-model"],
                kind: .chatCompletionsSidecar
            ))

            do {
                await store.saveProviderEndpoint(
                    providerID: providerID,
                    baseURL: editedBaseURL,
                    model: editedModel
                )
                try store.saveProviderAPIKey("raytone-smoke-key", providerID: providerID)
                await store.refreshRuntime()
                await store.testProviderConnection(providerID: providerID)

                let codexConfigText = (try? String(
                    contentsOfFile: store.providerConnectionCodexConfigPath,
                    encoding: .utf8
                )) ?? ""
                let proxyConfigText = (try? String(
                    contentsOfFile: store.providerConnectionProxyConfigPath,
                    encoding: .utf8
                )) ?? ""
                let ok = store.runtimeSnapshot.executable != nil &&
                    store.selectedProviderID == providerID &&
                    store.providerConnectionStatusText.contains("sidecar 已就绪") &&
                    store.providerConnectionBaseURL.contains("127.0.0.1") &&
                    store.selectedProvider.baseURL == editedBaseURL &&
                    store.selectedProvider.model == editedModel &&
                    codexConfigText.contains("model_provider = \"raytone-\(providerID)\"") &&
                    codexConfigText.contains("model = \"\(editedModel)\"") &&
                    codexConfigText.contains("wire_api = \"responses\"") &&
                    codexConfigText.contains("base_url = \"\(store.providerConnectionBaseURL)") &&
                    proxyConfigText.contains("current_provider = \"\(providerID)\"") &&
                    proxyConfigText.contains("base_url = \"\(editedBaseURL)\"") &&
                    proxyConfigText.contains("model = \"\(editedModel)\"") &&
                    proxyConfigText.contains("api_key_env = \"RAYTONE_PROVIDER_API_KEY\"")

                await store.stopAppServerForTesting()
                try? RaytoneKeychainService.deletePassword(account: providerID)

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "providerID": providerID,
                    "editedBaseURL": editedBaseURL,
                    "editedModel": editedModel,
                    "status": store.providerConnectionStatusText,
                    "detail": store.providerConnectionDetailText,
                    "sidecar": store.sidecarStatusText,
                    "baseURL": store.providerConnectionBaseURL,
                    "codexConfigPath": store.providerConnectionCodexConfigPath,
                    "proxyConfigPath": store.providerConnectionProxyConfigPath,
                    "codexConfigText": codexConfigText,
                    "proxyConfigText": proxyConfigText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                try? RaytoneKeychainService.deletePassword(account: providerID)
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "providerID": providerID,
                    "status": store.providerConnectionStatusText,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runReasoningConfigSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexReasoningConfigSmoke-\(UUID().uuidString)", isDirectory: true)
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                await store.saveRuntimeThinkingEnabled(providerID: "openai", enabled: false)
                let offConfig = store.runtimeConfig
                let configURL = codexHome.appendingPathComponent("config.toml")
                let offConfigText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""

                await store.saveRuntimeThinkingEnabled(providerID: "openai", enabled: true)
                let onConfig = store.runtimeConfig
                let onConfigText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let ok = offConfig?.reasoningEffort == "none" &&
                    offConfig?.reasoningSummary == "none" &&
                    offConfigText.contains("model_reasoning_effort = \"none\"") &&
                    offConfigText.contains("model_reasoning_summary = \"none\"") &&
                    onConfig?.reasoningEffort == "medium" &&
                    onConfig?.reasoningSummary == "auto" &&
                    onConfigText.contains("model_reasoning_effort = \"medium\"") &&
                    onConfigText.contains("model_reasoning_summary = \"auto\"")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "off": [
                        "reasoningEffort": offConfig?.reasoningEffort ?? "",
                        "reasoningSummary": offConfig?.reasoningSummary ?? "",
                        "configText": offConfigText
                    ],
                    "on": [
                        "reasoningEffort": onConfig?.reasoningEffort ?? "",
                        "reasoningSummary": onConfig?.reasoningSummary ?? "",
                        "configText": onConfigText
                    ],
                    "modelCatalogStatusText": store.modelCatalogStatusText,
                    "runtimeCatalogStatusText": store.runtimeCatalogStatusText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runInstructionsConfigSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let marker = "Raytone developer instructions smoke \(UUID().uuidString.prefix(8))"

        Task { @MainActor in
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexInstructionsConfigSmoke-\(UUID().uuidString)", isDirectory: true)
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                await store.saveInstructions(marker)
                let config = store.runtimeConfig
                await store.stopAppServerForTesting()

                let configURL = codexHome.appendingPathComponent("config.toml")
                let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let ok = config?.developerInstructions == marker &&
                    config?.instructions != marker &&
                    configText.contains("developer_instructions") &&
                    configText.contains(marker) &&
                    !configText.contains("\ninstructions =")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "developerInstructions": config?.developerInstructions ?? "",
                    "systemInstructions": config?.instructions ?? "",
                    "status": store.runtimeCatalogStatusText,
                    "configText": configText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runDefaultPermissionsSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexDefaultPermissionsSmoke-\(UUID().uuidString)", isDirectory: true)
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                let configURL = codexHome.appendingPathComponent("config.toml")

                await store.saveRuntimeDefaultPermissions(defaultEnabled: true, fullAccess: false)
                let workspaceConfig = store.runtimeConfig
                let workspaceConfigText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let workspaceState: [String: Any] = [
                    "profile": workspaceConfig?.defaultPermissions ?? "",
                    "storeProfile": store.runtimeDefaultPermissionsProfile,
                    "defaultEnabled": store.defaultPermissionsEnabled,
                    "fullAccess": store.defaultFullAccessPermissionsEnabled,
                    "configText": workspaceConfigText
                ]

                await store.saveRuntimeDefaultPermissions(defaultEnabled: false, fullAccess: false)
                let readOnlyConfig = store.runtimeConfig
                let readOnlyConfigText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let readOnlyState: [String: Any] = [
                    "profile": readOnlyConfig?.defaultPermissions ?? "",
                    "storeProfile": store.runtimeDefaultPermissionsProfile,
                    "defaultEnabled": store.defaultPermissionsEnabled,
                    "fullAccess": store.defaultFullAccessPermissionsEnabled,
                    "configText": readOnlyConfigText
                ]

                await store.saveRuntimeDefaultPermissions(defaultEnabled: true, fullAccess: true)
                let fullAccessConfig = store.runtimeConfig
                let fullAccessConfigText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let fullAccessState: [String: Any] = [
                    "profile": fullAccessConfig?.defaultPermissions ?? "",
                    "storeProfile": store.runtimeDefaultPermissionsProfile,
                    "defaultEnabled": store.defaultPermissionsEnabled,
                    "fullAccess": store.defaultFullAccessPermissionsEnabled,
                    "configText": fullAccessConfigText
                ]

                await store.stopAppServerForTesting()

                let ok = workspaceConfig?.defaultPermissions == ":workspace" &&
                    workspaceConfigText.contains("default_permissions = \":workspace\"") &&
                    readOnlyConfig?.defaultPermissions == ":read-only" &&
                    readOnlyConfigText.contains("default_permissions = \":read-only\"") &&
                    readOnlyState["defaultEnabled"] as? Bool == false &&
                    readOnlyState["fullAccess"] as? Bool == false &&
                    fullAccessConfig?.defaultPermissions == ":danger-full-access" &&
                    fullAccessConfigText.contains("default_permissions = \":danger-full-access\"") &&
                    fullAccessState["defaultEnabled"] as? Bool == true &&
                    fullAccessState["fullAccess"] as? Bool == true

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "workspace": workspaceState,
                    "readOnly": readOnlyState,
                    "fullAccess": fullAccessState,
                    "runtimeCatalogStatusText": store.runtimeCatalogStatusText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runAutoReviewSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexAutoReviewSmoke-\(UUID().uuidString)", isDirectory: true)
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                let configURL = codexHome.appendingPathComponent("config.toml")

                await store.saveRuntimeAutoReviewEnabled(true)
                let enabledConfig = store.runtimeConfig
                let enabledConfigText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let enabledState: [String: Any] = [
                    "storeApprovalsReviewer": store.approvalsReviewer.rawValue,
                    "configApprovalsReviewer": enabledConfig?.approvalsReviewer ?? "",
                    "accessMode": store.accessMode.shortTitle,
                    "configText": enabledConfigText
                ]

                await store.saveRuntimeAutoReviewEnabled(false)
                let disabledConfig = store.runtimeConfig
                let disabledConfigText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let disabledState: [String: Any] = [
                    "storeApprovalsReviewer": store.approvalsReviewer.rawValue,
                    "configApprovalsReviewer": disabledConfig?.approvalsReviewer ?? "",
                    "accessMode": store.accessMode.shortTitle,
                    "configText": disabledConfigText
                ]

                await store.stopAppServerForTesting()

                let ok = enabledConfig?.approvalsReviewer == CodexApprovalsReviewer.autoReview.rawValue &&
                    enabledConfigText.contains("approvals_reviewer = \"auto_review\"") &&
                    enabledState["storeApprovalsReviewer"] as? String == CodexApprovalsReviewer.autoReview.rawValue &&
                    disabledConfig?.approvalsReviewer == CodexApprovalsReviewer.user.rawValue &&
                    disabledConfigText.contains("approvals_reviewer = \"user\"") &&
                    disabledState["storeApprovalsReviewer"] as? String == CodexApprovalsReviewer.user.rawValue

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "enabled": enabledState,
                    "disabled": disabledState,
                    "runtimeCatalogStatusText": store.runtimeCatalogStatusText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runServiceTierSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexServiceTierSmoke-\(UUID().uuidString)", isDirectory: true)
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                let configURL = codexHome.appendingPathComponent("config.toml")
                var states: [[String: Any]] = []
                var ok = true

                for (label, expectedConfigValue, acceptedReadValues) in [
                    ("标准", "default", ["default"]),
                    ("更快", "fast", ["fast", "priority"]),
                    ("更稳", "flex", ["flex"])
                ] {
                    await store.saveRuntimeServiceTier(label: label)
                    let config = store.runtimeConfig
                    let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                    let readValue = config?.serviceTier ?? ""
                    let state: [String: Any] = [
                        "label": label,
                        "expectedConfigValue": expectedConfigValue,
                        "readServiceTier": readValue,
                        "uiLabel": store.runtimeServiceTierLabel,
                        "configText": configText
                    ]
                    states.append(state)
                    ok = ok &&
                        acceptedReadValues.contains(readValue) &&
                        store.runtimeServiceTierLabel == label &&
                        configText.contains("service_tier = \"\(expectedConfigValue)\"")
                }

                await store.stopAppServerForTesting()

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "states": states,
                    "runtimeCatalogStatusText": store.runtimeCatalogStatusText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runMemorySettingsSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexMemorySettingsSmoke-\(UUID().uuidString)", isDirectory: true)
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                let configURL = codexHome.appendingPathComponent("config.toml")

                await store.saveRuntimeMemoryEnabled(false)
                let disabledConfig = store.runtimeConfig
                let disabledText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let disabledState: [String: Any] = [
                    "runtimeMemoryEnabled": store.runtimeMemoryEnabled,
                    "generateMemories": disabledConfig?.memoryGenerateMemories as Any,
                    "useMemories": disabledConfig?.memoryUseMemories as Any,
                    "configText": disabledText
                ]

                await store.saveRuntimeMemoryEnabled(true)
                let enabledConfig = store.runtimeConfig
                let enabledText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let enabledState: [String: Any] = [
                    "runtimeMemoryEnabled": store.runtimeMemoryEnabled,
                    "generateMemories": enabledConfig?.memoryGenerateMemories as Any,
                    "useMemories": enabledConfig?.memoryUseMemories as Any,
                    "configText": enabledText
                ]

                await store.saveRuntimeSkipToolAssistedChats(true)
                let skipEnabledConfig = store.runtimeConfig
                let skipEnabledText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let skipEnabledState: [String: Any] = [
                    "runtimeSkipToolAssistedChats": store.runtimeSkipToolAssistedChats,
                    "disableOnExternalContext": skipEnabledConfig?.memoryDisableOnExternalContext as Any,
                    "configText": skipEnabledText
                ]

                await store.saveRuntimeSkipToolAssistedChats(false)
                let skipDisabledConfig = store.runtimeConfig
                let skipDisabledText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let skipDisabledState: [String: Any] = [
                    "runtimeSkipToolAssistedChats": store.runtimeSkipToolAssistedChats,
                    "disableOnExternalContext": skipDisabledConfig?.memoryDisableOnExternalContext as Any,
                    "configText": skipDisabledText
                ]

                await store.refreshRuntimeCatalog(forceReloadSkills: true)
                let chronicleState: [String: Any] = [
                    "available": store.chronicleRuntimeAvailable,
                    "status": store.chronicleRuntimeStatusText,
                    "detail": store.chronicleRuntimeDetailText,
                    "source": store.chronicleRuntimeSourceText,
                    "skillCount": store.runtimeSkills.count,
                    "mcpServerCount": store.runtimeMCPServers.count
                ]

                await store.stopAppServerForTesting()

                let ok = disabledConfig?.memoryGenerateMemories == false &&
                    disabledConfig?.memoryUseMemories == false &&
                    disabledText.contains("[memories]") &&
                    disabledText.contains("generate_memories = false") &&
                    disabledText.contains("use_memories = false") &&
                    enabledConfig?.memoryGenerateMemories == true &&
                    enabledConfig?.memoryUseMemories == true &&
                    enabledText.contains("generate_memories = true") &&
                    enabledText.contains("use_memories = true") &&
                    skipEnabledConfig?.memoryDisableOnExternalContext == true &&
                    skipEnabledText.contains("disable_on_external_context = true") &&
                    skipDisabledConfig?.memoryDisableOnExternalContext == false &&
                    skipDisabledText.contains("disable_on_external_context = false") &&
                    !store.chronicleRuntimeStatusText.isEmpty &&
                    !store.chronicleRuntimeDetailText.isEmpty

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "disabled": disabledState,
                    "enabled": enabledState,
                    "skipEnabled": skipEnabledState,
                    "skipDisabled": skipDisabledState,
                    "chronicleRuntime": chronicleState,
                    "runtimeCatalogStatusText": store.runtimeCatalogStatusText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runWorkModeSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexWorkModeSmoke-\(UUID().uuidString)", isDirectory: true)
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                let configURL = codexHome.appendingPathComponent("config.toml")

                await store.saveRuntimeWorkMode(id: "coding")
                let codingConfig = store.runtimeConfig
                let codingText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let codingState: [String: Any] = [
                    "workModeID": store.runtimeWorkModeID,
                    "modelVerbosity": codingConfig?.modelVerbosity ?? "",
                    "configText": codingText
                ]

                await store.saveRuntimeWorkMode(id: "daily")
                let dailyConfig = store.runtimeConfig
                let dailyText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let dailyState: [String: Any] = [
                    "workModeID": store.runtimeWorkModeID,
                    "modelVerbosity": dailyConfig?.modelVerbosity ?? "",
                    "configText": dailyText
                ]

                await store.stopAppServerForTesting()

                let ok = codingConfig?.modelVerbosity == "high" &&
                    codingText.contains("model_verbosity = \"high\"") &&
                    codingState["workModeID"] as? String == "coding" &&
                    dailyConfig?.modelVerbosity == "low" &&
                    dailyText.contains("model_verbosity = \"low\"") &&
                    dailyState["workModeID"] as? String == "daily"

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "coding": codingState,
                    "daily": dailyState,
                    "runtimeCatalogStatusText": store.runtimeCatalogStatusText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runDesktopSettingsSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            await executeDesktopSettingsSmoke(workspacePath: workspacePath)
        }

        dispatchMain()
    }

    @MainActor
    private static func executeDesktopSettingsSmoke(workspacePath: String) async {
        let codexHome = FileManager.default.temporaryDirectory
            .appendingPathComponent("RaytoneCodexDesktopSettingsSmoke-\(UUID().uuidString)", isDirectory: true)
        let store = SessionStore()
        store.workspacePath = workspacePath
        store.appServerEnvironmentOverridesForTesting = [
            "CODEX_HOME": codexHome.path
        ]

        do {
            try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
            await store.refreshRuntime()
            let runtime = store.runtimeSnapshot
            guard runtime.executable != nil else {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "none",
                    "runtimePath": "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": "Codex runtime executable was not found"
                ])
                exit(1)
            }

            let configURL = codexHome.appendingPathComponent("config.toml")

            await store.saveRuntimeShowInMenuBar(false)
            await store.saveRuntimeShowBottomPanel(false)
            await store.saveRuntimePreventSleepWhileRunning(false)
            await store.saveRuntimeTerminalPosition("右侧")
            await store.saveRuntimeAppearance("深色")
            let darkSchemeName = store.preferredColorSchemeName
            await store.saveRuntimeOpenTarget("Finder")
            await store.saveRuntimeLanguage("简体中文")
            await store.saveRuntimeAppearance("跟随系统")
            let systemSchemeName = store.preferredColorSchemeName
            await store.saveRuntimeAppearance("深色")

            let config = store.runtimeConfig
            let desktop = config?.desktopSettings
            let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
            await store.stopAppServerForTesting()

            let desktopValuesOk = desktop?.showInMenuBar == false &&
                desktop?.showBottomPanel == false &&
                desktop?.preventSleepWhileRunning == false &&
                desktop?.terminalPosition == "右侧" &&
                desktop?.appearance == "深色" &&
                desktop?.openTarget == "Finder" &&
                desktop?.language == "简体中文" &&
                config?.desktopKeys.contains("raytone") == true
            let appearanceMappingOk = darkSchemeName == "dark" && systemSchemeName == "system"
            let configTextOk = configText.contains("[desktop.raytone]") &&
                configText.contains("show_in_menu_bar = false") &&
                configText.contains("show_bottom_panel = false") &&
                configText.contains("prevent_sleep_while_running = false") &&
                configText.contains("terminal_position = \"右侧\"") &&
                configText.contains("appearance = \"深色\"") &&
                configText.contains("open_target = \"Finder\"") &&
                configText.contains("language = \"简体中文\"")
            let ok = desktopValuesOk && configTextOk && appearanceMappingOk
            let desktopPayload: [String: Any] = [
                "showInMenuBar": desktop?.showInMenuBar.map { $0 as Any } ?? NSNull(),
                "showBottomPanel": desktop?.showBottomPanel.map { $0 as Any } ?? NSNull(),
                "preventSleepWhileRunning": desktop?.preventSleepWhileRunning.map { $0 as Any } ?? NSNull(),
                "terminalPosition": desktop?.terminalPosition ?? "",
                "appearance": desktop?.appearance ?? "",
                "openTarget": desktop?.openTarget ?? "",
                "language": desktop?.language ?? ""
            ]
            let payload: [String: Any] = [
                "ok": ok,
                "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                "runtimePath": runtime.executable?.url.path ?? "",
                "runtimeVersion": runtime.version ?? "",
                "workspacePath": workspacePath,
                "codexHome": codexHome.path,
                "configPath": configURL.path,
                "desktopKeys": config?.desktopKeys ?? [],
                "desktop": desktopPayload,
                "appearanceMapping": [
                    "dark": darkSchemeName,
                    "system": systemSchemeName
                ],
                "configText": configText,
                "runtimeCatalogStatusText": store.runtimeCatalogStatusText
            ]
            emitJSON(payload)
            exit(ok ? 0 : 1)
        } catch {
            await store.stopAppServerForTesting()
            emitJSON([
                "ok": false,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "codexHome": codexHome.path,
                "error": error.localizedDescription
            ])
            exit(1)
        }
    }

    private static func runPreventSleepSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let codexHome = FileManager.default.temporaryDirectory
            .appendingPathComponent("RaytoneCodexPreventSleepSmoke-\(UUID().uuidString)", isDirectory: true)

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                let activeBefore = store.preventSleepAssertionIsActive
                store.desktopPreventSleepWhileRunning = true
                store.isRunning = true
                try? await Task.sleep(nanoseconds: 150_000_000)
                let activeWhileRunning = store.preventSleepAssertionIsActive
                let pmsetDuring = (try? runProcess(
                    ["pmset", "-g", "assertions"],
                    cwd: URL(fileURLWithPath: workspacePath)
                ).output) ?? ""
                let pmsetContainsRaytone = pmsetDuring.contains("PreventUserIdleSystemSleep") &&
                    pmsetDuring.contains("RaytoneCodex running Codex turn")

                await store.saveRuntimePreventSleepWhileRunning(false)
                let activeAfterPreferenceOff = store.preventSleepAssertionIsActive

                store.isRunning = false
                store.desktopPreventSleepWhileRunning = true
                store.isRunning = true
                let activeAfterReenable = store.preventSleepAssertionIsActive
                store.isRunning = false
                let activeAfterStop = store.preventSleepAssertionIsActive

                let configURL = codexHome.appendingPathComponent("config.toml")
                let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let ok = !activeBefore &&
                    activeWhileRunning &&
                    pmsetContainsRaytone &&
                    !activeAfterPreferenceOff &&
                    activeAfterReenable &&
                    !activeAfterStop &&
                    configText.contains("prevent_sleep_while_running = false")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "activeBefore": activeBefore,
                    "activeWhileRunning": activeWhileRunning,
                    "pmsetContainsRaytone": pmsetContainsRaytone,
                    "activeAfterPreferenceOff": activeAfterPreferenceOff,
                    "activeAfterReenable": activeAfterReenable,
                    "activeAfterStop": activeAfterStop,
                    "configPath": configURL.path,
                    "configText": configText,
                    "pmsetPreview": String(pmsetDuring.prefix(1600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runOpenTargetSmoke() {
        let fileManager = FileManager.default
        let smokeRoot = fileManager.temporaryDirectory
            .appendingPathComponent("RaytoneCodexOpenTargetSmoke-\(UUID().uuidString)", isDirectory: true)
        let codexHome = fileManager.temporaryDirectory
            .appendingPathComponent("RaytoneCodexOpenTargetCodexHome-\(UUID().uuidString)", isDirectory: true)

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = smokeRoot.path
            store.filePanelPath = smokeRoot.path
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]

            do {
                try fileManager.createDirectory(at: smokeRoot, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHome, withIntermediateDirectories: true)
                let targetURL = smokeRoot.appendingPathComponent("open-target-proof.txt")
                try "Raytone open target smoke\n".write(to: targetURL, atomically: true, encoding: .utf8)

                await store.refreshRuntime()
                let runtime = store.runtimeSnapshot
                guard runtime.executable != nil else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": smokeRoot.path,
                        "codexHome": codexHome.path,
                        "error": "Codex runtime executable was not found"
                    ])
                    exit(1)
                }

                store.filePreview = FilePreview(path: targetURL.path, text: "Raytone open target smoke", isTruncated: false)

                await store.saveRuntimeOpenTarget("Finder")
                let finder = store.openSelectedFileInDefaultTarget(performExternalOpen: false)
                await store.saveRuntimeOpenTarget("Terminal")
                let terminal = store.openSelectedFileInDefaultTarget(performExternalOpen: false)
                await store.saveRuntimeOpenTarget("iTerm2")
                let iTerm = store.openSelectedFileInDefaultTarget(performExternalOpen: false)

                let configURL = codexHome.appendingPathComponent("config.toml")
                let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let ok = finder?.target == .finder &&
                    finder?.selectedPath == targetURL.path &&
                    finder?.launchPath == targetURL.path &&
                    terminal?.target == .terminal &&
                    terminal?.selectedPath == targetURL.path &&
                    terminal?.launchPath == smokeRoot.path &&
                    terminal?.applicationBundleIdentifier == "com.apple.Terminal" &&
                    iTerm?.target == .iTerm2 &&
                    iTerm?.selectedPath == targetURL.path &&
                    iTerm?.launchPath == smokeRoot.path &&
                    iTerm?.applicationBundleIdentifier == "com.googlecode.iterm2" &&
                    configText.contains("open_target = \"iTerm2\"")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": smokeRoot.path,
                    "targetPath": targetURL.path,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "configText": configText,
                    "finder": openTargetPayload(finder),
                    "terminal": openTargetPayload(terminal),
                    "iTerm2": openTargetPayload(iTerm),
                    "filePanelStatus": store.filePanelStatusText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": smokeRoot.path,
                    "codexHome": codexHome.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func openTargetPayload(_ request: FileOpenTargetRequest?) -> [String: Any] {
        [
            "target": request?.target.rawValue ?? "",
            "selectedPath": request?.selectedPath ?? "",
            "launchPath": request?.launchPath ?? "",
            "applicationBundleIdentifier": request?.applicationBundleIdentifier ?? "",
            "applicationName": request?.applicationName ?? ""
        ]
    }

    private static func terminalStatusName(_ status: TerminalCommandRecord.Status?) -> String {
        switch status {
        case .running:
            "running"
        case .succeeded:
            "succeeded"
        case .failed:
            "failed"
        case nil:
            "missing"
        }
    }

    private static func runGoalSmoke() {
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
                    "workspacePath": workspacePath,
                    "error": "Codex runtime executable was not found"
                ])
                exit(1)
            }

            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexGoalSmoke-\(UUID().uuidString)", isDirectory: true)
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
                let thread = try await client.startThread(options: CodexAppServerOptions(
                    workspaceURL: URL(fileURLWithPath: workspacePath),
                    sandbox: .readOnly,
                    approvalPolicy: .never,
                    approvalsReviewer: .user
                ))

                let activeGoal = try await client.setThreadGoal(
                    threadID: thread.id,
                    objective: "RaytoneCodex goal smoke",
                    status: .active,
                    tokenBudget: 1234
                )
                let readGoal = try await client.getThreadGoal(threadID: thread.id)
                let pausedGoal = try await client.setThreadGoal(threadID: thread.id, status: .paused)
                let cleared = try await client.clearThreadGoal(threadID: thread.id)
                let afterClear = try await client.getThreadGoal(threadID: thread.id)
                await client.stop()

                let storeSmoke = await runStoreGoalSmoke(
                    workspacePath: workspacePath,
                    codexHome: codexHome
                )

                let ok = activeGoal.threadID == thread.id &&
                    activeGoal.objective == "RaytoneCodex goal smoke" &&
                    activeGoal.status == .active &&
                    activeGoal.tokenBudget == 1234 &&
                    readGoal?.objective == activeGoal.objective &&
                    pausedGoal.status == .paused &&
                    cleared &&
                    afterClear == nil &&
                    storeSmoke.ok
                var payload: [String: Any] = [
                    "ok": ok,
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "threadID": thread.id,
                    "activeGoal": goalPayload(activeGoal),
                    "readGoal": readGoal.map(goalPayload) ?? NSNull(),
                    "pausedGoal": goalPayload(pausedGoal),
                    "cleared": cleared,
                    "afterClear": afterClear.map(goalPayload) ?? NSNull()
                ]
                payload.merge(storeSmoke.payload) { _, new in new }
                emitJSON(payload)
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

    @MainActor
    private static func runStoreGoalSmoke(
        workspacePath: String,
        codexHome: URL
    ) async -> StoreGoalSmokeResult {
        let store = SessionStore()
        store.workspacePath = workspacePath
        store.sandbox = .readOnly
        store.approval = .never
        store.appServerEnvironmentOverridesForTesting = [
            "CODEX_HOME": codexHome.path
        ]

        await store.refreshRuntime()
        await store.setActiveGoal(objective: "RaytoneCodex store goal smoke", tokenBudget: 5678)
        let storeThreadID = store.selectedThread.appServerThreadID ?? ""
        let storeSetTitle = store.selectedThread.activeGoal?.title ?? ""
        let storeSetRuntimeBacked = store.selectedThread.activeGoal?.runtimeBacked ?? false

        await store.updateActiveGoalObjective("RaytoneCodex edited goal smoke")
        let storeEditedGoal = await store.refreshSelectedRuntimeGoal()
        let storeEditedTitle = store.selectedThread.activeGoal?.title ?? ""
        let storeStatusAfterEdit = store.runtimeCatalogStatusText

        await store.clearActiveGoal()
        let storeAfterClear = await store.refreshSelectedRuntimeGoal()
        let storeStatusAfterClear = store.runtimeCatalogStatusText
        await store.stopAppServerForTesting()

        let ok = !storeThreadID.isEmpty &&
            storeSetTitle == "RaytoneCodex store goal smoke" &&
            storeSetRuntimeBacked &&
            storeEditedGoal?.objective == "RaytoneCodex edited goal smoke" &&
            storeEditedTitle == "RaytoneCodex edited goal smoke" &&
            storeAfterClear == nil

        return StoreGoalSmokeResult(
            ok: ok,
            storeThreadID: storeThreadID,
            storeSetTitle: storeSetTitle,
            storeSetRuntimeBacked: storeSetRuntimeBacked,
            storeEditedGoalObjective: storeEditedGoal?.objective,
            storeEditedTitle: storeEditedTitle,
            storeStatusAfterEdit: storeStatusAfterEdit,
            storeAfterClearObjective: storeAfterClear?.objective,
            storeStatusAfterClear: storeStatusAfterClear
        )
    }

    private struct StoreGoalSmokeResult: Sendable {
        let ok: Bool
        let storeThreadID: String
        let storeSetTitle: String
        let storeSetRuntimeBacked: Bool
        let storeEditedGoalObjective: String?
        let storeEditedTitle: String
        let storeStatusAfterEdit: String
        let storeAfterClearObjective: String?
        let storeStatusAfterClear: String

        var payload: [String: Any] {
            [
                "storeThreadID": storeThreadID,
                "storeSetTitle": storeSetTitle,
                "storeSetRuntimeBacked": storeSetRuntimeBacked,
                "storeEditedGoal": storeEditedGoalObjective.map { ["objective": $0] } ?? NSNull(),
                "storeEditedTitle": storeEditedTitle,
                "storeStatusAfterEdit": storeStatusAfterEdit,
                "storeAfterClear": storeAfterClearObjective.map { ["objective": $0] } ?? NSNull(),
                "storeStatusAfterClear": storeStatusAfterClear
            ]
        }
    }

    private static func runBrowserNavigationSmoke() {
        Task { @MainActor in
            let store = SessionStore()
            let firstURL = URL(fileURLWithPath: "/tmp/raytone-browser-one.html")
            let secondURL = URL(fileURLWithPath: "/tmp/raytone-browser-two.html")

            store.updateBrowserNavigationState(
                url: firstURL,
                title: "第一页",
                canGoBack: false,
                canGoForward: false
            )
            let initialState: [String: Any] = [
                "url": store.browserURL?.path ?? "",
                "title": store.browserTitle,
                "canGoBack": store.browserCanGoBack,
                "canGoForward": store.browserCanGoForward
            ]

            store.updateBrowserNavigationState(
                url: secondURL,
                title: "第二页",
                canGoBack: true,
                canGoForward: false
            )
            store.goBackInBrowser()
            let backCommand = store.browserNavigationCommand
            store.updateBrowserNavigationState(
                url: firstURL,
                title: "第一页",
                canGoBack: false,
                canGoForward: true
            )
            let afterBackState: [String: Any] = [
                "url": store.browserURL?.path ?? "",
                "title": store.browserTitle,
                "canGoBack": store.browserCanGoBack,
                "canGoForward": store.browserCanGoForward,
                "command": backCommand?.action == .back ? "back" : "missing"
            ]

            store.goForwardInBrowser()
            let forwardCommand = store.browserNavigationCommand
            store.updateBrowserNavigationState(
                url: secondURL,
                title: "第二页",
                canGoBack: true,
                canGoForward: false
            )
            let afterForwardState: [String: Any] = [
                "url": store.browserURL?.path ?? "",
                "title": store.browserTitle,
                "canGoBack": store.browserCanGoBack,
                "canGoForward": store.browserCanGoForward,
                "command": forwardCommand?.action == .forward ? "forward" : "missing"
            ]

            let ok = initialState["title"] as? String == "第一页" &&
                initialState["canGoBack"] as? Bool == false &&
                initialState["canGoForward"] as? Bool == false &&
                backCommand?.action == .back &&
                afterBackState["title"] as? String == "第一页" &&
                afterBackState["canGoForward"] as? Bool == true &&
                forwardCommand?.action == .forward &&
                afterForwardState["title"] as? String == "第二页" &&
                afterForwardState["canGoBack"] as? Bool == true
            emitJSON([
                "ok": ok,
                "initial": initialState,
                "afterBack": afterBackState,
                "afterForward": afterForwardState
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runBrowserSnapshotSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.openBrowserSample()
            store.captureBrowserPanelScreenshot()
            let request = store.browserSnapshotRequest
            let ok = store.browserURL != nil &&
                request != nil &&
                request?.outputURL.path.contains("/screenshots/raytonecodex-browser-") == true &&
                store.browserScreenshotStatusText == "正在截取网页…"

            emitJSON([
                "ok": ok,
                "workspacePath": workspacePath,
                "browserURL": store.browserURL?.path ?? "",
                "status": store.browserScreenshotStatusText,
                "snapshotRequestID": request?.id.uuidString ?? "",
                "snapshotOutput": request?.outputURL.path ?? ""
            ])
            exit(ok ? 0 : 1)
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
                initialAgentMessages == [marker] &&
                historyThread != nil &&
                loadedUserMessages.contains(prompt) &&
                loadedAgentMessages == [marker]

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
                "initialAgentMessages": initialAgentMessages,
                "loadedUserMessages": loadedUserMessages,
                "loadedAgentMessages": loadedAgentMessages
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runSideChatSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let marker = "RaytoneCodex side chat smoke OK \(UUID().uuidString.prefix(8))"
        let prompt = "Reply exactly: \(marker)"

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.sandbox = .readOnly
            store.approval = .never

            await store.refreshRuntime()
            await store.sendSideChatMessage(prompt)

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
            let usedExecFallback = commands.contains { run in
                run.command.contains(" codex exec ") || run.command.contains("/codex exec ")
            }
            let appServerThreadID = store.selectedThread.appServerThreadID ?? ""
            let ok = !appServerThreadID.isEmpty &&
                !store.isRunning &&
                !usedExecFallback &&
                userMessages == [prompt] &&
                agentMessages == [marker] &&
                store.sideChatStatusText == "Codex 已回复"

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "marker": marker,
                "appServerThreadID": appServerThreadID,
                "usedExecFallback": usedExecFallback,
                "sideChatStatus": store.sideChatStatusText,
                "transcriptItemCount": items.count,
                "userMessages": userMessages,
                "agentMessages": agentMessages
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runEnvironmentSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            await store.refreshRuntime()
            await store.refreshWorkspaceBranches()
            let branchStatus = store.workspaceBranchStatusText

            await store.refreshWorkspaceGitDiff()
            let gitStatus = store.runtimeCatalogStatusText
            let gitErrors = store.runtimeCatalogErrors
            let diffSummary = SessionStore.diffSummary(store.workspaceGitDiff?.diff ?? "")
            let fallbackGitStatus = store.workspaceGitStatusText

            await store.refreshWorkspacePullRequestStatus()
            let pullRequestStatus = store.workspacePullRequestStatusText

            await store.refreshWorkspaceWorktrees()
            let worktreeStatus = store.runtimeCatalogStatusText
            let worktreeErrors = store.runtimeCatalogErrors

            await store.runGitCommitPushPreflightInTerminal()
            let terminalRun = store.terminalRuns.last
            let terminalOutput = terminalRun?.output ?? ""

            let gitDataAvailable = store.workspaceGitDiff != nil || !fallbackGitStatus.isEmpty
            let pullRequestStatusAvailable = !pullRequestStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                pullRequestStatus != "未刷新" &&
                pullRequestStatus != "正在读取 PR 状态…"
            let terminalPreflightOk = terminalRun?.exitCode == 0 &&
                terminalOutput.contains("== Git 状态 ==") &&
                terminalOutput.contains("== 安全建议 ==")
            let ok = store.runtimeSnapshot.executable != nil &&
                !branchStatus.hasPrefix("分支读取失败") &&
                !gitStatus.hasPrefix("Git 差异读取失败") &&
                !worktreeStatus.hasPrefix("工作树读取失败") &&
                gitDataAvailable &&
                pullRequestStatusAvailable &&
                terminalPreflightOk

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "branch": store.selectedProject.branch ?? "",
                "branchStatus": branchStatus,
                "branchCount": store.workspaceBranches.count,
                "gitStatus": gitStatus,
                "gitErrors": gitErrors,
                "git": [
                    "sha": store.workspaceGitDiff?.sha ?? "",
                    "diffBytes": store.workspaceGitDiff?.diff.utf8.count ?? 0,
                    "files": diffSummary.files,
                    "additions": diffSummary.additions,
                    "deletions": diffSummary.deletions,
                    "fallbackStatus": fallbackGitStatus
                ] as [String: Any],
                "pullRequestStatus": pullRequestStatus,
                "worktreeStatus": worktreeStatus,
                "worktreeErrors": worktreeErrors,
                "worktrees": store.workspaceWorktrees,
                "terminalPreflight": [
                    "exitCode": Int(terminalRun?.exitCode ?? -999),
                    "command": terminalRun?.command ?? "",
                    "outputPreview": String(terminalOutput.prefix(1200))
                ] as [String: Any]
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
                (gitStatus.hasPrefix("Git 差异读取失败") && store.workspaceGitStatusText.isEmpty) ||
                store.runtimeProfileDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                store.runtimeProfileHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                store.runtimeProfileInitials.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !store.runtimeDependencyReady ||
                store.runtimeVersionDisplay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                store.runtimePath == "Not found"

            emitJSON([
                "ok": !hardFailure,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "runtimeDependencies": [
                    "ready": store.runtimeDependencyReady,
                    "version": store.runtimeVersionDisplay,
                    "source": store.runtimeSourceDisplay,
                    "bundling": store.runtimeBundlingDisplay,
                    "path": store.runtimePath,
                    "sidecar": store.sidecarStatusText
                ] as [String: Any],
                "workspacePath": workspacePath,
                "accountStatus": accountStatus,
                "accountErrors": accountErrors,
                "account": [
                    "kind": store.runtimeAccount?.kind ?? "",
                    "email": store.runtimeAccount?.email ?? "",
                    "planType": store.runtimeAccount?.planType ?? "",
                    "requiresOpenAIAuth": store.runtimeAccount?.requiresOpenAIAuth ?? false
                ] as [String: Any],
                "profile": [
                    "displayName": store.runtimeProfileDisplayName,
                    "handle": store.runtimeProfileHandle,
                    "initials": store.runtimeProfileInitials,
                    "source": "account/read"
                ],
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
            var mockServer: MockResponsesServer?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try "# Automation hook smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )

                mockServer = try startMockResponsesServer(message: "Raytone automation hook smoke OK")
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
                }

                await store.refreshRuntime()
                await store.installAutomationHookTemplate(
                    title: "项目监控",
                    prompt: "Raytone automation hook smoke prompt"
                )

                store.prompt = "触发 Raytone 自动化 hook，并回复 Raytone automation hook smoke OK"
                await store.runPrompt()
                await waitForStoreToSettle(store)
                await store.stopAppServerForTesting()

                let configURL = codexHomeURL.appendingPathComponent("config.toml")
                let eventURL = codexHomeURL.appendingPathComponent("raytone-automation-events.jsonl")
                let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let eventText = (try? String(contentsOf: eventURL, encoding: .utf8)) ?? ""
                let requestLog = (try? String(contentsOf: mockServer!.requestLogURL, encoding: .utf8)) ?? ""
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
                let agentMessages = store.selectedThread.items.compactMap { item -> String? in
                    if case let .agentMessage(text) = item.kind { return text }
                    return nil
                }
                let raytoneHook = raytoneHooks.first
                let hookTrustStatus = raytoneHook?.trustStatus ?? ""
                let hookTrusted = hookTrustStatus.localizedCaseInsensitiveCompare("trusted") == .orderedSame ||
                    hookTrustStatus.localizedCaseInsensitiveCompare("managed") == .orderedSame
                let ok = store.runtimeSnapshot.executable != nil &&
                    !store.isRunning &&
                    configText.contains("[features]") &&
                    configText.contains("hooks = true") &&
                    configText.contains("UserPromptSubmit") &&
                    configText.contains("raytone-automation-events.jsonl") &&
                    raytoneHooks.count == 1 &&
                    hookTrusted &&
                    eventText.contains("\"source\":\"RaytoneCodex\"") &&
                    eventText.contains("\"template\":\"项目监控\"") &&
                    eventText.contains("\"event\":\"UserPromptSubmit\"") &&
                    requestLog.contains("/v1/responses") &&
                    agentMessages.contains("Raytone automation hook smoke OK")

                mockServer?.stop()
                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "mockResponsesBaseURL": mockServer?.baseURL ?? "",
                    "configPath": configURL.path,
                    "configText": configText,
                    "eventPath": eventURL.path,
                    "eventText": eventText,
                    "hookCount": hooks.count,
                    "raytoneHookCount": raytoneHooks.count,
                    "raytoneHookTrusted": hookTrusted,
                    "hooks": hooks.map { hook in
                        [
                            "key": hook.key,
                            "eventName": hook.eventName,
                            "handlerType": hook.handlerType,
                            "command": hook.command ?? "",
                            "source": hook.source,
                            "sourcePath": hook.sourcePath,
                            "enabled": hook.enabled,
                            "trustStatus": hook.trustStatus,
                            "currentHash": hook.currentHash
                        ] as [String: Any]
                    },
                    "agentMessages": agentMessages,
                    "mockRequestLogPreview": String(requestLog.prefix(1200)),
                    "status": store.runtimeCatalogStatusText,
                    "errors": store.runtimeCatalogErrors
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
                    "codexHome": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runAccountAuthSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("account-auth-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("account-auth-smoke: refreshAccountUsageRuntime\n", stderr)
            await store.refreshAccountUsageRuntime()
            let beforeAccountKind = store.runtimeAccount?.kind ?? "notLoggedIn"

            fputs("account-auth-smoke: startAccountChatGPTLogin\n", stderr)
            await store.startAccountChatGPTLogin(openBrowser: false)
            let login = store.activeAccountLogin
            let startStatus = store.runtimeCatalogStatusText
            let startErrors = store.runtimeCatalogErrors

            fputs("account-auth-smoke: cancelAccountLogin\n", stderr)
            await store.cancelAccountLogin()
            let cancelStatus = store.runtimeCatalogStatusText
            let cancelErrors = store.runtimeCatalogErrors

            let authURL = login?.authURL?.absoluteString ?? ""
            let ok = store.runtimeSnapshot.executable != nil &&
                login?.kind == "chatgpt" &&
                login?.loginID?.isEmpty == false &&
                !authURL.isEmpty &&
                startErrors.isEmpty &&
                !cancelStatus.hasPrefix("取消登录失败") &&
                !cancelErrors.contains { $0.localizedCaseInsensitiveContains("account/login/cancel") }

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "beforeAccountKind": beforeAccountKind,
                "loginKind": login?.kind ?? "",
                "loginID": login?.loginID ?? "",
                "authURLHost": login?.authURL?.host ?? "",
                "startStatus": startStatus,
                "startErrors": startErrors,
                "cancelStatus": cancelStatus,
                "cancelErrors": cancelErrors,
                "activeLoginAfterCancel": store.activeAccountLogin?.loginID ?? ""
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runAccountAPIKeySmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexAPIKeySmoke-\(UUID().uuidString)", isDirectory: true)
            let apiKey = "sk-raytone-test-\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)

                let store = SessionStore()
                store.workspacePath = workspacePath
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHome.path
                ]

                fputs("account-api-key-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()

                fputs("account-api-key-smoke: loginRuntimeAccountWithAPIKey\n", stderr)
                let loginOK = await store.loginRuntimeAccountWithAPIKey(apiKey)
                let loginStatus = store.runtimeCatalogStatusText
                let loginErrors = store.runtimeCatalogErrors
                let accountKind = store.runtimeAccount?.kind ?? ""

                let authURL = codexHome.appendingPathComponent("auth.json")
                let authExistsAfterLogin = FileManager.default.fileExists(atPath: authURL.path)
                let authObject = authExistsAfterLogin
                    ? ((try? JSONSerialization.jsonObject(with: Data(contentsOf: authURL))) as? [String: Any] ?? [:])
                    : [:]
                let authKeys = Array(authObject.keys).sorted()
                let authHasAPIKey = authObject.keys.contains { key in
                    key.localizedCaseInsensitiveContains("api") || key.localizedCaseInsensitiveContains("openai")
                }

                fputs("account-api-key-smoke: logoutRuntimeAccount\n", stderr)
                await store.logoutRuntimeAccount()
                let logoutStatus = store.runtimeCatalogStatusText
                let logoutErrors = store.runtimeCatalogErrors
                let authExistsAfterLogout = FileManager.default.fileExists(atPath: authURL.path)

                let ok = store.runtimeSnapshot.executable != nil &&
                    loginOK &&
                    accountKind == "apiKey" &&
                    authExistsAfterLogin &&
                    authHasAPIKey &&
                    !loginStatus.hasPrefix("API Key 登录失败") &&
                    !logoutStatus.hasPrefix("退出登录失败")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "accountKindAfterLogin": accountKind,
                    "loginStatus": loginStatus,
                    "loginErrors": loginErrors,
                    "authFileExistedAfterLogin": authExistsAfterLogin,
                    "authFileKeys": authKeys,
                    "authFileHadAPIKeyField": authHasAPIKey,
                    "logoutStatus": logoutStatus,
                    "logoutErrors": logoutErrors,
                    "authFileExistedAfterLogout": authExistsAfterLogout
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "unknown",
                    "runtimePath": "",
                    "runtimeVersion": "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
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

            fputs("integration-pages-smoke: loadFilePanelDirectory\n", stderr)
            await store.loadFilePanelDirectory(workspacePath)
            let fileConnectionCount = store.workspaceFileConnectionCount

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
                !worktreeStatus.hasPrefix("工作树读取失败") &&
                fileConnectionCount > 0

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
                "homeConnectionCards": [
                    "source": "app/list + mcpServerStatus/list + files/readDirectory",
                    "messaging": [
                        "connected": store.messagingConnectionCount > 0,
                        "count": store.messagingConnectionCount,
                        "names": store.messagingConnectionNames,
                        "subtitle": store.messagingConnectionSubtitle
                    ] as [String: Any],
                    "email": [
                        "connected": store.emailConnectionCount > 0,
                        "count": store.emailConnectionCount,
                        "names": store.emailConnectionNames,
                        "subtitle": store.emailConnectionSubtitle
                    ] as [String: Any],
                    "files": [
                        "connected": store.workspaceFileConnectionCount > 0,
                        "count": store.workspaceFileConnectionCount,
                        "subtitle": store.workspaceFileConnectionSubtitle,
                        "path": store.filePanelPath
                    ] as [String: Any]
                ] as [String: Any],
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

    private static func writePluginReadSmokeFixture(workspaceURL: URL, codexHomeURL: URL) throws {
        let fileManager = FileManager.default
        let pluginRoot = workspaceURL.appendingPathComponent("plugins/demo-plugin", isDirectory: true)
        try fileManager.createDirectory(at: workspaceURL.appendingPathComponent(".git", isDirectory: true), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: workspaceURL.appendingPathComponent(".agents/plugins", isDirectory: true), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: pluginRoot.appendingPathComponent(".codex-plugin", isDirectory: true), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: pluginRoot.appendingPathComponent("skills/thread-summarizer/agents", isDirectory: true), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: pluginRoot.appendingPathComponent("hooks", isDirectory: true), withIntermediateDirectories: true)

        try """
        {
          "name": "codex-curated",
          "plugins": [
            {
              "name": "demo-plugin",
              "source": {
                "source": "local",
                "path": "./plugins/demo-plugin"
              },
              "policy": {
                "installation": "AVAILABLE",
                "authentication": "ON_INSTALL"
              },
              "category": "Productivity"
            }
          ]
        }
        """.write(to: workspaceURL.appendingPathComponent(".agents/plugins/marketplace.json"), atomically: true, encoding: .utf8)

        try """
        {
          "name": "demo-plugin",
          "description": "Raytone plugin/read smoke long description",
          "keywords": ["raytone", "plugin-read"],
          "interface": {
            "displayName": "Raytone Plugin Read Smoke",
            "shortDescription": "plugin/read smoke subtitle",
            "longDescription": "plugin/read smoke long details",
            "developerName": "Raytone",
            "category": "Productivity",
            "capabilities": ["Interactive"]
          }
        }
        """.write(to: pluginRoot.appendingPathComponent(".codex-plugin/plugin.json"), atomically: true, encoding: .utf8)

        try """
        ---
        name: thread-summarizer
        description: Summarize Raytone plugin smoke threads
        ---

        # Thread Summarizer
        """.write(to: pluginRoot.appendingPathComponent("skills/thread-summarizer/SKILL.md"), atomically: true, encoding: .utf8)

        try """
        policy:
          products:
            - CODEX
        """.write(to: pluginRoot.appendingPathComponent("skills/thread-summarizer/agents/openai.yaml"), atomically: true, encoding: .utf8)

        try """
        {
          "mcpServers": {
            "demo": {
              "command": "demo-server"
            }
          }
        }
        """.write(to: pluginRoot.appendingPathComponent(".mcp.json"), atomically: true, encoding: .utf8)

        try """
        {
          "hooks": {
            "PreToolUse": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "echo plugin-read-smoke"
                  }
                ]
              }
            ]
          }
        }
        """.write(to: pluginRoot.appendingPathComponent("hooks/hooks.json"), atomically: true, encoding: .utf8)

        try """
        [features]
        plugins = true

        [[skills.config]]
        name = "demo-plugin:thread-summarizer"
        enabled = false

        [plugins."demo-plugin@codex-curated"]
        enabled = true
        """.write(to: codexHomeURL.appendingPathComponent("config.toml"), atomically: true, encoding: .utf8)

        let installedPluginRoot = codexHomeURL
            .appendingPathComponent("plugins/cache/codex-curated/demo-plugin/local/.codex-plugin", isDirectory: true)
        try fileManager.createDirectory(at: installedPluginRoot, withIntermediateDirectories: true)
        try #"{"name":"demo-plugin"}"#.write(
            to: installedPluginRoot.appendingPathComponent("plugin.json"),
            atomically: true,
            encoding: .utf8
        )
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

    private static func mcpResourceSmokeServerScript(marker: String, resourceURI: String) -> String {
        let markerLiteral = String(reflecting: marker)
        let resourceURILiteral = String(reflecting: resourceURI)
        return """
        import json
        import sys

        MARKER = \(markerLiteral)
        RESOURCE_URI = \(resourceURILiteral)

        def read_message():
            line = sys.stdin.buffer.readline()
            if not line:
                return None
            return json.loads(line.decode("utf-8"))

        def send_message(message):
            body = json.dumps(message, separators=(",", ":")).encode("utf-8")
            sys.stdout.buffer.write(body + b"\\n")
            sys.stdout.buffer.flush()

        def result_for(method, params):
            if method == "initialize":
                return {
                    "protocolVersion": params.get("protocolVersion", "2024-11-05"),
                    "capabilities": {
                        "resources": {"subscribe": False, "listChanged": False},
                        "tools": {}
                    },
                    "serverInfo": {
                        "name": "raytone-resource-smoke",
                        "title": "Raytone MCP Resource Smoke",
                        "version": "1.0.0"
                    }
                }
            if method == "resources/list":
                return {
                    "resources": [{
                        "uri": RESOURCE_URI,
                        "name": "raytone-smoke-resource",
                        "title": "Raytone MCP Smoke Resource",
                        "description": "A local smoke resource served over MCP stdio.",
                        "mimeType": "text/plain",
                        "size": len(MARKER)
                    }]
                }
            if method == "resources/templates/list":
                return {"resourceTemplates": []}
            if method == "resources/read":
                return {
                    "contents": [{
                        "uri": params.get("uri", RESOURCE_URI),
                        "mimeType": "text/plain",
                        "text": MARKER
                    }]
                }
            if method == "tools/list":
                return {"tools": []}
            if method == "ping":
                return {}
            raise KeyError(method)

        while True:
            message = read_message()
            if message is None:
                break
            request_id = message.get("id")
            if request_id is None:
                continue
            method = message.get("method")
            params = message.get("params") or {}
            try:
                send_message({"jsonrpc": "2.0", "id": request_id, "result": result_for(method, params)})
            except Exception as error:
                send_message({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {"code": -32601, "message": str(error)}
                })
        """
    }

    private static func mcpToolSmokeServerScript(marker: String, toolName: String) -> String {
        let markerLiteral = String(reflecting: marker)
        let toolNameLiteral = String(reflecting: toolName)
        return """
        import json
        import sys

        MARKER = \(markerLiteral)
        TOOL_NAME = \(toolNameLiteral)

        def read_message():
            line = sys.stdin.buffer.readline()
            if not line:
                return None
            return json.loads(line.decode("utf-8"))

        def send_message(message):
            body = json.dumps(message, separators=(",", ":")).encode("utf-8")
            sys.stdout.buffer.write(body + b"\\n")
            sys.stdout.buffer.flush()

        def result_for(method, params):
            if method == "initialize":
                return {
                    "protocolVersion": params.get("protocolVersion", "2024-11-05"),
                    "capabilities": {
                        "tools": {"listChanged": False},
                        "resources": {"subscribe": False, "listChanged": False}
                    },
                    "serverInfo": {
                        "name": "raytone-tool-smoke",
                        "title": "Raytone MCP Tool Smoke",
                        "version": "1.0.0"
                    }
                }
            if method == "tools/list":
                return {
                    "tools": [{
                        "name": TOOL_NAME,
                        "title": "Raytone Echo Tool",
                        "description": "Echo a message and prove mcpServer/tool/call reached the real MCP server.",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "message": {"type": "string"}
                            },
                            "required": ["message"],
                            "additionalProperties": False
                        },
                        "annotations": {"readOnlyHint": True}
                    }]
                }
            if method == "resources/list":
                return {"resources": []}
            if method == "resources/templates/list":
                return {"resourceTemplates": []}
            if method == "tools/call":
                arguments = params.get("arguments") or {}
                meta = params.get("_meta") or {}
                message = arguments.get("message", "")
                thread_id = meta.get("threadId", "")
                return {
                    "content": [{
                        "type": "text",
                        "text": "echo: " + message + " · " + MARKER
                    }],
                    "structuredContent": {
                        "echoed": message,
                        "marker": MARKER,
                        "threadId": thread_id
                    },
                    "isError": False,
                    "_meta": {
                        "calledBy": "raytone-tool-smoke"
                    }
                }
            if method == "ping":
                return {}
            raise KeyError(method)

        while True:
            message = read_message()
            if message is None:
                break
            request_id = message.get("id")
            if request_id is None:
                continue
            method = message.get("method")
            params = message.get("params") or {}
            try:
                send_message({"jsonrpc": "2.0", "id": request_id, "result": result_for(method, params)})
            except Exception as error:
                send_message({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {"code": -32601, "message": str(error)}
                })
        """
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

    private static func goalPayload(_ goal: CodexRuntimeGoal) -> [String: Any] {
        [
            "threadID": goal.threadID,
            "objective": goal.objective,
            "status": goal.status.rawValue,
            "tokenBudget": goal.tokenBudget.map { $0 as Any } ?? NSNull(),
            "tokensUsed": goal.tokensUsed,
            "timeUsedSeconds": goal.timeUsedSeconds,
            "createdAt": goal.createdAt,
            "updatedAt": goal.updatedAt
        ]
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
