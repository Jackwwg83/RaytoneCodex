import SwiftUI

/// The right-hand tools panel: a launcher grid (文件 / 侧边聊天 / 浏览器 / 终端)
/// and a 推荐 file list — matching the Codex desktop side panel.
struct InspectorView: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        switch store.toolPanel {
        case .browser:
            BrowserPanelView(store: store, showInspector: $showInspector)
        case .files:
            FilesToolPanel(store: store, showInspector: $showInspector)
        case .terminal:
            TerminalToolPanel(store: store, showInspector: $showInspector)
        case .sideChat:
            SideChatToolPanel(store: store, showInspector: $showInspector)
        case .launcher:
            if store.selectedThread.items.isEmpty {
                launcher
            } else {
                EnvironmentInfoPanel(store: store, showInspector: $showInspector)
            }
        }
    }

    private var launcher: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ToolCard(icon: "folder", title: "文件", subtitle: "浏览项目文件", shortcut: "⌘P") {
                            store.openToolPanel(.files)
                        }
                        ToolCard(icon: "plus.bubble", title: "侧边聊天", subtitle: "发起侧边对话", shortcut: nil) {
                            store.openToolPanel(.sideChat)
                        }
                        ToolCard(icon: "globe", title: "浏览器", subtitle: "打开网站", shortcut: "⌘T") {
                            store.openToolPanel(.browser)
                        }
                        ToolCard(icon: "terminal", title: "终端", subtitle: "启动交互式 shell", shortcut: "⌃`") {
                            store.openToolPanel(.terminal)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "推荐")
                        ForEach(recommendedFiles, id: \.self) { path in
                            RecommendedRow(path: path) {
                                store.openRecommendedFile(path)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .frame(width: Theme.Layout.inspectorWidth)
        .frame(maxHeight: .infinity)
        .background(Theme.panel)
        .overlay(alignment: .leading) { Hairline(axis: .vertical) }
        .task(id: store.workspacePath) {
            if store.filePanelPath != store.workspacePath || store.fileEntries.isEmpty {
                await store.loadFilePanelDirectory(store.workspacePath)
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                store.chooseFilesForPrompt()
            } label: {
                Image(systemName: "plus").font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(GhostIconButtonStyle())
            .help("添加文件")

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.18)) { showInspector = false }
            } label: {
                Image(systemName: "sidebar.trailing").font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(GhostIconButtonStyle())
            .help("关闭面板")
        }
        .padding(.horizontal, 12)
        .frame(height: Theme.Layout.headerHeight)
        .background(.bar)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private var recommendedFiles: [String] {
        store.inspectorRecommendedFiles
    }
}

