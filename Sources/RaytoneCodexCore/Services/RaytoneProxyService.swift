import Foundation

public struct RaytoneProxySession: Equatable, Sendable {
    public var port: Int
    public var baseURL: URL
    public var codexHomeURL: URL
    public var configURL: URL
    public var processIdentifier: Int32

    public init(port: Int, baseURL: URL, codexHomeURL: URL, configURL: URL, processIdentifier: Int32) {
        self.port = port
        self.baseURL = baseURL
        self.codexHomeURL = codexHomeURL
        self.configURL = configURL
        self.processIdentifier = processIdentifier
    }
}

public enum RaytoneProxyServiceError: LocalizedError, Sendable {
    case executableMissing(URL)
    case missingAPIKey(String)
    case launchFailed(String)
    case invalidListeningLine(String)
    case healthCheckFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .executableMissing(url):
            "Raytone provider sidecar is missing at \(url.path)."
        case let .missingAPIKey(provider):
            "Provider \(provider) is missing an API key."
        case let .launchFailed(message):
            "Raytone provider sidecar failed to launch. \(message)"
        case let .invalidListeningLine(line):
            "Raytone provider sidecar reported an invalid startup line: \(line)"
        case let .healthCheckFailed(message):
            "Raytone provider sidecar health check failed. \(message)"
        }
    }
}

