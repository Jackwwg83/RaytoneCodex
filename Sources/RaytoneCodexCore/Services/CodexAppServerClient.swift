import Foundation

public enum JSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .number(Double(value))
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .number(value):
            if value.rounded() == value, value >= Double(Int.min), value <= Double(Int.max) {
                try container.encode(Int(value))
            } else {
                try container.encode(value)
            }
        case let .bool(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    public var objectValue: [String: JSONValue]? {
        if case let .object(value) = self { value } else { nil }
    }

    public var arrayValue: [JSONValue]? {
        if case let .array(value) = self { value } else { nil }
    }

    public var stringValue: String? {
        if case let .string(value) = self { value } else { nil }
    }

    public var intValue: Int? {
        if case let .number(value) = self { Int(value) } else { nil }
    }

    public var boolValue: Bool? {
        if case let .bool(value) = self { value } else { nil }
    }

    public subscript(_ key: String) -> JSONValue? {
        objectValue?[key]
    }
}

public enum CodexAppServerRequestID: Codable, Hashable, Sendable, CustomStringConvertible {
    case number(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .number(value)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .number(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        }
    }

    public var description: String {
        switch self {
        case let .number(value): String(value)
        case let .string(value): value
        }
    }
}

public struct CodexAppServerRPCError: Codable, Equatable, Sendable, LocalizedError {
    public var code: Int?
    public var message: String
    public var data: JSONValue?

    public init(code: Int? = nil, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    public var errorDescription: String? { message }
}

public enum CodexAppServerError: LocalizedError, Sendable {
    case notRunning
    case invalidResponse(String)
    case processExited(Int32)
    case rpc(CodexAppServerRPCError)

    public var errorDescription: String? {
        switch self {
        case .notRunning:
            "Codex app-server is not running."
        case let .invalidResponse(detail):
            "Codex app-server returned an invalid response. \(detail)"
        case let .processExited(code):
            "Codex app-server exited with code \(code)."
        case let .rpc(error):
            error.localizedDescription
        }
    }
}

public struct CodexAppServerThread: Equatable, Sendable {
    public var id: String
    public var sessionID: String
    public var preview: String
    public var cliVersion: String?
    public var approvalPolicy: String?
    public var approvalsReviewer: CodexApprovalsReviewer?
    public var sandboxSummary: String?

    public init(
        id: String,
        sessionID: String,
        preview: String,
        cliVersion: String? = nil,
        approvalPolicy: String? = nil,
        approvalsReviewer: CodexApprovalsReviewer? = nil,
        sandboxSummary: String? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.preview = preview
        self.cliVersion = cliVersion
        self.approvalPolicy = approvalPolicy
        self.approvalsReviewer = approvalsReviewer
        self.sandboxSummary = sandboxSummary
    }
}

public struct CodexAppServerTurn: Equatable, Sendable {
    public var id: String
    public var status: String

    public init(id: String, status: String) {
        self.id = id
        self.status = status
    }
}

public enum CodexReviewDelivery: String, Sendable {
    case inline
    case detached
}

public enum CodexReviewTarget: Equatable, Sendable {
    case uncommittedChanges
    case baseBranch(String)
    case commit(sha: String, title: String?)
    case custom(instructions: String)

    fileprivate var jsonValue: JSONValue {
        switch self {
        case .uncommittedChanges:
            .object([
                "type": .string("uncommittedChanges")
            ])
        case let .baseBranch(branch):
            .object([
                "type": .string("baseBranch"),
                "branch": .string(branch)
            ])
        case let .commit(sha, title):
            .object([
                "type": .string("commit"),
                "sha": .string(sha),
                "title": title.map(JSONValue.string) ?? .null
            ])
        case let .custom(instructions):
            .object([
                "type": .string("custom"),
                "instructions": .string(instructions)
            ])
        }
    }
}

public struct CodexAppServerReview: Equatable, Sendable {
    public var reviewThreadID: String
    public var turn: CodexAppServerTurn

    public init(reviewThreadID: String, turn: CodexAppServerTurn) {
        self.reviewThreadID = reviewThreadID
        self.turn = turn
    }
}

public struct CodexReasoningEffortOption: Equatable, Sendable {
    public var effort: String
    public var description: String

    public init(effort: String, description: String) {
        self.effort = effort
        self.description = description
    }
}

public struct CodexAppServerModel: Equatable, Sendable, Identifiable {
    public var id: String
    public var model: String
    public var displayName: String
    public var description: String
    public var supportedReasoningEfforts: [CodexReasoningEffortOption]
    public var defaultReasoningEffort: String?
    public var inputModalities: [String]
    public var supportsPersonality: Bool
    public var isDefault: Bool

    public init(
        id: String,
        model: String,
        displayName: String,
        description: String,
        supportedReasoningEfforts: [CodexReasoningEffortOption],
        defaultReasoningEffort: String?,
        inputModalities: [String],
        supportsPersonality: Bool,
        isDefault: Bool
    ) {
        self.id = id
        self.model = model
        self.displayName = displayName
        self.description = description
        self.supportedReasoningEfforts = supportedReasoningEfforts
        self.defaultReasoningEffort = defaultReasoningEffort
        self.inputModalities = inputModalities
        self.supportsPersonality = supportsPersonality
        self.isDefault = isDefault
    }
}

public struct CodexDirectoryEntry: Equatable, Sendable, Identifiable {
    public var id: String { path }
    public var fileName: String
    public var path: String
    public var isDirectory: Bool
    public var isFile: Bool

    public init(fileName: String, path: String, isDirectory: Bool, isFile: Bool) {
        self.fileName = fileName
        self.path = path
        self.isDirectory = isDirectory
        self.isFile = isFile
    }
}

public struct CodexFuzzyFileSearchResult: Equatable, Sendable, Identifiable {
    public enum MatchType: String, Sendable {
        case file
        case directory
    }

    public var id: String { path }
    public var root: String
    public var relativePath: String
    public var path: String
    public var matchType: MatchType
    public var fileName: String
    public var score: Int
    public var indices: [Int]

    public var isDirectory: Bool { matchType == .directory }
    public var isFile: Bool { matchType == .file }

    public init(
        root: String,
        relativePath: String,
        path: String,
        matchType: MatchType,
        fileName: String,
        score: Int,
        indices: [Int]
    ) {
        self.root = root
        self.relativePath = relativePath
        self.path = path
        self.matchType = matchType
        self.fileName = fileName
        self.score = score
        self.indices = indices
    }
}

public struct CodexCommandExecResult: Equatable, Sendable {
    public var stdout: String
    public var stderr: String
    public var exitCode: Int32

    public init(stdout: String, stderr: String, exitCode: Int32) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }
}

public struct CodexRuntimePluginCatalog: Equatable, Sendable {
    public var plugins: [CodexRuntimePlugin]
    public var featuredPluginIds: [String]
    public var marketplaceLoadErrors: [String]

    public init(plugins: [CodexRuntimePlugin], featuredPluginIds: [String], marketplaceLoadErrors: [String]) {
        self.plugins = plugins
        self.featuredPluginIds = featuredPluginIds
        self.marketplaceLoadErrors = marketplaceLoadErrors
    }
}

public struct CodexRuntimePlugin: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var displayName: String
    public var summary: String
    public var marketplaceName: String
    public var marketplaceDisplayName: String
    public var marketplacePath: String?
    public var category: String?
    public var developerName: String?
    public var sourceType: String
    public var installPolicy: String
    public var authPolicy: String
    public var availability: String
    public var installed: Bool
    public var enabled: Bool

    public var mentionPath: String {
        "plugin://\(name)@\(marketplaceName)"
    }

    public init(
        id: String,
        name: String,
        displayName: String,
        summary: String,
        marketplaceName: String,
        marketplaceDisplayName: String,
        marketplacePath: String?,
        category: String?,
        developerName: String?,
        sourceType: String,
        installPolicy: String,
        authPolicy: String,
        availability: String,
        installed: Bool,
        enabled: Bool
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.summary = summary
        self.marketplaceName = marketplaceName
        self.marketplaceDisplayName = marketplaceDisplayName
        self.marketplacePath = marketplacePath
        self.category = category
        self.developerName = developerName
        self.sourceType = sourceType
        self.installPolicy = installPolicy
        self.authPolicy = authPolicy
        self.availability = availability
        self.installed = installed
        self.enabled = enabled
    }
}

public struct CodexAppServerMention: Equatable, Sendable {
    public var name: String
    public var path: String

    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

public struct CodexRuntimeSkillCatalog: Equatable, Sendable {
    public var skills: [CodexRuntimeSkill]
    public var errors: [String]

    public init(skills: [CodexRuntimeSkill], errors: [String]) {
        self.skills = skills
        self.errors = errors
    }
}

public struct CodexRuntimeSkill: Equatable, Sendable, Identifiable {
    public var id: String { path }
    public var name: String
    public var displayName: String
    public var summary: String
    public var path: String
    public var cwd: String
    public var scope: String
    public var enabled: Bool

    public init(name: String, displayName: String, summary: String, path: String, cwd: String, scope: String, enabled: Bool) {
        self.name = name
        self.displayName = displayName
        self.summary = summary
        self.path = path
        self.cwd = cwd
        self.scope = scope
        self.enabled = enabled
    }
}

public struct CodexRuntimeHookCatalog: Equatable, Sendable {
    public var hooks: [CodexRuntimeHook]
    public var warnings: [String]
    public var errors: [String]

    public init(hooks: [CodexRuntimeHook], warnings: [String], errors: [String]) {
        self.hooks = hooks
        self.warnings = warnings
        self.errors = errors
    }
}

public struct CodexRuntimeHook: Equatable, Sendable, Identifiable {
    public var id: String { key }
    public var key: String
    public var eventName: String
    public var handlerType: String
    public var command: String?
    public var matcher: String?
    public var source: String
    public var sourcePath: String
    public var trustStatus: String
    public var timeoutSec: Int
    public var enabled: Bool
    public var isManaged: Bool

