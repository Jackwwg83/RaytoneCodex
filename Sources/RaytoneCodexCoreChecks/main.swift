import Foundation
import RaytoneCodexCore

@main
struct RaytoneCodexCoreChecks {
    static func main() async throws {
        try bundleExecutableWinsOverPathExecutable()
        try environmentOverrideWinsOverBundleExecutable()
        try await runBuildsCodexExecArgumentsAndReadsLastMessage()
        try await runtimeInspectionTrimsVersion()
        try await appServerClientSpeaksJSONLProtocol()
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

    private static func appServerClientSpeaksJSONLProtocol() async throws {
        let temp = try TemporaryDirectory()
        let workspace = try temp.createDirectory("workspace")
        let logURL = temp.url.appendingPathComponent("fake-app-server.jsonl")
        let fakeCodex = try temp.createExecutable(
            at: temp.url.appendingPathComponent("codex"),
            contents: fakeAppServerScript
        )
        let client = CodexAppServerClient(
            executable: CodexExecutable(url: fakeCodex, source: .environment),
            workspaceURL: workspace,
            environmentOverrides: ["RAYTONE_FAKE_APP_SERVER_LOG": logURL.path],
            experimentalApi: true
        )
        let eventTask = Task<Bool, Never> {
            for await event in client.events {
                if case let .notification(method, params) = event,
                   method == "turn/started",
                   params?["threadId"]?.stringValue == "thread-core-check" {
                    return true
                }
            }
            return false
        }

        let options = CodexAppServerOptions(
            workspaceURL: workspace,
            model: "gpt-core-check",
            sandbox: .dangerFullAccess,
            approvalPolicy: .never,
            approvalsReviewer: .autoReview
        )

        try await client.initialize()
        let thread = try await client.startThread(options: options)
        let turn = try await client.startTurn(
            threadID: thread.id,
            prompt: "Core protocol prompt",
            options: options
        )
        try await Task.sleep(nanoseconds: 200_000_000)
        await client.stop()

        try check(thread.id == "thread-core-check", "Expected thread/start response to decode")
        try check(thread.sessionID == "session-core-check", "Expected sessionId from thread/start response")
        try check(turn.id == "turn-core-check", "Expected turn/start response to decode")
        try check(turn.status == "inProgress", "Expected turn status from response")
        try check(await eventTask.value, "Expected turn/started notification from app-server stdout")

        let messages = try readJSONLLines(logURL)
        try check(messages.containsMethod("initialize"), "Expected initialize request")
        try check(messages.containsMethod("initialized"), "Expected initialized notification")
        let threadStart = try require(messages.firstMessage(method: "thread/start"), "Expected thread/start request")
        let turnStart = try require(messages.firstMessage(method: "turn/start"), "Expected turn/start request")

        try check(threadStart["jsonrpc"] == nil, "App-server JSONL must not include a jsonrpc field")
        try check(turnStart["jsonrpc"] == nil, "App-server JSONL must not include a jsonrpc field")
        let threadParams = try require(threadStart["params"] as? [String: Any], "Expected thread/start params")
        let dynamicTools = try require(threadParams["dynamicTools"] as? [[String: Any]], "Expected dynamic tools")
        try check(
            dynamicTools.contains { $0["namespace"] as? String == "raytone_context" && $0["name"] as? String == "workspace_snapshot" },
            "Expected Raytone dynamic tools to be registered on thread/start"
        )
        try check(threadParams["approvalPolicy"] as? String == "never", "Expected approval policy mapping")
        try check(threadParams["approvalsReviewer"] as? String == "auto_review", "Expected approval reviewer mapping")
        try check(threadParams["sandbox"] as? String == "danger-full-access", "Expected thread sandbox mapping")

        let turnParams = try require(turnStart["params"] as? [String: Any], "Expected turn/start params")
        try check(turnParams["threadId"] as? String == "thread-core-check", "Expected turn/start thread id")
        let sandboxPolicy = try require(turnParams["sandboxPolicy"] as? [String: Any], "Expected turn sandbox policy")
        try check(sandboxPolicy["type"] as? String == "dangerFullAccess", "Expected app-server sandbox policy")
        let input = try require(turnParams["input"] as? [[String: Any]], "Expected turn input array")
        try check(input.first?["text"] as? String == "Core protocol prompt", "Expected prompt text in turn input")
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

    private static func readJSONLLines(_ url: URL) throws -> [[String: Any]] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return try text
            .split(separator: "\n")
            .map { line in
                let data = Data(line.utf8)
                guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw CheckFailure("Expected JSON object line in fake app-server log")
                }
                return object
            }
    }

    private static let fakeAppServerScript = """
#!/usr/bin/env python3
import json
import os
import sys

log_path = os.environ["RAYTONE_FAKE_APP_SERVER_LOG"]

def write(message):
    sys.stdout.write(json.dumps(message, separators=(",", ":")) + "\\n")
    sys.stdout.flush()

with open(log_path, "a", encoding="utf-8") as log:
    for line in sys.stdin:
        text = line.strip()
        if not text:
            continue
        log.write(text + "\\n")
        log.flush()
        message = json.loads(text)
        method = message.get("method")
        request_id = message.get("id")
        if request_id is None:
            continue
        if method == "initialize":
            write({"id": request_id, "result": {"capabilities": {"experimentalApi": True}}})
        elif method == "thread/start":
            write({
                "id": request_id,
                "result": {
                    "thread": {
                        "id": "thread-core-check",
                        "sessionId": "session-core-check",
                        "preview": "Core app-server check",
                        "cliVersion": "codex-core-check"
                    }
                }
            })
        elif method == "turn/start":
            write({
                "method": "turn/started",
                "params": {
                    "threadId": "thread-core-check",
                    "turn": {"id": "turn-core-check", "status": "inProgress"}
                }
            })
            write({
                "id": request_id,
                "result": {"turn": {"id": "turn-core-check", "status": "inProgress"}}
            })
        else:
            write({
                "id": request_id,
                "error": {"code": -32601, "message": "unknown method " + str(method)}
            })
"""
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
        try createExecutable(at: url, contents: "#!/bin/sh\nexit 0\n")
    }

    func createExecutable(at url: URL, contents: String) throws -> URL {
        _ = FileManager.default.createFile(atPath: url.path, contents: Data(contents.utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        return url
    }
}

private extension Array where Element == [String: Any] {
    func containsMethod(_ method: String) -> Bool {
        firstMessage(method: method) != nil
    }

    func firstMessage(method: String) -> [String: Any]? {
        first { $0["method"] as? String == method }
    }
}
