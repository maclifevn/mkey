// Renders the mkey app icon into AppIcon.appiconset.
// The glyph is the user's triangular "mountain" logo (from favicon.svg,
// viewBox 0 0 64 54.75) drawn over a deep-navy gradient.
// Usage: swift scripts/make_icon.swift <output-appiconset-dir>

import AppKit
import Foundation

let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Sources/Support/Assets.xcassets/AppIcon.appiconset"

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// Logo polygons in SVG space (64 × 54.75, y-down)
let logoSpace = NSSize(width: 64, height: 54.75)
let logoPolygons: [(color: NSColor, points: [NSPoint])] = [
    (NSColor(srgbRed: 0x12 / 255.0, green: 0xC3 / 255.0, blue: 0xF4 / 255.0, alpha: 1),
     [NSPoint(x: 13.77, y: 17.46), NSPoint(x: 1.29, y: 50.15), NSPoint(x: 12.29, y: 50.15), NSPoint(x: 27.56, y: 26.78)]),
    (NSColor(srgbRed: 0x39 / 255.0, green: 0xA4 / 255.0, blue: 0xDC / 255.0, alpha: 1),
     [NSPoint(x: 43.12, y: 2.94), NSPoint(x: 27.56, y: 26.78), NSPoint(x: 62.16, y: 50.15)]),
    (NSColor(srgbRed: 0x00 / 255.0, green: 0x66 / 255.0, blue: 0xAB / 255.0, alpha: 1),
     [NSPoint(x: 27.56, y: 26.78), NSPoint(x: 12.29, y: 50.15), NSPoint(x: 62.16, y: 50.15)]),
]

func logoPath(in frame: NSRect, polygon: [NSPoint]) -> NSBezierPath {
    let scale = min(frame.width / logoSpace.width, frame.height / logoSpace.height)
    let drawnSize = NSSize(width: logoSpace.width * scale, height: logoSpace.height * scale)
    let origin = NSPoint(x: frame.midX - drawnSize.width / 2, y: frame.midY - drawnSize.height / 2)

    let path = NSBezierPath()
    for (i, p) in polygon.enumerated() {
        // flip y: SVG is y-down, AppKit y-up
        let converted = NSPoint(x: origin.x + p.x * scale,
                                y: origin.y + (logoSpace.height - p.y) * scale)
        if i == 0 { path.move(to: converted) } else { path.line(to: converted) }
    }
    path.close()
    return path
}

func renderIcon(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = CGFloat(pixels)
    // macOS icon convention: content inset ~10%, continuous-corner rect
    let inset = s * 0.10
    let rect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = rect.width * 0.225
    let badge = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // navy gradient, lightened so the icon does not read as near-black
    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.16, green: 0.34, blue: 0.55, alpha: 1.0),
        NSColor(srgbRed: 0.07, green: 0.18, blue: 0.36, alpha: 1.0),
    ])!
    gradient.draw(in: badge, angle: -90)

    // subtle inner highlight
    let highlight = NSBezierPath(roundedRect: rect.insetBy(dx: rect.width * 0.012, dy: rect.width * 0.012),
                                 xRadius: radius * 0.96, yRadius: radius * 0.96)
    NSColor.white.withAlphaComponent(0.10).setStroke()
    highlight.lineWidth = max(1, s * 0.008)
    highlight.stroke()

    // the mountain logo, centered with breathing room
    let logoFrame = rect.insetBy(dx: rect.width * 0.16, dy: rect.height * 0.16)
    NSGraphicsContext.current?.cgContext.setShadow(offset: CGSize(width: 0, height: -s * 0.01),
                                                   blur: s * 0.03,
                                                   color: NSColor.black.withAlphaComponent(0.45).cgColor)
    for polygon in logoPolygons {
        polygon.color.setFill()
        logoPath(in: logoFrame, polygon: polygon.points).fill()
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let sizes: [(name: String, points: Int, scale: Int)] = [
    ("icon_16x16", 16, 1), ("icon_16x16@2x", 16, 2),
    ("icon_32x32", 32, 1), ("icon_32x32@2x", 32, 2),
    ("icon_128x128", 128, 1), ("icon_128x128@2x", 128, 2),
    ("icon_256x256", 256, 1), ("icon_256x256@2x", 256, 2),
    ("icon_512x512", 512, 1), ("icon_512x512@2x", 512, 2),
]

var images: [[String: String]] = []
for entry in sizes {
    let px = entry.points * entry.scale
    let rep = renderIcon(pixels: px)
    let data = rep.representation(using: .png, properties: [:])!
    let filename = "\(entry.name).png"
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(filename)"))
    images.append([
        "filename": filename,
        "idiom": "mac",
        "scale": "\(entry.scale)x",
        "size": "\(entry.points)x\(entry.points)",
    ])
}

let contents: [String: Any] = [
    "images": images,
    "info": ["author": "xcode", "version": 1],
]
let json = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try! json.write(to: URL(fileURLWithPath: "\(outDir)/Contents.json"))
print("AppIcon written to \(outDir)")
