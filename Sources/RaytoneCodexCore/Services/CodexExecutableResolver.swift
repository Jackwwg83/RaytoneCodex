import Foundation

public struct CodexExecutableResolver: @unchecked Sendable {
    public let environment: [String: String]
    public let pathString: String
    public let bundleResourceURL: URL?
    public let fileManager: FileManager

    public init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        pathString: String = ProcessInfo.processInfo.environment["PATH"] ?? "",
        bundleResourceURL: URL? = Bundle.main.resourceURL,
        fileManager: FileManager = .default
    ) {
        self.environment = environment
        self.pathString = pathString
        self.bundleResourceURL = bundleResourceURL
        self.fileManager = fileManager
    }

    public func resolve() -> CodexExecutable? {
        if let override = executableFromEnvironment() {
            return override
        }

        if let bundled = executableInAppBundle() {
            return bundled
        }

        if let officialApp = executableAt(
            URL(fileURLWithPath: "/Applications/Codex.app/Contents/Resources/codex"),
            source: .officialCodexApp
        ) {
            return officialApp
        }

        for pathComponent in pathString.split(separator: ":").map(String.init) {
            let candidate = URL(fileURLWithPath: pathComponent).appendingPathComponent("codex")
            if let executable = executableAt(candidate, source: .path) {
                return executable
            }
        }

        for candidatePath in ["/opt/homebrew/bin/codex", "/usr/local/bin/codex"] {
            if let executable = executableAt(URL(fileURLWithPath: candidatePath), source: .commonPath) {
                return executable
            }
        }

        return nil
    }

    private func executableFromEnvironment() -> CodexExecutable? {
        guard let rawPath = environment["RAYTONE_CODEX_CLI"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawPath.isEmpty
        else {
            return nil
        }

        return executableAt(URL(fileURLWithPath: rawPath), source: .environment)
    }

    private func executableInAppBundle() -> CodexExecutable? {
        guard let bundleResourceURL else {
            return nil
        }

        return executableAt(bundleResourceURL.appendingPathComponent("codex"), source: .appBundle)
    }

    private func executableAt(_ url: URL, source: CodexExecutableSource) -> CodexExecutable? {
        guard fileManager.isExecutableFile(atPath: url.path) else {
            return nil
        }

        return CodexExecutable(url: url, source: source)
    }
}
