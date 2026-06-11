//
//  StatusIcon.swift
//  mkey
//
//  Menu-bar glyph: a thin letter "V" (Vietnamese) or "E" (English) inside a
//  thin rounded frame. In monochrome mode the image is a template so the
//  menu bar tints it; in color mode the brand blue is used.
//

import AppKit

enum StatusIcon {
    static func image(vietnamese: Bool, gray: Bool) -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            let color: NSColor = gray ? .black : NSColor(srgbRed: 0x00 / 255.0, green: 0x66 / 255.0, blue: 0xAB / 255.0, alpha: 1)

            // hairline square frame, centered
            let side: CGFloat = 13.5
            let frameRect = NSRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
            let frame = NSBezierPath(roundedRect: frameRect, xRadius: 3, yRadius: 3)
            frame.lineWidth = 0.5
            color.setStroke()
            frame.stroke()

            // letter with readable weight
            let text = (vietnamese ? "V" : "E") as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: color,
            ]
            let textSize = text.size(withAttributes: attrs)
            text.draw(at: NSPoint(x: frameRect.midX - textSize.width / 2,
                                  y: frameRect.midY - textSize.height / 2),
                      withAttributes: attrs)
            return true
        }
        image.isTemplate = gray
        return image
    }
}
