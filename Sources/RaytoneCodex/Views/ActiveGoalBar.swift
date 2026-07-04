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
                    .foregroundStyle(Theme.textSecondary)
                Text("进行中的目标")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(goal.title)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 8)
                Text(elapsedText(now: timeline.date))
                    .font(Theme.mono(11.5, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                goalButton("pencil", "编辑", action: onEdit)
                goalButton("pause", "暂停", action: onPause)
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

    private func elapsedText(now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(goal.startedAt)))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        let secs = seconds % 60
        return "\(days)d \(hours)h \(minutes)m \(secs)s"
    }
}
