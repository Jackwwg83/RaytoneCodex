import RaytoneCodexCore
import SwiftUI

private func pluginShareSummary(_ shareContext: CodexRuntimePluginShareContext) -> String {
    var pieces = ["共享"]
    if let discoverability = shareContext.discoverability, !discoverability.isEmpty {
        pieces.append(pluginShareDiscoverabilityName(discoverability))
    }
    if let creatorName = shareContext.creatorName, !creatorName.isEmpty {
        pieces.append("来自 \(creatorName)")
    }
    let version = shareContext.remoteVersion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    pieces.append(version.isEmpty ? shareContext.remotePluginID : "\(shareContext.remotePluginID)@\(version)")
    return pieces.joined(separator: " · ")
}

private func pluginShareRows(_ shareContext: CodexRuntimePluginShareContext) -> [String] {
    var rows = [pluginShareSummary(shareContext)]
    if let shareURL = shareContext.shareURL, !shareURL.isEmpty {
        rows.append("链接 · \(shareURL)")
    }
    if !shareContext.sharePrincipals.isEmpty {
        let principals = shareContext.sharePrincipals
            .prefix(4)
            .map { "\($0.name) · \(pluginShareRoleName($0.role)) · \(pluginSharePrincipalTypeName($0.principalType))" }
        rows.append(contentsOf: principals)
    }
    return rows
}

private func pluginShareDiscoverabilityName(_ value: String) -> String {
    switch value.uppercased() {
    case "LISTED": "公开列出"
    case "UNLISTED": "未列出"
    case "PRIVATE": "私有"
    default: value
    }
}

private func pluginShareRoleName(_ value: String) -> String {
    switch value.lowercased() {
    case "reader": "可读"
    case "editor": "可编辑"
    case "owner": "所有者"
    default: value
    }
}

private func pluginSharePrincipalTypeName(_ value: String) -> String {
    switch value.lowercased() {
    case "user": "用户"
    case "group": "团队"
    case "workspace": "工作区"
    default: value
    }
}