private struct ToolCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let shortcut: String?
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.primary)
                    .frame(height: 24)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if let shortcut {
                    Text(shortcut)
                        .font(Theme.mono(10))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .background(hovering ? Theme.fillStrong : Theme.fill)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct FilesToolPanel: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool
    @State private var didRequestInitialLoad = false

    var body: some View {
        VStack(spacing: 0) {
            toolHeader(title: "文件", leadingSymbol: "folder") {
                Button {
                    store.toolPanel = .launcher
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("返回工具")
            } trailing: {
                fileActionsMenu
                Button {
                    Task { await store.loadFilePanelDirectory() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("刷新")
                Button {
                    store.openSelectedFileInDefaultTarget()
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("在 \(store.desktopOpenTarget) 中打开")
                closeButton
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Button {
                        Task { await store.openParentDirectoryInFilePanel() }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(GhostIconButtonStyle(size: 26))
                    .help("上一级")

                    Text(Project.abbreviate(store.filePanelPath.isEmpty ? store.workspacePath : store.filePanelPath))
                        .font(Theme.mono(11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 0)
                }
                Text(store.filePanelStatusText)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textTertiary)

                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                    TextField("搜索文件", text: $store.fileSearchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .onSubmit {
                            Task { await store.searchWorkspaceFiles() }
                        }
                    if store.fileSearchIsRunning {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.55)
                            .frame(width: 16, height: 16)
                    }
                    if !store.fileSearchQuery.isEmpty {
                        Button {
                            store.clearFileSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.textTertiary)
                        .help("清空搜索")
                    }
                }
                .padding(.horizontal, 9)
                .frame(height: 28)
                .background(Theme.fill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

                if !store.fileSearchStatusText.isEmpty {
                    Text(store.fileSearchStatusText)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(12)
            .background(Theme.panel)
            .overlay(alignment: .bottom) { Hairline() }

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if isShowingSearch {
                        ForEach(store.fileSearchResults) { entry in
                            Button {
                                Task { await store.openFileEntry(entry) }
                            } label: {
                                fileRow(entry, subtitle: Project.abbreviate(entry.path))
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        ForEach(store.fileEntries) { entry in
                            Button {
                                Task { await store.openFileEntry(entry) }
                            } label: {
                                fileRow(entry, subtitle: entry.subtitle)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let preview = store.filePreview {
                        Divider()
                            .padding(.vertical, 8)
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 12, weight: .medium))
                            Text(preview.fileName)
                                .font(.system(size: 12.5, weight: .semibold))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Button {
                                Task { await store.addPreviewedFileReferenceToPrompt() }
                            } label: {
                                Label("引用", systemImage: "text.badge.plus")
                                    .font(.system(size: 11.5, weight: .medium))
                            }
                            .buttonStyle(ChipButtonStyle())
                            .help("把当前文件加入下次对话")
                            if preview.isTruncated {
                                Text("已截断")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(Theme.warning)
                            }
                        }
                        .foregroundStyle(Theme.textSecondary)

                        Text(preview.metadataSummary)
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)

                        ScrollView([.horizontal, .vertical]) {
                            Text(preview.text)
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.textPrimary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .frame(minHeight: 180, maxHeight: 280)
                        .background(Theme.fillSubtle)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                                .stroke(Theme.borderSoft, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                    }
                }
                .padding(12)
            }
        }
        .task {
            guard !didRequestInitialLoad else { return }
            didRequestInitialLoad = true
            if store.fileEntries.isEmpty {
                await store.loadFilePanelDirectory()
            }
        }
        .frame(width: Theme.Layout.inspectorWidth)
        .frame(maxHeight: .infinity)
        .background(Theme.panel)
        .overlay(alignment: .leading) { Hairline(axis: .vertical) }
    }

    private var fileActionsMenu: some View {
        Menu {
            Button {
                Task { await store.createFileInCurrentPanelDirectory() }
            } label: {
                Label("新建文件", systemImage: "doc.badge.plus")
            }

            Button {
                Task { await store.createDirectoryInCurrentPanelDirectory() }
            } label: {
                Label("新建文件夹", systemImage: "folder.badge.plus")
            }

            Divider()

            Button {
                Task { await store.duplicatePreviewedFileSystemItem() }
            } label: {
                Label("复制当前预览", systemImage: "doc.on.doc")
            }
            .disabled(store.filePreview == nil)

            Button(role: .destructive) {
                Task { await store.removePreviewedFileSystemItem() }
            } label: {
                Label("删除当前预览", systemImage: "trash")
            }
            .disabled(store.filePreview == nil)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 13, weight: .medium))
        }
        .buttonStyle(GhostIconButtonStyle())
        .help("文件操作")
    }

    private var isShowingSearch: Bool {
        !store.fileSearchStatusText.isEmpty || !store.fileSearchResults.isEmpty
    }

    private func fileRow(_ entry: WorkspaceFileEntry, subtitle: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: entry.symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(entry.isDirectory ? Theme.info : Theme.textSecondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.name)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    private var closeButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { showInspector = false }
        } label: {
            Image(systemName: "sidebar.trailing")
                .font(.system(size: 14, weight: .medium))
        }
        .buttonStyle(GhostIconButtonStyle())
        .help("关闭面板")
    }
}

private struct TerminalToolPanel: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool

    var body: some View {
        VStack(spacing: 0) {
            toolHeader(title: "终端", leadingSymbol: "terminal") {
                Button {
                    store.toolPanel = .launcher
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("返回工具")
            } trailing: {
                Button {
                    Task { await store.cleanThreadBackgroundTerminals() }
                } label: {
                    Image(systemName: "eraser")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("清理 Codex 后台终端")
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showInspector = false }
                } label: {
                    Image(systemName: "sidebar.trailing")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("关闭面板")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(Project.abbreviate(store.workspacePath))
                    .font(Theme.mono(11.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    TextField(store.terminalIsRunning ? "发送 stdin" : "输入 shell 命令", text: $store.terminalCommand)
                        .textFieldStyle(.plain)
                        .font(Theme.mono(12))
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(Theme.fill)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                        .onSubmit {
                            Task { await store.runTerminalCommand() }
                        }
                    Button {
                        Task {
                            if store.terminalIsRunning {
                                await store.stopTerminalCommand()
                            } else {
                                await store.runTerminalCommand()
                            }
                        }
                    } label: {
                        Image(systemName: store.terminalIsRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(GhostIconButtonStyle(size: 30))
                    .help(store.terminalIsRunning ? "停止" : "运行")
                    Button {
                        Task { await store.runThreadShellCommandFromTerminal() }
                    } label: {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(GhostIconButtonStyle(size: 30))
                    .disabled(store.terminalIsRunning || store.terminalCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("作为当前 Codex 线程 Shell 运行")
                }

                TerminalSizeControls(store: store)
                Text(store.threadShellCommandStatusText)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                Text(store.backgroundTerminalCleanStatusText)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            .padding(12)
            .overlay(alignment: .bottom) { Hairline() }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(store.terminalRuns) { run in
                            TerminalRunView(run: run)
                                .id(run.id)
                        }
                        if store.terminalRuns.isEmpty {
                            VStack(spacing: 9) {
                                Image(systemName: "terminal")
                                    .font(.system(size: 30, weight: .regular))
                                    .foregroundStyle(Theme.textTertiary)
                                Text("等待命令")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 220)
                        }
                    }
                    .padding(12)
                }
                .onChange(of: store.terminalRuns.last?.id) { _, id in
                    if let id {
                        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(id, anchor: .bottom) }
                    }
                }
            }
        }
        .frame(width: Theme.Layout.inspectorWidth)
        .frame(maxHeight: .infinity)
        .background(Theme.panel)
        .overlay(alignment: .leading) { Hairline(axis: .vertical) }
    }
}

struct BottomTerminalToolPanel: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    store.toolPanel = .launcher
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("返回工具")

                Image(systemName: "terminal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text("终端")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(Project.abbreviate(store.workspacePath))
                    .font(Theme.mono(11.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 0)

                Button {
                    Task { @MainActor in
                        await store.saveRuntimeTerminalPosition("右侧")
                    }
                } label: {
                    Image(systemName: "sidebar.trailing")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("移到右侧")

                Button {
                    Task { await store.cleanThreadBackgroundTerminals() }
                } label: {
                    Image(systemName: "eraser")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("清理 Codex 后台终端")

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showInspector = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("关闭终端")
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(.bar)
            .overlay(alignment: .top) { Hairline() }
            .overlay(alignment: .bottom) { Hairline() }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    TextField(store.terminalIsRunning ? "发送 stdin" : "输入 shell 命令", text: $store.terminalCommand)
                        .textFieldStyle(.plain)
                        .font(Theme.mono(12))
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(Theme.fill)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                        .onSubmit {
                            Task { await store.runTerminalCommand() }
                        }
                    Button {
                        Task {
                            if store.terminalIsRunning {
                                await store.stopTerminalCommand()
                            } else {
                                await store.runTerminalCommand()
                            }
                        }
                    } label: {
                        Image(systemName: store.terminalIsRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(GhostIconButtonStyle(size: 30))
                    .help(store.terminalIsRunning ? "停止" : "运行")
                    Button {
                        Task { await store.runThreadShellCommandFromTerminal() }
                    } label: {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(GhostIconButtonStyle(size: 30))
                    .disabled(store.terminalIsRunning || store.terminalCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("作为当前 Codex 线程 Shell 运行")
                }
                TerminalSizeControls(store: store)
                Text(store.threadShellCommandStatusText)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                Text(store.backgroundTerminalCleanStatusText)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) { Hairline() }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(store.terminalRuns) { run in
                            TerminalRunView(run: run)
                                .id(run.id)
                        }
                        if store.terminalRuns.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "terminal")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Theme.textTertiary)
                                Text("等待命令")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 96)
                        }
                    }
                    .padding(12)
                }
                .onChange(of: store.terminalRuns.last?.id) { _, id in
                    if let id {
                        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(id, anchor: .bottom) }
                    }
                }
            }
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
        .background(Theme.panel)
    }
}

private struct TerminalSizeControls: View {
    @ObservedObject var store: SessionStore

    private let presets: [(rows: Int, cols: Int)] = [
        (24, 80),
        (30, 100),
        (40, 120),
        (42, 132)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(presets, id: \.cols) { preset in
                        Button("\(preset.rows)×\(preset.cols)") {
                            Task { await store.resizeTerminal(rows: preset.rows, cols: preset.cols) }
                        }
                    }
                } label: {
                    Label("\(store.terminalRows)×\(store.terminalCols)", systemImage: "rectangle.inset.filled")
                        .font(.system(size: 11.5, weight: .medium))
                }
                .menuStyle(.button)
                .fixedSize()

                Stepper("行 \(store.terminalRows)", value: $store.terminalRows, in: 10...80, step: 1)
                    .font(.system(size: 11.5))
                    .labelsHidden()
                    .help("终端行数")
                Text("\(store.terminalRows)")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 22, alignment: .trailing)

                Stepper("列 \(store.terminalCols)", value: $store.terminalCols, in: 40...240, step: 5)
                    .font(.system(size: 11.5))
                    .labelsHidden()
                    .help("终端列数")
                Text("\(store.terminalCols)")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 30, alignment: .trailing)

                Spacer(minLength: 0)

                Button {
                    Task { await store.resizeTerminal() }
                } label: {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                        .font(.system(size: 11.5, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle(size: 26))
                .help(store.terminalIsRunning ? "应用到当前终端" : "保存为下次运行尺寸")
            }

            Text(store.terminalResizeStatusText)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
        }
    }
}

