import Foundation

public enum CommandLinePreview {
    public static func render(executableURL: URL, arguments: [String]) -> String {
        ([executableURL.path] + arguments).map(quote).joined(separator: " ")
    }

    public static func quote(_ value: String) -> String {
        if value.range(of: #"^[A-Za-z0-9_@%+=:,./-]+$"#, options: .regularExpression) != nil {
            return value
        }

        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
