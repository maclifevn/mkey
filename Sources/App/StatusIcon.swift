//
//  StatusIcon.swift
//  mkey
//
//  Menu-bar glyph: a letter "V" (Vietnamese) or "E" (English) inside a rounded
//  frame, sized to match the standard ~18pt menu-bar icon height. In monochrome
//  mode the image is a template so the menu bar tints it; in colour mode the
//  brand blue is used.
//

import AppKit

enum StatusIcon {
    private static var cache: [Key: NSImage] = [:]

    static func image(vietnamese: Bool, gray: Bool, excluded: Bool = false) -> NSImage {
        let key = Key(vietnamese: vietnamese, gray: gray, excluded: excluded)
        if let image = cache[key] {
            return image
        }

        // In an excluded app MKey is fully bypassed — render the glyph faded so
        // the menu bar visibly signals "inactive here".
        let alpha: CGFloat = excluded ? 0.35 : 1.0
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let color: NSColor = (gray ? NSColor.black : NSColor(srgbRed: 0x00 / 255.0, green: 0x66 / 255.0, blue: 0xAB / 255.0, alpha: 1)).withAlphaComponent(alpha)

            // rounded filled rectangle filling most of the icon (matches sibling icons)
            let frameRect = rect.insetBy(dx: 1, dy: 1)
            let frame = NSBezierPath(roundedRect: frameRect, xRadius: 2, yRadius: 2)
            color.setFill()
            frame.fill()

            let text = (vietnamese ? "V" : "E") as NSString
            let font = NSFont.systemFont(ofSize: 14, weight: .medium)
            let textSize = text.size(withAttributes: [.font: font])
            // optically centre the cap glyph within the frame
            let x = frameRect.midX - textSize.width / 2
            let y = frameRect.midY - textSize.height / 2

            if gray {
                // In template mode, draw text using destinationOut (transparent cutout) so it is visible against the background fill
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current?.compositingOperation = .destinationOut
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
                text.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
                NSGraphicsContext.restoreGraphicsState()
            } else {
                // In color mode, draw text using white color for contrast against the blue background fill
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white.withAlphaComponent(alpha)]
                text.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
            }
            return true
        }
        image.isTemplate = gray
        cache[key] = image
        return image
    }

    private struct Key: Hashable {
        let vietnamese: Bool
        let gray: Bool
        let excluded: Bool
    }
}
