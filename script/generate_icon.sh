#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="${1:-$ROOT_DIR/dist/AppIcon.icns}"
WORK_DIR="$(mktemp -d)"
ICONSET="$WORK_DIR/AppIcon.iconset"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$ICONSET" "$(dirname "$DESTINATION")"

/usr/bin/swift - "$ICONSET" <<'SWIFT'
import AppKit
import CoreGraphics
import Foundation

let iconset = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let variants: [(pixels: Int, filename: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func drawIcon(pixels: Int, destination: URL) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "RaytoneCodexIcon", code: 1)
    }

    let size = CGFloat(pixels)
    let graphics = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    guard let context = graphics?.cgContext else {
        throw NSError(domain: "RaytoneCodexIcon", code: 2)
    }

    context.clear(CGRect(x: 0, y: 0, width: size, height: size))

    let outer = CGRect(x: size * 0.06, y: size * 0.06, width: size * 0.88, height: size * 0.88)
    let outerRadius = size * 0.23

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.02), blur: size * 0.055, color: color(0, 0, 0, 0.22))
    context.setFillColor(color(246, 246, 244))
    let background = CGPath(roundedRect: outer, cornerWidth: outerRadius, cornerHeight: outerRadius, transform: nil)
    context.addPath(background)
    context.fillPath()
    context.restoreGState()

    context.addPath(CGPath(roundedRect: outer.insetBy(dx: size * 0.012, dy: size * 0.012), cornerWidth: outerRadius * 0.93, cornerHeight: outerRadius * 0.93, transform: nil))
    context.setStrokeColor(color(24, 24, 22, 0.12))
    context.setLineWidth(max(1, size * 0.012))
    context.strokePath()

    let terminal = outer.insetBy(dx: size * 0.16, dy: size * 0.21)
    let terminalRadius = size * 0.075
    context.addPath(CGPath(roundedRect: terminal, cornerWidth: terminalRadius, cornerHeight: terminalRadius, transform: nil))
    context.setFillColor(color(22, 23, 22))
    context.fillPath()

    context.addPath(CGPath(roundedRect: terminal.insetBy(dx: size * 0.014, dy: size * 0.014), cornerWidth: terminalRadius * 0.82, cornerHeight: terminalRadius * 0.82, transform: nil))
    context.setStrokeColor(color(255, 255, 255, 0.08))
    context.setLineWidth(max(1, size * 0.01))
    context.strokePath()

    context.setStrokeColor(color(246, 246, 244))
    context.setLineWidth(max(1.3, size * 0.052))
    context.setLineCap(CGLineCap.round)
    context.setLineJoin(CGLineJoin.round)

    let left = CGPoint(x: terminal.minX + terminal.width * 0.28, y: terminal.midY)
    let top = CGPoint(x: terminal.minX + terminal.width * 0.43, y: terminal.midY + terminal.height * 0.17)
    let bottom = CGPoint(x: terminal.minX + terminal.width * 0.43, y: terminal.midY - terminal.height * 0.17)
    context.move(to: top)
    context.addLine(to: left)
    context.addLine(to: bottom)
    context.strokePath()

    context.move(to: CGPoint(x: terminal.minX + terminal.width * 0.55, y: terminal.midY - terminal.height * 0.17))
    context.addLine(to: CGPoint(x: terminal.minX + terminal.width * 0.75, y: terminal.midY - terminal.height * 0.17))
    context.strokePath()

    context.setFillColor(color(112, 191, 116))
    let dotSize = size * 0.08
    context.fillEllipse(in: CGRect(x: outer.maxX - dotSize * 1.8, y: outer.maxY - dotSize * 1.7, width: dotSize, height: dotSize))

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
        throw NSError(domain: "RaytoneCodexIcon", code: 3)
    }
    try png.write(to: destination)
}

try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for variant in variants {
    try drawIcon(pixels: variant.pixels, destination: iconset.appendingPathComponent(variant.filename))
}
SWIFT

/usr/bin/iconutil -c icns "$ICONSET" -o "$DESTINATION"
