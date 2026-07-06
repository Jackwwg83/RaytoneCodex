import Foundation
import RaytoneCodexCore

/// A workspace / repository the agent can operate in. Threads are grouped under
/// their project in the sidebar, mirroring the Codex desktop layout.
struct Project: Identifiable, Equatable {
    let id: UUID
    var name: String
    var path: String
    var branch: String?

    init(id: UUID = UUID(), name: String, path: String, branch: String? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.branch = branch
    }

    var shortPath: String { Project.abbreviate(path) }

    static func abbreviate(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path == home { return "~" }
        if path.hasPrefix(home + "/") { return "~" + path.dropFirst(home.count) }
        return path
    }
}

/// A single conversation thread. Each thread carries its own transcript and a
/// per-thread runtime configuration (model / sandbox / approval), just like a
/// Codex conversation.
struct ChatThread: Identifiable, Equatable {
    let id: UUID
    var title: String
    var projectID: UUID
    var items: [TranscriptItem]
    var model: String
    var sandbox: CodexSandboxMode
    var approval: CodexApprovalPolicy
    var approvalsReviewer: CodexApprovalsReviewer
    var personality: CodexPersonality
    var memoryMode: CodexThreadMemoryMode?
    var activeGoal: ActiveGoal?
    var progressSteps: [ProgressStep]
    var appServerThreadID: String?
    var appServerSessionID: String?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        projectID: UUID,
        items: [TranscriptItem] = [],
        model: String = "",
        sandbox: CodexSandboxMode = .workspaceWrite,
        approval: CodexApprovalPolicy = .onRequest,
        approvalsReviewer: CodexApprovalsReviewer = .user,
        personality: CodexPersonality = .friendly,
        memoryMode: CodexThreadMemoryMode? = nil,
        activeGoal: ActiveGoal? = nil,
        progressSteps: [ProgressStep] = [],
        appServerThreadID: String? = nil,
        appServerSessionID: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.projectID = projectID
        self.items = items
        self.model = model
        self.sandbox = sandbox
        self.approval = approval
        self.approvalsReviewer = approvalsReviewer
        self.personality = personality
        self.memoryMode = memoryMode
        self.activeGoal = activeGoal
        self.progressSteps = progressSteps
        self.appServerThreadID = appServerThreadID
        self.appServerSessionID = appServerSessionID
        self.updatedAt = updatedAt
    }

    /// Short subtitle shown under the thread title in the sidebar.
    var preview: String {
        for item in items.reversed() {
            switch item.kind {
            case let .userMessage(text): return text
            case let .agentMessage(text): return text
            case let .command(run): return run.command
            case let .fileChange(change): return "Edited \(change.fileName)"
            case let .approval(req): return req.title
            case let .reasoning(block): return block.title
            case let .notice(notice): return notice.text
            }
        }
        return "New thread"
    }

    var hasPendingApproval: Bool {
        items.contains { item in
            if case let .approval(req) = item.kind { return req.decision == .pending }
            return false
        }
    }
}

struct ActiveGoal: Equatable {
    var title: String
    var startedAt: Date
    var runtimeBacked: Bool

    init(title: String, startedAt: Date, runtimeBacked: Bool = false) {
        self.title = title
        self.startedAt = startedAt
        self.runtimeBacked = runtimeBacked
    }
}

struct BrowserNavigationCommand: Equatable {
    enum Action: Equatable {
        case back
        case forward
    }

    let id: UUID
    let action: Action

    init(id: UUID = UUID(), action: Action) {
        self.id = id
        self.action = action
    }
}

struct BrowserSnapshotRequest: Equatable {
    let id: UUID
    let outputURL: URL

    init(id: UUID = UUID(), outputURL: URL) {
        self.id = id
        self.outputURL = outputURL
    }
}

struct ProgressStep: Identifiable, Equatable {
    enum State: Equatable {
        case done
        case running
        case pending
    }

    let id: UUID
    var title: String
    var state: State

    init(id: UUID = UUID(), title: String, state: State) {
        self.id = id
        self.title = title
        self.state = state
    }
}

struct EnvironmentSourceFact: Identifiable, Equatable {
    var id: String { title }
    var symbol: String
    var title: String
    var detail: String
    var source: String
    var active: Bool
}

struct WorkspaceFileEntry: Identifiable, Equatable {
    var id: String { path }
    var name: String
    var path: String
    var isDirectory: Bool
    var isFile: Bool

    var symbol: String {
        isDirectory ? "folder" : "doc.text"
    }

    var subtitle: String {
        isDirectory ? "文件夹" : "文件"
    }
}

struct FilePreview: Equatable {
    var path: String
    var text: String
    var isTruncated: Bool
    var byteCount: Int = 0
    var modifiedAt: Date?
    var isSymlink: Bool = false

    var fileName: String {
        (path as NSString).lastPathComponent
    }

    var metadataSummary: String {
        var parts = ["\(byteCount.formatted()) 字节"]
        if let modifiedAt {
            parts.append("修改于 \(modifiedAt.formatted(date: .abbreviated, time: .shortened))")
        }
        if isSymlink {
            parts.append("符号链接")
        }
        return parts.joined(separator: " · ")
    }
}

