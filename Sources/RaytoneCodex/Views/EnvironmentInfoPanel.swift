import SwiftUI

struct EnvironmentInfoPanel: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    environmentRows
                    progressSection
                    sourcesSection
                }
                .padding(16)
            }
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
        VStack(alignment: .leading, spacing: 4) {
            EnvironmentInfoRow(symbol: "plus.forwardslash.minus", title: "变更", trailing: changesText)
            EnvironmentInfoRow(symbol: "desktopcomputer", title: "本地", trailing: "⌄")
            EnvironmentInfoRow(symbol: "arrow.triangle.branch", title: store.selectedProject.branch ?? "master", trailing: "⌄")
            EnvironmentInfoRow(symbol: "cpu", title: store.modelDisplayName, trailing: nil)
            EnvironmentInfoRow(symbol: "shippingbox", title: "Sidecar", trailing: store.sidecarStatusText)
            EnvironmentInfoRow(symbol: "arrow.up.circle", title: "提交或推送", trailing: nil)
            EnvironmentInfoRow(symbol: "chevron.left.forwardslash.chevron.right", title: "无法获取拉取请求状态", trailing: nil, secondary: true)
        }
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

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "来源")
            HStack(spacing: 8) {
                ForEach(["command", "globe", "folder", "doc.text", "terminal"], id: \.self) { symbol in
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Theme.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var changesText: String {
        if store.pendingChanges.isEmpty {
            return "无"
        }
        return "\(store.pendingChanges.count)"
    }

    private var progressSteps: [ProgressStep] {
        if !store.selectedThread.progressSteps.isEmpty {
            return store.selectedThread.progressSteps
        }
        return [
            ProgressStep(title: "重新校准生产访问、token 和现有审计报告状态", state: .done),
            ProgressStep(title: "验证上传 UI 候选并清理测试数据", state: .running),
            ProgressStep(title: "继续审计 Composer、Inspector、Settings/错误态等高风险工作流", state: .pending),
            ProgressStep(title: "把确认的 P0/P1 与排除项写入报告", state: .pending)
        ]
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
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(Theme.fillHover.opacity(secondary ? 0 : 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
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
