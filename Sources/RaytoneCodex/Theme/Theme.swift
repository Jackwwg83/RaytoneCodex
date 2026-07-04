import SwiftUI

/// Centralized design tokens for the Codex-style desktop client.
///
/// Colors are built on adaptive system colors (`NSColor` semantic colors and
/// `Color.primary/.secondary` opacity fills) so the entire UI tracks the macOS
/// system appearance — light and dark — with no per-mode branching.
enum Theme {
    // MARK: Surfaces

    /// Outer window background (the quiet neutral gray Codex uses behind chrome).
    static let window = Color(nsColor: .windowBackgroundColor)
    /// Sidebar / project list background.
    static let sidebar = Color(nsColor: .windowBackgroundColor)
    /// Transcript reading surface (white in light, near-black in dark).
    static let transcript = Color(nsColor: .textBackgroundColor)
    /// Right inspector / side-panel background.
    static let panel = Color(nsColor: .windowBackgroundColor)
    /// Inset code / terminal surface.
    static let code = Color(nsColor: .textBackgroundColor)

    // MARK: Fills (adaptive via primary opacity)

    static let fillSubtle = Color.primary.opacity(0.035)
    static let fill = Color.primary.opacity(0.06)
    static let fillStrong = Color.primary.opacity(0.10)
    static let fillSelected = Color.primary.opacity(0.085)
    static let fillHover = Color.primary.opacity(0.05)

    // MARK: Hairlines

    static let border = Color(nsColor: .separatorColor)
    static let borderSoft = Color.primary.opacity(0.07)

    // MARK: Text

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.62)

    // MARK: Accent & semantic

    static let accent = Color.accentColor
    static let success = Color(nsColor: .systemGreen)
    static let warning = Color(nsColor: .systemOrange)
    static let danger = Color(nsColor: .systemRed)
    static let info = Color(nsColor: .systemBlue)

    static let diffAddedText = Color(nsColor: .systemGreen)
    static let diffRemovedText = Color(nsColor: .systemRed)
    static let diffAddedFill = Color(nsColor: .systemGreen).opacity(0.12)
    static let diffRemovedFill = Color(nsColor: .systemRed).opacity(0.12)

    // MARK: Metrics

    enum Radius {
        static let row: CGFloat = 8
        static let control: CGFloat = 9
        static let card: CGFloat = 12
        static let composer: CGFloat = 18
    }

    enum Layout {
        static let sidebarWidth: CGFloat = 260
        static let inspectorWidth: CGFloat = 356
        static let transcriptMaxWidth: CGFloat = 760
        static let headerHeight: CGFloat = 52
    }

    // MARK: Typography helpers

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Shared shapes

/// A 1pt hairline divider that adapts to the system appearance.
struct Hairline: View {
    enum Axis { case horizontal, vertical }

    var axis: Axis = .horizontal
    var color: Color = Theme.borderSoft

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(
                width: axis == .vertical ? 1 : nil,
                height: axis == .horizontal ? 1 : nil
            )
    }
}

// MARK: - Button styles

/// Borderless toolbar icon button (header / inspector controls).
struct GhostIconButtonStyle: ButtonStyle {
    var size: CGFloat = 28

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .foregroundStyle(.secondary)
            .background(configuration.isPressed ? Theme.fillStrong : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
    }
}

/// Compact bordered "chip" button used for inline actions (Approve / Deny / Copy).
struct ChipButtonStyle: ButtonStyle {
    var tint: Color? = nil
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 11)
            .frame(height: 26)
            .background(background(pressed: configuration.isPressed))
            .overlay(
                Capsule().stroke(prominent ? Color.clear : Theme.border, lineWidth: 1)
            )
            .clipShape(Capsule())
            .contentShape(Capsule())
    }

    private var foreground: Color {
        if prominent { return Color(nsColor: .textBackgroundColor) }
        return tint ?? .primary
    }

    private func background(pressed: Bool) -> Color {
        if prominent { return (tint ?? Color.primary).opacity(pressed ? 0.8 : 1) }
        return pressed ? Theme.fillStrong : Theme.fill
    }
}