public actor RaytoneProxyService {
    private var process: Process?
    private var stderrTask: Task<Void, Never>?
    private var sessionDirectory: URL?
    private var session: RaytoneProxySession?

    public init() {}

    public func start(
        executableURL: URL,
        provider: RaytoneProviderConfiguration,
        apiKey: String
    ) async throws -> RaytoneProxySession {
        if let session, process?.isRunning == true {
            return session
        }

        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw RaytoneProxyServiceError.executableMissing(executableURL)
        }
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RaytoneProxyServiceError.missingAPIKey(provider.displayName)
        }

        let sessionDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RaytoneCodex", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let codexHomeURL = sessionDirectory.appendingPathComponent("codex-home", isDirectory: true)
        try FileManager.default.createDirectory(at: codexHomeURL, withIntermediateDirectories: true)

        let proxyConfigURL = sessionDirectory.appendingPathComponent("raytone-proxy.toml")
        try proxyConfig(for: provider).write(to: proxyConfigURL, atomically: true, encoding: .utf8)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let launchedProcess = Process()
        launchedProcess.executableURL = executableURL
        launchedProcess.arguments = [
            "--host", "127.0.0.1",
            "--port", "0",
            "--config", proxyConfigURL.path,
            "--provider", provider.id
        ]
        var environment = ProcessInfo.processInfo.environment
        environment["RAYTONE_PROVIDER_API_KEY"] = apiKey
        launchedProcess.environment = environment
        launchedProcess.standardOutput = stdoutPipe
        launchedProcess.standardError = stderrPipe

        do {
            try launchedProcess.run()
        } catch {
            throw RaytoneProxyServiceError.launchFailed(error.localizedDescription)
        }

        self.process = launchedProcess
        self.sessionDirectory = sessionDirectory
        stderrTask = drain(handle: stderrPipe.fileHandleForReading)

        let listeningLine = try await Self.readFirstLine(from: stdoutPipe.fileHandleForReading)
        let port = try Self.parseListeningPort(listeningLine)
        let baseURL = URL(string: "http://127.0.0.1:\(port)/v1")!
        try writeCodexConfig(provider: provider, codexHomeURL: codexHomeURL, sidecarBaseURL: baseURL)
        try await healthCheck(port: port)

        let started = RaytoneProxySession(
            port: port,
            baseURL: baseURL,
            codexHomeURL: codexHomeURL,
            configURL: proxyConfigURL,
            processIdentifier: launchedProcess.processIdentifier
        )
        self.session = started
        return started
    }

    public func stop() {
        stderrTask?.cancel()
        stderrTask = nil
        if let process, process.isRunning {
            process.terminate()
        }
        process = nil
        session = nil
        if let sessionDirectory {
            try? FileManager.default.removeItem(at: sessionDirectory)
        }
        sessionDirectory = nil
    }

    private func healthCheck(port: Int) async throws {
        let url = URL(string: "http://127.0.0.1:\(port)/health")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RaytoneProxyServiceError.healthCheckFailed(String(data: data, encoding: .utf8) ?? "No response body.")
        }
    }

    private func writeCodexConfig(
        provider: RaytoneProviderConfiguration,
        codexHomeURL: URL,
        sidecarBaseURL: URL
    ) throws {
        let providerID = "raytone-\(provider.id)"
        var lines = [
            "model = \"\(Self.tomlEscape(provider.model))\"",
            "model_provider = \"\(Self.tomlEscape(providerID))\""
        ]
        if let reasoning = provider.reasoning {
            lines.append("model_reasoning_effort = \"\(reasoning.supportsThinking ? "medium" : "none")\"")
            lines.append("model_reasoning_summary = \"\(reasoning.supportsThinking ? "auto" : "none")\"")
        }
        lines.append(contentsOf: [
            "",
            "[model_providers.\(providerID)]",
            "name = \"\(Self.tomlEscape(provider.displayName)) (via Raytone)\"",
            "base_url = \"\(Self.tomlEscape(sidecarBaseURL.absoluteString))\"",
            "wire_api = \"responses\"",
            "requires_openai_auth = false",
            "supports_websockets = false"
        ])
        let config = lines.joined(separator: "\n") + "\n"
        try config.write(to: codexHomeURL.appendingPathComponent("config.toml"), atomically: true, encoding: .utf8)
    }

    private func proxyConfig(for provider: RaytoneProviderConfiguration) -> String {
        var lines: [String] = [
            "current_provider = \"\(Self.tomlEscape(provider.id))\"",
            "",
            "[[providers]]",
            "id = \"\(Self.tomlEscape(provider.id))\"",
            "name = \"\(Self.tomlEscape(provider.displayName))\"",
            "base_url = \"\(Self.tomlEscape(provider.baseURL))\"",
            "api_key_env = \"RAYTONE_PROVIDER_API_KEY\"",
            "model = \"\(Self.tomlEscape(provider.model))\"",
            "models = [\(provider.models.map { "\"\(Self.tomlEscape($0))\"" }.joined(separator: ", "))]"
        ]

        if let reasoning = provider.reasoning {
            lines.append(contentsOf: [
                "",
                "[providers.reasoning]",
                "supportsThinking = \(reasoning.supportsThinking)",
                "supportsEffort = \(reasoning.supportsEffort)",
                "thinkingParam = \"\(Self.tomlEscape(reasoning.thinkingParam))\"",
                "effortParam = \"\(Self.tomlEscape(reasoning.effortParam))\"",
                "outputFormat = \"\(Self.tomlEscape(reasoning.outputFormat))\""
            ])
            if let mode = reasoning.effortValueMode {
                lines.append("effortValueMode = \"\(Self.tomlEscape(mode))\"")
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private func drain(handle: FileHandle) -> Task<Void, Never> {
        Task.detached(priority: .utility) {
            while !Task.isCancelled {
                do {
                    guard let data = try handle.read(upToCount: 4096), !data.isEmpty else {
                        break
                    }
                } catch {
                    break
                }
            }
        }
    }

    private nonisolated static func readFirstLine(from handle: FileHandle) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                var data = Data()
                do {
                    while true {
                        guard let chunk = try handle.read(upToCount: 1), !chunk.isEmpty else {
                            throw RaytoneProxyServiceError.launchFailed("stdout closed before startup.")
                        }
                        if chunk.first == 0x0A {
                            let line = String(data: data, encoding: .utf8) ?? ""
                            continuation.resume(returning: line)
                            return
                        }
                        data.append(chunk)
                        if data.count > 16_384 {
                            throw RaytoneProxyServiceError.invalidListeningLine(String(data: data, encoding: .utf8) ?? "")
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private nonisolated static func parseListeningPort(_ line: String) throws -> Int {
        guard let data = line.data(using: .utf8),
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              object["event"] as? String == "listening",
              let port = object["port"] as? Int else {
            throw RaytoneProxyServiceError.invalidListeningLine(line)
        }
        return port
    }

    private nonisolated static func tomlEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
