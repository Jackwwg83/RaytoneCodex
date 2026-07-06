import Foundation

enum AccessMode: CaseIterable, Equatable, Identifiable {
    case ask
    case autoReview
    case full

    var id: Self { self }

    var title: String {
        switch self {
        case .ask: "请求批准"
        case .autoReview: "替我审批"
        case .full: "完全访问权限"
        }
    }

    var shortTitle: String {
        switch self {
        case .ask: "请求批准"
        case .autoReview: "替我审批"
        case .full: "完全访问"
        }
    }

    var description: String {
        switch self {
        case .ask:
            "编辑外部文件和使用互联网时始终询问"
        case .autoReview:
            "仅对检测到的风险操作请求批准"
        case .full:
            "可不受限制地访问互联网和您电脑上的任何文件"
        }
    }

    var symbol: String {
        switch self {
        case .ask: "hand.raised"
        case .autoReview: "checkmark.shield"
        case .full: "globe"
        }
    }

    var capsuleSymbol: String {
        switch self {
        case .full: "exclamationmark.triangle"
        default: symbol
        }
    }
}

enum ToolPanel: Equatable {
    case launcher
    case browser
    case files
    case terminal
    case sideChat
}

enum WorkspaceExecutionMode: Equatable {
    case local
    case cloudPending

    var title: String {
        switch self {
        case .local: "本地模式"
        case .cloudPending: "云端模式"
        }
    }
}

enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case modelsProviders
    case profile
    case appearance
    case configuration
    case experimentalFeatures
    case personalization
    case keyboardShortcuts
    case usageBilling
    case appSnapshots
    case mcpServers
    case browser
    case computerControl
    case hooks
    case connections
    case git
    case environments
    case worktrees
    case archivedChats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "常规"
        case .modelsProviders: "模型与提供方"
        case .profile: "个人资料"
        case .appearance: "外观"
        case .configuration: "配置"
        case .experimentalFeatures: "实验功能"
        case .personalization: "个性化"
        case .keyboardShortcuts: "键盘快捷键"
        case .usageBilling: "使用情况和计费"
        case .appSnapshots: "应用快照"
        case .mcpServers: "MCP 服务器"
        case .browser: "浏览器"
        case .computerControl: "电脑操控"
        case .hooks: "钩子"
        case .connections: "连接"
        case .git: "Git"
        case .environments: "环境"
        case .worktrees: "工作树"
        case .archivedChats: "已归档对话"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .modelsProviders: "cpu"
        case .profile: "person.circle"
        case .appearance: "sun.max"
        case .configuration: "slider.horizontal.3"
        case .experimentalFeatures: "testtube.2"
        case .personalization: "face.smiling"
        case .keyboardShortcuts: "keyboard"
        case .usageBilling: "chart.pie"
        case .appSnapshots: "rectangle.dashed"
        case .mcpServers: "point.3.connected.trianglepath.dotted"
        case .browser: "macwindow"
        case .computerControl: "cursorarrow.rays"
        case .hooks: "link"
        case .connections: "globe"
        case .git: "arrow.triangle.branch"
        case .environments: "square.stack"
        case .worktrees: "rectangle.split.3x1"
        case .archivedChats: "archivebox"
        }
    }
}

struct SettingsGroup: Identifiable {
    var id: String { title }
    var title: String
    var panes: [SettingsPane]

    static let all: [SettingsGroup] = [
        SettingsGroup(title: "个人", panes: [
            .general, .modelsProviders, .profile, .appearance, .configuration, .experimentalFeatures, .personalization,
            .keyboardShortcuts, .usageBilling
        ]),
        SettingsGroup(title: "集成", panes: [
            .appSnapshots, .mcpServers, .browser, .computerControl
        ]),
        SettingsGroup(title: "编码", panes: [
            .hooks, .connections, .git, .environments, .worktrees
        ]),
        SettingsGroup(title: "已归档", panes: [
            .archivedChats
        ])
    ]
}

struct Plugin: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var subtitle: String
    var symbol: String
    var installed: Bool

    static let featured: [Plugin] = [
        Plugin(name: "Computer Use", subtitle: "Control Mac apps from Codex", symbol: "sparkles.rectangle.stack", installed: true),
        Plugin(name: "Chrome", subtitle: "Control Chrome with Codex", symbol: "globe", installed: true),
        Plugin(name: "Spreadsheets", subtitle: "Create and edit spreadsheet files", symbol: "tablecells", installed: true),
        Plugin(name: "Presentations", subtitle: "Create and edit presentations", symbol: "rectangle.on.rectangle.angled", installed: true),
        Plugin(name: "GitHub", subtitle: "Triage PRs, issues, CI, and publish flows", symbol: "chevron.left.forwardslash.chevron.right", installed: true),
        Plugin(name: "Slack", subtitle: "Read and manage Slack", symbol: "number.square", installed: true),
        Plugin(name: "Data Analytics", subtitle: "Turn data into clear decisions", symbol: "chart.bar", installed: true),
        Plugin(name: "Product Design", subtitle: "Explore and prototype ideas", symbol: "square.on.circle", installed: true),
        Plugin(name: "Creative Production", subtitle: "Create marketing visuals from a brief…", symbol: "paintpalette", installed: true),
        Plugin(name: "Sales", subtitle: "Prepare sales work faster", symbol: "cart", installed: false),
        Plugin(name: "Investment Banking", subtitle: "M&A, capital markets, LevFin, valuatio…", symbol: "building.columns", installed: false),
        Plugin(name: "Public Equity Investing", subtitle: "Public equity PM research, long/short,…", symbol: "chart.line.uptrend.xyaxis", installed: false),
        Plugin(name: "Notion", subtitle: "Notion workflows for specs, research,…", symbol: "note.text", installed: false),
        Plugin(name: "Linear", subtitle: "Find and reference issues and projects.", symbol: "line.diagonal", installed: true)
    ]
}
