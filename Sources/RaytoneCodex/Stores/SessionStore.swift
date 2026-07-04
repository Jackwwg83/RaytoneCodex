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
    @Published var route: Route = .thread
    @Published var accessMode: AccessMode = .full
    @Published var accessModePopoverPresented = false
    @Published var toolPanel: ToolPanel = .launcher
    @Published var browserURL: URL?
    @Published var browserTitle = "浏览器"
    @Published var browserReloadToken = UUID()
    @Published var browserScreenshotStatusText = ""
    @Published var filePanelPath = ""
    @Published var fileEntries: [WorkspaceFileEntry] = []
    @Published var filePreview: FilePreview?
    @Published var filePanelStatusText = "未加载"
    @Published var terminalCommand = "pwd && ls -la"
    @Published var terminalRuns: [TerminalCommandRecord] = []
    @Published var terminalIsRunning = false
    @Published var runtimePlugins: [CodexRuntimePlugin] = []
    @Published var runtimeSkills: [CodexRuntimeSkill] = []
    @Published var runtimeHooks: [CodexRuntimeHook] = []
    @Published var runtimeMCPServers: [CodexRuntimeMCPServer] = []
    @Published var runtimeConfig: CodexRuntimeConfig?
    @Published var runtimeAccount: CodexRuntimeAccount?
    @Published var runtimeTokenUsage: CodexRuntimeTokenUsage?
    @Published var runtimeRateLimits: CodexRuntimeRateLimits?
    @Published var runtimeRequirements: CodexRuntimeConfigRequirements?
    @Published var runtimeRemoteControlStatus: CodexRuntimeRemoteControlStatus?
    @Published var runtimeApps: [CodexRuntimeAppInfo] = []
    @Published var runtimePermissionProfiles: [CodexRuntimePermissionProfile] = []
    @Published var archivedRuntimeThreads: [CodexRuntimeThreadSummary] = []
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
            approval: .onRequest
        )
        let demoThread = SampleData.demoThread(projectID: primaryProject.id)
        let debugThread = SampleData.debugThread(projectID: primaryProject.id)
        let secondary = SampleData.secondaryBundle(workspacePath: workspacePath)

        self.workspacePath = workspacePath
        self.filePanelPath = workspacePath
        self.model = localThread.model
        self.sandbox = localThread.sandbox
        self.approval = localThread.approval
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
        selectedProvider.usesSidecar ? "\(selectedProvider.displayName) › \(selectedProvider.model)" : (model.isEmpty ? selectedProvider.model : model)
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

    func selectThread(_ thread: ChatThread) {
        selectedThreadID = thread.id
        if let project = projects.first(where: { $0.id == thread.projectID }) {
            workspacePath = project.path
        }
        model = thread.model
        sandbox = thread.sandbox
        approval = thread.approval
        accessMode = Self.accessMode(for: thread.approval, sandbox: thread.sandbox)
        toolPanel = .launcher
        route = .thread
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

        isRunning = true
        prompt = ""

        updateSelectedThread { thread in
            thread.model = model
            thread.sandbox = sandbox
            thread.approval = approval
            thread.items.append(TranscriptItem(kind: .userMessage(trimmedPrompt)))
        }

        do {
            try await runPromptWithAppServer(trimmedPrompt)
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
            await runPromptWithExec(trimmedPrompt)
        }

        isRunning = false
        await refreshRuntime()
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
        case .autoReview:
            approval = .untrusted
            sandbox = .workspaceWrite
        case .full:
            approval = .never
            sandbox = .dangerFullAccess
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
        openToolPanel(.browser)
    }

    func openBrowserExternally() {
        guard let url = browserURL else { return }
        NSWorkspace.shared.open(url)
    }

    func newBrowserTab() {
        browserURL = nil
        browserTitle = "浏览器"
        browserScreenshotStatusText = ""
        openToolPanel(.browser)
    }

    func reloadBrowserPanel() {
        browserReloadToken = UUID()
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
            let modelIDs = models.map(\.id)
            if !modelIDs.isEmpty,
               let openAIIndex = providers.firstIndex(where: { $0.id == "openai" }) {
                providers[openAIIndex].models = modelIDs
                if model.isEmpty,
                   let defaultModel = models.first(where: \.isDefault)?.id ?? modelIDs.first {
                    model = defaultModel
                    providers[openAIIndex].model = defaultModel
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
                runtimeConfig = try await client.readConfig(cwd: workspacePath, includeLayers: true)
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
            runtimeConfig = try await client.readConfig(cwd: workspacePath, includeLayers: true)
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
        }
        route = .thread
        toolPanel = .launcher
    }

    func saveInstructions(_ instructions: String) async {
        runtimeCatalogStatusText = "正在写入 instructions…"
        do {
            let client = try await ensureAppServerClient(useProviderConfiguration: false)
            try await client.writeConfigValue(keyPath: "instructions", value: .string(instructions))
            runtimeCatalogStatusText = "instructions 已写入 config.toml"
            await refreshRuntimeCatalog(forceReloadSkills: false)
        } catch {
            runtimeCatalogStatusText = "写入失败：\(error.localizedDescription)"
            runtimeCatalogErrors = [error.localizedDescription]
        }
    }

    func openCodexConfigFile() {
        let configURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex")
            .appendingPathComponent("config.toml")
        try? FileManager.default.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if !FileManager.default.fileExists(atPath: configURL.path) {
            FileManager.default.createFile(atPath: configURL.path, contents: Data())
        }
        NSWorkspace.shared.open(configURL)
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
        guard let index = providers.firstIndex(where: { $0.id == providerID }) else { return }
        providers[index].model = model
        selectedProviderID = providerID
        self.model = providers[index].usesSidecar ? model : model
        Task { await resetAppServerForProviderChange() }
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
        var threadID = selectedThread.appServerThreadID

        if threadID == nil {
            let serverThread = try await client.startThread(options: options)
            updateSelectedThread { thread in
                thread.appServerThreadID = serverThread.id
                thread.appServerSessionID = serverThread.sessionID
            }
            threadID = serverThread.id
        }

        guard let threadID else {
            throw CodexAppServerError.invalidResponse("Missing app-server thread id.")
        }

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

        let environmentOverrides = useProviderConfiguration ? try await appServerEnvironmentOverrides() : [:]
        let environmentKey = useProviderConfiguration ? (environmentOverrides["CODEX_HOME"] ?? "global") : "global-tools"
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
            approvalPolicy: approval
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
                    thread.activeGoal = ActiveGoal(
                        title: thread.items.compactMap { item in
                            if case let .userMessage(text) = item.kind { return text }
                            return nil
                        }.last ?? "运行 Codex",
                        startedAt: Date(timeIntervalSince1970: TimeInterval(startedAt))
                    )
                }
            }
        case "turn/completed":
            isRunning = false
            activeAppServerTurnID = nil
            handleCompletedTurn(params?["turn"])
        case "turn/plan/updated":
            updateProgressSteps(params?["plan"]?.arrayValue ?? [])
        case "turn/diff/updated":
            if let diff = params?["diff"]?.stringValue {
                upsertDiffFileChanges(diff)
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
            Task { await refreshRuntimeCatalog(forceReloadSkills: method == "skills/changed") }
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
            upsertTranscriptItem(
                serverItemID: serverItemID,
                kind: .agentMessage(object["text"]?.stringValue ?? "")
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
        case "fileChange":
            upsertFileChanges(serverItemID: serverItemID, changes: object["changes"]?.arrayValue ?? [])
        default:
            break
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

    static func approvalName(_ policy: CodexApprovalPolicy) -> String {
        switch policy {
        case .never: "从不"
        case .onRequest: "按需"
        case .untrusted: "不受信任时"
        }
    }

    static func accessMode(for approval: CodexApprovalPolicy, sandbox: CodexSandboxMode) -> AccessMode {
        if sandbox == .dangerFullAccess {
            return .full
        }
        switch approval {
        case .onRequest: return .ask
        case .untrusted: return .autoReview
        case .never: return .autoReview
        }
    }
}
