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
    static func image(vietnamese: Bool, gray: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let color: NSColor = gray ? .black : NSColor(srgbRed: 0x00 / 255.0, green: 0x66 / 255.0, blue: 0xAB / 255.0, alpha: 1)

            // rounded frame filling most of the icon (matches sibling icons)
            let frameRect = rect.insetBy(dx: 1, dy: 1)
            let frame = NSBezierPath(roundedRect: frameRect, xRadius: 4, yRadius: 4)
            frame.lineWidth = 0.8
            color.setStroke()
            frame.stroke()

            let text = (vietnamese ? "V" : "E") as NSString
            let font = NSFont.systemFont(ofSize: 11, weight: .medium)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
            let textSize = text.size(withAttributes: attrs)
            // optically centre the cap glyph within the frame
            let x = frameRect.midX - textSize.width / 2
            let y = frameRect.midY - font.capHeight / 2 + font.descender
            text.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
            return true
        }
        image.isTemplate = gray
        return image
    }
}
