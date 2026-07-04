import Foundation
import RaytoneCodexCore

@main
struct RaytoneCodexCoreChecks {
    static func main() async throws {
        try bundleExecutableWinsOverPathExecutable()
        try environmentOverrideWinsOverBundleExecutable()
        try await runBuildsCodexExecArgumentsAndReadsLastMessage()
        try await runtimeInspectionTrimsVersion()
        try quotesArgumentsWithWhitespace()
        print("RaytoneCodexCoreChecks: all checks passed")
    }

    private static func bundleExecutableWinsOverPathExecutable() throws {
        let temp = try TemporaryDirectory()
        let bundleResources = try temp.createDirectory("Resources")
        let pathBin = try temp.createDirectory("bin")
        let bundledCodex = try temp.createExecutable(at: bundleResources.appendingPathComponent("codex"))
        _ = try temp.createExecutable(at: pathBin.appendingPathComponent("codex"))

        let resolver = CodexExecutableResolver(
            environment: [:],
            pathString: pathBin.path,
            bundleResourceURL: bundleResources
        )

        let resolved = try require(resolver.resolve(), "Expected bundled executable")
        try check(resolved.url.path == bundledCodex.path, "Bundle executable should win over PATH executable")
        try check(resolved.source == .appBundle, "Expected appBundle source")
    }

    private static func environmentOverrideWinsOverBundleExecutable() throws {
        let temp = try TemporaryDirectory()
        let bundleResources = try temp.createDirectory("Resources")
        _ = try temp.createExecutable(at: bundleResources.appendingPathComponent("codex"))
        let override = try temp.createExecutable(at: temp.url.appendingPathComponent("custom-codex"))

        let resolver = CodexExecutableResolver(
            environment: ["RAYTONE_CODEX_CLI": override.path],
            pathString: "",
            bundleResourceURL: bundleResources
        )

        let resolved = try require(resolver.resolve(), "Expected override executable")
        try check(resolved.url.path == override.path, "Environment override should win")
        try check(resolved.source == .environment, "Expected environment source")
    }

    private static func runBuildsCodexExecArgumentsAndReadsLastMessage() async throws {
        let temp = try TemporaryDirectory()
        let codex = try temp.createExecutable(at: temp.url.appendingPathComponent("codex"))
        let workspace = try temp.createDirectory("workspace")
        let runner = CapturingRunner { invocation in
            guard let outputFlagIndex = invocation.arguments.firstIndex(of: "--output-last-message") else {
                return ProcessResult(exitCode: 2, stdout: "", stderr: "missing output flag")
            }
            let outputPathIndex = invocation.arguments.index(after: outputFlagIndex)
            let outputURL = URL(fileURLWithPath: invocation.arguments[outputPathIndex])
            try "RaytoneCodex fake final".write(to: outputURL, atomically: true, encoding: .utf8)
            return ProcessResult(exitCode: 0, stdout: "stdout stream", stderr: "")
        }
        let service = CodexCLIService(
            resolver: CodexExecutableResolver(environment: ["RAYTONE_CODEX_CLI": codex.path], pathString: "", bundleResourceURL: nil),
            runner: runner
        )

        let result = try await service.run(
            prompt: "Say hi",
            options: CodexRunOptions(workspaceURL: workspace, model: "gpt-test", sandbox: .readOnly, approvalPolicy: .never)
        )

        try check(result.finalMessage == "RaytoneCodex fake final", "Expected final message from output file")
        try check(runner.invocations.count == 1, "Expected one process invocation")
        let invocation = try require(runner.invocations.first, "Missing process invocation")
        try check(invocation.executableURL.path == codex.path, "Expected resolved codex path")
        try check(invocation.currentDirectoryURL?.path == workspace.path, "Expected workspace cwd")
        try check(invocation.arguments.starts(with: ["exec", "--skip-git-repo-check"]), "Expected codex exec prefix")
        try check(!invocation.arguments.contains("--ask-for-approval"), "codex exec 0.137+ removed the approval flag")
        try check(invocation.arguments.contains("--sandbox"), "Expected sandbox argument")
        try check(invocation.arguments.contains("read-only"), "Expected read-only sandbox")
        try check(invocation.arguments.contains("--model"), "Expected model flag")
        try check(invocation.arguments.contains("gpt-test"), "Expected model value")
        try check(invocation.arguments.last == "Say hi", "Expected prompt as final argument")
        try check(result.commandPreview.contains("codex exec"), "Expected readable command preview")
    }

    private static func runtimeInspectionTrimsVersion() async throws {
        let temp = try TemporaryDirectory()
        let codex = try temp.createExecutable(at: temp.url.appendingPathComponent("codex"))
        let runner = CapturingRunner { _ in
            ProcessResult(exitCode: 0, stdout: "codex-cli 9.9.9\n", stderr: "")
        }
        let service = CodexCLIService(
            resolver: CodexExecutableResolver(environment: ["RAYTONE_CODEX_CLI": codex.path], pathString: "", bundleResourceURL: nil),
            runner: runner
        )

        let snapshot = await service.inspectRuntime()

        try check(snapshot.version == "codex-cli 9.9.9", "Expected trimmed version")
        try check(snapshot.executable?.source == .environment, "Expected environment source")
    }

    private static func quotesArgumentsWithWhitespace() throws {
        let rendered = CommandLinePreview.render(
            executableURL: URL(fileURLWithPath: "/tmp/codex"),
            arguments: ["exec", "--cd", "/tmp/My Project", "It's fine"]
        )

        try check(
            rendered == #"/tmp/codex exec --cd '/tmp/My Project' 'It'\''s fine'"#,
            "Expected shell-safe quoting"
        )
    }

    private static func check(_ condition: Bool, _ message: String) throws {
        if !condition {
            throw CheckFailure(message)
        }
    }

    private static func require<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else {
            throw CheckFailure(message)
        }
        return value
    }
}

private struct CheckFailure: Error, CustomStringConvertible {
    var description: String

    init(_ description: String) {
        self.description = description
    }
}

private struct ProcessInvocation: Sendable {
    var executableURL: URL
    var arguments: [String]
    var currentDirectoryURL: URL?
    var environment: [String: String]?
}

private final class CapturingRunner: ProcessRunning, @unchecked Sendable {
    private let lock = NSLock()
    private let handler: @Sendable (ProcessInvocation) throws -> ProcessResult
    private var capturedInvocations: [ProcessInvocation] = []

    var invocations: [ProcessInvocation] {
        lock.withLock {
            capturedInvocations
        }
    }

    init(handler: @escaping @Sendable (ProcessInvocation) throws -> ProcessResult) {
        self.handler = handler
    }

    func run(
        executableURL: URL,
        arguments: [String],
        currentDirectoryURL: URL?,
        environment: [String: String]?
    ) async throws -> ProcessResult {
        let invocation = ProcessInvocation(
            executableURL: executableURL,
            arguments: arguments,
            currentDirectoryURL: currentDirectoryURL,
            environment: environment
        )
        lock.withLock {
            capturedInvocations.append(invocation)
        }
        return try handler(invocation)
    }
}

private struct TemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("RaytoneCodexChecks-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func createDirectory(_ name: String) throws -> URL {
        let directory = url.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func createExecutable(at url: URL) throws -> URL {
        _ = FileManager.default.createFile(atPath: url.path, contents: Data("#!/bin/sh\nexit 0\n".utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        return url
    }
}
