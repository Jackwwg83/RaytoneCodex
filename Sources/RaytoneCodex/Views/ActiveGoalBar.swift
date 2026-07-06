import SwiftUI

struct ActiveGoalBar: View {
    let goal: ActiveGoal
    var onEdit: () -> Void
    var onPause: () -> Void
    var onDelete: () -> Void
    var onExpand: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(statusTint)
                Text(statusTitle)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(goal.title)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let usageText {
                    Text(usageText)
                        .font(Theme.mono(10.5, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(elapsedText(now: timeline.date))
                    .font(Theme.mono(11.5, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                goalButton("pencil", "编辑", action: onEdit)
                goalButton(goal.status == .paused ? "play.fill" : "pause", goal.status == .paused ? "继续" : "暂停", action: onPause)
                goalButton("trash", "删除", action: onDelete)
                goalButton("chevron.right", "展开", action: onExpand)
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Theme.fill)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(Theme.borderSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
    }

    private func goalButton(_ symbol: String, _ help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11.5, weight: .medium))
        }
        .buttonStyle(GhostIconButtonStyle(size: 24))
        .help(help)
    }

    private var statusTitle: String {
        switch goal.status {
        case .active:
            "进行中的目标"
        case .paused:
            "已暂停的目标"
        case .blocked:
            "已阻塞的目标"
        case .usageLimited:
            "用量受限"
        case .budgetLimited:
            "预算受限"
        case .complete:
            "已完成的目标"
        }
    }

    private var statusTint: Color {
        switch goal.status {
        case .active:
            Theme.textSecondary
        case .paused:
            Theme.warning
        case .complete:
            Theme.success
        case .blocked, .usageLimited, .budgetLimited:
            Theme.danger
        }
    }

    private var usageText: String? {
        guard goal.tokensUsed > 0 || goal.tokenBudget != nil else { return nil }
        let used = Self.compactNumber(goal.tokensUsed)
        if let budget = goal.tokenBudget {
            return "\(used)/\(Self.compactNumber(budget))"
        }
        return used
    }

    private func elapsedText(now: Date) -> String {
        let seconds = goal.status == .active
            ? max(0, Int(now.timeIntervalSince(goal.startedAt)))
            : max(0, goal.timeUsedSeconds)
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        let secs = seconds % 60
        return "\(days)d \(hours)h \(minutes)m \(secs)s"
    }

    private static func compactNumber(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }
}
