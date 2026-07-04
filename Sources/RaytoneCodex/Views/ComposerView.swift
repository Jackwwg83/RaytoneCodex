import RaytoneCodexCore
import SwiftUI

/// The Codex-style composer: a rounded input with a "+" menu, an access-mode
/// dropdown (sandbox), a model dropdown, a mic affordance, and a send / stop
/// circular button.
struct ComposerView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        VStack(spacing: 0) {
            inputArea
            if store.desktopShowBottomPanel {
                controlRow
            }
        }
        .background(Theme.transcript)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.composer, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.composer, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
        .overlay(alignment: .bottomLeading) {
            if store.desktopShowBottomPanel && store.accessModePopoverPresented {
                AccessModePopover(store: store)
                    .offset(x: 40, y: -36)
                    .zIndex(20)
            }
        }
    }

    // MARK: Input

    private var inputArea: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $store.prompt)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 46, maxHeight: 150)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, store.desktopShowBottomPanel ? 0 : 38)

            if store.prompt.isEmpty {
                Text(placeholder)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .padding(.horizontal, 19)
                    .padding(.top, 20)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !store.desktopShowBottomPanel {
                sendButton
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
            }
        }
    }

    private var placeholder: String {
        "要求后续变更"
    }

    // MARK: Controls

    private var controlRow: some View {
        HStack(spacing: 8) {
            plusMenu
            AccessModeControl(store: store)
            Spacer(minLength: 6)
            modelMenu
            micButton
            sendButton
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
        .padding(.bottom, 10)
    }

    private var plusMenu: some View {
        Menu {
            Button {
                store.chooseFilesForPrompt()
            } label: { Label("添加文件…", systemImage: "paperclip") }
            Button {
                store.chooseImagesForPrompt()
            } label: { Label("添加图片…", systemImage: "photo") }
            Divider()
            ForEach(SlashCommand.all) { command in
                Button {
                    store.prompt = command.name + " "
                } label: {
                    Label("\(command.name)  \(command.summary)", systemImage: command.symbol)
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(Theme.fill)
                .clipShape(Circle())
                .contentShape(Circle())
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
            if let defaultOpenAIModel {
                Button {
                    store.chooseProviderModel(providerID: "openai", model: defaultOpenAIModel)
                } label: {
                    Label("默认 OpenAI：\(store.modelMenuTitle(providerID: "openai", model: defaultOpenAIModel))", systemImage: "sparkles")
                }
            } else {
                Button {
                    Task { await store.refreshModelCatalog() }
                } label: {
                    Label("读取 OpenAI 模型", systemImage: "arrow.clockwise")
                }
            }
            Button {
                Task { await store.refreshModelCatalog() }
            } label: {
                Label("刷新 Codex 模型列表", systemImage: "arrow.clockwise")
            }
        } label: {
            HStack(spacing: 5) {
                Text(store.modelDisplayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Theme.fill)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var defaultOpenAIModel: String? {
        store.codexModelCatalog.first(where: \.isDefault)?.id ??
            store.providers.first(where: { $0.id == "openai" })?.models.first
    }

    private var micButton: some View {
        Button {
            Task { await store.startVoiceInput() }
        } label: {
            Image(systemName: "mic")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
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
                .foregroundStyle(Color(nsColor: .textBackgroundColor))
                .frame(width: 30, height: 30)
                .background(sendEnabled ? Color.primary : Color.primary.opacity(0.3))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!store.isRunning && trimmedPromptEmpty)
        .help(store.isRunning ? "停止" : "发送 (⌘↩)")
    }

    private var trimmedPromptEmpty: Bool {
        store.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var sendEnabled: Bool {
        store.isRunning || !trimmedPromptEmpty
    }

    // MARK: Sandbox display

    static func sandboxName(_ mode: CodexSandboxMode) -> String {
        switch mode {
        case .readOnly: "只读"
        case .workspaceWrite: "工作区写入"
        case .dangerFullAccess: "完全访问"
        }
    }

    static func sandboxIcon(_ mode: CodexSandboxMode) -> String {
        switch mode {
        case .readOnly: "lock"
        case .workspaceWrite: "square.and.pencil"
        case .dangerFullAccess: "exclamationmark.triangle"
        }
    }
}
