import AppKit
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
        } else if CommandLine.arguments.contains("--terminal-resize-smoke-test") {
            runTerminalResizeSmoke()
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
        } else if CommandLine.arguments.contains("--mcp-elicitation-smoke-test") {
            runMCPElicitationSmoke()
        } else if CommandLine.arguments.contains("--tool-user-input-smoke-test") {
            runToolUserInputSmoke()
        } else if CommandLine.arguments.contains("--approval-compat-smoke-test") {
            runApprovalCompatSmoke()
        } else if CommandLine.arguments.contains("--dynamic-tool-smoke-test") {
            runDynamicToolSmoke()
        } else if CommandLine.arguments.contains("--interrupt-smoke-test") {
            runInterruptSmoke()
        } else if CommandLine.arguments.contains("--auth-attestation-smoke-test") {
            runAuthAttestationSmoke()
        } else if CommandLine.arguments.contains("--plugin-read-smoke-test") {
            runPluginReadSmoke()
        } else if CommandLine.arguments.contains("--skill-read-smoke-test") {
            runSkillReadSmoke()
        } else if CommandLine.arguments.contains("--skill-extra-roots-smoke-test") {
            runSkillExtraRootsSmoke()
        } else if CommandLine.arguments.contains("--plugin-scaffold-smoke-test") {
            runPluginScaffoldSmoke()
        } else if CommandLine.arguments.contains("--plugin-install-response-smoke-test") {
            runPluginInstallResponseSmoke()
        } else if CommandLine.arguments.contains("--plugin-share-smoke-test") {
            runPluginShareSmoke()
        } else if CommandLine.arguments.contains("--marketplace-upgrade-smoke-test") {
            runMarketplaceUpgradeSmoke()
        } else if CommandLine.arguments.contains("--codex-home-directory-smoke-test") {
            runCodexHomeDirectorySmoke()
        } else if CommandLine.arguments.contains("--account-auth-smoke-test") {
            runAccountAuthSmoke()
        } else if CommandLine.arguments.contains("--account-device-code-smoke-test") {
            runAccountDeviceCodeSmoke()
        } else if CommandLine.arguments.contains("--connection-recovery-smoke-test") {
            runConnectionRecoverySmoke()
        } else if CommandLine.arguments.contains("--account-api-key-smoke-test") {
            runAccountAPIKeySmoke()
        } else if CommandLine.arguments.contains("--profile-privacy-smoke-test") {
            runProfilePrivacySmoke()
        } else if CommandLine.arguments.contains("--profile-share-smoke-test") {
            runProfileShareSmoke()
        } else if CommandLine.arguments.contains("--add-credits-nudge-smoke-test") {
            runAddCreditsNudgeSmoke()
        } else if CommandLine.arguments.contains("--feedback-upload-smoke-test") {
            runFeedbackUploadSmoke()
        } else if CommandLine.arguments.contains("--windows-sandbox-smoke-test") {
            runWindowsSandboxSmoke()
        } else if CommandLine.arguments.contains("--experimental-features-smoke-test") {
            runExperimentalFeaturesSmoke()
        } else if CommandLine.arguments.contains("--mention-smoke-test") {
            runMentionSmoke()
        } else if CommandLine.arguments.contains("--runtime-pages-smoke-test") {
            runRuntimePagesSmoke()
        } else if CommandLine.arguments.contains("--settings-scene-smoke-test") {
            runSettingsSceneSmoke()
        } else if CommandLine.arguments.contains("--sample-data-gate-smoke-test") {
            runSampleDataGateSmoke()
        } else if CommandLine.arguments.contains("--usage-activity-smoke-test") {
            runUsageActivitySmoke()
        } else if CommandLine.arguments.contains("--settings-project-smoke-test") {
            runSettingsProjectSmoke()
        } else if CommandLine.arguments.contains("--automation-smoke-test") {
            runAutomationSmoke()
        } else if CommandLine.arguments.contains("--automation-hook-smoke-test") {
            runAutomationHookSmoke()
        } else if CommandLine.arguments.contains("--hook-notification-smoke-test") {
            runHookNotificationSmoke()
        } else if CommandLine.arguments.contains("--file-change-stream-smoke-test") {
            runFileChangeStreamSmoke()
        } else if CommandLine.arguments.contains("--runtime-diagnostics-smoke-test") {
            runRuntimeDiagnosticsSmoke()
        } else if CommandLine.arguments.contains("--process-stream-smoke-test") {
            runProcessStreamSmoke()
        } else if CommandLine.arguments.contains("--app-server-notification-smoke-test") {
            runAppServerNotificationSmoke()
        } else if CommandLine.arguments.contains("--guardian-denial-approve-smoke-test") {
            runGuardianDeniedApproveSmoke()
        } else if CommandLine.arguments.contains("--hook-controls-smoke-test") {
            runHookControlsSmoke()
        } else if CommandLine.arguments.contains("--integration-pages-smoke-test") {
            runIntegrationPagesSmoke()
        } else if CommandLine.arguments.contains("--home-connection-actions-smoke-test") {
            runHomeConnectionActionsSmoke()
        } else if CommandLine.arguments.contains("--app-mention-config-smoke-test") {
            runAppMentionConfigSmoke()
        } else if CommandLine.arguments.contains("--app-mention-turn-smoke-test") {
            runAppMentionTurnSmoke()
        } else if CommandLine.arguments.contains("--app-list-updated-smoke-test") {
            runAppListUpdatedSmoke()
        } else if CommandLine.arguments.contains("--project-switch-smoke-test") {
            runProjectSwitchSmoke()
        } else if CommandLine.arguments.contains("--workspace-switch-smoke-test") {
            runWorkspaceSwitchSmoke()
        } else if CommandLine.arguments.contains("--branch-switch-smoke-test") {
            runBranchSwitchSmoke()
        } else if CommandLine.arguments.contains("--worktree-switch-smoke-test") {
            runWorktreeSwitchSmoke()
        } else if CommandLine.arguments.contains("--remote-control-smoke-test") {
            runRemoteControlSmoke()
        } else if CommandLine.arguments.contains("--remote-control-mode-smoke-test") {
            runRemoteControlModeSmoke()
        } else if CommandLine.arguments.contains("--remote-control-revoke-smoke-test") {
            runRemoteControlRevokeSmoke()
        } else if CommandLine.arguments.contains("--realtime-voices-smoke-test") {
            runRealtimeVoicesSmoke()
        } else if CommandLine.arguments.contains("--realtime-session-smoke-test") {
            runRealtimeSessionSmoke()
        } else if CommandLine.arguments.contains("--access-mode-smoke-test") {
            runAccessModeSmoke()
        } else if CommandLine.arguments.contains("--new-thread-permissions-smoke-test") {
            runNewThreadPermissionsSmoke()
        } else if CommandLine.arguments.contains("--personality-smoke-test") {
            runPersonalitySmoke()
        } else if CommandLine.arguments.contains("--model-catalog-smoke-test") {
            runModelCatalogSmoke()
        } else if CommandLine.arguments.contains("--model-provider-capabilities-smoke-test") {
            runModelProviderCapabilitiesSmoke()
        } else if CommandLine.arguments.contains("--external-agent-config-smoke-test") {
            runExternalAgentConfigSmoke()
        } else if CommandLine.arguments.contains("--external-agent-real-smoke-test") {
            runExternalAgentRealSmoke()
        } else if CommandLine.arguments.contains("--model-config-smoke-test") {
            runModelConfigSmoke()
        } else if CommandLine.arguments.contains("--provider-sidecar-smoke-test") {
            runProviderSidecarSmoke()
        } else if CommandLine.arguments.contains("--provider-onboarding-smoke-test") {
            runProviderOnboardingSmoke()
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
        } else if CommandLine.arguments.contains("--thread-memory-mode-smoke-test") {
            runThreadMemoryModeSmoke()
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
        } else if CommandLine.arguments.contains("--browser-clear-data-smoke-test") {
            runBrowserClearDataSmoke()
        } else if CommandLine.arguments.contains("--browser-snapshot-smoke-test") {
            runBrowserSnapshotSmoke()
        } else if CommandLine.arguments.contains("--browser-snapshot-input-smoke-test") {
            runBrowserSnapshotInputSmoke()
        } else if CommandLine.arguments.contains("--config-write-smoke-test") {
            runConfigWriteSmoke()
        } else if CommandLine.arguments.contains("--thread-management-smoke-test") {
            runThreadManagementSmoke()
        } else if CommandLine.arguments.contains("--thread-bootstrap-actions-smoke-test") {
            runThreadBootstrapActionsSmoke()
        } else if CommandLine.arguments.contains("--thread-lifecycle-smoke-test") {
            runThreadLifecycleSmoke()
        } else if CommandLine.arguments.contains("--history-smoke-test") {
            runHistorySmoke()
        } else if CommandLine.arguments.contains("--loaded-threads-smoke-test") {
            runLoadedThreadsSmoke()
        } else if CommandLine.arguments.contains("--thread-unsubscribe-smoke-test") {
            runThreadUnsubscribeSmoke()
        } else if CommandLine.arguments.contains("--thread-metadata-smoke-test") {
            runThreadMetadataSmoke()
        } else if CommandLine.arguments.contains("--thread-shell-command-smoke-test") {
            runThreadShellCommandSmoke()
        } else if CommandLine.arguments.contains("--side-chat-smoke-test") {
            runSideChatSmoke()
        } else if CommandLine.arguments.contains("--side-chat-injection-smoke-test") {
            runSideChatInjectionSmoke()
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
                    stdinRun?.processID?.hasPrefix("raytone-terminal-") == true &&
                    stdinRun?.output.contains("got:raytone-stdin-smoke") == true &&
                    stdinRun?.status == .succeeded &&
                    streamedBeforeTerminate &&
                    terminatedRun?.processID?.hasPrefix("raytone-terminal-") == true &&
                    terminatedRun?.output.contains("sleeping") == true &&
                    terminatedRun?.output.contains("done") != true &&
                    store.runtimeCatalogStatusText.contains("process/exited") &&
                    store.terminalIsRunning == false

                let stdinOutput = stdinRun?.output ?? ""
                let terminatedOutput = terminatedRun?.output ?? ""
                let runtimeCatalogStatus = store.runtimeCatalogStatusText
                await store.stopAppServerForTesting()

                emitJSON([
                    "ok": ok,
                    "source": "process/spawn + process/writeStdin + process/kill",
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "runtimeCatalogStatus": runtimeCatalogStatus,
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "streamedBeforeInput": streamedBeforeInput,
                    "stdinProcessHandle": stdinRun?.processID ?? "",
                    "stdinExitCode": Int(stdinRun?.exitCode ?? -999),
                    "stdinStatus": terminalStatusName(stdinRun?.status),
                    "stdinOutput": stdinOutput,
                    "streamedBeforeTerminate": streamedBeforeTerminate,
                    "terminatedProcessHandle": terminatedRun?.processID ?? "",
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

    private static func runTerminalResizeSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexTerminalResizeSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexTerminalResizeCodexHome-\(UUID().uuidString)", isDirectory: true)

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.sandbox = .dangerFullAccess
                store.terminalRows = 24
                store.terminalCols = 80
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                await store.refreshRuntime()

                store.terminalCommand = "printf 'ready\\n'; read line; printf 'line:%s\\n' \"$line\"; stty size"
                let terminalTask = Task { @MainActor in
                    await store.runTerminalCommand()
                }

                let readyDeadline = Date().addingTimeInterval(8)
                while Date() < readyDeadline,
                      store.terminalRuns.last?.output.contains("ready") != true {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let streamedBeforeResize = store.terminalIsRunning &&
                    store.terminalRuns.last?.output.contains("ready") == true

                await store.resizeTerminal(rows: 42, cols: 132)
                let resizeStatus = store.terminalResizeStatusText

                store.terminalCommand = "raytone-resize-smoke"
                await store.runTerminalCommand()
                _ = await terminalTask.value

                let run = store.terminalRuns.last
                let output = run?.output ?? ""
                let ok = store.runtimeSnapshot.executable != nil &&
                    streamedBeforeResize &&
                    resizeStatus.contains("process/resizePty") &&
                    output.contains("line:raytone-resize-smoke") &&
                    output.contains("42 132") &&
                    run?.status == .succeeded &&
                    run?.processID?.hasPrefix("raytone-terminal-") == true &&
                    store.terminalRows == 42 &&
                    store.terminalCols == 132

                let runtimeCatalogStatus = store.runtimeCatalogStatusText
                await store.stopAppServerForTesting()

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "streamedBeforeResize": streamedBeforeResize,
                    "resizeStatus": resizeStatus,
                    "terminalRows": store.terminalRows,
                    "terminalCols": store.terminalCols,
                    "processHandle": run?.processID ?? "",
                    "runtimeCatalogStatus": runtimeCatalogStatus,
                    "runStatus": terminalStatusName(run?.status),
                    "output": output,
                    "source": "process/spawn + process/resizePty + process/writeStdin"
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
        let originalPreview = store.filePreview

        await store.duplicatePreviewedFileSystemItem()
        let duplicateURL = sourceDirectory.appendingPathComponent("NeedleRuntimeFile 副本.swift")
        let statusAfterDuplicate = store.filePanelStatusText
        let duplicateWasCreated = store.filePreview?.fileName == duplicateURL.lastPathComponent &&
            fileManager.fileExists(atPath: duplicateURL.path)
        await store.removePreviewedFileSystemItem(confirm: false)
        let statusAfterRemove = store.filePanelStatusText
        let duplicateWasRemoved = !fileManager.fileExists(atPath: duplicateURL.path)

        await store.createFileInCurrentPanelDirectory(named: "CreatedByAppServer.txt")
        let statusAfterCreateFile = store.filePanelStatusText
        let createdFileURL = sourceDirectory.appendingPathComponent("CreatedByAppServer.txt")
        let createdFileExists = fileManager.fileExists(atPath: createdFileURL.path)

        await store.createDirectoryInCurrentPanelDirectory(named: "CreatedFolder")
        let statusAfterCreateFolder = store.filePanelStatusText
        let createdFolderURL = sourceDirectory.appendingPathComponent("CreatedFolder", isDirectory: true)
        var createdFolderIsDirectory: ObjCBool = false
        let createdFolderExists = fileManager.fileExists(
            atPath: createdFolderURL.path,
            isDirectory: &createdFolderIsDirectory
        )

        await store.loadFilePanelDirectory(sourceDirectory.path)
        if let createdEntry = store.fileEntries.first(where: { $0.name == createdFileURL.lastPathComponent }) {
            await store.openFileEntry(createdEntry)
        }
        let mutationPreview = store.filePreview

        let ok = store.runtimeSnapshot.executable != nil &&
            targetResult != nil &&
            store.fileSearchStatusText.contains("fuzzyFileSearch/sessionCompleted") &&
            originalPreview?.path == targetURL.path &&
            originalPreview?.text.contains("fuzzy-file-search-runtime-proof") == true &&
            originalPreview?.byteCount == targetText.utf8.count &&
            originalPreview?.modifiedAt != nil &&
            duplicateWasCreated &&
            duplicateWasRemoved &&
            createdFileExists &&
            createdFolderExists &&
            createdFolderIsDirectory.boolValue &&
            mutationPreview?.path == createdFileURL.path &&
            mutationPreview?.byteCount == 0 &&
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
            "path": mutationPreview?.path ?? "",
            "fileName": mutationPreview?.fileName ?? "",
            "textPreview": String((mutationPreview?.text ?? "").prefix(200)),
            "byteCount": mutationPreview?.byteCount ?? 0,
            "metadataSummary": mutationPreview?.metadataSummary ?? "",
            "isTruncated": mutationPreview?.isTruncated ?? false
        ]
        let originalPreviewPayload: [String: Any] = [
            "path": targetURL.path,
            "fileName": targetURL.lastPathComponent,
            "matched": targetResult != nil,
            "textWasRead": originalPreview?.text.contains("fuzzy-file-search-runtime-proof") == true,
            "byteCountWasRead": originalPreview?.byteCount == targetText.utf8.count,
            "metadataWasRead": originalPreview?.modifiedAt != nil
        ]
        let mutationsPayload: [String: Any] = [
            "createdFile": createdFileURL.path,
            "createdFileExists": createdFileExists,
            "createdFolder": createdFolderURL.path,
            "createdFolderExists": createdFolderExists,
            "createdFolderIsDirectory": createdFolderIsDirectory.boolValue,
            "duplicatePath": duplicateURL.path,
            "duplicateWasCreated": duplicateWasCreated,
            "duplicateWasRemoved": duplicateWasRemoved,
            "statusAfterDuplicate": statusAfterDuplicate,
            "statusAfterRemove": statusAfterRemove,
            "statusAfterCreateFile": statusAfterCreateFile,
            "statusAfterCreateFolder": statusAfterCreateFolder,
            "status": store.filePanelStatusText
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
            "originalPreview": originalPreviewPayload,
            "fileMutations": mutationsPayload,
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
            let shareContextFixture = try? JSONValue(jsonString: """
            {
              "remotePluginId": "plugins_raytone_shared",
              "remoteVersion": "1.2.3",
              "discoverability": "UNLISTED",
              "creatorAccountUserId": "user_raytone",
              "creatorName": "Raytone",
              "shareUrl": "https://chatgpt.example/plugins/share/raytone",
              "sharePrincipals": [
                {
                  "principalId": "workspace_raytone",
                  "principalType": "workspace",
                  "role": "reader",
                  "name": "Raytone Workspace"
                }
              ]
            }
            """)
            let parsedShareContext = CodexAppServerClient.pluginShareContext(from: shareContextFixture)
            let shareContextParserOK = parsedShareContext?.remotePluginID == "plugins_raytone_shared" &&
                parsedShareContext?.remoteVersion == "1.2.3" &&
                parsedShareContext?.discoverability == "UNLISTED" &&
                parsedShareContext?.creatorName == "Raytone" &&
                parsedShareContext?.sharePrincipals.first?.principalType == "workspace" &&
                parsedShareContext?.sharePrincipals.first?.role == "reader"
            let checkoutFixture = try? JSONValue(jsonString: """
            {
              "remotePluginId": "plugins_raytone_shared",
              "pluginId": "raytone-demo@codex-curated",
              "pluginName": "raytone-demo",
              "pluginPath": "/Users/example/plugins/raytone-demo",
              "marketplaceName": "codex-curated",
              "marketplacePath": "/Users/example/.agents/plugins/marketplace.json",
              "remoteVersion": "1.2.3"
            }
            """)
            let parsedCheckout = checkoutFixture.flatMap { try? CodexAppServerClient.pluginShareCheckoutResult(from: $0) }
            let checkoutParserOK = parsedCheckout?.remotePluginID == "plugins_raytone_shared" &&
                parsedCheckout?.pluginID == "raytone-demo@codex-curated" &&
                parsedCheckout?.pluginName == "raytone-demo" &&
                parsedCheckout?.pluginPath.hasSuffix("/plugins/raytone-demo") == true &&
                parsedCheckout?.marketplaceName == "codex-curated" &&
                parsedCheckout?.marketplacePath.hasSuffix("/marketplace.json") == true &&
                parsedCheckout?.remoteVersion == "1.2.3"
            let ok = store.runtimeSnapshot.executable != nil &&
                hasConfig &&
                shareContextParserOK &&
                checkoutParserOK &&
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
                "sharedPluginCount": store.runtimeSharedPluginCount,
                "pluginsPreview": Array(store.runtimePlugins.prefix(8).map { plugin in
                    [
                        "id": plugin.id,
                        "name": plugin.name,
                        "displayName": plugin.displayName,
                        "installed": plugin.installed,
                        "enabled": plugin.enabled,
                        "marketplace": plugin.marketplaceDisplayName,
                        "shareContext": pluginSharePayload(plugin.shareContext)
                    ] as [String: Any]
                }),
                "shareContextParser": [
                    "ok": shareContextParserOK,
                    "remotePluginId": parsedShareContext?.remotePluginID ?? "",
                    "remoteVersion": parsedShareContext?.remoteVersion ?? "",
                    "discoverability": parsedShareContext?.discoverability ?? "",
                    "creatorName": parsedShareContext?.creatorName ?? "",
                    "principalCount": parsedShareContext?.sharePrincipals.count ?? 0
                ] as [String: Any],
                "shareCheckoutParser": [
                    "ok": checkoutParserOK,
                    "remotePluginId": parsedCheckout?.remotePluginID ?? "",
                    "pluginId": parsedCheckout?.pluginID ?? "",
                    "pluginName": parsedCheckout?.pluginName ?? "",
                    "marketplaceName": parsedCheckout?.marketplaceName ?? "",
                    "remoteVersion": parsedCheckout?.remoteVersion ?? ""
                ] as [String: Any],
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
        let resourceTemplateURI = "\(resourceURI)/{name}"
        let concreteTemplateURI = "\(resourceURI)/from-template"

        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexMCPResourceSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let serverURL = rootURL.appendingPathComponent("raytone_mcp_resource_server.py")

            do {
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try mcpResourceSmokeServerScript(
                    marker: marker,
                    resourceURI: resourceURI,
                    resourceTemplateURI: resourceTemplateURI
                )
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
                let resourcePreview = store.mcpResourcePreview?.textPreview ?? ""

                guard let template = server.resourceTemplates.first(where: { $0.uriTemplate == resourceTemplateURI }) else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                        "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                        "runtimeVersion": store.runtimeSnapshot.version ?? "",
                        "workspacePath": workspacePath,
                        "codexHome": codexHomeURL.path,
                        "serverName": serverName,
                        "resourceURI": resourceURI,
                        "resourceTemplateURI": resourceTemplateURI,
                        "status": store.runtimeCatalogStatusText,
                        "serverResourceTemplateCount": server.resourceTemplateCount,
                        "templates": server.resourceTemplates.map(\.uriTemplate)
                    ])
                    exit(1)
                }

                let templateKey = store.mcpResourceTemplateKey(template, server: server)
                store.mcpResourceTemplateURIText[templateKey] = concreteTemplateURI
                fputs("mcp-resource-smoke: readMCPResourceTemplate\n", stderr)
                await store.readMCPResourceTemplate(template, from: server)
                let templatePreview = store.mcpResourcePreview?.textPreview ?? ""
                let ok = store.runtimeSnapshot.executable != nil &&
                    server.resourceCount == 1 &&
                    server.resourceTemplateCount == 1 &&
                    server.resourceTemplates.count == 1 &&
                    resource.displayName == "Raytone MCP Smoke Resource" &&
                    template.displayName == "Raytone MCP Smoke Template" &&
                    store.mcpResourcePreview?.server == serverName &&
                    resourcePreview.contains(marker) &&
                    store.mcpResourcePreview?.requestedURI == concreteTemplateURI &&
                    templatePreview.contains(marker) &&
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
                    "resourceTemplate": [
                        "name": template.name,
                        "displayName": template.displayName,
                        "uriTemplate": template.uriTemplate,
                        "concreteURI": concreteTemplateURI,
                        "mimeType": template.mimeType ?? ""
                    ] as [String: Any],
                    "readStatus": store.mcpResourceStatusText,
                    "contentCount": store.mcpResourcePreview?.contents.count ?? 0,
                    "resourcePreview": resourcePreview,
                    "templatePreview": templatePreview
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

    private static func runMCPElicitationSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexMCPElicitationSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeMCPElicitationAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-mcp-elicitation"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_MCP_ELICITATION_LOG": logURL.path
                ]
                store.prompt = "触发 MCP 表单输入"

                await store.runPrompt()
                let elicitationItemID = await waitForMCPElicitation(in: store)
                let defaultDraft = elicitationItemID.flatMap { store.mcpElicitationDrafts[$0] } ?? ""
                if let elicitationItemID {
                    store.updateMcpElicitationDraft(
                        itemID: elicitationItemID,
                        draft: #"{"token":"raytone-smoke-token","confirmed":true}"#
                    )
                    store.decideMcpElicitation(itemID: elicitationItemID, action: .accept)
                }

                let deadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""elicitationResponse""#) &&
                        logText.contains(#""action":"accept""#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let elicitationRequests = store.selectedThread.items.compactMap { item -> McpElicitationRequest? in
                    if case let .mcpElicitation(request) = item.kind {
                        return request
                    }
                    return nil
                }
                let accepted = elicitationRequests.contains { request in
                    request.status == .accepted &&
                        request.serverName == "raytone_mcp" &&
                        request.message.contains("访问令牌")
                }
                let ok = elicitationItemID != nil &&
                    accepted &&
                    defaultDraft.contains(#""token""#) &&
                    defaultDraft.contains(#""confirmed""#) &&
                    logText.contains(#""method":"turn/start""#) &&
                    logText.contains(#""method":"mcpServer/elicitation/request""#) &&
                    logText.contains(#""elicitationResponse""#) &&
                    logText.contains(#""action":"accept""#) &&
                    logText.contains(#""raytone-smoke-token""#)

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "transcriptItemCount": store.selectedThread.items.count,
                    "elicitationCount": elicitationRequests.count,
                    "defaultDraft": defaultDraft,
                    "accepted": accepted,
                    "isRunning": store.isRunning,
                    "requestLogPreview": String(logText.prefix(2200))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runToolUserInputSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexToolUserInputSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeToolUserInputAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-tool-user-input"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_TOOL_USER_INPUT_LOG": logURL.path
                ]
                store.prompt = "触发工具补充信息"

                await store.runPrompt()
                let requestItemID = await waitForToolUserInput(in: store)
                if let requestItemID {
                    store.selectToolUserInputOption(
                        itemID: requestItemID,
                        questionID: "q_mode",
                        label: "继续"
                    )
                    store.updateToolUserInputDraft(
                        itemID: requestItemID,
                        questionID: "q_secret",
                        draft: "smoke-secret"
                    )
                    store.submitToolUserInput(itemID: requestItemID)
                }

                let deadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""toolUserInputResponse""#) &&
                        logText.contains(#""smoke-secret""#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let requests = store.selectedThread.items.compactMap { item -> ToolUserInputRequest? in
                    if case let .toolUserInput(request) = item.kind {
                        return request
                    }
                    return nil
                }
                let submitted = requests.contains { request in
                    request.status == .submitted &&
                        request.questions.count == 2 &&
                        request.questions.contains { $0.id == "q_secret" && $0.isSecret }
                }
                let ok = requestItemID != nil &&
                    submitted &&
                    logText.contains(#""method":"turn/start""#) &&
                    logText.contains(#""method":"item/tool/requestUserInput""#) &&
                    logText.contains(#""toolUserInputResponse""#) &&
                    logText.contains(#""q_mode":{"answers":["继续"]}"#) &&
                    logText.contains(#""q_secret":{"answers":["smoke-secret"]}"#)

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "transcriptItemCount": store.selectedThread.items.count,
                    "toolUserInputCount": requests.count,
                    "submitted": submitted,
                    "isRunning": store.isRunning,
                    "requestLogPreview": String(logText.prefix(2200))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runApprovalCompatSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexApprovalCompatSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeApprovalCompatAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-approval-compat"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_APPROVAL_COMPAT_LOG": logURL.path
                ]
                store.prompt = "触发权限与旧审批兼容"

                await store.runPrompt()
                guard let permissionsID = await waitForPendingApproval(in: store, title: "允许扩展权限？") else {
                    throw NSError(
                        domain: "RaytoneCodexApprovalCompatSmoke",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "permissions approval did not appear"]
                    )
                }
                store.decideApproval(itemID: permissionsID, decision: .approved)

                guard let execID = await waitForPendingApproval(in: store, title: "允许运行命令？") else {
                    throw NSError(
                        domain: "RaytoneCodexApprovalCompatSmoke",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "legacy exec approval did not appear"]
                    )
                }
                store.decideApproval(itemID: execID, decision: .approvedAlways)

                guard let patchID = await waitForPendingApproval(in: store, title: "允许修改文件？") else {
                    throw NSError(
                        domain: "RaytoneCodexApprovalCompatSmoke",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "legacy patch approval did not appear"]
                    )
                }
                store.decideApproval(itemID: patchID, decision: .denied(note: nil))

                let deadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""permissionsResponse""#) &&
                        logText.contains(#""legacyExecResponse""#) &&
                        logText.contains(#""legacyPatchResponse""#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let approvals = store.selectedThread.items.compactMap { item -> ApprovalRequest? in
                    if case let .approval(request) = item.kind {
                        return request
                    }
                    return nil
                }
                let ok = approvals.count >= 3 &&
                    logText.contains(#""method":"item/permissions/requestApproval""#) &&
                    logText.contains(#""permissionsResponse""#) &&
                    logText.contains(#""network":{"enabled":true}"#) &&
                    logText.contains(#""method":"execCommandApproval""#) &&
                    logText.contains(#""legacyExecResponse":{"decision":"approved_for_session"}"#) &&
                    logText.contains(#""method":"applyPatchApproval""#) &&
                    logText.contains(#""legacyPatchResponse":{"decision":"denied"}"#)

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "approvalCount": approvals.count,
                    "isRunning": store.isRunning,
                    "requestLogPreview": String(logText.prefix(2600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runDynamicToolSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexDynamicToolSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try "raytone dynamic tool smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                _ = try runProcess(["git", "init", "-b", "main"], cwd: workspaceURL)
                _ = try runProcess(["git", "config", "user.email", "raytone@example.invalid"], cwd: workspaceURL)
                _ = try runProcess(["git", "config", "user.name", "Raytone Smoke"], cwd: workspaceURL)
                _ = try runProcess(["git", "add", "README.md"], cwd: workspaceURL)
                _ = try runProcess(["git", "commit", "-m", "Initial dynamic tool smoke"], cwd: workspaceURL)
                try "raytone dynamic tool smoke\nfresh app-server diff\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try fakeDynamicToolAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-dynamic-tool"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_DYNAMIC_TOOL_LOG": logURL.path
                ]
                store.prompt = "触发 Raytone 动态工具"

                await store.runPrompt()
                let deadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""dynamicToolReadFileResponse""#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let commands = commandRuns(in: store.selectedThread.items)
                let dynamicCommand = commands.last { command in
                    command.command.contains("动态工具 raytone_context.workspace_snapshot")
                }
                let filesCommand = commands.last { command in
                    command.command.contains("动态工具 raytone_context.list_workspace_files")
                }
                let readFileCommand = commands.last { command in
                    command.command.contains("动态工具 raytone_context.read_workspace_file")
                }
                let output = dynamicCommand?.output ?? ""
                let filesOutput = filesCommand?.output ?? ""
                let readFileOutput = readFileCommand?.output ?? ""
                let normalizedOutput = output.replacingOccurrences(of: "\\/", with: "/")
                let normalizedFilesOutput = filesOutput.replacingOccurrences(of: "\\/", with: "/")
                let normalizedReadFileOutput = readFileOutput.replacingOccurrences(of: "\\/", with: "/")
                let registeredDynamicTool = logText.contains(#""dynamicTools""#) &&
                    logText.contains(#""namespace":"raytone_context""#) &&
                    logText.contains(#""name":"workspace_snapshot""#) &&
                    logText.contains(#""name":"list_workspace_files""#) &&
                    logText.contains(#""name":"read_workspace_file""#)
                let requestObserved = logText.contains(#""method":"item/tool/call""#) &&
                    logText.contains(#""tool":"workspace_snapshot""#) &&
                    logText.contains(#""tool":"list_workspace_files""#) &&
                    logText.contains(#""tool":"read_workspace_file""#)
                let responseObserved = logText.contains(#""dynamicToolResponse""#) &&
                    logText.contains(#""dynamicToolFilesResponse""#) &&
                    logText.contains(#""dynamicToolReadFileResponse""#) &&
                    logText.contains(#""success":true"#) &&
                    logText.contains(#""contentItems""#)
                let commandExecObserved = logText.contains(#""method":"command/exec""#) ||
                    logText.contains(#""method": "command/exec""#)
                let readFileRequestObserved = logText.contains(#""method":"fs/readFile""#) ||
                    logText.contains(#""method": "fs/readFile""#)
                let freshDiffObserved = output.contains(#""gitDiff""#) &&
                    output.contains(#""files" : 1"#) &&
                    output.contains(#""additions" : 1"#) &&
                    output.contains(#"M README.md"#)
                let fileListObserved = filesOutput.contains(#""entries""#) &&
                    filesOutput.contains(#""entryCount""#) &&
                    normalizedFilesOutput.contains("README.md") &&
                    normalizedFilesOutput.contains(workspaceURL.path)
                let fileReadObserved = readFileOutput.contains(#""content""#) &&
                    readFileOutput.contains(#""byteCount""#) &&
                    normalizedReadFileOutput.contains("README.md") &&
                    normalizedReadFileOutput.contains("raytone dynamic tool smoke") &&
                    normalizedReadFileOutput.contains(workspaceURL.path)
                let ok = registeredDynamicTool &&
                    requestObserved &&
                    responseObserved &&
                    commandExecObserved &&
                    readFileRequestObserved &&
                    freshDiffObserved &&
                    fileListObserved &&
                    fileReadObserved &&
                    dynamicCommand?.status == .succeeded &&
                    filesCommand?.status == .succeeded &&
                    readFileCommand?.status == .succeeded &&
                    output.contains(#""workspacePath""#) &&
                    normalizedOutput.contains(workspaceURL.path) &&
                    output.contains(#""approvalPolicy""#) &&
                    !store.isRunning

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "registeredDynamicTool": registeredDynamicTool,
                    "requestObserved": requestObserved,
                    "responseObserved": responseObserved,
                    "commandExecObserved": commandExecObserved,
                    "readFileRequestObserved": readFileRequestObserved,
                    "freshDiffObserved": freshDiffObserved,
                    "fileListObserved": fileListObserved,
                    "fileReadObserved": fileReadObserved,
                    "isRunning": store.isRunning,
                    "dynamicCommandStatus": runStatusName(dynamicCommand?.status),
                    "filesCommandStatus": runStatusName(filesCommand?.status),
                    "readFileCommandStatus": runStatusName(readFileCommand?.status),
                    "dynamicCommandOutputPreview": String(output.prefix(1200)),
                    "filesCommandOutputPreview": String(filesOutput.prefix(1200)),
                    "readFileCommandOutputPreview": String(readFileOutput.prefix(1200)),
                    "requestLogPreview": String(logText.prefix(2400))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runInterruptSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexInterruptSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeInterruptAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-interrupt"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_INTERRUPT_LOG": logURL.path
                ]
                store.prompt = "启动一个可中断轮次"

                await store.runPrompt()

                let runningDeadline = Date().addingTimeInterval(4)
                while !store.isRunning && Date() < runningDeadline {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }

                let wasRunningBeforeInterrupt = store.isRunning
                await store.interruptRunningTurn()

                let interruptDeadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < interruptDeadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""method":"turn/interrupt""#) && !store.isRunning {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let ok = wasRunningBeforeInterrupt &&
                    !store.isRunning &&
                    store.selectedThread.activeGoal == nil &&
                    store.runtimeCatalogStatusText == "turn/interrupt：已发送" &&
                    logText.contains(#""method":"turn/start""#) &&
                    logText.contains(#""method":"turn/interrupt""#) &&
                    logText.contains(#""threadId":"thread-smoke""#) &&
                    logText.contains(#""turnId":"turn-smoke""#) &&
                    logText.contains(#""turnCompletedAfterInterrupt":true"#)

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "wasRunningBeforeInterrupt": wasRunningBeforeInterrupt,
                    "isRunning": store.isRunning,
                    "activeGoalCleared": store.selectedThread.activeGoal == nil,
                    "runtimeStatus": store.runtimeCatalogStatusText,
                    "requestLogPreview": String(logText.prefix(2200))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runAuthAttestationSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexAuthAttestationSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeAuthAttestationAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-auth-attestation"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_AUTH_ATTESTATION_LOG": logURL.path
                ]
                store.prompt = "触发外部认证和 attestation 请求"

                await store.runPrompt()
                let deadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""authRefreshError""#) &&
                        logText.contains(#""attestationError""#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let notices = store.selectedThread.items.compactMap { item -> Notice? in
                    if case let .notice(notice) = item.kind {
                        return notice
                    }
                    return nil
                }
                let noticeText = notices.map(\.text).joined(separator: "\n")
                let authErrorObserved = logText.contains(#""authRefreshError""#) &&
                    logText.contains("没有托管 ChatGPT OAuth token")
                let attestationErrorObserved = logText.contains(#""attestationError""#) &&
                    logText.contains("不能伪造客户端证明")
                let ok = authErrorObserved &&
                    attestationErrorObserved &&
                    noticeText.contains("account/chatgptAuthTokens/refresh") == false &&
                    noticeText.contains("ChatGPT tokens") &&
                    noticeText.contains("attestation") &&
                    !store.isRunning

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "authErrorObserved": authErrorObserved,
                    "attestationErrorObserved": attestationErrorObserved,
                    "noticeCount": notices.count,
                    "noticePreview": String(noticeText.prefix(1200)),
                    "isRunning": store.isRunning,
                    "requestLogPreview": String(logText.prefix(2600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
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
                let previewSkill = detail?.skills.first { $0.name == "\(pluginName):thread-summarizer" }
                fputs("plugin-read-smoke: readRuntimePluginSkillPreview\n", stderr)
                let skillPreviewOK: Bool
                if let previewSkill {
                    skillPreviewOK = await store.readRuntimePluginSkillPreview(previewSkill)
                } else {
                    skillPreviewOK = false
                }
                let skillPreviewText = store.runtimePluginSkillPreviewText
                fputs("plugin-read-smoke: usePluginInComposer\n", stderr)
                let trialPrepared = await store.usePluginInComposer(plugin)
                let trialPrompt = store.prompt
                let trialMentionPath = store.lastMentionInputPreview.first?["path"] ?? ""
                let ok = store.runtimeSnapshot.executable != nil &&
                    plugin.installed &&
                    plugin.enabled &&
                    detail?.plugin.id == "\(pluginName)@\(marketplaceName)" &&
                    detail?.description == "Raytone plugin/read smoke long description" &&
                    detail?.skills.contains(where: { $0.name == "\(pluginName):thread-summarizer" && !$0.enabled }) == true &&
                    detail?.mcpServers.contains("demo") == true &&
                    detail?.hooks.contains(where: { $0.eventName == "preToolUse" }) == true &&
                    skillPreviewOK &&
                    previewSkill?.path?.isEmpty == false &&
                    store.runtimePluginSkillPreviewStatusText.hasPrefix("plugin/read + fs/readFile") &&
                    skillPreviewText.contains("# Thread Summarizer") &&
                    trialPrepared &&
                    trialPrompt.contains("@\(pluginName)") &&
                    trialPrompt.contains("技能：") &&
                    trialPrompt.contains("MCP：demo") &&
                    trialPrompt.contains("钩子：preToolUse") &&
                    trialMentionPath == plugin.mentionPath

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
                    "skillPreviewStatus": store.runtimePluginSkillPreviewStatusText,
                    "skillPreviewPath": previewSkill?.path ?? "",
                    "skillPreviewContainsHeading": skillPreviewText.contains("# Thread Summarizer"),
                    "trialPrepared": trialPrepared,
                    "trialPrompt": trialPrompt,
                    "trialMentions": store.lastMentionInputPreview,
                    "skills": detail?.skills.map { skill in
                        [
                            "name": skill.name,
                            "displayName": skill.displayName,
                            "enabled": skill.enabled,
                            "path": skill.path ?? ""
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

    private static func runSkillReadSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexSkillReadSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let skillURL = codexHomeURL
                .appendingPathComponent("skills/raytone-readable-skill/SKILL.md")
            let marker = "RAYTONE_SKILL_READ_SMOKE_MARKER"
            let skillText = """
            ---
            name: raytone-readable-skill
            shortDescription: Smoke skill content served through codex app-server fs/readFile.
            ---

            # Raytone Readable Skill

            \(marker)

            使用这个技能时，先说明真实文件路径，再给出可执行验证。
            """

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(
                    at: skillURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try skillText.write(to: skillURL, atomically: true, encoding: .utf8)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                fputs("skill-read-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()

                let skill = CodexRuntimeSkill(
                    name: "raytone-readable-skill",
                    displayName: "Raytone 可读取技能",
                    summary: "通过 app-server 读取本地技能 Markdown",
                    path: skillURL.path,
                    cwd: workspaceURL.path,
                    scope: "user",
                    enabled: true
                )

                fputs("skill-read-smoke: readRuntimeSkillPreview\n", stderr)
                let readOK = await store.readRuntimeSkillPreview(skill)
                let preview = store.runtimeSkillPreviewText
                let ok = store.runtimeSnapshot.executable != nil &&
                    readOK &&
                    store.runtimeSkillPreview?.path == skillURL.path &&
                    store.runtimeSkillPreviewStatusText.hasPrefix("fs/readFile") &&
                    preview.contains(marker) &&
                    preview.contains("# Raytone Readable Skill")

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "skillPath": skillURL.path,
                    "status": store.runtimeSkillPreviewStatusText,
                    "previewByteCount": preview.data(using: .utf8)?.count ?? 0,
                    "previewContainsMarker": preview.contains(marker),
                    "preview": String(preview.prefix(600))
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

    private static func runSkillExtraRootsSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexSkillExtraRootsSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let extraSkillsRootURL = rootURL.appendingPathComponent("runtime-skills", isDirectory: true)
            let skillURL = extraSkillsRootURL.appendingPathComponent("raytone-extra-root-skill/SKILL.md")
            let marker = "RAYTONE_SKILL_EXTRA_ROOTS_MARKER"
            let skillText = """
            ---
            name: raytone-extra-root-skill
            description: Runtime extra roots smoke skill.
            ---

            # Raytone Extra Roots Skill

            \(marker)
            """

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(
                    at: skillURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try skillText.write(to: skillURL, atomically: true, encoding: .utf8)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                fputs("skill-extra-roots-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                fputs("skill-extra-roots-smoke: setRuntimeSkillExtraRoots\n", stderr)
                let setOK = await store.setRuntimeSkillExtraRoots(paths: [extraSkillsRootURL.path])
                let setStatus = store.runtimeCatalogStatusText
                let extraRootsAfterSet = store.runtimeSkillExtraRoots
                let discovered = store.runtimeSkills.first { $0.name == "raytone-extra-root-skill" }
                let discoveredBeforeClear = discovered != nil
                if let discovered {
                    _ = await store.readRuntimeSkillPreview(discovered)
                }
                let preview = store.runtimeSkillPreviewText
                let previewStatus = store.runtimeSkillPreviewStatusText

                fputs("skill-extra-roots-smoke: clearRuntimeSkillExtraRoots\n", stderr)
                let clearOK = await store.setRuntimeSkillExtraRoots(paths: [])
                let removedAfterClear = !store.runtimeSkills.contains { $0.name == "raytone-extra-root-skill" }
                let clearStatus = store.runtimeCatalogStatusText

                await store.stopAppServerForTesting()

                let ok = store.runtimeSnapshot.executable != nil &&
                    setOK &&
                    clearOK &&
                    discoveredBeforeClear &&
                    preview.contains(marker) &&
                    previewStatus.hasPrefix("fs/readFile") &&
                    extraRootsAfterSet == [SessionStore.canonicalPath(extraSkillsRootURL.path)] &&
                    removedAfterClear &&
                    store.runtimeSkillExtraRoots.isEmpty

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "extraSkillsRoot": extraSkillsRootURL.path,
                    "skillPath": skillURL.path,
                    "setOK": setOK,
                    "clearOK": clearOK,
                    "discoveredBeforeClear": discoveredBeforeClear,
                    "removedAfterClear": removedAfterClear,
                    "setStatus": setStatus,
                    "clearStatus": clearStatus,
                    "extraRootsAfterSet": extraRootsAfterSet,
                    "previewStatus": previewStatus,
                    "previewContainsMarker": preview.contains(marker),
                    "preview": String(preview.prefix(600)),
                    "source": "skills/extraRoots/set + skills/list + fs/readFile"
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
                    "extraSkillsRoot": extraSkillsRootURL.path,
                    "skillPath": skillURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runPluginScaffoldSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexPluginScaffoldSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let pluginName = "raytone-local-plugin"
            let skillName = "raytone-local-skill"
            let pluginManifestURL = workspaceURL
                .appendingPathComponent("plugins/\(pluginName)/.codex-plugin/plugin.json")
            let marketplaceURL = workspaceURL
                .appendingPathComponent(".agents/plugins/marketplace.json")
            let pluginSkillURL = workspaceURL
                .appendingPathComponent("plugins/\(pluginName)/skills/raytone-project-helper/SKILL.md")
            let localSkillURL = codexHomeURL
                .appendingPathComponent("skills/\(skillName)/SKILL.md")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: workspaceURL.appendingPathComponent(".git", isDirectory: true), withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                fputs("plugin-scaffold-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                fputs("plugin-scaffold-smoke: createLocalPluginTemplate\n", stderr)
                guard let pluginResult = await store.createLocalPluginTemplate() else {
                    await store.stopAppServerForTesting()
                    emitJSON([
                        "ok": false,
                        "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                        "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                        "runtimeVersion": store.runtimeSnapshot.version ?? "",
                        "workspacePath": workspaceURL.path,
                        "codexHome": codexHomeURL.path,
                        "status": store.runtimeCatalogStatusText,
                        "errors": store.runtimeCatalogErrors
                    ])
                    exit(1)
                }

                fputs("plugin-scaffold-smoke: createLocalSkillTemplate\n", stderr)
                guard let skillResult = await store.createLocalSkillTemplate() else {
                    await store.stopAppServerForTesting()
                    emitJSON([
                        "ok": false,
                        "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                        "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                        "runtimeVersion": store.runtimeSnapshot.version ?? "",
                        "workspacePath": workspaceURL.path,
                        "codexHome": codexHomeURL.path,
                        "pluginResult": scaffoldPayload(pluginResult),
                        "status": store.runtimeCatalogStatusText,
                        "errors": store.runtimeCatalogErrors
                    ])
                    exit(1)
                }

                let marketplaceText = try String(contentsOf: marketplaceURL, encoding: .utf8)
                let manifestText = try String(contentsOf: pluginManifestURL, encoding: .utf8)
                let pluginSkillText = try String(contentsOf: pluginSkillURL, encoding: .utf8)
                let localSkillText = try String(contentsOf: localSkillURL, encoding: .utf8)
                let pluginDiscovered = store.runtimePlugins.contains {
                    $0.name == pluginName && $0.marketplaceName == "raytone-local"
                }
                let localSkillDiscovered = store.runtimeSkills.contains {
                    $0.name == skillName || $0.path == localSkillURL.path
                }
                let ok = store.runtimeSnapshot.executable != nil &&
                    marketplaceText.contains(pluginName) &&
                    manifestText.contains("Raytone 本地插件") &&
                    pluginSkillText.contains("raytone-project-helper") &&
                    localSkillText.contains(skillName) &&
                    pluginResult.readBackSnippets[pluginManifestURL.path]?.contains("Raytone 本地插件") == true &&
                    skillResult.readBackSnippets[localSkillURL.path]?.contains(skillName) == true &&
                    pluginDiscovered &&
                    localSkillDiscovered

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "pluginResult": scaffoldPayload(pluginResult),
                    "skillResult": scaffoldPayload(skillResult),
                    "pluginDiscovered": pluginDiscovered,
                    "localSkillDiscovered": localSkillDiscovered,
                    "status": store.runtimeCatalogStatusText,
                    "errors": store.runtimeCatalogErrors,
                    "artifacts": [
                        "marketplace": marketplaceURL.path,
                        "pluginManifest": pluginManifestURL.path,
                        "pluginSkill": pluginSkillURL.path,
                        "localSkill": localSkillURL.path
                    ],
                    "artifactSnippets": [
                        "marketplace": String(marketplaceText.prefix(240)),
                        "pluginManifest": String(manifestText.prefix(240)),
                        "pluginSkill": String(pluginSkillText.prefix(240)),
                        "localSkill": String(localSkillText.prefix(240))
                    ]
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

    private static func runPluginInstallResponseSmoke() {
        Task { @MainActor in
            let payload = JSONValue.object([
                "authPolicy": .string("ON_USE"),
                "appsNeedingAuth": .array([
                    .object([
                        "id": .string("alpha"),
                        "name": .string("alpha"),
                        "description": .string("Alpha 连接器需要授权"),
                        "installUrl": .string("https://chatgpt.com/apps/alpha/alpha"),
                        "needsAuth": .bool(true)
                    ])
                ])
            ])
            let result = CodexAppServerClient.pluginInstallResult(from: payload)
            let summary = SessionStore.pluginInstallSummary(
                pluginDisplayName: "Raytone Demo Plugin",
                result: result
            )
            let parseOK = result.authPolicy == "ON_USE" &&
                result.appsNeedingAuth.count == 1 &&
                result.appsNeedingAuth.first?.installURL == "https://chatgpt.com/apps/alpha/alpha" &&
                summary.contains("使用时授权") &&
                summary.contains("需要授权 1 个 app")

            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexPluginInstallSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let pluginName = "install-demo-plugin"
            let marketplaceName = "raytone-install"
            let installedManifestURL = codexHomeURL
                .appendingPathComponent("plugins/cache/\(marketplaceName)/\(pluginName)/local/.codex-plugin/plugin.json")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try writePluginInstallSmokeFixture(
                    workspaceURL: workspaceURL,
                    codexHomeURL: codexHomeURL,
                    pluginName: pluginName,
                    marketplaceName: marketplaceName
                )

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                fputs("plugin-install-response-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                fputs("plugin-install-response-smoke: refreshRuntimeCatalog\n", stderr)
                await store.refreshRuntimeCatalog(forceReloadSkills: true)

                guard let plugin = store.runtimePlugins.first(where: { $0.name == pluginName && $0.marketplaceName == marketplaceName }) else {
                    await store.stopAppServerForTesting()
                    emitJSON([
                        "ok": false,
                        "schema": "PluginInstallResponse",
                        "parseOK": parseOK,
                        "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                        "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                        "runtimeVersion": store.runtimeSnapshot.version ?? "",
                        "workspacePath": workspaceURL.path,
                        "codexHome": codexHomeURL.path,
                        "status": store.runtimeCatalogStatusText,
                        "errors": store.runtimeCatalogErrors,
                        "plugins": store.runtimePlugins.map { runtimePlugin in
                            [
                                "name": runtimePlugin.name,
                                "marketplace": runtimePlugin.marketplaceName,
                                "installed": runtimePlugin.installed
                            ] as [String: Any]
                        }
                    ])
                    exit(1)
                }

                fputs("plugin-install-response-smoke: togglePluginInstallation\n", stderr)
                let installedBefore = plugin.installed
                await store.togglePluginInstallation(plugin)
                let refreshedPlugin = store.runtimePlugins.first {
                    $0.name == pluginName && $0.marketplaceName == marketplaceName
                }
                let liveResult = store.runtimePluginInstallResult
                let opened = result.appsNeedingAuth.first.map {
                    store.openPluginInstallAuthURL($0, openExternal: false)
                } ?? false
                let integrationOK = store.runtimeSnapshot.executable != nil &&
                    !installedBefore &&
                    refreshedPlugin?.installed == true &&
                    liveResult?.authPolicy == "ON_USE" &&
                    liveResult?.appsNeedingAuth.isEmpty == true &&
                    fileManager.fileExists(atPath: installedManifestURL.path) &&
                    store.runtimeCatalogStatusText.contains("打开 alpha 授权链接")
                let ok = parseOK &&
                    integrationOK &&
                    opened &&
                    store.lastOpenedRuntimeAppInstallURL == "https://chatgpt.com/apps/alpha/alpha"

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "schema": "PluginInstallResponse",
                    "parseOK": parseOK,
                    "integrationOK": integrationOK,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "authPolicy": result.authPolicy,
                    "authPolicyName": SessionStore.pluginAuthPolicyDisplayName(result.authPolicy),
                    "summary": summary,
                    "appsNeedingAuth": result.appsNeedingAuth.map(pluginAppPayload),
                    "liveInstallResult": pluginInstallPayload(liveResult),
                    "installedBefore": installedBefore,
                    "installedAfter": refreshedPlugin?.installed ?? false,
                    "installedManifest": installedManifestURL.path,
                    "installedManifestExists": fileManager.fileExists(atPath: installedManifestURL.path),
                    "openedAuthURL": opened,
                    "lastOpenedRuntimeAppInstallURL": store.lastOpenedRuntimeAppInstallURL,
                    "status": store.runtimeCatalogStatusText,
                    "errors": store.runtimeCatalogErrors
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "schema": "PluginInstallResponse",
                    "parseOK": parseOK,
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runPluginShareSmoke() {
        Task { @MainActor in
            let saveFixture = try? JSONValue(jsonString: """
            {
              "remotePluginId": "plugins_raytone_share_smoke",
              "shareUrl": "https://chatgpt.example/plugins/share/plugins_raytone_share_smoke"
            }
            """)
            let parsedSave = saveFixture.flatMap { try? CodexAppServerClient.pluginShareSaveResult(from: $0) }
            let updateFixture = try? JSONValue(jsonString: """
            {
              "discoverability": "PRIVATE",
              "principals": [
                {
                  "principalId": "user_raytone",
                  "principalType": "user",
                  "role": "owner",
                  "name": "Raytone"
                }
              ]
            }
            """)
            let parsedUpdate = updateFixture.map { CodexAppServerClient.pluginShareUpdateResult(from: $0) }
            let parseOK = parsedSave?.remotePluginID == "plugins_raytone_share_smoke" &&
                parsedSave?.shareURL.contains("plugins_raytone_share_smoke") == true &&
                parsedUpdate?.discoverability == "PRIVATE" &&
                parsedUpdate?.principals.first?.role == "owner"

            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexPluginShareSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let pluginRootURL = workspaceURL.appendingPathComponent("plugins/share-smoke-plugin", isDirectory: true)
            let manifestURL = pluginRootURL.appendingPathComponent(".codex-plugin/plugin.json")
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(
                    at: manifestURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try #"{"name":"share-smoke-plugin"}"#.write(to: manifestURL, atomically: true, encoding: .utf8)
                try fakePluginShareAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let plugin = CodexRuntimePlugin(
                    id: "share-smoke-plugin@raytone-local",
                    name: "share-smoke-plugin",
                    displayName: "共享 Smoke 插件",
                    summary: "验证 plugin/share/save 和 plugin/share/updateTargets",
                    marketplaceName: "raytone-local",
                    marketplaceDisplayName: "Raytone Local",
                    marketplacePath: nil,
                    localPluginPath: pluginRootURL.path,
                    category: "local",
                    developerName: "Raytone",
                    sourceType: "local",
                    installPolicy: "AVAILABLE",
                    authPolicy: "NONE",
                    availability: "AVAILABLE",
                    shareContext: nil,
                    installed: true,
                    enabled: true
                )

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-plugin-share"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_PLUGIN_SHARE_LOG": logURL.path
                ]
                store.runtimePlugins = [plugin]
                store.runtimePluginDetail = CodexRuntimePluginDetail(
                    plugin: plugin,
                    description: "本地插件共享 smoke",
                    skills: [],
                    hooks: [],
                    mcpServers: [],
                    apps: []
                )

                await store.saveSharedPlugin(plugin)
                let sharedPlugin = store.runtimePluginDetail?.plugin
                await store.updateSharedPluginDiscoverability(sharedPlugin ?? plugin, discoverability: "PRIVATE")

                let deadline = Date().addingTimeInterval(4)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""method":"plugin/share/save""#) &&
                        logText.contains(#""method":"plugin/share/updateTargets""#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }

                let finalContext = store.runtimePluginDetail?.plugin.shareContext
                let saveRequestOK = logText.contains(#""method":"plugin/share/save""#) &&
                    logText.contains(#""pluginPath":""#) &&
                    logText.contains(pluginRootURL.path) &&
                    logText.contains(#""discoverability":"UNLISTED""#) &&
                    logText.contains(#""shareTargets":[]"#)
                let updateRequestOK = logText.contains(#""method":"plugin/share/updateTargets""#) &&
                    logText.contains(#""remotePluginId":"plugins_raytone_share_smoke""#) &&
                    logText.contains(#""discoverability":"PRIVATE""#)
                let uiStateOK = finalContext?.remotePluginID == "plugins_raytone_share_smoke" &&
                    finalContext?.discoverability == "PRIVATE" &&
                    finalContext?.shareURL == "https://chatgpt.example/plugins/share/plugins_raytone_share_smoke" &&
                    store.runtimeCatalogStatusText.contains("plugin/share/updateTargets")
                let ok = parseOK && saveRequestOK && updateRequestOK && uiStateOK

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "parseOK": parseOK,
                    "workspacePath": workspaceURL.path,
                    "pluginPath": pluginRootURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "saveRequestOK": saveRequestOK,
                    "updateRequestOK": updateRequestOK,
                    "uiStateOK": uiStateOK,
                    "remotePluginId": finalContext?.remotePluginID ?? "",
                    "discoverability": finalContext?.discoverability ?? "",
                    "shareUrl": finalContext?.shareURL ?? "",
                    "status": store.runtimeCatalogStatusText,
                    "requestLogPreview": String(logText.prefix(2400))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "parseOK": parseOK,
                    "workspacePath": workspaceURL.path,
                    "pluginPath": pluginRootURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runMarketplaceUpgradeSmoke() {
        Task { @MainActor in
            let addFixture = JSONValue.object([
                "marketplaceName": .string("raytone-market"),
                "installedRoot": .string("/tmp/raytone-market"),
                "alreadyAdded": .bool(false)
            ])
            let removeFixture = JSONValue.object([
                "marketplaceName": .string("raytone-market"),
                "installedRoot": .string("/tmp/raytone-market")
            ])
            let upgradeFixture = JSONValue.object([
                "selectedMarketplaces": .array([.string("raytone-market")]),
                "upgradedRoots": .array([.string("/tmp/raytone-market")]),
                "errors": .array([
                    .object([
                        "marketplaceName": .string("broken-market"),
                        "message": .string("network unavailable")
                    ])
                ])
            ])
            let parsedAdd = try? CodexAppServerClient.marketplaceAddResult(from: addFixture)
            let parsedRemove = try? CodexAppServerClient.marketplaceRemoveResult(from: removeFixture)
            let parsedUpgrade = try? CodexAppServerClient.marketplaceUpgradeResult(from: upgradeFixture)
            let parseOK = parsedAdd?.marketplaceName == "raytone-market" &&
                parsedAdd?.alreadyAdded == false &&
                parsedRemove?.installedRoot == "/tmp/raytone-market" &&
                parsedUpgrade?.selectedMarketplaces == ["raytone-market"] &&
                parsedUpgrade?.upgradedRoots == ["/tmp/raytone-market"] &&
                parsedUpgrade?.errors.first?.marketplaceName == "broken-market"

            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexMarketplaceSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                fputs("marketplace-upgrade-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                fputs("marketplace-upgrade-smoke: marketplace/upgrade\n", stderr)
                let result = await store.upgradePluginMarketplaces()
                let sourceFacts = store.environmentSourceFacts
                let marketplaceFact = sourceFacts.first { $0.title == "插件市场" }
                let summary = result.map { SessionStore.marketplaceUpgradeSummary($0) } ?? ""
                let integrationOK = store.runtimeSnapshot.executable != nil &&
                    result != nil &&
                    store.runtimeCatalogStatusText.hasPrefix("marketplace/upgrade") &&
                    marketplaceFact?.source == "marketplace/upgrade" &&
                    marketplaceFact?.active == true &&
                    store.runtimeCatalogErrors == (result?.errors.map { "\($0.marketplaceName)：\($0.message)" } ?? [])
                let ok = parseOK && integrationOK

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "schema": "MarketplaceAdd/Remove/Upgrade",
                    "parseOK": parseOK,
                    "integrationOK": integrationOK,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "status": store.runtimeCatalogStatusText,
                    "summary": summary,
                    "selectedMarketplaces": result?.selectedMarketplaces ?? [],
                    "upgradedRoots": result?.upgradedRoots ?? [],
                    "responseErrors": result?.errors.map { error in
                        [
                            "marketplaceName": error.marketplaceName,
                            "message": error.message
                        ]
                    } ?? [],
                    "storeErrors": store.runtimeCatalogErrors,
                    "marketplaceFact": [
                        "title": marketplaceFact?.title ?? "",
                        "source": marketplaceFact?.source ?? "",
                        "detail": marketplaceFact?.detail ?? "",
                        "active": marketplaceFact?.active ?? false
                    ]
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "schema": "MarketplaceAdd/Remove/Upgrade",
                    "parseOK": parseOK,
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runCodexHomeDirectorySmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexHomeDirectorySmoke-\(UUID().uuidString)", isDirectory: true)

            do {
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                let store = SessionStore()
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                let pluginsURL = store.ensureCodexHomeSubfolder("plugins")
                let skillsURL = store.ensureCodexHomeSubfolder("skills")
                let trimmedURL = store.ensureCodexHomeSubfolder("/plugins/")
                let homeURL = store.ensureCodexHomeSubfolder("")

                let pluginExists = fileManager.fileExists(atPath: pluginsURL.path)
                let skillsExists = fileManager.fileExists(atPath: skillsURL.path)
                let homeExists = fileManager.fileExists(atPath: homeURL.path)
                let ok = pluginExists &&
                    skillsExists &&
                    homeExists &&
                    homeURL.path == codexHomeURL.path &&
                    pluginsURL.path == codexHomeURL.appendingPathComponent("plugins").path &&
                    skillsURL.path == codexHomeURL.appendingPathComponent("skills").path &&
                    trimmedURL.path == pluginsURL.path &&
                    store.runtimeCatalogStatusText.contains(codexHomeURL.lastPathComponent)

                emitJSON([
                    "ok": ok,
                    "codexHome": codexHomeURL.path,
                    "homeURL": homeURL.path,
                    "pluginsURL": pluginsURL.path,
                    "skillsURL": skillsURL.path,
                    "trimmedURL": trimmedURL.path,
                    "homeExists": homeExists,
                    "pluginExists": pluginExists,
                    "skillsExists": skillsExists,
                    "status": store.runtimeCatalogStatusText
                ])
                try? fileManager.removeItem(at: codexHomeURL)
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "codexHome": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                try? fileManager.removeItem(at: codexHomeURL)
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

    private static func runModelProviderCapabilitiesSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexModelProviderCapabilitiesSmoke-\(UUID().uuidString)", isDirectory: true)
            let logURL = workspaceURL.appendingPathComponent("requests.jsonl")
            let scriptURL = workspaceURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeModelProviderCapabilitiesAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-model-provider-capabilities"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_MODEL_PROVIDER_CAPABILITIES_LOG": logURL.path
                ]

                await store.refreshModelProviderCapabilities()
                let capabilities = store.modelProviderCapabilities
                let status = store.modelProviderCapabilitiesStatusText
                await store.stopAppServerForTesting()

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                let ok = capabilities?.namespaceTools == true &&
                    capabilities?.imageGeneration == true &&
                    capabilities?.webSearch == false &&
                    status.contains("modelProvider/capabilities/read") &&
                    logText.contains(#""method":"modelProvider/capabilities/read""#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "namespaceTools": capabilities?.namespaceTools ?? false,
                    "imageGeneration": capabilities?.imageGeneration ?? false,
                    "webSearch": capabilities?.webSearch ?? false,
                    "status": status,
                    "runtimeCatalogErrors": store.runtimeCatalogErrors,
                    "requestLogPreview": String(logText.prefix(1200))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runExternalAgentConfigSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexExternalAgentConfigSmoke-\(UUID().uuidString)", isDirectory: true)
            let logURL = workspaceURL.appendingPathComponent("requests.jsonl")
            let scriptURL = workspaceURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeExternalAgentConfigAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-external-agent-config"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_EXTERNAL_AGENT_CONFIG_LOG": logURL.path
                ]

                await store.detectExternalAgentConfig()
                let detectedItems = store.externalAgentMigrationItems
                let detectStatus = store.externalAgentMigrationStatusText

                await store.importExternalAgentConfig()
                let deadline = Date().addingTimeInterval(8)
                while Date() < deadline && store.externalAgentMigrationIsImporting {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let importStatus = store.externalAgentMigrationStatusText

                await store.stopAppServerForTesting()

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                let ok = detectedItems.count == 2 &&
                    detectStatus.contains("externalAgentConfig/detect") &&
                    importStatus.contains("externalAgentConfig/import/completed") &&
                    !store.externalAgentMigrationIsImporting &&
                    store.externalAgentImportedItemCount == 2 &&
                    logText.contains(#""method":"externalAgentConfig/detect""#) &&
                    logText.contains(#""includeHome":true"#) &&
                    logText.contains(#""method":"externalAgentConfig/import""#) &&
                    logText.contains(#""migrationItems""#) &&
                    logText.contains(#""itemType":"PLUGINS""#) &&
                    logText.contains(#""details":{"plugins":["#) &&
                    logText.contains(#""marketplaceName":"team-marketplace""#) &&
                    logText.contains(#""pluginNames":["asana","jira"]"#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "detectedCount": detectedItems.count,
                    "detectStatus": detectStatus,
                    "importStatus": importStatus,
                    "importedItemCount": store.externalAgentImportedItemCount,
                    "items": detectedItems.map { item in
                        [
                            "itemType": item.itemType,
                            "description": item.description,
                            "cwd": item.cwd ?? "",
                            "details": item.details?.prettyJSONString ?? ""
                        ] as [String: Any]
                    },
                    "runtimeCatalogErrors": store.runtimeCatalogErrors,
                    "requestLogPreview": String(logText.prefix(1800))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runExternalAgentRealSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexExternalAgentRealSmoke-\(UUID().uuidString)", isDirectory: true)
            let homeURL = rootURL.appendingPathComponent("home", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let claudeURL = homeURL.appendingPathComponent(".claude", isDirectory: true)
            let sourceSkillURL = claudeURL
                .appendingPathComponent("skills/raytone-claude-skill/SKILL.md")
            let targetAgentsURL = codexHomeURL.appendingPathComponent("AGENTS.md")
            let targetSkillURL = rootURL
                .appendingPathComponent(".agents/skills/raytone-claude-skill/SKILL.md")
            let agentsMarker = "RAYTONE_EXTERNAL_AGENT_AGENTS_MARKER"
            let skillMarker = "RAYTONE_EXTERNAL_AGENT_SKILL_MARKER"

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(
                    at: sourceSkillURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try """
                # Claude Instructions

                \(agentsMarker)

                请把迁移后的说明改写为 Codex AGENTS.md。
                """.write(
                    to: claudeURL.appendingPathComponent("CLAUDE.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try """
                ---
                name: raytone-claude-skill
                shortDescription: Migrated Claude skill fixture.
                ---

                # Raytone Claude Skill

                \(skillMarker)
                """.write(to: sourceSkillURL, atomically: true, encoding: .utf8)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path,
                    "HOME": homeURL.path,
                    "USERPROFILE": homeURL.path
                ]

                fputs("external-agent-real-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                fputs("external-agent-real-smoke: detectExternalAgentConfig\n", stderr)
                await store.detectExternalAgentConfig()
                let detectedItems = store.externalAgentMigrationItems
                let detectTypes = Set(detectedItems.map(\.itemType))
                let detectStatus = store.externalAgentMigrationStatusText

                fputs("external-agent-real-smoke: importExternalAgentConfig\n", stderr)
                await store.importExternalAgentConfig(detectedItems)
                let deadline = Date().addingTimeInterval(15)
                while Date() < deadline && store.externalAgentMigrationIsImporting {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let importCompletionObserved = !store.externalAgentMigrationIsImporting
                try? await Task.sleep(nanoseconds: 500_000_000)
                let finalStatus = store.externalAgentMigrationStatusText
                let targetAgentsText = (try? String(contentsOf: targetAgentsURL, encoding: .utf8)) ?? ""
                let targetSkillText = (try? String(contentsOf: targetSkillURL, encoding: .utf8)) ?? ""
                let remainingItems = store.externalAgentMigrationItems
                await store.stopAppServerForTesting()

                let ok = store.runtimeSnapshot.executable != nil &&
                    detectTypes.contains("AGENTS_MD") &&
                    detectTypes.contains("SKILLS") &&
                    importCompletionObserved &&
                    targetAgentsText.contains(agentsMarker) &&
                    targetSkillText.contains(skillMarker) &&
                    remainingItems.isEmpty

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "rootPath": rootURL.path,
                    "homePath": homeURL.path,
                    "codexHome": codexHomeURL.path,
                    "workspacePath": workspaceURL.path,
                    "detectedCount": detectedItems.count,
                    "detectedTypes": detectedItems.map(\.itemType),
                    "detectStatus": detectStatus,
                    "importCompletionObserved": importCompletionObserved,
                    "finalStatus": finalStatus,
                    "remainingDetectedCount": remainingItems.count,
                    "targetAgentsPath": targetAgentsURL.path,
                    "targetAgentsContainsMarker": targetAgentsText.contains(agentsMarker),
                    "targetSkillPath": targetSkillURL.path,
                    "targetSkillContainsMarker": targetSkillText.contains(skillMarker),
                    "runtimeCatalogErrors": store.runtimeCatalogErrors
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "runtimeSource": "unknown",
                    "runtimePath": "",
                    "runtimeVersion": "",
                    "rootPath": rootURL.path,
                    "homePath": homeURL.path,
                    "codexHome": codexHomeURL.path,
                    "workspacePath": workspaceURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
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
        let editedModel = "smoke-edited-model"

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexProviderSidecarSmoke-\(UUID().uuidString)", isDirectory: true)
            let server: MockResponsesServer
            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                server = try startMockModelsServer(models: [editedModel, "smoke-secondary-model"])
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "providerID": providerID,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]
            let editedBaseURL = "\(server.baseURL)/v1"
            store.providers.append(RaytoneProviderConfiguration(
                id: providerID,
                displayName: "Smoke Provider",
                baseURL: editedBaseURL,
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
                let usageResponse = try await postProviderUsageSmokeRequest(
                    sidecarBaseURL: store.providerConnectionBaseURL,
                    model: editedModel
                )
                await store.refreshSelectedProviderUsage()

                let codexConfigText = (try? String(
                    contentsOfFile: store.providerConnectionCodexConfigPath,
                    encoding: .utf8
                )) ?? ""
                let proxyConfigText = (try? String(
                    contentsOfFile: store.providerConnectionProxyConfigPath,
                    encoding: .utf8
                )) ?? ""
                let persistedConfigURL = codexHome.appendingPathComponent("config.toml")
                let persistedConfigText = (try? String(contentsOf: persistedConfigURL, encoding: .utf8)) ?? ""
                let persistedProvider = store.runtimeConfig?.raytoneProviders.first { $0.id == providerID }
                let providerUsage = store.providerUsage
                let syncedModels = [editedModel, "smoke-secondary-model"]
                let ok = store.runtimeSnapshot.executable != nil &&
                    store.selectedProviderID == providerID &&
                    store.providerConnectionStatusText.contains("上游已验证") &&
                    store.providerConnectionBaseURL.contains("127.0.0.1") &&
                    store.providerConnectionDetailText.contains("/v1/models") &&
                    store.providerConnectionDetailText.contains("2 个模型") &&
                    store.providerConnectionDetailText.contains("已同步 2 个") &&
                    store.selectedProvider.models == syncedModels &&
                    store.selectedProvider.baseURL == editedBaseURL &&
                    store.selectedProvider.model == editedModel &&
                    codexConfigText.contains("model_provider = \"raytone-\(providerID)\"") &&
                    codexConfigText.contains("model = \"\(editedModel)\"") &&
                    codexConfigText.contains("wire_api = \"responses\"") &&
                    codexConfigText.contains("base_url = \"\(store.providerConnectionBaseURL)") &&
                    store.runtimeConfig?.raytoneSelectedProviderID == providerID &&
                    persistedProvider?.baseURL == editedBaseURL &&
                    persistedProvider?.model == editedModel &&
                    persistedProvider?.models == syncedModels &&
                    persistedConfigText.contains("selected_provider_id") &&
                    persistedConfigText.contains("providers_json") &&
                    persistedConfigText.contains(providerID) &&
                    persistedConfigText.contains("smoke-secondary-model") &&
                    proxyConfigText.contains("current_provider = \"\(providerID)\"") &&
                    proxyConfigText.contains("base_url = \"\(editedBaseURL)\"") &&
                    proxyConfigText.contains("model = \"\(editedModel)\"") &&
                    proxyConfigText.contains("smoke-secondary-model") &&
                    proxyConfigText.contains("api_key_env = \"RAYTONE_PROVIDER_API_KEY\"") &&
                    usageResponse.contains("\"total_tokens\":18") &&
                    providerUsage?.provider == providerID &&
                    providerUsage?.model == editedModel &&
                    providerUsage?.requests == 1 &&
                    providerUsage?.successfulResponses == 1 &&
                    providerUsage?.totalTokens == 18 &&
                    providerUsage?.reasoningTokens == 3
                let upstreamRequestLog = (try? String(contentsOf: server.requestLogURL, encoding: .utf8)) ?? ""
                let upstreamVerified = (
                    upstreamRequestLog.contains("\"path\":\"/v1/models\"") ||
                        upstreamRequestLog.contains("\"path\":\"\\/v1\\/models\"")
                ) &&
                    upstreamRequestLog.contains("\"path\":\"/v1/chat/completions\"") &&
                    upstreamRequestLog.contains("\"authorization\":\"Bearer raytone-smoke-key\"")
                let finalOK = ok && upstreamVerified

                await store.stopAppServerForTesting()
                try? RaytoneKeychainService.deletePassword(account: providerID)
                server.stop()

                emitJSON([
                    "ok": finalOK,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "providerID": providerID,
                    "editedBaseURL": editedBaseURL,
                    "editedModel": editedModel,
                    "status": store.providerConnectionStatusText,
                    "detail": store.providerConnectionDetailText,
                    "sidecar": store.sidecarStatusText,
                    "usageStatus": store.providerUsageStatusText,
                    "usageResponse": usageResponse,
                    "syncedModels": store.selectedProvider.models,
                    "providerUsage": providerUsage.map { usage in
                        [
                            "provider": usage.provider,
                            "model": usage.model,
                            "requests": usage.requests,
                            "successfulResponses": usage.successfulResponses,
                            "failedResponses": usage.failedResponses,
                            "inputTokens": usage.inputTokens,
                            "outputTokens": usage.outputTokens,
                            "totalTokens": usage.totalTokens,
                            "reasoningTokens": usage.reasoningTokens
                        ] as [String: Any]
                    } ?? NSNull(),
                    "baseURL": store.providerConnectionBaseURL,
                    "codexConfigPath": store.providerConnectionCodexConfigPath,
                    "proxyConfigPath": store.providerConnectionProxyConfigPath,
                    "persistedConfigPath": persistedConfigURL.path,
                    "persistedConfigText": persistedConfigText,
                    "persistedSelectedProviderID": store.runtimeConfig?.raytoneSelectedProviderID ?? "",
                    "persistedProvider": persistedProvider.map { provider in
                        [
                            "id": provider.id,
                            "baseURL": provider.baseURL,
                            "model": provider.model,
                            "models": provider.models
                        ] as [String: Any]
                    } ?? NSNull(),
                    "upstreamVerified": upstreamVerified,
                    "upstreamRequestLog": upstreamRequestLog,
                    "codexConfigText": codexConfigText,
                    "proxyConfigText": proxyConfigText
                ])
                exit(finalOK ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                try? RaytoneKeychainService.deletePassword(account: providerID)
                server.stop()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "providerID": providerID,
                    "status": store.providerConnectionStatusText,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runProviderOnboardingSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
        let providerID = "onboarding-\(UUID().uuidString.prefix(8))"
        let model = "onboarding-model"

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            let codexHome = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexProviderOnboardingSmoke-\(UUID().uuidString)", isDirectory: true)
            let server: MockResponsesServer

            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                server = try startMockModelsServer(models: [model])
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "providerID": providerID,
                    "error": error.localizedDescription
                ])
                exit(1)
            }

            let baseURL = "\(server.baseURL)/v1"
            store.appServerEnvironmentOverridesForTesting = [
                "CODEX_HOME": codexHome.path
            ]
            store.providers.append(RaytoneProviderConfiguration(
                id: providerID,
                displayName: "Onboarding Provider",
                baseURL: baseURL,
                model: model,
                models: [model],
                kind: .chatCompletionsSidecar
            ))

            do {
                try? RaytoneKeychainService.deletePassword(account: providerID)
                store.resetProviderOnboardingForTesting()
                store.evaluateProviderOnboarding(force: true)
                let initiallyPresented = store.providerOnboardingPresented

                let completed = await store.completeProviderOnboarding(
                    providerID: providerID,
                    apiKey: "raytone-onboarding-key",
                    baseURL: baseURL,
                    model: model
                )
                let savedKey = try RaytoneKeychainService.readPassword(account: providerID)
                store.evaluateProviderOnboarding()
                let presentedAfterCompletion = store.providerOnboardingPresented
                let codexConfigText = (try? String(
                    contentsOfFile: store.providerConnectionCodexConfigPath,
                    encoding: .utf8
                )) ?? ""
                let proxyConfigText = (try? String(
                    contentsOfFile: store.providerConnectionProxyConfigPath,
                    encoding: .utf8
                )) ?? ""
                let persistedConfigURL = codexHome.appendingPathComponent("config.toml")
                let persistedConfigText = (try? String(contentsOf: persistedConfigURL, encoding: .utf8)) ?? ""
                let requestLog = (try? String(contentsOf: server.requestLogURL, encoding: .utf8)) ?? ""
                let upstreamVerified = requestLog.contains("\"path\":\"/v1/models\"") ||
                    requestLog.contains("\"path\":\"\\/v1\\/models\"")
                let ok = initiallyPresented &&
                    completed &&
                    !presentedAfterCompletion &&
                    savedKey == "raytone-onboarding-key" &&
                    store.selectedProviderID == providerID &&
                    store.providerOnboardingStatusText.contains("已完成") &&
                    store.providerConnectionStatusText.contains("上游已验证") &&
                    store.providerConnectionBaseURL.contains("127.0.0.1") &&
                    codexConfigText.contains("model_provider = \"raytone-\(providerID)\"") &&
                    codexConfigText.contains("model = \"\(model)\"") &&
                    proxyConfigText.contains("current_provider = \"\(providerID)\"") &&
                    persistedConfigText.contains("selected_provider_id") &&
                    persistedConfigText.contains(providerID) &&
                    upstreamVerified

                let onboardingStatus = store.providerOnboardingStatusText
                let connectionStatus = store.providerConnectionStatusText
                let sidecarStatus = store.sidecarStatusText
                await store.stopAppServerForTesting()
                try? RaytoneKeychainService.deletePassword(account: providerID)
                store.resetProviderOnboardingForTesting()
                let cleanupStatus = store.providerOnboardingStatusText
                server.stop()

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "providerID": providerID,
                    "baseURL": baseURL,
                    "model": model,
                    "initiallyPresented": initiallyPresented,
                    "completed": completed,
                    "presentedAfterCompletion": presentedAfterCompletion,
                    "savedKey": "present",
                    "status": onboardingStatus,
                    "cleanupStatus": cleanupStatus,
                    "connectionStatus": connectionStatus,
                    "sidecar": sidecarStatus,
                    "codexConfigPath": store.providerConnectionCodexConfigPath,
                    "proxyConfigPath": store.providerConnectionProxyConfigPath,
                    "persistedConfigPath": persistedConfigURL.path,
                    "upstreamVerified": upstreamVerified,
                    "requestLog": requestLog,
                    "codexConfigText": codexConfigText,
                    "proxyConfigText": proxyConfigText,
                    "persistedConfigText": persistedConfigText
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store.stopAppServerForTesting()
                try? RaytoneKeychainService.deletePassword(account: providerID)
                store.resetProviderOnboardingForTesting()
                server.stop()
                emitJSON([
                    "ok": false,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "providerID": providerID,
                    "status": store.providerOnboardingStatusText,
                    "connectionStatus": store.providerConnectionStatusText,
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

    private static func runThreadMemoryModeSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadMemoryModeSmoke-\(UUID().uuidString)", isDirectory: true)
            let logURL = workspaceURL.appendingPathComponent("requests.jsonl")
            let scriptURL = workspaceURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeThreadMemoryModeAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-thread-memory-mode"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_THREAD_MEMORY_MODE_LOG": logURL.path
                ]

                await store.saveSelectedThreadMemoryMode(.disabled)
                let disabledStatus = store.runtimeCatalogStatusText
                let threadIDAfterFirstWrite = store.selectedThread.appServerThreadID ?? ""
                let disabledMode = store.selectedThread.memoryMode?.rawValue ?? ""

                await store.saveSelectedThreadMemoryMode(.enabled)
                let enabledStatus = store.runtimeCatalogStatusText
                let threadIDAfterSecondWrite = store.selectedThread.appServerThreadID ?? ""
                let enabledMode = store.selectedThread.memoryMode?.rawValue ?? ""

                await store.stopAppServerForTesting()

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                let ok = threadIDAfterFirstWrite == "00000000-0000-0000-0000-000000000001" &&
                    threadIDAfterSecondWrite == threadIDAfterFirstWrite &&
                    disabledMode == CodexThreadMemoryMode.disabled.rawValue &&
                    enabledMode == CodexThreadMemoryMode.enabled.rawValue &&
                    disabledStatus.contains("thread/memoryMode/set") &&
                    enabledStatus.contains("thread/memoryMode/set") &&
                    logText.contains(#""method":"thread/start""#) &&
                    logText.contains(#""method":"thread/memoryMode/set""#) &&
                    logText.contains(#""threadId":"00000000-0000-0000-0000-000000000001""#) &&
                    logText.contains(#""mode":"disabled""#) &&
                    logText.contains(#""mode":"enabled""#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "threadID": threadIDAfterSecondWrite,
                    "disabledMode": disabledMode,
                    "enabledMode": enabledMode,
                    "disabledStatus": disabledStatus,
                    "enabledStatus": enabledStatus,
                    "requestLogPreview": String(logText.prefix(1400))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
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
                await waitForCollaborationModeUpdate(in: store, expectedKind: "default")
                let codingConfig = store.runtimeConfig
                let codingText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let codingState: [String: Any] = [
                    "workModeID": store.runtimeWorkModeID,
                    "collaborationModeKind": store.selectedCollaborationModeKind,
                    "collaborationModeStatus": store.runtimeCollaborationModeStatusText,
                    "threadID": store.selectedThread.appServerThreadID ?? "",
                    "modelVerbosity": codingConfig?.modelVerbosity ?? "",
                    "configText": codingText
                ]

                await store.saveRuntimeWorkMode(id: "daily")
                await waitForCollaborationModeUpdate(in: store, expectedKind: "plan")
                let dailyConfig = store.runtimeConfig
                let dailyText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let collaborationModePayload = store.runtimeCollaborationModes.map { preset in
                    [
                        "name": preset.name,
                        "mode": preset.mode ?? "",
                        "model": preset.model ?? "",
                        "reasoningEffort": preset.reasoningEffort ?? ""
                    ]
                }
                let dailyState: [String: Any] = [
                    "workModeID": store.runtimeWorkModeID,
                    "collaborationModeKind": store.selectedCollaborationModeKind,
                    "collaborationModeStatus": store.runtimeCollaborationModeStatusText,
                    "threadID": store.selectedThread.appServerThreadID ?? "",
                    "modelVerbosity": dailyConfig?.modelVerbosity ?? "",
                    "configText": dailyText
                ]

                await store.stopAppServerForTesting()

                let modes = Set(store.runtimeCollaborationModes.compactMap(\.mode))
                let ok = codingConfig?.modelVerbosity == "high" &&
                    codingText.contains("model_verbosity = \"high\"") &&
                    codingState["workModeID"] as? String == "coding" &&
                    codingState["collaborationModeKind"] as? String == "default" &&
                    (codingState["threadID"] as? String)?.isEmpty == false &&
                    dailyConfig?.modelVerbosity == "low" &&
                    dailyText.contains("model_verbosity = \"low\"") &&
                    dailyState["workModeID"] as? String == "daily" &&
                    dailyState["collaborationModeKind"] as? String == "plan" &&
                    (dailyState["threadID"] as? String)?.isEmpty == false &&
                    modes.contains("default") &&
                    modes.contains("plan")

                emitJSON([
                    "ok": ok,
                    "source": "collaborationMode/list + thread/settings/update.collaborationMode + config/write model_verbosity",
                    "runtimeSource": runtime.executable?.source.rawValue ?? "none",
                    "runtimePath": runtime.executable?.url.path ?? "",
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspacePath,
                    "codexHome": codexHome.path,
                    "configPath": configURL.path,
                    "collaborationModes": collaborationModePayload,
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

    private static func runBrowserClearDataSmoke() {
        Task { @MainActor in
            let store = SessionStore()
            store.openBrowserAddress("https://raytone.example/clear-data-smoke")
            store.updateBrowserNavigationState(
                url: URL(string: "https://raytone.example/clear-data-smoke"),
                title: "Raytone Clear Data Smoke",
                canGoBack: true,
                canGoForward: true
            )
            let reloadTokenBefore = store.browserReloadToken

            await store.clearBrowserWebsiteData()

            let ok = store.browserDataStatusText == "已清除浏览数据和缓存" &&
                store.browserCanGoBack == false &&
                store.browserCanGoForward == false &&
                store.browserReloadToken != reloadTokenBefore

            emitJSON([
                "ok": ok,
                "browserURL": store.browserURL?.absoluteString ?? "",
                "browserTitle": store.browserTitle,
                "browserCanGoBack": store.browserCanGoBack,
                "browserCanGoForward": store.browserCanGoForward,
                "reloadTokenChanged": store.browserReloadToken != reloadTokenBefore,
                "browserDataStatusText": store.browserDataStatusText,
                "source": "SessionStore.clearBrowserWebsiteData -> WKWebsiteDataStore.default.removeData"
            ])
            exit(ok ? 0 : 1)
        }

        CFRunLoopRun()
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
                "scope": "snapshot-request-only",
                "workspacePath": workspacePath,
                "browserURL": store.browserURL?.path ?? "",
                "status": store.browserScreenshotStatusText,
                "snapshotRequestID": request?.id.uuidString ?? "",
                "snapshotOutput": request?.outputURL.path ?? "",
                "snapshotFileExists": request.map { FileManager.default.fileExists(atPath: $0.outputURL.path) } ?? false
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runBrowserSnapshotInputSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexBrowserSnapshotInputSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexBrowserSnapshotInputCodexHome-\(UUID().uuidString)", isDirectory: true)
            var mockServer: MockResponsesServer?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                let docsURL = workspaceURL.appendingPathComponent("docs", isDirectory: true)
                try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)
                try """
                <!doctype html>
                <title>Raytone browser snapshot input</title>
                <h1>Raytone browser snapshot input</h1>
                """.write(to: docsURL.appendingPathComponent("browser-sample.html"), atomically: true, encoding: .utf8)

                mockServer = try startMockResponsesServer(message: "Raytone browser snapshot input OK")
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
                    store.projects[index].name = "BrowserSnapshotInputSmoke"
                }

                fputs("browser-snapshot-input-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                store.openBrowserSample()
                store.captureBrowserPanelScreenshot()
                guard let request = store.browserSnapshotRequest else {
                    throw NSError(
                        domain: "RaytoneCodexBrowserSnapshotInputSmoke",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "browser snapshot request was not created"]
                    )
                }

                let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
                guard let pngData = Data(base64Encoded: pngBase64) else {
                    throw NSError(
                        domain: "RaytoneCodexBrowserSnapshotInputSmoke",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "failed to decode smoke PNG"]
                    )
                }
                try fileManager.createDirectory(at: request.outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try pngData.write(to: request.outputURL)

                store.completeBrowserPanelScreenshot(request: request, result: .success(request.outputURL))
                let queuedImages = store.pendingLocalImagePaths
                let promptAfterSnapshot = store.prompt
                store.prompt = "\(promptAfterSnapshot)\n\n请回复：Raytone browser snapshot input OK"
                let turnInput = CodexAppServerClient.userInputItems(
                    prompt: store.prompt,
                    localImagePaths: store.pendingLocalImagePaths
                )

                fputs("browser-snapshot-input-smoke: runPrompt\n", stderr)
                await store.runPrompt()
                await waitForStoreToSettle(store)
                await store.stopAppServerForTesting()

                let agentMessages = store.selectedThread.items.compactMap { item -> String? in
                    if case let .agentMessage(text) = item.kind { return text }
                    return nil
                }
                let requestLog = (try? String(contentsOf: mockServer!.requestLogURL, encoding: .utf8)) ?? ""
                let canonicalSnapshotPath = SessionStore.canonicalPath(request.outputURL.path)
                let requestContainsSnapshot = requestLog.contains("input_image") ||
                    requestLog.contains("localImage") ||
                    requestLog.contains(request.outputURL.lastPathComponent)
                let ok = store.runtimeSnapshot.executable != nil &&
                    !store.isRunning &&
                    queuedImages == [canonicalSnapshotPath] &&
                    store.browserAttachedSnapshotPath == canonicalSnapshotPath &&
                    store.browserScreenshotStatusText.contains("已加入下次对话图片") &&
                    promptAfterSnapshot.contains("请参考这张浏览器截图") &&
                    store.lastLocalImageInputPreview == [canonicalSnapshotPath] &&
                    store.pendingLocalImagePaths.isEmpty &&
                    agentMessages.contains("Raytone browser snapshot input OK") &&
                    requestLog.contains("/v1/responses") &&
                    requestContainsSnapshot

                mockServer?.stop()
                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "browserURL": store.browserURL?.path ?? "",
                    "snapshotOutput": request.outputURL.path,
                    "browserScreenshotStatus": store.browserScreenshotStatusText,
                    "browserAttachedSnapshotPath": store.browserAttachedSnapshotPath,
                    "queuedImagesBeforePrompt": queuedImages,
                    "lastLocalImageInputPreview": store.lastLocalImageInputPreview,
                    "pendingLocalImageCount": store.pendingLocalImagePaths.count,
                    "turnInput": jsonObject(from: turnInput),
                    "requestContainsSnapshot": requestContainsSnapshot,
                    "agentMessages": agentMessages,
                    "mockRequestLogPreview": String(requestLog.prefix(1200)),
                    "source": "WKWebView snapshot PNG -> localImagePaths -> turn/start"
                ])
                exit(ok ? 0 : 1)
            } catch {
                mockServer?.stop()
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
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

    private static func runNewThreadPermissionsSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexNewThreadPermissionsSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let switchFirstURL = rootURL.appendingPathComponent("switch-first", isDirectory: true)
            let switchSecondURL = rootURL.appendingPathComponent("switch-second", isDirectory: true)
            let switchLogURL = rootURL.appendingPathComponent("switch-requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: switchFirstURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: switchSecondURL, withIntermediateDirectories: true)
                try "# New thread permissions smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try "first\n".write(
                    to: switchFirstURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try "second\n".write(
                    to: switchSecondURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try fakeThreadBootstrapActionsAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                let projectID = store.selectedProject.id
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.sandbox = .readOnly
                store.approval = .never
                store.approvalsReviewer = .user
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-new-thread-permissions"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_THREAD_BOOTSTRAP_ACTIONS_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == projectID }) {
                    store.projects[index].path = workspaceURL.path
                }

                store.newThread(in: projectID)
                let inheritedSandbox = store.selectedThread.sandbox
                let inheritedApproval = store.selectedThread.approval
                let inheritedReviewer = store.selectedThread.approvalsReviewer

                await store.startSelectedThreadCompaction()
                await waitForStoreToSettle(store)

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                let directNewThreadOK = inheritedSandbox == .readOnly &&
                    inheritedApproval == .never &&
                    inheritedReviewer == .user &&
                    store.selectedThread.appServerThreadID == "thread-bootstrap-1" &&
                    store.runtimeThreadSyncStatusText.hasPrefix("thread/compact/start") &&
                    logText.contains(#""method":"thread/start""#) &&
                    logText.contains(#""sandbox":"read-only""#) &&
                    logText.contains(#""approvalPolicy":"never""#) &&
                    logText.contains(#""approvalsReviewer":"user""#) &&
                    logText.contains(#""method":"thread/compact/start""#)

                await store.stopAppServerForTesting()

                let switchStore = SessionStore()
                let firstProject = Project(name: "第一个项目", path: switchFirstURL.path)
                let secondProject = Project(name: "第二个项目", path: switchSecondURL.path)
                switchStore.projects = [firstProject, secondProject]
                switchStore.threads = [
                    ChatThread(
                        title: "新对话",
                        projectID: firstProject.id,
                        items: [],
                        model: "stale-model",
                        sandbox: .dangerFullAccess,
                        approval: .onRequest,
                        approvalsReviewer: .autoReview,
                        personality: .pragmatic
                    )
                ]
                switchStore.selectedThreadID = switchStore.threads[0].id
                switchStore.workspacePath = firstProject.path
                switchStore.filePanelPath = firstProject.path
                switchStore.model = "raytone-current-model"
                switchStore.sandbox = .readOnly
                switchStore.approval = .never
                switchStore.approvalsReviewer = .user
                switchStore.personality = .friendly
                switchStore.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-new-thread-permissions"
                )
                switchStore.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_THREAD_BOOTSTRAP_ACTIONS_LOG": switchLogURL.path
                ]

                switchStore.selectProjectForNewThread(secondProject.id)
                let reusedThread = switchStore.selectedThread
                let reusedThreadOK = reusedThread.projectID == secondProject.id &&
                    reusedThread.model == "raytone-current-model" &&
                    reusedThread.sandbox == .readOnly &&
                    reusedThread.approval == .never &&
                    reusedThread.approvalsReviewer == .user &&
                    reusedThread.personality == .friendly &&
                    switchStore.workspacePath == secondProject.path &&
                    switchStore.filePanelPath == secondProject.path

                await switchStore.startSelectedThreadCompaction()
                await waitForStoreToSettle(switchStore)

                let switchLogText = (try? String(contentsOf: switchLogURL, encoding: .utf8)) ?? ""
                let reusedRuntimeOK = switchStore.selectedThread.appServerThreadID == "thread-bootstrap-1" &&
                    switchStore.runtimeThreadSyncStatusText.hasPrefix("thread/compact/start") &&
                    switchLogText.contains(#""method":"thread/start""#) &&
                    switchLogText.contains(#""cwd":"\#(secondProject.path)""#) &&
                    switchLogText.contains(#""model":"raytone-current-model""#) &&
                    switchLogText.contains(#""sandbox":"read-only""#) &&
                    switchLogText.contains(#""approvalPolicy":"never""#) &&
                    switchLogText.contains(#""approvalsReviewer":"user""#) &&
                    switchLogText.contains(#""personality":"friendly""#)

                await switchStore.stopAppServerForTesting()
                let ok = directNewThreadOK && reusedThreadOK && reusedRuntimeOK
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "projectSwitchRequestLog": switchLogURL.path,
                    "directNewThreadOK": directNewThreadOK,
                    "reusedThreadOK": reusedThreadOK,
                    "reusedRuntimeOK": reusedRuntimeOK,
                    "inheritedSandbox": inheritedSandbox.rawValue,
                    "inheritedApproval": inheritedApproval.rawValue,
                    "inheritedApprovalsReviewer": inheritedReviewer.rawValue,
                    "appServerThreadID": store.selectedThread.appServerThreadID ?? "",
                    "reusedThreadModel": reusedThread.model,
                    "reusedThreadSandbox": reusedThread.sandbox.rawValue,
                    "reusedThreadApproval": reusedThread.approval.rawValue,
                    "reusedThreadApprovalsReviewer": reusedThread.approvalsReviewer.rawValue,
                    "reusedThreadPersonality": reusedThread.personality.rawValue,
                    "reusedThreadWorkspacePath": switchStore.workspacePath,
                    "runtimeThreadSyncStatus": store.runtimeThreadSyncStatusText,
                    "projectSwitchRuntimeThreadSyncStatus": switchStore.runtimeThreadSyncStatusText,
                    "source": "newThread/selectProjectForNewThread -> SessionStore runtime inheritance -> thread/start",
                    "requestLogPreview": String(logText.prefix(1200)),
                    "projectSwitchRequestLogPreview": String(switchLogText.prefix(1800))
                ])
                try? fileManager.removeItem(at: rootURL)
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                try? fileManager.removeItem(at: rootURL)
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
            var mockServer: MockResponsesServer?
            do {
                try FileManager.default.createDirectory(at: codexHome, withIntermediateDirectories: true)
                mockServer = try startMockResponsesServer(
                    message: "Raytone thread management smoke OK",
                    indexedResponses: true
                )
                try writeMockCodexConfig(codexHome: codexHome, baseURL: mockServer!.baseURL)
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

                let storeSmoke = await runStoreThreadManagementSmoke(
                    workspacePath: workspacePath,
                    codexHome: codexHome
                )

                let ok = !thread.id.isEmpty &&
                    !forked.id.isEmpty &&
                    thread.id != forked.id &&
                    storeSmoke.ok
                mockServer?.stop()
                var payload: [String: Any] = [
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
                ]
                payload.merge(storeSmoke.payload) { _, new in new }
                emitJSON(payload)
                exit(ok ? 0 : 1)
            } catch {
                mockServer?.stop()
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

    private static func runThreadLifecycleSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadLifecycleSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try "# Thread lifecycle smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try fakeThreadLifecycleAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-thread-lifecycle"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_THREAD_LIFECYCLE_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "ThreadLifecycleSmoke"
                }

                store.prompt = "触发线程生命周期通知"
                await store.runPrompt()
                let deadline = Date().addingTimeInterval(8)
                while Date() < deadline,
                      !store.runtimeThreadSyncStatusText.contains("thread/closed") {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }

                let serverID = store.threads.first { $0.appServerThreadID == "thread-life" }?.appServerThreadID ?? ""
                let titleAfterNotification = store.threads.first { $0.appServerThreadID == "thread-life" }?.title ?? ""
                let compactNoticeObserved = store.threads
                    .first { $0.appServerThreadID == "thread-life" }?
                    .items
                    .contains { item in
                        if case let .notice(notice) = item.kind {
                            return notice.text.contains("turn-life")
                        }
                        return false
                    } ?? false
                let closedStatus = store.runtimeThreadSyncStatusText
                let loadedAfterClosed = store.loadedRuntimeThreadIDs

                await store.archiveRuntimeThread(
                    id: "thread-life",
                    title: titleAfterNotification,
                    preview: "生命周期 smoke",
                    cwd: workspaceURL.path
                )
                let archiveDeadline = Date().addingTimeInterval(8)
                while Date() < archiveDeadline,
                      store.threads.contains(where: { $0.appServerThreadID == "thread-life" }) {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let archivedContainsThread = store.archivedRuntimeThreads.contains { $0.id == "thread-life" }
                let localRemovedAfterArchive = !store.threads.contains { $0.appServerThreadID == "thread-life" }
                let archiveStatus = store.runtimeCatalogStatusText

                if let archived = store.archivedRuntimeThreads.first(where: { $0.id == "thread-life" }) {
                    await store.unarchiveRuntimeThread(archived)
                }
                let unarchiveDeadline = Date().addingTimeInterval(8)
                while Date() < unarchiveDeadline,
                      !store.threads.contains(where: { $0.appServerThreadID == "thread-life" }) {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let unarchiveStatus = store.runtimeCatalogStatusText
                let localRestoredAfterUnarchive = store.threads.contains { $0.appServerThreadID == "thread-life" }
                let removedFromArchived = !store.archivedRuntimeThreads.contains { $0.id == "thread-life" }
                let restoredTitle = store.threads.first { $0.appServerThreadID == "thread-life" }?.title ?? ""
                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let ok = serverID == "thread-life" &&
                    titleAfterNotification == "远端生命周期重命名" &&
                    compactNoticeObserved &&
                    closedStatus.contains("thread/closed") &&
                    !loadedAfterClosed.contains("thread-life") &&
                    archivedContainsThread &&
                    localRemovedAfterArchive &&
                    archiveStatus.contains("thread/archive") &&
                    localRestoredAfterUnarchive &&
                    removedFromArchived &&
                    restoredTitle == "远端生命周期重命名" &&
                    unarchiveStatus.contains("thread/unarchive") &&
                    logText.contains(#""method":"thread/started""#) &&
                    logText.contains(#""method":"thread/status/changed""#) &&
                    logText.contains(#""method":"thread/name/updated""#) &&
                    logText.contains(#""method":"thread/compacted""#) &&
                    logText.contains(#""method":"thread/closed""#) &&
                    logText.contains(#""method":"thread/archived""#) &&
                    logText.contains(#""method":"thread/unarchived""#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "serverID": serverID,
                    "titleAfterNotification": titleAfterNotification,
                    "compactNoticeObserved": compactNoticeObserved,
                    "closedStatus": closedStatus,
                    "loadedAfterClosed": loadedAfterClosed,
                    "archivedContainsThread": archivedContainsThread,
                    "localRemovedAfterArchive": localRemovedAfterArchive,
                    "archiveStatus": archiveStatus,
                    "localRestoredAfterUnarchive": localRestoredAfterUnarchive,
                    "removedFromArchived": removedFromArchived,
                    "restoredTitle": restoredTitle,
                    "unarchiveStatus": unarchiveStatus,
                    "threadTitles": store.threads.map(\.title),
                    "archivedThreadIDs": store.archivedRuntimeThreads.map(\.id),
                    "requestLogPreview": String(logText.prefix(2600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runThreadBootstrapActionsSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadBootstrapActionsSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try "# Thread bootstrap actions smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try fakeThreadBootstrapActionsAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-thread-bootstrap-actions"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_THREAD_BOOTSTRAP_ACTIONS_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "ThreadBootstrapActionsSmoke"
                }

                let compactInitialHadNoThreadID = store.selectedThread.appServerThreadID == nil
                await store.startSelectedThreadCompaction()
                await waitForStoreToSettle(store)
                let compactThreadID = store.selectedThread.appServerThreadID ?? ""
                let compactStatus = store.runtimeThreadSyncStatusText

                let projectID = store.selectedThread.projectID
                store.newThread(in: projectID)
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                let rollbackInitialHadNoThreadID = store.selectedThread.appServerThreadID == nil
                await store.rollbackSelectedThreadLastTurn(confirm: false)
                await waitForStoreToSettle(store)
                let rollbackThreadID = store.selectedThread.appServerThreadID ?? ""
                let rollbackStatus = store.runtimeThreadSyncStatusText
                let rollbackTranscript = store.selectedThread.items.compactMap { item -> String? in
                    switch item.kind {
                    case let .userMessage(text), let .agentMessage(text):
                        return text
                    default:
                        return nil
                    }
                }.joined(separator: "\n")

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let threadStartCount = logText.components(separatedBy: #""method":"thread/start""#).count - 1
                let ok = compactInitialHadNoThreadID &&
                    rollbackInitialHadNoThreadID &&
                    compactThreadID == "thread-bootstrap-1" &&
                    rollbackThreadID == "thread-bootstrap-2" &&
                    compactStatus.hasPrefix("thread/compact/start") &&
                    rollbackStatus.hasPrefix("thread/rollback") &&
                    rollbackTranscript.contains("rollback restored user") &&
                    rollbackTranscript.contains("rollback restored agent") &&
                    threadStartCount >= 2 &&
                    logText.contains(#""method":"thread/compact/start""#) &&
                    logText.contains(#""method":"thread/rollback""#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "compactInitialHadNoThreadID": compactInitialHadNoThreadID,
                    "compactThreadID": compactThreadID,
                    "compactStatus": compactStatus,
                    "rollbackInitialHadNoThreadID": rollbackInitialHadNoThreadID,
                    "rollbackThreadID": rollbackThreadID,
                    "rollbackStatus": rollbackStatus,
                    "rollbackTranscript": rollbackTranscript,
                    "threadStartCount": threadStartCount,
                    "requestLogPreview": String(logText.prefix(2600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    @MainActor
    private static func runStoreThreadManagementSmoke(
        workspacePath: String,
        codexHome: URL
    ) async -> StoreThreadManagementSmokeResult {
        let store = SessionStore()
        store.workspacePath = workspacePath
        store.filePanelPath = workspacePath
        store.model = "mock-model"
        store.sandbox = .readOnly
        store.approval = .never
        store.appServerEnvironmentOverridesForTesting = [
            "CODEX_HOME": codexHome.path
        ]
        if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
            store.projects[index].path = workspacePath
        }

        await store.refreshRuntime()
        let originalLocalID = store.selectedThreadID
        store.prompt = "请回复：Raytone thread management smoke OK"
        await store.runPrompt()
        await waitForStoreToSettle(store)
        _ = await waitForAgentMessageCount(
            in: store,
            containing: "Raytone thread management smoke OK",
            atLeast: 1
        )
        let originalServerID = await waitForThreadServerID(in: store, localThreadID: originalLocalID)
        let renamed = "Raytone store thread \(UUID().uuidString.prefix(8))"
        let renameAccepted = await store.renameSelectedThread(to: renamed)
        await store.refreshRuntimeThreads(searchTerm: renamed, limit: 20)
        let runtimeRenamed = store.threads.contains { thread in
            thread.appServerThreadID == originalServerID && thread.title == renamed
        }

        if let original = store.threads.first(where: { $0.id == originalLocalID }) {
            store.selectThread(original)
        }
        store.duplicateSelectedThread()
        let forkLocalID = store.selectedThreadID
        let forkServerID = await waitForThreadServerID(in: store, localThreadID: forkLocalID)
        if !forkServerID.isEmpty,
           let fork = store.threads.first(where: { $0.id == forkLocalID }) {
            store.selectThread(fork)
            store.prompt = "请回复：Raytone thread management smoke OK"
            await store.runPrompt()
            await waitForStoreToSettle(store)

            let firstAgentCount = await waitForAgentMessageCount(
                in: store,
                containing: "Raytone thread management smoke OK",
                atLeast: 1
            )
            let rollbackPromptMarker = "Raytone rollback marker \(UUID().uuidString.prefix(8))"
            store.prompt = "这轮稍后会被回滚：\(rollbackPromptMarker)"
            await store.runPrompt()
            await waitForStoreToSettle(store)
            _ = await waitForAgentMessageCount(
                in: store,
                containing: "Raytone thread management smoke OK",
                atLeast: max(2, firstAgentCount + 1)
            )
        }
        let forkPromptPersistedBeforeRollback = store.selectedThread.items.contains { item in
            if case let .agentMessage(text) = item.kind {
                return text.contains("Raytone thread management smoke OK")
            }
            return false
        }
        let rollbackUserMessagesBefore = store.selectedThread.items.compactMap { item -> String? in
            if case let .userMessage(text) = item.kind { return text }
            return nil
        }
        let rollbackMarker = rollbackUserMessagesBefore.last ?? ""
        let rollbackItemCountBefore = store.selectedThread.items.count
        if !forkServerID.isEmpty {
            await store.rollbackSelectedThreadLastTurn(confirm: false)
        }
        let rollbackStatus = store.runtimeThreadSyncStatusText
        let rollbackItemCountAfter = store.selectedThread.items.count
        let rollbackRemovedLastTurn = !rollbackMarker.isEmpty &&
            rollbackUserMessagesBefore.contains(rollbackMarker) &&
            !store.selectedThread.items.contains { item in
                if case let .userMessage(text) = item.kind {
                    return text == rollbackMarker
                }
                return false
            }
        let forkPromptPersisted = store.selectedThread.items.contains { item in
            if case let .agentMessage(text) = item.kind {
                return text.contains("Raytone thread management smoke OK")
            }
            return false
        }
        if !forkServerID.isEmpty {
            await store.startSelectedThreadCompaction()
            await waitForStoreToSettle(store)
        }
        let compactStatus = store.runtimeThreadSyncStatusText
        let compactSubmitted = compactStatus.hasPrefix("thread/compact/start")

        if !forkServerID.isEmpty {
            store.deleteThread(forkLocalID)
            _ = await waitForCatalogStatus(in: store, containing: "thread/archive", timeout: 8)
            await store.refreshArchivedThreads()
        }

        let forkArchived = !forkServerID.isEmpty &&
            store.archivedRuntimeThreads.contains { $0.id == forkServerID && $0.archived }
        let archiveStatus = store.runtimeCatalogStatusText
        let archivedForkSummary = store.archivedRuntimeThreads.first { $0.id == forkServerID }
        if let archivedForkSummary {
            await store.unarchiveRuntimeThread(archivedForkSummary)
        }
        let unarchiveStatus = store.runtimeCatalogStatusText
        let forkUnarchived = !forkServerID.isEmpty &&
            store.threads.contains { $0.appServerThreadID == forkServerID }
        let forkRemovedFromArchive = !forkServerID.isEmpty &&
            !store.archivedRuntimeThreads.contains { $0.id == forkServerID }
        await store.stopAppServerForTesting()

        let ok = !originalServerID.isEmpty &&
            renameAccepted &&
            runtimeRenamed &&
            !forkServerID.isEmpty &&
            forkServerID != originalServerID &&
            forkPromptPersistedBeforeRollback &&
            forkPromptPersisted &&
            rollbackStatus.hasPrefix("thread/rollback") &&
            rollbackItemCountAfter < rollbackItemCountBefore &&
            rollbackRemovedLastTurn &&
            compactSubmitted &&
            forkArchived &&
            forkUnarchived &&
            forkRemovedFromArchive &&
            unarchiveStatus.hasPrefix("thread/unarchive")

        return StoreThreadManagementSmokeResult(
            ok: ok,
            originalLocalID: originalLocalID.uuidString,
            originalServerID: originalServerID,
            renamed: renamed,
            renameAccepted: renameAccepted,
            runtimeRenamed: runtimeRenamed,
            forkLocalID: forkLocalID.uuidString,
            forkServerID: forkServerID,
            forkPromptPersisted: forkPromptPersisted,
            rollbackStatus: rollbackStatus,
            rollbackItemCountBefore: rollbackItemCountBefore,
            rollbackItemCountAfter: rollbackItemCountAfter,
            rollbackRemovedLastTurn: rollbackRemovedLastTurn,
            compactStatus: compactStatus,
            compactSubmitted: compactSubmitted,
            forkArchived: forkArchived,
            forkUnarchived: forkUnarchived,
            forkRemovedFromArchive: forkRemovedFromArchive,
            archiveStatus: archiveStatus,
            unarchiveStatus: unarchiveStatus,
            archivedCount: store.archivedRuntimeThreads.count
        )
    }

    @MainActor
    private static func waitForThreadServerID(in store: SessionStore, localThreadID: UUID, timeout: TimeInterval = 8) async -> String {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let thread = store.threads.first(where: { $0.id == localThreadID }),
               let serverID = thread.appServerThreadID,
               !serverID.isEmpty {
                return serverID
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return store.threads.first(where: { $0.id == localThreadID })?.appServerThreadID ?? ""
    }

    @MainActor
    private static func waitForCatalogStatus(in store: SessionStore, containing needle: String, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if store.runtimeCatalogStatusText.contains(needle) {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return store.runtimeCatalogStatusText.contains(needle)
    }

    @MainActor
    private static func waitForCollaborationModeUpdate(
        in store: SessionStore,
        expectedKind: String,
        timeout: TimeInterval = 8
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if store.selectedCollaborationModeKind == expectedKind,
               store.runtimeCollaborationModeStatusText.contains("thread/settings/updated") {
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    @MainActor
    private static func waitForAgentMessageCount(
        in store: SessionStore,
        containing needle: String,
        atLeast expectedCount: Int,
        timeout: TimeInterval = 20
    ) async -> Int {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let count = agentMessageCount(in: store, containing: needle)
            if count >= expectedCount {
                return count
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return agentMessageCount(in: store, containing: needle)
    }

    @MainActor
    private static func agentMessageCount(in store: SessionStore, containing needle: String) -> Int {
        store.selectedThread.items.reduce(0) { count, item in
            if case let .agentMessage(text) = item.kind, text.contains(needle) {
                return count + 1
            }
            return count
        }
    }

    @MainActor
    private static func waitForMCPElicitation(in store: SessionStore, timeout: TimeInterval = 8) async -> UUID? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let item = store.selectedThread.items.first(where: { item in
                if case .mcpElicitation = item.kind {
                    return true
                }
                return false
            }) {
                return item.id
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return nil
    }

    @MainActor
    private static func waitForToolUserInput(in store: SessionStore, timeout: TimeInterval = 8) async -> UUID? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let item = store.selectedThread.items.first(where: { item in
                if case .toolUserInput = item.kind {
                    return true
                }
                return false
            }) {
                return item.id
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return nil
    }

    @MainActor
    private static func waitForPendingApproval(
        in store: SessionStore,
        title: String,
        timeout: TimeInterval = 8
    ) async -> UUID? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let item = store.selectedThread.items.first(where: { item in
                if case let .approval(request) = item.kind,
                   request.title == title,
                   request.decision == .pending {
                    return true
                }
                return false
            }) {
                return item.id
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return nil
    }

    @MainActor
    private static func waitForGuardianDeniedAction(
        in store: SessionStore,
        timeout: TimeInterval = 8
    ) async -> GuardianDeniedAction? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let action = store.recentGuardianDeniedActions.first {
                return action
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return store.recentGuardianDeniedActions.first
    }

    private struct StoreThreadManagementSmokeResult: Sendable {
        let ok: Bool
        let originalLocalID: String
        let originalServerID: String
        let renamed: String
        let renameAccepted: Bool
        let runtimeRenamed: Bool
        let forkLocalID: String
        let forkServerID: String
        let forkPromptPersisted: Bool
        let rollbackStatus: String
        let rollbackItemCountBefore: Int
        let rollbackItemCountAfter: Int
        let rollbackRemovedLastTurn: Bool
        let compactStatus: String
        let compactSubmitted: Bool
        let forkArchived: Bool
        let forkUnarchived: Bool
        let forkRemovedFromArchive: Bool
        let archiveStatus: String
        let unarchiveStatus: String
        let archivedCount: Int

        var payload: [String: Any] {
            [
                "storeThreadManagement": [
                    "ok": ok,
                    "originalLocalID": originalLocalID,
                    "originalServerID": originalServerID,
                    "renamed": renamed,
                    "renameAccepted": renameAccepted,
                    "runtimeRenamed": runtimeRenamed,
                    "forkLocalID": forkLocalID,
                    "forkServerID": forkServerID,
                    "forkPromptPersisted": forkPromptPersisted,
                    "rollbackStatus": rollbackStatus,
                    "rollbackItemCountBefore": rollbackItemCountBefore,
                    "rollbackItemCountAfter": rollbackItemCountAfter,
                    "rollbackRemovedLastTurn": rollbackRemovedLastTurn,
                    "compactStatus": compactStatus,
                    "compactSubmitted": compactSubmitted,
                    "forkArchived": forkArchived,
                    "forkUnarchived": forkUnarchived,
                    "forkRemovedFromArchive": forkRemovedFromArchive,
                    "archiveStatus": archiveStatus,
                    "unarchiveStatus": unarchiveStatus,
                    "archivedCount": archivedCount
                ] as [String: Any]
            ]
        }
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
            let historySearchStatus = reloaded.runtimeThreadSyncStatusText
            let historySearchSnippet = reloaded.runtimeThreadSearchSnippets[createdThreadID] ??
                reloaded.runtimeThreadSearchSnippets.values.first(where: { $0.contains(marker) }) ??
                ""

            let historyThread = reloaded.threads.first { thread in
                thread.appServerThreadID == createdThreadID ||
                    thread.title.localizedCaseInsensitiveContains(marker) ||
                    thread.preview.localizedCaseInsensitiveContains(marker) ||
                    (thread.appServerThreadID.flatMap { reloaded.runtimeThreadSearchSnippets[$0] } ?? "")
                        .localizedCaseInsensitiveContains(marker)
            }
            if let historyThread {
                reloaded.selectThread(historyThread)
                await reloaded.loadRuntimeThreadTranscript(localThreadID: historyThread.id)
            }
            let historyTranscriptStatus = reloaded.runtimeThreadSyncStatusText

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
                historySearchStatus.hasPrefix("thread/search") &&
                historySearchSnippet.localizedCaseInsensitiveContains(marker) &&
                historyTranscriptStatus.hasPrefix("thread/turns/list") &&
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
                "historySyncStatus": historySearchStatus,
                "historyTranscriptStatus": historyTranscriptStatus,
                "historySearchSnippet": historySearchSnippet,
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

    private static func runLoadedThreadsSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexLoadedThreadsSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexLoadedThreadsCodexHome-\(UUID().uuidString)", isDirectory: true)
            let marker = "Raytone loaded threads smoke OK \(UUID().uuidString.prefix(8))"
            let prompt = "Reply exactly: \(marker)"
            var mockServer: MockResponsesServer?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try "loaded-threads-smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )

                mockServer = try startMockResponsesServer(message: marker)
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
                    store.projects[index].name = "LoadedThreadsSmoke"
                }

                await store.refreshRuntime()
                store.prompt = prompt
                await store.runPrompt()
                await waitForStoreToSettle(store)

                let appServerThreadID = store.selectedThread.appServerThreadID ?? ""
                await store.refreshLoadedRuntimeThreads()
                let loadedIDs = store.loadedRuntimeThreadIDs
                let loadedStatus = store.runtimeLoadedThreadsStatusText
                let selectedThreadLoaded = !appServerThreadID.isEmpty && loadedIDs.contains(appServerThreadID)
                let sourceFacts = store.environmentSourceFacts.map { fact in
                    [
                        "title": fact.title,
                        "source": fact.source,
                        "detail": fact.detail,
                        "active": fact.active
                    ] as [String: Any]
                }
                let threadSourceFactActive = store.environmentSourceFacts.contains { fact in
                    fact.source == "thread/loaded/list" && fact.active
                }
                let agentMessages = store.selectedThread.items.compactMap { item -> String? in
                    if case let .agentMessage(text) = item.kind { return text }
                    return nil
                }
                let commands = store.selectedThread.items.compactMap { item -> CommandRun? in
                    if case let .command(run) = item.kind { return run }
                    return nil
                }
                let usedExecFallback = commands.contains { run in
                    run.command.contains(" codex exec ") || run.command.contains("/codex exec ")
                }
                let requestLog = (try? String(contentsOf: mockServer!.requestLogURL, encoding: .utf8)) ?? ""

                await store.stopAppServerForTesting()
                mockServer?.stop()

                let ok = store.runtimeSnapshot.executable != nil &&
                    !store.isRunning &&
                    !usedExecFallback &&
                    agentMessages.contains(marker) &&
                    selectedThreadLoaded &&
                    loadedStatus.hasPrefix("thread/loaded/list：") &&
                    threadSourceFactActive &&
                    requestLog.contains("/v1/responses")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "appServerThreadID": appServerThreadID,
                    "loadedRuntimeThreadIDs": loadedIDs,
                    "selectedThreadLoaded": selectedThreadLoaded,
                    "loadedStatus": loadedStatus,
                    "threadSourceFactActive": threadSourceFactActive,
                    "environmentSourceFacts": sourceFacts,
                    "usedExecFallback": usedExecFallback,
                    "agentMessages": agentMessages,
                    "mockRequestLogPreview": String(requestLog.prefix(1200)),
                    "source": "thread/loaded/list"
                ])
                exit(ok ? 0 : 1)
            } catch {
                mockServer?.stop()
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runThreadUnsubscribeSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadUnsubscribeSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadUnsubscribeCodexHome-\(UUID().uuidString)", isDirectory: true)
            var mockServer: MockResponsesServer?
            var client: CodexAppServerClient?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try "thread unsubscribe smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )

                mockServer = try startMockResponsesServer(message: "Raytone thread unsubscribe smoke")
                try writeMockCodexConfig(codexHome: codexHomeURL, baseURL: mockServer!.baseURL)

                let runtime = await CodexCLIService().inspectRuntime()
                guard let executable = runtime.executable else {
                    emitJSON([
                        "ok": false,
                        "runtimeSource": "none",
                        "runtimePath": "",
                        "runtimeVersion": runtime.version ?? "",
                        "workspacePath": workspaceURL.path,
                        "codexHomePath": codexHomeURL.path,
                        "error": runtime.errorDescription ?? "Codex CLI executable was not found."
                    ])
                    mockServer?.stop()
                    exit(1)
                }

                let appServerClient = CodexAppServerClient(
                    executable: executable,
                    workspaceURL: workspaceURL,
                    environmentOverrides: ["CODEX_HOME": codexHomeURL.path]
                )
                client = appServerClient
                try await appServerClient.initialize()
                let options = CodexAppServerOptions(
                    workspaceURL: workspaceURL,
                    model: "mock-model",
                    sandbox: .readOnly,
                    approvalPolicy: .never
                )
                let thread = try await appServerClient.startThread(options: options)
                let loadedBefore = try await appServerClient.listLoadedThreads(limit: 20)
                let firstStatus = try await appServerClient.unsubscribeThread(id: thread.id)
                let loadedAfterFirst = try await appServerClient.listLoadedThreads(limit: 20)
                let secondStatus = try await appServerClient.unsubscribeThread(id: thread.id)

                await appServerClient.stop()
                mockServer?.stop()

                let ok = loadedBefore.threadIDs.contains(thread.id) &&
                    firstStatus == .unsubscribed &&
                    secondStatus == .notSubscribed

                emitJSON([
                    "ok": ok,
                    "runtimeSource": executable.source.rawValue,
                    "runtimePath": executable.url.path,
                    "runtimeVersion": runtime.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "appServerThreadID": thread.id,
                    "loadedBefore": loadedBefore.threadIDs,
                    "loadedAfterFirst": loadedAfterFirst.threadIDs,
                    "firstUnsubscribeStatus": firstStatus.rawValue,
                    "secondUnsubscribeStatus": secondStatus.rawValue,
                    "source": "thread/unsubscribe"
                ])
                exit(ok ? 0 : 1)
            } catch {
                if let client {
                    await client.stop()
                }
                mockServer?.stop()
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runThreadMetadataSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadMetadataSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadMetadataCodexHome-\(UUID().uuidString)", isDirectory: true)
            let marker = "Raytone thread metadata smoke OK \(UUID().uuidString.prefix(8))"
            let prompt = "Reply exactly: \(marker)"
            var mockServer: MockResponsesServer?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try "thread metadata smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                _ = try runProcess(["git", "init", "-b", "main"], cwd: workspaceURL)
                _ = try runProcess(["git", "config", "user.email", "raytone@example.invalid"], cwd: workspaceURL)
                _ = try runProcess(["git", "config", "user.name", "Raytone Smoke"], cwd: workspaceURL)
                _ = try runProcess(["git", "remote", "add", "origin", "https://example.invalid/raytone-smoke.git"], cwd: workspaceURL)
                _ = try runProcess(["git", "add", "README.md"], cwd: workspaceURL)
                _ = try runProcess(["git", "commit", "-m", "Initial smoke commit"], cwd: workspaceURL)
                let expectedSHA = try runProcess(["git", "rev-parse", "HEAD"], cwd: workspaceURL)
                    .output
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                mockServer = try startMockResponsesServer(message: marker)
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
                    store.projects[index].name = "ThreadMetadataSmoke"
                }

                await store.refreshRuntime()
                store.prompt = prompt
                await store.runPrompt()
                await waitForStoreToSettle(store)

                let appServerThreadID = store.selectedThread.appServerThreadID ?? ""
                await store.syncSelectedThreadGitMetadata()
                let metadataStatus = store.runtimeThreadMetadataStatusText
                await store.refreshRuntimeThreads(searchTerm: marker, limit: 10)
                let syncedRuntimeThread = store.threads.first { thread in
                    thread.appServerThreadID == appServerThreadID
                }
                let sourceFacts = store.environmentSourceFacts.map { fact in
                    [
                        "title": fact.title,
                        "source": fact.source,
                        "detail": fact.detail,
                        "active": fact.active
                    ] as [String: Any]
                }
                let metadataSourceFactActive = store.environmentSourceFacts.contains { fact in
                    fact.source == "thread/metadata/update" && fact.active
                }
                let agentMessages = store.selectedThread.items.compactMap { item -> String? in
                    if case let .agentMessage(text) = item.kind { return text }
                    return nil
                }
                let commands = store.selectedThread.items.compactMap { item -> CommandRun? in
                    if case let .command(run) = item.kind { return run }
                    return nil
                }
                let usedExecFallback = commands.contains { run in
                    run.command.contains(" codex exec ") || run.command.contains("/codex exec ")
                }
                let requestLog = (try? String(contentsOf: mockServer!.requestLogURL, encoding: .utf8)) ?? ""

                await store.stopAppServerForTesting()
                mockServer?.stop()

                let ok = store.runtimeSnapshot.executable != nil &&
                    !store.isRunning &&
                    !usedExecFallback &&
                    !appServerThreadID.isEmpty &&
                    agentMessages.contains(marker) &&
                    metadataStatus.contains("thread/metadata/update") &&
                    metadataStatus.contains("main") &&
                    metadataStatus.contains(String(expectedSHA.prefix(12))) &&
                    metadataSourceFactActive &&
                    syncedRuntimeThread?.appServerThreadID == appServerThreadID &&
                    requestLog.contains("/v1/responses")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "appServerThreadID": appServerThreadID,
                    "expectedBranch": "main",
                    "expectedSHA": expectedSHA,
                    "metadataStatus": metadataStatus,
                    "metadataSourceFactActive": metadataSourceFactActive,
                    "environmentSourceFacts": sourceFacts,
                    "usedExecFallback": usedExecFallback,
                    "agentMessages": agentMessages,
                    "mockRequestLogPreview": String(requestLog.prefix(1200)),
                    "source": "thread/metadata/update"
                ])
                exit(ok ? 0 : 1)
            } catch {
                mockServer?.stop()
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runThreadShellCommandSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadShellSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexThreadShellCodexHome-\(UUID().uuidString)", isDirectory: true)
            let marker = "Raytone thread shell smoke OK \(UUID().uuidString.prefix(8))"
            var mockServer: MockResponsesServer?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try "thread shell smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )

                mockServer = try startMockResponsesServer(message: "unused")
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
                    store.projects[index].name = "ThreadShellSmoke"
                }

                await store.refreshRuntime()
                store.terminalCommand = "printf '\(marker)\\n'"
                await store.runThreadShellCommandFromTerminal()

                let deadline = Date().addingTimeInterval(15)
                while Date() < deadline {
                    let hasOutput = commandRuns(in: store.selectedThread.items).contains { run in
                        run.command.contains(marker) || run.output.contains(marker)
                    }
                    if hasOutput && !store.isRunning {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }

                let commandRuns = commandRuns(in: store.selectedThread.items)
                let matchingRun = commandRuns.first { run in
                    run.command.contains(marker) || run.output.contains(marker)
                }
                let sourceFacts = store.environmentSourceFacts.map { fact in
                    [
                        "title": fact.title,
                        "source": fact.source,
                        "detail": fact.detail,
                        "active": fact.active
                    ] as [String: Any]
                }
                let threadShellSourceFactActive = store.environmentSourceFacts.contains { fact in
                    fact.source == "thread/shellCommand" && fact.active
                }

                await store.stopAppServerForTesting()
                mockServer?.stop()

                let ok = store.runtimeSnapshot.executable != nil &&
                    store.selectedThread.appServerThreadID?.isEmpty == false &&
                    matchingRun?.output.contains(marker) == true &&
                    matchingRun?.exitCode == 0 &&
                    store.threadShellCommandStatusText.hasPrefix("thread/shellCommand") &&
                    threadShellSourceFactActive &&
                    store.terminalRuns.isEmpty

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "appServerThreadID": store.selectedThread.appServerThreadID ?? "",
                    "threadShellStatus": store.threadShellCommandStatusText,
                    "threadShellSourceFactActive": threadShellSourceFactActive,
                    "terminalRunCount": store.terminalRuns.count,
                    "commandRuns": commandRuns.map { run in
                        [
                            "command": run.command,
                            "output": run.output,
                            "exitCode": run.exitCode.map { Int($0) as Any } ?? NSNull()
                        ] as [String: Any]
                    },
                    "environmentSourceFacts": sourceFacts,
                    "source": "thread/shellCommand"
                ])
                exit(ok ? 0 : 1)
            } catch {
                mockServer?.stop()
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
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

    private static func runSideChatInjectionSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexSideChatInjectionSmoke-\(UUID().uuidString)", isDirectory: true)
            let codexHomeURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexSideChatInjectionCodexHome-\(UUID().uuidString)", isDirectory: true)
            let injectedMarker = "Raytone injected side context \(UUID().uuidString.prefix(8))"
            let turnMarker = "Raytone side injection reply \(UUID().uuidString.prefix(8))"
            let injectedContext = "请在下一轮记住这个侧边上下文：\(injectedMarker)"
            let turnPrompt = "Reply exactly: \(turnMarker)"
            var mockServer: MockResponsesServer?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try "side chat injection smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )

                mockServer = try startMockResponsesServer(message: turnMarker)
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
                    store.projects[index].name = "SideChatInjectionSmoke"
                }

                await store.refreshRuntime()
                store.sideChatDraft = injectedContext
                await store.injectSideChatContext()

                let injectionStatus = store.sideChatStatusText
                let itemsAfterInjection = store.selectedThread.items
                let sourceFactsAfterInjection = store.environmentSourceFacts
                let injectionSourceFactActive = sourceFactsAfterInjection.contains { fact in
                    fact.source == "thread/inject_items" && fact.active
                }

                store.prompt = turnPrompt
                await store.runPrompt()

                let deadline = Date().addingTimeInterval(30)
                while store.isRunning && Date() < deadline {
                    try? await Task.sleep(nanoseconds: 100_000_000)
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
                let notices = items.compactMap { item -> String? in
                    if case let .notice(notice) = item.kind { return notice.text }
                    return nil
                }
                let commands = items.compactMap { item -> CommandRun? in
                    if case let .command(run) = item.kind { return run }
                    return nil
                }
                let usedExecFallback = commands.contains { run in
                    run.command.contains(" codex exec ") || run.command.contains("/codex exec ")
                }
                let requestLog = (try? String(contentsOf: mockServer!.requestLogURL, encoding: .utf8)) ?? ""
                let appServerThreadID = store.selectedThread.appServerThreadID ?? ""

                await store.stopAppServerForTesting()
                mockServer?.stop()

                let ok = !appServerThreadID.isEmpty &&
                    !store.isRunning &&
                    !usedExecFallback &&
                    injectionStatus.hasPrefix("thread/inject_items") &&
                    itemsAfterInjection.count == 1 &&
                    injectionSourceFactActive &&
                    userMessages == [turnPrompt] &&
                    agentMessages == [turnMarker] &&
                    notices.contains { $0.contains("thread/inject_items") } &&
                    requestLog.contains(injectedMarker) &&
                    requestLog.contains(turnPrompt) &&
                    requestLog.contains("/v1/responses")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "appServerThreadID": appServerThreadID,
                    "injectedMarker": injectedMarker,
                    "turnMarker": turnMarker,
                    "injectionStatus": injectionStatus,
                    "injectionSourceFactActive": injectionSourceFactActive,
                    "itemsAfterInjection": itemsAfterInjection.count,
                    "usedExecFallback": usedExecFallback,
                    "userMessages": userMessages,
                    "agentMessages": agentMessages,
                    "notices": notices,
                    "requestContainsInjectedContext": requestLog.contains(injectedMarker),
                    "requestContainsTurnPrompt": requestLog.contains(turnPrompt),
                    "mockRequestLogPreview": String(requestLog.prefix(1600)),
                    "source": "thread/inject_items"
                ])
                exit(ok ? 0 : 1)
            } catch {
                mockServer?.stop()
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "codexHomePath": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runEnvironmentSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.filePanelPath = workspacePath

            await store.refreshRuntime()
            await store.loadFilePanelDirectory(workspacePath, updateWatch: false)
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
            let environmentSourceFacts = store.environmentSourceFacts
            let sourceFactsPayload = environmentSourceFacts.map { fact in
                [
                    "title": fact.title,
                    "source": fact.source,
                    "detail": fact.detail,
                    "active": fact.active
                ] as [String: Any]
            }
            let activeSourceTitles = Set(environmentSourceFacts.filter(\.active).map(\.title))

            let gitDataAvailable = store.workspaceGitDiff != nil || !fallbackGitStatus.isEmpty
            let pullRequestStatusAvailable = !pullRequestStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                pullRequestStatus != "未刷新" &&
                pullRequestStatus != "正在读取 PR 状态…"
            let terminalPreflightOk = terminalRun?.exitCode == 0 &&
                terminalOutput.contains("== Git 状态 ==") &&
                terminalOutput.contains("== 安全建议 ==")
            let sourceEvidenceOk = activeSourceTitles.contains("文件") &&
                activeSourceTitles.contains("变更") &&
                activeSourceTitles.contains("终端") &&
                environmentSourceFacts.contains {
                    $0.title == "文件" &&
                        $0.source.contains("fs/readDirectory") &&
                        !$0.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                } &&
                environmentSourceFacts.contains {
                    $0.title == "变更" &&
                        ($0.source.contains("command/exec") ||
                         $0.source.contains("turn/diff/updated")) &&
                        !$0.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                } &&
                environmentSourceFacts.contains {
                    $0.title == "终端" &&
                        $0.source == "command/exec" &&
                        !$0.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            let ok = store.runtimeSnapshot.executable != nil &&
                !branchStatus.hasPrefix("分支读取失败") &&
                !gitStatus.hasPrefix("Git 差异读取失败") &&
                !worktreeStatus.hasPrefix("工作树读取失败") &&
                gitDataAvailable &&
                pullRequestStatusAvailable &&
                terminalPreflightOk &&
                sourceEvidenceOk

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
                ] as [String: Any],
                "environmentSources": sourceFactsPayload,
                "sourceEvidenceOk": sourceEvidenceOk
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

    private static func runUsageActivitySmoke() {
        Task { @MainActor in
            let store = SessionStore()
            let buckets = (1...14).map { day in
                CodexRuntimeTokenUsageBucket(
                    startDate: String(format: "2026-07-%02d", day),
                    tokens: day
                )
            }
            store.runtimeTokenUsage = CodexRuntimeTokenUsage(
                lifetimeTokens: buckets.map(\.tokens).reduce(0, +),
                peakDailyTokens: buckets.map(\.tokens).max(),
                longestRunningTurnSec: 42,
                currentStreakDays: 14,
                longestStreakDays: 14,
                dailyBuckets: buckets
            )

            let daily = store.tokenUsageActivityValues(scale: "每日")
            let weekly = store.tokenUsageActivityValues(scale: "每周")
            let cumulative = store.tokenUsageActivityValues(scale: "累计")
            let ok = daily == Array(1...14) &&
                weekly == [28, 77] &&
                cumulative == [28, 105]

            emitJSON([
                "ok": ok,
                "source": "synthetic CodexRuntimeTokenUsage.dailyBuckets",
                "daily": daily,
                "weekly": weekly,
                "cumulative": cumulative,
                "lifetimeTokens": store.runtimeTokenUsage?.lifetimeTokens ?? 0
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runSampleDataGateSmoke() {
        Task { @MainActor in
            let expectSamples = CommandLine.arguments.contains("--expect-samples")
            let store = SessionStore()
            store.installSampleWorkspaceIfNeeded()

            let projectNames = store.projects.map(\.name)
            let threadTitles = store.threads.map(\.title)
            let hasSampleProjects = projectNames.contains { $0 != "RaytoneCodex" }
            let hasSampleThreads = threadTitles.contains("验证 Mac 客户端 UI smoke") ||
                threadTitles.contains("运行核心检查") ||
                threadTitles.contains("检查登录回调页面")
            let hasSamples = hasSampleProjects || hasSampleThreads
            let ok = expectSamples ? hasSamples : !hasSamples

            emitJSON([
                "ok": ok,
                "expectSamples": expectSamples,
                "sampleWorkspaceEnabled": SessionStore.sampleWorkspaceEnabled,
                "projectCount": store.projects.count,
                "threadCount": store.threads.count,
                "projectNames": projectNames,
                "threadTitles": threadTitles
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runSettingsSceneSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.route = .settings
            store.settingsPane = .configuration

            fputs("settings-scene-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("settings-scene-smoke: refreshRuntimeConfiguration\n", stderr)
            await store.refreshRuntimeConfiguration()

            let surface = SettingsView.runtimeSurfaceDescription
            let ok = surface == "SettingsRouteView" &&
                store.route == .settings &&
                store.settingsPane == .configuration &&
                store.runtimeCatalogStatusText.hasPrefix("config/read：") &&
                store.runtimeSnapshot.executable != nil

            emitJSON([
                "ok": ok,
                "settingsSceneSurface": surface,
                "legacyFormRemoved": surface == "SettingsRouteView",
                "route": "\(store.route)",
                "settingsPane": "\(store.settingsPane)",
                "runtimeStatus": store.runtimeCatalogStatusText,
                "runtimeErrors": store.runtimeCatalogErrors,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "configLayerCount": store.runtimeConfig?.layerCount ?? 0,
                "source": "Settings scene -> SettingsRouteView -> config/read"
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runSettingsProjectSmoke() {
        Task { @MainActor in
            let temporaryRoot = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexSettingsProjectSmoke-\(UUID().uuidString)", isDirectory: true)
            let firstProjectURL = temporaryRoot.appendingPathComponent("first", isDirectory: true)
            let secondProjectURL = temporaryRoot.appendingPathComponent("second", isDirectory: true)

            do {
                try FileManager.default.createDirectory(at: firstProjectURL, withIntermediateDirectories: true)
                try FileManager.default.createDirectory(at: secondProjectURL, withIntermediateDirectories: true)
                try "first\n".write(to: firstProjectURL.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
                try "second\n".write(to: secondProjectURL.appendingPathComponent("SETTINGS.md"), atomically: true, encoding: .utf8)

                let firstProject = Project(name: "设置项目一", path: firstProjectURL.path)
                let secondProject = Project(name: "设置项目二", path: secondProjectURL.path)
                let store = SessionStore()
                store.projects = [firstProject, secondProject]
                store.threads = [
                    ChatThread(title: "设置项目一对话", projectID: firstProject.id, items: []),
                    ChatThread(title: "设置项目二对话", projectID: secondProject.id, items: [])
                ]
                store.selectedThreadID = store.threads[0].id
                store.workspacePath = firstProject.path
                store.filePanelPath = firstProject.path
                store.route = .settings
                store.settingsPane = .configuration

                store.selectProjectForSettings(secondProject.id)

                let deadline = Date().addingTimeInterval(25)
                while Date() < deadline {
                    let hasFile = store.fileEntries.contains { $0.name == "SETTINGS.md" }
                    let configSettled = store.runtimeCatalogStatusText.hasPrefix("config/read：") ||
                        store.runtimeCatalogStatusText.hasPrefix("config/read 失败")
                    if hasFile && configSettled {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 250_000_000)
                }

                let fileNames = store.fileEntries.map(\.name)
                let ok = store.route == .settings &&
                    store.settingsPane == .configuration &&
                    store.selectedProject.id == secondProject.id &&
                    store.workspacePath == secondProject.path &&
                    store.filePanelPath == secondProject.path &&
                    fileNames.contains("SETTINGS.md") &&
                    store.runtimeCatalogStatusText.hasPrefix("config/read：")

                emitJSON([
                    "ok": ok,
                    "route": "\(store.route)",
                    "settingsPane": "\(store.settingsPane)",
                    "selectedProject": store.selectedProject.name,
                    "workspacePath": store.workspacePath,
                    "filePanelPath": store.filePanelPath,
                    "filePanelStatus": store.filePanelStatusText,
                    "fileEntries": fileNames,
                    "runtimeStatus": store.runtimeCatalogStatusText,
                    "runtimeErrors": store.runtimeCatalogErrors
                ])
                try? FileManager.default.removeItem(at: temporaryRoot)
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "error": error.localizedDescription
                ])
                try? FileManager.default.removeItem(at: temporaryRoot)
                exit(1)
            }
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
                await store.refreshAutomationEventLog()

                let configURL = codexHomeURL.appendingPathComponent("config.toml")
                let eventURL = codexHomeURL.appendingPathComponent("raytone-automation-events.jsonl")
                let configTextBeforeRemoval = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let eventText = (try? String(contentsOf: eventURL, encoding: .utf8)) ?? ""
                let requestLog = (try? String(contentsOf: mockServer!.requestLogURL, encoding: .utf8)) ?? ""
                let hooks = store.runtimeHooks
                let raytoneHooks = store.raytoneAutomationHooks()
                let agentMessages = store.selectedThread.items.compactMap { item -> String? in
                    if case let .agentMessage(text) = item.kind { return text }
                    return nil
                }
                let raytoneHook = raytoneHooks.first
                let hookTrustStatus = raytoneHook?.trustStatus ?? ""
                let hookTrusted = hookTrustStatus.localizedCaseInsensitiveCompare("trusted") == .orderedSame ||
                    hookTrustStatus.localizedCaseInsensitiveCompare("managed") == .orderedSame
                let eventLogStatus = store.automationEventLogStatusText
                let eventLogLineCount = store.automationEventLogLineCount
                let eventLogText = store.automationEventLogText

                await store.removeRaytoneAutomationHookTemplate()
                let hooksAfterRemoval = store.runtimeHooks
                let raytoneHooksAfterRemoval = store.raytoneAutomationHooks()
                let configTextAfterRemoval = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let removalStatus = store.runtimeCatalogStatusText
                let removalErrors = store.runtimeCatalogErrors
                await store.stopAppServerForTesting()

                let ok = store.runtimeSnapshot.executable != nil &&
                    !store.isRunning &&
                    configTextBeforeRemoval.contains("[features]") &&
                    configTextBeforeRemoval.contains("hooks = true") &&
                    configTextBeforeRemoval.contains("UserPromptSubmit") &&
                    configTextBeforeRemoval.contains("raytone-automation-events.jsonl") &&
                    raytoneHooks.count == 1 &&
                    hookTrusted &&
                    eventLogLineCount >= 1 &&
                    eventLogText.contains("\"source\":\"RaytoneCodex\"") &&
                    eventText.contains("\"source\":\"RaytoneCodex\"") &&
                    eventText.contains("\"template\":\"项目监控\"") &&
                    eventText.contains("\"event\":\"UserPromptSubmit\"") &&
                    requestLog.contains("/v1/responses") &&
                    agentMessages.contains("Raytone automation hook smoke OK") &&
                    raytoneHooksAfterRemoval.isEmpty &&
                    !configTextAfterRemoval.contains("BEGIN RaytoneCodex automation hooks") &&
                    !configTextAfterRemoval.contains("raytone-automation-events.jsonl") &&
                    removalErrors.isEmpty

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
                    "configTextBeforeRemoval": configTextBeforeRemoval,
                    "configTextAfterRemoval": configTextAfterRemoval,
                    "eventPath": eventURL.path,
                    "eventText": eventText,
                    "eventLogStatus": eventLogStatus,
                    "eventLogLineCount": eventLogLineCount,
                    "eventLogText": eventLogText,
                    "hookCount": hooks.count,
                    "raytoneHookCount": raytoneHooks.count,
                    "raytoneHookTrusted": hookTrusted,
                    "hookCountAfterRemoval": hooksAfterRemoval.count,
                    "raytoneHookCountAfterRemoval": raytoneHooksAfterRemoval.count,
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
                    "hooksAfterRemoval": hooksAfterRemoval.map { hook in
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
                    "status": removalStatus,
                    "errors": removalErrors
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

    private static func runHookNotificationSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexHookNotificationSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try "# Hook notification smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try fakeHookNotificationAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-hook-notification"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_HOOK_NOTIFICATION_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "HookNotificationSmoke"
                }

                store.prompt = "触发 app-server hook 通知"
                await store.runPrompt()

                let deadline = Date().addingTimeInterval(8)
                while Date() < deadline,
                      !store.automationEventLogText.contains(#""method":"hook/completed""#) {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let eventLogText = store.automationEventLogText
                let eventLines = eventLogText
                    .components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                let statusText = store.automationEventLogStatusText
                let catalogStatus = store.runtimeCatalogStatusText
                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let ok = !store.isRunning &&
                    eventLines.count >= 2 &&
                    eventLogText.contains(#""source":"Codex app-server""#) &&
                    eventLogText.contains(#""method":"hook/started""#) &&
                    eventLogText.contains(#""method":"hook/completed""#) &&
                    eventLogText.contains(#""eventName":"userPromptSubmit""#) &&
                    eventLogText.contains(#""status":"running""#) &&
                    eventLogText.contains(#""status":"completed""#) &&
                    statusText.contains("hook/completed") &&
                    catalogStatus.contains("提交用户提示") &&
                    logText.contains(#""method":"turn/start""#) &&
                    logText.contains(#""method":"hook/started""#) &&
                    logText.contains(#""method":"hook/completed""#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "eventLogLineCount": store.automationEventLogLineCount,
                    "eventLogStatus": statusText,
                    "runtimeCatalogStatus": catalogStatus,
                    "eventLogText": eventLogText,
                    "eventLines": eventLines,
                    "isRunning": store.isRunning,
                    "requestLogPreview": String(logText.prefix(2200))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runFileChangeStreamSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexFileChangeStreamSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try "# File change stream smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try fakeFileChangeStreamAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-file-change-stream"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_FILE_CHANGE_STREAM_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "FileChangeStreamSmoke"
                }

                store.prompt = "触发文件变更流式通知"
                await store.runPrompt()

                let deadline = Date().addingTimeInterval(8)
                while Date() < deadline,
                      !fileChanges(in: store.selectedThread.items).contains(where: { $0.path == "README.md" }) {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let fileChanges = fileChanges(in: store.selectedThread.items)
                let streamedFileChange = fileChanges.first { $0.path == "README.md" }
                let streamedLineObserved = streamedFileChange?.hunks
                    .flatMap(\.lines)
                    .contains { $0.kind == .added && $0.text.contains("streamed patch marker") } ?? false
                let outputBlocks = store.selectedThread.items.compactMap { item -> ReasoningBlock? in
                    if case let .reasoning(block) = item.kind, block.title == "文件变更输出" {
                        return block
                    }
                    return nil
                }
                let outputText = outputBlocks.map(\.detail).joined(separator: "\n")
                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let ok = !store.isRunning &&
                    store.selectedThread.appServerThreadID == "thread-file-change" &&
                    streamedFileChange?.additions == 1 &&
                    streamedFileChange?.deletions == 0 &&
                    streamedLineObserved &&
                    store.pendingChanges.contains(where: { $0.path == "README.md" }) &&
                    store.pendingAdditions == 1 &&
                    store.pendingDeletions == 0 &&
                    outputText.contains("apply_patch legacy stream") &&
                    logText.contains(#""method":"turn/start""#) &&
                    logText.contains(#""method":"item/fileChange/outputDelta""#) &&
                    logText.contains(#""method":"item/fileChange/patchUpdated""#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "appServerThreadID": store.selectedThread.appServerThreadID ?? "",
                    "transcriptItemCount": store.selectedThread.items.count,
                    "fileChanges": fileChanges.map { change in
                        [
                            "path": change.path,
                            "type": change.type.rawValue,
                            "additions": change.additions,
                            "deletions": change.deletions,
                            "hunkCount": change.hunks.count
                        ] as [String: Any]
                    },
                    "pendingChangeCount": store.pendingChanges.count,
                    "pendingAdditions": store.pendingAdditions,
                    "pendingDeletions": store.pendingDeletions,
                    "streamedLineObserved": streamedLineObserved,
                    "outputText": outputText,
                    "isRunning": store.isRunning,
                    "requestLogPreview": String(logText.prefix(2200))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runRuntimeDiagnosticsSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexRuntimeDiagnosticsSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try "# Runtime diagnostics smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try fakeRuntimeDiagnosticsAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-runtime-diagnostics"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_RUNTIME_DIAGNOSTICS_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "RuntimeDiagnosticsSmoke"
                }

                store.prompt = "触发运行时诊断通知"
                await store.runPrompt()

                let deadline = Date().addingTimeInterval(8)
                while Date() < deadline,
                      !store.runtimeCatalogStatusText.contains("deprecationNotice") {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let notices = store.selectedThread.items.compactMap { item -> Notice? in
                    if case let .notice(notice) = item.kind { return notice }
                    return nil
                }
                let noticeText = notices.map(\.text).joined(separator: "\n")
                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let expectedMethods = [
                    "configWarning",
                    "warning",
                    "guardianWarning",
                    "model/rerouted",
                    "model/verification",
                    "turn/moderationMetadata",
                    "windows/worldWritableWarning",
                    "windowsSandbox/setupCompleted",
                    "error",
                    "deprecationNotice"
                ]
                let logHasAllMethods = expectedMethods.allSatisfy { method in
                    logText.contains(#""method":"\#(method)""#)
                }
                let ok = !store.isRunning &&
                    store.selectedThread.appServerThreadID == "thread-runtime-diagnostics" &&
                    notices.count >= expectedMethods.count &&
                    noticeText.contains("配置文件") &&
                    noticeText.contains("Codex 警告") &&
                    noticeText.contains("安全审查") &&
                    noticeText.contains("高风险网络安全活动") &&
                    noticeText.contains("网络安全可信访问") &&
                    noticeText.contains("安全元数据") &&
                    noticeText.contains("Windows 路径权限警告") &&
                    noticeText.contains("Windows 沙箱设置失败") &&
                    noticeText.contains("Codex 轮次错误：provider returned 500 smoke") &&
                    noticeText.contains("Codex 不会自动重试") &&
                    noticeText.contains("内部服务器错误") &&
                    noticeText.contains("raytone error notification smoke") &&
                    noticeText.contains("旧版协议即将移除") &&
                    store.runtimeCatalogStatusText.contains("deprecationNotice") &&
                    store.runtimeCatalogErrors.contains(where: { $0.contains("旧版协议即将移除") }) &&
                    logHasAllMethods

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "appServerThreadID": store.selectedThread.appServerThreadID ?? "",
                    "noticeCount": notices.count,
                    "noticeText": noticeText,
                    "runtimeCatalogStatus": store.runtimeCatalogStatusText,
                    "runtimeCatalogErrors": store.runtimeCatalogErrors,
                    "isRunning": store.isRunning,
                    "logHasAllMethods": logHasAllMethods,
                    "requestLogPreview": String(logText.prefix(2600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runProcessStreamSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexProcessStreamSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try "# Process stream smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try fakeProcessStreamAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-process-stream"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_PROCESS_STREAM_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "ProcessStreamSmoke"
                }

                store.prompt = "触发进程流式通知"
                await store.runPrompt()

                let deadline = Date().addingTimeInterval(8)
                while Date() < deadline,
                      !store.runtimeCatalogStatusText.contains("process/exited") {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let processRun = store.terminalRuns.first { $0.processID == "process-stream-smoke" }
                let command = commandRuns(in: store.selectedThread.items).first { $0.command == "cat" }
                let commandOutput = command?.output ?? ""
                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let expectedMethods = [
                    "process/outputDelta",
                    "process/exited",
                    "item/commandExecution/outputDelta",
                    "item/commandExecution/terminalInteraction"
                ]
                let logHasAllMethods = expectedMethods.allSatisfy { method in
                    logText.contains(#""method":"\#(method)""#)
                }
                let ok = !store.isRunning &&
                    processRun?.command == "process/spawn process-stream-smoke" &&
                    processRun?.output.contains("process stdout stream") == true &&
                    processRun?.output.contains("process stderr stream") == true &&
                    processRun?.output.contains("stderr 输出已截断") == true &&
                    processRun?.exitCode == 0 &&
                    processRun?.status == .succeeded &&
                    command?.status == .running &&
                    commandOutput.contains("command ready") &&
                    commandOutput.contains("[stdin → command-process-smoke]") &&
                    commandOutput.contains("raytone stdin smoke") &&
                    commandOutput.contains("command done") &&
                    store.runtimeCatalogStatusText.contains("process/exited") &&
                    logHasAllMethods

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "terminalRuns": store.terminalRuns.map { run in
                        [
                            "command": run.command,
                            "processID": run.processID ?? "",
                            "output": run.output,
                            "exitCode": run.exitCode.map { Int($0) as Any } ?? NSNull(),
                            "status": terminalStatusName(run.status)
                        ] as [String: Any]
                    },
                    "commandOutput": commandOutput,
                    "runtimeCatalogStatus": store.runtimeCatalogStatusText,
                    "isRunning": store.isRunning,
                    "logHasAllMethods": logHasAllMethods,
                    "requestLogPreview": String(logText.prefix(2600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runAppServerNotificationSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexNotificationSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try "# Notification smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                try fakeAppServerNotificationScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-notification-stream"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_NOTIFICATION_SMOKE_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "NotificationSmoke"
                }

                store.prompt = "触发 app-server 通知覆盖"
                await store.runPrompt()

                let deadline = Date().addingTimeInterval(8)
                while Date() < deadline,
                      !store.voiceInputStatusText.contains("已关闭") {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let items = store.selectedThread.items
                let reasoningText = items.compactMap { item -> String? in
                    if case let .reasoning(block) = item.kind {
                        return "\(block.title)\n\(block.detail)"
                    }
                    return nil
                }.joined(separator: "\n\n")
                let agentText = items.compactMap { item -> String? in
                    if case let .agentMessage(text) = item.kind {
                        return text
                    }
                    return nil
                }.joined(separator: "\n")
                let notices = items.compactMap { item -> String? in
                    if case let .notice(notice) = item.kind {
                        return notice.text
                    }
                    return nil
                }
                let commands = commandRuns(in: items)
                let mcpCommand = commands.first { $0.command == "MCP demo/progress_tool" }
                let fileSearchStatus = store.fileSearchStatusText
                let fileSearchCount = store.fileSearchResults.count
                let voiceStatus = store.voiceInputStatusText
                let runtimeStatus = store.runtimeCatalogStatusText
                let runtimeErrors = store.runtimeCatalogErrors
                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let expectedMethods = [
                    "item/autoApprovalReview/started",
                    "item/autoApprovalReview/completed",
                    "rawResponseItem/completed",
                    "item/plan/delta",
                    "item/mcpToolCall/progress",
                    "item/reasoning/summaryPartAdded",
                    "fuzzyFileSearch/sessionUpdated",
                    "fuzzyFileSearch/sessionCompleted",
                    "thread/realtime/started",
                    "thread/realtime/itemAdded",
                    "thread/realtime/transcript/delta",
                    "thread/realtime/transcript/done",
                    "thread/realtime/outputAudio/delta",
                    "thread/realtime/sdp",
                    "thread/realtime/error",
                    "thread/realtime/closed"
                ]
                let logHasAllMethods = expectedMethods.allSatisfy { method in
                    logText.contains(#""method":"\#(method)""#)
                }
                let ok = !store.isRunning &&
                    reasoningText.contains("自动审批审查：已通过") &&
                    reasoningText.contains("检查真实 app-server 通知") &&
                    reasoningText.contains("摘要片段 1 已开始") &&
                    agentText.contains("raw response visible") &&
                    agentText.contains("实时响应完成") &&
                    mcpCommand?.output.contains("正在执行 MCP") == true &&
                    mcpCommand?.output.contains("tool result visible") == true &&
                    mcpCommand?.status == .succeeded &&
                    fileSearchCount == 1 &&
                    fileSearchStatus.contains("sessionCompleted") &&
                    voiceStatus.contains("已关闭") &&
                    notices.contains(where: { $0.contains("realtime 错误") }) &&
                    runtimeErrors.contains("realtime smoke error") &&
                    runtimeStatus.contains("thread/realtime/closed") &&
                    logHasAllMethods

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "reasoningText": reasoningText,
                    "agentText": agentText,
                    "mcpCommandOutput": mcpCommand?.output ?? "",
                    "mcpCommandStatus": mcpCommand.map { runStatusName($0.status) } ?? "",
                    "fileSearchStatus": fileSearchStatus,
                    "fileSearchCount": fileSearchCount,
                    "voiceStatus": voiceStatus,
                    "runtimeCatalogStatus": runtimeStatus,
                    "runtimeCatalogErrors": runtimeErrors,
                    "noticeText": notices.joined(separator: "\n"),
                    "logHasAllMethods": logHasAllMethods,
                    "requestLogPreview": String(logText.prefix(3200))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runGuardianDeniedApproveSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexGuardianDeniedSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeGuardianDeniedApproveAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-guardian-denied"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_GUARDIAN_APPROVE_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "GuardianDeniedSmoke"
                }

                store.prompt = "触发自动审批拒绝"
                await store.runPrompt()

                guard let denial = await waitForGuardianDeniedAction(in: store) else {
                    throw NSError(
                        domain: "RaytoneCodexGuardianDeniedSmoke",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "guardian denial action did not appear"]
                    )
                }
                await store.approveGuardianDeniedAction(denial)

                let deadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""method":"thread/approveGuardianDeniedAction""#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let requestLogged = logText.contains(#""method":"thread/approveGuardianDeniedAction""#) &&
                    logText.contains(#""threadId":"thread-guardian-denied-smoke""#) &&
                    logText.contains(#""id":"guardian-denied-smoke""#) &&
                    logText.contains(#""status":"denied""#) &&
                    logText.contains(#""command":"cat README.md""#)
                let ok = requestLogged &&
                    store.recentGuardianDeniedActions.isEmpty &&
                    store.runtimeCatalogStatusText.contains("已批准一次")

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "denialSummary": denial.summary,
                    "denialTurnID": denial.turnID,
                    "approvalRequestLogged": requestLogged,
                    "runtimeCatalogStatus": store.runtimeCatalogStatusText,
                    "requestLogPreview": String(logText.prefix(2600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
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

    private static func runAccountDeviceCodeSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("account-device-code-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("account-device-code-smoke: startAccountChatGPTDeviceCodeLogin\n", stderr)
            await store.startAccountChatGPTDeviceCodeLogin(openBrowser: false)
            let login = store.activeAccountLogin
            let startStatus = store.runtimeCatalogStatusText
            let startErrors = store.runtimeCatalogErrors

            fputs("account-device-code-smoke: cancelAccountLogin\n", stderr)
            await store.cancelAccountLogin()
            let cancelStatus = store.runtimeCatalogStatusText
            let cancelErrors = store.runtimeCatalogErrors

            let verificationURL = login?.verificationURL?.absoluteString ?? ""
            let userCode = login?.userCode ?? ""
            let ok = store.runtimeSnapshot.executable != nil &&
                login?.kind == "chatgptDeviceCode" &&
                login?.loginID?.isEmpty == false &&
                !verificationURL.isEmpty &&
                !userCode.isEmpty &&
                startStatus.contains("account/login/start(chatgptDeviceCode)") &&
                startErrors.isEmpty &&
                !cancelStatus.hasPrefix("取消登录失败") &&
                cancelErrors.isEmpty

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "loginKind": login?.kind ?? "",
                "loginID": login?.loginID ?? "",
                "verificationURLHost": login?.verificationURL?.host ?? "",
                "userCodeLength": userCode.count,
                "startStatus": startStatus,
                "startErrors": startErrors,
                "cancelStatus": cancelStatus,
                "cancelErrors": cancelErrors,
                "activeLoginAfterCancel": store.activeAccountLogin?.loginID ?? "",
                "source": "account/login/start(chatgptDeviceCode)"
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runConnectionRecoverySmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            await store.recoverConnection(
                from: .providerKeyMissing("DeepSeek"),
                openBrowserForLogin: false
            )
            let providerRouteOK = store.route == .settings &&
                store.settingsPane == .modelsProviders &&
                store.providerConnectionStatusText.contains("Provider API Key")
            let providerStatus = store.providerConnectionStatusText

            fputs("connection-recovery-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("connection-recovery-smoke: recover loginRequired\n", stderr)
            await store.recoverConnection(from: .loginRequired, openBrowserForLogin: false)
            let login = store.activeAccountLogin
            let loginStatus = store.runtimeCatalogStatusText
            let loginErrors = store.runtimeCatalogErrors
            let loginRouteOK = store.route == .settings && store.settingsPane == .usageBilling

            fputs("connection-recovery-smoke: cancelAccountLogin\n", stderr)
            await store.cancelAccountLogin()
            let cancelStatus = store.runtimeCatalogStatusText
            let cancelErrors = store.runtimeCatalogErrors

            let localizedStateOK = ConnectionState.loginRequired.title == "需要登录" &&
                ConnectionState.loginRequired.detail.contains("登录 Codex") &&
                ConnectionState.providerKeyMissing("DeepSeek").detail.contains("模型与提供方")
            let ok = store.runtimeSnapshot.executable != nil &&
                providerRouteOK &&
                loginRouteOK &&
                login?.kind == "chatgpt" &&
                login?.loginID?.isEmpty == false &&
                login?.authURL != nil &&
                loginErrors.isEmpty &&
                !cancelStatus.hasPrefix("取消登录失败") &&
                cancelErrors.isEmpty &&
                localizedStateOK

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "providerRouteOK": providerRouteOK,
                "providerStatus": providerStatus,
                "loginRouteOK": loginRouteOK,
                "loginKind": login?.kind ?? "",
                "loginID": login?.loginID ?? "",
                "authURLHost": login?.authURL?.host ?? "",
                "loginStatus": loginStatus,
                "loginErrors": loginErrors,
                "cancelStatus": cancelStatus,
                "cancelErrors": cancelErrors,
                "localizedStateOK": localizedStateOK
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

    private static func runProfilePrivacySmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("profile-privacy-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("profile-privacy-smoke: refreshProfilePrivacyRuntimeStatus\n", stderr)
            let profileStatus = await store.refreshProfilePrivacyRuntimeStatus()
            let catalogStatus = store.runtimeCatalogStatusText
            let errors = store.runtimeCatalogErrors
            let displayName = store.runtimeProfileDisplayName
            let accountKind = store.runtimeAccount?.kind ?? "notLoggedIn"
            let ok = store.runtimeSnapshot.executable != nil &&
                catalogStatus.contains("account/read") &&
                profileStatus.contains("account/read") &&
                profileStatus.contains("profile/privacy") &&
                !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                errors.isEmpty

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "accountKind": accountKind,
                "profileDisplayName": displayName,
                "profileHandle": store.runtimeProfileHandle,
                "profileStatus": profileStatus,
                "catalogStatus": catalogStatus,
                "errors": errors,
                "source": "account/read"
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runProfileShareSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("profile-share-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("profile-share-smoke: copyRuntimeProfileShareSummary\n", stderr)
            let status = await store.copyRuntimeProfileShareSummary()
            let clipboard = NSPasteboard.general.string(forType: .string) ?? ""
            let accountKind = store.runtimeAccount?.kind ?? "notLoggedIn"
            let sourceMarker = "account/read + account/usage/read + account/rateLimits/read"
            let ok = store.runtimeSnapshot.executable != nil &&
                status.contains("已复制分享摘要") &&
                status.contains(sourceMarker) &&
                clipboard.contains("RaytoneCodex") &&
                clipboard.contains("账户：") &&
                clipboard.contains("累计 Token：") &&
                clipboard.contains("速率限制桶：") &&
                clipboard.contains("来源：\(sourceMarker)")

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "accountKind": accountKind,
                "status": status,
                "errors": store.runtimeCatalogErrors,
                "clipboardLength": clipboard.count,
                "clipboardPreview": redactedProfileSharePreview(String(clipboard.prefix(360))),
                "source": sourceMarker
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runHookControlsSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexHookControlsSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            var store: SessionStore?

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)
                try "# Hook controls smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                let configURL = codexHomeURL.appendingPathComponent("config.toml")
                try """
                [features]
                hooks = true

                [hooks]

                [[hooks.UserPromptSubmit]]

                [[hooks.UserPromptSubmit.hooks]]
                type = "command"
                command = "echo raytone hook controls"
                timeout = 5
                async = false
                statusMessage = "Raytone hook controls smoke"
                """.write(to: configURL, atomically: true, encoding: .utf8)

                let hookStore = SessionStore()
                store = hookStore
                hookStore.workspacePath = workspaceURL.path
                hookStore.filePanelPath = workspaceURL.path
                hookStore.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]
                if let index = hookStore.projects.firstIndex(where: { $0.id == hookStore.selectedThread.projectID }) {
                    hookStore.projects[index].path = workspaceURL.path
                }

                await hookStore.refreshRuntime()
                await hookStore.refreshRuntimeHooks()
                guard let initialHook = firstUserPromptHook(in: hookStore.runtimeHooks) else {
                    await hookStore.stopAppServerForTesting()
                    emitJSON([
                        "ok": false,
                        "runtimeSource": hookStore.runtimeSnapshot.executable?.source.rawValue ?? "none",
                        "runtimePath": hookStore.runtimeSnapshot.executable?.url.path ?? "",
                        "runtimeVersion": hookStore.runtimeSnapshot.version ?? "",
                        "workspacePath": workspaceURL.path,
                        "codexHome": codexHomeURL.path,
                        "status": hookStore.runtimeCatalogStatusText,
                        "errors": hookStore.runtimeCatalogErrors,
                        "hooks": hookStore.runtimeHooks.map(hookPayload)
                    ])
                    exit(1)
                }

                await hookStore.trustRuntimeHook(initialHook)
                let trustedHook = firstUserPromptHook(in: hookStore.runtimeHooks)

                if let trustedHook {
                    await hookStore.setRuntimeHookEnabled(trustedHook, enabled: false)
                }
                let disabledHook = firstUserPromptHook(in: hookStore.runtimeHooks)

                if let disabledHook {
                    await hookStore.setRuntimeHookEnabled(disabledHook, enabled: true)
                }
                let enabledHook = firstUserPromptHook(in: hookStore.runtimeHooks)
                let finalConfig = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                await hookStore.stopAppServerForTesting()

                let trustOK = trustedHook?.trustStatus.localizedCaseInsensitiveCompare("trusted") == .orderedSame ||
                    trustedHook?.trustStatus.localizedCaseInsensitiveCompare("managed") == .orderedSame
                let ok = hookStore.runtimeSnapshot.executable != nil &&
                    initialHook.trustStatus.localizedCaseInsensitiveCompare("untrusted") == .orderedSame &&
                    initialHook.enabled &&
                    trustOK &&
                    disabledHook?.enabled == false &&
                    enabledHook?.enabled == true &&
                    finalConfig.contains("trusted_hash") &&
                    finalConfig.contains("enabled = true")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": hookStore.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": hookStore.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": hookStore.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "configPath": configURL.path,
                    "initialHook": hookPayload(initialHook),
                    "trustedHook": trustedHook.map(hookPayload) ?? NSNull(),
                    "disabledHook": disabledHook.map(hookPayload) ?? NSNull(),
                    "enabledHook": enabledHook.map(hookPayload) ?? NSNull(),
                    "finalConfig": finalConfig,
                    "status": hookStore.runtimeCatalogStatusText,
                    "errors": hookStore.runtimeCatalogErrors
                ])
                exit(ok ? 0 : 1)
            } catch {
                await store?.stopAppServerForTesting()
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

            fputs("integration-pages-smoke: refreshNewThreadHeroRuntime\n", stderr)
            await store.refreshNewThreadHeroRuntime()
            let integrationStatus = store.runtimeCatalogStatusText
            let integrationErrors = store.runtimeCatalogErrors
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
            let appWithInstallURL = store.runtimeApps.first { app in
                app.installURL?.isEmpty == false
            }
            let appInstallActionOK = appWithInstallURL.map {
                store.openRuntimeAppInstallURL($0, openExternal: false)
            } ?? false
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
                        "description": app.description ?? "",
                        "enabled": app.isEnabled,
                        "accessible": app.isAccessible,
                        "installURL": app.installURL ?? "",
                        "pluginDisplayNames": app.pluginDisplayNames,
                        "screenshotPromptCount": app.screenshotPrompts.count
                    ] as [String: Any]
                }),
                "appInstallAction": [
                    "attempted": appWithInstallURL != nil,
                    "ok": appInstallActionOK,
                    "app": appWithInstallURL?.name ?? "",
                    "url": store.lastOpenedRuntimeAppInstallURL,
                    "status": store.runtimeCatalogStatusText
                ] as [String: Any],
                "browserPluginCount": browserPlugins.count,
                "computerPluginCount": computerPlugins.count,
                "mcpServerCount": store.runtimeMCPServers.count,
                "homeConnectionCards": [
                    "source": "app/list + mcpServerStatus/list + files/readDirectory",
                    "status": store.homeConnectionStatusText,
                    "refreshed": store.homeConnectionsRefreshedAt != nil,
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

    private static func runHomeConnectionActionsSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath
            store.filePanelPath = workspacePath

            fputs("home-connection-actions-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("home-connection-actions-smoke: refreshNewThreadHeroRuntime\n", stderr)
            await store.refreshNewThreadHeroRuntime()
            let initialStatus = store.homeConnectionStatusText

            fputs("home-connection-actions-smoke: open files card\n", stderr)
            let filesOK = await store.openHomeConnection(.files)
            let fileNames = store.fileEntries.map(\.name)
            let filesPayload: [String: Any] = [
                "ok": filesOK,
                "route": "\(store.route)",
                "toolPanel": "\(store.toolPanel)",
                "status": store.homeConnectionStatusText,
                "filePanelStatus": store.filePanelStatusText,
                "path": store.filePanelPath,
                "entryCount": store.fileEntries.count,
                "fileCount": store.workspaceFileConnectionCount,
                "preview": Array(fileNames.prefix(12))
            ]

            fputs("home-connection-actions-smoke: open messaging card\n", stderr)
            let messagingOK = await store.openHomeConnection(.messaging)
            let messagingPayload: [String: Any] = [
                "ok": messagingOK,
                "route": "\(store.route)",
                "settingsPane": "\(store.settingsPane)",
                "status": store.homeConnectionStatusText,
                "runtimeCatalogStatus": store.runtimeCatalogStatusText,
                "count": store.messagingConnectionCount,
                "names": store.messagingConnectionNames
            ]

            fputs("home-connection-actions-smoke: open email card\n", stderr)
            let emailOK = await store.openHomeConnection(.email)
            let emailPayload: [String: Any] = [
                "ok": emailOK,
                "route": "\(store.route)",
                "settingsPane": "\(store.settingsPane)",
                "status": store.homeConnectionStatusText,
                "runtimeCatalogStatus": store.runtimeCatalogStatusText,
                "count": store.emailConnectionCount,
                "names": store.emailConnectionNames
            ]

            let ok = store.runtimeSnapshot.executable != nil &&
                filesOK &&
                messagingOK &&
                emailOK &&
                !initialStatus.hasPrefix("集成状态读取失败") &&
                store.homeConnectionsRefreshedAt != nil &&
                (filesPayload["fileCount"] as? Int ?? 0) > 0 &&
                (filesPayload["route"] as? String) == "thread" &&
                (filesPayload["toolPanel"] as? String) == "files" &&
                (messagingPayload["route"] as? String) == "settings" &&
                (messagingPayload["settingsPane"] as? String) == "connections" &&
                (emailPayload["route"] as? String) == "settings" &&
                (emailPayload["settingsPane"] as? String) == "connections"

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "source": "app/list + mcpServerStatus/list + fs/readDirectory",
                "initialStatus": initialStatus,
                "appCount": store.runtimeApps.count,
                "mcpServerCount": store.runtimeMCPServers.count,
                "runtimeErrors": store.runtimeCatalogErrors,
                "files": filesPayload,
                "messaging": messagingPayload,
                "email": emailPayload
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runAppMentionConfigSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexAppMentionConfigSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let codexHomeURL = rootURL.appendingPathComponent("codex-home", isDirectory: true)
            let configURL = codexHomeURL.appendingPathComponent("config.toml")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)

                let app = CodexRuntimeAppInfo(
                    id: "raytone.app-demo",
                    name: "Raytone Mail",
                    description: "用于验证 app mention 和 Codex apps 配置写入",
                    category: "邮件",
                    developer: "Raytone",
                    website: nil,
                    installURL: "https://chatgpt.com/apps/raytone/mail",
                    isAccessible: true,
                    isEnabled: true,
                    pluginDisplayNames: ["Raytone Mail Plugin"],
                    screenshotPrompts: ["打开邮件摘要"]
                )
                let prompt = "$\(app.inputSlug) 汇总今天的邮件"

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeApps = [app]
                store.appServerEnvironmentOverridesForTesting = [
                    "CODEX_HOME": codexHomeURL.path
                ]

                fputs("app-mention-config-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()
                fputs("app-mention-config-smoke: previewInputMentions\n", stderr)
                let mentions = await store.previewInputMentions(for: prompt)
                let inputItems = CodexAppServerClient.userInputItems(prompt: prompt, mentions: mentions)
                let inputJSONObject = jsonObject(from: inputItems)
                let mentionOK = mentions.count == 1 &&
                    mentions.first?.path == app.mentionPath &&
                    inputItems.arrayValue?.last?["type"]?.stringValue == "mention"

                fputs("app-mention-config-smoke: useRuntimeAppInComposer\n", stderr)
                store.runtimeApps = [app]
                let composerOK = await store.useRuntimeAppInComposer(app)

                fputs("app-mention-config-smoke: setRuntimeAppEnabled\n", stderr)
                let configWriteOK = await store.setRuntimeAppEnabled(app, enabled: false)
                let configText = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
                let configArtifactOK = configText.contains(#"[apps."raytone.app-demo"]"#) &&
                    configText.contains("enabled = false")
                let ok = store.runtimeSnapshot.executable != nil &&
                    mentionOK &&
                    composerOK &&
                    configWriteOK &&
                    configArtifactOK

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "configPath": configURL.path,
                    "appID": app.id,
                    "appSlug": app.inputSlug,
                    "mentionOK": mentionOK,
                    "composerOK": composerOK,
                    "configWriteOK": configWriteOK,
                    "configArtifactOK": configArtifactOK,
                    "mentions": mentions.map { ["name": $0.name, "path": $0.path] },
                    "turnInput": inputJSONObject,
                    "prompt": store.prompt,
                    "status": store.runtimeCatalogStatusText,
                    "errors": store.runtimeCatalogErrors,
                    "configPreview": configText
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "codexHome": codexHomeURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runAppMentionTurnSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexAppMentionTurnSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeAppMentionTurnAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let app = CodexRuntimeAppInfo(
                    id: "raytone.app-demo",
                    name: "Raytone Mail",
                    description: "用于验证 app mention 被发送到 turn/start",
                    category: "邮件",
                    developer: "Raytone",
                    website: nil,
                    installURL: "https://chatgpt.com/apps/raytone/mail",
                    isAccessible: true,
                    isEnabled: true,
                    pluginDisplayNames: ["Raytone Mail Plugin"],
                    screenshotPrompts: ["打开邮件摘要"]
                )
                let marker = "Raytone app mention turn smoke OK"

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-app-mention-turn"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_APP_MENTION_TURN_LOG": logURL.path
                ]
                store.runtimeApps = [app]

                fputs("app-mention-turn-smoke: useRuntimeAppInComposer\n", stderr)
                let composerOK = await store.useRuntimeAppInComposer(app)
                let preparedPrompt = store.prompt
                fputs("app-mention-turn-smoke: runPrompt\n", stderr)
                await store.runPrompt()

                let deadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""turnCompletedAfterMention":true"#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let agentMessages = store.selectedThread.items.compactMap { item -> String? in
                    if case let .agentMessage(text) = item.kind { return text }
                    return nil
                }
                let userMessages = store.selectedThread.items.compactMap { item -> String? in
                    if case let .userMessage(text) = item.kind { return text }
                    return nil
                }
                let promptContainsAppSlug = preparedPrompt.contains("$\(app.inputSlug)")
                let mentionInTurnStart = logText.contains(#""method":"turn/start""#) &&
                    logText.contains(#""type":"mention""#) &&
                    logText.contains(#""name":"Raytone Mail""#) &&
                    logText.contains(#""path":"app://raytone.app-demo""#)
                let textInTurnStart = logText.contains(#""type":"text""#) &&
                    logText.contains("最小可执行请求")
                let ok = composerOK &&
                    promptContainsAppSlug &&
                    mentionInTurnStart &&
                    textInTurnStart &&
                    userMessages.contains(preparedPrompt) &&
                    agentMessages.contains(marker) &&
                    !store.isRunning &&
                    store.selectedThread.appServerThreadID == "thread-app-mention"

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "appID": app.id,
                    "appSlug": app.inputSlug,
                    "composerOK": composerOK,
                    "promptContainsAppSlug": promptContainsAppSlug,
                    "mentionInTurnStart": mentionInTurnStart,
                    "textInTurnStart": textInTurnStart,
                    "isRunning": store.isRunning,
                    "threadID": store.selectedThread.appServerThreadID ?? "",
                    "preparedPrompt": preparedPrompt,
                    "agentMessages": agentMessages,
                    "requestLogPreview": String(logText.prefix(2600)),
                    "source": "useRuntimeAppInComposer + turn/start mention input"
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runAppListUpdatedSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexAppListUpdatedSmoke-\(UUID().uuidString)", isDirectory: true)
            let logURL = workspaceURL.appendingPathComponent("requests.jsonl")
            let scriptURL = workspaceURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeAppListUpdatedAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-app-list-updated"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_APP_LIST_UPDATED_LOG": logURL.path
                ]

                await store.refreshIntegrationRuntime(forceRefetchApps: true)
                let deadline = Date().addingTimeInterval(8)
                while Date() < deadline && store.runtimeApps.isEmpty {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let apps = store.runtimeApps
                let status = store.runtimeCatalogStatusText
                let appStatus = store.runtimeAppsStatusText
                await store.stopAppServerForTesting()

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                let firstApp = apps.first
                let ok = apps.count == 1 &&
                    firstApp?.id == "raytone-snapshot-app" &&
                    firstApp?.screenshotPrompts == ["打开设置并截取主窗口"] &&
                    firstApp?.installURL == "https://chatgpt.com/apps/raytone/snapshot" &&
                    appStatus.contains("app/list/updated") &&
                    logText.contains(#""method":"app/list""#) &&
                    logText.contains(#""forceRefetch":true"#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "status": status,
                    "appStatus": appStatus,
                    "appCount": apps.count,
                    "appsWithScreenshotMetadata": apps.filter { !$0.screenshotPrompts.isEmpty }.count,
                    "appPreview": apps.map { app in
                        [
                            "id": app.id,
                            "name": app.name,
                            "description": app.description ?? "",
                            "category": app.category ?? "",
                            "developer": app.developer ?? "",
                            "installURL": app.installURL ?? "",
                            "accessible": app.isAccessible,
                            "enabled": app.isEnabled,
                            "pluginDisplayNames": app.pluginDisplayNames,
                            "screenshotPrompts": app.screenshotPrompts
                        ] as [String: Any]
                    },
                    "runtimeCatalogErrors": store.runtimeCatalogErrors,
                    "requestLogPreview": String(logText.prefix(1600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runRemoteControlSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("remote-control-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("remote-control-smoke: remoteControl/status/read\n", stderr)
            await store.refreshRemoteControlStatus()

            let initialStatus = store.runtimeRemoteControlStatus
            let initialMode = store.workspaceExecutionMode.title

            fputs("remote-control-smoke: remoteControl/enable\n", stderr)
            await store.enableRemoteControlMode()
            let enabledStatus = store.runtimeRemoteControlStatus
            let enabledErrors = store.runtimeCatalogErrors
            let enabledMode = store.workspaceExecutionMode.title

            fputs("remote-control-smoke: remoteControl/disable\n", stderr)
            await store.disableRemoteControlMode()
            let disabledStatus = store.runtimeRemoteControlStatus
            let disabledErrors = store.runtimeCatalogErrors
            let disabledMode = store.workspaceExecutionMode.title

            var restored = false
            var restoreErrors: [String] = []
            if initialStatus?.status != "disabled" {
                fputs("remote-control-smoke: restore remoteControl/enable\n", stderr)
                await store.enableRemoteControlMode()
                restored = store.runtimeRemoteControlStatus?.status != "disabled"
                restoreErrors = store.runtimeCatalogErrors
            }

            let errors = enabledErrors + disabledErrors + restoreErrors
            let ok = store.runtimeSnapshot.executable != nil &&
                initialStatus != nil &&
                enabledStatus?.status != "disabled" &&
                disabledStatus?.status == "disabled" &&
                errors.isEmpty

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "catalogStatus": store.runtimeCatalogStatusText,
                "catalogErrors": errors,
                "initial": [
                    "workspaceExecutionMode": initialMode,
                    "remoteControl": remoteControlPayload(initialStatus)
                ] as [String: Any],
                "afterEnable": [
                    "workspaceExecutionMode": enabledMode,
                    "remoteControl": remoteControlPayload(enabledStatus),
                    "errors": enabledErrors
                ] as [String: Any],
                "afterDisable": [
                    "workspaceExecutionMode": disabledMode,
                    "remoteControl": remoteControlPayload(disabledStatus),
                    "errors": disabledErrors
                ] as [String: Any],
                "restoredInitialEnabledState": restored,
                "clientCount": store.runtimeRemoteControlClients.count,
                "clientListNextCursor": store.runtimeRemoteControlClientsNextCursor ?? ""
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runRemoteControlModeSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexRemoteModeSmoke-\(UUID().uuidString)", isDirectory: true)
            let logURL = workspaceURL.appendingPathComponent("requests.jsonl")
            let scriptURL = workspaceURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeRemoteControlAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-remote-control-mode"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_REMOTE_REVOKE_LOG": logURL.path
                ]

                store.chooseWorkspaceExecutionMode(.cloudPending)
                let cloudDeadline = Date().addingTimeInterval(8)
                while Date() < cloudDeadline &&
                    (store.runtimeCatalogIsRefreshing || store.runtimeRemoteControlPairing == nil) {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let cloudStatus = store.runtimeCatalogStatusText
                let cloudMode = store.workspaceExecutionMode.title
                let pairing = store.runtimeRemoteControlPairing
                let claimed = store.runtimeRemoteControlPairingClaimed

                store.chooseWorkspaceExecutionMode(.local)
                let localDeadline = Date().addingTimeInterval(8)
                while Date() < localDeadline &&
                    (store.runtimeCatalogIsRefreshing || store.runtimeRemoteControlStatus?.status != "disabled") {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                let localStatus = store.runtimeCatalogStatusText
                let localMode = store.workspaceExecutionMode.title
                let disabledStatus = store.runtimeRemoteControlStatus

                await store.stopAppServerForTesting()

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                func logContains(_ method: String) -> Bool {
                    logText.contains(#""method": "\#(method)""#) ||
                        logText.contains(#""method":"\#(method)""#)
                }

                let ok = cloudMode == WorkspaceExecutionMode.cloudPending.title &&
                    localMode == WorkspaceExecutionMode.local.title &&
                    pairing?.pairingCode == "PAIR-SMOKE" &&
                    pairing?.manualPairingCode == "MANUAL-SMOKE" &&
                    pairing?.environmentID == "env-smoke" &&
                    claimed == false &&
                    disabledStatus?.status == "disabled" &&
                    logContains("remoteControl/enable") &&
                    logContains("remoteControl/pairing/start") &&
                    logContains("remoteControl/pairing/status") &&
                    logContains("remoteControl/disable")

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "cloud": [
                        "workspaceExecutionMode": cloudMode,
                        "status": cloudStatus,
                        "pairingCode": pairing?.pairingCode ?? "",
                        "manualPairingCode": pairing?.manualPairingCode ?? "",
                        "environmentID": pairing?.environmentID ?? "",
                        "claimed": claimed ?? false,
                        "claimedWasReturned": claimed != nil
                    ] as [String: Any],
                    "local": [
                        "workspaceExecutionMode": localMode,
                        "status": localStatus,
                        "remoteControl": remoteControlPayload(disabledStatus)
                    ] as [String: Any],
                    "methodEvidence": [
                        "remoteControl/enable": logContains("remoteControl/enable"),
                        "remoteControl/pairing/start": logContains("remoteControl/pairing/start"),
                        "remoteControl/pairing/status": logContains("remoteControl/pairing/status"),
                        "remoteControl/disable": logContains("remoteControl/disable")
                    ] as [String: Any],
                    "requestLogPreview": String(logText.prefix(1800))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runRemoteControlRevokeSmoke() {
        Task {
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexRemoteRevokeSmoke-\(UUID().uuidString)", isDirectory: true)
            let logURL = workspaceURL.appendingPathComponent("requests.jsonl")
            let scriptURL = workspaceURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeRemoteControlAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let client = CodexAppServerClient(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    workspaceURL: workspaceURL,
                    environmentOverrides: [
                        "RAYTONE_REMOTE_REVOKE_LOG": logURL.path
                    ],
                    remoteControl: true
                )

                try await client.initialize()
                let before = try await client.listRemoteControlClients(
                    environmentID: "env-smoke",
                    limit: 10,
                    order: "asc"
                )
                try await client.revokeRemoteControlClient(
                    environmentID: "env-smoke",
                    clientID: "client-smoke"
                )
                let after = try await client.listRemoteControlClients(
                    environmentID: "env-smoke",
                    limit: 10,
                    order: "asc"
                )
                await client.stop()

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                let ok = before.clients.contains { $0.clientID == "client-smoke" } &&
                    after.clients.allSatisfy { $0.clientID != "client-smoke" } &&
                    logText.contains(#""method": "remoteControl/client/revoke""#) &&
                    logText.contains(#""environmentId": "env-smoke""#) &&
                    logText.contains(#""clientId": "client-smoke""#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "beforeClientCount": before.clients.count,
                    "afterClientCount": after.clients.count,
                    "beforeClients": before.clients.map(remoteClientPayload),
                    "afterClients": after.clients.map(remoteClientPayload),
                    "requestLogPreview": String(logText.prefix(1400))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runAddCreditsNudgeSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexAddCreditsNudgeSmoke-\(UUID().uuidString)", isDirectory: true)
            let logURL = workspaceURL.appendingPathComponent("requests.jsonl")
            let scriptURL = workspaceURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeAddCreditsNudgeAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-add-credits"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_ADD_CREDITS_NUDGE_LOG": logURL.path
                ]

                await store.sendAddCreditsNudgeEmail(creditType: .usageLimit)
                let usageLimitStatus = store.addCreditsNudgeStatusText
                await store.sendAddCreditsNudgeEmail(creditType: .credits)
                let creditsStatus = store.addCreditsNudgeStatusText
                await store.stopAppServerForTesting()

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                let ok = usageLimitStatus == "已发送提醒邮件" &&
                    creditsStatus == "冷却中，稍后再试" &&
                    logText.contains(#""method":"account/sendAddCreditsNudgeEmail""#) &&
                    logText.contains(#""creditType":"usage_limit""#) &&
                    logText.contains(#""creditType":"credits""#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "usageLimitStatus": usageLimitStatus,
                    "creditsStatus": creditsStatus,
                    "runtimeCatalogStatus": store.runtimeCatalogStatusText,
                    "runtimeCatalogErrors": store.runtimeCatalogErrors,
                    "requestLogPreview": String(logText.prefix(1400))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runFeedbackUploadSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexFeedbackUploadSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeFeedbackUploadAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-feedback-upload"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_FEEDBACK_UPLOAD_LOG": logURL.path
                ]
                if let index = store.projects.firstIndex(where: { $0.id == store.selectedThread.projectID }) {
                    store.projects[index].path = workspaceURL.path
                    store.projects[index].name = "FeedbackUploadSmoke"
                }

                let localThreadID = store.selectedThreadID
                store.prompt = "建立反馈上传 smoke 线程"
                await store.runPrompt()
                await waitForStoreToSettle(store)
                let runtimeThreadID = await waitForThreadServerID(in: store, localThreadID: localThreadID)
                let uploadOK = await store.uploadRuntimeFeedback(
                    category: .bug,
                    reason: "  Raytone feedback upload smoke  ",
                    includeLogs: true
                )

                let deadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""method":"feedback/upload""#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }

                let requestLogged = logText.contains(#""method":"feedback/upload""#) &&
                    logText.contains(#""classification":"bug""#) &&
                    logText.contains(#""reason":"Raytone feedback upload smoke""#) &&
                    logText.contains(#""threadId":"thread-feedback-upload-smoke""#) &&
                    logText.contains(#""includeLogs":true"#) &&
                    logText.contains(#""raytone_client":"macos""#) &&
                    logText.contains(#""raytone_surface":"settings""#)
                let ok = uploadOK &&
                    runtimeThreadID == "thread-feedback-upload-smoke" &&
                    store.feedbackUploadThreadID == "feedback-tracking-smoke" &&
                    store.feedbackUploadStatusText.contains("已上传日志") &&
                    requestLogged

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "runtimeThreadID": runtimeThreadID,
                    "feedbackUploadThreadID": store.feedbackUploadThreadID,
                    "feedbackUploadStatus": store.feedbackUploadStatusText,
                    "requestLogged": requestLogged,
                    "requestLogPreview": String(logText.prefix(2600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runWindowsSandboxSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexWindowsSandboxSmoke-\(UUID().uuidString)", isDirectory: true)
            let logURL = workspaceURL.appendingPathComponent("requests.jsonl")
            let scriptURL = workspaceURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeWindowsSandboxAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-windows-sandbox"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_WINDOWS_SANDBOX_LOG": logURL.path
                ]

                await store.refreshWindowsSandboxReadiness()
                let readinessStatus = store.windowsSandboxReadinessStatusText
                let started = await store.startWindowsSandboxSetup(mode: .unelevated)
                let setupStatus = store.windowsSandboxSetupStatusText
                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                await store.stopAppServerForTesting()

                let ok = store.windowsSandboxReadiness == .updateRequired &&
                    readinessStatus.contains("需要更新") &&
                    started &&
                    setupStatus.contains("非管理员模式") &&
                    logText.contains(#""method":"windowsSandbox/readiness""#) &&
                    logText.contains(#""method":"windowsSandbox/setupStart""#) &&
                    logText.contains(#""mode":"unelevated""#) &&
                    logText.contains(#""cwd":"\#(workspaceURL.path)""#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "readinessStatus": readinessStatus,
                    "setupStatus": setupStatus,
                    "started": started,
                    "requestLogPreview": String(logText.prefix(1600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runExperimentalFeaturesSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let workspaceURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexExperimentalFeaturesSmoke-\(UUID().uuidString)", isDirectory: true)
            let logURL = workspaceURL.appendingPathComponent("requests.jsonl")
            let scriptURL = workspaceURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeExperimentalFeaturesAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-experimental-features"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_EXPERIMENTAL_FEATURES_LOG": logURL.path
                ]

                await store.refreshRuntimeExperimentalFeatures()
                let initialFeatures = store.runtimeExperimentalFeatures
                guard let authFeature = initialFeatures.first(where: { $0.name == "auth_elicitation" }) else {
                    throw NSError(
                        domain: "RaytoneCodexExperimentalFeaturesSmoke",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "fake experimentalFeature/list did not return auth_elicitation"]
                    )
                }

                await store.setRuntimeExperimentalFeature(authFeature, enabled: true)
                let updatedFeature = store.runtimeExperimentalFeatures.first(where: { $0.name == "auth_elicitation" })
                let finalStatus = store.runtimeExperimentalFeaturesStatusText
                await store.stopAppServerForTesting()

                let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                let ok = initialFeatures.count == 2 &&
                    initialFeatures.first(where: { $0.name == "auth_elicitation" })?.enabled == false &&
                    updatedFeature?.enabled == true &&
                    finalStatus.contains("experimentalFeature/enablement/set") &&
                    logText.contains(#""method":"experimentalFeature/list""#) &&
                    logText.contains(#""method":"experimentalFeature/enablement/set""#) &&
                    logText.contains(#""enablement":{"auth_elicitation":true}"#)

                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "initialFeatureCount": initialFeatures.count,
                    "authFeatureInitiallyEnabled": authFeature.enabled,
                    "authFeatureFinallyEnabled": updatedFeature?.enabled ?? false,
                    "runtimeExperimentalFeaturesStatus": finalStatus,
                    "runtimeCatalogErrors": store.runtimeCatalogErrors,
                    "requestLogPreview": String(logText.prefix(1600))
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runProjectSwitchSmoke() {
        Task { @MainActor in
            let temporaryRoot = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexProjectSwitchSmoke-\(UUID().uuidString)", isDirectory: true)
            let firstProject = temporaryRoot.appendingPathComponent("first", isDirectory: true)
            let secondProject = temporaryRoot.appendingPathComponent("second", isDirectory: true)

            do {
                try FileManager.default.createDirectory(at: firstProject, withIntermediateDirectories: true)
                try FileManager.default.createDirectory(at: secondProject, withIntermediateDirectories: true)
                try "one\n".write(to: firstProject.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
                try "two\n".write(to: secondProject.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

                let store = SessionStore()
                let first = Project(name: "第一个项目", path: firstProject.path)
                let second = Project(name: "第二个项目", path: secondProject.path)
                store.projects = [first, second]
                store.threads = [
                    ChatThread(title: "新对话", projectID: first.id, items: [])
                ]
                store.selectedThreadID = store.threads[0].id
                store.workspacePath = first.path
                store.filePanelPath = first.path

                store.selectProjectForNewThread(second.id)
                let deadline = Date().addingTimeInterval(20)
                while Date() < deadline && !store.fileEntries.contains(where: { $0.name == "README.md" }) {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                }

                let selected = store.selectedProject
                let selectedThread = store.selectedThread
                let fileNames = store.fileEntries.map(\.name)
                let ok = selected.id == second.id &&
                    selectedThread.projectID == second.id &&
                    selectedThread.items.isEmpty &&
                    store.workspacePath == second.path &&
                    store.filePanelPath == second.path &&
                    fileNames.contains("README.md")

                emitJSON([
                    "ok": ok,
                    "selectedProject": selected.name,
                    "selectedThreadProjectMatches": selectedThread.projectID == second.id,
                    "workspacePath": store.workspacePath,
                    "filePanelPath": store.filePanelPath,
                    "filePanelStatus": store.filePanelStatusText,
                    "fileEntries": fileNames,
                    "route": "\(store.route)"
                ])
                try? FileManager.default.removeItem(at: temporaryRoot)
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "error": error.localizedDescription
                ])
                try? FileManager.default.removeItem(at: temporaryRoot)
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runWorkspaceSwitchSmoke() {
        Task { @MainActor in
            let temporaryRoot = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexWorkspaceSwitchSmoke-\(UUID().uuidString)", isDirectory: true)
            let targetWorkspace = temporaryRoot.appendingPathComponent("workspace", isDirectory: true)

            do {
                try FileManager.default.createDirectory(at: targetWorkspace, withIntermediateDirectories: true)
                try "workspace switch\n".write(to: targetWorkspace.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
                _ = try runProcess(["git", "init"], cwd: targetWorkspace)
                _ = try runProcess(["git", "checkout", "-b", "raytone-workspace-smoke"], cwd: targetWorkspace)

                let store = SessionStore()
                store.setWorkspacePathForSelectedProject(targetWorkspace.path)

                let deadline = Date().addingTimeInterval(25)
                while Date() < deadline {
                    let hasFile = store.fileEntries.contains { $0.name == "README.md" }
                    let hasBranch = store.workspaceBranches.contains("raytone-workspace-smoke") ||
                        store.selectedProject.branch == "raytone-workspace-smoke"
                    let gitStatusSettled = !store.runtimeCatalogStatusText.hasPrefix("正在")
                    if hasFile && hasBranch && gitStatusSettled {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 250_000_000)
                }

                let fileNames = store.fileEntries.map(\.name)
                let ok = store.workspacePath == targetWorkspace.path &&
                    store.filePanelPath == targetWorkspace.path &&
                    store.selectedProject.path == targetWorkspace.path &&
                    fileNames.contains("README.md") &&
                    (
                        store.workspaceBranches.contains("raytone-workspace-smoke") ||
                            store.selectedProject.branch == "raytone-workspace-smoke"
                    ) &&
                    !store.runtimeCatalogStatusText.hasPrefix("正在") &&
                    !store.runtimeCatalogStatusText.hasPrefix("Git 差异读取失败")

                emitJSON([
                    "ok": ok,
                    "selectedProject": store.selectedProject.name,
                    "selectedProjectPath": store.selectedProject.path,
                    "workspacePath": store.workspacePath,
                    "filePanelPath": store.filePanelPath,
                    "filePanelStatus": store.filePanelStatusText,
                    "fileEntries": fileNames,
                    "branch": store.selectedProject.branch ?? "",
                    "branches": store.workspaceBranches,
                    "branchStatus": store.workspaceBranchStatusText,
                    "runtimeStatus": store.runtimeCatalogStatusText
                ])
                try? FileManager.default.removeItem(at: temporaryRoot)
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "error": error.localizedDescription
                ])
                try? FileManager.default.removeItem(at: temporaryRoot)
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runBranchSwitchSmoke() {
        Task { @MainActor in
            let baseWorkspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath
            let workspaceURL = URL(fileURLWithPath: baseWorkspacePath)
                .appendingPathComponent(".build/raytone-branch-switch-smoke-\(UUID().uuidString)", isDirectory: true)
            let targetBranch = "raytone-branch-smoke"

            do {
                try FileManager.default.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try "branch smoke\n".write(
                    to: workspaceURL.appendingPathComponent("README.md"),
                    atomically: true,
                    encoding: .utf8
                )
                _ = try runProcess(["git", "init"], cwd: workspaceURL)
                _ = try runProcess(["git", "checkout", "-b", "main"], cwd: workspaceURL)
                _ = try runProcess(["git", "add", "README.md"], cwd: workspaceURL)
                _ = try runProcess([
                    "git",
                    "-c", "user.email=raytone@example.com",
                    "-c", "user.name=Raytone Smoke",
                    "commit",
                    "-m", "initial"
                ], cwd: workspaceURL)
                _ = try runProcess(["git", "branch", targetBranch], cwd: workspaceURL)

                let store = SessionStore()
                let project = Project(name: "分支切换 Smoke", path: workspaceURL.path, branch: "main")
                let thread = ChatThread(title: "分支切换", projectID: project.id, items: [])
                store.projects = [project]
                store.threads = [thread]
                store.selectedThreadID = thread.id
                store.workspacePath = workspaceURL.path
                store.filePanelPath = workspaceURL.path

                fputs("branch-switch-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()

                fputs("branch-switch-smoke: refreshWorkspaceBranches\n", stderr)
                await store.refreshWorkspaceBranches()
                let initialBranches = store.workspaceBranches
                let initialBranch = store.selectedProject.branch ?? ""

                fputs("branch-switch-smoke: checkoutWorkspaceBranch\n", stderr)
                await store.checkoutWorkspaceBranch(targetBranch)

                let gitBranchResult = try runProcess(["git", "branch", "--show-current"], cwd: workspaceURL)
                let actualBranch = gitBranchResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalBranches = store.workspaceBranches
                let finalBranch = store.selectedProject.branch ?? ""
                let ok = store.runtimeSnapshot.executable != nil &&
                    initialBranch == "main" &&
                    initialBranches.contains("main") &&
                    initialBranches.contains(targetBranch) &&
                    actualBranch == targetBranch &&
                    finalBranch == targetBranch &&
                    finalBranches.contains(targetBranch) &&
                    store.workspaceBranchStatusText.contains("Git 分支")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "workspacePath": workspaceURL.path,
                    "source": "NewThreadHero branch pill -> SessionStore.checkoutWorkspaceBranch -> command/exec git switch",
                    "initialBranch": initialBranch,
                    "initialBranches": initialBranches,
                    "targetBranch": targetBranch,
                    "actualGitBranch": actualBranch,
                    "selectedProjectBranch": finalBranch,
                    "finalBranches": finalBranches,
                    "branchStatus": store.workspaceBranchStatusText,
                    "runtimeStatus": store.runtimeCatalogStatusText
                ])
                try? FileManager.default.removeItem(at: workspaceURL)
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "targetBranch": targetBranch,
                    "error": error.localizedDescription
                ])
                try? FileManager.default.removeItem(at: workspaceURL)
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runWorktreeSwitchSmoke() {
        Task { @MainActor in
            let temporaryRoot = FileManager.default.temporaryDirectory
                .appendingPathComponent("RaytoneCodexWorktreeSwitchSmoke-\(UUID().uuidString)", isDirectory: true)
            let mainWorkspace = temporaryRoot.appendingPathComponent("main", isDirectory: true)
            let linkedWorktree = temporaryRoot.appendingPathComponent("linked", isDirectory: true)

            do {
                try FileManager.default.createDirectory(at: mainWorkspace, withIntermediateDirectories: true)
                try "main worktree\n".write(to: mainWorkspace.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
                _ = try runProcess(["git", "init"], cwd: mainWorkspace)
                _ = try runProcess(["git", "checkout", "-b", "main"], cwd: mainWorkspace)
                _ = try runProcess(["git", "add", "README.md"], cwd: mainWorkspace)
                _ = try runProcess([
                    "git",
                    "-c", "user.email=raytone@example.com",
                    "-c", "user.name=Raytone Smoke",
                    "commit",
                    "-m", "initial"
                ], cwd: mainWorkspace)
                _ = try runProcess(["git", "worktree", "add", "-b", "raytone-linked", linkedWorktree.path], cwd: mainWorkspace)
                try "linked worktree\n".write(to: linkedWorktree.appendingPathComponent("LINKED.md"), atomically: true, encoding: .utf8)

                let store = SessionStore()
                store.workspacePath = mainWorkspace.path
                store.filePanelPath = mainWorkspace.path

                fputs("worktree-switch-smoke: refreshRuntime\n", stderr)
                await store.refreshRuntime()

                fputs("worktree-switch-smoke: refreshWorkspaceWorktrees\n", stderr)
                await store.refreshWorkspaceWorktrees()
                let initialWorktrees = store.workspaceWorktrees
                let initialStatus = store.runtimeCatalogStatusText

                fputs("worktree-switch-smoke: openWorkspaceWorktree\n", stderr)
                let switched = await store.openWorkspaceWorktree(linkedWorktree.path, revealFiles: true)
                let fileNames = store.fileEntries.map(\.name)
                let finalStatus = store.runtimeCatalogStatusText
                let branch = store.selectedProject.branch ?? ""
                let normalizedLinked = SessionStore.canonicalPath(linkedWorktree.path)
                let normalizedMain = SessionStore.canonicalPath(mainWorkspace.path)

                let ok = store.runtimeSnapshot.executable != nil &&
                    switched &&
                    initialWorktrees.contains(normalizedMain) &&
                    initialWorktrees.contains(normalizedLinked) &&
                    store.workspacePath == normalizedLinked &&
                    store.filePanelPath == normalizedLinked &&
                    store.selectedProject.path == normalizedLinked &&
                    store.route == .thread &&
                    store.toolPanel == .files &&
                    fileNames.contains("LINKED.md") &&
                    branch == "raytone-linked" &&
                    store.workspaceWorktrees.contains(normalizedMain) &&
                    store.workspaceWorktrees.contains(normalizedLinked) &&
                    finalStatus.contains("已切换工作树")

                emitJSON([
                    "ok": ok,
                    "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                    "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                    "runtimeVersion": store.runtimeSnapshot.version ?? "",
                    "mainWorkspace": normalizedMain,
                    "linkedWorktree": normalizedLinked,
                    "initialStatus": initialStatus,
                    "initialWorktrees": initialWorktrees,
                    "switched": switched,
                    "workspacePath": store.workspacePath,
                    "filePanelPath": store.filePanelPath,
                    "selectedProjectPath": store.selectedProject.path,
                    "route": "\(store.route)",
                    "toolPanel": "\(store.toolPanel)",
                    "fileEntries": fileNames,
                    "branch": branch,
                    "branchStatus": store.workspaceBranchStatusText,
                    "finalStatus": finalStatus,
                    "worktrees": store.workspaceWorktrees,
                    "source": "command/exec git worktree list + command/exec git branch + fs/readDirectory"
                ])
                try? FileManager.default.removeItem(at: temporaryRoot)
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "mainWorkspace": mainWorkspace.path,
                    "linkedWorktree": linkedWorktree.path,
                    "error": error.localizedDescription
                ])
                try? FileManager.default.removeItem(at: temporaryRoot)
                exit(1)
            }
        }

        dispatchMain()
    }

    private static func runRealtimeVoicesSmoke() {
        let workspacePath = argument(after: "--workspace") ?? FileManager.default.currentDirectoryPath

        Task { @MainActor in
            let store = SessionStore()
            store.workspacePath = workspacePath

            fputs("realtime-voices-smoke: refreshRuntime\n", stderr)
            await store.refreshRuntime()

            fputs("realtime-voices-smoke: thread/realtime/listVoices\n", stderr)
            await store.refreshRealtimeVoicesForVoiceInput()

            let voices = store.runtimeRealtimeVoices
            let ok = store.runtimeSnapshot.executable != nil &&
                voices != nil &&
                voices?.v1.isEmpty == false &&
                voices?.v2.isEmpty == false

            emitJSON([
                "ok": ok,
                "runtimeSource": store.runtimeSnapshot.executable?.source.rawValue ?? "none",
                "runtimePath": store.runtimeSnapshot.executable?.url.path ?? "",
                "runtimeVersion": store.runtimeSnapshot.version ?? "",
                "workspacePath": workspacePath,
                "voiceInputStatusText": store.voiceInputStatusText,
                "voicesUpdatedAt": store.runtimeRealtimeVoicesUpdatedAt?.timeIntervalSince1970 ?? 0,
                "voices": realtimeVoicesPayload(voices)
            ])
            exit(ok ? 0 : 1)
        }

        dispatchMain()
    }

    private static func runRealtimeSessionSmoke() {
        Task { @MainActor in
            let fileManager = FileManager.default
            let rootURL = fileManager.temporaryDirectory
                .appendingPathComponent("RaytoneCodexRealtimeSessionSmoke-\(UUID().uuidString)", isDirectory: true)
            let workspaceURL = rootURL.appendingPathComponent("workspace", isDirectory: true)
            let logURL = rootURL.appendingPathComponent("requests.jsonl")
            let scriptURL = rootURL.appendingPathComponent("fake-codex")

            do {
                try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
                try fakeRealtimeSessionAppServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

                let store = SessionStore()
                store.workspacePath = workspaceURL.path
                store.runtimeSnapshot = CodexRuntimeSnapshot(
                    executable: CodexExecutable(url: scriptURL, source: .environment),
                    version: "fake-realtime-session"
                )
                store.appServerEnvironmentOverridesForTesting = [
                    "RAYTONE_REALTIME_SESSION_LOG": logURL.path
                ]

                fputs("realtime-session-smoke: list voices\n", stderr)
                await store.refreshRealtimeVoicesForVoiceInput()
                let voices = store.runtimeRealtimeVoices

                fputs("realtime-session-smoke: start realtime\n", stderr)
                let started = await store.startRealtimeTextSessionForVoiceInput(prompt: "Raytone realtime session smoke prompt")

                fputs("realtime-session-smoke: append text\n", stderr)
                let appended = await store.appendRealtimeTextForVoiceInput("Raytone realtime append text smoke")

                fputs("realtime-session-smoke: stop realtime\n", stderr)
                let stopped = await store.stopRealtimeVoiceInput()

                let deadline = Date().addingTimeInterval(8)
                var logText = ""
                while Date() < deadline {
                    logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
                    if logText.contains(#""realtimeStopped":true"#) {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                await waitForStoreToSettle(store)

                let transcriptTexts = store.selectedThread.items.compactMap { item -> String? in
                    switch item.kind {
                    case let .userMessage(text), let .agentMessage(text):
                        return text
                    default:
                        return nil
                    }
                }
                let requestObserved = logText.contains(#""method":"thread/realtime/listVoices""#) &&
                    logText.contains(#""method":"thread/start""#) &&
                    logText.contains(#""method":"thread/realtime/start""#) &&
                    logText.contains(#""outputModality":"text""#) &&
                    logText.contains(#""voice":"marin""#) &&
                    logText.contains("Raytone realtime session smoke prompt") &&
                    logText.contains(#""method":"thread/realtime/appendText""#) &&
                    logText.contains("Raytone realtime append text smoke") &&
                    logText.contains(#""method":"thread/realtime/stop""#)
                let notificationObserved = transcriptTexts.contains("Raytone realtime append text smoke") &&
                    (
                        store.voiceInputStatusText.contains("已停止") ||
                        store.voiceInputStatusText.contains("已关闭")
                    )
                let ok = started &&
                    appended &&
                    stopped &&
                    requestObserved &&
                    notificationObserved &&
                    voices?.defaultV2 == "marin" &&
                    store.selectedThread.appServerThreadID == "thread-realtime-smoke"

                await store.stopAppServerForTesting()
                emitJSON([
                    "ok": ok,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "started": started,
                    "appended": appended,
                    "stopped": stopped,
                    "requestObserved": requestObserved,
                    "notificationObserved": notificationObserved,
                    "voiceInputStatusText": store.voiceInputStatusText,
                    "threadID": store.selectedThread.appServerThreadID ?? "",
                    "voices": realtimeVoicesPayload(voices),
                    "transcriptTexts": transcriptTexts,
                    "requestLogPreview": String(logText.prefix(2600)),
                    "source": "thread/realtime/listVoices + start + appendText + stop"
                ])
                exit(ok ? 0 : 1)
            } catch {
                emitJSON([
                    "ok": false,
                    "workspacePath": workspaceURL.path,
                    "fakeExecutable": scriptURL.path,
                    "requestLog": logURL.path,
                    "error": error.localizedDescription
                ])
                exit(1)
            }
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

    private static func startMockResponsesServer(
        message: String,
        indexedResponses: Bool = false
    ) throws -> MockResponsesServer {
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
        process.arguments = [
            "python3",
            scriptURL.path,
            messageURL.path,
            portURL.path,
            logURL.path,
            indexedResponses ? "indexed" : "plain"
        ]
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

    private static func startMockModelsServer(models: [String]) throws -> MockResponsesServer {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("RaytoneCodexMockModels-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let modelsURL = directory.appendingPathComponent("models.json")
        let scriptURL = directory.appendingPathComponent("server.py")
        let portURL = directory.appendingPathComponent("port.txt")
        let logURL = directory.appendingPathComponent("requests.jsonl")
        let modelData = try JSONSerialization.data(withJSONObject: models, options: [])
        try modelData.write(to: modelsURL)
        try mockModelsServerScript.write(to: scriptURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", scriptURL.path, modelsURL.path, portURL.path, logURL.path]
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
                domain: "RaytoneCodexProviderSmoke",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "mock models server did not publish a port"]
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

    private static func postProviderUsageSmokeRequest(sidecarBaseURL: String, model: String) async throws -> String {
        guard let url = URL(string: "\(sidecarBaseURL)/responses") else {
            throw NSError(
                domain: "RaytoneCodexProviderSmoke",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "invalid sidecar base URL: \(sidecarBaseURL)"]
            )
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "input": "Raytone provider usage smoke",
            "stream": false
        ], options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(
                domain: "RaytoneCodexProviderSmoke",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "provider usage request failed"]
            )
        }
        return String(data: data, encoding: .utf8) ?? ""
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
        response_mode = sys.argv[4] if len(sys.argv) > 4 else "plain"
        request_index = 0

        def sse_payload(index):
            response_id = f"resp-raytone-review-{index}"
            item_id = f"msg-raytone-review-{index}"
            output_text = message if response_mode != "indexed" else f"{message} #{index}"
            events = [
                {"type": "response.created", "response": {"id": response_id}},
                {
                    "type": "response.output_item.done",
                    "item": {
                        "type": "message",
                        "role": "assistant",
                        "id": item_id,
                        "content": [{"type": "output_text", "text": output_text}],
                    },
                },
                {
                    "type": "response.completed",
                    "response": {
                        "id": response_id,
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
                global request_index
                length = int(self.headers.get("content-length") or "0")
                body = self.rfile.read(length).decode("utf-8", "replace")
                request_index += 1
                index = request_index
                with log_file.open("a", encoding="utf-8") as fh:
                    fh.write(json.dumps({"path": self.path, "body": body, "index": index}) + "\n")
                payload = sse_payload(index)
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

    private static var fakeRemoteControlAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_REMOTE_REVOKE_LOG")
        status = "connected"
        clients = [
            {
                "clientId": "client-smoke",
                "displayName": "Raytone Smoke iPhone",
                "deviceType": "phone",
                "platform": "iOS",
                "osVersion": "26.0",
                "deviceModel": "iPhone",
                "appVersion": "0.1.0",
                "lastSeenAt": 1783300000,
            },
            {
                "clientId": "client-keep",
                "displayName": "Raytone Keep Mac",
                "deviceType": "desktop",
                "platform": "macOS",
                "osVersion": "26.0",
                "deviceModel": "Mac",
                "appVersion": "0.1.0",
                "lastSeenAt": 1783300100,
            },
        ]

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, indent=0) + "\n")

        def send_result(request_id, result):
            sys.stdout.write(json.dumps({"id": request_id, "result": result}, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_error(request_id, message):
            sys.stdout.write(json.dumps({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "remoteControl/status/read":
                send_result(request_id, {
                    "status": status,
                    "serverName": "raytone-fake-remote",
                    "installationId": "install-smoke",
                    "environmentId": "env-smoke" if status != "disabled" else None,
                })
            elif method == "remoteControl/enable":
                status = "connected"
                send_result(request_id, {
                    "status": status,
                    "serverName": "raytone-fake-remote",
                    "installationId": "install-smoke",
                    "environmentId": "env-smoke",
                })
            elif method == "remoteControl/disable":
                status = "disabled"
                send_result(request_id, {
                    "status": status,
                    "serverName": "raytone-fake-remote",
                    "installationId": "install-smoke",
                    "environmentId": None,
                })
            elif method == "remoteControl/pairing/start":
                status = "connected"
                send_result(request_id, {
                    "pairingCode": "PAIR-SMOKE",
                    "manualPairingCode": "MANUAL-SMOKE" if params.get("manualCode") else None,
                    "environmentId": "env-smoke",
                    "expiresAt": 1783303700,
                })
            elif method == "remoteControl/pairing/status":
                send_result(request_id, {"claimed": False})
            elif method == "remoteControl/client/list":
                send_result(request_id, {"data": clients, "nextCursor": None})
            elif method == "remoteControl/client/revoke":
                environment_id = params.get("environmentId")
                client_id = params.get("clientId")
                if environment_id != "env-smoke":
                    send_error(request_id, "unexpected environmentId")
                    continue
                clients = [client for client in clients if client.get("clientId") != client_id]
                send_result(request_id, {})
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeRealtimeSessionAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_REALTIME_SESSION_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log(payload)
            send(payload)

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/realtime/listVoices":
                send_result(request_id, {
                    "voices": {
                        "v1": ["alloy"],
                        "v2": ["marin", "cedar"],
                        "defaultV1": "alloy",
                        "defaultV2": "marin",
                    }
                })
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": {
                        "id": "thread-realtime-smoke",
                        "sessionId": "session-realtime-smoke",
                        "name": "Realtime smoke",
                        "preview": "Realtime smoke",
                        "cwd": os.getcwd(),
                        "createdAt": 1700000000,
                        "updatedAt": 1700000001,
                        "status": {"type": "active", "activeFlags": []},
                    },
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "read-only",
                })
            elif method == "thread/realtime/start":
                send_result(request_id, {})
                send_notification("thread/realtime/started", {
                    "threadId": "thread-realtime-smoke",
                    "realtimeSessionId": "rt-session-smoke",
                    "version": "v2",
                })
                log({"realtimeStarted": True, "params": params})
            elif method == "thread/realtime/appendText":
                text = params.get("text", "")
                send_result(request_id, {})
                send_notification("thread/realtime/transcript/delta", {
                    "threadId": "thread-realtime-smoke",
                    "role": "user",
                    "delta": text,
                })
                send_notification("thread/realtime/transcript/done", {
                    "threadId": "thread-realtime-smoke",
                    "role": "user",
                    "text": text,
                })
                log({"realtimeAppendText": text})
            elif method == "thread/realtime/stop":
                send_result(request_id, {})
                send_notification("thread/realtime/closed", {
                    "threadId": "thread-realtime-smoke",
                    "reason": "requested",
                })
                log({"realtimeStopped": True})
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeThreadLifecycleAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_THREAD_LIFECYCLE_LOG")
        archived = False
        subscribed = False
        cwd = os.getcwd()

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log({"notification": payload})
            send(payload)

        def thread_payload(name="生命周期初始线程", is_archived=None):
            return {
                "id": "thread-life",
                "sessionId": "session-life",
                "name": name,
                "preview": "生命周期 smoke",
                "cwd": cwd,
                "archived": archived if is_archived is None else is_archived,
                "createdAt": 1700000000,
                "updatedAt": 1700000042,
                "modelProvider": "mock_provider",
                "source": {"type": "local"},
                "gitInfo": {
                    "branch": "main",
                    "sha": "abcdef1234567890",
                    "originUrl": "https://example.invalid/raytone.git",
                },
                "memoryMode": "enabled",
                "status": {"type": "idle"},
            }

        def thread_list(params):
            requested_archived = params.get("archived")
            if requested_archived is True:
                return {"data": [thread_payload("远端生命周期重命名", True)] if archived else [], "nextCursor": None}
            if requested_archived is False:
                return {"data": [] if archived else [thread_payload("远端生命周期重命名", False)], "nextCursor": None}
            return {"data": [thread_payload("远端生命周期重命名", archived)], "nextCursor": None}

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                cwd = params.get("cwd") or cwd
                subscribed = True
                send_result(request_id, {
                    "thread": thread_payload(),
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "danger-full-access",
                })
                send_notification("thread/started", {"thread": thread_payload()})
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-life", "status": "inProgress"}
                })
                send_notification("thread/status/changed", {
                    "threadId": "thread-life",
                    "status": {"type": "active", "activeFlags": ["waitingOnApproval"]},
                })
                send_notification("thread/name/updated", {
                    "threadId": "thread-life",
                    "threadName": "远端生命周期重命名",
                })
                send_notification("thread/compacted", {
                    "threadId": "thread-life",
                    "turnId": "turn-life",
                })
                send_notification("thread/status/changed", {
                    "threadId": "thread-life",
                    "status": {"type": "idle"},
                })
                send_notification("thread/closed", {
                    "threadId": "thread-life",
                })
                subscribed = False
                send_notification("turn/completed", {
                    "turn": {"id": "turn-life", "status": "completed"},
                })
            elif method == "thread/archive":
                archived = True
                send_result(request_id, {})
                send_notification("thread/archived", {"threadId": "thread-life"})
            elif method == "thread/unsubscribe":
                status = "unsubscribed" if subscribed else "notSubscribed"
                subscribed = False
                send_result(request_id, {"status": status})
            elif method == "thread/unarchive":
                archived = False
                send_result(request_id, {"thread": thread_payload("远端生命周期重命名", False)})
                send_notification("thread/unarchived", {"threadId": "thread-life"})
            elif method == "thread/list":
                send_result(request_id, thread_list(params))
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeFileChangeStreamAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_FILE_CHANGE_STREAM_LOG")
        cwd = os.getcwd()

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log(payload)
            send(payload)

        def file_change():
            diff = "\n".join([
                "diff --git a/README.md b/README.md",
                "index 1111111..2222222 100644",
                "--- a/README.md",
                "+++ b/README.md",
                "@@ -1 +1,2 @@",
                " # File change stream smoke",
                "+streamed patch marker",
                "",
            ])
            return {
                "path": "README.md",
                "kind": {"type": "update"},
                "diff": diff,
            }

        def thread_payload():
            return {
                "id": "thread-file-change",
                "sessionId": "session-file-change",
                "name": "文件变更流式线程",
                "preview": "File change stream smoke",
                "cwd": cwd,
                "createdAt": 1700000000,
                "updatedAt": 1700000001,
                "status": {"type": "active", "activeFlags": []},
            }

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                cwd = params.get("cwd") or cwd
                send_result(request_id, {
                    "thread": thread_payload(),
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "workspace-write",
                })
                send_notification("thread/started", {"thread": thread_payload()})
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-file-change", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-file-change",
                        "status": "inProgress",
                        "startedAt": 1700000000,
                    }
                })
                send_notification("item/fileChange/outputDelta", {
                    "threadId": "thread-file-change",
                    "turnId": "turn-file-change",
                    "itemId": "file-change-item",
                    "delta": "apply_patch legacy stream: README.md\n",
                })
                send_notification("item/fileChange/patchUpdated", {
                    "threadId": "thread-file-change",
                    "turnId": "turn-file-change",
                    "itemId": "file-change-item",
                    "changes": [file_change()],
                })
                send_notification("item/completed", {
                    "threadId": "thread-file-change",
                    "turnId": "turn-file-change",
                    "item": {
                        "id": "file-change-item",
                        "type": "fileChange",
                        "changes": [file_change()],
                    },
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-file-change", "status": "completed"}
                })
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeRuntimeDiagnosticsAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_RUNTIME_DIAGNOSTICS_LOG")
        cwd = os.getcwd()

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log(payload)
            send(payload)

        def thread_payload():
            return {
                "id": "thread-runtime-diagnostics",
                "sessionId": "session-runtime-diagnostics",
                "name": "运行时诊断线程",
                "preview": "Runtime diagnostics smoke",
                "cwd": cwd,
                "createdAt": 1700000000,
                "updatedAt": 1700000001,
                "status": {"type": "active", "activeFlags": []},
            }

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                cwd = params.get("cwd") or cwd
                send_result(request_id, {
                    "thread": thread_payload(),
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "workspace-write",
                })
                send_notification("thread/started", {"thread": thread_payload()})
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-runtime-diagnostics", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-runtime-diagnostics",
                        "status": "inProgress",
                        "startedAt": 1700000000,
                    }
                })
                send_notification("configWarning", {
                    "summary": "配置警告 smoke",
                    "details": "config.toml 中的测试字段无法识别",
                    "path": os.path.join(cwd, ".codex", "config.toml"),
                    "range": {
                        "start": {"line": 4, "column": 2},
                        "end": {"line": 4, "column": 12},
                    },
                })
                send_notification("warning", {
                    "threadId": "thread-runtime-diagnostics",
                    "message": "runtime warning smoke",
                })
                send_notification("guardianWarning", {
                    "threadId": "thread-runtime-diagnostics",
                    "message": "guardian warning smoke",
                })
                send_notification("model/rerouted", {
                    "threadId": "thread-runtime-diagnostics",
                    "turnId": "turn-runtime-diagnostics",
                    "fromModel": "gpt-5.3-codex",
                    "toModel": "gpt-5.2",
                    "reason": "highRiskCyberActivity",
                })
                send_notification("model/verification", {
                    "threadId": "thread-runtime-diagnostics",
                    "turnId": "turn-runtime-diagnostics",
                    "verifications": ["trustedAccessForCyber"],
                })
                send_notification("turn/moderationMetadata", {
                    "threadId": "thread-runtime-diagnostics",
                    "turnId": "turn-runtime-diagnostics",
                    "metadata": {"presentation": "inline", "smoke": True},
                })
                send_notification("windows/worldWritableWarning", {
                    "samplePaths": [os.path.join(cwd, "world-writable")],
                    "extraCount": 2,
                    "failedScan": False,
                })
                send_notification("windowsSandbox/setupCompleted", {
                    "mode": "unelevated",
                    "success": False,
                    "error": "sandbox setup smoke failure",
                })
                send_notification("error", {
                    "threadId": "thread-runtime-diagnostics",
                    "turnId": "turn-runtime-diagnostics",
                    "willRetry": False,
                    "error": {
                        "message": "provider returned 500 smoke",
                        "additionalDetails": "raytone error notification smoke",
                        "codexErrorInfo": "internalServerError",
                    },
                })
                send_notification("deprecationNotice", {
                    "summary": "旧版协议即将移除",
                    "details": "请迁移到 v2 app-server 通知。",
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-runtime-diagnostics", "status": "completed"}
                })
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeProcessStreamAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import base64
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_PROCESS_STREAM_LOG")
        cwd = os.getcwd()

        def b64(text):
            return base64.b64encode(text.encode("utf-8")).decode("ascii")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log(payload)
            send(payload)

        def thread_payload():
            return {
                "id": "thread-process-stream",
                "sessionId": "session-process-stream",
                "name": "进程流式线程",
                "preview": "Process stream smoke",
                "cwd": cwd,
                "createdAt": 1700000000,
                "updatedAt": 1700000001,
                "status": {"type": "active", "activeFlags": []},
            }

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                cwd = params.get("cwd") or cwd
                send_result(request_id, {
                    "thread": thread_payload(),
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "workspace-write",
                })
                send_notification("thread/started", {"thread": thread_payload()})
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-process-stream", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-process-stream",
                        "status": "inProgress",
                        "startedAt": 1700000000,
                    }
                })
                send_notification("process/outputDelta", {
                    "processHandle": "process-stream-smoke",
                    "stream": "stdout",
                    "deltaBase64": b64("process stdout stream\n"),
                    "capReached": False,
                })
                send_notification("process/outputDelta", {
                    "processHandle": "process-stream-smoke",
                    "stream": "stderr",
                    "deltaBase64": b64("process stderr stream\n"),
                    "capReached": True,
                })
                send_notification("process/exited", {
                    "processHandle": "process-stream-smoke",
                    "exitCode": 0,
                    "stdout": "",
                    "stdoutCapReached": False,
                    "stderr": "",
                    "stderrCapReached": True,
                })
                send_notification("item/started", {
                    "threadId": "thread-process-stream",
                    "turnId": "turn-process-stream",
                    "item": {
                        "id": "command-interaction-item",
                        "type": "commandExecution",
                        "command": "cat",
                        "cwd": cwd,
                        "status": "inProgress",
                        "aggregatedOutput": "",
                    },
                })
                send_notification("item/commandExecution/outputDelta", {
                    "threadId": "thread-process-stream",
                    "turnId": "turn-process-stream",
                    "itemId": "command-interaction-item",
                    "delta": "command ready\n",
                })
                send_notification("item/commandExecution/terminalInteraction", {
                    "threadId": "thread-process-stream",
                    "turnId": "turn-process-stream",
                    "itemId": "command-interaction-item",
                    "processId": "command-process-smoke",
                    "stdin": "raytone stdin smoke\n",
                })
                send_notification("item/commandExecution/outputDelta", {
                    "threadId": "thread-process-stream",
                    "turnId": "turn-process-stream",
                    "itemId": "command-interaction-item",
                    "delta": "command done\n",
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-process-stream", "status": "completed"}
                })
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeAppServerNotificationScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_NOTIFICATION_SMOKE_LOG")
        cwd = os.getcwd()

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log(payload)
            send(payload)

        def thread_payload():
            return {
                "id": "thread-notification-smoke",
                "sessionId": "session-notification-smoke",
                "name": "通知覆盖线程",
                "preview": "Notification smoke",
                "cwd": cwd,
                "createdAt": 1700000000,
                "updatedAt": 1700000001,
                "status": {"type": "active", "activeFlags": []},
            }

        def review_payload(status):
            return {
                "threadId": "thread-notification-smoke",
                "turnId": "turn-notification-smoke",
                "reviewId": "review-notification-smoke",
                "startedAtMs": 1700000000000,
                "completedAtMs": 1700000000500,
                "decisionSource": "agent",
                "targetItemId": "command-review-target",
                "action": {
                    "type": "command",
                    "source": "agent",
                    "command": "ls -la",
                    "cwd": cwd,
                },
                "review": {
                    "status": status,
                    "riskLevel": "low",
                    "userAuthorization": None,
                    "rationale": "通知 smoke 自动审查理由",
                },
            }

        def emit_notification_sequence():
            send_notification("turn/started", {
                "turn": {
                    "id": "turn-notification-smoke",
                    "status": "inProgress",
                    "startedAt": 1700000000,
                }
            })
            started = review_payload("inProgress")
            started.pop("completedAtMs", None)
            started.pop("decisionSource", None)
            send_notification("item/autoApprovalReview/started", started)
            send_notification("item/autoApprovalReview/completed", review_payload("approved"))
            send_notification("rawResponseItem/completed", {
                "threadId": "thread-notification-smoke",
                "turnId": "turn-notification-smoke",
                "item": {
                    "id": "raw-message-smoke",
                    "type": "message",
                    "role": "assistant",
                    "content": [{
                        "type": "output_text",
                        "text": "raw response visible",
                    }],
                },
            })
            send_notification("item/plan/delta", {
                "threadId": "thread-notification-smoke",
                "turnId": "turn-notification-smoke",
                "itemId": "plan-notification-smoke",
                "delta": "检查真实 app-server 通知",
            })
            send_notification("item/reasoning/summaryPartAdded", {
                "threadId": "thread-notification-smoke",
                "turnId": "turn-notification-smoke",
                "itemId": "reasoning-notification-smoke",
                "summaryIndex": 0,
            })
            send_notification("item/reasoning/summaryTextDelta", {
                "threadId": "thread-notification-smoke",
                "turnId": "turn-notification-smoke",
                "itemId": "reasoning-notification-smoke",
                "delta": "summary delta visible",
            })
            send_notification("item/mcpToolCall/progress", {
                "threadId": "thread-notification-smoke",
                "turnId": "turn-notification-smoke",
                "itemId": "mcp-notification-smoke",
                "message": "正在执行 MCP",
            })
            send_notification("item/completed", {
                "threadId": "thread-notification-smoke",
                "turnId": "turn-notification-smoke",
                "item": {
                    "id": "mcp-notification-smoke",
                    "type": "mcpToolCall",
                    "server": "demo",
                    "tool": "progress_tool",
                    "status": "completed",
                    "arguments": {"message": "hello"},
                    "pluginId": None,
                    "mcpAppResourceUri": None,
                    "durationMs": 42,
                    "result": {
                        "content": [{
                            "type": "text",
                            "text": "tool result visible",
                        }],
                        "structuredContent": {"ok": True},
                        "_meta": {"source": "notification-smoke"},
                    },
                    "error": None,
                },
            })
            send_notification("fuzzyFileSearch/sessionUpdated", {
                "sessionId": "fuzzy-notification-smoke",
                "query": "README",
                "files": [{
                    "file_name": "README.md",
                    "path": cwd + "/README.md",
                    "root": cwd,
                    "match_type": "fileName",
                    "score": 99,
                    "indices": [0, 1, 2],
                }],
            })
            send_notification("fuzzyFileSearch/sessionCompleted", {
                "sessionId": "fuzzy-notification-smoke",
            })
            send_notification("thread/realtime/started", {
                "threadId": "thread-notification-smoke",
                "realtimeSessionId": "rt-notification-smoke",
                "version": "v2",
            })
            send_notification("thread/realtime/itemAdded", {
                "threadId": "thread-notification-smoke",
                "item": {"type": "response.item", "id": "rt-item-smoke"},
            })
            send_notification("thread/realtime/transcript/delta", {
                "threadId": "thread-notification-smoke",
                "role": "assistant",
                "delta": "实时响应",
            })
            send_notification("thread/realtime/transcript/done", {
                "threadId": "thread-notification-smoke",
                "role": "assistant",
                "text": "实时响应完成",
            })
            send_notification("thread/realtime/outputAudio/delta", {
                "threadId": "thread-notification-smoke",
                "audio": {
                    "itemId": "rt-audio-smoke",
                    "data": "AAAA",
                    "numChannels": 1,
                    "sampleRate": 24000,
                    "samplesPerChannel": 2,
                },
            })
            send_notification("thread/realtime/sdp", {
                "threadId": "thread-notification-smoke",
                "sdp": "v=0\\no=- 0 0 IN IP4 127.0.0.1",
            })
            send_notification("thread/realtime/error", {
                "threadId": "thread-notification-smoke",
                "message": "realtime smoke error",
            })
            send_notification("thread/realtime/closed", {
                "threadId": "thread-notification-smoke",
                "reason": "smoke complete",
            })
            send_notification("turn/completed", {
                "turn": {"id": "turn-notification-smoke", "status": "completed"}
            })

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                cwd = params.get("cwd") or cwd
                send_result(request_id, {
                    "thread": thread_payload(),
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "workspace-write",
                })
                send_notification("thread/started", {"thread": thread_payload()})
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-notification-smoke", "status": "inProgress"}
                })
                emit_notification_sequence()
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeGuardianDeniedApproveAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_GUARDIAN_APPROVE_LOG")
        cwd = os.getcwd()

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log(payload)
            send(payload)

        def thread_payload():
            return {
                "id": "thread-guardian-denied-smoke",
                "sessionId": "session-guardian-denied-smoke",
                "name": "自动审批拒绝线程",
                "preview": "Guardian denied smoke",
                "cwd": cwd,
                "createdAt": 1700000000,
                "updatedAt": 1700000001,
                "status": {"type": "active", "activeFlags": []},
            }

        def guardian_denial_payload():
            return {
                "threadId": "thread-guardian-denied-smoke",
                "turnId": "turn-guardian-denied-smoke",
                "reviewId": "guardian-denied-smoke",
                "startedAtMs": 1700000000000,
                "completedAtMs": 1700000000750,
                "decisionSource": "agent",
                "targetItemId": "command-guardian-target",
                "action": {
                    "type": "command",
                    "source": "agent",
                    "command": "cat README.md",
                    "cwd": cwd,
                },
                "review": {
                    "status": "denied",
                    "riskLevel": "high",
                    "userAuthorization": "missing",
                    "rationale": "Guardian smoke denied this command before manual approval.",
                },
            }

        def emit_denial():
            send_notification("turn/started", {
                "turn": {
                    "id": "turn-guardian-denied-smoke",
                    "status": "inProgress",
                    "startedAt": 1700000000,
                }
            })
            send_notification("item/autoApprovalReview/completed", guardian_denial_payload())
            send_notification("turn/completed", {
                "turn": {"id": "turn-guardian-denied-smoke", "status": "completed"}
            })

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                cwd = params.get("cwd") or cwd
                send_result(request_id, {
                    "thread": thread_payload(),
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "auto",
                    "sandbox": "workspace-write",
                })
                send_notification("thread/started", {"thread": thread_payload()})
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-guardian-denied-smoke", "status": "inProgress"}
                })
                emit_denial()
            elif method == "thread/approveGuardianDeniedAction":
                send_result(request_id, {})
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeHookNotificationAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_HOOK_NOTIFICATION_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log({"notification": payload})
            send(payload)

        def hook_run(status):
            run = {
                "id": "hook-run-smoke",
                "eventName": "userPromptSubmit",
                "handlerType": "command",
                "executionMode": "sync",
                "scope": "turn",
                "sourcePath": os.path.join(os.getcwd(), ".codex", "config.toml"),
                "source": "project",
                "displayOrder": 0,
                "status": status,
                "statusMessage": "Raytone hook notification smoke",
                "startedAt": 1700000000000,
                "completedAt": None,
                "durationMs": None,
                "entries": [],
            }
            if status == "completed":
                run["completedAt"] = 1700000000042
                run["durationMs"] = 42
                run["entries"] = [
                    {"kind": "context", "text": "hook notification smoke context"},
                    {"kind": "feedback", "text": "hook notification smoke completed"},
                ]
            return run

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": {
                        "id": "thread-smoke",
                        "sessionId": "session-smoke",
                        "preview": "Hook notification smoke"
                    },
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "read-only"
                })
            elif method == "turn/start":
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-smoke",
                        "status": "inProgress",
                        "startedAt": 1700000000
                    }
                })
                send_notification("hook/started", {
                    "threadId": "thread-smoke",
                    "turnId": "turn-smoke",
                    "run": hook_run("running")
                })
                send_notification("hook/completed", {
                    "threadId": "thread-smoke",
                    "turnId": "turn-smoke",
                    "run": hook_run("completed")
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-smoke", "status": "completed"}
                })
                send_result(request_id, {
                    "turn": {"id": "turn-smoke", "status": "completed"}
                })
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeAddCreditsNudgeAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_ADD_CREDITS_NUDGE_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send_result(request_id, result):
            sys.stdout.write(json.dumps({"id": request_id, "result": result}, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_error(request_id, message):
            sys.stdout.write(json.dumps({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "account/sendAddCreditsNudgeEmail":
                credit_type = params.get("creditType")
                if credit_type == "usage_limit":
                    send_result(request_id, {"status": "sent"})
                elif credit_type == "credits":
                    send_result(request_id, {"status": "cooldown_active"})
                else:
                    send_error(request_id, f"unexpected creditType {credit_type}")
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeFeedbackUploadAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_FEEDBACK_UPLOAD_LOG")
        cwd = os.getcwd()

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log(payload)
            send(payload)

        def thread_payload():
            return {
                "id": "thread-feedback-upload-smoke",
                "sessionId": "session-feedback-upload-smoke",
                "name": "反馈上传线程",
                "preview": "Feedback upload smoke",
                "cwd": cwd,
                "createdAt": 1700000000,
                "updatedAt": 1700000001,
                "status": {"type": "active", "activeFlags": []},
            }

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                cwd = params.get("cwd") or cwd
                send_result(request_id, {
                    "thread": thread_payload(),
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "workspace-write",
                })
                send_notification("thread/started", {"thread": thread_payload()})
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-feedback-upload-smoke", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {"id": "turn-feedback-upload-smoke", "status": "inProgress"}
                })
                send_notification("rawResponseItem/completed", {
                    "threadId": "thread-feedback-upload-smoke",
                    "turnId": "turn-feedback-upload-smoke",
                    "item": {
                        "id": "feedback-message-smoke",
                        "type": "message",
                        "role": "assistant",
                        "content": [{
                            "type": "output_text",
                            "text": "feedback upload thread ready",
                        }],
                    },
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-feedback-upload-smoke", "status": "completed"}
                })
            elif method == "feedback/upload":
                if params.get("classification") != "bug":
                    send_error(request_id, "expected bug classification")
                else:
                    send_result(request_id, {"threadId": "feedback-tracking-smoke"})
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeWindowsSandboxAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_WINDOWS_SANDBOX_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            payload = {"method": method, "params": params or {}}
            log(payload)
            send(payload)

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "windowsSandbox/readiness":
                send_result(request_id, {"status": "updateRequired"})
            elif method == "windowsSandbox/setupStart":
                send_result(request_id, {"started": True})
                send_notification("windowsSandbox/setupCompleted", {
                    "mode": params.get("mode", "unelevated"),
                    "success": True,
                    "error": None,
                })
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeExperimentalFeaturesAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_EXPERIMENTAL_FEATURES_LOG")
        enablement = {
            "auth_elicitation": False,
            "memories": True,
        }

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def feature_payload():
            return {
                "data": [
                    {
                        "name": "auth_elicitation",
                        "stage": "underDevelopment",
                        "enabled": enablement["auth_elicitation"],
                        "defaultEnabled": False,
                        "displayName": None,
                        "description": None,
                        "announcement": None,
                    },
                    {
                        "name": "memories",
                        "stage": "beta",
                        "enabled": enablement["memories"],
                        "defaultEnabled": False,
                        "displayName": "记忆",
                        "description": "从聊天中生成新记忆，并将其带入新聊天",
                        "announcement": "实验功能 smoke",
                    },
                ],
                "nextCursor": None,
            }

        def send_result(request_id, result):
            sys.stdout.write(json.dumps({"id": request_id, "result": result}, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_error(request_id, message):
            sys.stdout.write(json.dumps({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "experimentalFeature/list":
                send_result(request_id, feature_payload())
            elif method == "experimentalFeature/enablement/set":
                requested = params.get("enablement") or {}
                accepted = {}
                for key, value in requested.items():
                    if key in enablement:
                        enablement[key] = bool(value)
                        accepted[key] = bool(value)
                send_result(request_id, {"enablement": accepted})
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeThreadBootstrapActionsAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_THREAD_BOOTSTRAP_ACTIONS_LOG")
        cwd = os.getcwd()
        thread_counter = 0

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def thread_payload(thread_id, include_turns=False):
            payload = {
                "id": thread_id,
                "sessionId": "session-" + thread_id,
                "name": "Bootstrap " + thread_id,
                "preview": "thread action bootstrap",
                "cwd": cwd,
                "archived": False,
                "createdAt": 1700000000,
                "updatedAt": 1700000042,
                "status": {"type": "idle"},
            }
            if include_turns:
                payload["turns"] = [{
                    "id": "turn-rollback",
                    "status": "completed",
                    "startedAt": 1700000030,
                    "items": [
                        {
                            "id": "user-rollback",
                            "type": "userMessage",
                            "content": [{"type": "text", "text": "rollback restored user"}],
                        },
                        {
                            "id": "agent-rollback",
                            "type": "agentMessage",
                            "text": "rollback restored agent",
                        },
                    ],
                }]
            return payload

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                cwd = params.get("cwd") or cwd
                thread_counter += 1
                thread_id = f"thread-bootstrap-{thread_counter}"
                send_result(request_id, {
                    "thread": thread_payload(thread_id),
                    "approvalPolicy": params.get("approvalPolicy", "on-request"),
                    "approvalsReviewer": params.get("approvalsReviewer", "user"),
                    "sandbox": params.get("sandbox", "danger-full-access"),
                })
            elif method == "thread/compact/start":
                send_result(request_id, {})
            elif method == "thread/rollback":
                send_result(request_id, {
                    "thread": thread_payload(params.get("threadId", "thread-bootstrap-rollback"), include_turns=True)
                })
            elif method == "command/exec":
                command = " ".join(params.get("command") or [])
                stdout = ""
                if "git branch" in command:
                    stdout = "* main\n  feature/current\n"
                send_result(request_id, {
                    "exitCode": 0,
                    "stdout": stdout,
                    "stderr": "",
                    "durationMs": 1,
                })
            elif method == "configRequirements/read":
                send_result(request_id, {"defaultPermissions": {"mode": "custom"}})
            elif method == "app/list":
                send_result(request_id, {"apps": []})
            elif method == "remoteControl/status/read":
                send_result(request_id, {"enabled": False, "environmentId": None, "publicUrl": None})
            elif method == "permissionProfile/list":
                send_result(request_id, {"profiles": []})
            elif method == "windowsSandbox/readiness":
                send_result(request_id, {"status": "unsupported"})
            elif method == "plugin/list":
                send_result(request_id, {"plugins": [], "marketplaceLoadErrors": []})
            elif method == "mcpServerStatus/list":
                send_result(request_id, {"servers": []})
            elif method == "fs/readDirectory":
                target = params.get("path") or cwd
                entries = []
                try:
                    for name in os.listdir(target):
                        item = os.path.join(target, name)
                        entries.append({
                            "fileName": name,
                            "isDirectory": os.path.isdir(item),
                            "isFile": os.path.isfile(item),
                        })
                except OSError:
                    pass
                send_result(request_id, {"entries": entries})
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeThreadMemoryModeAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_THREAD_MEMORY_MODE_LOG")
        thread_id = "00000000-0000-0000-0000-000000000001"
        session_id = "session-thread-memory-mode-smoke"
        memory_mode = "enabled"

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send_result(request_id, result):
            sys.stdout.write(json.dumps({"id": request_id, "result": result}, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_error(request_id, message):
            sys.stdout.write(json.dumps({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def thread_payload():
            return {
                "id": thread_id,
                "sessionId": session_id,
                "preview": "Raytone thread memory mode smoke",
                "memoryMode": memory_mode,
            }

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": thread_payload(),
                    "approvalPolicy": params.get("approvalPolicy"),
                    "approvalsReviewer": params.get("approvalsReviewer"),
                    "sandbox": params.get("sandbox"),
                })
            elif method == "thread/resume":
                send_result(request_id, {
                    "thread": thread_payload(),
                    "approvalPolicy": params.get("approvalPolicy"),
                    "approvalsReviewer": params.get("approvalsReviewer"),
                    "sandbox": params.get("sandbox"),
                })
            elif method == "thread/memoryMode/set":
                if params.get("threadId") != thread_id:
                    send_error(request_id, f"unexpected threadId {params.get('threadId')}")
                elif params.get("mode") not in ("enabled", "disabled"):
                    send_error(request_id, f"unexpected mode {params.get('mode')}")
                else:
                    memory_mode = params["mode"]
                    send_result(request_id, {})
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeModelProviderCapabilitiesAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_MODEL_PROVIDER_CAPABILITIES_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send_result(request_id, result):
            sys.stdout.write(json.dumps({"id": request_id, "result": result}, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_error(request_id, message):
            sys.stdout.write(json.dumps({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "modelProvider/capabilities/read":
                send_result(request_id, {
                    "namespaceTools": True,
                    "imageGeneration": True,
                    "webSearch": False,
                })
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeMCPElicitationAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_MCP_ELICITATION_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            send({"method": method, "params": params or {}})

        def send_elicitation_request():
            message = {
                "id": "elicitation-smoke",
                "method": "mcpServer/elicitation/request",
                "params": {
                    "serverName": "raytone_mcp",
                    "threadId": "thread-smoke",
                    "turnId": "turn-smoke",
                    "mode": "form",
                    "message": "请输入访问令牌以继续 MCP 工具调用。",
                    "requestedSchema": {
                        "type": "object",
                        "properties": {
                            "token": {
                                "type": "string",
                                "title": "访问令牌",
                                "description": "用于 smoke 的合成令牌。",
                                "default": ""
                            },
                            "confirmed": {
                                "type": "boolean",
                                "title": "确认",
                                "default": False
                            }
                        },
                        "required": ["token", "confirmed"]
                    }
                }
            }
            log({"serverRequest": message})
            send(message)

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            if request_id == "elicitation-smoke" and "result" in request:
                log({"elicitationResponse": request.get("result")})
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "elicitation-smoke"
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-smoke", "status": "completed"}
                })
                continue
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": {
                        "id": "thread-smoke",
                        "sessionId": "session-smoke",
                        "preview": "MCP elicitation smoke"
                    },
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "read-only"
                })
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-smoke", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-smoke",
                        "status": "inProgress",
                        "startedAt": 1700000000
                    }
                })
                send_elicitation_request()
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeToolUserInputAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_TOOL_USER_INPUT_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            send({"method": method, "params": params or {}})

        def send_tool_user_input_request():
            message = {
                "id": "tool-input-smoke",
                "method": "item/tool/requestUserInput",
                "params": {
                    "threadId": "thread-smoke",
                    "turnId": "turn-smoke",
                    "itemId": "tool-call-smoke",
                    "questions": [
                        {
                            "id": "q_mode",
                            "header": "运行方式",
                            "question": "工具应该如何继续？",
                            "isOther": False,
                            "isSecret": False,
                            "options": [
                                {
                                    "label": "继续",
                                    "description": "使用当前上下文继续运行工具。"
                                },
                                {
                                    "label": "暂停",
                                    "description": "暂不继续，等待更多信息。"
                                }
                            ]
                        },
                        {
                            "id": "q_secret",
                            "header": "临时口令",
                            "question": "请输入 smoke 用临时口令。",
                            "isOther": False,
                            "isSecret": True,
                            "options": None
                        }
                    ]
                }
            }
            log({"serverRequest": message})
            send(message)

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            if request_id == "tool-input-smoke" and "result" in request:
                log({"toolUserInputResponse": request.get("result")})
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "tool-input-smoke"
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-smoke", "status": "completed"}
                })
                continue
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": {
                        "id": "thread-smoke",
                        "sessionId": "session-smoke",
                        "preview": "Tool user input smoke"
                    },
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "read-only"
                })
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-smoke", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-smoke",
                        "status": "inProgress",
                        "startedAt": 1700000000
                    }
                })
                send_tool_user_input_request()
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeApprovalCompatAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_APPROVAL_COMPAT_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            send({"method": method, "params": params or {}})

        def send_permissions_request():
            message = {
                "id": "permissions-smoke",
                "method": "item/permissions/requestApproval",
                "params": {
                    "threadId": "thread-smoke",
                    "turnId": "turn-smoke",
                    "itemId": "permissions-item",
                    "cwd": os.getcwd(),
                    "startedAtMs": 1700000000000,
                    "reason": "需要联网读取文档。",
                    "permissions": {
                        "network": {"enabled": True},
                        "fileSystem": None
                    }
                }
            }
            log({"serverRequest": message})
            send(message)

        def send_legacy_exec_request():
            message = {
                "id": "legacy-exec-smoke",
                "method": "execCommandApproval",
                "params": {
                    "conversationId": "thread-smoke",
                    "callId": "exec-call-smoke",
                    "approvalId": "exec-approval-smoke",
                    "command": ["echo", "legacy"],
                    "cwd": os.getcwd(),
                    "reason": "验证旧 execCommandApproval 响应。",
                    "parsedCmd": []
                }
            }
            log({"serverRequest": message})
            send(message)

        def send_legacy_patch_request():
            message = {
                "id": "legacy-patch-smoke",
                "method": "applyPatchApproval",
                "params": {
                    "conversationId": "thread-smoke",
                    "callId": "patch-call-smoke",
                    "reason": "验证旧 applyPatchApproval 响应。",
                    "grantRoot": None,
                    "fileChanges": {
                        "Sources/LegacySmoke.swift": {
                            "type": "update",
                            "unified_diff": "@@ -1 +1 @@\n-old\n+new\n",
                            "move_path": None
                        }
                    }
                }
            }
            log({"serverRequest": message})
            send(message)

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            if request_id == "permissions-smoke" and "result" in request:
                log({"permissionsResponse": request.get("result")})
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "permissions-smoke"
                })
                send_legacy_exec_request()
                continue
            if request_id == "legacy-exec-smoke" and "result" in request:
                log({"legacyExecResponse": request.get("result")})
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "legacy-exec-smoke"
                })
                send_legacy_patch_request()
                continue
            if request_id == "legacy-patch-smoke" and "result" in request:
                log({"legacyPatchResponse": request.get("result")})
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "legacy-patch-smoke"
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-smoke", "status": "completed"}
                })
                continue
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": {
                        "id": "thread-smoke",
                        "sessionId": "session-smoke",
                        "preview": "Approval compatibility smoke"
                    },
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "read-only"
                })
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-smoke", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-smoke",
                        "status": "inProgress",
                        "startedAt": 1700000000
                    }
                })
                send_permissions_request()
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeDynamicToolAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import base64
        import json
        import os
        import subprocess
        import sys

        log_path = os.environ.get("RAYTONE_DYNAMIC_TOOL_LOG")
        tool_arguments = {"includeDiffStats": True}
        file_tool_arguments = {"path": ".", "maxEntries": 5, "includeHidden": False}
        read_file_tool_arguments = {"path": "README.md", "maxBytes": 200}

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            send({"method": method, "params": params or {}})

        def send_dynamic_tool_request(request_id, call_id, tool, arguments):
            message = {
                "id": request_id,
                "method": "item/tool/call",
                "params": {
                    "threadId": "thread-smoke",
                    "turnId": "turn-smoke",
                    "callId": call_id,
                    "namespace": "raytone_context",
                    "tool": tool,
                    "arguments": arguments
                }
            }
            log({"serverRequest": message})
            send(message)

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            if request_id == "dynamic-tool-smoke" and "result" in request:
                result = request.get("result") or {}
                log({"dynamicToolResponse": result})
                send_notification("item/completed", {
                    "item": {
                        "id": "call-smoke",
                        "type": "dynamicToolCall",
                        "namespace": "raytone_context",
                        "tool": "workspace_snapshot",
                        "arguments": tool_arguments,
                        "status": "completed",
                        "success": result.get("success"),
                        "contentItems": result.get("contentItems") or []
                    }
                })
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "dynamic-tool-smoke"
                })
                send_dynamic_tool_request(
                    "dynamic-tool-files-smoke",
                    "call-files-smoke",
                    "list_workspace_files",
                    file_tool_arguments,
                )
                continue
            if request_id == "dynamic-tool-files-smoke" and "result" in request:
                result = request.get("result") or {}
                log({"dynamicToolFilesResponse": result})
                send_notification("item/completed", {
                    "item": {
                        "id": "call-files-smoke",
                        "type": "dynamicToolCall",
                        "namespace": "raytone_context",
                        "tool": "list_workspace_files",
                        "arguments": file_tool_arguments,
                        "status": "completed",
                        "success": result.get("success"),
                        "contentItems": result.get("contentItems") or []
                    }
                })
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "dynamic-tool-files-smoke"
                })
                send_dynamic_tool_request(
                    "dynamic-tool-read-file-smoke",
                    "call-read-file-smoke",
                    "read_workspace_file",
                    read_file_tool_arguments,
                )
                continue
            if request_id == "dynamic-tool-read-file-smoke" and "result" in request:
                result = request.get("result") or {}
                log({"dynamicToolReadFileResponse": result})
                send_notification("item/completed", {
                    "item": {
                        "id": "call-read-file-smoke",
                        "type": "dynamicToolCall",
                        "namespace": "raytone_context",
                        "tool": "read_workspace_file",
                        "arguments": read_file_tool_arguments,
                        "status": "completed",
                        "success": result.get("success"),
                        "contentItems": result.get("contentItems") or []
                    }
                })
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "dynamic-tool-read-file-smoke"
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-smoke", "status": "completed"}
                })
                continue
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "command/exec":
                params = request.get("params") or {}
                command = params.get("command") or []
                cwd = params.get("cwd") or os.getcwd()
                try:
                    completed = subprocess.run(
                        command,
                        cwd=cwd,
                        text=True,
                        capture_output=True,
                        timeout=10,
                    )
                    result = {
                        "stdout": completed.stdout,
                        "stderr": completed.stderr,
                        "exitCode": completed.returncode,
                    }
                    log({"commandExecResponse": result})
                    send_result(request_id, result)
                except Exception as exc:
                    result = {
                        "stdout": "",
                        "stderr": str(exc),
                        "exitCode": 1,
                    }
                    log({"commandExecResponse": result})
                    send_result(request_id, result)
            elif method == "fs/readDirectory":
                params = request.get("params") or {}
                path = params.get("path") or os.getcwd()
                try:
                    entries = []
                    for entry in sorted(os.scandir(path), key=lambda item: item.name):
                        entries.append({
                            "fileName": entry.name,
                            "isDirectory": entry.is_dir(follow_symlinks=False),
                            "isFile": entry.is_file(follow_symlinks=False)
                        })
                    result = {"entries": entries}
                    log({"readDirectoryResponse": result})
                    send_result(request_id, result)
                except Exception as exc:
                    send_error(request_id, str(exc))
            elif method == "fs/readFile":
                params = request.get("params") or {}
                path = params.get("path") or os.getcwd()
                try:
                    with open(path, "rb") as handle:
                        data = handle.read()
                    result = {"dataBase64": base64.b64encode(data).decode("ascii")}
                    log({"readFileResponse": {"path": path, "byteCount": len(data)}})
                    send_result(request_id, result)
                except Exception as exc:
                    send_error(request_id, str(exc))
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": {
                        "id": "thread-smoke",
                        "sessionId": "session-smoke",
                        "preview": "Dynamic tool smoke"
                    },
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "read-only"
                })
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-smoke", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-smoke",
                        "status": "inProgress",
                        "startedAt": 1700000000
                    }
                })
                send_dynamic_tool_request(
                    "dynamic-tool-smoke",
                    "call-smoke",
                    "workspace_snapshot",
                    tool_arguments,
                )
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeInterruptAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_INTERRUPT_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            send({"method": method, "params": params or {}})

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": {
                        "id": "thread-smoke",
                        "sessionId": "session-smoke",
                        "preview": "Interrupt smoke"
                    },
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "read-only"
                })
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-smoke", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-smoke",
                        "status": "inProgress",
                        "startedAt": 1700000000
                    }
                })
            elif method == "turn/interrupt":
                params = request.get("params") or {}
                log({"turnInterrupt": params})
                send_result(request_id, {"status": "interrupted"})
                send_notification("turn/completed", {
                    "turn": {"id": params.get("turnId", "turn-smoke"), "status": "interrupted"}
                })
                log({"turnCompletedAfterInterrupt": True})
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeAuthAttestationAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_AUTH_ATTESTATION_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            })

        def send_notification(method, params=None):
            send({"method": method, "params": params or {}})

        def send_auth_refresh_request():
            message = {
                "id": "auth-refresh-smoke",
                "method": "account/chatgptAuthTokens/refresh",
                "params": {
                    "reason": "unauthorized",
                    "previousAccountId": "workspace-smoke"
                }
            }
            log({"serverRequest": message})
            send(message)

        def send_attestation_request():
            message = {
                "id": "attestation-smoke",
                "method": "attestation/generate",
                "params": {}
            }
            log({"serverRequest": message})
            send(message)

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            if request_id == "auth-refresh-smoke":
                log({"authRefreshError": request.get("error"), "authRefreshResult": request.get("result")})
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "auth-refresh-smoke"
                })
                send_attestation_request()
                continue
            if request_id == "attestation-smoke":
                log({"attestationError": request.get("error"), "attestationResult": request.get("result")})
                send_notification("serverRequest/resolved", {
                    "threadId": "thread-smoke",
                    "requestId": "attestation-smoke"
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-smoke", "status": "completed"}
                })
                continue
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": {
                        "id": "thread-smoke",
                        "sessionId": "session-smoke",
                        "preview": "Auth attestation smoke"
                    },
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "read-only"
                })
            elif method == "turn/start":
                send_result(request_id, {
                    "turn": {"id": "turn-smoke", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-smoke",
                        "status": "inProgress",
                        "startedAt": 1700000000
                    }
                })
                send_auth_refresh_request()
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeAppListUpdatedAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_APP_LIST_UPDATED_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send_result(request_id, result):
            sys.stdout.write(json.dumps({"id": request_id, "result": result}, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_notification(method, params=None):
            sys.stdout.write(json.dumps({
                "method": method,
                "params": params or {},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_error(request_id, message):
            sys.stdout.write(json.dumps({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def app_payload():
            return {
                "id": "raytone-snapshot-app",
                "name": "Raytone Snapshot",
                "description": "通过 app/list/updated 异步返回的应用目录项。",
                "logoUrl": "https://example.com/raytone.png",
                "logoUrlDark": None,
                "distributionChannel": None,
                "branding": {
                    "category": "开发工具",
                    "developer": "Raytone",
                    "website": "https://example.com/raytone",
                    "privacyPolicy": None,
                    "termsOfService": None,
                    "isDiscoverableApp": True,
                },
                "appMetadata": {
                    "review": {"status": "approved"},
                    "categories": ["开发工具"],
                    "subCategories": ["自动化"],
                    "seoDescription": "Raytone app-list updated smoke",
                    "screenshots": [{
                        "url": "https://example.com/snapshot.png",
                        "fileId": None,
                        "userPrompt": "打开设置并截取主窗口",
                    }],
                    "developer": "Raytone",
                    "version": "1.0.0",
                },
                "labels": {"source": "app-list-updated-smoke"},
                "installUrl": "https://chatgpt.com/apps/raytone/snapshot",
                "isAccessible": True,
                "isEnabled": True,
                "pluginDisplayNames": ["Browser"],
            }

        def result_for(method, params):
            if method == "initialize":
                return {}
            if method == "configRequirements/read":
                return {
                    "requirements": {
                        "defaultPermissions": ":workspace",
                        "allowAppshots": True,
                        "computerUse": {"allowLockedComputerUse": False},
                        "network": {"enabled": True},
                        "allowManagedHooksOnly": False,
                    }
                }
            if method == "app/list":
                return {"data": [], "nextCursor": None}
            if method == "remoteControl/status/read":
                return {"status": "disabled", "serverName": "fake", "installationId": "fake-installation", "environmentId": None}
            if method == "permissionProfile/list":
                return {"data": [], "nextCursor": None}
            if method in ("plugin/list", "plugin/installed"):
                return {"marketplaces": [], "featuredPluginIds": [], "marketplaceLoadErrors": []}
            if method == "mcpServerStatus/list":
                return {"data": [], "nextCursor": None}
            raise KeyError(method)

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            try:
                send_result(request_id, result_for(method, params))
                if method == "app/list":
                    send_notification("app/list/updated", {"data": [app_payload()]})
            except Exception as error:
                send_error(request_id, f"unsupported method {method}: {error}")
        """#
    }

    private static var fakeAppMentionTurnAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_APP_MENTION_TURN_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send(message):
            sys.stdout.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_result(request_id, result):
            send({"id": request_id, "result": result})

        def send_error(request_id, message):
            send({"id": request_id, "error": {"code": -32602, "message": message}})

        def send_notification(method, params=None):
            send({"method": method, "params": params or {}})

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "thread/start":
                send_result(request_id, {
                    "thread": {
                        "id": "thread-app-mention",
                        "sessionId": "session-app-mention",
                        "preview": "App mention smoke"
                    },
                    "approvalPolicy": "on-request",
                    "approvalsReviewer": "user",
                    "sandbox": "read-only"
                })
            elif method == "turn/start":
                log({"turnStartInput": params.get("input")})
                send_result(request_id, {
                    "turn": {"id": "turn-app-mention", "status": "inProgress"}
                })
                send_notification("turn/started", {
                    "turn": {
                        "id": "turn-app-mention",
                        "status": "inProgress",
                        "startedAt": 1700000000
                    }
                })
                send_notification("item/completed", {
                    "threadId": "thread-app-mention",
                    "turnId": "turn-app-mention",
                    "item": {
                        "id": "agent-app-mention",
                        "type": "agentMessage",
                        "text": "Raytone app mention turn smoke OK"
                    }
                })
                send_notification("turn/completed", {
                    "turn": {"id": "turn-app-mention", "status": "completed"}
                })
                log({"turnCompletedAfterMention": True})
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakePluginShareAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_PLUGIN_SHARE_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send_result(request_id, result):
            sys.stdout.write(json.dumps({"id": request_id, "result": result}, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_error(request_id, message):
            sys.stdout.write(json.dumps({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "plugin/share/save":
                plugin_path = params.get("pluginPath", "")
                if not plugin_path:
                    send_error(request_id, "missing pluginPath")
                else:
                    send_result(request_id, {
                        "remotePluginId": params.get("remotePluginId") or "plugins_raytone_share_smoke",
                        "shareUrl": "https://chatgpt.example/plugins/share/plugins_raytone_share_smoke",
                    })
            elif method == "plugin/share/updateTargets":
                if params.get("remotePluginId") != "plugins_raytone_share_smoke":
                    send_error(request_id, "unexpected remotePluginId")
                else:
                    send_result(request_id, {
                        "discoverability": params.get("discoverability") or "PRIVATE",
                        "principals": [],
                    })
            else:
                send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var fakeExternalAgentConfigAppServerScript: String {
        #"""
        #!/usr/bin/env python3
        import json
        import os
        import sys

        log_path = os.environ.get("RAYTONE_EXTERNAL_AGENT_CONFIG_LOG")

        def log(message):
            if not log_path:
                return
            with open(log_path, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n")

        def send_result(request_id, result):
            sys.stdout.write(json.dumps({"id": request_id, "result": result}, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_notification(method, params=None):
            sys.stdout.write(json.dumps({
                "method": method,
                "params": params or {},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def send_error(request_id, message):
            sys.stdout.write(json.dumps({
                "id": request_id,
                "error": {"code": -32602, "message": message},
            }, separators=(",", ":")) + "\n")
            sys.stdout.flush()

        def migration_items(params):
            cwd = None
            cwds = params.get("cwds") or []
            if cwds:
                cwd = cwds[0]
            return [
                {
                    "itemType": "CONFIG",
                    "description": "导入外部 Agent 的全局配置",
                    "cwd": None,
                    "details": None,
                },
                {
                    "itemType": "PLUGINS",
                    "description": "导入当前工作区支持的插件",
                    "cwd": cwd,
                    "details": {
                        "plugins": [
                            {
                                "marketplaceName": "team-marketplace",
                                "pluginNames": ["asana", "jira"],
                            }
                        ]
                    },
                },
            ]

        def empty_catalog(method):
            if method in ("plugin/list", "plugin/installed"):
                return {"marketplaces": [], "featuredPluginIds": [], "marketplaceLoadErrors": []}
            if method == "plugin/share/list":
                return {"data": [], "nextCursor": None}
            if method == "skills/list":
                return {"data": []}
            if method == "config/read":
                return {"config": {}, "layers": [], "origins": {}}
            if method == "hooks/list":
                return {"data": []}
            if method == "mcpServerStatus/list":
                return {"data": [], "nextCursor": None}
            raise KeyError(method)

        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            request = json.loads(line)
            log(request)
            request_id = request.get("id")
            method = request.get("method")
            params = request.get("params") or {}
            if request_id is None:
                continue
            if method == "initialize":
                send_result(request_id, {})
            elif method == "externalAgentConfig/detect":
                send_result(request_id, {"items": migration_items(params)})
            elif method == "externalAgentConfig/import":
                items = params.get("migrationItems") or []
                if len(items) != 2:
                    send_error(request_id, f"expected 2 migration items, got {len(items)}")
                else:
                    send_result(request_id, {})
                    send_notification("externalAgentConfig/import/completed", {})
            else:
                try:
                    send_result(request_id, empty_catalog(method))
                except Exception:
                    send_error(request_id, f"unsupported method {method}")
        """#
    }

    private static var mockModelsServerScript: String {
        #"""
        import json
        import sys
        from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
        from pathlib import Path

        models = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
        port_file = Path(sys.argv[2])
        log_file = Path(sys.argv[3])

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                with log_file.open("a", encoding="utf-8") as fh:
                    fh.write(json.dumps({
                        "method": "GET",
                        "path": self.path,
                        "authorization": self.headers.get("authorization", ""),
                    }, separators=(",", ":")) + "\n")
                if self.path not in ("/v1/models", "/models"):
                    self.send_response(404)
                    self.end_headers()
                    return
                payload = json.dumps({
                    "object": "list",
                    "data": [
                        {"id": model, "object": "model", "created": 0, "owned_by": "raytone-smoke"}
                        for model in models
                    ],
                }, separators=(",", ":")).encode("utf-8")
                self.send_response(200)
                self.send_header("content-type", "application/json")
                self.send_header("content-length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)

            def do_POST(self):
                length = int(self.headers.get("content-length") or "0")
                body = self.rfile.read(length).decode("utf-8", "replace")
                with log_file.open("a", encoding="utf-8") as fh:
                    fh.write(json.dumps({
                        "method": "POST",
                        "path": self.path,
                        "authorization": self.headers.get("authorization", ""),
                        "body": body,
                    }, separators=(",", ":")) + "\n")
                if self.path not in ("/v1/chat/completions", "/chat/completions"):
                    self.send_response(404)
                    self.end_headers()
                    return
                payload = json.dumps({
                    "id": "chatcmpl-raytone-usage",
                    "object": "chat.completion",
                    "created": 0,
                    "model": models[0] if models else "smoke-model",
                    "choices": [{
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": "Raytone provider usage smoke OK",
                        },
                        "finish_reason": "stop",
                    }],
                    "usage": {
                        "prompt_tokens": 11,
                        "completion_tokens": 7,
                        "total_tokens": 18,
                        "completion_tokens_details": {
                            "reasoning_tokens": 3,
                        },
                    },
                }, separators=(",", ":")).encode("utf-8")
                self.send_response(200)
                self.send_header("content-type", "application/json")
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

    private static func firstUserPromptHook(in hooks: [CodexRuntimeHook]) -> CodexRuntimeHook? {
        hooks.first { hook in
            hook.eventName
                .unicodeScalars
                .filter { CharacterSet.alphanumerics.contains($0) }
                .map { String($0).lowercased() }
                .joined() == "userpromptsubmit"
        }
    }

    private static func hookPayload(_ hook: CodexRuntimeHook) -> [String: Any] {
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
        ]
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

    private static func writePluginInstallSmokeFixture(
        workspaceURL: URL,
        codexHomeURL: URL,
        pluginName: String,
        marketplaceName: String
    ) throws {
        let fileManager = FileManager.default
        let pluginRoot = workspaceURL.appendingPathComponent("plugins/\(pluginName)", isDirectory: true)
        try fileManager.createDirectory(at: workspaceURL.appendingPathComponent(".git", isDirectory: true), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: workspaceURL.appendingPathComponent(".agents/plugins", isDirectory: true), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: pluginRoot.appendingPathComponent(".codex-plugin", isDirectory: true), withIntermediateDirectories: true)

        try """
        {
          "name": "\(marketplaceName)",
          "plugins": [
            {
              "name": "\(pluginName)",
              "source": {
                "source": "local",
                "path": "./plugins/\(pluginName)"
              },
              "policy": {
                "installation": "AVAILABLE",
                "authentication": "ON_USE"
              },
              "category": "Productivity"
            }
          ]
        }
        """.write(to: workspaceURL.appendingPathComponent(".agents/plugins/marketplace.json"), atomically: true, encoding: .utf8)

        try """
        {
          "name": "\(pluginName)",
          "description": "Raytone plugin/install smoke source",
          "interface": {
            "displayName": "Raytone Plugin Install Smoke",
            "shortDescription": "plugin/install smoke subtitle",
            "developerName": "Raytone",
            "category": "Productivity"
          }
        }
        """.write(to: pluginRoot.appendingPathComponent(".codex-plugin/plugin.json"), atomically: true, encoding: .utf8)

        try """
        [features]
        plugins = true
        """.write(to: codexHomeURL.appendingPathComponent("config.toml"), atomically: true, encoding: .utf8)
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

    private static func mcpResourceSmokeServerScript(
        marker: String,
        resourceURI: String,
        resourceTemplateURI: String
    ) -> String {
        let markerLiteral = String(reflecting: marker)
        let resourceURILiteral = String(reflecting: resourceURI)
        let resourceTemplateURILiteral = String(reflecting: resourceTemplateURI)
        return """
        import json
        import sys

        MARKER = \(markerLiteral)
        RESOURCE_URI = \(resourceURILiteral)
        RESOURCE_TEMPLATE_URI = \(resourceTemplateURILiteral)

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
                return {
                    "resourceTemplates": [{
                        "uriTemplate": RESOURCE_TEMPLATE_URI,
                        "name": "raytone-smoke-template",
                        "title": "Raytone MCP Smoke Template",
                        "description": "A template that resolves to a local smoke resource.",
                        "mimeType": "text/plain"
                    }]
                }
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

    private static func remoteControlPayload(_ status: CodexRuntimeRemoteControlStatus?) -> [String: Any] {
        [
            "status": status?.status ?? "",
            "statusName": SessionStore.remoteControlStatusDisplayName(status?.status),
            "serverName": status?.serverName ?? "",
            "installationID": status?.installationID ?? "",
            "environmentID": status?.environmentID ?? ""
        ]
    }

    private static func remoteClientPayload(_ client: CodexRemoteControlClient) -> [String: Any] {
        [
            "clientID": client.clientID,
            "displayName": client.displayName ?? "",
            "deviceType": client.deviceType ?? "",
            "platform": client.platform ?? "",
            "osVersion": client.osVersion ?? "",
            "deviceModel": client.deviceModel ?? "",
            "appVersion": client.appVersion ?? "",
            "lastSeenAt": client.lastSeenAt.map { $0 as Any } ?? NSNull()
        ]
    }

    private static func realtimeVoicesPayload(_ voices: CodexRealtimeVoices?) -> [String: Any] {
        [
            "v1": voices?.v1 ?? [],
            "v2": voices?.v2 ?? [],
            "defaultV1": voices?.defaultV1 ?? "",
            "defaultV2": voices?.defaultV2 ?? "",
            "v1Count": voices?.v1.count ?? 0,
            "v2Count": voices?.v2.count ?? 0
        ]
    }

    private static func scaffoldPayload(_ result: CodexRuntimeScaffoldResult) -> [String: Any] {
        [
            "kind": result.kind,
            "rootPath": result.rootPath,
            "files": result.files,
            "readBackSnippets": result.readBackSnippets,
            "discoveredPluginID": result.discoveredPluginID ?? "",
            "discoveredSkillPath": result.discoveredSkillPath ?? ""
        ]
    }

    private static func pluginSharePayload(_ context: CodexRuntimePluginShareContext?) -> [String: Any] {
        [
            "remotePluginId": context?.remotePluginID ?? "",
            "remoteVersion": context?.remoteVersion ?? "",
            "discoverability": context?.discoverability ?? "",
            "shareUrl": context?.shareURL ?? "",
            "creatorName": context?.creatorName ?? "",
            "principalCount": context?.sharePrincipals.count ?? 0
        ]
    }

    private static func pluginAppPayload(_ app: CodexRuntimePluginApp) -> [String: Any] {
        [
            "id": app.id,
            "name": app.name,
            "description": app.description ?? "",
            "installUrl": app.installURL ?? "",
            "needsAuth": app.needsAuth
        ]
    }

    private static func pluginInstallPayload(_ result: CodexRuntimePluginInstallResult?) -> [String: Any] {
        [
            "authPolicy": result?.authPolicy ?? "",
            "authPolicyName": result.map { SessionStore.pluginAuthPolicyDisplayName($0.authPolicy) } ?? "",
            "appsNeedingAuth": result?.appsNeedingAuth.map(pluginAppPayload) ?? []
        ]
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

    private static func redactedProfileSharePreview(_ value: String) -> String {
        value
            .replacingOccurrences(
                of: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
                with: "[redacted-email]",
                options: [.regularExpression, .caseInsensitive]
            )
            .replacingOccurrences(
                of: #"sk-[A-Za-z0-9_\-]{8,}"#,
                with: "[redacted-api-key]",
                options: .regularExpression
            )
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

    private static func runStatusName(_ status: RunStatus?) -> String {
        switch status {
        case .running:
            return "running"
        case .succeeded:
            return "succeeded"
        case .failed:
            return "failed"
        case .none:
            return "none"
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
