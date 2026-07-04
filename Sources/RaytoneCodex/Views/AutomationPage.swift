import RaytoneCodexCore
import SwiftUI

struct AutomationPage: View {
    @ObservedObject var store: SessionStore
    @State private var toast: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack(alignment: .bottom) {
                VStack(spacing: 18) {
                    Spacer(minLength: 60)
                    terminalCloud
                    Text("创建首个自动化")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    templateButtons
                    hooksRuntimeCard
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let toast {
                    Text(toast)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.transcript)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Theme.textPrimary)
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                }
            }
        }
        .task {
            await store.refreshRuntimeHooks()
        }
        .frame(minWidth: 620)
        .background(Theme.transcript)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("自动化")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 4) {
                    Text("按计划或按需运行聊天。")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.textSecondary)
                    Button("了解更多") {
                        store.route = .settings
                        store.settingsPane = .hooks
                    }
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.info)
                        .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)

            Button("查看模板") {
                store.prepareAutomationTemplate(
                    title: "自动化模板",
                    prompt: Self.templateLibraryPrompt
                )
            }
            .buttonStyle(ChipButtonStyle())

            Menu {
                Button("每日简报") {
                    store.prepareAutomationTemplate(title: "每日简报", prompt: Self.dailyBriefPrompt)
                }
                Button("每周回顾") {
                    store.prepareAutomationTemplate(title: "每周回顾", prompt: Self.weeklyReviewPrompt)
                }
                Button("项目监控") {
                    store.prepareAutomationTemplate(title: "项目监控", prompt: Self.projectMonitorPrompt)
                }
                Divider()
                Button("打开 Codex 配置") {
                    store.openCodexConfigFile()
                }
            } label: {
                HStack(spacing: 5) {
                    Text("通过聊天创建")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
            }
            .buttonStyle(ChipButtonStyle(prominent: true))
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .padding(.horizontal, 28)
        .padding(.top, 44)
        .padding(.bottom, 20)
        .background(.bar)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private var terminalCloud: some View {
        ZStack {
            Image(systemName: "cloud")
                .font(.system(size: 82, weight: .light))
                .foregroundStyle(Theme.textSecondary.opacity(0.55))
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
                .frame(width: 74, height: 50)
                .background(Theme.transcript)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    Text(">_")
                        .font(Theme.mono(20, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .offset(y: 8)
        }
        .frame(width: 120, height: 96)
    }

    private var templateButtons: some View {
        HStack(spacing: 10) {
            templateButton(symbol: "bell", title: "每日简报", prompt: Self.dailyBriefPrompt)
            templateButton(symbol: "calendar", title: "每周回顾", prompt: Self.weeklyReviewPrompt)
            templateButton(symbol: "sparkle.magnifyingglass", title: "项目监控", prompt: Self.projectMonitorPrompt)
        }
    }

    private func templateButton(symbol: String, title: String, prompt: String) -> some View {
        Button {
            Task { await store.installAutomationHookTemplate(title: title, prompt: prompt) }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Theme.fill)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var hooksRuntimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: store.runtimeCatalogIsRefreshing ? "arrow.triangle.2.circlepath" : "bolt.horizontal.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(store.runtimeCatalogErrors.isEmpty ? Theme.success : Theme.warning)
                Text("Codex 钩子运行时")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
                Text(store.runtimeCatalogStatusText)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button("刷新") {
                    Task { await store.refreshRuntimeHooks() }
                }
                .buttonStyle(ChipButtonStyle())
            }

            if store.runtimeHooks.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text("hooks/list 当前返回 0 个钩子")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text("开源 Codex app-server 目前没有稳定的自动化新增、读取、更新、删除接口；这里展示的是可落地的钩子自动化能力。你可以通过聊天生成钩子配置，或直接打开 config.toml 手动编辑。")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("打开 Codex 配置") {
                        store.openCodexConfigFile()
                    }
                    .buttonStyle(ChipButtonStyle(prominent: true))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.fillSubtle)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(store.runtimeHooks.prefix(5)) { hook in
                        HookRuntimeRow(hook: hook)
                    }
                }
            }

            ForEach(store.runtimeCatalogErrors.prefix(2), id: \.self) { error in
                Text(error)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: 720, alignment: .leading)
        .background(Theme.transcript)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private func showToast(_ message: String) {
        toast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if toast == message {
                toast = nil
            }
        }
    }

    private static let templateLibraryPrompt = """
    帮我基于 Codex 钩子设计一组本项目可用的自动化模板。请先读取当前仓库和 ~/.codex/config.toml，给出每日简报、每周回顾、项目监控三类钩子配置草案，并说明每个钩子的触发事件、命令、权限风险和验证方法。
    """

    private static let dailyBriefPrompt = """
    帮我为当前项目创建“每日简报”自动化方案。请使用 Codex 开源支持的钩子和 config.toml 能力，先检查现有 hooks/list 和仓库脚本，再生成最小可验证配置，要求输出验证命令和回滚方法。
    """

    private static let weeklyReviewPrompt = """
    帮我为当前项目创建“每周回顾”自动化方案。请基于 Codex 钩子或项目脚本实现，不要假设云端自动化接口存在；先审查现有配置，再给出可执行变更和端到端验证步骤。
    """

    private static let projectMonitorPrompt = """
    帮我为当前项目创建“项目监控”自动化方案。请检查 Codex 钩子、MCP 和本地脚本能力，设计一个能定期检查构建、测试、运行证据的最小闭环，并列出需要我确认的权限。
    """
}

private struct HookRuntimeRow: View {
    let hook: CodexRuntimeHook

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: hook.enabled ? "checkmark.circle.fill" : "pause.circle")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(hook.enabled ? Theme.success : Theme.textTertiary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(eventName)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(hook.handlerType)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 6)
                        .frame(height: 18)
                        .background(Theme.fill)
                        .clipShape(Capsule())
                    if hook.isManaged {
                        Text("托管")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(Theme.info)
                    }
                }
                Text(detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(sourceName) · \(trustName) · \(Project.abbreviate(hook.sourcePath))")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)

            Text("\(hook.timeoutSec)s")
                .font(Theme.mono(10.5, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(10)
        .background(Theme.fillSubtle)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    private var eventName: String {
        switch hook.eventName {
        case "pre_tool_use", "preToolUse": "工具前"
        case "post_tool_use", "postToolUse": "工具后"
        case "user_prompt_submit", "userPromptSubmit": "提交提示"
        case "session_start", "sessionStart": "会话开始"
        case "pre_compact", "preCompact": "压缩前"
        case "post_compact", "postCompact": "压缩后"
        case "permission_request", "permissionRequest": "请求权限"
        case "notification": "通知"
        case "stop": "停止"
        case "subagent_stop", "subagentStop": "子代理停止"
        case "subagent_start", "subagentStart": "子代理开始"
        default: hook.eventName
        }
    }

    private var detail: String {
        if let matcher = hook.matcher, let command = hook.command {
            return "\(matcher) · \(command)"
        }
        if let command = hook.command {
            return command
        }
        return hook.matcher ?? "无命令详情"
    }

    private var sourceName: String {
        switch hook.source {
        case "user": "用户配置"
        case "project": "项目配置"
        case "plugin": "插件"
        case "managed": "托管"
        default: hook.source
        }
    }

    private var trustName: String {
        switch hook.trustStatus {
        case "trusted": "已信任"
        case "untrusted": "待信任"
        case "modified": "已变更"
        default: hook.trustStatus
        }
    }
}
