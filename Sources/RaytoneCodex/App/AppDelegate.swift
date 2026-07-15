import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        localizeMainMenuTitles()

        DispatchQueue.main.async {
            self.localizeMainMenuTitles()
            NSApp.windows
                .filter { $0.title == "RaytoneX" }
                .forEach { window in
                    window.setFrame(
                        NSRect(origin: window.frame.origin, size: NSSize(width: 1440, height: 900)),
                        display: true
                    )
                    window.center()
                }
        }

        [0.1, 0.5, 1.5, 3.0].forEach { delay in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.localizeMainMenuTitles()
            }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        localizeMainMenuTitles()
    }

    func applicationWillUpdate(_ notification: Notification) {
        localizeMainMenuTitles()
    }

    func applicationDidUpdate(_ notification: Notification) {
        localizeMainMenuTitles()
    }

    private func localizeMainMenuTitles() {
        let localizedTitles = [
            "File": "文件",
            "Edit": "编辑",
            "View": "视图",
            "Window": "窗口",
            "Help": "帮助",
        ]

        NSApp.mainMenu?.items.forEach { item in
            if let localizedTitle = localizedTitles[item.title] {
                item.title = localizedTitle
                item.submenu?.title = localizedTitle
            }
        }
    }
}