    public init(
        key: String,
        eventName: String,
        handlerType: String,
        command: String?,
        matcher: String?,
        source: String,
        sourcePath: String,
        trustStatus: String,
        timeoutSec: Int,
        enabled: Bool,
        isManaged: Bool
    ) {
        self.key = key
        self.eventName = eventName
        self.handlerType = handlerType
        self.command = command
        self.matcher = matcher
        self.source = source
        self.sourcePath = sourcePath
        self.trustStatus = trustStatus
        self.timeoutSec = timeoutSec
        self.enabled = enabled
        self.isManaged = isManaged
    }
}

public struct CodexRuntimeMCPServerCatalog: Equatable, Sendable {
    public var servers: [CodexRuntimeMCPServer]
    public var nextCursor: String?

    public init(servers: [CodexRuntimeMCPServer], nextCursor: String?) {
        self.servers = servers
        self.nextCursor = nextCursor
    }
}

public struct CodexRuntimeMCPServer: Equatable, Sendable, Identifiable {
    public var id: String { name }
    public var name: String
    public var title: String
    public var version: String?
    public var authStatus: String
    public var toolNames: [String]
    public var resourceCount: Int
    public var resourceTemplateCount: Int

    public init(
        name: String,
        title: String,
        version: String?,
        authStatus: String,
        toolNames: [String],
        resourceCount: Int,
        resourceTemplateCount: Int
    ) {
        self.name = name
        self.title = title
        self.version = version
        self.authStatus = authStatus
        self.toolNames = toolNames
        self.resourceCount = resourceCount
        self.resourceTemplateCount = resourceTemplateCount
    }
}

public struct CodexMCPServerOAuthLogin: Equatable, Sendable {
    public var authorizationURL: URL

    public init(authorizationURL: URL) {
        self.authorizationURL = authorizationURL
    }
}

public struct CodexRuntimeDesktopSettings: Equatable, Sendable {
    public var showInMenuBar: Bool?
    public var showBottomPanel: Bool?
    public var preventSleepWhileRunning: Bool?
    public var terminalPosition: String?
    public var appearance: String?
    public var openTarget: String?
    public var language: String?

    public init(
        showInMenuBar: Bool? = nil,
        showBottomPanel: Bool? = nil,
        preventSleepWhileRunning: Bool? = nil,
        terminalPosition: String? = nil,
        appearance: String? = nil,
        openTarget: String? = nil,
        language: String? = nil
    ) {
        self.showInMenuBar = showInMenuBar
        self.showBottomPanel = showBottomPanel
        self.preventSleepWhileRunning = preventSleepWhileRunning
        self.terminalPosition = terminalPosition
        self.appearance = appearance
        self.openTarget = openTarget
        self.language = language
    }
}

public struct CodexRuntimeConfig: Equatable, Sendable {
    public var model: String?
    public var modelProvider: String?
    public var approvalPolicy: String?
    public var approvalsReviewer: String?
    public var sandboxMode: String?
    public var defaultPermissions: String?
    public var reasoningEffort: String?
    public var reasoningSummary: String?
    public var modelVerbosity: String?
    public var serviceTier: String?
    public var memoryGenerateMemories: Bool?
    public var memoryUseMemories: Bool?
    public var memoryDisableOnExternalContext: Bool?
    public var instructions: String?
    public var developerInstructions: String?
    public var desktopKeys: [String]
    public var desktopSettings: CodexRuntimeDesktopSettings
    public var layerCount: Int
    public var originKeys: [String]

    public init(
        model: String?,
        modelProvider: String?,
        approvalPolicy: String?,
        approvalsReviewer: String?,
        sandboxMode: String?,
        defaultPermissions: String?,
        reasoningEffort: String?,
        reasoningSummary: String?,
        modelVerbosity: String?,
        serviceTier: String?,
        memoryGenerateMemories: Bool?,
        memoryUseMemories: Bool?,
        memoryDisableOnExternalContext: Bool?,
        instructions: String?,
        developerInstructions: String?,
        desktopKeys: [String],
        desktopSettings: CodexRuntimeDesktopSettings,
        layerCount: Int,
        originKeys: [String]
    ) {
        self.model = model
        self.modelProvider = modelProvider
        self.approvalPolicy = approvalPolicy
        self.approvalsReviewer = approvalsReviewer
        self.sandboxMode = sandboxMode
        self.defaultPermissions = defaultPermissions
        self.reasoningEffort = reasoningEffort
        self.reasoningSummary = reasoningSummary
        self.modelVerbosity = modelVerbosity
        self.serviceTier = serviceTier
        self.memoryGenerateMemories = memoryGenerateMemories
        self.memoryUseMemories = memoryUseMemories
        self.memoryDisableOnExternalContext = memoryDisableOnExternalContext
        self.instructions = instructions
        self.developerInstructions = developerInstructions
        self.desktopKeys = desktopKeys
        self.desktopSettings = desktopSettings
        self.layerCount = layerCount
        self.originKeys = originKeys
    }
}

public struct CodexRuntimeAccount: Equatable, Sendable {
    public var kind: String
    public var email: String?
    public var planType: String?
    public var requiresOpenAIAuth: Bool

    public init(kind: String, email: String?, planType: String?, requiresOpenAIAuth: Bool) {
        self.kind = kind
        self.email = email
        self.planType = planType
        self.requiresOpenAIAuth = requiresOpenAIAuth
    }
}

public struct CodexRuntimeTokenUsage: Equatable, Sendable {
    public var lifetimeTokens: Int?
    public var peakDailyTokens: Int?
    public var longestRunningTurnSec: Int?
    public var currentStreakDays: Int?
    public var longestStreakDays: Int?
    public var dailyBuckets: [CodexRuntimeTokenUsageBucket]

    public init(
        lifetimeTokens: Int?,
        peakDailyTokens: Int?,
        longestRunningTurnSec: Int?,
        currentStreakDays: Int?,
        longestStreakDays: Int?,
        dailyBuckets: [CodexRuntimeTokenUsageBucket]
    ) {
        self.lifetimeTokens = lifetimeTokens
        self.peakDailyTokens = peakDailyTokens
        self.longestRunningTurnSec = longestRunningTurnSec
        self.currentStreakDays = currentStreakDays
        self.longestStreakDays = longestStreakDays
        self.dailyBuckets = dailyBuckets
    }
}

public struct CodexRuntimeTokenUsageBucket: Equatable, Sendable, Identifiable {
    public var id: String { startDate }
    public var startDate: String
    public var tokens: Int

    public init(startDate: String, tokens: Int) {
        self.startDate = startDate
        self.tokens = tokens
    }
}

public struct CodexRuntimeRateLimits: Equatable, Sendable {
    public var buckets: [CodexRuntimeRateLimitBucket]

    public init(buckets: [CodexRuntimeRateLimitBucket]) {
        self.buckets = buckets
    }
}

public struct CodexRuntimeRateLimitBucket: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var primary: CodexRuntimeRateLimitWindow?
    public var secondary: CodexRuntimeRateLimitWindow?
    public var creditsRemaining: Double?
    public var creditsUsed: Double?
    public var planType: String?
    public var reachedType: String?

    public init(
        id: String,
        name: String,
        primary: CodexRuntimeRateLimitWindow?,
        secondary: CodexRuntimeRateLimitWindow?,
        creditsRemaining: Double?,
        creditsUsed: Double?,
        planType: String?,
        reachedType: String?
    ) {
        self.id = id
        self.name = name
        self.primary = primary
        self.secondary = secondary
        self.creditsRemaining = creditsRemaining
        self.creditsUsed = creditsUsed
        self.planType = planType
        self.reachedType = reachedType
    }
}

public struct CodexRuntimeRateLimitWindow: Equatable, Sendable {
    public var usedPercent: Double?
    public var windowMinutes: Int?
    public var resetAt: String?

    public init(usedPercent: Double?, windowMinutes: Int?, resetAt: String?) {
        self.usedPercent = usedPercent
        self.windowMinutes = windowMinutes
        self.resetAt = resetAt
    }
}

public struct CodexRuntimeThreadCatalog: Equatable, Sendable {
    public var threads: [CodexRuntimeThreadSummary]
    public var nextCursor: String?
    public var backwardsCursor: String?

    public init(threads: [CodexRuntimeThreadSummary], nextCursor: String?, backwardsCursor: String?) {
        self.threads = threads
        self.nextCursor = nextCursor
        self.backwardsCursor = backwardsCursor
    }
}

public struct CodexRuntimeThreadSummary: Equatable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var preview: String
    public var cwd: String?
    public var modelProvider: String?
    public var source: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var archived: Bool
    public var gitBranch: String?
    public var gitSHA: String?
    public var gitOriginURL: String?

    public init(
        id: String,
        title: String,
        preview: String,
        cwd: String?,
        modelProvider: String?,
        source: String?,
        createdAt: String?,
        updatedAt: String?,
        archived: Bool,
        gitBranch: String?,
        gitSHA: String?,
        gitOriginURL: String?
    ) {
        self.id = id
        self.title = title
        self.preview = preview
        self.cwd = cwd
        self.modelProvider = modelProvider
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archived = archived
        self.gitBranch = gitBranch
        self.gitSHA = gitSHA
        self.gitOriginURL = gitOriginURL
    }
}

public enum CodexRuntimeGoalStatus: String, Equatable, Sendable {
    case active
    case paused
    case blocked
    case usageLimited
    case budgetLimited
    case complete
}

public struct CodexRuntimeGoal: Equatable, Sendable {
    public var threadID: String
    public var objective: String
    public var status: CodexRuntimeGoalStatus
    public var tokenBudget: Int?
    public var tokensUsed: Int
    public var timeUsedSeconds: Int
    public var createdAt: Int
    public var updatedAt: Int

