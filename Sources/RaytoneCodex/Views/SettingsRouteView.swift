import AppKit
import RaytoneCodexCore
import SwiftUI

struct SettingsRouteView: View {
    @ObservedObject var store: SessionStore

    @State private var search = ""
    @State private var accountAPIKeyDraft = ""
    @State private var showAccountAPIKeyLogin = false
    @State private var providerAPIKeyDraft = ""
    @State private var providerBaseURLDraft = ""
    @State private var providerModelDraft = ""
    @State private var providerEndpointDraftProviderID = ""
    @State private var providerStatusMessage = "未测试"
    @State private var instructionsStatus = ""
    @State private var profileStatus = ""
    @State private var didRequestSettingsBrowserSnapshotSmoke = false
    @State private var usageActivityScale = "每日"
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

    private var showInMenuBarBinding: Binding<Bool> {
        Binding(
            get: { store.desktopShowInMenuBar },
            set: { enabled in
                Task { @MainActor in
                    await store.saveRuntimeShowInMenuBar(enabled)
                }
            }
        )
    }

    private var bottomPanelBinding: Binding<Bool> {
        Binding(
            get: { store.desktopShowBottomPanel },
            set: { enabled in
                Task { @MainActor in
                    await store.saveRuntimeShowBottomPanel(enabled)
                }
            }
        )
    }

    private var preventSleepBinding: Binding<Bool> {
        Binding(
            get: { store.desktopPreventSleepWhileRunning },
            set: { enabled in
                Task { @MainActor in
                    await store.saveRuntimePreventSleepWhileRunning(enabled)
                }
            }
        )
    }

    private var terminalPositionBinding: Binding<String> {
        Binding(
            get: { store.desktopTerminalPosition },
            set: { position in
                Task { @MainActor in
                    await store.saveRuntimeTerminalPosition(position)
                }
            }
        )
    }

