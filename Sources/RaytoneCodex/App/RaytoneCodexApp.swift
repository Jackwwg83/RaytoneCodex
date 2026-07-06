import SwiftUI

@main
struct RaytoneCodexApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var sessionStore = SessionStore()

    init() {
        SmokeTestRunner.runIfRequested()
    }

    var body: some Scene {
        WindowGroup("Raytone Codex", id: "main") {
            ContentView(store: sessionStore)
                .frame(minWidth: 1220, minHeight: 760)
                .preferredColorScheme(sessionStore.preferredColorScheme)
                .task {
                    await sessionStore.refreshRuntime()
                    sessionStore.applyStartupScreenIfNeeded()
                    if SessionStore.startupScreenUsesNewThreadHero {
                        await sessionStore.refreshNewThreadHeroRuntime()
                    }
                    await sessionStore.refreshRuntimeThreads()
                    sessionStore.evaluateProviderOnboarding()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)
        .commands {
            AppCommands(store: sessionStore)
        }

        Settings {
            SettingsView(store: sessionStore)
                .frame(minWidth: 1040, minHeight: 760)
                .preferredColorScheme(sessionStore.preferredColorScheme)
        }

        MenuBarExtra(
            "RaytoneCodex",
            systemImage: "sparkles",
            isInserted: Binding(
                get: { sessionStore.desktopShowInMenuBar },
                set: { isVisible in
                    Task { @MainActor in
                        await sessionStore.saveRuntimeShowInMenuBar(isVisible)
                    }
                }
            )
        ) {
            Button("显示 RaytoneCodex") {
                showMainWindow()
            }
            Button("新建对话") {
                sessionStore.resetThread()
                showMainWindow()
            }
            Divider()
            Button("退出 RaytoneCodex") {
                NSApp.terminate(nil)
            }
        }
    }

    private func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows
            .filter { !$0.title.isEmpty }
            .forEach { $0.makeKeyAndOrderFront(nil) }
    }
}
