import SwiftUI

/// A tinted banner shown above the transcript when the runtime is not healthy.
/// Mirrors the Codex desktop connection lifecycle (disconnected, login/update
/// required, not installed, …).
struct ConnectionBanner: View {
    let state: ConnectionState
    var onRecover: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: state.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(state.title)
                    .font(.system(size: 12.5, weight: .semibold))
                Text(state.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let title = recoveryTitle {
                Button(action: onRecover) {
                    Text(title)
                }
                .buttonStyle(ChipButtonStyle(tint: tint, prominent: true))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(tint.opacity(0.10))
        .overlay(alignment: .bottom) { Hairline(color: tint.opacity(0.28)) }
    }

    private var tint: Color {
        switch state.severity {
        case .ok: Theme.success
        case .warning: Theme.warning
        case .error: Theme.danger
        }
    }

    private var recoveryTitle: String? {
        switch state {
        case .loginRequired: "登录"
        case .updateRequired: "更新"
        case .restartRequired: "重启"
        case .notInstalled: "定位 CLI"
        case .sidecarUnavailable: "重新连接"
        case .providerKeyMissing, .providerUnauthorized: "设置"
        case .disconnected: "重新连接"
        case .connecting, .connected: nil
        }
    }
}
