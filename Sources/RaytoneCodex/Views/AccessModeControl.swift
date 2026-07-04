import SwiftUI

struct AccessModeControl: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.14)) {
                store.accessModePopoverPresented.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: store.accessMode.capsuleSymbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(store.accessMode == .full ? Theme.warning : Theme.textSecondary)
                Text(store.accessMode.shortTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Theme.fill)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .help("批准模式")
    }
}

struct AccessModePopover: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("应该如何批准 Codex 操作？")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 12)
                Button("了解更多") {
                    store.route = .settings
                    store.settingsPane = .configuration
                }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.info)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)

            ForEach(AccessMode.allCases) { mode in
                AccessModeRow(
                    mode: mode,
                    isSelected: store.accessMode == mode
                ) {
                    store.chooseAccessMode(mode)
                    withAnimation(.easeInOut(duration: 0.12)) {
                        store.accessModePopoverPresented = false
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 330)
        .background(Theme.transcript)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: Color.primary.opacity(0.10), radius: 22, x: 0, y: 12)
    }
}

private struct AccessModeRow: View {
    let mode: AccessMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(mode == .full ? Theme.warning : Theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Theme.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(mode.description)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, 7)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 9)
            .background(isSelected ? Theme.fillSelected : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
