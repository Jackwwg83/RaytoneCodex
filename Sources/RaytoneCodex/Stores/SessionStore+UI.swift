import AppKit
import Foundation
import RaytoneCodexCore

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
            sandbox: .dangerFullAccess,
            approval: approval,
            approvalsReviewer: approvalsReviewer,
            personality: personality
        )
        threads.insert(thread, at: 0)
        selectThread(thread)
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

    var messagingConnectionCount: Int {
        messagingConnectionNames.count
    }

    var messagingConnectionNames: [String] {
        connectedIntegrationNames(matching: [
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
        ])
    }

    var emailConnectionCount: Int {
        emailConnectionNames.count
    }

    var emailConnectionNames: [String] {
        connectedIntegrationNames(matching: [
            "gmail",
            "email",
            "mail",
            "outlook",
            "imap"
        ])
    }

    var workspaceFileConnectionCount: Int {
        fileEntries.filter { $0.isFile && !$0.name.hasPrefix(".") }.count
    }

    var messagingConnectionSubtitle: String {
        messagingConnectionCount > 0
            ? "已连接 \(messagingConnectionCount) 个消息来源"
            : "未发现已授权消息连接"
    }

    var emailConnectionSubtitle: String {
        emailConnectionCount > 0
            ? "已连接 \(emailConnectionCount) 个电子邮件来源"
            : "未发现已授权邮件连接"
    }

    var workspaceFileConnectionSubtitle: String {
        workspaceFileConnectionCount > 0
            ? "已读取 \(workspaceFileConnectionCount) 个工作区文件"
            : "正在读取工作区文件"
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

    /// One-time seeding of extra sample projects so the sidebar mirrors a real
    /// Codex workspace. Idempotent — guarded by a sentinel project name.
    func installSampleWorkspaceIfNeeded() {
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
                app.developer ?? ""
            ]
                .joined(separator: " ")
                .lowercased()
            return normalizedTokens.contains { haystack.contains($0) } ? app.name : nil
        }
        return Array(Set(connectedMCPServers + connectedApps)).sorted()
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
