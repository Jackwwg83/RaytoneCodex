import RaytoneCodexCore
import SwiftUI

struct ProviderOnboardingView: View {
    @ObservedObject var store: SessionStore

    @State private var selectedProviderID = ""
    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var model = ""
    @State private var isTesting = false

    private var providers: [RaytoneProviderConfiguration] {
        store.sidecarProviders
    }

    private var selectedProvider: RaytoneProviderConfiguration? {
        providers.first { $0.id == selectedProviderID } ?? providers.first
    }

    var body: some View {
        HStack(spacing: 0) {
            providerList
            Divider()
                .overlay(Theme.borderSoft)
            providerForm
        }
        .background(Theme.window)
        .onAppear {
            if selectedProviderID.isEmpty {
                let provider = providers.first { $0.id == store.selectedProviderID } ?? providers.first
                syncDrafts(provider)
            }
        }
    }

    private var providerList: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("连接模型提供方")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("选择一个第三方模型提供方，RaytoneCodex 会启动本地代理，把 Codex app-server 的 Responses 请求转成对应上游的 Chat Completions。")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                ForEach(providers) { provider in
                    providerRow(provider)
                }
            }

            Spacer(minLength: 0)

            Button {
                store.route = .settings
                store.settingsPane = .modelsProviders
                store.dismissProviderOnboarding()
            } label: {
                Label("稍后在设置里配置", systemImage: "gearshape")
            }
            .buttonStyle(ChipButtonStyle())
        }
        .padding(22)
        .frame(width: 290)
        .frame(maxHeight: .infinity)
        .background(Theme.sidebar)
    }

    private func providerRow(_ provider: RaytoneProviderConfiguration) -> some View {
        Button {
            syncDrafts(provider)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: provider.id == "local-vllm" ? "desktopcomputer" : "shippingbox")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(provider.id == selectedProviderID ? Theme.accent : Theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Theme.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(provider.model)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if provider.id == selectedProviderID {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 48)
            .background(provider.id == selectedProviderID ? Theme.fillSelected : Theme.fillSubtle)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var providerForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let provider = selectedProvider {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(provider.displayName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(provider.baseURL)
                            .font(Theme.mono(11.5))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer(minLength: 0)
                    statusBadge(providerCredentialBadgeText(provider), ok: store.hasProviderAPIKey(provider))
                }

                VStack(alignment: .leading, spacing: 12) {
                    field("基础地址", text: $baseURL, prompt: "https://api.example.com/v1", mono: true)
                    field("模型", text: $model, prompt: provider.model, mono: true)
                    if provider.requiresAPIKey {
                        SecureField(store.hasProviderAPIKey(provider) ? "已保存，可留空继续使用" : "粘贴接口密钥", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12.5))
                    } else {
                        Text("该 Provider 不需要 API Key；请确认本地 OpenAI 兼容服务已启动。")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text(provider.requiresAPIKey ? "密钥保存到 macOS 钥匙串；本地代理的临时配置只引用环境变量，不把明文写入 TOML。" : "raytone-proxy 会直接访问本地端点，不发送 Authorization 头。")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ProviderOnboardingCard {
                    VStack(alignment: .leading, spacing: 8) {
                        metricRow("本地转换层", "raytone-proxy")
                        metricRow("Codex 配置", store.providerConnectionCodexConfigPath.isEmpty ? "测试后生成私有 CODEX_HOME/config.toml" : Project.abbreviate(store.providerConnectionCodexConfigPath))
                        metricRow("本地代理地址", store.providerConnectionBaseURL.isEmpty ? "等待测试" : store.providerConnectionBaseURL)
                        metricRow("状态", statusText)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Button("继续使用 OpenAI") {
                        Task { await continueWithOpenAI() }
                    }
                    .buttonStyle(ChipButtonStyle())
                    .disabled(isTesting)

                    Spacer(minLength: 0)

                    Button {
                        Task { await complete(provider) }
                    } label: {
                        HStack(spacing: 6) {
                            if isTesting {
                                ProgressView()
                                    .controlSize(.small)
                                    .scaleEffect(0.6)
                                    .frame(width: 14, height: 14)
                            }
                            Text(isTesting ? "正在测试" : "测试并完成")
                        }
                    }
                    .buttonStyle(ChipButtonStyle(tint: Theme.textPrimary, prominent: true))
                    .disabled(isTesting || baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                emptyState
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.transcript)
    }

    private var statusText: String {
        if !store.providerOnboardingStatusText.isEmpty, store.providerOnboardingStatusText != "未开始" {
            return store.providerOnboardingStatusText
        }
        return store.providerConnectionStatusText
    }

    private func complete(_ provider: RaytoneProviderConfiguration) async {
        isTesting = true
        defer { isTesting = false }
        _ = await store.completeProviderOnboarding(
            providerID: provider.id,
            apiKey: apiKey,
            baseURL: baseURL,
            model: model
        )
    }

    private func continueWithOpenAI() async {
        isTesting = true
        defer { isTesting = false }
        _ = await store.continueProviderOnboardingWithOpenAI()
    }

    private func syncDrafts(_ provider: RaytoneProviderConfiguration?) {
        guard let provider else { return }
        selectedProviderID = provider.id
        baseURL = provider.baseURL
        model = provider.model
        apiKey = ""
        if provider.requiresAPIKey {
            store.providerOnboardingStatusText = store.hasProviderAPIKey(provider) ? "密钥已就绪，可以测试连接" : "请输入接口密钥后测试连接"
        } else {
            store.providerOnboardingStatusText = "无需接口密钥，请直接测试本地端点"
        }
    }

    private func providerCredentialBadgeText(_ provider: RaytoneProviderConfiguration) -> String {
        if !provider.requiresAPIKey {
            return "无需密钥"
        }
        return store.hasProviderAPIKey(provider) ? "密钥已保存" : "需要密钥"
    }

    private func field(_ title: String, text: Binding<String>, prompt: String, mono: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
                .font(mono ? Theme.mono(12) : .system(size: 12.5))
        }
    }

    private func statusBadge(_ text: String, ok: Bool) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(ok ? Theme.success : Theme.warning)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(Theme.fill)
            .clipShape(Capsule())
    }

    private func metricRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(Theme.mono(11.2))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(Theme.textTertiary)
                Text("没有可配置的第三方模型提供方")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Button("关闭") {
                store.dismissProviderOnboarding()
            }
            .buttonStyle(ChipButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ProviderOnboardingCard<Content: View>: View {
    @ViewBuilder var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.transcript)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}
