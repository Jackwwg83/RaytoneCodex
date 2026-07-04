import Foundation

public enum CodexCLIError: LocalizedError, Equatable, Sendable {
    case executableNotFound
    case nonZeroExit(code: Int32, stderr: String, stdout: String)

    public var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "Codex CLI executable was not found."
        case let .nonZeroExit(code, stderr, stdout):
            let detail = stderr.isEmpty ? stdout : stderr
            return "Codex CLI exited with code \(code). \(detail)"
        }
    }
}

public struct CodexRunOptions: Equatable, Sendable {
    public var workspaceURL: URL
    public var model: String?
    public var sandbox: CodexSandboxMode
    public var approvalPolicy: CodexApprovalPolicy

    public init(
        workspaceURL: URL,
        model: String? = nil,
        sandbox: CodexSandboxMode = .readOnly,
        approvalPolicy: CodexApprovalPolicy = .never
    ) {
        self.workspaceURL = workspaceURL
        self.model = model
        self.sandbox = sandbox
        self.approvalPolicy = approvalPolicy
    }
}

public struct CodexCLIService: @unchecked Sendable {
    public let resolver: CodexExecutableResolver
    public let runner: any ProcessRunning
    public let fileManager: FileManager

    public init(
        resolver: CodexExecutableResolver = CodexExecutableResolver(),
        runner: any ProcessRunning = FoundationProcessRunner(),
        fileManager: FileManager = .default
    ) {
        self.resolver = resolver
        self.runner = runner
        self.fileManager = fileManager
    }

    public func inspectRuntime() async -> CodexRuntimeSnapshot {
        guard let executable = resolver.resolve() else {
            return CodexRuntimeSnapshot(executable: nil, version: nil, errorDescription: CodexCLIError.executableNotFound.localizedDescription)
        }

        do {
            let result = try await runner.run(
                executableURL: executable.url,
                arguments: ["--version"],
                currentDirectoryURL: nil,
                environment: nil
            )
            let version = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            let fallback = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            return CodexRuntimeSnapshot(
                executable: executable,
                version: version.isEmpty ? fallback : version,
                errorDescription: result.exitCode == 0 ? nil : fallback
            )
        } catch {
            return CodexRuntimeSnapshot(executable: executable, version: nil, errorDescription: error.localizedDescription)
        }
    }

    public func run(prompt: String, options: CodexRunOptions) async throws -> CodexCLIResult {
        guard let executable = resolver.resolve() else {
            throw CodexCLIError.executableNotFound
        }

        let outputFileURL = fileManager.temporaryDirectory
            .appendingPathComponent("RaytoneCodex-\(UUID().uuidString)-last-message.txt")
        let arguments = makeExecArguments(prompt: prompt, options: options, outputFileURL: outputFileURL)
        let commandPreview = CommandLinePreview.render(executableURL: executable.url, arguments: arguments)

        let result = try await runner.run(
            executableURL: executable.url,
            arguments: arguments,
            currentDirectoryURL: options.workspaceURL,
            environment: nil
        )

        let finalMessage = (try? String(contentsOf: outputFileURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard result.exitCode == 0 else {
            throw CodexCLIError.nonZeroExit(code: result.exitCode, stderr: result.stderr, stdout: result.stdout)
        }

        return CodexCLIResult(
            exitCode: result.exitCode,
            stdout: result.stdout,
            stderr: result.stderr,
            finalMessage: finalMessage.isEmpty ? result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) : finalMessage,
            commandPreview: commandPreview,
            outputFileURL: outputFileURL
        )
    }

    public func makeExecArguments(prompt: String, options: CodexRunOptions, outputFileURL: URL) -> [String] {
        // Codex CLI 0.137+ defaults headless `exec` runs to never ask for approvals.
        // The older `--ask-for-approval` flag was removed from `codex exec`.
        var arguments = [
            "exec",
            "--skip-git-repo-check",
            "--sandbox",
            options.sandbox.rawValue,
            "--color",
            "never",
            "--output-last-message",
            outputFileURL.path,
            "--cd",
            options.workspaceURL.path
        ]

        if let model = options.model?.trimmingCharacters(in: .whitespacesAndNewlines), !model.isEmpty {
            arguments.append(contentsOf: ["--model", model])
        }

        arguments.append(prompt)
        return arguments
    }
}