    public init(
        threadID: String,
        objective: String,
        status: CodexRuntimeGoalStatus,
        tokenBudget: Int?,
        tokensUsed: Int,
        timeUsedSeconds: Int,
        createdAt: Int,
        updatedAt: Int
    ) {
        self.threadID = threadID
        self.objective = objective
        self.status = status
        self.tokenBudget = tokenBudget
        self.tokensUsed = tokensUsed
        self.timeUsedSeconds = timeUsedSeconds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CodexRuntimeGitDiff: Equatable, Sendable {
    public var sha: String?
    public var diff: String

    public init(sha: String?, diff: String) {
        self.sha = sha
        self.diff = diff
    }
}

public struct CodexConfigWriteEdit: Equatable, Sendable {
    public var keyPath: String
    public var value: JSONValue
    public var mergeStrategy: String

    public init(keyPath: String, value: JSONValue, mergeStrategy: String = "upsert") {
        self.keyPath = keyPath
        self.value = value
        self.mergeStrategy = mergeStrategy
    }
}

public struct CodexRuntimeConfigRequirements: Equatable, Sendable {
    public var allowedApprovalPolicies: [String]
    public var allowedSandboxModes: [String]
    public var allowedWebSearchModes: [String]
    public var defaultPermissions: String?
    public var allowAppSnapshots: Bool?
    public var allowLockedComputerUse: Bool?
    public var networkEnabled: Bool?
    public var managedHooksOnly: Bool?

    public init(
        allowedApprovalPolicies: [String],
        allowedSandboxModes: [String],
        allowedWebSearchModes: [String],
        defaultPermissions: String?,
        allowAppSnapshots: Bool?,
        allowLockedComputerUse: Bool?,
        networkEnabled: Bool?,
        managedHooksOnly: Bool?
    ) {
        self.allowedApprovalPolicies = allowedApprovalPolicies
        self.allowedSandboxModes = allowedSandboxModes
        self.allowedWebSearchModes = allowedWebSearchModes
        self.defaultPermissions = defaultPermissions
        self.allowAppSnapshots = allowAppSnapshots
        self.allowLockedComputerUse = allowLockedComputerUse
        self.networkEnabled = networkEnabled
        self.managedHooksOnly = managedHooksOnly
    }
}

public struct CodexRuntimeRemoteControlStatus: Equatable, Sendable {
    public var status: String
    public var serverName: String
    public var installationID: String
    public var environmentID: String?

    public init(status: String, serverName: String, installationID: String, environmentID: String?) {
        self.status = status
        self.serverName = serverName
        self.installationID = installationID
        self.environmentID = environmentID
    }
}

public struct CodexRuntimeAppCatalog: Equatable, Sendable {
    public var apps: [CodexRuntimeAppInfo]
    public var nextCursor: String?

    public init(apps: [CodexRuntimeAppInfo], nextCursor: String?) {
        self.apps = apps
        self.nextCursor = nextCursor
    }
}

public struct CodexRuntimeAppInfo: Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var description: String?
    public var category: String?
    public var developer: String?
    public var website: String?
    public var isAccessible: Bool
    public var isEnabled: Bool
    public var pluginDisplayNames: [String]
    public var screenshotPrompts: [String]

    public init(
        id: String,
        name: String,
        description: String?,
        category: String?,
        developer: String?,
        website: String?,
        isAccessible: Bool,
        isEnabled: Bool,
        pluginDisplayNames: [String],
        screenshotPrompts: [String]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.developer = developer
        self.website = website
        self.isAccessible = isAccessible
        self.isEnabled = isEnabled
        self.pluginDisplayNames = pluginDisplayNames
        self.screenshotPrompts = screenshotPrompts
    }
}

public struct CodexRuntimePermissionProfileCatalog: Equatable, Sendable {
    public var profiles: [CodexRuntimePermissionProfile]
    public var nextCursor: String?

    public init(profiles: [CodexRuntimePermissionProfile], nextCursor: String?) {
        self.profiles = profiles
        self.nextCursor = nextCursor
    }
}

public struct CodexRuntimePermissionProfile: Equatable, Sendable, Identifiable {
    public var id: String
    public var description: String?

    public init(id: String, description: String?) {
        self.id = id
        self.description = description
    }
}

public struct CodexAppServerOptions: Equatable, Sendable {
    public var workspaceURL: URL
    public var model: String?
    public var sandbox: CodexSandboxMode
    public var approvalPolicy: CodexApprovalPolicy
    public var approvalsReviewer: CodexApprovalsReviewer
    public var personality: CodexPersonality?

    public init(
        workspaceURL: URL,
        model: String? = nil,
        sandbox: CodexSandboxMode = .workspaceWrite,
        approvalPolicy: CodexApprovalPolicy = .onRequest,
        approvalsReviewer: CodexApprovalsReviewer = .user,
        personality: CodexPersonality? = nil
    ) {
        self.workspaceURL = workspaceURL
        self.model = model
        self.sandbox = sandbox
        self.approvalPolicy = approvalPolicy
        self.approvalsReviewer = approvalsReviewer
        self.personality = personality
    }
}

public enum CodexAppServerApprovalDecision: String, Sendable {
    case accept
    case acceptForSession
    case decline
    case cancel
}

public enum ServerEvent: Sendable {
    case notification(method: String, params: JSONValue?)
    case serverRequest(id: CodexAppServerRequestID, method: String, params: JSONValue?)
    case stderr(String)
    case exited(Int32)
}

private struct CodexAppServerMessage: Codable {
    var id: CodexAppServerRequestID?
    var method: String?
    var params: JSONValue?
    var result: JSONValue?
    var error: CodexAppServerRPCError?

