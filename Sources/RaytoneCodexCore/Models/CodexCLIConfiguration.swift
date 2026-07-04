import Foundation

public struct CodexCLIConfiguration: Equatable, Sendable {
    public var executable: CodexExecutable
    public var workspaceURL: URL
    public var model: String?
    public var sandbox: CodexSandboxMode
    public var approvalPolicy: CodexApprovalPolicy

    public init(
        executable: CodexExecutable,
        workspaceURL: URL,
        model: String? = nil,
        sandbox: CodexSandboxMode = .readOnly,
        approvalPolicy: CodexApprovalPolicy = .never
    ) {
        self.executable = executable
        self.workspaceURL = workspaceURL
        self.model = model
        self.sandbox = sandbox
        self.approvalPolicy = approvalPolicy
    }
}

public struct CodexExecutable: Equatable, Sendable {
    public var url: URL
    public var source: CodexExecutableSource

    public init(url: URL, source: CodexExecutableSource) {
        self.url = url
        self.source = source
    }
}

public enum CodexExecutableSource: String, Equatable, Sendable {
    case appBundle = "Bundled in app"
    case environment = "Environment override"
    case officialCodexApp = "Installed Codex.app"
    case path = "PATH"
    case commonPath = "Common install path"
}

public enum CodexSandboxMode: String, CaseIterable, Equatable, Sendable {
    case readOnly = "read-only"
    case workspaceWrite = "workspace-write"
    case dangerFullAccess = "danger-full-access"

    public var displayName: String {
        switch self {
        case .readOnly:
            "Read only"
        case .workspaceWrite:
            "Workspace write"
        case .dangerFullAccess:
            "Full access"
        }
    }
}

public enum CodexApprovalPolicy: String, CaseIterable, Equatable, Sendable {
    case never
    case onRequest = "on-request"
    case untrusted

    public var displayName: String {
        switch self {
        case .never:
            "Never"
        case .onRequest:
            "On request"
        case .untrusted:
            "Untrusted"
        }
    }
}

public struct CodexCLIResult: Equatable, Sendable {
    public var exitCode: Int32
    public var stdout: String
    public var stderr: String
    public var finalMessage: String
    public var commandPreview: String
    public var outputFileURL: URL

    public init(
        exitCode: Int32,
        stdout: String,
        stderr: String,
        finalMessage: String,
        commandPreview: String,
        outputFileURL: URL
    ) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.finalMessage = finalMessage
        self.commandPreview = commandPreview
        self.outputFileURL = outputFileURL
    }
}

public struct CodexRuntimeSnapshot: Equatable, Sendable {
    public var executable: CodexExecutable?
    public var version: String?
    public var errorDescription: String?

    public init(
        executable: CodexExecutable?,
        version: String?,
        errorDescription: String? = nil
    ) {
        self.executable = executable
        self.version = version
        self.errorDescription = errorDescription
    }
}
