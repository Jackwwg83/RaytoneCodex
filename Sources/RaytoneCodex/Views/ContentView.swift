import RaytoneCodexCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        Group {
            if store.route == .settings {
                SettingsRouteView(store: store)
            } else {
                HStack(spacing: 0) {
                    SidebarView(store: store)
                    routeContent
                    if store.route == .thread, store.showInspector {
                        InspectorView(store: store, showInspector: $store.showInspector)
                    }
                }
            }
        }
        .background(Theme.window)
        .onAppear {
            store.installSampleWorkspaceIfNeeded()
            store.applyStartupScreenIfNeeded()
        }
    }

    @ViewBuilder
    private var routeContent: some View {
        switch store.route {
        case .thread:
            ThreadView(store: store, showInspector: $store.showInspector)
        case .plugins:
            PluginsPage(store: store)
        case .automation:
            AutomationPage(store: store)
        case .settings:
            SettingsRouteView(store: store)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        Form {
            TextField("工作区", text: $store.workspacePath)
            TextField("模型", text: $store.model)
            Picker("沙箱", selection: $store.sandbox) {
                ForEach(CodexSandboxMode.allCases, id: \.self) { mode in
                    Text(ComposerView.sandboxName(mode)).tag(mode)
                }
            }
            LabeledContent("审批") {
                Text(store.execApprovalDisplayName)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(20)
    }
}
