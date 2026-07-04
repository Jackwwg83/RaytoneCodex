import SwiftUI
import WebKit

struct BrowserPanelView: View {
    @ObservedObject var store: SessionStore
    @Binding var showInspector: Bool
    @State private var addressDraft = ""
    @State private var didRequestSmokeSnapshot = false

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            toolbar
            ZStack {
                if let url = store.browserURL {
                    BrowserWebView(
                        store: store,
                        url: url,
                        reloadToken: store.browserReloadToken,
                        navigationCommand: store.browserNavigationCommand,
                        snapshotRequest: store.browserSnapshotRequest
                    )
                } else {
                    browserEmptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.transcript)
            if !store.browserScreenshotStatusText.isEmpty {
                Text(store.browserScreenshotStatusText)
                    .font(Theme.mono(10.5))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.panel)
                    .overlay(alignment: .top) { Hairline() }
            }
        }
        .frame(width: Theme.Layout.inspectorWidth)
        .frame(maxHeight: .infinity)
        .background(Theme.panel)
        .overlay(alignment: .leading) { Hairline(axis: .vertical) }
        .onAppear {
            addressDraft = addressText
            requestSmokeSnapshotIfNeeded()
        }
        .onChange(of: store.browserURL) { _, _ in
            addressDraft = addressText
            requestSmokeSnapshotIfNeeded()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            Button {
                store.toolPanel = .launcher
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(GhostIconButtonStyle(size: 24))
            .help("返回工具")

            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text(tabTitle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 4)
                Button {
                    store.toolPanel = .launcher
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(GhostIconButtonStyle(size: 18))
                .help("关闭标签")
            }
            .padding(.leading, 9)
            .padding(.trailing, 4)
            .frame(height: 30)
            .background(Theme.fillSelected)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

            Button {
                store.newBrowserTab()
                addressDraft = ""
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(GhostIconButtonStyle(size: 24))
            .help("新标签")

            Spacer(minLength: 0)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) { showInspector = false }
            } label: {
                Image(systemName: "sidebar.trailing")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(GhostIconButtonStyle(size: 26))
            .help("关闭面板")
        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(.bar)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private var toolbar: some View {
        HStack(spacing: 7) {
            toolbarButton("chevron.left", "返回", disabled: !store.browserCanGoBack) {
                store.goBackInBrowser()
            }
            toolbarButton("chevron.right", "前进", disabled: !store.browserCanGoForward) {
                store.goForwardInBrowser()
            }
            toolbarButton("arrow.clockwise", "重新加载") {
                store.reloadBrowserPanel()
            }

            HStack(spacing: 6) {
                Image(systemName: "lock")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                TextField("输入网址或文件路径", text: $addressDraft)
                    .textFieldStyle(.plain)
                    .font(Theme.mono(11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .onSubmit {
                        store.openBrowserAddress(addressDraft)
                    }
            }
            .padding(.horizontal, 9)
            .frame(height: 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.fill)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            toolbarButton("camera", "截图") {
                store.captureBrowserPanelScreenshot()
            }
            toolbarButton("arrow.up.forward.app", "在浏览器打开") {
                store.openBrowserExternally()
            }
            toolbarButton("ellipsis", "更多") {
                store.openBrowserSample()
                addressDraft = addressText
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.panel)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private func toolbarButton(
        _ symbol: String,
        _ help: String,
        disabled: Bool = false,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12.5, weight: .medium))
        }
        .buttonStyle(GhostIconButtonStyle(size: 24))
        .foregroundStyle(disabled ? Theme.textTertiary : Theme.textSecondary)
        .disabled(disabled)
        .help(help)
    }

    private var browserEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "globe")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(Theme.textTertiary)
            Text("在地址栏输入网址或打开一个本地文件")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tabTitle: String {
        if !store.browserTitle.isEmpty, store.browserTitle != "浏览器" {
            return store.browserTitle
        }
        return store.browserURL?.lastPathComponent ?? "浏览器"
    }

    private var addressText: String {
        guard let url = store.browserURL else {
            return ""
        }
        if url.isFileURL {
            return url.path
        }
        return url.absoluteString
    }

    private func requestSmokeSnapshotIfNeeded() {
        guard ProcessInfo.processInfo.environment["RAYTONE_CODEX_BROWSER_SNAPSHOT_SMOKE"] == "1",
              !didRequestSmokeSnapshot,
              store.browserURL != nil else {
            return
        }

        didRequestSmokeSnapshot = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            store.captureBrowserPanelScreenshot()
        }
    }
}

