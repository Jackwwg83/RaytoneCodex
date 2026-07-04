import SwiftUI

/// Dispatches a transcript item to its row view. The transcript is a flowing
/// document — no avatars, no role labels — matching the Codex desktop app.
struct TranscriptItemRow: View {
    @ObservedObject var store: SessionStore
    let item: TranscriptItem

    var body: some View {
        switch item.kind {
        case let .userMessage(text):
            UserMessageView(text: text)
        case let .agentMessage(text):
            MarkdownText(text: text)
                .frame(maxWidth: .infinity, alignment: .leading)
        case let .reasoning(block):
            ReasoningLine(block: block)
        case let .command(run):
            CommandLine(run: run)
        case let .fileChange(change):
            FileChangeLine(change: change)
        case let .approval(request):
            ApprovalCard(store: store, itemID: item.id, request: request)
        case let .notice(notice):
            NoticeLine(notice: notice)
        }
    }
}

// MARK: - User message

private struct UserMessageView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14.5))
            .lineSpacing(4)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Theme.fill)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Reasoning

private struct ReasoningLine: View {
    let block: ReasoningBlock
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)
                    Text(block.title)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Text(block.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 15)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Command execution (subtle one-liner that expands)

private struct CommandLine: View {
    let run: CommandRun
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
            } label: {
                HStack(spacing: 7) {
                    glyph
                    label
                    Spacer(minLength: 0)
                    if run.status == .failed {
                        Text("失败")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(Theme.danger)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded, !run.output.isEmpty {
                outputView
            }
        }
    }

    @ViewBuilder private var glyph: some View {
        if run.status == .running {
            ProgressView().controlSize(.small).scaleEffect(0.66).frame(width: 14, height: 14)
        } else {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: 14)
        }
    }

    @ViewBuilder private var label: some View {
        if run.status == .running {
            Text("正在运行命令")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 5) {
                Text("已运行")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(run.command)
                    .font(Theme.mono(12.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var outputView: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            Text(run.output)
                .font(Theme.mono(11.5))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
        }
        .frame(maxHeight: 200)
        .background(Theme.fillSubtle)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.leading, 21)
    }
}

// MARK: - File change (subtle one-liner that expands to a diff)

private struct FileChangeLine: View {
    let change: FileChange
    @State private var expanded = false

    private var canExpand: Bool { !change.hunks.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                if canExpand { withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() } }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: change.type.symbol)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14)
                    Text(verbatim: actionWord)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(change.path)
                        .font(Theme.mono(12.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 6)
                    if change.additions > 0 {
                        Text("+\(change.additions)")
                            .font(Theme.mono(11, weight: .medium))
                            .foregroundStyle(Theme.diffAddedText)
                    }
                    if change.deletions > 0 {
                        Text("−\(change.deletions)")
                            .font(Theme.mono(11, weight: .medium))
                            .foregroundStyle(Theme.diffRemovedText)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canExpand)

            if expanded, canExpand {
                diffView
            }
        }
    }

    private var actionWord: String {
        switch change.type {
        case .added: "新建"
        case .modified: "编辑"
        case .deleted: "删除"
        case .renamed: "重命名"
        }
    }

    private var diffView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(change.hunks) { hunk in
                    Text(hunk.header)
                        .font(Theme.mono(11))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.fill)
                    ForEach(hunk.lines) { line in
                        DiffLineView(line: line)
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.leading, 21)
    }
}

private struct DiffLineView: View {
    let line: DiffLine

    var body: some View {
        HStack(spacing: 0) {
            Text(number(line.oldLine))
                .frame(width: 32, alignment: .trailing)
                .foregroundStyle(.tertiary)
            Text(number(line.newLine))
                .frame(width: 32, alignment: .trailing)
                .foregroundStyle(.tertiary)
                .padding(.trailing, 8)
            Text(prefix + line.text)
                .foregroundStyle(textColor)
                .frame(minWidth: 360, alignment: .leading)
        }
        .font(Theme.mono(11.5))
        .padding(.vertical, 1.5)
        .background(rowFill)
    }

    private func number(_ value: Int?) -> String { value.map(String.init) ?? "" }

    private var prefix: String {
        switch line.kind {
        case .added: "+ "
        case .removed: "− "
        case .context: "  "
        }
    }

    private var textColor: Color {
        switch line.kind {
        case .added: Theme.diffAddedText
        case .removed: Theme.diffRemovedText
        case .context: .primary
        }
    }

    private var rowFill: Color {
        switch line.kind {
        case .added: Theme.diffAddedFill
        case .removed: Theme.diffRemovedFill
        case .context: .clear
        }
    }
}

// MARK: - Approval

private struct ApprovalCard: View {
    @ObservedObject var store: SessionStore
    let itemID: UUID
    let request: ApprovalRequest