struct FileOpenTargetRequest: Equatable {
    enum Target: String, Equatable {
        case finder = "Finder"
        case terminal = "Terminal"
        case iTerm2 = "iTerm2"
    }

    var target: Target
    var selectedPath: String
    var launchPath: String
    var applicationBundleIdentifier: String?
    var applicationName: String
}

struct TerminalCommandRecord: Identifiable, Equatable {
    enum Status: Equatable {
        case running
        case succeeded
        case failed
    }

    let id: UUID
    var command: String
    var output: String
    var exitCode: Int32?
    var status: Status
    var processID: String?

    init(
        id: UUID = UUID(),
        command: String,
        output: String = "",
        exitCode: Int32? = nil,
        status: Status = .running,
        processID: String? = nil
    ) {
        self.id = id
        self.command = command
        self.output = output
        self.exitCode = exitCode
        self.status = status
        self.processID = processID
    }
}

/// App-server / runtime connection state. Mirrors the Codex desktop connection
/// lifecycle (connected, login required, update required, not installed, …).
enum ConnectionState: Equatable {
    case connecting
    case connected(version: String)
    case disconnected
    case loginRequired
    case updateRequired
    case restartRequired
    case notInstalled
    case sidecarUnavailable(String)
    case providerKeyMissing(String)
    case providerUnauthorized(String)

    enum Severity { case ok, warning, error }

    var severity: Severity {
        switch self {
        case .connected: .ok
        case .connecting: .warning
        case .disconnected, .loginRequired, .updateRequired, .restartRequired: .warning
        case .notInstalled, .sidecarUnavailable, .providerKeyMissing, .providerUnauthorized: .error
        }
    }

    var title: String {
        switch self {
        case .connecting: "正在连接"
        case .connected: "已连接"
        case .disconnected: "连接已断开"
        case .loginRequired: "需要登录"
        case .updateRequired: "需要更新"
        case .restartRequired: "需要重启"
        case .notInstalled: "未找到 Codex CLI"
        case .sidecarUnavailable: "Provider sidecar 不可用"
        case .providerKeyMissing: "需要 Provider API Key"
        case .providerUnauthorized: "Provider 授权失败"
        }
    }

    var detail: String {
        switch self {
        case .connecting: "正在连接本机 Codex runtime…"
        case let .connected(version): version
        case .disconnected: "app-server 连接已丢失。"
        case .loginRequired: "登录 Codex 后才能启动会话。"
        case .updateRequired: "当前需要更新到较新的 Codex runtime。"
        case .restartRequired: "重启 runtime 后配置才会生效。"
        case .notInstalled: "请打包 Codex CLI，或安装 Codex.app。"
        case let .sidecarUnavailable(detail): detail
        case let .providerKeyMissing(provider): "请在「模型与提供方」里补充 \(provider) 的 API Key。"
        case let .providerUnauthorized(provider): "\(provider) 拒绝了当前 API Key，请更新后重新测试。"
        }
    }

    var symbol: String {
        switch self {
        case .connecting: "dot.radiowaves.left.and.right"
        case .connected: "checkmark.circle.fill"
        case .disconnected: "bolt.horizontal.circle"
        case .loginRequired: "person.crop.circle.badge.exclamationmark"
        case .updateRequired: "arrow.down.circle"
        case .restartRequired: "arrow.clockwise.circle"
        case .notInstalled: "exclamationmark.triangle"
        case .sidecarUnavailable: "externaldrive.badge.exclamationmark"
        case .providerKeyMissing: "key.horizontal"
        case .providerUnauthorized: "lock.trianglebadge.exclamationmark"
        }
    }

    var showsBanner: Bool {
        if case .connected = self { return false }
        if case .connecting = self { return false }
        return true
    }
}

/// A composer slash command. Matches the Codex command palette surface.
struct SlashCommand: Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var summary: String
    var symbol: String

    init(name: String, summary: String, symbol: String) {
        self.id = name
        self.name = name
        self.summary = summary
        self.symbol = symbol
    }

    static let all: [SlashCommand] = [
        SlashCommand(name: "/init", summary: "为当前项目生成 AGENTS.md", symbol: "doc.badge.plus"),
        SlashCommand(name: "/diff", summary: "查看当前工作区变更", symbol: "plus.forwardslash.minus"),
        SlashCommand(name: "/review", summary: "审查当前变更", symbol: "checklist"),
        SlashCommand(name: "/test", summary: "运行项目测试", symbol: "testtube.2"),
        SlashCommand(name: "/explain", summary: "解释文件或符号", symbol: "text.magnifyingglass"),
        SlashCommand(name: "/clear", summary: "开始新对话", symbol: "trash")
    ]
}

/// Right-hand inspector tabs (side panels).
enum InspectorTab: String, CaseIterable, Identifiable {
    case runtime = "运行时"
    case changes = "变更"
    case terminal = "终端"
    case files = "文件"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .runtime: "shippingbox"
        case .changes: "plus.forwardslash.minus"
        case .terminal: "terminal"
        case .files: "folder"
        }
    }
}
