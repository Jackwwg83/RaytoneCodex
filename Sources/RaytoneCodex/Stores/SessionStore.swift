import AppKit
import Foundation
import IOKit.pwr_mgt
import RaytoneCodexCore
import UniformTypeIdentifiers
import WebKit

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
    @Published var browserSnapshotRequest: BrowserSnapshotRequest?
    @Published var browserScreenshotStatusText = ""
    @Published var browserDataStatusText = ""
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
    @Published var sideChatDraft = ""
    @Published var sideChatStatusText = "未发送"
    @Published var runtimePlugins: [CodexRuntimePlugin] = []
    @Published var runtimePluginDetail: CodexRuntimePluginDetail?
    @Published var runtimePluginDetailStatusText = "未读取"
    @Published var runtimeSkills: [CodexRuntimeSkill] = []
    @Published var runtimeHooks: [CodexRuntimeHook] = []
    @Published var runtimeMCPServers: [CodexRuntimeMCPServer] = []
    @Published var mcpResourcePreview: CodexMCPResourceReadResult?
    @Published var mcpResourceStatusText = "未读取"
    @Published var mcpToolArgumentText: [String: String] = [:]
    @Published var mcpToolCallPreview: CodexMCPToolCallResult?
    @Published var mcpToolCallStatusText = "未调用"
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
    @Published var activeAccountLogin: CodexAccountLogin?
    @Published var runtimeTokenUsage: CodexRuntimeTokenUsage?
    @Published var runtimeRateLimits: CodexRuntimeRateLimits?
    @Published var runtimeRequirements: CodexRuntimeConfigRequirements?
    @Published var runtimeRemoteControlStatus: CodexRuntimeRemoteControlStatus?
    @Published var runtimeRemoteControlPairing: CodexRemoteControlPairing?
    @Published var runtimeRealtimeVoices: CodexRealtimeVoices?
    @Published var voiceInputStatusText = "麦克风"
    @Published var runtimeApps: [CodexRuntimeAppInfo] = []
    @Published var runtimePermissionProfiles: [CodexRuntimePermissionProfile] = []
    @Published var archivedRuntimeThreads: [CodexRuntimeThreadSummary] = []
    @Published var runtimeThreadSyncStatusText = "未同步"
    @Published var workspaceGitDiff: CodexRuntimeGitDiff?
    @Published var workspaceGitStatusText = ""
    @Published var workspacePullRequestStatusText = "未刷新"
    @Published var workspaceWorktrees: [String] = []
    @Published var workspaceBranches: [String] = []
    @Published var workspaceBranchStatusText = "未刷新"
    @Published var workspaceExecutionMode: WorkspaceExecutionMode = .local
    @Published var runtimeCatalogStatusText = "未刷新"
    @Published var runtimeCatalogErrors: [String] = []
    @Published var runtimeCatalogIsRefreshing = false
    @Published var lastMentionInputPreview: [[String: String]] = []
    @Published var pendingLocalImagePaths: [String] = []
    @Published var lastLocalImageInputPreview: [String] = []
    @Published var settingsPane: SettingsPane = .general
    @Published var providers: [RaytoneProviderConfiguration] = RaytoneProviderConfiguration.defaultProviders
    @Published var selectedProviderID = "openai"
    @Published var codexModelCatalog: [CodexAppServerModel] = []
    @Published var sidecarStatusText = "未启动"
    @Published var modelCatalogStatusText = "未刷新"
    @Published var providerConnectionStatusText = "未测试"
    @Published var providerConnectionDetailText = ""
    @Published var providerConnectionBaseURL = ""
    @Published var providerConnectionCodexConfigPath = ""
    @Published var providerConnectionProxyConfigPath = ""
    @Published var providerUsage: RaytoneProxyUsage?
    @Published var providerUsageStatusText = "未读取"
    @Published var runtimeSnapshot = CodexRuntimeSnapshot(executable: nil, version: nil)
    @Published var isRunning = false {
        didSet { updatePreventSleepAssertion() }
    }
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

    nonisolated static var sampleWorkspaceEnabled: Bool {
        let environment = ProcessInfo.processInfo.environment
        if environment["RAYTONE_CODEX_ENABLE_SAMPLE_DATA"] == "1" {
            return true
        }
        return environment["RAYTONE_CODEX_UI_SCREEN"]?.isEmpty == false
    }

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
    private var filePanelWatchID: String?
    private var filePanelWatchedPath: String?
    private var activeTerminalRunID: UUID?
    private var activeTerminalProcessID: String?
    private var activeProxySession: RaytoneProxySession?
    private var preventSleepAssertionID: IOPMAssertionID?
    var appServerEnvironmentOverridesForTesting: [String: String] = [:]

    deinit {
        if let preventSleepAssertionID {
            IOPMAssertionRelease(preventSleepAssertionID)
        }
    }

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
        self.workspacePath = workspacePath
        self.filePanelPath = workspacePath
        self.model = localThread.model
        self.sandbox = localThread.sandbox
        self.approval = localThread.approval
        self.approvalsReviewer = localThread.approvalsReviewer
        self.personality = localThread.personality
        if Self.sampleWorkspaceEnabled {
            let demoThread = SampleData.demoThread(projectID: primaryProject.id)
            let debugThread = SampleData.debugThread(projectID: primaryProject.id)
            let secondary = SampleData.secondaryBundle(workspacePath: workspacePath)
            self.projects = [primaryProject, secondary.project]
            self.threads = [localThread, demoThread, debugThread] + secondary.threads
        } else {
            self.projects = [primaryProject]
            self.threads = [localThread]
        }
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

    var runtimeVersionDisplay: String {
        guard let version = runtimeSnapshot.version,
              !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return runtimeSnapshot.executable == nil ? "未检测到" : "版本未知"
        }
        return version
    }

    var runtimeSourceDisplay: String {
        guard let source = runtimeSnapshot.executable?.source else {
            return "未找到"
        }
        switch source {
        case .appBundle:
            return "App 内置"
        case .environment:
            return "环境变量指定"
        case .officialCodexApp:
            return "已安装 Codex.app"
        case .path:
            return "PATH"
        case .commonPath:
            return "常见安装路径"
        }
    }

    var runtimeBundlingDisplay: String {
        guard let executable = runtimeSnapshot.executable else {
            return runtimeSnapshot.errorDescription ?? "未找到 Codex CLI"
        }
        if executable.source == .appBundle {
            return "已使用 App 内置 CLI"
        }
        return "当前开发/测试使用外部 CLI：\(runtimeSourceDisplay)"
    }

    var runtimeDependencyReady: Bool {
        runtimeSnapshot.executable != nil
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

    var runtimeProfileDisplayName: String {
        guard let account = runtimeAccount else {
            return "未登录 Codex"
        }

        switch account.kind {
        case "chatgpt":
            return account.email?.isEmpty == false ? account.email! : "ChatGPT"
        case "apiKey":
            return "OpenAI API Key"
        case "amazonBedrock":
            return "Amazon Bedrock"
        default:
            return Self.accountDisplayName(account)
        }
    }

    var runtimeProfileHandle: String {
        guard let account = runtimeAccount else {
            return "运行 codex login"
        }
        if let email = account.email,
           let localPart = email.split(separator: "@").first,
           !localPart.isEmpty {
            return "@\(localPart)"
        }
        return account.kind == "notLoggedIn" ? "未连接账户" : account.kind
    }

    var runtimeProfileInitials: String {
        Self.initials(from: runtimeProfileDisplayName)
    }

    var runtimeSkipToolAssistedChats: Bool {
        runtimeConfig?.memoryDisableOnExternalContext ?? false
    }

    var preventSleepAssertionIsActive: Bool {
        preventSleepAssertionID != nil
    }

    static var startupScreenIdentifier: String? {
        ProcessInfo.processInfo.environment["RAYTONE_CODEX_UI_SCREEN"]?.lowercased()
    }

    static var startupScreenDisablesBottomPanel: Bool {
        switch startupScreenIdentifier {
        case "home-compact", "compact-composer", "bottom-panel-off":
            true
        default:
            false
        }
    }

    static var startupScreenTerminalPositionOverride: String? {
        switch startupScreenIdentifier {
        case "terminal", "terminal-panel":
            "右侧"
        case "terminal-bottom", "bottom-terminal":
            "底部"
        default:
            nil
        }
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
            applyRuntimeProviderSettings(config)
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
        if Self.startupScreenDisablesBottomPanel {
            desktopShowBottomPanel = false
        }
        desktopPreventSleepWhileRunning = settings.preventSleepWhileRunning ?? true
        desktopTerminalPosition = Self.startupScreenTerminalPositionOverride ?? settings.terminalPosition ?? "底部"
        desktopAppearance = settings.appearance ?? "跟随系统"
        desktopOpenTarget = settings.openTarget ?? "iTerm2"
        desktopLanguage = settings.language ?? "自动检测"
        updatePreventSleepAssertion()
    }

    private func applyRuntimeProviderSettings(_ config: CodexRuntimeConfig) {
        if !config.raytoneProviders.isEmpty {
            for provider in config.raytoneProviders {
                if let index = providers.firstIndex(where: { $0.id == provider.id }) {
                    providers[index] = provider
                } else {
                    providers.append(provider)
                }
            }
        }

        if let providerID = config.raytoneSelectedProviderID,
           providers.contains(where: { $0.id == providerID }) {
            selectedProviderID = providerID
            if selectedProvider.usesSidecar {
                model = selectedProvider.model
            }
        } else if let providerID = config.modelProvider,
                  providers.contains(where: { $0.id == providerID }) {
            selectedProviderID = providerID
        }

        if let runtimeModel = config.model, !selectedProvider.usesSidecar {
            model = runtimeModel
            if let index = providers.firstIndex(where: { $0.id == selectedProviderID }) {
                providers[index].model = runtimeModel
            }
        }
    }

    private func updatePreventSleepAssertion() {
        if isRunning && desktopPreventSleepWhileRunning {
            acquirePreventSleepAssertionIfNeeded()
        } else {
            releasePreventSleepAssertion()
        }
    }

    private func acquirePreventSleepAssertionIfNeeded() {
        guard preventSleepAssertionID == nil else { return }

        var assertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "RaytoneCodex running Codex turn" as CFString,
            &assertionID
        )

        if result == kIOReturnSuccess {
            preventSleepAssertionID = assertionID
        } else {
            runtimeCatalogErrors.append("防止系统休眠失败：IOKit \(result)")
        }
    }

    private func releasePreventSleepAssertion() {
        guard let assertionID = preventSleepAssertionID else { return }
        IOPMAssertionRelease(assertionID)
        preventSleepAssertionID = nil
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
        isRunning = false
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
        resetActiveTerminal()
        resetFilePanelWatch()
        await proxyService.stop()
        activeProxySession = nil
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
            let localImages = consumePendingLocalImages()
            await steerRunningTurn(trimmedPrompt, localImagePaths: localImages)
            return
        }

        prompt = ""
        if await handleSlashCommand(trimmedPrompt) {
            return
        }

        let localImages = consumePendingLocalImages()
        await runAgentPrompt(trimmedPrompt, localImagePaths: localImages)
    }

    func sendSideChatMessage(_ message: String? = nil) async {
        let source = message ?? sideChatDraft
        let trimmedMessage = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        if message == nil {
            sideChatDraft = ""
        }

        if isRunning {
            sideChatStatusText = "正在通过 turn/steer 追加到当前运行…"
            let didSteer = await steerRunningTurn(trimmedMessage)
            sideChatStatusText = didSteer ? "已追加到当前运行" : "侧边聊天发送失败"
        } else {
            sideChatStatusText = "正在通过 turn/start 发送…"
            await runAgentPrompt(trimmedMessage)
            sideChatStatusText = isRunning ? "已提交，等待 Codex 回复" : "Codex 已回复"
        }
    }

    private func runAgentPrompt(
        _ runtimePrompt: String,
        displayedPrompt: String? = nil,
        localImagePaths: [String] = []
    ) async {
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
            try await runPromptWithAppServer(runtimePrompt, localImagePaths: localImagePaths)
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

    @discardableResult
    private func steerRunningTurn(_ trimmedPrompt: String, localImagePaths: [String] = []) async -> Bool {
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
            return false
        }

        do {
            let mentions = await pluginMentions(in: trimmedPrompt)
            try await client.steer(
                threadID: threadID,
                expectedTurnID: turnID,
                prompt: trimmedPrompt,
                mentions: mentions,
                localImagePaths: localImagePaths
            )
            return true
        } catch {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "继续输入未能发送给 app-server：\(error.localizedDescription)"
                ))))
            }
            return false
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

    func setActiveGoal(objective: String, tokenBudget: Int? = nil) async {
        let trimmedObjective = objective.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedObjective.isEmpty else { return }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 thread/goal/set…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let options = appServerOptions()
            let threadID = try await ensureAppServerThread(client: client, options: options)
            let goal = try await client.setThreadGoal(
                threadID: threadID,
                objective: trimmedObjective,
                status: .active,
                tokenBudget: tokenBudget
            )
            applyRuntimeGoal(goal)
            runtimeCatalogStatusText = "thread/goal/set：\(goal.objective)"
        } catch {
            runtimeCatalogStatusText = "目标创建失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "目标创建失败：\(error.localizedDescription)"
                ))))
            }
        }

        runtimeCatalogIsRefreshing = false
    }

    @discardableResult
    func refreshSelectedRuntimeGoal() async -> CodexRuntimeGoal? {
        guard let threadID = selectedThread.appServerThreadID else {
            runtimeCatalogStatusText = "当前对话没有 app-server threadId"
            return nil
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 thread/goal/get…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let goal = try await client.getThreadGoal(threadID: threadID)
            if let goal {
                applyRuntimeGoal(goal)
                runtimeCatalogStatusText = "thread/goal/get：\(goal.status.rawValue)"
            } else {
                clearRuntimeGoal(threadID: threadID)
                runtimeCatalogStatusText = "thread/goal/get：没有活动目标"
            }
            runtimeCatalogIsRefreshing = false
            return goal
        } catch {
            runtimeCatalogStatusText = "目标读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            return nil
        }
    }

    func updateActiveGoalObjective(_ objective: String) async {
        let trimmedObjective = objective.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedObjective.isEmpty else { return }

        guard selectedThread.activeGoal?.runtimeBacked == true else {
            updateSelectedThread { thread in
                guard let current = thread.activeGoal else { return }
                thread.activeGoal = ActiveGoal(
                    title: trimmedObjective,
                    startedAt: current.startedAt,
                    runtimeBacked: current.runtimeBacked
                )
                thread.updatedAt = Date()
            }
            runtimeCatalogStatusText = "本地目标已更新"
            return
        }

        guard let threadID = selectedThread.appServerThreadID else {
            updateSelectedThread { thread in
                guard let current = thread.activeGoal else { return }
                thread.activeGoal = ActiveGoal(title: trimmedObjective, startedAt: current.startedAt, runtimeBacked: false)
                thread.updatedAt = Date()
            }
            runtimeCatalogStatusText = "目标已本地更新；当前线程没有 app-server threadId"
            return
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 thread/goal/set…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let updatedGoal = try await client.setThreadGoal(threadID: threadID, objective: trimmedObjective)
            applyRuntimeGoal(updatedGoal)
            if let readGoal = try await client.getThreadGoal(threadID: threadID) {
                applyRuntimeGoal(readGoal)
                runtimeCatalogStatusText = "thread/goal/set + get：\(readGoal.objective)"
            } else {
                runtimeCatalogStatusText = "thread/goal/set 已更新；thread/goal/get 未返回目标"
            }
        } catch {
            runtimeCatalogStatusText = "目标更新失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "目标更新失败：\(error.localizedDescription)"
                ))))
            }
        }

        runtimeCatalogIsRefreshing = false
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
            setWorkspacePathForSelectedProject(url.path)
        }
    }

    func setWorkspacePathForSelectedProject(_ path: String) {
        let normalizedPath = URL(fileURLWithPath: path)
            .standardizedFileURL
            .path
        workspacePath = normalizedPath
        filePanelPath = normalizedPath
        updateSelectedProject(path: normalizedPath)
        runtimeCatalogStatusText = "正在切换工作区：\(Project.abbreviate(normalizedPath))"

        Task {
            await refreshWorkspaceBranches()
            await loadFilePanelDirectory(normalizedPath)
            await refreshWorkspaceGitDiff()
        }
    }

    func resetThread() {
        newThread(in: selectedProject.id)
        lastCommandPreview = ""
        lastOutputPath = ""
        lastRawOutput = ""
        pendingLocalImagePaths = []
        lastLocalImageInputPreview = []
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
        updatePreventSleepAssertion()
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

    func startVoiceInput() async {
        await refreshRealtimeVoicesForVoiceInput()

        let didStart = NSApp.sendAction(Selector(("startDictation:")), to: nil, from: nil)
        guard !didStart else {
            voiceInputStatusText = "已请求系统听写 · Codex realtime \(runtimeRealtimeVoicesSummary)"
            return
        }

        updateSelectedThread { thread in
            thread.items.append(TranscriptItem(kind: .notice(Notice(
                level: .info,
                text: "系统没有接受听写命令。Codex realtime 已读取 \(runtimeRealtimeVoicesSummary)。请确认 macOS 已启用听写，或把焦点放到输入框后再点麦克风。"
            ))))
        }
    }

    func refreshRealtimeVoicesForVoiceInput() async {
        voiceInputStatusText = "正在读取 Codex realtime voices…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let voices = try await client.listRealtimeVoices()
            runtimeRealtimeVoices = voices
            voiceInputStatusText = "Codex realtime：v1 \(voices.v1.count) 个 · v2 \(voices.v2.count) 个 · 默认 \(voices.defaultV2)"
        } catch {
            voiceInputStatusText = "Codex realtime voices 读取失败：\(error.localizedDescription)"
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
        Task { await addImageReferencesToPrompt(paths: panel.urls.map(\.path)) }
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

    func addImageReferencesToPrompt(paths: [String]) async {
        let normalizedPaths = paths
            .map { URL(fileURLWithPath: $0).standardizedFileURL.path }
            .filter { !$0.isEmpty }
        guard !normalizedPaths.isEmpty else { return }

        var seenPaths = Set(pendingLocalImagePaths)
        for path in normalizedPaths where !seenPaths.contains(path) {
            pendingLocalImagePaths.append(path)
            seenPaths.insert(path)
        }

        await addFileReferencesToPrompt(paths: normalizedPaths, label: "图片")
    }

    private func consumePendingLocalImages() -> [String] {
        let images = pendingLocalImagePaths
        pendingLocalImagePaths = []
        lastLocalImageInputPreview = images
        return images
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

    func loadFilePanelDirectory(_ path: String? = nil, updateWatch: Bool = true) async {
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
            if updateWatch {
                await watchFilePanelDirectory(targetPath, client: client)
            }
            filePanelStatusText = filePanelWatchID == nil
                ? "\(fileEntries.count) 项"
                : "\(fileEntries.count) 项 · 已监听"
        } catch {
            guard !Self.isCancellation(error) else {
                filePanelStatusText = "读取已取消"
                return
            }
            filePanelStatusText = "读取失败：\(error.localizedDescription)"
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "文件面板无法通过 app-server 读取目录：\(error.localizedDescription)"
                ))))
            }
        }
    }

    private func watchFilePanelDirectory(_ path: String, client: CodexAppServerClient) async {
        if filePanelWatchedPath == path, filePanelWatchID != nil {
            return
        }

        if let oldWatchID = filePanelWatchID {
            try? await client.unwatchFileSystem(watchID: oldWatchID)
        }

        let watchID = "raytone-file-panel-\(UUID().uuidString)"
        do {
            let watchedPath = try await client.watchFileSystem(path: path, watchID: watchID)
            filePanelWatchID = watchID
            filePanelWatchedPath = watchedPath
        } catch {
            filePanelWatchID = nil
            filePanelWatchedPath = nil
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

    func createFileInCurrentPanelDirectory() async {
        guard let name = promptForFilePanelItemName(
            title: "新建文件",
            message: "在当前目录中创建一个空文件。",
            placeholder: "untitled.txt"
        ) else { return }
        await createFileInCurrentPanelDirectory(named: name)
    }

    func createFileInCurrentPanelDirectory(named name: String) async {
        guard let path = filePanelChildPath(named: name) else { return }

        filePanelStatusText = "正在创建文件…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeFile(path: path, data: Data())
            await loadFilePanelDirectory(currentFilePanelDirectoryPath)
            if let entry = fileEntry(matching: path) {
                await openFileEntry(entry)
            } else {
                filePanelStatusText = "已创建 \(Project.abbreviate(path))"
            }
        } catch {
            filePanelStatusText = "创建失败：\(error.localizedDescription)"
        }
    }

    func createDirectoryInCurrentPanelDirectory() async {
        guard let name = promptForFilePanelItemName(
            title: "新建文件夹",
            message: "在当前目录中创建一个文件夹。",
            placeholder: "New Folder"
        ) else { return }
        await createDirectoryInCurrentPanelDirectory(named: name)
    }

    func createDirectoryInCurrentPanelDirectory(named name: String) async {
        guard let path = filePanelChildPath(named: name) else { return }

        filePanelStatusText = "正在创建文件夹…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.createDirectory(path: path, recursive: true)
            await loadFilePanelDirectory(path)
        } catch {
            filePanelStatusText = "创建失败：\(error.localizedDescription)"
        }
    }

    func duplicatePreviewedFileSystemItem() async {
        guard let preview = filePreview else {
            filePanelStatusText = "没有可复制的文件"
            return
        }

        let destinationPath = nextFilePanelCopyPath(for: preview.path)
        filePanelStatusText = "正在复制文件…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.copyFileSystemItem(
                sourcePath: preview.path,
                destinationPath: destinationPath,
                recursive: false
            )
            await loadFilePanelDirectory(currentFilePanelDirectoryPath)
            if let entry = fileEntry(matching: destinationPath) {
                await openFileEntry(entry)
            } else {
                filePanelStatusText = "已复制到 \(Project.abbreviate(destinationPath))"
            }
        } catch {
            filePanelStatusText = "复制失败：\(error.localizedDescription)"
        }
    }

    func removePreviewedFileSystemItem(confirm: Bool = true) async {
        guard let preview = filePreview else {
            filePanelStatusText = "没有可删除的文件"
            return
        }
        guard !confirm || confirmFilePanelRemoval(path: preview.path) else { return }

        let parentPath = URL(fileURLWithPath: preview.path).deletingLastPathComponent().path
        filePanelStatusText = "正在删除文件…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.removeFileSystemItem(path: preview.path, recursive: false, force: false)
            filePreview = nil
            await loadFilePanelDirectory(parentPath)
            filePanelStatusText = "已删除 \(Project.abbreviate(preview.path))"
        } catch {
            filePanelStatusText = "删除失败：\(error.localizedDescription)"
        }
    }

    func openFileEntry(_ entry: WorkspaceFileEntry) async {
        if entry.isDirectory {
            await loadFilePanelDirectory(entry.path)
            return
        }

        let parentPath = URL(fileURLWithPath: entry.path).deletingLastPathComponent().path
        if !Self.filePanelPathsEqual(parentPath, currentFilePanelDirectoryPath) {
            await loadFilePanelDirectory(parentPath)
        }

        filePanelStatusText = "正在读取文件…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let metadata = try await client.getMetadata(path: entry.path)
            let data = try await client.readFile(path: entry.path)
            let maxBytes = 120_000
            let previewData = data.prefix(maxBytes)
            let text = String(data: previewData, encoding: .utf8)
                ?? String(decoding: previewData, as: UTF8.self)
            filePreview = FilePreview(
                path: entry.path,
                text: text,
                isTruncated: data.count > maxBytes,
                byteCount: data.count,
                modifiedAt: metadata.modifiedAtMs > 0
                    ? Date(timeIntervalSince1970: TimeInterval(metadata.modifiedAtMs) / 1000)
                    : nil,
                isSymlink: metadata.isSymlink
            )
            filePanelStatusText = Project.abbreviate(entry.path)
        } catch {
            guard !Self.isCancellation(error) else {
                filePanelStatusText = "读取文件已取消"
                return
            }
            filePanelStatusText = "读取失败：\(error.localizedDescription)"
        }
    }

    private var currentFilePanelDirectoryPath: String {
        filePanelPath.isEmpty ? workspacePath : filePanelPath
    }

    private func fileEntry(matching path: String) -> WorkspaceFileEntry? {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        return fileEntries.first {
            Self.filePanelPathsEqual($0.path, path) || $0.name == fileName
        }
    }

    private static func filePanelPathsEqual(_ lhs: String, _ rhs: String) -> Bool {
        comparableFilePanelPath(lhs) == comparableFilePanelPath(rhs)
    }

    private static func comparableFilePanelPath(_ path: String) -> String {
        URL(fileURLWithPath: path)
            .standardizedFileURL
            .path
            .precomposedStringWithCanonicalMapping
    }

    private func promptForFilePanelItemName(title: String, message: String, placeholder: String) -> String? {
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.placeholderString = placeholder
        field.stringValue = placeholder

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.accessoryView = field
        alert.addButton(withTitle: "创建")
        alert.addButton(withTitle: "取消")

        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func filePanelChildPath(named rawName: String) -> String? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            filePanelStatusText = "名称不能为空"
            return nil
        }
        guard name != "." && name != ".." && !name.contains("/") && !name.contains("\0") else {
            filePanelStatusText = "名称只能是当前目录下的单个文件名"
            return nil
        }

        let url = URL(fileURLWithPath: currentFilePanelDirectoryPath)
            .appendingPathComponent(name)
            .standardizedFileURL
        guard !FileManager.default.fileExists(atPath: url.path) else {
            filePanelStatusText = "已存在：\(name)"
            return nil
        }
        return url.path
    }

    private func nextFilePanelCopyPath(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()
        let extensionName = url.pathExtension
        let baseName = extensionName.isEmpty
            ? url.lastPathComponent
            : String(url.lastPathComponent.dropLast(extensionName.count + 1))

        for index in 1...999 {
            let suffix = index == 1 ? " 副本" : " 副本 \(index)"
            let candidateName = extensionName.isEmpty
                ? "\(baseName)\(suffix)"
                : "\(baseName)\(suffix).\(extensionName)"
            let candidateURL = directory.appendingPathComponent(candidateName)
            if !FileManager.default.fileExists(atPath: candidateURL.path) {
                return candidateURL.path
            }
        }

        let fallbackName = extensionName.isEmpty
            ? "\(baseName) 副本 \(UUID().uuidString)"
            : "\(baseName) 副本 \(UUID().uuidString).\(extensionName)"
        return directory.appendingPathComponent(fallbackName).path
    }

    private func confirmFilePanelRemoval(path: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = "删除文件？"
        alert.informativeText = "将通过 Codex app-server 删除 \(Project.abbreviate(path))。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }

    @discardableResult
    func openSelectedFileInDefaultTarget(performExternalOpen: Bool = true) -> FileOpenTargetRequest? {
        let path = filePreview?.path ?? fileEntries.first?.path ?? workspacePath
        guard let request = fileOpenTargetRequest(for: path) else {
            filePanelStatusText = "无法打开：\(Project.abbreviate(path))"
            return nil
        }

        guard performExternalOpen else {
            filePanelStatusText = "\(request.applicationName)：\(Project.abbreviate(request.launchPath))"
            return request
        }

        switch request.target {
        case .finder:
            NSWorkspace.shared.selectFile(
                request.selectedPath,
                inFileViewerRootedAtPath: URL(fileURLWithPath: request.selectedPath)
                    .deletingLastPathComponent()
                    .path
            )
            filePanelStatusText = "已在 Finder 中显示 \(Project.abbreviate(request.selectedPath))"
        case .terminal, .iTerm2:
            openPathInExternalApplication(request)
        }
        return request
    }

    private func fileOpenTargetRequest(for path: String) -> FileOpenTargetRequest? {
        let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: normalizedPath, isDirectory: &isDirectory) else {
            return nil
        }

        let launchPath = isDirectory.boolValue
            ? normalizedPath
            : URL(fileURLWithPath: normalizedPath).deletingLastPathComponent().path

        switch desktopOpenTarget {
        case "Terminal":
            return FileOpenTargetRequest(
                target: .terminal,
                selectedPath: normalizedPath,
                launchPath: launchPath,
                applicationBundleIdentifier: "com.apple.Terminal",
                applicationName: "Terminal"
            )
        case "iTerm2":
            return FileOpenTargetRequest(
                target: .iTerm2,
                selectedPath: normalizedPath,
                launchPath: launchPath,
                applicationBundleIdentifier: "com.googlecode.iterm2",
                applicationName: "iTerm2"
            )
        default:
            return FileOpenTargetRequest(
                target: .finder,
                selectedPath: normalizedPath,
                launchPath: normalizedPath,
                applicationBundleIdentifier: "com.apple.finder",
                applicationName: "Finder"
            )
        }
    }

    private func openPathInExternalApplication(_ request: FileOpenTargetRequest) {
        let launchURL = URL(fileURLWithPath: request.launchPath)
        guard let bundleIdentifier = request.applicationBundleIdentifier,
              let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            NSWorkspace.shared.selectFile(
                request.selectedPath,
                inFileViewerRootedAtPath: URL(fileURLWithPath: request.selectedPath)
                    .deletingLastPathComponent()
                    .path
            )
            filePanelStatusText = "未找到 \(request.applicationName)，已在 Finder 中显示"
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([launchURL], withApplicationAt: applicationURL, configuration: configuration) { [weak self] _, error in
            Task { @MainActor in
                if let error {
                    self?.filePanelStatusText = "\(request.applicationName) 打开失败：\(error.localizedDescription)"
                } else {
                    self?.filePanelStatusText = "已在 \(request.applicationName) 中打开 \(Project.abbreviate(request.launchPath))"
                }
            }
        }
    }

    func runTerminalCommand() async {
        let command = terminalCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        if terminalIsRunning {
            guard !command.isEmpty else { return }
            await writeTerminalInput(command + "\n")
            return
        }
        guard !command.isEmpty else { return }

        terminalIsRunning = true
        let recordID = UUID()
        let processID = "raytone-terminal-\(UUID().uuidString)"
        activeTerminalRunID = recordID
        activeTerminalProcessID = processID
        terminalRuns.append(TerminalCommandRecord(id: recordID, command: command, processID: processID))

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommandStreaming(
                ["/bin/zsh", "-lc", command],
                processID: processID,
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: sandbox
            )
            let output = [result.stdout, result.stderr]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")
            completeTerminalRun(id: recordID, finalOutput: output, exitCode: result.exitCode)
        } catch {
            failTerminalRun(id: recordID, errorText: error.localizedDescription)
        }

        if activeTerminalRunID == recordID {
            resetActiveTerminal()
        }
    }

    func stopTerminalCommand() async {
        guard terminalIsRunning,
              let processID = activeTerminalProcessID,
              let client = appServerClient else {
            return
        }

        do {
            try await client.terminateCommand(processID: processID)
        } catch {
            if let runID = activeTerminalRunID {
                appendTerminalRunOutput(id: runID, text: "\n终止失败：\(error.localizedDescription)\n")
            }
        }
    }

    private func writeTerminalInput(_ input: String) async {
        guard let processID = activeTerminalProcessID,
              let client = appServerClient else {
            return
        }

        do {
            try await client.writeCommandInput(processID: processID, data: Data(input.utf8))
        } catch {
            if let runID = activeTerminalRunID {
                appendTerminalRunOutput(id: runID, text: "\n写入 stdin 失败：\(error.localizedDescription)\n")
            }
        }
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

    func clearBrowserWebsiteData() async {
        browserDataStatusText = "正在清除浏览数据…"
        let completed = await Self.clearDefaultBrowserWebsiteData(timeoutSeconds: 5)
        browserCanGoBack = false
        browserCanGoForward = false
        browserReloadToken = UUID()
        browserDataStatusText = completed ? "已清除浏览数据和缓存" : "清除浏览数据请求已提交"
    }

    func newBrowserTab() {
        browserURL = nil
        browserTitle = "浏览器"
        browserCanGoBack = false
        browserCanGoForward = false
        browserNavigationCommand = nil
        browserSnapshotRequest = nil
        browserScreenshotStatusText = ""
        browserDataStatusText = ""
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
        guard browserURL != nil else {
            browserScreenshotStatusText = "没有可截图的网页"
            return
        }

        browserScreenshotStatusText = "正在截取网页…"
        browserSnapshotRequest = BrowserSnapshotRequest(outputURL: browserSnapshotOutputURL())
    }

    func completeBrowserPanelScreenshot(request: BrowserSnapshotRequest, result: Result<URL, Error>) {
        guard browserSnapshotRequest?.id == request.id else { return }
        browserSnapshotRequest = nil

        switch result {
        case let .success(url):
            browserScreenshotStatusText = "网页截图：\(Project.abbreviate(url.path))"
        case let .failure(error):
            browserScreenshotStatusText = "截图失败：\(error.localizedDescription)"
        }
    }

    private nonisolated static func clearDefaultBrowserWebsiteData(timeoutSeconds: TimeInterval) async -> Bool {
        await withCheckedContinuation { continuation in
            let box = BrowserWebsiteDataClearContinuation(continuation)
            DispatchQueue.main.async {
                WKWebsiteDataStore.default().removeData(
                    ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                    modifiedSince: .distantPast
                ) {
                    box.resume(true)
                }
            }
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeoutSeconds) {
                box.resume(false)
            }
        }
    }

    private func browserSnapshotOutputURL() -> URL {
        if let overridePath = ProcessInfo.processInfo.environment["RAYTONE_CODEX_BROWSER_SNAPSHOT_PATH"],
           !overridePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return URL(fileURLWithPath: (overridePath as NSString).expandingTildeInPath)
        }

        let directory = URL(fileURLWithPath: workspacePath).appendingPathComponent("screenshots")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return directory.appendingPathComponent("raytonecodex-browser-\(formatter.string(from: Date())).png")
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

    func reloadRuntimeMCPServers() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 config/mcpServer/reload…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.reloadMCPServerRegistry()
            runtimeCatalogStatusText = "config/mcpServer/reload 已完成，正在刷新状态…"
            await refreshRuntimeMCPServers()
        } catch {
            runtimeCatalogStatusText = "MCP 重载失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
        }
    }

    func loginMCPServer(_ server: CodexRuntimeMCPServer) async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在启动 \(server.title) OAuth 登录…"
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let login = try await client.loginMCPServerOAuth(name: server.name, timeoutSecs: 120)
            NSWorkspace.shared.open(login.authorizationURL)
            runtimeCatalogStatusText = "已打开 \(server.title) 授权页面，等待浏览器完成登录…"
        } catch {
            runtimeCatalogStatusText = "\(server.title) 登录失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    func readMCPResource(_ resource: CodexRuntimeMCPResource, from server: CodexRuntimeMCPServer) async {
        runtimeCatalogIsRefreshing = true
        mcpResourceStatusText = "正在读取 \(resource.displayName)…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.readMCPResource(
                server: server.name,
                uri: resource.uri,
                threadID: selectedThread.appServerThreadID
            )
            mcpResourcePreview = result
            mcpResourceStatusText = "mcpServer/resource/read：\(result.contents.count) 段内容"
            runtimeCatalogStatusText = mcpResourceStatusText
        } catch {
            mcpResourceStatusText = "资源读取失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = mcpResourceStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func mcpToolCallKey(_ tool: CodexRuntimeMCPTool, server: CodexRuntimeMCPServer) -> String {
        "\(server.name)::\(tool.name)"
    }

    func callMCPTool(_ tool: CodexRuntimeMCPTool, from server: CodexRuntimeMCPServer) async {
        runtimeCatalogIsRefreshing = true
        mcpToolCallStatusText = "正在调用 \(tool.displayName)…"
        runtimeCatalogErrors = []

        do {
            let key = mcpToolCallKey(tool, server: server)
            let rawArguments = mcpToolArgumentText[key] ?? "{}"
            let trimmedArguments = rawArguments.trimmingCharacters(in: .whitespacesAndNewlines)
            let arguments = try JSONValue(jsonString: trimmedArguments.isEmpty ? "{}" : trimmedArguments)
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let threadID = try await ensureAppServerThread(client: client, options: appServerOptions())
            let result = try await client.callMCPTool(
                threadID: threadID,
                server: server.name,
                tool: tool.name,
                arguments: arguments,
                meta: .object(["source": .string("RaytoneCodex settings")])
            )
            mcpToolCallPreview = result
            mcpToolCallStatusText = "mcpServer/tool/call：\(result.isError ? "工具返回错误" : "调用成功")"
            runtimeCatalogStatusText = mcpToolCallStatusText
        } catch {
            mcpToolCallStatusText = "工具调用失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = mcpToolCallStatusText
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

    func trustRuntimeHook(_ hook: CodexRuntimeHook) async {
        guard !hook.currentHash.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            runtimeCatalogStatusText = "hook 缺少 currentHash，无法写入信任状态"
            return
        }

        await writeRuntimeHookState(
            hook,
            values: ["trusted_hash": .string(hook.currentHash)],
            statusPrefix: "信任"
        )
    }

    func setRuntimeHookEnabled(_ hook: CodexRuntimeHook, enabled: Bool) async {
        await writeRuntimeHookState(
            hook,
            values: ["enabled": .bool(enabled)],
            statusPrefix: enabled ? "启用" : "停用"
        )
    }

    private func writeRuntimeHookState(
        _ hook: CodexRuntimeHook,
        values: [String: JSONValue],
        statusPrefix: String
    ) async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在\(statusPrefix) hook…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.batchWriteConfig(edits: [
                CodexConfigWriteEdit(
                    keyPath: "hooks.state",
                    value: .object([
                        hook.key: .object(values)
                    ])
                )
            ])
            let catalog = try await client.listHooks(cwds: [workspacePath])
            runtimeHooks = catalog.hooks
            runtimeCatalogErrors = catalog.warnings.map { "hooks warning：\($0)" } + catalog.errors.map { "hooks error：\($0)" }
            runtimeCatalogStatusText = "\(statusPrefix) hook：hooks/list 返回 \(catalog.hooks.count) 个钩子"
        } catch {
            runtimeCatalogStatusText = "\(statusPrefix) hook 失败：\(error.localizedDescription)"
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

            await refreshSelectedProviderUsage()

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

    func refreshSelectedProviderUsage() async {
        let provider = selectedProvider
        guard provider.usesSidecar else {
            providerUsage = nil
            providerUsageStatusText = "OpenAI 用量来自 account/usage/read"
            return
        }

        do {
            _ = try await appServerEnvironmentOverrides()
            guard let session = activeProxySession else {
                throw RaytoneProxyServiceError.healthCheckFailed("sidecar 未返回 session")
            }
            let usage = try await proxyService.readUsage(session: session)
            providerUsage = usage
            providerUsageStatusText = "sidecar /usage：\(usage.successfulResponses) 次响应"
        } catch {
            providerUsage = nil
            providerUsageStatusText = "sidecar 用量读取失败：\(error.localizedDescription)"
        }
    }

    func startAccountChatGPTLogin(openBrowser: Bool = true) async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 account/login/start…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let login = try await client.startChatGPTAccountLogin(codexStreamlinedLogin: false)
            activeAccountLogin = login
            if openBrowser, let authURL = login.authURL {
                NSWorkspace.shared.open(authURL)
                runtimeCatalogStatusText = "已打开 ChatGPT 授权页面，等待 account/login/completed…"
            } else if let authURL = login.authURL {
                let host = authURL.host ?? "auth URL"
                runtimeCatalogStatusText = "account/login/start：\(host) · \(login.loginID ?? "无 loginId")"
            } else {
                runtimeCatalogStatusText = "account/login/start：\(login.kind)"
            }
        } catch {
            runtimeCatalogStatusText = "ChatGPT 登录启动失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    @discardableResult
    func loginRuntimeAccountWithAPIKey(_ apiKey: String) async -> Bool {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            runtimeCatalogStatusText = "请输入 OpenAI API Key"
            return false
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 account/login/start(apiKey) 登录…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.loginWithOpenAIAPIKey(trimmedKey)
            activeAccountLogin = nil
            await refreshAccountUsageRuntime()
            runtimeCatalogStatusText = "account/login/start(apiKey)：已登录"
            runtimeCatalogIsRefreshing = false
            return true
        } catch {
            runtimeCatalogStatusText = "API Key 登录失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            return false
        }
    }

    func cancelAccountLogin() async {
        guard let loginID = activeAccountLogin?.loginID else {
            runtimeCatalogStatusText = "没有正在进行的账户登录"
            return
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 account/login/cancel…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let status = try await client.cancelAccountLogin(loginID: loginID)
            activeAccountLogin = nil
            await refreshAccountUsageRuntime()
            runtimeCatalogStatusText = "account/login/cancel：\(status)"
        } catch {
            runtimeCatalogStatusText = "取消登录失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func logoutRuntimeAccount() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 account/logout…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.logoutAccount()
            activeAccountLogin = nil
            runtimeAccount = nil
            runtimeTokenUsage = nil
            runtimeRateLimits = nil
            await refreshAccountUsageRuntime()
            runtimeCatalogStatusText = "account/logout 已完成"
        } catch {
            runtimeCatalogStatusText = "退出登录失败：\(error.localizedDescription)"
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
            archivedRuntimeThreads = mergedArchivedRuntimeThreads(serverThreads: catalog.threads)
            runtimeCatalogStatusText = "thread/list：\(archivedRuntimeThreads.count) 个已归档对话"
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
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在恢复 \(thread.title)…"
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let restoredThread = try await client.unarchiveThread(id: thread.id)
            archivedRuntimeThreads.removeAll { $0.id == thread.id }
            if let restoredThread {
                mergeRuntimeThreads([restoredThread])
            }
            await refreshArchivedThreads()
            await refreshRuntimeThreads(searchTerm: restoredThread?.title ?? thread.title, limit: 20)
            runtimeCatalogStatusText = "thread/unarchive：已恢复 \(restoredThread?.title ?? thread.title)"
        } catch {
            if Self.isRecoverableUnarchiveReadFailure(error) {
                archivedRuntimeThreads.removeAll { $0.id == thread.id }
                mergeRuntimeThreads([CodexRuntimeThreadSummary(
                    id: thread.id,
                    title: thread.title,
                    preview: thread.preview,
                    cwd: thread.cwd,
                    modelProvider: thread.modelProvider,
                    source: thread.source,
                    createdAt: thread.createdAt,
                    updatedAt: ISO8601DateFormatter().string(from: Date()),
                    archived: false,
                    gitBranch: thread.gitBranch,
                    gitSHA: thread.gitSHA,
                    gitOriginURL: thread.gitOriginURL
                )])
                await refreshArchivedThreads()
                runtimeCatalogStatusText = "thread/unarchive：已恢复 \(thread.title)"
                runtimeCatalogErrors = []
                runtimeCatalogIsRefreshing = false
                return
            }
            runtimeCatalogStatusText = "恢复失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    func archiveRuntimeThread(
        id threadID: String,
        title: String? = nil,
        preview: String? = nil,
        cwd: String? = nil
    ) async {
        runtimeCatalogStatusText = "正在归档对话…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.archiveThread(id: threadID)
            rememberArchivedRuntimeThread(id: threadID, title: title, preview: preview, cwd: cwd)
            runtimeCatalogStatusText = "thread/archive：已归档 \(threadID)"
        } catch {
            runtimeCatalogStatusText = "归档失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    private func rememberArchivedRuntimeThread(id threadID: String, title: String?, preview: String?, cwd: String?) {
        let now = ISO8601DateFormatter().string(from: Date())
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedPreview = preview?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let summary = CodexRuntimeThreadSummary(
            id: threadID,
            title: trimmedTitle.isEmpty ? "未命名对话" : trimmedTitle,
            preview: trimmedPreview,
            cwd: cwd,
            modelProvider: nil,
            source: nil,
            createdAt: now,
            updatedAt: now,
            archived: true,
            gitBranch: nil,
            gitSHA: nil,
            gitOriginURL: nil
        )
        archivedRuntimeThreads.removeAll { $0.id == threadID }
        archivedRuntimeThreads.insert(summary, at: 0)
    }

    private func mergedArchivedRuntimeThreads(serverThreads: [CodexRuntimeThreadSummary]) -> [CodexRuntimeThreadSummary] {
        var seenIDs = Set(serverThreads.map(\.id))
        var merged = serverThreads
        for thread in archivedRuntimeThreads where !seenIDs.contains(thread.id) {
            merged.append(thread)
            seenIDs.insert(thread.id)
        }
        return merged
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

    func refreshWorkspacePullRequestStatus() async {
        workspacePullRequestStatusText = "正在读取 PR 状态…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommand(
                ["/bin/zsh", "-lc", Self.pullRequestStatusCommand],
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: .readOnly,
                timeoutMs: 20_000
            )
            let output = [result.stdout, result.stderr]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            workspacePullRequestStatusText = output.isEmpty ? "没有 PR 状态输出" : output
        } catch {
            workspacePullRequestStatusText = "PR 状态读取失败：\(error.localizedDescription)"
        }
    }

    func refreshWorkspaceEnvironment() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在刷新工作区环境…"
        runtimeCatalogErrors = []

        await refreshWorkspaceBranches()
        await refreshWorkspaceGitDiff()
        await refreshWorkspacePullRequestStatus()
        await refreshWorkspaceWorktrees()

        let diff = workspaceGitDiff.map { Self.diffSummary($0.diff) }
        let statusCount = workspaceGitStatusText
            .split(separator: "\n", omittingEmptySubsequences: true)
            .filter { !$0.hasPrefix("##") }
            .count
        let changeText: String
        if let diff {
            changeText = "\(diff.files) 个文件 · +\(diff.additions) −\(diff.deletions)"
        } else if statusCount > 0 {
            changeText = "Git 状态 \(statusCount) 项"
        } else {
            changeText = "无变更"
        }
        runtimeCatalogStatusText = "环境已刷新：\(workspaceBranches.count) 个分支 · \(changeText) · \(workspaceWorktrees.count) 个工作树"
        runtimeCatalogIsRefreshing = false
    }

    func runGitCommitPushPreflightInTerminal() async {
        showInspector = true
        openToolPanel(.terminal)
        terminalCommand = Self.gitCommitPushPreflightCommand
        await runTerminalCommand()
    }

    func runGitDiffInTerminal() async {
        showInspector = true
        openToolPanel(.terminal)
        terminalCommand = "git status --short --branch && git diff --stat && git diff -- ."
        await runTerminalCommand()
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
            Task { await disableRemoteControlMode() }
        case .cloudPending:
            route = .settings
            settingsPane = .connections
            Task { await enableRemoteControlMode() }
        }
    }

    func refreshRemoteControlStatus() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 remoteControl/status/read 读取云端模式…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false, remoteControl: true)
            let status = try await client.readRemoteControlStatus()
            runtimeRemoteControlStatus = status
            workspaceExecutionMode = status.status == "disabled" ? .local : .cloudPending
            runtimeCatalogStatusText = "remoteControl/status/read：\(Self.remoteControlStatusDisplayName(status.status))"
        } catch {
            runtimeCatalogStatusText = "remoteControl/status/read 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func enableRemoteControlMode() async {
        workspaceExecutionMode = .cloudPending
        route = .settings
        settingsPane = .connections
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 remoteControl/enable 启用云端模式…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false, remoteControl: true)
            let status = try await client.enableRemoteControl()
            runtimeRemoteControlStatus = status
            runtimeCatalogStatusText = "remoteControl/enable：\(Self.remoteControlStatusDisplayName(status.status))"
        } catch {
            workspaceExecutionMode = .local
            runtimeCatalogStatusText = "remoteControl/enable 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func disableRemoteControlMode() async {
        workspaceExecutionMode = .local
        runtimeRemoteControlPairing = nil
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 remoteControl/disable 停用云端模式…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false, remoteControl: true)
            let status = try await client.disableRemoteControl()
            runtimeRemoteControlStatus = status
            runtimeCatalogStatusText = "remoteControl/disable：\(Self.remoteControlStatusDisplayName(status.status))"
        } catch {
            runtimeCatalogStatusText = "remoteControl/disable 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func startRemoteControlPairing(manualCode: Bool = true) async {
        workspaceExecutionMode = .cloudPending
        route = .settings
        settingsPane = .connections
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 remoteControl/pairing/start 生成配对码…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false, remoteControl: true)
            runtimeRemoteControlStatus = try await client.enableRemoteControl()
            let pairing = try await client.startRemoteControlPairing(manualCode: manualCode)
            runtimeRemoteControlPairing = pairing
            let manualText = pairing.manualPairingCode.map { " · 手动码 \($0)" } ?? ""
            runtimeCatalogStatusText = "remoteControl/pairing/start：\(pairing.pairingCode)\(manualText)"
        } catch {
            runtimeCatalogStatusText = "remoteControl/pairing/start 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
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
            if runtimePluginDetail?.plugin.id == plugin.id,
               let refreshed = runtimePlugins.first(where: { $0.id == plugin.id }) {
                await readRuntimePluginDetail(refreshed)
            }
        } catch {
            runtimeCatalogStatusText = "插件操作失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func readRuntimePluginDetail(_ plugin: CodexRuntimePlugin) async {
        runtimeCatalogIsRefreshing = true
        runtimePluginDetailStatusText = "正在读取 \(plugin.displayName)…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let detail = try await client.readPlugin(plugin)
            runtimePluginDetail = detail
            runtimePluginDetailStatusText = "plugin/read：\(detail.skills.count) 个技能 · \(detail.mcpServers.count) 个 MCP · \(detail.hooks.count) 个钩子 · \(detail.apps.count) 个 app"
            runtimeCatalogStatusText = runtimePluginDetailStatusText
        } catch {
            runtimePluginDetailStatusText = "插件详情读取失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimePluginDetailStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
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

    @discardableResult
    func usePluginInComposer(_ plugin: CodexRuntimePlugin) async -> Bool {
        runtimeCatalogStatusText = "正在读取 \(plugin.displayName) 的 plugin/read…"
        runtimePluginDetailStatusText = runtimeCatalogStatusText
        runtimeCatalogErrors = []

        var detail: CodexRuntimePluginDetail?
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            detail = try await client.readPlugin(plugin)
            runtimePluginDetail = detail
            if let detail {
                runtimePluginDetailStatusText = "plugin/read：已准备 @\(plugin.name) · \(detail.skills.count) 个技能 · \(detail.mcpServers.count) 个 MCP"
                runtimeCatalogStatusText = runtimePluginDetailStatusText
            }
        } catch {
            runtimePluginDetailStatusText = "plugin/read 失败，已准备基础 @提及：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimePluginDetailStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }

        prompt = Self.pluginTrialPrompt(for: plugin, detail: detail)
        _ = await previewPluginMentions(for: prompt)
        route = .thread
        return detail != nil
    }

    private static func pluginTrialPrompt(for plugin: CodexRuntimePlugin, detail: CodexRuntimePluginDetail?) -> String {
        let activePlugin = detail?.plugin ?? plugin
        var lines = [
            "@\(activePlugin.name) 请用中文说明你能在当前项目里做什么，并给出一个最小可执行示例。",
            "插件摘要：\(detail?.description ?? activePlugin.summary)"
        ]

        if let detail {
            let skills = detail.skills.prefix(4).map { "\($0.displayName)（\($0.enabled ? "启用" : "停用")）" }
            let apps = detail.apps.prefix(4).map { "\($0.name)（\($0.needsAuth ? "需要授权" : "可用")）" }
            if !skills.isEmpty {
                lines.append("技能：\(skills.joined(separator: "、"))")
            }
            if !detail.mcpServers.isEmpty {
                lines.append("MCP：\(detail.mcpServers.prefix(4).joined(separator: "、"))")
            }
            if !detail.hooks.isEmpty {
                let hooks = detail.hooks.prefix(4).map { "\($0.eventName):\($0.key)" }
                lines.append("钩子：\(hooks.joined(separator: "、"))")
            }
            if !apps.isEmpty {
                lines.append("App：\(apps.joined(separator: "、"))")
            }
        }

        lines.append("如果需要安装、授权或启用 MCP，请先明确下一步和验证方法。")
        return lines.joined(separator: "\n")
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
                    hook.source.localizedCaseInsensitiveCompare("user") == .orderedSame &&
                    !Self.isRaytoneAutomationHook(hook)
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

            if let hook = runtimeHooks.first(where: Self.isRaytoneAutomationHook),
               !hook.currentHash.isEmpty,
               !Self.isTrustedHook(hook) {
                try await client.batchWriteConfig(edits: [
                    CodexConfigWriteEdit(
                        keyPath: "hooks.state",
                        value: .object([
                            hook.key: .object([
                                "trusted_hash": .string(hook.currentHash)
                            ])
                        ])
                    )
                ])
                await refreshRuntimeHooks()
            }

            let raytoneHook = runtimeHooks.first(where: Self.isRaytoneAutomationHook)
            let trustSuffix = raytoneHook.map(Self.isTrustedHook) == true ? " · 已信任" : ""
            runtimeCatalogStatusText = "已安装 \(title)：hooks/list 返回 \(runtimeHooks.count) 个钩子\(trustSuffix)"
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
        let url = ensureCodexHomeSubfolder(subfolder)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @discardableResult
    func ensureCodexHomeSubfolder(_ subfolder: String) -> URL {
        let trimmedSubfolder = subfolder.trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespacesAndNewlines))
        let codexHomeURL = Self.defaultCodexConfigURL(
            overrideCodexHome: appServerEnvironmentOverridesForTesting["CODEX_HOME"]
        )
        .deletingLastPathComponent()
        let url = trimmedSubfolder.isEmpty
            ? codexHomeURL
            : codexHomeURL.appendingPathComponent(trimmedSubfolder, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let label = trimmedSubfolder.isEmpty ? "home" : trimmedSubfolder
        runtimeCatalogStatusText = "已准备 Codex \(label) 目录：\(Project.abbreviate(url.path))"
        return url
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

    private func appendTerminalRunOutput(id: UUID, text: String) {
        guard let index = terminalRuns.firstIndex(where: { $0.id == id }) else { return }
        terminalRuns[index].output.append(text)
    }

    private func completeTerminalRun(id: UUID, finalOutput: String, exitCode: Int32) {
        guard let index = terminalRuns.firstIndex(where: { $0.id == id }) else { return }
        if !finalOutput.isEmpty {
            if !terminalRuns[index].output.isEmpty {
                terminalRuns[index].output.append("\n")
            }
            terminalRuns[index].output.append(finalOutput)
        } else if terminalRuns[index].output.isEmpty {
            terminalRuns[index].output = "命令无输出"
        }
        terminalRuns[index].exitCode = exitCode
        terminalRuns[index].status = exitCode == 0 ? .succeeded : .failed
    }

    private func failTerminalRun(id: UUID, errorText: String) {
        guard let index = terminalRuns.firstIndex(where: { $0.id == id }) else { return }
        if terminalRuns[index].output.isEmpty {
            terminalRuns[index].output = errorText
        } else {
            terminalRuns[index].output.append("\n\(errorText)")
        }
        terminalRuns[index].exitCode = nil
        terminalRuns[index].status = .failed
    }

    func selectProvider(_ providerID: String) {
        guard providers.contains(where: { $0.id == providerID }) else { return }
        selectedProviderID = providerID
        model = selectedProvider.usesSidecar ? selectedProvider.model : model
        updateSelectedThread { thread in
            thread.model = model
        }
        Task {
            await persistRuntimeProviderSettings(statusName: "Provider 选择")
            await resetAppServerForProviderChange()
        }
    }

    func chooseProviderModel(providerID: String, model: String) {
        guard applyProviderModelSelection(providerID: providerID, model: model) != nil else { return }
        Task {
            await persistRuntimeProviderSettings(statusName: "Provider 模型")
            await resetAppServerForProviderChange()
        }
    }

    func saveProviderEndpoint(providerID: String, baseURL: String, model selectedModel: String) async {
        let trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = selectedModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBaseURL.isEmpty else {
            providerConnectionStatusText = "Base URL 不能为空"
            return
        }
        guard let endpointURL = URL(string: trimmedBaseURL),
              endpointURL.scheme?.isEmpty == false,
              endpointURL.host?.isEmpty == false else {
            providerConnectionStatusText = "Base URL 格式无效"
            return
        }
        guard !trimmedModel.isEmpty else {
            providerConnectionStatusText = "模型不能为空"
            return
        }
        guard let index = providers.firstIndex(where: { $0.id == providerID }) else {
            providerConnectionStatusText = "未找到 provider：\(providerID)"
            return
        }
        guard providers[index].usesSidecar else {
            providerConnectionStatusText = "OpenAI provider 使用 Codex 原生 model/list"
            return
        }

        providers[index].baseURL = trimmedBaseURL
        providers[index].model = trimmedModel
        if !providers[index].models.contains(trimmedModel) {
            providers[index].models.insert(trimmedModel, at: 0)
        }
        selectedProviderID = providerID
        model = trimmedModel
        updateSelectedThread { thread in
            thread.model = trimmedModel
        }
        providerConnectionStatusText = "已更新 \(providers[index].displayName) 端点"
        providerConnectionDetailText = "\(trimmedBaseURL) · \(trimmedModel)"
        modelCatalogStatusText = "\(providers[index].displayName) 将通过 sidecar 使用 \(trimmedModel)"
        await persistRuntimeProviderSettings(statusName: "\(providers[index].displayName) 端点")
        await resetAppServerForProviderChange()
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
            await persistRuntimeProviderSettings(statusName: "\(provider.displayName) 模型")
            await resetAppServerForProviderChange()
            modelCatalogStatusText = "\(provider.displayName) 将通过 sidecar 会话使用 \(selectedModel)"
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
            await persistRuntimeProviderSettings(statusName: "Provider Thinking")
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

    func testProviderConnection(providerID: String? = nil) async {
        let id = providerID ?? selectedProviderID
        guard let provider = providers.first(where: { $0.id == id }) else {
            providerConnectionStatusText = "未找到 provider：\(id)"
            providerConnectionDetailText = ""
            return
        }

        selectedProviderID = provider.id
        await resetAppServerForProviderChange()
        providerConnectionStatusText = "正在测试 \(provider.displayName)…"
        providerConnectionDetailText = ""
        providerConnectionBaseURL = ""
        providerConnectionCodexConfigPath = ""
        providerConnectionProxyConfigPath = ""

        guard provider.usesSidecar else {
            await refreshModelCatalog()
            let count = codexModelCatalog.count
            providerConnectionStatusText = count > 0 ? "model/list：\(count) 个模型" : modelCatalogStatusText
            providerConnectionDetailText = "Codex 原生 app-server model/list"
            return
        }

        do {
            _ = try await appServerEnvironmentOverrides()
            guard let session = activeProxySession else {
                throw RaytoneProxyServiceError.healthCheckFailed("sidecar 已启动但没有返回 session")
            }
            let upstream = try await proxyService.verifyUpstreamConnection(session: session)

            providerConnectionBaseURL = session.baseURL.absoluteString
            providerConnectionProxyConfigPath = session.configURL.path
            providerConnectionCodexConfigPath = session.codexHomeURL
                .appendingPathComponent("config.toml")
                .path
            providerConnectionStatusText = "上游已验证：\(provider.displayName)"
            providerConnectionDetailText = "\(upstream.modelsEndpoint) · \(upstream.modelCount) 个模型 · 当前 \(upstream.model)"
            runtimeCatalogStatusText = "Provider 测试通过：\(provider.displayName) via \(providerConnectionBaseURL)"
            await persistRuntimeProviderSettings(statusName: "\(provider.displayName) 连接")
        } catch {
            providerConnectionStatusText = "测试失败：\(error.localizedDescription)"
            providerConnectionDetailText = provider.apiKeyEnvironmentName.map { "Keychain 或 \($0)" } ?? "Keychain"
            runtimeCatalogStatusText = providerConnectionStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    private func persistRuntimeProviderSettings(statusName: String) async {
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.batchWriteConfig(edits: [
                CodexConfigWriteEdit(
                    keyPath: "desktop.raytone.selected_provider_id",
                    value: .string(selectedProviderID)
                ),
                CodexConfigWriteEdit(
                    keyPath: "desktop.raytone.providers_json",
                    value: .string(Self.providersConfigJSONString(providers.filter(\.usesSidecar)))
                )
            ])
            applyRuntimeConfig(try await client.readConfig(cwd: workspacePath, includeLayers: true))
            runtimeCatalogStatusText = "\(statusName) 已写入 desktop.raytone"
        } catch {
            runtimeCatalogStatusText = "\(statusName) 写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    private static func providersConfigJSONString(_ providers: [RaytoneProviderConfiguration]) -> String {
        let value = JSONValue.array(providers.map(providerConfigValue))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(value),
              let text = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return text
    }

    private static func providerConfigValue(_ provider: RaytoneProviderConfiguration) -> JSONValue {
        var object: [String: JSONValue] = [
            "id": .string(provider.id),
            "displayName": .string(provider.displayName),
            "baseURL": .string(provider.baseURL),
            "model": .string(provider.model),
            "models": .array(provider.models.map(JSONValue.string)),
            "kind": .string(provider.kind.rawValue)
        ]
        if let apiKeyEnvironmentName = provider.apiKeyEnvironmentName {
            object["apiKeyEnvironmentName"] = .string(apiKeyEnvironmentName)
        }
        if let reasoning = provider.reasoning {
            object["reasoning"] = .object([
                "supportsThinking": .bool(reasoning.supportsThinking),
                "supportsEffort": .bool(reasoning.supportsEffort),
                "thinkingParam": .string(reasoning.thinkingParam),
                "effortParam": .string(reasoning.effortParam),
                "effortValueMode": reasoning.effortValueMode.map(JSONValue.string) ?? .null,
                "outputFormat": .string(reasoning.outputFormat)
            ])
        }
        return .object(object)
    }

    private func runPromptWithAppServer(_ trimmedPrompt: String, localImagePaths: [String] = []) async throws {
        let options = appServerOptions()
        let client = try await ensureAppServerClient()
        let mentions = await pluginMentions(in: trimmedPrompt)
        let threadID = try await ensureAppServerThread(client: client, options: options)

        let turn = try await client.startTurn(
            threadID: threadID,
            prompt: trimmedPrompt,
            options: options,
            mentions: mentions,
            localImagePaths: localImagePaths
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

    private func ensureAppServerClient(
        useProviderConfiguration: Bool = true,
        remoteControl: Bool = false
    ) async throws -> CodexAppServerClient {
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
        let baseEnvironmentKey: String
        if let codexHome = environmentOverrides["CODEX_HOME"] {
            baseEnvironmentKey = codexHome
        } else if useProviderConfiguration {
            baseEnvironmentKey = "global"
        } else {
            baseEnvironmentKey = selectedProvider.usesSidecar ? "global-tools" : "global"
        }
        let environmentKey = "\(baseEnvironmentKey)|remoteControl:\(remoteControl)"
        if appServerEnvironmentKey != nil, appServerEnvironmentKey != environmentKey {
            if let existing = appServerClient {
                await existing.stop()
            }
            appServerClient = nil
            appServerEventsTask?.cancel()
            appServerEventsTask = nil
            appServerItemIDs.removeAll()
            activeDiffTranscriptIDs.removeAll()
            resetActiveTerminal()
            resetFilePanelWatch()
        }
        appServerEnvironmentKey = environmentKey

        let client: CodexAppServerClient
        if let existing = appServerClient {
            client = existing
        } else {
            client = CodexAppServerClient(
                executable: executable,
                workspaceURL: URL(fileURLWithPath: workspacePath),
                environmentOverrides: environmentOverrides,
                remoteControl: remoteControl
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
        resetActiveTerminal()
        resetFilePanelWatch()
        await proxyService.stop()
        activeProxySession = nil
        appServerConnectionState = nil
        sidecarStatusText = selectedProvider.usesSidecar ? "未启动" : "直连"
    }

    private func resetFilePanelWatch() {
        filePanelWatchID = nil
        filePanelWatchedPath = nil
    }

    private func resetActiveTerminal() {
        terminalIsRunning = false
        activeTerminalRunID = nil
        activeTerminalProcessID = nil
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
            "\(workspacePath)/sidecar/raytone-proxy/target/release/raytone-proxy",
            "\(workspacePath)/.build/raytone-codex-cli/raytone-proxy"
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
            if sideChatStatusText.hasPrefix("已提交") ||
                sideChatStatusText.hasPrefix("已追加") ||
                sideChatStatusText.hasPrefix("正在通过 turn/start") ||
                sideChatStatusText.hasPrefix("正在通过 turn/steer") {
                sideChatStatusText = "Codex 已回复"
            }
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
        case "skills/changed":
            if !isRunning {
                Task { await refreshRuntimeCatalog(forceReloadSkills: true) }
            }
        case "mcpServer/startupStatus/updated":
            let name = params?["name"]?.stringValue ?? "MCP"
            let status = params?["status"]?.stringValue ?? "updated"
            if let error = params?["error"]?.stringValue, !error.isEmpty {
                runtimeCatalogStatusText = "\(name)：\(status) · \(error)"
                runtimeCatalogErrors = [error]
            } else {
                runtimeCatalogStatusText = "\(name)：\(status)"
            }
            if !isRunning {
                Task { await refreshRuntimeMCPServers() }
            }
        case "mcpServer/oauthLogin/completed":
            let name = params?["name"]?.stringValue ?? "MCP"
            let success = params?["success"]?.boolValue ?? false
            if success {
                runtimeCatalogStatusText = "\(name) OAuth 登录完成"
                runtimeCatalogErrors = []
            } else {
                let error = params?["error"]?.stringValue ?? "OAuth 登录失败"
                runtimeCatalogStatusText = "\(name) OAuth 登录失败"
                runtimeCatalogErrors = [error]
            }
            Task { await refreshRuntimeMCPServers() }
        case "account/login/completed":
            let success = params?["success"]?.boolValue ?? false
            activeAccountLogin = nil
            if success {
                runtimeCatalogStatusText = "account/login/completed：登录成功"
                runtimeCatalogErrors = []
                appServerConnectionState = nil
            } else {
                let error = params?["error"]?.stringValue ?? "登录未完成"
                runtimeCatalogStatusText = "account/login/completed：\(error)"
                runtimeCatalogErrors = [error]
            }
            Task { await refreshAccountUsageRuntime() }
        case "account/updated":
            let authMode = params?["authMode"]?.stringValue ?? "未知"
            let planType = params?["planType"]?.stringValue ?? "未返回"
            runtimeCatalogStatusText = "account/updated：\(authMode) · \(planType)"
            runtimeCatalogErrors = []
            appServerConnectionState = nil
            Task { await refreshAccountUsageRuntime() }
        case "account/rateLimits/updated", "thread/tokenUsage/updated":
            Task { await refreshAccountUsageRuntime() }
        case "remoteControl/status/changed":
            let status = CodexAppServerClient.remoteControlStatus(from: params)
            runtimeRemoteControlStatus = status
            workspaceExecutionMode = status.status == "disabled" ? .local : .cloudPending
            runtimeCatalogStatusText = "remoteControl/status/changed：\(Self.remoteControlStatusDisplayName(status.status))"
            runtimeCatalogErrors = []
        case "fs/changed":
            handleFileSystemChanged(params)
        case "command/exec/outputDelta":
            handleTerminalOutputDelta(params)
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

    private func handleFileSystemChanged(_ params: JSONValue?) {
        guard let watchID = params?["watchId"]?.stringValue,
              watchID == filePanelWatchID,
              let watchedPath = filePanelWatchedPath else {
            return
        }

        let changedPaths = params?["changedPaths"]?.arrayValue?
            .compactMap(\.stringValue)
            .map(Project.abbreviate)
            .joined(separator: "、") ?? "工作区文件"
        filePanelStatusText = "检测到变化：\(changedPaths)"
        Task { await loadFilePanelDirectory(watchedPath, updateWatch: false) }
    }

    private func handleTerminalOutputDelta(_ params: JSONValue?) {
        guard let processID = params?["processId"]?.stringValue,
              let deltaBase64 = params?["deltaBase64"]?.stringValue,
              let data = Data(base64Encoded: deltaBase64) else {
            return
        }

        let stream = params?["stream"]?.stringValue ?? "stdout"
        let output = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
        let cappedSuffix = params?["capReached"]?.boolValue == true ? "\n[\(stream) 输出已截断]\n" : ""
        if let runID = terminalRuns.first(where: { $0.processID == processID })?.id {
            appendTerminalRunOutput(id: runID, text: output + cappedSuffix)
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

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }
        return error.localizedDescription.contains("CancellationError")
    }

    private static func isRecoverableUnarchiveReadFailure(_ error: Error) -> Bool {
        let description = error.localizedDescription
        return description.contains("failed to unarchive session") &&
            description.contains("failed to read unarchived thread")
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

    private static let pullRequestStatusCommand = """
    set +e
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "不是 Git 工作区"
      exit 0
    fi
    branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
      echo "detached HEAD，无法关联 PR"
      exit 0
    fi
    if ! command -v gh >/dev/null 2>&1; then
      echo "未安装 GitHub CLI，无法查询 PR"
      exit 0
    fi
    if ! gh auth status -h github.com >/dev/null 2>&1; then
      echo "GitHub CLI 未登录，无法查询 PR"
      exit 0
    fi
    out=$(gh pr view "$branch" --json number,state,title,isDraft,reviewDecision,headRefName,baseRefName,url --jq 'def state_name: if .state == "OPEN" then "打开" elif .state == "MERGED" then "已合并" elif .state == "CLOSED" then "已关闭" else .state end; def review_name: if .reviewDecision == "APPROVED" then "已批准" elif .reviewDecision == "CHANGES_REQUESTED" then "需修改" elif .reviewDecision == "REVIEW_REQUIRED" then "待审查" else "未审查" end; "PR #\\(.number) \\(state_name)\\(if .isDraft then " · 草稿" else "" end) · \\(review_name) · \\(.headRefName)→\\(.baseRefName) · \\(.title)"' 2>&1)
    status=$?
    if [ $status -eq 0 ]; then
      echo "$out"
      exit 0
    fi
    case "$out" in
      *"no pull requests found"*|*"no pull request"*|*"not found"*)
        echo "当前分支 $branch 无 PR"
        ;;
      *)
        printf "PR 状态不可用：%s\\n" "$out"
        ;;
    esac
    """

    private static let gitCommitPushPreflightCommand = """
    set +e
    echo "== Git 状态 =="
    git status --short --branch
    echo
    echo "== 变更统计 =="
    git diff --stat
    echo
    echo "== 最近提交 =="
    git log --oneline --decorate -5
    echo
    echo "== 安全建议 =="
    branch=$(git branch --show-current 2>/dev/null)
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    if [ -z "$branch" ]; then
      echo "当前是 detached HEAD；请先切到分支，再提交或推送。"
    elif [ -z "$upstream" ]; then
      echo "确认变更后可手动执行：git add -A && git commit -m '<message>' && git push -u origin $branch"
    else
      echo "确认变更后可手动执行：git add -A && git commit -m '<message>' && git push"
    fi
    """

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

    nonisolated static func remoteControlStatusDisplayName(_ value: String?) -> String {
        switch value {
        case "connected": "已连接"
        case "connecting": "连接中"
        case "errored": "错误"
        case "disconnected": "未连接"
        case "disabled": "已停用"
        case nil: "未返回"
        default: value ?? "未返回"
        }
    }

    static func initials(from value: String) -> String {
        let words = value
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
        let initials = words
            .prefix(2)
            .compactMap(\.first)
            .map { String($0).uppercased() }
            .joined()
        if !initials.isEmpty {
            return initials
        }
        return String(value.prefix(2)).uppercased()
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

    private static func isRaytoneAutomationHook(_ hook: CodexRuntimeHook) -> Bool {
        isUserPromptSubmitHook(hook) &&
            hook.command?.contains("raytone-automation-events.jsonl") == true
    }

    private static func isTrustedHook(_ hook: CodexRuntimeHook) -> Bool {
        hook.trustStatus.localizedCaseInsensitiveCompare("trusted") == .orderedSame ||
            hook.trustStatus.localizedCaseInsensitiveCompare("managed") == .orderedSame
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

private final class BrowserWebsiteDataClearContinuation: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Bool, Never>?

    init(_ continuation: CheckedContinuation<Bool, Never>) {
        self.continuation = continuation
    }

    func resume(_ result: Bool) {
        lock.lock()
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: result)
    }
}