    init(
        id: CodexAppServerRequestID? = nil,
        method: String? = nil,
        params: JSONValue? = nil,
        result: JSONValue? = nil,
        error: CodexAppServerRPCError? = nil
    ) {
        self.id = id
        self.method = method
        self.params = params
        self.result = result
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case id
        case method
        case params
        case result
        case error
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(method, forKey: .method)
        try container.encodeIfPresent(params, forKey: .params)
        try container.encodeIfPresent(result, forKey: .result)
        try container.encodeIfPresent(error, forKey: .error)
    }
}

public actor CodexAppServerClient {
    public nonisolated let events: AsyncStream<ServerEvent>

    private let executable: CodexExecutable
    private let workspaceURL: URL
    private let environmentOverrides: [String: String]
    private let experimentalApi: Bool
    private let eventContinuation: AsyncStream<ServerEvent>.Continuation
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let debugEnabled: Bool

    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var stdinHandle: FileHandle?
    private var stdoutTask: Task<Void, Never>?
    private var stderrTask: Task<Void, Never>?
    private var pending: [CodexAppServerRequestID: CheckedContinuation<JSONValue, Error>] = [:]
    private var nextRequestNumber = 1
    private var didInitialize = false
    private var isInitializing = false

    public init(
        executable: CodexExecutable,
        workspaceURL: URL,
        environmentOverrides: [String: String] = [:],
        experimentalApi: Bool = true
    ) {
        self.executable = executable
        self.workspaceURL = workspaceURL
        self.environmentOverrides = environmentOverrides
        self.experimentalApi = experimentalApi
        self.debugEnabled = ProcessInfo.processInfo.environment["RAYTONE_CODEX_APP_SERVER_DEBUG"] == "1"
        let stream = AsyncStream<ServerEvent>.makeStream()
        self.events = stream.stream
        self.eventContinuation = stream.continuation
    }

    public func start() throws {
        if process != nil {
            return
        }

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let launchedProcess = Process()
        launchedProcess.executableURL = executable.url
        launchedProcess.arguments = ["app-server", "--listen", "stdio://"]
        launchedProcess.currentDirectoryURL = workspaceURL
        launchedProcess.standardInput = stdinPipe
        launchedProcess.standardOutput = stdoutPipe
        launchedProcess.standardError = stderrPipe
        launchedProcess.environment = ProcessInfo.processInfo.environment.merging(environmentOverrides) { _, new in new }
        launchedProcess.terminationHandler = { [weak self] process in
            Task { await self?.processDidExit(process.terminationStatus) }
        }

        try launchedProcess.run()
        debugLog("started \(executable.url.path)")
        process = launchedProcess
        self.stdinPipe = stdinPipe
        self.stdoutPipe = stdoutPipe
        self.stderrPipe = stderrPipe
        stdinHandle = stdinPipe.fileHandleForWriting
        stdoutTask = readLines(from: stdoutPipe.fileHandleForReading, isStdout: true)
        stderrTask = readLines(from: stderrPipe.fileHandleForReading, isStdout: false)
    }

    public func initialize() async throws {
        try start()
        guard !didInitialize else {
            return
        }

        while isInitializing {
            try await Task.sleep(nanoseconds: 50_000_000)
            if didInitialize {
                return
            }
        }

        isInitializing = true
        defer { isInitializing = false }

        let params: JSONValue = .object([
            "clientInfo": .object([
                "name": .string("RaytoneCodex"),
                "title": .string("RaytoneCodex"),
                "version": .string("0.1.0")
            ]),
            "capabilities": .object([
                "experimentalApi": .bool(experimentalApi),
                "optOutNotificationMethods": .array([])
            ])
        ])
        _ = try await request(method: "initialize", params: params)
        try notify(method: "initialized", params: .object([:]))
        didInitialize = true
    }

    public func startThread(options: CodexAppServerOptions) async throws -> CodexAppServerThread {
        var params: [String: JSONValue] = [
            "cwd": .string(options.workspaceURL.path),
            "approvalPolicy": .string(options.approvalPolicy.appServerValue),
            "approvalsReviewer": .string(options.approvalsReviewer.rawValue),
            "sandbox": .string(options.sandbox.rawValue),
            "serviceName": .string("RaytoneCodex"),
            "sessionStartSource": .string("startup")
        ]
        if let model = options.model?.trimmingCharacters(in: .whitespacesAndNewlines), !model.isEmpty {
            params["model"] = .string(model)
        }
        if let personality = options.personality {
            params["personality"] = .string(personality.rawValue)
        }

        let result = try await request(method: "thread/start", params: .object(params))
        guard let thread = result["thread"]?.objectValue else {
            throw CodexAppServerError.invalidResponse("Missing thread payload.")
        }

        guard let threadID = thread["id"]?.stringValue,
              let sessionID = thread["sessionId"]?.stringValue else {
            throw CodexAppServerError.invalidResponse("Missing thread id or sessionId.")
        }

        return CodexAppServerThread(
            id: threadID,
            sessionID: sessionID,
            preview: thread["preview"]?.stringValue ?? "",
            cliVersion: thread["cliVersion"]?.stringValue,
            approvalPolicy: Self.stringDescription(from: result["approvalPolicy"]),
            approvalsReviewer: Self.approvalsReviewer(from: result["approvalsReviewer"]),
            sandboxSummary: Self.stringDescription(from: result["sandbox"])
        )
    }

    public func startTurn(
        threadID: String,
        prompt: String,
        options: CodexAppServerOptions,
        mentions: [CodexAppServerMention] = [],
        localImagePaths: [String] = []
    ) async throws -> CodexAppServerTurn {
        var params: [String: JSONValue] = [
            "threadId": .string(threadID),
            "input": Self.userInputItems(
                prompt: prompt,
                mentions: mentions,
                localImagePaths: localImagePaths
            ),
            "cwd": .string(options.workspaceURL.path),
            "approvalPolicy": .string(options.approvalPolicy.appServerValue),
            "approvalsReviewer": .string(options.approvalsReviewer.rawValue),
            "sandboxPolicy": options.sandbox.appServerSandboxPolicy
        ]
        if let model = options.model?.trimmingCharacters(in: .whitespacesAndNewlines), !model.isEmpty {
            params["model"] = .string(model)
        }
        if let personality = options.personality {
            params["personality"] = .string(personality.rawValue)
        }

        let result = try await request(method: "turn/start", params: .object(params))
        guard let turn = result["turn"]?.objectValue,
              let turnID = turn["id"]?.stringValue else {
            throw CodexAppServerError.invalidResponse("Missing turn payload.")
        }

        return CodexAppServerTurn(
            id: turnID,
            status: turn["status"]?.stringValue ?? "inProgress"
        )
    }

    public func startReview(
        threadID: String,
        target: CodexReviewTarget,
        delivery: CodexReviewDelivery = .inline
    ) async throws -> CodexAppServerReview {
        let result = try await request(method: "review/start", params: .object([
            "threadId": .string(threadID),
            "delivery": .string(delivery.rawValue),
            "target": target.jsonValue
        ]))
        guard let turn = result["turn"]?.objectValue,
              let turnID = turn["id"]?.stringValue else {
            throw CodexAppServerError.invalidResponse("Missing review/start turn payload.")
        }

        return CodexAppServerReview(
            reviewThreadID: result["reviewThreadId"]?.stringValue ?? threadID,
            turn: CodexAppServerTurn(
                id: turnID,
                status: turn["status"]?.stringValue ?? "inProgress"
            )
        )
    }

    public func steer(
        threadID: String,
        expectedTurnID: String,
        prompt: String,
        mentions: [CodexAppServerMention] = [],
        localImagePaths: [String] = []
    ) async throws {
        let params: JSONValue = .object([
            "threadId": .string(threadID),
            "expectedTurnId": .string(expectedTurnID),
            "input": Self.userInputItems(
                prompt: prompt,
                mentions: mentions,
                localImagePaths: localImagePaths
            )
        ])
        _ = try await request(method: "turn/steer", params: params)
    }

    public static func userInputItems(
        prompt: String,
        mentions: [CodexAppServerMention] = [],
        localImagePaths: [String] = []
    ) -> JSONValue {
        var items: [JSONValue] = [
            .object([
                "type": .string("text"),
                "text": .string(prompt),
                "text_elements": .array([])
            ])
        ]
        items.append(contentsOf: mentions.map { mention in
            .object([
                "type": .string("mention"),
                "name": .string(mention.name),
                "path": .string(mention.path)
            ])
        })
        items.append(contentsOf: localImagePaths.map { path in
            .object([
                "type": .string("localImage"),
                "path": .string(path)
            ])
        })
        return .array(items)
    }

    public func interrupt(threadID: String, turnID: String) async throws {
        let params: JSONValue = .object([
            "threadId": .string(threadID),
            "turnId": .string(turnID)
        ])
        _ = try await request(method: "turn/interrupt", params: params)
    }

    public func listModels(limit: Int = 100, includeHidden: Bool = false) async throws -> [CodexAppServerModel] {
        let result = try await request(method: "model/list", params: .object([
            "limit": .number(Double(limit)),
            "includeHidden": .bool(includeHidden)
        ]))
        return result["data"]?.arrayValue?.compactMap { value in
            guard let object = value.objectValue else { return nil }
            let id = object["id"]?.stringValue ?? object["model"]?.stringValue
            guard let id else { return nil }
            let model = object["model"]?.stringValue ?? id
            let supportedReasoningEfforts = object["supportedReasoningEfforts"]?.arrayValue?.compactMap { value -> CodexReasoningEffortOption? in
                guard let option = value.objectValue,
                      let effort = option["reasoningEffort"]?.stringValue else {
                    return nil
                }
                return CodexReasoningEffortOption(
                    effort: effort,
                    description: option["description"]?.stringValue ?? effort
                )
            } ?? []
            return CodexAppServerModel(
                id: id,
                model: model,
                displayName: object["displayName"]?.stringValue ?? id,
                description: object["description"]?.stringValue ?? "",
                supportedReasoningEfforts: supportedReasoningEfforts,
                defaultReasoningEffort: object["defaultReasoningEffort"]?.stringValue,
                inputModalities: object["inputModalities"]?.arrayValue?.compactMap(\.stringValue) ?? [],
                supportsPersonality: object["supportsPersonality"]?.boolValue ?? false,
                isDefault: object["isDefault"]?.boolValue ?? false
            )
        } ?? []
    }

    public func listPluginCatalog(cwds: [String]? = nil) async throws -> CodexRuntimePluginCatalog {
        var params: [String: JSONValue] = [:]
        if let cwds {
            params["cwds"] = .array(cwds.map(JSONValue.string))
        }
        let result = try await request(method: "plugin/list", params: .object(params))
        return Self.pluginCatalog(from: result)
    }

    public func listInstalledPluginCatalog(cwds: [String]? = nil) async throws -> CodexRuntimePluginCatalog {
        var params: [String: JSONValue] = [:]
        if let cwds {
            params["cwds"] = .array(cwds.map(JSONValue.string))
        }
        let result = try await request(method: "plugin/installed", params: .object(params))
        return Self.pluginCatalog(from: result)
    }

    public func installPlugin(_ plugin: CodexRuntimePlugin) async throws {
        var params: [String: JSONValue] = [
            "pluginName": .string(plugin.name)
        ]
        if let marketplacePath = plugin.marketplacePath {
            params["marketplacePath"] = .string(marketplacePath)
        } else {
            params["remoteMarketplaceName"] = .string(plugin.marketplaceName)
        }
        _ = try await request(method: "plugin/install", params: .object(params))
    }

    public func uninstallPlugin(_ plugin: CodexRuntimePlugin) async throws {
        _ = try await request(method: "plugin/uninstall", params: .object([
            "pluginId": .string(plugin.id)
        ]))
    }

    public func listSkills(cwds: [String], forceReload: Bool = false) async throws -> CodexRuntimeSkillCatalog {
        let result = try await request(method: "skills/list", params: .object([
            "cwds": .array(cwds.map(JSONValue.string)),
            "forceReload": .bool(forceReload)
        ]))
        return Self.skillCatalog(from: result)
    }

    public func setSkillEnabled(_ skill: CodexRuntimeSkill, enabled: Bool) async throws {
        _ = try await request(method: "skills/config/write", params: .object([
            "path": .string(skill.path),
            "name": .null,
            "enabled": .bool(enabled)
        ]))
    }

    public func readConfig(cwd: String? = nil, includeLayers: Bool = true) async throws -> CodexRuntimeConfig {
        var params: [String: JSONValue] = [
            "includeLayers": .bool(includeLayers)
        ]
        if let cwd {
            params["cwd"] = .string(cwd)
        }
        let result = try await request(method: "config/read", params: .object(params))
        return Self.runtimeConfig(from: result)
    }

    public func writeConfigValue(keyPath: String, value: JSONValue, filePath: String? = nil) async throws {
        var params: [String: JSONValue] = [
            "keyPath": .string(keyPath),
            "value": value,
            "mergeStrategy": .string("upsert")
        ]
        if let filePath {
            params["filePath"] = .string(filePath)
        }
        _ = try await request(method: "config/value/write", params: .object(params))
    }

    public func batchWriteConfig(
        edits: [CodexConfigWriteEdit],
        filePath: String? = nil,
        reloadUserConfig: Bool = true
    ) async throws {
        var params: [String: JSONValue] = [
            "edits": .array(edits.map { edit in
                .object([
                    "keyPath": .string(edit.keyPath),
                    "value": edit.value,
                    "mergeStrategy": .string(edit.mergeStrategy)
                ])
            }),
            "reloadUserConfig": .bool(reloadUserConfig)
        ]
        if let filePath {
            params["filePath"] = .string(filePath)
        }
        _ = try await request(method: "config/batchWrite", params: .object(params))
    }

    public func listHooks(cwds: [String]) async throws -> CodexRuntimeHookCatalog {
        let result = try await request(method: "hooks/list", params: .object([
            "cwds": .array(cwds.map(JSONValue.string))
        ]))
        return Self.hookCatalog(from: result)
    }

    public func listMCPServerStatus(threadID: String? = nil, limit: Int = 100) async throws -> CodexRuntimeMCPServerCatalog {
        var params: [String: JSONValue] = [
            "detail": .string("full"),
            "limit": .number(Double(limit))
        ]
        if let threadID {
            params["threadId"] = .string(threadID)
        }
        let result = try await request(method: "mcpServerStatus/list", params: .object(params))
        return Self.mcpCatalog(from: result)
    }

    public func loginMCPServerOAuth(name: String, scopes: [String]? = nil, timeoutSecs: Int? = nil) async throws -> CodexMCPServerOAuthLogin {
        var params: [String: JSONValue] = [
            "name": .string(name)
        ]
        if let scopes {
            params["scopes"] = .array(scopes.map(JSONValue.string))
        }
        if let timeoutSecs {
            params["timeoutSecs"] = .number(Double(timeoutSecs))
        }
        let result = try await request(method: "mcpServer/oauth/login", params: .object(params))
        guard let urlString = result["authorizationUrl"]?.stringValue,
              let url = URL(string: urlString) else {
            throw CodexAppServerError.invalidResponse("mcpServer/oauth/login did not return a valid authorizationUrl.")
        }
        return CodexMCPServerOAuthLogin(authorizationURL: url)
    }

    public func reloadMCPServerRegistry() async throws {
        _ = try await request(method: "config/mcpServer/reload", params: nil)
    }

    public func readAccount(refreshToken: Bool = false) async throws -> CodexRuntimeAccount {
        let result = try await request(method: "account/read", params: .object([
            "refreshToken": .bool(refreshToken)
        ]))
        return Self.runtimeAccount(from: result)
    }

    public func readAccountTokenUsage() async throws -> CodexRuntimeTokenUsage {
        let result = try await request(method: "account/usage/read", params: .object([:]))
        return Self.runtimeTokenUsage(from: result)
    }

    public func readAccountRateLimits() async throws -> CodexRuntimeRateLimits {
        let result = try await request(method: "account/rateLimits/read", params: .object([:]))
        return Self.runtimeRateLimits(from: result)
    }

    public func listThreads(
        archived: Bool? = nil,
        cwd: String? = nil,
        limit: Int = 50,
        cursor: String? = nil,
        searchTerm: String? = nil
    ) async throws -> CodexRuntimeThreadCatalog {
        var params: [String: JSONValue] = [
            "limit": .number(Double(limit)),
            "sortKey": .string("updated_at"),
            "sortDirection": .string("desc")
        ]
        if let archived {
            params["archived"] = .bool(archived)
        }
        if let cwd {
            params["cwd"] = .string(cwd)
        }
        if let cursor {
            params["cursor"] = .string(cursor)
        }
        if let searchTerm, !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["searchTerm"] = .string(searchTerm)
        }

        let result = try await request(method: "thread/list", params: .object(params))
        return Self.threadCatalog(from: result)
    }

