import AppKit
import RaytoneCodexCore
import SwiftUI

struct SettingsRouteView: View {
    @ObservedObject var store: SessionStore

    @State private var search = ""
    @State private var workMode = "coding"
    @State private var showInMenuBar = true
    @State private var bottomPanel = true
    @State private var preventSleep = true
    @State private var terminalPosition = "底部"
    @State private var appearance = "跟随系统"
    @State private var chronicleEnabled = true
    @State private var providerAPIKeyDraft = ""
    @State private var providerStatusMessage = "未测试"
    @State private var instructionsStatus = ""
    @State private var profileStatus = ""
    @State private var customInstructions = """
    Prefer concise, actionable engineering updates.
    Keep implementation notes tied to real files and runtime evidence.
    """

    private var defaultPermissionsBinding: Binding<Bool> {
        Binding(
            get: { store.defaultPermissionsEnabled },
            set: { enabled in
                Task { @MainActor in
                    await store.saveRuntimeDefaultPermissions(defaultEnabled: enabled)
                }
            }
        )
    }

    private var fullAccessPermissionsBinding: Binding<Bool> {
        Binding(
            get: { store.defaultFullAccessPermissionsEnabled },
            set: { enabled in
                Task { @MainActor in
                    await store.saveRuntimeDefaultPermissions(fullAccess: enabled)
                }
            }
        )
    }

    private var autoReviewBinding: Binding<Bool> {
        Binding(
            get: { store.approvalsReviewer == .autoReview },
            set: { enabled in
                Task { @MainActor in
                    await store.saveRuntimeAutoReviewEnabled(enabled)
                }
            }
        )
    }

    private var memoryEnabledBinding: Binding<Bool> {
        Binding(
            get: { store.runtimeMemoryEnabled },
            set: { enabled in
                Task { @MainActor in
                    await store.saveRuntimeMemoryEnabled(enabled)
                }
            }
        )
    }

