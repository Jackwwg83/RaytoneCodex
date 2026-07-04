import AppKit
import Foundation
import RaytoneCodexCore
import UniformTypeIdentifiers

@MainActor
final class SessionStore: ObservableObject {
    enum Route: Equatable {
        case thread
        case plugins
        case automation
        case settings
    }

    @Published var prompt: String = ""
    @Published var model: String = ""
    @Published var workspacePath: String
    @Published var sandbox: CodexSandboxMode = .dangerFullAccess
    @Published var approval: CodexApprovalPolicy = .onRequest
    @Published var approvalsReviewer: CodexApprovalsReviewer = .user
    @Published var personality: CodexPersonality = .friendly
    @Published var route: Route = .thread
    @Published var accessMode: AccessMode = .full
    @Published var accessModePopoverPresented = false
    @Published var toolPanel: ToolPanel = .launcher
    @Published var browserURL: URL?
    @Published var browserTitle = "浏览器"
    @Published var browserReloadToken = UUID()
    @Published var browserCanGoBack = false
    @Published var browserCanGoForward = false
    @Published var browserNavigationCommand: BrowserNavigationCommand?
    @Published var browserScreenshotStatusText = ""
    @Published var filePanelPath = ""
    @Published var fileEntries: [WorkspaceFileEntry] = []
    @Published var filePreview: FilePreview?
    @Published var filePanelStatusText = "未加载"
    @Published var fileSearchQuery = ""
    @Published var fileSearchResults: [WorkspaceFileEntry] = []
    @Published var fileSearchStatusText = ""
    @Published var fileSearchIsRunning = false
    @Published var terminalCommand = "pwd && ls -la"
    @Published var terminalRuns: [TerminalCommandRecord] = []
    @Published var terminalIsRunning = false
    @Published var runtimePlugins: [CodexRuntimePlugin] = []
    @Published var runtimeSkills: [CodexRuntimeSkill] = []
    @Published var runtimeHooks: [CodexRuntimeHook] = []
    @Published var runtimeMCPServers: [CodexRuntimeMCPServer] = []
    @Published var runtimeConfig: CodexRuntimeConfig?
    @Published var desktopShowInMenuBar = true
    @Published var desktopShowBottomPanel = true
    @Published var desktopPreventSleepWhileRunning = true
    @Published var desktopTerminalPosition = "底部"
    @Published var desktopAppearance = "跟随系统"
    @Published var desktopOpenTarget = "iTerm2"
    @Published var desktopLanguage = "自动检测"
    @Published var defaultPermissionsEnabled = true
    @Published var defaultFullAccessPermissionsEnabled = false
    @Published var runtimeAccount: CodexRuntimeAccount?
    @Published var runtimeTokenUsage: CodexRuntimeTokenUsage?
    @Published var runtimeRateLimits: CodexRuntimeRateLimits?
    @Published var runtimeRequirements: CodexRuntimeConfigRequirements?
    @Published var runtimeRemoteControlStatus: CodexRuntimeRemoteControlStatus?
    @Published var runtimeApps: [CodexRuntimeAppInfo] = []
    @Published var runtimePermissionProfiles: [CodexRuntimePermissionProfile] = []
    @Published var archivedRuntimeThreads: [CodexRuntimeThreadSummary] = []
    @Published var runtimeThreadSyncStatusText = "未同步"
    @Published var workspaceGitDiff: CodexRuntimeGitDiff?
    @Published var workspaceGitStatusText = ""
    @Published var workspaceWorktrees: [String] = []
    @Published var workspaceBranches: [String] = []
    @Published var workspaceBranchStatusText = "未刷新"
    @Published var workspaceExecutionMode: WorkspaceExecutionMode = .local
    @Published var runtimeCatalogStatusText = "未刷新"
    @Published var runtimeCatalogErrors: [String] = []
    @Published var runtimeCatalogIsRefreshing = false
    @Published var lastMentionInputPreview: [[String: String]] = []
    @Published var settingsPane: SettingsPane = .general
    @Published var providers: [RaytoneProviderConfiguration] = RaytoneProviderConfiguration.defaultProviders
    @Published var selectedProviderID = "openai"
    @Published var codexModelCatalog: [CodexAppServerModel] = []
    @Published var sidecarStatusText = "未启动"
    @Published var modelCatalogStatusText = "未刷新"
    @Published var runtimeSnapshot = CodexRuntimeSnapshot(executable: nil, version: nil)
    @Published var isRunning = false
    @Published var lastCommandPreview = ""
    @Published var lastOutputPath = ""
    @Published var lastRawOutput = ""
    @Published var inspectorTab: InspectorTab = .runtime
    @Published var sidebarSearch = ""
    @Published var showInspector = true
    @Published var projects: [Project]
    @Published var threads: [ChatThread]
    @Published var selectedThreadID: UUID

    private static let readOnlyPermissionsProfile = ":read-only"
    private static let workspacePermissionsProfile = ":workspace"
    private static let dangerFullAccessPermissionsProfile = ":danger-full-access"

    private let service: CodexCLIService
    private let proxyService = RaytoneProxyService()
    private var appServerClient: CodexAppServerClient?
    private var appServerEventsTask: Task<Void, Never>?
    private var appServerItemIDs: [String: UUID] = [:]
    private var activeDiffTranscriptIDs: Set<UUID> = []
    private var pendingApprovalRequestIDs: [UUID: CodexAppServerRequestID] = [:]
    private var activeAppServerTurnID: String?
    private var appServerConnectionState: ConnectionState?
    private var appServerEnvironmentKey: String?
    private var activeProxySession: RaytoneProxySession?
    var appServerEnvironmentOverridesForTesting: [String: String] = [:]

    init(service: CodexCLIService = CodexCLIService()) {
        self.service = service

        let workspacePath = Self.defaultWorkspacePath()
        let primaryProject = Project(
            name: "RaytoneCodex",
            path: workspacePath,
            branch: Self.currentGitBranch(at: workspacePath)
        )
        let localThread = ChatThread(
            title: "新对话",
            projectID: primaryProject.id,
            items: [],
            model: "",
            sandbox: .dangerFullAccess,
            approval: .onRequest,
            approvalsReviewer: .user,
            personality: .friendly
        )
        let demoThread = SampleData.demoThread(projectID: primaryProject.id)
        let debugThread = SampleData.debugThread(projectID: primaryProject.id)
        let secondary = SampleData.secondaryBundle(workspacePath: workspacePath)

        self.workspacePath = workspacePath
        self.filePanelPath = workspacePath
        self.model = localThread.model
        self.sandbox = localThread.sandbox
        self.approval = localThread.approval
        self.approvalsReviewer = localThread.approvalsReviewer
        self.personality = localThread.personality
        self.projects = [primaryProject, secondary.project]
        self.threads = [localThread, demoThread, debugThread] + secondary.threads
        self.selectedThreadID = localThread.id
    }

    var selectedThread: ChatThread {
        threads.first { $0.id == selectedThreadID } ?? threads[0]
    }

    var selectedProject: Project {
        projects.first { $0.id == selectedThread.projectID } ?? projects[0]
    }

    var visibleProjects: [Project] {
        projects.filter { project in
            sidebarSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                visibleThreads(in: project.id).isEmpty == false
        }
    }

    var connectionState: ConnectionState {
        if let appServerConnectionState {
            return appServerConnectionState
        }

        guard runtimeSnapshot.executable != nil else {
            return runtimeSnapshot.errorDescription == nil ? .connecting : .notInstalled
        }
        if let version = runtimeSnapshot.version, !version.isEmpty {
            return .connected(version: version)
        }
        return .disconnected
    }

    var runtimeSummary: String {
        guard let executable = runtimeSnapshot.executable else {
            return runtimeSnapshot.errorDescription ?? "Codex runtime unavailable"
        }

        let version = runtimeSnapshot.version ?? "version unknown"
        return "\(executable.source.rawValue) · \(version)"
    }

    var runtimePath: String {
        runtimeSnapshot.executable?.url.path ?? "Not found"
    }

    var selectedProvider: RaytoneProviderConfiguration {
        providers.first { $0.id == selectedProviderID } ?? providers[0]
    }

    var modelDisplayName: String {
        if selectedProvider.usesSidecar {
            return "\(selectedProvider.displayName) › \(selectedProvider.model)"
        }
        let selectedModel = model.isEmpty ? selectedProvider.model : model
        return codexModelMetadata(id: selectedModel)?.displayName ?? selectedModel
    }

    var selectedCodexModelMetadata: CodexAppServerModel? {
        let selectedModel = model.isEmpty ? selectedProvider.model : model
        return codexModelMetadata(id: selectedModel)
    }

    var runtimeThinkingEnabled: Bool {
        let effort = runtimeConfig?.reasoningEffort?.lowercased()
        let summary = runtimeConfig?.reasoningSummary?.lowercased()
        return effort != "none" && summary != "none"
    }

    var runtimeWorkModeID: String {
        Self.workModeID(for: runtimeConfig?.modelVerbosity)
    }

    var runtimeServiceTierLabel: String {
        Self.serviceTierLabel(for: runtimeConfig?.serviceTier)
    }

    var runtimeMemoryEnabled: Bool {
        let generate = runtimeConfig?.memoryGenerateMemories ?? true
        let use = runtimeConfig?.memoryUseMemories ?? true
        return generate && use
    }

    var runtimeSkipToolAssistedChats: Bool {
        runtimeConfig?.memoryDisableOnExternalContext ?? false
    }

    var runtimeDesktopSettingsSummary: String {
        [
            "菜单栏 \(desktopShowInMenuBar ? "开" : "关")",
            "面板 \(desktopShowBottomPanel ? "开" : "关")",
            desktopTerminalPosition,
            desktopAppearance
        ].joined(separator: " · ")
    }

    private func applyRuntimeConfig(_ config: CodexRuntimeConfig?, fallbackDefaultPermissions: String? = nil) {
        runtimeConfig = config
        if let config {
            applyRuntimeDesktopSettings(config.desktopSettings)
        }
        applyRuntimeDefaultPermissionsProfile(
            config?.defaultPermissions ?? fallbackDefaultPermissions ?? runtimeRequirements?.defaultPermissions
        )
        if let rawReviewer = config?.approvalsReviewer,
           let reviewer = CodexApprovalsReviewer(rawValue: rawReviewer) {
            approvalsReviewer = reviewer
            accessMode = Self.accessMode(for: approval, sandbox: sandbox, approvalsReviewer: reviewer)
            updateSelectedThread { thread in
                thread.approvalsReviewer = reviewer
            }
        }
    }

    private func applyRuntimeDesktopSettings(_ settings: CodexRuntimeDesktopSettings) {
        desktopShowInMenuBar = settings.showInMenuBar ?? true
        desktopShowBottomPanel = settings.showBottomPanel ?? true
        desktopPreventSleepWhileRunning = settings.preventSleepWhileRunning ?? true
        desktopTerminalPosition = settings.terminalPosition ?? "底部"
        desktopAppearance = settings.appearance ?? "跟随系统"
        desktopOpenTarget = settings.openTarget ?? "iTerm2"
        desktopLanguage = settings.language ?? "自动检测"
    }

    private func applyRuntimeDefaultPermissionsProfile(_ profile: String?) {
        guard let profile, !profile.isEmpty else {
            return
        }

        switch profile {
        case Self.readOnlyPermissionsProfile:
            defaultPermissionsEnabled = false
            defaultFullAccessPermissionsEnabled = false
        case Self.dangerFullAccessPermissionsProfile:
            defaultPermissionsEnabled = true
            defaultFullAccessPermissionsEnabled = true
        case Self.workspacePermissionsProfile:
            defaultPermissionsEnabled = true
            defaultFullAccessPermissionsEnabled = false
        default:
            defaultPermissionsEnabled = true
            defaultFullAccessPermissionsEnabled = false
        }
    }

    var execApprovalDisplayName: String {
        Self.approvalName(approval)
    }

    func refreshRuntime() async {
        runtimeSnapshot = await service.inspectRuntime()
        if runtimeSnapshot.executable == nil {
            appServerConnectionState = .notInstalled
        }
    }

    func stopAppServerForTesting() async {
        if let client = appServerClient {
            await client.stop()
        }
        appServerClient = nil
        appServerEventsTask?.cancel()
        appServerEventsTask = nil
        appServerEnvironmentKey = nil
        activeAppServerTurnID = nil
        activeDiffTranscriptIDs.removeAll()
        appServerItemIDs.removeAll()
    }

    func selectThread(_ thread: ChatThread) {
        selectedThreadID = thread.id
        if let project = projects.first(where: { $0.id == thread.projectID }) {
            workspacePath = project.path
        }
        model = thread.model
        sandbox = thread.sandbox
        approval = thread.approval
        approvalsReviewer = thread.approvalsReviewer
        personality = thread.personality
        accessMode = Self.accessMode(
            for: thread.approval,
            sandbox: thread.sandbox,
            approvalsReviewer: thread.approvalsReviewer
        )
        toolPanel = .launcher
        route = .thread
        if thread.appServerThreadID != nil, thread.items.isEmpty {
            Task { await loadRuntimeThreadTranscript(localThreadID: thread.id) }
        }
    }

    func selectThread(_ threadID: UUID) {
        guard let thread = threads.first(where: { $0.id == threadID }) else {
            return
        }
        selectThread(thread)
    }

    func visibleThreads(in projectID: UUID) -> [ChatThread] {
        let query = sidebarSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return threads
            .filter { thread in
                guard thread.projectID == projectID else { return false }
                guard !query.isEmpty else { return true }
                return thread.title.lowercased().contains(query) ||
                    thread.preview.lowercased().contains(query)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func runPrompt() async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            return
        }

        if isRunning {
            await steerRunningTurn(trimmedPrompt)
            return
        }

        prompt = ""
        if await handleSlashCommand(trimmedPrompt) {
            return
        }

        await runAgentPrompt(trimmedPrompt)
    }