    private var appearanceBinding: Binding<String> {
        Binding(
            get: { store.desktopAppearance },
            set: { appearance in
                Task { @MainActor in
                    await store.saveRuntimeAppearance(appearance)
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
            requestSettingsBrowserSnapshotSmokeIfNeeded()
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
            case .configuration:
                await store.refreshRuntimeConfiguration()
            case .personalization:
                await store.refreshRuntimeCatalog()
                await store.refreshRealtimeVoicesForVoiceInput()
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

    private func requestSettingsBrowserSnapshotSmokeIfNeeded() {
        guard store.settingsPane == .browser,
              ProcessInfo.processInfo.environment["RAYTONE_CODEX_SETTINGS_BROWSER_SNAPSHOT_SMOKE"] == "1",
              !didRequestSettingsBrowserSnapshotSmoke else {
            return
        }

        didRequestSettingsBrowserSnapshotSmoke = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            store.openBrowserSampleAndCapture()
        }
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
                    SettingsValueRow(title: "默认打开目标", description: "默认打开文件和文件夹的位置") {
                        menuValue(store.desktopOpenTarget, values: ["iTerm2", "Terminal", "Finder"]) { value in
                            Task { @MainActor in
                                await store.saveRuntimeOpenTarget(value)
                            }
                        }
                    }
                    SettingsValueRow(title: "语言", description: "应用 UI 语言") {
                        menuValue(store.desktopLanguage, values: ["自动检测", "简体中文", "English"]) { value in
                            Task { @MainActor in
                                await store.saveRuntimeLanguage(value)
                            }
                        }
                    }
                    SettingsToggleRow(title: "在菜单栏中显示", description: "关闭主窗口后，仍在 macOS 菜单栏中保留 Codex", isOn: showInMenuBarBinding)
                    SettingsToggleRow(title: "底部面板", description: "在应用标题栏中显示底部面板控件", isOn: bottomPanelBinding)
                    SettingsValueRow(title: "默认终端位置", description: "选择终端快捷方式和环境操作在何处打开终端标签页") {
                        segmented(values: ["底部", "右侧"], selection: terminalPositionBinding)
                    }
                    SettingsToggleRow(title: "运行时防止系统休眠", description: "在 Codex 运行对话时，让电脑保持唤醒状态", isOn: preventSleepBinding)
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
                accountAuthControlGroup
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
                Text(store.runtimeProfileInitials)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Theme.transcript)
                    .frame(width: 76, height: 76)
                    .background(store.runtimeAccount == nil ? Theme.textTertiary : Theme.warning)
                    .clipShape(Circle())
                Text(store.runtimeProfileDisplayName)
                    .font(.system(size: 20, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 6) {
                    Text(store.runtimeProfileHandle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(store.runtimeAccount?.planType ?? accountKindName(store.runtimeAccount?.kind))
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 7)
                        .frame(height: 20)
                        .background(Theme.fill)
                        .clipShape(Capsule())
                    statusBadge(accountKindName(store.runtimeAccount?.kind), ok: store.runtimeAccount?.kind != nil && store.runtimeAccount?.kind != "notLoggedIn")
                }
                if let login = store.activeAccountLogin, let loginID = login.loginID {
                    Text("正在等待登录完成 · \(loginID)")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
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
                    SettingsValueRow(title: "连接测试", description: store.providerConnectionDetailText.isEmpty ? "OpenAI 使用 model/list；第三方 provider 使用 raytone-proxy /health" : store.providerConnectionDetailText) {
                        Text(store.providerConnectionStatusText)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
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
                providerUsageSummaryCard
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
                Divider()
                    .overlay(Theme.borderSoft)
                accountAuthControlGroup
            }
        }
    }

    @ViewBuilder
    private var accountAuthControlGroup: some View {
        HStack(spacing: 8) {
            if store.activeAccountLogin != nil {
                Button("取消登录") {
                    Task { await store.cancelAccountLogin() }
                }
                .buttonStyle(ChipButtonStyle())
            } else if store.runtimeAccount == nil || store.runtimeAccount?.kind == "notLoggedIn" {
                Button("登录 Codex") {
                    Task { await store.startAccountChatGPTLogin() }
                }
                .buttonStyle(ChipButtonStyle(tint: Theme.accent, prominent: true))
                Button("API Key") {
                    showAccountAPIKeyLogin = true
                }
                .buttonStyle(ChipButtonStyle())
                .popover(isPresented: $showAccountAPIKeyLogin, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("使用 OpenAI API Key 登录")
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("API Key 会由 Codex app-server 保存到当前 CODEX_HOME，不写入 RaytoneCodex 设置。")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        SecureField("sk-...", text: $accountAPIKeyDraft)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12.5))
                        HStack {
                            Spacer(minLength: 0)
                            Button("取消") {
                                accountAPIKeyDraft = ""
                                showAccountAPIKeyLogin = false
                            }
                            .buttonStyle(ChipButtonStyle())
                            Button("登录") {
                                let key = accountAPIKeyDraft
                                Task { @MainActor in
                                    let ok = await store.loginRuntimeAccountWithAPIKey(key)
                                    if ok {
                                        accountAPIKeyDraft = ""
                                        showAccountAPIKeyLogin = false
                                    }
                                }
                            }
                            .buttonStyle(ChipButtonStyle(tint: Theme.accent, prominent: true))
                            .disabled(accountAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(14)
                    .frame(width: 330)
                    .background(Theme.panel)
                }
            } else {
                Button("退出登录") {
                    Task { await store.logoutRuntimeAccount() }
                }
                .buttonStyle(ChipButtonStyle())
            }
            Button("刷新账户") {
                Task { await store.refreshAccountUsageRuntime() }
            }
            .buttonStyle(ChipButtonStyle())
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

    private var providerUsageSummaryCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: store.selectedProvider.usesSidecar ? "shippingbox" : "sparkles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text("当前 Provider")
                        .font(.system(size: 13.5, weight: .semibold))
                    Spacer(minLength: 0)
                    statusBadge(providerUsageBadgeText, ok: providerUsageBadgeOK)
                }
                metricRow("Provider", store.selectedProvider.displayName)
                metricRow("模型", store.selectedProvider.usesSidecar ? store.selectedProvider.model : (store.model.isEmpty ? store.selectedProvider.model : store.model))
                if let usage = store.providerUsage {
                    metricRow("请求", "\(usage.requests) 次 · 成功 \(usage.successfulResponses) · 失败 \(usage.failedResponses)")
                    metricRow("Provider Token", tokenText(usage.totalTokens))
                    metricRow("输入 / 输出", "\(tokenText(usage.inputTokens)) / \(tokenText(usage.outputTokens))")
                    metricRow("推理 Token", tokenText(usage.reasoningTokens))
                    metricRow("更新", providerUsageUpdatedText(usage.lastUpdatedUnixMs))
                    metricRow("来源", "raytone-proxy /usage")
                } else {
                    metricRow("状态", store.providerUsageStatusText)
                    metricRow("来源", store.selectedProvider.usesSidecar ? "raytone-proxy /usage" : "account/usage/read")
                }
                HStack {
                    Spacer(minLength: 0)
                    Button("刷新 Provider") {
                        Task { await store.refreshSelectedProviderUsage() }
                    }
                    .buttonStyle(ChipButtonStyle())
                }
            }
        }
    }

    private var providerUsageBadgeText: String {
        if store.selectedProvider.usesSidecar {
            store.providerUsage == nil ? "未读取" : "已读取"
        } else {
            "Codex 账户"
        }
    }

    private var providerUsageBadgeOK: Bool {
        store.selectedProvider.usesSidecar ? store.providerUsage != nil : true
    }

    private func providerUsageUpdatedText(_ unixMs: Int?) -> String {
        guard let unixMs, unixMs > 0 else {
            return "未返回"
        }
        let date = Date(timeIntervalSince1970: TimeInterval(unixMs) / 1000)
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func providerListRow(_ provider: RaytoneProviderConfiguration) -> some View {
        Button {
            store.selectProvider(provider.id)
            providerAPIKeyDraft = ""
            syncProviderEndpointDrafts(provider)
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

                SettingsValueRow(title: "模型", description: provider.usesSidecar ? "sidecar 请求使用的 Chat Completions 模型名" : "当前 provider 的默认模型") {
                    if provider.usesSidecar {
                        TextField("模型", text: $providerModelDraft)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .frame(width: 210)
                    } else {
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
                }

                SettingsValueRow(title: "Base URL", description: provider.usesSidecar ? "raytone-proxy 会把 Responses 请求转发到这个端点" : "Codex 原生 OpenAI 端点") {
                    if provider.usesSidecar {
                        TextField("https://api.example.com/v1", text: $providerBaseURLDraft)
                            .textFieldStyle(.roundedBorder)
                            .font(Theme.mono(11.5))
                            .frame(width: 260)
                    } else {
                        Text(provider.baseURL)
                            .font(.system(size: 11.5, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
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
                    if provider.usesSidecar {
                        Button("保存端点") {
                            Task {
                                await store.saveProviderEndpoint(
                                    providerID: provider.id,
                                    baseURL: providerBaseURLDraft,
                                    model: providerModelDraft
                                )
                                providerStatusMessage = store.providerConnectionStatusText
                                syncProviderEndpointDrafts(store.selectedProvider)
                            }
                        }
                        .buttonStyle(ChipButtonStyle(tint: Theme.accent, prominent: true))
                        .disabled(
                            providerBaseURLDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                providerModelDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    Button("刷新模型列表") {
                        store.selectProvider(provider.id)
                        syncProviderEndpointDrafts(provider)
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
                            do {
                                let draft = providerAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !draft.isEmpty {
                                    try store.saveProviderAPIKey(draft, providerID: provider.id)
                                    providerAPIKeyDraft = ""
                                }
                                Task {
                                    await store.testProviderConnection(providerID: provider.id)
                                    providerStatusMessage = store.providerConnectionStatusText
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
        .onAppear {
            if providerEndpointDraftProviderID != provider.id {
                syncProviderEndpointDrafts(provider)
            }
        }
        .onChange(of: provider.id) { _, _ in
            syncProviderEndpointDrafts(provider)
        }
    }

    private func syncProviderEndpointDrafts(_ provider: RaytoneProviderConfiguration) {
        providerEndpointDraftProviderID = provider.id
        providerBaseURLDraft = provider.baseURL
        providerModelDraft = provider.model
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
                    Text(usageActivityCaption)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    segmented(values: ["每日", "每周", "累计"], selection: $usageActivityScale)
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
            ForEach(0..<heatmapRows, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<53, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Theme.accent.opacity(heatLevel(row: row, column: column)))
                            .frame(width: 9, height: usageActivityScale == "每日" ? 9 : 18)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var heatmapRows: Int {
        usageActivityScale == "每日" ? 7 : 1
    }

    private var usageActivityCaption: String {
        let values = store.tokenUsageActivityValues(scale: usageActivityScale)
        guard !values.isEmpty else {
            return "\(usageActivityScale) · account/usage/read 未返回活动桶"
        }
        let total = values.reduce(0, +)
        return "\(usageActivityScale) · \(values.count) 个桶 · \(tokenText(total))"
    }

    private func heatLevel(row: Int, column: Int) -> Double {
        let values = store.tokenUsageActivityValues(scale: usageActivityScale)
        let index = usageActivityScale == "每日" ? column * 7 + row : column
        guard !values.isEmpty,
              index < values.count else {
            return 0.08
        }
        let maxTokens = max(values.max() ?? 1, 1)
        let ratio = Double(values[index]) / Double(maxTokens)
        return values[index] == 0 ? 0.08 : 0.12 + min(ratio, 1.0) * 0.65
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
                        projectMenuValue
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
                    configMetric("输出详细度", store.runtimeConfig?.modelVerbosity ?? "默认")
                    configMetric("服务层级", store.runtimeConfig?.serviceTier ?? "默认")
                    configMetric("生成记忆", boolMetric(store.runtimeConfig?.memoryGenerateMemories))
                    configMetric("使用记忆", boolMetric(store.runtimeConfig?.memoryUseMemories))
                    configMetric("外部上下文跳过记忆", boolMetric(store.runtimeConfig?.memoryDisableOnExternalContext))
                    configMetric("桌面设置", store.runtimeDesktopSettingsSummary)
                    configMetric("菜单栏", boolMetric(store.runtimeConfig?.desktopSettings.showInMenuBar))
                    configMetric("底部面板", boolMetric(store.runtimeConfig?.desktopSettings.showBottomPanel))
                    configMetric("防止休眠", boolMetric(store.runtimeConfig?.desktopSettings.preventSleepWhileRunning))
                    configMetric("终端位置", store.runtimeConfig?.desktopSettings.terminalPosition ?? "默认")
                    configMetric("主题", store.runtimeConfig?.desktopSettings.appearance ?? "默认")
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
                        Text(store.runtimeVersionDisplay)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    SettingsValueRow(title: "Codex CLI", description: "RaytoneCodex 会优先使用 App 内置 CLI；开发模式可由 RAYTONE_CODEX_CLI 覆盖") {
                        statusBadge(store.runtimeDependencyReady ? store.runtimeSourceDisplay : "未找到", ok: store.runtimeDependencyReady)
                    }
                    SettingsValueRow(title: "一体化状态", description: "用于确认安装包是否真正携带 Codex CLI") {
                        Text(store.runtimeBundlingDisplay)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    SettingsValueRow(title: "CLI 路径", description: "当前实际执行 codex app-server / codex exec 的二进制") {
                        Text(Project.abbreviate(store.runtimePath))
                            .font(Theme.mono(11.5))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    SettingsValueRow(title: "Sidecar", description: "第三方 provider 的本地转换层随 App bundle 分发") {
                        statusBadge(store.sidecarStatusText, ok: store.sidecarStatusText == "直连" || store.sidecarStatusText.contains("127.0.0.1"))
                    }
                    SettingsValueRow(title: "诊断 Codex 工作空间中的问题", description: "检查当前捆绑包并记录诊断日志") {
                        Button("诊断") {
                            Task { await store.diagnoseWorkspaceRuntime() }
                        }
                            .buttonStyle(ChipButtonStyle())
                    }
                    SettingsValueRow(title: "Codex 数据目录", description: "打开当前运行时使用的 CODEX_HOME，插件、技能和配置都从这里读取") {
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

    private var projectMenuValue: some View {
        Menu {
            ForEach(store.projects) { project in
                Button {
                    store.selectProjectForSettings(project.id)
                } label: {
                    Label(project.name, systemImage: project.id == store.selectedProject.id ? "checkmark" : "folder")
                }
            }
        } label: {
            menuLabel(store.selectedProject.name)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
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

            realtimeVoiceSection

            SettingsSection(title: "记忆（实验性）", description: "设置 Codex 如何收集、保留和整合记忆。了解更多") {
                SettingsCard {
                    SettingsToggleRow(title: "启用记忆", description: "从聊天中生成新记忆，并将其带入新聊天", isOn: memoryEnabledBinding)
                    VStack(alignment: .leading, spacing: 6) {
                        SettingsValueRow(title: "Chronicle 研究预览", description: "通过 app-server 的 skills/list / mcpServerStatus/list 检测屏幕上下文能力") {
                            HStack(spacing: 8) {
                                statusBadge(store.chronicleRuntimeStatusText, ok: store.chronicleRuntimeAvailable)
                                Button("刷新") {
                                    Task { await store.refreshRuntimeCatalog(forceReloadSkills: true) }
                                }
                                .buttonStyle(ChipButtonStyle())
                            }
                        }
                        Text(store.chronicleRuntimeDetailText)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
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

    private var realtimeVoiceSection: some View {
        SettingsSection(title: "实时语音", description: "麦克风按钮会先读取 Codex app-server 的 thread/realtime/listVoices，再请求 macOS 系统听写。") {
            SettingsCard {
                SettingsValueRow(title: "语音目录", description: store.voiceInputStatusText) {
                    HStack(spacing: 8) {
                        statusBadge(store.runtimeRealtimeVoices == nil ? "未读取" : "已读取", ok: store.runtimeRealtimeVoices != nil)
                        Button("刷新") {
                            Task { await store.refreshRealtimeVoicesForVoiceInput() }
                        }
                        .buttonStyle(ChipButtonStyle())
                    }
                }
                if let voices = store.runtimeRealtimeVoices {
                    metricRow("默认 v1", voices.defaultV1.isEmpty ? "未返回" : voices.defaultV1)
                    metricRow("默认 v2", voices.defaultV2.isEmpty ? "未返回" : voices.defaultV2)
                    metricRow("v1 语音", voiceListPreview(voices.v1))
                    metricRow("v2 语音", voiceListPreview(voices.v2))
                    metricRow("来源", "thread/realtime/listVoices")
                    if let updatedAt = store.runtimeRealtimeVoicesUpdatedAt {
                        metricRow("刷新时间", updatedAt.formatted(date: .omitted, time: .standard))
                    }
                } else {
                    Text("尚未读取实时语音目录。点击刷新会通过当前捆绑的 codex app-server 获取真实 voice catalog。")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var mcpServersPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                paneTitle("MCP 服务器", subtitle: "来自 app-server 的 mcpServerStatus/list")
                Spacer(minLength: 0)
                Button("重载") {
                    Task { await store.reloadRuntimeMCPServers() }
                }
                .buttonStyle(ChipButtonStyle())
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
                                    if mcpServerCanLogin(server) {
                                        Button("登录") {
                                            Task { await store.loginMCPServer(server) }
                                        }
                                        .buttonStyle(ChipButtonStyle(prominent: true))
                                    }
                                    statusBadge(mcpAuthName(server.authStatus), ok: server.authStatus != "notLoggedIn")
                                }
                                metricRow("名称", server.name)
                                metricRow("版本", server.version ?? "未知")
                                metricRow("工具", server.toolNames.isEmpty ? "无" : server.toolNames.prefix(8).joined(separator: "、"))
                                metricRow("资源", "\(server.resourceCount) 个资源 · \(server.resourceTemplateCount) 个模板")
                                if !server.tools.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(server.tools.prefix(4)) { tool in
                                            mcpToolRow(tool, server: server)
                                        }
                                    }
                                }
                                if !server.resources.isEmpty {
                                    VStack(alignment: .leading, spacing: 7) {
                                        ForEach(server.resources.prefix(4)) { resource in
                                            mcpResourceRow(resource, server: server)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if let preview = store.mcpToolCallPreview {
                SettingsSection(title: "工具结果", description: store.mcpToolCallStatusText) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 8) {
                            metricRow("服务器", preview.server)
                            metricRow("工具", preview.tool)
                            metricRow("状态", preview.isError ? "工具返回错误" : "成功")
                            Text(diffPreview(preview.textPreview))
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.textSecondary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Theme.fillSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                        }
                    }
                }
            }

            if let preview = store.mcpResourcePreview {
                SettingsSection(title: "资源预览", description: store.mcpResourceStatusText) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 8) {
                            metricRow("服务器", preview.server)
                            metricRow("URI", preview.requestedURI)
                            Text(diffPreview(preview.textPreview))
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.textSecondary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Theme.fillSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
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
                                    statusBadge(hookTrustName(hook.trustStatus), ok: hookIsTrusted(hook))
                                }
                                metricRow("处理器", hook.handlerType)
                                metricRow("匹配器", hook.matcher ?? "全部")
                                metricRow("命令", hook.command ?? "非命令钩子")
                                metricRow("来源", "\(hookSourceName(hook.source)) · \(Project.abbreviate(hook.sourcePath))")
                                metricRow("超时", "\(hook.timeoutSec) 秒")
                                HStack(spacing: 8) {
                                    if !hookIsTrusted(hook), !hook.currentHash.isEmpty {
                                        Button("信任") {
                                            Task { await store.trustRuntimeHook(hook) }
                                        }
                                        .buttonStyle(ChipButtonStyle(prominent: true))
                                    }
                                    Button(hook.enabled ? "停用" : "启用") {
                                        Task { await store.setRuntimeHookEnabled(hook, enabled: !hook.enabled) }
                                    }
                                    .buttonStyle(ChipButtonStyle())
                                    .disabled(hook.isManaged)
                                    Spacer(minLength: 0)
                                    if hook.isManaged {
                                        Text("托管 hook 由 Codex 策略控制")
                                            .font(.system(size: 11.5))
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                }
                                .disabled(store.runtimeCatalogIsRefreshing)
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
                paneTitle("Git", subtitle: "来自 app-server 的 gitDiffToRemote 与 command/exec")
                Spacer(minLength: 0)
                Button("刷新") {
                    Task {
                        await store.refreshWorkspaceGitDiff()
                        await store.refreshWorkspacePullRequestStatus()
                    }
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
                    metricRow("PR 状态", store.workspacePullRequestStatusText)
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
                Button("打开并截图") {
                    store.openBrowserSampleAndCapture()
                }
                .buttonStyle(ChipButtonStyle(prominent: true))
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
                if let pairing = store.runtimeRemoteControlPairing {
                    Divider()
                        .overlay(Theme.borderSoft)
                    metricRow("配对码", pairing.pairingCode)
                    if let manualCode = pairing.manualPairingCode {
                        metricRow("手动码", manualCode)
                    }
                    metricRow("配对环境", pairing.environmentID)
                    metricRow("领取状态", remotePairingClaimedText(store.runtimeRemoteControlPairingClaimed))
                    metricRow("过期时间", remotePairingExpiryText(pairing.expiresAt))
                    HStack(spacing: 8) {
                        Button("检查配对状态") {
                            Task { await store.refreshRemoteControlPairingStatus() }
                        }
                        .buttonStyle(ChipButtonStyle())
                        .disabled(store.runtimeCatalogIsRefreshing)
                    }
                    .padding(.top, 6)
                }
                Divider()
                    .overlay(Theme.borderSoft)
                    .padding(.vertical, 8)
                HStack {
                    Text("授权客户端")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer(minLength: 0)
                    Button("刷新客户端") {
                        Task { await store.refreshRemoteControlClients() }
                    }
                    .buttonStyle(ChipButtonStyle())
                    .disabled(store.runtimeCatalogIsRefreshing)
                }
                if store.runtimeRemoteControlClients.isEmpty {
                    Text(remoteClientEmptyText)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 6)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(store.runtimeRemoteControlClients) { client in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "iphone.and.arrow.forward")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(width: 18)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(client.displayName ?? client.clientID)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(remoteClientDetailText(client))
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(2)
                                }
                                Spacer(minLength: 0)
                                Button("撤销") {
                                    Task { await store.revokeRemoteControlClient(client) }
                                }
                                .buttonStyle(ChipButtonStyle())
                                .disabled(store.runtimeCatalogIsRefreshing)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                HStack(spacing: 8) {
                    Button("启用云端模式") {
                        Task { await store.enableRemoteControlMode() }
                    }
                    .buttonStyle(ChipButtonStyle(tint: Theme.accent, prominent: true))
                    .disabled(store.runtimeCatalogIsRefreshing)

                    Button("生成配对码") {
                        Task { await store.startRemoteControlPairing(manualCode: true) }
                    }
                    .buttonStyle(ChipButtonStyle())
                    .disabled(store.runtimeCatalogIsRefreshing)

                    Button("停用") {
                        Task { await store.disableRemoteControlMode() }
                    }
                    .buttonStyle(ChipButtonStyle())
                    .disabled(store.runtimeCatalogIsRefreshing)
                }
                .padding(.top, 4)
            }

            SettingsSection(title: "MCP 连接") {
                if store.runtimeMCPServers.isEmpty {
                    emptySettingsState(symbol: "point.3.connected.trianglepath.dotted", title: "没有 MCP 连接", detail: "mcpServerStatus/list 没有返回服务器。")
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.runtimeMCPServers.prefix(8)) { server in
                            SettingsCard {
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        metricRow(server.title, mcpAuthName(server.authStatus))
                                        metricRow("工具", "\(server.toolNames.count) 个")
                                    }
                                    Spacer(minLength: 0)
                                    if mcpServerCanLogin(server) {
                                        Button("登录") {
                                            Task { await store.loginMCPServer(server) }
                                        }
                                        .buttonStyle(ChipButtonStyle(prominent: true))
                                    }
                                }
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
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 10) {
                                        VStack(alignment: .leading, spacing: 5) {
                                            metricRow(app.name, app.isAccessible ? "可访问" : "不可访问")
                                            if let description = app.description, !description.isEmpty {
                                                Text(description)
                                                    .font(.system(size: 11.5))
                                                    .foregroundStyle(Theme.textSecondary)
                                                    .lineLimit(2)
                                            }
                                            HStack(spacing: 6) {
                                                statusBadge(app.isEnabled ? "启用" : "停用", ok: app.isEnabled)
                                                if let developer = app.developer, !developer.isEmpty {
                                                    statusBadge(developer, ok: true)
                                                }
                                                if let category = app.category, !category.isEmpty {
                                                    statusBadge(category, ok: true)
                                                }
                                            }
                                        }
                                        Spacer(minLength: 0)
                                        Button(app.installURL == nil ? "无链接" : (app.isAccessible ? "打开" : "安装")) {
                                            store.openRuntimeAppInstallURL(app)
                                        }
                                        .buttonStyle(ChipButtonStyle(prominent: app.installURL != nil && !app.isAccessible))
                                        .disabled(app.installURL == nil)
                                    }
                                    if !app.pluginDisplayNames.isEmpty {
                                        Text("关联插件：\(app.pluginDisplayNames.prefix(3).joined(separator: "、"))")
                                            .font(.system(size: 11.5))
                                            .foregroundStyle(Theme.textTertiary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    if let installURL = app.installURL, !installURL.isEmpty {
                                        Text(installURL)
                                            .font(Theme.mono(10.5))
                                            .foregroundStyle(Theme.textTertiary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                }
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
                    segmented(values: ["浅色", "深色", "跟随系统"], selection: appearanceBinding)
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
            Task { @MainActor in
                await store.saveRuntimeWorkMode(id: id)
            }
        } label: {
            let selected = store.runtimeWorkModeID == id
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
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(selected ? Theme.accent : Theme.textTertiary)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 92)
            .background(Theme.transcript)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(selected ? Theme.accent : Theme.borderSoft, lineWidth: 1)
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

    private func menuValue(_ title: String, values: [String], onSelect: @escaping (String) -> Void) -> some View {
        Menu {
            ForEach(values, id: \.self) { value in
                Button(value) {
                    onSelect(value)
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
        SessionStore.remoteControlStatusDisplayName(value)
    }

    private var remoteClientEmptyText: String {
        if store.runtimeRemoteControlStatus?.environmentID?.isEmpty == false ||
            store.runtimeRemoteControlPairing?.environmentID.isEmpty == false {
            return "remoteControl/client/list 没有返回授权客户端。"
        }
        return "remoteControl/status/read 尚未返回环境 ID，连接成功后会读取客户端列表。"
    }

    private func remotePairingClaimedText(_ value: Bool?) -> String {
        guard let value else { return "未查询" }
        return value ? "已领取" : "等待领取"
    }

    private func remotePairingExpiryText(_ value: Int) -> String {
        guard value > 0 else { return "未返回" }
        let date = Date(timeIntervalSince1970: TimeInterval(value))
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func remoteClientDetailText(_ client: CodexRemoteControlClient) -> String {
        var parts: [String] = []
        if let platform = client.platform, !platform.isEmpty {
            parts.append(platform)
        }
        if let deviceType = client.deviceType, !deviceType.isEmpty {
            parts.append(deviceType)
        }
        if let deviceModel = client.deviceModel, !deviceModel.isEmpty {
            parts.append(deviceModel)
        }
        if let appVersion = client.appVersion, !appVersion.isEmpty {
            parts.append("App \(appVersion)")
        }
        if let lastSeenAt = client.lastSeenAt {
            let date = Date(timeIntervalSince1970: TimeInterval(lastSeenAt))
            parts.append("上次在线 \(date.formatted(date: .abbreviated, time: .shortened))")
        }
        return parts.isEmpty ? client.clientID : parts.joined(separator: " · ")
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

    private func voiceListPreview(_ voices: [String]) -> String {
        guard !voices.isEmpty else { return "未返回" }
        let shown = voices.prefix(8).joined(separator: "、")
        if voices.count > 8 {
            return "\(shown) 等 \(voices.count) 个"
        }
        return shown
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

    private func mcpServerCanLogin(_ server: CodexRuntimeMCPServer) -> Bool {
        server.authStatus == "notLoggedIn"
    }

    private func mcpToolArgumentsBinding(_ tool: CodexRuntimeMCPTool, server: CodexRuntimeMCPServer) -> Binding<String> {
        let key = store.mcpToolCallKey(tool, server: server)
        return Binding(
            get: { store.mcpToolArgumentText[key] ?? "{}" },
            set: { store.mcpToolArgumentText[key] = $0 }
        )
    }

    private func mcpToolRow(_ tool: CodexRuntimeMCPTool, server: CodexRuntimeMCPServer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "hammer")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.displayName)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(tool.displayDescription)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Button("调用") {
                    Task { await store.callMCPTool(tool, from: server) }
                }
                .buttonStyle(ChipButtonStyle(prominent: true))
                .disabled(store.runtimeCatalogIsRefreshing)
            }
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("参数 JSON")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    TextEditor(text: mcpToolArgumentsBinding(tool, server: server))
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 54, maxHeight: 70)
                        .padding(6)
                        .background(Theme.fill)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                }
                if let inputSchema = tool.inputSchema {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("输入 schema")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Text(diffPreview(inputSchema.prettyJSONString))
                            .font(Theme.mono(10.5))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Theme.fill)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                    }
                }
            }
        }
        .padding(9)
        .background(Theme.fillSubtle)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    private func mcpResourceRow(_ resource: CodexRuntimeMCPResource, server: CodexRuntimeMCPServer) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(resource.displayName)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(resource.uri)
                    .font(Theme.mono(10.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
            Button("读取") {
                Task { await store.readMCPResource(resource, from: server) }
            }
            .buttonStyle(ChipButtonStyle())
            .disabled(store.runtimeCatalogIsRefreshing)
        }
        .padding(9)
        .background(Theme.fillSubtle)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
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

    private func hookIsTrusted(_ hook: CodexRuntimeHook) -> Bool {
        hook.trustStatus.localizedCaseInsensitiveCompare("trusted") == .orderedSame ||
            hook.trustStatus.localizedCaseInsensitiveCompare("managed") == .orderedSame
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