    private var skipToolChatsBinding: Binding<Bool> {
        Binding(
            get: { store.runtimeSkipToolAssistedChats },
            set: { enabled in
                Task { @MainActor in
                    await store.saveRuntimeSkipToolAssistedChats(enabled)
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            settingsSidebar
            Divider()
            ScrollView {
                paneContent
                    .frame(maxWidth: 820, alignment: .topLeading)
                    .padding(.horizontal, 42)
                    .padding(.top, 46)
                    .padding(.bottom, 56)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Theme.transcript)
        }
        .frame(minWidth: 760)
        .background(Theme.window)
        .task(id: store.settingsPane) {
            switch store.settingsPane {
            case .profile, .usageBilling:
                await store.refreshAccountUsageRuntime()
            case .mcpServers:
                await store.refreshRuntimeMCPServers()
            case .hooks:
                await store.refreshRuntimeHooks()
            case .archivedChats:
                await store.refreshArchivedThreads()
            case .git:
                await store.refreshWorkspaceGitDiff()
            case .appSnapshots, .browser, .computerControl, .connections, .environments:
                await store.refreshIntegrationRuntime()
            case .worktrees:
                await store.refreshWorkspaceWorktrees()
            case .configuration, .personalization:
                await store.refreshRuntimeConfiguration()
            default:
                await store.refreshRuntimeCatalog()
            }
            if let instructions = store.runtimeConfig?.developerInstructions, !instructions.isEmpty {
                customInstructions = instructions
            } else if let instructions = store.runtimeConfig?.instructions, !instructions.isEmpty {
                customInstructions = instructions
            }
        }
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 36)

            Button {
                store.route = .thread
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("返回应用")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                TextField("搜索设置...", text: $search)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
            }
            .padding(.horizontal, 9)
            .frame(height: 30)
            .background(Theme.fill)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(SettingsGroup.all) { group in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(group.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                                .padding(.horizontal, 10)
                                .padding(.top, 2)

                            ForEach(filteredPanes(group.panes)) { pane in
                                settingsNavRow(pane)
                            }
                        }
                    }
                }
                .padding(.bottom, 18)
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 12)
        .frame(width: 230)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.sidebar)
    }

    private func filteredPanes(_ panes: [SettingsPane]) -> [SettingsPane] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return panes }
        return panes.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private func settingsNavRow(_ pane: SettingsPane) -> some View {
        Button {
            store.settingsPane = pane
        } label: {
            HStack(spacing: 8) {
                Image(systemName: pane.symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(store.settingsPane == pane ? Theme.textPrimary : Theme.textSecondary)
                    .frame(width: 17)
                Text(pane.title)
                    .font(.system(size: 12.5, weight: store.settingsPane == pane ? .semibold : .regular))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .frame(height: 29)
            .background(store.settingsPane == pane ? Theme.fillSelected : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var paneContent: some View {
        switch store.settingsPane {
        case .general:
            generalPane
        case .modelsProviders:
            modelsProvidersPane
        case .profile:
            profilePane
        case .appearance:
            appearancePane
        case .configuration:
            configurationPane
        case .personalization:
            personalizationPane
        case .usageBilling:
            usageBillingPane
        case .mcpServers:
            mcpServersPane
        case .hooks:
            hooksPane
        case .git:
            gitPane
        case .archivedChats:
            archivedChatsPane
        case .keyboardShortcuts:
            keyboardShortcutsPane
        case .appSnapshots:
            appSnapshotsPane
        case .browser:
            browserSettingsPane
        case .computerControl:
            computerControlPane
        case .connections:
            connectionsPane
        case .environments:
            environmentsPane
        case .worktrees:
            worktreesPane
        }
    }

    private var generalPane: some View {
        VStack(alignment: .leading, spacing: 24) {
            paneTitle("常规")

            SettingsSection(title: "工作模式", description: "选择 Codex 显示多少技术细节") {
                HStack(spacing: 12) {
                    modeCard(id: "coding", symbol: "terminal", title: "适用于编程", subtitle: "更具技术性的回复和控制")
                    modeCard(id: "daily", symbol: "sparkles", title: "适用于日常工作", subtitle: "同样强大，技术细节更少")
                }
            }

            SettingsSection(title: "权限") {
                SettingsCard {
                    SettingsToggleRow(title: "默认权限", description: "默认情况下，Codex 可以读取并编辑其工作区中的文件。必要时，它可以请求额外的访问权限", isOn: defaultPermissionsBinding)
                    SettingsToggleRow(title: "自动审核", description: "Codex 会自动审核额外访问权限请求。自动审核可能会出错。了解更多有关高风险的信息。", isOn: autoReviewBinding)
                    SettingsToggleRow(title: "完全访问权限", description: "当 Codex 以完全访问权限运行时，无需你批准。这会显著增加数据丢失、泄露或意外行为的风险。了解更多。", isOn: fullAccessPermissionsBinding)
                }
            }

            SettingsSection(title: "常规") {
                SettingsCard {
                    SettingsValueRow(title: "默认打开目标", description: "默认打开文件和文件夹的位置") { menuValue("iTerm2", values: ["iTerm2", "Terminal", "Finder"]) }
                    SettingsValueRow(title: "语言", description: "应用 UI 语言") { menuValue("自动检测", values: ["自动检测", "简体中文", "English"]) }
                    SettingsToggleRow(title: "在菜单栏中显示", description: "关闭主窗口后，仍在 macOS 菜单栏中保留 Codex", isOn: $showInMenuBar)
                    SettingsToggleRow(title: "底部面板", description: "在应用标题栏中显示底部面板控件", isOn: $bottomPanel)
                    SettingsValueRow(title: "默认终端位置", description: "选择终端快捷方式和环境操作在何处打开终端标签页") {
                        segmented(values: ["底部", "右侧"], selection: $terminalPosition)
                    }
                    SettingsToggleRow(title: "运行时防止系统休眠", description: "在 Codex 运行对话时，让电脑保持唤醒状态", isOn: $preventSleep)
                    SettingsValueRow(title: "速度", description: "写入 Codex 的 service_tier，用于新一轮模型请求") {
                        serviceTierMenu
                    }
                }
            }
        }
    }

    private var profilePane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Spacer(minLength: 0)
                Button("Share") {
                    copyProfileShareSummary()
                }
                    .buttonStyle(ChipButtonStyle())
                Button("私有") {
                    profileStatus = "个人资料保持私有"
                }
                    .buttonStyle(ChipButtonStyle())
                Button("编辑") {
                    store.settingsPane = .personalization
                }
                    .buttonStyle(ChipButtonStyle())
            }
            if !profileStatus.isEmpty {
                Text(profileStatus)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            VStack(spacing: 8) {
                Text("HW")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Theme.transcript)
                    .frame(width: 76, height: 76)
                    .background(Theme.warning)
                    .clipShape(Circle())
                Text("Hongqian Wu")
                    .font(.system(size: 20, weight: .semibold))
                HStack(spacing: 6) {
                    Text("@hqwu810")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Pro")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 7)
                        .frame(height: 20)
                        .background(Theme.fill)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)

            statsCard
            tokenActivityCard

            HStack(alignment: .top, spacing: 14) {
                insightCard
                pluginsUsageCard
            }
        }
    }

    private var modelsProvidersPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            paneTitle("模型与提供方", subtitle: "选择 Codex 使用的模型提供方。Chat Completions 提供方会通过本地 raytone-proxy 转换为 Responses。")

            HStack(alignment: .top, spacing: 16) {
                SettingsCard {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(store.providers) { provider in
                            providerListRow(provider)
                        }
                    }
                }
                .frame(width: 250)

                providerDetailCard(store.selectedProvider)
            }

            SettingsSection(title: "运行时状态") {
                SettingsCard {
                    SettingsValueRow(title: "当前提供方", description: "Composer 和新对话首屏会使用同一选择") {
                        Text(store.modelDisplayName)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    SettingsValueRow(title: "模型目录", description: "来自 app-server model/list 的 displayName 和 reasoning 元数据") {
                        Text(store.codexModelCatalog.isEmpty ? store.modelCatalogStatusText : "\(store.codexModelCatalog.count) 个模型 · \(store.selectedCodexModelMetadata?.defaultReasoningEffort ?? "默认推理")")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }
                    SettingsValueRow(title: "Sidecar", description: "仅第三方 Chat Completions 提供方需要") {
                        let sidecarText = store.selectedProvider.usesSidecar ? store.sidecarStatusText : "不需要"
                        statusBadge(sidecarText, ok: store.selectedProvider.usesSidecar ? sidecarText.contains("127.0.0.1") : true)
                    }
                }
            }
        }
    }

    private var usageBillingPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("使用情况和计费", subtitle: "来自 app-server 的 account/read、account/usage/read、account/rateLimits/read")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshAccountUsageRuntime() }
                }
                .buttonStyle(ChipButtonStyle())
            }

            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)

            runtimeErrorsSection

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                accountSummaryCard
                tokenUsageSummaryCard
            }

            SettingsSection(title: "速率限制") {
                if let rateLimits = store.runtimeRateLimits, !rateLimits.buckets.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(rateLimits.buckets) { bucket in
                            SettingsCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(bucket.name)
                                            .font(.system(size: 13.5, weight: .semibold))
                                        Spacer(minLength: 0)
                                        statusBadge(bucket.reachedType == nil ? "正常" : bucket.reachedType ?? "受限", ok: bucket.reachedType == nil)
                                    }
                                    metricRow("计划", bucket.planType ?? "未返回")
                                    metricRow("主窗口", rateLimitWindowText(bucket.primary))
                                    metricRow("次窗口", rateLimitWindowText(bucket.secondary))
                                    metricRow("余额", bucket.creditsRemaining.map { formatDecimal($0) } ?? "未返回")
                                    metricRow("已用", bucket.creditsUsed.map { formatDecimal($0) } ?? "未返回")
                                }
                            }
                        }
                    }
                } else {
                    emptySettingsState(symbol: "chart.pie", title: "没有 rate limit 快照", detail: "app-server 没有返回账户速率限制；未登录或该账户类型可能不提供此数据。")
                }
            }
        }
    }

    private var accountSummaryCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text("账户")
                        .font(.system(size: 13.5, weight: .semibold))
                    Spacer(minLength: 0)
                    let loggedIn = store.runtimeAccount != nil && store.runtimeAccount?.kind != "notLoggedIn"
                    statusBadge(loggedIn ? "已登录" : "未登录", ok: loggedIn)
                }
                metricRow("类型", accountKindName(store.runtimeAccount?.kind))
                metricRow("账户", store.runtimeAccount.map(SessionStore.accountDisplayName) ?? "未返回")
                metricRow("计划", store.runtimeAccount?.planType ?? "未返回")
                metricRow("来源", "account/read")
            }
        }
    }

    private var tokenUsageSummaryCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Token 使用")
                        .font(.system(size: 13.5, weight: .semibold))
                    Spacer(minLength: 0)
                    statusBadge(store.runtimeTokenUsage == nil ? "未返回" : "已读取", ok: store.runtimeTokenUsage != nil)
                }
                metricRow("累计 Token", tokenText(store.runtimeTokenUsage?.lifetimeTokens))
                metricRow("单日峰值", tokenText(store.runtimeTokenUsage?.peakDailyTokens))
                metricRow("最长任务", durationText(store.runtimeTokenUsage?.longestRunningTurnSec))
                metricRow("连续天数", daysText(store.runtimeTokenUsage?.currentStreakDays))
                metricRow("最长连续", daysText(store.runtimeTokenUsage?.longestStreakDays))
            }
        }
    }

    private func providerListRow(_ provider: RaytoneProviderConfiguration) -> some View {
        Button {
            store.selectProvider(provider.id)
            providerAPIKeyDraft = ""
            providerStatusMessage = store.hasProviderAPIKey(provider) ? "Key 已就绪" : "未配置"
        } label: {
            HStack(spacing: 10) {
                Image(systemName: provider.usesSidecar ? "shippingbox" : "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(provider.id == store.selectedProviderID ? Theme.accent : Theme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(Theme.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(store.modelMenuTitle(providerID: provider.id, model: provider.model))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if provider.id == store.selectedProviderID {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.horizontal, 9)
            .frame(height: 44)
            .background(provider.id == store.selectedProviderID ? Theme.fillSelected : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func providerDetailCard(_ provider: RaytoneProviderConfiguration) -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(provider.usesSidecar ? "通过本地 sidecar 使用 Chat Completions" : "使用 Codex 原生 OpenAI 连接")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    statusBadge(store.hasProviderAPIKey(provider) ? "可用" : "缺少 Key", ok: store.hasProviderAPIKey(provider))
                }
                .padding(.bottom, 12)

                SettingsValueRow(title: "模型", description: "当前 provider 的默认模型") {
                    Menu {
                        ForEach(provider.models, id: \.self) { model in
                            Button {
                                Task {
                                    await store.saveRuntimeModelSelection(providerID: provider.id, model: model)
                                    providerStatusMessage = store.modelCatalogStatusText
                                }
                            } label: {
                                Text(store.modelMenuTitle(providerID: provider.id, model: model))
                            }
                        }
                    } label: {
                        menuLabel(store.modelMenuTitle(providerID: provider.id, model: provider.model))
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                }

                SettingsValueRow(title: "Base URL", description: "用户可在后续版本中编辑；当前按官方预设填充") {
                    Text(provider.baseURL)
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                SettingsValueRow(title: "Thinking", description: "写入 Codex 的 model_reasoning_effort / model_reasoning_summary") {
                    Toggle("", isOn: Binding(
                        get: { store.providerThinkingEnabled(provider) },
                        set: { enabled in
                            Task {
                                await store.saveRuntimeThinkingEnabled(providerID: provider.id, enabled: enabled)
                                providerStatusMessage = store.modelCatalogStatusText
                            }
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(provider.usesSidecar && provider.reasoning == nil)
                }

                HStack(spacing: 8) {
                    Button("刷新模型列表") {
                        store.selectProvider(provider.id)
                        Task {
                            await store.refreshModelCatalog()
                            providerStatusMessage = store.modelCatalogStatusText
                        }
                    }
                    .buttonStyle(ChipButtonStyle())

                    Text(store.modelCatalogStatusText)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)

                if provider.usesSidecar {
                    SettingsValueRow(title: "API Key", description: "保存到 macOS Keychain，不写入 sidecar TOML") {
                        SecureField(store.hasProviderAPIKey(provider) ? "已保存" : "粘贴 API Key", text: $providerAPIKeyDraft)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .frame(width: 210)
                    }
                    HStack(spacing: 8) {
                        Button("保存 Key") {
                            do {
                                try store.saveProviderAPIKey(providerAPIKeyDraft, providerID: provider.id)
                                providerAPIKeyDraft = ""
                                providerStatusMessage = "Key 已保存"
                            } catch {
                                providerStatusMessage = error.localizedDescription
                            }
                        }
                        .buttonStyle(ChipButtonStyle(tint: Theme.accent, prominent: true))
                        .disabled(providerAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button("测试连接") {
                            store.selectProvider(provider.id)
                            do {
                                let draft = providerAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !draft.isEmpty {
                                    try store.saveProviderAPIKey(draft, providerID: provider.id)
                                    providerAPIKeyDraft = ""
                                }
                                Task {
                                    await store.refreshModelCatalog()
                                    providerStatusMessage = store.modelCatalogStatusText
                                }
                            } catch {
                                providerStatusMessage = error.localizedDescription
                            }
                        }
                        .buttonStyle(ChipButtonStyle())

                        Text(providerStatusMessage)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 10)
                }
            }
        }
    }

    private func statusBadge(_ text: String, ok: Bool) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(ok ? Theme.success : Theme.warning)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background((ok ? Theme.success : Theme.warning).opacity(0.10))
            .clipShape(Capsule())
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            statCell(value: tokenText(store.runtimeTokenUsage?.lifetimeTokens), label: "累计 Token 数")
            statCell(value: tokenText(store.runtimeTokenUsage?.peakDailyTokens), label: "峰值 Token 数")
            statCell(value: durationText(store.runtimeTokenUsage?.longestRunningTurnSec), label: "最长任务时长")
            statCell(value: daysText(store.runtimeTokenUsage?.currentStreakDays), label: "当前连续天数")
            statCell(value: daysText(store.runtimeTokenUsage?.longestStreakDays), label: "最长连续天数")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.transcript)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
    }

    private var tokenActivityCard: some View {
        SettingsSection(title: "Token 活动") {
            SettingsCard {
                HStack {
                    Spacer(minLength: 0)
                    segmented(values: ["每日", "每周", "累计"], selection: .constant("每日"))
                }
                heatmap
                HStack {
                    ForEach(["7月", "8月", "9月", "10月", "11月", "12月", "1月", "2月", "3月", "4月", "5月", "6月"], id: \.self) { month in
                        Text(month)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var heatmap: some View {
        VStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<53, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Theme.accent.opacity(heatLevel(row: row, column: column)))
                            .frame(width: 9, height: 9)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func heatLevel(row: Int, column: Int) -> Double {
        let index = column * 7 + row
        if let buckets = store.runtimeTokenUsage?.dailyBuckets,
           !buckets.isEmpty,
           index < buckets.count {
            let maxTokens = max(buckets.map(\.tokens).max() ?? 1, 1)
            let ratio = Double(buckets[index].tokens) / Double(maxTokens)
            return buckets[index].tokens == 0 ? 0.08 : 0.12 + min(ratio, 1.0) * 0.65
        }
        let value = (row * 11 + column * 7) % 6
        return value == 0 ? 0.08 : 0.12 + Double(value) * 0.13
    }

    private var insightCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("活动洞察")
                    .font(.system(size: 13, weight: .semibold))
                metricRow("账户", store.runtimeAccount.map(SessionStore.accountDisplayName) ?? "未返回")
                metricRow("计划", store.runtimeAccount?.planType ?? "未返回")
                metricRow("累计 Token", tokenText(store.runtimeTokenUsage?.lifetimeTokens))
                metricRow("单日峰值", tokenText(store.runtimeTokenUsage?.peakDailyTokens))
                metricRow("连续天数", daysText(store.runtimeTokenUsage?.currentStreakDays))
            }
        }
    }

    private var pluginsUsageCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("已启用插件")
                    .font(.system(size: 13, weight: .semibold))
                let enabledPlugins = Array(store.runtimePlugins.filter(\.enabled).prefix(5))
                if enabledPlugins.isEmpty {
                    Text("暂无已启用插件")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(enabledPlugins) { plugin in
                        pluginUsage("@\(plugin.name)", plugin.marketplaceDisplayName)
                    }
                }
            }
        }
    }

    private var configurationPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            paneTitle("配置", subtitle: "配置审批策略和沙盒设置 了解更多")

            SettingsSection(title: "自定义 config.toml 设置") {
                SettingsCard {
                    HStack {
                        menuValue(store.selectedProject.name, values: store.projects.map(\.name))
                        Spacer(minLength: 0)
                        Button("打开 config.toml ↗") {
                            store.openCodexConfigFile()
                        }
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.info)
                            .buttonStyle(.plain)
                    }
                }
            }

            SettingsSection(title: "app-server 读取结果") {
                SettingsCard {
                    configMetric("模型", store.runtimeConfig?.model ?? "未设置")
                    configMetric("模型提供方", store.runtimeConfig?.modelProvider ?? "默认")
                    configMetric("批准策略", store.runtimeConfig?.approvalPolicy ?? "默认")
                    configMetric("审批路由", store.runtimeConfig?.approvalsReviewer ?? "用户")
                    configMetric("沙盒", store.runtimeConfig?.sandboxMode ?? "默认")
                    configMetric("默认权限", store.runtimeConfig?.defaultPermissions ?? store.runtimeDefaultPermissionsProfile)
                    configMetric("推理强度", store.runtimeConfig?.reasoningEffort ?? "默认")
                    configMetric("推理摘要", store.runtimeConfig?.reasoningSummary ?? "默认")
                    configMetric("服务层级", store.runtimeConfig?.serviceTier ?? "默认")
                    configMetric("生成记忆", boolMetric(store.runtimeConfig?.memoryGenerateMemories))
                    configMetric("使用记忆", boolMetric(store.runtimeConfig?.memoryUseMemories))
                    configMetric("外部上下文跳过记忆", boolMetric(store.runtimeConfig?.memoryDisableOnExternalContext))
                    configMetric("配置层", "\(store.runtimeConfig?.layerCount ?? 0)")
                    configMetric("desktop 键", store.runtimeConfig?.desktopKeys.joined(separator: "、") ?? "无")
                }
            }

            SettingsCard {
                SettingsValueRow(title: "批准策略", description: "选择 Codex 何时请求批准") {
                    approvalMenu
                }
                SettingsValueRow(title: "审批路由", description: "选择由你审批，还是交给 Codex 自动审查风险") {
                    approvalsReviewerMenu
                }
                SettingsValueRow(title: "沙盒设置", description: "选择 Codex 的命令执行权限") {
                    sandboxMenu
                }
            }

            SettingsSection(title: "工作空间依赖项") {
                SettingsCard {
                    SettingsValueRow(title: "当前版本", description: nil) {
                        Text("26.601.10930")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    SettingsToggleRow(title: "Codex 依赖项", description: "允许 Codex 安装并提供随附的 Node.js 和 Python 工具", isOn: .constant(true))
                    SettingsValueRow(title: "诊断 Codex 工作空间中的问题", description: "检查当前捆绑包并记录诊断日志") {
                        Button("诊断") {
                            Task { await store.diagnoseWorkspaceRuntime() }
                        }
                            .buttonStyle(ChipButtonStyle())
                    }
                    SettingsValueRow(title: "重置并安装工作空间", description: "删除本地捆绑包，重新下载后再重新加载工具") {
                        Button("打开 .codex") {
                            store.revealCodexHomeSubfolder("")
                        }
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.danger)
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var personalizationPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            paneTitle("个性化")

            SettingsCard {
                SettingsValueRow(title: "个性", description: "选择 Codex 回复的默认语气") {
                    personalityMenu
                }
            }

            SettingsSection(title: "自定义指令", description: "为你的项目向 Codex 提供额外说明和上下文。了解更多") {
                VStack(alignment: .trailing, spacing: 10) {
                    TextEditor(text: $customInstructions)
                        .font(Theme.mono(12))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 150)
                        .background(Theme.fillSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    HStack {
                        Text(instructionsStatus.isEmpty ? store.runtimeCatalogStatusText : instructionsStatus)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Button("保存") {
                            instructionsStatus = "正在保存…"
                            Task {
                                await store.saveInstructions(customInstructions)
                                instructionsStatus = store.runtimeCatalogStatusText
                            }
                        }
                        .buttonStyle(ChipButtonStyle(prominent: true))
                    }
                }
            }

            SettingsSection(title: "记忆（实验性）", description: "设置 Codex 如何收集、保留和整合记忆。了解更多") {
                SettingsCard {
                    SettingsToggleRow(title: "启用记忆", description: "从聊天中生成新记忆，并将其带入新聊天", isOn: memoryEnabledBinding)
                    VStack(alignment: .leading, spacing: 6) {
                        SettingsToggleRow(title: "Chronicle 研究预览", description: "通过屏幕上下文增强记忆。了解更多", isOn: $chronicleEnabled)
                        HStack(spacing: 6) {
                            Text("状态：")
                                .font(.system(size: 11.5))
                                .foregroundStyle(Theme.textSecondary)
                            Text("运行中")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(Theme.success)
                        }
                        .padding(.leading, 2)
                    }
                    SettingsToggleRow(title: "跳过工具辅助对话", description: "请勿从使用了 MCP 工具或网页搜索的对话中生成记忆", isOn: skipToolChatsBinding)
                    SettingsValueRow(title: "重置记忆", description: "删除所有 Codex 记忆") {
                        Button("重置") {
                            confirmResetMemory()
                        }
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.danger)
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var mcpServersPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("MCP 服务器", subtitle: "来自 app-server 的 mcpServerStatus/list")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshRuntimeMCPServers() }
                }
                .buttonStyle(ChipButtonStyle())
            }
            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)

            runtimeErrorsSection

            if store.runtimeMCPServers.isEmpty {
                emptySettingsState(symbol: "point.3.connected.trianglepath.dotted", title: "没有已配置的 MCP 服务器", detail: "app-server 已读取当前 config；若配置了 MCP 但这里为空，请检查 config.toml。")
            } else {
                VStack(spacing: 10) {
                    ForEach(store.runtimeMCPServers) { server in
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "point.3.connected.trianglepath.dotted")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Theme.accent)
                                    Text(server.title)
                                        .font(.system(size: 13.5, weight: .semibold))
                                    Spacer(minLength: 0)
                                    statusBadge(mcpAuthName(server.authStatus), ok: server.authStatus != "notLoggedIn")
                                }
                                metricRow("名称", server.name)
                                metricRow("版本", server.version ?? "未知")
                                metricRow("工具", server.toolNames.isEmpty ? "无" : server.toolNames.prefix(8).joined(separator: "、"))
                                metricRow("资源", "\(server.resourceCount) 个资源 · \(server.resourceTemplateCount) 个模板")
                            }
                        }
                    }
                }
            }
        }
    }

    private var hooksPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("钩子", subtitle: "来自 app-server 的 hooks/list")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshRuntimeHooks() }
                }
                .buttonStyle(ChipButtonStyle())
            }
            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)

            runtimeErrorsSection

            if store.runtimeHooks.isEmpty {
                emptySettingsState(symbol: "link", title: "没有已发现的钩子", detail: "当前工作区没有启用 Codex hooks，或 config.toml 中未声明 hooks。")
            } else {
                VStack(spacing: 10) {
                    ForEach(store.runtimeHooks) { hook in
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: hook.enabled ? "link.circle.fill" : "link.circle")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(hook.enabled ? Theme.success : Theme.textSecondary)
                                    Text(hook.eventName)
                                        .font(.system(size: 13.5, weight: .semibold))
                                    Spacer(minLength: 0)
                                    statusBadge(hookTrustName(hook.trustStatus), ok: hook.trustStatus == "trusted" || hook.trustStatus == "managed")
                                }
                                metricRow("处理器", hook.handlerType)
                                metricRow("匹配器", hook.matcher ?? "全部")
                                metricRow("命令", hook.command ?? "非命令钩子")
                                metricRow("来源", "\(hookSourceName(hook.source)) · \(Project.abbreviate(hook.sourcePath))")
                                metricRow("超时", "\(hook.timeoutSec) 秒")
                            }
                        }
                    }
                }
            }
        }
    }

    private var gitPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("Git", subtitle: "来自 app-server 旧协议 gitDiffToRemote")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshWorkspaceGitDiff() }
                }
                .buttonStyle(ChipButtonStyle())
            }

            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)

            runtimeErrorsSection

            SettingsCard {
                VStack(alignment: .leading, spacing: 10) {
                    metricRow("工作区", Project.abbreviate(store.workspacePath))
                    metricRow("当前分支", store.selectedProject.branch ?? "未检测到")
                    metricRow("远端基准 SHA", store.workspaceGitDiff?.sha?.prefix(12).description ?? "未返回")
                    let parsed = SessionStore.diffSummary(store.workspaceGitDiff?.diff ?? "")
                    metricRow("差异", "\(parsed.files) 个文件 · +\(parsed.additions) −\(parsed.deletions)")
                    if !store.workspaceGitStatusText.isEmpty {
                        metricRow("本地状态", "command/exec 已读取")
                    }
                }
            }

            SettingsSection(title: "远端差异预览") {
                if let diff = store.workspaceGitDiff?.diff, !diff.isEmpty {
                    SettingsCard {
                        ScrollView(.horizontal) {
                            Text(diffPreview(diff))
                                .font(Theme.mono(11.5))
                                .foregroundStyle(Theme.textPrimary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else if !store.workspaceGitStatusText.isEmpty {
                    SettingsCard {
                        ScrollView(.horizontal) {
                            Text(store.workspaceGitStatusText)
                                .font(Theme.mono(11.5))
                                .foregroundStyle(Theme.textPrimary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else {
                    emptySettingsState(symbol: "arrow.triangle.branch", title: "没有远端差异", detail: "gitDiffToRemote 返回空 diff，或当前工作区没有可比较的远端分支。")
                }
            }
        }
    }

    private var archivedChatsPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("已归档对话", subtitle: "来自 app-server 的 thread/list archived=true")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshArchivedThreads() }
                }
                .buttonStyle(ChipButtonStyle())
            }

            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)

            runtimeErrorsSection

            if store.archivedRuntimeThreads.isEmpty {
                emptySettingsState(symbol: "archivebox", title: "没有已归档对话", detail: "thread/list 没有返回 archived=true 的对话。")
            } else {
                VStack(spacing: 10) {
                    ForEach(store.archivedRuntimeThreads) { thread in
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "archivebox")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Theme.textSecondary)
                                    Text(thread.title)
                                        .font(.system(size: 13.5, weight: .semibold))
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                    Button("恢复") {
                                        Task { await store.unarchiveRuntimeThread(thread) }
                                    }
                                    .buttonStyle(ChipButtonStyle())
                                }
                                if !thread.preview.isEmpty {
                                    Text(thread.preview)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(2)
                                }
                                metricRow("线程 ID", thread.id)
                                metricRow("工作区", thread.cwd.map(Project.abbreviate) ?? "未返回")
                                metricRow("提供方", thread.modelProvider ?? "未返回")
                                metricRow("更新时间", thread.updatedAt ?? "未返回")
                                metricRow("Git", thread.gitBranch ?? thread.gitSHA ?? "未返回")
                            }
                        }
                    }
                }
            }
        }
    }

    private var keyboardShortcutsPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            paneTitle("键盘快捷键", subtitle: "来自 RaytoneCodex 原生命令菜单，和顶部菜单保持一致")

            SettingsCard {
                VStack(alignment: .leading, spacing: 12) {
                    shortcutRow("新建对话", "⌘N", "创建本地线程并切回主对话")
                    shortcutRow("运行", "⌘↩", "发送 Composer 内容到 Codex app-server")
                    shortcutRow("刷新运行时", "⌘R", "重新检测内置 Codex CLI")
                    shortcutRow("删除对话", "⌘⌫", "删除当前本地线程")
                    shortcutRow("切换工具面板", "⌥⌘I", "显示或隐藏右侧工具面板")
                    shortcutRow("文件 / 浏览器 / 终端", "⌘P / ⌘T / ⌃`", "打开对应工具")
                    shortcutRow("设置", "⌘,", "进入设置页")
                }
            }
        }
    }

    private var appSnapshotsPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("应用快照", subtitle: "来自 configRequirements/read.allowAppshots 和 app/list.screenshots")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshIntegrationRuntime(forceRefetchApps: true) }
                }
                .buttonStyle(ChipButtonStyle())
            }

            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
            runtimeErrorsSection

            SettingsCard {
                metricRow("受管策略", optionalBoolText(store.runtimeRequirements?.allowAppSnapshots))
                metricRow("应用目录", "\(store.runtimeApps.count) 个 app")
                metricRow("含快照说明", "\(store.runtimeApps.filter { !$0.screenshotPrompts.isEmpty }.count) 个 app")
                metricRow("来源", "app/list")
            }

            let snapshotApps = store.runtimeApps.filter { !$0.screenshotPrompts.isEmpty }
            if snapshotApps.isEmpty {
                emptySettingsState(symbol: "rectangle.dashed", title: "没有应用快照元数据", detail: "app/list 没有返回 screenshots；如果远端目录不可用，会在运行时提示中显示真实错误。")
            } else {
                VStack(spacing: 10) {
                    ForEach(snapshotApps.prefix(12)) { app in
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(app.name)
                                        .font(.system(size: 13.5, weight: .semibold))
                                    Spacer(minLength: 0)
                                    statusBadge(app.isEnabled ? "启用" : "停用", ok: app.isEnabled)
                                }
                                if let description = app.description {
                                    Text(description)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(2)
                                }
                                metricRow("快照提示", "\(app.screenshotPrompts.count) 条")
                                metricRow("插件", app.pluginDisplayNames.isEmpty ? "未关联" : app.pluginDisplayNames.joined(separator: "、"))
                            }
                        }
                    }
                }
            }
        }
    }

    private var browserSettingsPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("浏览器", subtitle: "内置 WKWebView + Codex Browser/Chrome 插件状态")
                Spacer(minLength: 0)
                Button("打开示例") {
                    store.openBrowserSample()
                    store.route = .thread
                }
                .buttonStyle(ChipButtonStyle())
            }

            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
            runtimeErrorsSection

            SettingsCard {
                metricRow("当前页面", store.browserURL?.absoluteString ?? "未打开")
                metricRow("标题", store.browserTitle)
                metricRow("截图状态", store.browserScreenshotStatusText.isEmpty ? "未截图" : store.browserScreenshotStatusText)
                metricRow("工具面板", store.toolPanel == .browser ? "浏览器已打开" : "未打开")
            }

            integrationPluginSection(
                title: "浏览器插件",
                plugins: matchingPlugins(["browser", "chrome"])
            )
        }
    }

    private var computerControlPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("电脑操控", subtitle: "来自 configRequirements/read.computerUse 和 computer-use 插件")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshIntegrationRuntime() }
                }
                .buttonStyle(ChipButtonStyle())
            }

            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
            runtimeErrorsSection

            SettingsCard {
                metricRow("锁屏电脑操控", optionalBoolText(store.runtimeRequirements?.allowLockedComputerUse))
                metricRow("权限配置", store.runtimeRequirements?.defaultPermissions ?? "未返回")
                metricRow("受管 hooks", optionalBoolText(store.runtimeRequirements?.managedHooksOnly))
                metricRow("来源", "configRequirements/read")
            }

            integrationPluginSection(
                title: "电脑操控插件",
                plugins: matchingPlugins(["computer-use", "computer"])
            )
        }
    }

    private var connectionsPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("连接", subtitle: "来自 remoteControl/status/read、mcpServerStatus/list 和 app/list")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshIntegrationRuntime() }
                }
                .buttonStyle(ChipButtonStyle())
            }

            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
            runtimeErrorsSection

            SettingsCard {
                metricRow("远程控制", remoteControlName(store.runtimeRemoteControlStatus?.status))
                metricRow("服务器", store.runtimeRemoteControlStatus?.serverName ?? "未返回")
                metricRow("安装 ID", store.runtimeRemoteControlStatus?.installationID ?? "未返回")
                metricRow("环境 ID", store.runtimeRemoteControlStatus?.environmentID ?? "未返回")
            }

            SettingsSection(title: "MCP 连接") {
                if store.runtimeMCPServers.isEmpty {
                    emptySettingsState(symbol: "point.3.connected.trianglepath.dotted", title: "没有 MCP 连接", detail: "mcpServerStatus/list 没有返回服务器。")
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.runtimeMCPServers.prefix(8)) { server in
                            SettingsCard {
                                metricRow(server.title, mcpAuthName(server.authStatus))
                                metricRow("工具", "\(server.toolNames.count) 个")
                            }
                        }
                    }
                }
            }

            SettingsSection(title: "应用连接") {
                if store.runtimeApps.isEmpty {
                    emptySettingsState(symbol: "globe", title: "没有应用目录", detail: "app/list 没有返回应用。")
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.runtimeApps.prefix(8)) { app in
                            SettingsCard {
                                metricRow(app.name, app.isAccessible ? "可访问" : "不可访问")
                                metricRow("状态", app.isEnabled ? "启用" : "停用")
                            }
                        }
                    }
                }
            }
        }
    }

    private var environmentsPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("环境", subtitle: "来自 permissionProfile/list、configRequirements/read 和当前 bundle")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshIntegrationRuntime() }
                }
                .buttonStyle(ChipButtonStyle())
            }

            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
            runtimeErrorsSection

            SettingsCard {
                metricRow("工作区", Project.abbreviate(store.workspacePath))
                metricRow("Codex CLI", Project.abbreviate(store.runtimePath))
                metricRow("运行时", store.runtimeSummary)
                metricRow("Sidecar", store.sidecarStatusText)
                metricRow("网络要求", optionalBoolText(store.runtimeRequirements?.networkEnabled))
            }

            SettingsSection(title: "权限配置") {
                if store.runtimePermissionProfiles.isEmpty {
                    emptySettingsState(symbol: "lock.shield", title: "没有权限配置", detail: "permissionProfile/list 没有返回自定义 profile；Codex 会使用默认权限。")
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.runtimePermissionProfiles) { profile in
                            SettingsCard {
                                metricRow(profile.id, profile.description ?? "无描述")
                            }
                        }
                    }
                }
            }
        }
    }

    private var worktreesPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("工作树", subtitle: "通过 app-server command/exec 读取 git worktree list")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshWorkspaceWorktrees() }
                }
                .buttonStyle(ChipButtonStyle())
            }

            Text(store.runtimeCatalogStatusText)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
            runtimeErrorsSection

            if store.workspaceWorktrees.isEmpty {
                emptySettingsState(symbol: "rectangle.split.3x1", title: "没有检测到工作树", detail: "git worktree list 没有返回条目，或当前目录不是 Git 工作区。")
            } else {
                VStack(spacing: 10) {
                    ForEach(store.workspaceWorktrees, id: \.self) { path in
                        SettingsCard {
                            metricRow(Project.abbreviate(path), path == store.workspacePath ? "当前" : "可用")
                        }
                    }
                }
            }
        }
    }

    private var appearancePane: some View {
        VStack(alignment: .leading, spacing: 22) {
            paneTitle("外观", subtitle: "选择 RaytoneCodex 的显示方式")
            SettingsCard {
                SettingsValueRow(title: "主题", description: "浅色、深色或跟随系统") {
                    segmented(values: ["浅色", "深色", "跟随系统"], selection: $appearance)
                }
                SettingsValueRow(title: "强调色", description: "使用系统强调色突出选择状态") {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 18, height: 18)
                        Text("系统")
                            .font(.system(size: 12.5, weight: .medium))
                    }
                }
            }
        }
    }

    private var runtimeErrorsSection: some View {
        Group {
            if !store.runtimeCatalogErrors.isEmpty {
                SettingsCard {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("运行时提示")
                            .font(.system(size: 13, weight: .semibold))
                        ForEach(store.runtimeCatalogErrors.prefix(5), id: \.self) { error in
                            Text(error)
                                .font(.system(size: 11.5))
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func emptySettingsState(symbol: String, title: String, detail: String) -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
        }
    }

    private func paneTitle(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func modeCard(id: String, symbol: String, title: String, subtitle: String) -> some View {
        Button {
            workMode = id
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 34, height: 34)
                    .background(Theme.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: workMode == id ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(workMode == id ? Theme.accent : Theme.textTertiary)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 92)
            .background(Theme.transcript)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(workMode == id ? Theme.accent : Theme.borderSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var approvalMenu: some View {
        Menu {
            ForEach(CodexApprovalPolicy.allCases, id: \.self) { policy in
                Button {
                    Task { await store.saveRuntimeApprovalPolicy(policy) }
                } label: {
                    Label(
                        SessionStore.approvalName(policy),
                        systemImage: policy == store.approval ? "checkmark" : "circle"
                    )
                }
            }
        } label: {
            menuLabel(SessionStore.approvalName(store.approval))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private var sandboxMenu: some View {
        Menu {
            ForEach(CodexSandboxMode.allCases, id: \.self) { mode in
                Button {
                    Task { await store.saveRuntimeSandboxMode(mode) }
                } label: {
                    Label(
                        ComposerView.sandboxName(mode),
                        systemImage: mode == store.sandbox ? "checkmark" : "circle"
                    )
                }
            }
        } label: {
            menuLabel(ComposerView.sandboxName(store.sandbox))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private var approvalsReviewerMenu: some View {
        Menu {
            ForEach(CodexApprovalsReviewer.allCases, id: \.self) { reviewer in
                Button {
                    Task { await store.saveRuntimeApprovalsReviewer(reviewer) }
                } label: {
                    Label(
                        SessionStore.approvalsReviewerName(reviewer),
                        systemImage: reviewer == store.approvalsReviewer ? "checkmark" : "circle"
                    )
                }
            }
        } label: {
            menuLabel(SessionStore.approvalsReviewerName(store.approvalsReviewer))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private var serviceTierMenu: some View {
        let values = ["标准", "更快", "更稳"]
        return Menu {
            ForEach(values, id: \.self) { value in
                Button {
                    Task { @MainActor in
                        await store.saveRuntimeServiceTier(label: value)
                    }
                } label: {
                    Label(
                        value,
                        systemImage: value == store.runtimeServiceTierLabel ? "checkmark" : "circle"
                    )
                }
            }
        } label: {
            menuLabel(store.runtimeServiceTierLabel)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private var personalityMenu: some View {
        Menu {
            ForEach(CodexPersonality.allCases, id: \.self) { value in
                Button {
                    Task { await store.saveRuntimePersonality(value) }
                } label: {
                    Label(
                        SessionStore.personalityName(value),
                        systemImage: value == store.personality ? "checkmark" : "circle"
                    )
                }
            }
        } label: {
            menuLabel(SessionStore.personalityName(store.personality))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private func menuValue(_ title: String, values: [String]) -> some View {
        Menu {
            ForEach(values, id: \.self) { value in
                Button(value) {
                    store.runtimeCatalogStatusText = "\(value) 已选择"
                }
            }
        } label: {
            menuLabel(title)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private func boolMetric(_ value: Bool?) -> String {
        guard let value else { return "默认" }
        return value ? "开启" : "关闭"
    }

    private func menuLabel(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12.5, weight: .medium))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Theme.fill)
        .clipShape(Capsule())
    }

    private func segmented(values: [String], selection: Binding<String>) -> some View {
        HStack(spacing: 1) {
            ForEach(values, id: \.self) { value in
                Button {
                    selection.wrappedValue = value
                } label: {
                    Text(value)
                        .font(.system(size: 12, weight: selection.wrappedValue == value ? .semibold : .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(selection.wrappedValue == value ? Theme.transcript : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Theme.fill)
        .clipShape(Capsule())
    }

    private func copyProfileShareSummary() {
        let account = store.runtimeAccount.map(SessionStore.accountDisplayName) ?? "未返回账户"
        let summary = """
        RaytoneCodex
        账户：\(account)
        运行时：\(store.runtimeSummary)
        工作区：\(Project.abbreviate(store.workspacePath))
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)
        profileStatus = "已复制分享摘要"
    }

    private func confirmResetMemory() {
        let alert = NSAlert()
        alert.messageText = "重置 Codex 记忆？"
        alert.informativeText = "这会调用 app-server 的 memory/reset 删除 Codex 记忆。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { await store.resetCodexMemory() }
    }

    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }

    private func shortcutRow(_ title: String, _ shortcut: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                Text(detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            Text(shortcut)
                .font(Theme.mono(12))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(Theme.fill)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    private func integrationPluginSection(title: String, plugins: [CodexRuntimePlugin]) -> some View {
        SettingsSection(title: title) {
            if plugins.isEmpty {
                emptySettingsState(symbol: "puzzlepiece.extension", title: "没有匹配插件", detail: "plugin/list 没有返回对应插件。")
            } else {
                VStack(spacing: 10) {
                    ForEach(plugins) { plugin in
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(plugin.displayName)
                                        .font(.system(size: 13.5, weight: .semibold))
                                    Spacer(minLength: 0)
                                    statusBadge(plugin.installed ? "已安装" : "未安装", ok: plugin.installed)
                                }
                                Text(plugin.summary)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(2)
                                metricRow("启用", plugin.enabled ? "是" : "否")
                                metricRow("来源", "\(plugin.marketplaceDisplayName) · \(plugin.sourceType)")
                            }
                        }
                    }
                }
            }
        }
    }

    private func matchingPlugins(_ tokens: [String]) -> [CodexRuntimePlugin] {
        store.runtimePlugins.filter { plugin in
            let haystack = [plugin.name, plugin.displayName, plugin.summary]
                .joined(separator: " ")
                .lowercased()
            return tokens.contains { haystack.contains($0.lowercased()) }
        }
    }

    private func optionalBoolText(_ value: Bool?) -> String {
        guard let value else { return "未配置" }
        return value ? "允许" : "禁止"
    }

    private func remoteControlName(_ value: String?) -> String {
        switch value {
        case "connected": "已连接"
        case "connecting": "连接中"
        case "disconnected": "未连接"
        case "disabled": "已停用"
        case nil: "未返回"
        default: value ?? "未返回"
        }
    }

    private func tokenText(_ value: Int?) -> String {
        guard let value else { return "未返回" }
        return SessionStore.compactNumber(value)
    }

    private func daysText(_ value: Int?) -> String {
        guard let value else { return "未返回" }
        return "\(value) 天"
    }

    private func durationText(_ seconds: Int?) -> String {
        guard let seconds else { return "未返回" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours) 小时 \(minutes) 分"
        }
        return "\(max(minutes, 1)) 分"
    }

    private func accountKindName(_ value: String?) -> String {
        switch value {
        case "chatgpt": "ChatGPT"
        case "apiKey": "API Key"
        case "amazonBedrock": "Amazon Bedrock"
        case "notLoggedIn", nil: "未登录"
        default: value ?? "未登录"
        }
    }

    private func rateLimitWindowText(_ window: CodexRuntimeRateLimitWindow?) -> String {
        guard let window else { return "未返回" }
        var pieces: [String] = []
        if let used = window.usedPercent {
            pieces.append("\(Int(used))%")
        }
        if let minutes = window.windowMinutes {
            pieces.append("\(minutes) 分钟")
        }
        if let resetAt = window.resetAt {
            pieces.append("重置 \(resetAt)")
        }
        return pieces.isEmpty ? "未返回" : pieces.joined(separator: " · ")
    }

    private func formatDecimal(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func diffPreview(_ diff: String) -> String {
        let lines = diff.components(separatedBy: .newlines)
        let preview = lines.prefix(160).joined(separator: "\n")
        if lines.count > 160 {
            return preview + "\n… 已截断 \(lines.count - 160) 行"
        }
        return preview
    }

    private func configMetric(_ label: String, _ value: String) -> some View {
        SettingsValueRow(title: label, description: nil) {
            Text(value.isEmpty ? "未设置" : value)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }

    private func pluginUsage(_ name: String, _ runs: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 22, height: 22)
                .background(Theme.fill)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(name)
                .font(.system(size: 12, weight: .medium))
            Spacer(minLength: 0)
            Text(runs)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func mcpAuthName(_ value: String) -> String {
        switch value {
        case "unsupported": "无需登录"
        case "notLoggedIn": "未登录"
        case "bearerToken": "Bearer Token"
        case "oAuth": "OAuth"
        default: value
        }
    }

    private func hookTrustName(_ value: String) -> String {
        switch value {
        case "managed": "托管"
        case "trusted": "已信任"
        case "untrusted": "未信任"
        case "modified": "已变更"
        default: value
        }
    }

    private func hookSourceName(_ value: String) -> String {
        switch value {
        case "system": "系统"
        case "user": "用户"
        case "project": "项目"
        case "plugin": "插件"
        case "sessionFlags": "会话"
        default: value
        }
    }
}

private struct SettingsSection<Content: View>: View {
    var title: String
    var description: String?
    @ViewBuilder var content: Content

    init(title: String, description: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                if let description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            content
        }
    }
}

private struct SettingsCard<Content: View>: View {
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

private struct SettingsToggleRow: View {
    var title: String
    var description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(description)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 14)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.vertical, 10)
    }
}

private struct SettingsValueRow<Trailing: View>: View {
    var title: String
    var description: String?
    @ViewBuilder var trailing: Trailing

    init(title: String, description: String?, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.description = description
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                if let description {
                    Text(description)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 14)
            trailing
        }
        .padding(.vertical, 10)
    }
}
