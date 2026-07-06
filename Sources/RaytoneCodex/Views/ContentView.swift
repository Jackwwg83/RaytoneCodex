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
                    centerContent
                    if store.route == .thread, store.showInspector, !usesBottomTerminalPanel {
                        InspectorView(store: store, showInspector: $store.showInspector)
                    }
                }
            }
        }
        .background(Theme.window)
        .sheet(isPresented: $store.providerOnboardingPresented) {
            ProviderOnboardingView(store: store)
                .frame(width: 760, height: 560)
                .preferredColorScheme(store.preferredColorScheme)
        }
        .onAppear {
            store.installSampleWorkspaceIfNeeded()
        }
    }

    @ViewBuilder
    private var centerContent: some View {
        if usesBottomTerminalPanel {
            VStack(spacing: 0) {
                routeContent
                BottomTerminalToolPanel(store: store, showInspector: $store.showInspector)
            }
        } else {
            routeContent
        }
    }

    private var usesBottomTerminalPanel: Bool {
        store.route == .thread &&
            store.showInspector &&
            store.toolPanel == .terminal &&
            store.desktopTerminalPosition == "底部"
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