    private func runAgentPrompt(_ runtimePrompt: String, displayedPrompt: String? = nil) async {
        isRunning = true
        let userMessage = displayedPrompt ?? runtimePrompt

        updateSelectedThread { thread in
            thread.model = model
            thread.sandbox = sandbox
            thread.approval = approval
            thread.approvalsReviewer = approvalsReviewer
            thread.personality = personality
            thread.items.append(TranscriptItem(kind: .userMessage(userMessage)))
        }

        do {
            try await runPromptWithAppServer(runtimePrompt)
            return
        } catch {
            if selectedProvider.usesSidecar {
                updateSelectedThread { thread in
                    thread.items.append(TranscriptItem(kind: .notice(Notice(
                        level: .error,
                        text: "多 Provider 运行时不可用：\(error.localizedDescription)"
                    ))))
                }
                isRunning = false
                await refreshRuntime()
                return
            }
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "app-server 暂不可用，已降级到 codex exec：\(error.localizedDescription)"
                ))))
            }
            await runPromptWithExec(runtimePrompt)
        }

        isRunning = false
        await refreshRuntime()
    }

    private func handleSlashCommand(_ trimmedPrompt: String) async -> Bool {
        guard trimmedPrompt.hasPrefix("/") else {
            return false
        }

        let parts = trimmedPrompt.split(maxSplits: 1, whereSeparator: \.isWhitespace)
        guard let rawCommand = parts.first else {
            return false
        }

        let command = String(rawCommand).lowercased()
        let arguments = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

        switch command {
        case "/clear":
            resetThread()
            return true

        case "/diff":
            await runSlashShellCommand(
                displayedPrompt: trimmedPrompt,
                command: "git status --short --branch && git diff --stat && git diff -- .",
                sandbox: .readOnly,
                appendDiffFileChanges: true
            )
            return true

        case "/test":
            await runSlashShellCommand(
                displayedPrompt: trimmedPrompt,
                command: arguments.isEmpty ? detectedTestCommand() : arguments,
                sandbox: sandbox == .readOnly ? .workspaceWrite : sandbox,
                appendDiffFileChanges: false
            )
            return true

        case "/review":
            await runReviewOfCurrentChanges(displayedPrompt: trimmedPrompt, instructions: arguments.isEmpty ? nil : arguments)
            return true

        case "/init":
            let suffix = arguments.isEmpty ? "" : "\n\n补充要求：\(arguments)"
            await runAgentPrompt(
                "请根据当前项目生成或更新 AGENTS.md，记录构建、测试、代码风格、运行验证和协作约束。保留已有重要说明，只补充真实可验证的信息。\(suffix)",
                displayedPrompt: trimmedPrompt
            )
            return true

        case "/explain":
            guard !arguments.isEmpty else {
                appendSlashNotice(displayedPrompt: trimmedPrompt, text: "请在 /explain 后添加要解释的文件、符号或问题。")
                return true
            }
            await runAgentPrompt(
                "请解释下面这个文件、符号或问题，并结合当前项目上下文给出准确说明：\(arguments)",
                displayedPrompt: trimmedPrompt
            )
            return true

        default:
            return false
        }
    }

    private func appendSlashNotice(displayedPrompt: String, text: String) {
        updateSelectedThread { thread in
            thread.model = model
            thread.sandbox = sandbox
            thread.approval = approval
            thread.approvalsReviewer = approvalsReviewer
            thread.personality = personality
            thread.items.append(TranscriptItem(kind: .userMessage(displayedPrompt)))
            thread.items.append(TranscriptItem(kind: .notice(Notice(level: .warning, text: text))))
        }
    }

    private func runSlashShellCommand(
        displayedPrompt: String,
        command: String,
        sandbox commandSandbox: CodexSandboxMode,
        appendDiffFileChanges: Bool
    ) async {
        isRunning = true
        let transcriptID = UUID()

        updateSelectedThread { thread in
            thread.model = model
            thread.sandbox = sandbox
            thread.approval = approval
            thread.approvalsReviewer = approvalsReviewer
            thread.personality = personality
            thread.items.append(TranscriptItem(kind: .userMessage(displayedPrompt)))
            thread.items.append(TranscriptItem(
                id: transcriptID,
                kind: .command(CommandRun(
                    command: command,
                    directory: Project.abbreviate(workspacePath),
                    output: "正在通过 app-server command/exec 运行…",
                    status: .running
                ))
            ))
        }

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommand(
                ["/bin/zsh", "-lc", command],
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: commandSandbox,
                timeoutMs: 120_000
            )
            let output = [result.stdout, result.stderr]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")
            let renderedOutput = output.isEmpty ? "命令无输出" : output

            lastCommandPreview = command
            lastRawOutput = renderedOutput

            updateSelectedThread { thread in
                if let index = thread.items.firstIndex(where: { $0.id == transcriptID }) {
                    thread.items[index].kind = .command(CommandRun(
                        command: command,
                        directory: Project.abbreviate(workspacePath),
                        output: renderedOutput,
                        exitCode: result.exitCode,
                        status: result.exitCode == 0 ? .succeeded : .failed
                    ))
                }
            }

            if appendDiffFileChanges {
                workspaceGitStatusText = result.stdout
                workspaceGitDiff = CodexRuntimeGitDiff(sha: nil, diff: result.stdout)
                let changes = Self.fileChanges(fromUnifiedDiff: result.stdout)
                if changes.isEmpty {
                    updateSelectedThread { thread in
                        thread.items.append(TranscriptItem(kind: .notice(Notice(
                            level: .info,
                            text: "当前工作区没有可显示的未提交 diff。"
                        ))))
                    }
                } else {
                    updateSelectedThread { thread in
                        for change in changes {
                            thread.items.append(TranscriptItem(kind: .fileChange(change)))
                        }
                    }
                }
            }
        } catch {
            updateSelectedThread { thread in
                if let index = thread.items.firstIndex(where: { $0.id == transcriptID }) {
                    thread.items[index].kind = .command(CommandRun(
                        command: command,
                        directory: Project.abbreviate(workspacePath),
                        output: error.localizedDescription,
                        exitCode: nil,
                        status: .failed
                    ))
                }
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .error,
                    text: "slash 命令执行失败：\(error.localizedDescription)"
                ))))
            }
        }

        isRunning = false
        await refreshRuntime()
    }

    private func detectedTestCommand() -> String {
        let workspaceURL = URL(fileURLWithPath: workspacePath)
        let fileManager = FileManager.default
        let scriptURL = workspaceURL.appendingPathComponent("script/test.sh")
        if fileManager.fileExists(atPath: scriptURL.path) {
            return "bash script/test.sh"
        }

        if fileManager.fileExists(atPath: workspaceURL.appendingPathComponent("Package.swift").path) {
            return "swift test"
        }

        if fileManager.fileExists(atPath: workspaceURL.appendingPathComponent("package.json").path) {
            return "npm test"
        }

        if fileManager.fileExists(atPath: workspaceURL.appendingPathComponent("pyproject.toml").path) ||
            fileManager.fileExists(atPath: workspaceURL.appendingPathComponent("pytest.ini").path) {
            return "python -m pytest"
        }

        return "test -x ./test.sh && ./test.sh || (echo '未找到可自动识别的测试命令；请用 /test <命令> 指定。' >&2; exit 2)"
    }

    private static func reviewFallbackPrompt(instructions: String?) -> String {
        let trimmedInstructions = instructions?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let suffix = trimmedInstructions.isEmpty ? "" : "\n\n补充要求：\(trimmedInstructions)"
        return "请审查当前工作区变更，重点找 bug、行为回归、风险和缺失测试。先读取 git status 和 git diff，再按严重程度给出结论。\(suffix)"
    }

    private static func isStructuredReviewPayload(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{"),
              let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return object["findings"] != nil && object["overall_correctness"] != nil
    }

    private func steerRunningTurn(_ trimmedPrompt: String) async {
        prompt = ""
        updateSelectedThread { thread in
            thread.items.append(TranscriptItem(kind: .userMessage(trimmedPrompt)))
        }

        guard let client = appServerClient,
              let threadID = selectedThread.appServerThreadID,
              let turnID = activeAppServerTurnID else {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "当前运行时不支持继续输入；请等待这一轮完成后再发送。"
                ))))
            }
            return
        }

        do {
            let mentions = await pluginMentions(in: trimmedPrompt)
            try await client.steer(
                threadID: threadID,
                expectedTurnID: turnID,
                prompt: trimmedPrompt,
                mentions: mentions
            )
        } catch {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "继续输入未能发送给 app-server：\(error.localizedDescription)"
                ))))
            }
        }
    }

    func interruptRunningTurn() async {
        guard isRunning,
              let client = appServerClient,
              let threadID = selectedThread.appServerThreadID,
              let turnID = activeAppServerTurnID else {
            return
        }

        do {
            try await client.interrupt(threadID: threadID, turnID: turnID)
        } catch {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "无法停止当前轮次：\(error.localizedDescription)"
                ))))
            }
        }
    }

    func pauseActiveGoal() async {
        let shouldUpdateRuntimeGoal = selectedThread.activeGoal?.runtimeBacked == true
        if shouldUpdateRuntimeGoal,
           let client = appServerClient,
           let threadID = selectedThread.appServerThreadID {
            do {
                let goal = try await client.setThreadGoal(threadID: threadID, status: .paused)
                applyRuntimeGoal(goal)
                runtimeCatalogStatusText = "thread/goal/set：paused"
            } catch {
                updateSelectedThread { thread in
                    thread.items.append(TranscriptItem(kind: .notice(Notice(
                        level: .warning,
                        text: "无法暂停目标：\(error.localizedDescription)"
                    ))))
                }
            }
        }

        if isRunning {
            await interruptRunningTurn()
        } else if !shouldUpdateRuntimeGoal {
            clearSelectedThreadActiveGoal()
        }
    }

    func clearActiveGoal() async {
        guard selectedThread.activeGoal?.runtimeBacked == true else {
            clearSelectedThreadActiveGoal()
            return
        }

        guard let client = appServerClient,
              let threadID = selectedThread.appServerThreadID else {
            clearSelectedThreadActiveGoal()
            return
        }

        do {
            let cleared = try await client.clearThreadGoal(threadID: threadID)
            clearRuntimeGoal(threadID: threadID)
            runtimeCatalogStatusText = cleared ? "thread/goal/clear：已清除" : "thread/goal/clear：没有活动目标"
        } catch {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "无法清除目标：\(error.localizedDescription)"
                ))))
            }
        }
    }

    func respondToAppServerApproval(itemID: UUID, decision: ApprovalRequest.Decision) async {
        guard let requestID = pendingApprovalRequestIDs.removeValue(forKey: itemID),
              let client = appServerClient else {
            return
        }

        let appServerDecision: CodexAppServerApprovalDecision
        switch decision {
        case .pending:
            return
        case .approved:
            appServerDecision = .accept
        case .approvedAlways:
            appServerDecision = .acceptForSession
        case .denied:
            appServerDecision = .decline
        }

        do {
            try await client.respondApproval(requestID: requestID, decision: appServerDecision)
        } catch {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "审批结果未能回传给 app-server：\(error.localizedDescription)"
                ))))
            }
        }
    }

    func chooseWorkspace() {
        let panel = NSOpenPanel()
        panel.title = "Choose Workspace"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: workspacePath)

        if panel.runModal() == .OK, let url = panel.url {
            workspacePath = url.path
            updateSelectedProject(path: url.path)
        }
    }

    func resetThread() {
        newThread(in: selectedProject.id)
        lastCommandPreview = ""
        lastOutputPath = ""
        lastRawOutput = ""
    }

    func chooseAccessMode(_ mode: AccessMode) {
        accessMode = mode
        switch mode {
        case .ask:
            approval = .onRequest
            sandbox = .workspaceWrite
            approvalsReviewer = .user
        case .autoReview:
            approval = .onFailure
            sandbox = .workspaceWrite
            approvalsReviewer = .autoReview
        case .full:
            approval = .never
            sandbox = .dangerFullAccess
            approvalsReviewer = .user
        }

        updateSelectedThread { thread in
            thread.approval = approval
            thread.sandbox = sandbox
            thread.approvalsReviewer = approvalsReviewer
        }
    }

    var runtimeDefaultPermissionsProfile: String {
        if defaultFullAccessPermissionsEnabled {
            return Self.dangerFullAccessPermissionsProfile
        }
        return defaultPermissionsEnabled ? Self.workspacePermissionsProfile : Self.readOnlyPermissionsProfile
    }

    func saveRuntimeDefaultPermissions(defaultEnabled: Bool? = nil, fullAccess: Bool? = nil) async {
        var nextDefaultEnabled = defaultEnabled ?? defaultPermissionsEnabled
        var nextFullAccess = fullAccess ?? defaultFullAccessPermissionsEnabled
        if nextFullAccess {
            nextDefaultEnabled = true
        }
        if !nextDefaultEnabled {
            nextFullAccess = false
        }

        defaultPermissionsEnabled = nextDefaultEnabled
        defaultFullAccessPermissionsEnabled = nextFullAccess
        let profile = runtimeDefaultPermissionsProfile

        runtimeCatalogStatusText = "正在写入 default_permissions…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(
                keyPath: "default_permissions",
                value: .string(profile)
            )
            let config = try await client.readConfig(cwd: workspacePath, includeLayers: true)
            applyRuntimeConfig(config, fallbackDefaultPermissions: profile)
            runtimeCatalogStatusText = "default_permissions 已写入 config.toml：\(profile)"
        } catch {
            applyRuntimeDefaultPermissionsProfile(runtimeConfig?.defaultPermissions)
            runtimeCatalogStatusText = "default_permissions 写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveRuntimeApprovalPolicy(_ policy: CodexApprovalPolicy) async {
        approval = policy
        accessMode = Self.accessMode(for: approval, sandbox: sandbox, approvalsReviewer: approvalsReviewer)
        updateSelectedThread { thread in
            thread.approval = policy
        }

        runtimeCatalogStatusText = "正在写入 approval_policy…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(
                keyPath: "approval_policy",
                value: .string(policy.appServerValue)
            )
            runtimeCatalogStatusText = "approval_policy 已写入 config.toml"
            applyRuntimeConfig(try? await client.readConfig(cwd: workspacePath, includeLayers: true))
        } catch {
            runtimeCatalogStatusText = "approval_policy 写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveRuntimeSandboxMode(_ mode: CodexSandboxMode) async {
        sandbox = mode
        accessMode = Self.accessMode(for: approval, sandbox: sandbox, approvalsReviewer: approvalsReviewer)
        updateSelectedThread { thread in
            thread.sandbox = mode
        }

        runtimeCatalogStatusText = "正在写入 sandbox_mode…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(
                keyPath: "sandbox_mode",
                value: .string(mode.rawValue)
            )
            runtimeCatalogStatusText = "sandbox_mode 已写入 config.toml"
            applyRuntimeConfig(try? await client.readConfig(cwd: workspacePath, includeLayers: true))
        } catch {
            runtimeCatalogStatusText = "sandbox_mode 写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveRuntimeApprovalsReviewer(_ reviewer: CodexApprovalsReviewer) async {
        approvalsReviewer = reviewer
        accessMode = Self.accessMode(for: approval, sandbox: sandbox, approvalsReviewer: approvalsReviewer)
        updateSelectedThread { thread in
            thread.approvalsReviewer = reviewer
        }

        runtimeCatalogStatusText = "正在写入 approvals_reviewer…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(
                keyPath: "approvals_reviewer",
                value: .string(reviewer.rawValue)
            )
            runtimeCatalogStatusText = "approvals_reviewer 已写入 config.toml"
            applyRuntimeConfig(try? await client.readConfig(cwd: workspacePath, includeLayers: true))
        } catch {
            runtimeCatalogStatusText = "approvals_reviewer 写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveRuntimeAutoReviewEnabled(_ enabled: Bool) async {
        await saveRuntimeApprovalsReviewer(enabled ? .autoReview : .user)
    }

    func saveRuntimeWorkMode(id: String) async {
        let verbosity = Self.modelVerbosityValue(forWorkModeID: id)
        runtimeCatalogStatusText = "正在写入 model_verbosity…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(
                keyPath: "model_verbosity",
                value: .string(verbosity)
            )
            applyRuntimeConfig(try await client.readConfig(cwd: workspacePath, includeLayers: true))
            runtimeCatalogStatusText = "model_verbosity 已写入 config.toml：\(verbosity)"
        } catch {
            runtimeCatalogStatusText = "工作模式写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveRuntimeServiceTier(label: String) async {
        let serviceTier = Self.serviceTierConfigValue(for: label)
        runtimeCatalogStatusText = "正在写入 service_tier…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(
                keyPath: "service_tier",
                value: .string(serviceTier)
            )
            applyRuntimeConfig(try await client.readConfig(cwd: workspacePath, includeLayers: true))
            runtimeCatalogStatusText = "service_tier 已写入 config.toml：\(serviceTier)"
        } catch {
            runtimeCatalogStatusText = "service_tier 写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveRuntimeMemoryEnabled(_ enabled: Bool) async {
        runtimeCatalogStatusText = "正在写入 memories.generate_memories/use_memories…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.batchWriteConfig(edits: [
                CodexConfigWriteEdit(keyPath: "memories.generate_memories", value: .bool(enabled)),
                CodexConfigWriteEdit(keyPath: "memories.use_memories", value: .bool(enabled))
            ])
            applyRuntimeConfig(try await client.readConfig(cwd: workspacePath, includeLayers: true))
            runtimeCatalogStatusText = enabled ? "Codex 记忆已开启" : "Codex 记忆已关闭"
        } catch {
            runtimeCatalogStatusText = "记忆设置写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveRuntimeSkipToolAssistedChats(_ enabled: Bool) async {
        runtimeCatalogStatusText = "正在写入 memories.disable_on_external_context…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(
                keyPath: "memories.disable_on_external_context",
                value: .bool(enabled)
            )
            applyRuntimeConfig(try await client.readConfig(cwd: workspacePath, includeLayers: true))
            runtimeCatalogStatusText = enabled ? "工具辅助对话将跳过记忆生成" : "工具辅助对话可生成记忆"
        } catch {
            runtimeCatalogStatusText = "记忆跳过规则写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveRuntimeShowInMenuBar(_ enabled: Bool) async {
        desktopShowInMenuBar = enabled
        await saveRuntimeDesktopSetting(key: "show_in_menu_bar", value: .bool(enabled), statusName: "菜单栏显示")
    }

    func saveRuntimeShowBottomPanel(_ enabled: Bool) async {
        desktopShowBottomPanel = enabled
        await saveRuntimeDesktopSetting(key: "show_bottom_panel", value: .bool(enabled), statusName: "底部面板")
    }

    func saveRuntimePreventSleepWhileRunning(_ enabled: Bool) async {
        desktopPreventSleepWhileRunning = enabled
        await saveRuntimeDesktopSetting(key: "prevent_sleep_while_running", value: .bool(enabled), statusName: "防止系统休眠")
    }

    func saveRuntimeTerminalPosition(_ position: String) async {
        desktopTerminalPosition = position
        await saveRuntimeDesktopSetting(key: "terminal_position", value: .string(position), statusName: "默认终端位置")
    }

    func saveRuntimeAppearance(_ appearance: String) async {
        desktopAppearance = appearance
        await saveRuntimeDesktopSetting(key: "appearance", value: .string(appearance), statusName: "主题")
    }

    func saveRuntimeOpenTarget(_ target: String) async {
        desktopOpenTarget = target
        await saveRuntimeDesktopSetting(key: "open_target", value: .string(target), statusName: "默认打开目标")
    }

    func saveRuntimeLanguage(_ language: String) async {
        desktopLanguage = language
        await saveRuntimeDesktopSetting(key: "language", value: .string(language), statusName: "语言")
    }

    private func saveRuntimeDesktopSetting(key: String, value: JSONValue, statusName: String) async {
        runtimeCatalogStatusText = "正在写入 desktop.raytone.\(key)…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(
                keyPath: "desktop.raytone.\(key)",
                value: value
            )
            applyRuntimeConfig(try await client.readConfig(cwd: workspacePath, includeLayers: true))
            runtimeCatalogStatusText = "\(statusName) 已写入 desktop.raytone.\(key)"
        } catch {
            if let settings = runtimeConfig?.desktopSettings {
                applyRuntimeDesktopSettings(settings)
            }
            runtimeCatalogStatusText = "\(statusName) 写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveRuntimePersonality(_ newPersonality: CodexPersonality) async {
        personality = newPersonality
        updateSelectedThread { thread in
            thread.personality = newPersonality
        }

        guard let threadID = selectedThread.appServerThreadID else {
            runtimeCatalogStatusText = "个性已更新，将用于新对话和下一轮 Codex 请求"
            return
        }

        runtimeCatalogStatusText = "正在调用 thread/settings/update…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.updateThreadPersonality(threadID: threadID, personality: newPersonality)
            runtimeCatalogStatusText = "thread/settings/update：个性已提交"
        } catch {
            runtimeCatalogStatusText = "个性更新失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func startVoiceInput() {
        let didStart = NSApp.sendAction(Selector(("startDictation:")), to: nil, from: nil)
        guard !didStart else { return }

        updateSelectedThread { thread in
            thread.items.append(TranscriptItem(kind: .notice(Notice(
                level: .info,
                text: "系统没有接受听写命令。请确认 macOS 已启用听写，或把焦点放到输入框后再点麦克风。"
            ))))
        }
    }

    func openToolPanel(_ panel: ToolPanel) {
        showInspector = true
        toolPanel = panel
        if panel == .files {
            Task { await loadFilePanelDirectory() }
        }
    }

    func connectWorkspaceFiles() {
        showInspector = true
        toolPanel = .files
        Task { await loadFilePanelDirectory(workspacePath) }
    }

    func chooseFilesForPrompt() {
        let panel = NSOpenPanel()
        panel.title = "添加文件"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: workspacePath)

        guard panel.runModal() == .OK else { return }
        Task { await addFileReferencesToPrompt(paths: panel.urls.map(\.path)) }
    }

    func chooseImagesForPrompt() {
        let panel = NSOpenPanel()
        panel.title = "添加图片"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: workspacePath)
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP, .heic, .tiff]

        guard panel.runModal() == .OK else { return }
        Task { await addFileReferencesToPrompt(paths: panel.urls.map(\.path), label: "图片") }
    }

    func addFileReferencesToPrompt(paths: [String], label: String = "文件") async {
        let normalizedPaths = paths
            .map { URL(fileURLWithPath: $0).standardizedFileURL.path }
            .filter { !$0.isEmpty }
        guard !normalizedPaths.isEmpty else { return }

        let references = normalizedPaths.map { Self.promptReferencePath(for: $0, workspacePath: workspacePath) }
        let block = """
        请参考以下\(label)：
        \(references.map { "- `\($0)`" }.joined(separator: "\n"))
        """

        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        prompt = trimmed.isEmpty ? block : "\(trimmed)\n\n\(block)"
        await openFilePathInPanel(normalizedPaths[0])
    }

    func openRecommendedFile(_ path: String) {
        Task { await openFilePathInPanel(Self.absoluteWorkspacePath(path, workspacePath: workspacePath)) }
    }

    func openFilePathInPanel(_ path: String) async {
        let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        showInspector = true
        toolPanel = .files

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: normalizedPath, isDirectory: &isDirectory) else {
            filePanelStatusText = "文件不存在：\(Project.abbreviate(normalizedPath))"
            return
        }

        if isDirectory.boolValue {
            await loadFilePanelDirectory(normalizedPath)
            return
        }

        let parent = URL(fileURLWithPath: normalizedPath).deletingLastPathComponent().path
        await loadFilePanelDirectory(parent)
        let entry = fileEntries.first { $0.path == normalizedPath } ?? WorkspaceFileEntry(
            name: URL(fileURLWithPath: normalizedPath).lastPathComponent,
            path: normalizedPath,
            isDirectory: false,
            isFile: true
        )
        await openFileEntry(entry)
    }

    func loadFilePanelDirectory(_ path: String? = nil) async {
        let targetPath = path ?? (filePanelPath.isEmpty ? workspacePath : filePanelPath)
        filePanelStatusText = "正在读取…"
        filePreview = nil

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let entries = try await client.readDirectory(path: targetPath)
            filePanelPath = targetPath
            fileEntries = entries.map {
                WorkspaceFileEntry(
                    name: $0.fileName,
                    path: $0.path,
                    isDirectory: $0.isDirectory,
                    isFile: $0.isFile
                )
            }
            filePanelStatusText = "\(fileEntries.count) 项"
        } catch {
            filePanelStatusText = "读取失败：\(error.localizedDescription)"
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "文件面板无法通过 app-server 读取目录：\(error.localizedDescription)"
                ))))
            }
        }
    }

    func searchWorkspaceFiles() async {
        let query = fileSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            fileSearchResults = []
            fileSearchStatusText = ""
            return
        }

        fileSearchIsRunning = true
        fileSearchStatusText = "正在搜索…"

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let results = try await client.fuzzyFileSearch(query: query, roots: [workspacePath])
            fileSearchResults = results.map {
                WorkspaceFileEntry(
                    name: $0.fileName,
                    path: $0.path,
                    isDirectory: $0.isDirectory,
                    isFile: $0.isFile
                )
            }
            fileSearchStatusText = fileSearchResults.isEmpty ? "未找到匹配文件" : "\(fileSearchResults.count) 个匹配"
        } catch {
            fileSearchResults = []
            fileSearchStatusText = "搜索失败：\(error.localizedDescription)"
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "文件搜索无法通过 app-server 完成：\(error.localizedDescription)"
                ))))
            }
        }

        fileSearchIsRunning = false
    }

    func clearFileSearch() {
        fileSearchQuery = ""
        fileSearchResults = []
        fileSearchStatusText = ""
    }

    func openParentDirectoryInFilePanel() async {
        let parent = URL(fileURLWithPath: filePanelPath).deletingLastPathComponent().path
        guard parent != filePanelPath else { return }
        await loadFilePanelDirectory(parent)
    }

    func openFileEntry(_ entry: WorkspaceFileEntry) async {
        if entry.isDirectory {
            await loadFilePanelDirectory(entry.path)
            return
        }

        filePanelStatusText = "正在读取文件…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let data = try await client.readFile(path: entry.path)
            let maxBytes = 120_000
            let previewData = data.prefix(maxBytes)
            let text = String(data: previewData, encoding: .utf8)
                ?? String(decoding: previewData, as: UTF8.self)
            filePreview = FilePreview(
                path: entry.path,
                text: text,
                isTruncated: data.count > maxBytes
            )
            filePanelStatusText = Project.abbreviate(entry.path)
        } catch {
            filePanelStatusText = "读取失败：\(error.localizedDescription)"
        }
    }

    func revealSelectedFileInFinder() {
        guard let path = filePreview?.path ?? fileEntries.first?.path else {
            NSWorkspace.shared.selectFile(workspacePath, inFileViewerRootedAtPath: workspacePath)
            return
        }
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: URL(fileURLWithPath: path).deletingLastPathComponent().path)
    }

    func runTerminalCommand() async {
        let command = terminalCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty, !terminalIsRunning else { return }

        terminalIsRunning = true
        let recordID = UUID()
        terminalRuns.append(TerminalCommandRecord(id: recordID, command: command))

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommand(
                ["/bin/zsh", "-lc", command],
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: sandbox
            )
            let output = [result.stdout, result.stderr]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")
            updateTerminalRun(
                id: recordID,
                output: output.isEmpty ? "命令无输出" : output,
                exitCode: result.exitCode,
                status: result.exitCode == 0 ? .succeeded : .failed
            )
        } catch {
            updateTerminalRun(
                id: recordID,
                output: error.localizedDescription,
                exitCode: nil,
                status: .failed
            )
        }

        terminalIsRunning = false
    }

    func openBrowserAddress(_ address: String) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let url: URL?
        if trimmed.hasPrefix("/") || trimmed.hasPrefix("~") {
            let expanded = (trimmed as NSString).expandingTildeInPath
            url = URL(fileURLWithPath: expanded)
        } else if let parsed = URL(string: trimmed), parsed.scheme != nil {
            url = parsed
        } else {
            url = URL(string: "https://\(trimmed)")
        }

        guard let url else { return }
        browserURL = url
        browserTitle = url.isFileURL ? url.lastPathComponent : (url.host ?? url.absoluteString)
        browserCanGoBack = false
        browserCanGoForward = false
        openToolPanel(.browser)
    }

    func openBrowserExternally() {
        guard let url = browserURL else { return }
        NSWorkspace.shared.open(url)
    }

    func newBrowserTab() {
        browserURL = nil
        browserTitle = "浏览器"
        browserCanGoBack = false
        browserCanGoForward = false
        browserNavigationCommand = nil
        browserScreenshotStatusText = ""
        openToolPanel(.browser)
    }

    func reloadBrowserPanel() {
        browserReloadToken = UUID()
    }

    func goBackInBrowser() {
        browserNavigationCommand = BrowserNavigationCommand(action: .back)
    }

    func goForwardInBrowser() {
        browserNavigationCommand = BrowserNavigationCommand(action: .forward)
    }

    func updateBrowserNavigationState(
        url: URL?,
        title: String?,
        canGoBack: Bool,
        canGoForward: Bool
    ) {
        browserCanGoBack = canGoBack
        browserCanGoForward = canGoForward
        if let url {
            browserURL = url
        }
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedTitle.isEmpty {
            browserTitle = trimmedTitle
        } else if let url {
            browserTitle = url.isFileURL ? url.lastPathComponent : (url.host ?? url.absoluteString)
        }
    }

    func captureBrowserPanelScreenshot() {
        let directory = URL(fileURLWithPath: workspacePath).appendingPathComponent("screenshots")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = directory.appendingPathComponent("raytonecodex-browser-\(formatter.string(from: Date())).png")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-x", url.path]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            browserScreenshotStatusText = process.terminationStatus == 0 ? Project.abbreviate(url.path) : "截图失败"
        } catch {
            browserScreenshotStatusText = "截图失败：\(error.localizedDescription)"
        }
    }

    func refreshModelCatalog() async {
        modelCatalogStatusText = "正在从 app-server 读取…"
        do {
            let client = try await ensureAppServerClient()
            let models = try await client.listModels(limit: 100, includeHidden: false)
            codexModelCatalog = models
            let modelIDs = models.map(\.id)
            if !modelIDs.isEmpty,
               let openAIIndex = providers.firstIndex(where: { $0.id == "openai" }) {
                providers[openAIIndex].models = modelIDs
                if model.isEmpty,
                   let defaultModel = models.first(where: \.isDefault)?.id ?? modelIDs.first {
                    model = defaultModel
                    providers[openAIIndex].model = defaultModel
                    updateSelectedThread { thread in
                        thread.model = defaultModel
                    }
                }
            }
            modelCatalogStatusText = modelIDs.isEmpty ? "app-server 未返回模型" : "已读取 \(modelIDs.count) 个模型"
        } catch {
            modelCatalogStatusText = "读取失败：\(error.localizedDescription)"
        }
    }

    func refreshRuntimeCatalog(forceReloadSkills: Bool = false) async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在从 app-server 读取…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            var errors: [String] = []

            do {
                let catalog = try await client.listPluginCatalog(cwds: [workspacePath])
                if catalog.plugins.isEmpty {
                    let installed = try await client.listInstalledPluginCatalog(cwds: [workspacePath])
                    runtimePlugins = installed.plugins
                    errors.append(contentsOf: installed.marketplaceLoadErrors)
                } else {
                    runtimePlugins = catalog.plugins
                    errors.append(contentsOf: catalog.marketplaceLoadErrors)
                }
            } catch {
                errors.append("plugin/list：\(error.localizedDescription)")
                do {
                    let installed = try await client.listInstalledPluginCatalog(cwds: [workspacePath])
                    runtimePlugins = installed.plugins
                    errors.append(contentsOf: installed.marketplaceLoadErrors)
                } catch {
                    errors.append("plugin/installed：\(error.localizedDescription)")
                }
            }

            do {
                let catalog = try await client.listSkills(cwds: [workspacePath], forceReload: forceReloadSkills)
                runtimeSkills = catalog.skills
                errors.append(contentsOf: catalog.errors)
            } catch {
                errors.append("skills/list：\(error.localizedDescription)")
            }
            runtimeCatalogErrors = errors
            runtimeCatalogStatusText = "app-server：\(runtimePlugins.count) 个插件 · \(runtimeSkills.count) 个技能 · 正在读取设置…"

            do {
                applyRuntimeConfig(try await client.readConfig(cwd: workspacePath, includeLayers: true))
            } catch {
                errors.append("config/read：\(error.localizedDescription)")
            }

            do {
                let catalog = try await client.listHooks(cwds: [workspacePath])
                runtimeHooks = catalog.hooks
                errors.append(contentsOf: catalog.warnings.map { "hooks warning：\($0)" })
                errors.append(contentsOf: catalog.errors.map { "hooks error：\($0)" })
            } catch {
                errors.append("hooks/list：\(error.localizedDescription)")
            }

            do {
                let catalog = try await client.listMCPServerStatus(threadID: selectedThread.appServerThreadID)
                runtimeMCPServers = catalog.servers
            } catch {
                errors.append("mcpServerStatus/list：\(error.localizedDescription)")
            }

            runtimeCatalogErrors = errors
            runtimeCatalogStatusText = "app-server：\(runtimePlugins.count) 个插件 · \(runtimeSkills.count) 个技能 · \(runtimeMCPServers.count) 个 MCP · \(runtimeHooks.count) 个钩子"
        } catch {
            runtimeCatalogStatusText = "app-server 读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func refreshRuntimeConfiguration() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在读取 config/read…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            applyRuntimeConfig(try await client.readConfig(cwd: workspacePath, includeLayers: true))
            runtimeCatalogStatusText = "config/read：\(runtimeConfig?.layerCount ?? 0) 个配置层"
        } catch {
            runtimeCatalogStatusText = "config/read 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    func refreshRuntimeMCPServers() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在读取 mcpServerStatus/list…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let catalog = try await client.listMCPServerStatus(threadID: selectedThread.appServerThreadID)
            runtimeMCPServers = catalog.servers
            runtimeCatalogStatusText = "mcpServerStatus/list：\(catalog.servers.count) 个服务器"
        } catch {
            runtimeCatalogStatusText = "mcpServerStatus/list 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    func refreshRuntimeHooks() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在读取 hooks/list…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let catalog = try await client.listHooks(cwds: [workspacePath])
            runtimeHooks = catalog.hooks
            runtimeCatalogErrors = catalog.warnings.map { "hooks warning：\($0)" } + catalog.errors.map { "hooks error：\($0)" }
            runtimeCatalogStatusText = "hooks/list：\(catalog.hooks.count) 个钩子"
        } catch {
            runtimeCatalogStatusText = "hooks/list 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    func refreshAccountUsageRuntime() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在读取账户和用量…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            var errors: [String] = []

            do {
                runtimeAccount = try await client.readAccount(refreshToken: false)
            } catch {
                errors.append("account/read：\(error.localizedDescription)")
            }

            do {
                runtimeTokenUsage = try await client.readAccountTokenUsage()
            } catch {
                errors.append("account/usage/read：\(error.localizedDescription)")
            }

            do {
                runtimeRateLimits = try await client.readAccountRateLimits()
            } catch {
                errors.append("account/rateLimits/read：\(error.localizedDescription)")
            }

            runtimeCatalogErrors = errors
            let accountLabel = runtimeAccount.map { Self.accountDisplayName($0) } ?? "未返回账户"
            let tokenLabel = runtimeTokenUsage?.lifetimeTokens.map(Self.compactNumber) ?? "未知 token"
            runtimeCatalogStatusText = "账户：\(accountLabel) · 累计 \(tokenLabel)"
        } catch {
            runtimeCatalogStatusText = "账户读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func refreshArchivedThreads() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在读取 thread/list archived=true…"
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let catalog = try await client.listThreads(archived: true, cwd: nil, limit: 50)
            archivedRuntimeThreads = catalog.threads
            runtimeCatalogStatusText = "thread/list：\(catalog.threads.count) 个已归档对话"
        } catch {
            runtimeCatalogStatusText = "已归档对话读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    func refreshRuntimeThreads(searchTerm: String? = nil, limit: Int = 50) async {
        runtimeThreadSyncStatusText = "正在读取 thread/list…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let catalog = try await client.listThreads(
                archived: false,
                cwd: nil,
                limit: limit,
                searchTerm: searchTerm
            )
            mergeRuntimeThreads(catalog.threads)
            runtimeThreadSyncStatusText = "thread/list：\(catalog.threads.count) 个历史对话"
        } catch {
            runtimeThreadSyncStatusText = "历史对话读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func loadRuntimeThreadTranscript(localThreadID: UUID? = nil) async {
        let targetID = localThreadID ?? selectedThreadID
        guard let localIndex = threads.firstIndex(where: { $0.id == targetID }),
              let serverThreadID = threads[localIndex].appServerThreadID else {
            return
        }

        runtimeThreadSyncStatusText = "正在读取 thread/read…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.readThread(id: serverThreadID, includeTurns: true)
            applyRuntimeThreadRead(result, to: targetID)
            runtimeThreadSyncStatusText = "thread/read：已加载历史 transcript"
        } catch {
            runtimeThreadSyncStatusText = "历史 transcript 读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func unarchiveRuntimeThread(_ thread: CodexRuntimeThreadSummary) async {
        runtimeCatalogStatusText = "正在恢复 \(thread.title)…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            _ = try await client.unarchiveThread(id: thread.id)
            await refreshArchivedThreads()
        } catch {
            runtimeCatalogStatusText = "恢复失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func archiveRuntimeThread(id threadID: String) async {
        runtimeCatalogStatusText = "正在归档对话…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.archiveThread(id: threadID)
            runtimeCatalogStatusText = "thread/archive：已归档 \(threadID)"
        } catch {
            runtimeCatalogStatusText = "归档失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func setRuntimeThreadName(id threadID: String, name: String) async {
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.setThreadName(id: threadID, name: name)
            runtimeCatalogStatusText = "thread/name/set：已重命名"
        } catch {
            runtimeCatalogStatusText = "远端重命名失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func forkRuntimeThread(sourceThreadID: String, localCopyID: UUID) async {
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let serverThread = try await client.forkThread(id: sourceThreadID, options: appServerOptions())
            guard let index = threads.firstIndex(where: { $0.id == localCopyID }) else {
                return
            }
            threads[index].appServerThreadID = serverThread.id
            threads[index].appServerSessionID = serverThread.sessionID
            threads[index].updatedAt = Date()
            runtimeCatalogStatusText = "thread/fork：已复制为 \(serverThread.id)"
        } catch {
            runtimeCatalogStatusText = "远端复制失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    private func mergeRuntimeThreads(_ summaries: [CodexRuntimeThreadSummary]) {
        for summary in summaries {
            let projectID = projectIDForRuntimeThread(cwd: summary.cwd)
            let updatedAt = Self.dateFromRuntimeString(summary.updatedAt) ??
                Self.dateFromRuntimeString(summary.createdAt) ??
                Date()
            if let index = threads.firstIndex(where: { $0.appServerThreadID == summary.id }) {
                threads[index].title = summary.title
                threads[index].projectID = projectID
                threads[index].updatedAt = updatedAt
            } else {
                threads.append(ChatThread(
                    title: summary.title,
                    projectID: projectID,
                    items: [],
                    model: model,
                    sandbox: sandbox,
                    approval: approval,
                    approvalsReviewer: approvalsReviewer,
                    personality: personality,
                    appServerThreadID: summary.id,
                    appServerSessionID: nil,
                    updatedAt: updatedAt
                ))
            }
        }
    }

    private func projectIDForRuntimeThread(cwd: String?) -> UUID {
        let path = cwd?.isEmpty == false ? cwd! : workspacePath
        if let existing = projects.first(where: { $0.path == path }) {
            return existing.id
        }
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent.isEmpty ? "Codex 历史" : url.lastPathComponent
        let project = Project(name: name, path: path, branch: Self.currentGitBranch(at: path))
        projects.append(project)
        return project.id
    }

    private func applyRuntimeThreadRead(_ result: JSONValue, to localThreadID: UUID) {
        guard let threadValue = result["thread"],
              let index = threads.firstIndex(where: { $0.id == localThreadID }) else {
            return
        }
        let turns = threadValue["turns"]?.arrayValue ?? []
        let items = transcriptItems(from: turns, threadID: threadValue["id"]?.stringValue ?? threads[index].appServerThreadID ?? localThreadID.uuidString)
        threads[index].items = items
        threads[index].title = threadValue["name"]?.stringValue ??
            threadValue["preview"]?.stringValue ??
            threads[index].title
        threads[index].appServerSessionID = threadValue["sessionId"]?.stringValue ?? threads[index].appServerSessionID
        if let cwd = threadValue["cwd"]?.stringValue {
            threads[index].projectID = projectIDForRuntimeThread(cwd: cwd)
        }
        if let updatedAt = Self.dateFromRuntimeSeconds(threadValue["updatedAt"]) ??
            Self.dateFromRuntimeSeconds(threadValue["recencyAt"]) {
            threads[index].updatedAt = updatedAt
        } else {
            threads[index].updatedAt = Date()
        }
    }

    private func transcriptItems(from turns: [JSONValue], threadID: String) -> [TranscriptItem] {
        var transcript: [TranscriptItem] = []
        for (turnIndex, turn) in turns.enumerated() {
            let timestamp = Self.dateFromRuntimeSeconds(turn["startedAt"]) ?? Date()
            let items = turn["items"]?.arrayValue ?? []
            for (itemIndex, item) in items.enumerated() {
                transcript.append(contentsOf: transcriptItems(
                    fromRuntimeItem: item,
                    timestamp: timestamp,
                    stableIDPrefix: "history:\(threadID):\(turn["id"]?.stringValue ?? "\(turnIndex)"):\(item["id"]?.stringValue ?? "\(itemIndex)")"
                ))
            }
        }
        return transcript
    }

    private func transcriptItems(
        fromRuntimeItem item: JSONValue,
        timestamp: Date,
        stableIDPrefix: String
    ) -> [TranscriptItem] {
        guard let type = item["type"]?.stringValue else {
            return []
        }

        switch type {
        case "userMessage":
            let text = Self.textFromRuntimeContent(item["content"])
            guard !text.isEmpty else { return [] }
            return [TranscriptItem(
                id: transcriptUUID(for: stableIDPrefix),
                timestamp: timestamp,
                kind: .userMessage(text)
            )]
        case "agentMessage":
            let text = item["text"]?.stringValue ?? ""
            guard !text.isEmpty else { return [] }
            return [TranscriptItem(
                id: transcriptUUID(for: stableIDPrefix),
                timestamp: timestamp,
                kind: .agentMessage(text)
            )]
        case "reasoning":
            let detail = [
                Self.textFromRuntimeContent(item["summary"]),
                Self.textFromRuntimeContent(item["content"])
            ]
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")
            guard !detail.isEmpty else { return [] }
            return [TranscriptItem(
                id: transcriptUUID(for: stableIDPrefix),
                timestamp: timestamp,
                kind: .reasoning(ReasoningBlock(title: "思考", detail: detail))
            )]
        case "commandExecution":
            return [TranscriptItem(
                id: transcriptUUID(for: stableIDPrefix),
                timestamp: timestamp,
                kind: .command(CommandRun(
                    command: item["command"]?.stringValue ?? "命令",
                    directory: item["cwd"]?.stringValue.map(Project.abbreviate),
                    output: item["aggregatedOutput"]?.stringValue ?? "",
                    exitCode: item["exitCode"]?.intValue.map(Int32.init),
                    status: Self.runStatus(from: item["status"]?.stringValue)
                ))
            )]
        case "fileChange":
            return historyFileChangeItems(item, timestamp: timestamp, stableIDPrefix: stableIDPrefix)
        default:
            return []
        }
    }

    private func historyFileChangeItems(
        _ item: JSONValue,
        timestamp: Date,
        stableIDPrefix: String
    ) -> [TranscriptItem] {
        (item["changes"]?.arrayValue ?? []).compactMap { changeValue in
            guard let path = changeValue["path"]?.stringValue else { return nil }
            let diff = changeValue["diff"]?.stringValue ?? ""
            let parsedDiff = Self.parseUnifiedDiff(diff)
            return TranscriptItem(
                id: transcriptUUID(for: "\(stableIDPrefix):\(path)"),
                timestamp: timestamp,
                kind: .fileChange(FileChange(
                    path: path,
                    type: Self.fileChangeType(from: changeValue["kind"]),
                    additions: parsedDiff.additions,
                    deletions: parsedDiff.deletions,
                    hunks: parsedDiff.hunks
                ))
            )
        }
    }

    func refreshWorkspaceGitDiff() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在读取 gitDiffToRemote…"
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            workspaceGitDiff = try await client.gitDiffToRemote(cwd: workspacePath)
            workspaceGitStatusText = ""
            let parsed = Self.parseUnifiedDiff(workspaceGitDiff?.diff ?? "")
            runtimeCatalogStatusText = "gitDiffToRemote：+\(parsed.additions) −\(parsed.deletions)"
        } catch {
            let diffError = error.localizedDescription
            do {
                let client = try await ensureAppServerClient(useProviderConfiguration: false)
                let result = try await client.execCommand(
                    ["/bin/zsh", "-lc", "git status --short --branch && git rev-parse --short HEAD 2>/dev/null || true"],
                    cwd: URL(fileURLWithPath: workspacePath),
                    sandbox: .readOnly,
                    timeoutMs: 10_000
                )
                workspaceGitDiff = nil
                workspaceGitStatusText = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                runtimeCatalogStatusText = "gitDiffToRemote 不可用，已用 command/exec 读取本地 Git 状态"
                runtimeCatalogErrors = ["gitDiffToRemote：\(diffError)"]
            } catch {
                runtimeCatalogStatusText = "Git 差异读取失败：\(diffError)"
                runtimeCatalogErrors = ["gitDiffToRemote：\(diffError)", "command/exec：\(error.localizedDescription)"]
            }
        }
        runtimeCatalogIsRefreshing = false
    }

    func refreshIntegrationRuntime(forceRefetchApps: Bool = false) async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在读取 app-server 集成状态…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            var errors: [String] = []

            do {
                runtimeRequirements = try await client.readConfigRequirements()
                if runtimeConfig?.defaultPermissions == nil {
                    applyRuntimeDefaultPermissionsProfile(runtimeRequirements?.defaultPermissions)
                }
            } catch {
                errors.append("configRequirements/read：\(error.localizedDescription)")
            }

            do {
                let catalog = try await client.listApps(
                    threadID: selectedThread.appServerThreadID,
                    limit: 100,
                    forceRefetch: forceRefetchApps
                )
                runtimeApps = catalog.apps
            } catch {
                errors.append("app/list：\(error.localizedDescription)")
            }

            do {
                runtimeRemoteControlStatus = try await client.readRemoteControlStatus()
            } catch {
                errors.append("remoteControl/status/read：\(error.localizedDescription)")
            }

            do {
                let catalog = try await client.listPermissionProfiles(cwd: workspacePath)
                runtimePermissionProfiles = catalog.profiles
            } catch {
                errors.append("permissionProfile/list：\(error.localizedDescription)")
            }

            if runtimePlugins.isEmpty {
                do {
                    let catalog = try await client.listPluginCatalog(cwds: [workspacePath])
                    runtimePlugins = catalog.plugins
                    errors.append(contentsOf: catalog.marketplaceLoadErrors)
                } catch {
                    errors.append("plugin/list：\(error.localizedDescription)")
                }
            }

            if runtimeMCPServers.isEmpty {
                do {
                    let catalog = try await client.listMCPServerStatus(threadID: selectedThread.appServerThreadID)
                    runtimeMCPServers = catalog.servers
                } catch {
                    errors.append("mcpServerStatus/list：\(error.localizedDescription)")
                }
            }

            runtimeCatalogErrors = errors
            runtimeCatalogStatusText = "集成：\(runtimeApps.count) 个 app · \(runtimePlugins.count) 个插件 · \(runtimeMCPServers.count) 个 MCP · \(runtimePermissionProfiles.count) 个权限配置"
        } catch {
            runtimeCatalogStatusText = "集成状态读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func resetCodexMemory() async {
        runtimeCatalogStatusText = "正在调用 memory/reset…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.resetMemory()
            runtimeCatalogStatusText = "memory/reset：记忆已重置"
        } catch {
            runtimeCatalogStatusText = "记忆重置失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func refreshWorkspaceWorktrees() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在读取 git worktree…"
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommand(
                ["/bin/zsh", "-lc", "git worktree list --porcelain 2>/dev/null || git worktree list 2>/dev/null || true"],
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: .readOnly,
                timeoutMs: 10_000
            )
            workspaceWorktrees = Self.parseWorktreeOutput(result.stdout)
            runtimeCatalogStatusText = "git worktree：\(workspaceWorktrees.count) 个工作树"
        } catch {
            runtimeCatalogStatusText = "工作树读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    func refreshWorkspaceBranches() async {
        workspaceBranchStatusText = "正在读取 Git 分支…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommand(
                [
                    "/bin/zsh",
                    "-lc",
                    "printf 'CURRENT:%s\\n' \"$(git branch --show-current 2>/dev/null)\"; git branch --format='%(refname:short)' --sort=refname 2>/dev/null"
                ],
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: .readOnly,
                timeoutMs: 10_000
            )
            let parsed = Self.parseBranchOutput(result.stdout)
            workspaceBranches = parsed.branches
            updateSelectedProject(branch: parsed.current)
            workspaceBranchStatusText = parsed.branches.isEmpty ? "未发现分支" : "Git 分支：\(parsed.branches.count) 个"
        } catch {
            workspaceBranchStatusText = "分支读取失败：\(error.localizedDescription)"
            workspaceBranches = []
        }
    }

    func checkoutWorkspaceBranch(_ branch: String) async {
        let branchName = branch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !branchName.isEmpty else { return }

        workspaceBranchStatusText = "正在切换到 \(branchName)…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommand(
                ["/usr/bin/git", "switch", branchName],
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: .workspaceWrite,
                timeoutMs: 20_000
            )
            if result.exitCode == 0 {
                updateSelectedProject(branch: branchName)
                workspaceBranchStatusText = "已切换到 \(branchName)"
                await refreshWorkspaceBranches()
            } else {
                let output = [result.stdout, result.stderr]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .joined(separator: "\n")
                workspaceBranchStatusText = output.isEmpty ? "切换分支失败：退出 \(result.exitCode)" : output
            }
        } catch {
            workspaceBranchStatusText = "切换分支失败：\(error.localizedDescription)"
        }
    }

    func promptCreateWorkspaceBranch() {
        let alert = NSAlert()
        alert.messageText = "新建分支"
        alert.informativeText = "输入要从当前工作区创建并切换到的分支名称。"
        alert.addButton(withTitle: "创建")
        alert.addButton(withTitle: "取消")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.placeholderString = "feature/example"
        alert.accessoryView = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let branchName = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !branchName.isEmpty else { return }
        Task { await createWorkspaceBranch(branchName) }
    }

    func createWorkspaceBranch(_ branch: String) async {
        let branchName = branch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !branchName.isEmpty else { return }

        workspaceBranchStatusText = "正在创建 \(branchName)…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommand(
                ["/usr/bin/git", "switch", "-c", branchName],
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: .workspaceWrite,
                timeoutMs: 20_000
            )
            if result.exitCode == 0 {
                updateSelectedProject(branch: branchName)
                workspaceBranchStatusText = "已创建并切换到 \(branchName)"
                await refreshWorkspaceBranches()
            } else {
                let output = [result.stdout, result.stderr]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .joined(separator: "\n")
                workspaceBranchStatusText = output.isEmpty ? "创建分支失败：退出 \(result.exitCode)" : output
            }
        } catch {
            workspaceBranchStatusText = "创建分支失败：\(error.localizedDescription)"
        }
    }

    func chooseWorkspaceExecutionMode(_ mode: WorkspaceExecutionMode) {
        workspaceExecutionMode = mode
        switch mode {
        case .local:
            route = .thread
        case .cloudPending:
            route = .settings
            settingsPane = .environments
            Task { await refreshIntegrationRuntime() }
        }
    }

    func togglePluginInstallation(_ plugin: CodexRuntimePlugin) async {
        runtimeCatalogStatusText = plugin.installed ? "正在卸载 \(plugin.displayName)…" : "正在安装 \(plugin.displayName)…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            if plugin.installed {
                try await client.uninstallPlugin(plugin)
            } else {
                try await client.installPlugin(plugin)
            }
            await refreshRuntimeCatalog(forceReloadSkills: true)
        } catch {
            runtimeCatalogStatusText = "插件操作失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func toggleSkill(_ skill: CodexRuntimeSkill) async {
        runtimeCatalogStatusText = skill.enabled ? "正在停用 \(skill.displayName)…" : "正在启用 \(skill.displayName)…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.setSkillEnabled(skill, enabled: !skill.enabled)
            await refreshRuntimeCatalog(forceReloadSkills: true)
        } catch {
            runtimeCatalogStatusText = "技能操作失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func usePluginInComposer(_ plugin: CodexRuntimePlugin) {
        prompt = "@\(plugin.name) "
        lastMentionInputPreview = [
            [
                "name": plugin.displayName,
                "path": plugin.mentionPath
            ]
        ]
        route = .thread
    }

    func prepareAutomationTemplate(title: String, prompt templatePrompt: String) {
        let existingProject = selectedProject
        newThread(in: existingProject.id)
        prompt = templatePrompt
        updateSelectedThread { thread in
            thread.title = title
            thread.model = model
            thread.sandbox = sandbox
            thread.approval = approval
            thread.approvalsReviewer = approvalsReviewer
            thread.personality = personality
        }
        route = .thread
        toolPanel = .launcher
    }

    func installAutomationHookTemplate(title: String, prompt templatePrompt: String) async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在安装 \(title) 自动化 hook…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let existing = try await client.listHooks(cwds: [workspacePath])
            let conflictingUserHooks = existing.hooks.filter { hook in
                Self.isUserPromptSubmitHook(hook) &&
                    hook.source == "user" &&
                    !(hook.command?.contains("raytone-automation-events.jsonl") == true)
            }
            guard conflictingUserHooks.isEmpty else {
                runtimeCatalogStatusText = "未安装：已有用户级 UserPromptSubmit hook"
                runtimeCatalogErrors = [
                    "为避免覆盖现有 hook，请先在 Codex 配置里合并或移除：\(conflictingUserHooks.map(\.key).joined(separator: ", "))"
                ]
                runtimeCatalogIsRefreshing = false
                return
            }

            let command = Self.raytoneAutomationHookCommand(title: title)
            let configURL = try ensureCodexConfigFile()
            let existingConfig = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
            let updatedConfig = Self.installRaytoneAutomationHookBlock(
                into: existingConfig,
                title: title,
                command: command
            )
            try updatedConfig.write(to: configURL, atomically: true, encoding: .utf8)
            await refreshRuntimeHooks()
            runtimeCatalogStatusText = "已安装 \(title)：hooks/list 返回 \(runtimeHooks.count) 个钩子"
            if !templatePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                prompt = templatePrompt
            }
        } catch {
            runtimeCatalogStatusText = "自动化安装失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
        }
    }

    func saveInstructions(_ instructions: String) async {
        runtimeCatalogStatusText = "正在写入 developer_instructions…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(keyPath: "developer_instructions", value: .string(instructions))
            applyRuntimeConfig(try? await client.readConfig(cwd: workspacePath, includeLayers: true))
            runtimeCatalogStatusText = "developer_instructions 已写入 config.toml"
        } catch {
            runtimeCatalogStatusText = "写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func openCodexConfigFile() {
        let configURL = (try? ensureCodexConfigFile()) ?? Self.defaultCodexConfigURL()
        NSWorkspace.shared.open(configURL)
    }

    private func ensureCodexConfigFile() throws -> URL {
        let configURL = Self.defaultCodexConfigURL(
            overrideCodexHome: appServerEnvironmentOverridesForTesting["CODEX_HOME"]
        )
        try FileManager.default.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if !FileManager.default.fileExists(atPath: configURL.path) {
            FileManager.default.createFile(atPath: configURL.path, contents: Data())
        }
        return configURL
    }

    func revealCodexHomeSubfolder(_ subfolder: String) {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex")
            .appendingPathComponent(subfolder)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func diagnoseWorkspaceRuntime() async {
        let executablePath = runtimeSnapshot.executable?.url.path ?? service.resolver.resolve()?.url.path
        guard let executablePath else {
            runtimeCatalogStatusText = "诊断失败：找不到 Codex CLI"
            return
        }
        openToolPanel(.terminal)
        terminalCommand = "\(Self.shellQuoted(executablePath)) --version && \(Self.shellQuoted(executablePath)) app-server --help | head -40"
        await runTerminalCommand()
    }

    private func updateTerminalRun(
        id: UUID,
        output: String,
        exitCode: Int32?,
        status: TerminalCommandRecord.Status
    ) {
        guard let index = terminalRuns.firstIndex(where: { $0.id == id }) else { return }
        terminalRuns[index].output = output
        terminalRuns[index].exitCode = exitCode
        terminalRuns[index].status = status
    }

    func selectProvider(_ providerID: String) {
        guard providers.contains(where: { $0.id == providerID }) else { return }
        selectedProviderID = providerID
        model = selectedProvider.usesSidecar ? selectedProvider.model : model
        Task { await resetAppServerForProviderChange() }
    }

    func chooseProviderModel(providerID: String, model: String) {
        guard applyProviderModelSelection(providerID: providerID, model: model) != nil else { return }
        Task { await resetAppServerForProviderChange() }
    }

    func codexModelMetadata(id: String) -> CodexAppServerModel? {
        codexModelCatalog.first { $0.id == id || $0.model == id }
    }

    func modelMenuTitle(providerID: String, model modelID: String) -> String {
        guard providerID == "openai",
              let metadata = codexModelMetadata(id: modelID) else {
            return modelID
        }

        var parts = [metadata.displayName.isEmpty ? modelID : metadata.displayName]
        if let effort = metadata.defaultReasoningEffort, !effort.isEmpty {
            parts.append("推理 \(effort)")
        }
        if metadata.supportsPersonality {
            parts.append("个性")
        }
        return parts.joined(separator: " · ")
    }

    @discardableResult
    private func applyProviderModelSelection(
        providerID: String,
        model selectedModel: String
    ) -> RaytoneProviderConfiguration? {
        guard let index = providers.firstIndex(where: { $0.id == providerID }) else { return nil }
        providers[index].model = selectedModel
        selectedProviderID = providerID
        model = selectedModel
        updateSelectedThread { thread in
            thread.model = selectedModel
        }
        return providers[index]
    }

    func saveRuntimeModelSelection(providerID: String, model selectedModel: String) async {
        guard let provider = applyProviderModelSelection(providerID: providerID, model: selectedModel) else {
            modelCatalogStatusText = "未找到 provider：\(providerID)"
            return
        }

        await resetAppServerForProviderChange()

        guard provider.usesSidecar == false else {
            modelCatalogStatusText = "\(provider.displayName) 将通过 sidecar 会话使用 \(selectedModel)"
            runtimeCatalogStatusText = "第三方 provider 使用独立 CODEX_HOME，不写入全局 Codex config.toml"
            return
        }

        modelCatalogStatusText = "正在写入 model/model_provider…"
        runtimeCatalogStatusText = "正在写入 model/model_provider…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.batchWriteConfig(edits: [
                CodexConfigWriteEdit(keyPath: "model", value: .string(selectedModel)),
                CodexConfigWriteEdit(keyPath: "model_provider", value: .string(provider.id))
            ])
            let config = try await client.readConfig(cwd: workspacePath, includeLayers: true)
            applyRuntimeConfig(config)
            modelCatalogStatusText = "model/model_provider 已写入 config.toml"
            runtimeCatalogStatusText = "Codex 默认模型已更新为 \(selectedModel)"
        } catch {
            modelCatalogStatusText = "模型写入失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = "模型写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func providerThinkingEnabled(_ provider: RaytoneProviderConfiguration) -> Bool {
        if let reasoning = provider.reasoning {
            return reasoning.supportsThinking
        }
        return runtimeThinkingEnabled
    }

    func saveRuntimeThinkingEnabled(providerID: String, enabled: Bool) async {
        guard let index = providers.firstIndex(where: { $0.id == providerID }) else {
            modelCatalogStatusText = "未找到 provider：\(providerID)"
            return
        }

        var provider = providers[index]
        if var reasoning = provider.reasoning {
            reasoning.supportsThinking = enabled
            provider.reasoning = reasoning
            providers[index] = provider
        }

        let effort = enabled ? "medium" : "none"
        let summary = enabled ? "auto" : "none"

        if provider.usesSidecar {
            await resetAppServerForProviderChange()
            modelCatalogStatusText = enabled ? "Thinking 已开启，将写入下一次 sidecar Codex 会话" : "Thinking 已关闭，将写入下一次 sidecar Codex 会话"
            runtimeCatalogStatusText = "sidecar 会话将使用 model_reasoning_effort=\(effort)、model_reasoning_summary=\(summary)"
            return
        }

        modelCatalogStatusText = "正在写入 model_reasoning_*…"
        runtimeCatalogStatusText = "正在写入 model_reasoning_*…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.batchWriteConfig(edits: [
                CodexConfigWriteEdit(keyPath: "model_reasoning_effort", value: .string(effort)),
                CodexConfigWriteEdit(keyPath: "model_reasoning_summary", value: .string(summary))
            ])
            let config = try await client.readConfig(cwd: workspacePath, includeLayers: true)
            applyRuntimeConfig(config)
            modelCatalogStatusText = "model_reasoning_* 已写入 config.toml"
            runtimeCatalogStatusText = enabled ? "Thinking 已开启：\(effort) / \(summary)" : "Thinking 已关闭：none / none"
        } catch {
            modelCatalogStatusText = "Thinking 写入失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = "Thinking 写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func saveProviderAPIKey(_ key: String, providerID: String? = nil) throws {
        let id = providerID ?? selectedProviderID
        try RaytoneKeychainService.savePassword(key, account: id)
    }

    func providerAPIKey(providerID: String? = nil) -> String? {
        let id = providerID ?? selectedProviderID
        return try? RaytoneKeychainService.readPassword(account: id)
    }

    func hasProviderAPIKey(_ provider: RaytoneProviderConfiguration) -> Bool {
        if provider.kind == .openAI {
            return true
        }
        if let key = providerAPIKey(providerID: provider.id),
           !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        if let env = provider.apiKeyEnvironmentName,
           let key = ProcessInfo.processInfo.environment[env],
           !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }

    private func runPromptWithAppServer(_ trimmedPrompt: String) async throws {
        let options = appServerOptions()
        let client = try await ensureAppServerClient()
        let mentions = await pluginMentions(in: trimmedPrompt)
        let threadID = try await ensureAppServerThread(client: client, options: options)

        let turn = try await client.startTurn(
            threadID: threadID,
            prompt: trimmedPrompt,
            options: options,
            mentions: mentions
        )
        activeAppServerTurnID = turn.id
        isRunning = turn.status == "inProgress"
        updateSelectedThread { thread in
            thread.activeGoal = ActiveGoal(title: trimmedPrompt, startedAt: Date())
        }
    }

    func runReviewOfCurrentChanges(displayedPrompt: String = "/review", instructions: String? = nil) async {
        guard !isRunning else { return }

        isRunning = true
        let fallbackPrompt = Self.reviewFallbackPrompt(instructions: instructions)
        updateSelectedThread { thread in
            thread.model = model
            thread.sandbox = sandbox
            thread.approval = approval
            thread.approvalsReviewer = approvalsReviewer
            thread.personality = personality
            thread.items.append(TranscriptItem(kind: .userMessage(displayedPrompt)))
        }

        do {
            let options = appServerOptions()
            let client = try await ensureAppServerClient()
            let threadID = try await ensureAppServerThread(client: client, options: options)
            let target: CodexReviewTarget
            if let instructions, !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                target = .custom(instructions: fallbackPrompt)
            } else {
                target = .uncommittedChanges
            }

            let review = try await client.startReview(
                threadID: threadID,
                target: target,
                delivery: .inline
            )
            activeAppServerTurnID = review.turn.id
            isRunning = review.turn.status == "inProgress"
            updateSelectedThread { thread in
                thread.activeGoal = ActiveGoal(title: "审查当前变更", startedAt: Date())
            }
        } catch {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "review/start 暂不可用，已降级为普通 Codex 审查请求：\(error.localizedDescription)"
                ))))
            }
            do {
                try await runPromptWithAppServer(fallbackPrompt)
            } catch {
                if selectedProvider.usesSidecar {
                    updateSelectedThread { thread in
                        thread.items.append(TranscriptItem(kind: .notice(Notice(
                            level: .error,
                            text: "多 Provider 运行时不可用：\(error.localizedDescription)"
                        ))))
                    }
                    isRunning = false
                    await refreshRuntime()
                } else {
                    await runPromptWithExec(fallbackPrompt)
                }
            }
        }
    }

    private func ensureAppServerThread(
        client: CodexAppServerClient,
        options: CodexAppServerOptions
    ) async throws -> String {
        var threadID = selectedThread.appServerThreadID

        if threadID == nil {
            let serverThread = try await client.startThread(options: options)
            updateSelectedThread { thread in
                thread.appServerThreadID = serverThread.id
                thread.appServerSessionID = serverThread.sessionID
            }
            threadID = serverThread.id
        } else if selectedThread.appServerSessionID == nil, let existingThreadID = threadID {
            let serverThread = try await client.resumeThread(id: existingThreadID, options: options)
            updateSelectedThread { thread in
                thread.appServerThreadID = serverThread.id
                thread.appServerSessionID = serverThread.sessionID
            }
            threadID = serverThread.id
        }

        guard let threadID else {
            throw CodexAppServerError.invalidResponse("Missing app-server thread id.")
        }
        return threadID
    }

    private func runPromptWithExec(_ trimmedPrompt: String) async {
        do {
            let options = CodexRunOptions(
                workspaceURL: URL(fileURLWithPath: workspacePath),
                model: model.isEmpty ? nil : model,
                sandbox: sandbox,
                approvalPolicy: approval
            )
            let result = try await service.run(prompt: trimmedPrompt, options: options)
            let rawOutput = [result.stdout, result.stderr]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")

            lastCommandPreview = result.commandPreview
            lastOutputPath = result.outputFileURL.path
            lastRawOutput = rawOutput

            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .command(CommandRun(
                    command: result.commandPreview,
                    directory: Project.abbreviate(workspacePath),
                    output: rawOutput.isEmpty ? result.finalMessage : rawOutput,
                    exitCode: result.exitCode,
                    status: .succeeded
                ))))
                thread.items.append(TranscriptItem(kind: .agentMessage(result.finalMessage)))
            }
        } catch {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .error,
                    text: error.localizedDescription
                ))))
            }
        }
    }

    private func ensureAppServerClient(useProviderConfiguration: Bool = true) async throws -> CodexAppServerClient {
        if runtimeSnapshot.executable == nil {
            runtimeSnapshot = await service.inspectRuntime()
        }

        guard let executable = runtimeSnapshot.executable ?? service.resolver.resolve() else {
            appServerConnectionState = .notInstalled
            throw CodexCLIError.executableNotFound
        }

        var environmentOverrides = baseAppServerEnvironmentOverrides()
        if useProviderConfiguration {
            environmentOverrides.merge(try await appServerEnvironmentOverrides()) { _, new in new }
        }
        let environmentKey: String
        if let codexHome = environmentOverrides["CODEX_HOME"] {
            environmentKey = codexHome
        } else if useProviderConfiguration {
            environmentKey = "global"
        } else {
            environmentKey = selectedProvider.usesSidecar ? "global-tools" : "global"
        }
        if appServerEnvironmentKey != nil, appServerEnvironmentKey != environmentKey {
            if let existing = appServerClient {
                await existing.stop()
            }
            appServerClient = nil
            appServerEventsTask?.cancel()
            appServerEventsTask = nil
            appServerItemIDs.removeAll()
            activeDiffTranscriptIDs.removeAll()
        }
        appServerEnvironmentKey = environmentKey

        let client: CodexAppServerClient
        if let existing = appServerClient {
            client = existing
        } else {
            client = CodexAppServerClient(
                executable: executable,
                workspaceURL: URL(fileURLWithPath: workspacePath),
                environmentOverrides: environmentOverrides
            )
            appServerClient = client
            startAppServerEventPump(client)
        }

        try await client.initialize()
        let version = runtimeSnapshot.version?.isEmpty == false ? runtimeSnapshot.version! : "app-server"
        appServerConnectionState = .connected(version: version)
        return client
    }

    private func appServerEnvironmentOverrides() async throws -> [String: String] {
        let provider = selectedProvider
        guard provider.usesSidecar else {
            sidecarStatusText = "直连"
            return [:]
        }

        guard let proxyURL = resolveRaytoneProxyExecutableURL() else {
            let detail = "找不到 raytone-proxy。请重新构建应用或检查 bundle 资源。"
            appServerConnectionState = .sidecarUnavailable(detail)
            sidecarStatusText = "未找到"
            throw RaytoneProxyServiceError.launchFailed(detail)
        }

        let keychainKey = try? RaytoneKeychainService.readPassword(account: provider.id)
        let environmentKey = provider.apiKeyEnvironmentName.flatMap { ProcessInfo.processInfo.environment[$0] }
        guard let apiKey = keychainKey ?? environmentKey,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appServerConnectionState = .providerKeyMissing(provider.displayName)
            sidecarStatusText = "缺少 \(provider.displayName) Key"
            throw RaytoneProxyServiceError.missingAPIKey(provider.displayName)
        }

        do {
            let session = try await proxyService.start(
                executableURL: proxyURL,
                provider: provider,
                apiKey: apiKey
            )
            activeProxySession = session
            sidecarStatusText = "127.0.0.1:\(session.port) · \(provider.displayName)"
            return [
                "CODEX_HOME": session.codexHomeURL.path
            ]
        } catch {
            appServerConnectionState = .sidecarUnavailable(error.localizedDescription)
            sidecarStatusText = "启动失败"
            throw error
        }
    }

    private func baseAppServerEnvironmentOverrides() -> [String: String] {
        if !appServerEnvironmentOverridesForTesting.isEmpty {
            return appServerEnvironmentOverridesForTesting
        }
        guard let codexHome = ProcessInfo.processInfo.environment["RAYTONE_CODEX_HOME"],
              !codexHome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return [:]
        }
        return ["CODEX_HOME": codexHome]
    }

    private func resetAppServerForProviderChange() async {
        if let existing = appServerClient {
            await existing.stop()
        }
        appServerClient = nil
        appServerEventsTask?.cancel()
        appServerEventsTask = nil
        appServerEnvironmentKey = nil
        activeAppServerTurnID = nil
        activeDiffTranscriptIDs.removeAll()
        await proxyService.stop()
        activeProxySession = nil
        appServerConnectionState = nil
        sidecarStatusText = selectedProvider.usesSidecar ? "未启动" : "直连"
    }

    private func resolveRaytoneProxyExecutableURL() -> URL? {
        let environment = ProcessInfo.processInfo.environment
        if let override = environment["RAYTONE_PROXY"],
           FileManager.default.isExecutableFile(atPath: override) {
            return URL(fileURLWithPath: override)
        }

        if let resourceURL = Bundle.main.resourceURL?.appendingPathComponent("raytone-proxy"),
           FileManager.default.isExecutableFile(atPath: resourceURL.path) {
            return resourceURL
        }

        let candidates = [
            "\(workspacePath)/.build/raytone-codex-cli/raytone-proxy",
            "\(workspacePath)/sidecar/raytone-proxy/target/release/raytone-proxy"
        ]
        return candidates
            .first { FileManager.default.isExecutableFile(atPath: $0) }
            .map(URL.init(fileURLWithPath:))
    }

    private func startAppServerEventPump(_ client: CodexAppServerClient) {
        guard appServerEventsTask == nil else {
            return
        }

        let events = client.events
        appServerEventsTask = Task { [weak self] in
            for await event in events {
                self?.handleAppServerEvent(event)
            }
        }
    }

    private func appServerOptions() -> CodexAppServerOptions {
        let provider = selectedProvider
        let optionModel: String?
        if provider.usesSidecar {
            optionModel = provider.model
        } else {
            optionModel = model.isEmpty ? nil : model
        }
        return CodexAppServerOptions(
            workspaceURL: URL(fileURLWithPath: workspacePath),
            model: optionModel,
            sandbox: sandbox,
            approvalPolicy: approval,
            approvalsReviewer: approvalsReviewer,
            personality: personality
        )
    }

    func previewPluginMentions(for prompt: String) async -> [CodexAppServerMention] {
        await pluginMentions(in: prompt)
    }

    private func pluginMentions(in prompt: String) async -> [CodexAppServerMention] {
        let mentionTokens = Self.pluginMentionTokens(in: prompt)
        guard !mentionTokens.isEmpty else {
            lastMentionInputPreview = []
            return []
        }

        if runtimePlugins.isEmpty {
            await refreshRuntimeCatalog()
        }

        var pluginsByName: [String: CodexRuntimePlugin] = [:]
        for plugin in runtimePlugins where pluginsByName[plugin.name.lowercased()] == nil {
            pluginsByName[plugin.name.lowercased()] = plugin
        }
        var seenPaths = Set<String>()
        let mentions = mentionTokens.compactMap { token -> CodexAppServerMention? in
            guard let plugin = pluginsByName[token.lowercased()],
                  plugin.installed,
                  plugin.enabled,
                  !seenPaths.contains(plugin.mentionPath) else {
                return nil
            }
            seenPaths.insert(plugin.mentionPath)
            return CodexAppServerMention(name: plugin.displayName, path: plugin.mentionPath)
        }

        lastMentionInputPreview = mentions.map {
            [
                "name": $0.name,
                "path": $0.path
            ]
        }
        return mentions
    }

    private func handleAppServerEvent(_ event: ServerEvent) {
        switch event {
        case let .notification(method, params):
            handleAppServerNotification(method: method, params: params)
        case let .serverRequest(id, method, params):
            handleAppServerRequest(id: id, method: method, params: params)
        case let .stderr(line):
            lastRawOutput = [lastRawOutput, line]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")
        case let .exited(status):
            activeAppServerTurnID = nil
            isRunning = false
            if status != 0 {
                appServerConnectionState = .disconnected
            }
        }
    }

    private func handleAppServerNotification(method: String, params: JSONValue?) {
        switch method {
        case "turn/started":
            isRunning = true
            activeAppServerTurnID = params?["turn"]?["id"]?.stringValue
            if let startedAt = params?["turn"]?["startedAt"]?.intValue {
                updateSelectedThread { thread in
                    let runtimeBacked = thread.activeGoal?.runtimeBacked == true
                    thread.activeGoal = ActiveGoal(
                        title: thread.items.compactMap { item in
                            if case let .userMessage(text) = item.kind { return text }
                            return nil
                        }.last ?? "运行 Codex",
                        startedAt: Date(timeIntervalSince1970: TimeInterval(startedAt)),
                        runtimeBacked: runtimeBacked
                    )
                }
            }
        case "turn/completed":
            isRunning = false
            activeAppServerTurnID = nil
            handleCompletedTurn(params?["turn"])
            clearLocalActiveGoalIfNeeded()
        case "turn/plan/updated":
            updateProgressSteps(params?["plan"]?.arrayValue ?? [])
        case "turn/diff/updated":
            if let diff = params?["diff"]?.stringValue {
                upsertDiffFileChanges(diff)
            }
        case "thread/settings/updated":
            handleThreadSettingsUpdated(params)
        case "thread/goal/updated":
            if let goal = CodexAppServerClient.runtimeGoal(from: params?["goal"]) {
                applyRuntimeGoal(goal)
                runtimeCatalogStatusText = "thread/goal/updated：\(goal.status.rawValue)"
            }
        case "thread/goal/cleared":
            if let threadID = params?["threadId"]?.stringValue {
                clearRuntimeGoal(threadID: threadID)
                runtimeCatalogStatusText = "thread/goal/cleared"
            }
        case "item/started", "item/completed":
            if let item = params?["item"] {
                upsertAppServerItem(item)
            }
        case "serverRequest/resolved":
            if let requestID = params?["requestId"]?.stringValue {
                clearResolvedApproval(requestID)
            }
        case "skills/changed", "mcpServer/startupStatus/updated":
            if !isRunning {
                Task { await refreshRuntimeCatalog(forceReloadSkills: method == "skills/changed") }
            }
        case "item/agentMessage/delta":
            appendAgentDelta(itemID: params?["itemId"]?.stringValue, delta: params?["delta"]?.stringValue)
        case "item/reasoning/summaryTextDelta", "item/reasoning/textDelta":
            appendReasoningDelta(itemID: params?["itemId"]?.stringValue, delta: params?["delta"]?.stringValue)
        case "item/commandExecution/outputDelta":
            appendCommandOutputDelta(itemID: params?["itemId"]?.stringValue, delta: params?["delta"]?.stringValue)
        default:
            break
        }
    }

    private func handleThreadSettingsUpdated(_ params: JSONValue?) {
        guard let threadID = params?["threadId"]?.stringValue,
              let settings = params?["threadSettings"] else {
            return
        }

        if let rawPersonality = settings["personality"]?.stringValue,
           let updatedPersonality = CodexPersonality(rawValue: rawPersonality) {
            if selectedThread.appServerThreadID == threadID {
                personality = updatedPersonality
            }
            updateThread(appServerThreadID: threadID) { thread in
                thread.personality = updatedPersonality
            }
            runtimeCatalogStatusText = "thread/settings/updated：个性 \(Self.personalityName(updatedPersonality))"
        }
    }

    private func applyRuntimeGoal(_ goal: CodexRuntimeGoal) {
        let startedAtSeconds = goal.createdAt > 0 ? goal.createdAt : goal.updatedAt
        let startedAt = startedAtSeconds > 0
            ? Date(timeIntervalSince1970: TimeInterval(startedAtSeconds))
            : Date()
        updateThread(appServerThreadID: goal.threadID) { thread in
            thread.activeGoal = ActiveGoal(title: goal.objective, startedAt: startedAt, runtimeBacked: true)
            thread.updatedAt = Date()
        }
    }

    private func clearRuntimeGoal(threadID: String) {
        updateThread(appServerThreadID: threadID) { thread in
            thread.activeGoal = nil
            thread.updatedAt = Date()
        }
    }

    private func clearSelectedThreadActiveGoal() {
        updateSelectedThread { thread in
            thread.activeGoal = nil
            thread.updatedAt = Date()
        }
    }

    private func clearLocalActiveGoalIfNeeded() {
        guard selectedThread.activeGoal?.runtimeBacked == false else {
            return
        }
        clearSelectedThreadActiveGoal()
    }

    private func handleAppServerRequest(id: CodexAppServerRequestID, method: String, params: JSONValue?) {
        switch method {
        case "item/commandExecution/requestApproval":
            let command = params?["command"]?.stringValue
            let reason = params?["reason"]?.stringValue
            let itemID = params?["itemId"]?.stringValue ?? id.description
            let transcriptID = transcriptUUID(for: "approval:\(id.description)")
            let request = ApprovalRequest(
                id: transcriptID,
                kind: .command,
                title: "允许运行命令？",
                detail: command ?? "Codex 请求运行命令",
                rationale: reason,
                command: command,
                commandPrefix: Self.commandPrefix(for: command),
                decision: .pending
            )
            pendingApprovalRequestIDs[transcriptID] = id
            upsertTranscriptItem(serverItemID: "approval:\(id.description):\(itemID)", kind: .approval(request))
        case "item/fileChange/requestApproval":
            let reason = params?["reason"]?.stringValue
            let grantRoot = params?["grantRoot"]?.stringValue
            let transcriptID = transcriptUUID(for: "approval:\(id.description)")
            let request = ApprovalRequest(
                id: transcriptID,
                kind: .patch,
                title: "允许修改文件？",
                detail: grantRoot ?? "Codex 请求写入工作区文件",
                rationale: reason,
                decision: .pending
            )
            pendingApprovalRequestIDs[transcriptID] = id
            upsertTranscriptItem(serverItemID: "approval:\(id.description)", kind: .approval(request))
        default:
            break
        }
    }

    private func handleCompletedTurn(_ turn: JSONValue?) {
        guard let turn else { return }
        if turn["status"]?.stringValue == "failed" {
            let error = turn["error"]
            if error?["codexErrorInfo"]?.stringValue == "Unauthorized" {
                appServerConnectionState = .loginRequired
            }
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .error,
                    text: error?["message"]?.stringValue ?? "Codex 轮次失败"
                ))))
            }
        }
    }

    private func updateProgressSteps(_ plan: [JSONValue]) {
        let steps = plan.compactMap { value -> ProgressStep? in
            guard let step = value["step"]?.stringValue else { return nil }
            let state: ProgressStep.State
            switch value["status"]?.stringValue {
            case "completed":
                state = .done
            case "inProgress":
                state = .running
            default:
                state = .pending
            }
            return ProgressStep(title: step, state: state)
        }
        guard !steps.isEmpty else { return }
        updateSelectedThread { thread in
            thread.progressSteps = steps
        }
    }

    private func upsertAppServerItem(_ item: JSONValue) {
        guard let object = item.objectValue,
              let type = object["type"]?.stringValue,
              let serverItemID = object["id"]?.stringValue else {
            return
        }

        switch type {
        case "userMessage":
            break
        case "agentMessage":
            let text = object["text"]?.stringValue ?? ""
            guard !Self.isStructuredReviewPayload(text) else {
                break
            }
            guard !hasAgentMessage(text) else {
                break
            }
            upsertTranscriptItem(
                serverItemID: serverItemID,
                kind: .agentMessage(text)
            )
        case "plan":
            upsertTranscriptItem(
                serverItemID: serverItemID,
                kind: .reasoning(ReasoningBlock(title: "计划", detail: object["text"]?.stringValue ?? ""))
            )
        case "reasoning":
            let summary = Self.joinedStrings(object["summary"])
            let content = Self.joinedStrings(object["content"])
            let detail = [summary, content].filter { !$0.isEmpty }.joined(separator: "\n\n")
            upsertTranscriptItem(
                serverItemID: serverItemID,
                kind: .reasoning(ReasoningBlock(title: "思考", detail: detail))
            )
        case "commandExecution":
            let status = Self.runStatus(from: object["status"]?.stringValue)
            let command = object["command"]?.stringValue ?? "命令运行中"
            upsertTranscriptItem(
                serverItemID: serverItemID,
                kind: .command(CommandRun(
                    command: command,
                    directory: object["cwd"]?.stringValue.map(Project.abbreviate),
                    output: object["aggregatedOutput"]?.stringValue ?? "",
                    exitCode: object["exitCode"]?.intValue.map(Int32.init),
                    status: status
                ))
            )
        case "enteredReviewMode":
            upsertTranscriptItem(
                serverItemID: serverItemID,
                kind: .reasoning(ReasoningBlock(
                    title: "正在审查",
                    detail: object["review"]?.stringValue ?? "Codex reviewer 正在审查当前变更。"
                ))
            )
        case "exitedReviewMode":
            upsertTranscriptItem(
                serverItemID: serverItemID,
                kind: .agentMessage(object["review"]?.stringValue ?? "审查完成。")
            )
        case "fileChange":
            upsertFileChanges(serverItemID: serverItemID, changes: object["changes"]?.arrayValue ?? [])
        default:
            break
        }
    }

    private func hasAgentMessage(_ text: String) -> Bool {
        selectedThread.items.contains { item in
            if case let .agentMessage(existing) = item.kind {
                return existing == text
            }
            return false
        }
    }

    private func appendAgentDelta(itemID: String?, delta: String?) {
        guard let itemID, let delta, !delta.isEmpty else { return }
        let transcriptID = transcriptUUID(for: itemID)
        updateSelectedThread { thread in
            if let index = thread.items.firstIndex(where: { $0.id == transcriptID }),
               case let .agentMessage(existing) = thread.items[index].kind {
                thread.items[index].kind = .agentMessage(existing + delta)
            } else {
                thread.items.append(TranscriptItem(id: transcriptID, kind: .agentMessage(delta)))
            }
        }
    }

    private func appendReasoningDelta(itemID: String?, delta: String?) {
        guard let itemID, let delta, !delta.isEmpty else { return }
        let transcriptID = transcriptUUID(for: itemID)
        updateSelectedThread { thread in
            if let index = thread.items.firstIndex(where: { $0.id == transcriptID }),
               case var .reasoning(block) = thread.items[index].kind {
                block.detail += delta
                thread.items[index].kind = .reasoning(block)
            } else {
                thread.items.append(TranscriptItem(
                    id: transcriptID,
                    kind: .reasoning(ReasoningBlock(title: "思考", detail: delta))
                ))
            }
        }
    }

    private func appendCommandOutputDelta(itemID: String?, delta: String?) {
        guard let itemID, let delta, !delta.isEmpty else { return }
        let transcriptID = transcriptUUID(for: itemID)
        updateSelectedThread { thread in
            if let index = thread.items.firstIndex(where: { $0.id == transcriptID }),
               case var .command(run) = thread.items[index].kind {
                run.output += delta
                thread.items[index].kind = .command(run)
            } else {
                thread.items.append(TranscriptItem(
                    id: transcriptID,
                    kind: .command(CommandRun(command: "命令运行中", output: delta, status: .running))
                ))
            }
        }
    }

    private func upsertFileChanges(serverItemID: String, changes: [JSONValue]) {
        for changeValue in changes {
            guard let path = changeValue["path"]?.stringValue else { continue }
            let diff = changeValue["diff"]?.stringValue ?? ""
            let parsedDiff = Self.parseUnifiedDiff(diff)
            upsertTranscriptItem(
                serverItemID: "\(serverItemID):\(path)",
                kind: .fileChange(FileChange(
                    path: path,
                    type: Self.fileChangeType(from: changeValue["kind"]),
                    additions: parsedDiff.additions,
                    deletions: parsedDiff.deletions,
                    hunks: parsedDiff.hunks
                ))
            )
        }
    }

    private func upsertDiffFileChanges(_ diff: String) {
        let changes = Self.fileChanges(fromUnifiedDiff: diff)
        var currentIDs = Set<UUID>()

        for change in changes {
            let transcriptID = upsertTranscriptItem(
                serverItemID: "diff:\(change.path)",
                kind: .fileChange(change)
            )
            currentIDs.insert(transcriptID)
        }

        let staleIDs = activeDiffTranscriptIDs.subtracting(currentIDs)
        if !staleIDs.isEmpty {
            updateSelectedThread { thread in
                thread.items.removeAll { staleIDs.contains($0.id) }
            }
        }
        activeDiffTranscriptIDs = currentIDs
    }

    private func clearResolvedApproval(_ requestID: String) {
        pendingApprovalRequestIDs = pendingApprovalRequestIDs.filter { _, value in
            value.description != requestID
        }
    }

    @discardableResult
    private func upsertTranscriptItem(serverItemID: String, kind: TranscriptItem.Kind) -> UUID {
        let transcriptID = transcriptUUID(for: serverItemID)
        updateSelectedThread { thread in
            if let index = thread.items.firstIndex(where: { $0.id == transcriptID }) {
                thread.items[index].kind = kind
            } else {
                thread.items.append(TranscriptItem(id: transcriptID, kind: kind))
            }
        }
        return transcriptID
    }

    private func transcriptUUID(for serverItemID: String) -> UUID {
        if let existing = appServerItemIDs[serverItemID] {
            return existing
        }
        let uuid = UUID()
        appServerItemIDs[serverItemID] = uuid
        return uuid
    }

    private func updateSelectedThread(_ update: (inout ChatThread) -> Void) {
        guard let index = threads.firstIndex(where: { $0.id == selectedThreadID }) else {
            return
        }
        update(&threads[index])
        threads[index].updatedAt = Date()
    }

    private func updateThread(appServerThreadID: String, _ update: (inout ChatThread) -> Void) {
        guard let index = threads.firstIndex(where: { $0.appServerThreadID == appServerThreadID }) else {
            return
        }
        update(&threads[index])
        threads[index].updatedAt = Date()
    }

    private func updateSelectedProject(path: String) {
        guard let index = projects.firstIndex(where: { $0.id == selectedProject.id }) else {
            return
        }
        projects[index].path = path
        projects[index].branch = Self.currentGitBranch(at: path)
    }

    private func updateSelectedProject(branch: String?) {
        guard let index = projects.firstIndex(where: { $0.id == selectedProject.id }) else {
            return
        }
        projects[index].branch = branch
    }

    private static func defaultWorkspacePath() -> String {
        if let override = ProcessInfo.processInfo.environment["RAYTONE_CODEX_WORKSPACE"], !override.isEmpty {
            return override
        }

        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app",
           bundleURL.deletingLastPathComponent().lastPathComponent == "dist" {
            return bundleURL.deletingLastPathComponent().deletingLastPathComponent().path
        }

        return FileManager.default.currentDirectoryPath
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func absoluteWorkspacePath(_ path: String, workspacePath: String) -> String {
        if path.hasPrefix("/") || path.hasPrefix("~") {
            return (path as NSString).expandingTildeInPath
        }
        return URL(fileURLWithPath: workspacePath)
            .appendingPathComponent(path)
            .standardizedFileURL
            .path
    }

    private static func promptReferencePath(for path: String, workspacePath: String) -> String {
        let workspace = URL(fileURLWithPath: workspacePath).standardizedFileURL.path
        let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        guard normalizedPath.hasPrefix(workspace + "/") else {
            return normalizedPath
        }
        return String(normalizedPath.dropFirst(workspace.count + 1))
    }

    private static func parseBranchOutput(_ output: String) -> (current: String?, branches: [String]) {
        let rawLines = output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let current = rawLines
            .first(where: { $0.hasPrefix("CURRENT:") })
            .map { String($0.dropFirst("CURRENT:".count)) }
            .flatMap { $0.isEmpty ? nil : $0 }
        let lines = rawLines.filter { !$0.isEmpty && !$0.hasPrefix("CURRENT:") }
        var seen = Set<String>()
        var branches: [String] = []
        if let current, !current.isEmpty {
            seen.insert(current)
            branches.append(current)
        }
        for branch in lines {
            guard !seen.contains(branch) else { continue }
            seen.insert(branch)
            branches.append(branch)
        }
        return (current, branches)
    }

    private static func pluginMentionTokens(in text: String) -> [String] {
        let pattern = #"(?<![\p{L}\p{N}_\-])@([A-Za-z0-9][A-Za-z0-9_\-]*)(?![\p{L}\p{N}_\-])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let tokenRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[tokenRange])
        }
    }

    private static func currentGitBranch(at path: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "branch", "--show-current"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                return nil
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let branch = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return branch?.isEmpty == false ? branch : nil
        } catch {
            return nil
        }
    }

    private static func joinedStrings(_ value: JSONValue?) -> String {
        value?.arrayValue?.compactMap(\.stringValue).joined(separator: "\n") ?? ""
    }

    private static func textFromRuntimeContent(_ value: JSONValue?) -> String {
        guard let value else { return "" }
        if let string = value.stringValue {
            return string
        }
        if let array = value.arrayValue {
            return array.compactMap { entry in
                entry.stringValue ??
                    entry["text"]?.stringValue ??
                    entry["summary"]?.stringValue ??
                    entry["content"]?.stringValue
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        }
        return value["text"]?.stringValue ?? value["summary"]?.stringValue ?? value["content"]?.stringValue ?? ""
    }

    private static func dateFromRuntimeString(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: value)
    }

    private static func dateFromRuntimeSeconds(_ value: JSONValue?) -> Date? {
        guard let seconds = value?.intValue else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }

    static func compactNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func accountDisplayName(_ account: CodexRuntimeAccount) -> String {
        switch account.kind {
        case "chatgpt":
            return account.email ?? "ChatGPT"
        case "apiKey":
            return "API Key"
        case "amazonBedrock":
            return "Amazon Bedrock"
        default:
            return account.requiresOpenAIAuth ? "需要登录 OpenAI" : "未登录"
        }
    }

    static func diffSummary(_ diff: String) -> (files: Int, additions: Int, deletions: Int) {
        let changes = fileChanges(fromUnifiedDiff: diff)
        let totals = changes.reduce(into: (additions: 0, deletions: 0)) { partial, change in
            partial.additions += change.additions
            partial.deletions += change.deletions
        }
        return (changes.count, totals.additions, totals.deletions)
    }

    static func parseWorktreeOutput(_ output: String) -> [String] {
        let lines = output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
        let porcelain = lines.compactMap { line -> String? in
            guard line.hasPrefix("worktree ") else { return nil }
            return String(line.dropFirst("worktree ".count))
        }
        if !porcelain.isEmpty {
            return porcelain
        }
        return lines.compactMap { line in
            line.split(separator: " ").first.map(String.init)
        }
    }

    private static func runStatus(from value: String?) -> RunStatus {
        switch value {
        case "completed":
            .succeeded
        case "failed", "declined":
            .failed
        default:
            .running
        }
    }

    private static func fileChangeType(from value: JSONValue?) -> FileChangeType {
        let type = value?["type"]?.stringValue ?? value?.stringValue
        switch type {
        case "add":
            return .added
        case "delete":
            return .deleted
        case "update" where value?["movePath"]?.stringValue != nil:
            return .renamed
        default:
            return .modified
        }
    }

    private static func parseUnifiedDiff(_ diff: String) -> (additions: Int, deletions: Int, hunks: [DiffHunk]) {
        var additions = 0
        var deletions = 0
        var hunks: [DiffHunk] = []
        var currentHeader: String?
        var currentLines: [DiffLine] = []

        func flushHunk() {
            guard let currentHeader else { return }
            hunks.append(DiffHunk(header: currentHeader, lines: currentLines))
        }

        for line in diff.components(separatedBy: .newlines) {
            if line.hasPrefix("@@") {
                flushHunk()
                currentHeader = line
                currentLines = []
                continue
            }

            guard currentHeader != nil else { continue }
            if line.hasPrefix("+++") || line.hasPrefix("---") { continue }

            if line.hasPrefix("+") {
                additions += 1
                currentLines.append(DiffLine(kind: .added, text: String(line.dropFirst())))
            } else if line.hasPrefix("-") {
                deletions += 1
                currentLines.append(DiffLine(kind: .removed, text: String(line.dropFirst())))
            } else {
                let text = line.hasPrefix(" ") ? String(line.dropFirst()) : line
                currentLines.append(DiffLine(kind: .context, text: text))
            }
        }

        flushHunk()
        return (additions, deletions, hunks)
    }

    private static func fileChanges(fromUnifiedDiff diff: String) -> [FileChange] {
        let lines = diff.components(separatedBy: .newlines)
        var blocks: [[String]] = []
        var current: [String] = []

        func flush() {
            guard !current.isEmpty else { return }
            blocks.append(current)
            current = []
        }

        for line in lines {
            if line.hasPrefix("diff --git ") {
                flush()
                current = [line]
            } else if !current.isEmpty {
                current.append(line)
            }
        }
        flush()

        if blocks.isEmpty, diff.contains("@@") {
            blocks = [lines]
        }

        return blocks.compactMap { block -> FileChange? in
            let blockText = block.joined(separator: "\n")
            guard let path = diffPath(from: block) else { return nil }
            let parsed = parseUnifiedDiff(blockText)
            return FileChange(
                path: path,
                type: diffChangeType(from: block),
                additions: parsed.additions,
                deletions: parsed.deletions,
                hunks: parsed.hunks
            )
        }
    }

    private static func diffPath(from block: [String]) -> String? {
        for line in block where line.hasPrefix("+++ ") {
            let raw = String(line.dropFirst(4))
            guard raw != "/dev/null" else { continue }
            return stripDiffPath(raw)
        }

        for line in block where line.hasPrefix("rename to ") {
            return String(line.dropFirst("rename to ".count))
        }

        if let header = block.first(where: { $0.hasPrefix("diff --git ") }) {
            let parts = header.split(separator: " ")
            if parts.count >= 4 {
                return stripDiffPath(String(parts[3]))
            }
            if parts.count >= 3 {
                return stripDiffPath(String(parts[2]))
            }
        }

        for line in block where line.hasPrefix("--- ") {
            let raw = String(line.dropFirst(4))
            guard raw != "/dev/null" else { continue }
            return stripDiffPath(raw)
        }
        return nil
    }

    private static func stripDiffPath(_ path: String) -> String {
        var cleaned = path
        if cleaned.hasPrefix("\""), cleaned.hasSuffix("\"") {
            cleaned.removeFirst()
            cleaned.removeLast()
        }
        if cleaned.hasPrefix("a/") || cleaned.hasPrefix("b/") {
            cleaned.removeFirst(2)
        }
        return cleaned
    }

    private static func diffChangeType(from block: [String]) -> FileChangeType {
        if block.contains(where: { $0.hasPrefix("new file mode") }) {
            return .added
        }
        if block.contains(where: { $0.hasPrefix("deleted file mode") }) {
            return .deleted
        }
        if block.contains(where: { $0.hasPrefix("rename from ") || $0.hasPrefix("rename to ") }) {
            return .renamed
        }
        return .modified
    }

    private static func commandPrefix(for command: String?) -> String? {
        guard let first = command?
            .split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
            .first else {
            return command
        }
        return String(first)
    }

    private static func defaultCodexConfigURL(overrideCodexHome: String? = nil) -> URL {
        let environment = ProcessInfo.processInfo.environment
        let codexHome = overrideCodexHome?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? overrideCodexHome
            : environment["RAYTONE_CODEX_HOME"] ?? environment["CODEX_HOME"]
        if let codexHome, !codexHome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return URL(fileURLWithPath: codexHome).appendingPathComponent("config.toml")
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex")
            .appendingPathComponent("config.toml")
    }

    private static func installRaytoneAutomationHookBlock(into config: String, title: String, command: String) -> String {
        let withoutOldBlock = removeRaytoneAutomationHookBlock(from: config)
        let withFeature = ensureHooksFeatureEnabled(in: withoutOldBlock)
        let block = """

        # BEGIN RaytoneCodex automation hooks
        [[hooks.UserPromptSubmit]]

        [[hooks.UserPromptSubmit.hooks]]
        type = "command"
        command = \(tomlBasicString(command))
        timeout = 5
        async = false
        statusMessage = \(tomlBasicString("RaytoneCodex 自动化：\(title)"))
        # END RaytoneCodex automation hooks
        """
        return withFeature.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n" + block + "\n"
    }

    private static func removeRaytoneAutomationHookBlock(from config: String) -> String {
        let begin = "# BEGIN RaytoneCodex automation hooks"
        let end = "# END RaytoneCodex automation hooks"
        var result = config
        while let beginRange = result.range(of: begin),
              let endRange = result.range(of: end, range: beginRange.lowerBound..<result.endIndex) {
            result.removeSubrange(beginRange.lowerBound..<endRange.upperBound)
        }
        return result
    }

    private static func ensureHooksFeatureEnabled(in config: String) -> String {
        var lines = config.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let featuresIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "[features]" }) else {
            return "[features]\nhooks = true\n\n" + config.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var insertIndex = lines.index(after: featuresIndex)
        while insertIndex < lines.endIndex {
            let trimmed = lines[insertIndex].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                break
            }
            if trimmed.hasPrefix("hooks") || trimmed.hasPrefix("codex_hooks") {
                lines[insertIndex] = "hooks = true"
                return lines.joined(separator: "\n")
            }
            insertIndex = lines.index(after: insertIndex)
        }

        lines.insert("hooks = true", at: lines.index(after: featuresIndex))
        return lines.joined(separator: "\n")
    }

    private static func tomlBasicString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }

    private static func raytoneAutomationHookCommand(title: String) -> String {
        let titleArgument = shellSingleQuote(title)
        let script = """
        dir="${CODEX_HOME:-$HOME/.codex}"; mkdir -p "$dir"; printf '{"source":"RaytoneCodex","template":"%s","event":"UserPromptSubmit","timestamp":"%s"}\\n' \(titleArgument) "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$dir/raytone-automation-events.jsonl"
        """
        return "/bin/zsh -lc \(shellSingleQuote(script))"
    }

    private static func shellSingleQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\"'\"'"))'"
    }

    private static func isUserPromptSubmitHook(_ hook: CodexRuntimeHook) -> Bool {
        normalizedHookEventName(hook.eventName) == "userpromptsubmit"
    }

    private static func normalizedHookEventName(_ value: String) -> String {
        value
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map { String($0).lowercased() }
            .joined()
    }

    static func approvalName(_ policy: CodexApprovalPolicy) -> String {
        switch policy {
        case .never: "从不"
        case .onRequest: "按需"
        case .onFailure: "失败时"
        case .untrusted: "不受信任时"
        }
    }

    static func approvalsReviewerName(_ reviewer: CodexApprovalsReviewer) -> String {
        switch reviewer {
        case .user: "用户"
        case .autoReview: "自动审查"
        }
    }

    static func personalityName(_ personality: CodexPersonality) -> String {
        switch personality {
        case .none: "无"
        case .friendly: "亲和"
        case .pragmatic: "务实"
        }
    }

    static func modelVerbosityValue(forWorkModeID id: String) -> String {
        id == "daily" ? "low" : "high"
    }

    static func workModeID(for modelVerbosity: String?) -> String {
        switch modelVerbosity?.lowercased() {
        case "low": "daily"
        default: "coding"
        }
    }

    static func serviceTierConfigValue(for label: String) -> String {
        switch label {
        case "更快": "fast"
        case "更稳": "flex"
        default: "default"
        }
    }

    static func serviceTierLabel(for value: String?) -> String {
        switch value?.lowercased() {
        case "fast", "priority": "更快"
        case "flex": "更稳"
        case "default": "标准"
        case let value? where !value.isEmpty: value
        default: "标准"
        }
    }

    static func accessMode(
        for approval: CodexApprovalPolicy,
        sandbox: CodexSandboxMode,
        approvalsReviewer: CodexApprovalsReviewer
    ) -> AccessMode {
        if sandbox == .dangerFullAccess {
            return .full
        }
        if approvalsReviewer == .autoReview {
            return .autoReview
        }
        switch approval {
        case .onRequest: return .ask
        case .onFailure: return .autoReview
        case .untrusted: return .ask
        case .never: return .autoReview
        }
    }
}
