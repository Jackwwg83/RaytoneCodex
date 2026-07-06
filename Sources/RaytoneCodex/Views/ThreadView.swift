import SwiftUI

/// The central column: thread header, optional connection banner, the flowing
/// transcript, the changed-files bar, and the composer.
struct ThreadView: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool

    private let bottomID = "transcript-bottom"

    var body: some View {
        VStack(spacing: 0) {
            ThreadHeader(store: store, showInspector: $showInspector)

            if store.connectionState.showsBanner {
                ConnectionBanner(state: store.connectionState) {
                    Task { await store.recoverConnection(from: store.connectionState) }
                }
            }

            transcript
            if !store.selectedThread.items.isEmpty {
                bottomBar
            }
        }
        .frame(minWidth: 540)
        .background(Theme.transcript)
    }

    // MARK: Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if store.selectedThread.items.isEmpty {
                    NewThreadHeroView(store: store, showInspector: $showInspector)
                        .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(store.selectedThread.items) { item in
                            TranscriptItemRow(store: store, item: item)
                                .id(item.id)
                        }
                        if store.isRunning {
                            ThinkingRow().id("thinking")
                        }
                        Color.clear.frame(height: 4).id(bottomID)
                    }
                    .frame(maxWidth: Theme.Layout.transcriptMaxWidth)
                    .padding(.horizontal, 30)
                    .padding(.top, 24)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .background(Theme.transcript)
            .onChange(of: store.selectedThread.items.last?.id) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(bottomID, anchor: .bottom) }
            }
            .onChange(of: store.selectedThreadID) { _, _ in
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
            .onChange(of: store.isRunning) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(bottomID, anchor: .bottom) }
            }
        }
    }

    // MARK: Bottom bar (changed files + composer)

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if let activeGoal = store.selectedThread.activeGoal {
                ActiveGoalBar(
                    goal: activeGoal,
                    onEdit: { store.promptEditActiveGoal() },
                    onPause: { Task { await store.pauseActiveGoal() } },
                    onDelete: { Task { await store.clearActiveGoal() } },
                    onExpand: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showInspector = true
                            store.toolPanel = .launcher
                        }
                        Task { await store.refreshSelectedRuntimeGoal() }
                    }
                )
            }
            if !store.pendingChanges.isEmpty {
                ChangedFilesBar(store: store)
            }
            ComposerView(store: store)
        }
        .frame(maxWidth: Theme.Layout.transcriptMaxWidth)
        .padding(.horizontal, 30)
        .padding(.top, 6)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(Theme.transcript)
    }
}

// MARK: - Header

private struct ThreadHeader: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(store.selectedThread.title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)

            Menu {
                Button("重命名对话") {
                    store.renameSelectedThread()
                }
                Button("复制对话") {
                    store.duplicateSelectedThread()
                }
                Divider()
                Button("压缩对话历史") {
                    Task { await store.startSelectedThreadCompaction() }
                }
                .disabled(store.isRunning)
                Button("回滚最后一轮", role: .destructive) {
                    Task { await store.rollbackSelectedThreadLastTurn() }
                }
                .disabled(store.isRunning)
                Divider()
                Button("删除对话", role: .destructive) {
                    store.deleteThread(store.selectedThreadID)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()

            Spacer(minLength: 0)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showInspector = false
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(GhostIconButtonStyle())
            .help("展开")

            Button {
                withAnimation(.easeInOut(duration: 0.18)) { showInspector.toggle() }
            } label: {
                Image(systemName: "sidebar.trailing")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(GhostIconButtonStyle())
            .help("工具面板")
        }
        .padding(.horizontal, 18)
        .frame(height: Theme.Layout.headerHeight)
        .background(.bar)
        .overlay(alignment: .bottom) { Hairline() }
    }
}

// MARK: - Thinking indicator

private struct ThinkingRow: View {
    var body: some View {
        HStack(spacing: 7) {
            ProgressView().controlSize(.small).scaleEffect(0.7).frame(width: 14, height: 14)
            Text("正在思考")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Changed files bar

private struct ChangedFilesBar: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.forwardslash.minus")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("\(store.pendingChanges.count) 个文件已更改")
                .font(.system(size: 12.5, weight: .medium))
            if store.pendingAdditions > 0 {
                Text("+\(store.pendingAdditions)")
                    .font(Theme.mono(11.5, weight: .medium))
                    .foregroundStyle(Theme.diffAddedText)
            }
            if store.pendingDeletions > 0 {
                Text("−\(store.pendingDeletions)")
                    .font(Theme.mono(11.5, weight: .medium))
                    .foregroundStyle(Theme.diffRemovedText)
            }
            Spacer(minLength: 0)
            Button {
                Task { await store.runReviewOfCurrentChanges(displayedPrompt: "审查当前变更") }
            } label: {
                Text("审查")
            }
            .buttonStyle(ChipButtonStyle())
            .disabled(store.isRunning)
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
