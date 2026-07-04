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
                .task {
                    await sessionStore.refreshRuntime()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)
        .commands {
            AppCommands(store: sessionStore)
        }

        Settings {
            SettingsView(store: sessionStore)
                .frame(width: 520)
        }
    }
}
