import AppKit
import Foundation
import IOKit.pwr_mgt
import RaytoneCodexCore
import UniformTypeIdentifiers
import WebKit

struct CodexRuntimeScaffoldResult: Equatable {
    var kind: String
    var rootPath: String
    var files: [String]
    var readBackSnippets: [String: String]
    var discoveredPluginID: String?
    var discoveredSkillPath: String?
    var source: String
}

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
    @Published var browserAttachedSnapshotPath = ""
    @Published var browserDataStatusText = ""
    @Published var filePanelPath = ""
    @Published var fileEntries: [WorkspaceFileEntry] = []
    @Published var filePreview: FilePreview?
    @Published var filePanelStatusText = "未加载"
    @Published var filePanelLastOperationSource = "fs/readDirectory"
    @Published var inspectorRecommendedFilePaths: [String] = []
    @Published var inspectorRecommendedFilesSource = "未刷新"
    @Published var fileSearchQuery = ""
    @Published var fileSearchResults: [WorkspaceFileEntry] = []
    @Published var fileSearchStatusText = ""
    @Published var fileSearchIsRunning = false
    @Published var terminalCommand = "pwd && ls -la"
    @Published var terminalRows = 30
    @Published var terminalCols = 100
    @Published var terminalRuns: [TerminalCommandRecord] = []
    @Published var terminalIsRunning = false
    @Published var terminalResizeStatusText = "30×100"
    @Published var threadShellCommandStatusText = "未发送"
    @Published var backgroundTerminalCleanStatusText = "未清理"
    @Published var sideChatDraft = ""
    @Published var sideChatStatusText = "未发送"
    @Published var runtimePlugins: [CodexRuntimePlugin] = []
    @Published var runtimePluginDetail: CodexRuntimePluginDetail?
    @Published var runtimePluginDetailStatusText = "未读取"
    @Published var runtimePluginSkillPreview: CodexRuntimePluginSkill?
    @Published var runtimePluginSkillPreviewText = ""
    @Published var runtimePluginSkillPreviewStatusText = "未读取"
    @Published var runtimePluginInstallResult: CodexRuntimePluginInstallResult?
    @Published var runtimeSharedPluginCount = 0
    @Published var runtimeSkills: [CodexRuntimeSkill] = []
    @Published var runtimeSkillExtraRoots: [String] = []
    @Published var runtimeSkillPreview: CodexRuntimeSkill?
    @Published var runtimeSkillPreviewText = ""
    @Published var runtimeSkillPreviewStatusText = "未读取"
    @Published var runtimeExperimentalFeatures: [CodexExperimentalFeature] = []
    @Published var runtimeExperimentalFeaturesNextCursor: String?
    @Published var runtimeExperimentalFeaturesStatusText = "未读取"
    @Published var runtimeHooks: [CodexRuntimeHook] = []
    @Published var automationEventLogText = ""
    @Published var automationEventLogStatusText = "未读取"
    @Published var runtimeMCPServers: [CodexRuntimeMCPServer] = []
    @Published var mcpResourcePreview: CodexMCPResourceReadResult?
    @Published var mcpResourceStatusText = "未读取"
    @Published var mcpToolArgumentText: [String: String] = [:]
    @Published var mcpResourceTemplateURIText: [String: String] = [:]
    @Published var mcpToolCallPreview: CodexMCPToolCallResult?
    @Published var mcpToolCallStatusText = "未调用"
    @Published var runtimeConfig: CodexRuntimeConfig?
    @Published var externalAgentMigrationItems: [CodexExternalAgentMigrationItem] = []
    @Published var externalAgentMigrationStatusText = "未检测"
    @Published var externalAgentMigrationIsImporting = false
    @Published var externalAgentImportedItemCount = 0
    @Published var desktopShowInMenuBar = true
    @Published var desktopShowBottomPanel = true
    @Published var desktopPreventSleepWhileRunning = true
    @Published var desktopTerminalPosition = "底部"
    @Published var desktopAppearance = "跟随系统"
    @Published var desktopOpenTarget = "iTerm2"
    @Published var desktopLanguage = "自动检测"
    @Published var desktopCommitInstructions = ""
    @Published var desktopPullRequestInstructions = ""
    @Published var defaultPermissionsEnabled = true
    @Published var defaultFullAccessPermissionsEnabled = false
    @Published var runtimeAccount: CodexRuntimeAccount?
    @Published var activeAccountLogin: CodexAccountLogin?
    @Published var runtimeTokenUsage: CodexRuntimeTokenUsage?
    @Published var threadTokenUsageByThreadID: [String: CodexRuntimeThreadTokenUsage] = [:]
    @Published var selectedThreadTokenUsage: CodexRuntimeThreadTokenUsage?
    @Published var runtimeRateLimits: CodexRuntimeRateLimits?
    @Published var runtimeRequirements: CodexRuntimeConfigRequirements?
    @Published var runtimeRegisteredEnvironments: [RuntimeEnvironmentRegistration] = []
    @Published var selectedRuntimeEnvironmentID: String?
    @Published var runtimeEnvironmentIDDraft = "remote-a"
    @Published var runtimeEnvironmentURLDraft = "http://127.0.0.1:8080"
    @Published var runtimeEnvironmentCwdDraft = ""
    @Published var runtimeEnvironmentStatusText = "未注册"
    @Published var runtimeRemoteControlStatus: CodexRuntimeRemoteControlStatus?
    @Published var runtimeRemoteControlPairing: CodexRemoteControlPairing?
    @Published var runtimeRemoteControlPairingClaimed: Bool?
    @Published var runtimeRemoteControlClients: [CodexRemoteControlClient] = []
    @Published var runtimeRemoteControlClientsNextCursor: String?
    @Published var runtimeCollaborationModes: [CodexCollaborationModePreset] = []
    @Published var runtimeCollaborationModeStatusText = "未读取"
    @Published var selectedCollaborationModeKind = "default"
    @Published var runtimeRealtimeVoices: CodexRealtimeVoices?
    @Published var runtimeRealtimeVoicesUpdatedAt: Date?
    @Published var voiceInputStatusText = "麦克风"
    @Published var runtimeApps: [CodexRuntimeAppInfo] = []
    @Published var runtimeAppsStatusText = "未读取"
    @Published var runtimePermissionProfiles: [CodexRuntimePermissionProfile] = []
    @Published var lastOpenedRuntimeAppInstallURL = ""
    @Published var archivedRuntimeThreads: [CodexRuntimeThreadSummary] = []
    @Published var loadedRuntimeThreadIDs: [String] = []
    @Published var windowsSandboxReadiness: CodexWindowsSandboxReadiness?
    @Published var windowsSandboxReadinessStatusText = "未读取"
    @Published var windowsSandboxSetupStatusText = "未启动"
    @Published var runtimeLoadedThreadsStatusText = "未读取"
    @Published var runtimeThreadMetadataStatusText = "未同步"
    @Published var runtimeThreadSyncStatusText = "未同步"
    @Published var runtimeElicitationStatusText = "未挂起"
    @Published var runtimeThreadSearchSnippets: [String: String] = [:]
    @Published var workspaceGitDiff: CodexRuntimeGitDiff?
    @Published var workspaceGitStatusText = ""
    @Published var workspacePullRequestStatusText = "未刷新"
    @Published var workspaceWorktrees: [String] = []
    @Published var workspaceWorktreeStatusSource = ""
    @Published var workspaceBranches: [String] = []
    @Published var workspaceBranchStatusText = "未刷新"
    @Published var workspaceExecutionMode: WorkspaceExecutionMode = .local
    @Published var runtimeCatalogStatusText = "未刷新"
    @Published var runtimeCatalogErrors: [String] = []
    @Published var runtimeCatalogIsRefreshing = false
    @Published var recentGuardianDeniedActions: [GuardianDeniedAction] = []
    @Published var homeConnectionsRefreshedAt: Date?
    @Published var homeConnectionStatusText = "未刷新"
    @Published var lastMentionInputPreview: [[String: String]] = []
    @Published var pendingLocalImagePaths: [String] = []
    @Published var pendingPromptFileReferencePaths: [String] = []
    @Published var lastLocalImageInputPreview: [String] = []
    @Published var mcpElicitationDrafts: [UUID: String] = [:]
    @Published var toolUserInputDrafts: [UUID: [String: String]] = [:]
    @Published var toolUserInputSelections: [UUID: [String: String]] = [:]
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
    @Published var providerUsageByProviderID: [String: RaytoneProxyUsage] = [:]
    @Published var providerUsageStatusText = "未读取"
    @Published var providerOnboardingPresented = false
    @Published var providerOnboardingStatusText = "未开始"
    @Published var addCreditsNudgeStatusText = "未发送"
    @Published var feedbackUploadStatusText = "未发送"
    @Published var feedbackUploadThreadID = ""
    @Published var modelProviderCapabilities: CodexModelProviderCapabilities?
    @Published var modelProviderCapabilitiesStatusText = "未读取"
    @Published var runtimeSnapshot = CodexRuntimeSnapshot(executable: nil, version: nil)
    @Published var isRunning = false {
        didSet { updatePreventSleepAssertion() }
    }
    @Published var slashCommandStatusText = "未运行"
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
    private static let providerOnboardingCompletedKey = "RaytoneCodex.providerOnboardingCompleted.v1"
    static let inspectorPriorityFilePaths = [
        "Sources/RaytoneCodex/Views/ContentView.swift",
        "Sources/RaytoneCodex/Stores/SessionStore.swift",
        "docs/codex-screens-spec.md"
    ]

    private enum PendingApprovalResponseKind {
        case appServerDecision
        case permissions(requested: JSONValue)
        case legacyReviewDecision
    }

    private struct SlashShellCommandSelection {
        var command: String
        var source: String
    }

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
    private var activeFileChangePatchTranscriptIDs: [String: Set<UUID>] = [:]
    private var pendingApprovalRequestIDs: [UUID: CodexAppServerRequestID] = [:]
    private var pendingApprovalResponseKinds: [UUID: PendingApprovalResponseKind] = [:]
    private var pendingMcpElicitationRequestIDs: [UUID: CodexAppServerRequestID] = [:]
    private var pendingToolUserInputRequestIDs: [UUID: CodexAppServerRequestID] = [:]
    private var outOfBandElicitationThreadIDsByItemID: [UUID: String] = [:]
    private var activeAppServerTurnID: String?
    private var appServerConnectionState: ConnectionState?
    private var appServerEnvironmentKey: String?
    private var filePanelWatchID: String?
    private var filePanelWatchedPath: String?
    private var activeFileSearchSessionID: String?
    private var completedFileSearchSessionIDs: Set<String> = []
    private var ignoredFileSearchSessionIDs: Set<String> = []
    private var activeTerminalRunID: UUID?
    private var activeTerminalProcessID: String?
    private var activeProxySession: RaytoneProxySession?
    private var providerSelectionTask: Task<Void, Never>?
    private var providerModelSelectionTask: Task<Void, Never>?
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

    var sidecarProviders: [RaytoneProviderConfiguration] {
        providers.filter(\.usesSidecar)
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
        Self.workModeID(forCollaborationModeKind: selectedCollaborationModeKind)
    }

    var runtimeServiceTierLabel: String {
        Self.serviceTierLabel(for: runtimeConfig?.serviceTier)
    }

    func collaborationModePreset(
        forWorkModeID id: String,
        modes: [CodexCollaborationModePreset]? = nil
    ) -> CodexCollaborationModePreset {
        let modeKind = Self.collaborationModeKind(forWorkModeID: id)
        let availableModes = modes ?? runtimeCollaborationModes
        if let preset = availableModes.first(where: { $0.mode == modeKind }) {
            return preset
        }
        if let preset = availableModes.first(where: { $0.name.localizedCaseInsensitiveCompare(modeKind) == .orderedSame }) {
            return preset
        }
        return CodexCollaborationModePreset(
            name: modeKind == "plan" ? "Plan" : "Default",
            mode: modeKind,
            model: nil,
            reasoningEffort: modeKind == "plan" ? "medium" : nil
        )
    }

    func effectiveCollaborationModeModel(for preset: CodexCollaborationModePreset) -> String {
        if let presetModel = preset.model?.trimmingCharacters(in: .whitespacesAndNewlines),
           !presetModel.isEmpty {
            return presetModel
        }
        if selectedProvider.usesSidecar {
            return selectedProvider.model
        }
        let selectedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        return selectedModel.isEmpty ? selectedProvider.model : selectedModel
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

    static var startupScreenUsesNewThreadHero: Bool {
        switch startupScreenIdentifier {
        case "home", "start", "new-thread", "hero", "home-compact", "compact-composer", "bottom-panel-off", "access", "access-popover":
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
            desktopCommitInstructions = config.raytoneCommitInstructions ?? ""
            desktopPullRequestInstructions = config.raytonePullRequestInstructions ?? ""
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
        activeFileChangePatchTranscriptIDs.removeAll()
        pendingApprovalRequestIDs.removeAll()
        pendingApprovalResponseKinds.removeAll()
        pendingMcpElicitationRequestIDs.removeAll()
        pendingToolUserInputRequestIDs.removeAll()
        outOfBandElicitationThreadIDsByItemID.removeAll()
        runtimeElicitationStatusText = "未挂起"
        mcpElicitationDrafts.removeAll()
        toolUserInputDrafts.removeAll()
        toolUserInputSelections.removeAll()
        recentGuardianDeniedActions.removeAll()
        appServerItemIDs.removeAll()
        resetActiveTerminal()
        resetFilePanelWatch()
        await proxyService.stop()
        activeProxySession = nil
        providerSelectionTask?.cancel()
        providerSelectionTask = nil
    }

    func selectThread(_ thread: ChatThread) {
        selectedThreadID = thread.id
        syncSelectedThreadTokenUsage()
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
            Task { await resumeRuntimeThread(localThreadID: thread.id, loadTranscript: true) }
        }
    }

    func syncSelectedThreadTokenUsage() {
        guard let appServerThreadID = selectedThread.appServerThreadID else {
            selectedThreadTokenUsage = nil
            return
        }
        selectedThreadTokenUsage = threadTokenUsageByThreadID[appServerThreadID]
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

        if Self.isImmediateControlSlashCommand(trimmedPrompt) {
            prompt = ""
            if await handleSlashCommand(trimmedPrompt) {
                return
            }
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

    private static func isImmediateControlSlashCommand(_ trimmedPrompt: String) -> Bool {
        guard trimmedPrompt.hasPrefix("/") else {
            return false
        }
        let command = trimmedPrompt
            .split(maxSplits: 1, whereSeparator: \.isWhitespace)
            .first
            .map { String($0).lowercased() }
        return command == "/goal" || command == "/goal-status" || command == "/goal-clear"
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

    func injectSideChatContext(_ message: String? = nil) async {
        let source = message ?? sideChatDraft
        let trimmedMessage = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        if message == nil {
            sideChatDraft = ""
        }

        sideChatStatusText = "正在通过 thread/inject_items 注入上下文…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let threadID = try await ensureAppServerThread(client: client, options: appServerOptions())
            let injectedText = """
            [侧边上下文]
            \(trimmedMessage)
            """
            try await client.injectThreadItems(
                threadID: threadID,
                items: [
                    .object([
                        "type": .string("message"),
                        "role": .string("user"),
                        "content": .array([
                            .object([
                                "type": .string("input_text"),
                                "text": .string(injectedText)
                            ])
                        ])
                    ])
                ]
            )
            sideChatStatusText = "thread/inject_items：已注入上下文"
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .info,
                    text: "已通过 thread/inject_items 注入侧边上下文，不会启动新回复。"
                ))))
                thread.updatedAt = Date()
            }
        } catch {
            sideChatStatusText = "thread/inject_items 失败：\(error.localizedDescription)"
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: sideChatStatusText
                ))))
            }
        }
    }

    private func runAgentPrompt(
        _ runtimePrompt: String,
        displayedPrompt: String? = nil,
        localImagePaths: [String] = []
    ) async {
        isRunning = true
        defer { clearPendingFileReferenceMentions(in: runtimePrompt) }
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
            let selection = arguments.isEmpty
                ? await detectedTestCommand()
                : SlashShellCommandSelection(command: arguments, source: "手动 /test + command/exec")
            await runSlashShellCommand(
                displayedPrompt: trimmedPrompt,
                command: selection.command,
                sandbox: sandbox == .readOnly ? .workspaceWrite : sandbox,
                appendDiffFileChanges: false,
                source: selection.source
            )
            return true

        case "/review":
            await runReviewOfCurrentChanges(displayedPrompt: trimmedPrompt, instructions: arguments.isEmpty ? nil : arguments)
            return true

        case "/commit", "/commit-message":
            await runCommitMessageGeneration(displayedPrompt: trimmedPrompt, instructions: arguments.isEmpty ? nil : arguments)
            return true

        case "/pr", "/pull-request":
            await runPullRequestSummaryGeneration(displayedPrompt: trimmedPrompt, instructions: arguments.isEmpty ? nil : arguments)
            return true

        case "/goal":
            guard !arguments.isEmpty else {
                appendSlashNotice(displayedPrompt: trimmedPrompt, text: "请在 /goal 后添加目标内容。")
                return true
            }
            appendSlashNotice(displayedPrompt: trimmedPrompt, text: "正在通过 thread/goal/set 设置目标…")
            await setActiveGoal(objective: arguments)
            return true

        case "/goal-status":
            appendSlashNotice(displayedPrompt: trimmedPrompt, text: "正在通过 thread/goal/get 读取目标…")
            let goal = await refreshSelectedRuntimeGoal()
            if let goal {
                appendSlashNotice(
                    displayedPrompt: "/goal-status",
                    text: "当前目标：\(goal.objective) · \(goal.status.rawValue)"
                )
            } else {
                appendSlashNotice(displayedPrompt: "/goal-status", text: "当前对话没有活动目标。")
            }
            return true

        case "/goal-clear":
            appendSlashNotice(displayedPrompt: trimmedPrompt, text: "正在通过 thread/goal/clear 清除目标…")
            await clearActiveGoal()
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
        appendDiffFileChanges: Bool,
        source: String = "command/exec"
    ) async {
        isRunning = true
        slashCommandStatusText = "\(source)：\(command)"
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
            slashCommandStatusText = "\(source)：\(command) · exit \(result.exitCode)"

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
            slashCommandStatusText = "\(source) 失败：\(error.localizedDescription)"
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

    private func detectedTestCommand() async -> SlashShellCommandSelection {
        let workspaceURL = URL(fileURLWithPath: workspacePath)
        let fallback = "test -x ./test.sh && ./test.sh || (echo '未找到可自动识别的测试命令；请用 /test <命令> 指定。' >&2; exit 2)"
        let source = "fs/getMetadata + command/exec"

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            if await appServerFileExists("script/test.sh", in: workspaceURL, using: client) {
                return SlashShellCommandSelection(command: "bash script/test.sh", source: source)
            }

            if await appServerFileExists("Package.swift", in: workspaceURL, using: client) {
                return SlashShellCommandSelection(command: "swift test", source: source)
            }

            if await appServerFileExists("package.json", in: workspaceURL, using: client) {
                return SlashShellCommandSelection(command: "npm test", source: source)
            }

            let hasPyproject = await appServerFileExists("pyproject.toml", in: workspaceURL, using: client)
            let hasPytestIni = await appServerFileExists("pytest.ini", in: workspaceURL, using: client)
            if hasPyproject || hasPytestIni {
                return SlashShellCommandSelection(command: "python -m pytest", source: source)
            }

            return SlashShellCommandSelection(command: fallback, source: source)
        } catch {
            return SlashShellCommandSelection(command: fallback, source: "fs/getMetadata 失败 + command/exec")
        }
    }

    private func appServerFileExists(
        _ relativePath: String,
        in workspaceURL: URL,
        using client: CodexAppServerClient
    ) async -> Bool {
        let targetURL = workspaceURL.appendingPathComponent(relativePath)
        do {
            return try await client.getMetadata(path: targetURL.path).isFile
        } catch {
            return false
        }
    }

    private static func reviewFallbackPrompt(instructions: String?) -> String {
        let trimmedInstructions = instructions?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let suffix = trimmedInstructions.isEmpty ? "" : "\n\n补充要求：\(trimmedInstructions)"
        return "请审查当前工作区变更，重点找 bug、行为回归、风险和缺失测试。先读取 git status 和 git diff，再按严重程度给出结论。\(suffix)"
    }

    private func runCommitMessageGeneration(displayedPrompt: String, instructions: String?) async {
        guard !isRunning else { return }
        await refreshWorkspaceGitDiff()
        let runtimePrompt = Self.commitMessagePrompt(
            gitStatus: workspaceGitStatusText,
            diff: workspaceGitDiff?.diff ?? "",
            savedInstructions: desktopCommitInstructions,
            oneOffInstructions: instructions
        )
        slashCommandStatusText = "command/exec git + turn/start：生成提交信息"
        await runAgentPrompt(runtimePrompt, displayedPrompt: displayedPrompt)
    }

    private func runPullRequestSummaryGeneration(displayedPrompt: String, instructions: String?) async {
        guard !isRunning else { return }
        await refreshWorkspaceGitDiff()
        await refreshWorkspacePullRequestStatus()
        let runtimePrompt = Self.pullRequestPrompt(
            gitStatus: workspaceGitStatusText,
            diff: workspaceGitDiff?.diff ?? "",
            pullRequestStatus: workspacePullRequestStatusText,
            savedInstructions: desktopPullRequestInstructions,
            oneOffInstructions: instructions
        )
        slashCommandStatusText = "command/exec git + turn/start：生成 PR 标题和描述"
        await runAgentPrompt(runtimePrompt, displayedPrompt: displayedPrompt)
    }

    private static func commitMessagePrompt(
        gitStatus: String,
        diff: String,
        savedInstructions: String,
        oneOffInstructions: String?
    ) -> String {
        let instructionBlock = combinedInstructionBlock(
            title: "提交指令",
            savedInstructions: savedInstructions,
            oneOffInstructions: oneOffInstructions
        )
        return """
        请基于当前工作区未提交变更生成一条高质量 git commit message。

        输出要求：
        - 第一行是简洁英文 commit subject，不超过 72 个字符。
        - 如有必要，空一行后用 2-5 条中文要点解释主要改动和验证。
        - 不要执行 git commit，不要修改文件。
        \(instructionBlock)

        以下 Git 状态和 diff 已由 RaytoneCodex 通过 Codex app-server 的 command/exec 读取：

        ```text
        \(boundedGitText(gitStatus, fallback: "未返回 git status。"))
        ```

        ```diff
        \(boundedGitText(diff, fallback: "当前没有未提交 diff。"))
        ```
        """
    }

    private static func pullRequestPrompt(
        gitStatus: String,
        diff: String,
        pullRequestStatus: String,
        savedInstructions: String,
        oneOffInstructions: String?
    ) -> String {
        let instructionBlock = combinedInstructionBlock(
            title: "拉取请求指令",
            savedInstructions: savedInstructions,
            oneOffInstructions: oneOffInstructions
        )
        return """
        请基于当前工作区变更生成拉取请求标题和描述草稿。

        输出要求：
        - 先给一行 PR 标题。
        - 然后给“摘要”“验证”“风险”三段。
        - 不要创建 PR，不要推送分支，不要修改文件。
        \(instructionBlock)

        当前 PR 状态：\(pullRequestStatus)

        以下 Git 状态和 diff 已由 RaytoneCodex 通过 Codex app-server 的 command/exec 读取：

        ```text
        \(boundedGitText(gitStatus, fallback: "未返回 git status。"))
        ```

        ```diff
        \(boundedGitText(diff, fallback: "当前没有未提交 diff。"))
        ```
        """
    }

    private static func combinedInstructionBlock(
        title: String,
        savedInstructions: String,
        oneOffInstructions: String?
    ) -> String {
        let saved = savedInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        let oneOff = oneOffInstructions?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var lines: [String] = []
        if !saved.isEmpty {
            lines.append("\(title)：\(saved)")
        }
        if !oneOff.isEmpty {
            lines.append("本次补充要求：\(oneOff)")
        }
        guard !lines.isEmpty else { return "" }
        return "\n" + lines.joined(separator: "\n")
    }

    private static func boundedGitText(_ text: String, fallback: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        let maxCount = 20_000
        guard trimmed.count > maxCount else { return trimmed }
        let prefix = String(trimmed.prefix(maxCount))
        return "\(prefix)\n\n[已截断：仅保留前 \(maxCount) 字符]"
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
        defer { clearPendingFileReferenceMentions(in: trimmedPrompt) }
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
            let mentions = await inputMentions(in: trimmedPrompt)
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
            runtimeCatalogStatusText = "turn/interrupt：已发送"
        } catch {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "无法停止当前轮次：\(error.localizedDescription)"
                ))))
            }
        }
    }

    func startSelectedThreadCompaction() async {
        guard !isRunning else {
            runtimeThreadSyncStatusText = "当前有运行中的轮次，暂不能压缩"
            return
        }

        runtimeCatalogIsRefreshing = true
        runtimeThreadSyncStatusText = "正在调用 thread/compact/start…"
        runtimeCatalogStatusText = runtimeThreadSyncStatusText
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let threadID = try await ensureAppServerThread(client: client, options: appServerOptions())
            try await retryAfterActiveTurnSettles {
                try await client.startThreadCompaction(threadID: threadID)
            }
            runtimeThreadSyncStatusText = "thread/compact/start：已提交"
            runtimeCatalogStatusText = runtimeThreadSyncStatusText
        } catch {
            runtimeThreadSyncStatusText = "thread/compact/start 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimeThreadSyncStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "压缩历史失败：\(error.localizedDescription)"
                ))))
            }
        }

        runtimeCatalogIsRefreshing = false
    }

    func rollbackSelectedThreadLastTurn(confirm: Bool = true) async {
        guard !isRunning else {
            runtimeThreadSyncStatusText = "当前有运行中的轮次，暂不能回滚"
            return
        }
        guard !confirm || confirmThreadRollback() else {
            runtimeThreadSyncStatusText = "thread/rollback：已取消"
            return
        }

        let localThreadID = selectedThreadID
        runtimeCatalogIsRefreshing = true
        runtimeThreadSyncStatusText = "正在调用 thread/rollback…"
        runtimeCatalogStatusText = runtimeThreadSyncStatusText
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let threadID = try await ensureAppServerThread(client: client, options: appServerOptions())
            let result = try await retryAfterActiveTurnSettles {
                try await client.rollbackThread(id: threadID, numTurns: 1)
            }
            applyRuntimeThreadRead(result, to: localThreadID)
            runtimeThreadSyncStatusText = "thread/rollback：已回滚最后 1 轮"
            runtimeCatalogStatusText = runtimeThreadSyncStatusText
        } catch {
            runtimeThreadSyncStatusText = "thread/rollback 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimeThreadSyncStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "回滚最后一轮失败：\(error.localizedDescription)"
                ))))
            }
        }

        runtimeCatalogIsRefreshing = false
    }

    private func confirmThreadRollback() -> Bool {
        let alert = NSAlert()
        alert.messageText = "回滚最后一轮？"
        alert.informativeText = "这会通过 Codex app-server 调用 thread/rollback，只回滚对话历史，不会还原本地文件改动。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "回滚")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func retryAfterActiveTurnSettles<T>(
        attempts: Int = 8,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        for attempt in 0..<attempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                guard attempt + 1 < attempts, Self.isActiveTurnSettlingError(error) else {
                    throw error
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        throw lastError ?? CodexAppServerError.invalidResponse("Operation did not complete.")
    }

    private static func isActiveTurnSettlingError(_ error: Error) -> Bool {
        let text = error.localizedDescription.lowercased()
        return text.contains("turn is in progress") ||
            text.contains("active turn") ||
            text.contains("while a turn is in progress")
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
            updateSelectedThread { thread in
                guard var goal = thread.activeGoal else { return }
                goal.status = .paused
                goal.timeUsedSeconds = max(goal.timeUsedSeconds, Int(Date().timeIntervalSince(goal.startedAt)))
                thread.activeGoal = goal
                thread.updatedAt = Date()
            }
            runtimeCatalogStatusText = "本地目标已暂停"
        }
    }

    func resumeActiveGoal() async {
        guard selectedThread.activeGoal != nil else { return }

        if selectedThread.activeGoal?.runtimeBacked == true,
           let client = appServerClient,
           let threadID = selectedThread.appServerThreadID {
            do {
                let goal = try await client.setThreadGoal(threadID: threadID, status: .active)
                applyRuntimeGoal(goal)
                runtimeCatalogStatusText = "thread/goal/set：active"
            } catch {
                updateSelectedThread { thread in
                    thread.items.append(TranscriptItem(kind: .notice(Notice(
                        level: .warning,
                        text: "无法继续目标：\(error.localizedDescription)"
                    ))))
                }
            }
            return
        }

        updateSelectedThread { thread in
            guard var goal = thread.activeGoal else { return }
            goal.status = .active
            goal.startedAt = Date().addingTimeInterval(TimeInterval(-goal.timeUsedSeconds))
            thread.activeGoal = goal
            thread.updatedAt = Date()
        }
        runtimeCatalogStatusText = "本地目标已继续"
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
        clearRunningStateIfNoActiveTurn()
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
            clearRunningStateIfNoActiveTurn()
            return goal
        } catch {
            runtimeCatalogStatusText = "目标读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            clearRunningStateIfNoActiveTurn()
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
                    status: current.status,
                    tokenBudget: current.tokenBudget,
                    tokensUsed: current.tokensUsed,
                    timeUsedSeconds: current.timeUsedSeconds,
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
                thread.activeGoal = ActiveGoal(
                    title: trimmedObjective,
                    startedAt: current.startedAt,
                    status: current.status,
                    tokenBudget: current.tokenBudget,
                    tokensUsed: current.tokensUsed,
                    timeUsedSeconds: current.timeUsedSeconds,
                    runtimeBacked: false
                )
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
        clearRunningStateIfNoActiveTurn()
    }

    func clearActiveGoal() async {
        guard selectedThread.activeGoal?.runtimeBacked == true else {
            clearSelectedThreadActiveGoal()
            clearRunningStateIfNoActiveTurn()
            return
        }

        guard let client = appServerClient,
              let threadID = selectedThread.appServerThreadID else {
            clearSelectedThreadActiveGoal()
            clearRunningStateIfNoActiveTurn()
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
        clearRunningStateIfNoActiveTurn()
    }

    private func clearRunningStateIfNoActiveTurn() {
        if activeAppServerTurnID == nil {
            isRunning = false
        }
    }

    func respondToAppServerApproval(itemID: UUID, decision: ApprovalRequest.Decision) async {
        guard let requestID = pendingApprovalRequestIDs.removeValue(forKey: itemID),
              let client = appServerClient else {
            return
        }
        defer { endOutOfBandElicitation(itemID: itemID) }
        let responseKind = pendingApprovalResponseKinds.removeValue(forKey: itemID) ?? .appServerDecision

        do {
            switch responseKind {
            case .appServerDecision:
                guard let appServerDecision = Self.appServerApprovalDecision(from: decision) else { return }
                try await client.respondApproval(requestID: requestID, decision: appServerDecision)
            case let .permissions(requested):
                let permissions: JSONValue
                let scope: String
                switch decision {
                case .pending:
                    return
                case .approved:
                    permissions = requested
                    scope = "turn"
                case .approvedAlways:
                    permissions = requested
                    scope = "session"
                case .denied:
                    permissions = .object([:])
                    scope = "turn"
                }
                try await client.respondPermissionsApproval(
                    requestID: requestID,
                    permissions: permissions,
                    scope: scope,
                    strictAutoReview: false
                )
            case .legacyReviewDecision:
                guard let legacyDecision = Self.legacyReviewDecision(from: decision) else { return }
                try await client.respondLegacyApproval(requestID: requestID, decision: legacyDecision)
            }
        } catch {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "审批结果未能回传给 app-server：\(error.localizedDescription)"
                ))))
            }
        }
    }

    func respondToAppServerMcpElicitation(
        itemID: UUID,
        action: McpElicitationRequest.Action,
        content: JSONValue?
    ) async {
        guard let requestID = pendingMcpElicitationRequestIDs.removeValue(forKey: itemID),
              let client = appServerClient else {
            return
        }
        defer { endOutOfBandElicitation(itemID: itemID) }

        let appServerAction: CodexAppServerElicitationAction
        switch action {
        case .accept:
            appServerAction = .accept
        case .decline:
            appServerAction = .decline
        case .cancel:
            appServerAction = .cancel
        }

        do {
            try await client.respondMcpElicitation(
                requestID: requestID,
                action: appServerAction,
                content: content
            )
        } catch {
            updateMcpElicitationStatus(itemID: itemID, status: .failed(error.localizedDescription))
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "MCP 输入结果未能回传给 app-server：\(error.localizedDescription)"
                ))))
            }
        }
    }

    func updateMcpElicitationDraft(itemID: UUID, draft: String) {
        mcpElicitationDrafts[itemID] = draft
    }

    func decideMcpElicitation(itemID: UUID, action: McpElicitationRequest.Action) {
        guard let threadIndex = threads.firstIndex(where: { $0.id == selectedThreadID }),
              let itemIndex = threads[threadIndex].items.firstIndex(where: { $0.id == itemID }),
              case var .mcpElicitation(request) = threads[threadIndex].items[itemIndex].kind else {
            return
        }

        var content: JSONValue?
        if action == .accept, request.mode == .form {
            let draft = (mcpElicitationDrafts[itemID] ?? "{}")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            do {
                content = try JSONValue(jsonString: draft.isEmpty ? "{}" : draft)
            } catch {
                threads[threadIndex].items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "MCP 表单内容不是有效 JSON，尚未提交：\(error.localizedDescription)"
                ))))
                threads[threadIndex].updatedAt = Date()
                return
            }
        }

        switch action {
        case .accept:
            request.status = .accepted
        case .decline:
            request.status = .declined
        case .cancel:
            request.status = .cancelled
        }
        threads[threadIndex].items[itemIndex].kind = .mcpElicitation(request)
        threads[threadIndex].updatedAt = Date()

        Task {
            await respondToAppServerMcpElicitation(
                itemID: itemID,
                action: action,
                content: content
            )
        }
    }

    func selectToolUserInputOption(itemID: UUID, questionID: String, label: String) {
        var selections = toolUserInputSelections[itemID] ?? [:]
        selections[questionID] = label
        toolUserInputSelections[itemID] = selections
    }

    func updateToolUserInputDraft(itemID: UUID, questionID: String, draft: String) {
        var drafts = toolUserInputDrafts[itemID] ?? [:]
        drafts[questionID] = draft
        toolUserInputDrafts[itemID] = drafts
    }

    func submitToolUserInput(itemID: UUID) {
        guard let request = toolUserInputRequest(itemID: itemID) else {
            return
        }
        let answers = toolUserInputAnswers(for: request)
        setToolUserInputStatus(itemID: itemID, status: .submitted)
        Task {
            await respondToAppServerToolUserInput(itemID: itemID, answers: answers, statusOnSuccess: .submitted)
        }
    }

    func skipToolUserInput(itemID: UUID) {
        guard let request = toolUserInputRequest(itemID: itemID) else {
            return
        }
        let answers = Dictionary(uniqueKeysWithValues: request.questions.map { ($0.id, [String]()) })
        setToolUserInputStatus(itemID: itemID, status: .skipped)
        Task {
            await respondToAppServerToolUserInput(itemID: itemID, answers: answers, statusOnSuccess: .skipped)
        }
    }

    func respondToAppServerToolUserInput(
        itemID: UUID,
        answers: [String: [String]],
        statusOnSuccess: ToolUserInputRequest.Status
    ) async {
        guard let requestID = pendingToolUserInputRequestIDs.removeValue(forKey: itemID),
              let client = appServerClient else {
            return
        }
        defer { endOutOfBandElicitation(itemID: itemID) }

        do {
            try await client.respondToolUserInput(requestID: requestID, answers: answers)
            setToolUserInputStatus(itemID: itemID, status: statusOnSuccess)
        } catch {
            setToolUserInputStatus(itemID: itemID, status: .failed(error.localizedDescription))
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: "工具输入结果未能回传给 app-server：\(error.localizedDescription)"
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
        let normalizedPath = Self.canonicalPath(path)
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

    @discardableResult
    func openWorkspaceWorktree(_ path: String, revealFiles: Bool = false) async -> Bool {
        let normalizedPath = Self.canonicalPath(path)
        runtimeCatalogStatusText = "正在验证工作树：\(Project.abbreviate(normalizedPath))"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let metadata = try await client.getMetadata(path: normalizedPath)
            workspaceWorktreeStatusSource = "fs/getMetadata + worktreeSwitch"
            guard metadata.isDirectory else {
                runtimeCatalogStatusText = "工作树不是目录：\(Project.abbreviate(normalizedPath))"
                return false
            }
        } catch {
            guard !Self.isCancellation(error) else {
                runtimeCatalogStatusText = "工作树切换已取消"
                return false
            }
            runtimeCatalogStatusText = "工作树验证失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            return false
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogErrors = []
        runtimeCatalogStatusText = "正在切换工作树：\(Project.abbreviate(normalizedPath))"
        workspacePath = normalizedPath
        filePanelPath = normalizedPath
        updateSelectedProject(path: normalizedPath)

        if revealFiles {
            route = .thread
            openToolPanel(.files)
        }

        await refreshWorkspaceBranches()
        await loadFilePanelDirectory(normalizedPath)
        await refreshWorkspaceGitDiff()
        await refreshWorkspaceWorktrees()

        workspaceWorktreeStatusSource = "fs/getMetadata + worktreeSwitch + command/exec git worktree list"
        runtimeCatalogStatusText = "已切换工作树：\(Project.abbreviate(normalizedPath))"
        runtimeCatalogIsRefreshing = false
        return true
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

        let selectedApproval = approval
        let selectedSandbox = sandbox
        let selectedApprovalsReviewer = approvalsReviewer
        Task { @MainActor [weak self] in
            await self?.syncSelectedThreadExecutionSettings(
                approvalPolicy: selectedApproval,
                approvalsReviewer: selectedApprovalsReviewer,
                sandbox: selectedSandbox,
                statusName: mode.shortTitle
            )
        }
    }

    private func syncSelectedThreadExecutionSettings(
        model: String? = nil,
        approvalPolicy: CodexApprovalPolicy? = nil,
        approvalsReviewer: CodexApprovalsReviewer? = nil,
        sandbox: CodexSandboxMode? = nil,
        statusName: String
    ) async {
        guard model != nil || approvalPolicy != nil || approvalsReviewer != nil || sandbox != nil,
              let threadID = selectedThread.appServerThreadID,
              let client = appServerClient else {
            return
        }

        do {
            try await client.updateThreadExecutionSettings(
                threadID: threadID,
                model: model,
                approvalPolicy: approvalPolicy,
                approvalsReviewer: approvalsReviewer,
                sandbox: sandbox
            )
            runtimeCatalogStatusText = "thread/settings/update：\(statusName)"
        } catch {
            runtimeCatalogStatusText = "thread/settings/update 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
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

        await syncSelectedThreadExecutionSettings(
            approvalPolicy: policy,
            statusName: "批准策略 \(Self.approvalName(policy))"
        )

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

        await syncSelectedThreadExecutionSettings(
            sandbox: mode,
            statusName: "沙箱 \(Self.sandboxName(mode))"
        )

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

        await syncSelectedThreadExecutionSettings(
            approvalsReviewer: reviewer,
            statusName: "审批路由 \(Self.approvalsReviewerName(reviewer))"
        )

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
        let modeKind = Self.collaborationModeKind(forWorkModeID: id)
        selectedCollaborationModeKind = modeKind
        runtimeCatalogStatusText = "正在读取 collaborationMode/list…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let modes = try await client.listCollaborationModes()
            runtimeCollaborationModes = modes
            runtimeCollaborationModeStatusText = "collaborationMode/list：\(modes.count) 个 preset"
            let preset = collaborationModePreset(forWorkModeID: id, modes: modes)
            let effectiveModel = effectiveCollaborationModeModel(for: preset)

            try await client.writeConfigValue(
                keyPath: "model_verbosity",
                value: .string(verbosity)
            )
            let threadID = try await ensureAppServerThread(client: client, options: appServerOptions())
            try await client.updateThreadCollaborationMode(
                threadID: threadID,
                preset: preset,
                effectiveModel: effectiveModel
            )
            applyRuntimeConfig(try await client.readConfig(cwd: workspacePath, includeLayers: true))
            runtimeCatalogStatusText = "collaborationMode/list + thread/settings/update：\(preset.name)"
        } catch {
            runtimeCatalogStatusText = "工作模式更新失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func refreshRuntimeCollaborationModes() async {
        runtimeCollaborationModeStatusText = "正在读取 collaborationMode/list…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let modes = try await client.listCollaborationModes()
            runtimeCollaborationModes = modes
            runtimeCollaborationModeStatusText = "collaborationMode/list：\(modes.count) 个 preset"
            runtimeCatalogStatusText = runtimeCollaborationModeStatusText
        } catch {
            runtimeCollaborationModeStatusText = "collaborationMode/list 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimeCollaborationModeStatusText
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

    func saveSelectedThreadMemoryMode(_ mode: CodexThreadMemoryMode) async {
        runtimeCatalogStatusText = "正在调用 thread/memoryMode/set…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let threadID = try await ensureAppServerThread(client: client, options: appServerOptions())
            try await client.setThreadMemoryMode(threadID: threadID, mode: mode)
            updateSelectedThread { thread in
                thread.memoryMode = mode
            }
            runtimeCatalogStatusText = "thread/memoryMode/set：当前对话记忆已\(mode.displayName)"
        } catch {
            runtimeCatalogStatusText = "当前对话记忆写入失败：\(error.localizedDescription)"
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
        _ = await startRealtimeTextSessionForVoiceInput()

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

    @discardableResult
    func startRealtimeTextSessionForVoiceInput(
        prompt: String = "RaytoneCodex macOS 麦克风输入，请把随后追加的文本作为用户语音转写。"
    ) async -> Bool {
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let threadID = try await ensureAppServerThread(client: client, options: appServerOptions())
            try await client.startRealtime(
                threadID: threadID,
                outputModality: "text",
                prompt: prompt,
                voice: runtimeRealtimeVoices?.defaultV2.isEmpty == false ? runtimeRealtimeVoices?.defaultV2 : nil
            )
            voiceInputStatusText = "thread/realtime/start：文本会话已启动"
            runtimeCatalogStatusText = voiceInputStatusText
            return true
        } catch {
            voiceInputStatusText = "thread/realtime/start 失败，继续系统听写：\(error.localizedDescription)"
            runtimeCatalogStatusText = voiceInputStatusText
            return false
        }
    }

    func appendRealtimeTextForVoiceInput(_ text: String) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard let client = appServerClient,
              let threadID = selectedThread.appServerThreadID else {
            voiceInputStatusText = "thread/realtime/appendText：没有活动 realtime 线程"
            return false
        }

        do {
            try await client.appendRealtimeText(threadID: threadID, text: trimmed)
            voiceInputStatusText = "thread/realtime/appendText：已追加文本"
            runtimeCatalogStatusText = voiceInputStatusText
            return true
        } catch {
            voiceInputStatusText = "thread/realtime/appendText 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = voiceInputStatusText
            return false
        }
    }

    @discardableResult
    func appendRealtimeAudioForVoiceInput(
        _ data: Data,
        sampleRate: Int = 24_000,
        numChannels: Int = 1,
        samplesPerChannel: Int? = nil,
        itemID: String = "raytone-audio-\(UUID().uuidString)"
    ) async -> Bool {
        guard !data.isEmpty else { return false }
        guard let client = appServerClient,
              let threadID = selectedThread.appServerThreadID else {
            voiceInputStatusText = "thread/realtime/appendAudio：没有活动 realtime 线程"
            return false
        }

        let safeChannels = max(1, numChannels)
        let inferredSamples = max(1, data.count / max(safeChannels * 2, 1))
        let sampleCount = max(1, samplesPerChannel ?? inferredSamples)
        let chunk = CodexRealtimeAudioChunk(
            data: data.base64EncodedString(),
            sampleRate: max(1, sampleRate),
            numChannels: safeChannels,
            samplesPerChannel: sampleCount,
            itemID: itemID
        )

        do {
            try await client.appendRealtimeAudio(threadID: threadID, audio: chunk)
            voiceInputStatusText = "thread/realtime/appendAudio：已追加音频 \(sampleCount) samples/channel"
            runtimeCatalogStatusText = voiceInputStatusText
            return true
        } catch {
            voiceInputStatusText = "thread/realtime/appendAudio 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = voiceInputStatusText
            return false
        }
    }

    @discardableResult
    func appendRealtimeSilenceForVoiceInput(
        sampleRate: Int = 24_000,
        samplesPerChannel: Int = 2
    ) async -> Bool {
        let sampleCount = max(1, samplesPerChannel)
        let pcm16Silence = Data(repeating: 0, count: sampleCount * 2)
        return await appendRealtimeAudioForVoiceInput(
            pcm16Silence,
            sampleRate: sampleRate,
            numChannels: 1,
            samplesPerChannel: sampleCount,
            itemID: "raytone-silence-\(UUID().uuidString)"
        )
    }

    func stopRealtimeVoiceInput() async -> Bool {
        guard let client = appServerClient,
              let threadID = selectedThread.appServerThreadID else {
            voiceInputStatusText = "thread/realtime/stop：没有活动 realtime 线程"
            return false
        }

        do {
            try await client.stopRealtime(threadID: threadID)
            voiceInputStatusText = "thread/realtime/stop：已停止"
            runtimeCatalogStatusText = voiceInputStatusText
            return true
        } catch {
            voiceInputStatusText = "thread/realtime/stop 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = voiceInputStatusText
            return false
        }
    }

    func refreshRealtimeVoicesForVoiceInput() async {
        voiceInputStatusText = "正在读取 Codex realtime voices…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let voices = try await client.listRealtimeVoices()
            runtimeRealtimeVoices = voices
            runtimeRealtimeVoicesUpdatedAt = Date()
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
        let normalizedPaths = await verifiedPromptAttachmentPaths(
            paths
                .map { URL(fileURLWithPath: $0).standardizedFileURL.path }
                .filter { !$0.isEmpty },
            label: label
        )
        queuePendingFileReferenceMentions(paths: normalizedPaths)
        await appendVerifiedFileReferencesToPrompt(paths: normalizedPaths, label: label)
    }

    func addPreviewedFileReferenceToPrompt() async {
        guard let preview = filePreview else {
            filePanelStatusText = "没有可引用的文件"
            return
        }

        await addFileReferencesToPrompt(paths: [preview.path])
        filePanelStatusText = "已加入下次对话：\(Project.abbreviate(preview.path))"
    }

    func addImageReferencesToPrompt(paths: [String]) async {
        let normalizedPaths = await verifiedPromptAttachmentPaths(
            paths
                .map { URL(fileURLWithPath: $0).standardizedFileURL.path }
                .filter { !$0.isEmpty },
            label: "图片"
        )
        guard !normalizedPaths.isEmpty else { return }

        var seenPaths = Set(pendingLocalImagePaths)
        for path in normalizedPaths where !seenPaths.contains(path) {
            pendingLocalImagePaths.append(path)
            seenPaths.insert(path)
        }

        await appendVerifiedFileReferencesToPrompt(paths: normalizedPaths, label: "图片")
    }

    private func appendVerifiedFileReferencesToPrompt(paths normalizedPaths: [String], label: String) async {
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

    private func verifiedPromptAttachmentPaths(_ paths: [String], label: String) async -> [String] {
        guard !paths.isEmpty else { return [] }

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            var verified: [String] = []
            var rejected: [String] = []
            for path in paths {
                do {
                    let metadata = try await client.getMetadata(path: path)
                    if metadata.isFile {
                        verified.append(path)
                    } else {
                        rejected.append(path)
                    }
                } catch {
                    rejected.append(path)
                }
            }

            let rejectedSuffix = rejected.isEmpty ? "" : " · 跳过 \(rejected.count) 项"
            filePanelStatusText = "fs/getMetadata：已确认 \(verified.count) 个\(label)\(rejectedSuffix)"
            filePanelLastOperationSource = "fs/getMetadata"
            return verified
        } catch {
            filePanelStatusText = "fs/getMetadata 校验\(label)失败：\(error.localizedDescription)"
            return []
        }
    }

    private func consumePendingLocalImages() -> [String] {
        let images = pendingLocalImagePaths
        pendingLocalImagePaths = []
        lastLocalImageInputPreview = images
        return images
    }

    private func queuePendingFileReferenceMentions(paths: [String]) {
        guard !paths.isEmpty else { return }

        var seen = Set(pendingPromptFileReferencePaths)
        for path in paths where !path.isEmpty && seen.insert(path).inserted {
            pendingPromptFileReferencePaths.append(path)
        }
    }

    private func pendingFileReferenceMentions(in prompt: String) -> [CodexAppServerMention] {
        pendingPromptFileReferencePaths.compactMap { path in
            guard promptContainsFileReference(path, in: prompt) else { return nil }
            let name = URL(fileURLWithPath: path).lastPathComponent
            return CodexAppServerMention(name: name.isEmpty ? path : name, path: path)
        }
    }

    private func clearPendingFileReferenceMentions(in prompt: String) {
        pendingPromptFileReferencePaths.removeAll { promptContainsFileReference($0, in: prompt) }
    }

    private func promptContainsFileReference(_ path: String, in prompt: String) -> Bool {
        guard !path.isEmpty else { return false }
        let reference = Self.promptReferencePath(for: path, workspacePath: workspacePath)
        let candidates = [path, reference].filter { !$0.isEmpty }
        return candidates.contains { candidate in
            prompt.contains("`\(candidate)`") || prompt.contains(candidate)
        }
    }

    func openRecommendedFile(_ path: String) {
        Task { await openFilePathInPanel(Self.absoluteWorkspacePath(path, workspacePath: workspacePath)) }
    }

    func openFilePathInPanel(_ path: String) async {
        let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        showInspector = true
        toolPanel = .files
        filePanelStatusText = "正在检查路径…"
        filePanelLastOperationSource = "fs/getMetadata"

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let metadata = try await client.getMetadata(path: normalizedPath)

            if metadata.isDirectory {
                await loadFilePanelDirectory(normalizedPath)
                return
            }

            guard metadata.isFile else {
                filePanelStatusText = "无法预览：\(Project.abbreviate(normalizedPath))"
                return
            }

            let parent = URL(fileURLWithPath: normalizedPath).deletingLastPathComponent().path
            await loadFilePanelDirectory(parent)
            let entry = fileEntries.first { $0.path == normalizedPath } ?? WorkspaceFileEntry(
                name: URL(fileURLWithPath: normalizedPath).lastPathComponent,
                path: normalizedPath,
                isDirectory: metadata.isDirectory,
                isFile: metadata.isFile
            )
            await openFileEntry(entry)
            if filePreview?.path == normalizedPath {
                filePanelLastOperationSource = "openFilePathInPanel + fs/getMetadata + fs/readFile"
            }
        } catch {
            guard !Self.isCancellation(error) else {
                filePanelStatusText = "打开已取消"
                return
            }
            filePanelStatusText = "打开失败：\(error.localizedDescription)"
        }
    }

    func loadFilePanelDirectory(_ path: String? = nil, updateWatch: Bool = true) async {
        let targetPath = path ?? (filePanelPath.isEmpty ? workspacePath : filePanelPath)
        filePanelStatusText = "正在读取…"
        filePreview = nil

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let entries = try await client.readDirectory(path: targetPath)
            filePanelLastOperationSource = "fs/readDirectory"
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

    func refreshInspectorRecommendedFiles() async {
        let workspaceURL = URL(fileURLWithPath: workspacePath)
        var recommended: [String] = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            for relativePath in Self.inspectorPriorityFilePaths {
                let path = workspaceURL.appendingPathComponent(relativePath).standardizedFileURL.path
                do {
                    let metadata = try await client.getMetadata(path: path)
                    if metadata.isFile, !recommended.contains(path) {
                        recommended.append(path)
                    }
                } catch {
                    continue
                }
            }

            inspectorRecommendedFilePaths = recommended
            inspectorRecommendedFilesSource = recommended.isEmpty
                ? "fs/getMetadata：未找到推荐文件"
                : "fs/getMetadata：\(recommended.count) 个推荐文件"
        } catch {
            inspectorRecommendedFilePaths = []
            inspectorRecommendedFilesSource = "fs/getMetadata 失败：\(error.localizedDescription)"
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
            filePanelLastOperationSource = "fs/readDirectory + fs/watch"
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
        fileSearchStatusText = "正在启动 fuzzyFileSearch/sessionStart…"

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let sessionID = "raytone-file-search-\(UUID().uuidString)"
            activeFileSearchSessionID = sessionID
            completedFileSearchSessionIDs.remove(sessionID)
            ignoredFileSearchSessionIDs.remove(sessionID)
            do {
                try await client.startFuzzyFileSearchSession(sessionID: sessionID, roots: [workspacePath])
                try await client.updateFuzzyFileSearchSession(sessionID: sessionID, query: query)
                fileSearchStatusText = "fuzzyFileSearch/sessionUpdate：等待结果…"
                let completed = await waitForFuzzyFileSearchSession(sessionID: sessionID, timeout: 8)
                try? await client.stopFuzzyFileSearchSession(sessionID: sessionID)
                ignoredFileSearchSessionIDs.insert(sessionID)
                activeFileSearchSessionID = nil
                if completed {
                    fileSearchIsRunning = false
                    fileSearchStatusText = fileSearchResults.isEmpty
                        ? "fuzzyFileSearch/sessionCompleted：未找到匹配文件"
                        : "fuzzyFileSearch/sessionCompleted：\(fileSearchResults.count) 个匹配"
                    filePanelLastOperationSource = "fuzzyFileSearch/session"
                    runtimeCatalogStatusText = "\(fileSearchStatusText) · \(sessionID)"
                    return
                }
                fileSearchIsRunning = false
                fileSearchStatusText = fileSearchResults.isEmpty
                    ? "fuzzyFileSearch/sessionUpdate：等待超时，未收到匹配"
                    : "fuzzyFileSearch/sessionUpdate：等待超时，保留 \(fileSearchResults.count) 个匹配"
                return
            } catch {
                ignoredFileSearchSessionIDs.insert(sessionID)
                activeFileSearchSessionID = nil
                fileSearchStatusText = "fuzzyFileSearch/sessionStart 失败，降级 fuzzyFileSearch…"
            }

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
            filePanelLastOperationSource = "fuzzyFileSearch"
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

    private func waitForFuzzyFileSearchSession(sessionID: String, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if completedFileSearchSessionIDs.contains(sessionID) {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return completedFileSearchSessionIDs.contains(sessionID)
    }

    func clearFileSearch() {
        if let sessionID = activeFileSearchSessionID {
            ignoredFileSearchSessionIDs.insert(sessionID)
            activeFileSearchSessionID = nil
            Task { await stopFuzzyFileSearchSessionIfPossible(sessionID: sessionID) }
        }
        fileSearchQuery = ""
        fileSearchResults = []
        fileSearchStatusText = ""
        fileSearchIsRunning = false
    }

    private func stopFuzzyFileSearchSessionIfPossible(sessionID: String) async {
        guard let client = appServerClient else {
            return
        }
        try? await client.stopFuzzyFileSearchSession(sessionID: sessionID)
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
        filePanelStatusText = "正在创建文件…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            guard let path = try await filePanelChildPath(named: name, client: client) else { return }
            filePanelLastOperationSource = "fs/readDirectory + fs/writeFile"
            try await client.writeFile(path: path, data: Data())
            await loadFilePanelDirectory(currentFilePanelDirectoryPath)
            if let entry = fileEntry(matching: path) {
                await openFileEntry(entry)
                filePanelLastOperationSource = "fs/readDirectory + fs/writeFile + fs/getMetadata + fs/readFile"
            } else {
                filePanelLastOperationSource = "fs/readDirectory + fs/writeFile"
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
        filePanelStatusText = "正在创建文件夹…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            guard let path = try await filePanelChildPath(named: name, client: client) else { return }
            filePanelLastOperationSource = "fs/readDirectory + fs/createDirectory"
            try await client.createDirectory(path: path, recursive: true)
            await loadFilePanelDirectory(path)
            filePanelLastOperationSource = "fs/readDirectory + fs/createDirectory + fs/watch"
        } catch {
            filePanelStatusText = "创建失败：\(error.localizedDescription)"
        }
    }

    func duplicatePreviewedFileSystemItem() async {
        guard let preview = filePreview else {
            filePanelStatusText = "没有可复制的文件"
            return
        }

        filePanelStatusText = "正在复制文件…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let destinationPath = try await nextFilePanelCopyPath(for: preview.path, client: client)
            filePanelLastOperationSource = "fs/readDirectory + fs/copy"
            try await client.copyFileSystemItem(
                sourcePath: preview.path,
                destinationPath: destinationPath,
                recursive: false
            )
            await loadFilePanelDirectory(currentFilePanelDirectoryPath)
            if let entry = fileEntry(matching: destinationPath) {
                await openFileEntry(entry)
                filePanelLastOperationSource = "fs/readDirectory + fs/copy + fs/getMetadata + fs/readFile"
            } else {
                filePanelLastOperationSource = "fs/readDirectory + fs/copy"
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
            filePanelLastOperationSource = "fs/remove + fs/readDirectory"
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
            filePanelLastOperationSource = "fs/getMetadata + fs/readFile"
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

    private func filePanelChildPath(named rawName: String, client: CodexAppServerClient) async throws -> String? {
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
        guard !(try await appServerFilePanelPathExists(url.path, client: client)) else {
            filePanelStatusText = "已存在：\(name)"
            return nil
        }
        return url.path
    }

    private func nextFilePanelCopyPath(for path: String, client: CodexAppServerClient) async throws -> String {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()
        let extensionName = url.pathExtension
        let baseName = extensionName.isEmpty
            ? url.lastPathComponent
            : String(url.lastPathComponent.dropLast(extensionName.count + 1))
        let existingNames = Set(try await client.readDirectory(path: directory.path).map(\.fileName))
        filePanelLastOperationSource = "fs/readDirectory"

        for index in 1...999 {
            let suffix = index == 1 ? " 副本" : " 副本 \(index)"
            let candidateName = extensionName.isEmpty
                ? "\(baseName)\(suffix)"
                : "\(baseName)\(suffix).\(extensionName)"
            if !existingNames.contains(candidateName) {
                return directory.appendingPathComponent(candidateName).path
            }
        }

        let fallbackName = extensionName.isEmpty
            ? "\(baseName) 副本 \(UUID().uuidString)"
            : "\(baseName) 副本 \(UUID().uuidString).\(extensionName)"
        return directory.appendingPathComponent(fallbackName).path
    }

    private func appServerFilePanelPathExists(_ path: String, client: CodexAppServerClient) async throws -> Bool {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        let parentPath = url.deletingLastPathComponent().path
        let fileName = url.lastPathComponent
        let entries = try await client.readDirectory(path: parentPath)
        filePanelLastOperationSource = "fs/readDirectory"
        return entries.contains { $0.fileName == fileName || Self.filePanelPathsEqual($0.path, url.path) }
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
    func openSelectedFileInDefaultTarget(performExternalOpen: Bool = true) async -> FileOpenTargetRequest? {
        let path = filePreview?.path ?? fileEntries.first?.path ?? workspacePath
        filePanelStatusText = "正在检查打开目标…"

        let request: FileOpenTargetRequest
        do {
            guard let targetRequest = try await fileOpenTargetRequest(for: path) else {
                filePanelStatusText = "无法打开：\(Project.abbreviate(path))"
                return nil
            }
            request = targetRequest
        } catch {
            guard !Self.isCancellation(error) else {
                filePanelStatusText = "打开已取消"
                return nil
            }
            filePanelStatusText = "打开失败：\(error.localizedDescription)"
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

    private func fileOpenTargetRequest(for path: String) async throws -> FileOpenTargetRequest? {
        let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let client = try await ensureAppServerClient(useProviderConfiguration: false)
        let metadata = try await client.getMetadata(path: normalizedPath)
        filePanelLastOperationSource = "fs/getMetadata + openTarget"

        guard metadata.isDirectory || metadata.isFile else {
            return nil
        }

        let launchPath = metadata.isDirectory
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
            try await client.spawnProcess(
                ["/bin/zsh", "-lc", command],
                processHandle: processID,
                cwd: URL(fileURLWithPath: workspacePath),
                tty: true,
                streamStdin: true,
                streamStdoutStderr: true,
                rows: terminalRows,
                cols: terminalCols
            )
            runtimeCatalogStatusText = "process/spawn：\(processID)"
            await waitForTerminalRunToFinish(id: recordID)
        } catch {
            failTerminalRun(id: recordID, errorText: error.localizedDescription)
        }

        if activeTerminalRunID == recordID {
            resetActiveTerminal()
        }
    }

    func runThreadShellCommandFromTerminal() async {
        let command = terminalCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        guard !terminalIsRunning else {
            threadShellCommandStatusText = "当前终端命令运行中，暂不能提交线程 Shell"
            return
        }

        threadShellCommandStatusText = "正在调用 thread/shellCommand…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let threadID = try await ensureAppServerThread(client: client, options: appServerOptions())
            try await client.runThreadShellCommand(threadID: threadID, command: command)
            threadShellCommandStatusText = "thread/shellCommand：已提交"
            updateSelectedThread { thread in
                thread.activeGoal = ActiveGoal(title: "运行 shell：\(command)", startedAt: Date(), runtimeBacked: true)
                thread.updatedAt = Date()
            }
        } catch {
            threadShellCommandStatusText = "thread/shellCommand 失败：\(error.localizedDescription)"
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: threadShellCommandStatusText
                ))))
            }
        }
    }

    func cleanThreadBackgroundTerminals() async {
        backgroundTerminalCleanStatusText = "正在调用 thread/backgroundTerminals/clean…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let threadID = try await ensureAppServerThread(client: client, options: appServerOptions())
            try await client.cleanThreadBackgroundTerminals(threadID: threadID)
            backgroundTerminalCleanStatusText = "thread/backgroundTerminals/clean：已清理"
            runtimeCatalogStatusText = backgroundTerminalCleanStatusText
            runtimeCatalogErrors = []
        } catch {
            backgroundTerminalCleanStatusText = "thread/backgroundTerminals/clean 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = backgroundTerminalCleanStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: backgroundTerminalCleanStatusText
                ))))
            }
        }
    }

    func approveGuardianDeniedAction(_ denial: GuardianDeniedAction) async {
        runtimeCatalogStatusText = "正在调用 thread/approveGuardianDeniedAction…"
        do {
            let client: CodexAppServerClient
            if let existing = appServerClient {
                client = existing
            } else {
                client = try await ensureAppServerClient(useProviderConfiguration: true)
            }
            try await client.approveGuardianDeniedAction(threadID: denial.threadID, event: denial.event)
            recentGuardianDeniedActions.removeAll { $0.reviewID == denial.reviewID }
            runtimeCatalogStatusText = "thread/approveGuardianDeniedAction：已批准一次"
            updateSelectedThread { thread in
                thread.progressSteps.append(ProgressStep(title: "已批准自动审批拒绝：\(denial.summary)", state: .done))
                thread.updatedAt = Date()
            }
        } catch {
            runtimeCatalogStatusText = "thread/approveGuardianDeniedAction 失败：\(error.localizedDescription)"
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: runtimeCatalogStatusText
                ))))
            }
        }
    }

    func stopTerminalCommand() async {
        guard terminalIsRunning,
              let processID = activeTerminalProcessID,
              let client = appServerClient else {
            return
        }

        do {
            try await client.killProcess(processHandle: processID)
        } catch {
            if let runID = activeTerminalRunID {
                appendTerminalRunOutput(id: runID, text: "\n终止失败：\(error.localizedDescription)\n")
            }
        }
    }

    func resizeTerminal(rows: Int? = nil, cols: Int? = nil) async {
        let normalizedRows = min(max(rows ?? terminalRows, 10), 80)
        let normalizedCols = min(max(cols ?? terminalCols, 40), 240)
        terminalRows = normalizedRows
        terminalCols = normalizedCols

        guard terminalIsRunning,
              let processID = activeTerminalProcessID,
              let client = appServerClient else {
            terminalResizeStatusText = "\(normalizedRows)×\(normalizedCols) · 下次运行生效"
            return
        }

        do {
            try await client.resizeProcessPty(processHandle: processID, rows: normalizedRows, cols: normalizedCols)
            terminalResizeStatusText = "process/resizePty：\(normalizedRows)×\(normalizedCols)"
            if let runID = activeTerminalRunID {
                appendTerminalRunOutput(id: runID, text: "\n[终端尺寸 \(normalizedRows)×\(normalizedCols)]\n")
            }
        } catch {
            terminalResizeStatusText = "resize 失败：\(error.localizedDescription)"
            if let runID = activeTerminalRunID {
                appendTerminalRunOutput(id: runID, text: "\n调整终端尺寸失败：\(error.localizedDescription)\n")
            }
        }
    }

    private func writeTerminalInput(_ input: String) async {
        guard let processID = activeTerminalProcessID,
              let client = appServerClient else {
            return
        }

        do {
            try await client.writeProcessInput(processHandle: processID, data: Data(input.utf8))
        } catch {
            if let runID = activeTerminalRunID {
                appendTerminalRunOutput(id: runID, text: "\n写入 stdin 失败：\(error.localizedDescription)\n")
            }
        }
    }

    func openBrowserAddress(_ address: String) async {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let url = Self.browserURLCandidate(from: trimmed, workspacePath: workspacePath) else { return }
        if url.isFileURL {
            guard await verifyBrowserAddressFileURL(url) else {
                return
            }
        } else {
            browserDataStatusText = ""
        }
        browserURL = url
        browserTitle = url.isFileURL ? url.lastPathComponent : (url.host ?? url.absoluteString)
        browserCanGoBack = false
        browserCanGoForward = false
        browserSnapshotRequest = nil
        browserScreenshotStatusText = ""
        browserAttachedSnapshotPath = ""
        openToolPanel(.browser)
    }

    private static func browserURLCandidate(from address: String, workspacePath: String) -> URL? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("/") || trimmed.hasPrefix("~") {
            let expanded = (trimmed as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }
        if trimmed.hasPrefix("./") || trimmed.hasPrefix("../") {
            return URL(fileURLWithPath: workspacePath)
                .appendingPathComponent(trimmed)
                .standardizedFileURL
        }
        if let parsed = URL(string: trimmed), parsed.scheme != nil {
            return parsed
        }
        return URL(string: "https://\(trimmed)")
    }

    private func verifyBrowserAddressFileURL(_ url: URL) async -> Bool {
        let fileURL = url.standardizedFileURL
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let metadata = try await client.getMetadata(path: fileURL.path)
            guard metadata.isFile else {
                browserDataStatusText = metadata.isDirectory
                    ? "fs/getMetadata：地址栏目标是目录 · \(Project.abbreviate(fileURL.path))"
                    : "fs/getMetadata：地址栏目标不是可读取文件 · \(Project.abbreviate(fileURL.path))"
                return false
            }

            browserDataStatusText = "fs/getMetadata：已确认地址栏本地文件 · \(Project.abbreviate(fileURL.path))"
            return true
        } catch {
            browserDataStatusText = "fs/getMetadata 读取地址栏本地文件失败：\(error.localizedDescription)"
            return false
        }
    }

    func prepareBrowserSampleFileForOpening() async -> URL? {
        let sampleURL = URL(fileURLWithPath: workspacePath)
            .appendingPathComponent("docs/browser-sample.html")
            .standardizedFileURL

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let metadata = try await client.getMetadata(path: sampleURL.path)
            guard metadata.isFile else {
                browserDataStatusText = "fs/getMetadata：本地示例不是可读取文件 · \(Project.abbreviate(sampleURL.path))"
                return nil
            }

            let data = try await client.readFile(path: sampleURL.path)
            guard let html = String(data: data, encoding: .utf8),
                  html.localizedCaseInsensitiveContains("<html") ||
                  html.localizedCaseInsensitiveContains("<!doctype html") else {
                browserDataStatusText = "fs/getMetadata + fs/readFile：本地示例不是 HTML · \(Project.abbreviate(sampleURL.path))"
                return nil
            }

            browserDataStatusText = "fs/getMetadata + fs/readFile：已读取本地示例 \(data.count) bytes · \(Project.abbreviate(sampleURL.path))"
            return sampleURL
        } catch {
            browserDataStatusText = "fs/getMetadata 或 fs/readFile 读取本地示例失败：\(error.localizedDescription)"
            return nil
        }
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
        browserAttachedSnapshotPath = ""
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
            attachBrowserSnapshotToNextPrompt(url)
            browserScreenshotStatusText = "网页截图：\(Project.abbreviate(url.path)) · 已加入下次对话图片"
        case let .failure(error):
            browserScreenshotStatusText = "截图失败：\(error.localizedDescription)"
        }
    }

    private func attachBrowserSnapshotToNextPrompt(_ url: URL) {
        let path = Self.canonicalPath(url.path)
        guard !path.isEmpty else { return }

        if !pendingLocalImagePaths.contains(path) {
            pendingLocalImagePaths.append(path)
        }
        browserAttachedSnapshotPath = path

        let reference = Self.promptReferencePath(for: path, workspacePath: workspacePath)
        guard !prompt.contains(reference) else { return }

        let block = """
        请参考这张浏览器截图：
        - `\(reference)`
        """
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        prompt = trimmed.isEmpty ? block : "\(trimmed)\n\n\(block)"
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

    func refreshModelProviderCapabilities() async {
        modelProviderCapabilitiesStatusText = "正在读取 modelProvider/capabilities/read…"
        runtimeCatalogStatusText = modelProviderCapabilitiesStatusText
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let capabilities = try await client.readModelProviderCapabilities()
            modelProviderCapabilities = capabilities
            modelProviderCapabilitiesStatusText = "modelProvider/capabilities/read：\(Self.modelProviderCapabilitiesSummary(capabilities))"
            runtimeCatalogStatusText = modelProviderCapabilitiesStatusText
        } catch {
            modelProviderCapabilities = nil
            modelProviderCapabilitiesStatusText = "Provider 能力读取失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = modelProviderCapabilitiesStatusText
            runtimeCatalogErrors = [error.localizedDescription]
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
                let sharedCatalog = try await client.listSharedPluginCatalog()
                runtimeSharedPluginCount = sharedCatalog.plugins.count
                runtimePlugins = Self.mergedRuntimePlugins(runtimePlugins, with: sharedCatalog.plugins)
            } catch {
                runtimeSharedPluginCount = 0
                errors.append("plugin/share/list：\(error.localizedDescription)")
            }

            do {
                let catalog = try await client.listSkills(cwds: [workspacePath], forceReload: forceReloadSkills)
                runtimeSkills = catalog.skills
                errors.append(contentsOf: catalog.errors)
            } catch {
                errors.append("skills/list：\(error.localizedDescription)")
            }
            runtimeCatalogErrors = errors
            runtimeCatalogStatusText = "app-server：\(runtimePlugins.count) 个插件 · 共享 \(runtimeSharedPluginCount) 个 · \(runtimeSkills.count) 个技能 · 正在读取设置…"

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
            runtimeCatalogStatusText = "app-server：\(runtimePlugins.count) 个插件 · 共享 \(runtimeSharedPluginCount) 个 · \(runtimeSkills.count) 个技能 · \(runtimeMCPServers.count) 个 MCP · \(runtimeHooks.count) 个钩子"
        } catch {
            runtimeCatalogStatusText = "app-server 读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    private static func mergedRuntimePlugins(
        _ basePlugins: [CodexRuntimePlugin],
        with sharedPlugins: [CodexRuntimePlugin]
    ) -> [CodexRuntimePlugin] {
        guard !sharedPlugins.isEmpty else { return basePlugins }
        var merged = basePlugins
        for sharedPlugin in sharedPlugins {
            if let index = merged.firstIndex(where: { $0.id == sharedPlugin.id }) {
                if merged[index].shareContext == nil {
                    merged[index] = sharedPlugin
                }
            } else {
                merged.append(sharedPlugin)
            }
        }
        return merged
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

    func detectExternalAgentConfig() async {
        runtimeCatalogIsRefreshing = true
        externalAgentMigrationStatusText = "正在调用 externalAgentConfig/detect…"
        runtimeCatalogStatusText = externalAgentMigrationStatusText
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.detectExternalAgentConfig(includeHome: true, cwds: [workspacePath])
            externalAgentMigrationItems = result.items
            externalAgentMigrationStatusText = result.items.isEmpty
                ? "externalAgentConfig/detect：未检测到可迁移项"
                : "externalAgentConfig/detect：检测到 \(result.items.count) 项"
            runtimeCatalogStatusText = externalAgentMigrationStatusText
        } catch {
            externalAgentMigrationItems = []
            externalAgentMigrationStatusText = "externalAgentConfig/detect 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = externalAgentMigrationStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    func importExternalAgentConfig(_ items: [CodexExternalAgentMigrationItem]? = nil) async {
        let selectedItems = items ?? externalAgentMigrationItems
        guard !selectedItems.isEmpty else {
            externalAgentMigrationStatusText = "externalAgentConfig/import：没有可导入项"
            runtimeCatalogStatusText = externalAgentMigrationStatusText
            return
        }

        runtimeCatalogIsRefreshing = true
        externalAgentMigrationIsImporting = true
        externalAgentImportedItemCount = selectedItems.count
        externalAgentMigrationStatusText = "正在调用 externalAgentConfig/import…"
        runtimeCatalogStatusText = externalAgentMigrationStatusText
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.importExternalAgentConfig(items: selectedItems)
            if externalAgentMigrationIsImporting {
                externalAgentMigrationStatusText = "externalAgentConfig/import：已提交 \(selectedItems.count) 项，等待完成通知"
                runtimeCatalogStatusText = externalAgentMigrationStatusText
            }
        } catch {
            externalAgentMigrationIsImporting = false
            externalAgentMigrationStatusText = "externalAgentConfig/import 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = externalAgentMigrationStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    private func refreshExternalAgentMigrationItemsAfterImport() async {
        let countText = externalAgentImportedItemCount > 0 ? "\(externalAgentImportedItemCount) 项" : "所选项目"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.detectExternalAgentConfig(includeHome: true, cwds: [workspacePath])
            externalAgentMigrationItems = result.items
            let remainingText = result.items.isEmpty ? "无剩余项" : "剩余 \(result.items.count) 项"
            externalAgentMigrationStatusText = "externalAgentConfig/import/completed：已完成 \(countText) · \(remainingText)"
            runtimeCatalogStatusText = externalAgentMigrationStatusText
            runtimeCatalogErrors = []
        } catch {
            externalAgentMigrationStatusText = "externalAgentConfig/import/completed：已完成 \(countText)；剩余项刷新失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = externalAgentMigrationStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func refreshRuntimeExperimentalFeatures() async {
        runtimeCatalogIsRefreshing = true
        runtimeExperimentalFeaturesStatusText = "正在读取 experimentalFeature/list…"
        runtimeCatalogStatusText = runtimeExperimentalFeaturesStatusText
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let catalog = try await client.listExperimentalFeatures(threadID: selectedThread.appServerThreadID)
            runtimeExperimentalFeatures = catalog.features
            runtimeExperimentalFeaturesNextCursor = catalog.nextCursor
            runtimeExperimentalFeaturesStatusText = "experimentalFeature/list：\(catalog.features.count) 个功能"
            runtimeCatalogStatusText = runtimeExperimentalFeaturesStatusText
        } catch {
            runtimeExperimentalFeaturesStatusText = "实验功能读取失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimeExperimentalFeaturesStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
        runtimeCatalogIsRefreshing = false
    }

    func setRuntimeExperimentalFeature(_ feature: CodexExperimentalFeature, enabled: Bool) async {
        runtimeCatalogIsRefreshing = true
        runtimeExperimentalFeaturesStatusText = "正在调用 experimentalFeature/enablement/set…"
        runtimeCatalogStatusText = runtimeExperimentalFeaturesStatusText
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let updated = try await client.setExperimentalFeatureEnablement([feature.name: enabled])
            let acceptedValue = updated[feature.name]
            let catalog = try await client.listExperimentalFeatures(threadID: selectedThread.appServerThreadID)
            runtimeExperimentalFeatures = catalog.features
            runtimeExperimentalFeaturesNextCursor = catalog.nextCursor
            if acceptedValue == enabled {
                runtimeExperimentalFeaturesStatusText = "experimentalFeature/enablement/set：\(feature.name) \(enabled ? "已开启" : "已关闭")"
            } else {
                runtimeExperimentalFeaturesStatusText = "experimentalFeature/enablement/set：app-server 未接受 \(feature.name)"
            }
            runtimeCatalogStatusText = runtimeExperimentalFeaturesStatusText
        } catch {
            runtimeExperimentalFeaturesStatusText = "实验功能写入失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimeExperimentalFeaturesStatusText
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

    func mcpResourceTemplateKey(_ template: CodexRuntimeMCPResourceTemplate, server: CodexRuntimeMCPServer) -> String {
        "\(server.name)::\(template.uriTemplate)"
    }

    func readMCPResourceTemplate(_ template: CodexRuntimeMCPResourceTemplate, from server: CodexRuntimeMCPServer) async {
        let key = mcpResourceTemplateKey(template, server: server)
        let candidateURI = (mcpResourceTemplateURIText[key] ?? template.uriTemplate)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidateURI.isEmpty else {
            mcpResourceStatusText = "资源模板 URI 不能为空"
            runtimeCatalogStatusText = mcpResourceStatusText
            return
        }
        guard !candidateURI.contains("{"), !candidateURI.contains("}") else {
            mcpResourceStatusText = "请先把模板参数替换为实际 URI：\(template.uriTemplate)"
            runtimeCatalogStatusText = mcpResourceStatusText
            return
        }

        runtimeCatalogIsRefreshing = true
        mcpResourceStatusText = "正在通过模板读取 \(template.displayName)…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.readMCPResource(
                server: server.name,
                uri: candidateURI,
                threadID: selectedThread.appServerThreadID
            )
            mcpResourcePreview = result
            mcpResourceStatusText = "mcpServer/resource/read：模板 \(template.name) · \(result.contents.count) 段内容"
            runtimeCatalogStatusText = mcpResourceStatusText
        } catch {
            mcpResourceStatusText = "资源模板读取失败：\(error.localizedDescription)"
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

    func refreshProfilePrivacyRuntimeStatus() async -> String {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 account/read 刷新个人资料状态…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            runtimeAccount = try await client.readAccount(refreshToken: false)
            let accountLabel = runtimeAccount.map { Self.accountDisplayName($0) } ?? "未返回账户"
            runtimeCatalogStatusText = "account/read：个人资料状态已刷新 · \(accountLabel)"
            runtimeCatalogIsRefreshing = false
            return "个人资料保持私有；app-server 未提供 profile/privacy 写接口，已通过 account/read 刷新账户状态"
        } catch {
            let message = "个人资料状态刷新失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = message
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            return message
        }
    }

    func copyRuntimeProfileShareSummary() async -> String {
        await refreshAccountUsageRuntime()

        let summary = runtimeProfileShareSummary()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)

        let status = "已复制分享摘要 · account/read + account/usage/read + account/rateLimits/read"
        runtimeCatalogStatusText = status
        return status
    }

    func runtimeProfileShareSummary() -> String {
        let account = runtimeAccount.map(Self.accountDisplayName) ?? "未返回账户"
        let accountKind = runtimeAccount.map { Self.runtimeAccountKindName($0.kind) } ?? "未返回"
        let plan = runtimeAccount?.planType ?? "未返回"
        let tokenTotal = runtimeTokenUsage?.lifetimeTokens.map(Self.compactNumber) ?? "未返回"
        let peakDaily = runtimeTokenUsage?.peakDailyTokens.map(Self.compactNumber) ?? "未返回"
        let rateLimitCount = runtimeRateLimits.map { "\($0.buckets.count)" } ?? "未返回"
        let providerModel = selectedProvider.usesSidecar ? selectedProvider.model : (model.isEmpty ? selectedProvider.model : model)
        let providerSummary = providerModel.isEmpty ? selectedProvider.displayName : "\(selectedProvider.displayName) / \(providerModel)"
        let errors = runtimeCatalogErrors.isEmpty ? "无" : runtimeCatalogErrors.joined(separator: "；")

        return """
        RaytoneCodex
        账户：\(account)
        类型：\(accountKind)
        计划：\(plan)
        运行时：\(runtimeSummary)
        工作区：\(Project.abbreviate(workspacePath))
        累计 Token：\(tokenTotal)
        单日峰值：\(peakDaily)
        速率限制桶：\(rateLimitCount)
        Provider：\(providerSummary)
        来源：account/read + account/usage/read + account/rateLimits/read
        读取错误：\(errors)
        """
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
            providerUsageByProviderID[provider.id] = usage
            providerUsageStatusText = "sidecar /usage：\(usage.successfulResponses) 次响应"
        } catch {
            providerUsage = nil
            providerUsageStatusText = "sidecar 用量读取失败：\(error.localizedDescription)"
        }
    }

    func sendAddCreditsNudgeEmail(creditType: CodexAddCreditsNudgeCreditType) async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 account/sendAddCreditsNudgeEmail…"
        addCreditsNudgeStatusText = "正在发送…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let status = try await client.sendAddCreditsNudgeEmail(creditType: creditType)
            let statusText = Self.addCreditsNudgeStatusName(status)
            addCreditsNudgeStatusText = statusText
            runtimeCatalogStatusText = "account/sendAddCreditsNudgeEmail：\(statusText)"
        } catch {
            addCreditsNudgeStatusText = "发送失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = "额度提醒邮件失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
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

    func startAccountChatGPTDeviceCodeLogin(openBrowser: Bool = true) async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 account/login/start(chatgptDeviceCode)…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let login = try await client.startChatGPTDeviceCodeAccountLogin()
            activeAccountLogin = login
            let codeText = login.userCode.map { " · 设备码 \($0)" } ?? ""
            if openBrowser, let verificationURL = login.verificationURL {
                NSWorkspace.shared.open(verificationURL)
                runtimeCatalogStatusText = "已打开设备码验证页，等待 account/login/completed\(codeText)"
            } else if let verificationURL = login.verificationURL {
                let host = verificationURL.host ?? "verification URL"
                runtimeCatalogStatusText = "account/login/start(chatgptDeviceCode)：\(host)\(codeText)"
            } else {
                runtimeCatalogStatusText = "account/login/start(chatgptDeviceCode)：\(login.kind)\(codeText)"
            }
        } catch {
            runtimeCatalogStatusText = "设备码登录启动失败：\(error.localizedDescription)"
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
        let trimmedSearch = searchTerm?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        runtimeThreadSyncStatusText = trimmedSearch.isEmpty ? "正在读取 thread/list…" : "正在搜索 thread/search…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            if !trimmedSearch.isEmpty {
                do {
                    let catalog = try await client.searchThreads(
                        searchTerm: trimmedSearch,
                        archived: false,
                        limit: limit
                    )
                    runtimeThreadSearchSnippets = Dictionary(
                        uniqueKeysWithValues: catalog.results.map { ($0.thread.id, $0.snippet) }
                    )
                    mergeRuntimeThreads(catalog.results.map(\.thread))
                    runtimeThreadSyncStatusText = "thread/search：\(catalog.results.count) 个匹配"
                    return
                } catch {
                    runtimeThreadSearchSnippets = [:]
                    runtimeThreadSyncStatusText = "thread/search 失败，降级 thread/list…"
                }
            } else {
                runtimeThreadSearchSnippets = [:]
            }

            let catalog = try await client.listThreads(
                archived: false,
                cwd: nil,
                limit: limit,
                searchTerm: trimmedSearch.isEmpty ? nil : trimmedSearch
            )
            mergeRuntimeThreads(catalog.threads)
            runtimeThreadSyncStatusText = trimmedSearch.isEmpty
                ? "thread/list：\(catalog.threads.count) 个历史对话"
                : "thread/list：\(catalog.threads.count) 个标题匹配"
        } catch {
            runtimeThreadSyncStatusText = "历史对话读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func refreshLoadedRuntimeThreads(limit: Int = 100) async {
        runtimeLoadedThreadsStatusText = "正在读取 thread/loaded/list…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let catalog = try await client.listLoadedThreads(limit: limit)
            loadedRuntimeThreadIDs = catalog.threadIDs
            let selectedThreadID = selectedThread.appServerThreadID ?? ""
            let selectedLoaded = !selectedThreadID.isEmpty && catalog.threadIDs.contains(selectedThreadID)
            runtimeLoadedThreadsStatusText = selectedLoaded
                ? "thread/loaded/list：\(catalog.threadIDs.count) 个 · 当前线程已加载"
                : "thread/loaded/list：\(catalog.threadIDs.count) 个"
        } catch {
            loadedRuntimeThreadIDs = []
            runtimeLoadedThreadsStatusText = "已加载线程读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func syncSelectedThreadGitMetadata() async {
        guard let threadID = selectedThread.appServerThreadID, !threadID.isEmpty else {
            runtimeThreadMetadataStatusText = "当前对话还没有 app-server threadId"
            return
        }

        runtimeThreadMetadataStatusText = "正在读取 Git 元数据…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommand(
                ["/bin/zsh", "-lc", Self.gitMetadataCommand],
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: .readOnly,
                timeoutMs: 10_000
            )
            let metadata = Self.parseGitMetadataCommandOutput(result.stdout)
            guard metadata.branch != nil || metadata.sha != nil || metadata.originURL != nil else {
                runtimeThreadMetadataStatusText = "当前工作区没有可同步的 Git 元数据"
                return
            }

            let summary = try await client.updateThreadGitMetadata(
                threadID: threadID,
                branch: metadata.branch,
                sha: metadata.sha,
                originURL: metadata.originURL
            )
            mergeRuntimeThreads([summary])
            if let branch = summary.gitBranch ?? metadata.branch {
                updateSelectedProject(branch: branch)
            }
            let shaPreview = (summary.gitSHA ?? metadata.sha ?? "")
                .prefix(12)
            let branchText = summary.gitBranch ?? metadata.branch ?? "无分支"
            runtimeThreadMetadataStatusText = shaPreview.isEmpty
                ? "thread/metadata/update：\(branchText)"
                : "thread/metadata/update：\(branchText) · \(shaPreview)"
        } catch {
            runtimeThreadMetadataStatusText = "thread/metadata/update 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func loadRuntimeThreadTranscript(localThreadID: UUID? = nil) async {
        let targetID = localThreadID ?? selectedThreadID
        guard let localIndex = threads.firstIndex(where: { $0.id == targetID }),
              let serverThreadID = threads[localIndex].appServerThreadID else {
            return
        }

        runtimeThreadSyncStatusText = "正在读取 thread/turns/list…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            do {
                let turns = try await loadRuntimeThreadTurns(
                    client: client,
                    threadID: serverThreadID
                )
                applyRuntimeThreadTurns(turns, threadID: serverThreadID, to: targetID)
                runtimeThreadSyncStatusText = "thread/turns/list：已加载 \(turns.count) 轮历史 transcript"
                return
            } catch {
                runtimeThreadSyncStatusText = "thread/turns/list 不可用，降级 thread/read…"
            }

            let result = try await client.readThread(id: serverThreadID, includeTurns: true)
            applyRuntimeThreadRead(result, to: targetID)
            runtimeThreadSyncStatusText = "thread/read：已加载历史 transcript"
        } catch {
            runtimeThreadSyncStatusText = "历史 transcript 读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func resumeRuntimeThread(localThreadID: UUID? = nil, loadTranscript: Bool = false) async {
        let targetID = localThreadID ?? selectedThreadID
        guard let localIndex = threads.firstIndex(where: { $0.id == targetID }),
              let serverThreadID = threads[localIndex].appServerThreadID else {
            if loadTranscript {
                await loadRuntimeThreadTranscript(localThreadID: targetID)
            }
            return
        }
        guard !isRunning else {
            runtimeThreadSyncStatusText = "当前有运行中的轮次，暂不能恢复历史线程"
            return
        }

        runtimeThreadSyncStatusText = "正在调用 thread/resume…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let serverThread = try await client.resumeThread(
                id: serverThreadID,
                options: appServerOptions(),
                excludeTurns: true
            )
            updateThread(localThreadID: targetID) { thread in
                thread.appServerThreadID = serverThread.id
                thread.appServerSessionID = serverThread.sessionID
                if let memoryMode = serverThread.memoryMode {
                    thread.memoryMode = memoryMode
                }
            }
            if !loadedRuntimeThreadIDs.contains(serverThread.id) {
                loadedRuntimeThreadIDs.insert(serverThread.id, at: 0)
            }
            runtimeThreadSyncStatusText = "thread/resume：已恢复 \(serverThread.id)"
        } catch {
            runtimeThreadSyncStatusText = "thread/resume 失败，降级读取历史：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        if loadTranscript {
            await loadRuntimeThreadTranscript(localThreadID: targetID)
        }
    }

    private func loadRuntimeThreadTurns(
        client: CodexAppServerClient,
        threadID: String,
        pageLimit: Int = 100,
        maxPages: Int = 20
    ) async throws -> [JSONValue] {
        var cursor: String?
        var turns: [JSONValue] = []
        for _ in 0..<maxPages {
            let page = try await client.listThreadTurns(
                id: threadID,
                limit: pageLimit,
                cursor: cursor,
                sortDirection: "asc",
                itemsView: "full"
            )
            turns.append(contentsOf: page.turns)
            guard let nextCursor = page.nextCursor, !nextCursor.isEmpty else {
                break
            }
            cursor = nextCursor
        }
        turns = try await turnsWithFullRuntimeItems(
            turns,
            threadID: threadID,
            client: client,
            pageLimit: pageLimit,
            maxPages: maxPages
        )
        return turns
    }

    private func turnsWithFullRuntimeItems(
        _ turns: [JSONValue],
        threadID: String,
        client: CodexAppServerClient,
        pageLimit: Int,
        maxPages: Int
    ) async throws -> [JSONValue] {
        var enrichedTurns: [JSONValue] = []
        enrichedTurns.reserveCapacity(turns.count)

        for turn in turns {
            guard let turnID = turn["id"]?.stringValue else {
                enrichedTurns.append(turn)
                continue
            }

            do {
                let items = try await loadRuntimeThreadTurnItems(
                    client: client,
                    threadID: threadID,
                    turnID: turnID,
                    pageLimit: pageLimit,
                    maxPages: maxPages
                )
                guard !items.isEmpty, var object = turn.objectValue else {
                    enrichedTurns.append(turn)
                    continue
                }
                object["items"] = .array(items)
                enrichedTurns.append(.object(object))
            } catch {
                enrichedTurns.append(turn)
            }
        }

        return enrichedTurns
    }

    private func loadRuntimeThreadTurnItems(
        client: CodexAppServerClient,
        threadID: String,
        turnID: String,
        pageLimit: Int = 100,
        maxPages: Int = 20
    ) async throws -> [JSONValue] {
        var cursor: String?
        var items: [JSONValue] = []
        for _ in 0..<maxPages {
            let page = try await client.listThreadTurnItems(
                id: threadID,
                turnID: turnID,
                limit: pageLimit,
                cursor: cursor,
                sortDirection: "asc"
            )
            items.append(contentsOf: page.items)
            guard let nextCursor = page.nextCursor, !nextCursor.isEmpty else {
                break
            }
            cursor = nextCursor
        }
        return items
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
            let unsubscribeStatusText: String
            do {
                let unsubscribeStatus = try await client.unsubscribeThread(id: threadID)
                unsubscribeStatusText = unsubscribeStatus.rawValue
            } catch {
                unsubscribeStatusText = "failed: \(error.localizedDescription)"
                runtimeCatalogErrors = [error.localizedDescription]
            }
            rememberArchivedRuntimeThread(id: threadID, title: title, preview: preview, cwd: cwd)
            loadedRuntimeThreadIDs.removeAll { $0 == threadID }
            runtimeCatalogStatusText = "thread/archive：已归档 \(threadID) · unsubscribe \(unsubscribeStatusText)"
            runtimeLoadedThreadsStatusText = "thread/unsubscribe：\(unsubscribeStatusText)"
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
            if let memoryMode = serverThread.memoryMode {
                threads[index].memoryMode = memoryMode
            }
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
                if let memoryMode = summary.memoryMode {
                    threads[index].memoryMode = memoryMode
                }
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
                    memoryMode: summary.memoryMode,
                    appServerThreadID: summary.id,
                    appServerSessionID: nil,
                    updatedAt: updatedAt
                ))
            }
        }
    }

    private func mergeRuntimeThreadValue(_ threadValue: JSONValue) {
        guard let summary = Self.runtimeThreadSummary(from: threadValue) else {
            return
        }
        mergeRuntimeThreads([summary])
        if let sessionID = threadValue["sessionId"]?.stringValue {
            updateThread(appServerThreadID: summary.id) { thread in
                thread.appServerSessionID = sessionID
            }
        }
    }

    private static func runtimeThreadSummary(from value: JSONValue) -> CodexRuntimeThreadSummary? {
        guard let id = value["id"]?.stringValue else {
            return nil
        }
        let gitInfo = value["gitInfo"]
        let title = value["name"]?.stringValue ??
            value["threadName"]?.stringValue ??
            value["preview"]?.stringValue ??
            "未命名对话"
        return CodexRuntimeThreadSummary(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未命名对话" : title,
            preview: value["preview"]?.stringValue ?? "",
            cwd: runtimePathString(value["cwd"]),
            modelProvider: value["modelProvider"]?.stringValue,
            source: value["source"]?.stringValue ?? value["source"]?["type"]?.stringValue,
            createdAt: runtimeTimestampString(value["createdAt"]),
            updatedAt: runtimeTimestampString(value["updatedAt"] ?? value["recencyAt"]),
            archived: value["archived"]?.boolValue ?? false,
            gitBranch: gitInfo?["branch"]?.stringValue,
            gitSHA: gitInfo?["sha"]?.stringValue,
            gitOriginURL: gitInfo?["originUrl"]?.stringValue,
            memoryMode: CodexThreadMemoryMode(
                rawValue: value["memoryMode"]?.stringValue ?? value["memory_mode"]?.stringValue ?? ""
            )
        )
    }

    private static func runtimePathString(_ value: JSONValue?) -> String? {
        value?.stringValue ?? value?["path"]?.stringValue
    }

    private static func runtimeTimestampString(_ value: JSONValue?) -> String? {
        guard let value else {
            return nil
        }
        if let string = value.stringValue {
            return string
        }
        if case let .number(seconds) = value {
            return ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: seconds))
        }
        return nil
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
        if let memoryMode = CodexThreadMemoryMode(
            rawValue: threadValue["memoryMode"]?.stringValue ?? threadValue["memory_mode"]?.stringValue ?? ""
        ) {
            threads[index].memoryMode = memoryMode
        }
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

    private func applyRuntimeThreadTurns(
        _ turns: [JSONValue],
        threadID: String,
        to localThreadID: UUID
    ) {
        guard let index = threads.firstIndex(where: { $0.id == localThreadID }) else {
            return
        }
        threads[index].items = transcriptItems(from: turns, threadID: threadID)
        if let lastTimestamp = turns.reversed().compactMap({ turn in
            Self.dateFromRuntimeSeconds(turn["completedAt"]) ??
                Self.dateFromRuntimeSeconds(turn["startedAt"])
        }).first {
            threads[index].updatedAt = lastTimestamp
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
        runtimeCatalogStatusText = "正在通过 command/exec 读取 Git 状态…"
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.execCommand(
                ["/bin/zsh", "-lc", Self.workspaceGitSnapshotCommand],
                cwd: URL(fileURLWithPath: workspacePath),
                sandbox: .readOnly,
                timeoutMs: 20_000
            )
            let snapshot = Self.parseWorkspaceGitSnapshot(stdout: result.stdout, stderr: result.stderr)
            workspaceGitDiff = snapshot.isGitRepository
                ? CodexRuntimeGitDiff(sha: snapshot.sha, diff: snapshot.diff)
                : nil
            workspaceGitStatusText = snapshot.status
            let parsed = Self.parseUnifiedDiff(workspaceGitDiff?.diff ?? "")
            let statusCount = workspaceGitStatusText
                .split(separator: "\n", omittingEmptySubsequences: true)
                .filter { !$0.hasPrefix("##") }
                .count
            let statusSuffix = statusCount > 0 ? " · Git 状态 \(statusCount) 项" : ""
            runtimeCatalogStatusText = "command/exec git：+\(parsed.additions) −\(parsed.deletions)\(statusSuffix)"
        } catch {
            runtimeCatalogStatusText = "Git 状态读取失败：\(error.localizedDescription)"
            runtimeCatalogErrors = ["command/exec git：\(error.localizedDescription)"]
        }
        runtimeCatalogIsRefreshing = false
    }

    private static let workspaceGitSnapshotCommand = """
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          echo "__RAYTONE_GIT_STATUS__"
          echo "不是 Git 工作区"
          exit 0
        fi
        echo "__RAYTONE_GIT_SHA__"
        git rev-parse HEAD 2>/dev/null || true
        echo "__RAYTONE_GIT_STATUS__"
        git status --short --branch 2>&1 || true
        echo "__RAYTONE_GIT_DIFF__"
        git diff -- . 2>&1 || true
        """

    private static func parseWorkspaceGitSnapshot(
        stdout: String,
        stderr: String
    ) -> (isGitRepository: Bool, sha: String?, status: String, diff: String) {
        var sections: [String: [String]] = [:]
        var currentSection: String?

        for line in stdout.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            switch line {
            case "__RAYTONE_GIT_SHA__":
                currentSection = "sha"
            case "__RAYTONE_GIT_STATUS__":
                currentSection = "status"
            case "__RAYTONE_GIT_DIFF__":
                currentSection = "diff"
            default:
                guard let currentSection else { continue }
                sections[currentSection, default: []].append(line)
            }
        }

        let sha = sections["sha"]?
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var status = sections["status"]?
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let diff = sections["diff"]?
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stderrText = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stderrText.isEmpty {
            status = [status, "stderr:\n\(stderrText)"]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")
        }

        return (
            isGitRepository: status != "不是 Git 工作区",
            sha: sha,
            status: status,
            diff: diff
        )
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
        await refreshLoadedRuntimeThreads()
        await syncSelectedThreadGitMetadata()

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
        runtimeCatalogStatusText = "环境已刷新：\(workspaceBranches.count) 个分支 · \(changeText) · \(workspaceWorktrees.count) 个工作树 · \(loadedRuntimeThreadIDs.count) 个已加载线程"
        runtimeCatalogIsRefreshing = false
    }

    func runGitCommitPushPreflightInTerminal() async {
        showInspector = true
        openToolPanel(.terminal)
        terminalCommand = Self.gitCommitPushPreflightCommand
        await runTerminalCommand()
    }

    func runGitCreateRepositoryInTerminal() async {
        showInspector = true
        openToolPanel(.terminal)
        terminalCommand = Self.gitCreateRepositoryCommand
        await runTerminalCommand()
        await syncSelectedThreadGitMetadata()
        await refreshWorkspacePullRequestStatus()
    }

    func runGitPushCurrentBranchInTerminal() async {
        showInspector = true
        openToolPanel(.terminal)
        terminalCommand = Self.gitPushCurrentBranchCommand
        await runTerminalCommand()
        await refreshWorkspacePullRequestStatus()
    }

    func runGitCreatePullRequestInTerminal() async {
        showInspector = true
        openToolPanel(.terminal)
        terminalCommand = Self.gitCreatePullRequestCommand
        await runTerminalCommand()
        await refreshWorkspacePullRequestStatus()
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
                let snapshotCount = catalog.apps.filter { !$0.screenshotPrompts.isEmpty }.count
                runtimeAppsStatusText = "app/list：\(catalog.apps.count) 个 app · \(snapshotCount) 个含快照说明"
            } catch {
                errors.append("app/list：\(error.localizedDescription)")
                runtimeAppsStatusText = "app/list 失败：\(error.localizedDescription)"
            }

            do {
                let status = try await client.readRemoteControlStatus()
                applyRemoteControlStatus(status)
                do {
                    try await loadRemoteControlClientsIfAvailable(using: client, environmentID: status.environmentID)
                } catch {
                    errors.append("remoteControl/client/list：\(error.localizedDescription)")
                }
            } catch {
                errors.append("remoteControl/status/read：\(error.localizedDescription)")
            }

            do {
                let catalog = try await client.listPermissionProfiles(cwd: workspacePath)
                runtimePermissionProfiles = catalog.profiles
            } catch {
                errors.append("permissionProfile/list：\(error.localizedDescription)")
            }

            do {
                let readiness = try await client.readWindowsSandboxReadiness()
                applyWindowsSandboxReadiness(readiness)
            } catch {
                windowsSandboxReadinessStatusText = "windowsSandbox/readiness 失败：\(error.localizedDescription)"
                errors.append("windowsSandbox/readiness：\(error.localizedDescription)")
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

    @discardableResult
    func registerRuntimeEnvironment() async -> Bool {
        let environmentID = runtimeEnvironmentIDDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let execServerURL = runtimeEnvironmentURLDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let environmentCwd = runtimeEnvironmentCwdDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !environmentID.isEmpty else {
            runtimeEnvironmentStatusText = "请输入环境 ID"
            return false
        }
        guard URL(string: execServerURL) != nil else {
            runtimeEnvironmentStatusText = "请输入有效的执行服务器 URL"
            return false
        }

        runtimeEnvironmentStatusText = "正在调用 environment/add…"
        runtimeCatalogStatusText = "正在注册远程环境 \(environmentID)…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.addEnvironment(environmentID: environmentID, execServerURL: execServerURL)
            let registration = RuntimeEnvironmentRegistration(
                environmentID: environmentID,
                execServerURL: execServerURL,
                cwd: environmentCwd.isEmpty ? workspacePath : environmentCwd,
                registeredAt: Date()
            )
            if let index = runtimeRegisteredEnvironments.firstIndex(where: { $0.environmentID == environmentID }) {
                runtimeRegisteredEnvironments[index] = registration
            } else {
                runtimeRegisteredEnvironments.append(registration)
            }
            selectedRuntimeEnvironmentID = environmentID
            runtimeEnvironmentStatusText = "environment/add：已注册 \(environmentID)"
            runtimeCatalogStatusText = "environment/add：已注册 \(environmentID)"
            return true
        } catch {
            runtimeEnvironmentStatusText = "environment/add 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimeEnvironmentStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            return false
        }
    }

    func selectRuntimeEnvironment(_ environmentID: String?) {
        selectedRuntimeEnvironmentID = environmentID
        if let environmentID, !environmentID.isEmpty {
            runtimeEnvironmentStatusText = "已选择环境：\(environmentID)"
        } else {
            runtimeEnvironmentStatusText = "使用默认本地环境"
        }
    }

    func refreshWindowsSandboxReadiness() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在读取 windowsSandbox/readiness…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let readiness = try await client.readWindowsSandboxReadiness()
            applyWindowsSandboxReadiness(readiness)
            runtimeCatalogStatusText = windowsSandboxReadinessStatusText
        } catch {
            windowsSandboxReadinessStatusText = "windowsSandbox/readiness 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = windowsSandboxReadinessStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    @discardableResult
    func startWindowsSandboxSetup(mode: CodexWindowsSandboxSetupMode) async -> Bool {
        runtimeCatalogIsRefreshing = true
        windowsSandboxSetupStatusText = "正在调用 windowsSandbox/setupStart…"
        runtimeCatalogStatusText = windowsSandboxSetupStatusText
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let started = try await client.startWindowsSandboxSetup(mode: mode, cwd: workspacePath)
            windowsSandboxSetupStatusText = started
                ? "windowsSandbox/setupStart：已启动 \(Self.windowsSandboxSetupModeName(mode))"
                : "windowsSandbox/setupStart：未启动"
            runtimeCatalogStatusText = windowsSandboxSetupStatusText
            runtimeCatalogErrors = []
            runtimeCatalogIsRefreshing = false
            return started
        } catch {
            windowsSandboxSetupStatusText = "windowsSandbox/setupStart 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = windowsSandboxSetupStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            return false
        }
    }

    private func applyWindowsSandboxReadiness(_ readiness: CodexWindowsSandboxReadiness) {
        windowsSandboxReadiness = readiness
        windowsSandboxReadinessStatusText = "windowsSandbox/readiness：\(Self.windowsSandboxReadinessName(readiness))"
    }

    @discardableResult
    func openRuntimeAppInstallURL(_ app: CodexRuntimeAppInfo, openExternal: Bool = true) -> Bool {
        guard let installURL = app.installURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !installURL.isEmpty,
              let url = URL(string: installURL) else {
            runtimeCatalogStatusText = "app/list：\(app.name) 没有返回 installUrl"
            return false
        }

        lastOpenedRuntimeAppInstallURL = installURL
        runtimeCatalogStatusText = "app/list：打开 \(app.name) 安装链接"
        if openExternal {
            NSWorkspace.shared.open(url)
        }
        return true
    }

    @discardableResult
    func setRuntimeAppEnabled(_ app: CodexRuntimeAppInfo, enabled: Bool) async -> Bool {
        runtimeCatalogIsRefreshing = true
        let completedText = enabled ? "已启用" : "已停用"
        runtimeCatalogStatusText = "正在写入 apps.\(app.id).enabled…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(
                keyPath: "apps.\(Self.quotedConfigKeyPathSegment(app.id)).enabled",
                value: .bool(enabled)
            )
            await refreshIntegrationRuntime(forceRefetchApps: true)
            let updatedApp = runtimeApps.first { $0.id == app.id }
            let snapshotCount = runtimeApps.filter { !$0.screenshotPrompts.isEmpty }.count
            if updatedApp?.isEnabled == enabled {
                runtimeCatalogStatusText = "config/value/write + app/list：\(app.name) \(completedText)"
            } else if let updatedApp {
                let observedText = updatedApp.isEnabled ? "启用" : "停用"
                runtimeCatalogStatusText = "config/value/write：已提交；app/list 仍显示\(observedText)"
            } else {
                runtimeCatalogStatusText = "config/value/write：已提交；app/list 未找到 \(app.name)"
            }
            runtimeAppsStatusText = "app/list：\(runtimeApps.count) 个 app · \(snapshotCount) 个含快照说明"
            runtimeCatalogIsRefreshing = false
            return true
        } catch {
            runtimeCatalogStatusText = "应用设置写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            return false
        }
    }

    @discardableResult
    func useRuntimeAppInComposer(_ app: CodexRuntimeAppInfo) async -> Bool {
        guard app.isAccessible else {
            runtimeCatalogStatusText = "app/list：\(app.name) 尚未连接，无法在对话中使用"
            return false
        }
        guard app.isEnabled else {
            runtimeCatalogStatusText = "app/list：\(app.name) 已停用，先启用后才能使用"
            return false
        }

        let slug = app.inputSlug.isEmpty ? CodexRuntimeAppInfo.slug(for: app.id) : app.inputSlug
        let nextPrompt = "$\(slug) 请用中文说明你能读取哪些上下文，并给出一个最小可执行请求。"
        prompt = nextPrompt
        route = .thread
        toolPanel = .launcher
        _ = await previewInputMentions(for: nextPrompt)
        runtimeCatalogStatusText = "app/list：已把 \(app.name) 放入输入框"
        return lastMentionInputPreview.contains { $0["path"] == app.mentionPath }
    }

    @discardableResult
    func useRuntimeAppSnapshotPromptInComposer(_ app: CodexRuntimeAppInfo, prompt screenshotPrompt: String) async -> Bool {
        guard app.isAccessible else {
            runtimeCatalogStatusText = "app/list.screenshots：\(app.name) 尚未连接，无法使用快照提示"
            return false
        }
        guard app.isEnabled else {
            runtimeCatalogStatusText = "app/list.screenshots：\(app.name) 已停用，先启用后才能使用快照提示"
            return false
        }
        let trimmedPrompt = screenshotPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            runtimeCatalogStatusText = "app/list.screenshots：\(app.name) 的快照提示为空"
            return false
        }

        let slug = app.inputSlug.isEmpty ? CodexRuntimeAppInfo.slug(for: app.id) : app.inputSlug
        let nextPrompt = "$\(slug) \(trimmedPrompt)"
        prompt = nextPrompt
        route = .thread
        toolPanel = .launcher
        _ = await previewInputMentions(for: nextPrompt)
        runtimeCatalogStatusText = "app/list.screenshots：已把 \(app.name) 快照提示放入输入框"
        return lastMentionInputPreview.contains { $0["path"] == app.mentionPath }
    }

    func refreshNewThreadHeroRuntime() async {
        homeConnectionStatusText = "正在读取新对话连接状态…"

        await refreshWorkspaceBranches()
        await refreshIntegrationRuntime(forceRefetchApps: false)
        await loadFilePanelDirectory(workspacePath)

        homeConnectionsRefreshedAt = Date()
        let errorText = runtimeCatalogErrors.isEmpty ? "" : " · \(runtimeCatalogErrors.count) 个提示"
        homeConnectionStatusText = "app/list \(runtimeApps.count) 个 · MCP \(runtimeMCPServers.count) 个 · 文件 \(workspaceFileConnectionCount) 个\(errorText)"
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
            workspaceWorktreeStatusSource = "command/exec git worktree list"
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
                sandbox: sandbox,
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
                sandbox: sandbox,
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
            Task { await startRemoteControlPairing(manualCode: true) }
        }
    }

    func refreshRemoteControlStatus() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 remoteControl/status/read 读取云端模式…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false, remoteControl: true)
            let status = try await client.readRemoteControlStatus()
            applyRemoteControlStatus(status)
            do {
                try await loadRemoteControlClientsIfAvailable(using: client, environmentID: status.environmentID)
            } catch {
                runtimeCatalogErrors.append("remoteControl/client/list：\(error.localizedDescription)")
            }
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
            applyRemoteControlStatus(status)
            do {
                try await loadRemoteControlClientsIfAvailable(using: client, environmentID: status.environmentID)
            } catch {
                runtimeCatalogErrors.append("remoteControl/client/list：\(error.localizedDescription)")
            }
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
        runtimeRemoteControlPairingClaimed = nil
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 remoteControl/disable 停用云端模式…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false, remoteControl: true)
            let status = try await client.disableRemoteControl()
            applyRemoteControlStatus(status)
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
            let status = try await client.enableRemoteControl()
            applyRemoteControlStatus(status)
            let pairing = try await client.startRemoteControlPairing(manualCode: manualCode)
            runtimeRemoteControlPairing = pairing
            let pairingStatus = try await client.readRemoteControlPairingStatus(pairingCode: pairing.pairingCode)
            runtimeRemoteControlPairingClaimed = pairingStatus.claimed
            do {
                try await loadRemoteControlClientsIfAvailable(using: client, environmentID: pairing.environmentID)
            } catch {
                runtimeCatalogErrors.append("remoteControl/client/list：\(error.localizedDescription)")
            }
            let manualText = pairing.manualPairingCode.map { " · 手动码 \($0)" } ?? ""
            let claimedText = pairingStatus.claimed ? "已领取" : "等待领取"
            runtimeCatalogStatusText = "remoteControl/pairing/start：\(pairing.pairingCode)\(manualText) · \(claimedText)"
        } catch {
            runtimeCatalogStatusText = "remoteControl/pairing/start 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func refreshRemoteControlPairingStatus() async {
        guard let pairing = runtimeRemoteControlPairing else {
            runtimeRemoteControlPairingClaimed = nil
            runtimeCatalogStatusText = "没有可查询的远程控制配对码"
            return
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 remoteControl/pairing/status 检查配对状态…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false, remoteControl: true)
            let status = try await client.readRemoteControlPairingStatus(pairingCode: pairing.pairingCode)
            runtimeRemoteControlPairingClaimed = status.claimed
            runtimeCatalogStatusText = "remoteControl/pairing/status：\(status.claimed ? "已领取" : "等待领取")"
        } catch {
            runtimeCatalogStatusText = "remoteControl/pairing/status 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func refreshRemoteControlClients() async {
        let environmentID = runtimeRemoteControlStatus?.environmentID ?? runtimeRemoteControlPairing?.environmentID
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 remoteControl/client/list 读取授权客户端…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false, remoteControl: true)
            try await loadRemoteControlClientsIfAvailable(using: client, environmentID: environmentID)
            let count = runtimeRemoteControlClients.count
            runtimeCatalogStatusText = environmentID?.isEmpty == false
                ? "remoteControl/client/list：\(count) 个授权客户端"
                : "remoteControl/client/list：当前没有环境 ID"
        } catch {
            runtimeCatalogStatusText = "remoteControl/client/list 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    func revokeRemoteControlClient(_ remoteClient: CodexRemoteControlClient, confirm: Bool = true) async {
        let environmentID = runtimeRemoteControlStatus?.environmentID ?? runtimeRemoteControlPairing?.environmentID
        guard let environmentID, !environmentID.isEmpty else {
            runtimeCatalogStatusText = "remoteControl/client/revoke：当前没有 environmentId"
            return
        }
        guard !remoteClient.clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            runtimeCatalogStatusText = "remoteControl/client/revoke：缺少 clientId"
            return
        }
        guard !confirm || confirmRemoteControlClientRevoke(remoteClient) else {
            return
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在撤销 \(remoteClient.displayName ?? remoteClient.clientID)…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false, remoteControl: true)
            try await client.revokeRemoteControlClient(
                environmentID: environmentID,
                clientID: remoteClient.clientID
            )
            try await loadRemoteControlClientsIfAvailable(using: client, environmentID: environmentID)
            runtimeCatalogStatusText = "remoteControl/client/revoke：已撤销 \(remoteClient.displayName ?? remoteClient.clientID)"
        } catch {
            runtimeCatalogStatusText = "remoteControl/client/revoke 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    private func applyRemoteControlStatus(_ status: CodexRuntimeRemoteControlStatus) {
        runtimeRemoteControlStatus = status
        workspaceExecutionMode = status.status == "disabled" ? .local : .cloudPending
        if status.status == "disabled" {
            runtimeRemoteControlPairing = nil
            runtimeRemoteControlPairingClaimed = nil
            runtimeRemoteControlClients = []
            runtimeRemoteControlClientsNextCursor = nil
        }
    }

    private func loadRemoteControlClientsIfAvailable(
        using client: CodexAppServerClient,
        environmentID: String?
    ) async throws {
        guard let environmentID, !environmentID.isEmpty else {
            runtimeRemoteControlClients = []
            runtimeRemoteControlClientsNextCursor = nil
            return
        }

        let catalog = try await client.listRemoteControlClients(environmentID: environmentID)
        runtimeRemoteControlClients = catalog.clients
        runtimeRemoteControlClientsNextCursor = catalog.nextCursor
    }

    private func confirmRemoteControlClientRevoke(_ client: CodexRemoteControlClient) -> Bool {
        let alert = NSAlert()
        alert.messageText = "撤销授权客户端？"
        alert.informativeText = "将通过 Codex app-server 调用 remoteControl/client/revoke，撤销 \(client.displayName ?? client.clientID)。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "撤销")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }

    func togglePluginInstallation(_ plugin: CodexRuntimePlugin) async {
        runtimeCatalogStatusText = plugin.installed ? "正在卸载 \(plugin.displayName)…" : "正在安装 \(plugin.displayName)…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let finalStatus: String
            if plugin.installed {
                try await client.uninstallPlugin(plugin)
                runtimePluginInstallResult = nil
                finalStatus = "plugin/uninstall：已卸载 \(plugin.displayName)"
            } else {
                let result = try await client.installPlugin(plugin)
                runtimePluginInstallResult = result
                finalStatus = Self.pluginInstallSummary(pluginDisplayName: plugin.displayName, result: result)
            }
            await refreshRuntimeCatalog(forceReloadSkills: true)
            if runtimePluginDetail?.plugin.id == plugin.id,
               let refreshed = runtimePlugins.first(where: { $0.id == plugin.id }) {
                await readRuntimePluginDetail(refreshed)
            }
            runtimeCatalogStatusText = finalStatus
            runtimePluginDetailStatusText = finalStatus
        } catch {
            runtimeCatalogStatusText = "插件操作失败：\(error.localizedDescription)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    nonisolated static func pluginAuthPolicyDisplayName(_ policy: String) -> String {
        switch policy.uppercased() {
        case "ON_INSTALL":
            "安装时授权"
        case "ON_USE":
            "使用时授权"
        default:
            policy.isEmpty ? "未知授权" : policy
        }
    }

    nonisolated static func pluginInstallSummary(pluginDisplayName: String, result: CodexRuntimePluginInstallResult) -> String {
        let auth = pluginAuthPolicyDisplayName(result.authPolicy)
        guard !result.appsNeedingAuth.isEmpty else {
            return "plugin/install：已安装 \(pluginDisplayName) · \(auth) · 没有需要额外授权的 app"
        }
        let appNames = result.appsNeedingAuth.map(\.name).prefix(3).joined(separator: "、")
        let extra = result.appsNeedingAuth.count > 3 ? " 等" : ""
        return "plugin/install：已安装 \(pluginDisplayName) · \(auth) · 需要授权 \(result.appsNeedingAuth.count) 个 app\(extra)：\(appNames)"
    }

    func promptAddPluginMarketplace() {
        let alert = NSAlert()
        alert.messageText = "添加插件市场源"
        alert.informativeText = "输入 Git 仓库来源。Codex app-server 会通过 marketplace/add 安装到当前 CODEX_HOME。"
        alert.addButton(withTitle: "添加")
        alert.addButton(withTitle: "取消")

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8

        let sourceField = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        sourceField.placeholderString = "owner/repo 或 https://github.com/owner/repo"
        let refField = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        refField.placeholderString = "可选：分支、标签或提交"
        let sparseField = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        sparseField.placeholderString = "可选：稀疏路径，用逗号分隔"

        stack.addArrangedSubview(NSTextField(labelWithString: "来源"))
        stack.addArrangedSubview(sourceField)
        stack.addArrangedSubview(NSTextField(labelWithString: "版本引用"))
        stack.addArrangedSubview(refField)
        stack.addArrangedSubview(NSTextField(labelWithString: "稀疏路径"))
        stack.addArrangedSubview(sparseField)
        alert.accessoryView = stack

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let source = sourceField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            runtimeCatalogStatusText = "marketplace/add：缺少 source"
            return
        }
        let refName = refField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let sparsePaths = Self.marketplaceSparsePaths(from: sparseField.stringValue)
        Task {
            await addPluginMarketplace(
                source: source,
                refName: refName.isEmpty ? nil : refName,
                sparsePaths: sparsePaths.isEmpty ? nil : sparsePaths
            )
        }
    }

    func promptRemovePluginMarketplace() {
        let alert = NSAlert()
        alert.messageText = "移除插件市场源"
        alert.informativeText = "输入 marketplace 名称。Codex app-server 会通过 marketplace/remove 从当前 CODEX_HOME 移除。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "移除")
        alert.addButton(withTitle: "取消")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.placeholderString = "市场源名称"
        alert.accessoryView = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            runtimeCatalogStatusText = "marketplace/remove：缺少 marketplaceName"
            return
        }
        Task { await removePluginMarketplace(name: name) }
    }

    @discardableResult
    func addPluginMarketplace(
        source: String,
        refName: String? = nil,
        sparsePaths: [String]? = nil
    ) async -> CodexMarketplaceAddResult? {
        let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSource.isEmpty else {
            runtimeCatalogStatusText = "marketplace/add：缺少 source"
            return nil
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 marketplace/add 添加插件市场源…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.addPluginMarketplace(
                source: trimmedSource,
                refName: refName,
                sparsePaths: sparsePaths
            )
            await refreshRuntimeCatalog(forceReloadSkills: true)
            let finalStatus = Self.marketplaceAddSummary(result)
            runtimeCatalogStatusText = finalStatus
            runtimePluginDetailStatusText = finalStatus
            runtimeCatalogIsRefreshing = false
            return result
        } catch {
            runtimeCatalogStatusText = "marketplace/add 失败：\(error.localizedDescription)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            return nil
        }
    }

    @discardableResult
    func removePluginMarketplace(name: String) async -> CodexMarketplaceRemoveResult? {
        let marketplaceName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !marketplaceName.isEmpty else {
            runtimeCatalogStatusText = "marketplace/remove：缺少 marketplaceName"
            return nil
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 marketplace/remove 移除插件市场源…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.removePluginMarketplace(name: marketplaceName)
            runtimePluginDetail = nil
            await refreshRuntimeCatalog(forceReloadSkills: true)
            let finalStatus = Self.marketplaceRemoveSummary(result)
            runtimeCatalogStatusText = finalStatus
            runtimePluginDetailStatusText = finalStatus
            runtimeCatalogIsRefreshing = false
            return result
        } catch {
            runtimeCatalogStatusText = "marketplace/remove 失败：\(error.localizedDescription)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            return nil
        }
    }

    @discardableResult
    func upgradePluginMarketplaces(marketplaceName: String? = nil) async -> CodexMarketplaceUpgradeResult? {
        let trimmedName = marketplaceName?.trimmingCharacters(in: .whitespacesAndNewlines)
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 marketplace/upgrade 升级插件市场源…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.upgradePluginMarketplaces(marketplaceName: trimmedName?.isEmpty == false ? trimmedName : nil)
            await refreshRuntimeCatalog(forceReloadSkills: true)
            let finalStatus = Self.marketplaceUpgradeSummary(result, target: trimmedName)
            runtimeCatalogStatusText = finalStatus
            runtimePluginDetailStatusText = finalStatus
            runtimeCatalogErrors = result.errors.map { "\($0.marketplaceName)：\($0.message)" }
            runtimeCatalogIsRefreshing = false
            return result
        } catch {
            runtimeCatalogStatusText = "marketplace/upgrade 失败：\(error.localizedDescription)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            return nil
        }
    }

    nonisolated static func marketplaceAddSummary(_ result: CodexMarketplaceAddResult) -> String {
        let action = result.alreadyAdded ? "已存在" : "已添加"
        return "marketplace/add：\(action) \(result.marketplaceName) · \(Project.abbreviate(result.installedRoot))"
    }

    nonisolated static func marketplaceRemoveSummary(_ result: CodexMarketplaceRemoveResult) -> String {
        guard let installedRoot = result.installedRoot, !installedRoot.isEmpty else {
            return "marketplace/remove：已移除 \(result.marketplaceName)"
        }
        return "marketplace/remove：已移除 \(result.marketplaceName) · \(Project.abbreviate(installedRoot))"
    }

    nonisolated static func marketplaceUpgradeSummary(
        _ result: CodexMarketplaceUpgradeResult,
        target: String? = nil
    ) -> String {
        let targetName = target?.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetText = targetName?.isEmpty == false ? targetName! : "全部插件市场源"
        let selectedText = result.selectedMarketplaces.isEmpty ? "0 个源" : "\(result.selectedMarketplaces.count) 个源"
        let errorText = result.errors.isEmpty ? "无错误" : "\(result.errors.count) 个错误"
        return "marketplace/upgrade：\(targetText) · 选择 \(selectedText) · 更新 \(result.upgradedRoots.count) 个目录 · \(errorText)"
    }

    nonisolated private static func marketplaceSparsePaths(from text: String) -> [String] {
        text.components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func checkoutSharedPlugin(_ plugin: CodexRuntimePlugin) async {
        guard let remotePluginID = plugin.shareContext?.remotePluginID else {
            runtimeCatalogStatusText = "plugin/share/checkout：缺少 remotePluginId"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            return
        }

        runtimeCatalogStatusText = "正在检出共享插件 \(plugin.displayName)…"
        runtimePluginDetailStatusText = runtimeCatalogStatusText
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.checkoutSharedPlugin(remotePluginID: remotePluginID)
            await refreshRuntimeCatalog(forceReloadSkills: true)
            if let refreshed = runtimePlugins.first(where: {
                $0.shareContext?.remotePluginID == remotePluginID ||
                    $0.id == result.pluginID ||
                    $0.name == result.pluginName
            }) {
                await readRuntimePluginDetail(refreshed)
            }
            runtimeCatalogStatusText = "plugin/share/checkout：已检出 \(result.pluginName) 到 \(Project.abbreviate(result.pluginPath))"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
        } catch {
            runtimeCatalogStatusText = "plugin/share/checkout 失败：\(error.localizedDescription)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func deleteSharedPlugin(_ plugin: CodexRuntimePlugin) async {
        guard let remotePluginID = plugin.shareContext?.remotePluginID else {
            runtimeCatalogStatusText = "plugin/share/delete：缺少 remotePluginId"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            return
        }

        guard confirmDeleteSharedPlugin(plugin, remotePluginID: remotePluginID) else {
            runtimeCatalogStatusText = "plugin/share/delete：已取消"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            return
        }

        runtimeCatalogStatusText = "正在删除共享插件 \(plugin.displayName)…"
        runtimePluginDetailStatusText = runtimeCatalogStatusText
        runtimeCatalogErrors = []
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.deleteSharedPlugin(remotePluginID: remotePluginID)
            runtimePluginDetail = nil
            await refreshRuntimeCatalog(forceReloadSkills: true)
            runtimeCatalogStatusText = "plugin/share/delete：已删除 \(remotePluginID)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
        } catch {
            runtimeCatalogStatusText = "plugin/share/delete 失败：\(error.localizedDescription)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func openPluginShareURL(_ plugin: CodexRuntimePlugin) {
        guard let shareURL = plugin.shareContext?.shareURL,
              let url = URL(string: shareURL) else {
            runtimePluginDetailStatusText = "共享链接不可用"
            runtimeCatalogStatusText = runtimePluginDetailStatusText
            return
        }
        NSWorkspace.shared.open(url)
        runtimePluginDetailStatusText = "已打开共享链接"
        runtimeCatalogStatusText = runtimePluginDetailStatusText
    }

    func saveSharedPlugin(_ plugin: CodexRuntimePlugin, discoverability: String? = nil) async {
        guard let pluginPath = plugin.localPluginPath, !pluginPath.isEmpty else {
            runtimeCatalogStatusText = "plugin/share/save：\(plugin.displayName) 没有本地插件路径"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            return
        }

        let existingRemotePluginID = plugin.shareContext?.remotePluginID
        let createDiscoverability = existingRemotePluginID == nil ? (discoverability ?? "UNLISTED") : nil
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = existingRemotePluginID == nil
            ? "正在创建共享插件 \(plugin.displayName)…"
            : "正在保存共享插件 \(plugin.displayName)…"
        runtimePluginDetailStatusText = runtimeCatalogStatusText
        runtimeCatalogErrors = []
        defer { runtimeCatalogIsRefreshing = false }

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.saveSharedPlugin(
                pluginPath: pluginPath,
                remotePluginID: existingRemotePluginID,
                discoverability: createDiscoverability,
                shareTargets: createDiscoverability == nil ? nil : []
            )
            let context = Self.updatedShareContext(
                existing: plugin.shareContext,
                remotePluginID: result.remotePluginID,
                discoverability: createDiscoverability,
                shareURL: result.shareURL.isEmpty ? plugin.shareContext?.shareURL : result.shareURL,
                principals: plugin.shareContext?.sharePrincipals
            )
            applyShareContext(context, toPluginID: plugin.id, pluginName: plugin.name)
            let urlText = result.shareURL.isEmpty ? "未返回链接" : result.shareURL
            runtimeCatalogStatusText = "plugin/share/save：\(result.remotePluginID) · \(urlText)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
        } catch {
            runtimeCatalogStatusText = "plugin/share/save 失败：\(error.localizedDescription)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func updateSharedPluginDiscoverability(_ plugin: CodexRuntimePlugin, discoverability: String) async {
        guard let remotePluginID = plugin.shareContext?.remotePluginID, !remotePluginID.isEmpty else {
            runtimeCatalogStatusText = "plugin/share/updateTargets：缺少 remotePluginId"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            return
        }

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在更新共享权限 \(plugin.displayName)…"
        runtimePluginDetailStatusText = runtimeCatalogStatusText
        runtimeCatalogErrors = []
        defer { runtimeCatalogIsRefreshing = false }

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.updateSharedPluginTargets(
                remotePluginID: remotePluginID,
                discoverability: discoverability,
                shareTargets: []
            )
            let context = Self.updatedShareContext(
                existing: plugin.shareContext,
                remotePluginID: remotePluginID,
                discoverability: result.discoverability.isEmpty ? discoverability : result.discoverability,
                shareURL: plugin.shareContext?.shareURL,
                principals: result.principals
            )
            applyShareContext(context, toPluginID: plugin.id, pluginName: plugin.name)
            runtimeCatalogStatusText = "plugin/share/updateTargets：\(remotePluginID) · \(context.discoverability ?? discoverability)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
        } catch {
            runtimeCatalogStatusText = "plugin/share/updateTargets 失败：\(error.localizedDescription)"
            runtimePluginDetailStatusText = runtimeCatalogStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    nonisolated private static func updatedShareContext(
        existing: CodexRuntimePluginShareContext?,
        remotePluginID: String,
        discoverability: String?,
        shareURL: String?,
        principals: [CodexRuntimePluginSharePrincipal]?
    ) -> CodexRuntimePluginShareContext {
        CodexRuntimePluginShareContext(
            remotePluginID: remotePluginID,
            remoteVersion: existing?.remoteVersion,
            discoverability: discoverability ?? existing?.discoverability,
            shareURL: shareURL ?? existing?.shareURL,
            creatorAccountUserID: existing?.creatorAccountUserID,
            creatorName: existing?.creatorName,
            sharePrincipals: principals ?? existing?.sharePrincipals ?? []
        )
    }

    private func applyShareContext(_ context: CodexRuntimePluginShareContext, toPluginID pluginID: String, pluginName: String) {
        for index in runtimePlugins.indices where runtimePlugins[index].id == pluginID || runtimePlugins[index].name == pluginName {
            runtimePlugins[index].shareContext = context
        }
        if runtimePluginDetail?.plugin.id == pluginID || runtimePluginDetail?.plugin.name == pluginName {
            runtimePluginDetail?.plugin.shareContext = context
        }
    }

    @discardableResult
    func openPluginInstallAuthURL(_ app: CodexRuntimePluginApp, openExternal: Bool = true) -> Bool {
        guard let installURL = app.installURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !installURL.isEmpty,
              let url = URL(string: installURL) else {
            runtimePluginDetailStatusText = "plugin/install：\(app.name) 没有返回授权链接"
            runtimeCatalogStatusText = runtimePluginDetailStatusText
            return false
        }

        lastOpenedRuntimeAppInstallURL = installURL
        runtimePluginDetailStatusText = "plugin/install：打开 \(app.name) 授权链接"
        runtimeCatalogStatusText = runtimePluginDetailStatusText
        if openExternal {
            NSWorkspace.shared.open(url)
        }
        return true
    }

    private func confirmDeleteSharedPlugin(_ plugin: CodexRuntimePlugin, remotePluginID: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = "删除共享插件？"
        alert.informativeText = "将通过 app-server 删除 \(plugin.displayName) 的远端分享 \(remotePluginID)。如果当前账号没有权限，Codex 会返回真实失败原因。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }

    @discardableResult
    func createLocalPluginTemplate() async -> CodexRuntimeScaffoldResult? {
        let pluginName = "raytone-local-plugin"
        let skillName = "raytone-project-helper"
        let marketplaceName = "raytone-local"
        let workspaceURL = URL(fileURLWithPath: workspacePath, isDirectory: true)
        let agentsDirectory = workspaceURL.appendingPathComponent(".agents/plugins", isDirectory: true)
        let marketplaceURL = agentsDirectory.appendingPathComponent("marketplace.json")
        let pluginRoot = workspaceURL.appendingPathComponent("plugins/\(pluginName)", isDirectory: true)
        let manifestURL = pluginRoot.appendingPathComponent(".codex-plugin/plugin.json")
        let skillURL = pluginRoot.appendingPathComponent("skills/\(skillName)/SKILL.md")

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 app-server 创建本地插件模板…"
        runtimeCatalogErrors = []
        defer { runtimeCatalogIsRefreshing = false }

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(keyPath: "features.plugins", value: .bool(true))
            try await client.createDirectory(path: agentsDirectory.path)
            try await client.createDirectory(path: manifestURL.deletingLastPathComponent().path)
            try await client.createDirectory(path: skillURL.deletingLastPathComponent().path)

            let (existingMarketplaceData, marketplaceSource) = try await Self.optionalAppServerFileData(
                client: client,
                path: marketplaceURL.path
            )
            let marketplaceData = try Self.marketplaceTemplateData(
                existingData: existingMarketplaceData,
                marketplaceName: marketplaceName,
                pluginName: pluginName,
                pluginRelativePath: "./plugins/\(pluginName)"
            )
            let manifestData = try Self.jsonData([
                "name": pluginName,
                "description": "RaytoneCodex 创建的本机插件模板",
                "keywords": ["raytone", "local", "codex"],
                "interface": [
                    "displayName": "Raytone 本地插件",
                    "shortDescription": "项目级插件模板",
                    "longDescription": "这是 RaytoneCodex 通过 Codex app-server 写入的本地插件模板，可继续添加技能、MCP、钩子和 app。",
                    "developerName": "Raytone",
                    "category": "Productivity",
                    "capabilities": ["Interactive"]
                ]
            ])
            let skillData = Self.utf8Data("""
            ---
            name: \(skillName)
            description: 为当前项目准备 RaytoneCodex 本地插件工作流
            ---

            # Raytone Project Helper

            当用户在当前项目中提到本地插件、项目规范或最小可运行示例时，先读取仓库上下文，再给出中文、可执行、带证据路径的建议。
            """)

            try await client.writeFile(path: marketplaceURL.path, data: marketplaceData)
            try await client.writeFile(path: manifestURL.path, data: manifestData)
            try await client.writeFile(path: skillURL.path, data: skillData)

            let readBacks = try await Self.readBackSnippets(
                client: client,
                paths: [marketplaceURL.path, manifestURL.path, skillURL.path]
            )
            await refreshRuntimeCatalog(forceReloadSkills: true)
            let discoveredPlugin = runtimePlugins.first {
                $0.name == pluginName && $0.marketplaceName == marketplaceName
            }
            let discoveredSkill = runtimeSkills.first {
                $0.path == skillURL.path || $0.name == "\(pluginName):\(skillName)" || $0.name == skillName
            }
            let result = CodexRuntimeScaffoldResult(
                kind: "plugin",
                rootPath: pluginRoot.path,
                files: [marketplaceURL.path, manifestURL.path, skillURL.path],
                readBackSnippets: readBacks,
                discoveredPluginID: discoveredPlugin?.id,
                discoveredSkillPath: discoveredSkill?.path,
                source: "\(marketplaceSource) + fs/writeFile + fs/readFile + plugin/list + skills/list"
            )
            let loadedText = discoveredPlugin == nil ? "已写入，等待 plugin/list 加载" : "plugin/list 已发现 \(discoveredPlugin?.displayName ?? pluginName)"
            runtimeCatalogStatusText = "\(result.source)：已创建 \(pluginName) · \(loadedText)"
            return result
        } catch {
            runtimeCatalogStatusText = "创建本地插件失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            return nil
        }
    }

    @discardableResult
    func createLocalSkillTemplate() async -> CodexRuntimeScaffoldResult? {
        let skillName = "raytone-local-skill"
        let codexHomeURL = Self.defaultCodexConfigURL(
            overrideCodexHome: appServerEnvironmentOverridesForTesting["CODEX_HOME"]
        )
        .deletingLastPathComponent()
        let skillRoot = codexHomeURL.appendingPathComponent("skills/\(skillName)", isDirectory: true)
        let skillURL = skillRoot.appendingPathComponent("SKILL.md")

        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在通过 app-server 创建本地技能模板…"
        runtimeCatalogErrors = []
        defer { runtimeCatalogIsRefreshing = false }

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.createDirectory(path: skillRoot.path)
            let skillData = Self.utf8Data("""
            ---
            name: \(skillName)
            description: RaytoneCodex 本机技能模板
            ---

            # Raytone Local Skill

            当用户明确调用这个技能时，用中文给出当前仓库内可验证的最小下一步，并列出真实文件或运行结果作为证据。
            """)
            try await client.writeFile(path: skillURL.path, data: skillData)

            let readBacks = try await Self.readBackSnippets(client: client, paths: [skillURL.path])
            await refreshRuntimeCatalog(forceReloadSkills: true)
            let discoveredSkill = runtimeSkills.first { skill in
                skill.path == skillURL.path || skill.name == skillName
            }
            let result = CodexRuntimeScaffoldResult(
                kind: "skill",
                rootPath: skillRoot.path,
                files: [skillURL.path],
                readBackSnippets: readBacks,
                discoveredPluginID: nil,
                discoveredSkillPath: discoveredSkill?.path,
                source: "fs/createDirectory + fs/writeFile + fs/readFile + skills/list"
            )
            let loadedText = discoveredSkill == nil ? "已写入，等待 skills/list 加载" : "skills/list 已发现 \(discoveredSkill?.displayName ?? skillName)"
            runtimeCatalogStatusText = "\(result.source)：已创建 \(skillName) · \(loadedText)"
            return result
        } catch {
            runtimeCatalogStatusText = "创建本地技能失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            return nil
        }
    }

    func promptAddRuntimeSkillExtraRoot() {
        let panel = NSOpenPanel()
        panel.title = "选择运行时技能根目录"
        panel.message = "选择包含技能子目录的 skills 根目录。RaytoneCodex 会通过 skills/extraRoots/set 挂载到当前 Codex app-server 进程。"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: workspacePath)

        if panel.runModal() == .OK {
            let selectedPaths = panel.urls.map(\.path)
            Task { await addRuntimeSkillExtraRoots(selectedPaths) }
        }
    }

    @discardableResult
    func addRuntimeSkillExtraRoots(_ paths: [String]) async -> Bool {
        await setRuntimeSkillExtraRoots(paths: runtimeSkillExtraRoots + paths)
    }

    @discardableResult
    func setRuntimeSkillExtraRoots(paths: [String]) async -> Bool {
        let roots = Self.uniqueCanonicalPaths(paths)
        if roots.isEmpty && isRunning {
            runtimeCatalogStatusText = "当前有运行中的轮次，暂不能清除运行时技能根"
            return false
        }
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在调用 skills/extraRoots/set…"
        runtimeCatalogErrors = []
        defer { runtimeCatalogIsRefreshing = false }

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.setSkillExtraRoots(roots)
            runtimeSkillExtraRoots = roots

            let listClient: CodexAppServerClient
            if roots.isEmpty {
                await stopAppServerConnectionForRuntimeSkillRootChange()
                listClient = try await ensureAppServerClient(useProviderConfiguration: false)
            } else {
                listClient = client
            }

            let catalog = try await listClient.listSkills(cwds: [workspacePath], forceReload: true)
            runtimeSkills = catalog.skills
            runtimeCatalogErrors = catalog.errors
            let rootText = roots.isEmpty ? "已清除" : "\(roots.count) 个根"
            runtimeCatalogStatusText = "skills/extraRoots/set：\(rootText) · skills/list \(runtimeSkills.count) 个技能"
            return true
        } catch {
            runtimeCatalogStatusText = "skills/extraRoots/set 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            return false
        }
    }

    private func stopAppServerConnectionForRuntimeSkillRootChange() async {
        if let client = appServerClient {
            await client.stop()
        }
        appServerClient = nil
        appServerEventsTask?.cancel()
        appServerEventsTask = nil
        appServerEnvironmentKey = nil
        appServerItemIDs.removeAll()
        resetFilePanelWatch()
    }

    func readRuntimePluginDetail(_ plugin: CodexRuntimePlugin) async {
        runtimeCatalogIsRefreshing = true
        runtimePluginDetailStatusText = "正在读取 \(plugin.displayName)…"
        clearRuntimePluginSkillPreview()
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

    @discardableResult
    func readRuntimePluginSkillPreview(_ skill: CodexRuntimePluginSkill) async -> Bool {
        runtimePluginSkillPreview = skill
        runtimePluginSkillPreviewText = ""
        runtimeCatalogErrors = []

        if let path = skill.path, !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            runtimePluginSkillPreviewStatusText = "正在通过 fs/readFile 读取 \(skill.displayName)…"
            runtimeCatalogStatusText = runtimePluginSkillPreviewStatusText

            do {
                let client = try await ensureAppServerClient(useProviderConfiguration: false)
                let data = try await client.readFile(path: path)
                let text = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
                runtimePluginSkillPreviewText = text
                runtimePluginSkillPreviewStatusText = "plugin/read + fs/readFile：\(skill.displayName) · \(data.count) 字节"
                runtimeCatalogStatusText = runtimePluginSkillPreviewStatusText
                return true
            } catch {
                runtimePluginSkillPreviewStatusText = "插件技能读取失败：\(error.localizedDescription)"
                runtimeCatalogStatusText = runtimePluginSkillPreviewStatusText
                runtimeCatalogErrors = [error.localizedDescription]
                return false
            }
        }

        guard let plugin = runtimePluginDetail?.plugin,
              let remotePluginID = plugin.remotePluginID ?? plugin.shareContext?.remotePluginID,
              !remotePluginID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            runtimePluginSkillPreviewStatusText = "plugin/read 没有返回 \(skill.displayName) 的本地 path 或 remotePluginId"
            runtimeCatalogStatusText = runtimePluginSkillPreviewStatusText
            return false
        }

        runtimePluginSkillPreviewStatusText = "正在通过 plugin/skill/read 读取 \(skill.displayName)…"
        runtimeCatalogStatusText = runtimePluginSkillPreviewStatusText

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let result = try await client.readRemotePluginSkill(
                remoteMarketplaceName: plugin.marketplaceName,
                remotePluginID: remotePluginID,
                skillName: skill.name
            )
            let text = result.contents ?? ""
            runtimePluginSkillPreviewText = text
            runtimePluginSkillPreviewStatusText = result.contents == nil
                ? "plugin/skill/read：\(skill.displayName) · 未返回正文"
                : "plugin/skill/read：\(skill.displayName) · \(text.utf8.count) 字节"
            runtimeCatalogStatusText = runtimePluginSkillPreviewStatusText
            return result.contents != nil
        } catch {
            runtimePluginSkillPreviewStatusText = "插件技能读取失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimePluginSkillPreviewStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            return false
        }
    }

    func clearRuntimePluginSkillPreview() {
        runtimePluginSkillPreview = nil
        runtimePluginSkillPreviewText = ""
        runtimePluginSkillPreviewStatusText = "未读取"
    }

    func toggleSkill(_ skill: CodexRuntimeSkill) async {
        let targetEnabled = !skill.enabled
        let actionText = targetEnabled ? "启用" : "停用"
        let completedText = targetEnabled ? "已启用" : "已停用"
        runtimeCatalogStatusText = "正在\(actionText) \(skill.displayName)…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.setSkillEnabled(skill, enabled: targetEnabled)
            await refreshRuntimeCatalog(forceReloadSkills: true)
            let updatedSkill = runtimeSkills.first {
                $0.name == skill.name &&
                    Self.canonicalPath($0.path) == Self.canonicalPath(skill.path)
            }
            if updatedSkill?.enabled == targetEnabled {
                runtimeCatalogStatusText = "skills/config/write + skills/list：\(skill.displayName) \(completedText)"
            } else if let updatedSkill {
                let observedText = updatedSkill.enabled ? "启用" : "停用"
                runtimeCatalogStatusText = "skills/config/write：已提交；skills/list 仍显示\(observedText)"
            } else {
                runtimeCatalogStatusText = "skills/config/write：已提交；skills/list 未找到 \(skill.displayName)"
            }
        } catch {
            runtimeCatalogStatusText = "技能操作失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    @discardableResult
    func readRuntimeSkillPreview(_ skill: CodexRuntimeSkill) async -> Bool {
        runtimeSkillPreview = skill
        runtimeSkillPreviewText = ""
        runtimeSkillPreviewStatusText = "正在通过 fs/readFile 读取 \(skill.displayName)…"
        runtimeCatalogStatusText = runtimeSkillPreviewStatusText
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let data = try await client.readFile(path: skill.path)
            let text = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
            runtimeSkillPreviewText = text
            runtimeSkillPreviewStatusText = "fs/readFile：\(skill.displayName) · \(data.count) 字节"
            runtimeCatalogStatusText = runtimeSkillPreviewStatusText
            return true
        } catch {
            runtimeSkillPreviewStatusText = "技能内容读取失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = runtimeSkillPreviewStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            return false
        }
    }

    func clearRuntimeSkillPreview() {
        runtimeSkillPreview = nil
        runtimeSkillPreviewText = ""
        runtimeSkillPreviewStatusText = "未读取"
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
            let configURL = try await ensureCodexConfigFile(using: client)
            let existingConfigData = try await client.readFile(path: configURL.path)
            let existingConfig = String(data: existingConfigData, encoding: .utf8) ?? ""
            let updatedConfig = Self.installRaytoneAutomationHookBlock(
                into: existingConfig,
                title: title,
                command: command
            )
            try await client.writeFile(path: configURL.path, data: Self.utf8Data(updatedConfig))
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
            runtimeCatalogStatusText = "fs/createDirectory + fs/getMetadata + fs/writeFile + hooks/list：已安装 \(title)，返回 \(runtimeHooks.count) 个钩子\(trustSuffix)"
            if !templatePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                prompt = templatePrompt
            }
        } catch {
            runtimeCatalogStatusText = "自动化安装失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
        }
    }

    func raytoneAutomationHooks() -> [CodexRuntimeHook] {
        runtimeHooks.filter(Self.isRaytoneAutomationHook)
    }

    func isRaytoneManagedAutomationHook(_ hook: CodexRuntimeHook) -> Bool {
        Self.isRaytoneAutomationHook(hook)
    }

    func refreshAutomationEventLog() async {
        automationEventLogStatusText = "正在读取事件日志…"
        let eventURL = raytoneAutomationEventLogURL()

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let metadata = try await client.getMetadata(path: eventURL.path)
            guard metadata.isFile else {
                automationEventLogText = ""
                automationEventLogStatusText = metadata.isDirectory
                    ? "事件日志路径是目录：\(Project.abbreviate(eventURL.path))"
                    : "事件日志不是可读取文件：\(Project.abbreviate(eventURL.path))"
                return
            }
            let data = try await client.readFile(path: eventURL.path)
            automationEventLogText = String(data: data, encoding: .utf8) ?? ""
            automationEventLogStatusText = automationEventLogText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "fs/getMetadata + fs/readFile：事件日志为空 · \(Project.abbreviate(eventURL.path))"
                : "fs/getMetadata + fs/readFile：已读取 \(automationEventLogLineCount) 条事件"
        } catch {
            automationEventLogText = ""
            automationEventLogStatusText = "fs/getMetadata 或 fs/readFile 未读取到事件：\(Project.abbreviate(eventURL.path)) · \(error.localizedDescription)"
        }
    }

    func removeRaytoneAutomationHookTemplate() async {
        runtimeCatalogIsRefreshing = true
        runtimeCatalogStatusText = "正在移除 Raytone 自动化 hook…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let configURL = try await ensureCodexConfigFile(using: client)
            let existingConfigData = try await client.readFile(path: configURL.path)
            let existingConfig = String(data: existingConfigData, encoding: .utf8) ?? ""
            let updatedConfig = Self.removeRaytoneAutomationHookBlock(from: existingConfig)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard updatedConfig != existingConfig.trimmingCharacters(in: .whitespacesAndNewlines) else {
                await refreshRuntimeHooks()
                runtimeCatalogStatusText = "没有 Raytone 自动化 hook 可移除"
                return
            }

            try await client.writeFile(path: configURL.path, data: Self.utf8Data(updatedConfig + "\n"))
            await refreshRuntimeHooks()
            runtimeCatalogStatusText = "fs/createDirectory + fs/getMetadata + fs/writeFile + hooks/list：已移除 Raytone 自动化 hook，返回 \(runtimeHooks.count) 个钩子"
        } catch {
            runtimeCatalogStatusText = "移除自动化 hook 失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }

        runtimeCatalogIsRefreshing = false
    }

    var automationEventLogLineCount: Int {
        automationEventLogText
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
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

    func saveGitWritingInstructions(commit: String, pullRequest: String) async {
        let trimmedCommit = commit.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPullRequest = pullRequest.trimmingCharacters(in: .whitespacesAndNewlines)
        desktopCommitInstructions = trimmedCommit
        desktopPullRequestInstructions = trimmedPullRequest
        runtimeCatalogStatusText = "正在写入提交/PR 指令…"
        runtimeCatalogErrors = []

        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.batchWriteConfig(edits: [
                CodexConfigWriteEdit(
                    keyPath: "desktop.raytone.commit_instructions",
                    value: .string(trimmedCommit)
                ),
                CodexConfigWriteEdit(
                    keyPath: "desktop.raytone.pull_request_instructions",
                    value: .string(trimmedPullRequest)
                )
            ])
            if let config = try? await client.readConfig(cwd: workspacePath, includeLayers: true) {
                applyRuntimeConfig(config)
            }
            runtimeCatalogStatusText = "config/batchWrite：提交/PR 指令已保存"
        } catch {
            runtimeCatalogStatusText = "提交/PR 指令保存失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    private func ensureCodexConfigFile(using client: CodexAppServerClient) async throws -> URL {
        let configURL = Self.defaultCodexConfigURL(
            overrideCodexHome: appServerEnvironmentOverridesForTesting["CODEX_HOME"]
        )
        try await client.createDirectory(path: configURL.deletingLastPathComponent().path)
        let existingMetadata = try? await client.getMetadata(path: configURL.path)
        if let metadata = existingMetadata {
            guard metadata.isFile else {
                throw CodexAppServerError.invalidResponse("Codex config path is not a file: \(configURL.path)")
            }
            return configURL
        }

        try await client.writeFile(path: configURL.path, data: Data())
        let metadata = try await client.getMetadata(path: configURL.path)
        guard metadata.isFile else {
            throw CodexAppServerError.invalidResponse("Codex config path was not created as a file: \(configURL.path)")
        }
        return configURL
    }

    @discardableResult
    func prepareCodexConfigFileForOpening() async -> URL? {
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            let configURL = try await ensureCodexConfigFile(using: client)
            runtimeCatalogStatusText = "fs/createDirectory + fs/getMetadata (+ fs/writeFile if missing)：已准备 config.toml · \(Project.abbreviate(configURL.path))"
            return configURL
        } catch {
            runtimeCatalogStatusText = "打开 config.toml 前准备失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            return nil
        }
    }

    func openCodexConfigFile() async {
        guard let configURL = await prepareCodexConfigFileForOpening() else {
            return
        }
        NSWorkspace.shared.open(configURL)
    }

    func revealCodexHomeSubfolder(_ subfolder: String) async {
        guard let url = await ensureCodexHomeSubfolder(subfolder) else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        let label = Self.codexHomeSubfolderLabel(subfolder)
        runtimeCatalogStatusText = "fs/createDirectory + fs/getMetadata + Finder：已打开 Codex \(label) 目录 · \(Project.abbreviate(url.path))"
    }

    @discardableResult
    func ensureCodexHomeSubfolder(_ subfolder: String) async -> URL? {
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            return try await ensureCodexHomeSubfolder(subfolder, using: client)
        } catch {
            runtimeCatalogStatusText = "Codex 目录准备失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
            return nil
        }
    }

    private func ensureCodexHomeSubfolder(_ subfolder: String, using client: CodexAppServerClient) async throws -> URL {
        let url = Self.codexHomeSubfolderURL(
            subfolder,
            overrideCodexHome: appServerEnvironmentOverridesForTesting["CODEX_HOME"]
        )
        try await client.createDirectory(path: url.path)
        let metadata = try await client.getMetadata(path: url.path)
        guard metadata.isDirectory else {
            throw CodexAppServerError.invalidResponse("Codex directory path is not a directory: \(url.path)")
        }
        let label = Self.codexHomeSubfolderLabel(subfolder)
        runtimeCatalogStatusText = "fs/createDirectory + fs/getMetadata：已准备 Codex \(label) 目录 · \(Project.abbreviate(url.path))"
        return url
    }

    private static func codexHomeSubfolderURL(_ subfolder: String, overrideCodexHome: String?) -> URL {
        let trimmedSubfolder = subfolder.trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespacesAndNewlines))
        let codexHomeURL = Self.defaultCodexConfigURL(
            overrideCodexHome: overrideCodexHome
        )
        .deletingLastPathComponent()
        return trimmedSubfolder.isEmpty
            ? codexHomeURL
            : codexHomeURL.appendingPathComponent(trimmedSubfolder, isDirectory: true)
    }

    private static func codexHomeSubfolderLabel(_ subfolder: String) -> String {
        let trimmedSubfolder = subfolder.trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespacesAndNewlines))
        return trimmedSubfolder.isEmpty ? "home" : trimmedSubfolder
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

    @discardableResult
    func uploadRuntimeFeedback(
        category: CodexFeedbackCategory,
        reason: String,
        includeLogs: Bool
    ) async -> Bool {
        runtimeCatalogIsRefreshing = true
        feedbackUploadStatusText = "正在调用 feedback/upload…"
        runtimeCatalogStatusText = feedbackUploadStatusText
        runtimeCatalogErrors = []

        do {
            let client: CodexAppServerClient
            if let existing = appServerClient {
                client = existing
            } else {
                client = try await ensureAppServerClient(useProviderConfiguration: false)
            }
            let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
            let result = try await client.uploadFeedback(
                classification: category.rawValue,
                reason: trimmedReason.isEmpty ? nil : trimmedReason,
                threadID: selectedThread.appServerThreadID,
                includeLogs: includeLogs,
                tags: [
                    "raytone_client": "macos",
                    "raytone_surface": "settings"
                ]
            )
            feedbackUploadThreadID = result.threadID
            feedbackUploadStatusText = includeLogs
                ? "feedback/upload：已上传日志 · \(result.threadID)"
                : "feedback/upload：已记录 · \(result.threadID)"
            runtimeCatalogStatusText = feedbackUploadStatusText
            runtimeCatalogErrors = []
            runtimeCatalogIsRefreshing = false
            return true
        } catch {
            feedbackUploadStatusText = "feedback/upload 失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = feedbackUploadStatusText
            runtimeCatalogErrors = [error.localizedDescription]
            runtimeCatalogIsRefreshing = false
            return false
        }
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

    private func waitForTerminalRunToFinish(id: UUID) async {
        while true {
            guard let run = terminalRuns.first(where: { $0.id == id }) else {
                return
            }
            if run.status != .running {
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
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
        providerModelSelectionTask?.cancel()
        selectedProviderID = providerID
        model = selectedProvider.model
        providerUsage = selectedProvider.usesSidecar ? providerUsageByProviderID[providerID] : nil
        providerUsageStatusText = selectedProvider.usesSidecar
            ? (providerUsage == nil ? "\(selectedProvider.displayName) 尚未读取 /usage" : "sidecar /usage：\(providerUsage?.successfulResponses ?? 0) 次响应")
            : "OpenAI 用量来自 account/usage/read"
        updateSelectedThread { thread in
            thread.model = model
        }
        providerSelectionTask?.cancel()
        let providerID = selectedProviderID
        providerSelectionTask = Task { [weak self] in
            await self?.finishProviderSelection(providerID: providerID)
        }
    }

    private func finishProviderSelection(providerID: String) async {
        guard selectedProviderID == providerID, !Task.isCancelled else { return }
        await persistRuntimeProviderSettings(statusName: "Provider 选择")
        guard selectedProviderID == providerID, !Task.isCancelled else { return }
        await resetAppServerForProviderChange()
    }

    func waitForProviderSelectionToSettleForTesting() async {
        await providerSelectionTask?.value
        await providerModelSelectionTask?.value
    }

    func chooseProviderModel(providerID: String, model: String) {
        guard applyProviderModelSelection(providerID: providerID, model: model) != nil else { return }
        providerSelectionTask?.cancel()
        providerModelSelectionTask?.cancel()
        let providerID = selectedProviderID
        let model = self.model
        providerModelSelectionTask = Task { [weak self] in
            await self?.finishProviderModelSelection(providerID: providerID, model: model)
        }
    }

    private func finishProviderModelSelection(providerID: String, model: String) async {
        guard selectedProviderID == providerID, self.model == model, !Task.isCancelled else { return }
        guard let provider = providers.first(where: { $0.id == providerID }) else { return }
        await commitRuntimeModelSelection(provider: provider, model: model)
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

        providerSelectionTask?.cancel()
        providerModelSelectionTask?.cancel()
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
        providerSelectionTask?.cancel()
        providerModelSelectionTask?.cancel()
        guard let provider = applyProviderModelSelection(providerID: providerID, model: selectedModel) else {
            modelCatalogStatusText = "未找到 provider：\(providerID)"
            return
        }

        await commitRuntimeModelSelection(provider: provider, model: selectedModel)
    }

    private func commitRuntimeModelSelection(provider: RaytoneProviderConfiguration, model selectedModel: String) async {
        await syncSelectedThreadExecutionSettings(
            model: selectedModel,
            statusName: "模型 \(selectedModel)"
        )

        guard isCurrentRuntimeModelSelection(providerID: provider.id, model: selectedModel) else { return }
        await resetAppServerForProviderChange()
        guard isCurrentRuntimeModelSelection(providerID: provider.id, model: selectedModel) else { return }

        guard provider.usesSidecar == false else {
            await persistRuntimeProviderSettings(statusName: "\(provider.displayName) 模型")
            guard isCurrentRuntimeModelSelection(providerID: provider.id, model: selectedModel) else { return }
            await resetAppServerForProviderChange()
            modelCatalogStatusText = "\(provider.displayName) 将通过 sidecar 会话使用 \(selectedModel)"
            return
        }

        modelCatalogStatusText = "正在写入 model/model_provider…"
        runtimeCatalogStatusText = "正在写入 model/model_provider…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            guard isCurrentRuntimeModelSelection(providerID: provider.id, model: selectedModel) else { return }
            try await client.batchWriteConfig(edits: [
                CodexConfigWriteEdit(keyPath: "model", value: .string(selectedModel)),
                CodexConfigWriteEdit(keyPath: "model_provider", value: .string(provider.id)),
                CodexConfigWriteEdit(
                    keyPath: "desktop.raytone.selected_provider_id",
                    value: .string(provider.id)
                ),
                CodexConfigWriteEdit(
                    keyPath: "desktop.raytone.providers_json",
                    value: .string(Self.providersConfigJSONString(providers.filter(\.usesSidecar)))
                )
            ])
            let config = try await client.readConfig(cwd: workspacePath, includeLayers: true)
            applyRuntimeConfig(config)
            guard isCurrentRuntimeModelSelection(providerID: provider.id, model: selectedModel) else { return }
            modelCatalogStatusText = "model/model_provider 已写入 config.toml"
            runtimeCatalogStatusText = "Codex 默认模型已更新为 \(selectedModel)"
        } catch {
            modelCatalogStatusText = "模型写入失败：\(error.localizedDescription)"
            runtimeCatalogStatusText = "模型写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    private func isCurrentRuntimeModelSelection(providerID: String, model selectedModel: String) -> Bool {
        selectedProviderID == providerID && model == selectedModel && !Task.isCancelled
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

    private func markProviderUnauthorized(
        _ provider: RaytoneProviderConfiguration,
        status: Int? = nil,
        body: String? = nil
    ) {
        let providerName = provider.displayName
        let statusText = status.map { "上游返回 HTTP \($0)" } ?? "上游拒绝当前 API Key"
        let compactBody = body.map(Self.compactProviderErrorBody) ?? ""
        let detail = compactBody.isEmpty ? statusText : "\(statusText) · \(compactBody)"

        appServerConnectionState = .providerUnauthorized(providerName)
        sidecarStatusText = "\(providerName) 授权失败"
        providerConnectionStatusText = "\(providerName) API Key 无效或无权限"
        providerConnectionDetailText = "\(detail) · 请在「模型与提供方」更新 Key 后重新测试"
        runtimeCatalogStatusText = providerConnectionStatusText
        runtimeCatalogErrors = [providerConnectionDetailText]
    }

    private static func compactProviderErrorBody(_ body: String) -> String {
        let normalized = body
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count > 240 else { return normalized }
        return String(normalized.prefix(240)) + "…"
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
            await refreshModelProviderCapabilities()
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
            let syncedModelCount = syncProviderModelsFromUpstream(providerID: provider.id, upstreamModels: upstream.models)
            providerConnectionStatusText = "上游已验证：\(provider.displayName)"
            providerConnectionDetailText = "\(upstream.modelsEndpoint) · \(upstream.modelCount) 个模型 · 已同步 \(syncedModelCount) 个 · 当前 \(upstream.model)"
            modelCatalogStatusText = "\(provider.displayName) 模型目录已从 \(upstream.modelsEndpoint) 同步"
            runtimeCatalogStatusText = "Provider 测试通过：\(provider.displayName) via \(providerConnectionBaseURL)"
            await persistRuntimeProviderSettings(statusName: "\(provider.displayName) 连接")
            await resetAppServerForProviderChange()
            _ = try await appServerEnvironmentOverrides()
            if let refreshedSession = activeProxySession {
                providerConnectionBaseURL = refreshedSession.baseURL.absoluteString
                providerConnectionProxyConfigPath = refreshedSession.configURL.path
                providerConnectionCodexConfigPath = refreshedSession.codexHomeURL
                    .appendingPathComponent("config.toml")
                    .path
            }
        } catch let error as RaytoneProxyServiceError {
            switch error {
            case let .upstreamUnauthorized(status, body):
                markProviderUnauthorized(provider, status: status, body: body)
            default:
                providerConnectionStatusText = "测试失败：\(error.localizedDescription)"
                providerConnectionDetailText = provider.apiKeyEnvironmentName.map { "Keychain 或 \($0)" } ?? "Keychain"
                runtimeCatalogStatusText = providerConnectionStatusText
                runtimeCatalogErrors = [error.localizedDescription]
            }
        } catch {
            providerConnectionStatusText = "测试失败：\(error.localizedDescription)"
            providerConnectionDetailText = provider.apiKeyEnvironmentName.map { "Keychain 或 \($0)" } ?? "Keychain"
            runtimeCatalogStatusText = providerConnectionStatusText
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    private func syncProviderModelsFromUpstream(providerID: String, upstreamModels: [String]) -> Int {
        guard let index = providers.firstIndex(where: { $0.id == providerID }) else {
            return 0
        }
        let upstreamModelNames = upstreamModels
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !upstreamModelNames.isEmpty else {
            return providers[index].models.count
        }

        var seen = Set<String>()
        var normalizedModels: [String] = []
        func appendModel(_ rawModel: String) {
            let modelName = rawModel.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !modelName.isEmpty, !seen.contains(modelName) else { return }
            seen.insert(modelName)
            normalizedModels.append(modelName)
        }

        appendModel(providers[index].model)
        upstreamModelNames.forEach(appendModel)

        if !normalizedModels.isEmpty {
            providers[index].models = normalizedModels
        }
        return providers[index].models.count
    }

    func evaluateProviderOnboarding(force: Bool = false) {
        guard !Self.sampleWorkspaceEnabled || force else {
            providerOnboardingPresented = false
            return
        }
        guard !sidecarProviders.isEmpty else {
            providerOnboardingPresented = false
            return
        }
        if force {
            providerOnboardingPresented = true
            providerOnboardingStatusText = "请选择模型提供方"
            return
        }
        guard !UserDefaults.standard.bool(forKey: Self.providerOnboardingCompletedKey) else {
            providerOnboardingPresented = false
            return
        }
        let hasThirdPartyKey = sidecarProviders.contains { hasProviderAPIKey($0) }
        providerOnboardingPresented = !hasThirdPartyKey
        providerOnboardingStatusText = providerOnboardingPresented ? "请选择模型提供方" : "已检测到模型提供方密钥"
    }

    func dismissProviderOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.providerOnboardingCompletedKey)
        providerOnboardingPresented = false
        providerOnboardingStatusText = "已跳过首启向导，可在设置中继续配置"
    }

    func resetProviderOnboardingForTesting() {
        UserDefaults.standard.removeObject(forKey: Self.providerOnboardingCompletedKey)
        providerOnboardingPresented = false
        providerOnboardingStatusText = "未开始"
    }

    func completeProviderOnboarding(
        providerID: String,
        apiKey: String,
        baseURL: String,
        model selectedModel: String
    ) async -> Bool {
        guard let provider = providers.first(where: { $0.id == providerID }),
              provider.usesSidecar else {
            providerOnboardingStatusText = "请选择一个第三方 Provider"
            return false
        }

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            do {
                try saveProviderAPIKey(trimmedKey, providerID: providerID)
            } catch {
                providerOnboardingStatusText = "密钥保存失败：\(error.localizedDescription)"
                return false
            }
        } else if !hasProviderAPIKey(provider) {
            providerOnboardingStatusText = "\(provider.displayName) 需要接口密钥"
            return false
        }

        providerOnboardingStatusText = "正在保存端点并测试连接…"
        await saveProviderEndpoint(providerID: providerID, baseURL: baseURL, model: selectedModel)
        await testProviderConnection(providerID: providerID)

        let connected = providerConnectionStatusText.contains("上游已验证") &&
            !providerConnectionBaseURL.isEmpty &&
            !providerConnectionProxyConfigPath.isEmpty
        if connected {
            UserDefaults.standard.set(true, forKey: Self.providerOnboardingCompletedKey)
            providerOnboardingPresented = false
            providerOnboardingStatusText = "已完成：\(selectedProvider.displayName)"
            return true
        }

        providerOnboardingStatusText = providerConnectionStatusText
        return false
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
        let mentions = await inputMentions(in: trimmedPrompt)
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
                if let memoryMode = serverThread.memoryMode {
                    thread.memoryMode = memoryMode
                }
            }
            threadID = serverThread.id
        } else if selectedThread.appServerSessionID == nil, let existingThreadID = threadID {
            let serverThread = try await client.resumeThread(id: existingThreadID, options: options)
            updateSelectedThread { thread in
                thread.appServerThreadID = serverThread.id
                thread.appServerSessionID = serverThread.sessionID
                if let memoryMode = serverThread.memoryMode {
                    thread.memoryMode = memoryMode
                }
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
            activeFileChangePatchTranscriptIDs.removeAll()
            pendingApprovalRequestIDs.removeAll()
            pendingApprovalResponseKinds.removeAll()
            pendingMcpElicitationRequestIDs.removeAll()
            pendingToolUserInputRequestIDs.removeAll()
            outOfBandElicitationThreadIDsByItemID.removeAll()
            runtimeElicitationStatusText = "未挂起"
            mcpElicitationDrafts.removeAll()
            toolUserInputDrafts.removeAll()
            toolUserInputSelections.removeAll()
            recentGuardianDeniedActions.removeAll()
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
        if !runtimeSkillExtraRoots.isEmpty {
            try await client.setSkillExtraRoots(runtimeSkillExtraRoots)
        }
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
        activeFileChangePatchTranscriptIDs.removeAll()
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
            personality: personality,
            collaborationMode: collaborationModePreset(forWorkModeID: runtimeWorkModeID),
            environments: selectedRuntimeEnvironmentsForAppServer()
        )
    }

    private func selectedRuntimeEnvironmentsForAppServer() -> [CodexTurnEnvironment]? {
        guard let selectedRuntimeEnvironmentID,
              let environment = runtimeRegisteredEnvironments.first(where: { $0.environmentID == selectedRuntimeEnvironmentID }) else {
            return nil
        }
        return [
            CodexTurnEnvironment(
                environmentID: environment.environmentID,
                cwd: environment.cwd.isEmpty ? workspacePath : environment.cwd
            )
        ]
    }

    func previewPluginMentions(for prompt: String) async -> [CodexAppServerMention] {
        await inputMentions(in: prompt).filter { $0.path.hasPrefix("plugin://") }
    }

    func previewInputMentions(for prompt: String) async -> [CodexAppServerMention] {
        await inputMentions(in: prompt)
    }

    private func inputMentions(in prompt: String) async -> [CodexAppServerMention] {
        let mentionTokens = Self.pluginMentionTokens(in: prompt)
        let appTokens = Self.appMentionTokens(in: prompt)
        let fileMentions = pendingFileReferenceMentions(in: prompt)
        guard !mentionTokens.isEmpty || !appTokens.isEmpty || !fileMentions.isEmpty else {
            lastMentionInputPreview = []
            return []
        }

        if !mentionTokens.isEmpty && runtimePlugins.isEmpty {
            await refreshRuntimeCatalog()
        }
        if !appTokens.isEmpty && runtimeApps.isEmpty {
            await refreshIntegrationRuntime(forceRefetchApps: false)
        }

        var pluginsByName: [String: CodexRuntimePlugin] = [:]
        for plugin in runtimePlugins where pluginsByName[plugin.name.lowercased()] == nil {
            pluginsByName[plugin.name.lowercased()] = plugin
        }
        var seenPaths = Set<String>()
        var mentions: [CodexAppServerMention] = []
        for mention in fileMentions where seenPaths.insert(mention.path).inserted {
            mentions.append(mention)
        }

        mentions.append(contentsOf: mentionTokens.compactMap { token -> CodexAppServerMention? in
            guard let plugin = pluginsByName[token.lowercased()],
                  plugin.installed,
                  plugin.enabled,
                  !seenPaths.contains(plugin.mentionPath) else {
                return nil
            }
            seenPaths.insert(plugin.mentionPath)
            return CodexAppServerMention(name: plugin.displayName, path: plugin.mentionPath)
        })

        if !appTokens.isEmpty {
            var appsByToken: [String: CodexRuntimeAppInfo] = [:]
            for app in runtimeApps {
                let candidates = [
                    app.id.lowercased(),
                    app.inputSlug.lowercased(),
                    CodexRuntimeAppInfo.slug(for: app.id).lowercased()
                ]
                for candidate in candidates where !candidate.isEmpty && appsByToken[candidate] == nil {
                    appsByToken[candidate] = app
                }
            }

            for token in appTokens {
                guard let app = appsByToken[token.lowercased()],
                      app.isAccessible,
                      app.isEnabled,
                      !seenPaths.contains(app.mentionPath) else {
                    continue
                }
                seenPaths.insert(app.mentionPath)
                mentions.append(CodexAppServerMention(name: app.name, path: app.mentionPath))
            }
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
        case "thread/started":
            handleThreadStartedNotification(params)
        case "thread/status/changed":
            handleThreadStatusChanged(params)
        case "thread/name/updated":
            handleThreadNameUpdated(params)
        case "thread/archived":
            handleThreadArchived(params)
        case "thread/unarchived":
            handleThreadUnarchived(params)
        case "thread/closed":
            handleThreadClosed(params)
        case "thread/compacted":
            handleThreadCompacted(params)
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
                        status: .active,
                        runtimeBacked: runtimeBacked
                    )
                }
            }
        case "turn/completed":
            isRunning = false
            activeAppServerTurnID = nil
            handleCompletedTurn(params?["turn"])
            clearLocalActiveGoalIfNeeded()
            refreshProviderUsageAfterCompletedTurn()
            if sideChatStatusText.hasPrefix("已提交") ||
                sideChatStatusText.hasPrefix("已追加") ||
                sideChatStatusText.hasPrefix("正在通过 turn/start") ||
                sideChatStatusText.hasPrefix("正在通过 turn/steer") {
                sideChatStatusText = "Codex 已回复"
            }
            if threadShellCommandStatusText.hasPrefix("thread/shellCommand：已提交") ||
                threadShellCommandStatusText.hasPrefix("正在调用 thread/shellCommand") {
                threadShellCommandStatusText = "thread/shellCommand：已完成"
            }
        case "turn/plan/updated":
            updateProgressSteps(params?["plan"]?.arrayValue ?? [])
        case "turn/diff/updated":
            if let diff = params?["diff"]?.stringValue {
                upsertDiffFileChanges(diff)
            }
        case "hook/started", "hook/completed":
            handleHookNotification(method: method, params: params)
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
        case "item/autoApprovalReview/started":
            handleGuardianApprovalReview(params, completed: false)
        case "item/autoApprovalReview/completed":
            handleGuardianApprovalReview(params, completed: true)
        case "rawResponseItem/completed":
            handleRawResponseItemCompleted(params)
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
        case "account/rateLimits/updated":
            Task { await refreshAccountUsageRuntime() }
        case "thread/tokenUsage/updated":
            handleThreadTokenUsageUpdated(params)
        case "app/list/updated":
            let catalog = CodexAppServerClient.runtimeAppCatalog(from: params ?? .object([:]))
            runtimeApps = catalog.apps
            let snapshotCount = catalog.apps.filter { !$0.screenshotPrompts.isEmpty }.count
            runtimeAppsStatusText = "app/list/updated：\(catalog.apps.count) 个 app · \(snapshotCount) 个含快照说明"
            runtimeCatalogStatusText = runtimeAppsStatusText
            runtimeCatalogErrors = []
        case "remoteControl/status/changed":
            let status = CodexAppServerClient.remoteControlStatus(from: params)
            runtimeRemoteControlStatus = status
            workspaceExecutionMode = status.status == "disabled" ? .local : .cloudPending
            runtimeCatalogStatusText = "remoteControl/status/changed：\(Self.remoteControlStatusDisplayName(status.status))"
            runtimeCatalogErrors = []
        case "externalAgentConfig/import/completed":
            externalAgentMigrationIsImporting = false
            let countText = externalAgentImportedItemCount > 0 ? "\(externalAgentImportedItemCount) 项" : "所选项目"
            externalAgentMigrationStatusText = "externalAgentConfig/import/completed：已完成 \(countText)"
            runtimeCatalogStatusText = externalAgentMigrationStatusText
            runtimeCatalogErrors = []
            Task {
                await refreshExternalAgentMigrationItemsAfterImport()
                await refreshRuntimeCatalog(forceReloadSkills: true)
            }
        case "fs/changed":
            handleFileSystemChanged(params)
        case "command/exec/outputDelta":
            handleTerminalOutputDelta(params)
        case "process/outputDelta":
            handleProcessOutputDelta(params)
        case "process/exited":
            handleProcessExited(params)
        case "item/agentMessage/delta":
            appendAgentDelta(itemID: params?["itemId"]?.stringValue, delta: params?["delta"]?.stringValue)
        case "item/plan/delta":
            appendPlanDelta(itemID: params?["itemId"]?.stringValue, delta: params?["delta"]?.stringValue)
        case "item/reasoning/summaryTextDelta", "item/reasoning/textDelta":
            appendReasoningDelta(itemID: params?["itemId"]?.stringValue, delta: params?["delta"]?.stringValue)
        case "item/reasoning/summaryPartAdded":
            handleReasoningSummaryPartAdded(params)
        case "item/commandExecution/outputDelta":
            appendCommandOutputDelta(itemID: params?["itemId"]?.stringValue, delta: params?["delta"]?.stringValue)
        case "item/commandExecution/terminalInteraction":
            appendTerminalInteraction(params)
        case "item/mcpToolCall/progress":
            appendMcpToolCallProgress(params)
        case "item/fileChange/outputDelta":
            appendFileChangeOutputDelta(itemID: params?["itemId"]?.stringValue, delta: params?["delta"]?.stringValue)
        case "item/fileChange/patchUpdated":
            upsertFileChangePatch(itemID: params?["itemId"]?.stringValue, changes: params?["changes"]?.arrayValue ?? [])
        case "fuzzyFileSearch/sessionUpdated":
            handleFuzzyFileSearchSessionUpdated(params)
        case "fuzzyFileSearch/sessionCompleted":
            handleFuzzyFileSearchSessionCompleted(params)
        case "thread/realtime/started", "thread/realtime/itemAdded",
             "thread/realtime/transcript/delta", "thread/realtime/transcript/done",
             "thread/realtime/outputAudio/delta", "thread/realtime/sdp",
             "thread/realtime/error", "thread/realtime/closed":
            handleRealtimeNotification(method: method, params: params)
        case "error":
            handleTurnErrorNotification(params)
        case "warning", "guardianWarning", "deprecationNotice", "configWarning",
             "model/rerouted", "model/verification", "turn/moderationMetadata",
             "windows/worldWritableWarning", "windowsSandbox/setupCompleted":
            handleRuntimeDiagnosticNotification(method: method, params: params)
        default:
            break
        }
    }

    private func refreshProviderUsageAfterCompletedTurn() {
        guard selectedProvider.usesSidecar else { return }
        Task { await refreshSelectedProviderUsage() }
    }

    private func handleThreadStartedNotification(_ params: JSONValue?) {
        guard let threadValue = params?["thread"],
              let threadID = threadValue["id"]?.stringValue else {
            return
        }
        mergeRuntimeThreadValue(threadValue)
        if loadedRuntimeThreadIDs.contains(threadID) == false {
            loadedRuntimeThreadIDs.insert(threadID, at: 0)
        }
        if let status = threadValue["status"] {
            applyThreadStatus(threadID: threadID, status: status)
        } else {
            runtimeThreadSyncStatusText = "thread/started：\(threadValue["name"]?.stringValue ?? threadValue["preview"]?.stringValue ?? threadID)"
        }
    }

    private func handleThreadTokenUsageUpdated(_ params: JSONValue?) {
        guard let usage = CodexAppServerClient.runtimeThreadTokenUsage(from: params) else {
            return
        }

        threadTokenUsageByThreadID[usage.threadID] = usage
        if selectedThread.appServerThreadID == usage.threadID {
            selectedThreadTokenUsage = usage
        }
        runtimeCatalogStatusText = "thread/tokenUsage/updated：当前线程 \(Self.compactNumber(usage.total.totalTokens)) token"
    }

    private func handleThreadStatusChanged(_ params: JSONValue?) {
        guard let threadID = params?["threadId"]?.stringValue,
              let status = params?["status"] else {
            return
        }
        applyThreadStatus(threadID: threadID, status: status)
    }

    private func applyThreadStatus(threadID: String, status: JSONValue) {
        let type = status["type"]?.stringValue ?? status.stringValue ?? "unknown"
        let activeFlags = status["activeFlags"]?.arrayValue?.compactMap(\.stringValue) ?? []
        let flagsText = activeFlags.map(Self.threadActiveFlagName).joined(separator: "、")
        let display = Self.threadStatusDisplayName(type)
        runtimeThreadSyncStatusText = flagsText.isEmpty
            ? "thread/status/changed：\(display)"
            : "thread/status/changed：\(display) · \(flagsText)"
        runtimeLoadedThreadsStatusText = runtimeThreadSyncStatusText

        guard selectedThread.appServerThreadID == threadID else {
            return
        }

        switch type {
        case "active":
            isRunning = true
            updateSelectedThread { thread in
                if thread.activeGoal == nil {
                    let title = activeFlags.contains("waitingOnApproval")
                        ? "等待审批"
                        : activeFlags.contains("waitingOnUserInput") ? "等待输入" : "运行 Codex"
                    thread.activeGoal = ActiveGoal(title: title, startedAt: Date(), runtimeBacked: false)
                }
            }
        case "idle", "notLoaded", "systemError":
            isRunning = false
            activeAppServerTurnID = nil
            clearLocalActiveGoalIfNeeded()
        default:
            break
        }
    }

    private func handleThreadNameUpdated(_ params: JSONValue?) {
        guard let threadID = params?["threadId"]?.stringValue else {
            return
        }
        let name = params?["threadName"]?.stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let title = name?.isEmpty == false ? name! : "未命名对话"
        updateThread(appServerThreadID: threadID) { thread in
            thread.title = title
        }
        if let index = archivedRuntimeThreads.firstIndex(where: { $0.id == threadID }) {
            archivedRuntimeThreads[index].title = title
            archivedRuntimeThreads[index].updatedAt = ISO8601DateFormatter().string(from: Date())
        }
        runtimeThreadSyncStatusText = "thread/name/updated：\(title)"
        runtimeCatalogStatusText = runtimeThreadSyncStatusText
    }

    private func handleThreadArchived(_ params: JSONValue?) {
        guard let threadID = params?["threadId"]?.stringValue else {
            return
        }
        let archivedThread = threads.first { $0.appServerThreadID == threadID }
        let archivedProjectPath = archivedThread.flatMap { target in
            projects.first(where: { $0.id == target.projectID })?.path
        }
        rememberArchivedRuntimeThread(
            id: threadID,
            title: archivedThread?.title,
            preview: archivedThread?.preview,
            cwd: archivedProjectPath
        )

        let selectedWasArchived = selectedThread.appServerThreadID == threadID
        threads.removeAll { $0.appServerThreadID == threadID }
        loadedRuntimeThreadIDs.removeAll { $0 == threadID }
        if threads.isEmpty {
            newThread(in: projects.first?.id ?? UUID())
        } else if selectedWasArchived || !threads.contains(where: { $0.id == selectedThreadID }) {
            selectThread(threads[0])
        }
        runtimeCatalogStatusText = "thread/archived：已归档 \(archivedThread?.title ?? threadID)"
    }

    private func handleThreadUnarchived(_ params: JSONValue?) {
        guard let threadID = params?["threadId"]?.stringValue else {
            return
        }
        let existingArchived = archivedRuntimeThreads.first { $0.id == threadID }
        archivedRuntimeThreads.removeAll { $0.id == threadID }
        if let existingArchived {
            var summary = existingArchived
            summary.archived = false
            summary.updatedAt = ISO8601DateFormatter().string(from: Date())
            mergeRuntimeThreads([summary])
            runtimeCatalogStatusText = "thread/unarchived：已恢复 \(summary.title)"
        } else {
            runtimeCatalogStatusText = "thread/unarchived：\(threadID)"
        }
    }

    private func handleThreadClosed(_ params: JSONValue?) {
        guard let threadID = params?["threadId"]?.stringValue else {
            return
        }
        loadedRuntimeThreadIDs.removeAll { $0 == threadID }
        if selectedThread.appServerThreadID == threadID {
            isRunning = false
            activeAppServerTurnID = nil
            clearLocalActiveGoalIfNeeded()
        }
        runtimeLoadedThreadsStatusText = "thread/closed：\(threadID)"
        runtimeThreadSyncStatusText = runtimeLoadedThreadsStatusText
    }

    private func handleThreadCompacted(_ params: JSONValue?) {
        guard let threadID = params?["threadId"]?.stringValue else {
            return
        }
        let turnID = params?["turnId"]?.stringValue ?? ""
        if selectedThread.appServerThreadID == threadID {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .info,
                    text: turnID.isEmpty ? "Codex 已压缩当前上下文。" : "Codex 已压缩当前上下文：\(turnID)"
                ))))
            }
        }
        runtimeThreadSyncStatusText = turnID.isEmpty
            ? "thread/compacted：\(threadID)"
            : "thread/compacted：\(turnID)"
        runtimeCatalogStatusText = runtimeThreadSyncStatusText
    }

    private static func threadStatusDisplayName(_ value: String) -> String {
        switch value {
        case "notLoaded":
            "未加载"
        case "idle":
            "空闲"
        case "systemError":
            "系统错误"
        case "active":
            "活动中"
        default:
            value
        }
    }

    private static func threadActiveFlagName(_ value: String) -> String {
        switch value {
        case "waitingOnApproval":
            "等待审批"
        case "waitingOnUserInput":
            "等待输入"
        default:
            value
        }
    }

    private func handleHookNotification(method: String, params: JSONValue?) {
        let run = params?["run"]
        let hookID = run?["id"]?.stringValue ?? "unknown"
        let eventName = run?["eventName"]?.stringValue ?? "hook"
        let status = run?["status"]?.stringValue ?? (method == "hook/started" ? "running" : "completed")
        let handlerType = run?["handlerType"]?.stringValue ?? "handler"
        let executionMode = run?["executionMode"]?.stringValue ?? "sync"
        let scope = run?["scope"]?.stringValue ?? "turn"
        let sourcePath = run?["sourcePath"]?.stringValue ?? ""
        let statusMessage = run?["statusMessage"]?.stringValue ?? ""
        let durationMs = run?["durationMs"]?.intValue
        let entries = run?["entries"]?.arrayValue ?? []
        let displayEvent = Self.hookEventDisplayName(eventName)
        let displayStatus = Self.hookRunStatusDisplayName(status)
        let statusSuffix = durationMs.map { " · \($0)ms" } ?? ""

        var event: [String: JSONValue] = [
            "source": .string("Codex app-server"),
            "method": .string(method),
            "threadId": .string(params?["threadId"]?.stringValue ?? selectedThread.appServerThreadID ?? ""),
            "turnId": .string(params?["turnId"]?.stringValue ?? activeAppServerTurnID ?? ""),
            "hookId": .string(hookID),
            "eventName": .string(eventName),
            "eventDisplayName": .string(displayEvent),
            "status": .string(status),
            "statusDisplayName": .string(displayStatus),
            "handlerType": .string(handlerType),
            "executionMode": .string(executionMode),
            "scope": .string(scope),
            "sourcePath": .string(sourcePath),
            "entryCount": .number(Double(entries.count))
        ]
        if !statusMessage.isEmpty {
            event["statusMessage"] = .string(statusMessage)
        }
        if let durationMs {
            event["durationMs"] = .number(Double(durationMs))
        }

        appendAutomationRuntimeEvent(.object(event))
        automationEventLogStatusText = "\(method)：\(displayEvent) · \(displayStatus)\(statusSuffix) · 已同步 \(automationEventLogLineCount) 条事件"
        runtimeCatalogStatusText = "\(method)：\(displayEvent) · \(displayStatus)\(statusSuffix)"
        runtimeCatalogErrors = []
    }

    private func appendAutomationRuntimeEvent(_ event: JSONValue) {
        let line = Self.compactJSONString(event)
        if automationEventLogText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            automationEventLogText = line
        } else {
            automationEventLogText += "\n\(line)"
        }
    }

    private func handleRuntimeDiagnosticNotification(method: String, params: JSONValue?) {
        let diagnostic = Self.runtimeDiagnostic(method: method, params: params)
        runtimeCatalogStatusText = "\(method)：\(diagnostic.summary)"
        if diagnostic.level == .info {
            runtimeCatalogErrors = []
        } else {
            runtimeCatalogErrors = [diagnostic.detail]
        }
        appendRuntimeDiagnosticNotice(
            threadID: diagnostic.threadID,
            level: diagnostic.level,
            text: diagnostic.detail
        )
    }

    private func handleTurnErrorNotification(_ params: JSONValue?) {
        let threadID = params?["threadId"]?.stringValue
        let turnID = params?["turnId"]?.stringValue ?? activeAppServerTurnID
        let error = params?["error"]
        let willRetry = params?["willRetry"]?.boolValue ?? false
        let message = error?["message"]?.stringValue ?? "Codex 轮次发生错误"
        let additionalDetails = error?["additionalDetails"]?.stringValue
        let errorInfo = Self.codexErrorInfoDisplayName(error?["codexErrorInfo"])
        let retryText = willRetry ? "Codex 将自动重试。" : "Codex 不会自动重试。"

        if Self.codexErrorInfoIsUnauthorized(error?["codexErrorInfo"]) {
            if selectedProvider.usesSidecar {
                markProviderUnauthorized(selectedProvider, body: additionalDetails ?? message)
            } else {
                appServerConnectionState = .loginRequired
            }
        }
        if !willRetry, selectedThread.appServerThreadID == threadID || threadID == nil {
            isRunning = false
            activeAppServerTurnID = nil
            clearLocalActiveGoalIfNeeded()
        }

        var detail = ["Codex 轮次错误：\(message)", retryText]
        if let turnID, !turnID.isEmpty {
            detail.append("轮次：\(turnID)")
        }
        if let errorInfo, !errorInfo.isEmpty {
            detail.append("错误类型：\(errorInfo)")
        }
        if let additionalDetails, !additionalDetails.isEmpty {
            detail.append("详情：\(additionalDetails)")
        }
        let text = detail.joined(separator: "\n")
        runtimeCatalogStatusText = willRetry ? "error：\(message) · 将重试" : "error：\(message)"
        runtimeCatalogErrors = [text]
        appendRuntimeDiagnosticNotice(
            threadID: threadID,
            level: willRetry ? .warning : .error,
            text: text
        )
    }

    private func appendRuntimeDiagnosticNotice(threadID: String?, level: Notice.Level, text: String) {
        let notice = Notice(level: level, text: text)
        if let threadID, !threadID.isEmpty {
            updateThread(appServerThreadID: threadID) { thread in
                thread.items.append(TranscriptItem(kind: .notice(notice)))
            }
        } else {
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(notice)))
            }
        }
    }

    private static func compactJSONString(_ value: JSONValue) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(value),
              let text = String(data: data, encoding: .utf8) else {
            return value.prettyJSONString.replacingOccurrences(of: "\n", with: " ")
        }
        return text
    }

    private static func runtimeDiagnostic(
        method: String,
        params: JSONValue?
    ) -> (threadID: String?, level: Notice.Level, summary: String, detail: String) {
        let threadID = params?["threadId"]?.stringValue
        switch method {
        case "warning":
            let message = params?["message"]?.stringValue ?? "Codex 发出运行时警告"
            return (threadID, .warning, message, "Codex 警告：\(message)")
        case "guardianWarning":
            let message = params?["message"]?.stringValue ?? "Codex 安全审查发出警告"
            return (threadID, .warning, message, "安全审查：\(message)")
        case "deprecationNotice":
            let summary = params?["summary"]?.stringValue ?? "Codex 协议弃用提醒"
            let detail = params?["details"]?.stringValue
            return (threadID, .warning, summary, [summary, detail].compactMap { $0 }.joined(separator: "\n"))
        case "configWarning":
            let summary = params?["summary"]?.stringValue ?? "Codex 配置警告"
            var parts = [summary]
            if let path = params?["path"]?.stringValue, !path.isEmpty {
                parts.append("配置文件：\(Project.abbreviate(path))")
            }
            if let rangeText = configWarningRangeText(params?["range"]) {
                parts.append("位置：\(rangeText)")
            }
            if let details = params?["details"]?.stringValue, !details.isEmpty {
                parts.append(details)
            }
            return (threadID, .warning, summary, parts.joined(separator: "\n"))
        case "model/rerouted":
            let fromModel = params?["fromModel"]?.stringValue ?? "原模型"
            let toModel = params?["toModel"]?.stringValue ?? "新模型"
            let reason = modelRerouteReasonName(params?["reason"]?.stringValue)
            let summary = "模型已改路由到 \(toModel)"
            let detail = "Codex 已将本轮模型从 \(fromModel) 切换到 \(toModel)。\n原因：\(reason)"
            return (threadID, .warning, summary, detail)
        case "model/verification":
            let verifications = params?["verifications"]?.arrayValue?.compactMap(\.stringValue) ?? []
            let names = verifications.map(modelVerificationName)
            let summary = names.isEmpty ? "需要模型访问验证" : "需要验证：\(names.joined(separator: "、"))"
            return (threadID, .warning, summary, summary)
        case "turn/moderationMetadata":
            let preview = params?["metadata"].map(Self.compactJSONString) ?? "{}"
            let summary = "收到本轮安全元数据"
            let detail = "Codex 返回了本轮安全元数据：\(preview)"
            return (threadID, .info, summary, detail)
        case "windows/worldWritableWarning":
            let paths = params?["samplePaths"]?.arrayValue?.compactMap(\.stringValue) ?? []
            let extraCount = params?["extraCount"]?.intValue ?? 0
            let failedScan = params?["failedScan"]?.boolValue ?? false
            var parts = ["Windows 路径权限警告", "Codex 检测到 Windows 可被所有用户写入的路径。"]
            if !paths.isEmpty {
                parts.append("示例路径：\(paths.prefix(3).map(Project.abbreviate).joined(separator: "、"))")
            }
            if extraCount > 0 {
                parts.append("另外还有 \(extraCount) 个路径。")
            }
            if failedScan {
                parts.append("路径扫描未完全完成。")
            }
            return (threadID, .warning, "Windows 路径权限警告", parts.joined(separator: "\n"))
        case "windowsSandbox/setupCompleted":
            let mode = params?["mode"]?.stringValue ?? "unknown"
            let success = params?["success"]?.boolValue ?? false
            let error = params?["error"]?.stringValue
            let displayMode = windowsSandboxModeName(mode)
            if success {
                let summary = "Windows 沙箱设置完成"
                return (threadID, .info, summary, "\(summary)：\(displayMode)")
            }
            let summary = "Windows 沙箱设置失败"
            let detail = [summary, "模式：\(displayMode)", error].compactMap { $0 }.joined(separator: "\n")
            return (threadID, .warning, summary, detail)
        default:
            let detail = params.map(Self.compactJSONString) ?? "{}"
            return (threadID, .info, method, "\(method)：\(detail)")
        }
    }

    private static func codexErrorInfoIsUnauthorized(_ value: JSONValue?) -> Bool {
        switch value {
        case let .string(raw):
            raw.caseInsensitiveCompare("unauthorized") == .orderedSame
        default:
            false
        }
    }

    private static func codexErrorInfoDisplayName(_ value: JSONValue?) -> String? {
        switch value {
        case let .string(raw):
            return switch raw {
            case "contextWindowExceeded":
                "上下文窗口超限"
            case "usageLimitExceeded":
                "使用额度不足"
            case "serverOverloaded":
                "服务器繁忙"
            case "cyberPolicy":
                "网络安全策略"
            case "internalServerError":
                "内部服务器错误"
            case "unauthorized", "Unauthorized":
                "未授权"
            case "badRequest":
                "请求无效"
            case "threadRollbackFailed":
                "回滚失败"
            case "sandboxError":
                "沙箱错误"
            case "other":
                "其他错误"
            default:
                raw
            }
        case let .object(object):
            if let payload = object["httpConnectionFailed"] {
                return codexHTTPErrorInfoDisplayName("HTTP 连接失败", payload: payload)
            }
            if let payload = object["responseStreamConnectionFailed"] {
                return codexHTTPErrorInfoDisplayName("响应流连接失败", payload: payload)
            }
            if let payload = object["responseStreamDisconnected"] {
                return codexHTTPErrorInfoDisplayName("响应流中断", payload: payload)
            }
            if let payload = object["responseTooManyFailedAttempts"] {
                return codexHTTPErrorInfoDisplayName("响应重试次数过多", payload: payload)
            }
            if let payload = object["activeTurnNotSteerable"],
               let turnKind = payload["turnKind"]?.stringValue {
                return "当前轮次不可追加输入：\(turnKind)"
            }
            return compactJSONString(.object(object))
        case .null, nil:
            return nil
        default:
            return value.map(compactJSONString)
        }
    }

    private static func codexHTTPErrorInfoDisplayName(_ title: String, payload: JSONValue) -> String {
        if let status = payload["httpStatusCode"]?.intValue {
            return "\(title)（HTTP \(status)）"
        }
        return title
    }

    private static func configWarningRangeText(_ range: JSONValue?) -> String? {
        guard let range else { return nil }
        let startLine = range["start"]?["line"]?.intValue
        let startColumn = range["start"]?["column"]?.intValue
        let endLine = range["end"]?["line"]?.intValue
        let endColumn = range["end"]?["column"]?.intValue
        guard let startLine, let startColumn else { return nil }
        if let endLine, let endColumn {
            return "\(startLine):\(startColumn)-\(endLine):\(endColumn)"
        }
        return "\(startLine):\(startColumn)"
    }

    private static func modelRerouteReasonName(_ value: String?) -> String {
        switch value {
        case "highRiskCyberActivity":
            "高风险网络安全活动"
        case let value?:
            value
        case nil:
            "未说明"
        }
    }

    private static func modelVerificationName(_ value: String) -> String {
        switch value {
        case "trustedAccessForCyber":
            "网络安全可信访问"
        default:
            value
        }
    }

    private static func windowsSandboxModeName(_ value: String) -> String {
        switch value {
        case "elevated":
            "管理员模式"
        case "unelevated":
            "非管理员模式"
        default:
            value
        }
    }

    private static func windowsSandboxSetupModeName(_ mode: CodexWindowsSandboxSetupMode) -> String {
        windowsSandboxModeName(mode.rawValue)
    }

    private static func windowsSandboxReadinessName(_ readiness: CodexWindowsSandboxReadiness) -> String {
        switch readiness {
        case .ready:
            "就绪"
        case .notConfigured:
            "未配置"
        case .updateRequired:
            "需要更新"
        case .unknown:
            "未知"
        }
    }

    private static func hookEventDisplayName(_ value: String) -> String {
        switch value {
        case "preToolUse":
            "工具使用前"
        case "permissionRequest":
            "权限请求"
        case "postToolUse":
            "工具使用后"
        case "preCompact":
            "压缩前"
        case "postCompact":
            "压缩后"
        case "sessionStart":
            "会话开始"
        case "userPromptSubmit":
            "提交用户提示"
        case "subagentStart":
            "子代理开始"
        case "subagentStop":
            "子代理停止"
        case "stop":
            "停止"
        default:
            value
        }
    }

    private static func hookRunStatusDisplayName(_ value: String) -> String {
        switch value {
        case "running":
            "运行中"
        case "completed":
            "已完成"
        case "failed":
            "失败"
        case "blocked":
            "已阻止"
        case "stopped":
            "已停止"
        default:
            value
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

    private func handleProcessOutputDelta(_ params: JSONValue?) {
        guard let processHandle = params?["processHandle"]?.stringValue,
              let deltaBase64 = params?["deltaBase64"]?.stringValue,
              let data = Data(base64Encoded: deltaBase64) else {
            return
        }

        let stream = params?["stream"]?.stringValue ?? "stdout"
        let output = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
        let cappedSuffix = params?["capReached"]?.boolValue == true ? "\n[\(stream) 输出已截断]\n" : ""
        let runID = ensureTerminalRun(processID: processHandle, command: "process/spawn \(processHandle)")
        appendTerminalRunOutput(id: runID, text: output + cappedSuffix)
        runtimeCatalogStatusText = "process/outputDelta：\(processHandle) · \(stream)"
    }

    private func handleProcessExited(_ params: JSONValue?) {
        guard let processHandle = params?["processHandle"]?.stringValue,
              let exitCode = params?["exitCode"]?.intValue else {
            return
        }

        let runID = ensureTerminalRun(processID: processHandle, command: "process/spawn \(processHandle)")
        let stdout = params?["stdout"]?.stringValue ?? ""
        let stderr = params?["stderr"]?.stringValue ?? ""
        let bufferedOutput = [stdout, stderr]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
        if !bufferedOutput.isEmpty {
            appendTerminalRunOutput(id: runID, text: bufferedOutput)
        }
        appendTerminalCapNoticeIfNeeded(runID: runID, stream: "stdout", capReached: params?["stdoutCapReached"]?.boolValue == true)
        appendTerminalCapNoticeIfNeeded(runID: runID, stream: "stderr", capReached: params?["stderrCapReached"]?.boolValue == true)
        updateTerminalRun(
            id: runID,
            output: terminalRuns.first(where: { $0.id == runID })?.output ?? "",
            exitCode: Int32(exitCode),
            status: exitCode == 0 ? .succeeded : .failed
        )
        runtimeCatalogStatusText = "process/exited：\(processHandle) · 退出 \(exitCode)"
        if activeTerminalProcessID == processHandle {
            terminalIsRunning = false
            resetActiveTerminal()
        }
    }

    private func ensureTerminalRun(processID: String, command: String) -> UUID {
        if let existing = terminalRuns.first(where: { $0.processID == processID }) {
            return existing.id
        }
        let id = UUID()
        terminalRuns.append(TerminalCommandRecord(id: id, command: command, processID: processID))
        return id
    }

    private func appendTerminalCapNoticeIfNeeded(runID: UUID, stream: String, capReached: Bool) {
        guard capReached,
              let run = terminalRuns.first(where: { $0.id == runID }) else {
            return
        }
        let marker = "[\(stream) 输出已截断]"
        if !run.output.contains(marker) {
            appendTerminalRunOutput(id: runID, text: "\n\(marker)\n")
        }
    }

    private func handleThreadSettingsUpdated(_ params: JSONValue?) {
        guard let threadID = params?["threadId"]?.stringValue,
              let settings = params?["threadSettings"] else {
            return
        }

        var updatedModel: String?
        var updatedApproval: CodexApprovalPolicy?
        var updatedApprovalsReviewer: CodexApprovalsReviewer?
        var updatedSandbox: CodexSandboxMode?
        var updatedParts: [String] = []

        if let rawModel = settings["model"]?.stringValue,
           !rawModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updatedModel = rawModel
            updatedParts.append("模型 \(rawModel)")
        }

        if let rawApproval = settings["approvalPolicy"]?.stringValue,
           let policy = CodexApprovalPolicy(rawValue: rawApproval) {
            updatedApproval = policy
            updatedParts.append("批准策略 \(Self.approvalName(policy))")
        }

        if let rawReviewer = settings["approvalsReviewer"]?.stringValue,
           let reviewer = Self.approvalsReviewer(fromAppServerValue: rawReviewer) {
            updatedApprovalsReviewer = reviewer
            updatedParts.append("审批路由 \(Self.approvalsReviewerName(reviewer))")
        }

        if let sandboxMode = Self.sandboxMode(fromAppServerSandboxPolicy: settings["sandboxPolicy"] ?? settings["sandbox_policy"]) {
            updatedSandbox = sandboxMode
            updatedParts.append("沙箱 \(Self.sandboxName(sandboxMode))")
        }

        if selectedThread.appServerThreadID == threadID {
            if let updatedModel {
                model = updatedModel
            }
            if let updatedApproval {
                approval = updatedApproval
            }
            if let updatedApprovalsReviewer {
                approvalsReviewer = updatedApprovalsReviewer
            }
            if let updatedSandbox {
                sandbox = updatedSandbox
            }
            accessMode = Self.accessMode(for: approval, sandbox: sandbox, approvalsReviewer: approvalsReviewer)
        }

        if updatedModel != nil || updatedApproval != nil || updatedApprovalsReviewer != nil || updatedSandbox != nil {
            updateThread(appServerThreadID: threadID) { thread in
                if let updatedModel {
                    thread.model = updatedModel
                }
                if let updatedApproval {
                    thread.approval = updatedApproval
                }
                if let updatedApprovalsReviewer {
                    thread.approvalsReviewer = updatedApprovalsReviewer
                }
                if let updatedSandbox {
                    thread.sandbox = updatedSandbox
                }
            }
            runtimeCatalogStatusText = "thread/settings/updated：\(updatedParts.joined(separator: " · "))"
        }

        if let mode = settings["collaborationMode"]?["mode"]?.stringValue ??
            settings["collaboration_mode"]?["mode"]?.stringValue {
            selectedCollaborationModeKind = mode
            runtimeCollaborationModeStatusText = "thread/settings/updated：\(mode)"
            runtimeCatalogStatusText = "thread/settings/updated：工作模式 \(Self.workModeName(forCollaborationModeKind: mode))"
            updateThread(appServerThreadID: threadID) { thread in
                thread.updatedAt = Date()
            }
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
            thread.activeGoal = ActiveGoal(
                title: goal.objective,
                startedAt: startedAt,
                status: goal.status,
                tokenBudget: goal.tokenBudget,
                tokensUsed: goal.tokensUsed,
                timeUsedSeconds: goal.timeUsedSeconds,
                runtimeBacked: true
            )
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

    private func threadIDForElicitationCounter(params: JSONValue?) -> String? {
        params?["threadId"]?.stringValue ?? selectedThread.appServerThreadID
    }

    private func beginOutOfBandElicitation(itemID: UUID, threadID: String?) {
        guard let threadID, !threadID.isEmpty, outOfBandElicitationThreadIDsByItemID[itemID] == nil else {
            return
        }
        outOfBandElicitationThreadIDsByItemID[itemID] = threadID
        runtimeElicitationStatusText = "thread/increment_elicitation：正在同步"

        Task { @MainActor in
            do {
                guard let client = appServerClient else {
                    throw CodexAppServerError.notRunning
                }
                let counter = try await client.incrementThreadElicitation(threadID: threadID)
                runtimeElicitationStatusText = "thread/increment_elicitation：count \(counter.count) · \(counter.paused ? "已暂停超时" : "未暂停")"
            } catch {
                runtimeElicitationStatusText = "thread/increment_elicitation 失败：\(error.localizedDescription)"
            }
        }
    }

    private func endOutOfBandElicitation(itemID: UUID) {
        guard let threadID = outOfBandElicitationThreadIDsByItemID.removeValue(forKey: itemID),
              !threadID.isEmpty else {
            return
        }
        runtimeElicitationStatusText = "thread/decrement_elicitation：正在同步"

        Task { @MainActor in
            do {
                guard let client = appServerClient else {
                    throw CodexAppServerError.notRunning
                }
                let counter = try await client.decrementThreadElicitation(threadID: threadID)
                runtimeElicitationStatusText = "thread/decrement_elicitation：count \(counter.count) · \(counter.paused ? "仍暂停" : "已恢复超时")"
            } catch {
                runtimeElicitationStatusText = "thread/decrement_elicitation 失败：\(error.localizedDescription)"
            }
        }
    }

    private func handleAppServerRequest(id: CodexAppServerRequestID, method: String, params: JSONValue?) {
        switch method {
        case "item/commandExecution/requestApproval":
            let command = params?["command"]?.stringValue
            let reason = params?["reason"]?.stringValue
            let itemID = params?["itemId"]?.stringValue ?? id.description
            let serverItemID = "approval:\(id.description):\(itemID)"
            let transcriptID = transcriptUUID(for: serverItemID)
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
            pendingApprovalResponseKinds[transcriptID] = .appServerDecision
            beginOutOfBandElicitation(itemID: transcriptID, threadID: threadIDForElicitationCounter(params: params))
            upsertTranscriptItem(serverItemID: serverItemID, kind: .approval(request))
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
            pendingApprovalResponseKinds[transcriptID] = .appServerDecision
            beginOutOfBandElicitation(itemID: transcriptID, threadID: threadIDForElicitationCounter(params: params))
            upsertTranscriptItem(serverItemID: "approval:\(id.description)", kind: .approval(request))
        case "item/permissions/requestApproval":
            let requestedPermissions = params?["permissions"] ?? .object([:])
            let serverItemID = "approval:\(id.description):permissions"
            let transcriptID = transcriptUUID(for: serverItemID)
            let request = ApprovalRequest(
                id: transcriptID,
                kind: Self.permissionApprovalKind(requestedPermissions),
                title: "允许扩展权限？",
                detail: Self.permissionApprovalDetail(params),
                rationale: params?["reason"]?.stringValue,
                decision: .pending
            )
            pendingApprovalRequestIDs[transcriptID] = id
            pendingApprovalResponseKinds[transcriptID] = .permissions(requested: requestedPermissions)
            beginOutOfBandElicitation(itemID: transcriptID, threadID: threadIDForElicitationCounter(params: params))
            upsertTranscriptItem(
                serverItemID: serverItemID,
                kind: .approval(request)
            )
        case "execCommandApproval":
            let command = (params?["command"]?.arrayValue ?? [])
                .compactMap(\.stringValue)
                .joined(separator: " ")
            let reason = params?["reason"]?.stringValue
            let callID = params?["approvalId"]?.stringValue ?? params?["callId"]?.stringValue ?? id.description
            let transcriptID = transcriptUUID(for: "approval:\(id.description):legacy-exec:\(callID)")
            let request = ApprovalRequest(
                id: transcriptID,
                kind: .command,
                title: "允许运行命令？",
                detail: command.isEmpty ? "Codex 请求运行命令" : command,
                rationale: reason,
                command: command.isEmpty ? nil : command,
                commandPrefix: Self.commandPrefix(for: command),
                decision: .pending
            )
            pendingApprovalRequestIDs[transcriptID] = id
            pendingApprovalResponseKinds[transcriptID] = .legacyReviewDecision
            beginOutOfBandElicitation(itemID: transcriptID, threadID: threadIDForElicitationCounter(params: params))
            upsertTranscriptItem(
                serverItemID: "approval:\(id.description):legacy-exec:\(callID)",
                kind: .approval(request)
            )
        case "applyPatchApproval":
            let fileChanges = params?["fileChanges"]?.objectValue ?? [:]
            let changedPaths = fileChanges.keys.sorted()
            let grantRoot = params?["grantRoot"]?.stringValue
            let reason = params?["reason"]?.stringValue
            let callID = params?["callId"]?.stringValue ?? id.description
            let detail = grantRoot ?? (changedPaths.isEmpty ? "Codex 请求修改文件" : changedPaths.joined(separator: "\n"))
            let transcriptID = transcriptUUID(for: "approval:\(id.description):legacy-patch:\(callID)")
            let request = ApprovalRequest(
                id: transcriptID,
                kind: .patch,
                title: "允许修改文件？",
                detail: detail,
                rationale: reason,
                decision: .pending
            )
            pendingApprovalRequestIDs[transcriptID] = id
            pendingApprovalResponseKinds[transcriptID] = .legacyReviewDecision
            beginOutOfBandElicitation(itemID: transcriptID, threadID: threadIDForElicitationCounter(params: params))
            upsertTranscriptItem(
                serverItemID: "approval:\(id.description):legacy-patch:\(callID)",
                kind: .approval(request)
            )
        case "mcpServer/elicitation/request":
            let mode = McpElicitationRequest.Mode(rawValue: params?["mode"]?.stringValue ?? "form")
            let requestedSchema = params?["requestedSchema"]
            let transcriptID = transcriptUUID(for: "mcp-elicitation:\(id.description)")
            let request = McpElicitationRequest(
                id: transcriptID,
                serverName: params?["serverName"]?.stringValue ?? "MCP",
                threadID: params?["threadId"]?.stringValue,
                turnID: params?["turnId"]?.stringValue,
                message: params?["message"]?.stringValue ?? "MCP 工具请求输入",
                mode: mode,
                urlString: params?["url"]?.stringValue,
                requestedSchema: requestedSchema,
                status: .pending
            )
            if mode == .form, mcpElicitationDrafts[transcriptID] == nil {
                mcpElicitationDrafts[transcriptID] = Self.defaultMcpElicitationDraft(from: requestedSchema)
            }
            pendingMcpElicitationRequestIDs[transcriptID] = id
            beginOutOfBandElicitation(itemID: transcriptID, threadID: threadIDForElicitationCounter(params: params))
            upsertTranscriptItem(
                serverItemID: "mcp-elicitation:\(id.description)",
                kind: .mcpElicitation(request)
            )
        case "item/tool/requestUserInput":
            let itemID = params?["itemId"]?.stringValue ?? id.description
            let transcriptID = transcriptUUID(for: "tool-user-input:\(id.description):\(itemID)")
            let questions = Self.toolUserInputQuestions(from: params?["questions"]?.arrayValue ?? [])
            let request = ToolUserInputRequest(
                id: transcriptID,
                threadID: params?["threadId"]?.stringValue ?? selectedThread.appServerThreadID ?? "",
                turnID: params?["turnId"]?.stringValue ?? activeAppServerTurnID ?? "",
                itemID: itemID,
                questions: questions,
                status: .pending
            )
            initializeToolUserInputState(itemID: transcriptID, questions: questions)
            pendingToolUserInputRequestIDs[transcriptID] = id
            beginOutOfBandElicitation(itemID: transcriptID, threadID: threadIDForElicitationCounter(params: params))
            upsertTranscriptItem(
                serverItemID: "tool-user-input:\(id.description):\(itemID)",
                kind: .toolUserInput(request)
            )
        case "item/tool/call":
            let callID = params?["callId"]?.stringValue ?? id.description
            let threadID = params?["threadId"]?.stringValue
            let namespace = params?["namespace"]?.stringValue
            let tool = params?["tool"]?.stringValue ?? "unknown"
            let arguments = params?["arguments"] ?? .object([:])
            upsertDynamicToolCallTranscript(
                callID: callID,
                namespace: namespace,
                tool: tool,
                arguments: arguments,
                status: .running,
                responseText: nil
            )
            Task {
                await respondToDynamicToolCall(
                    requestID: id,
                    callID: callID,
                    threadID: threadID,
                    namespace: namespace,
                    tool: tool,
                    arguments: arguments
                )
            }
        case "account/chatgptAuthTokens/refresh":
            let reason = params?["reason"]?.stringValue ?? "unknown"
            let previousAccountID = params?["previousAccountId"]?.stringValue ?? params?["previous_account_id"]?.stringValue
            let message = [
                "Codex 请求刷新外部 ChatGPT tokens，但 RaytoneCodex 当前没有托管 ChatGPT OAuth token。",
                "原因：\(reason)",
                previousAccountID.map { "账号：\($0)" }
            ]
                .compactMap { $0 }
                .joined(separator: "\n")
            appServerConnectionState = .loginRequired
            runtimeCatalogStatusText = "account/chatgptAuthTokens/refresh：需要重新登录"
            Task { await rejectAppServerRequest(requestID: id, message: message) }
        case "attestation/generate":
            let message = "Codex 请求生成上游 attestation，但 RaytoneCodex 没有声明 requestAttestation 能力，也不能伪造客户端证明。"
            runtimeCatalogStatusText = "attestation/generate：未启用 attestation provider"
            Task { await rejectAppServerRequest(requestID: id, message: message) }
        default:
            break
        }
    }

    private func handleCompletedTurn(_ turn: JSONValue?) {
        guard let turn else { return }
        if turn["status"]?.stringValue == "failed" {
            let error = turn["error"]
            if Self.codexErrorInfoIsUnauthorized(error?["codexErrorInfo"]) {
                if selectedProvider.usesSidecar {
                    markProviderUnauthorized(
                        selectedProvider,
                        body: error?["additionalDetails"]?.stringValue ?? error?["message"]?.stringValue
                    )
                } else {
                    appServerConnectionState = .loginRequired
                }
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

    private func handleGuardianApprovalReview(_ params: JSONValue?, completed: Bool) {
        guard let reviewID = params?["reviewId"]?.stringValue else { return }

        let review = params?["review"]
        let action = params?["action"]
        let status = review?["status"]?.stringValue ?? (completed ? "completed" : "inProgress")
        let statusName = Self.guardianReviewStatusName(status)
        let actionSummary = Self.guardianActionSummary(action)
        var details = [
            "状态：\(statusName)",
            "对象：\(actionSummary)"
        ]
        if let riskLevel = review?["riskLevel"]?.stringValue {
            details.append("风险：\(Self.guardianRiskName(riskLevel))")
        }
        if let rationale = review?["rationale"]?.stringValue,
           !rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            details.append("理由：\(rationale)")
        }
        if let decisionSource = params?["decisionSource"]?.stringValue {
            details.append("来源：\(decisionSource)")
        }
        if let targetItemID = params?["targetItemId"]?.stringValue {
            details.append("关联项：\(targetItemID)")
        }

        upsertTranscriptItem(
            serverItemID: "guardian-review:\(reviewID)",
            kind: .reasoning(ReasoningBlock(
                title: completed ? "自动审批审查：\(statusName)" : "自动审批审查中",
                detail: details.joined(separator: "\n")
            ))
        )

        updateSelectedThread { thread in
            let title = "自动审批审查：\(actionSummary)"
            let state: ProgressStep.State = completed
                ? (status == "approved" ? .done : .pending)
                : .running
            if let index = thread.progressSteps.firstIndex(where: { $0.title.hasPrefix("自动审批审查：") }) {
                thread.progressSteps[index].title = title
                thread.progressSteps[index].state = state
            } else {
                thread.progressSteps.append(ProgressStep(title: title, state: state))
            }
        }

        if completed {
            if status == "denied",
               let threadID = params?["threadId"]?.stringValue ?? selectedThread.appServerThreadID,
               let event = Self.guardianAssessmentEvent(
                   reviewID: reviewID,
                   params: params,
                   review: review,
                   action: action,
                   fallbackTurnID: activeAppServerTurnID
               ) {
                recordGuardianDeniedAction(GuardianDeniedAction(
                    reviewID: reviewID,
                    threadID: threadID,
                    turnID: event["turnId"]?.stringValue ?? "",
                    summary: actionSummary,
                    rationale: review?["rationale"]?.stringValue,
                    riskLevel: review?["riskLevel"]?.stringValue,
                    event: event,
                    createdAt: Date()
                ))
            } else {
                recentGuardianDeniedActions.removeAll { $0.reviewID == reviewID }
            }
        }

        runtimeCatalogStatusText = completed
            ? "item/autoApprovalReview/completed：\(statusName)"
            : "item/autoApprovalReview/started：\(actionSummary)"
        runtimeCatalogErrors = []
    }

    private func recordGuardianDeniedAction(_ denial: GuardianDeniedAction) {
        recentGuardianDeniedActions.removeAll { $0.reviewID == denial.reviewID }
        recentGuardianDeniedActions.insert(denial, at: 0)
        if recentGuardianDeniedActions.count > 10 {
            recentGuardianDeniedActions.removeLast(recentGuardianDeniedActions.count - 10)
        }
    }

    private static func guardianAssessmentEvent(
        reviewID: String,
        params: JSONValue?,
        review: JSONValue?,
        action: JSONValue?,
        fallbackTurnID: String?
    ) -> JSONValue? {
        guard let action,
              let turnID = params?["turnId"]?.stringValue ?? fallbackTurnID else {
            return nil
        }

        let startedAt = params?["startedAtMs"] ?? .number(Date().timeIntervalSince1970 * 1000)
        let status = review?["status"]?.stringValue ?? "denied"
        var event: [String: JSONValue] = [
            "id": .string(reviewID),
            "turnId": .string(turnID),
            "startedAtMs": startedAt,
            "status": .string(status),
            "action": action
        ]

        for key in ["targetItemId", "completedAtMs", "decisionSource"] {
            if let value = params?[key], value != .null {
                event[key] = value
            }
        }

        for key in ["riskLevel", "userAuthorization", "rationale"] {
            if let value = review?[key], value != .null {
                event[key] = value
            }
        }

        return .object(event)
    }

    private func handleRawResponseItemCompleted(_ params: JSONValue?) {
        guard let item = params?["item"],
              let type = item["type"]?.stringValue else {
            return
        }
        let stableID = item["id"]?.stringValue ??
            item["call_id"]?.stringValue ??
            "\(type):\(params?["turnId"]?.stringValue ?? activeAppServerTurnID ?? "turn")"

        switch type {
        case "message":
            let text = Self.textFromRuntimeContent(item["content"])
            let role = item["role"]?.stringValue ?? "assistant"
            guard !text.isEmpty else { break }
            if role == "user" {
                upsertTranscriptItem(serverItemID: "raw-response:\(stableID)", kind: .userMessage(text))
            } else {
                upsertTranscriptItem(serverItemID: "raw-response:\(stableID)", kind: .agentMessage(text))
            }
        case "agent_message":
            let recipient = item["recipient"]?.stringValue
            let text = Self.textFromRuntimeContent(item["content"])
            if !text.isEmpty {
                upsertTranscriptItem(
                    serverItemID: "raw-response:\(stableID)",
                    kind: .agentMessage(recipient.map { "@\($0)\n\(text)" } ?? text)
                )
            }
        case "reasoning":
            let summary = Self.textFromRuntimeContent(item["summary"])
            let content = Self.textFromRuntimeContent(item["content"])
            let detail = [summary, content].filter { !$0.isEmpty }.joined(separator: "\n\n")
            if !detail.isEmpty {
                upsertTranscriptItem(
                    serverItemID: "raw-response:\(stableID)",
                    kind: .reasoning(ReasoningBlock(title: "思考", detail: detail))
                )
            }
        case "local_shell_call":
            let action = item["action"]
            let command = Self.localShellCommand(from: action)
            upsertTranscriptItem(
                serverItemID: "raw-response:\(stableID)",
                kind: .command(CommandRun(
                    command: command.isEmpty ? "本地 shell 调用" : command,
                    directory: action?["working_directory"]?.stringValue.map(Project.abbreviate),
                    status: Self.runStatus(from: item["status"]?.stringValue)
                ))
            )
        case "function_call", "tool_search_call", "custom_tool_call":
            let name = item["name"]?.stringValue ?? item["execution"]?.stringValue ?? "tool"
            let arguments = item["arguments"] ?? item["input"] ?? .object([:])
            upsertTranscriptItem(
                serverItemID: "raw-response:\(stableID)",
                kind: .command(CommandRun(
                    command: "响应工具 \(name)",
                    output: Self.rawArgumentText(arguments),
                    status: Self.runStatus(from: item["status"]?.stringValue)
                ))
            )
        case "function_call_output", "custom_tool_call_output":
            let output = Self.textFromRuntimeContent(item["output"])
            upsertTranscriptItem(
                serverItemID: "raw-response:\(stableID)",
                kind: .command(CommandRun(
                    command: "响应工具输出 \(item["call_id"]?.stringValue ?? "")",
                    output: output.isEmpty ? item.prettyJSONString : output,
                    status: .succeeded
                ))
            )
        default:
            upsertTranscriptItem(
                serverItemID: "raw-response:\(stableID)",
                kind: .reasoning(ReasoningBlock(
                    title: "原始响应项：\(type)",
                    detail: item.prettyJSONString
                ))
            )
        }

        runtimeCatalogStatusText = "rawResponseItem/completed：\(type)"
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
                    output: commandOutput(
                        for: serverItemID,
                        proposed: object["aggregatedOutput"]?.stringValue,
                        in: selectedThread
                    ),
                    exitCode: object["exitCode"]?.intValue.map(Int32.init),
                    status: status
                ))
            )
        case "mcpToolCall":
            let server = object["server"]?.stringValue ?? "MCP"
            let tool = object["tool"]?.stringValue ?? "tool"
            let status = Self.mcpToolRunStatus(object["status"]?.stringValue)
            let finalOutput = Self.mcpToolCallOutputText(object)
            let progressOutput = existingCommandOutput(for: serverItemID, in: selectedThread) ?? ""
            let output = progressOutput.isEmpty || finalOutput.contains(progressOutput)
                ? finalOutput
                : [progressOutput, finalOutput].filter { !$0.isEmpty }.joined(separator: "\n")
            upsertTranscriptItem(
                serverItemID: serverItemID,
                kind: .command(CommandRun(
                    command: "MCP \(server)/\(tool)",
                    output: output,
                    exitCode: status == .failed ? 1 : nil,
                    status: status
                ))
            )
        case "dynamicToolCall":
            let namespace = object["namespace"]?.stringValue
            let tool = object["tool"]?.stringValue ?? object["name"]?.stringValue ?? "unknown"
            let arguments = object["arguments"] ?? object["input"] ?? .object([:])
            let success = object["success"]?.boolValue
            let responseText = Self.dynamicToolContentText(
                object["contentItems"]?.arrayValue ?? object["content"]?.arrayValue ?? [],
                success: success
            )
            let status: RunStatus
            if success == false || object["status"]?.stringValue == "failed" {
                status = .failed
            } else if success == true ||
                object["status"]?.stringValue == "completed" ||
                object["status"]?.stringValue == "succeeded" {
                status = .succeeded
            } else {
                status = .running
            }
            upsertDynamicToolCallTranscript(
                callID: serverItemID,
                namespace: namespace,
                tool: tool,
                arguments: arguments,
                status: status,
                responseText: responseText
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

    private func appendPlanDelta(itemID: String?, delta: String?) {
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
                    kind: .reasoning(ReasoningBlock(title: "计划", detail: delta))
                ))
            }

            let stepTitle = "接收 Codex 计划：\(delta.trimmingCharacters(in: .whitespacesAndNewlines))"
            if let index = thread.progressSteps.firstIndex(where: { $0.title.hasPrefix("接收 Codex 计划：") }) {
                thread.progressSteps[index].title = stepTitle
                thread.progressSteps[index].state = .running
            } else {
                thread.progressSteps.append(ProgressStep(title: stepTitle, state: .running))
            }
        }
        runtimeCatalogStatusText = "item/plan/delta：\(itemID)"
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

    private func handleReasoningSummaryPartAdded(_ params: JSONValue?) {
        guard let itemID = params?["itemId"]?.stringValue else { return }
        let summaryIndex = params?["summaryIndex"]?.intValue ?? 0
        let transcriptID = transcriptUUID(for: itemID)
        updateSelectedThread { thread in
            let marker = "摘要片段 \(summaryIndex + 1) 已开始\n"
            if let index = thread.items.firstIndex(where: { $0.id == transcriptID }),
               case var .reasoning(block) = thread.items[index].kind {
                if !block.detail.contains(marker) {
                    block.detail = [block.detail, marker]
                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        .joined(separator: "\n")
                    thread.items[index].kind = .reasoning(block)
                }
            } else {
                thread.items.append(TranscriptItem(
                    id: transcriptID,
                    kind: .reasoning(ReasoningBlock(title: "思考", detail: marker))
                ))
            }
        }
        runtimeCatalogStatusText = "item/reasoning/summaryPartAdded：\(summaryIndex + 1)"
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

    private func appendMcpToolCallProgress(_ params: JSONValue?) {
        guard let itemID = params?["itemId"]?.stringValue else { return }
        let message = params?["message"]?.stringValue ?? "MCP 工具正在运行"
        let transcriptID = transcriptUUID(for: itemID)
        let line = "[进度] \(message)\n"
        updateSelectedThread { thread in
            if let index = thread.items.firstIndex(where: { $0.id == transcriptID }),
               case var .command(run) = thread.items[index].kind {
                run.output += line
                run.status = .running
                thread.items[index].kind = .command(run)
            } else {
                thread.items.append(TranscriptItem(
                    id: transcriptID,
                    kind: .command(CommandRun(
                        command: "MCP 工具调用",
                        output: line,
                        status: .running
                    ))
                ))
            }
        }
        mcpToolCallStatusText = "item/mcpToolCall/progress：\(message)"
        runtimeCatalogStatusText = mcpToolCallStatusText
    }

    private func appendTerminalInteraction(_ params: JSONValue?) {
        guard let itemID = params?["itemId"]?.stringValue else { return }
        let stdin = params?["stdin"]?.stringValue ?? ""
        let processID = params?["processId"]?.stringValue ?? "process"
        let interactionText = "\n[stdin → \(processID)]\n\(stdin)"
        let transcriptID = transcriptUUID(for: itemID)
        updateSelectedThread { thread in
            if let index = thread.items.firstIndex(where: { $0.id == transcriptID }),
               case var .command(run) = thread.items[index].kind {
                run.output += interactionText
                thread.items[index].kind = .command(run)
            } else {
                thread.items.append(TranscriptItem(
                    id: transcriptID,
                    kind: .command(CommandRun(
                        command: "终端交互",
                        output: interactionText.trimmingCharacters(in: .newlines),
                        status: .running
                    ))
                ))
            }
        }
    }

    private func handleFuzzyFileSearchSessionUpdated(_ params: JSONValue?) {
        guard let sessionID = params?["sessionId"]?.stringValue else { return }
        guard shouldAcceptFileSearchSession(sessionID) else { return }
        let query = params?["query"]?.stringValue ?? fileSearchQuery
        let files = params?["files"]?.arrayValue ?? []
        if !query.isEmpty {
            fileSearchQuery = query
        }
        fileSearchResults = files.map { file in
            let path = Self.fuzzyFileSearchPath(from: file)
            return WorkspaceFileEntry(
                name: Self.fuzzyFileSearchFileName(from: file, path: path),
                path: path,
                isDirectory: Self.fuzzyFileSearchIsDirectory(file),
                isFile: !Self.fuzzyFileSearchIsDirectory(file)
            )
        }
        if completedFileSearchSessionIDs.contains(sessionID) {
            fileSearchIsRunning = false
            fileSearchStatusText = fileSearchResults.isEmpty
                ? "fuzzyFileSearch/sessionCompleted：未找到匹配文件"
                : "fuzzyFileSearch/sessionCompleted：\(fileSearchResults.count) 个匹配"
        } else {
            fileSearchIsRunning = true
            fileSearchStatusText = "fuzzyFileSearch/sessionUpdated：\(fileSearchResults.count) 个匹配"
        }
        runtimeCatalogStatusText = "\(fileSearchStatusText) · \(sessionID)"
    }

    private func handleFuzzyFileSearchSessionCompleted(_ params: JSONValue?) {
        let sessionID = params?["sessionId"]?.stringValue ?? "session"
        guard shouldAcceptFileSearchSession(sessionID) else { return }
        completedFileSearchSessionIDs.insert(sessionID)
        fileSearchIsRunning = false
        fileSearchStatusText = fileSearchResults.isEmpty
            ? "fuzzyFileSearch/sessionCompleted：未找到匹配文件"
            : "fuzzyFileSearch/sessionCompleted：\(fileSearchResults.count) 个匹配"
        runtimeCatalogStatusText = "\(fileSearchStatusText) · \(sessionID)"
    }

    private func shouldAcceptFileSearchSession(_ sessionID: String) -> Bool {
        if ignoredFileSearchSessionIDs.contains(sessionID) {
            return false
        }
        if let activeFileSearchSessionID {
            return activeFileSearchSessionID == sessionID
        }
        return true
    }

    private static func fuzzyFileSearchPath(from file: JSONValue) -> String {
        let rawPath = file["path"]?.stringValue ??
            file["relativePath"]?.stringValue ??
            file["file_name"]?.stringValue ??
            ""
        if rawPath.hasPrefix("/") {
            return rawPath
        }
        guard let root = file["root"]?.stringValue, !root.isEmpty else {
            return rawPath
        }
        return URL(fileURLWithPath: root).appendingPathComponent(rawPath).path
    }

    private static func fuzzyFileSearchFileName(from file: JSONValue, path: String) -> String {
        file["file_name"]?.stringValue ??
            file["fileName"]?.stringValue ??
            URL(fileURLWithPath: path).lastPathComponent
    }

    private static func fuzzyFileSearchIsDirectory(_ file: JSONValue) -> Bool {
        let matchType = file["match_type"]?.stringValue ??
            file["matchType"]?.stringValue ??
            ""
        return matchType.lowercased().contains("directory")
    }

    private func handleRealtimeNotification(method: String, params: JSONValue?) {
        let threadID = params?["threadId"]?.stringValue ?? selectedThread.appServerThreadID ?? "thread"

        switch method {
        case "thread/realtime/started":
            let version = params?["version"]?.stringValue ?? "unknown"
            let sessionID = params?["realtimeSessionId"]?.stringValue
            voiceInputStatusText = sessionID.map { "Codex realtime 已启动：\(version) · \($0)" } ?? "Codex realtime 已启动：\(version)"
        case "thread/realtime/transcript/delta":
            let role = params?["role"]?.stringValue ?? "assistant"
            let delta = params?["delta"]?.stringValue ?? ""
            appendRealtimeTranscript(threadID: threadID, role: role, text: delta, replace: false)
            voiceInputStatusText = "Codex realtime transcript：\(Self.realtimeRoleName(role))"
        case "thread/realtime/transcript/done":
            let role = params?["role"]?.stringValue ?? "assistant"
            let text = params?["text"]?.stringValue ?? ""
            appendRealtimeTranscript(threadID: threadID, role: role, text: text, replace: true)
            voiceInputStatusText = "Codex realtime transcript 完成：\(Self.realtimeRoleName(role))"
        case "thread/realtime/outputAudio/delta":
            let audio = params?["audio"]
            let itemID = audio?["itemId"]?.stringValue ?? "audio"
            let sampleRate = audio?["sampleRate"]?.intValue ?? 0
            let channels = audio?["numChannels"]?.intValue ?? 0
            let samples = audio?["samplesPerChannel"]?.intValue ?? 0
            upsertTranscriptItem(
                serverItemID: "realtime-audio:\(threadID):\(itemID)",
                kind: .reasoning(ReasoningBlock(
                    title: "实时语音输出",
                    detail: "\(sampleRate) Hz · \(channels) 声道 · \(samples) samples/channel"
                ))
            )
            voiceInputStatusText = "Codex realtime 音频输出：\(sampleRate) Hz"
        case "thread/realtime/sdp":
            let sdp = params?["sdp"]?.stringValue ?? ""
            upsertTranscriptItem(
                serverItemID: "realtime-sdp:\(threadID)",
                kind: .reasoning(ReasoningBlock(
                    title: "实时连接 SDP",
                    detail: String(sdp.prefix(2000))
                ))
            )
            voiceInputStatusText = "Codex realtime 已收到 SDP"
        case "thread/realtime/error":
            let message = params?["message"]?.stringValue ?? "realtime error"
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(level: .error, text: "Codex realtime 错误：\(message)"))))
            }
            voiceInputStatusText = "Codex realtime 错误：\(message)"
            runtimeCatalogErrors = [message]
        case "thread/realtime/closed":
            let reason = params?["reason"]?.stringValue ?? "已关闭"
            voiceInputStatusText = "Codex realtime 已关闭：\(reason)"
        case "thread/realtime/itemAdded":
            let item = params?["item"] ?? .object([:])
            upsertTranscriptItem(
                serverItemID: "realtime-item:\(threadID):\(UUID().uuidString)",
                kind: .reasoning(ReasoningBlock(
                    title: "实时事件",
                    detail: item.prettyJSONString
                ))
            )
            voiceInputStatusText = "Codex realtime 收到事件"
        default:
            break
        }

        runtimeCatalogStatusText = "\(method)：\(voiceInputStatusText)"
    }

    private func appendRealtimeTranscript(threadID: String, role: String, text: String, replace: Bool) {
        guard !text.isEmpty else { return }
        let serverItemID = "realtime-transcript:\(threadID):\(role)"
        let transcriptID = transcriptUUID(for: serverItemID)
        let isUser = role == "user"
        updateSelectedThread { thread in
            if let index = thread.items.firstIndex(where: { $0.id == transcriptID }) {
                if isUser, case let .userMessage(existing) = thread.items[index].kind {
                    thread.items[index].kind = .userMessage(replace ? text : existing + text)
                } else if case let .agentMessage(existing) = thread.items[index].kind {
                    thread.items[index].kind = .agentMessage(replace ? text : existing + text)
                } else {
                    thread.items[index].kind = isUser ? .userMessage(text) : .agentMessage(text)
                }
            } else {
                thread.items.append(TranscriptItem(
                    id: transcriptID,
                    kind: isUser ? .userMessage(text) : .agentMessage(text)
                ))
            }
        }
    }

    private func appendFileChangeOutputDelta(itemID: String?, delta: String?) {
        guard let itemID, let delta, !delta.isEmpty else { return }
        let transcriptID = transcriptUUID(for: "\(itemID):fileChangeOutput")
        updateSelectedThread { thread in
            if let index = thread.items.firstIndex(where: { $0.id == transcriptID }),
               case var .reasoning(block) = thread.items[index].kind {
                block.detail += delta
                thread.items[index].kind = .reasoning(block)
            } else {
                thread.items.append(TranscriptItem(
                    id: transcriptID,
                    kind: .reasoning(ReasoningBlock(title: "文件变更输出", detail: delta))
                ))
            }
        }
    }

    private func upsertFileChangePatch(itemID: String?, changes: [JSONValue]) {
        guard let itemID else { return }
        upsertFileChanges(serverItemID: itemID, changes: changes)
    }

    private func upsertFileChanges(serverItemID: String, changes: [JSONValue]) {
        var currentIDs = Set<UUID>()

        for changeValue in changes {
            guard let path = changeValue["path"]?.stringValue else { continue }
            let diff = changeValue["diff"]?.stringValue ?? ""
            let parsedDiff = Self.parseUnifiedDiff(diff)
            let transcriptID = upsertTranscriptItem(
                serverItemID: "\(serverItemID):\(path)",
                kind: .fileChange(FileChange(
                    path: path,
                    type: Self.fileChangeType(from: changeValue["kind"]),
                    additions: parsedDiff.additions,
                    deletions: parsedDiff.deletions,
                    hunks: parsedDiff.hunks
                ))
            )
            currentIDs.insert(transcriptID)
        }

        let staleIDs = activeFileChangePatchTranscriptIDs[serverItemID, default: []].subtracting(currentIDs)
        if !staleIDs.isEmpty {
            updateSelectedThread { thread in
                thread.items.removeAll { staleIDs.contains($0.id) }
            }
        }
        if currentIDs.isEmpty {
            activeFileChangePatchTranscriptIDs.removeValue(forKey: serverItemID)
        } else {
            activeFileChangePatchTranscriptIDs[serverItemID] = currentIDs
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
        let resolvedApprovalIDs = pendingApprovalRequestIDs.compactMap { itemID, value in
            value.description == requestID ? itemID : nil
        }
        pendingApprovalRequestIDs = pendingApprovalRequestIDs.filter { _, value in
            value.description != requestID
        }
        for itemID in resolvedApprovalIDs {
            pendingApprovalResponseKinds.removeValue(forKey: itemID)
            endOutOfBandElicitation(itemID: itemID)
        }
        let resolvedElicitationIDs = pendingMcpElicitationRequestIDs.compactMap { itemID, value in
            value.description == requestID ? itemID : nil
        }
        pendingMcpElicitationRequestIDs = pendingMcpElicitationRequestIDs.filter { _, value in
            value.description != requestID
        }
        for itemID in resolvedElicitationIDs {
            updateMcpElicitationStatusIfPending(itemID: itemID, status: .cancelled)
            endOutOfBandElicitation(itemID: itemID)
        }
        let resolvedToolInputIDs = pendingToolUserInputRequestIDs.compactMap { itemID, value in
            value.description == requestID ? itemID : nil
        }
        pendingToolUserInputRequestIDs = pendingToolUserInputRequestIDs.filter { _, value in
            value.description != requestID
        }
        for itemID in resolvedToolInputIDs {
            setToolUserInputStatusIfPending(itemID: itemID, status: .cancelled)
            endOutOfBandElicitation(itemID: itemID)
        }
    }

    private func updateMcpElicitationStatus(itemID: UUID, status: McpElicitationRequest.Status) {
        guard let index = threads.firstIndex(where: { $0.id == selectedThreadID }),
              let itemIndex = threads[index].items.firstIndex(where: { $0.id == itemID }),
              case var .mcpElicitation(request) = threads[index].items[itemIndex].kind else {
            return
        }
        request.status = status
        threads[index].items[itemIndex].kind = .mcpElicitation(request)
        threads[index].updatedAt = Date()
    }

    private func updateMcpElicitationStatusIfPending(itemID: UUID, status: McpElicitationRequest.Status) {
        guard let index = threads.firstIndex(where: { $0.id == selectedThreadID }),
              let itemIndex = threads[index].items.firstIndex(where: { $0.id == itemID }),
              case var .mcpElicitation(request) = threads[index].items[itemIndex].kind,
              request.status == .pending else {
            return
        }
        request.status = status
        threads[index].items[itemIndex].kind = .mcpElicitation(request)
        threads[index].updatedAt = Date()
    }

    private static func defaultMcpElicitationDraft(from schema: JSONValue?) -> String {
        guard let properties = schema?["properties"]?.objectValue else {
            return "{}"
        }

        var content: [String: JSONValue] = [:]
        for (name, property) in properties {
            if let defaultValue = property["default"], defaultValue != .null {
                content[name] = defaultValue
                continue
            }

            switch property["type"]?.stringValue {
            case "boolean":
                content[name] = .bool(false)
            case "number", "integer":
                content[name] = .number(0)
            case "array":
                content[name] = .array([])
            default:
                content[name] = .string("")
            }
        }

        return JSONValue.object(content).prettyJSONString
    }

    private static func permissionApprovalKind(_ permissions: JSONValue) -> ApprovalRequest.Kind {
        if permissions["network"]?.objectValue != nil {
            return .network
        }
        return .patch
    }

    private static func permissionApprovalDetail(_ params: JSONValue?) -> String {
        let permissions = params?["permissions"]
        var lines: [String] = []
        if let cwd = params?["cwd"]?.stringValue, !cwd.isEmpty {
            lines.append("工作目录：\(cwd)")
        }
        if permissions?["network"]?.objectValue != nil {
            let enabled = permissions?["network"]?["enabled"]?.boolValue
            lines.append("网络：\(enabled == false ? "不扩展" : "允许访问")")
        }
        if let fileSystem = permissions?["fileSystem"]?.objectValue {
            let read = fileSystem["read"]?.arrayValue?.compactMap(\.stringValue) ?? []
            let write = fileSystem["write"]?.arrayValue?.compactMap(\.stringValue) ?? []
            if !read.isEmpty {
                lines.append("读取：\(read.joined(separator: "、"))")
            }
            if !write.isEmpty {
                lines.append("写入：\(write.joined(separator: "、"))")
            }
            if let entries = fileSystem["entries"]?.arrayValue, !entries.isEmpty {
                let entryText = entries.compactMap { entry -> String? in
                    guard let access = entry["access"]?.stringValue else { return nil }
                    if let path = entry["path"]?["path"]?.stringValue {
                        return "\(access)：\(path)"
                    }
                    if let pattern = entry["path"]?["pattern"]?.stringValue {
                        return "\(access)：\(pattern)"
                    }
                    if let special = entry["path"]?["value"]?["kind"]?.stringValue {
                        return "\(access)：\(special)"
                    }
                    return access
                }
                if !entryText.isEmpty {
                    lines.append("文件系统：\(entryText.joined(separator: "、"))")
                }
            }
        }
        if let reason = params?["reason"]?.stringValue, !reason.isEmpty {
            lines.append("原因：\(reason)")
        }
        if lines.isEmpty {
            lines.append(permissions?.prettyJSONString ?? "Codex 请求扩展权限")
        }
        return lines.joined(separator: "\n")
    }

    private static func toolUserInputQuestions(from values: [JSONValue]) -> [ToolUserInputQuestion] {
        values.compactMap { value in
            guard let id = value["id"]?.stringValue,
                  let header = value["header"]?.stringValue,
                  let question = value["question"]?.stringValue else {
                return nil
            }
            let options = (value["options"]?.arrayValue ?? []).compactMap { option -> ToolUserInputOption? in
                guard let label = option["label"]?.stringValue,
                      let description = option["description"]?.stringValue else {
                    return nil
                }
                return ToolUserInputOption(label: label, description: description)
            }
            return ToolUserInputQuestion(
                id: id,
                header: header,
                question: question,
                isOther: value["isOther"]?.boolValue ?? false,
                isSecret: value["isSecret"]?.boolValue ?? false,
                options: options
            )
        }
    }

    private static func appServerApprovalDecision(
        from decision: ApprovalRequest.Decision
    ) -> CodexAppServerApprovalDecision? {
        switch decision {
        case .pending:
            return nil
        case .approved:
            return .accept
        case .approvedAlways:
            return .acceptForSession
        case .denied:
            return .decline
        }
    }

    private static func legacyReviewDecision(
        from decision: ApprovalRequest.Decision
    ) -> CodexAppServerLegacyReviewDecision? {
        switch decision {
        case .pending:
            return nil
        case .approved:
            return .approved
        case .approvedAlways:
            return .approvedForSession
        case .denied:
            return .denied
        }
    }

    private static func dynamicToolQualifiedName(namespace: String?, tool: String) -> String {
        [namespace, Optional(tool)]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ".")
    }

    private static func dynamicToolContentText(_ items: [JSONValue], success: Bool?) -> String? {
        guard !items.isEmpty || success != nil else { return nil }

        let content = items.compactMap { item -> String? in
            switch item["type"]?.stringValue {
            case "inputText":
                return item["text"]?.stringValue
            case "inputImage":
                if let url = item["imageUrl"]?.stringValue ?? item["imageURL"]?.stringValue {
                    return "图片：\(url)"
                }
                return item.prettyJSONString
            default:
                return item.prettyJSONString
            }
        }
        let contentText = content.joined(separator: "\n")
        if let success {
            return contentText.isEmpty ? "成功：\(success)" : "成功：\(success)\n\(contentText)"
        }
        return contentText
    }

    private static func guardianReviewStatusName(_ status: String) -> String {
        switch status {
        case "inProgress": "审查中"
        case "approved": "已通过"
        case "denied": "已拒绝"
        case "timedOut": "已超时"
        case "aborted": "已中止"
        default: status
        }
    }

    private static func guardianRiskName(_ risk: String) -> String {
        switch risk {
        case "low": "低"
        case "medium": "中"
        case "high": "高"
        case "critical": "严重"
        default: risk
        }
    }

    private static func guardianActionSummary(_ action: JSONValue?) -> String {
        guard let type = action?["type"]?.stringValue else {
            return "未知操作"
        }
        switch type {
        case "command":
            return action?["command"]?.stringValue ?? "命令"
        case "execve":
            let program = action?["program"]?.stringValue ?? "execve"
            let argv = action?["argv"]?.arrayValue?.compactMap(\.stringValue).joined(separator: " ") ?? ""
            return [program, argv].filter { !$0.isEmpty }.joined(separator: " ")
        case "applyPatch":
            let files = action?["files"]?.arrayValue?.compactMap(\.stringValue).map(Project.abbreviate) ?? []
            return files.isEmpty ? "修改文件" : "修改 \(files.joined(separator: "、"))"
        case "networkAccess":
            let protocolName = action?["protocol"]?.stringValue ?? "network"
            let host = action?["host"]?.stringValue ?? action?["target"]?.stringValue ?? "host"
            if let port = action?["port"]?.intValue {
                return "\(protocolName) \(host):\(port)"
            }
            return "\(protocolName) \(host)"
        case "mcpToolCall":
            let server = action?["server"]?.stringValue ?? "MCP"
            let tool = action?["toolTitle"]?.stringValue ?? action?["toolName"]?.stringValue ?? "tool"
            return "MCP \(server)/\(tool)"
        case "requestPermissions":
            if let reason = action?["reason"]?.stringValue, !reason.isEmpty {
                return "请求权限：\(reason)"
            }
            return "请求权限"
        default:
            return type
        }
    }

    private static func localShellCommand(from action: JSONValue?) -> String {
        guard let action else { return "" }
        if let command = action["command"]?.arrayValue?.compactMap(\.stringValue),
           !command.isEmpty {
            return command.joined(separator: " ")
        }
        return action["command"]?.stringValue ?? ""
    }

    private static func rawArgumentText(_ value: JSONValue) -> String {
        if let string = value.stringValue {
            return string
        }
        return value.prettyJSONString
    }

    private func commandOutput(for serverItemID: String, proposed: String?, in thread: ChatThread) -> String {
        let proposedOutput = proposed ?? ""
        if !proposedOutput.isEmpty {
            return proposedOutput
        }
        return existingCommandOutput(for: serverItemID, in: thread) ?? proposedOutput
    }

    private func existingCommandOutput(for serverItemID: String, in thread: ChatThread) -> String? {
        guard let transcriptID = appServerItemIDs[serverItemID],
              let item = thread.items.first(where: { $0.id == transcriptID }),
              case let .command(existing) = item.kind else {
            return nil
        }
        return existing.output
    }

    private static func mcpToolRunStatus(_ status: String?) -> RunStatus {
        switch status {
        case "completed": .succeeded
        case "failed": .failed
        default: .running
        }
    }

    private static func mcpToolCallOutputText(_ object: [String: JSONValue]) -> String {
        var sections = ["参数：\n\(object["arguments"]?.prettyJSONString ?? "{}")"]
        if let result = object["result"] {
            let contentText = textFromRuntimeContent(result["content"])
            if !contentText.isEmpty {
                sections.append("结果：\n\(contentText)")
            }
            if let structured = result["structuredContent"] {
                sections.append("结构化内容：\n\(structured.prettyJSONString)")
            }
            if let meta = result["_meta"] {
                sections.append("元数据：\n\(meta.prettyJSONString)")
            }
        }
        if let error = object["error"]?["message"]?.stringValue {
            sections.append("错误：\(error)")
        }
        if let resourceURI = object["mcpAppResourceUri"]?.stringValue {
            sections.append("资源：\(resourceURI)")
        }
        if let durationMs = object["durationMs"]?.intValue {
            sections.append("耗时：\(durationMs) ms")
        }
        return sections.joined(separator: "\n\n")
    }

    private static func realtimeRoleName(_ role: String) -> String {
        switch role {
        case "user": "用户"
        case "assistant", "agent": "Codex"
        default: role
        }
    }

    private func rejectAppServerRequest(requestID: CodexAppServerRequestID, message: String) async {
        do {
            try await appServerClient?.respondError(
                requestID: requestID,
                message: message,
                data: .object([
                    "source": .string("RaytoneCodex"),
                    "requestId": .string(requestID.description)
                ])
            )
        } catch {
            runtimeCatalogErrors = [error.localizedDescription]
        }
        updateSelectedThread { thread in
            thread.items.append(TranscriptItem(kind: .notice(Notice(
                level: .warning,
                text: message
            ))))
        }
    }

    private func respondToDynamicToolCall(
        requestID: CodexAppServerRequestID,
        callID: String,
        threadID: String?,
        namespace: String?,
        tool: String,
        arguments: JSONValue
    ) async {
        guard let client = appServerClient else {
            return
        }

        let result = await dynamicToolCallResult(
            threadID: threadID,
            namespace: namespace,
            tool: tool,
            arguments: arguments
        )
        do {
            try await client.respondDynamicToolCall(
                requestID: requestID,
                success: result.success,
                text: result.text
            )
            upsertDynamicToolCallTranscript(
                callID: callID,
                namespace: namespace,
                tool: tool,
                arguments: arguments,
                status: result.success ? .succeeded : .failed,
                responseText: result.text
            )
        } catch {
            let message = "动态工具结果未能回传给 app-server：\(error.localizedDescription)"
            upsertDynamicToolCallTranscript(
                callID: callID,
                namespace: namespace,
                tool: tool,
                arguments: arguments,
                status: .failed,
                responseText: message
            )
            updateSelectedThread { thread in
                thread.items.append(TranscriptItem(kind: .notice(Notice(
                    level: .warning,
                    text: message
                ))))
            }
        }
    }

    private func dynamicToolCallResult(
        threadID: String?,
        namespace: String?,
        tool: String,
        arguments: JSONValue
    ) async -> (success: Bool, text: String) {
        if namespace == "raytone_context", tool == "workspace_snapshot" {
            if arguments["includeDiffStats"]?.boolValue ?? true {
                await refreshWorkspaceGitDiff()
            }
            return (true, workspaceSnapshotText(arguments: arguments))
        }
        if namespace == "raytone_context", tool == "list_workspace_files" {
            return await listWorkspaceFilesDynamicToolText(arguments: arguments)
        }
        if namespace == "raytone_context", tool == "read_workspace_file" {
            return await readWorkspaceFileDynamicToolText(arguments: arguments)
        }
        if namespace == "raytone_browser", tool == "current_page" {
            return browserCurrentPageDynamicToolText(arguments: arguments)
        }
        if namespace == "raytone_browser", tool == "open_url" {
            return await browserOpenURLDynamicToolText(arguments: arguments)
        }
        if namespace == "raytone_browser", tool == "capture_snapshot" {
            return browserCaptureSnapshotDynamicToolText(arguments: arguments)
        }
        if namespace == "raytone_terminal", tool == "run_command" {
            return await runTerminalCommandDynamicToolText(arguments: arguments)
        }
        if namespace == "raytone_mcp", tool == "read_resource" {
            return await readMCPResourceDynamicToolText(threadID: threadID, arguments: arguments)
        }
        if namespace == "raytone_mcp", tool == "call_tool" {
            return await callMCPToolDynamicToolText(threadID: threadID, arguments: arguments)
        }

        let qualifiedName = Self.dynamicToolQualifiedName(namespace: namespace, tool: tool)
        return (
            false,
            "RaytoneCodex 暂未提供动态工具 \(qualifiedName.isEmpty ? tool : qualifiedName)。客户端已按 Codex app-server 协议返回失败，避免当前轮次挂起。"
        )
    }

    private func listWorkspaceFilesDynamicToolText(arguments: JSONValue) async -> (success: Bool, text: String) {
        guard let client = appServerClient else {
            return (false, "Codex app-server 尚未连接，无法读取工作区目录。")
        }

        let rawPath = arguments["path"]?.stringValue ?? "."
        guard let targetPath = Self.dynamicToolWorkspacePath(rawPath, workspacePath: workspacePath) else {
            return (false, "路径必须位于当前工作区内：\(rawPath)")
        }

        let rawLimit = arguments["maxEntries"]?.intValue ?? 80
        let maxEntries = min(max(rawLimit, 1), 200)
        let includeHidden = arguments["includeHidden"]?.boolValue ?? false

        do {
            let entries = try await client.readDirectory(path: targetPath)
            let filteredEntries = entries.filter { includeHidden || !$0.fileName.hasPrefix(".") }
            let visibleEntries = Array(filteredEntries.prefix(maxEntries))
            let payload: JSONValue = .object([
                "workspacePath": .string(workspacePath),
                "path": .string(targetPath),
                "relativePath": .string(Self.dynamicToolRelativeWorkspacePath(targetPath, workspacePath: workspacePath)),
                "entryCount": .number(Double(filteredEntries.count)),
                "returnedCount": .number(Double(visibleEntries.count)),
                "truncated": .bool(filteredEntries.count > visibleEntries.count),
                "includeHidden": .bool(includeHidden),
                "entries": .array(visibleEntries.map { entry in
                    .object([
                        "name": .string(entry.fileName),
                        "path": .string(Self.dynamicToolRelativeWorkspacePath(entry.path, workspacePath: workspacePath)),
                        "type": .string(entry.isDirectory ? "directory" : (entry.isFile ? "file" : "other"))
                    ])
                })
            ])
            return (true, payload.prettyJSONString)
        } catch {
            return (false, "fs/readDirectory 失败：\(error.localizedDescription)")
        }
    }

    private func readWorkspaceFileDynamicToolText(arguments: JSONValue) async -> (success: Bool, text: String) {
        guard let client = appServerClient else {
            return (false, "Codex app-server 尚未连接，无法读取工作区文件。")
        }

        guard let rawPath = arguments["path"]?.stringValue,
              !rawPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (false, "必须提供工作区内文件路径。")
        }
        guard let targetPath = Self.dynamicToolWorkspacePath(rawPath, workspacePath: workspacePath) else {
            return (false, "路径必须位于当前工作区内：\(rawPath)")
        }

        let rawLimit = arguments["maxBytes"]?.intValue ?? 32_768
        let maxBytes = min(max(rawLimit, 1), 200_000)

        do {
            let metadata = try await client.getMetadata(path: targetPath)
            if metadata.isDirectory {
                return (false, "fs/getMetadata：目标路径是目录，请改用 list_workspace_files：\(Self.dynamicToolRelativeWorkspacePath(targetPath, workspacePath: workspacePath))")
            }
            guard metadata.isFile else {
                return (false, "fs/getMetadata：目标路径不是可读取文件：\(Self.dynamicToolRelativeWorkspacePath(targetPath, workspacePath: workspacePath))")
            }

            let data = try await client.readFile(path: targetPath)
            let limitedData = Data(data.prefix(maxBytes))
            let truncated = data.count > limitedData.count
            let looksBinary = limitedData.contains(0)
            let content = looksBinary
                ? "文件看起来是二进制内容，RaytoneCodex 已省略正文。"
                : String(decoding: limitedData, as: UTF8.self)
            let payload: JSONValue = .object([
                "workspacePath": .string(workspacePath),
                "path": .string(targetPath),
                "relativePath": .string(Self.dynamicToolRelativeWorkspacePath(targetPath, workspacePath: workspacePath)),
                "byteCount": .number(Double(data.count)),
                "returnedBytes": .number(Double(limitedData.count)),
                "truncated": .bool(truncated),
                "encoding": .string(looksBinary ? "binary" : "utf-8"),
                "source": .string("fs/getMetadata + fs/readFile"),
                "content": .string(content)
            ])
            return (true, payload.prettyJSONString)
        } catch {
            return (false, "fs/getMetadata 或 fs/readFile 失败：\(error.localizedDescription)")
        }
    }

    private func browserCurrentPageDynamicToolText(arguments: JSONValue) -> (success: Bool, text: String) {
        let includeSnapshotPath = arguments["includeSnapshotPath"]?.boolValue ?? true
        return (true, browserStateJSON(includeSnapshotPath: includeSnapshotPath).prettyJSONString)
    }

    private func browserOpenURLDynamicToolText(arguments: JSONValue) async -> (success: Bool, text: String) {
        guard let address = Self.trimmedDynamicToolString(arguments["url"]) ??
            Self.trimmedDynamicToolString(arguments["address"]) else {
            return (false, "必须提供要打开的 url。")
        }
        guard let requestedURL = Self.browserURLCandidate(from: address, workspacePath: workspacePath) else {
            return (false, "无法解析浏览器地址：\(address)")
        }

        await openBrowserAddress(address)
        if arguments["captureSnapshot"]?.boolValue ?? false {
            captureBrowserPanelScreenshot()
        }

        let opened = Self.browserURLsMatch(browserURL, requestedURL)
        var payloadObject = browserStateJSON(
            includeSnapshotPath: arguments["includeSnapshotPath"]?.boolValue ?? true
        ).objectValue ?? [:]
        payloadObject["requestedURL"] = .string(requestedURL.absoluteString)
        payloadObject["opened"] = .bool(opened)
        payloadObject["source"] = .string("RaytoneCodex BrowserPanel + Codex app-server fs/getMetadata")
        let payload = JSONValue.object(payloadObject)
        return (
            opened,
            opened
                ? payload.prettyJSONString
                : "浏览器未能打开目标地址：\(address)\n\(payload.prettyJSONString)"
        )
    }

    private func browserCaptureSnapshotDynamicToolText(arguments: JSONValue) -> (success: Bool, text: String) {
        guard browserURL != nil else {
            return (false, "没有可截图的网页。请先调用 raytone_browser.open_url。")
        }

        captureBrowserPanelScreenshot()
        var payloadObject = browserStateJSON(
            includeSnapshotPath: arguments["includeSnapshotPath"]?.boolValue ?? true
        ).objectValue ?? [:]
        payloadObject["source"] = .string("RaytoneCodex BrowserPanel WKWebView snapshot request")
        payloadObject["snapshotRequested"] = .bool(browserSnapshotRequest != nil)
        let payload = JSONValue.object(payloadObject)
        return (true, payload.prettyJSONString)
    }

    private func runTerminalCommandDynamicToolText(arguments: JSONValue) async -> (success: Bool, text: String) {
        guard let client = appServerClient else {
            return (false, "Codex app-server 尚未连接，无法运行终端命令。")
        }
        guard let command = Self.trimmedDynamicToolString(arguments["command"]) else {
            return (false, "必须提供 command。")
        }

        let rawCWD = arguments["cwd"]?.stringValue ?? "."
        guard let cwdPath = Self.dynamicToolWorkspacePath(rawCWD, workspacePath: workspacePath) else {
            return (false, "cwd 必须位于当前工作区内：\(rawCWD)")
        }

        let timeoutSeconds = min(max(arguments["timeoutSeconds"]?.intValue ?? 30, 1), 120)
        let timeoutMs = timeoutSeconds * 1000
        let recordID = UUID()
        terminalRuns.append(TerminalCommandRecord(
            id: recordID,
            command: command,
            output: "正在通过 app-server command/exec 运行…"
        ))
        openToolPanel(.terminal)

        do {
            let result = try await client.execCommand(
                ["/bin/zsh", "-lc", command],
                cwd: URL(fileURLWithPath: cwdPath),
                sandbox: sandbox,
                timeoutMs: timeoutMs
            )
            let output = [result.stdout, result.stderr]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")
            completeTerminalRun(id: recordID, finalOutput: output, exitCode: result.exitCode)
            runtimeCatalogStatusText = "command/exec：动态终端 · exit \(result.exitCode)"

            let payload: JSONValue = .object([
                "source": .string("Codex app-server command/exec"),
                "command": .string(command),
                "cwd": .string(cwdPath),
                "relativeCWD": .string(Self.dynamicToolRelativeWorkspacePath(cwdPath, workspacePath: workspacePath)),
                "sandbox": .string(sandbox.rawValue),
                "timeoutMs": .number(Double(timeoutMs)),
                "exitCode": .number(Double(result.exitCode)),
                "stdout": .string(result.stdout),
                "stderr": .string(result.stderr)
            ])
            return (result.exitCode == 0, payload.prettyJSONString)
        } catch {
            failTerminalRun(id: recordID, errorText: error.localizedDescription)
            return (false, "command/exec 失败：\(error.localizedDescription)")
        }
    }

    private func readMCPResourceDynamicToolText(
        threadID: String?,
        arguments: JSONValue
    ) async -> (success: Bool, text: String) {
        guard let client = appServerClient else {
            return (false, "Codex app-server 尚未连接，无法读取 MCP 资源。")
        }
        guard let server = Self.trimmedDynamicToolString(arguments["server"]),
              let uri = Self.trimmedDynamicToolString(arguments["uri"]) else {
            return (false, "必须提供 MCP server 和 uri。")
        }

        do {
            let result = try await client.readMCPResource(
                server: server,
                uri: uri,
                threadID: Self.trimmedDynamicToolString(.string(threadID ?? ""))
            )
            mcpResourcePreview = result
            mcpResourceStatusText = "mcpServer/resource/read：动态工具 \(server) · \(result.contents.count) 段内容"
            runtimeCatalogStatusText = mcpResourceStatusText
            let contents: [JSONValue] = result.contents.map { content in
                .object([
                    "uri": .string(content.uri),
                    "mimeType": content.mimeType.map(JSONValue.string) ?? .null,
                    "text": content.text.map(JSONValue.string) ?? .null,
                    "blobBase64ByteCount": .number(Double(content.blobBase64?.utf8.count ?? 0))
                ])
            }
            let payload: JSONValue = .object([
                "server": .string(result.server),
                "requestedURI": .string(result.requestedURI),
                "contentCount": .number(Double(result.contents.count)),
                "textPreview": .string(result.textPreview),
                "contents": .array(contents)
            ])
            return (true, payload.prettyJSONString)
        } catch {
            return (false, "mcpServer/resource/read 失败：\(error.localizedDescription)")
        }
    }

    private func callMCPToolDynamicToolText(
        threadID: String?,
        arguments: JSONValue
    ) async -> (success: Bool, text: String) {
        guard let client = appServerClient else {
            return (false, "Codex app-server 尚未连接，无法调用 MCP 工具。")
        }
        guard let resolvedThreadID = Self.trimmedDynamicToolString(.string(threadID ?? "")) else {
            return (false, "动态 MCP 工具调用缺少 threadId。")
        }
        guard let server = Self.trimmedDynamicToolString(arguments["server"]),
              let tool = Self.trimmedDynamicToolString(arguments["tool"]) else {
            return (false, "必须提供 MCP server 和 tool。")
        }

        do {
            let result = try await client.callMCPTool(
                threadID: resolvedThreadID,
                server: server,
                tool: tool,
                arguments: arguments["arguments"] ?? .object([:]),
                meta: .object(["source": .string("RaytoneCodex dynamic tool")])
            )
            mcpToolCallPreview = result
            mcpToolCallStatusText = "mcpServer/tool/call：动态工具 \(server)/\(tool) · \(result.isError ? "工具返回错误" : "调用成功")"
            runtimeCatalogStatusText = mcpToolCallStatusText
            let payload: JSONValue = .object([
                "server": .string(result.server),
                "tool": .string(result.tool),
                "isError": .bool(result.isError),
                "textPreview": .string(result.textPreview),
                "content": .array(result.content),
                "structuredContent": result.structuredContent ?? .null,
                "meta": result.meta ?? .null
            ])
            return (!result.isError, payload.prettyJSONString)
        } catch {
            return (false, "mcpServer/tool/call 失败：\(error.localizedDescription)")
        }
    }

    private static func trimmedDynamicToolString(_ value: JSONValue?) -> String? {
        guard let text = value?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }
        return text
    }

    private static func dynamicToolWorkspacePath(_ rawPath: String, workspacePath: String) -> String? {
        let workspace = canonicalPath(workspacePath)
        let trimmed = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = trimmed.isEmpty ? "." : trimmed
        let candidate: String
        if path == "." {
            candidate = workspace
        } else if path.hasPrefix("/") || path.hasPrefix("~") {
            candidate = canonicalPath((path as NSString).expandingTildeInPath)
        } else {
            candidate = canonicalPath(URL(fileURLWithPath: workspace, isDirectory: true)
                .appendingPathComponent(path)
                .path)
        }

        guard candidate == workspace || candidate.hasPrefix(workspace + "/") else {
            return nil
        }
        return candidate
    }

    private static func dynamicToolRelativeWorkspacePath(_ path: String, workspacePath: String) -> String {
        let workspace = canonicalPath(workspacePath)
        let normalized = canonicalPath(path)
        if normalized == workspace {
            return "."
        }
        return promptReferencePath(for: normalized, workspacePath: workspacePath)
    }

    private static func browserURLsMatch(_ lhs: URL?, _ rhs: URL) -> Bool {
        guard let lhs else { return false }
        if lhs.isFileURL || rhs.isFileURL {
            return lhs.standardizedFileURL.path == rhs.standardizedFileURL.path
        }
        return lhs.absoluteString == rhs.absoluteString
    }

    private func workspaceSnapshotText(arguments: JSONValue) -> String {
        let includeDiffStats = arguments["includeDiffStats"]?.boolValue ?? true
        let currentGoal = selectedThread.activeGoal
        let diffSummary = Self.diffSummary(workspaceGitDiff?.diff ?? "")
        var snapshot: [String: JSONValue] = [
            "workspacePath": .string(workspacePath),
            "projectName": .string(selectedProject.name),
            "projectBranch": .string(selectedProject.branch ?? Self.currentGitBranch(at: workspacePath) ?? ""),
            "threadTitle": .string(selectedThread.title),
            "threadId": .string(selectedThread.appServerThreadID ?? ""),
            "model": .string(model.isEmpty ? "默认" : model),
            "sandbox": .string(sandbox.rawValue),
            "approvalPolicy": .string(approval.appServerValue),
            "isRunning": .bool(isRunning),
            "pendingTranscriptChanges": .number(Double(pendingChanges.count)),
            "pendingAdditions": .number(Double(pendingAdditions)),
            "pendingDeletions": .number(Double(pendingDeletions))
        ]
        snapshot["browser"] = browserStateJSON(includeSnapshotPath: true)
        snapshot["activeGoal"] = currentGoal.map { goal in
            .object([
                "title": .string(goal.title),
                "status": .string(goal.status.rawValue),
                "startedAt": .number(goal.startedAt.timeIntervalSince1970),
                "elapsedSeconds": .number(Date().timeIntervalSince(goal.startedAt)),
                "timeUsedSeconds": .number(Double(goal.timeUsedSeconds)),
                "tokensUsed": .number(Double(goal.tokensUsed)),
                "tokenBudget": goal.tokenBudget.map { .number(Double($0)) } ?? .null,
                "runtimeBacked": .bool(goal.runtimeBacked),
                "source": .string(goal.runtimeBacked ? "thread/goal/get" : "本地 activeGoal")
            ])
        } ?? .null
        snapshot["progressSteps"] = .array(selectedThread.progressSteps.map { step in
            .object([
                "title": .string(step.title),
                "state": .string(Self.progressStepStateName(step.state))
            ])
        })
        snapshot["environment"] = .object([
            "source": .string("EnvironmentInfoPanel + Codex app-server runtime state"),
            "workspacePath": .string(workspacePath),
            "changes": .object([
                "files": .number(Double(diffSummary.files)),
                "additions": .number(Double(diffSummary.additions)),
                "deletions": .number(Double(diffSummary.deletions)),
                "status": .string(workspaceGitStatusText)
            ]),
            "pullRequestStatus": .string(workspacePullRequestStatusText),
            "threadGitMetadataStatus": .string(runtimeThreadMetadataStatusText),
            "loadedThreadStatus": .string(runtimeLoadedThreadsStatusText),
            "loadedThreadIDs": .array(loadedRuntimeThreadIDs.map(JSONValue.string)),
            "sidecarStatus": .string(sidecarStatusText),
            "worktrees": .array(workspaceWorktrees.map(JSONValue.string)),
            "model": .string(modelDisplayName)
        ])

        if includeDiffStats {
            snapshot["gitDiff"] = .object([
                "files": .number(Double(diffSummary.files)),
                "additions": .number(Double(diffSummary.additions)),
                "deletions": .number(Double(diffSummary.deletions)),
                "status": .string(workspaceGitStatusText)
            ])
            snapshot["changedFiles"] = .array(pendingChanges.prefix(20).map { .string($0.path) })
        }

        return JSONValue.object(snapshot).prettyJSONString
    }

    private func browserStateJSON(includeSnapshotPath: Bool) -> JSONValue {
        var state: [String: JSONValue] = [
            "isOpen": .bool(browserURL != nil),
            "url": .string(browserURL?.absoluteString ?? ""),
            "title": .string(browserTitle),
            "canGoBack": .bool(browserCanGoBack),
            "canGoForward": .bool(browserCanGoForward),
            "toolPanel": .string(Self.toolPanelName(toolPanel)),
            "screenshotStatus": .string(browserScreenshotStatusText),
            "dataStatus": .string(browserDataStatusText),
            "hasPendingSnapshotRequest": .bool(browserSnapshotRequest != nil)
        ]

        if includeSnapshotPath {
            state["attachedSnapshotPath"] = .string(browserAttachedSnapshotPath)
            state["attachedSnapshotRelativePath"] = .string(
                browserAttachedSnapshotPath.isEmpty
                    ? ""
                    : Self.promptReferencePath(for: browserAttachedSnapshotPath, workspacePath: workspacePath)
            )
        }
        if let request = browserSnapshotRequest {
            state["pendingSnapshotPath"] = .string(request.outputURL.path)
        }

        return .object(state)
    }

    private nonisolated static func toolPanelName(_ panel: ToolPanel) -> String {
        switch panel {
        case .launcher:
            return "launcher"
        case .browser:
            return "browser"
        case .files:
            return "files"
        case .terminal:
            return "terminal"
        case .sideChat:
            return "sideChat"
        }
    }

    private nonisolated static func progressStepStateName(_ state: ProgressStep.State) -> String {
        switch state {
        case .done:
            return "done"
        case .running:
            return "running"
        case .pending:
            return "pending"
        }
    }

    private func upsertDynamicToolCallTranscript(
        callID: String,
        namespace: String?,
        tool: String,
        arguments: JSONValue,
        status: RunStatus,
        responseText: String?
    ) {
        let qualifiedName = Self.dynamicToolQualifiedName(namespace: namespace, tool: tool)
        let output = [
            "参数：",
            arguments.prettyJSONString,
            responseText.map { "\n结果：\n\($0)" }
        ]
            .compactMap { $0 }
            .joined(separator: "\n")
        upsertTranscriptItem(
            serverItemID: "dynamic-tool:\(callID)",
            kind: .command(CommandRun(
                command: "动态工具 \(qualifiedName.isEmpty ? tool : qualifiedName)",
                directory: Project.abbreviate(workspacePath),
                output: output,
                status: status
            ))
        )
    }

    private func initializeToolUserInputState(itemID: UUID, questions: [ToolUserInputQuestion]) {
        if toolUserInputDrafts[itemID] == nil {
            toolUserInputDrafts[itemID] = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, "") })
        }
        if toolUserInputSelections[itemID] == nil {
            toolUserInputSelections[itemID] = [:]
        }
    }

    private func toolUserInputRequest(itemID: UUID) -> ToolUserInputRequest? {
        guard let thread = threads.first(where: { $0.id == selectedThreadID }),
              let item = thread.items.first(where: { $0.id == itemID }),
              case let .toolUserInput(request) = item.kind else {
            return nil
        }
        return request
    }

    private func toolUserInputAnswers(for request: ToolUserInputRequest) -> [String: [String]] {
        let drafts = toolUserInputDrafts[request.id] ?? [:]
        let selections = toolUserInputSelections[request.id] ?? [:]
        return Dictionary(uniqueKeysWithValues: request.questions.map { question in
            var values: [String] = []
            if let selected = selections[question.id],
               !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                values.append(selected)
            }
            let draft = drafts[question.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !draft.isEmpty {
                values.append(draft)
            }
            return (question.id, values)
        })
    }

    private func setToolUserInputStatus(itemID: UUID, status: ToolUserInputRequest.Status) {
        guard let index = threads.firstIndex(where: { $0.id == selectedThreadID }),
              let itemIndex = threads[index].items.firstIndex(where: { $0.id == itemID }),
              case var .toolUserInput(request) = threads[index].items[itemIndex].kind else {
            return
        }
        request.status = status
        threads[index].items[itemIndex].kind = .toolUserInput(request)
        threads[index].updatedAt = Date()
    }

    private func setToolUserInputStatusIfPending(itemID: UUID, status: ToolUserInputRequest.Status) {
        guard let index = threads.firstIndex(where: { $0.id == selectedThreadID }),
              let itemIndex = threads[index].items.firstIndex(where: { $0.id == itemID }),
              case var .toolUserInput(request) = threads[index].items[itemIndex].kind,
              request.status == .pending else {
            return
        }
        request.status = status
        threads[index].items[itemIndex].kind = .toolUserInput(request)
        threads[index].updatedAt = Date()
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
        syncSelectedThreadTokenUsage()
    }

    private func updateThread(appServerThreadID: String, _ update: (inout ChatThread) -> Void) {
        guard let index = threads.firstIndex(where: { $0.appServerThreadID == appServerThreadID }) else {
            return
        }
        update(&threads[index])
        threads[index].updatedAt = Date()
    }

    private func updateThread(localThreadID: UUID, _ update: (inout ChatThread) -> Void) {
        guard let index = threads.firstIndex(where: { $0.id == localThreadID }) else {
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
    gh_bin="${RAYTONE_GH_PATH:-gh}"
    if ! command -v "$gh_bin" >/dev/null 2>&1; then
      echo "未安装 GitHub CLI，无法查询 PR"
      exit 0
    fi
    if ! "$gh_bin" auth status -h github.com >/dev/null 2>&1; then
      echo "GitHub CLI 未登录，无法查询 PR"
      exit 0
    fi
    out=$("$gh_bin" pr view "$branch" --json number,state,title,isDraft,reviewDecision,headRefName,baseRefName,url --jq 'def state_name: if .state == "OPEN" then "打开" elif .state == "MERGED" then "已合并" elif .state == "CLOSED" then "已关闭" else .state end; def review_name: if .reviewDecision == "APPROVED" then "已批准" elif .reviewDecision == "CHANGES_REQUESTED" then "需修改" elif .reviewDecision == "REVIEW_REQUIRED" then "待审查" else "未审查" end; "PR #\\(.number) \\(state_name)\\(if .isDraft then " · 草稿" else "" end) · \\(review_name) · \\(.headRefName)→\\(.baseRefName) · \\(.title)"' 2>&1)
    pr_rc=$?
    if [ $pr_rc -eq 0 ]; then
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

    private static let gitCreateRepositoryCommand = """
    set +e
    echo "== GitHub 建库预检 =="
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "不是 Git 工作区；请先运行 git init 并提交一次，再创建 GitHub 仓库。"
      exit 2
    fi

    branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
      echo "当前是 detached HEAD；请先切到一个分支，再创建 GitHub 仓库。"
      exit 2
    fi

    existing_origin=$(git remote get-url origin 2>/dev/null)
    if [ -n "$existing_origin" ]; then
      echo "已配置 origin：$existing_origin"
      echo "无需重复创建 GitHub 仓库；如需发布当前分支，请点“推送”。"
      exit 0
    fi

    gh_bin="${RAYTONE_GH_PATH:-gh}"
    if ! command -v "$gh_bin" >/dev/null 2>&1; then
      echo "未安装 GitHub CLI，无法创建 GitHub 仓库。"
      echo "安装后请运行：gh auth login"
      exit 5
    fi

    if ! "$gh_bin" auth status -h github.com >/dev/null 2>&1; then
      echo "GitHub CLI 未登录，无法创建 GitHub 仓库。请先运行：gh auth login"
      exit 6
    fi

    top_level=$(git rev-parse --show-toplevel 2>/dev/null)
    repo_name="${RAYTONE_GITHUB_REPO_NAME:-$(basename "$top_level")}"
    repo_name=$(printf '%s' "$repo_name" | tr -cs 'A-Za-z0-9._-' '-' | sed 's/^-//;s/-$//')
    if [ -z "$repo_name" ]; then
      echo "无法推断仓库名；请设置 RAYTONE_GITHUB_REPO_NAME 后重试。"
      exit 7
    fi

    echo "仓库：$repo_name"
    echo "可见性：private"
    echo "执行：$gh_bin repo create $repo_name --private --source=. --remote=origin"
    "$gh_bin" repo create "$repo_name" --private --source=. --remote=origin
    create_rc=$?
    if [ $create_rc -ne 0 ]; then
      echo "gh repo create 失败：$create_rc"
      exit $create_rc
    fi

    origin_after=$(git remote get-url origin 2>/dev/null)
    if [ -z "$origin_after" ]; then
      echo "仓库创建命令完成，但 origin 未写入；请检查 gh 输出。"
      exit 8
    fi

    echo
    echo "== 仓库已创建 =="
    echo "origin：$origin_after"
    echo "下一步：点击“推送”发布当前分支 $branch。"
    """

    private static let gitPushCurrentBranchCommand = """
    set +e
    echo "== GitHub 推送预检 =="
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "不是 Git 工作区"
      exit 2
    fi

    branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
      echo "当前是 detached HEAD；请先切到一个分支，再推送。"
      exit 2
    fi
    gh_bin="${RAYTONE_GH_PATH:-gh}"

    git_status_porcelain=$(git status --porcelain=v1 2>/dev/null)
    if [ -n "$git_status_porcelain" ]; then
      echo "当前还有未提交变更；请先提交或清理后再推送。"
      echo
      git status --short --branch
      exit 3
    fi

    origin=$(git remote get-url origin 2>/dev/null)
    if [ -z "$origin" ]; then
      echo "未配置 origin；请先创建 GitHub 仓库或添加远端。"
      echo "示例：gh repo create --private --source=. --remote=origin"
      exit 4
    fi

    if ! command -v "$gh_bin" >/dev/null 2>&1; then
      echo "未安装 GitHub CLI，无法确认 GitHub 登录态。"
      echo "安装后请运行：gh auth login"
      exit 5
    fi

    if ! "$gh_bin" auth status -h github.com >/dev/null 2>&1; then
      echo "GitHub CLI 未登录，无法安全推送。请先运行：gh auth login"
      exit 6
    fi

    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    echo "分支：$branch"
    echo "origin：$origin"
    if [ -z "$upstream" ]; then
      echo "执行：git push -u origin $branch"
      git push -u origin "$branch"
    else
      echo "upstream：$upstream"
      echo "执行：git push"
      git push
    fi
    push_rc=$?
    if [ $push_rc -ne 0 ]; then
      echo "git push 失败：$push_rc"
      exit $push_rc
    fi

    echo
    echo "== 推送完成 =="
    "$gh_bin" pr view "$branch" --json number,state,title,url --jq '"PR #\\(.number) \\(.state) · \\(.title) · \\(.url)"' 2>/dev/null || \
      echo "当前分支没有 PR；需要时可执行：gh pr create --draft --fill"
    """

    private static let gitCreatePullRequestCommand = """
    set +e
    echo "== GitHub PR 预检 =="
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "不是 Git 工作区"
      exit 2
    fi

    branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
      echo "当前是 detached HEAD；请先切到一个分支，再创建 PR。"
      exit 2
    fi
    gh_bin="${RAYTONE_GH_PATH:-gh}"

    git_status_porcelain=$(git status --porcelain=v1 2>/dev/null)
    if [ -n "$git_status_porcelain" ]; then
      echo "当前还有未提交变更；请先提交或清理后再创建 PR。"
      echo
      git status --short --branch
      exit 3
    fi

    origin=$(git remote get-url origin 2>/dev/null)
    if [ -z "$origin" ]; then
      echo "未配置 origin；请先创建 GitHub 仓库或添加远端。"
      echo "可先点击“建库”，或手动执行：gh repo create --private --source=. --remote=origin"
      exit 4
    fi

    if ! command -v "$gh_bin" >/dev/null 2>&1; then
      echo "未安装 GitHub CLI，无法创建 PR。"
      echo "安装后请运行：gh auth login"
      exit 5
    fi

    if ! "$gh_bin" auth status -h github.com >/dev/null 2>&1; then
      echo "GitHub CLI 未登录，无法创建 PR。请先运行：gh auth login"
      exit 6
    fi

    existing_pr=$("$gh_bin" pr view "$branch" --json number,state,title,url --jq '"PR #\\(.number) \\(.state) · \\(.title) · \\(.url)"' 2>&1)
    existing_rc=$?
    if [ $existing_rc -eq 0 ]; then
      echo "已有 PR：$existing_pr"
      exit 0
    fi
    case "$existing_pr" in
      *"no pull requests found"*|*"no pull request"*|*"not found"*)
        echo "当前分支 $branch 暂无 PR，准备创建草稿 PR。"
        ;;
      *)
        printf "PR 状态不可用：%s\\n" "$existing_pr"
        exit $existing_rc
        ;;
    esac

    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    echo "分支：$branch"
    echo "origin：$origin"
    if [ -z "$upstream" ]; then
      echo "执行：git push -u origin $branch"
      git push -u origin "$branch"
    else
      echo "upstream：$upstream"
      echo "执行：git push"
      git push
    fi
    push_rc=$?
    if [ $push_rc -ne 0 ]; then
      echo "git push 失败：$push_rc"
      exit $push_rc
    fi

    echo
    echo "执行：$gh_bin pr create --draft --fill --head $branch"
    pr_url=$("$gh_bin" pr create --draft --fill --head "$branch" 2>&1)
    pr_rc=$?
    if [ $pr_rc -ne 0 ]; then
      printf "gh pr create 失败：%s\\n" "$pr_url"
      exit $pr_rc
    fi

    echo "$pr_url"
    echo
    echo "== PR 已创建 =="
    "$gh_bin" pr view "$branch" --json number,state,title,url --jq '"PR #\\(.number) \\(.state) · \\(.title) · \\(.url)"' 2>/dev/null || true
    """

    private static let gitMetadataCommand = """
    set +e
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      exit 0
    fi
    printf 'BRANCH:%s\\n' "$(git branch --show-current 2>/dev/null)"
    printf 'SHA:%s\\n' "$(git rev-parse HEAD 2>/dev/null)"
    printf 'ORIGIN:%s\\n' "$(git config --get remote.origin.url 2>/dev/null)"
    """

    private static func promptReferencePath(for path: String, workspacePath: String) -> String {
        let workspace = URL(fileURLWithPath: workspacePath).standardizedFileURL.path
        let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        guard normalizedPath.hasPrefix(workspace + "/") else {
            return normalizedPath
        }
        return String(normalizedPath.dropFirst(workspace.count + 1))
    }

    private static func parseGitMetadataCommandOutput(_ output: String) -> (branch: String?, sha: String?, originURL: String?) {
        var values: [String: String] = [:]
        for line in output.components(separatedBy: .newlines) {
            guard let separatorIndex = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<separatorIndex])
            let value = String(line[line.index(after: separatorIndex)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            values[key] = value
        }

        func nonEmpty(_ key: String) -> String? {
            guard let value = values[key], !value.isEmpty else { return nil }
            return value
        }

        return (
            branch: nonEmpty("BRANCH"),
            sha: nonEmpty("SHA"),
            originURL: nonEmpty("ORIGIN")
        )
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

    private static func appMentionTokens(in text: String) -> [String] {
        let pattern = #"(?<![\p{L}\p{N}_\-])\$([A-Za-z0-9][A-Za-z0-9_\-]*)(?![\p{L}\p{N}_\-])"#
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

    private static func quotedConfigKeyPathSegment(_ segment: String) -> String {
        let escaped = segment
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
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

    static func runtimeAccountKindName(_ kind: String?) -> String {
        switch kind {
        case "chatgpt": "ChatGPT"
        case "apiKey": "API Key"
        case "amazonBedrock": "Amazon Bedrock"
        case "notLoggedIn", nil: "未登录"
        default: kind ?? "未返回"
        }
    }

    static func addCreditsNudgeStatusName(_ status: CodexAddCreditsNudgeEmailStatus) -> String {
        switch status {
        case .sent: "已发送提醒邮件"
        case .cooldownActive: "冷却中，稍后再试"
        case .unknown: "未知状态"
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

    static func modelProviderCapabilitiesSummary(_ capabilities: CodexModelProviderCapabilities) -> String {
        [
            "命名空间工具 \(capabilities.namespaceTools ? "开" : "关")",
            "图像生成 \(capabilities.imageGeneration ? "开" : "关")",
            "网页搜索 \(capabilities.webSearch ? "开" : "关")"
        ].joined(separator: " · ")
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
            return canonicalPath(String(line.dropFirst("worktree ".count)))
        }
        if !porcelain.isEmpty {
            return porcelain
        }
        return lines.compactMap { line in
            line.split(separator: " ").first.map { canonicalPath(String($0)) }
        }
    }

    static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path)
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
    }

    static func uniqueCanonicalPaths(_ paths: [String]) -> [String] {
        var seen = Set<String>()
        return paths.compactMap { path in
            let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let normalized = canonicalPath(trimmed)
            guard seen.insert(normalized).inserted else { return nil }
            return normalized
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

    private static func marketplaceTemplateData(
        existingData: Data?,
        marketplaceName: String,
        pluginName: String,
        pluginRelativePath: String
    ) throws -> Data {
        var marketplace: [String: Any]
        if let existingData, !existingData.isEmpty {
            let object = try JSONSerialization.jsonObject(with: existingData)
            guard let decoded = object as? [String: Any] else {
                throw NSError(
                    domain: "RaytoneCodex",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "marketplace.json 必须是 JSON object"]
                )
            }
            marketplace = decoded
        } else {
            marketplace = [
                "name": marketplaceName,
                "plugins": []
            ]
        }

        if (marketplace["name"] as? String)?.isEmpty != false {
            marketplace["name"] = marketplaceName
        }

        let rawPlugins = marketplace["plugins"] as? [Any] ?? []
        let pluginEntries = rawPlugins.compactMap { $0 as? [String: Any] }
        if pluginEntries.count != rawPlugins.count {
            throw NSError(
                domain: "RaytoneCodex",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "marketplace.json 的 plugins 必须是 object 数组"]
            )
        }

        let entry: [String: Any] = [
            "name": pluginName,
            "source": [
                "source": "local",
                "path": pluginRelativePath
            ],
            "policy": [
                "installation": "AVAILABLE",
                "authentication": "ON_INSTALL"
            ],
            "category": "Productivity"
        ]
        var mergedPlugins = pluginEntries
        if let index = mergedPlugins.firstIndex(where: { ($0["name"] as? String) == pluginName }) {
            mergedPlugins[index] = entry
        } else {
            mergedPlugins.append(entry)
        }
        marketplace["plugins"] = mergedPlugins
        return try jsonData(marketplace)
    }

    private static func jsonData(_ object: [String: Any]) throws -> Data {
        var data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        data.append(0x0A)
        return data
    }

    private static func utf8Data(_ string: String) -> Data {
        Data(string.utf8)
    }

    private static func readBackSnippets(
        client: CodexAppServerClient,
        paths: [String]
    ) async throws -> [String: String] {
        var snippets: [String: String] = [:]
        for path in paths {
            let data = try await client.readFile(path: path)
            let text = String(data: data, encoding: .utf8) ?? "<非 UTF-8 内容>"
            snippets[path] = String(text.prefix(240))
        }
        return snippets
    }

    private static func optionalAppServerFileData(
        client: CodexAppServerClient,
        path: String
    ) async throws -> (Data?, String) {
        do {
            let metadata = try await client.getMetadata(path: path)
            guard metadata.isFile else {
                return (nil, "fs/getMetadata non-file")
            }
            let data = try await client.readFile(path: path)
            return (data, "fs/getMetadata + fs/readFile")
        } catch {
            return (nil, "fs/getMetadata missing")
        }
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

    private func raytoneAutomationEventLogURL() -> URL {
        Self.defaultCodexConfigURL(
            overrideCodexHome: appServerEnvironmentOverridesForTesting["CODEX_HOME"]
        )
        .deletingLastPathComponent()
        .appendingPathComponent("raytone-automation-events.jsonl")
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

    static func sandboxName(_ mode: CodexSandboxMode) -> String {
        switch mode {
        case .readOnly: "只读"
        case .workspaceWrite: "工作区写入"
        case .dangerFullAccess: "完全访问"
        }
    }

    private static func approvalsReviewer(fromAppServerValue rawValue: String) -> CodexApprovalsReviewer? {
        if rawValue == "guardian_subagent" {
            return .autoReview
        }
        return CodexApprovalsReviewer(rawValue: rawValue)
    }

    private static func sandboxMode(fromAppServerSandboxPolicy value: JSONValue?) -> CodexSandboxMode? {
        if let rawValue = value?.stringValue {
            return CodexSandboxMode(rawValue: rawValue)
        }
        guard let type = value?["type"]?.stringValue else {
            return nil
        }
        switch type {
        case "readOnly":
            return .readOnly
        case "workspaceWrite":
            return .workspaceWrite
        case "dangerFullAccess":
            return .dangerFullAccess
        default:
            return nil
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

    static func collaborationModeKind(forWorkModeID id: String) -> String {
        id == "daily" ? "plan" : "default"
    }

    static func workModeID(forCollaborationModeKind kind: String?) -> String {
        switch kind?.lowercased() {
        case "plan": "daily"
        default: "coding"
        }
    }

    static func workModeName(forCollaborationModeKind kind: String?) -> String {
        workModeID(forCollaborationModeKind: kind) == "daily" ? "适用于日常工作" : "适用于编程"
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
