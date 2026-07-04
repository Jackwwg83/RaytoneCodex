import AppKit
import Foundation

enum BrowserSnapshotWriter {
    enum SnapshotError: LocalizedError {
        case missingImageData

        var errorDescription: String? {
            switch self {
            case .missingImageData:
                return "无法从网页快照生成 PNG 数据"
            }
        }
    }

    static func writePNG(image: NSImage, to url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw SnapshotError.missingImageData
        }

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try pngData.write(to: url, options: .atomic)
    }
}