private struct TerminalRunView: View {
    let run: TerminalCommandRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                statusIcon
                Text(run.command)
                    .font(Theme.mono(11.5, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                if let exitCode = run.exitCode {
                    Text("退出 \(exitCode)")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(exitCode == 0 ? Theme.success : Theme.danger)
                }
            }
            if !run.output.isEmpty {
                Text(run.output)
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.textSecondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fillSubtle)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch run.status {
        case .running:
            ProgressView().controlSize(.small).scaleEffect(0.62).frame(width: 14, height: 14)
        case .succeeded:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.success)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Theme.danger)
        }
    }
}

private struct SideChatToolPanel: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool

    var body: some View {
        VStack(spacing: 0) {
            toolHeader(title: "侧边聊天", leadingSymbol: "plus.bubble") {
                Button {
                    store.toolPanel = .launcher
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("返回工具")
            } trailing: {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showInspector = false }
                } label: {
                    Image(systemName: "sidebar.trailing")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("关闭面板")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(store.selectedThread.title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recentTranscript) { item in
                            sideChatTranscriptRow(item)
                        }
                        if recentTranscript.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.bubble")
                                    .font(.system(size: 28, weight: .regular))
                                    .foregroundStyle(Theme.textTertiary)
                                Text("从这里给 Codex 补充上下文")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 140)
                        }
                    }
                    .padding(10)
                }
                .frame(minHeight: 180)
                .background(Theme.fillSubtle)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

                TextEditor(text: $store.sideChatDraft)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 96)
                    .padding(8)
                    .background(Theme.fill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

                Text(store.sideChatStatusText)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(2)

                HStack {
                    Spacer(minLength: 0)
                    Button {
                        Task { await store.injectSideChatContext() }
                    } label: {
                        Label("注入上下文", systemImage: "text.badge.plus")
                    }
                    .buttonStyle(ChipButtonStyle())
                    .disabled(store.isRunning || store.sideChatDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button {
                        Task { await store.sendSideChatMessage() }
                    } label: {
                        Label(store.isRunning ? "继续发送" : "发送", systemImage: "arrow.up")
                    }
                    .buttonStyle(ChipButtonStyle(tint: Theme.textPrimary, prominent: true))
                    .disabled(store.sideChatDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(14)

            Spacer(minLength: 0)
        }
        .frame(width: Theme.Layout.inspectorWidth)
        .frame(maxHeight: .infinity)
        .background(Theme.panel)
        .overlay(alignment: .leading) { Hairline(axis: .vertical) }
    }

    private var recentTranscript: [TranscriptItem] {
        Array(store.selectedThread.items.suffix(8))
    }

    @ViewBuilder
    private func sideChatTranscriptRow(_ item: TranscriptItem) -> some View {
        switch item.kind {
        case let .userMessage(text):
            sideChatBubble(title: "你", text: text, symbol: "person", accent: Theme.info)
        case let .agentMessage(text):
            sideChatBubble(title: "Codex", text: text, symbol: "sparkles", accent: Theme.success)
        case let .command(run):
            sideChatBubble(title: "命令", text: run.command, symbol: "terminal", accent: Theme.textSecondary)
        case let .notice(notice):
            sideChatBubble(title: "提示", text: notice.text, symbol: "exclamationmark.circle", accent: Theme.warning)
        case let .approval(request):
            sideChatBubble(title: "审批", text: request.title, symbol: "checkmark.shield", accent: Theme.warning)
        case let .mcpElicitation(request):
            sideChatBubble(title: "MCP 输入", text: request.message, symbol: "puzzlepiece.extension", accent: Theme.info)
        case let .toolUserInput(request):
            sideChatBubble(
                title: "工具输入",
                text: request.questions.first?.question ?? "请求补充信息",
                symbol: "questionmark.bubble",
                accent: Theme.info
            )
        case let .reasoning(block):
            sideChatBubble(title: block.title, text: block.detail, symbol: "brain", accent: Theme.textSecondary)
        case let .fileChange(change):
            sideChatBubble(title: "文件", text: change.fileName, symbol: "doc.text", accent: Theme.info)
        }
    }

    private func sideChatBubble(title: String, text: String, symbol: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 16, height: 16)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                Text(text)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(4)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(Theme.fill)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }
}

