import Foundation

struct CommandSurfaceShortcut: Identifiable, Equatable {
    var id: String
    var title: String
    var shortcut: String
    var detail: String
    var source: String
    var isAvailable: Bool
}