private struct BrowserWebView: NSViewRepresentable {
    @ObservedObject var store: SessionStore
    let url: URL
    let reloadToken: UUID
    let navigationCommand: BrowserNavigationCommand?
    let snapshotRequest: BrowserSnapshotRequest?

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        load(url, in: webView, coordinator: context.coordinator)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.store = store

        if let navigationCommand,
           context.coordinator.handledNavigationCommandID != navigationCommand.id {
            context.coordinator.handledNavigationCommandID = navigationCommand.id
            switch navigationCommand.action {
            case .back:
                if webView.canGoBack {
                    webView.goBack()
                    return
                }
            case .forward:
                if webView.canGoForward {
                    webView.goForward()
                    return
                }
            }
            context.coordinator.publishNavigationState(from: webView)
        }

        if let snapshotRequest,
           context.coordinator.handledSnapshotRequestID != snapshotRequest.id {
            context.coordinator.handledSnapshotRequestID = snapshotRequest.id
            context.coordinator.captureSnapshot(snapshotRequest, from: webView)
        }

        guard context.coordinator.loadedURL != url else {
            if context.coordinator.reloadToken != reloadToken {
                context.coordinator.reloadToken = reloadToken
                webView.reload()
            }
            context.coordinator.publishNavigationState(from: webView)
            return
        }
        load(url, in: webView, coordinator: context.coordinator)
    }

    private func load(_ url: URL, in webView: WKWebView, coordinator: Coordinator) {
        coordinator.loadedURL = url
        coordinator.reloadToken = reloadToken
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var store: SessionStore?
        var loadedURL: URL?
        var reloadToken: UUID?

        var handledNavigationCommandID: UUID?
        var handledSnapshotRequestID: UUID?

        init(store: SessionStore) {
            self.store = store
        }

        func publishNavigationState(from webView: WKWebView) {
            let currentURL = webView.url
            let currentTitle = webView.title
            let canGoBack = webView.canGoBack
            let canGoForward = webView.canGoForward
            Task { @MainActor [weak self] in
                self?.store?.updateBrowserNavigationState(
                    url: currentURL,
                    title: currentTitle,
                    canGoBack: canGoBack,
                    canGoForward: canGoForward
                )
            }
        }

        func captureSnapshot(_ request: BrowserSnapshotRequest, from webView: WKWebView) {
            let configuration = WKSnapshotConfiguration()
            configuration.rect = webView.bounds
            webView.takeSnapshot(with: configuration) { [weak self] image, error in
                Task { @MainActor [weak self] in
                    if let error {
                        self?.store?.completeBrowserPanelScreenshot(request: request, result: .failure(error))
                        return
                    }

                    guard let image else {
                        self?.store?.completeBrowserPanelScreenshot(
                            request: request,
                            result: .failure(BrowserSnapshotWriter.SnapshotError.missingImageData)
                        )
                        return
                    }

                    do {
                        try BrowserSnapshotWriter.writePNG(image: image, to: request.outputURL)
                        self?.store?.completeBrowserPanelScreenshot(request: request, result: .success(request.outputURL))
                    } catch {
                        self?.store?.completeBrowserPanelScreenshot(request: request, result: .failure(error))
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            loadedURL = webView.url
            publishNavigationState(from: webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loadedURL = webView.url
            publishNavigationState(from: webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            publishNavigationState(from: webView)
        }
    }
}
