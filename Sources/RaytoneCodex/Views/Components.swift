import SwiftUI

// MARK: - Pill / chip

/// A compact rounded label used for header and composer metadata.
struct Pill: View {
    var title: String
    var systemImage: String? = nil
    var prominent: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10.5, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 11.5, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(prominent ? Color.primary : Color.secondary)
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(Theme.fill)
        .clipShape(Capsule())
    }
}

// MARK: - Section header

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(Theme.textTertiary)
    }
}

// MARK: - Status dot

struct StatusDot: View {
    var severity: ConnectionState.Severity
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }

    private var color: Color {
        switch severity {
        case .ok: Theme.success
        case .warning: Theme.warning
        case .error: Theme.danger
        }
    }
}

// MARK: - Avatar

struct Avatar: View {
    var symbol: String
    var foreground: Color
    var background: Color
    var filled: Bool = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: 24, height: 24)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    static let user = Avatar(symbol: "person.fill", foreground: .white, background: Color.accentColor)
    static let agent = Avatar(symbol: "sparkle", foreground: .primary, background: Theme.fillStrong)
}

// MARK: - Key/value row (runtime panel)

struct KeyValueRow: View {
    var label: String
    var value: String
    var mono = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(mono ? Theme.mono(11) : .system(size: 12))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Inset code / output block

struct CodeBlock: View {
    var text: String
    var tint: Color = Theme.textSecondary

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(text.isEmpty ? "—" : text)
                .font(Theme.mono(11.5))
                .foregroundStyle(tint)
                .textSelection(.enabled)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.code)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.borderSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Lightweight markdown renderer

/// Renders agent text with inline markdown (bold / italic / inline code / links)
/// and fenced ``` code blocks. Block-level lists render as plain lines, which
/// keeps the renderer dependency-free and robust.
struct MarkdownText: View {
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(MarkdownText.parse(text)) { block in
                switch block.kind {
                case .paragraph:
                    Text(MarkdownText.inline(block.text))
                        .font(.system(size: 14))
                        .lineSpacing(4)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .code:
                    CodeBlock(text: block.text, tint: .primary)
                }
            }
        }
    }

    struct Block: Identifiable {
        let id = UUID()
        let kind: Kind
        let text: String
        enum Kind { case paragraph, code }
    }

    static func inline(_ string: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        if let attributed = try? AttributedString(markdown: string, options: options) {
            return attributed
        }
        return AttributedString(string)
    }

    static func parse(_ raw: String) -> [Block] {
        var blocks: [Block] = []
        var buffer: [String] = []
        var inCode = false

        func flush(_ kind: Block.Kind) {
            let joined = buffer.joined(separator: "\n")
                .trimmingCharacters(in: .newlines)
            if !joined.isEmpty {
                blocks.append(Block(kind: kind, text: joined))
            }
            buffer.removeAll()
        }

        for line in raw.components(separatedBy: "\n") {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                flush(inCode ? .code : .paragraph)
                inCode.toggle()
                continue
            }
            buffer.append(line)
        }
        flush(inCode ? .code : .paragraph)

        return blocks.isEmpty ? [Block(kind: .paragraph, text: raw)] : blocks
    }
}

// MARK: - Relative time

enum RelativeTime {
    static func short(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "刚刚" }
        if seconds < 3600 { return "\(Int(seconds / 60))分钟" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))小时" }
        let days = Int(seconds / 86_400)
        if days < 7 { return "\(days)天" }
        if days < 30 { return "\(days / 7)周" }
        return "\(days / 30)个月"
    }
}
