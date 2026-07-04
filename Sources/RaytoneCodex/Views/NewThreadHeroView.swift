import RaytoneCodexCore
import SwiftUI

struct NewThreadHeroView: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool

    var body: some View {
        VStack(spacing: 0) {
            topControls
            Spacer(minLength: 32)
            VStack(spacing: 18) {
                Text("我们应该在 \(store.selectedProject.name) 中构建什么？")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                heroComposer
                pillRow
                connectionCards
            }
            .frame(maxWidth: 720)
            .padding(.horizontal, 28)
            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity, minHeight: 620)
        .background(Theme.transcript)
        .task {
            await store.refreshWorkspaceBranches()
            if store.fileEntries.isEmpty {
                await store.loadFilePanelDirectory(store.workspacePath)
            }
            if store.runtimeMCPServers.isEmpty {
                await store.refreshRuntimeMCPServers()
            }
        }
    }

    private var topControls: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            modelMenu
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
        .padding(.top, 12)
    }

    private var heroComposer: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $store.prompt)
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 98, maxHeight: 150)
                    .padding(.horizontal, 18)
                    .padding(.top, 15)
                    .padding(.bottom, store.desktopShowBottomPanel ? 0 : 42)

                if store.prompt.isEmpty {
                    Text("随心输入")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !store.desktopShowBottomPanel {
                    sendButton
                        .padding(.trailing, 12)
                        .padding(.bottom, 12)
                }
            }

            if store.desktopShowBottomPanel {
                HStack(spacing: 8) {
                    plusMenu
                    AccessModeControl(store: store)
                    Spacer(minLength: 8)
                    modelMenu
                    micButton
                    sendButton
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Theme.transcript)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.composer, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.composer, style: .continuous))
        .shadow(color: Theme.border.opacity(0.35), radius: 18, x: 0, y: 10)
        .overlay(alignment: .bottomLeading) {
            if store.desktopShowBottomPanel && store.accessModePopoverPresented {
                AccessModePopover(store: store)
                    .offset(x: 42, y: -36)
                    .zIndex(20)
            }
        }
    }

    private var plusMenu: some View {
        Menu {
            Button {
                store.chooseFilesForPrompt()
            } label: { Label("添加文件…", systemImage: "paperclip") }
            Button {
                store.chooseImagesForPrompt()
            } label: { Label("添加图片…", systemImage: "photo") }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 30, height: 30)
                .background(Theme.fill)
                .clipShape(Circle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var modelMenu: some View {
        Menu {
            ForEach(store.providers) { provider in
                Menu(provider.displayName) {
                    ForEach(provider.models, id: \.self) { model in
                        Button {
                            store.chooseProviderModel(providerID: provider.id, model: model)
                        } label: {
                            Label(
                                store.modelMenuTitle(providerID: provider.id, model: model),
                                systemImage: provider.id == store.selectedProviderID && model == store.selectedProvider.model ? "checkmark" : "circle"
                            )
                        }
                    }
                }
            }
            Divider()
            Button {
                Task { await store.refreshModelCatalog() }
            } label: {
                Label("刷新 Codex 模型列表", systemImage: "arrow.clockwise")
            }
        } label: {
            HStack(spacing: 5) {
                Text(heroModelName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Theme.fill)
            .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var micButton: some View {
        Button {
            Task { await store.startVoiceInput() }
        } label: {
            Image(systemName: "mic")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .help(store.voiceInputStatusText)
    }

    private var sendButton: some View {
        Button {
            if store.isRunning {
                Task { await store.interruptRunningTurn() }
            } else {
                Task { await store.runPrompt() }
            }
        } label: {
            Image(systemName: store.isRunning ? "stop.fill" : "arrow.up")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.transcript)
                .frame(width: 30, height: 30)
                .background(sendEnabled ? Theme.textPrimary : Theme.textPrimary.opacity(0.3))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!store.isRunning && !sendEnabled)
        .help(store.isRunning ? "停止" : "发送 (⌘↩)")
    }

    private var pillRow: some View {
        HStack(spacing: 8) {
            pillMenu(symbol: "folder", title: store.selectedProject.name) {
                ForEach(store.projects) { project in
                    Button {
                        store.selectProjectForNewThread(project.id)
                    } label: {
                        Label(project.name, systemImage: project.id == store.selectedProject.id ? "checkmark" : "folder")
                    }
                }
            }
            pillMenu(symbol: "desktopcomputer", title: store.workspaceExecutionMode.title) {
                Button {
                    store.chooseWorkspaceExecutionMode(.local)
                } label: {
                    Label("本地模式", systemImage: store.workspaceExecutionMode == .local ? "checkmark" : "desktopcomputer")
                }
                Button {
                    store.chooseWorkspaceExecutionMode(.cloudPending)
                } label: {
                    Label("云端模式", systemImage: store.workspaceExecutionMode == .cloudPending ? "checkmark" : "cloud")
                }
            }
            pillMenu(symbol: "arrow.triangle.branch", title: branchTitle) {
                if store.workspaceBranches.isEmpty {
                    Text(store.workspaceBranchStatusText)
                } else {
                    ForEach(store.workspaceBranches, id: \.self) { branch in
                        Button {
                            Task { await store.checkoutWorkspaceBranch(branch) }
                        } label: {
                            Label(branch, systemImage: branch == store.selectedProject.branch ? "checkmark" : "circle")
                        }
                    }
                }
                Divider()
                Button {
                    Task { await store.refreshWorkspaceBranches() }
                } label: {
                    Label("刷新分支", systemImage: "arrow.clockwise")
                }
                Button {
                    store.promptCreateWorkspaceBranch()
                } label: {
                    Label("新建分支…", systemImage: "plus")
                }
            }
        }
    }

    private func pillMenu<Content: View>(
        symbol: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu(content: content) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(Theme.fill)
            .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var connectionCards: some View {
        HStack(spacing: 12) {
            ConnectionCard(
                symbol: "message",
                title: "连接消息传送",
                subtitle: store.messagingConnectionSubtitle,
                connected: store.messagingConnectionCount > 0
            ) {
                store.openConnectionsSettings()
            }
            ConnectionCard(
                symbol: "envelope",
                title: "连接电子邮件",
                subtitle: store.emailConnectionSubtitle,
                connected: store.emailConnectionCount > 0
            ) {
                store.openConnectionsSettings()
            }
            ConnectionCard(
                symbol: "folder",
                title: "连接文件",
                subtitle: store.workspaceFileConnectionSubtitle,
                connected: store.workspaceFileConnectionCount > 0
            ) {
                store.connectWorkspaceFiles()
            }
        }
    }

    private var heroModelName: String {
        store.modelDisplayName
    }

    private var branchTitle: String {
        store.selectedProject.branch ?? store.workspaceBranches.first ?? "无分支"
    }

    private var sendEnabled: Bool {
        store.isRunning || !store.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct ConnectionCard: View {
    let symbol: String
    let title: String
    let subtitle: String
    let connected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 30, height: 30)
                        .background(Theme.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Spacer(minLength: 0)
                    if connected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.success)
                    } else {
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .background(Theme.transcript)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(Theme.borderSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