private func toolHeader<Leading: View, Trailing: View>(
    title: String,
    leadingSymbol: String,
    @ViewBuilder leading: () -> Leading,
    @ViewBuilder trailing: () -> Trailing
) -> some View {
    HStack(spacing: 8) {
        leading()
        Image(systemName: leadingSymbol)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
        Spacer(minLength: 0)
        trailing()
    }
    .padding(.horizontal, 12)
    .frame(height: Theme.Layout.headerHeight)
    .background(.bar)
    .overlay(alignment: .bottom) { Hairline() }
}

private struct ToolPlaceholderPanel: View {
    let title: String
    let symbol: String
    let message: String
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    store.toolPanel = .launcher
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("返回工具")

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showInspector = false }
                } label: {
                    Image(systemName: "sidebar.trailing")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(GhostIconButtonStyle())
                .help("关闭面板")
            }
            .padding(.horizontal, 12)
            .frame(height: Theme.Layout.headerHeight)
            .background(.bar)
            .overlay(alignment: .bottom) { Hairline() }

            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(Theme.textTertiary)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: Theme.Layout.inspectorWidth)
        .frame(maxHeight: .infinity)
        .background(Theme.panel)
        .overlay(alignment: .leading) { Hairline(axis: .vertical) }
    }
}

private struct RecommendedRow: View {
    let path: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: "doc.text")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text((path as NSString).lastPathComponent)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Text("文档")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(hovering ? Theme.fill : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
