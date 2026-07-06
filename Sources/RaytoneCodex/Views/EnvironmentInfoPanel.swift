import SwiftUI

struct EnvironmentInfoPanel: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool
    @State private var didRefreshEnvironment = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    environmentRows
                    activeGoalSection
                    progressSection
                    if !store.recentGuardianDeniedActions.isEmpty {
                        guardianDeniedSection
                    }
                    sourcesSection
                }
                .padding(16)
            }
        }
        .task {
            guard !didRefreshEnvironment else { return }
            didRefreshEnvironment = true
            await store.refreshWorkspaceBranches()
            await store.refreshWorkspaceGitDiff()
            await store.refreshWorkspacePullRequestStatus()
            await store.refreshWorkspaceWorktrees()
            await store.refreshLoadedRuntimeThreads()
            await store.syncSelectedThreadGitMetadata()
        }
        .frame(width: Theme.Layout.inspectorWidth)
        .frame(maxHeight: .infinity)
        .background(Theme.panel)
        .overlay(alignment: .leading) { Hairline(axis: .vertical) }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("环境信息")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
            Button {
                Task { await store.refreshWorkspaceEnvironment() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(GhostIconButtonStyle())
            .disabled(store.runtimeCatalogIsRefreshing)
            .help("刷新环境")
            Button {
                store.route = .settings
                store.settingsPane = .environments
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(GhostIconButtonStyle())
            .help("环境设置")
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { showInspector = false }
            } label: {
                Image(systemName: "sidebar.trailing")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(GhostIconButtonStyle())
            .help("关闭面板")
        }
        .padding(.horizontal, 14)
        .frame(height: Theme.Layout.headerHeight)
        .background(.bar)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private var environmentRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            EnvironmentInfoActionRow(symbol: "plus.forwardslash.minus", title: "变更", detail: changesText) {
                Button("审查") {
                    Task { await store.runReviewOfCurrentChanges(displayedPrompt: "审查当前环境变更") }
                }
                .buttonStyle(ChipButtonStyle())
                .disabled(store.isRunning || changesText == "无")
                Button {
                    Task { await store.runGitDiffInTerminal() }
                } label: {
                    Image(systemName: "terminal")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle(size: 26))
                .help("在终端查看 diff")
            }
            EnvironmentInfoRow(symbol: "desktopcomputer", title: "本地", trailing: Project.abbreviate(store.workspacePath))
            EnvironmentInfoActionRow(symbol: "arrow.triangle.branch", title: branchTitle, detail: branchStatusText) {
                branchMenu
                Button {
                    store.promptCreateWorkspaceBranch()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle(size: 26))
                .help("新建分支")
            }
            EnvironmentInfoActionRow(symbol: "arrow.triangle.branch", title: "线程 Git", detail: store.runtimeThreadMetadataStatusText) {
                Button {
                    Task { await store.syncSelectedThreadGitMetadata() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle(size: 26))
                .help("同步到 Codex 线程")
            }
            EnvironmentInfoActionRow(symbol: "tray.and.arrow.up", title: "提交或推送", detail: commitPushText) {
                Button("预检") {
                    Task { await store.runGitCommitPushPreflightInTerminal() }
                }
                .buttonStyle(ChipButtonStyle())
                Button("建库") {
                    Task { await store.runGitCreateRepositoryInTerminal() }
                }
                .buttonStyle(ChipButtonStyle())
                .disabled(store.terminalIsRunning)
                Button("推送") {
                    Task { await store.runGitPushCurrentBranchInTerminal() }
                }
                .buttonStyle(ChipButtonStyle(prominent: true))
                .disabled(store.terminalIsRunning)
            }
            EnvironmentInfoRow(symbol: "cpu", title: store.modelDisplayName, trailing: nil)
            EnvironmentInfoActionRow(symbol: "bubble.left.and.text.bubble.right", title: "已加载线程", detail: loadedThreadText) {
                Button {
                    Task { await store.refreshLoadedRuntimeThreads() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle(size: 26))
                .help("刷新已加载线程")
            }
            EnvironmentInfoRow(symbol: "shippingbox", title: "Sidecar", trailing: store.sidecarStatusText)
            EnvironmentInfoRow(symbol: "rectangle.split.3x1", title: "工作树", trailing: worktreeText)
            EnvironmentInfoActionRow(symbol: "chevron.left.forwardslash.chevron.right", title: "PR 状态", detail: pullRequestStatusText, secondary: true) {
                Button("创建") {
                    Task { await store.runGitCreatePullRequestInTerminal() }
                }
                .buttonStyle(ChipButtonStyle())
                .disabled(store.terminalIsRunning)
                Button {
                    Task { await store.refreshWorkspacePullRequestStatus() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle(size: 26))
                .help("刷新 PR 状态")
            }
        }
    }

    private var branchMenu: some View {
        Menu {
            if store.workspaceBranches.isEmpty {
                Text("暂无分支")
            } else {
                ForEach(store.workspaceBranches, id: \.self) { branch in
                    Button(branchTitle == branch ? "✓ \(branch)" : branch) {
                        Task { await store.checkoutWorkspaceBranch(branch) }
                    }
                }
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 26, height: 26)
                .background(Theme.fill)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("切换分支")
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "进度")
            VStack(alignment: .leading, spacing: 11) {
                ForEach(progressSteps) { step in
                    ProgressStepRow(step: step)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.fillSubtle)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(Theme.borderSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
    }

    @ViewBuilder
    private var activeGoalSection: some View {
        if let goal = store.selectedThread.activeGoal {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "目标")
                    ActiveGoalDetailCard(
                        goal: goal,
                        now: timeline.date,
                        runtimeStatus: store.runtimeCatalogStatusText,
                        refresh: {
                            Task { await store.refreshSelectedRuntimeGoal() }
                        },
                        edit: {
                            store.promptEditActiveGoal()
                        },
                        togglePause: {
                            Task {
                                if goal.status == .paused {
                                    await store.resumeActiveGoal()
                                } else {
                                    await store.pauseActiveGoal()
                                }
                            }
                        },
                        clear: {
                            Task { await store.clearActiveGoal() }
                        }
                    )
                }
            }
        }
    }

    private var guardianDeniedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "自动审批拒绝")
            VStack(spacing: 8) {
                ForEach(Array(store.recentGuardianDeniedActions.prefix(3))) { denial in
                    GuardianDeniedActionRow(denial: denial) {
                        Task { await store.approveGuardianDeniedAction(denial) }
                    }
                }
            }
        }
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "来源")
            VStack(spacing: 8) {
                ForEach(store.environmentSourceFacts) { fact in
                    SourceFactRow(fact: fact)
                }
            }
        }
    }

    private var changesText: String {
        if let diff = store.workspaceGitDiff?.diff, !diff.isEmpty {
            let parsed = SessionStore.diffSummary(diff)
            return "\(parsed.files) 个文件 · +\(parsed.additions) −\(parsed.deletions)"
        }

        let statusChangeCount = Self.gitStatusChangeCount(store.workspaceGitStatusText)
        if statusChangeCount > 0 {
            return "Git 状态 \(statusChangeCount) 项"
        }

        if !store.pendingChanges.isEmpty {
            return "\(store.pendingChanges.count) 个文件 · +\(store.pendingAdditions) −\(store.pendingDeletions)"
        }

        if store.runtimeCatalogIsRefreshing {
            return "读取中"
        }
        return "无"
    }

    private var branchTitle: String {
        store.selectedProject.branch ?? store.workspaceBranches.first ?? "无分支"
    }

    private var branchStatusText: String {
        if store.workspaceBranchStatusText.isEmpty {
            return "未刷新"
        }
        return store.workspaceBranchStatusText
    }

    private var worktreeText: String {
        if store.workspaceWorktrees.isEmpty {
            return "未检测到"
        }
        return "\(store.workspaceWorktrees.count) 个"
    }

    private var loadedThreadText: String {
        if store.runtimeLoadedThreadsStatusText != "未读取" {
            return store.runtimeLoadedThreadsStatusText
        }
        if store.loadedRuntimeThreadIDs.isEmpty {
            return "未读取"
        }
        return "\(store.loadedRuntimeThreadIDs.count) 个"
    }

    private var pullRequestStatusText: String {
        store.workspacePullRequestStatusText
    }

    private var commitPushText: String {
        changesText == "无" ? "无待提交变更" : "先预检，再手动确认提交/推送"
    }

    private var progressSteps: [ProgressStep] {
        if !store.selectedThread.progressSteps.isEmpty {
            return store.selectedThread.progressSteps
        }
        if store.isRunning {
            return [
                ProgressStep(title: "app-server 正在运行当前 turn", state: .running),
                ProgressStep(title: "等待 turn/plan/updated 返回 Codex 计划", state: .pending),
                ProgressStep(title: "完成后刷新 Git 与环境状态", state: .pending)
            ]
        }
        if store.runtimeCatalogIsRefreshing {
            return [
                ProgressStep(title: "正在通过 app-server 读取环境状态", state: .running),
                ProgressStep(title: "同步 Git 分支、差异和工作树", state: .pending)
            ]
        }
        return [
            ProgressStep(title: "app-server 连接就绪", state: .done),
            ProgressStep(title: "Git 环境状态已同步到面板", state: store.workspaceGitDiff != nil || !store.workspaceGitStatusText.isEmpty ? .done : .pending),
            ProgressStep(title: "开始运行后显示 Codex 计划更新", state: .pending)
        ]
    }

    private static func gitStatusChangeCount(_ status: String) -> Int {
        status
            .split(separator: "\n", omittingEmptySubsequences: true)
            .filter { !$0.hasPrefix("##") }
            .count
    }
}

