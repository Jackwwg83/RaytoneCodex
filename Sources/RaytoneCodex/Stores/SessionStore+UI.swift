import AppKit
import Foundation
import RaytoneCodexCore

enum HomeConnectionKind: String, CaseIterable {
    case messaging
    case email
    case files

    var title: String {
        switch self {
        case .messaging: "连接消息传送"
        case .email: "连接电子邮件"
        case .files: "连接文件"
        }
    }

    var emptyText: String {
        switch self {
        case .messaging: "未发现已授权消息连接"
        case .email: "未发现已授权邮件连接"
        case .files: "未发现工作区文件"
        }
    }

    var matchTokens: [String] {
        switch self {
        case .messaging:
            [
                "slack",
                "dingtalk",
                "ding talk",
                "microsoft teams",
                "discord",
                "telegram",
                "whatsapp",
                "wechat",
                "飞书",
                "lark"
            ]
        case .email:
            [
                "gmail",
                "email",
                "mail",
                "outlook",
                "imap"
            ]
        case .files:
            [
                "drive",
                "file",
                "files",
                "folder",
                "documents",
                "文档",
                "文件"
            ]
        }
    }
}

/// Additive UI affordances layered on top of the core `SessionStore`: per-project
/// thread creation, deletion, approval decisions, and one-time sample seeding so
/// the sidebar resembles a real Codex workspace. Kept separate so the core store
/// stays focused on the runtime.
extension SessionStore {
    /// Create a fresh, empty thread in the given project and select it. The empty
    /// transcript surfaces the welcome / suggestion state.
    func newThread(in projectID: UUID) {
        let thread = ChatThread(
            title: "新对话",
            projectID: projectID,
            items: [],
            model: model,
            sandbox: sandbox,
            approval: approval,
            approvalsReviewer: approvalsReviewer,
            personality: personality
        )
        threads.insert(thread, at: 0)
        selectThread(thread)
    }

    /// Switch the empty hero composer to a different project without leaving a
    /// stranded local thread behind. If the current selection is already a real
    /// conversation, create a fresh thread in the target project instead.
    func selectProjectForNewThread(_ projectID: UUID) {
        guard let project = projects.first(where: { $0.id == projectID }) else {
            return
        }

        if let index = threads.firstIndex(where: { $0.id == selectedThreadID }),
           threads[index].items.isEmpty,
           threads[index].appServerThreadID == nil {
            threads[index].projectID = projectID
            threads[index].model = model
            threads[index].sandbox = sandbox
            threads[index].approval = approval
            threads[index].approvalsReviewer = approvalsReviewer
            threads[index].personality = personality
            threads[index].updatedAt = Date()
            selectedThreadID = threads[index].id
            syncSelectedThreadTokenUsage()
            workspacePath = project.path
            filePanelPath = project.path
            route = .thread
            toolPanel = .launcher
            Task {
                await refreshNewThreadHeroRuntime()
            }
            return
        }

        newThread(in: projectID)
        filePanelPath = project.path
        Task {
            await refreshNewThreadHeroRuntime()
        }
    }

    func selectProjectForSettings(_ projectID: UUID) {
        guard let project = projects.first(where: { $0.id == projectID }) else {
            return
        }
        let previousRoute = route
        let previousSettingsPane = settingsPane

        if let thread = threads.first(where: { $0.projectID == projectID }) {
            selectThread(thread)
        } else {
            newThread(in: projectID)
        }

        route = previousRoute
        settingsPane = previousSettingsPane
        workspacePath = project.path
        filePanelPath = project.path
        runtimeCatalogStatusText = "正在切换到 \(project.name)…"

        Task {
            await refreshWorkspaceBranches()
            await loadFilePanelDirectory(project.path)
            await refreshRuntimeConfiguration()
        }
    }

    /// Remove a thread. Keeps at least one thread alive and reselects if needed.
    func deleteThread(_ id: UUID) {
        guard threads.count > 1 else { return }
        let thread = threads.first(where: { $0.id == id })
        let appServerThreadID = thread?.appServerThreadID
        let projectPath = thread.flatMap { target in
            projects.first(where: { $0.id == target.projectID })?.path
        }
        let wasSelected = selectedThreadID == id
        threads.removeAll { $0.id == id }
        if let appServerThreadID {
            threadTokenUsageByThreadID[appServerThreadID] = nil
        }
        if wasSelected, let next = threads.first {
            selectThread(next)
        }
        if let appServerThreadID, let thread {
            Task {
                await archiveRuntimeThread(
                    id: appServerThreadID,
                    title: thread.title,
                    preview: thread.preview,
                    cwd: projectPath
                )
            }
        }
    }

