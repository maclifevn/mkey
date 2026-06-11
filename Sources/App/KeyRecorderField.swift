//
//  KeyRecorderField.swift
//  mkey
//
//  A small SwiftUI control that records a single key press (key code +
//  display character) for the language-switch and quick-convert hotkeys.
//  Press Delete to clear the key (0xFE = no key).
//

import AppKit
import Carbon.HIToolbox
import SwiftUI

struct KeyRecorderField: View {
    /// (keyCode, displayChar) packed like the legacy hotkey bitfield users expect.
    @Binding var keyCode: UInt8
    @Binding var displayChar: UInt8
    @State private var isRecording = false

    private var label: String {
        if displayChar == 0xFE { return isRecording ? "Nhấn phím…" : "Chưa đặt" }
        if keyCode == UInt8(kVK_Space) { return "Space" }
        let scalar = UnicodeScalar(displayChar)
        return String(scalar).uppercased()
    }

    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
            Text(label)
                .frame(minWidth: 64)
                .foregroundStyle(displayChar == 0xFE && !isRecording ? .secondary : .primary)
        }
        .buttonStyle(.bordered)
        .background(KeyCaptureRepresentable(isRecording: $isRecording, keyCode: $keyCode, displayChar: $displayChar))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isRecording ? Color.accentColor : .clear, lineWidth: 2)
        )
    }
}

private struct KeyCaptureRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var keyCode: UInt8
    @Binding var displayChar: UInt8

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isRecording = isRecording
        context.coordinator.startOrStopMonitor()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator {
        var parent: KeyCaptureRepresentable
        var isRecording = false
        private var monitor: Any?

        init(parent: KeyCaptureRepresentable) {
            self.parent = parent
        }

        func startOrStopMonitor() {
            if isRecording, monitor == nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    guard let self, self.isRecording else { return event }
                    let code = event.keyCode
                    if code == UInt16(kVK_Delete) || code == UInt16(kVK_ForwardDelete) {
                        self.parent.keyCode = 0xFE
                        self.parent.displayChar = 0xFE
                    } else if code == UInt16(kVK_Space) {
                        self.parent.keyCode = UInt8(kVK_Space)
                        self.parent.displayChar = UInt8(kVK_Space)
                    } else if let chars = event.characters, let first = chars.utf8.first, code < 0xFE {
                        self.parent.keyCode = UInt8(truncatingIfNeeded: code)
                        self.parent.displayChar = first
                    } else {
                        return event //ignore pure modifier / exotic keys
                    }
                    self.parent.isRecording = false
                    return nil //swallow the keystroke
                }
            } else if !isRecording, let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}