private struct ActiveGoalDetailCard: View {
    let goal: ActiveGoal
    let now: Date
    let runtimeStatus: String
    let refresh: () -> Void
    let edit: () -> Void
    let togglePause: () -> Void
    let clear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: statusSymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(statusTint)
                    .frame(width: 18, height: 18)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(statusName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(goal.runtimeBacked ? "thread/goal/get" : "本地状态")
                            .font(Theme.mono(9.5, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                    Text(goal.title)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                GoalDetailRow(label: "Token", value: tokenText)
                GoalDetailRow(label: "预算", value: budgetText)
                GoalDetailRow(label: "耗时", value: elapsedText)
                GoalDetailRow(label: "最近状态", value: runtimeStatus.isEmpty ? "未刷新" : runtimeStatus)
            }

            HStack(spacing: 8) {
                Button("刷新") {
                    refresh()
                }
                .buttonStyle(ChipButtonStyle())
                Button("编辑") {
                    edit()
                }
                .buttonStyle(ChipButtonStyle())
                Button(goal.status == .paused ? "继续" : "暂停") {
                    togglePause()
                }
                .buttonStyle(ChipButtonStyle())
                Button("清除") {
                    clear()
                }
                .buttonStyle(ChipButtonStyle(tint: Theme.danger))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fillSubtle)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .help("来自 Codex app-server thread/goal/get 的当前目标详情")
    }

    private var statusSymbol: String {
        switch goal.status {
        case .active:
            return "arrow.triangle.2.circlepath"
        case .paused:
            return "pause.circle.fill"
        case .complete:
            return "checkmark.circle.fill"
        case .blocked, .usageLimited, .budgetLimited:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusTint: Color {
        switch goal.status {
        case .active:
            return Theme.info
        case .paused:
            return Theme.warning
        case .complete:
            return Theme.success
        case .blocked, .usageLimited, .budgetLimited:
            return Theme.danger
        }
    }

    private var statusName: String {
        switch goal.status {
        case .active:
            return "进行中"
        case .paused:
            return "已暂停"
        case .blocked:
            return "已阻塞"
        case .usageLimited:
            return "用量受限"
        case .budgetLimited:
            return "预算受限"
        case .complete:
            return "已完成"
        }
    }

    private var tokenText: String {
        SessionStore.compactNumber(goal.tokensUsed)
    }

    private var budgetText: String {
        goal.tokenBudget.map(SessionStore.compactNumber) ?? "未设置"
    }

    private var elapsedText: String {
        let seconds = goal.status == .active
            ? max(0, Int(now.timeIntervalSince(goal.startedAt)))
            : max(0, goal.timeUsedSeconds)
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        let secs = seconds % 60
        return "\(days)d \(hours)h \(minutes)m \(secs)s"
    }
}

private struct GoalDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}

private struct GuardianDeniedActionRow: View {
    let denial: GuardianDeniedAction
    let approve: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.warning)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(denial.summary)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                    Text(detailText)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Text(denial.turnID.isEmpty ? denial.reviewID : denial.turnID)
                    .font(Theme.mono(10.5, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                Button("批准一次") {
                    approve()
                }
                .buttonStyle(ChipButtonStyle(prominent: true))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fillSubtle)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .help("把这次被自动审批拒绝的操作发回 Codex 批准一次")
    }

    private var detailText: String {
        var parts: [String] = []
        if let riskLevel = denial.riskLevel, !riskLevel.isEmpty {
            parts.append("风险 \(riskName(riskLevel))")
        }
        if let rationale = denial.rationale?.trimmingCharacters(in: .whitespacesAndNewlines), !rationale.isEmpty {
            parts.append(rationale)
        }
        return parts.isEmpty ? "Codex 自动审批审查已拒绝此操作，可手动批准一次继续。" : parts.joined(separator: " · ")
    }

    private func riskName(_ risk: String) -> String {
        switch risk {
        case "low": "低"
        case "medium": "中"
        case "high": "高"
        case "critical": "严重"
        default: risk
        }
    }
}

private struct EnvironmentInfoRow: View {
    let symbol: String
    let title: String
    let trailing: String?
    var secondary = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(secondary ? Theme.textTertiary : Theme.textSecondary)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(secondary ? Theme.textTertiary : Theme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(Theme.fillHover.opacity(secondary ? 0 : 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
    }
}

private struct EnvironmentInfoActionRow<Actions: View>: View {
    let symbol: String
    let title: String
    let detail: String?
    var secondary = false
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(secondary ? Theme.textTertiary : Theme.textSecondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(secondary ? Theme.textTertiary : Theme.textPrimary)
                    .lineLimit(1)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                actions()
            }
            .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(minHeight: 42)
        .background(Theme.fillHover.opacity(secondary ? 0 : 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
    }
}

private struct SourceFactRow: View {
    let fact: EnvironmentSourceFact

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: fact.symbol)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(fact.active ? Theme.info : Theme.textTertiary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(fact.title)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(fact.active ? Theme.textPrimary : Theme.textTertiary)
                        .lineLimit(1)
                    Text(fact.source)
                        .font(Theme.mono(9.5, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Text(fact.detail)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fact.active ? Theme.fillStrong : Theme.fill)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .help(fact.active ? "\(fact.title)：\(fact.detail)" : "\(fact.title) 暂无当前数据")
    }
}

private struct ProgressStepRow: View {
    let step: ProgressStep

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            statusIcon
                .frame(width: 16, height: 16)
                .padding(.top, 1)
            Text(step.title)
                .font(.system(size: 13))
                .foregroundStyle(step.state == .pending ? Theme.textSecondary : Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch step.state {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.success)
        case .running:
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.62)
        case .pending:
            Image(systemName: "circle")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}