    func duplicateSelectedThread() {
        let sourceAppServerThreadID = selectedThread.appServerThreadID
        let copy = ChatThread(
            title: "\(selectedThread.title) 副本",
            projectID: selectedThread.projectID,
            items: selectedThread.items,
            model: selectedThread.model,
            sandbox: selectedThread.sandbox,
            approval: selectedThread.approval,
            approvalsReviewer: selectedThread.approvalsReviewer,
            personality: selectedThread.personality,
            memoryMode: selectedThread.memoryMode,
            activeGoal: nil,
            progressSteps: selectedThread.progressSteps,
            appServerThreadID: nil,
            appServerSessionID: nil
        )
        let copyID = copy.id
        threads.insert(copy, at: 0)
        selectThread(copy)
        if let sourceAppServerThreadID {
            Task { await forkRuntimeThread(sourceThreadID: sourceAppServerThreadID, localCopyID: copyID) }
        }
    }

    func renameSelectedThread() {
        let alert = NSAlert()
        alert.messageText = "重命名对话"
        alert.informativeText = "输入新的对话名称。"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.stringValue = selectedThread.title
        alert.accessoryView = field

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let title = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        Task { await renameSelectedThread(to: title) }
    }

    @discardableResult
    func renameSelectedThread(to title: String) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return false }
        guard let index = threads.firstIndex(where: { $0.id == selectedThreadID }) else {
            return false
        }
        let appServerThreadID = threads[index].appServerThreadID
        threads[index].title = trimmedTitle
        threads[index].updatedAt = Date()
        if let appServerThreadID {
            await setRuntimeThreadName(id: appServerThreadID, name: trimmedTitle)
        }
        return true
    }

    /// Record an approve / deny decision on an approval request in the selected thread.
    func decideApproval(itemID: UUID, decision: ApprovalRequest.Decision) {
        guard let threadIndex = threads.firstIndex(where: { $0.id == selectedThreadID }),
              let itemIndex = threads[threadIndex].items.firstIndex(where: { $0.id == itemID }) else {
            return
        }
        if case .approval(var request) = threads[threadIndex].items[itemIndex].kind {
            request.decision = decision
            threads[threadIndex].items[itemIndex].kind = .approval(request)
            threads[threadIndex].updatedAt = Date()
            Task { await respondToAppServerApproval(itemID: itemID, decision: decision) }
        }
    }

    /// File changes referenced in the selected thread (for the changed-files bar).
    var pendingChanges: [FileChange] {
        selectedThread.items.compactMap {
            if case let .fileChange(change) = $0.kind { return change }
            return nil
        }
    }

    var pendingAdditions: Int {
        pendingChanges.reduce(0) { $0 + $1.additions }
    }

    var pendingDeletions: Int {
        pendingChanges.reduce(0) { $0 + $1.deletions }
    }

    /// Command executions in the selected thread.
    var commandRuns: [CommandRun] {
        selectedThread.items.compactMap {
            if case let .command(run) = $0.kind { return run }
            return nil
        }
    }

    var environmentSourceFacts: [EnvironmentSourceFact] {
        let commandFacts = commandRuns
        let lastCommand = commandFacts.last
        let commandDetail: String
        if let lastCommand {
            commandDetail = "\(commandFacts.count) 次 · \(Self.runStatusName(lastCommand.status))"
        } else {
            commandDetail = "当前 transcript 没有命令记录"
        }

        let browserDetail: String
        if let browserURL {
            browserDetail = browserTitle.isEmpty ? browserURL.absoluteString : browserTitle
        } else {
            browserDetail = "未打开网页"
        }

        let fileSource: String
        let fileDetail: String
        if let filePreview {
            fileSource = filePanelLastOperationSource.isEmpty
                ? "fs/readFile + fs/getMetadata"
                : filePanelLastOperationSource
            fileDetail = "\(filePreview.fileName) · \(filePreview.byteCount.formatted()) 字节"
        } else if !fileSearchResults.isEmpty {
            fileSource = filePanelLastOperationSource.isEmpty
                ? (fileSearchStatusText.contains("session") ? "fuzzyFileSearch/session" : "fuzzyFileSearch")
                : filePanelLastOperationSource
            fileDetail = "\(fileSearchResults.count) 个搜索结果"
        } else if !fileEntries.isEmpty {
            fileSource = filePanelLastOperationSource.isEmpty
                ? (filePanelStatusText.contains("已监听") ? "fs/readDirectory + fs/watch" : "fs/readDirectory")
                : filePanelLastOperationSource
            fileDetail = "\(fileEntries.count) 项 · \(Project.abbreviate(currentEnvironmentFilePanelPath))"
        } else {
            fileSource = "fs/readDirectory"
            fileDetail = "未读取文件面板"
        }

        let diffSummary = Self.diffSummary(workspaceGitDiff?.diff ?? "")
        let statusChangeCount = workspaceGitStatusText
            .split(separator: "\n", omittingEmptySubsequences: true)
            .filter { !$0.hasPrefix("##") }
            .count
        let changeDetail: String
        let changeSource: String
        if diffSummary.files > 0 {
            changeDetail = "\(diffSummary.files) 个文件 · +\(diffSummary.additions) −\(diffSummary.deletions)"
            changeSource = "command/exec git diff"
        } else if statusChangeCount > 0 {
            changeDetail = "Git 状态 \(statusChangeCount) 项"
            changeSource = "command/exec git status"
        } else if !pendingChanges.isEmpty {
            changeDetail = "\(pendingChanges.count) 个 transcript 文件变更"
            changeSource = "turn/diff/updated"
        } else {
            changeDetail = "无变更"
            changeSource = "command/exec git"
        }

        let lastTerminalRun = terminalRuns.last
        let terminalDetail: String
        if let lastTerminalRun {
            let exitText = lastTerminalRun.exitCode.map { "退出 \($0)" } ?? Self.terminalStatusName(lastTerminalRun.status)
            terminalDetail = "\(terminalRuns.count) 次 · \(exitText)"
        } else {
            terminalDetail = "未运行终端命令"
        }

        let selectedRuntimeThreadID = selectedThread.appServerThreadID ?? ""
        let selectedThreadLoaded = !selectedRuntimeThreadID.isEmpty && loadedRuntimeThreadIDs.contains(selectedRuntimeThreadID)
        let loadedThreadDetail = loadedRuntimeThreadIDs.isEmpty
            ? runtimeLoadedThreadsStatusText
            : "\(loadedRuntimeThreadIDs.count) 个 · \(selectedThreadLoaded ? "当前线程已加载" : "当前线程未加载")"
        let threadMetadataActive = runtimeThreadMetadataStatusText.hasPrefix("thread/metadata/update")
        let threadShellActive = threadShellCommandStatusText.hasPrefix("thread/shellCommand")
        let backgroundTerminalCleanActive = backgroundTerminalCleanStatusText.hasPrefix("thread/backgroundTerminals/clean")
        let sideChatRuntimeActive = sideChatStatusText.hasPrefix("thread/inject_items") ||
            sideChatStatusText.hasPrefix("正在通过 thread/inject_items") ||
            sideChatStatusText.hasPrefix("正在通过 turn/") ||
            sideChatStatusText.hasPrefix("已追加") ||
            sideChatStatusText == "Codex 已回复"
        let marketplaceRuntimeActive = runtimeCatalogStatusText.hasPrefix("marketplace/")
        let marketplaceSource: String
        if runtimeCatalogStatusText.hasPrefix("marketplace/add") {
            marketplaceSource = "marketplace/add"
        } else if runtimeCatalogStatusText.hasPrefix("marketplace/remove") {
            marketplaceSource = "marketplace/remove"
        } else if runtimeCatalogStatusText.hasPrefix("marketplace/upgrade") {
            marketplaceSource = "marketplace/upgrade"
        } else {
            marketplaceSource = "plugin/list"
        }

        return [
            EnvironmentSourceFact(
                symbol: "bubble.left.and.text.bubble.right",
                title: "线程",
                detail: loadedThreadDetail,
                source: "thread/loaded/list",
                active: selectedThreadLoaded || !loadedRuntimeThreadIDs.isEmpty
            ),
            EnvironmentSourceFact(
                symbol: "arrow.triangle.branch",
                title: "线程 Git",
                detail: runtimeThreadMetadataStatusText,
                source: "thread/metadata/update",
                active: threadMetadataActive
            ),
            EnvironmentSourceFact(
                symbol: "terminal",
                title: "线程 Shell",
                detail: threadShellCommandStatusText,
                source: "thread/shellCommand",
                active: threadShellActive
            ),
            EnvironmentSourceFact(
                symbol: "eraser",
                title: "后台终端",
                detail: backgroundTerminalCleanStatusText,
                source: "thread/backgroundTerminals/clean",
                active: backgroundTerminalCleanActive
            ),
            EnvironmentSourceFact(
                symbol: "plus.bubble",
                title: "侧边聊天",
                detail: sideChatStatusText,
                source: sideChatStatusText.hasPrefix("thread/inject_items") ||
                    sideChatStatusText.hasPrefix("正在通过 thread/inject_items") ? "thread/inject_items" : "turn/start|turn/steer",
                active: sideChatRuntimeActive
            ),
            EnvironmentSourceFact(
                symbol: "puzzlepiece.extension",
                title: "插件市场",
                detail: runtimeCatalogStatusText,
                source: marketplaceSource,
                active: marketplaceRuntimeActive || !runtimePlugins.isEmpty
            ),
            EnvironmentSourceFact(
                symbol: "command",
                title: "命令",
                detail: commandDetail,
                source: "item/commandExecution",
                active: !commandFacts.isEmpty
            ),
            EnvironmentSourceFact(
                symbol: "globe",
                title: "浏览器",
                detail: browserDetail,
                source: "WKWebView",
                active: browserURL != nil
            ),
            EnvironmentSourceFact(
                symbol: "folder",
                title: "文件",
                detail: fileDetail,
                source: fileSource,
                active: filePreview != nil || !fileSearchResults.isEmpty || !fileEntries.isEmpty
            ),
            EnvironmentSourceFact(
                symbol: "doc.text",
                title: "变更",
                detail: changeDetail,
                source: changeSource,
                active: diffSummary.files > 0 || statusChangeCount > 0 || !pendingChanges.isEmpty || workspaceGitDiff != nil
            ),
            EnvironmentSourceFact(
                symbol: "terminal",
                title: "终端",
                detail: terminalDetail,
                source: "command/exec",
                active: !terminalRuns.isEmpty
            )
        ]
    }

    private var currentEnvironmentFilePanelPath: String {
        filePanelPath.isEmpty ? workspacePath : filePanelPath
    }

    private static func runStatusName(_ status: RunStatus) -> String {
        switch status {
        case .running: "运行中"
        case .succeeded: "成功"
        case .failed: "失败"
        }
    }

    private static func terminalStatusName(_ status: TerminalCommandRecord.Status) -> String {
        switch status {
        case .running: "运行中"
        case .succeeded: "成功"
        case .failed: "失败"
        }
    }

    /// Files shown in the inspector launcher recommendation list. Prefer real
    /// runtime data from the current thread or workspace directory; fall back to
    /// common repo entrypoints only before the directory has loaded.
    var inspectorRecommendedFiles: [String] {
        let changed = pendingChanges.map(\.path)
        if !changed.isEmpty {
            return Array(changed.prefix(5))
        }

        let files = fileEntries.filter { $0.isFile && !$0.name.hasPrefix(".") }
        var selected: [String] = []
        let priorityNames = [
            "Package.swift",
            "README.md",
            "AGENTS.md",
            "package.json",
            "pyproject.toml",
            "Cargo.toml"
        ]

        for name in priorityNames {
            if let entry = files.first(where: { $0.name == name }),
               !selected.contains(entry.path) {
                selected.append(entry.path)
            }
        }

        let priorityPaths = [
            "Sources/RaytoneCodex/Views/ContentView.swift",
            "Sources/RaytoneCodex/Stores/SessionStore.swift",
            "docs/codex-screens-spec.md"
        ]
        for path in priorityPaths {
            let absolutePath = URL(fileURLWithPath: workspacePath)
                .appendingPathComponent(path)
                .standardizedFileURL
                .path
            if FileManager.default.fileExists(atPath: absolutePath),
               !selected.contains(absolutePath) {
                selected.append(absolutePath)
            }
        }

        for entry in files where !selected.contains(entry.path) {
            selected.append(entry.path)
        }

        if !selected.isEmpty {
            return Array(selected.prefix(5))
        }

        return [
            "Package.swift",
            "Sources/RaytoneCodex/Views/ContentView.swift",
            "docs/codex-screens-spec.md"
        ]
    }

    func tokenUsageActivityValues(scale: String) -> [Int] {
        let dailyValues = (runtimeTokenUsage?.dailyBuckets ?? [])
            .sorted { $0.startDate < $1.startDate }
            .map(\.tokens)

        switch scale {
        case "每周":
            return Self.weeklyUsageValues(from: dailyValues)
        case "累计":
            return Self.cumulativeUsageValues(from: Self.weeklyUsageValues(from: dailyValues))
        default:
            return Array(dailyValues.suffix(371))
        }
    }

    private static func weeklyUsageValues(from dailyValues: [Int]) -> [Int] {
        guard !dailyValues.isEmpty else { return [] }
        let recent = Array(dailyValues.suffix(371))
        var values: [Int] = []
        var index = 0
        while index < recent.count {
            let end = min(index + 7, recent.count)
            values.append(recent[index..<end].reduce(0, +))
            index = end
        }
        return Array(values.suffix(53))
    }

    private static func cumulativeUsageValues(from values: [Int]) -> [Int] {
        var running = 0
        return values.map { value in
            running += value
            return running
        }
    }

    var messagingConnectionCount: Int {
        messagingConnectionNames.count
    }

    var messagingConnectionNames: [String] {
        connectedIntegrationNames(matching: HomeConnectionKind.messaging.matchTokens)
    }

    var emailConnectionCount: Int {
        emailConnectionNames.count
    }

    var emailConnectionNames: [String] {
        connectedIntegrationNames(matching: HomeConnectionKind.email.matchTokens)
    }

    var workspaceFileConnectionCount: Int {
        fileEntries.filter { $0.isFile && !$0.name.hasPrefix(".") }.count
    }

    var messagingConnectionSubtitle: String {
        if messagingConnectionCount > 0 {
            return "已连接 \(messagingConnectionCount) 个消息来源"
        }
        if runtimeCatalogIsRefreshing {
            return "正在读取集成状态"
        }
        if homeConnectionsRefreshedAt == nil {
            return "等待读取消息连接"
        }
        if runtimeApps.isEmpty && runtimeMCPServers.isEmpty && !runtimeCatalogErrors.isEmpty {
            return "集成状态读取失败"
        }
        return "未发现已授权消息连接"
    }

    var emailConnectionSubtitle: String {
        if emailConnectionCount > 0 {
            return "已连接 \(emailConnectionCount) 个电子邮件来源"
        }
        if runtimeCatalogIsRefreshing {
            return "正在读取集成状态"
        }
        if homeConnectionsRefreshedAt == nil {
            return "等待读取邮件连接"
        }
        if runtimeApps.isEmpty && runtimeMCPServers.isEmpty && !runtimeCatalogErrors.isEmpty {
            return "集成状态读取失败"
        }
        return "未发现已授权邮件连接"
    }

    var workspaceFileConnectionSubtitle: String {
        if workspaceFileConnectionCount > 0 {
            return "已读取 \(workspaceFileConnectionCount) 个工作区文件"
        }
        if filePanelStatusText.hasPrefix("读取失败") {
            return "文件读取失败"
        }
        if filePanelStatusText == "未加载" {
            return "等待读取工作区文件"
        }
        return "正在读取工作区文件"
    }

    var chronicleRuntimeAvailable: Bool {
        if let server = chronicleMCPServer {
            return server.authStatus != "notLoggedIn" && server.authStatus != "unsupported"
        }
        return chronicleSkill?.enabled == true
    }

    var chronicleRuntimeStatusText: String {
        if let server = chronicleMCPServer {
            switch server.authStatus {
            case "notLoggedIn":
                return "未登录"
            case "unsupported":
                return "不可用"
            default:
                return "已连接"
            }
        }
        if let skill = chronicleSkill {
            return skill.enabled ? "技能已启用" : "技能已停用"
        }
        if runtimeSkills.isEmpty && runtimeMCPServers.isEmpty {
            return "未读取"
        }
        return "未检测到"
    }

    var chronicleRuntimeDetailText: String {
        if let server = chronicleMCPServer {
            return "mcpServerStatus/list：\(server.title) · \(server.authStatus)"
        }
        if let skill = chronicleSkill {
            return "skills/list：\(skill.displayName) · \(skill.scope)"
        }
        if runtimeSkills.isEmpty && runtimeMCPServers.isEmpty {
            return "等待读取 skills/list 和 mcpServerStatus/list"
        }
        return "当前 app-server catalog 没有返回 Chronicle 技能或 MCP 服务"
    }

    var chronicleRuntimeSourceText: String {
        chronicleMCPServer == nil ? "skills/list" : "mcpServerStatus/list"
    }

    var runtimeRealtimeVoicesSummary: String {
        guard let voices = runtimeRealtimeVoices else {
            return "voices 未读取"
        }
        let defaultVoice = voices.defaultV2.isEmpty ? voices.defaultV1 : voices.defaultV2
        return "v1 \(voices.v1.count) 个 · v2 \(voices.v2.count) 个 · 默认 \(defaultVoice.isEmpty ? "未返回" : defaultVoice)"
    }

    func openConnectionsSettings() {
        route = .settings
        settingsPane = .connections
        Task { await refreshIntegrationRuntime() }
    }

    @discardableResult
    func openHomeConnection(_ kind: HomeConnectionKind) async -> Bool {
        homeConnectionStatusText = "正在打开\(kind.title)…"

        switch kind {
        case .messaging, .email:
            route = .settings
            settingsPane = .connections
            await refreshIntegrationRuntime(forceRefetchApps: true)
            homeConnectionsRefreshedAt = Date()

            let names = kind == .messaging ? messagingConnectionNames : emailConnectionNames
            let connectionText = names.isEmpty ? kind.emptyText : names.joined(separator: "、")
            let ok = !runtimeCatalogStatusText.hasPrefix("集成状态读取失败")
            if ok, let app = preferredRuntimeApp(matching: kind.matchTokens) {
                let inserted = await useRuntimeAppInComposer(app)
                let actionText = inserted ? "已放入输入框" : "mention 解析失败"
                homeConnectionStatusText = "\(kind.title)：app/list \(runtimeApps.count) 个 · \(app.name) \(actionText) · \(connectionText)"
                return inserted
            }
            homeConnectionStatusText = "\(kind.title)：app/list \(runtimeApps.count) 个 · MCP \(runtimeMCPServers.count) 个 · \(connectionText)"
            return ok

        case .files:
            route = .thread
            showInspector = true
            toolPanel = .files
            await loadFilePanelDirectory(workspacePath)
            homeConnectionsRefreshedAt = Date()

            let ok = !filePanelStatusText.hasPrefix("读取失败")
            let fileText = workspaceFileConnectionCount > 0
                ? "文件 \(workspaceFileConnectionCount) 个 · \(filePanelStatusText)"
                : kind.emptyText
            homeConnectionStatusText = "\(kind.title)：fs/readDirectory \(Project.abbreviate(filePanelPath)) · \(fileText)"
            return ok
        }
    }

    func recoverConnection(
        from state: ConnectionState? = nil,
        openBrowserForLogin: Bool = true
    ) async {
        let currentState = state ?? connectionState
        switch currentState {
        case .loginRequired:
            route = .settings
            settingsPane = .usageBilling
            await startAccountChatGPTLogin(openBrowser: openBrowserForLogin)
        case .providerKeyMissing, .providerUnauthorized:
            route = .settings
            settingsPane = .modelsProviders
            providerConnectionStatusText = "请补充 Provider API Key 并测试连接"
        case .sidecarUnavailable:
            route = .settings
            settingsPane = .modelsProviders
            await refreshModelCatalog()
        case .notInstalled:
            route = .settings
            settingsPane = .general
            await refreshRuntime()
        case .disconnected, .restartRequired, .updateRequired:
            await refreshRuntime()
        case .connecting, .connected:
            break
        }
    }

    func promptEditActiveGoal() {
        guard let goal = selectedThread.activeGoal else { return }

        let alert = NSAlert()
        alert.messageText = "编辑目标"
        alert.informativeText = goal.runtimeBacked
            ? "这会通过 Codex app-server 调用 thread/goal/set 更新当前线程目标。"
            : "这会更新当前本地目标。"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        field.stringValue = goal.title
        alert.accessoryView = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { await updateActiveGoalObjective(field.stringValue) }
    }

    func editActiveGoalInComposer() {
        promptEditActiveGoal()
    }

    func clearActiveGoalLocally() {
        guard let index = threads.firstIndex(where: { $0.id == selectedThreadID }) else {
            return
        }
        threads[index].activeGoal = nil
        threads[index].updatedAt = Date()
    }

    /// One-time seeding of extra sample projects for UI screenshots and smoke
    /// fixtures. Normal app launches stay grounded in real runtime history.
    func installSampleWorkspaceIfNeeded() {
        guard Self.sampleWorkspaceEnabled else {
            return
        }

        let bundles = SampleData.extraWorkspace()
        // Idempotent: if the sample workspace is already present, do nothing.
        if let firstName = bundles.first?.project.name,
           projects.contains(where: { $0.name == firstName }) {
            return
        }
        for bundle in bundles where !projects.contains(where: { $0.name == bundle.project.name }) {
            projects.append(bundle.project)
            threads.append(contentsOf: bundle.threads)
        }
        // Open the richest thread so the first screen shows real Codex-style content.
        if let richest = threads.max(by: { $0.items.count < $1.items.count }),
           richest.items.count > 1 {
            selectThread(richest)
        }
    }

    func applyStartupScreenIfNeeded() {
        guard let screen = ProcessInfo.processInfo.environment["RAYTONE_CODEX_UI_SCREEN"]?.lowercased(),
              !screen.isEmpty else {
            return
        }

        accessModePopoverPresented = false
        toolPanel = .launcher

        switch screen {
        case "home", "start", "new-thread", "hero":
            newThread(in: selectedProject.id)
            model = ""
            route = .thread
        case "home-compact", "compact-composer", "bottom-panel-off":
            newThread(in: selectedProject.id)
            model = ""
            desktopShowBottomPanel = false
            accessModePopoverPresented = false
            route = .thread
        case "access", "access-popover":
            newThread(in: selectedProject.id)
            model = ""
            route = .thread
            chooseAccessMode(.full)
            accessModePopoverPresented = true
        case "thread", "active-thread":
            selectActiveDemoThreadForSmoke()
            route = .thread
            showInspector = true
            toolPanel = .launcher
        case "environment", "env", "env-panel":
            selectActiveDemoThreadForSmoke()
            route = .thread
            showInspector = true
            toolPanel = .launcher
        case "browser":
            selectActiveDemoThreadForSmoke()
            route = .thread
            showInspector = true
            openBrowserSample()
        case "files", "file-panel":
            selectActiveDemoThreadForSmoke()
            route = .thread
            showInspector = true
            openToolPanel(.files)
        case "terminal", "terminal-panel":
            selectActiveDemoThreadForSmoke()
            route = .thread
            showInspector = true
            desktopTerminalPosition = "右侧"
            openToolPanel(.terminal)
            terminalCommand = "pwd && ls Package.swift Sources script"
            Task { await runTerminalCommand() }
        case "terminal-bottom", "bottom-terminal":
            selectActiveDemoThreadForSmoke()
            route = .thread
            showInspector = true
            desktopTerminalPosition = "底部"
            openToolPanel(.terminal)
            terminalCommand = "pwd && ls Package.swift Sources script"
            Task { await runTerminalCommand() }
        case "side-chat", "sidechat", "side-chat-panel":
            selectActiveDemoThreadForSmoke()
            route = .thread
            showInspector = true
            openToolPanel(.sideChat)
            sideChatDraft = "继续检查这个改动的风险"
            sideChatStatusText = "已连接 Codex 侧边聊天"
        case "plugins":
            route = .plugins
        case "automation":
            route = .automation
        case "settings", "settings-general":
            route = .settings
            settingsPane = .general
        case "settings-models", "settings-providers", "settings-models-providers":
            route = .settings
            settingsPane = .modelsProviders
        case "settings-keyboard", "settings-keyboard-shortcuts":
            route = .settings
            settingsPane = .keyboardShortcuts
        case "settings-app-snapshots", "settings-snapshots":
            route = .settings
            settingsPane = .appSnapshots
        case "settings-browser":
            route = .settings
            settingsPane = .browser
        case "settings-computer", "settings-computer-control":
            route = .settings
            settingsPane = .computerControl
        case "settings-mcp", "settings-mcp-servers":
            route = .settings
            settingsPane = .mcpServers
        case "settings-hooks":
            route = .settings
            settingsPane = .hooks
        case "settings-connections":
            route = .settings
            settingsPane = .connections
        case "settings-environments":
            route = .settings
            settingsPane = .environments
        case "settings-worktrees":
            route = .settings
            settingsPane = .worktrees
        case "settings-usage", "settings-usage-billing":
            route = .settings
            settingsPane = .usageBilling
        case "settings-git":
            route = .settings
            settingsPane = .git
        case "settings-archived", "settings-archived-chats":
            route = .settings
            settingsPane = .archivedChats
        case "settings-profile":
            route = .settings
            settingsPane = .profile
        case "settings-config", "settings-configuration":
            route = .settings
            settingsPane = .configuration
            approval = .onRequest
            sandbox = .readOnly
            approvalsReviewer = .user
            accessMode = .ask
        case "settings-experimental", "settings-experimental-features":
            route = .settings
            settingsPane = .experimentalFeatures
        case "settings-personalization":
            route = .settings
            settingsPane = .personalization
        default:
            route = .thread
        }
    }

    func openBrowserSample() {
        let sampleURL = URL(fileURLWithPath: workspacePath)
            .appendingPathComponent("docs/browser-sample.html")
        browserURL = sampleURL
        browserTitle = "RaytoneCodex 本地示例"
        browserCanGoBack = false
        browserCanGoForward = false
        browserNavigationCommand = nil
        openToolPanel(.browser)
    }

    func openBrowserSampleAndCapture() {
        openBrowserSample()
        route = .thread
        browserScreenshotStatusText = "准备截取本地示例…"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            Task { @MainActor [weak self] in
                self?.captureBrowserPanelScreenshot()
            }
        }
    }

    private func selectActiveDemoThreadForSmoke() {
        if let activeThread = threads.first(where: { $0.activeGoal != nil }) {
            selectThread(activeThread)
            return
        }

        if let richest = threads.max(by: { $0.items.count < $1.items.count }),
           !richest.items.isEmpty {
            selectThread(richest)
        }
    }

    private func connectedIntegrationNames(matching tokens: [String]) -> [String] {
        let normalizedTokens = tokens.map { $0.lowercased() }
        let connectedMCPServers = runtimeMCPServers.compactMap { server -> String? in
            guard server.authStatus != "notLoggedIn",
                  server.authStatus != "unsupported" else {
                return nil
            }
            let haystack = ([server.name, server.title] + server.toolNames)
                .joined(separator: " ")
                .lowercased()
            return normalizedTokens.contains { haystack.contains($0) } ? server.title : nil
        }
        let connectedApps = runtimeApps.compactMap { app -> String? in
            guard app.isEnabled, app.isAccessible else {
                return nil
            }
            let haystack = [
                app.name,
                app.description ?? "",
                app.category ?? "",
                app.developer ?? "",
                app.pluginDisplayNames.joined(separator: " ")
            ]
                .joined(separator: " ")
                .lowercased()
            return normalizedTokens.contains { haystack.contains($0) } ? app.name : nil
        }
        return Array(Set(connectedMCPServers + connectedApps)).sorted()
    }

    private func preferredRuntimeApp(matching tokens: [String]) -> CodexRuntimeAppInfo? {
        let normalizedTokens = tokens.map { $0.lowercased() }
        return runtimeApps.first { app in
            guard app.isEnabled, app.isAccessible else {
                return false
            }
            let haystack = [
                app.id,
                app.name,
                app.description ?? "",
                app.category ?? "",
                app.developer ?? "",
                app.pluginDisplayNames.joined(separator: " ")
            ]
                .joined(separator: " ")
                .lowercased()
            return normalizedTokens.contains { haystack.contains($0) }
        }
    }

    private var chronicleSkill: CodexRuntimeSkill? {
        runtimeSkills.first { skill in
            let haystack = [skill.name, skill.displayName, skill.path]
                .joined(separator: " ")
                .lowercased()
            return haystack.contains("chronicle")
        }
    }

    private var chronicleMCPServer: CodexRuntimeMCPServer? {
        runtimeMCPServers.first { server in
            let haystack = [server.name, server.title]
                .joined(separator: " ")
                .lowercased()
            return haystack.contains("chronicle")
        }
    }
}
