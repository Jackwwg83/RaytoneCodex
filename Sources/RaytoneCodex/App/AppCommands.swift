import AppKit
import SwiftUI

/// The native macOS menu bar for RaytoneX. Standard 编辑 / 窗口 menus are
/// provided by the system; this adds About, 文件 items, 视图, and the custom
/// 对话 / 工具 / 帮助 menus, all wired to the session store.
struct AppCommands: Commands {
    @ObservedObject var store: SessionStore

    var body: some Commands {
        // App menu → About
        CommandGroup(replacing: .appInfo) {
            Button("关于 RaytoneX") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }
        }

        CommandGroup(replacing: .appSettings) {
            Button("设置…") {
                store.route = .settings
                store.settingsPane = .general
            }
            .keyboardShortcut(",", modifiers: [.command])
        }

        // 文件
        CommandGroup(replacing: .newItem) {
            Button("新建对话") {
                store.resetThread()
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("在当前项目新建对话") {
                store.newThread(in: store.selectedProject.id)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Divider()

            Button("打开工作区…") {
                store.chooseWorkspace()
            }
            .keyboardShortcut("o", modifiers: [.command])
        }

        // 视图
        CommandGroup(after: .sidebar) {
            Button(store.showInspector ? "隐藏工具面板" : "显示工具面板") {
                store.showInspector.toggle()
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
        }

        // 对话
        CommandMenu("对话") {
            Button(store.isRunning ? "停止" : "运行") {
                if store.isRunning {
                    Task { await store.interruptRunningTurn() }
                } else {
                    Task { await store.runPrompt() }
                }
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(!store.isRunning && store.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("刷新运行时") {
                Task { await store.refreshRuntime() }
            }
            .keyboardShortcut("r", modifiers: [.command])

            Divider()

            Button("删除当前对话") {
                store.deleteThread(store.selectedThreadID)
            }
            .keyboardShortcut(.delete, modifiers: [.command])
            .disabled(store.threads.count <= 1)
        }

        // 工具
        CommandMenu("工具") {
            Button("文件") { store.openToolPanel(.files) }
                .keyboardShortcut("p", modifiers: [.command])
            Button("浏览器") { store.openToolPanel(.browser) }
                .keyboardShortcut("t", modifiers: [.command])
            Button("终端") { store.openToolPanel(.terminal) }
                .keyboardShortcut("`", modifiers: [.control])
            Button("侧边聊天") { store.openToolPanel(.sideChat) }
        }

        // 帮助
        CommandGroup(replacing: .help) {
            Button("运行时诊断") {
                Task { await store.diagnoseWorkspaceRuntime() }
            }

            Divider()

            Button("RaytoneX 帮助") {
                if let url = URL(string: "https://github.com/openai/codex") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
