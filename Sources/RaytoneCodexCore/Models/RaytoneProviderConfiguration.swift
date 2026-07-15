import Foundation

public enum RaytoneProviderKind: String, Codable, Sendable {
    case openAI
    case chatCompletionsSidecar
}

public struct RaytoneProviderConfiguration: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var displayName: String
    public var baseURL: String
    public var model: String
    public var models: [String]
    public var kind: RaytoneProviderKind
    public var apiKeyEnvironmentName: String?
    public var requiresAPIKey: Bool
    public var reasoning: CodexChatReasoningSettings?

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case baseURL
        case model
        case models
        case kind
        case apiKeyEnvironmentName
        case requiresAPIKey
        case reasoning
    }

    public init(
        id: String,
        displayName: String,
        baseURL: String,
        model: String,
        models: [String],
        kind: RaytoneProviderKind,
        apiKeyEnvironmentName: String? = nil,
        requiresAPIKey: Bool = true,
        reasoning: CodexChatReasoningSettings? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.baseURL = baseURL
        self.model = model
        self.models = models
        self.kind = kind
        self.apiKeyEnvironmentName = apiKeyEnvironmentName
        self.requiresAPIKey = requiresAPIKey
        self.reasoning = reasoning
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.baseURL = try container.decode(String.self, forKey: .baseURL)
        self.model = try container.decode(String.self, forKey: .model)
        self.models = try container.decode([String].self, forKey: .models)
        self.kind = try container.decode(RaytoneProviderKind.self, forKey: .kind)
        self.apiKeyEnvironmentName = try container.decodeIfPresent(String.self, forKey: .apiKeyEnvironmentName)
        self.requiresAPIKey = try container.decodeIfPresent(Bool.self, forKey: .requiresAPIKey) ?? true
        self.reasoning = try container.decodeIfPresent(CodexChatReasoningSettings.self, forKey: .reasoning)
    }

    public var usesSidecar: Bool {
        kind == .chatCompletionsSidecar
    }
}

public struct CodexChatReasoningSettings: Codable, Equatable, Sendable {
    public var supportsThinking: Bool
    public var supportsEffort: Bool
    public var thinkingParam: String
    public var effortParam: String
    public var effortValueMode: String?
    public var outputFormat: String

    public init(
        supportsThinking: Bool,
        supportsEffort: Bool,
        thinkingParam: String,
        effortParam: String,
        effortValueMode: String? = nil,
        outputFormat: String
    ) {
        self.supportsThinking = supportsThinking
        self.supportsEffort = supportsEffort
        self.thinkingParam = thinkingParam
        self.effortParam = effortParam
        self.effortValueMode = effortValueMode
        self.outputFormat = outputFormat
    }
}

public extension RaytoneProviderConfiguration {
    static let defaultProviders: [RaytoneProviderConfiguration] = [
        RaytoneProviderConfiguration(
            id: "openai",
            displayName: "OpenAI",
            baseURL: "https://api.openai.com/v1",
            model: "gpt-5.5",
            models: ["gpt-5.5", "gpt-5.1-codex"],
            kind: .openAI
        ),
        RaytoneProviderConfiguration(
            id: "deepseek",
            displayName: "DeepSeek",
            baseURL: "https://api.deepseek.com",
            model: "deepseek-v4-flash",
            models: ["deepseek-v4-flash", "deepseek-chat", "deepseek-reasoner"],
            kind: .chatCompletionsSidecar,
            apiKeyEnvironmentName: "DEEPSEEK_API_KEY",
            reasoning: CodexChatReasoningSettings(
                supportsThinking: true,
                supportsEffort: true,
                thinkingParam: "thinking",
                effortParam: "reasoning_effort",
                effortValueMode: "deepseek",
                outputFormat: "reasoning_content"
            )
        ),
        RaytoneProviderConfiguration(
            id: "glm",
            displayName: "Z.AI GLM",
            baseURL: "https://api.z.ai/api/coding/paas/v4",
            model: "GLM-5.1",
            models: ["GLM-5.1", "GLM-5", "GLM-5-Turbo", "GLM-4.7", "GLM-4.6"],
            kind: .chatCompletionsSidecar,
            apiKeyEnvironmentName: "ZAI_API_KEY",
            reasoning: CodexChatReasoningSettings(
                supportsThinking: true,
                supportsEffort: false,
                thinkingParam: "thinking",
                effortParam: "none",
                outputFormat: "reasoning_content"
            )
        ),
        RaytoneProviderConfiguration(
            id: "kimi",
            displayName: "Kimi",
            baseURL: "https://api.moonshot.cn/v1",
            model: "kimi-k2.6",
            models: ["kimi-k2.6", "kimi-k2.5", "kimi-k2"],
            kind: .chatCompletionsSidecar,
            apiKeyEnvironmentName: "MOONSHOT_API_KEY",
            reasoning: CodexChatReasoningSettings(
                supportsThinking: true,
                supportsEffort: false,
                thinkingParam: "thinking",
                effortParam: "none",
                outputFormat: "reasoning_content"
            )
        ),
        RaytoneProviderConfiguration(
            id: "minimax",
            displayName: "MiniMax",
            baseURL: "https://api.minimax.io",
            model: "MiniMax-M3",
            models: ["MiniMax-M3", "MiniMax-M2.7", "MiniMax-M2"],
            kind: .chatCompletionsSidecar,
            apiKeyEnvironmentName: "MINIMAX_API_KEY",
            reasoning: CodexChatReasoningSettings(
                supportsThinking: true,
                supportsEffort: false,
                thinkingParam: "reasoning_split",
                effortParam: "none",
                outputFormat: "reasoning_details"
            )
        ),
        RaytoneProviderConfiguration(
            id: "local-vllm",
            displayName: "本地 vLLM",
            baseURL: "http://127.0.0.1:8000/v1",
            model: "local-model",
            models: ["local-model"],
            kind: .chatCompletionsSidecar,
            requiresAPIKey: false,
            reasoning: nil
        )
    ]
}
