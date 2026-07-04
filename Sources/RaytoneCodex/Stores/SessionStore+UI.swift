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
        let appServerThreadID = threads.first(where: { $0.id == id })?.appServerThreadID
        let wasSelected = selectedThreadID == id
        threads.removeAll { $0.id == id }
        if wasSelected, let next = threads.first {
            selectThread(next)
        }
        if let appServerThreadID {
            Task { await archiveRuntimeThread(id: appServerThreadID) }
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
        updateSelectedThreadTitle(title)
    }

    private func updateSelectedThreadTitle(_ title: String) {
        guard let index = threads.firstIndex(where: { $0.id == selectedThreadID }) else {
            return
        }
        let appServerThreadID = threads[index].appServerThreadID
        threads[index].title = title
        threads[index].updatedAt = Date()
        if let appServerThreadID {
            Task { await setRuntimeThreadName(id: appServerThreadID, name: title) }
        }
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

    func editActiveGoalInComposer() {
        guard let goal = selectedThread.activeGoal else { return }
        prompt = goal.title
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
            openToolPanel(.terminal)
            terminalCommand = "pwd && ls Package.swift Sources script"
            Task { await runTerminalCommand() }
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
}