struct PluginsPage: View {
    @ObservedObject var store: SessionStore
    @State private var selectedTab: PluginTab = .plugins
    @State private var search = ""
    @State private var sourceFilter = "OpenAI 构建"
    @State private var stateFilter = "全部"

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var filteredPlugins: [CodexRuntimePlugin] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.runtimePlugins.filter { plugin in
            let matchesSource: Bool
            switch sourceFilter {
            case "全部来源":
                matchesSource = true
            case "共享插件":
                matchesSource = plugin.shareContext != nil
            default:
                matchesSource = plugin.marketplaceDisplayName.localizedCaseInsensitiveContains("OpenAI") ||
                    plugin.marketplaceDisplayName.localizedCaseInsensitiveContains("Codex official") ||
                    plugin.developerName?.localizedCaseInsensitiveContains("OpenAI") == true
            }
            let matchesState: Bool
            switch stateFilter {
            case "已安装":
                matchesState = plugin.installed
            case "未安装":
                matchesState = !plugin.installed
            default:
                matchesState = true
            }
            let matchesQuery = query.isEmpty ||
                plugin.displayName.localizedCaseInsensitiveContains(query) ||
                plugin.name.localizedCaseInsensitiveContains(query) ||
                plugin.summary.localizedCaseInsensitiveContains(query) ||
                plugin.marketplaceDisplayName.localizedCaseInsensitiveContains(query) ||
                plugin.shareContext?.remotePluginID.localizedCaseInsensitiveContains(query) == true ||
                plugin.shareContext?.creatorName?.localizedCaseInsensitiveContains(query) == true ||
                plugin.shareContext?.shareURL?.localizedCaseInsensitiveContains(query) == true
            return matchesSource && matchesState && matchesQuery
        }
    }

    private var filteredSkills: [CodexRuntimeSkill] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.runtimeSkills.filter {
            let matchesState: Bool
            switch stateFilter {
            case "已启用":
                matchesState = $0.enabled
            case "已停用":
                matchesState = !$0.enabled
            default:
                matchesState = true
            }
            let matchesQuery = query.isEmpty ||
                $0.displayName.localizedCaseInsensitiveContains(query) ||
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.summary.localizedCaseInsensitiveContains(query) ||
                $0.scope.localizedCaseInsensitiveContains(query)
            return matchesState && matchesQuery
        }
    }

    private var stateFilterValues: [String] {
        selectedTab == .plugins ? ["全部", "已安装", "未安装"] : ["全部", "已启用", "已停用"]
    }

    private var runtimeSkillExtraRootsText: String {
        store.runtimeSkillExtraRoots
            .map(Project.abbreviate)
            .joined(separator: "、")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 22) {
                    Text("让 Codex 按你的方式工作")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, 30)

                    searchRow

                    if selectedTab == .plugins {
                        featuredBanner
                        runtimeStatusCard
                        pluginDetailCard
                        pluginGrid
                    } else {
                        runtimeStatusCard
                        skillsList
                    }
                }
                .frame(maxWidth: 860)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            await store.refreshRuntimeCatalog()
        }
        .frame(minWidth: 620)
        .background(Theme.transcript)
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 18) {
            HStack(spacing: 18) {
                tabButton(.plugins)
                tabButton(.skills)
            }
            Spacer(minLength: 0)
            Button("管理") {
                store.route = .settings
                store.settingsPane = .mcpServers
            }
                .buttonStyle(ChipButtonStyle())
            Menu {
                Button("新建本地插件模板") {
                    selectedTab = .plugins
                    sourceFilter = "全部来源"
                    stateFilter = "全部"
                    Task { await store.createLocalPluginTemplate() }
                }
                Button("新建本地技能模板") {
                    selectedTab = .skills
                    stateFilter = "全部"
                    Task { await store.createLocalSkillTemplate() }
                }
                Button("添加运行时技能根目录…") {
                    selectedTab = .skills
                    stateFilter = "全部"
                    store.promptAddRuntimeSkillExtraRoot()
                }
                Button("清除运行时技能根目录") {
                    selectedTab = .skills
                    Task { await store.setRuntimeSkillExtraRoots(paths: []) }
                }
                .disabled(store.runtimeSkillExtraRoots.isEmpty)
                Divider()
                Button("添加插件市场源…") {
                    store.promptAddPluginMarketplace()
                }
                Button("升级插件市场源") {
                    Task { await store.upgradePluginMarketplaces() }
                }
                Button("移除插件市场源…") {
                    store.promptRemovePluginMarketplace()
                }
                Divider()
                Button("打开插件目录") {
                    Task { await store.revealCodexHomeSubfolder("plugins") }
                }
                Button("打开技能目录") {
                    Task { await store.revealCodexHomeSubfolder("skills") }
                }
            } label: {
                HStack(spacing: 5) {
                    Text("创建")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
            }
            .buttonStyle(ChipButtonStyle(prominent: true))
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            Button {
                Task { await store.refreshRuntimeCatalog(forceReloadSkills: true) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(GhostIconButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 36)
        .frame(height: 88, alignment: .bottom)
        .background(.bar)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private func tabButton(_ tab: PluginTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 8) {
                Text(tab.title)
                    .font(.system(size: 13.5, weight: selectedTab == tab ? .semibold : .medium))
                    .foregroundStyle(selectedTab == tab ? Theme.textPrimary : Theme.textSecondary)
                Capsule()
                    .fill(selectedTab == tab ? Theme.textPrimary : Color.clear)
                    .frame(width: 28, height: 2)
            }
        }
        .buttonStyle(.plain)
    }

    private var searchRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                TextField(selectedTab == .plugins ? "搜索插件" : "搜索技能", text: $search)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .frame(height: 38)
            .background(Theme.fill)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

            filterMenu(selection: $sourceFilter, values: ["OpenAI 构建", "共享插件", "全部来源"])
            filterMenu(selection: $stateFilter, values: stateFilterValues)
        }
    }

    private func filterMenu(selection: Binding<String>, values: [String]) -> some View {
        Menu {
            ForEach(values, id: \.self) { value in
                Button(value) {
                    selection.wrappedValue = value
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selection.wrappedValue)
                    .font(.system(size: 12.5, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 11)
            .frame(height: 38)
            .background(Theme.fill)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var featuredBanner: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.34), Theme.fillStrong, Theme.accent.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 20, weight: .semibold))
                    Text(featuredPromptText)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(16)
                .frame(width: 360)
                .background(Theme.transcript)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .shadow(color: Theme.border.opacity(0.28), radius: 16, x: 0, y: 8)

                Button("在对话中试用") {
                    if let plugin = store.runtimePlugins.first(where: { $0.installed && $0.enabled }) {
                        Task { await store.usePluginInComposer(plugin) }
                    } else {
                        store.route = .thread
                    }
                }
                .buttonStyle(ChipButtonStyle(prominent: true))
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 7) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? Theme.textPrimary : Theme.textPrimary.opacity(0.25))
                        .frame(width: index == 0 ? 7 : 6, height: index == 0 ? 7 : 6)
                }
            }
            .padding(.trailing, 18)
        }
        .frame(height: 210)
    }

    private var featuredPromptText: String {
        if let plugin = store.runtimePlugins.first(where: { $0.installed && $0.enabled }) ?? store.runtimePlugins.first {
            return "\(plugin.displayName) · \(plugin.summary)"
        }
        return "从 Codex app-server 读取插件后，可直接在对话中使用 @提及"
    }

    private var runtimeStatusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: store.runtimeCatalogIsRefreshing ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(store.runtimeCatalogErrors.isEmpty ? Theme.success : Theme.warning)
                Text(store.runtimeCatalogStatusText)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
                Button("刷新") {
                    Task { await store.refreshRuntimeCatalog(forceReloadSkills: true) }
                }
                .buttonStyle(ChipButtonStyle())
            }

            ForEach(store.runtimeCatalogErrors.prefix(3), id: \.self) { error in
                Text(error)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }

            if !store.runtimeSkillExtraRoots.isEmpty {
                Text("运行时技能根：\(runtimeSkillExtraRootsText)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if let installResult = store.runtimePluginInstallResult {
                Divider()
                    .overlay(Theme.borderSoft)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: installResult.appsNeedingAuth.isEmpty ? "checkmark.shield" : "key")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(installResult.appsNeedingAuth.isEmpty ? Theme.success : Theme.warning)
                        Text("plugin/install 返回")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Text(SessionStore.pluginAuthPolicyDisplayName(installResult.authPolicy))
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.textTertiary)
                        Spacer(minLength: 0)
                    }

                    if installResult.appsNeedingAuth.isEmpty {
                        Text("没有 app 需要额外授权。")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.textTertiary)
                    } else {
                        ForEach(Array(installResult.appsNeedingAuth.prefix(4))) { app in
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundStyle(Theme.textPrimary)
                                        .lineLimit(1)
                                    Text(app.description ?? "需要在 Codex app-server 返回的 installUrl 中完成授权")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.textTertiary)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 8)
                                Button("授权") {
                                    store.openPluginInstallAuthURL(app)
                                }
                                .buttonStyle(ChipButtonStyle(prominent: app.installURL != nil))
                                .disabled(app.installURL == nil)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fillSubtle)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private var pluginGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("插件")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            if filteredPlugins.isEmpty {
                emptyRuntimeCard(
                    symbol: "puzzlepiece.extension",
                    title: "app-server 暂未返回插件",
                    detail: "已调用 plugin/list；如果上方有错误，会显示真实失败原因。"
                )
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredPlugins) { plugin in
                        RuntimePluginRow(plugin: plugin, detail: {
                            Task { await store.readRuntimePluginDetail(plugin) }
                        }, toggle: {
                            Task { await store.togglePluginInstallation(plugin) }
                        })
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var pluginDetailCard: some View {
        if let detail = store.runtimePluginDetail {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 26, height: 26)
                        .background(Theme.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(detail.plugin.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(detail.description ?? detail.plugin.summary)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(3)
                        if let shareContext = detail.plugin.shareContext {
                            Text(pluginShareSummary(shareContext))
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    Spacer(minLength: 0)
                    Text(store.runtimePluginDetailStatusText)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }

                HStack(spacing: 8) {
                    pluginDetailMetric("技能", detail.skills.count)
                    pluginDetailMetric("MCP", detail.mcpServers.count)
                    pluginDetailMetric("钩子", detail.hooks.count)
                    pluginDetailMetric("App", detail.apps.count)
                }

                if detail.plugin.localPluginPath != nil || detail.plugin.shareContext != nil {
                    pluginShareActions(detail.plugin, shareContext: detail.plugin.shareContext)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if let shareContext = detail.plugin.shareContext {
                        pluginDetailList("共享", rows: pluginShareRows(shareContext))
                    }
                    if !detail.skills.isEmpty {
                        pluginSkillList(detail.skills)
                    }
                    if store.runtimePluginSkillPreview != nil {
                        pluginSkillPreviewCard
                    }
                    if !detail.mcpServers.isEmpty {
                        pluginDetailList("MCP 服务器", rows: detail.mcpServers)
                    }
                    if !detail.hooks.isEmpty {
                        pluginDetailList("钩子", rows: detail.hooks.map { "\($0.eventName) · \($0.key)" })
                    }
                    if !detail.apps.isEmpty {
                        pluginDetailList("App", rows: detail.apps.map { "\($0.name) · \($0.needsAuth ? "需要授权" : "已可用")" })
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.fillSubtle)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(Theme.borderSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
    }

    private func pluginSkillList(_ skills: [CodexRuntimePluginSkill]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("技能")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            ForEach(Array(skills.prefix(4))) { skill in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(skill.displayName) · \(skill.enabled ? "启用" : "停用")")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                        Text(skill.path.map(Project.abbreviate) ?? "plugin/read 未返回 path")
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer(minLength: 8)

                    Button {
                        Task { await store.readRuntimePluginSkillPreview(skill) }
                    } label: {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Theme.fill)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(skill.path == nil)
                    .help("读取技能内容")
                }
            }
        }
    }

    private var pluginSkillPreviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("插件技能内容")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(store.runtimePluginSkillPreviewStatusText)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer(minLength: 0)
                Button {
                    store.clearRuntimePluginSkillPreview()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 22, height: 22)
                        .background(Theme.fill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if let skill = store.runtimePluginSkillPreview {
                Text(skill.path.map(Project.abbreviate) ?? skill.name)
                    .font(Theme.mono(10.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            ScrollView {
                Text(store.runtimePluginSkillPreviewText.isEmpty ? "尚未读取到内容。" : store.runtimePluginSkillPreviewText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .frame(maxHeight: 180)
            .background(Theme.transcript)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .padding(.top, 2)
    }

    private func pluginShareActions(
        _ plugin: CodexRuntimePlugin,
        shareContext: CodexRuntimePluginShareContext?
    ) -> some View {
        HStack(spacing: 8) {
            if plugin.localPluginPath != nil {
                Button {
                    Task { await store.saveSharedPlugin(plugin) }
                } label: {
                    Label(shareContext == nil ? "创建共享链接" : "保存共享插件", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(ChipButtonStyle(prominent: true))
            }

            if shareContext != nil && plugin.localPluginPath == nil {
                Button {
                    Task { await store.checkoutSharedPlugin(plugin) }
                } label: {
                    Label("检出共享插件", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(ChipButtonStyle(prominent: true))
            }

            if let shareContext, shareContext.shareURL != nil {
                Button {
                    store.openPluginShareURL(plugin)
                } label: {
                    Label("打开链接", systemImage: "arrow.up.forward")
                }
                .buttonStyle(ChipButtonStyle())
            }

            if shareContext != nil {
                Menu {
                    Button("设为未列出链接") {
                        Task { await store.updateSharedPluginDiscoverability(plugin, discoverability: "UNLISTED") }
                    }
                    Button("设为私有") {
                        Task { await store.updateSharedPluginDiscoverability(plugin, discoverability: "PRIVATE") }
                    }
                } label: {
                    Label("共享权限", systemImage: "person.2.badge.gearshape")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .buttonStyle(ChipButtonStyle())
            }

            Spacer(minLength: 0)

            if shareContext != nil {
                Button {
                    Task { await store.deleteSharedPlugin(plugin) }
                } label: {
                    Label("删除分享", systemImage: "trash")
                }
                .buttonStyle(ChipButtonStyle(tint: Theme.danger))
            }
        }
    }

    private func pluginDetailMetric(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.transcript)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    private func pluginDetailList(_ title: String, rows: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            ForEach(rows.prefix(4), id: \.self) { row in
                Text(row)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var skillsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("技能")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            if filteredSkills.isEmpty {
                emptyRuntimeCard(
                    symbol: "sparkles",
                    title: "app-server 暂未返回技能",
                    detail: "已调用 skills/list；本地 skill 目录为空或读取失败时会显示在上方状态中。"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredSkills) { skill in
                        RuntimeSkillRow(
                            skill: skill,
                            detail: {
                                Task { await store.readRuntimeSkillPreview(skill) }
                            },
                            toggle: {
                                Task { await store.toggleSkill(skill) }
                            }
                        )
                    }
                    if store.runtimeSkillPreview != nil {
                        skillPreviewCard
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var skillPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("技能内容")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(store.runtimeSkillPreviewStatusText)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer(minLength: 8)

                Button {
                    store.clearRuntimeSkillPreview()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Theme.fill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if let skill = store.runtimeSkillPreview {
                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(Project.abbreviate(skill.path))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            ScrollView {
                Text(store.runtimeSkillPreviewText.isEmpty ? "尚未读取到内容。" : store.runtimeSkillPreviewText)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(maxHeight: 260)
            .background(Theme.fillSubtle)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        }
        .padding(14)
        .background(Theme.transcript)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private func emptyRuntimeCard(symbol: String, title: String, detail: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Theme.textSecondary)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            Text(detail)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(Theme.fillSubtle)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

private enum PluginTab {
    case plugins
    case skills

    var title: String {
        switch self {
        case .plugins: "插件"
        case .skills: "技能"
        }
    }
}

private struct RuntimePluginRow: View {
    let plugin: CodexRuntimePlugin
    var detail: () -> Void
    var toggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 34, height: 34)
                .background(Theme.fill)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(plugin.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(plugin.summary)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                Text("\(plugin.marketplaceDisplayName) · \(plugin.installed ? "已安装" : "未安装") · \(plugin.enabled ? "启用" : "停用")")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                if let shareContext = plugin.shareContext {
                    Text(pluginShareSummary(shareContext))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 8)

            Button(action: detail) {
                Image(systemName: "info")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(Theme.fill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button(action: toggle) {
                Image(systemName: plugin.installed ? "minus" : "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(plugin.installed ? Theme.textSecondary : Theme.textPrimary)
                    .frame(width: 24, height: 24)
                    .background(plugin.installed ? Theme.fill : Theme.fillStrong)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(plugin.installPolicy == "NOT_AVAILABLE")
        }
        .padding(.horizontal, 12)
        .frame(height: plugin.shareContext == nil ? 72 : 84)
        .background(Theme.transcript)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private var symbol: String {
        switch plugin.sourceType {
        case "remote": "cloud"
        case "git": "arrow.triangle.branch"
        case "local": "shippingbox"
        default: "puzzlepiece.extension"
        }
    }
}

private struct RuntimeSkillRow: View {
    let skill: CodexRuntimeSkill
    var detail: () -> Void
    var toggle: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: skill.enabled ? "sparkles" : "sparkle")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(skill.enabled ? Theme.accent : Theme.textSecondary)
                .frame(width: 34, height: 34)
                .background(Theme.fill)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(skill.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(skill.summary)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                Text("\(scopeName(skill.scope)) · \(skill.enabled ? "启用" : "停用") · \(Project.abbreviate(skill.path))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: detail) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(Theme.fill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button(skill.enabled ? "停用" : "启用", action: toggle)
                .buttonStyle(ChipButtonStyle(prominent: !skill.enabled))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.transcript)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private func scopeName(_ scope: String) -> String {
        switch scope {
        case "user": "用户"
        case "repo": "仓库"
        case "system": "系统"
        case "admin": "管理员"
        default: scope
        }
    }
}