    public func readThread(id threadID: String, includeTurns: Bool = true) async throws -> JSONValue {
        try await request(method: "thread/read", params: .object([
            "threadId": .string(threadID),
            "includeTurns": .bool(includeTurns)
        ]))
    }

    public func updateThreadPersonality(threadID: String, personality: CodexPersonality) async throws {
        _ = try await request(method: "thread/settings/update", params: .object([
            "threadId": .string(threadID),
            "personality": .string(personality.rawValue)
        ]))
    }

    public func resumeThread(id threadID: String, options: CodexAppServerOptions) async throws -> CodexAppServerThread {
        var params: [String: JSONValue] = [
            "threadId": .string(threadID),
            "cwd": .string(options.workspaceURL.path),
            "approvalPolicy": .string(options.approvalPolicy.appServerValue),
            "approvalsReviewer": .string(options.approvalsReviewer.rawValue),
            "sandbox": .string(options.sandbox.rawValue)
        ]
        if let model = options.model {
            params["model"] = .string(model)
        }
        if let personality = options.personality {
            params["personality"] = .string(personality.rawValue)
        }

        let result = try await request(method: "thread/resume", params: .object(params))
        guard let thread = result["thread"] else {
            throw CodexAppServerError.invalidResponse("Missing thread/resume thread.")
        }
        return CodexAppServerThread(
            id: thread["id"]?.stringValue ?? threadID,
            sessionID: thread["sessionId"]?.stringValue ?? "",
            preview: thread["preview"]?.stringValue ?? "",
            cliVersion: thread["cliVersion"]?.stringValue,
            approvalPolicy: Self.stringDescription(from: result["approvalPolicy"]),
            approvalsReviewer: Self.approvalsReviewer(from: result["approvalsReviewer"]),
            sandboxSummary: Self.stringDescription(from: result["sandbox"])
        )
    }

    public func archiveThread(id threadID: String) async throws {
        _ = try await request(method: "thread/archive", params: .object([
            "threadId": .string(threadID)
        ]))
    }

    public func setThreadName(id threadID: String, name: String) async throws {
        _ = try await request(method: "thread/name/set", params: .object([
            "threadId": .string(threadID),
            "name": .string(name)
        ]))
    }

    public func setThreadGoal(
        threadID: String,
        objective: String? = nil,
        status: CodexRuntimeGoalStatus? = nil,
        tokenBudget: Int? = nil
    ) async throws -> CodexRuntimeGoal {
        var params: [String: JSONValue] = [
            "threadId": .string(threadID)
        ]
        if let objective {
            params["objective"] = .string(objective)
        }
        if let status {
            params["status"] = .string(status.rawValue)
        }
        if let tokenBudget {
            params["tokenBudget"] = .number(Double(tokenBudget))
        }

        let result = try await request(method: "thread/goal/set", params: .object(params))
        guard let goal = Self.runtimeGoal(from: result["goal"]) else {
            throw CodexAppServerError.invalidResponse("Missing thread/goal/set goal.")
        }
        return goal
    }

    public func getThreadGoal(threadID: String) async throws -> CodexRuntimeGoal? {
        let result = try await request(method: "thread/goal/get", params: .object([
            "threadId": .string(threadID)
        ]))
        return Self.runtimeGoal(from: result["goal"])
    }

    public func clearThreadGoal(threadID: String) async throws -> Bool {
        let result = try await request(method: "thread/goal/clear", params: .object([
            "threadId": .string(threadID)
        ]))
        return result["cleared"]?.boolValue ?? false
    }

    public func forkThread(id threadID: String, options: CodexAppServerOptions) async throws -> CodexAppServerThread {
        var params: [String: JSONValue] = [
            "threadId": .string(threadID),
            "cwd": .string(options.workspaceURL.path),
            "approvalPolicy": .string(options.approvalPolicy.appServerValue),
            "approvalsReviewer": .string(options.approvalsReviewer.rawValue),
            "sandbox": .string(options.sandbox.rawValue),
            "ephemeral": .bool(false)
        ]
        if let model = options.model {
            params["model"] = .string(model)
        }
        if let personality = options.personality {
            params["personality"] = .string(personality.rawValue)
        }

        let result = try await request(method: "thread/fork", params: .object(params))
        guard let thread = result["thread"] else {
            throw CodexAppServerError.invalidResponse("Missing thread/fork thread.")
        }
        return CodexAppServerThread(
            id: thread["id"]?.stringValue ?? threadID,
            sessionID: thread["sessionId"]?.stringValue ?? "",
            preview: thread["preview"]?.stringValue ?? "",
            cliVersion: result["model"]?.stringValue,
            approvalPolicy: Self.stringDescription(from: result["approvalPolicy"]),
            approvalsReviewer: Self.approvalsReviewer(from: result["approvalsReviewer"]),
            sandboxSummary: Self.stringDescription(from: result["sandbox"])
        )
    }

    @discardableResult
    public func unarchiveThread(id threadID: String) async throws -> CodexRuntimeThreadSummary? {
        let result = try await request(method: "thread/unarchive", params: .object([
            "threadId": .string(threadID)
        ]))
        guard let thread = result["thread"] else {
            return nil
        }
        return Self.threadSummary(from: thread)
    }

    public func gitDiffToRemote(cwd: String) async throws -> CodexRuntimeGitDiff {
        let result = try await request(method: "gitDiffToRemote", params: .object([
            "cwd": .string(cwd)
        ]))
        return CodexRuntimeGitDiff(
            sha: result["sha"]?.stringValue ?? result["sha"]?["hash"]?.stringValue,
            diff: result["diff"]?.stringValue ?? ""
        )
    }

    public func readConfigRequirements() async throws -> CodexRuntimeConfigRequirements {
        let result = try await request(method: "configRequirements/read", params: nil)
        return Self.configRequirements(from: result)
    }

    public func readRemoteControlStatus() async throws -> CodexRuntimeRemoteControlStatus {
        let result = try await request(method: "remoteControl/status/read", params: nil)
        return Self.remoteControlStatus(from: result)
    }

    public func resetMemory() async throws {
        _ = try await request(method: "memory/reset", params: nil)
    }

    public func listApps(threadID: String? = nil, limit: Int = 100, forceRefetch: Bool = false) async throws -> CodexRuntimeAppCatalog {
        var params: [String: JSONValue] = [
            "limit": .number(Double(limit)),
            "forceRefetch": .bool(forceRefetch)
        ]
        if let threadID {
            params["threadId"] = .string(threadID)
        }
        let result = try await request(method: "app/list", params: .object(params))
        return Self.appCatalog(from: result)
    }

    public func listPermissionProfiles(cwd: String? = nil, limit: Int = 100) async throws -> CodexRuntimePermissionProfileCatalog {
        var params: [String: JSONValue] = [
            "limit": .number(Double(limit))
        ]
        if let cwd {
            params["cwd"] = .string(cwd)
        }
        let result = try await request(method: "permissionProfile/list", params: .object(params))
        return Self.permissionProfileCatalog(from: result)
    }

