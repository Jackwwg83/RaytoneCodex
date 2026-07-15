import Foundation
import RaytoneCodexCore

/// A single row in a thread transcript. Models the rich item types a Codex-style
/// agent surfaces: plain messages, reasoning summaries, command executions,
/// file diffs, approval requests, and system notices.
struct TranscriptItem: Identifiable, Equatable {
    let id: UUID
    var timestamp: Date
    var kind: Kind

    init(id: UUID = UUID(), timestamp: Date = Date(), kind: Kind) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
    }

    enum Kind: Equatable {
        case userMessage(String)
        case agentMessage(String)        // markdown-ish text
        case reasoning(ReasoningBlock)
        case command(CommandRun)
        case fileChange(FileChange)
        case approval(ApprovalRequest)
        case mcpElicitation(McpElicitationRequest)
        case toolUserInput(ToolUserInputRequest)
        case notice(Notice)
    }
}

// MARK: - Reasoning

struct ReasoningBlock: Equatable {
    var title: String      // e.g. "Thought for 6s"
    var detail: String
}

// MARK: - Command execution

enum RunStatus: Equatable {
    case running
    case succeeded
    case failed
}

struct CommandRun: Identifiable, Equatable {
    let id: UUID
    var command: String
    var directory: String?
    var output: String
    var exitCode: Int32?
    var status: RunStatus

    init(
        id: UUID = UUID(),
        command: String,
        directory: String? = nil,
        output: String = "",
        exitCode: Int32? = nil,
        status: RunStatus = .running
    ) {
        self.id = id
        self.command = command
        self.directory = directory
        self.output = output
        self.exitCode = exitCode
        self.status = status
    }
}

// MARK: - File changes / diffs

enum FileChangeType: String, Equatable {
    case added = "Added"
    case modified = "Modified"
    case deleted = "Deleted"
    case renamed = "Renamed"

    var symbol: String {
        switch self {
        case .added: "plus.square"
        case .modified: "pencil"
        case .deleted: "minus.square"
        case .renamed: "arrow.triangle.swap"
        }
    }
}

struct DiffLine: Identifiable, Equatable {
    enum Kind: Equatable { case context, added, removed }

    let id: UUID
    var kind: Kind
    var text: String
    var oldLine: Int?
    var newLine: Int?

    init(id: UUID = UUID(), kind: Kind, text: String, oldLine: Int? = nil, newLine: Int? = nil) {
        self.id = id
        self.kind = kind
        self.text = text
        self.oldLine = oldLine
        self.newLine = newLine
    }
}

struct DiffHunk: Identifiable, Equatable {
    let id: UUID
    var header: String     // e.g. "@@ -1,5 +1,8 @@"
    var lines: [DiffLine]

    init(id: UUID = UUID(), header: String, lines: [DiffLine]) {
        self.id = id
        self.header = header
        self.lines = lines
    }
}

struct FileChange: Identifiable, Equatable {
    let id: UUID
    var path: String
    var type: FileChangeType
    var additions: Int
    var deletions: Int
    var hunks: [DiffHunk]

    init(
        id: UUID = UUID(),
        path: String,
        type: FileChangeType,
        additions: Int,
        deletions: Int,
        hunks: [DiffHunk] = []
    ) {
        self.id = id
        self.path = path
        self.type = type
        self.additions = additions
        self.deletions = deletions
        self.hunks = hunks
    }

    var fileName: String { (path as NSString).lastPathComponent }
}

// MARK: - Approvals

struct ApprovalRequest: Identifiable, Equatable {
    enum Kind: Equatable { case command, patch, network }
    enum Decision: Equatable { case pending, approved, approvedAlways, denied(note: String?) }

    let id: UUID
    var kind: Kind
    var title: String
    var detail: String
    var rationale: String?
    var command: String?
    var commandPrefix: String?
    var decision: Decision

    init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        detail: String,
        rationale: String? = nil,
        command: String? = nil,
        commandPrefix: String? = nil,
        decision: Decision = .pending
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.rationale = rationale
        self.command = command
        self.commandPrefix = commandPrefix
        self.decision = decision
    }

    var symbol: String {
        switch kind {
        case .command: "terminal"
        case .patch: "doc.badge.gearshape"
        case .network: "network"
        }
    }
}

// MARK: - MCP elicitation

struct McpElicitationRequest: Identifiable, Equatable {
    enum Mode: Equatable {
        case form
        case url
        case unknown(String)

        init(rawValue: String) {
            switch rawValue {
            case "form":
                self = .form
            case "url":
                self = .url
            default:
                self = .unknown(rawValue)
            }
        }

        var label: String {
            switch self {
            case .form: "表单"
            case .url: "链接"
            case let .unknown(raw): raw
            }
        }
    }

    enum Action: String, Equatable {
        case accept
        case decline
        case cancel
    }

    enum Status: Equatable {
        case pending
        case accepted
        case declined
        case cancelled
        case failed(String)
    }

    let id: UUID
    var serverName: String
    var threadID: String?
    var turnID: String?
    var message: String
    var mode: Mode
    var urlString: String?
    var requestedSchema: JSONValue?
    var status: Status

    init(
        id: UUID = UUID(),
        serverName: String,
        threadID: String? = nil,
        turnID: String? = nil,
        message: String,
        mode: Mode,
        urlString: String? = nil,
        requestedSchema: JSONValue? = nil,
        status: Status = .pending
    ) {
        self.id = id
        self.serverName = serverName
        self.threadID = threadID
        self.turnID = turnID
        self.message = message
        self.mode = mode
        self.urlString = urlString
        self.requestedSchema = requestedSchema
        self.status = status
    }

    var url: URL? {
        guard let urlString else { return nil }
        return URL(string: urlString)
    }
}

// MARK: - Tool user input

struct ToolUserInputOption: Identifiable, Equatable {
    let id: UUID
    var label: String
    var description: String

    init(id: UUID = UUID(), label: String, description: String) {
        self.id = id
        self.label = label
        self.description = description
    }
}

struct ToolUserInputQuestion: Identifiable, Equatable {
    var id: String
    var header: String
    var question: String
    var isOther: Bool
    var isSecret: Bool
    var options: [ToolUserInputOption]
}

struct ToolUserInputRequest: Identifiable, Equatable {
    enum Status: Equatable {
        case pending
        case submitted
        case skipped
        case cancelled
        case failed(String)
    }

    let id: UUID
    var threadID: String
    var turnID: String
    var itemID: String
    var questions: [ToolUserInputQuestion]
    var status: Status

    init(
        id: UUID = UUID(),
        threadID: String,
        turnID: String,
        itemID: String,
        questions: [ToolUserInputQuestion],
        status: Status = .pending
    ) {
        self.id = id
        self.threadID = threadID
        self.turnID = turnID
        self.itemID = itemID
        self.questions = questions
        self.status = status
    }
}

// MARK: - Notices

struct Notice: Equatable {
    enum Level: Equatable { case info, warning, error }

    var level: Level
    var text: String
}
