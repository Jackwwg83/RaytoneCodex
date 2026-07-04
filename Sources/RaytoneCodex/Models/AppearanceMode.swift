import SwiftUI

extension SessionStore {
    var preferredColorScheme: ColorScheme? {
        switch desktopAppearance {
        case "浅色":
            return .light
        case "深色":
            return .dark
        default:
            return nil
        }
    }

    var preferredColorSchemeName: String {
        switch preferredColorScheme {
        case .light:
            return "light"
        case .dark:
            return "dark"
        case nil:
            return "system"
        @unknown default:
            return "system"
        }
    }
}