    public func readDirectory(path: String) async throws -> [CodexDirectoryEntry] {
        let result = try await request(method: "fs/readDirectory", params: .object([
            "path": .string(path)
        ]))
        guard let entries = result["entries"]?.arrayValue else {
            throw CodexAppServerError.invalidResponse("Missing fs/readDirectory entries.")
        }

        return entries.compactMap { value in
            guard let object = value.objectValue,
                  let fileName = object["fileName"]?.stringValue else {
                return nil
            }
            return CodexDirectoryEntry(
                fileName: fileName,
                path: URL(fileURLWithPath: path).appendingPathComponent(fileName).path,
                isDirectory: object["isDirectory"]?.boolValue ?? false,
                isFile: object["isFile"]?.boolValue ?? false
            )
        }
        .sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory && !rhs.isDirectory
            }
            return lhs.fileName.localizedStandardCompare(rhs.fileName) == .orderedAscending
        }
    }

    public func fuzzyFileSearch(
        query: String,
        roots: [String],
        cancellationToken: String? = nil
    ) async throws -> [CodexFuzzyFileSearchResult] {
        var params: [String: JSONValue] = [
            "query": .string(query),
            "roots": .array(roots.map(JSONValue.string))
        ]
        if let cancellationToken {
            params["cancellationToken"] = .string(cancellationToken)
        }

        let result = try await request(method: "fuzzyFileSearch", params: .object(params))
        guard let files = result["files"]?.arrayValue else {
            throw CodexAppServerError.invalidResponse("Missing fuzzyFileSearch files.")
        }

        return files.compactMap(Self.fuzzyFileSearchResult(from:))
    }

    public func readFile(path: String) async throws -> Data {
        let result = try await request(method: "fs/readFile", params: .object([
            "path": .string(path)
        ]))
        guard let dataBase64 = result["dataBase64"]?.stringValue,
              let data = Data(base64Encoded: dataBase64) else {
            throw CodexAppServerError.invalidResponse("Missing or invalid fs/readFile dataBase64.")
        }
        return data
    }

    public func execCommand(
        _ command: [String],
        cwd: URL? = nil,
        sandbox: CodexSandboxMode? = nil,
        timeoutMs: Int? = 30_000
    ) async throws -> CodexCommandExecResult {
        var params: [String: JSONValue] = [
            "command": .array(command.map(JSONValue.string))
        ]
        if let cwd {
            params["cwd"] = .string(cwd.path)
        }
        if let sandbox {
            params["sandboxPolicy"] = sandbox.appServerSandboxPolicy
        }
        if let timeoutMs {
            params["timeoutMs"] = .number(Double(timeoutMs))
        }

        let result = try await request(method: "command/exec", params: .object(params))
        guard let exitCode = result["exitCode"]?.intValue else {
            throw CodexAppServerError.invalidResponse("Missing command/exec exitCode.")
        }

        return CodexCommandExecResult(
            stdout: result["stdout"]?.stringValue ?? "",
            stderr: result["stderr"]?.stringValue ?? "",
            exitCode: Int32(exitCode)
        )
    }

    public func respondApproval(
        requestID: CodexAppServerRequestID,
        decision: CodexAppServerApprovalDecision
    ) async throws {
        try respond(requestID: requestID, result: .object([
            "decision": .string(decision.rawValue)
        ]))
    }

    public func stop() {
        stdoutTask?.cancel()
        stderrTask?.cancel()
        if let process, process.isRunning {
            process.terminate()
        }
        process = nil
        stdinPipe = nil
        stdoutPipe = nil
        stderrPipe = nil
        stdinHandle = nil
        didInitialize = false
        isInitializing = false
        eventContinuation.finish()
    }

    private func request(method: String, params: JSONValue?) async throws -> JSONValue {
        let requestID = CodexAppServerRequestID.number(nextRequestNumber)
        nextRequestNumber += 1
        let message = CodexAppServerMessage(id: requestID, method: method, params: params)
        debugLog("request \(requestID.description) \(method)")

        return try await withCheckedThrowingContinuation { continuation in
            pending[requestID] = continuation
            do {
                try write(message)
            } catch {
                pending.removeValue(forKey: requestID)
                continuation.resume(throwing: error)
            }
        }
    }

    private func notify(method: String, params: JSONValue?) throws {
        try write(CodexAppServerMessage(method: method, params: params))
    }

    private func respond(requestID: CodexAppServerRequestID, result: JSONValue) throws {
        try write(CodexAppServerMessage(id: requestID, result: result))
    }

    private func write(_ message: CodexAppServerMessage) throws {
        guard let stdinHandle else {
            throw CodexAppServerError.notRunning
        }

        var data = try encoder.encode(message)
        data.append(0x0A)
        if debugEnabled, let line = String(data: data, encoding: .utf8) {
            debugLog("stdin \(line.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        stdinHandle.write(data)
    }

    private func readLines(from handle: FileHandle, isStdout: Bool) -> Task<Void, Never> {
        Task.detached(priority: .utility) { [weak self] in
            var buffer = Data()
            while !Task.isCancelled {
                let chunk = handle.availableData
                guard !chunk.isEmpty else {
                    break
                }
                buffer.append(chunk)
                while let newlineIndex = buffer.firstIndex(of: 0x0A) {
                    let lineData = buffer[..<newlineIndex]
                    buffer.removeSubrange(...newlineIndex)
                    await self?.handleLineData(Data(lineData), isStdout: isStdout)
                }
            }

            if !buffer.isEmpty {
                await self?.handleLineData(buffer, isStdout: isStdout)
            }
        }
    }

    private func handleLineData(_ data: Data, isStdout: Bool) {
        guard let line = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !line.isEmpty else {
            return
        }

        guard isStdout else {
            debugLog("stderr \(line)")
            emit(.stderr(line))
            return
        }

        debugLog("stdout \(line)")
        do {
            let message = try decoder.decode(CodexAppServerMessage.self, from: Data(line.utf8))
            if let id = message.id, let method = message.method {
                emit(.serverRequest(id: id, method: method, params: message.params))
            } else if let id = message.id {
                guard let continuation = pending.removeValue(forKey: id) else {
                    emit(.stderr("Unexpected app-server response id \(id)."))
                    return
                }
                if let error = message.error {
                    continuation.resume(throwing: CodexAppServerError.rpc(error))
                } else {
                    continuation.resume(returning: message.result ?? .null)
                }
            } else if let method = message.method {
                emit(.notification(method: method, params: message.params))
            } else {
                emit(.stderr("Unrecognized app-server message: \(line)"))
            }
        } catch {
            emit(.stderr("Could not decode app-server JSONL: \(line)"))
        }
    }

    private func emit(_ event: ServerEvent) {
        eventContinuation.yield(event)
    }

    private func processDidExit(_ status: Int32) {
        let continuations = pending.values
        pending.removeAll()
        for continuation in continuations {
            continuation.resume(throwing: CodexAppServerError.processExited(status))
        }
        emit(.exited(status))
        process = nil
        stdinPipe = nil
        stdoutPipe = nil
        stderrPipe = nil
        stdinHandle = nil
        didInitialize = false
        isInitializing = false
    }

    private func debugLog(_ message: String) {
        guard debugEnabled else { return }
        fputs("app-server-client: \(message)\n", stderr)
    }

    private static func approvalsReviewer(from value: JSONValue?) -> CodexApprovalsReviewer? {
        guard let rawValue = value?.stringValue else {
            return nil
        }
        if rawValue == "guardian_subagent" {
            return .autoReview
        }
        return CodexApprovalsReviewer(rawValue: rawValue)
    }

    private static func stringDescription(from value: JSONValue?) -> String? {
        guard let value else {
            return nil
        }

        switch value {
        case let .string(text):
            return text
        case let .number(number):
            return number.rounded() == number ? String(Int(number)) : String(number)
        case let .bool(flag):
            return flag ? "true" : "false"
        case .null:
            return nil
        case let .array(values):
            return values.compactMap { stringDescription(from: $0) }.joined(separator: ", ")
        case let .object(object):
            if let type = object["type"]?.stringValue {
                return type
            } else if object["granular"]?.objectValue != nil {
                return "granular"
            } else {
                return object.keys.sorted().joined(separator: ",")
            }
        }
    }

    private static func pluginCatalog(from result: JSONValue) -> CodexRuntimePluginCatalog {
        let featuredPluginIds = result["featuredPluginIds"]?.arrayValue?.compactMap(\.stringValue) ?? []
        let loadErrors = result["marketplaceLoadErrors"]?.arrayValue?.compactMap { value -> String? in
            guard let object = value.objectValue else { return nil }
            let path = object["marketplacePath"]?.pathString ?? "marketplace"
            let message = object["message"]?.stringValue ?? "unknown error"
            return "\(path): \(message)"
        } ?? []

        let plugins = result["marketplaces"]?.arrayValue?.flatMap { marketplaceValue -> [CodexRuntimePlugin] in
            guard let marketplace = marketplaceValue.objectValue else { return [] }
            let marketplaceName = marketplace["name"]?.stringValue ?? "default"
            let marketplaceDisplayName = marketplace["interface"]?["displayName"]?.stringValue ?? marketplaceName
            let marketplacePath = marketplace["path"]?.pathString

            return marketplace["plugins"]?.arrayValue?.compactMap { pluginValue in
                guard let plugin = pluginValue.objectValue else { return nil }
                let name = plugin["name"]?.stringValue ?? plugin["id"]?.stringValue
                guard let name else { return nil }
                let interface = plugin["interface"]
                let displayName = interface?["displayName"]?.stringValue ?? name
                let summary = interface?["shortDescription"]?.stringValue
                    ?? interface?["longDescription"]?.stringValue
                    ?? plugin["keywords"]?.stringList.joined(separator: " · ")
                    ?? "Codex 插件"
                return CodexRuntimePlugin(
                    id: plugin["id"]?.stringValue ?? "\(name)@\(marketplaceName)",
                    name: name,
                    displayName: displayName,
                    summary: summary,
                    marketplaceName: marketplaceName,
                    marketplaceDisplayName: marketplaceDisplayName,
                    marketplacePath: marketplacePath,
                    category: interface?["category"]?.stringValue,
                    developerName: interface?["developerName"]?.stringValue,
                    sourceType: plugin["source"]?["type"]?.stringValue ?? "unknown",
                    installPolicy: plugin["installPolicy"]?.stringValue ?? "UNKNOWN",
                    authPolicy: plugin["authPolicy"]?.stringValue ?? "UNKNOWN",
                    availability: plugin["availability"]?.stringValue ?? "AVAILABLE",
                    installed: plugin["installed"]?.boolValue ?? false,
                    enabled: plugin["enabled"]?.boolValue ?? false
                )
            } ?? []
        } ?? []

        return CodexRuntimePluginCatalog(
            plugins: plugins.sorted {
                if featuredPluginIds.contains($0.id) != featuredPluginIds.contains($1.id) {
                    return featuredPluginIds.contains($0.id)
                }
                if $0.installed != $1.installed {
                    return $0.installed && !$1.installed
                }
                return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            },
            featuredPluginIds: featuredPluginIds,
            marketplaceLoadErrors: loadErrors
        )
    }

    private static func skillCatalog(from result: JSONValue) -> CodexRuntimeSkillCatalog {
        var skills: [CodexRuntimeSkill] = []
        var errors: [String] = []

        for entryValue in result["data"]?.arrayValue ?? [] {
            guard let entry = entryValue.objectValue else { continue }
            let cwd = entry["cwd"]?.stringValue ?? ""
            for errorValue in entry["errors"]?.arrayValue ?? [] {
                guard let error = errorValue.objectValue else { continue }
                let path = error["path"]?.stringValue ?? cwd
                let message = error["message"]?.stringValue ?? "unknown error"
                errors.append("\(path): \(message)")
            }
            for skillValue in entry["skills"]?.arrayValue ?? [] {
                guard let skill = skillValue.objectValue,
                      let name = skill["name"]?.stringValue else {
                    continue
                }
                let interface = skill["interface"]
                let path = skill["path"]?.pathString ?? name
                let summary = interface?["shortDescription"]?.stringValue
                    ?? skill["shortDescription"]?.stringValue
                    ?? skill["description"]?.stringValue
                    ?? "Codex 技能"
                skills.append(CodexRuntimeSkill(
                    name: name,
                    displayName: interface?["displayName"]?.stringValue ?? name,
                    summary: summary,
                    path: path,
                    cwd: cwd,
                    scope: skill["scope"]?.stringValue ?? "unknown",
                    enabled: skill["enabled"]?.boolValue ?? false
                ))
            }
        }

        return CodexRuntimeSkillCatalog(
            skills: skills.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending },
            errors: errors
        )
    }

    private static func hookCatalog(from result: JSONValue) -> CodexRuntimeHookCatalog {
        var hooks: [CodexRuntimeHook] = []
        var warnings: [String] = []
        var errors: [String] = []

        for entryValue in result["data"]?.arrayValue ?? [] {
            guard let entry = entryValue.objectValue else { continue }
            let cwd = entry["cwd"]?.stringValue ?? ""
            for warningValue in entry["warnings"]?.arrayValue ?? [] {
                guard let warning = warningValue.objectValue else { continue }
                let path = warning["path"]?.stringValue ?? cwd
                warnings.append("\(path): \(warning["message"]?.stringValue ?? "warning")")
            }
            for errorValue in entry["errors"]?.arrayValue ?? [] {
                guard let error = errorValue.objectValue else { continue }
                let path = error["path"]?.stringValue ?? cwd
                errors.append("\(path): \(error["message"]?.stringValue ?? "error")")
            }
            for hookValue in entry["hooks"]?.arrayValue ?? [] {
                guard let hook = hookValue.objectValue,
                      let key = hook["key"]?.stringValue else {
                    continue
                }
                hooks.append(CodexRuntimeHook(
                    key: key,
                    eventName: hook["eventName"]?.stringValue ?? "unknown",
                    handlerType: hook["handlerType"]?.stringValue ?? "unknown",
                    command: hook["command"]?.stringValue,
                    matcher: hook["matcher"]?.stringValue,
                    source: hook["source"]?.stringValue ?? "unknown",
                    sourcePath: hook["sourcePath"]?.pathString ?? cwd,
                    trustStatus: hook["trustStatus"]?.stringValue ?? "unknown",
                    timeoutSec: hook["timeoutSec"]?.intValue ?? 0,
                    enabled: hook["enabled"]?.boolValue ?? false,
                    isManaged: hook["isManaged"]?.boolValue ?? false
                ))
            }
        }

        return CodexRuntimeHookCatalog(
            hooks: hooks.sorted { $0.eventName.localizedStandardCompare($1.eventName) == .orderedAscending },
            warnings: warnings,
            errors: errors
        )
    }

    private static func mcpCatalog(from result: JSONValue) -> CodexRuntimeMCPServerCatalog {
        let servers = result["data"]?.arrayValue?.compactMap { value -> CodexRuntimeMCPServer? in
            guard let server = value.objectValue,
                  let name = server["name"]?.stringValue else {
                return nil
            }
            let info = server["serverInfo"]
            let toolsObject = server["tools"]?.objectValue ?? [:]
            let toolNames = toolsObject.map { key, value in
                value["name"]?.stringValue ?? key
            }
            return CodexRuntimeMCPServer(
                name: name,
                title: info?["title"]?.stringValue ?? info?["name"]?.stringValue ?? name,
                version: info?["version"]?.stringValue,
                authStatus: server["authStatus"]?.stringValue ?? "unsupported",
                toolNames: toolNames.sorted(),
                resourceCount: server["resources"]?.arrayValue?.count ?? 0,
                resourceTemplateCount: server["resourceTemplates"]?.arrayValue?.count ?? 0
            )
        } ?? []

        return CodexRuntimeMCPServerCatalog(
            servers: servers.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending },
            nextCursor: result["nextCursor"]?.stringValue
        )
    }

    private static func runtimeConfig(from result: JSONValue) -> CodexRuntimeConfig {
        let config = result["config"]
        let memories = config?["memories"]
        let desktop = config?["desktop"]
        let raytoneDesktop = desktop?["raytone"] ?? desktop?["RaytoneCodex"]
        let desktopKeys = config?["desktop"]?.objectValue?.keys.sorted() ?? []
        let originKeys = result["origins"]?.objectValue?.keys.sorted() ?? []
        return CodexRuntimeConfig(
            model: config?["model"]?.stringValue,
            modelProvider: config?["model_provider"]?.stringValue,
            approvalPolicy: config?["approval_policy"]?.stringValue,
            approvalsReviewer: config?["approvals_reviewer"]?.stringValue,
            sandboxMode: config?["sandbox_mode"]?.stringValue,
            defaultPermissions: config?["default_permissions"]?.stringValue ?? config?["defaultPermissions"]?.stringValue,
            reasoningEffort: config?["model_reasoning_effort"]?.stringValue,
            reasoningSummary: config?["model_reasoning_summary"]?.stringValue,
            modelVerbosity: config?["model_verbosity"]?.stringValue,
            serviceTier: config?["service_tier"]?.stringValue,
            memoryGenerateMemories: memories?["generate_memories"]?.boolValue ?? memories?["generateMemories"]?.boolValue,
            memoryUseMemories: memories?["use_memories"]?.boolValue ?? memories?["useMemories"]?.boolValue,
            memoryDisableOnExternalContext: memories?["disable_on_external_context"]?.boolValue ?? memories?["disableOnExternalContext"]?.boolValue,
            instructions: config?["instructions"]?.stringValue,
            developerInstructions: config?["developer_instructions"]?.stringValue,
            desktopKeys: desktopKeys,
            desktopSettings: CodexRuntimeDesktopSettings(
                showInMenuBar: configBool(raytoneDesktop, snake: "show_in_menu_bar", camel: "showInMenuBar"),
                showBottomPanel: configBool(raytoneDesktop, snake: "show_bottom_panel", camel: "showBottomPanel"),
                preventSleepWhileRunning: configBool(raytoneDesktop, snake: "prevent_sleep_while_running", camel: "preventSleepWhileRunning"),
                terminalPosition: configString(raytoneDesktop, snake: "terminal_position", camel: "terminalPosition"),
                appearance: configString(raytoneDesktop, snake: "appearance", camel: "appearance"),
                openTarget: configString(raytoneDesktop, snake: "open_target", camel: "openTarget"),
                language: configString(raytoneDesktop, snake: "language", camel: "language")
            ),
            layerCount: result["layers"]?.arrayValue?.count ?? 0,
            originKeys: originKeys
        )
    }

    private static func configBool(_ value: JSONValue?, snake: String, camel: String) -> Bool? {
        value?[snake]?.boolValue ?? value?[camel]?.boolValue
    }

    private static func configString(_ value: JSONValue?, snake: String, camel: String) -> String? {
        value?[snake]?.stringValue ?? value?[camel]?.stringValue
    }

    private static func runtimeAccount(from result: JSONValue) -> CodexRuntimeAccount {
        let account = result["account"]
        let kind = account?["type"]?.stringValue ?? "notLoggedIn"
        return CodexRuntimeAccount(
            kind: kind,
            email: account?["email"]?.stringValue,
            planType: account?["planType"]?.stringValue,
            requiresOpenAIAuth: result["requiresOpenaiAuth"]?.boolValue ?? false
        )
    }

    private static func runtimeTokenUsage(from result: JSONValue) -> CodexRuntimeTokenUsage {
        let summary = result["summary"]
        let buckets = result["dailyUsageBuckets"]?.arrayValue?.compactMap { value -> CodexRuntimeTokenUsageBucket? in
            guard let startDate = value["startDate"]?.stringValue else {
                return nil
            }
            return CodexRuntimeTokenUsageBucket(
                startDate: startDate,
                tokens: value["tokens"]?.intValue ?? 0
            )
        } ?? []

        return CodexRuntimeTokenUsage(
            lifetimeTokens: summary?["lifetimeTokens"]?.intValue,
            peakDailyTokens: summary?["peakDailyTokens"]?.intValue,
            longestRunningTurnSec: summary?["longestRunningTurnSec"]?.intValue,
            currentStreakDays: summary?["currentStreakDays"]?.intValue,
            longestStreakDays: summary?["longestStreakDays"]?.intValue,
            dailyBuckets: buckets
        )
    }

    private static func runtimeRateLimits(from result: JSONValue) -> CodexRuntimeRateLimits {
        var buckets: [CodexRuntimeRateLimitBucket] = []

        if let keyed = result["rateLimitsByLimitId"]?.objectValue, !keyed.isEmpty {
            buckets = keyed.compactMap { key, value in
                rateLimitBucket(from: value, fallbackID: key)
            }
        } else if let value = result["rateLimits"] {
            buckets = rateLimitBucket(from: value, fallbackID: "default").map { [$0] } ?? []
        }

        return CodexRuntimeRateLimits(
            buckets: buckets.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        )
    }

    private static func rateLimitBucket(from value: JSONValue, fallbackID: String) -> CodexRuntimeRateLimitBucket? {
        guard let object = value.objectValue else {
            return nil
        }
        let credits = object["credits"]
        let individualLimit = object["individualLimit"]
        let id = object["limitId"]?.stringValue ?? fallbackID
        let name = object["limitName"]?.stringValue ?? id

        return CodexRuntimeRateLimitBucket(
            id: id,
            name: name,
            primary: rateLimitWindow(from: object["primary"]),
            secondary: rateLimitWindow(from: object["secondary"]),
            creditsRemaining: credits?["balance"]?.stringValue.flatMap(Double.init),
            creditsUsed: individualLimit?["used"]?.stringValue.flatMap(Double.init),
            planType: object["planType"]?.stringValue,
            reachedType: object["rateLimitReachedType"]?.stringValue
        )
    }

    private static func rateLimitWindow(from value: JSONValue?) -> CodexRuntimeRateLimitWindow? {
        guard let value,
              value.objectValue != nil else {
            return nil
        }
        return CodexRuntimeRateLimitWindow(
            usedPercent: value["usedPercent"]?.numberValue,
            windowMinutes: value["windowDurationMins"]?.intValue,
            resetAt: timestampString(from: value["resetsAt"])
        )
    }

    private static func threadCatalog(from result: JSONValue) -> CodexRuntimeThreadCatalog {
        CodexRuntimeThreadCatalog(
            threads: result["data"]?.arrayValue?.compactMap(threadSummary(from:)) ?? [],
            nextCursor: result["nextCursor"]?.stringValue,
            backwardsCursor: result["backwardsCursor"]?.stringValue
        )
    }

    private static func threadSummary(from value: JSONValue) -> CodexRuntimeThreadSummary? {
        guard let id = value["id"]?.stringValue else {
            return nil
        }
        let gitInfo = value["gitInfo"]
        let title = value["name"]?.stringValue ?? value["preview"]?.stringValue ?? "未命名对话"
        return CodexRuntimeThreadSummary(
            id: id,
            title: title.isEmpty ? "未命名对话" : title,
            preview: value["preview"]?.stringValue ?? "",
            cwd: value["cwd"]?.pathString,
            modelProvider: value["modelProvider"]?.stringValue,
            source: value["source"]?.stringValue ?? value["source"]?["type"]?.stringValue,
            createdAt: timestampString(from: value["createdAt"]),
            updatedAt: timestampString(from: value["updatedAt"]),
            archived: value["archived"]?.boolValue ?? true,
            gitBranch: gitInfo?["branch"]?.stringValue,
            gitSHA: gitInfo?["sha"]?.stringValue,
            gitOriginURL: gitInfo?["originUrl"]?.stringValue
        )
    }

    public static func runtimeGoal(from value: JSONValue?) -> CodexRuntimeGoal? {
        guard let value,
              let threadID = value["threadId"]?.stringValue,
              let objective = value["objective"]?.stringValue else {
            return nil
        }
        let statusRaw = value["status"]?.stringValue ?? CodexRuntimeGoalStatus.active.rawValue
        return CodexRuntimeGoal(
            threadID: threadID,
            objective: objective,
            status: CodexRuntimeGoalStatus(rawValue: statusRaw) ?? .active,
            tokenBudget: value["tokenBudget"]?.intValue,
            tokensUsed: value["tokensUsed"]?.intValue ?? 0,
            timeUsedSeconds: value["timeUsedSeconds"]?.intValue ?? 0,
            createdAt: value["createdAt"]?.intValue ?? 0,
            updatedAt: value["updatedAt"]?.intValue ?? 0
        )
    }

    private static func timestampString(from value: JSONValue?) -> String? {
        guard let seconds = value?.numberValue else {
            return value?.stringValue
        }
        let date = Date(timeIntervalSince1970: seconds)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private static func configRequirements(from result: JSONValue) -> CodexRuntimeConfigRequirements {
        let requirements = result["requirements"]
        return CodexRuntimeConfigRequirements(
            allowedApprovalPolicies: requirements?["allowedApprovalPolicies"]?.stringList ?? [],
            allowedSandboxModes: requirements?["allowedSandboxModes"]?.stringList ?? [],
            allowedWebSearchModes: requirements?["allowedWebSearchModes"]?.stringList ?? [],
            defaultPermissions: requirements?["defaultPermissions"]?.stringValue,
            allowAppSnapshots: requirements?["allowAppshots"]?.boolValue,
            allowLockedComputerUse: requirements?["computerUse"]?["allowLockedComputerUse"]?.boolValue,
            networkEnabled: requirements?["network"]?["enabled"]?.boolValue,
            managedHooksOnly: requirements?["allowManagedHooksOnly"]?.boolValue
        )
    }

    private static func remoteControlStatus(from result: JSONValue) -> CodexRuntimeRemoteControlStatus {
        CodexRuntimeRemoteControlStatus(
            status: result["status"]?.stringValue ?? "unknown",
            serverName: result["serverName"]?.stringValue ?? "",
            installationID: result["installationId"]?.stringValue ?? "",
            environmentID: result["environmentId"]?.stringValue
        )
    }

    private static func appCatalog(from result: JSONValue) -> CodexRuntimeAppCatalog {
        let apps = result["data"]?.arrayValue?.compactMap { value -> CodexRuntimeAppInfo? in
            guard let id = value["id"]?.stringValue,
                  let name = value["name"]?.stringValue else {
                return nil
            }
            let branding = value["branding"]
            let metadata = value["appMetadata"]
            let screenshotPrompts = metadata?["screenshots"]?.arrayValue?.compactMap { screenshot in
                screenshot["userPrompt"]?.stringValue
            } ?? []

            return CodexRuntimeAppInfo(
                id: id,
                name: name,
                description: value["description"]?.stringValue ?? metadata?["seoDescription"]?.stringValue,
                category: branding?["category"]?.stringValue ?? metadata?["categories"]?.stringList.first,
                developer: branding?["developer"]?.stringValue ?? metadata?["developer"]?.stringValue,
                website: branding?["website"]?.stringValue,
                isAccessible: value["isAccessible"]?.boolValue ?? false,
                isEnabled: value["isEnabled"]?.boolValue ?? true,
                pluginDisplayNames: value["pluginDisplayNames"]?.stringList ?? [],
                screenshotPrompts: screenshotPrompts
            )
        } ?? []

        return CodexRuntimeAppCatalog(
            apps: apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
            nextCursor: result["nextCursor"]?.stringValue
        )
    }

    private static func permissionProfileCatalog(from result: JSONValue) -> CodexRuntimePermissionProfileCatalog {
        let profiles = result["data"]?.arrayValue?.compactMap { value -> CodexRuntimePermissionProfile? in
            guard let id = value["id"]?.stringValue else {
                return nil
            }
            return CodexRuntimePermissionProfile(
                id: id,
                description: value["description"]?.stringValue
            )
        } ?? []

        return CodexRuntimePermissionProfileCatalog(
            profiles: profiles.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending },
            nextCursor: result["nextCursor"]?.stringValue
        )
    }

    private static func fuzzyFileSearchResult(from value: JSONValue) -> CodexFuzzyFileSearchResult? {
        guard let root = value["root"]?.stringValue,
              let relativePath = value["path"]?.stringValue else {
            return nil
        }

        let matchTypeValue = value["match_type"]?.stringValue
            ?? value["matchType"]?.stringValue
            ?? "file"
        let matchType = CodexFuzzyFileSearchResult.MatchType(rawValue: matchTypeValue) ?? .file
        let fileName = value["file_name"]?.stringValue
            ?? value["fileName"]?.stringValue
            ?? URL(fileURLWithPath: relativePath).lastPathComponent
        let absolutePath = relativePath.hasPrefix("/")
            ? relativePath
            : URL(fileURLWithPath: root).appendingPathComponent(relativePath).path

        return CodexFuzzyFileSearchResult(
            root: root,
            relativePath: relativePath,
            path: absolutePath,
            matchType: matchType,
            fileName: fileName,
            score: value["score"]?.intValue ?? 0,
            indices: value["indices"]?.arrayValue?.compactMap(\.intValue) ?? []
        )
    }
}

private extension JSONValue {
    var pathString: String? {
        if let stringValue {
            return stringValue
        }
        return objectValue?["path"]?.stringValue
    }

    var stringList: [String] {
        arrayValue?.compactMap(\.stringValue) ?? []
    }

    var numberValue: Double? {
        if case let .number(value) = self {
            return value
        }
        return nil
    }
}

public extension CodexApprovalPolicy {
    var appServerValue: String {
        switch self {
        case .never:
            "never"
        case .onRequest:
            "on-request"
        case .onFailure:
            "on-failure"
        case .untrusted:
            "untrusted"
        }
    }
}

public extension CodexSandboxMode {
    var appServerSandboxPolicy: JSONValue {
        switch self {
        case .readOnly:
            .object([
                "type": .string("readOnly"),
                "networkAccess": .bool(false)
            ])
        case .workspaceWrite:
            .object([
                "type": .string("workspaceWrite"),
                "writableRoots": .array([]),
                "networkAccess": .bool(false),
                "excludeTmpdirEnvVar": .bool(false),
                "excludeSlashTmp": .bool(false)
            ])
        case .dangerFullAccess:
            .object([
                "type": .string("dangerFullAccess")
            ])
        }
    }
}