    var body: some View {
        if request.kind == .command {
            CommandApprovalCard(store: store, itemID: itemID, request: request)
        } else {
            legacyApprovalCard
        }
    }

    private var legacyApprovalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: request.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.warning)
                Text(request.title)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(request.detail)
                .font(Theme.mono(11.5))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            switch request.decision {
            case .pending:
                HStack(spacing: 8) {
                    Button { store.decideApproval(itemID: itemID, decision: .approved) } label: {
                        Label("批准", systemImage: "checkmark")
                    }
                    .buttonStyle(ChipButtonStyle(tint: Theme.success, prominent: true))
                    Button { store.decideApproval(itemID: itemID, decision: .denied(note: nil)) } label: {
                        Label("拒绝", systemImage: "xmark")
                    }
                    .buttonStyle(ChipButtonStyle())
                }
            case .approved:
                resolved("checkmark.circle.fill", "已批准", Theme.success)
            case .approvedAlways:
                resolved("checkmark.shield.fill", "已批准并记住", Theme.success)
            case .denied:
                resolved("xmark.circle.fill", "已拒绝", Theme.danger)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.warning.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.warning.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private func resolved(_ symbol: String, _ text: String, _ tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(tint)
    }
}

private enum CommandApprovalChoice {
    case yes
    case always
    case no
}

private struct CommandApprovalCard: View {
    @ObservedObject var store: SessionStore
    let itemID: UUID
    let request: ApprovalRequest

    @State private var selected: CommandApprovalChoice = .yes

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let rationale = request.rationale, !rationale.isEmpty {
                Text(rationale)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            Text(commandText)
                .font(Theme.mono(12))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
                .lineLimit(3)
                .truncationMode(.middle)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.fill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

            switch request.decision {
            case .pending:
                VStack(spacing: 6) {
                    choiceRow(.yes) {
                        Text("是")
                            .font(.system(size: 13, weight: .medium))
                    }
                    choiceRow(.always) {
                        HStack(spacing: 4) {
                            Text("是，且对于以")
                            Text(commandPrefix)
                                .font(Theme.mono(11.5, weight: .medium))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Theme.fillStrong)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            Text("开头的命令不再询问")
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    choiceRow(.no) {
                        Text("否，请告知 Codex 如何调整")
                            .font(.system(size: 13, weight: .medium))
                    } accessory: {
                        HStack(spacing: 7) {
                            Button("跳过") {
                                store.decideApproval(itemID: itemID, decision: .denied(note: nil))
                            }
                            .buttonStyle(ChipButtonStyle())
                            Button("提交 ↵") {
                                submitSelection()
                            }
                            .buttonStyle(ChipButtonStyle(tint: Theme.textPrimary, prominent: true))
                        }
                    }
                }
            case .approved:
                resolved("checkmark.circle.fill", "已批准", Theme.success)
            case .approvedAlways:
                resolved("checkmark.shield.fill", "已批准并记住此前缀", Theme.success)
            case .denied:
                resolved("xmark.circle.fill", "已拒绝", Theme.danger)
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

    private func choiceRow<Label: View, Accessory: View>(
        _ choice: CommandApprovalChoice,
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                selected = choice
            }
        } label: {
            HStack(spacing: 8) {
                label()
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: 10)
                if selected == choice {
                    Text("↑↓")
                        .font(Theme.mono(11, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
                accessory()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected == choice ? Theme.fillSelected : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func choiceRow<Label: View>(
        _ choice: CommandApprovalChoice,
        @ViewBuilder label: () -> Label
    ) -> some View {
        choiceRow(choice, label: label) {
            EmptyView()
        }
    }

    private func submitSelection() {
        switch selected {
        case .yes:
            store.decideApproval(itemID: itemID, decision: .approved)
        case .always:
            store.decideApproval(itemID: itemID, decision: .approvedAlways)
        case .no:
            store.decideApproval(itemID: itemID, decision: .denied(note: nil))
        }
    }

    private func resolved(_ symbol: String, _ text: String, _ tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(tint)
    }

    private var commandText: String {
        request.command ?? request.detail
    }

    private var commandPrefix: String {
        request.commandPrefix ?? commandText
    }
}

// MARK: - Notice

private struct NoticeLine: View {
    let notice: Notice

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .padding(.top, 1)
            Text(notice.text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(11)
        .background(tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private var symbol: String {
        switch notice.level {
        case .info: "info.circle"
        case .warning: "exclamationmark.triangle"
        case .error: "xmark.octagon"
        }
    }

    private var tint: Color {
        switch notice.level {
        case .info: Theme.info
        case .warning: Theme.warning
        case .error: Theme.danger
        }
    }
}
